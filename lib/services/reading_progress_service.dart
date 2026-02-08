import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/feed_features.dart';

/// Service für Lesezeit-Tracking und Lesefortschritt
/// 
/// Funktionen:
/// - Wort-Zählung aus Feed-Inhalten
/// - Geschätzte Lesezeit-Berechnung (200 Wörter/Minute)
/// - Tracking des Lesefortschritts (% gelesen)
/// - Persistente Speicherung des Fortschritts
/// - Lesehistorie und Statistiken
class ReadingProgressService {
  static const String _keyReadingProgress = 'reading_progress';
  static const String _keyReadingHistory = 'reading_history';
  static const int _wordsPerMinute = 200; // Durchschnittliche Lesegeschwindigkeit

  // Lesefortschritt pro Feed-ID
  final Map<String, ReadingProgress> _progressMap = {};

  // Lesehistorie (Feed-IDs von gelesenen Artikeln)
  final List<String> _readHistory = [];

  // Stream für Progress-Updates
  final StreamController<Map<String, ReadingProgress>> _progressController =
      StreamController<Map<String, ReadingProgress>>.broadcast();

  Stream<Map<String, ReadingProgress>> get progressStream =>
      _progressController.stream;

  /// Initialisiere Service und lade gespeicherten Fortschritt
  Future<void> init() async {
    await _loadProgress();
    await _loadHistory();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getStringList(_keyReadingProgress) ?? [];

    for (final entry in progressJson) {
      try {
        final parts = entry.split('|');
        if (parts.length == 3) {
          final feedId = parts[0];
          final progressPercent = double.parse(parts[1]);
          final timestamp = DateTime.parse(parts[2]);

          _progressMap[feedId] = ReadingProgress(
            feedId: feedId,
            progressPercent: progressPercent,
            lastReadAt: timestamp,
            totalWords: 0, // Wird beim Zugriff neu berechnet
            estimatedMinutes: 0, // Wird beim Zugriff neu berechnet
          );
        }
      } catch (e) {
        // Fehlerhafte Einträge ignorieren
      }
    }
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_keyReadingHistory) ?? [];
    _readHistory.clear();
    _readHistory.addAll(history);
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = _progressMap.entries.map((e) {
      final lastRead = e.value.lastReadAt ?? DateTime.now();
      return '${e.key}|${e.value.progressPercent}|${lastRead.toIso8601String()}';
    }).toList();
    await prefs.setStringList(_keyReadingProgress, progressJson);
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyReadingHistory, _readHistory);
  }

  /// Berechne Lesezeit-Informationen aus Text
  ReadingProgress calculateReadingInfo(String feedId, String text) {
    final words = _countWords(text);
    final minutes = (words / _wordsPerMinute).ceil();

    // Prüfe ob bereits Fortschritt gespeichert
    final existingProgress = _progressMap[feedId];

    return ReadingProgress(
      feedId: feedId,
      totalWords: words,
      estimatedMinutes: minutes,
      progressPercent: existingProgress?.progressPercent ?? 0.0,
      lastReadAt: existingProgress?.lastReadAt,
    );
  }

  int _countWords(String text) {
    if (text.isEmpty) return 0;

    // Entferne HTML-Tags und extra Whitespace
    final cleanedText = text
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Zähle Wörter
    return cleanedText.split(RegExp(r'\s+')).length;
  }

  /// Aktualisiere Lesefortschritt für einen Feed
  Future<void> updateProgress(
    String feedId,
    double progressPercent, {
    int? totalWords,
    int? estimatedMinutes,
  }) async {
    final progress = ReadingProgress(
      feedId: feedId,
      totalWords: totalWords ?? _progressMap[feedId]?.totalWords ?? 0,
      estimatedMinutes:
          estimatedMinutes ?? _progressMap[feedId]?.estimatedMinutes ?? 0,
      progressPercent: progressPercent.clamp(0.0, 100.0),
      lastReadAt: DateTime.now(),
    );

    _progressMap[feedId] = progress;

    // Wenn zu 100% gelesen, zur Historie hinzufügen
    if (progressPercent >= 100.0 && !_readHistory.contains(feedId)) {
      _readHistory.insert(0, feedId); // Neueste zuerst
      if (_readHistory.length > 100) {
        _readHistory.removeLast(); // Maximal 100 Historie-Einträge
      }
      await _saveHistory();
    }

    await _saveProgress();
    _notifyListeners();
  }

  /// Markiere Feed als gelesen (100%)
  Future<void> markAsRead(String feedId, String text) async {
    final info = calculateReadingInfo(feedId, text);
    await updateProgress(
      feedId,
      100.0,
      totalWords: info.totalWords,
      estimatedMinutes: info.estimatedMinutes,
    );
  }

  /// Hole Lesefortschritt für einen Feed
  ReadingProgress? getProgress(String feedId) {
    return _progressMap[feedId];
  }

  /// Prüfe ob Feed gelesen wurde
  bool isRead(String feedId) {
    final progress = _progressMap[feedId];
    return progress != null && progress.progressPercent >= 100.0;
  }

  /// Prüfe ob Feed teilweise gelesen wurde
  bool isPartiallyRead(String feedId) {
    final progress = _progressMap[feedId];
    return progress != null && progress.progressPercent > 0.0 && progress.progressPercent < 100.0;
  }

  /// Hole Lesehistorie
  List<String> getReadHistory() {
    return List.unmodifiable(_readHistory);
  }

  /// Statistiken: Anzahl gelesener Artikel
  int get totalReadCount => _readHistory.length;

  /// Statistiken: Anzahl teilweise gelesener Artikel
  int get partiallyReadCount =>
      _progressMap.values.where((p) => p.progressPercent > 0 && p.progressPercent < 100).length;

  /// Statistiken: Gesamte geschätzte Lesezeit aller gelesenen Artikel (in Minuten)
  int get totalReadingTimeMinutes {
    int total = 0;
    for (final feedId in _readHistory) {
      final progress = _progressMap[feedId];
      if (progress != null) {
        total += progress.estimatedMinutes;
      }
    }
    return total;
  }

  /// Lösche Fortschritt für einen Feed
  Future<void> clearProgress(String feedId) async {
    _progressMap.remove(feedId);
    await _saveProgress();
    _notifyListeners();
  }

  /// Lösche gesamte Lesehistorie
  Future<void> clearHistory() async {
    _readHistory.clear();
    _progressMap.clear();
    await _saveHistory();
    await _saveProgress();
    _notifyListeners();
  }

  void _notifyListeners() {
    _progressController.add(Map.from(_progressMap));
  }

  void dispose() {
    _progressController.close();
  }
}
