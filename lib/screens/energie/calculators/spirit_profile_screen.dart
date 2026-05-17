// 🌟 SPIRIT-PROFIL — Konsolidierter Bericht aus 10 Analysen
//
// Ersetzt die früheren 10 separaten "Universal-Tool"-Karten (Energiefeld,
// Polaritäten, Transformation, Unterbewusstsein, Innere Karten, Zyklen,
// Orientierung, Meta-Spiegel, Wahrnehmung, Selbstbeobachtung). Alle nutzen
// die gleichen Profil-Inputs und produzieren austauschbare Numerologie-
// Prosa — daher ergibt EIN zusammengefasster Bericht mehr Sinn als 10
// Einzel-Klicks.

import 'package:flutter/material.dart';

import '../../../models/energie_profile.dart';
import '../../../services/mentor_service.dart';
import '../../../services/spirit_calculations/all_spirit_tools_engine.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/profile_required_widget.dart';
import '../../shared/mentor_chat_screen.dart';

class SpiritProfileScreen extends StatefulWidget {
  const SpiritProfileScreen({super.key});

  @override
  State<SpiritProfileScreen> createState() => _SpiritProfileScreenState();
}

class _SpiritProfileScreenState extends State<SpiritProfileScreen> {
  static const _bg = Color(0xFF06040F);
  static const _purple = Color(0xFF9C27B0);

  final _storage = StorageService();
  EnergieProfile? _profile;
  bool _loading = true;

  // Tab-Definitionen mit Engine-Call.
  static final List<_TabDef> _tabs = [
    _TabDef('Energiefeld', '⚡', const Color(0xFF00BCD4),
        (p) => AllSpiritToolsEngine.calculateEnergyField(p).interpretation),
    _TabDef('Polaritäten', '☯️', const Color(0xFFE91E63),
        (p) => AllSpiritToolsEngine.calculatePolarity(p).interpretation),
    _TabDef('Transformation', '🦋', const Color(0xFF9C27B0),
        (p) => AllSpiritToolsEngine.calculateTransformation(p).interpretation),
    _TabDef('Schatten', '🌑', const Color(0xFF4CAF50),
        (p) => AllSpiritToolsEngine.calculateUnconscious(p).interpretation),
    _TabDef('Innere Karten', '🧭', const Color(0xFFFF9800),
        (p) => AllSpiritToolsEngine.calculateInnerMaps(p).interpretation),
    _TabDef('Zyklen', '🔄', const Color(0xFF673AB7),
        (p) => AllSpiritToolsEngine.calculateCycles(p).interpretation),
    _TabDef('Orientierung', '🌀', const Color(0xFF2196F3),
        (p) => AllSpiritToolsEngine.calculateOrientation(p).interpretation),
    _TabDef('Meta-Spiegel', '🔗', const Color(0xFFFFD700),
        (p) => AllSpiritToolsEngine.calculateMetaMirror(p).interpretation),
    _TabDef('Wahrnehmung', '👁️', const Color(0xFF00BCD4),
        (p) => AllSpiritToolsEngine.calculatePerception(p).interpretation),
    _TabDef('Selbstbeobachtung', '🪞', const Color(0xFF9C27B0),
        (p) => AllSpiritToolsEngine.calculateSelfObservation(p).interpretation),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await _storage.loadEnergieProfile();
    if (!mounted) return;
    setState(() {
      _profile = p;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: _bg,
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: _purple,
          foregroundColor: Colors.white,
          icon: const Text('🧙', style: TextStyle(fontSize: 20)),
          label: const Text('Mit Mentor sprechen',
              style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MentorChatScreen(
                personality: MentorPersonality.alchemist,
                world: 'energie',
              ),
            ),
          ),
        ),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D0D1A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Row(
            children: [
              Text('🌟', style: TextStyle(fontSize: 22)),
              SizedBox(width: 10),
              Text('Spirit-Profil',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: _purple,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              for (final t in _tabs)
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(t.title,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: _purple),
              )
            : _profile == null
                ? ProfileRequiredWidget(
                    worldType: 'energie',
                    message: 'Energie-Profil erforderlich',
                    onProfileCreated: _load,
                  )
                : TabBarView(
                    children: [
                      for (final t in _tabs)
                        _InterpretationView(
                          accent: t.color,
                          interpretation: t.interpret(_profile!),
                        ),
                    ],
                  ),
      ),
    );
  }
}

class _TabDef {
  final String title;
  final String emoji;
  final Color color;
  final String Function(EnergieProfile) interpret;
  const _TabDef(this.title, this.emoji, this.color, this.interpret);
}

class _InterpretationView extends StatelessWidget {
  final Color accent;
  final String interpretation;
  const _InterpretationView({
    required this.accent,
    required this.interpretation,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.18),
              const Color(0xFF100B1E),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: SelectableText(
          interpretation,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.55,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}
