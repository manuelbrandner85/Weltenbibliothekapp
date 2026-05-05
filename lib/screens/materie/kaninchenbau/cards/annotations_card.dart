/// 💬 COMMUNITY-HINWEISE — Anmerkungen, Beweise, Whistleblower-Beiträge.
///
/// Eingeloggte User können Hinweise pinnen (anonym oder mit Name).
/// Up/Downvotes via thread_annotation_votes.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/saved_threads_service.dart';
import '../widgets/kb_design.dart';

class AnnotationsCard extends StatefulWidget {
  final String topic;
  const AnnotationsCard({super.key, required this.topic});

  @override
  State<AnnotationsCard> createState() => _AnnotationsCardState();
}

class _AnnotationsCardState extends State<AnnotationsCard> {
  final _service = SavedThreadsService.instance;
  List<ThreadAnnotation> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _service.listAnnotations(widget.topic);
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _addDialog() async {
    final result = await showDialog<_AddResult>(
      context: context,
      builder: (_) => _AddAnnotationDialog(topic: widget.topic),
    );
    if (result == null) return;
    final added = await _service.addAnnotation(
      topic: widget.topic,
      body: result.body,
      sourceUrl: result.sourceUrl,
      isAnonymous: result.anonymous,
    );
    if (added != null) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: const Color(0xFFCE93D8)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.forum_rounded,
                  color: Color(0xFFCE93D8), size: 18),
              const SizedBox(width: 8),
              const Text(
                'COMMUNITY-HINWEISE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_circle_rounded,
                    color: Color(0xFFCE93D8), size: 22),
                onPressed: _addDialog,
                tooltip: 'Hinweis hinzufügen',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Anonyme Whistleblower-Beiträge möglich',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(strokeWidth: 2),
            ))
          else if (_items.isEmpty)
            _buildEmpty()
          else
            ..._items.map(_buildItem),
        ],
      ),
    );
  }

  Widget _buildEmpty() => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Noch keine Hinweise zu diesem Thema.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _addDialog,
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text('Ersten Hinweis posten'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCE93D8),
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      );

  Widget _buildItem(ThreadAnnotation a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(KbDesign.radiusSm),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: const Color(0xFFCE93D8).withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                a.isAnonymous
                    ? Icons.shield_rounded
                    : Icons.person_rounded,
                size: 13,
                color: a.isAnonymous
                    ? KbDesign.goldAccent
                    : const Color(0xFFCE93D8),
              ),
              const SizedBox(width: 4),
              Text(
                a.isAnonymous ? 'Anonym' : 'Mitglied',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _relTime(a.createdAt),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              _voteBadge(a),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            a.body,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (a.sourceUrl != null && a.sourceUrl!.isNotEmpty) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final uri = Uri.tryParse(a.sourceUrl!);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Row(
                children: [
                  Icon(Icons.link_rounded,
                      size: 12,
                      color: const Color(0xFFCE93D8).withValues(alpha: 0.9)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      a.sourceUrl!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFFCE93D8).withValues(alpha: 0.9),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _voteButton(
                icon: Icons.arrow_upward_rounded,
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await _service.voteAnnotation(a.id, 1);
                  await _load();
                },
              ),
              const SizedBox(width: 8),
              _voteButton(
                icon: Icons.arrow_downward_rounded,
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await _service.voteAnnotation(a.id, -1);
                  await _load();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _voteBadge(ThreadAnnotation a) {
    final score = a.score;
    final color = score > 0
        ? const Color(0xFF66BB6A)
        : score < 0
            ? const Color(0xFFEF5350)
            : Colors.white54;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: color.withValues(alpha: 0.18),
      ),
      child: Text(
        score >= 0 ? '+$score' : '$score',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _voteButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Colors.white.withValues(alpha: 0.05),
        ),
        child: Icon(icon, size: 14, color: Colors.white70),
      ),
    );
  }

  String _relTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    return '${(d.inDays / 7).floor()}w';
  }
}

class _AddResult {
  final String body;
  final String? sourceUrl;
  final bool anonymous;
  _AddResult(
      {required this.body, required this.anonymous, this.sourceUrl});
}

class _AddAnnotationDialog extends StatefulWidget {
  final String topic;
  const _AddAnnotationDialog({required this.topic});

  @override
  State<_AddAnnotationDialog> createState() => _AddAnnotationDialogState();
}

class _AddAnnotationDialogState extends State<_AddAnnotationDialog> {
  final _body = TextEditingController();
  final _src = TextEditingController();
  bool _anon = false;

  @override
  void dispose() {
    _body.dispose();
    _src.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: KbDesign.cardSurface,
      title: Row(
        children: [
          Icon(Icons.edit_note_rounded, color: const Color(0xFFCE93D8)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Hinweis zu "${widget.topic}"',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _body,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Was möchtest du dazu sagen?',
                hintStyle: TextStyle(color: Colors.white38),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _src,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Quelle/Beleg-URL (optional)',
                hintStyle: TextStyle(color: Colors.white38),
                prefixIcon: Icon(Icons.link_rounded, color: Colors.white38),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              dense: true,
              value: _anon,
              onChanged: (v) => setState(() => _anon = v ?? false),
              title: const Text(
                'Anonym posten (Whistleblower-Modus)',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              activeColor: KbDesign.goldAccent,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () {
            final b = _body.text.trim();
            if (b.isEmpty) return;
            Navigator.pop(
              context,
              _AddResult(
                body: b,
                sourceUrl: _src.text.trim().isEmpty ? null : _src.text.trim(),
                anonymous: _anon,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFCE93D8),
            foregroundColor: Colors.black,
          ),
          child: const Text('Posten'),
        ),
      ],
    );
  }
}
