/// WELTENBIBLIOTHEK v5.17 – VEREINFACHTER INTERNATIONALER VERGLEICH
/// 
/// Zeigt deutsche vs. internationale Perspektive mit Fokus auf Kernquellen (2-4)
/// 
/// Struktur:
/// - 🇩🇪 Deutsche Darstellung (2-4 Kernquellen)
/// - 🇺🇸 Internationale Darstellung (2-4 Kernquellen)
library;

import 'package:flutter/material.dart';
import '../models/international_perspectives.dart';
import '../utils/responsive_utils.dart';
import '../utils/responsive_text_styles.dart';
import '../utils/responsive_spacing.dart';

class InternationalComparisonSimpleCard extends StatelessWidget {
  final InternationalPerspectivesAnalysis analysis;
  
  const InternationalComparisonSimpleCard({
    super.key,
    required this.analysis,
  });
  
  @override
  Widget build(BuildContext context) {
    // Extrahiere deutsche und internationale Perspektiven
    final germanPerspective = analysis.perspectives.firstWhere(
      (p) => p.region == 'de',
      orElse: () => analysis.perspectives.first,
    );
    
    final internationalPerspective = analysis.perspectives.firstWhere(
      (p) => p.region == 'us' || p.region == 'uk' || p.region == 'global',
      orElse: () => analysis.perspectives.last,
    );
    
    return SingleChildScrollView(
      padding: context.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 🇩🇪 DEUTSCHE DARSTELLUNG
          _buildPerspectiveCard(
            context,
            flag: '🇩🇪',
            title: 'Deutschsprachige Darstellung',
            perspective: germanPerspective,
            color: Colors.red[700]!,
            maxSources: 4,
          ),
          
          context.vSpaceMd,
          
          // 🇺🇸 INTERNATIONALE DARSTELLUNG
          _buildPerspectiveCard(
            context,
            flag: '🇺🇸',
            title: 'Internationale Darstellung',
            perspective: internationalPerspective,
            color: Colors.blue[700]!,
            maxSources: 4,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPerspectiveCard(
    BuildContext context, {
    required String flag,
    required String title,
    required InternationalPerspective perspective,
    required Color color,
    required int maxSources,
  }) {
    final responsive = context.responsive;
    final textStyles = context.textStyles;
    
    // Limitiere Quellen auf maxSources (2-4 Kernquellen)
    final kernquellen = perspective.sources.take(maxSources).toList();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(responsive.borderRadiusSm),
        border: Border.all(
          color: color,
          width: responsive.borderRadiusXs / 4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Container(
            padding: context.paddingMd,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(responsive.borderRadiusSm * 0.8),
                topRight: Radius.circular(responsive.borderRadiusSm * 0.8),
              ),
            ),
            child: Row(
              children: [
                Text(
                  flag,
                  style: textStyles.headlineMedium,
                ),
                context.hSpaceSm,
                Expanded(
                  child: Text(
                    title,
                    style: textStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // KERNQUELLEN (2-4 Stück)
          Container(
            padding: context.paddingMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.source,
                      color: color,
                      size: responsive.iconSizeSm,
                    ),
                    context.hSpaceXs,
                    Text(
                      'KERNQUELLEN (${kernquellen.length})',
                      style: textStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                context.vSpaceSm,
                ...kernquellen.asMap().entries.map((entry) {
                  final index = entry.key;
                  final source = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(bottom: responsive.spacingXs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: responsive.iconSizeMd,
                          height: responsive.iconSizeMd,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: textStyles.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: responsive.spacingXs),
                        Expanded(
                          child: Text(
                            source,
                            style: textStyles.bodySmall.copyWith(
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          
          const Divider(height: 1, color: Colors.white24),
          
          // NARRATIVE
          Container(
            padding: context.paddingMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.format_quote,
                      color: color,
                      size: responsive.iconSizeSm,
                    ),
                    context.hSpaceXs,
                    Text(
                      'TONFALL & NARRATIVE',
                      style: textStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                context.vSpaceSm,
                Container(
                  padding: context.paddingSm,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(responsive.borderRadiusXs),
                  ),
                  child: Text(
                    perspective.narrative,
                    style: textStyles.bodySmall.copyWith(
                      color: Colors.white,
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: Colors.white24),
          
          // HAUPTPUNKTE
          Container(
            padding: context.paddingMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.checklist,
                      color: color,
                      size: responsive.iconSizeSm,
                    ),
                    context.hSpaceXs,
                    Text(
                      'HAUPTPUNKTE',
                      style: textStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                context.vSpaceSm,
                ...perspective.keyPoints.map((point) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: responsive.spacingXs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: color,
                          size: responsive.iconSizeSm,
                        ),
                        context.hSpaceXs,
                        Expanded(
                          child: Text(
                            point,
                            style: textStyles.bodySmall.copyWith(
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
