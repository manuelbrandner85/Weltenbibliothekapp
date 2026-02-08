import 'package:flutter/material.dart';
import 'tools/materie_tools.dart';

/// 🛠️ WERKZEUG-LAUNCHER für MATERIE Chat-Räume
class MaterieToolLauncherScreen extends StatelessWidget {
  final String roomId;
  
  const MaterieToolLauncherScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    // Tool-Mapping
    final Map<String, Map<String, dynamic>> roomTools = {
      'politik': {
        'tool': NewsTrackerTool(realm: 'materie', roomId: 'politik'),
        'icon': Icons.newspaper,
        'name': '📰 News-Tracker',
        'description': 'Verfolge alternative Nachrichtenquellen',
        'color': Colors.red,
      },
      'geschichte': {
        'tool': ArtefaktDatenbankTool(realm: 'materie', roomId: 'geschichte'),
        'icon': Icons.account_balance,
        'name': '🗺️ Artefakt-Datenbank',
        'description': 'Sammle antike Fundorte',
        'color': Colors.amber,
      },
      'ufos': {
        'tool': UfoSichtungsMelderTool(realm: 'materie', roomId: 'ufos'),
        'icon': Icons.explore,
        'name': '📍 Sichtungs-Melder',
        'description': 'Melde UFO-Sichtungen',
        'color': Colors.green,
      },
      'verschwoerungen': {
        'tool': ConnectionsBoardTool(realm: 'materie', roomId: 'verschwoerungen'),
        'icon': Icons.account_tree,
        'name': '🕸️ Connections-Board',
        'description': 'Verknüpfe Verbindungen',
        'color': Colors.purple,
      },
      'wissenschaft': {
        'tool': PatentArchivTool(realm: 'materie', roomId: 'wissenschaft'),
        'icon': Icons.science,
        'name': '💡 Patent-Archiv',
        'description': 'Sammle unterdrückte Patente',
        'color': Colors.blue,
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
