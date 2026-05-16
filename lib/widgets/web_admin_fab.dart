// 👑 WEB ADMIN FAB
// Floating Action Button für Admin-Zugang zum Web-Panel.
// Nur sichtbar auf Web + wenn web_is_admin = true in SharedPreferences.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebAdminFab extends StatefulWidget {
  const WebAdminFab({super.key});

  @override
  State<WebAdminFab> createState() => _WebAdminFabState();
}

class _WebAdminFabState extends State<WebAdminFab> {
  bool _isAdmin = false;

  static const Color _gold = Color(0xFFC9A84C);

  @override
  void initState() {
    super.initState();
    if (kIsWeb) _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final isAdmin = prefs.getBool('web_is_admin') ?? false;
    if (mounted) setState(() => _isAdmin = isAdmin);
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || !_isAdmin) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.extended(
          heroTag: 'web_admin_fab',
          onPressed: () =>
              Navigator.pushNamed(context, '/admin/web-users').then((_) {
            // Re-check admin status after returning (e.g. if logged out)
            _checkAdmin();
          }),
          backgroundColor: _gold,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.manage_accounts_rounded, size: 20),
          label: const Text(
            'Web-Zugänge',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          elevation: 4,
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'web_logout_fab',
          onPressed: _logout,
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: Colors.white54,
          tooltip: 'Ausloggen',
          child: const Icon(Icons.logout_rounded, size: 18),
        ),
      ],
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

    if (confirm != true || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('web_logged_in');
    await prefs.remove('web_user_name');
    await prefs.remove('web_is_admin');

    if (mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/', (route) => false);
    }
  }
}
