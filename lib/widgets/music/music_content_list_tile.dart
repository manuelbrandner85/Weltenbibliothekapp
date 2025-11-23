import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/audio_content.dart';
import '../../providers/player_provider.dart';
import '../../providers/music_library_provider.dart';
import '../../screens/music_player_screen.dart';

/// 🎵 Audio Content List Tile für Weltenbibliothek
class MusicContentListTile extends StatelessWidget {
  final AudioContent content;

  const MusicContentListTile({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final libraryProvider = Provider.of<MusicLibraryProvider>(context);
    final isPlaying =
        playerProvider.currentContent?.id == content.id &&
        playerProvider.isPlaying;
    final isFavorite = libraryProvider.isFavorite(content.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: const Color(0xFF1A1A2E),
      child: ListTile(
        leading: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: content.thumbnailUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[800],
                  child: const Icon(Icons.music_note, color: Colors.grey),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[800],
                  child: const Icon(Icons.music_note, color: Colors.grey),
                ),
              ),
            ),
            if (isPlaying)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.equalizer,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          content.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
            color: isPlaying ? const Color(0xFF9B59B6) : Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  content.durationFormatted,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9B59B6).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    content.category,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9B59B6),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.grey,
              ),
              onPressed: () {
                libraryProvider.toggleFavorite(content);
              },
            ),
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_circle : Icons.play_circle,
                color: const Color(0xFF9B59B6),
                size: 32,
              ),
              onPressed: () {
                if (isPlaying) {
                  playerProvider.pause();
                } else {
                  playerProvider.playContent(content);
                }
              },
            ),
          ],
        ),
        onTap: () {
          playerProvider.playContent(content);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MusicPlayerScreen()),
          );
        },
      ),
    );
  }
}
