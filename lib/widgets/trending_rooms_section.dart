// Trending-Rooms-Section — Top-3 aktivste Chat-Räume der letzten 24h.
//
// Aggregiert chat_messages über die letzten 24 Stunden, gruppiert nach
// room_id, sortiert nach Nachrichten-Count. Zeigt Snippet der letzten
// Nachricht + Count. Tap navigiert zu... der Chat-Tab muss extern
// geöffnet werden (nicht von hier — wir bieten nur Callback).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'wb_skeleton.dart';

class TrendingRoom {
  final String roomId;
  final int messageCount;
  final String? lastMessage;
  final String? lastUsername;
  const TrendingRoom({
    required this.roomId,
    required this.messageCount,
    this.lastMessage,
    this.lastUsername,
  });
}

class TrendingRoomsSection extends StatefulWidget {
  final String realm;
  final Color accent;
  final void Function(String roomId)? onRoomTap;

  const TrendingRoomsSection({
    super.key,
    required this.realm,
    required this.accent,
    this.onRoomTap,
  });

  @override
  State<TrendingRoomsSection> createState() => _TrendingRoomsSectionState();
}

class _TrendingRoomsSectionState extends State<TrendingRoomsSection> {
  List<TrendingRoom> _rooms = const [];
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(minutes: 3), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final since = DateTime.now()
          .subtract(const Duration(hours: 24))
          .toUtc()
          .toIso8601String();
      final res = await Supabase.instance.client
          .from('chat_messages')
          .select('room_id,message,username,created_at')
          .like('room_id', '${widget.realm}-%')
          .gte('created_at', since)
          .order('created_at', ascending: false)
          .limit(300)
          .timeout(const Duration(seconds: 5));

      if (!mounted) return;

      final byRoom = <String, List<Map<String, dynamic>>>{};
      for (final row in (res as List)) {
        final m = Map<String, dynamic>.from(row as Map);
        final r = (m['room_id'] as String?) ?? '';
        if (r.isEmpty) continue;
        byRoom.putIfAbsent(r, () => []).add(m);
      }

      final list = byRoom.entries
          .map((e) => TrendingRoom(
                roomId: e.key,
                messageCount: e.value.length,
                lastMessage: e.value.first['message'] as String?,
                lastUsername: e.value.first['username'] as String?,
              ))
          .toList()
        ..sort((a, b) => b.messageCount.compareTo(a.messageCount));

      setState(() {
        _rooms = list.take(3).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _readableRoom(String roomId) {
    // 'materie-politik' → 'Politik', 'materie-ufo' → 'UFO'
    final parts = roomId.split('-');
    if (parts.length < 2) return roomId;
    final name = parts.skip(1).join(' ');
    return name.isNotEmpty
        ? '${name[0].toUpperCase()}${name.substring(1)}'
        : roomId;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: 96,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 3,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(right: 10),
            child: WBSkeleton(
              width: 220,
              height: 86,
              borderRadius: BorderRadius.circular(14),
              accent: widget.accent,
            ),
          ),
        ),
      );
    }
    if (_rooms.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _rooms.length,
        itemBuilder: (_, i) {
          final r = _rooms[i];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _TrendingCard(
              room: r,
              readableName: _readableRoom(r.roomId),
              accent: widget.accent,
              onTap: () => widget.onRoomTap?.call(r.roomId),
            ),
          );
        },
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final TrendingRoom room;
  final String readableName;
  final Color accent;
  final VoidCallback? onTap;

  const _TrendingCard({
    required this.room,
    required this.readableName,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: 0.18),
                accent.withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.local_fire_department_rounded,
                      color: accent, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      readableName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${room.messageCount}',
                      style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${room.lastUsername ?? ""}: ${room.lastMessage ?? ""}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
