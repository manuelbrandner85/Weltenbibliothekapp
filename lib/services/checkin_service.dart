import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/checkin.dart';

/// Service für Check-Ins an Orten (Marker)
class CheckInService {
  static final CheckInService _instance = CheckInService._internal();
  factory CheckInService() => _instance;
  CheckInService._internal();

  static const String _keyCheckIns = 'location_checkins';
  
  final List<CheckIn> _checkIns = [];
  
  // Stream für UI-Updates
  final StreamController<List<CheckIn>> _checkInsController = 
      StreamController<List<CheckIn>>.broadcast();
  
  Stream<List<CheckIn>> get checkInsStream => _checkInsController.stream;

  /// Initialisierung
  Future<void> init() async {
    await _loadCheckIns();
  }

  Future<void> _loadCheckIns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final checkInsJson = prefs.getStringList(_keyCheckIns) ?? [];
      
      _checkIns.clear();
      for (final json in checkInsJson) {
        try {
          final parts = json.split('|');
          if (parts.length >= 5) {
            _checkIns.add(CheckIn(
              id: parts[0],
              locationId: parts[1],
              locationName: parts[2],
              category: parts[3],
              timestamp: DateTime.parse(parts[4]),
              notes: parts.length > 5 ? parts[5] : null,
              worldType: parts.length > 6 ? parts[6] : 'energie',
            ));
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Fehler beim Parsen von Check-In: $e');
          }
        }
      }
      
      if (kDebugMode) {
        debugPrint('📍 Check-Ins geladen: ${_checkIns.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Fehler beim Laden der Check-Ins: $e');
      }
    }
  }

  /// Check-In erstellen
  Future<void> checkIn({
    required String locationId,
    required String locationName,
    required String category,
    required String worldType,
    String? notes,
  }) async {
    // Prüfen ob bereits eingecheckt
    if (hasVisited(locationId)) {
      if (kDebugMode) {
        debugPrint('📍 Bereits eingecheckt: $locationName');
      }
      return;
    }

    final checkIn = CheckIn(
      id: '${locationId}_${DateTime.now().millisecondsSinceEpoch}',
      locationId: locationId,
      locationName: locationName,
      category: category,
      timestamp: DateTime.now(),
      notes: notes,
      worldType: worldType,
    );

    _checkIns.add(checkIn);
    await _saveCheckIns();
    _checkInsController.add(_checkIns);
    
    if (kDebugMode) {
      debugPrint('✅ Check-In erstellt: $locationName');
    }
  }

  /// Alle Check-Ins abrufen
  List<CheckIn> getCheckIns({String? worldType, String? category}) {
    var filtered = _checkIns;
    
    if (worldType != null) {
      filtered = filtered.where((c) => c.worldType == worldType).toList();
    }
    
    if (category != null) {
      filtered = filtered.where((c) => c.category == category).toList();
    }
    
    // Sortieren nach neuesten
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return filtered;
  }

  /// Prüfen ob Ort bereits besucht wurde
  bool hasVisited(String locationId) {
    return _checkIns.any((c) => c.locationId == locationId);
  }

  /// Anzahl besuchter Orte
  int getVisitedCount({String? worldType, String? category}) {
    return getCheckIns(worldType: worldType, category: category).length;
  }

  /// Anzahl besuchter Orte pro Kategorie
  Map<String, int> getCategoryCounts({String? worldType}) {
    final checkIns = getCheckIns(worldType: worldType);
    final counts = <String, int>{};
    
    for (final checkIn in checkIns) {
      counts[checkIn.category] = (counts[checkIn.category] ?? 0) + 1;
    }
    
    return counts;
  }

  /// Check-In für einen Ort abrufen
  CheckIn? getCheckIn(String locationId) {
    try {
      return _checkIns.firstWhere((c) => c.locationId == locationId);
    } catch (e) {
      return null;
    }
  }

  /// Check-In löschen
  Future<void> deleteCheckIn(String locationId) async {
    _checkIns.removeWhere((c) => c.locationId == locationId);
    await _saveCheckIns();
    _checkInsController.add(_checkIns);
    
    if (kDebugMode) {
      debugPrint('🗑️ Check-In gelöscht: $locationId');
    }
  }

  /// Speichern
  Future<void> _saveCheckIns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final checkInsJson = _checkIns.map((c) {
        return '${c.id}|${c.locationId}|${c.locationName}|${c.category}|'
               '${c.timestamp.toIso8601String()}|${c.notes ?? ''}|${c.worldType}';
      }).toList();
      
      await prefs.setStringList(_keyCheckIns, checkInsJson);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Fehler beim Speichern der Check-Ins: $e');
      }
    }
  }

  /// Alle Check-Ins löschen
  Future<void> clearAll() async {
    _checkIns.clear();
    await _saveCheckIns();
    _checkInsController.add(_checkIns);
  }
}
