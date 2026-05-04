/// 🎙️ B8: Live-Untertitel Overlay — zeigt die letzten 3 Captions
/// als schwebende semi-transparente Bar am unteren Bildschirmrand.
library;

import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import '../services/live_caption_service.dart';

class LiveCaptionOverlay extends StatefulWidget {
  final LiveCaptionService service;

  const LiveCaptionOverlay({super.key, required this.service});

  @override
  State<LiveCaptionOverlay> createState() => _LiveCaptionOverlayState();
}

class _LiveCaptionOverlayState extends State<LiveCaptionOverlay> {
  final Queue<CaptionEvent> _recent = Queue();
  StreamSubscription<CaptionEvent>? _sub;

  static const _maxVisible = 3;
  static const _expireAfter = Duration(seconds: 8);

  @override
  void initState() {
    super.initState();
    _sub = widget.service.captionsStream.listen(_onCaption);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onCaption(CaptionEvent event) {
    setState(() {
      _recent.addLast(event);
      // Maximal _maxVisible Einträge halten
      while (_recent.length > _maxVisible) {
        _recent.removeFirst();
      }
    });
    // Nach Ablauf der Anzeigedauer automatisch entfernen
    Future.delayed(_expireAfter, () {
      if (!mounted) return;
      setState(() => _recent.remove(event));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Partial-Text des lokalen Users (Echtzeit-Vorschau)
    final partial = widget.service.partialText;

    final visibleCaptions = _recent.toList();
    final hasContent = visibleCaptions.isNotEmpty || partial.isNotEmpty;

    if (!hasContent) return const SizedBox.shrink();

    return Positioned(
      left: 16,
      right: 16,
      bottom: 90, // Über der ControlBar
      child: IgnorePointer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Vergangene finalisierte Captions
            ...visibleCaptions.map((e) => _CaptionLine(event: e)),
            // Partial-Text (Echtzeit, lokaler User)
            if (partial.isNotEmpty)
              _CaptionLine.partial(text: partial),
          ],
        ),
      ),
    );
  }
}

class _CaptionLine extends StatelessWidget {
  final String name;
  final String text;
  final bool isPartial;

  const _CaptionLine({required CaptionEvent event})
      : name = event.name,
        text = event.text,
        isPartial = false;

  const _CaptionLine.partial({required this.text})
      : name = 'Du',
        isPartial = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$name: ',
              style: TextStyle(
                color: Colors.white.withValues(alpha: isPartial ? 0.55 : 0.80),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            TextSpan(
              text: text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: isPartial ? 0.55 : 0.95),
                fontSize: 13,
                fontStyle: isPartial ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
