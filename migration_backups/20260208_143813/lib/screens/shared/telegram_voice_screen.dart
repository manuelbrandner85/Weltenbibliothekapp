/// 🎙️ SIMPLE TELEGRAM VOICE SCREEN
/// Minimalistic voice chat UI using SimpleVoiceController
library;

import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/simple_voice_controller.dart';
import '../../models/chat_models.dart';

class TelegramVoiceScreen extends StatefulWidget {
  const TelegramVoiceScreen({super.key});

  @override
  State<TelegramVoiceScreen> createState() => _TelegramVoiceScreenState();
}

class _TelegramVoiceScreenState extends State<TelegramVoiceScreen> {
  final SimpleVoiceController _voiceController = SimpleVoiceController();
  Timer? _uiUpdateTimer; // 🔧 FIX 4: Timer for UI updates

  @override
  void initState() {
    super.initState();
    print('🎙️ [TelegramVoiceScreen] Initialized');
    print('📊 [TelegramVoiceScreen] Current participants: ${_voiceController.participantCount}');
    print('🏠 [TelegramVoiceScreen] Current room: ${_voiceController.currentRoomId}');
    print('👤 [TelegramVoiceScreen] Current user: ${_voiceController.currentUserId}');
    
    // 🔧 FIX 4: Start UI update timer (10 FPS for smooth audio visualization)
    _uiUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
    
    // DEBUG: Force participant list update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        print('🔄 [TelegramVoiceScreen] Force UI refresh');
      });
    });
  }

  @override
  void dispose() {
    _uiUpdateTimer?.cancel(); // 🔧 Clean up timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: ListenableBuilder(
          listenable: _voiceController,
          builder: (context, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _voiceController.currentRoomName ?? 'Voice Chat',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_voiceController.participantCount} participants',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content - Participants Grid
            Column(
              children: [
                const SizedBox(height: 16),
                
                Expanded(
                  child: ListenableBuilder(
                    listenable: _voiceController,
                    builder: (context, child) {
                      final participants = _voiceController.participants;

                      if (participants.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off, size: 64, color: Colors.white24),
                              SizedBox(height: 16),
                              Text(
                                'No participants yet...',
                                style: TextStyle(color: Colors.white54, fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: participants.length,
                        itemBuilder: (context, index) {
                          return _buildParticipantTile(participants[index]);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

            // Bottom Controls
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute Button
                    ListenableBuilder(
                      listenable: _voiceController,
                      builder: (context, child) {
                        final isMuted = _voiceController.isMuted;
                        return _buildControlButton(
                          icon: isMuted ? Icons.mic_off : Icons.mic,
                          label: isMuted ? 'Freischalten' : 'Stumm',
                          color: isMuted ? Colors.red : Colors.green,
                          onPressed: () => _voiceController.toggleMute(),
                        );
                      },
                    ),

                    // Leave Button
                    _buildControlButton(
                      icon: Icons.call_end,
                      label: 'Verlassen',
                      color: Colors.red,
                      onPressed: () async {
                        await _voiceController.leaveVoiceRoom();
                        if (mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantTile(VoiceParticipant participant) {
    final isCurrentUser = participant.userId == _voiceController.currentUserId;
    
    // 🔧 FIX 4: Get real-time audio level & speaking state
    final audioLevel = _voiceController.getAudioLevel(participant.userId);
    final isSpeaking = _voiceController.isSpeaking(participant.userId);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSpeaking
              ? Colors.green // 🔧 Green when speaking!
              : isCurrentUser
                  ? Colors.blue
                  : Colors.transparent,
          width: isSpeaking ? 4 : 3, // 🔧 Thicker when speaking
        ),
        // 🔧 Pulsing animation when speaking
        boxShadow: isSpeaking
            ? [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 🔧 FIX 4: Audio Level Indicator (Ring around avatar)
          Stack(
            alignment: Alignment.center,
            children: [
              // Audio level ring
              if (audioLevel > 0.1)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.green.withOpacity(audioLevel),
                      width: 3,
                    ),
                  ),
                ),
              
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getColorForUser(participant.userId),
                      _getColorForUser(participant.userId).withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    participant.username[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Username
          Text(
            participant.username,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // 🔧 FIX 4: Speaking indicator
          if (isSpeaking)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mic, color: Colors.green, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Speaking',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          
          // You indicator
          if (isCurrentUser && !isSpeaking)
            Text(
              '(You)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),

          // Mute indicator
          if (participant.isMuted)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Icon(Icons.mic_off, color: Colors.red, size: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color.withValues(alpha: 0.2),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getColorForUser(String userId) {
    final colors = [
      const Color(0xFF6A5ACD),
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFFFFD93D),
      const Color(0xFF95E1D3),
      const Color(0xFFF38181),
      const Color(0xFF6C5CE7),
      const Color(0xFF00B894),
    ];

    final hash = userId.hashCode.abs();
    return colors[hash % colors.length];
  }
}
