import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/event_model.dart';
import '../providers/event_provider.dart';
import '../services/schumann_service.dart';

/// 🎨 Moderner Event-Detail-Screen
///
/// Glassmorphismus-Design mit Gradient-Backgrounds, animierten Sections
/// und modernen Material Design 3 Komponenten
class ModernEventDetailScreen extends StatefulWidget {
  final EventModel event;

  const ModernEventDetailScreen({super.key, required this.event});

  @override
  State<ModernEventDetailScreen> createState() =>
      _ModernEventDetailScreenState();
}

class _ModernEventDetailScreenState extends State<ModernEventDetailScreen>
    with SingleTickerProviderStateMixin {
  YoutubePlayerController? _youtubeController;
  final SchumannResonanceService _schumannService = SchumannResonanceService();
  SchumannData? _schumannData;
  bool _isLoadingSchumann = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeYoutubePlayer();
    _loadSchumannData();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  Future<void> _loadSchumannData() async {
    try {
      final data = await _schumannService.getResonanceForLocation(
        widget.event.location.latitude,
        widget.event.location.longitude,
      );
      if (mounted) {
        setState(() {
          _schumannData = data;
          _isLoadingSchumann = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSchumann = false);
      }
    }
  }

  void _initializeYoutubePlayer() {
    if (widget.event.videoUrl != null) {
      final videoId = YoutubePlayer.convertUrlToId(widget.event.videoUrl!);
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
        );
      }
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Color _getCategoryColor() {
    switch (widget.event.category.toLowerCase()) {
      case 'mysterium':
      case 'mystery':
        return const Color(0xFF8B5CF6);
      case 'archäologie':
      case 'archaeology':
        return const Color(0xFFF59E0B);
      case 'historisch':
      case 'historical':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.watch<EventProvider>().isFavorite(
      widget.event.id,
    );
    final categoryColor = _getCategoryColor();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        bottom: true,
        child: CustomScrollView(
          slivers: [
            // Modern App Bar mit Gradient
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              stretch: true,
              backgroundColor: const Color(0xFF1E293B),
              flexibleSpace: FlexibleSpaceBar(
                title: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.black.withValues(alpha: 0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.event.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 4,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Hintergrundbild
                    if (widget.event.imageUrl != null)
                      Image.network(
                        widget.event.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  categoryColor.withValues(alpha: 0.6),
                                  categoryColor.withValues(alpha: 0.3),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                // Favorite Button
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_outline,
                      color: isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: () {
                      context.read<EventProvider>().toggleFavorite(
                        widget.event.id,
                      );
                    },
                  ),
                ),
                // Share Button
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () => _shareEvent(),
                  ),
                ),
              ],
            ),

            // Content
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kategorie & Verifizierung
                      _buildCategoryBadge(categoryColor),
                      const SizedBox(height: 24),

                      // Datum & Location
                      _buildMetaInfo(),
                      const SizedBox(height: 24),

                      // Schumann-Resonanz Card
                      if (!_isLoadingSchumann && _schumannData != null)
                        _buildSchumannCard(),
                      const SizedBox(height: 24),

                      // Beschreibung
                      _buildDescriptionCard(),
                      const SizedBox(height: 24),

                      // YouTube Video
                      if (_youtubeController != null) ...[
                        _buildVideoCard(),
                        const SizedBox(height: 24),
                      ],

                      // Tags
                      if (widget.event.tags.isNotEmpty) ...[
                        _buildTagsSection(),
                        const SizedBox(height: 24),
                      ],

                      // Quelle
                      if (widget.event.source != null) _buildSourceCard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(Color categoryColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                categoryColor.withValues(alpha: 0.3),
                categoryColor.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: categoryColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.label_rounded, size: 18, color: categoryColor),
              const SizedBox(width: 8),
              Text(
                widget.event.category.toUpperCase(),
                style: TextStyle(
                  color: categoryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (widget.event.isVerified)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.5),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: Color(0xFF10B981),
                ),
                SizedBox(width: 6),
                Text(
                  'VERIFIZIERT',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMetaInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          if (widget.event.date != null)
            _buildMetaRow(
              Icons.calendar_today_rounded,
              'Datum',
              DateFormat('dd. MMMM yyyy').format(widget.event.date!),
              const Color(0xFFFBBF24),
            ),
          const SizedBox(height: 16),
          _buildMetaRow(
            Icons.location_on_rounded,
            'Koordinaten',
            '${widget.event.location.latitude.toStringAsFixed(4)}, ${widget.event.location.longitude.toStringAsFixed(4)}',
            const Color(0xFF34D399),
          ),
          if (widget.event.resonanceFrequency != null) ...[
            const SizedBox(height: 16),
            _buildMetaRow(
              Icons.graphic_eq_rounded,
              'Schumann-Frequenz',
              '${widget.event.resonanceFrequency!.toStringAsFixed(2)} Hz',
              const Color(0xFF8B5CF6),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFFE2E8F0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSchumannCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withValues(alpha: 0.2),
            const Color(0xFF6D28D9).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.waves_rounded, color: Color(0xFF8B5CF6)),
              SizedBox(width: 12),
              Text(
                'Schumann-Resonanz',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE2E8F0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${_schumannData!.frequency.toStringAsFixed(2)} Hz',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B5CF6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Beschreibung',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE2E8F0),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.event.description,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF94A3B8),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: true,
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.event.tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF334155),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            tag,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSourceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.source_rounded, color: Color(0xFF64748B), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.event.source!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareEvent() {
    // Share functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Event teilen'),
        content: Text('Teile: ${widget.event.title}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }
}
