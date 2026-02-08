/// 📴 WELTENBIBLIOTHEK - OFFLINE INDICATOR
/// Visual feedback for network state and pending sync actions
/// Features: Network status, sync progress, pending actions count

import 'package:flutter/material.dart';
import '../services/offline_sync_service.dart';

class OfflineIndicator extends StatefulWidget {
  const OfflineIndicator({Key? key}) : super(key: key);

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> 
    with SingleTickerProviderStateMixin {
  final OfflineSyncService _syncService = OfflineSyncService();
  late AnimationController _pulseController;
  
  NetworkState _networkState = NetworkState.unknown;
  bool _isSyncing = false;
  int _pendingActions = 0;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _networkState = _syncService.networkState;
    _pendingActions = _syncService.pendingActionsCount;
    
    _syncService.networkStateStream.listen((state) {
      if (mounted) {
        setState(() => _networkState = state);
      }
    });
    
    _syncService.syncStatusStream.listen((syncing) {
      if (mounted) {
        setState(() => _isSyncing = syncing);
      }
    });
    
    _syncService.pendingActionsStream.listen((count) {
      if (mounted) {
        setState(() => _pendingActions = count);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only show when offline or syncing
    if (_networkState == NetworkState.online && !_isSyncing && _pendingActions == 0) {
      return const SizedBox.shrink();
    }
    
    return Material(
      color: _getBackgroundColor(),
      child: InkWell(
        onTap: _showSyncDetails,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status Icon
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Icon(
                    _getStatusIcon(),
                    color: Colors.white.withValues(
                      alpha: 0.7 + (_pulseController.value * 0.3),
                    ),
                    size: 16,
                  );
                },
              ),
              
              const SizedBox(width: 8),
              
              // Status Text
              Flexible(
                child: Text(
                  _getStatusText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Pending Actions Count
              if (_pendingActions > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$_pendingActions',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              
              // Sync Progress
              if (_isSyncing) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (_networkState == NetworkState.offline) {
      return Colors.red.withValues(alpha: 0.9);
    } else if (_isSyncing) {
      return Colors.orange.withValues(alpha: 0.9);
    } else if (_pendingActions > 0) {
      return Colors.blue.withValues(alpha: 0.9);
    }
    return Colors.grey.withValues(alpha: 0.9);
  }

  IconData _getStatusIcon() {
    if (_networkState == NetworkState.offline) {
      return Icons.cloud_off;
    } else if (_isSyncing) {
      return Icons.sync;
    } else if (_pendingActions > 0) {
      return Icons.cloud_queue;
    }
    return Icons.cloud_done;
  }

  String _getStatusText() {
    if (_networkState == NetworkState.offline) {
      return 'Offline-Modus';
    } else if (_isSyncing) {
      return 'Synchronisiere...';
    } else if (_pendingActions > 0) {
      return '$_pendingActions ausstehend';
    }
    return 'Online';
  }

  void _showSyncDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getStatusIcon(),
              color: _getBackgroundColor(),
            ),
            const SizedBox(width: 8),
            const Text('Sync-Status'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              'Netzwerk',
              _networkState == NetworkState.online ? 'Online' : 'Offline',
              _networkState == NetworkState.online ? Icons.wifi : Icons.wifi_off,
            ),
            const Divider(),
            _buildInfoRow(
              'Ausstehende Aktionen',
              '$_pendingActions',
              Icons.queue,
            ),
            const Divider(),
            _buildInfoRow(
              'Sync-Status',
              _isSyncing ? 'Läuft...' : 'Bereit',
              _isSyncing ? Icons.sync : Icons.check_circle,
            ),
            if (_syncService.lastSyncTime != null) ...[
              const Divider(),
              _buildInfoRow(
                'Letzte Sync',
                _formatLastSync(_syncService.lastSyncTime!),
                Icons.access_time,
              ),
            ],
          ],
        ),
        actions: [
          if (_pendingActions > 0 && _networkState == NetworkState.online)
            TextButton(
              onPressed: () {
                _syncService.syncPendingActions();
                Navigator.pop(context);
              },
              child: const Text('Jetzt synchronisieren'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastSync(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Gerade eben';
    } else if (difference.inMinutes < 60) {
      return 'vor ${difference.inMinutes} Min';
    } else if (difference.inHours < 24) {
      return 'vor ${difference.inHours} Std';
    } else {
      return 'vor ${difference.inDays} Tagen';
    }
  }
}

/// Floating Offline Badge
class OfflineFloatingBadge extends StatelessWidget {
  const OfflineFloatingBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: kToolbarHeight + 8,
      left: 0,
      right: 0,
      child: Center(
        child: OfflineIndicator(),
      ),
    );
  }
}
