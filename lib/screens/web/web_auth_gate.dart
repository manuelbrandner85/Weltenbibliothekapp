// 🔐 WEB AUTH GATE v2
// SharedPreferences-basierter Auth-Check — kein Supabase Auth.
// Zustände:
//   null  = Laden (prüft SharedPreferences)
//   false = Nicht eingeloggt → WebLoginScreen
//   true  = Eingeloggt → PortalHomeScreen

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../portal_home_screen.dart';
import 'web_login_screen.dart';

class WebAuthGate extends StatefulWidget {
  const WebAuthGate({super.key});

  @override
  State<WebAuthGate> createState() => _WebAuthGateState();
}

class _WebAuthGateState extends State<WebAuthGate> {
  bool? _loggedIn;

  @override
  void initState() {
    super.initState();
    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('web_logged_in') ?? false;

    if (!loggedIn) {
      if (mounted) setState(() => _loggedIn = false);
      return;
    }

    final name = prefs.getString('web_user_name') ?? '';
    final isAdmin = prefs.getBool('web_is_admin') ?? false;

    // Admin braucht keinen DB-Check
    if (isAdmin) {
      if (mounted) setState(() => _loggedIn = true);
      return;
    }

    // Regulärer User: prüfen ob noch approved in DB
    try {
      final existing = await Supabase.instance.client
          .from('web_access_requests')
          .select('status')
          .eq('display_name', name)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      if (!mounted) return;

      final status = existing?['status'] as String? ?? 'pending';
      if (status == 'approved') {
        setState(() => _loggedIn = true);
      } else {
        // Zugang widerrufen oder abgelehnt → ausloggen
        await prefs.remove('web_logged_in');
        await prefs.remove('web_user_name');
        await prefs.remove('web_is_admin');
        if (mounted) setState(() => _loggedIn = false);
      }
    } catch (e) {
      // Bei Fehler eingeloggt lassen (offline-friendly)
      if (mounted) setState(() => _loggedIn = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loggedIn == null) return const _LoadingScreen();
    if (_loggedIn == true) return const PortalHomeScreen();
    return WebLoginScreen(onLoginSuccess: _checkLoginState);
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: Color(0xFFC9A84C),
                strokeWidth: 2.5,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Zugang wird geprüft…',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
