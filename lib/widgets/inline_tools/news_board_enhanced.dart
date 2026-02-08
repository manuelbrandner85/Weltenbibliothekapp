import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/user_auth_service.dart'; // ✅ Real Auth

class NewsBoardEnhanced extends StatefulWidget {
  final String roomId;
  const NewsBoardEnhanced({super.key, required this.roomId});
  @override
  State<NewsBoardEnhanced> createState() => _NewsBoardEnhancedState();
}

class _NewsBoardEnhancedState extends State<NewsBoardEnhanced> {
  final _titleController = TextEditingController();
  final _sourceController = TextEditingController();
  List<Map<String, dynamic>> _news = [];
  Timer? _refreshTimer;
  bool _isLoading = false;
  
  // ✅ Real User Auth
  String? _currentUsername;
  String? _currentUserId;
  bool _isAuthenticated = false;
  int _activeCurators = 0;

  @override
  void initState() {
    super.initState();
    _loadUserAuth();
    _loadNews();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadNews());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _titleController.dispose();
    _sourceController.dispose();
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

  Future<void> _loadNews() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.newsTrackerUrl + '?room_id=${widget.roomId}'), headers: {'Authorization': 'Bearer _C578hgIAimVPG0WjfeAjk23RxQMQ9gox0W7ebLv'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _news = data.cast<Map<String, dynamic>>();
          _activeCurators = _news.map((e) => e['username'] as String?).toSet().length;
        });
      }
    } catch (e) {
   if (kDebugMode) {
     debugPrint('⚠️ NewsBoardEnhanced: Error - $e');
   }
   // Silently fail - widget remains functional
 }
  }

  Future<void> _addNews() async {
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
    

    if (_titleController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await http.post(
        Uri.parse(ApiConfig.newsTrackerUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer _C578hgIAimVPG0WjfeAjk23RxQMQ9gox0W7ebLv'
        },
        body: jsonEncode({
          'room_id': widget.roomId,
          'title': _titleController.text.trim(),
          'source': _sourceController.text.trim(),
          'username': _currentUsername, // ✅ Real username
          'user_id': _currentUserId,    // ✅ Real user ID
        }),
      );
      _titleController.clear();
      _sourceController.clear();
      await _loadNews();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📰 News hinzugefügt!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error adding news: $e');
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
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF44336), Color(0xFFD32F2F)]), borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [const Icon(Icons.article, color: Colors.white, size: 28), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('NEWS-BOARD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)), Text('${_news.length} News • $_activeCurators Kuratoren', style: const TextStyle(color: Colors.white70, fontSize: 12))]))]),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(children: [TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'News-Titel', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title))), const SizedBox(height: 8), TextField(controller: _sourceController, decoration: const InputDecoration(labelText: 'Quelle (optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.source))), const SizedBox(height: 12), SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _isLoading ? null : _addNews, icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add), label: const Text('News teilen'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF44336), padding: const EdgeInsets.symmetric(vertical: 14))))])),
          const SizedBox(height: 16),
          Container(constraints: const BoxConstraints(maxHeight: 200), child: _news.isEmpty ? const Center(child: Text('Keine News vorhanden', style: TextStyle(color: Colors.white70))) : ListView.builder(itemCount: _news.length, itemBuilder: (c, i) {
            final n = _news[i];
            return Card(child: ListTile(leading: const CircleAvatar(backgroundColor: Color(0xFFF44336), child: Icon(Icons.article, color: Colors.white)), title: Text(n['title'] ?? 'Unbekannt'), subtitle: Text('Von ${n['username'] ?? 'Anonym'}', style: const TextStyle(fontSize: 11))));
          }))
        ]),
      ),
    );
  }
}
