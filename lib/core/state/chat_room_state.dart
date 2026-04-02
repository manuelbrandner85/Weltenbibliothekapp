/// 💬 CHAT ROOM STATE
/// 
/// Immutable state container for chat room functionality
/// 
/// Features:
/// - Message list with pagination
/// - Typing indicators
/// - Voice room integration
/// - Reactions system
/// - Reply/Edit support
/// - Search functionality
/// - Error handling
library;

import 'package:flutter/foundation.dart';
import '../../models/chat_models.dart';

@immutable
class ChatRoomState {
  final List<ChatMessage> messages;
  final Set<String> typingUsers;
  final bool isInVoiceRoom;
  final bool isMuted;
  final List<Map<String, dynamic>> voiceParticipants;
  final Map<String, Map<String, List<String>>> reactions;
  final Map<String, dynamic>? replyToMessage;
  final String? editingMessageId;
  final bool searchVisible;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const ChatRoomState({
    this.messages = const [],
    this.typingUsers = const {},
    this.isInVoiceRoom = false,
    this.isMuted = false,
    this.voiceParticipants = const [],
    this.reactions = const {},
    this.replyToMessage,
    this.editingMessageId,
    this.searchVisible = false,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  ChatRoomState copyWith({
    List<ChatMessage>? messages,
    Set<String>? typingUsers,
    bool? isInVoiceRoom,
    bool? isMuted,
    List<Map<String, dynamic>>? voiceParticipants,
    Map<String, Map<String, List<String>>>? reactions,
    Map<String, dynamic>? replyToMessage,
    String? editingMessageId,
    bool? searchVisible,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return ChatRoomState(
      messages: messages ?? this.messages,
      typingUsers: typingUsers ?? this.typingUsers,
      isInVoiceRoom: isInVoiceRoom ?? this.isInVoiceRoom,
      isMuted: isMuted ?? this.isMuted,
      voiceParticipants: voiceParticipants ?? this.voiceParticipants,
      reactions: reactions ?? this.reactions,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      editingMessageId: editingMessageId ?? this.editingMessageId,
      searchVisible: searchVisible ?? this.searchVisible,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }

  ChatRoomState clearError() => copyWith(error: null);
  
  /// Check if user is typing
  bool isUserTyping(String userId) => typingUsers.contains(userId);
  
  /// Get message by ID
  ChatMessage? getMessageById(String messageId) {
    try {
      return messages.firstWhere((msg) => msg.id == messageId);
    } catch (e) {
      return null;
    }
  }
  
  /// Get reactions for message
  Map<String, List<String>>? getMessageReactions(String messageId) {
    return reactions[messageId];
  }
  
  /// Count total reactions for message
  int getReactionCount(String messageId) {
    final msgReactions = reactions[messageId];
    if (msgReactions == null) return 0;
    return msgReactions.values.fold(0, (sum, users) => sum + users.length);
  }
  
  /// Check if message is being edited
  bool isMessageEditing(String messageId) => editingMessageId == messageId;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ChatRoomState &&
        listEquals(other.messages, messages) &&
        setEquals(other.typingUsers, typingUsers) &&
        other.isInVoiceRoom == isInVoiceRoom &&
        other.isMuted == isMuted &&
        listEquals(other.voiceParticipants, voiceParticipants) &&
        mapEquals(other.reactions, reactions) &&
        mapEquals(other.replyToMessage, replyToMessage) &&
        other.editingMessageId == editingMessageId &&
        other.searchVisible == searchVisible &&
        other.isLoading == isLoading &&
        other.hasMore == hasMore &&
        other.error == error;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(messages),
      Object.hashAll(typingUsers),
      isInVoiceRoom,
      isMuted,
      Object.hashAll(voiceParticipants),
      reactions,
      replyToMessage,
      editingMessageId,
      searchVisible,
      isLoading,
      hasMore,
      error,
    );
  }
  
  @override
  String toString() {
    return 'ChatRoomState('
        'messages: ${messages.length}, '
        'typingUsers: ${typingUsers.length}, '
        'isInVoiceRoom: $isInVoiceRoom, '
        'isMuted: $isMuted, '
        'voiceParticipants: ${voiceParticipants.length}, '
        'searchVisible: $searchVisible, '
        'isLoading: $isLoading, '
        'hasMore: $hasMore, '
        'error: $error'
        ')';
  }
}
