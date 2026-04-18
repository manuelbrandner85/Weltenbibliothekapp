import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/soul_numerology_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SoulContractToolScreen – 3 Tabs
//   Tab 0: Neu    (Name + Geburtsdatum → Seelenvertrag berechnen)
//   Tab 1: Verlauf (gespeicherte Seelenverträge aus soul_contracts)
//   Tab 2: Zahlen (numerologisches Lexikon mit Kategorie-Filter)
// ─────────────────────────────────────────────────────────────────────────────

const _kGold = Color(0xFFFFB300);
const _kDarkBg = Color(0xFF0A0A0F);
const _kCardBg = Color(0xFF1A1A2E);
const _kBorder = Color(0xFF2A2A4E);

final _db = Supabase.instance.client;

class SoulContractToolScreen extends StatefulWidget {
  const SoulContractToolScreen({super.key});

  @override
  State<SoulContractToolScreen> createState() =>
      _SoulContractToolScreenState();
}

class _SoulContractToolScreenState extends State<SoulContractToolScreen>
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
        title: const Text('📜 Seelenvertrag',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _kGold,
          labelColor: _kGold,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.auto_awesome), text: 'Neu'),
            Tab(icon: Icon(Icons.history), text: 'Verlauf'),
            Tab(icon: Icon(Icons.menu_book), text: 'Zahlen'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _NewContractTab(),
          _HistoryTab(),
          _NumbersGuideTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 0: Neu  (Phase 5.2b füllt diesen Stub)
// ─────────────────────────────────────────────────────────────────────────────

class _NewContractTab extends StatefulWidget {
  const _NewContractTab();
  @override
  State<_NewContractTab> createState() => _NewContractTabState();
}

class _NewContractTabState extends State<_NewContractTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  DateTime? _birthDate;
  SoulNumerologyResult? _result;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: _kGold,
            onPrimary: Colors.black,
            surface: _kCardBg,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  void _compute() {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bitte Geburtsdatum wählen')));
      return;
    }
    try {
      final r = SoulNumerology.compute(
        fullName: _nameCtrl.text,
        birthDate: _birthDate!,
      );
      setState(() => _result = r);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Berechnungs-Fehler: $e')));
    }
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '📜 Seelenvertrag erstellen',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Vollständiger Geburtsname + Geburtsdatum → Numerologie des Seelenvertrags.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            // Name
            TextFormField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco(
                  label: 'Vollständiger Geburtsname',
                  hint: 'z. B. Maria Elisabeth Schmidt'),
              validator: (v) {
                if (v == null || v.trim().length < 2) {
                  return 'Bitte vollen Namen eingeben';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Birthdate
            InkWell(
              onTap: _pickBirthDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorder),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_month, color: _kGold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _birthDate == null
                          ? 'Geburtsdatum wählen'
                          : _formatDate(_birthDate!),
                      style: TextStyle(
                          color: _birthDate == null
                              ? Colors.white54
                              : Colors.white,
                          fontSize: 15),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white38),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              child: ElevatedButton.icon(
                onPressed: _compute,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Berechnen'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 24),
              _ResultPreview(result: _result!),
              const SizedBox(height: 16),
              SizedBox(
                child: ElevatedButton.icon(
                  onPressed: () => _showDeepResult(_result!),
                  icon: const Icon(Icons.menu_book),
                  label: const Text('Deutung & Speichern'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _kCardBg,
                      foregroundColor: _kGold,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: _kGold))),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadMeanings(
      SoulNumerologyResult r) async {
    // Lade genau die relevanten (number, category)-Kombinationen.
    final wanted = <List<dynamic>>[
      [r.lifePath, 'life_path'],
      [r.destiny, 'destiny'],
      [r.soulUrge, 'soul_urge'],
      [r.personality, 'personality'],
      ...r.karmicDebts.map((n) => [n, 'karmic_debt']),
    ];
    final rows = await _db
        .from('soul_number_meanings')
        .select('number, category, title, keywords, short_text, deep_text, practice_text');
    final byKey = <String, Map<String, dynamic>>{
      for (final m in rows)
        '${m['number']}_${m['category']}': Map<String, dynamic>.from(m)
    };
    final out = <Map<String, dynamic>>[];
    for (final w in wanted) {
      final key = '${w[0]}_${w[1]}';
      final m = byKey[key];
      if (m != null) out.add(m);
    }
    return out;
  }

  Future<void> _saveContract(SoulNumerologyResult r, String notes) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Nicht angemeldet');
    await _db.from('soul_contracts').insert({
      'user_id': user.id,
      'full_name': _nameCtrl.text.trim(),
      'birth_date': _birthDate!.toIso8601String().split('T').first,
      'life_path': r.lifePath,
      'destiny': r.destiny,
      'soul_urge': r.soulUrge,
      'personality': r.personality,
      'birth_day': r.birthDay,
      'karmic_debts': r.karmicDebts,
      'computation': r.computation,
      'notes': notes.trim().isEmpty ? null : notes.trim(),
    });
  }

  void _showDeepResult(SoulNumerologyResult r) {
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
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, sc) => FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadMeanings(r),
            builder: (_, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(
                    child: CircularProgressIndicator(color: _kGold));
              }
              if (snap.hasError) {
                return Center(
                    child: Text('Fehler: ${snap.error}',
                        style: const TextStyle(color: Colors.white54)));
              }
              final meanings = snap.data ?? [];
              return ListView(
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
                  const Text('📜 Deutung deines Seelenvertrags',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...meanings.map((m) => _MeaningCard(meaning: m)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesCtrl,
                    enabled: !saving && !saved,
                    maxLines: 3,
                    minLines: 2,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Optionale Notiz …',
                      hintStyle: const TextStyle(
                          color: Colors.white38, fontSize: 13),
                      filled: true,
                      fillColor: _kDarkBg,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: _kBorder)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: _kBorder)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: _kGold)),
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
                                await _saveContract(r, notesCtrl.text);
                                if (!sheetCtx2.mounted) return;
                                setSheet(() {
                                  saving = false;
                                  saved = true;
                                });
                                ScaffoldMessenger.of(sheetCtx2).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            '✅ Seelenvertrag gespeichert')));
                              } catch (e) {
                                if (!sheetCtx2.mounted) return;
                                setSheet(() => saving = false);
                                ScaffoldMessenger.of(sheetCtx2).showSnackBar(
                                    SnackBar(
                                        content: Text('Fehler: $e')));
                              }
                            },
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black))
                          : Icon(saved ? Icons.check_circle : Icons.save),
                      label: Text(saving
                          ? 'Speichern …'
                          : (saved ? 'Gespeichert' : 'Vertrag speichern')),
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              saved ? Colors.green : _kGold,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor:
                              saved ? Colors.green : _kBorder,
                          disabledForegroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12))),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ).whenComplete(() => notesCtrl.dispose());
  }

  InputDecoration _inputDeco({required String label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: _kCardBg,
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
        borderSide: const BorderSide(color: _kGold),
      ),
    );
  }
}

// Phase 5.2d füllt dieses Preview komplett aus (mit Meaning-Rows + Save)
class _ResultPreview extends StatelessWidget {
  final SoulNumerologyResult result;
  const _ResultPreview({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kGold.withValues(alpha: 0.4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dein Seelenvertrag (Zahlen)',
              style: TextStyle(
                  color: _kGold,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _ResultRow(
              label: 'Lebensweg', value: result.lifePath.toString()),
          _ResultRow(label: 'Ausdruck', value: result.destiny.toString()),
          _ResultRow(
              label: 'Seelenantrieb', value: result.soulUrge.toString()),
          _ResultRow(
              label: 'Persönlichkeit',
              value: result.personality.toString()),
          _ResultRow(
              label: 'Geburtstag', value: result.birthDay.toString()),
          if (result.karmicDebts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Karmische Schulden: ${result.karmicDebts.join(', ')}',
              style: const TextStyle(
                  color: Colors.orangeAccent, fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Tippe im nächsten Schritt „Deutung ansehen" für die detaillierten Texte (Phase 5.2c/d).',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14)),
          ),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _kDarkBg,
              shape: BoxShape.circle,
              border: Border.all(color: _kGold),
            ),
            child: Text(value,
                style: const TextStyle(
                    color: _kGold,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Verlauf (Phase 5.2e füllt diesen Stub)
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Verlauf – Phase 5.2e',
          style: TextStyle(color: Colors.white38)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Zahlen-Guide (Phase 5.2f füllt diesen Stub)
// ─────────────────────────────────────────────────────────────────────────────

class _NumbersGuideTab extends StatelessWidget {
  const _NumbersGuideTab();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Zahlen – Phase 5.2f',
          style: TextStyle(color: Colors.white38)),
    );
  }
}

const _kCategoryLabels = <String, String>{
  'life_path': '🌟 Lebensweg',
  'destiny': '🎯 Ausdruck',
  'soul_urge': '💖 Seelenantrieb',
  'personality': '🎭 Persönlichkeit',
  'birth_day': '🌙 Geburtstag',
  'karmic_debt': '⚖️ Karmische Schuld',
  'master': '✨ Meisterzahl',
};

class _MeaningCard extends StatelessWidget {
  final Map<String, dynamic> meaning;
  const _MeaningCard({required this.meaning});

  @override
  Widget build(BuildContext context) {
    final cat = meaning['category'] as String? ?? '';
    final catLabel = _kCategoryLabels[cat] ?? cat;
    final number = meaning['number'];
    final title = meaning['title'] as String? ?? '';
    final keywords = (meaning['keywords'] as List?) ?? const [];
    final shortText = meaning['short_text'] as String? ?? '';
    final deepText = meaning['deep_text'] as String? ?? '';
    final practice = meaning['practice_text'] as String?;
    final isKarmic = cat == 'karmic_debt';
    final accent = isKarmic ? Colors.orangeAccent : _kGold;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _kDarkBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: _kCardBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 2)),
              child: Text('$number',
                  style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(catLabel,
                      style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ]),
          if (keywords.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: keywords
                  .map((k) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: _kCardBg,
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: _kBorder)),
                        child: Text('$k',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 10),
          Text(shortText,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 8),
          Text(deepText,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13, height: 1.4)),
          if (practice != null && practice.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.lightGreenAccent
                          .withValues(alpha: 0.4))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🌱 Praxis',
                      style: TextStyle(
                          color: Colors.lightGreenAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(practice,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.35)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
