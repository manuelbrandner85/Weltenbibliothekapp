// Meine Kristall-Sammlung. Bereich K6.
// Liest 'my_crystals_v1' aus SharedPrefs (befuellt vom CrystalRitualScreen
// via Bookmark-Toggle).

import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/crystal_library.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import 'crystal_ritual_screen.dart';

class MyCrystalsScreen extends StatefulWidget {
  const MyCrystalsScreen({super.key});

  @override
  State<MyCrystalsScreen> createState() => _MyCrystalsScreenState();
}

class _MyCrystalsScreenState extends State<MyCrystalsScreen> {
  static const _kStorageKey = 'my_crystals_v1';
  List<CrystalEntry> _mine = [];
  bool _loading = true;
  static const _gold = Color(0xFFC9A84C);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kStorageKey);
      if (raw == null) {
        setState(() => _loading = false);
        return;
      }
      final names = (jsonDecode(raw) as List).cast<String>();
      final list = crystalLibrary.where((c) => names.contains(c.name)).toList();
      if (!mounted) return;
      setState(() {
        _mine = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(CrystalEntry c) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kStorageKey);
    if (raw == null) return;
    final names = (jsonDecode(raw) as List).cast<String>();
    names.remove(c.name);
    await prefs.setString(_kStorageKey, jsonEncode(names));
    _load();
  }

  Map<String, int> get _byChakra {
    final map = <String, int>{};
    for (final c in _mine) {
      final k = c.chakra ?? 'Sonstige';
      map[k] = (map[k] ?? 0) + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06040F),
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        title: 'Meine Kristalle',
        world: WBWorld.energie,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white60),
            onPressed: _load,
          ),
        ],
      ),
      body: Stack(
        children: [
          const IgnorePointer(
              child: WBAmbientParticles(world: WBWorld.energie, count: 24)),
          const WBVignette(),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _mine.isEmpty
                    ? _empty()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
                        children: [
                          _stats(),
                          const SizedBox(height: 14),
                          ..._mine.map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _crystalCard(c),
                              )),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_outline_rounded,
              size: 80, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 18),
          const Text(
              'Noch keine Kristalle gespeichert.\n\n'
              'Tippe auf das Lesezeichen-Symbol\n'
              'in einem Kristall-Ritual, um ihn zu deiner\n'
              'Sammlung hinzuzufuegen.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.white60, fontSize: 14, height: 1.55)),
        ],
      ),
    );
  }

  Widget _stats() {
    final byChakra = _byChakra;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.collections_bookmark_rounded,
                color: _gold, size: 22),
            const SizedBox(width: 10),
            Text('${_mine.length} Kristalle in deiner Sammlung',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
          ]),
          if (byChakra.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: byChakra.entries
                  .map((e) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${e.key}: ${e.value}',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _crystalCard(CrystalEntry c) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CrystalRitualScreen(crystal: c)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                c.displayColor.withValues(alpha: 0.18),
                Colors.white.withValues(alpha: 0.03),
              ]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.displayColor.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              Text(c.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                    Text(
                      [c.chakra, c.element].where((e) => e != null).join(' · '),
                      style: TextStyle(
                          color: c.displayColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(c.spiritualEffect,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12, height: 1.4)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.white38, size: 18),
                onPressed: () => _remove(c),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
