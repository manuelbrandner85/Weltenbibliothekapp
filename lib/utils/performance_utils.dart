import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 🚀 Performance Utilities für Weltenbibliothek
///
/// Sammlung von Performance-Optimierungen und Helper-Funktionen

class PerformanceUtils {
  /// Debounce-Function für häufige Aufrufe (z.B. Search)
  static Function debounce(
    Function func, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    DateTime? lastCall;
    return () {
      final now = DateTime.now();
      if (lastCall == null || now.difference(lastCall!) > delay) {
        lastCall = now;
        func();
      }
    };
  }

  /// Throttle-Function für kontinuierliche Events (z.B. Scroll)
  static Function throttle(
    Function func, {
    Duration interval = const Duration(milliseconds: 100),
  }) {
    bool canCall = true;
    return () {
      if (canCall) {
        func();
        canCall = false;
        Future.delayed(interval, () {
          canCall = true;
        });
      }
    };
  }

  /// Batch-Update für mehrere State-Changes
  static void batchUpdate(List<VoidCallback> updates) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      for (final update in updates) {
        update();
      }
    });
  }

  /// Measure Widget Build Time (Debug only)
  static T measureBuildTime<T>(String label, T Function() builder) {
    if (!kDebugMode) return builder();

    final stopwatch = Stopwatch()..start();
    final result = builder();
    stopwatch.stop();

    debugPrint('⏱️ $label: ${stopwatch.elapsedMilliseconds}ms');
    return result;
  }

  /// Check if device is low-end (reduce animations)
  static bool isLowEndDevice() {
    // Vereinfachte Heuristik - könnte erweitert werden
    return false; // TODO: Implementiere Device-Performance-Check
  }

  /// Reduce animation duration for low-end devices
  static Duration getAnimationDuration(Duration normal) {
    return isLowEndDevice()
        ? Duration(milliseconds: (normal.inMilliseconds * 0.5).toInt())
        : normal;
  }
}

/// 🎯 Memoization Helper
///
/// Cached Berechnungen für teure Operationen
class Memoizer<T> {
  final Map<String, T> _cache = {};
  final Map<String, DateTime> _timestamps = {};
  final Duration cacheDuration;

  Memoizer({this.cacheDuration = const Duration(minutes: 5)});

  T call(String key, T Function() computation) {
    final now = DateTime.now();

    // Check if cached value exists and is still valid
    if (_cache.containsKey(key) && _timestamps.containsKey(key)) {
      final age = now.difference(_timestamps[key]!);
      if (age < cacheDuration) {
        return _cache[key]!;
      }
    }

    // Compute new value
    final value = computation();
    _cache[key] = value;
    _timestamps[key] = now;

    return value;
  }

  void clear() {
    _cache.clear();
    _timestamps.clear();
  }

  void invalidate(String key) {
    _cache.remove(key);
    _timestamps.remove(key);
  }
}

/// 📊 Performance Monitor
///
/// Überwacht App-Performance Metriken
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._();

  final Map<String, List<int>> _metrics = {};

  void recordMetric(String name, int milliseconds) {
    if (!kDebugMode) return;

    _metrics.putIfAbsent(name, () => []);
    _metrics[name]!.add(milliseconds);

    // Keep only last 100 measurements
    if (_metrics[name]!.length > 100) {
      _metrics[name]!.removeAt(0);
    }
  }

  Map<String, double> getAverages() {
    final averages = <String, double>{};

    for (final entry in _metrics.entries) {
      final sum = entry.value.reduce((a, b) => a + b);
      averages[entry.key] = sum / entry.value.length;
    }

    return averages;
  }

  void printReport() {
    if (!kDebugMode) return;

    debugPrint('📊 Performance Report:');
    final averages = getAverages();

    for (final entry in averages.entries) {
      debugPrint('   ${entry.key}: ${entry.value.toStringAsFixed(2)}ms');
    }
  }

  void clear() {
    _metrics.clear();
  }
}

/// 🔄 Async Task Queue
///
/// Verhindert gleichzeitige API-Calls
class AsyncTaskQueue {
  final List<Future<void> Function()> _queue = [];
  bool _isProcessing = false;

  Future<void> add(Future<void> Function() task) async {
    _queue.add(task);

    if (!_isProcessing) {
      await _processQueue();
    }
  }

  Future<void> _processQueue() async {
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final task = _queue.removeAt(0);
      try {
        await task();
      } catch (e) {
        debugPrint('❌ Task error: $e');
      }
    }

    _isProcessing = false;
  }

  void clear() {
    _queue.clear();
  }

  int get pendingTasks => _queue.length;
}

/// 💾 Memory-Efficient List Builder
///
/// Für große Listen mit vielen Items
class ChunkedListBuilder<T> {
  final List<T> items;
  final int chunkSize;

  ChunkedListBuilder({required this.items, this.chunkSize = 20});

  List<T> getChunk(int chunkIndex) {
    final start = chunkIndex * chunkSize;
    final end = (start + chunkSize).clamp(0, items.length);

    if (start >= items.length) return [];

    return items.sublist(start, end);
  }

  int get totalChunks => (items.length / chunkSize).ceil();

  bool hasChunk(int chunkIndex) {
    return chunkIndex >= 0 && chunkIndex < totalChunks;
  }
}

/// 🎨 Conditional Rendering Helper
///
/// Rendert Widgets nur wenn nötig
class ConditionalBuilder {
  static Widget build({
    required bool condition,
    required Widget Function() builder,
    Widget Function()? fallback,
  }) {
    if (condition) {
      return builder();
    } else if (fallback != null) {
      return fallback();
    } else {
      return const SizedBox.shrink();
    }
  }

  static Widget lazyBuild({
    required Future<bool> condition,
    required Widget Function() builder,
    Widget? loading,
    Widget? error,
  }) {
    return FutureBuilder<bool>(
      future: condition,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loading ?? const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return error ?? const Icon(Icons.error);
        }

        if (snapshot.data == true) {
          return builder();
        }

        return const SizedBox.shrink();
      },
    );
  }
}

/// 📱 Device Info Helper
///
/// Hilfsfunktionen für Device-spezifische Optimierungen
class DeviceOptimization {
  /// Check if current platform is Web
  static bool get isWeb => kIsWeb;

  /// Get optimal image quality based on device
  static int getImageQuality() {
    if (kIsWeb) return 85;
    return 90; // Higher quality for mobile
  }

  /// Get optimal concurrent downloads
  static int getMaxConcurrentDownloads() {
    if (kIsWeb) return 6; // Browser limit
    return 4; // Mobile conservative
  }

  /// Should use aggressive caching
  static bool get shouldUseAggressiveCaching => kIsWeb;

  /// Animation reducer for low-end devices
  static double getAnimationScale() {
    return PerformanceUtils.isLowEndDevice() ? 0.5 : 1.0;
  }
}
