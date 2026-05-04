/// 💬 In-Call Text-Chat via LiveKit DataChannel
///
/// Ermöglicht Text-Nachrichten innerhalb eines laufenden LiveKit-Calls.
/// Kein Server-Backend nötig — rein P2P via DataChannel.
///
/// DataChannel-Protokoll:
///   {type: 'incall_chat', text: '...', name: '...', identity: '...'}
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

class InCallMessage {
  final String identity;
  final String name;
  final String text;
  final DateTime timestamp;
  final bool isLocal;

  const InCallMessage({
    required this.identity,
    required this.name,
    required this.text,
    required this.timestamp,
    required this.isLocal,
  });
}

class InCallChatService {
  InCallChatService._();
  static final InCallChatService instance = InCallChatService._();

  final StreamController<InCallMessage> _ctrl =
      StreamController<InCallMessage>.broadcast();
  Stream<InCallMessage> get messageStream => _ctrl.stream;

  // Ungelesene Nachrichten-Zähler (nur wenn Panel geschlossen)
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  final _unreadNotifier = ValueNotifier<int>(0);
  ValueNotifier<int> get unreadNotifier => _unreadNotifier;

  final List<InCallMessage> _history = [];
  List<InCallMessage> get history => List.unmodifiable(_history);

  lk.Room? _room;
  String? _localIdentity;
  String? _localName;

  void attachRoom(lk.Room room, String identity, String name) {
    _room = room;
    _localIdentity = identity;
    _localName = name;
  }

  void detachRoom() {
    _room = null;
    _localIdentity = null;
    _localName = null;
    _history.clear();
    _unreadCount = 0;
    _unreadNotifier.value = 0;
  }

  /// Wird aufgerufen wenn das Chat-Panel geöffnet wird.
  void markAllRead() {
    _unreadCount = 0;
    _unreadNotifier.value = 0;
  }

  /// Verarbeitet eingehende DataChannel-Pakete.
  void handleIncomingData(Map<dynamic, dynamic> data, lk.Participant? from) {
    try {
      final text = data['text'] as String?;
      if (text == null || text.isEmpty) return;
      final identity =
          data['identity'] as String? ?? from?.identity ?? '?';
      final name = data['name'] as String? ??
          (from?.name.isNotEmpty == true ? from!.name : identity);

      final msg = InCallMessage(
        identity: identity,
        name: name,
        text: text,
        timestamp: DateTime.now(),
        isLocal: false,
      );
      _history.add(msg);
      _ctrl.add(msg);
      _unreadCount++;
      _unreadNotifier.value = _unreadCount;
    } catch (_) {}
  }

  /// Sendet eine Nachricht an alle Teilnehmer.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final lp = _room?.localParticipant;
    if (lp == null) return;

    final msg = InCallMessage(
      identity: _localIdentity ?? 'local',
      name: _localName ?? 'Du',
      text: trimmed,
      timestamp: DateTime.now(),
      isLocal: true,
    );
    _history.add(msg);
    _ctrl.add(msg);

    try {
      await lp.publishData(
        utf8.encode(jsonEncode({
          'type': 'incall_chat',
          'text': trimmed,
          'identity': _localIdentity ?? '',
          'name': _localName ?? '',
        })),
        reliable: true,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ InCallChat send error: $e');
    }
  }

  void dispose() {
    _ctrl.close();
    _unreadNotifier.dispose();
  }
}
