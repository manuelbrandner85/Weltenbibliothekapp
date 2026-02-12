/// 🎤 TELEGRAM VOICE CHAT SCREEN (EXACT TELEGRAM STYLE)
/// Vertical list layout with small avatars like real Telegram
/// Features:
/// - Vertical ListView (NOT Grid!)
/// - Small avatars (40px)
/// - "listening" / "speaking" status
/// - "You are Live" indicator
/// - Admin long-press menu

import 'package:flutter/material.dart';
import '../../widgets/admin/warning_dialog.dart';
import '../../widgets/admin/ban_user_dialog.dart';
import '../../models/admin_action.dart';

class TelegramVoiceChatScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String userId;
  final String username;
  final List<Map<String, dynamic>> participants;
  final bool isMuted;
  final Color accentColor;
  final VoidCallback onToggleMute;
  final VoidCallback onLeave;
  final Function(String userId)? onKickUser;
  final Function(String userId)? onMuteUser;
  final Function(String userId, String reason)? onWarnUser;
  final Function(String userId, BanDuration duration, String? reason)? onBanUser;
  final bool isAdmin;
  final int Function(String userId)? getWarningCount;

  const TelegramVoiceChatScreen({
    Key? key,
    required this.roomId,
    required this.roomName,
    required this.userId,
    required this.username,
    required this.participants,
    required this.isMuted,
    required this.accentColor,
    required this.onToggleMute,
    required this.onLeave,
    this.onKickUser,
    this.onMuteUser,
    this.onWarnUser,
    this.onBanUser,
    this.isAdmin = false,
    this.getWarningCount,
  }) : super(key: key);

  @override
  State<TelegramVoiceChatScreen> createState() => _TelegramVoiceChatScreenState();
}

class _TelegramVoiceChatScreenState extends State<TelegramVoiceChatScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E), // Dark like Telegram
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voice Chat',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${widget.participants.length} participants',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Participant List (Vertical like Telegram!)
          Expanded(
            child: ListView.builder(
              itemCount: widget.participants.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                return _buildParticipantTile(widget.participants[index]);
              },
            ),
          ),
          
          // "You are Live" Indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'You are Live',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              border: Border(
                top: BorderSide(
                  color: Color(0xFF2A2A2A),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mute Button
                _buildControlButton(
                  icon: widget.isMuted ? Icons.mic_off : Icons.mic,
                  label: widget.isMuted ? 'Unmute' : 'Mute',
                  onTap: widget.onToggleMute,
                  isActive: !widget.isMuted,
                  color: widget.accentColor,
                ),
                
                // Leave Button
                _buildControlButton(
                  icon: Icons.call_end,
                  label: 'Leave',
                  onTap: () {
                    widget.onLeave();
                    Navigator.pop(context);
                  },
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Participant List Tile (Telegram Style)
  Widget _buildParticipantTile(Map<String, dynamic> participant) {
    final isCurrentUser = participant['userId'] == widget.userId;
    final isSpeaking = participant['isSpeaking'] == true;
    final isMuted = participant['isMuted'] == true;
    final username = participant['username']?.toString() ?? 'Unknown';
    final avatarEmoji = participant['avatarEmoji']?.toString() ?? '👤';

    return ListTile(
      onLongPress: () {
        if (widget.isAdmin && !isCurrentUser) {
          _showAdminMenu(participant);
        }
      },
      leading: CircleAvatar(
        radius: 20, // Small like Telegram!
        backgroundColor: widget.accentColor.withOpacity(0.2),
        child: Text(
          avatarEmoji,
          style: const TextStyle(fontSize: 20),
        ),
      ),
      title: Row(
        children: [
          Text(
            username,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: widget.accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'You',
                style: TextStyle(
                  color: widget.accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        isSpeaking ? 'speaking' : 'listening', // Telegram status!
        style: TextStyle(
          color: isSpeaking ? Colors.green : Colors.grey,
          fontSize: 13,
        ),
      ),
      trailing: Icon(
        isMuted ? Icons.mic_off : Icons.mic,
        color: isSpeaking ? Colors.green : Colors.grey,
        size: 20,
      ),
    );
  }

  /// Control Button (Bottom)
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isActive ? color.withOpacity(0.2) : const Color(0xFF2A2A2A),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? color : Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? color : Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Admin Menu (Bottom Sheet)
  void _showAdminMenu(Map<String, dynamic> participant) {
    final String participantId = participant['userId'].toString();
    final String participantName = participant['username']?.toString() ?? 'Unknown';
    final bool isMuted = participant['isMuted'] == true;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: widget.accentColor.withOpacity(0.2),
                      child: Text(
                        participant['avatarEmoji']?.toString() ?? '👤',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            participantName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'User ID: $participantId',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(color: Color(0xFF2A2A2A)),
              
              // Admin Actions Section Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'ADMIN ACTIONS',
                      style: TextStyle(
                        color: Colors.blue.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Mute/Unmute User
              ListTile(
                leading: Icon(
                  isMuted ? Icons.mic : Icons.mic_off,
                  color: isMuted ? Colors.green : Colors.orange,
                ),
                title: Text(
                  isMuted ? 'Stummschaltung aufheben' : 'Stummschalten',
                  style: TextStyle(
                    color: isMuted ? Colors.green : Colors.orange,
                  ),
                ),
                subtitle: Text(
                  isMuted ? 'User kann wieder sprechen' : 'Mikrofon sperren',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onMuteUser?.call(participantId);
                },
              ),
              
              // Kick User with Reason
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: const Text(
                  'Aus Voice Chat entfernen',
                  style: TextStyle(color: Colors.red),
                ),
                subtitle: Text(
                  '30 Sekunden Cooldown',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onKickUser?.call(participantId);
                },
              ),
              
              const Divider(color: Color(0xFF2A2A2A)),
              
              // Moderation Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.gavel, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'MODERATION',
                      style: TextStyle(
                        color: Colors.orange.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Warning (will be implemented)
              ListTile(
                leading: const Icon(Icons.warning_amber_rounded, color: Colors.yellow),
                title: const Text(
                  'Verwarnung aussprechen',
                  style: TextStyle(color: Colors.yellow),
                ),
                subtitle: Text(
                  'User erhält offizielle Warnung',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  
                  if (widget.onWarnUser != null) {
                    // Get current warning count
                    final warningCount = widget.getWarningCount?.call(participantId) ?? 0;
                    
                    // Show Warning Dialog
                    await showDialog(
                      context: context,
                      builder: (context) => WarningDialog(
                        username: participantName,
                        userId: participantId,
                        currentWarningCount: warningCount,
                        onWarn: (reason) {
                          widget.onWarnUser?.call(participantId, reason);
                        },
                      ),
                    );
                  }
                },
              ),
              
              // Timeout
              ListTile(
                leading: const Icon(Icons.timer, color: Colors.deepOrange),
                title: const Text(
                  'Timeout geben',
                  style: TextStyle(color: Colors.deepOrange),
                ),
                subtitle: Text(
                  'Temporärer Ban (5min - 24h)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  
                  if (widget.onBanUser != null) {
                    // Show Ban Dialog with default duration = 24h
                    await showDialog(
                      context: context,
                      builder: (context) => BanUserDialog(
                        username: participantName,
                        userId: participantId,
                        onBan: (duration, reason) {
                          widget.onBanUser?.call(participantId, duration, reason);
                        },
                      ),
                    );
                  }
                },
              ),
              
              // Ban
              ListTile(
                leading: Icon(Icons.block, color: Colors.red.shade900),
                title: Text(
                  'User bannen',
                  style: TextStyle(color: Colors.red.shade900),
                ),
                subtitle: Text(
                  'Permanent vom Chat ausschließen',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  
                  if (widget.onBanUser != null) {
                    // Show Ban Dialog with default duration = permanent
                    await showDialog(
                      context: context,
                      builder: (context) => BanUserDialog(
                        username: participantName,
                        userId: participantId,
                        onBan: (duration, reason) {
                          widget.onBanUser?.call(participantId, duration, reason);
                        },
                      ),
                    );
                  }
                },
              ),
              
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
