import 'package:flutter/material.dart';
import '../utils/performance_optimizer.dart';

/// 🚀 Optimized List Widget
/// High-performance list with automatic optimizations
class OptimizedListView extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Widget? header;
  final Widget? footer;
  final Widget? emptyState;
  
  const OptimizedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.header,
    this.footer,
    this.emptyState,
  });

  @override
  Widget build(BuildContext context) {
    // Show empty state if no items
    if (itemCount == 0 && emptyState != null) {
      return emptyState!;
    }
    
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: _calculateItemCount(),
      itemBuilder: (context, index) {
        // Header
        if (header != null && index == 0) {
          return PerformanceOptimizer.optimizeListItem(header!);
        }
        
        // Footer
        if (footer != null && index == _calculateItemCount() - 1) {
          return PerformanceOptimizer.optimizeListItem(footer!);
        }
        
        // Calculate actual item index
        final actualIndex = header != null ? index - 1 : index;
        
        // Build item with RepaintBoundary
        return PerformanceOptimizer.optimizeListItem(
          itemBuilder(context, actualIndex),
        );
      },
      // Performance optimizations
      cacheExtent: 1000,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false, // We handle it manually
    );
  }
  
  int _calculateItemCount() {
    int count = itemCount;
    if (header != null) count++;
    if (footer != null) count++;
    return count;
  }
}

/// 🎯 Optimized Grid View
class OptimizedGridView extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  
  const OptimizedGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 8.0,
    this.childAspectRatio = 1.0,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return PerformanceOptimizer.optimizeListItem(
          itemBuilder(context, index),
        );
      },
      // Performance optimizations
      cacheExtent: 1000,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
    );
  }
}

/// 📜 Optimized Sliver List
class OptimizedSliverList extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  
  const OptimizedSliverList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return PerformanceOptimizer.optimizeListItem(
            itemBuilder(context, index),
          );
        },
        childCount: itemCount,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
      ),
    );
  }
}

/// 🔄 Lazy Loading List
class LazyLoadingList extends StatefulWidget {
  final Future<List<dynamic>> Function(int page) loadMore;
  final Widget Function(BuildContext, dynamic) itemBuilder;
  final Widget? loadingWidget;
  final Widget? emptyWidget;
  final int itemsPerPage;
  
  const LazyLoadingList({
    super.key,
    required this.loadMore,
    required this.itemBuilder,
    this.loadingWidget,
    this.emptyWidget,
    this.itemsPerPage = 20,
  });

  @override
  State<LazyLoadingList> createState() => _LazyLoadingListState();
}

class _LazyLoadingListState extends State<LazyLoadingList> {
  final List<dynamic> _items = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final newItems = await widget.loadMore(_currentPage);
      
      if (mounted) {
        setState(() {
          _items.addAll(newItems);
          _currentPage++;
          _hasMore = newItems.length == widget.itemsPerPage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && !_isLoading) {
      return widget.emptyWidget ?? const Center(child: Text('No items'));
    }

    return OptimizedListView(
      controller: _scrollController,
      itemCount: _items.length,
      itemBuilder: (context, index) => widget.itemBuilder(context, _items[index]),
      footer: _isLoading
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: widget.loadingWidget ??
                  const Center(child: CircularProgressIndicator()),
            )
          : null,
    );
  }
}

/// 🎨 Animated List Item
class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration delay;
  
  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 50),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300) + (delay * index),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
