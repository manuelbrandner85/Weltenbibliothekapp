/// 🎵 B10.1 + B10.2 — Soundscape & Heilfrequenz-Player
///
/// Generiert Sinus-Wellen in Dart (kein Audio-Asset nötig → PATCH-kompatibel).
/// Materie: 40 Hz + 44 Hz Mix (4 Hz binauraler Beat) → Konzentration, Erdung.
/// Energie: 432 Hz (Naturstimmung) → ruhige Atmosphäre.
/// Heilfrequenz: Solfeggio-Frequenzen 174–963 Hz (nur Energie-Welt).
///
/// Nutzt `audioplayers` BytesSource + ReleaseMode.loop.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

// Solfeggio-Frequenzen mit Beschreibung
class HeilfrequenzEntry {
  final int hz;
  final String label;
  final String description;
  const HeilfrequenzEntry(this.hz, this.label, this.description);
}

const List<HeilfrequenzEntry> kHeilfrequenzen = [
  HeilfrequenzEntry(174, '174 Hz', 'Schmerzlinderung & Entspannung'),
  HeilfrequenzEntry(285, '285 Hz', 'Geweberegeneration & Heilung'),
  HeilfrequenzEntry(396, '396 Hz', 'Schuld & Angst loslassen'),
  HeilfrequenzEntry(417, '417 Hz', 'Veränderung & Neuanfang'),
  HeilfrequenzEntry(432, '432 Hz', 'Naturstimmung & Harmonie'),
  HeilfrequenzEntry(528, '528 Hz', 'DNA-Reparatur & Liebe'),
  HeilfrequenzEntry(639, '639 Hz', 'Verbindung & Beziehung'),
  HeilfrequenzEntry(741, '741 Hz', 'Ausdruck & Bewusstsein'),
  HeilfrequenzEntry(852, '852 Hz', 'Intuition & innere Ordnung'),
  HeilfrequenzEntry(963, '963 Hz', 'Erleuchtung & höheres Bewusstsein'),
];

class SoundscapeService {
  SoundscapeService._();
  static final SoundscapeService instance = SoundscapeService._();

  static const int _sampleRate = 22050; // 22 kHz — guter Kompromiss Qualität/Größe
  static const int _durationSec = 5; // 5-Sekunden-Loop
  static const double _defaultVolume = 0.12; // 12 % — sehr leise im Hintergrund

  final AudioPlayer _soundscapePlayer = AudioPlayer();
  final AudioPlayer _heilPlayer = AudioPlayer();

  bool _soundscapeEnabled = false;
  bool get soundscapeEnabled => _soundscapeEnabled;

  bool _heilEnabled = false;
  bool get heilEnabled => _heilEnabled;

  int _heilHz = 432; // Standard: 432 Hz Naturstimmung
  int get heilHz => _heilHz;

  // ── Soundscape (Atmosphäre) ────────────────────────────────────────────────

  /// Schaltet Soundscape ein/aus. Gibt neuen Status zurück.
  Future<bool> toggleSoundscape(String world) async {
    if (_soundscapeEnabled) {
      await _soundscapePlayer.stop();
      _soundscapeEnabled = false;
      return false;
    }
    _soundscapeEnabled = true;
    await _playLoop(
      player: _soundscapePlayer,
      wavBytes: _generateSoundscape(world),
    );
    return true;
  }

  /// Stoppt Soundscape (z.B. beim Verlassen des Calls).
  Future<void> stopSoundscape() async {
    if (_soundscapeEnabled) {
      await _soundscapePlayer.stop();
      _soundscapeEnabled = false;
    }
  }

  // ── Heilfrequenz ──────────────────────────────────────────────────────────

  /// Schaltet Heilfrequenz-Player ein/aus. Gibt neuen Status zurück.
  Future<bool> toggleHeilfrequenz({int? hz}) async {
    if (hz != null && hz != _heilHz) {
      // Frequenz gewechselt → neu laden
      _heilHz = hz;
      if (_heilEnabled) {
        await _heilPlayer.stop();
        await _playLoop(
          player: _heilPlayer,
          wavBytes: _generateSine(_heilHz, volume: 0.10),
        );
        return true;
      }
    }
    if (_heilEnabled) {
      await _heilPlayer.stop();
      _heilEnabled = false;
      return false;
    }
    _heilEnabled = true;
    await _playLoop(
      player: _heilPlayer,
      wavBytes: _generateSine(_heilHz, volume: 0.10),
    );
    return true;
  }

  /// Stoppt Heilfrequenz (z.B. beim Verlassen des Calls).
  Future<void> stopHeilfrequenz() async {
    if (_heilEnabled) {
      await _heilPlayer.stop();
      _heilEnabled = false;
    }
  }

  /// Stoppt alles — bei leaveRoom aufrufen.
  Future<void> stopAll() async {
    await stopSoundscape();
    await stopHeilfrequenz();
  }

  // ── Private Helpers ────────────────────────────────────────────────────────

  Future<void> _playLoop({
    required AudioPlayer player,
    required Uint8List wavBytes,
  }) async {
    try {
      await player.setVolume(_defaultVolume);
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(BytesSource(wavBytes));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ SoundscapeService play error: $e');
    }
  }

  /// Generiert welt-spezifisches Soundscape als WAV-Bytes.
  Uint8List _generateSoundscape(String world) {
    if (world == 'materie') {
      // Materie: 40 Hz + 44 Hz (4 Hz binauraler Beat — Gamma-Bereich)
      return _generateBinaural(40, 44, volume: 0.55);
    } else {
      // Energie: 432 Hz Naturstimmung, sehr subtil
      return _generateSine(432, volume: 0.45);
    }
  }

  /// Generiert eine einzelne Sinuswelle als WAV.
  Uint8List _generateSine(int freqHz, {double volume = 1.0}) {
    final totalSamples = _sampleRate * _durationSec;
    final fadeSamples = (_sampleRate * 0.020).round(); // 20ms Fade

    final samples = Int16List(totalSamples);
    final amplitude = (32767 * volume).round();

    for (int i = 0; i < totalSamples; i++) {
      final t = i / _sampleRate;
      double fade = 1.0;
      if (i < fadeSamples) fade = i / fadeSamples;
      if (i >= totalSamples - fadeSamples) {
        fade = (totalSamples - i) / fadeSamples;
      }
      final raw = math.sin(2 * math.pi * freqHz * t);
      samples[i] = (raw * amplitude * fade).round().clamp(-32768, 32767);
    }
    return _buildWav(samples);
  }

  /// Generiert einen binauralen Mix aus zwei Frequenzen.
  Uint8List _generateBinaural(int hz1, int hz2, {double volume = 1.0}) {
    final totalSamples = _sampleRate * _durationSec;
    final fadeSamples = (_sampleRate * 0.020).round();

    final samples = Int16List(totalSamples);
    final amplitude = (32767 * volume * 0.5).round(); // 0.5 weil 2 Wellen summiert

    for (int i = 0; i < totalSamples; i++) {
      final t = i / _sampleRate;
      double fade = 1.0;
      if (i < fadeSamples) fade = i / fadeSamples;
      if (i >= totalSamples - fadeSamples) {
        fade = (totalSamples - i) / fadeSamples;
      }
      final raw = math.sin(2 * math.pi * hz1 * t) +
          math.sin(2 * math.pi * hz2 * t);
      samples[i] = (raw * amplitude * fade).round().clamp(-32768, 32767);
    }
    return _buildWav(samples);
  }

  /// Baut einen gültigen WAV-Header + PCM-Daten.
  Uint8List _buildWav(Int16List samples) {
    const int channels = 1; // Mono
    const int bitsPerSample = 16;
    const int byteRate = _sampleRate * channels * (bitsPerSample ~/ 8);
    final int dataSize = samples.length * (bitsPerSample ~/ 8);
    final int fileSize = 44 + dataSize;

    final out = ByteData(fileSize);
    int offset = 0;

    // RIFF header
    _writeAscii(out, offset, 'RIFF'); offset += 4;
    out.setUint32(offset, fileSize - 8, Endian.little); offset += 4;
    _writeAscii(out, offset, 'WAVE'); offset += 4;

    // fmt chunk
    _writeAscii(out, offset, 'fmt '); offset += 4;
    out.setUint32(offset, 16, Endian.little); offset += 4; // chunk size
    out.setUint16(offset, 1, Endian.little); offset += 2; // PCM
    out.setUint16(offset, channels, Endian.little); offset += 2;
    out.setUint32(offset, _sampleRate, Endian.little); offset += 4;
    out.setUint32(offset, byteRate, Endian.little); offset += 4;
    out.setUint16(offset, channels * (bitsPerSample ~/ 8), Endian.little); offset += 2; // block align
    out.setUint16(offset, bitsPerSample, Endian.little); offset += 2;

    // data chunk
    _writeAscii(out, offset, 'data'); offset += 4;
    out.setUint32(offset, dataSize, Endian.little); offset += 4;

    for (final sample in samples) {
      out.setInt16(offset, sample, Endian.little);
      offset += 2;
    }

    return out.buffer.asUint8List();
  }

  void _writeAscii(ByteData data, int offset, String s) {
    for (int i = 0; i < s.length; i++) {
      data.setUint8(offset + i, s.codeUnitAt(i));
    }
  }
}
