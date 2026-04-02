/// 📰 MATERIE WORLD EXTENSIONS - V115+
/// News Feed, Conspiracy Database, Knowledge Graph
library;

import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:graphview/GraphView.dart';

// ========================================
// 📰 NEWS FEED SCREEN
// ========================================
class NewsArticle {
  final String id;
  final String title;
  final String summary;
  final String category;
  final DateTime publishedAt;
  final String? imageUrl;
  final bool isBookmarked;

  NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.publishedAt,
    this.imageUrl,
    this.isBookmarked = false,
  });
}

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  String _selectedCategory = 'Alle';
  final List<String> _categories = ['Alle', 'Geopolitik', 'Wissenschaft', 'Alternative Medien', 'Technologie'];
  
  final List<NewsArticle> _articles = [
    NewsArticle(
      id: '1',
      title: 'Neue Enthüllungen über globale Machtverhältnisse',
      summary: 'Investigative Journalisten decken verborgene Verbindungen auf...',
      category: 'Geopolitik',
      publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NewsArticle(
      id: '2',
      title: 'Durchbruch in der Quantenphysik',
      summary: 'Wissenschaftler entdecken neue Dimension der Realität...',
      category: 'Wissenschaft',
      publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredArticles = _selectedCategory == 'Alle'
        ? _articles
        : _articles.where((a) => a.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('📰 News Feed'),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: Column(
        children: [
          // Category Filter
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = category);
                    },
                    selectedColor: const Color(0xFF1976D2),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Articles List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredArticles.length,
              itemBuilder: (context, index) {
                final article = filteredArticles[index];
                return Card(
                  color: const Color(0xFF1A1A2E),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.article, color: Colors.blue),
                    ),
                    title: Text(
                      article.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(article.summary, style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(
                          '${article.category} • ${_formatTime(article.publishedAt)}',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        article.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: Colors.blue,
                      ),
                      onPressed: () {
                        // Toggle bookmark
                      },
                    ),
                    onTap: () {
                      // Open article details
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inHours < 1) return 'vor ${diff.inMinutes}m';
    if (diff.inDays < 1) return 'vor ${diff.inHours}h';
    return 'vor ${diff.inDays}d';
  }
}

// ========================================
// 🔍 CONSPIRACY DATABASE SCREEN
// ========================================
class ConspiracyTheory {
  final String id;
  final String title;
  final String summary;
  final List<String> evidence;
  final List<String> sources;
  final DateTime? timelineDate;

  ConspiracyTheory({
    required this.id,
    required this.title,
    required this.summary,
    required this.evidence,
    required this.sources,
    this.timelineDate,
  });
}

class ConspiracyDatabaseScreen extends StatelessWidget {
  const ConspiracyDatabaseScreen({super.key});

  static final List<ConspiracyTheory> _theories = [
    ConspiracyTheory(
      id: '1',
      title: 'MK-Ultra Projekt',
      summary: 'CIA-Programm zur Bewusstseinskontrolle (1953-1973)',
      evidence: [
        'Freigegebene CIA-Dokumente',
        'Zeugenaussagen ehemaliger Teilnehmer',
        'Kongressanhörungen 1977',
      ],
      sources: [
        'CIA Freedom of Information Act',
        'Church Committee Report',
      ],
      timelineDate: DateTime(1953),
    ),
    ConspiracyTheory(
      id: '2',
      title: 'Operation Northwoods',
      summary: 'Geplante False-Flag-Operation gegen Kuba (1962)',
      evidence: [
        'Deklassifizierte Pentagon-Dokumente',
        'Joint Chiefs of Staff Memorandum',
      ],
      sources: [
        'National Security Archive',
        'ABC News Report 2001',
      ],
      timelineDate: DateTime(1962),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('🔍 Conspiracy Database'),
        backgroundColor: const Color(0xFFC62828),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _theories.length,
        itemBuilder: (context, index) {
          final theory = _theories[index];
          return Card(
            color: const Color(0xFF1A1A2E),
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              title: Text(
                theory.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                theory.summary,
                style: const TextStyle(color: Colors.white70),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📋 Beweise:',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      ...theory.evidence.map((e) => Padding(
                            padding: const EdgeInsets.only(left: 8, top: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(color: Colors.white70)),
                                Expanded(child: Text(e, style: const TextStyle(color: Colors.white70))),
                              ],
                            ),
                          )),
                      const SizedBox(height: 12),
                      const Text(
                        '🔗 Quellen:',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      ...theory.sources.map((s) => Padding(
                            padding: const EdgeInsets.only(left: 8, top: 4),
                            child: Text('• $s', style: const TextStyle(color: Colors.blue)),
                          )),
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

// ========================================
// 🕸️ KNOWLEDGE GRAPH SCREEN
// ========================================

class KnowledgeGraphScreen extends StatefulWidget {
  const KnowledgeGraphScreen({super.key});

  @override
  State<KnowledgeGraphScreen> createState() => _KnowledgeGraphScreenState();
}

class _KnowledgeGraphScreenState extends State<KnowledgeGraphScreen> {
  final Graph graph = Graph()..isTree = false;
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

  @override
  void initState() {
    super.initState();
    _buildGraph();
  }

  void _buildGraph() {
    final node1 = Node.Id(1);
    final node2 = Node.Id(2);
    final node3 = Node.Id(3);
    final node4 = Node.Id(4);

    graph.addEdge(node1, node2);
    graph.addEdge(node1, node3);
    graph.addEdge(node2, node4);
    graph.addEdge(node3, node4);

    builder
      ..siblingSeparation = 100
      ..levelSeparation = 150
      ..subtreeSeparation = 150
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('🕸️ Wissensgraph'),
        backgroundColor: const Color(0xFF6A1B9A),
      ),
      body: InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(100),
        minScale: 0.1,
        maxScale: 2.0,
        child: GraphView(
          graph: graph,
          algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
          paint: Paint()
            ..color = Colors.purple
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
          builder: (Node node) {
            final id = node.key!.value as int;
            final labels = ['Konzept A', 'Person B', 'Ereignis C', 'Theorie D'];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF7B1FA2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple),
              ),
              child: Text(
                labels[id - 1],
                style: const TextStyle(color: Colors.white),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ========================================
// 👥 COMMUNITY GROUPS SCREEN
// ========================================
class CommunityGroup {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int memberCount;

  CommunityGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.memberCount,
  });
}

class CommunityGroupsScreen extends StatelessWidget {
  const CommunityGroupsScreen({super.key});

  static final List<CommunityGroup> _groups = [
    CommunityGroup(
      id: '1',
      name: 'Meditation Circle',
      description: 'Tägliche Gruppen-Meditationen',
      icon: '🧘',
      memberCount: 142,
    ),
    CommunityGroup(
      id: '2',
      name: 'Tarot Study Group',
      description: 'Tarot-Legungen lernen und teilen',
      icon: '🔮',
      memberCount: 87,
    ),
    CommunityGroup(
      id: '3',
      name: 'Forschungs-Team Alpha',
      description: 'Untersuchung von Verschwörungstheorien',
      icon: '🔍',
      memberCount: 203,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('👥 Community Gruppen'),
        backgroundColor: const Color(0xFF00897B),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          return Card(
            color: const Color(0xFF1A1A2E),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF26A69A).withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(group.icon, style: const TextStyle(fontSize: 24))),
              ),
              title: Text(group.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.description, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text('${group.memberCount} Mitglieder', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${group.name} beigetreten!')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF26A69A)),
                child: const Text('Beitreten'),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ========================================
// 🤝 FRIENDSHIP SYSTEM SCREEN
// ========================================
class FriendProfile {
  final String id;
  final String username;
  final String avatar;
  final int level;
  final String status;

  FriendProfile({
    required this.id,
    required this.username,
    required this.avatar,
    required this.level,
    required this.status,
  });
}

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  static final List<FriendProfile> _friends = [
    FriendProfile(id: '1', username: 'MysticSoul', avatar: '🧙', level: 12, status: 'Meditiert gerade'),
    FriendProfile(id: '2', username: 'CosmicSeeker', avatar: '🌟', level: 8, status: 'Online'),
    FriendProfile(id: '3', username: 'TruthFinder', avatar: '🔍', level: 15, status: 'Forscht'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('🤝 Freunde'),
        backgroundColor: const Color(0xFFF57C00),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          return Card(
            color: const Color(0xFF1A1A2E),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFFF9800),
                child: Text(friend.avatar, style: const TextStyle(fontSize: 24)),
              ),
              title: Row(
                children: [
                  Text(friend.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB74D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Lvl ${friend.level}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ],
              ),
              subtitle: Text(friend.status, style: const TextStyle(color: Colors.white70)),
              trailing: IconButton(
                icon: const Icon(Icons.chat, color: Colors.orange),
                onPressed: () {
                  // Open chat
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add friend
        },
        backgroundColor: const Color(0xFFFF9800),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
