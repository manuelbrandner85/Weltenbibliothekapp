import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'glassmorphism_card.dart';
import 'premium_icons.dart';

/// 🎬 VIDEO PREVIEW WIDGET - Video-Vorschau mit Thumbnail
class VideoPreviewWidget extends StatelessWidget {
  final XFile video;
  final VoidCallback onRemove;
  final Map<String, dynamic>? metadata;
  
  const VideoPreviewWidget({
    super.key,
    required this.video,
    required this.onRemove,
    this.metadata,
  });
  
  @override
  Widget build(BuildContext context) {
    return GlassmorphismCard(
      blur: 15,
      opacity: 0.1,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Video Icon mit Gradient
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.play_circle_filled,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          
          // Video Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (metadata != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${(metadata!['sizeMB'] as double).toStringAsFixed(1)} MB',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Remove Button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// 🎥 GIF PICKER WIDGET - GIF-Auswahl-Dialog
class GifPickerWidget extends StatefulWidget {
  final Function(String gifUrl) onGifSelected;
  
  const GifPickerWidget({
    super.key,
    required this.onGifSelected,
  });
  
  @override
  State<GifPickerWidget> createState() => _GifPickerWidgetState();
}

class _GifPickerWidgetState extends State<GifPickerWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _gifs = [];
  bool _isLoading = false;
  String _selectedCategory = 'Trending';
  
  final List<String> _categories = [
    'Trending',
    'Funny',
    'Reaction',
    'Love',
    'Sad',
    'Happy',
    'Dance',
    'Celebration',
  ];
  
  @override
  void initState() {
    super.initState();
    _loadTrendingGifs();
  }
  
  Future<void> _loadTrendingGifs() async {
    setState(() => _isLoading = true);
    // Simuliere Tenor API Call
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _gifs = List.generate(20, (i) => {
        'id': 'gif_$i',
        'url': 'https://via.placeholder.com/200x150.gif?text=GIF+${i+1}',
        'title': 'Trending GIF ${i+1}',
      });
      _isLoading = false;
    });
  }
  
  Future<void> _searchGifs(String query) async {
    if (query.isEmpty) {
      _loadTrendingGifs();
      return;
    }
    
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _gifs = List.generate(20, (i) => {
        'id': 'search_$i',
        'url': 'https://via.placeholder.com/200x150.gif?text=$query+${i+1}',
        'title': '$query ${i+1}',
      });
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const GradientIcon(
                icon: Icons.gif_box,
                size: 28,
                colors: [Color(0xFF00BCD4), Color(0xFF3F51B5)],
              ),
              const SizedBox(width: 12),
              const Text(
                'GIF auswählen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Search Bar
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'GIF suchen...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: _searchGifs,
          ),
          const SizedBox(height: 16),
          
          // Categories
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedCategory = category);
                      _searchGifs(category);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF00BCD4), Color(0xFF3F51B5)],
                              )
                            : null,
                        color: isSelected ? null : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // GIF Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _gifs.length,
                    itemBuilder: (context, index) {
                      final gif = _gifs[index];
                      return InkWell(
                        onTap: () {
                          widget.onGifSelected(gif['url']);
                          Navigator.pop(context);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            color: Colors.white.withValues(alpha: 0.1),
                            child: Center(
                              child: Text(
                                gif['title'],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// 📸 MULTI-IMAGE GALLERY WIDGET - Swipeable Image Gallery
class MultiImageGalleryWidget extends StatelessWidget {
  final List<XFile> images;
  final Function(int index) onRemove;
  final VoidCallback onAddMore;
  final int maxImages;
  
  const MultiImageGalleryWidget({
    super.key,
    required this.images,
    required this.onRemove,
    required this.onAddMore,
    this.maxImages = 5,
  });
  
  @override
  Widget build(BuildContext context) {
    return GlassmorphismCard(
      blur: 15,
      opacity: 0.1,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GradientIcon(
                icon: Icons.photo_library,
                size: 24,
                colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
              ),
              const SizedBox(width: 8),
              Text(
                '${images.length}/$maxImages Bilder',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (images.length < maxImages)
                TextButton.icon(
                  onPressed: onAddMore,
                  icon: const Icon(Icons.add_photo_alternate, color: Colors.white, size: 18),
                  label: const Text(
                    'Mehr',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Image Grid
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(images[index].path),
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () => onRemove(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
