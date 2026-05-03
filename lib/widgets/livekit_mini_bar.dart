/// 📞 LIVEKIT MINI-BAR — Floating Live-Indicator beim Multi-Tasking
///
/// Zeigt sich automatisch oben am Screen wenn ein LiveKit-Call aktiv ist UND
/// der User NICHT aktuell auf dem LiveKitGroupCallScreen ist (also minimiert
/// hat oder zur normalen App-Navigation zurückgekehrt ist).
///
/// Tap auf Bar → öffnet wieder den LiveKitGroupCallScreen.
/// Auflegen-Button → beendet den Anruf direkt von der Bar.
/// Mute-Button → toggelt Mikrofon ohne Screen zu öffnen.
///
/// Wird in main.dart über MaterialApp.builder injiziert damit es über
/// jedem Screen liegt.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/wb_design.dart';
import '../providers/livekit_call_provider.dart';
import '../screens/shared/livekit_group_call_screen.dart';
import '../services/livekit_call_service.dart';

/// Globaler Marker: ist der LiveKitGroupCallScreen gerade sichtbar?
/// Wird vom Screen selbst gesetzt damit die Mini-Bar weiß sich zu verstecken.
class LiveKitScreenVisibility extends ChangeNotifier {
  static final instance = LiveKitScreenVisibility._();
  LiveKitScreenVisibility._();

  bool _visible = false;
  bool get visible => _visible;

  void setVisible(bool v) {
    if (_visible != v) {
      _visible = v;
      notifyListeners();
    }
  }
}

class LiveKitMiniBar extends ConsumerWidget {
  const LiveKitMiniBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.watch(livekitCallProvider);
    final connected = svc.connectionState == LiveKitConnectionState.connected ||
        svc.connectionState == LiveKitConnectionState.reconnecting;

    return AnimatedBuilder(
      animation: LiveKitScreenVisibility.instance,
      builder: (context, _) {
        // Show only when in call AND screen is NOT currently visible
        final shouldShow = connected &&
            !LiveKitScreenVisibility.instance.visible &&
            svc.roomName != null &&
            svc.world != null;

        return AnimatedSlide(
          offset: shouldShow ? Offset.zero : const Offset(0, -1.5),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: shouldShow ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: shouldShow
                ? _MiniBarContent(svc: svc)
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

class _MiniBarContent extends StatelessWidget {
  final LiveKitCallService svc;
  const _MiniBarContent({required this.svc});

  String _formatDuration(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  void _expandToFull(BuildContext context) {
    // 🛑 Bundle 3.6: Wenn der Vollbild-Screen schon offen ist (oder gerade
    // animiert), nicht nochmal pushen — sonst stapeln sich mehrere Screens.
    if (LiveKitScreenVisibility.instance.visible) return;
    final world = svc.world ?? 'materie';
    final roomName = svc.roomName ?? '';
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => LiveKitGroupCallScreen(
          roomName: roomName,
          world: world,
          displayName: svc.localDisplayName ?? 'Mitglied',
          avatarUrl: svc.localAvatarUrl,
        ),
      ),
    );
  }

  Future<void> _hangUp(BuildContext context) async {
    await svc.leaveRoom();
  }

  @override
  Widget build(BuildContext context) {
    final world = svc.world ?? 'materie';
    final accent = WbDesign.accent(world);

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: GestureDetector(
            onTap: () => _expandToFull(context),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: WbDesign.surface(world).withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accent.withValues(alpha: 0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Pulsing live-dot
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50)
                              .withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Welt-Branding + Dauer
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Live · ${svc.totalParticipantCount} ${svc.totalParticipantCount == 1 ? "Teilnehmer" : "Teilnehmer"}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatDuration(svc.callDurationSeconds),
                          style: TextStyle(
                            color: accent.withValues(alpha: 0.85),
                            fontSize: 11,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Mute-Button
                  IconButton(
                    tooltip: svc.micEnabled
                        ? 'Mikrofon stumm'
                        : 'Mikrofon an',
                    icon: Icon(
                      svc.micEnabled
                          ? Icons.mic_rounded
                          : Icons.mic_off_rounded,
                      color: svc.micEnabled
                          ? Colors.white
                          : Colors.white60,
                      size: 20,
                    ),
                    onPressed: () => svc.toggleMicrophone(),
                    constraints: const BoxConstraints(
                        minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                  // Hangup-Button
                  IconButton(
                    tooltip: 'Auflegen',
                    icon: const Icon(
                      Icons.call_end_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () => _hangUp(context),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFF1744),
                      shape: const CircleBorder(),
                      minimumSize: const Size(36, 36),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
