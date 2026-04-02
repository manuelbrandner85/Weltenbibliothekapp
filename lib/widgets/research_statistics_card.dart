/// Professionelle Statistik-Karten für Research-Tools
/// Version: 2.0.0
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/responsive_utils.dart';
import '../utils/responsive_text_styles.dart';
import '../utils/responsive_spacing.dart';

class ForschungsStatistikKarte extends StatelessWidget {
  final String titel;
  final String untertitel;
  final IconData icon;
  final Color farbe;
  final List<StatistikElement> elemente;
  
  const ForschungsStatistikKarte({
    super.key,
    required this.titel,
    required this.untertitel,
    required this.icon,
    required this.farbe,
    required this.elemente,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textStyles = context.textStyles;
    
    return Container(
      padding: context.paddingMd,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            farbe.withValues(alpha: 0.15),
            const Color(0xFF1A1A1A),
          ],
        ),
        borderRadius: BorderRadius.circular(responsive.borderRadiusLg),
        border: Border.all(
          color: farbe.withValues(alpha: 0.3),
          width: responsive.borderRadiusXs / 3,
        ),
        boxShadow: [
          BoxShadow(
            color: farbe.withValues(alpha: 0.1),
            blurRadius: responsive.spacingMd,
            offset: Offset(0, responsive.spacingXs),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: context.paddingSm,
                decoration: BoxDecoration(
                  color: farbe.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(responsive.borderRadiusSm),
                ),
                child: Icon(
                  icon,
                  color: farbe,
                  size: responsive.iconSizeLg,
                ),
              ),
              context.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titel,
                      style: textStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: responsive.spacingXs / 2),
                    Text(
                      untertitel,
                      style: textStyles.labelSmall.copyWith(
                        color: farbe.withValues(alpha: 0.8),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          context.vSpaceMd,
          
          // Statistik-Elemente
          ...elemente.map((element) => _buildStatElement(context, element)),
        ],
      ),
    );
  }

  Widget _buildStatElement(BuildContext context, StatistikElement element) {
    final responsive = context.responsive;
    final textStyles = context.textStyles;
    
    return Container(
      margin: EdgeInsets.only(bottom: responsive.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                element.bezeichnung,
                style: textStyles.bodySmall.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                element.wert,
                style: textStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: element.farbeWert ?? farbe,
                ),
              ),
            ],
          ),
          if (element.prozent != null) ...[
            SizedBox(height: responsive.spacingXs / 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(responsive.borderRadiusXs),
              child: LinearProgressIndicator(
                value: element.prozent!,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  element.farbeWert ?? farbe,
                ),
                minHeight: responsive.spacingXs / 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StatistikElement {
  final String bezeichnung;
  final String wert;
  final double? prozent; // 0.0 - 1.0
  final Color? farbeWert;
  
  StatistikElement({
    required this.bezeichnung,
    required this.wert,
    this.prozent,
    this.farbeWert,
  });
}

// ═══════════════════════════════════════════════════════════════
// KREISDIAGRAMM-WIDGET
// ═══════════════════════════════════════════════════════════════

class KreisdiagrammKarte extends StatelessWidget {
  final String titel;
  final List<KreisSegment> segmente;
  final Color hauptfarbe;
  
  const KreisdiagrammKarte({
    super.key,
    required this.titel,
    required this.segmente,
    required this.hauptfarbe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: segmente.map((segment) {
                  return PieChartSectionData(
                    color: segment.farbe,
                    value: segment.wert,
                    title: '${segment.wert.toInt()}%',
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Legende
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: segmente.map((segment) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: segment.farbe,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    segment.bezeichnung,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class KreisSegment {
  final String bezeichnung;
  final double wert;
  final Color farbe;
  
  KreisSegment({
    required this.bezeichnung,
    required this.wert,
    required this.farbe,
  });
}

// ═══════════════════════════════════════════════════════════════
// BALKENDIAGRAMM-WIDGET
// ═══════════════════════════════════════════════════════════════

class BalkendiagrammKarte extends StatelessWidget {
  final String titel;
  final List<BalkenDaten> daten;
  final Color hauptfarbe;
  final String xAchsenBezeichnung;
  final String yAchsenBezeichnung;
  
  const BalkendiagrammKarte({
    super.key,
    required this.titel,
    required this.daten,
    required this.hauptfarbe,
    required this.xAchsenBezeichnung,
    required this.yAchsenBezeichnung,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: daten.isEmpty ? 100 : daten.map((d) => d.wert).reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= daten.length) return const Text('');
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            daten[value.toInt()].bezeichnung,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 10,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white10,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: daten.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.wert,
                        color: entry.value.farbe ?? hauptfarbe,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Achsenbezeichnungen
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                xAchsenBezeichnung,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white60,
                  fontStyle: FontStyle.italic,
                ),
              ),
              Text(
                yAchsenBezeichnung,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white60,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BalkenDaten {
  final String bezeichnung;
  final double wert;
  final Color? farbe;
  
  BalkenDaten({
    required this.bezeichnung,
    required this.wert,
    this.farbe,
  });
}

// ═══════════════════════════════════════════════════════════════
// ZEITREIHEN-DIAGRAMM
// ═══════════════════════════════════════════════════════════════

class ZeitreihenDiagramm extends StatelessWidget {
  final String titel;
  final List<ZeitpunktDaten> daten;
  final Color linienfarbe;
  
  const ZeitreihenDiagramm({
    super.key,
    required this.titel,
    required this.daten,
    required this.linienfarbe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white10,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= daten.length) return const Text('');
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            daten[value.toInt()].bezeichnung,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: daten.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.wert);
                    }).toList(),
                    isCurved: true,
                    color: linienfarbe,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: linienfarbe,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: linienfarbe.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ZeitpunktDaten {
  final String bezeichnung; // z.B. "2020", "Jan", "Q1"
  final double wert;
  
  ZeitpunktDaten({
    required this.bezeichnung,
    required this.wert,
  });
}
