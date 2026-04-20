import 'package:flutter/material.dart';

/// Floating-Button „↓ N neue Nachrichten".
///
/// Wird eingeblendet, wenn der Nutzer nicht am unteren Ende der Liste ist
/// und neue Nachrichten eingetroffen sind. Tippen scrollt runter und
/// resettet den Zähler.
class ChatNewMessagesFab extends StatelessWidget {
  const ChatNewMessagesFab({
    super.key,
    required this.visible,
    required this.count,
    required this.onTap,
    this.color = const Color(0xFF7C4DFF),
  });

  final bool visible;
  final int count;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 1.5),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: Material(
          color: color,
          elevation: 4,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.keyboard_arrow_down,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    count > 0
                        ? '$count neue Nachricht${count == 1 ? '' : 'en'}'
                        : 'Zum Ende',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
