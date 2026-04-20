/// 📤 EXPORT SERVICE - V115+
/// Export Tarot, Meditation Stats, Crystal Collection
library;

import 'dart:convert';
import 'package:flutter/material.dart';

// ========================================
// 📤 EXPORT SERVICE
// ========================================
class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  /// Export Tarot Reading as Text
  Future<String> exportTarotReading(Map<String, dynamic> reading) async {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════');
    buffer.writeln('🔮 TAROT-LEGUNG');
    buffer.writeln('═══════════════════════════════');
    buffer.writeln('Datum: ${reading['date'] ?? DateTime.now().toString()}');
    buffer.writeln('Frage: ${reading['question'] ?? 'Keine Frage'}');
    buffer.writeln();
    buffer.writeln('KARTEN:');
    
    final cards = reading['cards'] as List? ?? [];
    for (var i = 0; i < cards.length; i++) {
      final card = cards[i];
      buffer.writeln('${i + 1}. ${card['name']} - ${card['position']}');
      buffer.writeln('   Bedeutung: ${card['meaning']}');
      buffer.writeln();
    }
    
    buffer.writeln('INTERPRETATION:');
    buffer.writeln(reading['interpretation'] ?? 'Keine Interpretation');
    buffer.writeln();
    buffer.writeln('═══════════════════════════════');
    
    return buffer.toString();
  }

  /// Export Meditation Stats as CSV
  Future<String> exportMeditationStatsCSV(List<Map<String, dynamic>> sessions) async {
    final buffer = StringBuffer();
    buffer.writeln('Datum,Dauer (Min),Typ,Notizen');
    
    for (var session in sessions) {
      final date = session['date'] ?? '';
      final duration = session['duration'] ?? 0;
      final type = session['type'] ?? 'Standard';
      final notes = session['notes'] ?? '';
      
      buffer.writeln('$date,$duration,$type,"$notes"');
    }
    
    return buffer.toString();
  }

  /// Export Crystal Collection as JSON
  Future<String> exportCrystalCollectionJSON(List<Map<String, dynamic>> crystals) async {
    final data = {
      'exportDate': DateTime.now().toIso8601String(),
      'totalCrystals': crystals.length,
      'crystals': crystals,
    };
    
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Show export options dialog
  static void showExportDialog(
    BuildContext context, {
    required String title,
    required List<ExportOption> options,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            return ListTile(
              leading: Icon(option.icon, color: option.color),
              title: Text(option.label, style: const TextStyle(color: Colors.white)),
              subtitle: Text(option.description, style: const TextStyle(color: Colors.white70)),
              onTap: () {
                Navigator.pop(context);
                option.onTap();
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );
  }
}

class ExportOption {
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  ExportOption({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

// ========================================
// 📊 QUICK EXPORT WIDGETS
// ========================================
class QuickExportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const QuickExportButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
