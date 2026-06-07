// WBToast — kurze, non-blocking Bestätigungen.
//
// Material SnackBars sind oft zu groß und blockieren das untere Drittel
// der App. WBToast zeigt eine kompakte Pille mittig-unten die nach
// 1.5s wegfadet. Im Web hat sie zusätzlich `pointer-events: none` durch
// IgnorePointer, damit Clicks dahinter durchgehen.
//
// Verwendung:
//   WBToast.success(context, 'XP gewonnen');
//   WBToast.error(context, 'Hat nicht geklappt');
//   WBToast.info(context, 'Synchronisiert');

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

class WBToast {
  static OverlayEntry? _current;

  static void success(BuildContext context, String message) =>
      _show(context, message, _ToastKind.success);
  static void error(BuildContext context, String message) =>
      _show(context, message, _ToastKind.error);
  static void info(BuildContext context, String message) =>
      _show(context, message, _ToastKind.info);

  static void _show(BuildContext context, String message, _ToastKind kind) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    _current?.remove();
    final entry = OverlayEntry(
      builder: (ctx) => _ToastView(message: message, kind: kind),
    );
    _current = entry;
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (_current == entry) {
        try {
          entry.remove();
        } catch (e) { if (kDebugMode) debugPrint('wb_toast: silent catch -> $e'); }
        _current = null;
      }
    });
  }
}

enum _ToastKind { success, error, info }

class _ToastView extends StatefulWidget {
  final String message;
  final _ToastKind kind;
  const _ToastView({required this.message, required this.kind});

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _ctrl.reverse();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.kind) {
      case _ToastKind.success:
        return const Color(0xFF4CAF50);
      case _ToastKind.error:
        return const Color(0xFFE53935);
      case _ToastKind.info:
        return const Color(0xFFC9A84C);
    }
  }

  IconData get _icon {
    switch (widget.kind) {
      case _ToastKind.success:
        return Icons.check_circle_rounded;
      case _ToastKind.error:
        return Icons.error_rounded;
      case _ToastKind.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Positioned(
      left: 0,
      right: 0,
      bottom: mq.padding.bottom + 60,
      child: IgnorePointer(
        child: Center(
          child: SlideTransition(
            position: _offset,
            child: FadeTransition(
              opacity: _opacity,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  constraints: const BoxConstraints(maxWidth: 320),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D1A).withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _color.withValues(alpha: 0.6)),
                    boxShadow: [
                      BoxShadow(
                        color: _color.withValues(alpha: 0.3),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_icon, color: _color, size: 18),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          widget.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
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
        ),
      ),
    );
  }
}
