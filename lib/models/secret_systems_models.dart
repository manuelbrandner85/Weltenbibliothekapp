/// Geheimes-Tools Datenmodelle
/// 9 analytische System-Tools
/// Version: 1.0.0
library;


// ═══════════════════════════════════════════════════════════════
// TOOL 1: ORGANISATIONS-EXPLORER
// ═══════════════════════════════════════════════════════════════

enum StructureType {
  hierarchical,
  networked,
  cellular,
  hybrid,
}

enum AccessLogic {
  invitation,
  examination,
  recommendation,
  hereditary,
  purchase,
}

class Organization {
  final String id;
  final String name;
  final String epoch;
  final String region;
  final StructureType structureType;
  final String networkForm;
  final AccessLogic accessLogic;
  final String stabilityMechanism;
  final double symbolDensity; // 0-1
  final Map<String, dynamic> metadata;

  Organization({
    required this.id,
    required this.name,
    required this.epoch,
    required this.region,
    required this.structureType,
    required this.networkForm,
    required this.accessLogic,
    required this.stabilityMechanism,
    required this.symbolDensity,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'epoch': epoch,
    'region': region,
    'structureType': structureType.toString(),
    'networkForm': networkForm,
    'accessLogic': accessLogic.toString(),
    'stabilityMechanism': stabilityMechanism,
    'symbolDensity': symbolDensity,
    'metadata': metadata,
  };
}

class OrganizationComparison {
  final List<Organization> organizations;
  final Map<String, List<String>> commonalities;
  final Map<String, List<String>> differences;
  final DateTime generatedAt;

  OrganizationComparison({
    required this.organizations,
    required this.commonalities,
    required this.differences,
    required this.generatedAt,
  });
}

// ═══════════════════════════════════════════════════════════════
// TOOL 2: GRAD- & ROLLEN-ANALYZER
// ═══════════════════════════════════════════════════════════════

class DegreeNode {
  final String id;
  final String name;
  final int level;
  final String function;
  final String psychologicalEffect;
  final String systemRole;
  final List<String> childIds;
  final Map<String, dynamic> metadata;

  DegreeNode({
    required this.id,
    required this.name,
    required this.level,
    required this.function,
    required this.psychologicalEffect,
    required this.systemRole,
    this.childIds = const [],
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'level': level,
    'function': function,
    'psychologicalEffect': psychologicalEffect,
    'systemRole': systemRole,
    'childIds': childIds,
    'metadata': metadata,
  };
}

class DegreeSystem {
  final String organizationId;
  final String systemName;
  final List<DegreeNode> degrees;
  final Map<String, List<String>> hierarchy;
  final DateTime analyzedAt;

  DegreeSystem({
    required this.organizationId,
    required this.systemName,
    required this.degrees,
    required this.hierarchy,
    required this.analyzedAt,
  });
}

// ═══════════════════════════════════════════════════════════════
// TOOL 3: SYMBOL- & ZEICHEN-MAPPER
// ═══════════════════════════════════════════════════════════════

enum SymbolLayer {
  public,
  internal,
  archetypal,
}

class Symbol {
  final String id;
  final String name;
  final String visualDescription;
  final Map<SymbolLayer, String> meaningsByLayer;
  final List<String> organizationIds;
  final Map<String, dynamic> metadata;

  Symbol({
    required this.id,
    required this.name,
    required this.visualDescription,
    required this.meaningsByLayer,
    required this.organizationIds,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'visualDescription': visualDescription,
    'meaningsByLayer': meaningsByLayer.map((k, v) => MapEntry(k.toString(), v)),
    'organizationIds': organizationIds,
    'metadata': metadata,
  };
}

class SymbolMapResult {
  final List<Symbol> symbols;
  final Map<String, List<String>> symbolToOrganizations;
  final Map<String, List<String>> organizationToSymbols;
  final DateTime generatedAt;

  SymbolMapResult({
    required this.symbols,
    required this.symbolToOrganizations,
    required this.organizationToSymbols,
    required this.generatedAt,
  });
}

// ═══════════════════════════════════════════════════════════════
// TOOL 4: SYSTEMARCHITEKTUR-ANALYZER
// ═══════════════════════════════════════════════════════════════

enum PowerDistribution {
  vertical,
  horizontal,
  radial,
  cellular,
}

class SystemArchitecture {
  final String organizationId;
  final PowerDistribution powerDistribution;
  final Map<String, double> informationFlow; // Node -> Flow Score
  final List<String> filterMechanisms;
  final List<String> loyaltyAnchors;
  final List<String> selfStabilization;
  final Map<String, List<double>> heatmapData; // Layer -> [values]
  final DateTime analyzedAt;

  SystemArchitecture({
    required this.organizationId,
    required this.powerDistribution,
    required this.informationFlow,
    required this.filterMechanisms,
    required this.loyaltyAnchors,
    required this.selfStabilization,
    required this.heatmapData,
    required this.analyzedAt,
  });

  Map<String, dynamic> toJson() => {
    'organizationId': organizationId,
    'powerDistribution': powerDistribution.toString(),
    'informationFlow': informationFlow,
    'filterMechanisms': filterMechanisms,
    'loyaltyAnchors': loyaltyAnchors,
    'selfStabilization': selfStabilization,
    'heatmapData': heatmapData,
    'analyzedAt': analyzedAt.toIso8601String(),
  };
}

// ═══════════════════════════════════════════════════════════════
// TOOL 5: NETZWERK-VISUALIZER
// ═══════════════════════════════════════════════════════════════

enum NodeType {
  organization,
  symbol,
  archetype,
  role,
  timeframe,
}

class NetworkNode {
  final String id;
  final String label;
  final NodeType type;
  final List<String> connections;
  final Map<String, dynamic> metadata;

  NetworkNode({
    required this.id,
    required this.label,
    required this.type,
    required this.connections,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'type': type.toString(),
    'connections': connections,
    'metadata': metadata,
  };
}

class NetworkCluster {
  final String id;
  final String name;
  final List<String> nodeIds;
  final double density;

  NetworkCluster({
    required this.id,
    required this.name,
    required this.nodeIds,
    required this.density,
  });
}

class NetworkGraph {
  final List<NetworkNode> nodes;
  final Map<String, List<String>> edges;
  final List<NetworkCluster> clusters;
  final DateTime generatedAt;

  NetworkGraph({
    required this.nodes,
    required this.edges,
    required this.clusters,
    required this.generatedAt,
  });
}

// ═══════════════════════════════════════════════════════════════
// TOOL 6: PSYCHOLOGISCHE WIRKUNG-ENGINE
// ═══════════════════════════════════════════════════════════════

class PsychologicalInput {
  final StructureType structureType;
  final double symbolDensity;
  final int groupStrength;
  final int repetitionDegree;

  PsychologicalInput({
    required this.structureType,
    required this.symbolDensity,
    required this.groupStrength,
    required this.repetitionDegree,
  });
}

class PsychologicalOutput {
  final double bindingStrength; // 0-100
  final double identityShift; // 0-100
  final double dependencyPotential; // 0-100
  final double stabilityDegree; // 0-100
  final Map<String, String> analysis;

  PsychologicalOutput({
    required this.bindingStrength,
    required this.identityShift,
    required this.dependencyPotential,
    required this.stabilityDegree,
    required this.analysis,
  });

  Map<String, dynamic> toJson() => {
    'bindingStrength': bindingStrength,
    'identityShift': identityShift,
    'dependencyPotential': dependencyPotential,
    'stabilityDegree': stabilityDegree,
    'analysis': analysis,
  };
}

// ═══════════════════════════════════════════════════════════════
// TOOL 7: ARCHETYP-ENGINE
// ═══════════════════════════════════════════════════════════════

enum Archetype {
  seeker,
  builder,
  guardian,
  invisible,
  mediator,
}

class ArchetypeRole {
  final String roleId;
  final String roleName;
  final Archetype archetype;
  final List<String> organizationIds;
  final List<String> traits;
  final Map<String, dynamic> metadata;

  ArchetypeRole({
    required this.roleId,
    required this.roleName,
    required this.archetype,
    required this.organizationIds,
    required this.traits,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'roleId': roleId,
    'roleName': roleName,
    'archetype': archetype.toString(),
    'organizationIds': organizationIds,
    'traits': traits,
    'metadata': metadata,
  };
}

class ArchetypeComparison {
  final Archetype archetype;
  final List<ArchetypeRole> roles;
  final Map<String, List<String>> crossSystemPatterns;
  final DateTime analyzedAt;

  ArchetypeComparison({
    required this.archetype,
    required this.roles,
    required this.crossSystemPatterns,
    required this.analyzedAt,
  });
}

// ═══════════════════════════════════════════════════════════════
// TOOL 8: ENTHÜLLUNGS-PATTERN-DETECTOR
// ═══════════════════════════════════════════════════════════════

enum SystemReaction {
  denial,
  integration,
  mystification,
  deflection,
  silence,
}

class RevelationEvent {
  final String id;
  final String organizationId;
  final DateTime date;
  final String content;
  final SystemReaction reaction;
  final double mysticismIncrease; // 0-100
  final double resilienceScore; // 0-100
  final List<String> narrativeIntegration;
  final Map<String, dynamic> metadata;

  RevelationEvent({
    required this.id,
    required this.organizationId,
    required this.date,
    required this.content,
    required this.reaction,
    required this.mysticismIncrease,
    required this.resilienceScore,
    required this.narrativeIntegration,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'organizationId': organizationId,
    'date': date.toIso8601String(),
    'content': content,
    'reaction': reaction.toString(),
    'mysticismIncrease': mysticismIncrease,
    'resilienceScore': resilienceScore,
    'narrativeIntegration': narrativeIntegration,
    'metadata': metadata,
  };
}

class RevelationPattern {
  final List<RevelationEvent> events;
  final Map<SystemReaction, int> reactionFrequency;
  final double avgResilienceScore;
  final DateTime analyzedAt;

  RevelationPattern({
    required this.events,
    required this.reactionFrequency,
    required this.avgResilienceScore,
    required this.analyzedAt,
  });
}

// ═══════════════════════════════════════════════════════════════
// TOOL 9: GEOMETRIE- & RAUM-ANALYZER
// ═══════════════════════════════════════════════════════════════

enum GeometricForm {
  circle,
  triangle,
  square,
  pentagon,
  hexagon,
  spiral,
}

class GeometricEffect {
  final GeometricForm form;
  final String psychologicalEffect;
  final String perceptionShift;
  final double stabilityFactor; // 0-1

  GeometricEffect({
    required this.form,
    required this.psychologicalEffect,
    required this.perceptionShift,
    required this.stabilityFactor,
  });

  Map<String, dynamic> toJson() => {
    'form': form.toString(),
    'psychologicalEffect': psychologicalEffect,
    'perceptionShift': perceptionShift,
    'stabilityFactor': stabilityFactor,
  };
}

class SpatialStructure {
  final String organizationId;
  final List<GeometricEffect> geometricElements;
  final Map<String, String> spacePerception;
  final double repetitionStability; // 0-100
  final DateTime analyzedAt;

  SpatialStructure({
    required this.organizationId,
    required this.geometricElements,
    required this.spacePerception,
    required this.repetitionStability,
    required this.analyzedAt,
  });

  Map<String, dynamic> toJson() => {
    'organizationId': organizationId,
    'geometricElements': geometricElements.map((e) => e.toJson()).toList(),
    'spacePerception': spacePerception,
    'repetitionStability': repetitionStability,
    'analyzedAt': analyzedAt.toIso8601String(),
  };
}
