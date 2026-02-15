/// 🎤 MODERN WEBRTC VOICE CHAT SCREEN
/// 2×5 Grid layout for up to 10 participants
/// Features:
/// - Dynamic participant grid (2 columns, max 5 rows)
/// - Active speaker highlight with glow effect
/// - Speaking animations
/// - Modern Material Design 3 UI
/// - Admin controls (long-press menu)
/// - Room full indicator
/// - Reconnecting state
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/webrtc_call_provider.dart';
import '../../models/webrtc_call_state.dart';
import '../../widgets/voice/participant_grid_tile.dart';
import '../../widgets/admin/warning_dialog.dart';
import '../../widgets/admin/ban_user_dialog.dart';
import '../../models/admin_action.dart';

class ModernVoiceChatScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String roomName;
  final String userId;
  final String username;
  final String world;  // ✅ ADD: world parameter
  final Color accentColor;
  final bool isObserverMode;  // ✅ ADD: observer mode parameter
  final String? userName;  // ✅ ADD: alternative userName parameter

  const ModernVoiceChatScreen({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.userId,
    required this.username,
    required this.world,  // ✅ ADD: world parameter
    this.accentColor = Colors.blue,
    this.isObserverMode = false,  // ✅ ADD: observer mode parameter
    this.userName,  // ✅ ADD: alternative userName parameter
  });

  @override
  ConsumerState<ModernVoiceChatScreen> createState() => _ModernVoiceChatScreenState();
}

class _ModernVoiceChatScreenState extends ConsumerState<ModernVoiceChatScreen> {
  @override
  Widget build(BuildContext context) {
    // Watch WebRTC state
    final callState = ref.watch(webrtcCallProvider);
    final isInCall = ref.watch(isInCallProvider);
    final participantCount = ref.watch(participantCountProvider);
    final isRoomFull = ref.watch(isRoomFullProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E), // Dark background
      appBar: _buildAppBar(callState, participantCount, isRoomFull),
      body: Column(
        children: [
          // Connection status banner
          if (callState.connectionState == CallConnectionState.reconnecting)
            _buildReconnectingBanner(callState),

          // Participant Grid
          Expanded(
            child: callState.participants.isEmpty
                ? _buildEmptyState()
                : _buildParticipantGrid(callState),
          ),

          // Bottom Controls
          _buildBottomControls(callState),
        ],
      ),
    );
  }

  /// App Bar with status
  PreferredSizeWidget _buildAppBar(
    WebRTCCallState state,
    int participantCount,
    bool isRoomFull,
  ) {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A1A),
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.roomName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              // Connection status dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getConnectionColor(state.connectionState),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '$participantCount / ${state.maxParticipants} participants',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              if (isRoomFull) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'FULL',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Get connection status color
  Color _getConnectionColor(CallConnectionState state) {
    switch (state) {
      case CallConnectionState.connected:
        return Colors.green;
      case CallConnectionState.connecting:
      case CallConnectionState.reconnecting:
        return Colors.orange;
      case CallConnectionState.error:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Reconnecting banner
  Widget _buildReconnectingBanner(WebRTCCallState state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.orange.withValues(alpha: 0.2),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Reconnecting... (Attempt ${state.reconnectAttempts}/${state.maxReconnectAttempts})',
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 2×5 Participant Grid
  Widget _buildParticipantGrid(WebRTCCallState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 columns
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8, // Slightly taller than wide
        ),
        itemCount: state.participants.length,
        itemBuilder: (context, index) {
          final participant = state.participants[index];
          final isCurrentUser = participant.userId == widget.userId;

          return ParticipantGridTile(
            participant: participant,
            isCurrentUser: isCurrentUser,
            isAdmin: state.isAdmin || state.isRootAdmin,
            accentColor: widget.accentColor,
            onLongPress: () => _showAdminMenu(participant.userId),
          );
        },
      ),
    );
  }

  /// Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Waiting for participants...',
            style: TextStyle(
              color: Colors.grey.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Control Bar
  Widget _buildBottomControls(WebRTCCallState state) {
    final notifier = ref.read(webrtcCallProvider.notifier);

    return Container(
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
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute/Unmute Button
            _buildControlButton(
              icon: state.isLocalMuted ? Icons.mic_off : Icons.mic,
              label: state.isLocalMuted ? 'Unmute' : 'Mute',
              onTap: () => notifier.toggleMute(),
              color: state.isLocalMuted ? Colors.red : widget.accentColor,
              isActive: !state.isLocalMuted,
            ),

            // Leave Button
            _buildControlButton(
              icon: Icons.call_end,
              label: 'Leave',
              onTap: () async {
                await notifier.leaveRoom();
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              color: Colors.red,
            ),

            // Admin Button (only if admin)
            if (state.isAdmin || state.isRootAdmin)
              _buildControlButton(
                icon: Icons.admin_panel_settings,
                label: 'Admin',
                onTap: () => _showAdminPanel(),
                color: Colors.amber,
              ),
          ],
        ),
      ),
    );
  }

  /// Control Button
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isActive ? 0.2 : 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Show admin menu for participant
  void _showAdminMenu(String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.volume_off, color: Colors.orange),
              title: const Text(
                'Mute User',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                ref.read(webrtcCallProvider.notifier).muteUser(userId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_remove, color: Colors.red),
              title: const Text(
                'Kick User',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                ref.read(webrtcCallProvider.notifier).kickUser(userId);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Show admin panel
  void _showAdminPanel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Admin Panel',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Long-press any participant to access admin actions.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
