/// 💬 CHAT ROOM CONTROLLER (SIMPLIFIED)
/// 
/// Simplified chat controller without external dependencies
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/state/chat_room_state.dart';
import '../models/chat_models.dart';
import '../services/cloudflare_api_service.dart';
import '../services/webrtc_voice_service.dart';
import '../config/api_config.dart';

class ChatRoomController extends ChangeNotifier {
  ChatRoomState _state = const ChatRoomState();
  
  final String roomId;
  Timer? _typingTimer;
  Timer? _messagePollingTimer;
  
  ChatRoomController({required this.roomId}) {
    _initialize();
  }
  
  ChatRoomState get state => _state;
  
  Future<void> _initialize() async {
    try {
      await loadMessages();
      _startMessagePolling();
    } catch (e) {
      _state = _state.copyWith(error: 'Failed to initialize: $e');
      notifyListeners();
    }
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
      final tempMessage = ChatMessage.text(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        senderId: 'current_user',
        senderName: 'You',
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
      final currentUserId = 'current_user';
      
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
      final currentUserId = 'current_user';
      
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
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {});
  }
  
  // 🔧 FIX: Timer-Management für Typing Indicators (verhindert Memory Leak)
  final Map<String, Timer> _typingTimers = {};
  
  void handleUserTyping(String userId) {
    // Cancel existing timer for this user
    _typingTimers[userId]?.cancel();
    
    final updated = Set<String>.from(_state.typingUsers)..add(userId);
    _state = _state.copyWith(typingUsers: updated);
    notifyListeners();
    
    // Create new timer and store reference
    _typingTimers[userId] = Timer(const Duration(seconds: 5), () {
      final removed = Set<String>.from(_state.typingUsers)..remove(userId);
      _state = _state.copyWith(typingUsers: removed);
      _typingTimers.remove(userId);
      notifyListeners();
    });
  }
  
  // 🔧 FIX: WebRTC Voice-Chat Integration
  Future<void> toggleVoiceRoom() async {
    try {
      final newState = !_state.isInVoiceRoom;
      
      if (newState) {
        // Join voice room
        final webrtc = WebRTCVoiceService();
        await webrtc.joinRoom(
          roomId: roomId,
          userId: 'current_user', // TODO: Get from auth
          username: 'User', // TODO: Get from auth
          world: 'materie', // TODO: Get from context
        );
        
        _state = _state.copyWith(
          isInVoiceRoom: true,
          isMuted: false,
        );
      } else {
        // Leave voice room
        final webrtc = WebRTCVoiceService();
        await webrtc.leaveRoom();
        
        _state = _state.copyWith(
          isInVoiceRoom: false,
          isMuted: false,
          voiceParticipants: [],
        );
      }
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Voice room error: $e');
      }
      _state = _state.copyWith(error: 'Voice room error: $e');
      notifyListeners();
    }
  }
  
  void toggleMute() {
    try {
      final webrtc = WebRTCVoiceService();
      final newMuted = !_state.isMuted;
      
      if (newMuted) {
        webrtc.mute();
      } else {
        webrtc.unmute();
      }
      
      _state = _state.copyWith(isMuted: newMuted);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Mute toggle error: $e');
      }
    }
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
  
  // 🔧 FIX: Echte API-Integration statt Mock-Daten
  Future<List<ChatMessage>> _fetchMessagesFromServer({DateTime? before}) async {
    try {
      final api = CloudflareApiService();
      final result = await api.getChatMessages(
        roomId: roomId,
        realm: 'materie', // TODO: realm dynamisch setzen
        limit: 20,
        before: before,
      );
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to fetch messages from API: $e');
      }
      // Fallback: leere Liste statt Mock-Daten
      return [];
    }
  }
  
  Future<ChatMessage> _sendMessageToServer(ChatMessage message) async {
    try {
      final api = CloudflareApiService();
      final result = await api.sendChatMessage(
        roomId: roomId,
        realm: 'materie', // TODO: realm dynamisch setzen
        content: message.content,
        messageType: 'text',
        replyToId: message.replyToMessageId,
      );
      
      return message.copyWith(
        id: result['id'] ?? message.id,
        status: MessageStatus.sent,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to send message to API: $e');
      }
      return message.copyWith(status: MessageStatus.failed);
    }
  }
  
  Future<void> _editMessageOnServer(String messageId, String content) async {
    try {
      final api = CloudflareApiService();
      await api.updateChatMessage(
        messageId: messageId,
        content: content,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to edit message: $e');
      }
      rethrow;
    }
  }
  
  Future<void> _deleteMessageOnServer(String messageId) async {
    try {
      final api = CloudflareApiService();
      await api.deleteChatMessage(messageId: messageId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to delete message: $e');
      }
      rethrow;
    }
  }
  
  Future<void> _sendReactionToServer(String messageId, String emoji) async {
    try {
      final api = CloudflareApiService();
      await api.addReaction(
        messageId: messageId,
        emoji: emoji,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to add reaction: $e');
      }
      rethrow;
    }
  }
  
  Future<void> _removeReactionFromServer(String messageId, String emoji) async {
    try {
      final api = CloudflareApiService();
      await api.removeReaction(
        messageId: messageId,
        emoji: emoji,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to remove reaction: $e');
      }
      rethrow;
    }
  }

  /// Server call to clear all messages in the room
  Future<void> _clearMessagesOnServer() async {
    try {
      // ⚠️ TODO: Backend-Endpoint für Clear implementieren
      // Vorerst: Keine Aktion (würde 404 werfen)
      if (kDebugMode) {
        debugPrint('⚠️ Clear messages API not yet implemented');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to clear messages: $e');
      }
      rethrow;
    }
  }
  
  @override
  void dispose() {
    _typingTimer?.cancel();
    _messagePollingTimer?.cancel();
    
    // 🔧 FIX: Cancel all typing timers to prevent memory leak
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();
    
    super.dispose();
  }
}
