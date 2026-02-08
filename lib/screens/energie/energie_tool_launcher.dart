import 'package:flutter/material.dart';
import 'tools/energie_tools.dart';

/// 🛠️ WERKZEUG-LAUNCHER für ENERGIE Chat-Räume
class EnergieToolLauncherScreen extends StatelessWidget {
  final String roomId;
  
  const EnergieToolLauncherScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    // Tool-Mapping
    final Map<String, Map<String, dynamic>> roomTools = {
      'meditation': {
        'tool': MeditationsTimerTool(realm: 'energie', roomId: 'meditation'),
        'icon': Icons.self_improvement,
        'name': '⏱️ Meditations-Timer',
        'description': 'Geführte Meditationssessions',
        'color': Colors.blue,
      },
      'astralreisen': {
        'tool': TraumTagebuchTool(realm: 'energie', roomId: 'astralreisen'),
        'icon': Icons.bedtime,
        'name': '📔 Traum-Tagebuch',
        'description': 'Dokumentiere Astralreisen',
        'color': Colors.indigo,
      },
      'chakren': {
        'tool': ChakraScannerTool(realm: 'energie', roomId: 'chakren'),
        'icon': Icons.emoji_objects,
        'name': '🌈 Chakra-Scanner',
        'description': 'Chakren visualisieren',
        'color': Colors.purple,
      },
      'spiritualitaet': {
        'tool': BewusstseinsJournalTool(realm: 'energie', roomId: 'spiritualitaet'),
        'icon': Icons.auto_stories,
        'name': '🔮 Bewusstseins-Journal',
        'description': 'Spirituelle Erkenntnisse',
        'color': Colors.amber,
      },
      'heilung': {
        'tool': HeilfrequenzPlayerTool(realm: 'energie', roomId: 'heilung'),
        'icon': Icons.music_note,
        'name': '🎵 Heilfrequenz-Player',
        'description': 'Solfeggio-Frequenzen',
        'color': Colors.green,
      },
    };

    final toolData = roomTools[roomId];

    if (toolData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('🛠️ Kein Werkzeug')),
        body: const Center(child: Text('Für diesen Raum gibt es kein Werkzeug.')),
      );
    }

    return toolData['tool'] as Widget;
  }
}
