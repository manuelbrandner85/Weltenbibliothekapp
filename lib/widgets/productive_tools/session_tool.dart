import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/cloudflare_api_service.dart';
import '../../services/chat_tools_service.dart';  // ✅ ChatToolsService

/// ⏱️ GRUPPEN-SESSIONS - Synchronisierte Meditations-Sessions
/// ERWEITERT: 20+ Techniken, Schwierigkeit, Fokus-Bereich
class SessionTool extends StatefulWidget {
  final String roomId;
  const SessionTool({super.key, required this.roomId});

  @override
  State<SessionTool> createState() => _SessionToolState();
}

class _SessionToolState extends State<SessionTool> {
  // UNUSED FIELD: static const String _baseUrl = 'https://weltenbibliothek-community-api.brandy13062.workers.dev';
  final CloudflareApiService _api = CloudflareApiService();
  final ChatToolsService _toolsService = ChatToolsService();  // ✅ Tools Service

  List<Session> _sessions = [];
  bool _isLoading = false;
  Timer? _refreshTimer;
  Timer? _meditationTimer;
  int _remainingSeconds = 0;
  bool _isMeditating = false;

  final TextEditingController _nameController = TextEditingController();
  int _selectedDuration = 10;
  String _selectedTechnik = 'Atemmeditation';
  String _selectedSchwierigkeit = 'Mittel';
  String _selectedFokus = 'Entspannung';

  final List<int> _durationOptions = [5, 10, 15, 20, 30, 45, 60];

  // ✨ ERWEITERT: 25+ Meditationstechniken
  final List<String> _techniken = [
    'Atemmeditation',
    'Vipassana',
    'Zen-Meditation',
    'Achtsamkeitsmeditation',
    'Transzendentale Meditation',
    'Loving-Kindness (Metta)',
    'Body-Scan',
    'Chakra-Meditation',
    'Mantra-Meditation',
    'Gehmeditation',
    'Kundalini',
    'Yoga Nidra',
    'Tonglen',
    'Zazen',
    'Qigong-Meditation',
    'Trataka (Kerzenmeditation)',
    'Sound-Meditation',
    'Geführte Visualisierung',
    'Dynamische Meditation',
    'Stille Meditation',
    'Tantra-Meditation',
    'Theta-Meditation',
    'Herzmeditation',
    'Dankbarkeitsmeditation',
    'Natur-Meditation',
  ];

  final List<String> _schwierigkeiten = [
    'Anfänger',
    'Leicht',
    'Mittel',
    'Fortgeschritten',
    'Experte',
  ];

  final List<String> _fokusOptionen = [
    'Entspannung',
    'Konzentration',
    'Bewusstsein',
    'Mitgefühl',
    'Energie',
    'Heilung',
    'Intuition',
    'Kreativität',
    'Loslassen',
    'Selbstliebe',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _meditationTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    try {
      setState(() => _isLoading = true);
      
      // ✅ Nutze ChatToolsService statt direkten API-Call
      final results = await _toolsService.getToolResults(
        roomId: widget.roomId,
        toolType: 'session',
        limit: 100,
      );
      
      setState(() {
        _sessions = results.map((result) {
          final data = result['data'] as Map<String, dynamic>;
          return Session(
            id: result['id'],
            name: data['name'] ?? 'Unbenannt',
            technique: data['technique'] ?? 'Atemmeditation',
            difficulty: data['difficulty'] ?? 'Mittel',
            focus: data['focus'] ?? 'Entspannung',
            duration: data['duration'] ?? 10,
            timestamp: DateTime.tryParse(result['created_at']) ?? DateTime.now(),
          );
        }).toList();
        _sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      });
    } catch (e) {
      debugPrint('Fehler beim Laden: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startMeditation() {
    setState(() {
      _isMeditating = true;
      _remainingSeconds = _selectedDuration * 60;
    });

    _meditationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        setState(() => _isMeditating = false);
        _showToast('Meditation abgeschlossen! 🧘', Colors.green);
      }
    });
  }

  void _stopMeditation() {
    _meditationTimer?.cancel();
    setState(() => _isMeditating = false);
  }

  // TODO: Review unused method: _submitSession
  // Future<void> _submitSession() async {
    // if (_nameController.text.trim().isEmpty) {
      // _showToast('Bitte Session-Name eingeben', Colors.orange);
      // return;
    // }
 //     // try {
      // final sessionName = _nameController.text.trim();
      // final username = 'Meditierende${DateTime.now().millisecondsSinceEpoch % 1000}';
       //       // ✅ Nutze ChatToolsService zum Speichern
      // await _toolsService.saveToolResult(
        // roomId: widget.roomId,
        // toolType: 'session',
        // username: username,
        // data: {
          // 'name': sessionName,
          // 'technique': _selectedTechnik,
          // 'difficulty': _selectedSchwierigkeit,
          // 'focus': _selectedFokus,
          // 'duration': _selectedDuration,
          // 'created_at': DateTime.now().toIso8601String(),
        // },
      // );
 //       // _showToast('✅ Session gespeichert!', Colors.green);
      // _clearForm();
      // await _loadData();  // Reload sessions
       //       // 🆕 Sende Tool-Aktivitäts-Nachricht im Chat
      // try {
        // await _api.sendToolActivityMessage(
          // roomId: widget.roomId,
          // realm: 'energie',
          // username: username,
          // toolName: 'Meditation',
          // activity: '$_selectedTechnik ($_selectedDuration Min)',
        // );
      // } catch (e) {
        // debugPrint('⚠️ Tool-Nachricht konnte nicht gesendet werden: $e');
      // }
    // } catch (e) {
      // _showToast('❌ Fehler: $e', Colors.red);
    // }
  // }

  // TODO: Review unused method: _clearForm
  // void _clearForm() {
    // _nameController.clear();
    // setState(() {
      // _selectedDuration = 10;
      // _selectedTechnik = 'Atemmeditation';
      // _selectedSchwierigkeit = 'Mittel';
      // _selectedFokus = 'Entspannung';
    // });
  // }

  void _showToast(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uniqueUsers = _sessions.length;
    final totalMinutes = _sessions.fold<int>(0, (sum, s) => sum + s.duration);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.indigo.shade900, Colors.deepPurple.shade800],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const Text('⏱️ GRUPPEN-SESSIONS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard('$uniqueUsers', 'Teilnehmer', Icons.group),
                    _buildStatCard('${_sessions.length}', 'Sessions', Icons.self_improvement),
                    _buildStatCard('${totalMinutes}min', 'Gesamt', Icons.timer),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_isMeditating) _buildMeditationTimer() else _buildInputForm(),
                  const SizedBox(height: 24),
                  _buildSessionList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade300, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.indigo.shade200, size: 28),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.indigo.shade200)),
        ],
      ),
    );
  }

  Widget _buildMeditationTimer() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo.shade300, width: 3),
      ),
      child: Column(
        children: [
          const Icon(Icons.self_improvement, size: 80, color: Colors.white),
          const SizedBox(height: 20),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            _selectedTechnik,
            style: TextStyle(fontSize: 18, color: Colors.indigo.shade200, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _stopMeditation,
            icon: const Icon(Icons.stop),
            label: const Text('BEENDEN'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('➕ Neue Session starten', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          
          // Session Name
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Session-Name',
              labelStyle: TextStyle(color: Colors.indigo.shade200),
              prefixIcon: const Icon(Icons.title, color: Colors.indigo),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          // ✨ ERWEITERT: Technik-Dropdown (25+ Optionen)
          DropdownButtonFormField<String>(
            initialValue: _selectedTechnik,
            dropdownColor: Colors.indigo.shade900,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Meditations-Technik',
              labelStyle: TextStyle(color: Colors.indigo.shade200),
              prefixIcon: const Icon(Icons.psychology, color: Colors.indigo),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _techniken.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedTechnik = v);
            },
          ),
          const SizedBox(height: 12),

          // Dauer
          DropdownButtonFormField<int>(
            initialValue: _selectedDuration,
            dropdownColor: Colors.indigo.shade900,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Dauer (Minuten)',
              labelStyle: TextStyle(color: Colors.indigo.shade200),
              prefixIcon: const Icon(Icons.timer, color: Colors.indigo),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _durationOptions.map((d) => DropdownMenuItem(value: d, child: Text('$d Minuten'))).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedDuration = v);
            },
          ),
          const SizedBox(height: 12),

          // ✨ ERWEITERT: Schwierigkeit
          DropdownButtonFormField<String>(
            initialValue: _selectedSchwierigkeit,
            dropdownColor: Colors.indigo.shade900,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Schwierigkeit',
              labelStyle: TextStyle(color: Colors.indigo.shade200),
              prefixIcon: const Icon(Icons.bar_chart, color: Colors.indigo),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _schwierigkeiten.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedSchwierigkeit = v);
            },
          ),
          const SizedBox(height: 12),

          // ✨ ERWEITERT: Fokus-Bereich
          DropdownButtonFormField<String>(
            initialValue: _selectedFokus,
            dropdownColor: Colors.indigo.shade900,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Fokus',
              labelStyle: TextStyle(color: Colors.indigo.shade200),
              prefixIcon: const Icon(Icons.center_focus_strong, color: Colors.indigo),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _fokusOptionen.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedFokus = v);
            },
          ),
          const SizedBox(height: 16),

          // Start Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startMeditation,
              icon: const Icon(Icons.play_arrow),
              label: const Text('SESSION STARTEN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionList() {
    if (_sessions.isEmpty) {
      return Center(child: Column(children: [
        const SizedBox(height: 40),
        Icon(Icons.self_improvement_outlined, size: 64, color: Colors.indigo.shade200),
        const SizedBox(height: 16),
        Text('Noch keine Sessions', style: TextStyle(color: Colors.indigo.shade200, fontSize: 18)),
      ]));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🧘 VERGANGENE SESSIONS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        ..._sessions.map((s) => _buildSessionCard(s)),
      ],
    );
  }

  Widget _buildSessionCard(Session session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: Colors.indigo, shape: BoxShape.circle),
                child: Center(child: Text("Nutzer"[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Nutzer", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('${session.duration} Min', style: TextStyle(color: Colors.indigo.shade200, fontSize: 12)),
                  ],
                ),
              ),
              // Schwierigkeit Badge
              if (session.difficulty.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(session.difficulty),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    session.difficulty,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(session.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.psychology, size: 16, color: Colors.indigo.shade200),
              const SizedBox(width: 6),
              Text(session.technique, style: TextStyle(color: Colors.indigo.shade100)),
            ],
          ),
          if (session.focus.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.center_focus_strong, size: 16, color: Colors.indigo.shade200),
                const SizedBox(width: 6),
                Text('Fokus: ${session.focus}', style: TextStyle(color: Colors.indigo.shade100)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Anfänger':
        return Colors.green.shade700;
      case 'Leicht':
        return Colors.lightGreen.shade700;
      case 'Mittel':
        return Colors.orange.shade700;
      case 'Fortgeschritten':
        return Colors.deepOrange.shade700;
      case 'Experte':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}

class Session {
  final String id, name, technique;
  final String difficulty, focus;
  final int duration;
  final DateTime timestamp;

  Session({
    required this.id,
    required this.name,
    required this.technique,
    required this.difficulty,
    required this.focus,
    required this.duration,
    required this.timestamp,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      technique: json['technique']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? '',
      focus: json['focus']?.toString() ?? '',
      duration: json['duration'] as int? ?? 10,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
