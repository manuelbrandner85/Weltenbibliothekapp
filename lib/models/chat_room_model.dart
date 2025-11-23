/// ChatRoom Model - Repräsentiert einen Chat-Raum
class ChatRoom {
  final String id;
  final String name;
  final String description;
  final String type; // 'fixed' oder 'user_created'
  final String? createdBy; // User ID des Erstellers
  final DateTime createdAt;
  final int memberCount;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String emoji;
  final bool isFixed; // Fixe Gruppen können nicht gelöscht werden

  // Thematische Hintergrund-Konfiguration
  String get backgroundTheme {
    // Mapping von Chat-ID zu Hintergrund-Thema
    final themeMap = {
      'room_mystery': 'mystery', // Mysterien & Rätsel
      'room_wisdom': 'wisdom', // Weisheit & Philosophie
      'room_alchemy': 'alchemy', // Alchemie & Transformation
      'room_cosmos': 'cosmos', // Kosmos & Sterne
      'room_nature': 'nature', // Natur & Elemente
      'room_ancient': 'ancient', // Antike Zivilisationen
      'room_energy': 'energy', // Energie & Frequenzen
      'room_art': 'art', // Kunst & Kreativität
      'general': 'library', // Allgemeiner Chat
      'music': 'music', // Musik-Chat
    };
    return themeMap[id] ?? 'library'; // Standard: Bibliothek
  }

  ChatRoom({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.createdBy,
    required this.createdAt,
    this.memberCount = 0,
    this.lastMessage,
    this.lastMessageTime,
    this.emoji = '💬',
    this.isFixed = false,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> data) {
    // Parse is_fixed - kann int (0/1) oder bool sein
    final isFixedValue = data['is_fixed'];
    final bool isFixedParsed;
    if (isFixedValue is int) {
      isFixedParsed = isFixedValue == 1;
    } else if (isFixedValue is bool) {
      isFixedParsed = isFixedValue;
    } else {
      isFixedParsed = false;
    }

    return ChatRoom(
      id: data['id'] as String,
      name: data['name'] as String,
      description: data['description'] as String,
      type: data['type'] as String,
      createdBy: data['created_by'] as String?,
      createdAt: DateTime.parse(data['created_at'] as String),
      memberCount: data['member_count'] as int? ?? 0,
      lastMessage: data['last_message'] as String?,
      lastMessageTime: data['last_message_time'] != null
          ? DateTime.parse(data['last_message_time'] as String)
          : null,
      emoji: data['emoji'] as String? ?? '💬',
      isFixed: isFixedParsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'member_count': memberCount,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'emoji': emoji,
      'is_fixed': isFixed,
    };
  }

  /// Erstellt fixe Chat-Gruppen
  static List<ChatRoom> getFixedChatRooms() {
    return [
      ChatRoom(
        id: 'general',
        name: 'Allgemeiner Chat',
        description:
            'Zentraler Treffpunkt für alle Benutzer der Weltenbibliothek',
        type: 'fixed',
        createdAt: DateTime(2025, 1, 1),
        emoji: '🌍',
        isFixed: true,
        memberCount: 0,
      ),
      ChatRoom(
        id: 'music',
        name: 'Musik-Chat',
        description:
            'Diskussionen über Musik, Künstler und musikalische Geheimnisse',
        type: 'fixed',
        createdAt: DateTime(2025, 1, 1),
        emoji: '🎵',
        isFixed: true,
        memberCount: 0,
      ),
    ];
  }
}
