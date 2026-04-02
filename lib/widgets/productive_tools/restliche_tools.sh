#!/bin/bash

# 3. SICHTUNGS-KARTE (UFO)
cat > sichtungskarte_tool.dart << 'EOF'
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SichtungsKarteTool extends StatefulWidget {
  final String roomId;
  const SichtungsKarteTool({super.key, required this.roomId});
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
        Uri.parse('https://weltenbibliothek-api.brandy13062.workers.dev/api/tools/sightings?room_id=${widget.roomId}'),
        headers: {'Authorization': 'Bearer _C578hgIAimVPG0WjfeAjk23RxQMQ9gox0W7ebLv'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _sichtungen = data.cast<Map<String, dynamic>>();
          _activeWitnesses = _sichtungen.map((e) => e['username'] as String?).toSet().length;
        });
      }
    } catch (e) {}
  }

  Future<void> _addSichtung() async {
    if (_ortController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await http.post(
        Uri.parse('https://weltenbibliothek-api.brandy13062.workers.dev/api/tools/sightings'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer _C578hgIAimVPG0WjfeAjk23RxQMQ9gox0W7ebLv'},
        body: jsonEncode({
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🛸 Sichtung eingetragen!')));
    } catch (e) {} finally {
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
            value: _selectedTyp,
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
EOF

# 4-10: Weitere Tools (sehr kompakt)
for i in {4..10}; do
  case $i in
    4) NAME="RechercheBoard"; FILE="recherche_tool.dart"; TITLE="RECHERCHE-BOARD"; ICON="account_tree" ;;
    5) NAME="ExperimentLog"; FILE="experiment_tool.dart"; TITLE="EXPERIMENT-LOG"; ICON="science" ;;
    6) NAME="GruppenSession"; FILE="session_tool.dart"; TITLE="GRUPPEN-SESSIONS"; ICON="groups" ;;
    7) NAME="TraumAnalyse"; FILE="traumanalyse_tool.dart"; TITLE="TRAUM-ANALYSE"; ICON="bedtime" ;;
    8) NAME="EnergieTracking"; FILE="energie_tool.dart"; TITLE="ENERGIE-TRACKING"; ICON="energy_savings_leaf" ;;
    9) NAME="WeisheitsBibliothek"; FILE="weisheit_tool.dart"; TITLE="WEISHEITS-BIBLIOTHEK"; ICON="menu_book" ;;
    10) NAME="HeilungsProtokoll"; FILE="heilung_tool.dart"; TITLE="HEILUNGS-PROTOKOLLE"; ICON="healing" ;;
  esac

  cat > $FILE << TOOLEOF
import 'package:flutter/material.dart';

class ${NAME}Tool extends StatelessWidget {
  final String roomId;
  const ${NAME}Tool({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.$ICON, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              '${TITLE}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Produktives Gruppen-Tool\nKommt bald!',
              style: TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Raum-ID: \${roomId}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
TOOLEOF

done

echo "✅ Alle 8 restlichen Tools erstellt"
