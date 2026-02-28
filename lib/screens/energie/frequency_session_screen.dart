import 'package:flutter/material.dart';
import '../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'dart:async';
import '../../services/group_tools_service.dart';
import '../../services/user_service.dart'; // 🆕 User Service für Auth
import '../../widgets/frequency_audio_player.dart';

/// 🎵 FREQUENZ-SESSIONS SCREEN
/// Gemeinsame Heilfrequenz-Sessions mit Timer
class FrequencySessionScreen extends StatefulWidget {
  final String roomId;
  
  const FrequencySessionScreen({
    super.key,
    required this.roomId,
  });

  @override
  State<FrequencySessionScreen> createState() => _FrequencySessionScreenState();
}

class _FrequencySessionScreenState extends State<FrequencySessionScreen> {
  final GroupToolsService _toolsService = GroupToolsService();
  
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = false;
  
  // Frequency presets (ALL 10 frequencies now have audio support!)
  final Map<String, Map<String, dynamic>> _frequencies = {
    '174': {'name': '174 Hz - Schmerzlinderung', 'color': const Color(0xFF1976D2), 'effect': 'Natürliches Anästhetikum', 'hasAudio': true},
    '285': {'name': '285 Hz - Geweberegenierung', 'color': const Color(0xFF388E3C), 'effect': 'Zellheilung & Verjüngung', 'hasAudio': true},
    '396': {'name': '396 Hz - Angst befreien', 'color': Colors.red, 'effect': 'Befreiung von Angst und Schuld', 'hasAudio': true},
    '417': {'name': '417 Hz - Veränderung', 'color': Colors.orange, 'effect': 'Negative Energien transformieren', 'hasAudio': true},
    '432': {'name': '432 Hz - Universelle Heilung', 'color': Colors.amber, 'effect': 'Universelle Heilfrequenz', 'hasAudio': true},
    '528': {'name': '528 Hz - DNA-Reparatur', 'color': const Color(0xFF4CAF50), 'effect': 'DNA-Heilung und Liebe', 'hasAudio': true},
    '639': {'name': '639 Hz - Beziehungen', 'color': Colors.green, 'effect': 'Harmonie und Verbindung', 'hasAudio': true},
    '741': {'name': '741 Hz - Erwachen', 'color': Colors.blue, 'effect': 'Intuition und Bewusstsein', 'hasAudio': true},
    '852': {'name': '852 Hz - Spiritualität', 'color': Colors.indigo, 'effect': 'Spirituelles Erwachen', 'hasAudio': true},
    '963': {'name': '963 Hz - Einheit', 'color': Colors.purple, 'effect': 'Kosmische Einheit', 'hasAudio': true},
  };
  
  @override
  void initState() {
    super.initState();
    _loadSessions();
  }
  
  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await _toolsService.getFrequencySessions(roomId: widget.roomId);
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  void _showCreateSessionDialog() {
    String? selectedFrequency;
    int duration = 10;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('🎵 Neue Frequenz-Session', style: TextStyle(color: Colors.amber)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Wähle eine Heilfrequenz:', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                
                // Frequency selection
                ..._frequencies.entries.map((entry) {
                  final freq = entry.key;
                  final data = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: selectedFrequency == freq ? data['color'].withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selectedFrequency == freq ? data['color'] : Colors.grey[700]!,
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      title: Text(data['name'], style: TextStyle(color: data['color'], fontWeight: FontWeight.bold)),
                      subtitle: Text(data['effect'], style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      onTap: () {
                        setDialogState(() => selectedFrequency = freq);
                      },
                    ),
                  );
                }),
                
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 16),
                
                // Duration slider
                const Text('Session-Dauer:', style: TextStyle(color: Colors.white70)),
                Slider(
                  value: duration.toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 11,
                  label: '$duration Min',
                  activeColor: Colors.amber,
                  onChanged: (value) {
                    setDialogState(() => duration = value.toInt());
                  },
                ),
                Center(
                  child: Text(
                    '$duration Minuten',
                    style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: selectedFrequency == null ? null : () async {
                Navigator.pop(context);
                await _createSession(selectedFrequency!, duration);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: const Text('Session starten'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showFrequencyPlayer(BuildContext context, String frequency, Map<String, dynamic> freqData, int durationMinutes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🎵 ${freqData['name']}',
                    style: TextStyle(
                      color: freqData['color'],
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Effect description
              Text(
                freqData['effect'],
                style: const TextStyle(color: Colors.white60, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Audio Player
              FrequencyAudioPlayer(
                frequencyHz: frequency,
                accentColor: freqData['color'],
                durationMinutes: durationMinutes,
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _createSession(String frequency, int duration) async {
    try {
      final freqData = _frequencies[frequency]!;
      await _toolsService.createFrequencySession(
        roomId: widget.roomId,
        userId: UserService.getCurrentUserId(), // 🔥 Real User ID from UserService
        frequencyHz: frequency,
        durationMinutes: duration,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${freqData['name']} Session gestartet!'),
          backgroundColor: Colors.green,
        ),
      );
      
      await _loadSessions();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Fehler: $e'), backgroundColor: Colors.red),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text('🎵 Frequenz-Sessions'),
        backgroundColor: const Color(0xFF1B263B),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : _sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.music_note, size: 64, color: Colors.white24),
                      const SizedBox(height: 16),
                      const Text(
                        'Keine Sessions vorhanden',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showCreateSessionDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Erste Session starten'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    final freq = session['frequency'] ?? '528';
                    final freqData = _frequencies[freq] ?? _frequencies['528']!;
                    
                    return Card(
                      color: const Color(0xFF1A1A2E),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: freqData['color'].withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: freqData['color'], width: 2),
                          ),
                          child: Center(
                            child: Text(
                              '$freq\nHz',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: freqData['color'],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          freqData['name'],
                          style: TextStyle(color: freqData['color'], fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              freqData['effect'],
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.timer, size: 14, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  '${session['duration_minutes']} Min',
                                  style: const TextStyle(color: Colors.amber, fontSize: 12),
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.person, size: 14, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text(
                                  session['created_by'] ?? 'Unbekannt',
                                  style: const TextStyle(color: Colors.blue, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Icon(
                          freqData['hasAudio'] == true 
                              ? Icons.play_circle_filled 
                              : Icons.music_note,
                          color: freqData['hasAudio'] == true 
                              ? Colors.amber 
                              : Colors.grey,
                        ),
                        onTap: () {
                          if (freqData['hasAudio'] == true) {
                            _showFrequencyPlayer(context, freq, freqData, session['duration_minutes']);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('ℹ️ Audio für ${freqData['name']} noch nicht verfügbar'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSessionDialog,
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Neue Session'),
      ),
    );
  }
}
