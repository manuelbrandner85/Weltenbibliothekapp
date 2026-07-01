import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/map_clustering_helper.dart'; // 🗺️ MARKER-CLUSTERING
import '../../services/live_map_pins_service.dart'; // 📍 B9: Live-Pins
import '../../services/youtube_service.dart';
import '../../services/wikimedia_service.dart';
import '../../widgets/live_pins_layer.dart'; // 📍 B9: Live-Pins-Marker
import '../../widgets/youtube_player_inline.dart';
import '../../widgets/wb_cached_image.dart';
import '../../widgets/wb_segmented_tabs.dart'; // 🧭 Unified Tab-Bar
import '../../data/energie_extra_locations.dart'; // 📍 +25 Marker (Phase 2)

/// ENERGIE-Karte Tab - Spirituelle Kraftorte & Ley-Lines
class EnergieKarteTabPro extends StatefulWidget {
  const EnergieKarteTabPro({super.key});

  @override
  State<EnergieKarteTabPro> createState() => _EnergieKarteTabProState();
}

class _EnergieKarteTabProState extends State<EnergieKarteTabPro>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  // Filter State (Single-Select)
  EnergieCategory? _selectedCategory; // null = "Alle" ausgewählt
  String _searchQuery = '';
  EnergieLocationDetail? _selectedLocation;
  bool _showLeyLines = true;

  // Map Layer State
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

  // Detail Panel Tab State
  int _detailTabIndex = 0;

  // Dynamic Media State
  List<YoutubeVideo>? _ytVideos;
  bool _ytLoading = false;
  YoutubeVideo? _ytPlaying;
  String _ytLocationName = '';

  List<String> _wikiImages = const [];
  bool _wikiLoading = false;
  String _wikiLocationName = '';

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
    final videos = await YoutubeService.instance.searchVideos(name, max: 5);
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

  List<EnergieLocationDetail> get _filteredLocations {
    var locations = allEnergieLocations;

    // Filter nach Kategorie (Single-Select)
    if (_selectedCategory != null) {
      locations =
          locations.where((loc) => loc.category == _selectedCategory).toList();
    }

    // Filter nach Such-Query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      locations = locations
          .where((loc) =>
              loc.name.toLowerCase().contains(query) ||
              loc.description.toLowerCase().contains(query) ||
              loc.keywords.any((k) => k.toLowerCase().contains(query)))
          .toList();
    }

    return locations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06040F),
      body: Stack(
        children: [
          // MAP
          // Feature E: close radial menu on background tap
          if (_layerMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _layerMenuOpen = false),
                child: Container(color: Colors.transparent),
              ),
            ),

          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(46.8182, 8.2275), // Schweiz Zentrum
              initialZoom: 5.0,
              minZoom: 2.0,
              maxZoom: 18.0,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture && !_headerCollapsed) {
                  setState(() => _headerCollapsed = true);
                }
              },
              // 📍 B9: Long-Press auf die Karte → Live-Pin-Modal öffnen
              onLongPress: (tapPos, latlng) =>
                  _showLivePinModal(context, latlng),
            ),
            children: [
              TileLayer(
                urlTemplate: _getMapLayerUrl(),
                userAgentPackageName: 'com.weltenbibliothek.app',
                maxZoom: 19,
              ),

              // 📍 B9: Live-Pins-Layer (gepulste Marker, auto-expire 5min)
              const LivePinsLayer(world: 'energie', accent: Color(0xFF9C27B0)),

              // LEY-LINES
              if (_showLeyLines)
                PolylineLayer(
                  polylines: _buildLeyLines(),
                ),

              // MARKERS mit Clustering — _buildMarkers() nur 1× pro Build
              // (vorher 2× → O(n²) bei vielen Markern)
              () {
                final markers = _buildMarkers();
                return MapClusteringHelper.createClusterLayer(
                  markers: markers,
                  clusterColor: const Color(0xFF9C27B0),
                  maxClusterRadius:
                      MapClusteringHelper.calculateOptimalClusterRadius(
                          markers.length),
                );
              }(),
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
                  color: const Color(0xFF1A0F2E).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF9C27B0).withValues(alpha: 0.4)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off,
                        color: Color(0xFF9C27B0), size: 32),
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
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Filter zurücksetzen'),
                    ),
                  ],
                ),
              ),
            ),

          // Feature F: Animated gradient sky header (collapsible)
          SafeArea(
            child: AnimatedBuilder(
              animation: _gradientAnim,
              builder: (context, child) {
                final alpha = (0.06 * math.sin(_gradientAnim.value * math.pi));
                return Stack(
                  children: [
                    // Gradient background behind header
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
                              const Color(0xFF9C27B0)
                                  .withValues(alpha: alpha.clamp(0.0, 0.06)),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Collapsible header content
                    AnimatedSize(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                      clipBehavior: Clip.hardEdge,
                      child: _headerCollapsed
                          ? const SizedBox.shrink()
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildTopBar(),
                                const SizedBox(height: 12),
                                _buildFilterChips(),
                              ],
                            ),
                    ),

                    // Collapsed state: floating search pill
                    if (_headerCollapsed)
                      Positioned(
                        top: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _headerCollapsed = false),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  height: 32,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: const Color(0xFF9C27B0)
                                            .withValues(alpha: 0.4)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.search,
                                          color: Colors.white70, size: 16),
                                      SizedBox(width: 6),
                                      Text('Suchen…',
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12)),
                                      SizedBox(width: 6),
                                      Icon(Icons.expand_more,
                                          color: Colors.white70, size: 16),
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

          // 🗺️ MAP LAYER SWITCHER (Bottom Left) — Feature E: Radial Menu
          Positioned(
            bottom: 100,
            left: 16,
            child: _buildRadialLayerMenu(),
          ),

          // DETAIL PANEL — Feature A: Blur + SlideTransition
          if (_selectedLocation != null) _buildDetailPanel(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xB31A0F2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFA855F7).withValues(alpha: 0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.50),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.14),
                  blurRadius: 32,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.map, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Kraftorte, Chakren, Ley-Lines suchen...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear,
                        color: Colors.white70, size: 20),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  ),
                IconButton(
                  icon: Icon(
                    _showLeyLines ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _showLeyLines = !_showLeyLines;
                    });
                  },
                  tooltip:
                      'Ley-Lines ${_showLeyLines ? 'ausblenden' : 'einblenden'}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final total = allEnergieLocations.length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // ALLE
          _buildFilterChip(
            label: 'Alle ($total)',
            icon: Icons.select_all,
            isSelected: _selectedCategory == null,
            onTap: () {
              setState(() {
                _selectedCategory = null; // "Alle" auswählen
              });
            },
            color: const Color(0xFF9C27B0),
          ),
          const SizedBox(width: 8),

          // KATEGORIEN
          ...EnergieCategory.values.map((cat) {
            final count =
                allEnergieLocations.where((l) => l.category == cat).length;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(
                label: '${cat.label} ($count)',
                icon: cat.icon,
                isSelected: _selectedCategory == cat,
                onTap: () {
                  setState(() {
                    _selectedCategory = cat; // Single-Select
                  });
                },
                color: cat.color,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.40),
                    color.withValues(alpha: 0.18),
                  ],
                )
              : null,
          color: isSelected ? null : const Color(0xB30C1022),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.10),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    return _filteredLocations.map((location) {
      final isSelected = _selectedLocation?.name == location.name;
      return Marker(
        point: location.position,
        width: 64,
        height: 64,
        child: GestureDetector(
          onTap: () {
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
            _loadYoutubeForLocation(location.name);
            _loadWikimediaForLocation(location.name);
          },
          child: _PulsingMarker(
            categoryColor: location.category.color,
            icon: location.category.icon,
            isSelected: isSelected,
            label: location.category.label,
          ),
        ),
      );
    }).toList();
  }

  /// v5.44.7: Extrapoliert eine Ley-Line ueber ihre genannten Orte hinaus.
  /// Eine Ley-Line ist konzeptionell eine durchgehende Linie um die Erde - die
  /// genannten Orte sind nur Markierungen auf der Linie, nicht End-Punkte.
  /// Daher: extrapoliere vor dem ersten und nach dem letzten Punkt um
  /// [extendFactor]-fache der Endsegment-Laenge, damit die Linie ueber den
  /// sichtbaren Kartenrand hinausgeht und der User keine "abgeschnittenen"
  /// Linien sieht.
  ///
  /// Einfache lineare Extrapolation in Lat/Lng (gut genug fuer Karten-Visual,
  /// Geodaeten-Mathematik wuerde Vincenty erfordern).
  List<LatLng> _extendLine(List<LatLng> points, {double extendFactor = 4.0}) {
    if (points.length < 2) return points;
    final out = <LatLng>[];
    // Vor dem ersten Punkt: rueckwaerts vom Vektor (points[1] -> points[0])
    final first = points.first;
    final second = points[1];
    out.add(LatLng(
      first.latitude + (first.latitude - second.latitude) * extendFactor,
      first.longitude + (first.longitude - second.longitude) * extendFactor,
    ));
    out.addAll(points);
    // Nach dem letzten Punkt: vorwaerts vom Vektor (last-1 -> last)
    final lastIdx = points.length - 1;
    final last = points[lastIdx];
    final secondLast = points[lastIdx - 1];
    out.add(LatLng(
      last.latitude + (last.latitude - secondLast.latitude) * extendFactor,
      last.longitude + (last.longitude - secondLast.longitude) * extendFactor,
    ));
    return out;
  }

  List<Polyline> _buildLeyLines() {
    // Quellen: John Michell "The View Over Atlantis" (St. Michael-Linie),
    // Paul Devereux "Ley Lines: The Greatest Landscape Mystery" (2007),
    // Alfred Watkins "The Old Straight Track" (1925), David Cowan
    // "Ancient Energies of the Earth", Hartmann-/Curry-Gitter-Mapper.
    // Esoterische Tradition — kein verifiziertes physikalisches Phänomen.
    return [
      // ━━━ ST. MICHAEL & APOLLO-LINIE (Europas berühmteste Leyline)
      // Sieben Michaelheiligtümer in gerader Linie quer durch Europa.
      Polyline(
        points: _extendLine([
          const LatLng(50.1689, -5.4759), // St. Michael's Mount, Cornwall
          const LatLng(51.1448, -2.6986), // Glastonbury Tor
          const LatLng(51.7548, 0.4715), // Bury St Edmunds
          const LatLng(48.6360, -1.5115), // Mont-Saint-Michel
          const LatLng(45.0975, 7.3429), // Sacra di San Michele
          const LatLng(41.7081, 15.9536), // Monte Sant'Angelo Gargano
          const LatLng(36.6147, 27.8358), // Symi-Insel
          const LatLng(32.8275, 34.9701), // Stella Maris Berg Karmel
        ]),
        strokeWidth: 2.5,
        color: const Color(0xFFFFEB3B).withAlpha((0.55 * 255).round()),
      ),

      // ━━━ ST. MARY-LINIE (parallel zu Michael, "weibliche" Linie)
      Polyline(
        points: _extendLine([
          const LatLng(
              51.1448, -2.6986), // Glastonbury (Schnittpunkt mit Michael)
          const LatLng(51.4286, -1.8542), // Avebury
          const LatLng(52.6864, 1.2934), // Norwich
        ]),
        strokeWidth: 2,
        color: const Color(0xFFE91E63).withAlpha((0.5 * 255).round()),
      ),

      // ━━━ ATLANTIS-ENERGIE-LINIE
      Polyline(
        points: _extendLine([
          const LatLng(27.9881, -15.4165), // Kanarische Inseln
          const LatLng(29.9792, 31.1342), // Gizeh
          const LatLng(31.7683, 35.2137), // Jerusalem
          const LatLng(37.9838, 23.7275), // Athen / Akropolis
          const LatLng(38.4824, 22.5010), // Delphi
        ]),
        strokeWidth: 2,
        color: const Color(0xFF00BCD4).withAlpha((0.5 * 255).round()),
      ),

      // ━━━ HIMALAYA-CHAKRA-LINIE
      Polyline(
        points: _extendLine([
          const LatLng(31.0667, 81.3125), // Mount Kailash
          const LatLng(27.9878, 86.9250), // Mount Everest
          const LatLng(29.6517, 91.1176), // Lhasa Potala
          const LatLng(27.1751, 78.0421), // Taj Mahal
          const LatLng(24.6961, 84.9911), // Bodhgaya
          const LatLng(25.3176, 82.9739), // Varanasi
          const LatLng(19.0760, 72.8777), // Mumbai
        ]),
        strokeWidth: 2,
        color: const Color(0xFF9C27B0).withAlpha((0.5 * 255).round()),
      ),

      // ━━━ HYPERBOREAN-LINIE (Nord-Süd durch Europa)
      // Watkins beschrieb diese als "alte Geraden Strecke" durch
      // mehrere britische und kontinentale Megalith-Plätze.
      Polyline(
        points: _extendLine([
          const LatLng(64.9631, -19.0208), // Þingvellir, Island
          const LatLng(58.9700, 5.7331), // Stavanger
          const LatLng(54.5973, -5.9301), // Belfast
          const LatLng(53.6948, -6.4753), // Newgrange
          const LatLng(51.1789, -1.8262), // Stonehenge
          const LatLng(43.5263, 5.4454), // Aix-en-Provence
        ]),
        strokeWidth: 2,
        color: const Color(0xFF4CAF50).withAlpha((0.45 * 255).round()),
      ),

      // ━━━ PAZIFIK-RING (Vulkangürtel als Energie-Ring, John Michell)
      Polyline(
        points: _extendLine([
          const LatLng(41.4099, -122.1949), // Mount Shasta
          const LatLng(34.8697, -111.7610), // Sedona
          const LatLng(19.4069, -155.2834), // Kilauea
          const LatLng(-25.3444, 131.0369), // Uluru
          const LatLng(-43.5950, 170.1418), // Aoraki / Mt Cook
          const LatLng(35.3606, 138.7274), // Mount Fuji
        ]),
        strokeWidth: 2,
        color: const Color(0xFFFF5722).withAlpha((0.45 * 255).round()),
      ),

      // ━━━ MAYA-INKA-LINIE (Mesoamerika)
      Polyline(
        points: _extendLine([
          const LatLng(19.6925, -98.8438), // Teotihuacán
          const LatLng(20.6843, -88.5678), // Chichén Itzá
          const LatLng(17.2229, -89.6230), // Tikal
          const LatLng(-13.1631, -72.5450), // Machu Picchu
          const LatLng(-14.6919, -75.1380), // Nazca-Linien
        ]),
        strokeWidth: 2,
        color: const Color(0xFFFF9800).withAlpha((0.45 * 255).round()),
      ),

      // ━━━ AFRIKA-EUROPA-LINIE (Sphinx-Akhenaten-Linie)
      Polyline(
        points: _extendLine([
          const LatLng(29.9753, 31.1376), // Sphinx Gizeh
          const LatLng(25.7188, 32.6573), // Karnak / Luxor
          const LatLng(-25.6833, 30.5000), // Adam's Calendar Südafrika
        ]),
        strokeWidth: 2,
        color: const Color(0xFFFFC107).withAlpha((0.45 * 255).round()),
      ),

      // ━━━ DEUTSCH-NORDISCHE LINIE (Wilhelm Teudt "Heilige Linien" 1929)
      Polyline(
        points: _extendLine([
          const LatLng(51.8689, 8.9152), // Externsteine
          const LatLng(53.2350, 9.2725), // Steinkreis von Boitin
          const LatLng(54.7833, 11.7000), // Hünengrab Fehmarn
          const LatLng(57.7089, 11.9746), // Göteborg
        ]),
        strokeWidth: 2,
        color: const Color(0xFFCDDC39).withAlpha((0.45 * 255).round()),
      ),

      // ━━━ PETRA-MEKKA-LINIE (semitisch-arabischer Korridor)
      Polyline(
        points: _extendLine([
          const LatLng(30.3285, 35.4444), // Petra
          const LatLng(31.7683, 35.2137), // Jerusalem
          const LatLng(21.4225, 39.8262), // Mekka Kaaba
          const LatLng(24.4670, 39.6118), // Medina
        ]),
        strokeWidth: 2,
        color: const Color(0xFF795548).withAlpha((0.5 * 255).round()),
      ),

      // ━━━ KELTISCH-IBERISCHE LINIE
      Polyline(
        points: _extendLine([
          const LatLng(43.5263, -1.5556), // Bayonne (keltisches Heiligtum)
          const LatLng(40.4168, -3.7038), // Madrid
          const LatLng(38.7223, -9.1393), // Lissabon
          const LatLng(38.7967, -9.3963), // Sintra Quinta da Regaleira
        ]),
        strokeWidth: 2,
        color: const Color(0xFF03A9F4).withAlpha((0.45 * 255).round()),
      ),

      // ━━━ ASIATISCH-OZEANISCHE LINIE
      Polyline(
        points: _extendLine([
          const LatLng(29.6557, 91.1170), // Lhasa Potala
          const LatLng(13.4125, 103.8670), // Angkor Wat
          const LatLng(-7.6079, 110.2038), // Borobudur
          const LatLng(-25.3444, 131.0369), // Uluru
        ]),
        strokeWidth: 2,
        color: const Color(0xFF673AB7).withAlpha((0.45 * 255).round()),
      ),
    ];
  }

  Widget _buildDetailPanel() {
    // Defensiv: kann zwischen setState und Build null werden (Race)
    final location = _selectedLocation;
    if (location == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _panelSlideAnimation,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: location.category.color.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: location.category.color.withValues(alpha: 0.15),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
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
                        _PulsingIconContainer(
                          color: location.category.color,
                          icon: location.category.icon,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                location.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                location.category.label,
                                style: TextStyle(
                                  color: location.category.color,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () {
                            setState(() {
                              _selectedLocation = null;
                              _detailTabIndex = 0;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // TABS — immer alle 3 sichtbar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: WbSegmentedTabs(
                      style: WbTabsStyle.underline,
                      accent: Colors.white,
                      selectedIndex: _detailTabIndex,
                      onChanged: (i) => setState(() => _detailTabIndex = i),
                      items: const [
                        WbTabItem(label: 'Info', icon: Icons.info_outline),
                        WbTabItem(label: 'Bilder', icon: Icons.image_outlined),
                        WbTabItem(
                            label: 'Videos', icon: Icons.play_circle_outline),
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
      ), // SlideTransition
    ); // Positioned
  }

  Widget _buildTabContent(EnergieLocationDetail location) {
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

  Widget _buildInfoTab(EnergieLocationDetail location) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Energie-Level
        if (location.energyLevel != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.05 * 255).round()),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: location.category.color.withAlpha((0.3 * 255).round()),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '✨ Energie-Level',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${location.energyLevel}/10',
                      style: TextStyle(
                        color: location.category.color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: location.energyLevel! / 10,
                    minHeight: 10,
                    backgroundColor:
                        Colors.white.withAlpha((0.1 * 255).round()),
                    valueColor: AlwaysStoppedAnimation(location.category.color),
                  ),
                ),
              ],
            ),
          ),

        // Description
        Text(
          location.description,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
            height: 1.5,
          ),
        ),

        if (location.detailedInfo.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.05 * 255).round()),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              location.detailedInfo,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withAlpha((0.8 * 255).round()),
                height: 1.6,
              ),
            ),
          ),
        ],

        // Keywords
        if (location.keywords.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: location.keywords.map((keyword) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: location.category.color.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        location.category.color.withAlpha((0.5 * 255).round()),
                  ),
                ),
                child: Text(
                  keyword,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ],

        // Sources
        if (location.sources.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'Quellen:',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white,
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
                    color: Colors.white.withAlpha((0.6 * 255).round()),
                  ),
                ),
              )),
        ],

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildImagesTab(EnergieLocationDetail location) {
    // genspark.ai URLs sind temporäre KI-Bild-Links die nicht öffentlich zugänglich sind → filtern
    final allImages = [
      ...location.imageUrls.where((url) => !url.contains('genspark.ai')),
      ..._wikiImages,
    ];

    if (_wikiLoading && allImages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF9C27B0), strokeWidth: 2),
            SizedBox(height: 12),
            Text('Suche Bilder…',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      );
    }

    if (allImages.isEmpty) {
      return Container(
        height: 240,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF7C4DFF).withValues(alpha: 0.08),
              Colors.black.withValues(alpha: 0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome,
                size: 48, color: Colors.white.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              'Kein Bild verfügbar',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              location.name,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Feature C: Cinematic image swiper
    final maxDots = allImages.length.clamp(0, 6);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // PageView with parallax
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
                            pageBuilder: (_, __, ___) => _FullscreenImageViewer(
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
                              tag: 'map_image_${index}_${location.name}',
                              child: Transform.translate(
                                offset: Offset(offset, 0),
                                // PERF-FIX (#3): Karten-Bilder cachen.
                                child: WbCachedImage(
                                  allImages[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 220,
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
              // Counter badge top-right
              Positioned(
                top: 8,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        // Dot indicators
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
                color: isCurrent ? const Color(0xFF9C27B0) : Colors.transparent,
                border: Border.all(
                  color: const Color(0xFF9C27B0).withValues(alpha: 0.7),
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

  List<YoutubeVideo> _hardcodedEnergieVideos(EnergieLocationDetail location) {
    return location.videoUrls
        .where((id) => id.isNotEmpty)
        .map((id) => YoutubeVideo(
              videoId: id,
              title: location.name,
              channel: 'YouTube',
              thumbnail: '',
              published: '',
              description: '',
            ))
        .toList();
  }

  Widget _buildVideosTab(EnergieLocationDetail location) {
    final staticVideos = _hardcodedEnergieVideos(location);
    final allVideos = [
      ...staticVideos,
      ...(_ytVideos ?? [])
          .where((v) => staticVideos.every((s) => s.videoId != v.videoId)),
    ];

    if (_ytPlaying != null) {
      return SingleChildScrollView(
        child: Column(
          children: [
            YoutubePlayerInline(
              video: _ytPlaying!,
              onClose: () => setState(() => _ytPlaying = null),
            ),
            const SizedBox(height: 12),
            ..._buildEnergieVideoList(allVideos),
          ],
        ),
      );
    }

    if (allVideos.isEmpty && _ytLoading) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: Color(0xFF9C27B0), strokeWidth: 2),
          SizedBox(height: 12),
          Text('Suche Videos…',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
        ]),
      );
    }

    if (allVideos.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.videocam_off, color: Colors.white24, size: 40),
          SizedBox(height: 8),
          Text('Keine Videos verfügbar',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
        ]),
      );
    }

    return SingleChildScrollView(
        child: Column(children: _buildEnergieVideoList(allVideos)));
  }

  List<Widget> _buildEnergieVideoList(List<YoutubeVideo> videos) {
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
                  ? const Color(0xFF9C27B0)
                  : const Color(0xFF9C27B0).withValues(alpha: 0.3),
              width: isPlaying ? 2 : 1,
            ),
            color: Colors.black.withValues(alpha: 0.3),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(children: [
            Stack(children: [
              // PERF-FIX (#3): Video-Thumbnails cachen.
              WbCachedImage(
                video.thumbnail.isNotEmpty
                    ? video.thumbnail
                    : video.fallbackThumbnail,
                width: 110,
                height: 70,
                fit: BoxFit.cover,
                errorWidget: Container(
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
                  color: const Color(0xFF9C27B0),
                  size: 32,
                ),
              )),
            ]),
            Expanded(
                child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(video.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      Expanded(
                          child: Text(video.channel,
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                      if (video.isSubtitled)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.4),
                                width: 0.8),
                          ),
                          child: const Text('🇩🇪 UT',
                              style: TextStyle(
                                  color: Colors.lightBlueAccent,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700)),
                        ),
                    ]),
                  ]),
            )),
          ]),
        ),
      );
    }).toList();
  }

  // 🗺️ MAP LAYER URL PROVIDER
  String _getMapLayerUrl() {
    switch (_currentMapLayer) {
      case 'street':
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case 'satellite':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case 'terrain':
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
      case 'topo':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}';
      default:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  // Feature E: Radial circular layer menu
  Widget _buildRadialLayerMenu() {
    const accent = Color(0xFFA855F7);
    const layers = [
      ('street', Icons.map, 'Straße'),
      ('satellite', Icons.satellite, 'Satellit'),
      ('terrain', Icons.terrain, 'Gelände'),
      ('topo', Icons.layers, 'Topo'),
    ];

    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Fan options — animate outward
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
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? accent.withValues(alpha: 0.85)
                                : const Color(0xB31A0F2E),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : Colors.white.withValues(alpha: 0.12),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.45),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                              if (isSelected)
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.55),
                                  blurRadius: 18,
                                ),
                            ],
                          ),
                          child: Icon(icon,
                              size: 20,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.75)),
                        ),
                      ),
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
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _layerMenuOpen
                          ? accent.withValues(alpha: 0.85)
                          : const Color(0xB31A0F2E),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: accent.withValues(
                              alpha: _layerMenuOpen ? 0.55 : 0.25),
                          blurRadius: _layerMenuOpen ? 22 : 14,
                        ),
                      ],
                    ),
                    child: AnimatedRotation(
                      turns: _layerMenuOpen ? 0.125 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.layers,
                        size: 24,
                        color: _layerMenuOpen ? Colors.white : accent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────
  // 📍 BUNDLE 9: LIVE MAP PINS (Energie-USP)
  // ───────────────────────────────────────────────────────────────────
  Future<void> _showLivePinModal(BuildContext context, LatLng latlng) async {
    final controller = TextEditingController();
    const accent = Color(0xFF9C27B0);
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
      backgroundColor: const Color(0xFF100B1E),
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
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.location_on, color: accent, size: 22),
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
                  borderSide: BorderSide(color: accent.withValues(alpha: 0.25)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: accent, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accent.withValues(alpha: 0.25)),
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
                    onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                    icon: const Icon(Icons.send, size: 18),
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
      world: 'energie',
      lat: latlng.latitude,
      lon: latlng.longitude,
      label: result,
      authorName: authorName,
      authorAvatarUrl: avatarUrl,
    );
    if (mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('📍 Live-Pin gesendet — alle sehen ihn live'),
          backgroundColor: accent,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature B: Animated pulsing marker
// ─────────────────────────────────────────────────────────────────────────────
class _PulsingMarker extends StatefulWidget {
  final Color categoryColor;
  final IconData icon;
  final bool isSelected;
  final String label;

  const _PulsingMarker({
    required this.categoryColor,
    required this.icon,
    required this.isSelected,
    this.label = '',
  });

  @override
  State<_PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<_PulsingMarker>
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
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
              if (widget.label.isNotEmpty) ...[
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.categoryColor.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.label.length > 10
                        ? '${widget.label.substring(0, 9)}…'
                        : widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature A: Pulsing icon in panel header
// ─────────────────────────────────────────────────────────────────────────────
class _PulsingIconContainer extends StatefulWidget {
  final Color color;
  final IconData icon;
  const _PulsingIconContainer({required this.color, required this.icon});

  @override
  State<_PulsingIconContainer> createState() => _PulsingIconContainerState();
}

class _PulsingIconContainerState extends State<_PulsingIconContainer>
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
        child: Icon(widget.icon, color: widget.color, size: 28),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature D: Fullscreen image viewer with Hero + swipe-down-to-close
// ─────────────────────────────────────────────────────────────────────────────
class _FullscreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String locationName;

  const _FullscreenImageViewer({
    required this.images,
    required this.initialIndex,
    required this.locationName,
  });

  @override
  State<_FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<_FullscreenImageViewer>
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
    return AnimatedOpacity(
      opacity: _fadeAnim.value,
      duration: Duration.zero,
      child: AnimatedBuilder(
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
                          tag: 'map_image_${index}_${widget.locationName}',
                          // PERF-FIX (#3): Fullscreen-Bild cachen.
                          child: WbCachedImage(
                            widget.images[index],
                            fit: BoxFit.contain,
                            errorWidget: const Icon(Icons.broken_image,
                                color: Colors.white30, size: 80),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Close button
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
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ENERGIE KATEGORIEN
enum EnergieCategory {
  leyLines,
  chakraPoints,
  kraftorte,
  meditationCenters,
  sacredSites,
  vortexPoints,
  crystalCaves,
  ancientTemples,
  // NEUE KATEGORIEN FÜR HISTORISCHE EVENTS
  ancientWisdom, // Antike Weisheit
  spiritualTeachings, // Spirituelle Lehren
  consciousnessShifts, // Bewusstseins-Shifts
  cosmicEvents, // Kosmische Ereignisse
  energyDisasters, // Energie-Katastrophen
  dimensionalPortals, // Dimensionale Portale
  collectiveTrauma, // Kollektive Traumata
  awakeningMoments, // Erwachensmomente
  darkEnergies, // Dunkle Energien
  lightWarriors, // Lichtkrieger
  truthSeekers, // Wahrheitssucher
  frequencyShifts; // Frequenz-Verschiebungen

  String get label {
    switch (this) {
      case EnergieCategory.leyLines:
        return 'Ley-Lines';
      case EnergieCategory.chakraPoints:
        return 'Chakra-Punkte';
      case EnergieCategory.kraftorte:
        return 'Kraftorte';
      case EnergieCategory.meditationCenters:
        return 'Meditation';
      case EnergieCategory.sacredSites:
        return 'Heilige Stätten';
      case EnergieCategory.vortexPoints:
        return 'Vortex-Punkte';
      case EnergieCategory.crystalCaves:
        return 'Kristall-Höhlen';
      case EnergieCategory.ancientTemples:
        return 'Alte Tempel';
      case EnergieCategory.ancientWisdom:
        return 'Antike Weisheit';
      case EnergieCategory.spiritualTeachings:
        return 'Spirituelle Lehren';
      case EnergieCategory.consciousnessShifts:
        return 'Bewusstseins-Shifts';
      case EnergieCategory.cosmicEvents:
        return 'Kosmische Ereignisse';
      case EnergieCategory.energyDisasters:
        return 'Energie-Katastrophen';
      case EnergieCategory.dimensionalPortals:
        return 'Dimensionale Portale';
      case EnergieCategory.collectiveTrauma:
        return 'Kollektive Traumata';
      case EnergieCategory.awakeningMoments:
        return 'Erwachensmomente';
      case EnergieCategory.darkEnergies:
        return 'Dunkle Energien';
      case EnergieCategory.lightWarriors:
        return 'Lichtkrieger';
      case EnergieCategory.truthSeekers:
        return 'Wahrheitssucher';
      case EnergieCategory.frequencyShifts:
        return 'Frequenz-Shifts';
    }
  }

  IconData get icon {
    switch (this) {
      case EnergieCategory.leyLines:
        return Icons.show_chart;
      case EnergieCategory.chakraPoints:
        return Icons.self_improvement;
      case EnergieCategory.kraftorte:
        return Icons.energy_savings_leaf;
      case EnergieCategory.meditationCenters:
        return Icons.spa;
      case EnergieCategory.sacredSites:
        return Icons.temple_buddhist;
      case EnergieCategory.vortexPoints:
        return Icons.cyclone;
      case EnergieCategory.crystalCaves:
        return Icons.diamond;
      case EnergieCategory.ancientTemples:
        return Icons.account_balance;
      case EnergieCategory.ancientWisdom:
        return Icons.auto_stories;
      case EnergieCategory.spiritualTeachings:
        return Icons.school;
      case EnergieCategory.consciousnessShifts:
        return Icons.psychology;
      case EnergieCategory.cosmicEvents:
        return Icons.auto_awesome;
      case EnergieCategory.energyDisasters:
        return Icons.flash_on;
      case EnergieCategory.dimensionalPortals:
        return Icons.all_inclusive;
      case EnergieCategory.collectiveTrauma:
        return Icons.healing;
      case EnergieCategory.awakeningMoments:
        return Icons.wb_sunny;
      case EnergieCategory.darkEnergies:
        return Icons.dark_mode;
      case EnergieCategory.lightWarriors:
        return Icons.shield;
      case EnergieCategory.truthSeekers:
        return Icons.search;
      case EnergieCategory.frequencyShifts:
        return Icons.vibration;
    }
  }

  Color get color {
    switch (this) {
      case EnergieCategory.leyLines:
        return const Color(0xFFFFEB3B); // Gelb
      case EnergieCategory.chakraPoints:
        return const Color(0xFF9C27B0); // Lila
      case EnergieCategory.kraftorte:
        return const Color(0xFF4CAF50); // Grün
      case EnergieCategory.meditationCenters:
        return const Color(0xFF00BCD4); // Cyan
      case EnergieCategory.sacredSites:
        return const Color(0xFFFF9800); // Orange
      case EnergieCategory.vortexPoints:
        return const Color(0xFFE91E63); // Pink
      case EnergieCategory.crystalCaves:
        return const Color(0xFF03A9F4); // Blau
      case EnergieCategory.ancientTemples:
        return const Color(0xFF795548); // Braun
      case EnergieCategory.ancientWisdom:
        return const Color(0xFF8BC34A); // Hellgrün
      case EnergieCategory.spiritualTeachings:
        return const Color(0xFF673AB7); // Tiefviolett
      case EnergieCategory.consciousnessShifts:
        return const Color(0xFF00BCD4); // Türkis
      case EnergieCategory.cosmicEvents:
        return const Color(0xFFFFEB3B); // Gold
      case EnergieCategory.energyDisasters:
        return const Color(0xFFFF5722); // Tiefes Orange
      case EnergieCategory.dimensionalPortals:
        return const Color(0xFF9C27B0); // Magenta
      case EnergieCategory.collectiveTrauma:
        return const Color(0xFF607D8B); // Blaugrau
      case EnergieCategory.awakeningMoments:
        return const Color(0xFFFFC107); // Amber
      case EnergieCategory.darkEnergies:
        return const Color(0xFF424242); // Dunkelgrau
      case EnergieCategory.lightWarriors:
        return const Color(0xFFFFFFFF); // Weiß
      case EnergieCategory.truthSeekers:
        return const Color(0xFF2196F3); // Blau
      case EnergieCategory.frequencyShifts:
        return const Color(0xFFE91E63); // Pink
    }
  }
}

// ENERGIE LOCATION MODEL
class EnergieLocationDetail {
  final String name;
  final String description;
  final String detailedInfo;
  final LatLng position;
  final EnergieCategory category;
  final List<String> keywords;
  final int? energyLevel; // 1-10
  final List<String> imageUrls;
  final List<String> videoUrls; // YouTube Video IDs
  final List<String> sources;

  EnergieLocationDetail({
    required this.name,
    required this.description,
    required this.detailedInfo,
    required this.position,
    required this.category,
    this.keywords = const [],
    this.energyLevel,
    this.imageUrls = const [],
    this.videoUrls = const [],
    this.sources = const [],
  });
}

// ENERGIE LOCATIONS DATA
final List<EnergieLocationDetail> allEnergieLocations = [
  // LEY-LINES KNOTENPUNKTE
  EnergieLocationDetail(
    name: 'Stonehenge - England',
    description: 'Prähistorisches Monument & Ley-Line-Knotenpunkt',
    detailedInfo:
        '''Stonehenge ist eines der berühmtesten megalithischen Bauwerke der Welt, gelegen in der Salisbury Plain in Südengland. Erbaut vor etwa 5.000 Jahren (3.000 v. Chr.), besteht es aus massiven Steinkreisen, die perfekt ausgerichtet sind.

📘 OFFIZIELLE VERSION (Archäologie):
Stonehenge war ein prähistorischer Tempel und Begräbnisplatz. Erbaut in mehreren Phasen zwischen 3.000-1.500 v. Chr. Die äußeren Sarsen-Steine (bis 25 Tonnen) wurden 30 km weit transportiert, die inneren Bluestones (bis 4 Tonnen) aus Wales (240 km). Astronomische Ausrichtung: Sonnenwende-Sonnenaufgang am 21. Juni. Funktion: Zeremonielle Stätte für Bestattungen, Feste und Sonnenanbetung. English Heritage: "Ein Monument für die Ahnen".

🔍 ALTERNATIVE SICHTWEISE (Ley-Lines & Energie):
Stonehenge liegt auf einem kraftvollen Ley-Line-Knotenpunkt - Energielinien, die die Erde durchziehen. Die Steine fungieren als Energieverstärker und Portal zwischen Dimensionen. Druiden nutzten Stonehenge für Rituale und Heilungen. Die präzise Ausrichtung ermöglicht kosmische Energiekanalisierung während der Sonnenwende. Akustische Resonanz: Die Bluestones haben piezoelektrische Eigenschaften - sie erzeugen elektrische Ladung unter Druck. Erdmagnetische Anomalien: Messbare Magnetfeldabweichungen am Standort. Stonehenge könnte Teil eines weltweiten Energie-Gitter-Netzwerks sein.

🔬 BEWEISE & INDIZIEN:
• Erdmagnetische Messungen: 1960er Studien zeigten Magnetfeldanomalien im Stonehenge-Kreis
• Bluestones aus Wales: Prähistorischer Transport über 240 km - warum diese spezifischen Steine?
• Piezoelektrische Eigenschaften: Bluestones erzeugen elektrische Ladung bei Druck (Paul Devereux, 2001)
• Akustische Resonanz: Studien zeigten ungewöhnliche Klangverstärkung im Steinkreis (Royal College of Art, 2012)
• Ley-Line-Kartierungen: Alfred Watkins (1925) dokumentierte Steinkreis-Alignments über ganz Großbritannien
• Astronomische Präzision: Sonnenwende-Ausrichtung auf 1° genau - fortgeschrittenes astronomisches Wissen
• Heilungsberichte: Mittelalterliche Texte beschreiben Stonehenge-Steine als "Riesenheilsteine"
• Moderne Radiästhesie: Rutengänger messen starke Energie-Wirbel an den Steinpositionen
• Aubrey Holes: 56 Löcher bilden perfekten Kreis - mögliche Mondphasen-Berechnung (Gerald Hawkins, 1963)''',
    position: const LatLng(51.1789, -1.8262),
    category: EnergieCategory.leyLines,
    keywords: [
      'Stonehenge',
      'Megalith',
      'Ley-Line',
      'Druiden',
      'Sonnenwende',
      'Bluestones',
      'Erdmagnetismus',
      'Akustische Resonanz'
    ],
    energyLevel: 10,
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3c/Stonehenge2007_07_30.jpg/1200px-Stonehenge2007_07_30.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d3/Stonehenge_Closeup.jpg/1200px-Stonehenge_Closeup.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e4/Stonehenge_Panorama.jpg/1200px-Stonehenge_Panorama.jpg',
    ],
    videoUrls: ['Dah5JKW9Y3M'], // Stonehenge Documentary
    sources: [
      'English Heritage: "Stonehenge: A Complete History" (2021) - 384 Seiten, offizielle archäologische Dokumentation',
      'Gerald Hawkins: "Stonehenge Decoded" (1965) - 202 Seiten, astronomische Analyse, Nature-publiziert',
      'Paul Devereux: "Stone Age Soundtracks" (2001) - Akustik- und Energiestudien, 312 Seiten',
      'Alfred Watkins: "The Old Straight Track" (1925) - 256 Seiten, Ley-Line-Pionier-Werk',
      'Royal College of Art Acoustic Study (2012) - Peer-reviewed Resonanzforschung',
      'Mike Parker Pearson: "Stonehenge: Exploring the Greatest Stone Age Mystery" (2012) - 448 Seiten, Ausgrabungsberichte',
    ],
  ),

  EnergieLocationDetail(
    name: 'Gizeh-Pyramiden - Ägypten',
    description: 'Antikes Weltwunder & Energie-Zentrum',
    detailedInfo:
        '''Die Große Pyramide von Gizeh (Cheops-Pyramide) ist das älteste und einzige erhaltene der Sieben Weltwunder der Antike. Erbaut vor etwa 4.500 Jahren (2.560 v. Chr.), ein architektonisches und mathematisches Meisterwerk.

📘 OFFIZIELLE VERSION (Ägyptologie):
Die Pyramiden von Gizeh wurden als Grabmäler für die Pharaonen Cheops, Chephren und Mykerinos errichtet. Erbaut von tausenden Arbeitern über ~20 Jahre. 2,3 Millionen Steinblöcke (je 2,5 Tonnen). Rampen und Hebelwerkzeuge wurden zum Transport verwendet. Präzise Ausrichtung nach Himmelsrichtungen (Nordkante nur 3,4 Bogenminuten Abweichung). Funktion: Aufstieg des Pharao ins Jenseits, monumentale Machtdemonstration. Keine mysteriösen Technologien - nur ingenieurtechnisches Können der alten Ägypter.

🔍 ALTERNATIVE SICHTWEISE (Energietechnologie & Ancient Aliens):
Die Große Pyramide war kein Grabmal, sondern ein Energiekonverter bzw. Kraftwerk. Christopher Dunn-Theorie (1998): Pyramide nutzte unterirdische Wasserströme und chemische Reaktionen zur Wasserstoff-Erzeugung - Energiegewinnung. Orion-Korrelation: Die 3 Pyramiden spiegeln exakt den Gürtel des Orion-Sternbilds (Robert Bauval, 1993) - astronomisches Wissen weit über die Zeit hinaus. Goldener Schnitt & Pi: Mathematische Verhältnisse in der Pyramide zeigen fortgeschrittenes Wissen. Präzision unmöglich mit Bronze-Werkzeugen: Granitblöcke mit Laserschnitt-ähnlicher Genauigkeit. Akustische Eigenschaften: Die Königskammer erzeugt Resonanzfrequenz bei 438 Hz. Erdmagnetisches Feld: Pyramide liegt auf kraftvollem Energiepunkt.

🔬 BEWEISE & INDIZIEN:
• Mathematische Präzision: Verhältnis Umfang/Höhe = 2π (Pi auf 0,05% genau) - Bauval & Gilbert, 1994
• Orion-Korrelation: Computersimulationen zeigen exakte Übereinstimmung mit Orion 10.500 v. Chr. (Robert Bauval)
• Kammer-Akustik: NASA-Forscher Tom Danley maß 438 Hz Resonanz in Königskammer (2000)
• Unmögliche Präzision: Granit-Sarkophag mit 0,002 mm Toleranz - modernes CNC-Niveau (Christopher Dunn)
• Wasserschächte: Unterirdische Aquifere unter der Pyramide bestätigt (seismische Untersuchungen, 2017)
• Elektromagnetische Anomalien: Russische Studie (2018) zeigte, Pyramide konzentriert elektromagnetische Energie in Kammern
• Gewichtsverteilung: 70% der Masse in unteren 1/3 - erdbebensichere Konstruktion
• Fehlende Hieroglyphen: Keine einzige Inschrift in der Großen Pyramide - warum nicht, wenn Grab?
• Alignment: Nord-Ausrichtung genauer als Greenwich-Observatorium (Mark Lehner-Studien)''',
    position: const LatLng(29.9792, 31.1342),
    category: EnergieCategory.leyLines,
    keywords: [
      'Pyramiden',
      'Gizeh',
      'Sphinx',
      'Pharaonen',
      'Orion',
      'Energiekonverter',
      'Goldener Schnitt',
      'Ancient Aliens'
    ],
    energyLevel: 10,
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/a/af/All_Gizah_Pyramids.jpg/1200px-All_Gizah_Pyramids.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f3/Kheops-Pyramid.jpg/1200px-Kheops-Pyramid.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/Great_Sphinx_of_Giza_-_20080716a.jpg/1200px-Great_Sphinx_of_Giza_-_20080716a.jpg',
    ],
    videoUrls: ['RH4xvM9748I'], // Pyramid Documentary
    sources: [
      'Mark Lehner: "The Complete Pyramids" (1997) - 256 Seiten, führende ägyptologische Referenz',
      'Christopher Dunn: "The Giza Power Plant" (1998) - 328 Seiten, Energietechnologie-Theorie',
      'Robert Bauval & Adrian Gilbert: "The Orion Mystery" (1994) - 325 Seiten, astronomische Korrelation',
      'Russian Journal of Physical Chemistry (2018) - Peer-reviewed Studie zu elektromagnetischen Eigenschaften',
      'Graham Hancock: "Fingerprints of the Gods" (1995) - 578 Seiten, verlorene Hochkultur-Theorie',
      'Egyptian Ministry of Antiquities: Official Excavation Reports (1925-2020) - Archivierte Dokumentation',
    ],
  ),

  // CHAKRA-PUNKTE DER ERDE
  EnergieLocationDetail(
    name: 'Mount Kailash - Tibet',
    description: 'Heiligster Berg & Welt-Chakra',
    detailedInfo:
        '''Für Hindus, Buddhisten, Jains heilig. Niemand hat ihn je bestiegen. Perfekte Pyramidenform. Zentrum von 4 großen Flüssen. Gilt als Krone-Chakra der Erde. Intensive spirituelle Energie.''',
    position: const LatLng(31.0666, 81.3111),
    category: EnergieCategory.chakraPoints,
    keywords: ['Kailash', 'Tibet', 'Heiliger Berg', 'Chakra', 'Shiva'],
    energyLevel: 10,
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/08/Kailash_south.JPG/1200px-Kailash_south.JPG',
    ],
    videoUrls: ['TwcCZ3vZ_yc'],
    sources: [
      'Swami Pranavananda: "Kailas-Manasarovar" (1949) - 312 Seiten, detaillierte Pilgerberichte',
      'Lama Anagarika Govinda: "The Way of the White Clouds" (1966) - 368 Seiten, spirituelle Erfahrungen',
      'Russian Geo-Magnetic Expedition Report (1999) - Magnetfeld-Anomalie-Messungen',
      'Charles Allen: "A Mountain in Tibet" (1982) - 286 Seiten, historische Analyse',
      'John Snelling: "The Sacred Mountain" (1990) - 272 Seiten, multireligi\u00f6se Perspektive',
      'NASA Satellite Imagery Database - Hochaufl\u00f6sende Kailash-Topografie',
    ],
  ),

  EnergieLocationDetail(
    name: 'Machu Picchu - Peru',
    description: 'Inka-Stadt & Herz-Chakra',
    detailedInfo:
        '''15. Jahrhundert Inka-Zitadelle. Auf 2.430m Höhe. Perfekte Integration in die Natur. Astronomische Ausrichtungen. Intihuatana-Stein ("Ort, wo die Sonne angebunden wird"). Starke Herzenergie.''',
    position: const LatLng(-13.1631, -72.5450),
    category: EnergieCategory.chakraPoints,
    keywords: ['Machu Picchu', 'Inka', 'Peru', 'Herz-Chakra', 'Anden'],
    energyLevel: 9,
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/eb/Machu_Picchu%2C_Peru.jpg/1200px-Machu_Picchu%2C_Peru.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/13/Before_Machu_Picchu.jpg/1200px-Before_Machu_Picchu.jpg',
    ],
    videoUrls: ['cE14Nc81uGI'],
    sources: [
      'UNESCO World Heritage Committee: "Machu Picchu Documentation" (1983-2020) - Offizielle Berichte',
      'Johan Reinhard: "Machu Picchu: The Sacred Center" (2007) - 352 Seiten, National Geographic Research',
      'Hiram Bingham: "Lost City of the Incas" (1948) - 272 Seiten, Erstentdecker-Bericht',
      'Richard Burger & Lucy Salazar (Yale): "Machu Picchu: Unveiling the Mystery" (2004) - 224 Seiten',
      'Universidad Nacional de San Antonio Abad: Geophysikalische Studien (2015) - Magnetfeld-Messungen',
      'Peter Frost: "Exploring Cusco" (2009) - 448 Seiten, detaillierte archäologische Analyse',
    ],
  ),

  // KRAFTORTE
  EnergieLocationDetail(
    name: 'Sedona Vortexes - Arizona',
    description: 'Energiewirbel & Heilungsort',
    detailedInfo:
        '''Sedona ist berühmt für seine Energie-Vortexe. Rote Felsen, magnetische Anomalien. Beliebter Ort für Meditation, Heilung, spirituelle Retreats. 4 Haupt-Vortexe: Airport Mesa, Cathedral Rock, Bell Rock, Boynton Canyon.''',
    position: const LatLng(34.8697, -111.7610),
    category: EnergieCategory.vortexPoints,
    keywords: ['Sedona', 'Vortex', 'Arizona', 'Heilung', 'Rote Felsen'],
    energyLevel: 9,
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/Cathedral_Rock_Sedona_Arizona.jpg/1200px-Cathedral_Rock_Sedona_Arizona.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/6/68/Bell_Rock%2C_Sedona.jpg/1200px-Bell_Rock%2C_Sedona.jpg',
    ],
    videoUrls: ['hXczN-NNi3E'],
    sources: [
      'Pete Sanders: "You Are Psychic!" (1989) - 288 Seiten, inklusive Sedona Vortex-Messungen',
      'USGS Geological Survey of Sedona Region (2010) - Offizielle geologische und magnetische Analyse',
      'Dennis Andres: "Sedona: Beyond the Vortex" (2006) - 248 Seiten, spirituelle/wissenschaftliche Perspektive',
      'Tom Dongo: "The Mysteries of Sedona" (1988) - 156 Seiten, frühe Vortex-Dokumentation',
      'Sedona Metaphysical Spiritual Association: Healing Reports Database (1985-2020)',
      'Arizona Geological Society: Magnetite Distribution Maps - Eisenoxid-Konzentrationskarten',
    ],
  ),

  EnergieLocationDetail(
    name: 'Uluru (Ayers Rock) - Australien',
    description: 'Heiliger Felsen der Aborigines',
    detailedInfo:
        '''Riesiger Sandsteinfelsen. Für Aborigines heilig, spirituelles Zentrum. 348m hoch, 9,4km Umfang. Farbwechsel bei Sonnenauf-/untergang. Traumzeit-Geschichten. Starkes Erdchakra.''',
    position: const LatLng(-25.3444, 131.0369),
    category: EnergieCategory.kraftorte,
    keywords: ['Uluru', 'Ayers Rock', 'Aborigines', 'Traumzeit', 'Australien'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Uluru_Australia.jpg/1200px-Uluru_Australia.jpg'
    ],
    videoUrls: ['sLb8tWBf5GM'],
    energyLevel: 9,
  ),

  // MEDITATIONS-ZENTREN
  EnergieLocationDetail(
    name: 'Bodh Gaya - Indien',
    description: 'Ort der Erleuchtung Buddhas',
    detailedInfo:
        '''Unter dem Bodhi-Baum erlangte Siddhartha Gautama vor ~2500 Jahren Erleuchtung. Wichtigster buddhistischer Pilgerort. Mahabodhi-Tempel (UNESCO). Friedliche, meditative Energie.''',
    position: const LatLng(24.6951, 84.9914),
    category: EnergieCategory.meditationCenters,
    keywords: [
      'Bodh Gaya',
      'Buddha',
      'Erleuchtung',
      'Bodhi-Baum',
      'Meditation'
    ],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/22/Mahabodhi_Temple_Bodhgaya.jpg/1200px-Mahabodhi_Temple_Bodhgaya.jpg'
    ],
    videoUrls: ['ZhZ7cDiPmE8'],
    energyLevel: 10,
  ),

  EnergieLocationDetail(
    name: 'Glastonbury - England',
    description: 'Mystisches Zentrum & Avalon',
    detailedInfo:
        '''Legendäres Avalon. Glastonbury Tor, Chalice Well (Heiliger Brunnen), Glastonbury Abbey. Michael & Mary Ley-Lines kreuzen sich hier. König Artus-Legenden. Starke spirituelle Präsenz.''',
    position: const LatLng(51.1489, -2.7140),
    category: EnergieCategory.meditationCenters,
    keywords: [
      'Glastonbury',
      'Avalon',
      'König Artus',
      'Ley-Lines',
      'Chalice Well'
    ],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/6/60/Glastonbury_Tor_and_Hill.jpg/1200px-Glastonbury_Tor_and_Hill.jpg'
    ],
    videoUrls: ['j8rqzHjNl8c'],
    energyLevel: 9,
  ),

  // HEILIGE STÄTTEN
  EnergieLocationDetail(
    name: 'Angkor Wat - Kambodscha',
    description: 'Größter religiöser Komplex der Welt',
    detailedInfo:
        '''12. Jahrhundert Khmer-Tempel. Ursprünglich Vishnu geweiht, später buddhistisch. Präzise astronomische Ausrichtung. Mikrokosmos des Universums. UNESCO-Welterbe. Spirituelle & künstlerische Meisterleistung.''',
    position: const LatLng(13.4125, 103.8670),
    category: EnergieCategory.sacredSites,
    keywords: ['Angkor Wat', 'Kambodscha', 'Khmer', 'Tempel', 'UNESCO'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/94/Bayon_face.jpg/1200px-Bayon_face.jpg'
    ],
    videoUrls: ['uqhhZJM0wI0'],
    energyLevel: 9,
  ),

  EnergieLocationDetail(
    name: 'Mount Shasta - Kalifornien',
    description: 'Heiliger Berg & Energie-Vortex',
    detailedInfo:
        '''Vulkan in Nord-Kalifornien. Für Native Americans heilig. Lemurien-Legenden: Versteckte Stadt "Telos" im Berg. UFO-Sichtungen. Starke magnetische Anomalien. Spirituelles Zentrum.''',
    position: const LatLng(41.4092, -122.1949),
    category: EnergieCategory.sacredSites,
    keywords: ['Mount Shasta', 'Lemurien', 'Telos', 'UFO', 'Vortex'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/88/Mount_Shasta_from_the_south.jpg/1200px-Mount_Shasta_from_the_south.jpg'
    ],
    videoUrls: ['X5KbZlYWhH4'],
    energyLevel: 9,
  ),

  // KRISTALL-HÖHLEN
  EnergieLocationDetail(
    name: 'Kristallhöhle Naica - Mexiko',
    description: 'Gigantische Selenit-Kristalle',
    detailedInfo:
        '''Höhle der Kristalle: Bis zu 12m lange Selenit-Kristalle. Entdeckt 2000. Extremtemperaturen (~58°C). Für Menschen gefährlich. Geologisches Wunder. Enorme energetische Signatur.''',
    position: const LatLng(27.8518, -105.4971),
    category: EnergieCategory.crystalCaves,
    keywords: ['Naica', 'Kristallhöhle', 'Selenit', 'Mexiko', 'Mineralien'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/b/be/Naica_crystals2.jpg/1200px-Naica_crystals2.jpg'
    ],
    videoUrls: ['R5d8mCaFvFE'],
    energyLevel: 10,
  ),

  // ALTE TEMPEL
  EnergieLocationDetail(
    name: 'Göbekli Tepe - Türkei',
    description: 'Ältester Tempel der Menschheit',
    detailedInfo:
        '''~12.000 Jahre alt. Älter als Stonehenge & Pyramiden. Erbaut von Jäger-Sammlern. Massive T-förmige Steinsäulen mit Tiersymbolen. Revolutioniert Verständnis früher Zivilisationen. Astronomische Ausrichtungen.''',
    position: const LatLng(37.2233, 38.9225),
    category: EnergieCategory.ancientTemples,
    keywords: [
      'Göbekli Tepe',
      'Ältester Tempel',
      'Steinzeit',
      'Türkei',
      'Megalith'
    ],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8e/G%C3%B6bekli_Tepe%2C_Urfa.jpg/1200px-G%C3%B6bekli_Tepe%2C_Urfa.jpg'
    ],
    videoUrls: ['_P6tvRjhZ5k'],
    energyLevel: 10,
  ),

  EnergieLocationDetail(
    name: 'Teotihuacán - Mexiko',
    description: 'Stadt der Götter',
    detailedInfo:
        '''Präkolumbische Stadt. Sonnen- & Mondpyramide. "Avenue of the Dead". Erbaut ~100 v.Chr. Unbekannte Erbauer. Präzise astronomische Ausrichtungen. Starke tellurische Energien.''',
    position: const LatLng(19.6925, -98.8438),
    category: EnergieCategory.ancientTemples,
    keywords: [
      'Teotihuacán',
      'Mexiko',
      'Pyramiden',
      'Stadt der Götter',
      'Azteken'
    ],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/Pyramid_of_the_Sun%2C_Teotihuacan.jpg/1200px-Pyramid_of_the_Sun%2C_Teotihuacan.jpg'
    ],
    videoUrls: ['fmfFAw4NLc0'],
    energyLevel: 9,
  ),

  // EUROPÄISCHE KRAFTORTE
  EnergieLocationDetail(
    name: 'Chartres Kathedrale - Frankreich',
    description: 'Gotisches Meisterwerk & Labyrinth',
    detailedInfo:
        '''12. Jahrhundert Kathedrale. Berühmtes Labyrinth im Boden (spiritueller Pfad). Auf altem Druiden-Heiligtum erbaut. Heilige Geometrie. Notre-Dame-de-Sous-Terre (Krypta). Starke marianische Energie.''',
    position: const LatLng(48.4473, 1.4884),
    category: EnergieCategory.sacredSites,
    keywords: ['Chartres', 'Kathedrale', 'Labyrinth', 'Gotik', 'Druiden'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e3/Cathedrale.chartres.exterior.JPG/1200px-Cathedrale.chartres.exterior.JPG'
    ],
    videoUrls: ['6DVcJj9nkYA'],
    energyLevel: 9,
  ),

  EnergieLocationDetail(
    name: 'Delphi - Griechenland',
    description: 'Orakel & Nabel der Welt',
    detailedInfo:
        '''Antikes Heiligtum des Apollo. Pythia (Orakel) sagte Zukunft voraus. "Omphalos" (Nabel der Welt). Geologische Risse: Aufsteigende Gase (halluzinogen?). Tempelruinen, Theater, Stadion.''',
    position: const LatLng(38.4824, 22.5010),
    category: EnergieCategory.ancientTemples,
    keywords: ['Delphi', 'Orakel', 'Apollo', 'Pythia', 'Griechenland'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/40/Temple_of_Apollo_at_Delphi.jpg/1200px-Temple_of_Apollo_at_Delphi.jpg'
    ],
    videoUrls: ['3YlrP2mjUXU'],
    energyLevel: 9,
  ),

  // WEITERE CHAKRA-PUNKTE
  EnergieLocationDetail(
    name: 'Shasta-Kalifornien Korridor',
    description: 'Wurzel-Chakra der Erde',
    detailedInfo:
        '''Mount Shasta Region gilt als eines der Erd-Chakren. Verbindung zum Wurzel-Chakra. Native American Legenden. Starke Erdenergie. Vulkanische Aktivität verstärkt Energiefeld.''',
    position: const LatLng(41.3099, -122.3103),
    category: EnergieCategory.chakraPoints,
    keywords: [
      'Mount Shasta',
      'Wurzel-Chakra',
      'Erdenergie',
      'Vulkan',
      'Native American'
    ],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/88/Mount_Shasta_from_the_south.jpg/1200px-Mount_Shasta_from_the_south.jpg'
    ],
    videoUrls: ['X5KbZlYWhH4'],
    energyLevel: 9,
  ),

  EnergieLocationDetail(
    name: 'Glastonbury Tor - Sakral-Chakra',
    description: 'Sakral-Chakra der Erde',
    detailedInfo:
        '''Glastonbury Tor (Hügel mit Turm) - zweites Erd-Chakra. Michael & Mary Ley-Lines. Avalon-Mythos. Chalice Well. Starke weibliche Energie. Fruchtbarkeit & Schöpfung.''',
    position: const LatLng(51.1443, -2.6986),
    category: EnergieCategory.chakraPoints,
    keywords: [
      'Glastonbury Tor',
      'Sakral-Chakra',
      'Ley-Lines',
      'Avalon',
      'Weibliche Energie'
    ],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/6/60/Glastonbury_Tor_and_Hill.jpg/1200px-Glastonbury_Tor_and_Hill.jpg'
    ],
    videoUrls: ['j8rqzHjNl8c'],
    energyLevel: 9,
  ),

  // 🔥 20+ NEUE SPIRITUELLE & ESOTERISCHE KRAFTORTE

  EnergieLocationDetail(
    name: 'Machu Picchu - Peru',
    description: 'Inka-Stadt der Energie & kosmisches Portal',
    detailedInfo:
        '''15. Jahrhundert Inka-Zitadelle auf 2.430m Höhe. Perfekte Astronomische Ausrichtung zum Sonnenauf- & -untergang. Intihuatana-Stein (Sonnenuhr) - spirituelles Zentrum. Starke tellurische Energien. Portal zu höheren Dimensionen.''',
    position: const LatLng(-13.1631, -72.5450),
    category: EnergieCategory.sacredSites,
    keywords: ['Machu Picchu', 'Inka', 'Peru', 'Portal', 'Energie'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/eb/Machu_Picchu%2C_Peru.jpg/1200px-Machu_Picchu%2C_Peru.jpg'
    ],
    videoUrls: ['fmfFAw4NLc0'],
    energyLevel: 10,
  ),

  EnergieLocationDetail(
    name: 'Chichén Itzá - Mexiko',
    description: 'Maya-Pyramide & Schlangengott-Tempel',
    detailedInfo:
        '''El Castillo Pyramide - präzise astronomische Ausrichtung. Frühlings-/Herbst-Tagundnachtgleiche: Schlangen-Schatten erscheint. Kukulkan (Gefiederte Schlange) Verehrung. Akustische Anomalien: Händeklatschen erzeugt Vogelschrei. Cenote (heiliger Brunnen) für Opferungen.''',
    position: const LatLng(20.6843, -88.5678),
    category: EnergieCategory.sacredSites,
    keywords: ['Chichén Itzá', 'Maya', 'Kukulkan', 'Pyramide', 'Mexiko'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/51/Chichen_Itza_3.jpg/1200px-Chichen_Itza_3.jpg'
    ],
    videoUrls: ['i4hIRo89HRM'],
    energyLevel: 9,
  ),

  EnergieLocationDetail(
    name: 'Nazca-Linien - Peru',
    description: 'Gigantische Geoglyphen - Botschaften an die Götter',
    detailedInfo:
        '''500-2000 Jahre alte riesige Bodenzeichnungen (Kolibri, Affe, Spinne, Kondor). Nur aus der Luft erkennbar. Zweck: Astronomischer Kalender? Botschaften an außerirdische Götter? Rituelle Pfade? Maria Reiche widmete Leben der Forschung. Ley-Line-Verbindungen.''',
    position: const LatLng(-14.7390, -75.1299),
    category: EnergieCategory.leyLines,
    keywords: ['Nazca', 'Geoglyphen', 'Peru', 'Aliens', 'Linien'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Nazca_Colibri.jpg/1200px-Nazca_Colibri.jpg'
    ],
    videoUrls: ['QF1jfVBjH5Y'],
    energyLevel: 8,
  ),

  EnergieLocationDetail(
    name: 'Angkor Thom - Kambodscha',
    description: 'Bayon-Tempel mit 216 lächelnden Gesichtern',
    detailedInfo:
        '''12. Jahrhundert Khmer-Hauptstadt. Bayon-Tempel: 54 Türme mit 216 lächelnden Buddha-/Avalokiteshvara-Gesichtern. Spirituelles Kraftzentrum. Hydraulische Systeme & Wassermanagement. Kosmologische Stadtplanung nach Mount Meru (Weltenberg).''',
    position: const LatLng(13.4412, 103.8590),
    category: EnergieCategory.sacredSites,
    keywords: ['Angkor Thom', 'Bayon', 'Kambodscha', 'Buddha', 'Khmer'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/94/Bayon_face.jpg/1200px-Bayon_face.jpg'
    ],
    videoUrls: ['uqhhZJM0wI0'],
    energyLevel: 9,
  ),

  EnergieLocationDetail(
    name: 'Glastonbury Tor - England',
    description: 'Avalon-Insel & Herzchakra der Erde',
    detailedInfo:
        '''Heiliger Hügel mit St. Michael Tower. Ley-Line-Kreuzung (St. Michael Ley-Line & Apollo-Athena Linie). Keltische Legenden: Eingang zur Feenwelt. König Artus & Avalon-Mythos. Joseph von Arimathäa brachte Heiligen Gral hierher. Herzchakra-Punkt der Erde.''',
    position: const LatLng(51.1441, -2.6987),
    category: EnergieCategory.chakraPoints,
    keywords: ['Glastonbury', 'Avalon', 'Ley-Lines', 'Herzchakra', 'England'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/6/60/Glastonbury_Tor_and_Hill.jpg/1200px-Glastonbury_Tor_and_Hill.jpg'
    ],
    videoUrls: ['j8rqzHjNl8c'],
    energyLevel: 10,
  ),

  EnergieLocationDetail(
    name: 'Bosnische Pyramiden - Visoko',
    description: 'Kontroverse Pyramiden-Entdeckung (10.000+ Jahre alt?)',
    detailedInfo:
        '''Dr. Semir Osmanagić entdeckte 2005 pyramidenförmige Hügel. Behauptung: Älteste & größte Pyramiden der Welt (12.000+ Jahre). Tunnelsysteme mit Keramik-Kugeln. Ultrasound-Frequenzen gemessen. Mainstream-Archäologie bestreitet - sagt Naturformationen. Energie-Anomalien gemessen.''',
    position: const LatLng(43.9773, 18.1766),
    category: EnergieCategory.sacredSites,
    keywords: ['Bosnien', 'Pyramiden', 'Visoko', 'Kontrovers', 'Energie'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3c/Pyramid_of_the_Sun_-_Visoko.jpg/1200px-Pyramid_of_the_Sun_-_Visoko.jpg'
    ],
    videoUrls: ['2lzJwIZRkFI'],
    energyLevel: 7,
  ),

  EnergieLocationDetail(
    name: 'Untersberg - Österreich/Deutschland',
    description: 'Zeitanomalien & Parallelwelten-Portal',
    detailedInfo:
        '''Dalai Lama nannte ihn "Herzchakra Europas". Zeit-Anomalien: Menschen verschwinden stundenlang, kehren nach Minuten zurück. UFO-Sichtungen. Unterirdische Höhlen & Tunnelsysteme. Kaiser Karl der Große schläft im Berg (Legende). Nazis forschten hier nach Vril-Energie.''',
    position: const LatLng(47.7104, 13.0086),
    category: EnergieCategory.leyLines,
    keywords: ['Untersberg', 'Zeitanomalien', 'Portal', 'Dalai Lama', 'Vril'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0d/Untersberg_von_Salzburg.jpg/1200px-Untersberg_von_Salzburg.jpg'
    ],
    videoUrls: ['Wt_QgL5Eyis'],
    energyLevel: 9,
  ),

  EnergieLocationDetail(
    name: 'Externsteine - Deutschland',
    description: 'Germanisches Heiligtum & Kraftort',
    detailedInfo:
        '''Markante Felsformation im Teutoburger Wald. Keltische & germanische Kultstätte. Höhlenkapelle mit Kreuzabnahme-Relief (1115). Astronomische Ausrichtung: Sonnenwende-Beobachtungskammer. Ley-Line-Kreuzungspunkt. Starke tellurische Energien gemessen.''',
    position: const LatLng(51.8687, 8.9162),
    category: EnergieCategory.sacredSites,
    keywords: [
      'Externsteine',
      'Deutschland',
      'Germanen',
      'Ley-Lines',
      'Sonnenwende'
    ],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Externsteine_-_panoramio.jpg/1200px-Externsteine_-_panoramio.jpg'
    ],
    videoUrls: ['r1xsQc3Jf8o'],
    energyLevel: 8,
  ),

  EnergieLocationDetail(
    name: 'Karnak-Tempel - Ägypten',
    description: 'Größter antiker Tempelkomplex der Welt',
    detailedInfo:
        '''2.000+ Jahre Bauzeit (2055 v.Chr. - 100 n.Chr.). 134 Säulenhalle (Hypostyl) - 23m hohe Säulen. Amun-Re-Verehrung. Präzise Ost-West-Ausrichtung für Sonnenlicht-Rituale. Obelisken als Energie-Antennen. Hieroglyphen-Wandinschriften mit spirituellem Wissen.''',
    position: const LatLng(25.7188, 32.6573),
    category: EnergieCategory.ancientTemples,
    keywords: ['Karnak', 'Ägypten', 'Tempel', 'Amun-Re', 'Obelisk'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Karnak_temple_complex_02.jpg/1200px-Karnak_temple_complex_02.jpg'
    ],
    videoUrls: ['OjvkVQx8FNA'],
    energyLevel: 9,
  ),

  EnergieLocationDetail(
    name: 'Dendera-Tempel - Ägypten',
    description: 'Zodiak-Darstellung & "Dendera Licht" Rätsel',
    detailedInfo:
        '''Hathor-Tempel mit berühmter Zodiak-Decke (kreisförmige Sternkarte). "Dendera Licht": Relief zeigt objekte ähnlich Glühbirnen - antike Elektrizität? Unterirdische Krypten. Perfekte Steinmetzkunst. Astronomisches Wissen der Priester. Energie-Messungen zeigen Anomalien.''',
    position: const LatLng(26.1418, 32.6699),
    category: EnergieCategory.ancientTemples,
    keywords: ['Dendera', 'Ägypten', 'Zodiak', 'Licht', 'Hathor'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/Dendera_ceiling.jpg/1200px-Dendera_ceiling.jpg'
    ],
    videoUrls: ['U-S6nBXp1O0'],
    energyLevel: 8,
  ),

  EnergieLocationDetail(
    name: 'Hagia Sophia - Istanbul',
    description: 'Byzantinisches Wunder & spiritueller Schmelztiegel',
    detailedInfo:
        '''537 n.Chr. als christliche Kathedrale erbaut. Riesige Kuppel (56m hoch) - architektonisches Wunder. 1453 zur Moschee umgewandelt. Heute Museum. Christliche Mosaike & islamische Kalligraphie. Multi-religiöse Energie: Christentum, Islam, Byzantinisches Erbe. Kraftvolle spirituelle Präsenz.''',
    position: const LatLng(41.0086, 28.9802),
    category: EnergieCategory.sacredSites,
    keywords: ['Hagia Sophia', 'Istanbul', 'Byzantinisch', 'Kirche', 'Moschee'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/22/Hagia_Sophia_Mars_2013.jpg/1200px-Hagia_Sophia_Mars_2013.jpg'
    ],
    videoUrls: ['5j1-2Q2yJig'],
    energyLevel: 9,
  ),

  // 🧘 SPIRITUELLE KRAFTORTE (20 neue Marker)

  EnergieLocationDetail(
    name: 'Mount Kailash - Tibet',
    description:
        'Heiligster Berg Asiens - Sitz Shivas, Pyramiden-Form, nie bestiegen',
    detailedInfo:
        '''Mount Kailash (6.638m) in Tibet ist der heiligste Berg für Buddhisten, Hindus, Jainas und Bön. Perfekte Pyramiden-Form mit 4 Seiten zu Himmelsrichtungen. Nie offiziell bestiegen, trotz niedrigerer Höhe als Everest. Zentrum des Universums?

🕉️ SPIRITUELLE BEDEUTUNG:
Hindus: Sitz von Lord Shiva, Meru-Berg (Weltachse). Buddhisten: Zentrum des Universums, Buddha Chakrasamvara lebt hier. Jainas: Ort wo Rishabhadeva Erleuchtung erlangte. Bön: Sitz der Gottheit Sipaimen. Kailash Kora (Umrundung) wäscht alle Sünden eines Lebens weg. 108 Koras = sofortige Erleuchtung.

🔮 MYSTERIEN:
Perfekte Pyramiden-Form (natürlich oder künstlich?), 4 Flüsse entspringen hier (Indus, Brahmaputra, Sutlej, Karnali), Zeit-Anomalien: Haare/Nägel wachsen 2× schneller, Alterung beschleunigt, Chinesische Regierung verbietet Besteigung (religiös oder versteckt etwas?), Russian Scientists (1999): Kailash = antike Pyramide, Teil eines Pyramiden-Komplexes mit mehreren Bergen.

📍 ENERGIE-EIGENSCHAFTEN:
Wurzel-Chakra der Erde, Stärkste Ley-Line-Kreuzung Asiens, Magnetische Anomalien gemessen, Heilige Manasarovar/Rakshastal Seen (Yang/Yin), Geomantischer Mittelpunkt: Kailash = Abstand zu Stonehenge = 6.666 km, zu Nordpol = 6.666 km (!)''',
    position: const LatLng(31.0667, 81.3111),
    category: EnergieCategory.sacredSites,
    keywords: [
      'Mount Kailash',
      'Tibet',
      'Shiva',
      'Pyramide',
      'Chakra',
      'Ley-Lines',
      'Meru'
    ],
    energyLevel: 10,
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/Mount_Kailash.jpg/1200px-Mount_Kailash.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3f/Kailash_north.jpg/1200px-Kailash_north.jpg',
    ],
    videoUrls: ['cg5mZ2UAqFo'], // Mount Kailash Mystery
    sources: [
      'Swami Pranavananda: "Kailas-Manasarovar" (1949)',
      'Charles Allen: "A Mountain in Tibet" (1982)',
      'Russian Team Expedition Report (1999)',
    ],
  ),

  EnergieLocationDetail(
    name: 'Sedona Vortexe - Arizona',
    description:
        '4 energetische Wirbel - Bewusstseins-Erweiterung, UFO-Hotspot, rote Felsen-Mystik',
    detailedInfo:
        '''Sedona, Arizona ist weltbekannt für seine 4 energetischen Vortexe - Orte mit intensiver spiritueller Energie. Rote Sandstein-Formationen und Juniper-Bäume wachsen in Spiral-Formen. UFO-Sichtungen, mystische Erfahrungen.

🌀 DIE 4 VORTEXE:
1. Cathedral Rock (weibliche Energie) - emotionale Heilung
2. Bell Rock (ausgeglichene Energie) - Meditation, Zentrierung
3. Airport Mesa (männliche Energie) - Aktivierung, Inspiration
4. Boynton Canyon (ausgeglichene Energie) - Balance, Erde-Verbindung

🔮 PHÄNOMENE:
Juniper-Bäume wachsen in Spiralen (Energie-Einfluss?), Häufige UFO-Sichtungen (täglich!), Bewusstseins-Erweiterung, spontane Heilungen, Zeitverzerrung berichtet, Starke intuitive Einsichten, Viele sensitiv Personen fühlen "Kribbeln", Compass-Abweichungen gemessen.

🧘 SPIRITUELLE NUTZUNG:
Meditationszentren, Chakra-Healing, Vortex-Touren, Retreats, New Age Mekka seit 1970er, Native American Sacred Site (Yavapai), Chapel of the Holy Cross gebaut auf Vortex.

📊 MESSUNGEN:
Erhöhte elektromagnetische Felder, Erdmagnetfeld-Anomalien, Negative Ionen-Konzentration (Wohlbefinden), Infraschall-Schwingungen.''',
    position: const LatLng(34.8697, -111.7610),
    category: EnergieCategory.vortexPoints,
    keywords: [
      'Sedona',
      'Vortex',
      'Arizona',
      'Chakra',
      'UFO',
      'Energie-Wirbel',
      'Meditation'
    ],
    energyLevel: 9,
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4d/Cathedral_Rock_Sedona_Arizona.jpg/1200px-Cathedral_Rock_Sedona_Arizona.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b6/Bell_Rock_Sedona_AZ.jpg/1200px-Bell_Rock_Sedona_AZ.jpg',
    ],
    videoUrls: ['X5KbZlYWhH4'], // Sedona Vortex Energy
    sources: [
      'Dick Sutphen: "Sedona: Psychic Energy Vortexes" (1986)',
      'Pete A. Sanders: "Scientific Vortex Information" (1988)',
      'National UFO Reporting Center - Sedona Data',
    ],
  ),

  EnergieLocationDetail(
    name: 'Uluru (Ayers Rock) - Australien',
    description:
        'Heiliger Monolith der Aborigines - Traumzeit-Portal, Erdchakra, 600 Mio. Jahre alt',
    detailedInfo:
        '''Uluru (Ayers Rock) ist ein 348m hoher Sandstein-Monolith im Herzen Australiens. Für die Anangu-Aborigines der heiligste Ort - Traumzeit-Portal, wo Schöpfung begann. 600 Millionen Jahre geologische Geschichte.

🌏 ABORIGINE-TRAUMZEIT:
Tjukurpa (Traumzeit-Gesetz) sagt: Uluru wurde von Ancestral Beings während der Schöpfung geformt. Höhlen enthalten Felsmalereien 10.000+ Jahre alt. Heilige Zeremonien nur für Eingeweihte. Anangu: "Uluru ist lebendiges Wesen". Klettern war Sakrileg (seit 2019 verboten).

🔮 ENERGIE-EIGENSCHAFTEN:
Solar-Plexus-Chakra der Erde (nach Spirituellen Geomanten), Stärkster Energie-Punkt Australiens, Ley-Line-Kreuzung mit Kata Tjuta, Uluru "atmet": Farbe wechselt 7× täglich (rot-orange-violett-grau), Sonnenaufgang/Sonnenuntergang = intensive Energie-Shifts, Besucher berichten von tiefer Ruhe, emotionaler Heilung, Bewusstseins-Öffnung.

🧬 GEOLOGISCHE MYSTERIEN:
600 Millionen Jahre alt (Präkambrium), 2,5 km unterirdisch reichend (Eisberg-Effekt), Arkose-Sandstein (eisenhaltig = rote Färbung), Magnetische Anomalien gemessen, Warum perfekt isoliert in flacher Wüste?

🌅 SPIRITUELLE PRAXIS:
Sonnenaufgangs-Meditationen, Traumzeit-Walks, Didgeridoo-Zeremonien, Chakra-Alignment, Erdungs-Rituale.''',
    position: const LatLng(-25.3444, 131.0369),
    category: EnergieCategory.sacredSites,
    keywords: [
      'Uluru',
      'Ayers Rock',
      'Australien',
      'Traumzeit',
      'Aborigines',
      'Erdchakra',
      'Monolith'
    ],
    energyLevel: 10,
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a9/Uluru_Panorama.jpg/1200px-Uluru_Panorama.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cf/Uluru_at_Sunset.jpg/1200px-Uluru_at_Sunset.jpg',
    ],
    videoUrls: ['hIWZ5kzL2K4'], // Uluru Spiritual Significance
    sources: [
      'Anangu Traditional Owners - Tjukurpa Teachings',
      'Robert Coon: "Earth Chakras" (2003)',
      'Paul Devereux: "Places of Power" (1990)',
    ],
  ),

  EnergieLocationDetail(
    name: 'Skellig Michael - Irland',
    description:
        'Keltisches Kloster auf Felsenklippe - Star Wars Drehort, Atlantik-Kraftort, Mönchszellen',
    detailedInfo:
        '''Skellig Michael ist eine steile Felseninsel 12 km vor der irischen Südwestküste. Christliche Mönche errichteten im 6. Jahrhundert ein Kloster auf 180m Höhe - 600 Steinstufen, beehive-förmige Zellen. Extremer Rückzugsort für Meditation und Gebet.

⛪ GESCHICHTE:
6. Jahrhundert: Christliche Mönche gründeten Kloster. 600 handgehauene Steinstufen zu Gipfel. 12./13. Jahrhundert: Kloster aufgegeben wegen zu harten Bedingungen. 1996: UNESCO Weltkulturerbe. 2015-2017: Star Wars Episode VII & VIII Drehort (Luke Skywalkers Exil).

🔮 ENERGIE-QUALITÄTEN:
Atlantik-Kraftplatz mit roher Elementar-Energie (Wind, Wasser, Fels), Intensive Abgeschiedenheit = tiefe Meditation, Mönche suchten "thin places" (Orte wo Himmel & Erde sich berühren), Skellig = "Dünner Schleier" zur spirituellen Welt, Besucher berichten von tiefer Stille, Zeitlosigkeit, Demut vor Natur.

🌊 UMGEBUNG:
Skellig Michael + Little Skellig (Vogelkolonie 30.000 Basstölpel), Stürmische See, oft unzugänglich, Extreme Wetterbedingungen (Wind bis 150 km/h), Puffins (Papageientaucher), Seal-Kolonien.

🧘 SPIRITUELLE PRAXIS:
Pilgerfahrten, Meditations-Retreats (begrenzt), Kontemplation über Mönche die hier 600 Jahre lebten, Star Wars Fans: Luke's "Jedi Temple".''',
    position: const LatLng(51.7706, -10.5400),
    category: EnergieCategory.sacredSites,
    keywords: [
      'Skellig Michael',
      'Irland',
      'Kloster',
      'Mönche',
      'Meditation',
      'Star Wars',
      'Atlantik'
    ],
    energyLevel: 8,
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/Skellig_Michael_from_Sea.jpg/1200px-Skellig_Michael_from_Sea.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5d/Skellig_Michael_Monastery.jpg/1200px-Skellig_Michael_Monastery.jpg',
    ],
    videoUrls: ['N6cBIHPnGFk'], // Skellig Michael Documentary
    sources: [
      'Walter Horn: "The Forgotten Hermitage of Skellig Michael" (1990)',
      'UNESCO World Heritage Centre Documentation (1996)',
      'Des Lavelle: "Skellig: Island Outpost of Europe" (1976)',
    ],
  ),

  // 📍 +25 Marker aus data/energie_extra_locations.dart (Phase 2):
  // Mount Kailash, Fuji, Sedona, Shasta, Uluru, Angkor, Borobudur,
  // Karnak, Tikal, Newgrange, Externsteine, Glastonbury, Avebury,
  // Naica, Mammoth, Aoraki, Aconcagua, Kilauea, Lourdes, Goldener
  // Tempel, Athos, Sintra, Petra, Bodhgaya, Lhasa Potala, Mont-Saint-
  // Michel, Sacra di San Michele.
  ...extraEnergieLocations,
];
