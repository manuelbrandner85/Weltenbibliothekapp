// 🔊 Splash intro audio — fire-and-forget, lifecycle-independent playback.
//
// The cinematic splash should play `assets/audio/splash_intro.mp3` IN FULL,
// even after the splash widget is disposed and the app navigates onward.
// To achieve this, this service owns ONE AudioPlayer that lives outside any
// widget lifecycle (singleton). It self-releases when playback completes.
//
// Uses the same conditional-import pattern as the rest of the codebase so it
// compiles on web (where audioplayers is a no-op stub).

import 'package:audioplayers/audioplayers.dart'
    if (dart.library.html) '../stubs/audioplayers_stub.dart';

class SplashAudioService {
  SplashAudioService._();
  static final SplashAudioService instance = SplashAudioService._();

  AudioPlayer? _player;
  bool _started = false;

  /// Plays the splash intro once, fully. Safe to call multiple times
  /// (no-op after the first). Releases itself when playback completes.
  Future<void> playOnce() async {
    if (_started) return;
    _started = true;
    try {
      final p = AudioPlayer();
      _player = p;
      await p.setReleaseMode(ReleaseMode.release);
      // Play asset; path is relative to the assets/ root for audioplayers.
      await p.play(AssetSource('audio/splash_intro.mp3'));
      p.onPlayerComplete.listen((_) {
        p.dispose();
        if (_player == p) _player = null;
      });
    } catch (_) {
      // Audio is non-critical; never block the splash on failure.
    }
  }

  /// Optional manual stop (e.g. if you ever need it). Not called on skip
  /// because the user wants full playback.
  Future<void> stop() async {
    try {
      await _player?.stop();
      await _player?.dispose();
    } catch (_) {}
    _player = null;
  }
}
