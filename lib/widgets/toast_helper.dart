import 'package:flutter/material.dart';

/// Premium Toast-Nachrichten für professionelle UX
class ToastHelper {
  /// Zeigt eine Success-Toast-Nachricht
  static void showSuccess(BuildContext context, String message) {
    _showToast(
      context,
      message,
      Icons.check_circle,
      const Color(0xFF4CAF50), // Grün
    );
  }

  /// Zeigt eine Info-Toast-Nachricht
  static void showInfo(BuildContext context, String message) {
    _showToast(
      context,
      message,
      Icons.info_outline,
      const Color(0xFF2196F3), // Blau
    );
  }

  /// Zeigt eine Warning-Toast-Nachricht
  static void showWarning(BuildContext context, String message) {
    _showToast(
      context,
      message,
      Icons.warning_amber_rounded,
      const Color(0xFFFF9800), // Orange
    );
  }

  /// Zeigt eine Error-Toast-Nachricht
  static void showError(BuildContext context, String message) {
    _showToast(
      context,
      message,
      Icons.error_outline,
      const Color(0xFFF44336), // Rot
    );
  }

  /// Interne Toast-Implementierung mit Premium-Design
  static void _showToast(
    BuildContext context,
    String message,
    IconData icon,
    Color color,
  ) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        icon: icon,
        color: color,
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss nach 3 Sekunden
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
}

/// Toast Widget mit Premium-Design
class _ToastWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color color;

  const _ToastWidget({
    required this.message,
    required this.icon,
    required this.color,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Auto-dismiss Animation
    Future.delayed(const Duration(milliseconds: 2700), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.color.withValues(alpha: 0.3),
                          widget.color.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
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
}
