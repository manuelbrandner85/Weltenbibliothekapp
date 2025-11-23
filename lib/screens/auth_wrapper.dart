import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../main.dart';

/// ═══════════════════════════════════════════════════════════════
/// AUTH WRAPPER - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// Prüft beim App-Start, ob User eingeloggt ist
/// - Wenn ja → MainScreen
/// - Wenn nein → LoginScreen
/// ═══════════════════════════════════════════════════════════════

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isChecking = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      final user = await _authService.getCurrentUser();

      if (mounted) {
        setState(() {
          _isAuthenticated = user != null;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF8B5CF6)),
              SizedBox(height: 24),
              Text(
                'Weltenbibliothek',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _isAuthenticated ? const MainScreen() : const LoginScreen();
  }
}
