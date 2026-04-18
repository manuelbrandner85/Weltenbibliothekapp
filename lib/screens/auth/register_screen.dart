import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;
  bool _obscure = true;
  String _selectedWorld = 'materie';

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; _success = null; });

    try {
      await SupabaseAuthService.instance.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        username: _usernameCtrl.text.trim(),
        world: _selectedWorld,
      );
      if (mounted) {
        setState(() {
          _success = 'Registrierung erfolgreich! Bitte bestätige deine E-Mail.';
          _loading = false;
        });
      }
    } on AuthException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Registrieren', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Konto erstellen',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Username
                  TextFormField(
                    controller: _usernameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Benutzername', Icons.person_outline),
                    validator: (v) => (v == null || v.trim().length < 3)
                        ? 'Mindestens 3 Zeichen'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // E-Mail
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('E-Mail', Icons.email_outlined),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Gültige E-Mail eingeben'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Passwort
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Passwort', Icons.lock_outlined).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white54,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Mindestens 6 Zeichen'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Passwort bestätigen
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _obscure,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Passwort bestätigen', Icons.lock_outlined),
                    validator: (v) => v != _passwordCtrl.text
                        ? 'Passwörter stimmen nicht überein'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Welt wählen
                  Row(
                    children: [
                      const Text('Welt:', style: TextStyle(color: Colors.white70)),
                      const SizedBox(width: 16),
                      _worldChip('materie', '⚔️ Materie', const Color(0xFFE53935)),
                      const SizedBox(width: 8),
                      _worldChip('energie', '✨ Energie', const Color(0xFF7C4DFF)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (_error != null)
                    _messageBox(_error!, Colors.red),
                  if (_success != null)
                    _messageBox(_success!, Colors.green),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Registrieren', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _worldChip(String value, String label, Color color) {
    final selected = _selectedWorld == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedWorld = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(color: selected ? color : Colors.white24),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: selected ? color : Colors.white54)),
      ),
    );
  }

  Widget _messageBox(String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(message, style: TextStyle(color: color)),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF1A1A2E),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2A4E)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1976D2)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent),
    );
  }
}
