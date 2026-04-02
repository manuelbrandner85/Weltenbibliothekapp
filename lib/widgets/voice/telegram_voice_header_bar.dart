/// 🎤 TELEGRAM VOICE HEADER BAR
/// Shows voice chat status at the top of the chat screen
/// - Active: Shows participants with speaking animations
/// - Inactive: Shows "Join Voice Chat" button
/// 
/// This is the MAIN way to access voice chat in Telegram-style
library;

import 'package:flutter/material.dart';

class TelegramVoiceHeaderBar extends StatelessWidget {
  final bool isActive;
  final List<Map<String, dynamic>> participants;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback? onJoin;

  const TelegramVoiceHeaderBar({
    super.key,
    required this.isActive,
    required this.participants,
    required this.accentColor,
    required this.onTap,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isActive ? onTap : (onJoin ?? onTap),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentColor.withValues(alpha: 0.2),
              accentColor.withValues(alpha: 0.1),
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: accentColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: isActive ? _buildActiveVoiceChat() : _buildJoinButton(),
      ),
    );
  }

  /// Active Voice Chat - Shows participants
  Widget _buildActiveVoiceChat() {
    return Row(
      children: [
        // Voice Icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: accentColor,
              width: 2,
            ),
          ),
          child: Icon(
            Icons.people,
            color: accentColor,
            size: 20,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Participants Avatars
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: participants.take(10).map((participant) {
                final isSpeaking = participant['isSpeaking'] == true;
                final isMuted = participant['isMuted'] == true;
                final avatarEmoji = participant['avatarEmoji']?.toString() ?? '👤';
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      // Avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withValues(alpha: 0.2),
                          border: Border.all(
                            color: isSpeaking
                                ? Colors.green
                                : accentColor.withValues(alpha: 0.5),
                            width: isSpeaking ? 3 : 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            avatarEmoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      
                      // Muted Indicator
                      if (isMuted)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mic_off,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      
                      // Speaking Indicator (Pulsing Animation)
                      if (isSpeaking && !isMuted)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mic,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        
        // Participant Count + Arrow
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${participants.length}',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: accentColor,
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Inactive Voice Chat - Shows Join Button
  Widget _buildJoinButton() {
    return Row(
      children: [
        // Voice Icon (Inactive)
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: accentColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.people_outline,
            color: accentColor.withValues(alpha: 0.7),
            size: 20,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Text
        Expanded(
          child: Text(
            'Voice Chat',
            style: TextStyle(
              color: accentColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // Join Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.mic,
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                'Beitreten',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
