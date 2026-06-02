import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/materie/osint_source_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
// B — Datenleck-Prüfer
// ─────────────────────────────────────────────────────────────────────────────

const _kBg = Color(0xFF0D0000);
const _kSurface = Color(0xFF1A0808);
const _kAccent = Color(0xFFE53935);
const _kText = Colors.white;
const _kMuted = Color(0xFFB0A0A0);
const _kBorder = Color(0x33E53935);
const _kGreen = Color(0xFF4CAF50);
const _kAmber = Color(0xFFFFB300);

class DataLeakTool extends StatefulWidget {
  const DataLeakTool({super.key});

  @override
  State<DataLeakTool> createState() => _DataLeakToolState();
}

class _DataLeakToolState extends State<DataLeakTool> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final uri = Uri.parse(
        '${ApiConfig.workerUrl}/api/tools/data-leak?email=${Uri.encodeComponent(email)}',
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

  /// Verschleiert das Passwort-Feld in einer Datenleck-Zeile
  String _obfuscateLine(String line) {
    final parts = line.split(':');
    if (parts.length >= 2) {
      final pass = parts.last;
      final stars =
          '••••${pass.length > 4 ? pass.substring(pass.length - 2) : ''}';
      return '${parts.take(parts.length - 1).join(':')}:$stars';
    }
    return line;
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

  @override
  Widget build(BuildContext context) {
    final count = _result?['count'] as int? ?? 0;
    final lines = (_result?['samples'] as List?)?.cast<String>() ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: Row(children: [
          Icon(Icons.security_rounded, color: _kAccent, size: 22),
          const SizedBox(width: 8),
          const Text('Datenleck-Prüfer',
              style: TextStyle(color: _kText, fontWeight: FontWeight.bold)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('E-Mail-Adresse prüfen',
                style: TextStyle(color: _kMuted, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: _kText),
              decoration: InputDecoration(
                hintText: 'nutzer@beispiel.de',
                hintStyle: TextStyle(color: _kMuted.withValues(alpha: 0.6)),
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
              onSubmitted: (_) => _check(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _check,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.shield_rounded, size: 18),
                label: const Text('Auf Datenlecks prüfen'),
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
          OsintSourceBanner(
            source: 'Pruefung gegen bekannte Datenleck-Sammlungen ueber den '
                'Weltenbibliothek-Worker. Passwoerter werden nie im '
                'Klartext gesendet. ',
            accent: _kAccent,
            sources: [
              OsintSource('Have I Been Pwned', 'https://haveibeenpwned.com'),
            ],
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
            // Ergebnis-Banner
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: count == 0
                    ? _kGreen.withValues(alpha: 0.1)
                    : _kAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: count == 0
                        ? _kGreen.withValues(alpha: 0.4)
                        : _kAccent.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                Icon(
                  count == 0
                      ? Icons.check_circle_rounded
                      : Icons.warning_rounded,
                  color: count == 0 ? _kGreen : _kAccent,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                        count == 0
                            ? 'Keine Treffer gefunden'
                            : '$count Einträge gefunden',
                        style: TextStyle(
                          color: count == 0 ? _kGreen : _kAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        count == 0
                            ? 'Diese E-Mail wurde in keinem bekannten Datenleck gefunden.'
                            : 'Diese E-Mail erscheint in Datenleck-Datenbanken.',
                        style: const TextStyle(color: _kMuted, fontSize: 12),
                      ),
                    ])),
              ]),
            ),

            if (lines.isNotEmpty)
              _card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.list_alt_rounded, color: _kAmber, size: 16),
                      const SizedBox(width: 6),
                      const Text('Beispiel-Einträge (Passwörter verschleiert)',
                          style: TextStyle(color: _kMuted, fontSize: 12)),
                    ]),
                    const SizedBox(height: 8),
                    ...lines.take(10).map((line) => Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _kBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _kBorder),
                          ),
                          child: Text(
                            _obfuscateLine(line),
                            style: const TextStyle(
                                color: _kText,
                                fontSize: 11,
                                fontFamily: 'monospace'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                  ])),

            if (count > 0)
              _card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.tips_and_updates_rounded,
                          color: _kAmber, size: 16),
                      const SizedBox(width: 6),
                      const Text('Empfehlungen',
                          style: TextStyle(
                              color: _kAmber,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ]),
                    const SizedBox(height: 8),
                    const Text(
                      '• Ändere sofort das Passwort auf den betroffenen Webseiten.\n'
                      '• Nutze für jede Webseite ein anderes, starkes Passwort.\n'
                      '• Aktiviere Zwei-Faktor-Authentifizierung (2FA) wo möglich.\n'
                      '• Prüfe Deine E-Mails auf verdächtige Aktivitäten.\n'
                      '• Nutze einen Passwort-Manager (z.B. Bitwarden, KeePass).',
                      style:
                          TextStyle(color: _kMuted, fontSize: 13, height: 1.6),
                    ),
                  ])),
          ],
        ]),
      ),
    );
  }
}
