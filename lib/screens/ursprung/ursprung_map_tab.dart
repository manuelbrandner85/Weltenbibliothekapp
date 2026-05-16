import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class UrsprungMapTab extends StatefulWidget {
  const UrsprungMapTab({super.key});

  @override
  State<UrsprungMapTab> createState() => _UrsprungMapTabState();
}

class _ConsciousnessCenter {
  final String name, description, badge;
  final double lat, lng;

  const _ConsciousnessCenter({
    required this.name,
    required this.description,
    required this.badge,
    required this.lat,
    required this.lng,
  });
}

const _sites = [
  _ConsciousnessCenter(
    name: 'Monroe Institut',
    description: 'Heimat des Gateway Experience — Hemi-Sync Forschungszentrum',
    badge: 'Monroe Institut',
    lat: 37.83,
    lng: -78.77,
  ),
  _ConsciousnessCenter(
    name: 'SRI International',
    description: 'Remote Viewing Forschung 1972-1995, Heimat des STAR GATE Programms',
    badge: 'SRI',
    lat: 37.45,
    lng: -122.18,
  ),
  _ConsciousnessCenter(
    name: 'Esalen Institute',
    description: 'Pioniierzentrum für Humanistische Psychologie & Bewusstseinsforschung',
    badge: 'Esalen',
    lat: 36.14,
    lng: -121.63,
  ),
  _ConsciousnessCenter(
    name: 'Fort Meade (STAR GATE)',
    description: 'Standort des militärischen Remote Viewing Programms',
    badge: 'STAR GATE',
    lat: 39.11,
    lng: -76.77,
  ),
  _ConsciousnessCenter(
    name: 'Princeton PEAR Lab',
    description: 'Princeton Engineering Anomalies Research — Geist-Materie-Interaktion',
    badge: 'PEAR Lab',
    lat: 40.34,
    lng: -74.65,
  ),
  _ConsciousnessCenter(
    name: 'Findhorn Foundation',
    description: 'Internationales Zentrum für spirituelle Entwicklung',
    badge: 'Findhorn',
    lat: 57.66,
    lng: -3.60,
  ),
  _ConsciousnessCenter(
    name: 'Montauk Point',
    description: 'Standort geheimer Bewusstseins-Experimente (Montauk Project)',
    badge: 'Montauk',
    lat: 41.07,
    lng: -71.86,
  ),
  _ConsciousnessCenter(
    name: 'Skinwalker Ranch',
    description: 'Intensiv erforschtes Anomalien-Zentrum — UAP & Bewusstseinsphänomene',
    badge: 'Skinwalker',
    lat: 40.26,
    lng: -109.89,
  ),
];

class _UrsprungMapTabState extends State<UrsprungMapTab> {
  static const _cyan = Color(0xFF00D4AA);
  static const _bg = Color(0xFF050510);
  static const _surface = Color(0xFF080818);

  final _mapController = MapController();
  _ConsciousnessCenter? _selected;

  void _showDetail(_ConsciousnessCenter site) {
    setState(() => _selected = site);
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _cyan.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _cyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _cyan.withValues(alpha: 0.5)),
              ),
              child: Text(site.badge,
                  style: const TextStyle(color: _cyan, fontSize: 12)),
            ),
            const SizedBox(height: 10),
            Text(
              site.name,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              site.description,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  height: 1.5),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.location_on, color: _cyan, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${site.lat.toStringAsFixed(2)}°N, ${site.lng.toStringAsFixed(2)}°',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _selected = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(40.0, -95.0),
            initialZoom: 3.0,
            minZoom: 2.0,
            maxZoom: 12.0,
            backgroundColor: _bg,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png',
              userAgentPackageName: 'com.myapp.mobile',
            ),
            MarkerLayer(
              markers: _sites.map((s) {
                final isSelected = _selected?.name == s.name;
                return Marker(
                  point: LatLng(s.lat, s.lng),
                  width: isSelected ? 28 : 20,
                  height: isSelected ? 28 : 20,
                  child: GestureDetector(
                    onTap: () {
                      _mapController.move(LatLng(s.lat, s.lng), 5.0);
                      _showDetail(s);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? _cyan : _cyan.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : _cyan,
                          width: isSelected ? 2.5 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _cyan.withValues(alpha: isSelected ? 0.6 : 0.3),
                            blurRadius: isSelected ? 12 : 6,
                            spreadRadius: isSelected ? 2 : 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        Positioned(
          bottom: 12,
          right: 12,
          child: Text(
            '© Stadia Maps',
            style: TextStyle(
              color: _cyan.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}
