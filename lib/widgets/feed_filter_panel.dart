import 'package:flutter/material.dart';
import '../models/live_feed_entry.dart';
import '../services/feed_filter_service.dart';

/// Filter-Panel für erweiterte Feed-Filterung
/// 
/// Zeigt interaktive Filter-Optionen:
/// - Themen-Chips (klickbar)
/// - Quellen-Chips (klickbar)
/// - Quellentyp-Segmente
/// - Datums-Dropdown
/// - Tiefe-Slider
/// - Sortier-Dropdown
class FeedFilterPanel extends StatefulWidget {
  final FeedFilterService filterService;
  final List<String> availableThemes;
  final List<String> availableSources;
  final Color accentColor;

  const FeedFilterPanel({
    super.key,
    required this.filterService,
    required this.availableThemes,
    required this.availableSources,
    this.accentColor = const Color(0xFF2196F3),
  });

  @override
  State<FeedFilterPanel> createState() => _FeedFilterPanelState();
}

class _FeedFilterPanelState extends State<FeedFilterPanel> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FeedFilterState>(
      stream: widget.filterService.filterStream,
      initialData: widget.filterService.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? widget.filterService.currentState;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(state),
              const SizedBox(height: 16),
              _buildThemeFilter(state),
              const SizedBox(height: 16),
              _buildSourceFilter(state),
              const SizedBox(height: 16),
              _buildTypeFilter(state),
              const SizedBox(height: 16),
              _buildDateAndTiefeFilters(state),
              const SizedBox(height: 16),
              _buildSortByDropdown(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(FeedFilterState state) {
    final hasFilters = widget.filterService.hasActiveFilters;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.filter_list,
              color: widget.accentColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Filter & Sortierung',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.accentColor,
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.filterService.activeFilterCount} aktiv',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.accentColor,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (hasFilters)
          TextButton.icon(
            onPressed: () async {
              await widget.filterService.clearAllFilters();
            },
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text('Zurücksetzen'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
          ),
      ],
    );
  }

  Widget _buildThemeFilter(FeedFilterState state) {
    if (widget.availableThemes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🏷️ Themen',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.availableThemes.map((theme) {
            final isSelected = state.selectedThemes.contains(theme);
            return FilterChip(
              label: Text(theme),
              selected: isSelected,
              onSelected: (selected) async {
                await widget.filterService.toggleTheme(theme);
              },
              selectedColor: widget.accentColor.withValues(alpha: 0.2),
              checkmarkColor: widget.accentColor,
              side: BorderSide(
                color: isSelected
                    ? widget.accentColor
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSourceFilter(FeedFilterState state) {
    if (widget.availableSources.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📰 Quellen',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.availableSources.map((source) {
            final isSelected = state.selectedSources.contains(source);
            return FilterChip(
              label: Text(source),
              selected: isSelected,
              onSelected: (selected) async {
                await widget.filterService.toggleSource(source);
              },
              selectedColor: widget.accentColor.withValues(alpha: 0.2),
              checkmarkColor: widget.accentColor,
              side: BorderSide(
                color: isSelected
                    ? widget.accentColor
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTypeFilter(FeedFilterState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📚 Quellentyp',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: QuellenTyp.values.map((type) {
            final isSelected = state.selectedTypes.contains(type);
            return FilterChip(
              label: Text(_getQuellenTypLabel(type)),
              selected: isSelected,
              onSelected: (selected) async {
                await widget.filterService.toggleType(type);
              },
              selectedColor: widget.accentColor.withValues(alpha: 0.2),
              checkmarkColor: widget.accentColor,
              side: BorderSide(
                color: isSelected
                    ? widget.accentColor
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateAndTiefeFilters(FeedFilterState state) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📅 Zeitraum',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<DateFilterRange>(
                initialValue: state.dateRange,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
                items: DateFilterRange.values.map((range) {
                  return DropdownMenuItem(
                    value: range,
                    child: Text('${range.icon} ${range.label}'),
                  );
                }).toList(),
                onChanged: (value) async {
                  if (value != null) {
                    await widget.filterService.setDateRange(value);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⭐ Min. Tiefe: ${state.minTiefe > 0 ? state.minTiefe : 'Alle'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Slider(
                value: state.minTiefe.toDouble(),
                min: 0,
                max: 5,
                divisions: 5,
                label: state.minTiefe > 0
                    ? '${'⭐' * state.minTiefe}+'
                    : 'Alle',
                activeColor: widget.accentColor,
                onChanged: (value) async {
                  await widget.filterService.setMinTiefe(value.toInt());
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSortByDropdown(FeedFilterState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🔄 Sortierung',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<FeedSortBy>(
          initialValue: state.sortBy,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            isDense: true,
          ),
          items: FeedSortBy.values.map((sortBy) {
            return DropdownMenuItem(
              value: sortBy,
              child: Text('${sortBy.icon} ${sortBy.label}'),
            );
          }).toList(),
          onChanged: (value) async {
            if (value != null) {
              await widget.filterService.setSortBy(value);
            }
          },
        ),
      ],
    );
  }

  /// Helper-Methode für QuellenTyp Labels
  String _getQuellenTypLabel(QuellenTyp type) {
    switch (type) {
      case QuellenTyp.essay:
        return 'ESSAY';
      case QuellenTyp.archiv:
        return 'ARCHIV';
      case QuellenTyp.pdf:
        return 'PDF';
      case QuellenTyp.analyse:
        return 'ANALYSE';
      case QuellenTyp.fachtext:
        return 'FACHTEXT';
      case QuellenTyp.symbollexikon:
        return 'SYMBOLLEXIKON';
      case QuellenTyp.uebersetzung:
        return 'ÜBERSETZUNG';
      case QuellenTyp.tiefenpsychologie:
        return 'TIEFENPSYCHOLOGIE';
    }
  }
}
