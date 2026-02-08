import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/user_auth_service.dart'; // ✅ Real Auth

class PatentArchivEnhanced extends StatefulWidget {
  final String roomId;
  const PatentArchivEnhanced({super.key, required this.roomId});
  @override
  State<PatentArchivEnhanced> createState() => _PatentArchivEnhancedState();
}

class _PatentArchivEnhancedState extends State<PatentArchivEnhanced> {
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  List<Map<String, dynamic>> _patents = [];
  Timer? _refreshTimer;
  bool _isLoading = false;
  
  // ✅ Real User Auth
  String? _currentUsername;
  String? _currentUserId;
  bool _isAuthenticated = false;
  int _activeArchivists = 0;

  @override
  void initState() {
    super.initState();
    _loadUserAuth();
    _loadPatents();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadPatents());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _nameController.dispose();
    _numberController.dispose();
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

  Future<void> _loadPatents() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.patenteUrl + '?room_id=${widget.roomId}'),
        headers: {'Authorization': 'Bearer _C578hgIAimVPG0WjfeAjk23RxQMQ9gox0W7ebLv'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _patents = data.cast<Map<String, dynamic>>();
          _activeArchivists = _patents.map((e) => e['username'] as String?).toSet().length;
        });
      }
    } catch (e) {
   if (kDebugMode) {
     debugPrint('⚠️ PatentArchivEnhanced: Error - $e');
   }
   // Silently fail - widget remains functional
 }
  }

  Future<void> _addPatent() async {
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
    

    if (_nameController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await http.post(
        Uri.parse(ApiConfig.patenteUrl),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer _C578hgIAimVPG0WjfeAjk23RxQMQ9gox0W7ebLv'},
        body: jsonEncode({
          'room_id': widget.roomId,
          'patent_name': _nameController.text.trim(),
          'patent_number': _numberController.text.trim(),
          'username': _currentUsername, // ✅ Real username
          'user_id': _currentUserId,    // ✅ Real user ID,
        }),
      );
      _nameController.clear();
      _numberController.clear();
      await _loadPatents();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📜 Patent archiviert!'), backgroundColor: Colors.blue));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF1976D2)]), borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.gavel, color: Colors.white, size: 28),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('PATENT-ARCHIV', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('${_patents.length} Patente • $_activeArchivists Archivare', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ])),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Patent-Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description))),
                const SizedBox(height: 8),
                TextField(controller: _numberController, decoration: const InputDecoration(labelText: 'Patentnummer (optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.numbers))),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _addPatent,
                    icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add),
                    label: const Text('Archivieren'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3), padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: _patents.isEmpty
                  ? const Center(child: Text('Noch keine Patente', style: TextStyle(color: Colors.white70)))
                  : ListView.builder(
                      itemCount: _patents.length,
                      itemBuilder: (c, i) {
                        final p = _patents[i];
                        return Card(child: ListTile(leading: const CircleAvatar(backgroundColor: Color(0xFF2196F3), child: Icon(Icons.gavel, color: Colors.white)), title: Text(p['patent_name'] ?? 'Unbekannt'), subtitle: Text('Von ${p['username'] ?? 'Anonym'}', style: const TextStyle(fontSize: 11))));
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
