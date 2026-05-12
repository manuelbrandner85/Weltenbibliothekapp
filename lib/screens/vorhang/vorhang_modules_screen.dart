import 'package:flutter/material.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';

/// 🎭 VORHANG Modules Screen — Placeholder
class VorhangModulesScreen extends StatelessWidget {
  const VorhangModulesScreen({super.key});

  static const _gold = Color(0xFFC9A84C);
  static const _bgBlack = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: _bgBlack,
      appBar: WBGlassAppBar(
        world: WBWorld.vorhang,
        title: 'VORHANG MODULE',
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _gold),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: _gold.withValues(alpha: 0.4)),
            const SizedBox(height: 20),
            const Text(
              'MODULE',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w200,
                letterSpacing: 6.0,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Module werden bald freigeschaltet',
              style: TextStyle(
                fontSize: 14,
                color: _gold.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
