import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../../services/image_analysis_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// IMAGE FORENSICS SCREEN v2.0
// Echte KI-Bildanalyse via Hugging Face (kostenlos) + lokale Forensik
// ═══════════════════════════════════════════════════════════════════════════

class ImageForensicsScreen extends StatefulWidget {
  const ImageForensicsScreen({super.key});

  @override
  State<ImageForensicsScreen> createState() => _ImageForensicsScreenState();
}

class _ImageForensicsScreenState extends State<ImageForensicsScreen>
    with SingleTickerProviderStateMixin {

  // State
  File? _selectedImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _analysis;
  bool _isAnalyzing = false;
  String? _imageHash;
  String _analysisStatus = '';
  final Map<String, Map<String, dynamic>> _cache = {};

  // Animation
  late AnimationController _pulseCtrl;

  // Colors
  static const _bg    = Color(0xFF060A14);
  static const _card  = Color(0xFF0D1525);
  static const _blue  = Color(0xFF2979FF);
  static const _green = Color(0xFF00E676);
  static const _red   = Color(0xFFFF1744);
  static const _amber = Color(0xFFFFAB00);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // BILD AUSWÄHLEN
  // ─────────────────────────────────────────────

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (image != null && mounted) {
        final bytes = await File(image.path).readAsBytes();
        setState(() {
          _selectedImage = File(image.path);
          _imageBytes = bytes;
          _analysis = null;
          _imageHash = null;
          _analysisStatus = '';
        });
      }
    } catch (e) {
      if (mounted) _showError('Fehler beim Laden: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (photo != null && mounted) {
        final bytes = await File(photo.path).readAsBytes();
        setState(() {
          _selectedImage = File(photo.path);
          _imageBytes = bytes;
          _analysis = null;
          _imageHash = null;
          _analysisStatus = '';
        });
      }
    } catch (e) {
      if (mounted) _showError('Fehler bei Kamera: $e');
    }
  }

  // ─────────────────────────────────────────────
  // ANALYSE
  // ─────────────────────────────────────────────

  Future<void> _analyzeImage() async {
    if (_imageBytes == null || _isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _analysisStatus = '🔍 Berechne Bild-Hash…';
    });

    try {
      // Hash für Cache
      final currentHash = md5.convert(_imageBytes!).toString();

      if (_cache.containsKey(currentHash)) {
        setState(() {
          _analysis = _cache[currentHash];
          _imageHash = currentHash;
          _isAnalyzing = false;
          _analysisStatus = '✅ Cache verwendet';
        });
        _showSuccess('Aus Cache geladen');
        return;
      }

      // Schritt 1: Lokale Analyse
      setState(() => _analysisStatus = '🧬 EXIF & Metadaten analysieren…');
      await Future.delayed(const Duration(milliseconds: 200));

      // Schritt 2: KI-Analyse
      setState(() => _analysisStatus = '🤖 Hugging Face KI lädt…');

      final result = await ImageAnalysisService.analyzeImage(_imageBytes!);

      // Cache speichern
      _cache[currentHash] = result;

      if (!mounted) return;

      setState(() {
        _analysis = result;
        _imageHash = currentHash;
        _isAnalyzing = false;
        _analysisStatus = '✅ Analyse abgeschlossen';
      });

      final isAI = result['isRealAI'] == true;
      if (isAI) {
        _showSuccess('✅ KI-Analyse mit Hugging Face abgeschlossen');
      } else {
        _showWarning('⚠️ KI-API nicht verfügbar – lokale Analyse durchgeführt');
      }

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _analysisStatus = '❌ Fehler';
      });
      _showError('Fehler: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade800),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green.shade800,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.orange.shade800,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: const TextStyle(decoration: TextDecoration.none),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildInfoBanner(),
                      const SizedBox(height: 20),
                      _buildImagePicker(),
                      const SizedBox(height: 16),
                      if (_selectedImage != null) _buildPreviewCard(),
                      const SizedBox(height: 16),
                      _buildAnalyzeButton(),
                      if (_analysis != null) ...[
                        const SizedBox(height: 24),
                        _buildResultsPanel(),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      decoration: BoxDecoration(
        color: _card,
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
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
              const Text('Image Forensics',
                  style: TextStyle(
                      color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.w700, letterSpacing: -0.3)),
              Text('Echtheit & KI-Erkennung',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _green.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFF00E676), size: 12),
                SizedBox(width: 5),
                Text('AI-powered',
                    style: TextStyle(color: Color(0xFF00E676), fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _blue.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF82B1FF), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Kostenlose KI-Bildanalyse via Hugging Face + lokale EXIF-Forensik. '
              'Erkennt: KI-generierte Bilder, Manipulation, Deep Fakes.',
              style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Row(
      children: [
        Expanded(
          child: _PickerButton(
            icon: Icons.photo_library_outlined,
            label: 'Galerie',
            color: _green,
            onTap: _pickImage,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PickerButton(
            icon: Icons.camera_alt_outlined,
            label: 'Kamera',
            color: _blue,
            onTap: _takePhoto,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard() {
    final sizeKB = (_imageBytes?.length ?? 0) / 1024;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              _selectedImage!,
              width: 64, height: 64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bild ausgewählt',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 3),
                Text('${sizeKB.toStringAsFixed(1)} KB',
                    style: const TextStyle(color: Colors.white54, fontSize: 11)),
                if (_imageHash != null) ...[
                  const SizedBox(height: 3),
                  Text('Hash: ${_imageHash!.substring(0, 12)}…',
                      style: TextStyle(color: _blue.withValues(alpha: 0.7),
                          fontSize: 10, fontFamily: 'monospace')),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _selectedImage = null;
              _imageBytes = null;
              _analysis = null;
              _imageHash = null;
            }),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, color: Colors.white54, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => GestureDetector(
        onTap: (_isAnalyzing || _selectedImage == null) ? null : _analyzeImage,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: _isAnalyzing
                ? null
                : LinearGradient(
                    colors: [
                      const Color(0xFFE91E63),
                      const Color(0xFFC2185B),
                    ],
                  ),
            color: _isAnalyzing
                ? Colors.white.withValues(alpha: 0.05)
                : null,
            borderRadius: BorderRadius.circular(18),
            boxShadow: _isAnalyzing
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFFE91E63).withValues(
                          alpha: 0.2 + _pulseCtrl.value * 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: _isAnalyzing
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white70),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _analysisStatus.isEmpty
                            ? '🤖 Analysiere…'
                            : _analysisStatus,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.biotech_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _selectedImage == null
                            ? 'Bild wählen'
                            : 'KI-Analyse starten',
                        style: TextStyle(
                          color: _selectedImage == null
                              ? Colors.white38
                              : Colors.white,
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

  // ─────────────────────────────────────────────
  // ERGEBNISSE
  // ─────────────────────────────────────────────

  Widget _buildResultsPanel() {
    if (_analysis == null) return const SizedBox.shrink();

    final a = _analysis!;
    final verdict = a['overallVerdict'] as String? ?? 'UNBEKANNT';
    final score = a['manipulationScore'] as int? ?? 0;
    final confidence = a['confidence'] as int? ?? 0;
    final isAI = a['isRealAI'] == true;
    final aiSource = a['aiSource'] as String? ?? 'lokal';

    // Farbe basierend auf Urteil
    Color verdictColor;
    IconData verdictIcon;
    if (score == 0) {
      verdictColor = _green;
      verdictIcon = Icons.verified_rounded;
    } else if (score < 25) {
      verdictColor = Colors.lightGreen;
      verdictIcon = Icons.check_circle_outline;
    } else if (score < 50) {
      verdictColor = _amber;
      verdictIcon = Icons.warning_amber_rounded;
    } else {
      verdictColor = _red;
      verdictIcon = Icons.dangerous_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Haupturteil ──────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: verdictColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: verdictColor.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(verdictIcon, color: verdictColor, size: 28),
                  const SizedBox(width: 10),
                  Text(verdict,
                      style: TextStyle(
                          color: verdictColor, fontSize: 18,
                          fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MetricChip(
                    label: 'Manipulations-Score',
                    value: '$score%',
                    color: score > 50 ? _red : score > 25 ? _amber : _green,
                  ),
                  _MetricChip(
                    label: 'Konfidenz',
                    value: '$confidence%',
                    color: _blue,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isAI
                      ? _green.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isAI
                        ? _green.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAI ? Icons.cloud_done : Icons.computer,
                      size: 12,
                      color: isAI ? _green : Colors.white38,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isAI ? 'KI-Analyse: $aiSource' : 'Lokale Analyse',
                      style: TextStyle(
                          color: isAI ? _green : Colors.white38,
                          fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── KI-Caption (wenn verfügbar) ──────────────────────
        if (a['aiCaption'] != null) ...[
          _buildSection(
            icon: Icons.auto_stories_rounded,
            title: 'Bildbeschreibung (KI)',
            color: _blue,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _blue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _blue.withValues(alpha: 0.15)),
              ),
              child: Text(
                '"${a['aiCaption']}"',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13,
                    fontStyle: FontStyle.italic, height: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── KI-Erkennung ─────────────────────────────────────
        if (a['isAIGenerated'] != null) ...[
          _buildSection(
            icon: Icons.smart_toy_rounded,
            title: 'KI / Deep Fake Erkennung',
            color: a['isAIGenerated'] == true ? _red : _green,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (a['isAIGenerated'] == true ? _red : _green)
                    .withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (a['isAIGenerated'] == true ? _red : _green)
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    a['isAIGenerated'] == true
                        ? Icons.warning_rounded
                        : Icons.check_circle_outline_rounded,
                    color: a['isAIGenerated'] == true ? _red : _green,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a['isAIGenerated'] == true
                              ? '⚠️ KI-generiertes Bild erkannt'
                              : '✅ Authentisches Foto',
                          style: TextStyle(
                              color: a['isAIGenerated'] == true ? _red : _green,
                              fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Konfidenz: ${((a['aiConfidence'] as double? ?? 0) * 100).toInt()}%',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── Bildkategorie ─────────────────────────────────────
        if (a['imageCategory'] != null) ...[
          _buildSection(
            icon: Icons.category_rounded,
            title: 'Bildinhalt (Klassifikation)',
            color: Colors.teal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.image_search_rounded,
                      color: Colors.teal, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${a['imageCategory']}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── Beweise/Warnungen ─────────────────────────────────
        if ((a['evidence'] as List<dynamic>?)?.isNotEmpty == true) ...[
          _buildSection(
            icon: Icons.policy_rounded,
            title: 'Forensische Hinweise',
            color: _amber,
            child: Column(
              children: ((a['evidence'] as List<dynamic>?) ?? [])
                  .map((e) => _EvidenceItem(
                        text: e.toString(),
                        color: _amber,
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── EXIF-Info ─────────────────────────────────────────
        if (((a['tests'] as Map<String, dynamic>?) ?? {})['exif'] != null) ...[
          _buildSection(
            icon: Icons.data_object_rounded,
            title: 'EXIF & Metadaten',
            color: Colors.indigo,
            child: _TestResultCard(
              result: (a['tests'] as Map<String, dynamic>)['exif']
                  as Map<String, dynamic>,
              color: ((a['tests'] as Map<String, dynamic>)['exif']
                          as Map<String, dynamic>)['suspicious'] ==
                      true
                  ? _amber
                  : _green,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── Dateiformats-Info ─────────────────────────────────
        if (a['format'] != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Row(
              children: [
                const Icon(Icons.insert_drive_file_outlined,
                    color: Colors.white38, size: 16),
                const SizedBox(width: 8),
                Text('Format: ${a['format']}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(width: 16),
                Text('Größe: ${a['imageSizeKB']} KB',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 7),
          Text(title,
              style: TextStyle(
                  color: color, fontSize: 12,
                  fontWeight: FontWeight.w700, letterSpacing: 0.3)),
        ]),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PickerButton({
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
                    color: color, fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 22,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}

class _EvidenceItem extends StatelessWidget {
  final String text;
  final Color color;
  const _EvidenceItem({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white70, fontSize: 12, height: 1.4)),
    );
  }
}

class _TestResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  final Color color;
  const _TestResultCard({required this.result, required this.color});

  @override
  Widget build(BuildContext context) {
    final reason = result['reason'] as String? ?? '';
    final software = result['software'] as String?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result['suspicious'] == true
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
                color: color, size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(reason,
                    style: TextStyle(color: color, fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (software != null) ...[
            const SizedBox(height: 6),
            Text('Software: $software',
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
          Row(children: [
            if (result['isJpeg'] == true)
              _Tag('JPEG', Colors.blue),
            if (result['isPng'] == true)
              _Tag('PNG', Colors.purple),
            if (result['hasExifData'] == true)
              _Tag('EXIF', Colors.teal),
          ]),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(color: color, fontSize: 9,
              fontWeight: FontWeight.w700)),
    );
  }
}
