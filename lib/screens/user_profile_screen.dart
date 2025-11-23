import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../widgets/user_avatar.dart';
import '../widgets/online_status_indicator.dart';
import '../widgets/user_moderation_dialog.dart';
import '../widgets/cached_network_image_widget.dart';
import 'edit_profile_screen.dart';
import 'dm_conversation_screen.dart';

/// ═══════════════════════════════════════════════════════════════
/// USER PROFILE SCREEN - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// Zeigt User-Profil mit allen Informationen
/// Features:
/// - Profilbild (tappable → Vollbild)
/// - Username, Display-Name, Bio
/// - Online-Status mit "Zuletzt online"-Text
/// - Rolle-Badge (Admin, Moderator)
/// - Action-Buttons:
///   - "Nachricht senden" → DM öffnen
///   - "Blockieren" / "Entblocken"
///   - "Melden"
///   - Nur Admins: "Moderieren"
/// - Eigenes Profil: "Bearbeiten"-Button
/// ═══════════════════════════════════════════════════════════════

class UserProfileScreen extends StatefulWidget {
  final String username;

  const UserProfileScreen({super.key, required this.username});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  User? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userProvider = context.read<UserProvider>();
      final user = await userProvider.getUserByUsername(widget.username);

      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Fehler beim Laden des Profils: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_user == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DMConversationScreen(username: _user!.username),
      ),
    );
  }

  Future<void> _blockUser() async {
    if (_user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User blockieren?'),
        content: Text(
          'Möchtest du ${_user!.effectiveDisplayName} wirklich blockieren? '
          'Du wirst keine Nachrichten mehr von diesem User erhalten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Blockieren'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.blockUser(_user!.username);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_user!.effectiveDisplayName} wurde blockiert'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Zurück zur vorherigen Seite
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _reportUser() async {
    if (_user == null) return;

    final TextEditingController reasonController = TextEditingController();
    final TextEditingController detailsController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User melden'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User: ${_user!.effectiveDisplayName}'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Grund *',
                  hintText: 'Spam, Belästigung, etc.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Details (optional)',
                  hintText: 'Weitere Informationen...',
                  border: OutlineInputBorder(),
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
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bitte Grund angeben')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Melden'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      reasonController.dispose();
      detailsController.dispose();
      return;
    }

    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.reportUser(
        username: _user!.username,
        reason: reasonController.text.trim(),
        details: detailsController.text.trim().isEmpty
            ? null
            : detailsController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ User wurde gemeldet. Danke für deine Meldung!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      reasonController.dispose();
      detailsController.dispose();
    }
  }

  Future<void> _showModerationDialog() async {
    if (_user == null) return;

    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.currentUser;
    if (currentUser == null) return;

    await showUserModerationDialog(
      context,
      userId: _user!.id,
      username: _user!.username,
      currentUserRole: currentUser.role,
    );

    // Profil neu laden nach Moderation
    _loadUserProfile();
  }

  Future<void> _navigateToEditProfile() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );

    if (updated == true) {
      _loadUserProfile(); // Reload nach Bearbeitung
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final currentUser = userProvider.currentUser;
    final isOwnProfile = currentUser?.username == widget.username;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isOwnProfile ? 'Mein Profil' : 'Profil',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _navigateToEditProfile,
            ),
        ],
      ),
      body: _buildBody(currentUser, isOwnProfile),
    );
  }

  Widget _buildBody(User? currentUser, bool isOwnProfile) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
              ),
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    if (_user == null) {
      return const Center(
        child: Text(
          'User nicht gefunden',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Profilbild
          GestureDetector(
            onTap: () {
              if (_user!.avatarUrl != null) {
                _showFullscreenAvatar();
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                UserAvatar.fromUser(
                  _user!,
                  size: AvatarSize.xlarge,
                  showRoleBadge: true,
                ),
                if (_user!.isOnline)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: OnlineStatusIndicator(
                      isOnline: true,
                      size: IndicatorSize.large,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Username & Display-Name
          Text(
            _user!.effectiveDisplayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_user!.username != _user!.effectiveDisplayName)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '@${_user!.username}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 16,
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Online-Status-Text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OnlineStatusIndicator(
                isOnline: _user!.isOnline,
                size: IndicatorSize.small,
              ),
              const SizedBox(width: 8),
              Text(
                _user!.onlineStatusText,
                style: TextStyle(
                  color: _user!.isOnline ? Colors.green : Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Rolle-Badge
          if (_user!.role != 'user')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Color(_user!.roleColor).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color(_user!.roleColor), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getRoleIcon(_user!.role),
                    color: Color(_user!.roleColor),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _user!.roleDisplayName,
                    style: TextStyle(
                      color: Color(_user!.roleColor),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Bio
          if (_user!.bio != null && _user!.bio!.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _user!.bio!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 32),

          // Action Buttons
          if (!isOwnProfile)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Nachricht senden
                  ElevatedButton.icon(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.message),
                    label: const Text('Nachricht senden'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Blockieren & Melden
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _blockUser,
                          icon: const Icon(Icons.block),
                          label: const Text('Blockieren'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _reportUser,
                          icon: const Icon(Icons.flag),
                          label: const Text('Melden'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Moderieren (nur für Admins/Moderatoren)
                  if (currentUser?.isModerator ?? false) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _showModerationDialog,
                      icon: const Icon(Icons.shield),
                      label: const Text('Moderieren'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 32),

          // Metadaten
          _buildMetadataSection(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMetadataSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informationen',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildMetadataRow(
            Icons.calendar_today,
            'Beigetreten',
            _formatDate(_user!.createdAt),
          ),
          if (_user!.email != null)
            _buildMetadataRow(Icons.email, 'E-Mail', _user!.email!),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8B5CF6), size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember',
    ];
    return '${date.day}. ${months[date.month - 1]} ${date.year}';
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'super_admin':
        return Icons.admin_panel_settings;
      case 'admin':
        return Icons.shield;
      case 'moderator':
        return Icons.gavel;
      default:
        return Icons.person;
    }
  }

  void _showFullscreenAvatar() {
    if (_user?.avatarUrl == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: CachedNetworkImageWidget(
                imageUrl: _user!.avatarUrl!,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
