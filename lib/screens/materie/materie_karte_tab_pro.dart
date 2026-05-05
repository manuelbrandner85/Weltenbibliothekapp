import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/map_clustering_helper.dart'; // 🗺️ MARKER-CLUSTERING
import '../../models/materie_location_detail.dart'; // ✅ MODEL
import '../../models/location_category.dart'; // ✅ ENUM
import '../../data/materie_locations.dart'; // ✅ DATA
import '../../services/live_map_pins_service.dart'; // 📍 B7: Live-Pins
import '../../services/youtube_service.dart';
import '../../services/wikimedia_service.dart';
import '../../widgets/live_pins_layer.dart'; // 📍 B7: Live-Pins-Marker
import '../../widgets/youtube_player_inline.dart';

class MaterieKarteTabPro extends StatefulWidget {
  const MaterieKarteTabPro({super.key});

  @override
  State<MaterieKarteTabPro> createState() => _MaterieKarteTabProState();
}

class _MaterieKarteTabProState extends State<MaterieKarteTabPro>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  // Filter State (Single-Select)
  LocationCategory? _selectedCategory;
  String _searchQuery = '';
  MaterieLocationDetail? _selectedLocation;

  // Gespeicherte Karten-Position (für Zoom-Zurück)
  LatLng? _savedMapCenter;
  double? _savedMapZoom;

  // Timeline Filter (Jahr-Range)
  double _selectedYear = 2024;
  bool _showTimeline = false;

  // Detail Panel Tab State
  int _detailTabIndex = 0;

  // YouTube-State pro Marker
  List<YoutubeVideo>? _ytVideos;
  bool _ytLoading = false;
  YoutubeVideo? _ytPlaying;
  String _ytLocationName = '';

  // Wikimedia-Bilder-State pro Marker
  List<String> _wikiImages = const [];
  bool _wikiLoading = false;
  String _wikiLocationName = '';

  // 🗺️ MAP LAYER STATE
  String _currentMapLayer = 'street';

  // Feature E: Radial layer menu
  bool _layerMenuOpen = false;

  // Feature F: Collapsible header
  bool _headerCollapsed = false;

  // Feature A: Panel slide animation
  late AnimationController _panelSlideController;
  late Animation<Offset> _panelSlideAnimation;

  // Feature F: Gradient animation
  late AnimationController _gradientAnimController;
  late Animation<double> _gradientAnim;

  // Feature C: Image swiper
  PageController? _imagePageController;
  int _imagePage = 0;

  @override
  void initState() {
    super.initState();
    _selectedCategory = null;

    // Feature A: Panel slide
    _panelSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _panelSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _panelSlideController,
      curve: Curves.elasticOut,
    ));

    // Feature F: Gradient cycling
    _gradientAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _gradientAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      _gradientAnimController,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _panelSlideController.dispose();
    _gradientAnimController.dispose();
    _imagePageController?.dispose();
    super.dispose();
  }

  void _openPanel() {
    _imagePageController?.dispose();
    _imagePageController = PageController();
    _imagePage = 0;
    _panelSlideController.forward(from: 0);
  }

  Future<void> _loadYoutubeForLocation(String name) async {
    if (_ytLocationName == name) return;
    if (!mounted) return;
    setState(() {
      _ytLoading = true;
      _ytLocationName = name;
    });
    final videos = await YoutubeService.instance
        .searchVideos('$name deutsch', max: 5);
    if (!mounted) return;
    setState(() {
      _ytVideos = videos;
      _ytLoading = false;
    });
  }

  Future<void> _loadWikimediaForLocation(String name) async {
    if (_wikiLocationName == name) return;
    if (!mounted) return;
    setState(() {
      _wikiLoading = true;
      _wikiLocationName = name;
    });
    final images = await WikimediaService.instance.searchImages(name);
    if (!mounted) return;
    setState(() {
      _wikiImages = images;
      _wikiLoading = false;
    });
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
          // Feature E: close radial menu on background tap
          if (_layerMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _layerMenuOpen = false),
                child: Container(color: Colors.transparent),
              ),
            ),

          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(50.0, 10.0), // Europa-Zentrum
              initialZoom: 4.0,
              minZoom: 2.0,
              maxZoom: 18.0,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture && !_headerCollapsed) {
                  setState(() => _headerCollapsed = true);
                }
              },
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

              // Marker Layer mit Clustering — Feature B: _PulsingMarkerMaterie
              MapClusteringHelper.createClusterLayer(
                markers: _filteredLocations.map((location) {
                  final isSelected = _selectedLocation?.name == location.name;
                  return Marker(
                    point: location.position,
                    width: 52,
                    height: 52,
                    child: GestureDetector(
                      onTap: () {
                        _savedMapCenter = _mapController.camera.center;
                        _savedMapZoom = _mapController.camera.zoom;
                        setState(() {
                          _selectedLocation = location;
                          _detailTabIndex = 0;
                          _ytVideos = null;
                          _ytPlaying = null;
                          _ytLocationName = '';
                          _wikiImages = const [];
                          _wikiLocationName = '';
                          _headerCollapsed = true;
                        });
                        _openPanel();
                        _mapController.move(location.position, 12.0);
                        _loadYoutubeForLocation(location.name);
                        _loadWikimediaForLocation(location.name);
                      },
                      child: _PulsingMarkerMaterie(
                        categoryColor: _getCategoryColor(location.category),
                        icon: _getCategoryIcon(location.category),
                        isSelected: isSelected,
                      ),
                    ),
                  );
                }).toList(),
                clusterColor: const Color(0xFFE53935),
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

          // 🗺️ MAP LAYER SWITCHER — Feature E: Radial Menu
          Positioned(
            bottom: 100,
            left: 16,
            child: _buildRadialLayerMenu(),
          ),

          // Feature F: Animated gradient sky header (collapsible)
          SafeArea(
            child: AnimatedBuilder(
              animation: _gradientAnim,
              builder: (context, child) {
                final alpha = (0.06 * math.sin(_gradientAnim.value * math.pi));
                return Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: _headerCollapsed ? 0 : 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFFE53935).withValues(alpha: alpha.clamp(0.0, 0.06)),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                      height: _headerCollapsed ? 0 : double.infinity,
                      clipBehavior: Clip.hardEdge,
                      decoration: const BoxDecoration(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSearchAndFilterBar(),
                          const SizedBox(height: 12),
                          _buildCategoryFilters(),
                        ],
                      ),
                    ),
                    if (_headerCollapsed)
                      Positioned(
                        top: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: () => setState(() => _headerCollapsed = false),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  height: 32,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: const Color(0xFFE53935).withValues(alpha: 0.4)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.search, color: Colors.white70, size: 16),
                                      SizedBox(width: 6),
                                      Text('Suchen…',
                                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                                      SizedBox(width: 6),
                                      Icon(Icons.expand_more, color: Colors.white70, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
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
    return SlideTransition(
      position: _panelSlideAnimation,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: _getCategoryColor(location.category).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _getCategoryColor(location.category).withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
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
          
          // Header — Feature A: pulsing icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _PulsingIconContainerMaterie(
                  color: _getCategoryColor(location.category),
                  icon: _getCategoryIcon(location.category),
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
                    if (_savedMapCenter != null && _savedMapZoom != null) {
                      _mapController.move(_savedMapCenter!, _savedMapZoom!);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // TABS — immer alle 3 sichtbar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildTab('Info', 0, Icons.info_outline),
                _buildTab('Bilder', 1, Icons.image_outlined),
                _buildTab('Videos', 2, Icons.play_circle_outline),
              ],
            ),
          ),
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
      ), // Container
        ), // BackdropFilter
      ), // ClipRRect
    ); // SlideTransition
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
    final allImages = [...location.imageUrls, ..._wikiImages];

    if (_wikiLoading && allImages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
            SizedBox(height: 12),
            Text('Suche Bilder…', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      );
    }

    if (allImages.isEmpty) {
      return Center(
        child: Text(
          'Keine Bilder gefunden',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        ),
      );
    }

    // Feature C: Cinematic image swiper
    final maxDots = allImages.length.clamp(0, 6);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 220,
          child: Stack(
            children: [
              PageView.builder(
                controller: _imagePageController,
                itemCount: allImages.length,
                onPageChanged: (page) => setState(() => _imagePage = page),
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _imagePageController!,
                    builder: (context, child) {
                      double pageOffset = 0;
                      if (_imagePageController!.hasClients &&
                          _imagePageController!.page != null) {
                        pageOffset = _imagePageController!.page!;
                      } else {
                        pageOffset = _imagePage.toDouble();
                      }
                      final offset = (index - pageOffset) * 30.0;
                      return GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder: (_, __, ___) => _FullscreenImageViewerMaterie(
                              images: allImages,
                              initialIndex: index,
                              locationName: location.name,
                            ),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ClipRect(
                            child: Hero(
                              tag: 'mat_image_${index}_${location.name}',
                              child: Transform.translate(
                                offset: Offset(offset, 0),
                                child: Image.network(
                                  allImages[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 220,
                                  loadingBuilder: (ctx, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                            color: Colors.red, strokeWidth: 2)),
                                    );
                                  },
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    child: Icon(Icons.broken_image,
                                        color: Colors.white.withValues(alpha: 0.3),
                                        size: 48),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              Positioned(
                top: 8,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_imagePage + 1} / ${allImages.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(maxDots, (i) {
            final isCurrent = i == _imagePage.clamp(0, maxDots - 1);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isCurrent ? 10 : 7,
              height: isCurrent ? 10 : 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent ? const Color(0xFFE53935) : Colors.transparent,
                border: Border.all(
                  color: const Color(0xFFE53935).withValues(alpha: 0.7),
                  width: 1.5,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
  
  Widget _buildVideosTab(MaterieLocationDetail location) {
    // Inline-Player wenn ein Video läuft
    if (_ytPlaying != null) {
      return SingleChildScrollView(
        child: Column(
          children: [
            YoutubePlayerInline(
              video: _ytPlaying!,
              onClose: () => setState(() => _ytPlaying = null),
            ),
            const SizedBox(height: 12),
            ..._buildVideoList(),
          ],
        ),
      );
    }

    if (_ytLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
            SizedBox(height: 12),
            Text('Suche Videos…',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      );
    }

    if (_ytVideos == null || _ytVideos!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white24, size: 40),
            const SizedBox(height: 8),
            Text(
              'Keine Videos gefunden',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'YouTube API Key nötig (YOUTUBE_API_KEY)',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 10),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(children: _buildVideoList()),
    );
  }

  List<Widget> _buildVideoList() {
    final videos = _ytVideos ?? [];
    return videos.map((video) {
      final isPlaying = _ytPlaying?.videoId == video.videoId;
      return GestureDetector(
        onTap: () => setState(() => _ytPlaying = isPlaying ? null : video),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPlaying
                  ? Colors.red
                  : Colors.red.withValues(alpha: 0.3),
              width: isPlaying ? 2 : 1,
            ),
            color: Colors.black.withValues(alpha: 0.3),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              // Thumbnail
              Stack(
                children: [
                  Image.network(
                    video.thumbnail.isNotEmpty
                        ? video.thumbnail
                        : video.fallbackThumbnail,
                    width: 110,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 110,
                      height: 70,
                      color: Colors.white.withValues(alpha: 0.05),
                      child: const Icon(Icons.videocam_off,
                          color: Colors.white24, size: 28),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Icon(
                        isPlaying ? Icons.stop_circle : Icons.play_circle_fill,
                        color: Colors.red,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              color: Colors.white38, size: 11),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              video.channel,
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (video.isSubtitled)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blue.withValues(alpha: 0.4), width: 0.8),
                              ),
                              child: const Text('🇩🇪 UT',
                                  style: TextStyle(color: Colors.lightBlueAccent, fontSize: 8, fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
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
  
  // Feature E: Radial circular layer menu
  Widget _buildRadialLayerMenu() {
    const accent = Color(0xFFE53935);
    const layers = [
      ('street', Icons.map_rounded, 'Straße'),
      ('satellite', Icons.satellite_rounded, 'Satellit'),
      ('terrain', Icons.terrain_rounded, 'Gelände'),
      ('topo', Icons.layers_rounded, 'Topo'),
    ];

    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ...List.generate(layers.length, (i) {
            final (layerType, icon, label) = layers[i];
            final angle = math.pi + (i * (math.pi / 2) / (layers.length - 1));
            const radius = 68.0;
            final dx = math.cos(angle) * radius;
            final dy = math.sin(angle) * radius;
            final isSelected = _currentMapLayer == layerType;

            return AnimatedPositioned(
              duration: Duration(milliseconds: 150 + i * 80),
              curve: Curves.easeOutBack,
              bottom: _layerMenuOpen ? (56 - dy) : 0,
              left: _layerMenuOpen ? (0 + dx + 56) : 56,
              child: AnimatedOpacity(
                opacity: _layerMenuOpen ? 1.0 : 0.0,
                duration: Duration(milliseconds: 150 + i * 60),
                child: Tooltip(
                  message: label,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _currentMapLayer = layerType;
                      _layerMenuOpen = false;
                    }),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? accent : const Color(0xFF0A1020),
                        border: Border.all(
                          color: isSelected ? accent : accent.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(icon,
                          size: 20,
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.7)),
                    ),
                  ),
                ),
              ),
            );
          }),

          // Toggle FAB
          Positioned(
            bottom: 0,
            left: 0,
            child: GestureDetector(
              onTap: () => setState(() => _layerMenuOpen = !_layerMenuOpen),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _layerMenuOpen ? accent : const Color(0xFF0A1020),
                  border: Border.all(color: accent.withValues(alpha: 0.6), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _layerMenuOpen
                          ? accent.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: AnimatedRotation(
                  turns: _layerMenuOpen ? 0.125 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    Icons.layers_rounded,
                    size: 24,
                    color: _layerMenuOpen ? Colors.white : accent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Feature B: Animated pulsing marker (Materie)
// ─────────────────────────────────────────────────────────────────────────────
class _PulsingMarkerMaterie extends StatefulWidget {
  final Color categoryColor;
  final IconData icon;
  final bool isSelected;

  const _PulsingMarkerMaterie({
    required this.categoryColor,
    required this.icon,
    required this.isSelected,
  });

  @override
  State<_PulsingMarkerMaterie> createState() => _PulsingMarkerMaterieState();
}

class _PulsingMarkerMaterieState extends State<_PulsingMarkerMaterie>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.0, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final glowAlpha = 0.2 + 0.25 * _anim.value;
        final blurR = 10.0 + 8.0 * _anim.value;
        final scale = widget.isSelected ? 1.35 : 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.categoryColor,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: widget.categoryColor.withValues(alpha: glowAlpha),
                  blurRadius: blurR,
                  spreadRadius: widget.isSelected ? 4 : 2,
                ),
              ],
            ),
            child: Icon(widget.icon, color: Colors.white, size: 20),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature A: Pulsing icon in panel header (Materie)
// ─────────────────────────────────────────────────────────────────────────────
class _PulsingIconContainerMaterie extends StatefulWidget {
  final Color color;
  final IconData icon;
  const _PulsingIconContainerMaterie({required this.color, required this.icon});

  @override
  State<_PulsingIconContainerMaterie> createState() =>
      _PulsingIconContainerMaterieState();
}

class _PulsingIconContainerMaterieState
    extends State<_PulsingIconContainerMaterie>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.color.withValues(alpha: 0.5)),
        ),
        child: Icon(widget.icon, color: widget.color, size: 24),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature D: Fullscreen image viewer with Hero + swipe-down-to-close (Materie)
// ─────────────────────────────────────────────────────────────────────────────
class _FullscreenImageViewerMaterie extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String locationName;

  const _FullscreenImageViewerMaterie({
    required this.images,
    required this.initialIndex,
    required this.locationName,
  });

  @override
  State<_FullscreenImageViewerMaterie> createState() =>
      _FullscreenImageViewerMaterieState();
}

class _FullscreenImageViewerMaterieState
    extends State<_FullscreenImageViewerMaterie>
    with SingleTickerProviderStateMixin {
  late PageController _pageCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(initialPage: widget.initialIndex);
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeCtrl);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _close() {
    _fadeCtrl.reverse().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnim,
      builder: (context, child) {
        return Opacity(opacity: _fadeAnim.value, child: child);
      },
      child: GestureDetector(
        onVerticalDragUpdate: (d) {
          setState(() => _dragOffset += d.delta.dy);
        },
        onVerticalDragEnd: (d) {
          if (_dragOffset.abs() > 100 ||
              d.velocity.pixelsPerSecond.dy.abs() > 300) {
            _close();
          } else {
            setState(() => _dragOffset = 0);
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Transform.translate(
                offset: Offset(0, _dragOffset),
                child: PageView.builder(
                  controller: _pageCtrl,
                  itemCount: widget.images.length,
                  itemBuilder: (context, index) {
                    return InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Hero(
                        tag: 'mat_image_${index}_${widget.locationName}',
                        child: Image.network(
                          widget.images[index],
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              color: Colors.white30,
                              size: 80),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 16,
                child: GestureDetector(
                  onTap: _close,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
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
