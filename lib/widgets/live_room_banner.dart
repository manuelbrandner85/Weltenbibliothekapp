/// 📺 LiveRoomBanner — Telegram-ähnlicher Banner für aktive Anrufe
///
/// Wird am oberen Rand des Chat-Screens gezeigt wenn in einer Welt
/// gerade jemand in einem Sprach-/Videoraum ist.
/// Tip auf den Banner → direkt dem Anruf beitreten.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/wb_design.dart';
import '../services/voice_session_service.dart';

class LiveRoomBanner extends StatefulWidget {
  final String world;
  final String currentRoomName;
  final Function(String roomName) onJoin;

  const LiveRoomBanner({
    super.key,
    required this.world,
    required this.currentRoomName,
    required this.onJoin,
  });

  @override
  State<LiveRoomBanner> createState() => _LiveRoomBannerState();
}

class _LiveRoomBannerState extends State<LiveRoomBanner>
    with SingleTickerProviderStateMixin {
  // { roomName → List<{ username, displayName }> }
  Map<String, List<Map<String, dynamic>>> _sessions = {};
  RealtimeChannel? _channel;
  Timer? _refreshTimer;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _loadSessions();
    _subscribeRealtime();
    // Fallback-Refresh alle 30 Sekunden
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadSessions();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _refreshTimer?.cancel();
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    final data = await VoiceSessionService.instance
        .getActiveSessions(widget.world);
    if (mounted) setState(() => _sessions = data);
  }

  void _subscribeRealtime() {
    _channel = Supabase.instance.client
        .channel('voice_sessions_${widget.world}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'voice_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'world',
            value: widget.world,
          ),
          callback: (_) => _loadSessions(),
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    // Nur Räume anzeigen die nicht der aktuelle Raum des Users ist
    final activeRooms = _sessions.entries
        .where((e) => e.value.isNotEmpty)
        .toList();

    if (activeRooms.isEmpty) return const SizedBox.shrink();

    final accent = WbDesign.accent(widget.world);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: activeRooms.map((entry) {
        final roomName = entry.key;
        final participants = entry.value;
        final names = participants
            .take(3)
            .map((p) => p['display_name'] ?? p['username'] ?? '?')
            .join(', ');
        final extra = participants.length > 3
            ? ' +${participants.length - 3}'
            : '';

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onJoin(roomName);
          },
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.15),
                  accent.withValues(alpha: 0.08),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: accent.withValues(alpha: 0.30),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Blinkender Punkt
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF1744)
                          .withValues(alpha: _pulse.value),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF1744)
                              .withValues(alpha: _pulse.value * 0.5),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$names$extra sind jetzt live',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _roomDisplayName(roomName),
                        style: TextStyle(
                          color: WbDesign.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: accent.withValues(alpha: 0.45), width: 1),
                  ),
                  child: Text(
                    'Beitreten',
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    color: WbDesign.textTertiary, size: 18),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _roomDisplayName(String roomName) {
    final suffix = roomName
        .replaceFirst('materie-', '')
        .replaceFirst('energie-', '');
    const names = {
      'politik': 'Politik',
      'geschichte': 'Geschichte',
      'ufo': 'UFOs & Aliens',
      'verschwoerung': 'Verschwörungen',
      'wissenschaft': 'Wissenschaft',
      'tech': 'Technologie',
      'gesundheit': 'Gesundheit',
      'medien': 'Medien',
      'finanzen': 'Finanzen',
      'meditation': 'Meditation',
      'traeume': 'Träume',
      'chakra': 'Chakren',
      'bewusstsein': 'Bewusstsein',
      'heilung': 'Heilung',
      'astrologie': 'Astrologie',
      'kristalle': 'Kristalle',
      'kraftorte': 'Kraftorte',
    };
    return names[suffix] ?? suffix;
  }
}
