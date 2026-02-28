import 'package:flutter/material.dart';
import '../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/timeline_widget.dart';
import '../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../../widgets/graph_3d_enhanced_widget.dart'; // 🆕 ENHANCED VERSION
import '../../widgets/interactive_map_enhanced_widget.dart'; // 🆕 ENHANCED MAP
import '../../widgets/video_player_widget.dart';
import '../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../../widgets/related_narratives_card.dart';  // 🆕 Related Narratives
import '../../models/narrative.dart';  // 🆕 Narrative Model
import '../../services/achievement_service.dart';  // 🏆 Achievement System
import '../../services/daily_challenges_service.dart';  // 🎯 Daily Challenges
import 'package:shared_preferences/shared_preferences.dart';  // 🏆 Daily Tracking

/// Narrative Detail Screen mit 3D Graph, Karte und Video Player
class NarrativeDetailScreen extends StatefulWidget {
  final String narrativeId;
  final String narrativeTitle;

  const NarrativeDetailScreen({
    super.key,
    required this.narrativeId,
    required this.narrativeTitle,
  });

  @override
  State<NarrativeDetailScreen> createState() => _NarrativeDetailScreenState();
}

class _NarrativeDetailScreenState extends State<NarrativeDetailScreen>
    with SingleTickerProviderStateMixin {
  static const String _backendUrl = 'https://api-backend.brandy13062.workers.dev';

  Map<String, dynamic>? _narrative;
  List<Map<String, dynamic>> _relatedNarratives = [];
  Map<String, dynamic>? _graphData;
  bool _isLoading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadNarrativeDetails();
    
    // 🏆 Achievement Trigger: Narrative View
    _trackNarrativeView();
  }
  
  /// Track narrative view for achievements
  Future<void> _trackNarrativeView() async {
    try {
      await AchievementService().incrementProgress('first_narrative');
      await AchievementService().incrementProgress('narrative_explorer');
      
      // 🎯 Daily Challenge Tracking
      await DailyChallengesService().incrementProgress(
        ChallengeCategory.read,
        amount: 1,
      );
      
      // 🏆 Quick Learner: Track daily narrative count
      await _trackDailyNarrativeCount();
      
      // 🏆 Encyclopedia: Track category (if available)
      if (_narrative?['category'] != null) {
        await _trackCategoryView(_narrative!['category'] as String);
      }
    } catch (e) {
      debugPrint('⚠️ Achievement tracking error: $e');
    }
  }
  
  /// Track daily narrative count for quick_learner achievement
  Future<void> _trackDailyNarrativeCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
      
      final lastDate = prefs.getString('daily_narrative_date') ?? '';
      final count = prefs.getInt('daily_narrative_count') ?? 0;
      
      if (lastDate == today) {
        // Same day - increment count
        final newCount = count + 1;
        await prefs.setInt('daily_narrative_count', newCount);
        
        // Check for quick_learner achievement (3 narratives)
        if (newCount >= 3) {
          await AchievementService().incrementProgress('quick_learner', amount: newCount);
        }
      } else {
        // New day - reset counter
        await prefs.setString('daily_narrative_date', today);
        await prefs.setInt('daily_narrative_count', 1);
      }
    } catch (e) {
      debugPrint('⚠️ Daily narrative tracking error: $e');
    }
  }
  
  /// Track category view for encyclopedia achievement
  Future<void> _trackCategoryView(String category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final viewedCategories = prefs.getStringList('viewed_categories') ?? [];
      
      if (!viewedCategories.contains(category)) {
        viewedCategories.add(category);
        await prefs.setStringList('viewed_categories', viewedCategories);
        
        // Check for encyclopedia achievement (10 categories)
        if (viewedCategories.length >= 10) {
          await AchievementService().incrementProgress('encyclopedia', amount: viewedCategories.length);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Category tracking error: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNarrativeDetails() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/api/narrative/${widget.narrativeId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _narrative = data['narrative'];
          _relatedNarratives = List<Map<String, dynamic>>.from(
            data['related'] ?? [],
          );
          _graphData = data['graphData'];
        });
      }
    } catch (e) {
      debugPrint('Error loading narrative details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.narrativeTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'Info'),
            Tab(icon: Icon(Icons.hub), text: '3D Graph'),
            Tab(icon: Icon(Icons.map), text: 'Karte'),
            Tab(icon: Icon(Icons.video_library), text: 'Videos'),
          ],
          indicatorColor: Colors.cyan,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(),
                _build3DGraphTab(),
                _buildMapTab(),
                _buildVideosTab(),
              ],
            ),
    );
  }

  // TAB 1: INFO
  Widget _buildInfoTab() {
    if (_narrative == null) {
      return const Center(child: Text('Keine Daten verfügbar'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titel & Kategorien
          _buildSectionTitle('📚 Narrative'),
          const SizedBox(height: 8),
          Text(
            _narrative!['title'] as String,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: (_narrative!['categories'] as List)
                .map((cat) => Chip(
                      label: Text(_getCategoryName(cat as String)),
                      backgroundColor: Colors.cyan.withValues(alpha: 0.2),
                      labelStyle: const TextStyle(color: Colors.cyan),
                    ))
                .toList(),
          ),

          const SizedBox(height: 24),

          // Timeline
          if (_narrative!['timeline'] != null) ...[
            _buildSectionTitle('📅 Timeline'),
            const SizedBox(height: 12),
            TimelineVisualization(
              title: _narrative!['title'] as String,
              events: (_narrative!['timeline'] as List)
                  .map((e) => TimelineEvent(
                        year: e['year'] as int,
                        event: e['event'] as String,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Location
          if (_narrative!['location'] != null) ...[
            _buildSectionTitle('📍 Ort'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      (_narrative!['location'] as Map)['name'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Keywords
          if (_narrative!['keywords'] != null) ...[
            _buildSectionTitle('🔑 Schlüsselwörter'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_narrative!['keywords'] as List)
                  .map((keyword) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          keyword as String,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
          
          // 🆕 RELATED NARRATIVES (AI-POWERED CONNECTIONS)
          const SizedBox(height: 24),
          if (_narrative != null) RelatedNarrativesCard(
            currentNarrative: Narrative(
              id: widget.narrativeId,
              titel: _narrative!['title'] as String? ?? widget.narrativeTitle,
              kategorie: (_narrative!['categories'] as List?)?.firstOrNull?.toString() ?? 'Unknown',
              zusammenfassung: _narrative!['description'] as String?,
              tags: (_narrative!['keywords'] as List?)?.map((e) => e.toString()).toList(),
            ),
            onNarrativeTap: (narrative) {
              // TODO: Navigate to related narrative detail
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📖 Öffne: ${narrative.titel}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // TAB 2: 3D GRAPH
  Widget _build3DGraphTab() {
    if (_graphData == null) {
      return const Center(
        child: Text(
          'Keine Graph-Daten verfügbar',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('🕸️ Verbindungs-Netzwerk (3D)'),
          const SizedBox(height: 8),
          const Text(
            'Dieses Narrative ist mit folgenden Themen verbunden:',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),

          // 🆕 ENHANCED 3D Graph Widget mit Filter & Search
          Graph3DEnhancedWidget(
            graphData: _graphData!,
            availableCategories: const [
              'UFO & Technologie',
              'Geheimgesellschaften',
              'Historische Ereignisse',
              'Wissenschaft',
              'Politik',
            ],
            onNodeTap: (narrativeId) {
              // Navigate to related narrative
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Öffne Narrative: $narrativeId'),
                  backgroundColor: Colors.cyan,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Related Narratives List
          _buildSectionTitle('🔗 Verwandte Narrative'),
          const SizedBox(height: 12),
          ..._relatedNarratives.map((related) => Card(
                color: Colors.grey[900],
                child: ListTile(
                  leading: const Icon(Icons.link, color: Colors.cyan),
                  title: Text(
                    related['title'] as String,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NarrativeDetailScreen(
                          narrativeId: related['id'] as String,
                          narrativeTitle: related['title'] as String,
                        ),
                      ),
                    );
                  },
                ),
              )),
        ],
      ),
    );
  }

  // TAB 3: KARTE
  Widget _buildMapTab() {
    if (_narrative == null || _narrative!['location'] == null) {
      return const Center(
        child: Text(
          'Keine Geo-Daten verfügbar',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    // Alle Narratives mit Location (main + related)
    final narrativesWithLocation = [
      _narrative!,
      ..._relatedNarratives.where((n) => n['location'] != null),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('🗺️ Ereignis-Karte'),
          const SizedBox(height: 8),
          const Text(
            'Geografische Visualisierung der Ereignisse',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),

          // 🆕 ENHANCED Interactive Map mit Clustering & Heatmap
          InteractiveMapEnhancedWidget(
            narratives: narrativesWithLocation,
            enableClustering: true,
            enableHeatmap: false,
            onMarkerTap: (narrativeId) {
              debugPrint('Marker tapped: $narrativeId');
              // Optional: Navigate to related narrative
            },
          ),
        ],
      ),
    );
  }

  // TAB 4: VIDEOS
  Widget _buildVideosTab() {
    // Demo Videos basierend auf Narrative
    final demoVideos = [
      {
        'title': 'Dokumentation: ${_narrative?['title'] ?? 'Recherche'}',
        'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'thumbnail': 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
      },
      {
        'title': 'Alternative Perspektive',
        'url': 'https://rumble.com/search/video?q=${widget.narrativeId}',
        'thumbnail': null,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('🎥 Video-Material'),
          const SizedBox(height: 8),
          const Text(
            'Dokumentationen und alternative Quellen',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),

          // Video Players
          ...demoVideos.map((video) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: InAppVideoPlayer(
                  videoUrl: video['url'] as String,
                  title: video['title'] as String,
                  thumbnail: video['thumbnail'],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.cyan,
      ),
    );
  }

  String _getCategoryName(String categoryId) {
    const categoryNames = {
      'ufo': '👽 UFOs',
      'secret_society': '🏛️ Geheimgesellschaften',
      'technology': '⚡ Technologie',
      'history': '📜 Historie',
      'geopolitics': '🌍 Geopolitik',
      'science': '🔬 Wissenschaft',
      'cosmology': '🌌 Kosmologie',
    };
    return categoryNames[categoryId] ?? categoryId;
  }
}
