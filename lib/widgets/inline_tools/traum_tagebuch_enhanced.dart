import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/user_auth_service.dart'; // ✅ Real Auth

class TraumTagebuchEnhanced extends StatefulWidget {
  final String roomId;
  const TraumTagebuchEnhanced({super.key, required this.roomId});
  @override
  State<TraumTagebuchEnhanced> createState() => _TraumTagebuchEnhancedState();
}

class _TraumTagebuchEnhancedState extends State<TraumTagebuchEnhanced> {
  final _descController = TextEditingController();
  List<Map<String, dynamic>> _dreams = [];
  Timer? _refreshTimer;
  bool _isLoading = false;
  
  // ✅ Real User Auth
  String? _currentUsername;
  String? _currentUserId;
  bool _isAuthenticated = false;
  int _activeDreamers = 0;

  @override
  void initState() {
    super.initState();
    _loadUserAuth();
    _loadDreams();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadDreams());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _descController.dispose();
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

  Future<void> _loadDreams() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.traeumeUrl + '?room_id=${widget.roomId}'), headers: {'Authorization': 'Bearer _C578hgIAimVPG0WjfeAjk23RxQMQ9gox0W7ebLv'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _dreams = data.cast<Map<String, dynamic>>();
          _activeDreamers = _dreams.map((e) => e['username'] as String?).toSet().length;
        });
      }
    } catch (e) {
   if (kDebugMode) {
     debugPrint('⚠️ TraumTagebuchEnhanced: Error - $e');
   }
   // Silently fail - widget remains functional
 }
  }

  Future<void> _addDream() async {
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
    

    if (_descController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await http.post(
        Uri.parse(ApiConfig.traeumeUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer _C578hgIAimVPG0WjfeAjk23RxQMQ9gox0W7ebLv'
        },
        body: jsonEncode({
          'room_id': widget.roomId,
          'dream_description': _descController.text.trim(),
          'username': _currentUsername, // ✅ Real username
          'user_id': _currentUserId,    // ✅ Real user ID
        }),
      );
      _descController.clear();
      await _loadDreams();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💭 Traum geteilt!'),
            backgroundColor: Colors.indigo,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error adding dream: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF673AB7), Color(0xFF512DA8)]), borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [const Text('💭', style: TextStyle(fontSize: 28)), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('TRAUM-TAGEBUCH', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)), Text('${_dreams.length} Träume • $_activeDreamers Träumer', style: const TextStyle(color: Colors.white70, fontSize: 12))]))]),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(children: [TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Traum-Beschreibung', border: OutlineInputBorder(), prefixIcon: Icon(Icons.cloud)), maxLines: 3), const SizedBox(height: 12), SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _isLoading ? null : _addDream, icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add), label: const Text('Traum teilen'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF673AB7), padding: const EdgeInsets.symmetric(vertical: 14))))])),
          const SizedBox(height: 16),
          Container(constraints: const BoxConstraints(maxHeight: 200), child: _dreams.isEmpty ? const Center(child: Text('Keine Träume vorhanden', style: TextStyle(color: Colors.white70))) : ListView.builder(itemCount: _dreams.length, itemBuilder: (c, i) {
            final d = _dreams[i];
            return Card(child: ListTile(leading: const CircleAvatar(backgroundColor: Color(0xFF673AB7), child: Icon(Icons.cloud, color: Colors.white)), title: Text(d['dream_description'] ?? 'Unbekannt'), subtitle: Text('Von ${d['username'] ?? 'Anonym'}', style: const TextStyle(fontSize: 11))));
          }))
        ]),
      ),
    );
  }
}
