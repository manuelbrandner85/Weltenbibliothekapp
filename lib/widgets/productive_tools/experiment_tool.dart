import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/cloudflare_api_service.dart';

/// 🔬 EXPERIMENT-LOG - Kollaboratives Experiment-Dokumentations-Tool
/// Features:
/// - Experimente dokumentieren
/// - Hypothesen formulieren
/// - Ergebnisse teilen
/// - Status tracking (Geplant, Laufend, Abgeschlossen)
/// - Peer-Review-System
/// - Erfolgsrate berechnen
class ExperimentTool extends StatefulWidget {
  final String roomId;

  const ExperimentTool({
    super.key,
    required this.roomId,
  });

  @override
  State<ExperimentTool> createState() => _ExperimentToolState();
}

class _ExperimentToolState extends State<ExperimentTool> {
  // API Configuration
  static const String _baseUrl = 'https://weltenbibliothek-community-api.brandy13062.workers.dev';
  // UNUSED FIELD: final CloudflareApiService _api = CloudflareApiService();
  // UNUSED FIELD: final ChatToolsService _toolsService = ChatToolsService();
  // State
  List<Experiment> _experimente = [];
  bool _isLoading = false;
  Timer? _refreshTimer;

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _hypotheseController = TextEditingController();
  final TextEditingController _methodikController = TextEditingController();
  final TextEditingController _ergebnisController = TextEditingController();
  String _selectedStatus = 'Geplant';
  bool _successful = false;

  // Status Options
  final List<String> _statusOptions = [
    'Geplant',
    'Laufend',
    'Abgeschlossen',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _nameController.dispose();
    _hypotheseController.dispose();
    _methodikController.dispose();
    _ergebnisController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (_isLoading) return;

    try {
      setState(() => _isLoading = true);

      final response = await http.get(
        Uri.parse('$_baseUrl/api/tools/experiment?room_id=${widget.roomId}'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['experiments'] != null) {
          setState(() {
            _experimente = (data['experiments'] as List)
                .map((e) => Experiment.fromJson(e))
                .toList();
            _experimente.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          });
        }
      }
    } catch (e) {
      debugPrint('Fehler beim Laden: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitExperiment() async {
    if (_nameController.text.trim().isEmpty) {
      _showToast('Bitte Experiment-Name eingeben', Colors.orange);
      return;
    }

    if (_hypotheseController.text.trim().isEmpty) {
      _showToast('Bitte Hypothese eingeben', Colors.orange);
      return;
    }

    try {
      // 🔧 AUTO-FIX: Username-Variable für Chat-Integration
      final generatedUsername = 'Wissenschaftler${DateTime.now().millisecondsSinceEpoch % 1000}';
      final response = await http.post(
        Uri.parse('$_baseUrl/api/tools/experiment'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'room_id': widget.roomId,
          'name': _nameController.text.trim(),
          'hypothesis': _hypotheseController.text.trim(),
          'methodology': _methodikController.text.trim(),
          'result': _ergebnisController.text.trim(),
          'status': _selectedStatus,
          'successful': _successful,
          'username': generatedUsername,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showToast('Experiment erfolgreich hinzugefügt!', Colors.green);
        _clearForm();
        await _loadData();
        
        // Chat-Aktivität posten
        try {
          final api = CloudflareApiService();
          await api.sendToolActivityMessage(
            roomId: widget.roomId,
            realm: 'materie',
            toolName: 'Experiment',
            username: generatedUsername, // 🔧 FIX: Username übergeben
            activity: 'Experiment: ${_nameController.text.trim()} - $_selectedStatus',
          );
        } catch (e) {
          debugPrint('Chat-Aktivität fehlgeschlagen: $e');
        }
      } else {
        _showToast('Fehler beim Speichern', Colors.red);
      }
    } catch (e) {
      _showToast('Netzwerkfehler: $e', Colors.red);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _hypotheseController.clear();
    _methodikController.clear();
    _ergebnisController.clear();
    setState(() {
      _selectedStatus = 'Geplant';
      _successful = false;
    });
  }

  void _showToast(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Map<String, int> _getStats() {
    final geplant = _experimente.where((e) => e.status == 'Geplant').length;
    final laufend = _experimente.where((e) => e.status == 'Laufend').length;
    final abgeschlossen = _experimente.where((e) => e.status == 'Abgeschlossen').length;
    final erfolgreich = _experimente.where((e) => e.successful).length;
    
    return {
      'geplant': geplant,
      'laufend': laufend,
      'abgeschlossen': abgeschlossen,
      'erfolgreich': erfolgreich,
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _getStats();
    final uniqueScientists = _experimente.length;
    final successRate = stats['abgeschlossen']! > 0
        ? (stats['erfolgreich']! / stats['abgeschlossen']! * 100).toInt()
        : 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.cyan.shade900,
            Colors.teal.shade800,
          ],
        ),
      ),
      child: Column(
        children: [
          // Header mit Statistik
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  '🔬 EXPERIMENT-LOG',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard('$uniqueScientists', 'Wissenschaftler', Icons.science),
                    _buildStatCard('${_experimente.length}', 'Experimente', Icons.biotech),
                    _buildStatCard('$successRate%', 'Erfolgsrate', Icons.trending_up),
                  ],
                ),
                const SizedBox(height: 12),
                // Status Breakdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMiniStat('${stats['geplant']}', 'Geplant', Colors.blue.shade300),
                    _buildMiniStat('${stats['laufend']}', 'Laufend', Colors.orange.shade300),
                    _buildMiniStat('${stats['abgeschlossen']}', 'Fertig', Colors.green.shade300),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Eingabeformular
                  _buildInputForm(),
                  
                  const SizedBox(height: 24),
                  
                  // Experiment-Liste
                  _buildExperimentList(),
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
        border: Border.all(color: Colors.cyan.shade300, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.cyan.shade200, size: 28),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.cyan.shade200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInputForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '➕ Neues Experiment hinzufügen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Experiment Name
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Experiment-Name',
              labelStyle: TextStyle(color: Colors.cyan.shade200),
              hintText: 'z.B. Quantenverschränkungs-Test',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              prefixIcon: const Icon(Icons.science, color: Colors.cyan),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.cyan.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.cyan.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.cyan, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Status
          DropdownButtonFormField<String>(
            initialValue: _selectedStatus,
            dropdownColor: Colors.cyan.shade900,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Status',
              labelStyle: TextStyle(color: Colors.cyan.shade200),
              prefixIcon: const Icon(Icons.flag, color: Colors.cyan),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.cyan.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.cyan.shade300),
              ),
            ),
            items: _statusOptions.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Row(
                  children: [
                    _getStatusIcon(status),
                    const SizedBox(width: 8),
                    Text(status),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedStatus = value);
              }
            },
          ),
          const SizedBox(height: 12),

          // Hypothese
          TextField(
            controller: _hypotheseController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Hypothese',
              labelStyle: TextStyle(color: Colors.cyan.shade200),
              hintText: 'Was erwartest du als Ergebnis?',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              prefixIcon: const Icon(Icons.lightbulb, color: Colors.cyan),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.cyan.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.cyan.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.cyan, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Methodik
          TextField(
            controller: _methodikController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Methodik',
              labelStyle: TextStyle(color: Colors.cyan.shade200),
              hintText: 'Wie führst du das Experiment durch?',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              prefixIcon: const Icon(Icons.list, color: Colors.cyan),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.cyan.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.cyan.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.cyan, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Ergebnis (nur bei "Abgeschlossen")
          if (_selectedStatus == 'Abgeschlossen') ...[
            TextField(
              controller: _ergebnisController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Ergebnis',
                labelStyle: TextStyle(color: Colors.cyan.shade200),
                hintText: 'Was ist das Resultat?',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                prefixIcon: const Icon(Icons.check_circle, color: Colors.cyan),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.cyan.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.cyan.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.cyan, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Erfolgreich?
            Row(
              children: [
                Checkbox(
                  value: _successful,
                  activeColor: Colors.cyan,
                  onChanged: (value) {
                    setState(() => _successful = value ?? false);
                  },
                ),
                Text(
                  'Experiment erfolgreich?',
                  style: TextStyle(
                    color: Colors.cyan.shade200,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitExperiment,
              icon: const Icon(Icons.add),
              label: const Text(
                'EXPERIMENT HINZUFÜGEN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'Geplant':
        return Icon(Icons.schedule, color: Colors.blue.shade300, size: 20);
      case 'Laufend':
        return Icon(Icons.hourglass_empty, color: Colors.orange.shade300, size: 20);
      case 'Abgeschlossen':
        return Icon(Icons.check_circle, color: Colors.green.shade300, size: 20);
      default:
        return const Icon(Icons.help, color: Colors.grey, size: 20);
    }
  }

  Widget _buildExperimentList() {
    if (_experimente.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.science_outlined,
              size: 64,
              color: Colors.cyan.shade200,
            ),
            const SizedBox(height: 16),
            Text(
              'Noch keine Experimente vorhanden',
              style: TextStyle(
                color: Colors.cyan.shade200,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🔬 LAUFENDE & VERGANGENE EXPERIMENTE',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ..._experimente.map((exp) => _buildExperimentCard(exp)),
      ],
    );
  }

  Widget _buildExperimentCard(Experiment exp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: exp.status == 'Abgeschlossen'
              ? Colors.green.shade300
              : exp.status == 'Laufend'
                  ? Colors.orange.shade300
                  : Colors.cyan.shade300,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.cyan,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    "Nutzer"[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Nutzer",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatTimestamp(exp.timestamp),
                      style: TextStyle(
                        color: Colors.cyan.shade200,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: exp.status == 'Abgeschlossen'
                      ? Colors.green.shade700
                      : exp.status == 'Laufend'
                          ? Colors.orange.shade700
                          : Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _getStatusIcon(exp.status),
                    const SizedBox(width: 6),
                    Text(
                      exp.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Experiment Name
          Text(
            exp.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Hypothese
          _buildSection('💡 Hypothese', exp.hypothesis),
          
          // Methodik
          if (exp.methodology.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSection('📋 Methodik', exp.methodology),
          ],

          // Ergebnis (nur bei Abgeschlossen)
          if (exp.status == 'Abgeschlossen' && exp.result.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSection('✅ Ergebnis', exp.result),
            const SizedBox(height: 12),
            // Erfolg-Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: exp.successful ? Colors.green.shade700 : Colors.red.shade700,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    exp.successful ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    exp.successful ? 'ERFOLGREICH' : 'FEHLGESCHLAGEN',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.cyan.shade200,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'vor ${diff.inHours}h';
    return 'vor ${diff.inDays}d';
  }
}

// Experiment Model
class Experiment {
  final String id;
  final String name;
  final String hypothesis;
  final String methodology;
  final String result;
  final String status;
  final bool successful;  final DateTime timestamp;

  Experiment({
    required this.id,
    required this.name,
    required this.hypothesis,
    required this.methodology,
    required this.result,
    required this.status,
    required this.successful,
    required this.timestamp,
  });

  factory Experiment.fromJson(Map<String, dynamic> json) {
    return Experiment(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      hypothesis: json['hypothesis']?.toString() ?? '',
      methodology: json['methodology']?.toString() ?? '',
      result: json['result']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Geplant',
      successful: json['successful'] as bool? ?? false,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
