import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/ursprung_research_sites.dart';

class UrsprungMapTab extends StatefulWidget {
  const UrsprungMapTab({super.key});

  @override
  State<UrsprungMapTab> createState() => _UrsprungMapTabState();
}

typedef _ResearchSite = ResearchSite;

// 56 Sites in lib/data/ursprung_research_sites.dart definiert.
// Hier die ehemals inline-Liste ersetzt durch:
const _sites = allUrsprungSites;

// (alte _ResearchSite-Klasse + Liste folgte hier — entfernt.)

class _UrsprungMapTabState extends State<UrsprungMapTab> {
  static const _cyan = Color(0xFF00D4AA);
  static const _bg = Color(0xFF050510);
  static const _surface = Color(0xFF080818);

  final _mapController = MapController();
  _ResearchSite? _selected;

  // FEATURE (U7): Kategorie-Filter fuer die Forschungsstaetten.
  String _categoryFilter = 'all';

  static const Map<String, ({String label, String emoji})> _categories = {
    'all': (label: 'Alle', emoji: '🌐'),
    'consciousness': (label: 'Bewusstsein', emoji: '🧠'),
    'rv': (label: 'Remote Viewing', emoji: '👁️'),
    'ufo': (label: 'UFO/Anomalien', emoji: '🛸'),
    'archaeology': (label: 'Archäologie', emoji: '🏛️'),
    'tradition': (label: 'Traditionen', emoji: '📜'),
    'cymatics': (label: 'Kymatik', emoji: '🌊'),
  };

  List<_ResearchSite> get _visibleSites {
    if (_categoryFilter == 'all') return _sites;
    return _sites.where((s) => s.category == _categoryFilter).toList();
  }

  void _showDetail(_ResearchSite s) {
    setState(() => _selected = s);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.62,
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
                    color: _cyan.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (s.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    s.imageUrl!,
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
                                  color: _cyan, strokeWidth: 2),
                            ),
                          ),
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: Colors.white.withValues(alpha: 0.04),
                      alignment: Alignment.center,
                      child: Icon(s.icon,
                          color: _cyan.withValues(alpha: 0.6), size: 48),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _cyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _cyan.withValues(alpha: 0.5)),
                    ),
                    child: Text(s.badge,
                        style: const TextStyle(
                            color: _cyan,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: s.status.startsWith('Aktiv')
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      s.status,
                      style: TextStyle(
                          color: s.status.startsWith('Aktiv')
                              ? Colors.greenAccent
                              : Colors.orange,
                          fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(s.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text(s.founded,
                  style: TextStyle(
                      color: _cyan.withValues(alpha: 0.65),
                      fontSize: 12,
                      fontStyle: FontStyle.italic)),
              const SizedBox(height: 12),
              Text(s.description,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 14, height: 1.55)),
              if (s.findings.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Schlüsselergebnisse',
                    style: TextStyle(
                        color: _cyan,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...s.findings.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ',
                              style: TextStyle(color: _cyan, fontSize: 14)),
                          Expanded(
                            child: Text(f,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 13,
                                    height: 1.4)),
                          ),
                        ],
                      ),
                    )),
              ],
              if (s.researchers.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('Forscher',
                    style: TextStyle(
                        color: _cyan,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: s.researchers
                      .map((r) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _cyan.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _cyan.withValues(alpha: 0.3)),
                            ),
                            child: Text(r,
                                style: const TextStyle(
                                    color: _cyan, fontSize: 12)),
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
            initialCenter: LatLng(42.0, -90.0),
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
              markers: _visibleSites.map((s) {
                final sel = _selected?.name == s.name;
                return Marker(
                  point: LatLng(s.lat, s.lng),
                  width: sel ? 36 : 24,
                  height: sel ? 36 : 24,
                  child: GestureDetector(
                    onTap: () {
                      _mapController.move(LatLng(s.lat, s.lng), 5.5);
                      _showDetail(s);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: sel ? _cyan : _cyan.withValues(alpha: 0.75),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: sel ? Colors.white : _cyan,
                          width: sel ? 2.5 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _cyan.withValues(alpha: sel ? 0.7 : 0.3),
                            blurRadius: sel ? 14 : 6,
                            spreadRadius: sel ? 3 : 0,
                          ),
                        ],
                      ),
                      child: sel
                          ? const Icon(Icons.close,
                              color: Colors.black, size: 14)
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
                const Text('BEWUSSTSEINSZENTREN',
                    style: TextStyle(
                        color: _cyan,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3)),
                Text(
                  '${_visibleSites.length} von ${_sites.length} Standorten · Marker antippen',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12),
                ),
                const SizedBox(height: 10),
                // FEATURE (U7): Kategorie-Filter-Chips.
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _categories.entries.map((e) {
                      final active = _categoryFilter == e.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _categoryFilter = e.key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: active
                                  ? _cyan.withValues(alpha: 0.9)
                                  : _cyan.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: active
                                    ? _cyan
                                    : _cyan.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(e.value.emoji,
                                    style: const TextStyle(fontSize: 13)),
                                const SizedBox(width: 5),
                                Text(
                                  e.value.label,
                                  style: TextStyle(
                                    color:
                                        active ? Colors.black : Colors.white70,
                                    fontSize: 12,
                                    fontWeight: active
                                        ? FontWeight.bold
                                        : FontWeight.normal,
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
