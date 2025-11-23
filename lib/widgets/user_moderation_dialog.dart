import 'package:flutter/material.dart';
import '../services/moderation_service.dart';

/// ═══════════════════════════════════════════════════════════════
/// USER MODERATION DIALOG - Ban/Mute Actions
/// ═══════════════════════════════════════════════════════════════
/// Für Admins und Moderatoren
/// Features:
/// - User bannen (temporär/permanent)
/// - User muten (Chat/Voice/Both)
/// - Ban/Mute Historie anzeigen
/// ═══════════════════════════════════════════════════════════════

class UserModerationDialog extends StatefulWidget {
  final int userId;
  final String username;
  final String currentUserRole; // 'super_admin', 'admin', or 'moderator'

  const UserModerationDialog({
    super.key,
    required this.userId,
    required this.username,
    required this.currentUserRole,
  });

  @override
  State<UserModerationDialog> createState() => _UserModerationDialogState();
}

class _UserModerationDialogState extends State<UserModerationDialog> {
  final ModerationService _moderationService = ModerationService();
  final TextEditingController _reasonController = TextEditingController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _bans = [];
  List<Map<String, dynamic>> _mutes = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bans = await _moderationService.getUserBans(widget.userId);
      final mutes = await _moderationService.getUserMutes(widget.userId);

      if (mounted) {
        setState(() {
          _bans = bans;
          _mutes = mutes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showBanDialog() async {
    String banType = 'temporary';
    int durationHours = 24;
    _reasonController.clear();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('🚫 User bannen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User: ${widget.username}'),
                const SizedBox(height: 16),

                // Ban type
                const Text(
                  'Ban-Typ:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                RadioListTile<String>(
                  title: const Text('Temporär'),
                  value: 'temporary',
                  groupValue: banType,
                  onChanged: (value) {
                    setDialogState(() {
                      banType = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                if (widget.currentUserRole == 'super_admin')
                  RadioListTile<String>(
                    title: const Text('Permanent (nur Super-Admin)'),
                    value: 'permanent',
                    groupValue: banType,
                    onChanged: (value) {
                      setDialogState(() {
                        banType = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),

                // Duration (if temporary)
                if (banType == 'temporary') ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Dauer:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<int>(
                    value: durationHours,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 Stunde')),
                      DropdownMenuItem(value: 6, child: Text('6 Stunden')),
                      DropdownMenuItem(value: 24, child: Text('24 Stunden')),
                      DropdownMenuItem(value: 72, child: Text('3 Tage')),
                      DropdownMenuItem(value: 168, child: Text('1 Woche')),
                      DropdownMenuItem(value: 720, child: Text('30 Tage')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        durationHours = value!;
                      });
                    },
                  ),
                ],

                const SizedBox(height: 16),

                // Reason
                TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Grund *',
                    border: OutlineInputBorder(),
                    hintText: 'Warum wird der User gebannt?',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bitte Grund angeben')),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Bannen'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _executeBan(banType, durationHours);
    }
  }

  Future<void> _executeBan(String banType, int durationHours) async {
    try {
      await _moderationService.banUser(
        userId: widget.userId,
        banType: banType,
        reason: _reasonController.text.trim(),
        durationHours: banType == 'temporary' ? durationHours : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ User erfolgreich gebannt'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showMuteDialog() async {
    String muteType = 'chat';
    int durationHours = 24;
    _reasonController.clear();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('🔇 User stummschalten'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User: ${widget.username}'),
                const SizedBox(height: 16),

                // Mute type
                const Text(
                  'Typ:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                RadioListTile<String>(
                  title: const Text('💬 Nur Chat'),
                  value: 'chat',
                  groupValue: muteType,
                  onChanged: (value) {
                    setDialogState(() {
                      muteType = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<String>(
                  title: const Text('🎤 Nur Voice'),
                  value: 'voice',
                  groupValue: muteType,
                  onChanged: (value) {
                    setDialogState(() {
                      muteType = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<String>(
                  title: const Text('🔇 Chat + Voice'),
                  value: 'both',
                  groupValue: muteType,
                  onChanged: (value) {
                    setDialogState(() {
                      muteType = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),

                // Duration
                const SizedBox(height: 8),
                const Text(
                  'Dauer:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<int?>(
                  value: durationHours,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: 1, child: Text('1 Stunde')),
                    const DropdownMenuItem(value: 6, child: Text('6 Stunden')),
                    const DropdownMenuItem(
                      value: 24,
                      child: Text('24 Stunden'),
                    ),
                    if (widget.currentUserRole != 'moderator') ...[
                      const DropdownMenuItem(value: 72, child: Text('3 Tage')),
                      const DropdownMenuItem(
                        value: 168,
                        child: Text('1 Woche'),
                      ),
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Permanent (Admin)'),
                      ),
                    ],
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      durationHours = value ?? 0;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Reason
                TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Grund *',
                    border: OutlineInputBorder(),
                    hintText: 'Warum wird der User stummgeschaltet?',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bitte Grund angeben')),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Muten'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _executeMute(muteType, durationHours > 0 ? durationHours : null);
    }
  }

  Future<void> _executeMute(String muteType, int? durationHours) async {
    try {
      await _moderationService.muteUser(
        userId: widget.userId,
        muteType: muteType,
        reason: _reasonController.text.trim(),
        durationHours: durationHours,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ User erfolgreich stummgeschaltet'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _unbanUser() async {
    try {
      await _moderationService.unbanUser(widget.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Ban aufgehoben'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _unmuteUser() async {
    try {
      await _moderationService.unmuteUser(widget.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Stummschaltung aufgehoben'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadHistory();
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
    final hasActiveBan = _bans.any((ban) => ban['is_active'] == 1);
    final hasActiveMute = _mutes.any((mute) => mute['is_active'] == 1);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield, size: 28, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'User Moderation',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.username,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quick Actions
                          const Text(
                            'Aktionen:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (widget.currentUserRole == 'super_admin' ||
                              widget.currentUserRole == 'admin') ...[
                            ElevatedButton.icon(
                              onPressed: hasActiveBan
                                  ? _unbanUser
                                  : _showBanDialog,
                              icon: Icon(
                                hasActiveBan ? Icons.check : Icons.block,
                              ),
                              label: Text(
                                hasActiveBan ? 'Ban aufheben' : 'User bannen',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hasActiveBan
                                    ? Colors.green
                                    : Colors.red,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 45),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],

                          ElevatedButton.icon(
                            onPressed: hasActiveMute
                                ? _unmuteUser
                                : _showMuteDialog,
                            icon: Icon(
                              hasActiveMute
                                  ? Icons.volume_up
                                  : Icons.volume_off,
                            ),
                            label: Text(
                              hasActiveMute
                                  ? 'Stummschaltung aufheben'
                                  : 'User muten',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasActiveMute
                                  ? Colors.green
                                  : Colors.orange,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 45),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Ban History
                          const Text(
                            'Ban-Historie:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_bans.isEmpty)
                            const Text(
                              'Keine Bans',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            ..._bans.map(
                              (ban) => _buildHistoryCard(ban, isBan: true),
                            ),

                          const SizedBox(height: 16),

                          // Mute History
                          const Text(
                            'Mute-Historie:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_mutes.isEmpty)
                            const Text(
                              'Keine Mutes',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            ..._mutes.map(
                              (mute) => _buildHistoryCard(mute, isBan: false),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> record, {required bool isBan}) {
    final isActive = record['is_active'] == 1;
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      (record['created_at'] as int) * 1000,
    );
    final moderator = isBan
        ? record['banned_by_username']
        : record['muted_by_username'];
    final reason = record['reason'] as String;
    final type = isBan ? record['ban_type'] : record['mute_type'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isActive ? Colors.red.shade50 : Colors.grey.shade100,
      child: ListTile(
        leading: Icon(
          isBan ? Icons.block : Icons.volume_off,
          color: isActive ? Colors.red : Colors.grey,
        ),
        title: Text(
          '$type ${isActive ? "(AKTIV)" : ""}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.red : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Von: $moderator'),
            Text('Grund: $reason'),
            Text('${createdAt.day}.${createdAt.month}.${createdAt.year}'),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

/// Helper function to show user moderation dialog
Future<void> showUserModerationDialog(
  BuildContext context, {
  required int userId,
  required String username,
  required String currentUserRole,
}) {
  return showDialog(
    context: context,
    builder: (context) => UserModerationDialog(
      userId: userId,
      username: username,
      currentUserRole: currentUserRole,
    ),
  );
}
