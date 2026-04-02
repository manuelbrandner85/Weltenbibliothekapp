import 'package:flutter/material.dart';
import '../../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:weltenbibliothek/services/tool_api_service.dart';

class PatentArchivTool extends StatefulWidget {
  final String realm;
  final String roomId;
  
  const PatentArchivTool({
    super.key,
    required this.realm,
    this.roomId = 'wissenschaft',
  });

  @override
  State<PatentArchivTool> createState() => _PatentArchivToolState();
}

class _PatentArchivToolState extends State<PatentArchivTool> {
  final ToolApiService _api = ToolApiService();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _inventorController = TextEditingController();
  final TextEditingController _patentIdController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _inventorController.dispose();
    _patentIdController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _api.getToolData(
        endpoint: '/api/tools/patente',
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
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Titel eingeben')),
      );
      return;
    }
    
    final newItem = {
      'room_id': widget.roomId,
      'title': _titleController.text.trim(),
      'inventor': _inventorController.text.trim(),
      'patent_id': _patentIdController.text.trim(),
      'description': _descriptionController.text.trim(),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      await _api.postToolData(
        endpoint: '/api/tools/patente',
        data: newItem,
      );
      
      _titleController.clear();
      _inventorController.clear();
      _patentIdController.clear();
      _descriptionController.clear();
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
        endpoint: '/api/tools/patente',
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
        title: const Text('Patent hinzufügen'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Patent-Titel *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _inventorController,
                decoration: const InputDecoration(labelText: 'Erfinder'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _patentIdController,
                decoration: const InputDecoration(labelText: 'Patent-Nummer'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Beschreibung'),
                maxLines: 3,
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
        title: Text('💡 PATENT-ARCHIV'),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lightbulb, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Noch keine Patente erfasst',
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
                          leading: const Icon(Icons.lightbulb, color: Colors.blue),
                          title: Text(
                            item['title'] ?? '',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item['inventor'] != null && item['inventor'].toString().isNotEmpty)
                                Text('👤 ${item['inventor']}', style: TextStyle(color: Colors.grey[400])),
                              if (item['patent_id'] != null && item['patent_id'].toString().isNotEmpty)
                                Text('📄 ${item['patent_id']}', style: TextStyle(color: Colors.grey[400])),
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
