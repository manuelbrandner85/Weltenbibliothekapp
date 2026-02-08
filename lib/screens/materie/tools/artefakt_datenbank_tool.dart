import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 🗺️ ARTEFAKT-DATENBANK - Geschichte & Archäologie
/// Sammle antike Fundorte und mysteriöse Artefakte
class ArtefaktDatenbankTool extends StatefulWidget {
  const ArtefaktDatenbankTool({super.key});

  @override
  State<ArtefaktDatenbankTool> createState() => _ArtefaktDatenbankToolState();
}

class _ArtefaktDatenbankToolState extends State<ArtefaktDatenbankTool> {
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _periodController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  List<Map<String, dynamic>> _artefakte = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtefakte();
  }

  Future<void> _loadArtefakte() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance(); final data = prefs.getString('artefakt_datenbank');
    if (data != null) {
      setState(() {
        _artefakte = List<Map<String, dynamic>>.from(json.decode(data));
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveArtefakte() async {
    final prefs = await SharedPreferences.getInstance(); await prefs.setString('artefakt_datenbank', json.encode(_artefakte));
  }

  void _addArtefakt() {
    if (_nameController.text.isEmpty) return;
    
    setState(() {
      _artefakte.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': _nameController.text,
        'location': _locationController.text,
        'period': _periodController.text,
        'description': _descriptionController.text,
        'date': DateTime.now().toIso8601String(),
      });
    });
    
    _saveArtefakte();
    _nameController.clear();
    _locationController.clear();
    _periodController.clear();
    _descriptionController.clear();
    Navigator.pop(context);
  }

  void _deleteArtefakt(int index) {
    setState(() => _artefakte.removeAt(index));
    _saveArtefakte();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🗺️ Artefakt-Datenbank'),
        backgroundColor: Colors.amber,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _artefakte.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.temple_hindu, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Noch keine Artefakte',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Dokumentiere mysteriöse Fundstücke!',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _artefakte.length,
                  itemBuilder: (context, index) {
                    final item = _artefakte[index];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.amber,
                          child: Icon(Icons.account_balance, color: Colors.white),
                        ),
                        title: Text(
                          item['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item['location'].isNotEmpty)
                              Text('📍 ${item['location']}'),
                            if (item['period'].isNotEmpty)
                              Text('📅 ${item['period']}'),
                            if (item['description'].isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item['description'],
                                style: const TextStyle(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteArtefakt(index),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Artefakt hinzufügen'),
        backgroundColor: Colors.amber,
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗺️ Neues Artefakt'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                  hintText: 'z.B. Pyramide von Gizeh',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Fundort',
                  border: OutlineInputBorder(),
                  hintText: 'z.B. Ägypten, Gizeh',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _periodController,
                decoration: const InputDecoration(
                  labelText: 'Zeitperiode',
                  border: OutlineInputBorder(),
                  hintText: 'z.B. 2500 v. Chr.',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung',
                  border: OutlineInputBorder(),
                ),
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
            onPressed: _addArtefakt,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _periodController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
