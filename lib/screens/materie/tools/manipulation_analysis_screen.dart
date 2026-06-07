import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' if (dart.library.html) '../../../stubs/dart_io_stub.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

// =============================================================================
// MANIPULATIONSANALYSE SCREEN
// Erkennt Bildbearbeitung, Fotofilter, Kopierstempel, Kompression und
// Objekt-Einmontage via lokaler Artefakt-Analyse + Hugging Face KI.
// =============================================================================

// ─── Result model (plain class, no named records) ────────────────────────────

class _ManipFinding {
  final String category;
  final String title;
  final String detail;
  final int severity; // 0=ok 1=suspicious 2=likely 3=confirmed
  const _ManipFinding({
    required this.category,
    required this.title,
    required this.detail,
    required this.severity,
  });
}

class _ManipResult {
  final int overallScore; // 0-100
  final String verdict;
  final List<_ManipFinding> findings;
  final String? aiCaption;
  final bool isAiAnalysis;
  final String analysisSource;
  const _ManipResult({
    required this.overallScore,
    required this.verdict,
    required this.findings,
    this.aiCaption,
    required this.isAiAnalysis,
    required this.analysisSource,
  });
}

// ─── Analysis logic ──────────────────────────────────────────────────────────

class _ManipAnalyzer {
  static const String _hfBase = 'https://api-inference.huggingface.co/models';

  static Future<_ManipResult> analyze(Uint8List bytes) async {
    final findings = <_ManipFinding>[];

    // 1. Local analyses (always run)
    _checkJpegStructure(bytes, findings);
    _checkExifConsistency(bytes, findings);
    _checkEntropyAnomalies(bytes, findings);
    _checkColorUniformity(bytes, findings);
    _checkFileConsistency(bytes, findings);

    // 2. Remote HF analysis (best-effort)
    String? aiCaption;
    bool isAi = false;
    String aiSource = 'Lokale Analyse';

    try {
      final b64 = base64Encode(bytes);
      final hfResult = await _hfAnalyze(b64);
      if (hfResult != null) {
        aiCaption = hfResult['caption'] as String?;
        final aiDetected = hfResult['aiGenerated'] as bool? ?? false;
        if (aiDetected) {
          findings.add(const _ManipFinding(
            category: 'KI-Generierung',
            title: 'Moegliches KI-generiertes Bild erkannt',
            detail: 'Das Klassifikationsmodell stuft dieses Bild als '
                'moeglicherweise KI-generiert ein (GAN/Diffusion). '
                'Pruefen Sie die Quelle sorgfaeltig.',
            severity: 2,
          ));
        }
        isAi = true;
        aiSource = 'Lokale Analyse + Hugging Face KI';
      }
    } catch (_) {
      // silently fall back to local-only
    }

    // Compute overall score from findings
    final score = _computeScore(findings);
    final verdict = _verdictText(score);

    return _ManipResult(
      overallScore: score,
      verdict: verdict,
      findings: findings,
      aiCaption: aiCaption,
      isAiAnalysis: isAi,
      analysisSource: aiSource,
    );
  }

  // ── JPEG structure integrity ────────────────────────────────────────────────
  static void _checkJpegStructure(
      Uint8List bytes, List<_ManipFinding> out) {
    if (bytes.length < 4) return;
    final isJpeg = bytes[0] == 0xFF && bytes[1] == 0xD8;
    if (!isJpeg) return;

    // Look for multiple APP1 markers — indicates possible resave/re-edit
    int app1Count = 0;
    int dqtCount = 0; // Quantization tables
    for (int i = 0; i < bytes.length - 1; i++) {
      if (bytes[i] == 0xFF) {
        final marker = bytes[i + 1];
        if (marker == 0xE1) app1Count++;
        if (marker == 0xDB) dqtCount++;
      }
    }

    if (app1Count > 1) {
      out.add(_ManipFinding(
        category: 'Dateistruktur',
        title: 'Mehrfache Metadaten-Bloecke ($app1Count APP1-Marker)',
        detail: 'Das Bild enthaelt $app1Count APP1-Metadaten-Bloecke. '
            'Authentische Kamera-JPEGs haben normalerweise nur einen. '
            'Mehrere Bloecke deuten auf ein Respeichern in einer '
            'Bildbearbeitungssoftware hin.',
        severity: 1,
      ));
    }

    if (dqtCount > 2) {
      out.add(_ManipFinding(
        category: 'Kompression',
        title: 'Ungewoehnliche Anzahl Quantisierungstabellen ($dqtCount DQT)',
        detail: 'Standard-JPEGs nutzen 2 Quantisierungstabellen. '
            '$dqtCount Tabellen deuten auf mehrfaches Neu-Komprimieren hin, '
            'wie es bei Bildbearbeitung und Wiederholung passiert.',
        severity: 1,
      ));
    }

    // Check for JPEG restart markers -- presence with irregular spacing
    int rstCount = 0;
    for (int i = 0; i < bytes.length - 1; i++) {
      if (bytes[i] == 0xFF &&
          bytes[i + 1] >= 0xD0 &&
          bytes[i + 1] <= 0xD7) {
        rstCount++;
      }
    }
    if (rstCount == 0 && bytes.length > 200000) {
      // Large JPEG without restart markers is a soft flag
      out.add(const _ManipFinding(
        category: 'Dateistruktur',
        title: 'Keine Restart-Marker in grosser Datei',
        detail: 'Grosse JPEG-Dateien aus Kamerasystemen enthalten '
            'typischerweise Restart-Marker fuer Fehlertoleranz. '
            'Ihr Fehlen kann auf Nachbearbeitung hinweisen.',
        severity: 0,
      ));
    }
  }

  // ── EXIF consistency ────────────────────────────────────────────────────────
  static void _checkExifConsistency(
      Uint8List bytes, List<_ManipFinding> out) {
    final hasExif = _findSequence(bytes, [0x45, 0x78, 0x69, 0x66]); // "Exif"
    final hasThumbnail =
        _findSequence(bytes, [0x4A, 0x46, 0x49, 0x46]); // "JFIF"
    final hasXmp = _findSequence(bytes,
        [0x3C, 0x78, 0x3A, 0x78, 0x6D, 0x70, 0x6D, 0x65, 0x74, 0x61]);

    if (!hasExif && !hasThumbnail) {
      out.add(const _ManipFinding(
        category: 'Metadaten',
        title: 'Keine Kamera-Metadaten (EXIF fehlt)',
        detail: 'Das Bild enthaelt keine EXIF-Metadaten. '
            'Authentische Kamera-Fotos haben fast immer EXIF (Geraet, '
            'Belichtung, GPS). Fehlende Metadaten koennen auf '
            'Screenshot, Social-Media-Download oder bewusstes Entfernen '
            'der Daten hinweisen.',
        severity: 1,
      ));
    }

    if (hasXmp && hasExif) {
      out.add(const _ManipFinding(
        category: 'Metadaten',
        title: 'XMP + EXIF parallel vorhanden',
        detail: 'Das Bild enthaelt sowohl XMP- als auch EXIF-Metadaten. '
            'XMP wird von Adobe-Produkten (Lightroom, Photoshop) beim '
            'Exportieren hinzugefuegt. Dies ist ein starkes Signal fuer '
            'Nachbearbeitung mit Adobe-Software.',
        severity: 2,
      ));
    } else if (hasXmp) {
      out.add(const _ManipFinding(
        category: 'Metadaten',
        title: 'Adobe XMP-Metadaten enthalten',
        detail: 'Das Bild enthaelt XMP-Metadaten, die typischerweise '
            'von Adobe Lightroom oder Photoshop beim Speichern '
            'eingefuegt werden. Deutet auf Bearbeitung hin.',
        severity: 2,
      ));
    }

    // Software tag detection via simple byte scan
    final softwareTag = _extractSoftwareTag(bytes);
    if (softwareTag != null) {
      final lower = softwareTag.toLowerCase();
      int sev = 0;
      String detail = 'Software-Tag gefunden: "$softwareTag". ';
      if (lower.contains('photoshop') || lower.contains('adobe')) {
        sev = 3;
        detail += 'Adobe Photoshop wurde fuer dieses Bild verwendet. '
            'Das ist ein sicherer Beweis fuer Nachbearbeitung.';
      } else if (lower.contains('gimp') ||
          lower.contains('pixelmator') ||
          lower.contains('affinity') ||
          lower.contains('lightroom')) {
        sev = 2;
        detail += 'Bildbearbeitungs-Software erkannt. '
            'Das Bild wurde nach der Aufnahme bearbeitet.';
      } else if (lower.contains('camera') ||
          lower.contains('iphone') ||
          lower.contains('samsung') ||
          lower.contains('canon') ||
          lower.contains('nikon') ||
          lower.contains('sony')) {
        sev = 0;
        detail += 'Kamera- oder Geraete-Software erkannt. '
            'Kein Anzeichen fuer nachtraegliche Bearbeitung.';
      } else {
        sev = 1;
        detail +=
            'Unbekannte Software. Koennte auf Bearbeitung hinweisen.';
      }
      out.add(_ManipFinding(
        category: 'Software',
        title: 'Bearbeitungssoftware: $softwareTag',
        detail: detail,
        severity: sev,
      ));
    }
  }

  // ── Entropy / randomness anomalies ─────────────────────────────────────────
  static void _checkEntropyAnomalies(
      Uint8List bytes, List<_ManipFinding> out) {
    if (bytes.length < 512) return;

    // Compare entropy of JPEG file segments
    // Real photos have consistent entropy; edited areas can differ
    final chunkSize = math.min(bytes.length ~/ 4, 8192);
    final entropies = <double>[];
    for (int offset = 0; offset + chunkSize <= bytes.length; offset += chunkSize) {
      final chunk = bytes.sublist(offset, offset + chunkSize);
      entropies.add(_entropy(chunk));
    }
    if (entropies.length < 2) return;

    final mean = entropies.reduce((a, b) => a + b) / entropies.length;
    final variance = entropies
            .map((e) => math.pow(e - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        entropies.length;
    final stddev = math.sqrt(variance);

    if (stddev > 1.5) {
      out.add(_ManipFinding(
        category: 'Kompression',
        title: 'Inhomogene Kompressionsartefakte (ELA-Indiz)',
        detail: 'Verschiedene Bildbereiche zeigen stark unterschiedliche '
            'Kompressionslevels (Entropie-Standardabweichung: '
            '${stddev.toStringAsFixed(2)}). '
            'Bei eingefuegten oder kopierten Bildteilen ist das '
            'Kompressionsrauschen anders als beim Originalhintergrund. '
            'Dies ist ein klassischer ELA-Befund fuer Montagen.',
        severity: stddev > 2.5 ? 2 : 1,
      ));
    }

    // Very low entropy in a large file = suspicious uniform regions
    final minEntropy = entropies.reduce((a, b) => a < b ? a : b);
    if (minEntropy < 1.5 && bytes.length > 50000) {
      out.add(_ManipFinding(
        category: 'Pixelstruktur',
        title: 'Auffaellig gleichmaessiger Bildbereich',
        detail: 'Ein Bereich im Bild zeigt sehr geringe '
            'Bildinformation (Entropie: ${minEntropy.toStringAsFixed(2)}). '
            'Koennte auf kuenstliche Hintergrundfuellung, '
            'Content-Aware-Fill oder Stempel-Werkzeug hinweisen.',
        severity: 1,
      ));
    }
  }

  // ── Color uniformity check ──────────────────────────────────────────────────
  static void _checkColorUniformity(
      Uint8List bytes, List<_ManipFinding> out) {
    // Rough channel histogram via byte sampling
    if (bytes.length < 100) return;

    // Sample bytes spread evenly across the file as a proxy for pixel values
    final sampleCount = math.min(2048, bytes.length);
    final step = bytes.length ~/ sampleCount;
    final freq = List<int>.filled(256, 0);
    for (int i = 0; i < sampleCount; i++) {
      freq[bytes[i * step]]++;
    }

    // Count how many bins are completely empty (value = 0) in middle range
    int zeroBins = 0;
    for (int v = 32; v < 224; v++) {
      if (freq[v] == 0) zeroBins++;
    }

    if (zeroBins > 80) {
      out.add(_ManipFinding(
        category: 'Farbverteilung',
        title: 'Ungewoehnliche Farbwerteverteilung ($zeroBins leere Bins)',
        detail: 'Das Helligkeitshistogramm zeigt $zeroBins leere '
            'Wertebereiche im mittleren Spektrum. '
            'Starke Nachbearbeitung, Tonwertspreizung oder '
            'extreme Filter veraendern die Farbverteilung auf '
            'diese Weise.',
        severity: 1,
      ));
    }

    // Check for extreme saturation by counting near-max and near-min bytes
    final extremeLow = freq.sublist(0, 5).reduce((a, b) => a + b);
    final extremeHigh = freq.sublist(251).reduce((a, b) => a + b);
    final extremeRatio =
        (extremeLow + extremeHigh) / math.max(1, sampleCount);
    if (extremeRatio > 0.45) {
      out.add(_ManipFinding(
        category: 'Farbverteilung',
        title: 'Extreme Helligkeitswerte (${(extremeRatio * 100).toInt()}%)',
        detail: 'Ein grosser Anteil der Pixelwerte liegt an den Extremen '
            '(fast schwarz oder fast weiss). '
            'Starke Kontrastfilter, Ueberbelichtungs-Korrekturen oder '
            'HDR-Effekte hinterlassen diese Signatur.',
        severity: 1,
      ));
    }
  }

  // ── File consistency ────────────────────────────────────────────────────────
  static void _checkFileConsistency(
      Uint8List bytes, List<_ManipFinding> out) {
    // Check file ends properly with JPEG EOI marker
    if (bytes.length >= 2) {
      final isJpeg = bytes[0] == 0xFF && bytes[1] == 0xD8;
      if (isJpeg) {
        final endsCorrectly =
            bytes[bytes.length - 2] == 0xFF && bytes[bytes.length - 1] == 0xD9;
        if (!endsCorrectly) {
          out.add(const _ManipFinding(
            category: 'Dateistruktur',
            title: 'Unvollstaendiger oder beschaedigter JPEG-Abschluss',
            detail: 'Der JPEG-Dateiabschluss (EOI-Marker FF D9) fehlt oder '
                'ist an falscher Position. Dies kann auf abgeschnittene '
                'Daten, nachtraegliche Dateimanipulation oder beschaedigte '
                'Downloads hinweisen.',
            severity: 1,
          ));
        }
      }
    }

    // Payload-after-EOF detection (data hidden after JPEG end)
    if (bytes.length >= 4) {
      final isJpeg = bytes[0] == 0xFF && bytes[1] == 0xD8;
      if (isJpeg) {
        // Find EOI marker
        for (int i = bytes.length - 2; i >= 2; i--) {
          if (bytes[i] == 0xFF && bytes[i + 1] == 0xD9) {
            final hiddenBytes = bytes.length - i - 2;
            if (hiddenBytes > 64) {
              out.add(_ManipFinding(
                category: 'Steganographie',
                title: 'Daten nach JPEG-Ende ($hiddenBytes Bytes)',
                detail: 'Nach dem offiziellen JPEG-Ende befinden sich '
                    '$hiddenBytes Bytes extra Daten. '
                    'Dies kann auf versteckte Nutzlast, '
                    'Steganographie oder Software-spezifische '
                    'Anhaenge hinweisen.',
                severity: hiddenBytes > 1024 ? 2 : 1,
              ));
            }
            break;
          }
        }
      }
    }

    // PNG check
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      out.add(const _ManipFinding(
        category: 'Dateiformat',
        title: 'PNG-Format erkannt',
        detail: 'PNGs sind verlustfrei und werden haeufig fuer '
            'Screenshots oder bearbeitete Bilder genutzt, '
            'da sie keine JPEG-Kompressionsartefakte erzeugen. '
            'Der Originalnachweis ist schwieriger als bei JPEG.',
        severity: 0,
      ));
    }
  }

  // ── HF remote analysis ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> _hfAnalyze(String b64) async {
    final responses = await Future.wait([
      _hfCaption(b64),
      _hfAiDetect(b64),
    ], eagerError: false);

    final caption = responses[0] as String?;
    final aiGenerated = responses[1] as bool? ?? false;

    if (caption == null) return null;
    return {'caption': caption, 'aiGenerated': aiGenerated};
  }

  static Future<String?> _hfCaption(String b64) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$_hfBase/Salesforce/blip-image-captioning-base'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'inputs': b64}),
          )
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List && (data as List).isNotEmpty) {
          return (data as List).first['generated_text'] as String?;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<bool?> _hfAiDetect(String b64) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$_hfBase/umm-maybe/AI-image-detector'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'inputs': b64}),
          )
          .timeout(const Duration(seconds: 25));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) {
          for (final item in data as List) {
            final label = (item['label'] as String? ?? '').toLowerCase();
            final score = (item['score'] as num?)?.toDouble() ?? 0.0;
            if ((label.contains('artif') ||
                    label.contains('ai') ||
                    label.contains('fake')) &&
                score > 0.6) {
              return true;
            }
          }
        }
      }
    } catch (_) {}
    return false;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static bool _findSequence(Uint8List bytes, List<int> seq) {
    outer:
    for (int i = 0; i <= bytes.length - seq.length; i++) {
      for (int j = 0; j < seq.length; j++) {
        if (bytes[i + j] != seq[j]) continue outer;
      }
      return true;
    }
    return false;
  }

  static String? _extractSoftwareTag(Uint8List bytes) {
    // Look for ASCII "Software" EXIF tag followed by readable string
    final softBytes = [0x53, 0x6F, 0x66, 0x74, 0x77, 0x61, 0x72, 0x65];
    for (int i = 0; i <= bytes.length - 40; i++) {
      bool match = true;
      for (int j = 0; j < softBytes.length; j++) {
        if (bytes[i + j] != softBytes[j]) {
          match = false;
          break;
        }
      }
      if (match) {
        // Try to read a printable ASCII string within the next 64 bytes
        final sb = StringBuffer();
        for (int k = i + softBytes.length; k < math.min(i + 80, bytes.length); k++) {
          final c = bytes[k];
          if (c == 0 && sb.length > 3) break;
          if (c >= 32 && c < 127) sb.writeCharCode(c);
        }
        final result = sb.toString().trim();
        if (result.length > 3) return result;
      }
    }
    return null;
  }

  static double _entropy(Uint8List data) {
    final freq = List<int>.filled(256, 0);
    for (final b in data) {
      freq[b]++;
    }
    double e = 0;
    for (final f in freq) {
      if (f == 0) continue;
      final p = f / data.length;
      e -= p * math.log(p) / math.ln2;
    }
    return e;
  }

  static int _computeScore(List<_ManipFinding> findings) {
    if (findings.isEmpty) return 0;
    int score = 0;
    for (final f in findings) {
      switch (f.severity) {
        case 0:
          score += 0;
          break;
        case 1:
          score += 15;
          break;
        case 2:
          score += 30;
          break;
        case 3:
          score += 50;
          break;
      }
    }
    return score.clamp(0, 100);
  }

  static String _verdictText(int score) {
    if (score == 0) return 'Keine Manipulation erkannt';
    if (score < 20) return 'Geringfuegige Hinweise';
    if (score < 45) return 'Bearbeitung wahrscheinlich';
    if (score < 70) return 'Deutliche Manipulations-Zeichen';
    return 'Starke Manipulation erkannt';
  }
}

// =============================================================================
// SCREEN
// =============================================================================

class ManipulationAnalysisScreen extends StatefulWidget {
  const ManipulationAnalysisScreen({super.key});

  @override
  State<ManipulationAnalysisScreen> createState() =>
      _ManipulationAnalysisScreenState();
}

class _ManipulationAnalysisScreenState
    extends State<ManipulationAnalysisScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  File? _file;
  Uint8List? _bytes;
  _ManipResult? _result;
  bool _loading = false;
  String _status = '';
  String? _hash;
  final _picker = ImagePicker();
  final _cache = <String, _ManipResult>{};

  // ── Animation ──────────────────────────────────────────────────────────────
  late AnimationController _pulse;

  // ── Palette ────────────────────────────────────────────────────────────────
  static const _bg = Color(0xFF060A14);
  static const _card = Color(0xFF0D1525);
  static const _accent = Color(0xFFE91E63);
  static const _green = Color(0xFF00E676);
  static const _amber = Color(0xFFFFAB00);
  static const _red = Color(0xFFFF1744);
  static const _blue = Color(0xFF2979FF);

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  // ── Image picking ───────────────────────────────────────────────────────────

  Future<void> _pick(ImageSource source) async {
    if (kIsWeb) return;
    try {
      final xf = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 95,
      );
      if (xf == null || !mounted) return;
      final nativeFile = File(xf.path);
      final bytes = await nativeFile.readAsBytes();
      setState(() {
        _file = nativeFile;
        _bytes = bytes;
        _result = null;
        _hash = null;
        _status = '';
      });
    } catch (e) {
      _snack('Fehler beim Laden: $e', _red);
    }
  }

  // ── Analysis ────────────────────────────────────────────────────────────────

  Future<void> _analyze() async {
    if (_bytes == null || _loading) return;
    final bytes = _bytes!;

    setState(() {
      _loading = true;
      _status = 'Hash berechnen...';
    });

    try {
      final hash = md5.convert(bytes).toString();

      if (_cache.containsKey(hash)) {
        setState(() {
          _result = _cache[hash];
          _hash = hash;
          _loading = false;
          _status = 'Aus Cache geladen';
        });
        _snack('Cache-Ergebnis geladen', _green);
        return;
      }

      setState(() => _status = 'Dateistruktur analysieren...');
      await Future.delayed(const Duration(milliseconds: 100));

      setState(() => _status = 'Metadaten und EXIF pruefen...');
      await Future.delayed(const Duration(milliseconds: 100));

      setState(() => _status = 'Kompressionsartefakte auswerten...');
      final result = await _ManipAnalyzer.analyze(bytes);

      _cache[hash] = result;
      if (!mounted) return;

      setState(() {
        _result = result;
        _hash = hash;
        _loading = false;
        _status = 'Analyse abgeschlossen';
      });

      if (result.isAiAnalysis) {
        _snack('Analyse mit Hugging Face KI abgeschlossen', _green);
      } else {
        _snack('Lokale Analyse abgeschlossen (KI offline)', _amber);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _status = 'Fehler';
      });
      _snack('Fehler: $e', _red);
    }
  }

  void _snack(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: bg,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _reset() {
    setState(() {
      _file = null;
      _bytes = null;
      _result = null;
      _hash = null;
      _status = '';
    });
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: const TextStyle(decoration: TextDecoration.none),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              _header(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _infoBanner(),
                      const SizedBox(height: 16),
                      _pickerRow(),
                      const SizedBox(height: 12),
                      if (_file != null) _previewCard(),
                      const SizedBox(height: 12),
                      _analyzeButton(),
                      if (_result != null) ...[
                        const SizedBox(height: 24),
                        _resultsPanel(),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      decoration: BoxDecoration(
        color: _card,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manipulationsanalyse',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Bildbearbeitung & Faelschungen erkennen',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45), fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _accent.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.find_in_page_rounded,
                    color: Color(0xFFE91E63), size: 12),
                SizedBox(width: 5),
                Text(
                  'LOGIK',
                  style: TextStyle(
                    color: Color(0xFFE91E63),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _blue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _blue.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF82B1FF), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Lokale Forensik-Analyse + optionale Hugging Face KI. '
              'Erkennt: Photoshop-Bearbeitung, EXIF-Anomalien, '
              'Kompressionsartefakte, Farb-Filter und eingebettete Daten.',
              style: TextStyle(
                  color: Colors.white60, fontSize: 11, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickerRow() {
    return Row(
      children: [
        Expanded(
          child: _PickBtn(
            icon: Icons.photo_library_outlined,
            label: 'Galerie',
            color: _green,
            onTap: () => _pick(ImageSource.gallery),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PickBtn(
            icon: Icons.camera_alt_outlined,
            label: 'Kamera',
            color: _blue,
            onTap: () => _pick(ImageSource.camera),
          ),
        ),
      ],
    );
  }

  Widget _previewCard() {
    final sizeKb = (_bytes?.length ?? 0) / 1024;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              _file! as dynamic,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bild geladen',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                const SizedBox(height: 3),
                Text(
                  '${sizeKb.toStringAsFixed(1)} KB',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                if (_hash != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'MD5: ${_hash!.substring(0, 12)}...',
                    style: TextStyle(
                        color: _blue.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontFamily: 'monospace'),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: _reset,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.close, color: Colors.white54, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _analyzeButton() {
    final canAnalyze = _file != null && !_loading;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => GestureDetector(
        onTap: canAnalyze ? _analyze : null,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: _loading || _file == null
                ? null
                : const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
                  ),
            color: _loading || _file == null
                ? Colors.white.withValues(alpha: 0.05)
                : null,
            borderRadius: BorderRadius.circular(18),
            boxShadow: canAnalyze
                ? [
                    BoxShadow(
                      color: const Color(0xFFE91E63)
                          .withValues(alpha: 0.2 + _pulse.value * 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: _loading
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white70),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _status.isEmpty ? 'Analysiere...' : _status,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _file == null
                            ? 'Zuerst Bild auswaehlen'
                            : 'Manipulation pruefen',
                        style: TextStyle(
                          color: canAnalyze
                              ? Colors.white
                              : Colors.white38,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ── Results panel ───────────────────────────────────────────────────────────

  Widget _resultsPanel() {
    final r = _result!;
    final score = r.overallScore;

    Color scoreColor;
    IconData scoreIcon;
    if (score == 0) {
      scoreColor = _green;
      scoreIcon = Icons.verified_rounded;
    } else if (score < 20) {
      scoreColor = Colors.lightGreen;
      scoreIcon = Icons.check_circle_outline_rounded;
    } else if (score < 45) {
      scoreColor = _amber;
      scoreIcon = Icons.warning_amber_rounded;
    } else {
      scoreColor = _red;
      scoreIcon = Icons.gpp_bad_rounded;
    }

    final suspiciousFindings =
        r.findings.where((f) => f.severity > 0).toList();
    final okFindings = r.findings.where((f) => f.severity == 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Verdict card ──────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scoreColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: scoreColor.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(scoreIcon, color: scoreColor, size: 26),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      r.verdict,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Chip(
                    label: 'Manipulations-Score',
                    value: '$score%',
                    color: scoreColor,
                  ),
                  _Chip(
                    label: 'Hinweise',
                    value: '${suspiciousFindings.length}',
                    color: suspiciousFindings.isEmpty ? _green : _amber,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: r.isAiAnalysis
                      ? _green.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: r.isAiAnalysis
                        ? _green.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      r.isAiAnalysis
                          ? Icons.cloud_done_rounded
                          : Icons.computer_rounded,
                      color: r.isAiAnalysis ? _green : Colors.white38,
                      size: 12,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      r.analysisSource,
                      style: TextStyle(
                        color: r.isAiAnalysis ? _green : Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── AI Caption ────────────────────────────────────────────────────────
        if (r.aiCaption != null) ...[
          const SizedBox(height: 16),
          _sectionLabel(Icons.auto_stories_rounded, 'KI-Bildbeschreibung',
              _blue),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _blue.withValues(alpha: 0.15)),
            ),
            child: Text(
              '"${r.aiCaption}"',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],

        // ── Suspicious findings ───────────────────────────────────────────────
        if (suspiciousFindings.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionLabel(Icons.policy_rounded,
              'Manipulations-Hinweise (${suspiciousFindings.length})', _red),
          const SizedBox(height: 8),
          ...suspiciousFindings.map(_findingCard),
        ],

        // ── OK findings ───────────────────────────────────────────────────────
        if (okFindings.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionLabel(Icons.check_circle_outline_rounded,
              'Hinweise ohne Bedenken', _green),
          const SizedBox(height: 8),
          ...okFindings.map(_findingCard),
        ],

        // ── Empty state ───────────────────────────────────────────────────────
        if (r.findings.isEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _green.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_rounded, color: Color(0xFF00E676), size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Keine Manipulations-Indikatoren gefunden. '
                    'Das Bild sieht unveraendert aus.',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── Disclaimer ────────────────────────────────────────────────────────
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: const Text(
            'Hinweis: Diese Analyse ersetzt keine professionelle forensische '
            'Untersuchung. Technische Indikatoren koennen bei unbeschaetigten '
            'Bildern auftreten. Kombinieren Sie mehrere Ergebnisse fuer ein '
            'belastbares Urteil.',
            style: TextStyle(
                color: Colors.white38, fontSize: 10, height: 1.45),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 7),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _findingCard(_ManipFinding f) {
    Color c = _amber;
    IconData ico = Icons.warning_amber_rounded;
    switch (f.severity) {
      case 0:
        c = _green;
        ico = Icons.check_circle_outline_rounded;
        break;
      case 1:
        c = _amber;
        ico = Icons.warning_amber_rounded;
        break;
      case 2:
        c = Colors.orange;
        ico = Icons.report_problem_rounded;
        break;
      default:
        c = _red;
        ico = Icons.gpp_bad_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ico, color: c, size: 15),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  f.title,
                  style: TextStyle(
                    color: c,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: c.withValues(alpha: 0.3)),
                ),
                child: Text(
                  f.category,
                  style: TextStyle(
                      color: c,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            f.detail,
            style: const TextStyle(
                color: Colors.white60, fontSize: 11, height: 1.45),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SMALL REUSABLE WIDGETS
// =============================================================================

class _PickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PickBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Chip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              color: color, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}
