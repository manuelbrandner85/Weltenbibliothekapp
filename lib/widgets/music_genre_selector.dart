import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/music_genre.dart';
import '../providers/music_player_provider.dart';

/// 🎼 Music Genre Selector
/// Grid mit 26 Genre-Buttons (4 pro Reihe)
class MusicGenreSelector extends StatelessWidget {
  const MusicGenreSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicPlayerProvider>(
      builder: (context, musicPlayer, child) {
        final currentGenre = musicPlayer.currentGenre;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.music_note, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Wähle Genre',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (musicPlayer.isConnected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${musicPlayer.participantCount} Online',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Genre Grid (4 pro Reihe)
              ...MusicGenre.gridRows.map((row) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: row.map((genre) {
                      final isSelected = genre == currentGenre;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _GenreButton(
                            genre: genre,
                            isSelected: isSelected,
                            isLoading: musicPlayer.isLoading && isSelected,
                            onTap: () {
                              musicPlayer.selectGenre(genre);
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

/// Genre Button Widget
class _GenreButton extends StatelessWidget {
  final MusicGenre genre;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;

  const _GenreButton({
    required this.genre,
    required this.isSelected,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.primaryColor
          : theme.cardColor.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(12),
      elevation: isSelected ? 4 : 1,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Text(genre.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(
                genre.displayName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : theme.textTheme.bodyMedium?.color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
