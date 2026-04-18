import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BodyScanToolScreen – 3 Tabs
//   Tab 0: Scan    (Symptome wählen → Chakra-Score berechnen)
//   Tab 1: Verlauf (vergangene Scans aus body_scan_results)
//   Tab 2: Info    (statisches Chakra-Lexikon)
// ─────────────────────────────────────────────────────────────────────────────

const _kPink = Color(0xFFE91E63);
const _kDarkBg = Color(0xFF0A0A0F);
const _kCardBg = Color(0xFF1A1A2E);

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

class _ScanTab extends StatelessWidget {
  const _ScanTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Scan-Tab – Phase 7.2b',
            style: TextStyle(color: Colors.white38),
            textAlign: TextAlign.center),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Verlauf (Phase 7.2e füllt diesen Stub)
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Verlauf – Phase 7.2e',
          style: TextStyle(color: Colors.white38)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Info (Phase 7.2f füllt diesen Stub)
// ─────────────────────────────────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  const _InfoTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Chakra-Info – Phase 7.2f',
          style: TextStyle(color: Colors.white38)),
    );
  }
}
