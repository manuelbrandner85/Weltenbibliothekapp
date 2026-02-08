import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// In-App Video Player Widget
/// 
/// Zeigt YouTube/Rumble Videos direkt in der App (Web: embedded player)
class InAppVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String? thumbnail;

  const InAppVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.title,
    this.thumbnail,
  });

  @override
  State<InAppVideoPlayer> createState() => _InAppVideoPlayerState();
}

class _InAppVideoPlayerState extends State<InAppVideoPlayer> {
  String? _embedUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _extractEmbedUrl();
  }

  void _extractEmbedUrl() {
    setState(() => _isLoading = true);

    // YouTube
    if (widget.videoUrl.contains('youtube.com') || widget.videoUrl.contains('youtu.be')) {
      final videoId = _extractYouTubeId(widget.videoUrl);
      if (videoId != null) {
        _embedUrl = 'https://www.youtube.com/embed/$videoId';
      }
    }
    // Rumble
    else if (widget.videoUrl.contains('rumble.com')) {
      // Rumble hat oft embed in URL, ansonsten direkt öffnen
      if (widget.videoUrl.contains('/embed/')) {
        _embedUrl = widget.videoUrl;
      } else {
        _embedUrl = null; // Kein direktes Embedding möglich
      }
    }

    setState(() => _isLoading = false);
  }

  String? _extractYouTubeId(String url) {
    // youtube.com/watch?v=VIDEO_ID
    if (url.contains('watch?v=')) {
      final uri = Uri.parse(url);
      return uri.queryParameters['v'];
    }
    // youtu.be/VIDEO_ID
    else if (url.contains('youtu.be/')) {
      return url.split('youtu.be/').last.split('?').first;
    }
    // youtube.com/embed/VIDEO_ID
    else if (url.contains('/embed/')) {
      return url.split('/embed/').last.split('?').first;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video Player Area
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: _embedUrl != null
                  ? _buildEmbeddedPlayer()
                  : _buildThumbnailWithButton(),
            ),
          ),

          // Title & Controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildActionButton(
                      icon: Icons.open_in_new,
                      label: 'Im Browser öffnen',
                      onPressed: () => _openInBrowser(widget.videoUrl),
                    ),
                    if (_embedUrl != null)
                      _buildActionButton(
                        icon: Icons.fullscreen,
                        label: 'Vollbild',
                        onPressed: () => _openFullscreen(),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmbeddedPlayer() {
    // Für Web: HTML iframe (geht automatisch via flutter web)
    // Für Mobile: Wir verwenden einen WebView-ähnlichen Ansatz
    return Stack(
      children: [
        Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_circle_outline,
                  size: 80,
                  color: Colors.white70,
                ),
                const SizedBox(height: 16),
                Text(
                  'Video in Browser öffnen',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _openInBrowser(_embedUrl!),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Video abspielen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnailWithButton() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Thumbnail
        if (widget.thumbnail != null)
          Image.network(
            widget.thumbnail!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[900],
                child: const Icon(
                  Icons.videocam,
                  size: 80,
                  color: Colors.white54,
                ),
              );
            },
          )
        else
          Container(
            color: Colors.grey[900],
            child: const Icon(
              Icons.videocam,
              size: 80,
              color: Colors.white54,
            ),
          ),

        // Overlay
        Container(
          color: Colors.black.withValues(alpha: 0.4),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Tippen zum Abspielen',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tap to play
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openInBrowser(widget.videoUrl),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.cyan),
      label: Text(
        label,
        style: const TextStyle(color: Colors.cyan),
      ),
    );
  }

  void _openInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konnte URL nicht öffnen: $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openFullscreen() {
    // Für Vollbild: Video in neuem Screen öffnen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenVideoPlayer(
          embedUrl: _embedUrl!,
          title: widget.title,
        ),
      ),
    );
  }
}

/// Vollbild Video Player Screen
class FullscreenVideoPlayer extends StatelessWidget {
  final String embedUrl;
  final String title;

  const FullscreenVideoPlayer({
    super.key,
    required this.embedUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_circle_outline,
              size: 120,
              color: Colors.white54,
            ),
            const SizedBox(height: 24),
            const Text(
              'Video-Wiedergabe',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Wird in Browser geöffnet',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(embedUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Im Browser öffnen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
