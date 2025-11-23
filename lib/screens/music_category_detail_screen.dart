import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/music_category.dart';
import '../providers/music_library_provider.dart';
import '../widgets/music/music_content_list_tile.dart';

/// 📂 Musik-Kategorie Detail Screen
class MusicCategoryDetailScreen extends StatefulWidget {
  final ContentCategory category;

  const MusicCategoryDetailScreen({super.key, required this.category});

  @override
  State<MusicCategoryDetailScreen> createState() =>
      _MusicCategoryDetailScreenState();
}

class _MusicCategoryDetailScreenState extends State<MusicCategoryDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final libraryProvider = Provider.of<MusicLibraryProvider>(
        context,
        listen: false,
      );
      libraryProvider.searchByCategory(widget.category);
    });
  }

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<MusicLibraryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        backgroundColor: widget.category.color,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.category.color.withValues(alpha: 0.8),
                  widget.category.color,
                ],
              ),
            ),
            child: Column(
              children: [
                Icon(widget.category.icon, size: 64, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  widget.category.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFF0F0F1E),
              child: libraryProvider.isLoading
                  ? Center(
                      child: SpinKitFadingCircle(
                        color: widget.category.color,
                        size: 50.0,
                      ),
                    )
                  : libraryProvider.error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            libraryProvider.error!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              libraryProvider.searchByCategory(widget.category);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.category.color,
                            ),
                            child: const Text('Erneut versuchen'),
                          ),
                        ],
                      ),
                    )
                  : libraryProvider.searchResults.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Keine Inhalte gefunden',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: libraryProvider.searchResults.length,
                      itemBuilder: (context, index) {
                        final content = libraryProvider.searchResults[index];
                        return MusicContentListTile(content: content);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
