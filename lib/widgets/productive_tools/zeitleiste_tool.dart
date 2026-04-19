import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../services/cloudflare_api_service.dart';
import 'dart:convert';

class ZeitleisteTool extends StatefulWidget {
  final String roomId;  const ZeitleisteTool({super.key, required this.roomId});
  @override
  State<ZeitleisteTool> createState() => _ZeitleisteToolState();
}

class _ZeitleisteToolState extends State<ZeitleisteTool> {
  final _ereignisController = TextEditingController();
  final _datumController = TextEditingController();
  final _ortController = TextEditingController();
  List<Map<String, dynamic>> _ereignisse = [];
  Timer? _refreshTimer;
  bool _isLoading = false;
  int _activeHistorians = 0;

  @override
  void initState() {
    super.initState();
    _loadEreignisse();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadEreignisse());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _ereignisController.dispose();
    _datumController.dispose();
    _ortController.dispose();
    super.dispose();
  }

  Future<void> _loadEreignisse() async {
    try {
      final response = await http.get(
        Uri.parse('https://weltenbibliothek-community-api.brandy13062.workers.dev/api/tools/zeitleiste'),
        headers: {'Authorization': 'Bearer _C578hgIAimVPG0WjfeAjk23RxQMQ9gox0W7ebLv'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _ereignisse = data.cast<Map<String, dynamic>>();
          _ereignisse.sort((a, b) => (a['datum'] ?? '').compareTo(b['datum'] ?? ''));
          _activeHistorians = _ereignisse.map((e) => e['username'] as String?).toSet().length;
        });
      }
    } catch (e) {
   if (kDebugMode) {
     debugPrint('⚠️ ZeitleisteTool: Error - $e');
   }
   // Silently fail - widget remains functional
 }
  }

  Future<void> _addEreignis() async {
    if (_ereignisController.text.isEmpty || _datumController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await http.post(
        Uri.parse('https://weltenbibliothek-community-api.brandy13062.workers.dev/api/tools/zeitleiste'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer _C578hgIAimVPG0WjfeAjk23RxQMQ9gox0W7ebLv'},        body: jsonEncode({
          'room_id': widget.roomId,
          'ereignis': _ereignisController.text.trim(),
          'datum': _datumController.text.trim(),
          'ort': _ortController.text.trim(),
          'username': 'Historiker${DateTime.now().millisecondsSinceEpoch % 1000}',
        }),
      );
      _ereignisController.clear();
      _datumController.clear();
      _ortController.clear();
      await _loadEreignisse();
      // Chat-Aktivität posten
              try {
                final api = CloudflareApiService();
                await api.sendToolActivityMessage(
                  roomId: widget.roomId,
                  realm: 'materie',
                  toolName: 'Zeitleiste',
            username: 'Historiker${DateTime.now().millisecondsSinceEpoch % 1000}', // ✅ Direct
                  activity: 'Ereignis hinzugefügt: ${_ereignisController.text.trim()} (${_datumController.text.trim()})',
                );
              } catch (e) {
                debugPrint('Chat-Aktivität fehlgeschlagen: $e');
              }

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📅 Ereignis zur Timeline hinzugefügt!')));
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
          Text('📅 ZEITLEISTE - $_activeHistorians Historiker', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _ereignisController, decoration: const InputDecoration(labelText: 'Ereignis', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _datumController, decoration: const InputDecoration(labelText: 'Datum (z.B. 1969-07-20)', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _ortController, decoration: const InputDecoration(labelText: 'Ort (optional)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _isLoading ? null : _addEreignis, child: const Text('Hinzufügen')),
          const SizedBox(height: 20),
          Expanded(
            child: _ereignisse.isEmpty
                ? const Center(child: Text('Noch keine Ereignisse'))
                : ListView.builder(
                    itemCount: _ereignisse.length,
                    itemBuilder: (c, i) {
                      final e = _ereignisse[i];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.event),
                          title: Text(e['ereignis'] ?? 'Unbekannt'),
                          subtitle: Text('${e['datum']} • ${e['ort'] ?? 'Unbekannter Ort'}\nVon ${e['username'] ?? 'Anonym'}'),
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
