/// 💬 CHAT ROOM CONTROLLER
/// 
/// Supabase Realtime + Offline-First mit LocalChatStorageService
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/state/chat_room_state.dart';
import '../models/chat_models.dart';
import '../services/supabase_service.dart';         // 🟢 Supabase Backend
import '../services/local_chat_storage_service.dart'; // 📦 Offline-Fallback

class ChatRoomController extends ChangeNotifier {
  ChatRoomState _state = const ChatRoomState();
  
  final String roomId;
  Timer? _typingTimer;
  Timer? _messagePollingTimer;
  
  ChatRoomController({required this.roomId}) {
    _initialize();
  }
  
  ChatRoomState get state => _state;
  
  // Realtime-Subscription
  dynamic _realtimeChannel;

  Future<void> _initialize() async {
    // 📦 Offline-Storage initialisieren
    await LocalChatStorageService().initialize();
    try {
      await loadMessages();
      _subscribeRealtime();
      // ✅ Alle Nachrichten beim Öffnen als gelesen markieren
      await markAllAsRead();
    } catch (e) {
      _state = _state.copyWith(error: 'Failed to initialize: $e');
      notifyListeners();
    }
  }

  /// 🟢 Realtime-Subscription: Nachrichten + Typing + Read-Receipts
  void _subscribeRealtime() {
    try {
      _realtimeChannel = SupabaseChatService.instance.subscribeToRoomFull(
        roomId,
        onMessage: (data) {
          final msgId = data['id'] as String? ?? 'rt_${DateTime.now().millisecondsSinceEpoch}';
          final readBy = (data['read_by'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [];

          // Existierende Nachricht aktualisieren (z.B. read_by oder edit)
          final existingIndex = _state.messages.indexWhere((m) => m.id == msgId);
          if (existingIndex >= 0) {
            final updated = _state.messages[existingIndex].copyWith(
              content: data['content'] as String? ?? data['message'] as String?
                  ?? _state.messages[existingIndex].content,
              readBy: readBy.isNotEmpty ? readBy : _state.messages[existingIndex].readBy,
              editedAt: data['edited_at'] != null
                  ? DateTime.tryParse(data['edited_at'] as String)
                  : _state.messages[existingIndex].editedAt,
            );
            final msgs = List<ChatMessage>.from(_state.messages);
            msgs[existingIndex] = updated;
            _state = _state.copyWith(messages: msgs);
            notifyListeners();
            return;
          }

          // Neue Nachricht einfügen
          final msg = ChatMessage.text(
            id: msgId,
            senderId: data['user_id'] as String? ?? 'unknown',
            senderName: data['username'] as String? ?? 'Anonym',
            content: data['message'] as String? ?? data['content'] as String? ?? '',
            timestamp: data['created_at'] != null
                ? DateTime.tryParse(data['created_at'] as String) ?? DateTime.now()
                : DateTime.now(),
          ).copyWith(readBy: readBy);

          _state = _state.copyWith(messages: [..._state.messages, msg]);
          notifyListeners();

          // Neue Nachricht sofort als gelesen markieren
          _markIncomingMessageAsRead(msg);
        },
        onTyping: (userId, username, isTyping) {
          final currentUserId = Supabase.instance.client.auth.currentUser?.id;
          if (userId == currentUserId) return; // eigene Typing-Events ignorieren
          if (isTyping) {
            handleUserTyping(userId);
          } else {
            final removed = Set<String>.from(_state.typingUsers)..remove(userId);
            _state = _state.copyWith(typingUsers: removed);
            notifyListeners();
          }
        },
        onRead: (messageId, userId) {
          // read_by in lokaler State aktualisieren
          final idx = _state.messages.indexWhere((m) => m.id == messageId);
          if (idx >= 0) {
            final msg = _state.messages[idx];
            if (!msg.readBy.contains(userId)) {
              final updated = msg.copyWith(readBy: [...msg.readBy, userId]);
              final msgs = List<ChatMessage>.from(_state.messages);
              msgs[idx] = updated;
              _state = _state.copyWith(messages: msgs);
              notifyListeners();
            }
          }
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Chat] Realtime subscribe failed: $e');
    }
  }

  /// Eingehende Nachricht sofort als gelesen markieren (wenn nicht eigene)
  void _markIncomingMessageAsRead(ChatMessage msg) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null || msg.senderId == currentUserId) return;
    SupabaseChatService.instance.markMessageAsRead(
      messageId: msg.id,
      userId: currentUserId,
    );
  }

  /// Alle Nachrichten im Raum als gelesen markieren (beim Öffnen des Chats)
  Future<void> markAllAsRead() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;
    await SupabaseChatService.instance.markRoomMessagesAsRead(
      roomId: roomId,
      userId: currentUserId,
    );
    // Lokalen State aktualisieren
    final msgs = _state.messages.map((m) {
      if (!m.readBy.contains(currentUserId)) {
        return m.copyWith(readBy: [...m.readBy, currentUserId]);
      }
      return m;
    }).toList();
    _state = _state.copyWith(messages: msgs);
    notifyListeners();
  }
  
  Future<void> loadMessages({bool loadMore = false}) async {
    if (_state.isLoading || (!loadMore && _state.messages.isNotEmpty)) return;
    
    try {
      _state = _state.copyWith(isLoading: true);
      notifyListeners();
      
      final newMessages = await _fetchMessagesFromServer(
        before: loadMore && _state.messages.isNotEmpty 
            ? _state.messages.first.timestamp
            : null,
      );
      
      _state = _state.copyWith(
        messages: loadMore 
            ? [...newMessages, ..._state.messages]
            : newMessages,
        isLoading: false,
        hasMore: newMessages.length >= 20,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Failed to load messages: $e',
      );
      notifyListeners();
    }
  }
  
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      final userId = currentUser?.id ?? 'anon_${DateTime.now().millisecondsSinceEpoch}';
      final username = currentUser?.userMetadata?['username'] as String?
          ?? currentUser?.email?.split('@').first
          ?? 'Anonym';
      final tempMessage = ChatMessage.text(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        senderId: userId,
        senderName: username,
        content: content.trim(),
        timestamp: DateTime.now(),
        replyToMessageId: _state.replyToMessage?['id'],
        replyToContent: _state.replyToMessage?['content'],
        replyToSenderName: _state.replyToMessage?['senderName'],
      );
      
      _state = _state.copyWith(
        messages: [..._state.messages, tempMessage],
        replyToMessage: null,
      );
      notifyListeners();
      
      final sentMessage = await _sendMessageToServer(tempMessage);
      
      final updatedMessages = _state.messages.map((msg) {
        return msg.id == tempMessage.id ? sentMessage : msg;
      }).toList();
      
      _state = _state.copyWith(messages: updatedMessages);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(error: 'Failed to send message: $e');
      notifyListeners();
    }
  }
  
  Future<void> editMessage(String messageId, String newContent) async {
    try {
      await _editMessageOnServer(messageId, newContent);
      
      final updatedMessages = _state.messages.map((msg) {
        if (msg.id == messageId) {
          return msg.copyWith(
            content: newContent,
            editedAt: DateTime.now(),
          );
        }
        return msg;
      }).toList();
      
      _state = _state.copyWith(
        messages: updatedMessages,
        editingMessageId: null,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(error: 'Failed to edit message: $e');
      notifyListeners();
    }
  }
  
  Future<void> deleteMessage(String messageId) async {
    try {
      await _deleteMessageOnServer(messageId);
      
      _state = _state.copyWith(
        messages: _state.messages.where((msg) => msg.id != messageId).toList(),
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(error: 'Failed to delete message: $e');
      notifyListeners();
    }
  }
  
  Future<void> addReaction(String messageId, String emoji) async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? 'anon';
      
      final updatedReactions = Map<String, Map<String, List<String>>>.from(_state.reactions);
      final messageReactions = Map<String, List<String>>.from(
        updatedReactions[messageId] ?? {},
      );
      
      final userList = List<String>.from(messageReactions[emoji] ?? []);
      if (!userList.contains(currentUserId)) {
        userList.add(currentUserId);
      }
      messageReactions[emoji] = userList;
      updatedReactions[messageId] = messageReactions;
      
      _state = _state.copyWith(reactions: updatedReactions);
      notifyListeners();
      
      await _sendReactionToServer(messageId, emoji);
    } catch (e) {
      _state = _state.copyWith(error: 'Failed to add reaction: $e');
      notifyListeners();
    }
  }
  
  Future<void> removeReaction(String messageId, String emoji) async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? 'anon';
      
      final updatedReactions = Map<String, Map<String, List<String>>>.from(_state.reactions);
      final messageReactions = Map<String, List<String>>.from(
        updatedReactions[messageId] ?? {},
      );
      
      final userList = List<String>.from(messageReactions[emoji] ?? []);
      userList.remove(currentUserId);
      
      if (userList.isEmpty) {
        messageReactions.remove(emoji);
      } else {
        messageReactions[emoji] = userList;
      }
      
      if (messageReactions.isEmpty) {
        updatedReactions.remove(messageId);
      } else {
        updatedReactions[messageId] = messageReactions;
      }
      
      _state = _state.copyWith(reactions: updatedReactions);
      notifyListeners();
      
      await _removeReactionFromServer(messageId, emoji);
    } catch (e) {
      _state = _state.copyWith(error: 'Failed to remove reaction: $e');
      notifyListeners();
    }
  }
  
  void setReplyToMessage(ChatMessage message) {
    _state = _state.copyWith(
      replyToMessage: {
        'id': message.id,
        'content': message.content,
        'senderName': message.senderName,
      },
    );
    notifyListeners();
  }
  
  void clearReply() {
    _state = _state.copyWith(replyToMessage: null);
    notifyListeners();
  }
  
  void setEditingMessage(String messageId) {
    _state = _state.copyWith(editingMessageId: messageId);
    notifyListeners();
  }
  
  void clearEditMode() {
    _state = _state.copyWith(editingMessageId: null);
    notifyListeners();
  }
  
  void sendTypingIndicator() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;
    final userId = currentUser.id;
    final username = currentUser.userMetadata?['username'] as String?
        ?? currentUser.email?.split('@').first
        ?? 'Anonym';

    // Typing-Broadcast über Supabase Realtime senden
    SupabaseChatService.instance.sendTypingIndicator(
      roomId: roomId,
      userId: userId,
      username: username,
      isTyping: true,
    );

    // Nach 3 Sekunden Typing-Stop senden
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      SupabaseChatService.instance.sendTypingIndicator(
        roomId: roomId,
        userId: userId,
        username: username,
        isTyping: false,
      );
    });
  }
  
  void handleUserTyping(String userId) {
    final updated = Set<String>.from(_state.typingUsers)..add(userId);
    _state = _state.copyWith(typingUsers: updated);
    notifyListeners();
    
    Timer(const Duration(seconds: 5), () {
      final removed = Set<String>.from(_state.typingUsers)..remove(userId);
      _state = _state.copyWith(typingUsers: removed);
      notifyListeners();
    });
  }
  
  Future<void> toggleVoiceRoom() async {
    try {
      final newState = !_state.isInVoiceRoom;
      
      _state = _state.copyWith(
        isInVoiceRoom: newState,
        isMuted: newState ? false : _state.isMuted,
        voiceParticipants: newState ? _state.voiceParticipants : [],
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(error: 'Voice room error: $e');
      notifyListeners();
    }
  }
  
  void toggleMute() {
    _state = _state.copyWith(isMuted: !_state.isMuted);
    notifyListeners();
  }
  
  void toggleSearch() {
    _state = _state.copyWith(searchVisible: !_state.searchVisible);
    notifyListeners();
  }
  
  void clearError() {
    _state = _state.clearError();
    notifyListeners();
  }

  /// Clear all messages from the chat room
  Future<void> clearMessages() async {
    try {
      // Clear messages on server
      await _clearMessagesOnServer();
      
      // Clear local state
      _state = _state.copyWith(
        messages: [],
        reactions: {},
        typingUsers: <String>{}.toSet(),
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(error: 'Failed to clear messages: $e');
      notifyListeners();
      rethrow;
    }
  }
  
  // ignore: unused_element
  void _startMessagePolling() {
    _messagePollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pollNewMessages(),
    );
  }
  
  Future<void> _pollNewMessages() async {
    if (kDebugMode) {
      // Poll for new messages
    }
  }
  
  Future<List<ChatMessage>> _fetchMessagesFromServer({DateTime? before}) async {
    // 🟢 Versuche Supabase
    try {
      final rows = await SupabaseChatService.instance.getMessages(roomId);
      final msgs = rows.map((data) => ChatMessage.text(
        id: data['id'] as String? ?? 'srv_${DateTime.now().millisecondsSinceEpoch}',
        senderId: data['user_id'] as String? ?? 'unknown',
        senderName: data['username'] as String? ?? 'Anonym',
        content: data['message'] as String? ?? data['content'] as String? ?? '',
        timestamp: data['created_at'] != null
            ? DateTime.tryParse(data['created_at'] as String) ?? DateTime.now()
            : DateTime.now(),
      )).toList();

      // 📦 Lokal cachen für Offline-Nutzung
      final local = LocalChatStorageService();
      for (final r in rows) {
        await local.sendMessage(
          roomId: roomId,
          realm: 'materie',
          userId: r['user_id'] as String? ?? 'unknown',
          username: r['username'] as String? ?? 'Anonym',
          message: r['message'] as String? ?? r['content'] as String? ?? '',
          avatarUrl: r['avatar_url'] as String?,
        );
      }
      return msgs;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Chat] Supabase fetch failed, lade offline: $e');
      // 📦 Offline-Fallback: lokale Nachrichten zurückgeben
      try {
        final localMsgs = await LocalChatStorageService().getMessages(roomId, 'materie');
        return localMsgs.map((data) => ChatMessage.text(
          id: data['id'] as String? ?? 'local_${DateTime.now().millisecondsSinceEpoch}',
          senderId: data['userId'] as String? ?? 'unknown',
          senderName: data['username'] as String? ?? 'Anonym',
          content: data['message'] as String? ?? '',
          timestamp: data['timestamp'] != null
              ? DateTime.tryParse(data['timestamp'] as String) ?? DateTime.now()
              : DateTime.now(),
        )).toList();
      } catch (_) {
        return [];
      }
    }
  }
  
  Future<ChatMessage> _sendMessageToServer(ChatMessage message) async {
    // 📦 Immer lokal speichern (Offline-First)
    try {
      await LocalChatStorageService().sendMessage(
        roomId: roomId,
        realm: 'materie',
        userId: message.senderId,
        username: message.senderName,
        message: message.content,
      );
    } catch (_) {}

    // 🟢 Supabase: Online senden
    try {
      final sent = await SupabaseChatService.instance.sendMessage(
        roomId: roomId,
        message: message.content,
      );
      return message.copyWith(
        id: sent['id'] as String? ?? message.id,
        status: MessageStatus.sent,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Chat] Offline – Nachricht lokal gespeichert: $e');
      // Offline: lokale ID bestätigen
      return message.copyWith(
        id: 'offline_${DateTime.now().millisecondsSinceEpoch}',
        status: MessageStatus.sent,
      );
    }
  }
  
  Future<void> _editMessageOnServer(String messageId, String content) async {
    try {
      await supabase
          .from('chat_messages')
          .update({'message': content, 'edited_at': DateTime.now().toIso8601String()})
          .eq('id', messageId);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Chat] Edit failed: $e');
    }
  }
  
  Future<void> _deleteMessageOnServer(String messageId) async {
    try {
      await supabase
          .from('chat_messages')
          .update({'is_deleted': true})
          .eq('id', messageId);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Chat] Delete failed: $e');
    }
  }
  
  Future<void> _sendReactionToServer(String messageId, String emoji) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      await supabase.from('message_reactions').upsert({
        'message_id': messageId,
        'user_id': userId,
        'emoji': emoji,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Chat] Reaction send failed: $e');
    }
  }
  
  Future<void> _removeReactionFromServer(String messageId, String emoji) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      await supabase
          .from('message_reactions')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', userId)
          .eq('emoji', emoji);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Chat] Reaction remove failed: $e');
    }
  }

  /// Server call to clear all messages in the room (soft-delete via Supabase)
  Future<void> _clearMessagesOnServer() async {
    try {
      // Soft-delete: alle Nachrichten im Raum als gelöscht markieren
      await supabase
          .from('chat_messages')
          .update({'is_deleted': true})
          .eq('room_id', roomId);
    } catch (e) {
      debugPrint('⚠️ Fehler beim Löschen der Nachrichten: $e');
    }
  }
  
  @override
  void dispose() {
    _typingTimer?.cancel();
    _messagePollingTimer?.cancel();
    // 🔌 Realtime-Subscription beenden
    try {
      _realtimeChannel?.unsubscribe();
    } catch (_) {}
    super.dispose();
  }
}
