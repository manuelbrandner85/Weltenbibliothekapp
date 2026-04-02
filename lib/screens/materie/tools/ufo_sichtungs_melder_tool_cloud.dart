import 'package:flutter/material.dart';
import '../../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:weltenbibliothek/services/tool_api_service.dart';

class UfoSichtungsMelderTool extends StatefulWidget {
  final String realm;
  final String roomId;
  
  const UfoSichtungsMelderTool({
    super.key,
    required this.realm,
    this.roomId = 'ufos',
  });

  @override
  State<UfoSichtungsMelderTool> createState() => _UfoSichtungsMelderToolState();
}

class _UfoSichtungsMelderToolState extends State<UfoSichtungsMelderTool> {
  final ToolApiService _api = ToolApiService();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _verified = 'unverified';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _api.getToolData(
        endpoint: '/api/tools/ufo-sichtungen',
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
    if (_locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Ort eingeben')),
      );
      return;
    }
    
    final newItem = {
      'room_id': widget.roomId,
      'location': _locationController.text.trim(),
      'description': _descriptionController.text.trim(),
      'verified': _verified,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      await _api.postToolData(
        endpoint: '/api/tools/ufo-sichtungen',
        data: newItem,
      );
      
      _locationController.clear();
      _descriptionController.clear();
      setState(() => _verified = 'unverified');
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
        endpoint: '/api/tools/ufo-sichtungen',
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
        title: const Text('UFO-Sichtung melden'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Ort *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Beschreibung'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _verified,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'unverified', child: Text('Unverifiziert')),
                  DropdownMenuItem(value: 'verified', child: Text('Verifiziert')),
                ],
                onChanged: (value) => setState(() => _verified = value!),
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
        title: Text('🛸 UFO-SICHTUNGS-MELDER'),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flight, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Noch keine Sichtungen gemeldet',
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
                          leading: Icon(
                            Icons.flight,
                            color: item['verified'] == 'verified' ? Colors.green : Colors.orange,
                          ),
                          title: Text(
                            item['location'] ?? '',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            item['description'] ?? '',
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
