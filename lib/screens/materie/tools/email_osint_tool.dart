import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/materie/osint_source_banner.dart';
import '../../../utils/osint_result_share.dart';

// ─────────────────────────────────────────────────────────────────────────────
// M-X3 — E-Mail Leak-Check (Datenleck-Pruefung)
// Datenquelle: XposedOrNot (kostenlos, kein API-Key).
// ─────────────────────────────────────────────────────────────────────────────

const _kBg = Color(0xFF0D0000);
const _kSurface = Color(0xFF1A0808);
const _kAccent = Color(0xFFE53935);
const _kSafe = Color(0xFF66BB6A);
const _kText = Colors.white;
const _kMuted = Color(0xFFB0A0A0);
const _kBorder = Color(0x33E53935);

class EmailOsintTool extends StatefulWidget {
  const EmailOsintTool({super.key});

  @override
  State<EmailOsintTool> createState() => _EmailOsintToolState();
}

class _EmailOsintToolState extends State<EmailOsintTool> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  static final _emailRe =
      RegExp(r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$', caseSensitive: false);

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    if (!_emailRe.hasMatch(email)) {
      setState(() => _error = 'Bitte eine gueltige E-Mail-Adresse eingeben.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final uri = Uri.parse(
          'https://api.xposedornot.com/v1/check-email/${Uri.encodeComponent(email)}');
      final resp = await http.get(uri).timeout(const Duration(seconds: 20));

      // 404 / "Not found" = keine bekannten Leaks (kein Fehler).
      final breaches = <String>[];
      try {
        final data = jsonDecode(resp.body);
        if (data is Map && data['breaches'] is List) {
          final outer = data['breaches'] as List;
          if (outer.isNotEmpty && outer.first is List) {
            for (final b in (outer.first as List)) {
              breaches.add(b.toString());
            }
          }
        }
      } catch (_) {
        // Body nicht parsebar -> als "keine Treffer" behandeln.
      }
      breaches.sort();
      setState(() {
        _result = {
          'email': email,
          'breach_count': breaches.length,
          'breaches': breaches,
        };
      });
    } catch (e) {
      setState(
          () => _error = 'Abfrage fehlgeschlagen. Bitte erneut versuchen.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _card(Widget child, {Color? border}) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border ?? _kBorder),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final r = _result;
    final count = (r?['breach_count'] as int?) ?? 0;
    final breaches = (r?['breaches'] as List?)?.cast<String>() ?? const [];
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: Row(children: [
          const Icon(Icons.mark_email_unread_rounded,
              color: _kAccent, size: 22),
          const SizedBox(width: 8),
          const Text('E-Mail Leak-Check',
              style: TextStyle(color: _kText, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          OsintResultShare.actionButton(
            context,
            toolName: 'E-Mail-Leak-Check',
            query: _emailCtrl.text,
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
            const Text('E-Mail-Adresse',
                style: TextStyle(color: _kMuted, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: _kText),
              decoration: InputDecoration(
                hintText: 'name@beispiel.de',
                hintStyle: TextStyle(color: _kMuted.withValues(alpha: 0.6)),
                prefixIcon: const Icon(Icons.alternate_email_rounded,
                    color: _kMuted, size: 18),
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
                    : const Icon(Icons.shield_outlined, size: 18),
                label: const Text('Auf Datenlecks pruefen'),
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
            source: 'Abgleich gegen oeffentlich bekannte Datenlecks ueber '
                'XposedOrNot. Negativ-Ergebnis ist keine Garantie.',
            accent: _kAccent,
            sources: [OsintSource('XposedOrNot', 'https://xposedornot.com')],
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
            if (count == 0)
              _card(
                border: _kSafe.withValues(alpha: 0.5),
                Row(children: const [
                  Icon(Icons.verified_user_rounded, color: _kSafe, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Keine bekannten Datenlecks gefunden.',
                      style: TextStyle(
                          color: _kSafe,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
              )
            else ...[
              _card(
                border: _kAccent.withValues(alpha: 0.6),
                Row(children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: _kAccent, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'In $count bekannten Datenleck(s) gefunden. '
                      'Passwoerter dieser Dienste aendern.',
                      style: const TextStyle(
                          color: _kAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.4),
                    ),
                  ),
                ]),
              ),
              _card(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Betroffene Dienste',
                      style: TextStyle(color: _kMuted, fontSize: 12)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final b in breaches)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _kAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _kAccent.withValues(alpha: 0.3)),
                          ),
                          child: Text(b,
                              style:
                                  const TextStyle(color: _kText, fontSize: 12)),
                        ),
                    ],
                  ),
                ],
              )),
            ],
          ],
        ]),
      ),
    );
  }
}
