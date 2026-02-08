import 'package:flutter/material.dart';

/// ENERGIE SPIRIT TAB - Cloudflare Edition
/// Vereinfachte Version ohne Firebase-Abhängigkeiten
class SpiritTabCloudflare extends StatefulWidget {
  const SpiritTabCloudflare({super.key});

  @override
  State<SpiritTabCloudflare> createState() => _SpiritTabCloudflareState();
}

class _SpiritTabCloudflareState extends State<SpiritTabCloudflare> {
  // UNUSED FIELD: final CloudflareApiService _api = CloudflareApiService();
  
  // Spirit Tools
  final List<Map<String, dynamic>> _spiritTools = [
    {
      'icon': Icons.self_improvement,
      'title': 'Meditation Timer',
      'description': 'Geführte Meditation',
      'color': Colors.purple,
    },
    {
      'icon': Icons.psychology,
      'title': 'Bewusstseins-Tracker',
      'description': 'Tägliches Bewusstsein',
      'color': Colors.blue,
    },
    {
      'icon': Icons.auto_awesome,
      'title': 'Chakra-Scanner',
      'description': 'Energiezentren prüfen',
      'color': Colors.pink,
    },
    {
      'icon': Icons.nightlight,
      'title': 'Astralreise-Guide',
      'description': 'OBE Techniken',
      'color': Colors.cyan,
    },
    {
      'icon': Icons.stream,
      'title': 'Frequenz-Generator',
      'description': 'Solfeggio Frequenzen',
      'color': Colors.amber,
    },
    {
      'icon': Icons.ac_unit,
      'title': 'Kristall-Heilung',
      'description': 'Kristallenergie',
      'color': Colors.teal,
    },
    {
      'icon': Icons.wb_twilight,
      'title': 'Mond-Kalender',
      'description': 'Mondphasen & Energie',
      'color': Colors.indigo,
    },
    {
      'icon': Icons.track_changes,
      'title': 'Synchronizität-Journal',
      'description': 'Bedeutungsvolle Zufälle',
      'color': Colors.deepPurple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),
          
          // Tools Grid
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildToolCard(_spiritTools[index]),
                childCount: _spiritTools.length,
              ),
            ),
          ),
          
          // Daily Practice
          SliverToBoxAdapter(
            child: _buildDailyPractice(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade900,
            Colors.blue.shade900,
            Colors.pink.shade900,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Text(
                  'SPIRIT TOOLS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Werkzeuge für spirituelle Entwicklung',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cloud, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Powered by Cloudflare',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(Map<String, dynamic> tool) {
    return GestureDetector(
      onTap: () => _openTool(tool),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tool['color'].withValues(alpha: 0.3),
              tool['color'].withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: tool['color'].withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                tool['icon'] as IconData,
                size: 48,
                color: tool['color'],
              ),
              const SizedBox(height: 12),
              Text(
                tool['title'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tool['description'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyPractice() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wb_sunny, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Tägliche Praxis',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPracticeItem('Morgen-Meditation', '10 Minuten', Icons.self_improvement),
          const SizedBox(height: 12),
          _buildPracticeItem('Chakra-Reinigung', '5 Minuten', Icons.ac_unit),
          const SizedBox(height: 12),
          _buildPracticeItem('Dankbarkeits-Journal', '3 Einträge', Icons.edit_note),
        ],
      ),
    );
  }

  Widget _buildPracticeItem(String title, String duration, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  duration,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_outline, color: Colors.white.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  void _openTool(Map<String, dynamic> tool) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Row(
          children: [
            Icon(tool['icon'] as IconData, color: tool['color']),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tool['title'],
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tool['description'],
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            const Text(
              'Dieses Tool wird bald verfügbar sein!',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Feature wird mit Cloudflare Workers implementiert',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }
}
