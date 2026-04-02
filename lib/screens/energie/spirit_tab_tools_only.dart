import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../../widgets/micro_interactions.dart';
import 'calculators/numerology_calculator_screen.dart';
import 'calculators/archetype_calculator_screen.dart';
import 'calculators/chakra_calculator_screen.dart';
import 'calculators/kabbalah_calculator_screen.dart';
import 'calculators/hermetic_calculator_screen.dart';
import 'calculators/gematria_calculator_screen.dart';
import 'frequency_generator_screen.dart'; // ✅ FIXED: Missing import
// ✨ NEW 15 SPIRIT TOOLS
import 'calculators/new_spirit_tool_screens.dart';

/// ✨ SPIRIT-TAB (NUR BERECHNUNGS-TOOLS)
/// 
/// KONZEPT: Reine Berechnungs-Werkzeuge, keine Dashboard-Daten
/// 
/// INHALT:
/// - Numerologie-Rechner
/// - Archetypen-Analyse
/// - Astrologie-Berechnung
/// - Synchronizitäts-Tracker
/// - Name-Energie-Analyse
/// - Chakra-Rechner
class SpiritTabToolsOnly extends StatefulWidget {
  const SpiritTabToolsOnly({super.key});

  @override
  State<SpiritTabToolsOnly> createState() => _SpiritTabToolsOnlyState();
}

class _SpiritTabToolsOnlyState extends State<SpiritTabToolsOnly> {
  String _selectedCategory = 'Alle';

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
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildDashboardButton(),
                const SizedBox(height: 24),
                _buildStatsCard(),
                const SizedBox(height: 24),
                _buildCategoryFilter(),
                const SizedBox(height: 24),
                _buildToolsGrid(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF9C27B0), Color(0xFFFFD700)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SPIRIT BERECHNUNGS-CENTER',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '21 Professionelle Analyse-Systeme',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFCE93D8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF1E1E1E)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('6', 'Systeme', Icons.apps),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildStatItem('25+', 'Tabs', Icons.tab),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildStatItem('100+', 'Berechnungen', Icons.functions),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFFD700), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFFCE93D8),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['Alle', 'Numerologie', 'Archetypen', 'Astrologie', 'Chakren', 'Synchronizität'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'KATEGORIEN',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFFCE93D8),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _selectedCategory == category;

              return InkWell(
                onTap: () => setState(() => _selectedCategory = category),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF9C27B0), Color(0xFFFFD700)],
                          )
                        : null,
                    color: isSelected ? null : const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : const Color(0xFF9C27B0).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white : const Color(0xFFCE93D8),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BERECHNUNGS-TOOLS',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFFCE93D8),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                'Numerologie',
                'Lebensweg berechnen',
                Icons.calculate,
                const Color(0xFF9C27B0),
                badge: 'BELIEBT',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildToolCard(
                'Gematria',
                'Zahlen in Wörtern',
                Icons.calculate,
                const Color(0xFF673AB7),
                badge: 'LIVE',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                'Kabbala',
                'Baum des Lebens',
                Icons.account_tree,
                const Color(0xFFE91E63),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildToolCard(
                'Hermetik',
                'Das Kybalion',
                Icons.menu_book,
                const Color(0xFFFFD700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                'Archetypen',
                'C.G. Jung Analyse',
                Icons.psychology,
                const Color(0xFF7B1FA2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildToolCard(
                'Chakra-Rechner',
                'Energie-Zentren',
                Icons.spa,
                const Color(0xFF4A148C),
              ),
            ),
          ],
        ),
        
        // ✨ ROW 4: NEW SPIRIT TOOLS
        const SizedBox(height: 16),
        const Text(
          'NEUE SPIRIT-TOOLS',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFFCE93D8),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                'Mondphasen',
                '8 Mondzyklen',
                Icons.nightlight_round,
                const Color(0xFF5E35B1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildToolCard(
                'Tarot',
                'Tagesziehung',
                Icons.auto_fix_high,
                const Color(0xFF7B1FA2),
                badge: 'NEU',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                'Kristalle',
                '50+ Heilsteine',
                Icons.diamond,
                const Color(0xFF1976D2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildToolCard(
                'Meditation',
                'Timer & Gong',
                Icons.self_improvement,
                const Color(0xFF00897B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                'Aura',
                'Farb-Analyse',
                Icons.wb_sunny,
                const Color(0xFFFFB300),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildToolCard(
                'DNA',
                '12-Strang DNA',
                Icons.biotech,
                const Color(0xFFD32F2F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                'Frequenzen',
                'Solfeggio',
                Icons.music_note,
                const Color(0xFFD32F2F),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildToolCard(
                'Akasha',
                'Chronik-Journal',
                Icons.book,
                const Color(0xFF00897B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                'Mantras',
                'Heilige Klänge',
                Icons.spa,
                const Color(0xFFE65100),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildToolCard(
                'Geometrie',
                'Heilige Formen',
                Icons.hexagon,
                const Color(0xFF5E35B1),
                badge: 'NEU',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                'Erdung',
                '4 Übungen',
                Icons.landscape,
                const Color(0xFF5E35B1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildToolCard(
                'Transformation',
                'Meilensteine',
                Icons.track_changes,
                const Color(0xFF00897B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                'Lichtsprache',
                '8 Codes',
                Icons.star,
                const Color(0xFFFFA000),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildToolCard(
                'Yoga',
                '6 Asanas',
                Icons.self_improvement,
                const Color(0xFF7B1FA2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                'Göttinnen',
                'Orakel',
                Icons.auto_awesome,
                const Color(0xFFE91E63),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()), // Placeholder
          ],
        ),
      ],
    );
  }

  Widget _buildToolCard(String title, String description, IconData icon, Color color, {String? badge}) {
    return HoverGlowCard(
      glowColor: color,
      onTap: () {
        if (title == 'Numerologie') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NumerologyCalculatorScreen()),
          );
        } else if (title == 'Archetypen') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ArchetypeCalculatorScreen()),
          );
        } else if (title == 'Chakra-Rechner') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChakraCalculatorScreen()),
          );
        } else if (title == 'Kabbala') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const KabbalahCalculatorScreen()),
          );
        } else if (title == 'Hermetik') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HermeticCalculatorScreen()),
          );
        } else if (title == 'Gematria') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GematriaCalculatorScreen()),
          );
        }
        // ✨ NEW 15 SPIRIT TOOLS NAVIGATION
        else if (title == 'Mondphasen') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MoonPhaseTrackerScreen()));
        } else if (title == 'Tarot') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TarotDailyDrawScreen()));
        } else if (title == 'Kristalle') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CrystalDatabaseScreen()));
        } else if (title == 'Meditation') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MeditationTimerScreen()));
        } else if (title == 'Aura') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AuraColorReaderScreen()));
        } else if (title == 'DNA') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DnaActivationTrackerScreen()));
        } else if (title == 'Frequenzen') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FrequencyGeneratorScreen()));
        } else if (title == 'Akasha') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AkashaChronicleJournalScreen()));
        } else if (title == 'Mantras') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MantraLibraryScreen()));
        } else if (title == 'Geometrie') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SacredGeometryScreen()));
        } else if (title == 'Erdung') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const GroundingExercisesScreen()));
        } else if (title == 'Transformation') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TransformationTrackerScreen()));
        } else if (title == 'Lichtsprache') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const LightLanguageDecoderScreen()));
        } else if (title == 'Yoga') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const YogaAsanaGuideScreen()));
        } else if (title == 'Göttinnen') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const GoddessOracleScreen()));
        } 
        else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title wird geöffnet...'),
              backgroundColor: color,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.2),
              const Color(0xFF1E1E1E),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDashboardButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/dashboard');
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1976D2).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.dashboard,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 Dashboard',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Deine spirituelle Reise auf einen Blick',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
