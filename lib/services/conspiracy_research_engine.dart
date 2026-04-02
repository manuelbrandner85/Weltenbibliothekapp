/// Conspiracy Research Engine
/// 10 automatische Analyse-Tools
/// Version: 1.0.0
library;

import 'package:flutter/material.dart' show Color;
import '../models/conspiracy_research_models.dart';

class ConspiracyResearchEngine {
  // ═══════════════════════════════════════════════════════════════
  // VORDEFINIERTE THEMEN
  // ═══════════════════════════════════════════════════════════════

  static List<ResearchTopic> getAllTopics() {
    return [
      ResearchTopic(
        theme: ResearchTheme.secretPrograms,
        title: 'Geheime Programme & Experimente',
        icon: '🧠',
        color: const Color(0xFF9C27B0),
        keywords: ['MK-Ultra', 'COINTELPRO', 'Human Experiments', 'Mind Control'],
        activeToolIndices: [0, 1, 2, 4, 7, 9], // Welche Tools aktiviert werden
      ),
      
      ResearchTopic(
        theme: ResearchTheme.secretSocieties,
        title: 'Geheimgesellschaften & Elitennetzwerke',
        icon: '🕸️',
        color: const Color(0xFF673AB7),
        keywords: ['Freimaurer', 'Illuminati', 'Bilderberg', 'Skull & Bones'],
        activeToolIndices: [0, 2, 5, 6, 8],
      ),
      
      ResearchTopic(
        theme: ResearchTheme.powerStructures,
        title: 'Globale Machtstrukturen',
        icon: '🌍',
        color: const Color(0xFF3F51B5),
        keywords: ['Weltbank', 'IMF', 'Konzerne', 'Lobbyismus'],
        activeToolIndices: [2, 3, 6, 8, 9],
      ),
      
      ResearchTopic(
        theme: ResearchTheme.mediaNarratives,
        title: 'Medien, Narrative & PsyOps',
        icon: '📰',
        color: const Color(0xFF2196F3),
        keywords: ['Propaganda', 'Operation Mockingbird', 'Nudging'],
        activeToolIndices: [1, 3, 4, 7, 9],
      ),
      
      ResearchTopic(
        theme: ResearchTheme.ancientKnowledge,
        title: 'Altes & verdrängtes Wissen',
        icon: '📜',
        color: const Color(0xFF00BCD4),
        keywords: ['Hermetik', 'Alchemie', 'Geomantie', 'Symbolik'],
        activeToolIndices: [5, 6, 8],
      ),
      
      ResearchTopic(
        theme: ResearchTheme.crisesWars,
        title: 'Krisen, Kriege & Umbrüche',
        icon: '⚔️',
        color: const Color(0xFFF44336),
        keywords: ['9/11', 'Gulf of Tonkin', 'False Flags', 'Pandemien'],
        activeToolIndices: [0, 1, 3, 4, 7, 9],
      ),
      
      ResearchTopic(
        theme: ResearchTheme.controlMechanisms,
        title: 'Mensch & Kontrolle',
        icon: '🧬',
        color: const Color(0xFFFF9800),
        keywords: ['Massenpsychologie', 'Überwachung', 'Social Engineering'],
        activeToolIndices: [3, 7, 8, 9],
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════════
  // TOOL 1: CONSPIRACY DEEP SCANNER
  // ═══════════════════════════════════════════════════════════════

  static DeepScanResult runDeepScan(ResearchTheme theme) {
    // MK-Ultra Beispiel
    final claims = <ConspiracyClaim>[
      ConspiracyClaim(
        id: 'claim1',
        claim: 'CIA führte Bewusstseinskontroll-Experimente durch',
        type: ClaimType.factual,
        actors: ['CIA', 'Dr. Sidney Gottlieb', 'MKULTRA Scientists'],
        motives: ['Militärische Überlegenheit', 'Verhörtechniken', 'Agentenkontrolle'],
        evidence: {
          'Church Committee Report (1975)': 'Offizielle Bestätigung',
          'FOIA Documents': '20,000 freigegebene Seiten',
          'Survivor Testimonies': 'Mehrere Zeugenaussagen',
        },
      ),
      
      ConspiracyClaim(
        id: 'claim2',
        claim: 'LSD wurde ohne Wissen an Zivilisten getestet',
        type: ClaimType.factual,
        actors: ['CIA', 'Militär', 'Psychiatrische Kliniken'],
        motives: ['Waffen-Entwicklung', 'Verh Ortstechniken'],
        evidence: {
          'Frank Olson Fall': 'CIA-Wissenschaftler starb nach unwissentlicher LSD-Gabe',
          'Operation Midnight Climax': 'Bordell-basierte Tests dokumentiert',
        },
      ),
      
      ConspiracyClaim(
        id: 'claim3',
        claim: 'Monarch Programming schuf „Schläfer-Agenten"',
        type: ClaimType.speculative,
        actors: ['CIA (behauptet)', 'Trauma-Spezialisten (behauptet)'],
        motives: ['Perfekte Kontrolle', 'Deniable Assets'],
        evidence: {
          'Survivor Claims': 'Nicht verifizierbar',
          'Pop Culture References': 'Zahlreiche Filme/Bücher',
          'MKULTRA Sub-Projects': 'Trauma-basierte Forschung dokumentiert, aber kein "Monarch"',
        },
      ),
      
      ConspiracyClaim(
        id: 'claim4',
        claim: 'Programm wurde 1973 vollständig beendet',
        type: ClaimType.contradictory,
        actors: ['CIA (offiziell)', 'Kritiker (inoffiziell)'],
        motives: ['Schadensbegrenzung vs. Programm-Fortsetzung'],
        evidence: {
          'Pro': 'CIA-Direktor ordnete Aktenvernichtung an (1973)',
          'Contra': 'Wissen blieb, neue Programme mit anderen Namen möglich',
        },
      ),
    ];
    
    final distribution = <ClaimType, int>{
      ClaimType.factual: claims.where((c) => c.type == ClaimType.factual).length,
      ClaimType.speculative: claims.where((c) => c.type == ClaimType.speculative).length,
      ClaimType.contradictory: claims.where((c) => c.type == ClaimType.contradictory).length,
    };
    
    final contradictions = <String>[
      'CIA bestätigt Programm, aber bestreitet fortgesetzte Nutzung',
      'Dokumentierte Tests vs. Behauptung ethischer Grenzen',
      'Aktenvernichtung vs. spätere FOIA-Freigaben',
    ];
    
    return DeepScanResult(
      theme: theme,
      claims: claims,
      distribution: distribution,
      contradictions: contradictions,
      scannedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOOL 2: SOURCE & ORIGIN TRACKER
  // ═══════════════════════════════════════════════════════════════

  static OriginTrackingResult trackOrigins(ResearchTheme theme) {
    final sources = <SourceNode>[
      SourceNode(
        id: 'src1',
        title: 'Church Committee Report (1975)',
        publishDate: DateTime(1975, 4, 26),
        author: 'US Senate Select Committee',
        citationCount: 847,
        citedBy: ['src2', 'src3', 'src5'],
        agendaScore: 0.2,
      ),
      
      SourceNode(
        id: 'src2',
        title: 'The Search for the Manchurian Candidate (1979)',
        publishDate: DateTime(1979, 1, 1),
        author: 'John Marks',
        citationCount: 523,
        citedBy: ['src4', 'src6'],
        agendaScore: 0.4,
      ),
      
      SourceNode(
        id: 'src3',
        title: 'FOIA Documents Release (1977)',
        publishDate: DateTime(1977, 8, 3),
        author: 'CIA',
        citationCount: 1203,
        citedBy: ['src2', 'src4', 'src5', 'src6'],
        agendaScore: 0.3,
      ),
      
      SourceNode(
        id: 'src4',
        title: 'Mind Control Blog Post',
        publishDate: DateTime(2015, 3, 12),
        author: 'Anonymous Blogger',
        citationCount: 67,
        citedBy: [],
        agendaScore: 0.85,
      ),
      
      SourceNode(
        id: 'src5',
        title: 'Academic Paper: MKULTRA Ethics',
        publishDate: DateTime(2010, 6, 15),
        author: 'Dr. Research',
        citationCount: 234,
        citedBy: ['src6'],
        agendaScore: 0.1,
      ),
      
      SourceNode(
        id: 'src6',
        title: 'Conspiracy Documentary',
        publishDate: DateTime(2020, 11, 5),
        author: 'Documentary Filmmaker',
        citationCount: 892,
        citedBy: [],
        agendaScore: 0.75,
      ),
    ];
    
    final citationChains = <String, List<String>>{
      'src1 → src2 → src4': ['src1', 'src2', 'src4'],
      'src3 → src2 → src6': ['src3', 'src2', 'src6'],
      'src3 → src5 → src6': ['src3', 'src5', 'src6'],
    };
    
    final echoChambers = <EchoChamber>[
      EchoChamber(
        id: 'echo1',
        sourceIds: ['src4', 'src6'],
        isolationScore: 0.75,
        sharedNarratives: ['Mind Control continues', 'Government cover-up'],
      ),
      EchoChamber(
        id: 'echo2',
        sourceIds: ['src1', 'src5'],
        isolationScore: 0.3,
        sharedNarratives: ['Historical documentation', 'Ethical violations confirmed'],
      ),
    ];
    
    return OriginTrackingResult(
      sources: sources,
      citationChains: citationChains,
      echoChambers: echoChambers,
      trackedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOOL 3: POWER NETWORK ANALYZER
  // ═══════════════════════════════════════════════════════════════

  static PowerNetworkResult analyzePowerNetwork(ResearchTheme theme) {
    final actors = <PowerActor>[
      PowerActor(
        id: 'act1',
        name: 'CIA',
        type: ActorType.intelligence,
        connections: ['act2', 'act3', 'act5'],
        influenceScore: 95,
        isSilent: false,
      ),
      
      PowerActor(
        id: 'act2',
        name: 'US Military',
        type: ActorType.state,
        connections: ['act1', 'act4'],
        influenceScore: 90,
        isSilent: false,
      ),
      
      PowerActor(
        id: 'act3',
        name: 'Pharmaceutical Companies',
        type: ActorType.corporation,
        connections: ['act1', 'act6'],
        influenceScore: 70,
        isSilent: true,
      ),
      
      PowerActor(
        id: 'act4',
        name: 'University Research Labs',
        type: ActorType.corporation,
        connections: ['act2', 'act5'],
        influenceScore: 55,
        isSilent: true,
      ),
      
      PowerActor(
        id: 'act5',
        name: 'Private Contractors',
        type: ActorType.corporation,
        connections: ['act1', 'act4'],
        influenceScore: 60,
        isSilent: true,
      ),
      
      PowerActor(
        id: 'act6',
        name: 'Media Outlets',
        type: ActorType.corporation,
        connections: ['act3'],
        influenceScore: 50,
        isSilent: false,
      ),
    ];
    
    final connections = <String, List<String>>{};
    for (final actor in actors) {
      connections[actor.id] = actor.connections;
    }
    
    final zones = <InfluenceZone>[
      InfluenceZone(
        id: 'zone1',
        name: 'Intelligence-Military Complex',
        actorIds: ['act1', 'act2'],
        controlDegree: 95,
      ),
      InfluenceZone(
        id: 'zone2',
        name: 'Research-Pharma Axis',
        actorIds: ['act3', 'act4', 'act5'],
        controlDegree: 65,
      ),
    ];
    
    final silentActors = actors.where((a) => a.isSilent).map((a) => a.name).toList();
    
    return PowerNetworkResult(
      actors: actors,
      connections: connections,
      zones: zones,
      silentActors: silentActors,
      analyzedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOOL 4: NARRATIVE & PSYOPS ANALYZER
  // ═══════════════════════════════════════════════════════════════

  static NarrativeAnalysisResult analyzeNarrative(ResearchTheme theme) {
    final patterns = <LanguagePattern>[
      LanguagePattern(
        pattern: 'Sicherheit vs. Freiheit',
        frequency: 0.85,
        examples: [
          '"Zum Schutz der Bürger notwendig"',
          '"Bedauerliche, aber unvermeidbare Maßnahmen"',
        ],
      ),
      
      LanguagePattern(
        pattern: 'Einzelfall-Framing',
        frequency: 0.65,
        examples: [
          '"Wenige Ausnahmen"',
          '"Nicht repräsentativ für das Programm"',
        ],
      ),
      
      LanguagePattern(
        pattern: 'Zeitliche Distanzierung',
        frequency: 0.75,
        examples: [
          '"Das war damals, heute gelten andere Standards"',
          '"Historischer Kontext muss beachtet werden"',
        ],
      ),
    ];
    
    final triggers = <EmotionalTrigger>[
      EmotionalTrigger(
        trigger: 'Kalter Krieg Bedrohung',
        emotion: 'Angst',
        intensity: 0.9,
      ),
      
      EmotionalTrigger(
        trigger: 'Nationale Sicherheit',
        emotion: 'Patriotismus',
        intensity: 0.8,
      ),
      
      EmotionalTrigger(
        trigger: 'Opfer-Geschichten',
        emotion: 'Empörung',
        intensity: 0.85,
      ),
    ];
    
    final mechanisms = <PolarizationMechanism>[
      PolarizationMechanism(
        mechanism: 'Verschwörungstheorie-Label',
        description: 'Kritiker als "Verschwörungstheoretiker" abstempeln',
        effectStrength: 0.75,
      ),
      
      PolarizationMechanism(
        mechanism: 'Autoritäts-Appeal',
        description: '"Experten/Regierung wissen es besser"',
        effectStrength: 0.7,
      ),
      
      PolarizationMechanism(
        mechanism: 'False Dichotomy',
        description: '"Entweder du unterstützt uns, oder du hilfst dem Feind"',
        effectStrength: 0.8,
      ),
    ];
    
    final manipulationScore = (patterns.fold<double>(0, (sum, p) => sum + p.frequency) / patterns.length) * 100;
    
    return NarrativeAnalysisResult(
      patterns: patterns,
      triggers: triggers,
      mechanisms: mechanisms,
      overallManipulationScore: manipulationScore,
      analyzedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOOL 5: TEMPORAL TRUTH ANALYZER
  // ═══════════════════════════════════════════════════════════════
  
  static TemporalAnalysisResult analyzeTemporalTruth(ResearchTheme theme) {
    return TemporalAnalysisResult(
      timeline: [
        NarrativeSnapshot(
          timestamp: DateTime(1953),
          officialVersion: 'Keine Kommentare zu Geheimprogrammen',
          alternativeVersion: 'Gerüchte über Mind Control Experimente',
          forgottenInfo: [],
        ),
        NarrativeSnapshot(
          timestamp: DateTime(1975),
          officialVersion: 'Church Committee bestätigt MKULTRA',
          alternativeVersion: 'Nur Spitze des Eisbergs',
          forgottenInfo: ['Aktenvernichtung 1973'],
        ),
      ],
      versionChanges: {'Official': 3, 'Alternative': 5},
      suppressedFacts: ['Ausmaß der Opfer', 'Fortsetzung unter anderen Namen'],
      analyzedAt: DateTime.now(),
    );
  }

  static KnowledgeCorrelationResult correlateAncientKnowledge(ResearchTheme theme) {
    return KnowledgeCorrelationResult(
      knowledge: [
        AncientKnowledge(
          id: 'ak1',
          name: 'Hermetische Prinzipien',
          origin: 'Antikes Ägypten/Griechenland',
          originalPurpose: 'Spirituelle Transformation',
          modernApplication: 'Propaganda-Techniken, NLP',
          purposeShift: 0.85,
        ),
      ],
      modernConnections: {
        'Hermetik → Werbung': ['Suggestion', 'Symbolik'],
      },
      analyzedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOOL 7: PATTERN & OVERLAP DETECTOR
  // ═══════════════════════════════════════════════════════════════
  
  static PatternDetectionResult detectPatterns(ResearchTheme theme) {
    return PatternDetectionResult(
      patterns: [
        RecurringPattern(
          id: 'pat1',
          name: 'Deny → Admit → Minimize',
          occurrences: ['MKULTRA', 'Watergate', 'Iran-Contra'],
          patternScore: 0.9,
          methods: ['Initial Denial', 'Partial Admission', 'Downplay Impact'],
        ),
      ],
      overlaps: {
        'Pattern1 & Pattern2': ['Method A', 'Method B'],
      },
      analyzedAt: DateTime.now(),
    );
  }
  
  // Alias for consistency
  static PatternDetectionResult detectPatternOverlap(ResearchTheme theme) {
    return detectPatterns(theme);
  }

  static BeliefAnalysisResult analyzeBeliefDynamics(ResearchTheme theme) {
    return BeliefAnalysisResult(
      mechanisms: [
        BeliefMechanism(
          mechanism: 'Confirmation Bias',
          psychologicalBasis: 'Menschen suchen bestätigende Information',
          strength: 0.85,
        ),
      ],
      dynamics: [
        GroupDynamic(
          dynamic: 'In-Group Solidarität',
          effect: 'Verstärkung durch Gruppenzugehörigkeit',
          intensity: 0.75,
        ),
      ],
      radicalizationPotential: 65,
      analyzedAt: DateTime.now(),
    );
  }

  static SystemOverlayResult overlaySystemLayers(ResearchTheme theme) {
    return SystemOverlayResult(
      layers: [
        SystemLayer(
          name: 'Staat',
          powerLogic: 'Kontrolle durch Gesetze',
          narrative: 'Sicherheit und Ordnung',
          methods: ['Überwachung', 'Regulierung'],
        ),
        SystemLayer(
          name: 'Konzern',
          powerLogic: 'Kontrolle durch Märkte',
          narrative: 'Effizienz und Innovation',
          methods: ['Monopolisierung', 'Datensammlung'],
        ),
      ],
      sharedMethods: {
        'Informationskontrolle': ['Staat', 'Konzern', 'Geheimdienst'],
      },
      narrativeDifferences: ['Staat: Sicherheit', 'Konzern: Profit'],
      analyzedAt: DateTime.now(),
    );
  }

  static HypothesisTestResult testHypotheses(ResearchTheme theme) {
    return HypothesisTestResult(
      hypotheses: [
        Hypothesis(
          id: 'hyp1',
          hypothesis: 'MKULTRA-Methoden wurden unter neuen Namen fortgesetzt',
          proEvidence: [
            'Wissen blieb erhalten',
            'Neue Programme mit ähnlichen Zielen',
          ],
          contraEvidence: [
            'Keine direkten Beweise',
            'Ethische Standards heute strenger (offiziell)',
          ],
          uncertaintyDegree: 0.7,
          generationMethod: 'Pattern-basiert',
        ),
      ],
      testedAt: DateTime.now(),
    );
  }
}
