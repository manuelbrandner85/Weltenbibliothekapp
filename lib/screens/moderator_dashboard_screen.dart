import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/moderation_tab.dart';

/// ═══════════════════════════════════════════════════════════════
/// MODERATOR DASHBOARD SCREEN - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// Sichtbar für: Super-Admin, Admin, Moderator
/// Features:
/// - Content-Moderation
/// - User-Verwaltung (kicken/muten)
/// - Reports ansehen
/// ═══════════════════════════════════════════════════════════════

class ModeratorDashboardScreen extends StatefulWidget {
  const ModeratorDashboardScreen({super.key});

  @override
  State<ModeratorDashboardScreen> createState() =>
      _ModeratorDashboardScreenState();
}

class _ModeratorDashboardScreenState extends State<ModeratorDashboardScreen> {
  final AuthService _authService = AuthService();

  String? _currentUserRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final user = await _authService.getCurrentUser();
      final role = user?['role'] as String?;

      if (role != 'super_admin' && role != 'admin' && role != 'moderator') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⛔ Keine Berechtigung für Moderatoren-Dashboard'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      setState(() {
        _currentUserRole = role;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.build, color: Colors.white),
            SizedBox(width: 12),
            Text('Moderatoren Dashboard'),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: const ModerationTab(),
    );
  }
}
