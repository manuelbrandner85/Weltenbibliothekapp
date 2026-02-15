/// 💬 CHAT ROOM CONTROLLER (SIMPLIFIED)
/// 
/// Simplified chat controller without external dependencies
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/state/chat_room_state.dart';
import '../models/chat_models.dart';

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
        typingUsers: [],
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
  
  Future<List<ChatMessage>> _fetchMessagesFromServer({DateTime? before}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.generate(20, (index) {
      return ChatMessage.text(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_$index',
        senderId: index % 2 == 0 ? 'user1' : 'user2',
        senderName: index % 2 == 0 ? 'Alice' : 'Bob',
        content: 'Sample message $index',
        timestamp: DateTime.now().subtract(Duration(minutes: 20 - index)),
      );
    });
  }
  
  Future<ChatMessage> _sendMessageToServer(ChatMessage message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return message.copyWith(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      status: MessageStatus.sent,
    );
  }
  
  Future<void> _editMessageOnServer(String messageId, String content) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
  
  Future<void> _deleteMessageOnServer(String messageId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
  
  Future<void> _sendReactionToServer(String messageId, String emoji) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
  
  Future<void> _removeReactionFromServer(String messageId, String emoji) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Server call to clear all messages in the room
  Future<void> _clearMessagesOnServer() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: Implement actual API call when backend endpoint is ready
    // Example: await http.delete('${ApiConfig.baseUrl}/api/chat/$roomId/messages');
  }
  
  @override
  void dispose() {
    _typingTimer?.cancel();
    _messagePollingTimer?.cancel();
    super.dispose();
  }
}
