import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event_model.dart';
import '../providers/event_provider.dart';
import '../services/schumann_service.dart';
import '../widgets/mystical_particle_effects.dart';
import '../widgets/flippable_info_card.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  YoutubePlayerController? _youtubeController;
  final SchumannResonanceService _schumannService = SchumannResonanceService();
  SchumannData? _schumannData;
  bool _isLoadingSchumann = true;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeYoutubePlayer();
    _loadSchumannData();

    // Parallax scroll listener
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  /// Lade Schumann-Resonanz-Daten für Event-Location
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
        setState(() {
          _isLoadingSchumann = false;
        });
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.watch<EventProvider>().isFavorite(
      widget.event.id,
    );

    return MysticalParticleEffect(
      particleCount: 12,
      particleColor: const Color(0xFFFFD700),
      child: Scaffold(
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate parallax factor based on scroll position
                  final appBarHeight = constraints.maxHeight;
                  final parallaxFactor =
                      (appBarHeight - kToolbarHeight) / (300 - kToolbarHeight);
                  final imageScale = 1.0 + (parallaxFactor * 0.3);
                  final imageOffset = _scrollOffset * 0.5;

                  return FlexibleSpaceBar(
                    title: AnimatedOpacity(
                      opacity: parallaxFactor < 0.5 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        widget.event.title,
                        style: const TextStyle(
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 8,
                              color: Colors.black87,
                            ),
                          ],
                        ),
                      ),
                    ),
                    background: Hero(
                      tag: 'event_hero_${widget.event.id}',
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Parallax image layer
                          Transform.scale(
                            scale: imageScale,
                            child: Transform.translate(
                              offset: Offset(0, -imageOffset),
                              child: widget.event.imageUrl != null
                                  ? Image.network(
                                      widget.event.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.secondary,
                                                  ],
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.image_not_supported,
                                                size: 64,
                                              ),
                                            );
                                          },
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                          ],
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.location_on,
                                          size: 80,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          // Gradient overlay for better text visibility
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.7),
                                ],
                                stops: const [0.5, 1.0],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_outline,
                    color: isFavorite ? Colors.red : null,
                  ),
                  onPressed: () {
                    context.read<EventProvider>().toggleFavorite(
                      widget.event.id,
                    );
                  },
                  tooltip: 'Zu Favoriten hinzufügen',
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareEvent(),
                  tooltip: 'Teilen',
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kategorie & Verifizierung
                    Row(
                      children: [
                        Chip(
                          avatar: Text(_getCategoryEmoji()),
                          label: Text(_getCategoryLabel()),
                        ),
                        const SizedBox(width: 8),
                        if (widget.event.isVerified)
                          const Chip(
                            avatar: Icon(Icons.verified, size: 18),
                            label: Text('Verifiziert'),
                            backgroundColor: Colors.green,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Datum
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Datum'),
                      subtitle: Text(
                        DateFormat('dd.MM.yyyy').format(widget.event.date),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),

                    // Koordinaten
                    ListTile(
                      leading: const Icon(Icons.place),
                      title: const Text('Koordinaten'),
                      subtitle: Text(
                        '${widget.event.location.latitude.toStringAsFixed(4)}, '
                        '${widget.event.location.longitude.toStringAsFixed(4)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () => _openInMaps(),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),

                    // SCHUMANN-RESONANZ CARD
                    _buildSchumannResonanceCard(),

                    const SizedBox(height: 16),

                    // Quelle
                    if (widget.event.source != null)
                      ListTile(
                        leading: const Icon(Icons.source),
                        title: const Text('Quelle'),
                        subtitle: Text(widget.event.source!),
                        contentPadding: EdgeInsets.zero,
                      ),

                    const Divider(height: 32),

                    // Beschreibung
                    const Text(
                      'Beschreibung',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.event.description,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    // Tags
                    if (widget.event.tags.isNotEmpty) ...[
                      const Text(
                        'Tags',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.event.tags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 🎴 3D-FLIP CARDS für zusätzliche Infos
                    const Text(
                      'Zusätzliche Informationen',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Energie-Info Flip-Card
                    FlippableInfoCard(
                      front: EventInfoFront(
                        title: 'Energie-Signatur',
                        subtitle: 'Tippen für Details',
                        icon: Icons.bolt_rounded,
                        color: const Color(0xFF10B981),
                      ),
                      back: EventInfoBack(
                        content:
                            'Dieses Event weist eine besondere energetische Signatur auf.',
                        bulletPoints: [
                          'Resonanzfrequenz: ${widget.event.resonanceFrequency?.toStringAsFixed(2) ?? "N/A"} Hz',
                          'Kategorie: ${widget.event.category}',
                          'Verifiziert: ${widget.event.isVerified ? "Ja" : "Nein"}',
                        ],
                        color: const Color(0xFF10B981),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Historischer Kontext Flip-Card
                    FlippableInfoCard(
                      front: EventInfoFront(
                        title: 'Historischer Kontext',
                        subtitle: 'Tippen für Details',
                        icon: Icons.history_edu_rounded,
                        color: const Color(0xFF8B5CF6),
                      ),
                      back: EventInfoBack(
                        content:
                            'Historische Bedeutung und zeitlicher Kontext dieses Ereignisses.',
                        bulletPoints: [
                          'Datum: ${DateFormat('dd.MM.yyyy').format(widget.event.date)}',
                          'Location: ${widget.event.location.latitude.toStringAsFixed(2)}°, ${widget.event.location.longitude.toStringAsFixed(2)}°',
                          'Quelle: ${widget.event.source ?? "Nicht angegeben"}',
                        ],
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Video Player
                    if (_youtubeController != null) ...[
                      const Text(
                        'Video',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      YoutubePlayer(
                        controller: _youtubeController!,
                        showVideoProgressIndicator: true,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Dokument-Link
                    if (widget.event.documentUrl != null) ...[
                      const Text(
                        'Dokument',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf, size: 40),
                          title: const Text('Dokument anzeigen'),
                          subtitle: const Text('PDF-Datei'),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () => _openDocument(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryEmoji() {
    final cat = EventCategory.values.firstWhere(
      (c) => c.name == widget.event.category,
      orElse: () => EventCategory.mystery,
    );
    return cat.emoji;
  }

  String _getCategoryLabel() {
    final cat = EventCategory.values.firstWhere(
      (c) => c.name == widget.event.category,
      orElse: () => EventCategory.mystery,
    );
    return cat.label;
  }

  void _shareEvent() {
    // Share-Funktionalität implementieren
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share-Funktion wird implementiert...')),
    );
  }

  void _openInMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query='
      '${widget.event.location.latitude},${widget.event.location.longitude}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _openDocument() async {
    if (widget.event.documentUrl != null) {
      final url = Uri.parse(widget.event.documentUrl!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  /// Schumann-Resonanz Widget
  Widget _buildSchumannResonanceCard() {
    if (_isLoadingSchumann) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Lade Schumann-Resonanz-Daten...'),
            ],
          ),
        ),
      );
    }

    if (_schumannData == null) {
      return const SizedBox.shrink();
    }

    final frequency = _schumannData!.frequency;
    final interpretation = _schumannService.interpretFrequency(frequency);
    final intensity = _schumannService.calculateEnergyIntensity(frequency);

    Color frequencyColor;
    if (frequency < 7.7) {
      frequencyColor = Colors.blue;
    } else if (frequency < 7.9) {
      frequencyColor = Colors.green;
    } else if (frequency < 8.2) {
      frequencyColor = Colors.orange;
    } else {
      frequencyColor = Colors.red;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: frequencyColor.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              frequencyColor.withValues(alpha: 0.1),
              frequencyColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.waves, color: frequencyColor, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Schumann-Resonanz',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Frequenz-Anzeige
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Frequenz',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${frequency.toStringAsFixed(2)} Hz',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: frequencyColor,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Interpretation',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        interpretation,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: frequencyColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Energie-Intensität Balken
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Energie-Intensität',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: intensity,
                      minHeight: 12,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(frequencyColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(intensity * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: frequencyColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Quelle
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Quelle: ${_schumannData!.source}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
