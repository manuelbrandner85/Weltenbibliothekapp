import 'package:flutter/material.dart';
import '../../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:weltenbibliothek/services/tool_api_service.dart';

class HeilfrequenzPlayerTool extends StatefulWidget {
  final String realm;
  final String roomId;
  
  const HeilfrequenzPlayerTool({
    super.key,
    required this.realm,
    this.roomId = 'heilung',
  });

  @override
  State<HeilfrequenzPlayerTool> createState() => _HeilfrequenzPlayerToolState();
}

class _HeilfrequenzPlayerToolState extends State<HeilfrequenzPlayerTool> {
  final ToolApiService _api = ToolApiService();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  final TextEditingController _notesController = TextEditingController();
  String _frequency = '396';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _api.getToolData(
        endpoint: '/api/tools/heilfrequenz-sessions',
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

    
    final newItem = {
      'room_id': widget.roomId,
      'frequency': _frequency,
      'notes': _notesController.text.trim(),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      await _api.postToolData(
        endpoint: '/api/tools/heilfrequenz-sessions',
        data: newItem,
      );
      
      _notesController.clear();
      setState(() => _frequency = '396');
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
        endpoint: '/api/tools/heilfrequenz-sessions',
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
        title: const Text('Session speichern'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _frequency,
                decoration: const InputDecoration(labelText: 'Frequenz'),
                items: const [
                  DropdownMenuItem(value: '174', child: Text('174 Hz - Schmerzlinderung')),
                  DropdownMenuItem(value: '285', child: Text('285 Hz - Geweberegenierung')),
                  DropdownMenuItem(value: '396', child: Text('396 Hz - Befreiung von Angst')),
                  DropdownMenuItem(value: '417', child: Text('417 Hz - Resonanz & Veränderung')),
                  DropdownMenuItem(value: '432', child: Text('432 Hz - Herz-Öffnung')),
                  DropdownMenuItem(value: '528', child: Text('528 Hz - Transformation')),
                  DropdownMenuItem(value: '639', child: Text('639 Hz - Harmonische Beziehungen')),
                  DropdownMenuItem(value: '741', child: Text('741 Hz - Erwachen der Intuition')),
                  DropdownMenuItem(value: '852', child: Text('852 Hz - Rückkehr zur Ordnung')),
                  DropdownMenuItem(value: '963', child: Text('963 Hz - Verbindung zum Göttlichen')),
                ],
                onChanged: (value) => setState(() => _frequency = value!),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notizen (optional)'),
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
        title: Text('🎵 HEILFREQUENZ-PLAYER'),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.music_note, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Noch keine Sessions gespeichert',
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
                          leading: const Icon(Icons.music_note, color: Colors.green),
                          title: Text(
                            '${item['frequency']} Hz',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: item['notes'] != null && item['notes'].toString().isNotEmpty
                              ? Text(item['notes'], style: TextStyle(color: Colors.grey[400]))
                              : null,
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
