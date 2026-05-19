// RealtimeNotificationHost -- Overlay-Widget das in-app Banner zeigt.
// Wird einmal um die MaterialApp.builder gewickelt und horcht auf
// RealtimeNotificationService.instance.stream.

import 'dart:async';

import 'package:flutter/material.dart';

import '../services/realtime_notification_service.dart';

class RealtimeNotificationHost extends StatefulWidget {
  final Widget child;

  const RealtimeNotificationHost({super.key, required this.child});

  @override
  State<RealtimeNotificationHost> createState() =>
      _RealtimeNotificationHostState();
}

class _RealtimeNotificationHostState extends State<RealtimeNotificationHost> {
  StreamSubscription<InAppNotification>? _sub;
  final List<InAppNotification> _stack = [];

  @override
  void initState() {
    super.initState();
    _sub = RealtimeNotificationService.instance.stream.listen((n) {
      if (!mounted) return;
      setState(() {
        _stack.insert(0, n);
        // Max 3 gleichzeitig sichtbar.
        if (_stack.length > 3) _stack.removeRange(3, _stack.length);
      });
      // Auto-dismiss nach 3.5s.
      Future.delayed(const Duration(milliseconds: 3500), () {
        if (!mounted) return;
        setState(() => _stack.remove(n));
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          right: 12,
          child: IgnorePointer(
            ignoring: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _stack
                  .map((n) => _NotificationBanner(
                        key: ValueKey(n.timestamp.microsecondsSinceEpoch),
                        notification: n,
                        onDismiss: () => setState(() => _stack.remove(n)),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationBanner extends StatefulWidget {
  final InAppNotification notification;
  final VoidCallback onDismiss;

  const _NotificationBanner({
    super.key,
    required this.notification,
    required this.onDismiss,
  });

  @override
  State<_NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<_NotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();
    _slide = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    return AnimatedBuilder(
      animation: _slide,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -40 * (1 - _slide.value)),
        child: Opacity(opacity: _slide.value, child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onDismiss,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0B1F).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: n.accent.withValues(alpha: 0.6), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: n.accent.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        n.accent.withValues(alpha: 0.6),
                        n.accent.withValues(alpha: 0.15),
                      ]),
                    ),
                    alignment: Alignment.center,
                    child: Icon(n.icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          n.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: n.accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        if (n.body.isNotEmpty)
                          Text(
                            n.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              height: 1.35,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.close_rounded, color: Colors.white24, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
