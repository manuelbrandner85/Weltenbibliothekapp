// Erweiterung 3: unified "Vier-Welten-Karte" data layer.
//
// Adapts the four existing hardcoded marker datasets (Materie, Energie,
// Vorhang, Ursprung) into ONE list of [UnifiedMapMarker]s grouped into four
// toggleable map layers -- WITHOUT touching or duplicating the source data.
// The original per-world maps stay fully intact; this only re-projects their
// data for the shared layered map.

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'materie_locations.dart';
import 'vorhang_power_centers.dart';
import 'ursprung_research_sites.dart';
import '../screens/energie/energie_karte_tab_pro.dart';

/// A map layer definition (one per source world).
class MapLayer {
  final String id;
  final String label;
  final String world;
  final Color color;
  final IconData icon;

  const MapLayer({
    required this.id,
    required this.label,
    required this.world,
    required this.color,
    required this.icon,
  });
}

/// The four layers, named per the spec.
class MapLayers {
  static const geopolitik = MapLayer(
    id: 'geopolitik',
    label: 'Geopolitik-Hotspots',
    world: 'materie',
    color: Color(0xFF3B82F6),
    icon: Icons.public,
  );
  static const kraftorte = MapLayer(
    id: 'kraftorte',
    label: 'Kraftorte',
    world: 'energie',
    color: Color(0xFFA855F7),
    icon: Icons.bolt,
  );
  static const symbolorte = MapLayer(
    id: 'symbol',
    label: 'Symbol-Orte',
    world: 'vorhang',
    color: Color(0xFFC9A84C),
    icon: Icons.visibility,
  );
  static const historisch = MapLayer(
    id: 'historisch',
    label: 'Historische Orte',
    world: 'ursprung',
    color: Color(0xFF00D4AA),
    icon: Icons.account_balance,
  );

  static const List<MapLayer> all = [
    geopolitik,
    kraftorte,
    symbolorte,
    historisch,
  ];

  static MapLayer byId(String id) =>
      all.firstWhere((l) => l.id == id, orElse: () => geopolitik);

  /// Default-active layer ids per world (each world highlights its own data
  /// first; the others can be toggled on for the cross-world view).
  static Set<String> defaultsFor(String world) {
    switch (world) {
      case 'energie':
        return {kraftorte.id};
      case 'vorhang':
        return {symbolorte.id};
      case 'ursprung':
        return {historisch.id};
      case 'materie':
      default:
        return {geopolitik.id};
    }
  }
}

/// A single marker on the unified map, normalized from any source world.
/// Plain Dart class (NO Dart 3 record types).
class UnifiedMapMarker {
  final String layerId;
  final String name;
  final LatLng position;
  final String? subtitle;
  final String description;

  const UnifiedMapMarker({
    required this.layerId,
    required this.name,
    required this.position,
    this.subtitle,
    required this.description,
  });
}

/// Builds the full marker set across all four worlds. Pure transformation of
/// the existing data lists -- safe and side-effect-free.
List<UnifiedMapMarker> buildUnifiedMarkers() {
  final out = <UnifiedMapMarker>[];

  // Materie -> Geopolitik-Hotspots
  for (final m in allMaterieLocations) {
    out.add(UnifiedMapMarker(
      layerId: MapLayers.geopolitik.id,
      name: m.name,
      position: m.position,
      subtitle: m.category.name,
      description: m.description,
    ));
  }

  // Energie -> Kraftorte
  for (final e in allEnergieLocations) {
    out.add(UnifiedMapMarker(
      layerId: MapLayers.kraftorte.id,
      name: e.name,
      position: e.position,
      subtitle:
          e.energyLevel != null ? 'Energielevel ${e.energyLevel}/10' : null,
      description: e.description,
    ));
  }

  // Vorhang -> Symbol-Orte (Macht-/Symbolzentren)
  for (final v in allVorhangCenters) {
    out.add(UnifiedMapMarker(
      layerId: MapLayers.symbolorte.id,
      name: v.name,
      position: LatLng(v.lat, v.lng),
      subtitle: v.badge,
      description: v.description,
    ));
  }

  // Ursprung -> Historische Orte (Forschungsstaetten)
  for (final s in allUrsprungSites) {
    out.add(UnifiedMapMarker(
      layerId: MapLayers.historisch.id,
      name: s.name,
      position: LatLng(s.lat, s.lng),
      subtitle: s.badge,
      description: s.description,
    ));
  }

  return out;
}
