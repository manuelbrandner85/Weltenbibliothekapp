// GatewayRecordingService — eigene Session-Notizen für Gateway-Room (J3).
//
// Bleibt rein lokal (SharedPrefs) — Gateway-Sessions sind privat.
// Audio-Recording über das record-Package läuft im UI; dieser Service
// speichert nur die Metadaten (Title, Tags, Dauer, Notizen) und einen
// optionalen lokalen File-Path.

import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

class GatewaySession {
  final String id;
  final DateTime date;
  final String title;
  final int durationSec;
  final List<String> tags;
  final String? notes;
  final String? localFilePath;
  const GatewaySession({
    required this.id,
    required this.date,
    required this.title,
    required this.durationSec,
    required this.tags,
    required this.notes,
    required this.localFilePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'title': title,
        'durationSec': durationSec,
        'tags': tags,
        'notes': notes,
        'localFilePath': localFilePath,
      };
  factory GatewaySession.fromJson(Map<String, dynamic> j) => GatewaySession(
        id: j['id'] as String? ?? '',
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        title: j['title'] as String? ?? '',
        durationSec: (j['durationSec'] as int?) ?? 0,
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        notes: j['notes'] as String?,
        localFilePath: j['localFilePath'] as String?,
      );
}

class GatewayRecordingService {
  GatewayRecordingService._();
  static final instance = GatewayRecordingService._();

  static const _key = 'gateway_sessions';

  Future<List<GatewaySession>> list() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return const [];
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => GatewaySession.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Gateway list: $e');
      return const [];
    }
  }

  Future<bool> save(GatewaySession s) async {
    try {
      final existing = await list();
      final updated = existing.where((e) => e.id != s.id).toList();
      updated.insert(0, s);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(updated.map((e) => e.toJson()).toList()),
      );
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Gateway save: $e');
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      final existing = await list();
      final filtered = existing.where((e) => e.id != id).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(filtered.map((e) => e.toJson()).toList()),
      );
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Gateway delete: $e');
      return false;
    }
  }
}
