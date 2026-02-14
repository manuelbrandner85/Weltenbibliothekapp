// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'webrtc_call_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$WebRTCCallState {
// Connection
  CallConnectionState get connectionState => throw _privateConstructorUsedError;
  String? get roomId => throw _privateConstructorUsedError;
  String? get roomName =>
      throw _privateConstructorUsedError; // Participants (max 10)
  List<WebRTCParticipant> get participants =>
      throw _privateConstructorUsedError;
  int get maxParticipants =>
      throw _privateConstructorUsedError; // Active speaker
  String? get activeSpeakerId => throw _privateConstructorUsedError;
  Map<String, double> get speakingLevels =>
      throw _privateConstructorUsedError; // userId -> volume level
// Local user state
  String? get localUserId => throw _privateConstructorUsedError;
  bool get isLocalMuted => throw _privateConstructorUsedError;
  bool get isPushToTalk => throw _privateConstructorUsedError; // Admin
  bool get isAdmin => throw _privateConstructorUsedError;
  bool get isRootAdmin => throw _privateConstructorUsedError; // Reconnection
  int get reconnectAttempts => throw _privateConstructorUsedError;
  int get maxReconnectAttempts => throw _privateConstructorUsedError;
  DateTime? get lastReconnectAt =>
      throw _privateConstructorUsedError; // Error tracking
  String? get errorMessage => throw _privateConstructorUsedError;
  DateTime? get errorOccurredAt =>
      throw _privateConstructorUsedError; // Timestamps
  DateTime? get connectedAt => throw _privateConstructorUsedError;
  DateTime? get disconnectedAt => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $WebRTCCallStateCopyWith<WebRTCCallState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WebRTCCallStateCopyWith<$Res> {
  factory $WebRTCCallStateCopyWith(
          WebRTCCallState value, $Res Function(WebRTCCallState) then) =
      _$WebRTCCallStateCopyWithImpl<$Res, WebRTCCallState>;
  @useResult
  $Res call(
      {CallConnectionState connectionState,
      String? roomId,
      String? roomName,
      List<WebRTCParticipant> participants,
      int maxParticipants,
      String? activeSpeakerId,
      Map<String, double> speakingLevels,
      String? localUserId,
      bool isLocalMuted,
      bool isPushToTalk,
      bool isAdmin,
      bool isRootAdmin,
      int reconnectAttempts,
      int maxReconnectAttempts,
      DateTime? lastReconnectAt,
      String? errorMessage,
      DateTime? errorOccurredAt,
      DateTime? connectedAt,
      DateTime? disconnectedAt});
}

/// @nodoc
class _$WebRTCCallStateCopyWithImpl<$Res, $Val extends WebRTCCallState>
    implements $WebRTCCallStateCopyWith<$Res> {
  _$WebRTCCallStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? connectionState = null,
    Object? roomId = freezed,
    Object? roomName = freezed,
    Object? participants = null,
    Object? maxParticipants = null,
    Object? activeSpeakerId = freezed,
    Object? speakingLevels = null,
    Object? localUserId = freezed,
    Object? isLocalMuted = null,
    Object? isPushToTalk = null,
    Object? isAdmin = null,
    Object? isRootAdmin = null,
    Object? reconnectAttempts = null,
    Object? maxReconnectAttempts = null,
    Object? lastReconnectAt = freezed,
    Object? errorMessage = freezed,
    Object? errorOccurredAt = freezed,
    Object? connectedAt = freezed,
    Object? disconnectedAt = freezed,
  }) {
    return _then(_value.copyWith(
      connectionState: null == connectionState
          ? _value.connectionState
          : connectionState // ignore: cast_nullable_to_non_nullable
              as CallConnectionState,
      roomId: freezed == roomId
          ? _value.roomId
          : roomId // ignore: cast_nullable_to_non_nullable
              as String?,
      roomName: freezed == roomName
          ? _value.roomName
          : roomName // ignore: cast_nullable_to_non_nullable
              as String?,
      participants: null == participants
          ? _value.participants
          : participants // ignore: cast_nullable_to_non_nullable
              as List<WebRTCParticipant>,
      maxParticipants: null == maxParticipants
          ? _value.maxParticipants
          : maxParticipants // ignore: cast_nullable_to_non_nullable
              as int,
      activeSpeakerId: freezed == activeSpeakerId
          ? _value.activeSpeakerId
          : activeSpeakerId // ignore: cast_nullable_to_non_nullable
              as String?,
      speakingLevels: null == speakingLevels
          ? _value.speakingLevels
          : speakingLevels // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      localUserId: freezed == localUserId
          ? _value.localUserId
          : localUserId // ignore: cast_nullable_to_non_nullable
              as String?,
      isLocalMuted: null == isLocalMuted
          ? _value.isLocalMuted
          : isLocalMuted // ignore: cast_nullable_to_non_nullable
              as bool,
      isPushToTalk: null == isPushToTalk
          ? _value.isPushToTalk
          : isPushToTalk // ignore: cast_nullable_to_non_nullable
              as bool,
      isAdmin: null == isAdmin
          ? _value.isAdmin
          : isAdmin // ignore: cast_nullable_to_non_nullable
              as bool,
      isRootAdmin: null == isRootAdmin
          ? _value.isRootAdmin
          : isRootAdmin // ignore: cast_nullable_to_non_nullable
              as bool,
      reconnectAttempts: null == reconnectAttempts
          ? _value.reconnectAttempts
          : reconnectAttempts // ignore: cast_nullable_to_non_nullable
              as int,
      maxReconnectAttempts: null == maxReconnectAttempts
          ? _value.maxReconnectAttempts
          : maxReconnectAttempts // ignore: cast_nullable_to_non_nullable
              as int,
      lastReconnectAt: freezed == lastReconnectAt
          ? _value.lastReconnectAt
          : lastReconnectAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      errorOccurredAt: freezed == errorOccurredAt
          ? _value.errorOccurredAt
          : errorOccurredAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      connectedAt: freezed == connectedAt
          ? _value.connectedAt
          : connectedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      disconnectedAt: freezed == disconnectedAt
          ? _value.disconnectedAt
          : disconnectedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WebRTCCallStateImplCopyWith<$Res>
    implements $WebRTCCallStateCopyWith<$Res> {
  factory _$$WebRTCCallStateImplCopyWith(_$WebRTCCallStateImpl value,
          $Res Function(_$WebRTCCallStateImpl) then) =
      __$$WebRTCCallStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {CallConnectionState connectionState,
      String? roomId,
      String? roomName,
      List<WebRTCParticipant> participants,
      int maxParticipants,
      String? activeSpeakerId,
      Map<String, double> speakingLevels,
      String? localUserId,
      bool isLocalMuted,
      bool isPushToTalk,
      bool isAdmin,
      bool isRootAdmin,
      int reconnectAttempts,
      int maxReconnectAttempts,
      DateTime? lastReconnectAt,
      String? errorMessage,
      DateTime? errorOccurredAt,
      DateTime? connectedAt,
      DateTime? disconnectedAt});
}

/// @nodoc
class __$$WebRTCCallStateImplCopyWithImpl<$Res>
    extends _$WebRTCCallStateCopyWithImpl<$Res, _$WebRTCCallStateImpl>
    implements _$$WebRTCCallStateImplCopyWith<$Res> {
  __$$WebRTCCallStateImplCopyWithImpl(
      _$WebRTCCallStateImpl _value, $Res Function(_$WebRTCCallStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? connectionState = null,
    Object? roomId = freezed,
    Object? roomName = freezed,
    Object? participants = null,
    Object? maxParticipants = null,
    Object? activeSpeakerId = freezed,
    Object? speakingLevels = null,
    Object? localUserId = freezed,
    Object? isLocalMuted = null,
    Object? isPushToTalk = null,
    Object? isAdmin = null,
    Object? isRootAdmin = null,
    Object? reconnectAttempts = null,
    Object? maxReconnectAttempts = null,
    Object? lastReconnectAt = freezed,
    Object? errorMessage = freezed,
    Object? errorOccurredAt = freezed,
    Object? connectedAt = freezed,
    Object? disconnectedAt = freezed,
  }) {
    return _then(_$WebRTCCallStateImpl(
      connectionState: null == connectionState
          ? _value.connectionState
          : connectionState // ignore: cast_nullable_to_non_nullable
              as CallConnectionState,
      roomId: freezed == roomId
          ? _value.roomId
          : roomId // ignore: cast_nullable_to_non_nullable
              as String?,
      roomName: freezed == roomName
          ? _value.roomName
          : roomName // ignore: cast_nullable_to_non_nullable
              as String?,
      participants: null == participants
          ? _value._participants
          : participants // ignore: cast_nullable_to_non_nullable
              as List<WebRTCParticipant>,
      maxParticipants: null == maxParticipants
          ? _value.maxParticipants
          : maxParticipants // ignore: cast_nullable_to_non_nullable
              as int,
      activeSpeakerId: freezed == activeSpeakerId
          ? _value.activeSpeakerId
          : activeSpeakerId // ignore: cast_nullable_to_non_nullable
              as String?,
      speakingLevels: null == speakingLevels
          ? _value._speakingLevels
          : speakingLevels // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      localUserId: freezed == localUserId
          ? _value.localUserId
          : localUserId // ignore: cast_nullable_to_non_nullable
              as String?,
      isLocalMuted: null == isLocalMuted
          ? _value.isLocalMuted
          : isLocalMuted // ignore: cast_nullable_to_non_nullable
              as bool,
      isPushToTalk: null == isPushToTalk
          ? _value.isPushToTalk
          : isPushToTalk // ignore: cast_nullable_to_non_nullable
              as bool,
      isAdmin: null == isAdmin
          ? _value.isAdmin
          : isAdmin // ignore: cast_nullable_to_non_nullable
              as bool,
      isRootAdmin: null == isRootAdmin
          ? _value.isRootAdmin
          : isRootAdmin // ignore: cast_nullable_to_non_nullable
              as bool,
      reconnectAttempts: null == reconnectAttempts
          ? _value.reconnectAttempts
          : reconnectAttempts // ignore: cast_nullable_to_non_nullable
              as int,
      maxReconnectAttempts: null == maxReconnectAttempts
          ? _value.maxReconnectAttempts
          : maxReconnectAttempts // ignore: cast_nullable_to_non_nullable
              as int,
      lastReconnectAt: freezed == lastReconnectAt
          ? _value.lastReconnectAt
          : lastReconnectAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      errorOccurredAt: freezed == errorOccurredAt
          ? _value.errorOccurredAt
          : errorOccurredAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      connectedAt: freezed == connectedAt
          ? _value.connectedAt
          : connectedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      disconnectedAt: freezed == disconnectedAt
          ? _value.disconnectedAt
          : disconnectedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$WebRTCCallStateImpl implements _WebRTCCallState {
  const _$WebRTCCallStateImpl(
      {this.connectionState = CallConnectionState.idle,
      this.roomId,
      this.roomName,
      final List<WebRTCParticipant> participants = const [],
      this.maxParticipants = 10,
      this.activeSpeakerId,
      final Map<String, double> speakingLevels = const {},
      this.localUserId,
      this.isLocalMuted = false,
      this.isPushToTalk = false,
      this.isAdmin = false,
      this.isRootAdmin = false,
      this.reconnectAttempts = 0,
      this.maxReconnectAttempts = 3,
      this.lastReconnectAt,
      this.errorMessage,
      this.errorOccurredAt,
      this.connectedAt,
      this.disconnectedAt})
      : _participants = participants,
        _speakingLevels = speakingLevels;

// Connection
  @override
  @JsonKey()
  final CallConnectionState connectionState;
  @override
  final String? roomId;
  @override
  final String? roomName;
// Participants (max 10)
  final List<WebRTCParticipant> _participants;
// Participants (max 10)
  @override
  @JsonKey()
  List<WebRTCParticipant> get participants {
    if (_participants is EqualUnmodifiableListView) return _participants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_participants);
  }

  @override
  @JsonKey()
  final int maxParticipants;
// Active speaker
  @override
  final String? activeSpeakerId;
  final Map<String, double> _speakingLevels;
  @override
  @JsonKey()
  Map<String, double> get speakingLevels {
    if (_speakingLevels is EqualUnmodifiableMapView) return _speakingLevels;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_speakingLevels);
  }

// userId -> volume level
// Local user state
  @override
  final String? localUserId;
  @override
  @JsonKey()
  final bool isLocalMuted;
  @override
  @JsonKey()
  final bool isPushToTalk;
// Admin
  @override
  @JsonKey()
  final bool isAdmin;
  @override
  @JsonKey()
  final bool isRootAdmin;
// Reconnection
  @override
  @JsonKey()
  final int reconnectAttempts;
  @override
  @JsonKey()
  final int maxReconnectAttempts;
  @override
  final DateTime? lastReconnectAt;
// Error tracking
  @override
  final String? errorMessage;
  @override
  final DateTime? errorOccurredAt;
// Timestamps
  @override
  final DateTime? connectedAt;
  @override
  final DateTime? disconnectedAt;

  @override
  String toString() {
    return 'WebRTCCallState(connectionState: $connectionState, roomId: $roomId, roomName: $roomName, participants: $participants, maxParticipants: $maxParticipants, activeSpeakerId: $activeSpeakerId, speakingLevels: $speakingLevels, localUserId: $localUserId, isLocalMuted: $isLocalMuted, isPushToTalk: $isPushToTalk, isAdmin: $isAdmin, isRootAdmin: $isRootAdmin, reconnectAttempts: $reconnectAttempts, maxReconnectAttempts: $maxReconnectAttempts, lastReconnectAt: $lastReconnectAt, errorMessage: $errorMessage, errorOccurredAt: $errorOccurredAt, connectedAt: $connectedAt, disconnectedAt: $disconnectedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WebRTCCallStateImpl &&
            (identical(other.connectionState, connectionState) ||
                other.connectionState == connectionState) &&
            (identical(other.roomId, roomId) || other.roomId == roomId) &&
            (identical(other.roomName, roomName) ||
                other.roomName == roomName) &&
            const DeepCollectionEquality()
                .equals(other._participants, _participants) &&
            (identical(other.maxParticipants, maxParticipants) ||
                other.maxParticipants == maxParticipants) &&
            (identical(other.activeSpeakerId, activeSpeakerId) ||
                other.activeSpeakerId == activeSpeakerId) &&
            const DeepCollectionEquality()
                .equals(other._speakingLevels, _speakingLevels) &&
            (identical(other.localUserId, localUserId) ||
                other.localUserId == localUserId) &&
            (identical(other.isLocalMuted, isLocalMuted) ||
                other.isLocalMuted == isLocalMuted) &&
            (identical(other.isPushToTalk, isPushToTalk) ||
                other.isPushToTalk == isPushToTalk) &&
            (identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin) &&
            (identical(other.isRootAdmin, isRootAdmin) ||
                other.isRootAdmin == isRootAdmin) &&
            (identical(other.reconnectAttempts, reconnectAttempts) ||
                other.reconnectAttempts == reconnectAttempts) &&
            (identical(other.maxReconnectAttempts, maxReconnectAttempts) ||
                other.maxReconnectAttempts == maxReconnectAttempts) &&
            (identical(other.lastReconnectAt, lastReconnectAt) ||
                other.lastReconnectAt == lastReconnectAt) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.errorOccurredAt, errorOccurredAt) ||
                other.errorOccurredAt == errorOccurredAt) &&
            (identical(other.connectedAt, connectedAt) ||
                other.connectedAt == connectedAt) &&
            (identical(other.disconnectedAt, disconnectedAt) ||
                other.disconnectedAt == disconnectedAt));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        connectionState,
        roomId,
        roomName,
        const DeepCollectionEquality().hash(_participants),
        maxParticipants,
        activeSpeakerId,
        const DeepCollectionEquality().hash(_speakingLevels),
        localUserId,
        isLocalMuted,
        isPushToTalk,
        isAdmin,
        isRootAdmin,
        reconnectAttempts,
        maxReconnectAttempts,
        lastReconnectAt,
        errorMessage,
        errorOccurredAt,
        connectedAt,
        disconnectedAt
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WebRTCCallStateImplCopyWith<_$WebRTCCallStateImpl> get copyWith =>
      __$$WebRTCCallStateImplCopyWithImpl<_$WebRTCCallStateImpl>(
          this, _$identity);
}

abstract class _WebRTCCallState implements WebRTCCallState {
  const factory _WebRTCCallState(
      {final CallConnectionState connectionState,
      final String? roomId,
      final String? roomName,
      final List<WebRTCParticipant> participants,
      final int maxParticipants,
      final String? activeSpeakerId,
      final Map<String, double> speakingLevels,
      final String? localUserId,
      final bool isLocalMuted,
      final bool isPushToTalk,
      final bool isAdmin,
      final bool isRootAdmin,
      final int reconnectAttempts,
      final int maxReconnectAttempts,
      final DateTime? lastReconnectAt,
      final String? errorMessage,
      final DateTime? errorOccurredAt,
      final DateTime? connectedAt,
      final DateTime? disconnectedAt}) = _$WebRTCCallStateImpl;

  @override // Connection
  CallConnectionState get connectionState;
  @override
  String? get roomId;
  @override
  String? get roomName;
  @override // Participants (max 10)
  List<WebRTCParticipant> get participants;
  @override
  int get maxParticipants;
  @override // Active speaker
  String? get activeSpeakerId;
  @override
  Map<String, double> get speakingLevels;
  @override // userId -> volume level
// Local user state
  String? get localUserId;
  @override
  bool get isLocalMuted;
  @override
  bool get isPushToTalk;
  @override // Admin
  bool get isAdmin;
  @override
  bool get isRootAdmin;
  @override // Reconnection
  int get reconnectAttempts;
  @override
  int get maxReconnectAttempts;
  @override
  DateTime? get lastReconnectAt;
  @override // Error tracking
  String? get errorMessage;
  @override
  DateTime? get errorOccurredAt;
  @override // Timestamps
  DateTime? get connectedAt;
  @override
  DateTime? get disconnectedAt;
  @override
  @JsonKey(ignore: true)
  _$$WebRTCCallStateImplCopyWith<_$WebRTCCallStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
