/// RechercheCard -- reusable card for a single SearchHistoryEntry.
///
/// Displays query (title), summary / result count (description), tags, and
/// date.  Tap opens a detail bottom-sheet; the replay button re-triggers the
/// search; swipe-left dismisses (delete).
library;

import 'package:flutter/material.dart';

import '../models/search_history.dart';

// Materie accent palette (mirrors recherche_screen.dart constants)
const _kAccent = Color(0xFF2979FF);
const _kBg = Color(0xFF04080F);
const _kSurface = Color(0xFF0C0C1A);

/// Opens the shared detail bottom-sheet for [entry].
///
/// Exposed so both the list [RechercheCard] and the grid
/// `RechercheResultTile` reuse the exact same detail UI.
void showRechercheDetailSheet(
  BuildContext context, {
  required SearchHistoryEntry entry,
  required VoidCallback onReplay,
  required VoidCallback onDelete,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: _kSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (_) => _DetailSheet(
      entry: entry,
      onReplay: () {
        Navigator.of(context).pop();
        onReplay();
      },
      onDelete: () {
        Navigator.of(context).pop();
        onDelete();
      },
    ),
  );
}

/// A card that represents a [SearchHistoryEntry].
///
/// [onReplay]  is called when the replay button is tapped.
/// [onDelete]  is called after the card is dismissed (swipe) or the remove
///             button in the detail-sheet is tapped.
class RechercheCard extends StatelessWidget {
  final SearchHistoryEntry entry;
  final VoidCallback onReplay;
  final VoidCallback onDelete;

  const RechercheCard({
    super.key,
    required this.entry,
    required this.onReplay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('rc_dismiss_${entry.id}'),
      direction: DismissDirection.endToStart,
      background: _SwipeDeleteBg(),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: () => _showDetailSheet(context),
        child: Card(
          color: _kSurface,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leading icon
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 12),
                  child: Icon(
                    Icons.manage_search_rounded,
                    color: _kAccent.withValues(alpha: 0.75),
                    size: 22,
                  ),
                ),

                // Content
                Expanded(child: _CardBody(entry: entry)),

                // Replay button
                IconButton(
                  icon: const Icon(
                    Icons.replay_rounded,
                    size: 18,
                    color: _kAccent,
                  ),
                  tooltip: 'Suche wiederholen',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: onReplay,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Opens a bottom-sheet with the full entry details.
  void _showDetailSheet(BuildContext context) {
    showRechercheDetailSheet(
      context,
      entry: entry,
      onReplay: onReplay,
      onDelete: onDelete,
    );
  }
}

// ---------------------------------------------------------------------------
// Card body (title, description, tags, date)
// ---------------------------------------------------------------------------

class _CardBody extends StatelessWidget {
  final SearchHistoryEntry entry;
  const _CardBody({required this.entry});

  @override
  Widget build(BuildContext context) {
    final tags = entry.tags ?? [];
    final hasSummary =
        entry.summary != null && entry.summary!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title = query
        Text(
          entry.query,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),

        // Description = summary or result count
        if (hasSummary)
          Text(
            entry.summary!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          )
        else if (entry.resultCount > 0)
          Text(
            '${entry.resultCount} Treffer gefunden',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),

        const SizedBox(height: 6),

        // Footer row: date + result badge
        Row(
          children: [
            Text(
              entry.formattedDate,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
              ),
            ),
            if (entry.resultCount > 0) ...[
              const SizedBox(width: 8),
              _Badge(label: '${entry.resultCount} Treffer', color: _kAccent),
            ],
          ],
        ),

        // Tags
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: tags.take(4).map((t) => _TagChip(label: t)).toList(),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Detail bottom-sheet
// ---------------------------------------------------------------------------

class _DetailSheet extends StatelessWidget {
  final SearchHistoryEntry entry;
  final VoidCallback onReplay;
  final VoidCallback onDelete;

  const _DetailSheet({
    required this.entry,
    required this.onReplay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tags = entry.tags ?? [];
    final hasSummary =
        entry.summary != null && entry.summary!.trim().isNotEmpty;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => ColoredBox(
        color: _kSurface,
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: icon + title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.manage_search_rounded,
                          color: _kAccent,
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.query,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Meta row
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          entry.formattedDate,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                        if (entry.resultCount > 0) ...[
                          const SizedBox(width: 12),
                          _Badge(
                            label: '${entry.resultCount} Treffer',
                            color: _kAccent,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Summary
                    if (hasSummary) ...[
                      const Text(
                        'Zusammenfassung',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _kBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Text(
                          entry.summary!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Tags
                    if (tags.isNotEmpty) ...[
                      const Text(
                        'Themen',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: tags.map((t) => _TagChip(label: t)).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onReplay,
                            style: FilledButton.styleFrom(
                              backgroundColor: _kAccent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.replay_rounded, size: 18),
                            label: const Text('Recherche wiederholen'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: onDelete,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                          child: const Icon(Icons.delete_outline, size: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small reusable widgets
// ---------------------------------------------------------------------------

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withValues(alpha: 0.9),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white60, fontSize: 10),
      ),
    );
  }
}

class _SwipeDeleteBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(
        Icons.delete_outline,
        color: Colors.redAccent,
        size: 22,
      ),
    );
  }
}
