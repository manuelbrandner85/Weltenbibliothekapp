/// 📍 LIVE MAP PINS SERVICE (Bundle 7 — Materie-USP)
///
/// User markieren Live-Pins auf der Geopolitik-Karte. Pins werden via
/// Supabase Realtime BROADCAST an alle anderen Geräte gesendet — KEINE
/// DB-Persistenz, rein temporär. Pins fadeen nach ~5 Min automatisch aus.
///
/// Use-Case: gemeinsame Live-Diskussion über Orte/Ereignisse, ohne dass
/// die Karte von permanenten User-Pins zugemüllt wird.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LiveMapPin {
  final String id; // unique pro Pin (für Dedup + Auto-Remove)
  final double lat;
  final double lon;
  final String label;
  final String authorName;
  final String? authorAvatarUrl;
  final String world; // 'materie' | 'energie'
  final DateTime createdAt;

  const LiveMapPin({
    required this.id,
    required this.lat,
    required this.lon,
    required this.label,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.world,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'lat': lat,
        'lon': lon,
        'label': label,
        'author_name': authorName,
        'author_avatar_url': authorAvatarUrl,
        'world': world,
        'created_at': createdAt.toIso8601String(),
      };

  static LiveMapPin? fromJson(Map<String, dynamic> json) {
    try {
      return LiveMapPin(
        id: json['id']?.toString() ?? '',
        lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
        lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
        label: json['label']?.toString() ?? '',
        authorName: json['author_name']?.toString() ?? 'Anonym',
        authorAvatarUrl: json['author_avatar_url']?.toString(),
        world: json['world']?.toString() ?? 'materie',
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('LiveMapPin.fromJson parse error: $e');
      return null;
    }
  }
}

class LiveMapPinsService {
  LiveMapPinsService._();
  static final instance = LiveMapPinsService._();

  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, StreamController<List<LiveMapPin>>> _ctrls = {};
  final Map<String, List<LiveMapPin>> _pinsByWorld = {};
  final Map<String, Timer> _expiryTimers = {};

  /// Auto-Expiry: Pins älter als 5 Min werden entfernt.
  static const Duration _pinTtl = Duration(minutes: 5);

  /// Stream der aktuellen Live-Pins für eine Welt.
  /// Erste Subscription öffnet einen Realtime-Channel.
  Stream<List<LiveMapPin>> streamPinsForWorld(String world) {
    final ctrl = _ctrls.putIfAbsent(world, () {
      _subscribeChannel(world);
      return StreamController<List<LiveMapPin>>.broadcast(
        onCancel: () => _maybeUnsubscribe(world),
      );
    });
    // Initial state pushen (leere Liste zur Subscription)
    Future.microtask(() {
      ctrl.add(_pinsByWorld[world] ?? const []);
    });
    return ctrl.stream;
  }

  void _subscribeChannel(String world) {
    if (_channels.containsKey(world)) return;
    try {
      final channel = Supabase.instance.client.channel('wb-live-pins-$world');
      channel.onBroadcast(
        event: 'pin',
        callback: (payload) {
          final raw = payload;
          // Supabase liefert je nach Version entweder das Event als Map
          // oder als wrapped {'event': 'pin', 'payload': {...}}.
          final data = raw['payload'] is Map
              ? Map<String, dynamic>.from(raw['payload'] as Map)
              : Map<String, dynamic>.from(raw);
          final pin = LiveMapPin.fromJson(data);
          if (pin != null) _addOrReplacePin(world, pin);
        },
      );
      channel.subscribe();
      _channels[world] = channel;
      if (kDebugMode) debugPrint('📍 Live-Pins subscribed: $world');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Live-Pins channel subscribe failed: $e');
    }
  }

  void _maybeUnsubscribe(String world) {
    final ctrl = _ctrls[world];
    if (ctrl == null || ctrl.hasListener) return;
    final ch = _channels.remove(world);
    if (ch != null) {
      try {
        Supabase.instance.client.removeChannel(ch);
      } catch (_) {}
    }
    _ctrls.remove(world)?.close();
    _pinsByWorld.remove(world);
  }

  void _addOrReplacePin(String world, LiveMapPin pin) {
    final list = _pinsByWorld.putIfAbsent(world, () => <LiveMapPin>[]);
    list.removeWhere((p) => p.id == pin.id); // dedup
    list.add(pin);
    _pruneExpired(world);
    _ctrls[world]?.add(List.unmodifiable(list));
    _scheduleExpiryCheck(world);
  }

  void _pruneExpired(String world) {
    final list = _pinsByWorld[world];
    if (list == null) return;
    final cutoff = DateTime.now().subtract(_pinTtl);
    list.removeWhere((p) => p.createdAt.isBefore(cutoff));
  }

  void _scheduleExpiryCheck(String world) {
    _expiryTimers[world]?.cancel();
    _expiryTimers[world] = Timer(const Duration(seconds: 30), () {
      _pruneExpired(world);
      _ctrls[world]?.add(List.unmodifiable(_pinsByWorld[world] ?? const []));
      if ((_pinsByWorld[world]?.isNotEmpty ?? false)) {
        _scheduleExpiryCheck(world);
      }
    });
  }

  /// Sendet einen Live-Pin an alle Geräte in der gleichen Welt.
  /// Selbst-Echo: der eigene Pin wird auch lokal angezeigt (ohne Round-Trip).
  Future<void> sendPin({
    required String world,
    required double lat,
    required double lon,
    required String label,
    required String authorName,
    String? authorAvatarUrl,
  }) async {
    // Sicherstellen dass wir subscribed sind (sonst kein lokales Echo)
    _subscribeChannel(world);
    final pin = LiveMapPin(
      id: '${DateTime.now().microsecondsSinceEpoch}_${authorName.hashCode}',
      lat: lat,
      lon: lon,
      label: label,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      world: world,
      createdAt: DateTime.now(),
    );
    final ch = _channels[world];
    if (ch != null) {
      try {
        await ch.sendBroadcastMessage(event: 'pin', payload: pin.toJson());
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ sendPin broadcast failed: $e');
      }
    }
    // Selbst-Echo damit Sender den Pin sofort sieht (broadcast schickt
    // typischerweise NICHT an den Sender selbst zurück)
    _addOrReplacePin(world, pin);
  }
}
