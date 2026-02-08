/// **WELTENBIBLIOTHEK - STEP 3 VISUALISIERUNG**
/// Karte Widget für Standorte und Organisationen
/// 
/// Zeigt geografische Standorte von Akteuren und Organisationen
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Standort auf der Karte
class KartenStandort {
  final String id;
  final String name;
  final LatLng position;
  final String typ; // organisation, ereignis, person, regierung
  final String beschreibung;
  final List<String> verbindungen; // IDs anderer Standorte
  final double wichtigkeit; // 0.0 - 1.0
  
  const KartenStandort({
    required this.id,
    required this.name,
    required this.position,
    required this.typ,
    required this.beschreibung,
    this.verbindungen = const [],
    this.wichtigkeit = 0.5,
  });
}

class KarteWidget extends StatefulWidget {
  final List<KartenStandort> standorte;
  final LatLng? initialCenter;
  final double initialZoom;
  
  const KarteWidget({
    super.key,
    required this.standorte,
    this.initialCenter,
    this.initialZoom = 5.0,
  });

  @override
  State<KarteWidget> createState() => _KarteWidgetState();
}

class _KarteWidgetState extends State<KarteWidget> {
  final MapController _mapController = MapController();
  KartenStandort? _selectedStandort;
  String _filterTyp = 'alle';
  bool _showConnections = true;
  
  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  List<KartenStandort> get _filteredStandorte {
    if (_filterTyp == 'alle') {
      return widget.standorte;
    }
    return widget.standorte.where((s) => s.typ == _filterTyp).toList();
  }

  LatLng get _center {
    if (widget.initialCenter != null) {
      return widget.initialCenter!;
    }
    if (widget.standorte.isEmpty) {
      return const LatLng(51.1657, 10.4515); // Deutschland Zentrum
    }
    
    double avgLat = 0;
    double avgLng = 0;
    for (final standort in widget.standorte) {
      avgLat += standort.position.latitude;
      avgLng += standort.position.longitude;
    }
    return LatLng(
      avgLat / widget.standorte.length,
      avgLng / widget.standorte.length,
    );
  }

  Color _getTypColor(String typ) {
    switch (typ.toLowerCase()) {
      case 'organisation':
        return Colors.blue;
      case 'ereignis':
        return Colors.red;
      case 'person':
        return Colors.green;
      case 'regierung':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypIcon(String typ) {
    switch (typ.toLowerCase()) {
      case 'organisation':
        return Icons.business;
      case 'ereignis':
        return Icons.event;
      case 'person':
        return Icons.person;
      case 'regierung':
        return Icons.account_balance;
      default:
        return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.standorte.isEmpty) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: widget.initialZoom,
            minZoom: 2.0,
            maxZoom: 18.0,
            onTap: (_, __) => setState(() => _selectedStandort = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.dualrealms.knowledge',
              tileBuilder: _darkModeTileBuilder,
            ),
            if (_showConnections) _buildConnectionsLayer(),
            _buildMarkersLayer(),
          ],
        ),
        _buildControls(),
        if (_selectedStandort != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildStandortDetails(),
          ),
      ],
    );
  }

  Widget _darkModeTileBuilder(BuildContext context, Widget tileWidget, TileImage tile) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        -1, 0, 0, 0, 255,
        0, -1, 0, 0, 255,
        0, 0, -1, 0, 255,
        0, 0, 0, 1, 0,
      ]),
      child: tileWidget,
    );
  }

  Widget _buildConnectionsLayer() {
    final polylines = <Polyline>[];
    
    for (final standort in _filteredStandorte) {
      for (final verbindungId in standort.verbindungen) {
        final ziel = widget.standorte.firstWhere(
          (s) => s.id == verbindungId,
          orElse: () => standort,
        );
        
        if (ziel.id != standort.id) {
          polylines.add(
            Polyline(
              points: [standort.position, ziel.position],
              strokeWidth: 2,
              color: _getTypColor(standort.typ).withValues(alpha: 0.3),
              // isDotted removed in flutter_map 7.0.2 - use pattern instead
              pattern: const StrokePattern.dotted(),
            ),
          );
        }
      }
    }
    
    return PolylineLayer(polylines: polylines);
  }

  Widget _buildMarkersLayer() {
    return MarkerLayer(
      markers: _filteredStandorte.map((standort) {
        final size = 40.0 + (standort.wichtigkeit * 30.0); // 40-70px
        final isSelected = _selectedStandort?.id == standort.id;
        
        return Marker(
          point: standort.position,
          width: size,
          height: size,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedStandort = isSelected ? null : standort;
              });
              if (!isSelected) {
                _mapController.move(standort.position, _mapController.camera.zoom);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getTypColor(standort.typ),
                border: Border.all(
                  color: isSelected ? Colors.yellow : Colors.white.withValues(alpha: 0.7),
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getTypColor(standort.typ).withValues(alpha: 0.7),
                    blurRadius: isSelected ? 15 : 8,
                    spreadRadius: isSelected ? 3 : 1,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  _getTypIcon(standort.typ),
                  color: Colors.white,
                  size: size * 0.5,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildControls() {
    final typen = ['alle', 'organisation', 'ereignis', 'person', 'regierung'];
    
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        color: Colors.black.withValues(alpha: 0.8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Filter-Chips
              Wrap(
                spacing: 8,
                children: typen.map((typ) {
                  final isSelected = _filterTyp == typ;
                  return FilterChip(
                    label: Text(
                      typ.toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _filterTyp = typ;
                      });
                    },
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    selectedColor: typ == 'alle'
                        ? Colors.white
                        : _getTypColor(typ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              // Verbindungen Toggle
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: _showConnections,
                    onChanged: (value) {
                      setState(() {
                        _showConnections = value;
                      });
                    },
                    activeThumbColor: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Verbindungen anzeigen',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Zoom Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.zoom_in, color: Colors.white),
                    onPressed: () {
                      final newZoom = (_mapController.camera.zoom + 1).clamp(2.0, 18.0);
                      _mapController.move(_mapController.camera.center, newZoom);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.zoom_out, color: Colors.white),
                    onPressed: () {
                      final newZoom = (_mapController.camera.zoom - 1).clamp(2.0, 18.0);
                      _mapController.move(_mapController.camera.center, newZoom);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.my_location, color: Colors.white),
                    onPressed: () {
                      _mapController.move(_center, widget.initialZoom);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStandortDetails() {
    final standort = _selectedStandort!;
    final verbundeneStandorte = widget.standorte
        .where((s) => standort.verbindungen.contains(s.id))
        .toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: _getTypColor(standort.typ),
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
                _getTypIcon(standort.typ),
                color: _getTypColor(standort.typ),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      standort.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      standort.typ.toUpperCase(),
                      style: TextStyle(
                        color: _getTypColor(standort.typ),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => setState(() => _selectedStandort = null),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            standort.beschreibung,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.place,
                size: 16,
                color: Colors.white54,
              ),
              const SizedBox(width: 4),
              Text(
                '${standort.position.latitude.toStringAsFixed(4)}, ${standort.position.longitude.toStringAsFixed(4)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          if (verbundeneStandorte.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Verbindungen:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: verbundeneStandorte.map((s) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedStandort = s;
                    });
                    _mapController.move(s.position, _mapController.camera.zoom);
                  },
                  child: Chip(
                    avatar: Icon(
                      _getTypIcon(s.typ),
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      s.name,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: _getTypColor(s.typ).withValues(alpha: 0.5),
                  ),
                );
              }).toList(),
            ),
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
            Icons.map,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Keine Standortdaten verfügbar',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
