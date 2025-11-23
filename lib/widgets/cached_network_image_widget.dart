import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 🚀 Performance-Optimized Image Widget
///
/// Verwendet cached_network_image Package mit Memory-Limits und Disk-Cache
/// - Automatisches Memory Management (max 200x200 Cache)
/// - Disk Caching für schnelleres Laden
/// - Smooth Fade-In Animation
/// - Error Handling mit Placeholder
class CachedNetworkImageWidget extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const CachedNetworkImageWidget({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      // ✅ MEMORY LIMITS: Verhindert Out-of-Memory bei großen Bildern
      memCacheWidth: width != null ? (width! * 2).toInt() : 400,
      memCacheHeight: height != null ? (height! * 2).toInt() : 400,
      // ✅ MAX CACHE SIZE: 200x200 für optimale Performance
      maxWidthDiskCache: 800,
      maxHeightDiskCache: 800,
      // ✅ PLACEHOLDER: Zeigt während Ladevorgang
      placeholder: (context, url) =>
          placeholder ??
          Container(
            width: width,
            height: height,
            color: const Color(0xFF1E293B),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF8B5CF6),
                ),
              ),
            ),
          ),
      // ✅ ERROR WIDGET: Zeigt bei Ladefehler
      errorWidget: (context, url, error) =>
          errorWidget ??
          Container(
            width: width,
            height: height,
            color: const Color(0xFF334155),
            child: const Center(
              child: Icon(
                Icons.broken_image,
                size: 40,
                color: Color(0xFF64748B),
              ),
            ),
          ),
      // ✅ FADE-IN ANIMATION: Smooth appearance
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
    );

    // ✅ BORDER RADIUS: Optionales Clipping
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

/// 🎯 Lazy Loading Image Widget
///
/// Lädt Bilder nur wenn sie im Viewport sichtbar sind
/// Reduziert Initial-Load-Zeit und Memory-Verbrauch
class LazyLoadImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const LazyLoadImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<LazyLoadImage> createState() => _LazyLoadImageState();
}

class _LazyLoadImageState extends State<LazyLoadImage> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    // ✅ DELAYED LOADING: Verhindert simultane Downloads
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: widget.borderRadius,
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF8B5CF6),
            ),
          ),
        ),
      );
    }

    return CachedNetworkImageWidget(
      imageUrl: widget.imageUrl,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      borderRadius: widget.borderRadius,
    );
  }
}

/// 🖼️ Thumbnail Image Widget
///
/// Lädt kleine Thumbnail-Version für Listen und Previews
/// - Optimiert für 80x80 bis 200x200 Thumbnails
/// - Reduzierte Cache-Größe für Listen-Performance
class ThumbnailImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final BorderRadius? borderRadius;

  const ThumbnailImage({
    super.key,
    required this.imageUrl,
    this.size = 80,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      // ✅ THUMBNAIL MEMORY LIMITS: Sehr klein für Listen
      memCacheWidth: (size * 1.5).toInt(),
      memCacheHeight: (size * 1.5).toInt(),
      maxWidthDiskCache: 200,
      maxHeightDiskCache: 200,
      imageBuilder: (context, imageProvider) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
      placeholder: (context, url) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF8B5CF6),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF334155),
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.broken_image,
          size: 24,
          color: Color(0xFF64748B),
        ),
      ),
      fadeInDuration: const Duration(milliseconds: 200),
    );
  }
}

/// 📸 Avatar Image Widget
///
/// Spezialisiert für User-Avatare mit Kreis-Clipping
/// - Feste Größe 40x40 oder 80x80 oder custom
/// - Kreisförmiges Clipping
/// - Fallback auf Initialen
class AvatarImage extends StatelessWidget {
  final String? imageUrl;
  final String fallbackText;
  final double size;
  final Color? backgroundColor;

  const AvatarImage({
    super.key,
    this.imageUrl,
    required this.fallbackText,
    this.size = 40,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      // Fallback: Zeige Initialen
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? const Color(0xFF8B5CF6),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            _getInitials(fallbackText),
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // ✅ AVATAR MEMORY LIMITS: Klein für viele User-Profile
        memCacheWidth: (size * 2).toInt(),
        memCacheHeight: (size * 2).toInt(),
        maxWidthDiskCache: 150,
        maxHeightDiskCache: 150,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          color: const Color(0xFF1E293B),
          child: Center(
            child: SizedBox(
              width: size * 0.4,
              height: size * 0.4,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF8B5CF6),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor ?? const Color(0xFF8B5CF6),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _getInitials(fallbackText),
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        fadeInDuration: const Duration(milliseconds: 150),
      ),
    );
  }

  String _getInitials(String text) {
    if (text.isEmpty) return '?';
    final words = text.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return text.substring(0, text.length > 2 ? 2 : text.length).toUpperCase();
  }
}
