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

import '../services/restart_service.dart';
import '../services/update_service.dart';
import '../utils/changelog_translator.dart';

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
            const SizedBox(height: 10),
            Text(
              'Ein neues Update ist startklar — beim Neustart aktivieren wir '
              'die Verbesserungen und Fehler-Fixes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            // Friendly-Changelog: Kategorisierte, übersetzte Liste
            FutureBuilder<String?>(
              future: _changelogFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: _ChangelogSkeleton(),
                  );
                }
                if (!snap.hasData ||
                    snap.data == null ||
                    snap.data!.trim().isEmpty) {
                  return const SizedBox.shrink();
                }
                final friendly = parseFriendlyChangelog(snap.data!);
                if (friendly.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF00E5FF)
                            .withValues(alpha: 0.22),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded,
                                color: Color(0xFF00E5FF), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Was ist neu',
                              style: TextStyle(
                                color: const Color(0xFF00E5FF)
                                    .withValues(alpha: 0.95),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Kategorien
                        ConstrainedBox(
                          constraints:
                              const BoxConstraints(maxHeight: 240),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: friendly.categories
                                  .where((c) => !c.isEmpty)
                                  .map((c) => _CategoryBlock(category: c))
                                  .toList(),
                            ),
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
                  'App neu starten',
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

  Future<void> _closeApp(BuildContext context) async {
    if (Platform.isAndroid) {
      final handled = await RestartService.restartApp();
      if (!handled) {
        SystemNavigator.pop();
        await Future.delayed(const Duration(milliseconds: 300));
        exit(0);
      }
    } else {
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

// ── Friendly-Changelog: Kategorie-Block ────────────────────────────────────

class _CategoryBlock extends StatelessWidget {
  final ChangelogCategory category;
  const _CategoryBlock({required this.category});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kategorie-Header
          Row(
            children: [
              Text(
                category.emoji,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 6),
              Text(
                category.title,
                style: TextStyle(
                  color: category.color.withValues(alpha: 0.95),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${category.items.length}',
                  style: TextStyle(
                    color: category.color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Items
          ...category.items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 4, top: 3, bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6, right: 8),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Loading-Skeleton ───────────────────────────────────────────────────────

class _ChangelogSkeleton extends StatelessWidget {
  const _ChangelogSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF00E5FF).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(3, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7))),
              const SizedBox(width: 8),
              Container(
                height: 12,
                width: 140.0 - i * 20,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }
}
