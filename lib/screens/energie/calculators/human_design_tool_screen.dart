import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HumanDesignToolScreen – Tool 3
//   Tab 0: Neu       (Geburtsdaten → Type/Profile/Authority/Centers/Gates)
//   Tab 1: Verlauf   (gespeicherte HD-Charts)
//   Tab 2: Lexikon   (Types, Authorities, Centers, 64 Gates)
// ─────────────────────────────────────────────────────────────────────────────

const _kTeal = Color(0xFF26C6DA);
const _kDarkBg = Color(0xFF0A0A0F);
const _kCardBg = Color(0xFF1A1A2E);

class HumanDesignToolScreen extends StatefulWidget {
  const HumanDesignToolScreen({super.key});

  @override
  State<HumanDesignToolScreen> createState() => _HumanDesignToolScreenState();
}

class _HumanDesignToolScreenState extends State<HumanDesignToolScreen>
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
        title: const Text('🌀 Human Design',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _kTeal,
          labelColor: _kTeal,
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
          _NewHdTab(),
          _HdHistoryTab(),
          _HdLexiconTab(),
        ],
      ),
    );
  }
}

class _NewHdTab extends StatelessWidget {
  const _NewHdTab();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Neues Human-Design-Chart anlegen…\n(Phase 3.2c)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16)),
      ),
    );
  }
}

class _HdHistoryTab extends StatelessWidget {
  const _HdHistoryTab();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Gespeicherte HD-Charts…\n(Phase 3.2d)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16)),
    );
  }
}

class _HdLexiconTab extends StatelessWidget {
  const _HdLexiconTab();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('HD-Lexikon…\n(Phase 3.2e)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16)),
    );
  }
}
