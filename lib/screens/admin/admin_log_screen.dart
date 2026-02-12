/// ADMIN LOG SCREEN
/// Vollständige Admin-Log-Ansicht mit allen durchgeführten Aktionen
/// 
/// Features:
/// - Liste aller Admin-Aktionen (chronologisch)
/// - Filter nach Typ (Kick, Mute, Ban, Warning)
/// - User-spezifische History
/// - Export-Funktion
/// - Nur für Root Admin & Admin
library;

import 'package:flutter/material.dart';
import '../../models/admin_action.dart';
import '../../services/admin_action_service.dart';

class AdminLogScreen extends StatefulWidget {
  final AdminActionService adminService;
  
  const AdminLogScreen({
    super.key,
    required this.adminService,
  });

  @override
  State<AdminLogScreen> createState() => _AdminLogScreenState();
}

class _AdminLogScreenState extends State<AdminLogScreen> {
  AdminActionType? _filterType;
  String _searchQuery = '';
  
  List<AdminAction> get _filteredActions {
    var actions = widget.adminService.actionLog;
    
    // Filter by type
    if (_filterType != null) {
      actions = actions.where((a) => a.type == _filterType).toList();
    }
    
    // Search filter
    if (_searchQuery.isNotEmpty) {
      actions = actions.where((a) {
        return a.targetUsername.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               a.adminUsername.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (a.reason?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }
    
    return actions;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          '📋 Admin Log',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Filter Button
          PopupMenuButton<AdminActionType?>(
            icon: Icon(
              _filterType != null ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _filterType != null ? Colors.blue : Colors.white,
            ),
            onSelected: (type) {
              setState(() {
                _filterType = type;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Alle Aktionen'),
              ),
              const PopupMenuDivider(),
              ...AdminActionType.values.map((type) {
                String label;
                IconData icon;
                
                switch (type) {
                  case AdminActionType.kick:
                    label = 'Kicks';
                    icon = Icons.exit_to_app;
                    break;
                  case AdminActionType.mute:
                    label = 'Mutes';
                    icon = Icons.mic_off;
                    break;
                  case AdminActionType.unmute:
                    label = 'Unmutes';
                    icon = Icons.mic;
                    break;
                  case AdminActionType.ban:
                    label = 'Bans';
                    icon = Icons.block;
                    break;
                  case AdminActionType.unban:
                    label = 'Unbans';
                    icon = Icons.check_circle;
                    break;
                  case AdminActionType.timeout:
                    label = 'Timeouts';
                    icon = Icons.timer;
                    break;
                  case AdminActionType.warning:
                    label = 'Warnings';
                    icon = Icons.warning;
                    break;
                  case AdminActionType.deleteMessage:
                    label = 'Gelöschte Nachrichten';
                    icon = Icons.delete;
                    break;
                  case AdminActionType.slowMode:
                    label = 'Slow Mode';
                    icon = Icons.speed;
                    break;
                }
                
                return PopupMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: 12),
                      Text(label),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1A1A2E),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nach User oder Admin suchen...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: const Color(0xFF252538),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // Stats Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1A1A2E),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Gesamt',
                  widget.adminService.actionLog.length,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Heute',
                  widget.adminService.actionLog.where((a) {
                    final now = DateTime.now();
                    return a.timestamp.year == now.year &&
                           a.timestamp.month == now.month &&
                           a.timestamp.day == now.day;
                  }).length,
                  Colors.green,
                ),
                _buildStatItem(
                  'Gefiltert',
                  _filteredActions.length,
                  Colors.orange,
                ),
              ],
            ),
          ),
          
          // Action List
          Expanded(
            child: _filteredActions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Keine Aktionen gefunden',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredActions.length,
                    itemBuilder: (context, index) {
                      final action = _filteredActions[index];
                      return _buildActionTile(action);
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionTile(AdminAction action) {
    Color actionColor;
    switch (action.type) {
      case AdminActionType.kick:
        actionColor = Colors.red;
        break;
      case AdminActionType.mute:
        actionColor = Colors.orange;
        break;
      case AdminActionType.unmute:
        actionColor = Colors.green;
        break;
      case AdminActionType.ban:
      case AdminActionType.timeout:
        actionColor = Colors.red.shade900;
        break;
      case AdminActionType.unban:
        actionColor = Colors.green;
        break;
      case AdminActionType.warning:
        actionColor = Colors.orange;
        break;
      case AdminActionType.deleteMessage:
        actionColor = Colors.grey;
        break;
      case AdminActionType.slowMode:
        actionColor = Colors.blue;
        break;
    }
    
    final timeAgo = _getTimeAgo(action.timestamp);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: actionColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: actionColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getActionIcon(action.type),
            color: actionColor,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Text(
              action.icon,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                action.description,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Von: ${action.adminUsername}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            Text(
              timeAgo,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
            if (action.roomId != null) ...[
              const SizedBox(height: 4),
              Text(
                'Room: ${action.roomId}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
        trailing: action.expiresAt != null
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getDurationText(action.duration),
                  style: TextStyle(
                    color: actionColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }
  
  IconData _getActionIcon(AdminActionType type) {
    switch (type) {
      case AdminActionType.kick:
        return Icons.exit_to_app;
      case AdminActionType.mute:
        return Icons.mic_off;
      case AdminActionType.unmute:
        return Icons.mic;
      case AdminActionType.ban:
        return Icons.block;
      case AdminActionType.unban:
        return Icons.check_circle;
      case AdminActionType.timeout:
        return Icons.timer;
      case AdminActionType.warning:
        return Icons.warning;
      case AdminActionType.deleteMessage:
        return Icons.delete;
      case AdminActionType.slowMode:
        return Icons.speed;
    }
  }
  
  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return 'Gerade eben';
    } else if (difference.inMinutes < 60) {
      return 'vor ${difference.inMinutes} Min';
    } else if (difference.inHours < 24) {
      return 'vor ${difference.inHours} Std';
    } else {
      return 'vor ${difference.inDays} Tag${difference.inDays > 1 ? "en" : ""}';
    }
  }
  
  String _getDurationText(BanDuration? duration) {
    if (duration == null) return '';
    switch (duration) {
      case BanDuration.fiveMinutes:
        return '5min';
      case BanDuration.thirtyMinutes:
        return '30min';
      case BanDuration.oneHour:
        return '1h';
      case BanDuration.oneDay:
        return '24h';
      case BanDuration.permanent:
        return 'PERM';
    }
  }
}
