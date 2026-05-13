import 'package:flutter/material.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';

/// 🌀 URSPRUNG Lesson Screen — Placeholder
class UrsprungLessonScreen extends StatelessWidget {
  const UrsprungLessonScreen({super.key});

  static const _cyan = Color(0xFF00D4AA);
  static const _bgDeep = Color(0xFF050510);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: _bgDeep,
      appBar: WBGlassAppBar(
        world: WBWorld.ursprung,
        title: 'LEKTION',
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _cyan),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline, size: 64, color: _cyan.withValues(alpha: 0.4)),
            const SizedBox(height: 20),
            const Text(
              'LEKTION',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w200,
                letterSpacing: 6.0,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Lektionen werden bald freigeschaltet',
              style: TextStyle(
                fontSize: 14,
                color: _cyan.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
