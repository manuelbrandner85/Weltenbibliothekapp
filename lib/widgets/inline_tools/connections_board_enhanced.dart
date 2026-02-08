import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/user_auth_service.dart'; // ✅ Real Auth

class ConnectionsBoardEnhanced extends StatefulWidget {
  final String roomId;
  const ConnectionsBoardEnhanced({super.key, required this.roomId});
  @override
  State<ConnectionsBoardEnhanced> createState() => _ConnectionsBoardEnhancedState();
}

class _ConnectionsBoardEnhancedState extends State<ConnectionsBoardEnhanced> {
  final _entity1Controller = TextEditingController();
  final _entity2Controller = TextEditingController();
  final _connectionController = TextEditingController();
  List<Map<String, dynamic>> _connections = [];
  Timer? _refreshTimer;
  bool _isLoading = false;
  
  // ✅ Real User Auth
  String? _currentUsername;
  String? _currentUserId;
  bool _isAuthenticated = false;
  int _activeResearchers = 0;

  @override
  void initState() {
    super.initState();
    _loadUserAuth();
    _loadConnections();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadConnections());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _entity1Controller.dispose();
    _entity2Controller.dispose();
    _connectionController.dispose();
    super.dispose();
  }

  // ✅ Load real user auth
  Future<void> _loadUserAuth() async {
    _currentUsername = await UserAuthService.getUsername();
    _currentUserId = await UserAuthService.getUserId();
    setState(() {
      _isAuthenticated = _currentUsername != null;
    });
  }

  Future<void> _loadConnections() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.connectionsUrl + '?room_id=${widget.roomId}'),
        headers: {'Authorization': 'Bearer _C578hgIAimVPG0WjfeAjk23RxQMQ9gox0W7ebLv'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _connections = data.cast<Map<String, dynamic>>();
          _activeResearchers = _connections.map((e) => e['username'] as String?).toSet().length;
        });
      }
    } catch (e) {
   if (kDebugMode) {
     debugPrint('⚠️ ConnectionsBoardEnhanced: Error - $e');
   }
   // Silently fail - widget remains functional
 }
  }

  Future<void> _addConnection() async {
    // ✅ Check authentication
    if (!_isAuthenticated || _currentUsername == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Bitte erstelle zuerst ein Profil'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    

    if (_entity1Controller.text.isEmpty || _entity2Controller.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.connectionsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer _C578hgIAimVPG0WjfeAjk23RxQMQ9gox0W7ebLv',
        },
        body: jsonEncode({
          'room_id': widget.roomId,
          'entity1': _entity1Controller.text.trim(),
          'entity2': _entity2Controller.text.trim(),
          'connection_type': _connectionController.text.trim(),
          'username': _currentUsername, // ✅ Real username
          'user_id': _currentUserId,    // ✅ Real user ID,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        _entity1Controller.clear();
        _entity2Controller.clear();
        _connectionController.clear();
        await _loadConnections();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🔗 Verbindung hinzugefügt!'), backgroundColor: Colors.purple),
          );
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.account_tree, color: Colors.white, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CONNECTIONS-NETZWERK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('${_connections.length} Verbindungen • $_activeResearchers Forscher', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  TextField(
                    controller: _entity1Controller,
                    decoration: const InputDecoration(labelText: 'Entität 1', hintText: 'z.B. Organisation X', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _entity2Controller,
                    decoration: const InputDecoration(labelText: 'Entität 2', hintText: 'z.B. Person Y', border: OutlineInputBorder(), prefixIcon: Icon(Icons.business)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _connectionController,
                    decoration: const InputDecoration(labelText: 'Verbindungstyp (optional)', hintText: 'z.B. Finanzierung, Mitgliedschaft', border: OutlineInputBorder(), prefixIcon: Icon(Icons.link)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _addConnection,
                      icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.add),
                      label: Text(_isLoading ? 'Wird hinzugefügt...' : 'Verbindung hinzufügen'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C27B0), padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: _connections.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_tree, size: 48, color: Colors.white54),
                            SizedBox(height: 8),
                            Text('Noch keine Verbindungen', style: TextStyle(color: Colors.white70)),
                            Text('Erstelle das erste Verbindungsnetz!', style: TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _connections.length,
                      itemBuilder: (context, index) {
                        final connection = _connections[index];
                        final entity1 = connection['entity1'] as String? ?? '';
                        final entity2 = connection['entity2'] as String? ?? '';
                        final type = connection['connection_type'] as String? ?? 'Unbekannt';
                        final username = connection['username'] as String? ?? 'Anonym';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const CircleAvatar(backgroundColor: Color(0xFF9C27B0), child: Icon(Icons.link, color: Colors.white)),
                            title: Text('$entity1 ↔ $entity2', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Typ: $type', style: const TextStyle(fontSize: 12)),
                                Text('Von $username', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
