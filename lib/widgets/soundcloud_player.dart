import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 🎵 SoundCloud Player Widget
///
/// Integriert SoundCloud-Tracks in die App via WebView
/// 
/// Features:
/// - Embed SoundCloud Tracks/Playlists
/// - Compact Player für Chat-Integration
/// - Fullscreen Player für Details
/// - Auto-Play Support
/// - Volume Control Integration
class SoundCloudPlayer extends StatefulWidget {
  final String trackUrl; // z.B. 'https://soundcloud.com/artist/track'
  final bool autoPlay;
  final bool showArtwork;
  final Color? accentColor;
  final double height;

  const SoundCloudPlayer({
    super.key,
    required this.trackUrl,
    this.autoPlay = false,
    this.showArtwork = true,
    this.accentColor,
    this.height = 166,
  });

  @override
  State<SoundCloudPlayer> createState() => _SoundCloudPlayerState();
}

class _SoundCloudPlayerState extends State<SoundCloudPlayer> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    // SoundCloud Embed URL erstellen
    final embedUrl = _buildEmbedUrl(widget.trackUrl);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1E293B))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('SoundCloud Player Error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(embedUrl));
  }

  /// Erstellt SoundCloud Embed URL mit Parametern
  String _buildEmbedUrl(String trackUrl) {
    // SoundCloud Widget API
    // Docs: https://developers.soundcloud.com/docs/api/html5-widget
    
    final encodedUrl = Uri.encodeComponent(trackUrl);
    final color = widget.accentColor != null
        ? widget.accentColor!.value.toRadixString(16).substring(2)
        : '8B5CF6'; // Default: Primary Violet
    
    return 'https://w.soundcloud.com/player/?'
        'url=$encodedUrl'
        '&color=%23$color'
        '&auto_play=${widget.autoPlay}'
        '&hide_related=true'
        '&show_comments=false'
        '&show_user=true'
        '&show_reposts=false'
        '&show_teaser=false'
        '&visual=${widget.showArtwork}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: const Color(0xFF1E293B),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 🎵 SoundCloud Compact Player
/// 
/// Minimale Version für Chat-Integration (nur Waveform)
class SoundCloudCompactPlayer extends StatelessWidget {
  final String trackUrl;
  final bool autoPlay;

  const SoundCloudCompactPlayer({
    super.key,
    required this.trackUrl,
    this.autoPlay = false,
  });

  @override
  Widget build(BuildContext context) {
    return SoundCloudPlayer(
      trackUrl: trackUrl,
      autoPlay: autoPlay,
      showArtwork: false,
      height: 120, // Kompakter
      accentColor: const Color(0xFF8B5CF6),
    );
  }
}

/// 🎨 SoundCloud Visual Player
/// 
/// Vollständiger Player mit Artwork für dedizierte Musik-Screens
class SoundCloudVisualPlayer extends StatelessWidget {
  final String trackUrl;
  final bool autoPlay;

  const SoundCloudVisualPlayer({
    super.key,
    required this.trackUrl,
    this.autoPlay = true,
  });

  @override
  Widget build(BuildContext context) {
    return SoundCloudPlayer(
      trackUrl: trackUrl,
      autoPlay: autoPlay,
      showArtwork: true,
      height: 400, // Größer für visuelle Darstellung
      accentColor: const Color(0xFFFFD700), // Gold Accent
    );
  }
}

/// 📋 SoundCloud Playlist Player
/// 
/// Für SoundCloud Sets/Playlists
class SoundCloudPlaylistPlayer extends StatelessWidget {
  final String playlistUrl; // z.B. 'https://soundcloud.com/artist/sets/playlist'
  final bool autoPlay;

  const SoundCloudPlaylistPlayer({
    super.key,
    required this.playlistUrl,
    this.autoPlay = false,
  });

  @override
  Widget build(BuildContext context) {
    return SoundCloudPlayer(
      trackUrl: playlistUrl,
      autoPlay: autoPlay,
      showArtwork: true,
      height: 450, // Höher für Playlist
      accentColor: const Color(0xFF8B5CF6),
    );
  }
}

/// 🔗 SoundCloud Helper
/// 
/// Utility-Funktionen für SoundCloud-URLs
class SoundCloudHelper {
  /// Validiere SoundCloud URL
  static bool isValidSoundCloudUrl(String url) {
    return url.contains('soundcloud.com') &&
        (url.contains('/tracks/') || 
         url.contains('/sets/') ||
         RegExp(r'soundcloud\.com/[\w-]+/[\w-]+').hasMatch(url));
  }

  /// Extrahiere Track-ID aus URL (falls benötigt)
  static String? extractTrackId(String url) {
    final match = RegExp(r'/tracks/(\d+)').firstMatch(url);
    return match?.group(1);
  }

  /// Baue direkten Track-Link
  static String buildTrackUrl(String username, String trackSlug) {
    return 'https://soundcloud.com/$username/$trackSlug';
  }

  /// Baue Playlist-Link
  static String buildPlaylistUrl(String username, String playlistSlug) {
    return 'https://soundcloud.com/$username/sets/$playlistSlug';
  }

  /// Öffne in SoundCloud App (wenn installiert)
  static Future<void> openInSoundCloudApp(String url) async {
    // TODO: Verwende url_launcher für deep-link
    // soundcloud://sounds:track_id
    debugPrint('Open in SoundCloud app: $url');
  }
}
