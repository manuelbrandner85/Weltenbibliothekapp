import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/live_feed_entry.dart';

/// Service für erweiterte Feed-Filterung
/// 
/// Unterstützt:
/// - Filter nach Thema (Geopolitik, Spiritualität, etc.)
/// - Filter nach Quelle (Amerika21, Yoga Vidya, etc.)
/// - Filter nach Quellentyp (Analyse, Fachtext, etc.)
/// - Filter nach Datum (heute, diese Woche, letzter Monat)
/// - Filter nach Tiefe-Level (1-5 Sterne)
/// - Sortierung (neueste, älteste, höchste Tiefe)
class FeedFilterService {
  static const String _keySelectedThemes = 'filter_themes';
  static const String _keySelectedSources = 'filter_sources';
  static const String _keySelectedTypes = 'filter_types';
  static const String _keyDateRange = 'filter_date_range';
  static const String _keyMinTiefe = 'filter_min_tiefe';
  static const String _keySortBy = 'filter_sort_by';

  // Aktuelle Filter-Einstellungen
  Set<String> _selectedThemes = {};
  Set<String> _selectedSources = {};
  Set<QuellenTyp> _selectedTypes = {};
  DateFilterRange _dateRange = DateFilterRange.all;
  int _minTiefe = 0;
  FeedSortBy _sortBy = FeedSortBy.newest;

  // Stream für Filter-Updates
  final StreamController<FeedFilterState> _filterController =
      StreamController<FeedFilterState>.broadcast();

  Stream<FeedFilterState> get filterStream => _filterController.stream;

  FeedFilterState get currentState => FeedFilterState(
        selectedThemes: _selectedThemes,
        selectedSources: _selectedSources,
        selectedTypes: _selectedTypes,
        dateRange: _dateRange,
        minTiefe: _minTiefe,
        sortBy: _sortBy,
      );

  bool get hasActiveFilters =>
      _selectedThemes.isNotEmpty ||
      _selectedSources.isNotEmpty ||
      _selectedTypes.isNotEmpty ||
      _dateRange != DateFilterRange.all ||
      _minTiefe > 0;

  int get activeFilterCount {
    int count = 0;
    if (_selectedThemes.isNotEmpty) count++;
    if (_selectedSources.isNotEmpty) count++;
    if (_selectedTypes.isNotEmpty) count++;
    if (_dateRange != DateFilterRange.all) count++;
    if (_minTiefe > 0) count++;
    return count;
  }

  /// Initialisiere Service und lade gespeicherte Filter
  Future<void> init() async {
    await _loadFilters();
  }

  Future<void> _loadFilters() async {
    final prefs = await SharedPreferences.getInstance();

    // Lade Themen
    final themes = prefs.getStringList(_keySelectedThemes) ?? [];
    _selectedThemes = themes.toSet();

    // Lade Quellen
    final sources = prefs.getStringList(_keySelectedSources) ?? [];
    _selectedSources = sources.toSet();

    // Lade Quellentypen
    final types = prefs.getStringList(_keySelectedTypes) ?? [];
    _selectedTypes = types
        .map((t) => QuellenTyp.values.firstWhere(
              (qt) => qt.toString() == t,
              orElse: () => QuellenTyp.analyse,
            ))
        .toSet();

    // Lade Datumsbereich
    final dateRangeStr = prefs.getString(_keyDateRange) ?? 'all';
    _dateRange = DateFilterRange.values.firstWhere(
      (d) => d.toString().split('.').last == dateRangeStr,
      orElse: () => DateFilterRange.all,
    );

    // Lade minimale Tiefe
    _minTiefe = prefs.getInt(_keyMinTiefe) ?? 0;

    // Lade Sortierung
    final sortByStr = prefs.getString(_keySortBy) ?? 'newest';
    _sortBy = FeedSortBy.values.firstWhere(
      (s) => s.toString().split('.').last == sortByStr,
      orElse: () => FeedSortBy.newest,
    );

    _notifyListeners();
  }

  /// Speichere Filter-Einstellungen
  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(_keySelectedThemes, _selectedThemes.toList());
    await prefs.setStringList(_keySelectedSources, _selectedSources.toList());
    await prefs.setStringList(
      _keySelectedTypes,
      _selectedTypes.map((t) => t.toString()).toList(),
    );
    await prefs.setString(
      _keyDateRange,
      _dateRange.toString().split('.').last,
    );
    await prefs.setInt(_keyMinTiefe, _minTiefe);
    await prefs.setString(_keySortBy, _sortBy.toString().split('.').last);
  }

  /// Thema hinzufügen/entfernen
  Future<void> toggleTheme(String theme) async {
    if (_selectedThemes.contains(theme)) {
      _selectedThemes.remove(theme);
    } else {
      _selectedThemes.add(theme);
    }
    await _saveFilters();
    _notifyListeners();
  }

  /// Quelle hinzufügen/entfernen
  Future<void> toggleSource(String source) async {
    if (_selectedSources.contains(source)) {
      _selectedSources.remove(source);
    } else {
      _selectedSources.add(source);
    }
    await _saveFilters();
    _notifyListeners();
  }

  /// Quellentyp hinzufügen/entfernen
  Future<void> toggleType(QuellenTyp type) async {
    if (_selectedTypes.contains(type)) {
      _selectedTypes.remove(type);
    } else {
      _selectedTypes.add(type);
    }
    await _saveFilters();
    _notifyListeners();
  }

  /// Datumsbereich setzen
  Future<void> setDateRange(DateFilterRange range) async {
    _dateRange = range;
    await _saveFilters();
    _notifyListeners();
  }

  /// Minimale Tiefe setzen
  Future<void> setMinTiefe(int level) async {
    _minTiefe = level.clamp(0, 5);
    await _saveFilters();
    _notifyListeners();
  }

  /// Sortierung setzen
  Future<void> setSortBy(FeedSortBy sortBy) async {
    _sortBy = sortBy;
    await _saveFilters();
    _notifyListeners();
  }

  /// Alle Filter zurücksetzen
  Future<void> clearAllFilters() async {
    _selectedThemes.clear();
    _selectedSources.clear();
    _selectedTypes.clear();
    _dateRange = DateFilterRange.all;
    _minTiefe = 0;
    _sortBy = FeedSortBy.newest;
    await _saveFilters();
    _notifyListeners();
  }

  /// Wende Filter auf Feed-Liste an
  List<T> applyFilters<T extends LiveFeedEntry>(List<T> feeds) {
    var filtered = feeds.where((feed) {
      // Filter nach Thema (MaterieFeedEntry hat `thema`, EnergieFeedEntry hat `spiritThema`)
      if (_selectedThemes.isNotEmpty) {
        final feedThema = (feed is MaterieFeedEntry) 
            ? feed.thema 
            : (feed is EnergieFeedEntry) 
                ? feed.spiritThema 
                : '';
        if (!_selectedThemes.contains(feedThema)) {
          return false;
        }
      }

      // Filter nach Quelle
      if (_selectedSources.isNotEmpty) {
        if (!_selectedSources.contains(feed.quelle)) {
          return false;
        }
      }

      // Filter nach Quellentyp
      if (_selectedTypes.isNotEmpty) {
        if (!_selectedTypes.contains(feed.quellentyp)) {
          return false;
        }
      }

      // Filter nach Datum
      if (_dateRange != DateFilterRange.all) {
        final now = DateTime.now();
        final feedDate = feed.fetchTimestamp;

        switch (_dateRange) {
          case DateFilterRange.today:
            if (!_isSameDay(feedDate, now)) return false;
            break;
          case DateFilterRange.thisWeek:
            final weekAgo = now.subtract(const Duration(days: 7));
            if (feedDate.isBefore(weekAgo)) return false;
            break;
          case DateFilterRange.thisMonth:
            final monthAgo = now.subtract(const Duration(days: 30));
            if (feedDate.isBefore(monthAgo)) return false;
            break;
          case DateFilterRange.all:
            break;
        }
      }

      // Filter nach minimaler Tiefe (nur für MaterieFeedEntry)
      if (_minTiefe > 0) {
        if (feed is MaterieFeedEntry) {
          if (feed.tiefeLevel < _minTiefe) {
            return false;
          }
        }
        // EnergieFeedEntry hat kein tiefeLevel, also bei ENERGIE-Feeds wird dieser Filter ignoriert
      }

      return true;
    }).toList();

    // Sortiere gefilterte Feeds
    filtered.sort((a, b) {
      switch (_sortBy) {
        case FeedSortBy.newest:
          return b.fetchTimestamp.compareTo(a.fetchTimestamp);
        case FeedSortBy.oldest:
          return a.fetchTimestamp.compareTo(b.fetchTimestamp);
        case FeedSortBy.highestTiefe:
          // Nur für MaterieFeedEntry sinnvoll (EnergieFeedEntry hat kein tiefeLevel)
          final aTiefe = (a is MaterieFeedEntry) ? a.tiefeLevel : 0;
          final bTiefe = (b is MaterieFeedEntry) ? b.tiefeLevel : 0;
          final tiefeDiff = bTiefe.compareTo(aTiefe);
          if (tiefeDiff != 0) return tiefeDiff;
          return b.fetchTimestamp.compareTo(a.fetchTimestamp); // Bei gleicher Tiefe: neueste zuerst
      }
    });

    return filtered;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _notifyListeners() {
    _filterController.add(currentState);
  }

  void dispose() {
    _filterController.close();
  }
}

/// Datumsfilter-Bereiche
enum DateFilterRange {
  all,
  today,
  thisWeek,
  thisMonth,
}

/// Sortier-Optionen
enum FeedSortBy {
  newest,
  oldest,
  highestTiefe,
}

/// Filter-Status für UI-Updates
class FeedFilterState {
  final Set<String> selectedThemes;
  final Set<String> selectedSources;
  final Set<QuellenTyp> selectedTypes;
  final DateFilterRange dateRange;
  final int minTiefe;
  final FeedSortBy sortBy;

  FeedFilterState({
    required this.selectedThemes,
    required this.selectedSources,
    required this.selectedTypes,
    required this.dateRange,
    required this.minTiefe,
    required this.sortBy,
  });
}

/// Extensions für bessere Lesbarkeit
extension DateFilterRangeExtension on DateFilterRange {
  String get label {
    switch (this) {
      case DateFilterRange.all:
        return 'Alle';
      case DateFilterRange.today:
        return 'Heute';
      case DateFilterRange.thisWeek:
        return 'Diese Woche';
      case DateFilterRange.thisMonth:
        return 'Dieser Monat';
    }
  }

  String get icon {
    switch (this) {
      case DateFilterRange.all:
        return '🌍';
      case DateFilterRange.today:
        return '📅';
      case DateFilterRange.thisWeek:
        return '📆';
      case DateFilterRange.thisMonth:
        return '📋';
    }
  }
}

extension FeedSortByExtension on FeedSortBy {
  String get label {
    switch (this) {
      case FeedSortBy.newest:
        return 'Neueste zuerst';
      case FeedSortBy.oldest:
        return 'Älteste zuerst';
      case FeedSortBy.highestTiefe:
        return 'Höchste Tiefe';
    }
  }

  String get icon {
    switch (this) {
      case FeedSortBy.newest:
        return '⬇️';
      case FeedSortBy.oldest:
        return '⬆️';
      case FeedSortBy.highestTiefe:
        return '⭐';
    }
  }
}
