import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/cloudflare_api_service.dart';

/// 🌈 ENERGIE-TRACKING - 7-Chakren-Status-Monitor
class EnergieTool extends StatefulWidget {
  final String roomId;  const EnergieTool({super.key, required this.roomId});

  @override
  State<EnergieTool> createState() => _EnergieToolState();
}

class _EnergieToolState extends State<EnergieTool> {
  static const String _baseUrl = 'https://weltenbibliothek-community-api.brandy13062.workers.dev';
  // UNUSED FIELD: final CloudflareApiService _api = CloudflareApiService();
  // UNUSED FIELD: final ChatToolsService _toolsService = ChatToolsService();
  List<EnergieReading> _readings = [];
  bool _isLoading = false;
  Timer? _refreshTimer;

  final Map<String, int> _chakraValues = {
    'Wurzel': 5,
    'Sakral': 5,
    'Solar': 5,
    'Herz': 5,
    'Kehle': 5,
    'Stirn': 5,
    'Krone': 5,
  };

  final Map<String, Color> _chakraColors = {
    'Wurzel': Colors.red,
    'Sakral': Colors.orange,
    'Solar': Colors.yellow,
    'Herz': Colors.green,
    'Kehle': Colors.blue,
    'Stirn': Colors.indigo,
    'Krone': Colors.purple,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    try {
      setState(() => _isLoading = true);
      final response = await http.get(
        Uri.parse('$_baseUrl/api/tools/energie?room_id=${widget.roomId}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['readings'] != null) {
          setState(() {
            _readings = (data['readings'] as List).map((r) => EnergieReading.fromJson(r)).toList();
            _readings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          });
        }
      }
    } catch (e) {
      debugPrint('Fehler: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReading() async {
    try {
      // 🔧 AUTO-FIX: Username-Variable für Chat-Integration
      final generatedUsername = 'Reader${DateTime.now().millisecondsSinceEpoch % 1000}';
      final response = await http.post(
        Uri.parse('$_baseUrl/api/tools/energie'),
        body: json.encode({
          'room_id': widget.roomId,
          'chakra_values': _chakraValues,
          'username': generatedUsername,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Energie-Reading gespeichert!'), backgroundColor: Colors.green),
        );
        await _loadData();
        
        // Chat-Aktivität posten
        try {
          final api = CloudflareApiService();
          // Berechne durchschnittliche Chakra-Energie
          final avgEnergy = (_chakraValues.values.reduce((a, b) => a + b) / _chakraValues.length).round();
          await api.sendToolActivityMessage(
            roomId: widget.roomId,
            realm: 'energie',
            toolName: 'Energie-Tracking',
            username: generatedUsername, // 🔧 FIX: Username übergeben
            activity: 'Chakra-Reading: Durchschnitt $avgEnergy/10',
          );
        } catch (e) {
          debugPrint('Chat-Aktivität fehlgeschlagen: $e');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uniqueReaders = _readings.length; // Simplified: count all readings

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.teal.shade900, Colors.cyan.shade800],
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
                const Text('🌈 ENERGIE-TRACKING', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard('$uniqueReaders', 'Reader', Icons.person),
                    _buildStatCard('${_readings.length}', 'Readings', Icons.auto_awesome),
                    _buildStatCard('7', 'Chakren', Icons.center_focus_strong),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildChakraInput(),
                  const SizedBox(height: 24),
                  _buildReadingsList(),
                ],
              ),
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
        border: Border.all(color: Colors.teal.shade300, width: 2),
      ),
      child: Column(children: [
        Icon(icon, color: Colors.teal.shade200, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.teal.shade200)),
      ]),
    );
  }

  Widget _buildChakraInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🧘 Dein Chakra-Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const Text('Bewerte deine Chakren von 1 (blockiert) bis 10 (voll aktiv)', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 16),
          ..._chakraValues.keys.map((chakra) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _chakraColors[chakra],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$chakra-Chakra',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '${_chakraValues[chakra]}/10',
                        style: TextStyle(color: _chakraColors[chakra], fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _chakraValues[chakra]!.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: _chakraColors[chakra],
                    onChanged: (v) {
                      setState(() => _chakraValues[chakra] = v.toInt());
                    },
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitReading,
              icon: const Icon(Icons.send),
              label: const Text('READING TEILEN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingsList() {
    if (_readings.isEmpty) {
      return Center(child: Column(children: [
        const SizedBox(height: 40),
        Icon(Icons.auto_awesome_outlined, size: 64, color: Colors.teal.shade200),
        const SizedBox(height: 16),
        Text('Noch keine Readings', style: TextStyle(color: Colors.teal.shade200, fontSize: 18)),
      ]));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('💎 GRUPPEN-READINGS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        ..._readings.map((r) => _buildReadingCard(r)),
      ],
    );
  }

  Widget _buildReadingCard(EnergieReading reading) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: Colors.teal, shape: BoxShape.circle),
              child: Center(child: Text("Nutzer"[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text("Nutzer", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 16),
          ...reading.chakraValues.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _chakraColors[e.key],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(e.key, style: TextStyle(color: Colors.teal.shade100))),
                  Container(
                    width: 100,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: e.value / 10,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _chakraColors[e.key],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${e.value}', style: TextStyle(color: _chakraColors[e.key], fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class EnergieReading {
  final String id;
  final Map<String, int> chakraValues;
  final DateTime timestamp;


  EnergieReading({
    required this.id,
    required this.chakraValues,
    required this.timestamp,
  });

  factory EnergieReading.fromJson(Map<String, dynamic> json) {
    return EnergieReading(
      id: json['id']?.toString() ?? '',
      chakraValues: Map<String, int>.from(json['chakra_values'] ?? {}),
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
