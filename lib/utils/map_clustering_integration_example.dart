// ignore_for_file: dangling_library_doc_comments
/// 🗺️ MARKER-CLUSTERING INTEGRATION EXAMPLE
/// 
/// So wird MapClusteringHelper in Karte-Tabs genutzt:
/// 
/// BEISPIEL für materie_karte_tab_pro.dart oder energie_karte_tab_pro.dart:

/*
import '../utils/map_clustering_helper.dart';

// In State-Klasse:
List<Marker> _markers = [];

// Marker erstellen:
void _buildMarkers() {
  _markers = locations.map((location) {
    return MapClusteringHelper.createMarker(
      point: LatLng(location.lat, location.lng),
      id: location.id,
      child: MapClusteringHelper.createMarkerIcon(
        icon: Icons.place,
        color: Colors.blue,
        size: 40,
      ),
      onTap: () => _showLocationDetail(location),
    );
  }).toList();
  
  setState(() {});
}

// In FlutterMap Widget:
FlutterMap(
  options: MapOptions(...),
  children: [
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    ),
    
    // ✅ MARKER-CLUSTERING aktiviert
    MapClusteringHelper.createClusterLayer(
      markers: _markers,
      clusterColor: Colors.blue,
      maxClusterRadius: MapClusteringHelper.calculateOptimalClusterRadius(
        _markers.length,
      ),
    ),
  ],
)

// Das war's! Marker werden automatisch geclustert bei Zoom-out
*/

/// VORTEILE:
/// - Überlappende Marker werden gruppiert
/// - Performance bei 100+ Markern
/// - Zoom-in öffnet Cluster automatisch
/// - Custom Farben pro Typ möglich

/// ZU BEACHTEN:
/// - Import: import '../utils/map_clustering_helper.dart';
/// - Package bereits installiert: flutter_map_marker_cluster: ^1.3.6
/// - Funktioniert mit bestehenden flutter_map Setups
