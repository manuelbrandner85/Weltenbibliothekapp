/// 👤 DIGITALER FUSSABDRUCK — Username in 25 Netzwerken finden.
///
/// Quelle: Worker-Endpoint /api/sherlock/check (Sherlock-Lite-Implementierung).
/// User gibt Username ein → Worker prüft 25 Plattformen parallel via HEAD-Requests.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../services/kaninchenbau_service.dart';
import '../widgets/kb_design.dart';

class SherlockCard extends StatefulWidget {
  /// Vorausgefüllter Username aus dem Thema (wird normalisiert: lowercase, ohne Leerzeichen).
  final String topic;

  const SherlockCard({super.key, required this.topic});

  @override
  State<SherlockCard> createState() => _SherlockCardState();
}

class _SherlockCardState extends State<SherlockCard> {
  final _service = KaninchenbauService();
  final _ctrl = TextEditingController();
  List<SherlockHit> _hits = const [];
  bool _loading = false;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    // Username-Vorschlag aus Topic generieren
    _ctrl.text = widget.topic
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^a-z0-9._-]'), '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final u = _ctrl.text.trim();
    if (u.length < 2) return;
    HapticFeedback.lightImpact();
    setState(() {
      _loading = true;
      _searched = true;
    });
    final hits = await _service.sherlockCheck(u);
    if (!mounted) return;
    setState(() {
      _hits = hits;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final found = _hits.where((h) => h.found).toList();
    return Container(
      decoration: KbDesign.glassBox(tint: const Color(0xFF4DD0E1)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fingerprint_rounded,
                  color: Color(0xFF4DD0E1), size: 18),
              const SizedBox(width: 8),
              const Text(
                'DIGITALER FUSSABDRUCK',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_searched && !_loading)
                Text(
                  '${found.length} / ${_hits.length} Treffer',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Username in 25 Netzwerken aufspüren',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: const Color(0xFF4DD0E1).withValues(alpha: 0.3),
                    ),
                  ),
                  child: TextField(
                    controller: _ctrl,
                    onSubmitted: (_) => _check(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'username',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                      prefixIcon: Icon(Icons.alternate_email_rounded,
                          color: Color(0xFF4DD0E1), size: 18),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loading ? null : _check,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4DD0E1),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.search_rounded, size: 18),
              ),
            ],
          ),
          if (_searched && !_loading) ...[
            const SizedBox(height: 14),
            if (found.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'Keine bekannten Profile mit diesem Namen gefunden.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: found.map((h) => _buildHit(h)).toList(),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildHit(SherlockHit h) {
    return InkWell(
      onTap: () async {
        HapticFeedback.lightImpact();
        final uri = Uri.tryParse(h.url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFF4DD0E1).withValues(alpha: 0.12),
          border: Border.all(
            color: const Color(0xFF4DD0E1).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                size: 12, color: Color(0xFF4DD0E1)),
            const SizedBox(width: 6),
            Text(
              h.platform,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
