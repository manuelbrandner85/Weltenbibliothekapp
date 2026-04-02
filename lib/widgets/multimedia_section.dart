import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Multimedia Section Widget - Zeigt Videos, Bilder, Dokumente, Audio
class MultimediaSection extends StatelessWidget {
  final Map<String, dynamic>? multimedia;

  const MultimediaSection({
    super.key,
    required this.multimedia,
  });

  @override
  Widget build(BuildContext context) {
    if (multimedia == null || multimedia!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📚 Multimedia-Ressourcen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // VIDEOS
            if (multimedia!['videos'] != null && (multimedia!['videos'] as List).isNotEmpty)
              _buildVideosSection(context, multimedia!['videos'] as List),
            
            // BILDER
            if (multimedia!['images'] != null && (multimedia!['images'] as List).isNotEmpty)
              _buildImagesSection(context, multimedia!['images'] as List),
            
            // DOKUMENTE
            if (multimedia!['documents'] != null && (multimedia!['documents'] as List).isNotEmpty)
              _buildDocumentsSection(context, multimedia!['documents'] as List),
            
            // AUDIO
            if (multimedia!['audio'] != null && (multimedia!['audio'] as List).isNotEmpty)
              _buildAudioSection(context, multimedia!['audio'] as List),
          ],
        ),
      ),
    );
  }

  Widget _buildVideosSection(BuildContext context, List videos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.video_library, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              'Videos (${videos.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...videos.map((video) => _buildMediaCard(
          context,
          title: video['title'] ?? 'Video',
          subtitle: video['platform'] ?? '',
          url: video['url'],
          icon: Icons.play_circle_filled,
          iconColor: Colors.red,
        )),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildImagesSection(BuildContext context, List images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.image, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              'Bilder (${images.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...images.map((image) => _buildMediaCard(
          context,
          title: image['title'] ?? 'Bild',
          subtitle: image['source'] ?? '',
          url: image['url'],
          icon: Icons.image,
          iconColor: Colors.blue,
        )),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDocumentsSection(BuildContext context, List documents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.description, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'Dokumente (${documents.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...documents.map((doc) => _buildMediaCard(
          context,
          title: doc['title'] ?? 'Dokument',
          subtitle: '${doc['source'] ?? ''} • ${doc['type'] ?? 'PDF'}',
          url: doc['url'],
          icon: Icons.picture_as_pdf,
          iconColor: Colors.orange,
        )),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAudioSection(BuildContext context, List audio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.audiotrack, color: Colors.purple),
            const SizedBox(width: 8),
            Text(
              'Audio (${audio.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...audio.map((a) => _buildMediaCard(
          context,
          title: a['title'] ?? 'Audio',
          subtitle: a['source'] ?? '',
          url: a['url'],
          icon: Icons.headphones,
          iconColor: Colors.purple,
        )),
      ],
    );
  }

  Widget _buildMediaCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String url,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withAlpha((0.2 * 255).round()),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
        trailing: const Icon(Icons.open_in_new),
        onTap: () => _launchUrl(context, url),
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    try {
      final Uri uri = Uri.parse(url);
      
      if (!await canLaunchUrl(uri)) {
        throw 'Kann URL nicht öffnen: $url';
      }
      
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // Öffnet im Browser
      );
      
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler beim Öffnen der URL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
