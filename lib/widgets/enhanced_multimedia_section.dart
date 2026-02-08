import 'package:flutter/material.dart';
import 'pdf_viewer_widget.dart';
import 'image_gallery_widget.dart';
import 'video_player_widget.dart';
import 'telegram_channels_widget.dart';

/// Enhanced Multimedia Section Widget v7.3
/// 
/// Zeigt Videos, Bilder, Dokumente DIREKT IN DER APP
class EnhancedMultimediaSection extends StatelessWidget {
  final Map<String, dynamic>? multimedia;
  final String query;

  const EnhancedMultimediaSection({
    super.key,
    required this.multimedia,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    if (multimedia == null || multimedia!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.collections, color: Colors.cyan, size: 28),
              SizedBox(width: 12),
              Text(
                '📚 Multimedia-Ressourcen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // TELEGRAM KANÄLE - 🆕 v7.3
        if (multimedia!['telegram'] != null && (multimedia!['telegram'] as List).isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TelegramChannelsWidget(
              channels: multimedia!['telegram'] as List<dynamic>,
              query: query,
            ),
          ),

        // DOKUMENTE (PDFs) - In-App Viewer
        if (multimedia!['documents'] != null && 
            (multimedia!['documents'] as List).isNotEmpty)
          _buildDocumentsSection(context, multimedia!['documents'] as List),

        // BILDER - In-App Gallery
        if (multimedia!['images'] != null && 
            (multimedia!['images'] as List).isNotEmpty)
          _buildImagesSection(context, multimedia!['images'] as List),

        // VIDEOS - In-App Player
        if (multimedia!['videos'] != null && 
            (multimedia!['videos'] as List).isNotEmpty)
          _buildVideosSection(context, multimedia!['videos'] as List),
      ],
    );
  }

  // DOKUMENTE SECTION mit In-App PDF Viewer
  Widget _buildDocumentsSection(BuildContext context, List documents) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Text(
                  'Dokumente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ...documents.map((doc) {
            return InAppPdfViewer(
              pdfUrl: doc['url'] as String,
              title: doc['title'] as String,
              description: doc['description'] as String?,
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // BILDER SECTION mit In-App Gallery
  Widget _buildImagesSection(BuildContext context, List images) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.photo_library, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text(
                  'Bildmaterial',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          InAppImageGallery(
            images: images.map((img) => img as Map<String, dynamic>).toList(),
            title: 'Bildmaterial: $query',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // VIDEOS SECTION mit In-App Player
  Widget _buildVideosSection(BuildContext context, List videos) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.video_library, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Text(
                  'Videos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ...videos.map((video) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InAppVideoPlayer(
                videoUrl: video['url'] as String,
                title: video['title'] as String,
                thumbnail: video['thumbnail'] as String?,
              ),
            );
          }),
        ],
      ),
    );
  }
}
