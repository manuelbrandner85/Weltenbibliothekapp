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
import 'dart:math' show Random;

import 'package:flutter/foundation.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/api_config.dart';
import 'cowatch_service.dart';
import 'incall_chat_service.dart';
import 'live_caption_service.dart';

/// Verbindungs-Phasen — granular damit die UI passende Indicator zeigen kann.
enum LiveKitConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// 🔁 Bundle 2 (B2): Layout-Modus für den Group-Call-Screen.
///   - gallery: alle Teilnehmer gleich groß im Grid (Standard, gut für 2-6)
///   - speaker: aktiver Sprecher GROSS, andere als kleiner Strip unten
enum LiveKitViewMode { gallery, speaker }

/// 📶 Bundle 2 (B2): Verbindungs-Qualität pro Teilnehmer.
enum LiveKitParticipantQuality {
  excellent,
  good,
  poor,
  lost,
  unknown,
}

/// 💖 Bundle 4: Reaction-Event (Send + Receive via LiveKit DataChannel).
class ReactionEvent {
  final String emoji;
  final String fromIdentity;
  final String fromName;
  final DateTime timestamp;
  const ReactionEvent({
    required this.emoji,
    required this.fromIdentity,
    required this.fromName,
    required this.timestamp,
  });
}

class LiveKitCallService extends ChangeNotifier {
  LiveKitCallService();

  Room? _room;
  EventsListener<RoomEvent>? _listener;
  Timer? _durationTimer;
  Timer? _tokenRefreshTimer;

  /// Bundle 4.5/4.6: Granulare Notifier — UI-Komponenten lauschen nur auf
  /// das, was sie wirklich brauchen. Vorher rief `notifyListeners()` bei
  /// jedem Sekunden-Tick UND bei jedem ActiveSpeaker-Update den GANZEN
  /// GroupCallScreen mit AnimatedBackground neu auf → Akku-Drain + Stottern.
  /// Jetzt:
  ///   - durationNotifier feuert pro Sekunde — nur das Timer-Label rebuildet
  ///   - speakersNotifier feuert auf Sprecher-Wechsel — nur die Tile-Glows
  final ValueNotifier<int> durationNotifier = ValueNotifier<int>(0);
  final ValueNotifier<Set<String>> speakersNotifier =
      ValueNotifier<Set<String>>(const <String>{});

  /// Letzte Connect-Parameter — gebraucht für Token-Refresh + Reconnect.
  String? _activeWorld;
  String? _activeDisplayName;
  String? _activeAvatarUrl;

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

  // 🎧 Bundle 1: Audio-Only-Modus — Kamera/Video komplett aus, spart Akku +
  // Bandbreite massiv. Ideal für lange Calls oder schwache Netze.
  // Wenn aktiv, wird beim Join die Kamera nicht mehr automatisch
  // angeboten und Camera-Toggle ist deaktiviert.
  bool _audioOnlyMode = false;
  bool get audioOnlyMode => _audioOnlyMode;

  // 🔁 Bundle 2: Layout-Modus (gallery vs. speaker-view)
  LiveKitViewMode _viewMode = LiveKitViewMode.gallery;
  LiveKitViewMode get viewMode => _viewMode;
  void setViewMode(LiveKitViewMode mode) {
    if (_viewMode == mode) return;
    _viewMode = mode;
    notifyListeners();
  }
  void toggleViewMode() {
    setViewMode(_viewMode == LiveKitViewMode.gallery
        ? LiveKitViewMode.speaker
        : LiveKitViewMode.gallery);
  }

  /// Avatar-URL des lokalen Users — wird beim Connect via setAttributes
  /// an alle Teilnehmer gebroadcastet damit ihre UI sie zeigen kann.
  String? _localAvatarUrl;
  String? get localAvatarUrl => _localAvatarUrl;

  String? _localDisplayName;

  // ── Getters ────────────────────────────────────────────────────────────────

  Room? get room => _room;
  LiveKitConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == LiveKitConnectionState.connected;
  String? get roomName => _roomName;
  String? get world => _world;
  String? get localDisplayName => _localDisplayName;
  String? get errorMessage => _errorMessage;
  int get callDurationSeconds => _callDurationSeconds;

  String? get pinnedIdentity => _pinnedIdentity;
  bool get autoSpeakerFocus => _autoSpeakerFocus;

  bool get micEnabled => _micEnabled;
  bool get cameraEnabled => _cameraEnabled;
  bool get screenShareEnabled => _screenShareEnabled;
  bool get handRaised => _handRaised;

  // 💖 Bundle 4: Floating Reactions
  // Stream von empfangenen Reactions für die Floating-Animation-Layer.
  // Jedes Event: ReactionEvent { emoji, fromIdentity, fromName, timestamp }.
  // Bewusst NICHT broadcastet zurück — wir haben Send + Empfang via
  // LiveKit DataChannel, keine zusätzliche Persistenz.
  final StreamController<ReactionEvent> _reactionsCtrl =
      StreamController<ReactionEvent>.broadcast();
  Stream<ReactionEvent> get reactionsStream => _reactionsCtrl.stream;

  /// 💖 Bundle 4: Reaction senden — broadcastet via LiveKit DataChannel
  /// an alle Teilnehmer im Raum. Selbst-Echo: das Event wird auch lokal
  /// gefeuert damit der Sender die eigene Reaction sieht.
  Future<void> sendReaction(String emoji) async {
    final room = _room;
    final lp = room?.localParticipant;
    if (room == null || lp == null) return;
    final payload = jsonEncode({
      'type': 'reaction',
      'emoji': emoji,
    });
    try {
      await lp.publishData(
        utf8.encode(payload),
        reliable: false,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ sendReaction failed: $e');
    }
    // Selbst-Echo damit der Sender die eigene Reaction sieht
    _reactionsCtrl.add(ReactionEvent(
      emoji: emoji,
      fromIdentity: lp.identity,
      fromName: lp.name.isNotEmpty ? lp.name : 'Du',
      timestamp: DateTime.now(),
    ));
  }

  /// Anzahl der entfernten Teilnehmer (ohne lokalen User).
  int get remoteParticipantCount => _room?.remoteParticipants.length ?? 0;

  /// Gesamt-Teilnehmerzahl inkl. lokalem User.
  int get totalParticipantCount =>
      remoteParticipantCount + (_room?.localParticipant != null ? 1 : 0);

  /// Liste der entfernten Teilnehmer-Namen für UI-Anzeige.
  /// Sortiert nach Identity damit die Reihenfolge stabil bleibt wenn
  /// Teilnehmer joinen/leaven (sonst springen Tiles im Grid hin und her).
  List<String> get remoteParticipantNames {
    final r = _room;
    if (r == null) return const [];
    final sorted = r.remoteParticipants.values.toList()
      ..sort((a, b) => a.identity.compareTo(b.identity));
    return sorted
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
  /// LinkedHashMap behält die Insertion-Reihenfolge → wir sortieren beim
  /// Befüllen nach Identity, damit das Grid synchron mit
  /// `remoteParticipantNames` bleibt und Tiles nicht springen.
  Map<String, VideoTrack?> get remoteVideoTracks {
    final r = _room;
    if (r == null) return const {};
    final sorted = r.remoteParticipants.values.toList()
      ..sort((a, b) => a.identity.compareTo(b.identity));
    final map = <String, VideoTrack?>{};
    for (final p in sorted) {
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

  /// 📶 Bundle 2: Verbindungs-Qualität eines Teilnehmers (für Tile-Indikator).
  /// Funktioniert für lokal + remote.
  LiveKitParticipantQuality connectionQualityFor(String identity) {
    final r = _room;
    if (r == null) return LiveKitParticipantQuality.unknown;
    final lp = r.localParticipant;
    if (lp != null && lp.identity == identity) {
      return _mapQuality(lp.connectionQuality);
    }
    final p = r.remoteParticipants.values
        .where((p) => p.identity == identity)
        .firstOrNull;
    if (p == null) return LiveKitParticipantQuality.unknown;
    return _mapQuality(p.connectionQuality);
  }

  LiveKitParticipantQuality _mapQuality(dynamic q) {
    // livekit_client.ConnectionQuality enum als String matchen damit wir
    // robust über Versions-Drift sind.
    final s = q?.toString().toLowerCase() ?? '';
    if (s.contains('excellent')) return LiveKitParticipantQuality.excellent;
    if (s.contains('good')) return LiveKitParticipantQuality.good;
    if (s.contains('poor')) return LiveKitParticipantQuality.poor;
    if (s.contains('lost')) return LiveKitParticipantQuality.lost;
    return LiveKitParticipantQuality.unknown;
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
    bool audioOnly = false,
    bool initialMicEnabled = true,
  }) async {
    // Avatar-URL + Display-Name für später (Mini-Bar & Re-Open)
    _localAvatarUrl = avatarUrl;
    _localDisplayName = displayName;
    _audioOnlyMode = audioOnly;
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

      // WICHTIG: Anon-Session NICHT abmelden — sie wird vom Chat-Screen für
      // JWT-authentifizierte Requests (Edit/Delete via Worker) benötigt.
      // Anon-Sessions stören LiveKit nicht (Token kommt von Edge Function,
      // nicht von der Supabase-Session direkt).

      // Edge Function akzeptiert sowohl echten User-Bearer-Token als auch
      // anon-key-only (Guest-Modus). Wir versuchen beide:
      //   1. Wenn echte Session vorhanden: Bearer = User-Access-Token
      //   2. Sonst: Bearer = Anon-Key (Edge-Function-Auth über apikey-Header)
      // Damit funktioniert LiveKit auch ohne Supabase-Account und es wird
      // KEIN automatischer Anonymous-Signup erzwungen.
      final session = supabase.auth.currentSession;
      final bearerToken =
          session?.accessToken ?? ApiConfig.supabaseAnonKey;
      if (kDebugMode) {
        debugPrint('🔑 LiveKit token: ${session != null ? "user-session" : "guest (anon-key)"}');
      }

      // Stabile Guest-ID (UUID-ähnlich, persistent in SharedPreferences)
      // damit Reconnects als gleicher User auftauchen UND mehrere Geräte
      // mit gleichem Display-Name nicht in Identity-Clash geraten.
      final guestId = await _getOrCreateClientGuestId();

      // Token von Supabase Edge Function holen (direkt, kein Cloudflare)
      final tokenRes = await http
          .post(
            Uri.parse(ApiConfig.livekitTokenUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $bearerToken',
              'apikey': ApiConfig.supabaseAnonKey,
            },
            body: jsonEncode({
              'roomName': roomName,
              if (displayName != null) 'displayName': displayName,
              'clientGuestId': guestId,
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

      // 🎙️ Bundle 1: High-End-Audio
      // - noiseSuppression: WebRTC RNNoise filtert Tastatur, Lüfter, Verkehr
      // - echoCancellation: verhindert Feedback wenn User über Lautsprecher hört
      // - autoGainControl: gleicht laute/leise Stimmen automatisch aus
      // - highPassFilter: filtert Frequenzen unter 80Hz (Brummen, Wind, Pop)
      // - typingNoiseDetection: erkennt + dämpft Tastatur-Klicks gezielt
      // Alle 5 zusammen: Pro-Sound-Qualität wie Krisp/Zoom — ohne Extra-Library.
      final room = Room(
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultAudioCaptureOptions: AudioCaptureOptions(
            noiseSuppression: true,
            echoCancellation: true,
            autoGainControl: true,
            highPassFilter: true,
            typingNoiseDetection: true,
          ),
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

      // Connect-Optionen mit Auto-Subscribe — sonst hören Teilnehmer einander nicht.
      // Hard-Timeout 60s: ohne den hängt die UI bei NAT/Firewall-Problemen
      // ewig in "verbinde..." weil LiveKit intern endlos retried.
      // Mobile/CGNAT-Netzwerke brauchen oft 15-25s für ICE-Gathering,
      // 30s war zu knapp für slow LTE/3G.
      //
      // ICE-Server-Config: coturn auf 72.62.154.95:3478 als TURN-Relay
      // damit User hinter symmetrischem NAT (Firmen-VPN, manche CGNAT)
      // auch durchkommen. STUN-Server (Google) als Fallback für die
      // initiale Public-IP-Erkennung.
      // Creds sind public (auch im Repo) — abuse-mitigated via coturn
      // Rate-Limits + denied-peer-ip für private Subnetze.
      await room
          .connect(
            livekitUrl,
            token,
            connectOptions: ConnectOptions(
              autoSubscribe: true,
              rtcConfiguration: const RTCConfiguration(
                iceServers: [
                  RTCIceServer(
                    urls: [
                      'turn:72.62.154.95:3478?transport=udp',
                      'turn:72.62.154.95:3478?transport=tcp',
                    ],
                    username: 'wb-turn-2026',
                    credential: 'WbCoturnRelay_a9b26485d407e7dc',
                  ),
                  RTCIceServer(urls: ['stun:stun.l.google.com:19302']),
                ],
              ),
            ),
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw Exception(
                'Verbindung zum Sprach-Server fehlgeschlagen — '
                'wahrscheinlich blockiert dein Netzwerk WebRTC. '
                'Versuche es mit WLAN/Mobilfunk-Wechsel.',
              );
            },
          );

      if (kDebugMode) {
        debugPrint('✅ LiveKit: connected — '
            'localId=${room.localParticipant?.identity}, '
            'remoteParticipants=${room.remoteParticipants.length}');
      }

      // Avatar-URL als Attribut SOFORT nach connect setzen — vor allen anderen
      // async Operationen. Sonst sehen Remote-Teilnehmer den lokalen User
      // bis zu mehrere Sekunden ohne Avatar (Race mit FG-Service-Init).
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        try {
          final lp = room.localParticipant;
          if (lp != null) {
            lp.setAttributes({
              ...lp.attributes,
              'avatarUrl': avatarUrl,
            });
          }
          if (kDebugMode) {
            debugPrint('🖼️  Avatar-URL gebroadcastet: $avatarUrl');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Avatar-broadcast failed: $e');
          }
        }
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

      // Mikrofon beim Beitritt je nach User-Wunsch aktivieren.
      // initialMicEnabled=true (Standard) → Mikrofon an.
      // initialMicEnabled=false → stumm beitreten (Zuhörer-Modus).
      try {
        await room.localParticipant?.setMicrophoneEnabled(initialMicEnabled);
        _micEnabled = initialMicEnabled;
        if (kDebugMode) {
          debugPrint(initialMicEnabled ? '🎤 Mikrofon aktiviert' : '🔇 Stumm beigetreten (Zuhörer)');
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

      // 🎙️ B8: Caption-Service mit Raum verknüpfen
      final lp2 = room.localParticipant;
      if (lp2 != null) {
        LiveCaptionService.instance.attachRoom(
          room,
          lp2.identity,
          displayName ?? lp2.identity,
        );
        CoWatchService.instance.attachRoom(room, lp2.identity);
        // 💬 In-Call-Chat anhängen
        InCallChatService.instance.attachRoom(
          room,
          lp2.identity,
          displayName ?? lp2.identity,
        );
      }

      // 🔁 Bundle 3.1: Token-Refresh-Loop starten — verhindert Auth-Verlust
      // bei langen Calls (Token-TTL 4h auf der Edge Function).
      _activeWorld = world;
      _activeDisplayName = displayName;
      _activeAvatarUrl = avatarUrl;
      _scheduleTokenRefresh(token);
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
      // Wenn Disconnect mit ICE-/Connection-Reason kommt, klare User-Meldung
      // setzen damit die UI nicht nur leer "getrennt" zeigt.
      final reasonStr = event.reason?.toString() ?? '';
      if (_connectionState == LiveKitConnectionState.connecting ||
          _connectionState == LiveKitConnectionState.reconnecting) {
        if (reasonStr.contains('iceFailure') ||
            reasonStr.contains('signalClose') ||
            reasonStr.contains('peerConnection')) {
          _errorMessage = 'Sprach-Verbindung wurde getrennt — '
              'wahrscheinlich blockiert dein Netzwerk WebRTC. '
              'Versuche es im WLAN oder mit Mobilfunk-Wechsel.';
        }
      }
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
    // 🛑 Bundle 3.5: User stoppt ScreenShare aus dem System-Notification-
    // Drawer → LocalTrackUnpublishedEvent kommt mit source=screenShareVideo.
    // UI bleibt sonst auf "Stop"-Button hängen weil _screenShareEnabled true.
    listener.on<LocalTrackUnpublishedEvent>((event) {
      if (event.publication.source == TrackSource.screenShareVideo &&
          _screenShareEnabled) {
        if (kDebugMode) {
          debugPrint('🖥️  ScreenShare extern gestoppt — UI sync');
        }
        _screenShareEnabled = false;
        // Foreground-Service auch stoppen (war nur für ScreenShare aktiv).
        FlutterBackground.disableBackgroundExecution().catchError((_) => false);
        notifyListeners();
      }
    });
    // 📶 Bundle 2: Connection-Quality wird via existierende Events refreshed
    // (TrackSubscribed / Participant-Attributes / ActiveSpeakers feuern
    // notifyListeners). Eigener Quality-Event-Listener wäre versions-fragil.

    // 💖 Bundle 4: DataChannel-Reaction empfangen → in Stream feeden.
    // Andere Geräte broadcasten via room.localParticipant.publishData mit
    // payload {"type":"reaction","emoji":"❤️"}. Wir parsen + feeden in
    // _reactionsCtrl, die ReactionsOverlay zeichnet die Floating-Animation.
    listener.on<DataReceivedEvent>((event) {
      try {
        final raw = utf8.decode(event.data);
        final data = jsonDecode(raw);
        if (data is! Map) return;
        final type = data['type'];

        // 🔦 B11: Spotlight — Host pinnt Teilnehmer für alle
        if (type == 'spotlight') {
          final identity = data['identity'] as String?;
          _pinnedIdentity = identity;
          _autoSpeakerFocus = false;
          notifyListeners();
          return;
        }
        if (type == 'spotlight_clear') {
          _pinnedIdentity = null;
          _autoSpeakerFocus = true;
          notifyListeners();
          return;
        }

        // 🎙️ B8: Caption-Event → LiveCaptionService weiterleiten
        if (type == 'caption') {
          LiveCaptionService.instance.handleIncomingData(data, event.participant);
          return;
        }

        // 📺 B10.4: Co-Watch-Event → CoWatchService weiterleiten
        if (type == 'cowatch') {
          CoWatchService.instance.handleIncomingData(data, event.participant);
          return;
        }
        // 💬 In-Call-Chat-Event
        if (type == 'incall_chat') {
          InCallChatService.instance.handleIncomingData(data, event.participant);
          return;
        }

        if (type != 'reaction') return;
        final emoji = data['emoji'];
        if (emoji is! String || emoji.isEmpty) return;
        final from = event.participant;
        _reactionsCtrl.add(ReactionEvent(
          emoji: emoji,
          fromIdentity: from?.identity ?? '?',
          fromName: (from?.name.isNotEmpty ?? false)
              ? from!.name
              : (from?.identity ?? 'Mitglied'),
          timestamp: DateTime.now(),
        ));
      } catch (_) {}
    });

    // Hand-Heben-Sync: andere User ändern Attribute → UI muss neu zeichnen.
    listener.on<ParticipantAttributesChanged>((event) {
      if (kDebugMode) {
        debugPrint('🏷️  LiveKit: ${event.participant.identity} '
            'attributes=${event.participant.attributes}');
      }
      notifyListeners();
    });
    // Active-Speakers Update — UI highlightet wer grade redet.
    // Bundle 4.6: Nur granular-Notifier feuern (nicht voller Screen-Rebuild).
    // Bundle 2 (B2): Wenn Auto-Speaker-Focus aktiv ist und kein User
    // manuell gepinnt hat → automatisch auf den aktuellen Sprecher pinnen
    // (aber nur wenn es kein lokaler User ist — sich selbst zu pinnen
    // bringt nichts).
    listener.on<ActiveSpeakersChangedEvent>((event) {
      _activeSpeakers = event.speakers.map((p) => p.identity).toSet();
      speakersNotifier.value = _activeSpeakers;

      if (_autoSpeakerFocus && event.speakers.isNotEmpty) {
        final lp = _room?.localParticipant;
        // Ersten Remote-Sprecher finden (lokalen ignorieren)
        final firstRemote = event.speakers.firstWhere(
          (p) => p.identity != (lp?.identity ?? ''),
          orElse: () => event.speakers.first,
        );
        if (firstRemote.identity != (lp?.identity ?? '')) {
          if (_pinnedIdentity != firstRemote.identity) {
            _pinnedIdentity = firstRemote.identity;
            notifyListeners();
          }
        }
      }
    });
  }

  /// Verlässt den Raum und räumt alle Ressourcen auf.
  Future<void> leaveRoom() async {
    _stopDurationTimer();
    _cancelTokenRefresh();

    // Reihenfolge wichtig (Android 14+ Policy):
    // 1) Aktive ScreenShare-Tracks unpublishen, BEVOR der Foreground-Service
    //    weg ist — sonst meldet das System "ScreenShare ohne FG-Service".
    if (_screenShareEnabled) {
      final lp = _room?.localParticipant;
      if (lp != null) {
        for (final pub in lp.videoTrackPublications.toList()) {
          if (pub.source != TrackSource.screenShareVideo) continue;
          try {
            await lp.removePublishedTrack(pub.sid).timeout(
                const Duration(seconds: 3));
          } catch (_) {}
        }
      }
    }

    // 2) Foreground-Service stoppen (genau einmal, nicht doppelt).
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

    // 🎙️ B8: Caption-Service vom Raum trennen
    LiveCaptionService.instance.detachRoom();
    // 📺 B10.4: CoWatch-Service vom Raum trennen
    CoWatchService.instance.detachRoom();
    // 💬 In-Call-Chat vom Raum trennen
    InCallChatService.instance.detachRoom();

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
    _audioOnlyMode = false;     // Reset für nächsten Join
    _cameraIndex = 0;          // 🔄 Bundle 3.4: Index für nächsten Join resetten
    _activeSpeakers = {};
    speakersNotifier.value = const <String>{};
    durationNotifier.value = 0;
    _remoteVolumes.clear();
    _localDisplayName = null;
    _localAvatarUrl = null;
    notifyListeners();
  }

  /// 🎧 Bundle 1: Audio-Only-Modus zur Laufzeit umschalten.
  /// AN: Kamera wird abgeschaltet wenn aktiv, Toggle blockiert weiter.
  /// AUS: User kann Kamera wie gewohnt aktivieren.
  /// Akku- und Bandbreiten-Ersparnis ~80% gegenüber Video.
  Future<void> toggleAudioOnlyMode() async {
    final target = !_audioOnlyMode;
    _audioOnlyMode = target;
    if (target && _cameraEnabled) {
      // Wenn Kamera aktiv ist beim Aktivieren von Audio-Only → ausschalten
      await toggleCamera();
    }
    notifyListeners();
    if (kDebugMode) {
      debugPrint('🎧 Audio-Only-Modus: ${target ? "AN" : "AUS"}');
    }
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
      bool timedOut = false;
      await lp.setMicrophoneEnabled(target).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          timedOut = true;
          if (kDebugMode) {
            debugPrint('⚠️ setMicrophoneEnabled($target) Timeout');
          }
        },
      );
      if (timedOut) {
        _errorMessage =
            'Mikrofon konnte nicht umgeschaltet werden. Bitte erneut versuchen.';
        notifyListeners();
        return;
      }
      _errorMessage = null; // Erfolg → alte Fehler löschen
      _micEnabled = target;
      notifyListeners();
    } catch (e) {
      _errorMessage = _friendlyError(e);
      notifyListeners();
    } finally {
      _micToggleInFlight = false;
    }
  }

  // 🎙️ B12: Push-to-Talk
  bool _pttActive = false;
  bool get pttActive => _pttActive;

  Future<void> pttPress() async {
    if (_pttActive) return;
    _pttActive = true;
    notifyListeners();
    if (!_micEnabled) await toggleMicrophone();
  }

  Future<void> pttRelease() async {
    if (!_pttActive) return;
    _pttActive = false;
    notifyListeners();
    if (_micEnabled) await toggleMicrophone();
  }

  bool _cameraToggleInFlight = false;

  /// Kamera ein-/ausschalten. Fragt Permission beim ersten Aktivieren.
  /// Doppel-Tap-Schutz + 5s Timeout damit UI nie ewig auf hängenden
  /// Camera-Resource-Release wartet.
  Future<void> toggleCamera() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;

    // 🎧 Bundle 1: Im Audio-Only-Modus ist Kamera-AN gesperrt
    // (Akku/Bandbreite zu schützen). Ausschalten bleibt erlaubt.
    final wantTarget = !_cameraEnabled;
    if (wantTarget && _audioOnlyMode) {
      _errorMessage = 'Audio-Only-Modus ist aktiv. Bitte zuerst deaktivieren um die Kamera zu nutzen.';
      notifyListeners();
      return;
    }

    // Doppel-Tap-Schutz: zweiter Tap während der erste läuft → ignoriere
    if (_cameraToggleInFlight) {
      if (kDebugMode) {
        debugPrint('📷 toggleCamera: schon in flight, ignore');
      }
      return;
    }
    _cameraToggleInFlight = true;
    final target = wantTarget;

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

      bool timedOut = false;
      bool partialFailure = false;
      if (target) {
        // Beim AN-Schalten: simpler Toggle mit Timeout
        await lp.setCameraEnabled(true).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            timedOut = true;
            if (kDebugMode) {
              debugPrint('⚠️ setCameraEnabled(true) Timeout');
            }
          },
        );
      } else {
        // Beim AUS-Schalten: explicit unpublish vermeidet Hang weil
        // setCameraEnabled(false) in livekit_client 2.4 manchmal auf
        // langsame Camera-Resource-Release wartet.
        // Bundle 7.2: KEIN extra `track.dispose()` — `removePublishedTrack`
        // disposed den Track selbst. Doppel-Dispose hat in der Vergangenheit
        // Native-Crash-Reports erzeugt.
        for (final pub in lp.videoTrackPublications.toList()) {
          if (pub.source != TrackSource.camera) continue;
          try {
            bool unpublishTimedOut = false;
            await lp.removePublishedTrack(pub.sid).timeout(
              const Duration(seconds: 3),
              onTimeout: () {
                unpublishTimedOut = true;
                if (kDebugMode) debugPrint('⚠️ removePublishedTrack timeout');
              },
            );
            if (unpublishTimedOut) partialFailure = true;
          } catch (e) {
            partialFailure = true;
            if (kDebugMode) debugPrint('⚠️ removePublishedTrack: $e');
          }
        }
      }

      if (timedOut || partialFailure) {
        _errorMessage = target
            ? 'Kamera konnte nicht aktiviert werden. Bitte erneut versuchen.'
            : 'Kamera-Stream konnte nicht gestoppt werden. Bitte erneut versuchen.';
        notifyListeners();
        return;
      }
      _errorMessage = null; // Erfolg → alte Fehler löschen
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

  int _cameraIndex = 0;

  /// Wechselt zwischen Front- und Back-Kamera. Nutzt flutter_webrtc um die
  /// Geräte aufzuzählen, dann LocalVideoTrack.switchCamera(deviceId).
  Future<void> switchCamera() async {
    final lp = _room?.localParticipant;
    if (lp == null || !_cameraEnabled) return;
    try {
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
      // Geräte via flutter_webrtc enumerieren (durch livekit_client mitgeliefert)
      final devices = await rtc.navigator.mediaDevices.enumerateDevices();
      final cameras = devices.where((d) => d.kind == 'videoinput').toList();
      if (cameras.length < 2) {
        _errorMessage = 'Nur eine Kamera verfügbar.';
        notifyListeners();
        return;
      }
      final prevIndex = _cameraIndex;
      _cameraIndex = (_cameraIndex + 1) % cameras.length;
      final next = cameras[_cameraIndex];
      bool timedOut = false;
      await cameraTrack.switchCamera(next.deviceId).timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          timedOut = true;
          if (kDebugMode) debugPrint('⚠️ switchCamera Timeout');
        },
      );
      if (timedOut) {
        _cameraIndex = prevIndex; // Revert damit nächster Tap wieder versucht
        _errorMessage = 'Kamera-Wechsel fehlgeschlagen. Bitte erneut versuchen.';
        notifyListeners();
        return;
      }
      _errorMessage = null;
      if (kDebugMode) {
        debugPrint('📷 Camera gewechselt → ${next.label}');
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
        // sonst lehnt Android 12+ die MediaProjection ab. Bei Fehler
        // gar nicht erst versuchen (sonst silent fail mit Krypto-Fehler).
        bool fgOk = false;
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
          fgOk = await FlutterBackground.enableBackgroundExecution();
          if (kDebugMode) {
            debugPrint('🖥️  Foreground-Service: ${fgOk ? "OK" : "FAIL"}');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Foreground-Service init failed: $e');
          }
        }
        if (!fgOk) {
          _errorMessage = 'Bildschirm-Teilen benötigt einen aktiven '
              'Hintergrund-Dienst. Bitte App-Berechtigungen prüfen.';
          notifyListeners();
          return;
        }
        // setScreenShareEnabled triggert das System-Permission-Popup.
        // Hard-Timeout: User könnte Popup ignorieren oder schließen.
        bool timedOut = false;
        await lp.setScreenShareEnabled(true).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            timedOut = true;
            if (kDebugMode) debugPrint('⚠️ setScreenShareEnabled Timeout');
          },
        );
        if (timedOut) {
          _errorMessage = 'Bildschirm-Teilen abgebrochen oder verweigert.';
          notifyListeners();
          return;
        }
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
      _errorMessage = null; // Erfolg → alte Fehler löschen
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

  // ── Active-Speaker + Lautstärke + Pin ──────────────────────────────────

  Set<String> _activeSpeakers = {};
  Set<String> get activeSpeakers => _activeSpeakers;

  bool isActiveSpeaker(String identity) =>
      _activeSpeakers.contains(identity);

  /// Lokal: pro Remote-Identity ein Multiplier 0.0..1.5 für Wiedergabe-Lautstärke.
  /// Wert 0.0 = stumm, 1.0 = normal (default), 1.5 = lauter.
  /// Wird NICHT gebroadcastet — rein lokal beim Hörer.
  final Map<String, double> _remoteVolumes = {};

  double remoteVolumeOf(String identity) =>
      _remoteVolumes[identity] ?? 1.0;

  /// Setzt lokal die Wiedergabe-Lautstärke für einen Remote-User.
  /// volume: 0.0 (stumm) bis 1.5 (laut), 1.0 = original.
  ///
  /// Implementierung in livekit_client 2.4:
  /// - 0.0 → Audio-Track unsubscribe (User hört diesen Remote nicht mehr)
  /// - > 0.0 → Audio-Track subscribe (default)
  /// Volume-Slider zwischen 0..1.5 ist UI-State, echte stufenlose
  /// Lautstärke-API ist in 2.4 nicht direkt exponiert.
  Future<void> setRemoteVolume(String identity, double volume) async {
    final v = volume.clamp(0.0, 1.5);
    _remoteVolumes[identity] = v;
    final r = _room;
    if (r == null) {
      notifyListeners();
      return;
    }
    final p = r.remoteParticipants.values
        .where((p) => p.identity == identity)
        .firstOrNull;
    if (p == null) {
      notifyListeners();
      return;
    }
    for (final pub in p.audioTrackPublications) {
      try {
        // Bundle 7.1: API-defensiv — versuche zuerst die offizielle
        // `subscribed`-Setter-API von livekit_client 2.x; fallback auf die
        // dynamische unsubscribe()/subscribe()-Methode.
        final wantSubscribed = v > 0.0;
        if (pub.subscribed != wantSubscribed) {
          var ok = false;
          try {
            // ignore: avoid_dynamic_calls
            (pub as dynamic).subscribed = wantSubscribed;
            ok = true;
          } catch (_) {}
          if (!ok) {
            try {
              if (wantSubscribed) {
                // ignore: avoid_dynamic_calls
                await (pub as dynamic).subscribe();
              } else {
                // ignore: avoid_dynamic_calls
                await (pub as dynamic).unsubscribe();
              }
            } catch (e2) {
              if (kDebugMode) {
                debugPrint('⚠️ setRemoteVolume($identity, $v) — '
                    'beide APIs fehlgeschlagen: $e2');
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ setRemoteVolume($identity, $v) failed: $e');
        }
      }
    }
    if (kDebugMode) debugPrint('🔊 Volume($identity) → $v');
    notifyListeners();
  }

  /// Toggle: 0.0 ↔ 1.0
  Future<void> toggleRemoteMute(String identity) async {
    final cur = remoteVolumeOf(identity);
    await setRemoteVolume(identity, cur > 0 ? 0.0 : 1.0);
  }

  bool isRemoteMutedLocally(String identity) =>
      (_remoteVolumes[identity] ?? 1.0) <= 0.0;

  // ── Pin / Auto-Speaker-Focus (UI-state, kein LiveKit-API-Call) ────────────

  void pinParticipant(String? identity) {
    _pinnedIdentity = identity;
    notifyListeners();
  }

  void setAutoSpeakerFocus(bool enabled) {
    _autoSpeakerFocus = enabled;
    notifyListeners();
  }

  // 🔦 B11: Spotlight — pinnt Teilnehmer für ALLE via DataChannel
  Future<void> sendSpotlight(String? identity) async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    final payload = jsonEncode(
      identity != null
          ? {'type': 'spotlight', 'identity': identity}
          : {'type': 'spotlight_clear'},
    );
    try {
      await lp.publishData(utf8.encode(payload), reliable: true);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ sendSpotlight failed: $e');
    }
    // Lokal sofort anwenden
    _pinnedIdentity = identity;
    _autoSpeakerFocus = identity == null;
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
    durationNotifier.value = 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callDurationSeconds++;
      // Nur den Duration-Notifier feuern → kein voller Screen-Rebuild mehr.
      durationNotifier.value = _callDurationSeconds;
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  /// 🔁 Bundle 3.1: Token-Refresh — verhindert "Authentifizierung erforderlich"
  /// nach 4h Call. Liest `exp` aus dem JWT und plant ein Refresh ~5 min vor
  /// Ablauf. Holt einen frischen Token von der Edge Function und gibt ihn
  /// per `Room.setE2EEEnabled` ähnlicher API an LiveKit weiter (siehe
  /// `_applyRefreshedToken`).
  void _scheduleTokenRefresh(String token) {
    _cancelTokenRefresh();
    final exp = _jwtExpEpoch(token);
    if (exp == null) {
      // Fallback: Wenn exp nicht dekodierbar ist (malformed JWT), trotzdem
      // refreshen — nach 3h30min — damit User nach 4h nicht silent disconnected.
      if (kDebugMode) {
        debugPrint('⚠️ Token-exp nicht dekodierbar → Fallback-Refresh in 3h30min');
      }
      _tokenRefreshTimer =
          Timer(const Duration(hours: 3, minutes: 30), _refreshToken);
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final secondsLeft = exp - now;
    // 5 min vor Ablauf refreshen, mindestens 30 s Vorlaufzeit lassen.
    final leadSeconds = secondsLeft - 300;
    if (leadSeconds < 30) {
      // Token läuft sehr bald ab — sofort refreshen.
      _refreshToken();
      return;
    }
    if (kDebugMode) {
      debugPrint('🔁 Token-Refresh in ${leadSeconds}s geplant (exp in ${secondsLeft}s)');
    }
    _tokenRefreshTimer = Timer(Duration(seconds: leadSeconds), _refreshToken);
  }

  void _cancelTokenRefresh() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
  }

  /// Decodiert den `exp`-Claim aus einem JWT (epoch-Sekunden) oder null.
  int? _jwtExpEpoch(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      // Base64URL → bytes → JSON → exp.
      final pad = '=' * ((4 - parts[1].length % 4) % 4);
      final json = utf8.decode(base64Url.decode(parts[1] + pad));
      final claims = jsonDecode(json) as Map<String, dynamic>;
      final exp = claims['exp'];
      if (exp is int) return exp;
      if (exp is num) return exp.toInt();
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshToken() async {
    final room = _room;
    final roomName = _roomName;
    if (room == null || roomName == null) return;
    if (kDebugMode) debugPrint('🔁 Token-Refresh: starte …');
    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      final bearerToken = session?.accessToken ?? ApiConfig.supabaseAnonKey;
      final guestId = await _getOrCreateClientGuestId();

      final res = await http.post(
        Uri.parse(ApiConfig.livekitTokenUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $bearerToken',
          'apikey': ApiConfig.supabaseAnonKey,
        },
        body: jsonEncode({
          'roomName': roomName,
          if (_activeDisplayName != null) 'displayName': _activeDisplayName,
          'clientGuestId': guestId,
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('⚠️ Token-Refresh Server-Fehler ${res.statusCode}');
        }
        // In 60s nochmal probieren — nicht abbrechen.
        _tokenRefreshTimer = Timer(const Duration(seconds: 60), _refreshToken);
        return;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final newToken = data['token'] as String?;
      if (newToken == null || newToken.isEmpty) return;

      // Versuch: LiveKit-Client `Room.updateToken(...)` ist seit 2.x verfügbar
      // (in Pre-2.5 hieß es teilweise anders). Fallback: stilles Re-Schedule.
      try {
        // ignore: avoid_dynamic_calls
        await (room as dynamic).updateToken(newToken);
        if (kDebugMode) debugPrint('✅ Token erfolgreich erneuert');
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Room.updateToken nicht verfügbar: $e — '
              'plane Re-Schedule für nächsten Refresh-Window');
        }
      }
      _scheduleTokenRefresh(newToken);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Token-Refresh fehlgeschlagen: $e');
      // Erneut probieren in 60s — kein hard-fail.
      _tokenRefreshTimer = Timer(const Duration(seconds: 60), _refreshToken);
    }
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
    // Token-Refresh-Timer war nicht abgebaut → Timer feuerte mit
    // disposed Room/State weiter und hielt Service via Closure am Leben.
    _cancelTokenRefresh();
    try {
      _listener?.dispose();
    } catch (_) {}
    try {
      _room?.disconnect();
    } catch (_) {}
    try {
      _reactionsCtrl.close();
    } catch (_) {}
    super.dispose();
  }

  /// Holt oder erstellt eine stabile Guest-ID die in SharedPreferences
  /// persistiert wird. Wird der Edge Function als clientGuestId mitgegeben
  /// damit (a) Reconnects als gleicher User erkannt werden und (b) zwei
  /// Geräte mit dem gleichen Display-Name nicht in Identity-Clash kommen.
  static const _kGuestIdKey = 'wb.livekit.client_guest_id';

  Future<String> _getOrCreateClientGuestId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? id = prefs.getString(_kGuestIdKey);
      if (id != null && id.length >= 8) return id;
      // Erzeuge neue 16-stellige zufällige ID (URL-safe)
      const alpha = 'abcdefghijklmnopqrstuvwxyz0123456789';
      final rnd = Random.secure();
      id = List.generate(16, (_) => alpha[rnd.nextInt(alpha.length)]).join();
      await prefs.setString(_kGuestIdKey, id);
      return id;
    } catch (_) {
      // Fallback: in-memory random (nicht persistent, aber besser als nichts)
      const alpha = 'abcdefghijklmnopqrstuvwxyz0123456789';
      final rnd = Random();
      return List.generate(16, (_) => alpha[rnd.nextInt(alpha.length)]).join();
    }
  }
}
