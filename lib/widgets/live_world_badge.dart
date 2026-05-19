// Live-Activity-Badge für World-Cards im Portal.
//
// Zeigt "🔴 N im Stream" wenn aktuell Voice-Sessions in der Welt aktiv
// sind. Subscribt auf voice_sessions via VoiceSessionService + Realtime,
// poll-fallback alle 30s. Bei 0 aktiven Sessions: unsichtbar (kein Platz
// verschwendet auf inaktive Welten).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/voice_session_service.dart';

class LiveWorldBadge extends StatefulWidget {
  final String world;
  final Color accent;

  const LiveWorldBadge({
    super.key,
    required this.world,
    required this.accent,
  });

  @override
  State<LiveWorldBadge> createState() => _LiveWorldBadgeState();
}

class _LiveWorldBadgeState extends State<LiveWorldBadge>
    with SingleTickerProviderStateMixin {
  int _liveCount = 0;
  RealtimeChannel? _channel;
  Timer? _poll;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _load();
    _subscribe();
    _poll = Timer.periodic(const Duration(seconds: 45), (_) => _load());
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _poll?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final sessions =
          await VoiceSessionService.instance.getActiveSessions(widget.world);
      if (!mounted) return;
      final total = sessions.values.fold<int>(0, (s, list) => s + list.length);
      if (total != _liveCount) setState(() => _liveCount = total);
    } catch (_) {}
  }

  void _subscribe() {
    try {
      _channel = Supabase.instance.client
          .channel(
              'world-badge-${widget.world}-${DateTime.now().millisecondsSinceEpoch}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'voice_sessions',
            callback: (_) => _load(),
          )
          .subscribe();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_liveCount == 0) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final alpha = 0.5 + 0.5 * _pulse.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.18 * alpha),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.45 * alpha),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withValues(alpha: alpha),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$_liveCount LIVE',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
