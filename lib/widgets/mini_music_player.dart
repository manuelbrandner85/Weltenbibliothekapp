import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_player_provider.dart';
import 'cached_network_image_widget.dart';

/// 🎵 Mini Music Player
/// Kompakter Player am unteren Bildschirmrand (verdeckt Chat nicht)
class MiniMusicPlayer extends StatelessWidget {
  const MiniMusicPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicPlayerProvider>(
      builder: (context, musicPlayer, child) {
        final currentTrack = musicPlayer.currentTrack;

        // Zeige Player nur wenn Song aktiv
        if (currentTrack == null) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                // Progress Bar (dünn oben)
                _ProgressBar(
                  position: musicPlayer.position,
                  duration: musicPlayer.duration,
                ),

                // Player Controls
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        // Thumbnail
                        ThumbnailImage(
                          imageUrl: currentTrack.thumbnailUrl,
                          size: 50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(width: 12),

                        // Song Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                currentTrack.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentTrack.artist,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Playback Controls
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Play/Pause Button
                            IconButton(
                              icon: musicPlayer.isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      musicPlayer.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      size: 28,
                                    ),
                              onPressed: musicPlayer.isLoading
                                  ? null
                                  : () => musicPlayer.togglePlayPause(),
                            ),

                            // Next Button
                            IconButton(
                              icon: const Icon(Icons.skip_next, size: 28),
                              onPressed: musicPlayer.isLoading
                                  ? null
                                  : () => musicPlayer.nextSong(),
                            ),

                            // Volume Button
                            IconButton(
                              icon: Icon(
                                _getVolumeIcon(musicPlayer.volume),
                                size: 24,
                              ),
                              onPressed: () =>
                                  _showVolumeDialog(context, musicPlayer),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getVolumeIcon(double volume) {
    if (volume == 0) return Icons.volume_off;
    if (volume < 0.5) return Icons.volume_down;
    return Icons.volume_up;
  }

  void _showVolumeDialog(
    BuildContext context,
    MusicPlayerProvider musicPlayer,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.volume_up),
            const SizedBox(width: 12),
            const Text('Lautstärke'),
            const Spacer(),
            Text(
              '${(musicPlayer.volume * 100).toInt()}%',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dynamische Lautstärke-Anzeige
            if (musicPlayer.maxVolume < 1.0)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Max. ${(musicPlayer.maxVolume * 100).toInt()}% (${musicPlayer.participantCount} Teilnehmer)',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Volume Slider
            Row(
              children: [
                const Icon(Icons.volume_down),
                Expanded(
                  child: Slider(
                    value: musicPlayer.volume,
                    min: 0.0,
                    max: musicPlayer.maxVolume,
                    divisions: (musicPlayer.maxVolume * 100).toInt(),
                    label: '${(musicPlayer.volume * 100).toInt()}%',
                    onChanged: (value) => musicPlayer.setVolume(value),
                  ),
                ),
                const Icon(Icons.volume_up),
              ],
            ),

            // Lautstärke-Regeln Info
            const SizedBox(height: 12),
            Text(
              '💡 Lautstärke-Regeln:\n'
              '• 1 Teilnehmer: max. 100%\n'
              '• 2 Teilnehmer: max. 50%\n'
              '• 3+ Teilnehmer: max. 10%',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }
}

/// Progress Bar Widget
class _ProgressBar extends StatelessWidget {
  final Duration position;
  final Duration duration;

  const _ProgressBar({required this.position, required this.duration});

  @override
  Widget build(BuildContext context) {
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return SizedBox(
      height: 3,
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        backgroundColor: Colors.grey.withValues(alpha: 0.2),
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
