import 'package:flutter/material.dart';
import '../../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BewusstseinsJournalTool extends StatefulWidget {
  const BewusstseinsJournalTool({super.key});
  @override
  State<BewusstseinsJournalTool> createState() => _BewusstseinsJournalToolState();
}

class _BewusstseinsJournalToolState extends State<BewusstseinsJournalTool> {
  
  final TextEditingController _entryController = TextEditingController();
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance(); final data = prefs.getString('bewusstseins_journal');
    if (data != null) {
      setState(() {
        _entries = List<Map<String, dynamic>>.from(json.decode(data));
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance(); await prefs.setString('bewusstseins_journal', json.encode(_entries));
  }

  void _addEntry() {
    if (_entryController.text.isEmpty) return;
    setState(() {
      _entries.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'entry': _entryController.text,
        'date': DateTime.now().toIso8601String(),
      });
    });
    _saveEntries();
    _entryController.clear();
    Navigator.pop(context);
  }

  void _deleteEntry(int index) {
    setState(() => _entries.removeAt(index));
    _saveEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔮 Bewusstseins-Journal'), backgroundColor: Colors.amber),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.auto_stories, size: 64, color: Colors.grey[400]), const SizedBox(height: 16), Text('Noch keine Einträge', style: TextStyle(fontSize: 18, color: Colors.grey[600]))]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final item = _entries[index];
                    final date = DateTime.parse(item['date']);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.wb_sunny, color: Colors.white)),
                        title: Text(item['entry'], maxLines: 3, overflow: TextOverflow.ellipsis),
                        subtitle: Text('✨ ${date.day}.${date.month}.${date.year}'),
                        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteEntry(index)),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showAddDialog(), icon: const Icon(Icons.add), label: const Text('Eintrag'), backgroundColor: Colors.amber),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔮 Neuer Eintrag'),
        content: TextField(controller: _entryController, decoration: const InputDecoration(labelText: 'Erkenntnisse *', border: OutlineInputBorder(), hintText: 'Was hast du erkannt?'), maxLines: 5),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          ElevatedButton(onPressed: _addEntry, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber), child: const Text('Speichern')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }
}
