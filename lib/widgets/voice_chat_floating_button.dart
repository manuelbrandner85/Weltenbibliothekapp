/// 🎤 WELTENBIBLIOTHEK - VOICE CHAT FLOATING BUTTON
/// Floating voice chat controls that work across all screens
/// Features: Join/leave, mute/unmute, participant list, quality indicator

import 'package:flutter/material.dart';
import '../services/webrtc_voice_service.dart';

class VoiceChatFloatingButton extends StatefulWidget {
  const VoiceChatFloatingButton({Key? key}) : super(key: key);

  @override
  State<VoiceChatFloatingButton> createState() => _VoiceChatFloatingButtonState();
}

class _VoiceChatFloatingButtonState extends State<VoiceChatFloatingButton> 
    with SingleTickerProviderStateMixin {
  final WebRTCVoiceService _voiceService = WebRTCVoiceService();
  late AnimationController _pulseController;
  
  VoiceConnectionState _state = VoiceConnectionState.disconnected;
  List<VoiceParticipant> _participants = [];
  bool _isMuted = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _voiceService.stateStream.listen((state) {
      if (mounted) {
        setState(() => _state = state);
      }
    });
    
    _voiceService.participantsStream.listen((participants) {
      if (mounted) {
        setState(() => _participants = participants);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_state == VoiceConnectionState.disconnected) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      bottom: 80,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Participant list (when expanded)
          if (_isExpanded && _participants.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(maxWidth: 250),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${_participants.length + 1} Teilnehmer',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  ..._participants.map((p) => _buildParticipantTile(p)).toList(),
                  _buildParticipantTile(VoiceParticipant(
                    userId: 'me',
                    username: 'Du',
                    isMuted: _voiceService.isMuted,
                  )),
                ],
              ),
            ),
          
          // Main floating button
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getStateColor().withValues(
                        alpha: 0.3 + (_pulseController.value * 0.3),
                      ),
                      blurRadius: 20 + (_pulseController.value * 10),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  heroTag: 'voice_chat',
                  backgroundColor: _getStateColor(),
                  onPressed: _toggleExpanded,
                  child: Icon(
                    _getStateIcon(),
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          
          // Quick controls (when expanded)
          if (_isExpanded) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mute button
                FloatingActionButton.small(
                  heroTag: 'voice_mute',
                  backgroundColor: _voiceService.isMuted
                      ? Colors.red
                      : Colors.grey[300],
                  onPressed: () async {
                    await _voiceService.toggleMute();
                    setState(() {
                      _isMuted = _voiceService.isMuted;
                    });
                  },
                  child: Icon(
                    _voiceService.isMuted ? Icons.mic_off : Icons.mic,
                    color: _voiceService.isMuted
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Leave button
                FloatingActionButton.small(
                  heroTag: 'voice_leave',
                  backgroundColor: Colors.red,
                  onPressed: () async {
                    await _voiceService.leaveRoom();
                    setState(() => _isExpanded = false);
                  },
                  child: const Icon(
                    Icons.call_end,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }

  Widget _buildParticipantTile(VoiceParticipant participant) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 12,
            backgroundColor: participant.isMuted
                ? Colors.grey
                : Colors.green,
            child: Text(
              participant.username[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Name
          Expanded(
            child: Text(
              participant.username,
              style: TextStyle(
                fontSize: 12,
                color: participant.isMuted
                    ? Colors.grey
                    : Colors.black87,
              ),
            ),
          ),
          
          // Status icon
          Icon(
            participant.isMuted ? Icons.mic_off : Icons.mic,
            size: 14,
            color: participant.isMuted ? Colors.red : Colors.green,
          ),
        ],
      ),
    );
  }

  Color _getStateColor() {
    switch (_state) {
      case VoiceConnectionState.connecting:
        return Colors.orange;
      case VoiceConnectionState.connected:
        return Colors.green;
      case VoiceConnectionState.error:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStateIcon() {
    switch (_state) {
      case VoiceConnectionState.connecting:
        return Icons.connecting_airports;
      case VoiceConnectionState.connected:
        return Icons.phone_in_talk;
      case VoiceConnectionState.error:
        return Icons.error;
      default:
        return Icons.phone;
    }
  }
}
