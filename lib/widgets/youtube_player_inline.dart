import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/youtube_service.dart';

/// Inline YouTube-Player via WebView-Embed (kein externes Package nötig)
class YoutubePlayerInline extends StatefulWidget {
  final YoutubeVideo video;
  final VoidCallback? onClose;

  const YoutubePlayerInline({super.key, required this.video, this.onClose});

  @override
  State<YoutubePlayerInline> createState() => _YoutubePlayerInlineState();
}

class _YoutubePlayerInlineState extends State<YoutubePlayerInline> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
      ))
      ..loadRequest(Uri.parse(widget.video.embedUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title bar
          Container(
            color: const Color(0xFF1A0000),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.play_circle_fill, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.video.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.onClose != null)
                  GestureDetector(
                    onTap: widget.onClose,
                    child: const Icon(Icons.close, color: Colors.white54, size: 18),
                  ),
              ],
            ),
          ),
          // Player
          SizedBox(
            height: 210,
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_loading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
                  ),
              ],
            ),
          ),
          // Channel info
          Container(
            color: const Color(0xFF0D0000),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.person_outline, color: Colors.white38, size: 13),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.video.channel,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
