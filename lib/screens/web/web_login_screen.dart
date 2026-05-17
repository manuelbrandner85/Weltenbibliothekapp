// 🌐 WEB LOGIN SCREEN v2
// Name-only Zugang für Web-User. Kein Passwort für reguläre User.
// Admin-Trigger: Name "Weltenbibliothek" (case-insensitive) → Passwort-Feld.
// Login-State wird in SharedPreferences (localStorage auf Web) gespeichert.
//
// 🔐 SICHERHEIT: Admin-Passwort wird server-seitig im Worker validiert
// (env.ROOT_ADMIN_PASSWORD). KEIN hardcoded Passwort im Client mehr.

import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/api_config.dart';

class WebLoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const WebLoginScreen({super.key, this.onLoginSuccess});

  @override
  State<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _loading = false;
  bool _showPassword = false;
  bool _isAdminMode = false;
  bool _passwordVisible = false;
  String? _errorMessage;
  String? _successMessage;

  late AnimationController _passwordAnim;
  late Animation<double> _passwordHeight;
  late Animation<double> _passwordOpacity;

  static const String _adminName = 'Weltenbibliothek';
  // ⚠️ KEIN _adminPassword mehr im Client — Worker validiert server-seitig
  // via env.ROOT_ADMIN_PASSWORD. Client schickt PW an /api/profile/materie,
  // Worker antwortet 200 (OK) oder 403 (Falsches PW).

  static const Color _gold = Color(0xFFC9A84C);
  static const Color _goldLight = Color(0xFFE0C872);
  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _surface = Color(0xFF141414);
  static const Color _border = Color(0xFF2A2A2A);

  @override
  void initState() {
    super.initState();
    _passwordAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _passwordHeight = Tween<double>(begin: 0, end: 110).animate(
      CurvedAnimation(parent: _passwordAnim, curve: Curves.easeOutCubic),
    );
    _passwordOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _passwordAnim, curve: Curves.easeOutCubic),
    );

    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    final name = _nameController.text.trim();
    final shouldShowPassword =
        name.toLowerCase() == _adminName.toLowerCase();

    if (shouldShowPassword != _isAdminMode) {
      setState(() {
        _isAdminMode = shouldShowPassword;
        _showPassword = shouldShowPassword;
        _errorMessage = null;
      });
      if (shouldShowPassword) {
        _passwordAnim.forward();
      } else {
        _passwordAnim.reverse();
        _passwordController.clear();
      }
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _passwordFocus.dispose();
    _passwordAnim.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!mounted) return;
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Bitte gib deinen Namen ein.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    // Admin-Login — Passwort wird SERVER-SEITIG vom Worker validiert.
    if (_isAdminMode) {
      final pw = _passwordController.text;
      if (pw.isEmpty) {
        setState(() {
          _errorMessage = 'Passwort eingeben.';
          _loading = false;
        });
        return;
      }
      try {
        // Worker /api/profile/materie validiert PW + setzt role=root_admin
        // (via DB-Trigger auto_set_admin_role bei username=Weltenbibliothek).
        // Bei falschem PW: HTTP 403 mit {"success":false,"error":"..."}.
        final res = await http
            .post(
              Uri.parse('${ApiConfig.workerUrl}/api/profile/materie'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'username': _adminName,
                'password': pw,
                'world': 'materie',
              }),
            )
            .timeout(const Duration(seconds: 10));
        Map<String, dynamic> data = const {};
        try {
          data = jsonDecode(res.body) as Map<String, dynamic>;
        } catch (_) {}
        if (res.statusCode != 200 || data['success'] != true) {
          final msg = (data['error'] as String?) ?? 'Falsches Passwort.';
          setState(() {
            _errorMessage = msg;
            _loading = false;
          });
          return;
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Login fehlgeschlagen — Netzwerk prüfen.';
          _loading = false;
        });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('web_logged_in', true);
      await prefs.setString('web_user_name', _adminName);
      await prefs.setBool('web_is_admin', true);

      if (!mounted) return;
      setState(() => _loading = false);
      widget.onLoginSuccess?.call();
      return;
    }

    // Regulärer User: Supabase-Check
    try {
      final supabase = Supabase.instance.client;

      final existing = await supabase
          .from('web_access_requests')
          .select('status')
          .eq('display_name', name)
          .maybeSingle();

      if (!mounted) return;

      if (existing == null) {
        setState(() {
          _errorMessage =
              'Kein Zugang für "$name" gefunden. Beantrage zuerst einen Zugang.';
          _loading = false;
        });
        return;
      }

      final status = existing['status'] as String? ?? 'pending';

      if (status == 'approved') {
        // last_login_at aktualisieren
        try {
          await supabase
              .from('web_access_requests')
              .update({'last_login_at': DateTime.now().toIso8601String()})
              .eq('display_name', name);
        } catch (_) {}

        if (!mounted) return;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('web_logged_in', true);
        await prefs.setString('web_user_name', name);
        await prefs.setBool('web_is_admin', false);

        if (!mounted) return;
        setState(() => _loading = false);
        widget.onLoginSuccess?.call();
      } else if (status == 'pending') {
        setState(() {
          _errorMessage =
              'Dein Zugang ist noch nicht freigeschaltet.\nEin Administrator prüft deinen Antrag.';
          _loading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Dein Zugangsantrag wurde abgelehnt. Bitte kontaktiere einen Administrator.';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Verbindungsfehler. Bitte versuche es erneut.';
        _loading = false;
      });
    }
  }

  Future<void> _requestAccess() async {
    if (!mounted) return;
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Bitte gib deinen Namen ein.');
      return;
    }

    if (name.toLowerCase() == _adminName.toLowerCase()) {
      setState(() =>
          _errorMessage = 'Dieser Name ist reserviert.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;

      final existing = await supabase
          .from('web_access_requests')
          .select('status')
          .eq('display_name', name)
          .maybeSingle();

      if (!mounted) return;

      if (existing != null) {
        final status = existing['status'] as String? ?? 'pending';
        if (status == 'pending') {
          setState(() {
            _errorMessage =
                'Ein Antrag für "$name" ist bereits gestellt und wird geprüft.';
            _loading = false;
          });
        } else if (status == 'approved') {
          setState(() {
            _errorMessage =
                '"$name" ist bereits freigeschaltet. Klicke auf "Eintreten".';
            _loading = false;
          });
        } else {
          setState(() {
            _errorMessage =
                'Der Antrag für "$name" wurde abgelehnt. Wähle einen anderen Namen.';
            _loading = false;
          });
        }
        return;
      }

      await supabase.from('web_access_requests').insert({
        'display_name': name,
        'status': 'pending',
        'requested_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      setState(() {
        _loading = false;
        _successMessage =
            'Antrag für "$name" wurde eingereicht!\nEin Administrator schaltet dich frei.';
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('unique') || msg.contains('duplicate')) {
        setState(() {
          _errorMessage =
              'Der Name "$name" ist bereits vergeben. Wähle einen anderen.';
          _loading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Fehler beim Antrag stellen. Bitte versuche es erneut.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(kIsWeb, 'WebLoginScreen ist nur für Web.');

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
                const Icon(Icons.auto_stories_rounded, color: _gold, size: 56),
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

                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Name
                      _buildLabel('Dein Name'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _nameController,
                        focusNode: _nameFocus,
                        hint: 'Wie heißt du?',
                        icon: Icons.person_outline_rounded,
                        onSubmitted: (_) => _isAdminMode
                            ? _passwordFocus.requestFocus()
                            : _login(),
                      ),
                      const SizedBox(height: 4),
                      if (_isAdminMode)
                        const Padding(
                          padding: EdgeInsets.only(left: 2),
                          child: Text(
                            '🔑 Admin-Zugang erkannt',
                            style: TextStyle(
                              color: _gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      // Animiertes Passwort-Feld (nur für Admin)
                      AnimatedBuilder(
                        animation: _passwordAnim,
                        builder: (context, child) {
                          return SizedBox(
                            height: _passwordHeight.value,
                            child: Opacity(
                              opacity: _passwordOpacity.value,
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            _buildLabel('Admin-Passwort'),
                            const SizedBox(height: 6),
                            _buildTextField(
                              controller: _passwordController,
                              focusNode: _passwordFocus,
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
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Fehlermeldung
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

                      // Erfolgsmeldung
                      if (_successMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.green.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline,
                                  color: Colors.greenAccent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _successMessage!,
                                  style: const TextStyle(
                                      color: Colors.greenAccent, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Buttons
                      if (_loading)
                        const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              color: _gold,
                              strokeWidth: 2.5,
                            ),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _gold,
                                foregroundColor: Colors.black,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Eintreten',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                            if (!_isAdminMode) ...[
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: _requestAccess,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _goldLight,
                                  side:
                                      const BorderSide(color: _gold, width: 1),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text(
                                  'Zugang beantragen',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                ),
                              ),
                            ],
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
    FocusNode? focusNode,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffix,
    ValueChanged<String>? onSubmitted,
  }) =>
      TextField(
        controller: controller,
        focusNode: focusNode,
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
