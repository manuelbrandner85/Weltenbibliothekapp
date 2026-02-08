/// Multi-Media Grid Widget
/// Zeigt extrahierte Videos, PDFs, Bilder, Audios
/// 
/// VERWENDUNG:
/// MediaGridWidget(media: response['media'])
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MediaGridWidget extends StatelessWidget {
  final Map<String, dynamic> media;

  const MediaGridWidget({
    super.key,
    required this.media,
  });

  @override
  Widget build(BuildContext context) {
    final videos = (media['videos'] as List?)?.cast<String>() ?? [];
    final pdfs = (media['pdfs'] as List?)?.cast<String>() ?? [];
    final images = (media['images'] as List?)?.cast<String>() ?? [];
    final audios = (media['audios'] as List?)?.cast<String>() ?? [];

    final totalMedia = videos.length + pdfs.length + images.length + audios.length;

    if (totalMedia == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.withValues(alpha: 0.3),
                Colors.blue.withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.perm_media, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'MULTI-MEDIA ($totalMedia)',
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

        // Videos
        if (videos.isNotEmpty) ...[
          _buildMediaSection(
            icon: Icons.play_circle_outline,
            title: 'Videos (${videos.length})',
            color: Colors.red,
            items: videos,
            context: context,
          ),
          const SizedBox(height: 16),
        ],

        // PDFs
        if (pdfs.isNotEmpty) ...[
          _buildMediaSection(
            icon: Icons.picture_as_pdf,
            title: 'PDFs (${pdfs.length})',
            color: Colors.orange,
            items: pdfs,
            context: context,
          ),
          const SizedBox(height: 16),
        ],

        // Bilder
        if (images.isNotEmpty) ...[
          _buildMediaSection(
            icon: Icons.image,
            title: 'Bilder (${images.length})',
            color: Colors.green,
            items: images,
            context: context,
          ),
          const SizedBox(height: 16),
        ],

        // Audios
        if (audios.isNotEmpty) ...[
          _buildMediaSection(
            icon: Icons.audiotrack,
            title: 'Audios (${audios.length})',
            color: Colors.blue,
            items: audios,
            context: context,
          ),
        ],
      ],
    );
  }

  Widget _buildMediaSection({
    required IconData icon,
    required String title,
    required Color color,
    required List<String> items,
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Media Grid
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.take(10).map((url) {
            return _buildMediaChip(
              url: url,
              color: color,
              context: context,
            );
          }).toList(),
        ),

        // "Mehr anzeigen" wenn >10 Items
        if (items.length > 10) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              _showAllMediaDialog(context, title, items, color);
            },
            icon: Icon(Icons.unfold_more, color: color, size: 16),
            label: Text(
              '+${items.length - 10} weitere anzeigen',
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMediaChip({
    required String url,
    required Color color,
    required BuildContext context,
  }) {
    // Extrahiere Dateinamen oder Domain
    final displayName = _extractDisplayName(url);

    return InkWell(
      onTap: () => _openUrl(url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link, color: color, size: 14),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Text(
                displayName,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _extractDisplayName(String url) {
    try {
      final uri = Uri.parse(url);
      
      // YouTube
      if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
        return '▶️ YouTube Video';
      }
      
      // Vimeo
      if (uri.host.contains('vimeo.com')) {
        return '▶️ Vimeo Video';
      }
      
      // Spotify
      if (uri.host.contains('spotify.com')) {
        return '🎵 Spotify Track';
      }
      
      // SoundCloud
      if (uri.host.contains('soundcloud.com')) {
        return '🎵 SoundCloud Track';
      }
      
      // Dateiname aus Path
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        final fileName = segments.last;
        if (fileName.length <= 30) {
          return fileName;
        }
        return '${fileName.substring(0, 27)}...';
      }
      
      // Domain als Fallback
      return uri.host;
    } catch (e) {
      return url.length > 30 ? '${url.substring(0, 27)}...' : url;
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showAllMediaDialog(
    BuildContext context,
    String title,
    List<String> items,
    Color color,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Row(
          children: [
            Icon(Icons.perm_media, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final url = items[index];
              return ListTile(
                leading: Icon(Icons.link, color: color, size: 20),
                title: Text(
                  _extractDisplayName(url),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  url,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  _openUrl(url);
                  Navigator.pop(context);
                },
              );
            },
          ),
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
