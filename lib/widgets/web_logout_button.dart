// 🚪 WEB LOGOUT BUTTON
// Nur auf Web sichtbar. Löscht SharedPreferences und kehrt zum Login zurück.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebLogoutButton extends StatelessWidget {
  const WebLogoutButton({super.key});

  static const Color _gold = Color(0xFFC9A84C);

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ausloggen?',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        content: const Text(
          'Du wirst vom Web-Portal abgemeldet.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen',
                style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ausloggen', style: TextStyle(color: _gold)),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('web_logged_in');
    await prefs.remove('web_user_name');
    await prefs.remove('web_is_admin');

    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: IconButton(
        icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
        tooltip: 'Ausloggen',
        onPressed: () => _logout(context),
      ),
    );
  }
}
