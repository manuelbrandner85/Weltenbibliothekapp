import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../config/api_config.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// A — Bildanalyse
// ─────────────────────────────────────────────────────────────────────────────

const _kBg      = Color(0xFF0D0000);
const _kSurface = Color(0xFF1A0808);
const _kAccent  = Color(0xFFE53935);
const _kText    = Colors.white;
const _kMuted   = Color(0xFFB0A0A0);
const _kBorder  = Color(0x33E53935);

class ImageAnalysisTool extends StatefulWidget {
  const ImageAnalysisTool({super.key});

  @override
  State<ImageAnalysisTool> createState() => _ImageAnalysisToolState();
}

class _ImageAnalysisToolState extends State<ImageAnalysisTool> {
  final _urlCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _analyse() async {
    final raw = _urlCtrl.text.trim();
    if (raw.isEmpty) return;
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final uri = Uri.parse(
        '${ApiConfig.workerUrl}/api/tools/image-analysis?url=${Uri.encodeComponent(raw)}',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 20));
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['error'] != null) throw Exception(data['error'].toString());
      setState(() { _result = data; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _openUrl(String url) async {
    final u = Uri.parse(url);
    if (await canLaunchUrl(u)) await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  Widget _card(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _kSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _kBorder, width: 1),
    ),
    child: child,
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 120, child: Text(label, style: const TextStyle(color: _kMuted, fontSize: 12))),
      Expanded(child: Text(value, style: const TextStyle(color: _kText, fontSize: 13))),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: Row(children: [
          Icon(Icons.image_search_rounded, color: _kAccent, size: 22),
          const SizedBox(width: 8),
          const Text('Bildanalyse', style: TextStyle(color: _kText, fontWeight: FontWeight.bold)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Input card
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Bild-URL eingeben', style: TextStyle(color: _kMuted, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _urlCtrl,
              style: const TextStyle(color: _kText),
              decoration: InputDecoration(
                hintText: 'https://example.com/bild.jpg',
                hintStyle: TextStyle(color: _kMuted.withValues(alpha: 0.6)),
                filled: true,
                fillColor: _kBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _kAccent),
                ),
              ),
              onSubmitted: (_) => _analyse(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _analyse,
                icon: _loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.search_rounded, size: 18),
                label: const Text('Analysieren'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ])),

          if (_error != null)
            _card(Row(children: [
              const Icon(Icons.error_outline, color: _kAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(_error!, style: const TextStyle(color: _kAccent, fontSize: 13))),
            ])),

          if (_result != null) ...[
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Datei-Informationen', style: TextStyle(color: _kAccent, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              if (_result!['contentType'] != null) _row('Content-Type', _result!['contentType'].toString()),
              if (_result!['size'] != null) _row('Dateigröße', _result!['size'].toString()),
              if (_result!['width'] != null && _result!['height'] != null)
                _row('Abmessungen', '${_result!['width']} × ${_result!['height']} px'),
              if (_result!['lastModified'] != null) _row('Geändert', _result!['lastModified'].toString()),
            ])),

            if (_result!['exif'] != null && (_result!['exif'] as Map).isNotEmpty)
              _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('EXIF-Metadaten', style: TextStyle(color: _kAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                ...(_result!['exif'] as Map).entries.take(15).map((e) => _row(e.key.toString(), e.value.toString())),
              ])),

            // Suchen-Buttons
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Suchen in', style: TextStyle(color: _kMuted, fontSize: 12)),
              const SizedBox(height: 10),
              Row(children: [
                _searchBtn('TinEye', Icons.image_search, () {
                  _openUrl('https://tineye.com/search?url=${Uri.encodeComponent(_urlCtrl.text.trim())}');
                }),
                const SizedBox(width: 8),
                _searchBtn('Google', Icons.search, () {
                  _openUrl('https://www.google.com/searchbyimage?image_url=${Uri.encodeComponent(_urlCtrl.text.trim())}');
                }),
                const SizedBox(width: 8),
                _searchBtn('Yandex', Icons.travel_explore, () {
                  _openUrl('https://yandex.com/images/search?rpt=imageview&url=${Uri.encodeComponent(_urlCtrl.text.trim())}');
                }),
              ]),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  _openUrl('https://hivemoderation.com/image-moderation-demo');
                },
                icon: const Icon(Icons.verified_user_rounded, size: 16),
                label: const Text('Hive Moderation AI prüfen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kMuted,
                  side: const BorderSide(color: _kBorder),
                ),
              ),
            ])),
          ],
        ]),
      ),
    );
  }

  Widget _searchBtn(String label, IconData icon, VoidCallback onTap) => Expanded(
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: _kAccent,
        side: const BorderSide(color: _kBorder),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    ),
  );
}
