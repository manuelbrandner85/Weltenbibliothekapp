import 'package:flutter/material.dart';
import '../../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:weltenbibliothek/services/tool_api_service.dart';

class BewusstseinsJournalTool extends StatefulWidget {
  final String realm;
  final String roomId;
  
  const BewusstseinsJournalTool({
    super.key,
    required this.realm,
    this.roomId = 'spiritualitaet',
  });

  @override
  State<BewusstseinsJournalTool> createState() => _BewusstseinsJournalToolState();
}

class _BewusstseinsJournalToolState extends State<BewusstseinsJournalTool> {
  final ToolApiService _api = ToolApiService();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _insightController = TextEditingController();
  final TextEditingController _synchronicityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _insightController.dispose();
    _synchronicityController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _api.getToolData(
        endpoint: '/api/tools/bewusstseins-eintraege',
        roomId: widget.roomId,
      );
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e')),
        );
      }
    }
  }

  Future<void> _addItem() async {
    if (_insightController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Erkenntnis eingeben')),
      );
      return;
    }
    
    final newItem = {
      'room_id': widget.roomId,
      'title': _titleController.text.trim(),
      'insight': _insightController.text.trim(),
      'synchronicity': _synchronicityController.text.trim(),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      await _api.postToolData(
        endpoint: '/api/tools/bewusstseins-eintraege',
        data: newItem,
      );
      
      _titleController.clear();
      _insightController.clear();
      _synchronicityController.clear();
      await _loadItems();
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Erfolgreich hinzugefügt!')),
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

  Future<void> _deleteItem(String id) async {
    try {
      await _api.deleteToolData(
        endpoint: '/api/tools/bewusstseins-eintraege',
        itemId: id,
      );
      await _loadItems();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Gelöscht!')),
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

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eintrag hinzufügen'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titel (optional)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _insightController,
                decoration: const InputDecoration(labelText: 'Erkenntnis *'),
                maxLines: 4,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _synchronicityController,
                decoration: const InputDecoration(labelText: 'Synchronizität'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: _addItem,
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text('✨ BEWUSSTSEINS-JOURNAL'),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Noch keine Einträge erfasst',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadItems,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        color: const Color(0xFF1A1A1A),
                        child: ListTile(
                          leading: const Icon(Icons.auto_awesome, color: Colors.amber),
                          title: Text(
                            item['title'] ?? 'Eintrag vom ${DateTime.fromMillisecondsSinceEpoch(item['created_at']).day}.${DateTime.fromMillisecondsSinceEpoch(item['created_at']).month}.',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['insight'] ?? '',
                                style: TextStyle(color: Colors.grey[400]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item['synchronicity'] != null && item['synchronicity'].toString().isNotEmpty)
                                Text('✨ ${item['synchronicity']}', style: TextStyle(color: Colors.grey[500])),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteItem(item['id'].toString()),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
