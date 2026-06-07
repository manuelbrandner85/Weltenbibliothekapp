// Mediathek screen — full video archive per world.
// Inline YouTube playback via youtube_player_flutter.
// Category chips for filtering, search field over youtube_title + raw_title.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../services/archive_video_service.dart';

// ── Category chip definition (no Record types) ──────────────────────────────

class _CategoryChip {
  final String label;
  final String? emoji;

  const _CategoryChip({required this.label, this.emoji});
}

// ── Screen ───────────────────────────────────────────────────────────────────

class MediathekScreen extends StatefulWidget {
  final String world;
  // embedded=true: als Tab in der Welt-Navigationsleiste -> keine eigene
  // AppBar mit Back-Button + transparenter Hintergrund (Welt-Background
  // scheint durch). embedded=false (Default): Vollbild-Screen mit AppBar.
  final bool embedded;
  const MediathekScreen({super.key, required this.world, this.embedded = false});

  @override
  State<MediathekScreen> createState() => _MediathekScreenState();
}

class _MediathekScreenState extends State<MediathekScreen> {
  final _svc = ArchiveVideoService.instance;
  final _searchCtrl = TextEditingController();

  List<ArchiveVideo> _videos = [];
  List<ArchiveVideo> _filtered = [];
  List<_CategoryChip> _chips = [];
  String? _activeCategory;
  bool _isLoading = true;

  // ── world accent ────────────────────────────────────────────────────────────
  Color get _primary {
    switch (widget.world) {
      case 'materie':
        return const Color(0xFF3B82F6);
      case 'energie':
        return const Color(0xFFA855F7);
      case 'vorhang':
        return const Color(0xFFC9A84C);
      case 'ursprung':
        return const Color(0xFF00D4AA);
      default:
        return const Color(0xFFA855F7);
    }
  }

  Color get _primarySoft {
    switch (widget.world) {
      case 'materie':
        return const Color(0xFF60A5FA);
      case 'energie':
        return const Color(0xFFC084FC);
      case 'vorhang':
        return const Color(0xFFE0C872);
      case 'ursprung':
        return const Color(0xFF40E8C0);
      default:
        return const Color(0xFFC084FC);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    // 2026-06-07: search + fetchCategories parallelisieren -- vorher
    // seriell, ~200-400ms Mehrlatenz beim ersten Aufruf.
    final results = await Future.wait([
      _svc.search(world: widget.world, query: ''),
      _svc.fetchCategories(widget.world),
    ]);
    final videos = (results[0] as List).cast<ArchiveVideo>();
    final cats = (results[1] as List).cast<String>();
    if (!mounted) return;
    setState(() {
      _videos = videos;
      _chips = cats
          .map((c) => _CategoryChip(label: c, emoji: _emojiForCategory(c)))
          .toList();
      _isLoading = false;
      _applyFilter();
    });
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = _videos.where((v) {
        final matchCat =
            _activeCategory == null || v.category == _activeCategory;
        final matchSearch = q.isEmpty ||
            v.title.toLowerCase().contains(q) ||
            v.rawTitle.toLowerCase().contains(q);
        return matchCat && matchSearch;
      }).toList();
    });
  }

  String? _emojiForCategory(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('doku')) return '🎬';
    if (lower.contains('vortrag') || lower.contains('talk')) return '🎤';
    if (lower.contains('interview')) return '🎙️';
    if (lower.contains('meditation')) return '🧘';
    if (lower.contains('wissenschaft') || lower.contains('science')) return '🔬';
    if (lower.contains('natur')) return '🌿';
    if (lower.contains('spirituell') || lower.contains('spirit')) return '✨';
    return '📹';
  }

  void _openPlayer(ArchiveVideo video) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _VideoPlayerScreen(video: video, primary: _primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Embedded-Variante (Welt-Tab): kein Scaffold/AppBar/Back-Button,
    // transparenter Hintergrund + schlanker Titel-Header.
    if (widget.embedded) {
      return Column(
        children: [
          _buildEmbeddedHeader(),
          _buildSearchBar(),
          if (_chips.isNotEmpty) _buildCategoryChips(),
          Expanded(child: _isLoading ? _buildSpinner() : _buildGrid()),
        ],
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mediathek',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _primary.withValues(alpha: 0.2)),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_chips.isNotEmpty) _buildCategoryChips(),
          Expanded(child: _isLoading ? _buildSpinner() : _buildGrid()),
        ],
      ),
    );
  }

  // Schlanker Header fuer den eingebetteten Welt-Tab (statt AppBar).
  Widget _buildEmbeddedHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [BoxShadow(color: _primary, blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Videos',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w300,
              fontSize: 26,
              letterSpacing: 2,
              shadows: [
                Shadow(color: _primary.withValues(alpha: 0.4), blurRadius: 20),
              ],
            ),
          ),
          const Spacer(),
          Icon(Icons.play_circle_outline_rounded,
              color: _primary.withValues(alpha: 0.6), size: 22),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _primary.withValues(alpha: 0.2)),
        ),
        child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Videos durchsuchen …',
            hintStyle:
                TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            prefixIcon:
                Icon(Icons.search_rounded, color: _primarySoft, size: 18),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.5), size: 16),
                    onPressed: () {
                      _searchCtrl.clear();
                      _applyFilter();
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        children: [
          _chip(null, '🎞️', 'Alle'),
          ..._chips.map((c) => _chip(c.label, c.emoji, c.label)),
        ],
      ),
    );
  }

  Widget _chip(String? value, String? emoji, String label) {
    final selected = _activeCategory == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _activeCategory = value);
        _applyFilter();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? _primary.withValues(alpha: 0.2)
              : const Color(0xFF111827),
          border: Border.all(
            color: selected ? _primary : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? _primarySoft : Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_rounded,
                size: 48, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(
              'Keine Videos gefunden',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _VideoCard(
        video: _filtered[i],
        primary: _primary,
        primarySoft: _primarySoft,
        onTap: () => _openPlayer(_filtered[i]),
      ),
    );
  }

  Widget _buildSpinner() => Center(
        child: CircularProgressIndicator(color: _primary, strokeWidth: 2),
      );
}

// ── Video card ────────────────────────────────────────────────────────────────

class _VideoCard extends StatelessWidget {
  final ArchiveVideo video;
  final Color primary;
  final Color primarySoft;
  final VoidCallback onTap;

  const _VideoCard({
    required this.video,
    required this.primary,
    required this.primarySoft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF0B0D1A),
          border: Border.all(color: primary.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
                color: primary.withValues(alpha: 0.08), blurRadius: 12),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: video.effectiveThumbnail,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFF111827),
                        child: Icon(Icons.play_circle_outline_rounded,
                            size: 40,
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                    ),
                    // Play button overlay
                    Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.55),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.6)),
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                    // Category chip
                    if (video.category != null)
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            video.category!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Title
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Text(
                    video.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Inline YouTube player screen ──────────────────────────────────────────────

class _VideoPlayerScreen extends StatefulWidget {
  final ArchiveVideo video;
  final Color primary;

  const _VideoPlayerScreen({required this.video, required this.primary});

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  late YoutubePlayerController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = YoutubePlayerController(
      initialVideoId: widget.video.youtubeVideoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _ctrl,
        showVideoProgressIndicator: true,
        progressIndicatorColor: widget.primary,
      ),
      builder: (context, player) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: widget.primary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.video.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600),
          ),
        ),
        body: Column(
          children: [
            player,
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                  widget.video.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
