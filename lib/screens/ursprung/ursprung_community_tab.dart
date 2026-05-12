import 'package:flutter/material.dart';

/// 🌀 URSPRUNG Community Tab — Placeholder
class UrsprungCommunityTab extends StatelessWidget {
  const UrsprungCommunityTab({super.key});

  static const _cyan = Color(0xFF00D4AA);
  static const _bgDeep = Color(0xFF050510);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgDeep,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: _cyan.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text(
              'URSPRUNG COMMUNITY',
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
                color: _cyan.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
