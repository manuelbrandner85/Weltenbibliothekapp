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
              'Tippe auf "App neu starten" – die App startet automatisch neu '
              'und das Update wird sofort aktiv.',
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
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: _ChangelogSkeleton(),
                  );
                }
                if (!snap.hasData || snap.data == null || snap.data!.trim().isEmpty) {
                  return const SizedBox.shrink();
                }
                final items = _parseChangelog(snap.data!);
                if (items.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                            const Icon(Icons.auto_awesome_rounded,
                                color: Color(0xFF00E5FF), size: 14),
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
                        const SizedBox(height: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 160),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: items
                                  .map((e) => _ChangelogItem(entry: e))
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

// ── Changelog-Parsing ──────────────────────────────────────────────────────

class _ChangelogEntry {
  final IconData icon;
  final Color color;
  final String text;
  const _ChangelogEntry({required this.icon, required this.color, required this.text});
}

List<_ChangelogEntry> _parseChangelog(String raw) {
  final lines = raw
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  return lines.map((line) {
    // Erkennt "type(scope): beschreibung" oder "type: beschreibung"
    final typeMatch = RegExp(r'^(\w+)(?:\([^)]*\))?:\s*(.+)$').firstMatch(line);
    if (typeMatch != null) {
      final type = typeMatch.group(1)!.toLowerCase();
      final description = typeMatch.group(2)!;
      final (icon, color) = _iconForType(type);
      return _ChangelogEntry(
        icon: icon,
        color: color,
        text: _capitalize(description),
      );
    }
    // Kein Präfix → allgemeine Änderung
    return _ChangelogEntry(
      icon: Icons.circle_rounded,
      color: const Color(0xFF00E5FF),
      text: _capitalize(line),
    );
  }).toList();
}

(IconData, Color) _iconForType(String type) {
  switch (type) {
    case 'feat':
    case 'feature':
      return (Icons.auto_awesome_rounded, Color(0xFF69F0AE)); // Grün
    case 'fix':
    case 'bugfix':
      return (Icons.build_circle_rounded, Color(0xFF40C4FF)); // Blau
    case 'style':
    case 'ui':
      return (Icons.palette_rounded, Color(0xFFE040FB)); // Lila
    case 'perf':
      return (Icons.speed_rounded, Color(0xFFFFD740)); // Gelb
    case 'security':
      return (Icons.shield_rounded, Color(0xFFFF6E40)); // Orange
    case 'refactor':
      return (Icons.recycling_rounded, Color(0xFF80DEEA)); // Cyan
    case 'docs':
      return (Icons.description_rounded, Color(0xFFB0BEC5)); // Grau
    default:
      return (Icons.check_circle_rounded, Color(0xFF00E5FF)); // Standard
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// ── Changelog-Item Widget ──────────────────────────────────────────────────

class _ChangelogItem extends StatelessWidget {
  final _ChangelogEntry entry;
  const _ChangelogItem({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(entry.icon, color: entry.color, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
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
