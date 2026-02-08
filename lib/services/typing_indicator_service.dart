import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Typing Indicator Service
/// Verwaltet "User tippt..." Status
class TypingIndicatorService {
  final Map<String, Set<String>> _typingUsers = {}; // roomId -> Set<username>
  final Map<String, Timer?> _timeouts = {}; // userId -> timeout timer
  
  final _typingController = StreamController<Map<String, Set<String>>>.broadcast();
  Stream<Map<String, Set<String>>> get typingStream => _typingController.stream;
  
  /// User beginnt zu tippen
  void startTyping(String roomId, String username) {
    if (!_typingUsers.containsKey(roomId)) {
      _typingUsers[roomId] = {};
    }
    
    _typingUsers[roomId]!.add(username);
    _notifyListeners();
    
    // Auto-Stop nach 3 Sekunden
    _timeouts[username]?.cancel();
    _timeouts[username] = Timer(const Duration(seconds: 3), () {
      stopTyping(roomId, username);
    });
    
    if (kDebugMode) {
      debugPrint('⌨️ $username tippt in $roomId');
    }
  }
  
  /// User hört auf zu tippen
  void stopTyping(String roomId, String username) {
    _typingUsers[roomId]?.remove(username);
    _timeouts[username]?.cancel();
    _timeouts.remove(username);
    _notifyListeners();
    
    if (kDebugMode) {
      debugPrint('⌨️ $username hat aufgehört zu tippen in $roomId');
    }
  }
  
  /// Hole tippende User für einen Raum
  Set<String> getTypingUsers(String roomId) {
    return _typingUsers[roomId] ?? {};
  }
  
  /// Formatiere Typing-Text
  String getTypingText(String roomId, String currentUsername) {
    final users = getTypingUsers(roomId)
        .where((u) => u != currentUsername)
        .toList();
    
    if (users.isEmpty) return '';
    if (users.length == 1) return '${users[0]} tippt...';
    if (users.length == 2) return '${users[0]} und ${users[1]} tippen...';
    return '${users.length} Personen tippen...';
  }
  
  void _notifyListeners() {
    _typingController.add(Map.from(_typingUsers));
  }
  
  void dispose() {
    _typingController.close();
    for (var timer in _timeouts.values) {
      timer?.cancel();
    }
  }
}
