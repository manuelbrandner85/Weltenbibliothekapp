// ShadowJournalService — privates Schatten-Journal mit lokaler Verschlüsselung (I4).
//
// Speichert AUSSCHLIESSLICH lokal in SQLite/SharedPrefs. Body wird mit
// XOR-Obfuskation gegen einen pro-Device-Schlüssel verschleiert — kein
// militärischer Schutz, aber Schutz gegen Casual-Lookup im File-System.
// Echte AES-Verschlüsselung wäre via `encrypt`-Package möglich (kommt
// als Follow-up wenn das Paket im pubspec ergänzt wird).

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

class ShadowEntry {
  final String id;
  final DateTime date;
  final String title;
  final String body;
  final List<String> tags;
  const ShadowEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.body,
    required this.tags,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'title': title,
        'body': body,
        'tags': tags,
      };
  factory ShadowEntry.fromJson(Map<String, dynamic> j) => ShadowEntry(
        id: j['id'] as String? ?? '',
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
      );
}

class ShadowJournalService {
  ShadowJournalService._();
  static final instance = ShadowJournalService._();

  static const _listKey = 'shadow_journal_entries';
  static const _keyKey = 'shadow_journal_key';

  Future<List<int>> _key() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyKey);
    if (raw != null && raw.isNotEmpty) return base64Decode(raw);
    // Erzeuge per-device Schlüssel (32 random bytes).
    final r = Random.secure();
    final bytes = List<int>.generate(32, (_) => r.nextInt(256));
    await prefs.setString(_keyKey, base64Encode(bytes));
    return bytes;
  }

  String _xorTransform(String text, List<int> key) {
    final input = utf8.encode(text);
    final out = Uint8List(input.length);
    for (var i = 0; i < input.length; i++) {
      out[i] = input[i] ^ key[i % key.length];
    }
    return base64Encode(out);
  }

  String _xorReverse(String b64, List<int> key) {
    final bytes = base64Decode(b64);
    final out = Uint8List(bytes.length);
    for (var i = 0; i < bytes.length; i++) {
      out[i] = bytes[i] ^ key[i % key.length];
    }
    return utf8.decode(out);
  }

  Future<List<ShadowEntry>> list() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_listKey) ?? const [];
      final key = await _key();
      return raw
          .map((enc) {
            try {
              final decrypted = _xorReverse(enc, key);
              return ShadowEntry.fromJson(
                  jsonDecode(decrypted) as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<ShadowEntry>()
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ ShadowJournal list: $e');
      return const [];
    }
  }

  Future<bool> save(ShadowEntry entry) async {
    try {
      final existing = await list();
      final updated = existing.where((e) => e.id != entry.id).toList();
      updated.insert(0, entry);
      final key = await _key();
      final raw = updated
          .map((e) => _xorTransform(jsonEncode(e.toJson()), key))
          .toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_listKey, raw);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ ShadowJournal save: $e');
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      final existing = await list();
      final filtered = existing.where((e) => e.id != id).toList();
      final key = await _key();
      final raw = filtered
          .map((e) => _xorTransform(jsonEncode(e.toJson()), key))
          .toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_listKey, raw);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ ShadowJournal delete: $e');
      return false;
    }
  }
}
