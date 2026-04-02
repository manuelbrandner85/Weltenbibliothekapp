import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/cloudflare_api_service.dart';

/// 💚 HEILUNGS-PROTOKOLLE - Heilmethoden dokumentieren
class HeilungTool extends StatefulWidget {
  final String roomId;  const HeilungTool({super.key, required this.roomId});

  @override
  State<HeilungTool> createState() => _HeilungToolState();
}

class _HeilungToolState extends State<HeilungTool> {
  static const String _baseUrl = 'https://weltenbibliothek-community-api.brandy13062.workers.dev';
  // UNUSED FIELD: final CloudflareApiService _api = CloudflareApiService();
  // UNUSED FIELD: final ChatToolsService _toolsService = ChatToolsService();
  List<HeilProtokoll> _protokolle = [];
  bool _isLoading = false;
  Timer? _refreshTimer;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _beschreibungController = TextEditingController();
  final TextEditingController _anwendungController = TextEditingController();
  final TextEditingController _warnungenController = TextEditingController();
  String _selectedKategorie = 'Energiearbeit';
  int _effektivitaet = 5;

  final List<String> _kategorien = [
    'Energiearbeit',
    'Frequenzen',
    'Kräuter',
    'Meditation',
    'Atemtechniken',
    'Kristalle',
    'Akupressur',
    'Yoga',
    'Ernährung',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _nameController.dispose();
    _beschreibungController.dispose();
    _anwendungController.dispose();
    _warnungenController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    try {
      setState(() => _isLoading = true);
      final response = await http.get(
        Uri.parse('$_baseUrl/api/tools/heilung?room_id=${widget.roomId}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['protocols'] != null) {
          setState(() {
            _protokolle = (data['protocols'] as List).map((p) => HeilProtokoll.fromJson(p)).toList();
            _protokolle.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          });
        }
      }
    } catch (e) {
      debugPrint('Fehler: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitProtokoll() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Name eingeben'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      // 🔧 AUTO-FIX: Username-Variable für Chat-Integration
      final generatedUsername = 'Heiler${DateTime.now().millisecondsSinceEpoch % 1000}';
      final response = await http.post(
        Uri.parse('$_baseUrl/api/tools/heilung'),
        body: json.encode({
          'room_id': widget.roomId,
          'name': _nameController.text.trim(),
          'beschreibung': _beschreibungController.text.trim(),
          'anwendung': _anwendungController.text.trim(),
          'warnungen': _warnungenController.text.trim(),
          'kategorie': _selectedKategorie,
          'effektivitaet': _effektivitaet,
          'username': generatedUsername,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Chat-Aktivität posten (VOR dem Clearen!)
        final methodeName = _nameController.text.trim();
        
        try {
          final api = CloudflareApiService();
          await api.sendToolActivityMessage(
            roomId: widget.roomId,
            realm: 'energie',
            toolName: 'Heilungs-Protokoll',
            username: generatedUsername, // 🔧 FIX: username von JSON übernehmen
            activity: 'Heilung: $methodeName ($_selectedKategorie, Effektivität $_effektivitaet/10)',
          );
        } catch (e) {
          debugPrint('Chat-Aktivität fehlgeschlagen: $e');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Protokoll hinzugefügt!'), backgroundColor: Colors.green),
        );
        _nameController.clear();
        _beschreibungController.clear();
        _anwendungController.clear();
        _warnungenController.clear();
        setState(() => _effektivitaet = 5);
        await _loadData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uniqueHealer = _protokolle.length;
    final avgEffectiveness = _protokolle.isEmpty ? 0 : (_protokolle.map((p) => p.effektivitaet).reduce((a, b) => a + b) / _protokolle.length).round();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade900, Colors.teal.shade800],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const Text('💚 HEILUNGS-PROTOKOLLE', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard('$uniqueHealer', 'Heiler', Icons.healing),
                    _buildStatCard('${_protokolle.length}', 'Protokolle', Icons.medical_services),
                    _buildStatCard('$avgEffectiveness/10', 'Ø Rating', Icons.star),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [_buildInputForm(), const SizedBox(height: 24), _buildProtokollList()]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300, width: 2),
      ),
      child: Column(children: [
        Icon(icon, color: Colors.green.shade200, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.green.shade200)),
      ]),
    );
  }

  Widget _buildInputForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('➕ Neues Heilungs-Protokoll', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Name der Methode',
              hintText: 'z.B. Reiki-Heilung',
              labelStyle: TextStyle(color: Colors.green.shade200),
              prefixIcon: const Icon(Icons.healing, color: Colors.green),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedKategorie,
            dropdownColor: Colors.green.shade900,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Kategorie',
              labelStyle: TextStyle(color: Colors.green.shade200),
              prefixIcon: const Icon(Icons.category, color: Colors.green),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _kategorien.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedKategorie = v);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _beschreibungController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Beschreibung',
              hintText: 'Wie funktioniert diese Methode?',
              labelStyle: TextStyle(color: Colors.green.shade200),
              prefixIcon: const Icon(Icons.description, color: Colors.green),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _anwendungController,
            maxLines: 2,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Anwendung',
              hintText: 'Wie wird es angewendet?',
              labelStyle: TextStyle(color: Colors.green.shade200),
              prefixIcon: const Icon(Icons.medical_services, color: Colors.green),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _warnungenController,
            maxLines: 2,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Warnungen / Nebenwirkungen',
              hintText: 'Gibt es Risiken?',
              labelStyle: TextStyle(color: Colors.red.shade200),
              prefixIcon: const Icon(Icons.warning, color: Colors.red),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Text('Effektivität: ', style: TextStyle(color: Colors.green.shade200, fontWeight: FontWeight.bold)),
            Expanded(
              child: Slider(
                value: _effektivitaet.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: Colors.green,
                label: '$_effektivitaet/10',
                onChanged: (v) => setState(() => _effektivitaet = v.toInt()),
              ),
            ),
            Text('$_effektivitaet/10', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitProtokoll,
              icon: const Icon(Icons.add),
              label: const Text('PROTOKOLL HINZUFÜGEN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtokollList() {
    if (_protokolle.isEmpty) {
      return Center(child: Column(children: [
        const SizedBox(height: 40),
        Icon(Icons.medical_services_outlined, size: 64, color: Colors.green.shade200),
        const SizedBox(height: 16),
        Text('Noch keine Protokolle', style: TextStyle(color: Colors.green.shade200, fontSize: 18)),
      ]));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🌿 DOKUMENTIERTE HEILMETHODEN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        ..._protokolle.map((p) => _buildProtokollCard(p)),
      ],
    );
  }

  Widget _buildProtokollCard(HeilProtokoll protokoll) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              child: const Icon(Icons.healing, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(protokoll.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(protokoll.kategorie, style: TextStyle(color: Colors.green.shade200, fontSize: 12)),
                ],
              ),
            ),
            Row(children: List.generate(5, (i) => Icon(i < protokoll.effektivitaet ? Icons.star : Icons.star_border, color: Colors.amber, size: 16))),
          ]),
          const SizedBox(height: 12),
          Text(protokoll.beschreibung, style: TextStyle(color: Colors.green.shade100)),
          if (protokoll.anwendung.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [const Icon(Icons.medical_services, size: 16, color: Colors.white), const SizedBox(width: 8), const Text('Anwendung:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 4),
                  Text(protokoll.anwendung, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
          if (protokoll.warnungen.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.shade900.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [const Icon(Icons.warning, size: 16, color: Colors.red), const SizedBox(width: 8), const Text('⚠️ Warnungen:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 4),
                  Text(protokoll.warnungen, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.person, size: 16, color: Colors.white70),
            const SizedBox(width: 8),
            Text('Geteilt von: ${"Nutzer"}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ],
      ),
    );
  }
}

class HeilProtokoll {
  final String id, name, beschreibung, anwendung, warnungen, kategorie;
  final int effektivitaet;
  final DateTime timestamp;


  HeilProtokoll({
    required this.id,
    required this.name,
    required this.beschreibung,
    required this.anwendung,
    required this.warnungen,
    required this.kategorie,
    required this.effektivitaet,
    required this.timestamp,
  });

  factory HeilProtokoll.fromJson(Map<String, dynamic> json) {
    return HeilProtokoll(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      beschreibung: json['beschreibung']?.toString() ?? '',
      anwendung: json['anwendung']?.toString() ?? '',
      warnungen: json['warnungen']?.toString() ?? '',
      kategorie: json['kategorie']?.toString() ?? 'Energiearbeit',
      effektivitaet: json['effektivitaet'] as int? ?? 5,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
