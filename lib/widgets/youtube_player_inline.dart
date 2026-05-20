import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/youtube_service.dart';
import '_youtube_web_iframe_stub.dart'
    if (dart.library.html) '_youtube_web_iframe_web.dart';

/// Inline YouTube-Player via WebView. Fängt Error 153 (Embedding-Sperre)
/// per YT-IFrame-API ab und zeigt Fallback-Thumbnail + Button der intern in m.youtube.com öffnet.
class YoutubePlayerInline extends StatefulWidget {
  final YoutubeVideo video;
  final VoidCallback? onClose;

  const YoutubePlayerInline({super.key, required this.video, this.onClose});

  @override
  State<YoutubePlayerInline> createState() => _YoutubePlayerInlineState();
}

class _YoutubePlayerInlineState extends State<YoutubePlayerInline> {
  WebViewController? _controller;
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Auf Web nutzen wir ein natives <iframe> via HtmlElementView.
    // webview_flutter hat keine Web-Implementierung → würde nur grau bleiben.
    if (kIsWeb) {
      _loading = false;
      return;
    }
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'YtError',
        onMessageReceived: (_) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _loading = false;
            });
          }
        },
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onWebResourceError: (_) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _loading = false;
            });
          }
        },
        onNavigationRequest: (request) {
          final u = request.url;
          // YouTube-Links (inkl. Fallback-Button) intern im WebView abspielen
          if (u.contains('youtube.com') || u.contains('youtu.be/')) {
            return NavigationDecision.navigate;
          }
          if (u.startsWith('about:') ||
              u.startsWith('data:') ||
              u.contains('googleapis.com')) {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
      ))
      ..loadHtmlString(_buildHtml(widget.video.videoId));
  }

  String _buildHtml(String videoId) => '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<style>
* { margin:0; padding:0; box-sizing:border-box; }
body { background:#000; overflow:hidden; }
#wrap { position:relative; width:100vw; padding-bottom:56.25%; }
#wrap > div { position:absolute; top:0; left:0; width:100%; height:100%; }
#fallback { display:none; background:#111; flex-direction:column; align-items:center; justify-content:center; }
#fallback.show { display:flex; }
#thumb { width:90%; border-radius:10px; max-height:160px; object-fit:cover; }
#btn { margin-top:14px; background:#f00; color:#fff; padding:11px 22px;
       border-radius:22px; border:none; cursor:pointer; font:bold 15px/1 sans-serif; }
</style>
</head>
<body>
<div id="wrap">
  <div id="yt-player"></div>
  <div id="fallback">
    <img id="thumb" src="https://img.youtube.com/vi/$videoId/mqdefault.jpg">
    <button id="btn" onclick="window.location.href='https://m.youtube.com/watch?v=$videoId'">&#9654; Video abspielen</button>
  </div>
</div>
<script>
function onYouTubeIframeAPIReady() {
  new YT.Player('yt-player', {
    videoId: '$videoId',
    playerVars: { autoplay:1, hl:'de', rel:0, playsinline:1, modestbranding:1 },
    events: {
      onError: function(e) {
        document.getElementById('yt-player').style.display = 'none';
        document.getElementById('fallback').className = 'show';
        if (window.YtError) YtError.postMessage(String(e.data));
      }
    }
  });
}
</script>
<script src="https://www.youtube.com/iframe_api"></script>
</body>
</html>
''';

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
              spreadRadius: 2),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: const Color(0xFF1A0000),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.play_circle_fill, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.video.title.isNotEmpty
                        ? widget.video.title
                        : 'Video',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.onClose != null)
                  GestureDetector(
                    onTap: widget.onClose,
                    child: const Icon(Icons.close,
                        color: Colors.white54, size: 18),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 210,
            child: kIsWeb
                ? buildYoutubeIframe(widget.video.videoId)
                : Stack(
                    children: [
                      if (_controller != null)
                        WebViewWidget(controller: _controller!),
                      if (_loading && !_hasError)
                        const Center(
                          child: CircularProgressIndicator(
                              color: Colors.red, strokeWidth: 2),
                        ),
                    ],
                  ),
          ),
          Container(
            color: const Color(0xFF0D0000),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.person_outline,
                    color: Colors.white38, size: 13),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.video.channel.isNotEmpty
                        ? widget.video.channel
                        : 'YouTube',
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
