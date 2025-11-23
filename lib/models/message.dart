/// Message Model - Repräsentiert eine Chat-Nachricht
class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final String type; // 'text', 'image', 'video'
  final String? mediaUrl;
  final bool isEdited; // Neue Eigenschaft
  final DateTime? updatedAt; // Neue Eigenschaft

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.type = 'text',
    this.mediaUrl,
    this.isEdited = false,
    this.updatedAt,
  });

  factory Message.fromJson(Map<String, dynamic> data) {
    // API sendet 'created_at', aber Model verwendet 'timestamp'
    final timestampStr =
        data['created_at'] as String? ?? data['timestamp'] as String?;
    final updatedAtStr = data['updated_at'] as String?;
    final isEditedInt = data['is_edited'] as int?;

    return Message(
      id: data['id'] as String,
      senderId: data['sender_id'] as String,
      senderName: data['sender_name'] as String,
      content: data['content'] as String,
      timestamp: timestampStr != null
          ? DateTime.parse(timestampStr)
          : DateTime.now(),
      type: data['type'] as String? ?? 'text',
      mediaUrl: data['media_url'] as String?,
      isEdited: isEditedInt == 1,
      updatedAt: updatedAtStr != null ? DateTime.parse(updatedAtStr) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'media_url': mediaUrl,
      'is_edited': isEdited ? 1 : 0,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
