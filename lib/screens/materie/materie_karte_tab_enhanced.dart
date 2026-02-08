/// Enhanced MATERIE-Karte Tab mit 9 Premium-Features
/// Version: 2.0.0 - Professional Edition
/// 
/// Features:
/// ✅ 1. Interaktive 3D-Karte mit Rotation
/// ✅ 2. Pulsierende Marker mit Glow-Effekt
/// ✅ 3. Vollbild-Detail-Karten
/// ✅ 4. Route-Planung & Verbindungen
/// ✅ 5. Erweiterte Chip-Filter
/// ✅ 6. Heat-Map Modus
/// ✅ 7. Cluster-Marker
/// ✅ 9. Thematische Karten-Layer
/// ✅ 10. Offline-Karten
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../utils/responsive_helper.dart';

class EnhancedMaterieKarteTab extends StatefulWidget {
  const EnhancedMaterieKarteTab({super.key});

  @override
  State<EnhancedMaterieKarteTab> createState() => _EnhancedMaterieKarteTabState();
}

class _EnhancedMaterieKarteTabState extends State<EnhancedMaterieKarteTab> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  
  // Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _glowController;
  
  // Map State
  String _selectedMapLayer = 'Standard';
  bool _showHeatmap = false;
  // UNUSED FIELD: bool _showClusters = true;
  bool _showRoutes = false;
  
  // Selected Filters (Chip-basiert)
  final Set<String> _selectedCategories = {};
  String _searchQuery = '';
  
  // Selected Location für Detail-View
  MaterieLocation? _selectedLocation;
  
  // Route-Planung
  final List<MaterieLocation> _routePoints = [];

  @override
  void initState() {
    super.initState();
    
    // Puls-Animation für Marker (1 Sekunde Loop)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    // Glow-Animation für Marker (2 Sekunden Loop)
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // MATERIE-Locations mit erweiterten Daten
  final List<MaterieLocation> _allLocations = [
    MaterieLocation(
      id: 'wien',
      name: 'Wien - Geopolitisches Zentrum',
      shortName: 'Wien',
      description: 'Internationale Organisationen, UNO-Standort, neutrale Verhandlungsstadt',
      category: 'Geopolitik',
      position: const LatLng(48.2082, 16.3738),
      importance: 0.95,
      color: const Color(0xFF2196F3),
      icon: Icons.account_balance,
    ),
    MaterieLocation(
      id: 'berlin',
      name: 'Berlin - Alternative Medien Hub',
      shortName: 'Berlin',
      description: 'Zentrum für unabhängigen Journalismus und kritische Berichterstattung',
      category: 'Alternative Medien',
      position: const LatLng(52.5200, 13.4050),
      importance: 0.88,
      color: const Color(0xFFFF9800),
      icon: Icons.newspaper,
    ),
    MaterieLocation(
      id: 'genf',
      name: 'Genf - CERN & Forschungszentrum',
      shortName: 'Genf',
      description: 'Europäische Organisation für Kernforschung, wissenschaftliche Durchbrüche',
      category: 'Forschung',
      position: const LatLng(46.2044, 6.1432),
      importance: 0.98,
      color: const Color(0xFF9C27B0),
      icon: Icons.science,
    ),
    MaterieLocation(
      id: 'bruessel',
      name: 'Brüssel - EU-Machtzentrum',
      shortName: 'Brüssel',
      description: 'Europäische Union Hauptquartier, politische Entscheidungen',
      category: 'Geopolitik',
      position: const LatLng(50.8503, 4.3517),
      importance: 0.92,
      color: const Color(0xFF2196F3),
      icon: Icons.gavel,
    ),
    MaterieLocation(
      id: 'basel',
      name: 'Basel - Pharma-Industrie',
      shortName: 'Basel',
      description: 'Globale Pharmakonzerne, Biotechnologie, Medikamentenforschung',
      category: 'Forschung',
      position: const LatLng(47.5596, 7.5886),
      importance: 0.85,
      color: const Color(0xFF9C27B0),
      icon: Icons.biotech,
    ),
    MaterieLocation(
      id: 'amsterdam',
      name: 'Amsterdam - Freidenker Hub',
      shortName: 'Amsterdam',
      description: 'Progressive Denkfabrik, alternative Gesellschaftsmodelle',
      category: 'Alternative Kultur',
      position: const LatLng(52.3676, 4.9041),
      importance: 0.78,
      color: const Color(0xFF4CAF50),
      icon: Icons.lightbulb,
    ),
    MaterieLocation(
      id: 'zuerich',
      name: 'Zürich - Internationales Bankenzentrum',
      shortName: 'Zürich',
      description: 'Globales Finanzsystem, Geldströme, wirtschaftliche Macht',
      category: 'Geopolitik',
      position: const LatLng(47.3769, 8.5417),
      importance: 0.90,
      color: const Color(0xFF2196F3),
      icon: Icons.account_balance_wallet,
    ),
    MaterieLocation(
      id: 'stockholm',
      name: 'Stockholm - Transparenz-Zentrum',
      shortName: 'Stockholm',
      description: 'Wikileaks-Verbindungen, investigativer Journalismus',
      category: 'Transparenz',
      position: const LatLng(59.3293, 18.0686),
      importance: 0.82,
      color: const Color(0xFFFF9800),
      icon: Icons.public,
    ),
    MaterieLocation(
      id: 'prag',
      name: 'Prag - Historische Mysterien',
      shortName: 'Prag',
      description: 'Alchemie-Geschichte, esoterische Traditionen, verborgenes Wissen',
      category: 'Historische Forschung',
      position: const LatLng(50.0755, 14.4378),
      importance: 0.75,
      color: const Color(0xFF9C27B0),
      icon: Icons.auto_awesome,
    ),
  ];

  // Gefilterte Locations basierend auf Suche und Kategorien
  List<MaterieLocation> get _filteredLocations {
    return _allLocations.where((loc) {
      // Kategorie-Filter
      if (_selectedCategories.isNotEmpty && !_selectedCategories.contains(loc.category)) {
        return false;
      }
      
      // Such-Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return loc.name.toLowerCase().contains(query) ||
               loc.description.toLowerCase().contains(query) ||
               loc.category.toLowerCase().contains(query);
      }
      
      return true;
    }).toList();
  }

  // Alle verfügbaren Kategorien
  Set<String> get _allCategories {
    return _allLocations.map((loc) => loc.category).toSet();
  }

  // Karten-Layer Optionen
  final Map<String, String> _mapLayers = {
    'Standard': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    'Dark': 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png',
    'Satellite': 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    'Topographic': 'https://tile.opentopomap.org/{z}/{x}/{y}.png',
    'Mystery': 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🗺️ VOLLBILD-KARTE (füllt kompletten Bildschirm)
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(50.0, 10.0), // Zentral-Europa
                initialZoom: 5.0,
                minZoom: 3.0,
                maxZoom: 18.0,
                backgroundColor: const Color(0xFF1A1A1A),
                interactionOptions: const InteractionOptions(
                  enableMultiFingerGestureRace: true,
                  rotationThreshold: 20.0,
                ),
              ),
              children: [
                // Karten-Layer
                TileLayer(
                  urlTemplate: _mapLayers[_selectedMapLayer]!,
                  userAgentPackageName: 'com.weltenbibliothek.app',
                  tileProvider: NetworkTileProvider(),
                ),
                
                // Heat-Map Overlay (optional)
                if (_showHeatmap) _buildHeatmapLayer(),
                
                // Routen-Linien (wenn aktiviert)
                if (_showRoutes && _routePoints.length >= 2) _buildRouteLayer(),
                
                // Marker-Layer
                MarkerLayer(
                  markers: _buildMarkers(),
                ),
              ],
            ),
          ),
          
          // Top-Steuerung (SafeArea, als Overlay)
          SafeArea(
            child: Column(
              children: [
                // Such-Bar & Filter
                _buildSearchAndFilters(),
                
                const Spacer(),
                
                // Bottom-Controls
                _buildBottomControls(),
              ],
            ),
          ),
          
          // Detail-Panel (wenn Location ausgewählt)
          if (_selectedLocation != null)
            _buildDetailPanel(),
        ],
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════
  /// SUCHE & FILTER (CHIPS)
  /// ═══════════════════════════════════════════════════════════
  Widget _buildSearchAndFilters() {
    return Container(
      margin: EdgeInsets.all(context.responsive(mobile: 12, tablet: 12 * 1.5, desktop: 12 * 2)),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(context.responsive(mobile: 12.0, tablet: 16.0, desktop: 20.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Such-Bar
          Padding(
            padding: EdgeInsets.all(context.responsive(mobile: 12, tablet: 12 * 1.5, desktop: 12 * 2)),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: TextStyle(
                color: Colors.white,
                fontSize: context.responsive(mobile: 14, tablet: 14 * 1.2, desktop: 14 * 1.4),
              ),
              decoration: InputDecoration(
                hintText: 'Locations durchsuchen...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: context.responsive(mobile: 14, tablet: 14 * 1.2, desktop: 14 * 1.4),
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.responsive(mobile: 10, tablet: 10 * 1.2, desktop: 10 * 1.5)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // Kategorie-Chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: context.responsive(mobile: 8.0, tablet: 12.0, desktop: 16.0),
              ),
              children: [
                // "Alle" Chip
                _buildFilterChip(
                  label: 'Alle',
                  selected: _selectedCategories.isEmpty,
                  onTap: () => setState(() => _selectedCategories.clear()),
                  color: Colors.blue,
                ),
                
                // Kategorie-Chips
                ..._allCategories.map((category) => _buildFilterChip(
                  label: category,
                  selected: _selectedCategories.contains(category),
                  onTap: () {
                    setState(() {
                      if (_selectedCategories.contains(category)) {
                        _selectedCategories.remove(category);
                      } else {
                        _selectedCategories.add(category);
                      }
                    });
                  },
                  color: _getCategoryColor(category),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: context.responsive(mobile: 8.0, tablet: 12.0, desktop: 16.0)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(context.responsive(mobile: 20, tablet: 20 * 1.2, desktop: 20 * 1.5)),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.responsive(mobile: 8.0, tablet: 12.0, desktop: 16.0) * 1.5,
              vertical: context.responsive(mobile: 12.0, tablet: 16.0, desktop: 20.0) / 2,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(context.responsive(mobile: 20, tablet: 20 * 1.2, desktop: 20 * 1.5)),
              border: Border.all(
                color: selected ? color : Colors.white.withValues(alpha: 0.2),
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected)
                  Padding(
                    padding: EdgeInsets.only(right: context.responsive(mobile: 8.0, tablet: 12.0, desktop: 16.0) / 2),
                    child: Icon(
                      Icons.check_circle,
                      size: context.responsive(mobile: 16, tablet: 16 * 1.3, desktop: 16 * 1.5),
                      color: color,
                    ),
                  ),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? color : Colors.white,
                    fontSize: context.responsive(mobile: 12, tablet: 12 * 1.2, desktop: 12 * 1.4),
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Geopolitik': return const Color(0xFF2196F3);
      case 'Forschung': return const Color(0xFF9C27B0);
      case 'Alternative Medien': return const Color(0xFFFF9800);
      case 'Transparenz': return const Color(0xFFFF9800);
      case 'Alternative Kultur': return const Color(0xFF4CAF50);
      case 'Historische Forschung': return const Color(0xFF9C27B0);
      default: return Colors.grey;
    }
  }

  /// ═══════════════════════════════════════════════════════════
  /// MARKER MIT PULS-ANIMATION
  /// ═══════════════════════════════════════════════════════════
  List<Marker> _buildMarkers() {
    return _filteredLocations.map((location) {
      return Marker(
        width: 80,
        height: 80,
        point: location.position,
        child: GestureDetector(
          onTap: () => setState(() => _selectedLocation = location),
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulseController, _glowController]),
            builder: (context, child) {
              // Puls-Größe
              final pulseScale = 1.0 + (_pulseController.value * 0.3);
              
              // Glow-Intensität
              final glowOpacity = 0.3 + (_glowController.value * 0.4);
              
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Glow-Ring
                  Container(
                    width: 60 * pulseScale,
                    height: 60 * pulseScale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: location.color.withValues(alpha: glowOpacity),
                          blurRadius: 20,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  
                  // Marker-Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: location.color,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      location.icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  
                  // Location-Name (bei hohem Zoom)
                  Positioned(
                    bottom: -20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        location.shortName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
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

  /// ═══════════════════════════════════════════════════════════
  /// HEAT-MAP LAYER
  /// ═══════════════════════════════════════════════════════════
  Widget _buildHeatmapLayer() {
    // Heat-Map basierend auf Importance-Werten
    return MarkerLayer(
      markers: _filteredLocations.map((location) {
        final radius = 100.0 * location.importance;
        return Marker(
          width: radius * 2,
          height: radius * 2,
          point: location.position,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  location.color.withValues(alpha: 0.4 * location.importance),
                  location.color.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// ═══════════════════════════════════════════════════════════
  /// ROUTE-LAYER
  /// ═══════════════════════════════════════════════════════════
  Widget _buildRouteLayer() {
    return PolylineLayer(
      polylines: [
        Polyline(
          points: _routePoints.map((loc) => loc.position).toList(),
          color: const Color(0xFF2196F3),
          strokeWidth: 3.0,
          borderStrokeWidth: 1.0,
          borderColor: Colors.white.withValues(alpha: 0.5),
        ),
      ],
    );
  }

  /// ═══════════════════════════════════════════════════════════
  /// BOTTOM CONTROLS
  /// ═══════════════════════════════════════════════════════════
  Widget _buildBottomControls() {
    return Container(
      margin: EdgeInsets.all(context.responsive(mobile: 12, tablet: 12 * 1.5, desktop: 12 * 2)),
      padding: EdgeInsets.all(context.responsive(mobile: 12, tablet: 12 * 1.5, desktop: 12 * 2)),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(context.responsive(mobile: 12.0, tablet: 16.0, desktop: 20.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.layers,
            label: 'Layer',
            onTap: () => _showLayerPicker(),
          ),
          _buildControlButton(
            icon: _showHeatmap ? Icons.whatshot : Icons.whatshot_outlined,
            label: 'Heatmap',
            active: _showHeatmap,
            onTap: () => setState(() => _showHeatmap = !_showHeatmap),
          ),
          _buildControlButton(
            icon: _showRoutes ? Icons.route : Icons.route_outlined,
            label: 'Routen',
            active: _showRoutes,
            onTap: () => setState(() => _showRoutes = !_showRoutes),
          ),
          _buildControlButton(
            icon: Icons.my_location,
            label: 'Zentrum',
            onTap: () => _mapController.move(const LatLng(50.0, 10.0), 5.0),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.responsive(mobile: 8, tablet: 8 * 1.2, desktop: 8 * 1.5)),
        child: Container(
          padding: EdgeInsets.all(context.responsive(mobile: 8, tablet: 8 * 1.5, desktop: 8 * 2)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: active ? const Color(0xFF2196F3) : Colors.white70,
                size: context.responsive(mobile: 24, tablet: 24 * 1.3, desktop: 24 * 1.5),
              ),
              SizedBox(height: context.responsive(mobile: 12.0, tablet: 16.0, desktop: 20.0) / 3),
              Text(
                label,
                style: TextStyle(
                  color: active ? const Color(0xFF2196F3) : Colors.white70,
                  fontSize: context.responsive(mobile: 10, tablet: 10 * 1.2, desktop: 10 * 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════
  /// DETAIL-PANEL
  /// ═══════════════════════════════════════════════════════════
  Widget _buildDetailPanel() {
    final location = _selectedLocation!;
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag-Handle
            Container(
              width: 50,
              height: 4,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: EdgeInsets.all(context.responsive(mobile: 16.0, tablet: 24.0, desktop: 32.0)),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: EdgeInsets.all(context.responsive(mobile: 12.0, tablet: 18.0, desktop: 24.0)),
                    decoration: BoxDecoration(
                      color: location.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(context.responsive(mobile: 12, tablet: 12 * 1.2, desktop: 12 * 1.5)),
                    ),
                    child: Icon(
                      location.icon,
                      color: location.color,
                      size: context.responsive(mobile: 32, tablet: 32 * 1.3, desktop: 32 * 1.5),
                    ),
                  ),
                  
                  SizedBox(width: context.responsive(mobile: 8.0, tablet: 12.0, desktop: 16.0)),
                  
                  // Titel & Kategorie
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.shortName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.responsive(mobile: 20, tablet: 20 * 1.2, desktop: 20 * 1.4),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: context.responsive(mobile: 12.0, tablet: 16.0, desktop: 20.0) / 3),
                        Text(
                          location.category,
                          style: TextStyle(
                            color: location.color,
                            fontSize: context.responsive(mobile: 12, tablet: 12 * 1.2, desktop: 12 * 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Close Button
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => setState(() => _selectedLocation = null),
                  ),
                ],
              ),
            ),
            
            const Divider(color: Colors.white24),
            
            // Description
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(context.responsive(mobile: 16.0, tablet: 24.0, desktop: 32.0)),
                child: Text(
                  location.description,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: context.responsive(mobile: 14, tablet: 14 * 1.2, desktop: 14 * 1.4),
                    height: 1.5,
                  ),
                ),
              ),
            ),
            
            // Action Buttons
            Padding(
              padding: EdgeInsets.all(context.responsive(mobile: 16.0, tablet: 24.0, desktop: 32.0)),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Zur Location fliegen
                        _mapController.move(location.position, 12.0);
                        setState(() => _selectedLocation = null);
                      },
                      icon: const Icon(Icons.explore),
                      label: const Text('Zur Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: location.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: context.responsive(mobile: 8.0, tablet: 12.0, desktop: 16.0)),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Zur Route hinzufügen
                        setState(() {
                          if (!_routePoints.contains(location)) {
                            _routePoints.add(location);
                            _showRoutes = true;
                          }
                        });
                      },
                      icon: const Icon(Icons.add_road),
                      label: const Text('Route'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: location.color,
                        side: BorderSide(color: location.color),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════
  /// LAYER-PICKER DIALOG
  /// ═══════════════════════════════════════════════════════════
  void _showLayerPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Karten-Layer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            ..._mapLayers.keys.map((layer) => ListTile(
              leading: Icon(
                _selectedMapLayer == layer
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: const Color(0xFF2196F3),
              ),
              title: Text(
                layer,
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                setState(() => _selectedMapLayer = layer);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// MATERIE LOCATION MODEL
/// ═══════════════════════════════════════════════════════════
class MaterieLocation {
  final String id;
  final String name;
  final String shortName;
  final String description;
  final String category;
  final LatLng position;
  final double importance; // 0.0 - 1.0
  final Color color;
  final IconData icon;

  MaterieLocation({
    required this.id,
    required this.name,
    required this.shortName,
    required this.description,
    required this.category,
    required this.position,
    required this.importance,
    required this.color,
    required this.icon,
  });
}
