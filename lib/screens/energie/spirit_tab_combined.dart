/// 🌟 SPIRIT-TAB - NUR TOOLS
/// 
/// Zeigt die 6 Spirit-Rechner (Numerologie, Archetypen, etc.)

import 'package:flutter/material.dart';
import '../../models/energie_profile.dart';
import '../../services/storage_service.dart';
import '../../widgets/hover_glow_card.dart';
import 'calculators/numerology_calculator_screen.dart';
import 'calculators/archetype_calculator_screen.dart';
import 'calculators/chakra_calculator_screen.dart';
import 'calculators/kabbalah_calculator_screen.dart';
import 'calculators/hermetic_calculator_screen.dart';
import 'calculators/gematria_calculator_screen.dart';
import 'calculators/spirit_universal_tool_screen.dart';

class SpiritTabCombined extends StatefulWidget {
  const SpiritTabCombined({super.key});

  @override
  State<SpiritTabCombined> createState() => _SpiritTabCombinedState();
}

class _SpiritTabCombinedState extends State<SpiritTabCombined> {
  final _storage = StorageService();
  
  EnergieProfile? _profile;
  bool _isLoading = true;
  String? _error;
  


  @override
  void initState() {
    super.initState();
    _loadAllModules();
  }

  Future<void> _loadAllModules() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Lade nur das Profil (keine Module mehr)
      final profile = await _storage.loadEnergieProfile();

      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Laden: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF4A148C),
            Color(0xFF1A1A2E),
            Color(0xFF0F0F23),
          ],
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _error != null
                ? _buildErrorState()
                : _buildCombinedContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)),
          ),
          SizedBox(height: 20),
          Text(
            'Lade Spirit-Bereich...',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 20),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadAllModules,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
            ),
            child: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedContent() {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(child: _buildHeader()),

        // NUR SPIRIT-TOOLS (Die 6 Calculators)
        SliverToBoxAdapter(child: _buildToolsSection()),

        // Abstand am Ende
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titel mit Gradient
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF9C27B0), Color(0xFFE91E63), Color(0xFFFFD700)],
            ).createShader(bounds),
            child: const Text(
              'SPIRIT-WELT',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            'Für ${_profile?.firstName ?? ''} ${_profile?.lastName ?? ''}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          
          Text(
            '16 Spirit-Tools',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // SEKTION 1: SPIRIT-TOOLS
  // ========================================

  Widget _buildToolsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFFFFD700)],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'SPIRIT-TOOLS',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Berechnungs-Werkzeuge für spirituelle Erkenntnisse',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),

          // Tools Grid
          _buildToolsGrid(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildToolsGrid() {
    final tools = [
      {
        'icon': Icons.calculate,
        'title': 'Numerologie',
        'subtitle': 'Zahlen deines Lebens',
        'color': const Color(0xFF9C27B0),
        'screen': const NumerologyCalculatorScreen(),
      },
      {
        'icon': Icons.psychology,
        'title': 'Archetypen',
        'subtitle': 'Deine inneren Muster',
        'color': const Color(0xFF673AB7),
        'screen': const ArchetypeCalculatorScreen(),
      },
      {
        'icon': Icons.spa,
        'title': 'Chakren',
        'subtitle': 'Energiezentren',
        'color': const Color(0xFFE91E63),
        'screen': const ChakraCalculatorScreen(),
      },
      {
        'icon': Icons.account_tree,
        'title': 'Kabbala',
        'subtitle': 'Lebensbaum-Analyse',
        'color': const Color(0xFF00BCD4),
        'screen': const KabbalahCalculatorScreen(),
      },
      {
        'icon': Icons.auto_awesome,
        'title': 'Hermetik',
        'subtitle': 'Hermetische Gesetze',
        'color': const Color(0xFFFF9800),
        'screen': const HermeticCalculatorScreen(),
      },
      {
        'icon': Icons.translate,
        'title': 'Gematria',
        'subtitle': 'Zahlen-Buchstaben',
        'color': const Color(0xFF4CAF50),
        'screen': const GematriaCalculatorScreen(),
      },
      // === 10 NEUE SPIRIT-TOOLS ===
      {
        'icon': Icons.bolt,
        'title': 'Energiefeld',
        'subtitle': 'Biofield-Analyse',
        'color': const Color(0xFF00BCD4),
        'screen': const SpiritUniversalToolScreen(
          toolName: 'Energiefeld-Analyse',
          toolIcon: Icons.bolt,
          toolColor: Color(0xFF00BCD4),
          toolType: 'energy_field',
        ),
      },
      {
        'icon': Icons.balance,
        'title': 'Polaritäten',
        'subtitle': 'Yin-Yang Balance',
        'color': const Color(0xFFE91E63),
        'screen': const SpiritUniversalToolScreen(
          toolName: 'Polaritäts-Analyse',
          toolIcon: Icons.balance,
          toolColor: Color(0xFFE91E63),
          toolType: 'polarity',
        ),
      },
      {
        'icon': Icons.transform,
        'title': 'Transformation',
        'subtitle': 'Spirituelle Stufen',
        'color': const Color(0xFF9C27B0),
        'screen': const SpiritUniversalToolScreen(
          toolName: 'Transformations-Analyse',
          toolIcon: Icons.transform,
          toolColor: Color(0xFF9C27B0),
          toolType: 'transformation',
        ),
      },
      {
        'icon': Icons.psychology_outlined,
        'title': 'Unterbewusstsein',
        'subtitle': 'Shadow Work',
        'color': const Color(0xFF4CAF50),
        'screen': const SpiritUniversalToolScreen(
          toolName: 'Unterbewusstseins-Analyse',
          toolIcon: Icons.psychology_outlined,
          toolColor: Color(0xFF4CAF50),
          toolType: 'unconscious',
        ),
      },
      {
        'icon': Icons.explore,
        'title': 'Innere Karten',
        'subtitle': 'Prozessnavigation',
        'color': const Color(0xFFFF9800),
        'screen': const SpiritUniversalToolScreen(
          toolName: 'Innere-Karten-Analyse',
          toolIcon: Icons.explore,
          toolColor: Color(0xFFFF9800),
          toolType: 'inner_maps',
        ),
      },
      {
        'icon': Icons.access_time,
        'title': 'Zyklen',
        'subtitle': 'Saturn Return',
        'color': const Color(0xFF673AB7),
        'screen': const SpiritUniversalToolScreen(
          toolName: 'Zyklus-Analyse',
          toolIcon: Icons.access_time,
          toolColor: Color(0xFF673AB7),
          toolType: 'cycles',
        ),
      },
      {
        'icon': Icons.trending_up,
        'title': 'Orientierung',
        'subtitle': 'Spiral Dynamics',
        'color': const Color(0xFF00BCD4),
        'screen': const SpiritUniversalToolScreen(
          toolName: 'Orientierungs-Analyse',
          toolIcon: Icons.trending_up,
          toolColor: Color(0xFF00BCD4),
          toolType: 'orientation',
        ),
      },
      {
        'icon': Icons.image_aspect_ratio,
        'title': 'Meta-Spiegel',
        'subtitle': 'Synchronizität',
        'color': const Color(0xFFE91E63),
        'screen': const SpiritUniversalToolScreen(
          toolName: 'Meta-Spiegel-Analyse',
          toolIcon: Icons.image_aspect_ratio,
          toolColor: Color(0xFFE91E63),
          toolType: 'meta_mirror',
        ),
      },
      {
        'icon': Icons.remove_red_eye,
        'title': 'Wahrnehmung',
        'subtitle': 'Bewusstseins-Filter',
        'color': const Color(0xFF9C27B0),
        'screen': const SpiritUniversalToolScreen(
          toolName: 'Wahrnehmungs-Analyse',
          toolIcon: Icons.remove_red_eye,
          toolColor: Color(0xFF9C27B0),
          toolType: 'perception',
        ),
      },
      {
        'icon': Icons.list_alt,
        'title': 'Selbstbeobachtung',
        'subtitle': 'Meta-Kognition',
        'color': const Color(0xFF4CAF50),
        'screen': const SpiritUniversalToolScreen(
          toolName: 'Selbstbeobachtungs-Analyse',
          toolIcon: Icons.list_alt,
          toolColor: Color(0xFF4CAF50),
          toolType: 'self_observation',
        ),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return _buildToolCard(
          icon: tool['icon'] as IconData,
          title: tool['title'] as String,
          subtitle: tool['subtitle'] as String,
          color: tool['color'] as Color,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => tool['screen'] as Widget),
          ),
        );
      },
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isActive = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: HoverGlowCard(
        glowColor: color,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isActive 
                            ? [color, color.withValues(alpha: 0.6)]
                            : [color.withValues(alpha: 0.3), color.withValues(alpha: 0.1)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon, 
                        color: Colors.white.withValues(alpha: isActive ? 1.0 : 0.5), 
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: isActive ? 1.0 : 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),

                    // Subtitle
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: isActive ? 0.6 : 0.3),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // "In Entwicklung" Badge
              if (!isActive)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'BALD',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
