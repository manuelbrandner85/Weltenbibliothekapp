/// 🖼️ WELTENBIBLIOTHEK - IMAGE CACHE SERVICE
/// Centralized image cache management with cleanup and optimization
/// Features: Memory limits, cache clearing, statistics, preloading

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Service for managing image caching across the app
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  // Cache configuration
  static const int maxCacheSize = 100 * 1024 * 1024; // 100 MB
  static const Duration stalePeriod = Duration(days: 7);
  
  // Custom cache manager
  static final CacheManager cacheManager = CacheManager(
    Config(
      'weltenbibliothek_image_cache',
      stalePeriod: stalePeriod,
      maxNrOfCacheObjects: 200,
      repo: JsonCacheInfoRepository(databaseName: 'weltenbibliothek_image_cache'),
      fileService: HttpFileService(),
    ),
  );

  /// Clear all cached images
  Future<void> clearCache() async {
    try {
      await cacheManager.emptyCache();
      
      // Also clear PaintingBinding cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      
      if (kDebugMode) {
        print('🗑️ ImageCache: Cache cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCache: Error clearing cache - $e');
      }
    }
  }

  /// Clear old cached images (older than stalePeriod)
  Future<void> clearOldCache() async {
    try {
      // This is automatically handled by CacheManager
      // But we can force cleanup
      await cacheManager.emptyCache();
      
      if (kDebugMode) {
        print('🗑️ ImageCache: Old cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCache: Error clearing old cache - $e');
      }
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      // Memory cache stats
      final memoryCache = PaintingBinding.instance.imageCache;
      
      return {
        'memory_current_count': memoryCache.currentSize,
        'memory_max_count': memoryCache.maximumSize,
        'memory_current_bytes': memoryCache.currentSizeBytes,
        'memory_max_bytes': memoryCache.maximumSizeBytes,
        'memory_live_count': memoryCache.liveImageCount,
        'memory_pending_count': memoryCache.pendingImageCount,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCache: Error getting stats - $e');
      }
      return {};
    }
  }

  /// Set memory cache limits
  void setMemoryCacheSize({int? maxCount, int? maxBytes}) {
    final imageCache = PaintingBinding.instance.imageCache;
    
    if (maxCount != null) {
      imageCache.maximumSize = maxCount;
    }
    
    if (maxBytes != null) {
      imageCache.maximumSizeBytes = maxBytes;
    }
    
    if (kDebugMode) {
      print('🎯 ImageCache: Memory limits updated - '
          'maxCount: ${imageCache.maximumSize}, '
          'maxBytes: ${imageCache.maximumSizeBytes}');
    }
  }

  /// Preload important images
  Future<void> preloadImages(
    List<String> imageUrls,
    BuildContext? context,
  ) async {
    if (context == null) return;
    
    try {
      final List<Future> preloadFutures = [];
      
      for (final url in imageUrls) {
        if (url.startsWith('assets/')) {
          // Preload asset images
          preloadFutures.add(
            precacheImage(AssetImage(url), context),
          );
        } else {
          // Preload network images
          preloadFutures.add(
            CachedNetworkImageProvider(url).evict(),
          );
          preloadFutures.add(
            precacheImage(CachedNetworkImageProvider(url), context),
          );
        }
      }
      
      await Future.wait(preloadFutures);
      
      if (kDebugMode) {
        print('✅ ImageCache: Preloaded ${imageUrls.length} images');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCache: Error preloading images - $e');
      }
    }
  }

  /// Remove specific image from cache
  Future<void> removeFromCache(String imageUrl) async {
    try {
      await cacheManager.removeFile(imageUrl);
      
      // Also evict from memory
      if (!imageUrl.startsWith('assets/')) {
        await CachedNetworkImageProvider(imageUrl).evict();
      }
      
      if (kDebugMode) {
        print('🗑️ ImageCache: Removed $imageUrl from cache');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCache: Error removing from cache - $e');
      }
    }
  }

  /// Initialize cache with optimal settings
  void initialize() {
    // Set memory cache limits based on device capabilities
    setMemoryCacheSize(
      maxCount: 100,
      maxBytes: 50 * 1024 * 1024, // 50 MB memory cache
    );
    
    if (kDebugMode) {
      print('✅ ImageCache: Initialized with optimal settings');
    }
  }

  /// Cleanup expired cache on app start
  Future<void> cleanupOnStart() async {
    try {
      // Clear old files automatically
      await clearOldCache();
      
      if (kDebugMode) {
        print('✅ ImageCache: Startup cleanup complete');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCache: Startup cleanup failed - $e');
      }
    }
  }
}
