import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import '../providers/music_library_provider.dart';

/// 🎵 Musik-Player Screen für Weltenbibliothek
class MusicPlayerScreen extends StatelessWidget {
  const MusicPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final libraryProvider = Provider.of<MusicLibraryProvider>(context);
    final content = playerProvider.currentContent;

    if (content == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Player'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Kein Content geladen')),
      );
    }

    final isFavorite = libraryProvider.isFavorite(content.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jetzt läuft'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: () {
              libraryProvider.toggleFavorite(content);
            },
          ),
          IconButton(
            icon: const Icon(Icons.library_add),
            onPressed: () {
              libraryProvider.addToLibrary(content);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Zur Bibliothek hinzugefügt'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.withValues(alpha: 0.3), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Album Art / Thumbnail
                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: content.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[800],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.music_note,
                          size: 100,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Titel & Autor
                Text(
                  content.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  content.author,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Progress Bar
                Column(
                  children: [
                    Slider(
                      value: playerProvider.progress.clamp(0.0, 1.0),
                      onChanged: (value) {
                        final position = playerProvider.duration * value;
                        playerProvider.seek(position);
                      },
                      activeColor: Colors.deepPurple,
                      inactiveColor: Colors.white24,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            playerProvider.formatDuration(
                              playerProvider.position,
                            ),
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            playerProvider.formatDuration(
                              playerProvider.duration,
                            ),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Playback Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Previous (deaktiviert in v1)
                    IconButton(
                      iconSize: 40,
                      icon: const Icon(Icons.skip_previous),
                      color: Colors.white38,
                      onPressed: null,
                    ),

                    const SizedBox(width: 20),

                    // Play/Pause
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.deepPurple,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: IconButton(
                        iconSize: 64,
                        icon: Icon(
                          playerProvider.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        color: Colors.white,
                        onPressed: () {
                          playerProvider.togglePlayPause();
                        },
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Next (deaktiviert in v1)
                    IconButton(
                      iconSize: 40,
                      icon: const Icon(Icons.skip_next),
                      color: Colors.white38,
                      onPressed: null,
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Kategorie-Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.deepPurple, width: 1),
                  ),
                  child: Text(
                    content.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
