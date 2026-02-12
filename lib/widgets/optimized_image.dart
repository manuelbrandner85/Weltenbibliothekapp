/// 🖼️ WELTENBIBLIOTHEK - OPTIMIZED IMAGE WIDGET
/// Smart image loading with caching, progressive loading, and error handling
/// Features: Memory cache, disk cache, thumbnails, WebP support
library;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

/// Optimized image widget with caching and progressive loading
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? placeholder;
  final bool enableMemoryCache;
  final bool enableDiskCache;
  final Duration fadeInDuration;
  final Color? backgroundColor;
  
  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.enableMemoryCache = true,
    this.enableDiskCache = true,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    
    // Handle local assets
    if (imageUrl.startsWith('assets/')) {
      imageWidget = Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
      );
    } else {
      // Network image with caching
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: fadeInDuration,
        memCacheWidth: width != null ? (width! * 2).toInt() : null,
        memCacheHeight: height != null ? (height! * 2).toInt() : null,
        
        // Progressive loading with shimmer effect
        placeholder: (context, url) => _buildShimmer(context),
        
        // Error handling with fallback icon
        errorWidget: (context, url, error) => _buildErrorWidget(context),
        
        // Cache configuration
        cacheKey: _generateCacheKey(imageUrl),
      );
    }
    
    // Wrap with border radius if provided
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }
    
    // Wrap with background color if provided
    if (backgroundColor != null) {
      imageWidget = Container(
        color: backgroundColor,
        child: imageWidget,
      );
    }
    
    return imageWidget;
  }
  
  /// Generate unique cache key for better cache management
  String _generateCacheKey(String url) {
    final sizeKey = width != null && height != null 
        ? '${width!.toInt()}x${height!.toInt()}'
        : 'original';
    return '$url-$sizeKey';
  }
  
  /// Build shimmer loading effect
  Widget _buildShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor: Theme.of(context).colorScheme.surface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
  
  /// Build error widget with icon
  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}

/// Avatar image with optimized loading
class OptimizedAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final String? fallbackText;
  
  const OptimizedAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 24,
    this.fallbackText,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: ClipOval(
        child: OptimizedImage(
          imageUrl: imageUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: fallbackText,
        ),
      ),
    );
  }
}

/// Thumbnail image with smart sizing
class OptimizedThumbnail extends StatelessWidget {
  final String imageUrl;
  final double size;
  final VoidCallback? onTap;
  
  const OptimizedThumbnail({
    super.key,
    required this.imageUrl,
    this.size = 80,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: OptimizedImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

/// Hero image with optimized loading for fullscreen view
class OptimizedHeroImage extends StatelessWidget {
  final String imageUrl;
  final String tag;
  final VoidCallback? onTap;
  
  const OptimizedHeroImage({
    super.key,
    required this.imageUrl,
    required this.tag,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      child: GestureDetector(
        onTap: onTap,
        child: OptimizedImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
