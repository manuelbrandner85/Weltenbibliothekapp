import 'package:flutter/material.dart';
import '../../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PatentArchivTool extends StatefulWidget {
  const PatentArchivTool({super.key});
  @override
  State<PatentArchivTool> createState() => _PatentArchivToolState();
}

class _PatentArchivToolState extends State<PatentArchivTool> {
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _inventorController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<Map<String, dynamic>> _patents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatents();
  }

  Future<void> _loadPatents() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance(); final data = prefs.getString('patent_archiv');
    if (data != null) {
      setState(() {
        _patents = List<Map<String, dynamic>>.from(json.decode(data));
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePatents() async {
    final prefs = await SharedPreferences.getInstance(); await prefs.setString('patent_archiv', json.encode(_patents));
  }

  void _addPatent() {
    if (_titleController.text.isEmpty) return;
    setState(() {
      _patents.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': _titleController.text,
        'inventor': _inventorController.text,
        'description': _descriptionController.text,
        'date': DateTime.now().toIso8601String(),
      });
    });
    _savePatents();
    _titleController.clear();
    _inventorController.clear();
    _descriptionController.clear();
    Navigator.pop(context);
  }

  void _deletePatent(int index) {
    setState(() => _patents.removeAt(index));
    _savePatents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('💡 Patent-Archiv'), backgroundColor: Colors.blue),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _patents.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.lightbulb, size: 64, color: Colors.grey[400]), const SizedBox(height: 16), Text('Noch keine Patente', style: TextStyle(fontSize: 18, color: Colors.grey[600]))]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _patents.length,
                  itemBuilder: (context, index) {
                    final item = _patents[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.science, color: Colors.white)),
                        title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (item['inventor'].isNotEmpty) Text('👤 ${item['inventor']}'),
                          if (item['description'].isNotEmpty) Text(item['description'], maxLines: 2, overflow: TextOverflow.ellipsis),
                        ]),
                        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deletePatent(index)),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showAddDialog(), icon: const Icon(Icons.add), label: const Text('Patent'), backgroundColor: Colors.blue),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('💡 Neues Patent'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Titel *', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _inventorController, decoration: const InputDecoration(labelText: 'Erfinder', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Beschreibung', border: OutlineInputBorder()), maxLines: 3),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          ElevatedButton(onPressed: _addPatent, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue), child: const Text('Hinzufügen')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _inventorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
