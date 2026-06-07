// PWA-Install-Hint — Web-only Banner mit Tipp zur Installation.
//
// Erscheint nur auf Flutter Web. Mobile-App ignoriert. Einmal pro Session
// verworfen (SharedPreferences mit Session-Token gespeichert). Zeigt
// die Browser-spezifischen Schritte nicht — verlässt sich auf den
// Browser-Install-Button im Menü.
//
// Bewusst kein dart:js_interop / beforeinstallprompt — minimaler
// Aufwand bei maximalem Hinweis-Wert. Kann in einer Iteration später
// auf programmatischen Prompt aufgerüstet werden.

import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PwaInstallHint extends StatefulWidget {
  const PwaInstallHint({super.key});

  @override
  State<PwaInstallHint> createState() => _PwaInstallHintState();
}

class _PwaInstallHintState extends State<PwaInstallHint> {
  static const _prefKey = 'pwa_install_hint_dismissed';
  bool _show = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) _check();
  }

  Future<void> _check() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getBool(_prefKey) ?? false;
      if (!dismissed && mounted) setState(() => _show = true);
    } catch (e) { if (kDebugMode) debugPrint('pwa_install_hint: silent catch -> $e'); }
  }

  Future<void> _dismiss() async {
    setState(() => _show = false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
    } catch (e) { if (kDebugMode) debugPrint('pwa_install_hint: silent catch -> $e'); }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || !_show) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF00D4AA).withValues(alpha: 0.16),
              const Color(0xFF00D4AA).withValues(alpha: 0.04),
            ],
          ),
          border: Border.all(
            color: const Color(0xFF00D4AA).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.install_mobile_rounded,
                color: Color(0xFF00D4AA), size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Tipp: Im Browser-Menü kannst du die App installieren — '
                'läuft dann wie eine native App.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              icon: const Icon(Icons.close_rounded,
                  size: 16, color: Colors.white38),
              onPressed: _dismiss,
            ),
          ],
        ),
      ),
    );
  }
}
