import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../../services/research_history_service.dart';

/// 📚 RESEARCH HISTORY SCREEN
/// Displays search history with categories, timeline, and search
class ResearchHistoryScreen extends StatefulWidget {
  final Function(String)? onQuerySelected;
  
  const ResearchHistoryScreen({
    super.key,
    this.onQuerySelected,
  });
  
  @override
  State<ResearchHistoryScreen> createState() => _ResearchHistoryScreenState();
}

class _ResearchHistoryScreenState extends State<ResearchHistoryScreen> {
  final ResearchHistoryService _historyService = ResearchHistoryService();
  final TextEditingController _searchController = TextEditingController();
  
  List<ResearchHistoryEntry> _allHistory = [];
  List<ResearchHistoryEntry> _filteredHistory = [];
  Map<String, int> _categoryCounts = {};
  String? _selectedCategory;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }
  
  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    
    final history = await _historyService.getAllHistory();
    final counts = await _historyService.getCategoryCounts();
    
    if (mounted) {
      setState(() {
        _allHistory = history;
        _filteredHistory = history;
        _categoryCounts = counts;
        _isLoading = false;
      });
    }
  }
  
  void _filterByCategory(String? category) {
    setState(() {
      _selectedCategory = category;
      if (category == null) {
        _filteredHistory = _allHistory;
      } else {
        _filteredHistory = _allHistory.where((e) => e.category == category).toList();
      }
    });
  }
  
  Future<void> _searchHistory(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _filteredHistory = _allHistory);
      return;
    }
    
    final results = await _historyService.searchHistory(query);
    setState(() => _filteredHistory = results);
  }
  
  Future<void> _deleteEntry(ResearchHistoryEntry entry) async {
    await _historyService.deleteEntry(entry.timestamp.millisecondsSinceEpoch);
    _loadHistory();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Eintrag gelöscht'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  Future<void> _clearAllHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verlauf löschen?'),
        content: const Text('Möchten Sie wirklich den gesamten Suchverlauf löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _historyService.clearHistory();
      _loadHistory();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verlauf gelöscht'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Recherche-Verlauf'),
        actions: [
          if (_allHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAllHistory,
              tooltip: 'Verlauf löschen',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Suche im Verlauf...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          _searchHistory('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _searchHistory,
            ),
          ),
          
          // Category Filter Chips
          if (_categoryCounts.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // All Categories Chip
                    _buildCategoryChip(
                      label: 'Alle (${_allHistory.length})',
                      icon: '📋',
                      isSelected: _selectedCategory == null,
                      onTap: () => _filterByCategory(null),
                    ),
                    const SizedBox(width: 8),
                    
                    // Category Chips
                    ..._categoryCounts.entries.map((entry) {
                      final sampleEntry = _allHistory.firstWhere(
                        (e) => e.category == entry.key,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildCategoryChip(
                          label: '${entry.key} (${entry.value})',
                          icon: sampleEntry.categoryIcon,
                          isSelected: _selectedCategory == entry.key,
                          onTap: () => _filterByCategory(entry.key),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
          
          // History List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'Keine Ergebnisse gefunden'
                                  : 'Kein Suchverlauf',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredHistory.length,
                        itemBuilder: (context, index) {
                          final entry = _filteredHistory[index];
                          return Dismissible(
                            key: Key(entry.timestamp.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (_) => _deleteEntry(entry),
                            child: _buildHistoryCard(entry),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryChip({
    required String label,
    required String icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.cyan.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.cyan : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.cyan : Colors.white70,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHistoryCard(ResearchHistoryEntry entry) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (widget.onQuerySelected != null) {
            widget.onQuerySelected!(entry.query);
            Navigator.pop(context);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Query
              Text(
                entry.query,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Metadata
              Row(
                children: [
                  // Category
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(entry.categoryIcon),
                        const SizedBox(width: 4),
                        Text(
                          entry.category,
                          style: const TextStyle(
                            color: Colors.cyan,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Results Count
                  if (entry.resultCount > 0) ...[
                    Icon(
                      Icons.article,
                      size: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.resultCount} Ergebnisse',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  
                  // Timestamp
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    entry.formattedTime,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
