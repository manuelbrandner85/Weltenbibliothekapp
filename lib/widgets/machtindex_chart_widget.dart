/// Machtindex-Chart Widget
/// Visualisiert Machtverteilung zwischen Akteuren als Bar-Chart
/// 
/// VERWENDUNG:
/// - Machtstrukturen vergleichen
/// - Einfluss-Hierarchien darstellen
/// - Top-Akteure identifizieren
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/analyse_models.dart';

class MachtindexChartWidget extends StatelessWidget {
  final List<Akteur> akteure;
  final String titel;

  const MachtindexChartWidget({
    super.key,
    required this.akteure,
    this.titel = 'Machtindex-Verteilung',
  });

  @override
  Widget build(BuildContext context) {
    if (akteure.isEmpty) {
      return _buildEmptyState();
    }

    // Sortiere Akteure nach Machtindex (absteigend)
    final sortedAkteure = List<Akteur>.from(akteure)
      ..sort((a, b) => (b.machtindex ?? 0).compareTo(a.machtindex ?? 0));

    // Nimm nur Top 10
    final topAkteure = sortedAkteure.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titel
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            titel,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        // Chart
        Container(
          height: 300,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 1.0,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final akteur = topAkteure[group.x.toInt()];
                    return BarTooltipItem(
                      '${akteur.name}\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(
                          text: 'Machtindex: ${(akteur.machtindex! * 100).toInt()}%',
                          style: TextStyle(
                            color: akteur.farbe,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < topAkteure.length) {
                        final akteur = topAkteure[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Icon(
                            akteur.icon,
                            color: akteur.farbe,
                            size: 16,
                          ),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 0.2,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${(value * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              barGroups: topAkteure.asMap().entries.map((entry) {
                final index = entry.key;
                final akteur = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: akteur.machtindex ?? 0.0,
                      color: akteur.farbe,
                      width: 20,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: 1.0,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                );
              }).toList(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 0.2,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.white.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Legende
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: topAkteure.take(5).map((akteur) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(akteur.icon, color: akteur.farbe, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    akteur.name,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Machtindex-Daten verfügbar',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
