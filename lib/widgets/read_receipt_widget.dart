import 'package:flutter/material.dart';

/// Read Receipt Widget
/// Zeigt "Gelesen" Status unter Nachrichten
class ReadReceiptWidget extends StatelessWidget {
  final Map<String, dynamic> message;
  final String currentUsername;
  final bool isOwnMessage;
  
  const ReadReceiptWidget({
    super.key,
    required this.message,
    required this.currentUsername,
    required this.isOwnMessage,
  });
  
  bool _isRead() {
    final readBy = message['readBy'] as List<dynamic>?;
    if (readBy == null || readBy.isEmpty) return false;
    
    // Remove own username from readBy list
    final otherReaders = readBy
        .where((username) => username != message['username'])
        .toList();
    
    return otherReaders.isNotEmpty;
  }
  
  String _getReadText() {
    final readBy = message['readBy'] as List<dynamic>?;
    if (readBy == null || readBy.isEmpty) return 'Gesendet';
    
    final otherReaders = readBy
        .where((username) => username != message['username'])
        .cast<String>()
        .toList();
    
    if (otherReaders.isEmpty) return 'Gesendet';
    if (otherReaders.length == 1) return 'Gelesen von ${otherReaders[0]}';
    if (otherReaders.length == 2) {
      return 'Gelesen von ${otherReaders[0]} und ${otherReaders[1]}';
    }
    return 'Gelesen von ${otherReaders.length} Personen';
  }
  
  String _getReadTime() {
    final readAt = message['readAt'];
    if (readAt == null) return '';
    
    try {
      final DateTime time = readAt is String 
          ? DateTime.parse(readAt)
          : DateTime.fromMillisecondsSinceEpoch(readAt as int);
      
      final now = DateTime.now();
      final diff = now.difference(time);
      
      if (diff.inMinutes < 1) return 'Gerade eben';
      if (diff.inMinutes < 60) return 'vor ${diff.inMinutes}m';
      if (diff.inHours < 24) return 'vor ${diff.inHours}h';
      
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Only show for own messages
    if (!isOwnMessage) return const SizedBox.shrink();
    
    final isRead = _isRead();
    
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRead ? Icons.done_all : Icons.done,
            size: 14,
            color: isRead ? Colors.blue : Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 4),
          Text(
            isRead ? _getReadText() : 'Gesendet',
            style: TextStyle(
              color: isRead ? Colors.blue : Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (isRead && _getReadTime().isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              _getReadTime(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Read Receipt Manager
/// Verwaltet Read Receipts für Nachrichten
class ReadReceiptManager {
  /// Mark message as read
  static void markAsRead(Map<String, dynamic> message, String username) {
    if (message['readBy'] == null) {
      message['readBy'] = <String>[];
    }
    
    final readBy = message['readBy'] as List<dynamic>;
    
    // Don't add if already read
    if (readBy.contains(username)) return;
    
    // Add username to readBy list
    readBy.add(username);
    
    // Set read timestamp
    message['readAt'] = DateTime.now().toIso8601String();
  }
  
  /// Check if message is read by specific user
  static bool isReadBy(Map<String, dynamic> message, String username) {
    final readBy = message['readBy'] as List<dynamic>?;
    if (readBy == null) return false;
    return readBy.contains(username);
  }
  
  /// Get list of users who read the message
  static List<String> getReaders(Map<String, dynamic> message) {
    final readBy = message['readBy'] as List<dynamic>?;
    if (readBy == null) return [];
    return readBy.cast<String>().toList();
  }
}
