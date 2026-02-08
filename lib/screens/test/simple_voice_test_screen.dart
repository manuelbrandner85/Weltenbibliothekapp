/// 🧪 SIMPLE VOICE TEST SCREEN
/// Test screen für das neue Simple Voice System
library;

import 'package:flutter/material.dart';
import '../../services/simple_voice_controller.dart';
import '../../models/chat_models.dart';

class SimpleVoiceTestScreen extends StatefulWidget {
  const SimpleVoiceTestScreen({super.key});

  @override
  State<SimpleVoiceTestScreen> createState() => _SimpleVoiceTestScreenState();
}

class _SimpleVoiceTestScreenState extends State<SimpleVoiceTestScreen> {
  final SimpleVoiceController _controller = SimpleVoiceController();
  bool _isInitializing = false;
  bool _isJoining = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Simple Voice Test',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            return Column(
              children: [
                // 📊 STATUS
                _buildStatusSection(),
                
                const SizedBox(height: 24),
                
                // 🎤 MICROPHONE BUTTON
                if (!_controller.isInCall)
                  _buildMicrophoneButton(),
                
                const SizedBox(height: 16),
                
                // 🚀 JOIN BUTTON
                if (!_controller.isInCall)
                  _buildJoinButton(),
                
                // 🚪 LEAVE BUTTON
                if (_controller.isInCall)
                  _buildLeaveButton(),
                
                const SizedBox(height: 24),
                
                // 👥 PARTICIPANTS
                Expanded(
                  child: _buildParticipantsList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusRow('Mikrofon', _controller.localStream != null ? '✅' : '❌'),
          _buildStatusRow('Im Voice-Chat', _controller.isInCall ? '✅' : '❌'),
          _buildStatusRow('Stumm', _controller.isMuted ? '🔇' : '🔊'),
          _buildStatusRow('Participants', '${_controller.participantCount}'),
          
          if (_controller.isInCall) ...[
            const Divider(color: Colors.white24, height: 24),
            _buildStatusRow('Room', _controller.currentRoomName ?? 'Unknown'),
            _buildStatusRow('User', _controller.currentUsername ?? 'Unknown'),
          ],
          
          if (_error != null) ...[
            const Divider(color: Colors.white24, height: 24),
            Text(
              '❌ Error: $_error',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicrophoneButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: _isInitializing ? null : _initMicrophone,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          minimumSize: const Size(double.infinity, 0),
        ),
        icon: _isInitializing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.mic),
        label: Text(_isInitializing ? 'Initialisiere...' : '🎤 Mikrofon initialisieren'),
      ),
    );
  }

  Widget _buildJoinButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: (_isJoining || _controller.localStream == null) ? null : _joinRoom,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 16),
          minimumSize: const Size(double.infinity, 0),
        ),
        icon: _isJoining
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.call),
        label: Text(_isJoining ? 'Beitrete...' : '🚀 Voice-Chat beitreten'),
      ),
    );
  }

  Widget _buildLeaveButton() {
    return Column(
      children: [
        // MUTE BUTTON
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton.icon(
            onPressed: () => _controller.toggleMute(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _controller.isMuted ? Colors.orange : Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 0),
            ),
            icon: Icon(_controller.isMuted ? Icons.mic_off : Icons.mic),
            label: Text(_controller.isMuted ? '🔇 Freischalten' : '🔊 Stumm schalten'),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // LEAVE BUTTON
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton.icon(
            onPressed: _leaveRoom,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 0),
            ),
            icon: const Icon(Icons.call_end),
            label: const Text('🚪 Voice-Chat verlassen'),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsList() {
    final participants = _controller.participants;
    
    if (participants.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'Keine Participants',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: participants.length,
      itemBuilder: (context, index) {
        final participant = participants[index];
        return _buildParticipantTile(participant);
      },
    );
  }

  Widget _buildParticipantTile(VoiceParticipant participant) {
    final isCurrentUser = participant.userId == _controller.currentUserId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser ? Colors.green : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getColorForUser(participant.userId),
            ),
            child: Center(
              child: Text(
                participant.username[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isCurrentUser)
                  const Text(
                    '(Du)',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
              ],
            ),
          ),
          
          // Status Icons
          if (participant.isMuted)
            const Icon(Icons.mic_off, color: Colors.red, size: 20)
          else
            const Icon(Icons.mic, color: Colors.green, size: 20),
          
          const SizedBox(width: 8),
          
          if (participant.isSpeaking)
            const Icon(Icons.volume_up, color: Colors.blue, size: 20),
        ],
      ),
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

  // 🎤 INIT MICROPHONE
  Future<void> _initMicrophone() async {
    setState(() {
      _isInitializing = true;
      _error = null;
    });
    
    try {
      print('🎤 [Test] Initializing microphone...');
      final success = await _controller.initMicrophone();
      
      if (success) {
        print('✅ [Test] Microphone initialized');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Mikrofon initialisiert'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('❌ [Test] Microphone initialization failed');
        setState(() {
          _error = 'Mikrofon-Initialisierung fehlgeschlagen';
        });
      }
      
    } catch (e) {
      print('❌ [Test] Error: $e');
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  // 🚀 JOIN ROOM
  Future<void> _joinRoom() async {
    setState(() {
      _isJoining = true;
      _error = null;
    });
    
    try {
      print('🚀 [Test] Joining room...');
      final success = await _controller.joinVoiceRoom(
        'test_room',
        'Test Room',
        'user_test',
        'TestUser',
      );
      
      if (success) {
        print('✅ [Test] Joined room');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Voice-Chat beigetreten'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        // TEST: Simulate another user joining after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          print('🧪 [Test] Simulating remote user join...');
          _controller.onUserJoined('user_remote', 'RemoteUser');
        });
        
      } else {
        print('❌ [Test] Join failed');
        setState(() {
          _error = 'Beitritt fehlgeschlagen';
        });
      }
      
    } catch (e) {
      print('❌ [Test] Error: $e');
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isJoining = false;
      });
    }
  }

  // 🚪 LEAVE ROOM
  Future<void> _leaveRoom() async {
    try {
      print('🚪 [Test] Leaving room...');
      await _controller.leaveVoiceRoom();
      
      print('✅ [Test] Left room');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Voice-Chat verlassen'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      
    } catch (e) {
      print('❌ [Test] Error: $e');
      setState(() {
        _error = e.toString();
      });
    }
  }
}
