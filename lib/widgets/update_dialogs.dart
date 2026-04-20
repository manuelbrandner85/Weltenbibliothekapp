// 🟢 UPDATE DIALOGS – UI für In-App-Update-Meldungen
//
// - [ReleaseUpdateDialog]: kompakte Legacy-Dialog-Variante für neue APK
//   (aktuell wird stattdessen der Fullscreen [ReleaseUpdateScreen] verwendet).
//
// HINWEIS: Der frühere [PatchReadyBanner] (kleine SnackBar für OTA-Patches)
// wurde ab v5.36.0 entfernt. Patch-Benachrichtigungen laufen jetzt über
// den prominenten [PatchReadyDialog] in patch_ready_dialog.dart.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/update_service.dart';

// ---------------------------------------------------------------------------
// Release-Update-Dialog (neue APK) – Legacy/Kompakt-Variante
// ---------------------------------------------------------------------------

class ReleaseUpdateDialog extends StatelessWidget {
  final UpdateCheckResult info;

  const ReleaseUpdateDialog({super.key, required this.info});

  /// Zeigt den Dialog. Bei Force-Update ist er nicht abbrechbar.
  static Future<void> show(BuildContext context, UpdateCheckResult info) {
    return showDialog(
      context: context,
      barrierDismissible: !info.isForced,
      useRootNavigator: true,
      builder: (_) => PopScope(
        canPop: !info.isForced,
        child: ReleaseUpdateDialog(info: info),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = info.isForced
        ? 'Update erforderlich'
        : 'Neue Version verfügbar';
    final subtitle = info.latestVersion != null
        ? 'Version ${info.latestVersion} ist bereit zum Download.'
        : 'Eine neue Version ist verfügbar.';

    return Dialog(
      backgroundColor: const Color(0xFF0A1020),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF2979FF), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2979FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color:
                            const Color(0xFF2979FF).withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.system_update,
                      color: Color(0xFF00E5FF), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (info.currentVersion != null)
              _VersionRow(
                current: info.currentVersion!,
                latest: info.latestVersion ?? '—',
              ),
            if ((info.changelog ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Was ist neu?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  info.changelog!,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      height: 1.4),
                ),
              ),
            ],
            if (info.isForced) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color:
                          const Color(0xFFE53935).withValues(alpha: 0.35)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFE53935), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Diese Version wird nicht mehr unterstützt. Bitte aktualisiere, um die App weiter zu nutzen.',
                        style: TextStyle(
                            color: Color(0xFFE53935),
                            fontSize: 12,
                            height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!info.isForced)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Später',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7))),
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _openDownload(context, info.apkDownloadUrl),
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: const Text('Jetzt herunterladen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2979FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDownload(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download-Link konnte nicht geöffnet werden.'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
    }
  }
}

class _VersionRow extends StatelessWidget {
  final String current;
  final String latest;
  const _VersionRow({required this.current, required this.latest});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _pill('Installiert', current, Colors.white.withValues(alpha: 0.15)),
        const SizedBox(width: 10),
        const Icon(Icons.arrow_forward, color: Color(0xFF00E5FF), size: 18),
        const SizedBox(width: 10),
        _pill('Neu', latest, const Color(0xFF2979FF).withValues(alpha: 0.25)),
      ],
    );
  }

  Widget _pill(String label, String value, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
