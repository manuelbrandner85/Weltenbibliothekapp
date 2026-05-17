// SpiritAIService — Combo-Synthese + TTS via Worker (G2 + G3).

import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class SpiritAIService {
  SpiritAIService._();
  static final instance = SpiritAIService._();

  /// G2: nimmt eine Liste von Tool-Ergebnissen (jeweils tool + summary) und
  /// fordert vom Worker eine kurze Gesamtsynthese.
  Future<String?> synthesize(List<({String tool, String summary})> readings) async {
    if (readings.isEmpty) return null;
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/spirit/synthesize'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'readings': readings
                  .map((r) => {'tool': r.tool, 'summary': r.summary})
                  .toList(),
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['synthesis'] as String?;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Spirit synthesize: $e');
      return null;
    }
  }

  /// G3: lässt den Worker TTS generieren und gibt die Audio-URL zurück.
  /// MVP — Worker entscheidet ob Workers AI TTS oder ein anderes Backend.
  Future<String?> tts(String text, {String voice = 'de-DE'}) async {
    if (text.trim().isEmpty) return null;
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/spirit/tts'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text, 'voice': voice}),
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['audioUrl'] as String?;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Spirit tts: $e');
      return null;
    }
  }
}
