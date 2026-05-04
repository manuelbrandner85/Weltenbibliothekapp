import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/map_clustering_helper.dart'; // 🗺️ MARKER-CLUSTERING
import '../../models/materie_location_detail.dart'; // ✅ MODEL
import '../../models/location_category.dart'; // ✅ ENUM
import '../../data/materie_locations.dart'; // ✅ DATA
import '../../services/live_map_pins_service.dart'; // 📍 B7: Live-Pins
import '../../widgets/live_pins_layer.dart'; // 📍 B7: Live-Pins-Marker

class MaterieKarteTabPro extends StatefulWidget {
  const MaterieKarteTabPro({super.key});

  @override
  State<MaterieKarteTabPro> createState() => _MaterieKarteTabProState();
}

class _MaterieKarteTabProState extends State<MaterieKarteTabPro> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  
  // Filter State (Single-Select)
  LocationCategory? _selectedCategory; // null = "Alle" ausgewählt
  String _searchQuery = '';
  MaterieLocationDetail? _selectedLocation;
  
  // Gespeicherte Karten-Position (für Zoom-Zurück)
  LatLng? _savedMapCenter;
  double? _savedMapZoom;
  
  // Timeline Filter (Jahr-Range)
  double _selectedYear = 2024; // Aktuelles Jahr als Standard
  bool _showTimeline = false;  // Timeline-Slider ein/aus
  
  // Detail Panel Tab State
  int _detailTabIndex = 0;
  
  // 🗺️ MAP LAYER STATE
  String _currentMapLayer = 'street'; // street, satellite, terrain, topo
  bool _isLayerSwitcherExpanded = false; // Standard: Eingeklappt
  
  @override
  void initState() {
    super.initState();
    // Default: "Alle" ausgewählt (keine spezifische Kategorie)
    _selectedCategory = null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MaterieLocationDetail> get _filteredLocations {
    var locations = allMaterieLocations;
    
    // Filter nach Kategorie (Single-Select)
    if (_selectedCategory != null) {
      locations = locations.where((loc) => loc.category == _selectedCategory).toList();
    }
    
    // 📅 TIMELINE-FILTER (±50 Jahre Toleranz)
    if (_showTimeline && _selectedYear != 2024) {
      locations = locations.where((loc) {
        if (loc.date == null) return false; // Events ohne Datum ausblenden
        
        final eventYear = loc.date!.year;
        final tolerance = 50.0;
        
        return (eventYear >= _selectedYear - tolerance) && 
               (eventYear <= _selectedYear + tolerance);
      }).toList();
    }
    
    // Filter nach Such-Query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      locations = locations.where((loc) =>
        loc.name.toLowerCase().contains(query) ||
        loc.description.toLowerCase().contains(query) ||
        loc.keywords.any((k) => k.toLowerCase().contains(query))
      ).toList();
    }
    
    return locations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(50.0, 10.0), // Europa-Zentrum
              initialZoom: 4.0,
              minZoom: 2.0,
              maxZoom: 18.0,
              // 📍 B7: Long-Press auf die Karte → Live-Pin-Modal öffnen
              onLongPress: (tapPos, latlng) =>
                  _showLivePinModal(context, latlng),
            ),
            children: [
              // 🗺️ DYNAMIC TILE LAYER (based on _currentMapLayer)
              TileLayer(
                urlTemplate: _getMapLayerUrl(),
                userAgentPackageName: 'com.dualrealms.knowledge',
                maxZoom: 19,
              ),

              // 📍 B7: Live-Pins-Layer (gepulste Marker, auto-expire 5min)
              const LivePinsLayer(world: 'materie', accent: Color(0xFF2979FF)),

              // Marker Layer mit Clustering
              MapClusteringHelper.createClusterLayer(
                markers: _filteredLocations.map((location) {
                  return Marker(
                    point: location.position,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () {
                        // Aktuelle Position/Zoom speichern vor dem Zoom
                        _savedMapCenter = _mapController.camera.center;
                        _savedMapZoom = _mapController.camera.zoom;
                        
                        setState(() => _selectedLocation = location);
                        _mapController.move(location.position, 12.0);
                      },
                      child: _buildMarker(location),
                    ),
                  );
                }).toList(),
                clusterColor: const Color(0xFF2979FF),
                maxClusterRadius: MapClusteringHelper.calculateOptimalClusterRadius(
                  _filteredLocations.length,
                ),
              ),
            ],
          ),

          // EMPTY-STATE Overlay wenn aktiver Filter 0 Treffer hat
          if (_filteredLocations.isEmpty &&
              (_searchQuery.isNotEmpty || _selectedCategory != null))
            Positioned(
              top: MediaQuery.of(context).padding.top + 140,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF04080F).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF2979FF).withValues(alpha: 0.4)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off_rounded,
                        color: Color(0xFF2979FF), size: 32),
                    const SizedBox(height: 8),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'Keine Orte für "$_searchQuery" gefunden'
                          : 'Keine Orte in dieser Kategorie',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _selectedCategory = null;
                        });
                      },
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      label: const Text('Filter zurücksetzen'),
                    ),
                  ],
                ),
              ),
            ),

          // 🗺️ MAP LAYER SWITCHER (Bottom Left - Fixed Position)
          Positioned(
            bottom: 100,  // Über dem Info-Panel
            left: 16,     // Links ausgerichtet
            child: _buildMapLayerSwitcher(),
          ),
          
          // TOP BAR (wie bei Energie - mit SafeArea)
          SafeArea(
            child: Column(
              children: [
                _buildSearchAndFilterBar(),
                const SizedBox(height: 12),  // 📍 Spacing wie bei Energie
                _buildCategoryFilters(),
              ],
            ),
          ),
          
          // 📅 TIMELINE SLIDER
          if (_showTimeline)
            Positioned(
              top: 145,  // 📍 Angepasst: unter SafeArea+Column (16 margin + 12 spacing + Filter ~60px + 12 spacing)
              left: 0,
              right: 0,
              child: _buildTimelineSlider(),
            ),
          
          // Bottom Info Panel
          if (_selectedLocation != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildInfoPanel(_selectedLocation!),
            ),
        ],
      ),
    );
  }

  Widget _buildMarker(MaterieLocationDetail location) {
    final color = _getCategoryColor(location.category);
    final icon = _getCategoryIcon(location.category);
    
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2979FF).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2979FF).withValues(alpha: 0.1),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Suche nach Orten, Ereignissen...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          // TIMELINE TOGGLE BUTTON
          IconButton(
            icon: Icon(
              _showTimeline ? Icons.timeline : Icons.timeline_outlined,
              color: _showTimeline ? const Color(0xFF2979FF) : Colors.white,
              size: 24,
            ),
            onPressed: () => setState(() => _showTimeline = !_showTimeline),
            tooltip: 'Zeitleiste',
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white, size: 20),
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          const SizedBox(width: 8),
          Text(
            '${_filteredLocations.length}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: LocationCategory.values.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // "Alle" Button
            final allSelected = _selectedCategory == null;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('Alle (${allMaterieLocations.length})'),
                selected: allSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = null; // "Alle" auswählen
                  });
                },
                backgroundColor: const Color(0xFF0A1020).withValues(alpha: 0.9),
                selectedColor: Colors.white.withValues(alpha: 0.3),
                labelStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: allSelected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: allSelected 
                    ? Colors.white 
                    : Colors.white.withValues(alpha: 0.3),
                ),
              ),
            );
          }
          
          final category = LocationCategory.values[index - 1];
          final count = allMaterieLocations.where((l) => l.category == category).length;
          final isSelected = _selectedCategory == category;
          final color = _getCategoryColor(category);
          final icon = _getCategoryIcon(category);
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(icon, size: 18, color: isSelected ? Colors.white : color),
              label: Text('${_getCategoryName(category)} ($count)'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category : null; // Single-Select
                });
              },
              backgroundColor: isSelected 
                ? color.withValues(alpha: 0.8)
                : Colors.black.withValues(alpha: 0.6),
              selectedColor: color.withValues(alpha: 0.8),
              labelStyle: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected ? Colors.white : color.withValues(alpha: 0.5),
                width: isSelected ? 2.5 : 1,
              ),
              elevation: isSelected ? 4 : 0,
              pressElevation: 2,
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoPanel(MaterieLocationDetail location) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A1020).withValues(alpha: 0.99),
            const Color(0xFF04080F).withValues(alpha: 0.99),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: _getCategoryColor(location.category).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(location.category).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(location.category),
                    color: _getCategoryColor(location.category),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getCategoryName(location.category),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getCategoryColor(location.category),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _selectedLocation = null;
                      _detailTabIndex = 0;
                    });
                    
                    // Zoom zurück zur gespeicherten Position
                    if (_savedMapCenter != null && _savedMapZoom != null) {
                      _mapController.move(_savedMapCenter!, _savedMapZoom!);
                    }
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // TABS (nur wenn Multimedia vorhanden)
          if (location.imageUrls.isNotEmpty || location.videoUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildTab('Info', 0, Icons.info_outline),
                  if (location.imageUrls.isNotEmpty)
                    _buildTab('Bilder', 1, Icons.image_outlined),
                  if (location.videoUrls.isNotEmpty)
                    _buildTab('Videos', 2, Icons.play_circle_outline),
                ],
              ),
            ),
          
          if (location.imageUrls.isNotEmpty || location.videoUrls.isNotEmpty)
            const SizedBox(height: 12),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildTabContent(location),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTab(String label, int index, IconData icon) {
    final isSelected = _detailTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _detailTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTabContent(MaterieLocationDetail location) {
    switch (_detailTabIndex) {
      case 0: // INFO
        return _buildInfoTab(location);
      case 1: // BILDER
        return _buildImagesTab(location);
      case 2: // VIDEOS
        return _buildVideosTab(location);
      default:
        return _buildInfoTab(location);
    }
  }
  
  Widget _buildInfoTab(MaterieLocationDetail location) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        Text(
          location.description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.9),
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        // Detailed Info (inkl. offizielle & alternative Sichtweisen)
        if (location.detailedInfo.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            location.detailedInfo,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.6,
            ),
          ),
        ],
        
        // Keywords
        if (location.keywords.isNotEmpty) ...[
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: location.keywords.map((keyword) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  keyword,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        
        // Sources
        if (location.sources.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Quellen:',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...location.sources.map((source) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $source',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          )),
        ],
        
        const SizedBox(height: 20),
      ],
    );
  }
  
  Widget _buildImagesTab(MaterieLocationDetail location) {
    if (location.imageUrls.isEmpty) {
      return Center(
        child: Text(
          'Keine Bilder verfügbar',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        ),
      );
    }
    
    return Column(
      children: location.imageUrls.map((imageUrl) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 200,
                color: Colors.white.withValues(alpha: 0.05),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Colors.white.withValues(alpha: 0.05),
                child: Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 48,
                  ),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildVideosTab(MaterieLocationDetail location) {
    if (location.videoUrls.isEmpty) {
      return Center(
        child: Text(
          'Keine Videos verfügbar',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        ),
      );
    }
    
    return Column(
      children: location.videoUrls.map((videoId) {
        final youtubeUrl = 'https://www.youtube.com/watch?v=$videoId';
        
        return GestureDetector(
          onTap: () {
            // 📱 Show YouTube URL (Android-compatible)
            debugPrint('📱 YouTube: $youtubeUrl');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('📺 Video: $videoId'),
                action: SnackBarAction(
                  label: 'OK',
                  onPressed: () {},
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.shade400.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.shade400.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // YouTube Thumbnail (hochauflösend)
                Image.network(
                  'https://img.youtube.com/vi/$videoId/maxresdefault.jpg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback zu Standard-Thumbnail
                    return Image.network(
                      'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.white.withValues(alpha: 0.05),
                          child: const Center(
                            child: Icon(Icons.videocam_off, color: Colors.white38, size: 48),
                          ),
                        );
                      },
                    );
                  },
                ),
                
                // Play-Button Overlay (zentriert & groß)
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red.shade600.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),
                
                // Info-Bar unten
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_circle_filled, color: Colors.red.shade400, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Auf YouTube ansehen',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.open_in_new, color: Colors.white.withValues(alpha: 0.7), size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getCategoryColor(LocationCategory category) {
    switch (category) {
      case LocationCategory.geopolitics:
        return const Color(0xFF4CAF50); // Green
      case LocationCategory.alternativeMedia:
        return const Color(0xFFF44336); // Red
      case LocationCategory.research:
        return const Color(0xFF9C27B0); // Purple
      case LocationCategory.transparency:
        return const Color(0xFFFFEB3B); // Yellow
      case LocationCategory.assassinations:
        return const Color(0xFFFF5722); // Deep Orange
      case LocationCategory.wars:
        return const Color(0xFF795548); // Brown
      case LocationCategory.finance:
        return const Color(0xFF2196F3); // Blue
      case LocationCategory.secretSocieties:
        return const Color(0xFF673AB7); // Deep Purple
      case LocationCategory.ufo:
        return const Color(0xFF00BCD4); // Cyan
      case LocationCategory.deepState:
        return const Color(0xFF607D8B); // Blue Grey
      case LocationCategory.surveillance:
        return const Color(0xFFFF9800); // Orange
      case LocationCategory.biotech:
        return const Color(0xFF8BC34A); // Light Green
      
      // NEUE KATEGORIEN
      case LocationCategory.ancientCivilizations:
        return const Color(0xFF9E9D24); // Olive
      case LocationCategory.religion:
        return const Color(0xFF5D4037); // Brown
      case LocationCategory.archaeology:
        return const Color(0xFF8D6E63); // Light Brown
      case LocationCategory.technology:
        return const Color(0xFF455A64); // Blue Grey Dark
      case LocationCategory.medicine:
        return const Color(0xFF00897B); // Teal
      case LocationCategory.art:
        return const Color(0xFFE91E63); // Pink
      case LocationCategory.science:
        return const Color(0xFF1976D2); // Dark Blue
      case LocationCategory.exploration:
        return const Color(0xFF388E3C); // Dark Green
      case LocationCategory.revolution:
        return const Color(0xFFD32F2F); // Dark Red
      case LocationCategory.disasters:
        return const Color(0xFFFF6F00); // Dark Orange
      case LocationCategory.falseFlags:
        return const Color(0xFF37474F); // Dark Grey
      case LocationCategory.propaganda:
        return const Color(0xFF6A1B9A); // Purple Dark
      case LocationCategory.censorship:
        return const Color(0xFF212121); // Almost Black
      case LocationCategory.epstein:
        return const Color(0xFFD32F2F); // 🔥 Dunkelrot - Epstein
    }
  }

  IconData _getCategoryIcon(LocationCategory category) {
    switch (category) {
      case LocationCategory.geopolitics:
        return Icons.public;
      case LocationCategory.alternativeMedia:
        return Icons.newspaper;
      case LocationCategory.research:
        return Icons.science;
      case LocationCategory.transparency:
        return Icons.lock_open;
      case LocationCategory.assassinations:
        return Icons.warning;
      case LocationCategory.wars:
        return Icons.gavel;
      case LocationCategory.finance:
        return Icons.attach_money;
      case LocationCategory.secretSocieties:
        return Icons.groups;
      case LocationCategory.ufo:
        return Icons.flight;
      case LocationCategory.deepState:
        return Icons.shield;
      case LocationCategory.surveillance:
        return Icons.visibility;
      case LocationCategory.biotech:
        return Icons.biotech;
      
      // NEUE KATEGORIEN
      case LocationCategory.ancientCivilizations:
        return Icons.account_balance;
      case LocationCategory.religion:
        return Icons.church;
      case LocationCategory.archaeology:
        return Icons.museum;
      case LocationCategory.technology:
        return Icons.settings;
      case LocationCategory.medicine:
        return Icons.healing;
      case LocationCategory.art:
        return Icons.palette;
      case LocationCategory.science:
        return Icons.science_outlined;
      case LocationCategory.exploration:
        return Icons.explore;
      case LocationCategory.revolution:
        return Icons.campaign;
      case LocationCategory.disasters:
        return Icons.emergency;
      case LocationCategory.falseFlags:
        return Icons.flag;
      case LocationCategory.propaganda:
        return Icons.volume_up;
      case LocationCategory.censorship:
        return Icons.block;
      case LocationCategory.epstein:
        return Icons.warning_amber; // 🔥 Warnung - Epstein
    }
  }

  // 📅 TIMELINE SLIDER WIDGET
  Widget _buildTimelineSlider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A1020).withValues(alpha: 0.98),
            const Color(0xFF04080F).withValues(alpha: 0.98),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2979FF).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.timeline, color: Color(0xFF2979FF), size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Zeitleiste',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => setState(() => _showTimeline = false),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // JAHR-ANZEIGE
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2979FF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2979FF), width: 2),
              ),
              child: Text(
                _selectedYear >= 0 
                  ? '${_selectedYear.toInt()} n.Chr.'
                  : '${(-_selectedYear).toInt()} v.Chr.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // SLIDER
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF2979FF),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
              thumbColor: const Color(0xFF2979FF),
              overlayColor: const Color(0xFF2979FF).withValues(alpha: 0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: _selectedYear,
              min: -8000,  // 8000 v.Chr.
              max: 2024,   // 2024 n.Chr.
              divisions: 201, // 50-Jahres-Schritte
              label: _selectedYear >= 0 
                ? '${_selectedYear.toInt()} n.Chr.'
                : '${(-_selectedYear).toInt()} v.Chr.',
              onChanged: (value) {
                setState(() => _selectedYear = value);
              },
            ),
          ),
          
          // ZEIT-MARKER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('8000 v.Chr.', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
              Text('0', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
              Text('2024 n.Chr.', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // SCHNELL-FILTER
          Wrap(
            spacing: 8,
            children: [
              _buildQuickYearFilter('Antike', -3000),
              _buildQuickYearFilter('Mittelalter', 1000),
              _buildQuickYearFilter('Neuzeit', 1800),
              _buildQuickYearFilter('20. Jh.', 1950),
              _buildQuickYearFilter('Heute', 2024),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickYearFilter(String label, double year) {
    return InkWell(
      onTap: () => setState(() => _selectedYear = year),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2979FF).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF2979FF).withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
  
  String _getCategoryName(LocationCategory category) {
    switch (category) {
      // URSPRÜNGLICH
      case LocationCategory.geopolitics:
        return 'Geopolitik';
      case LocationCategory.alternativeMedia:
        return 'Alt. Medien';
      case LocationCategory.research:
        return 'Forschung';
      case LocationCategory.transparency:
        return 'Transparenz';
      case LocationCategory.assassinations:
        return 'Attentate';
      case LocationCategory.wars:
        return 'Kriege';
      case LocationCategory.finance:
        return 'Finanzen';
      case LocationCategory.secretSocieties:
        return 'Geheimges.';
      case LocationCategory.ufo:
        return 'UFO';
      case LocationCategory.deepState:
        return 'Deep State';
      case LocationCategory.surveillance:
        return 'Überwachung';
      case LocationCategory.biotech:
        return 'Biotech';
      
      // NEU
      case LocationCategory.ancientCivilizations:
        return 'Antike';
      case LocationCategory.religion:
        return 'Religion';
      case LocationCategory.archaeology:
        return 'Archäologie';
      case LocationCategory.technology:
        return 'Technologie';
      case LocationCategory.medicine:
        return 'Medizin';
      case LocationCategory.art:
        return 'Kunst';
      case LocationCategory.science:
        return 'Wissenschaft';
      case LocationCategory.exploration:
        return 'Entdeckung';
      case LocationCategory.revolution:
        return 'Revolution';
      case LocationCategory.disasters:
        return 'Katastrophe';
      case LocationCategory.falseFlags:
        return 'False Flag';
      case LocationCategory.propaganda:
        return 'Propaganda';
      case LocationCategory.censorship:
        return 'Zensur';
      case LocationCategory.epstein:
        return '🔥 Epstein'; // Gesonderte Kategorie
    }
  }

  // ───────────────────────────────────────────────────────────────────
  // 📍 BUNDLE 7: LIVE MAP PINS (Materie-USP)
  // ───────────────────────────────────────────────────────────────────
  Future<void> _showLivePinModal(BuildContext context, LatLng latlng) async {
    final controller = TextEditingController();
    final accent = const Color(0xFF2979FF);
    final messenger = ScaffoldMessenger.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    final userMeta = user?.userMetadata ?? const {};
    final authorName = (userMeta['username'] as String?) ??
        (userMeta['display_name'] as String?) ??
        user?.email?.split('@').first ??
        'Anonym';
    final avatarUrl = userMeta['avatar_url'] as String?;

    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A1020),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 4,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.location_on_rounded, color: accent, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Live-Pin senden',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${latlng.latitude.toStringAsFixed(4)}°, ${latlng.longitude.toStringAsFixed(4)}°  ·  Verschwindet nach 5 Min',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 80,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Was willst du markieren? (optional)',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: accent.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: accent.withValues(alpha: 0.25)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accent, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: accent.withValues(alpha: 0.25)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, null),
                    child: Text(
                      'Abbrechen',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pop(ctx, controller.text.trim()),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Pin senden'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;

    await LiveMapPinsService.instance.sendPin(
      world: 'materie',
      lat: latlng.latitude,
      lon: latlng.longitude,
      label: result,
      authorName: authorName,
      authorAvatarUrl: avatarUrl,
    );
    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('📍 Live-Pin gesendet — alle sehen ihn live'),
          backgroundColor: accent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // 🗺️ MAP LAYER FUNCTIONS
  String _getMapLayerUrl() {
    switch (_currentMapLayer) {
      case 'street':
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case 'satellite':
        // Esri World Imagery (Satellite)
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case 'terrain':
        // OpenTopoMap (Terrain with contour lines)
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
      case 'topo':
        // Esri World Topo Map
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}';
      default:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }
  
  Widget _buildMapLayerSwitcher() {
    const accent = Color(0xFF2979FF);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: const Color(0xFF0A1020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // TOGGLE BUTTON (immer sichtbar)
          InkWell(
            onTap: () {
              setState(() => _isLayerSwitcherExpanded = !_isLayerSwitcherExpanded);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.layers, size: 24, color: accent),
                  const SizedBox(width: 10),
                  const Text('Karte',
                      style: TextStyle(
                          fontSize: 14, color: accent,
                          fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                  const SizedBox(width: 6),
                  Icon(
                    _isLayerSwitcherExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20, color: accent,
                  ),
                ],
              ),
            ),
          ),

          // LAYER OPTIONEN (nur wenn ausgeklappt)
          if (_isLayerSwitcherExpanded) ...[
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
            _buildLayerOption('street', Icons.map, 'Straße'),
            _buildLayerOption('satellite', Icons.satellite, 'Satellit'),
            _buildLayerOption('terrain', Icons.terrain, 'Gelände'),
            _buildLayerOption('topo', Icons.layers, 'Topo'),
          ],
        ],
      ),
    );
  }

  Widget _buildLayerOption(String layerType, IconData icon, String label) {
    const accent = Color(0xFF2979FF);
    final isSelected = _currentMapLayer == layerType;

    return InkWell(
      onTap: () {
        setState(() {
          _currentMapLayer = layerType;
          _isLayerSwitcherExpanded = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.15) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22,
                color: isSelected ? accent : Colors.white.withValues(alpha: 0.5)),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? accent : Colors.white.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Enums & Models

// ✅ MODELS & DATA IMPORTED FROM SEPARATE FILES
// - lib/models/location_category.dart
// - lib/models/materie_location_detail.dart
// - lib/data/materie_locations.dart
