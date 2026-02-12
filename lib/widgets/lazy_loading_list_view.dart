/// 📄 WELTENBIBLIOTHEK - LAZY LOADING LIST WIDGET
/// Pagination & Infinite Scroll for large lists
/// 
/// Features:
/// - Automatic pagination (load more on scroll)
/// - Pull-to-refresh
/// - Loading indicators
/// - Error handling
/// - Empty state
/// 
/// Usage:
/// ```dart
/// LazyLoadingListView<Message>(
///   itemBuilder: (context, message, index) => MessageTile(message),
///   loadMore: (page) async => await fetchMessages(page),
///   emptyMessage: 'Keine Nachrichten',
/// )
/// ```
library;

import 'package:flutter/material.dart';

class LazyLoadingListView<T> extends StatefulWidget {
  /// Builder for each item
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  
  /// Function to load more items
  /// Returns list of items for the requested page
  final Future<List<T>> Function(int page) loadMore;
  
  /// Message when list is empty
  final String emptyMessage;
  
  /// Items per page (default: 20)
  final int itemsPerPage;
  
  /// Enable pull-to-refresh (default: true)
  final bool enableRefresh;
  
  /// Custom loading widget
  final Widget? loadingWidget;
  
  /// Custom error widget
  final Widget Function(String error)? errorBuilder;
  
  /// Scroll controller (optional)
  final ScrollController? controller;
  
  /// Item separator
  final Widget? separator;

  const LazyLoadingListView({
    super.key,
    required this.itemBuilder,
    required this.loadMore,
    this.emptyMessage = 'Keine Daten vorhanden',
    this.itemsPerPage = 20,
    this.enableRefresh = true,
    this.loadingWidget,
    this.errorBuilder,
    this.controller,
    this.separator,
  });

  @override
  State<LazyLoadingListView<T>> createState() => _LazyLoadingListViewState<T>();
}

class _LazyLoadingListViewState<T> extends State<LazyLoadingListView<T>> {
  final ScrollController _scrollController = ScrollController();
  final List<T> _items = [];
  
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    
    // Use provided controller or create new one
    final controller = widget.controller ?? _scrollController;
    
    // Listen for scroll events
    controller.addListener(_onScroll);
    
    // Load initial data
    _loadInitialData();
  }
  
  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }
  
  /// Load initial page
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _items.clear();
      _hasMore = true;
    });
    
    await _loadPage(_currentPage);
  }
  
  /// Load specific page
  Future<void> _loadPage(int page) async {
    if (_isLoading || !_hasMore) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final newItems = await widget.loadMore(page);
      
      if (mounted) {
        setState(() {
          if (newItems.length < widget.itemsPerPage) {
            _hasMore = false; // Last page
          }
          
          _items.addAll(newItems);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  /// Handle scroll events
  void _onScroll() {
    final controller = widget.controller ?? _scrollController;
    
    // Load more when scrolled to 80% of the list
    final threshold = controller.position.maxScrollExtent * 0.8;
    
    if (controller.position.pixels >= threshold && !_isLoading && _hasMore) {
      _currentPage++;
      _loadPage(_currentPage);
    }
  }
  
  /// Pull-to-refresh handler
  Future<void> _onRefresh() async {
    await _loadInitialData();
  }
  
  @override
  Widget build(BuildContext context) {
    // Error state
    if (_error != null && _items.isEmpty) {
      return _buildError();
    }
    
    // Loading initial data
    if (_isLoading && _items.isEmpty) {
      return _buildLoading();
    }
    
    // Empty state
    if (_items.isEmpty) {
      return _buildEmpty();
    }
    
    // List with items
    final controller = widget.controller ?? _scrollController;
    
    Widget listView = ListView.separated(
      controller: controller,
      itemCount: _items.length + (_hasMore ? 1 : 0),
      separatorBuilder: (context, index) {
        if (index >= _items.length) return const SizedBox.shrink();
        return widget.separator ?? const SizedBox.shrink();
      },
      itemBuilder: (context, index) {
        // Loading indicator at end
        if (index >= _items.length) {
          return _buildLoadingMore();
        }
        
        // Item
        return widget.itemBuilder(context, _items[index], index);
      },
    );
    
    // Wrap with RefreshIndicator if enabled
    if (widget.enableRefresh) {
      listView = RefreshIndicator(
        onRefresh: _onRefresh,
        child: listView,
      );
    }
    
    return listView;
  }
  
  /// Build loading state (initial)
  Widget _buildLoading() {
    return widget.loadingWidget ?? 
      const Center(
        child: CircularProgressIndicator(),
      );
  }
  
  /// Build loading more indicator (at end of list)
  Widget _buildLoadingMore() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
  
  /// Build error state
  Widget _buildError() {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(_error!);
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Fehler beim Laden',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadInitialData,
            icon: const Icon(Icons.refresh),
            label: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }
  
  /// Build empty state
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            widget.emptyMessage,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          if (widget.enableRefresh) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _loadInitialData,
              icon: const Icon(Icons.refresh),
              label: const Text('Aktualisieren'),
            ),
          ],
        ],
      ),
    );
  }
}
