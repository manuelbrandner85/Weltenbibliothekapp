// 🟢 PATCH READY DIALOG – Prominenter Fullscreen-Dialog für OTA-Patches
//
// Ersetzt die alte kleine PatchReadyBanner-SnackBar, die leicht übersehen wurde.
// Wird vom UpdateGate angezeigt, sobald Shorebird einen Patch heruntergeladen
// hat, der beim nächsten App-Start aktiv wird.
//
// Verhalten:
//   - Fullscreen-Dialog mit Cyan-Akzent (Home-Dashboard-Stil)
//   - Patch-Changelog aus Supabase app_config.patch_changelog (FutureBuilder)
//   - Großer "App jetzt schließen"-Button → SystemNavigator.pop() + exit(0) Fallback
//   - "Später"-TextButton erlaubt Schließen ohne Restart
//   - barrierDismissible:false + PopScope canPop:false → User muss aktiv entscheiden

import 'dart:io' show Platform, exit;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/update_service.dart';

class PatchReadyDialog extends StatefulWidget {
  final PatchCheckResult result;

  const PatchReadyDialog({super.key, required this.result});

  /// Zeigt den prominenten Patch-Ready-Dialog.
  /// Nicht via Barrier schließbar — User muss "App schließen" oder "Später" tippen.
  static Future<void> show(BuildContext context, PatchCheckResult result) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => PopScope(
        canPop: false,
        child: PatchReadyDialog(result: result),
      ),
    );
  }

  @override
  State<PatchReadyDialog> createState() => _PatchReadyDialogState();
}

class _PatchReadyDialogState extends State<PatchReadyDialog> {
  late final Future<String?> _changelogFuture;

  @override
  void initState() {
    super.initState();
    _changelogFuture = UpdateService.instance.fetchPatchChangelog();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0A1020),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero-Icon in Cyan/Lila-Gradient
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                      blurRadius: 28,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Update bereit!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ein neues Update wurde im Hintergrund heruntergeladen und '
              'ist bereit zur Aktivierung.\n\n'
              'Bitte schließe die App und öffne sie erneut, um das Update '
              'zu aktivieren.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            // Patch-Changelog aus Supabase (wenn vorhanden)
            FutureBuilder<String?>(
              future: _changelogFuture,
              builder: (context, snap) {
                if (!snap.hasData || snap.data == null) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.list_alt_rounded,
                              color: Color(0xFF00E5FF),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Was ist neu',
                              style: TextStyle(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snap.data!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (widget.result.nextPatchNumber != null) ...[
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF00E5FF),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Patch ${widget.result.nextPatchNumber} wartet',
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 26),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => _closeApp(context),
                icon: const Icon(Icons.power_settings_new_rounded, size: 22),
                label: const Text(
                  'App jetzt schließen',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: const Color(0xFF04080F),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.6),
                minimumSize: const Size(0, 42),
              ),
              child: const Text(
                'Später',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _closeApp(BuildContext context) {
    // Android: App schließen, User öffnet sie neu → Patch wird aktiv.
    // Auf iOS ist exit() per App-Store-Policy tabu, aber wir liefern Android
    // als Sideload-APK — hier ist das akzeptabel.
    if (Platform.isAndroid) {
      SystemNavigator.pop();
      // Fallback falls SystemNavigator.pop() nicht greift:
      Future.delayed(const Duration(milliseconds: 300), () => exit(0));
    } else {
      Navigator.of(context).pop();
    }
  }
}
