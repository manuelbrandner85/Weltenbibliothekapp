import 'package:flutter/material.dart';

/// Q3: Einheitlicher Empty-State fuer "keine Daten"-Situationen.
///
/// Ersetzt uneinheitliche Center(Column([Icon, Text]))-Bloecke durch
/// ein konsistentes, ruhiges Layout. Optional mit Aktion (z.B. "Neu laden").
///
/// ```dart
/// WBEmptyState(
///   icon: Icons.bookmark_border,
///   title: 'Noch keine Lesezeichen',
///   message: 'Markierte Inhalte erscheinen hier.',
/// )
/// ```
class WBEmptyState extends StatelessWidget {
  const WBEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.accent,
    this.compact = false,
  });

  /// Symbol oben (z.B. Icons.inbox).
  final IconData icon;

  /// Kurze Hauptzeile (deutsche UI-Sprache).
  final String title;

  /// Optionale erklaerende zweite Zeile.
  final String? message;

  /// Optionaler Aktions-Button (z.B. "Erneut laden").
  final Widget? action;

  /// Akzentfarbe; default dezentes Weiss.
  final Color? accent;

  /// true = kleineres Layout fuer enge Bereiche.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Colors.white;
    final iconSize = compact ? 40.0 : 64.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 14 : 20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.06),
                border: Border.all(color: color.withValues(alpha: 0.15)),
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: color.withValues(alpha: 0.55),
              ),
            ),
            SizedBox(height: compact ? 12 : 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color.withValues(alpha: 0.9),
                fontSize: compact ? 15 : 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color.withValues(alpha: 0.5),
                  fontSize: compact ? 12 : 13,
                  height: 1.4,
                ),
              ),
            ],
            if (action != null) ...[
              SizedBox(height: compact ? 14 : 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
