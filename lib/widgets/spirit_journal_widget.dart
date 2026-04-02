import 'package:flutter/material.dart';
import '../models/spirit_extended_models.dart';
import '../services/spirit_journal_service.dart';
import '../screens/spirit/journal_detail_screen.dart';
import '../utils/custom_page_route.dart';
import 'skeleton_widgets.dart';

/// ============================================
/// SPIRIT JOURNAL WIDGET
/// Timeline-Ansicht mit Mood-Tracking
/// ============================================

class SpiritJournalWidget extends StatefulWidget {
  final Color accentColor;

  const SpiritJournalWidget({
    super.key,
    this.accentColor = const Color(0xFF9C27B0),
  });

  @override
  State<SpiritJournalWidget> createState() => _SpiritJournalWidgetState();
}

class _SpiritJournalWidgetState extends State<SpiritJournalWidget> {
  final _service = SpiritJournalService();
  String _selectedCategory = 'all'; // 'all' oder Kategorie-Name
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    await _service.init();
    // Simulate minimum loading time for smooth UX
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allEntries = _service.entries;
    final entries = _selectedCategory == 'all'
        ? allEntries
        : _service.getEntriesByCategory(_selectedCategory);

    final journalStreak = _service.journalStreak;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF0F0F1E),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.accentColor,
                        widget.accentColor.withValues(alpha: 0.6),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_stories,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Titel & Streak
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Spirit Journal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${entries.length} ${entries.length == 1 ? "Eintrag" : "Einträge"}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                          if (journalStreak > 0) ...[
                            Text(
                              ' • ',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            const Icon(
                              Icons.local_fire_department,
                              size: 14,
                              color: Color(0xFFFF6B35),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$journalStreak ${journalStreak == 1 ? "Tag" : "Tage"}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFFF6B35),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Add-Button
                IconButton(
                  onPressed: () => _showAddDialog(),
                  icon: const Icon(Icons.add_circle, color: Colors.white),
                  tooltip: 'Neuer Eintrag',
                ),
              ],
            ),
          ),

          // Filter-Chips (Kategorien)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('Alle', 'all'),
                  const SizedBox(width: 8),
                  ...SpiritJournalService.categories.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildCategoryChip(
                        '${SpiritJournalService.getCategoryEmoji(cat)} ${SpiritJournalService.getCategoryName(cat)}',
                        cat,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Einträge-Liste
          Expanded(
            child: _isLoading
                ? LoadingList(
                    itemCount: 3,
                    itemBuilder: (context, index) => JournalEntrySkeleton(
                      accentColor: widget.accentColor,
                    ),
                  )
                : entries.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return AnimatedListItem(
                            index: index,
                            delay: const Duration(milliseconds: 50),
                            child: _buildEntryCard(entry),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  /// Kategorie-Chip
  Widget _buildCategoryChip(String label, String value) {
    final isSelected = _selectedCategory == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedCategory = selected ? value : 'all');
      },
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      selectedColor: widget.accentColor.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected
            ? widget.accentColor
            : Colors.white.withValues(alpha: 0.6),
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected
            ? widget.accentColor
            : Colors.white.withValues(alpha: 0.1),
      ),
    );
  }

  /// Entry-Card
  Widget _buildEntryCard(SpiritJournalEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDetailScreen(entry),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Datum, Kategorie, Mood
                Row(
                  children: [
                    // Mood-Emoji
                    Text(
                      SpiritJournalService.getMoodEmoji(entry.mood),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),

                    // Kategorie
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: widget.accentColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '${SpiritJournalService.getCategoryEmoji(entry.category)} ${SpiritJournalService.getCategoryName(entry.category)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Datum
                    Text(
                      _formatDate(entry.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Content (Vorschau)
                Text(
                  entry.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),

                // Tags & Rating
                if (entry.tags.isNotEmpty || entry.rating != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Tags
                      if (entry.tags.isNotEmpty)
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: entry.tags.take(3).map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                      // Rating
                      if (entry.rating != null) ...[
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(
                            entry.rating!,
                            (index) => const Icon(
                              Icons.star,
                              size: 14,
                              color: Color(0xFFFFD700),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Empty-State
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories,
              size: 64,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Dein Journal ist leer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Beginne, deine spirituelle Reise zu dokumentieren',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddDialog(),
              icon: const Icon(Icons.add),
              label: const Text('ERSTER EINTRAG'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Add-Dialog
  void _showAddDialog() {
    String selectedCategory = 'meditation';
    String content = '';
    String selectedMood = 'neutral';
    List<String> selectedTags = [];
    int rating = 3;

    Navigator.of(context).push(
      CustomDialogRoute(
        dialog: StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Neuer Journal-Eintrag'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kategorie
                    const Text('Kategorie', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: SpiritJournalService.categories.map((cat) {
                        final isSelected = cat == selectedCategory;
                        return FilterChip(
                          label: Text(
                            '${SpiritJournalService.getCategoryEmoji(cat)} ${SpiritJournalService.getCategoryName(cat)}',
                          ),
                          selected: isSelected,
                          onSelected: (_) => setDialogState(() => selectedCategory = cat),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Content
                    TextField(
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Inhalt',
                        hintText: 'Beschreibe deine Gedanken...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => content = value,
                    ),
                    const SizedBox(height: 16),

                    // Mood
                    const Text('Stimmung', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: SpiritJournalService.moods.map((mood) {
                        final isSelected = mood == selectedMood;
                        return FilterChip(
                          label: Text(SpiritJournalService.getMoodEmoji(mood)),
                          selected: isSelected,
                          onSelected: (_) => setDialogState(() => selectedMood = mood),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Rating
                    const Text('Bewertung', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return IconButton(
                          icon: Icon(
                            starValue <= rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () => setDialogState(() => rating = starValue),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('ABBRECHEN'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (content.trim().isEmpty) return;

                    await _service.createEntry(
                      category: selectedCategory,
                      content: content,
                      mood: selectedMood,
                      tags: selectedTags,
                      rating: rating,
                    );
                    if (mounted) {
                      setState(() {});
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Journal-Eintrag gespeichert! +8 Punkte'),
                          backgroundColor: widget.accentColor,
                        ),
                      );
                    }
                  },
                  child: const Text('SPEICHERN'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Detail-Screen öffnen
  void _openDetailScreen(SpiritJournalEntry entry) {
    Navigator.push(
      context,
      SlidePageRoute(
        page: SpiritJournalDetailScreen(
          entry: entry,
        ),
        direction: SlideDirection.left,
      ),
    );
  }

  /// Datum formatieren
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Heute, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Gestern';
    } else if (diff.inDays < 7) {
      return 'vor ${diff.inDays} Tagen';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
