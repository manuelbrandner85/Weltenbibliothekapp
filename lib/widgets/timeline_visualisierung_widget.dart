/// Timeline-Visualisierungs-Widget
/// Zeigt historische Ereignisse auf einer interaktiven Zeitachse
/// 
/// VERWENDUNG:
/// - Historischer Kontext darstellen
/// - Ereignisse chronologisch visualisieren
/// - Zusammenhänge über Zeit zeigen
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/analyse_models.dart';

class TimelineVisualisierungWidget extends StatefulWidget {
  final List<HistorischerKontext> ereignisse;
  final String titel;

  const TimelineVisualisierungWidget({
    super.key,
    required this.ereignisse,
    this.titel = 'Historische Timeline',
  });

  @override
  State<TimelineVisualisierungWidget> createState() => 
      _TimelineVisualisierungWidgetState();
}

class _TimelineVisualisierungWidgetState 
    extends State<TimelineVisualisierungWidget> {
  
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.ereignisse.isEmpty) {
      return _buildEmptyState();
    }

    // Ereignisse chronologisch sortieren
    final sortedEreignisse = List<HistorischerKontext>.from(widget.ereignisse)
      ..sort((a, b) => a.datum.compareTo(b.datum));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titel
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            widget.titel,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        // Timeline-Chart
        Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: _buildTimelineChart(sortedEreignisse),
        ),

        const SizedBox(height: 16),

        // Ereignis-Liste
        ...sortedEreignisse.asMap().entries.map((entry) {
          final index = entry.key;
          final ereignis = entry.value;
          return _buildEreignisKarte(ereignis, index);
        }),
      ],
    );
  }

  Widget _buildTimelineChart(List<HistorischerKontext> ereignisse) {
    if (ereignisse.isEmpty) return const SizedBox();

    // Erstelle Daten-Punkte für das Chart
    final spots = ereignisse.asMap().entries.map((entry) {
      final index = entry.key;
      final ereignis = entry.value;
      return FlSpot(
        index.toDouble(),
        ereignis.istVerifiziert ? 1.0 : 0.5,
      );
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 0.5,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.white.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
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
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < ereignisse.length) {
                  final ereignis = ereignisse[index];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${ereignis.datum.year}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 0.5,
              getTitlesWidget: (value, meta) {
                if (value == 1.0) {
                  return const Text(
                    'Verifiziert',
                    style: TextStyle(color: Colors.green, fontSize: 10),
                  );
                } else if (value == 0.5) {
                  return const Text(
                    'Ungeprüft',
                    style: TextStyle(color: Colors.orange, fontSize: 10),
                  );
                }
                return const Text('');
              },
              reservedSize: 60,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        minX: 0,
        maxX: (ereignisse.length - 1).toDouble(),
        minY: 0,
        maxY: 1.5,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final ereignis = ereignisse[index];
                return FlDotCirclePainter(
                  radius: 6,
                  color: ereignis.istVerifiziert ? Colors.green : Colors.orange,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
            setState(() {
              if (touchResponse == null ||
                  touchResponse.lineBarSpots == null ||
                  touchResponse.lineBarSpots!.isEmpty) {
                _selectedIndex = null;
              } else {
                _selectedIndex = touchResponse.lineBarSpots!.first.x.toInt();
              }
            });
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final ereignis = ereignisse[barSpot.x.toInt()];
                return LineTooltipItem(
                  ereignis.ereignis,
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEreignisKarte(HistorischerKontext ereignis, int index) {
    final istSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedIndex = istSelected ? null : index;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: istSelected
                  ? const Color(0xFF2E2E2E)
                  : const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ereignis.istVerifiziert
                    ? Colors.green.withValues(alpha: istSelected ? 0.5 : 0.3)
                    : Colors.orange.withValues(alpha: istSelected ? 0.5 : 0.3),
                width: istSelected ? 2 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Datum-Marker
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: ereignis.istVerifiziert ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    if (!istSelected)
                      Container(
                        width: 2,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                  ],
                ),
                
                const SizedBox(width: 12),
                
                // Ereignis-Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            ereignis.istVerifiziert ? Icons.verified : Icons.warning,
                            size: 14,
                            color: ereignis.istVerifiziert ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDatum(ereignis.datum),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: ereignis.istVerifiziert ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ereignis.ereignis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (istSelected) ...[
                        const SizedBox(height: 6),
                        Text(
                          ereignis.beschreibung,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        if (ereignis.quelle != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.link,
                                size: 12,
                                color: Colors.blue.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  ereignis.quelle!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue.withValues(alpha: 0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
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
              Icons.timeline,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Timeline-Daten verfügbar',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDatum(DateTime datum) {
    return '${datum.day.toString().padLeft(2, '0')}.${datum.month.toString().padLeft(2, '0')}.${datum.year}';
  }
}
