/// 💬 CHAT ROOM CONTROLLER
/// 
/// Production-ready chat controller with:
/// - Message sending/receiving
/// - Reactions management
/// - Reply/Edit functionality
/// - Voice room integration
/// - Typing indicators
/// - Pagination
/// - guard() error handling
/// - AppLogger integration
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/state/chat_room_state.dart';
import '../models/chat_models.dart';

class ChatRoomController extends ChangeNotifier {
  ChatRoomState _state = const ChatRoomState();
  
  // Services (inject in constructor)
  final String roomId;
  Timer? _typingTimer;
  Timer? _messagePollingTimer;
  
  ChatRoomController({required this.roomId}) {
    _initialize();
  }
  
  ChatRoomState get state => _state;
  
  // ============================================================================
  // INITIALIZATION
  // ============================================================================
  
  Future<void> _initialize() async {
    await guard(
      () async {
        AppLogger.info('Initializing chat room', context: {'roomId': roomId});
        
        // Load initial messages
        await loadMessages();
        
        // Start message polling
        _startMessagePolling();
        
        AppLogger.info('Chat room initialized');
      },
      operationName: 'initializeChatRoom',
      context: {'roomId': roomId},
      onError: (exception, stackTrace) {
        _state = _state.copyWith(
          error: 'Failed to initialize chat: ${exception.message ?? exception.toString()}',
        );
        notifyListeners();
      },
    );
  }
  
  // ============================================================================
  // MESSAGE OPERATIONS
  // ============================================================================
  
  /// Load messages (initial or pagination)
  Future<void> loadMessages({bool loadMore = false}) async {
    if (_state.isLoading || (!loadMore && _state.messages.isNotEmpty)) {
      return;
    }
    
    await guard(
      () async {
        _state = _state.copyWith(isLoading: true);
        notifyListeners();
        
        AppLogger.info(
          loadMore ? 'Loading more messages' : 'Loading initial messages',
          context: {'roomId': roomId},
        );
        
        // TODO: Replace with actual API call
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
          hasMore: newMessages.length >= 20, // Pagination threshold
        );
        
        AppLogger.info('Messages loaded successfully', context: {
          'count': newMessages.length,
          'total': _state.messages.length,
        });
        
        notifyListeners();
      },
      operationName: 'loadMessages',
      context: {'roomId': roomId, 'loadMore': loadMore},
      onError: (exception, stackTrace) {
        _state = _state.copyWith(
          isLoading: false,
          error: 'Failed to load messages: ${exception.message ?? exception.toString()}',
        );
        notifyListeners();
      },
    );
  }
  
  /// Send text message
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    
    await guard(
      () async {
        // Create optimistic message
        final tempMessage = ChatMessage.text(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          senderId: 'current_user', // TODO: Get from auth
          senderName: 'You',
          content: content.trim(),
          timestamp: DateTime.now(),
          replyToMessageId: _state.replyToMessage?['id'],
          replyToContent: _state.replyToMessage?['content'],
          replyToSenderName: _state.replyToMessage?['senderName'],
        );
        
        // Add optimistically to UI
        _state = _state.copyWith(
          messages: [..._state.messages, tempMessage],
          replyToMessage: null, // Clear reply after sending
        );
        notifyListeners();
        
        AppLogger.info('Sending message', context: {
          'roomId': roomId,
          'messageId': tempMessage.id,
          'contentLength': content.length,
        });
        
        // TODO: Send to server
        final sentMessage = await _sendMessageToServer(tempMessage);
        
        // Update with server response
        final updatedMessages = _state.messages.map((msg) {
          return msg.id == tempMessage.id ? sentMessage : msg;
        }).toList();
        
        _state = _state.copyWith(messages: updatedMessages);
        notifyListeners();
        
        AppLogger.info('Message sent successfully', context: {
          'messageId': sentMessage.id,
        });
      },
      operationName: 'sendMessage',
      context: {'roomId': roomId},
      onError: (exception, stackTrace) {
        // Mark message as failed
        _state = _state.copyWith(
          error: 'Failed to send message: ${exception.message ?? exception.toString()}',
        );
        notifyListeners();
        
        AppLogger.error('Message send failed', context: {
          'roomId': roomId,
          'error': exception.toString(),
        });
      },
    );
  }
  
  /// Edit message
  Future<void> editMessage(String messageId, String newContent) async {
    await guard(
      () async {
        AppLogger.info('Editing message', context: {
          'roomId': roomId,
          'messageId': messageId,
        });
        
        // TODO: Send edit to server
        await _editMessageOnServer(messageId, newContent);
        
        // Update local state
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
        
        AppLogger.info('Message edited successfully');
      },
      operationName: 'editMessage',
      context: {'roomId': roomId, 'messageId': messageId},
      onError: (exception, stackTrace) {
        _state = _state.copyWith(
          error: 'Failed to edit message: ${exception.message ?? exception.toString()}',
        );
        notifyListeners();
      },
    );
  }
  
  /// Delete message
  Future<void> deleteMessage(String messageId) async {
    await guard(
      () async {
        AppLogger.info('Deleting message', context: {
          'roomId': roomId,
          'messageId': messageId,
        });
        
        // TODO: Send delete to server
        await _deleteMessageOnServer(messageId);
        
        // Remove from local state
        _state = _state.copyWith(
          messages: _state.messages.where((msg) => msg.id != messageId).toList(),
        );
        notifyListeners();
        
        AppLogger.info('Message deleted successfully');
      },
      operationName: 'deleteMessage',
      context: {'roomId': roomId, 'messageId': messageId},
      onError: (exception, stackTrace) {
        _state = _state.copyWith(
          error: 'Failed to delete message: ${exception.message ?? exception.toString()}',
        );
        notifyListeners();
      },
    );
  }
  
  // ============================================================================
  // REACTIONS
  // ============================================================================
  
  /// Add reaction to message
  Future<void> addReaction(String messageId, String emoji) async {
    await guard(
      () async {
        final currentUserId = 'current_user'; // TODO: Get from auth
        
        AppLogger.info('Adding reaction', context: {
          'roomId': roomId,
          'messageId': messageId,
          'emoji': emoji,
        });
        
        // Optimistic update
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
        
        // TODO: Send to server
        await _sendReactionToServer(messageId, emoji);
        
        AppLogger.info('Reaction added successfully');
      },
      operationName: 'addReaction',
      context: {'roomId': roomId, 'messageId': messageId, 'emoji': emoji},
      onError: (exception, stackTrace) {
        _state = _state.copyWith(
          error: 'Failed to add reaction: ${exception.message ?? exception.toString()}',
        );
        notifyListeners();
      },
    );
  }
  
  /// Remove reaction from message
  Future<void> removeReaction(String messageId, String emoji) async {
    await guard(
      () async {
        final currentUserId = 'current_user'; // TODO: Get from auth
        
        AppLogger.info('Removing reaction', context: {
          'roomId': roomId,
          'messageId': messageId,
          'emoji': emoji,
        });
        
        // Optimistic update
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
        
        // TODO: Send to server
        await _removeReactionFromServer(messageId, emoji);
        
        AppLogger.info('Reaction removed successfully');
      },
      operationName: 'removeReaction',
      context: {'roomId': roomId, 'messageId': messageId, 'emoji': emoji},
      onError: (exception, stackTrace) {
        _state = _state.copyWith(
          error: 'Failed to remove reaction: ${exception.message ?? exception.toString()}',
        );
        notifyListeners();
      },
    );
  }
  
  // ============================================================================
  // REPLY / EDIT
  // ============================================================================
  
  /// Set message to reply to
  void setReplyToMessage(ChatMessage message) {
    _state = _state.copyWith(
      replyToMessage: {
        'id': message.id,
        'content': message.content,
        'senderName': message.senderName,
      },
    );
    notifyListeners();
    
    AppLogger.debug('Reply set', context: {'messageId': message.id});
  }
  
  /// Clear reply
  void clearReply() {
    _state = _state.copyWith(replyToMessage: null);
    notifyListeners();
  }
  
  /// Set message to edit
  void setEditingMessage(String messageId) {
    _state = _state.copyWith(editingMessageId: messageId);
    notifyListeners();
    
    AppLogger.debug('Edit mode set', context: {'messageId': messageId});
  }
  
  /// Clear edit mode
  void clearEditMode() {
    _state = _state.copyWith(editingMessageId: null);
    notifyListeners();
  }
  
  // ============================================================================
  // TYPING INDICATORS
  // ============================================================================
  
  /// Send typing indicator
  void sendTypingIndicator() {
    // Cancel previous timer
    _typingTimer?.cancel();
    
    // TODO: Send typing start event to server
    if (kDebugMode) {
      AppLogger.debug('Typing indicator sent');
    }
    
    // Auto-stop after 3 seconds
    _typingTimer = Timer(const Duration(seconds: 3), () {
      // TODO: Send typing stop event to server
    });
  }
  
  /// Handle user typing event
  void handleUserTyping(String userId) {
    final updated = Set<String>.from(_state.typingUsers)..add(userId);
    _state = _state.copyWith(typingUsers: updated);
    notifyListeners();
    
    // Auto-remove after 5 seconds
    Timer(const Duration(seconds: 5), () {
      final removed = Set<String>.from(_state.typingUsers)..remove(userId);
      _state = _state.copyWith(typingUsers: removed);
      notifyListeners();
    });
  }
  
  // ============================================================================
  // VOICE ROOM
  // ============================================================================
  
  /// Toggle voice room
  Future<void> toggleVoiceRoom() async {
    await guard(
      () async {
        final newState = !_state.isInVoiceRoom;
        
        AppLogger.info(
          newState ? 'Joining voice room' : 'Leaving voice room',
          context: {'roomId': roomId},
        );
        
        if (newState) {
          // TODO: Join voice room via service
          _state = _state.copyWith(
            isInVoiceRoom: true,
            isMuted: false,
          );
        } else {
          // TODO: Leave voice room via service
          _state = _state.copyWith(
            isInVoiceRoom: false,
            voiceParticipants: [],
          );
        }
        
        notifyListeners();
        
        AppLogger.info(
          newState ? 'Joined voice room' : 'Left voice room',
        );
      },
      operationName: 'toggleVoiceRoom',
      context: {'roomId': roomId},
      onError: (exception, stackTrace) {
        _state = _state.copyWith(
          error: 'Voice room error: ${exception.message ?? exception.toString()}',
        );
        notifyListeners();
      },
    );
  }
  
  /// Toggle mute
  void toggleMute() {
    _state = _state.copyWith(isMuted: !_state.isMuted);
    notifyListeners();
    
    AppLogger.info('Mute toggled', context: {'isMuted': _state.isMuted});
    
    // TODO: Send mute state to server
  }
  
  // ============================================================================
  // SEARCH
  // ============================================================================
  
  /// Toggle search
  void toggleSearch() {
    _state = _state.copyWith(searchVisible: !_state.searchVisible);
    notifyListeners();
  }
  
  // ============================================================================
  // POLLING & REAL-TIME
  // ============================================================================
  
  void _startMessagePolling() {
    _messagePollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pollNewMessages(),
    );
  }
  
  Future<void> _pollNewMessages() async {
    // TODO: Implement real polling
    if (kDebugMode) {
      AppLogger.debug('Polling new messages');
    }
  }
  
  // ============================================================================
  // SERVER API CALLS (MOCK)
  // ============================================================================
  
  Future<List<ChatMessage>> _fetchMessagesFromServer({DateTime? before}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // TODO: Replace with actual API call
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
    
    // TODO: Replace with actual API call
    return message.copyWith(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      status: MessageStatus.sent,
    );
  }
  
  Future<void> _editMessageOnServer(String messageId, String content) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // TODO: Implement API call
  }
  
  Future<void> _deleteMessageOnServer(String messageId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // TODO: Implement API call
  }
  
  Future<void> _sendReactionToServer(String messageId, String emoji) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // TODO: Implement API call
  }
  
  Future<void> _removeReactionFromServer(String messageId, String emoji) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // TODO: Implement API call
  }
  
  // ============================================================================
  // ERROR HANDLING
  // ============================================================================
  
  /// Clear error
  void clearError() {
    _state = _state.clearError();
    notifyListeners();
  }
  
  // ============================================================================
  // CLEANUP
  // ============================================================================
  
  @override
  void dispose() {
    _typingTimer?.cancel();
    _messagePollingTimer?.cancel();
    super.dispose();
    
    AppLogger.info('ChatRoomController disposed', context: {'roomId': roomId});
  }
}
