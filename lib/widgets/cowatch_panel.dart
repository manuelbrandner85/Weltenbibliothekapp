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

// ── Eingabe-Dialog ────────────────────────────────────────────────────────────

/// Zeigt einen Dialog zur YouTube-URL-Eingabe.
/// Gibt die eingegebene URL zurück oder null wenn abgebrochen.
Future<String?> showCoWatchInputDialog(
    BuildContext context, String world) async {
  final ctrl = TextEditingController();
  final accent = WbDesign.accent(world);
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: AlertDialog(
        backgroundColor: WbDesign.surface(world),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WbDesign.radiusLarge),
          side: BorderSide(color: accent.withValues(alpha: 0.3)),
        ),
        title: Row(
          children: [
            Icon(Icons.play_circle_rounded, color: accent, size: 22),
            const SizedBox(width: 10),
            const Text(
              'Co-Watch starten',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YouTube-Link oder Video-ID eingeben.\nAlle Teilnehmer sehen das Video gleichzeitig.',
              style: TextStyle(
                color: WbDesign.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'https://youtu.be/...',
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
                      BorderSide(color: accent.withValues(alpha: 0.5)),
                ),
                prefixIcon:
                    Icon(Icons.link_rounded, color: accent, size: 18),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) Navigator.pop(ctx, v.trim());
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Abbrechen',
                style: TextStyle(color: WbDesign.textTertiary)),
          ),
          FilledButton.icon(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isNotEmpty) Navigator.pop(ctx, v);
            },
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Starten'),
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(WbDesign.radiusMedium),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
