// ═══════════════════════════════════════════════════════════
// ANLEITUNG: Chat-Tools mit Cloudflare Backend verbinden
// ═══════════════════════════════════════════════════════════
//
// Jedes Tool muss folgendes implementieren:
//
// 1) ChatToolsService importieren:
//    import '../../services/chat_tools_service.dart';
//
// 2) ChatToolsService instanziieren:
//    final ChatToolsService _toolsService = ChatToolsService();
//
// 3) username und roomId als Parameter übergeben:
//    const SessionTool({
//      Key? key,
//      required this.roomId,
//      required this.username,  // ← NEU!
//    }) : super(key: key);
//
// 4) Tool-Ergebnis speichern nach Aktion:
//    await _toolsService.saveToolResult(
//      roomId: widget.roomId,
//      toolType: 'session',  // oder 'traumanalyse', 'heilung', etc.
//      username: widget.username,
//      data: {
//        'name': _nameController.text,
//        'duration': _selectedDuration,
//        'technik': _selectedTechnik,
//        'created_at': DateTime.now().toIso8601String(),
//      },
//    );
//
// 5) Tool-Ergebnisse laden (initState):
//    final results = await _toolsService.getToolResults(
//      roomId: widget.roomId,
//      toolType: 'session',
//    );
//
// 6) UI anzeigen: Liste aller Tool-Ergebnisse anzeigen
//    - Eigene Ergebnisse hervorheben (username == widget.username)
//    - Andere Nutzer-Ergebnisse grau/transparent
//    - Löschen-Button nur bei eigenen Ergebnissen
//
// ═══════════════════════════════════════════════════════════
// BEISPIEL: SessionTool mit Backend-Integration
// ═══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/chat_tools_service.dart';

class SessionTool extends StatefulWidget {
  final String roomId;
  final String username;

  const SessionTool({
    super.key,
    required this.roomId,
    required this.username,
  });

  @override
  State<SessionTool> createState() => _SessionToolState();
}

class _SessionToolState extends State<SessionTool> {
  final ChatToolsService _toolsService = ChatToolsService();
  
  List<Map<String, dynamic>> _savedSessions = [];
  bool _isLoading = false;
  
  final TextEditingController _nameController = TextEditingController();
  final int _selectedDuration = 10;
  
  @override
  void initState() {
    super.initState();
    _loadSessions();
  }
  
  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await _toolsService.getToolResults(
        roomId: widget.roomId,
        toolType: 'session',
      );
      
      setState(() {
        _savedSessions = results;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Fehler beim Laden: $e');
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _createSession() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Namen eingeben')),
      );
      return;
    }
    
    try {
      await _toolsService.saveToolResult(
        roomId: widget.roomId,
        toolType: 'session',
        username: widget.username,
        data: {
          'name': _nameController.text,
          'duration': _selectedDuration,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      
      _nameController.clear();
      await _loadSessions(); // Reload
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Session gespeichert!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fehler: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // CREATE FORM
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Session-Name'),
        ),
        const SizedBox(height: 16),
        
        ElevatedButton(
          onPressed: _createSession,
          child: const Text('Session erstellen'),
        ),
        
        const Divider(),
        
        // SAVED SESSIONS LIST
        _isLoading
            ? const CircularProgressIndicator()
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _savedSessions.length,
                itemBuilder: (context, index) {
                  final session = _savedSessions[index];
                  final data = session['data'] as Map<String, dynamic>;
                  final isOwnSession = session['username'] == widget.username;
                  
                  return Card(
                    color: isOwnSession ? Colors.blue.shade50 : Colors.grey.shade100,
                    child: ListTile(
                      title: Text(data['name'] ?? 'Unbenannt'),
                      subtitle: Text('${data['duration']} Min - ${session['username']}'),
                      trailing: isOwnSession
                          ? IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                await _toolsService.deleteToolResult(
                                  resultId: session['id'],
                                  username: widget.username,
                                );
                                await _loadSessions();
                              },
                            )
                          : null,
                    ),
                  );
                },
              ),
      ],
    );
  }
}
