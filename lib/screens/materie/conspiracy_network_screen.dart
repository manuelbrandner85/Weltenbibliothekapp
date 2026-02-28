import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../../services/group_tools_service.dart';

class ConspiracyNetworkScreen extends StatefulWidget {
  final String roomId;
  const ConspiracyNetworkScreen({super.key, required this.roomId});
  @override
  State<ConspiracyNetworkScreen> createState() => _ConspiracyNetworkScreenState();
}

class _ConspiracyNetworkScreenState extends State<ConspiracyNetworkScreen> {
  final _svc = GroupToolsService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = false;
  
  @override
  void initState() {
    super.initState();
    _load();
  }
  
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _svc.getConspiracyNetwork(roomId: widget.roomId);
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }
  
  void _add() {
    final title = TextEditingController();
    final desc = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('👁️ Verbindung hinzufügen', style: TextStyle(color: Colors.purple)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: title, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Titel', labelStyle: TextStyle(color: Colors.white70))),
            const SizedBox(height: 16),
            TextField(controller: desc, style: const TextStyle(color: Colors.white), maxLines: 3, decoration: const InputDecoration(labelText: 'Beschreibung', labelStyle: TextStyle(color: Colors.white70))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (title.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await _svc.createConspiracyConnection(roomId: widget.roomId, userId: 'user_manuel', username: 'Manuel', connectionTitle: title.text.trim(), connectionDescription: desc.text.trim());
              await _load();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(title: const Text('👁️ Verbindungsnetz'), backgroundColor: const Color(0xFF1B263B), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)]),
      body: _loading ? const Center(child: CircularProgressIndicator(color: Colors.purple)) : _items.isEmpty ? Center(child: ElevatedButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Erste Verbindung'), style: ElevatedButton.styleFrom(backgroundColor: Colors.purple))) : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _items.length, itemBuilder: (ctx, i) {
        final item = _items[i];
        return Card(color: const Color(0xFF1A1A2E), margin: const EdgeInsets.only(bottom: 12), child: ListTile(leading: const Icon(Icons.account_tree, color: Colors.purple, size: 32), title: Text(item['connection_title'] ?? 'Verbindung', style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)), subtitle: Text(item['connection_description'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 2)));
      }),
      floatingActionButton: FloatingActionButton(onPressed: _add, backgroundColor: Colors.purple, child: const Icon(Icons.add)),
    );
  }

  @override
  void dispose() {
    // 🧹 PHASE B: Proper resource disposal
    super.dispose();
  }
}
