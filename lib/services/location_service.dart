import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/event_model.dart';

/// Service für GPS-basierte Location-Funktionen
///
/// Ermöglicht:
/// - GPS-Position abrufen
/// - Distanzberechnung zu Events
/// - Events im Umkreis finden (50km Radius)
/// - Berechtigungen verwalten
class LocationService {
  static const double nearbyRadiusKm = 50.0; // 50km Radius für "in der Nähe"

  /// Hole aktuelle GPS-Position des Benutzers
  ///
  /// Returns: Position mit Latitude/Longitude oder null bei Fehler
  Future<Position?> getCurrentPosition() async {
    try {
      // Prüfe ob Location Services aktiviert sind
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Prüfe Berechtigungen
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Hole Position mit hoher Genauigkeit
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  /// Berechne Distanz zwischen zwei Koordinaten in Kilometern
  ///
  /// Verwendet die Haversine-Formel für präzise Berechnung
  double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadiusKm = 6371.0;

    double lat1Rad = _degreesToRadians(point1.latitude);
    double lat2Rad = _degreesToRadians(point2.latitude);
    double deltaLatRad = _degreesToRadians(point2.latitude - point1.latitude);
    double deltaLonRad = _degreesToRadians(point2.longitude - point1.longitude);

    double a =
        sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLonRad / 2) *
            sin(deltaLonRad / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Finde alle Events im Umkreis von 50km
  ///
  /// [userPosition] - Aktuelle Position des Benutzers
  /// [allEvents] - Liste aller verfügbaren Events
  ///
  /// Returns: Liste von Events mit Distanzinformation
  Future<List<EventWithDistance>> findNearbyEvents(
    Position userPosition,
    List<EventModel> allEvents,
  ) async {
    final userLatLng = LatLng(userPosition.latitude, userPosition.longitude);
    final nearbyEvents = <EventWithDistance>[];

    for (final event in allEvents) {
      final distance = calculateDistance(userLatLng, event.location);

      if (distance <= nearbyRadiusKm) {
        nearbyEvents.add(EventWithDistance(event: event, distanceKm: distance));
      }
    }

    // Sortiere nach Distanz (nächste zuerst)
    nearbyEvents.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return nearbyEvents;
  }

  /// Finde das nächstgelegene Event
  Future<EventWithDistance?> findNearestEvent(
    Position userPosition,
    List<EventModel> allEvents,
  ) async {
    if (allEvents.isEmpty) return null;

    final userLatLng = LatLng(userPosition.latitude, userPosition.longitude);
    EventWithDistance? nearest;
    double minDistance = double.infinity;

    for (final event in allEvents) {
      final distance = calculateDistance(userLatLng, event.location);

      if (distance < minDistance) {
        minDistance = distance;
        nearest = EventWithDistance(event: event, distanceKm: distance);
      }
    }

    return nearest;
  }

  /// Prüfe ob Berechtigungen erteilt wurden
  Future<LocationPermissionStatus> checkPermissionStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    switch (permission) {
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return LocationPermissionStatus.granted;
      default:
        return LocationPermissionStatus.denied;
    }
  }

  /// Fordere Location-Berechtigungen an
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Öffne App-Einstellungen für manuelle Berechtigung
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Formatiere Distanz für Anzeige
  String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceKm.round()} km';
    }
  }

  /// Bestimme ob Event "in der Nähe" ist (< 50km)
  bool isNearby(double distanceKm) {
    return distanceKm <= nearbyRadiusKm;
  }

  /// Hilfsfunktion: Grad zu Radiant
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }
}

/// Event mit Distanzinformation
class EventWithDistance {
  final EventModel event;
  final double distanceKm;

  EventWithDistance({required this.event, required this.distanceKm});

  /// Formatierte Distanz für UI
  String get formattedDistance {
    final service = LocationService();
    return service.formatDistance(distanceKm);
  }

  /// Ist das Event in der Nähe? (< 50km)
  bool get isNearby {
    return distanceKm <= LocationService.nearbyRadiusKm;
  }
}

/// Status der Location-Berechtigung
enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}
