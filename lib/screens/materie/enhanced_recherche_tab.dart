/// ENHANCED RECHERCHE WRAPPER v2.0
/// Erweitert den bestehenden Recherche-Tab mit neuen Features:
/// - Search History Dropdown
/// - Bookmarks/Favorites
/// - Voice Search
/// - Quick Filters
/// - Timeout Handling
/// - Better Error Messages
/// - Theme Toggle
/// - Related Topics
/// - Offline Mode Indicator
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../services/search_history_service.dart';
import '../../services/recherche_bookmarks_service.dart';
import '../../services/voice_search_service.dart';
import '../../services/voice_assistant_service.dart';
import '../../widgets/voice_search_button.dart';
import '../../widgets/smart_suggestions_widget.dart';  // 🆕 Smart Suggestions
import '../../widgets/smart_filter_widget.dart';  // 🆕 Smart Filter
import 'recherche_tab_mobile.dart';

class EnhancedRechercheTab extends StatefulWidget {
  const EnhancedRechercheTab({super.key});

  @override
  State<EnhancedRechercheTab> createState() => _EnhancedRechercheTabState();
}

class _EnhancedRechercheTabState extends State<EnhancedRechercheTab> {
  // Services (SearchHistoryService ist static)
  final RechercheBookmarksService _bookmarksService = RechercheBookmarksService();
  final VoiceSearchService _voiceSearchService = VoiceSearchService();
  
  // State
  final TextEditingController _searchController = TextEditingController();
  List<String> _recentSearches = [];
  bool _isBookmarked = false;
  bool _showHistory = false;
  String? _activeFilter; // 'videos', 'pdfs', 'articles', 'images'
  bool _isDarkTheme = true;
  bool _isOnline = true;
  bool _isVoiceSearching = false;
  
  // Related Topics (example data - would come from backend)
  // UNUSED FIELD: final List<String> _relatedTopics = [];
  
  // Connectivity
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  @override
  void initState() {
    super.initState();
    _initServices();
    _initConnectivity();
  }
  
  Future<void> _initServices() async {
    await SearchHistoryService.init(); // Static call
    await _bookmarksService.init();
    await _loadRecentSearches();
  }
  
  Future<void> _loadRecentSearches() async {
    final searches = SearchHistoryService.getRecentHistory(limit: 10); // Static call
    if (mounted) {
      setState(() {
        _recentSearches = searches.map((e) => e.query).toList(); // Extract queries
      });
    }
  }
  
  Future<void> _initConnectivity() async {
    try {
      // TEMPORARILY DISABLED: Connectivity check causing build issues
      // final connectivityResults = await Connectivity().checkConnectivity();
      // _updateConnectionStatus(connectivityResults);
      
      // Assume online for now
      setState(() {
        _isOnline = true;
      });
          
      // Listen to changes
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
        (results) {
          _updateConnectionStatus(results);
                },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Connectivity] Init failed: $e');
      }
      // Assume online if check fails
      if (mounted) {
        setState(() {
          _isOnline = true;
        });
      }
    }
  }
  
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    if (mounted) {
      setState(() {
        // Online if any connection type is available
        _isOnline = results.any((result) => 
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet
        );
      });
      
      if (kDebugMode) {
        debugPrint('📡 [Connectivity] Status: ${_isOnline ? "Online" : "Offline"}');
        debugPrint('   → Types: ${results.map((r) => r.name).toList()}');
      }
    }
  }
  
  Future<void> _checkIfBookmarked() async {
    if (_searchController.text.trim().isEmpty) return;
    
    final bookmarked = await _bookmarksService.isBookmarked(_searchController.text);
    if (mounted) {
      setState(() {
        _isBookmarked = bookmarked;
      });
    }
  }
  
  Future<void> _toggleBookmark() async {
    if (_searchController.text.trim().isEmpty) return;
    
    if (_isBookmarked) {
      await _bookmarksService.removeBookmarkByQuery(_searchController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Lesezeichen entfernt'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      await _bookmarksService.addBookmark(
        query: _searchController.text,
        summary: 'Recherche zu: ${_searchController.text}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⭐ Lesezeichen hinzugefügt'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
    
    await _checkIfBookmarked();
  }
  
  void _startVoiceSearch() async {
    setState(() {
      _isVoiceSearching = true;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎤 Sprachsuche: Bitte sprechen Sie jetzt...'),
          duration: Duration(seconds: 3),
        ),
      );
    }
    
    try {
      final result = await _voiceSearchService.startListening(
        locale: 'de_DE',
        timeout: const Duration(seconds: 10),
      );
      
      if (mounted) {
        if (result != null && result.isNotEmpty) {
          setState(() {
            _searchController.text = result;
            _isVoiceSearching = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Erkannt: "$result"'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
          
          // Auto-save to history (static call)
          SearchHistoryService.addSearch(query: result);
          await _loadRecentSearches();
          await _checkIfBookmarked();
        } else {
          setState(() {
            _isVoiceSearching = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Keine Sprache erkannt. Bitte erneut versuchen.'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVoiceSearching = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Spracherkennung fehlgeschlagen: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _selectFilter(String? filter) {
    setState(() {
      _activeFilter = _activeFilter == filter ? null : filter;
    });
    
    if (filter != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📌 Filter aktiviert: $filter'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkTheme ? const Color(0xFF0A0A0A) : Colors.white,
      body: Column(
        children: [
          // Enhanced Header with all new features
          _buildEnhancedHeader(),
          
          // 🆕 Smart Search Suggestions Widget
          SmartSuggestionsWidget(
            onSuggestionTap: (suggestion) {
              // Execute search with suggestion
              _searchController.text = suggestion;
              SearchHistoryService.addSearch(query: suggestion);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Suche: "$suggestion"'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.blue.shade700,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          
          // 🆕 Smart Filter Widget
          SmartFilterWidget(
            onFilterChanged: (activeTags) {
              if (kDebugMode) {
                debugPrint('🏷️ Active filters: $activeTags');
              }
              // TODO: Filter recherche results by tags
              if (mounted && activeTags.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Filter: ${activeTags.join(", ")}'),
                    backgroundColor: Colors.purple.shade700,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            showTrending: true,
          ),
          
          // Original Recherche Tab (wrapped)
          const Expanded(
            child: MobileOptimierterRechercheTab(),
          ),
        ],
      ),
      // Voice Search Button (Floating)
      floatingActionButton: VoiceSearchButton(
        onSearchQuery: (query) {
          // Execute voice search
          _searchController.text = query;
          SearchHistoryService.addSearch(query: query);
          
          // Show success feedback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.mic, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Suche nach: "$query"'),
                    ),
                  ],
                ),
                backgroundColor: Colors.purple.shade700,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        onVoiceCommand: (command) {
          // Handle voice commands
          if (kDebugMode) {
            debugPrint('🎤 Voice Command: $command');
          }
          
          // Navigate based on command
          if (command.type == VoiceCommandType.navigate && command.target != null) {
            // TODO: Implement navigation routing
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Navigation zu: ${command.target}'),
                  backgroundColor: Colors.blue.shade700,
                ),
              );
            }
          }
        },
      ),
    );
  }
  
  Widget _buildEnhancedHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDarkTheme
              ? [
                  const Color(0xFF1976D2).withValues(alpha: 0.3),
                  const Color(0xFF0D47A1).withValues(alpha: 0.2),
                ]
              : [
                  const Color(0xFF64B5F6),
                  const Color(0xFF2196F3),
                ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top Row: Title + Theme Toggle + Bookmarks Button
            Row(
              children: [
                Expanded(
                  child: Text(
                    'WELTENBIBLIOTHEK',
                    style: TextStyle(
                      color: _isDarkTheme ? Colors.white : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                
                // Offline Indicator
                if (!_isOnline) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          'Offline',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                
                // Theme Toggle
                IconButton(
                  icon: Icon(
                    _isDarkTheme ? Icons.light_mode : Icons.dark_mode,
                    color: _isDarkTheme ? Colors.white : Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isDarkTheme = !_isDarkTheme;
                    });
                  },
                  tooltip: 'Theme wechseln',
                ),
                
                // Bookmarks Button
                IconButton(
                  icon: Icon(
                    Icons.bookmarks,
                    color: _isDarkTheme ? Colors.white : Colors.white,
                  ),
                  onPressed: () => _showBookmarksDialog(),
                  tooltip: 'Lesezeichen',
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Search Field with Voice + History + Bookmark
            Row(
              children: [
                // History Dropdown Button
                IconButton(
                  icon: Icon(
                    _showHistory ? Icons.keyboard_arrow_up : Icons.history,
                    color: _isDarkTheme ? Colors.white70 : Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _showHistory = !_showHistory;
                    });
                  },
                  tooltip: 'Suchverlauf',
                ),
                
                // Search Field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: _isDarkTheme ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Suchen...',
                      hintStyle: TextStyle(
                        color: _isDarkTheme ? Colors.white38 : Colors.black38,
                      ),
                      filled: true,
                      fillColor: _isDarkTheme
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: _isDarkTheme ? Colors.white70 : Colors.white,
                      ),
                    ),
                    onChanged: (value) {
                      _checkIfBookmarked();
                    },
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        SearchHistoryService.addSearch(query: value); // Static call
                        _loadRecentSearches();
                      }
                    },
                  ),
                ),
                
                // Voice Search Button (Animated while listening)
                IconButton(
                  icon: _isVoiceSearching
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _isDarkTheme ? Colors.red : Colors.red,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.mic,
                          color: _isDarkTheme ? Colors.white70 : Colors.white,
                        ),
                  onPressed: _isVoiceSearching ? null : _startVoiceSearch,
                  tooltip: _isVoiceSearching ? 'Hört zu...' : 'Sprachsuche',
                ),
                
                // Bookmark Toggle Button
                IconButton(
                  icon: Icon(
                    _isBookmarked ? Icons.star : Icons.star_border,
                    color: _isBookmarked
                        ? Colors.amber
                        : (_isDarkTheme ? Colors.white70 : Colors.white),
                  ),
                  onPressed: _toggleBookmark,
                  tooltip: _isBookmarked ? 'Lesezeichen entfernen' : 'Lesezeichen hinzufügen',
                ),
              ],
            ),
            
            // History Dropdown
            if (_showHistory && _recentSearches.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isDarkTheme
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Letzte Suchen:',
                          style: TextStyle(
                            color: _isDarkTheme ? Colors.white70 : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            SearchHistoryService.clearAllHistory(); // Static call
                            _loadRecentSearches();
                            setState(() {
                              _showHistory = false;
                            });
                          },
                          child: Text(
                            'Löschen',
                            style: TextStyle(
                              color: Colors.red.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _recentSearches.map((search) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _searchController.text = search;
                              _showHistory = false;
                            });
                            _checkIfBookmarked();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _isDarkTheme
                                  ? const Color(0xFF1976D2).withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              search,
                              style: TextStyle(
                                color: _isDarkTheme ? Colors.white : Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
            
            // Quick Filter Chips
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('📺 Videos', 'videos'),
                  const SizedBox(width: 8),
                  _buildFilterChip('📄 PDFs', 'pdfs'),
                  const SizedBox(width: 8),
                  _buildFilterChip('📰 Artikel', 'articles'),
                  const SizedBox(width: 8),
                  _buildFilterChip('🖼️ Bilder', 'images'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilterChip(String label, String filterValue) {
    final isActive = _activeFilter == filterValue;
    
    return InkWell(
      onTap: () => _selectFilter(filterValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF1976D2)
              : (_isDarkTheme
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? const Color(0xFF1976D2)
                : (_isDarkTheme ? Colors.white24 : Colors.white54),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? Colors.white
                : (_isDarkTheme ? Colors.white70 : Colors.white),
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  void _showBookmarksDialog() async {
    final bookmarks = await _bookmarksService.getBookmarks();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkTheme ? const Color(0xFF1A1A2E) : Colors.white,
        title: Row(
          children: [
            Icon(
              Icons.bookmarks,
              color: _isDarkTheme ? Colors.amber : Colors.blue,
            ),
            const SizedBox(width: 8),
            Text(
              'Lesezeichen',
              style: TextStyle(
                color: _isDarkTheme ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: bookmarks.isEmpty
            ? SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    'Keine Lesezeichen vorhanden',
                    style: TextStyle(
                      color: _isDarkTheme ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ),
              )
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = bookmarks[index];
                    return ListTile(
                      leading: const Icon(Icons.star, color: Colors.amber),
                      title: Text(
                        bookmark.query,
                        style: TextStyle(
                          color: _isDarkTheme ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        '${bookmark.sourceCount} Quellen • ${_formatDate(bookmark.timestamp)}',
                        style: TextStyle(
                          color: _isDarkTheme ? Colors.white54 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: _isDarkTheme ? Colors.red.withValues(alpha: 0.7) : Colors.red,
                        ),
                        onPressed: () {
                          _bookmarksService.removeBookmark(bookmark.id);
                          Navigator.pop(context);
                          _showBookmarksDialog();
                        },
                      ),
                      onTap: () {
                        setState(() {
                          _searchController.text = bookmark.query;
                        });
                        Navigator.pop(context);
                        _checkIfBookmarked();
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Schließen',
              style: TextStyle(
                color: _isDarkTheme ? Colors.blue : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'Heute';
    if (diff.inDays == 1) return 'Gestern';
    if (diff.inDays < 7) return 'Vor ${diff.inDays} Tagen';
    return '${date.day}.${date.month}.${date.year}';
  }
}
