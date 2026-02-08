import 'package:flutter/material.dart';
import '../services/favorites_service.dart';
import '../models/favorite.dart';

/// Favorites Overview Widget v8.0
/// Simplified version using static API
class FavoritesOverviewWidget extends StatefulWidget {
  final Color accentColor;
  final String worldType; // 'materie' or 'energie'
  
  const FavoritesOverviewWidget({
    super.key,
    required this.accentColor,
    this.worldType = 'materie',
  });

  @override
  State<FavoritesOverviewWidget> createState() => _FavoritesOverviewWidgetState();
}

class _FavoritesOverviewWidgetState extends State<FavoritesOverviewWidget> {
  FavoriteType? _selectedFilter;
  String _searchQuery = '';
  
  List<Favorite> get _favorites {
    var favorites = FavoritesService.getAllFavorites();
    
    // Apply type filter
    if (_selectedFilter != null) {
      favorites = favorites.where((f) => f.type == _selectedFilter).toList();
    }
    
    // Apply search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      favorites = favorites.where((f) => 
        f.title.toLowerCase().contains(query) ||
        (f.description?.toLowerCase().contains(query) ?? false)
      ).toList();
    }
    
    return favorites;
  }

  @override
  Widget build(BuildContext context) {
    final favorites = _favorites;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.accentColor.withValues(alpha: 0.1),
            Colors.black.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.favorite, color: widget.accentColor, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Deine Favoriten',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${favorites.length}',
                    style: TextStyle(
                      color: widget.accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Favoriten durchsuchen...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                prefixIcon: Icon(Icons.search, color: widget.accentColor),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterChip('Alle', null),
                const SizedBox(width: 8),
                _buildFilterChip('Recherchen', FavoriteType.research),
                const SizedBox(width: 8),
                _buildFilterChip('Narratives', FavoriteType.narrative),
                const SizedBox(width: 8),
                _buildFilterChip('PDFs', FavoriteType.pdf),
                const SizedBox(width: 8),
                _buildFilterChip('Bilder', FavoriteType.image),
                const SizedBox(width: 8),
                _buildFilterChip('Videos', FavoriteType.video),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Favorites List
          Expanded(
            child: favorites.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Noch keine Favoriten',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: favorites.length,
                    itemBuilder: (context, index) {
                      final favorite = favorites[index];
                      return _buildFavoriteCard(favorite);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, FavoriteType? type) {
    final isSelected = _selectedFilter == type;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = selected ? type : null);
      },
      selectedColor: widget.accentColor,
      backgroundColor: Colors.white.withValues(alpha: 0.1),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildFavoriteCard(Favorite favorite) {
    IconData icon;
    switch (favorite.type) {
      case FavoriteType.research:
        icon = Icons.search;
        break;
      case FavoriteType.narrative:
        icon = Icons.account_tree;
        break;
      case FavoriteType.pdf:
        icon = Icons.picture_as_pdf;
        break;
      case FavoriteType.image:
        icon = Icons.image;
        break;
      case FavoriteType.video:
        icon = Icons.video_library;
        break;
      case FavoriteType.telegram:
        icon = Icons.telegram;
        break;
      case FavoriteType.source:
        icon = Icons.link;
        break;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: widget.accentColor),
        title: Text(
          favorite.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: favorite.description != null
            ? Text(
                favorite.description!,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () async {
            await FavoritesService.deleteFavorite(favorite.id);
            setState(() {});
          },
        ),
        onTap: () {
          // TODO: Navigate to favorite item
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('TODO: Open ${favorite.title}')),
          );
        },
      ),
    );
  }
}
