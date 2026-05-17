import 'package:flutter/material.dart';
 // OpenClaw v2.0
import 'dart:math' as math;
import 'dart:ui';
import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'materie_world_wrapper.dart';
import 'energie_world_wrapper.dart';
import 'vorhang/vorhang_world_wrapper.dart';
import 'ursprung/ursprung_world_wrapper.dart';
import '../animations/world_transition_video.dart';
import '../services/sound_service.dart';
import '../services/haptic_service.dart';
import '../utils/responsive_helper.dart';
import 'profile_settings_screen.dart';
import '../utils/portal_enhancements.dart';
// 🎨 NEW: Animation System
// 🎨 NEW: Enhanced Themes
import '../painters/energy_effects_painter.dart';
import '../widgets/tutorial_overlay.dart';
import '../widgets/pwa_install_prompt.dart'; // 📱 PWA INSTALL PROMPT (NEW Phase 3)
import '../widgets/web_admin_fab.dart'; // 👑 WEB ADMIN FAB
import '../widgets/web_logout_button.dart'; // 🚪 WEB LOGOUT BUTTON
import 'package:flutter/foundation.dart' show kIsWeb;
import '../data/hidden_facts.dart';
import '../data/achievement_data.dart';
import '../widgets/mini_game.dart';
import '../services/achievement_service.dart';

/// CINEMA-QUALITY Portal mit Nebula-Effekt und Advanced Particle System
class PortalHomeScreen extends StatefulWidget {
  const PortalHomeScreen({super.key});

  @override
  State<PortalHomeScreen> createState() => _PortalHomeScreenState();
}

class _PortalHomeScreenState extends State<PortalHomeScreen> with TickerProviderStateMixin {
  late AnimationController _portalController;
  late AnimationController _nebulaController;
  late AnimationController _particleController;
  late AnimationController _starsController;
  late List<Particle> _particles;
  late List<Star> _stars;
  
  // Easter Egg: 10x tap counter
  int _portalTapCount = 0;
  DateTime? _lastTapTime;
  
  // Touch position for interactive particles
  Offset? _touchPosition;
  
  // GlobalKeys for button positions (v5.37 - for energy beams)
  final GlobalKey _materieButtonKey = GlobalKey();
  final GlobalKey _energieButtonKey = GlobalKey();
  final GlobalKey _portalKey = GlobalKey();
  
  // Tutorial overlay (v5.37 - Improvement 5.5)
  bool _showTutorial = false;
  
  // Gyroscope 3D Parallax (deaktiviert - sensors_plus Kompatibilität)
  // Kann reaktiviert werden, wenn gyroscopeEventStream() verfügbar ist
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  double _gyroX = 0.0; // ignore: prefer_final_fields
  double _gyroY = 0.0; // ignore: prefer_final_fields
  
  // Portal Color Scheme (v5.39 - Dynamic Colors)
  Color _portalColor1 = const Color(0xFF3B82F6); // Materie Blue
  Color _portalColor2 = const Color(0xFFA855F7); // Energie Purple
  String _currentColorScheme = 'Standard';
  
  // v5.40 - Easter Egg Improvements
  late AnimationController _tapPulseController;
  late AnimationController _progressRingController;
  late AnimationController _wordmarkController;
  
  // Achievement System (v5.40 - 2.3)
  int _totalPortalTaps = 0;
  final Set<String> _unlockedAchievements = {};
  final Set<String> _triedColorSchemes = {};
  int _worldSwitchCount = 0;
  
  // Secret Portal Variant (v5.40 - 3.2)
  bool _goldenPortalUnlocked = false;
  
  // Mini-Game State (v5.40 - 3.1)
  // UNUSED FIELD: bool _showMiniGame = false;
  
  // ✅ PORTAL READY STATE - default true für sofortigen Start
  bool _portalReady = true;

  @override
  void initState() {
    super.initState();
    
    // ✅ DELAYED INITIALIZATION für smooth display
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePortal();
    });
  }
  
  /// ✅ LAZY PORTAL INITIALIZATION - nicht blockierend
  Future<void> _initializePortal() async {
    try {
      // Portal-Animationen initialisieren
      _portalController = AnimationController(
        duration: const Duration(seconds: 10),
        vsync: this,
      )..repeat();
      
      // Nebula Pulsation
      _nebulaController = AnimationController(
        duration: const Duration(seconds: 4),
        vsync: this,
      )..repeat(reverse: true);
      
      // Particle Animation
      _particleController = AnimationController(
        duration: const Duration(seconds: 20),
        vsync: this,
      )..repeat();
      
      // Stars Animation (v5.37)
      _starsController = AnimationController(
        duration: const Duration(seconds: 30),
        vsync: this,
      )..repeat();
      
      // v5.40 - Tap Pulse Animation (1.3)
      _tapPulseController = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );
      
      // v5.40 - Progress Ring Animation (1.1)
      _progressRingController = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );

      // Wordmark letter-by-letter reveal
      _wordmarkController = AnimationController(
        duration: const Duration(milliseconds: 2400),
        vsync: this,
      )..forward();

      // Initialize 200 Particles
      _particles = List.generate(200, (i) => Particle(index: i));
      
      // Initialize 100 Stars (v5.37)
      _stars = List.generate(100, (i) => Star(index: i));
      
      // Check if tutorial should be shown (v5.37 - Improvement 5.5)
      _checkTutorial();
      
      // Portal ist bereit
      if (mounted) {
        setState(() {
          _portalReady = true;
        });
      }
      
      debugPrint('✅ Portal initialisiert und bereit');
    } catch (e) {
      debugPrint('⚠️ Portal initialization error: $e');
      // Fallback: Portal trotzdem anzeigen
      if (mounted) {
        setState(() {
          _portalReady = true;
        });
      }
    }
  }
  
  /// Original initState - nur für Rückwärtskompatibilität
     //     // Start gyroscope listener (v5.37 - Improvement 5.4)
    // _gyroscopeSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      // if (mounted) {
        // setState(() {
          // Subtle tilt effect (limit range)
          // _gyroX = (event.y * 10).clamp(-20.0, 20.0);
          // _gyroY = (event.x * 10).clamp(-20.0, 20.0);
        // });
      // }
    // });
  // }
  
  Future<void> _checkTutorial() async {
    final show = await shouldShowTutorial();
    if (show && mounted) {
      // Delay to let animations start
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _showTutorial = true);
        }
      });
    }
  }

  @override
  void dispose() {
    _portalController.dispose();
    _nebulaController.dispose();
    _particleController.dispose();
    _starsController.dispose();
    _tapPulseController.dispose();
    _progressRingController.dispose();
    _wordmarkController.dispose();
    _gyroscopeSubscription?.cancel();
    super.dispose();
  }
  
  // Easter Egg Handler (v5.40 - Enhanced with all improvements)
  void _handlePortalTap() async {
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
      _portalTapCount = 0;
    }
    _lastTapTime = now;
    _portalTapCount++;
    _totalPortalTaps++; // Achievement tracking
    
    // 1.2 - Haptic Feedback
    HapticService.lightImpact();
    
    // 1.3 - Portal Pulse Animation
    _tapPulseController.forward(from: 0.0);
    
    // 1.1 - Progress Ring Animation
    setState(() {
      _progressRingController.animateTo(
        _portalTapCount / 10.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
    
    // 1.2 - Sound Feedback (pitch increases with taps)
    final pitch = 1.0 + (_portalTapCount * 0.1);
    SoundService.playTapSound(pitch: pitch);
    
    if (_portalTapCount >= 10) {
      // Heavy haptic for unlock
      HapticService.heavyImpact();
      
      // 1.2 - Unlock Sound
      SoundService.playUnlockSound();
      
      // v5.41 - FIX 1: Delay dialog to prevent accidental tap
      await Future.delayed(const Duration(milliseconds: 300));
      
      _showEasterEgg();
      _portalTapCount = 0;
      _progressRingController.animateTo(0.0, duration: const Duration(milliseconds: 500));
      
      // 2.3 - Achievement: Portal Entdecker
      _unlockAchievement('portal_entdecker');
    }
    
    // 3.2 - Check for Golden Portal unlock (50 total taps)
    if (_totalPortalTaps >= 50 && !_goldenPortalUnlocked) {
      _goldenPortalUnlocked = true;
      _unlockAchievement('golden_portal');
      _showGoldenPortalUnlock();
    }
  }
  
  void _showEasterEgg() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFFFFD700)),
            SizedBox(width: 10),
            Text('🌀 Portal Geheimnis', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Du hast das versteckte Portal-Menü entdeckt!',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildEasterEggOption(
              '🎨 Portal-Farben ändern', 
              'Wechsle zwischen Farbschemas',
              () {
                Navigator.pop(context);
                _showPortalColorPicker();
              },
            ),
            _buildEasterEggOption(
              '📚 Hidden Facts', 
              'Verschwörungstheorien & Fakten',
              () {
                Navigator.pop(context);
                _showHiddenFacts();
              },
            ),
            _buildEasterEggOption(
              '🎮 Mini-Game: Portal Defense', 
              'Verteidige das Portal!',
              () {
                Navigator.pop(context);
                _startMiniGame();
              },
            ),
            _buildEasterEggOption(
              '🔐 Cheat Codes', 
              'Geheime Codes eingeben',
              () {
                Navigator.pop(context);
                _showCheatCodes();
              },
            ),
            _buildEasterEggOption(
              '🏆 Achievements', 
              'Deine Erfolge & Fortschritt',
              () {
                Navigator.pop(context);
                _showAchievements();
              },
            ),
            _buildEasterEggOption(
              '📊 Entwickler-Stats', 
              'Technische Details & Performance',
              () {
                Navigator.pop(context);
                _showDeveloperStats();
              },
            ),
            _buildEasterEggOption(
              '📤 Stats teilen', 
              'Portal-Stats auf Social Media',
              () {
                Navigator.pop(context);
                _sharePortalStats();
              },
            ),
            _buildEasterEggOption(
              '🔮 Über das Portal', 
              'Weltenbibliothek v5.40 COMPLETE',
              () {
                Navigator.pop(context);
                _showAboutPortal();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen', style: TextStyle(color: Color(0xFF64B5F6), fontSize: 16)),
          ),
        ],
      ),
    );
  }
  
  // Portal Color Picker (v5.38 - Vollständig)
  void _showPortalColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.palette, color: Color(0xFFFFD700)),
            SizedBox(width: 10),
            Text('🎨 Portal-Farben', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildColorSchemeOption('Standard (Blau/Lila)', '🌀', const Color(0xFF2196F3), const Color(0xFF9C27B0)),
            _buildColorSchemeOption('Feuer (Rot/Orange)', '🔥', const Color(0xFFFF5722), const Color(0xFFFF9800)),
            _buildColorSchemeOption('Natur (Grün/Türkis)', '🌿', const Color(0xFF4CAF50), const Color(0xFF00BCD4)),
            _buildColorSchemeOption('Mystisch (Lila/Pink)', '✨', const Color(0xFF9C27B0), const Color(0xFFE91E63)),
            _buildColorSchemeOption('Cyber (Cyan/Magenta)', '⚡', const Color(0xFF00E5FF), const Color(0xFFFF00FF)),
          ],
        ),
        actions: [
          // v5.41 - FIX 2: Zurück zum Easter Egg (Color Picker)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEasterEgg();
            },
            child: const Text('← Easter Egg Menü', style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );
  }
  
  Widget _buildColorSchemeOption(String name, String emoji, Color color1, Color color2) {
    final isActive = _currentColorScheme == name.split(' ')[0]; // Extract first word
    
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        // APPLY COLOR SCHEME (v5.39)
        setState(() {
          _portalColor1 = color1;
          _portalColor2 = color2;
          _currentColorScheme = name.split(' ')[0];
          
          // v5.40 - Track for achievements
          _triedColorSchemes.add(name.split(' ')[0]);
          if (_triedColorSchemes.length >= 5) {
            _unlockAchievement('farb_meister');
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$emoji $name aktiviert!'),
            backgroundColor: color1,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color1.withValues(alpha: 0.3), color2.withValues(alpha: 0.3)],
          ),
          border: Border.all(
            color: isActive 
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.2),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  if (isActive)
                    const Text(
                      'Aktiv',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color1, color2],
                ),
                border: isActive 
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
              child: isActive 
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
  
  // Developer Stats (v5.38 - Vollständig)
  void _showDeveloperStats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Color(0xFFFFD700)),
            SizedBox(width: 10),
            Text('📊 Entwickler-Stats', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatItem('Flutter Version', '3.35.4'),
              _buildStatItem('Dart Version', '3.9.2'),
              _buildStatItem('Partikel', '200'),
              _buildStatItem('Sterne', '100'),
              _buildStatItem('Animationen', '4 Controller'),
              _buildStatItem('Portal-Rotation', '10s / 360°'),
              _buildStatItem('Gyroscope', _gyroX != 0.0 || _gyroY != 0.0 ? 'Aktiv' : 'Inaktiv'),
              _buildStatItem('Touch-Position', _touchPosition != null ? 'Getrackt' : 'Keine'),
              const Divider(color: Colors.white24),
              _buildStatItem('Features', '9 Easter Egg Verbesserungen'),
              _buildStatItem('Build-Zeit', '60.8s'),
              _buildStatItem('Version', 'v5.41 UX FIXES'),
            ],
          ),
        ),
        actions: [
          // v5.41 - FIX 2: Zurück zum Easter Egg (Developer Stats)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEasterEgg();
            },
            child: const Text('← Easter Egg Menü', style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF64B5F6),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  // About Portal (v5.38 - Vollständig)
  void _showAboutPortal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFFFFD700)),
            SizedBox(width: 10),
            Text('🔮 Über das Portal', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WELTENBIBLIOTHEK',
                style: TextStyle(
                  color: Color(0xFF64B5F6),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Dual Realms · Deep Research',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 20),
              const Text(
                'Das Portal verbindet zwei Welten:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildWorldDescription(
                '🔵 MATERIE',
                'Die physische Realität. Forschung, Fakten, Geopolitik und Wissen.',
                const Color(0xFF2196F3),
              ),
              const SizedBox(height: 12),
              _buildWorldDescription(
                '🟣 ENERGIE',
                'Die spirituelle Dimension. Spirit, Bewusstsein, Archetypen und Symbolik.',
                const Color(0xFF9C27B0),
              ),
              const Divider(color: Colors.white24, height: 32),
              const Text(
                'Version: 5.37 FINAL',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const Text(
                'Alle 9 Verbesserungen implementiert',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 8),
              const Text(
                'Made with 💙 by Claude Code Agent',
                style: TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          // v5.41 - FIX 2: Zurück zum Easter Egg (About Portal)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEasterEgg();
            },
            child: const Text('← Easter Egg Menü', style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWorldDescription(String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEasterEggOption(String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF64B5F6), size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // 📱 NEW: Use context extension for responsive values
    
    // ✅ SMOOTH LOADING: Zeige Loader bis Portal bereit
    if (!_portalReady) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A192F),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsierender Portal-Loader
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.2),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeInOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF2196F3).withValues(alpha: 0.5),
                            const Color(0xFF9C27B0).withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
                onEnd: () {
                  // Loop animation
                  if (mounted && !_portalReady) {
                    setState(() {});
                  }
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Portal wird geladen...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Stack(
      children: [
        Scaffold(
          body: GestureDetector(
        // Touch-Interactive Particles (v5.37 - Improvement 1.2)
        onPanUpdate: (details) {
          setState(() {
            _touchPosition = details.localPosition;
          });
        },
        onPanEnd: (_) {
          setState(() {
            _touchPosition = null;
          });
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, 0.3),
              radius: 1.4,
              colors: [
                Color(0xFF0D0A1A),
                Color(0xFF050310),
                Color(0xFF000004),
              ],
            ),
          ),
          child: Stack(
          children: [
            // NEBULA BACKGROUND
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _nebulaController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: NebulaPainter(_nebulaController.value),
                  );
                },
              ),
            ),
            
            // DYNAMIC STARFIELD (v5.37 - Improvement 2.1)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _starsController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: StarfieldPainter(_starsController.value, _stars),
                  );
                },
              ),
            ),
            
            // ADVANCED PARTICLE SYSTEM (200 particles)
            ...List.generate(_particles.length, (index) {
              return AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  final particle = _particles[index];
                  final progress = (_particleController.value + particle.offset) % 1.0;
                  
                  // Orbital movement around portal center
                  final angle = progress * 2 * math.pi + particle.angleOffset;
                  final radius = particle.orbitRadius * (0.3 + progress * 0.7);
                  var x = size.width / 2 + math.cos(angle) * radius;
                  var y = size.height / 2 + math.sin(angle) * radius;
                  
                  // Touch-Interactive Particles (v5.37 - Improvement 1.2)
                  if (_touchPosition != null) {
                    final dx = x - _touchPosition!.dx;
                    final dy = y - _touchPosition!.dy;
                    final distance = math.sqrt(dx * dx + dy * dy);
                    final pushRadius = 150.0; // Particles flee within 150px
                    
                    if (distance < pushRadius) {
                      final pushStrength = (1.0 - distance / pushRadius) * 60.0;
                      x += (dx / distance) * pushStrength;
                      y += (dy / distance) * pushStrength;
                    }
                  }
                  
                  // Depth-based opacity and size
                  final depth = math.sin(progress * math.pi);
                  final opacity = (0.2 + depth * 0.8) * particle.brightness;
                  final particleSize = particle.size * (0.5 + depth * 1.5);
                  
                  return Positioned(
                    left: x - particleSize / 2,
                    top: y - particleSize / 2,
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Container(
                        width: particleSize,
                        height: particleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              particle.color.withValues(alpha: 0.9),
                              particle.color.withValues(alpha: 0.0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: particle.color.withValues(alpha: 0.6),
                              blurRadius: particleSize * 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
            
            // ENERGY BEAMS FROM PORTAL TO BUTTONS (v5.37 - Improvement 2.3)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _portalController,
                builder: (context, child) {
                  // Get positions
                  final portalBox = _portalKey.currentContext?.findRenderObject() as RenderBox?;
                  final materieBox = _materieButtonKey.currentContext?.findRenderObject() as RenderBox?;
                  final energieBox = _energieButtonKey.currentContext?.findRenderObject() as RenderBox?;
                  
                  if (portalBox == null || materieBox == null || energieBox == null) {
                    return const SizedBox.shrink();
                  }
                  
                  final portalCenter = portalBox.localToGlobal(
                    Offset(portalBox.size.width / 2, portalBox.size.height / 2),
                  );
                  final materieCenter = materieBox.localToGlobal(
                    Offset(materieBox.size.width / 2, materieBox.size.height / 2),
                  );
                  final energieCenter = energieBox.localToGlobal(
                    Offset(energieBox.size.width / 2, energieBox.size.height / 2),
                  );
                  
                  return CustomPaint(
                    painter: EnergyBeamPainter(
                      animation: _portalController.value,
                      portalCenter: portalCenter,
                      materieButtonCenter: materieCenter,
                      energieButtonCenter: energieCenter,
                      materieColor: _portalColor1,
                      energieColor: _portalColor2,
                    ),
                  );
                },
              ),
            ),
            
            // MAIN CONTENT — Cinematic Portal Design
            SafeArea(
              child: Column(
                children: [
                  // ── Top bar ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Anno MMXXVI', style: TextStyle(fontSize: 10, letterSpacing: 4.2, color: Colors.white.withValues(alpha: 0.42), fontWeight: FontWeight.w500)),
                                Container(width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.5))),
                                Text('Vol. V', style: TextStyle(fontSize: 10, letterSpacing: 4.2, color: Colors.white.withValues(alpha: 0.42), fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Willkommen, Reisender', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.78), fontWeight: FontWeight.w300, letterSpacing: 0.2)),
                          ],
                        ),
                        _buildIconBtn(Icons.settings, () {
                          HapticService.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileSettingsScreen(),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // ── Wordmark ──
                  AnimatedBuilder(
                    animation: _wordmarkController,
                    builder: (context, child) {
                      return Column(
                        children: [
                          _buildWordmarkRow('WELTEN', _wordmarkController.value, 0.0, isGradient: false),
                          const SizedBox(height: 2),
                          _buildWordmarkRow('BIBLIOTHEK', _wordmarkController.value, 0.12, isGradient: true),
                          const SizedBox(height: 18),
                          Opacity(
                            opacity: ((_wordmarkController.value - 0.7) / 0.3).clamp(0.0, 1.0),
                            child: Text(
                              'Wähle deine Welt · vier Pfade, ein Ursprung',
                              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: Colors.white.withValues(alpha: 0.46), letterSpacing: 1.8, fontWeight: FontWeight.w300),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const Spacer(),

                  // ── Cinematic Dual-World Portal (tap = easter egg) ──
                  GestureDetector(
                    onTap: _handlePortalTap,
                    child: SizedBox(
                      key: _portalKey,
                      width: 260,
                      height: 280,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_portalController, _nebulaController, _tapPulseController]),
                        builder: (context, child) {
                          final tapScale = 1.0 + _tapPulseController.value * 0.14;
                          final neo = _nebulaController.value;
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Dual ambient atmosphere
                              Transform.scale(
                                scale: tapScale,
                                child: Container(
                                  width: 260, height: 260,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: _portalColor1.withValues(alpha: 0.22 * neo), blurRadius: 110, spreadRadius: 55),
                                      BoxShadow(color: _portalColor2.withValues(alpha: 0.22 * (1 - neo)), blurRadius: 110, spreadRadius: 55),
                                    ],
                                  ),
                                ),
                              ),
                              // Cinematic dual-world vortex painter
                              CustomPaint(
                                size: const Size(240, 240),
                                painter: CinematicPortalPainter(
                                  animation: _portalController.value,
                                  pulse: neo,
                                  materieColor: _portalColor1,
                                  energieColor: _portalColor2,
                                ),
                              ),
                              // Central division crack (world boundary)
                              Container(
                                width: 2.5,
                                height: 112,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withValues(alpha: 0.82),
                                      Colors.white,
                                      Colors.white,
                                      Colors.white.withValues(alpha: 0.82),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.15, 0.35, 0.65, 0.85, 1.0],
                                  ),
                                  boxShadow: [
                                    BoxShadow(color: Colors.white.withValues(alpha: 0.65), blurRadius: 14),
                                    BoxShadow(color: _portalColor1.withValues(alpha: 0.45), blurRadius: 26, offset: const Offset(-10, 0)),
                                    BoxShadow(color: _portalColor2.withValues(alpha: 0.45), blurRadius: 26, offset: const Offset(10, 0)),
                                  ],
                                ),
                              ),
                              // Nexus dot at the boundary
                              Opacity(
                                opacity: (0.7 + 0.3 * neo).clamp(0.0, 1.0),
                                child: Container(
                                  width: 12, height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      const BoxShadow(color: Colors.white, blurRadius: 30, spreadRadius: 8),
                                      BoxShadow(color: _portalColor1.withValues(alpha: 0.55), blurRadius: 60, spreadRadius: 14, offset: const Offset(-7, 0)),
                                      BoxShadow(color: _portalColor2.withValues(alpha: 0.55), blurRadius: 60, spreadRadius: 14, offset: const Offset(7, 0)),
                                    ],
                                  ),
                                ),
                              ),
                              // Tap progress ring
                              if (_portalTapCount > 0)
                                CustomPaint(
                                  size: const Size(256, 256),
                                  painter: TapProgressRingPainter(
                                    progress: _portalTapCount / 10.0,
                                    tapCount: _portalTapCount,
                                    color1: _portalColor1,
                                    color2: _portalColor2,
                                  ),
                                ),
                              // Tap dots
                              Positioned(
                                bottom: 0,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(10, (i) => Container(
                                    width: 5, height: 5,
                                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: i < _portalTapCount
                                          ? const Color(0xFFFFD479)
                                          : Colors.white.withValues(alpha: 0.15),
                                      boxShadow: i < _portalTapCount
                                          ? [const BoxShadow(color: Color(0xFFFFD479), blurRadius: 8)]
                                          : null,
                                    ),
                                  )),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  const Spacer(),

                  // ── World cards (2×2 Quad-Portal Grid) ──
                  // Auf PC: max 800px breit damit Kacheln nicht riesig werden.
                  // Mobile (Container.maxWidth ≤ 600) bleibt voll-breit.
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Zeile 1: Materie + Energie
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuadWorldCard(
                                cardKey: _materieButtonKey,
                                eyebrow: 'WELT I',
                                title: 'MATERIE',
                                subtitle: 'Wissen · Fakten',
                                primaryColor: const Color(0xFF3B82F6),
                                deepColor: const Color(0xFF040D1F),
                                labelColor: const Color(0xFF7DA7FF),
                                icon: Icons.public,
                                onTap: () => _navigateWithCinematicTransition(const MaterieWorldWrapper()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildQuadWorldCard(
                                cardKey: _energieButtonKey,
                                eyebrow: 'WELT II',
                                title: 'ENERGIE',
                                subtitle: 'Spirit · Mystik',
                                primaryColor: const Color(0xFFA855F7),
                                deepColor: const Color(0xFF0C0318),
                                labelColor: const Color(0xFFC79AFF),
                                icon: Icons.auto_awesome,
                                onTap: () => _navigateWithCinematicTransition(const EnergieWorldWrapper()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Zeile 2: Vorhang + Ursprung
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuadWorldCard(
                                eyebrow: 'WELT III',
                                title: 'VORHANG',
                                subtitle: 'Psychologie · Macht',
                                primaryColor: const Color(0xFFC9A84C),
                                deepColor: const Color(0xFF0D0B00),
                                labelColor: const Color(0xFFE0C872),
                                icon: Icons.psychology,
                                onTap: () => _navigateWithCinematicTransition(const VorhangWorldWrapper()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildQuadWorldCard(
                                eyebrow: 'WELT IV',
                                title: 'URSPRUNG',
                                subtitle: 'Bewusstsein · CIA',
                                primaryColor: const Color(0xFF00D4AA),
                                deepColor: const Color(0xFF050510),
                                labelColor: const Color(0xFF40E8C0),
                                icon: Icons.all_inclusive,
                                onTap: () => _navigateWithCinematicTransition(const UrsprungWorldWrapper()),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                    ), // ConstrainedBox close
                  ), // Center close

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ],
        ),
      ),
      ), // GestureDetector closing
    ), // Scaffold closing
      
    // TUTORIAL OVERLAY (v5.37 - Improvement 5.5)
    if (_showTutorial)
      TutorialOverlay(
        onComplete: () async {
          // ✅ KRITISCH: Tutorial-Abschluss speichern!
          await markTutorialAsShown();
          if (mounted) {
            setState(() => _showTutorial = false);
          }
        },
      ),
      
    // 📱 PWA INSTALL PROMPT (NEW Phase 3)
    const PWAInstallPrompt(),

    // 👑 WEB ADMIN FAB (nur auf Web für Admins sichtbar)
    if (kIsWeb)
      const Positioned(
        bottom: 20,
        right: 20,
        child: WebAdminFab(),
      ),

    // 🚪 WEB LOGOUT (nur auf Web sichtbar)
    if (kIsWeb)
      const Positioned(
        top: 40,
        right: 16,
        child: WebLogoutButton(),
      ),
    ],
    );
  }

  // ── Design-bundle helpers ──

  Widget _buildIconBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.85)),
      ),
    );
  }

  Widget _buildHaloRing(double size, double opacity) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: opacity), width: 1),
        boxShadow: [BoxShadow(color: const Color(0xFF7878FF).withValues(alpha: 0.12), blurRadius: 80, spreadRadius: 6)],
      ),
    );
  }

  Widget _buildWordmarkRow(String text, double anim, double delayFrac, {required bool isGradient}) {
    final letters = text.split('');
    final total = letters.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final start = delayFrac + i * (0.55 / total);
        final end = (start + 0.18).clamp(0.0, 1.0);
        final t = ((anim - start) / (end - start)).clamp(0.0, 1.0);
        final child = Transform.translate(
          offset: Offset(0, 40 * (1 - t)),
          child: Opacity(
            opacity: t,
            child: isGradient
                ? ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [Color(0xFF5B8DEF), Color(0xFFA78BFA), Color(0xFFE879F9)],
                    ).createShader(Rect.fromLTWH(0, 0, b.width * total, b.height)),
                    child: Text(
                      letters[i] == ' ' ? ' ' : letters[i],
                      style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w300, fontSize: 38, letterSpacing: 10, color: Colors.white, height: 1),
                    ),
                  )
                : Text(
                    letters[i] == ' ' ? ' ' : letters[i],
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w200, fontSize: 38, letterSpacing: 10, color: Colors.white.withValues(alpha: 0.96), height: 1,
                      shadows: [Shadow(color: Colors.white.withValues(alpha: 0.18), blurRadius: 40)]),
                  ),
          ),
        );
        return child;
      }),
    );
  }

  Widget _buildWorldCard({
    required Key cardKey,
    required String eyebrow,
    required String title,
    required String subtitle,
    required List<String> tags,
    required Color primaryColor,
    required Color deepColor,
    required Color labelColor,
    required Alignment orbOffset,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: cardKey,
      onTap: () {
        HapticService.mediumImpact();
        onTap();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
          child: Container(
            height: 126,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  deepColor,
                  Color.lerp(deepColor, primaryColor, 0.18)!,
                ],
              ),
              border: Border.all(color: primaryColor.withValues(alpha: 0.28), width: 1.2),
              boxShadow: [
                BoxShadow(color: primaryColor.withValues(alpha: 0.26), blurRadius: 38, offset: const Offset(0, 12)),
                BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 18, offset: const Offset(0, 5)),
              ],
            ),
            child: Stack(
              children: [
                // Atmospheric orb glow in background
                Positioned.fill(
                  child: Align(
                    alignment: orbOffset,
                    child: Container(
                      width: 170, height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            primaryColor.withValues(alpha: 0.38),
                            primaryColor.withValues(alpha: 0.10),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                // Grid texture overlay
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: CustomPaint(painter: _GridLinePainter(primaryColor.withValues(alpha: 0.055))),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 18, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: eyebrow chip + arrow
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: primaryColor.withValues(alpha: 0.45), width: 0.8),
                            ),
                            child: Text(eyebrow, style: TextStyle(fontSize: 9, letterSpacing: 3.0, color: labelColor, fontWeight: FontWeight.w700)),
                          ),
                          const Spacer(),
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryColor.withValues(alpha: 0.15),
                              border: Border.all(color: primaryColor.withValues(alpha: 0.35), width: 0.8),
                            ),
                            child: Icon(Icons.arrow_forward, color: primaryColor, size: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // World name
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w200,
                          letterSpacing: 6.0, color: Colors.white, height: 1,
                        ),
                      ),
                      const SizedBox(height: 9),
                      // Tag pills
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: tags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
                          ),
                          child: Text(tag, style: TextStyle(fontSize: 8.5, color: Colors.white.withValues(alpha: 0.52), letterSpacing: 0.3)),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorldsDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xFF3B82F6)],
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: 26, height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Icon(Icons.compare_arrows, size: 13, color: Colors.white.withValues(alpha: 0.30)),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFA855F7), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuadWorldCard({
    Key? cardKey,
    required String eyebrow,
    required String title,
    required String subtitle,
    required Color primaryColor,
    required Color deepColor,
    required Color labelColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: cardKey,
      onTap: () {
        HapticService.mediumImpact();
        onTap();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  deepColor,
                  Color.lerp(deepColor, primaryColor, 0.14)!,
                ],
              ),
              border: Border.all(color: primaryColor.withValues(alpha: 0.24), width: 1),
              boxShadow: [
                BoxShadow(color: primaryColor.withValues(alpha: 0.20), blurRadius: 28, offset: const Offset(0, 8)),
                BoxShadow(color: Colors.black.withValues(alpha: 0.50), blurRadius: 14, offset: const Offset(0, 4)),
              ],
            ),
            child: Stack(
              children: [
                // Atmospheric orb glow
                Positioned(
                  top: -30, right: -30,
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          primaryColor.withValues(alpha: 0.30),
                          primaryColor.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // Grid texture
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: CustomPaint(painter: _GridLinePainter(primaryColor.withValues(alpha: 0.04))),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Eyebrow chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.40), width: 0.8),
                        ),
                        child: Text(eyebrow, style: TextStyle(fontSize: 8, letterSpacing: 2.5, color: labelColor, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 10),
                      // Icon + Title
                      Row(
                        children: [
                          Icon(icon, color: primaryColor, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w200,
                                letterSpacing: 3.0, color: Colors.white, height: 1,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Subtitle
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.48),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      // Arrow
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withValues(alpha: 0.12),
                            border: Border.all(color: primaryColor.withValues(alpha: 0.30), width: 0.8),
                          ),
                          child: Icon(Icons.arrow_forward, color: primaryColor, size: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required Color glowColor,
    required VoidCallback onTap,
    // Removed: ResponsiveHelper responsive (using context extension)
  }) {
    return Container(
      height: context.responsive(mobile: 80.0, tablet: 95.0, desktop: 95.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.4),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  glowColor.withValues(alpha: 0.25),
                  glowColor.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: glowColor.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(24),
                splashColor: glowColor.withValues(alpha: 0.2),
                child: Padding(
                  padding: EdgeInsets.all(context.responsive(mobile: 16, tablet: 24, desktop: 16)),
                  child: Row(
                    children: [
                      // Icon with premium glow (Mobile-Optimiert)
                      Container(
                        padding: EdgeInsets.all(context.responsive(mobile: 12.0, tablet: 16.0, desktop: 16.0)),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: gradient,
                          boxShadow: [
                            BoxShadow(
                              color: glowColor.withValues(alpha: 0.6),
                              blurRadius: 25,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: context.responsive(mobile: 28, tablet: 28 * 1.3, desktop: 28 * 1.5),
                        ),
                      ),
                      
                      SizedBox(width: context.responsive(mobile: 8.0, tablet: 12.0, desktop: 16.0)),
                      
                      // Text (Mobile-Optimiert)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => gradient.createShader(bounds),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: context.responsive(mobile: 24, tablet: 24 * 1.2, desktop: 24 * 1.4),
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: context.responsive(mobile: 2.0, tablet: 4.0, desktop: 5.0,
                                    ),
                                    shadows: const [
                                      Shadow(color: Colors.black, blurRadius: 15),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: context.responsive(mobile: 12.0, tablet: 16.0, desktop: 20.0) / 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: context.responsive(mobile: 9, tablet: 9 * 1.2, desktop: 9 * 1.4),
                                color: Colors.white.withValues(alpha: 0.85),
                                letterSpacing: 1.0,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      // Arrow with glow
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: glowColor.withValues(alpha: 0.2),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateWithCinematicTransition(Widget screen, {String targetWorld = ''}) async {
    // Bestimme Welt-Typ automatisch wenn nicht explizit übergeben
    if (targetWorld.isEmpty) {
      if (screen is MaterieWorldWrapper) {
        targetWorld = 'materie';
      } else if (screen is EnergieWorldWrapper) {
        targetWorld = 'energie';
      } else if (screen is VorhangWorldWrapper) {
        targetWorld = 'vorhang';
      } else if (screen is UrsprungWorldWrapper) {
        targetWorld = 'ursprung';
      } else {
        targetWorld = 'materie'; // Fallback
      }
    }
    
    // 📳 HAPTIC: Medium Impact beim Start (v5.40)
    HapticService.mediumImpact();
    
    // Kurze Verzögerung für Haptic-Sync
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted) return;
    
    // 📳 HAPTIC: Heavy Impact beim Warp-Start (v5.40)
    HapticService.heavyImpact();
    
    // 🎬 CINEMATIC ÜBERGANG — Alle 4 Welten unterstützt
    // Materie/Energie: echte MP4-Videos
    // Vorhang/Ursprung: programmatische Vortex-Animation mit Welt-Farben
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorldTransitionVideo(
          targetScreen: screen,
          targetWorld: targetWorld,
        ),
      ),
    );
    
    // Track world switch for achievements (v5.40)
    _worldSwitchCount++;
    if (_worldSwitchCount >= 10) {
      _unlockAchievement('welten_reisender');
    }
  }
  
  // v5.40 - 2.1: Hidden Facts Dialog
  void _showHiddenFacts() {
    int currentFactIndex = 0;
    final facts = HiddenFacts.getAllFacts();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final fact = facts[currentFactIndex];
          return AlertDialog(
            backgroundColor: Colors.black.withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.auto_stories, color: Color(0xFFFFD700)),
                const SizedBox(width: 10),
                Text('${fact['title']}', style: const TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      fact['category']!,
                      style: const TextStyle(color: Color(0xFF64B5F6), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    fact['fact']!,
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      facts.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentFactIndex == index
                              ? const Color(0xFFFFD700)
                              : Colors.white24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Fact ${currentFactIndex + 1} von ${facts.length}',
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // v5.41 - FIX 2: Zurück zum Easter Egg statt schließen
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showEasterEgg();
                },
                child: const Text('← Easter Egg Menü', style: TextStyle(color: Color(0xFFFFD700))),
              ),
              if (currentFactIndex > 0)
                TextButton(
                  onPressed: () {
                    setState(() {
                      currentFactIndex--;
                    });
                  },
                  child: const Text('← Zurück', style: TextStyle(color: Color(0xFF64B5F6))),
                ),
              if (currentFactIndex < facts.length - 1)
                TextButton(
                  onPressed: () {
                    setState(() {
                      currentFactIndex++;
                    });
                    if (currentFactIndex == facts.length - 1) {
                      _unlockAchievement('hidden_facts_scholar');
                    }
                  },
                  child: const Text('Weiter →', style: TextStyle(color: Color(0xFF64B5F6))),
                ),
            ],
          );
        },
      ),
    );
  }
  
  // v5.40 - 2.2: Cheat Codes Dialog
  void _showCheatCodes() {
    final TextEditingController codeController = TextEditingController();
    final List<String> unlockedCodes = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.black.withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.vpn_key, color: Color(0xFFFFD700)),
              SizedBox(width: 10),
              Text('🔐 Cheat Codes', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 2),
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'CODE EINGEBEN',
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2196F3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2196F3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                    ),
                  ),
                  onSubmitted: (code) {
                    final upperCode = code.toUpperCase();
                    setState(() {
                      switch (upperCode) {
                        case 'ILLUMINATI':
                          if (!unlockedCodes.contains('ILLUMINATI')) {
                            unlockedCodes.add('ILLUMINATI');
                            _activateIlluminatiMode();
                          }
                          break;
                        case 'MATRIX':
                          if (!unlockedCodes.contains('MATRIX')) {
                            unlockedCodes.add('MATRIX');
                            _activateMatrixMode();
                          }
                          break;
                        case 'NOLAN':
                          if (!unlockedCodes.contains('NOLAN')) {
                            unlockedCodes.add('NOLAN');
                            _activateNolanMode();
                          }
                          break;
                      }
                      codeController.clear();
                      
                      if (unlockedCodes.length == 3) {
                        _unlockAchievement('cheat_code_master');
                      }
                    });
                  },
                ),
                const SizedBox(height: 20),
                if (unlockedCodes.isNotEmpty) ...[
                  const Text(
                    'Freigeschaltete Codes:',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...unlockedCodes.map((code) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
                        const SizedBox(width: 8),
                        Text(code, style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 14)),
                      ],
                    ),
                  )),
                ] else ...[
                  const Text(
                    'Tipp: Versuche ILLUMINATI, MATRIX oder NOLAN',
                    style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            // v5.41 - FIX 2: Zurück zum Easter Egg
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showEasterEgg();
              },
              child: const Text('← Easter Egg Menü', style: TextStyle(color: Color(0xFFFFD700))),
            ),
          ],
        ),
      ),
    ).whenComplete(codeController.dispose);
  }

  // v5.40 - 2.3: Achievements Dialog
  void _showAchievements() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Color(0xFFFFD700)),
            SizedBox(width: 10),
            Text('🏆 Achievements', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Achievement Stats
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2196F3).withValues(alpha: 0.2),
                        const Color(0xFF9C27B0).withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${_unlockedAchievements.length}/${AchievementData.getAllAchievements().length}',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Freigeschaltete Achievements',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Achievement List
                ...AchievementData.getAllAchievements().map((achievement) {
                  final isUnlocked = _unlockedAchievements.contains(achievement['id']);
                  final rarityColor = AchievementData.getRarityColor(achievement['rarity']);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? rarityColor.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isUnlocked ? rarityColor : Colors.white24,
                        width: isUnlocked ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Opacity(
                          opacity: isUnlocked ? 1.0 : 0.3,
                          child: Text(
                            achievement['icon'],
                            style: const TextStyle(
                              fontSize: 32,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                achievement['title'],
                                style: TextStyle(
                                  color: isUnlocked ? rarityColor : Colors.white38,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                achievement['description'],
                                style: TextStyle(
                                  color: isUnlocked ? Colors.white70 : Colors.white24,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isUnlocked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: rarityColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+${achievement['points']}',
                              style: TextStyle(
                                color: rarityColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          // v5.41 - FIX 2: Zurück zum Easter Egg (Achievements)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEasterEgg();
            },
            child: const Text('← Easter Egg Menü', style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );
  }
  
  // v5.40 - 3.1: Start Mini-Game
  void _startMiniGame() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => PortalDefenseMiniGame(
          onExit: () {
            Navigator.of(context).pop();
            // v5.41 - FIX 2: Zurück zum Easter Egg nach Mini-Game
            _showEasterEgg();
          },
          onGameOver: (score) {
            if (score >= 100) {
              _unlockAchievement('mini_game_champion');
            }
          },
        ),
      ),
    );
  }
  
  // v5.40 - 3.2: Show Golden Portal Unlock
  void _showGoldenPortalUnlock() {
    HapticService.heavyImpact();
    SoundService.playAchievementSound();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.stars, color: Color(0xFFFFD700)),
            SizedBox(width: 10),
            Text('👑 GOLDENES PORTAL FREIGESCHALTET!', style: TextStyle(color: Color(0xFFFFD700), fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFD700),
                    const Color(0xFFFF9800).withValues(alpha: 0.5),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '👑',
                  style: TextStyle(fontSize: 48),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Du hast das Portal 50x getappt!',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Das goldene Portal ist nun freigeschaltet. Es erscheint mit goldenen Partikeln und Effekten!',
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fantastisch!', style: TextStyle(color: Color(0xFFFFD700), fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  
  // v5.40 - 4.1: Share Portal Stats
  void _sharePortalStats() {
    final statsText = '''
🌀 WELTENBIBLIOTHEK - Meine Portal-Stats

📊 Statistiken:
• Portal-Taps: $_totalPortalTaps
• Welten-Wechsel: $_worldSwitchCount
• Achievements: ${_unlockedAchievements.length}/${AchievementData.getAllAchievements().length}
• Farbschema: $_currentColorScheme
${_goldenPortalUnlocked ? '• 👑 Goldenes Portal FREIGESCHALTET!' : ''}

🎮 Entdecke die Weltenbibliothek selbst!
''';
    
    // Show share dialog (web-compatible)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.share, color: Color(0xFFFFD700)),
            SizedBox(width: 10),
            Text('📤 Stats teilen', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2196F3)),
              ),
              child: SelectableText(
                statsText,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Kopiere den Text und teile ihn auf Social Media!',
              style: TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          // v5.41 - FIX 2: Zurück zum Easter Egg (Share Stats)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEasterEgg();
            },
            child: const Text('← Easter Egg Menü', style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );
  }
  
  // v5.40 - Achievement Unlock Handler (FIXED: Persistent Storage)
  void _unlockAchievement(String achievementId) async {
    final achievementService = AchievementService();
    
    // ✅ PERSISTENT UNLOCK via AchievementService
    final unlocked = await achievementService.incrementProgress(achievementId);
    
    if (unlocked && !_unlockedAchievements.contains(achievementId)) {
      setState(() {
        _unlockedAchievements.add(achievementId);
      });
      
      HapticService.mediumImpact();
      SoundService.playAchievementSound();
      
      final achievement = AchievementData.getAchievement(achievementId);
      if (achievement != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(achievement['icon'], style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Achievement freigeschaltet!',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        achievement['title'],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Text(
                  '+${achievement['points']}',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            backgroundColor: AchievementData.getRarityColor(achievement['rarity']).withValues(alpha: 0.9),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  // v5.40 - Cheat Code Activations
  void _activateIlluminatiMode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔺 ILLUMINATI MODE AKTIVIERT - Portal leuchtet gold!'),
        backgroundColor: Color(0xFFFFD700),
        duration: Duration(seconds: 2),
      ),
    );
    setState(() {
      _portalColor1 = const Color(0xFFFFD700);
      _portalColor2 = const Color(0xFFFF9800);
      _currentColorScheme = 'Illuminati';
    });
  }
  
  void _activateMatrixMode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('💚 MATRIX MODE AKTIVIERT - Grüne Matrix-Partikel!'),
        backgroundColor: Color(0xFF4CAF50),
        duration: Duration(seconds: 2),
      ),
    );
    setState(() {
      _portalColor1 = const Color(0xFF00FF00);
      _portalColor2 = const Color(0xFF4CAF50);
      _currentColorScheme = 'Matrix';
    });
  }
  
  void _activateNolanMode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎬 NOLAN MODE AKTIVIERT - Ultra-Cinema Effekte!'),
        backgroundColor: Color(0xFF1565C0),
        duration: Duration(seconds: 2),
      ),
    );
    // Add extra cinema effects (could enhance portal animation)
  }
}

/// Particle Data Class
class Particle {
  final int index;
  late final double size;
  late final Color color;
  late final double orbitRadius;
  late final double angleOffset;
  late final double offset;
  late final double brightness;
  
  Particle({required this.index}) {
    final random = math.Random(index);
    size = 2 + random.nextDouble() * 4;
    
    // Color variety
    final colorType = random.nextInt(4);
    color = colorType == 0
        ? const Color(0xFF2196F3) // Blue
        : colorType == 1
            ? const Color(0xFF9C27B0) // Purple
            : colorType == 2
                ? const Color(0xFFFFD700) // Gold
                : const Color(0xFF64B5F6); // Light Blue
    
    orbitRadius = 100 + random.nextDouble() * 200;
    angleOffset = random.nextDouble() * 2 * math.pi;
    offset = random.nextDouble();
    brightness = 0.4 + random.nextDouble() * 0.6;
  }
}

/// Nebula Background Painter
class NebulaPainter extends CustomPainter {
  final double animation;

  NebulaPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    // Create nebula clouds with radial gradients
    for (int i = 0; i < 5; i++) {
      final offset = Offset(
        size.width * (0.3 + i * 0.15),
        size.height * (0.2 + math.sin(animation * math.pi + i) * 0.3),
      );
      
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            (i % 2 == 0 ? const Color(0xFF2196F3) : const Color(0xFF9C27B0))
                .withValues(alpha: 0.15 * animation),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: offset, radius: 200 + i * 50));
      
      canvas.drawCircle(offset, 200 + i * 50, paint);
    }
  }

  @override
  bool shouldRepaint(NebulaPainter oldDelegate) => animation != oldDelegate.animation;
}

/// Dual-World Cinematic Portal — Materie (blue, left) | Energie (purple, right)
class CinematicPortalPainter extends CustomPainter {
  final double animation;
  final double pulse;
  final Color materieColor;
  final Color energieColor;

  CinematicPortalPainter({
    required this.animation,
    required this.pulse,
    required this.materieColor,
    required this.energieColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 4;
    final center = Offset(cx, cy);

    // Left hemisphere fill — Materie blue
    final lPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.45, 0),
        colors: [
          materieColor.withValues(alpha: 0.52 + 0.10 * pulse),
          materieColor.withValues(alpha: 0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, cx, size.height));
    canvas.drawCircle(center, r * 0.86, lPaint);
    canvas.restore();

    // Right hemisphere fill — Energie purple
    final rPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.45, 0),
        colors: [
          energieColor.withValues(alpha: 0.52 + 0.10 * (1 - pulse)),
          energieColor.withValues(alpha: 0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(cx, 0, size.width, size.height));
    canvas.drawCircle(center, r * 0.86, rPaint);
    canvas.restore();

    // Outer sweep ring (bicolor, rotating)
    final outerRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..shader = SweepGradient(
        colors: [
          materieColor.withValues(alpha: 0.85),
          energieColor.withValues(alpha: 0.85),
          materieColor.withValues(alpha: 0.85),
        ],
        transform: GradientRotation(animation * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, outerRing);

    // Inner counter-rotating ring
    final innerRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..shader = SweepGradient(
        colors: [
          energieColor.withValues(alpha: 0.6),
          materieColor.withValues(alpha: 0.6),
          energieColor.withValues(alpha: 0.6),
        ],
        transform: GradientRotation(-animation * 2 * math.pi + math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: r * 0.7));
    canvas.drawCircle(center, r * 0.7, innerRing);

    // Materie spiral arms (left side, clockwise)
    for (int i = 0; i < 3; i++) {
      final angle = animation * 2 * math.pi + i * (2 * math.pi / 3);
      _drawArm(canvas, cx, cy, r * 0.68, angle, materieColor, clockwise: true);
    }

    // Energie spiral arms (right side, counter-clockwise)
    for (int i = 0; i < 3; i++) {
      final angle = -animation * 2 * math.pi + i * (2 * math.pi / 3) + math.pi;
      _drawArm(canvas, cx, cy, r * 0.68, angle, energieColor, clockwise: false);
    }
  }

  void _drawArm(Canvas canvas, double cx, double cy, double maxR, double startAngle, Color color, {required bool clockwise}) {
    final path = Path();
    const steps = 22;
    bool started = false;
    for (int s = 0; s <= steps; s++) {
      final t = s / steps;
      final armR = maxR * t * 0.52;
      final a = startAngle + t * math.pi * 0.65 * (clockwise ? 1 : -1);
      final px = cx + math.cos(a) * armR;
      final py = cy + math.sin(a) * armR;
      if (!started) { path.moveTo(px, py); started = true; }
      else { path.lineTo(px, py); }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.withValues(alpha: 0.36)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
    );
  }

  @override
  bool shouldRepaint(CinematicPortalPainter old) =>
      old.animation != animation || old.pulse != pulse;
}

/// v5.40 - 1.1: Tap Progress Ring Painter
class TapProgressRingPainter extends CustomPainter {
  final double progress;
  final int tapCount;
  final Color color1;
  final Color color2;

  TapProgressRingPainter({
    required this.progress,
    required this.tapCount,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    // Background ring
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, bgPaint);
    
    // Progress ring
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          color1,
          color2,
          const Color(0xFFFFD700),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    final progressRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      progressRect,
      -math.pi / 2, // Start at top
      2 * math.pi * progress, // Progress angle
      false,
      progressPaint,
    );
    
    // Tap count text
    if (tapCount < 10) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$tapCount/10',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: color1.withValues(alpha: 0.8),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - radius - 30,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(TapProgressRingPainter oldDelegate) {
    return progress != oldDelegate.progress || tapCount != oldDelegate.tapCount;
  }
}

/// Subtle grid-line texture for world cards.
class _GridLinePainter extends CustomPainter {
  final Color color;
  _GridLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 0.6;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridLinePainter old) => old.color != color;
}
