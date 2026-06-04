import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/materie/osint_source_banner.dart';
import '../../../utils/osint_result_share.dart';

// ─────────────────────────────────────────────────────────────────────────────
// M-X1 — Person / Entitaets-Recherche (oeffentliche Wissensquellen)
// Datenquelle: Wikipedia (Search + REST-Summary), kostenlos, kein API-Key.
// Bewusst auf oeffentliche/notable Eintraege beschraenkt -- kein Doxxing.
// ─────────────────────────────────────────────────────────────────────────────

const _kBg = Color(0xFF0D0000);
const _kSurface = Color(0xFF1A0808);
const _kAccent = Color(0xFFE53935);
const _kText = Colors.white;
const _kMuted = Color(0xFFB0A0A0);
const _kBorder = Color(0x33E53935);

class PersonOsintTool extends StatefulWidget {
  const PersonOsintTool({super.key});

  @override
  State<PersonOsintTool> createState() => _PersonOsintToolState();
}

class _PersonOsintToolState extends State<PersonOsintTool> {
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _otherHits = const [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _stripHtml(String s) =>
      s.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&quot;', '"');

  Future<void> _search([String? override]) async {
    final q = (override ?? _nameCtrl.text).trim();
    if (q.isEmpty) return;
    if (override != null) _nameCtrl.text = q;
    setState(() {
      _loading = true;
      _error = null;
      _summary = null;
      _otherHits = const [];
    });
    try {
      // 1) Suche nach dem besten Artikel-Titel.
      final searchUri = Uri.parse(
        'https://de.wikipedia.org/w/api.php?action=query&list=search'
        '&srsearch=${Uri.encodeQueryComponent(q)}&format=json&srlimit=5&origin=*',
      );
      final searchResp =
          await http.get(searchUri).timeout(const Duration(seconds: 20));
      final searchData = jsonDecode(searchResp.body) as Map<String, dynamic>;
      final hits = ((searchData['query']?['search']) as List?)
              ?.cast<Map<String, dynamic>>() ??
          const [];
      if (hits.isEmpty) {
        setState(() => _error =
            'Kein oeffentlicher Eintrag gefunden. Nur bekannte Personen, '
                'Organisationen und Begriffe sind erfasst.');
        return;
      }

      final topTitle = hits.first['title'].toString();
      // 2) REST-Summary fuer den Top-Treffer.
      final sumUri = Uri.parse(
        'https://de.wikipedia.org/api/rest_v1/page/summary/'
        '${Uri.encodeComponent(topTitle.replaceAll(' ', '_'))}',
      );
      final sumResp =
          await http.get(sumUri).timeout(const Duration(seconds: 20));
      final summary = jsonDecode(sumResp.body) as Map<String, dynamic>;

      setState(() {
        _summary = summary;
        _otherHits = hits.skip(1).toList();
      });
    } catch (e) {
      setState(
          () => _error = 'Abfrage fehlgeschlagen. Bitte erneut versuchen.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Map<String, dynamic>? get _shareResult {
    final s = _summary;
    if (s == null) return null;
    return {
      'name': s['title'],
      'beschreibung': s['description'],
      'zusammenfassung': s['extract'],
      'quelle': s['content_urls']?['desktop']?['page'],
    };
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _card(Widget child) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final s = _summary;
    final thumb = (s?['thumbnail']?['source'])?.toString();
    final pageUrl = (s?['content_urls']?['desktop']?['page'])?.toString();
    final isDisambig = (s?['type']?.toString() ?? '') == 'disambiguation';
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: Row(children: [
          const Icon(Icons.person_search_rounded, color: _kAccent, size: 22),
          const SizedBox(width: 8),
          const Text('Personen-Recherche',
              style: TextStyle(color: _kText, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          OsintResultShare.actionButton(
            context,
            toolName: 'Personen-Recherche',
            query: _nameCtrl.text,
            result: _shareResult,
            color: _kAccent,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Name, Organisation oder Begriff',
                style: TextStyle(color: _kMuted, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: _kText),
              decoration: InputDecoration(
                hintText: 'z.B. Edward Snowden, OpenAI, Bilderberg',
                hintStyle: TextStyle(color: _kMuted.withValues(alpha: 0.6)),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: _kMuted, size: 18),
                filled: true,
                fillColor: _kBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kBorder)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kBorder)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kAccent)),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : () => _search(),
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.travel_explore_rounded, size: 18),
                label: const Text('Recherchieren'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ])),
          const OsintSourceBanner(
            source: 'Oeffentliche Wissensbasis (Wikipedia). Nur bekannte '
                'Personen/Organisationen erfasst - kein Zugriff auf '
                'private Daten.',
            accent: _kAccent,
            sources: [OsintSource('Wikipedia', 'https://de.wikipedia.org')],
          ),
          if (_error != null)
            _card(Row(children: [
              const Icon(Icons.info_outline, color: _kAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(_error!,
                      style: const TextStyle(color: _kAccent, fontSize: 13))),
            ])),
          if (s != null) ...[
            _card(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (thumb != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      thumb,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                if (thumb != null) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['title']?.toString() ?? '',
                            style: const TextStyle(
                                color: _kText,
                                fontSize: 17,
                                fontWeight: FontWeight.bold)),
                        if (s['description'] != null) ...[
                          const SizedBox(height: 4),
                          Text(s['description'].toString(),
                              style: const TextStyle(
                                  color: _kAccent, fontSize: 12.5)),
                        ],
                      ]),
                ),
              ]),
              if (isDisambig) ...[
                const SizedBox(height: 10),
                const Text(
                  'Mehrdeutiger Begriff - bitte praezisieren.',
                  style: TextStyle(color: Color(0xFFFFB300), fontSize: 12),
                ),
              ],
              if (s['extract'] != null) ...[
                const SizedBox(height: 12),
                Text(s['extract'].toString(),
                    style: const TextStyle(
                        color: _kText, fontSize: 13, height: 1.5)),
              ],
              if (pageUrl != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _open(pageUrl),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Auf Wikipedia oeffnen'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kAccent,
                    side: BorderSide(color: _kAccent.withValues(alpha: 0.5)),
                  ),
                ),
              ],
            ])),
            if (_otherHits.isNotEmpty)
              _card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Weitere Treffer',
                        style: TextStyle(color: _kMuted, fontSize: 12)),
                    const SizedBox(height: 8),
                    for (final h in _otherHits)
                      InkWell(
                        onTap: () => _search(h['title'].toString()),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(h['title']?.toString() ?? '',
                                  style: const TextStyle(
                                      color: _kText,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              if (h['snippet'] != null)
                                Text(_stripHtml(h['snippet'].toString()),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: _kMuted, fontSize: 11.5)),
                            ],
                          ),
                        ),
                      ),
                  ])),
          ],
        ]),
      ),
    );
  }
}
