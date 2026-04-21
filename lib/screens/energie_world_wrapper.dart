import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/roles.dart';
import 'energie_world_screen.dart';
import '../services/achievement_service.dart';
import 'shared/world_admin_dashboard.dart';

/// Energie-Welt-Wrapper
/// Admin-Check direkt über Supabase profiles.role (nicht OpenClaw).
class EnergieWorldWrapper extends StatefulWidget {
  const EnergieWorldWrapper({super.key});

  @override
  State<EnergieWorldWrapper> createState() => _EnergieWorldWrapperState();
}

class _EnergieWorldWrapperState extends State<EnergieWorldWrapper> {
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoad();
    _trackWorldVisit();
  }

  Future<void> _checkAdminAndLoad() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 8));
        if (profile != null) {
          final role = profile['role'] as String? ?? AppRoles.user;
          _isAdmin = AppRoles.isAdmin(role);
          if (kDebugMode) {
            debugPrint('👑 ENERGIE ADMIN-CHECK: $_isAdmin (role: $role)');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Energie Admin-Check error: $e');
      _isAdmin = false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _trackWorldVisit() async {
    try {
      await AchievementService().incrementProgress('world_traveler');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.purple),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('ENERGIE', style: TextStyle(color: Colors.purple)),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF4A148C).withValues(alpha: 0.3),
                Colors.black,
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
          ),
        ),
      );
    }

    if (_isAdmin) {
      if (kDebugMode) debugPrint('👑 ENERGIE → Admin Dashboard');
      return const WorldAdminDashboard(world: 'energie');
    }

    return const EnergieWorldScreen();
  }
}
