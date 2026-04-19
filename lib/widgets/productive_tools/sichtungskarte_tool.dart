import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../services/cloudflare_api_service.dart';
import 'dart:convert';

class SichtungsKarteTool extends StatefulWidget {
  final String roomId;  const SichtungsKarteTool({super.key, required this.roomId});
  @override
  State<SichtungsKarteTool> createState() => _SichtungsKarteToolState();
}

class _SichtungsKarteToolState extends State<SichtungsKarteTool> {
  final _ortController = TextEditingController();
  final _koordinatenController = TextEditingController();
  final _beschreibungController = TextEditingController();
  List<Map<String, dynamic>> _sichtungen = [];
  Timer? _refreshTimer;
  bool _isLoading = false;
  int _activeWitnesses = 0;
  String _selectedTyp = 'Licht';

  @override
  void initState() {
    super.initState();
    _loadSichtungen();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadSichtungen());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _ortController.dispose();
    _koordinatenController.dispose();
    _beschreibungController.dispose();
    super.dispose();
  }

  Future<void> _loadSichtungen() async {
    try {
      final response = await http.get(
        Uri.parse('https://weltenbibliothek-community-api.brandy13062.workers.dev/api/tools/sichtungen'),
        headers: {'Authorization': 'Bearer _C578hgIAimVPG0WjfeAjk23RxQMQ9gox0W7ebLv'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _sichtungen = data.cast<Map<String, dynamic>>();
          _activeWitnesses = _sichtungen.map((e) => e['username'] as String?).toSet().length;
        });
      }
    } catch (e) {
   if (kDebugMode) {
     debugPrint('⚠️ SichtungskarteTool: Error - $e');
   }
   // Silently fail - widget remains functional
 }
  }

  Future<void> _addSichtung() async {
    if (_ortController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await http.post(
        Uri.parse('https://weltenbibliothek-community-api.brandy13062.workers.dev/api/tools/sichtungen'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer _C578hgIAimVPG0WjfeAjk23RxQMQ9gox0W7ebLv'},        body: jsonEncode({
          'room_id': widget.roomId,
          'ort': _ortController.text.trim(),
          'koordinaten': _koordinatenController.text.trim(),
          'typ': _selectedTyp,
          'beschreibung': _beschreibungController.text.trim(),
          'username': 'Zeuge${DateTime.now().millisecondsSinceEpoch % 1000}',
        }),
      );
      _ortController.clear();
      _koordinatenController.clear();
      _beschreibungController.clear();
      await _loadSichtungen();
      
      // Chat-Aktivität posten
      try {
        final api = CloudflareApiService();
        await api.sendToolActivityMessage(
          roomId: widget.roomId,
          realm: 'materie',
          toolName: 'Sichtungskarte',
            username: 'Zeuge${DateTime.now().millisecondsSinceEpoch % 1000}', // ✅ Direct
          activity: 'UFO-Sichtung: $_selectedTyp am ${_ortController.text.trim()}',
        );
      } catch (e) {
        debugPrint('Chat-Aktivität fehlgeschlagen: $e');
      }
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🛸 Sichtung eingetragen!')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('🗺️ SICHTUNGS-KARTE - $_activeWitnesses Zeugen', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          TextField(controller: _ortController, decoration: const InputDecoration(labelText: 'Ort', border: OutlineInputBorder()), style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          TextField(controller: _koordinatenController, decoration: const InputDecoration(labelText: 'Koordinaten (optional)', border: OutlineInputBorder()), style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedTyp,
            decoration: const InputDecoration(labelText: 'UFO-Typ', border: OutlineInputBorder()),
            items: ['Licht', 'Scheibe', 'Dreieck', 'Zigarre', 'Sonstiges'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _selectedTyp = v!),
          ),
          const SizedBox(height: 8),
          TextField(controller: _beschreibungController, decoration: const InputDecoration(labelText: 'Beschreibung', border: OutlineInputBorder()), maxLines: 2, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _isLoading ? null : _addSichtung, child: const Text('Sichtung melden')),
          const SizedBox(height: 20),
          Expanded(
            child: _sichtungen.isEmpty
                ? const Center(child: Text('Keine Sichtungen', style: TextStyle(color: Colors.white70)))
                : ListView.builder(
                    itemCount: _sichtungen.length,
                    itemBuilder: (c, i) {
                      final s = _sichtungen[i];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.place, color: Colors.green),
                          title: Text('${s['ort']} - ${s['typ']}'),
                          subtitle: Text('${s['beschreibung']}\nVon ${s['username']}'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
