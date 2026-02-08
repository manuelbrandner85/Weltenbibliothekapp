/// WELTENBIBLIOTHEK v5.10 – ADAPTIVES SCORING-SYSTEM
/// 
/// Intelligente Quellen-Bewertung basierend auf User-Profil:
/// - Trust-Score * User-Gewichtung = Adaptiver Score
/// - Personalisierte Relevanz-Berechnung
/// - Dynamische Ranking-Anpassung
library;

import '../models/user_profile.dart';
import '../utils/quellen_bewertung.dart';

/// Adaptives Scoring-System für personalisierte Quellen-Bewertung
class AdaptiveScoring {
  /// Berechnet adaptierten Score basierend auf User-Profil
  /// 
  /// Formula: adaptedScore = trustScore * userWeight
  /// 
  /// Beispiel:
  /// - trustScore: 80/100
  /// - userWeight: 1.5 (Dokumente bevorzugt)
  /// - adaptedScore: 120 (capped at 100)
  static double calculateAdaptedScore({
    required QuellenBewertung bewertung,
    required UserProfile userProfile,
    required String sourceType,
  }) {
    // Basis Trust-Score
    final trustScore = bewertung.vertrauensScore.toDouble();
    
    // 🚫 Nicht bewertete Quellen: Kein adaptiver Score
    if (!bewertung.istBewertet || trustScore < 0) {
      return -1.0;
    }
    
    // User-Gewichtung für diesen Quellen-Typ
    final userWeight = userProfile.getSourceWeight(sourceType);
    
    // Adaptiver Score = Trust-Score * User-Gewichtung
    final adaptedScore = trustScore * userWeight;
    
    // Auf 0-100 begrenzen
    return adaptedScore.clamp(0.0, 100.0);
  }
  
  /// Berechnet adaptive Scores für eine Liste von Bewertungen
  static List<AdaptiveScoredSource> scoreMultipleSources({
    required List<QuellenBewertung> bewertungen,
    required List<String> sourceTypes,
    required UserProfile userProfile,
  }) {
    final scoredSources = <AdaptiveScoredSource>[];
    
    for (int i = 0; i < bewertungen.length; i++) {
      final bewertung = bewertungen[i];
      final sourceType = i < sourceTypes.length ? sourceTypes[i] : 'unknown';
      
      final adaptedScore = calculateAdaptedScore(
        bewertung: bewertung,
        userProfile: userProfile,
        sourceType: sourceType,
      );
      
      scoredSources.add(AdaptiveScoredSource(
        bewertung: bewertung,
        sourceType: sourceType,
        trustScore: bewertung.vertrauensScore.toDouble(),
        userWeight: userProfile.getSourceWeight(sourceType),
        adaptedScore: adaptedScore,
      ));
    }
    
    return scoredSources;
  }
  
  /// Sortiert Quellen nach adaptivem Score (höchste zuerst)
  static List<AdaptiveScoredSource> sortByAdaptedScore(
    List<AdaptiveScoredSource> sources,
  ) {
    final sorted = List<AdaptiveScoredSource>.from(sources);
    sorted.sort((a, b) {
      // Nicht bewertete ans Ende
      if (a.adaptedScore < 0 && b.adaptedScore < 0) return 0;
      if (a.adaptedScore < 0) return 1;
      if (b.adaptedScore < 0) return -1;
      // Nach adaptivem Score sortieren
      return b.adaptedScore.compareTo(a.adaptedScore);
    });
    return sorted;
  }
  
  /// Berechnet Relevanz-Score (kombiniert Trust + User-Präferenz + Quellen-Typ)
  static double calculateRelevanceScore({
    required QuellenBewertung bewertung,
    required UserProfile userProfile,
    required String sourceType,
  }) {
    // Basis: Adaptiver Score
    final adaptedScore = calculateAdaptedScore(
      bewertung: bewertung,
      userProfile: userProfile,
      sourceType: sourceType,
    );
    
    if (adaptedScore < 0) return -1.0;
    
    // Bonus: Bevorzugte Quelle
    final isPreferred = userProfile.isSourcePreferred(sourceType);
    final preferenceBonus = isPreferred ? 10.0 : 0.0;
    
    // Bonus: Sichtweisen-Match (wenn implementiert)
    // final viewBonus = _calculateViewBonus(bewertung, userProfile);
    
    // Gesamt-Relevanz
    final relevance = adaptedScore + preferenceBonus;
    
    return relevance.clamp(0.0, 100.0);
  }
  
  /// Erstellt Scoring-Report für Debugging
  static ScoringReport generateReport({
    required List<AdaptiveScoredSource> sources,
    required UserProfile userProfile,
  }) {
    final bewerteteQuellen = sources.where((s) => s.adaptedScore >= 0).toList();
    final nichtBewertete = sources.where((s) => s.adaptedScore < 0).toList();
    
    // Durchschnittliche Scores
    final avgTrustScore = bewerteteQuellen.isEmpty 
        ? 0.0 
        : bewerteteQuellen.fold<double>(0, (sum, s) => sum + s.trustScore) / 
          bewerteteQuellen.length;
    
    final avgAdaptedScore = bewerteteQuellen.isEmpty 
        ? 0.0 
        : bewerteteQuellen.fold<double>(0, (sum, s) => sum + s.adaptedScore) / 
          bewerteteQuellen.length;
    
    // Gewichtungs-Effekt
    final weightingEffect = avgAdaptedScore - avgTrustScore;
    
    return ScoringReport(
      totalSources: sources.length,
      bewerteteQuellen: bewerteteQuellen.length,
      nichtBewerteteQuellen: nichtBewertete.length,
      averageTrustScore: avgTrustScore,
      averageAdaptedScore: avgAdaptedScore,
      weightingEffect: weightingEffect,
      topSources: bewerteteQuellen.take(5).toList(),
    );
  }
}

/// Quelle mit adaptivem Score
class AdaptiveScoredSource {
  final QuellenBewertung bewertung;
  final String sourceType;
  final double trustScore;      // Original Trust-Score
  final double userWeight;      // User-Gewichtung
  final double adaptedScore;    // Adaptiver Score
  
  const AdaptiveScoredSource({
    required this.bewertung,
    required this.sourceType,
    required this.trustScore,
    required this.userWeight,
    required this.adaptedScore,
  });
  
  /// Score-Differenz (wie stark wurde angepasst?)
  double get scoreDifference => adaptedScore - trustScore;
  
  /// Wurde die Quelle aufgewertet?
  bool get wasUpgraded => scoreDifference > 0;
  
  /// Wurde die Quelle abgewertet?
  bool get wasDowngraded => scoreDifference < 0;
  
  /// Formatierter Score-String
  String get scoreDisplay {
    if (adaptedScore < 0) return 'Nicht bewertet';
    
    final arrow = wasUpgraded 
        ? '↑' 
        : wasDowngraded 
            ? '↓' 
            : '→';
    
    return '${adaptedScore.toStringAsFixed(0)}/100 $arrow';
  }
  
  /// Formatierte Gewichtungs-Info
  String get weightDisplay {
    if (userWeight == 1.0) return 'Standard (1.0x)';
    if (userWeight > 1.0) return 'Bevorzugt (${userWeight.toStringAsFixed(1)}x)';
    return 'Reduziert (${userWeight.toStringAsFixed(1)}x)';
  }
}

/// Scoring-Report für Debugging und Analytics
class ScoringReport {
  final int totalSources;
  final int bewerteteQuellen;
  final int nichtBewerteteQuellen;
  final double averageTrustScore;
  final double averageAdaptedScore;
  final double weightingEffect;
  final List<AdaptiveScoredSource> topSources;
  
  const ScoringReport({
    required this.totalSources,
    required this.bewerteteQuellen,
    required this.nichtBewerteteQuellen,
    required this.averageTrustScore,
    required this.averageAdaptedScore,
    required this.weightingEffect,
    required this.topSources,
  });
  
  /// Formatierter Report-String
  String toDisplayString() {
    final buffer = StringBuffer();
    buffer.writeln('═══ SCORING-REPORT ═══');
    buffer.writeln();
    buffer.writeln('📊 Quellen-Übersicht:');
    buffer.writeln('  Gesamt: $totalSources');
    buffer.writeln('  Bewertet: $bewerteteQuellen');
    buffer.writeln('  Nicht bewertet: $nichtBewerteteQuellen');
    buffer.writeln();
    buffer.writeln('📈 Durchschnittliche Scores:');
    buffer.writeln('  Trust-Score: ${averageTrustScore.toStringAsFixed(1)}/100');
    buffer.writeln('  Adaptiver Score: ${averageAdaptedScore.toStringAsFixed(1)}/100');
    buffer.writeln('  Gewichtungs-Effekt: ${weightingEffect >= 0 ? '+' : ''}${weightingEffect.toStringAsFixed(1)}');
    buffer.writeln();
    buffer.writeln('🏆 Top 5 Quellen:');
    for (int i = 0; i < topSources.length; i++) {
      final source = topSources[i];
      buffer.writeln('  ${i + 1}. ${source.bewertung.quelle}');
      buffer.writeln('     Score: ${source.scoreDisplay}');
      buffer.writeln('     Gewichtung: ${source.weightDisplay}');
    }
    
    return buffer.toString();
  }
}

/// Helper: Extrahiert Quellen-Typ aus Quelle
class SourceTypeDetector {
  /// Detektiert Quellen-Typ basierend auf URL/Text
  static String detectSourceType(String quelle) {
    final lower = quelle.toLowerCase();
    
    // Archive
    if (lower.contains('archive') || 
        lower.contains('wayback') ||
        lower.contains('archiv')) {
      return 'archive';
    }
    
    // Dokumente
    if (lower.contains('document') ||
        lower.contains('.pdf') ||
        lower.contains('dokument') ||
        lower.contains('akte') ||
        lower.contains('file')) {
      return 'documents';
    }
    
    // Medien
    if (lower.contains('video') ||
        lower.contains('youtube') ||
        lower.contains('vimeo') ||
        lower.contains('audio') ||
        lower.contains('podcast')) {
      return 'media';
    }
    
    // Timeline (spezielle Marker)
    if (lower.contains('timeline') ||
        lower.contains('chronology') ||
        lower.contains('zeitstrahl')) {
      return 'timeline';
    }
    
    // Default: Web
    return 'web';
  }
  
  /// Detektiert Quellen-Typen für Liste
  static List<String> detectMultipleTypes(List<String> quellen) {
    return quellen.map((q) => detectSourceType(q)).toList();
  }
}
