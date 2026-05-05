/// 📚 INTERNET ARCHIVE — Wayback Machine + 50M+ archivierte Dokumente (kostenlos, kein Key)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class ArchiveCard extends StatelessWidget {
  final List<ArchiveDoc> docs;
  final bool loading;

  const ArchiveCard({super.key, required this.docs, required this.loading});

  static const _accent = Color(0xFF66BB6A);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: _accent, opacity: 0.10),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.archive_rounded, color: _accent, size: 18),
            const SizedBox(width: 8),
            const Text('INTERNET ARCHIVE',
                style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (docs.isNotEmpty)
              Text('${docs.length}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
          ]),
          const SizedBox(height: 4),
          Text('archive.org · Wayback Machine · 50M+ Dokumente · Bücher · Videos',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
          const SizedBox(height: 14),
          if (loading)
            _buildLoading()
          else if (docs.isEmpty)
            _buildEmpty()
          else
            ...docs.take(6).map(_buildDoc),
        ],
      ),
    );
  }

  Widget _buildLoading() => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: _accent, strokeWidth: 2)),
        ),
      );

  Widget _buildEmpty() => Padding(
        padding: const EdgeInsets.all(20),
        child: Text('Keine archivierten Dokumente gefunden.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
      );

  Widget _buildDoc(ArchiveDoc d) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          HapticFeedback.lightImpact();
          final uri = Uri.tryParse(d.url);
          if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _accent.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withValues(alpha: 0.12),
              ),
              alignment: Alignment.center,
              child: Icon(_iconForType(d.mediatype), color: _accent, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.title,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  _typeBadge(d.mediatype),
                  if (d.creator.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(d.creator,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  if (d.date.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(d.date.length > 10 ? d.date.substring(0, 4) : d.date,
                        style: TextStyle(color: _accent.withValues(alpha: 0.6), fontSize: 9, fontWeight: FontWeight.w600)),
                  ],
                ]),
                if (d.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(d.description,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, height: 1.3),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ]),
            ),
            Icon(Icons.open_in_new_rounded, color: _accent, size: 13),
          ]),
        ),
      ),
    );
  }

  Widget _typeBadge(String type) {
    final color = _colorForType(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(type.toUpperCase(),
          style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w800)),
    );
  }

  Color _colorForType(String type) {
    switch (type.toLowerCase()) {
      case 'texts': return const Color(0xFF42A5F5);
      case 'movies': return const Color(0xFFFF7043);
      case 'audio': return const Color(0xFFAB47BC);
      case 'image': return const Color(0xFF26A69A);
      default: return _accent;
    }
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'texts': return Icons.description_rounded;
      case 'movies': return Icons.movie_rounded;
      case 'audio': return Icons.headphones_rounded;
      case 'image': return Icons.image_rounded;
      default: return Icons.folder_rounded;
    }
  }
}
