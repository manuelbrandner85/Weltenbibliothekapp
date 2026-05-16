import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class VorhangMapTab extends StatefulWidget {
  const VorhangMapTab({super.key});

  @override
  State<VorhangMapTab> createState() => _VorhangMapTabState();
}

class _PowerCenter {
  final String name, description, badge;
  final double lat, lng;
  final List<String> connections;

  const _PowerCenter({
    required this.name,
    required this.description,
    required this.badge,
    required this.lat,
    required this.lng,
    this.connections = const [],
  });
}

const _centers = [
  _PowerCenter(
    name: 'World Economic Forum',
    description: 'Jährliches Treffen der globalen Elite',
    badge: 'WEF',
    lat: 46.80,
    lng: 9.84,
    connections: ['V-21', 'V-22', 'Machtpsychologie'],
  ),
  _PowerCenter(
    name: 'Bilderberg Hotel',
    description: 'Geheimtreffen seit 1954',
    badge: 'Bilderberg',
    lat: 51.98,
    lng: 5.83,
    connections: ['V-01', 'V-06', 'Elite-Strategien'],
  ),
  _PowerCenter(
    name: 'City of London',
    description: 'Eigenständiger Stadtstaat im Herzen Londons',
    badge: 'Finanzzentrum',
    lat: 51.51,
    lng: -0.09,
    connections: ['V-23', 'V-24', 'Soft Power'],
  ),
  _PowerCenter(
    name: 'Vatikan',
    description: 'Kleinster Staat, maximaler globaler Einfluss',
    badge: 'Vatikan',
    lat: 41.90,
    lng: 12.45,
    connections: ['V-02', 'V-26', 'Schattenarbeit'],
  ),
  _PowerCenter(
    name: 'Council on Foreign Relations',
    description: 'Council on Foreign Relations — Außenpolitik-Vordenker',
    badge: 'CFR',
    lat: 40.77,
    lng: -73.97,
    connections: ['V-21', 'Geopolitik', 'V-25'],
  ),
  _PowerCenter(
    name: 'Bank für Internationalen Zahlungsausgleich',
    description: 'Zentralbank der Zentralbanken',
    badge: 'BIS',
    lat: 47.54,
    lng: 7.60,
    connections: ['V-23', 'Spieltheorie'],
  ),
  _PowerCenter(
    name: 'Trilaterale Kommission',
    description: 'Transatlantische Elite-Koordination',
    badge: 'Trilateral',
    lat: 50.85,
    lng: 4.35,
    connections: ['V-01', 'V-04', 'Soft Power'],
  ),
  _PowerCenter(
    name: 'Skull & Bones',
    description: 'Geheimbund der Yale University',
    badge: 'Skull & Bones',
    lat: 41.31,
    lng: -72.92,
    connections: ['V-06', 'V-08', 'Dunkle Triade'],
  ),
  _PowerCenter(
    name: 'Bohemian Grove',
    description: 'Elite-Treffen im Redwood-Wald',
    badge: 'Bohemian Grove',
    lat: 38.53,
    lng: -123.00,
    connections: ['V-02', 'V-05', 'BOSS Machtmeister'],
  ),
  _PowerCenter(
    name: 'Chatham House',
    description: 'Royal Institute of International Affairs',
    badge: 'Chatham House',
    lat: 51.51,
    lng: -0.13,
    connections: ['V-22', 'Systemisches Denken'],
  ),
];

class _VorhangMapTabState extends State<VorhangMapTab> {
  static const _gold = Color(0xFFC9A84C);
  static const _bg = Color(0xFF000000);
  static const _surface = Color(0xFF0D0B00);

  final _mapController = MapController();
  _PowerCenter? _selected;

  void _showDetail(_PowerCenter center) {
    setState(() => _selected = center);
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
                  color: _gold.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _gold.withValues(alpha: 0.5)),
                  ),
                  child: Text(center.badge,
                      style: const TextStyle(color: _gold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              center.name,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              center.description,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 14, height: 1.4),
            ),
            if (center.connections.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Verbindungen',
                style: TextStyle(
                    color: _gold, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: center.connections
                    .map((c) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _gold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _gold.withValues(alpha: 0.3)),
                          ),
                          child: Text(c,
                              style:
                                  const TextStyle(color: _gold, fontSize: 11)),
                        ))
                    .toList(),
              ),
            ],
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
            initialCenter: LatLng(47.0, 8.0),
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
              markers: _centers.map((c) {
                final isSelected = _selected?.name == c.name;
                return Marker(
                  point: LatLng(c.lat, c.lng),
                  width: isSelected ? 28 : 20,
                  height: isSelected ? 28 : 20,
                  child: GestureDetector(
                    onTap: () {
                      _mapController.move(LatLng(c.lat, c.lng), 5.0);
                      _showDetail(c);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? _gold : _gold.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : _gold,
                          width: isSelected ? 2.5 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _gold.withValues(alpha: isSelected ? 0.6 : 0.3),
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
              color: _gold.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}
