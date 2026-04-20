import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/dream_symbol_matcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DreamInterpretationToolScreen – 4 Tabs
//   Tab 0: Neuer Traum      (_NewDreamTab)
//   Tab 1: Symbol-Lexikon   (_LexiconTab)
//   Tab 2: Mein Traumbuch   (_JournalTab)
//   Tab 3: Muster           (_PatternsTab)
// ─────────────────────────────────────────────────────────────────────────────

class DreamInterpretationToolScreen extends StatefulWidget {
  const DreamInterpretationToolScreen({super.key});

  @override
  State<DreamInterpretationToolScreen> createState() =>
      _DreamInterpretationToolScreenState();
}

class _DreamInterpretationToolScreenState
    extends State<DreamInterpretationToolScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  static const _purple = Color(0xFF7C4DFF);
  static const _darkBg = Color(0xFF0A0A0F);
  static const _cardBg = Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        title: const Text('💭 Traumdeutung',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _purple,
          labelColor: _purple,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Neu'),
            Tab(icon: Icon(Icons.auto_stories), text: 'Lexikon'),
            Tab(icon: Icon(Icons.book), text: 'Journal'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Muster'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _NewDreamTab(),
          _LexiconTab(),
          _JournalTab(),
          _PatternsTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared constants
// ─────────────────────────────────────────────────────────────────────────────

const _kPurple = Color(0xFF7C4DFF);
const _kCardBg = Color(0xFF1A1A2E);
const _kBorder = Color(0xFF2A2A4E);

final _db = Supabase.instance.client;

// ─────────────────────────────────────────────────────────────────────────────
// Tab 0: Neuer Traum
// ─────────────────────────────────────────────────────────────────────────────

class _NewDreamTab extends StatefulWidget {
  const _NewDreamTab();
  @override
  State<_NewDreamTab> createState() => _NewDreamTabState();
}

class _NewDreamTabState extends State<_NewDreamTab> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _mood = 'neutral';
  bool _lucid = false;
  bool _recurring = false;
  bool _saving = false;
  List<String> _detectedTags = [];
  List<Map<String, dynamic>> _detectedSymbolDetails = [];

  static const _moods = [
    ('neutral', '😐', 'Neutral'),
    ('freude', '😄', 'Freude'),
    ('angst', '😨', 'Angst'),
    ('traurig', '😢', 'Traurig'),
    ('wut', '😠', 'Wut'),
    ('ekstatisch', '🤩', 'Ekstatisch'),
  ];

  @override
  void initState() {
    super.initState();
    DreamSymbolMatcher.instance.preload();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte erst einloggen')),
      );
      return;
    }
    if (_descCtrl.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Traum beschreiben')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _db.from('dream_journal_v2').insert({
        'user_id': uid,
        'title': _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'symbol_tags': _detectedTags,
        'mood': _mood,
        'lucid': _lucid,
        'recurring': _recurring,
      });
      if (!mounted) return;
      _titleCtrl.clear();
      _descCtrl.clear();
      setState(() {
        _mood = 'neutral';
        _lucid = false;
        _recurring = false;
        _detectedTags = [];
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Traum gespeichert'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    }
  }

  void _detectSymbols(String text) {
    final tags = DreamSymbolMatcher.instance.match(text);
    if (tags.toString() == _detectedTags.toString()) return;
    setState(() => _detectedTags = tags);
    if (tags.isNotEmpty) {
      DreamSymbolMatcher.instance.symbolsForKeys(tags).then((details) {
        if (mounted) setState(() => _detectedSymbolDetails = details);
      });
    } else {
      setState(() => _detectedSymbolDetails = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A3E), Color(0xFF0D0D2B)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kBorder),
            ),
            child: const Row(
              children: [
                Text('💭', style: TextStyle(fontSize: 32)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Traum aufzeichnen',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Beschreibe deinen Traum – Symbole werden automatisch erkannt.',
                          style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Titel
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Titel (optional)', Icons.title),
          ),
          const SizedBox(height: 12),

          // Beschreibung
          TextField(
            controller: _descCtrl,
            style: const TextStyle(color: Colors.white),
            maxLines: 5,
            onChanged: _detectSymbols,
            decoration: _inputDecoration(
                'Beschreibe deinen Traum…', Icons.edit_note,
                helperText: 'Symbole werden automatisch erkannt'),
          ),
          const SizedBox(height: 16),

          // Stimmung
          const Text('Stimmung beim Aufwachen',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _moods.map((m) {
              final selected = _mood == m.$1;
              return GestureDetector(
                onTap: () => setState(() => _mood = m.$1),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? _kPurple : _kCardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: selected ? _kPurple : _kBorder),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(m.$2, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(m.$3,
                        style: TextStyle(
                            color: selected ? Colors.white : Colors.white54,
                            fontSize: 12)),
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Toggles
          Container(
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Luzider Traum',
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Du wusstest, dass du träumst',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  value: _lucid,
                  activeThumbColor: _kPurple,
                  onChanged: (v) => setState(() => _lucid = v),
                ),
                Divider(color: _kBorder, height: 1),
                SwitchListTile(
                  title: const Text('Wiederkehrender Traum',
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Dieser Traum kehrt regelmäßig wieder',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  value: _recurring,
                  activeThumbColor: _kPurple,
                  onChanged: (v) => setState(() => _recurring = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Erkannte Symbole mit Kurzinterpretation
          if (_detectedTags.isNotEmpty) ...[
            const Text('Erkannte Symbole',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._detectedSymbolDetails.map((sym) {
              final meanings =
                  Map<String, dynamic>.from(sym['meanings'] as Map? ?? {});
              final preview = (meanings['jungian'] ??
                      meanings['spiritual'] ??
                      '') as String;
              return Card(
                color: const Color(0xFF1E1E3E),
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: _kBorder),
                ),
                child: ListTile(
                  leading: Text(sym['emoji'] as String? ?? '🔮',
                      style: const TextStyle(fontSize: 24)),
                  title: Text(sym['symbol_name'] as String? ?? '',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  subtitle: preview.isNotEmpty
                      ? Text(
                          preview.length > 80
                              ? '${preview.substring(0, 80)}…'
                              : preview,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12))
                      : null,
                  trailing: const Icon(Icons.info_outline,
                      color: Colors.white38, size: 18),
                  onTap: () => _SymbolListTile(symbol: sym)
                      .showDetailFrom(context),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],

          // Speichern
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Speichert…' : 'Traum speichern'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon,
      {String? helperText}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      helperText: helperText,
      helperStyle: const TextStyle(color: Colors.white38, fontSize: 11),
      prefixIcon: Icon(icon, color: Colors.white38),
      filled: true,
      fillColor: _kCardBg,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPurple)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Symbol-Lexikon
// ─────────────────────────────────────────────────────────────────────────────

class _LexiconTab extends StatefulWidget {
  const _LexiconTab();
  @override
  State<_LexiconTab> createState() => _LexiconTabState();
}

class _LexiconTabState extends State<_LexiconTab> {
  List<Map<String, dynamic>> _symbols = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _search = '';
  String _selectedCategory = 'alle';

  static const _categories = [
    ('alle', 'Alle'),
    ('element', 'Elemente'),
    ('tier', 'Tiere'),
    ('mensch', 'Menschen'),
    ('aktion', 'Aktionen'),
    ('ort', 'Orte'),
    ('objekt', 'Objekte'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _db
          .from('dream_symbols')
          .select('symbol_key, symbol_name, category, emoji, meanings')
          .order('sort_order');
      if (!mounted) return;
      setState(() {
        _symbols = List<Map<String, dynamic>>.from(data);
        _applyFilter();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    _filtered = _symbols.where((s) {
      final catOk = _selectedCategory == 'alle' ||
          s['category'] == _selectedCategory;
      final q = _search.toLowerCase();
      final nameOk = q.isEmpty ||
          (s['symbol_name'] as String).toLowerCase().contains(q);
      return catOk && nameOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search + filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            onChanged: (v) => setState(() {
              _search = v;
              _applyFilter();
            }),
            decoration: InputDecoration(
              hintText: 'Symbol suchen…',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon:
                  const Icon(Icons.search, color: Colors.white38),
              filled: true,
              fillColor: _kCardBg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final sel = _selectedCategory == cat.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat.$2,
                      style: TextStyle(
                          color: sel ? Colors.white : Colors.white54,
                          fontSize: 12)),
                  selected: sel,
                  selectedColor: _kPurple,
                  backgroundColor: _kCardBg,
                  onSelected: (_) => setState(() {
                    _selectedCategory = cat.$1;
                    _applyFilter();
                  }),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? const Center(
                      child: Text('Keine Symbole gefunden',
                          style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) =>
                          _SymbolListTile(symbol: _filtered[i]),
                    ),
        ),
      ],
    );
  }
}

class _SymbolListTile extends StatelessWidget {
  final Map<String, dynamic> symbol;
  const _SymbolListTile({required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _kCardBg,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _kBorder)),
      child: ListTile(
        leading: Text(symbol['emoji'] ?? '🔮',
            style: const TextStyle(fontSize: 28)),
        title: Text(symbol['symbol_name'] ?? '',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(symbol['category'] ?? '',
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: () => showDetailFrom(context),
      ),
    );
  }

  void showDetailFrom(BuildContext context) => _showDetail(context);

  void _showDetail(BuildContext context) {
    final meanings =
        Map<String, dynamic>.from(symbol['meanings'] as Map? ?? {});
    final traditions = [
      ('🧠 Jung', 'jungian'),
      ('🛋️ Freud', 'freudian'),
      ('✨ Spirituell', 'spiritual'),
      ('🪶 Schamanisch', 'shamanic'),
      ('🌿 Germanisch', 'germanic'),
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Text(symbol['emoji'] ?? '🔮',
                  style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(symbol['symbol_name'] ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 20),
            ...traditions.map((t) {
              final text = meanings[t.$2] as String?;
              if (text == null || text.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.$1,
                        style: const TextStyle(
                            color: _kPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(text,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13, height: 1.5)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Mein Traumjounal
// ─────────────────────────────────────────────────────────────────────────────

class _JournalTab extends StatefulWidget {
  const _JournalTab();
  @override
  State<_JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends State<_JournalTab> {
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final data = await _db
          .from('dream_journal_v2')
          .select()
          .eq('user_id', uid)
          .order('dream_date', ascending: false)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _entries = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCardBg,
        title: const Text('Traum löschen?',
            style: TextStyle(color: Colors.white)),
        content: const Text('Dieser Eintrag wird dauerhaft gelöscht.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Löschen',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _db.from('dream_journal_v2').delete().eq('id', id);
      if (!mounted) return;
      setState(() => _entries.removeWhere((e) => e['id'] == id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Traum gelöscht')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Fehler: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_db.auth.currentUser == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Bitte einloggen um dein Traumtagebuch zu sehen.',
              style: TextStyle(color: Colors.white54),
              textAlign: TextAlign.center),
        ),
      );
    }
    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Noch keine Träume aufgezeichnet.',
                style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 8),
            TextButton(
                onPressed: _load,
                child: const Text('Aktualisieren',
                    style: TextStyle(color: _kPurple))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _entries.length,
        itemBuilder: (_, i) {
          final e = _entries[i];
          final tags = (e['symbol_tags'] as List?)?.cast<String>() ?? [];
          final mood = e['mood'] as String? ?? 'neutral';
          final lucid = e['lucid'] == true;
          return Card(
            color: _kCardBg,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: _kBorder)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                          e['title'] as String? ??
                              (e['description'] as String? ?? '')
                                  .split(' ')
                                  .take(5)
                                  .join(' '),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent, size: 20),
                      onPressed: () => _delete(e['id'] as String),
                      visualDensity: VisualDensity.compact,
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                      (e['description'] as String? ?? '').length > 120
                          ? '${(e['description'] as String).substring(0, 120)}…'
                          : (e['description'] as String? ?? ''),
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(children: [
                    if (lucid) ...[
                      _pill('✨ Luzid', const Color(0xFF7C4DFF)),
                      const SizedBox(width: 6),
                    ],
                    _pill(_moodEmoji(mood), _kCardBg),
                    const Spacer(),
                    Text(e['dream_date'] as String? ?? '',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                  ]),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: tags
                          .map((t) => _pill(t, const Color(0xFF263238)))
                          .toList(),
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

  Widget _pill(String label, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      );

  String _moodEmoji(String mood) {
    const map = {
      'neutral': '😐 Neutral',
      'freude': '😄 Freude',
      'angst': '😨 Angst',
      'traurig': '😢 Traurig',
      'wut': '😠 Wut',
      'ekstatisch': '🤩 Ekstatisch',
    };
    return map[mood] ?? '😐';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3: Muster
// ─────────────────────────────────────────────────────────────────────────────

class _PatternsTab extends StatefulWidget {
  const _PatternsTab();
  @override
  State<_PatternsTab> createState() => _PatternsTabState();
}

class _PatternsTabState extends State<_PatternsTab> {
  List<_TagFreq> _topTags = [];
  Map<String, int> _moodCounts = {};
  int _total = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final data = await _db
          .from('dream_journal_v2')
          .select('symbol_tags, mood')
          .eq('user_id', uid);
      final entries = List<Map<String, dynamic>>.from(data);
      final tagCount = <String, int>{};
      final moodCount = <String, int>{};
      for (final e in entries) {
        for (final t in (e['symbol_tags'] as List? ?? [])) {
          tagCount[t as String] = (tagCount[t] ?? 0) + 1;
        }
        final m = e['mood'] as String? ?? 'neutral';
        moodCount[m] = (moodCount[m] ?? 0) + 1;
      }
      final sorted = tagCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (!mounted) return;
      setState(() {
        _topTags = sorted.take(10).map((e) => _TagFreq(e.key, e.value)).toList();
        _moodCounts = moodCount;
        _total = entries.length;
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
    if (_db.auth.currentUser == null) {
      return const Center(
          child: Text('Bitte einloggen.',
              style: TextStyle(color: Colors.white54)));
    }
    if (_total == 0) {
      return const Center(
        child: Text('Noch keine Daten.\nZeichne Träume auf um Muster zu sehen.',
            style: TextStyle(color: Colors.white54),
            textAlign: TextAlign.center),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('📊 Gesamt: $_total Träume'),
          const SizedBox(height: 12),
          if (_topTags.isNotEmpty) ...[
            _sectionHeader('🔁 Häufigste Symbole'),
            const SizedBox(height: 8),
            ..._topTags.map((t) => _TagBar(tag: t, max: _topTags.first.count)),
            const SizedBox(height: 20),
          ],
          if (_moodCounts.isNotEmpty) ...[
            _sectionHeader('😊 Stimmungsverteilung'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _moodCounts.entries
                  .map((e) => _MoodBubble(mood: e.key, count: e.value))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) => Text(text,
      style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold));
}

class _TagFreq {
  final String tag;
  final int count;
  const _TagFreq(this.tag, this.count);
}

class _TagBar extends StatelessWidget {
  final _TagFreq tag;
  final int max;
  const _TagBar({required this.tag, required this.max});

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? tag.count / max : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child: Text(tag.tag,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13))),
            Text('${tag.count}×',
                style:
                    const TextStyle(color: Colors.white38, fontSize: 12)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: _kBorder,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(_kPurple),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodBubble extends StatelessWidget {
  final String mood;
  final int count;
  const _MoodBubble({required this.mood, required this.count});

  static const _emojis = {
    'neutral': '😐',
    'freude': '😄',
    'angst': '😨',
    'traurig': '😢',
    'wut': '😠',
    'ekstatisch': '🤩',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Text(_emojis[mood] ?? '😐',
              style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text('$count×',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}
