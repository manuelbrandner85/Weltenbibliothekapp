import 'package:flutter/material.dart';
import 'package:weltenbibliothek/services/tool_api_service.dart';

class ConnectionsBoardTool extends StatefulWidget {
  final String realm;
  final String roomId;
  
  const ConnectionsBoardTool({
    super.key,
    required this.realm,
    this.roomId = 'verschwoerungen',
  });

  @override
  State<ConnectionsBoardTool> createState() => _ConnectionsBoardToolState();
}

class _ConnectionsBoardToolState extends State<ConnectionsBoardTool> {
  final ToolApiService _api = ToolApiService();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  final TextEditingController _entity1Controller = TextEditingController();
  final TextEditingController _entity2Controller = TextEditingController();
  final TextEditingController _connectionController = TextEditingController();
  final TextEditingController _evidenceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _entity1Controller.dispose();
    _entity2Controller.dispose();
    _connectionController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _api.getToolData(
        endpoint: '/api/tools/connections',
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
    if (_entity1Controller.text.trim().isEmpty || _entity2Controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte beide Entitäten eingeben')),
      );
      return;
    }
    
    final newItem = {
      'room_id': widget.roomId,
      'entity1': _entity1Controller.text.trim(),
      'entity2': _entity2Controller.text.trim(),
      'connection': _connectionController.text.trim(),
      'evidence': _evidenceController.text.trim(),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      await _api.postToolData(
        endpoint: '/api/tools/connections',
        data: newItem,
      );
      
      _entity1Controller.clear();
      _entity2Controller.clear();
      _connectionController.clear();
      _evidenceController.clear();
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
        endpoint: '/api/tools/connections',
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
        title: const Text('Verbindung hinzufügen'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _entity1Controller,
                decoration: const InputDecoration(labelText: 'Entität 1 *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _entity2Controller,
                decoration: const InputDecoration(labelText: 'Entität 2 *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _connectionController,
                decoration: const InputDecoration(labelText: 'Verbindung'),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _evidenceController,
                decoration: const InputDecoration(labelText: 'Beweise'),
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
        title: Text('👁️ CONNECTIONS BOARD'),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_tree, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Noch keine Verbindungen dokumentiert',
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
                          leading: const Icon(Icons.account_tree, color: Colors.purple),
                          title: Text(
                            '${item['entity1']} ↔️ ${item['entity2']}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            item['connection'] ?? '',
                            style: TextStyle(color: Colors.grey[400]),
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
