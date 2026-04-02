import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../../services/unified_knowledge_service.dart';
import '../../models/knowledge_extended_models.dart';
import '../../widgets/stats/stats_charts.dart';

/// 📊 Premium Stats Dashboard Screen
/// 
/// Zeigt umfassende Statistiken:
/// - Animierte Counter (Gelesen, Favoriten, Notizen, Streak)
/// - Category Pie Chart (Verteilung der gelesenen Kategorien)
/// - Reading Progress Line Chart (Fortschritt über Zeit)
/// - Streak Tracker Heatmap (GitHub-Style)
class StatsDashboardScreen extends StatefulWidget {
  final String world; // 'materie' oder 'energie'
  
  const StatsDashboardScreen({
    super.key,
    required this.world,
  });

  @override
  State<StatsDashboardScreen> createState() => _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends State<StatsDashboardScreen> {
  final _knowledgeService = UnifiedKnowledgeService();
  
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _categoryDistribution = [];
  List<Map<String, dynamic>> _progressHistory = [];
  Map<String, int> _streakData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    
    try {
      await _knowledgeService.init();
      
      // 1. Grundlegende Stats
      final stats = await _knowledgeService.getStatistics(widget.world);
      
      // 2. Category Distribution (für Pie Chart)
      final categoryDist = await _calculateCategoryDistribution();
      
      // 3. Progress History (für Line Chart) - ✅ ECHTE DATEN
      final progressHist = await _loadRealProgressHistory();
      
      // 4. Streak Data (für Heatmap) - ✅ ECHTE DATEN
      final streakData = await _loadRealStreakData();
      
      setState(() {
        _stats = stats;
        _categoryDistribution = categoryDist;
        _progressHistory = progressHist;
        _streakData = streakData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Stats loading error: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Berechnet die Kategorieverteilung für den Pie Chart
  Future<List<Map<String, dynamic>>> _calculateCategoryDistribution() async {
    final entries = await _knowledgeService.getAllEntries(world: widget.world);
    
    // Gelesene Einträge filtern (async)
    final List<KnowledgeEntry> readEntries = [];
    for (var entry in entries) {
      final progress = await _knowledgeService.getProgress(entry.id);
      if (progress?.isRead == true) {
        readEntries.add(entry);
      }
    }
    
    // Kategorien zählen
    final Map<String, int> categoryCount = {};
    for (var entry in readEntries) {
      final category = entry.category;
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }
    
    // In Chart-Format umwandeln
    return categoryCount.entries.map((e) {
      return {
        'category': _getCategoryLabel(e.key),
        'count': e.value,
        'color': _getCategoryColor(e.key),
      };
    }).toList();
  }

  /// ✅ PRODUCTION: Lädt echte Fortschritts-Historie aus User-Daten
  Future<List<Map<String, dynamic>>> _loadRealProgressHistory() async {
    final entries = await _knowledgeService.getAllEntries(world: widget.world);
    final Map<String, int> dailyReadCount = {};
    
    // Alle gelesenen Einträge mit ihrem Timestamp sammeln
    for (var entry in entries) {
      final progress = await _knowledgeService.getProgress(entry.id);
      if (progress != null && progress.isRead && progress.readAt != null) {
        final dateKey = '${progress.readAt!.year}-${progress.readAt!.month.toString().padLeft(2, '0')}-${progress.readAt!.day.toString().padLeft(2, '0')}';
        dailyReadCount[dateKey] = (dailyReadCount[dateKey] ?? 0) + 1;
      }
    }
    
    // History für letzte 30 Tage generieren (mit echten Daten)
    final now = DateTime.now();
    final history = <Map<String, dynamic>>[];
    int cumulativeProgress = 0;
    
    for (int i = 30; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      // Tatsächliche gelesene Artikel an diesem Tag
      final dailyRead = dailyReadCount[dateKey] ?? 0;
      cumulativeProgress += dailyRead;
      
      history.add({
        'date': date,
        'progress': cumulativeProgress,
        'dailyCount': dailyRead,
      });
    }
    
    return history;
  }

  /// ✅ PRODUCTION: Lädt echte Streak-Daten aus User-Aktivität
  Future<Map<String, int>> _loadRealStreakData() async {
    final entries = await _knowledgeService.getAllEntries(world: widget.world);
    final Map<String, int> streakData = {};
    
    // Alle gelesenen Einträge mit Datum sammeln
    for (var entry in entries) {
      final progress = await _knowledgeService.getProgress(entry.id);
      if (progress != null && progress.isRead && progress.readAt != null) {
        final dateKey = '${progress.readAt!.year}-${progress.readAt!.month.toString().padLeft(2, '0')}-${progress.readAt!.day.toString().padLeft(2, '0')}';
        streakData[dateKey] = (streakData[dateKey] ?? 0) + 1;
      }
    }
    
    // Sicherstellen, dass auch Tage ohne Aktivität im Bereich sind
    final now = DateTime.now();
    for (int i = 90; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      if (!streakData.containsKey(dateKey)) {
        streakData[dateKey] = 0;
      }
    }
    
    return streakData;
  }

  String _getCategoryLabel(String category) {
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
    return labels[category] ?? category;
  }

  Color _getCategoryColor(String category) {
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
    return colors[category] ?? Colors.grey;
  }

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
              widget.world == 'materie' ? 'Materie Statistiken' : 'Energie Statistiken',
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
            onPressed: _loadStatistics,
            tooltip: 'Statistiken aktualisieren',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. ANIMIERTE COUNTER
                    _buildCounterSection(),
                    
                    const SizedBox(height: 24),
                    
                    // 2. CATEGORY PIE CHART
                    if (_categoryDistribution.isNotEmpty) ...[
                      _buildSectionHeader('📊 Kategorieverteilung', 'Gelesene Themen'),
                      const SizedBox(height: 16),
                      CategoryPieChart(
                        data: _categoryDistribution,
                        world: widget.world,
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // 3. READING PROGRESS LINE CHART
                    if (_progressHistory.isNotEmpty) ...[
                      _buildSectionHeader('📈 Lesefortschritt', 'Letzte 30 Tage'),
                      const SizedBox(height: 16),
                      ReadingProgressChart(
                        data: _progressHistory,
                        world: widget.world,
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // 4. STREAK TRACKER HEATMAP
                    if (_streakData.isNotEmpty) ...[
                      _buildSectionHeader('🔥 Aktivitätsverlauf', 'Letzte 90 Tage'),
                      const SizedBox(height: 16),
                      StreakHeatmap(
                        data: _streakData,
                        world: widget.world,
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Footer mit Tipp
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          '💡 Tipp: Lies jeden Tag, um deinen Streak zu erhöhen!',
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
    if (_stats == null) return const SizedBox.shrink();
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AnimatedCounterCard(
                title: 'Gelesen',
                value: _stats!['read'] ?? 0,
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedCounterCard(
                title: 'Favoriten',
                value: _stats!['favorites'] ?? 0,
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
                title: 'Notizen',
                value: _stats!['notes'] ?? 0,
                icon: Icons.note_alt,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedCounterCard(
                title: 'Streak',
                value: _stats!['currentStreak'] ?? 0,
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
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
