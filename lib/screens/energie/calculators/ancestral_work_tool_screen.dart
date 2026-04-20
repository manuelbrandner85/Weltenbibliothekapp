import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AncestralWorkToolScreen – 3 Tabs
//   Tab 0: Ahnen   (eingetragene Ahnen, hinzufügen/bearbeiten)
//   Tab 1: Muster  (Familien-/Generationsmuster, hinzufügen/bearbeiten)
//   Tab 2: Rituale (8 öffentliche Rituale aus verschiedenen Traditionen)
// ─────────────────────────────────────────────────────────────────────────────

const _kAmber = Color(0xFFD4A24C);
const _kDarkBg = Color(0xFF0A0A0F);
const _kCardBg = Color(0xFF1A1A2E);
const _kBorder = Color(0xFF2A2A4E);

final _db = Supabase.instance.client;

class AncestralWorkToolScreen extends StatefulWidget {
  const AncestralWorkToolScreen({super.key});

  @override
  State<AncestralWorkToolScreen> createState() =>
      _AncestralWorkToolScreenState();
}

class _AncestralWorkToolScreenState extends State<AncestralWorkToolScreen>
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
        title: const Text('🕯️ Ahnenarbeit',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _kAmber,
          labelColor: _kAmber,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.family_restroom), text: 'Ahnen'),
            Tab(icon: Icon(Icons.hub_outlined), text: 'Muster'),
            Tab(icon: Icon(Icons.auto_stories), text: 'Rituale'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _AncestorsTab(),
          _PatternsTab(),
          _RitualsTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 0: Ahnen  (Phase 4.2b)
// ─────────────────────────────────────────────────────────────────────────────

const Map<String, String> _kRelations = {
  'mother': 'Mutter',
  'father': 'Vater',
  'grandmother_mat': 'Großmutter (mütterl.)',
  'grandfather_mat': 'Großvater (mütterl.)',
  'grandmother_pat': 'Großmutter (väterl.)',
  'grandfather_pat': 'Großvater (väterl.)',
  'great_grandmother': 'Urgroßmutter',
  'great_grandfather': 'Urgroßvater',
  'aunt': 'Tante',
  'uncle': 'Onkel',
  'sibling': 'Geschwisterteil',
  'other': 'Andere/r',
};

class _AncestorsTab extends StatefulWidget {
  const _AncestorsTab();
  @override
  State<_AncestorsTab> createState() => _AncestorsTabState();
}

class _AncestorsTabState extends State<_AncestorsTab> {
  List<Map<String, dynamic>> _rows = [];
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
      final rows = await _db
          .from('ancestors')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
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

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCardBg,
        title: const Text('Ahn_in löschen?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'Dieser Eintrag wird unwiderruflich gelöscht.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen',
                  style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Löschen',
                  style: TextStyle(color: _kAmber))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _db.from('ancestors').delete().eq('id', id);
      if (!mounted) return;
      setState(() => _rows.removeWhere((r) => r['id'] == id));
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ahn_in gelöscht')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')));
    }
  }

  Future<void> _openEditor({Map<String, dynamic>? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AncestorEditorSheet(existing: existing),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kAmber,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Ahn_in'),
        onPressed: () => _openEditor(),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kAmber));
    }
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
                      style: TextStyle(color: _kAmber))),
            ],
          ),
        ),
      );
    }
    if (_rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.family_restroom, color: _kAmber, size: 48),
              SizedBox(height: 12),
              Text(
                  'Noch keine Ahnen eingetragen.\nTippe unten + Ahn_in, um zu beginnen.',
                  style: TextStyle(color: Colors.white54),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: _kAmber,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
        itemCount: _rows.length,
        itemBuilder: (_, i) {
          final r = _rows[i];
          final relation = _kRelations[r['relation']] ?? r['relation'];
          final by = r['birth_year'] as int?;
          final dy = r['death_year'] as int?;
          final traits =
              List<String>.from((r['known_traits'] as List?) ?? const []);
          return Card(
            color: _kCardBg,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: _kAmber.withValues(alpha: 0.3))),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openEditor(existing: r),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: _kAmber,
                        child: Icon(Icons.person,
                            color: Colors.black, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['name'] as String? ?? '—',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                                '$relation${by != null || dy != null ? '  •  ${by ?? '?'}–${dy ?? '?'}' : ''}',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.white38, size: 20),
                        onPressed: () => _delete(r['id'] as String),
                      ),
                    ]),
                    if (traits.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: traits
                            .map((t) => Chip(
                                  label: Text(t,
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11)),
                                  backgroundColor: _kBorder,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ),
                    ],
                    if ((r['story'] as String?)?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 8),
                      Text(r['story'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AncestorEditorSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _AncestorEditorSheet({this.existing});
  @override
  State<_AncestorEditorSheet> createState() => _AncestorEditorSheetState();
}

class _AncestorEditorSheetState extends State<_AncestorEditorSheet> {
  final _nameCtrl = TextEditingController();
  final _birthCtrl = TextEditingController();
  final _deathCtrl = TextEditingController();
  final _traitsCtrl = TextEditingController();
  final _storyCtrl = TextEditingController();
  final _giftsCtrl = TextEditingController();
  final _healingCtrl = TextEditingController();
  final _intentionCtrl = TextEditingController();
  String _relation = 'mother';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e['name'] as String? ?? '';
      _relation = e['relation'] as String? ?? 'mother';
      _birthCtrl.text = (e['birth_year'] as int?)?.toString() ?? '';
      _deathCtrl.text = (e['death_year'] as int?)?.toString() ?? '';
      _traitsCtrl.text =
          List<String>.from((e['known_traits'] as List?) ?? const [])
              .join(', ');
      _storyCtrl.text = e['story'] as String? ?? '';
      _giftsCtrl.text = e['gifts'] as String? ?? '';
      _healingCtrl.text = e['healing_needed'] as String? ?? '';
      _intentionCtrl.text = e['intention'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _birthCtrl.dispose();
    _deathCtrl.dispose();
    _traitsCtrl.dispose();
    _storyCtrl.dispose();
    _giftsCtrl.dispose();
    _healingCtrl.dispose();
    _intentionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name darf nicht leer sein')));
      return;
    }
    final user = _db.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bitte zuerst anmelden')));
      return;
    }
    setState(() => _saving = true);
    try {
      final traits = _traitsCtrl.text
          .split(RegExp(r'[,\n]'))
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      final payload = {
        'name': name,
        'relation': _relation,
        'birth_year': int.tryParse(_birthCtrl.text.trim()),
        'death_year': int.tryParse(_deathCtrl.text.trim()),
        'known_traits': traits,
        'story': _storyCtrl.text.trim().isEmpty
            ? null
            : _storyCtrl.text.trim(),
        'gifts': _giftsCtrl.text.trim().isEmpty
            ? null
            : _giftsCtrl.text.trim(),
        'healing_needed': _healingCtrl.text.trim().isEmpty
            ? null
            : _healingCtrl.text.trim(),
        'intention': _intentionCtrl.text.trim().isEmpty
            ? null
            : _intentionCtrl.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (widget.existing == null) {
        await _db.from('ancestors').insert({
          ...payload,
          'user_id': user.id,
        });
      } else {
        await _db
            .from('ancestors')
            .update(payload)
            .eq('id', widget.existing!['id'] as String);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: _kDarkBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    const Icon(Icons.family_restroom, color: _kAmber),
                    const SizedBox(width: 8),
                    Text(
                        widget.existing == null
                            ? 'Neue Ahn_in'
                            : 'Ahn_in bearbeiten',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    _field(_nameCtrl, 'Name*', Icons.person_outline),
                    const SizedBox(height: 12),
                    _relationPicker(),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: _field(_birthCtrl, 'Geburtsjahr',
                              Icons.cake_outlined,
                              keyboard: TextInputType.number)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _field(_deathCtrl, 'Sterbejahr',
                              Icons.nights_stay_outlined,
                              keyboard: TextInputType.number)),
                    ]),
                    const SizedBox(height: 12),
                    _field(_traitsCtrl,
                        'Bekannte Eigenschaften (kommagetrennt)',
                        Icons.label_outline),
                    const SizedBox(height: 12),
                    _field(_storyCtrl, 'Geschichte / Erinnerung',
                        Icons.auto_stories_outlined,
                        maxLines: 3),
                    const SizedBox(height: 12),
                    _field(_giftsCtrl, 'Gaben, die er/sie brachte',
                        Icons.card_giftcard_outlined,
                        maxLines: 2),
                    const SizedBox(height: 12),
                    _field(_healingCtrl, 'Wunden / Themen zur Heilung',
                        Icons.healing_outlined,
                        maxLines: 2),
                    const SizedBox(height: 12),
                    _field(_intentionCtrl, 'Deine Intention zu ihm/ihr',
                        Icons.flag_outlined,
                        maxLines: 2),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black))
                            : const Icon(Icons.save_outlined),
                        label: Text(widget.existing == null
                            ? 'Speichern'
                            : 'Aktualisieren'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kAmber,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {int maxLines = 1, TextInputType? keyboard}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: _kAmber),
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
            borderSide: const BorderSide(color: _kAmber)),
      ),
    );
  }

  Widget _relationPicker() {
    return DropdownButtonFormField<String>(
      initialValue: _relation,
      dropdownColor: _kCardBg,
      iconEnabledColor: _kAmber,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Beziehung',
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.account_tree_outlined, color: _kAmber),
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
            borderSide: const BorderSide(color: _kAmber)),
      ),
      items: _kRelations.entries
          .map((e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value,
                    style: const TextStyle(color: Colors.white)),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _relation = v);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Muster  (Phase 4.2c)
// ─────────────────────────────────────────────────────────────────────────────

const Map<String, String> _kPatternTypes = {
  'belief': 'Glaubenssatz',
  'trauma': 'Trauma',
  'strength': 'Stärke',
  'gift': 'Gabe',
  'silence': 'Schweigen',
  'taboo': 'Tabu',
  'other': 'Andere',
};

const Map<String, String> _kPatternStatus = {
  'recognized': 'Erkannt',
  'in_healing': 'In Heilung',
  'integrated': 'Integriert',
};

const Map<String, Color> _kPatternStatusColor = {
  'recognized': Color(0xFFD4A24C),
  'in_healing': Color(0xFF64B5F6),
  'integrated': Color(0xFF81C784),
};

class _PatternsTab extends StatefulWidget {
  const _PatternsTab();
  @override
  State<_PatternsTab> createState() => _PatternsTabState();
}

class _PatternsTabState extends State<_PatternsTab> {
  List<Map<String, dynamic>> _rows = [];
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
      final rows = await _db
          .from('ancestor_patterns')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
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

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCardBg,
        title: const Text('Muster löschen?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'Dieser Eintrag wird unwiderruflich gelöscht.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen',
                  style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Löschen',
                  style: TextStyle(color: _kAmber))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _db.from('ancestor_patterns').delete().eq('id', id);
      if (!mounted) return;
      setState(() => _rows.removeWhere((r) => r['id'] == id));
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Muster gelöscht')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')));
    }
  }

  Future<void> _openEditor({Map<String, dynamic>? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PatternEditorSheet(existing: existing),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kAmber,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Muster'),
        onPressed: () => _openEditor(),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kAmber));
    }
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
                      style: TextStyle(color: _kAmber))),
            ],
          ),
        ),
      );
    }
    if (_rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.hub_outlined, color: _kAmber, size: 48),
              SizedBox(height: 12),
              Text(
                  'Noch keine Muster erkannt.\nTippe unten + Muster, um zu beginnen.',
                  style: TextStyle(color: Colors.white54),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: _kAmber,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
        itemCount: _rows.length,
        itemBuilder: (_, i) {
          final r = _rows[i];
          final pType = r['pattern_type'] as String? ?? 'other';
          final status = r['status'] as String? ?? 'recognized';
          final statusColor =
              _kPatternStatusColor[status] ?? Colors.white54;
          return Card(
            color: _kCardBg,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: _kAmber.withValues(alpha: 0.3))),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openEditor(existing: r),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['title'] as String? ?? '—',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: _kBorder,
                                    borderRadius:
                                        BorderRadius.circular(10)),
                                child: Text(
                                    _kPatternTypes[pType] ?? pType,
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color:
                                        statusColor.withValues(alpha: 0.2),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    border: Border.all(
                                        color: statusColor
                                            .withValues(alpha: 0.5))),
                                child: Text(
                                    _kPatternStatus[status] ?? status,
                                    style: TextStyle(
                                        color: statusColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.white38, size: 20),
                        onPressed: () => _delete(r['id'] as String),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Text(r['description'] as String? ?? '',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    if ((r['generations_affected'] as String?)?.isNotEmpty ??
                        false) ...[
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.people_outline,
                            size: 13, color: Colors.white38),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(r['generations_affected'] as String,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11)),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PatternEditorSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _PatternEditorSheet({this.existing});
  @override
  State<_PatternEditorSheet> createState() => _PatternEditorSheetState();
}

class _PatternEditorSheetState extends State<_PatternEditorSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _genCtrl = TextEditingController();
  final _healCtrl = TextEditingController();
  String _type = 'other';
  String _status = 'recognized';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e['title'] as String? ?? '';
      _descCtrl.text = e['description'] as String? ?? '';
      _genCtrl.text = e['generations_affected'] as String? ?? '';
      _healCtrl.text = e['healing_intention'] as String? ?? '';
      _type = e['pattern_type'] as String? ?? 'other';
      _status = e['status'] as String? ?? 'recognized';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _genCtrl.dispose();
    _healCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Titel und Beschreibung sind Pflicht')));
      return;
    }
    final user = _db.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bitte zuerst anmelden')));
      return;
    }
    setState(() => _saving = true);
    try {
      final payload = {
        'title': title,
        'description': desc,
        'pattern_type': _type,
        'status': _status,
        'generations_affected':
            _genCtrl.text.trim().isEmpty ? null : _genCtrl.text.trim(),
        'healing_intention':
            _healCtrl.text.trim().isEmpty ? null : _healCtrl.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (widget.existing == null) {
        await _db.from('ancestor_patterns').insert({
          ...payload,
          'user_id': user.id,
        });
      } else {
        await _db
            .from('ancestor_patterns')
            .update(payload)
            .eq('id', widget.existing!['id'] as String);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: _kDarkBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    const Icon(Icons.hub_outlined, color: _kAmber),
                    const SizedBox(width: 8),
                    Text(
                        widget.existing == null
                            ? 'Neues Muster'
                            : 'Muster bearbeiten',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    _field(_titleCtrl, 'Titel*', Icons.title),
                    const SizedBox(height: 12),
                    _typeDropdown(),
                    const SizedBox(height: 12),
                    _field(_descCtrl, 'Beschreibung*',
                        Icons.description_outlined,
                        maxLines: 4),
                    const SizedBox(height: 12),
                    _field(_genCtrl, 'Betroffene Generationen',
                        Icons.people_outline,
                        maxLines: 2),
                    const SizedBox(height: 12),
                    _field(_healCtrl, 'Heil-Intention',
                        Icons.healing_outlined,
                        maxLines: 3),
                    const SizedBox(height: 12),
                    _statusDropdown(),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black))
                            : const Icon(Icons.save_outlined),
                        label: Text(widget.existing == null
                            ? 'Speichern'
                            : 'Aktualisieren'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kAmber,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: _kAmber),
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
            borderSide: const BorderSide(color: _kAmber)),
      ),
    );
  }

  Widget _typeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _type,
      dropdownColor: _kCardBg,
      iconEnabledColor: _kAmber,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Typ',
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.category_outlined, color: _kAmber),
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
            borderSide: const BorderSide(color: _kAmber)),
      ),
      items: _kPatternTypes.entries
          .map((e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value,
                    style: const TextStyle(color: Colors.white)),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _type = v);
      },
    );
  }

  Widget _statusDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _status,
      dropdownColor: _kCardBg,
      iconEnabledColor: _kAmber,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Status',
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.flag_outlined, color: _kAmber),
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
            borderSide: const BorderSide(color: _kAmber)),
      ),
      items: _kPatternStatus.entries
          .map((e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value,
                    style: const TextStyle(color: Colors.white)),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _status = v);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Rituale  (Phase 4.2d)
// ─────────────────────────────────────────────────────────────────────────────

const Map<String, String> _kTraditionLabels = {
  'allgemein': 'Allgemein',
  'schamanisch': 'Schamanisch',
  'keltisch': 'Keltisch',
  'familienaufstellung': 'Aufstellung',
  'germanisch': 'Germanisch',
  'afrikanisch': 'Afrikanisch',
  'ostasiatisch': 'Ostasiatisch',
  'buddhistisch': 'Buddhistisch',
};

class _RitualsTab extends StatefulWidget {
  const _RitualsTab();
  @override
  State<_RitualsTab> createState() => _RitualsTabState();
}

class _RitualsTabState extends State<_RitualsTab> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';

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
      final rows = await _db
          .from('ancestral_rituals')
          .select()
          .order('sort_order', ascending: true);
      if (!mounted) return;
      setState(() {
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

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'all') return _rows;
    return _rows.where((r) => r['tradition'] == _filter).toList();
  }

  Set<String> get _traditions =>
      _rows.map((r) => r['tradition'] as String).toSet();

  void _openDetail(Map<String, dynamic> r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RitualDetailSheet(ritual: r),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kAmber));
    }
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
                      style: TextStyle(color: _kAmber))),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: _kAmber,
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _chip('all', 'Alle'),
                  ..._traditions.map((t) =>
                      _chip(t, _kTraditionLabels[t] ?? t)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
            sliver: SliverList.builder(
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final r = _filtered[i];
                return _RitualCard(
                  ritual: r,
                  onTap: () => _openDetail(r),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String key, String label) {
    final selected = _filter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
      child: FilterChip(
        label: Text(label,
            style: TextStyle(
                color: selected ? Colors.black : Colors.white70,
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500)),
        selected: selected,
        backgroundColor: _kCardBg,
        selectedColor: _kAmber,
        checkmarkColor: Colors.black,
        side: BorderSide(
            color: selected ? _kAmber : _kBorder, width: 1),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        onSelected: (_) => setState(() => _filter = key),
      ),
    );
  }
}

class _RitualCard extends StatelessWidget {
  final Map<String, dynamic> ritual;
  final VoidCallback onTap;
  const _RitualCard({required this.ritual, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final emoji = ritual['emoji'] as String? ?? '🕯️';
    final tradition = ritual['tradition'] as String? ?? '';
    final duration = ritual['duration_minutes'] as int? ?? 0;
    final steps = (ritual['steps'] as List?)?.length ?? 0;
    return Card(
      color: _kCardBg,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: _kAmber.withValues(alpha: 0.3))),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ritual['title'] as String? ?? '—',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: _kAmber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(
                              _kTraditionLabels[tradition] ?? tradition,
                              style: const TextStyle(
                                  color: _kAmber,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.schedule,
                            color: Colors.white38, size: 12),
                        const SizedBox(width: 3),
                        Text('$duration Min',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 11)),
                        const SizedBox(width: 10),
                        const Icon(Icons.format_list_numbered,
                            color: Colors.white38, size: 12),
                        const SizedBox(width: 3),
                        Text('$steps Schritte',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 11)),
                      ]),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Text(ritual['description'] as String? ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RitualDetailSheet extends StatelessWidget {
  final Map<String, dynamic> ritual;
  const _RitualDetailSheet({required this.ritual});

  @override
  Widget build(BuildContext context) {
    final emoji = ritual['emoji'] as String? ?? '🕯️';
    final tradition = ritual['tradition'] as String? ?? '';
    final duration = ritual['duration_minutes'] as int? ?? 0;
    final steps = List<String>.from((ritual['steps'] as List?) ?? const []);
    final materials =
        List<String>.from((ritual['materials'] as List?) ?? const []);
    final bestTime = ritual['best_time'] as String?;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: _kDarkBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ritual['title'] as String? ?? '—',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 3),
                        Text(
                            '${_kTraditionLabels[tradition] ?? tradition}  •  $duration Minuten',
                            style: const TextStyle(
                                color: _kAmber,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Text(ritual['description'] as String? ?? '',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5)),
                  if (bestTime != null && bestTime.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: _kAmber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _kAmber.withValues(alpha: 0.3))),
                      child: Row(children: [
                        const Icon(Icons.calendar_month,
                            color: _kAmber, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                              'Bester Zeitpunkt: $bestTime',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13)),
                        ),
                      ]),
                    ),
                  ],
                  if (materials.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Materialien',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: materials
                          .map((m) => Chip(
                                label: Text(m,
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12)),
                                backgroundColor: _kCardBg,
                                side: const BorderSide(color: _kBorder),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                  ],
                  if (steps.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Ablauf',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    for (int i = 0; i < steps.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                  color: _kAmber,
                                  shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Text('${i + 1}',
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(steps[i],
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        height: 1.5)),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
