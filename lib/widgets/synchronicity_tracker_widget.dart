import 'package:flutter/material.dart';
import '../models/spirit_extended_models.dart';
import '../services/synchronicity_service.dart';
import '../utils/custom_page_route.dart';
import 'skeleton_widgets.dart';

/// ============================================
/// SYNCHRONICITY TRACKER WIDGET
/// Timeline-Ansicht für Synchronizitäten
/// ============================================

class SynchronicityTrackerWidget extends StatefulWidget {
  final Color accentColor;

  const SynchronicityTrackerWidget({
    super.key,
    this.accentColor = const Color(0xFF9C27B0),
  });

  @override
  State<SynchronicityTrackerWidget> createState() => _SynchronicityTrackerWidgetState();
}

class _SynchronicityTrackerWidgetState extends State<SynchronicityTrackerWidget> {
  final _service = SynchronicityService();
  int _selectedSignificance = 0; // 0 = alle
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
    final entries = _selectedSignificance > 0
        ? _service.getEntriesBySignificance(_selectedSignificance)
        : allEntries;

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
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Titel
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Synchronizitäten',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entries.length} ${entries.length == 1 ? "Eintrag" : "Einträge"}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                // Add-Button
                IconButton(
                  onPressed: () => _showAddDialog(),
                  icon: const Icon(Icons.add_circle, color: Colors.white),
                  tooltip: 'Neue Synchronizität',
                ),
              ],
            ),
          ),

          // Filter-Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Alle', 0),
                  const SizedBox(width: 8),
                  _buildFilterChip('⭐⭐⭐⭐⭐', 5),
                  const SizedBox(width: 8),
                  _buildFilterChip('⭐⭐⭐⭐', 4),
                  const SizedBox(width: 8),
                  _buildFilterChip('⭐⭐⭐', 3),
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
                    itemBuilder: (context, index) => SynchronicityEntrySkeleton(
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

  /// Filter-Chip
  Widget _buildFilterChip(String label, int value) {
    final isSelected = _selectedSignificance == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedSignificance = selected ? value : 0);
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
  Widget _buildEntryCard(SynchronicityEntry entry) {
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
          onTap: () => _showDetailDialog(entry),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header mit Datum & Significance
                Row(
                  children: [
                    // Datum
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(entry.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const Spacer(),
                    
                    // Significance Stars
                    ...List.generate(
                      5,
                      (index) => Icon(
                        index < entry.significance ? Icons.star : Icons.star_border,
                        size: 14,
                        color: index < entry.significance
                            ? const Color(0xFFFFD700)
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Event
                Text(
                  entry.event,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Meaning
                Text(
                  entry.meaning,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                // Numbers & Tags
                if (entry.numbers.isNotEmpty || entry.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      // Numbers
                      ...entry.numbers.map((number) => _buildChip(
                        number.toString(),
                        const Color(0xFF00BCD4),
                      )),
                      
                      // Tags
                      ...entry.tags.map((tag) => _buildChip(
                        tag,
                        widget.accentColor,
                      )),
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

  /// Chip (für Numbers & Tags)
  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
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
              Icons.auto_awesome,
              size: 64,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Synchronizitäten',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Beginne, bedeutungsvolle Zufälle zu dokumentieren',
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
              label: const Text('ERSTE SYNCHRONIZITÄT'),
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
    showDialog(
      context: context,
      builder: (context) => SyncEntryDialog(
        accentColor: widget.accentColor,
        onSave: (event, meaning, tags, numbers, significance) async {
          await _service.createEntry(
            event: event,
            meaning: meaning,
            tags: tags,
            numbers: numbers,
            significance: significance,
          );
          setState(() {});
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Synchronizität gespeichert! +5 Punkte'),
                backgroundColor: widget.accentColor,
              ),
            );
          }
        },
      ),
    );
  }

  /// Detail-Dialog
  void _showDetailDialog(SynchronicityEntry entry) {
    showDialog(
      context: context,
      builder: (context) => SyncDetailDialog(
        entry: entry,
        accentColor: widget.accentColor,
        onEdit: () {
          Navigator.pop(context);
          // TODO: Edit-Dialog
        },
        onDelete: () async {
          await _service.deleteEntry(entry.id);
          setState(() {});
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Synchronizität gelöscht')),
            );
          }
        },
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

/// ============================================
/// SYNC ENTRY DIALOG (für Erstellen/Bearbeiten)
/// ============================================

class SyncEntryDialog extends StatefulWidget {
  final Color accentColor;
  final Function(String event, String meaning, List<String> tags, List<int> numbers, int significance) onSave;

  const SyncEntryDialog({
    super.key,
    required this.accentColor,
    required this.onSave,
  });

  @override
  State<SyncEntryDialog> createState() => _SyncEntryDialogState();
}

class _SyncEntryDialogState extends State<SyncEntryDialog> {
  final _eventController = TextEditingController();
  final _meaningController = TextEditingController();
  final _tagsController = TextEditingController();
  final _numbersController = TextEditingController();
  int _significance = 3;

  @override
  void dispose() {
    _eventController.dispose();
    _meaningController.dispose();
    _tagsController.dispose();
    _numbersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: widget.accentColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      title: const Text(
        'Neue Synchronizität',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event
            TextField(
              controller: _eventController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Was ist passiert?',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                hintText: 'z.B. "Ich sah 11:11 auf der Uhr"',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: widget.accentColor),
                ),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // Meaning
            TextField(
              controller: _meaningController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Was bedeutet es für dich?',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                hintText: 'z.B. "Ein Zeichen, auf dem richtigen Weg zu sein"',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: widget.accentColor),
                ),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            // Numbers
            TextField(
              controller: _numbersController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Zahlen (optional)',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                hintText: 'z.B. "11, 11"',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: widget.accentColor),
                ),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            // Tags
            TextField(
              controller: _tagsController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Tags (optional)',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                hintText: 'z.B. "11:11, Zeichen"',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: widget.accentColor),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Significance
            Text(
              'Bedeutung: $_significance/5',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            Slider(
              value: _significance.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              activeColor: widget.accentColor,
              inactiveColor: Colors.white.withValues(alpha: 0.2),
              onChanged: (value) {
                setState(() => _significance = value.toInt());
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'ABBRECHEN',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_eventController.text.isEmpty || _meaningController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bitte fülle Event und Bedeutung aus')),
              );
              return;
            }
            
            final tags = _tagsController.text
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList();
            
            final numbers = _numbersController.text
                .split(',')
                .map((n) => int.tryParse(n.trim()))
                .where((n) => n != null)
                .cast<int>()
                .toList();
            
            widget.onSave(
              _eventController.text,
              _meaningController.text,
              tags,
              numbers,
              _significance,
            );
            
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.accentColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('SPEICHERN'),
        ),
      ],
    );
  }
}

/// ============================================
/// SYNC DETAIL DIALOG
/// ============================================

class SyncDetailDialog extends StatelessWidget {
  final SynchronicityEntry entry;
  final Color accentColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SyncDetailDialog({
    super.key,
    required this.entry,
    required this.accentColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: accentColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              entry.event,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Löschen',
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Significance
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < entry.significance ? Icons.star : Icons.star_border,
                  size: 20,
                  color: index < entry.significance
                      ? const Color(0xFFFFD700)
                      : Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Meaning
            Text(
              'Bedeutung:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.6),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              entry.meaning,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),

            // Numbers
            if (entry.numbers.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Zahlen:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: entry.numbers.map((number) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BCD4).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF00BCD4).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      number.toString(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF00BCD4),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Tags
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Tags:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: entry.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 13,
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 16),

            // Timestamp
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.timestamp.day}.${entry.timestamp.month}.${entry.timestamp.year}, ${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')} Uhr',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('SCHLIEẞEN', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
