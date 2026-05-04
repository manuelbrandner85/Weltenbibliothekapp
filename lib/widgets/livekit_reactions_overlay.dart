/// 💖 Bundle 4: Floating-Reactions-Overlay für LiveKit Group Call
///
/// Lauscht auf [LiveKitCallService.reactionsStream] und zeichnet jede
/// empfangene Reaction als floating Emoji die nach oben treibt + ausfadet.
/// Mehrere parallel — jedes Event spawned ein eigenes _FloatingEmoji.
///
/// Animation:
///   - Start: zufälliger X-Offset im unteren Drittel
///   - Dauer: 3.5s
///   - Path: leicht zickzack (sin-wave) nach oben
///   - Scale: 0 → 1.4 (pop) → 0.8 (decay)
///   - Opacity: 0 → 1 → 0
library;

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../services/livekit_call_service.dart';

/// Verfügbare Reaktions-Emojis im WB-Style.
/// Pro Welt eine eigene Mischung — Energie eher esoterisch,
/// Materie eher kraftvoll/wissenschaftlich.
const List<String> kEnergieReactions = [
  '✨', '💜', '🙏', '🕊️', '🪷', '🔮', '🌙', '⭐',
];

const List<String> kMaterieReactions = [
  '🔥', '💪', '🚀', '👁️', '⚡', '🛸', '🧠', '🌍',
];

class LiveKitReactionsOverlay extends StatefulWidget {
  final Stream<ReactionEvent> reactions;

  const LiveKitReactionsOverlay({super.key, required this.reactions});

  @override
  State<LiveKitReactionsOverlay> createState() =>
      _LiveKitReactionsOverlayState();
}

class _LiveKitReactionsOverlayState extends State<LiveKitReactionsOverlay> {
  final List<_FloatingEmojiData> _items = [];
  StreamSubscription<ReactionEvent>? _sub;
  final math.Random _rnd = math.Random();
  int _nextId = 0;

  @override
  void initState() {
    super.initState();
    _sub = widget.reactions.listen(_onReaction);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onReaction(ReactionEvent ev) {
    if (!mounted) return;
    setState(() {
      _items.add(_FloatingEmojiData(
        id: _nextId++,
        emoji: ev.emoji,
        startXFraction: 0.15 + _rnd.nextDouble() * 0.7,
        wavePhase: _rnd.nextDouble() * math.pi * 2,
      ));
    });
  }

  void _removeItem(int id) {
    if (!mounted) return;
    setState(() {
      _items.removeWhere((it) => it.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    // IgnorePointer damit das Overlay keine Touch-Events frisst
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final item in _items)
            _FloatingEmoji(
              key: ValueKey('reaction_${item.id}'),
              data: item,
              onComplete: () => _removeItem(item.id),
            ),
        ],
      ),
    );
  }
}

class _FloatingEmojiData {
  final int id;
  final String emoji;
  final double startXFraction;
  final double wavePhase;
  _FloatingEmojiData({
    required this.id,
    required this.emoji,
    required this.startXFraction,
    required this.wavePhase,
  });
}

class _FloatingEmoji extends StatefulWidget {
  final _FloatingEmojiData data;
  final VoidCallback onComplete;
  const _FloatingEmoji({super.key, required this.data, required this.onComplete});

  @override
  State<_FloatingEmoji> createState() => _FloatingEmojiState();
}

class _FloatingEmojiState extends State<_FloatingEmoji>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onComplete();
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value; // 0..1

        // Y: vom unteren 75% zum oberen 10%
        final yStart = size.height * 0.75;
        final yEnd = size.height * 0.10;
        final y = yStart + (yEnd - yStart) * t;

        // X: leichter Zickzack via sin
        final waveAmplitude = 30.0;
        final xBase = size.width * widget.data.startXFraction;
        final x = xBase +
            math.sin(t * math.pi * 2 + widget.data.wavePhase) *
                waveAmplitude *
                t;

        // Scale: pop → decay
        final scale = t < 0.2
            ? (t / 0.2) * 1.4 // 0 → 1.4
            : 1.4 - ((t - 0.2) / 0.8) * 0.6; // 1.4 → 0.8

        // Opacity: in → halten → out
        final opacity = t < 0.15
            ? t / 0.15
            : (t > 0.7 ? (1.0 - (t - 0.7) / 0.3) : 1.0);

        return Positioned(
          left: x - 24,
          top: y - 24,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: Text(
                widget.data.emoji,
                style: TextStyle(
                  fontSize: 44,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
