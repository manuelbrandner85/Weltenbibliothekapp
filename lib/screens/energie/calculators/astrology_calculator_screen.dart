import 'package:flutter/material.dart';
import '../../../services/spirit_calculations/astrology_engine.dart';
import '../../../models/energie_profile.dart';
import '../../../core/storage/unified_storage_service.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/micro_interactions.dart';

/// ♈ ASTROLOGIE-RECHNER
class AstrologyCalculatorScreen extends StatefulWidget {
  const AstrologyCalculatorScreen({super.key});

  @override
  State<AstrologyCalculatorScreen> createState() => _AstrologyCalculatorScreenState();
}

class _AstrologyCalculatorScreenState extends State<AstrologyCalculatorScreen> {
  EnergieProfile? _profile;
  Map<String, dynamic>? _sunSign;
  Map<String, dynamic>? _moonSign;
  Map<String, dynamic>? _ascendant;
  Map<String, int>? _elements;
  Map<String, int>? _modalities;
  Map<String, dynamic>? _astroAge;

  @override
  void initState() {
    super.initState();
    _loadAndCalculate();
  }

  void _loadAndCalculate() {
    final profile = StorageService().getEnergieProfile();
    
    if (profile != null) {
      setState(() {
        _profile = profile;
        _sunSign = AstrologyEngine.calculateSunSign(profile.birthDate);
        _moonSign = AstrologyEngine.calculateMoonSign(profile.birthDate);
        _ascendant = AstrologyEngine.calculateAscendant(profile.birthDate, profile.birthTime);
        _elements = AstrologyEngine.calculateElementDistribution(_sunSign!, _moonSign!, _ascendant);
        _modalities = AstrologyEngine.calculateModalityDistribution(_sunSign!, _moonSign!, _ascendant);
        _astroAge = AstrologyEngine.calculateAstrologicalAge(profile.birthDate);
      });
    } else {
      // Kein Profil vorhanden
      setState(() => _profile = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A148C),
        title: const Text('ASTROLOGIE-RECHNER'),
      ),
      body: _profile == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9C27B0)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildZodiacCard('SONNENZEICHEN', _sunSign!, const Color(0xFFFFD700), Icons.wb_sunny),
                  const SizedBox(height: 16),
                  _buildZodiacCard('MONDZEICHEN', _moonSign!, const Color(0xFF9C27B0), Icons.nightlight_round),
                  if (_ascendant != null) ...[
                    const SizedBox(height: 16),
                    _buildZodiacCard('ASZENDENT', _ascendant!, const Color(0xFFE91E63), Icons.arrow_upward),
                  ],
                  const SizedBox(height: 24),
                  _buildElementsCard(),
                  const SizedBox(height: 16),
                  _buildModalitiesCard(),
                  const SizedBox(height: 16),
                  _buildAgeCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildZodiacCard(String title, Map<String, dynamic> sign, Color color, IconData icon) {
    final keywords = (sign['keywords'] as List).cast<String>();
    
    return HoverGlowCard(
      glowColor: color,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.2), const Color(0xFF1E1E1E)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            sign['symbol'],
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            sign['name'],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(sign['element'], const Color(0xFF673AB7)),
                const SizedBox(width: 8),
                _buildInfoChip(sign['modality'], const Color(0xFF7B1FA2)),
                const SizedBox(width: 8),
                _buildInfoChip('Herrscher: ${sign['ruler']}', color.withValues(alpha: 0.8)),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: keywords.map((kw) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  kw,
                  style: TextStyle(fontSize: 11, color: color),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildElementsCard() {
    if (_elements == null) return const SizedBox.shrink();

    return HoverGlowCard(
      glowColor: const Color(0xFF00BCD4),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF00BCD4).withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ELEMENTEVERTEILUNG',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF00BCD4),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            ..._elements!.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDistributionBar(e.key, e.value, _getElementColor(e.key)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildModalitiesCard() {
    if (_modalities == null) return const SizedBox.shrink();

    return HoverGlowCard(
      glowColor: const Color(0xFF9C27B0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MODALITÄTEN',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9C27B0),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            ..._modalities!.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDistributionBar(e.key, e.value, _getModalityColor(e.key)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeCard() {
    if (_astroAge == null) return const SizedBox.shrink();

    return HoverGlowCard(
      glowColor: const Color(0xFFFFD700),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFF4A148C)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4), width: 2),
        ),
        child: Column(
          children: [
            const Icon(Icons.hourglass_bottom, color: Color(0xFFFFD700), size: 48),
            const SizedBox(height: 16),
            Text(
              '${_astroAge!['age']} Jahre',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD700),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Saturn-Phase ${_astroAge!['saturnPhase']}: ${_astroAge!['saturnTheme']}',
              style: const TextStyle(fontSize: 13, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Jupiter-Zyklus ${_astroAge!['jupiterCycle']}: ${_astroAge!['jupiterTheme']}',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionBar(String label, int value, Color color) {
    final maxValue = 3;
    final percentage = value / maxValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.white)),
            Text(value.toString(), style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getElementColor(String element) {
    switch (element) {
      case 'Feuer': return const Color(0xFFE91E63);
      case 'Erde': return const Color(0xFF4CAF50);
      case 'Luft': return const Color(0xFF00BCD4);
      case 'Wasser': return const Color(0xFF673AB7);
      default: return const Color(0xFF9C27B0);
    }
  }

  Color _getModalityColor(String modality) {
    switch (modality) {
      case 'Kardinal': return const Color(0xFFFFD700);
      case 'Fix': return const Color(0xFF9C27B0);
      case 'Veränderlich': return const Color(0xFF00BCD4);
      default: return const Color(0xFF9C27B0);
    }
  }
}
