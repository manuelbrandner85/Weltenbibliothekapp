import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../widgets/toast_helper.dart';
import '../../widgets/checkin_button.dart';

/// ENERGIE-Karte Tab - OpenStreetMap mit Kraftorten & Spirituellen Zentren
/// Zeigt: Energetische Hotspots, Ley-Linien, Heilige Stätten, Chakra-Punkte der Erde
class EnergieKarteTab extends StatefulWidget {
  const EnergieKarteTab({super.key});

  @override
  State<EnergieKarteTab> createState() => _EnergieKarteTabState();
}

class _EnergieKarteTabState extends State<EnergieKarteTab> {
  final MapController _mapController = MapController();
  
  // Map-Modi
  String _selectedMapMode = 'Standard';
  final List<String> _mapModes = ['Standard', 'Satellit', 'Hell', 'Dunkel', 'Topografisch'];
  
  String _getMapTileUrl() {
    switch (_selectedMapMode) {
      case 'Satellit':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case 'Hell':
        return 'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}{r}.png';
      case 'Dunkel':
        return 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png';
      case 'Topografisch':
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
      default:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }
  
  // ENERGIE-spezifische Locations (Kraftorte, Spirituelle Zentren, Energiepunkte)
  final List<EnergieLocation> _locations = [
    // Stonehenge - Ley-Linie Knotenpunkt
    EnergieLocation(
      name: 'Stonehenge - Uralter Kraftort',
      description: 'Prähistorisches Steinmonument, Ley-Linien-Knotenpunkt, astronomische Ausrichtung, Sonnenwenden-Zeremonien',
      position: const LatLng(51.1789, -1.8262),
      type: EnergieLocationType.leyLine,
      category: 'Ley-Lines',
      energyLevel: 5,
    ),
    // Sedona - Vortex Energie
    EnergieLocation(
      name: 'Sedona - Energie-Vortex',
      description: 'Kraftvolle Energie-Wirbel, Heilung, spirituelles Erwachen, rote Felsformationen mit hoher Schwingung',
      position: const LatLng(34.8697, -111.7610),
      type: EnergieLocationType.powerPlace,
      category: 'Kraftorte',
      energyLevel: 5,
    ),
    // Mount Shasta - Heiliger Berg
    EnergieLocation(
      name: 'Mount Shasta - Heiliger Berg',
      description: 'Spirituelles Zentrum, Wurzelchakra der Erde, Lemuria-Verbindung, Aufstiegsenergien',
      position: const LatLng(41.4092, -122.1949),
      type: EnergieLocationType.sacredSite,
      category: 'Heilige Stätten',
      energyLevel: 5,
    ),
    // Machu Picchu - Inka-Heiligtum
    EnergieLocation(
      name: 'Machu Picchu - Inka-Kraftort',
      description: 'Heilige Inka-Stadt, Energie-Portal, Verbindung zu höheren Dimensionen, Solarplexus-Chakra der Erde',
      position: const LatLng(-13.1631, -72.5450),
      type: EnergieLocationType.sacredSite,
      category: 'Heilige Stätten',
      energyLevel: 5,
    ),
    // Glastonbury - Avalon Tor
    EnergieLocation(
      name: 'Glastonbury - Avalon Tor',
      description: 'Mystisches Avalon, Herzchakra der Erde, Maria-Energie, Ley-Linien-Kreuzung',
      position: const LatLng(51.1444, -2.7145),
      type: EnergieLocationType.powerPlace,
      category: 'Kraftorte',
      energyLevel: 5,
    ),
    // Pyramiden von Gizeh
    EnergieLocation(
      name: 'Pyramiden von Gizeh - Uralte Weisheit',
      description: 'Energetische Kraftwerke, kosmische Verbindung, Atlanter-Technologie, Kehlkopfchakra der Erde',
      position: const LatLng(29.9792, 31.1342),
      type: EnergieLocationType.sacredSite,
      category: 'Heilige Stätten',
      energyLevel: 5,
    ),
    // Uluru - Aborigine-Heiligtum
    EnergieLocation(
      name: 'Uluru - Heiliger Felsen',
      description: 'Aborigine-Traumzeit-Ort, tiefe Erdverbindung, Wurzelchakra-Energie, Schöpfungsmythen',
      position: const LatLng(-25.3444, 131.0369),
      type: EnergieLocationType.powerPlace,
      category: 'Kraftorte',
      energyLevel: 5,
    ),
    // Bali - Spirituelle Insel
    EnergieLocation(
      name: 'Bali - Tempel der Götter',
      description: 'Hinduistische Tempel, Wasserreinigungszeremonien, spirituelle Praktiken, hohe Schwingung',
      position: const LatLng(-8.3405, 115.0920),
      type: EnergieLocationType.sacredSite,
      category: 'Spirituelle Zentren',
      energyLevel: 4,
    ),
    // Externsteine - Deutsches Kraftzentrum
    EnergieLocation(
      name: 'Externsteine - Germanischer Kraftort',
      description: 'Natürliche Felsformation, Ley-Linien, keltisch-germanische Kultstätte, Sommersonnenwende',
      position: const LatLng(51.8692, 8.9178),
      type: EnergieLocationType.leyLine,
      category: 'Ley-Lines',
      energyLevel: 4,
    ),
    // Teotihuacan - Stadt der Götter
    EnergieLocation(
      name: 'Teotihuacan - Stadt der Götter',
      description: 'Aztekische Pyramidenstadt, kosmische Ausrichtung, Aufstiegsenergien, Stirnchakra der Erde',
      position: const LatLng(19.6925, -98.8438),
      type: EnergieLocationType.sacredSite,
      category: 'Heilige Stätten',
      energyLevel: 5,
    ),
    // Untersberg - Mysterienberg
    EnergieLocation(
      name: 'Untersberg - Berg der Mysterien',
      description: 'Zeitanomalien, Portal zu anderen Dimensionen, Dalai Lama nannte es Herzchakra Europas',
      position: const LatLng(47.7025, 12.9789),
      type: EnergieLocationType.powerPlace,
      category: 'Kraftorte',
      energyLevel: 5,
    ),
    // Mount Kailash - Heiligster Berg
    EnergieLocation(
      name: 'Mount Kailash - Kronenchakra der Erde',
      description: 'Heiligster Berg für Hindus, Buddhisten, Jainas, Kronenchakra der Erde, kosmische Achse',
      position: const LatLng(31.0667, 81.3111),
      type: EnergieLocationType.sacredSite,
      category: 'Heilige Stätten',
      energyLevel: 5,
    ),
    
    // 🆕 WEITERE ENERGIE-KRAFTORTE
    EnergieLocation(
      name: 'Teotihuacán - Pyramiden der Götter',
      description: 'Mysteriöse Pyramidenstadt mit starken Energie-Phänomenen. Sonnenpyramide auf geomantischem Knotenpunkt. Initiationsort für schamanische Praktiken.',
      position: LatLng(19.6925, -98.8438),
      type: EnergieLocationType.powerPlace,
      category: 'Kraftorte',
      energyLevel: 5,
    ),
    
    EnergieLocation(
      name: 'Bosnische Pyramiden - Visoko',
      description: 'Umstrittene Pyramidenstrukturen mit Ultraschall-Anomalien (28 kHz). Meditations-Zentrum. Energie-Heiler berichten außergewöhnliche Wirkungen.',
      position: LatLng(43.9772, 18.1758),
      type: EnergieLocationType.powerPlace,
      category: 'Kraftorte',
      energyLevel: 4,
    ),
    
    EnergieLocation(
      name: 'Rishikesh - Yoga-Hauptstadt',
      description: 'Heilige Stadt am Ganges-Ufer. Spirituelles Zentrum für Yoga und Meditation. Himalaya-Nähe verstärkt Erdkraft. Beatles meditierte hier 1968.',
      position: LatLng(30.0869, 78.2676),
      type: EnergieLocationType.sacredSite,
      category: 'Heilige Stätten',
      energyLevel: 5,
    ),
    EnergieLocation(
      name: 'Mount Kailash - Heiliger Berg',
      description: 'Einer der kraftvollsten spirituellen Orte der Welt, heilig in 4 Religionen (Hinduismus, Buddhismus, Jainismus, Bön). Zentrum der Welt-Energie.',
      position: LatLng(31.0672, 81.3111),
      type: EnergieLocationType.sacredSite,
      category: 'Heilige Stätten',
      energyLevel: 5,
    ),
    EnergieLocation(
      name: 'Uluru (Ayers Rock) - Aborigine Kraftort',
      description: 'Heiliger Berg der Aborigines. Starke Erdenergie, spirituelle Zeremonien, Traumzeit-Geschichten. Kraftvoll für Erdung.',
      position: LatLng(-25.3444, 131.0369),
      type: EnergieLocationType.powerPlace,
      category: 'Kraftorte',
      energyLevel: 5,
    ),
    EnergieLocation(
      name: 'Lake Titicaca - Inka Energie-Portal',
      description: 'Heiliger See der Inka. Geburtsort von Sonne und Mond in der Mythologie. Portal zu höheren Dimensionen.',
      position: LatLng(-15.8422, -69.3584),
      type: EnergieLocationType.powerPlace,
      category: 'Kraftorte',
      energyLevel: 5,
    ),
    EnergieLocation(
      name: 'Avebury Stone Circle - Britischer Steinkreis',
      description: 'Größter prähistorischer Steinkreis Europas. Starke Ley-Line Energie, geomantisches Zentrum.',
      position: LatLng(51.4291, -1.8538),
      type: EnergieLocationType.leyLine,
      category: 'Ley-Lines',
      energyLevel: 4,
    ),
  ];

  Set<String> _selectedFilters = {'Alle'};

  List<EnergieLocation> get _filteredLocations {
    if (_selectedFilters.contains('Alle')) return _locations;
    return _locations.where((loc) => _selectedFilters.contains(loc.category)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🗺️ VOLLBILD-KARTE (füllt kompletten Bildschirm)
          Positioned.fill(
            child: _buildMap(),
          ),
          
          // Kompakte Floating-Controls (Oben Rechts)
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: _buildCompactControls(),
            ),
          ),
          
          // Kompakte Legende (Unten Links)
          Positioned(
            bottom: 16,
            left: 16,
            child: SafeArea(
              child: _buildCompactLegend(),
            ),
          ),
        ],
      ),
    );
  }

  /// Kompakte Floating-Controls (Oben Rechts)
  Widget _buildCompactControls() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Map-Mode Dropdown
          _buildCompactDropdown(
            icon: Icons.map,
            value: _selectedMapMode,
            items: _mapModes,
            onChanged: (value) {
              setState(() {
                _selectedMapMode = value!;
              });
            },
          ),
          
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          
          // Kategorie-Chips (ersetzt Dropdown)
          _buildCategoryChips(),
        ],
      ),
    );
  }

  /// Kategorie-Chips (klickbare Filter mit Counter)
  Widget _buildCategoryChips() {
    // Zähle Marker pro Kategorie
    final categoryCount = <String, int>{};
    categoryCount['Alle'] = _locations.length;
    for (var location in _locations) {
      categoryCount[location.category] = (categoryCount[location.category] ?? 0) + 1;
    }

    final categories = [
      {'name': 'Alle', 'icon': '⭐', 'color': Color(0xFFFFD700)},
      {'name': 'Kraftorte', 'icon': '🟣', 'color': Color(0xFF9C27B0)},
      {'name': 'Ley-Lines', 'icon': '🔵', 'color': Color(0xFF2196F3)},
      {'name': 'Heilige Stätten', 'icon': '🟢', 'color': Color(0xFF4CAF50)},
      {'name': 'Spirituelle Zentren', 'icon': '🟡', 'color': Color(0xFFFFEB3B)},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.85),
            Colors.black.withValues(alpha: 0.65),
            Colors.black.withValues(alpha: 0.50),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        child: Row(
          children: categories.map((cat) {
            final catName = cat['name'] as String;
            final isSelected = _selectedFilters.contains(catName);
            final count = categoryCount[catName] ?? 0;
            final color = cat['color'] as Color;
            
            return Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (catName == 'Alle') {
                      _selectedFilters = {'Alle'};
                    } else {
                      if (_selectedFilters.contains(catName)) {
                        _selectedFilters.remove(catName);
                        if (_selectedFilters.isEmpty) {
                          _selectedFilters.add('Alle');
                        }
                      } else {
                        _selectedFilters.add(catName);
                        _selectedFilters.remove('Alle');
                      }
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: isSelected 
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withValues(alpha: 0.7),
                              color.withValues(alpha: 0.5),
                              color.withValues(alpha: 0.3),
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.12),
                              Colors.white.withValues(alpha: 0.08),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.3),
                      width: isSelected ? 2.5 : 1.8,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: Offset(0, 4),
                      ),
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 28,
                        spreadRadius: 4,
                        offset: Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ] : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isSelected ? RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.4),
                              color.withValues(alpha: 0.2),
                            ],
                          ) : null,
                        ),
                        child: Text(
                          cat['icon'] as String,
                          style: TextStyle(
                            fontSize: 20,
                            shadows: isSelected ? [
                              Shadow(
                                color: color.withValues(alpha: 0.9),
                                blurRadius: 12,
                              ),
                              Shadow(
                                color: Colors.white.withValues(alpha: 0.6),
                                blurRadius: 4,
                              ),
                            ] : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        catName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 15,
                          letterSpacing: 0.5,
                          shadows: isSelected ? [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.7),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                            Shadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                          ] : [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.5),
                                    Colors.white.withValues(alpha: 0.3),
                                    color.withValues(alpha: 0.4),
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.15),
                                    Colors.white.withValues(alpha: 0.10),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected 
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.2),
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ] : null,
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            shadows: isSelected ? [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 4,
                              ),
                            ] : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Kompaktes Dropdown Widget
  Widget _buildCompactDropdown({
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFFFD700), size: 20),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: value,
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            underline: const SizedBox.shrink(),
            dropdownColor: const Color(0xFF1E1E1E),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 20),
            isDense: true,
          ),
        ],
      ),
    );
  }



  Widget _buildMap() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: const LatLng(30.0, 0.0), // Weltzentrum
          initialZoom: 2.0,
          minZoom: 2.0,
          maxZoom: 18.0,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          // OpenStreetMap Tiles - HELL (kein Filter mehr!)
          TileLayer(
            urlTemplate: _getMapTileUrl(),
            userAgentPackageName: 'com.dualrealms.knowledge',
          ),
          
          // Marker Layer
          MarkerLayer(
            markers: _filteredLocations.map((location) {
              return Marker(
                point: location.position,
                width: 70,
                height: 70,
                child: GestureDetector(
                  onTap: () => _showLocationDetails(location),
                  child: _buildMarker(location),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMarker(EnergieLocation location) {
    final color = _getMarkerColor(location.type);
    final icon = _getMarkerIcon(location.type);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.4),
                color.withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Energie-Level Anzeige
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(location.energyLevel, (index) {
            return Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Color _getMarkerColor(EnergieLocationType type) {
    switch (type) {
      case EnergieLocationType.powerPlace:
        return const Color(0xFF9C27B0); // Lila
      case EnergieLocationType.leyLine:
        return const Color(0xFFFFD700); // Gold
      case EnergieLocationType.sacredSite:
        return const Color(0xFFBA68C8); // Hell-Lila
    }
  }

  IconData _getMarkerIcon(EnergieLocationType type) {
    switch (type) {
      case EnergieLocationType.powerPlace:
        return Icons.auto_awesome;
      case EnergieLocationType.leyLine:
        return Icons.location_on;
      case EnergieLocationType.sacredSite:
        return Icons.temple_hindu;
    }
  }

  void _showLocationDetails(EnergieLocation location) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E1E1E),
              _getMarkerColor(location.type).withValues(alpha: 0.1),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: _getMarkerColor(location.type).withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _getMarkerColor(location.type).withValues(alpha: 0.3),
              blurRadius: 20,
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + Name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        _getMarkerColor(location.type).withValues(alpha: 0.3),
                        _getMarkerColor(location.type).withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getMarkerColor(location.type).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Icon(
                    _getMarkerIcon(location.type),
                    color: _getMarkerColor(location.type),
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
                      // Energie-Level
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: Color(0xFFFFD700),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Energie-Level: ${location.energyLevel}/5',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFFD700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Kategorie Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getMarkerColor(location.type).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _getMarkerColor(location.type).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getMarkerIcon(location.type),
                    size: 14,
                    color: _getMarkerColor(location.type),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    location.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getMarkerColor(location.type),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Beschreibung
            Text(
              location.description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            
            // Check-In Button
            Center(
              child: CheckInButton(
                locationId: location.name.replaceAll(' ', '_').toLowerCase(),
                locationName: location.name,
                category: location.category.toLowerCase().replaceAll(' ', '_'),
                worldType: 'energie',
                accentColor: _getMarkerColor(location.type),
              ),
            ),
            const SizedBox(height: 16),
            
            // Navigieren Button mit Glow
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _mapController.move(location.position, 12);
                  ToastHelper.showSuccess(context, 'Navigiere zu ${location.name}');
                },
                icon: const Icon(Icons.explore),
                label: const Text('Kraftort erkunden'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getMarkerColor(location.type).withValues(alpha: 0.3),
                  foregroundColor: _getMarkerColor(location.type),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _getMarkerColor(location.type).withValues(alpha: 0.5),
                    ),
                  ),
                  elevation: 0,
                  shadowColor: _getMarkerColor(location.type).withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kompakte Icon-Only Legende (Unten Links)
  Widget _buildCompactLegend() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactLegendItem(Icons.auto_awesome, const Color(0xFF9C27B0)),
          const SizedBox(height: 6),
          _buildCompactLegendItem(Icons.location_on, const Color(0xFFFFD700)),
          const SizedBox(height: 6),
          _buildCompactLegendItem(Icons.temple_hindu, const Color(0xFFBA68C8)),
        ],
      ),
    );
  }

  Widget _buildCompactLegendItem(IconData icon, Color color) {
    return Icon(icon, color: color, size: 20);
  }
}

// ENERGIE Location Model
class EnergieLocation {
  final String name;
  final String description;
  final LatLng position;
  final EnergieLocationType type;
  final String category;
  final int energyLevel; // 1-5

  EnergieLocation({
    required this.name,
    required this.description,
    required this.position,
    required this.type,
    required this.category,
    required this.energyLevel,
  });
}

enum EnergieLocationType {
  powerPlace,
  leyLine,
  sacredSite,
}
