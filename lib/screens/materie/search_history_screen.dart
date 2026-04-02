import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../../services/search_history_service.dart';
import '../../models/search_history.dart';

/// Search History Screen v8.0
/// 
/// Shows all past searches with:
/// - Search functionality
/// - Delete individual entries
/// - Clear all history
/// - Statistics view
/// - Click to re-search
class SearchHistoryScreen extends StatefulWidget {
  const SearchHistoryScreen({super.key});

  @override
  State<SearchHistoryScreen> createState() => _SearchHistoryScreenState();
}

class _SearchHistoryScreenState extends State<SearchHistoryScreen> {
  String _searchQuery = '';
  bool _showStats = false;
  
  List<SearchHistoryEntry> get _filteredHistory {
    if (_searchQuery.isEmpty) {
      return SearchHistoryService.getAllHistory();
    }
    return SearchHistoryService.searchHistory(_searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    final history = _filteredHistory;
    final stats = SearchHistoryService.getStatistics();
    
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(
          children: [
            Icon(Icons.history, color: Colors.cyan, size: 24),
            SizedBox(width: 8),
            Text('📜 RECHERCHE-HISTORIE'),
          ],
        ),
        actions: [
          // Stats Toggle
          IconButton(
            icon: Icon(_showStats ? Icons.close : Icons.analytics),
            tooltip: _showStats ? 'Statistiken ausblenden' : 'Statistiken anzeigen',
            onPressed: () {
              setState(() => _showStats = !_showStats);
            },
          ),
          // Clear All
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              tooltip: 'Gesamte Historie löschen',
              onPressed: () => _showClearAllDialog(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1A1A1A),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'In Historie suchen...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                prefixIcon: const Icon(Icons.search, color: Colors.cyan),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // Statistics Card
          if (_showStats)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 Statistiken',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow('Gesamt-Suchanfragen', '${stats['totalSearches']}'),
                  _buildStatRow('Einzigartige Queries', '${stats['uniqueQueries']}'),
                  _buildStatRow('Ø Ergebnisse', '${stats['averageResultCount']}'),
                ],
              ),
            ),
          
          // History List
          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Noch keine Suchanfragen'
                              : 'Keine Treffer in Historie',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final entry = history[index];
                      return _buildHistoryCard(entry);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.cyan,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(SearchHistoryEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.cyan.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        leading: const Icon(Icons.search, color: Colors.cyan),
        title: Text(
          entry.query,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              entry.formattedDate,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
            if (entry.summary != null) ...[
              const SizedBox(height: 4),
              Text(
                entry.summary!,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (entry.resultCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${entry.resultCount} Ergebnisse',
                style: const TextStyle(color: Colors.cyan, fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _deleteEntry(entry),
        ),
        onTap: () => _reSearch(entry.query),
      ),
    );
  }

  void _reSearch(String query) {
    Navigator.pop(context, query);
  }

  Future<void> _deleteEntry(SearchHistoryEntry entry) async {
    await SearchHistoryService.deleteEntry(entry.id);
    setState(() {});
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📜 Eintrag gelöscht'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          '⚠️ Gesamte Historie löschen?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Alle gespeicherten Suchanfragen werden unwiderruflich gelöscht.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              await SearchHistoryService.clearAllHistory();
              setState(() {});
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🗑️ Historie gelöscht'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text(
              'Löschen',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
