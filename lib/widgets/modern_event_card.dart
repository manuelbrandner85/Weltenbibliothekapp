import 'package:flutter/material.dart';
import '../models/event_model.dart';
import 'package:intl/intl.dart';
import 'cached_network_image_widget.dart';

/// 🎨 Moderne Event-Card für Weltenbibliothek
///
/// Glassmorphismus-Design mit Gradients, Schatten und Animationen
class ModernEventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const ModernEventCard({super.key, required this.event, required this.onTap});

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'mysterium':
      case 'mystery':
        return const Color(0xFF8B5CF6); // Violett
      case 'archäologie':
      case 'archaeology':
        return const Color(0xFFF59E0B); // Gold
      case 'historisch':
      case 'historical':
        return const Color(0xFF3B82F6); // Blau
      case 'energie':
      case 'energy':
        return const Color(0xFF10B981); // Grün
      case 'wissenschaft':
      case 'science':
        return const Color(0xFF06B6D4); // Cyan
      default:
        return const Color(0xFF6B7280); // Grau
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'mysterium':
      case 'mystery':
        return Icons.psychology_rounded;
      case 'archäologie':
      case 'archaeology':
        return Icons.account_balance_rounded;
      case 'historisch':
      case 'historical':
        return Icons.history_edu_rounded;
      case 'energie':
      case 'energy':
        return Icons.bolt_rounded;
      case 'wissenschaft':
      case 'science':
        return Icons.science_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(event.category);

    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'event_hero_${event.id}',
        flightShuttleBuilder:
            (flightContext, animation, direction, fromContext, toContext) {
              // Smooth transition animation
              return Material(
                color: Colors.transparent,
                child: toContext.widget,
              );
            },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1E293B),
                const Color(0xFF334155).withValues(alpha: 0.8),
              ],
            ),
            border: Border.all(
              color: categoryColor.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: categoryColor.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Hintergrundbild mit Gradient-Overlay
                if (event.imageUrl != null)
                  Positioned.fill(
                    child: Stack(
                      children: [
                        CachedNetworkImageWidget(
                          imageUrl: event.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 200,
                          errorWidget: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  categoryColor.withValues(alpha: 0.3),
                                  categoryColor.withValues(alpha: 0.1),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Dark Gradient Overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.3),
                                Colors.black.withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kategorie Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: categoryColor.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getCategoryIcon(event.category),
                                  size: 16,
                                  color: categoryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  event.category.toUpperCase(),
                                  style: TextStyle(
                                    color: categoryColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Resonanz-Frequenz
                          if (event.resonanceFrequency != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF8B5CF6,
                                ).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFF8B5CF6,
                                  ).withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.graphic_eq_rounded,
                                    size: 14,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${event.resonanceFrequency!.toStringAsFixed(2)} Hz',
                                    style: const TextStyle(
                                      color: Color(0xFF8B5CF6),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const Spacer(),

                      // Titel
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE2E8F0),
                          letterSpacing: 0.5,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 12),

                      // Beschreibung (gekürzt)
                      Text(
                        event.description.split('\n').first,
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF94A3B8),
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 16),

                      // Meta-Informationen
                      Row(
                        children: [
                          // Datum
                          if (event.date != null) ...[
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('dd.MM.yyyy').format(event.date!),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],

                          // Verifiziert Badge
                          if (event.isVerified) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    size: 14,
                                    color: Color(0xFF10B981),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'VERIFIZIERT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Glow-Effekt am Rand
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: categoryColor.withValues(alpha: 0.1),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
