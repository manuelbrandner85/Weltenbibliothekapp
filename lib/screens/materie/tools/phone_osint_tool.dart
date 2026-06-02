import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/materie/osint_source_banner.dart';
import '../../../utils/osint_result_share.dart';

// ─────────────────────────────────────────────────────────────────────────────
// E — Telefon-OSINT
// ─────────────────────────────────────────────────────────────────────────────

const _kBg = Color(0xFF0D0000);
const _kSurface = Color(0xFF1A0808);
const _kAccent = Color(0xFFE53935);
const _kText = Colors.white;
const _kMuted = Color(0xFFB0A0A0);
const _kBorder = Color(0x33E53935);

class PhoneOsintTool extends StatefulWidget {
  const PhoneOsintTool({super.key});

  @override
  State<PhoneOsintTool> createState() => _PhoneOsintToolState();
}

class _PhoneOsintToolState extends State<PhoneOsintTool> {
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final number = _phoneCtrl.text.trim();
    if (number.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final uri = Uri.parse(
        '${ApiConfig.workerUrl}/api/tools/phone?number=${Uri.encodeComponent(number)}',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 20));
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['error'] != null) throw Exception(data['error'].toString());
      setState(() {
        _result = data;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
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
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: Row(children: [
          Icon(Icons.phone_in_talk_rounded, color: _kAccent, size: 22),
          const SizedBox(width: 8),
          const Text('Telefon-OSINT',
              style: TextStyle(color: _kText, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          OsintResultShare.actionButton(
            context,
            toolName: 'Telefon-OSINT',
            query: _phoneCtrl.text,
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
            const Text('Telefonnummer eingeben',
                style: TextStyle(color: _kMuted, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: _kText),
              decoration: InputDecoration(
                hintText: '+49 123 4567890',
                hintStyle: TextStyle(color: _kMuted.withValues(alpha: 0.6)),
                prefixIcon:
                    const Icon(Icons.phone_rounded, color: _kMuted, size: 18),
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
            const SizedBox(height: 4),
            const Text('Mit Ländervorwahl eingeben, z.B. +49 für Deutschland',
                style: TextStyle(color: _kMuted, fontSize: 10)),
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
                label: const Text('Nummer analysieren'),
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
            source: 'Rufnummern-Analyse (Land, Carrier, Typ) ueber den '
                'Weltenbibliothek-Worker. Keine Klarnamen-Aufloesung.',
            accent: _kAccent,
          ),
          if (_error != null)
            _card(Row(children: [
              const Icon(Icons.error_outline, color: _kAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(_error!,
                      style: const TextStyle(color: _kAccent, fontSize: 13))),
            ])),
          if (_result != null) ...[
            _card(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.flag_rounded, color: _kAccent, size: 16),
                const SizedBox(width: 6),
                const Text('Nummer-Informationen',
                    style: TextStyle(
                        color: _kAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ]),
              const SizedBox(height: 10),
              if (_result!['countryFlag'] != null &&
                  _result!['country'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Text(_result!['countryFlag'].toString(),
                        style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Text(_result!['country'].toString(),
                        style: const TextStyle(
                            color: _kText,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                  ]),
                ),
              _row('Ländercode', _result!['countryCode']?.toString()),
              _row('Vorwahl', _result!['callingCode']?.toString()),
              _row('Typ', _result!['lineType']?.toString()),
              _row('Zeitzone', _result!['timezone']?.toString()),
              _row('Kontinent', _result!['continent']?.toString()),
              _row('Formatiert', _result!['formatted']?.toString()),
            ])),
            if (_result!['prefixInfo'] != null)
              _card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Vorwahlbereich',
                        style: TextStyle(color: _kMuted, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(_result!['prefixInfo'].toString(),
                        style: const TextStyle(
                            color: _kText, fontSize: 13, height: 1.5)),
                  ])),
            _card(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Hinweis',
                  style: TextStyle(color: _kMuted, fontSize: 11)),
              const SizedBox(height: 4),
              const Text(
                'Diese Analyse basiert auf öffentlich verfügbaren Vorwahl-Daten. '
                'Genaue Anbieter- und Teilnehmer-Daten erfordern Behörden-Anfragen.',
                style: TextStyle(color: _kMuted, fontSize: 12, height: 1.5),
              ),
            ])),
          ],
        ]),
      ),
    );
  }
}
