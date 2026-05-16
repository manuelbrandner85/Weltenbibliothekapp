// 👑 WEB ADMIN FAB
// FloatingActionButton — nur sichtbar auf Web + wenn web_is_admin=true.
// Navigiert zum Web-Admin-Panel.

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

    return FloatingActionButton.extended(
      heroTag: 'web_admin_fab',
      onPressed: () => Navigator.pushNamed(context, '/admin/web-users')
          .then((_) => _checkAdmin()),
      backgroundColor: _gold,
      foregroundColor: Colors.black,
      icon: const Icon(Icons.admin_panel_settings_rounded, size: 20),
      label: const Text(
        'Web-Zugänge',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      elevation: 4,
    );
  }
}
