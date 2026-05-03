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

  /// Avatar-URL des lokalen Users — wird beim Connect via setAttributes
  /// an alle Teilnehmer gebroadcastet damit ihre UI sie zeigen kann.
  String? _localAvatarUrl;
  String? get localAvatarUrl => _localAvatarUrl;

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
    String? avatarUrl,
  }) async {
    // Avatar-URL für später (wird via setAttributes an alle gebroadcastet)
    _localAvatarUrl = avatarUrl;
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

      // Foreground-Service starten damit der Anruf weiter läuft wenn der
      // User die App minimiert (Standard-Verhalten von Android: kill ohne FG).
      try {
        final hasPerms = await FlutterBackground.hasPermissions;
        if (!hasPerms) {
          await FlutterBackground.initialize(
            androidConfig: const FlutterBackgroundAndroidConfig(
              notificationTitle: 'Sprach-Anruf läuft',
              notificationText:
                  'Weltenbibliothek hält den Anruf im Hintergrund aktiv.',
              notificationImportance: AndroidNotificationImportance.normal,
              enableWifiLock: true,
            ),
          );
        }
        final ok = await FlutterBackground.enableBackgroundExecution();
        if (kDebugMode) {
          debugPrint(ok
              ? '🌙 Background-Service aktiviert — Anruf läuft auch minimiert'
              : '⚠️ Background-Service nicht aktivierbar (vermutl. Permission)');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ FlutterBackground init/enable failed: $e');
        }
      }

      // Avatar-URL als Attribut broadcasten damit alle Teilnehmer sie sehen
      // (für Profilbild-Anzeige im Tile wenn Kamera aus).
      // NOTE: setAttributes returnt void in livekit_client 2.4 — kein await.
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        try {
          room.localParticipant?.setAttributes({'avatarUrl': avatarUrl});
          if (kDebugMode) {
            debugPrint('🖼️  Avatar-URL gebroadcastet: $avatarUrl');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Avatar-broadcast failed: $e');
          }
        }
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
    // Hand-Heben-Sync: andere User ändern Attribute → UI muss neu zeichnen.
    // Nutze nur participant.attributes — garantiert vorhanden quer durch
    // alle livekit_client-Versionen.
    listener.on<ParticipantAttributesChanged>((event) {
      if (kDebugMode) {
        debugPrint('🏷️  LiveKit: ${event.participant.identity} '
            'attributes=${event.participant.attributes}');
      }
      notifyListeners();
    });
  }

  /// Verlässt den Raum und räumt alle Ressourcen auf.
  Future<void> leaveRoom() async {
    _stopDurationTimer();

    // Foreground-Service IMMER stoppen wenn der Anruf verlassen wird —
    // war für Background-Mode aktiv (vom joinRoom gestartet).
    try {
      await FlutterBackground.disableBackgroundExecution();
      if (kDebugMode) {
        debugPrint('🌙 Background-Service deaktiviert (Anruf verlassen)');
      }
    } catch (_) {}

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

  bool _micToggleInFlight = false;

  /// Mikrofon ein-/ausschalten. Wirft KEINE Exception — Fehler landen in
  /// errorMessage damit die UI sie anzeigen kann. Doppel-Tap-Schutz +
  /// 5s Hard-Timeout damit UI nicht hängt wenn OS-Resource klemmt.
  Future<void> toggleMicrophone() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    if (_micToggleInFlight) return;
    _micToggleInFlight = true;
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
      await lp.setMicrophoneEnabled(target).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('⚠️ setMicrophoneEnabled($target) Timeout — '
                'forciere UI-Update');
          }
        },
      );
      _micEnabled = target;
      notifyListeners();
    } catch (e) {
      _errorMessage = _friendlyError(e);
      notifyListeners();
    } finally {
      _micToggleInFlight = false;
    }
  }

  bool _cameraToggleInFlight = false;

  /// Kamera ein-/ausschalten. Fragt Permission beim ersten Aktivieren.
  /// Doppel-Tap-Schutz + 5s Timeout damit UI nie ewig auf hängenden
  /// Camera-Resource-Release wartet.
  Future<void> toggleCamera() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;

    // Doppel-Tap-Schutz: zweiter Tap während der erste läuft → ignoriere
    if (_cameraToggleInFlight) {
      if (kDebugMode) {
        debugPrint('📷 toggleCamera: schon in flight, ignore');
      }
      return;
    }
    _cameraToggleInFlight = true;
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

      if (kDebugMode) {
        debugPrint('📷 setCameraEnabled($target) …');
      }

      if (target) {
        // Beim AN-Schalten: simpler Toggle mit Timeout
        await lp.setCameraEnabled(true).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            if (kDebugMode) {
              debugPrint('⚠️ setCameraEnabled(true) Timeout');
            }
          },
        );
      } else {
        // Beim AUS-Schalten: explicit unpublish + dispose vermeidet Hang
        // weil setCameraEnabled(false) in livekit_client 2.4 manchmal
        // auf langsame Camera-Resource-Release wartet.
        for (final pub in lp.videoTrackPublications.toList()) {
          if (pub.source != TrackSource.camera) continue;
          try {
            await lp.removePublishedTrack(pub.sid).timeout(
              const Duration(seconds: 3),
              onTimeout: () {
                if (kDebugMode) debugPrint('⚠️ removePublishedTrack timeout');
              },
            );
          } catch (e) {
            if (kDebugMode) debugPrint('⚠️ removePublishedTrack: $e');
          }
          // Track-Dispose im Hintergrund (await würde wieder hängen)
          unawaited(Future.microtask(() async {
            try {
              await pub.track?.dispose();
            } catch (_) {}
          }));
        }
      }

      _cameraEnabled = target;
      if (kDebugMode) {
        debugPrint('📷 Camera ist jetzt ${target ? "AN" : "AUS"}');
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ toggleCamera error: $e');
      }
      _errorMessage = _friendlyError(e);
      notifyListeners();
    } finally {
      _cameraToggleInFlight = false;
    }
  }

  /// Aktueller Kamera-Index (0 = front, 1 = back). Wird beim switchCamera
  /// rotiert damit nicht jedes Mal die gleiche Kamera ausgewählt wird.
  int _cameraIndex = 0;

  /// Wechselt zwischen Front- und Back-Kamera. Funktioniert nur wenn die
  /// Kamera bereits aktiv ist.
  Future<void> switchCamera() async {
    final lp = _room?.localParticipant;
    if (lp == null || !_cameraEnabled) return;
    try {
      // Finde aktiven Camera-Track
      LocalVideoTrack? cameraTrack;
      for (final pub in lp.videoTrackPublications) {
        if (pub.source == TrackSource.camera && pub.track != null) {
          cameraTrack = pub.track as LocalVideoTrack;
          break;
        }
      }
      if (cameraTrack == null) {
        if (kDebugMode) debugPrint('📷 switchCamera: kein aktiver Track');
        return;
      }
      // Hole alle verfügbaren Kameras (typisch: front + back)
      final cameras = await Hardware.instance.cameras();
      if (cameras.length < 2) {
        _errorMessage = 'Nur eine Kamera verfügbar.';
        notifyListeners();
        return;
      }
      // Rotiere zur nächsten Kamera in der Liste
      _cameraIndex = (_cameraIndex + 1) % cameras.length;
      final next = cameras[_cameraIndex];
      await cameraTrack.switchCamera(next.deviceId).timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          if (kDebugMode) debugPrint('⚠️ switchCamera Timeout');
        },
      );
      if (kDebugMode) {
        debugPrint('📷 Camera gewechselt → ${next.label} (${next.deviceId})');
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ switchCamera failed: $e');
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
    if (_screenShareToggleInFlight) return;
    _screenShareToggleInFlight = true;
    final target = !_screenShareEnabled;
    try {
      if (target) {
        if (kDebugMode) debugPrint('🖥️  Bildschirm-Teilen wird angefragt …');
        // Foreground-Service muss VOR setScreenShareEnabled laufen,
        // sonst lehnt Android die MediaProjection ab.
        try {
          if (!await FlutterBackground.hasPermissions) {
            await FlutterBackground.initialize(
              androidConfig: const FlutterBackgroundAndroidConfig(
                notificationTitle: 'Bildschirm wird geteilt',
                notificationText:
                    'Weltenbibliothek teilt deinen Bildschirm im Anruf.',
                enableWifiLock: true,
              ),
            );
          }
          final ok = await FlutterBackground.enableBackgroundExecution();
          if (kDebugMode) {
            debugPrint('🖥️  Foreground-Service: ${ok ? "OK" : "FAIL"}');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Foreground-Service init failed: $e — '
                'Bildschirm-Teilen funktioniert vermutlich nicht');
          }
        }
        // setScreenShareEnabled triggert das System-Permission-Popup.
        // Hard-Timeout: User könnte Popup ignorieren oder schließen.
        await lp.setScreenShareEnabled(true).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            if (kDebugMode) debugPrint('⚠️ setScreenShareEnabled Timeout');
          },
        );
      } else {
        // Beim AUS-Schalten: ScreenShare-Track unpublishen
        for (final pub in lp.videoTrackPublications.toList()) {
          if (pub.source != TrackSource.screenShareVideo) continue;
          try {
            await lp.removePublishedTrack(pub.sid).timeout(
                const Duration(seconds: 3));
          } catch (_) {}
        }
        try {
          await FlutterBackground.disableBackgroundExecution();
        } catch (_) {}
      }
      _screenShareEnabled = target;
      if (kDebugMode) {
        debugPrint('🖥️  Screen-Share ist jetzt ${target ? "AN" : "AUS"}');
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ toggleScreenShare error: $e');
      _errorMessage = _friendlyError(e);
      notifyListeners();
    } finally {
      _screenShareToggleInFlight = false;
    }
  }

  bool _screenShareToggleInFlight = false;

  /// Hand heben / senken. Sync via participant.setAttributes — alle
  /// Teilnehmer sehen den Status via ParticipantAttributesChangedEvent.
  Future<void> toggleHandRaised() async {
    if (!isConnected) return;
    final lp = _room?.localParticipant;
    if (lp == null) return;
    final target = !_handRaised;
    try {
      // setAttributes returnt void in livekit_client 2.4 — kein await
      lp.setAttributes({
        ...lp.attributes,
        'handRaised': target ? 'true' : 'false',
      });
      _handRaised = target;
      if (kDebugMode) {
        debugPrint('✋ Hand ${target ? "gehoben" : "gesenkt"} '
            '(broadcast an alle Teilnehmer)');
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ toggleHandRaised setAttributes failed: $e');
      }
      _errorMessage = _friendlyError(e);
      notifyListeners();
    }
  }

  /// Prüft ob ein Remote-Teilnehmer die Hand gehoben hat (für UI).
  bool isRemoteHandRaised(String identity) {
    final r = _room;
    if (r == null) return false;
    final p = r.remoteParticipants.values
        .where((p) => p.identity == identity)
        .firstOrNull;
    if (p == null) return false;
    return p.attributes['handRaised'] == 'true';
  }

  /// Liefert die Avatar-URL eines Remote-Teilnehmers (aus Attributes).
  /// Returns null wenn nicht gesetzt.
  String? remoteAvatarUrl(String identity) {
    final r = _room;
    if (r == null) return null;
    final p = r.remoteParticipants.values
        .where((p) => p.identity == identity)
        .firstOrNull;
    if (p == null) return null;
    final url = p.attributes['avatarUrl'];
    return (url != null && url.isNotEmpty) ? url : null;
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
