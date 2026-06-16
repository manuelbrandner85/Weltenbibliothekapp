// 📚 LERNREIHEN-INDEX
//
// Zentraler Einstiegspunkt für alle tagesweisen Lernpfade im Spirit-Tab.
// Listet alle Reihen mit Fortschrittsbalken aus SharedPreferences.
//
// The module catalog and progress live in LearningModuleService; the cards
// are rendered by the reusable LearningModuleCard widget. The layout adapts
// to the available width (single-column list on phones, multi-column grid on
// tablets / wide screens).

import 'package:flutter/material.dart';

import '../../../services/learning_module_service.dart';
import '../../../widgets/learning_module_card.dart';
import '../../../widgets/lesson_series_screen.dart';

class LernreihenIndexScreen extends StatefulWidget {
  const LernreihenIndexScreen({super.key});

  @override
  State<LernreihenIndexScreen> createState() => _LernreihenIndexScreenState();
}

class _LernreihenIndexScreenState extends State<LernreihenIndexScreen> {
  static const _bg = Color(0xFF06040F);
  static const _surface = Color(0xFF100B1E);

  final LearningModuleService _service = LearningModuleService.instance;

  Map<String, int> _progress = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final progress = await _service.loadProgress();
    if (mounted) {
      setState(() {
        _progress = progress;
        _loading = false;
      });
    }
  }

  void _openModule(LearningModule m) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonSeriesScreen(
          title: m.title,
          emoji: m.emoji,
          accent: m.accent,
          storageKey: m.storageKey,
          entries: m.entries,
          tradition: m.description,
        ),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final modules = _service.modules;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1530),
        title: const Row(
          children: [
            Text('📚', style: TextStyle(fontSize: 22)),
            SizedBox(width: 10),
            Text(
              'Lernreihen',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                // Responsive: one card per ~440px of width, capped at 3 columns.
                final columns = (constraints.maxWidth / 440).floor().clamp(
                  1,
                  3,
                );
                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      sliver: SliverToBoxAdapter(child: _buildIntro()),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisExtent: 124,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        delegate: SliverChildBuilderDelegate((context, i) {
                          final m = modules[i];
                          return LearningModuleCard(
                            module: m,
                            progress: _service.progressFor(m, _progress),
                            onTap: () => _openModule(m),
                          );
                        }, childCount: modules.length),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildIntro() {
    final totalEntries = _service.totalLessons;
    final completed = _service.completedLessons(_progress);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A1530), _surface]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tagesweise Lernpfade',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Jeder Pfad ist 7–64 Tage lang. Lies eine Lektion pro Tag, '
            'beantworte die Reflexionsfrage, hake ab. Fortschritt bleibt lokal.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$completed / $totalEntries Lektionen abgeschlossen',
            style: const TextStyle(
              color: Color(0xFF4DB6AC),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
