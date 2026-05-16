// Web-Stub für audioplayers — alle Methoden sind no-ops.

import 'dart:async';

enum PlayerState { stopped, playing, paused, completed, disposed }

enum ReleaseMode { release, loop, stop }

enum PlayerMode { mediaPlayer, lowLatency }

abstract class Source {
  const Source();
}

class AssetSource extends Source {
  final String path;
  const AssetSource(this.path);
}

class UrlSource extends Source {
  final String url;
  const UrlSource(this.url);
}

class DeviceFileSource extends Source {
  final String path;
  const DeviceFileSource(this.path);
}

class BytesSource extends Source {
  final List<int> bytes;
  const BytesSource(this.bytes);
}

class AudioPlayer {
  AudioPlayer();

  PlayerState state = PlayerState.stopped;

  Future<void> play(Source source,
      {double? volume,
      double? balance,
      Object? ctx,
      Duration? position,
      PlayerMode? mode}) async {}
  Future<void> pause() async {}
  Future<void> resume() async {}
  Future<void> stop() async {}
  Future<void> release() async {}
  Future<void> seek(Duration position) async {}
  Future<void> dispose() async {}
  Future<void> setVolume(double volume) async {}
  Future<void> setBalance(double balance) async {}
  Future<void> setPlaybackRate(double rate) async {}
  Future<void> setReleaseMode(ReleaseMode mode) async {}
  Future<void> setPlayerMode(PlayerMode mode) async {}
  Future<void> setSource(Source source) async {}
  Future<void> setSourceUrl(String url) async {}
  Future<void> setSourceAsset(String path) async {}
  Future<void> setSourceDeviceFile(String path) async {}
  Future<void> setSourceBytes(List<int> bytes) async {}
  Future<Duration?> getDuration() async => null;
  Future<Duration?> getCurrentPosition() async => null;

  Stream<PlayerState> get onPlayerStateChanged => const Stream.empty();
  Stream<Duration> get onPositionChanged => const Stream.empty();
  Stream<Duration> get onDurationChanged => const Stream.empty();
  Stream<void> get onPlayerComplete => const Stream.empty();
  Stream<void> get onSeekComplete => const Stream.empty();
}
