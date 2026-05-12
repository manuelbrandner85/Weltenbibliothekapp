import 'package:flutter/material.dart';

/// 🎭 VORHANG Research Tab — Placeholder
class VorhangResearchTab extends StatelessWidget {
  const VorhangResearchTab({super.key});

  static const _gold = Color(0xFFC9A84C);
  static const _bgBlack = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgBlack,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, size: 48, color: _gold.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text(
              'VORHANG WISSEN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w300,
                letterSpacing: 4.0,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kommt bald...',
              style: TextStyle(
                fontSize: 13,
                color: _gold.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
