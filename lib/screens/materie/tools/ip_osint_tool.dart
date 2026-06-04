import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/materie/osint_source_banner.dart';
import '../../../utils/osint_result_share.dart';

// ─────────────────────────────────────────────────────────────────────────────
// M-X2 — IP / ASN-Lookup (Geolocation, ISP, ASN)
// Datenquelle: ipwho.is (kostenlos, kein API-Key, HTTPS).
// ─────────────────────────────────────────────────────────────────────────────

const _kBg = Color(0xFF0D0000);
const _kSurface = Color(0xFF1A0808);
const _kAccent = Color(0xFFE53935);
const _kText = Colors.white;
const _kMuted = Color(0xFFB0A0A0);
const _kBorder = Color(0x33E53935);

class IpOsintTool extends StatefulWidget {
  const IpOsintTool({super.key});

  @override
  State<IpOsintTool> createState() => _IpOsintToolState();
}

class _IpOsintToolState extends State<IpOsintTool> {
  final _ipCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _ipCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final ip = _ipCtrl.text.trim();
    if (ip.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      // ipwho.is accepts both IPv4/IPv6 and bare domains.
      final uri = Uri.parse('https://ipwho.is/${Uri.encodeComponent(ip)}');
      final resp = await http.get(uri).timeout(const Duration(seconds: 20));
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['success'] == false) {
        throw Exception(data['message']?.toString() ?? 'IP nicht gefunden');
      }
      setState(() => _result = data);
    } catch (e) {
      setState(() => _error = 'Abfrage fehlgeschlagen. Bitte IP pruefen.');
    } finally {
      setState(() => _loading = false);
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

  Widget _row(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(color: _kMuted, fontSize: 12))),
        Expanded(
            child: Text(value,
                style: const TextStyle(color: _kText, fontSize: 13))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    final conn = r?['connection'] as Map<String, dynamic>?;
    final tz = r?['timezone'] as Map<String, dynamic>?;
    final flag = r?['flag'] as Map<String, dynamic>?;
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: Row(children: [
          const Icon(Icons.travel_explore_rounded, color: _kAccent, size: 22),
          const SizedBox(width: 8),
          const Text('IP / ASN-Lookup',
              style: TextStyle(color: _kText, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          OsintResultShare.actionButton(
            context,
            toolName: 'IP-OSINT',
            query: _ipCtrl.text,
            result: _result,
            color: _kAccent,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('IP-Adresse oder Domain',
                style: TextStyle(color: _kMuted, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _ipCtrl,
              keyboardType: TextInputType.url,
              style: const TextStyle(color: _kText),
              decoration: InputDecoration(
                hintText: '8.8.8.8 oder example.com',
                hintStyle: TextStyle(color: _kMuted.withValues(alpha: 0.6)),
                prefixIcon:
                    const Icon(Icons.lan_rounded, color: _kMuted, size: 18),
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
              onSubmitted: (_) => _lookup(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _lookup,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.search_rounded, size: 18),
                label: const Text('IP analysieren'),
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
            source: 'Live-Geolokalisierung, ISP und ASN ueber ipwho.is. '
                'Standort ist auf Stadt-/Provider-Ebene genau, nicht hausgenau.',
            accent: _kAccent,
            sources: [OsintSource('ipwho.is', 'https://ipwho.is')],
          ),
          if (_error != null)
            _card(Row(children: [
              const Icon(Icons.error_outline, color: _kAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(_error!,
                      style: const TextStyle(color: _kAccent, fontSize: 13))),
            ])),
          if (r != null) ...[
            _card(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (flag?['emoji'] != null)
                  Text(flag!['emoji'].toString(),
                      style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    [r['city'], r['region'], r['country']]
                        .where((e) => e != null && e.toString().isNotEmpty)
                        .join(', '),
                    style: const TextStyle(
                        color: _kText,
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              _row('IP', r['ip']?.toString()),
              _row('Typ', r['type']?.toString()),
              _row('Land', r['country']?.toString()),
              _row('Region', r['region']?.toString()),
              _row('Stadt', r['city']?.toString()),
              _row('PLZ', r['postal']?.toString()),
              _row(
                  'Koordinaten',
                  (r['latitude'] != null && r['longitude'] != null)
                      ? '${r['latitude']}, ${r['longitude']}'
                      : null),
            ])),
            if (conn != null)
              _card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: const [
                      Icon(Icons.dns_rounded, color: _kAccent, size: 16),
                      SizedBox(width: 6),
                      Text('Netzwerk / Provider',
                          style: TextStyle(
                              color: _kAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ]),
                    const SizedBox(height: 10),
                    _row(
                        'ASN', conn['asn'] != null ? 'AS${conn['asn']}' : null),
                    _row('Organisation', conn['org']?.toString()),
                    _row('ISP', conn['isp']?.toString()),
                    _row('Domain', conn['domain']?.toString()),
                  ])),
            if (tz != null)
              _card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Zeitzone',
                        style: TextStyle(color: _kMuted, fontSize: 12)),
                    const SizedBox(height: 8),
                    _row('Zone', tz['id']?.toString()),
                    _row('UTC-Offset', tz['utc']?.toString()),
                  ])),
          ],
        ]),
      ),
    );
  }
}
