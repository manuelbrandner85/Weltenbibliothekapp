/// ⌨️ VOICE KEYBOARD SHORTCUTS
/// Keyboard shortcuts for voice chat controls
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/webrtc_voice_service.dart'; // ✅ UNIFIED WebRTC Service
import '../services/voice_feedback_service.dart';

class VoiceKeyboardShortcuts extends StatefulWidget {
  final SimpleVoiceController voiceController;
  final Widget child;
  final Function(String emoji)? onEmojiShortcut;
  final VoidCallback? onHandRaiseShortcut;

  const VoiceKeyboardShortcuts({
    super.key,
    required this.voiceController,
    required this.child,
    this.onEmojiShortcut,
    this.onHandRaiseShortcut,
  });

  @override
  State<VoiceKeyboardShortcuts> createState() => _VoiceKeyboardShortcutsState();
}

class _VoiceKeyboardShortcutsState extends State<VoiceKeyboardShortcuts> {
  final VoiceFeedbackService _feedback = VoiceFeedbackService();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleKeyPress(RawKeyEvent event) async {
    if (event is! RawKeyDownEvent) return;

    // Only handle if not typing in a text field
    if (FocusScope.of(context).focusedChild?.context?.widget is EditableText) {
      return;
    }

    switch (event.logicalKey) {
      // M - Toggle Mute
      case LogicalKeyboardKey.keyM:
        await widget.voiceController.toggleMute();
        await _feedback.micOn();
        if (mounted) {
          _showShortcutSnackBar(
            widget.voiceController.isMuted ? '🔇 Stummgeschaltet' : '🎤 Mikrofon aktiv',
          );
        }
        break;

      // L - Leave Voice Chat
      case LogicalKeyboardKey.keyL:
        await widget.voiceController.leaveVoiceRoom();
        if (mounted) {
          _showShortcutSnackBar('🚪 Voice Chat verlassen');
          Navigator.of(context).pop();
        }
        break;

      // E - Emoji Reactions
      case LogicalKeyboardKey.keyE:
        widget.onEmojiShortcut?.call('👍');
        _showShortcutSnackBar('👍 Reaktion gesendet');
        break;

      // H - Raise Hand
      case LogicalKeyboardKey.keyH:
        widget.onHandRaiseShortcut?.call();
        _showShortcutSnackBar('✋ Hand gehoben/gesenkt');
        break;

      // Numbers 1-5: Quick Emoji Reactions
      case LogicalKeyboardKey.digit1:
        widget.onEmojiShortcut?.call('👍');
        _showShortcutSnackBar('👍');
        break;

      case LogicalKeyboardKey.digit2:
        widget.onEmojiShortcut?.call('❤️');
        _showShortcutSnackBar('❤️');
        break;

      case LogicalKeyboardKey.digit3:
        widget.onEmojiShortcut?.call('😂');
        _showShortcutSnackBar('😂');
        break;

      case LogicalKeyboardKey.digit4:
        widget.onEmojiShortcut?.call('🎉');
        _showShortcutSnackBar('🎉');
        break;

      case LogicalKeyboardKey.digit5:
        widget.onEmojiShortcut?.call('👏');
        _showShortcutSnackBar('👏');
        break;

      // ? - Show Shortcuts Help
      case LogicalKeyboardKey.slash:
        if (event.isShiftPressed) {
          _showShortcutsHelp();
        }
        break;

      default:
        break;
    }
  }

  void _showShortcutSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
      ),
    );
  }

  void _showShortcutsHelp() {
    showDialog(
      context: context,
      builder: (context) => const VoiceShortcutsHelpDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyPress,
      child: widget.child,
    );
  }
}

/// ❓ Shortcuts Help Dialog
class VoiceShortcutsHelpDialog extends StatelessWidget {
  const VoiceShortcutsHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.keyboard, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text(
                  'Tastaturkürzel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildShortcut('M', 'Mikrofon ein/aus'),
            _buildShortcut('L', 'Voice Chat verlassen'),
            _buildShortcut('E', 'Emoji-Reaktion (👍)'),
            _buildShortcut('H', 'Hand heben/senken'),
            _buildShortcut('Space', 'Push-to-Talk (gedrückt halten)'),
            const SizedBox(height: 16),
            const Text(
              '📱 Schnell-Emojis:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildShortcut('1', '👍 Like'),
            _buildShortcut('2', '❤️ Herz'),
            _buildShortcut('3', '😂 Lachen'),
            _buildShortcut('4', '🎉 Party'),
            _buildShortcut('5', '👏 Applaus'),
            const SizedBox(height: 16),
            _buildShortcut('?', 'Diese Hilfe anzeigen (Shift + ?)'),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Schließen',
                  style: TextStyle(color: Colors.greenAccent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcut(String key, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Text(
              key,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
