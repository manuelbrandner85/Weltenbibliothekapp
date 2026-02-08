/// WELTENBIBLIOTHEK v5.10 – ADAPTIVE SCORING UI-KOMPONENTE
/// 
/// Zeigt adaptierten Score mit User-Gewichtung visuell an
library;

import 'package:flutter/material.dart';
import '../utils/adaptive_scoring.dart';
import '../utils/quellen_bewertung.dart';
import '../utils/responsive_utils.dart';
import '../utils/responsive_text_styles.dart';
import '../utils/responsive_spacing.dart';

/// Widget für adaptive Quellen-Bewertung mit User-Gewichtung
class AdaptiveScoredSourceCard extends StatelessWidget {
  final AdaptiveScoredSource scoredSource;
  final bool showDetails;
  
  const AdaptiveScoredSourceCard({
    super.key,
    required this.scoredSource,
    this.showDetails = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    // Nicht bewertete Quellen → Fallback zur Standard-Card
    if (scoredSource.adaptedScore < 0) {
      return QuellenBewertungsCard(
        bewertung: scoredSource.bewertung,
        showDetails: showDetails,
      );
    }
    
    final stufe = _getStufeByScore(scoredSource.adaptedScore);
    
    return Card(
      elevation: responsive.elevationSm,
      margin: EdgeInsets.symmetric(vertical: responsive.spacingXs),
      child: Padding(
        padding: context.paddingSm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QUELLE & ADAPTIVE SCORES
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vertrauensstufe-Icon
                Icon(
                  stufe.icon,
                  color: stufe.color,
                  size: responsive.iconSizeLg,
                ),
                context.hSpaceSm,
                
                // Quelle & Scores
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scoredSource.bewertung.quelle,
                        style: context.textStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: responsive.spacingXs / 2),
                      _buildScoreRow(context, stufe),
                    ],
                  ),
                ),
              ],
            ),
            
            // DETAILS (optional)
            if (showDetails) ...[
              context.vSpaceSm,
              const Divider(),
              context.vSpaceXs,
              
              // SCORING-BREAKDOWN
              _buildScoringBreakdown(context),
              
              context.vSpaceSm,
              
              // INDIKATOREN
              if (scoredSource.bewertung.positiveIndikatoren.isNotEmpty ||
                  scoredSource.bewertung.negativeIndikatoren.isNotEmpty)
                _buildIndikatoren(context),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildScoreRow(BuildContext context, VertrauensStufe stufe) {
    final responsive = context.responsive;
    final textStyles = context.textStyles;
    
    return Row(
      children: [
        // Trust-Score Badge
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.spacingXs,
            vertical: responsive.spacingXs / 2,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(responsive.borderRadiusXs),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Trust: ${scoredSource.trustScore.toStringAsFixed(0)}',
                style: textStyles.labelSmall.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(width: responsive.spacingXs / 1.5),
        
        // Gewichtungs-Arrow
        Icon(
          scoredSource.wasUpgraded 
              ? Icons.arrow_upward 
              : scoredSource.wasDowngraded 
                  ? Icons.arrow_downward 
                  : Icons.arrow_forward,
          size: responsive.iconSizeSm,
          color: scoredSource.wasUpgraded 
              ? Colors.green 
              : scoredSource.wasDowngraded 
                  ? Colors.red 
                  : Colors.grey,
        ),
        
        SizedBox(width: responsive.spacingXs / 1.5),
        
        // Adaptiver Score Badge
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.spacingXs,
            vertical: responsive.spacingXs / 2,
          ),
          decoration: BoxDecoration(
            color: stufe.color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(responsive.borderRadiusXs),
          ),
          child: Text(
            'Adaptiv: ${scoredSource.adaptedScore.toStringAsFixed(0)}',
            style: textStyles.labelSmall.copyWith(
              color: stufe.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildScoringBreakdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 6),
              Text(
                'Scoring-Breakdown',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Trust-Score
          _buildScoreLine(
            context,
            'Trust-Score',
            scoredSource.trustScore,
            Colors.grey[600]!,
          ),
          
          // User-Gewichtung
          _buildWeightLine(
            context,
            'User-Gewichtung (${scoredSource.sourceType})',
            scoredSource.userWeight,
          ),
          
          const Divider(height: 16),
          
          // Adaptiver Score
          _buildScoreLine(
            context,
            'Adaptiver Score',
            scoredSource.adaptedScore,
            Colors.blue[700]!,
            isBold: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildScoreLine(BuildContext context, String label, double value, Color color, {bool isBold = false}) {
    final utils = ResponsiveUtils.of(context);
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: utils.spacingXs / 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: ResponsiveTextStyles.of(context).labelSmall.copyWith(
                color: Colors.grey[700],
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)}/100',
            style: ResponsiveTextStyles.of(context).labelSmall.copyWith(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWeightLine(BuildContext context, String label, double weight) {
    final utils = ResponsiveUtils.of(context);
    final color = weight > 1.0 
        ? Colors.green 
        : weight < 1.0 
            ? Colors.orange 
            : Colors.grey;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: utils.spacingXs / 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: ResponsiveTextStyles.of(context).labelSmall.copyWith(
                color: Colors.grey[700],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: utils.spacingXs / 2, 
              vertical: utils.spacingXs / 4,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(utils.borderRadiusXs),
            ),
            child: Text(
              '× ${weight.toStringAsFixed(1)}',
              style: ResponsiveTextStyles.of(context).labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildIndikatoren(BuildContext context) {
    final utils = ResponsiveUtils.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // POSITIVE INDIKATOREN
        if (scoredSource.bewertung.positiveIndikatoren.isNotEmpty) ...[
          Text(
            'Positive Indikatoren',
            style: ResponsiveTextStyles.of(context).labelSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          SizedBox(height: utils.spacingXs / 2),
          ...scoredSource.bewertung.positiveIndikatoren.map((indikator) => 
            Padding(
              padding: EdgeInsets.only(left: utils.spacingXs, top: utils.spacingXs / 2),
              child: Row(
                children: [
                  Icon(indikator.icon, size: utils.iconSizeSm, color: indikator.color),
                  SizedBox(width: utils.spacingXs / 2),
                  Expanded(
                    child: Text(
                      indikator.label,
                      style: ResponsiveTextStyles.of(context).labelSmall.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: utils.spacingXs),
        ],
        
        // NEGATIVE INDIKATOREN
        if (scoredSource.bewertung.negativeIndikatoren.isNotEmpty) ...[
          Text(
            'Negative Indikatoren',
            style: ResponsiveTextStyles.of(context).labelSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          SizedBox(height: utils.spacingXs / 2),
          ...scoredSource.bewertung.negativeIndikatoren.map((indikator) => 
            Padding(
              padding: EdgeInsets.only(left: utils.spacingXs, top: utils.spacingXs / 2),
              child: Row(
                children: [
                  Icon(indikator.icon, size: utils.iconSizeSm, color: indikator.color),
                  SizedBox(width: utils.spacingXs / 2),
                  Expanded(
                    child: Text(
                      indikator.label,
                      style: ResponsiveTextStyles.of(context).labelSmall.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  VertrauensStufe _getStufeByScore(double score) {
    if (score >= 75) return VertrauensStufe.hoch;
    if (score >= 50) return VertrauensStufe.mittel;
    if (score >= 25) return VertrauensStufe.niedrig;
    return VertrauensStufe.sehrNiedrig;
  }
}

/// Scoring-Report Widget
class ScoringReportWidget extends StatelessWidget {
  final ScoringReport report;
  
  const ScoringReportWidget({
    super.key,
    required this.report,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue[700], size: 24),
                const SizedBox(width: 8),
                Text(
                  'SCORING-REPORT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            SelectableText(
              report.toDisplayString(),
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
