import 'package:flutter/material.dart';
import 'dart:async';
import 'package:weltenbibliothek/services/tool_api_service.dart';

/// CONNECTIONS-BOARD - Kollaboratives Tool für Verschwörungs-Chat
class ConnectionsBoardWidget extends StatefulWidget {
  final String roomId;
  
  const ConnectionsBoardWidget({
    super.key,
    required this.roomId,
  });

  @override
  State<ConnectionsBoardWidget> createState() => _ConnectionsBoardWidgetState();
}

class _ConnectionsBoardWidgetState extends State<ConnectionsBoardWidget> {
  final _apiService = ToolApiService();
  List<Map<String, dynamic>> _connections = [];
  bool _isLoading = false;
  Timer? _pollTimer;
  
  final _entity1Controller = TextEditingController();
  final _entity2Controller = TextEditingController();
  final _connectionController = TextEditingController();
  final _evidenceController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadConnections();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadConnections();
    });
  }
  
  @override
  void dispose() {
    _pollTimer?.cancel();
    _entity1Controller.dispose();
    _entity2Controller.dispose();
    _connectionController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }
  
  Future<void> _loadConnections() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final data = await _apiService.getToolData(
        endpoint: '/api/tools/connections',
        roomId: widget.roomId,
      );
      
      setState(() {
        _connections = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _addConnection() async {
    if (_entity1Controller.text.isEmpty || _entity2Controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte beide Entitäten eingeben')),
      );
      return;
    }
    
    try {
      await _apiService.postToolData(
        endpoint: '/api/tools/connections',
        data: {
          'room_id': widget.roomId,
          'entity1': _entity1Controller.text,
          'entity2': _entity2Controller.text,
          'connection': _connectionController.text,
          'evidence': _evidenceController.text,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      _entity1Controller.clear();
      _entity2Controller.clear();
      _connectionController.clear();
      _evidenceController.clear();
      
      await _loadConnections();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verbindung hinzugefügt!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          bottom: BorderSide(color: Colors.deepPurple.withValues(alpha: 0.3), width: 2),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple[800]!, Colors.deepPurple[900]!],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_tree, color: Colors.purpleAccent, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '🕸️ CONNECTIONS-BOARD',
                  style: TextStyle(
                    color: Colors.purpleAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_connections.length} Verbindungen',
                    style: const TextStyle(color: Colors.purpleAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
          // Quick Add Form
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _entity1Controller,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Entität 1 (Person/Org)',
                          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward, color: Colors.grey[600], size: 16),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _entity2Controller,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Entität 2 (Person/Org)',
                          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _connectionController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Art der Verbindung (Optional)',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _evidenceController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Beweise/Quellen (Optional)',
                          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addConnection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.add, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Connections Liste
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: _isLoading && _connections.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
                : _connections.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Noch keine Verbindungen dokumentiert.\nStarte deine Recherche!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _connections.length,
                        itemBuilder: (context, index) {
                          final conn = _connections[index];
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[850],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.purpleAccent.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${conn['entity1']} ↔️ ${conn['entity2']}',
                                        style: const TextStyle(
                                          color: Colors.purpleAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatTime(conn['created_at']),
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                if (conn['connection'] != null && (conn['connection'] as String).isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    '🔗 ${conn['connection']}',
                                    style: TextStyle(color: Colors.grey[300], fontSize: 12),
                                  ),
                                ],
                                if (conn['evidence'] != null && (conn['evidence'] as String).isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '📎 ${conn['evidence']}',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
    final now = DateTime.now();
    final diff = now.difference(dt);
    
    if (diff.inMinutes < 1) return 'Jetzt';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'vor ${diff.inHours}h';
    return 'vor ${diff.inDays}d';
  }
}
