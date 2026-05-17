// CrystalVisionService — Kristall-Erkennung via Worker AI Vision (H4).

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class CrystalIdentification {
  final String name;
  final double confidence;
  final List<String> properties;
  const CrystalIdentification({
    required this.name,
    required this.confidence,
    required this.properties,
  });
}

class CrystalVisionService {
  CrystalVisionService._();
  static final instance = CrystalVisionService._();

  /// Erwartet JPEG/PNG-Bytes. Limit: 4 MB.
  Future<CrystalIdentification?> identify(Uint8List imageBytes) async {
    if (imageBytes.lengthInBytes > 4 * 1024 * 1024) {
      if (kDebugMode) debugPrint('⚠️ Crystal-Vision: Bild zu groß');
      return null;
    }
    try {
      final b64 = base64Encode(imageBytes);
      final res = await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/crystal/identify'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'imageBase64': b64}),
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return CrystalIdentification(
        name: body['name'] as String? ?? 'Unbekannt',
        confidence: (body['confidence'] as num?)?.toDouble() ?? 0,
        properties: (body['properties'] as List?)?.cast<String>() ?? const [],
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Crystal identify: $e');
      return null;
    }
  }
}
