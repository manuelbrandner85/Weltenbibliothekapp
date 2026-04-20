import 'package:flutter/material.dart';
import 'dart:async';
import 'package:weltenbibliothek/services/tool_api_service.dart';

class PatentArchivWidget extends StatefulWidget {
  final String roomId;
  const PatentArchivWidget({super.key, required this.roomId});
  @override
  State<PatentArchivWidget> createState() => _PatentArchivWidgetState();
}

class _PatentArchivWidgetState extends State<PatentArchivWidget> {
  final _apiService = ToolApiService();
  List<Map<String, dynamic>> _patente = [];
  bool _isLoading = false;
  Timer? _pollTimer;
  final _titleController = TextEditingController();
  final _inventorController = TextEditingController();
  final _patentIdController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadPatente();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadPatente());
  }
  
  @override
  void dispose() {
    _pollTimer?.cancel();
    _titleController.dispose();
    _inventorController.dispose();
    _patentIdController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _loadPatente() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getToolData(
        endpoint: '/api/tools/patente',
        roomId: widget.roomId,
      );
      setState(() {
        _patente = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _addPatent() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Titel eingeben')),
      );
      return;
    }
    try {
      await _apiService.postToolData(
        endpoint: '/api/tools/patente',
        data: {
          'room_id': widget.roomId,
          'title': _titleController.text,
          'inventor': _inventorController.text,
          'patent_id': _patentIdController.text,
          'description': _descriptionController.text,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
      );
      _titleController.clear();
      _inventorController.clear();
      _patentIdController.clear();
      _descriptionController.clear();
      await _loadPatente();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patent hinzugefügt!')),
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
          bottom: BorderSide(color: Colors.blue.withValues(alpha: 0.3), width: 2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[800]!, Colors.blue[900]!],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.science, color: Colors.blueAccent, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '📜 PATENT-ARCHIV',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_patente.length} Patente',
                    style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
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
                    hintText: 'Patent-Titel',
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inventorController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Erfinder',
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
                    Expanded(
                      child: TextField(
                        controller: _patentIdController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Patent-Nr.',
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
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _descriptionController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Beschreibung',
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
                      onPressed: _addPatent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
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
            child: _isLoading && _patente.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                : _patente.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Noch keine Patente archiviert.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _patente.length,
                        itemBuilder: (context, index) {
                          final patent = _patente[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[850],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blueAccent.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patent['title'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                if (patent['inventor'] != null && (patent['inventor'] as String).isNotEmpty)
                                  Text(
                                    'von ${patent['inventor']}',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                  ),
                                if (patent['patent_id'] != null && (patent['patent_id'] as String).isNotEmpty)
                                  Text(
                                    'Nr. ${patent['patent_id']}',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                  ),
                                if (patent['description'] != null && (patent['description'] as String).isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    patent['description'],
                                    style: TextStyle(color: Colors.grey[300], fontSize: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
