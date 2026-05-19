import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/api_config.dart';
import 'haptic_service.dart';
import 'sqlite_storage_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🎮 OCTALYSIS GAMIFICATION SERVICE
// XP/Leveling, Skill-Tree, Artefakte, Schicksalskarten, Streak-System
// Welten: materie, energie, noir, genesis
// ═══════════════════════════════════════════════════════════════════════════

// ── ENUMS ────────────────────────────────────────────────────────────────

/// Seltenheitsstufen für Artefakte.
enum ArtifactRarity { common, rare, epic, legendary }

/// Schicksalskarten-Typen.
enum DestinyCardType { wisdom, challenge, boost, mystery }

// ── MODELS ───────────────────────────────────────────────────────────────

/// Spieler-XP und Level für eine Welt.
class PlayerProgress {
  final String world;
  final int totalXp;
  final int level;
  final int xpForCurrentLevel;
  final int xpForNextLevel;
  final int streakDays;
  final DateTime? lastActiveDate;
  final int freezesRemaining;

  PlayerProgress({
    required this.world,
    required this.totalXp,
    required this.streakDays,
    this.lastActiveDate,
    this.freezesRemaining = 0,
  })  : level = _calcLevel(totalXp),
        xpForCurrentLevel = _xpForLevel(_calcLevel(totalXp)),
        xpForNextLevel = _xpForLevel(_calcLevel(totalXp) + 1);

  /// Level-Formel: level = sqrt(totalXP / 100)
  static int _calcLevel(int xp) => max(1, sqrt(xp / 100).floor());

  /// XP benötigt um ein bestimmtes Level zu erreichen.
  static int _xpForLevel(int lvl) => lvl * lvl * 100;

  double get progressToNext {
    final range = xpForNextLevel - xpForCurrentLevel;
    if (range <= 0) return 1.0;
    return ((totalXp - xpForCurrentLevel) / range).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        'world': world,
        'totalXp': totalXp,
        'level': level,
        'streakDays': streakDays,
        'lastActiveDate': lastActiveDate?.toIso8601String(),
        'freezesRemaining': freezesRemaining,
      };

  factory PlayerProgress.fromJson(Map<String, dynamic> json) {
    return PlayerProgress(
      world: json['world'] as String? ?? 'materie',
      totalXp: json['totalXp'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
      lastActiveDate: json['lastActiveDate'] != null
          ? DateTime.tryParse(json['lastActiveDate'] as String)
          : null,
      freezesRemaining: json['freezesRemaining'] as int? ?? 0,
    );
  }

  factory PlayerProgress.empty(String world) =>
      PlayerProgress(world: world, totalXp: 0, streakDays: 0);
}

/// Skill im Skill-Tree.
class SkillNode {
  final String skillKey;
  final String world;
  final int level;
  final int xp;
  final DateTime unlockedAt;

  SkillNode({
    required this.skillKey,
    required this.world,
    required this.level,
    required this.xp,
    required this.unlockedAt,
  });

  Map<String, dynamic> toJson() => {
        'skillKey': skillKey,
        'world': world,
        'level': level,
        'xp': xp,
        'unlockedAt': unlockedAt.toIso8601String(),
      };

  factory SkillNode.fromJson(Map<String, dynamic> json) {
    return SkillNode(
      skillKey:
          json['skillKey'] as String? ?? json['skill_key'] as String? ?? '',
      world: json['world'] as String? ?? 'materie',
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.tryParse(json['unlockedAt'] as String) ?? DateTime.now()
          : json['unlocked_at'] != null
              ? DateTime.tryParse(json['unlocked_at'] as String) ??
                  DateTime.now()
              : DateTime.now(),
    );
  }
}

/// Artefakt (aus dem globalen Katalog).
class Artifact {
  final String id;
  final String key;
  final String world;
  final String nameDe;
  final String descriptionDe;
  final ArtifactRarity rarity;
  final String iconEmoji;
  final int xpBonus;
  final Map<String, dynamic> effectJson;

  Artifact({
    required this.id,
    required this.key,
    required this.world,
    required this.nameDe,
    required this.descriptionDe,
    required this.rarity,
    required this.iconEmoji,
    required this.xpBonus,
    required this.effectJson,
  });

  factory Artifact.fromJson(Map<String, dynamic> json) {
    return Artifact(
      id: json['id'] as String? ?? '',
      key: json['key'] as String? ?? '',
      world: json['world'] as String? ?? 'universal',
      nameDe: json['name_de'] as String? ?? json['nameDe'] as String? ?? '',
      descriptionDe: json['description_de'] as String? ??
          json['descriptionDe'] as String? ??
          '',
      rarity: _parseRarity(json['rarity'] as String?),
      iconEmoji:
          json['icon_emoji'] as String? ?? json['iconEmoji'] as String? ?? '🔮',
      xpBonus: json['xp_bonus'] as int? ?? json['xpBonus'] as int? ?? 0,
      effectJson: (json['effect_json'] ?? json['effectJson']) is Map
          ? Map<String, dynamic>.from(
              (json['effect_json'] ?? json['effectJson']) as Map)
          : <String, dynamic>{},
    );
  }

  static ArtifactRarity _parseRarity(String? r) {
    switch (r) {
      case 'rare':
        return ArtifactRarity.rare;
      case 'epic':
        return ArtifactRarity.epic;
      case 'legendary':
        return ArtifactRarity.legendary;
      default:
        return ArtifactRarity.common;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'key': key,
        'world': world,
        'nameDe': nameDe,
        'descriptionDe': descriptionDe,
        'rarity': rarity.name,
        'iconEmoji': iconEmoji,
        'xpBonus': xpBonus,
        'effectJson': effectJson,
      };
}

/// Vom User besessenes Artefakt.
class UserArtifact {
  final String id;
  final Artifact artifact;
  final DateTime acquiredAt;
  final bool isEquipped;

  UserArtifact({
    required this.id,
    required this.artifact,
    required this.acquiredAt,
    required this.isEquipped,
  });

  factory UserArtifact.fromJson(Map<String, dynamic> json, Artifact artifact) {
    return UserArtifact(
      id: json['id'] as String? ?? '',
      artifact: artifact,
      acquiredAt: json['acquired_at'] != null
          ? DateTime.tryParse(json['acquired_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      isEquipped: json['is_equipped'] as bool? ?? false,
    );
  }
}

/// Titel des Users.
class UserTitle {
  final String titleKey;
  final String titleDe;
  final DateTime unlockedAt;
  final bool isActive;

  UserTitle({
    required this.titleKey,
    required this.titleDe,
    required this.unlockedAt,
    required this.isActive,
  });

  Map<String, dynamic> toJson() => {
        'titleKey': titleKey,
        'titleDe': titleDe,
        'unlockedAt': unlockedAt.toIso8601String(),
        'isActive': isActive,
      };

  factory UserTitle.fromJson(Map<String, dynamic> json) {
    return UserTitle(
      titleKey:
          json['title_key'] as String? ?? json['titleKey'] as String? ?? '',
      titleDe: json['title_de'] as String? ?? json['titleDe'] as String? ?? '',
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.tryParse(json['unlocked_at'] as String) ?? DateTime.now()
          : json['unlockedAt'] != null
              ? DateTime.tryParse(json['unlockedAt'] as String) ??
                  DateTime.now()
              : DateTime.now(),
      isActive:
          json['is_active'] as bool? ?? json['isActive'] as bool? ?? false,
    );
  }
}

/// Schicksalskarte.
class DestinyCard {
  final String id;
  final DestinyCardType type;
  final int cardIndex;
  final String titleDe;
  final String messageDe;
  final DateTime drawnAt;
  final bool redeemed;

  DestinyCard({
    required this.id,
    required this.type,
    required this.cardIndex,
    required this.titleDe,
    required this.messageDe,
    required this.drawnAt,
    required this.redeemed,
  });

  factory DestinyCard.fromJson(Map<String, dynamic> json) {
    return DestinyCard(
      id: json['id'] as String? ?? '',
      type: _parseType(json['card_type'] as String? ?? json['type'] as String?),
      cardIndex: json['card_index'] as int? ?? json['cardIndex'] as int? ?? 0,
      titleDe: json['title_de'] as String? ?? json['titleDe'] as String? ?? '',
      messageDe:
          json['message_de'] as String? ?? json['messageDe'] as String? ?? '',
      drawnAt: json['drawn_at'] != null
          ? DateTime.tryParse(json['drawn_at'] as String) ?? DateTime.now()
          : json['drawnAt'] != null
              ? DateTime.tryParse(json['drawnAt'] as String) ?? DateTime.now()
              : DateTime.now(),
      redeemed: json['redeemed'] as bool? ?? false,
    );
  }

  static DestinyCardType _parseType(String? t) {
    switch (t) {
      case 'challenge':
        return DestinyCardType.challenge;
      case 'boost':
        return DestinyCardType.boost;
      case 'mystery':
        return DestinyCardType.mystery;
      default:
        return DestinyCardType.wisdom;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'cardIndex': cardIndex,
        'titleDe': titleDe,
        'messageDe': messageDe,
        'drawnAt': drawnAt.toIso8601String(),
        'redeemed': redeemed,
      };
}

// ── SKILL DEFINITIONS ───────────────────────────────────────────────────

/// Statische Skill-Definitionen pro Welt.
class SkillDefinition {
  final String key;
  final String nameDe;
  final String descriptionDe;
  final String iconEmoji;
  final String world;
  final List<String>
      prerequisites; // Skill-Keys die zuerst freigeschaltet sein müssen
  final int maxLevel;

  const SkillDefinition({
    required this.key,
    required this.nameDe,
    required this.descriptionDe,
    required this.iconEmoji,
    required this.world,
    this.prerequisites = const [],
    this.maxLevel = 10,
  });
}

/// Alle verfügbaren Skills pro Welt.
const Map<String, List<SkillDefinition>> worldSkillDefinitions = {
  'materie': [
    SkillDefinition(
        key: 'recherche_1',
        nameDe: 'Grundrecherche',
        descriptionDe: 'Basis-Fähigkeit zur Informationssuche',
        iconEmoji: '🔍',
        world: 'materie'),
    SkillDefinition(
        key: 'faktencheck_1',
        nameDe: 'Faktencheck',
        descriptionDe: 'Behauptungen kritisch prüfen',
        iconEmoji: '✅',
        world: 'materie',
        prerequisites: ['recherche_1']),
    SkillDefinition(
        key: 'quellenanalyse_1',
        nameDe: 'Quellenanalyse',
        descriptionDe: 'Quellen auf Glaubwürdigkeit bewerten',
        iconEmoji: '📊',
        world: 'materie',
        prerequisites: ['faktencheck_1']),
    SkillDefinition(
        key: 'osint_1',
        nameDe: 'OSINT-Methodik',
        descriptionDe: 'Open Source Intelligence anwenden',
        iconEmoji: '🕵️',
        world: 'materie',
        prerequisites: ['quellenanalyse_1']),
    SkillDefinition(
        key: 'deep_research_1',
        nameDe: 'Tiefenrecherche',
        descriptionDe: 'Verborgene Zusammenhänge aufdecken',
        iconEmoji: '🧬',
        world: 'materie',
        prerequisites: ['osint_1']),
  ],
  'energie': [
    SkillDefinition(
        key: 'meditation_1',
        nameDe: 'Meditation',
        descriptionDe: 'Grundlagen der Achtsamkeit',
        iconEmoji: '🧘',
        world: 'energie'),
    SkillDefinition(
        key: 'heilung_1',
        nameDe: 'Energieheilung',
        descriptionDe: 'Feinstoffliche Energien lenken',
        iconEmoji: '💜',
        world: 'energie',
        prerequisites: ['meditation_1']),
    SkillDefinition(
        key: 'chakra_1',
        nameDe: 'Chakra-Arbeit',
        descriptionDe: 'Die sieben Hauptchakren aktivieren',
        iconEmoji: '🌀',
        world: 'energie',
        prerequisites: ['heilung_1']),
    SkillDefinition(
        key: 'bewusstsein_1',
        nameDe: 'Bewusstseinserweiterung',
        descriptionDe: 'Grenzen des Geistes erweitern',
        iconEmoji: '🌟',
        world: 'energie',
        prerequisites: ['chakra_1']),
    SkillDefinition(
        key: 'transzendenz_1',
        nameDe: 'Transzendenz',
        descriptionDe: 'Jenseits des Materiellen wirken',
        iconEmoji: '✨',
        world: 'energie',
        prerequisites: ['bewusstsein_1']),
  ],
  'noir': [
    SkillDefinition(
        key: 'strategie_1',
        nameDe: 'Strategisches Denken',
        descriptionDe: 'Machtstrukturen analysieren',
        iconEmoji: '♟️',
        world: 'noir'),
    SkillDefinition(
        key: 'geopolitik_1',
        nameDe: 'Geopolitik',
        descriptionDe: 'Globale Machtspiele verstehen',
        iconEmoji: '🌍',
        world: 'noir',
        prerequisites: ['strategie_1']),
    SkillDefinition(
        key: 'manipulation_1',
        nameDe: 'Manipulation erkennen',
        descriptionDe: 'Propaganda und Täuschung entlarven',
        iconEmoji: '🎭',
        world: 'noir',
        prerequisites: ['geopolitik_1']),
    SkillDefinition(
        key: 'netzwerk_1',
        nameDe: 'Netzwerkanalyse',
        descriptionDe: 'Verborgene Verbindungen kartieren',
        iconEmoji: '🕸️',
        world: 'noir',
        prerequisites: ['manipulation_1']),
    SkillDefinition(
        key: 'machtspiel_1',
        nameDe: 'Machtspiel-Meister',
        descriptionDe: 'Die Regeln hinter den Regeln kennen',
        iconEmoji: '👑',
        world: 'noir',
        prerequisites: ['netzwerk_1']),
  ],
  'genesis': [
    SkillDefinition(
        key: 'alchemie_1',
        nameDe: 'Alchemie',
        descriptionDe: 'Transformation verstehen',
        iconEmoji: '⚗️',
        world: 'genesis'),
    SkillDefinition(
        key: 'mythen_1',
        nameDe: 'Mythologie',
        descriptionDe: 'Ur-Geschichten der Menschheit',
        iconEmoji: '📜',
        world: 'genesis',
        prerequisites: ['alchemie_1']),
    SkillDefinition(
        key: 'kosmologie_1',
        nameDe: 'Kosmologie',
        descriptionDe: 'Ursprung und Struktur des Universums',
        iconEmoji: '🌌',
        world: 'genesis',
        prerequisites: ['mythen_1']),
    SkillDefinition(
        key: 'schoepfung_1',
        nameDe: 'Schöpfungslehre',
        descriptionDe: 'Die Mysterien der Entstehung',
        iconEmoji: '🌅',
        world: 'genesis',
        prerequisites: ['kosmologie_1']),
    SkillDefinition(
        key: 'erleuchtung_1',
        nameDe: 'Erleuchtung',
        descriptionDe: 'Höchste Stufe des Verstehens',
        iconEmoji: '🔆',
        world: 'genesis',
        prerequisites: ['schoepfung_1']),
  ],
};

// ── DESTINY CARD POOL (60 Karten) ───────────────────────────────────────

/// Statischer Pool aller 60 Schicksalskarten.
/// 20 wisdom, 15 challenge, 15 boost, 10 mystery.
const List<Map<String, String>> _destinyCardPool = [
  // ── WISDOM (20) ──
  {
    'type': 'wisdom',
    'title': 'Spiegel der Erkenntnis',
    'message':
        'Was du im Außen suchst, findest du nur in dir selbst. Halte heute inne und reflektiere.'
  },
  {
    'type': 'wisdom',
    'title': 'Das Gesetz der Resonanz',
    'message':
        'Gleiches zieht Gleiches an. Achte heute bewusst auf deine Gedanken — sie formen deine Realität.'
  },
  {
    'type': 'wisdom',
    'title': 'Memento Mori',
    'message':
        'Bedenke, dass du sterblich bist. Was würdest du tun, wenn dies dein letzter Tag wäre?'
  },
  {
    'type': 'wisdom',
    'title': 'Das dritte Auge',
    'message':
        'Schau hinter die Oberfläche. Die wahre Geschichte liegt immer zwischen den Zeilen.'
  },
  {
    'type': 'wisdom',
    'title': 'Tabula Rasa',
    'message':
        'Vergiss alles, was du zu wissen glaubst. Nur ein leerer Geist kann Neues aufnehmen.'
  },
  {
    'type': 'wisdom',
    'title': 'Der Fluss des Dao',
    'message':
        'Nicht gegen den Strom schwimmen, sondern ihn verstehen. Flexibilität ist wahre Stärke.'
  },
  {
    'type': 'wisdom',
    'title': 'Hermes' ' Botschaft',
    'message':
        'Wie oben, so unten. Wie innen, so außen. Die kleinen Muster spiegeln die großen.'
  },
  {
    'type': 'wisdom',
    'title': 'Sokrates' ' Frage',
    'message':
        'Ich weiß, dass ich nichts weiß. Wahre Weisheit beginnt mit dem Eingeständnis der Unwissenheit.'
  },
  {
    'type': 'wisdom',
    'title': 'Das Paradox der Wahl',
    'message':
        'Weniger ist mehr. Heute: Reduziere deine Optionen und handle entschlossen.'
  },
  {
    'type': 'wisdom',
    'title': 'Schatten und Licht',
    'message':
        'Akzeptiere deine Schattenseiten. Nur wer seinen Schatten kennt, kann im Licht stehen.'
  },
  {
    'type': 'wisdom',
    'title': 'Zeitlose Weisheit',
    'message':
        'Was vor tausend Jahren wahr war, ist es noch heute. Suche die ewigen Prinzipien.'
  },
  {
    'type': 'wisdom',
    'title': 'Die Kraft der Stille',
    'message':
        'Im Lärm der Welt liegt die Wahrheit verborgen. Finde heute 10 Minuten absolute Stille.'
  },
  {
    'type': 'wisdom',
    'title': 'Ouroboros',
    'message':
        'Jedes Ende ist ein Anfang. Was in deinem Leben endet, macht Platz für Neues.'
  },
  {
    'type': 'wisdom',
    'title': 'Der Beobachter',
    'message':
        'Tritt einen Schritt zurück. Beobachte deine Gedanken, ohne dich mit ihnen zu identifizieren.'
  },
  {
    'type': 'wisdom',
    'title': 'Fibonacci-Spirale',
    'message':
        'Die Natur folgt mathematischen Mustern. Suche heute die verborgene Ordnung im Chaos.'
  },
  {
    'type': 'wisdom',
    'title': 'Das Leere Glas',
    'message':
        'Nur ein leeres Glas kann gefüllt werden. Lass heute eine alte Überzeugung los.'
  },
  {
    'type': 'wisdom',
    'title': 'Achtsamer Atem',
    'message':
        'Dein Atem ist die Brücke zwischen Körper und Geist. Atme heute 3x bewusst tief ein und aus.'
  },
  {
    'type': 'wisdom',
    'title': 'Die fünfte Dimension',
    'message':
        'Jenseits von Raum und Zeit existiert reines Bewusstsein. Was nimmst du jenseits deiner Sinne wahr?'
  },
  {
    'type': 'wisdom',
    'title': 'Der Wanderer',
    'message':
        'Der Weg ist das Ziel. Genieße die Reise, nicht nur das Ankommen.'
  },
  {
    'type': 'wisdom',
    'title': 'Quantum der Möglichkeiten',
    'message':
        'Bis du beobachtest, existieren alle Möglichkeiten gleichzeitig. Wähle weise.'
  },

  // ── CHALLENGE (15) ──
  {
    'type': 'challenge',
    'title': 'Recherche-Sprint',
    'message':
        'Finde heute 3 Quellen zu einem Thema, das dich seit langem beschäftigt. +25 XP bei Abschluss.'
  },
  {
    'type': 'challenge',
    'title': 'Faktencheck-Duell',
    'message':
        'Überprüfe eine populäre Behauptung mit dem Faktencheck-Tool. Teile das Ergebnis. +30 XP.'
  },
  {
    'type': 'challenge',
    'title': 'Meditations-Challenge',
    'message':
        'Meditiere heute 15 Minuten. Dokumentiere deine Erfahrung in der Energie-Welt. +20 XP.'
  },
  {
    'type': 'challenge',
    'title': 'Mentor-Gespräch',
    'message':
        'Führe ein tiefes Gespräch mit deinem KI-Mentor. Stelle mindestens 5 Fragen. +25 XP.'
  },
  {
    'type': 'challenge',
    'title': 'Verborgene Verbindung',
    'message':
        'Finde eine Verbindung zwischen zwei scheinbar unzusammenhängenden Themen. +35 XP.'
  },
  {
    'type': 'challenge',
    'title': 'Quellenprüfung',
    'message':
        'Bewerte heute 5 Nachrichtenquellen nach Glaubwürdigkeit. Nutze OSINT-Methoden. +30 XP.'
  },
  {
    'type': 'challenge',
    'title': 'Kaninchenbau',
    'message':
        'Folge einem Thema 3 Ebenen tief in den Kaninchenbau. Dokumentiere deine Reise. +40 XP.'
  },
  {
    'type': 'challenge',
    'title': 'Perspektivwechsel',
    'message':
        'Vertrete heute bewusst die Gegenposition zu einer deiner Überzeugungen. +20 XP.'
  },
  {
    'type': 'challenge',
    'title': 'Wissen teilen',
    'message':
        'Teile eine Erkenntnis aus der Weltenbibliothek mit jemandem in der realen Welt. +25 XP.'
  },
  {
    'type': 'challenge',
    'title': 'Digitale Detox',
    'message':
        '2 Stunden ohne Smartphone. Nutze die Zeit für Reflexion oder Lesen. +30 XP.'
  },
  {
    'type': 'challenge',
    'title': 'Muster-Erkennung',
    'message':
        'Identifiziere ein wiederkehrendes Muster in aktuellen Nachrichten. +35 XP.'
  },
  {
    'type': 'challenge',
    'title': 'Alchemie des Alltags',
    'message':
        'Verwandle eine negative Erfahrung in eine positive Lektion. Dokumentiere es. +25 XP.'
  },
  {
    'type': 'challenge',
    'title': 'Der Fragende',
    'message':
        'Stelle heute 10 Fragen, die du noch nie gestellt hast. Schreibe sie auf. +20 XP.'
  },
  {
    'type': 'challenge',
    'title': 'Netzwerk-Kartierung',
    'message':
        'Erstelle eine Mindmap zu einem komplexen Thema. Verbinde mindestens 10 Konzepte. +35 XP.'
  },
  {
    'type': 'challenge',
    'title': 'Zeitkapsel',
    'message':
        'Schreibe eine Nachricht an dein zukünftiges Ich in 1 Jahr. Was willst du bis dahin wissen? +15 XP.'
  },

  // ── BOOST (15) ──
  {
    'type': 'boost',
    'title': 'XP-Verstärker',
    'message': 'Doppelte XP für die nächsten 2 Stunden! Nutze die Zeit weise.'
  },
  {
    'type': 'boost',
    'title': 'Streak-Schild',
    'message':
        'Dein Streak ist heute geschützt! Selbst wenn du nicht aktiv bist, bricht er nicht ab.'
  },
  {
    'type': 'boost',
    'title': 'Artefakt-Glück',
    'message':
        'Erhöhte Chance auf ein seltenes Artefakt bei deiner nächsten Entdeckung!'
  },
  {
    'type': 'boost',
    'title': 'Mentor-Bonus',
    'message':
        'Dein nächstes Mentor-Gespräch gibt +50% XP. Der Mentor antwortet heute besonders ausführlich.'
  },
  {
    'type': 'boost',
    'title': 'Wissens-Turbo',
    'message': '+15 XP sofort! Dein Wissensdurst wird belohnt.'
  },
  {
    'type': 'boost',
    'title': 'Kosmische Ausrichtung',
    'message': 'Die Sterne stehen günstig. +20 XP für jede Recherche heute.'
  },
  {
    'type': 'boost',
    'title': 'Bibliothekars-Segen',
    'message':
        'Der Bibliothekar der Weltenbibliothek gewährt dir Zugang zu tieferem Wissen. +25 XP.'
  },
  {
    'type': 'boost',
    'title': 'Energiefeld-Stärkung',
    'message':
        'Dein Energiefeld ist heute besonders stark. Alle Heilungs-Skills +10% Effizienz.'
  },
  {
    'type': 'boost',
    'title': 'Schattenblick',
    'message':
        'Du siehst heute klarer durch den Schleier der Desinformation. Noir-Skills +15%.'
  },
  {
    'type': 'boost',
    'title': 'Genesis-Funke',
    'message':
        'Ein Funke der Urschöpfung erhellt deinen Geist. +10 XP und frische Inspiration.'
  },
  {
    'type': 'boost',
    'title': 'Goldener Schlüssel',
    'message': 'Schaltet einen zufälligen Bonus-Inhalt in der Bibliothek frei.'
  },
  {
    'type': 'boost',
    'title': 'Erfahrungs-Elixier',
    'message': '+30 XP! Ein alchemistisches Elixier beschleunigt dein Wachstum.'
  },
  {
    'type': 'boost',
    'title': 'Zeit-Dehnung',
    'message': 'Alle Cooldowns heute halbiert. Nutze die zusätzliche Zeit.'
  },
  {
    'type': 'boost',
    'title': 'Schutzamulett',
    'message':
        'Dein Streak wird für die nächsten 48 Stunden eingefroren, falls nötig.'
  },
  {
    'type': 'boost',
    'title': 'Weisheits-Perle',
    'message':
        '+20 XP und ein klarer Geist. Deine nächste Entscheidung wird die richtige sein.'
  },

  // ── MYSTERY (10) ──
  {
    'type': 'mystery',
    'title': '???',
    'message':
        'Etwas Unerwartetes geschieht... Prüfe deine Artefakt-Sammlung auf Überraschungen!'
  },
  {
    'type': 'mystery',
    'title': 'Der Fremde',
    'message':
        'Ein unbekannter Wanderer hinterlässt eine Nachricht: „Suche dort, wo du zuletzt aufgehört hast."'
  },
  {
    'type': 'mystery',
    'title': 'Zeitriss',
    'message':
        'Ein Riss in der Zeit offenbart ein Fragment vergessenen Wissens. Was findest du?'
  },
  {
    'type': 'mystery',
    'title': 'Schrödingers Karte',
    'message':
        'Diese Karte ist gleichzeitig gut und schlecht. Erst dein Handeln bestimmt das Ergebnis.'
  },
  {
    'type': 'mystery',
    'title': 'Der 23. Buchstabe',
    'message':
        'W — der 23. Buchstabe. Zufälle gibt es nicht. Achte heute auf die Zahl 23.'
  },
  {
    'type': 'mystery',
    'title': 'Akasha-Echo',
    'message':
        'Ein Echo aus der Akasha-Chronik: Du hast diesen Moment schon einmal erlebt. Déjà-vu?'
  },
  {
    'type': 'mystery',
    'title': 'Schwarzer Schwan',
    'message':
        'Erwarte das Unerwartbare. Heute passiert etwas, das niemand vorhersagen konnte.'
  },
  {
    'type': 'mystery',
    'title': 'Spiegelwelt',
    'message':
        'Alles ist heute umgekehrt. Was du für wahr hältst, könnte falsch sein — und umgekehrt.'
  },
  {
    'type': 'mystery',
    'title': 'Das verlorene Wort',
    'message':
        'Ein Wort, das die Welt verändern könnte, liegt auf deiner Zungenspitze. Welches ist es?'
  },
  {
    'type': 'mystery',
    'title': 'Nullpunkt-Energie',
    'message':
        'Aus dem Nichts entsteht alles. +0 bis +50 XP — das Universum entscheidet.'
  },
];

// ═══════════════════════════════════════════════════════════════════════════
// GAMIFICATION SERVICE (Singleton)
// ═══════════════════════════════════════════════════════════════════════════

class GamificationService {
  GamificationService._internal();
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;

  static const String _boxProgress = 'gamification_progress';
  static const String _boxSkills = 'gamification_skills';
  static const String _boxArtifacts = 'gamification_artifacts';
  static const String _boxCards = 'gamification_cards';
  static const String _boxTitles = 'gamification_titles';

  final _client = http.Client();
  final _random = Random();

  // ── Basis-URL ──
  String get _baseUrl => ApiConfig.workerUrl;

  // ── Auth ──
  Map<String, String> get _headers {
    final token =
        Supabase.instance.client.auth.currentSession?.accessToken ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════
  // XP & LEVELING
  // ═══════════════════════════════════════════════════════════

  /// Lade Spielerfortschritt für eine Welt (lokal).
  PlayerProgress getProgress(String world) {
    try {
      final raw = SqliteStorageService.instance.getSync(_boxProgress, world);
      if (raw == null) return PlayerProgress.empty(world);
      return PlayerProgress.fromJson(Map<String, dynamic>.from(raw as Map));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ GamificationService.getProgress: $e');
      return PlayerProgress.empty(world);
    }
  }

  /// XP hinzufügen (lokal + optional Server-Sync).
  Future<PlayerProgress> addXp(String world, int amount,
      {String? reason, bool syncServer = true}) async {
    final current = getProgress(world);
    final oldLevel = current.level;

    final updated = PlayerProgress(
      world: world,
      totalXp: current.totalXp + amount,
      streakDays: current.streakDays,
      lastActiveDate: DateTime.now(),
      freezesRemaining: current.freezesRemaining,
    );

    // Lokal speichern
    await SqliteStorageService.instance
        .put(_boxProgress, world, updated.toJson());

    // Haptic-Feedback: jeder XP-Gain ein leichter Click; Level-Up extra
    // (medium impact). Wenn HapticService noch nicht initialisiert ist
    // (z.B. Test-Umgebung), fängt der Service intern.
    if (amount > 0) HapticService.selectionClick();

    // Level-Up erkennen
    if (updated.level > oldLevel) {
      if (kDebugMode) {
        debugPrint('🎮 LEVEL UP! $world: $oldLevel → ${updated.level}');
      }
      HapticService.mediumImpact();
      await _checkLevelRewards(world, updated.level);
    }

    // Server-Sync (fire & forget)
    if (syncServer && _userId != null) {
      _syncXpToServer(world, amount, reason);
    }

    return updated;
  }

  /// Prüfe Level-Belohnungen (Titel, Artefakte).
  Future<void> _checkLevelRewards(String world, int newLevel) async {
    // Titel bei bestimmten Levels freischalten
    final titleMap = <int, Map<String, String>>{
      5: {'key': '${world}_adept', 'title': _levelTitle(world, 5)},
      10: {'key': '${world}_experte', 'title': _levelTitle(world, 10)},
      20: {'key': '${world}_meister', 'title': _levelTitle(world, 20)},
      50: {'key': '${world}_grossmeister', 'title': _levelTitle(world, 50)},
    };

    final reward = titleMap[newLevel];
    if (reward != null) {
      await _unlockTitle(reward['key']!, reward['title']!);
    }
  }

  String _levelTitle(String world, int level) {
    final worldNames = {
      'materie': 'Materie',
      'energie': 'Energie',
      'noir': 'Noir',
      'genesis': 'Genesis',
    };
    final ranks = {5: 'Adept', 10: 'Experte', 20: 'Meister', 50: 'Großmeister'};
    return '${ranks[level] ?? "Stufe $level"} der ${worldNames[world] ?? world}';
  }

  /// Server-Sync für XP (async, kein await im Hauptfluss).
  void _syncXpToServer(String world, int amount, String? reason) {
    _client
        .post(
          Uri.parse('$_baseUrl/api/gamification/add-xp'),
          headers: _headers,
          body: jsonEncode({
            'world': world,
            'amount': amount,
            'reason': reason ?? 'activity',
            'userId': _userId,
          }),
        )
        .timeout(const Duration(seconds: 10))
        .catchError((e) {
      if (kDebugMode) debugPrint('⚠️ XP-Sync fehlgeschlagen: $e');
    });
  }

  // ═══════════════════════════════════════════════════════════
  // STREAK SYSTEM
  // ═══════════════════════════════════════════════════════════

  /// Streak prüfen und aktualisieren.
  Future<PlayerProgress> checkAndUpdateStreak(String world) async {
    final current = getProgress(world);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (current.lastActiveDate == null) {
      // Erster Tag
      return _saveProgress(current, streakDays: 1, lastActive: now);
    }

    final lastActive = current.lastActiveDate!;
    final lastDay = DateTime(lastActive.year, lastActive.month, lastActive.day);
    final diff = today.difference(lastDay).inDays;

    if (diff == 0) {
      // Bereits heute aktiv gewesen
      return current;
    } else if (diff == 1) {
      // Streak fortsetzen!
      return _saveProgress(current,
          streakDays: current.streakDays + 1, lastActive: now);
    } else if (diff == 2 && current.freezesRemaining > 0) {
      // Freeze einsetzen (1 Tag verpasst)
      return _saveProgress(current,
          streakDays: current.streakDays,
          lastActive: now,
          freezesRemaining: current.freezesRemaining - 1);
    } else {
      // Streak gebrochen
      return _saveProgress(current, streakDays: 1, lastActive: now);
    }
  }

  /// Streak-Freeze gewähren (1 pro Woche).
  Future<void> grantWeeklyFreeze(String world) async {
    final current = getProgress(world);
    if (current.freezesRemaining < 1) {
      await _saveProgress(current, freezesRemaining: 1);
    }
  }

  Future<PlayerProgress> _saveProgress(
    PlayerProgress p, {
    int? streakDays,
    DateTime? lastActive,
    int? freezesRemaining,
  }) async {
    final updated = PlayerProgress(
      world: p.world,
      totalXp: p.totalXp,
      streakDays: streakDays ?? p.streakDays,
      lastActiveDate: lastActive ?? p.lastActiveDate,
      freezesRemaining: freezesRemaining ?? p.freezesRemaining,
    );
    await SqliteStorageService.instance
        .put(_boxProgress, p.world, updated.toJson());
    return updated;
  }

  // ═══════════════════════════════════════════════════════════
  // SKILL TREE
  // ═══════════════════════════════════════════════════════════

  /// Alle freigeschalteten Skills für eine Welt laden.
  List<SkillNode> getSkills(String world) {
    try {
      final raw = SqliteStorageService.instance.getSync(_boxSkills, world);
      if (raw == null) return [];
      return (raw as List<dynamic>)
          .map((e) => SkillNode.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ GamificationService.getSkills: $e');
      return [];
    }
  }

  /// Skill freischalten oder upgraden.
  Future<SkillNode?> unlockOrUpgradeSkill(String world, String skillKey) async {
    final definitions = worldSkillDefinitions[world] ?? [];
    final def = definitions.where((d) => d.key == skillKey).firstOrNull;
    if (def == null) return null;

    // Prerequisites prüfen
    final currentSkills = getSkills(world);
    final skillMap = {for (final s in currentSkills) s.skillKey: s};

    for (final prereq in def.prerequisites) {
      if (!skillMap.containsKey(prereq)) {
        if (kDebugMode) {
          debugPrint('⚠️ Prerequisite nicht erfüllt: $prereq für $skillKey');
        }
        return null;
      }
    }

    final existing = skillMap[skillKey];
    final SkillNode newNode;

    if (existing != null) {
      // Upgrade
      if (existing.level >= def.maxLevel) return existing; // Max erreicht
      newNode = SkillNode(
        skillKey: skillKey,
        world: world,
        level: existing.level + 1,
        xp: existing.xp,
        unlockedAt: existing.unlockedAt,
      );
      skillMap[skillKey] = newNode;
    } else {
      // Neu freischalten
      newNode = SkillNode(
        skillKey: skillKey,
        world: world,
        level: 1,
        xp: 0,
        unlockedAt: DateTime.now(),
      );
      skillMap[skillKey] = newNode;
    }

    // Speichern
    await SqliteStorageService.instance.put(
      _boxSkills,
      world,
      skillMap.values.map((s) => s.toJson()).toList(),
    );

    return newNode;
  }

  /// Prüfe ob ein Skill freigeschaltet werden kann.
  bool canUnlockSkill(String world, String skillKey) {
    final definitions = worldSkillDefinitions[world] ?? [];
    final def = definitions.where((d) => d.key == skillKey).firstOrNull;
    if (def == null) return false;

    final currentSkills = getSkills(world);
    final unlockedKeys = {for (final s in currentSkills) s.skillKey};

    // Bereits freigeschaltet = kann geupgraded werden
    if (unlockedKeys.contains(skillKey)) return true;

    // Prerequisites prüfen
    return def.prerequisites.every(unlockedKeys.contains);
  }

  // ═══════════════════════════════════════════════════════════
  // ARTIFACTS
  // ═══════════════════════════════════════════════════════════

  /// Artefakt-Katalog laden (vom Server oder Cache).
  Future<List<Artifact>> getArtifactCatalog({bool forceRefresh = false}) async {
    // Zuerst aus Cache
    if (!forceRefresh) {
      final cached =
          SqliteStorageService.instance.getSync(_boxArtifacts, 'catalog');
      if (cached != null) {
        return (cached as List<dynamic>)
            .map((e) => Artifact.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    }

    // Server abrufen
    try {
      final res = await _client
          .get(
            Uri.parse('$_baseUrl/api/gamification/artifacts'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final artifacts = (data['artifacts'] as List<dynamic>)
            .map((e) => Artifact.fromJson(e as Map<String, dynamic>))
            .toList();

        // Cache speichern
        await SqliteStorageService.instance.put(
          _boxArtifacts,
          'catalog',
          artifacts.map((a) => a.toJson()).toList(),
        );

        return artifacts;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ getArtifactCatalog: $e');
    }

    return [];
  }

  /// User-Artefakte laden.
  Future<List<UserArtifact>> getUserArtifacts() async {
    try {
      final catalog = await getArtifactCatalog();
      final catalogMap = {for (final a in catalog) a.id: a};

      final raw =
          SqliteStorageService.instance.getSync(_boxArtifacts, 'user_owned');
      if (raw == null) return [];

      return (raw as List<dynamic>)
          .map((e) {
            final json = Map<String, dynamic>.from(e as Map);
            final artifactId = json['artifact_id'] as String? ?? '';
            final artifact = catalogMap[artifactId];
            if (artifact == null) return null;
            return UserArtifact.fromJson(json, artifact);
          })
          .whereType<UserArtifact>()
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ getUserArtifacts: $e');
      return [];
    }
  }

  /// Artefakt erwerben.
  Future<bool> acquireArtifact(String artifactId) async {
    try {
      final catalog = await getArtifactCatalog();
      final artifact = catalog.where((a) => a.id == artifactId).firstOrNull;
      if (artifact == null) return false;

      // Lokal speichern
      final raw =
          SqliteStorageService.instance.getSync(_boxArtifacts, 'user_owned');
      final current =
          raw != null ? List<dynamic>.from(raw as List) : <dynamic>[];

      // Duplikat-Check
      if (current.any((e) => (e as Map)['artifact_id'] == artifactId)) {
        return false;
      }

      current.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'artifact_id': artifactId,
        'acquired_at': DateTime.now().toIso8601String(),
        'is_equipped': false,
      });

      await SqliteStorageService.instance
          .put(_boxArtifacts, 'user_owned', current);

      // XP-Bonus
      if (artifact.xpBonus > 0) {
        await addXp(artifact.world == 'universal' ? 'materie' : artifact.world,
            artifact.xpBonus,
            reason: 'artifact_acquired');
      }

      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ acquireArtifact: $e');
      return false;
    }
  }

  /// Artefakt an-/ablegen.
  Future<void> toggleEquipArtifact(String userArtifactId) async {
    try {
      final raw =
          SqliteStorageService.instance.getSync(_boxArtifacts, 'user_owned');
      if (raw == null) return;

      final list = List<dynamic>.from(raw as List);
      for (var i = 0; i < list.length; i++) {
        final item = Map<String, dynamic>.from(list[i] as Map);
        if (item['id'] == userArtifactId) {
          item['is_equipped'] = !(item['is_equipped'] as bool? ?? false);
          list[i] = item;
          break;
        }
      }

      await SqliteStorageService.instance
          .put(_boxArtifacts, 'user_owned', list);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ toggleEquipArtifact: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // DESTINY CARDS
  // ═══════════════════════════════════════════════════════════

  /// Heutige Schicksalskarte laden (oder null wenn noch keine gezogen).
  DestinyCard? getTodayCard() {
    try {
      final today = _todayKey();
      final raw = SqliteStorageService.instance.getSync(_boxCards, today);
      if (raw == null) return null;
      return DestinyCard.fromJson(Map<String, dynamic>.from(raw as Map));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ getTodayCard: $e');
      return null;
    }
  }

  /// Hat der User heute bereits eine Karte gezogen?
  bool hasDrawnToday() => getTodayCard() != null;

  /// Schicksalskarte ziehen (lokal + optional Server).
  Future<DestinyCard?> drawCard({bool syncServer = true}) async {
    if (hasDrawnToday()) return getTodayCard();

    // Zufällige Karte aus Pool
    final index = _random.nextInt(_destinyCardPool.length);
    final poolCard = _destinyCardPool[index];

    final card = DestinyCard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: DestinyCard._parseType(poolCard['type']),
      cardIndex: index,
      titleDe: poolCard['title']!,
      messageDe: poolCard['message']!,
      drawnAt: DateTime.now(),
      redeemed: false,
    );

    // Lokal speichern
    await SqliteStorageService.instance
        .put(_boxCards, _todayKey(), card.toJson());

    // Boost-Karten: Sofort XP gewähren falls spezifiziert
    if (card.type == DestinyCardType.boost) {
      _applyBoostCard(card);
    }

    // Server-Sync (fire & forget)
    if (syncServer && _userId != null) {
      _syncCardToServer(card);
    }

    return card;
  }

  /// Karten-Historie (letzte N Tage).
  List<DestinyCard> getCardHistory({int days = 7}) {
    final cards = <DestinyCard>[];
    final now = DateTime.now();

    for (var i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final raw = SqliteStorageService.instance.getSync(_boxCards, key);
      if (raw != null) {
        cards.add(DestinyCard.fromJson(Map<String, dynamic>.from(raw as Map)));
      }
    }

    return cards;
  }

  void _applyBoostCard(DestinyCard card) {
    // XP-Boosts aus den Kartentexten extrahieren
    final xpMatch = RegExp(r'\+(\d+)\s*XP').firstMatch(card.messageDe);
    if (xpMatch != null) {
      final xp = int.tryParse(xpMatch.group(1)!) ?? 0;
      if (xp > 0) {
        addXp('materie', xp, reason: 'destiny_card_boost', syncServer: false);
      }
    }
  }

  void _syncCardToServer(DestinyCard card) {
    _client
        .post(
          Uri.parse('$_baseUrl/api/gamification/draw-card'),
          headers: _headers,
          body: jsonEncode({
            'userId': _userId,
            'cardType': card.type.name,
            'cardIndex': card.cardIndex,
            'titleDe': card.titleDe,
            'messageDe': card.messageDe,
          }),
        )
        .timeout(const Duration(seconds: 10))
        .catchError((e) {
      if (kDebugMode) debugPrint('⚠️ Card-Sync fehlgeschlagen: $e');
    });
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ═══════════════════════════════════════════════════════════
  // TITLES
  // ═══════════════════════════════════════════════════════════

  /// Alle Titel des Users.
  List<UserTitle> getTitles() {
    try {
      final raw = SqliteStorageService.instance.getSync(_boxTitles, 'all');
      if (raw == null) return [];
      return (raw as List<dynamic>)
          .map((e) => UserTitle.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ getTitles: $e');
      return [];
    }
  }

  /// Aktiven Titel abrufen.
  UserTitle? getActiveTitle() {
    return getTitles().where((t) => t.isActive).firstOrNull;
  }

  /// Titel freischalten.
  Future<void> _unlockTitle(String titleKey, String titleDe) async {
    final titles = getTitles();
    if (titles.any((t) => t.titleKey == titleKey)) return; // Bereits vorhanden

    titles.add(UserTitle(
      titleKey: titleKey,
      titleDe: titleDe,
      unlockedAt: DateTime.now(),
      isActive: false,
    ));

    await SqliteStorageService.instance.put(
      _boxTitles,
      'all',
      titles.map((t) => t.toJson()).toList(),
    );

    if (kDebugMode) debugPrint('🏅 Titel freigeschaltet: $titleDe');
  }

  /// Titel aktivieren (nur einer gleichzeitig).
  Future<void> setActiveTitle(String titleKey) async {
    final titles = getTitles();
    final updated = titles.map((t) {
      return UserTitle(
        titleKey: t.titleKey,
        titleDe: t.titleDe,
        unlockedAt: t.unlockedAt,
        isActive: t.titleKey == titleKey,
      );
    }).toList();

    await SqliteStorageService.instance.put(
      _boxTitles,
      'all',
      updated.map((t) => t.toJson()).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SYNC (Supabase ↔ Lokal)
  // ═══════════════════════════════════════════════════════════

  /// Vollständigen Sync mit Supabase durchführen.
  Future<void> syncWithSupabase() async {
    if (_userId == null) return;
    final sb = Supabase.instance.client;

    try {
      // Skill-Tree synchronisieren
      await _syncSkillsFromSupabase(sb);

      // User-Artefakte synchronisieren
      await _syncArtifactsFromSupabase(sb);

      // Titel synchronisieren
      await _syncTitlesFromSupabase(sb);

      if (kDebugMode) debugPrint('✅ Gamification sync erfolgreich');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Gamification sync: $e');
    }
  }

  Future<void> _syncSkillsFromSupabase(SupabaseClient sb) async {
    try {
      final rows = await sb
          .from('user_skill_tree')
          .select()
          .eq('user_id', _userId!)
          .order('unlocked_at');

      // Nach Welt gruppieren
      final byWorld = <String, List<Map<String, dynamic>>>{};
      for (final row in rows) {
        final world = row['world'] as String;
        byWorld.putIfAbsent(world, () => []).add(row);
      }

      for (final entry in byWorld.entries) {
        final skills = entry.value
            .map((r) => SkillNode(
                  skillKey: r['skill_key'] as String,
                  world: r['world'] as String,
                  level: r['level'] as int,
                  xp: r['xp'] as int,
                  unlockedAt: DateTime.tryParse(r['unlocked_at'] as String) ??
                      DateTime.now(),
                ))
            .toList();

        await SqliteStorageService.instance.put(
          _boxSkills,
          entry.key,
          skills.map((s) => s.toJson()).toList(),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ _syncSkillsFromSupabase: $e');
    }
  }

  Future<void> _syncArtifactsFromSupabase(SupabaseClient sb) async {
    try {
      // Katalog aktualisieren
      final catalogRows = await sb.from('artifacts').select().order('world');
      await SqliteStorageService.instance.put(
        _boxArtifacts,
        'catalog',
        catalogRows.map((r) => Artifact.fromJson(r).toJson()).toList(),
      );

      // User-Artefakte
      final ownedRows = await sb
          .from('user_artifacts')
          .select()
          .eq('user_id', _userId!)
          .order('acquired_at');

      await SqliteStorageService.instance.put(
        _boxArtifacts,
        'user_owned',
        ownedRows,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ _syncArtifactsFromSupabase: $e');
    }
  }

  Future<void> _syncTitlesFromSupabase(SupabaseClient sb) async {
    try {
      final rows = await sb
          .from('user_titles')
          .select()
          .eq('user_id', _userId!)
          .order('unlocked_at');

      final titles = rows.map((r) => UserTitle.fromJson(r)).toList();

      await SqliteStorageService.instance.put(
        _boxTitles,
        'all',
        titles.map((t) => t.toJson()).toList(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ _syncTitlesFromSupabase: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // UTILITIES
  // ═══════════════════════════════════════════════════════════

  /// Gesamte XP über alle Welten.
  int get totalXpAllWorlds {
    var total = 0;
    for (final world in ['materie', 'energie', 'noir', 'genesis']) {
      total += getProgress(world).totalXp;
    }
    return total;
  }

  /// Globales Level (basierend auf Gesamt-XP).
  int get globalLevel => max(1, sqrt(totalXpAllWorlds / 100).floor());

  /// Rarity-Farbe als Hex-Int.
  static int rarityColor(ArtifactRarity rarity) {
    switch (rarity) {
      case ArtifactRarity.common:
        return 0xFF9E9E9E; // Grau
      case ArtifactRarity.rare:
        return 0xFF42A5F5; // Blau
      case ArtifactRarity.epic:
        return 0xFFAB47BC; // Lila
      case ArtifactRarity.legendary:
        return 0xFFFFD54F; // Gold
    }
  }

  /// Rarity-Label (Deutsch).
  static String rarityLabel(ArtifactRarity rarity) {
    switch (rarity) {
      case ArtifactRarity.common:
        return 'Gewöhnlich';
      case ArtifactRarity.rare:
        return 'Selten';
      case ArtifactRarity.epic:
        return 'Episch';
      case ArtifactRarity.legendary:
        return 'Legendär';
    }
  }

  /// DestinyCardType-Label (Deutsch).
  static String cardTypeLabel(DestinyCardType type) {
    switch (type) {
      case DestinyCardType.wisdom:
        return 'Weisheit';
      case DestinyCardType.challenge:
        return 'Herausforderung';
      case DestinyCardType.boost:
        return 'Verstärker';
      case DestinyCardType.mystery:
        return 'Mysterium';
    }
  }

  /// DestinyCardType-Farbe.
  static int cardTypeColor(DestinyCardType type) {
    switch (type) {
      case DestinyCardType.wisdom:
        return 0xFF64B5F6; // Blau
      case DestinyCardType.challenge:
        return 0xFFFF7043; // Orange
      case DestinyCardType.boost:
        return 0xFF66BB6A; // Grün
      case DestinyCardType.mystery:
        return 0xFFAB47BC; // Lila
    }
  }

  /// DestinyCardType-Emoji.
  static String cardTypeEmoji(DestinyCardType type) {
    switch (type) {
      case DestinyCardType.wisdom:
        return '📖';
      case DestinyCardType.challenge:
        return '⚔️';
      case DestinyCardType.boost:
        return '⚡';
      case DestinyCardType.mystery:
        return '🔮';
    }
  }
}
