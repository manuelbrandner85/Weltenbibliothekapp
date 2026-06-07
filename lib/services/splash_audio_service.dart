// 🔊 Splash intro audio — fire-and-forget, lifecycle-independent playback.
//
// The cinematic splash should play `assets/audio/splash_intro.mp3` IN FULL,
// even after the splash widget is disposed and the app navigates onward.
// To achieve this, this service owns ONE AudioPlayer that lives outside any
// widget lifecycle (singleton). It self-releases when playback completes.
//
// NOTE: a new asset like this MP3 only reaches the device with a full APK
// RELEASE — it is NOT included in a Shorebird OTA Dart patch. If the splash
// is silent on an OTA-patched build, the asset simply isn't bundled yet.
//
// Uses the same conditional-import pattern as the rest of the codebase so it
// compiles on web (where audioplayers is a no-op stub).

import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
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

      // Self-release once playback finishes — set up BEFORE play() so a very
      // short clip can never complete before the listener is attached.
      p.onPlayerComplete.listen((_) {
        p.dispose();
        if (_player == p) _player = null;
      });

      // release: free native resources when done (single playthrough).
      await p.setReleaseMode(ReleaseMode.release);
      // mediaPlayer mode -> STREAM_MUSIC on Android (plays in vibrate/silent
      // ring profile as long as media volume is up).
      await p.setPlayerMode(PlayerMode.mediaPlayer);
      // Full volume — the splash intro is meant to be heard.
      await p.setVolume(1.0);
      // Path is relative to the assets/ root for audioplayers.
      await p.play(AssetSource('audio/splash_intro.mp3'));
    } catch (e) {
      // Audio is non-critical; never block the splash on failure. Log in debug
      // so a missing asset (OTA-patched build) is diagnosable.
      if (kDebugMode) debugPrint('⚠️ SplashAudioService.playOnce: $e');
      _started = false; // allow a retry on next splash mount
    }
  }

  /// Optional manual stop (e.g. if you ever need it). Not called on skip
  /// because the user wants full playback.
  Future<void> stop() async {
    try {
      await _player?.stop();
      await _player?.dispose();
    } catch (e) { if (kDebugMode) debugPrint('splash_audio_service: silent catch -> $e'); }
    _player = null;
  }
}
