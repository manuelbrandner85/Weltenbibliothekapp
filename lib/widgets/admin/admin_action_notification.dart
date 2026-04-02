/// ADMIN ACTION NOTIFICATION
/// Vollbild-Overlay das angezeigt wird wenn ein User von Admin-Aktionen betroffen ist
/// 
/// Features:
/// - Kicked Notification (mit Cooldown Timer)
/// - Muted Notification (Admin Lock)
/// - Banned Notification (mit Dauer)
/// - Warning Notification (mit Counter)
library;

import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/admin_action.dart';

enum AdminNotificationType {
  kicked,
  muted,
  unmuted,
  banned,
  warned,
}

class AdminActionNotification extends StatefulWidget {
  final AdminNotificationType type;
  final String? reason;
  final String? adminUsername;
  final BanDuration? banDuration;
  final DateTime? expiresAt;
  final int? warningCount;
  final VoidCallback? onDismiss;
  final VoidCallback? onExpiry;
  
  const AdminActionNotification({
    super.key,
    required this.type,
    this.reason,
    this.adminUsername,
    this.banDuration,
    this.expiresAt,
    this.warningCount,
    this.onDismiss,
    this.onExpiry,
  });

  @override
  State<AdminActionNotification> createState() => _AdminActionNotificationState();
}

class _AdminActionNotificationState extends State<AdminActionNotification> {
  Timer? _countdownTimer;
  Duration? _remainingTime;
  
  @override
  void initState() {
    super.initState();
    
    // Start countdown for temporary bans/kicks
    if (widget.expiresAt != null) {
      _updateRemainingTime();
      _countdownTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _updateRemainingTime(),
      );
    }
  }
  
  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
  
  void _updateRemainingTime() {
    if (widget.expiresAt == null) return;
    
    final now = DateTime.now();
    if (now.isAfter(widget.expiresAt!)) {
      _countdownTimer?.cancel();
      widget.onExpiry?.call();
      return;
    }
    
    setState(() {
      _remainingTime = widget.expiresAt!.difference(now);
    });
  }
  
  String get _remainingTimeText {
    if (_remainingTime == null) return '';
    
    final hours = _remainingTime!.inHours;
    final minutes = _remainingTime!.inMinutes % 60;
    final seconds = _remainingTime!.inSeconds % 60;
    
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${seconds}s';
    }
  }
  
  Map<String, dynamic> get _notificationConfig {
    switch (widget.type) {
      case AdminNotificationType.kicked:
        return {
          'icon': Icons.exit_to_app,
          'color': Colors.red,
          'title': 'Aus Voice Chat entfernt',
          'message': widget.reason != null
              ? 'Du wurdest aus dem Voice Chat entfernt.\n\nGrund: ${widget.reason}'
              : 'Du wurdest aus dem Voice Chat entfernt.',
          'footer': widget.expiresAt != null
              ? 'Du kannst in $_remainingTimeText wieder beitreten.'
              : null,
        };
        
      case AdminNotificationType.muted:
        return {
          'icon': Icons.mic_off,
          'color': Colors.orange,
          'title': 'Vom Admin stummgeschaltet',
          'message': widget.reason != null
              ? 'Du wurdest vom Admin stummgeschaltet.\n\nGrund: ${widget.reason}'
              : 'Du wurdest vom Admin stummgeschaltet.',
          'footer': 'Dein Mikrofon wurde gesperrt. Nur ein Admin kann dich wieder freischalten.',
        };
        
      case AdminNotificationType.unmuted:
        return {
          'icon': Icons.mic,
          'color': Colors.green,
          'title': 'Stummschaltung aufgehoben',
          'message': 'Ein Admin hat deine Stummschaltung aufgehoben. Du kannst jetzt wieder sprechen.',
          'footer': null,
        };
        
      case AdminNotificationType.banned:
        final isPermanent = widget.banDuration == BanDuration.permanent;
        return {
          'icon': Icons.block,
          'color': Colors.red.shade900,
          'title': isPermanent ? 'Permanent gebannt' : 'Temporär gebannt',
          'message': widget.reason != null
              ? 'Du wurdest vom Admin gebannt.\n\nGrund: ${widget.reason}'
              : 'Du wurdest vom Admin gebannt.',
          'footer': isPermanent
              ? 'Dieser Ban ist permanent. Du kannst nicht mehr am Chat teilnehmen.'
              : widget.expiresAt != null
                  ? 'Ban endet in: $_remainingTimeText'
                  : null,
        };
        
      case AdminNotificationType.warned:
        final count = widget.warningCount ?? 1;
        final isLastWarning = count >= 3;
        return {
          'icon': Icons.warning_amber_rounded,
          'color': isLastWarning ? Colors.red : Colors.orange,
          'title': isLastWarning ? '⚠️ LETZTE VERWARNUNG!' : 'Verwarnung erhalten',
          'message': widget.reason != null
              ? 'Du hast eine Verwarnung vom Admin erhalten.\n\nGrund: ${widget.reason}\n\nVerwarnungen: $count/3'
              : 'Du hast eine Verwarnung vom Admin erhalten.\n\nVerwarnungen: $count/3',
          'footer': isLastWarning
              ? '🚫 Bei der nächsten Verwarnung wirst du automatisch für 24 Stunden gebannt!'
              : 'Bei 3 Verwarnungen erfolgt ein automatischer 24-Stunden-Ban.',
        };
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final config = _notificationConfig;
    final canDismiss = widget.type == AdminNotificationType.unmuted || 
                       widget.type == AdminNotificationType.warned;
    
    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (config['color'] as Color).withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (config['color'] as Color).withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: (config['color'] as Color).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      config['icon'] as IconData,
                      color: config['color'] as Color,
                      size: 40,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    config['title'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: config['color'] as Color,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Message
                  Text(
                    config['message'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  
                  // Admin Info
                  if (widget.adminUsername != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Von: ${widget.adminUsername}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  
                  // Footer
                  if (config['footer'] != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (config['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (config['color'] as Color).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: config['color'] as Color,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              config['footer'] as String,
                              style: TextStyle(
                                color: (config['color'] as Color).withValues(alpha: 0.9),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Dismiss Button (only for certain types)
                  if (canDismiss) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onDismiss?.call();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: config['color'] as Color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Verstanden',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Show admin notification
void showAdminNotification(
  BuildContext context, {
  required AdminNotificationType type,
  String? reason,
  String? adminUsername,
  BanDuration? banDuration,
  DateTime? expiresAt,
  int? warningCount,
  VoidCallback? onDismiss,
  VoidCallback? onExpiry,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AdminActionNotification(
      type: type,
      reason: reason,
      adminUsername: adminUsername,
      banDuration: banDuration,
      expiresAt: expiresAt,
      warningCount: warningCount,
      onDismiss: onDismiss,
      onExpiry: onExpiry,
    ),
  );
}
