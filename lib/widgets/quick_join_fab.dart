/// 🚀 QUICK JOIN FAB
/// Floating Action Button for quick voice chat join
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/webrtc_voice_service.dart'; // ✅ UNIFIED WebRTC Service

class QuickJoinFAB extends StatefulWidget {
  final String currentRoomId;
  final String currentRoomName;
  final String userId;
  final String username;
  final Color color;

  const QuickJoinFAB({
    super.key,
    required this.currentRoomId,
    required this.currentRoomName,
    required this.userId,
    required this.username,
    required this.color,
  });

  @override
  State<QuickJoinFAB> createState() => _QuickJoinFABState();
}

class _QuickJoinFABState extends State<QuickJoinFAB> {
  static const String _keyLastRoom = 'last_voice_room';
  static const String _keyLastRoomName = 'last_voice_room_name';
  
  final SimpleVoiceController _voiceController = SimpleVoiceController();
  String? _lastRoomId;
  String? _lastRoomName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLastRoom();
  }

  Future<void> _loadLastRoom() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastRoomId = prefs.getString(_keyLastRoom);
      _lastRoomName = prefs.getString(_keyLastRoomName);
    });
  }

  Future<void> _saveLastRoom() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastRoom, widget.currentRoomId);
    await prefs.setString(_keyLastRoomName, widget.currentRoomName);
  }

  Future<void> _quickJoin() async {
    if (_lastRoomId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _voiceController.joinVoiceRoom(
        _lastRoomId!,
        _lastRoomName ?? 'Voice Chat',
        widget.userId,
        widget.username,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎙️ Beigetreten: $_lastRoomName'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Fehler beim Beitreten'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show if not in call and have last room
    if (_voiceController.isInCall || _lastRoomId == null) {
      // Save current room when joining
      if (_voiceController.isInCall) {
        _saveLastRoom();
      }
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      onPressed: _isLoading ? null : _quickJoin,
      backgroundColor: widget.color,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.flash_on, color: Colors.white),
      label: Text(
        _lastRoomName ?? 'Quick Join',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
