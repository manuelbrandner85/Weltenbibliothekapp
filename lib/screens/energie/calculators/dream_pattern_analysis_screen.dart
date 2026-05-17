// 💭 TRAUMDEUTUNG · KI-MUSTERANALYSE
//
// Liest die letzten 30 Traum-Einträge aus dream_journal_v2 und sendet
// eine kompakte Symbol-Summary an den Mentor-Worker. KI analysiert
// wiederkehrende Symbole, Emotionen, Themen-Cluster.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/api_config.dart';

class DreamPatternAnalysisScreen extends StatefulWidget {
  const DreamPatternAnalysisScreen({super.key});

  @override
  State<DreamPatternAnalysisScreen> createState() =>
      _DreamPatternAnalysisScreenState();
}

class _DreamPatternAnalysisScreenState
    extends State<DreamPatternAnalysisScreen> {
  static const _bg = Color(0xFF06040F);
  static const _surface = Color(0xFF1A1530);
  static const _accent = Color(0xFF1A237E);
  static const _accentLight = Color(0xFF7986CB);

  final _supa = Supabase.instance.client;

  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;
  String? _analysis;
  bool _analyzing = false;
  String? _error;

  // Lokale Auswertung
  Map<String, int> _symbolFreq = {};
  Map<String, int> _categoryFreq = {};
  int _lucidCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _supa.auth.currentUser?.id;
    if (uid == null) {
      setState(() {
        _loading = false;
        _error = 'Bitte zuerst einloggen.';
      });
      return;
    }
    try {
      final data = await _supa
          .from('dream_journal_v2')
          .select()
          .eq('user_id', uid)
          .order('dream_date', ascending: false)
          .limit(60);
      if (!mounted) return;
      final list = List<Map<String, dynamic>>.from(data);
      _computeLocal(list);
      setState(() {
        _entries = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Konnte Traum-Einträge nicht laden: $e';
      });
    }
  }

  void _computeLocal(List<Map<String, dynamic>> list) {
    final symbolFreq = <String, int>{};
    final catFreq = <String, int>{};
    var lucid = 0;
    for (final e in list) {
      final symbols = (e['symbols'] as List?)?.cast<String>() ?? const [];
      for (final s in symbols) {
        symbolFreq[s] = (symbolFreq[s] ?? 0) + 1;
      }
      final cat = e['category'] as String?;
      if (cat != null) catFreq[cat] = (catFreq[cat] ?? 0) + 1;
      if (e['is_lucid'] == true) lucid++;
    }
    _symbolFreq = symbolFreq;
    _categoryFreq = catFreq;
    _lucidCount = lucid;
  }

  Future<void> _runAIAnalysis() async {
    if (_entries.isEmpty) return;
    setState(() {
      _analyzing = true;
      _analysis = null;
    });

    // Kompakte Zusammenfassung erstellen (kein voller Inhalt — DSGVO + Token-Sparsamkeit).
    final topSymbols = _symbolFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCats = _categoryFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final summary = StringBuffer()
      ..writeln('Anzahl Träume: ${_entries.length}')
      ..writeln('Davon Klarträume: $_lucidCount')
      ..writeln('Häufigste Symbole: ${topSymbols.take(15).map((e) => '${e.key} (${e.value}x)').join(', ')}')
      ..writeln('Kategorien: ${topCats.map((e) => '${e.key} (${e.value}x)').join(', ')}');

    final message = 'Bitte analysiere folgende Traum-Statistik der letzten Wochen und erkenne '
        'wiederkehrende Themen, Symbol-Cluster, emotionale Muster und mögliche '
        'Botschaften des Unbewussten. Strukturiere die Antwort: 1) Dominante Themen, '
        '2) Symbol-Cluster mit Deutung, 3) Empfehlung für die nächste Woche.\n\n'
        '${summary.toString()}';

    try {
      final token = _supa.auth.currentSession?.accessToken ?? '';
      final userId = _supa.auth.currentUser?.id ?? '';
      final res = await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/mentor/chat'),
            headers: {
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'personality': 'heiler',
              'message': message,
              'conversationHistory': [],
              'world': 'energie',
              'userId': userId,
              'systemPrompt':
                  'Du bist ein erfahrener Traum-Deuter im Stil von C.G. Jung. '
                      'Analysiere die gegebene Traum-Statistik systematisch: erkenne '
                      'wiederkehrende Archetypen, Schatten-Muster, kompensatorische '
                      'Themen. Sei konkret, aber vorsichtig — Traumdeutung ist '
                      'Selbstforschung, nicht Diagnose.',
              'mentorDisplayName': 'Traum-Deuter',
              'mentorAvatarEmoji': '💭',
            }),
          )
          .timeout(const Duration(seconds: 60));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final reply = (data['response'] as String?) ??
            (data['message'] as String?) ??
            (data['reply'] as String?) ??
            'Antwort vorerst nicht verfügbar.';
        setState(() => _analysis = reply);
      } else {
        setState(() => _error = 'Worker-Fehler ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Netzwerk-Fehler: $e');
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _accent,
        title: const Row(children: [
          Text('💭', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Text('Traum-Muster',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accentLight))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white70)))
              : _entries.isEmpty
                  ? _buildEmpty()
                  : _buildContent(),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('💭', style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text('Noch keine Traum-Einträge',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(
            'Trage erst einige Träume im Traumdeutung-Tool ein, dann kommt die KI-Musteranalyse.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
        ]),
      ),
    );
  }

  Widget _buildContent() {
    final topSymbols = _symbolFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_accent, _accent.withValues(alpha: 0.4)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📊 STATISTIK',
                  style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${_entries.length} Träume · $_lucidCount Klarträume',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${_symbolFreq.length} verschiedene Symbole · ${_categoryFreq.length} Kategorien',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text('TOP-SYMBOLE',
            style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final s in topSymbols.take(20))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _accentLight.withValues(alpha: 0.4)),
              ),
              child: Text('${s.key} · ${s.value}',
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
        ]),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _analyzing ? null : _runAIAnalysis,
            icon: _analyzing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome),
            label: Text(_analyzing ? 'KI denkt nach…' : 'KI-MUSTERANALYSE STARTEN',
                style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentLight,
              foregroundColor: _bg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        if (_analysis != null) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accentLight.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.auto_awesome, color: _accentLight),
                  const SizedBox(width: 8),
                  const Text('JUNGIANISCHE ANALYSE',
                      style: TextStyle(color: _accentLight, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 10),
                SelectableText(_analysis!,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.6)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
