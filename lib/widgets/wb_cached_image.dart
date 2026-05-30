// WbCachedImage -- zentraler Wrapper um CachedNetworkImage.
//
// PERF-FIX (#3): Vorher nutzten ~37 Stellen Image.network OHNE Caching.
// Bei jedem Rebuild/Scroll wurde das Bild neu vom Server geladen ->
// Bandbreiten-Drain + UI-Lag in Bild-Listen (Karten-Thumbnails,
// Replay-Library, Avatare). CachedNetworkImage cached lokal.
//
// Verwendung (Drop-in fuer Image.network):
//   WbCachedImage(url, fit: BoxFit.cover, width: 80, height: 80)
//
// Liefert automatisch:
//   - Platzhalter (dezenter Spinner) waehrend Laden
//   - Fehler-Widget (broken-image Icon) bei Fehler
//   - leeres SizedBox bei leerer/null URL

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class WbCachedImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;
  final Color? placeholderColor;

  const WbCachedImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
    this.placeholderColor,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) {
      return _wrap(SizedBox(
        width: width,
        height: height,
        child: errorWidget ?? _defaultError(),
      ));
    }
    return _wrap(CachedNetworkImage(
      imageUrl: url!,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, __) => Container(
        width: width,
        height: height,
        color: placeholderColor ?? Colors.white.withValues(alpha: 0.04),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => SizedBox(
        width: width,
        height: height,
        child: errorWidget ?? _defaultError(),
      ),
    ));
  }

  Widget _wrap(Widget child) {
    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }

  Widget _defaultError() => Container(
        color: Colors.white.withValues(alpha: 0.04),
        child: Icon(
          Icons.broken_image_rounded,
          color: Colors.white.withValues(alpha: 0.3),
          size: (width != null && width! < 48) ? 16 : 28,
        ),
      );
}
