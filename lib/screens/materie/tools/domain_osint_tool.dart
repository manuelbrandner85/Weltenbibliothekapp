import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';

// ─────────────────────────────────────────────────────────────────────────────
// D — Domain-OSINT
// ─────────────────────────────────────────────────────────────────────────────

const _kBg      = Color(0xFF0D0000);
const _kSurface = Color(0xFF1A0808);
const _kAccent  = Color(0xFFE53935);
const _kText    = Colors.white;
const _kMuted   = Color(0xFFB0A0A0);
const _kBorder  = Color(0x33E53935);

class DomainOsintTool extends StatefulWidget {
  const DomainOsintTool({super.key});

  @override
  State<DomainOsintTool> createState() => _DomainOsintToolState();
}

class _DomainOsintToolState extends State<DomainOsintTool> {
  final _domainCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _domainCtrl.dispose();
    super.dispose();
  }

  /// Extrahiert Hostname aus einer URL
  String _cleanDomain(String input) {
    try {
      var s = input.trim().toLowerCase();
      if (!s.startsWith('http')) s = 'https://$s';
      return Uri.parse(s).host;
    } catch (_) {
      return input.trim();
    }
  }

  Future<void> _lookup() async {
    final domain = _cleanDomain(_domainCtrl.text);
    if (domain.isEmpty) return;
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final uri = Uri.parse(
        '${ApiConfig.workerUrl}/api/tools/domain?domain=${Uri.encodeComponent(domain)}',
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
        SizedBox(width: 130, child: Text(label, style: const TextStyle(color: _kMuted, fontSize: 12))),
        Expanded(child: Text(value, style: const TextStyle(color: _kText, fontSize: 12))),
      ]),
    );
  }

  Widget _recordList(String label, List<dynamic> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: _kMuted, fontSize: 11)),
        const SizedBox(height: 4),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text('• $item', style: const TextStyle(color: _kText, fontSize: 12, fontFamily: 'monospace')),
        )),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final whois = _result?['whois'] as Map<String, dynamic>?;
    final dns   = _result?['dns'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: Row(children: [
          Icon(Icons.language_rounded, color: _kAccent, size: 22),
          const SizedBox(width: 8),
          const Text('Domain-OSINT', style: TextStyle(color: _kText, fontWeight: FontWeight.bold)),
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
              const Text('Domain oder URL eingeben', style: TextStyle(color: _kMuted, fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: _domainCtrl,
                style: const TextStyle(color: _kText),
                decoration: InputDecoration(
                  hintText: 'example.com oder https://example.com',
                  hintStyle: TextStyle(color: _kMuted.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: _kBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kAccent)),
                ),
                onSubmitted: (_) => _lookup(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _lookup,
                  icon: _loading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search_rounded, size: 18),
                  label: const Text('Domain analysieren'),
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

          if (whois != null)
            _card('WHOIS / Registrar', Icons.business_rounded, const Color(0xFF29B6F6), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _row('Registrar', whois['registrar']?.toString()),
              _row('Registriert', whois['createdDate']?.toString()),
              _row('Läuft ab', whois['expiryDate']?.toString()),
              _row('Status', whois['status']?.toString()),
              if (whois['nameservers'] is List)
                _recordList('Nameserver', whois['nameservers'] as List),
            ])),

          if (dns != null) ...[
            if ((dns['a'] as List?)?.isNotEmpty ?? false)
              _card('DNS – A-Records (IPv4)', Icons.router_rounded, const Color(0xFF66BB6A), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _recordList('A-Records', dns['a'] as List),
              ])),

            if ((dns['mx'] as List?)?.isNotEmpty ?? false)
              _card('DNS – MX-Records (Mail)', Icons.mail_rounded, const Color(0xFFFFAB00), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _recordList('MX-Records', dns['mx'] as List),
              ])),

            if ((dns['txt'] as List?)?.isNotEmpty ?? false)
              _card('DNS – TXT-Records', Icons.text_snippet_rounded, const Color(0xFFAB47BC), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _recordList('TXT-Records', dns['txt'] as List),
              ])),
          ],
        ]),
      ),
    );
  }
}
