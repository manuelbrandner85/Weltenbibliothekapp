import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../../../services/moderation_service.dart';
import '../../../models/moderation_models.dart';
import 'flagged_content_list_screen.dart'; // 🚩 FLAGGED CONTENT LIST

/// Moderation Dashboard Screen
/// Zeigt gemeldete Inhalte und Moderation-Log
class ModerationDashboardScreen extends StatefulWidget {
  final String world;
  final String adminToken;
  final bool isRootAdmin;
  
  const ModerationDashboardScreen({
    super.key,
    required this.world,
    required this.adminToken,
    required this.isRootAdmin,
  });
  
  @override
  State<ModerationDashboardScreen> createState() => _ModerationDashboardScreenState();
}

class _ModerationDashboardScreenState extends State<ModerationDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _moderationService = ModerationService();
  
  List<FlaggedContent> _flaggedContent = [];
  List<ModerationLogEntry> _moderationLog = [];
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Load flagged content
      final flaggedResult = await _moderationService.getFlaggedContent(
        world: widget.world,
        status: 'pending',
        adminToken: widget.adminToken,
      );
      
      if (flaggedResult['success'] == true) {
        _flaggedContent = (flaggedResult['flagged_content'] as List)
            .map((json) => FlaggedContent.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      
      // Load moderation log
      final logResult = await _moderationService.getModerationLog(
        world: widget.world,
        limit: 50,
        adminToken: widget.adminToken,
      );
      
      if (logResult['success'] == true) {
        _moderationLog = (logResult['logs'] as List)
            .map((json) => ModerationLogEntry.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Laden: $e';
        _isLoading = false;
      });
      if (kDebugMode) {
        debugPrint('❌ Error loading moderation data: $e');
      }
    }
  }
  
  Future<void> _resolveFlag(FlaggedContent flag, String action) async {
    final result = await _moderationService.resolveFlag(
      flagId: flag.id,
      world: widget.world,
      resolutionAction: action,
      adminToken: widget.adminToken,
    );
    
    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Meldung bearbeitet'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _dismissFlag(FlaggedContent flag) async {
    final result = await _moderationService.dismissFlag(
      flagId: flag.id,
      world: widget.world,
      notes: 'Verworfen durch ${widget.isRootAdmin ? 'Root-' : ''}Admin',
      adminToken: widget.adminToken,
    );
    
    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Meldung verworfen'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      _loadData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1f3a),
        title: Row(
          children: [
            const Icon(Icons.shield, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'Moderation',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              icon: Stack(
                children: [
                  const Icon(Icons.flag),
                  if (_flaggedContent.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${_flaggedContent.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              text: 'Meldungen',
            ),
            const Tab(
              icon: Icon(Icons.history),
              text: 'Verlauf',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text('Neu laden'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFlaggedContentTab(),
                    _buildModerationLogTab(),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FlaggedContentListScreen(
                world: widget.world,
                adminToken: widget.adminToken,
              ),
            ),
          );
        },
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.list_alt),
        label: const Text('Alle Meldungen'),
      ),
    );
  }
  
  Widget _buildFlaggedContentTab() {
    if (_flaggedContent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Keine ausstehenden Meldungen',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.orange,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _flaggedContent.length,
        itemBuilder: (context, index) {
          final flag = _flaggedContent[index];
          return _buildFlaggedContentCard(flag);
        },
      ),
    );
  }
  
  Widget _buildFlaggedContentCard(FlaggedContent flag) {
    return Card(
      color: const Color(0xFF1a1f3a),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  flag.contentType == 'post' ? Icons.article : Icons.comment,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  flag.contentType == 'post' ? 'Post' : 'Kommentar',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    flag.statusText,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Reason
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0E27),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Grund:',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    flag.reason,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Info
            Row(
              children: [
                const Icon(Icons.person, color: Colors.grey, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Gemeldet von: ${flag.flaggedByUsername}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (flag.contentAuthorUsername != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.edit, color: Colors.grey, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Autor: ${flag.contentAuthorUsername}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            
            // Actions (nur Root-Admin)
            if (widget.isRootAdmin) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.grey),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _resolveFlag(flag, 'deleted'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Löschen', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _dismissFlag(flag),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Verwerfen', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildModerationLogTab() {
    if (_moderationLog.isEmpty) {
      return Center(
        child: Text(
          'Keine Einträge im Moderation-Log',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.orange,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _moderationLog.length,
        itemBuilder: (context, index) {
          final entry = _moderationLog[index];
          return _buildLogEntryCard(entry);
        },
      ),
    );
  }
  
  Widget _buildLogEntryCard(ModerationLogEntry entry) {
    return Card(
      color: const Color(0xFF1a1f3a),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: entry.isRootAdmin 
              ? Colors.purple.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
          child: Icon(
            entry.isRootAdmin ? Icons.shield : Icons.admin_panel_settings,
            color: entry.isRootAdmin ? Colors.purple : Colors.orange,
            size: 20,
          ),
        ),
        title: Text(
          entry.actionText,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${entry.moderatorUsername} • ${_formatDate(entry.createdAt)}',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
            if (entry.targetUsername != null) ...[
              const SizedBox(height: 4),
              Text(
                'Ziel: ${entry.targetUsername}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ],
            if (entry.reason != null) ...[
              const SizedBox(height: 4),
              Text(
                'Grund: ${entry.reason}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        trailing: Icon(
          _getActionIcon(entry.actionType),
          color: Colors.grey,
          size: 20,
        ),
      ),
    );
  }
  
  IconData _getActionIcon(String actionType) {
    switch (actionType) {
      case 'delete_post':
      case 'delete_comment':
        return Icons.delete;
      case 'edit_post':
      case 'edit_comment':
        return Icons.edit;
      case 'mute_user_24h':
      case 'mute_user_permanent':
        return Icons.block;
      case 'unmute_user':
        return Icons.check_circle;
      case 'flag_content':
        return Icons.flag;
      case 'resolve_flag':
        return Icons.done;
      case 'dismiss_flag':
        return Icons.close;
      default:
        return Icons.info;
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) {
      return 'Gerade eben';
    } else if (diff.inHours < 1) {
      return 'Vor ${diff.inMinutes}m';
    } else if (diff.inDays < 1) {
      return 'Vor ${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return 'Vor ${diff.inDays}d';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
