import 'package:flutter/material.dart';
import 'dart:async';

/// ⚡ LAZY LOADING BUILDER - Verzögertes Laden von Widgets
class LazyLoadingBuilder extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Widget? placeholder;
  
  const LazyLoadingBuilder({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 100),
    this.placeholder,
  });
  
  @override
  State<LazyLoadingBuilder> createState() => _LazyLoadingBuilderState();
}

class _LazyLoadingBuilderState extends State<LazyLoadingBuilder> {
  bool _loaded = false;
  
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() => _loaded = true);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return widget.placeholder ?? const SizedBox.shrink();
    }
    return widget.child;
  }
}

/// 📦 MEMORY CACHE MANAGER - In-Memory Caching
class MemoryCacheManager {
  static final MemoryCacheManager _instance = MemoryCacheManager._internal();
  factory MemoryCacheManager() => _instance;
  MemoryCacheManager._internal();
  
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _timestamps = {};
  final Duration _maxAge = const Duration(minutes: 30);
  
  /// Get from cache
  T? get<T>(String key) {
    if (!_cache.containsKey(key)) return null;
    
    final timestamp = _timestamps[key];
    if (timestamp != null && DateTime.now().difference(timestamp) > _maxAge) {
      _cache.remove(key);
      _timestamps.remove(key);
      return null;
    }
    
    return _cache[key] as T?;
  }
  
  /// Put in cache
  void put<T>(String key, T value) {
    _cache[key] = value;
    _timestamps[key] = DateTime.now();
  }
  
  /// Clear cache
  void clear() {
    _cache.clear();
    _timestamps.clear();
  }
  
  /// Clear expired entries
  void clearExpired() {
    final now = DateTime.now();
    final expiredKeys = _timestamps.entries
        .where((entry) => now.difference(entry.value) > _maxAge)
        .map((entry) => entry.key)
        .toList();
    
    for (final key in expiredKeys) {
      _cache.remove(key);
      _timestamps.remove(key);
    }
  }
}

/// 🔄 ASYNC BUILDER WITH CACHE - Async Loading mit Cache
class AsyncBuilderWithCache<T> extends StatelessWidget {
  final String cacheKey;
  final Future<T> Function() future;
  final Widget Function(BuildContext, T) builder;
  final Widget Function(BuildContext)? loadingBuilder;
  final Widget Function(BuildContext, Object)? errorBuilder;
  
  const AsyncBuilderWithCache({
    super.key,
    required this.cacheKey,
    required this.future,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
  });
  
  @override
  Widget build(BuildContext context) {
    final cache = MemoryCacheManager();
    final cached = cache.get<T>(cacheKey);
    
    if (cached != null) {
      return builder(context, cached);
    }
    
    return FutureBuilder<T>(
      future: future(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingBuilder?.call(context) ??
              const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return errorBuilder?.call(context, snapshot.error!) ??
              Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (snapshot.hasData) {
          cache.put(cacheKey, snapshot.data as T);
          return builder(context, snapshot.data as T);
        }
        
        return const SizedBox.shrink();
      },
    );
  }
}

/// 📊 PERFORMANCE MONITOR - Performance-Tracking
class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};
  
  static void start(String operationName) {
    _timers[operationName] = Stopwatch()..start();
  }
  
  static void end(String operationName) {
    final timer = _timers[operationName];
    if (timer != null) {
      timer.stop();
      debugPrint('⚡ $operationName took ${timer.elapsedMilliseconds}ms');
      _timers.remove(operationName);
    }
  }
  
  static Future<T> measure<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    start(operationName);
    try {
      final result = await operation();
      end(operationName);
      return result;
    } catch (e) {
      end(operationName);
      rethrow;
    }
  }
}

/// 🎯 DEBOUNCER - Verzögerte Ausführung
class Debouncer {
  final Duration delay;
  Timer? _timer;
  
  Debouncer({this.delay = const Duration(milliseconds: 300)});
  
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }
  
  void cancel() {
    _timer?.cancel();
  }
}

/// 🔄 THROTTLER - Ratenbegrenzte Ausführung
class Throttler {
  final Duration duration;
  DateTime? _lastExecuted;
  
  Throttler({this.duration = const Duration(milliseconds: 500)});
  
  bool canExecute() {
    if (_lastExecuted == null) return true;
    return DateTime.now().difference(_lastExecuted!) >= duration;
  }
  
  void execute(VoidCallback action) {
    if (canExecute()) {
      action();
      _lastExecuted = DateTime.now();
    }
  }
}
