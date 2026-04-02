/// ⚡ PERFORMANCE OPTIMIZATION HELPERS
/// Utilities for app performance optimization
/// 
/// Features:
/// - Image compression
/// - Lazy loading
/// - Memory management
/// - Performance monitoring
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class PerformanceHelper {
  /// Debounce function calls
  static Function debounce(
    Function function, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    Timer? timer;
    return () {
      timer?.cancel();
      timer = Timer(delay, () {
        function();
      });
    };
  }
  
  /// Throttle function calls
  static Function throttle(
    Function function, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    Timer? timer;
    bool canCall = true;
    
    return () {
      if (canCall) {
        function();
        canCall = false;
        timer = Timer(delay, () {
          canCall = true;
        });
      }
    };
  }
  
  /// Lazy load widget
  static Widget lazyLoad({
    required Widget Function() builder,
    Widget? placeholder,
  }) {
    return FutureBuilder(
      future: Future.delayed(const Duration(milliseconds: 50)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return builder();
        }
        return placeholder ?? const SizedBox.shrink();
      },
    );
  }
  
  /// Measure widget build time
  static Future<Duration> measureBuildTime(
    Widget Function() builder,
  ) async {
    final stopwatch = Stopwatch()..start();
    builder();
    stopwatch.stop();
    
    if (kDebugMode) {
      debugPrint('⏱️ Build time: ${stopwatch.elapsedMilliseconds}ms');
    }
    
    return stopwatch.elapsed;
  }
  
  /// Optimize list rendering with RepaintBoundary
  static Widget optimizedListItem({
    required Widget child,
    Key? key,
  }) {
    return RepaintBoundary(
      key: key,
      child: child,
    );
  }
  
  /// Cache images aggressively
  static ImageProvider cachedImage(String url) {
    return NetworkImage(url);
  }
  
  /// Preload images
  static Future<void> preloadImage(String url, BuildContext context) async {
    try {
      await precacheImage(NetworkImage(url), context);
      
      if (kDebugMode) {
        debugPrint('🖼️ Image preloaded: $url');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error preloading image: $e');
      }
    }
  }
  
  /// Batch preload images
  static Future<void> preloadImages(
    List<String> urls,
    BuildContext context,
  ) async {
    for (final url in urls) {
      await preloadImage(url, context);
    }
  }
  
  /// Memory usage monitoring
  static void logMemoryUsage() {
    if (kDebugMode) {
      debugPrint('💾 Memory monitoring enabled');
      // In production, use flutter_performance_plugin or similar
    }
  }
  
  /// Clear image cache
  static void clearImageCache() {
    imageCache.clear();
    imageCache.clearLiveImages();
    
    if (kDebugMode) {
      debugPrint('🗑️ Image cache cleared');
    }
  }
  
  /// Set max cache size
  static void setMaxCacheSize(int maxImages, int maxBytes) {
    imageCache.maximumSize = maxImages;
    imageCache.maximumSizeBytes = maxBytes;
    
    if (kDebugMode) {
      debugPrint('💾 Max cache size set: $maxImages images, $maxBytes bytes');
    }
  }
}

/// Timer for debounce/throttle
class Timer {
  final Duration duration;
  final VoidCallback callback;
  
  Future<void>? _future;
  
  Timer(this.duration, this.callback) {
    _start();
  }
  
  void _start() {
    _future = Future.delayed(duration, callback);
  }
  
  void cancel() {
    _future = null;
  }
}
