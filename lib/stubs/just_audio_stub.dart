// Web-Stub für just_audio — alle Methoden sind no-ops.

import 'dart:async';
import 'dart:typed_data';

enum LoopMode { off, one, all }

enum ProcessingState { idle, loading, buffering, ready, completed }

class PlayerState {
  final bool playing;
  final ProcessingState processingState;
  const PlayerState(this.playing, this.processingState);
}

abstract class AudioSource {
  const AudioSource();
}

class StreamAudioResponse {
  final int? sourceLength;
  final int contentLength;
  final int offset;
  final Stream<List<int>> stream;
  final String contentType;

  const StreamAudioResponse({
    this.sourceLength,
    required this.contentLength,
    required this.offset,
    required this.stream,
    required this.contentType,
  });
}

abstract class StreamAudioSource extends AudioSource {
  StreamAudioSource({dynamic tag});
  Future<StreamAudioResponse> request([int? start, int? end]);
}

class AudioPlayer {
  AudioPlayer();

  bool get playing => false;
  Duration? get duration => null;
  Duration get position => Duration.zero;
  ProcessingState get processingState => ProcessingState.idle;

  Future<Duration?> setUrl(String url) async => null;
  Future<Duration?> setFilePath(String path) async => null;
  Future<Duration?> setAsset(String path) async => null;
  Future<Duration?> setAudioSource(AudioSource source,
          {Duration? initialPosition,
          int? initialIndex,
          bool preload = true}) async =>
      null;
  Future<void> play() async {}
  Future<void> pause() async {}
  Future<void> stop() async {}
  Future<void> seek(Duration? position, {int? index}) async {}
  Future<void> setVolume(double volume) async {}
  Future<void> setSpeed(double speed) async {}
  Future<void> setLoopMode(LoopMode mode) async {}
  Future<void> setShuffleModeEnabled(bool enabled) async {}
  Future<void> dispose() async {}

  Stream<PlayerState> get playerStateStream => const Stream.empty();
  Stream<Duration> get positionStream => const Stream.empty();
  Stream<Duration?> get durationStream => const Stream.empty();
  Stream<bool> get playingStream => const Stream.empty();
  Stream<ProcessingState> get processingStateStream => const Stream.empty();
}

// Avoid unused import warning for Uint8List in case consumers import it transitively.
// ignore: unused_element
Uint8List _unused() => Uint8List(0);
