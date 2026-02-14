/// 🎙️ VOICE PARTICIPANTS PANEL
/// Bottom sheet showing participants list with statistics
library;

import 'package:flutter/material.dart';
import '../models/chat_models.dart';
import '../../services/webrtc_voice_service.dart'; // ✅ UNIFIED WebRTC Service

class VoiceParticipantsPanel extends StatefulWidget {
  final SimpleVoiceController voiceController;

  const VoiceParticipantsPanel({
    super.key,
    required this.voiceController,
  });

  @override
  State<VoiceParticipantsPanel> createState() => _VoiceParticipantsPanelState();
}

class _VoiceParticipantsPanelState extends State<VoiceParticipantsPanel> {
  DateTime? _joinTime;
  
  @override
  void initState() {
    super.initState();
    _joinTime = DateTime.now();
  }

  String _formatDuration() {
    if (_joinTime == null) return '0:00';
    final duration = DateTime.now().difference(_joinTime!);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.people, color: Colors.purple),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Teilnehmer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ListenableBuilder(
                        listenable: widget.voiceController,
                        builder: (context, child) {
                          return Text(
                            '${widget.voiceController.participantCount} im Voice Chat',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Statistics
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.timer,
                  label: 'Dauer',
                  value: _formatDuration(),
                ),
                _buildStatItem(
                  icon: Icons.signal_cellular_alt,
                  label: 'Qualität',
                  value: 'Gut',
                  color: Colors.green,
                ),
                ListenableBuilder(
                  listenable: widget.voiceController,
                  builder: (context, child) {
                    final isMuted = widget.voiceController.isMuted;
                    return _buildStatItem(
                      icon: isMuted ? Icons.mic_off : Icons.mic,
                      label: 'Mikrofon',
                      value: isMuted ? 'Aus' : 'An',
                      color: isMuted ? Colors.red : Colors.green,
                    );
                  },
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Teilnehmerliste',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Participants List
          Flexible(
            child: ListenableBuilder(
              listenable: widget.voiceController,
              builder: (context, child) {
                final participants = widget.voiceController.participants;
                
                if (participants.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Keine Teilnehmer',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    return _buildParticipantItem(participants[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.purple, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.purple,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantItem(VoiceParticipant participant) {
    final isSpeaking = widget.voiceController.currentSpeakerId == participant.userId;
    final isCurrentUser = participant.userId == widget.voiceController.currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSpeaking
            ? Colors.green.withValues(alpha: 0.1)
            : const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSpeaking ? Colors.green : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.purple,
              shape: BoxShape.circle,
              border: isSpeaking
                  ? Border.all(color: Colors.green, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                participant.username[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      participant.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Du',
                          style: TextStyle(
                            color: Colors.purple,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (isSpeaking)
                  const Text(
                    '🎙️ Spricht gerade...',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          
          // Mute Status
          Icon(
            participant.isMuted ? Icons.mic_off : Icons.mic,
            color: participant.isMuted ? Colors.red : Colors.white54,
            size: 20,
          ),
        ],
      ),
    );
  }
}
