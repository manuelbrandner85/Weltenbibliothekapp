/// 📴 WELTENBIBLIOTHEK - OFFLINE SYNC SERVICE (SQLite)
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import '../core/db/app_database.dart';
import '../services/error_reporting_service.dart';
import '../services/cloudflare_api_service.dart';

/// Offline Action Type
enum OfflineActionType {
  sendMessage,
  editMessage,
  deleteMessage,
  uploadFile,
  updateProfile,
  createPost,
  updatePost,
  deletePost,
}

/// Offline Action
class OfflineAction {
  final String id;
  final OfflineActionType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;
  final String? userId;

  OfflineAction({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
    this.userId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'retryCount': retryCount,
    'userId': userId,
  };

  factory OfflineAction.fromJson(Map<String, dynamic> json) => OfflineAction(
    id: json['id'] as String,
    type: OfflineActionType.values.firstWhere(
      (e) => e.toString() == json['type'],
    ),
    data: json['data'] as Map<String, dynamic>,
    timestamp: DateTime.parse(json['timestamp'] as String),
    retryCount: json['retryCount'] as int? ?? 0,
    userId: json['userId'] as String?,
  );

  OfflineAction copyWith({int? retryCount}) => OfflineAction(
    id: id,
    type: type,
    data: data,
    timestamp: timestamp,
    retryCount: retryCount ?? this.retryCount,
    userId: userId,
  );
}

/// Network State
enum NetworkState { online, offline, unknown }

/// Offline Sync Service (SQLite-backed)
class OfflineSyncService extends ChangeNotifier {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  NetworkState _networkState = NetworkState.unknown;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  int _pendingActions = 0;

  final _networkStateController    = StreamController<NetworkState>.broadcast();
  final _syncStatusController      = StreamController<bool>.broadcast();
  final _pendingActionsController  = StreamController<int>.broadcast();

  Stream<NetworkState> get networkStateStream   => _networkStateController.stream;
  Stream<bool>         get syncStatusStream      => _syncStatusController.stream;
  Stream<int>          get pendingActionsStream  => _pendingActionsController.stream;

  NetworkState get networkState      => _networkState;
  bool         get isOnline          => _networkState == NetworkState.online;
  bool         get isOffline         => _networkState == NetworkState.offline;
  bool         get isSyncing         => _isSyncing;
  DateTime?    get lastSyncTime      => _lastSyncTime;
  int          get pendingActionsCount => _pendingActions;

  static const int _maxRetryAttempts = 3;
  static const Duration _syncInterval = Duration(seconds: 30);
  Timer? _syncTimer;

  // ──────────────────────────────────────────────────────
  // INIT
  // ──────────────────────────────────────────────────────

  Future<void> initialize() async {
    try {
      if (kDebugMode) debugPrint('📴 OfflineSync: Initializing...');

      final db = await AppDatabase.instance.db;

      // Pending count
      final countResult = await db.rawQuery(
          'SELECT COUNT(*) as c FROM offline_actions');
      _pendingActions = (countResult.first['c'] as int?) ?? 0;
      _pendingActionsController.add(_pendingActions);

      // Last sync time
      final kv = await db.query('kv_store',
          where: 'key = ?', whereArgs: ['last_sync_time']);
      if (kv.isNotEmpty) {
        _lastSyncTime = DateTime.tryParse(kv.first['value'] as String);
      }

      await _setupNetworkMonitoring();
      _startPeriodicSync();

      if (kDebugMode) {
        debugPrint('✅ OfflineSync: Initialized, pending: $_pendingActions');
      }
    } catch (e, stack) {
      if (kDebugMode) debugPrint('❌ OfflineSync: Initialization failed - $e');
      ErrorReportingService().reportError(
          error: e, stackTrace: stack, context: 'Offline Sync - Initialize');
    }
  }

  // ──────────────────────────────────────────────────────
  // NETWORK
  // ──────────────────────────────────────────────────────

  Future<void> _setupNetworkMonitoring() async {
    try {
      _updateNetworkState(await _connectivity.checkConnectivity());
      _connectivitySubscription = _connectivity.onConnectivityChanged
          .listen(_updateNetworkState);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ OfflineSync: Network setup failed - $e');
    }
  }

  void _updateNetworkState(List<ConnectivityResult> results) {
    final hasConn = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
    final newState = hasConn ? NetworkState.online : NetworkState.offline;
    if (_networkState != newState) {
      _networkState = newState;
      _networkStateController.add(_networkState);
      notifyListeners();
      if (kDebugMode) {
        debugPrint('🌐 OfflineSync: Network → ${_networkState.name}');
      }
      if (_networkState == NetworkState.online && _pendingActions > 0) {
        syncPendingActions();
      }
    }
  }

  // ──────────────────────────────────────────────────────
  // QUEUE
  // ──────────────────────────────────────────────────────

  Future<String> queueAction({
    required OfflineActionType type,
    required Map<String, dynamic> data,
    String? userId,
  }) async {
    try {
      final action = OfflineAction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        data: data,
        timestamp: DateTime.now(),
        userId: userId,
      );
      final db = await AppDatabase.instance.db;
      await db.insert('offline_actions', {
        'id': action.id,
        'type': action.type.toString(),
        'data': jsonEncode(action.data),
        'timestamp': action.timestamp.toIso8601String(),
        'retry_count': action.retryCount,
        'user_id': action.userId,
      });
      _pendingActions++;
      _pendingActionsController.add(_pendingActions);
      notifyListeners();
      if (kDebugMode) debugPrint('📥 OfflineSync: Queued ${type.name}');
      if (isOnline) syncPendingActions();
      return action.id;
    } catch (e, stack) {
      if (kDebugMode) debugPrint('❌ OfflineSync: queueAction failed - $e');
      ErrorReportingService().reportError(
          error: e, stackTrace: stack, context: 'Offline Sync - Queue Action');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────
  // SYNC
  // ──────────────────────────────────────────────────────

  Future<void> syncPendingActions() async {
    if (_isSyncing || !isOnline || _pendingActions == 0) return;
    try {
      _isSyncing = true;
      _syncStatusController.add(true);
      notifyListeners();
      if (kDebugMode) {
        debugPrint('🔄 OfflineSync: Syncing $_pendingActions actions...');
      }

      final db = await AppDatabase.instance.db;
      final rows = await db.query('offline_actions', orderBy: 'timestamp ASC');
      int ok = 0, fail = 0;

      for (final row in rows) {
        try {
          final action = OfflineAction.fromJson({
            'id': row['id'],
            'type': row['type'],
            'data': jsonDecode(row['data'] as String),
            'timestamp': row['timestamp'],
            'retryCount': row['retry_count'],
            'userId': row['user_id'],
          });
          final success = await _executeAction(action);
          if (success) {
            await db.delete('offline_actions',
                where: 'id = ?', whereArgs: [action.id]);
            ok++;
          } else {
            final retries = action.retryCount + 1;
            if (retries >= _maxRetryAttempts) {
              await db.delete('offline_actions',
                  where: 'id = ?', whereArgs: [action.id]);
              fail++;
              ErrorReportingService().reportError(
                error: 'Offline action max retries exceeded',
                context: 'Offline Sync - Max Retries',
                additionalData: {'action_type': action.type.name},
              );
            } else {
              await db.update('offline_actions', {'retry_count': retries},
                  where: 'id = ?', whereArgs: [action.id]);
            }
          }
        } catch (e) {
          if (kDebugMode) debugPrint('❌ OfflineSync: action error - $e');
          fail++;
        }
      }

      final countResult = await db.rawQuery(
          'SELECT COUNT(*) as c FROM offline_actions');
      _pendingActions = (countResult.first['c'] as int?) ?? 0;
      _pendingActionsController.add(_pendingActions);

      _lastSyncTime = DateTime.now();
      await db.insert('kv_store', {
        'key': 'last_sync_time',
        'value': _lastSyncTime!.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      if (kDebugMode) {
        debugPrint('✅ OfflineSync: done – ok=$ok, fail=$fail, remaining=$_pendingActions');
      }
    } catch (e, stack) {
      if (kDebugMode) debugPrint('❌ OfflineSync: sync error - $e');
      ErrorReportingService().reportError(
          error: e, stackTrace: stack, context: 'Offline Sync - Sync Actions');
    } finally {
      _isSyncing = false;
      _syncStatusController.add(false);
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────
  // EXECUTE ACTION
  // ──────────────────────────────────────────────────────

  Future<bool> _executeAction(OfflineAction action) async {
    final api = CloudflareApiService();
    // User-Revalidation: queued actions belong to the user who was logged in when
    // the action was queued. If a different user is logged in now, skip the action
    // instead of executing it under the wrong identity.
    //
    // Wichtig: Wenn aktuell KEIN User eingeloggt ist (currentUserId == null),
    // queued action aufschieben statt durchführen — sonst geht sie unter falschem
    // (anonymem) Identitäts-Kontext raus oder schlägt mit RLS-Deny silent fail.
    final queuedUserId = action.data['userId']?.toString() ?? action.userId;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (queuedUserId == null || queuedUserId.isEmpty) {
      // Action hat keinen Owner — drop (broken queue entry).
      if (kDebugMode) debugPrint('⚠️  OfflineSync: queued action ohne userId — drop');
      return true;
    }
    if (currentUserId == null) {
      // Niemand eingeloggt → noch nicht ausführen, bei nächstem Versuch retry.
      if (kDebugMode) debugPrint('⏸  OfflineSync: kein currentUser → defer');
      return false;
    }
    if (currentUserId != queuedUserId) {
      if (kDebugMode) {
        debugPrint('⚠️  OfflineSync: queued user $queuedUserId != current $currentUserId — skipping');
      }
      return true; // drop from queue, don't retry under wrong identity
    }
    try {
      switch (action.type) {
        case OfflineActionType.sendMessage:
          await api.sendChatMessage(
            roomId: action.data['roomId'] ?? '',
            realm: action.data['realm'] ?? 'energie',
            userId: action.data['userId'] ?? '',
            username: action.data['username'] ?? 'Anonym',
            message: action.data['message'] ?? '',
            avatarEmoji: action.data['avatarEmoji'],
            avatarUrl: action.data['avatarUrl'],
          );
          return true;
        case OfflineActionType.editMessage:
          await api.editChatMessage(
            messageId: action.data['messageId'] ?? '',
            roomId: action.data['roomId'] ?? '',
            newMessage: action.data['newContent'] ?? action.data['newMessage'] ?? '',
            userId: action.data['userId'] ?? '',
            username: action.data['username'] ?? 'Anonym',
            realm: action.data['realm'],
          );
          return true;
        case OfflineActionType.deleteMessage:
          await api.deleteChatMessage(
            messageId: action.data['messageId'] ?? '',
            roomId: action.data['roomId'] ?? '',
            userId: action.data['userId'] ?? '',
            username: action.data['username'] ?? 'Anonym',
            realm: action.data['realm'],
          );
          return true;
        case OfflineActionType.uploadFile:
          if (kDebugMode) debugPrint('📁 OfflineSync: File upload skipped');
          return true;
        case OfflineActionType.updateProfile:
          if (kDebugMode) debugPrint('👤 OfflineSync: Profile update – use ProfileSyncService');
          return true;
        case OfflineActionType.createPost:
          await api.sendChatMessage(
            roomId: action.data['roomId'] ?? 'general',
            realm: action.data['realm'] ?? 'energie',
            userId: action.data['userId'] ?? '',
            username: action.data['username'] ?? 'Anonym',
            message: action.data['content'] ?? action.data['message'] ?? '',
          );
          return true;
        case OfflineActionType.updatePost:
        case OfflineActionType.deletePost:
          if (kDebugMode) debugPrint('📝 OfflineSync: Post op – no offline support');
          return true;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ OfflineSync: execute failed - $e');
      return false;
    }
  }

  // ──────────────────────────────────────────────────────
  // MESSAGES CACHE
  // ──────────────────────────────────────────────────────

  Future<void> saveMessage(Map<String, dynamic> message) async {
    try {
      final db = await AppDatabase.instance.db;
      final messageId = message['id'] ?? message['message_id'];
      if (messageId == null) return;
      await db.insert('chat_messages', {
        'id': messageId.toString(),
        'room_id': message['room_id']?.toString() ?? '',
        'data': jsonEncode(message),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ OfflineSync: saveMessage failed - $e');
    }
  }

  Future<List<Map<String, dynamic>>> getOfflineMessages({
    String? roomId,
    int limit = 50,
  }) async {
    try {
      final db = await AppDatabase.instance.db;
      final rows = roomId != null
          ? await db.query('chat_messages',
              where: 'room_id = ?',
              whereArgs: [roomId],
              orderBy: 'created_at DESC',
              limit: limit)
          : await db.query('chat_messages',
              orderBy: 'created_at DESC', limit: limit);
      return rows
          .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ OfflineSync: getOfflineMessages failed - $e');
      return [];
    }
  }

  // ──────────────────────────────────────────────────────
  // UTILITIES
  // ──────────────────────────────────────────────────────

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      if (isOnline && _pendingActions > 0) syncPendingActions();
    });
  }

  Future<void> clearAll() async {
    try {
      final db = await AppDatabase.instance.db;
      await db.delete('offline_actions');
      await db.delete('kv_store', where: "key = 'last_sync_time'");
      _pendingActions = 0;
      _pendingActionsController.add(0);
      _lastSyncTime = null;
      notifyListeners();
      if (kDebugMode) debugPrint('✅ OfflineSync: All data cleared');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ OfflineSync: clearAll failed - $e');
    }
  }

  @override
  Future<void> dispose() async {
    // Robustes Dispose: jeder Schritt einzeln gecatcht, damit ein einzelner
    // Fehler die anderen nicht blockiert (vermeidet Stream-Controller-Leaks).
    _syncTimer?.cancel();
    try {
      await _connectivitySubscription?.cancel();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ connectivity cancel failed: $e');
    }
    try {
      await _networkStateController.close();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ networkStateController close failed: $e');
    }
    try {
      await _syncStatusController.close();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ syncStatusController close failed: $e');
    }
    try {
      await _pendingActionsController.close();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ pendingActionsController close failed: $e');
    }
    super.dispose();
  }
}

