import 'package:flutter/material.dart';
import '../../../../services/youtube_service.dart';
import '../../../../widgets/youtube_player_inline.dart';

class YoutubeCard extends StatefulWidget {
  final String topic;
  final Color accentColor;

  const YoutubeCard({
    super.key,
    required this.topic,
    this.accentColor = Colors.red,
  });

  @override
  State<YoutubeCard> createState() => _YoutubeCardState();
}

class _YoutubeCardState extends State<YoutubeCard> {
  List<YoutubeVideo>? _videos;
  bool _loading = true;
  YoutubeVideo? _playing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(YoutubeCard old) {
    super.didUpdateWidget(old);
    if (old.topic != widget.topic) {
      setState(() {
        _videos = null;
        _loading = true;
        _playing = null;
      });
      _load();
    }
  }

  Future<void> _load() async {
    final results = await YoutubeService.instance
        .searchVideos('${widget.topic} deutsch', max: 6);
    if (!mounted) return;
    setState(() {
      _videos = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A0000),
            widget.accentColor.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.play_circle_fill, color: Colors.red, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('YouTube Videos',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      Text('Deutsche Quellen zum Thema',
                          style: TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                if (_loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.red, strokeWidth: 1.5),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Inline Player
          if (_playing != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: YoutubePlayerInline(
                video: _playing!,
                onClose: () => setState(() => _playing = null),
              ),
            ),

          if (_playing != null) const SizedBox(height: 12),

          // Video-Liste
          if (_loading)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: _SkeletonList(),
            )
          else if (_videos == null || _videos!.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Text(
                'Keine deutschen Videos gefunden. YouTube API Key nötig.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
              child: SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _videos!.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => _VideoTile(
                    video: _videos![i],
                    playing: _playing?.videoId == _videos![i].videoId,
                    onTap: () => setState(() {
                      _playing = _playing?.videoId == _videos![i].videoId
                          ? null
                          : _videos![i];
                    }),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  final YoutubeVideo video;
  final bool playing;
  final VoidCallback onTap;

  const _VideoTile({
      required this.video, required this.playing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: playing
                ? Colors.red
                : Colors.white.withValues(alpha: 0.1),
            width: playing ? 2 : 1,
          ),
          color: const Color(0xFF1A1A1A),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  video.thumbnail.isNotEmpty ? video.thumbnail : video.fallbackThumbnail,
                  height: 90,
                  width: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 90,
                    color: Colors.white.withValues(alpha: 0.05),
                    child: const Center(
                        child: Icon(Icons.videocam_off, color: Colors.white24)),
                  ),
                ),
                if (playing)
                  Container(
                    height: 90,
                    width: 160,
                    color: Colors.black54,
                    child: const Center(
                      child: Icon(Icons.stop_circle,
                          color: Colors.red, size: 36),
                    ),
                  )
                else
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(Icons.play_circle_fill,
                            color: Colors.red, size: 36),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      video.channel,
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 9),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (_) => Container(
          width: 160,
          height: 130,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ),
    );
  }
}
