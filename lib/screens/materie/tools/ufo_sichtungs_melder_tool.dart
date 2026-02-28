import 'package:flutter/material.dart';
import '../../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 📍 UFO-SICHTUNGS-MELDER
class UfoSichtungsMelderTool extends StatefulWidget {
  const UfoSichtungsMelderTool({super.key});
  @override
  State<UfoSichtungsMelderTool> createState() => _UfoSichtungsMelderToolState();
}

class _UfoSichtungsMelderToolState extends State<UfoSichtungsMelderTool> {
  
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  List<Map<String, dynamic>> _sichtungen = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSichtungen();
  }

  Future<void> _loadSichtungen() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance(); final data = prefs.getString('ufo_sichtungen');
    if (data != null) {
      setState(() {
        _sichtungen = List<Map<String, dynamic>>.from(json.decode(data));
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSichtungen() async {
    final prefs = await SharedPreferences.getInstance(); await prefs.setString('ufo_sichtungen', json.encode(_sichtungen));
  }

  void _addSichtung() {
    if (_locationController.text.isEmpty) return;
    setState(() {
      _sichtungen.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'location': _locationController.text,
        'description': _descriptionController.text,
        'date': DateTime.now().toIso8601String(),
        'verified': false,
      });
    });
    _saveSichtungen();
    _locationController.clear();
    _descriptionController.clear();
    Navigator.pop(context);
  }

  void _toggleVerified(int index) {
    setState(() {
      _sichtungen[index]['verified'] = !(_sichtungen[index]['verified'] ?? false);
    });
    _saveSichtungen();
  }

  void _deleteSichtung(int index) {
    setState(() => _sichtungen.removeAt(index));
    _saveSichtungen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📍 UFO-Sichtungs-Melder'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sichtungen.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.explore, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Noch keine Sichtungen', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text('Melde UFO-Sichtungen!', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sichtungen.length,
                  itemBuilder: (context, index) {
                    final item = _sichtungen[index];
                    final date = DateTime.parse(item['date']);
                    final verified = item['verified'] ?? false;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: verified ? Colors.green[50] : null,
                      child: ListTile(
                        leading: IconButton(
                          icon: Icon(verified ? Icons.check_circle : Icons.help_outline, color: verified ? Colors.green : Colors.grey),
                          onPressed: () => _toggleVerified(index),
                        ),
                        title: Text('📍 ${item['location']}', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🕐 ${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}'),
                            if (item['description'].isNotEmpty) Text(item['description'], style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteSichtung(index)),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Sichtung melden'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📍 UFO-Sichtung'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'Ort *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Beschreibung', border: OutlineInputBorder()), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          ElevatedButton(onPressed: _addSichtung, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('Melden')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
