// VoiceMemoService — Upload eines aufgenommenen Voice-Memo zu R2 via
// Worker (E1).
//
// Recording-Aufnahme selbst läuft via record-package im UI; dieser
// Service kümmert sich nur um den Upload + die finale Public-URL.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class VoiceMemoUploadResult {
  final bool ok;
  final String? url;
  final String? error;
  const VoiceMemoUploadResult({required this.ok, this.url, this.error});
}

class VoiceMemoService {
  VoiceMemoService._();
  static final instance = VoiceMemoService._();

  /// Erwartet Audio-Bytes (AAC/M4A/Opus — der Worker akzeptiert beliebige
  /// audio/* MIME-Types).
  Future<VoiceMemoUploadResult> upload({
    required Uint8List bytes,
    required String mimeType,
    required String userId,
    int? durationSec,
  }) async {
    if (bytes.isEmpty) {
      return const VoiceMemoUploadResult(ok: false, error: 'leere Datei');
    }
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      return const VoiceMemoUploadResult(ok: false, error: 'zu groß (>5 MB)');
    }
    try {
      final req = http.MultipartRequest(
        'POST',
        // Reuse existing /api/chat/voice-upload endpoint (R2-Upload).
        Uri.parse('${ApiConfig.workerUrl}/api/chat/voice-upload'),
      );
      req.fields['userId'] = userId;
      if (durationSec != null) {
        req.fields['durationSec'] = durationSec.toString();
      }
      req.fields['mimeType'] = mimeType;
      req.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: 'memo-${DateTime.now().millisecondsSinceEpoch}',
      ));
      final streamed = await req.send().timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode != 200) {
        return VoiceMemoUploadResult(ok: false, error: 'HTTP ${res.statusCode}');
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final url = body['url'] as String?;
      if (url == null) {
        return const VoiceMemoUploadResult(ok: false, error: 'Keine URL zurück');
      }
      return VoiceMemoUploadResult(ok: true, url: url);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ VoiceMemo upload: $e');
      return VoiceMemoUploadResult(ok: false, error: e.toString());
    }
  }
}
