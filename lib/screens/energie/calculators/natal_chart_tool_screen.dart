import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NatalChartToolScreen – Geburtshoroskop (Tool 1)
//   Tab 0: Neu       (Geburtsdaten eingeben → berechnen → speichern)
//   Tab 1: Verlauf   (gespeicherte Charts laden / ansehen / löschen)
//   Tab 2: Lexikon   (Zeichen / Planeten-Bedeutungen)
// ─────────────────────────────────────────────────────────────────────────────

const _kIndigo = Color(0xFF6C63FF);
const _kDarkBg = Color(0xFF0A0A0F);
const _kCardBg = Color(0xFF1A1A2E);

class NatalChartToolScreen extends StatefulWidget {
  const NatalChartToolScreen({super.key});

  @override
  State<NatalChartToolScreen> createState() => _NatalChartToolScreenState();
}

class _NatalChartToolScreenState extends State<NatalChartToolScreen>
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
        title: const Text('♓ Geburtshoroskop',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _kIndigo,
          labelColor: _kIndigo,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.auto_awesome), text: 'Neu'),
            Tab(icon: Icon(Icons.history), text: 'Verlauf'),
            Tab(icon: Icon(Icons.menu_book), text: 'Lexikon'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _NewChartTab(),
          _HistoryTab(),
          _LexiconTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 0: Neu (Phase 1.2c) – Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _NewChartTab extends StatelessWidget {
  const _NewChartTab();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Neues Geburtshoroskop anlegen…\n(Phase 1.2c)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Verlauf (Phase 1.2d) – Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Gespeicherte Charts…\n(Phase 1.2d)',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70, fontSize: 16),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Lexikon (Phase 1.2e) – Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _LexiconTab extends StatelessWidget {
  const _LexiconTab();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Astrologie-Lexikon…\n(Phase 1.2e)',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70, fontSize: 16),
      ),
    );
  }
}
