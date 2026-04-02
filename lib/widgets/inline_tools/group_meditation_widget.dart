import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:weltenbibliothek/services/tool_api_service.dart';
import 'dart:async';

class GroupMeditationWidget extends StatefulWidget {
  final String roomId;
  
  const GroupMeditationWidget({super.key, required this.roomId});

  @override
  State<GroupMeditationWidget> createState() => _GroupMeditationWidgetState();
}

class _GroupMeditationWidgetState extends State<GroupMeditationWidget> {
  final ToolApiService _api = ToolApiService();
  Map<String, dynamic>? _activeSession;
  Timer? _pollTimer;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _isTimerRunning = false;
  
  @override
  void initState() {
    super.initState();
    _loadActiveSession();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadActiveSession());
  }
  
  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadActiveSession() async {
    try {
      final sessions = await _api.getToolData(
        endpoint: '/api/tools/meditation-sessions',
        roomId: widget.roomId,
        limit: 1,
      );
      
      if (sessions.isNotEmpty && mounted) {
        final session = sessions.first;
        final createdAt = session['created_at'] as int;
        final duration = session['duration'] as int;
        final endTime = createdAt + (duration * 60 * 1000);
        final now = DateTime.now().millisecondsSinceEpoch;
        final remaining = ((endTime - now) / 1000).ceil();
        
        if (remaining > 0) {
          setState(() {
            _activeSession = session;
            _remainingSeconds = remaining;
          });
          
          if (!_isTimerRunning) {
            _isTimerRunning = true;
            _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
              if (mounted && _remainingSeconds > 0) {
                setState(() => _remainingSeconds--);
              } else {
                _countdownTimer?.cancel();
                _isTimerRunning = false;
              }
            });
          }
        }
      }
    } catch (e) {
   if (kDebugMode) {
     debugPrint('⚠️ GroupMeditationWidget: Error - $e');
   }
   // Silently fail - widget remains functional
 }
  }
  
  Future<void> _startSession(int minutes) async {
    try {
      await _api.postToolData(
        endpoint: '/api/tools/meditation-sessions',
        data: {
          'room_id': widget.roomId,
          'duration': minutes,
          'notes': 'Gruppen-Session',
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
      );
      await _loadActiveSession();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🧘 $minutes Min Session gestartet')),
        );
      }
    } catch (e) {
   if (kDebugMode) {
     debugPrint('⚠️ GroupMeditationWidget: Error - $e');
   }
   // Silently fail - widget remains functional
 }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.withValues(alpha: 0.2), Colors.purple.withValues(alpha: 0.2)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _isTimerRunning
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🧘 GRUPPEN-MEDITATION', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  '${_remainingSeconds ~/ 60}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Gemeinsam meditieren...', style: TextStyle(color: Colors.white70)),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🧘 GRUPPEN-MEDITATION', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [5, 10, 15, 20, 30].map((m) => 
                    ElevatedButton(
                      onPressed: () => _startSession(m),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.withValues(alpha: 0.3),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text('$m Min', style: const TextStyle(fontSize: 12)),
                    )
                  ).toList(),
                ),
              ],
            ),
    );
  }
}
