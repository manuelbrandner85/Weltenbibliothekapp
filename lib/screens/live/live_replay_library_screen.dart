// Live Replay Library Screen
// =========================================================================
// Browse and play back archived LiveKit recordings ("Live · Archiv").
//
// Data source: Supabase table `live_recordings` (schema described in CLAUDE.md
// task brief). Falls back to an empty state when the table is missing or empty
// -- never crashes, never injects mock data.
//
// The screen is intentionally self-contained: detail screen, skeleton loaders
// and a stub video player live in this same file to keep the live archive a
// drop-in addition without further wiring.
// =========================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../config/api_config.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_ambient_particles.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';
import '../../widgets/wb_cached_image.dart';

// =========================================================================
// MODELS
// =========================================================================

/// Lightweight world descriptor for this screen.
///
/// Spec asks for explicit color hexes (0xFF2196F3 / 0xFF7C4DFF / 0xFF00BCD4)
/// that don't exactly match `WBCinematic.palette()`. We honour the spec here
/// while still mapping to a `WBWorld` for the `WBGlassAppBar` accent line.
class _WorldTheme {
  final String key; // 'materie' | 'energie' | 'neutral'
  final String label;
  final Color primary;
  final Color secondary;
  final Color glow;
  final WBWorld wbWorld;

  const _WorldTheme({
    required this.key,
    required this.label,
    required this.primary,
    required this.secondary,
    required this.glow,
    required this.wbWorld,
  });

  static _WorldTheme fromKey(String key) {
    switch (key) {
      case 'materie':
        return const _WorldTheme(
          key: 'materie',
          label: 'MATERIE',
          primary: Color(0xFF2196F3),
          secondary: Color(0xFF0D47A1),
          glow: Color(0x662196F3),
          wbWorld: WBWorld.materie,
        );
      case 'energie':
        return const _WorldTheme(
          key: 'energie',
          label: 'ENERGIE',
          primary: Color(0xFF7C4DFF),
          secondary: Color(0xFF3B0D6E),
          glow: Color(0x667C4DFF),
          wbWorld: WBWorld.energie,
        );
      case 'neutral':
      default:
        return const _WorldTheme(
          key: 'neutral',
          label: 'ALLE WELTEN',
          primary: Color(0xFF00BCD4),
          secondary: Color(0xFF006064),
          glow: Color(0x6600BCD4),
          wbWorld: WBWorld.neutral,
        );
    }
  }
}

/// Single highlight marker inside a recording.
class ReplayHighlight {
  final int timestampSec;
  final String text;

  const ReplayHighlight({required this.timestampSec, required this.text});

  static ReplayHighlight? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final tsRaw = raw['timestamp_sec'];
    int? ts;
    if (tsRaw is int) {
      ts = tsRaw;
    } else if (tsRaw is num) {
      ts = tsRaw.toInt();
    } else if (tsRaw is String) {
      ts = int.tryParse(tsRaw);
    }
    final text = raw['text'];
    if (ts == null || text is! String || text.isEmpty) return null;
    return ReplayHighlight(timestampSec: ts, text: text);
  }
}

/// Materialised row from the `live_recordings` Supabase table.
///
/// Defensive parsing -- the table may not exist yet; partial rows must not
/// crash the list. Missing or wrong-typed fields fall back to sane defaults.
class LiveRecording {
  final String id;
  final String title;
  final String world; // 'materie' | 'energie' | 'neutral' | ''
  final String hostName;
  final String? hostAvatarUrl;
  final DateTime startedAt;
  final int durationSec;
  final int participantCount;
  final String? recordingUrl;
  final String? transcriptUrl;
  final String? thumbnailUrl;
  final List<ReplayHighlight> highlights;

  const LiveRecording({
    required this.id,
    required this.title,
    required this.world,
    required this.hostName,
    required this.hostAvatarUrl,
    required this.startedAt,
    required this.durationSec,
    required this.participantCount,
    required this.recordingUrl,
    required this.transcriptUrl,
    required this.thumbnailUrl,
    required this.highlights,
  });

  bool get hasRecording =>
      recordingUrl != null && recordingUrl!.trim().isNotEmpty;
  bool get hasTranscript =>
      transcriptUrl != null && transcriptUrl!.trim().isNotEmpty;
  bool get hasHighlights => highlights.isNotEmpty;

  static LiveRecording fromRow(Map<String, dynamic> row) {
    DateTime parseDate(Object? raw) {
      if (raw is String && raw.isNotEmpty) {
        return DateTime.tryParse(raw)?.toLocal() ?? DateTime.now();
      }
      if (raw is DateTime) return raw.toLocal();
      return DateTime.now();
    }

    int parseInt(Object? raw, {int fallback = 0}) {
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw) ?? fallback;
      return fallback;
    }

    String? parseStringOrNull(Object? raw) {
      if (raw is String) {
        final t = raw.trim();
        return t.isEmpty ? null : t;
      }
      return null;
    }

    final highlightsRaw = row['highlights'];
    final highlights = <ReplayHighlight>[];
    if (highlightsRaw is List) {
      for (final h in highlightsRaw) {
        final parsed = ReplayHighlight.tryParse(h);
        if (parsed != null) highlights.add(parsed);
      }
    }
    // Highlights might arrive as JSON-encoded string from jsonb. Parse defensively.
    if (highlightsRaw is String && highlightsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(highlightsRaw);
        if (decoded is List) {
          for (final h in decoded) {
            final parsed = ReplayHighlight.tryParse(h);
            if (parsed != null) highlights.add(parsed);
          }
        }
      } catch (_) {
        // ignore -- partial data is acceptable
      }
    }

    return LiveRecording(
      id: (row['id'] ?? '').toString(),
      title: parseStringOrNull(row['title']) ?? 'Ohne Titel',
      world: (parseStringOrNull(row['world']) ?? '').toLowerCase(),
      hostName: parseStringOrNull(row['host_name']) ?? 'Anonym',
      hostAvatarUrl: parseStringOrNull(row['host_avatar_url']),
      startedAt: parseDate(row['started_at']),
      durationSec: parseInt(row['duration_sec']),
      participantCount: parseInt(row['participant_count']),
      recordingUrl: parseStringOrNull(row['recording_url']),
      transcriptUrl: parseStringOrNull(row['transcript_url']),
      thumbnailUrl: parseStringOrNull(row['thumbnail_url']),
      highlights: highlights,
    );
  }
}

/// Quick filter chip values.
enum _ReplayFilter { all, today, week, withTranscript }

extension _ReplayFilterLabel on _ReplayFilter {
  String get label {
    switch (this) {
      case _ReplayFilter.all:
        return 'Alle';
      case _ReplayFilter.today:
        return 'Heute';
      case _ReplayFilter.week:
        return 'Diese Woche';
      case _ReplayFilter.withTranscript:
        return 'Mit Transkript';
    }
  }
}

// =========================================================================
// LIBRARY SCREEN
// =========================================================================

class LiveReplayLibraryScreen extends StatefulWidget {
  final String world; // 'materie' | 'energie' | 'neutral'
  const LiveReplayLibraryScreen({super.key, this.world = 'neutral'});

  @override
  State<LiveReplayLibraryScreen> createState() =>
      _LiveReplayLibraryScreenState();
}

class _LiveReplayLibraryScreenState extends State<LiveReplayLibraryScreen> {
  static const String _watchedKey = 'replay_watched_v1';
  static const String _posKeyPrefix = 'replay_pos_';
  static const String _posKeySuffix = '_v1';

  late final _WorldTheme _theme;
  final TextEditingController _searchCtrl = TextEditingController();
  _ReplayFilter _filter = _ReplayFilter.all;

  bool _loading = true;
  String? _errorMessage;
  List<LiveRecording> _recordings = const [];
  Set<String> _watchedIds = <String>{};
  final Map<String, int> _resumePositions = <String, int>{};

  @override
  void initState() {
    super.initState();
    _theme = _WorldTheme.fromKey(widget.world);
    _searchCtrl.addListener(() => setState(() {}));
    _bootstrap();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _loadWatchedState();
    await _loadRecordings();
  }

  Future<void> _loadWatchedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_watchedKey) ?? <String>[];
      _watchedIds = stored.toSet();
      // Eagerly hydrate resume positions; the keys are individually scoped
      // so we can scan SharedPreferences once.
      for (final key in prefs.getKeys()) {
        if (key.startsWith(_posKeyPrefix) && key.endsWith(_posKeySuffix)) {
          final id = key.substring(
            _posKeyPrefix.length,
            key.length - _posKeySuffix.length,
          );
          final value = prefs.getInt(key);
          if (value != null && value > 0) {
            _resumePositions[id] = value;
          }
        }
      }
    } catch (_) {
      // Best-effort: missing prefs should not block the UI.
    }
  }

  Future<void> _persistWatched(String id) async {
    if (!mounted) return;
    setState(() => _watchedIds.add(id));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_watchedKey, _watchedIds.toList());
    } catch (_) {
      // ignore -- non-critical
    }
  }

  Future<void> _persistResumePosition(String id, int seconds) async {
    if (seconds <= 0) return;
    _resumePositions[id] = seconds;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        '$_posKeyPrefix$id$_posKeySuffix',
        seconds,
      );
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadRecordings() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final client = Supabase.instance.client;
      final worldFilter = widget.world == 'neutral' ? '' : widget.world;
      final dynamic res = await client
          .from('live_recordings')
          .select()
          .eq('world', worldFilter)
          .order('started_at', ascending: false)
          .limit(50);

      final list = <LiveRecording>[];
      if (res is List) {
        for (final row in res) {
          if (row is Map<String, dynamic>) {
            try {
              list.add(LiveRecording.fromRow(row));
            } catch (_) {
              // Skip malformed rows rather than break the whole list.
            }
          } else if (row is Map) {
            try {
              list.add(LiveRecording.fromRow(Map<String, dynamic>.from(row)));
            } catch (_) {
              // skip
            }
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _recordings = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recordings = const [];
        _loading = false;
        _errorMessage = _humanizeError(e);
      });
    }
  }

  String _humanizeError(Object e) {
    final msg = e.toString();
    // Treat "missing table" responses as an empty state instead of an error.
    if (msg.contains('PGRST') ||
        msg.toLowerCase().contains('does not exist') ||
        msg.contains('relation') ||
        msg.contains('404')) {
      return ''; // empty -> render empty state without an error banner
    }
    return msg;
  }

  // ----------------------------------------------------------------------
  // Filtering
  // ----------------------------------------------------------------------

  List<LiveRecording> get _visibleRecordings {
    final query = _searchCtrl.text.trim().toLowerCase();
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfToday.subtract(const Duration(days: 6));

    return _recordings.where((rec) {
      switch (_filter) {
        case _ReplayFilter.today:
          if (rec.startedAt.isBefore(startOfToday)) return false;
          break;
        case _ReplayFilter.week:
          if (rec.startedAt.isBefore(startOfWeek)) return false;
          break;
        case _ReplayFilter.withTranscript:
          if (!rec.hasTranscript) return false;
          break;
        case _ReplayFilter.all:
          break;
      }
      if (query.isEmpty) return true;
      return rec.title.toLowerCase().contains(query) ||
          rec.hostName.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  // ----------------------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final filtered = _visibleRecordings;
    final hasAnyData = _recordings.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: _theme.wbWorld,
        titleWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.live_tv_rounded,
                size: 16, color: _theme.primary.withValues(alpha: 0.9)),
            const SizedBox(width: 8),
            const Text(
              'LIVE  ARCHIV',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 4.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Aktualisieren',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _loading ? null : _loadRecordings,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackdrop(),
          IgnorePointer(
            child: WBAmbientParticles(
              world: _theme.wbWorld,
              count: 28,
            ),
          ),
          const IgnorePointer(child: WBVignette(intensity: 0.55)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: kToolbarHeight),
              child: Column(
                children: [
                  _buildSearchBar(),
                  _buildFilterRow(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _loading
                        ? _SkeletonList(theme: _theme)
                        : hasAnyData
                            ? _buildList(filtered)
                            : _EmptyState(
                                theme: _theme,
                                onOpenLive: () => Navigator.of(context).pop(),
                                errorMessage: _errorMessage,
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackdrop() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.2, -0.5),
          radius: 1.4,
          colors: [
            _theme.secondary.withValues(alpha: 0.45),
            Colors.black,
          ],
          stops: const [0.0, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: _Orb(color: _theme.primary, size: 320),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: _Orb(color: _theme.secondary, size: 360),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(WBRadius.md),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(WBRadius.md),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              cursorColor: _theme.primary,
              decoration: InputDecoration(
                hintText: 'Sessions oder Hosts suchen...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.white.withValues(alpha: 0.55),
                  size: 20,
                ),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withValues(alpha: 0.55),
                          size: 18,
                        ),
                        onPressed: () => _searchCtrl.clear(),
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          for (final f in _ReplayFilter.values) ...[
            _FilterChip(
              label: f.label,
              selected: _filter == f,
              theme: _theme,
              onTap: () => setState(() => _filter = f),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildList(List<LiveRecording> items) {
    if (items.isEmpty) {
      return _NoMatchState(theme: _theme);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final rec = items[index];
        return _ReplayCard(
          recording: rec,
          theme: _theme,
          watched: _watchedIds.contains(rec.id),
          resumeSeconds: _resumePositions[rec.id],
          onTap: () => _openDetail(rec, autoPlay: false),
          onPlay: () => _openDetail(rec, autoPlay: true),
        );
      },
    );
  }

  Future<void> _openDetail(LiveRecording rec, {required bool autoPlay}) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _ReplayDetailScreen(
          recording: rec,
          theme: _theme,
          autoPlay: autoPlay,
          initialPositionSec: _resumePositions[rec.id] ?? 0,
          onWatched: () => _persistWatched(rec.id),
          onPositionUpdate: (sec) => _persistResumePosition(rec.id, sec),
        ),
      ),
    );
    if (mounted) setState(() {});
  }
}

// =========================================================================
// VISUAL HELPERS
// =========================================================================

class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.35),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final _WorldTheme theme;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: WBMotion.press,
        curve: WBMotion.enterCurve,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.primary.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(WBRadius.pill),
          border: Border.all(
            color: selected
                ? theme.primary.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
            letterSpacing: 0.4,
            color:
                selected ? Colors.white : Colors.white.withValues(alpha: 0.72),
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? borderColor;
  final Color? fill;

  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = WBRadius.md,
    this.borderColor,
    this.fill,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fill ?? Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// =========================================================================
// RECORDING CARD
// =========================================================================

class _ReplayCard extends StatelessWidget {
  final LiveRecording recording;
  final _WorldTheme theme;
  final bool watched;
  final int? resumeSeconds;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  const _ReplayCard({
    required this.recording,
    required this.theme,
    required this.watched,
    required this.resumeSeconds,
    required this.onTap,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final relativeDate = _formatRelativeDate(recording.startedAt);
    final duration = _formatDuration(recording.durationSec);
    final participants = recording.participantCount;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: _GlassPanel(
        padding: const EdgeInsets.all(12),
        radius: WBRadius.lg,
        borderColor: watched
            ? theme.primary.withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumbnail(recording: recording, theme: theme, watched: watched),
            const SizedBox(width: 12),
            Expanded(child: _buildBody(relativeDate, duration, participants)),
            const SizedBox(width: 8),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(String relativeDate, String duration, int participants) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (watched)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: theme.primary.withValues(alpha: 0.9),
                ),
              ),
            Expanded(
              child: Text(
                recording.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  height: 1.25,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          recording.hostName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.primary.withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _MetaPill(icon: Icons.schedule_rounded, label: relativeDate),
            _MetaPill(icon: Icons.timer_rounded, label: duration),
            _MetaPill(
              icon: Icons.people_alt_rounded,
              label: participants > 0 ? '$participants' : '-',
            ),
          ],
        ),
        if (resumeSeconds != null && resumeSeconds! > 0) ...[
          const SizedBox(height: 8),
          Text(
            'Weitersehen ab ${_formatTimestamp(resumeSeconds!)}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: theme.primary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundIconButton(
          icon: Icons.play_arrow_rounded,
          color: Colors.white,
          background: theme.primary.withValues(alpha: 0.9),
          enabled: recording.hasRecording,
          onTap: onPlay,
          tooltip:
              recording.hasRecording ? 'Abspielen' : 'Kein Video verfuegbar',
        ),
        const SizedBox(height: 8),
        _RoundIconButton(
          icon: Icons.description_outlined,
          color: recording.hasTranscript
              ? Colors.white
              : Colors.white.withValues(alpha: 0.35),
          background: Colors.white.withValues(alpha: 0.08),
          enabled: recording.hasTranscript,
          onTap: onTap,
          tooltip: recording.hasTranscript
              ? 'Transkript verfuegbar'
              : 'Kein Transkript',
        ),
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final LiveRecording recording;
  final _WorldTheme theme;
  final bool watched;
  const _Thumbnail({
    required this.recording,
    required this.theme,
    required this.watched,
  });

  @override
  Widget build(BuildContext context) {
    final url = recording.thumbnailUrl;
    final initials = _initialsFromName(recording.hostName);
    return ClipRRect(
      borderRadius: BorderRadius.circular(WBRadius.sm),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primary.withValues(alpha: 0.35),
              theme.secondary.withValues(alpha: 0.65),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // PERF-FIX (#3): CachedNetworkImage statt Image.network --
            // Thumbnails in der Replay-Liste werden nicht mehr bei jedem
            // Scroll neu geladen.
            if (url != null)
              WbCachedImage(
                url,
                fit: BoxFit.cover,
                errorWidget: _AvatarFallback(initials: initials, theme: theme),
              )
            else if (recording.hostAvatarUrl != null)
              WbCachedImage(
                recording.hostAvatarUrl!,
                fit: BoxFit.cover,
                errorWidget: _AvatarFallback(initials: initials, theme: theme),
              )
            else
              _AvatarFallback(initials: initials, theme: theme),
            // Bottom overlay -- duration badge
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formatDuration(recording.durationSec),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
            if (watched)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: theme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String initials;
  final _WorldTheme theme;
  const _AvatarFallback({required this.initials, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w800,
          fontSize: 22,
          color: Colors.white.withValues(alpha: 0.85),
          shadows: [
            Shadow(
              color: theme.primary.withValues(alpha: 0.6),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.55)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final bool enabled;
  final VoidCallback onTap;
  final String tooltip;

  const _RoundIconButton({
    required this.icon,
    required this.color,
    required this.background,
    required this.enabled,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.45,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// EMPTY + LOADING STATES
// =========================================================================

class _SkeletonList extends StatefulWidget {
  final _WorldTheme theme;
  const _SkeletonList({required this.theme});

  @override
  State<_SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<_SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;
          return _GlassPanel(
            radius: WBRadius.lg,
            child: Row(
              children: [
                _ShimmerBox(width: 80, height: 80, t: t, theme: widget.theme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(
                          width: 220, height: 14, t: t, theme: widget.theme),
                      const SizedBox(height: 8),
                      _ShimmerBox(
                          width: 140, height: 10, t: t, theme: widget.theme),
                      const SizedBox(height: 10),
                      _ShimmerBox(
                          width: 180, height: 10, t: t, theme: widget.theme),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double t; // 0..1
  final _WorldTheme theme;
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.t,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final alpha = 0.08 + 0.12 * (0.5 + 0.5 * math.sin(t * 2 * math.pi));
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: alpha),
            theme.primary.withValues(alpha: alpha * 0.6),
            Colors.white.withValues(alpha: alpha),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final _WorldTheme theme;
  final VoidCallback onOpenLive;
  final String? errorMessage;

  const _EmptyState({
    required this.theme,
    required this.onOpenLive,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '\u{1F399}\u{FE0F}',
              style: TextStyle(fontSize: 96),
            ),
            const SizedBox(height: 16),
            const Text(
              'Noch keine Aufzeichnungen',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Colors.white,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Live-Sessions werden hier archiviert sobald welche stattfinden.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            if (errorMessage != null && errorMessage!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 24),
            _GlowButton(
              label: 'Live-Bereich oeffnen',
              theme: theme,
              onTap: onOpenLive,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoMatchState extends StatelessWidget {
  final _WorldTheme theme;
  const _NoMatchState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64, color: theme.primary.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            const Text(
              'Keine Treffer',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Probiere eine andere Suche oder andere Filter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowButton extends StatelessWidget {
  final String label;
  final _WorldTheme theme;
  final VoidCallback onTap;
  const _GlowButton({
    required this.label,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primary,
              theme.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(WBRadius.pill),
          boxShadow: [
            BoxShadow(
              color: theme.primary.withValues(alpha: 0.45),
              blurRadius: 24,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 1.4,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// DETAIL SCREEN
// =========================================================================

class _ReplayDetailScreen extends StatefulWidget {
  final LiveRecording recording;
  final _WorldTheme theme;
  final bool autoPlay;
  final int initialPositionSec;
  final VoidCallback onWatched;
  final void Function(int positionSec) onPositionUpdate;

  const _ReplayDetailScreen({
    required this.recording,
    required this.theme,
    required this.autoPlay,
    required this.initialPositionSec,
    required this.onWatched,
    required this.onPositionUpdate,
  });

  @override
  State<_ReplayDetailScreen> createState() => _ReplayDetailScreenState();
}

class _ReplayDetailScreenState extends State<_ReplayDetailScreen> {
  VideoPlayerController? _videoCtrl;
  String? _videoError;
  bool _videoReady = false;
  bool _watchedSent = false;

  bool _transcriptLoading = false;
  String? _transcriptText;
  String? _transcriptError;
  final TextEditingController _transcriptSearchCtrl = TextEditingController();
  bool _transcriptExpanded = false;

  bool _summaryLoading = false;
  String? _summaryText;
  String? _summaryError;

  Timer? _positionTimer;

  @override
  void initState() {
    super.initState();
    _initVideo();
    if (widget.recording.hasTranscript) {
      _loadTranscript();
    }
    _transcriptSearchCtrl.addListener(() => setState(() {}));
  }

  Future<void> _initVideo() async {
    final url = widget.recording.recordingUrl;
    if (url == null || url.isEmpty) {
      setState(() => _videoError = 'Keine Video-URL hinterlegt.');
      return;
    }
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) {
        setState(() => _videoError = 'Ungueltige Video-URL.');
        return;
      }
      final ctrl = VideoPlayerController.networkUrl(uri);
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      if (widget.initialPositionSec > 0) {
        await ctrl.seekTo(Duration(seconds: widget.initialPositionSec));
      }
      if (widget.autoPlay) {
        await ctrl.play();
      }
      ctrl.addListener(_onVideoTick);
      setState(() {
        _videoCtrl = ctrl;
        _videoReady = true;
      });
      _positionTimer =
          Timer.periodic(const Duration(seconds: 5), (_) => _persistPosition());
    } catch (e) {
      setState(() => _videoError = 'Player nicht verfuegbar: $e');
    }
  }

  void _onVideoTick() {
    if (_watchedSent) return;
    final ctrl = _videoCtrl;
    if (ctrl == null) return;
    final value = ctrl.value;
    if (!value.isInitialized) return;
    // Mark as watched once we've crossed 30 seconds or 25% playback.
    final positionSec = value.position.inSeconds;
    final durationSec = value.duration.inSeconds;
    if (positionSec >= 30 ||
        (durationSec > 0 && positionSec >= durationSec * 0.25)) {
      _watchedSent = true;
      widget.onWatched();
    }
  }

  void _persistPosition() {
    final ctrl = _videoCtrl;
    if (ctrl == null) return;
    final pos = ctrl.value.position.inSeconds;
    if (pos > 0) widget.onPositionUpdate(pos);
  }

  Future<void> _loadTranscript() async {
    final url = widget.recording.transcriptUrl;
    if (url == null || url.isEmpty) return;
    setState(() {
      _transcriptLoading = true;
      _transcriptError = null;
    });
    try {
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        setState(() {
          _transcriptText = res.body;
          _transcriptLoading = false;
        });
      } else {
        setState(() {
          _transcriptError = 'HTTP ${res.statusCode}';
          _transcriptLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _transcriptError = 'Konnte Transkript nicht laden.';
        _transcriptLoading = false;
      });
    }
  }

  Future<void> _generateSummary() async {
    final text = _transcriptText;
    if (text == null || text.trim().isEmpty) return;
    setState(() {
      _summaryLoading = true;
      _summaryError = null;
    });
    final cap = math.min(text.length, 8000);
    final excerpt = text.substring(0, cap);
    final prompt =
        'Fasse diese Live-Session in 5 Bullet-Points zusammen:\n\n$excerpt';
    try {
      String? bearer;
      try {
        final session = Supabase.instance.client.auth.currentSession;
        bearer = session?.accessToken;
      } catch (_) {
        // Auth optional; fall back to anonymous request.
      }
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (bearer != null && bearer.isNotEmpty) {
        headers['Authorization'] = 'Bearer $bearer';
      }
      final body = jsonEncode({
        'personality': 'heiler',
        'message': prompt,
      });
      final res = await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/mentor/chat'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        String? answer;
        try {
          final decoded = jsonDecode(res.body);
          if (decoded is Map) {
            final candidate = decoded['response'] ??
                decoded['message'] ??
                decoded['answer'] ??
                decoded['content'];
            if (candidate is String) answer = candidate;
          }
        } catch (_) {
          answer = res.body;
        }
        setState(() {
          _summaryText = (answer == null || answer.isEmpty) ? res.body : answer;
          _summaryLoading = false;
        });
      } else {
        setState(() {
          _summaryError = 'Mentor-API: HTTP ${res.statusCode}';
          _summaryLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _summaryError = 'Mentor nicht erreichbar.';
        _summaryLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _persistPosition();
    final ctrl = _videoCtrl;
    if (ctrl != null) {
      ctrl.removeListener(_onVideoTick);
      ctrl.dispose();
    }
    _transcriptSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final rec = widget.recording;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: theme.wbWorld,
        titleWidget: Text(
          'REPLAY',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 12,
            letterSpacing: 4.0,
            color: Colors.white.withValues(alpha: 0.95),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.secondary.withValues(alpha: 0.55),
                  Colors.black,
                ],
              ),
            ),
          ),
          const IgnorePointer(child: WBVignette(intensity: 0.5)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: kToolbarHeight),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPlayer(rec),
                    const SizedBox(height: 16),
                    _buildHeader(rec),
                    if (rec.hasHighlights) ...[
                      const SizedBox(height: 18),
                      _buildHighlights(rec),
                    ],
                    if (rec.hasTranscript) ...[
                      const SizedBox(height: 18),
                      _buildTranscript(),
                    ],
                    if (rec.hasTranscript) ...[
                      const SizedBox(height: 16),
                      _buildSummarySection(),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------- Player --------

  Widget _buildPlayer(LiveRecording rec) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(WBRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(
              color: widget.theme.primary.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: _buildPlayerContent(rec),
        ),
      ),
    );
  }

  Widget _buildPlayerContent(LiveRecording rec) {
    if (!rec.hasRecording) {
      return _PlayerStub(
        theme: widget.theme,
        title: 'Kein Replay verfuegbar',
        subtitle: 'Diese Session wurde nicht aufgezeichnet.',
      );
    }
    if (_videoError != null) {
      return _PlayerStub(
        theme: widget.theme,
        title: 'Replay nicht spielbar in diesem Build',
        subtitle: _videoError!,
      );
    }
    final ctrl = _videoCtrl;
    if (!_videoReady || ctrl == null) {
      return Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(widget.theme.primary),
          ),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: ctrl.value.size.width == 0 ? 16 : ctrl.value.size.width,
            height: ctrl.value.size.height == 0 ? 9 : ctrl.value.size.height,
            child: VideoPlayer(ctrl),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() {
              if (ctrl.value.isPlaying) {
                ctrl.pause();
              } else {
                ctrl.play();
              }
            });
          },
          child: AnimatedOpacity(
            duration: WBMotion.press,
            opacity: ctrl.value.isPlaying ? 0.0 : 1.0,
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: Center(
                child: Icon(
                  Icons.play_circle_filled_rounded,
                  size: 72,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: VideoProgressIndicator(
            ctrl,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: widget.theme.primary,
              bufferedColor: widget.theme.primary.withValues(alpha: 0.3),
              backgroundColor: Colors.white.withValues(alpha: 0.15),
            ),
            padding: const EdgeInsets.all(0),
          ),
        ),
      ],
    );
  }

  // -------- Header --------

  Widget _buildHeader(LiveRecording rec) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rec.title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'mit ${rec.hostName}',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: widget.theme.primary.withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            _MetaPill(
              icon: Icons.schedule_rounded,
              label: _formatRelativeDate(rec.startedAt),
            ),
            _MetaPill(
              icon: Icons.timer_rounded,
              label: _formatDuration(rec.durationSec),
            ),
            _MetaPill(
              icon: Icons.people_alt_rounded,
              label: '${rec.participantCount} Teilnehmer',
            ),
          ],
        ),
      ],
    );
  }

  // -------- Highlights --------

  Widget _buildHighlights(LiveRecording rec) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(text: 'HIGHLIGHTS', theme: widget.theme),
        const SizedBox(height: 8),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: rec.highlights.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final h = rec.highlights[index];
              return GestureDetector(
                onTap: () => _seekTo(h.timestampSec),
                behavior: HitTestBehavior.opaque,
                child: _GlassPanel(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  radius: WBRadius.md,
                  borderColor: widget.theme.primary.withValues(alpha: 0.45),
                  fill: widget.theme.primary.withValues(alpha: 0.10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTimestamp(h.timestampSec),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.4,
                          color: widget.theme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          h.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _seekTo(int seconds) {
    final ctrl = _videoCtrl;
    if (ctrl == null) return;
    ctrl.seekTo(Duration(seconds: seconds));
    ctrl.play();
  }

  // -------- Transcript --------

  Widget _buildTranscript() {
    final query = _transcriptSearchCtrl.text.trim().toLowerCase();
    final source = _transcriptText ?? '';
    final filteredText = query.isEmpty
        ? source
        : source
            .split('\n')
            .where((line) => line.toLowerCase().contains(query))
            .join('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SectionLabel(text: 'TRANSKRIPT', theme: widget.theme),
            ),
            GestureDetector(
              onTap: () =>
                  setState(() => _transcriptExpanded = !_transcriptExpanded),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  _transcriptExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
        ),
        if (_transcriptExpanded) ...[
          const SizedBox(height: 8),
          _GlassPanel(
            radius: WBRadius.md,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _transcriptSearchCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  cursorColor: widget.theme.primary,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    hintText: 'Im Transkript suchen...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_transcriptLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              widget.theme.primary),
                        ),
                      ),
                    ),
                  )
                else if (_transcriptError != null)
                  Text(
                    _transcriptError!,
                    style: const TextStyle(color: Colors.redAccent),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        filteredText.isEmpty
                            ? 'Keine Treffer fuer "$query".'
                            : filteredText,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // -------- AI summary --------

  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel(text: 'AI ZUSAMMENFASSUNG', theme: widget.theme),
        const SizedBox(height: 8),
        if (_summaryText == null)
          GestureDetector(
            onTap: _summaryLoading ? null : _generateSummary,
            behavior: HitTestBehavior.opaque,
            child: _GlassPanel(
              radius: WBRadius.md,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              borderColor: widget.theme.primary.withValues(alpha: 0.45),
              fill: widget.theme.primary.withValues(alpha: 0.10),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      color: widget.theme.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _summaryLoading
                          ? 'Mentor schreibt...'
                          : 'Session in 5 Bullet-Points zusammenfassen',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (_summaryLoading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(widget.theme.primary),
                      ),
                    )
                  else
                    Icon(Icons.arrow_forward_rounded,
                        color: widget.theme.primary, size: 18),
                ],
              ),
            ),
          )
        else
          _GlassPanel(
            radius: WBRadius.md,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        color: widget.theme.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Mentor-Heiler',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 1.5,
                        color: widget.theme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _summaryText!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _generateSummary,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    'Neu generieren',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: widget.theme.primary.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_summaryError != null) ...[
          const SizedBox(height: 8),
          Text(
            _summaryError!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final _WorldTheme theme;
  const _SectionLabel({required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 1,
          color: theme.primary.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 3.6,
            color: theme.primary.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

class _PlayerStub extends StatelessWidget {
  final _WorldTheme theme;
  final String title;
  final String subtitle;
  const _PlayerStub({
    required this.theme,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.ondemand_video_rounded,
                size: 48, color: theme.primary.withValues(alpha: 0.7)),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// FORMATTING HELPERS
// =========================================================================

String _formatRelativeDate(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'gerade eben';
  if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min';
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return h == 1 ? 'vor 1 Std' : 'vor $h Std';
  }
  if (diff.inDays < 7) {
    final d = diff.inDays;
    return d == 1 ? 'gestern' : 'vor $d Tagen';
  }
  if (diff.inDays < 30) {
    final w = (diff.inDays / 7).floor();
    return w == 1 ? 'vor 1 Woche' : 'vor $w Wochen';
  }
  if (diff.inDays < 365) {
    final m = (diff.inDays / 30).floor();
    return m == 1 ? 'vor 1 Monat' : 'vor $m Monaten';
  }
  final y = (diff.inDays / 365).floor();
  return y == 1 ? 'vor 1 Jahr' : 'vor $y Jahren';
}

String _formatDuration(int seconds) {
  if (seconds <= 0) return '--';
  if (seconds < 60) return '${seconds}s';
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final remMin = minutes % 60;
  if (remMin == 0) return '${hours}h';
  return '${hours}h ${remMin}m';
}

String _formatTimestamp(int seconds) {
  if (seconds < 0) seconds = 0;
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  String two(int v) => v < 10 ? '0$v' : '$v';
  if (h > 0) return '${two(h)}:${two(m)}:${two(s)}';
  return '${two(m)}:${two(s)}';
}

String _initialsFromName(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) {
    return parts.first.characters.first.toUpperCase();
  }
  final first = parts.first.characters.first;
  final last = parts.last.characters.first;
  return '$first$last'.toUpperCase();
}
