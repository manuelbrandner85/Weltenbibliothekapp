import 'package:flutter/foundation.dart';
import '../services/webrtc_service.dart';

/// WebRTCProvider - Provider Wrapper für WebRTCService
///
/// Bietet globalen Zugriff auf WebRTC Service via Provider Pattern.
///
/// Usage:
/// ```dart
/// // In main.dart:
/// MultiProvider(
///   providers: [
///     ChangeNotifierProvider(create: (_) => WebRTCProvider()),
///   ],
/// )
///
/// // In Widgets:
/// final webrtc = Provider.of<WebRTCProvider>(context);
/// final webrtc = context.watch<WebRTCProvider>();
/// ```

class WebRTCProvider extends ChangeNotifier {
  final WebRTCService _service = WebRTCService();

  // NEW: Room-specific streaming state
  final Map<String, bool> _roomStreams = {};
  String? _pipRoomId;

  // ═══════════════════════════════════════════════════════════════════════════
  // DELEGATED GETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  WebRTCService get service => _service;

  bool get isInitialized => _service.isInitialized;
  bool get isInChannel => _service.isInChannel;
  bool get isCameraEnabled => _service.isCameraEnabled;
  bool get isMicEnabled => _service.isMicEnabled;
  bool get isMicrophoneMuted => _service.isMicrophoneMuted;
  bool get isMinimized => _service.isMinimized;
  bool get isPictureInPicture => _service.isPictureInPicture;

  String? get currentChannel => _service.currentChannel;
  String? get currentChannelId => _service.currentChannelId;
  String? get lastError => _service.lastError;

  Map<int, bool> get remoteUsers => _service.remoteUsers;

  // NEW: PiP state
  String? get pipRoomId => _pipRoomId;
  bool get hasPiP => _pipRoomId != null;

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  WebRTCProvider() {
    // Listen to service changes
    _service.addListener(_onServiceChanged);
  }

  void _onServiceChanged() {
    notifyListeners();
  }

  Future<void> initialize() async {
    await _service.initialize();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DELEGATED METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> joinChannel(String channelId, int uid) async {
    await _service.joinChannel(channelId, uid);
    notifyListeners();
  }

  Future<void> leaveChannel() async {
    await _service.leaveChannel();
    notifyListeners();
  }

  Future<void> enableCamera() async {
    await _service.enableCamera();
    notifyListeners();
  }

  Future<void> disableCamera() async {
    await _service.disableCamera();
    notifyListeners();
  }

  Future<void> switchCamera() async {
    await _service.switchCamera();
  }

  Future<void> toggleMicrophone() async {
    await _service.toggleMicrophone();
    notifyListeners();
  }

  void setMinimized(bool minimized) {
    _service.setMinimized(minimized);
    notifyListeners();
  }

  void toggleMinimized() {
    _service.toggleMinimized();
  }

  void minimizeVideo() {
    _service.minimizeVideo();
  }

  void maximizeVideo() {
    _service.maximizeVideo();
  }

  Future<void> muteMicrophone() async {
    await _service.muteMicrophone();
    notifyListeners();
  }

  Future<void> unmuteMicrophone() async {
    await _service.unmuteMicrophone();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NEW: ROOM-SPECIFIC STREAMING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Start streaming in a specific room
  /// WICHTIG: Kamera ist standardmäßig AUS (nur Audio)
  Future<void> startRoomStream(String roomId) async {
    // Initialize WebRTC if needed
    if (!_service.isInitialized) {
      await initialize();
    }

    // Join WebRTC channel for this room
    final uid = DateTime.now().millisecondsSinceEpoch % 1000000;
    await _service.joinChannel('room_$roomId', uid);

    // KAMERA STANDARDMÄSSIG AUS - Nur Audio aktiviert!
    // User kann Kamera später manuell einschalten
    if (_service.isCameraEnabled) {
      await _service.disableCamera();
    }

    _roomStreams[roomId] = true;
    notifyListeners();
  }

  /// Stop streaming in a specific room
  Future<void> stopRoomStream(String roomId) async {
    // Leave WebRTC channel
    if (_service.isInChannel) {
      await _service.leaveChannel();
    }

    _roomStreams[roomId] = false;
    if (_pipRoomId == roomId) {
      _pipRoomId = null;
    }
    notifyListeners();
  }

  /// Check if streaming in a specific room
  bool isStreaming(String roomId) {
    return _roomStreams[roomId] ?? false;
  }

  /// Enable PiP mode for a room
  void enablePiP(String roomId) {
    if (_roomStreams[roomId] == true) {
      _pipRoomId = roomId;
      notifyListeners();
    }
  }

  /// Disable PiP mode
  void disablePiP() {
    _pipRoomId = null;
    notifyListeners();
  }

  /// Get all active room streams
  List<String> getActiveRoomStreams() {
    return _roomStreams.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    _service.dispose();
    _roomStreams.clear();
    _pipRoomId = null;
    super.dispose();
  }
}
