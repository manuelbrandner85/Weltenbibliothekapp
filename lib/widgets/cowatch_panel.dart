/// 📺 B10.4 — Co-Watch Panel
///
/// Zeigt ein synchronisiertes YouTube-Video für alle Call-Teilnehmer.
/// Der Host steuert Play/Pause/Seek via DataChannel.
/// Alle anderen Teilnehmer empfangen Sync-Events und folgen automatisch.
library;

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../config/wb_design.dart';
import '../services/cowatch_service.dart';
import '../services/youtube_service.dart';

class CoWatchPanel extends StatefulWidget {
  final String videoId;
  final String world;
  final bool isHost;
  final CoWatchService service;
  final VoidCallback onClose;

  const CoWatchPanel({
    super.key,
    required this.videoId,
    required this.world,
    required this.isHost,
    required this.service,
    required this.onClose,
  });

  @override
  State<CoWatchPanel> createState() => _CoWatchPanelState();
}

class _CoWatchPanelState extends State<CoWatchPanel> {
  late final WebViewController _controller;
  StreamSubscription<CoWatchEvent>? _sub;
  bool _webViewReady = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _sub = widget.service.eventStream.listen(_onEvent);
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'CoWatchBridge',
        onMessageReceived: _onJsMessage,
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _webViewReady = true);
        },
      ))
      ..loadHtmlString(_buildHtml(widget.videoId));
  }

  void _onJsMessage(JavaScriptMessage msg) {
    if (!widget.isHost) return;
    // Host broadcastet Zustandsänderungen an alle
    try {
      final parts = msg.message.split(':');
      if (parts.length < 2) return;
      final event = parts[0];
      final position = double.tryParse(parts[1]) ?? 0.0;
      if (event == 'play') widget.service.broadcastPlay(position);
      if (event == 'pause') widget.service.broadcastPause(position);
      if (event == 'seek') widget.service.broadcastSeek(position);
    } catch (_) {}
  }

  void _onEvent(CoWatchEvent event) {
    if (!_webViewReady) return;
    if (event.fromIdentity == widget.service.currentVideoId) return;
    switch (event.action) {
      case CoWatchAction.play:
        _js('seekAndPlay(${event.position ?? 0});');
      case CoWatchAction.pause:
        _js('seekAndPause(${event.position ?? 0});');
      case CoWatchAction.seek:
        _js('seekTo(${event.position ?? 0});');
      case CoWatchAction.close:
        widget.onClose();
      default:
        break;
    }
  }

  void _js(String script) {
    _controller.runJavaScript(script);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = WbDesign.accent(widget.world);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: accent.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            children: [
              // TopBar mit Titel + Schließen-Button
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: WbDesign.surface(widget.world).withValues(alpha: 0.9),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.play_circle_rounded,
                        color: accent, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Co-Watch',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.isHost) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'HOST',
                          style: TextStyle(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white54, size: 20),
                      onPressed: () {
                        if (widget.isHost) widget.service.closeVideo();
                        widget.onClose();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // YouTube WebView
              Expanded(
                child: Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    if (!_webViewReady)
                      const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white54),
                      ),
                    if (!widget.isHost)
                      // Overlay-Hinweis für Nicht-Host
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Steuerung liegt beim Host',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildHtml(String videoId) => '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { background: #000; width: 100vw; height: 100vh; overflow: hidden; }
    #player { width: 100%; height: 100%; }
  </style>
</head>
<body>
  <div id="player"></div>
  <script>
    var tag = document.createElement('script');
    tag.src = "https://www.youtube.com/iframe_api";
    document.head.appendChild(tag);

    var player;
    var isReady = false;
    var pendingSeek = null;

    function onYouTubeIframeAPIReady() {
      player = new YT.Player('player', {
        videoId: '$videoId',
        playerVars: {
          'autoplay': 0,
          'controls': 1,
          'rel': 0,
          'modestbranding': 1,
          'playsinline': 1
        },
        events: {
          'onReady': function(e) {
            isReady = true;
            if (pendingSeek !== null) { seekTo(pendingSeek); pendingSeek = null; }
          },
          'onStateChange': function(e) {
            var t = player.getCurrentTime();
            if (e.data === YT.PlayerState.PLAYING) {
              CoWatchBridge.postMessage('play:' + t);
            } else if (e.data === YT.PlayerState.PAUSED) {
              CoWatchBridge.postMessage('pause:' + t);
            }
          }
        }
      });
    }

    function seekAndPlay(secs) {
      if (!isReady) { pendingSeek = secs; return; }
      player.seekTo(secs, true);
      player.playVideo();
    }
    function seekAndPause(secs) {
      if (!isReady) return;
      player.seekTo(secs, true);
      player.pauseVideo();
    }
    function seekTo(secs) {
      if (!isReady) { pendingSeek = secs; return; }
      player.seekTo(secs, true);
    }
  </script>
</body>
</html>
''';
}

// ── Eingabe-Dialog (URL ODER Thema-Suche) ───────────────────────────────────

/// Zeigt einen Dialog für Co-Watch:
/// - Plain Text (z.B. „WEF 2024") → YouTube-Suche, Tap auf Ergebnis startet Co-Watch
/// - URL/Video-ID → direkt starten
///
/// Der LiveKit-Call wird NIE unterbrochen — Dialog ist Overlay, Co-Watch danach
/// ebenfalls Overlay-Panel (Stack).
Future<String?> showCoWatchInputDialog(
    BuildContext context, String world) async {
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (ctx) => _CoWatchPickerDialog(world: world),
  );
}

bool _looksLikeYoutubeUrlOrId(String input) {
  final s = input.trim();
  if (s.isEmpty) return false;
  // 11-stellige Video-ID
  if (RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(s)) return true;
  // youtube.com / youtu.be Links
  if (s.contains('youtube.com/') || s.contains('youtu.be/')) return true;
  return false;
}

class _CoWatchPickerDialog extends StatefulWidget {
  final String world;
  const _CoWatchPickerDialog({required this.world});

  @override
  State<_CoWatchPickerDialog> createState() => _CoWatchPickerDialogState();
}

class _CoWatchPickerDialogState extends State<_CoWatchPickerDialog> {
  final _ctrl = TextEditingController();
  List<YoutubeVideo>? _results;
  bool _searching = false;
  String _lastQuery = '';

  Color get _accent => WbDesign.accent(widget.world);

  Future<void> _search() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty || q == _lastQuery) return;
    setState(() {
      _searching = true;
      _lastQuery = q;
    });
    final res = await YoutubeService.instance.searchVideos(q, max: 8);
    if (!mounted) return;
    setState(() {
      _results = res;
      _searching = false;
    });
  }

  void _submit() {
    final v = _ctrl.text.trim();
    if (v.isEmpty) return;
    if (_looksLikeYoutubeUrlOrId(v)) {
      Navigator.pop(context, v);
    } else {
      _search();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrl = _looksLikeYoutubeUrlOrId(_ctrl.text);
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: WbDesign.surface(widget.world),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WbDesign.radiusLarge),
          side: BorderSide(color: _accent.withValues(alpha: 0.3)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.play_circle_rounded, color: _accent, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Co-Watch starten',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white54, size: 22),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'YouTube-Link einfügen ODER Thema eingeben (z.B. „WEF 2024"). Der Stream läuft weiter.',
                  style: TextStyle(
                    color: WbDesign.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                // Eingabefeld
                TextField(
                  controller: _ctrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'youtu.be/... oder „Mondlandung"',
                    hintStyle: TextStyle(color: WbDesign.textTertiary),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.07),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(WbDesign.radiusMedium),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(WbDesign.radiusMedium),
                      borderSide:
                          BorderSide(color: _accent.withValues(alpha: 0.5)),
                    ),
                    prefixIcon: Icon(
                      isUrl ? Icons.link_rounded : Icons.search_rounded,
                      color: _accent,
                      size: 18,
                    ),
                    suffixIcon: _ctrl.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear,
                                color: Colors.white38, size: 16),
                            onPressed: () => setState(() {
                              _ctrl.clear();
                              _results = null;
                              _lastQuery = '';
                            }),
                          ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),

                const SizedBox(height: 12),

                // Aktion: Starten (URL) oder Suchen (Thema)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _ctrl.text.trim().isEmpty ? null : _submit,
                        icon: Icon(
                          isUrl
                              ? Icons.play_arrow_rounded
                              : Icons.search_rounded,
                          size: 18,
                        ),
                        label: Text(isUrl ? 'Starten' : 'Videos suchen'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(WbDesign.radiusMedium),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Ergebnis-Liste
                if (_searching)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                              color: _accent, strokeWidth: 2),
                          const SizedBox(height: 10),
                          Text(
                            'Suche YouTube…',
                            style: TextStyle(
                                color: WbDesign.textTertiary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_results != null && _results!.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Keine Videos gefunden. YouTube API Key nötig oder anderes Thema versuchen.',
                      style: TextStyle(
                          color: WbDesign.textTertiary, fontSize: 12),
                    ),
                  )
                else if (_results != null && _results!.isNotEmpty)
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _results!.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final v = _results![i];
                        return _SearchResultTile(
                          video: v,
                          accent: _accent,
                          onTap: () => Navigator.pop(context, v.videoId),
                        );
                      },
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

class _SearchResultTile extends StatelessWidget {
  final YoutubeVideo video;
  final Color accent;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.video,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  Image.network(
                    video.thumbnail.isNotEmpty
                        ? video.thumbnail
                        : video.fallbackThumbnail,
                    width: 90,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 90,
                      height: 56,
                      color: Colors.white.withValues(alpha: 0.05),
                      child: const Icon(Icons.videocam_off,
                          color: Colors.white24, size: 20),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Icon(Icons.play_circle_fill,
                          color: accent, size: 24),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.channel,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.play_arrow_rounded, color: accent, size: 20),
          ],
        ),
      ),
    );
  }
}
