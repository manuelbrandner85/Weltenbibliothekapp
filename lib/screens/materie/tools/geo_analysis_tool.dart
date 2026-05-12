import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../config/api_config.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// G — Geo-Analyse
// ─────────────────────────────────────────────────────────────────────────────

const _kBg      = Color(0xFF0D0000);
const _kSurface = Color(0xFF1A0808);
const _kAccent  = Color(0xFFE53935);
const _kText    = Colors.white;
const _kMuted   = Color(0xFFB0A0A0);
const _kBorder  = Color(0x33E53935);

class GeoAnalysisTool extends StatefulWidget {
  const GeoAnalysisTool({super.key});

  @override
  State<GeoAnalysisTool> createState() => _GeoAnalysisToolState();
}

class _GeoAnalysisToolState extends State<GeoAnalysisTool> {
  final _queryCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _analyse() async {
    final query = _queryCtrl.text.trim();
    if (query.isEmpty) return;
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final uri = Uri.parse(
        '${ApiConfig.workerUrl}/api/tools/geo?q=${Uri.encodeComponent(query)}',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 25));
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['error'] != null) throw Exception(data['error'].toString());
      setState(() { _result = data; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _openMap(double lat, double lon) async {
    final uri = Uri.parse('https://www.openstreetmap.org/?mlat=$lat&mlon=$lon#map=12/$lat/$lon');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _card(String title, IconData icon, Color color, Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _kSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _kBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
      const SizedBox(height: 10),
      child,
    ]),
  );

  Widget _row(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(color: _kMuted, fontSize: 12))),
        Expanded(child: Text(value, style: const TextStyle(color: _kText, fontSize: 13))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final geo        = _result?['location'] as Map<String, dynamic>?;
    final weather    = _result?['weather'] as Map<String, dynamic>?;
    final wikipedia  = (_result?['wikipedia'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final lat        = geo?['lat'] as double?;
    final lon        = geo?['lon'] as double?;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: Row(children: [
          Icon(Icons.map_rounded, color: _kAccent, size: 22),
          const SizedBox(width: 8),
          const Text('Geo-Analyse', style: TextStyle(color: _kText, fontWeight: FontWeight.bold)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Ortsname oder Koordinaten', style: TextStyle(color: _kMuted, fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: _queryCtrl,
                style: const TextStyle(color: _kText),
                decoration: InputDecoration(
                  hintText: 'Berlin, 52.52 13.41, oder Timbuktu',
                  hintStyle: TextStyle(color: _kMuted.withValues(alpha: 0.6)),
                  prefixIcon: const Icon(Icons.location_on_rounded, color: _kMuted, size: 18),
                  filled: true,
                  fillColor: _kBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kAccent)),
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
                      : const Icon(Icons.travel_explore_rounded, size: 18),
                  label: const Text('Geo-Analyse starten'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ]),
          ),

          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _kSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder)),
              child: Row(children: [
                const Icon(Icons.error_outline, color: _kAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: const TextStyle(color: _kAccent, fontSize: 13))),
              ]),
            ),

          if (geo != null)
            _card('Standort', Icons.location_on_rounded, _kAccent, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _row('Name', geo['displayName']?.toString()),
              _row('Land', geo['country']?.toString()),
              _row('Region', geo['region']?.toString()),
              _row('Staat', geo['state']?.toString()),
              if (lat != null && lon != null) ...[
                _row('Koordinaten', '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}'),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _openMap(lat, lon),
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: const Text('Auf OpenStreetMap anzeigen'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kAccent,
                    side: BorderSide(color: _kAccent.withValues(alpha: 0.4)),
                  ),
                ),
              ],
            ])),

          if (weather != null)
            _card('Aktuelles Wetter', Icons.cloud_rounded, const Color(0xFF29B6F6), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (weather['temperature'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('${weather['temperature']}°C', style: const TextStyle(color: _kText, fontSize: 24, fontWeight: FontWeight.bold)),
                ),
              _row('Windgeschwindigkeit', weather['windSpeed'] != null ? '${weather['windSpeed']} km/h' : null),
              _row('Niederschlag', weather['precipitation'] != null ? '${weather['precipitation']} mm' : null),
              _row('Zeitpunkt', weather['time']?.toString()),
            ])),

          if (wikipedia.isNotEmpty)
            _card('Wikipedia in der Nähe', Icons.auto_stories_rounded, const Color(0xFFAB47BC), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ...wikipedia.take(5).map((article) => InkWell(
                onTap: () async {
                  final title = article['title'] as String? ?? '';
                  final wikiUri = Uri.parse('https://de.wikipedia.org/wiki/${Uri.encodeComponent(title)}');
                  if (await canLaunchUrl(wikiUri)) await launchUrl(wikiUri, mode: LaunchMode.externalApplication);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Row(children: [
                    const Icon(Icons.article_rounded, color: _kMuted, size: 14),
                    const SizedBox(width: 8),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(article['title']?.toString() ?? '', style: const TextStyle(color: _kText, fontSize: 13, fontWeight: FontWeight.w500)),
                      if (article['distance'] != null)
                        Text('${article['distance']} m entfernt', style: const TextStyle(color: _kMuted, fontSize: 11)),
                    ])),
                    const Icon(Icons.open_in_new_rounded, color: _kMuted, size: 12),
                  ]),
                ),
              )),
            ])),
        ]),
      ),
    );
  }
}
