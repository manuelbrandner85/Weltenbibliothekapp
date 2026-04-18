import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BodyScanToolScreen – 3 Tabs
//   Tab 0: Scan    (Symptome wählen → Chakra-Score berechnen)
//   Tab 1: Verlauf (vergangene Scans aus body_scan_results)
//   Tab 2: Info    (statisches Chakra-Lexikon)
// ─────────────────────────────────────────────────────────────────────────────

const _kPink = Color(0xFFE91E63);
const _kDarkBg = Color(0xFF0A0A0F);
const _kCardBg = Color(0xFF1A1A2E);
const _kBorder = Color(0xFF2A2A4E);

final _db = Supabase.instance.client;

const _categories = [
  ('alle', 'Alle'),
  ('körperlich', '🫀 Körper'),
  ('emotional', '💗 Gefühle'),
  ('mental', '🧠 Gedanken'),
  ('spirituell', '✨ Spirit'),
];

class BodyScanToolScreen extends StatefulWidget {
  const BodyScanToolScreen({super.key});

  @override
  State<BodyScanToolScreen> createState() => _BodyScanToolScreenState();
}

class _BodyScanToolScreenState extends State<BodyScanToolScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDarkBg,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        title: const Text('🧘 Körperscan',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _kPink,
          labelColor: _kPink,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.sensors), text: 'Scan'),
            Tab(icon: Icon(Icons.history), text: 'Verlauf'),
            Tab(icon: Icon(Icons.info_outline), text: 'Chakren'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _ScanTab(),
          _HistoryTab(),
          _InfoTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 0: Scan  (Phase 7.2b/c/d füllen diesen Stub)
// ─────────────────────────────────────────────────────────────────────────────

class _ScanTab extends StatefulWidget {
  const _ScanTab();
  @override
  State<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<_ScanTab> {
  List<Map<String, dynamic>> _symptoms = [];
  final Set<String> _selected = {};
  String _filterCategory = 'alle';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await _db
          .from('chakra_symptoms')
          .select()
          .order('chakra_number')
          .order('sort_order');
      if (!mounted) return;
      setState(() {
        _symptoms = List<Map<String, dynamic>>.from(rows);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_symptoms.isEmpty) {
      return const Center(
          child: Text('Keine Symptome geladen',
              style: TextStyle(color: Colors.white54)));
    }

    // Filter nach Kategorie
    final filtered = _filterCategory == 'alle'
        ? _symptoms
        : _symptoms
            .where((s) => s['symptom_category'] == _filterCategory)
            .toList();

    // Gruppieren nach Chakra
    final byChakra = <int, List<Map<String, dynamic>>>{};
    for (final s in filtered) {
      final n = s['chakra_number'] as int;
      byChakra.putIfAbsent(n, () => []).add(s);
    }
    final chakraKeys = byChakra.keys.toList()..sort();

    return Stack(
      children: [
        Column(
      children: [
        // Filter-Chips
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final sel = _filterCategory == cat.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat.$2,
                      style: TextStyle(
                          color: sel ? Colors.white : Colors.white54,
                          fontSize: 12)),
                  selected: sel,
                  selectedColor: _kPink,
                  backgroundColor: _kCardBg,
                  side: const BorderSide(color: _kBorder),
                  onSelected: (_) =>
                      setState(() => _filterCategory = cat.$1),
                ),
              );
            },
          ),
        ),
        // Selected-Counter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text('${_selected.length} Symptom(e) ausgewählt',
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 12)),
              const Spacer(),
              if (_selected.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _selected.clear()),
                  child: const Text('Zurücksetzen',
                      style: TextStyle(color: _kPink, fontSize: 12)),
                ),
            ],
          ),
        ),
        // Symptom-Liste
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
            itemCount: chakraKeys.length,
            itemBuilder: (_, i) {
              final chakra = chakraKeys[i];
              final items = byChakra[chakra]!;
              final first = items.first;
              return Card(
                color: _kCardBg,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: _parseColor(first['chakra_color'] as String?)
                          .withValues(alpha: 0.3)),
                ),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    iconColor: Colors.white54,
                    collapsedIconColor: Colors.white54,
                    title: Row(children: [
                      Text(first['chakra_emoji'] as String? ?? '',
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(first['chakra_name'] as String? ?? '',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                      Text('${items.length}',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12)),
                    ]),
                    children: items.map((s) {
                      final id = s['id'] as String;
                      final sel = _selected.contains(id);
                      return CheckboxListTile(
                        dense: true,
                        value: sel,
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _selected.add(id);
                          } else {
                            _selected.remove(id);
                          }
                        }),
                        activeColor: _kPink,
                        checkColor: Colors.white,
                        title: Text(s['symptom_text'] as String,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        subtitle: Text(s['symptom_category'] as String,
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 10)),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
        ),
        // Auswerten-Button (unten pinned)
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selected.isEmpty ? null : _showResult,
              icon: const Icon(Icons.auto_graph),
              label: Text(_selected.isEmpty
                  ? 'Symptome auswählen'
                  : 'Auswerten (${_selected.length})'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kPink,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _kBorder,
                  disabledForegroundColor: Colors.white38,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ),
      ],
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null) return Colors.white;
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  // ────── Phase 7.2c: Score-Berechnung + Ergebnis ──────
  Map<int, int> _computeScores() {
    final scores = <int, int>{};
    for (final s in _symptoms) {
      if (!_selected.contains(s['id'])) continue;
      final n = s['chakra_number'] as int;
      final w = s['weight'] as int? ?? 2;
      scores[n] = (scores[n] ?? 0) + w;
    }
    return scores;
  }

  int? _primaryBlocked(Map<int, int> scores) {
    if (scores.isEmpty) return null;
    return scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  List<Map<String, dynamic>> _chakraInfoRows() {
    final seen = <int>{};
    final out = <Map<String, dynamic>>[];
    for (final s in _symptoms) {
      final n = s['chakra_number'] as int;
      if (seen.add(n)) {
        out.add({
          'chakra_number': n,
          'chakra_name': s['chakra_name'],
          'chakra_color': s['chakra_color'],
          'chakra_emoji': s['chakra_emoji'],
        });
      }
    }
    out.sort((a, b) =>
        (a['chakra_number'] as int).compareTo(b['chakra_number'] as int));
    return out;
  }

  Future<void> _saveScan({
    required Map<int, int> scores,
    required int? primary,
    required String notes,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) {
      throw Exception('Nicht angemeldet');
    }
    // chakra_scores JSONB erwartet String-Keys
    final jsonScores = <String, int>{
      for (final e in scores.entries) e.key.toString(): e.value,
    };
    await _db.from('body_scan_results').insert({
      'user_id': user.id,
      'selected_symptom_ids': _selected.toList(),
      'chakra_scores': jsonScores,
      'primary_blocked_chakra': primary,
      'notes': notes.trim().isEmpty ? null : notes.trim(),
    });
  }

  void _showResult() {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bitte mindestens ein Symptom auswählen')));
      return;
    }
    final scores = _computeScores();
    final primary = _primaryBlocked(scores);
    final maxScore =
        scores.values.isEmpty ? 1 : scores.values.reduce((a, b) => a > b ? a : b);

    final notesCtrl = TextEditingController();
    bool saving = false;
    bool saved = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx2, setSheet) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, sc) => ListView(
          controller: sc,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('🔮 Dein Scan-Ergebnis',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Basierend auf ${_selected.length} Symptom(en)',
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 20),
            if (primary != null) ...[
              _PrimaryChakraCard(
                chakra: _chakraInfoRows()
                    .firstWhere((c) => c['chakra_number'] == primary),
                score: scores[primary]!,
              ),
              const SizedBox(height: 20),
            ],
            const Text('Alle Chakren-Scores',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._chakraInfoRows().map((c) {
              final n = c['chakra_number'] as int;
              final score = scores[n] ?? 0;
              final pct = maxScore > 0 ? score / maxScore : 0.0;
              final color = _parseColor(c['chakra_color'] as String?);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(c['chakra_emoji'] as String? ?? '',
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(c['chakra_name'] as String? ?? '',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ),
                      Text(score > 0 ? '$score' : '–',
                          style: TextStyle(
                              color: score > 0 ? color : Colors.white38,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ]),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: _kBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            // Freitext-Notiz
            TextField(
              controller: notesCtrl,
              enabled: !saving && !saved,
              maxLines: 3,
              minLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Optionale Notiz zu diesem Scan …',
                hintStyle:
                    const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: _kDarkBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kPink),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (saving || saved)
                    ? null
                    : () async {
                        setSheet(() => saving = true);
                        try {
                          await _saveScan(
                            scores: scores,
                            primary: primary,
                            notes: notesCtrl.text,
                          );
                          if (!sheetCtx2.mounted) return;
                          setSheet(() {
                            saving = false;
                            saved = true;
                          });
                          ScaffoldMessenger.of(sheetCtx2).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('✅ Scan gespeichert')));
                        } catch (e) {
                          if (!sheetCtx2.mounted) return;
                          setSheet(() => saving = false);
                          ScaffoldMessenger.of(sheetCtx2).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Fehler beim Speichern: $e')));
                        }
                      },
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(saved ? Icons.check_circle : Icons.save),
                label: Text(saving
                    ? 'Speichern …'
                    : (saved ? 'Gespeichert' : 'Scan speichern')),
                style: ElevatedButton.styleFrom(
                    backgroundColor: saved ? Colors.green : _kPink,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        saved ? Colors.green : _kBorder,
                    disabledForegroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],
        ),
      ),
      ),
    ).whenComplete(() {
      notesCtrl.dispose();
      if (saved && mounted) {
        setState(() => _selected.clear());
      }
    });
  }
}

class _PrimaryChakraCard extends StatelessWidget {
  final Map<String, dynamic> chakra;
  final int score;
  const _PrimaryChakraCard({required this.chakra, required this.score});

  @override
  Widget build(BuildContext context) {
    final cleaned =
        (chakra['chakra_color'] as String? ?? '#E91E63').replaceAll('#', '');
    final color = Color(int.parse('FF$cleaned', radix: 16));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.3), _kCardBg],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Text(chakra['chakra_emoji'] as String? ?? '',
              style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hauptblockade',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 2),
                Text(chakra['chakra_name'] as String? ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Score: $score',
                    style: TextStyle(color: color, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Verlauf (Phase 7.2e füllt diesen Stub)
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryTab extends StatefulWidget {
  const _HistoryTab();
  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  List<Map<String, dynamic>> _rows = [];
  Map<int, Map<String, dynamic>> _chakraMeta = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = _db.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Bitte zuerst anmelden';
        });
        return;
      }
      // Chakra-Meta aus chakra_symptoms aggregieren (für Emoji/Farbe)
      final metaRows = await _db
          .from('chakra_symptoms')
          .select('chakra_number, chakra_name, chakra_color, chakra_emoji');
      final meta = <int, Map<String, dynamic>>{};
      for (final m in metaRows) {
        final n = m['chakra_number'] as int;
        meta.putIfAbsent(n, () => Map<String, dynamic>.from(m));
      }
      final rows = await _db
          .from('body_scan_results')
          .select()
          .eq('user_id', user.id)
          .order('scanned_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _chakraMeta = meta;
        _rows = List<Map<String, dynamic>>.from(rows);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _deleteScan(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCardBg,
        title: const Text('Scan löschen?',
            style: TextStyle(color: Colors.white)),
        content: const Text('Dieser Scan wird unwiderruflich gelöscht.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen',
                  style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Löschen',
                  style: TextStyle(color: _kPink))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _db.from('body_scan_results').delete().eq('id', id);
      if (!mounted) return;
      setState(() => _rows.removeWhere((r) => r['id'] == id));
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scan gelöscht')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')));
    }
  }

  Color _parseColor(String? hex) {
    if (hex == null) return Colors.white;
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return iso;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!,
                  style: const TextStyle(color: Colors.white54),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(
                  onPressed: _load,
                  child: const Text('Erneut versuchen',
                      style: TextStyle(color: _kPink))),
            ],
          ),
        ),
      );
    }
    if (_rows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
              'Noch keine Scans gespeichert.\nFühre deinen ersten Körperscan durch.',
              style: TextStyle(color: Colors.white54),
              textAlign: TextAlign.center),
        ),
      );
    }
    return RefreshIndicator(
      color: _kPink,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _rows.length,
        itemBuilder: (_, i) {
          final r = _rows[i];
          final primary = r['primary_blocked_chakra'] as int?;
          final meta = primary != null ? _chakraMeta[primary] : null;
          final color = _parseColor(meta?['chakra_color'] as String?);
          final scoresRaw = r['chakra_scores'] as Map?;
          final scores = <int, int>{
            for (final e in (scoresRaw ?? const {}).entries)
              int.parse(e.key.toString()): (e.value as num).toInt(),
          };
          final count = (r['selected_symptom_ids'] as List?)?.length ?? 0;
          final notes = r['notes'] as String?;
          return Card(
            color: _kCardBg,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: color.withValues(alpha: 0.3))),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(meta?['chakra_emoji'] as String? ?? '🌀',
                        style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(meta?['chakra_name'] as String? ?? 'Scan',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(_formatDate(r['scanned_at'] as String),
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.white38, size: 20),
                      onPressed: () => _deleteScan(r['id'] as String),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text('$count Symptom(e) • Scores: ${scores.entries.map((e) => '${e.key}:${e.value}').join(' ')}',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11)),
                  if (notes != null && notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: _kDarkBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _kBorder)),
                      child: Text(notes,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Info (Phase 7.2f füllt diesen Stub)
// ─────────────────────────────────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  const _InfoTab();

  static const List<Map<String, dynamic>> _chakras = [
    {
      'nr': 1,
      'name': 'Wurzelchakra',
      'sanskrit': 'Muladhara',
      'color': '#F44336',
      'emoji': '🔴',
      'location': 'Steißbein / Beckenboden',
      'element': 'Erde',
      'theme': 'Sicherheit, Erdung, Urvertrauen',
      'balance':
          'Gefühl von Sicherheit, Stabilität, Vertrauen ins Leben, finanzielle Klarheit.',
      'blockade':
          'Existenzangst, Rückenschmerzen, Unsicherheit, Gefühl von Entwurzelung.',
      'heal':
          'Barfuß gehen, Wurzelgemüse essen, rote Kristalle (Jaspis, Granat), Wurzel-Meditation.',
    },
    {
      'nr': 2,
      'name': 'Sakralchakra',
      'sanskrit': 'Svadhisthana',
      'color': '#FF9800',
      'emoji': '🟠',
      'location': 'Unterbauch, zwei Finger unter Bauchnabel',
      'element': 'Wasser',
      'theme': 'Kreativität, Lust, Gefühle, Sexualität',
      'balance':
          'Leidenschaft, gesunder Genuss, kreativer Fluss, lebendige Beziehungen.',
      'blockade':
          'Gefühlstaubheit, Kontrollzwang, sexuelle Scham, Kreativitätsblockade.',
      'heal':
          'Tanzen, Wasser-Rituale, Karneol tragen, Becken kreisen, Atemarbeit.',
    },
    {
      'nr': 3,
      'name': 'Solarplexuschakra',
      'sanskrit': 'Manipura',
      'color': '#FFEB3B',
      'emoji': '🟡',
      'location': 'Oberbauch, unter Brustbein',
      'element': 'Feuer',
      'theme': 'Selbstwert, Willenskraft, Identität',
      'balance':
          'Starkes Selbstbewusstsein, klare Entscheidungen, persönliche Kraft.',
      'blockade':
          'Selbstkritik, Perfektionismus, Verdauungsprobleme, Opferhaltung.',
      'heal':
          'Sonnenlicht, gelbe Lebensmittel, Citrin, Lachyoga, "Ich bin"-Affirmationen.',
    },
    {
      'nr': 4,
      'name': 'Herzchakra',
      'sanskrit': 'Anahata',
      'color': '#4CAF50',
      'emoji': '💚',
      'location': 'Mitte der Brust',
      'element': 'Luft',
      'theme': 'Liebe, Mitgefühl, Vergebung',
      'balance':
          'Bedingungslose Liebe zu sich und anderen, tiefe Verbindung, Mitgefühl.',
      'blockade':
          'Bitterkeit, Isolation, Herz-Kreislauf-Probleme, unfähig zu vergeben.',
      'heal':
          'Herzöffnende Yoga-Haltungen, Rosenquarz, Vergebungsrituale, Naturkontakt.',
    },
    {
      'nr': 5,
      'name': 'Kehlchakra',
      'sanskrit': 'Vishuddha',
      'color': '#2196F3',
      'emoji': '🔵',
      'location': 'Hals / Kehle',
      'element': 'Äther',
      'theme': 'Wahrheit, Ausdruck, Kommunikation',
      'balance':
          'Authentisches Sprechen, klare Grenzen, kreativer Ausdruck, Zuhören können.',
      'blockade':
          'Halsschmerzen, Schilddrüsenprobleme, Angst zu sprechen, Lügen.',
      'heal':
          'Singen, Mantren, Tagebuchschreiben, Sodalith/Aquamarin, Kehl-Atmung.',
    },
    {
      'nr': 6,
      'name': 'Drittes Auge',
      'sanskrit': 'Ajna',
      'color': '#9C27B0',
      'emoji': '🟣',
      'location': 'Stirn zwischen den Augenbrauen',
      'element': 'Licht',
      'theme': 'Intuition, Weisheit, innere Visionen',
      'balance':
          'Klare Intuition, lebendige Träume, innere Führung, Weitsicht.',
      'blockade':
          'Migräne, Überanalyse, Fantasie-Realität-Vermischung, Zweifel an Intuition.',
      'heal':
          'Meditation, Amethyst, Traumjournal, Stille, Yoga Nidra.',
    },
    {
      'nr': 7,
      'name': 'Kronenchakra',
      'sanskrit': 'Sahasrara',
      'color': '#E1BEE7',
      'emoji': '⚪',
      'location': 'Scheitel / über dem Kopf',
      'element': 'Reines Bewusstsein',
      'theme': 'Spiritualität, Einheit, Transzendenz',
      'balance':
          'Gefühl von Einheit, spirituelle Verbundenheit, tiefer Sinn, innerer Frieden.',
      'blockade':
          'Sinnverlust, Nihilismus, Abgeschnittenheit, spiritueller Hochmut.',
      'heal':
          'Stille Meditation, Beten, Bergkristall, Fasten, heilige Räume aufsuchen.',
    },
  ];

  Color _parseColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _chakras.length,
      itemBuilder: (_, i) {
        final c = _chakras[i];
        final color = _parseColor(c['color'] as String);
        return Card(
          color: _kCardBg,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: color.withValues(alpha: 0.4))),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              iconColor: Colors.white70,
              collapsedIconColor: Colors.white54,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.4), _kDarkBg]),
                    shape: BoxShape.circle,
                    border: Border.all(color: color),
                  ),
                  alignment: Alignment.center,
                  child: Text(c['emoji'] as String,
                      style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${c['nr']}. ${c['name']}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(c['sanskrit'] as String,
                          style: TextStyle(color: color, fontSize: 11)),
                    ],
                  ),
                ),
              ]),
              children: [
                _InfoRow(
                    label: 'Ort', value: c['location'] as String, color: color),
                _InfoRow(
                    label: 'Element',
                    value: c['element'] as String,
                    color: color),
                _InfoRow(
                    label: 'Thema',
                    value: c['theme'] as String,
                    color: color),
                const SizedBox(height: 8),
                _InfoBlock(
                    title: '✨ Im Gleichgewicht',
                    text: c['balance'] as String,
                    color: color),
                const SizedBox(height: 8),
                _InfoBlock(
                    title: '⚠️ Bei Blockade',
                    text: c['blockade'] as String,
                    color: Colors.orangeAccent),
                const SizedBox(height: 8),
                _InfoBlock(
                    title: '🌱 Heilpraxis',
                    text: c['heal'] as String,
                    color: Colors.lightGreenAccent),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _InfoRow(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String title;
  final String text;
  final Color color;
  const _InfoBlock(
      {required this.title, required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: _kDarkBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(text,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12, height: 1.35)),
        ],
      ),
    );
  }
}
