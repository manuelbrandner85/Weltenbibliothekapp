// 🕐 WEB WAITING APPROVAL SCREEN
// Zeigt dem User dass sein Zugangsantrag noch geprüft wird.
// Prüft alle 30 Sekunden ob er freigeschaltet wurde.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/wb_cinematic_tokens.dart';
class WebWaitingApprovalScreen extends StatefulWidget {
  const WebWaitingApprovalScreen({super.key});

  @override
  State<WebWaitingApprovalScreen> createState() =>
      _WebWaitingApprovalScreenState();
}

class _WebWaitingApprovalScreenState extends State<WebWaitingApprovalScreen>
    with TickerProviderStateMixin {
  Timer? _checkTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const Color _gold = Color(0xFFC9A84C);
  static const Color _bgDark = Color(0xFF0A0A0A);

  /// Theme-aware background. Light-Mode liefert helle `context.wb.bgVoid`,
  /// Dark-Mode behält den Original-Ton.
  Color _bg(BuildContext context) {
    final wb = Theme.of(context).extension<WBCinematic>();
    return wb?.bgVoid ?? _bgDark;
  }

  @override
  void initState() {
    super.initState();

    // Puls-Animation für die Sanduhr
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.8, end: 1.0).animate(_pulseController);

    // Alle 30 Sekunden Status prüfen
    _checkTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _checkApproval());

    // Sofort einmal prüfen
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkApproval());
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkApproval() async {
    if (!mounted) return;
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final profile = await supabase
          .from('web_user_profiles')
          .select('is_approved')
          .eq('user_id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (profile != null && profile['is_approved'] == true) {
        // Freigegeben! → AuthGate aktualisiert sich automatisch via Stream
        // Trotzdem kurz warten und dann State refreshen
        setState(() {});
      }
    } catch (e) {
      // Netzwerkfehler ignorieren, nächste Prüfung in 30s
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    // WebAuthGate übernimmt automatisch nach signOut
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      body: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animierte Sanduhr
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _gold.withValues(alpha: 0.1),
                    border: Border.all(
                        color: _gold.withValues(alpha: 0.4), width: 2),
                  ),
                  child: const Icon(
                    Icons.hourglass_bottom_rounded,
                    color: _gold,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Zugang wird geprüft',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                'Dein Antrag wurde eingereicht und wird von einem Administrator geprüft.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Du wirst automatisch weitergeleitet, sobald dein Zugang freigeschaltet wurde.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),

              // Status-Anzeige
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: _gold.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Warte auf Freigabe…',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Ausloggen-Button
              TextButton(
                onPressed: _signOut,
                child: const Text(
                  'Ausloggen',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
