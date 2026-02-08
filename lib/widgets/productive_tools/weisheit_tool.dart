import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/cloudflare_api_service.dart';

/// 📿 WEISHEITS-BIBLIOTHEK - Zitate & Lehren sammeln
class WeisheitTool extends StatefulWidget {
  final String roomId;  const WeisheitTool({super.key, required this.roomId});

  @override
  State<WeisheitTool> createState() => _WeisheitToolState();
}

class _WeisheitToolState extends State<WeisheitTool> {
  static const String _baseUrl = 'https://weltenbibliothek-community-api.brandy13062.workers.dev';
  // UNUSED FIELD: final CloudflareApiService _api = CloudflareApiService();
  // UNUSED FIELD: final ChatToolsService _toolsService = ChatToolsService();
  List<Weisheit> _weisheiten = [];
  bool _isLoading = false;
  Timer? _refreshTimer;

  final TextEditingController _quoteController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _teachingController = TextEditingController(); // 🆕 Ausführliche Lehre
  final TextEditingController _contextController = TextEditingController(); // 📖 Historischer Kontext
  String _selectedCategory = 'Allgemein';

  final List<String> _categories = [
    'Allgemein',
    'Buddhismus',
    'Taoismus',
    'Yoga',
    'Meditation',
    'Erleuchtung',
    'Karma',
    'Achtsamkeit',
    'Nondualität',
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
    _quoteController.dispose();
    _authorController.dispose();
    _commentController.dispose();
    _teachingController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    try {
      setState(() => _isLoading = true);
      final response = await http.get(
        Uri.parse('$_baseUrl/api/tools/weisheit?room_id=${widget.roomId}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['wisdom'] != null) {
          setState(() {
            _weisheiten = (data['wisdom'] as List).map((w) => Weisheit.fromJson(w)).toList();
            _weisheiten.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          });
        }
      }
    } catch (e) {
      debugPrint('Fehler: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitWeisheit() async {
    if (_quoteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Zitat eingeben'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      // 🔧 AUTO-FIX: Username-Variable für Chat-Integration
      final generatedUsername = 'Sammler${DateTime.now().millisecondsSinceEpoch % 1000}';
      final response = await http.post(
        Uri.parse('$_baseUrl/api/tools/weisheit'),
        body: json.encode({
          'room_id': widget.roomId,
          'quote': _quoteController.text.trim(),
          'author': _authorController.text.trim(),
          'comment': _commentController.text.trim(),
          'teaching': _teachingController.text.trim(), // 🆕 Ausführliche Lehre
          'context': _contextController.text.trim(), // 📖 Kontext
          'category': _selectedCategory,
          'username': generatedUsername,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Chat-Aktivität posten (VOR dem Clearen!)
        final quotePreview = _quoteController.text.trim().length > 50 
            ? '${_quoteController.text.trim().substring(0, 50)}...' 
            : _quoteController.text.trim();
        final author = _authorController.text.trim();
        
        try {
          final api = CloudflareApiService();
          await api.sendToolActivityMessage(
            roomId: widget.roomId,
            realm: 'energie',
            toolName: 'Weisheits-Zitat',
            username: generatedUsername, // 🔧 FIX: Username übergeben
            activity: 'Weisheit geteilt: "$quotePreview" - $author',
          );
        } catch (e) {
          debugPrint('Chat-Aktivität fehlgeschlagen: $e');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weisheit hinzugefügt!'), backgroundColor: Colors.green),
        );
        _quoteController.clear();
        _authorController.clear();
        _commentController.clear();
        _teachingController.clear();
        _contextController.clear();
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
    final uniqueCollectors = _weisheiten.length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepOrange.shade900, Colors.orange.shade800],
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
                const Text('📿 WEISHEITS-BIBLIOTHEK', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard('$uniqueCollectors', 'Sammler', Icons.person),
                    _buildStatCard('${_weisheiten.length}', 'Weisheiten', Icons.auto_stories),
                    _buildStatCard('${_categories.length}', 'Kategorien', Icons.category),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [_buildInputForm(), const SizedBox(height: 24), _buildWeisheitList()]),
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
        border: Border.all(color: Colors.deepOrange.shade300, width: 2),
      ),
      child: Column(children: [
        Icon(icon, color: Colors.deepOrange.shade200, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.deepOrange.shade200)),
      ]),
    );
  }

  Widget _buildInputForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepOrange.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('➕ Neue Weisheit hinzufügen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          TextField(
            controller: _quoteController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Zitat / Weisheit',
              hintText: 'Der Weg ist das Ziel...',
              labelStyle: TextStyle(color: Colors.deepOrange.shade200),
              prefixIcon: const Icon(Icons.format_quote, color: Colors.deepOrange),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _authorController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Autor / Quelle',
              hintText: 'Buddha, Lao Tzu...',
              labelStyle: TextStyle(color: Colors.deepOrange.shade200),
              prefixIcon: const Icon(Icons.person, color: Colors.deepOrange),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            dropdownColor: Colors.deepOrange.shade900,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Kategorie',
              labelStyle: TextStyle(color: Colors.deepOrange.shade200),
              prefixIcon: const Icon(Icons.category, color: Colors.deepOrange),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedCategory = v);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 2,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Dein Kommentar (optional)',
              hintText: 'Was bedeutet das für dich?',
              labelStyle: TextStyle(color: Colors.deepOrange.shade200),
              prefixIcon: const Icon(Icons.comment, color: Colors.deepOrange),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          // 🆕 Ausführliche Lehre (Langform)
          TextField(
            controller: _teachingController,
            maxLines: 8,
            minLines: 5,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: '📖 Ausführliche Lehre / Erklärung',
              hintText: 'Erkläre die tiefere Bedeutung dieser Weisheit...\n\nBeschreibe die spirituelle Praxis, Philosophie und praktische Anwendung ausführlich.\n\nMinimum 200 Zeichen für tiefgründige Lehren.',
              labelStyle: TextStyle(color: Colors.deepOrange.shade200),
              prefixIcon: const Icon(Icons.menu_book, color: Colors.deepOrange),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              helperText: '💡 Tipp: Ausführliche spirituelle Lehren mit praktischen Beispielen',
              helperStyle: TextStyle(color: Colors.deepOrange.shade200),
            ),
          ),
          const SizedBox(height: 12),
          // 🆕 Historischer Kontext
          TextField(
            controller: _contextController,
            maxLines: 5,
            minLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: '🏛️ Historischer Kontext / Hintergrund',
              hintText: 'Historische Quelle, kultureller Hintergrund, Entstehungsgeschichte...\n\nWoher stammt diese Weisheit? In welchem Kontext wurde sie gelehrt?',
              labelStyle: TextStyle(color: Colors.deepOrange.shade200),
              prefixIcon: const Icon(Icons.history_edu, color: Colors.deepOrange),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              helperText: '📚 Historische Quelle und kultureller Hintergrund',
              helperStyle: TextStyle(color: Colors.deepOrange.shade200),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitWeisheit,
              icon: const Icon(Icons.add),
              label: const Text('WEISHEIT HINZUFÜGEN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeisheitList() {
    if (_weisheiten.isEmpty) {
      return Center(child: Column(children: [
        const SizedBox(height: 40),
        Icon(Icons.auto_stories_outlined, size: 64, color: Colors.deepOrange.shade200),
        const SizedBox(height: 16),
        Text('Noch keine Weisheiten', style: TextStyle(color: Colors.deepOrange.shade200, fontSize: 18)),
      ]));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🕉️ GESAMMELTE WEISHEITEN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        ..._weisheiten.map((w) => _buildWeisheitCard(w)),
      ],
    );
  }

  Widget _buildWeisheitCard(Weisheit weisheit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepOrange.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.deepOrange.shade700, borderRadius: BorderRadius.circular(20)),
              child: Text(weisheit.category, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const Spacer(),
            Text("Nutzer", style: TextStyle(color: Colors.deepOrange.shade200, fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          const Icon(Icons.format_quote, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(weisheit.quote, style: const TextStyle(color: Colors.white, fontSize: 16, fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.person, size: 16, color: Colors.white70),
            const SizedBox(width: 8),
            Text(weisheit.author, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          ]),
          if (weisheit.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.comment, size: 16, color: Colors.deepOrange.shade200),
                      const SizedBox(width: 8),
                      Text('Kommentar:', style: TextStyle(color: Colors.deepOrange.shade200, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(weisheit.comment, style: TextStyle(color: Colors.deepOrange.shade100)),
                ],
              ),
            ),
          ],
          // 🆕 Ausführliche Lehre anzeigen
          if (weisheit.teaching.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepOrange.shade800.withValues(alpha: 0.3), Colors.orange.shade700.withValues(alpha: 0.3)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepOrange.shade400, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.menu_book, size: 20, color: Colors.deepOrange.shade200),
                      const SizedBox(width: 8),
                      Text('📖 AUSFÜHRLICHE LEHRE', style: TextStyle(color: Colors.deepOrange.shade200, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const Divider(color: Colors.deepOrange, height: 20),
                  Text(
                    weisheit.teaching, 
                    style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6),
                  ),
                ],
              ),
            ),
          ],
          // 🆕 Historischer Kontext anzeigen
          if (weisheit.context.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.brown.shade800.withValues(alpha: 0.3), Colors.brown.shade700.withValues(alpha: 0.3)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.brown.shade400, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history_edu, size: 20, color: Colors.brown.shade200),
                      const SizedBox(width: 8),
                      Text('🏛️ HISTORISCHER KONTEXT', style: TextStyle(color: Colors.brown.shade200, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const Divider(color: Colors.brown, height: 20),
                  Text(
                    weisheit.context, 
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class Weisheit {
  final String id, quote, author, comment, category;
  final String teaching; // 🆕 Ausführliche Lehre
  final String context; // 🆕 Historischer Kontext
  final DateTime timestamp;


  Weisheit({
    required this.id,
    required this.quote,
    required this.author,
    required this.comment,
    required this.category,
    required this.teaching,
    required this.context,
    required this.timestamp,
  });

  factory Weisheit.fromJson(Map<String, dynamic> json) {
    return Weisheit(
      id: json['id']?.toString() ?? '',
      quote: json['quote']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Allgemein',
      teaching: json['teaching']?.toString() ?? '',
      context: json['context']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
