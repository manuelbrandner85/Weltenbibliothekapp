// 🟢 PATCH DOWNLOAD INDICATOR – Dezenter Fortschritts-Overlay
//
// Zeigt einen kleinen animierten Banner am unteren Rand während Shorebird
// einen Patch prüft oder herunterlädt. Verschwindet automatisch wenn fertig.
// Erscheint NUR wenn wirklich ein Download läuft (phase == downloading),
// für checking kurz, für done/error sofort wieder weg.

import 'dart:async';

import 'package:flutter/material.dart';

import '../services/update_service.dart';

class PatchDownloadIndicator extends StatefulWidget {
  const PatchDownloadIndicator({super.key});

  @override
  State<PatchDownloadIndicator> createState() => _PatchDownloadIndicatorState();
}

class _PatchDownloadIndicatorState extends State<PatchDownloadIndicator>
    with SingleTickerProviderStateMixin {
  StreamSubscription<PatchDownloadStatus>? _sub;
  PatchDownloadPhase? _phase;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _sub = UpdateService.instance.onPatchDownloadStatus.listen((status) {
      if (!mounted) return;
      setState(() => _phase = status.phase);
      if (status.phase == PatchDownloadPhase.downloading) {
        _fadeCtrl.forward();
      } else if (status.phase == PatchDownloadPhase.done ||
          status.phase == PatchDownloadPhase.error) {
        _fadeCtrl.reverse();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == null || _phase == PatchDownloadPhase.done) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      left: 24,
      right: 24,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1020).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.download_rounded,
                    color: Color(0xFF00E5FF),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _phase == PatchDownloadPhase.downloading
                        ? 'Update wird heruntergeladen…'
                        : 'Prüfe auf Updates…',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF00E5FF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
