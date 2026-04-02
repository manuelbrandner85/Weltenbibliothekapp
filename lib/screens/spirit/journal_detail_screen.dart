/// Spirit Journal Detail Screen
/// Full entry view with edit/delete capabilities
library;

import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../../models/spirit_extended_models.dart';
import '../../services/spirit_journal_service.dart';

class SpiritJournalDetailScreen extends StatefulWidget {
  final SpiritJournalEntry entry;

  const SpiritJournalDetailScreen({
    super.key,
    required this.entry,
  });

  @override
  State<SpiritJournalDetailScreen> createState() =>
      _SpiritJournalDetailScreenState();
}

class _SpiritJournalDetailScreenState extends State<SpiritJournalDetailScreen> {
  final _journalService = SpiritJournalService();
  late bool _isEditMode;
  late TextEditingController _contentController;
  late String _selectedCategory;
  late String _selectedMood;
  late int _selectedRating;
  late List<String> _selectedTags;

  @override
  void initState() {
    super.initState();
    _isEditMode = false;
    _contentController = TextEditingController(text: widget.entry.content);
    _selectedCategory = widget.entry.category;
    _selectedMood = widget.entry.mood;
    _selectedRating = widget.entry.rating ?? 3;
    _selectedTags = List.from(widget.entry.tags);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    // Service hat keine updateEntry-Methode mit SpiritJournalEntry!
    // Wir müssen deleteEntry + createEntry verwenden:
    await _journalService.deleteEntry(widget.entry.id);
    await _journalService.createEntry(
      category: _selectedCategory,
      content: _contentController.text.trim(),
      mood: _selectedMood,
      tags: _selectedTags,
      rating: _selectedRating,
    );

    setState(() => _isEditMode = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Journal-Eintrag aktualisiert'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteEntry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eintrag löschen?'),
        content: const Text(
          'Dieser Journal-Eintrag wird unwiderruflich gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ABBRECHEN'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('LÖSCHEN'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _journalService.deleteEntry(widget.entry.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Journal-Eintrag gelöscht'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: Text(_isEditMode ? 'Eintrag bearbeiten' : 'Journal-Eintrag'),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isEditMode) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditMode = true),
              tooltip: 'Bearbeiten',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteEntry,
              tooltip: 'Löschen',
            ),
          ] else ...[
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditMode = false;
                  _contentController.text = widget.entry.content;
                  _selectedCategory = widget.entry.category;
                  _selectedMood = widget.entry.mood;
                  _selectedRating = widget.entry.rating ?? 3;
                  _selectedTags = List.from(widget.entry.tags);
                });
              },
              child: const Text(
                'ABBRECHEN',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: _saveChanges,
              child: const Text(
                'SPEICHERN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timestamp
            _buildTimestampCard(isDark),
            const SizedBox(height: 16),

            // Category
            _buildCategorySection(isDark),
            const SizedBox(height: 16),

            // Mood
            _buildMoodSection(isDark),
            const SizedBox(height: 16),

            // Rating
            _buildRatingSection(isDark),
            const SizedBox(height: 16),

            // Tags
            _buildTagsSection(isDark),
            const SizedBox(height: 16),

            // Content
            _buildContentSection(isDark),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTimestampCard(bool isDark) {
    final formattedDate = _formatDate(widget.entry.timestamp);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: Colors.purple[300],
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            formattedDate,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kategorie',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          if (_isEditMode)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SpiritJournalService.categories.map((cat) {
                final isSelected = cat == _selectedCategory;
                return FilterChip(
                  label: Text(
                    '${SpiritJournalService.getCategoryEmoji(cat)} ${SpiritJournalService.getCategoryName(cat)}',
                  ),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                  backgroundColor:
                      isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                  selectedColor: Colors.purple[100],
                );
              }).toList(),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${SpiritJournalService.getCategoryEmoji(_selectedCategory)} ${SpiritJournalService.getCategoryName(_selectedCategory)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.purple[800],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMoodSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stimmung',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          if (_isEditMode)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SpiritJournalService.moods.map((mood) {
                final isSelected = mood == _selectedMood;
                return FilterChip(
                  label: Text(SpiritJournalService.getMoodEmoji(mood)),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedMood = mood),
                  backgroundColor:
                      isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                  selectedColor: Colors.purple[100],
                );
              }).toList(),
            )
          else
            Text(
              '${SpiritJournalService.getMoodEmoji(_selectedMood)} ${SpiritJournalService.getMoodName(_selectedMood)}',
              style: const TextStyle(fontSize: 24),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bewertung',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          if (_isEditMode)
            Row(
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return IconButton(
                  icon: Icon(
                    starValue <= _selectedRating
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () => setState(() => _selectedRating = starValue),
                );
              }),
            )
          else
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < _selectedRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 28,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tags',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          if (_isEditMode)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                'Traum',
                'Vision',
                'Erkenntnis',
                'Dankbarkeit',
                'Herausforderung',
                'Meditation',
                'Zeichen',
              ].map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (_) => _toggleTag(tag),
                  backgroundColor:
                      isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                  selectedColor: Colors.purple[100],
                );
              }).toList(),
            )
          else if (_selectedTags.isEmpty)
            Text(
              'Keine Tags',
              style: TextStyle(
                color: isDark ? Colors.grey[600] : Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedTags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      backgroundColor: Colors.purple[50],
                      labelStyle: TextStyle(color: Colors.purple[800]),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildContentSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Eintrag',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          if (_isEditMode)
            TextField(
              controller: _contentController,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: 'Deine Gedanken...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
              ),
            )
          else
            Text(
              widget.entry.content,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: isDark ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Heute, ${date.hour}:${date.minute.toString().padLeft(2, '0')} Uhr';
    } else if (diff.inDays == 1) {
      return 'Gestern, ${date.hour}:${date.minute.toString().padLeft(2, '0')} Uhr';
    } else {
      return '${date.day}.${date.month}.${date.year}, ${date.hour}:${date.minute.toString().padLeft(2, '0')} Uhr';
    }
  }
}
