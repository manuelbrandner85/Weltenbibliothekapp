/// Geheimes-Tools Berechnungs-Engines
/// 9 analytische System-Tools
/// Version: 1.0.0
library;

import '../models/secret_systems_models.dart';

class SecretSystemsEngine {
  // ═══════════════════════════════════════════════════════════════
  // TOOL 1: ORGANISATIONS-EXPLORER
  // ═══════════════════════════════════════════════════════════════

  static List<Organization> getAllOrganizations() {
    return [
      Organization(
        id: 'org1',
        name: 'Freimaurerei',
        epoch: '1717-heute',
        region: 'Europa/Global',
        structureType: StructureType.hierarchical,
        networkForm: 'Logen-Netzwerk',
        accessLogic: AccessLogic.recommendation,
        stabilityMechanism: 'Grad-System + Rituale',
        symbolDensity: 0.9,
        metadata: {
          'foundingYear': 1717,
          'estimatedMembers': 6000000,
        },
      ),
      
      Organization(
        id: 'org2',
        name: 'Rosenkreuzer',
        epoch: '1614-heute',
        region: 'Europa',
        structureType: StructureType.networked,
        networkForm: 'Dezentrale Zirkel',
        accessLogic: AccessLogic.invitation,
        stabilityMechanism: 'Geheimhaltung + Symbolik',
        symbolDensity: 0.95,
        metadata: {
          'foundingYear': 1614,
          'estimatedMembers': 250000,
        },
      ),
      
      Organization(
        id: 'org3',
        name: 'Skull & Bones',
        epoch: '1832-heute',
        region: 'USA',
        structureType: StructureType.cellular,
        networkForm: 'Jahrgangskohorten',
        accessLogic: AccessLogic.invitation,
        stabilityMechanism: 'Elite-Bindung + Netzwerk',
        symbolDensity: 0.7,
        metadata: {
          'foundingYear': 1832,
          'estimatedMembers': 800,
        },
      ),
      
      Organization(
        id: 'org4',
        name: 'Illuminatenorden (hist.)',
        epoch: '1776-1785',
        region: 'Bayern',
        structureType: StructureType.hierarchical,
        networkForm: 'Pyramidale Struktur',
        accessLogic: AccessLogic.examination,
        stabilityMechanism: 'Informationskontrolle',
        symbolDensity: 0.85,
        metadata: {
          'foundingYear': 1776,
          'dissolutionYear': 1785,
        },
      ),
      
      Organization(
        id: 'org5',
        name: 'Tempelritter (hist.)',
        epoch: '1119-1312',
        region: 'Europa/Naher Osten',
        structureType: StructureType.hierarchical,
        networkForm: 'Militär-Orden',
        accessLogic: AccessLogic.recommendation,
        stabilityMechanism: 'Gelübde + Hierarchie',
        symbolDensity: 0.8,
        metadata: {
          'foundingYear': 1119,
          'dissolutionYear': 1312,
        },
      ),
    ];
  }

  static OrganizationComparison compareOrganizations(List<String> organizationIds) {
    final allOrgs = getAllOrganizations();
    final selected = allOrgs.where((org) => organizationIds.contains(org.id)).toList();
    
    final commonalities = <String, List<String>>{
      'Strukturtypen': selected.map((o) => o.structureType.toString()).toSet().toList(),
      'Zugangsmechanismen': selected.map((o) => o.accessLogic.toString()).toSet().toList(),
      'Epochen': selected.map((o) => o.epoch).toSet().toList(),
    };
    
    final differences = <String, List<String>>{
      'Symbol-Dichte': selected.map((o) => '${o.name}: ${(o.symbolDensity * 100).toInt()}%').toList(),
      'Netzwerkformen': selected.map((o) => '${o.name}: ${o.networkForm}').toList(),
    };
    
    return OrganizationComparison(
      organizations: selected,
      commonalities: commonalities,
      differences: differences,
      generatedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOOL 2: GRAD- & ROLLEN-ANALYZER
  // ═══════════════════════════════════════════════════════════════

  static DegreeSystem analyzeDegreeSystem(String organizationId) {
    final degrees = <DegreeNode>[
      DegreeNode(
        id: 'deg1',
        name: 'Lehrling',
        level: 1,
        function: 'Aufnahme, Grundlagen erlernen',
        psychologicalEffect: 'Erwartung, Zugehörigkeitsgefühl',
        systemRole: 'Basis-Ebene, Filter',
        childIds: ['deg2'],
      ),
      
      DegreeNode(
        id: 'deg2',
        name: 'Geselle',
        level: 2,
        function: 'Vertiefung, Praktische Arbeit',
        psychologicalEffect: 'Fortschritt, Kompetenz',
        systemRole: 'Mittlere Ebene, Multiplikatoren',
        childIds: ['deg3'],
      ),
      
      DegreeNode(
        id: 'deg3',
        name: 'Meister',
        level: 3,
        function: 'Vollmitgliedschaft, Lehrberechtigung',
        psychologicalEffect: 'Status, Verantwortung',
        systemRole: 'Obere Ebene, Entscheidungsträger',
        childIds: ['deg4'],
      ),
      
      DegreeNode(
        id: 'deg4',
        name: 'Hochgrade',
        level: 4,
        function: 'Spezialisierung, Führung',
        psychologicalEffect: 'Exklusivität, Macht',
        systemRole: 'Elite-Ebene, Strategie',
        childIds: [],
      ),
    ];
    
    final hierarchy = <String, List<String>>{
      'deg1': ['deg2'],
      'deg2': ['deg3'],
      'deg3': ['deg4'],
      'deg4': [],
    };
    
    return DegreeSystem(
      organizationId: organizationId,
      systemName: 'Freimaurerisches Grad-System',
      degrees: degrees,
      hierarchy: hierarchy,
      analyzedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOOL 3: SYMBOL- & ZEICHEN-MAPPER
  // ═══════════════════════════════════════════════════════════════

  static SymbolMapResult buildSymbolMap() {
    final symbols = <Symbol>[
      Symbol(
        id: 'sym1',
        name: 'Auge der Vorsehung',
        visualDescription: 'Auge in Dreieck mit Strahlen',
        meaningsByLayer: {
          SymbolLayer.public: 'Göttliche Vorsehung',
          SymbolLayer.internal: 'Allsehende Beobachtung',
          SymbolLayer.archetypal: 'Bewusstsein, Erkenntnis',
        },
        organizationIds: ['org1', 'org4'],
      ),
      
      Symbol(
        id: 'sym2',
        name: 'Zirkel und Winkel',
        visualDescription: 'Gekreuzte geometrische Werkzeuge',
        meaningsByLayer: {
          SymbolLayer.public: 'Baumeister-Tradition',
          SymbolLayer.internal: 'Ordnung und Präzision',
          SymbolLayer.archetypal: 'Struktur vs. Chaos',
        },
        organizationIds: ['org1'],
      ),
      
      Symbol(
        id: 'sym3',
        name: 'Rose + Kreuz',
        visualDescription: 'Rose am Kreuz',
        meaningsByLayer: {
          SymbolLayer.public: 'Christliche Mystik',
          SymbolLayer.internal: 'Transformation',
          SymbolLayer.archetypal: 'Leiden → Erleuchtung',
        },
        organizationIds: ['org2'],
      ),
      
      Symbol(
        id: 'sym4',
        name: 'Totenkopf + Knochen',
        visualDescription: 'Schädel mit gekreuzten Knochen',
        meaningsByLayer: {
          SymbolLayer.public: 'Sterblichkeit',
          SymbolLayer.internal: 'Memento Mori, Elite-Bindung',
          SymbolLayer.archetypal: 'Tod als Transformation',
        },
        organizationIds: ['org3'],
      ),
      
      Symbol(
        id: 'sym5',
        name: 'Eule der Minerva',
        visualDescription: 'Eule auf Buch',
        meaningsByLayer: {
          SymbolLayer.public: 'Weisheit',
          SymbolLayer.internal: 'Wissen als Macht',
          SymbolLayer.archetypal: 'Nächtliches Sehen',
        },
        organizationIds: ['org4'],
      ),
    ];
    
    final symbolToOrganizations = <String, List<String>>{};
    final organizationToSymbols = <String, List<String>>{};
    
    for (final symbol in symbols) {
      symbolToOrganizations[symbol.id] = symbol.organizationIds;
      for (final orgId in symbol.organizationIds) {
        organizationToSymbols.putIfAbsent(orgId, () => []);
        organizationToSymbols[orgId]!.add(symbol.id);
      }
    }
    
    return SymbolMapResult(
      symbols: symbols,
      symbolToOrganizations: symbolToOrganizations,
      organizationToSymbols: organizationToSymbols,
      generatedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOOL 4: SYSTEMARCHITEKTUR-ANALYZER
  // ═══════════════════════════════════════════════════════════════

  static SystemArchitecture analyzeSystemArchitecture(String organizationId) {
    return SystemArchitecture(
      organizationId: organizationId,
      powerDistribution: PowerDistribution.vertical,
      informationFlow: {
        'Basis → Mitte': 0.3,
        'Mitte → Spitze': 0.6,
        'Spitze → Mitte': 0.4,
        'Mitte → Basis': 0.2,
      },
      filterMechanisms: [
        'Grad-Aufstieg verzögert',
        'Geheimhaltungspflichten',
        'Informations-Dosierung',
        'Rituelle Barrieren',
      ],
      loyaltyAnchors: [
        'Gemeinsame Geheimnisse',
        'Status-Investition',
        'Soziales Netzwerk',
        'Rituelle Bindung',
      ],
      selfStabilization: [
        'Selbstverstärkende Symbolik',
        'Mythos-Produktion',
        'Externe Kritik → Interne Stärkung',
        'Generationenübergreifend',
      ],
      heatmapData: {
        'Informationszugang': [20, 40, 60, 80, 100],
        'Entscheidungsmacht': [10, 30, 50, 70, 95],
        'Geheimwissen': [5, 25, 45, 75, 100],
      },
      analyzedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOOL 5: NETZWERK-VISUALIZER
  // ═══════════════════════════════════════════════════════════════

  static NetworkGraph buildNetworkGraph() {
    final nodes = <NetworkNode>[
      NetworkNode(
        id: 'org1',
        label: 'Freimaurerei',
        type: NodeType.organization,
        connections: ['sym1', 'sym2', 'arch1'],
      ),
      NetworkNode(
        id: 'org2',
        label: 'Rosenkreuzer',
        type: NodeType.organization,
        connections: ['sym3', 'arch1'],
      ),
      NetworkNode(
        id: 'sym1',
        label: 'Auge der Vorsehung',
        type: NodeType.symbol,
        connections: ['org1', 'org4', 'arch4'],
      ),
      NetworkNode(
        id: 'arch1',
        label: 'Sucher',
        type: NodeType.archetype,
        connections: ['org1', 'org2', 'org4'],
      ),
      NetworkNode(
        id: 'time1',
        label: '18. Jahrhundert',
        type: NodeType.timeframe,
        connections: ['org1', 'org4'],
      ),
    ];
    
    final edges = <String, List<String>>{};
    for (final node in nodes) {
      edges[node.id] = node.connections;
    }
    
    final clusters = <NetworkCluster>[
      NetworkCluster(
        id: 'cluster1',
        name: 'Aufklärung-Cluster',
        nodeIds: ['org1', 'org4', 'time1'],
        density: 0.8,
      ),
      NetworkCluster(
        id: 'cluster2',
        name: 'Mystik-Cluster',
        nodeIds: ['org2', 'sym3', 'arch1'],
        density: 0.7,
      ),
    ];
    
    return NetworkGraph(
      nodes: nodes,
      edges: edges,
      clusters: clusters,
      generatedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOOL 6: PSYCHOLOGISCHE WIRKUNG-ENGINE
  // ═══════════════════════════════════════════════════════════════

  static PsychologicalOutput analyzePsychologicalEffect(PsychologicalInput input) {
    double bindingStrength = 0;
    double identityShift = 0;
    double dependencyPotential = 0;
    double stabilityDegree = 0;
    
    // Berechnung basierend auf Inputs
    switch (input.structureType) {
      case StructureType.hierarchical:
        bindingStrength += 30;
        identityShift += 40;
        break;
      case StructureType.networked:
        bindingStrength += 20;
        identityShift += 25;
        break;
      case StructureType.cellular:
        bindingStrength += 25;
        identityShift += 35;
        break;
      case StructureType.hybrid:
        bindingStrength += 28;
        identityShift += 30;
        break;
    }
    
    bindingStrength += input.symbolDensity * 40;
    identityShift += input.symbolDensity * 30;
    dependencyPotential = (input.groupStrength / 100) * 60 + (input.symbolDensity * 40);
    stabilityDegree = (input.repetitionDegree / 10) * 50 + bindingStrength * 0.5;
    
    return PsychologicalOutput(
      bindingStrength: bindingStrength.clamp(0, 100),
      identityShift: identityShift.clamp(0, 100),
      dependencyPotential: dependencyPotential.clamp(0, 100),
      stabilityDegree: stabilityDegree.clamp(0, 100),
      analysis: {
        'Bindung': bindingStrength > 70 ? 'Stark' : bindingStrength > 40 ? 'Mittel' : 'Schwach',
        'Identität': identityShift > 70 ? 'Hoch' : identityShift > 40 ? 'Mittel' : 'Gering',
        'Abhängigkeit': dependencyPotential > 70 ? 'Hoch' : dependencyPotential > 40 ? 'Mittel' : 'Gering',
        'Stabilität': stabilityDegree > 70 ? 'Sehr stabil' : stabilityDegree > 40 ? 'Stabil' : 'Instabil',
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOOL 7: ARCHETYP-ENGINE
  // ═══════════════════════════════════════════════════════════════

  static ArchetypeComparison analyzeArchetype(Archetype archetype) {
    final roles = <ArchetypeRole>[
      ArchetypeRole(
        roleId: 'role1',
        roleName: 'Lehrling',
        archetype: Archetype.seeker,
        organizationIds: ['org1', 'org2'],
        traits: ['Wissensdurst', 'Offenheit', 'Unsicherheit'],
      ),
      ArchetypeRole(
        roleId: 'role2',
        roleName: 'Großmeister',
        archetype: Archetype.guardian,
        organizationIds: ['org1'],
        traits: ['Bewahrung', 'Autorität', 'Kontinuität'],
      ),
      ArchetypeRole(
        roleId: 'role3',
        roleName: 'Geselle',
        archetype: Archetype.builder,
        organizationIds: ['org1'],
        traits: ['Umsetzung', 'Praktisch', 'Vermittlung'],
      ),
    ];
    
    final filtered = roles.where((r) => r.archetype == archetype).toList();
    
    return ArchetypeComparison(
      archetype: archetype,
      roles: filtered,
      crossSystemPatterns: {
        'Gemeinsame Funktionen': ['Systemerhalt', 'Wissensweitergabe'],
        'Psychologische Muster': ['Identitätsbildung', 'Rollenfixierung'],
      },
      analyzedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOOL 8: ENTHÜLLUNGS-PATTERN-DETECTOR
  // ═══════════════════════════════════════════════════════════════

  static RevelationPattern analyzeRevelationPatterns() {
    final events = <RevelationEvent>[
      RevelationEvent(
        id: 'rev1',
        organizationId: 'org1',
        date: DateTime(1826),
        content: 'Morgan-Affäre: Enthüllung freimaurerischer Rituale',
        reaction: SystemReaction.mystification,
        mysticismIncrease: 45,
        resilienceScore: 85,
        narrativeIntegration: ['Verschwörungstheorien verstärkt', 'Öffentliches Interesse gesteigert'],
      ),
      RevelationEvent(
        id: 'rev2',
        organizationId: 'org3',
        date: DateTime(2004),
        content: 'Skull & Bones Gebäude-Bilder veröffentlicht',
        reaction: SystemReaction.silence,
        mysticismIncrease: 30,
        resilienceScore: 90,
        narrativeIntegration: ['Schweigen verstärkt Mystik', 'Keine Dementi'],
      ),
      RevelationEvent(
        id: 'rev3',
        organizationId: 'org1',
        date: DateTime(1984),
        content: 'P2-Loge Skandal',
        reaction: SystemReaction.deflection,
        mysticismIncrease: 55,
        resilienceScore: 70,
        narrativeIntegration: ['Einzelfall-Narrativ', 'Systemtrennung'],
      ),
    ];
    
    final reactionFrequency = <SystemReaction, int>{};
    for (final event in events) {
      reactionFrequency[event.reaction] = (reactionFrequency[event.reaction] ?? 0) + 1;
    }
    
    final avgResilience = events.map((e) => e.resilienceScore).reduce((a, b) => a + b) / events.length;
    
    return RevelationPattern(
      events: events,
      reactionFrequency: reactionFrequency,
      avgResilienceScore: avgResilience,
      analyzedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOOL 9: GEOMETRIE- & RAUM-ANALYZER
  // ═══════════════════════════════════════════════════════════════

  static SpatialStructure analyzeGeometry(String organizationId) {
    final geometricElements = <GeometricEffect>[
      GeometricEffect(
        form: GeometricForm.circle,
        psychologicalEffect: 'Einheit, Geschlossenheit',
        perceptionShift: 'Zentripetal, Fokussierung',
        stabilityFactor: 0.8,
      ),
      GeometricEffect(
        form: GeometricForm.triangle,
        psychologicalEffect: 'Hierarchie, Richtung',
        perceptionShift: 'Vertikal, Aufstrebend',
        stabilityFactor: 0.9,
      ),
      GeometricEffect(
        form: GeometricForm.square,
        psychologicalEffect: 'Ordnung, Stabilität',
        perceptionShift: 'Horizontal, Ausgewogen',
        stabilityFactor: 0.85,
      ),
    ];
    
    return SpatialStructure(
      organizationId: organizationId,
      geometricElements: geometricElements,
      spacePerception: {
        'Raumaufbau': 'Konzentrisch mit Zentrum',
        'Wahrnehmung': 'Sakraler Raum, Schwellenüberschreitung',
        'Wiederholung': 'Rituelle Raumnutzung verstärkt Muster',
      },
      repetitionStability: 85,
      analyzedAt: DateTime.now(),
    );
  }
}
