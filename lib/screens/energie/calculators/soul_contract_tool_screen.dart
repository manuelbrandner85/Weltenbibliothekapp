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
            ],
          ],
        ),
      ),
    );
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
