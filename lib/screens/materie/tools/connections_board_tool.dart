import 'package:flutter/material.dart';
import '../../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ConnectionsBoardTool extends StatefulWidget {
  const ConnectionsBoardTool({super.key});
  @override
  State<ConnectionsBoardTool> createState() => _ConnectionsBoardToolState();
}

class _ConnectionsBoardToolState extends State<ConnectionsBoardTool> {
  
  final TextEditingController _entityController = TextEditingController();
  final TextEditingController _connectionController = TextEditingController();
  List<Map<String, dynamic>> _connections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance(); final data = prefs.getString('connections_board');
    if (data != null) {
      setState(() {
        _connections = List<Map<String, dynamic>>.from(json.decode(data));
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConnections() async {
    final prefs = await SharedPreferences.getInstance(); await prefs.setString('connections_board', json.encode(_connections));
  }

  void _addConnection() {
    if (_entityController.text.isEmpty) return;
    setState(() {
      _connections.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'entity': _entityController.text,
        'connection': _connectionController.text,
        'date': DateTime.now().toIso8601String(),
      });
    });
    _saveConnections();
    _entityController.clear();
    _connectionController.clear();
    Navigator.pop(context);
  }

  void _deleteConnection(int index) {
    setState(() => _connections.removeAt(index));
    _saveConnections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🕸️ Connections-Board'), backgroundColor: Colors.purple),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _connections.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.hub, size: 64, color: Colors.grey[400]), const SizedBox(height: 16), Text('Noch keine Verbindungen', style: TextStyle(fontSize: 18, color: Colors.grey[600]))]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _connections.length,
                  itemBuilder: (context, index) {
                    final item = _connections[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.account_tree, color: Colors.white)),
                        title: Text(item['entity'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: item['connection'].isNotEmpty ? Text(item['connection']) : null,
                        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteConnection(index)),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showAddDialog(), icon: const Icon(Icons.add), label: const Text('Verbindung'), backgroundColor: Colors.purple),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🕸️ Neue Verbindung'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _entityController, decoration: const InputDecoration(labelText: 'Person/Organisation *', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _connectionController, decoration: const InputDecoration(labelText: 'Verbindung', border: OutlineInputBorder()), maxLines: 2),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          ElevatedButton(onPressed: _addConnection, style: ElevatedButton.styleFrom(backgroundColor: Colors.purple), child: const Text('Hinzufügen')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _entityController.dispose();
    _connectionController.dispose();
    super.dispose();
  }
}
