import 'package:flutter/material.dart';
import '../services/moderation_service.dart';
import '../services/auth_service.dart';

/// ═══════════════════════════════════════════════════════════════
/// MODERATION TAB - User Moderation Tools
/// ═══════════════════════════════════════════════════════════════
/// Für Admins und Moderatoren
/// Features:
/// - Reports verwalten
/// - User bannen/muten
/// - Moderations-Aktionen-Log
/// ═══════════════════════════════════════════════════════════════

class ModerationTab extends StatefulWidget {
  const ModerationTab({super.key});

  @override
  State<ModerationTab> createState() => _ModerationTabState();
}

class _ModerationTabState extends State<ModerationTab>
    with SingleTickerProviderStateMixin {
  final ModerationService _moderationService = ModerationService();
  final AuthService _authService = AuthService();

  late TabController _subTabController;
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _moderationActions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reports = await _moderationService.getReports(status: 'pending');
      final actions = await _moderationService.getModerationActions(limit: 30);

      if (mounted) {
        setState(() {
          _reports = reports;
          _moderationActions = actions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Fehler beim Laden: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resolveReport(int reportId, String status, String? note) async {
    try {
      await _moderationService.resolveReport(
        reportId: reportId,
        status: status,
        resolutionNote: note,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Report $status'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _subTabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              icon: const Icon(Icons.flag),
              text: 'Reports (${_reports.length})',
            ),
            const Tab(icon: Icon(Icons.history), text: 'Aktionen-Log'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [_buildReportsTab(), _buildActionsTab()],
          ),
        ),
      ],
    );
  }

  Widget _buildReportsTab() {
    if (_reports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              '✅ Keine offenen Reports',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          return _buildReportCard(report);
        },
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final reportType = report['report_type'] as String;
    final reason = report['reason'] as String;
    final description = report['description'] as String?;
    final reporterUsername = report['reporter_username'] as String;
    final reportedUsername = report['reported_username'] as String?;
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      (report['created_at'] as int) * 1000,
    );

    IconData typeIcon;
    Color typeColor;
    switch (reportType) {
      case 'user':
        typeIcon = Icons.person;
        typeColor = Colors.orange;
        break;
      case 'message':
        typeIcon = Icons.message;
        typeColor = Colors.blue;
        break;
      case 'room':
        typeIcon = Icons.video_call;
        typeColor = Colors.purple;
        break;
      default:
        typeIcon = Icons.flag;
        typeColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(typeIcon, color: typeColor, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reportType.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildReasonBadge(reason),
              ],
            ),
            const Divider(height: 20),

            // Reporter info
            Row(
              children: [
                const Text(
                  'Gemeldet von: ',
                  style: TextStyle(color: Colors.grey),
                ),
                Text(
                  reporterUsername,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Reported user
            if (reportedUsername != null)
              Row(
                children: [
                  const Text(
                    'Gemeldet: ',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    reportedUsername,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),

            // Description
            if (description != null && description.isNotEmpty) ...[
              const Text(
                'Beschreibung:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(description),
              const SizedBox(height: 12),
            ],

            // Timestamp
            Text(
              '📅 ${_formatDate(createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showResolveDialog(report, 'dismissed'),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Ablehnen'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showResolveDialog(report, 'resolved'),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Erledigt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonBadge(String reason) {
    String label;
    Color color;

    switch (reason) {
      case 'spam':
        label = 'Spam';
        color = Colors.orange;
        break;
      case 'harassment':
        label = 'Belästigung';
        color = Colors.red;
        break;
      case 'inappropriate':
        label = 'Unangemessen';
        color = Colors.purple;
        break;
      case 'violence':
        label = 'Gewalt';
        color = Colors.deepOrange;
        break;
      default:
        label = 'Sonstiges';
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _showResolveDialog(
    Map<String, dynamic> report,
    String status,
  ) async {
    final TextEditingController noteController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          status == 'resolved' ? '✅ Report erledigen' : '❌ Report ablehnen',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Report von ${report['reporter_username']} wird als "$status" markiert.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notiz (optional)',
                border: OutlineInputBorder(),
                hintText: 'Begründung...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bestätigen'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _resolveReport(
        report['id'] as int,
        status,
        noteController.text.trim().isEmpty ? null : noteController.text.trim(),
      );
    }

    noteController.dispose();
  }

  Widget _buildActionsTab() {
    if (_moderationActions.isEmpty) {
      return const Center(child: Text('Keine Moderations-Aktionen vorhanden'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _moderationActions.length,
        itemBuilder: (context, index) {
          final action = _moderationActions[index];
          return _buildActionCard(action);
        },
      ),
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action) {
    final actionType = action['action_type'] as String;
    final moderatorUsername = action['moderator_username'] as String;
    final targetUsername = action['target_username'] as String?;
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      (action['created_at'] as int) * 1000,
    );

    IconData icon;
    Color color;

    switch (actionType) {
      case 'ban_user':
        icon = Icons.block;
        color = Colors.red;
        break;
      case 'mute_user':
        icon = Icons.volume_off;
        color = Colors.orange;
        break;
      case 'resolve_report':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'delete_message':
        icon = Icons.delete;
        color = Colors.red;
        break;
      default:
        icon = Icons.shield;
        color = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          _getActionLabel(actionType),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('👤 $moderatorUsername'),
            if (targetUsername != null) Text('🎯 Ziel: $targetUsername'),
            Text(
              '📅 ${_formatDate(createdAt)}',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  String _getActionLabel(String actionType) {
    switch (actionType) {
      case 'ban_user':
        return 'User gebannt';
      case 'mute_user':
        return 'User stummgeschaltet';
      case 'unban_user':
        return 'Ban aufgehoben';
      case 'unmute_user':
        return 'Stummschaltung aufgehoben';
      case 'resolve_report':
        return 'Report erledigt';
      case 'delete_message':
        return 'Nachricht gelöscht';
      case 'kick_user':
        return 'User entfernt';
      default:
        return actionType;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Gerade eben';
    } else if (diff.inHours < 1) {
      return 'vor ${diff.inMinutes} Min.';
    } else if (diff.inDays < 1) {
      return 'vor ${diff.inHours} Std.';
    } else if (diff.inDays < 7) {
      return 'vor ${diff.inDays} Tagen';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
