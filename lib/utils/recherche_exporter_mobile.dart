/// WELTENBIBLIOTHEK – EXPORT-FUNKTIONALITÄT (MOBILE VERSION)
/// 
/// Export von Recherche-Ergebnissen in verschiedenen Formaten:
/// - PDF: Professionelle Dokumente mit Formatierung
/// - Markdown: Für Notizen und GitHub/Wikis
/// - JSON: Maschinenlesbare Rohdaten
/// - TXT: Einfacher Fließtext
library;

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class RechercheExporter {
  /// Exportiert Recherche-Daten in verschiedenen Formaten (Mobile: Log only)
  static void exportResearch({
    required BuildContext context,
    required Map<String, dynamic> data,
    required String query,
    required String format,
  }) {
    try {
      final timestamp = DateTime.now().toIso8601String().split('.')[0].replaceAll(':', '-');
      final filename = 'recherche_${query.replaceAll(' ', '_')}_$timestamp';

      // 📱 Android: Log export request (can be extended with file_picker/share plugins)
      if (kDebugMode) {
        debugPrint('📱 [Android] Export requested: $filename.$format');
        debugPrint('📱 [Android] Data: ${json.encode(data)}');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📱 Export auf Mobile noch nicht verfügbar'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Export error: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export fehlgeschlagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
