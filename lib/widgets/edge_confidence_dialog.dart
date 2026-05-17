// EdgeConfidenceDialog — Slider (1-5 Sterne) für Conspiracy-Network-Edge.
//
// Verwendung von einer Edge-Tap-Geste (z.B. on long-press einer Verbindung):
//   await EdgeConfidenceDialog.show(context,
//     world: 'materie', nodeA: 'CIA', nodeB: 'Mockingbird',
//     userId: '...');

import 'package:flutter/material.dart';

import '../services/edge_confidence_service.dart';
import '../utils/wb_toast.dart';

class EdgeConfidenceDialog {
  static Future<bool> show(
    BuildContext context, {
    required String world,
    required String userId,
    required String nodeA,
    required String nodeB,
    Color accent = const Color(0xFF2979FF),
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _DialogContent(
        world: world,
        userId: userId,
        nodeA: nodeA,
        nodeB: nodeB,
        accent: accent,
      ),
    );
    return result ?? false;
  }
}

class _DialogContent extends StatefulWidget {
  final String world, userId, nodeA, nodeB;
  final Color accent;

  const _DialogContent({
    required this.world,
    required this.userId,
    required this.nodeA,
    required this.nodeB,
    required this.accent,
  });

  @override
  State<_DialogContent> createState() => _DialogContentState();
}

class _DialogContentState extends State<_DialogContent> {
  int _rating = 3;
  bool _loading = true;
  bool _saving = false;
  EdgeConfidence? _existing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ec = await EdgeConfidenceService.instance.getForUser(
      userId: widget.userId,
      world: widget.world,
      nodeA: widget.nodeA,
      nodeB: widget.nodeB,
    );
    if (!mounted) return;
    setState(() {
      _existing = ec;
      if ((ec?.rating ?? 0) > 0) _rating = ec!.rating;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final ok = await EdgeConfidenceService.instance.rate(
      userId: widget.userId,
      world: widget.world,
      nodeA: widget.nodeA,
      nodeB: widget.nodeB,
      rating: _rating,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      WBToast.success(context, '⭐ Bewertung gespeichert');
      Navigator.of(context).pop(true);
    } else {
      WBToast.error(context, 'Fehler beim Speichern');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0D0D1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wie sicher belegt?',
              style: TextStyle(
                color: widget.accent,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.nodeA}  ↔  ${widget.nodeB}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final v = i + 1;
                  final filled = v <= _rating;
                  return IconButton(
                    onPressed: () => setState(() => _rating = v),
                    icon: Icon(
                      filled ? Icons.star_rounded : Icons.star_border_rounded,
                      color: filled ? widget.accent : Colors.white38,
                      size: 32,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _ratingLabel(_rating),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (!_loading && _existing != null && _existing!.voteCount > 0) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Community: ${_existing!.avgRating.toStringAsFixed(1)} ⭐ '
                  '(${_existing!.voteCount} Stimmen)',
                  style: TextStyle(
                    color: widget.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Abbrechen',
                      style: TextStyle(color: Colors.white60)),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accent,
                    foregroundColor: Colors.white,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.8,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text('Speichern'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1:
        return 'Sehr spekulativ';
      case 2:
        return 'Schwache Hinweise';
      case 3:
        return 'Plausibel';
      case 4:
        return 'Gut belegt';
      case 5:
        return 'Faktisch nachweisbar';
      default:
        return '';
    }
  }
}
