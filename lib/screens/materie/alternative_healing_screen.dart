import 'package:flutter/material.dart';
import '../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../../services/group_tools_service.dart';
import '../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0

class AlternativeHealingScreen extends StatefulWidget {
  final String roomId;
  const AlternativeHealingScreen({super.key, required this.roomId});
  @override
  State<AlternativeHealingScreen> createState() => _AlternativeHealingScreenState();
}

class _AlternativeHealingScreenState extends State<AlternativeHealingScreen> {
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
      final items = await _svc.getHealingMethods(roomId: widget.roomId);
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
        title: const Text('💚 Heilmethode hinzufügen', style: TextStyle(color: Colors.green)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: title, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.white70))),
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
              await _svc.createHealingMethod(roomId: widget.roomId, userId: 'user_manuel', username: 'Manuel', methodName: title.text.trim(), methodDescription: desc.text.trim(), category: 'alternative');
              await _load();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
      appBar: AppBar(title: const Text('💚 Alternative Gesundheit'), backgroundColor: const Color(0xFF1B263B), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)]),
      body: _loading ? const Center(child: CircularProgressIndicator(color: Colors.green)) : _items.isEmpty ? Center(child: ElevatedButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Erste Methode'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green))) : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _items.length, itemBuilder: (ctx, i) {
        final item = _items[i];
        return Card(color: const Color(0xFF1A1A2E), margin: const EdgeInsets.only(bottom: 12), child: ListTile(leading: const Icon(Icons.healing, color: Colors.green, size: 32), title: Text(item['method_name'] ?? 'Methode', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)), subtitle: Text(item['method_description'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 2)));
      }),
      floatingActionButton: FloatingActionButton(onPressed: _add, backgroundColor: Colors.green, child: const Icon(Icons.add)),
    );
  }

  @override
  void dispose() {
    // 🧹 PHASE B: Proper resource disposal
    super.dispose();
  }
}
