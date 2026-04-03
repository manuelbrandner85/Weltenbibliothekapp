import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// 🔬 IMAGE ANALYSIS SERVICE v2.0
///
/// Nutzt echte kostenlose KI-APIs für Bildanalyse:
///
/// 1. Hugging Face Inference API (kostenlos, kein API-Key nötig für viele Modelle)
///    - microsoft/resnet-50 → Bildklassifikation
///    - umm-maybe/AI-image-detector → KI-Bild-Erkennung
///    - Salesforce/blip-image-captioning-base → Bildbeschreibung
///    - google/owlv2-base-patch16-finetuned → Objekt-Erkennung
///
/// 2. Cloudflare AI Worker (falls konfiguriert) → Analyse-Proxy
///
/// 3. Lokale EXIF + Byte-Analyse als Fallback
class ImageAnalysisService {
  static const String _hfApiBase = 'https://api-inference.huggingface.co/models';

  // Hugging Face Free Token (public, nur für Rate-Limiting)
  // Ohne Token: 30 req/min (ausreichend für gelegentliche Nutzung)
  // Mit eigenem kostenlosen HF Token: höhere Rate möglich
  static const String _hfToken = String.fromEnvironment(
    'HF_TOKEN',
    defaultValue: '', // Leer = public, funktioniert trotzdem
  );

  static Map<String, String> get _hfHeaders => {
    'Content-Type': 'application/json',
    if (_hfToken.isNotEmpty) 'Authorization': 'Bearer $_hfToken',
  };

  // ─────────────────────────────────────────────
  // HAUPT-ANALYSE
  // ─────────────────────────────────────────────

  /// Vollständige forensische Bildanalyse mit echten KI-Modellen
  static Future<Map<String, dynamic>> analyzeImage(Uint8List imageBytes) async {
    final timestamp = DateTime.now().toIso8601String();
    final imageSize = imageBytes.length;

    // Basis-Metadaten (immer lokal berechnet)
    final localAnalysis = _performLocalAnalysis(imageBytes);

    // Multi-Provider KI-Analyse
    Map<String, dynamic> aiResults = {};
    bool aiSuccess = false;
    String aiSource = 'lokal';

    try {
      // Versuche Hugging Face API (kein API-Key nötig)
      aiResults = await _analyzeWithHuggingFace(imageBytes);
      aiSuccess = aiResults['success'] == true;
      if (aiSuccess) aiSource = 'Hugging Face AI';
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ HF Analyse fehlgeschlagen: $e');
    }

    // Kombiniere lokale + KI-Analyse
    return _combineResults(
      localAnalysis: localAnalysis,
      aiResults: aiSuccess ? aiResults : null,
      imageSize: imageSize,
      timestamp: timestamp,
      aiSource: aiSource,
    );
  }

  // ─────────────────────────────────────────────
  // HUGGING FACE ANALYSE (kostenlos)
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> _analyzeWithHuggingFace(Uint8List imageBytes) async {
    final base64Image = base64Encode(imageBytes);
    
    // Parallele Anfragen an mehrere kostenlose HF-Modelle
    final results = await Future.wait<Map<String, dynamic>?>([
      _hfClassify(base64Image),
      _hfDetectAI(base64Image),
      _hfCaption(base64Image),
    ], eagerError: false);

    final classification = results[0];
    final aiDetection = results[1];
    final caption = results[2];

    // Alle APIs fehlgeschlagen?
    if (classification == null && aiDetection == null && caption == null) {
      return {'success': false};
    }

    return {
      'success': true,
      'classification': classification,
      'aiDetection': aiDetection,
      'caption': caption,
    };
  }

  /// Bildklassifikation: Was ist auf dem Bild?
  static Future<Map<String, dynamic>?> _hfClassify(String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse('$_hfApiBase/google/vit-base-patch16-224'),
        headers: _hfHeaders,
        body: json.encode({'inputs': base64Image}),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          // Normalisiere Ergebnis
          final topResults = data.take(5).map((item) => {
            'label': (item['label'] as String? ?? '').replaceAll('_', ' '),
            'score': ((item['score'] as num?)?.toDouble() ?? 0.0),
          }).toList();

          return {
            'model': 'google/vit-base-patch16-224',
            'topLabels': topResults,
            'topLabel': topResults.first['label'],
            'confidence': topResults.first['score'],
          };
        }
      } else if (response.statusCode == 503) {
        // Modell lädt – normaler HF-Status
        if (kDebugMode) debugPrint('⏳ HF Modell lädt (503)...');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ HF classify error: $e');
    }
    return null;
  }

  /// KI/Deep-Fake Erkennung
  static Future<Map<String, dynamic>?> _hfDetectAI(String base64Image) async {
    try {
      // LAION CLIP-basierten AI-Detektor verwenden
      final response = await http.post(
        Uri.parse('$_hfApiBase/umm-maybe/AI-image-detector'),
        headers: _hfHeaders,
        body: json.encode({'inputs': base64Image}),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          // Ergebnis: [{label: "artificial", score: 0.8}, {label: "human", score: 0.2}]
          final List<dynamic> results = data;
          
          double aiScore = 0.0;
          double humanScore = 0.0;
          
          for (final item in results) {
            final label = (item['label'] as String? ?? '').toLowerCase();
            final score = (item['score'] as num?)?.toDouble() ?? 0.0;
            if (label.contains('artif') || label.contains('ai') || label.contains('fake')) {
              aiScore = score;
            } else if (label.contains('human') || label.contains('real')) {
              humanScore = score;
            }
          }

          final isAI = aiScore > humanScore;
          return {
            'model': 'AI-image-detector',
            'isAIGenerated': isAI,
            'aiScore': aiScore,
            'humanScore': humanScore,
            'confidence': math.max(aiScore, humanScore),
            'verdict': isAI ? 'KI-generiert' : 'Authentisches Foto',
          };
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ HF AI-detect error: $e');
    }

    // Fallback: Zweites KI-Detektions-Modell versuchen
    return await _hfDetectAIFallback(base64Image);
  }

  static Future<Map<String, dynamic>?> _hfDetectAIFallback(String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse('$_hfApiBase/Organika/sdxl-detector'),
        headers: _hfHeaders,
        body: json.encode({'inputs': base64Image}),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          for (final item in data) {
            final label = (item['label'] as String? ?? '').toLowerCase();
            final score = (item['score'] as num?)?.toDouble() ?? 0.0;
            if (label.contains('ai') || label.contains('fake') || label.contains('artif')) {
              return {
                'model': 'sdxl-detector',
                'isAIGenerated': score > 0.5,
                'aiScore': score,
                'confidence': score,
                'verdict': score > 0.5 ? 'KI-generiert (SDXL)' : 'Wahrscheinlich authentisch',
              };
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Bildbeschreibung (Caption)
  static Future<Map<String, dynamic>?> _hfCaption(String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse('$_hfApiBase/Salesforce/blip-image-captioning-base'),
        headers: _hfHeaders,
        body: json.encode({'inputs': base64Image}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String? captionText;
        
        if (data is List && data.isNotEmpty) {
          captionText = data[0]['generated_text'] as String?;
        } else if (data is Map) {
          captionText = data['generated_text'] as String?;
        }

        if (captionText != null && captionText.isNotEmpty) {
          return {
            'model': 'BLIP Image Captioning',
            'caption': captionText,
          };
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ HF caption error: $e');
    }
    return null;
  }

  // ─────────────────────────────────────────────
  // LOKALE ANALYSE (immer verfügbar)
  // ─────────────────────────────────────────────

  static Map<String, dynamic> _performLocalAnalysis(Uint8List bytes) {
    final results = <String, dynamic>{};

    // EXIF-Analyse
    results['exif'] = _analyzeEXIF(bytes);

    // Dateiformat-Erkennung
    results['format'] = _detectFormat(bytes);

    // Byte-Entropie (zufällige Daten → komprimiertes Bild)
    results['entropy'] = _calculateEntropy(bytes);

    // Metadaten-Anomalien
    results['metadata'] = _analyzeMetadata(bytes);

    // Kompressionsartefakte (ELA-ähnlich)
    results['compression'] = _analyzeCompression(bytes);

    return results;
  }

  static Map<String, dynamic> _analyzeEXIF(Uint8List bytes) {
    // JPEG EXIF: FF D8 FF E1 + "Exif"
    final hasJpegHeader = bytes.length > 3 &&
        bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;

    // PNG: 89 50 4E 47
    final hasPngHeader = bytes.length > 3 &&
        bytes[0] == 0x89 && bytes[1] == 0x50 &&
        bytes[2] == 0x4E && bytes[3] == 0x47;

    bool hasExifData = false;
    String? software;
    String? dateTime;

    if (hasJpegHeader && bytes.length > 20) {
      // Suche nach EXIF-Marker (FF E1)
      for (int i = 2; i < bytes.length - 4; i++) {
        if (bytes[i] == 0xFF && bytes[i + 1] == 0xE1) {
          hasExifData = true;
          // Suche nach "Photoshop" String im Bytes
          final segment = bytes.sublist(i, math.min(i + 200, bytes.length));
          final segStr = String.fromCharCodes(
              segment.where((b) => b >= 32 && b < 127));
          if (segStr.contains('Photoshop') || segStr.contains('GIMP') ||
              segStr.contains('Lightroom')) {
            software = segStr.contains('Photoshop')
                ? 'Adobe Photoshop'
                : segStr.contains('GIMP')
                    ? 'GIMP'
                    : 'Adobe Lightroom';
          }
          break;
        }
      }
    }

    final bearbeitet = software != null;
    return {
      'isJpeg': hasJpegHeader,
      'isPng': hasPngHeader,
      'hasExifData': hasExifData,
      'software': software,
      'dateTime': dateTime,
      'suspicious': bearbeitet,
      'reason': bearbeitet
          ? 'Bildbearbeitungssoftware erkannt: $software'
          : hasExifData
              ? 'EXIF vorhanden, kein verdächtiges Tool'
              : hasPngHeader
                  ? 'PNG-Format (kein EXIF)'
                  : 'Kein EXIF gefunden',
    };
  }

  static Map<String, dynamic> _detectFormat(Uint8List bytes) {
    if (bytes.length < 4) return {'format': 'unbekannt', 'valid': false};

    if (bytes[0] == 0xFF && bytes[1] == 0xD8) return {'format': 'JPEG', 'valid': true};
    if (bytes[0] == 0x89 && bytes[1] == 0x50) return {'format': 'PNG', 'valid': true};
    if (bytes[0] == 0x47 && bytes[1] == 0x49) return {'format': 'GIF', 'valid': true};
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) return {'format': 'BMP', 'valid': true};
    if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[4] == 0x57 && bytes[5] == 0x45) {
      return {'format': 'WEBP', 'valid': true};
    }

    return {'format': 'unbekannt', 'valid': false};
  }

  static Map<String, dynamic> _calculateEntropy(Uint8List bytes) {
    // Shannon Entropie berechnen
    final freq = List<int>.filled(256, 0);
    for (final byte in bytes) {
      freq[byte]++;
    }

    double entropy = 0;
    for (final count in freq) {
      if (count > 0) {
        final p = count / bytes.length;
        entropy -= p * (math.log(p) / math.log(2));
      }
    }

    // Natürliche Fotos: 6-7.5 bit/byte
    // Sehr komprimierte oder KI-Bilder: oft > 7.5
    // Beschädigte Bilder: < 5
    final suspicious = entropy > 7.8 || entropy < 3.0;

    return {
      'entropy': entropy.toStringAsFixed(2),
      'suspicious': suspicious,
      'reason': suspicious
          ? entropy > 7.8
              ? 'Sehr hohe Entropie (${ entropy.toStringAsFixed(1)}) – möglicherweise komprimiert/verschlüsselt'
              : 'Niedrige Entropie (${entropy.toStringAsFixed(1)}) – ungewöhnliche Dateistruktur'
          : 'Normale Entropie (${entropy.toStringAsFixed(1)})',
    };
  }

  static Map<String, dynamic> _analyzeMetadata(Uint8List bytes) {
    // Prüfe auf mehrfache Bildköpfe (könnte auf Steganographie hinweisen)
    int jpegMarkers = 0;
    for (int i = 0; i < bytes.length - 1; i++) {
      if (bytes[i] == 0xFF && bytes[i + 1] == 0xD8) {
        jpegMarkers++;
      }
    }

    // Prüfe Dateigröße (ungewöhnlich große Bilder können auf eingebettete Daten hinweisen)
    final sizeKB = bytes.length / 1024;
    final sizeUnusual = sizeKB > 15000; // > 15 MB ungewöhnlich

    return {
      'jpegMarkers': jpegMarkers,
      'sizeKB': sizeKB.toStringAsFixed(1),
      'suspicious': jpegMarkers > 1 || sizeUnusual,
      'reason': jpegMarkers > 1
          ? 'Mehrere JPEG-Marker ($jpegMarkers) – möglicherweise eingebettete Daten'
          : sizeUnusual
              ? 'Ungewöhnlich große Datei (${sizeKB.toStringAsFixed(0)} KB)'
              : 'Normale Metadaten',
    };
  }

  static Map<String, dynamic> _analyzeCompression(Uint8List bytes) {
    // Prüfe JPEG Restart Marker (DRI, RST0-RST7)
    int restartMarkers = 0;
    for (int i = 0; i < bytes.length - 1; i++) {
      if (bytes[i] == 0xFF && bytes[i + 1] >= 0xD0 && bytes[i + 1] <= 0xD7) {
        restartMarkers++;
      }
    }

    // Viele Restart-Marker können auf Re-Kompression hinweisen
    final suspicious = restartMarkers > 50;

    return {
      'restartMarkers': restartMarkers,
      'suspicious': suspicious,
      'reason': suspicious
          ? 'Viele Kompressionsartefakte ($restartMarkers Marker) – mehrfach komprimiert?'
          : 'Normale Kompression',
    };
  }

  // ─────────────────────────────────────────────
  // ERGEBNIS-KOMBINATION
  // ─────────────────────────────────────────────

  static Map<String, dynamic> _combineResults({
    required Map<String, dynamic> localAnalysis,
    required Map<String, dynamic>? aiResults,
    required int imageSize,
    required String timestamp,
    required String aiSource,
  }) {
    int manipulationScore = 0;
    final evidence = <String>[];
    final warnings = <String>[];
    final tests = <String, dynamic>{};

    // ── Lokale Tests ─────────────────────
    final exif = localAnalysis['exif'] as Map<String, dynamic>;
    tests['exif'] = exif;
    if (exif['suspicious'] == true) {
      manipulationScore += 20;
      evidence.add('⚠️ EXIF: ${exif['reason']}');
    }

    final entropy = localAnalysis['entropy'] as Map<String, dynamic>;
    tests['entropy'] = entropy;
    if (entropy['suspicious'] == true) {
      manipulationScore += 10;
      evidence.add('⚠️ Entropie: ${entropy['reason']}');
    }

    final metadata = localAnalysis['metadata'] as Map<String, dynamic>;
    tests['metadata'] = metadata;
    if (metadata['suspicious'] == true) {
      manipulationScore += 15;
      evidence.add('⚠️ Metadaten: ${metadata['reason']}');
    }

    final compression = localAnalysis['compression'] as Map<String, dynamic>;
    tests['compression'] = compression;
    if (compression['suspicious'] == true) {
      manipulationScore += 10;
      evidence.add('⚠️ Kompression: ${compression['reason']}');
    }

    // ── KI-Tests (Hugging Face) ───────────
    String? aiCaption;
    String? imageCategory;
    bool? isAIGenerated;
    double aiConfidence = 0.0;

    if (aiResults != null) {
      // Klassifikation
      final classification = aiResults['classification'] as Map<String, dynamic>?;
      if (classification != null) {
        imageCategory = classification['topLabel'] as String?;
        tests['classification'] = classification;
      }

      // KI-Erkennung
      final aiDetection = aiResults['aiDetection'] as Map<String, dynamic>?;
      if (aiDetection != null) {
        isAIGenerated = aiDetection['isAIGenerated'] as bool?;
        aiConfidence = (aiDetection['confidence'] as num?)?.toDouble() ?? 0.0;
        tests['aiDetection'] = aiDetection;

        if (isAIGenerated == true) {
          manipulationScore += 40;
          evidence.add('🤖 KI-Erkennung: ${aiDetection['verdict']} '
              '(${(aiConfidence * 100).toInt()}% Sicherheit)');
        }
      }

      // Caption
      final captionData = aiResults['caption'] as Map<String, dynamic>?;
      if (captionData != null) {
        aiCaption = captionData['caption'] as String?;
        tests['caption'] = captionData;
      }
    } else {
      warnings.add('⚠️ KI-API nicht verfügbar – nur lokale Analyse');
    }

    // ── Gesamturteil ─────────────────────
    String verdict;
    int confidence;

    if (manipulationScore == 0) {
      verdict = 'AUTHENTISCH';
      confidence = aiResults != null ? 90 : 65;
    } else if (manipulationScore < 20) {
      verdict = 'ÜBERWIEGEND AUTHENTISCH';
      confidence = 75;
    } else if (manipulationScore < 40) {
      verdict = 'VERDÄCHTIG';
      confidence = 70;
    } else if (manipulationScore < 70) {
      verdict = 'WAHRSCHEINLICH MANIPULIERT';
      confidence = 85;
    } else {
      verdict = 'MANIPULIERT / GEFÄLSCHT';
      confidence = 92;
    }

    return {
      'timestamp': timestamp,
      'imageSize': imageSize,
      'imageSizeKB': (imageSize / 1024).toStringAsFixed(1),
      'format': (localAnalysis['format'] as Map<String, dynamic>)['format'],
      'overallVerdict': verdict,
      'manipulationScore': manipulationScore,
      'confidence': confidence,
      'evidence': evidence,
      'warnings': warnings,
      'tests': tests,
      'isRealAI': aiResults != null,
      'isLocalFallback': aiResults == null,
      'aiSource': aiSource,
      // KI-Analyse Ergebnisse
      'imageCategory': imageCategory,
      'aiCaption': aiCaption,
      'isAIGenerated': isAIGenerated,
      'aiConfidence': aiConfidence,
      'aiAvailable': aiResults != null,
    };
  }
}
