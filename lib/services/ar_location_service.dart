import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

/// AR Location Service - Mystische Orte in der Nähe finden
class ARLocationService {
  static final ARLocationService _instance = ARLocationService._internal();
  factory ARLocationService() => _instance;
  ARLocationService._internal();

  Position? _currentPosition;

  /// Standort-Berechtigung prüfen und anfordern
  Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('❌ Standortdienste sind deaktiviert');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('❌ Standort-Berechtigung verweigert');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('❌ Standort-Berechtigung dauerhaft verweigert');
      return false;
    }

    return true;
  }

  /// Aktuellen Standort abrufen
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) return null;

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      debugPrint('📍 Standort: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      return _currentPosition;
    } catch (e) {
      debugPrint('❌ Fehler beim Abrufen des Standorts: $e');
      return null;
    }
  }

  /// Mystische Orte in der Nähe finden
  Future<List<Map<String, dynamic>>> findNearbyLocations({
    double radiusKm = 50.0,
    String? world,
  }) async {
    final position = await getCurrentLocation();
    if (position == null) return [];

    final allLocations = _getMysticalLocations();
    final nearby = <Map<String, dynamic>>[];

    for (var location in allLocations) {
      // Filter nach Welt
      if (world != null && location['world'] != world) continue;

      final distance = _calculateDistance(
        position.latitude,
        position.longitude,
        location['latitude'],
        location['longitude'],
      );

      if (distance <= radiusKm) {
        final locationWithDistance = Map<String, dynamic>.from(location);
        locationWithDistance['distance'] = distance;
        locationWithDistance['direction'] = _calculateDirection(
          position.latitude,
          position.longitude,
          location['latitude'],
          location['longitude'],
        );
        nearby.add(locationWithDistance);
      }
    }

    // Sortiere nach Entfernung
    nearby.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

    return nearby;
  }

  /// Entfernung zwischen zwei Koordinaten berechnen (Haversine)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  /// Richtung berechnen (Kompassrichtung)
  String _calculateDirection(double lat1, double lon1, double lat2, double lon2) {
    final dLon = _degreesToRadians(lon2 - lon1);
    final y = sin(dLon) * cos(_degreesToRadians(lat2));
    final x = cos(_degreesToRadians(lat1)) * sin(_degreesToRadians(lat2)) -
        sin(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            cos(dLon);

    final bearing = atan2(y, x);
    final degrees = (_radiansToDegrees(bearing) + 360) % 360;

    // Konvertiere zu Kompassrichtung
    if (degrees >= 337.5 || degrees < 22.5) return 'N';
    if (degrees >= 22.5 && degrees < 67.5) return 'NE';
    if (degrees >= 67.5 && degrees < 112.5) return 'E';
    if (degrees >= 112.5 && degrees < 157.5) return 'SE';
    if (degrees >= 157.5 && degrees < 202.5) return 'S';
    if (degrees >= 202.5 && degrees < 247.5) return 'SW';
    if (degrees >= 247.5 && degrees < 292.5) return 'W';
    return 'NW';
  }

  double _degreesToRadians(double degrees) => degrees * pi / 180;
  double _radiansToDegrees(double radians) => radians * 180 / pi;

  /// Mystische Orte Datenbank
  List<Map<String, dynamic>> _getMysticalLocations() {
    return [
      // MATERIE-Orte
      {
        'id': '1',
        'name': 'Area 51',
        'world': 'materie',
        'type': 'Geheime Militärbasis',
        'latitude': 37.2431,
        'longitude': -115.7930,
        'description': 'Top-Secret Militärbasis, UFO-Forschung',
        'icon': '🛸',
      },
      {
        'id': '2',
        'name': 'Bohemian Grove',
        'world': 'materie',
        'type': 'Geheimtreffen',
        'latitude': 38.4111,
        'longitude': -123.0150,
        'description': 'Treffen der Mächtigen, okkulte Rituale',
        'icon': '👁️',
      },
      
      // ENERGIE-Orte
      {
        'id': '3',
        'name': 'Stonehenge',
        'world': 'energie',
        'type': 'Kraftort',
        'latitude': 51.1789,
        'longitude': -1.8262,
        'description': 'Megalithisches Monument, Ley-Linien Knotenpunkt',
        'icon': '🗿',
      },
      {
        'id': '4',
        'name': 'Machu Picchu',
        'world': 'energie',
        'type': 'Kraftort',
        'latitude': -13.1631,
        'longitude': -72.5450,
        'description': 'Inka-Ruinenstadt, spirituelle Energie',
        'icon': '⛰️',
      },
      {
        'id': '5',
        'name': 'Sedona Vortex',
        'world': 'energie',
        'type': 'Energie-Wirbel',
        'latitude': 34.8697,
        'longitude': -111.7610,
        'description': 'Energiewirbel, Heilung & Meditation',
        'icon': '🌀',
      },
      
      // Deutschland - MATERIE
      {
        'id': '6',
        'name': 'Wewelsburg',
        'world': 'materie',
        'type': 'Okkultes Zentrum',
        'latitude': 51.6067,
        'longitude': 8.6550,
        'description': 'SS-Ordensburg, okkulte NS-Geschichte',
        'icon': '🏰',
      },
      
      // Deutschland - ENERGIE
      {
        'id': '7',
        'name': 'Externsteine',
        'world': 'energie',
        'type': 'Kraftort',
        'latitude': 51.8694,
        'longitude': 8.9169,
        'description': 'Megalithische Felsformation, Ley-Linien',
        'icon': '🪨',
      },
      {
        'id': '8',
        'name': 'Untersberg',
        'world': 'energie',
        'type': 'Mystischer Berg',
        'latitude': 47.7167,
        'longitude': 13.0167,
        'description': 'Zeitanomalien, interdimensionale Portale',
        'icon': '⛰️',
      },
    ];
  }

  /// Orte nach Typ filtern
  List<Map<String, dynamic>> getLocationsByType(String type) {
    return _getMysticalLocations().where((loc) => loc['type'] == type).toList();
  }

  /// Einzelnen Ort abrufen
  Map<String, dynamic>? getLocation(String id) {
    try {
      return _getMysticalLocations().firstWhere((loc) => loc['id'] == id);
    } catch (e) {
      return null;
    }
  }
}
