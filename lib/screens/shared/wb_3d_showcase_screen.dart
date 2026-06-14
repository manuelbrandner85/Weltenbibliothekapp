import 'package:flutter/material.dart';

import '../../widgets/cinematic/wb_model_view.dart';

/// 3D-Galerie: interaktive glTF-Modelle (drehen/zoomen) mit Auswahl.
/// Bewusst geoeffneter 3D-Screen -> forceEnable (Tier-Gate aus, Reduce-Motion
/// bleibt aktiv).
class Wb3DShowcaseScreen extends StatefulWidget {
  const Wb3DShowcaseScreen({super.key});

  @override
  State<Wb3DShowcaseScreen> createState() => _Wb3DShowcaseScreenState();
}

class _Wb3DShowcaseScreenState extends State<Wb3DShowcaseScreen> {
  // (Label, Asset, Alt, Akzentfarbe)
  static const _models = <(String, String, String, Color)>[
    ('Bewusstseins-Orb', 'assets/models/wb_orb.glb', 'Orb', Color(0xFF00D4AA)),
    (
      'Merkaba',
      'assets/models/wb_merkaba.glb',
      'Heilige Geometrie',
      Color(0xFF00D4AA)
    ),
    (
      'Globus',
      'assets/models/wb_globe.glb',
      'Machtnetz-Globus',
      Color(0xFF3B82F6)
    ),
    (
      'Chakren',
      'assets/models/wb_chakras.glb',
      'Chakren-Saeule',
      Color(0xFFA855F7)
    ),
  ];

  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final m = _models[_i];
    return Scaffold(
      backgroundColor: const Color(0xFF000004),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('3D-Schaufenster'),
      ),
      body: Column(
        children: [
          Expanded(
            child: WbModelView(
              key: ValueKey(m.$2), // beim Wechsel neu laden
              src: m.$2,
              alt: m.$3,
              forceEnable: true,
              fallback: const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Text(
                    '3D ist hier deaktiviert\n(Reduce-Motion aktiv).',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, height: 1.5),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _models.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final sel = i == _i;
                  final c = _models[i].$4;
                  return Center(
                    child: GestureDetector(
                      onTap: () => setState(() => _i = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: sel
                              ? c.withValues(alpha: 0.20)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(color: sel ? c : Colors.white12),
                        ),
                        child: Text(
                          _models[i].$1,
                          style: TextStyle(
                            color: sel ? c : Colors.white54,
                            fontSize: 12.5,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
