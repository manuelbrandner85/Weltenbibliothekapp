import 'package:flutter/material.dart';
import 'dart:async';
import 'package:weltenbibliothek/services/tool_api_service.dart';

class HeilfrequenzPlayerWidget extends StatefulWidget {
  final String roomId;
  const HeilfrequenzPlayerWidget({super.key, required this.roomId});
  @override
  State<HeilfrequenzPlayerWidget> createState() => _HeilfrequenzPlayerWidgetState();
}

class _HeilfrequenzPlayerWidgetState extends State<HeilfrequenzPlayerWidget> {
  final _apiService = ToolApiService();
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = false;
  Timer? _pollTimer;
  String _selectedFrequency = '396 Hz';
  final _notesController = TextEditingController();
  
  final Map<String, String> _frequencies = {
    '174 Hz': 'Schmerzlinderung',
    '285 Hz': 'Geweberegenierung',
    '396 Hz': 'Befreiung von Angst',
    '417 Hz': 'Wandel und Veränderung',
    '432 Hz': 'Herz-Öffnung',
    '528 Hz': 'Transformation und Heilung',
    '639 Hz': 'Harmonische Beziehungen',
    '741 Hz': 'Erwachen der Intuition',
    '852 Hz': 'Rückkehr zur spirituellen Ordnung',
    '963 Hz': 'Einheit und Vollkommenheit',
  };
  
  @override
  void initState() {
    super.initState();
    _loadSessions();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadSessions());
  }
  
  @override
  void dispose() {
    _pollTimer?.cancel();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSessions() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getToolData(
        endpoint: '/api/tools/heilfrequenz-sessions',
        roomId: widget.roomId,
      );
      setState(() {
        _sessions = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _addSession() async {
    try {
      await _apiService.postToolData(
        endpoint: '/api/tools/heilfrequenz-sessions',
        data: {
          'room_id': widget.roomId,
          'frequency': _selectedFrequency,
          'notes': _notesController.text,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
      );
      _notesController.clear();
      await _loadSessions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session gespeichert!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          bottom: BorderSide(color: Colors.teal.withValues(alpha: 0.3), width: 2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal[800]!, Colors.teal[900]!],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.graphic_eq, color: Colors.tealAccent, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '🎵 HEILFREQUENZ-PLAYER',
                  style: TextStyle(
                    color: Colors.tealAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.tealAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_sessions.length} Sessions',
                    style: const TextStyle(color: Colors.tealAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedFrequency,
                    isExpanded: true,
                    dropdownColor: Colors.grey[850],
                    underline: Container(),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: _frequencies.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text('${entry.key} - ${entry.value}'),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedFrequency = value!),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _notesController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Erfahrungen, Wirkung...',
                          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.add, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: _isLoading && _sessions.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
                : _sessions.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Noch keine Sessions.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _sessions.length,
                        itemBuilder: (context, index) {
                          final session = _sessions[index];
                          final freq = session['frequency'] ?? '';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[850],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.tealAccent.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  freq,
                                  style: const TextStyle(
                                    color: Colors.tealAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                if (_frequencies.containsKey(freq))
                                  Text(
                                    _frequencies[freq]!,
                                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                  ),
                                if (session['notes'] != null && (session['notes'] as String).isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    session['notes'],
                                    style: TextStyle(color: Colors.grey[300], fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
