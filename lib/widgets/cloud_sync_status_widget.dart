/// Cloud Sync Status Widget (Anonymous)
/// Shows sync status and manual backup button (no authentication required)
library;

import 'package:flutter/material.dart';
import '../services/anonymous_cloud_sync_service.dart';
import '../utils/responsive_utils.dart';
import '../utils/responsive_text_styles.dart';

class CloudSyncStatusWidget extends StatefulWidget {
  const CloudSyncStatusWidget({super.key});

  @override
  State<CloudSyncStatusWidget> createState() => _CloudSyncStatusWidgetState();
}

class _CloudSyncStatusWidgetState extends State<CloudSyncStatusWidget> {
  final AnonymousCloudSyncService _syncService = AnonymousCloudSyncService();
  
  SyncStatus _currentStatus = SyncStatus.idle;
  DateTime? _lastSyncAt;

  @override
  void initState() {
    super.initState();
    _currentStatus = _syncService.currentStatus;
    _lastSyncAt = _syncService.lastSyncAt;
    
    // Listen to sync status changes
    _syncService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _currentStatus = status;
          if (status == SyncStatus.success) {
            _lastSyncAt = _syncService.lastSyncAt;
          }
        });
      }
    });
  }

  Future<void> _triggerManualBackup() async {
    final result = await _syncService.sync();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? '✅ Backup erfolgreich: ${result.uploadedCount} Einträge gesichert'
                : '⚠️ ${result.message}',
          ),
          backgroundColor: result.success ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final utils = ResponsiveUtils.of(context);
    final textStyles = ResponsiveTextStyles.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Only show if cloud backup is available (optional feature)
    if (!_syncService.cloudSyncAvailable) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: utils.spacingMd, 
        vertical: utils.spacingMd * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Status icon
          _buildStatusIcon(context),
          SizedBox(width: utils.spacingMd * 0.75),
          
          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getStatusText(),
                  style: textStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (_lastSyncAt != null)
                  Text(
                    _getLastSyncText(),
                    style: textStyles.bodySmall.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          
          // Backup button
          if (_currentStatus != SyncStatus.syncing)
            IconButton(
              icon: Icon(Icons.cloud_upload, size: utils.iconSizeMd),
              onPressed: _triggerManualBackup,
              tooltip: 'Backup erstellen',
              color: Theme.of(context).colorScheme.primary,
            )
          else
            SizedBox(
              width: utils.iconSizeMd,
              height: utils.iconSizeMd,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    final utils = ResponsiveUtils.of(context);
    IconData icon;
    Color color;
    
    switch (_currentStatus) {
      case SyncStatus.idle:
        icon = Icons.cloud_outlined;
        color = Colors.grey;
        break;
      case SyncStatus.syncing:
        icon = Icons.cloud_sync;
        color = Colors.blue;
        break;
      case SyncStatus.success:
        icon = Icons.cloud_done;
        color = Colors.green;
        break;
      case SyncStatus.error:
        icon = Icons.cloud_off;
        color = Colors.orange;
        break;
    }
    
    return Icon(icon, color: color, size: utils.iconSizeMd);
  }

  String _getStatusText() {
    switch (_currentStatus) {
      case SyncStatus.idle:
        return 'Cloud-Backup verfügbar';
      case SyncStatus.syncing:
        return 'Erstelle Backup...';
      case SyncStatus.success:
        return 'Backup gesichert';
      case SyncStatus.error:
        return 'Backup optional';
    }
  }

  String _getLastSyncText() {
    if (_lastSyncAt == null) return 'Noch kein Backup';
    
    final now = DateTime.now();
    final diff = now.difference(_lastSyncAt!);
    
    if (diff.inMinutes < 1) {
      return 'Gerade eben';
    } else if (diff.inMinutes < 60) {
      return 'Vor ${diff.inMinutes} Min';
    } else if (diff.inHours < 24) {
      return 'Vor ${diff.inHours} Std';
    } else {
      return 'Vor ${diff.inDays} Tagen';
    }
  }
}
