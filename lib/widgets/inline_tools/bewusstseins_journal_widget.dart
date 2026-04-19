import 'package:flutter/material.dart';
import 'dart:async';
import 'package:weltenbibliothek/services/tool_api_service.dart';

class BewusstseinsJournalWidget extends StatefulWidget {
  final String roomId;
  const BewusstseinsJournalWidget({super.key, required this.roomId});
  @override
  State<BewusstseinsJournalWidget> createState() => _BewusstseinsJournalWidgetState();
}

class _BewusstseinsJournalWidgetState extends State<BewusstseinsJournalWidget> {
  final _apiService = ToolApiService();
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = false;
  Timer? _pollTimer;
  final _titleController = TextEditingController();
  final _insightController = TextEditingController();
  final _synchronicityController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadEntries();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadEntries());
  }
  
  @override
  void dispose() {
    _pollTimer?.cancel();
    _titleController.dispose();
    _insightController.dispose();
    _synchronicityController.dispose();
    super.dispose();
  }
  
  Future<void> _loadEntries() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getToolData(
        endpoint: '/api/tools/bewusstseins-eintraege',
        roomId: widget.roomId,
      );
      setState(() {
        _entries = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _addEntry() async {
    if (_insightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Erkenntnis eingeben')),
      );
      return;
    }
    try {
      await _apiService.postToolData(
        endpoint: '/api/tools/bewusstseins-eintraege',
        data: {
          'room_id': widget.roomId,
          'title': _titleController.text,
          'insight': _insightController.text,
          'synchronicity': _synchronicityController.text,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
      );
      _titleController.clear();
      _insightController.clear();
      _synchronicityController.clear();
      await _loadEntries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eintrag gespeichert!')),
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
          bottom: BorderSide(color: Colors.amber.withValues(alpha: 0.3), width: 2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber[800]!, Colors.amber[900]!],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '🔮 BEWUSSTSEINS-JOURNAL',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_entries.length} Einträge',
                    style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Titel (Optional)',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _insightController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Spirituelle Erkenntnis',
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _synchronicityController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Synchronizität (Optional)',
                          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amberAccent,
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
            child: _isLoading && _entries.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Colors.amberAccent))
                : _entries.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Noch keine Einträge.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          final entry = _entries[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[850],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.amberAccent.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (entry['title'] != null && (entry['title'] as String).isNotEmpty)
                                  Text(
                                    entry['title'],
                                    style: const TextStyle(
                                      color: Colors.amberAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                Text(
                                  entry['insight'] ?? '',
                                  style: TextStyle(color: Colors.grey[300], fontSize: 12),
                                ),
                                if (entry['synchronicity'] != null && (entry['synchronicity'] as String).isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '✨ ${entry['synchronicity']}',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 11, fontStyle: FontStyle.italic),
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
