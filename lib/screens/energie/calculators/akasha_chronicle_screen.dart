// 🌌 AKASHA-CHRONIK · Cinematic Journal + AI-Reflexion + Mood-Tracking
//
// 7 Eintrag-Kategorien (Traum/Meditation/Insight/Frage/Vision/Synchro/Dankbarkeit)
// Stimmung 1-5 mit Emoji
// AI-Reflexion via /api/mentor/chat (alchemist) — spirituelle Deutung
// 30-Tage Mood-Chart
// Lokal + spirit_readings persistiert
// Streak-Counter für tägliches Schreiben

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/api_config.dart';
import '../../../core/storage/unified_storage_service.dart';
import '../../../services/spirit_reading_service.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';

class AkashaChronicleScreen extends StatefulWidget {
  const AkashaChronicleScreen({super.key});

  @override
  State<AkashaChronicleScreen> createState() => _AkashaChronicleScreenState();
}

class _AkashaChronicleScreenState extends State<AkashaChronicleScreen>
    with TickerProviderStateMixin {
  static const Color _bg = Color(0xFF0A0420);
  static const Color _primary = Color(0xFF7C4DFF);
  static const Color _accent = Color(0xFFFFC400);
  static const Color _gold = Color(0xFFFFD54F);
  static const String _kvKey = 'akasha_chronicle_v1';

  List<_JournalEntry> _entries = [];
  _Category _selectedCat = _categories[0];
  int _selectedMood = 3;
  final _textCtrl = TextEditingController();
  bool _loading = true;
  String? _filterCat;

  late final AnimationController _ambientCtrl;
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 11))..repeat();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _ambientCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kvKey) ?? const [];
    final out = <_JournalEntry>[];
    for (final s in raw) {
      try {
        out.add(_JournalEntry.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {}
    }
    if (mounted) setState(() { _entries = out; _loading = false; });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _entries.take(200).map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_kvKey, list);
  }

  int get _currentStreak {
    if (_entries.isEmpty) return 0;
    final sorted = [..._entries]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    int streak = 0;
    var checkDay = DateTime.now();
    for (final e in sorted) {
      final eDay = DateTime.parse(e.createdAt);
      // Same day or yesterday from checkDay
      final diff = checkDay.difference(eDay).inDays;
      if (diff == 0) {
        if (streak == 0) streak = 1;
      } else if (diff == 1 && streak > 0) {
        streak++;
        checkDay = eDay;
      } else if (diff > 1) {
        break;
      }
    }
    return streak;
  }

  Future<void> _addEntry() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.mediumImpact();
    final entry = _JournalEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      category: _selectedCat.code,
      mood: _selectedMood,
      text: text,
      reflection: null,
      createdAt: DateTime.now().toIso8601String(),
    );
    setState(() {
      _entries.insert(0, entry);
      _textCtrl.clear();
    });
    await _persist();
    // Spirit-Readings (cloud)
    try {
      final username = UnifiedStorageService().getUsername('energie');
      final userId = await UnifiedStorageService().getCurrentUserId() ?? 'anonym';
      await SpiritReadingService.instance.save(
        userId: userId,
        username: username,
        tool: 'akasha',
        summary: '${_selectedCat.emoji} ${_selectedCat.label} · Mood $_selectedMood',
        result: {
          'category': _selectedCat.code,
          'mood': _selectedMood,
          'text': text,
        },
      );
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🌌 Eintrag in Akasha-Chronik gespeichert · Streak $_currentStreak'),
      backgroundColor: _primary,
    ));
  }

  Future<void> _requestReflection(_JournalEntry entry) async {
    HapticFeedback.selectionClick();
    final idx = _entries.indexWhere((e) => e.id == entry.id);
    if (idx < 0) return;
    setState(() {
      _entries[idx] = _entries[idx].copyWith(reflectionLoading: true);
    });
    try {
      final prompt = StringBuffer()
        ..writeln('Reflektiere folgenden Tagebuch-Eintrag aus spiritueller Sicht:')
        ..writeln('Kategorie: ${_categories.firstWhere((c) => c.code == entry.category, orElse: () => _categories[0]).label}')
        ..writeln('Stimmung: ${entry.mood}/5')
        ..writeln('Text:')
        ..writeln('"${entry.text}"')
        ..writeln('')
        ..writeln('Gib eine warme, präzise Reflexion in 3-4 Sätzen. '
            'Spiegele das Wesentliche, biete eine Frage zur Vertiefung an. '
            'Du-Form, ohne esoterischen Kitsch, ohne Disclaimer.');
      final token = Supabase.instance.client.auth.currentSession?.accessToken ?? '';
      final res = await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/mentor/chat'),
            headers: {
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'personality': 'alchemist',
              'message': prompt.toString(),
              'world': 'energie',
              'conversationHistory': [],
            }),
          )
          .timeout(const Duration(seconds: 30));
      String? reflection;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        reflection = ((data['reply'] ?? data['answer'] ?? data['response'] ?? data['message'] ?? '') as String).trim();
      } else {
        reflection = '⚠️ AI nicht verfügbar (HTTP ${res.statusCode})';
      }
      if (!mounted) return;
      setState(() {
        final i = _entries.indexWhere((e) => e.id == entry.id);
        if (i >= 0) {
          _entries[i] = _entries[i].copyWith(reflection: reflection, reflectionLoading: false);
        }
      });
      await _persist();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        final i = _entries.indexWhere((e) => e.id == entry.id);
        if (i >= 0) {
          _entries[i] = _entries[i].copyWith(
              reflection: '⚠️ Netzwerk: $e', reflectionLoading: false);
        }
      });
    }
  }

  Future<void> _deleteEntry(_JournalEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1428),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eintrag löschen?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Lokal entfernt — bereits gespeicherte Cloud-Einträge bleiben im Akasha-Tagebuch.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    ) ?? false;
    if (ok) {
      setState(() => _entries.removeWhere((e) => e.id == entry.id));
      await _persist();
    }
  }

  List<_JournalEntry> get _filtered {
    if (_filterCat == null) return _entries;
    return _entries.where((e) => e.category == _filterCat).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: WBWorld.energie,
        titleWidget: ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [_gold, _primary, _accent],
          ).createShader(r),
          child: const Text('AKASHA-CHRONIK',
              style: TextStyle(
                  color: Colors.white, fontSize: 14,
                  fontWeight: FontWeight.w900, letterSpacing: 3)),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Cosmic gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.4),
                radius: 1.5,
                colors: [Color(0x553D1F8C), Color(0x331A0833), _bg],
              ),
            ),
          ),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _ambientCtrl,
              builder: (_, __) => CustomPaint(
                painter: _CosmicOrbsPainter(_ambientCtrl.value),
                size: Size.infinite,
              ),
            ),
          ),
          const IgnorePointer(child: WBAmbientParticles(world: WBWorld.energie, count: 50)),
          SafeArea(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: _primary))
                : _content(),
          ),
          const IgnorePointer(child: WBVignette()),
        ],
      ),
    );
  }

  Widget _content() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _streakMoodHeader()),
        SliverToBoxAdapter(child: _entryComposer()),
        SliverToBoxAdapter(child: _filterRow()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
          sliver: _filtered.isEmpty
              ? SliverToBoxAdapter(child: _emptyHint())
              : SliverList.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _entryCard(_filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _streakMoodHeader() {
    final streak = _currentStreak;
    final last30 = _moodChart30Days();
    final entriesTotal = _entries.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primary.withValues(alpha: 0.2), _accent.withValues(alpha: 0.08)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(children: [
              Row(children: [
                _metric('🔥 Streak', '$streak', 'Tag${streak == 1 ? "" : "e"}'),
                _metric('📖 Einträge', '$entriesTotal', 'gesamt'),
                _metric('💗 Ø Mood',
                    entriesTotal == 0 ? '–' : (last30.where((e) => e > 0).fold<int>(0, (s, e) => s + e) / math.max(1, last30.where((e) => e > 0).length)).toStringAsFixed(1), '/ 5'),
              ]),
              const SizedBox(height: 12),
              const Text('STIMMUNG · 30 TAGE',
                  style: TextStyle(color: _gold, fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              SizedBox(
                height: 38,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: last30.map((m) {
                    final h = m == 0 ? 3.0 : 5.0 + (m / 5) * 28;
                    final col = m == 0
                        ? Colors.white.withValues(alpha: 0.08)
                        : _moodColor(m);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Container(
                          height: h,
                          decoration: BoxDecoration(
                            color: col,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _metric(String label, String value, String unit) {
    return Expanded(
      child: Column(children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text(value,
              style: const TextStyle(color: _gold, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(width: 3),
          Text(unit, style: const TextStyle(color: Colors.white54, fontSize: 9)),
        ]),
      ]),
    );
  }

  List<int> _moodChart30Days() {
    final map = <String, int>{};
    for (final e in _entries) {
      final d = e.createdAt.substring(0, 10);
      // Letzten Eintrag des Tages
      map[d] = e.mood;
    }
    final result = <int>[];
    for (int i = 29; i >= 0; i--) {
      final dt = DateTime.now().subtract(Duration(days: i));
      final key = dt.toIso8601String().substring(0, 10);
      result.add(map[key] ?? 0);
    }
    return result;
  }

  Color _moodColor(int m) {
    if (m <= 1) return const Color(0xFF455A64);
    if (m == 2) return const Color(0xFF1976D2);
    if (m == 3) return const Color(0xFF7C4DFF);
    if (m == 4) return const Color(0xFFFFA726);
    return const Color(0xFFFFC400);
  }

  String _moodEmoji(int m) {
    switch (m) {
      case 1: return '😔'; case 2: return '😐';
      case 3: return '🙂'; case 4: return '😊';
      default: return '✨';
    }
  }

  Widget _entryComposer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Kategorie + Mood
              Row(children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (_, i) {
                        final c = _categories[i];
                        final sel = c.code == _selectedCat.code;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedCat = c);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: sel
                                    ? LinearGradient(colors: [c.color.withValues(alpha: 0.6), c.color.withValues(alpha: 0.2)])
                                    : null,
                                color: sel ? null : Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: sel ? c.color : Colors.transparent),
                              ),
                              child: Row(children: [
                                Text(c.emoji, style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                Text(c.label,
                                    style: TextStyle(color: sel ? Colors.white : Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              // Mood
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (i) {
                  final m = i + 1;
                  final sel = m == _selectedMood;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedMood = m);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: sel ? _moodColor(m).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
                        border: Border.all(color: sel ? _moodColor(m) : Colors.transparent, width: 2),
                      ),
                      child: Center(
                        child: Text(_moodEmoji(m), style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _textCtrl,
                maxLines: 4,
                maxLength: 1500,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Was passiert in deinem inneren Universum?',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.04),
                  counterStyle: const TextStyle(color: Colors.white24, fontSize: 9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addEntry,
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('IN AKASHA EINTRAGEN',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedCat.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _filterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Row(children: [
        const Text('FILTER',
            style: TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 2)),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 28,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterPill('Alle', null),
                ..._categories.map((c) => _filterPill('${c.emoji} ${c.label}', c.code)),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _filterPill(String label, String? code) {
    final sel = code == _filterCat;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _filterCat = code),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: sel ? _primary.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? _primary : Colors.transparent),
          ),
          child: Text(label,
              style: TextStyle(color: sel ? Colors.white : Colors.white60, fontSize: 10, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _emptyHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(children: [
        Icon(Icons.auto_stories_rounded, color: _primary.withValues(alpha: 0.4), size: 60),
        const SizedBox(height: 14),
        const Text('Deine Chronik ist noch unbeschrieben.',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 4),
        const Text('Schreibe deinen ersten Eintrag oben.',
            style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _entryCard(_JournalEntry entry) {
    final cat = _categories.firstWhere((c) => c.code == entry.category, orElse: () => _categories[0]);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cat.color.withValues(alpha: 0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cat.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cat.color.withValues(alpha: 0.5)),
                  ),
                  child: Text('${cat.emoji} ${cat.label}',
                      style: TextStyle(color: cat.color, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Text(_moodEmoji(entry.mood), style: const TextStyle(fontSize: 16)),
                const Spacer(),
                Text(_fmt(entry.createdAt),
                    style: const TextStyle(color: Colors.white54, fontSize: 10)),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded, color: Colors.white38, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showEntryActions(entry),
                ),
              ]),
              const SizedBox(height: 10),
              SelectableText(entry.text,
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5)),
              const SizedBox(height: 10),
              if (entry.reflection != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.auto_awesome_rounded, color: _gold, size: 12),
                      const SizedBox(width: 4),
                      Text('ALCHEMIST · REFLEXION',
                          style: TextStyle(color: _gold.withValues(alpha: 0.9), fontSize: 8, letterSpacing: 2, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 6),
                    SelectableText(entry.reflection!,
                        style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.6, fontStyle: FontStyle.italic)),
                  ]),
                ),
              ] else if (entry.reflectionLoading == true) ...[
                AnimatedBuilder(
                  animation: _glowCtrl,
                  builder: (_, __) => Row(children: [
                    Icon(Icons.auto_awesome,
                        color: _primary.withValues(alpha: 0.5 + 0.3 * _glowCtrl.value), size: 14),
                    const SizedBox(width: 6),
                    Text('Alchemist reflektiert…',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5 + 0.3 * _glowCtrl.value), fontSize: 11)),
                  ]),
                ),
              ] else
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _requestReflection(entry),
                    icon: const Icon(Icons.auto_awesome_rounded, color: _gold, size: 14),
                    label: const Text('AI-Reflexion',
                        style: TextStyle(color: _gold, fontSize: 11, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showEntryActions(_JournalEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (entry.reflection == null)
            ListTile(
              leading: const Icon(Icons.auto_awesome_rounded, color: _gold),
              title: const Text('AI-Reflexion holen', style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(ctx); _requestReflection(entry); },
            ),
          ListTile(
            leading: const Icon(Icons.copy_rounded, color: Colors.white70),
            title: const Text('In Zwischenablage', style: TextStyle(color: Colors.white)),
            onTap: () {
              Clipboard.setData(ClipboardData(text: entry.text));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('📋 Kopiert'),
                backgroundColor: _primary,
              ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            title: const Text('Lokal löschen', style: TextStyle(color: Colors.redAccent)),
            onTap: () { Navigator.pop(ctx); _deleteEntry(entry); },
          ),
        ]),
      ),
    );
  }

  String _fmt(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 2) return 'jetzt';
      if (diff.inHours < 1) return 'vor ${diff.inMinutes}m';
      if (diff.inHours < 24) return 'vor ${diff.inHours}h';
      return '${dt.day.toString().padLeft(2,'0')}.${dt.month.toString().padLeft(2,'0')}. ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return ''; }
  }
}

class _Category {
  final String code;
  final String label;
  final String emoji;
  final Color color;
  const _Category(this.code, this.label, this.emoji, this.color);
}

const List<_Category> _categories = [
  _Category('insight',    'Insight',     '💡', Color(0xFFFFC400)),
  _Category('dream',      'Traum',       '🌙', Color(0xFF7C4DFF)),
  _Category('meditation', 'Meditation',  '🧘', Color(0xFF26C6DA)),
  _Category('question',   'Frage',       '❓', Color(0xFF42A5F5)),
  _Category('vision',     'Vision',      '👁️', Color(0xFFAB47BC)),
  _Category('synchro',    'Synchro',     '🔮', Color(0xFFEC407A)),
  _Category('gratitude',  'Dankbarkeit', '🙏', Color(0xFF66BB6A)),
];

class _JournalEntry {
  final String id;
  final String category;
  final int mood; // 1..5
  final String text;
  final String? reflection;
  final bool? reflectionLoading;
  final String createdAt;
  const _JournalEntry({
    required this.id,
    required this.category,
    required this.mood,
    required this.text,
    required this.reflection,
    this.reflectionLoading,
    required this.createdAt,
  });
  _JournalEntry copyWith({String? reflection, bool? reflectionLoading}) => _JournalEntry(
        id: id, category: category, mood: mood, text: text,
        reflection: reflection ?? this.reflection,
        reflectionLoading: reflectionLoading,
        createdAt: createdAt,
      );
  Map<String, dynamic> toJson() => {
        'id': id, 'category': category, 'mood': mood,
        'text': text, 'reflection': reflection, 'createdAt': createdAt,
      };
  factory _JournalEntry.fromJson(Map<String, dynamic> j) => _JournalEntry(
        id: j['id'] as String? ?? '${DateTime.now().millisecondsSinceEpoch}',
        category: j['category'] as String? ?? 'insight',
        mood: (j['mood'] as int?) ?? 3,
        text: j['text'] as String? ?? '',
        reflection: j['reflection'] as String?,
        createdAt: j['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      );
}

class _CosmicOrbsPainter extends CustomPainter {
  final double t;
  _CosmicOrbsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _draw(canvas, Offset(size.width * 0.18, size.height * (0.3 + math.sin(t * 2 * math.pi) * 0.05)),
        120, const Color(0xFF7C4DFF));
    _draw(canvas, Offset(size.width * 0.86, size.height * (0.55 + math.cos(t * 2 * math.pi) * 0.04)),
        100, const Color(0xFFFFC400));
    _draw(canvas, Offset(size.width * 0.5, size.height * (0.92 + math.sin(t * math.pi) * 0.03)),
        85, const Color(0xFFEC407A));
  }

  void _draw(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5);
    canvas.drawCircle(c, r, p);
  }

  @override
  bool shouldRepaint(_CosmicOrbsPainter old) => old.t != t;
}
