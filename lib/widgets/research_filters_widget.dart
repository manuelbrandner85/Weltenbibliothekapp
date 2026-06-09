import 'package:flutter/material.dart';

/// Research Filters Widget v7.5
///
/// Erweiterte Filter für Recherche-Ergebnisse
class ResearchFiltersWidget extends StatefulWidget {
  final Function(ResearchFilters) onFiltersChanged;
  final ResearchFilters initialFilters;

  const ResearchFiltersWidget({
    super.key,
    required this.onFiltersChanged,
    required this.initialFilters,
  });

  @override
  State<ResearchFiltersWidget> createState() => _ResearchFiltersWidgetState();
}

class _ResearchFiltersWidgetState extends State<ResearchFiltersWidget> {
  late ResearchFilters _filters;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Header mit Toggle
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.filter_list,
                      color: Colors.cyan,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Filter & Sortierung',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  _buildActiveFilterCount(),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.cyan,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Filters
          if (_isExpanded) ...[
            const Divider(color: Colors.grey, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSourceTypeFilter(),
                  const SizedBox(height: 20),
                  _buildMediaTypeFilter(),
                  const SizedBox(height: 20),
                  _buildDateRangeFilter(),
                  const SizedBox(height: 20),
                  _buildLanguageFilter(),
                  const SizedBox(height: 20),
                  _buildTrustLevelFilter(),
                  const SizedBox(height: 20),
                  _buildSortFilter(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveFilterCount() {
    final count = _filters.getActiveFilterCount();
    if (count == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.cyan,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSourceTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📰 Quellen-Typ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              label: 'Alle',
              isSelected: _filters.sourceType == SourceType.all,
              onTap: () => _updateSourceType(SourceType.all),
              color: Colors.grey,
            ),
            _buildFilterChip(
              label: 'Mainstream',
              isSelected: _filters.sourceType == SourceType.mainstream,
              onTap: () => _updateSourceType(SourceType.mainstream),
              color: Colors.blue,
            ),
            _buildFilterChip(
              label: 'Alternative',
              isSelected: _filters.sourceType == SourceType.alternative,
              onTap: () => _updateSourceType(SourceType.alternative),
              color: Colors.orange,
            ),
            _buildFilterChip(
              label: 'Leaks',
              isSelected: _filters.sourceType == SourceType.leaks,
              onTap: () => _updateSourceType(SourceType.leaks),
              color: Colors.red,
            ),
            _buildFilterChip(
              label: 'Unabhängig',
              isSelected: _filters.sourceType == SourceType.independent,
              onTap: () => _updateSourceType(SourceType.independent),
              color: Colors.green,
            ),
            _buildFilterChip(
              label: 'Wissenschaftlich',
              isSelected: _filters.sourceType == SourceType.scientific,
              onTap: () => _updateSourceType(SourceType.scientific),
              color: Colors.lightBlue,
            ),
            _buildFilterChip(
              label: 'Faktencheck',
              isSelected: _filters.sourceType == SourceType.factcheck,
              onTap: () => _updateSourceType(SourceType.factcheck),
              color: Colors.amber,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMediaTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📁 Medien-Typ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              label: 'Alle',
              isSelected: _filters.mediaType == MediaType.all,
              onTap: () => _updateMediaType(MediaType.all),
              color: Colors.grey,
            ),
            _buildFilterChip(
              label: 'PDFs',
              isSelected: _filters.mediaType == MediaType.documents,
              onTap: () => _updateMediaType(MediaType.documents),
              color: Colors.red,
            ),
            _buildFilterChip(
              label: 'Bilder',
              isSelected: _filters.mediaType == MediaType.images,
              onTap: () => _updateMediaType(MediaType.images),
              color: Colors.blue,
            ),
            _buildFilterChip(
              label: 'Videos',
              isSelected: _filters.mediaType == MediaType.videos,
              onTap: () => _updateMediaType(MediaType.videos),
              color: Colors.purple,
            ),
            _buildFilterChip(
              label: 'Telegram',
              isSelected: _filters.mediaType == MediaType.telegram,
              onTap: () => _updateMediaType(MediaType.telegram),
              color: Colors.cyan,
            ),
            _buildFilterChip(
              label: 'Audio/Podcast',
              isSelected: _filters.mediaType == MediaType.audio,
              onTap: () => _updateMediaType(MediaType.audio),
              color: Colors.deepPurple,
            ),
            _buildFilterChip(
              label: 'Datensaetze',
              isSelected: _filters.mediaType == MediaType.datasets,
              onTap: () => _updateMediaType(MediaType.datasets),
              color: Colors.teal,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📅 Zeitraum',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              label: 'Alle',
              isSelected: _filters.dateRange == DateRange.all,
              onTap: () => _updateDateRange(DateRange.all),
              color: Colors.grey,
            ),
            _buildFilterChip(
              label: 'Letzte Woche',
              isSelected: _filters.dateRange == DateRange.lastWeek,
              onTap: () => _updateDateRange(DateRange.lastWeek),
              color: Colors.green,
            ),
            _buildFilterChip(
              label: 'Letzter Monat',
              isSelected: _filters.dateRange == DateRange.lastMonth,
              onTap: () => _updateDateRange(DateRange.lastMonth),
              color: Colors.blue,
            ),
            _buildFilterChip(
              label: 'Letztes Jahr',
              isSelected: _filters.dateRange == DateRange.lastYear,
              onTap: () => _updateDateRange(DateRange.lastYear),
              color: Colors.orange,
            ),
            _buildFilterChip(
              label: 'Historisch (>5 Jahre)',
              isSelected: _filters.dateRange == DateRange.historical,
              onTap: () => _updateDateRange(DateRange.historical),
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🌍 Sprache',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              label: 'Alle',
              isSelected: _filters.language == Language.all,
              onTap: () => _updateLanguage(Language.all),
              color: Colors.grey,
            ),
            _buildFilterChip(
              label: 'Deutsch',
              isSelected: _filters.language == Language.german,
              onTap: () => _updateLanguage(Language.german),
              color: Colors.red,
            ),
            _buildFilterChip(
              label: 'Englisch',
              isSelected: _filters.language == Language.english,
              onTap: () => _updateLanguage(Language.english),
              color: Colors.blue,
            ),
            _buildFilterChip(
              label: 'Franzoesisch',
              isSelected: _filters.language == Language.french,
              onTap: () => _updateLanguage(Language.french),
              color: Colors.indigo,
            ),
            _buildFilterChip(
              label: 'Spanisch',
              isSelected: _filters.language == Language.spanish,
              onTap: () => _updateLanguage(Language.spanish),
              color: Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _resetFilters,
            icon: const Icon(Icons.clear, size: 18),
            label: const Text('Zurücksetzen'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey,
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.5)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _applyFilters,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Anwenden'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              foregroundColor: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  void _updateSourceType(SourceType type) {
    setState(() {
      _filters = _filters.copyWith(sourceType: type);
    });
  }

  void _updateMediaType(MediaType type) {
    setState(() {
      _filters = _filters.copyWith(mediaType: type);
    });
  }

  void _updateDateRange(DateRange range) {
    setState(() {
      _filters = _filters.copyWith(dateRange: range);
    });
  }

  void _updateLanguage(Language language) {
    setState(() {
      _filters = _filters.copyWith(language: language);
    });
  }

  Widget _buildTrustLevelFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vertrauensniveau',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              label: 'Alle',
              isSelected: _filters.trustLevel == TrustLevel.all,
              onTap: () => _updateTrustLevel(TrustLevel.all),
              color: Colors.grey,
            ),
            _buildFilterChip(
              label: 'Hoch',
              isSelected: _filters.trustLevel == TrustLevel.high,
              onTap: () => _updateTrustLevel(TrustLevel.high),
              color: Colors.green,
            ),
            _buildFilterChip(
              label: 'Mittel',
              isSelected: _filters.trustLevel == TrustLevel.medium,
              onTap: () => _updateTrustLevel(TrustLevel.medium),
              color: Colors.orange,
            ),
            _buildFilterChip(
              label: 'Alternativ',
              isSelected: _filters.trustLevel == TrustLevel.low,
              onTap: () => _updateTrustLevel(TrustLevel.low),
              color: Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '↕ Sortierung',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              label: 'Relevanz',
              isSelected: _filters.sortOrder == SortOrder.relevance,
              onTap: () => _updateSortOrder(SortOrder.relevance),
              color: Colors.cyan,
            ),
            _buildFilterChip(
              label: 'Datum (neu)',
              isSelected: _filters.sortOrder == SortOrder.dateDesc,
              onTap: () => _updateSortOrder(SortOrder.dateDesc),
              color: Colors.green,
            ),
            _buildFilterChip(
              label: 'Datum (alt)',
              isSelected: _filters.sortOrder == SortOrder.dateAsc,
              onTap: () => _updateSortOrder(SortOrder.dateAsc),
              color: Colors.orange,
            ),
            _buildFilterChip(
              label: 'Quelle A-Z',
              isSelected: _filters.sortOrder == SortOrder.sourceAz,
              onTap: () => _updateSortOrder(SortOrder.sourceAz),
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  void _updateSortOrder(SortOrder order) {
    setState(() {
      _filters = _filters.copyWith(sortOrder: order);
    });
  }

  void _updateTrustLevel(TrustLevel level) {
    setState(() {
      _filters = _filters.copyWith(trustLevel: level);
    });
  }

  void _resetFilters() {
    setState(() {
      _filters = ResearchFilters.defaultFilters();
    });
    widget.onFiltersChanged(_filters);
  }

  void _applyFilters() {
    widget.onFiltersChanged(_filters);
    setState(() {
      _isExpanded = false;
    });
  }
}

// Research Filters Model
class ResearchFilters {
  final SourceType sourceType;
  final MediaType mediaType;
  final DateRange dateRange;
  final Language language;
  final SortOrder sortOrder;
  final TrustLevel trustLevel;

  const ResearchFilters({
    required this.sourceType,
    required this.mediaType,
    required this.dateRange,
    required this.language,
    required this.sortOrder,
    required this.trustLevel,
  });

  factory ResearchFilters.defaultFilters() {
    return const ResearchFilters(
      sourceType: SourceType.all,
      mediaType: MediaType.all,
      dateRange: DateRange.all,
      language: Language.all,
      sortOrder: SortOrder.relevance,
      trustLevel: TrustLevel.all,
    );
  }

  ResearchFilters copyWith({
    SourceType? sourceType,
    MediaType? mediaType,
    DateRange? dateRange,
    Language? language,
    SortOrder? sortOrder,
    TrustLevel? trustLevel,
  }) {
    return ResearchFilters(
      sourceType: sourceType ?? this.sourceType,
      mediaType: mediaType ?? this.mediaType,
      dateRange: dateRange ?? this.dateRange,
      language: language ?? this.language,
      sortOrder: sortOrder ?? this.sortOrder,
      trustLevel: trustLevel ?? this.trustLevel,
    );
  }

  int getActiveFilterCount() {
    int count = 0;
    if (sourceType != SourceType.all) count++;
    if (mediaType != MediaType.all) count++;
    if (dateRange != DateRange.all) count++;
    if (language != Language.all) count++;
    if (sortOrder != SortOrder.relevance) count++;
    if (trustLevel != TrustLevel.all) count++;
    return count;
  }

  Map<String, dynamic> toJson() {
    return {
      'sourceType': sourceType.toString(),
      'mediaType': mediaType.toString(),
      'dateRange': dateRange.toString(),
      'language': language.toString(),
      'sortOrder': sortOrder.toString(),
      'trustLevel': trustLevel.toString(),
    };
  }
}

// Enums
enum SourceType {
  all,
  mainstream,
  alternative,
  leaks,
  independent,
  scientific,
  factcheck,
}

enum MediaType { all, documents, images, videos, telegram, audio, datasets }

enum DateRange { all, lastWeek, lastMonth, lastYear, historical }

enum Language { all, german, english, french, spanish }

enum SortOrder { relevance, dateDesc, dateAsc, sourceAz }

enum TrustLevel { all, high, medium, low }
