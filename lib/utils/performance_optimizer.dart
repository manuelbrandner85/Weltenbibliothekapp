import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 🚀 Performance Optimizer Utility
/// Zentrale Performance-Optimierungen für die Weltenbibliothek
class PerformanceOptimizer {
  // ═══════════════════════════════════════════════════════════
  // REPAINT BOUNDARY HELPERS
  // ═══════════════════════════════════════════════════════════
  
  /// Wraps a widget in RepaintBoundary for better performance
  static Widget withRepaintBoundary(Widget child, {String? debugLabel}) {
    return RepaintBoundary(
      child: child,
    );
  }
  
  /// Wraps a list item in RepaintBoundary
  static Widget optimizeListItem(Widget child) {
    return RepaintBoundary(
      child: child,
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // CONST CONSTRUCTOR HELPERS
  // ═══════════════════════════════════════════════════════════
  
  /// Creates a SizedBox for spacing
  static Widget spacing(double height) => SizedBox(height: height);
  
  /// Creates a Divider
  static const Widget divider = Divider(height: 1);
  
  // ═══════════════════════════════════════════════════════════
  // ANIMATION OPTIMIZATION
  // ═══════════════════════════════════════════════════════════
  
  /// Optimized AnimationController creation
  static AnimationController createController({
    required TickerProvider vsync,
    required Duration duration,
    double? value,
  }) {
    return AnimationController(
      vsync: vsync,
      duration: duration,
      value: value ?? 0.0,
    );
  }
  
  /// Dispose multiple controllers
  static void disposeControllers(List<AnimationController> controllers) {
    for (final controller in controllers) {
      controller.dispose();
    }
  }
  
  // ═══════════════════════════════════════════════════════════
  // LAZY LOADING HELPERS
  // ═══════════════════════════════════════════════════════════
  
  /// Delays initialization until after first frame
  static Future<void> delayedInit(VoidCallback callback) async {
    await Future.delayed(Duration.zero);
    callback();
  }
  
  /// Post-frame callback wrapper
  static void postFrameCallback(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callback();
    });
  }
  
  // ═══════════════════════════════════════════════════════════
  // LIST VIEW OPTIMIZATION
  // ═══════════════════════════════════════════════════════════
  
  /// Creates an optimized ListView.builder
  static Widget optimizedListView({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    ScrollController? controller,
    EdgeInsets? padding,
  }) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: itemBuilder(context, index),
        );
      },
      // Performance optimizations
      cacheExtent: 1000, // Larger cache for smoother scrolling
      addAutomaticKeepAlives: false, // Reduce memory usage
      addRepaintBoundaries: false, // We handle it manually
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // IMAGE OPTIMIZATION
  // ═══════════════════════════════════════════════════════════
  
  /// Optimized cached network image
  static Widget optimizedImage(
    String url, {
    double? width,
    double? height,
    BoxFit? fit,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      // Performance optimizations
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? const Icon(Icons.error);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? const CircularProgressIndicator();
      },
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // WIDGET REBUILD OPTIMIZATION
  // ═══════════════════════════════════════════════════════════
  
  /// Prevents unnecessary rebuilds using ValueListenableBuilder
  static Widget buildOnValueChange<T>({
    required ValueNotifier<T> valueListenable,
    required Widget Function(BuildContext, T, Widget?) builder,
    Widget? child,
  }) {
    return ValueListenableBuilder<T>(
      valueListenable: valueListenable,
      builder: builder,
      child: child,
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // PARTICLE SYSTEM OPTIMIZATION
  // ═══════════════════════════════════════════════════════════
  
  /// Optimized particle count based on device performance
  static int getOptimalParticleCount(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pixels = size.width * size.height;
    
    // Adjust particle count based on screen size
    if (pixels > 2000000) {
      return 200; // High-end devices
    } else if (pixels > 1000000) {
      return 100; // Mid-range devices
    } else {
      return 50; // Low-end devices
    }
  }
  
  /// Reduce particle count for better performance
  static int reduceParticleCount(int original) {
    return (original * 0.5).toInt();
  }
  
  // ═══════════════════════════════════════════════════════════
  // MEMORY OPTIMIZATION
  // ═══════════════════════════════════════════════════════════
  
  /// Clear image cache to free memory
  static void clearImageCache() {
    imageCache.clear();
    imageCache.clearLiveImages();
  }
  
  /// Optimize image cache settings
  static void optimizeImageCache() {
    imageCache.maximumSize = 100; // Limit cache size
    imageCache.maximumSizeBytes = 50 << 20; // 50 MB
  }
  
  // ═══════════════════════════════════════════════════════════
  // ANIMATION FRAME RATE OPTIMIZATION
  // ═══════════════════════════════════════════════════════════
  
  /// Throttle animation updates
  static bool shouldUpdateFrame(int frameCount, int throttle) {
    return frameCount % throttle == 0;
  }
  
  /// Get optimal frame throttle based on device
  static int getOptimalFrameThrottle() {
    // Can be adjusted based on device capabilities
    return 2; // Update every 2nd frame (30 FPS instead of 60)
  }
}

/// 🎯 Performance Metrics Helper
class PerformanceMetrics {
  static final Stopwatch _stopwatch = Stopwatch();
  
  /// Start measuring performance
  static void startMeasure() {
    _stopwatch.reset();
    _stopwatch.start();
  }
  
  /// Stop and log performance
  static void stopAndLog(String label) {
    _stopwatch.stop();
    debugPrint('⏱️ $label: ${_stopwatch.elapsedMilliseconds}ms');
  }
}
