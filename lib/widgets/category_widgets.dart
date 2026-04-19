import 'package:flutter/material.dart';

/// Kategorie Model
class NarrativeCategory {
  final String id;
  final String name;
  final String icon;
  final Color color;

  NarrativeCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  factory NarrativeCategory.fromJson(Map<String, dynamic> json) {
    return NarrativeCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: _parseColor(json['color'] as String? ?? '#808080'),
    );
  }

  static Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}

/// Category Filter Chips Widget
class CategoryFilterChips extends StatelessWidget {
  final List<NarrativeCategory> categories;
  final String? selectedCategoryId;
  final Function(String?) onCategorySelected;

  const CategoryFilterChips({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // "Alle" Chip
          _buildCategoryChip(
            context,
            label: 'Alle',
            icon: '🌐',
            color: Colors.grey,
            isSelected: selectedCategoryId == null,
            onTap: () => onCategorySelected(null),
          ),
          const SizedBox(width: 8),
          
          // Category Chips
          ...categories.map((category) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildCategoryChip(
              context,
              label: category.name,
              icon: category.icon,
              color: category.color,
              isSelected: selectedCategoryId == category.id,
              onTap: () => onCategorySelected(category.id),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context, {
    required String label,
    required String icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: color.withAlpha((0.2 * 255).round()),
      selectedColor: color,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? color : color.withAlpha((0.5 * 255).round()),
        width: isSelected ? 2 : 1,
      ),
    );
  }
}

/// Narrative Card with Category Badges
class NarrativeCard extends StatelessWidget {
  final Map<String, dynamic> narrative;
  final VoidCallback onTap;

  const NarrativeCard({
    super.key,
    required this.narrative,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = narrative['title'] as String? ?? 'Unbekannt';
    final categories = narrative['categories'] as List<dynamic>? ?? [];
    final priority = narrative['priority'] as int? ?? 3;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Priority Badge
              if (priority <= 2)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priority == 1 ? Colors.red : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    priority == 1 ? '🔥 TOP' : '⭐ WICHTIG',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              
              const SizedBox(height: 8),
              
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Category Tags
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: categories.map((cat) {
                  final catStr = cat as String;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(catStr).withAlpha((0.2 * 255).round()),
                      border: Border.all(color: _getCategoryColor(catStr)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getCategoryName(catStr),
                      style: TextStyle(
                        fontSize: 11,
                        color: _getCategoryColor(catStr),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 8),
              
              // Arrow
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String categoryId) {
    switch (categoryId) {
      case 'ufo':
        return const Color(0xFF00FF00);
      case 'secret_society':
        return const Color(0xFF8B4513);
      case 'technology':
        return const Color(0xFFFFD700);
      case 'history':
        return const Color(0xFFCD5C5C);
      case 'geopolitics':
        return const Color(0xFF4169E1);
      case 'science':
        return const Color(0xFF32CD32);
      case 'cosmology':
        return const Color(0xFF9370DB);
      default:
        return Colors.grey;
    }
  }

  String _getCategoryName(String categoryId) {
    switch (categoryId) {
      case 'ufo':
        return '👽 UFOs';
      case 'secret_society':
        return '🏛️ Geheimgesellschaft';
      case 'technology':
        return '⚡ Technologie';
      case 'history':
        return '📜 Historie';
      case 'geopolitics':
        return '🌍 Geopolitik';
      case 'science':
        return '🔬 Wissenschaft';
      case 'cosmology':
        return '🌌 Kosmologie';
      default:
        return categoryId;
    }
  }
}
