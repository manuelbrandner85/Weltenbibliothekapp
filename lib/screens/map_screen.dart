import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/event_model.dart';
import '../data/mystical_events_data.dart';
import 'modern_event_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  String? _selectedCategory;
  String _searchQuery = '';
  late AnimationController _pulseController;
  late AnimationController _schumannController;

  bool _showFilters = false;
  bool _showListView = false;
  bool _clusteringEnabled = true;
  bool _showRoutes = false;
  bool _showSearch = false;
  String _mapStyle = 'dark';
  bool _uiVisible = true; // NEW: Auto-hide UI
  bool _showQuickZoom = false; // NEW: Toggle quick zoom
  bool _compactMode = true; // NEW: Compact UI mode

  // Timeline filter
  int _startYear = -3000;
  int _endYear = 2025;

  final Map<String, String> _mapStyles = {
    'dark': 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
    'satellite':
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    'terrain': 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
  };

  // Quick Zoom Locations
  final Map<String, Map<String, dynamic>> _quickZoomLocations = {
    'Europa': {'coords': const LatLng(50.0, 10.0), 'zoom': 4.0},
    'Asien': {'coords': const LatLng(35.0, 100.0), 'zoom': 3.5},
    'Amerika': {'coords': const LatLng(40.0, -100.0), 'zoom': 3.0},
    'Afrika': {'coords': const LatLng(0.0, 20.0), 'zoom': 3.5},
    'Welt': {'coords': const LatLng(20.0, 0.0), 'zoom': 2.5},
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _schumannController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Auto-hide UI after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _compactMode) {
        setState(() => _uiVisible = false);
      }
    });
  }

  void _toggleUIVisibility() {
    setState(() => _uiVisible = !_uiVisible);
  }

  void _resetAutoHideTimer() {
    setState(() => _uiVisible = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _compactMode) {
        setState(() => _uiVisible = false);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _schumannController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<EventModel> _getFilteredEvents() {
    final allEvents = MysticalEventsData.getAllEvents();

    return allEvents.where((event) {
      // Category filter
      if (_selectedCategory != null && event.category != _selectedCategory) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!event.title.toLowerCase().contains(query) &&
            !event.description.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Timeline filter
      final eventYear = event.date.year;
      if (eventYear < _startYear || eventYear > _endYear) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> _goToMyLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📍 Standortdienste sind deaktiviert'),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📍 Standort-Berechtigung verweigert'),
              ),
            );
          }
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      _mapController.move(LatLng(position.latitude, position.longitude), 10.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📍 Zu meinem Standort gezoomt')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Fehler: $e')));
      }
    }
  }

  void _showEventPreview(EventModel event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF1E293B), const Color(0xFF0F172A)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: _getCategoryColor(event.category).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Event Preview Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getCategoryColor(event.category),
                          _getCategoryColor(
                            event.category,
                          ).withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getCategoryEmoji(event.category),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getCategoryName(event.category),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Date & Location
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Color(0xFFFBBF24),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${event.date.year}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Color(0xFFFBBF24),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${event.location.latitude.toStringAsFixed(2)}, ${event.location.longitude.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description Preview
                  Text(
                    event.description.length > 150
                        ? '${event.description.substring(0, 150)}...'
                        : event.description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showEventDetail(event);
                          },
                          icon: const Icon(Icons.visibility),
                          label: const Text('Details ansehen'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _mapController.move(event.location, 12.0);
                        },
                        icon: const Icon(Icons.my_location),
                        label: const Text('Zoom'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF334155),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents = _getFilteredEvents();

    return Scaffold(
      body: Stack(
        children: [
          // Map or List View
          if (!_showListView) ...[
            // Map View
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(20.0, 0.0),
                initialZoom: 2.5,
                minZoom: 1.5,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: _mapStyles[_mapStyle]!,
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.weltenbibliothek',
                ),

                if (_showRoutes) ..._buildRouteLines(),

                if (_clusteringEnabled)
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 120,
                      size: const Size(50, 50),
                      markers: _buildGlowingMarkers(filteredEvents),
                      onClusterTap: (cluster) {
                        // Zoom in when cluster is tapped
                        final bounds = LatLngBounds.fromPoints(
                          cluster.markers.map((m) => m.point).toList(),
                        );
                        _mapController.fitCamera(
                          CameraFit.bounds(
                            bounds: bounds,
                            padding: const EdgeInsets.all(50),
                          ),
                        );
                      },
                      builder: (context, markers) {
                        return GestureDetector(
                          onTap: () {
                            final bounds = LatLngBounds.fromPoints(
                              markers.map((m) => m.point).toList(),
                            );
                            _mapController.fitCamera(
                              CameraFit.bounds(
                                bounds: bounds,
                                padding: const EdgeInsets.all(50),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                              ),
                              border: Border.all(
                                color: const Color(
                                  0xFFFBBF24,
                                ).withValues(alpha: 0.5),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF8B5CF6,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                markers.length.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  MarkerLayer(markers: _buildGlowingMarkers(filteredEvents)),
              ],
            ),
          ] else ...[
            // List View
            _buildEventListView(filteredEvents),
          ],

          // Compact Header (Only shows when UI is visible or in list view)
          if (_uiVisible || _showListView)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: AnimatedOpacity(
                  opacity: _uiVisible ? 1.0 : 0.3,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            // Compact Title
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF8B5CF6),
                                    Color(0xFF6D28D9),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.map,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${filteredEvents.length} Orte',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            // Compact Control Buttons
                            IconButton(
                              icon: Icon(
                                _showSearch ? Icons.search_off : Icons.search,
                                color: _showSearch
                                    ? const Color(0xFFFBBF24)
                                    : Colors.white,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showSearch = !_showSearch;
                                  if (!_showSearch) {
                                    _searchQuery = '';
                                    _searchController.clear();
                                  }
                                });
                                _resetAutoHideTimer();
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                _mapStyle == 'dark'
                                    ? Icons.satellite_alt
                                    : Icons.dark_mode,
                                color: Colors.white,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              onPressed: () {
                                setState(() {
                                  _mapStyle = _mapStyle == 'dark'
                                      ? 'satellite'
                                      : 'dark';
                                });
                                _resetAutoHideTimer();
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                _showListView ? Icons.map : Icons.list,
                                color: _showListView
                                    ? const Color(0xFFFBBF24)
                                    : Colors.white,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              onPressed: () {
                                setState(() => _showListView = !_showListView);
                                _resetAutoHideTimer();
                              },
                            ),
                          ],
                        ),

                        // Compact Search Bar
                        if (_showSearch) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _searchController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Suchen...',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Color(0xFFFBBF24),
                                size: 18,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                          _searchController.clear();
                                        });
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: const Color(
                                0xFF0F172A,
                              ).withValues(alpha: 0.8),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              isDense: true,
                            ),
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                              _resetAutoHideTimer();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Floating Quick Zoom Toggle (Top-Left)
          if (!_showListView && _uiVisible)
            Positioned(
              top: _showSearch ? 110 : 70,
              left: 12,
              child: AnimatedOpacity(
                opacity: _uiVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _showQuickZoom ? Icons.close : Icons.explore,
                      color: _showQuickZoom
                          ? const Color(0xFFFBBF24)
                          : Colors.white,
                      size: 20,
                    ),
                    tooltip: 'Quick Zoom',
                    onPressed: () {
                      setState(() => _showQuickZoom = !_showQuickZoom);
                      _resetAutoHideTimer();
                    },
                  ),
                ),
              ),
            ),

          // Quick Zoom Buttons (Dropdown)
          if (!_showListView && _showQuickZoom && _uiVisible)
            Positioned(
              top: _showSearch ? 110 : 70,
              left: 60,
              child: AnimatedOpacity(
                opacity: _uiVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _quickZoomLocations.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _buildCompactQuickZoomButton(
                          entry.key,
                          entry.value['coords'] as LatLng,
                          entry.value['zoom'] as double,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

          // Timeline Slider (Only when filters visible) - TOP POSITION
          if (!_showListView && _showFilters && _uiVisible)
            Positioned(
              bottom: 250,
              left: 12,
              right: 12,
              child: AnimatedOpacity(
                opacity: _uiVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _buildCompactTimelineSlider(),
              ),
            ),

          // Category Filters (Compact, Bottom) - MIDDLE POSITION
          if (!_showListView && _uiVisible)
            Positioned(
              bottom: 180,
              left: 12,
              right: 200,
              child: AnimatedOpacity(
                opacity: _uiVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _buildCompactCategoryFilters(filteredEvents),
              ),
            ),

          // Compact Schumann Widget (Bottom-Left, Auto-Hide)
          if (_uiVisible)
            Positioned(
              bottom: 120,
              left: 12,
              child: AnimatedOpacity(
                opacity: _uiVisible ? 0.8 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _buildCompactSchumannWidget(),
              ),
            ),

          // ✅ VERBESSERTE Navigation-Buttons (Benutzerfreundlicher)
          if (!_showListView)
            Positioned(
              bottom: 100,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 📍 Mein Standort (Größer, immer sichtbar)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: FloatingActionButton(
                      heroTag: 'my_location',
                      onPressed: _goToMyLocation,
                      backgroundColor: const Color(0xFF10B981),
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 🔍 Suche (Größer, klare Beschriftung)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: FloatingActionButton(
                      heroTag: 'search_toggle',
                      onPressed: () {
                        setState(() => _showSearch = !_showSearch);
                      },
                      backgroundColor: _showSearch
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF334155),
                      child: Icon(
                        _showSearch ? Icons.close : Icons.search,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 🎛️ Filter (Größer, klare Farbe)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: FloatingActionButton(
                      heroTag: 'filter_toggle',
                      onPressed: () {
                        setState(() => _showFilters = !_showFilters);
                      },
                      backgroundColor: _showFilters
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFF334155),
                      child: Icon(
                        Icons.tune,
                        color: _showFilters ? Colors.black : Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 📋 Listen-Ansicht (NEU - Toggle)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: FloatingActionButton(
                      heroTag: 'list_toggle',
                      onPressed: () {
                        setState(() => _showListView = !_showListView);
                      },
                      backgroundColor: const Color(0xFF3B82F6),
                      child: const Icon(
                        Icons.list,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickZoomButton(String label, LatLng coords, double zoom) {
    return ElevatedButton(
      onPressed: () {
        _mapController.move(coords, zoom);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🌍 Zu $label gezoomt'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E293B).withValues(alpha: 0.95),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.explore, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTimelineSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '⏱️ Timeline Filter',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                '$_startYear - $_endYear',
                style: const TextStyle(
                  color: Color(0xFFFBBF24),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: RangeValues(_startYear.toDouble(), _endYear.toDouble()),
            min: -3000,
            max: 2025,
            divisions: 100,
            activeColor: const Color(0xFF8B5CF6),
            inactiveColor: const Color(0xFF334155),
            labels: RangeLabels(_startYear.toString(), _endYear.toString()),
            onChanged: (RangeValues values) {
              setState(() {
                _startYear = values.start.round();
                _endYear = values.end.round();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventListView(List<EventModel> events) {
    return Container(
      color: const Color(0xFF0F172A),
      child: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 180, bottom: 100),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: _getCategoryColor(
                      event.category,
                    ).withValues(alpha: 0.3),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          _getCategoryColor(event.category),
                          _getCategoryColor(
                            event.category,
                          ).withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getCategoryEmoji(event.category),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  title: Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    '${event.date.year} • ${_getCategoryName(event.category)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                  onTap: () {
                    setState(() => _showListView = false);
                    _mapController.move(event.location, 10.0);
                    Future.delayed(const Duration(milliseconds: 500), () {
                      _showEventPreview(event);
                    });
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<PolylineLayer> _buildRouteLines() {
    final filteredEvents = _getFilteredEvents();
    final List<Polyline> polylines = [];

    // Sort by date for chronological routes
    final sortedEvents = List<EventModel>.from(filteredEvents)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (int i = 0; i < sortedEvents.length - 1; i++) {
      polylines.add(
        Polyline(
          points: [sortedEvents[i].location, sortedEvents[i + 1].location],
          strokeWidth: 2,
          color: _getCategoryColor(
            sortedEvents[i].category,
          ).withValues(alpha: 0.4),
          gradientColors: [
            _getCategoryColor(sortedEvents[i].category).withValues(alpha: 0.6),
            _getCategoryColor(
              sortedEvents[i + 1].category,
            ).withValues(alpha: 0.4),
          ],
        ),
      );
    }

    return [PolylineLayer(polylines: polylines)];
  }

  List<Marker> _buildGlowingMarkers(List<EventModel> events) {
    return events.map((event) {
      return Marker(
        point: event.location,
        width: 60,
        height: 60,
        child: GestureDetector(
          onTap: () => _showEventPreview(event),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_pulseController.value * 0.3);
              final opacity = 0.3 + (_pulseController.value * 0.4);

              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 40 * scale,
                    height: 40 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getCategoryColor(
                        event.category,
                      ).withValues(alpha: opacity * 0.3),
                      boxShadow: [
                        BoxShadow(
                          color: _getCategoryColor(
                            event.category,
                          ).withValues(alpha: opacity),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getCategoryColor(event.category),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        _getCategoryEmoji(event.category),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }).toList();
  }

  Widget _buildCategoryFilters(List<EventModel> allEvents) {
    final archaeologyCount = allEvents
        .where((e) => e.category == 'archaeology')
        .length;
    final mysteryCount = allEvents.where((e) => e.category == 'mystery').length;
    final historicalCount = allEvents
        .where((e) => e.category == 'historical')
        .length;
    final energyCount = allEvents.where((e) => e.category == 'energy').length;
    final phenomenonCount = allEvents
        .where((e) => e.category == 'phenomenon')
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showFilters = !_showFilters),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.filter_list,
                      color: Color(0xFFFBBF24),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedCategory == null
                          ? 'Filter: Alle (${allEvents.length})'
                          : 'Filter: ${_getCategoryName(_selectedCategory!)} (${allEvents.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Icon(
                  _showFilters ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white,
                ),
              ],
            ),
          ),

          if (_showFilters) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF8B5CF6), height: 1),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    'Alle',
                    MysticalEventsData.getAllEvents().length,
                    null,
                  ),
                  _buildFilterChip(
                    '🏛️ Archäo',
                    archaeologyCount,
                    'archaeology',
                  ),
                  _buildFilterChip('❓ Mystery', mysteryCount, 'mystery'),
                  _buildFilterChip('📜 Histor.', historicalCount, 'historical'),
                  _buildFilterChip('⚡ Energie', energyCount, 'energy'),
                  _buildFilterChip('🌀 Phäno', phenomenonCount, 'phenomenon'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, String? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedCategory = category);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF8B5CF6)
                : const Color(0xFF2D2D44),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFFFBBF24) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[300],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.3)
                      : const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFFFBBF24),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchumannWidget() {
    return AnimatedBuilder(
      animation: _schumannController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00FF00).withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00FF00).withValues(alpha: 0.3),
                blurRadius: 15,
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.waves, color: Color(0xFF00FF00), size: 16),
              const SizedBox(width: 8),
              const Text(
                'Schumann:',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '8.05 Hz',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00FF00),
                ),
              ),
              const Spacer(),
              Text(
                'Q: 4.3',
                style: TextStyle(color: Colors.yellow[700], fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'archaeology':
        return const Color(0xFFF59E0B);
      case 'mystery':
        return const Color(0xFF8B5CF6);
      case 'historical':
        return const Color(0xFF3B82F6);
      case 'energy':
        return const Color(0xFF10B981);
      case 'phenomenon':
        return const Color(0xFF06B6D4);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  String _getCategoryEmoji(String category) {
    final cat = EventCategory.values.firstWhere(
      (c) => c.name == category,
      orElse: () => EventCategory.mystery,
    );
    return cat.emoji;
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'archaeology':
        return 'Archäologie';
      case 'mystery':
        return 'Mysterien';
      case 'historical':
        return 'Historisch';
      case 'energy':
        return 'Energie';
      case 'phenomenon':
        return 'Phänomene';
      default:
        return category;
    }
  }

  void _showEventDetail(EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModernEventDetailScreen(event: event),
      ),
    );
  }

  // NEW: Compact Quick Zoom Button
  Widget _buildCompactQuickZoomButton(
    String label,
    LatLng coords,
    double zoom,
  ) {
    return ElevatedButton(
      onPressed: () {
        _mapController.move(coords, zoom);
        setState(() => _showQuickZoom = false);
        _resetAutoHideTimer();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.9),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  // NEW: Compact Category Filters
  Widget _buildCompactCategoryFilters(List<EventModel> filteredEvents) {
    final categories = <String, int>{};
    for (var event in MysticalEventsData.getAllEvents()) {
      categories[event.category] = (categories[event.category] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildCompactCategoryChip('Alle', null, filteredEvents.length),
            const SizedBox(width: 6),
            ...categories.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _buildCompactCategoryChip(
                  _getCategoryEmoji(entry.key),
                  entry.key,
                  entry.value,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCategoryChip(String label, String? category, int count) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = category);
        _resetAutoHideTimer();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? _getCategoryColor(category ?? 'mystery').withValues(alpha: 0.3)
              : const Color(0xFF0F172A).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? _getCategoryColor(category ?? 'mystery')
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? _getCategoryColor(category ?? 'mystery')
                    : const Color(0xFF334155),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Compact Timeline Slider
  Widget _buildCompactTimelineSlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '⏱️ Timeline',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                '$_startYear - $_endYear',
                style: const TextStyle(
                  color: Color(0xFFFBBF24),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: RangeValues(_startYear.toDouble(), _endYear.toDouble()),
            min: -3000,
            max: 2025,
            divisions: 100,
            activeColor: const Color(0xFF8B5CF6),
            inactiveColor: const Color(0xFF334155),
            labels: RangeLabels(_startYear.toString(), _endYear.toString()),
            onChanged: (RangeValues values) {
              setState(() {
                _startYear = values.start.round();
                _endYear = values.end.round();
              });
              _resetAutoHideTimer();
            },
          ),
        ],
      ),
    );
  }

  // NEW: Compact Schumann Widget
  Widget _buildCompactSchumannWidget() {
    return GestureDetector(
      onTap: _resetAutoHideTimer,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF8B5CF6).withValues(alpha: 0.3),
              const Color(0xFF6D28D9).withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
          ),
        ),
        child: AnimatedBuilder(
          animation: _schumannController,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.waves,
                  color: Color.lerp(
                    const Color(0xFFFBBF24),
                    const Color(0xFF8B5CF6),
                    _schumannController.value,
                  ),
                  size: 16,
                ),
                const SizedBox(width: 6),
                const Text(
                  '7.83 Hz',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
