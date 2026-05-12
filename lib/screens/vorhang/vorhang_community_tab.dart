import 'package:flutter/material.dart';

/// 🎭 VORHANG Community Tab — Placeholder
class VorhangCommunityTab extends StatelessWidget {
  const VorhangCommunityTab({super.key});

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
            Icon(Icons.people_outline, size: 48, color: _gold.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text(
              'VORHANG COMMUNITY',
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
