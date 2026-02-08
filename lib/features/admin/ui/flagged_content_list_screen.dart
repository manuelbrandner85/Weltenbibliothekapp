import 'package:flutter/material.dart';
import '../../../services/moderation_service.dart';
import '../../../models/moderation_models.dart';

/// 🚩 FLAGGED CONTENT LIST
/// Shows all content flagged for moderation review
class FlaggedContentListScreen extends StatefulWidget {
  final String world;
  final String adminToken; // 🎫 Admin token for authentication
  
  const FlaggedContentListScreen({
    super.key,
    required this.world,
    required this.adminToken,
  });

  @override
  State<FlaggedContentListScreen> createState() => _FlaggedContentListScreenState();
}

class _FlaggedContentListScreenState extends State<FlaggedContentListScreen> {
  final ModerationService _moderation = ModerationService();
  
  List<FlaggedContent> _flaggedItems = [];
  bool _isLoading = false;
  String _filter = 'pending'; // pending, resolved, dismissed
  
  @override
  void initState() {
    super.initState();
    _loadFlaggedContent();
  }
  
  Future<void> _loadFlaggedContent() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _moderation.getFlaggedContent(
        world: widget.world,
        status: _filter,
        adminToken: widget.adminToken,
      );
      
      // Parse the result map
      if (result['success'] == true) {
        final List<dynamic> contentList = result['flagged_content'] ?? [];
        final items = contentList
            .map((json) => FlaggedContent.fromJson(json as Map<String, dynamic>))
            .toList();
        
        setState(() {
          _flaggedItems = items;
          _isLoading = false;
        });
      } else {
        throw Exception(result['error'] ?? 'Unknown error');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final worldColor = widget.world == 'materie'
        ? Colors.orange
        : const Color(0xFF9B51E0);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          '🚩 Gemeldete Inhalte (${widget.world.toUpperCase()})',
          style: TextStyle(color: worldColor),
        ),
        actions: [
          // Filter Dropdown
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) {
              setState(() => _filter = value);
              _loadFlaggedContent();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'pending', child: Text('🟡 Ausstehend')),
              const PopupMenuItem(value: 'resolved', child: Text('✅ Bearbeitet')),
              const PopupMenuItem(value: 'dismissed', child: Text('❌ Abgelehnt')),
            ],
          ),
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadFlaggedContent,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _flaggedItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 64,
                        color: worldColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _filter == 'pending'
                            ? 'Keine ausstehenden Meldungen'
                            : 'Keine $_filter Meldungen',
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFlaggedContent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _flaggedItems.length,
                    itemBuilder: (context, index) {
                      final item = _flaggedItems[index];
                      return _buildFlaggedCard(item, worldColor);
                    },
                  ),
                ),
    );
  }
  
  Widget _buildFlaggedCard(FlaggedContent item, Color worldColor) {
    final statusColor = item.status == 'pending'
        ? Colors.orange
        : item.status == 'resolved'
            ? Colors.green
            : Colors.red;
    
    return Card(
      color: const Color(0xFF1A1A2E),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Type + Status
            Row(
              children: [
                Icon(
                  item.contentType == 'post' ? Icons.article : Icons.comment,
                  color: worldColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  item.contentType.toUpperCase(),
                  style: TextStyle(
                    color: worldColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    item.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Content ID
            Text(
              'ID: ${item.contentId}',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
            
            // Author
            if (item.contentAuthorUsername != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: Colors.white60),
                  const SizedBox(width: 4),
                  Text(
                    'Autor: ${item.contentAuthorUsername}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ],
            
            const Divider(color: Colors.white12, height: 24),
            
            // Reason
            if (item.reason.isNotEmpty) ...[
              const Text(
                '📝 Grund:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.reason,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
            ],
            
            // Flagged By
            Row(
              children: [
                const Icon(Icons.flag, size: 14, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  'Gemeldet von: ${item.flaggedByUsername}',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
            
            // Timestamp
            Text(
              '🕒 ${_formatDateTime(item.createdAt)}',
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
            
            // Resolution (if resolved/dismissed)
            if (item.status != 'pending' && item.resolvedByUsername != null) ...[
              const Divider(color: Colors.white12, height: 24),
              Row(
                children: [
                  Icon(
                    item.status == 'resolved' ? Icons.check_circle : Icons.cancel,
                    size: 14,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Bearbeitet von: ${item.resolvedByUsername}',
                    style: TextStyle(color: statusColor, fontSize: 11),
                  ),
                ],
              ),
              if (item.resolutionNotes != null && item.resolutionNotes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '💬 ${item.resolutionNotes}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ],
            
            // Actions (only for pending)
            if (item.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showDismissDialog(item),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Ablehnen'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showResolveDialog(item),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Bearbeiten'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 🗑️ RESOLVE DIALOG
  void _showResolveDialog(FlaggedContent item) {
    final notesController = TextEditingController();
    String action = 'deleted'; // deleted, edited, no_action
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Meldung bearbeiten', style: TextStyle(color: Colors.green)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Aktion:', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: action,
                isExpanded: true,
                dropdownColor: const Color(0xFF0F0F23),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() => action = value!);
                },
                items: const [
                  DropdownMenuItem(value: 'deleted', child: Text('🗑️ Gelöscht')),
                  DropdownMenuItem(value: 'edited', child: Text('✏️ Bearbeitet')),
                  DropdownMenuItem(value: 'no_action', child: Text('✅ Keine Aktion')),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Notizen (optional)',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _resolveFlag(item.id, action, notesController.text.trim());
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Bestätigen'),
            ),
          ],
        ),
      ),
    );
  }
  
  /// ❌ DISMISS DIALOG
  void _showDismissDialog(FlaggedContent item) {
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Meldung ablehnen', style: TextStyle(color: Colors.red)),
        content: TextField(
          controller: notesController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Grund für Ablehnung (optional)',
            hintStyle: TextStyle(color: Colors.white38),
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _dismissFlag(item.id, notesController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ablehnen'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _resolveFlag(int flagId, String action, String notes) async {
    try {
      await _moderation.resolveFlag(
        flagId: flagId,
        resolutionAction: action,
        resolutionNotes: notes,
        world: widget.world,
        adminToken: widget.adminToken,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Meldung wurde bearbeitet'),
            backgroundColor: Colors.green,
          ),
        );
        _loadFlaggedContent();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _dismissFlag(int flagId, String notes) async {
    try {
      await _moderation.dismissFlag(
        flagId: flagId,
        notes: notes,
        world: widget.world,
        adminToken: widget.adminToken,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Meldung wurde abgelehnt'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadFlaggedContent();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    try {
      final now = DateTime.now();
      final diff = now.difference(dateTime);
      
      if (diff.inMinutes < 1) return 'Jetzt';
      if (diff.inHours < 1) return 'vor ${diff.inMinutes} Min';
      if (diff.inDays < 1) return 'vor ${diff.inHours} Std';
      if (diff.inDays < 7) return 'vor ${diff.inDays} Tagen';
      
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    } catch (e) {
      return '';
    }
  }
}
