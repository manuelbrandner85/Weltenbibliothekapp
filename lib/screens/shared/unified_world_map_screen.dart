// Erweiterung 3: unified "Vier-Welten-Karte" with toggleable layers.
//
// Additive feature -- the four per-world maps stay intact. This screen shows
// all 258+ markers on ONE map, organized into four toggleable layers
// (Kraftorte, Geopolitik-Hotspots, Symbol-Orte, historische Orte). Each world
// opens it with its own layer active by default; the others can be toggled on
// to compare across worlds.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../data/unified_map_data.dart';
import '../../utils/map_clustering_helper.dart';
import '../../services/haptic_service.dart';

class UnifiedWorldMapScreen extends StatefulWidget {
  /// Calling world -- decides which layer is active by default + accent color.
  final String world;
  const UnifiedWorldMapScreen({super.key, required this.world});

  @override
  State<UnifiedWorldMapScreen> createState() => _UnifiedWorldMapScreenState();
}

class _UnifiedWorldMapScreenState extends State<UnifiedWorldMapScreen> {
  final MapController _mapController = MapController();

  late List<UnifiedMapMarker> _allMarkers;
  late Set<String> _activeLayers;

  @override
  void initState() {
    super.initState();
    _allMarkers = buildUnifiedMarkers();
    _activeLayers = MapLayers.defaultsFor(widget.world);
  }

  Color get _accent {
    switch (widget.world) {
      case 'energie':
        return const Color(0xFFA855F7);
      case 'vorhang':
        return const Color(0xFFC9A84C);
      case 'ursprung':
        return const Color(0xFF00D4AA);
      case 'materie':
      default:
        return const Color(0xFF3B82F6);
    }
  }

  List<UnifiedMapMarker> get _visible =>
      _allMarkers.where((m) => _activeLayers.contains(m.layerId)).toList();

  void _toggleLayer(String id) {
    HapticService.selectionClick();
    setState(() {
      if (_activeLayers.contains(id)) {
        _activeLayers.remove(id);
      } else {
        _activeLayers.add(id);
      }
    });
  }

  List<Marker> _buildMarkers() {
    return _visible.map((m) {
      final layer = MapLayers.byId(m.layerId);
      return MapClusteringHelper.createMarker(
        point: m.position,
        id: '${m.layerId}_${m.name}',
        onTap: () => _openDetail(m, layer),
        child: _MarkerPin(color: layer.color, icon: layer.icon),
      );
    }).toList();
  }

  void _openDetail(UnifiedMapMarker marker, MapLayer layer) {
    HapticService.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MarkerDetailSheet(marker: marker, layer: layer),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF04060A),
        elevation: 0,
        iconTheme: IconThemeData(color: _accent),
        title: Text(
          'VIER-WELTEN-KARTE',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w300,
            fontSize: 15,
            letterSpacing: 2.5,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(30, 10),
              initialZoom: 2.2,
              minZoom: 1.5,
              maxZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.weltenbibliothek.app',
                retinaMode: RetinaMode.isHighDensity(context),
              ),
              MapClusteringHelper.createClusterLayer(
                markers: _buildMarkers(),
                clusterColor: _accent.withValues(alpha: 0.85),
                maxClusterRadius: 80,
                showPopup: false,
              ),
            ],
          ),
          _buildLayerBar(),
          _buildCountBadge(),
        ],
      ),
    );
  }

  Widget _buildLayerBar() {
    return Positioned(
      top: 8,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            for (final layer in MapLayers.all) _layerChip(layer),
          ],
        ),
      ),
    );
  }

  Widget _layerChip(MapLayer layer) {
    final active = _activeLayers.contains(layer.id);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _toggleLayer(layer.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: active
                  ? layer.color.withValues(alpha: 0.22)
                  : Colors.black.withValues(alpha: 0.55),
              border: Border.all(
                color:
                    active ? layer.color : Colors.white.withValues(alpha: 0.15),
                width: active ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(layer.icon,
                    size: 14,
                    color: active
                        ? layer.color
                        : Colors.white.withValues(alpha: 0.6)),
                const SizedBox(width: 6),
                Text(
                  layer.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    color: active
                        ? layer.color
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountBadge() {
    return Positioned(
      bottom: 20,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _accent.withValues(alpha: 0.4)),
        ),
        child: Text(
          '${_visible.length} Orte',
          style: TextStyle(
            color: _accent,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Colored circular pin with the layer's icon.
class _MarkerPin extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _MarkerPin({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.9),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

/// Bottom sheet with the marker's details + which layer/world it belongs to.
class _MarkerDetailSheet extends StatelessWidget {
  final UnifiedMapMarker marker;
  final MapLayer layer;
  const _MarkerDetailSheet({required this.marker, required this.layer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0B0D12),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: layer.color.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: layer.color.withValues(alpha: 0.15),
                  border: Border.all(color: layer.color.withValues(alpha: 0.5)),
                ),
                child: Icon(layer.icon, color: layer.color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marker.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      layer.label,
                      style: TextStyle(
                        color: layer.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (marker.subtitle != null && marker.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: layer.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                marker.subtitle!,
                style: TextStyle(
                  color: layer.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            marker.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tipp: Im Layer-Menue oben kannst du weitere Welten einblenden und '
            'dasselbe Gebiet aus mehreren Perspektiven sehen.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
