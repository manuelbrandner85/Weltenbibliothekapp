// 🔐 WEB AUTH GATE
// Zentraler Auth-Zustandsautomat für die Web-Version.
//
// Zustände:
//   1. Kein eingeloggter User        → WebLoginScreen
//   2. Eingeloggt, noch nicht genehmigt → WebWaitingApprovalScreen
//   3. Eingeloggt und genehmigt      → PortalHomeScreen
//
// Bei erstem Web-Login wird automatisch ein Eintrag in web_user_profiles
// angelegt (is_approved=false), wenn noch keiner existiert.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../portal_home_screen.dart';
import 'web_login_screen.dart';
import 'web_waiting_approval_screen.dart';

class WebAuthGate extends StatefulWidget {
  const WebAuthGate({super.key});

  @override
  State<WebAuthGate> createState() => _WebAuthGateState();
}

class _WebAuthGateState extends State<WebAuthGate> {
  // null = Laden, false = abgelehnt/ausstehend, true = freigegeben
  bool? _approved;
  bool _checkingProfile = false;

  @override
  void initState() {
    super.initState();
    // Initiale Session prüfen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) _checkProfile(session.user);
    });

    // Auth-State-Änderungen überwachen
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedOut ||
          event == AuthChangeEvent.userDeleted) {
        setState(() => _approved = null);
        return;
      }

      if (session != null &&
          (event == AuthChangeEvent.signedIn ||
              event == AuthChangeEvent.tokenRefreshed)) {
        _checkProfile(session.user);
      }
    });
  }

  Future<void> _checkProfile(User user) async {
    if (_checkingProfile) return;
    _checkingProfile = true;

    try {
      final supabase = Supabase.instance.client;

      // Profil in web_user_profiles prüfen / anlegen
      final existing = await supabase
          .from('web_user_profiles')
          .select('is_approved')
          .eq('user_id', user.id)
          .maybeSingle();

      if (!mounted) {
        _checkingProfile = false;
        return;
      }

      if (existing == null) {
        // Erster Login auf Web → Eintrag anlegen
        await supabase.from('web_user_profiles').insert({
          'user_id': user.id,
          'email': user.email ?? '',
          'is_approved': false,
          'requested_at': DateTime.now().toIso8601String(),
        });

        // Admin-Benachrichtigung
        try {
          await supabase.from('web_admin_notifications').insert({
            'user_id': user.id,
            'email': user.email ?? '',
            'type': 'access_request',
            'message': 'Neuer Zugangsantrag von ${user.email}',
          });
        } catch (_) {}

        if (mounted) setState(() => _approved = false);
      } else {
        final approved = existing['is_approved'] as bool? ?? false;
        if (mounted) setState(() => _approved = approved);
      }
    } catch (e) {
      debugPrint('⚠️ [WebAuthGate] Profil-Check fehlgeschlagen: $e');
      if (mounted) setState(() => _approved = false);
    } finally {
      _checkingProfile = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    // Kein User eingeloggt
    if (session == null) {
      return const WebLoginScreen();
    }

    // User eingeloggt, aber Status wird noch geladen
    if (_approved == null) {
      return const _LoadingScreen();
    }

    // Freigegeben → normale App
    if (_approved == true) {
      return const PortalHomeScreen();
    }

    // Warten auf Freigabe
    return const WebWaitingApprovalScreen();
  }
}

// Lade-Bildschirm während Profil-Check
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
