/// 🎥 LIVEKIT CALL SERVICE
///
/// Flutter-Pendant zu Mensaenas LiveRoomModal-Logik. Kapselt die komplette
/// LiveKit-Room-Funktionalität (Connect, Mic/Cam/Screen-Share, Hand-Heben,
/// Reactions, In-Call-Chat) hinter einer ChangeNotifier-API damit Flutter-UI
/// und Riverpod-Provider sauber daran anschließen können.
///
/// **Token-Flow** (1:1 wie Mensaena):
///   1. Client holt Supabase-Access-Token aus aktueller Session
///   2. POST /api/livekit/token mit { roomName, displayName }
///   3. Worker antwortet mit { token, url }
///   4. Room.connect(url, token) → live
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart';
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

/// In-Call-Chat-Nachricht (DataChannel).
@immutable
class LiveCallChatMessage {
  final String identity;
  final String displayName;
  final String text;
  final DateTime timestamp;

  const LiveCallChatMessage({
    required this.identity,
    required this.displayName,
    required this.text,
    required this.timestamp,
  });
}

/// Reaktion (Emoji) — fliegt kurz über den Bildschirm und verschwindet.
@immutable
class LiveCallReaction {
  final String identity;
  final String emoji;
  final DateTime timestamp;

  const LiveCallReaction({
    required this.identity,
    required this.emoji,
    required this.timestamp,
  });
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

  final Set<String> _raisedHands = <String>{};
  final List<LiveCallChatMessage> _chatMessages = <LiveCallChatMessage>[];
  final List<LiveCallReaction> _reactions = <LiveCallReaction>[];

  // ── Getters ────────────────────────────────────────────────────────────────

  Room? get room => _room;
  LiveKitConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == LiveKitConnectionState.connected;
  String? get roomName => _roomName;
  String? get world => _world;
  String? get errorMessage => _errorMessage;
  int get callDurationSeconds => _callDurationSeconds;

  bool get isMicOn =>
      _room?.localParticipant?.isMicrophoneEnabled() ?? false;
  bool get isCameraOn =>
      _room?.localParticipant?.isCameraEnabled() ?? false;
  bool get isScreenSharing =>
      _room?.localParticipant?.isScreenShareEnabled() ?? false;
  bool get isHandRaised {
    final id = _room?.localParticipant?.identity;
    if (id == null) return false;
    return _raisedHands.contains(id);
  }

  List<Participant> get participants {
    final r = _room;
    if (r == null) return const <Participant>[];
    final list = <Participant>[];
    final local = r.localParticipant;
    if (local != null) list.add(local);
    list.addAll(r.remoteParticipants.values);
    return list;
  }

  int get participantCount => participants.length;

  Set<String> get raisedHands => Set<String>.unmodifiable(_raisedHands);
  List<LiveCallChatMessage> get chatMessages =>
      List<LiveCallChatMessage>.unmodifiable(_chatMessages);
  List<LiveCallReaction> get reactions =>
      List<LiveCallReaction>.unmodifiable(_reactions);

  String? get pinnedIdentity => _pinnedIdentity;
  bool get autoSpeakerFocus => _autoSpeakerFocus;

  // ── Connection-Lifecycle ───────────────────────────────────────────────────

  /// Tritt einem LiveKit-Raum bei. Wirft eine Exception mit deutscher
  /// Fehlermeldung wenn der Token-Endpoint failt oder die Verbindung scheitert.
  Future<void> joinRoom({
    required String roomName,
    required String world,
    String? displayName,
  }) async {
    if (!ApiConfig.isLivekitEnabled) {
      throw Exception('Video-Call ist nicht konfiguriert (LIVEKIT_URL fehlt).');
    }
    if (_connectionState == LiveKitConnectionState.connecting ||
        _connectionState == LiveKitConnectionState.connected) {
      return;
    }

    _setState(LiveKitConnectionState.connecting);
    _roomName = roomName;
    _world = world;
    _errorMessage = null;
    _raisedHands.clear();
    _chatMessages.clear();
    _reactions.clear();
    _pinnedIdentity = null;

    try {
      final supabase = Supabase.instance.client;
      final accessToken = supabase.auth.currentSession?.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Nicht angemeldet — bitte erneut einloggen.');
      }

      // Token vom Worker holen
      final tokenRes = await http
          .post(
            Uri.parse(ApiConfig.livekitTokenUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({
              'roomName': roomName,
              if (displayName != null) 'displayName': displayName,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (tokenRes.statusCode != 200) {
        String msg = 'Token-Endpoint Fehler (${tokenRes.statusCode})';
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

      // Room mit adaptive Streaming + Dynacast (CPU/Bandbreiten-schonend)
      final roomOptions = const RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultAudioPublishOptions: AudioPublishOptions(
          dtx: true,
        ),
        defaultVideoPublishOptions: VideoPublishOptions(
          simulcast: true,
        ),
      );

      final room = Room(roomOptions: roomOptions);
      _room = room;
      _attachListener(room);

      await room.connect(livekitUrl, token);

      // Audio standardmäßig an, Video aus (User schaltet manuell ein)
      await room.localParticipant?.setMicrophoneEnabled(true);
      await room.localParticipant?.setCameraEnabled(false);

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

  /// Verlässt den Raum und räumt alle Ressourcen auf.
  Future<void> leaveRoom() async {
    _stopDurationTimer();
    try {
      await _listener?.dispose();
    } catch (_) {}
    _listener = null;
    try {
      await _room?.disconnect();
    } catch (_) {}
    _room = null;
    _connectionState = LiveKitConnectionState.disconnected;
    _roomName = null;
    _world = null;
    _errorMessage = null;
    _callDurationSeconds = 0;
    _raisedHands.clear();
    _chatMessages.clear();
    _reactions.clear();
    _pinnedIdentity = null;
    notifyListeners();
  }

  // ── Track-Toggles ─────────────────────────────────────────────────────────

  Future<void> toggleMicrophone() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    await lp.setMicrophoneEnabled(!lp.isMicrophoneEnabled());
    notifyListeners();
  }

  Future<void> toggleCamera() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    await lp.setCameraEnabled(!lp.isCameraEnabled());
    notifyListeners();
  }

  /// Front-/Back-Kamera tauschen.
  /// Funktioniert nur wenn Kamera aktuell aktiv ist. Implementierung folgt
  /// im UI-Phase-PR (sobald die Helper-API von livekit_client geprüft ist).
  Future<void> flipCamera() async {
    if (kDebugMode) debugPrint('flipCamera: kommt im UI-Phase-PR');
    notifyListeners();
  }

  /// Screen-Share an/aus. Auf Android: flutter_background Foreground-Service
  /// muss vom Caller VORHER gestartet werden (siehe LiveKitGroupCallScreen).
  Future<void> toggleScreenShare() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    await lp.setScreenShareEnabled(!lp.isScreenShareEnabled());
    notifyListeners();
  }

  // ── DataChannel-Features (Hand, Reactions, Chat) ──────────────────────────

  Future<void> toggleHandRaise() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    final id = lp.identity;
    final raised = !_raisedHands.contains(id);
    if (raised) {
      _raisedHands.add(id);
    } else {
      _raisedHands.remove(id);
    }
    notifyListeners();
    await _publishData({'type': 'raise-hand', 'raised': raised});
  }

  Future<void> sendReaction(String emoji) async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    final r = LiveCallReaction(
      identity: lp.identity,
      emoji: emoji,
      timestamp: DateTime.now(),
    );
    _reactions.add(r);
    _trimReactions();
    notifyListeners();
    await _publishData({'type': 'reaction', 'emoji': emoji});
  }

  Future<void> sendChatMessage(String text) async {
    final lp = _room?.localParticipant;
    if (lp == null || text.trim().isEmpty) return;
    final msg = LiveCallChatMessage(
      identity: lp.identity,
      displayName: lp.name.isNotEmpty ? lp.name : 'Ich',
      text: text.trim(),
      timestamp: DateTime.now(),
    );
    _chatMessages.add(msg);
    notifyListeners();
    await _publishData({'type': 'chat', 'text': text.trim()});
  }

  // ── Pin / Auto-Speaker-Focus ──────────────────────────────────────────────

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

  void _trimReactions() {
    final cutoff = DateTime.now().subtract(const Duration(seconds: 4));
    _reactions.removeWhere((r) => r.timestamp.isBefore(cutoff));
  }

  Future<void> _publishData(Map<String, dynamic> payload) async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    try {
      final bytes = utf8.encode(jsonEncode(payload));
      await lp.publishData(bytes, reliable: true);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ publishData: $e');
    }
  }

  void _attachListener(Room room) {
    _listener?.dispose();
    final l = room.createListener();
    _listener = l;

    l
      ..on<DataReceivedEvent>(_handleData)
      ..on<ParticipantConnectedEvent>((_) => notifyListeners())
      ..on<ParticipantDisconnectedEvent>((e) {
        _raisedHands.remove(e.participant.identity);
        if (_pinnedIdentity == e.participant.identity) {
          _pinnedIdentity = null;
        }
        notifyListeners();
      })
      ..on<TrackSubscribedEvent>((_) => notifyListeners())
      ..on<TrackUnsubscribedEvent>((_) => notifyListeners())
      ..on<TrackMutedEvent>((_) => notifyListeners())
      ..on<TrackUnmutedEvent>((_) => notifyListeners())
      ..on<ActiveSpeakersChangedEvent>(_handleActiveSpeakers)
      ..on<RoomReconnectingEvent>(
          (_) => _setState(LiveKitConnectionState.reconnecting))
      ..on<RoomReconnectedEvent>(
          (_) => _setState(LiveKitConnectionState.connected))
      ..on<RoomDisconnectedEvent>((_) {
        _setState(LiveKitConnectionState.disconnected);
        _stopDurationTimer();
      });
  }

  void _handleData(DataReceivedEvent event) {
    try {
      final raw = utf8.decode(event.data);
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) return;
      final type = data['type'];
      final senderId = event.participant?.identity ?? 'unknown';
      final senderName = event.participant?.name ?? '';

      switch (type) {
        case 'raise-hand':
          final raised = data['raised'] == true;
          if (raised) {
            _raisedHands.add(senderId);
          } else {
            _raisedHands.remove(senderId);
          }
          notifyListeners();
          break;
        case 'reaction':
          final emoji = (data['emoji'] as String?) ?? '👍';
          _reactions.add(LiveCallReaction(
            identity: senderId,
            emoji: emoji,
            timestamp: DateTime.now(),
          ));
          _trimReactions();
          notifyListeners();
          break;
        case 'chat':
          final text = (data['text'] as String?)?.trim();
          if (text == null || text.isEmpty) return;
          _chatMessages.add(LiveCallChatMessage(
            identity: senderId,
            displayName: senderName.isNotEmpty ? senderName : 'Mitglied',
            text: text,
            timestamp: DateTime.now(),
          ));
          notifyListeners();
          break;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ _handleData: $e');
    }
  }

  void _handleActiveSpeakers(ActiveSpeakersChangedEvent event) {
    if (!_autoSpeakerFocus) {
      notifyListeners();
      return;
    }
    final localId = _room?.localParticipant?.identity;
    final firstRemote = event.speakers.firstWhere(
      (p) => p.identity != localId,
      orElse: () => event.speakers.isNotEmpty
          ? event.speakers.first
          : (_room?.localParticipant ?? event.speakers.first),
    );
    final newPin = firstRemote.identity;
    if (newPin != _pinnedIdentity) {
      _pinnedIdentity = newPin;
    }
    notifyListeners();
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
      return 'Video-Call ist serverseitig noch nicht aktiviert.';
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
