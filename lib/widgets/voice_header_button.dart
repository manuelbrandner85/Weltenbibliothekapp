/// 🎙️ VOICE CHAT HEADER BUTTON
/// Compact voice chat button for AppBar
/// Opens Telegram-style voice chat screen
library;

import 'package:flutter/material.dart';
import '../services/webrtc_voice_service.dart'; // ✅ UNIFIED WebRTC Service
import '../screens/shared/modern_voice_chat_screen.dart';

class VoiceHeaderButton extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String userId;
  final String username;
  final Color color;

  const VoiceHeaderButton({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.userId,
    required this.username,
    this.color = Colors.white,
  });

  @override
  State<VoiceHeaderButton> createState() => _VoiceHeaderButtonState();
}

class _VoiceHeaderButtonState extends State<VoiceHeaderButton> {
  final WebRTCVoiceService _voiceController = WebRTCVoiceService();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _voiceController,
      builder: (context, child) {
        final isInCall = _voiceController.isInCall;
        final isInThisRoom = _voiceController.currentRoomId == widget.roomId;
        final participantCount = _voiceController.participantCount;

        return Stack(
          children: [
            IconButton(
              icon: Icon(
                isInThisRoom ? Icons.mic : Icons.groups,
                color: isInThisRoom ? Colors.green : widget.color,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ModernVoiceChatScreen(
                      roomId: widget.roomId,
                      roomName: widget.roomName,
                      userId: widget.userId,
                      username: widget.username,
                      world: 'materie', // Default world
                      accentColor: widget.color,
                    ),
                  ),
                );
              },
              tooltip: isInThisRoom 
                  ? 'Im Voice-Raum ($participantCount)' 
                  : 'Voice-Chat öffnen',
            ),
            
            // Participant count badge
            if (participantCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isInThisRoom ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF121212),
                      width: 1,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$participantCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
