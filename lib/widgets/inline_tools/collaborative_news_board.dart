import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:weltenbibliothek/services/tool_api_service.dart';
import 'dart:async';

class CollaborativeNewsBoard extends StatefulWidget {
  final String roomId;
  
  const CollaborativeNewsBoard({super.key, required this.roomId});

  @override
  State<CollaborativeNewsBoard> createState() => _CollaborativeNewsBoardState();
}

class _CollaborativeNewsBoardState extends State<CollaborativeNewsBoard> {
  final ToolApiService _api = ToolApiService();
  final _titleController = TextEditingController();
  final _sourceController = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  Timer? _pollTimer;
  bool _showForm = false;
  
  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _load(silent: true));
  }
  
  @override
  void dispose() {
    _pollTimer?.cancel();
    _titleController.dispose();
    _sourceController.dispose();
    super.dispose();
  }
  
  Future<void> _load({bool silent = false}) async {
    try {
      final items = await _api.getToolData(
        endpoint: '/api/tools/news-tracker',
        roomId: widget.roomId,
        limit: 10,
      );
      if (mounted) setState(() => _items = items);
    } catch (e) {
   if (kDebugMode) {
     debugPrint('⚠️ CollaborativeNewsBoard: Error - $e');
   }
   // Silently fail - widget remains functional
 }
  }
  
  Future<void> _add() async {
    if (_titleController.text.trim().isEmpty) return;
    try {
      await _api.postToolData(
        endpoint: '/api/tools/news-tracker',
        data: {
          'room_id': widget.roomId,
          'title': _titleController.text.trim(),
          'source': _sourceController.text.trim(),
          'link': '',
          'notes': '',
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
      );
      _titleController.clear();
      _sourceController.clear();
      setState(() => _showForm = false);
      await _load();
    } catch (e) {
   if (kDebugMode) {
     debugPrint('⚠️ CollaborativeNewsBoard: Error - $e');
   }
   // Silently fail - widget remains functional
 }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.newspaper, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              const Text('RESEARCH BOARD', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${_items.length}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              IconButton(
                icon: Icon(_showForm ? Icons.close : Icons.add, size: 18),
                color: Colors.red,
                onPressed: () => setState(() => _showForm = !_showForm),
              ),
            ],
          ),
          if (_showForm) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Titel',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                isDense: true,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _sourceController,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Quelle',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                isDense: true,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _add,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Hinzufügen', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
          if (_items.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final item = _items[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.article, color: Colors.red, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] ?? '',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item['source'] != null && item['source'].toString().isNotEmpty)
                                Text(
                                  item['source'],
                                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                                  maxLines: 1,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
