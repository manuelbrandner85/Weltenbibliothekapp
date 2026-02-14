import 'package:flutter/material.dart';
import '../../../services/storage_service.dart';
import 'dart:async';

/// 🧘 MEDITATION TIMER ENHANCED (v44.1.0)
/// Mit Presets, Streak Tracking, Chakra Integration & History
class MeditationTimerEnhanced extends StatefulWidget {
  const MeditationTimerEnhanced({super.key});

  @override
  State<MeditationTimerEnhanced> createState() => _MeditationTimerEnhancedState();
}

class _MeditationTimerEnhancedState extends State<MeditationTimerEnhanced> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Timer State
  Timer? _timer;
  int _seconds = 0;
  int _selectedDuration = 600; // 10 Minuten default
  bool _isRunning = false;
  bool _isPaused = false;
  
  // Presets
  final List<Map<String, dynamic>> _defaultPresets = [
    {'name': 'Schnell', 'duration': 300, 'icon': '⚡', 'chakra': null},
    {'name': 'Standard', 'duration': 600, 'icon': '🧘', 'chakra': null},
    {'name': 'Tief', 'duration': 1200, 'icon': '🌙', 'chakra': null},
    {'name': 'Wurzel', 'duration': 420, 'icon': '🔴', 'chakra': 1},
    {'name': 'Sakral', 'duration': 480, 'icon': '🟠', 'chakra': 2},
    {'name': 'Solar', 'duration': 540, 'icon': '🟡', 'chakra': 3},
    {'name': 'Herz', 'duration': 600, 'icon': '💚', 'chakra': 4},
    {'name': 'Hals', 'duration': 660, 'icon': '🔵', 'chakra': 5},
    {'name': 'Stirn', 'duration': 720, 'icon': '💜', 'chakra': 6},
    {'name': 'Krone', 'duration': 840, 'icon': '⚪', 'chakra': 7},
  ];
  
  List<Map<String, dynamic>> _customPresets = [];
  List<Map<String, dynamic>> _sessions = [];
  int _streak = 0;
  int _totalMinutes = 0;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    // Lade Custom Presets
    _customPresets = StorageService().getMeditationPresets();
    
    // Lade Sessions
    _sessions = StorageService().getEnhancedMeditationSessions();
    
    // Berechne Streak
    _streak = StorageService().getMeditationStreak();
    
    // Berechne Total Minutes
    _totalMinutes = _sessions.fold<int>(0, (sum, s) => sum + (s['durationMinutes'] as int));
    
    setState(() {});
  }
  
  void _startTimer() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
      if (_seconds == 0) {
        _seconds = _selectedDuration;
      }
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else {
        _completeSession();
      }
    });
  }
  
  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isPaused = true;
      _isRunning = false;
    });
  }
  
  void _resumeTimer() {
    _startTimer();
  }
  
  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _seconds = 0;
    });
  }
  
  Future<void> _completeSession() async {
    _timer?.cancel();
    
    final durationMinutes = (_selectedDuration ~/ 60);
    final session = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'durationMinutes': durationMinutes,
      'durationSeconds': _selectedDuration,
      'completed': true,
    };
    
    await StorageService().saveEnhancedMeditationSession(session);
    await _loadData();
    
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _seconds = 0;
    });
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Row(
            children: [
              Text('🎉 ', style: TextStyle(fontSize: 32)),
              Text(
                'Session abgeschlossen!',
                style: TextStyle(color: Color(0xFF9C27B0)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Du hast $durationMinutes Minuten meditiert!',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF9C27B0).withValues(alpha: 0.3),
                      const Color(0xFF1E1E1E),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '🔥 $_streak Tage Streak',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9C27B0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_totalMinutes Gesamt-Minuten',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                foregroundColor: Colors.white,
              ),
              child: const Text('Schließen'),
            ),
          ],
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('🧘 Meditation Timer'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF9C27B0),
          labelColor: const Color(0xFF9C27B0),
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'TIMER'),
            Tab(text: 'PRESETS'),
            Tab(text: 'HISTORY'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A0033).withValues(alpha: 0.95),
              const Color(0xFF0D001A).withValues(alpha: 0.98),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTimerTab(),
              _buildPresetsTab(),
              _buildHistoryTab(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTimerTab() {
    final progress = _selectedDuration > 0 ? _seconds / _selectedDuration : 0.0;
    final minutesLeft = _seconds ~/ 60;
    final secondsLeft = _seconds % 60;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Stats Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF9C27B0).withValues(alpha: 0.3),
                  const Color(0xFF1E1E1E),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('🔥 Streak', '$_streak Tage'),
                _buildStatItem('⏱️ Sessions', '${_sessions.length}'),
                _buildStatItem('🧘 Minuten', '$_totalMinutes'),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Timer Display
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 250,
                height: 250,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${minutesLeft.toString().padLeft(2, '0')}:${secondsLeft.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRunning ? 'Läuft...' : _isPaused ? 'Pausiert' : 'Bereit',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Duration Selector (nur wenn nicht läuft)
          if (!_isRunning && !_isPaused) ...[
            const Text(
              'DAUER WÄHLEN',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9C27B0),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [5, 10, 15, 20, 30, 45, 60].map((min) {
                final isSelected = _selectedDuration == min * 60;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDuration = min * 60),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                const Color(0xFF9C27B0),
                                const Color(0xFF9C27B0).withValues(alpha: 0.7),
                              ],
                            )
                          : null,
                      color: isSelected ? null : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF9C27B0) : Colors.white24,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      '$min Min',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
          
          // Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isRunning && !_isPaused)
                _buildControlButton(
                  icon: Icons.play_arrow,
                  label: 'Start',
                  color: const Color(0xFF9C27B0),
                  onPressed: _startTimer,
                ),
              
              if (_isRunning)
                _buildControlButton(
                  icon: Icons.pause,
                  label: 'Pause',
                  color: Colors.amber,
                  onPressed: _pauseTimer,
                ),
              
              if (_isPaused) ...[
                _buildControlButton(
                  icon: Icons.play_arrow,
                  label: 'Weiter',
                  color: Colors.green,
                  onPressed: _resumeTimer,
                ),
                const SizedBox(width: 16),
                _buildControlButton(
                  icon: Icons.stop,
                  label: 'Stop',
                  color: Colors.red,
                  onPressed: _stopTimer,
                ),
              ],
              
              if (_isRunning) ...[
                const SizedBox(width: 16),
                _buildControlButton(
                  icon: Icons.stop,
                  label: 'Stop',
                  color: Colors.red,
                  onPressed: _stopTimer,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPresetsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚡ STANDARD PRESETS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          ..._defaultPresets.map((preset) => _buildPresetCard(preset, isCustom: false)),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              const Text(
                '✨ EIGENE PRESETS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _showAddPresetDialog,
                icon: const Icon(Icons.add_circle, color: Color(0xFF9C27B0)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_customPresets.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Noch keine eigenen Presets',
                  style: TextStyle(color: Colors.white60),
                ),
              ),
            )
          else
            ..._customPresets.map((preset) => _buildPresetCard(preset, isCustom: true)),
        ],
      ),
    );
  }
  
  Widget _buildHistoryTab() {
    if (_sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.self_improvement, size: 64, color: Color(0xFF9C27B0)),
            const SizedBox(height: 16),
            Text(
              'Noch keine Sessions',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        return _buildSessionCard(session);
      },
    );
  }
  
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 32),
      label: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
  
  Widget _buildPresetCard(Map<String, dynamic> preset, {required bool isCustom}) {
    final name = preset['name'] as String;
    final duration = preset['duration'] as int;
    final icon = preset['icon'] as String;
    final minutes = duration ~/ 60;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _selectedDuration = duration);
            _tabController.animateTo(0);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Preset "$name" gewählt: $minutes Min'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$minutes Minuten',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9C27B0),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Color(0xFF9C27B0), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSessionCard(Map<String, dynamic> session) {
    final timestamp = DateTime.parse(session['timestamp'] as String);
    final durationMinutes = session['durationMinutes'] as int;
    final dateStr = '${timestamp.day}.${timestamp.month}.${timestamp.year}';
    final timeStr = '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF9C27B0),
                  const Color(0xFF9C27B0).withValues(alpha: 0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.self_improvement, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$durationMinutes Minuten',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateStr • $timeStr',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9C27B0),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.green, size: 24),
        ],
      ),
    );
  }
  
  void _showAddPresetDialog() {
    final nameController = TextEditingController();
    int customDuration = 600;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Eigenes Preset erstellen',
            style: TextStyle(color: Color(0xFF9C27B0)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Colors.white60),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF9C27B0)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Dauer (Minuten):',
                style: TextStyle(color: Colors.white70),
              ),
              Slider(
                value: customDuration / 60,
                min: 5,
                max: 60,
                divisions: 11,
                activeColor: const Color(0xFF9C27B0),
                label: '${customDuration ~/ 60} Min',
                onChanged: (value) {
                  setDialogState(() => customDuration = (value * 60).toInt());
                },
              ),
              Text(
                '${customDuration ~/ 60} Minuten',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9C27B0),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                
                final preset = {
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'name': nameController.text.trim(),
                  'duration': customDuration,
                  'icon': '⭐',
                };
                
                await StorageService().saveMeditationPreset(preset);
                await _loadData();
                
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                foregroundColor: Colors.white,
              ),
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }
}
