import 'package:flutter/material.dart';
import '../../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 📰 NEWS-TRACKER - Politik & Weltgeschehen
/// Verfolge alternative Nachrichtenquellen und wichtige Ereignisse
class NewsTrackerTool extends StatefulWidget {
  const NewsTrackerTool({super.key});

  @override
  State<NewsTrackerTool> createState() => _NewsTrackerToolState();
}

class _NewsTrackerToolState extends State<NewsTrackerTool> {
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  List<Map<String, dynamic>> _newsItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNewsItems();
  }

  Future<void> _loadNewsItems() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance(); final data = prefs.getString('news_tracker_items');
    if (data != null) {
      setState(() {
        _newsItems = List<Map<String, dynamic>>.from(json.decode(data));
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNewsItems() async {
    final prefs = await SharedPreferences.getInstance(); await prefs.setString('news_tracker_items', json.encode(_newsItems));
  }

  void _addNewsItem() {
    if (_titleController.text.isEmpty) return;
    
    setState(() {
      _newsItems.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': _titleController.text,
        'source': _sourceController.text,
        'link': _linkController.text,
        'notes': _notesController.text,
        'date': DateTime.now().toIso8601String(),
        'important': false,
      });
    });
    
    _saveNewsItems();
    _titleController.clear();
    _sourceController.clear();
    _linkController.clear();
    _notesController.clear();
    Navigator.pop(context);
  }

  void _toggleImportant(int index) {
    setState(() {
      _newsItems[index]['important'] = !(_newsItems[index]['important'] ?? false);
    });
    _saveNewsItems();
  }

  void _deleteNewsItem(int index) {
    setState(() => _newsItems.removeAt(index));
    _saveNewsItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📰 News-Tracker'),
        backgroundColor: Colors.red,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _newsItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.newspaper, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Noch keine News getrackt',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Füge wichtige Nachrichten hinzu!',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _newsItems.length,
                  itemBuilder: (context, index) {
                    final item = _newsItems[index];
                    final date = DateTime.parse(item['date']);
                    final isImportant = item['important'] ?? false;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isImportant ? Colors.red[50] : null,
                      child: ListTile(
                        leading: IconButton(
                          icon: Icon(
                            isImportant ? Icons.star : Icons.star_border,
                            color: isImportant ? Colors.red : Colors.grey,
                          ),
                          onPressed: () => _toggleImportant(index),
                        ),
                        title: Text(
                          item['title'],
                          style: TextStyle(
                            fontWeight: isImportant ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item['source'].isNotEmpty)
                              Text('📍 ${item['source']}'),
                            Text(
                              '🕐 ${date.day}.${date.month}.${date.year}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            if (item['notes'].isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(item['notes'], style: const TextStyle(fontSize: 12)),
                            ],
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteNewsItem(index),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        icon: const Icon(Icons.add),
        label: const Text('News hinzufügen'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📰 Neue Nachricht'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titel *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _sourceController,
                decoration: const InputDecoration(
                  labelText: 'Quelle (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'z.B. Alternative News XYZ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Link (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'https://...',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notizen (optional)',
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
            onPressed: _addNewsItem,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _sourceController.dispose();
    _linkController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
