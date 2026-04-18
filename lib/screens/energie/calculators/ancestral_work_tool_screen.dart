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

class _AncestorsTab extends StatelessWidget {
  const _AncestorsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Ahnen-Tab folgt in Phase 4.2b',
          style: TextStyle(color: Colors.white54, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Muster  (Phase 4.2c)
// ─────────────────────────────────────────────────────────────────────────────

class _PatternsTab extends StatelessWidget {
  const _PatternsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Muster-Tab folgt in Phase 4.2c',
          style: TextStyle(color: Colors.white54, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Rituale  (Phase 4.2d)
// ─────────────────────────────────────────────────────────────────────────────

class _RitualsTab extends StatelessWidget {
  const _RitualsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Rituale-Tab folgt in Phase 4.2d',
          style: TextStyle(color: Colors.white54, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
