/// Conspiracy Research Datenmodelle
/// Themenbasiertes Deep-Research-System
/// Version: 1.0.0
library;

import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
// THEMEN-AUSWAHL
// ═══════════════════════════════════════════════════════════════

enum ResearchTheme {
  secretPrograms,     // Geheime Programme & Experimente
  secretSocieties,    // Geheimgesellschaften & Elitennetzwerke
  powerStructures,    // Globale Machtstrukturen
  mediaNarratives,    // Medien, Narrative & PsyOps
  ancientKnowledge,   // Altes & verdrängtes Wissen
  crisesWars,         // Krisen, Kriege & Umbrüche
  controlMechanisms,  // Mensch & Kontrolle
}

class ResearchTopic {
  final ResearchTheme theme;
  final String title;
  final String icon;
  final Color color;
  final List<String> keywords;
  final List<int> activeToolIndices; // Welche Tools aktiviert werden

  ResearchTopic({
    required this.theme,
    required this.title,
    required this.icon,
    required this.color,
    required this.keywords,
    required this.activeToolIndices,
  });
}

// ═══════════════════════════════════════════════════════════════
// TOOL 1: CONSPIRACY DEEP SCANNER
// ═══════════════════════════════════════════════════════════════

enum ClaimType {
  factual,
  speculative,
  contradictory,
}

class ConspiracyClaim {
  final String id;
  final String claim;
  final ClaimType type;
  final List<String> actors;
  final List<String> motives;
  final Map<String, dynamic> evidence;

  ConspiracyClaim({
    required this.id,
    required this.claim,
    required this.type,
    required this.actors,
    required this.motives,
    required this.evidence,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'claim': claim,
    'type': type.toString(),
    'actors': actors,
    'motives': motives,
    'evidence': evidence,
  };
}

class DeepScanResult {
  final ResearchTheme theme;
  final List<ConspiracyClaim> claims;
  final Map<ClaimType, int> distribution;
  final List<String> contradictions;
  final DateTime scannedAt;

  DeepScanResult({
    required this.theme,
    required this.claims,
    required this.distribution,
    required this.contradictions,
    required this.scannedAt,
  });
}

// ═══════════════════════════════════════════════════════════════
// TOOL 2: SOURCE & ORIGIN TRACKER
// ═══════════════════════════════════════════════════════════════

class SourceNode {
  final String id;
  final String title;
  final DateTime publishDate;
  final String author;
  final int citationCount;
  final List<String> citedBy;
  final double agendaScore; // 0-1

  SourceNode({
    required this.id,
    required this.title,
    required this.publishDate,
    required this.author,
    required this.citationCount,
    required this.citedBy,
    required this.agendaScore,
  });
}

class EchoChamber {
  final String id;
  final List<String> sourceIds;
  final double isolationScore; // 0-1
  final List<String> sharedNarratives;

  EchoChamber({
    required this.id,
    required this.sourceIds,
    required this.isolationScore,
    required this.sharedNarratives,
  });
}

class OriginTrackingResult {
  final List<SourceNode> sources;
  final Map<String, List<String>> citationChains;
  final List<EchoChamber> echoChambers;
  final DateTime trackedAt;

  OriginTrackingResult({
    required this.sources,
    required this.citationChains,
    required this.echoChambers,
    required this.trackedAt,
  });
}

// ═══════════════════════════════════════════════════════════════
// TOOL 3: POWER NETWORK ANALYZER
// ═══════════════════════════════════════════════════════════════

enum ActorType {
  state,
  corporation,
  intelligence,
  society,
  individual,
}

class PowerActor {
  final String id;
  final String name;
  final ActorType type;
  final List<String> connections;
  final double influenceScore; // 0-100
  final bool isSilent; // "stiller Akteur"

  PowerActor({
    required this.id,
    required this.name,
    required this.type,
    required this.connections,
    required this.influenceScore,
    this.isSilent = false,
  });
}

class InfluenceZone {
  final String id;
  final String name;
  final List<String> actorIds;
  final double controlDegree; // 0-100

  InfluenceZone({
    required this.id,
    required this.name,
    required this.actorIds,
    required this.controlDegree,
  });
}

class PowerNetworkResult {
  final List<PowerActor> actors;
  final Map<String, List<String>> connections;
  final List<InfluenceZone> zones;
  final List<String> silentActors;
  final DateTime analyzedAt;

  PowerNetworkResult({
    required this.actors,
    required this.connections,
    required this.zones,
    required this.silentActors,
    required this.analyzedAt,
  });
}

// ═══════════════════════════════════════════════════════════════
// TOOL 4: NARRATIVE & PSYOPS ANALYZER
// ═══════════════════════════════════════════════════════════════

class LanguagePattern {
  final String pattern;
  final double frequency; // 0-1
  final List<String> examples;

  LanguagePattern({
    required this.pattern,
    required this.frequency,
    required this.examples,
  });
}

class EmotionalTrigger {
  final String trigger;
  final String emotion;
  final double intensity; // 0-1

  EmotionalTrigger({
    required this.trigger,
    required this.emotion,
    required this.intensity,
  });
}

class PolarizationMechanism {
  final String mechanism;
  final String description;
  final double effectStrength; // 0-1

  PolarizationMechanism({
    required this.mechanism,
    required this.description,
    required this.effectStrength,
  });
}

class NarrativeAnalysisResult {
  final List<LanguagePattern> patterns;
  final List<EmotionalTrigger> triggers;
  final List<PolarizationMechanism> mechanisms;
  final double overallManipulationScore; // 0-100
  final DateTime analyzedAt;

  NarrativeAnalysisResult({
    required this.patterns,
    required this.triggers,
    required this.mechanisms,
    required this.overallManipulationScore,
    required this.analyzedAt,
  });
}

// ═══════════════════════════════════════════════════════════════
// TOOL 5: TEMPORAL TRUTH ANALYZER
// ═══════════════════════════════════════════════════════════════

class NarrativeSnapshot {
  final DateTime timestamp;
  final String officialVersion;
  final String alternativeVersion;
  final List<String> forgottenInfo;

  NarrativeSnapshot({
    required this.timestamp,
    required this.officialVersion,
    required this.alternativeVersion,
    required this.forgottenInfo,
  });
}

class TemporalAnalysisResult {
  final List<NarrativeSnapshot> timeline;
  final Map<String, int> versionChanges;
  final List<String> suppressedFacts;
  final DateTime analyzedAt;

  TemporalAnalysisResult({
    required this.timeline,
    required this.versionChanges,
    required this.suppressedFacts,
    required this.analyzedAt,
  });
}

// ═══════════════════════════════════════════════════════════════
// TOOL 6: ANCIENT KNOWLEDGE CORRELATOR
// ═══════════════════════════════════════════════════════════════

class AncientKnowledge {
  final String id;
  final String name;
  final String origin;
  final String originalPurpose;
  final String modernApplication;
  final double purposeShift; // 0-1

  AncientKnowledge({
    required this.id,
    required this.name,
    required this.origin,
    required this.originalPurpose,
    required this.modernApplication,
    required this.purposeShift,
  });
}

class KnowledgeCorrelationResult {
  final List<AncientKnowledge> knowledge;
  final Map<String, List<String>> modernConnections;
  final DateTime analyzedAt;

  KnowledgeCorrelationResult({
    required this.knowledge,
    required this.modernConnections,
    required this.analyzedAt,
  });
}

// ═══════════════════════════════════════════════════════════════
// TOOL 7: PATTERN & OVERLAP DETECTOR
// ═══════════════════════════════════════════════════════════════

class RecurringPattern {
  final String id;
  final String name;
  final List<String> occurrences;
  final double patternScore; // 0-1
  final List<String> methods;

  RecurringPattern({
    required this.id,
    required this.name,
    required this.occurrences,
    required this.patternScore,
    required this.methods,
  });
}

class PatternDetectionResult {
  final List<RecurringPattern> patterns;
  final Map<String, List<String>> overlaps;
  final DateTime analyzedAt;

  PatternDetectionResult({
    required this.patterns,
    required this.overlaps,
    required this.analyzedAt,
  });
}

// ═══════════════════════════════════════════════════════════════
// TOOL 8: BELIEF & GROUP DYNAMICS ANALYZER
// ═══════════════════════════════════════════════════════════════

class BeliefMechanism {
  final String mechanism;
  final String psychologicalBasis;
  final double strength; // 0-1

  BeliefMechanism({
    required this.mechanism,
    required this.psychologicalBasis,
    required this.strength,
  });
}

class GroupDynamic {
  final String dynamic;
  final String effect;
  final double intensity; // 0-1

  GroupDynamic({
    required this.dynamic,
    required this.effect,
    required this.intensity,
  });
}

class BeliefAnalysisResult {
  final List<BeliefMechanism> mechanisms;
  final List<GroupDynamic> dynamics;
  final double radicalizationPotential; // 0-100
  final DateTime analyzedAt;

  BeliefAnalysisResult({
    required this.mechanisms,
    required this.dynamics,
    required this.radicalizationPotential,
    required this.analyzedAt,
  });
}

// ═══════════════════════════════════════════════════════════════
// TOOL 9: SYSTEM OVERLAY ENGINE
// ═══════════════════════════════════════════════════════════════

class SystemLayer {
  final String name;
  final String powerLogic;
  final String narrative;
  final List<String> methods;

  SystemLayer({
    required this.name,
    required this.powerLogic,
    required this.narrative,
    required this.methods,
  });
}

class SystemOverlayResult {
  final List<SystemLayer> layers;
  final Map<String, List<String>> sharedMethods;
  final List<String> narrativeDifferences;
  final DateTime analyzedAt;

  SystemOverlayResult({
    required this.layers,
    required this.sharedMethods,
    required this.narrativeDifferences,
    required this.analyzedAt,
  });
}

// ═══════════════════════════════════════════════════════════════
// TOOL 10: HYPOTHESIS TEST LAB
// ═══════════════════════════════════════════════════════════════

class Hypothesis {
  final String id;
  final String hypothesis;
  final List<String> proEvidence;
  final List<String> contraEvidence;
  final double uncertaintyDegree; // 0-1
  final String generationMethod;

  Hypothesis({
    required this.id,
    required this.hypothesis,
    required this.proEvidence,
    required this.contraEvidence,
    required this.uncertaintyDegree,
    required this.generationMethod,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'hypothesis': hypothesis,
    'proEvidence': proEvidence,
    'contraEvidence': contraEvidence,
    'uncertaintyDegree': uncertaintyDegree,
    'generationMethod': generationMethod,
  };
}

class HypothesisTestResult {
  final List<Hypothesis> hypotheses;
  final DateTime testedAt;

  HypothesisTestResult({
    required this.hypotheses,
    required this.testedAt,
  });
}
