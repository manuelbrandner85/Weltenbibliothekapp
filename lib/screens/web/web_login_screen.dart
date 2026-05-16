// 🌐 WEB LOGIN SCREEN
// Anmeldung für die Web-Version der Weltenbibliothek.
// Nur freigegebene User (is_approved=true) erhalten Zugang.
// Neue User können Zugang beantragen – ein Admin muss sie freischalten.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WebLoginScreen extends StatefulWidget {
  const WebLoginScreen({super.key});

  @override
  State<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;
  bool _passwordVisible = false;

  // Goldfarbe für Akzente
  static const Color _gold = Color(0xFFC9A84C);
  static const Color _goldLight = Color(0xFFE0C872);
  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _surface = Color(0xFF141414);
  static const Color _surfaceBorder = Color(0xFF2A2A2A);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!mounted) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Bitte E-Mail und Passwort eingeben.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;

      // Anmelden
      await supabase.auth.signInWithPassword(email: email, password: password);

      if (!mounted) return;

      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Anmeldung fehlgeschlagen.');

      // Freigabe prüfen
      final profile = await supabase
          .from('web_user_profiles')
          .select('is_approved')
          .eq('user_id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (profile == null || profile['is_approved'] != true) {
        // Nicht freigeschaltet → abmelden und Fehlermeldung
        await supabase.auth.signOut();
        setState(() {
          _errorMessage =
              'Dein Zugang wurde noch nicht freigeschaltet. Bitte warte auf die Freigabe durch einen Administrator.';
          _loading = false;
        });
        return;
      }

      // Erfolgreich → WebAuthGate übernimmt die Navigation
      setState(() => _loading = false);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _friendlyAuthError(e.message);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Fehler bei der Anmeldung: ${e.toString()}';
        _loading = false;
      });
    }
  }

  Future<void> _requestAccess() async {
    if (!mounted) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() =>
          _errorMessage = 'Bitte E-Mail und Passwort eingeben, um Zugang zu beantragen.');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Passwort muss mindestens 6 Zeichen haben.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;

      // Registrieren (Supabase sendet Bestätigungs-E-Mail)
      final response = await supabase.auth.signUp(email: email, password: password);

      if (!mounted) return;

      final user = response.user;
      if (user == null) {
        setState(() {
          _errorMessage = 'Registrierung fehlgeschlagen. Versuche es erneut.';
          _loading = false;
        });
        return;
      }

      // Profil anlegen (is_approved=false)
      await supabase.from('web_user_profiles').upsert({
        'user_id': user.id,
        'email': email,
        'is_approved': false,
        'requested_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      // Admin-Benachrichtigung
      await supabase.from('web_admin_notifications').insert({
        'user_id': user.id,
        'email': email,
        'type': 'access_request',
        'message': 'Neuer Zugangsantrag von $email',
      });

      if (!mounted) return;

      // Abmelden (wartet auf Admin-Freigabe)
      await supabase.auth.signOut();

      setState(() {
        _loading = false;
        _errorMessage = null;
      });

      if (mounted) {
        _showSuccessDialog(email);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      // User existiert möglicherweise schon
      if (e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('already been registered')) {
        setState(() {
          _errorMessage =
              'Diese E-Mail ist bereits registriert. Bitte melde dich an oder warte auf die Freigabe.';
          _loading = false;
        });
      } else {
        setState(() {
          _errorMessage = _friendlyAuthError(e.message);
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Fehler: ${e.toString()}';
        _loading = false;
      });
    }
  }

  void _showSuccessDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _gold, width: 1),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: _gold, size: 28),
            SizedBox(width: 12),
            Text('Antrag gesendet',
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Text(
          'Dein Zugangsantrag wurde eingereicht.\n\n'
          'Ein Administrator wird deinen Antrag prüfen und dich unter $email benachrichtigen.\n\n'
          'Sobald du freigeschaltet bist, kannst du dich hier einloggen.',
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Verstanden', style: TextStyle(color: _gold)),
          ),
        ],
      ),
    );
  }

  String _friendlyAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login') || lower.contains('invalid credentials')) {
      return 'E-Mail oder Passwort ist falsch.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Bitte bestätige zuerst deine E-Mail-Adresse.';
    }
    if (lower.contains('too many')) {
      return 'Zu viele Versuche. Bitte warte kurz.';
    }
    if (lower.contains('network')) {
      return 'Netzwerkfehler. Bitte Verbindung prüfen.';
    }
    return 'Anmeldung fehlgeschlagen: $message';
  }

  @override
  Widget build(BuildContext context) {
    // Nur auf Web rendern – auf anderen Plattformen unsichtbar
    assert(kIsWeb, 'WebLoginScreen darf nur auf Web verwendet werden');

    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo / Titel
                const SizedBox(height: 16),
                const Icon(
                  Icons.auto_stories_rounded,
                  color: _gold,
                  size: 56,
                ),
                const SizedBox(height: 20),
                const Text(
                  'WELTENBIBLIOTHEK',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _gold,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Wissens- & Bewusstseins-Plattform',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 48),

                // Login-Formular
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _surfaceBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // E-Mail
                      _buildLabel('E-Mail'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _emailController,
                        hint: 'deine@email.de',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        onSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 16),

                      // Passwort
                      _buildLabel('Passwort'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _passwordController,
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        obscureText: !_passwordVisible,
                        suffix: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white38,
                            size: 18,
                          ),
                          onPressed: () => setState(
                              () => _passwordVisible = !_passwordVisible),
                        ),
                        onSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 24),

                      // Fehleranzeige
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.redAccent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                      color: Colors.redAccent, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Login-Button
                      _loading
                          ? const Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  color: _gold,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _gold,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Einloggen',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: _requestAccess,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _goldLight,
                                    side: const BorderSide(
                                        color: _gold, width: 1),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Zugang beantragen',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Zugang nur für eingeladene Mitglieder',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF555555), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffix,
    ValueChanged<String>? onSubmitted,
  }) =>
      TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onSubmitted: onSubmitted,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF555555)),
          prefixIcon: Icon(icon, color: Colors.white38, size: 18),
          suffixIcon: suffix,
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _gold, width: 1.5),
          ),
        ),
      );
}
