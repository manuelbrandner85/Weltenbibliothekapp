import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Interaktive Karte für Ereignis-Visualisierung
/// 
/// Zeigt Narrative auf einer Weltkarte mit Markern und Details
class InteractiveMapWidget extends StatefulWidget {
  final List<Map<String, dynamic>> narratives;
  final Function(String narrativeId)? onMarkerTap;

  const InteractiveMapWidget({
    super.key,
    required this.narratives,
    this.onMarkerTap,
  });

  @override
  State<InteractiveMapWidget> createState() => _InteractiveMapWidgetState();
}

class _InteractiveMapWidgetState extends State<InteractiveMapWidget> {
  final MapController _mapController = MapController();
  String? _selectedNarrativeId;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Karte
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(40.0, 0.0), // Welt-Zentrum
                initialZoom: 2.0,
                minZoom: 1.0,
                maxZoom: 18.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                // Tile Layer (OpenStreetMap)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.dualrealms.knowledge',
                  maxNativeZoom: 19,
                  maxZoom: 22,
                ),

                // Marker Layer
                MarkerLayer(
                  markers: _buildMarkers(),
                ),

                // Polygon Layer für Verbindungen (optional)
                if (_selectedNarrativeId != null)
                  PolylineLayer(
                    polylines: _buildConnectionLines(),
                  ),
              ],
            ),

            // Legend
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🗺️ Ereignis-Karte',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem('🔴', 'UFO & Technologie'),
                    _buildLegendItem('🟢', 'Geheimgesellschaften'),
                    _buildLegendItem('🔵', 'Historische Ereignisse'),
                  ],
                ),
              ),
            ),

            // Reset Button
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                onPressed: () {
                  _mapController.move(const LatLng(40.0, 0.0), 2.0);
                  setState(() => _selectedNarrativeId = null);
                },
                child: const Icon(Icons.zoom_out_map),
              ),
            ),

            // Selected Narrative Info
            if (_selectedNarrativeId != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 80,
                child: _buildNarrativeInfoCard(),
              ),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    return widget.narratives
        .where((n) => n['location'] != null)
        .map((narrative) {
      final location = narrative['location'] as Map<String, dynamic>;
      final lat = (location['lat'] as num).toDouble();
      final lng = (location['lng'] as num).toDouble();

      final isSelected = _selectedNarrativeId == narrative['id'];

      return Marker(
        point: LatLng(lat, lng),
        width: isSelected ? 80 : 60,
        height: isSelected ? 80 : 60,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedNarrativeId = narrative['id'] as String;
            });
            _mapController.move(LatLng(lat, lng), 6.0);
            widget.onMarkerTap?.call(narrative['id'] as String);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: Column(
              children: [
                // Marker Icon
                Container(
                  width: isSelected ? 50 : 40,
                  height: isSelected ? 50 : 40,
                  decoration: BoxDecoration(
                    color: _getMarkerColor(narrative['categories'] as List),
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
                  child: Center(
                    child: Text(
                      _getCategoryIcon(narrative['categories'] as List),
                      style: TextStyle(fontSize: isSelected ? 24 : 20),
                    ),
                  ),
                ),
                
                // Label (nur bei Selektion)
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _truncateTitle(narrative['title'] as String),
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
    }).toList();
  }

  List<Polyline> _buildConnectionLines() {
    final selected = widget.narratives.firstWhere(
      (n) => n['id'] == _selectedNarrativeId,
    );

    final relatedIds = selected['relatedNarratives'] as List?;
    if (relatedIds == null) return [];

    final selectedLocation = selected['location'] as Map<String, dynamic>;
    final selectedPoint = LatLng(
      (selectedLocation['lat'] as num).toDouble(),
      (selectedLocation['lng'] as num).toDouble(),
    );

    return relatedIds
        .map((id) {
          final related = widget.narratives.firstWhere(
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
    final narrative = widget.narratives.firstWhere(
      (n) => n['id'] == _selectedNarrativeId,
    );

    final location = narrative['location'] as Map<String, dynamic>;

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
              Text(
                _getCategoryIcon(narrative['categories'] as List),
                style: const TextStyle(fontSize: 24),
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

  Widget _buildLegendItem(String emoji, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _getMarkerColor(List categories) {
    if (categories.contains('ufo')) return Colors.red.withValues(alpha: 0.8);
    if (categories.contains('secret_society')) return Colors.green.withValues(alpha: 0.8);
    if (categories.contains('history')) return Colors.blue.withValues(alpha: 0.8);
    return Colors.purple.withValues(alpha: 0.8);
  }

  String _getCategoryIcon(List categories) {
    if (categories.contains('ufo')) return '👽';
    if (categories.contains('secret_society')) return '🏛️';
    if (categories.contains('history')) return '📜';
    if (categories.contains('technology')) return '⚡';
    return '🌍';
  }

  String _truncateTitle(String title) {
    if (title.length <= 20) return title;
    return '${title.substring(0, 20)}...';
  }
}
