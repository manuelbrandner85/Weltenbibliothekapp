/// 🎙️ B8: Live-Untertitel via speech_to_text + LiveKit DataChannel
///
/// Transkribiert lokales Mikrofon on-device (kein API-Aufruf) und
/// broadcastet via DataChannel an alle Teilnehmer im Raum.
/// Empfangene Captions werden im Stream [captionsStream] ausgegeben.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:speech_to_text/speech_to_text.dart';

/// Ein empfangenes Caption-Event.
class CaptionEvent {
  final String identity;
  final String name;
  final String text;
  final DateTime timestamp;
  const CaptionEvent({
    required this.identity,
    required this.name,
    required this.text,
    required this.timestamp,
  });
}

class LiveCaptionService {
  LiveCaptionService._();
  static final LiveCaptionService instance = LiveCaptionService._();

  final SpeechToText _stt = SpeechToText();
  bool _sttAvailable = false;
  bool _captionsEnabled = false;
  bool get captionsEnabled => _captionsEnabled;

  // Letzter erkannter Text (für Partial-Display)
  String _partialText = '';
  String get partialText => _partialText;

  // Broadcast-Stream für empfangene (+ eigene) Captions
  final StreamController<CaptionEvent> _captionsCtrl =
      StreamController<CaptionEvent>.broadcast();
  Stream<CaptionEvent> get captionsStream => _captionsCtrl.stream;

  // Referenz auf den aktiven LiveKit-Raum für DataChannel-Broadcast
  lk.Room? _room;
  String? _localIdentity;
  String? _localName;

  /// Muss aufgerufen werden wenn ein Raum beigetreten wird.
  void attachRoom(lk.Room room, String identity, String name) {
    _room = room;
    _localIdentity = identity;
    _localName = name;
  }

  /// Aufräumen wenn Raum verlassen wird.
  void detachRoom() {
    _room = null;
    _localIdentity = null;
    _localName = null;
    if (_captionsEnabled) _stopListening();
  }

  /// Empfangenes DataChannel-Paket verarbeiten (wird von LiveKitCallService aufgerufen).
  void handleIncomingData(Map<dynamic, dynamic> data, lk.Participant? from) {
    try {
      final text = data['text'] as String?;
      if (text == null || text.isEmpty) return;
      final identity = data['identity'] as String? ?? from?.identity ?? '?';
      final name = data['name'] as String? ??
          (from?.name.isNotEmpty == true ? from!.name : identity);
      _captionsCtrl.add(CaptionEvent(
        identity: identity,
        name: name,
        text: text,
        timestamp: DateTime.now(),
      ));
    } catch (_) {}
  }

  /// Untertitel ein-/ausschalten.
  Future<bool> toggle() async {
    if (_captionsEnabled) {
      _captionsEnabled = false;
      _stopListening();
      return false;
    }
    // Initialisieren falls noch nicht geschehen
    if (!_sttAvailable) {
      _sttAvailable = await _stt.initialize(
        onError: (e) {
          if (kDebugMode) debugPrint('⚠️ STT error: ${e.errorMsg}');
          _scheduleRestart();
        },
        onStatus: (status) {
          if (kDebugMode) debugPrint('🎙️ STT status: $status');
          // Wenn STT stopped und Captions noch an: neu starten
          if (status == 'done' && _captionsEnabled) _scheduleRestart();
        },
      );
    }
    if (!_sttAvailable) return false;
    _captionsEnabled = true;
    _startListening();
    return true;
  }

  void _startListening() {
    if (!_sttAvailable || !_captionsEnabled) return;
    _stt.listen(
      onResult: (result) {
        _partialText = result.recognizedWords;
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          _broadcastCaption(result.recognizedWords);
          _partialText = '';
          // Direkt neu starten für kontinuierliche Erkennung
          Future.delayed(const Duration(milliseconds: 200), _startListening);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      localeId: 'de_DE',
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
      ),
    );
  }

  void _stopListening() {
    _stt.stop();
    _partialText = '';
  }

  Timer? _restartTimer;
  void _scheduleRestart() {
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(seconds: 1), () {
      if (_captionsEnabled) _startListening();
    });
  }

  Future<void> _broadcastCaption(String text) async {
    final room = _room;
    final lp = room?.localParticipant;
    if (lp == null) return;

    // Lokal sofort anzeigen
    _captionsCtrl.add(CaptionEvent(
      identity: _localIdentity ?? 'local',
      name: _localName ?? 'Du',
      text: text,
      timestamp: DateTime.now(),
    ));

    // Via DataChannel broadcasten
    final payload = jsonEncode({
      'type': 'caption',
      'text': text,
      'identity': _localIdentity ?? '',
      'name': _localName ?? '',
    });
    try {
      await lp.publishData(utf8.encode(payload), reliable: true);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ caption broadcast failed: $e');
    }
  }

  void dispose() {
    _restartTimer?.cancel();
    _captionsCtrl.close();
    _stt.cancel();
  }
}
