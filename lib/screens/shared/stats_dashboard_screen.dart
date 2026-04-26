import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/stats/stats_charts.dart';

/// 📊 Stats Dashboard – Echtzeit aus Supabase
///
/// Daten kommen direkt aus den produktiven Tabellen
/// (likes, bookmarks, articles, chat_messages) und werden über
/// Supabase-Realtime live aktualisiert.
class StatsDashboardScreen extends StatefulWidget {
  final String world; // 'materie' oder 'energie'

  const StatsDashboardScreen({super.key, required this.world});

  @override
  State<StatsDashboardScreen> createState() => _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends State<StatsDashboardScreen> {
  final _db = Supabase.instance.client;

  Map<String, int> _stats = {
    'read': 0,
    'favorites': 0,
    'notes': 0,
    'currentStreak': 0,
  };
  List<Map<String, dynamic>> _categoryDistribution = [];
  List<Map<String, dynamic>> _progressHistory = [];
  Map<String, int> _streakData = {};
  bool _isLoading = true;

  RealtimeChannel? _likesChannel;
  RealtimeChannel? _bookmarksChannel;
  RealtimeChannel? _articlesChannel;
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
    _likesChannel?.unsubscribe();
    _bookmarksChannel?.unsubscribe();
    _articlesChannel?.unsubscribe();
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

    _likesChannel = _db
        .channel('stats_likes_${widget.world}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'likes',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: uid,
        ),
        callback: (_) => scheduleReload(),
      )
      ..subscribe();

    _bookmarksChannel = _db
        .channel('stats_bookmarks_${widget.world}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'bookmarks',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: uid,
        ),
        callback: (_) => scheduleReload(),
      )
      ..subscribe();

    _articlesChannel = _db
        .channel('stats_articles_${widget.world}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'articles',
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
        _fetchLikedArticles(uid),
        _fetchBookmarkedArticles(uid),
        _fetchOwnArticles(uid),
        _fetchOwnChatDates(uid),
      ]);

      final liked = results[0] as List<Map<String, dynamic>>;
      final bookmarked = results[1] as List<Map<String, dynamic>>;
      final owned = results[2] as List<Map<String, dynamic>>;
      final chatDates = results[3] as List<DateTime>;

      // Counters
      final read = liked.length;
      final favorites = bookmarked.length;
      final notes = owned.length;
      final currentStreak = _calcCurrentStreak(chatDates);

      // Category distribution (aus geliketen Artikeln, gruppiert)
      final categoryDist = _groupByCategory(liked);

      // Reading progress: kumulative Likes-Anzahl pro Tag (letzte 30 Tage)
      final progressHist = _buildProgressHistory(liked);

      // Streak heatmap: Aktivitäts-Counts pro Tag (letzte 90 Tage)
      final streakData = _buildStreakHeatmap(chatDates);

      if (mounted) {
        setState(() {
          _stats = {
            'read': read,
            'favorites': favorites,
            'notes': notes,
            'currentStreak': currentStreak,
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

  /// Likes des Users → JOIN articles (nur für Welt X) für Datum + Kategorie
  Future<List<Map<String, dynamic>>> _fetchLikedArticles(String uid) async {
    try {
      final res = await _db
          .from('likes')
          .select('created_at, articles!inner(world, category)')
          .eq('user_id', uid)
          .eq('articles.world', widget.world);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ likes query: $e');
      return [];
    }
  }

  /// Bookmarks des Users für Welt X
  Future<List<Map<String, dynamic>>> _fetchBookmarkedArticles(String uid) async {
    try {
      final res = await _db
          .from('bookmarks')
          .select('created_at, articles!inner(world, category)')
          .eq('user_id', uid)
          .eq('articles.world', widget.world);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ bookmarks query: $e');
      return [];
    }
  }

  /// Eigene Artikel des Users in Welt X (= Notizen/Beiträge)
  Future<List<Map<String, dynamic>>> _fetchOwnArticles(String uid) async {
    try {
      final res = await _db
          .from('articles')
          .select('id, created_at, category')
          .eq('user_id', uid)
          .eq('world', widget.world);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ articles query: $e');
      return [];
    }
  }

  /// Chat-Aktivität als Streak-Quelle (alle Räume der Welt)
  Future<List<DateTime>> _fetchOwnChatDates(String uid) async {
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
      if (kDebugMode) debugPrint('⚠️ chat dates query: $e');
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
    // Wenn heute keine Aktivität, prüfe ab gestern
    if (!daySet.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (daySet.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  List<Map<String, dynamic>> _groupByCategory(
      List<Map<String, dynamic>> liked) {
    final Map<String, int> counts = {};
    for (final row in liked) {
      final art = row['articles'] as Map<String, dynamic>?;
      final cat = (art?['category'] as String?) ?? 'unknown';
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
    return counts.entries
        .map((e) => {
              'category': _getCategoryLabel(e.key),
              'count': e.value,
              'color': _getCategoryColor(e.key),
            })
        .toList();
  }

  List<Map<String, dynamic>> _buildProgressHistory(
      List<Map<String, dynamic>> liked) {
    final Map<String, int> daily = {};
    for (final row in liked) {
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

  String _getCategoryLabel(String c) {
    const labels = {
      'conspiracy': 'Verschwörungen',
      'research': 'Forschung',
      'forbiddenKnowledge': 'Verbotenes Wissen',
      'ancientWisdom': 'Alte Weisheit',
      'meditation': 'Meditation',
      'astrology': 'Astrologie',
      'energyWork': 'Energie-Arbeit',
      'consciousness': 'Bewusstsein',
    };
    return labels[c] ?? c;
  }

  Color _getCategoryColor(String c) {
    const colors = {
      'conspiracy': Color(0xFFE53935),
      'research': Color(0xFF1E88E5),
      'forbiddenKnowledge': Color(0xFF6A1B9A),
      'ancientWisdom': Color(0xFFFFB300),
      'meditation': Color(0xFF7E57C2),
      'astrology': Color(0xFFAB47BC),
      'energyWork': Color(0xFF26A69A),
      'consciousness': Color(0xFF29B6F6),
    };
    return colors[c] ?? Colors.grey;
  }

  // ── BUILD ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final worldColor = widget.world == 'materie'
        ? const Color(0xFF1E88E5)
        : const Color(0xFF7E57C2);

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
                          '📊 Kategorieverteilung', 'Geliketen Themen'),
                      const SizedBox(height: 16),
                      CategoryPieChart(
                        data: _categoryDistribution,
                        world: widget.world,
                      ),
                      const SizedBox(height: 24),
                    ],
                    _buildSectionHeader('📈 Lesefortschritt', 'Letzte 30 Tage'),
                    const SizedBox(height: 16),
                    ReadingProgressChart(
                      data: _progressHistory,
                      world: widget.world,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('🔥 Aktivitätsverlauf', 'Letzte 90 Tage'),
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
                          '💡 Tipp: Like Artikel und schreibe im Chat, um deinen Streak zu erhöhen!',
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
                title: 'Gelesen',
                value: _stats['read'] ?? 0,
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedCounterCard(
                title: 'Favoriten',
                value: _stats['favorites'] ?? 0,
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
                title: 'Beiträge',
                value: _stats['notes'] ?? 0,
                icon: Icons.note_alt,
                color: Colors.orange,
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
