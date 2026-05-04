/// Quellen-Karte: Multi-Perspektive (Offiziell ↔ Kritisch) mit Slider.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class SourcesCard extends StatefulWidget {
  final List<SourceItem> sources;
  final bool loading;
  const SourcesCard({
    super.key,
    required this.sources,
    required this.loading,
  });

  @override
  State<SourcesCard> createState() => _SourcesCardState();
}

class _SourcesCardState extends State<SourcesCard> {
  double _bias = 0.5; // 0=offiziell, 1=kritisch

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: KbDesign.lensOfficial),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded,
                  color: KbDesign.lensOfficial, size: 18),
              const SizedBox(width: 8),
              const Text(
                'QUELLEN',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildBiasSlider(),
          const SizedBox(height: 14),
          if (widget.loading)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(strokeWidth: 2),
            ))
          else
            ..._filteredSources().map((s) => _SourceTile(item: s)),
        ],
      ),
    );
  }

  List<SourceItem> _filteredSources() {
    final bias = _bias;
    return widget.sources.where((s) {
      switch (s.lens) {
        case SourceLens.official:
          return bias < 0.66;
        case SourceLens.critical:
          return bias > 0.33;
        case SourceLens.neutral:
          return true;
      }
    }).toList();
  }

  Widget _buildBiasSlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: KbDesign.cardSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Offiziell',
                style: TextStyle(
                  color: _bias < 0.5
                      ? KbDesign.lensOfficial
                      : Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Kritisch',
                style: TextStyle(
                  color: _bias > 0.5
                      ? KbDesign.lensCritical
                      : Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              activeTrackColor: KbDesign.lensCritical,
              inactiveTrackColor: KbDesign.lensOfficial.withValues(alpha: 0.5),
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: _bias,
              onChanged: (v) => setState(() => _bias = v),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final SourceItem item;
  const _SourceTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = _lensColor(item.lens);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(KbDesign.radiusSm),
        onTap: () async {
          final uri = Uri.tryParse(item.url);
          if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: KbDesign.cardSurfaceAlt,
            borderRadius: BorderRadius.circular(KbDesign.radiusSm),
            border: Border(
              left: BorderSide(color: color, width: 3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _lensLabel(item.lens),
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    item.credibility >= 80
                        ? Icons.verified_rounded
                        : Icons.info_outline_rounded,
                    size: 13,
                    color: _credColor(item.credibility),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.credibility}',
                    style: TextStyle(
                      color: _credColor(item.credibility),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
              if (item.snippet.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.snippet,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _lensColor(SourceLens l) {
    switch (l) {
      case SourceLens.official:
        return KbDesign.lensOfficial;
      case SourceLens.critical:
        return KbDesign.lensCritical;
      case SourceLens.neutral:
        return KbDesign.lensNeutral;
    }
  }

  String _lensLabel(SourceLens l) {
    switch (l) {
      case SourceLens.official:
        return 'OFFIZIELL';
      case SourceLens.critical:
        return 'KRITISCH';
      case SourceLens.neutral:
        return 'NEUTRAL';
    }
  }

  Color _credColor(int v) {
    if (v >= 80) return KbDesign.credGold;
    if (v >= 60) return KbDesign.credSilver;
    return KbDesign.credAlert;
  }
}
