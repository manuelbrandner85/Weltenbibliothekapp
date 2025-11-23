import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../services/local_storage_service.dart';

/// Chat Provider für Kanäle und Nachrichten
class ChatProvider extends ChangeNotifier {
  // ignore: unused_field
  final LocalStorageService _localStorage;

  List<ChannelModel> _channels = [];
  final Map<String, List<MessageModel>> _messages = {};

  ChatProvider({required LocalStorageService localStorage})
    : _localStorage = localStorage {
    _initializeChannels();
  }

  // Getters
  List<ChannelModel> get channels => _channels;

  /// Kanäle initialisieren mit Mock-Daten
  void _initializeChannels() {
    _channels = [
      ChannelModel(
        id: 'channel_1',
        name: '🏛️ Alte Mysterien',
        description:
            'Diskussionen über antike Geheimnisse und verlorene Zivilisationen',
        category: 'mystery',
        memberCount: 1247,
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
        isPinned: true,
        unreadCount: 3,
        lastMessage: MessageModel(
          id: 'msg_1',
          channelId: 'channel_1',
          senderId: 'user_2',
          senderName: 'Dr. Archaeo',
          content: 'Neue Entdeckungen in Ägypten deuten auf...',
          type: MessageType.text,
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
          likes: 12,
          likedBy: [],
        ),
      ),
      ChannelModel(
        id: 'channel_2',
        name: '🛸 UFO & Aliens',
        description: 'Außerirdische Phänomene und ungeklärte Sichtungen',
        category: 'conspiracy',
        memberCount: 2891,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        unreadCount: 7,
        lastMessage: MessageModel(
          id: 'msg_2',
          channelId: 'channel_2',
          senderId: 'user_3',
          senderName: 'TruthSeeker',
          content: 'Pentagon bestätigt neue UFO-Videos!',
          type: MessageType.text,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          likes: 24,
          likedBy: [],
        ),
      ),
      ChannelModel(
        id: 'channel_3',
        name: '📜 Verbotenes Wissen',
        description: 'Zensierte Dokumente und geheime Archive',
        category: 'document',
        memberCount: 892,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        unreadCount: 0,
        lastMessage: MessageModel(
          id: 'msg_3',
          channelId: 'channel_3',
          senderId: 'user_4',
          senderName: 'Archivar',
          content: 'Neues geleaktes CIA-Dokument hochgeladen',
          type: MessageType.document,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          likes: 45,
          likedBy: [],
        ),
      ),
      ChannelModel(
        id: 'channel_4',
        name: '🔬 Wissenschaft & Forschung',
        description: 'Aktuelle Forschung und wissenschaftliche Durchbrüche',
        category: 'science',
        memberCount: 3421,
        createdAt: DateTime.now().subtract(const Duration(days: 540)),
        unreadCount: 1,
        lastMessage: MessageModel(
          id: 'msg_4',
          channelId: 'channel_4',
          senderId: 'user_5',
          senderName: 'Prof. Nova',
          content: 'Neue Quantencomputer-Ergebnisse sind verblüffend!',
          type: MessageType.text,
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          likes: 18,
          likedBy: [],
        ),
      ),
      ChannelModel(
        id: 'channel_5',
        name: '🗺️ Weltweite Events',
        description: 'Historische Ereignisse auf der Weltkarte',
        category: 'history',
        memberCount: 1653,
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
        isPinned: true,
        unreadCount: 0,
        lastMessage: MessageModel(
          id: 'msg_5',
          channelId: 'channel_5',
          senderId: 'user_6',
          senderName: 'Historiker',
          content: 'Neuer Event-Marker in Peru hinzugefügt',
          type: MessageType.location,
          timestamp: DateTime.now().subtract(const Duration(hours: 8)),
          likes: 8,
          likedBy: [],
        ),
      ),
    ];

    // Mock-Nachrichten für jeden Kanal
    for (final channel in _channels) {
      _messages[channel.id] = _generateMockMessages(channel);
    }

    notifyListeners();
  }

  /// Mock-Nachrichten generieren
  List<MessageModel> _generateMockMessages(ChannelModel channel) {
    final now = DateTime.now();
    return [
      MessageModel(
        id: 'msg_${channel.id}_1',
        channelId: channel.id,
        senderId: 'user_1',
        senderName: 'Admin',
        content: 'Willkommen im Kanal "${channel.name}"! 👋',
        type: MessageType.text,
        timestamp: now.subtract(const Duration(days: 7)),
        likes: 15,
        likedBy: [],
      ),
      MessageModel(
        id: 'msg_${channel.id}_2',
        channelId: channel.id,
        senderId: 'user_2',
        senderName: 'Forscher',
        content: 'Danke für die Einladung! Gibt es schon konkrete Themen?',
        type: MessageType.text,
        timestamp: now.subtract(const Duration(days: 6, hours: 12)),
        likes: 8,
        likedBy: [],
      ),
      MessageModel(
        id: 'msg_${channel.id}_3',
        channelId: channel.id,
        senderId: 'current_user',
        senderName: 'Du',
        content: 'Ich freue mich auf den Austausch hier!',
        type: MessageType.text,
        timestamp: now.subtract(const Duration(days: 6)),
        likes: 5,
        likedBy: [],
      ),
      if (channel.lastMessage != null) channel.lastMessage!,
    ];
  }

  /// Nachrichten für einen Kanal abrufen
  List<MessageModel> getChannelMessages(String channelId) {
    return _messages[channelId] ?? [];
  }

  /// Nachricht senden
  Future<void> sendMessage({
    required String channelId,
    required String content,
    required MessageType type,
    String? mediaUrl,
  }) async {
    final message = MessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      channelId: channelId,
      senderId: 'current_user',
      senderName: 'Du',
      content: content,
      type: type,
      mediaUrl: mediaUrl,
      timestamp: DateTime.now(),
      likes: 0,
      likedBy: [],
    );

    _messages[channelId] = [...(_messages[channelId] ?? []), message];

    // Kanal aktualisieren
    final channelIndex = _channels.indexWhere((c) => c.id == channelId);
    if (channelIndex != -1) {
      _channels[channelIndex] = ChannelModel(
        id: _channels[channelIndex].id,
        name: _channels[channelIndex].name,
        description: _channels[channelIndex].description,
        avatarUrl: _channels[channelIndex].avatarUrl,
        category: _channels[channelIndex].category,
        memberCount: _channels[channelIndex].memberCount,
        createdAt: _channels[channelIndex].createdAt,
        lastMessage: message,
        isPinned: _channels[channelIndex].isPinned,
        isMuted: _channels[channelIndex].isMuted,
        unreadCount: 0,
      );
    }

    notifyListeners();
  }

  /// Kanal anheften/lösen
  void togglePin(String channelId) {
    final index = _channels.indexWhere((c) => c.id == channelId);
    if (index != -1) {
      final channel = _channels[index];
      _channels[index] = ChannelModel(
        id: channel.id,
        name: channel.name,
        description: channel.description,
        avatarUrl: channel.avatarUrl,
        category: channel.category,
        memberCount: channel.memberCount,
        createdAt: channel.createdAt,
        lastMessage: channel.lastMessage,
        isPinned: !channel.isPinned,
        isMuted: channel.isMuted,
        unreadCount: channel.unreadCount,
      );

      // Pinned Kanäle nach oben sortieren
      _channels.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.lastMessage?.timestamp.compareTo(
              a.lastMessage?.timestamp ?? DateTime.now(),
            ) ??
            0;
      });

      notifyListeners();
    }
  }

  /// Kanal stummschalten/aktivieren
  void toggleMute(String channelId) {
    final index = _channels.indexWhere((c) => c.id == channelId);
    if (index != -1) {
      final channel = _channels[index];
      _channels[index] = ChannelModel(
        id: channel.id,
        name: channel.name,
        description: channel.description,
        avatarUrl: channel.avatarUrl,
        category: channel.category,
        memberCount: channel.memberCount,
        createdAt: channel.createdAt,
        lastMessage: channel.lastMessage,
        isPinned: channel.isPinned,
        isMuted: !channel.isMuted,
        unreadCount: channel.unreadCount,
      );
      notifyListeners();
    }
  }

  /// Nachricht liken
  void likeMessage(String channelId, String messageId) {
    final messages = _messages[channelId];
    if (messages != null) {
      final index = messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final message = messages[index];
        final isLiked = message.likedBy.contains('current_user');

        messages[index] = MessageModel(
          id: message.id,
          channelId: message.channelId,
          senderId: message.senderId,
          senderName: message.senderName,
          senderAvatar: message.senderAvatar,
          type: message.type,
          content: message.content,
          mediaUrl: message.mediaUrl,
          timestamp: message.timestamp,
          isRead: message.isRead,
          likes: isLiked ? message.likes - 1 : message.likes + 1,
          likedBy: isLiked
              ? message.likedBy.where((id) => id != 'current_user').toList()
              : [...message.likedBy, 'current_user'],
        );

        notifyListeners();
      }
    }
  }
}
