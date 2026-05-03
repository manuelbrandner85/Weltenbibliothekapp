/// 🎥 LIVEKIT CALL SERVICE
///
/// Kapselt die Token-Beschaffung, Room-Connect-Logik und Track-Toggles
/// (Mikrofon, Kamera, Bildschirm-Teilen, Hand heben).
///
/// **Token-Flow:**
///   1. Client holt Supabase-Access-Token aus aktueller Session
///   2. POST /functions/v1/livekit-token mit { roomName, displayName }
///   3. Supabase Edge Function antwortet mit { token, url }
///   4. Room.connect(url, token) → live
///
/// **Track-Flow** (Phase 2):
///   - Mikrofon wird beim Beitritt automatisch aktiviert (nach Permission-OK)
///   - Kamera/Bildschirm-Teilen sind opt-in via Toggle
///   - Hand-heben wird als participant.attributes.handRaised gesetzt
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/api_config.dart';

/// Verbindungs-Phasen — granular damit die UI passende Indicator zeigen kann.
enum LiveKitConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class LiveKitCallService extends ChangeNotifier {
  LiveKitCallService();

  Room? _room;
  EventsListener<RoomEvent>? _listener;
  Timer? _durationTimer;

  // ── State ──────────────────────────────────────────────────────────────────

  LiveKitConnectionState _connectionState = LiveKitConnectionState.disconnected;
  String? _roomName;
  String? _world;
  String? _errorMessage;
  int _callDurationSeconds = 0;
  String? _pinnedIdentity;
  bool _autoSpeakerFocus = true;

  // Track-Toggle State
  bool _micEnabled = false;
  bool _cameraEnabled = false;
  bool _screenShareEnabled = false;
  bool _handRaised = false;

  // ── Getters ────────────────────────────────────────────────────────────────

  Room? get room => _room;
  LiveKitConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == LiveKitConnectionState.connected;
  String? get roomName => _roomName;
  String? get world => _world;
  String? get errorMessage => _errorMessage;
  int get callDurationSeconds => _callDurationSeconds;

  String? get pinnedIdentity => _pinnedIdentity;
  bool get autoSpeakerFocus => _autoSpeakerFocus;

  bool get micEnabled => _micEnabled;
  bool get cameraEnabled => _cameraEnabled;
  bool get screenShareEnabled => _screenShareEnabled;
  bool get handRaised => _handRaised;

  /// Anzahl der entfernten Teilnehmer (ohne lokalen User).
  int get remoteParticipantCount => _room?.remoteParticipants.length ?? 0;

  /// Gesamt-Teilnehmerzahl inkl. lokalem User.
  int get totalParticipantCount =>
      remoteParticipantCount + (_room?.localParticipant != null ? 1 : 0);

  /// Liste der entfernten Teilnehmer-Namen für UI-Anzeige.
  List<String> get remoteParticipantNames {
    final r = _room;
    if (r == null) return const [];
    return r.remoteParticipants.values
        .map((p) => p.name.isNotEmpty ? p.name : (p.identity))
        .toList();
  }

  /// Lokaler Video-Track (Kamera) wenn aktiv — für UI-Rendering.
  VideoTrack? get localVideoTrack {
    final lp = _room?.localParticipant;
    if (lp == null) return null;
    for (final pub in lp.videoTrackPublications) {
      // Nur Kamera-Track, nicht Screen-Share
      if (pub.source == TrackSource.camera && pub.track != null) {
        return pub.track as VideoTrack;
      }
    }
    return null;
  }

  /// Liste aller Remote-Video-Tracks für UI — Reihenfolge stabil per identity.
  /// Map: identity → VideoTrack (oder null wenn Cam aus).
  Map<String, VideoTrack?> get remoteVideoTracks {
    final r = _room;
    if (r == null) return const {};
    final map = <String, VideoTrack?>{};
    for (final p in r.remoteParticipants.values) {
      VideoTrack? track;
      for (final pub in p.videoTrackPublications) {
        if (pub.source == TrackSource.camera &&
            pub.subscribed &&
            pub.track != null) {
          track = pub.track as VideoTrack;
          break;
        }
      }
      map[p.identity] = track;
    }
    return map;
  }

  /// Hat ein bestimmter Remote-Teilnehmer Mic aktiv?
  bool isRemoteMicActive(String identity) {
    final r = _room;
    if (r == null) return false;
    final p = r.remoteParticipants.values
        .where((p) => p.identity == identity)
        .firstOrNull;
    if (p == null) return false;
    for (final pub in p.audioTrackPublications) {
      if (!pub.muted) return true;
    }
    return false;
  }


  // ── Connection-Lifecycle ───────────────────────────────────────────────────

  /// Tritt einem LiveKit-Raum bei. Wirft eine Exception mit deutscher
  /// Fehlermeldung wenn der Token-Endpoint failt oder die Verbindung scheitert.
  Future<void> joinRoom({
    required String roomName,
    required String world,
    String? displayName,
  }) async {
    if (!ApiConfig.isLivekitEnabled) {
      throw Exception('Sprach-Anruf ist nicht konfiguriert (LIVEKIT_URL fehlt).');
    }
    if (_connectionState == LiveKitConnectionState.connecting ||
        _connectionState == LiveKitConnectionState.connected) {
      return;
    }

    _setState(LiveKitConnectionState.connecting);
    _roomName = roomName;
    _world = world;
    _errorMessage = null;
    _pinnedIdentity = null;
    _micEnabled = false;
    _cameraEnabled = false;
    _screenShareEnabled = false;
    _handRaised = false;

    try {
      // Mikrofon-Permission bevor Room-Connect — sonst kann LiveKit kein
      // Audio-Track publishen.
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        throw Exception(
            'Mikrofon-Berechtigung fehlt. Bitte in den App-Einstellungen erlauben.');
      }

      final supabase = Supabase.instance.client;

      // Wenn keine Supabase-Session → automatisch anonyme Session erstellen
      // (App unterstützt lokale-only User, aber LiveKit-Token-Generation
      // braucht ein gültiges JWT). signInAnonymously erstellt schwachen
      // Account ohne Email/Passwort — perfekt für Voice-Call-Identifikation.
      if (supabase.auth.currentSession == null) {
        if (kDebugMode) {
          debugPrint('🔑 LiveKit: keine Supabase-Session → '
              'erstelle anonyme Session …');
        }
        try {
          await supabase.auth.signInAnonymously();
          if (kDebugMode) {
            debugPrint('🔑 LiveKit: anonyme Session erstellt — '
                'userId=${supabase.auth.currentUser?.id}');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ LiveKit: signInAnonymously failed — $e');
          }
          throw Exception(
              'Konnte keine Anruf-Sitzung erstellen. Bitte App neu starten '
              'und erneut versuchen.\nDetails: $e');
        }
      }

      final accessToken = supabase.auth.currentSession?.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception(
            'Nicht angemeldet — bitte App neu starten und erneut versuchen.');
      }

      // Token von Supabase Edge Function holen (direkt, kein Cloudflare)
      final tokenRes = await http
          .post(
            Uri.parse(ApiConfig.livekitTokenUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
              'apikey': ApiConfig.supabaseAnonKey,
            },
            body: jsonEncode({
              'roomName': roomName,
              if (displayName != null) 'displayName': displayName,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (tokenRes.statusCode != 200) {
        String msg = 'Token-Server Fehler (${tokenRes.statusCode})';
        try {
          final body = jsonDecode(tokenRes.body);
          if (body is Map && body['error'] is String) {
            msg = body['error'] as String;
          }
        } catch (_) {}
        throw Exception(msg);
      }

      final tokenData = jsonDecode(tokenRes.body) as Map<String, dynamic>;
      final token = tokenData['token'] as String?;
      final urlFromServer = (tokenData['url'] as String?) ?? '';
      final livekitUrl =
          urlFromServer.isNotEmpty ? urlFromServer : ApiConfig.livekitUrl;
      if (token == null || token.isEmpty) {
        throw Exception('Server lieferte kein gültiges Token.');
      }
      if (livekitUrl.isEmpty) {
        throw Exception('Keine LiveKit-Server-URL verfügbar.');
      }

      if (kDebugMode) {
        debugPrint('🎥 LiveKit: connecting to $livekitUrl room=$roomName …');
      }

      final room = Room(
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          // Ohne defaultAudioPublishOptions kommt Mensaena-Default-Encoding
          defaultAudioPublishOptions: AudioPublishOptions(
            dtx: true, // Discontinuous Transmission — spart Bandbreite bei Stille
          ),
          defaultVideoPublishOptions: VideoPublishOptions(
            simulcast: true,
          ),
        ),
      );
      _room = room;

      // Room-Events abonnieren — UI muss State-Wechsel widerspiegeln
      // (Disconnect, Reconnect, Teilnehmer-Wechsel, neue Tracks).
      _attachRoomListener(room);

      // Connect-Optionen mit Auto-Subscribe — sonst hören Teilnehmer einander nicht
      await room.connect(
        livekitUrl,
        token,
        connectOptions: const ConnectOptions(
          autoSubscribe: true, // Remote-Tracks automatisch abonnieren
        ),
      );

      if (kDebugMode) {
        debugPrint('✅ LiveKit: connected — '
            'localId=${room.localParticipant?.identity}, '
            'remoteParticipants=${room.remoteParticipants.length}');
      }

      // Mikrofon direkt beim Beitritt aktivieren — User soll standardmäßig
      // im Anruf hörbar sein (nicht "stumm beigetreten").
      try {
        await room.localParticipant?.setMicrophoneEnabled(true);
        _micEnabled = true;
        if (kDebugMode) {
          debugPrint('🎤 Mikrofon aktiviert');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ setMicrophoneEnabled fehlgeschlagen: $e');
        }
      }

      // Speakerphone an — sonst hört User durch Hörmuschel statt Lautsprecher
      try {
        await Hardware.instance.setPreferSpeakerOutput(true);
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ setPreferSpeakerOutput failed: $e');
      }


      _setState(LiveKitConnectionState.connected);
      _startDurationTimer();
    } catch (e) {
      _errorMessage = _friendlyError(e);
      _setState(LiveKitConnectionState.error);
      // Best-effort cleanup
      try {
        await _room?.disconnect();
      } catch (_) {}
      _room = null;
      rethrow;
    }
  }

  /// Hängt sich an Room-Events: Disconnect/Reconnect/Participant-Wechsel.
  /// Wichtig damit die UI bei Netz-Drops nicht "verbunden" suggeriert.
  void _attachRoomListener(Room room) {
    _listener?.dispose();
    final listener = room.createListener();
    _listener = listener;

    listener.on<RoomReconnectingEvent>((_) {
      _setState(LiveKitConnectionState.reconnecting);
    });
    listener.on<RoomReconnectedEvent>((_) {
      _setState(LiveKitConnectionState.connected);
    });
    listener.on<RoomDisconnectedEvent>((event) {
      if (kDebugMode) {
        debugPrint('🔴 LiveKit: disconnected — reason=${event.reason}');
      }
      _stopDurationTimer();
      _connectionState = LiveKitConnectionState.disconnected;
      notifyListeners();
    });
    listener.on<ParticipantConnectedEvent>((event) {
      if (kDebugMode) {
        debugPrint('👤 LiveKit: participant joined — '
            '${event.participant.identity} (${event.participant.name})');
      }
      notifyListeners();
    });
    listener.on<ParticipantDisconnectedEvent>((event) {
      if (kDebugMode) {
        debugPrint('👤 LiveKit: participant left — ${event.participant.identity}');
      }
      notifyListeners();
    });
    // Track-Events damit UI auf Cam-On/Off + Audio reagiert
    listener.on<TrackSubscribedEvent>((event) {
      if (kDebugMode) {
        debugPrint('🎵 LiveKit: subscribed track '
            '${event.publication.kind} from ${event.participant.identity}');
      }
      notifyListeners();
    });
    listener.on<TrackUnsubscribedEvent>((event) {
      if (kDebugMode) {
        debugPrint('🎵 LiveKit: unsubscribed ${event.publication.kind} '
            'from ${event.participant.identity}');
      }
      notifyListeners();
    });
    listener.on<TrackPublishedEvent>((event) {
      if (kDebugMode) {
        debugPrint('📤 LiveKit: published ${event.publication.kind} '
            'by ${event.participant.identity}');
      }
      notifyListeners();
    });
    listener.on<TrackUnpublishedEvent>((event) {
      if (kDebugMode) {
        debugPrint('📤 LiveKit: unpublished ${event.publication.kind} '
            'by ${event.participant.identity}');
      }
      notifyListeners();
    });
    listener.on<LocalTrackPublishedEvent>((event) {
      if (kDebugMode) {
        debugPrint('📤 LiveKit: LOCAL published ${event.publication.kind}');
      }
      notifyListeners();
    });
  }

  /// Verlässt den Raum und räumt alle Ressourcen auf.
  Future<void> leaveRoom() async {
    _stopDurationTimer();

    // Bildschirm-Teilen: Foreground-Service stoppen falls aktiv
    if (_screenShareEnabled) {
      try {
        await FlutterBackground.disableBackgroundExecution();
      } catch (_) {}
    }

    try {
      await _listener?.dispose();
    } catch (_) {}
    _listener = null;

    // Bildschirm-Teilen: Foreground-Service stoppen falls aktiv
    if (_screenShareEnabled) {
      try {
        await FlutterBackground.disableBackgroundExecution();
      } catch (_) {}
    }

    try {
      await _room?.disconnect();
    } catch (_) {}
    _room = null;
    _connectionState = LiveKitConnectionState.disconnected;
    _roomName = null;
    _world = null;
    _errorMessage = null;
    _callDurationSeconds = 0;
    _pinnedIdentity = null;
    _micEnabled = false;
    _cameraEnabled = false;
    _screenShareEnabled = false;
    _handRaised = false;
    notifyListeners();
  }

  // ── Track-Toggles ──────────────────────────────────────────────────────────

  /// Mikrofon ein-/ausschalten. Wirft KEINE Exception — Fehler landen in
  /// errorMessage damit die UI sie anzeigen kann.
  Future<void> toggleMicrophone() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    final target = !_micEnabled;
    try {
      if (target) {
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          _errorMessage =
              'Mikrofon-Berechtigung fehlt. Bitte in den App-Einstellungen erlauben.';
          notifyListeners();
          return;
        }
      }
      await lp.setMicrophoneEnabled(target);
      _micEnabled = target;
      notifyListeners();
    } catch (e) {
      _errorMessage = _friendlyError(e);
      notifyListeners();
    }
  }

  /// Kamera ein-/ausschalten. Fragt Permission beim ersten Aktivieren.
  Future<void> toggleCamera() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    final target = !_cameraEnabled;
    try {
      if (target) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          _errorMessage =
              'Kamera-Berechtigung fehlt. Bitte in den App-Einstellungen erlauben.';
          notifyListeners();
          return;
        }
      }
      await lp.setCameraEnabled(target);
      _cameraEnabled = target;
      notifyListeners();
    } catch (e) {
      _errorMessage = _friendlyError(e);
      notifyListeners();
    }
  }

  /// Bildschirm teilen ein-/ausschalten. Auf Android ist dafür ein
  /// Foreground-Service mit MediaProjection-Permission nötig — den startet
  /// `flutter_background` automatisch.
  Future<void> toggleScreenShare() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    final target = !_screenShareEnabled;
    try {
      if (target) {
        // Foreground-Service starten (Android-Pflicht für Screen-Capture).
        try {
          final hasPerms = await FlutterBackground.hasPermissions;
          if (!hasPerms) {
            await FlutterBackground.initialize(
              androidConfig: const FlutterBackgroundAndroidConfig(
                notificationTitle: 'Bildschirm wird geteilt',
                notificationText:
                    'Weltenbibliothek teilt deinen Bildschirm im Anruf.',
                enableWifiLock: true,
              ),
            );
          }
          await FlutterBackground.enableBackgroundExecution();
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ Foreground-Service fehlgeschlagen: $e');
        }
      } else {
        try {
          await FlutterBackground.disableBackgroundExecution();
        } catch (_) {}
      }
      await lp.setScreenShareEnabled(target);
      _screenShareEnabled = target;
      notifyListeners();
    } catch (e) {
      _errorMessage = _friendlyError(e);
      notifyListeners();
    }
  }

  /// Hand heben / senken. Toggelt aktuell nur den lokalen UI-State —
  /// Cross-Participant-Sync (DataChannel-Broadcast) kommt in Folge-PR
  /// wenn die exakte LiveKit-API-Form für die installierte Version
  /// verifiziert ist.
  Future<void> toggleHandRaised() async {
    if (!isConnected) return;
    _handRaised = !_handRaised;
    notifyListeners();
  }

  // ── Pin / Auto-Speaker-Focus (UI-state, kein LiveKit-API-Call) ────────────

  void pinParticipant(String? identity) {
    _pinnedIdentity = identity;
    notifyListeners();
  }

  void setAutoSpeakerFocus(bool enabled) {
    _autoSpeakerFocus = enabled;
    notifyListeners();
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  void _setState(LiveKitConnectionState state) {
    _connectionState = state;
    notifyListeners();
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _callDurationSeconds = 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callDurationSeconds++;
      notifyListeners();
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('SocketException') || s.contains('Failed host lookup')) {
      return 'Keine Internet-Verbindung — bitte WLAN/Mobilfunk prüfen.';
    }
    if (s.contains('TimeoutException')) {
      return 'Server reagiert nicht. Bitte später erneut versuchen.';
    }
    if (s.contains('401') || s.contains('Nicht authentifiziert')) {
      return 'Nicht angemeldet. Bitte App neu starten und einloggen.';
    }
    if (s.contains('503') || s.contains('nicht konfiguriert')) {
      return 'Sprach-Anruf ist serverseitig noch nicht aktiviert.';
    }
    if (s.contains('Mikrofon-Berechtigung') ||
        s.contains('Kamera-Berechtigung')) {
      return s.replaceFirst('Exception: ', '');
    }
    return s.replaceFirst('Exception: ', '');
  }

  @override
  void dispose() {
    _stopDurationTimer();
    try {
      _listener?.dispose();
    } catch (_) {}
    try {
      _room?.disconnect();
    } catch (_) {}
    super.dispose();
  }
}
