import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/music_genre.dart';
import '../../providers/simple_music_provider.dart';

/// Genre Selector Widget
///
/// Zeigt 26 Musik-Genres als klickbare Buttons in einem Grid-Layout.
/// Bei Auswahl wird automatisch eine Playlist für das Genre geladen
/// und der erste Song gestartet.
class GenreSelector extends StatelessWidget {
  final String roomId;

  const GenreSelector({Key? key, required this.roomId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleMusicProvider>(
      builder: (context, musicProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Musik-Genre auswählen',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Wähle ein Genre und die Musik startet automatisch',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Genre Grid
              Expanded(
                child: musicProvider.isLoadingGenre
                    ? _buildLoadingState(context, musicProvider)
                    : _buildGenreGrid(context, musicProvider),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Erstellt das Genre-Button-Grid
  Widget _buildGenreGrid(
    BuildContext context,
    SimpleMusicProvider musicProvider,
  ) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 Buttons pro Reihe
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: MusicGenre.values.length,
      itemBuilder: (context, index) {
        final genre = MusicGenre.values[index];
        final isActive = musicProvider.currentGenre == genre;

        return _buildGenreButton(
          context: context,
          genre: genre,
          isActive: isActive,
          onTap: () => _onGenreTap(context, musicProvider, genre),
        );
      },
    );
  }

  /// Erstellt einen einzelnen Genre-Button
  Widget _buildGenreButton({
    required BuildContext context,
    required MusicGenre genre,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji
            Text(genre.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            // Genre-Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                genre.displayName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Loading-State während Genre-Auswahl
  Widget _buildLoadingState(
    BuildContext context,
    SimpleMusicProvider musicProvider,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Lade Playlist für ${musicProvider.currentGenre?.displayName ?? "Genre"}...',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Suche beste Songs auf YouTube',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// Behandelt Genre-Button-Tap
  Future<void> _onGenreTap(
    BuildContext context,
    SimpleMusicProvider musicProvider,
    MusicGenre genre,
  ) async {
    try {
      // Genre auswählen und Playlist laden
      await musicProvider.selectGenre(roomId, genre);

      // Erfolgs-Feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(genre.emoji),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${genre.displayName} Playlist gestartet!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Fehler-Feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

/// Kompakte Genre-Auswahl als Dialog
class GenreSelectorDialog extends StatelessWidget {
  final String roomId;

  const GenreSelectorDialog({Key? key, required this.roomId}) : super(key: key);

  /// Zeigt den Genre-Selector als Dialog
  static Future<void> show(BuildContext context, String roomId) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: GenreSelector(roomId: roomId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: GenreSelector(roomId: roomId),
      ),
    );
  }
}
