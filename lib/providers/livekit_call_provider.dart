/// 🎥 LiveKit-Call Riverpod-Provider
///
/// Stellt einen geteilten LiveKitCallService als Provider bereit, damit alle
/// Widgets im Call-Tree (Grid, Control-Bar, Chat-Panel, Settings) die selbe
/// Service-Instanz konsumieren und auf Änderungen reagieren.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';

import '../services/livekit_call_service.dart';

/// Singleton-Service über die ganze App.
final livekitCallServiceProvider = Provider<LiveKitCallService>((ref) {
  final svc = LiveKitCallService();
  ref.onDispose(svc.dispose);
  return svc;
});

/// Reaktive Service-Wrapper — UI baut sich neu sobald notifyListeners feuert.
final livekitCallProvider =
    ChangeNotifierProvider<LiveKitCallService>((ref) {
  return ref.watch(livekitCallServiceProvider);
});

/// Convenience: Connection-State (für Top-Bar-Indicator).
final livekitConnectionStateProvider =
    Provider<LiveKitConnectionState>((ref) {
  return ref.watch(livekitCallProvider).connectionState;
});

/// Convenience: ist gerade ein Call aktiv? (für Mini-Banner in Chat-Screens)
final livekitIsInCallProvider = Provider<bool>((ref) {
  final state = ref.watch(livekitConnectionStateProvider);
  return state == LiveKitConnectionState.connected ||
      state == LiveKitConnectionState.reconnecting;
});

/// Convenience: Teilnehmerliste mit lokaler Reihenfolge (Local zuerst).
final livekitParticipantsProvider = Provider<List<Participant>>((ref) {
  return ref.watch(livekitCallProvider).participants;
});

@visibleForTesting
ProviderContainer createTestContainer() => ProviderContainer();
