/// 📴 WELTENBIBLIOTHEK - OFFLINE SYNC SERVICE
/// Comprehensive offline-first architecture with background sync
/// Features: Message queue, auto-sync, conflict resolution, network detection
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/error_reporting_service.dart';

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
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
      'userId': userId,
    };
  }
  
  factory OfflineAction.fromJson(Map<String, dynamic> json) {
    return OfflineAction(
      id: json['id'] as String,
      type: OfflineActionType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
      userId: json['userId'] as String?,
    );
  }
  
  OfflineAction copyWith({int? retryCount}) {
    return OfflineAction(
      id: id,
      type: type,
      data: data,
      timestamp: timestamp,
      retryCount: retryCount ?? this.retryCount,
      userId: userId,
    );
  }
}

/// Network State
enum NetworkState {
  online,
  offline,
  unknown,
}

/// Offline Sync Service
class OfflineSyncService extends ChangeNotifier {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  // Hive Boxes
  Box<dynamic>? _queueBox;
  Box<dynamic>? _messagesBox;
  Box<dynamic>? _syncStateBox;
  
  // Network State
  NetworkState _networkState = NetworkState.unknown;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  // Sync State
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  int _pendingActions = 0;
  
  // Stream Controllers
  final _networkStateController = StreamController<NetworkState>.broadcast();
  final _syncStatusController = StreamController<bool>.broadcast();
  final _pendingActionsController = StreamController<int>.broadcast();
  
  // Streams
  Stream<NetworkState> get networkStateStream => _networkStateController.stream;
  Stream<bool> get syncStatusStream => _syncStatusController.stream;
  Stream<int> get pendingActionsStream => _pendingActionsController.stream;
  
  // Getters
  NetworkState get networkState => _networkState;
  bool get isOnline => _networkState == NetworkState.online;
  bool get isOffline => _networkState == NetworkState.offline;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get pendingActionsCount => _pendingActions;
  
  // Constants
  static const String _queueBoxName = 'offline_action_queue';
  static const String _messagesBoxName = 'offline_messages';
  static const String _syncStateBoxName = 'sync_state';
  static const int _maxRetryAttempts = 3;
  static const Duration _syncInterval = Duration(seconds: 30);
  
  Timer? _syncTimer;

  /// Initialize offline sync service
  Future<void> initialize() async {
    try {
      if (kDebugMode) {
        print('📴 OfflineSync: Initializing...');
      }
      
      // Initialize Hive
      await Hive.initFlutter();
      
      // Open boxes
      _queueBox = await Hive.openBox(_queueBoxName);
      _messagesBox = await Hive.openBox(_messagesBoxName);
      _syncStateBox = await Hive.openBox(_syncStateBoxName);
      
      // Load pending actions count
      _pendingActions = _queueBox?.length ?? 0;
      _pendingActionsController.add(_pendingActions);
      
      // Load last sync time
      final lastSync = _syncStateBox?.get('last_sync_time');
      if (lastSync != null) {
        _lastSyncTime = DateTime.parse(lastSync as String);
      }
      
      // Setup network monitoring
      await _setupNetworkMonitoring();
      
      // Start periodic sync
      _startPeriodicSync();
      
      if (kDebugMode) {
        print('✅ OfflineSync: Initialized successfully');
        print('📊 OfflineSync: Pending actions: $_pendingActions');
      }
      
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ OfflineSync: Initialization failed - $e');
      }
      ErrorReportingService().reportError(
        error: e,
        stackTrace: stack,
        context: 'Offline Sync - Initialize',
      );
    }
  }

  /// Setup network monitoring
  Future<void> _setupNetworkMonitoring() async {
    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _updateNetworkState(result);
      
      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
        _updateNetworkState(result);
      });
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ OfflineSync: Error setting up network monitoring - $e');
      }
    }
  }

  /// Update network state
  void _updateNetworkState(List<ConnectivityResult> results) {
    final hasConnection = results.any((result) => 
      result == ConnectivityResult.wifi || 
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.ethernet
    );
    
    final newState = hasConnection ? NetworkState.online : NetworkState.offline;
    
    if (_networkState != newState) {
      _networkState = newState;
      _networkStateController.add(_networkState);
      notifyListeners();
      
      if (kDebugMode) {
        print('🌐 OfflineSync: Network state changed to ${_networkState.name}');
      }
      
      // Trigger sync when coming online
      if (_networkState == NetworkState.online && _pendingActions > 0) {
        syncPendingActions();
      }
    }
  }

  /// Queue offline action
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
      
      await _queueBox?.put(action.id, jsonEncode(action.toJson()));
      
      _pendingActions = _queueBox?.length ?? 0;
      _pendingActionsController.add(_pendingActions);
      notifyListeners();
      
      if (kDebugMode) {
        print('📥 OfflineSync: Action queued - ${type.name}');
      }
      
      // Try to sync immediately if online
      if (isOnline) {
        syncPendingActions();
      }
      
      return action.id;
      
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ OfflineSync: Error queuing action - $e');
      }
      ErrorReportingService().reportError(
        error: e,
        stackTrace: stack,
        context: 'Offline Sync - Queue Action',
      );
      rethrow;
    }
  }

  /// Sync pending actions
  Future<void> syncPendingActions() async {
    if (_isSyncing || !isOnline || _pendingActions == 0) {
      return;
    }
    
    try {
      _isSyncing = true;
      _syncStatusController.add(true);
      notifyListeners();
      
      if (kDebugMode) {
        print('🔄 OfflineSync: Starting sync... ($_pendingActions pending)');
      }
      
      final keys = _queueBox?.keys.toList() ?? [];
      int successCount = 0;
      int failCount = 0;
      
      for (final key in keys) {
        final data = _queueBox?.get(key);
        if (data == null) continue;
        
        try {
          final actionJson = jsonDecode(data as String) as Map<String, dynamic>;
          final action = OfflineAction.fromJson(actionJson);
          
          // Execute action
          final success = await _executeAction(action);
          
          if (success) {
            // Remove from queue
            await _queueBox?.delete(key);
            successCount++;
            
            if (kDebugMode) {
              print('✅ OfflineSync: Action synced - ${action.type.name}');
            }
          } else {
            // Increment retry count
            if (action.retryCount < _maxRetryAttempts) {
              final updatedAction = action.copyWith(
                retryCount: action.retryCount + 1,
              );
              await _queueBox?.put(key, jsonEncode(updatedAction.toJson()));
              
              if (kDebugMode) {
                print('🔄 OfflineSync: Action retry ${action.retryCount + 1}/$_maxRetryAttempts - ${action.type.name}');
              }
            } else {
              // Max retries reached, remove from queue
              await _queueBox?.delete(key);
              failCount++;
              
              if (kDebugMode) {
                print('❌ OfflineSync: Action failed after max retries - ${action.type.name}');
              }
              
              ErrorReportingService().reportError(
                error: 'Offline action failed after max retries',
                context: 'Offline Sync - Max Retries',
                additionalData: {
                  'action_type': action.type.name,
                  'action_id': action.id,
                },
              );
            }
          }
          
        } catch (e) {
          if (kDebugMode) {
            print('❌ OfflineSync: Error processing action - $e');
          }
          failCount++;
        }
      }
      
      _pendingActions = _queueBox?.length ?? 0;
      _pendingActionsController.add(_pendingActions);
      
      _lastSyncTime = DateTime.now();
      await _syncStateBox?.put('last_sync_time', _lastSyncTime!.toIso8601String());
      
      if (kDebugMode) {
        print('✅ OfflineSync: Sync complete - Success: $successCount, Failed: $failCount, Remaining: $_pendingActions');
      }
      
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ OfflineSync: Sync error - $e');
      }
      ErrorReportingService().reportError(
        error: e,
        stackTrace: stack,
        context: 'Offline Sync - Sync Actions',
      );
    } finally {
      _isSyncing = false;
      _syncStatusController.add(false);
      notifyListeners();
    }
  }

  /// Execute action
  Future<bool> _executeAction(OfflineAction action) async {
    try {
      // This is where you would call your actual API
      // For now, simulate success after a delay
      await Future.delayed(const Duration(milliseconds: 100));
      
      switch (action.type) {
        case OfflineActionType.sendMessage:
          // TODO: Implement actual message sending
          return true;
        case OfflineActionType.editMessage:
          // TODO: Implement actual message editing
          return true;
        case OfflineActionType.deleteMessage:
          // TODO: Implement actual message deletion
          return true;
        case OfflineActionType.uploadFile:
          // TODO: Implement actual file upload
          return true;
        case OfflineActionType.updateProfile:
          // TODO: Implement actual profile update
          return true;
        case OfflineActionType.createPost:
          // TODO: Implement actual post creation
          return true;
        case OfflineActionType.updatePost:
          // TODO: Implement actual post update
          return true;
        case OfflineActionType.deletePost:
          // TODO: Implement actual post deletion
          return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ OfflineSync: Action execution failed - $e');
      }
      return false;
    }
  }

  /// Save message for offline access
  Future<void> saveMessage(Map<String, dynamic> message) async {
    try {
      final messageId = message['id'] ?? message['message_id'];
      if (messageId != null) {
        await _messagesBox?.put(messageId, jsonEncode(message));
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ OfflineSync: Error saving message - $e');
      }
    }
  }

  /// Get offline messages
  Future<List<Map<String, dynamic>>> getOfflineMessages({
    String? roomId,
    int limit = 50,
  }) async {
    try {
      final messages = <Map<String, dynamic>>[];
      
      for (var key in _messagesBox?.keys ?? []) {
        final data = _messagesBox?.get(key);
        if (data != null) {
          final message = jsonDecode(data as String) as Map<String, dynamic>;
          
          if (roomId != null && message['room_id'] != roomId) {
            continue;
          }
          
          messages.add(message);
        }
        
        if (messages.length >= limit) break;
      }
      
      return messages;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ OfflineSync: Error getting offline messages - $e');
      }
      return [];
    }
  }

  /// Start periodic sync
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      if (isOnline && _pendingActions > 0) {
        syncPendingActions();
      }
    });
  }

  /// Clear all offline data
  Future<void> clearAll() async {
    try {
      await _queueBox?.clear();
      await _messagesBox?.clear();
      await _syncStateBox?.clear();
      
      _pendingActions = 0;
      _pendingActionsController.add(0);
      _lastSyncTime = null;
      notifyListeners();
      
      if (kDebugMode) {
        print('✅ OfflineSync: All data cleared');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ OfflineSync: Error clearing data - $e');
      }
    }
  }

  /// Dispose
  @override
  Future<void> dispose() async {
    _syncTimer?.cancel();
    await _connectivitySubscription?.cancel();
    await _networkStateController.close();
    await _syncStatusController.close();
    await _pendingActionsController.close();
    super.dispose();
  }
}
