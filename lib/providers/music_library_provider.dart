import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/audio_content.dart';
import '../models/music_category.dart';
import '../services/ytdlp_api_service.dart';

/// 📚 Music Library Provider - Verwaltet Musik-Content-Bibliothek
class MusicLibraryProvider with ChangeNotifier {
  final YtdlpApiService _ytdlpService = YtdlpApiService();

  List<AudioContent> _library = [];
  List<AudioContent> _favorites = [];
  List<AudioContent> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  // Getter
  List<AudioContent> get library => _library;
  List<AudioContent> get favorites => _favorites;
  List<AudioContent> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialisiere Hive & lade gespeicherte Bibliothek
  Future<void> initialize() async {
    try {
      await Hive.initFlutter();

      // Öffne Boxen für Library und Favorites
      if (!Hive.isBoxOpen('library')) {
        await Hive.openBox('library');
      }
      if (!Hive.isBoxOpen('favorites')) {
        await Hive.openBox('favorites');
      }

      await _loadFromStorage();

      if (kDebugMode) {
        debugPrint('📚 Bibliothek geladen: ${_library.length} Inhalte');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler bei Initialisierung: $e');
      }
      _error = 'Initialisierungsfehler: $e';
    }
  }

  /// Lade Library aus lokalem Storage
  Future<void> _loadFromStorage() async {
    try {
      final libraryBox = Hive.box('library');
      final favoritesBox = Hive.box('favorites');

      // Lade Library
      final libraryData = libraryBox.get('contents', defaultValue: []);
      if (libraryData is List) {
        _library = libraryData
            .map(
              (item) => AudioContent.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }

      // Lade Favorites
      final favoritesData = favoritesBox.get('contents', defaultValue: []);
      if (favoritesData is List) {
        _favorites = favoritesData
            .map(
              (item) => AudioContent.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Fehler beim Laden aus Storage: $e');
      }
    }
  }

  /// Speichere Library in lokalem Storage
  Future<void> _saveToStorage() async {
    try {
      final libraryBox = Hive.box('library');
      final favoritesBox = Hive.box('favorites');

      await libraryBox.put(
        'contents',
        _library.map((c) => c.toJson()).toList(),
      );
      await favoritesBox.put(
        'contents',
        _favorites.map((c) => c.toJson()).toList(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Fehler beim Speichern: $e');
      }
    }
  }

  /// Suche Content nach Kategorie-Keywords
  Future<void> searchByCategory(ContentCategory category) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Kombiniere Keywords für bessere Suche
      final searchQuery = category.keywords.take(3).join(' OR ');

      if (kDebugMode) {
        debugPrint('🔍 Suche in Kategorie: ${category.name}');
      }

      final videoIds = await _ytdlpService.searchVideos(
        searchQuery,
        maxResults: 15,
      );

      if (videoIds.isEmpty) {
        _error = 'Keine Videos gefunden';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final contents = await _ytdlpService.loadAudioContents(
        videoIds,
        category: category.name,
      );

      _searchResults = contents;

      if (kDebugMode) {
        debugPrint('✅ ${contents.length} Videos geladen');
      }
    } catch (e) {
      _error = 'Suchfehler: $e';
      if (kDebugMode) {
        debugPrint('❌ Suchfehler: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Freie Textsuche
  Future<void> searchByText(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final videoIds = await _ytdlpService.searchVideos(query, maxResults: 20);
      final contents = await _ytdlpService.loadAudioContents(videoIds);

      _searchResults = contents;
    } catch (e) {
      _error = 'Suchfehler: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Füge Content zur Bibliothek hinzu
  Future<void> addToLibrary(AudioContent content) async {
    if (!_library.any((c) => c.id == content.id)) {
      _library.insert(0, content);
      await _saveToStorage();
      notifyListeners();

      if (kDebugMode) {
        debugPrint('➕ Zur Bibliothek hinzugefügt: ${content.title}');
      }
    }
  }

  /// Entferne aus Bibliothek
  Future<void> removeFromLibrary(String contentId) async {
    _library.removeWhere((c) => c.id == contentId);
    await _saveToStorage();
    notifyListeners();
  }

  /// Toggle Favorite
  Future<void> toggleFavorite(AudioContent content) async {
    final isFavorite = _favorites.any((c) => c.id == content.id);

    if (isFavorite) {
      _favorites.removeWhere((c) => c.id == content.id);
    } else {
      _favorites.insert(0, content);
    }

    await _saveToStorage();
    notifyListeners();
  }

  /// Prüfe ob Content Favorit ist
  bool isFavorite(String contentId) {
    return _favorites.any((c) => c.id == contentId);
  }

  /// Hole Contents nach Kategorie
  List<AudioContent> getContentsByCategory(String category) {
    return _library.where((c) => c.category == category).toList();
  }

  /// Lösche alle Suchergebnisse
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }
}
