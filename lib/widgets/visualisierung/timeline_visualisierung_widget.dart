/// **WELTENBIBLIOTHEK - STEP 3 VISUALISIERUNG**
/// Timeline-Visualisierung Widget für historische Ereignisse
/// 
/// Zeigt chronologische Abfolge von Ereignissen mit Kontext und Quellen
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Historisches Ereignis
class ZeitEreignis {
  final String id;
  final DateTime datum;
  final String titel;
  final String beschreibung;
  final String kategorie; // politik, wirtschaft, gesellschaft, militär
  final List<String> quellen;
  final double relevanz; // 0.0 - 1.0
  
  const ZeitEreignis({
    required this.id,
    required this.datum,
    required this.titel,
    required this.beschreibung,
    required this.kategorie,
    this.quellen = const [],
    this.relevanz = 0.5,
  });
}

class TimelineVisualisierungWidget extends StatefulWidget {
  final List<ZeitEreignis> ereignisse;
  final String? highlightedId;
  
  const TimelineVisualisierungWidget({
    super.key,
    required this.ereignisse,
    this.highlightedId,
  });

  @override
  State<TimelineVisualisierungWidget> createState() => _TimelineVisualisierungWidgetState();
}

class _TimelineVisualisierungWidgetState extends State<TimelineVisualisierungWidget> {
  final ScrollController _scrollController = ScrollController();
  ZeitEreignis? _selectedEreignis;
  String _filterKategorie = 'alle';
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<ZeitEreignis> get _filteredEreignisse {
    var filtered = widget.ereignisse;
    
    if (_filterKategorie != 'alle') {
      filtered = filtered.where((e) => e.kategorie == _filterKategorie).toList();
    }
    
    filtered.sort((a, b) => a.datum.compareTo(b.datum));
    return filtered;
  }

  Color _getKategorieColor(String kategorie) {
    switch (kategorie.toLowerCase()) {
      case 'politik':
        return Colors.blue;
      case 'wirtschaft':
        return Colors.green;
      case 'gesellschaft':
        return Colors.purple;
      case 'militär':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getKategorieIcon(String kategorie) {
    switch (kategorie.toLowerCase()) {
      case 'politik':
        return Icons.gavel;
      case 'wirtschaft':
        return Icons.trending_up;
      case 'gesellschaft':
        return Icons.people;
      case 'militär':
        return Icons.shield;
      default:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ereignisse.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildFilter(),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _filteredEreignisse.length,
            itemBuilder: (context, index) {
              final ereignis = _filteredEreignisse[index];
              final isLast = index == _filteredEreignisse.length - 1;
              final isHighlighted = ereignis.id == widget.highlightedId;
              
              return _buildTimelineItem(ereignis, isLast, isHighlighted);
            },
          ),
        ),
        if (_selectedEreignis != null) _buildEreignisDetails(),
      ],
    );
  }

  Widget _buildFilter() {
    final kategorien = ['alle', 'politik', 'wirtschaft', 'gesellschaft', 'militär'];
    
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: kategorien.length,
        itemBuilder: (context, index) {
          final kategorie = kategorien[index];
          final isSelected = _filterKategorie == kategorie;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                kategorie.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
              checkmarkColor: Colors.black,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineItem(ZeitEreignis ereignis, bool isLast, bool isHighlighted) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline-Achse
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getKategorieColor(ereignis.kategorie),
                  border: Border.all(
                    color: isHighlighted ? Colors.yellow : Colors.white.withValues(alpha: 0.5),
                    width: isHighlighted ? 3 : 2,
                  ),
                  boxShadow: isHighlighted
                      ? [
                          BoxShadow(
                            color: Colors.yellow.withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  _getKategorieIcon(ereignis.kategorie),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Ereignis-Karte
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildEreignisCard(ereignis, isHighlighted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEreignisCard(ZeitEreignis ereignis, bool isHighlighted) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedEreignis = _selectedEreignis?.id == ereignis.id ? null : ereignis;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighlighted
                ? Colors.yellow
                : _getKategorieColor(ereignis.kategorie).withValues(alpha: 0.5),
            width: isHighlighted ? 2 : 1,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: Colors.yellow.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Datum
            Text(
              DateFormat('dd. MMMM yyyy', 'de_DE').format(ereignis.datum),
              style: TextStyle(
                color: _getKategorieColor(ereignis.kategorie),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Titel
            Text(
              ereignis.titel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Beschreibung
            Text(
              ereignis.beschreibung,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Relevanz-Indikator
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: ereignis.relevanz,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(
                      _getKategorieColor(ereignis.kategorie),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(ereignis.relevanz * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            if (ereignis.quellen.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${ereignis.quellen.length} Quelle${ereignis.quellen.length != 1 ? 'n' : ''}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEreignisDetails() {
    final ereignis = _selectedEreignis!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: _getKategorieColor(ereignis.kategorie),
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
              Icon(
                _getKategorieIcon(ereignis.kategorie),
                color: _getKategorieColor(ereignis.kategorie),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ereignis.titel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('dd. MMMM yyyy', 'de_DE').format(ereignis.datum),
                      style: TextStyle(
                        color: _getKategorieColor(ereignis.kategorie),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => setState(() => _selectedEreignis = null),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            ereignis.beschreibung,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          if (ereignis.quellen.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Quellen:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...ereignis.quellen.map((quelle) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_right,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 16,
                  ),
                  Expanded(
                    child: Text(
                      quelle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
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
            Icons.timeline,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Keine Timeline-Daten verfügbar',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
