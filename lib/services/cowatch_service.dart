/// 📺 B10.4 — Co-Watch (gemeinsam Video schauen)
///
/// Synchronisierter YouTube-Player via LiveKit DataChannel.
/// Host lädt Video → alle Teilnehmer sehen es gleichzeitig.
/// Play/Pause/Seek werden über DataChannel synchronisiert.
///
/// DataChannel-Protokoll:
///   {type: 'cowatch', action: 'load',  videoId: '...'}
///   {type: 'cowatch', action: 'play',  position: <sek>}
///   {type: 'cowatch', action: 'pause', position: <sek>}
///   {type: 'cowatch', action: 'seek',  position: <sek>}
///   {type: 'cowatch', action: 'close'}
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

enum CoWatchAction { load, play, pause, seek, close }

class CoWatchEvent {
  final CoWatchAction action;
  final String? videoId;
  final double? position; // Sekunden
  final String fromIdentity;
  const CoWatchEvent({
    required this.action,
    this.videoId,
    this.position,
    required this.fromIdentity,
  });
}

class CoWatchService {
  CoWatchService._();
  static final CoWatchService instance = CoWatchService._();

  final StreamController<CoWatchEvent> _ctrl =
      StreamController<CoWatchEvent>.broadcast();
  Stream<CoWatchEvent> get eventStream => _ctrl.stream;

  bool _active = false;
  bool get active => _active;

  String? _currentVideoId;
  String? get currentVideoId => _currentVideoId;

  lk.Room? _room;
  String? _localIdentity;

  void attachRoom(lk.Room room, String identity) {
    _room = room;
    _localIdentity = identity;
  }

  void detachRoom() {
    _room = null;
    _localIdentity = null;
    _active = false;
    _currentVideoId = null;
  }

  /// Verarbeitet eingehende DataChannel-Pakete vom LiveKitCallService.
  void handleIncomingData(Map<dynamic, dynamic> data, lk.Participant? from) {
    try {
      final action = _parseAction(data['action'] as String?);
      if (action == null) return;
      final identity = from?.identity ?? 'remote';
      final position = (data['position'] as num?)?.toDouble();
      final videoId = data['videoId'] as String?;

      if (action == CoWatchAction.load && videoId != null) {
        _active = true;
        _currentVideoId = videoId;
      }
      if (action == CoWatchAction.close) {
        _active = false;
        _currentVideoId = null;
      }
      _ctrl.add(CoWatchEvent(
        action: action,
        videoId: videoId,
        position: position,
        fromIdentity: identity,
      ));
    } catch (_) {}
  }

  // ── Host-Aktionen (werden gebroadcastet + lokal angezeigt) ───────────────

  Future<void> loadVideo(String youtubeUrl) async {
    final videoId = _extractVideoId(youtubeUrl);
    if (videoId == null) return;
    _active = true;
    _currentVideoId = videoId;
    await _broadcast({'type': 'cowatch', 'action': 'load', 'videoId': videoId});
    // Lokal anzeigen
    _ctrl.add(CoWatchEvent(
      action: CoWatchAction.load,
      videoId: videoId,
      fromIdentity: _localIdentity ?? 'local',
    ));
  }

  Future<void> broadcastPlay(double positionSec) => _broadcast(
      {'type': 'cowatch', 'action': 'play', 'position': positionSec});

  Future<void> broadcastPause(double positionSec) => _broadcast(
      {'type': 'cowatch', 'action': 'pause', 'position': positionSec});

  Future<void> broadcastSeek(double positionSec) => _broadcast(
      {'type': 'cowatch', 'action': 'seek', 'position': positionSec});

  Future<void> closeVideo() async {
    _active = false;
    _currentVideoId = null;
    await _broadcast({'type': 'cowatch', 'action': 'close'});
    _ctrl.add(CoWatchEvent(
      action: CoWatchAction.close,
      fromIdentity: _localIdentity ?? 'local',
    ));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _broadcast(Map<String, dynamic> payload) async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    try {
      await lp.publishData(
        utf8.encode(jsonEncode(payload)),
        reliable: true,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ CoWatch broadcast error: $e');
    }
  }

  CoWatchAction? _parseAction(String? s) {
    switch (s) {
      case 'load':
        return CoWatchAction.load;
      case 'play':
        return CoWatchAction.play;
      case 'pause':
        return CoWatchAction.pause;
      case 'seek':
        return CoWatchAction.seek;
      case 'close':
        return CoWatchAction.close;
      default:
        return null;
    }
  }

  /// Extrahiert YouTube-Video-ID aus verschiedenen URL-Formaten.
  String? _extractVideoId(String url) {
    // youtu.be/ID
    final shortMatch =
        RegExp(r'youtu\.be/([A-Za-z0-9_-]{11})').firstMatch(url);
    if (shortMatch != null) return shortMatch.group(1);
    // youtube.com/watch?v=ID
    final longMatch =
        RegExp(r'[?&]v=([A-Za-z0-9_-]{11})').firstMatch(url);
    if (longMatch != null) return longMatch.group(1);
    // youtube.com/embed/ID
    final embedMatch =
        RegExp(r'embed/([A-Za-z0-9_-]{11})').firstMatch(url);
    if (embedMatch != null) return embedMatch.group(1);
    // Nur ID angegeben (11 Zeichen)
    if (RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(url.trim())) {
      return url.trim();
    }
    return null;
  }

  void dispose() {
    _ctrl.close();
  }
}
