/// 🎤 VOICE CONTROL PANEL WIDGET
/// Bottom sheet with comprehensive voice chat controls

import 'package:flutter/material.dart';

class VoiceControlPanel extends StatefulWidget {
  final String roomId;
  final String userId;
  final String username;
  final bool isInVoiceRoom;
  final bool isMuted;
  final List<Map<String, dynamic>> participants;
  final Color accentColor;
  final bool isAdmin;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final VoidCallback onToggleMute;
  final Function(String userId)? onKickUser;
  final Function(String userId)? onMuteUser;

  const VoiceControlPanel({
    Key? key,
    required this.roomId,
    required this.userId,
    required this.username,
    required this.isInVoiceRoom,
    required this.isMuted,
    required this.participants,
    required this.accentColor,
    this.isAdmin = false,
    required this.onJoin,
    required this.onLeave,
    required this.onToggleMute,
    this.onKickUser,
    this.onMuteUser,
  }) : super(key: key);

  @override
  State<VoiceControlPanel> createState() => _VoiceControlPanelState();
}

class _VoiceControlPanelState extends State<VoiceControlPanel> {
  double _volume = 0.8;
  String _audioQuality = 'medium'; // low, medium, high

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.headset_mic,
                    color: widget.accentColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Voice Chat Controls',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Room: #${widget.roomId}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isInVoiceRoom
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.isInVoiceRoom
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.isInVoiceRoom
                                ? Colors.green
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.isInVoiceRoom ? 'Connected' : 'Not Connected',
                          style: TextStyle(
                            color: widget.isInVoiceRoom
                                ? Colors.green
                                : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(color: Color(0xFF2A2A3E)),
            
            // Participants List
            if (widget.isInVoiceRoom) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text(
                      'Participants',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.participants.length}/10',
                        style: TextStyle(
                          color: widget.accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Participant List
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.participants.length,
                  itemBuilder: (context, index) {
                    final participant = widget.participants[index];
                    final isCurrentUser = participant['userId'] == widget.userId;
                    final isSpeaking = participant['isSpeaking'] == true;
                    final isMuted = participant['isMuted'] == true;
                    
                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: isSpeaking
                                ? Colors.green.withValues(alpha: 0.3)
                                : Colors.grey.withValues(alpha: 0.3),
                            child: Text(
                              participant['avatarEmoji']?.toString() ?? '👤',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          if (isSpeaking)
                            Positioned.fill(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.green,
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              participant['username']?.toString() ?? 'Unknown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (isCurrentUser)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: widget.accentColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'You',
                                style: TextStyle(
                                  color: widget.accentColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        isSpeaking
                            ? 'Speaking...'
                            : isMuted
                                ? 'Muted'
                                : 'Listening',
                        style: TextStyle(
                          color: isSpeaking
                              ? Colors.green
                              : isMuted
                                  ? Colors.grey
                                  : Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                      trailing: widget.isAdmin && !isCurrentUser
                          ? PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.white,
                              ),
                              color: const Color(0xFF2A2A3E),
                              onSelected: (value) {
                                if (value == 'kick') {
                                  widget.onKickUser?.call(
                                    participant['userId'].toString(),
                                  );
                                } else if (value == 'mute') {
                                  widget.onMuteUser?.call(
                                    participant['userId'].toString(),
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'mute',
                                  child: Row(
                                    children: [
                                      Icon(Icons.mic_off, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Mute User',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'kick',
                                  child: Row(
                                    children: [
                                      Icon(Icons.exit_to_app, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text(
                                        'Kick User',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Icon(
                              isMuted ? Icons.mic_off : Icons.mic,
                              color: isMuted
                                  ? Colors.grey
                                  : isSpeaking
                                      ? Colors.green
                                      : Colors.white,
                            ),
                    );
                  },
                ),
              ),
              
              const Divider(color: Color(0xFF2A2A3E)),
            ],
            
            // Controls
            if (widget.isInVoiceRoom) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Mute/Unmute Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.onToggleMute,
                        icon: Icon(
                          widget.isMuted ? Icons.mic_off : Icons.mic,
                        ),
                        label: Text(
                          widget.isMuted ? 'Unmute' : 'Mute',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.isMuted
                              ? Colors.red.withValues(alpha: 0.2)
                              : Colors.green.withValues(alpha: 0.2),
                          foregroundColor: widget.isMuted
                              ? Colors.red
                              : Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Volume Control
                    Row(
                      children: [
                        const Icon(
                          Icons.volume_down,
                          color: Colors.white,
                        ),
                        Expanded(
                          child: Slider(
                            value: _volume,
                            onChanged: (value) {
                              setState(() {
                                _volume = value;
                              });
                              // TODO: Apply volume to WebRTC
                            },
                            activeColor: widget.accentColor,
                            inactiveColor: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        const Icon(
                          Icons.volume_up,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(_volume * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Audio Quality
                    Row(
                      children: [
                        const Icon(
                          Icons.high_quality,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Audio Quality:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'low',
                                label: Text('Low', style: TextStyle(fontSize: 12)),
                              ),
                              ButtonSegment(
                                value: 'medium',
                                label: Text('Med', style: TextStyle(fontSize: 12)),
                              ),
                              ButtonSegment(
                                value: 'high',
                                label: Text('High', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                            selected: {_audioQuality},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _audioQuality = newSelection.first;
                              });
                              // TODO: Apply quality setting to WebRTC
                            },
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.resolveWith(
                                (states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return widget.accentColor;
                                  }
                                  return Colors.grey.withValues(alpha: 0.2);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Leave Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.onLeave,
                        icon: const Icon(Icons.call_end),
                        label: const Text('Leave Voice Room'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.2),
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Join Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Room Preview
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.people,
                            color: widget.accentColor,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${widget.participants.length} ${widget.participants.length == 1 ? 'Person' : 'People'} in Voice Room',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.participants.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Join them in the voice chat',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Join Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.onJoin,
                        icon: const Icon(Icons.call),
                        label: const Text('Join Voice Room'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
