// Ähnlich wie News Board, aber für Artefakte
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:weltenbibliothek/services/tool_api_service.dart';
import 'dart:async';

class ArtefaktCollectionWidget extends StatefulWidget {
  final String roomId;
  const ArtefaktCollectionWidget({super.key, required this.roomId});
  @override
  State<ArtefaktCollectionWidget> createState() => _ArtefaktCollectionWidgetState();
}

class _ArtefaktCollectionWidgetState extends State<ArtefaktCollectionWidget> {
  final ToolApiService _api = ToolApiService();
  List<Map<String, dynamic>> _items = [];
  Timer? _pollTimer;
  
  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }
  
  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _load() async {
    try {
      final items = await _api.getToolData(endpoint: '/api/tools/artefakte', roomId: widget.roomId, limit: 5);
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ ArtefaktCollection: Failed to load data - $e');
      }
      // Silently fail - widget shows empty state
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
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.museum, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Text('ARTEFAKT-SAMMLUNG', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${_items.length}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          if (_items.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final item = _items[i];
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.inventory, color: Colors.amber, size: 16),
                        const SizedBox(height: 4),
                        Text(
                          item['name'] ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
