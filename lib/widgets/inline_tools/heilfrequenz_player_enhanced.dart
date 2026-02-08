import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/user_auth_service.dart'; // ✅ Real Auth

class HeilfrequenzPlayerEnhanced extends StatefulWidget {
  final String roomId;
  const HeilfrequenzPlayerEnhanced({super.key, required this.roomId});
  @override
  State<HeilfrequenzPlayerEnhanced> createState() => _HeilfrequenzPlayerEnhancedState();
}

class _HeilfrequenzPlayerEnhancedState extends State<HeilfrequenzPlayerEnhanced> {
  List<Map<String, dynamic>> _sessions = [];
  Timer? _refreshTimer;
  bool _isLoading = false;
  
  // ✅ Real User Auth
  String? _currentUsername;
  String? _currentUserId;
  bool _isAuthenticated = false;
  int _activeHealers = 0;
  String _selectedFreq = '396 Hz';

  @override
  void initState() {
    super.initState();
    _loadUserAuth();
    _loadSessions();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadSessions());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
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

  Future<void> _loadSessions() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.heilfrequenzUrl + '?room_id=${widget.roomId}'), headers: {'Authorization': 'Bearer _C578hgIAimVPG0WjfeAjk23RxQMQ9gox0W7ebLv'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _sessions = data.cast<Map<String, dynamic>>();
          _activeHealers = _sessions.map((e) => e['username'] as String?).toSet().length;
        });
      }
    } catch (e) {
   if (kDebugMode) {
     debugPrint('⚠️ HeilfrequenzPlayerEnhanced: Error - $e');
   }
   // Silently fail - widget remains functional
 }
  }

  Future<void> _startSession() async {
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
    

    setState(() => _isLoading = true);
    try {
      await http.post(
        Uri.parse(ApiConfig.heilfrequenzUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer _C578hgIAimVPG0WjfeAjk23RxQMQ9gox0W7ebLv'
        },
        body: jsonEncode({
          'room_id': widget.roomId,
          'frequency': _selectedFreq,
          'username': _currentUsername, // ✅ Real username
          'user_id': _currentUserId,    // ✅ Real user ID
        }),
      );
      await _loadSessions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎵 Heilsession gestartet: $_selectedFreq'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error starting heilfrequenz session: $e');
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
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF388E3C)]), borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [const Text('🎵', style: TextStyle(fontSize: 28)), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('HEILFREQUENZ-PLAYER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)), Text('${_sessions.length} Sessions • $_activeHealers Heiler', style: const TextStyle(color: Colors.white70, fontSize: 12))]))]),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(children: [DropdownButtonFormField<String>(initialValue: _selectedFreq, decoration: const InputDecoration(labelText: 'Solfeggio-Frequenz', border: OutlineInputBorder()), items: ['174 Hz (Erdung)', '285 Hz (Gewebeheilung)', '396 Hz (Angst lösen)', '417 Hz (Veränderung)', '528 Hz (Transformation)', '639 Hz (Beziehungen)', '741 Hz (Erwachen)', '852 Hz (Intuition)', '963 Hz (Erleuchtung)'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(), onChanged: (v) => setState(() => _selectedFreq = v!)), const SizedBox(height: 12), SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _isLoading ? null : _startSession, icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_arrow), label: const Text('Session starten'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50), padding: const EdgeInsets.symmetric(vertical: 14))))])),
          const SizedBox(height: 16),
          Container(constraints: const BoxConstraints(maxHeight: 200), child: _sessions.isEmpty ? const Center(child: Text('Keine Sessions aktiv', style: TextStyle(color: Colors.white70))) : ListView.builder(itemCount: _sessions.length, itemBuilder: (c, i) {
            final s = _sessions[i];
            return Card(child: ListTile(leading: const CircleAvatar(backgroundColor: Color(0xFF4CAF50), child: Icon(Icons.music_note, color: Colors.white)), title: Text(s['frequency'] ?? 'Unbekannt'), subtitle: Text('Von ${s['username'] ?? 'Anonym'}', style: const TextStyle(fontSize: 11))));
          }))
        ]),
      ),
    );
  }
}
