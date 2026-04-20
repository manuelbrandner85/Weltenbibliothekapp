// 🟢 UPDATE SUCCESS BANNER – Grüne Erfolgsmeldung nach Patch/Version-Update
//
// Erscheint kurz nach App-Start wenn ein OTA-Patch oder eine neue APK-Version
// erfolgreich aktiviert wurde. Animiert von oben ein, verschwindet nach 4s.
// Tapping schließt es sofort.

import 'package:flutter/material.dart';

import '../services/update_confirmation_service.dart';

class UpdateSuccessBanner extends StatefulWidget {
  final UpdateConfirmationResult result;

  const UpdateSuccessBanner({super.key, required this.result});

  @override
  State<UpdateSuccessBanner> createState() => _UpdateSuccessBannerState();
}

class _UpdateSuccessBannerState extends State<UpdateSuccessBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    _ctrl.forward();
    // Nach 4 Sekunden automatisch ausblenden
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _dismiss();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (!mounted) return;
    _ctrl.reverse();
  }

  String get _message {
    if (widget.result.type == UpdateConfirmationType.version) {
      return 'App auf v${widget.result.currentVersion} aktualisiert ✓';
    }
    if (widget.result.currentPatch != null) {
      return 'Patch ${widget.result.currentPatch} erfolgreich aktiviert ✓';
    }
    return 'Update erfolgreich aktiviert ✓';
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D2E1A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF00C853).withValues(alpha: 0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C853).withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF00C853),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.close_rounded,
                    color: Colors.white.withValues(alpha: 0.4),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
