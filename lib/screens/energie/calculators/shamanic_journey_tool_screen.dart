import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ShamanicJourneyToolScreen – 3 Tabs
//   Tab 0: Neu        (Reise starten: Guide wählen, Intention, Timer, Journal)
//   Tab 1: Verlauf    (frühere Reisen + Krafttiere)
//   Tab 2: Leitfäden  (6 öffentliche Guides)
// ─────────────────────────────────────────────────────────────────────────────

const _kDeep = Color(0xFF8E5AE2);
const _kDarkBg = Color(0xFF0A0A0F);
const _kCardBg = Color(0xFF1A1A2E);
const _kBorder = Color(0xFF2A2A4E);

final _db = Supabase.instance.client;

class ShamanicJourneyToolScreen extends StatefulWidget {
  const ShamanicJourneyToolScreen({super.key});

  @override
  State<ShamanicJourneyToolScreen> createState() =>
      _ShamanicJourneyToolScreenState();
}

class _ShamanicJourneyToolScreenState extends State<ShamanicJourneyToolScreen>
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
        title: const Text('🥁 Schamanische Reise',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _kDeep,
          labelColor: _kDeep,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.play_circle_outline), text: 'Neu'),
            Tab(icon: Icon(Icons.history), text: 'Verlauf'),
            Tab(icon: Icon(Icons.menu_book), text: 'Leitfäden'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _NewJourneyTab(),
          _JourneyHistoryTab(),
          _GuidesTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 0: Neu  (Phase 2.2b)
// ─────────────────────────────────────────────────────────────────────────────

class _NewJourneyTab extends StatelessWidget {
  const _NewJourneyTab();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Neu-Tab folgt in Phase 2.2b',
            style: TextStyle(color: Colors.white54),
            textAlign: TextAlign.center),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Verlauf  (Phase 2.2c)
// ─────────────────────────────────────────────────────────────────────────────

class _JourneyHistoryTab extends StatelessWidget {
  const _JourneyHistoryTab();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Verlauf-Tab folgt in Phase 2.2c',
            style: TextStyle(color: Colors.white54),
            textAlign: TextAlign.center),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Leitfäden  (Phase 2.2d)
// ─────────────────────────────────────────────────────────────────────────────

class _GuidesTab extends StatelessWidget {
  const _GuidesTab();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Leitfäden-Tab folgt in Phase 2.2d',
            style: TextStyle(color: Colors.white54),
            textAlign: TextAlign.center),
      ),
    );
  }
}
