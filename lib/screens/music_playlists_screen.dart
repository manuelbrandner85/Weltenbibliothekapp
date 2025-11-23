import 'package:flutter/material.dart';
import '../services/music_playlist_service.dart';
import '../services/auth_service.dart';

/// 🎵 Musik-Playlists Screen
///
/// Verwaltet und zeigt alle Musik-Playlists des Users
class MusicPlaylistsScreen extends StatefulWidget {
  const MusicPlaylistsScreen({super.key});

  @override
  State<MusicPlaylistsScreen> createState() => _MusicPlaylistsScreenState();
}

class _MusicPlaylistsScreenState extends State<MusicPlaylistsScreen> {
  final MusicPlaylistService _playlistService = MusicPlaylistService();
  final AuthService _authService = AuthService();

  List<MusicPlaylist> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    await _playlistService.initialize();

    final userId = _authService.userId ?? 'anonymous';
    final playlists = await _playlistService.getPlaylists(
      userId: userId,
      forceSync: true,
    );

    if (mounted) {
      setState(() {
        _playlists = playlists;
        _isLoading = false;
      });
    }
  }

  Future<void> _createPlaylist() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _CreatePlaylistDialog(),
    );

    if (result != null) {
      setState(() => _isLoading = true);

      final userId = _authService.userId ?? 'anonymous';
      final playlist = await _playlistService.createPlaylist(
        userId: userId,
        name: result['name']!,
        description: result['description'],
      );

      if (playlist != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Playlist erstellt'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadPlaylists();
      }
    }
  }

  Future<void> _deletePlaylist(MusicPlaylist playlist) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Playlist löschen?'),
        content: Text('Möchtest du "${playlist.name}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      final userId = _authService.userId ?? 'anonymous';
      final success = await _playlistService.deletePlaylist(
        playlistId: playlist.id,
        userId: userId,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Playlist gelöscht'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadPlaylists();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _loadPlaylists,
            tooltip: 'Synchronisieren',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _playlists.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadPlaylists,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _playlists.length,
                itemBuilder: (context, index) {
                  return _buildPlaylistCard(_playlists[index]);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPlaylist,
        icon: const Icon(Icons.add),
        label: const Text('Neue Playlist'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_music, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Noch keine Playlists',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Erstelle deine erste Playlist!',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createPlaylist,
            icon: const Icon(Icons.add),
            label: const Text('Playlist erstellen'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistCard(MusicPlaylist playlist) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // TODO: Open playlist detail screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Öffne Playlist: ${playlist.name}')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Cover Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                child: playlist.coverImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          playlist.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.music_note,
                              size: 40,
                              color: Colors.white,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.music_note,
                        size: 40,
                        color: Colors.white,
                      ),
              ),

              const SizedBox(width: 16),

              // Playlist Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (playlist.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        playlist.description!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.music_note,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${playlist.trackCount} Songs',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(playlist.totalDuration),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (action) {
                  switch (action) {
                    case 'delete':
                      _deletePlaylist(playlist);
                      break;
                    case 'share':
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Share-Feature kommt bald!'),
                        ),
                      );
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share),
                        SizedBox(width: 12),
                        Text('Teilen'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Löschen', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  void dispose() {
    _playlistService.dispose();
    super.dispose();
  }
}

/// Create Playlist Dialog
class _CreatePlaylistDialog extends StatefulWidget {
  const _CreatePlaylistDialog();

  @override
  State<_CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<_CreatePlaylistDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Neue Playlist'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'z.B. Mystische Klänge',
                prefixIcon: Icon(Icons.music_note),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bitte gib einen Namen ein';
                }
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beschreibung (optional)',
                hintText: 'z.B. Musik für entspannte Stunden',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text.trim(),
                'description': _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
              });
            }
          },
          child: const Text('Erstellen'),
        ),
      ],
    );
  }
}
