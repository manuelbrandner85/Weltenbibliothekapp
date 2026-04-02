import 'package:flutter/material.dart';
import '../../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:weltenbibliothek/services/tool_api_service.dart';

class ChakraScannerTool extends StatefulWidget {
  final String realm;
  final String roomId;
  
  const ChakraScannerTool({
    super.key,
    required this.realm,
    this.roomId = 'chakren',
  });

  @override
  State<ChakraScannerTool> createState() => _ChakraScannerToolState();
}

class _ChakraScannerToolState extends State<ChakraScannerTool> {
  final ToolApiService _api = ToolApiService();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  final TextEditingController _notesController = TextEditingController();
  String _chakra = 'wurzel';

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
        endpoint: '/api/tools/chakra-readings',
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
      'chakra': _chakra,
      'notes': _notesController.text.trim(),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      await _api.postToolData(
        endpoint: '/api/tools/chakra-readings',
        data: newItem,
      );
      
      _notesController.clear();
      setState(() => _chakra = 'wurzel');
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
        endpoint: '/api/tools/chakra-readings',
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
        title: const Text('Chakra-Messung speichern'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _chakra,
                decoration: const InputDecoration(labelText: 'Chakra'),
                items: const [
                  DropdownMenuItem(value: 'wurzel', child: Text('🔴 Wurzel (396 Hz)')),
                  DropdownMenuItem(value: 'sakral', child: Text('🟠 Sakral (417 Hz)')),
                  DropdownMenuItem(value: 'solar', child: Text('🟡 Solar (528 Hz)')),
                  DropdownMenuItem(value: 'herz', child: Text('🟢 Herz (639 Hz)')),
                  DropdownMenuItem(value: 'kehl', child: Text('🔵 Kehl (741 Hz)')),
                  DropdownMenuItem(value: 'stirn', child: Text('🟣 Stirn (852 Hz)')),
                  DropdownMenuItem(value: 'krone', child: Text('⚪ Krone (963 Hz)')),
                ],
                onChanged: (value) => setState(() => _chakra = value!),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notizen'),
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


  Color _getChakraColor(String chakra) {
    switch (chakra) {
      case 'wurzel': return Colors.red;
      case 'sakral': return Colors.orange;
      case 'solar': return Colors.yellow;
      case 'herz': return Colors.green;
      case 'kehl': return Colors.blue;
      case 'stirn': return Colors.purple;
      case 'krone': return Colors.white;
      default: return Colors.grey;
    }
  }

  String _getChakraName(String chakra) {
    switch (chakra) {
      case 'wurzel': return '🔴 Wurzel-Chakra';
      case 'sakral': return '🟠 Sakral-Chakra';
      case 'solar': return '🟡 Solar-Chakra';
      case 'herz': return '🟢 Herz-Chakra';
      case 'kehl': return '🔵 Kehl-Chakra';
      case 'stirn': return '🟣 Stirn-Chakra';
      case 'krone': return '⚪ Krone-Chakra';
      default: return chakra;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text('🌈 CHAKRA-SCANNER'),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.spa, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Noch keine Messungen gespeichert',
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
                          leading: Icon(Icons.spa, color: _getChakraColor(item['chakra'])),
                          title: Text(
                            _getChakraName(item['chakra']),
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
