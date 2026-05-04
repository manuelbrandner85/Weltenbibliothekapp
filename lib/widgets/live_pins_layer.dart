/// 📍 LIVE PINS LAYER für FlutterMap (Bundle 7)
///
/// Zeigt Live-Pins (gepulst, Welt-farbig) als MarkerLayer auf der Karte.
/// Stream-basiert via [LiveMapPinsService.streamPinsForWorld(world)].
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/live_map_pins_service.dart';

class LivePinsLayer extends StatelessWidget {
  final String world;
  final Color accent;

  const LivePinsLayer({super.key, required this.world, required this.accent});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LiveMapPin>>(
      stream: LiveMapPinsService.instance.streamPinsForWorld(world),
      initialData: const [],
      builder: (_, snap) {
        final pins = snap.data ?? const [];
        if (pins.isEmpty) return const SizedBox.shrink();
        return MarkerLayer(
          markers: pins
              .map(
                (p) => Marker(
                  point: LatLng(p.lat, p.lon),
                  width: 44,
                  height: 60,
                  alignment: Alignment.bottomCenter,
                  child: _LivePinMarker(pin: p, accent: accent),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _LivePinMarker extends StatefulWidget {
  final LiveMapPin pin;
  final Color accent;
  const _LivePinMarker({required this.pin, required this.accent});

  @override
  State<_LivePinMarker> createState() => _LivePinMarkerState();
}

class _LivePinMarkerState extends State<_LivePinMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPinDetails(context),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = _ctrl.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.accent,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: 0.45 + t * 0.30),
                      blurRadius: 14 + t * 10,
                      spreadRadius: 1 + t * 3,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: widget.pin.authorAvatarUrl != null &&
                          widget.pin.authorAvatarUrl!.isNotEmpty
                      ? Image.network(
                          widget.pin.authorAvatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _initialsFallback(),
                        )
                      : _initialsFallback(),
                ),
              ),
              // Pin-Spitze
              CustomPaint(
                size: const Size(14, 14),
                painter: _PinTipPainter(widget.accent),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _initialsFallback() => Container(
        alignment: Alignment.center,
        color: widget.accent,
        child: Text(
          _initials(widget.pin.authorName),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  void _showPinDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1020),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: widget.accent.withValues(alpha: 0.3),
                  child: Text(
                    _initials(widget.pin.authorName),
                    style: TextStyle(
                      color: widget.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.pin.authorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Live-Pin · ${_relativeTime(widget.pin.createdAt)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: widget.accent.withValues(alpha: 0.25)),
              ),
              child: Text(
                widget.pin.label.isEmpty
                    ? '(Kein Text — nur Markierung)'
                    : widget.pin.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${widget.pin.lat.toStringAsFixed(4)}°, ${widget.pin.lon.toStringAsFixed(4)}°',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime t) {
    final s = DateTime.now().difference(t).inSeconds;
    if (s < 60) return 'gerade eben';
    final m = s ~/ 60;
    if (m < 5) return 'vor $m Min';
    return 'vor ${m} Min (verschwindet bald)';
  }
}

class _PinTipPainter extends CustomPainter {
  final Color color;
  _PinTipPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);

    // Weißer Border
    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant _PinTipPainter old) => old.color != color;
}
