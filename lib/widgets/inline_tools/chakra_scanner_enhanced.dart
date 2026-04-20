import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/user_auth_service.dart'; // ✅ Real Auth

class ChakraScannerEnhanced extends StatefulWidget {
  final String roomId;
  const ChakraScannerEnhanced({super.key, required this.roomId});
  @override
  State<ChakraScannerEnhanced> createState() => _ChakraScannerEnhancedState();
}

class _ChakraScannerEnhancedState extends State<ChakraScannerEnhanced> {
  List<Map<String, dynamic>> _readings = [];
  Timer? _refreshTimer;
  bool _isLoading = false;
  int _activeReaders = 0;
  String _selectedChakra = 'Wurzel';
  
  // ✅ Real User Auth
  String? _currentUsername;
  String? _currentUserId;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _loadUserAuth(); // ✅ Load auth first
    _loadReadings();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadReadings());
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
    
    if (kDebugMode) {
      debugPrint('✅ ChakraScanner: Username = $_currentUsername, Authenticated = $_isAuthenticated');
    }
  }

  Future<void> _loadReadings() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.chakraReadingsUrl}?room_id=${widget.roomId}'), headers: {'Authorization': 'Bearer _C578hgIAimVPG0WjfeAjk23RxQMQ9gox0W7ebLv'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _readings = data.cast<Map<String, dynamic>>();
          _activeReaders = _readings.map((e) => e['username'] as String?).toSet().length;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ ChakraScanner: Failed to load readings - $e');
      }
      // Silently fail - widget shows empty/cached state
    }
  }

  Future<void> _addReading() async {
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
        Uri.parse(ApiConfig.chakraReadingsUrl), 
        headers: {
          'Content-Type': 'application/json', 
          'Authorization': 'Bearer _C578hgIAimVPG0WjfeAjk23RxQMQ9gox0W7ebLv'
        }, 
        body: jsonEncode({
          'room_id': widget.roomId, 
          'chakra_name': _selectedChakra, 
          'energy_level': 50, 
          'username': _currentUsername, // ✅ Real username
          'user_id': _currentUserId,    // ✅ Real user ID
        })
      );
      await _loadReadings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔮 $_selectedChakra-Chakra gescannt!'), 
            backgroundColor: Colors.teal
          )
        );
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
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF009688), Color(0xFF00796B)]), borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [const Text('🔮', style: TextStyle(fontSize: 28)), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('CHAKRA-SCANNER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)), Text('${_readings.length} Readings • $_activeReaders Reader', style: const TextStyle(color: Colors.white70, fontSize: 12))]))]),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(children: [DropdownButtonFormField<String>(initialValue: _selectedChakra, decoration: const InputDecoration(labelText: 'Chakra', border: OutlineInputBorder()), items: ['Wurzel', 'Sakral', 'Solarplexus', 'Herz', 'Kehle', 'Stirn', 'Krone'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => _selectedChakra = v!)), const SizedBox(height: 12), SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _isLoading ? null : _addReading, icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add), label: const Text('Scannen'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009688), padding: const EdgeInsets.symmetric(vertical: 14))))])),
          const SizedBox(height: 16),
          Container(constraints: const BoxConstraints(maxHeight: 200), child: _readings.isEmpty ? const Center(child: Text('Keine Readings vorhanden', style: TextStyle(color: Colors.white70))) : ListView.builder(itemCount: _readings.length, itemBuilder: (c, i) {
            final r = _readings[i];
            return Card(child: ListTile(leading: const CircleAvatar(backgroundColor: Color(0xFF009688), child: Icon(Icons.explore, color: Colors.white)), title: Text('${r['chakra_name']}-Chakra'), subtitle: Text('Von ${r['username'] ?? 'Anonym'}', style: const TextStyle(fontSize: 11))));
          }))
        ]),
      ),
    );
  }
}
