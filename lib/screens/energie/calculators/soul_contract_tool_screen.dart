import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class _NewContractTab extends StatelessWidget {
  const _NewContractTab();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Neu – Phase 5.2b',
          style: TextStyle(color: Colors.white38)),
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
