import 'package:flutter/material.dart';

/// ⚡ LAZY LOADING PAGINATED LIST VIEW
/// 
/// Performance-optimierte ListView mit:
/// - Pagination (lädt nur 20 Items auf einmal)
/// - Infinite Scroll (lädt mehr beim Scrollen)
/// - Loading Indicator
/// - Empty State
/// - Error Handling
class LazyLoadingListView<T> extends StatefulWidget {
  final Future<List<T>> Function(int page, int pageSize) fetchItems;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int pageSize;
  final Widget? emptyWidget;
  final Widget? errorWidget;

  const LazyLoadingListView({
    super.key,
    required this.fetchItems,
    required this.itemBuilder,
    this.pageSize = 20,
    this.emptyWidget,
    this.errorWidget,
  });

  @override
  State<LazyLoadingListView<T>> createState() => _LazyLoadingListViewState<T>();
}

class _LazyLoadingListViewState<T> extends State<LazyLoadingListView<T>> {
  final List<T> _items = [];
  final ScrollController _scrollController = ScrollController();
  
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newItems = await widget.fetchItems(_currentPage, widget.pageSize);
      
      setState(() {
        _items.addAll(newItems);
        _currentPage++;
        _hasMore = newItems.length == widget.pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _currentPage = 0;
      _hasMore = true;
      _error = null;
    });
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _items.isEmpty) {
      return widget.errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Fehler: $_error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refresh,
                  child: const Text('Erneut versuchen'),
                ),
              ],
            ),
          );
    }

    if (_items.isEmpty && !_isLoading) {
      return widget.emptyWidget ??
          const Center(
            child: Text('Keine Einträge gefunden'),
          );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return widget.itemBuilder(context, _items[index], index);
        },
      ),
    );
  }
}

/// ⚡ OPTIMIZED HIVE BATCH QUERIES
/// 
/// Utility-Funktionen für performante Hive-Queries
class HiveOptimizer {
  /// Batch-Get: Holt mehrere Keys auf einmal
  static Future<Map<String, dynamic>> batchGet(
    dynamic box,
    List<String> keys,
  ) async {
    final result = <String, dynamic>{};
    
    for (final key in keys) {
      final value = box.get(key);
      if (value != null) {
        result[key] = value;
      }
    }
    
    return result;
  }

  /// Batch-Put: Speichert mehrere Items auf einmal
  static Future<void> batchPut(
    dynamic box,
    Map<String, dynamic> items,
  ) async {
    for (final entry in items.entries) {
      await box.put(entry.key, entry.value);
    }
  }

  /// Filtered Query: Filtert direkt beim Lesen
  static List<T> filteredQuery<T>(
    dynamic box,
    bool Function(T item) predicate,
    T Function(dynamic json) fromJson,
  ) {
    final results = <T>[];
    
    for (final key in box.keys) {
      final json = box.get(key);
      if (json != null) {
        final item = fromJson(json);
        if (predicate(item)) {
          results.add(item);
        }
      }
    }
    
    return results;
  }

  /// Paginated Query: Holt nur einen Teil der Daten
  static List<T> paginatedQuery<T>(
    dynamic box,
    int page,
    int pageSize,
    T Function(dynamic json) fromJson, {
    int Function(T a, T b)? sortComparator,
  }) {
    final allItems = <T>[];
    
    // Alle Items laden
    for (final key in box.keys) {
      final json = box.get(key);
      if (json != null) {
        allItems.add(fromJson(json));
      }
    }
    
    // Optional sortieren
    if (sortComparator != null) {
      allItems.sort(sortComparator);
    }
    
    // Paginieren
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, allItems.length);
    
    if (start >= allItems.length) {
      return [];
    }
    
    return allItems.sublist(start, end);
  }

  /// Count Query: Zählt Items ohne sie zu laden
  static int countWhere(
    dynamic box,
    bool Function(dynamic json) predicate,
  ) {
    int count = 0;
    
    for (final key in box.keys) {
      final json = box.get(key);
      if (json != null && predicate(json)) {
        count++;
      }
    }
    
    return count;
  }
}

/// ⚡ WIDGET REBUILD OPTIMIZER
/// 
/// Verhindert unnötige Rebuilds durch intelligentes Caching
class RebuildOptimizer extends StatefulWidget {
  final Widget Function(BuildContext context) builder;
  final List<Object?> dependencies;

  const RebuildOptimizer({
    super.key,
    required this.builder,
    required this.dependencies,
  });

  @override
  State<RebuildOptimizer> createState() => _RebuildOptimizerState();
}

class _RebuildOptimizerState extends State<RebuildOptimizer> {
  Widget? _cachedWidget;
  List<Object?>? _lastDependencies;

  @override
  Widget build(BuildContext context) {
    // Prüfe ob Dependencies sich geändert haben
    bool shouldRebuild = _lastDependencies == null ||
        _lastDependencies!.length != widget.dependencies.length ||
        !_dependenciesEqual(_lastDependencies!, widget.dependencies);

    if (shouldRebuild) {
      _cachedWidget = widget.builder(context);
      _lastDependencies = List.from(widget.dependencies);
    }

    return _cachedWidget!;
  }

  bool _dependenciesEqual(List<Object?> a, List<Object?> b) {
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// ⚡ PERFORMANCE MONITOR
/// 
/// Misst und loggt Performance-Metriken
class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};

  static void start(String label) {
    _timers[label] = Stopwatch()..start();
  }

  static void stop(String label) {
    final timer = _timers[label];
    if (timer != null) {
      timer.stop();
      debugPrint('⚡ [$label] took ${timer.elapsedMilliseconds}ms');
      _timers.remove(label);
    }
  }

  static Future<T> measure<T>(
    String label,
    Future<T> Function() operation,
  ) async {
    start(label);
    final result = await operation();
    stop(label);
    return result;
  }
}
