import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/webrtc_voice_service.dart';
import '../models/chat_models.dart';

/// 🎙️ TELEGRAM-STYLE VOICE PANEL
/// Floating panel with participants, raise hand, and live indicators
class TelegramVoicePanel extends StatefulWidget {
  final String roomId;
  final String userId;
  final String username;
  final Color accentColor;
  final VoidCallback? onLeave;

  const TelegramVoicePanel({
    super.key,
    required this.roomId,
    required this.userId,
    required this.username,
    this.accentColor = Colors.blue,
    this.onLeave,
  });

  @override
  State<TelegramVoicePanel> createState() => _TelegramVoicePanelState();
}

class _TelegramVoicePanelState extends State<TelegramVoicePanel>
    with TickerProviderStateMixin {
  final WebRTCVoiceService _voiceService = WebRTCVoiceService();
  
  bool _isMuted = false;
  bool _isExpanded = false;
  bool _handRaised = false;
  List<VoiceParticipant> _participants = [];
  
  late AnimationController _speakingController;
  late AnimationController _handController;
  StreamSubscription<List<VoiceParticipant>>? _participantsSubscription;

  @override
  void initState() {
    super.initState();
    
    _speakingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    
    _handController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _joinVoiceChat();
    
    // Listen to participants
    _participantsSubscription = _voiceService.participantsStream.listen((participants) {
      if (mounted) {
        setState(() {
          _participants = participants;
        });
      }
    });
  }

  @override
  void dispose() {
    _speakingController.dispose();
    _handController.dispose();
    _participantsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _joinVoiceChat() async {
    try {
      await _voiceService.joinVoiceRoom(
        widget.roomId,
        widget.userId,
        widget.username,
      );
    } catch (e) {
      debugPrint('❌ Failed to join voice chat: $e');
    }
  }

  Future<void> _toggleMute() async {
    HapticFeedback.lightImpact();
    setState(() => _isMuted = !_isMuted);
    await _voiceService.toggleMute();
  }

  Future<void> _toggleRaiseHand() async {
    HapticFeedback.mediumImpact();
    setState(() => _handRaised = !_handRaised);
    
    if (_handRaised) {
      _handController.forward();
      await _voiceService.raiseHand(widget.userId);
    } else {
      _handController.reverse();
      await _voiceService.lowerHand(widget.userId);
    }
  }

  Future<void> _leaveVoiceChat() async {
    HapticFeedback.heavyImpact();
    await _voiceService.leaveVoiceRoom();
    widget.onLeave?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isExpanded ? 400 : 80,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (always visible)
          _buildHeader(),
          
          // Expanded content
          if (_isExpanded) ...[
            const Divider(color: Colors.white12, height: 1),
            Expanded(child: _buildParticipantsList()),
            const Divider(color: Colors.white12, height: 1),
            _buildControls(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Voice indicator
            Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing ring when speaking
                if (!_isMuted)
                  AnimatedBuilder(
                    animation: _speakingController,
                    builder: (context, child) {
                      return Container(
                        width: 56 + (_speakingController.value * 12),
                        height: 56 + (_speakingController.value * 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.accentColor.withValues(
                              alpha: 0.3 - (_speakingController.value * 0.3),
                            ),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),
                
                // Main circle
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        widget.accentColor,
                        widget.accentColor.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Icon(
                    _isMuted ? Icons.mic_off : Icons.mic,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
            
            const SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Voice Chat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_participants.length} participant${_participants.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Expand indicator
            Icon(
              _isExpanded ? Icons.expand_more : Icons.expand_less,
              color: Colors.white60,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _participants.length,
      itemBuilder: (context, index) {
        final participant = _participants[index];
        final isOwn = participant.userId == widget.userId;
        final isSpeaking = participant.isSpeaking;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Avatar with speaking indicator
              Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.accentColor.withValues(alpha: 0.2),
                      border: isSpeaking
                          ? Border.all(color: widget.accentColor, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        participant.username.isNotEmpty
                            ? participant.username[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  // Raised hand indicator
                  if (participant.handRaised)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Text('✋', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(width: 12),
              
              // Name
              Expanded(
                child: Text(
                  '${participant.username}${isOwn ? ' (You)' : ''}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: isOwn ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              
              // Status icons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (participant.isMuted)
                    Icon(
                      Icons.mic_off,
                      size: 16,
                      color: Colors.white38,
                    ),
                  
                  if (participant.role == VoiceRole.moderator)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 16,
                        color: Colors.amber,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute/Unmute
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            label: _isMuted ? 'Unmute' : 'Mute',
            color: _isMuted ? Colors.red : widget.accentColor,
            onTap: _toggleMute,
          ),
          
          // Raise Hand
          _buildControlButton(
            icon: Icons.back_hand,
            label: _handRaised ? 'Lower' : 'Raise',
            color: _handRaised ? Colors.orange : Colors.white24,
            onTap: _toggleRaiseHand,
          ),
          
          // Leave
          _buildControlButton(
            icon: Icons.call_end,
            label: 'Leave',
            color: Colors.red,
            onTap: _leaveVoiceChat,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
