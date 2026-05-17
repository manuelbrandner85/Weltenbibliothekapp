import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/vorhang_power_centers.dart';

class VorhangMapTab extends StatefulWidget {
  const VorhangMapTab({super.key});

  @override
  State<VorhangMapTab> createState() => _VorhangMapTabState();
}

// 56 Machtzentren mit Foto-URLs in lib/data/vorhang_power_centers.dart.
typedef _PowerCenter = PowerCenter;

const _centers = allVorhangCenters;

class _VorhangMapTabState extends State<VorhangMapTab> {
  static const _gold = Color(0xFFC9A84C);
  static const _bg = Color(0xFF000000);
  static const _surface = Color(0xFF0D0B00);

  final _mapController = MapController();
  _PowerCenter? _selected;

  void _showDetail(_PowerCenter c) {
    setState(() => _selected = c);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (_, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          child: Column(
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
              if (c.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    c.imageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, p) => p == null
                        ? child
                        : Container(
                            height: 180,
                            color: Colors.white.withValues(alpha: 0.04),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: _gold,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: Colors.white.withValues(alpha: 0.04),
                      alignment: Alignment.center,
                      child: Icon(c.icon,
                          color: _gold.withValues(alpha: 0.6), size: 48),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _gold.withValues(alpha: 0.5)),
                    ),
                    child: Text(c.badge,
                        style: const TextStyle(
                            color: _gold, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      c.influence,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(c.name,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(c.founded,
                  style: TextStyle(
                      color: _gold.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontStyle: FontStyle.italic)),
              const SizedBox(height: 12),
              Text(c.description,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 14, height: 1.55)),
              if (c.members.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Bekannte Mitglieder',
                    style: TextStyle(
                        color: _gold, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...c.members.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline, color: _gold, size: 14),
                          const SizedBox(width: 8),
                          Text(m,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 13)),
                        ],
                      ),
                    )),
              ],
              if (c.connections.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Verbindungen',
                    style: TextStyle(
                        color: _gold, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: c.connections
                      .map((x) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _gold.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: _gold.withValues(alpha: 0.35)),
                            ),
                            child: Text(x,
                                style: const TextStyle(color: _gold, fontSize: 12)),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
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
            initialCenter: LatLng(47.0, 5.0),
            initialZoom: 3.2,
            minZoom: 2.0,
            maxZoom: 14.0,
            backgroundColor: _bg,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.myapp.mobile',
            ),
            MarkerLayer(
              markers: _centers.map((c) {
                final sel = _selected?.name == c.name;
                return Marker(
                  point: LatLng(c.lat, c.lng),
                  width: sel ? 36 : 24,
                  height: sel ? 36 : 24,
                  child: GestureDetector(
                    onTap: () {
                      _mapController.move(LatLng(c.lat, c.lng), 5.5);
                      _showDetail(c);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: sel ? _gold : _gold.withValues(alpha: 0.75),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: sel ? Colors.white : _gold,
                          width: sel ? 2.5 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _gold.withValues(alpha: sel ? 0.7 : 0.3),
                            blurRadius: sel ? 14 : 6,
                            spreadRadius: sel ? 3 : 0,
                          ),
                        ],
                      ),
                      child: sel
                          ? const Icon(Icons.close, color: Colors.black, size: 14)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: _bg.withValues(alpha: 0.82),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MACHTZENTREN',
                    style: TextStyle(
                        color: _gold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3)),
                Text(
                  '${_centers.length} Standorte · Marker antippen für Details',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
