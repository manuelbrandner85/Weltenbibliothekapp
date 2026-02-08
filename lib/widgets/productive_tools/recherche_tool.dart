import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/cloudflare_api_service.dart';

/// 🕸️ RECHERCHE-BOARD - Kollaboratives Recherche-Tool
/// Features:
/// - Notizen & Dokumente sammeln
/// - Verbindungen zwischen Notizen visualisieren
/// - Tags/Kategorien für Organisation
/// - Vertrauenswürdigkeit bewerten (1-5 Sterne)
/// - Quellen-Links teilen
/// - Gemeinsame Kommentare
class RechercheTool extends StatefulWidget {
  final String roomId;

  const RechercheTool({
    super.key,
    required this.roomId,
  });

  @override
  State<RechercheTool> createState() => _RechercheToolState();
}

class _RechercheToolState extends State<RechercheTool> {
  // API Configuration
  static const String _baseUrl = 'https://weltenbibliothek-community-api.brandy13062.workers.dev';
  // UNUSED FIELD: final CloudflareApiService _api = CloudflareApiService();
  // UNUSED FIELD: final ChatToolsService _toolsService = ChatToolsService();
  // State
  List<Notiz> _notizen = [];
  bool _isLoading = false;
  Timer? _refreshTimer;

  // Form Controllers
  final TextEditingController _titelController = TextEditingController();
  final TextEditingController _inhaltController = TextEditingController();
  final TextEditingController _quelleController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  int _selectedTrustLevel = 3;
  String _selectedCategory = 'Allgemein';

  // Categories
  final List<String> _categories = [
    'Allgemein',
    'Politik',
    'Wirtschaft',
    'Technologie',
    'Wissenschaft',
    'Geheime Projekte',
    'Historische Fakten',
    'Whistleblower',
    'Dokumente',
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
    _titelController.dispose();
    _inhaltController.dispose();
    _quelleController.dispose();
    _tagsController.dispose();
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
        Uri.parse('$_baseUrl/api/tools/recherche?room_id=${widget.roomId}'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['notizen'] != null) {
          setState(() {
            _notizen = (data['notizen'] as List)
                .map((n) => Notiz.fromJson(n))
                .toList();
            _notizen.sort((a, b) => b.timestamp.compareTo(a.timestamp));
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

  Future<void> _submitNotiz() async {
    if (_titelController.text.trim().isEmpty) {
      _showToast('Bitte Titel eingeben', Colors.orange);
      return;
    }

    if (_inhaltController.text.trim().isEmpty) {
      _showToast('Bitte Inhalt eingeben', Colors.orange);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/tools/recherche'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'room_id': widget.roomId,
          'title': _titelController.text.trim(),
          'content': _inhaltController.text.trim(),
          'source_url': _quelleController.text.trim(),
          'tags': _tagsController.text.trim(),
          'category': _selectedCategory,
          'trust_level': _selectedTrustLevel,
          'username': 'Forscher${DateTime.now().millisecondsSinceEpoch % 1000}',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showToast('Notiz erfolgreich hinzugefügt!', Colors.green);
        _clearForm();
        await _loadData();
        
        // Chat-Aktivität posten
        try {
          final api = CloudflareApiService();
          await api.sendToolActivityMessage(
            roomId: widget.roomId,
            realm: 'materie',
            toolName: 'Recherche',
            username: 'Forscher${DateTime.now().millisecondsSinceEpoch % 1000}', // ✅ Direct
            activity: 'Recherche-Notiz: ${_titelController.text.trim()} ($_selectedCategory)',
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
    _titelController.clear();
    _inhaltController.clear();
    _quelleController.clear();
    _tagsController.clear();
    setState(() {
      _selectedTrustLevel = 3;
      _selectedCategory = 'Allgemein';
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

  @override
  Widget build(BuildContext context) {
    final uniqueResearchers = _notizen.length;
    final totalNotes = _notizen.length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade900,
            Colors.deepPurple.shade800,
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
                  '🕸️ RECHERCHE-BOARD',
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
                    _buildStatCard('$uniqueResearchers', 'Forscher', Icons.person),
                    _buildStatCard('$totalNotes', 'Notizen', Icons.note),
                    _buildStatCard('${_categories.length}', 'Kategorien', Icons.category),
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
                  
                  // Notizenliste
                  _buildNotizenList(),
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
        border: Border.all(color: Colors.purple.shade300, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.purple.shade200, size: 28),
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
              color: Colors.purple.shade200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '➕ Neue Notiz hinzufügen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Titel
          TextField(
            controller: _titelController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Titel',
              labelStyle: TextStyle(color: Colors.purple.shade200),
              hintText: 'z.B. Geheimes Dokument entdeckt',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              prefixIcon: const Icon(Icons.title, color: Colors.purple),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.purple.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.purple.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.purple, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Kategorie
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            dropdownColor: Colors.purple.shade900,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Kategorie',
              labelStyle: TextStyle(color: Colors.purple.shade200),
              prefixIcon: const Icon(Icons.category, color: Colors.purple),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.purple.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.purple.shade300),
              ),
            ),
            items: _categories.map((cat) {
              return DropdownMenuItem(
                value: cat,
                child: Text(cat),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCategory = value);
              }
            },
          ),
          const SizedBox(height: 12),

          // Inhalt
          TextField(
            controller: _inhaltController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Inhalt',
              labelStyle: TextStyle(color: Colors.purple.shade200),
              hintText: 'Beschreibe deine Recherche-Ergebnisse...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              prefixIcon: const Icon(Icons.description, color: Colors.purple),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.purple.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.purple.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.purple, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Quelle (URL)
          TextField(
            controller: _quelleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Quelle (URL)',
              labelStyle: TextStyle(color: Colors.purple.shade200),
              hintText: 'https://...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              prefixIcon: const Icon(Icons.link, color: Colors.purple),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.purple.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.purple.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.purple, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Tags
          TextField(
            controller: _tagsController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Tags (Komma-getrennt)',
              labelStyle: TextStyle(color: Colors.purple.shade200),
              hintText: 'geheim, dokument, wichtig',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              prefixIcon: const Icon(Icons.tag, color: Colors.purple),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.purple.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.purple.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.purple, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Vertrauenswürdigkeit
          Row(
            children: [
              Text(
                'Vertrauenswürdigkeit: ',
                style: TextStyle(
                  color: Colors.purple.shade200,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _selectedTrustLevel.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: Colors.purple,
                  inactiveColor: Colors.purple.shade200,
                  label: '$_selectedTrustLevel ⭐',
                  onChanged: (value) {
                    setState(() => _selectedTrustLevel = value.toInt());
                  },
                ),
              ),
              Text(
                '$_selectedTrustLevel ⭐',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitNotiz,
              icon: const Icon(Icons.add),
              label: const Text(
                'NOTIZ HINZUFÜGEN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
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

  Widget _buildNotizenList() {
    if (_notizen.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.purple.shade200,
            ),
            const SizedBox(height: 16),
            Text(
              'Noch keine Notizen vorhanden',
              style: TextStyle(
                color: Colors.purple.shade200,
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
          '📚 RECHERCHE-NOTIZEN',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ..._notizen.map((notiz) => _buildNotizCard(notiz)),
      ],
    );
  }

  Widget _buildNotizCard(Notiz notiz) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade300, width: 2),
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
                decoration: BoxDecoration(
                  color: Colors.purple,
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
                      _formatTimestamp(notiz.timestamp),
                      style: TextStyle(
                        color: Colors.purple.shade200,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Trust Level Stars
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < notiz.trustLevel ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Category Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.purple.shade700,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              notiz.category,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Titel
          Text(
            notiz.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Inhalt
          Text(
            notiz.content,
            style: TextStyle(
              color: Colors.purple.shade100,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),

          // Tags
          if (notiz.tags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: notiz.tags.split(',').map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade800,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.purple.shade300),
                  ),
                  child: Text(
                    '#${tag.trim()}',
                    style: TextStyle(
                      color: Colors.purple.shade200,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Source URL
          if (notiz.sourceUrl.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.link,
                  color: Colors.purple.shade200,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notiz.sourceUrl,
                    style: TextStyle(
                      color: Colors.purple.shade200,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
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

// Notiz Model
class Notiz {
  final String id;
  final String title;
  final String content;
  final String sourceUrl;
  final String tags;
  final String category;
  final int trustLevel;  final DateTime timestamp;

  Notiz({
    required this.id,
    required this.title,
    required this.content,
    required this.sourceUrl,
    required this.tags,
    required this.category,
    required this.trustLevel,
    required this.timestamp,
  });

  factory Notiz.fromJson(Map<String, dynamic> json) {
    return Notiz(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      sourceUrl: json['source_url']?.toString() ?? '',
      tags: json['tags']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Allgemein',
      trustLevel: json['trust_level'] as int? ?? 3,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
