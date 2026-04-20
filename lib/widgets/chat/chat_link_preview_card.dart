import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/link_preview.dart';
import '../../services/chat/link_preview_service.dart';

/// Rendert eine Link-Vorschau unter einer Chat-Nachricht.
/// Lädt Metadaten asynchron via [LinkPreviewService]; zeigt während des
/// Ladens einen schlanken Platzhalter, bei Fehler gar nichts.
class ChatLinkPreviewCard extends StatefulWidget {
  const ChatLinkPreviewCard({
    super.key,
    required this.url,
    this.accent = const Color(0xFF7C4DFF),
    this.backgroundColor = const Color(0xFF111122),
  });

  final String url;
  final Color accent;
  final Color backgroundColor;

  @override
  State<ChatLinkPreviewCard> createState() => _ChatLinkPreviewCardState();
}

class _ChatLinkPreviewCardState extends State<ChatLinkPreviewCard> {
  LinkPreview? _preview;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final cached = LinkPreviewService.instance.cached(widget.url);
    if (cached != null) {
      _preview = cached;
    } else {
      _loading = true;
      LinkPreviewService.instance.fetch(widget.url).then((p) {
        if (!mounted) return;
        setState(() {
          _preview = p;
          _loading = false;
          _failed = p == null;
        });
      });
    }
  }

  Future<void> _openUrl() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();
    if (_loading && _preview == null) {
      return _buildSkeleton();
    }
    final p = _preview;
    if (p == null) return const SizedBox.shrink();

    return InkWell(
      onTap: _openUrl,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(color: widget.accent, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (p.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(10),
                ),
                child: Image.network(
                  p.imageUrl!,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  loadingBuilder: (ctx, child, prog) {
                    if (prog == null) return child;
                    return Container(
                      height: 140,
                      color: Colors.white10,
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (p.siteName != null)
                    Text(
                      p.siteName!,
                      style: TextStyle(
                        color: widget.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (p.title != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      p.title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (p.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      p.description!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      height: 60,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: widget.accent, width: 3)),
      ),
      child: const Center(
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
