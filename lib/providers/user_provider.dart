import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';

/// ═══════════════════════════════════════════════════════════════
/// USER PROVIDER - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// State Management für User-Daten
/// Features:
/// - Aktueller User mit typsicherem Zugriff
/// - User-Cache für Performance
/// - Online-Status-Tracking mit Polling
/// - Reactive Updates für UI
/// ═══════════════════════════════════════════════════════════════

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  // ═══════════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════════

  User? _currentUser;
  List<User> _allUsers = [];
  List<User> _searchResults = [];
  Map<String, User> _userCache = {}; // Username → User
  Map<String, bool> _onlineStatusCache = {}; // Username → isOnline
  Map<String, DateTime> _onlineStatusCacheTTL = {}; // Username → Expires

  bool _isLoading = false;
  String? _error;

  Timer? _onlineStatusPollingTimer;

  // ═══════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════

  User? get currentUser => _currentUser;
  List<User> get allUsers => _allUsers;
  List<User> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Überprüft, ob aktueller User authentifiziert ist
  bool get isAuthenticated => _currentUser != null;

  /// Überprüft, ob aktueller User Admin ist
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  /// Überprüft, ob aktueller User Moderator oder höher ist
  bool get isModerator => _currentUser?.isModerator ?? false;

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════

  /// Initialisiert Provider und lädt aktuellen User
  Future<void> initialize() async {
    if (_authService.isAuthenticated) {
      await fetchCurrentUser();
      _startOnlineStatusPolling();
    }
  }

  /// Räumt Ressourcen auf (z.B. Timer)
  @override
  void dispose() {
    _onlineStatusPollingTimer?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // CURRENT USER OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Lädt aktuellen User vom Backend
  Future<void> fetchCurrentUser() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = await _userService.getCurrentUserProfile();
      _currentUser = user;

      // In Cache speichern
      _userCache[user.username] = user;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Aktualisiert Profil (Display-Name, Bio)
  Future<void> updateProfile({String? displayName, String? bio}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedUser = await _userService.updateUserProfile(
        displayName: displayName,
        bio: bio,
      );

      _currentUser = updatedUser;
      _userCache[updatedUser.username] = updatedUser;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Lädt Profilbild hoch
  Future<void> uploadAvatar(File imageFile) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final avatarUrl = await _userService.uploadProfilePicture(imageFile);

      // Aktualisiere lokalen User
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(avatarUrl: avatarUrl);
        _userCache[_currentUser!.username] = _currentUser!;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Meldet User ab (cleart State)
  void logout() {
    _currentUser = null;
    _allUsers = [];
    _searchResults = [];
    _userCache.clear();
    _onlineStatusCache.clear();
    _onlineStatusCacheTTL.clear();
    _onlineStatusPollingTimer?.cancel();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // USER DISCOVERY & SEARCH
  // ═══════════════════════════════════════════════════════════════

  /// Sucht User nach Query
  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final results = await _userService.searchUsers(query);
      _searchResults = results;

      // In Cache speichern
      for (final user in results) {
        _userCache[user.username] = user;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lädt alle User
  Future<void> fetchAllUsers({int page = 1, int limit = 50}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final users = await _userService.getAllUsers(page: page, limit: limit);
      _allUsers = users;

      // In Cache speichern
      for (final user in users) {
        _userCache[user.username] = user;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Holt User aus Cache oder lädt vom Backend
  Future<User?> getUserByUsername(String username) async {
    // Zuerst Cache prüfen
    if (_userCache.containsKey(username)) {
      return _userCache[username];
    }

    // Vom Backend laden
    try {
      final user = await _userService.getUserProfile(username);
      if (user != null) {
        _userCache[username] = user;
      }
      return user;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user $username: $e');
      }
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ONLINE STATUS TRACKING
  // ═══════════════════════════════════════════════════════════════

  /// Startet automatisches Polling für Online-Status
  void _startOnlineStatusPolling() {
    _onlineStatusPollingTimer?.cancel();
    _onlineStatusPollingTimer = Timer.periodic(const Duration(seconds: 10), (
      _,
    ) {
      _updateOnlineStatusBatch();
    });
  }

  /// Aktualisiert Online-Status für alle gecachten User (Batch)
  Future<void> _updateOnlineStatusBatch() async {
    if (_userCache.isEmpty) return;

    try {
      final usernames = _userCache.keys.toList();
      final statuses = await _userService.getBatchUserStatus(usernames);

      // Cache aktualisieren
      final now = DateTime.now();
      statuses.forEach((username, isOnline) {
        _onlineStatusCache[username] = isOnline;
        _onlineStatusCacheTTL[username] = now.add(const Duration(seconds: 15));

        // User-Objekt aktualisieren
        if (_userCache.containsKey(username)) {
          _userCache[username] = _userCache[username]!.copyWith(
            isOnline: isOnline,
            lastSeenAt: isOnline ? now : null,
          );
        }
      });

      notifyListeners();
    } catch (e) {
      // Silent fail - Polling sollte UI nicht stören
      if (kDebugMode) {
        print('Error updating online status: $e');
      }
    }
  }

  /// Holt Online-Status für einzelnen User (mit Cache)
  Future<bool> getOnlineStatus(String username) async {
    // Cache-Check mit TTL
    if (_onlineStatusCache.containsKey(username)) {
      final expiry = _onlineStatusCacheTTL[username];
      if (expiry != null && DateTime.now().isBefore(expiry)) {
        return _onlineStatusCache[username]!;
      }
    }

    // Vom Backend laden
    try {
      final status = await _userService.getUserStatus(username);
      final isOnline = status['isOnline'] as bool;

      // Cache aktualisieren
      _onlineStatusCache[username] = isOnline;
      _onlineStatusCacheTTL[username] = DateTime.now().add(
        const Duration(seconds: 15),
      );

      return isOnline;
    } catch (e) {
      return false; // Fallback: offline
    }
  }

  /// Manuell Online-Status aktualisieren (z.B. für spezifische User)
  void updateOnlineStatus(String username, bool isOnline) {
    _onlineStatusCache[username] = isOnline;
    _onlineStatusCacheTTL[username] = DateTime.now().add(
      const Duration(seconds: 15),
    );

    if (_userCache.containsKey(username)) {
      _userCache[username] = _userCache[username]!.copyWith(
        isOnline: isOnline,
        lastSeenAt: isOnline ? DateTime.now() : null,
      );
    }

    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // USER BLOCKING & REPORTING
  // ═══════════════════════════════════════════════════════════════

  /// Blockiert einen User
  Future<void> blockUser(String username) async {
    try {
      await _userService.blockUser(username);
      // Aus Cache entfernen
      _userCache.remove(username);
      _allUsers.removeWhere((u) => u.username == username);
      _searchResults.removeWhere((u) => u.username == username);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Entblockt einen User
  Future<void> unblockUser(String username) async {
    try {
      await _userService.unblockUser(username);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Meldet einen User (Report)
  Future<void> reportUser({
    required String username,
    required String reason,
    String? details,
  }) async {
    try {
      await _userService.reportUser(
        username: username,
        reason: reason,
        details: details,
      );
    } catch (e) {
      rethrow;
    }
  }
}
