/// Spirit Cosmic Insights Screen
/// Mondphasen, Chakra-Status und kosmische Einflüsse
library;
import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:flutter/foundation.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../../theme/app_theme.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../../widgets/premium_components.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../../services/moon_phase_service.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../../services/astrological_service.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../../services/planetary_hours_service.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:intl/intl.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'chakra_meditation_screen.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0

class SpiritCosmicInsightsScreen extends StatefulWidget {
  const SpiritCosmicInsightsScreen({super.key});

  @override
  State<SpiritCosmicInsightsScreen> createState() => _SpiritCosmicInsightsScreenState();
}

class _SpiritCosmicInsightsScreenState extends State<SpiritCosmicInsightsScreen> {
  // Services
  final _moonService = MoonPhaseService();
  final _astroService = AstrologicalService();
  final _planetaryHoursService = PlanetaryHoursService();
  
  // Data
  late MoonPhaseData _moonPhase;
  late AstrologicalData _astroData;
  late PlanetaryHour _currentHour;
  
  // Chakra-Status (1-10)
  final Map<String, int> _chakraLevels = {
    'Wurzel': 8,
    'Sakral': 7,
    'Solarplexus': 6,
    'Herz': 9,
    'Hals': 7,
    'Stirn': 8,
    'Krone': 6,
  };

  @override
  void initState() {
    super.initState();
    // Lade aktuelle kosmische Daten
    _moonPhase = _moonService.getCurrentMoonPhase();
    _astroData = _astroService.getCurrentInfluences();
    _currentHour = _planetaryHoursService.getCurrentPlanetaryHour();
    
    if (kDebugMode) {
      debugPrint('🌙 Spirit Cosmic Insights Screen initialisiert');
      debugPrint('🌙 Mondphase: ${_moonPhase.phaseName} (${_moonPhase.illuminationPercent})');
      debugPrint('🌟 Sonne in ${_astroData.sunSign}, Mond in ${_astroData.moonSign}');
      debugPrint('🕐 Planetare Stunde: ${_currentHour.planet}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Kosmische Einflüsse',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF4A148C).withValues(alpha: 0.1),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 24),
              
              // Mondphasen-Widget
              _buildMoonPhaseCard(),
              const SizedBox(height: 20),
              
              // Chakra-Status
              _buildChakraStatusCard(),
              const SizedBox(height: 20),
              
              // Astrologische Einflüsse (Placeholder)
              _buildAstrologicalInfluencesCard(),
              const SizedBox(height: 20),
              
              // Planetare Stunden (Placeholder)
              _buildPlanetaryHoursCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🌌 Kosmische Einflüsse',
          style: AppTheme.headlineLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Verstehe die kosmischen Energien, die dein Leben beeinflussen',
          style: AppTheme.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildMoonPhaseCard() {
    return PremiumCard(
      gradient: LinearGradient(
        colors: [
          Colors.indigo.shade900.withValues(alpha: 0.3),
          Colors.deepPurple.shade900.withValues(alpha: 0.3),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Row(
              children: [
                Text('🌙', style: TextStyle(fontSize: 32)),
                SizedBox(width: 12),
                Text(
                  'Mondphase',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Mond-Visualisierung
            Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.yellow.withValues(alpha: 0.9, red: 1.0, green: 1.0, blue: 0.7),
                      Colors.orange.withValues(alpha: 0.8 * _moonPhase.illumination, red: 1.0, green: 0.6, blue: 0.2),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.yellow.withValues(alpha: 0.4 * _moonPhase.illumination),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _moonPhase.phaseEmoji,
                    style: const TextStyle(fontSize: 80),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Phase Info
            Center(
              child: Column(
                children: [
                  Text(
                    _moonPhase.phaseName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Beleuchtung: ${_moonPhase.illuminationPercent}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _moonPhase.isWaxing ? 'Zunehmend ↗' : 'Abnehmend ↘',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Bedeutung
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.indigo.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💫 Energie der Phase',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _moonPhase.energyDescription,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Aktionen für diese Phase
            _buildMoonPhaseActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildMoonPhaseActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✨ Empfohlene Aktivitäten',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
          ..._moonPhase.recommendedActivities.map((activity) {
            final parts = activity.split(' ');
            final emoji = parts.isNotEmpty ? parts[0] : '✨';
            final text = parts.length > 1 ? parts.sublist(1).join(' ') : activity;
            return _buildActionItem(emoji, text);
          }),
          const SizedBox(height: 16),
          // Nächste Phasen
          _buildNextPhases(),
        ],
      ),
    );
  }

  Widget _buildNextPhases() {
    final dateFormat = DateFormat('dd.MM.yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📅 Nächste Phasen',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 12),
        _buildNextPhaseItem('🌑 Neumond', dateFormat.format(_moonPhase.nextNewMoon)),
        _buildNextPhaseItem('🌓 Erstes Viertel', dateFormat.format(_moonPhase.nextFirstQuarter)),
        _buildNextPhaseItem('🌕 Vollmond', dateFormat.format(_moonPhase.nextFullMoon)),
        _buildNextPhaseItem('🌗 Letztes Viertel', dateFormat.format(_moonPhase.nextLastQuarter)),
      ],
    );
  }

  Widget _buildNextPhaseItem(String phase, String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            phase,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          Text(
            date,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChakraStatusCard() {
    return PremiumCard(
      gradient: LinearGradient(
        colors: [
          Colors.purple.shade800.withValues(alpha: 0.3),
          Colors.pink.shade800.withValues(alpha: 0.3),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Row(
              children: [
                Text('🔮', style: TextStyle(fontSize: 28)),
                SizedBox(width: 12),
                Text(
                  'Chakra-Status',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Deine aktuelle Energieverteilung',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            
            // Chakra-Liste
            ..._chakraLevels.entries.map((entry) {
              return _buildChakraBar(
                entry.key,
                entry.value,
                _getChakraColor(entry.key),
                _getChakraIcon(entry.key),
                _getChakraDescription(entry.key),
              );
            }),
            
            const SizedBox(height: 16),
            
            // Gesamtbalance
            _buildOverallBalance(),
          ],
        ),
      ),
    );
  }

  Widget _buildChakraBar(String name, int level, Color color, String icon, String description) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChakraMeditationScreen(
              chakraName: name,
              chakraColor: color,
              chakraLevel: level,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header mit Icon und Name
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$level/10',
                          style: TextStyle(
                            fontSize: 14,
                            color: color.withValues(alpha: 0.9),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: level / 10,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color,
                          color.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildOverallBalance() {
    final avgLevel = _chakraLevels.values.reduce((a, b) => a + b) / _chakraLevels.length;
    final balancePercentage = (avgLevel / 10 * 100).toInt();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.purple.withValues(alpha: 0.8),
                  Colors.pink.withValues(alpha: 0.6),
                ],
              ),
            ),
            child: Center(
              child: Text(
                '$balancePercentage%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gesamtbalance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getBalanceDescription(balancePercentage),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAstrologicalInfluencesCard() {
    return PremiumCard(
      gradient: LinearGradient(
        colors: [
          Colors.blue.shade900.withValues(alpha: 0.3),
          Colors.cyan.shade900.withValues(alpha: 0.3),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_astroService.getZodiacSymbol(_astroData.sunSign), 
                     style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                const Text(
                  'Astrologische Einflüsse',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Sonne & Mond
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAstrologicalItem(
                    '☉ Sonne',
                    _astroData.sunSign,
                    Colors.orange,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _astroData.sunDescription,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAstrologicalItem(
                    '☽ Mond',
                    _astroData.moonSign,
                    Colors.blue.shade300,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _astroData.moonDescription,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Planeten
            Text(
              'Planetare Positionen',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 12),
            ..._astroData.planetaryPositions.values.map((planet) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        planet.symbol,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  planet.planet,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  planet.sign,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(planet.color),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              planet.influence,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            
            const SizedBox(height: 16),
            
            // Täglicher Einfluss
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✨ Heutiger Einfluss',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _astroData.dailyInfluence,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAstrologicalItem(String planet, String sign, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          planet,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          sign,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanetaryHoursCard() {
    return PremiumCard(
      gradient: LinearGradient(
        colors: [
          Colors.amber.shade900.withValues(alpha: 0.3),
          Colors.orange.shade900.withValues(alpha: 0.3),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_currentHour.symbol, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                const Text(
                  'Planetare Stunden',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Optimale Zeiten für verschiedene Aktivitäten',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            
            // Aktuelle Stunde
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(_currentHour.color).withValues(alpha: 0.3),
                    Color(_currentHour.color).withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(_currentHour.color).withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(_currentHour.color).withValues(alpha: 0.3),
                        ),
                        child: Center(
                          child: Text(
                            _currentHour.symbol,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Jetzt: ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  _currentHour.planet,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(_currentHour.color),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentHour.timeRange,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentHour.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '✨ Empfohlene Aktivitäten:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._currentHour.activities.map((activity) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(_currentHour.color),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              activity,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.8),
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
            const SizedBox(height: 16),
            
            // Nächste Stunden Vorschau
            Text(
              '📅 Kommende Stunden',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 12),
            _buildNextPlanetaryHours(),
          ],
        ),
      ),
    );
  }

  Widget _buildNextPlanetaryHours() {
    final allHours = _planetaryHoursService.getDailyPlanetaryHours(
      DateTime.now(),
      latitude: 48.1351,
      longitude: 11.5820,
    );
    
    // Finde nächste 3 Stunden
    final now = DateTime.now();
    final nextHours = allHours
        .where((h) => h.startTime.isAfter(now))
        .take(3)
        .toList();
    
    return Column(
      children: nextHours.map((hour) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Color(hour.color).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Text(
                hour.symbol,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hour.planet,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hour.timeRange,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(hour.color).withValues(alpha: 0.5),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getChakraColor(String chakra) {
    switch (chakra) {
      case 'Wurzel':
        return Colors.red;
      case 'Sakral':
        return Colors.orange;
      case 'Solarplexus':
        return Colors.yellow;
      case 'Herz':
        return Colors.green;
      case 'Hals':
        return Colors.blue;
      case 'Stirn':
        return Colors.indigo;
      case 'Krone':
        return Colors.purple;
      default:
        return Colors.white;
    }
  }

  String _getChakraIcon(String chakra) {
    switch (chakra) {
      case 'Wurzel':
        return '🔴';
      case 'Sakral':
        return '🟠';
      case 'Solarplexus':
        return '🟡';
      case 'Herz':
        return '💚';
      case 'Hals':
        return '🔵';
      case 'Stirn':
        return '🟣';
      case 'Krone':
        return '⚪';
      default:
        return '⭕';
    }
  }

  String _getChakraDescription(String chakra) {
    switch (chakra) {
      case 'Wurzel':
        return 'Erdung & Stabilität';
      case 'Sakral':
        return 'Kreativität & Emotionen';
      case 'Solarplexus':
        return 'Willenskraft & Selbstvertrauen';
      case 'Herz':
        return 'Liebe & Mitgefühl';
      case 'Hals':
        return 'Kommunikation & Ausdruck';
      case 'Stirn':
        return 'Intuition & Weisheit';
      case 'Krone':
        return 'Spiritualität & Verbindung';
      default:
        return '';
    }
  }

  String _getBalanceDescription(int percentage) {
    if (percentage >= 80) {
      return 'Ausgezeichnete Balance! Deine Energiezentren sind harmonisch ausgerichtet.';
    } else if (percentage >= 60) {
      return 'Gute Balance. Einige Bereiche könnten noch gestärkt werden.';
    } else if (percentage >= 40) {
      return 'Moderate Balance. Fokussiere dich auf schwächere Chakren.';
    } else {
      return 'Energetisches Ungleichgewicht. Zeit für intensive Chakra-Arbeit.';
    }
  }
}
