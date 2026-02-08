import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/cloudflare_api_service.dart';

/// 🌙 TRAUM-ANALYSE V2 - Mit Symbol-Chips, Emotionen, Traum-Typ
class TraumanalyseTool extends StatefulWidget {
  final String roomId;
  const TraumanalyseTool({super.key, required this.roomId});

  @override
  State<TraumanalyseTool> createState() => _TraumanalyseToolState();
}

class _TraumanalyseToolState extends State<TraumanalyseTool> {
  static const String _baseUrl = 'https://weltenbibliothek-community-api.brandy13062.workers.dev';
  // UNUSED FIELD: final CloudflareApiService _api = CloudflareApiService();
  // UNUSED FIELD: final ChatToolsService _toolsService = ChatToolsService();
  List<Traum> _traume = [];
  bool _isLoading = false;
  Timer? _refreshTimer;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _interpretationController = TextEditingController();
  
  bool _isLucid = false;
  String _selectedTraumTyp = 'Normal';
  String _selectedEmotion = 'Neutral';
  int _selectedKlarheit = 5;
  
  // ✨ ERWEITERT: Symbol-Chips (Multiselect)
  final Set<String> _selectedSymbols = {};
  final List<String> _symbolOptions = [
    'Wasser', 'Feuer', 'Fliegen', 'Fallen', 'Verfolgung',
    'Tiere', 'Menschen', 'Licht', 'Dunkelheit', 'Natur',
    'Gebäude', 'Reisen', 'Tod', 'Geburt', 'Transformation',
    'Musik', 'Farben', 'Zahlen', 'Symbole', 'Werkzeuge',
  ];

  final List<String> _traumTypen = [
    'Normal',
    'Luzid',
    'Albtraum',
    'Wach-Traum',
    'Prophetisch',
    'Klartraum',
    'Wiederkehrend',
  ];

  final List<String> _emotionen = [
    'Neutral',
    'Freude',
    'Angst',
    'Trauer',
    'Wut',
    'Liebe',
    'Neugier',
    'Verwirrung',
    'Frieden',
    'Aufregung',
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
    _titleController.dispose();
    _contentController.dispose();
    _interpretationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    try {
      setState(() => _isLoading = true);
      final response = await http.get(
        Uri.parse('$_baseUrl/api/tools/traum?room_id=${widget.roomId}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['dreams'] != null) {
          setState(() {
            _traume = (data['dreams'] as List).map((t) => Traum.fromJson(t)).toList();
            _traume.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          });
        }
      }
    } catch (e) {
      debugPrint('Fehler: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitTraum() async {
    if (_titleController.text.trim().isEmpty) {
      _showToast('Bitte Titel eingeben', Colors.orange);
      return;
    }
    if (_contentController.text.trim().isEmpty) {
      _showToast('Bitte Traum beschreiben', Colors.orange);
      return;
    }

    try {
      // 🔧 AUTO-FIX: Username-Variable für Chat-Integration
      final generatedUsername = 'Träumer${DateTime.now().millisecondsSinceEpoch % 1000}';
      final response = await http.post(
        Uri.parse('$_baseUrl/api/tools/traum'),
        body: json.encode({
          'room_id': widget.roomId,
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'symbols': _selectedSymbols.join(','),
          'interpretation': _interpretationController.text.trim(),
          'is_lucid': _isLucid,
          'traum_typ': _selectedTraumTyp,
          'emotion': _selectedEmotion,
          'klarheit': _selectedKlarheit,
          'username': generatedUsername,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showToast('Traum gespeichert!', Colors.green);
        _clearForm();
        await _loadData();
        
        // Chat-Aktivität posten
        try {
          final api = CloudflareApiService();
          await api.sendToolActivityMessage(
            roomId: widget.roomId,
            realm: 'energie',
            toolName: 'Traumanalyse',
            username: generatedUsername, // 🔧 FIX: Username übergeben
            activity: 'Traum dokumentiert: ${_titleController.text.trim()} ($_selectedTraumTyp)',
          );
        } catch (e) {
          debugPrint('Chat-Aktivität fehlgeschlagen: $e');
        }
      }
    } catch (e) {
      _showToast('Fehler: $e', Colors.red);
    }
  }

  void _clearForm() {
    _titleController.clear();
    _contentController.clear();
    _interpretationController.clear();
    setState(() {
      _isLucid = false;
      _selectedSymbols.clear();
      _selectedTraumTyp = 'Normal';
      _selectedEmotion = 'Neutral';
      _selectedKlarheit = 5;
    });
  }

  void _showToast(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uniqueDreamers = _traume.length;
    final lucidCount = _traume.where((t) => t.isLucid).length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepPurple.shade900, Colors.purple.shade800],
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
                const Text('🌙 TRAUM-ANALYSE', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard('$uniqueDreamers', 'Träumer', Icons.bedtime),
                    _buildStatCard('${_traume.length}', 'Träume', Icons.nights_stay),
                    _buildStatCard('$lucidCount', 'Luzide', Icons.lightbulb),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [_buildInputForm(), const SizedBox(height: 24), _buildTraumList()]),
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
        border: Border.all(color: Colors.deepPurple.shade300, width: 2),
      ),
      child: Column(children: [
        Icon(icon, color: Colors.deepPurple.shade200, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.deepPurple.shade200)),
      ]),
    );
  }

  Widget _buildInputForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('➕ Neuen Traum hinzufügen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Titel',
              hintText: 'z.B. Flug durch die Sterne',
              labelStyle: TextStyle(color: Colors.deepPurple.shade200),
              prefixIcon: const Icon(Icons.title, color: Colors.deepPurple),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          // ✨ ERWEITERT: Traum-Typ Dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedTraumTyp,
            dropdownColor: Colors.deepPurple.shade900,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Traum-Typ',
              labelStyle: TextStyle(color: Colors.deepPurple.shade200),
              prefixIcon: const Icon(Icons.category, color: Colors.deepPurple),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _traumTypen.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedTraumTyp = v);
            },
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _contentController,
            maxLines: 5,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Traum-Beschreibung',
              hintText: 'Beschreibe deinen Traum im Detail...',
              labelStyle: TextStyle(color: Colors.deepPurple.shade200),
              prefixIcon: const Icon(Icons.description, color: Colors.deepPurple),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          // ✨ ERWEITERT: Symbol-Chips (Multiselect)
          const Text('Symbole wählen:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _symbolOptions.map((symbol) {
              final isSelected = _selectedSymbols.contains(symbol);
              return FilterChip(
                label: Text(symbol),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSymbols.add(symbol);
                    } else {
                      _selectedSymbols.remove(symbol);
                    }
                  });
                },
                backgroundColor: Colors.black.withValues(alpha: 0.3),
                selectedColor: Colors.purple.shade700,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.purple.shade200,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // ✨ ERWEITERT: Emotion Dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedEmotion,
            dropdownColor: Colors.deepPurple.shade900,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Hauptemotion',
              labelStyle: TextStyle(color: Colors.deepPurple.shade200),
              prefixIcon: const Icon(Icons.mood, color: Colors.deepPurple),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _emotionen.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedEmotion = v);
            },
          ),
          const SizedBox(height: 12),

          // ✨ ERWEITERT: Klarheit Slider
          Row(
            children: [
              Text('Klarheit: ', style: TextStyle(color: Colors.deepPurple.shade200, fontWeight: FontWeight.bold)),
              Expanded(
                child: Slider(
                  value: _selectedKlarheit.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: Colors.deepPurple,
                  label: '$_selectedKlarheit/10',
                  onChanged: (v) => setState(() => _selectedKlarheit = v.toInt()),
                ),
              ),
              Text('$_selectedKlarheit/10', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),

          TextField(
            controller: _interpretationController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Interpretation (optional)',
              hintText: 'Deine Deutung des Traums...',
              labelStyle: TextStyle(color: Colors.deepPurple.shade200),
              prefixIcon: const Icon(Icons.lightbulb, color: Colors.deepPurple),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          Row(children: [
            Checkbox(
              value: _isLucid,
              activeColor: Colors.deepPurple,
              onChanged: (v) => setState(() => _isLucid = v ?? false),
            ),
            Text('Luzider Traum?', style: TextStyle(color: Colors.deepPurple.shade200, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitTraum,
              icon: const Icon(Icons.add),
              label: const Text('TRAUM HINZUFÜGEN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraumList() {
    if (_traume.isEmpty) {
      return Center(child: Column(children: [
        const SizedBox(height: 40),
        Icon(Icons.nights_stay_outlined, size: 64, color: Colors.deepPurple.shade200),
        const SizedBox(height: 16),
        Text('Noch keine Träume', style: TextStyle(color: Colors.deepPurple.shade200, fontSize: 18)),
      ]));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('💭 TRAUM-TAGEBUCH', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        ..._traume.map((t) => _buildTraumCard(t)),
      ],
    );
  }

  Widget _buildTraumCard(Traum traum) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: traum.isLucid ? Colors.amber : Colors.deepPurple.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
              child: Center(child: Text("Nutzer"[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Nutzer", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('vor ${_formatTime(traum.timestamp)}', style: TextStyle(color: Colors.deepPurple.shade200, fontSize: 12)),
              ],
            )),
            if (traum.isLucid) Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(20)),
              child: const Text('✨ LUZID', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.purple.shade800, borderRadius: BorderRadius.circular(12)),
                child: Text(traum.traumTyp, style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
              const SizedBox(width: 8),
              Icon(Icons.mood, size: 14, color: Colors.purple.shade200),
              const SizedBox(width: 4),
              Text(traum.emotion, style: TextStyle(color: Colors.purple.shade200, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          
          Text(traum.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(traum.content, style: TextStyle(color: Colors.deepPurple.shade100)),
          
          if (traum.symbols.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: traum.symbols.split(',').map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.purple.shade800, borderRadius: BorderRadius.circular(16)),
                child: Text('#${s.trim()}', style: TextStyle(color: Colors.purple.shade200, fontSize: 12)),
              )).toList(),
            ),
          ],
          
          if (traum.interpretation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [Icon(Icons.lightbulb, size: 16, color: Colors.amber), const SizedBox(width: 8), Text('Interpretation:', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 4),
                  Text(traum.interpretation, style: TextStyle(color: Colors.deepPurple.shade100)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class Traum {
  final String id, title, content, symbols, interpretation;
  final String traumTyp, emotion;
  final bool isLucid;
  final DateTime timestamp;

  Traum({
    required this.id,
    required this.title,
    required this.content,
    required this.symbols,
    required this.interpretation,
    required this.isLucid,
    required this.traumTyp,
    required this.emotion,
    required this.timestamp,
  });

  factory Traum.fromJson(Map<String, dynamic> json) {
    return Traum(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      symbols: json['symbols']?.toString() ?? '',
      interpretation: json['interpretation']?.toString() ?? '',
      isLucid: json['is_lucid'] as bool? ?? false,
      traumTyp: json['traum_typ']?.toString() ?? 'Normal',
      emotion: json['emotion']?.toString() ?? 'Neutral',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
