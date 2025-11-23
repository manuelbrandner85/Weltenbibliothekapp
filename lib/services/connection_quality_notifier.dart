import 'package:flutter/material.dart';
import '../models/room_connection_state.dart';
import 'bandwidth_monitor.dart';

/// ═══════════════════════════════════════════════════════════════
/// CONNECTION QUALITY NOTIFIER - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// Automatically shows toast notifications when connection quality degrades
/// - Monitors connection quality changes
/// - Shows warnings for Poor/Critical quality
/// - Provides recommendations for improving quality
/// - Auto-dismisses warnings when quality improves
/// ═══════════════════════════════════════════════════════════════

class ConnectionQualityNotifier {
  final BandwidthMonitor _bandwidthMonitor;
  final Map<String, ConnectionQuality> _lastQualityState = {};
  final Map<String, DateTime> _lastWarningTime = {};

  // Prevent warning spam (minimum 30 seconds between warnings for same peer)
  static const Duration warningCooldown = Duration(seconds: 30);

  // Auto-dismiss warnings after quality improves for this duration
  static const Duration improvementDelay = Duration(seconds: 5);

  ConnectionQualityNotifier(this._bandwidthMonitor) {
    _bandwidthMonitor.addListener(_onQualityChanged);
  }

  void dispose() {
    _bandwidthMonitor.removeListener(_onQualityChanged);
  }

  void _onQualityChanged() {
    // Check each room's connection quality
    for (final roomId in _bandwidthMonitor.activeRoomIds) {
      final roomStats = _bandwidthMonitor.getRoomStats(roomId);

      if (roomStats == null) continue;

      // Check overall room quality
      _checkRoomQuality(roomId, roomStats);

      // Check individual peer connections
      for (final entry in roomStats.connectionStats.entries) {
        _checkPeerQuality(roomId, entry.key, entry.value);
      }
    }
  }

  void _checkRoomQuality(String roomId, RoomStats stats) {
    final currentQuality = stats.averageQuality;
    final key = 'room_$roomId';
    final lastQuality = _lastQualityState[key];

    // Quality degraded
    if (lastQuality != null &&
        currentQuality.index > lastQuality.index &&
        (currentQuality == ConnectionQuality.poor ||
            currentQuality == ConnectionQuality.critical)) {
      _showQualityWarning(
        key: key,
        title: 'Verbindungsqualität verschlechtert',
        message: _getRoomQualityMessage(stats),
        quality: currentQuality,
      );
    }

    // Quality improved
    if (lastQuality != null &&
        currentQuality.index < lastQuality.index &&
        lastQuality == ConnectionQuality.critical) {
      _showQualityImprovement(
        key: key,
        message: 'Verbindungsqualität verbessert sich',
      );
    }

    _lastQualityState[key] = currentQuality;
  }

  void _checkPeerQuality(String roomId, String peerId, ConnectionStats stats) {
    final currentQuality = stats.quality;
    final key = 'peer_${roomId}_$peerId';
    final lastQuality = _lastQualityState[key];

    // Quality degraded
    if (lastQuality != null &&
        currentQuality.index > lastQuality.index &&
        currentQuality == ConnectionQuality.critical) {
      _showQualityWarning(
        key: key,
        title: 'Kritische Verbindung erkannt',
        message: _getPeerQualityMessage(peerId, stats),
        quality: currentQuality,
      );
    }

    _lastQualityState[key] = currentQuality;
  }

  String _getRoomQualityMessage(RoomStats stats) {
    final issues = <String>[];

    if (stats.averageRttMs > 500) {
      issues.add('Hohe Latenz (${stats.averageRttMs}ms)');
    }

    if (stats.averagePacketLoss > 10) {
      issues.add(
        'Paketverlustt (${stats.averagePacketLoss.toStringAsFixed(1)}%)',
      );
    }

    if (stats.totalBandwidthMbps < 0.5) {
      issues.add('Niedrige Bandbreite');
    }

    final recommendation = _getQualityRecommendation(stats.averageQuality);

    return '${issues.join(', ')}\n\n$recommendation';
  }

  String _getPeerQualityMessage(String peerId, ConnectionStats stats) {
    final issues = <String>[];

    if (stats.rttMs > 1000) {
      issues.add('Sehr hohe Latenz (${stats.rttMs}ms)');
    }

    if (stats.packetLoss > 20) {
      issues.add(
        'Hoher Paketverlust (${stats.packetLoss.toStringAsFixed(1)}%)',
      );
    }

    final recommendation = _getQualityRecommendation(stats.quality);

    return 'Verbindung zu $peerId:\n${issues.join(', ')}\n\n$recommendation';
  }

  String _getQualityRecommendation(ConnectionQuality quality) {
    switch (quality) {
      case ConnectionQuality.critical:
        return '💡 Tipp: Näher zum WLAN-Router gehen oder zu mobilen Daten wechseln';
      case ConnectionQuality.poor:
        return '💡 Tipp: Andere Apps schließen um Bandbreite freizugeben';
      case ConnectionQuality.good:
        return '✅ Verbindungsqualität ist akzeptabel';
      case ConnectionQuality.excellent:
        return '✅ Optimale Verbindungsqualität';
      case ConnectionQuality.unknown:
        return '';
    }
  }

  void _showQualityWarning({
    required String key,
    required String title,
    required String message,
    required ConnectionQuality quality,
  }) {
    // Check cooldown
    final lastWarning = _lastWarningTime[key];
    if (lastWarning != null &&
        DateTime.now().difference(lastWarning) < warningCooldown) {
      return; // Skip warning (cooldown active)
    }

    _lastWarningTime[key] = DateTime.now();

    // This will be called from UI context
    // Store warning for later display
    _pendingWarnings[key] = QualityWarning(
      title: title,
      message: message,
      quality: quality,
      timestamp: DateTime.now(),
    );
  }

  void _showQualityImprovement({required String key, required String message}) {
    // Remove pending warning if exists
    _pendingWarnings.remove(key);

    // Store improvement notification
    _pendingImprovements[key] = QualityImprovement(
      message: message,
      timestamp: DateTime.now(),
    );
  }

  // Pending warnings/improvements for UI to consume
  final Map<String, QualityWarning> _pendingWarnings = {};
  final Map<String, QualityImprovement> _pendingImprovements = {};

  /// Get and clear pending warnings
  List<QualityWarning> consumeWarnings() {
    final warnings = _pendingWarnings.values.toList();
    _pendingWarnings.clear();
    return warnings;
  }

  /// Get and clear pending improvements
  List<QualityImprovement> consumeImprovements() {
    final improvements = _pendingImprovements.values.toList();
    _pendingImprovements.clear();
    return improvements;
  }

  /// Check if there are pending notifications
  bool get hasPendingNotifications =>
      _pendingWarnings.isNotEmpty || _pendingImprovements.isNotEmpty;
}

class QualityWarning {
  final String title;
  final String message;
  final ConnectionQuality quality;
  final DateTime timestamp;

  QualityWarning({
    required this.title,
    required this.message,
    required this.quality,
    required this.timestamp,
  });

  Color get backgroundColor {
    switch (quality) {
      case ConnectionQuality.critical:
        return Colors.red;
      case ConnectionQuality.poor:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (quality) {
      case ConnectionQuality.critical:
        return Icons.warning_amber_rounded;
      case ConnectionQuality.poor:
        return Icons.info_outline;
      default:
        return Icons.signal_cellular_alt;
    }
  }
}

class QualityImprovement {
  final String message;
  final DateTime timestamp;

  QualityImprovement({required this.message, required this.timestamp});
}
