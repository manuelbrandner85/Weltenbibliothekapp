/// 🔊 AudioFeedbackService — B10.8 Spatial Audio + Call-Sounds
///
/// - Join/Leave-Chimes (synthetisiert via just_audio BytesSource)
/// - Hand-Raise-Ton + visuelle Toast-Benachrichtigung
/// - Spatial Ducking: aktiver Sprecher 1.0, Stille 0.65 — hilft beim Fokus
library;

import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

// ─── Raum-Themes (B10.6) ────────────────────────────────────────────────────

enum RoomTheme {
  /// Standard — Welt-spezifischer Painter (bisheriges Aussehen)
  standard,
  /// Materie: pulsierendes Netzwerk-Geflecht + blaue Datenpunkte
  netzwerk,
  /// Materie: Weltraum-Nebel mit roten Gaswolken + Sternfeld
  kosmos,
  /// Energie: rotierendes Mandala-Muster
  mandala,
  /// Energie: schwebende Kristall-Scherben mit Prisma-Licht
  kristall,
}

extension RoomThemeInfo on RoomTheme {
  String get label {
    switch (this) {
      case RoomTheme.standard:
        return 'Standard';
      case RoomTheme.netzwerk:
        return 'Netzwerk';
      case RoomTheme.kosmos:
        return 'Kosmos';
      case RoomTheme.mandala:
        return 'Mandala';
      case RoomTheme.kristall:
        return 'Kristall';
    }
  }

  String get description {
    switch (this) {
      case RoomTheme.standard:
        return 'Welt-spezifisches Standard-Design';
      case RoomTheme.netzwerk:
        return 'Pulsierendes Datennetz mit Knotenpunkten';
      case RoomTheme.kosmos:
        return 'Weltraum-Nebel mit roten Gaswolken';
      case RoomTheme.mandala:
        return 'Rotierendes Bewusstseins-Mandala';
      case RoomTheme.kristall:
        return 'Schwebende Licht-Kristalle';
    }
  }

  IconData get icon {
    switch (this) {
      case RoomTheme.standard:
        return Icons.palette_outlined;
      case RoomTheme.netzwerk:
        return Icons.account_tree_rounded;
      case RoomTheme.kosmos:
        return Icons.stars_rounded;
      case RoomTheme.mandala:
        return Icons.blur_circular_rounded;
      case RoomTheme.kristall:
        return Icons.diamond_outlined;
    }
  }

  /// Welche Themes gehören zu welcher Welt?
  bool availableFor(String world) {
    switch (this) {
      case RoomTheme.standard:
        return true;
      case RoomTheme.netzwerk:
      case RoomTheme.kosmos:
        return world == 'materie';
      case RoomTheme.mandala:
      case RoomTheme.kristall:
        return world == 'energie';
    }
  }
}

// ─── AudioFeedbackService ────────────────────────────────────────────────────

class AudioFeedbackService {
  AudioFeedbackService._();
  static final instance = AudioFeedbackService._();

  // B10.8: Spatial Ducking — Volumen-Map pro Participant-Identity
  final _volumes = <String, double>{};
  bool _spatialEnabled = true;
  lk.Room? _room;

  // B10.6: Raumstimmung
  final _themeNotifier = ValueNotifier<RoomTheme>(RoomTheme.standard);
  ValueNotifier<RoomTheme> get themeNotifier => _themeNotifier;
  RoomTheme get currentTheme => _themeNotifier.value;

  void setTheme(RoomTheme theme) => _themeNotifier.value = theme;

  // ─── Room-Lifecycle ────────────────────────────────────────────────────────

  void attachRoom(lk.Room room) {
    _room = room;
    _volumes.clear();
    _applyDucking();
  }

  void detachRoom() {
    _volumes.clear();
    _room = null;
  }

  // ─── B10.8: Spatial Ducking ────────────────────────────────────────────────

  bool get spatialEnabled => _spatialEnabled;

  void toggleSpatial() {
    _spatialEnabled = !_spatialEnabled;
    // Hinweis: livekit_client 2.x stellt kein setVolume() auf RemoteParticipant
    // bereit (nur Web-SDK). Spatial Audio ist derzeit Visual-only — der aktive
    // Sprecher wird durch den Aura-Glow in der ParticipantTile hervorgehoben.
    // Audio-Ducking wird aktiviert sobald livekit_client ein Volume-API liefert.
  }

  /// Wird von LiveKitCallService aufgerufen wenn sich aktive Sprecher ändern.
  /// Derzeit nur Tracking — Volume-Manipulation nicht verfügbar in livekit_client 2.x.
  void updateActiveSpeakers(Set<String> activeSpeakerIdentities) {
    if (!_spatialEnabled) return;
    // Volume-Ducking: livekit_client 2.5.x hat kein setVolume() auf
    // RemoteParticipant (nur WebAudio im Browser-SDK). Wir tracken den State
    // und können in einer späteren SDK-Version aktivieren.
    for (final identity in activeSpeakerIdentities) {
      _volumes[identity] = 1.0;
    }
    if (_room != null) {
      for (final p in _room!.remoteParticipants.values) {
        if (!activeSpeakerIdentities.contains(p.identity)) {
          _volumes[p.identity] = 0.65;
        }
      }
    }
  }

  // ─── B10.8: Synthesized Call-Sounds ───────────────────────────────────────

  /// Erzeugt einen WAV-Puffer (44.1 kHz, 16-bit Mono) für einen
  /// synthetisierten Ton. Wird inline ohne externe Dateien abgespielt.
  static Uint8List _generateTone({
    required double frequency,
    required double durationSec,
    double volume = 0.35,
    double fadeRatio = 0.15,
  }) {
    const sampleRate = 44100;
    final numSamples = (sampleRate * durationSec).round();
    final fadeSamples = (numSamples * fadeRatio).round();

    final data = Int16List(numSamples);
    for (int i = 0; i < numSamples; i++) {
      double env = 1.0;
      if (i < fadeSamples) env = i / fadeSamples;
      if (i > numSamples - fadeSamples) {
        env = (numSamples - i) / fadeSamples;
      }
      final sample =
          (math.sin(2 * math.pi * frequency * i / sampleRate) * 32767 * volume * env)
              .round()
              .clamp(-32767, 32767);
      data[i] = sample;
    }

    // WAV-Header zusammenbauen
    final byteData = ByteData(44 + numSamples * 2);
    // RIFF
    byteData.setUint8(0, 0x52); byteData.setUint8(1, 0x49);
    byteData.setUint8(2, 0x46); byteData.setUint8(3, 0x46);
    byteData.setUint32(4, 36 + numSamples * 2, Endian.little);
    byteData.setUint8(8, 0x57); byteData.setUint8(9, 0x41);
    byteData.setUint8(10, 0x56); byteData.setUint8(11, 0x45);
    // fmt chunk
    byteData.setUint8(12, 0x66); byteData.setUint8(13, 0x6D);
    byteData.setUint8(14, 0x74); byteData.setUint8(15, 0x20);
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little); // PCM
    byteData.setUint16(22, 1, Endian.little); // Mono
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little);
    byteData.setUint16(32, 2, Endian.little);
    byteData.setUint16(34, 16, Endian.little);
    // data chunk
    byteData.setUint8(36, 0x64); byteData.setUint8(37, 0x61);
    byteData.setUint8(38, 0x74); byteData.setUint8(39, 0x61);
    byteData.setUint32(40, numSamples * 2, Endian.little);
    for (int i = 0; i < numSamples; i++) {
      byteData.setInt16(44 + i * 2, data[i], Endian.little);
    }
    return byteData.buffer.asUint8List();
  }

  // Vorgenerierte Töne (lazy, einmalig erstellt)
  Uint8List? _joinSound;
  Uint8List? _leaveSound;
  Uint8List? _handSound;
  Uint8List? _muteSound;

  Uint8List get joinWav => _joinSound ??= _generateTone(
        frequency: 880,
        durationSec: 0.18,
        volume: 0.28,
        fadeRatio: 0.25,
      );

  Uint8List get leaveWav => _leaveSound ??= _generateTone(
        frequency: 440,
        durationSec: 0.22,
        volume: 0.22,
        fadeRatio: 0.30,
      );

  Uint8List get handRaiseWav => _handSound ??= _generateTone(
        frequency: 660,
        durationSec: 0.14,
        volume: 0.25,
        fadeRatio: 0.20,
      );

  Uint8List get muteToggleWav => _muteSound ??= _generateTone(
        frequency: 520,
        durationSec: 0.08,
        volume: 0.18,
        fadeRatio: 0.20,
      );
}
