import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/ursprung_research_sites.dart';
import '../../models/favorite.dart';
import '../../services/favorites_service.dart';
import '../../services/youtube_service.dart';
import '../../services/wikimedia_service.dart';
import '../../utils/map_clustering_helper.dart';
import '../../widgets/wb_cached_image.dart';
import '../../widgets/youtube_player_inline.dart';

class UrsprungMapTab extends StatefulWidget {
  const UrsprungMapTab({super.key});

  @override
  State<UrsprungMapTab> createState() => _UrsprungMapTabState();
}

typedef _ResearchSite = ResearchSite;

const _sites = allUrsprungSites;

class _UrsprungMapTabState extends State<UrsprungMapTab>
    with TickerProviderStateMixin {
  static const _cyan = Color(0xFF00D4AA);
  static const _bg = Color(0xFF050510);
  static const _surface = Color(0xFF080818);

  final _mapController = MapController();
  _ResearchSite? _selected;
  String _categoryFilter = 'all';
  bool _headerCollapsed = false;

  late AnimationController _panelCtrl;
  late Animation<Offset> _panelSlide;

  List<YoutubeVideo>? _ytVideos;
  bool _ytLoading = false;
  YoutubeVideo? _ytPlaying;
  String _ytLocationName = '';
  List<String> _wikiImages = const [];
  bool _wikiLoading = false;
  String _wikiLocationName = '';
  int _detailTabIndex = 0;

  static const Map<String, ({String label, String emoji})> _categories = {
    'all': (label: 'Alle', emoji: '🌐'),
    'consciousness': (label: 'Bewusstsein', emoji: '🧠'),
    'rv': (label: 'Remote Viewing', emoji: '👁️'),
    'ufo': (label: 'UFO/Anomalien', emoji: '🛸'),
    'archaeology': (label: 'Archäologie', emoji: '🏛️'),
    'tradition': (label: 'Traditionen', emoji: '📜'),
    'cymatics': (label: 'Kymatik', emoji: '🌊'),
  };

  static Color _accentFor(String cat) {
    switch (cat) {
      case 'rv':
        return const Color(0xFFAB47BC);
      case 'ufo':
        return const Color(0xFF42A5F5);
      case 'archaeology':
        return const Color(0xFF8D6E63);
      case 'tradition':
        return const Color(0xFFFFCA28);
      case 'cymatics':
        return const Color(0xFF26C6DA);
      default:
        return _cyan;
    }
  }

  static IconData _iconFor(String cat) {
    switch (cat) {
      case 'rv':
        return Icons.remove_red_eye;
      case 'ufo':
        return Icons.flight;
      case 'archaeology':
        return Icons.account_balance;
      case 'tradition':
        return Icons.local_fire_department;
      case 'cymatics':
        return Icons.graphic_eq;
      default:
        return Icons.psychology;
    }
  }

  List<_ResearchSite> get _visibleSites {
    if (_categoryFilter == 'all') return _sites;
    return _sites.where((s) => s.category == _categoryFilter).toList();
  }

  @override
  void initState() {
    super.initState();
    _panelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _panelSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _panelCtrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _panelCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadYoutube(String name) async {
    if (_ytLocationName == name) return;
    if (!mounted) return;
    setState(() {
      _ytLoading = true;
      _ytLocationName = name;
    });
    final videos =
        await YoutubeService.instance.searchVideos('$name deutsch', max: 5);
    if (!mounted) return;
    setState(() {
      _ytVideos = videos;
      _ytLoading = false;
    });
  }

  Future<void> _loadWikimedia(String name) async {
    if (_wikiLocationName == name) return;
    if (!mounted) return;
    setState(() {
      _wikiLoading = true;
      _wikiLocationName = name;
    });
    final images = await WikimediaService.instance.searchImages(name);
    if (!mounted) return;
    setState(() {
      _wikiImages = images;
      _wikiLoading = false;
    });
  }

  void _select(_ResearchSite s) {
    setState(() {
      _selected = s;
      _detailTabIndex = 0;
      _ytVideos = null;
      _ytPlaying = null;
      _ytLocationName = '';
      _wikiImages = const [];
      _wikiLocationName = '';
      _headerCollapsed = true;
    });
    _panelCtrl.forward(from: 0);
    _mapController.move(LatLng(s.lat, s.lng), 5.5);
    _loadYoutube(s.name);
    _loadWikimedia(s.name);
  }

  void _deselect() {
    _panelCtrl.reverse().then((_) {
      if (mounted) setState(() => _selected = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(42.0, -90.0),
            initialZoom: 3.2,
            minZoom: 2.0,
            maxZoom: 14.0,
            backgroundColor: _bg,
            onPositionChanged: (_, hasGesture) {
              if (hasGesture && !_headerCollapsed) {
                setState(() => _headerCollapsed = true);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.myapp.mobile',
            ),
            MapClusteringHelper.createClusterLayer(
              markers: _visibleSites.map((s) {
                final sel = _selected?.name == s.name;
                return Marker(
                  point: LatLng(s.lat, s.lng),
                  width: 52,
                  height: 52,
                  child: GestureDetector(
                    onTap: () => _select(s),
                    child: _PulsingMarker(
                      color: _accentFor(s.category),
                      icon: _iconFor(s.category),
                      isSelected: sel,
                    ),
                  ),
                );
              }).toList(),
              clusterColor: _cyan.withValues(alpha: 0.85),
              maxClusterRadius:
                  MapClusteringHelper.calculateOptimalClusterRadius(
                _visibleSites.length,
              ),
            ),
          ],
        ),

        // Header
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _headerCollapsed
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: _buildFullHeader(),
            secondChild: _buildCollapsedHeader(),
          ),
        ),

        // Sliding detail panel
        if (_selected != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _panelSlide,
              child: _buildDetailPanel(_selected!, screenH),
            ),
          ),
      ],
    );
  }

  Widget _buildFullHeader() {
    return Container(
      color: _bg.withValues(alpha: 0.85),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BEWUSSTSEINSZENTREN',
            style: TextStyle(
                color: _cyan,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 3),
          ),
          Text(
            '${_visibleSites.length} von ${_sites.length} Standorten · Marker antippen',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _categories.entries.map((e) {
                final active = _categoryFilter == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _categoryFilter = e.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: active
                            ? _cyan.withValues(alpha: 0.9)
                            : _cyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: active
                              ? _cyan
                              : _cyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(e.value.emoji,
                              style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 5),
                          Text(
                            e.value.label,
                            style: TextStyle(
                              color: active ? Colors.black : Colors.white70,
                              fontSize: 12,
                              fontWeight: active
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedHeader() {
    return Container(
      color: _bg.withValues(alpha: 0.78),
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_visibleSites.length} Bewusstseinszentren',
              style: const TextStyle(
                  color: _cyan, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _headerCollapsed = false),
            child: const Icon(Icons.expand_more, color: _cyan, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel(_ResearchSite s, double screenH) {
    final accent = _accentFor(s.category);
    return SizedBox(
      height: screenH * 0.60,
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.28),
              blurRadius: 22,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 10),
                decoration: BoxDecoration(
                  color: _cyan.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: accent.withValues(alpha: 0.5)),
                    ),
                    child:
                        Icon(_iconFor(s.category), color: accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          s.badge,
                          style: TextStyle(color: accent, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Bookmark
                  Builder(builder: (ctx) {
                    final favId = 'map_ursprung_${s.name}';
                    final isSaved = FavoritesService.isFavorite(favId);
                    return IconButton(
                      tooltip: isSaved
                          ? 'Aus Favoriten entfernen'
                          : 'Ort speichern',
                      icon: Icon(
                        isSaved
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: accent,
                      ),
                      onPressed: () async {
                        if (isSaved) {
                          await FavoritesService.deleteFavorite(favId);
                        } else {
                          await FavoritesService.addFavorite(Favorite(
                            id: favId,
                            type: FavoriteType.source,
                            title: s.name,
                            description: s.description,
                            url: s.imageUrl,
                            createdAt: DateTime.now(),
                            metadata: {
                              'lat': s.lat,
                              'lng': s.lng,
                              'category': s.category,
                              'world': 'ursprung',
                            },
                          ));
                        }
                        if (!ctx.mounted) return;
                        setState(() {});
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          duration: const Duration(seconds: 2),
                          content: Text(isSaved
                              ? 'Ort aus Favoriten entfernt'
                              : '${s.name} gespeichert'),
                        ));
                      },
                    );
                  }),
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white54),
                    onPressed: _deselect,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Tab chips
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  _tabChip('Überblick', 0, accent),
                  const SizedBox(width: 8),
                  _tabChip('Bilder', 1, accent),
                  const SizedBox(width: 8),
                  _tabChip('Videos', 2, accent),
                ],
              ),
            ),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                child: _detailTabIndex == 0
                    ? _buildOverviewTab(s, accent)
                    : _detailTabIndex == 1
                        ? _buildImagesTab(accent)
                        : _buildVideosTab(accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabChip(String label, int index, Color accent) {
    final active = _detailTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _detailTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? accent.withValues(alpha: 0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? accent : Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? accent : Colors.white54,
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(_ResearchSite s, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (s.imageUrl != null) ...[
          WbCachedImage(
            s.imageUrl!,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(12),
            errorWidget: Container(
              height: 160,
              color: Colors.white.withValues(alpha: 0.04),
              alignment: Alignment.center,
              child: Icon(s.icon,
                  color: accent.withValues(alpha: 0.5), size: 40),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.5)),
              ),
              child: Text(s.badge,
                  style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: s.status.startsWith('Aktiv')
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                s.status,
                style: TextStyle(
                    color: s.status.startsWith('Aktiv')
                        ? Colors.greenAccent
                        : Colors.orange,
                    fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(s.founded,
            style: TextStyle(
                color: accent.withValues(alpha: 0.7),
                fontSize: 12,
                fontStyle: FontStyle.italic)),
        const SizedBox(height: 10),
        Text(s.description,
            style: const TextStyle(
                color: Colors.white70, fontSize: 14, height: 1.55)),
        if (s.findings.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Schlüsselergebnisse',
              style: TextStyle(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...s.findings.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ',
                        style: TextStyle(color: accent, fontSize: 14)),
                    Expanded(
                      child: Text(f,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 13,
                              height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
        if (s.researchers.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('Forscher',
              style: TextStyle(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: s.researchers
                .map((r) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: accent.withValues(alpha: 0.3)),
                      ),
                      child: Text(r,
                          style:
                              TextStyle(color: accent, fontSize: 12)),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildImagesTab(Color accent) {
    if (_wikiLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: CircularProgressIndicator(color: accent),
        ),
      );
    }
    if (_wikiImages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text('Keine Bilder gefunden',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4))),
        ),
      );
    }
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.3,
      ),
      itemCount: _wikiImages.length,
      itemBuilder: (_, i) => WbCachedImage(
        _wikiImages[i],
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildVideosTab(Color accent) {
    if (_ytLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: CircularProgressIndicator(color: accent),
        ),
      );
    }
    if (_ytVideos == null || _ytVideos!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text('Keine Videos gefunden',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4))),
        ),
      );
    }
    return Column(
      children: _ytVideos!.map((v) {
        final playing = _ytPlaying?.videoId == v.videoId;
        return playing
            ? YoutubePlayerInline(
                video: v,
                onClose: () => setState(() => _ytPlaying = null),
              )
            : ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 4),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: WbCachedImage(v.thumbnail,
                      width: 80, height: 54, fit: BoxFit.cover),
                ),
                title: Text(v.title,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                trailing:
                    Icon(Icons.play_circle_outline, color: accent),
                onTap: () => setState(() => _ytPlaying = v),
              );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Pulsing animated marker — matches Materie/Energie style
// ---------------------------------------------------------------------------
class _PulsingMarker extends StatefulWidget {
  final Color color;
  final IconData icon;
  final bool isSelected;

  const _PulsingMarker({
    required this.color,
    required this.icon,
    required this.isSelected,
  });

  @override
  State<_PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<_PulsingMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.0, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final glow = 0.2 + 0.25 * _anim.value;
        final blur = 10.0 + 8.0 * _anim.value;
        return Transform.scale(
          scale: widget.isSelected ? 1.35 : 1.0,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: glow),
                  blurRadius: blur,
                  spreadRadius: widget.isSelected ? 4 : 2,
                ),
              ],
            ),
            child: Icon(widget.icon, color: Colors.white, size: 20),
          ),
        );
      },
    );
  }
}
