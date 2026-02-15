/// 🎙️ VOICE CHAT BUTTON
/// Telegram-style voice chat button for live chat screens
library;

import 'package:flutter/material.dart';
import '../services/webrtc_voice_service.dart'; // ✅ UNIFIED WebRTC Service
import '../screens/shared/telegram_voice_screen.dart';

class VoiceChatButton extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String userId;
  final String username;
  final Color color;

  const VoiceChatButton({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.userId,
    required this.username,
    this.color = const Color(0xFF34C759), // Default green
  });

  @override
  State<VoiceChatButton> createState() => _VoiceChatButtonState();
}

class _VoiceChatButtonState extends State<VoiceChatButton> {
  final WebRTCVoiceService _voiceController = WebRTCVoiceService();
  bool _isJoining = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _voiceController,
      builder: (context, child) {
        final isInCall = _voiceController.isInCall;
        final isInThisRoom = _voiceController.currentRoomId == widget.roomId;
        final participantCount = _voiceController.participantCount;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleTap(isInCall, isInThisRoom),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with pulsing animation
                  if (_isJoining)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                      ),
                    )
                  else
                    Icon(
                      isInThisRoom ? Icons.groups : Icons.groups_outlined,
                      color: widget.color,
                      size: 20,
                    ),
                  const SizedBox(width: 8),
                  // Text
                  Text(
                    _getButtonText(isInCall, isInThisRoom, participantCount),
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getButtonText(bool isInCall, bool isInThisRoom, int count) {
    if (_isJoining) return 'Beitrete...';
    if (isInThisRoom) return '$count im Voice-Chat';
    return 'Voice-Chat beitreten';
  }

  Future<void> _handleTap(bool isInCall, bool isInThisRoom) async {
    if (_isJoining) return;

    // Already in this room's call -> Open Voice Screen
    if (isInThisRoom) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const TelegramVoiceScreen(),
        ),
      );
      return;
    }

    // In a different room's call -> Ask to switch
    if (isInCall) {
      final shouldSwitch = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Voice-Raum wechseln?'),
          content: Text(
            'Du bist bereits in einem anderen Voice-Chat. '
            'Möchtest du diesen verlassen und "${widget.roomName}" beitreten?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: widget.color),
              child: const Text('Wechseln'),
            ),
          ],
        ),
      );

      if (shouldSwitch != true) return;
    }

    // Join voice chat
    setState(() => _isJoining = true);

    try {
      // STEP 1: Init microphone if not already done
      if (_voiceController.localStream == null) {
        final micSuccess = await _voiceController.initMicrophone();
        if (!micSuccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Mikrofon-Zugriff verweigert'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // STEP 2: Join room
      final success = await _voiceController.joinVoiceRoom(
        widget.roomId,
        widget.roomName,
        widget.userId,
        widget.username,
      );

      if (success && mounted) {
        // Open Voice Screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const TelegramVoiceScreen(),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fehler beim Beitritt zum Voice-Chat. Bitte erneut versuchen.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }
}

/// Voice Chat Banner (for top of chat screens)
class VoiceChatBanner extends StatelessWidget {
  final String roomId;
  final String roomName;
  final String userId;
  final String username;
  final Color color;

  const VoiceChatBanner({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.userId,
    required this.username,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                'Gruppen-Voice-Chat verfügbar',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Trete bei und diskutiere in Echtzeit mit anderen',
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          VoiceChatButton(
            roomId: roomId,
            roomName: roomName,
            userId: userId,
            username: username,
            color: color,
          ),
        ],
      ),
    );
  }
}
