import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../widgets/user_list_tile.dart';
import 'user_profile_screen.dart';
import 'dm_conversation_screen.dart';

/// ═══════════════════════════════════════════════════════════════
/// USER SEARCH SCREEN - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// Live-Suche nach Benutzern
/// Features:
/// - Suchleiste mit Debouncing (300ms)
/// - Live-Suche während Eingabe
/// - Filter: Online/Offline, Rolle (Admin/Moderator/User)
/// - Ergebnisliste mit Avatar + Online-Status
/// - Empty State: "Keine Benutzer gefunden"
/// - Tap → User-Profil öffnen
/// ═══════════════════════════════════════════════════════════════

enum RoleFilter { all, admin, moderator, user }

enum OnlineFilter { all, online, offline }

class UserSearchScreen extends StatefulWidget {
  /// ✅ NEW: Optional parameter to enable DM mode
  final bool forDirectMessage;

  const UserSearchScreen({super.key, this.forDirectMessage = false});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  RoleFilter _roleFilter = RoleFilter.all;
  OnlineFilter _onlineFilter = OnlineFilter.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    // Debouncing: Warte 300ms nach letzter Eingabe
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return;
    }

    final userProvider = context.read<UserProvider>();
    await userProvider.searchUsers(query);
  }

  List<User> _getFilteredResults(List<User> results) {
    return results.where((user) {
      // Rolle-Filter
      final roleMatch = switch (_roleFilter) {
        RoleFilter.all => true,
        RoleFilter.admin => user.isAdmin,
        RoleFilter.moderator => user.role == 'moderator',
        RoleFilter.user => user.role == 'user',
      };

      // Online-Filter
      final onlineMatch = switch (_onlineFilter) {
        OnlineFilter.all => true,
        OnlineFilter.online => user.isOnline,
        OnlineFilter.offline => !user.isOnline,
      };

      return roleMatch && onlineMatch;
    }).toList();
  }

  void _navigateToProfile(User user) {
    // ✅ NEW: If in DM mode, open conversation instead of profile
    if (widget.forDirectMessage) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DMConversationScreen(username: user.username),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(username: user.username),
        ),
      );
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titel
                  const Text(
                    'Filter',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Rolle-Filter
                  const Text(
                    'Rolle',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip(
                        label: 'Alle',
                        isSelected: _roleFilter == RoleFilter.all,
                        onTap: () {
                          setModalState(() => _roleFilter = RoleFilter.all);
                          setState(() {});
                        },
                      ),
                      _buildFilterChip(
                        label: 'Admin',
                        isSelected: _roleFilter == RoleFilter.admin,
                        onTap: () {
                          setModalState(() => _roleFilter = RoleFilter.admin);
                          setState(() {});
                        },
                      ),
                      _buildFilterChip(
                        label: 'Moderator',
                        isSelected: _roleFilter == RoleFilter.moderator,
                        onTap: () {
                          setModalState(
                            () => _roleFilter = RoleFilter.moderator,
                          );
                          setState(() {});
                        },
                      ),
                      _buildFilterChip(
                        label: 'User',
                        isSelected: _roleFilter == RoleFilter.user,
                        onTap: () {
                          setModalState(() => _roleFilter = RoleFilter.user);
                          setState(() {});
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Online-Filter
                  const Text(
                    'Status',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip(
                        label: 'Alle',
                        isSelected: _onlineFilter == OnlineFilter.all,
                        onTap: () {
                          setModalState(() => _onlineFilter = OnlineFilter.all);
                          setState(() {});
                        },
                      ),
                      _buildFilterChip(
                        label: 'Online',
                        isSelected: _onlineFilter == OnlineFilter.online,
                        onTap: () {
                          setModalState(
                            () => _onlineFilter = OnlineFilter.online,
                          );
                          setState(() {});
                        },
                      ),
                      _buildFilterChip(
                        label: 'Offline',
                        isSelected: _onlineFilter == OnlineFilter.offline,
                        onTap: () {
                          setModalState(
                            () => _onlineFilter = OnlineFilter.offline,
                          );
                          setState(() {});
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _roleFilter = RoleFilter.all;
                              _onlineFilter = OnlineFilter.all;
                            });
                            setState(() {});
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white30),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Zurücksetzen'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Anwenden'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B5CF6) : Colors.white30,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final searchResults = userProvider.searchResults;
    final filteredResults = _getFilteredResults(searchResults);
    final isLoading = userProvider.isLoading;
    final hasSearched = _searchController.text.trim().isNotEmpty;

    final activeFilterCount =
        (_roleFilter != RoleFilter.all ? 1 : 0) +
        (_onlineFilter != OnlineFilter.all ? 1 : 0);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('User-Suche', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Suchleiste + Filter-Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Suche nach Username...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF8B5CF6),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white70,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF8B5CF6),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Filter-Button
                Stack(
                  children: [
                    IconButton(
                      onPressed: _showFilterBottomSheet,
                      icon: const Icon(
                        Icons.filter_list,
                        color: Colors.white,
                        size: 28,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                    if (activeFilterCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF8B5CF6),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$activeFilterCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Ergebnisse
          Expanded(
            child: _buildResultsList(
              hasSearched: hasSearched,
              isLoading: isLoading,
              filteredResults: filteredResults,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList({
    required bool hasSearched,
    required bool isLoading,
    required List<User> filteredResults,
  }) {
    if (!hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Suche nach Benutzern',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gib einen Benutzernamen ein',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
        ),
      );
    }

    if (filteredResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Benutzer gefunden',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Versuche eine andere Suche',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredResults.length,
      itemBuilder: (context, index) {
        final user = filteredResults[index];
        return UserListTile(
          user: user,
          onTap: () => _navigateToProfile(user),
          showOnlineStatus: true,
          showRoleBadge: true,
        );
      },
    );
  }
}
