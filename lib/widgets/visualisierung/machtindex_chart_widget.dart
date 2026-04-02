/// **WELTENBIBLIOTHEK - STEP 2 VISUALISIERUNG**
/// Machtindex-Chart Widget für Machtstrukturen-Analyse
/// 
/// Zeigt Machtindex-Analysen mit Charts und Statistiken
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Machtindex-Eintrag
class MachtIndexEintrag {
  final String id;
  final String name;
  final String kategorie; // politik, wirtschaft, medien, militär
  final double index; // 0.0 - 100.0
  final double trend; // -100.0 bis +100.0 (Veränderung)
  final Map<String, double> subIndizes; // Detaillierte Indizes
  
  const MachtIndexEintrag({
    required this.id,
    required this.name,
    required this.kategorie,
    required this.index,
    this.trend = 0.0,
    this.subIndizes = const {},
  });
}

class MachtindexChartWidget extends StatefulWidget {
  final List<MachtIndexEintrag> eintraege;
  final String chartTyp; // bar, radar, ranking
  
  const MachtindexChartWidget({
    super.key,
    required this.eintraege,
    this.chartTyp = 'bar',
  });

  @override
  State<MachtindexChartWidget> createState() => _MachtindexChartWidgetState();
}

class _MachtindexChartWidgetState extends State<MachtindexChartWidget> {
  String _selectedChartTyp;
  String _filterKategorie = 'alle';
  MachtIndexEintrag? _selectedEintrag;
  
  _MachtindexChartWidgetState() : _selectedChartTyp = 'bar';
  
  @override
  void initState() {
    super.initState();
    _selectedChartTyp = widget.chartTyp;
  }

  List<MachtIndexEintrag> get _filteredEintraege {
    var filtered = widget.eintraege;
    
    if (_filterKategorie != 'alle') {
      filtered = filtered.where((e) => e.kategorie == _filterKategorie).toList();
    }
    
    filtered.sort((a, b) => b.index.compareTo(a.index));
    return filtered.take(10).toList(); // Top 10
  }

  Color _getKategorieColor(String kategorie) {
    switch (kategorie.toLowerCase()) {
      case 'politik':
        return Colors.blue;
      case 'wirtschaft':
        return Colors.green;
      case 'medien':
        return Colors.orange;
      case 'militär':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.eintraege.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildControls(),
        const SizedBox(height: 16),
        Expanded(
          child: _buildChart(),
        ),
        if (_selectedEintrag != null) _buildEintragDetails(),
      ],
    );
  }

  Widget _buildControls() {
    final kategorien = ['alle', 'politik', 'wirtschaft', 'medien', 'militär'];
    final chartTypen = ['bar', 'radar', 'ranking'];
    
    return Card(
      color: Colors.black.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Kategorie-Filter
            Wrap(
              spacing: 8,
              children: kategorien.map((kategorie) {
                final isSelected = _filterKategorie == kategorie;
                return FilterChip(
                  label: Text(
                    kategorie.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _filterKategorie = kategorie;
                    });
                  },
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  selectedColor: kategorie == 'alle'
                      ? Colors.white
                      : _getKategorieColor(kategorie),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            // Chart-Typ Auswahl
            SegmentedButton<String>(
              segments: chartTypen.map((typ) {
                return ButtonSegment(
                  value: typ,
                  label: Text(typ.toUpperCase()),
                  icon: Icon(_getChartIcon(typ)),
                );
              }).toList(),
              selected: {_selectedChartTyp},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedChartTyp = newSelection.first;
                });
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>(
                  (states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.blue;
                    }
                    return Colors.white.withValues(alpha: 0.1);
                  },
                ),
                foregroundColor: WidgetStateProperty.resolveWith<Color>(
                  (states) {
                    return Colors.white;
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getChartIcon(String typ) {
    switch (typ) {
      case 'bar':
        return Icons.bar_chart;
      case 'radar':
        return Icons.radar;
      case 'ranking':
        return Icons.format_list_numbered;
      default:
        return Icons.analytics;
    }
  }

  Widget _buildChart() {
    switch (_selectedChartTyp) {
      case 'bar':
        return _buildBarChart();
      case 'radar':
        return _buildRadarChart();
      case 'ranking':
        return _buildRankingList();
      default:
        return _buildBarChart();
    }
  }

  Widget _buildBarChart() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(
            touchCallback: (FlTouchEvent event, barTouchResponse) {
              setState(() {
                if (barTouchResponse == null ||
                    barTouchResponse.spot == null ||
                    event is! FlTapUpEvent) {
                  _selectedEintrag = null;
                  return;
                }
                final index = barTouchResponse.spot!.touchedBarGroupIndex;
                _selectedEintrag = _filteredEintraege[index];
              });
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= _filteredEintraege.length) {
                    return const SizedBox.shrink();
                  }
                  final eintrag = _filteredEintraege[index];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      eintrag.name.length > 8
                          ? '${eintrag.name.substring(0, 8)}...'
                          : eintrag.name,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
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
                      color: Colors.white70,
                      fontSize: 12,
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
                color: Colors.white.withValues(alpha: 0.1),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: _filteredEintraege.asMap().entries.map((entry) {
            final index = entry.key;
            final eintrag = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: eintrag.index,
                  color: _getKategorieColor(eintrag.kategorie),
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
    );
  }

  Widget _buildRadarChart() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: RadarChart(
        RadarChartData(
          dataSets: _filteredEintraege.take(5).map((eintrag) {
            final subIndizes = eintrag.subIndizes.values.toList();
            return RadarDataSet(
              fillColor: _getKategorieColor(eintrag.kategorie).withValues(alpha: 0.2),
              borderColor: _getKategorieColor(eintrag.kategorie),
              entryRadius: 3,
              dataEntries: subIndizes.map((value) {
                return RadarEntry(value: value);
              }).toList(),
            );
          }).toList(),
          radarBackgroundColor: Colors.transparent,
          radarBorderData: const BorderSide(color: Colors.transparent),
          titleTextStyle: const TextStyle(color: Colors.white70, fontSize: 12),
          getTitle: (index, angle) {
            final keys = _filteredEintraege.first.subIndizes.keys.toList();
            if (index >= keys.length) return RadarChartTitle(text: '');
            return RadarChartTitle(text: keys[index]);
          },
          tickCount: 5,
          ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 10),
          tickBorderData: const BorderSide(color: Colors.white24),
          gridBorderData: const BorderSide(color: Colors.white24, width: 1),
        ),
      ),
    );
  }

  Widget _buildRankingList() {
    return ListView.builder(
      itemCount: _filteredEintraege.length,
      itemBuilder: (context, index) {
        final eintrag = _filteredEintraege[index];
        final isSelected = _selectedEintrag?.id == eintrag.id;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedEintrag = isSelected ? null : eintrag;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.yellow
                    : _getKategorieColor(eintrag.kategorie).withValues(alpha: 0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Rang
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getKategorieColor(eintrag.kategorie),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Name und Kategorie
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eintrag.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        eintrag.kategorie.toUpperCase(),
                        style: TextStyle(
                          color: _getKategorieColor(eintrag.kategorie),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Index und Trend
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      eintrag.index.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          eintrag.trend > 0
                              ? Icons.arrow_upward
                              : eintrag.trend < 0
                                  ? Icons.arrow_downward
                                  : Icons.remove,
                          color: eintrag.trend > 0
                              ? Colors.green
                              : eintrag.trend < 0
                                  ? Colors.red
                                  : Colors.grey,
                          size: 16,
                        ),
                        Text(
                          '${eintrag.trend.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: eintrag.trend > 0
                                ? Colors.green
                                : eintrag.trend < 0
                                    ? Colors.red
                                    : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEintragDetails() {
    final eintrag = _selectedEintrag!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: _getKategorieColor(eintrag.kategorie),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getKategorieColor(eintrag.kategorie),
                ),
                child: Center(
                  child: Text(
                    eintrag.index.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
                      eintrag.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      eintrag.kategorie.toUpperCase(),
                      style: TextStyle(
                        color: _getKategorieColor(eintrag.kategorie),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => setState(() => _selectedEintrag = null),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (eintrag.subIndizes.isNotEmpty) ...[
            const Text(
              'Detaillierte Indizes:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...eintrag.subIndizes.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          entry.value.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: entry.value / 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(
                        _getKategorieColor(eintrag.kategorie),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Keine Machtindex-Daten verfügbar',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
