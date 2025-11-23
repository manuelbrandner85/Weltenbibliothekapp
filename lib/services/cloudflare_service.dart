import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../data/mystical_events_data.dart';

/// Cloudflare D1 Database & Workers API Service
class CloudflareService {
  // Cloudflare Workers API-Endpunkt (wird über Environment Variable gesetzt)
  static const String _baseUrl = String.fromEnvironment(
    'CLOUDFLARE_API_URL',
    defaultValue: 'https://weltenbibliothek-api.pages.dev',
  );

  static const String _apiKey = String.fromEnvironment(
    'CLOUDFLARE_API_KEY',
    defaultValue: 'demo_key_12345',
  );

  final http.Client _client;

  CloudflareService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_apiKey',
  };

  /// Alle Events abrufen
  Future<List<EventModel>> getEvents({
    String? category,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (category != null) 'category': category,
      };

      final uri = Uri.parse(
        '$_baseUrl/api/events',
      ).replace(queryParameters: queryParams);

      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final eventsJson = data['events'] as List<dynamic>;
        return eventsJson
            .map((json) => EventModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching events: $e');
      }
      // Fallback zu Mock-Daten wenn API nicht erreichbar
      return _getMockEvents();
    }
  }

  /// Event nach ID abrufen
  Future<EventModel> getEventById(String id) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/events/$id');
      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return EventModel.fromJson(data['event'] as Map<String, dynamic>);
      } else {
        throw Exception('Failed to load event: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching event $id: $e');
      }
      rethrow;
    }
  }

  /// Neues Event erstellen
  Future<EventModel> createEvent(EventModel event) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/events');
      final response = await _client.post(
        uri,
        headers: _headers,
        body: json.encode(event.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return EventModel.fromJson(data['event'] as Map<String, dynamic>);
      } else {
        throw Exception('Failed to create event: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating event: $e');
      }
      rethrow;
    }
  }

  /// Event aktualisieren
  Future<EventModel> updateEvent(EventModel event) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/events/${event.id}');
      final response = await _client.put(
        uri,
        headers: _headers,
        body: json.encode(event.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return EventModel.fromJson(data['event'] as Map<String, dynamic>);
      } else {
        throw Exception('Failed to update event: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating event: $e');
      }
      rethrow;
    }
  }

  /// Event löschen
  Future<void> deleteEvent(String id) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/events/$id');
      final response = await _client.delete(uri, headers: _headers);

      if (response.statusCode != 204) {
        throw Exception('Failed to delete event: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting event $id: $e');
      }
      rethrow;
    }
  }

  /// Events in einem geografischen Bereich suchen
  Future<List<EventModel>> getEventsInBounds({
    required double northLat,
    required double southLat,
    required double eastLng,
    required double westLng,
  }) async {
    try {
      final queryParams = {
        'north': northLat.toString(),
        'south': southLat.toString(),
        'east': eastLng.toString(),
        'west': westLng.toString(),
      };

      final uri = Uri.parse(
        '$_baseUrl/api/events/bounds',
      ).replace(queryParameters: queryParams);

      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final eventsJson = data['events'] as List<dynamic>;
        return eventsJson
            .map((json) => EventModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Failed to load events in bounds: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching events in bounds: $e');
      }
      return _getMockEvents();
    }
  }

  /// Mock-Daten für Offline/Fallback - nutzt mystische Events Datenbank
  List<EventModel> _getMockEvents() {
    // Import der lokalen Datenbank
    return MysticalEventsData.getAllEvents();

    /* Alte Mock-Daten (werden ersetzt durch MysticalEventsData):
    return [
    */
  }

  void dispose() {
    _client.close();
  }
}
