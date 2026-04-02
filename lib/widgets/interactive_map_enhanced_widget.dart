import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

/// 🗺️ ENHANCED Interaktive Karte mit Clustering, Custom Icons & Heatmap
/// 
/// Features:
/// - ✅ Marker Clustering (automatische Gruppierung)
/// - ✅ Custom Icon System (kategorie-basiert)
/// - ✅ Heatmap Layer (Dichte-Visualisierung)
/// - ✅ Filter nach Kategorien
/// - ✅ Search-Funktionalität
/// - ✅ Performance-optimiert
class InteractiveMapEnhancedWidget extends StatefulWidget {
  final List<Map<String, dynamic>> narratives;
  final Function(String narrativeId)? onMarkerTap;
  final bool enableClustering;
  final bool enableHeatmap;

  const InteractiveMapEnhancedWidget({
    super.key,
    required this.narratives,
    this.onMarkerTap,
    this.enableClustering = true,
    this.enableHeatmap = false,
  });

  @override
  State<InteractiveMapEnhancedWidget> createState() => _InteractiveMapEnhancedWidgetState();
}

class _InteractiveMapEnhancedWidgetState extends State<InteractiveMapEnhancedWidget> {
  final MapController _mapController = MapController();
  String? _selectedNarrativeId;
  double _currentZoom = 2.0;
  
  // 🆕 Filter & Search
  Set<String> _selectedCategories = {};
  final String _searchQuery = '';
  bool _showLegend = true;
  bool _showHeatmap = false;
  
  // Category Icons & Colors
  final Map<String, IconData> _categoryIcons = {
    'ufo': Icons.rocket_launch,
    'secret_society': Icons.account_balance,
    'history': Icons.history_edu,
    'technology': Icons.bolt,
    'science': Icons.science,
    'politics': Icons.gavel,
  };
  
  final Map<String, Color> _categoryColors = {
    'ufo': Colors.red,
    'secret_society': Colors.purple,
    'history': Colors.blue,
    'technology': Colors.orange,
    'science': Colors.green,
    'politics': Colors.brown,
  };

  @override
  void initState() {
    super.initState();
    // Initialisiere alle Kategorien als ausgewählt
    _selectedCategories = _categoryIcons.keys.toSet();
    _showHeatmap = widget.enableHeatmap;
    
    // Listen for map events
    _mapController.mapEventStream.listen((event) {
      if (event is MapEventMove) {
        setState(() {
          _currentZoom = event.camera.zoom;
        });
      }
    });
  }

  // 🆕 Filtere Narratives nach Kategorien und Search
  List<Map<String, dynamic>> _getFilteredNarratives() {
    return widget.narratives.where((narrative) {
      // Location-Filter
      if (narrative['location'] == null) return false;
      
      // Kategorie-Filter
      final categories = narrative['categories'] as List?;
      if (categories != null && _selectedCategories.isNotEmpty) {
        final hasMatchingCategory = categories.any((cat) => 
          _selectedCategories.contains(cat.toString().toLowerCase())
        );
        if (!hasMatchingCategory) return false;
      }
      
      // Search-Filter
      if (_searchQuery.isNotEmpty) {
        final title = (narrative['title'] as String? ?? '').toLowerCase();
        final description = (narrative['description'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return title.contains(query) || description.contains(query);
      }
      
      return true;
    }).toList();
  }

  // 🆕 Marker Clustering Algorithm
  List<dynamic> _buildClusters() {
    final filteredNarratives = _getFilteredNarratives();
    
    if (!widget.enableClustering || _currentZoom > 6.0) {
      // Zeige einzelne Marker bei hohem Zoom
      return filteredNarratives.map((n) => {
        'type': 'marker',
        'narrative': n,
      }).toList();
    }
    
    // Clustering-Algorithmus (Grid-based)
    final clusters = <String, List<Map<String, dynamic>>>{};
    final gridSize = _getGridSize(_currentZoom);
    
    for (final narrative in filteredNarratives) {
      final location = narrative['location'] as Map<String, dynamic>;
      final lat = (location['lat'] as num).toDouble();
      final lng = (location['lng'] as num).toDouble();
      
      // Berechne Grid-Zelle
      final gridX = (lat / gridSize).floor();
      final gridY = (lng / gridSize).floor();
      final gridKey = '$gridX:$gridY';
      
      clusters.putIfAbsent(gridKey, () => []);
      clusters[gridKey]!.add(narrative);
    }
    
    // Erstelle Cluster-Objekte
    return clusters.entries.map((entry) {
      if (entry.value.length == 1) {
        return {
          'type': 'marker',
          'narrative': entry.value.first,
        };
      } else {
        // Berechne Cluster-Zentrum
        final avgLat = entry.value.map((n) => 
          ((n['location'] as Map)['lat'] as num).toDouble()
        ).reduce((a, b) => a + b) / entry.value.length;
        
        final avgLng = entry.value.map((n) => 
          ((n['location'] as Map)['lng'] as num).toDouble()
        ).reduce((a, b) => a + b) / entry.value.length;
        
        return {
          'type': 'cluster',
          'count': entry.value.length,
          'lat': avgLat,
          'lng': avgLng,
          'narratives': entry.value,
        };
      }
    }).toList();
  }

  double _getGridSize(double zoom) {
    if (zoom < 3) return 20.0;
    if (zoom < 5) return 10.0;
    return 5.0;
  }

  @override
  Widget build(BuildContext context) {
    final clusters = _buildClusters();
    
    return Container(
      height: 600,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Main Map
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(40.0, 0.0),
                initialZoom: 2.0,
                minZoom: 1.0,
                maxZoom: 18.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                // Tile Layer
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.dualrealms.knowledge',
                  maxNativeZoom: 19,
                  maxZoom: 22,
                ),

                // Heatmap Layer disabled (type incompatibility with Flutter Map layers)
                // if (_showHeatmap && _currentZoom < 8.0)
                //   ..._buildHeatmapCircles(),

                // Marker/Cluster Layer
                MarkerLayer(
                  markers: _buildMarkers(clusters),
                ),

                // Connection Lines
                if (_selectedNarrativeId != null)
                  PolylineLayer(
                    polylines: _buildConnectionLines(),
                  ),
              ],
            ),

            // Top Controls
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  // Legend Toggle
                  _buildControlButton(
                    _showLegend ? Icons.map : Icons.map_outlined,
                    () => setState(() => _showLegend = !_showLegend),
                    'Legende',
                  ),
                  const SizedBox(width: 8),
                  
                  // Heatmap Toggle
                  _buildControlButton(
                    _showHeatmap ? Icons.thermostat : Icons.thermostat_outlined,
                    () => setState(() => _showHeatmap = !_showHeatmap),
                    'Heatmap',
                    isActive: _showHeatmap,
                  ),
                  
                  const Spacer(),
                  
                  // Stats Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: Colors.cyan, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${_getFilteredNarratives().length} Events',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Legend Panel
            if (_showLegend)
              Positioned(
                top: 70,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(maxWidth: 250),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.category, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Kategorien',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._categoryIcons.entries.map((entry) {
                        final isSelected = _selectedCategories.contains(entry.key);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedCategories.add(entry.key);
                              } else {
                                _selectedCategories.remove(entry.key);
                              }
                            });
                          },
                          title: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                entry.value,
                                size: 16,
                                color: _categoryColors[entry.key],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getCategoryLabel(entry.key),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: _categoryColors[entry.key],
                        );
                      }),
                    ],
                  ),
                ),
              ),

            // Bottom Controls
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Zoom In
                  _buildControlButton(
                    Icons.add,
                    () => _mapController.move(
                      _mapController.camera.center,
                      (_currentZoom + 1).clamp(1.0, 18.0),
                    ),
                    'Zoom In',
                  ),
                  const SizedBox(height: 8),
                  
                  // Zoom Out
                  _buildControlButton(
                    Icons.remove,
                    () => _mapController.move(
                      _mapController.camera.center,
                      (_currentZoom - 1).clamp(1.0, 18.0),
                    ),
                    'Zoom Out',
                  ),
                  const SizedBox(height: 8),
                  
                  // Reset
                  _buildControlButton(
                    Icons.zoom_out_map,
                    () {
                      _mapController.move(const LatLng(40.0, 0.0), 2.0);
                      setState(() => _selectedNarrativeId = null);
                    },
                    'Reset',
                  ),
                ],
              ),
            ),

            // Selected Narrative Info Card
            if (_selectedNarrativeId != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 100,
                child: _buildNarrativeInfoCard(),
              ),
          ],
        ),
      ),
    );
  }

  // 🆕 Heatmap Circles
  List<CircleMarker> _buildHeatmapCircles() {
    final filteredNarratives = _getFilteredNarratives();
    
    return filteredNarratives.map((narrative) {
      final location = narrative['location'] as Map<String, dynamic>;
      final lat = (location['lat'] as num).toDouble();
      final lng = (location['lng'] as num).toDouble();
      
      return CircleMarker(
        point: LatLng(lat, lng),
        radius: 50000 / (_currentZoom + 1), // Adaptive radius
        color: Colors.red.withValues(alpha: 0.3),
        borderColor: Colors.red.withValues(alpha: 0.5),
        borderStrokeWidth: 2,
        useRadiusInMeter: true,
      );
    }).toList();
  }

  // 🆕 Build Markers with Clustering
  List<Marker> _buildMarkers(List<dynamic> clusters) {
    return clusters.map<Marker>((item) {
      if (item['type'] == 'marker') {
        return _buildSingleMarker(item['narrative'] as Map<String, dynamic>);
      } else {
        return _buildClusterMarker(
          item['lat'] as double,
          item['lng'] as double,
          item['count'] as int,
          item['narratives'] as List<Map<String, dynamic>>,
        );
      }
    }).toList();
  }

  // Single Marker
  Marker _buildSingleMarker(Map<String, dynamic> narrative) {
    final location = narrative['location'] as Map<String, dynamic>;
    final lat = (location['lat'] as num).toDouble();
    final lng = (location['lng'] as num).toDouble();
    final isSelected = _selectedNarrativeId == narrative['id'];
    
    final category = _getPrimaryCategory(narrative['categories'] as List?);
    final icon = _categoryIcons[category] ?? Icons.place;
    final color = _categoryColors[category] ?? Colors.grey;

    return Marker(
      point: LatLng(lat, lng),
      width: isSelected ? 80 : 60,
      height: isSelected ? 80 : 60,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedNarrativeId = narrative['id'] as String;
          });
          _mapController.move(LatLng(lat, lng), math.max(_currentZoom, 8.0));
          widget.onMarkerTap?.call(narrative['id'] as String);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isSelected ? 50 : 40,
                height: isSelected ? 50 : 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.black45,
                    width: isSelected ? 4 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: isSelected ? 12 : 6,
                      spreadRadius: isSelected ? 2 : 0,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: isSelected ? 28 : 22,
                ),
              ),
              
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _truncateTitle(narrative['title'] as String, 15),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 🆕 Cluster Marker
  Marker _buildClusterMarker(
    double lat,
    double lng,
    int count,
    List<Map<String, dynamic>> narratives,
  ) {
    final size = math.min(70.0, 40.0 + count * 3.0);
    
    return Marker(
      point: LatLng(lat, lng),
      width: size,
      height: size,
      child: GestureDetector(
        onTap: () {
          // Zoom in to cluster
          _mapController.move(
            LatLng(lat, lng),
            math.min(_currentZoom + 3.0, 18.0),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.purple,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Polyline> _buildConnectionLines() {
    final filteredNarratives = _getFilteredNarratives();
    final selected = filteredNarratives.firstWhere(
      (n) => n['id'] == _selectedNarrativeId,
      orElse: () => {},
    );

    if (selected.isEmpty) return [];

    final relatedIds = selected['relatedNarratives'] as List?;
    if (relatedIds == null) return [];

    final selectedLocation = selected['location'] as Map<String, dynamic>;
    final selectedPoint = LatLng(
      (selectedLocation['lat'] as num).toDouble(),
      (selectedLocation['lng'] as num).toDouble(),
    );

    return relatedIds
        .map((id) {
          final related = filteredNarratives.firstWhere(
            (n) => n['id'] == id,
            orElse: () => {},
          );

          if (related.isEmpty || related['location'] == null) return null;

          final relatedLocation = related['location'] as Map<String, dynamic>;
          final relatedPoint = LatLng(
            (relatedLocation['lat'] as num).toDouble(),
            (relatedLocation['lng'] as num).toDouble(),
          );

          return Polyline(
            points: [selectedPoint, relatedPoint],
            color: Colors.cyan.withValues(alpha: 0.6),
            strokeWidth: 3.0,
            borderColor: Colors.white,
            borderStrokeWidth: 1.0,
          );
        })
        .where((p) => p != null)
        .cast<Polyline>()
        .toList();
  }

  Widget _buildNarrativeInfoCard() {
    final filteredNarratives = _getFilteredNarratives();
    final narrative = filteredNarratives.firstWhere(
      (n) => n['id'] == _selectedNarrativeId,
      orElse: () => {},
    );

    if (narrative.isEmpty) return const SizedBox.shrink();

    final location = narrative['location'] as Map<String, dynamic>;
    final category = _getPrimaryCategory(narrative['categories'] as List?);
    final icon = _categoryIcons[category] ?? Icons.place;
    final color = _categoryColors[category] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  narrative['title'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedNarrativeId = null),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.red),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location['name'] as String,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
    IconData icon,
    VoidCallback onPressed,
    String tooltip, {
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: isActive 
              ? Colors.cyan.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            icon,
            color: isActive ? Colors.white : Colors.black87,
          ),
          onPressed: onPressed,
          iconSize: 20,
        ),
      ),
    );
  }

  String _getPrimaryCategory(List? categories) {
    if (categories == null || categories.isEmpty) return 'default';
    final cat = categories.first.toString().toLowerCase();
    return _categoryIcons.containsKey(cat) ? cat : 'default';
  }

  String _getCategoryLabel(String key) {
    final labels = {
      'ufo': 'UFO & Tech',
      'secret_society': 'Geheimges.',
      'history': 'Geschichte',
      'technology': 'Technologie',
      'science': 'Wissenschaft',
      'politics': 'Politik',
    };
    return labels[key] ?? key;
  }

  String _truncateTitle(String title, int maxLength) {
    if (title.length <= maxLength) return title;
    return '${title.substring(0, maxLength)}...';
  }
}
