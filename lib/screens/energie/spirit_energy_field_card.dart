/// 🌟 ENERGETISCHE FELDANALYSE - UI KOMPONENTE
/// 
/// Visualisiert das komplette Energiefeld mit allen 8 Analysen:
/// 1. Gesamt-Energiefeld
/// 2. Dominante Frequenzen
/// 3. Schwache Felder
/// 4. Überlagerungen
/// 5. Feldkohärenz
/// 6. Energiefluss-Achsen
/// 7. Resonanzdichte
/// 8. Langzeit-Entwicklung
library;

import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../../models/spirit_energy_field.dart';
import '../../widgets/micro_interactions.dart';

class SpiritEnergyFieldCard extends StatefulWidget {
  final SpiritEnergyField field;
  
  const SpiritEnergyFieldCard({
    super.key,
    required this.field,
  });

  @override
  State<SpiritEnergyFieldCard> createState() => _SpiritEnergyFieldCardState();
}

class _SpiritEnergyFieldCardState extends State<SpiritEnergyFieldCard> {
  int _detailLevel = 0; // 0 = Übersicht, 1 = Detail, 2 = Meta
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header mit Tiefe-Regler
        _buildHeader(),
        const SizedBox(height: 16),
        
        // Inhalt basierend auf Detailstufe
        if (_detailLevel == 0) _buildOverview(),
        if (_detailLevel == 1) _buildDetailView(),
        if (_detailLevel == 2) _buildMetaView(),
      ],
    );
  }
  
  Widget _buildHeader() {
    return HoverGlowCard(
      glowColor: const Color(0xFFFFD700),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF9C27B0).withValues(alpha: 0.4),
              const Color(0xFF673AB7).withValues(alpha: 0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: Column(
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
                  child: const Icon(Icons.energy_savings_leaf, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'ENERGETISCHE FELDANALYSE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Tiefe-Regler
            Row(
              children: [
                const Text(
                  'Ansicht:',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      _buildDetailButton(0, 'Übersicht'),
                      const SizedBox(width: 8),
                      _buildDetailButton(1, 'Detail'),
                      const SizedBox(width: 8),
                      _buildDetailButton(2, 'Meta'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailButton(int level, String label) {
    final isActive = _detailLevel == level;
    
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _detailLevel = level),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive 
              ? const Color(0xFFFFD700).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive 
                ? const Color(0xFFFFD700)
                : Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? const Color(0xFFFFD700) : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
  
  // === ÜBERSICHT (Level 0) ===
  
  Widget _buildOverview() {
    return Column(
      children: [
        // Gesamt-Energiefeld (groß)
        _buildOverallFieldCard(),
        const SizedBox(height: 16),
        
        // Primäre Frequenz
        _buildPrimaryFrequencyCard(),
        const SizedBox(height: 16),
        
        // Schnellübersicht
        _buildQuickStats(),
      ],
    );
  }
  
  Widget _buildOverallFieldCard() {
    return HoverGlowCard(
      glowColor: _getColorFromString(widget.field.fieldColor),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getColorFromString(widget.field.fieldColor).withValues(alpha: 0.3),
              const Color(0xFF1E1E1E),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getColorFromString(widget.field.fieldColor).withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            // Titel
            const Text(
              'DEIN ENERGIEFELD',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFCE93D8),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            
            // Kreis mit Prozent
            SizedBox(
              height: 160,
              width: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Äußerer Kreis
                  CircularProgressIndicator(
                    value: widget.field.overallFieldStrength,
                    strokeWidth: 12,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(
                      _getColorFromString(widget.field.fieldColor),
                    ),
                  ),
                  // Prozent
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(widget.field.overallFieldStrength * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          foreground: Paint()
                            ..shader = LinearGradient(
                              colors: [
                                _getColorFromString(widget.field.fieldColor),
                                Colors.white,
                              ],
                            ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                        ),
                      ),
                      Text(
                        widget.field.fieldQuality,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Feldfarbe und Phase
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getColorFromString(widget.field.fieldColor).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _getColorFromString(widget.field.fieldColor),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _getColorFromString(widget.field.fieldColor).withValues(alpha: 0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.field.fieldColor,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Phase: ${widget.field.currentPhase}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
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
  
  Widget _buildPrimaryFrequencyCard() {
    final freq = widget.field.primaryFrequency;
    
    return HoverGlowCard(
      glowColor: _getColorFromString(freq.color),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getColorFromString(freq.color).withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PRIMÄRE FREQUENZ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _getColorFromString(freq.color),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getColorFromString(freq.color).withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${(freq.strength * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getColorFromString(freq.color),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        freq.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        freq.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: freq.keywords.map((keyword) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getColorFromString(freq.color).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getColorFromString(freq.color).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  keyword,
                  style: TextStyle(
                    fontSize: 10,
                    color: _getColorFromString(freq.color),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatBox(
            'Kohärenz',
            '${(widget.field.coherenceLevel * 100).toInt()}%',
            widget.field.coherenceState,
            const Color(0xFF9C27B0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(
            'Resonanz',
            '${(widget.field.resonanceDensity * 100).toInt()}%',
            '${widget.field.resonancePoints.length} Punkte',
            const Color(0xFFFFD700),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatBox(String label, String value, String detail, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white60,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // === DETAIL-ANSICHT (Level 1) ===
  
  Widget _buildDetailView() {
    return Column(
      children: [
        // Alle Frequenzen
        _buildAllFrequenciesSection(),
        const SizedBox(height: 16),
        
        // Schwache Felder
        _buildWeakFieldsSection(),
        const SizedBox(height: 16),
        
        // Energiefluss
        _buildFlowAxesSection(),
        const SizedBox(height: 16),
        
        // Überlagerungen
        _buildOverlaysSection(),
      ],
    );
  }
  
  Widget _buildAllFrequenciesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ALLE ENERGIEFREQUENZEN',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFCE93D8),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.field.dominantFrequencies.asMap().entries.map((entry) {
            final index = entry.key;
            final freq = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: index < widget.field.dominantFrequencies.length - 1 ? 12 : 0),
              child: _buildFrequencyBar(freq),
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildFrequencyBar(EnergyFrequency freq) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getColorFromString(freq.color),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                freq.name,
                style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${(freq.strength * 100).toInt()}%',
              style: TextStyle(
                fontSize: 11,
                color: _getColorFromString(freq.color),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              FractionallySizedBox(
                widthFactor: freq.strength,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getColorFromString(freq.color),
                        _getColorFromString(freq.color).withValues(alpha: 0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildWeakFieldsSection() {
    if (widget.field.weakFields.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Text(
                'ZU ENTWICKELNDE BEREICHE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.field.weakFields.map((freq) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.circle_outlined, size: 12, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    freq.name,
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
  
  Widget _buildFlowAxesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF673AB7).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ENERGIEFLUSS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9C27B0),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Muster: ${widget.field.flowPattern}',
            style: const TextStyle(fontSize: 11, color: Colors.white60),
          ),
          const SizedBox(height: 16),
          ...widget.field.flowAxes.map((axis) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_getFlowIcon(axis.direction), 
                      color: const Color(0xFF9C27B0), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      axis.direction,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Bereiche: ${axis.areas.join(", ")}',
                  style: const TextStyle(fontSize: 10, color: Colors.white60),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
  
  Widget _buildOverlaysSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ENERGIEÜBERLAGERUNGEN (${widget.field.overlayComplexity} Ebenen)',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.field.overlays.reversed.map((overlay) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: overlay.intensity * 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFFFD700).withValues(alpha: overlay.intensity * 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      overlay.layer,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      overlay.effect,
                      style: const TextStyle(fontSize: 10, color: Colors.white60),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  overlay.energies.join(' • '),
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
  
  // === META-ANSICHT (Level 2) ===
  
  Widget _buildMetaView() {
    return Column(
      children: [
        _buildEvolutionSection(),
        const SizedBox(height: 16),
        _buildInstabilitySection(),
        const SizedBox(height: 16),
        _buildMetaNotesSection(),
      ],
    );
  }
  
  Widget _buildEvolutionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF673AB7).withValues(alpha: 0.3),
            const Color(0xFF1E1E1E),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF673AB7).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FELDENTWICKLUNG',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9C27B0),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.trending_up, color: Color(0xFF9C27B0)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trend: ${widget.field.evolution.trend}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Veränderungsrate: ${(widget.field.evolution.changeRate * 100).toInt()}%',
                      style: const TextStyle(fontSize: 11, color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Meilensteine:',
            style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...widget.field.evolution.milestones.map((milestone) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  ', style: TextStyle(color: Color(0xFF9C27B0))),
                Expanded(
                  child: Text(
                    milestone,
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.arrow_forward, color: Color(0xFF9C27B0), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nächste Phase:',
                        style: TextStyle(fontSize: 10, color: Colors.white60),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.field.nextPhase,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9C27B0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInstabilitySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Text(
                'INSTABILITÄTSZONEN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.field.instabilityZones.map((zone) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    zone,
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Instabilitäten sind natürlich und Teil des Wachstums',
                    style: TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetaNotesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF673AB7).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Color(0xFF9C27B0), size: 20),
              SizedBox(width: 8),
              Text(
                'META-HINWEISE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9C27B0),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetaNote(
            '⚠️ Symbolische Darstellung',
            'Diese Analyse ist modellhaft und symbolisch. Sie zeigt Muster und Tendenzen, keine absoluten Wahrheiten.',
          ),
          const SizedBox(height: 12),
          _buildMetaNote(
            '🔄 Dynamisch',
            'Dein Energiefeld verändert sich ständig. Diese Momentaufnahme reflektiert deinen aktuellen Zustand.',
          ),
          const SizedBox(height: 12),
          _buildMetaNote(
            '🎯 Entwicklung',
            'Schwache Felder sind Potenziale, keine Mängel. Jeder Bereich kann entwickelt werden.',
          ),
          const SizedBox(height: 16),
          Text(
            'Berechnet: ${widget.field.calculatedAt.day}.${widget.field.calculatedAt.month}.${widget.field.calculatedAt.year} | Version ${widget.field.version}',
            style: const TextStyle(fontSize: 9, color: Colors.white38),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetaNote(String title, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9C27B0),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
  
  // === HELPER METHODS ===
  
  Color _getColorFromString(String colorName) {
    const colorMap = {
      'Tiefviolett': Color(0xFF4A148C),
      'Indigoblau': Color(0xFF303F9F),
      'Himmelblau': Color(0xFF1976D2),
      'Türkis': Color(0xFF00ACC1),
      'Smaragdgrün': Color(0xFF00897B),
      'Gelbgrün': Color(0xFF7CB342),
      'Goldgelb': Color(0xFFFDD835),
      'Bernstein': Color(0xFFFFB300),
      'Orange': Color(0xFFFB8C00),
      'Korallenrot': Color(0xFFE53935),
      'Magenta': Color(0xFFAD1457),
      'Silbergrau': Color(0xFF757575),
      'Feuerrot': Color(0xFFE53935),
      'Pastellrosa': Color(0xFFF48FB1),
      'Sonnengelb': Color(0xFFFFEB3B),
      'Erdbraun': Color(0xFF795548),
      'Rosenquarz': Color(0xFFF8BBD0),
      'Violett': Color(0xFF9C27B0),
      'Gold': Color(0xFFFFD700),
      'Regenbogen': Color(0xFF9C27B0),
      'Weißgold': Color(0xFFFFF59D),
      'Platin': Color(0xFFCFD8DC),
      'Kristallklar': Color(0xFFE1F5FE),
    };
    
    return colorMap[colorName] ?? const Color(0xFF9C27B0);
  }
  
  IconData _getFlowIcon(String direction) {
    if (direction.contains('Aufwärts')) return Icons.arrow_upward;
    if (direction.contains('Abwärts')) return Icons.arrow_downward;
    if (direction.contains('Horizontal')) return Icons.arrow_forward;
    return Icons.swap_horiz;
  }
}
