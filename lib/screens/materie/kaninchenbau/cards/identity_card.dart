/// Identitäts-Karte: Hero-Card mit Name, Beschreibung, Bild, Quick-Facts.
library;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/kb_design.dart';

class IdentityCard extends StatelessWidget {
  final String topic;
  final Map<String, dynamic>? data;
  final bool loading;

  const IdentityCard({
    super.key,
    required this.topic,
    required this.data,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.heroBox(),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_rounded,
                  color: KbDesign.neonRedSoft, size: 18),
              const SizedBox(width: 8),
              Text(
                'IDENTITÄT',
                style: TextStyle(
                  color: KbDesign.neonRedSoft,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (loading)
            const _Skeleton()
          else if (data == null)
            _buildEmpty()
          else
            _buildContent(context),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final label = (data!['label'] ?? topic).toString();
    final desc = (data!['description'] ?? '').toString();
    final image = data!['image']?.toString();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: KbDesign.neonRed.withValues(alpha: 0.4),
              width: 1.5,
            ),
            color: KbDesign.cardSurfaceAlt,
          ),
          clipBehavior: Clip.antiAlias,
          child: image != null && image.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: image,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _avatarFallback(label),
                )
              : _avatarFallback(label),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatarFallback(String label) => Center(
        child: Text(
          label.isNotEmpty ? label[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w300,
          ),
        ),
      );

  Widget _buildEmpty() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(
              topic,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Keine Wikidata-Treffer — andere Quellen werden geladen.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
}

class _Skeleton extends StatefulWidget {
  const _Skeleton();
  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final v = 0.3 + 0.4 * _c.value;
        Color c = Colors.white.withValues(alpha: v * 0.18);
        return Row(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 200, height: 22, color: c),
                  const SizedBox(height: 8),
                  Container(width: double.infinity, height: 14, color: c),
                  const SizedBox(height: 6),
                  Container(width: 180, height: 14, color: c),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
