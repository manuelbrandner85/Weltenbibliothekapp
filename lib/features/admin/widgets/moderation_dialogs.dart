import 'package:flutter/material.dart';
import '../../../services/moderation_service.dart';

/// User Mute Dialog
/// Zeigt Dialog zum Sperren eines Users (24h oder permanent)
class UserMuteDialog extends StatefulWidget {
  final String world;
  final String userId;
  final String username;
  final String adminToken;
  final bool isRootAdmin;
  
  const UserMuteDialog({
    super.key,
    required this.world,
    required this.userId,
    required this.username,
    required this.adminToken,
    required this.isRootAdmin,
  });
  
  @override
  State<UserMuteDialog> createState() => _UserMuteDialogState();
}

class _UserMuteDialogState extends State<UserMuteDialog> {
  final _moderationService = ModerationService();
  final _reasonController = TextEditingController();
  String _muteType = '24h';
  bool _isLoading = false;
  
  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
  
  Future<void> _muteUser() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte Grund angeben'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    final result = await _moderationService.muteUser(
      world: widget.world,
      userId: widget.userId,
      username: widget.username,
      muteType: _muteType,
      reason: _reasonController.text.trim(),
      adminToken: widget.adminToken,
    );
    
    setState(() {
      _isLoading = false;
    });
    
    if (result['success'] == true) {
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${widget.username} wurde gesperrt ($_muteType)',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
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
    return AlertDialog(
      backgroundColor: const Color(0xFF1a1f3a),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          const Icon(Icons.block, color: Colors.red),
          const SizedBox(width: 8),
          const Text(
            'User sperren',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Username
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0E27),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Mute Type Selection
            const Text(
              'Sperr-Dauer:',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            
            // 24h Option
            RadioListTile<String>(
              value: '24h',
              groupValue: _muteType,
              onChanged: (value) {
                setState(() {
                  _muteType = value!;
                });
              },
              title: const Text(
                '24 Stunden',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Temporäre Sperre (für Normal-Admins)',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              activeColor: Colors.orange,
              tileColor: _muteType == '24h' 
                  ? Colors.orange.withOpacity(0.1)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            
            // Permanent Option (nur Root-Admin)
            RadioListTile<String>(
              value: 'permanent',
              groupValue: _muteType,
              onChanged: widget.isRootAdmin 
                  ? (value) {
                      setState(() {
                        _muteType = value!;
                      });
                    }
                  : null,
              title: Row(
                children: [
                  const Text(
                    'Permanent',
                    style: TextStyle(color: Colors.white),
                  ),
                  if (!widget.isRootAdmin) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.lock,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                widget.isRootAdmin
                    ? 'Dauerhafte Sperre (nur Root-Admin)'
                    : 'Nur für Root-Admins verfügbar',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              activeColor: Colors.red,
              tileColor: _muteType == 'permanent'
                  ? Colors.red.withOpacity(0.1)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            
            // Reason TextField
            const Text(
              'Grund (erforderlich):',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'z.B. Beleidigung, Spam, etc.',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF0A0E27),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.orange),
                ),
              ),
            ),
            
            // Warning
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Der User kann nach der Sperre nicht mehr posten oder kommentieren.',
                      style: TextStyle(
                        color: Colors.red[300],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text(
            'Abbrechen',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _muteUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: _muteType == 'permanent' ? Colors.red : Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Sperren'),
        ),
      ],
    );
  }
}

/// Flag Content Dialog
/// Dialog zum Melden von inappropriatem Content
class FlagContentDialog extends StatefulWidget {
  final String world;
  final String contentType;
  final String contentId;
  final String? contentAuthorId;
  final String? contentAuthorUsername;
  final String adminToken;
  
  const FlagContentDialog({
    super.key,
    required this.world,
    required this.contentType,
    required this.contentId,
    this.contentAuthorId,
    this.contentAuthorUsername,
    required this.adminToken,
  });
  
  @override
  State<FlagContentDialog> createState() => _FlagContentDialogState();
}

class _FlagContentDialogState extends State<FlagContentDialog> {
  final _moderationService = ModerationService();
  final _reasonController = TextEditingController();
  bool _isLoading = false;
  
  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
  
  Future<void> _flagContent() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte Grund angeben'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    final result = await _moderationService.flagContent(
      world: widget.world,
      contentType: widget.contentType,
      contentId: widget.contentId,
      contentAuthorId: widget.contentAuthorId,
      contentAuthorUsername: widget.contentAuthorUsername,
      reason: _reasonController.text.trim(),
      adminToken: widget.adminToken,
    );
    
    setState(() {
      _isLoading = false;
    });
    
    if (result['success'] == true) {
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Content wurde gemeldet'),
            backgroundColor: Colors.green,
          ),
        );
      }
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
    return AlertDialog(
      backgroundColor: const Color(0xFF1a1f3a),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          const Icon(Icons.flag, color: Colors.orange),
          const SizedBox(width: 8),
          const Text(
            'Content melden',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0E27),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.contentType == 'post' ? Icons.article : Icons.comment,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.contentType == 'post' ? 'Post' : 'Kommentar',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.contentAuthorUsername != null) ...[
                    const Spacer(),
                    Text(
                      'von ${widget.contentAuthorUsername}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Reason TextField
            const Text(
              'Grund der Meldung:',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'z.B. Beleidigung, Fehlinformation, Spam, etc.',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF0A0E27),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.orange),
                ),
              ),
            ),
            
            // Info
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Die Meldung wird an den Root-Admin weitergeleitet.',
                      style: TextStyle(
                        color: Colors.blue[300],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text(
            'Abbrechen',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _flagContent,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Melden'),
        ),
      ],
    );
  }
}
