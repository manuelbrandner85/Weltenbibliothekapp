import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

/// Full-screen image viewer for chat media — pinch to zoom, hero animation.
class ChatImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;
  final Color accentColor;

  const ChatImageViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    required this.accentColor,
  });

  static void open(BuildContext context, {required String imageUrl, required String heroTag, required Color accentColor}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => ChatImageViewer(
          imageUrl: imageUrl,
          heroTag: heroTag,
          accentColor: accentColor,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Bild', style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: Hero(
        tag: heroTag,
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 4,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          loadingBuilder: (_, __) => Center(
            child: CircularProgressIndicator(color: accentColor, strokeWidth: 2),
          ),
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
          ),
        ),
      ),
    );
  }
}
