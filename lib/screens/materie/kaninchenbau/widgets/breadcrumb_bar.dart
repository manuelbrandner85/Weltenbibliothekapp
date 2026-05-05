/// Smarte Breadcrumb-Bar oben — zeigt Recherche-Pfad.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'kb_design.dart';

class BreadcrumbBar extends StatelessWidget {
  final List<String> path;
  final void Function(int index) onJump;
  final VoidCallback onClose;
  final VoidCallback? onSave;
  final bool saved;

  const BreadcrumbBar({
    super.key,
    required this.path,
    required this.onJump,
    required this.onClose,
    this.onSave,
    this.saved = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        bottom: 10,
        left: 8,
        right: 8,
      ),
      decoration: BoxDecoration(
        color: KbDesign.voidBlack.withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(
            color: KbDesign.neonRed.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: Colors.white70,
            onPressed: onClose,
          ),
          const Text('🐇', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                children: [
                  for (var i = 0; i < path.length; i++) ...[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.chevron_right_rounded,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onJump(i);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: i == path.length - 1
                              ? KbDesign.neonRed.withValues(alpha: 0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: i == path.length - 1
                                ? KbDesign.neonRed.withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          path[i],
                          style: TextStyle(
                            color: i == path.length - 1
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.55),
                            fontWeight: i == path.length - 1
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (onSave != null)
            IconButton(
              icon: Icon(
                saved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: saved ? KbDesign.goldAccent : Colors.white70,
                size: 22,
              ),
              tooltip: saved ? 'Gespeichert' : 'Recherche speichern',
              onPressed: () {
                HapticFeedback.lightImpact();
                onSave!();
              },
            ),
        ],
      ),
    );
  }
}
