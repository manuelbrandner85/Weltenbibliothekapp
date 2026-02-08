import 'package:flutter/material.dart';
import '../../../services/user_management_service.dart';
import '../../../models/user_management_models.dart';

/// User Detail Screen - Detailansicht eines Users
/// 
/// Features:
/// - User Info & Avatar
/// - Statistics Dashboard
/// - Activity Timeline
/// - Admin Actions (Suspend, Unsuspend, Add Note)
/// - Admin Notes History
class UserDetailScreen extends StatefulWidget {
  final WorldUser user;
  final String world;
  final String adminToken;
  final bool isRootAdmin;

  const UserDetailScreen({
    super.key,
    required this.user,
    required this.world,
    required this.adminToken,
    required this.isRootAdmin,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> with SingleTickerProviderStateMixin {
  final UserManagementService _service = UserManagementService();
  
  late TabController _tabController;
  
  List<UserActivity> _activity = [];
  UserStatistics? _stats;
  List<UserNote> _notes = [];
  
  bool _isLoadingActivity = false;
  bool _isLoadingStats = false;
  bool _isLoadingNotes = false;
  
  String? _activityError;
  String? _statsError;
  String? _notesError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadUserActivity(),
      _loadUserStats(),
      _loadUserNotes(),
    ]);
  }

  Future<void> _loadUserActivity() async {
    setState(() {
      _isLoadingActivity = true;
      _activityError = null;
    });

    try {
      final result = await _service.getUserActivity(
        world: widget.world,
        userId: widget.user.id,
        adminToken: widget.adminToken,
        limit: 100,
      );

      final activities = (result['activity'] as List<dynamic>?)
          ?.map((json) => UserActivity.fromJson(json as Map<String, dynamic>))
          .toList() ?? [];

      setState(() {
        _activity = activities;
        _isLoadingActivity = false;
      });
    } catch (e) {
      setState(() {
        _activityError = e.toString();
        _isLoadingActivity = false;
      });
    }
  }

  Future<void> _loadUserStats() async {
    setState(() {
      _isLoadingStats = true;
      _statsError = null;
    });

    try {
      final result = await _service.getUserStats(
        world: widget.world,
        userId: widget.user.id,
        adminToken: widget.adminToken,
      );

      if (result['stats'] != null) {
        setState(() {
          _stats = UserStatistics.fromJson(result['stats'] as Map<String, dynamic>);
          _isLoadingStats = false;
        });
      } else {
        throw Exception('Keine Statistiken verfügbar');
      }
    } catch (e) {
      setState(() {
        _statsError = e.toString();
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _loadUserNotes() async {
    setState(() {
      _isLoadingNotes = true;
      _notesError = null;
    });

    try {
      final result = await _service.getUserNotes(
        world: widget.world,
        userId: widget.user.id,
        adminToken: widget.adminToken,
      );

      final notes = (result['notes'] as List<dynamic>?)
          ?.map((json) => UserNote.fromJson(json as Map<String, dynamic>))
          .toList() ?? [];

      setState(() {
        _notes = notes;
        _isLoadingNotes = false;
      });
    } catch (e) {
      setState(() {
        _notesError = e.toString();
        _isLoadingNotes = false;
      });
    }
  }

  Future<void> _suspendUser() async {
    final reasonController = TextEditingController();
    String suspensionType = 'temporary'; // 'temporary' or 'permanent'

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('User sperren', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User: ${widget.user.username}',
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              // SUSPENSION TYPE
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('24 Stunden', style: TextStyle(color: Colors.white)),
                      value: 'temporary',
                      groupValue: suspensionType,
                      onChanged: (value) {
                        setState(() {
                          suspensionType = value!;
                        });
                      },
                      activeColor: Colors.orange,
                    ),
                  ),
                  if (widget.isRootAdmin)
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Permanent', style: TextStyle(color: Colors.white)),
                        value: 'permanent',
                        groupValue: suspensionType,
                        onChanged: (value) {
                          setState(() {
                            suspensionType = value!;
                          });
                        },
                        activeColor: Colors.red,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // REASON INPUT
              TextField(
                controller: reasonController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Grund (optional)',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: suspensionType == 'permanent' ? Colors.red : Colors.orange,
              ),
              child: const Text('Sperren'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        final expiresAt = suspensionType == 'temporary'
            ? DateTime.now().add(const Duration(hours: 24)).toIso8601String()
            : null;

        await _service.suspendUser(
          world: widget.world,
          userId: widget.user.id,
          suspensionType: suspensionType,
          reason: reasonController.text.trim(),
          adminToken: widget.adminToken,
          expiresAt: expiresAt,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ User ${widget.user.username} gesperrt ($suspensionType)',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Close detail screen
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

    reasonController.dispose();
  }

  Future<void> _unsuspendUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Sperre aufheben', style: TextStyle(color: Colors.white)),
        content: Text(
          'Sperre für ${widget.user.username} aufheben?',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Aufheben'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.unsuspendUser(
          world: widget.world,
          userId: widget.user.id,
          adminToken: widget.adminToken,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Sperre aufgehoben'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
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
  }

  Future<void> _addNote() async {
    final noteController = TextEditingController();
    String noteType = 'general'; // 'general', 'warning', 'praise', 'concern'

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Admin-Notiz hinzufügen', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User: ${widget.user.username}',
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              // NOTE TYPE
              DropdownButtonFormField<String>(
                initialValue: noteType,
                style: const TextStyle(color: Colors.white),
                dropdownColor: const Color(0xFF16213E),
                decoration: const InputDecoration(
                  labelText: 'Typ',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('Allgemein')),
                  DropdownMenuItem(value: 'warning', child: Text('⚠️ Warnung')),
                  DropdownMenuItem(value: 'praise', child: Text('✅ Lob')),
                  DropdownMenuItem(value: 'concern', child: Text('❗ Bedenken')),
                ],
                onChanged: (value) {
                  setState(() {
                    noteType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              // NOTE INPUT
              TextField(
                controller: noteController,
                style: const TextStyle(color: Colors.white),
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Notiz eingeben...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
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
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && noteController.text.trim().isNotEmpty) {
      try {
        await _service.addUserNote(
          world: widget.world,
          userId: widget.user.id,
          note: noteController.text.trim(),
          noteType: noteType,
          adminToken: widget.adminToken,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Notiz hinzugefügt'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUserNotes(); // Reload notes
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

    noteController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final worldColor = widget.world == 'materie' 
        ? const Color(0xFFFF6B35) 
        : const Color(0xFF4ECDC4);

    // ROLE BADGE
    Color roleBadgeColor = Colors.grey;
    String roleLabel = 'User';
    if (widget.user.isRootAdmin) {
      roleBadgeColor = Colors.red;
      roleLabel = 'ROOT-ADMIN';
    } else if (widget.user.isAdmin) {
      roleBadgeColor = Colors.orange;
      roleLabel = 'ADMIN';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(widget.user.username, style: TextStyle(color: worldColor)),
        actions: [
          // ADMIN ACTIONS
          if (!widget.user.isRootAdmin) ...[
            IconButton(
              icon: const Icon(Icons.note_add),
              onPressed: _addNote,
              tooltip: 'Notiz hinzufügen',
            ),
            IconButton(
              icon: Icon(widget.user.isSuspended ? Icons.lock_open : Icons.block),
              onPressed: widget.user.isSuspended ? _unsuspendUser : _suspendUser,
              tooltip: widget.user.isSuspended ? 'Sperre aufheben' : 'User sperren',
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: worldColor,
          labelColor: worldColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Übersicht'),
            Tab(text: 'Aktivität'),
            Tab(text: 'Notizen'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(worldColor, roleBadgeColor, roleLabel),
          _buildActivityTab(worldColor),
          _buildNotesTab(worldColor),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Color worldColor, Color roleBadgeColor, String roleLabel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // USER INFO CARD
          Card(
            color: const Color(0xFF16213E),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: worldColor.withOpacity(0.2),
                    child: widget.user.avatarEmoji != null
                        ? Text(widget.user.avatarEmoji!, style: const TextStyle(fontSize: 48))
                        : Text(
                            widget.user.username[0].toUpperCase(),
                            style: TextStyle(
                              color: worldColor,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.user.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: roleBadgeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: roleBadgeColor, width: 1),
                    ),
                    child: Text(
                      roleLabel,
                      style: TextStyle(
                        color: roleBadgeColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: ${widget.user.id}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  if (widget.user.isSuspended) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.block, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'GESPERRT',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (widget.user.suspensionReason != null)
                                  Text(
                                    widget.user.suspensionReason!,
                                    style: TextStyle(color: Colors.red[200], fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // STATISTICS
          if (_isLoadingStats)
            const Center(child: CircularProgressIndicator())
          else if (_statsError != null)
            Text('Fehler: $_statsError', style: const TextStyle(color: Colors.red))
          else if (_stats != null)
            _buildStatsGrid(_stats!, worldColor),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(UserStatistics stats, Color worldColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistiken',
          style: TextStyle(
            color: worldColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard('Logins', stats.totalLogins, Icons.login, Colors.blue),
            _buildStatCard('Posts', stats.totalPosts, Icons.article, Colors.green),
            _buildStatCard('Kommentare', stats.totalComments, Icons.comment, Colors.orange),
            _buildStatCard('Chat-Nachrichten', stats.totalChatMessages, Icons.chat, Colors.purple),
            _buildStatCard('Likes erhalten', stats.totalLikesReceived, Icons.favorite, Colors.pink),
            _buildStatCard('Likes gegeben', stats.totalLikesGiven, Icons.favorite_border, Colors.pink),
            _buildStatCard('Reputation', stats.reputationScore, Icons.star, Colors.amber),
            _buildStatCard('Trust Level', 0, Icons.shield, _getTrustLevelColor(stats.trustLevel), 
              subtitle: stats.trustLevel.toUpperCase()),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color, {String? subtitle}) {
    return Card(
      color: const Color(0xFF16213E),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              subtitle ?? value.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getTrustLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'new': return Colors.grey;
      case 'basic': return Colors.blue;
      case 'member': return Colors.green;
      case 'regular': return Colors.orange;
      case 'leader': return Colors.purple;
      default: return Colors.grey;
    }
  }

  Widget _buildActivityTab(Color worldColor) {
    if (_isLoadingActivity) {
      return Center(child: CircularProgressIndicator(color: worldColor));
    }

    if (_activityError != null) {
      return Center(
        child: Text('Fehler: $_activityError', style: const TextStyle(color: Colors.red)),
      );
    }

    if (_activity.isEmpty) {
      return const Center(
        child: Text('Keine Aktivität', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activity.length,
      itemBuilder: (context, index) {
        final activity = _activity[index];
        return _buildActivityItem(activity, worldColor);
      },
    );
  }

  Widget _buildActivityItem(UserActivity activity, Color worldColor) {
    IconData icon;
    Color iconColor;

    switch (activity.actionType) {
      case 'login':
        icon = Icons.login;
        iconColor = Colors.blue;
        break;
      case 'post_create':
        icon = Icons.article;
        iconColor = Colors.green;
        break;
      case 'comment_create':
        icon = Icons.comment;
        iconColor = Colors.orange;
        break;
      case 'chat_message':
        icon = Icons.chat;
        iconColor = Colors.purple;
        break;
      default:
        icon = Icons.circle;
        iconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF16213E),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.2),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          _getActionLabel(activity.actionType),
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          _formatDateTime(activity.createdAt),
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        trailing: activity.actionDetails != null
            ? const Icon(Icons.info_outline, color: Colors.grey, size: 20)
            : null,
      ),
    );
  }

  String _getActionLabel(String actionType) {
    final labels = {
      'login': 'Login',
      'logout': 'Logout',
      'profile_update': 'Profil aktualisiert',
      'post_create': 'Post erstellt',
      'post_delete': 'Post gelöscht',
      'comment_create': 'Kommentar erstellt',
      'comment_delete': 'Kommentar gelöscht',
      'chat_message': 'Chat-Nachricht',
      'content_flag': 'Inhalt gemeldet',
      'report_submit': 'Report eingereicht',
    };
    return labels[actionType] ?? actionType;
  }

  Widget _buildNotesTab(Color worldColor) {
    return Column(
      children: [
        // ADD NOTE BUTTON
        if (!widget.user.isRootAdmin)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _addNote,
              icon: const Icon(Icons.add),
              label: const Text('Notiz hinzufügen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: worldColor,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),

        if (_isLoadingNotes)
          Expanded(child: Center(child: CircularProgressIndicator(color: worldColor)))
        else if (_notesError != null)
          Expanded(
            child: Center(
              child: Text('Fehler: $_notesError', style: const TextStyle(color: Colors.red)),
            ),
          )
        else if (_notes.isEmpty)
          const Expanded(
            child: Center(
              child: Text('Keine Notizen', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return _buildNoteItem(note);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildNoteItem(UserNote note) {
    Color noteColor;
    IconData noteIcon;

    switch (note.noteType) {
      case 'warning':
        noteColor = Colors.orange;
        noteIcon = Icons.warning;
        break;
      case 'praise':
        noteColor = Colors.green;
        noteIcon = Icons.check_circle;
        break;
      case 'concern':
        noteColor = Colors.red;
        noteIcon = Icons.error;
        break;
      default:
        noteColor = Colors.grey;
        noteIcon = Icons.note;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: noteColor.withOpacity(0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(noteIcon, color: noteColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  note.noteType.toUpperCase(),
                  style: TextStyle(
                    color: noteColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDateTime(note.createdAt),
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note.note,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'von ${note.createdByUsername} (${note.createdByRole})',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Jetzt';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std';
    if (diff.inDays < 7) return 'vor ${diff.inDays} Tagen';
    
    return '${dt.day}.${dt.month}.${dt.year}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
