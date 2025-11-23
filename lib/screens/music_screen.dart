import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/music_category.dart';
import '../providers/music_library_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/music/music_category_card.dart';
import '../widgets/music/music_mini_player.dart';
import '../widgets/music/music_content_list_tile.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// 🎵 Musik-Screen - Neuer Tab in Weltenbibliothek
class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final hasCurrentContent = playerProvider.currentContent != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎵 Musik & Podcasts'),
        backgroundColor: const Color(0xFF9B59B6),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.category), text: 'Kategorien'),
            Tab(icon: Icon(Icons.library_music), text: 'Bibliothek'),
            Tab(icon: Icon(Icons.search), text: 'Suche'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCategoriesTab(),
                _buildLibraryTab(),
                _buildSearchTab(),
              ],
            ),
          ),
          if (hasCurrentContent) const MusicMiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return Container(
      color: const Color(0xFF0F0F1E),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Entdecke verborgenes Wissen',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Wähle eine Kategorie und tauche ein',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: defaultCategories.length,
              itemBuilder: (context, index) {
                return MusicCategoryCard(category: defaultCategories[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryTab() {
    final libraryProvider = Provider.of<MusicLibraryProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: const Color(0xFF1A1A2E),
            child: const TabBar(
              labelColor: Color(0xFF9B59B6),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF9B59B6),
              tabs: [
                Tab(icon: Icon(Icons.library_music), text: 'Bibliothek'),
                Tab(icon: Icon(Icons.favorite), text: 'Favoriten'),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFF0F0F1E),
              child: TabBarView(
                children: [
                  _buildContentList(
                    contents: libraryProvider.library,
                    emptyIcon: Icons.library_music,
                    emptyMessage: 'Noch keine Inhalte',
                  ),
                  _buildContentList(
                    contents: libraryProvider.favorites,
                    emptyIcon: Icons.favorite_border,
                    emptyMessage: 'Noch keine Favoriten',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    final libraryProvider = Provider.of<MusicLibraryProvider>(context);

    return Container(
      color: const Color(0xFF0F0F1E),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Durchsuche YouTube',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Suche nach Themen...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF9B59B6),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              libraryProvider.clearSearchResults();
                              setState(() => _hasSearched = false);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Color(0xFF9B59B6)),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF2A2A3E),
                  ),
                  onSubmitted: (_) => _performSearch(),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _searchController.text.trim().isEmpty
                      ? null
                      : _performSearch,
                  icon: const Icon(Icons.search),
                  label: const Text('Suchen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9B59B6),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: libraryProvider.isLoading
                ? const Center(
                    child: SpinKitFadingCircle(
                      color: Color(0xFF9B59B6),
                      size: 50.0,
                    ),
                  )
                : !_hasSearched
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 80,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Gib einen Suchbegriff ein',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : libraryProvider.searchResults.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Keine Ergebnisse',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: libraryProvider.searchResults.length,
                    itemBuilder: (context, index) {
                      return MusicContentListTile(
                        content: libraryProvider.searchResults[index],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentList({
    required List contents,
    required IconData emptyIcon,
    required String emptyMessage,
  }) {
    if (contents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: contents.length,
      itemBuilder: (context, index) {
        return MusicContentListTile(content: contents[index]);
      },
    );
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      final libraryProvider = Provider.of<MusicLibraryProvider>(
        context,
        listen: false,
      );
      libraryProvider.searchByText(query);
      setState(() => _hasSearched = true);
      FocusScope.of(context).unfocus();
    }
  }
}
