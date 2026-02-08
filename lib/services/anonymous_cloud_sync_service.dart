/// Anonymous Cloud Sync Service
/// Sync data without user authentication using device ID
library;

import 'dart:async';
import '../config/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'spirit_journal_service.dart';
import 'synchronicity_service.dart';

/// Anonymous Cloud Sync Service Singleton
class AnonymousCloudSyncService {
  static final AnonymousCloudSyncService _instance = AnonymousCloudSyncService._internal();
  factory AnonymousCloudSyncService() => _instance;
  AnonymousCloudSyncService._internal();

  final SpiritJournalService _journalService = SpiritJournalService();
  final SynchronicityService _syncService = SynchronicityService();
  final http.Client _client = http.Client();

  /// CLOUDFLARE WORKER URL (DEPLOYED)
  static String get baseUrl => ApiConfig.cloudSyncApiUrl;
  
  /// Device ID (anonymous identifier)
  String? _deviceId;
  String? get deviceId => _deviceId;

  /// Sync status stream
  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  /// Current sync status
  SyncStatus _currentStatus = SyncStatus.idle;
  SyncStatus get currentStatus => _currentStatus;

  /// Last sync timestamp
  DateTime? _lastSyncAt;
  DateTime? get lastSyncAt => _lastSyncAt;

  /// Auto-sync enabled
  bool _autoSyncEnabled = false; // Disabled by default (optional feature)
  bool get autoSyncEnabled => _autoSyncEnabled;

  /// Auto-sync timer
  Timer? _autoSyncTimer;

  /// Cloud sync available (backend deployed)
  bool _cloudSyncAvailable = false;
  bool get cloudSyncAvailable => _cloudSyncAvailable;

  /// Offline Queue for pending syncs
  final List<Map<String, dynamic>> _pendingSyncs = [];
  int get pendingSyncCount => _pendingSyncs.length;
  
  /// Network status (simplified - will be enhanced)
  final bool _isOnline = true;
  bool get isOnline => _isOnline;

  // ============================================
  // INITIALIZATION
  // ============================================

  /// Initialize sync service
  Future<void> init() async {
    try {
      await _loadOrCreateDeviceId();
      await _loadLastSyncTime();
      await _loadPendingSyncs();
      await _checkCloudAvailability();

      if (kDebugMode) {
        debugPrint('☁️ AnonymousCloudSyncService initialized');
        debugPrint('   Device ID: $_deviceId');
        debugPrint('   Last sync: ${_lastSyncAt ?? 'Never'}');
        debugPrint('   Cloud available: $_cloudSyncAvailable');
        debugPrint('   Auto-sync: $_autoSyncEnabled');
        debugPrint('   Pending syncs: ${_pendingSyncs.length}');
      }

      // Process pending syncs if cloud available
      if (_cloudSyncAvailable && _pendingSyncs.isNotEmpty) {
        _processPendingSyncs();
      }

      // Start auto-sync if enabled and cloud available
      if (_autoSyncEnabled && _cloudSyncAvailable) {
        _startAutoSync();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ AnonymousCloudSyncService init error: $e');
      }
    }
  }

  /// Load or create device ID
  Future<void> _loadOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('device_id');
    
    if (_deviceId == null) {
      // Generate anonymous device ID
      _deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
      await prefs.setString('device_id', _deviceId!);
      
      if (kDebugMode) {
        debugPrint('✅ Generated new device ID: $_deviceId');
      }
    }
  }

  /// Generate random string
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(length, (index) => chars[(DateTime.now().millisecondsSinceEpoch + index) % chars.length]).join();
  }

  /// Load last sync time from storage
  Future<void> _loadLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString('last_cloud_sync_at');
      if (timestamp != null) {
        _lastSyncAt = DateTime.parse(timestamp);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to load last sync time: $e');
      }
    }
  }

  /// Save last sync time
  Future<void> _saveLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_cloud_sync_at', DateTime.now().toIso8601String());
      _lastSyncAt = DateTime.now();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to save last sync time: $e');
      }
    }
  }

  /// Check if cloud backend is available
  Future<void> _checkCloudAvailability() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 3));
      
      _cloudSyncAvailable = response.statusCode == 200;
    } catch (e) {
      _cloudSyncAvailable = false;
      if (kDebugMode) {
        debugPrint('⚠️ Cloud backend not available (this is optional)');
      }
    }
  }

  // ============================================
  // AUTO SYNC (OPTIONAL FEATURE)
  // ============================================

  /// Start auto-sync (every 10 minutes)
  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      if (_cloudSyncAvailable) {
        sync();
      }
    });

    if (kDebugMode) {
      debugPrint('🔄 Auto-sync started (every 10 minutes)');
    }
  }

  /// Stop auto-sync
  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    _autoSyncEnabled = false;

    if (kDebugMode) {
      debugPrint('⏸️ Auto-sync stopped');
    }
  }

  /// Enable auto-sync (if user wants cloud backup)
  void enableAutoSync() {
    _autoSyncEnabled = true;
    if (_cloudSyncAvailable) {
      _startAutoSync();
    }
  }

  // ============================================
  // SYNC OPERATIONS (OPTIONAL - ONLY IF BACKEND DEPLOYED)
  // ============================================

  /// Full sync (backup to cloud)
  Future<SyncResult> sync() async {
    if (!_cloudSyncAvailable) {
      return SyncResult(
        success: false,
        message: 'Cloud backup nicht verfügbar (optional)',
      );
    }

    if (_currentStatus == SyncStatus.syncing) {
      if (kDebugMode) {
        debugPrint('⚠️ Sync already in progress');
      }
      return SyncResult(
        success: false,
        message: 'Sync bereits aktiv',
      );
    }

    _updateStatus(SyncStatus.syncing);

    try {
      int uploadCount = 0;

      // Upload local data as backup (no download - local data is source of truth)
      if (kDebugMode) {
        debugPrint('☁️ Uploading local data as backup...');
      }
      uploadCount = await _uploadLocalDataAsBackup();

      await _saveLastSyncTime();
      _updateStatus(SyncStatus.success);

      if (kDebugMode) {
        debugPrint('✅ Backup completed: ↑$uploadCount');
      }

      return SyncResult(
        success: true,
        message: 'Backup erfolgreich',
        uploadedCount: uploadCount,
      );
    } catch (e) {
      _updateStatus(SyncStatus.error);

      // Add to offline queue if network error
      if (e.toString().contains('SocketException') || 
          e.toString().contains('TimeoutException') ||
          e.toString().contains('Failed host lookup')) {
        
        final backupData = {
          'device_id': _deviceId,
          'timestamp': DateTime.now().toIso8601String(),
          'journal_entries': _journalService.entries.map((e) => e.toJson()).toList(),
          'sync_entries': _syncService.entries.map((e) => e.toJson()).toList(),
        };
        
        await _addToPendingQueue({
          'data': backupData,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        return SyncResult(
          success: false,
          message: 'Offline - zur Warteschlange hinzugefügt',
        );
      }

      if (kDebugMode) {
        debugPrint('❌ Backup error: $e');
      }

      return SyncResult(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Upload local data as backup (simplified - for optional cloud backup)
  Future<int> _uploadLocalDataAsBackup() async {
    int count = 0;

    try {
      // Build backup data
      final backupData = {
        'device_id': _deviceId,
        'timestamp': DateTime.now().toIso8601String(),
        'journal_entries': _journalService.entries.map((e) => e.toJson()).toList(),
        'sync_entries': _syncService.entries.map((e) => e.toJson()).toList(),
      };

      // Upload to cloud (if backend is deployed)
      final response = await _client.post(
        Uri.parse('$baseUrl/api/backup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(backupData),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        count = (_journalService.entries.length + _syncService.entries.length);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Backup upload failed: $e');
      }
      rethrow;
    }

    return count;
  }

  /// Update sync status
  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  // ============================================
  // OFFLINE QUEUE MANAGEMENT
  // ============================================

  /// Load pending syncs from storage
  Future<void> _loadPendingSyncs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncsJson = prefs.getStringList('pending_syncs') ?? [];
      
      _pendingSyncs.clear();
      for (final syncStr in syncsJson) {
        _pendingSyncs.add(jsonDecode(syncStr));
      }
      
      if (kDebugMode && _pendingSyncs.isNotEmpty) {
        debugPrint('📦 Loaded ${_pendingSyncs.length} pending syncs from queue');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to load pending syncs: $e');
      }
    }
  }

  /// Save pending syncs to storage
  Future<void> _savePendingSyncs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncsJson = _pendingSyncs.map((s) => jsonEncode(s)).toList();
      await prefs.setStringList('pending_syncs', syncsJson);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to save pending syncs: $e');
      }
    }
  }

  /// Add sync to offline queue
  Future<void> _addToPendingQueue(Map<String, dynamic> syncData) async {
    _pendingSyncs.add(syncData);
    await _savePendingSyncs();
    
    if (kDebugMode) {
      debugPrint('➕ Added to offline queue (total: ${_pendingSyncs.length})');
    }
  }

  /// Process pending syncs (when online)
  Future<void> _processPendingSyncs() async {
    if (_pendingSyncs.isEmpty || !_cloudSyncAvailable) {
      return;
    }

    if (kDebugMode) {
      debugPrint('⚙️ Processing ${_pendingSyncs.length} pending syncs...');
    }

    final syncsToProcess = List<Map<String, dynamic>>.from(_pendingSyncs);
    int successCount = 0;

    for (final syncData in syncsToProcess) {
      try {
        // Generate backup code if not present
        final backupCode = syncData['backup_code'] ?? _generateRandomString(6);
        
        final response = await _client.post(
          Uri.parse('$baseUrl/api/backup'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'device_id': _deviceId,
            'backup_code': backupCode,
            'data': syncData['data'],
            'timestamp': syncData['timestamp'],
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          _pendingSyncs.remove(syncData);
          successCount++;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to process pending sync: $e');
        }
        // Keep in queue for retry
      }
    }

    await _savePendingSyncs();

    if (kDebugMode) {
      debugPrint('✅ Processed $successCount pending syncs (remaining: ${_pendingSyncs.length})');
    }
  }

  /// Retry failed syncs (manual trigger)
  Future<SyncResult> retryPendingSyncs() async {
    if (_pendingSyncs.isEmpty) {
      return SyncResult(
        success: false,
        message: 'Keine ausstehenden Syncs',
      );
    }

    if (!_cloudSyncAvailable) {
      return SyncResult(
        success: false,
        message: 'Cloud nicht verfügbar',
      );
    }

    final initialCount = _pendingSyncs.length;
    await _processPendingSyncs();
    final processedCount = initialCount - _pendingSyncs.length;

    return SyncResult(
      success: processedCount > 0,
      message: '$processedCount von $initialCount Syncs erfolgreich',
      uploadedCount: processedCount,
    );
  }

  /// Clear all pending syncs (manual clear)
  Future<void> clearPendingSyncs() async {
    _pendingSyncs.clear();
    await _savePendingSyncs();
    
    if (kDebugMode) {
      debugPrint('🗑️ Cleared all pending syncs');
    }
  }

  /// Dispose
  void dispose() {
    _autoSyncTimer?.cancel();
    _statusController.close();
  }
}

/// Sync Status
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

/// Sync Result
class SyncResult {
  final bool success;
  final String message;
  final int uploadedCount;
  final int downloadedCount;

  SyncResult({
    required this.success,
    required this.message,
    this.uploadedCount = 0,
    this.downloadedCount = 0,
  });

  @override
  String toString() =>
      'SyncResult(success: $success, message: $message, ↑$uploadedCount ↓$downloadedCount)';
}
