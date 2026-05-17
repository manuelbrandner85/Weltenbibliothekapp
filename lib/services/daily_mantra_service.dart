// DailyMantraService — Tages-Mantra/Zitat (F1).
//
// Lädt einmal pro Tag ein zufälliges Mantra aus daily_mantras (gewichtet
// nach weight). Lokaler Cache pro Tag — kein Tausch bei mehrfachem
// Aufruf am gleichen Tag.

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Mantra {
  final String text;
  final String? author;
  final String? tradition;
  const Mantra({required this.text, this.author, this.tradition});

  Map<String, dynamic> toJson() =>
      {'text': text, 'author': author, 'tradition': tradition};
  factory Mantra.fromJson(Map<String, dynamic> j) => Mantra(
        text: j['text'] as String? ?? '',
        author: j['author'] as String?,
        tradition: j['tradition'] as String?,
      );
}

class DailyMantraService {
  DailyMantraService._();
  static final instance = DailyMantraService._();

  Future<Mantra?> today() async {
    final dateKey = _todayKey();
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('mantra_$dateKey');
      if (cached != null) {
        return Mantra.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      }

      final res = await Supabase.instance.client
          .from('daily_mantras')
          .select('text_de,author,tradition,weight')
          .limit(200);
      final list = (res as List).cast<Map<String, dynamic>>();
      if (list.isEmpty) return null;

      // Gewichtetes Pick mit Tagestid als Seed → deterministisch.
      final seed = int.parse(dateKey.replaceAll('-', ''));
      final rnd = Random(seed);
      final weighted = <Mantra>[];
      for (final m in list) {
        final w = (m['weight'] as int?) ?? 1;
        for (var i = 0; i < w; i++) {
          weighted.add(Mantra(
            text: m['text_de'] as String? ?? '',
            author: m['author'] as String?,
            tradition: m['tradition'] as String?,
          ));
        }
      }
      final pick = weighted[rnd.nextInt(weighted.length)];

      await prefs.setString('mantra_$dateKey', jsonEncode(pick.toJson()));
      return pick;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ DailyMantra: $e');
      return null;
    }
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }
}
