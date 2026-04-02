import 'package:flutter/material.dart';
import '../../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:weltenbibliothek/services/tool_api_service.dart';

class TraumTagebuchTool extends StatefulWidget {
  final String realm;
  final String roomId;
  
  const TraumTagebuchTool({
    super.key,
    required this.realm,
    this.roomId = 'astralreisen',
  });

  @override
  State<TraumTagebuchTool> createState() => _TraumTagebuchToolState();
}

class _TraumTagebuchToolState extends State<TraumTagebuchTool> {
  final ToolApiService _api = ToolApiService();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _symbolsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _symbolsController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _api.getToolData(
        endpoint: '/api/tools/traeume',
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
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Beschreibung eingeben')),
      );
      return;
    }
    
    final newItem = {
      'room_id': widget.roomId,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'symbols': _symbolsController.text.trim(),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      await _api.postToolData(
        endpoint: '/api/tools/traeume',
        data: newItem,
      );
      
      _titleController.clear();
      _descriptionController.clear();
      _symbolsController.clear();
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
        endpoint: '/api/tools/traeume',
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
        title: const Text('Traum hinzufügen'),
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
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Traumbeschreibung *'),
                maxLines: 4,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _symbolsController,
                decoration: const InputDecoration(labelText: 'Symbole/Themen'),
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
        title: Text('🌙 TRAUM-TAGEBUCH'),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.nightlight, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Noch keine Träume erfasst',
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
                          leading: const Icon(Icons.nightlight, color: Colors.purple),
                          title: Text(
                            item['title'] ?? 'Traum vom ${DateTime.fromMillisecondsSinceEpoch(item['created_at']).day}.${DateTime.fromMillisecondsSinceEpoch(item['created_at']).month}.',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['description'] ?? '',
                                style: TextStyle(color: Colors.grey[400]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item['symbols'] != null && item['symbols'].toString().isNotEmpty)
                                Text('🔮 ${item['symbols']}', style: TextStyle(color: Colors.grey[500])),
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
