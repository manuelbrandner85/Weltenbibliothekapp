import 'package:flutter/material.dart';
import '../data/mystical_events_data.dart';
import '../models/event_model.dart';
import 'modern_event_detail_screen.dart';
import '../widgets/modern_event_card.dart';
import '../widgets/mystical_particle_effects.dart'; // NEW: Particle Effects

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final allEvents = MysticalEventsData.getAllEvents();
    final featuredEvents = allEvents.take(6).toList();

    return MysticalParticleEffect(
      // NEW: Wrap entire screen
      particleCount: 15,
      particleColor: const Color(0xFFFFD700), // Gold particles
      particleSize: 2.0,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F1E),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar mit mystischem Header-Banner
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF1A1A2E),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Mystisches Header-Banner
                      Image.asset(
                        'assets/images/home_header_banner.png',
                        fit: BoxFit.cover,
                      ),
                      // Dunkler Gradient-Overlay für Lesbarkeit
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.3),
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                      // Zentrierter Content
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            // Icon mit goldenem Glow
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFD4AF37,
                                    ).withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.explore,
                                size: 56,
                                color: Color(0xFFD4AF37), // Goldenes Icon
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Titel mit starkem Schatten
                            Text(
                              '141 Mystische Orte',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius: 8,
                                    color: Colors.black.withValues(alpha: 0.8),
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Statistiken
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildStatisticsSection(allEvents),
                ),
              ),

              // Featured Events Header
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'Ausgewählte Orte',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Featured Events Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final event = featuredEvents[index];
                    return ModernEventCard(
                      event: event,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ModernEventDetailScreen(event: event),
                          ),
                        );
                      },
                    );
                  }, childCount: featuredEvents.length),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ), // Close Scaffold
    ); // Close MysticalParticleEffect
  }

  Widget _buildStatisticsSection(List<EventModel> events) {
    final categories = {
      'archaeology': events.where((e) => e.category == 'archaeology').length,
      'alternative': events.where((e) => e.category == 'alternative').length,
      'energy': events.where((e) => e.category == 'energy').length,
      'phenomenon': events.where((e) => e.category == 'phenomenon').length,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF9B59B6).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.location_on,
                label: 'Gesamt',
                value: '${events.length}',
                color: const Color(0xFF9B59B6),
              ),
              _buildStatItem(
                icon: Icons.category,
                label: 'Kategorien',
                value: '${categories.length}',
                color: const Color(0xFF3498DB),
              ),
              _buildStatItem(
                icon: Icons.explore,
                label: 'Energie',
                value: '${categories['energy']}',
                color: const Color(0xFF2ECC71),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCategoryChip('🏛️', categories['archaeology'] ?? 0),
              _buildCategoryChip('🔍', categories['alternative'] ?? 0),
              _buildCategoryChip('⚡', categories['energy'] ?? 0),
              _buildCategoryChip('❓', categories['phenomenon'] ?? 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String emoji, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF9B59B6).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: const TextStyle(
              color: Color(0xFF9B59B6),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedEventCard(BuildContext context, EventModel event) {
    return Card(
      color: const Color(0xFF1A1A2E),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ModernEventDetailScreen(event: event),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder with category-based gradient
            Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getCategoryColor(event.category).withValues(alpha: 0.7),
                    _getCategoryColor(event.category).withValues(alpha: 0.4),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  if (event.imageUrl != null)
                    Image.network(
                      event.imageUrl!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getCategoryColor(
                              event.category,
                            ).withValues(alpha: 0.9),
                            _getCategoryColor(
                              event.category,
                            ).withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getCategoryColor(
                              event.category,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Text(
                        EventModel.getCategoryName(event.category),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.graphic_eq, size: 12, color: Colors.white38),
                        const SizedBox(width: 4),
                        Text(
                          '${event.resonanceFrequency?.toStringAsFixed(2) ?? "N/A"} Hz',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'archaeology':
        return const Color(0xFFF59E0B); // Gold
      case 'mystery':
        return const Color(0xFF8B5CF6); // Violet
      case 'historical':
        return const Color(0xFF3B82F6); // Blue
      case 'energy':
        return const Color(0xFF10B981); // Green
      case 'phenomenon':
        return const Color(0xFF06B6D4); // Cyan
      default:
        return const Color(0xFF8B5CF6); // Default Violet
    }
  }
}
