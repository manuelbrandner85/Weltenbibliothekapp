import 'package:flutter/material.dart';
import '../../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TraumTagebuchTool extends StatefulWidget {
  const TraumTagebuchTool({super.key});
  @override
  State<TraumTagebuchTool> createState() => _TraumTagebuchToolState();
}

class _TraumTagebuchToolState extends State<TraumTagebuchTool> {
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<Map<String, dynamic>> _dreams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDreams();
  }

  Future<void> _loadDreams() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance(); final data = prefs.getString('traum_tagebuch');
    if (data != null) {
      setState(() {
        _dreams = List<Map<String, dynamic>>.from(json.decode(data));
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDreams() async {
    final prefs = await SharedPreferences.getInstance(); await prefs.setString('traum_tagebuch', json.encode(_dreams));
  }

  void _addDream() {
    if (_titleController.text.isEmpty) return;
    setState(() {
      _dreams.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': _titleController.text,
        'description': _descriptionController.text,
        'date': DateTime.now().toIso8601String(),
      });
    });
    _saveDreams();
    _titleController.clear();
    _descriptionController.clear();
    Navigator.pop(context);
  }

  void _deleteDream(int index) {
    setState(() => _dreams.removeAt(index));
    _saveDreams();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📔 Traum-Tagebuch'), backgroundColor: Colors.indigo),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dreams.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.nights_stay, size: 64, color: Colors.grey[400]), const SizedBox(height: 16), Text('Noch keine Träume', style: TextStyle(fontSize: 18, color: Colors.grey[600]))]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _dreams.length,
                  itemBuilder: (context, index) {
                    final item = _dreams[index];
                    final date = DateTime.parse(item['date']);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.bedtime, color: Colors.white)),
                        title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('🌙 ${date.day}.${date.month}.${date.year}'),
                          if (item['description'].isNotEmpty) Text(item['description'], maxLines: 2, overflow: TextOverflow.ellipsis),
                        ]),
                        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteDream(index)),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showAddDialog(), icon: const Icon(Icons.add), label: const Text('Traum'), backgroundColor: Colors.indigo),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📔 Neuer Traum'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Titel *', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Beschreibung', border: OutlineInputBorder()), maxLines: 4),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          ElevatedButton(onPressed: _addDream, style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo), child: const Text('Speichern')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
