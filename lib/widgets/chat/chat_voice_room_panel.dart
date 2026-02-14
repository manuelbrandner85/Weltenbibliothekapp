/// 💬 CHAT VOICE ROOM PANEL
/// 
/// Voice room panel showing active participants
/// 
/// Features:
/// - Voice participants grid
/// - Speaking indicators
/// - Mute status
/// - Join/Leave controls
/// - Mute/Unmute toggle
library;

import 'package:flutter/material.dart';

class ChatVoiceRoomPanel extends StatefulWidget {
  final bool isInVoiceRoom;
  final bool isMuted;
  final List<Map<String, dynamic>> voiceParticipants;
  final VoidCallback? onToggleVoiceRoom;
  final VoidCallback? onToggleMute;
  
  const ChatVoiceRoomPanel({
    super.key,
    required this.isInVoiceRoom,
    required this.isMuted,
    required this.voiceParticipants,
    this.onToggleVoiceRoom,
    this.onToggleMute,
  });

  @override
  State<ChatVoiceRoomPanel> createState() => _ChatVoiceRoomPanelState();
}

class _ChatVoiceRoomPanelState extends State<ChatVoiceRoomPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isExpanded = false;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isInVoiceRoom && widget.voiceParticipants.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Voice icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.isInVoiceRoom
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isInVoiceRoom ? Icons.phone : Icons.phone_disabled,
                        color: widget.isInVoiceRoom ? Colors.white : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Title and participant count
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isInVoiceRoom ? 'Voice Room Active' : 'Voice Room Available',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: widget.isInVoiceRoom
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.voiceParticipants.length} ${widget.voiceParticipants.length == 1 ? 'participant' : 'participants'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Expand icon
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),
            
            // Expanded content
            if (_isExpanded) ...[
              const Divider(height: 1),
              
              // Participants grid
              if (widget.voiceParticipants.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: widget.voiceParticipants.map((participant) {
                      return _buildParticipantAvatar(participant);
                    }).toList(),
                  ),
                ),
              
              // Controls
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute/Unmute button
                    if (widget.isInVoiceRoom)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.onToggleMute,
                          icon: Icon(
                            widget.isMuted ? Icons.mic_off : Icons.mic,
                            size: 20,
                          ),
                          label: Text(
                            widget.isMuted ? 'Unmute' : 'Mute',
                            style: const TextStyle(fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.isMuted
                                ? Colors.orange
                                : Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    
                    if (widget.isInVoiceRoom) const SizedBox(width: 12),
                    
                    // Join/Leave button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onToggleVoiceRoom,
                        icon: Icon(
                          widget.isInVoiceRoom ? Icons.call_end : Icons.phone,
                          size: 20,
                        ),
                        label: Text(
                          widget.isInVoiceRoom ? 'Leave' : 'Join',
                          style: const TextStyle(fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.isInVoiceRoom
                              ? Colors.red
                              : Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
  
  Widget _buildParticipantAvatar(Map<String, dynamic> participant) {
    final userName = participant['name'] as String? ?? 'Unknown';
    final userId = participant['id'] as String? ?? '';
    final isMuted = participant['is_muted'] as bool? ?? false;
    final isSpeaking = participant['is_speaking'] as bool? ?? false;
    final avatarUrl = participant['avatar_url'] as String?;
    
    return Column(
      children: [
        Stack(
          children: [
            // Speaking indicator (animated ring)
            if (isSpeaking)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withValues(
                          alpha: 0.3 + (_pulseController.value * 0.4),
                        ),
                        width: 3,
                      ),
                    ),
                  );
                },
              ),
            
            // Avatar
            Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              ),
              child: ClipOval(
                child: avatarUrl != null
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultAvatar(userName);
                        },
                      )
                    : _buildDefaultAvatar(userName),
              ),
            ),
            
            // Mute indicator
            if (isMuted)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.mic_off,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 70,
          child: Text(
            userName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSpeaking ? FontWeight.w600 : FontWeight.normal,
              color: isSpeaking
                  ? Theme.of(context).primaryColor
                  : Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDefaultAvatar(String userName) {
    return Container(
      alignment: Alignment.center,
      child: Text(
        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
