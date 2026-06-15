/// RechercheResultTile -- compact grid cell for a single SearchHistoryEntry.
///
/// Counterpart to the list-oriented [RechercheCard]: the same data is rendered
/// as a square-ish tile so several results fit into a [GridView] / SliverGrid.
/// Tapping a tile opens the shared detail bottom-sheet
/// ([showRechercheDetailSheet]); the replay button re-triggers the search.
///
/// Category grouping helpers ([rechercheCategoryOf], [groupRechercheByCategory])
/// also live here so the screen can sort the results by category.
library;

import 'package:flutter/material.dart';

import '../models/search_history.dart';
import 'recherche_card.dart';

// Materie accent palette (mirrors recherche_screen.dart constants)
const _kAccent = Color(0xFF2979FF);
const _kSurface = Color(0xFF0C0C1A);

/// Fallback category label for entries without tags.
const String kRechercheUncategorized = 'Allgemein';

/// Derives a display category for [entry].
///
/// Entries carry no dedicated category column, so the first tag is used as the
/// grouping key (capitalised). Without tags the entry falls back to
/// [kRechercheUncategorized].
String rechercheCategoryOf(SearchHistoryEntry entry) {
  final tags = entry.tags;
  if (tags == null || tags.isEmpty) return kRechercheUncategorized;
  final first = tags.first.trim();
  if (first.isEmpty) return kRechercheUncategorized;
  return first[0].toUpperCase() + first.substring(1);
}

/// Plain holder for a category and its entries (no Dart 3 record -- CLAUDE.md
/// rule #8).
class RechercheCategoryGroup {
  final String category;
  final List<SearchHistoryEntry> entries;
  const RechercheCategoryGroup(this.category, this.entries);
}

/// Groups [entries] by [rechercheCategoryOf] and returns the groups sorted
/// alphabetically by category, with [kRechercheUncategorized] always last.
///
/// The order of entries inside each group is preserved (callers pass them in
/// the desired newest/oldest order).
List<RechercheCategoryGroup> groupRechercheByCategory(
  List<SearchHistoryEntry> entries,
) {
  final byCategory = <String, List<SearchHistoryEntry>>{};
  for (final entry in entries) {
    byCategory.putIfAbsent(rechercheCategoryOf(entry), () => []).add(entry);
  }

  final categories = byCategory.keys.toList()
    ..sort((a, b) {
      // Keep the fallback bucket at the bottom of the list.
      if (a == kRechercheUncategorized) return 1;
      if (b == kRechercheUncategorized) return -1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });

  return categories
      .map((c) => RechercheCategoryGroup(c, byCategory[c]!))
      .toList();
}

/// A compact grid tile representing a [SearchHistoryEntry].
class RechercheResultTile extends StatelessWidget {
  final SearchHistoryEntry entry;
  final VoidCallback onReplay;
  final VoidCallback onDelete;

  const RechercheResultTile({
    super.key,
    required this.entry,
    required this.onReplay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasSummary =
        entry.summary != null && entry.summary!.trim().isNotEmpty;

    return GestureDetector(
      onTap: () => showRechercheDetailSheet(
        context,
        entry: entry,
        onReplay: onReplay,
        onDelete: onDelete,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: icon + replay button
            Row(
              children: [
                Icon(
                  Icons.manage_search_rounded,
                  color: _kAccent.withValues(alpha: 0.75),
                  size: 20,
                ),
                const Spacer(),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    icon: const Icon(
                      Icons.replay_rounded,
                      size: 16,
                      color: _kAccent,
                    ),
                    tooltip: 'Suche wiederholen',
                    padding: EdgeInsets.zero,
                    onPressed: onReplay,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Title = query
            Text(
              entry.query,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Description = summary or result count
            Expanded(
              child: Text(
                hasSummary
                    ? entry.summary!
                    : (entry.resultCount > 0
                          ? '${entry.resultCount} Treffer gefunden'
                          : 'Keine Treffer gespeichert'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),

            // Footer: date + result badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.formattedDate,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (entry.resultCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _kAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${entry.resultCount}',
                      style: TextStyle(
                        color: _kAccent.withValues(alpha: 0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
