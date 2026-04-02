import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../../models/knowledge_extended_models.dart';

/// ============================================
/// MODERNE KNOWLEDGE CARD
/// Features:
/// - Gradient Background basierend auf Kategorie
/// - Category Badge mit Icon
/// - Lesezeit-Badge
/// - Hero Animation ready
/// - Glassmorphism Effect
/// ============================================

class KnowledgeCardModern extends StatelessWidget {
  final KnowledgeEntry entry;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final Color primaryColor;

  const KnowledgeCardModern({
    super.key,
    required this.entry,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = _getCategoryColor(entry.category);
    
    return Hero(
      tag: 'knowledge_${entry.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        categoryColor.withValues(alpha: 0.15),
                        categoryColor.withValues(alpha: 0.05),
                      ]
                    : [
                        categoryColor.withValues(alpha: 0.1),
                        Colors.white,
                      ],
              ),
              border: Border.all(
                color: categoryColor.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: categoryColor.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Glassmorphism Effect
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          categoryColor.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Badge & Favorite
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCategoryBadge(categoryColor, isDark),
                          _buildFavoriteButton(),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Title
                      Text(
                        entry.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Description
                      Text(
                        entry.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: (isDark ? Colors.white : Colors.black87).withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Bottom Row: Tags & Reading Time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // First Tag
                          if (entry.tags.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: categoryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '#${entry.tags.first}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: categoryColor,
                                ),
                              ),
                            ),
                          
                          // Reading Time Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: (isDark ? Colors.white : Colors.black87)
                                      .withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${entry.readingTimeMinutes} Min',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: (isDark ? Colors.white : Colors.black87)
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(Color categoryColor, bool isDark) {
    final icon = _getCategoryIcon(entry.category);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: categoryColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: categoryColor),
          const SizedBox(width: 6),
          Text(
            _getCategoryName(entry.category),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: categoryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: onFavoriteToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isFavorite
              ? Colors.red.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? Colors.red : Colors.grey,
          size: 20,
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'conspiracy':
        return const Color(0xFFE74C3C); // Red
      case 'research':
        return const Color(0xFF3498DB); // Blue
      case 'forbidden_knowledge':
        return const Color(0xFF9B59B6); // Purple
      case 'ancient_wisdom':
        return const Color(0xFFF39C12); // Orange
      case 'meditation':
        return const Color(0xFF1ABC9C); // Turquoise
      case 'astrology':
        return const Color(0xFFE91E63); // Pink
      case 'energy_work':
        return const Color(0xFF00BCD4); // Cyan
      case 'consciousness':
        return const Color(0xFF9C27B0); // Deep Purple
      default:
        return const Color(0xFF95A5A6); // Gray
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'conspiracy':
        return Icons.psychology;
      case 'research':
        return Icons.science;
      case 'forbidden_knowledge':
        return Icons.lock;
      case 'ancient_wisdom':
        return Icons.auto_stories;
      case 'meditation':
        return Icons.self_improvement;
      case 'astrology':
        return Icons.nights_stay;
      case 'energy_work':
        return Icons.bolt;
      case 'consciousness':
        return Icons.visibility;
      default:
        return Icons.article;
    }
  }

  String _getCategoryName(String category) {
    switch (category.toLowerCase()) {
      case 'conspiracy':
        return 'Verschwörung';
      case 'research':
        return 'Forschung';
      case 'forbidden_knowledge':
        return 'Verboten';
      case 'ancient_wisdom':
        return 'Weisheit';
      case 'meditation':
        return 'Meditation';
      case 'astrology':
        return 'Astrologie';
      case 'energy_work':
        return 'Energie';
      case 'consciousness':
        return 'Bewusstsein';
      default:
        return category;
    }
  }
}
