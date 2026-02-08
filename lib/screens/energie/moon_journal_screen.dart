/// Moon Journal Screen - Mondtagebuch
/// Weltenbibliothek v61
library;

import 'package:flutter/material.dart';

class MoonJournalScreen extends StatefulWidget {
  const MoonJournalScreen({super.key});

  @override
  State<MoonJournalScreen> createState() => _MoonJournalScreenState();
}

class _MoonJournalScreenState extends State<MoonJournalScreen> {
  // UNUSED FIELD: final _storageService = StorageService();
  final _noteController = TextEditingController();
  
  final List<MoonJournalEntry> _entries = [];
  
  @override
  void initState() {
    super.initState();
    _loadEntries();
  }
  
  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
  
  Future<void> _loadEntries() async {
    // Für v61: Einfache lokale Liste (später mit Hive Storage)
    setState(() {
      // Placeholder - später mit echtem Storage
    });
  }
  
  void _addEntry() {
    if (_noteController.text.trim().isEmpty) return;
    
    final entry = MoonJournalEntry(
      date: DateTime.now(),
      note: _noteController.text.trim(),
      moonPhase: _getCurrentMoonPhase(),
    );
    
    setState(() {
      _entries.insert(0, entry);
      _noteController.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mondtagebuch-Eintrag gespeichert! 🌙'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  String _getCurrentMoonPhase() {
    // Vereinfachte Mondphasen-Berechnung
    final now = DateTime.now();
    final dayOfMonth = now.day;
    
    if (dayOfMonth <= 7) return 'Neumond 🌑';
    if (dayOfMonth <= 14) return 'Zunehmend 🌓';
    if (dayOfMonth <= 21) return 'Vollmond 🌕';
    if (dayOfMonth <= 28) return 'Abnehmend 🌗';
    return 'Neumond 🌑';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text('🌙 Mondtagebuch'),
        backgroundColor: Color(0xFF1A237E),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A237E), Color(0xFF000000)],
          ),
        ),
        child: Column(
          children: [
            // Input Section
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Neuer Eintrag',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Current Moon Phase
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Aktuelle Phase:',
                          style: TextStyle(color: Colors.white70),
                        ),
                        SizedBox(width: 8),
                        Text(
                          _getCurrentMoonPhase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Note Input
                  TextField(
                    controller: _noteController,
                    maxLines: 4,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Deine Gedanken, Träume, Erkenntnisse...',
                      hintStyle: TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Add Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addEntry,
                      icon: Icon(Icons.add),
                      label: Text('Eintrag hinzufügen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF5E35B1),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Entries List
            Expanded(
              child: _entries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.book, size: 64, color: Colors.white24),
                          SizedBox(height: 16),
                          Text(
                            'Noch keine Einträge',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(20),
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        return _buildEntryCard(entry, index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEntryCard(MoonJournalEntry entry, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF5E35B1).withValues(alpha: 0.3),
            Color(0xFF1A237E).withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${entry.date.day}.${entry.date.month}.${entry.date.year}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  Text(
                    entry.moonPhase,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _entries.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            entry.note,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class MoonJournalEntry {
  final DateTime date;
  final String note;
  final String moonPhase;
  
  MoonJournalEntry({
    required this.date,
    required this.note,
    required this.moonPhase,
  });
}
