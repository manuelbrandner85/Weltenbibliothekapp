/// ⚖️ SPIRIT-MODUL 2: POLARITÄTEN & AUSGLEICHSMODELLE - UI KARTE
/// 
/// Visualisiert alle 8 Polaritäts-Berechnungen in einer detaillierten Karte
library;

import 'package:flutter/material.dart';
import '../../models/spirit_polarities.dart';
import '../../widgets/hover_glow_card.dart';

class SpiritPolaritiesCard extends StatelessWidget {
  final SpiritPolarities polarities;

  const SpiritPolaritiesCard({
    super.key,
    required this.polarities,
  });

  @override
  Widget build(BuildContext context) {
    return HoverGlowCard(
      glowColor: const Color(0xFFE91E63), // Pink für Polaritäten
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE91E63).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const Divider(color: Color(0xFFE91E63), thickness: 1),

            // Inhalt mit Tabs für die 8 Analysen
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE91E63).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.balance,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),

          // Titel & Meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'POLARITÄTEN & AUSGLEICHSMODELLE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE91E63),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Für ${polarities.profileName}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Version ${polarities.version} • Berechnet: ${_formatDateTime(polarities.calculatedAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return DefaultTabController(
      length: 8,
      child: Column(
        children: [
          // Tab Bar
          Container(
            color: const Color(0xFF2A2A2A),
            child: TabBar(
              isScrollable: true,
              indicatorColor: const Color(0xFFE91E63),
              labelColor: const Color(0xFFE91E63),
              unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'AKTIV ↔ PASSIV'),
                Tab(text: 'ORDNUNG ↔ CHAOS'),
                Tab(text: 'KONTROLLE ↔ HINGABE'),
                Tab(text: 'EXPANSION ↔ RÜCKZUG'),
                Tab(text: 'SPANNUNGSACHSEN'),
                Tab(text: 'BALANCE-ZUSTÄNDE'),
                Tab(text: 'ÜBERSTEUERUNG'),
                Tab(text: 'INTEGRATIONSPOLE'),
              ],
            ),
          ),

          // Tab Views
          SizedBox(
            height: 600,
            child: TabBarView(
              children: [
                _buildActivePassiveTab(),
                _buildOrderChaosTab(),
                _buildControlSurrenderTab(),
                _buildExpansionWithdrawalTab(),
                _buildTensionAxesTab(),
                _buildBalanceStatesTab(),
                _buildOversteeringTab(),
                _buildIntegrationPolesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // TAB 1: AKTIV ↔ PASSIV
  // ========================================

  Widget _buildActivePassiveTab() {
    final data = polarities.activePassiveDominance;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dominanter Pol Badge
          _buildDominanceBadge(data.dominantPole, data.currentPhase),
          const SizedBox(height: 20),

          // Balance-Verhältnis Visualisierung
          _buildPolarityBar(
            'AKTIV',
            data.activeScore,
            'PASSIV',
            data.passiveScore,
            const Color(0xFFFF6B6B),
            const Color(0xFF4ECDC4),
          ),
          const SizedBox(height: 16),
          Text(
            'Balance-Verhältnis: ${data.balanceRatio.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFE91E63),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Aktive Indikatoren
          if (data.activeIndicators.isNotEmpty) ...[
            const Text(
              'AKTIVE INDIKATOREN',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B6B),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...data.activeIndicators.map((indicator) => _buildIndicatorItem(
                  indicator,
                  const Color(0xFFFF6B6B),
                  Icons.trending_up,
                )),
            const SizedBox(height: 20),
          ],

          // Passive Indikatoren
          if (data.passiveIndicators.isNotEmpty) ...[
            const Text(
              'PASSIVE INDIKATOREN',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4ECDC4),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...data.passiveIndicators.map((indicator) => _buildIndicatorItem(
                  indicator,
                  const Color(0xFF4ECDC4),
                  Icons.trending_down,
                )),
            const SizedBox(height: 20),
          ],

          // Interpretation
          _buildInterpretationBox(data.interpretation),
        ],
      ),
    );
  }

  // ========================================
  // TAB 2: ORDNUNG ↔ CHAOS
  // ========================================

  Widget _buildOrderChaosTab() {
    final data = polarities.orderChaosAxis;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dominanter Pol
          _buildDominanceBadge(data.dominantPole, data.currentNeed),
          const SizedBox(height: 20),

          // Polaritäts-Visualisierung
          _buildPolarityBar(
            'ORDNUNG',
            data.orderScore,
            'CHAOS',
            data.chaosScore,
            const Color(0xFF3498DB),
            const Color(0xFFE74C3C),
          ),
          const SizedBox(height: 20),

          // Stabilität & Kreativität
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Stabilität',
                  data.stabilityLevel,
                  const Color(0xFF3498DB),
                  Icons.lock,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Chaos-Kreativität',
                  data.chaosCreativity,
                  const Color(0xFFE74C3C),
                  Icons.bolt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Ordnungs-Muster
          if (data.orderPatterns.isNotEmpty) ...[
            const Text(
              'ORDNUNGS-MUSTER',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3498DB),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...data.orderPatterns.map((pattern) => _buildIndicatorItem(
                  pattern,
                  const Color(0xFF3498DB),
                  Icons.grid_on,
                )),
            const SizedBox(height: 20),
          ],

          // Chaos-Muster
          if (data.chaosPatterns.isNotEmpty) ...[
            const Text(
              'CHAOS-MUSTER',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE74C3C),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...data.chaosPatterns.map((pattern) => _buildIndicatorItem(
                  pattern,
                  const Color(0xFFE74C3C),
                  Icons.scatter_plot,
                )),
            const SizedBox(height: 20),
          ],

          // Interpretation
          _buildInterpretationBox(data.interpretation),
        ],
      ),
    );
  }

  // ========================================
  // TAB 3: KONTROLLE ↔ HINGABE
  // ========================================

  Widget _buildControlSurrenderTab() {
    final data = polarities.controlSurrenderBalance;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dominanter Modus
          _buildDominanceBadge(data.dominantMode, data.currentLesson),
          const SizedBox(height: 20),

          // Polaritäts-Visualisierung
          _buildPolarityBar(
            'KONTROLLE',
            data.controlScore,
            'HINGABE',
            data.surrenderScore,
            const Color(0xFF8E44AD),
            const Color(0xFF1ABC9C),
          ),
          const SizedBox(height: 20),

          // Vertrauen & Angst
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Vertrauens-Level',
                  data.trustLevel,
                  const Color(0xFF1ABC9C),
                  Icons.favorite,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Angst vor Verlust',
                  data.fearOfLoss,
                  const Color(0xFF8E44AD),
                  Icons.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Kontroll-Bereiche
          if (data.controlAreas.isNotEmpty) ...[
            const Text(
              'KONTROLL-BEREICHE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8E44AD),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...data.controlAreas.map((area) => _buildIndicatorItem(
                  area,
                  const Color(0xFF8E44AD),
                  Icons.settings,
                )),
            const SizedBox(height: 20),
          ],

          // Hingabe-Bereiche
          if (data.surrenderAreas.isNotEmpty) ...[
            const Text(
              'HINGABE-BEREICHE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1ABC9C),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...data.surrenderAreas.map((area) => _buildIndicatorItem(
                  area,
                  const Color(0xFF1ABC9C),
                  Icons.air,
                )),
            const SizedBox(height: 20),
          ],

          // Aktuelle Lektion Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE91E63).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.school, color: Color(0xFFE91E63), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'AKTUELLE LEKTION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE91E63),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  data.currentLesson,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Interpretation
          _buildInterpretationBox(data.interpretation),
        ],
      ),
    );
  }

  // ========================================
  // TAB 4: EXPANSION ↔ RÜCKZUG
  // ========================================

  Widget _buildExpansionWithdrawalTab() {
    final data = polarities.expansionWithdrawal;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aktuelle Richtung
          _buildDominanceBadge(data.currentDirection, data.healthyBalance),
          const SizedBox(height: 20),

          // Polaritäts-Visualisierung
          _buildPolarityBar(
            'EXPANSION',
            data.expansionScore,
            'RÜCKZUG',
            data.withdrawalScore,
            const Color(0xFFF39C12),
            const Color(0xFF34495E),
          ),
          const SizedBox(height: 16),

          // Energie-Fluss Indikator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ENERGIE-FLUSS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF39C12),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.arrow_back, color: Color(0xFF34495E)),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (data.energyFlow + 100) / 200,
                        backgroundColor: const Color(0xFF34495E).withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF39C12)),
                      ),
                    ),
                    const Icon(Icons.arrow_forward, color: Color(0xFFF39C12)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  data.energyFlow > 0
                      ? 'Nach außen fließend (+${data.energyFlow.toStringAsFixed(0)})'
                      : 'Nach innen fließend (${data.energyFlow.toStringAsFixed(0)})',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Expansions-Bereiche
          if (data.expansionAreas.isNotEmpty) ...[
            const Text(
              'EXPANSIONS-BEREICHE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF39C12),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...data.expansionAreas.map((area) => _buildIndicatorItem(
                  area,
                  const Color(0xFFF39C12),
                  Icons.open_in_full,
                )),
            const SizedBox(height: 20),
          ],

          // Rückzugs-Bereiche
          if (data.withdrawalAreas.isNotEmpty) ...[
            const Text(
              'RÜCKZUGS-BEREICHE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF34495E),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...data.withdrawalAreas.map((area) => _buildIndicatorItem(
                  area,
                  const Color(0xFF34495E),
                  Icons.close_fullscreen,
                )),
            const SizedBox(height: 20),
          ],

          // Zyklisches Muster
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE91E63).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.autorenew, color: Color(0xFFE91E63), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'ZYKLISCHES MUSTER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE91E63),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  data.cyclicPattern,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Interpretation
          _buildInterpretationBox(data.interpretation),
        ],
      ),
    );
  }

  // ========================================
  // TAB 5: SPANNUNGSACHSEN
  // ========================================

  Widget _buildTensionAxesTab() {
    final data = polarities.innerTensionAxes;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gesamt-Spannung
          _buildMetricCard(
            'Gesamt-Spannung',
            data.overallTension,
            _getTensionColor(data.overallTension),
            Icons.graphic_eq,
          ),
          const SizedBox(height: 20),

          // Höchste & Niedrigste Spannung
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HÖCHSTE SPANNUNG',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data.highestTension,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NIEDRIGSTE SPANNUNG',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data.lowestTension,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Alle Spannungsachsen
          const Text(
            'SPANNUNGSACHSEN',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE91E63),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          ...data.axes.map((axis) => _buildTensionAxisCard(axis)),

          const SizedBox(height: 24),

          // Konfliktbereiche
          if (data.conflictAreas.isNotEmpty) ...[
            const Text(
              'KONFLIKTBEREICHE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...data.conflictAreas.map((area) => _buildIndicatorItem(
                  area,
                  Colors.orange,
                  Icons.warning_amber,
                )),
            const SizedBox(height: 20),
          ],

          // Auflösungs-Pfad
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE91E63).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb, color: Color(0xFFE91E63), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'AUFLÖSUNGS-PFAD',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE91E63),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  data.resolutionPath,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Interpretation
          _buildInterpretationBox(data.interpretation),
        ],
      ),
    );
  }

  // ========================================
  // TAB 6: BALANCE-ZUSTÄNDE
  // ========================================

  Widget _buildBalanceStatesTab() {
    final data = polarities.balanceStates;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gesamt-Balance
          _buildMetricCard(
            'Gesamt-Balance',
            data.overallBalance,
            _getBalanceColor(data.overallBalance),
            Icons.balance,
          ),
          const SizedBox(height: 20),

          // Balance-Typ Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Balance-Typ: ${data.balanceType}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Dimensionen-Balance
          const Text(
            'BALANCE PRO DIMENSION',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE91E63),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          ...data.dimensionBalances.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${entry.value.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 13,
                            color: _getBalanceColor(entry.value),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: entry.value / 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getBalanceColor(entry.value),
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 24),

          // Beste & Schlechteste Balance
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AM BESTEN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data.mostBalanced,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AM WENIGSTEN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data.leastBalanced,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stärken
          if (data.balanceStrengths.isNotEmpty) ...[
            const Text(
              'BALANCE-STÄRKEN',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...data.balanceStrengths.map((strength) => _buildIndicatorItem(
                  strength,
                  Colors.green,
                  Icons.check_circle,
                )),
            const SizedBox(height: 20),
          ],

          // Schwächen
          if (data.balanceWeaknesses.isNotEmpty) ...[
            const Text(
              'BALANCE-SCHWÄCHEN',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...data.balanceWeaknesses.map((weakness) => _buildIndicatorItem(
                  weakness,
                  Colors.orange,
                  Icons.warning,
                )),
            const SizedBox(height: 20),
          ],

          // Interpretation
          _buildInterpretationBox(data.interpretation),
        ],
      ),
    );
  }

  // ========================================
  // TAB 7: ÜBERSTEUERUNG
  // ========================================

  Widget _buildOversteeringTab() {
    final data = polarities.oversteeringIndicators;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gesamt-Übersteuerung & Dringlichkeit
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Gesamt-Übersteuerung',
                  data.overallOversteering,
                  _getOversteeringColor(data.overallOversteering),
                  Icons.speed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getUrgencyColor(data.urgencyLevel).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getUrgencyIcon(data.urgencyLevel),
                            color: _getUrgencyColor(data.urgencyLevel),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'DRINGLICHKEIT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data.urgencyLevel,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getUrgencyColor(data.urgencyLevel),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Am meisten übersteuert
          if (data.mostOversteered != 'Keine Übersteuerung') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AM MEISTEN ÜBERSTEUERT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.mostOversteered,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Übersteuerungs-Bereiche
          if (data.areas.isNotEmpty) ...[
            const Text(
              'ÜBERSTEUERUNGS-BEREICHE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE91E63),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...data.areas.map((area) => _buildOversteeringAreaCard(area)),
            const SizedBox(height: 24),
          ],

          // Symptome
          if (data.symptoms.isNotEmpty) ...[
            const Text(
              'SYMPTOME',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...data.symptoms.map((symptom) => _buildIndicatorItem(
                  symptom,
                  Colors.orange,
                  Icons.healing,
                )),
            const SizedBox(height: 20),
          ],

          // Korrekturen
          if (data.corrections.isNotEmpty) ...[
            const Text(
              'KORREKTUR-VORSCHLÄGE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...data.corrections.map((correction) => _buildIndicatorItem(
                  correction,
                  Colors.green,
                  Icons.build,
                )),
            const SizedBox(height: 20),
          ],

          // Interpretation
          _buildInterpretationBox(data.interpretation),
        ],
      ),
    );
  }

  // ========================================
  // TAB 8: INTEGRATIONSPOLE
  // ========================================

  Widget _buildIntegrationPolesTab() {
    final data = polarities.integrationPoles;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Integrations-Fortschritt & Qualität
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Integrations-Fortschritt',
                  data.integrationProgress,
                  _getProgressColor(data.integrationProgress),
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getQualityColor(data.integrationQuality).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getQualityIcon(data.integrationQuality),
                            color: _getQualityColor(data.integrationQuality),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'QUALITÄT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data.integrationQuality,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getQualityColor(data.integrationQuality),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Nächster Integrationspol
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NÄCHSTER INTEGRATIONSPOL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.nearestPole,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Nächste Schritte
          if (data.integrationSteps.isNotEmpty) ...[
            const Text(
              'NÄCHSTE SCHRITTE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE91E63),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...data.integrationSteps.map((step) => _buildIndicatorItem(
                  step,
                  const Color(0xFFE91E63),
                  Icons.arrow_forward,
                )),
            const SizedBox(height: 24),
          ],

          // Alle Integrationspole
          const Text(
            'ALLE INTEGRATIONSPOLE',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE91E63),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          ...data.poles.map((pole) => _buildIntegrationPoleCard(pole)),

          const SizedBox(height: 20),

          // Interpretation
          _buildInterpretationBox(data.interpretation),
        ],
      ),
    );
  }

  // ========================================
  // HELPER WIDGETS
  // ========================================

  Widget _buildDominanceBadge(String dominant, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dominant.toUpperCase(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolarityBar(
    String label1,
    double value1,
    String label2,
    double value2,
    Color color1,
    Color color2,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label1,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color1,
                ),
              ),
              Text(
                label2,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    flex: value1.toInt(),
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          bottomLeft: Radius.circular(6),
                        ),
                        color: color1,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: value2.toInt(),
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(6),
                          bottomRight: Radius.circular(6),
                        ),
                        color: color2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${value1.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: color1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${value2.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: color2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${value.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: value / 100,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorItem(String text, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterpretationBox(String interpretation) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE91E63).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Color(0xFFE91E63), size: 20),
              const SizedBox(width: 8),
              const Text(
                'INTERPRETATION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE91E63),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            interpretation,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTensionAxisCard(TensionAxis axis) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getTensionColor(axis.tensionLevel).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            axis.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _getTensionColor(axis.tensionLevel),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  axis.pole1,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  axis.pole2,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: axis.tensionLevel / 100,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              _getTensionColor(axis.tensionLevel),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spannung: ${axis.tensionLevel.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: _getTensionColor(axis.tensionLevel),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                axis.currentPull,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOversteeringAreaCard(OversteeringArea area) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getOversteeringColor(area.level).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                area.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getOversteeringColor(area.level),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getOversteeringColor(area.level).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  area.direction,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getOversteeringColor(area.level),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: area.level / 100,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              _getOversteeringColor(area.level),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Impact: ${area.impact}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationPoleCard(IntegrationPole pole) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getProgressColor(100 - pole.distance).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pole.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getProgressColor(100 - pole.distance),
                ),
              ),
              Text(
                '${(100 - pole.distance).toStringAsFixed(0)}% nah',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getProgressColor(100 - pole.distance),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            pole.description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (100 - pole.distance) / 100,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(100 - pole.distance),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Erforderlich:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE91E63),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          ...pole.requirements.map((req) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_right, color: Color(0xFFE91E63), size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        req,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ========================================
  // COLOR HELPERS
  // ========================================

  Color _getTensionColor(double tension) {
    if (tension > 70) return Colors.red;
    if (tension > 40) return Colors.orange;
    return Colors.green;
  }

  Color _getBalanceColor(double balance) {
    if (balance > 70) return Colors.green;
    if (balance > 40) return Colors.orange;
    return Colors.red;
  }

  Color _getOversteeringColor(double level) {
    if (level > 70) return Colors.red;
    if (level > 40) return Colors.orange;
    return Colors.yellow;
  }

  Color _getProgressColor(double progress) {
    if (progress > 70) return Colors.green;
    if (progress > 40) return const Color(0xFFE91E63);
    return Colors.orange;
  }

  Color _getUrgencyColor(String urgency) {
    if (urgency == 'Hoch') return Colors.red;
    if (urgency == 'Mittel') return Colors.orange;
    return Colors.green;
  }

  Color _getQualityColor(String quality) {
    if (quality == 'Ganzheitlich') return Colors.green;
    if (quality == 'Teilweise') return Colors.orange;
    return Colors.red;
  }

  IconData _getUrgencyIcon(String urgency) {
    if (urgency == 'Hoch') return Icons.priority_high;
    if (urgency == 'Mittel') return Icons.warning;
    return Icons.check_circle;
  }

  IconData _getQualityIcon(String quality) {
    if (quality == 'Ganzheitlich') return Icons.check_circle;
    if (quality == 'Teilweise') return Icons.donut_large;
    return Icons.scatter_plot;
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
