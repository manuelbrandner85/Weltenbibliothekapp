import 'package:flutter/material.dart';
import 'dart:async';
import 'package:weltenbibliothek/services/tool_api_service.dart';

class TraumTagebuchWidget extends StatefulWidget {
  final String roomId;
  const TraumTagebuchWidget({super.key, required this.roomId});
  @override
  State<TraumTagebuchWidget> createState() => _TraumTagebuchWidgetState();
}

class _TraumTagebuchWidgetState extends State<TraumTagebuchWidget> {
  final _apiService = ToolApiService();
  List<Map<String, dynamic>> _traeume = [];
  bool _isLoading = false;
  Timer? _pollTimer;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _symbolsController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadTraeume();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadTraeume());
  }
  
  @override
  void dispose() {
    _pollTimer?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    _symbolsController.dispose();
    super.dispose();
  }
  
  Future<void> _loadTraeume() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getToolData(
        endpoint: '/api/tools/traeume',
        roomId: widget.roomId,
      );
      setState(() {
        _traeume = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _addTraum() async {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Beschreibung eingeben')),
      );
      return;
    }
    try {
      await _apiService.postToolData(
        endpoint: '/api/tools/traeume',
        data: {
          'room_id': widget.roomId,
          'title': _titleController.text,
          'description': _descriptionController.text,
          'symbols': _symbolsController.text,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
      );
      _titleController.clear();
      _descriptionController.clear();
      _symbolsController.clear();
      await _loadTraeume();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Traum dokumentiert!')),
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
          bottom: BorderSide(color: Colors.indigo.withValues(alpha: 0.3), width: 2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo[800]!, Colors.indigo[900]!],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.nightlight_round, color: Colors.indigoAccent, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '📔 TRAUM-TAGEBUCH',
                  style: TextStyle(
                    color: Colors.indigoAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.indigoAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_traeume.length} Träume',
                    style: const TextStyle(color: Colors.indigoAccent, fontSize: 12),
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
                    hintText: 'Traum-Titel (Optional)',
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
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Traum-Beschreibung',
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
                        controller: _symbolsController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Symbole (z.B. Wasser, Fliegen)',
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
                      onPressed: _addTraum,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigoAccent,
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
            child: _isLoading && _traeume.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Colors.indigoAccent))
                : _traeume.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Noch keine Träume dokumentiert.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _traeume.length,
                        itemBuilder: (context, index) {
                          final traum = _traeume[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[850],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.indigoAccent.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (traum['title'] != null && (traum['title'] as String).isNotEmpty)
                                  Text(
                                    traum['title'],
                                    style: const TextStyle(
                                      color: Colors.indigoAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                Text(
                                  traum['description'] ?? '',
                                  style: TextStyle(color: Colors.grey[300], fontSize: 12),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (traum['symbols'] != null && (traum['symbols'] as String).isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '🔮 ${traum['symbols']}',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
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
