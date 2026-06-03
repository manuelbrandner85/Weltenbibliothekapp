// RestrictionGate: blendet einen Bereich aus, wenn der aktuelle User dafuer
// vom Admin gesperrt wurde (siehe RestrictionGuard / user_restrictions).
//
// Verwendung: Tab-/Hub-Body mit dem passenden Scope umhuellen, z.B.
//   RestrictionGate(scope: 'spirit_tools', toolLabel: 'Spirit-Tools', child: ...)
// Solange der Status laedt, wird das Kind angezeigt (fail-open). Ist der
// Bereich gesperrt, erscheint stattdessen ein Hinweis mit Einspruch-Pfad.

import 'package:flutter/material.dart';

import '../services/restriction_guard.dart';

class RestrictionGate extends StatefulWidget {
  /// Scope-Schluessel wie in user_restrictions (z.B. 'spirit_tools').
  final String scope;

  /// Anzeigename des Bereichs fuer die Sperr-Meldung.
  final String toolLabel;

  /// Inhalt, der bei freigeschaltetem Bereich angezeigt wird.
  final Widget child;

  /// Optionaler Tap auf "Einspruch" -- fuehrt z.B. in die Profil-Einstellungen.
  final VoidCallback? onAppeal;

  const RestrictionGate({
    super.key,
    required this.scope,
    required this.toolLabel,
    required this.child,
    this.onAppeal,
  });

  @override
  State<RestrictionGate> createState() => _RestrictionGateState();
}

class _RestrictionGateState extends State<RestrictionGate> {
  @override
  void initState() {
    super.initState();
    // Status laden und neu zeichnen, sobald bekannt.
    RestrictionGuard.instance.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final restricted = RestrictionGuard.instance.isRestricted(widget.scope);
    if (!restricted) return widget.child;
    return _LockedView(toolLabel: widget.toolLabel, onAppeal: widget.onAppeal);
  }
}

class _LockedView extends StatelessWidget {
  final String toolLabel;
  final VoidCallback? onAppeal;
  const _LockedView({required this.toolLabel, this.onAppeal});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, color: Colors.redAccent, size: 56),
            const SizedBox(height: 16),
            Text(
              '$toolLabel gesperrt',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Ein Administrator hat dir den Zugriff auf diesen Bereich '
              'voruebergehend entzogen. Bei Fragen kannst du im Profil einen '
              'Einspruch einreichen.',
              style:
                  TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            if (onAppeal != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onAppeal,
                icon: const Icon(Icons.gavel_rounded, size: 18),
                label: const Text('Einspruch einreichen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
