import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/stats/stats_charts.dart';

/// 📊 Stats Dashboard – Echtzeit aus Supabase
///
/// Daten kommen direkt aus community_posts und chat_messages:
/// - Beiträge = eigene Posts in dieser Welt
/// - Likes    = Likes die eigene Posts erhalten haben
/// - Chat     = Chat-Nachrichten in Räumen dieser Welt
/// - Streak   = Aufeinanderfolgende Aktivitätstage (Chat + Posts)
class StatsDashboardScreen extends StatefulWidget {
  final String world; // 'materie' oder 'energie'

  const StatsDashboardScreen({super.key, required this.world});

  @override
  State<StatsDashboardScreen> createState() => _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends State<StatsDashboardScreen> {
  final _db = Supabase.instance.client;

  Map<String, int> _stats = {
    'posts': 0,
    'likes': 0,
    'messages': 0,
    'currentStreak': 0,
  };
  List<Map<String, dynamic>> _categoryDistribution = [];
  List<Map<String, dynamic>> _progressHistory = [];
  Map<String, int> _streakData = {};
  bool _isLoading = true;

  RealtimeChannel? _postsChannel;
  RealtimeChannel? _chatChannel;
  Timer? _debounceTimer;

  String? get _uid => _db.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _postsChannel?.unsubscribe();
    _chatChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeRealtime() {
    final uid = _uid;
    if (uid == null) return;

    void scheduleReload() {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 400), () {
        if (mounted) _loadAll(silent: true);
      });
    }

    _postsChannel = _db
        .channel('stats_posts_${widget.world}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'community_posts',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: uid,
        ),
        callback: (_) => scheduleReload(),
      )
      ..subscribe();

    _chatChannel = _db
        .channel('stats_chat_${widget.world}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'chat_messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: uid,
        ),
        callback: (_) => scheduleReload(),
      )
      ..subscribe();
  }

  Future<void> _loadAll({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);

    final uid = _uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final results = await Future.wait([
        _fetchUserPosts(uid),
        _fetchChatDates(uid),
      ]);

      final posts     = results[0] as List<Map<String, dynamic>>;
      final chatDates = results[1] as List<DateTime>;

      final postCount    = posts.length;
      final likesReceived = posts.fold<int>(0, (s, p) => s + ((p['likes_count'] as num?)?.toInt() ?? 0));
      final chatCount    = chatDates.length;
      final streak       = _calcCurrentStreak(chatDates);

      // Kategorieverteilung aus Posts
      final categoryDist = _groupByCategory(posts);

      // Lesefortschritt: kumulierte Posts pro Tag (30 Tage)
      final progressHist = _buildProgressHistory(posts);

      // Streak-Heatmap aus Chat-Aktivität
      final streakData = _buildStreakHeatmap(chatDates);

      if (mounted) {
        setState(() {
          _stats = {
            'posts': postCount,
            'likes': likesReceived,
            'messages': chatCount,
            'currentStreak': streak,
          };
          _categoryDistribution = categoryDist;
          _progressHistory = progressHist;
          _streakData = streakData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Stats load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Supabase-Queries ──────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _fetchUserPosts(String uid) async {
    try {
      final res = await _db
          .from('community_posts')
          .select('id, created_at, likes_count, content')
          .eq('user_id', uid)
          .eq('world', widget.world)
          .order('created_at', ascending: false)
          .limit(500);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ community_posts query: $e');
      return [];
    }
  }

  Future<List<DateTime>> _fetchChatDates(String uid) async {
    try {
      final res = await _db
          .from('chat_messages')
          .select('created_at')
          .eq('user_id', uid)
          .like('room_id', '${widget.world}%')
          .order('created_at', ascending: false)
          .limit(1000);
      return (res as List)
          .map((r) => DateTime.tryParse(r['created_at'] as String? ?? ''))
          .whereType<DateTime>()
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ chat_messages query: $e');
      return [];
    }
  }

  // ── Aggregations ──────────────────────────────────────────────────────

  int _calcCurrentStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    final daySet = dates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();
    int streak = 0;
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);
    if (!daySet.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (daySet.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  List<Map<String, dynamic>> _groupByCategory(List<Map<String, dynamic>> posts) {
    // Wörter im Post-Content als Proxy für Kategorie
    final worldColor = widget.world == 'materie'
        ? const Color(0xFFE53935)
        : const Color(0xFF7C4DFF);
    if (posts.isEmpty) return [];
    return [
      {
        'category': widget.world == 'materie' ? 'Materie-Beiträge' : 'Energie-Beiträge',
        'count': posts.length,
        'color': worldColor,
      }
    ];
  }

  List<Map<String, dynamic>> _buildProgressHistory(List<Map<String, dynamic>> posts) {
    final Map<String, int> daily = {};
    for (final row in posts) {
      final ts = DateTime.tryParse(row['created_at'] as String? ?? '');
      if (ts == null) continue;
      final key = _dayKey(ts);
      daily[key] = (daily[key] ?? 0) + 1;
    }
    final now = DateTime.now();
    final history = <Map<String, dynamic>>[];
    int cumulative = 0;
    for (int i = 30; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = _dayKey(date);
      final dailyCount = daily[key] ?? 0;
      cumulative += dailyCount;
      history.add({
        'date': date,
        'progress': cumulative,
        'dailyCount': dailyCount,
      });
    }
    return history;
  }

  Map<String, int> _buildStreakHeatmap(List<DateTime> dates) {
    final Map<String, int> heatmap = {};
    for (final d in dates) {
      final key = _dayKey(d);
      heatmap[key] = (heatmap[key] ?? 0) + 1;
    }
    final now = DateTime.now();
    for (int i = 90; i >= 0; i--) {
      final key = _dayKey(now.subtract(Duration(days: i)));
      heatmap.putIfAbsent(key, () => 0);
    }
    return heatmap;
  }

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── BUILD ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final worldColor = widget.world == 'materie'
        ? const Color(0xFFE53935)
        : const Color(0xFF7C4DFF);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.analytics_outlined, color: worldColor),
            const SizedBox(width: 8),
            Text(
              widget.world == 'materie'
                  ? 'Materie Statistiken'
                  : 'Energie Statistiken',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: worldColor,
              ),
            ),
          ],
        ),
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadAll(),
            tooltip: 'Statistiken aktualisieren',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCounterSection(),
                    const SizedBox(height: 24),
                    if (_categoryDistribution.isNotEmpty) ...[
                      _buildSectionHeader(
                          '📊 Aktivitätsübersicht', 'Deine Beiträge'),
                      const SizedBox(height: 16),
                      CategoryPieChart(
                        data: _categoryDistribution,
                        world: widget.world,
                      ),
                      const SizedBox(height: 24),
                    ],
                    _buildSectionHeader('📈 Beitragsfortschritt', 'Letzte 30 Tage'),
                    const SizedBox(height: 16),
                    ReadingProgressChart(
                      data: _progressHistory,
                      world: widget.world,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('🔥 Chat-Aktivitätsverlauf', 'Letzte 90 Tage'),
                    const SizedBox(height: 16),
                    StreakHeatmap(
                      data: _streakData,
                      world: widget.world,
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          '💡 Tipp: Schreibe Posts und chatte täglich, um deinen Streak zu erhöhen!',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCounterSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AnimatedCounterCard(
                title: 'Beiträge',
                value: _stats['posts'] ?? 0,
                icon: Icons.edit_note,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedCounterCard(
                title: 'Likes erhalten',
                value: _stats['likes'] ?? 0,
                icon: Icons.favorite,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AnimatedCounterCard(
                title: 'Nachrichten',
                value: _stats['messages'] ?? 0,
                icon: Icons.chat_bubble_outline,
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedCounterCard(
                title: 'Streak',
                value: _stats['currentStreak'] ?? 0,
                icon: Icons.local_fire_department,
                color: Colors.deepOrange,
                suffix: ' Tage',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
