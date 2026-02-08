import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'dart:convert';
import 'dart:async';
import '../../services/group_tools_service.dart';
import '../../services/user_service.dart';

/// 🧘 Meditation Timer Screen
/// Gemeinsame Meditation-Sessions mit synchronisiertem Timer
class MeditationTimerScreen extends StatefulWidget {
  final String roomId;
  
  const MeditationTimerScreen({
    super.key,
    this.roomId = 'meditation',
  });

  @override
  State<MeditationTimerScreen> createState() => _MeditationTimerScreenState();
}

class _MeditationTimerScreenState extends State<MeditationTimerScreen> {
  final GroupToolsService _toolsService = GroupToolsService();
  final UserService _userService = UserService();
  
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = false;
  String _username = '';
  String _userId = '';
  String? _errorMessage;
  
  // Timer State
  bool _isTimerRunning = false;
  int _remainingSeconds = 0;
  Timer? _timer;
  int _selectedDuration = 10; // Minutes
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSessions();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    final user = await _userService.getCurrentUser();
    setState(() {
      _username = user.username;
      _userId = 'user_${user.username.toLowerCase()}';
    });
  }
  
  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final sessions = await _toolsService.getMeditationSessions(
        roomId: widget.roomId,
        limit: 50,
      );
      
      if (kDebugMode) {
        debugPrint('🧘 Loaded ${sessions.length} sessions');
      }
      
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading sessions: $e');
      }
      setState(() {
        _errorMessage = 'Fehler beim Laden: $e';
        _isLoading = false;
      });
    }
  }
  
  void _startTimer() {
    if (_username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Bitte erstelle erst ein Profil'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isTimerRunning = true;
      _remainingSeconds = _selectedDuration * 60;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _stopTimer(completed: true);
        }
      });
    });
  }
  
  void _stopTimer({bool completed = false}) {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
    
    if (completed) {
      _saveSession();
      _showCompletionDialog();
    }
  }
  
  Future<void> _saveSession() async {
    try {
      final sessionId = await _toolsService.createMeditationSession(
        roomId: widget.roomId,
        userId: _userId,
        durationMinutes: _selectedDuration,
        participants: [_userId],
        notes: 'Meditation abgeschlossen',
      );
      
      if (sessionId != null) {
        _loadSessions(); // Reload
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving session: $e');
      }
    }
  }
  
  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          '✨ Meditation abgeschlossen!',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                ),
              ),
              child: const Icon(Icons.check, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Du hast $_selectedDuration Minuten meditiert!',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
            ),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('🧘 Meditation Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadSessions(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Timer Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4A148C).withValues(alpha: 0.3),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // Timer Display
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _isTimerRunning 
                          ? _formatTime(_remainingSeconds)
                          : _formatTime(_selectedDuration * 60),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Duration Selector (only when timer not running)
                if (!_isTimerRunning) ...[
                  const Text(
                    'Dauer wählen',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    children: [5, 10, 15, 20, 30, 45, 60].map((minutes) {
                      final isSelected = _selectedDuration == minutes;
                      return ChoiceChip(
                        label: Text('$minutes min'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedDuration = minutes);
                        },
                        selectedColor: Colors.purple,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Control Buttons
                if (_isTimerRunning)
                  ElevatedButton.icon(
                    onPressed: () => _stopTimer(),
                    icon: const Icon(Icons.stop),
                    label: const Text('Stoppen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _startTimer,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Starten'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C27B0),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
              ],
            ),
          ),
          
          // Sessions List
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '📊 Vergangene Sessions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error, size: 48, color: Colors.red),
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : _sessions.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Noch keine Sessions',
                                    style: TextStyle(color: Colors.white38),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _sessions.length,
                                  itemBuilder: (context, index) {
                                    final session = _sessions[index];
                                    return _buildSessionCard(session);
                                  },
                                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSessionCard(Map<String, dynamic> session) {
    final duration = session['duration_minutes'] ?? 0;
    final notes = session['notes'] ?? '';
    final createdAt = session['created_at'] ?? '';
// UNUSED: final createdBy = session['created_by'] ?? 'Anonym';
    
    // Parse participants
    List<String> participants = [];
    try {
      final partsJson = session['participants'];
      if (partsJson is String && partsJson.isNotEmpty) {
        participants = List<String>.from(
          partsJson.startsWith('[') 
            ? (jsonDecode(partsJson) as List) 
            : [partsJson]
        );
      } else if (partsJson is List) {
        participants = List<String>.from(partsJson);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error parsing participants: $e');
      }
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                ),
              ),
              child: const Icon(Icons.self_improvement, color: Colors.white),
            ),
            
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$duration Minuten Meditation',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (notes.isNotEmpty)
                    Text(
                      notes,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${participants.length} Teilnehmer',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Date
            Text(
              createdAt.split(' ').first,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
