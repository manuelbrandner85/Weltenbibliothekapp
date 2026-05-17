// 🌳 STAMMBAUM-GENERATOR
//
// Interaktiver 3-Generationen-Stammbaum für Ahnenarbeit. Pro Person:
// Name, Beruf, Pers-Notiz, vermutete Muster. Lokal in SharedPreferences,
// JSON-Format, exportierbar.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FamilyTreeScreen extends StatefulWidget {
  const FamilyTreeScreen({super.key});

  @override
  State<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends State<FamilyTreeScreen> {
  static const _bg = Color(0xFF06040F);
  static const _surface = Color(0xFF1A1A0F);
  static const _accent = Color(0xFFD4A24C);
  static const _kvKey = 'family_tree_v1';

  Map<String, _Member> _members = {};
  bool _loading = true;

  // Slots (Position im Baum)
  static const _slots = [
    ('self',       'Ich',           '🧍', 2),
    ('mother',     'Mutter',        '👩', 1),
    ('father',     'Vater',         '👨', 1),
    ('mgrandma',   'Großmutter (M)', '👵', 0),
    ('mgrandpa',   'Großvater (M)', '👴', 0),
    ('fgrandma',   'Großmutter (V)', '👵', 0),
    ('fgrandpa',   'Großvater (V)', '👴', 0),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kvKey);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _members = map.map((k, v) => MapEntry(
          k, _Member.fromJson(v as Map<String, dynamic>)));
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _members.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_kvKey, jsonEncode(map));
  }

  Future<void> _editMember(String key, String label, String emoji) async {
    final existing = _members[key];
    final result = await showModalBottomSheet<_Member>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _MemberEditSheet(
        label: label, emoji: emoji, existing: existing, accent: _accent),
    );
    if (result != null) {
      setState(() => _members[key] = result);
      await _save();
    }
  }

  Future<void> _exportJson() async {
    final map = _members.map((k, v) => MapEntry(k, v.toJson()));
    final json = const JsonEncoder.withIndent('  ').convert(map);
    await Clipboard.setData(ClipboardData(text: json));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Stammbaum als JSON in Zwischenablage'),
        backgroundColor: _accent,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _accent.withValues(alpha: 0.9),
        foregroundColor: Colors.black,
        title: const Row(children: [
          Text('🌳', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Text('Stammbaum', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Als JSON kopieren',
            onPressed: _exportJson,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_accent.withValues(alpha: 0.4), _surface]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Trage 3 Generationen ein: dich, beide Eltern, alle 4 Großeltern. '
                    'Pro Person: Name, Lebensthema, Muster — Ahnenarbeit beginnt mit Erinnerung.',
                    style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                  ),
                ),
                const SizedBox(height: 20),
                // Großeltern-Reihe
                const Text('GENERATION 3 · GROSSELTERN',
                    style: TextStyle(color: _accent, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _slot('mgrandma', 'GM Mutter', '👵')),
                  const SizedBox(width: 6),
                  Expanded(child: _slot('mgrandpa', 'GV Mutter', '👴')),
                  const SizedBox(width: 6),
                  Expanded(child: _slot('fgrandma', 'GM Vater', '👵')),
                  const SizedBox(width: 6),
                  Expanded(child: _slot('fgrandpa', 'GV Vater', '👴')),
                ]),
                const SizedBox(height: 18),
                // Eltern-Reihe
                const Text('GENERATION 2 · ELTERN',
                    style: TextStyle(color: _accent, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _slot('mother', 'Mutter', '👩')),
                  const SizedBox(width: 6),
                  Expanded(child: _slot('father', 'Vater', '👨')),
                ]),
                const SizedBox(height: 18),
                // Selbst
                const Text('GENERATION 1 · ICH',
                    style: TextStyle(color: _accent, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _slot('self', 'Ich', '🧍'),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '🔒 Daten bleiben rein lokal auf diesem Gerät (SharedPreferences). '
                    'Nichts wird an Server übertragen. Mit JSON-Export kannst du den Baum '
                    'sichern oder weitergeben.',
                    style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.5),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _slot(String key, String label, String emoji) {
    final m = _members[key];
    final filled = m != null;
    return GestureDetector(
      onTap: () => _editMember(key, label, emoji),
      child: Container(
        padding: const EdgeInsets.all(10),
        height: 110,
        decoration: BoxDecoration(
          color: filled ? _accent.withValues(alpha: 0.15) : _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: filled ? _accent : _accent.withValues(alpha: 0.2),
            width: filled ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              filled ? (m.name.isEmpty ? label : m.name) : label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: filled ? Colors.white : Colors.white60,
                fontSize: 11,
                fontWeight: filled ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (filled && m.theme.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(m.theme,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _accent.withValues(alpha: 0.8), fontSize: 9, fontStyle: FontStyle.italic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }
}

class _Member {
  final String name;
  final String profession;
  final String theme;
  final String notes;
  const _Member({
    required this.name,
    required this.profession,
    required this.theme,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'profession': profession,
        'theme': theme,
        'notes': notes,
      };

  factory _Member.fromJson(Map<String, dynamic> j) => _Member(
        name: j['name'] as String? ?? '',
        profession: j['profession'] as String? ?? '',
        theme: j['theme'] as String? ?? '',
        notes: j['notes'] as String? ?? '',
      );
}

class _MemberEditSheet extends StatefulWidget {
  final String label;
  final String emoji;
  final _Member? existing;
  final Color accent;
  const _MemberEditSheet({
    required this.label,
    required this.emoji,
    required this.existing,
    required this.accent,
  });

  @override
  State<_MemberEditSheet> createState() => _MemberEditSheetState();
}

class _MemberEditSheetState extends State<_MemberEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _profession;
  late final TextEditingController _theme;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _profession = TextEditingController(text: widget.existing?.profession ?? '');
    _theme = TextEditingController(text: widget.existing?.theme ?? '');
    _notes = TextEditingController(text: widget.existing?.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _profession.dispose();
    _theme.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
              Text(widget.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Text(widget.label,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),
            _field('Name', _name),
            const SizedBox(height: 12),
            _field('Beruf / Tätigkeit', _profession),
            const SizedBox(height: 12),
            _field('Lebensthema (1 Satz)', _theme),
            const SizedBox(height: 12),
            _field('Notizen, vermutete Muster', _notes, maxLines: 4),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(
                  context,
                  _Member(
                    name: _name.text,
                    profession: _profession.text,
                    theme: _theme.text,
                    notes: _notes.text,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('SPEICHERN', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: widget.accent, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: widget.accent.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: widget.accent),
            ),
          ),
        ),
      ],
    );
  }
}
