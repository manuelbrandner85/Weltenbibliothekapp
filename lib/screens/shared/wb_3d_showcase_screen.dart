import 'package:flutter/material.dart';

import '../../widgets/cinematic/wb_model_view.dart';

/// 3D-Schaufenster: zeigt den interaktiven Bewusstseins-Orb (glTF) zum
/// Drehen/Zoomen. Bewusst geoeffneter 3D-Screen -> forceEnable (Tier-Gate aus,
/// Reduce-Motion bleibt aktiv).
class Wb3DShowcaseScreen extends StatelessWidget {
  const Wb3DShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000004),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('3D-Schaufenster'),
      ),
      body: WbModelView(
        src: 'assets/models/wb_orb.glb',
        alt: 'Bewusstseins-Orb',
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
    );
  }
}
