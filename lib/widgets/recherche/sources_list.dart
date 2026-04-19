/// 📚 SOURCES LIST WIDGET
/// 
/// Research sources list widget with:
/// - Source cards with title, URL, excerpt
/// - Relevance score indicator
/// - Source type badges (book, article, document, website)
/// - Open URL functionality
/// - Copy URL to clipboard
/// - Publish date display
/// - Search/filter functionality
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../models/recherche_view_state.dart';

class SourcesList extends StatefulWidget {
  final List<RechercheSource> sources;
  final String? title;
  final bool showSearch;
  final VoidCallback? onSourceOpened;
  
  const SourcesList({
    super.key,
    required this.sources,
    this.title,
    this.showSearch = false,
    this.onSourceOpened,
  });

  @override
  State<SourcesList> createState() => _SourcesListState();
}

class _SourcesListState extends State<SourcesList> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RechercheSource> get _filteredSources {
    if (_searchQuery.isEmpty) {
      return widget.sources;
    }
    return widget.sources.where((source) {
      final query = _searchQuery.toLowerCase();
      return source.title.toLowerCase().contains(query) ||
             source.excerpt.toLowerCase().contains(query) ||
             source.url.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sources.isEmpty) {
      return _buildEmptyState(context);
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withValues(alpha: 0.12),
            Colors.teal.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.15),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context),
          
          // Search bar (optional)
          if (widget.showSearch && widget.sources.length > 3)
            _buildSearchBar(context),
          
          Divider(height: 1, color: Colors.grey[200]),
          
          // Sources list
          _buildSourcesList(context),
        ],
      ),
    );
  }
  
  // ==========================================================================
  // HEADER
  // ==========================================================================
  
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.source,
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title ?? 'Quellen',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_filteredSources.length} ${_filteredSources.length == 1 ? "Quelle" : "Quellen"}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // ==========================================================================
  // SEARCH BAR
  // ==========================================================================
  
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Quellen durchsuchen...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, size: 18, color: Colors.grey[600]),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: const TextStyle(fontSize: 14),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ),
    );
  }
  
  // ==========================================================================
  // SOURCES LIST
  // ==========================================================================
  
  Widget _buildSourcesList(BuildContext context) {
    final filteredSources = _filteredSources;
    
    if (filteredSources.isEmpty) {
      return _buildNoResults(context);
    }
    
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: filteredSources.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildSourceCard(
          context,
          source: filteredSources[index],
          index: index,
        );
      },
    );
  }
  
  Widget _buildSourceCard(
    BuildContext context, {
    required RechercheSource source,
    required int index,
  }) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final formattedDate = source.publishDate != null
        ? dateFormat.format(source.publishDate!)
        : null;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openUrl(context, source.url),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with index and relevance
                Row(
                  children: [
                    // Index badge
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Source type badge
                    _buildSourceTypeBadge(context, source.sourceType),
                    
                    const Spacer(),
                    
                    // Relevance indicator
                    _buildRelevanceIndicator(context, source.relevance),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Title
                Text(
                  source.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                    height: 1.3,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Excerpt
                if (source.excerpt.isNotEmpty)
                  Text(
                    source.excerpt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                // Footer row with URL and date
                Row(
                  children: [
                    // URL
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.link,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatUrl(source.url),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Date
                    if (formattedDate != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Copy URL button
                    TextButton.icon(
                      onPressed: () => _copyUrl(context, source.url),
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text('URL kopieren'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Open button
                    ElevatedButton.icon(
                      onPressed: () => _openUrl(context, source.url),
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: const Text('Öffnen'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // ==========================================================================
  // HELPER WIDGETS
  // ==========================================================================
  
  Widget _buildSourceTypeBadge(BuildContext context, String sourceType) {
    IconData icon;
    Color color;
    String label;
    
    switch (sourceType.toLowerCase()) {
      case 'book':
        icon = Icons.menu_book;
        color = Colors.brown;
        label = 'Buch';
        break;
      case 'article':
        icon = Icons.article;
        color = Colors.blue;
        label = 'Artikel';
        break;
      case 'document':
        icon = Icons.description;
        color = Colors.orange;
        label = 'Dokument';
        break;
      case 'website':
        icon = Icons.language;
        color = Colors.green;
        label = 'Website';
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
        label = 'Unbekannt';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRelevanceIndicator(BuildContext context, double relevance) {
    final percentage = (relevance * 100).toInt();
    Color color;
    
    if (relevance >= 0.8) {
      color = Colors.green;
    } else if (relevance >= 0.6) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bar_chart,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  // ==========================================================================
  // EMPTY STATES
  // ==========================================================================
  
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.source_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Quellen verfügbar',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Für diese Recherche wurden keine Quellen gefunden.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoResults(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Ergebnisse',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keine Quelle enthält "$_searchQuery"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  // ==========================================================================
  // ACTIONS
  // ==========================================================================
  
  Future<void> _openUrl(BuildContext context, String urlString) async {
    try {
      final url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        widget.onSourceOpened?.call();
      } else {
        if (context.mounted) {
          _showError(context, 'URL konnte nicht geöffnet werden');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Fehler beim Öffnen der URL');
      }
    }
  }
  
  void _copyUrl(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('URL kopiert!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }
  
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  // ==========================================================================
  // HELPER METHODS
  // ==========================================================================
  
  String _formatUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (e) {
      return url;
    }
  }
}
