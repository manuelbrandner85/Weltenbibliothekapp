// Crystal-Ritual: Schritt-fuer-Schritt-Anleitung pro Kristall.
// Bereich K5 -- Cleansing -> Aufladen -> Programmierung -> Anwendung -> Pflege.

import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/crystal_library.dart';
import '../../../services/streak_tracking_service.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';
import '../../../theme/wb_cinematic_tokens.dart';

class CrystalRitualScreen extends StatefulWidget {
  final CrystalEntry crystal;
  const CrystalRitualScreen({super.key, required this.crystal});

  @override
  State<CrystalRitualScreen> createState() => _CrystalRitualScreenState();
}

class _CrystalRitualScreenState extends State<CrystalRitualScreen> {
  int _step = 0;
  bool _inCollection = false;

  static const _gold = Color(0xFFC9A84C);
  static const _kStorageKey = 'my_crystals_v1';

  @override
  void initState() {
    super.initState();
    StreakTrackingService().trackToolUsage('crystal_ritual');
    _checkCollection();
  }

  Future<void> _checkCollection() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kStorageKey);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List).cast<String>();
      if (mounted && list.contains(widget.crystal.name)) {
        setState(() => _inCollection = true);
      }
    } catch (_) {}
  }

  Future<void> _toggleCollection() async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kStorageKey);
    final names = raw == null
        ? <String>[]
        : ((jsonDecode(raw) as List).cast<String>());
    if (names.contains(widget.crystal.name)) {
      names.remove(widget.crystal.name);
    } else {
      names.add(widget.crystal.name);
    }
    await prefs.setString(_kStorageKey, jsonEncode(names));
    if (!mounted) return;
    setState(() => _inCollection = names.contains(widget.crystal.name));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_inCollection
          ? '${widget.crystal.name} zu deiner Sammlung hinzugefuegt'
          : 'Aus Sammlung entfernt'),
      backgroundColor: _gold,
      duration: const Duration(seconds: 2),
    ));
  }

  List<_RitualStep> get _steps {
    final c = widget.crystal;
    return [
      _RitualStep(
        icon: Icons.cleaning_services_rounded,
        title: '1. Reinigung',
        subtitle: 'Reinige deinen Kristall vor erster Nutzung',
        body: c.cleansing,
        accent: const Color(0xFF4FC3F7),
      ),
      _RitualStep(
        icon: Icons.bolt_rounded,
        title: '2. Aufladen',
        subtitle: 'Energetisch wieder aktivieren',
        body: c.charging,
        accent: const Color(0xFFFFD54F),
      ),
      _RitualStep(
        icon: Icons.psychology_rounded,
        title: '3. Programmieren',
        subtitle: 'Intention klar setzen',
        body: 'Nimm den Kristall in deine dominante Hand. Schliesse die '
            'Augen. Formuliere deine Intention konkret und positiv -- '
            'z.B. "Dieser ${c.name} schenkt mir ${c.intentions.isNotEmpty ? c.intentions.first.toLowerCase() : "Klarheit"}". '
            'Sprich oder denke die Intention 3x klar.',
        accent: const Color(0xFFCE93D8),
      ),
      _RitualStep(
        icon: Icons.favorite_rounded,
        title: '4. Anwendung',
        subtitle: 'So nutzt du ihn taeglich',
        body: c.howToUse.isNotEmpty
            ? c.howToUse
            : 'In der Hosentasche tragen, am Koerper als Schmuck oder '
                'auf das entsprechende Chakra legen (${c.chakra ?? "Herz"}).',
        accent: const Color(0xFF81C784),
      ),
      _RitualStep(
        icon: Icons.shield_outlined,
        title: '5. Pflege & Vorsicht',
        subtitle: 'Was du beachten musst',
        body: c.careNote.isNotEmpty
            ? c.careNote
            : 'Sanft mit trockenem Tuch reinigen. Regelmaessig (alle '
                '2 Wochen) energetisch reinigen. Bei Beschaedigung neu '
                'aufladen.',
        accent: c.careNote.isNotEmpty
            ? Colors.orangeAccent
            : const Color(0xFF8D6E63),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.crystal;
    return Scaffold(
      backgroundColor: const Color(0xFF06040F),
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        title: c.name,
        world: WBWorld.energie,
        actions: [
          IconButton(
            icon: Icon(
              _inCollection ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
              color: _gold,
            ),
            tooltip: _inCollection ? 'Aus Sammlung entfernen' : 'Zu Meine Kristalle',
            onPressed: _toggleCollection,
          ),
        ],
      ),
      body: Stack(
        children: [
          const IgnorePointer(
              child: WBAmbientParticles(world: WBWorld.energie, count: 24)),
          const WBVignette(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
              child: Column(
                children: [
                  _hero(c),
                  const SizedBox(height: 14),
                  _stepIndicator(),
                  const SizedBox(height: 14),
                  Expanded(child: _stepCard(_steps[_step])),
                  const SizedBox(height: 10),
                  _navRow(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(CrystalEntry c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          c.displayColor.withValues(alpha: 0.3),
          c.displayColor.withValues(alpha: 0.06),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.displayColor.withValues(alpha: 0.5)),
      ),
      child: Row(children: [
        Text(c.emoji, style: const TextStyle(fontSize: 44)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
              Text(
                [c.chakra, c.element].where((e) => e != null).join(' · '),
                style: TextStyle(
                    color: c.displayColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(c.spiritualEffect,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _stepIndicator() {
    return Row(children: List.generate(_steps.length, (i) {
      final active = i == _step;
      final past = i < _step;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _step = i),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 6,
            decoration: BoxDecoration(
              color: (active || past) ? _gold : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      );
    }));
  }

  Widget _stepCard(_RitualStep s) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: s.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: s.accent.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 42, height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: s.accent.withValues(alpha: 0.25),
                  ),
                  child: Icon(s.icon, color: s.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.title,
                          style: TextStyle(
                              color: s.accent,
                              fontSize: 16,
                              fontWeight: FontWeight.w900)),
                      Text(s.subtitle,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(s.body,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          height: 1.65)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navRow() {
    return Row(children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: _step > 0 ? () => setState(() => _step--) : null,
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Zurueck'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _step < _steps.length - 1
              ? () => setState(() => _step++)
              : null,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text('Weiter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _gold,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    ]);
  }
}

class _RitualStep {
  final IconData icon;
  final String title;
  final String subtitle;
  final String body;
  final Color accent;
  const _RitualStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.accent,
  });
}
