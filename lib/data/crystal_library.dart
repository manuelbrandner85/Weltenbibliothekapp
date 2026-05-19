// Erweiterte Kristall-Datenbank mit 60+ Mineralien.
// Bereich K1 -- ersetzt die ehemals interne _MineralEntry-Liste und macht
// die Daten oeffentlich, sodass Crystal-Library, Crystal-Finder,
// Crystal-Combiner und Birthstone-Matcher alle dieselbe Quelle nutzen.

import 'package:flutter/material.dart';

class CrystalEntry {
  final String name;
  final String nameEn;
  final String formula;
  final String hardness;
  final List<String> colors;
  final String crystalSystem;
  final List<String> origins;
  final String spiritualEffect;
  final String? chakra;       // Wurzel/Sakral/Solarplexus/Herz/Hals/Stirn/Krone
  final String? element;       // Erde/Wasser/Feuer/Luft/Aether
  final List<String> tags;     // 'Schutz','Liebe','Erdung','Klarheit',...
  final List<String> intentions; // K2-Wizard: 'Beruhigung','Mut','Erfolg',...
  final String emoji;
  final Color displayColor;
  final String cleansing;       // Wie reinigen
  final String charging;        // Wie aufladen
  final String careNote;        // Warnung (UV, Wasser, Sonne)
  final String howToUse;        // Anwendung praktisch
  final List<int> birthMonths;  // 1-12 (Jan = 1)
  final List<String> zodiac;    // 'Widder','Stier',...
  final int? lifePathNumber;    // Best fitting Numerologie-Zahl 1-9

  const CrystalEntry({
    required this.name,
    required this.nameEn,
    required this.formula,
    required this.hardness,
    required this.colors,
    required this.crystalSystem,
    required this.origins,
    required this.spiritualEffect,
    this.chakra,
    this.element,
    required this.tags,
    this.intentions = const [],
    required this.emoji,
    required this.displayColor,
    this.cleansing = 'Unter fliessendem Wasser oder mit Raeucherwerk (Salbei, Palo Santo).',
    this.charging = 'Im Mondlicht (besonders Vollmond) oder auf einem Bergkristall-Cluster.',
    this.careNote = '',
    this.howToUse = '',
    this.birthMonths = const [],
    this.zodiac = const [],
    this.lifePathNumber,
  });
}

const List<CrystalEntry> crystalLibrary = [
  // ── QUARZ-FAMILIE ──────────────────────────────────────────────────────
  CrystalEntry(
    name: 'Amethyst', nameEn: 'Amethyst', formula: 'SiO₂', hardness: '7',
    colors: ['Violett','Lila','Hellviolett'], crystalSystem: 'Trigonal',
    origins: ['Brasilien','Uruguay','Sambia','Madagaskar'],
    spiritualEffect: 'Spirituelle Klarheit, Schutz, oeffnet das dritte Auge. Beruhigt einen ueberhitzten Geist.',
    chakra: 'Stirn', element: 'Luft',
    tags: ['Schutz','Klarheit','Meditation','Spiritualitaet'],
    intentions: ['Beruhigung','Klarheit','Meditation','Schlaf','Suchtbefreiung'],
    emoji: '💜', displayColor: Color(0xFF9C27B0),
    careNote: 'Verblasst bei direkter Sonne -- nicht stundenlang ans Fenster.',
    howToUse: 'Auf das Stirnchakra legen, unter das Kissen fuer ruhigen Schlaf, oder beim Meditieren in die Hand nehmen.',
    birthMonths: [2], zodiac: ['Fische','Wassermann','Steinbock'], lifePathNumber: 7),

  CrystalEntry(
    name: 'Rosenquarz', nameEn: 'Rose Quartz', formula: 'SiO₂', hardness: '7',
    colors: ['Rosa','Hellrosa'], crystalSystem: 'Trigonal',
    origins: ['Brasilien','Madagaskar','Suedafrika'],
    spiritualEffect: 'Stein der bedingungslosen Liebe und Selbstliebe. Oeffnet das Herzchakra sanft.',
    chakra: 'Herz', element: 'Wasser',
    tags: ['Liebe','Heilung','Selbstwert','Mitgefuehl'],
    intentions: ['Selbstliebe','Trauerverarbeitung','Beziehungsheilung','Sanftheit','Versoehnung'],
    emoji: '🌸', displayColor: Color(0xFFE91E63),
    careNote: 'Verblasst bei Sonne. Nicht laenger als 1h direkt ans Licht.',
    howToUse: 'Auf das Herzchakra legen. Im Schlafzimmer fuer Beziehungs-Harmonie. In der Hosentasche tragen fuer mehr Selbstmitgefuehl.',
    birthMonths: [1], zodiac: ['Stier','Waage','Krebs'], lifePathNumber: 6),

  CrystalEntry(
    name: 'Bergkristall', nameEn: 'Clear Quartz', formula: 'SiO₂', hardness: '7',
    colors: ['Klar','Durchsichtig'], crystalSystem: 'Trigonal',
    origins: ['Brasilien','Madagaskar','Arkansas (USA)','Alpen'],
    spiritualEffect: 'Master-Heiler. Verstaerkt jede Energie und Intention. Universal-Kristall.',
    chakra: 'Krone', element: 'Aether',
    tags: ['Verstaerker','Klarheit','Universell','Heilung'],
    intentions: ['Klarheit','Manifestation','Energiekanal','Reinigung','Verstaerkung'],
    emoji: '🤍', displayColor: Color(0xFFE0E0E0),
    cleansing: 'Unter fliessendem Wasser, im Salzwasser-Bad oder via Klangschale.',
    charging: 'Sonne (1-2 Std) ODER Mond. Bergkristall ist robust.',
    howToUse: 'Programmierbar: Halte ihn, formuliere deine Intention dreimal klar im Kopf, traegst ihn dann mit dir.',
    birthMonths: [4], zodiac: ['Loewe','Steinbock','alle'], lifePathNumber: 1),

  CrystalEntry(
    name: 'Citrin', nameEn: 'Citrine', formula: 'SiO₂', hardness: '7',
    colors: ['Gelb','Goldgelb','Honig'], crystalSystem: 'Trigonal',
    origins: ['Brasilien','Bolivien','Russland','Madagaskar'],
    spiritualEffect: 'Sonne in Stein-Form. Foerdert Lebensfreude, Selbstvertrauen, Wohlstand.',
    chakra: 'Solarplexus', element: 'Feuer',
    tags: ['Wohlstand','Freude','Selbstvertrauen','Erfolg'],
    intentions: ['Wohlstand','Selbstvertrauen','Freude','Erfolg','Motivation'],
    emoji: '💛', displayColor: Color(0xFFFFC107),
    careNote: 'Verblasst bei direkter Sonne -- echter Citrin (selten) eher als geheizter Amethyst.',
    howToUse: 'Auf den Solarplexus legen, in der Geldboerse tragen, am Schreibtisch fuer Motivation.',
    birthMonths: [11], zodiac: ['Loewe','Schuetze','Zwillinge'], lifePathNumber: 3),

  CrystalEntry(
    name: 'Rauchquarz', nameEn: 'Smoky Quartz', formula: 'SiO₂', hardness: '7',
    colors: ['Braun','Grau','Schwarz-grau'], crystalSystem: 'Trigonal',
    origins: ['Brasilien','Schottland','Schweizer Alpen'],
    spiritualEffect: 'Erdender Schutzstein. Loest Spannung, transformiert negative Energien.',
    chakra: 'Wurzel', element: 'Erde',
    tags: ['Erdung','Schutz','Loslassen','Stressabbau'],
    intentions: ['Erdung','Stressabbau','Loslassen','Schutz','Konzentration'],
    emoji: '🟤', displayColor: Color(0xFF5D4037),
    howToUse: 'In der Hosentasche bei Stress. Auf das Wurzelchakra legen. Im Buero gegen Elektrosmog.',
    birthMonths: [10], zodiac: ['Steinbock','Skorpion','Schuetze'], lifePathNumber: 8),

  CrystalEntry(
    name: 'Aventurin', nameEn: 'Aventurine', formula: 'SiO₂', hardness: '7',
    colors: ['Gruen','Hellgruen'], crystalSystem: 'Trigonal',
    origins: ['Indien','Brasilien','Russland'],
    spiritualEffect: 'Stein der Chancen und des Glücks. Beruhigt das Herz, foerdert Optimismus.',
    chakra: 'Herz', element: 'Erde',
    tags: ['Glueck','Chancen','Beruhigung','Wachstum'],
    intentions: ['Glueck','Neuanfang','Optimismus','Herzheilung','Geld-Manifestation'],
    emoji: '🍀', displayColor: Color(0xFF66BB6A),
    howToUse: 'In der linken Hosentasche fuer Empfangen. Bei Vorstellungs-Gespraechen oder Pruefungen mitnehmen.',
    birthMonths: [5,8], zodiac: ['Stier','Krebs','Jungfrau'], lifePathNumber: 5),

  CrystalEntry(
    name: 'Tigerauge', nameEn: 'Tiger Eye', formula: 'SiO₂ + Krokydolith', hardness: '7',
    colors: ['Goldbraun','Braun mit Schimmer'], crystalSystem: 'Trigonal',
    origins: ['Suedafrika','Australien','Indien'],
    spiritualEffect: 'Mut, Klarheit, Erdung in Entscheidungen. Schaerft den Blick fuer das Wesentliche.',
    chakra: 'Solarplexus', element: 'Feuer',
    tags: ['Mut','Klarheit','Schutz','Entscheidung'],
    intentions: ['Mut','Entscheidung','Konzentration','Schutz','Selbststaerke'],
    emoji: '🐯', displayColor: Color(0xFFB8860B),
    howToUse: 'Bei wichtigen Entscheidungen in der Hand halten. Im Auto fuer Wachsamkeit. Als Amulett gegen Manipulation.',
    birthMonths: [11], zodiac: ['Loewe','Steinbock','Stier'], lifePathNumber: 8),

  CrystalEntry(
    name: 'Carneol', nameEn: 'Carnelian', formula: 'SiO₂', hardness: '7',
    colors: ['Orange','Rotorange','Rotbraun'], crystalSystem: 'Trigonal',
    origins: ['Brasilien','Indien','Madagaskar'],
    spiritualEffect: 'Stein der Lebenskraft und Sexualitaet. Foerdert Leidenschaft, Kreativitaet, Mut.',
    chakra: 'Sakral', element: 'Feuer',
    tags: ['Lebenskraft','Kreativitaet','Mut','Sexualitaet'],
    intentions: ['Energie','Kreativitaet','Leidenschaft','Mut','Vitalitaet'],
    emoji: '🔥', displayColor: Color(0xFFFF5722),
    howToUse: 'Auf das Sakralchakra. Bei Schoepfungs-Blockade auf den Schreibtisch. Vor wichtigen Auftritten am Koerper tragen.',
    birthMonths: [7], zodiac: ['Loewe','Jungfrau','Stier'], lifePathNumber: 5),

  CrystalEntry(
    name: 'Onyx', nameEn: 'Black Onyx', formula: 'SiO₂', hardness: '7',
    colors: ['Schwarz','Schwarz-weiss gestreift'], crystalSystem: 'Trigonal',
    origins: ['Indien','Brasilien','Madagaskar'],
    spiritualEffect: 'Schutzschild. Absorbiert negative Energien, foerdert Selbstdisziplin.',
    chakra: 'Wurzel', element: 'Erde',
    tags: ['Schutz','Disziplin','Erdung','Standhaftigkeit'],
    intentions: ['Schutz','Disziplin','Standhaftigkeit','Trauer-Loslassen'],
    emoji: '⬛', displayColor: Color(0xFF212121),
    howToUse: 'Als Schmuck bei Konflikten. Auf dem Schreibtisch fuer Fokus. Beim Auflegen aufs Wurzelchakra fuer Erdung.',
    birthMonths: [12], zodiac: ['Steinbock','Loewe'], lifePathNumber: 4),

  CrystalEntry(
    name: 'Achat', nameEn: 'Agate', formula: 'SiO₂', hardness: '7',
    colors: ['Vielfaeltig','Gestreift','Verlauf'], crystalSystem: 'Trigonal',
    origins: ['Brasilien','Uruguay','Botswana','Indien'],
    spiritualEffect: 'Balance, Harmonie, Erdung. Beruhigt aufgewuehlte Emotionen.',
    chakra: 'Wurzel', element: 'Erde',
    tags: ['Balance','Harmonie','Erdung','Beruhigung'],
    intentions: ['Balance','Beruhigung','Stabilitaet','Erdung'],
    emoji: '🪨', displayColor: Color(0xFF8D6E63),
    howToUse: 'Beim Spazierengehen in der Hand. Im Schlafzimmer fuer ruhige Naechte. Auf den Bauch bei Verdauungsstress.',
    birthMonths: [6], zodiac: ['Stier','Zwillinge','Jungfrau'], lifePathNumber: 4),

  // ── HEILSTEINE / SCHMUCKSTEINE ─────────────────────────────────────────
  CrystalEntry(
    name: 'Labradorit', nameEn: 'Labradorite', formula: 'CaAl₂Si₂O₈–NaAlSi₃O₈', hardness: '6-6.5',
    colors: ['Grau-blau mit Schimmer','Regenbogen'], crystalSystem: 'Triklin',
    origins: ['Labrador (Kanada)','Madagaskar','Finnland'],
    spiritualEffect: 'Magier-Stein. Schuetzt die Aura, foerdert Intuition und Magie.',
    chakra: 'Stirn', element: 'Wasser',
    tags: ['Intuition','Schutz','Magie','Transformation'],
    intentions: ['Intuition','Aura-Schutz','Traumarbeit','Synchronizitaet'],
    emoji: '🌈', displayColor: Color(0xFF455A64),
    howToUse: 'Als Anhaenger ueber dem Herzchakra. Bei Traumarbeit unter das Kissen. Bei energetischer Erschoepfung tragen.',
    birthMonths: [2,3], zodiac: ['Wassermann','Skorpion','Loewe'], lifePathNumber: 7),

  CrystalEntry(
    name: 'Mondstein', nameEn: 'Moonstone', formula: 'KAlSi₃O₈', hardness: '6-6.5',
    colors: ['Weiss-schimmernd','Pfirsich','Regenbogen'], crystalSystem: 'Monoklin',
    origins: ['Sri Lanka','Indien','Madagaskar'],
    spiritualEffect: 'Stein der goettlichen Weiblichkeit. Foerdert Intuition, sanfte Zyklen, Empfaenglichkeit.',
    chakra: 'Sakral', element: 'Wasser',
    tags: ['Weiblichkeit','Intuition','Zyklus','Empfaenglichkeit'],
    intentions: ['Zyklus-Harmonie','Intuition','Fruchtbarkeit','Sanftheit','Traumarbeit'],
    emoji: '🌙', displayColor: Color(0xFFF5F5F5),
    howToUse: 'Als Anhaenger waehrend des Menstruationszyklus. Auf das Sakralchakra. Bei Vollmond auf Fensterbank fuer Aufladung.',
    birthMonths: [6], zodiac: ['Krebs','Fische','Skorpion'], lifePathNumber: 2),

  CrystalEntry(
    name: 'Sonnenstein', nameEn: 'Sunstone', formula: 'NaAlSi₃O₈–CaAl₂Si₂O₈', hardness: '6-6.5',
    colors: ['Orange-rot','Goldorange'], crystalSystem: 'Triklin',
    origins: ['Norwegen','USA','Indien'],
    spiritualEffect: 'Stein der Lebensfreude und maennlichen Kraft. Vertreibt depressive Stimmung.',
    chakra: 'Sakral', element: 'Feuer',
    tags: ['Lebensfreude','Energie','Maennlich','Lichtstimmung'],
    intentions: ['Freude','Antrieb','Selbstvertrauen','Depression-Linderung'],
    emoji: '☀️', displayColor: Color(0xFFFF9800),
    howToUse: 'Morgens in die Hand nehmen, bewusst Sonne empfangen. Bei Antriebslosigkeit tragen.',
    birthMonths: [8], zodiac: ['Loewe','Widder','Schuetze'], lifePathNumber: 1),

  CrystalEntry(
    name: 'Obsidian', nameEn: 'Obsidian', formula: 'SiO₂ (vulkanisches Glas)', hardness: '5-5.5',
    colors: ['Schwarz','Schwarz-glaenzend','Rauchschwarz'], crystalSystem: 'Amorph',
    origins: ['Mexiko','Island','USA','Italien'],
    spiritualEffect: 'Spiegel-Stein. Zeigt schonungslos die Schattenseiten und befreit von Illusionen.',
    chakra: 'Wurzel', element: 'Feuer',
    tags: ['Schatten','Schutz','Wahrheit','Erdung'],
    intentions: ['Schatten-Arbeit','Wahrheit','Schutz','Loslassen'],
    emoji: '⚫', displayColor: Color(0xFF000000),
    careNote: 'Kann emotional intensiv sein -- bei akuten Krisen unter Begleitung nutzen.',
    howToUse: 'Bei Schatten-Arbeit kurz halten (nicht stundenlang). Als Schutz-Anhaenger bei Energie-Vampiren.',
    birthMonths: [10,11], zodiac: ['Skorpion','Steinbock','Schuetze'], lifePathNumber: 8),

  CrystalEntry(
    name: 'Malachit', nameEn: 'Malachite', formula: 'Cu₂(CO₃)(OH)₂', hardness: '3.5-4',
    colors: ['Gruen mit dunklen Baendern'], crystalSystem: 'Monoklin',
    origins: ['Kongo','Russland','Australien'],
    spiritualEffect: 'Wandlungsstein. Bringt verdraengte Emotionen ans Licht zur Heilung.',
    chakra: 'Herz', element: 'Erde',
    tags: ['Wandlung','Heilung','Schutz','Emotion'],
    intentions: ['Trauerverarbeitung','Transformation','Emotionale Heilung','Schutz'],
    emoji: '💚', displayColor: Color(0xFF388E3C),
    careNote: 'GIFTIG! Niemals in Wasser tauchen oder lutschen -- enthaelt Kupfer. Nur trocken reinigen mit Tuch.',
    howToUse: 'Als gefasster Anhaenger tragen. Auf das Herzchakra bei alter Trauer. Niemals roh ins Mund-Bereich.',
    birthMonths: [5], zodiac: ['Skorpion','Steinbock'], lifePathNumber: 9),

  CrystalEntry(
    name: 'Lapis Lazuli', nameEn: 'Lapis Lazuli', formula: 'Lazurit + Calcit + Pyrit', hardness: '5-5.5',
    colors: ['Tiefblau mit Goldsprenkeln'], crystalSystem: 'Kubisch',
    origins: ['Afghanistan','Chile','Russland'],
    spiritualEffect: 'Wahrheit, Weisheit, Selbstausdruck. Oeffnet Hals-Chakra und drittes Auge.',
    chakra: 'Hals', element: 'Luft',
    tags: ['Wahrheit','Weisheit','Ausdruck','Spirituell'],
    intentions: ['Wahrheit-sprechen','Weisheit','Selbstausdruck','Kommunikation'],
    emoji: '💙', displayColor: Color(0xFF1A237E),
    careNote: 'Nicht laenger in Wasser -- Pyrit-Einschluesse koennen rosten.',
    howToUse: 'Vor wichtigen Gespraechen am Hals tragen. Beim Schreiben auf den Tisch.',
    birthMonths: [9,12], zodiac: ['Schuetze','Wassermann','Jungfrau'], lifePathNumber: 7),

  CrystalEntry(
    name: 'Tuerkis', nameEn: 'Turquoise', formula: 'CuAl₆(PO₄)₄(OH)₈·4H₂O', hardness: '5-6',
    colors: ['Tuerkis-blau','Blaugruen'], crystalSystem: 'Triklin',
    origins: ['Iran','USA (Arizona)','Tibet'],
    spiritualEffect: 'Heiler und Schutzstein. Foerdert Kommunikation und Authentizitaet.',
    chakra: 'Hals', element: 'Luft',
    tags: ['Heilung','Schutz','Kommunikation','Reisen'],
    intentions: ['Reiseschutz','Authentizitaet','Halsbeschwerden','Heilung'],
    emoji: '🩵', displayColor: Color(0xFF26C6DA),
    careNote: 'Empfindlich gegen Schweiss, Parfuem, Sonne. Mit Olivenoel sanft pflegen.',
    howToUse: 'Als Reise-Amulett. Bei Halsthemen am Hals tragen. Auf Reisen am Bauch fuer Verdauung.',
    birthMonths: [12], zodiac: ['Schuetze','Skorpion','Fische'], lifePathNumber: 5),

  CrystalEntry(
    name: 'Haematit', nameEn: 'Hematite', formula: 'Fe₂O₃', hardness: '5.5-6.5',
    colors: ['Silber-metallisch','Rot bei Bruch'], crystalSystem: 'Trigonal',
    origins: ['Brasilien','China','Schweden'],
    spiritualEffect: 'Schwerer Erdungsstein. Bei Stress, Aengsten, geistiger Erschoepfung.',
    chakra: 'Wurzel', element: 'Erde',
    tags: ['Erdung','Schutz','Stabilisierung','Eisen'],
    intentions: ['Erdung','Stressabbau','Eisenmangel','Stabilitaet'],
    emoji: '🪙', displayColor: Color(0xFF455A64),
    careNote: 'Verliert Magnetismus mit der Zeit. Nicht ins Wasser (rostet).',
    howToUse: 'In den Schuhen bei Hitze oder Erschoepfung. Auf das Wurzelchakra. Als Armband bei Panik.',
    birthMonths: [3], zodiac: ['Widder','Wassermann','Steinbock'], lifePathNumber: 4),

  CrystalEntry(
    name: 'Granat', nameEn: 'Garnet', formula: '(Mg,Fe,Mn,Ca)₃(Al,Cr,Fe)₂(SiO₄)₃', hardness: '6.5-7.5',
    colors: ['Tiefrot','Granatrot'], crystalSystem: 'Kubisch',
    origins: ['Indien','Sri Lanka','Madagaskar'],
    spiritualEffect: 'Leidenschaft, Lebenskraft, Wille. Aktiviert die Wurzel-Energie.',
    chakra: 'Wurzel', element: 'Feuer',
    tags: ['Leidenschaft','Vitalitaet','Wille','Wurzel'],
    intentions: ['Leidenschaft','Energie','Mut','Sexualitaet','Manifestation'],
    emoji: '🍎', displayColor: Color(0xFFB71C1C),
    howToUse: 'Bei Energielosigkeit am Koerper tragen. Vor Sport oder anstrengender Arbeit aktivieren.',
    birthMonths: [1], zodiac: ['Steinbock','Wassermann','Loewe'], lifePathNumber: 8),

  CrystalEntry(
    name: 'Aquamarin', nameEn: 'Aquamarine', formula: 'Be₃Al₂Si₆O₁₈', hardness: '7.5-8',
    colors: ['Hellblau','Meerwasserblau'], crystalSystem: 'Hexagonal',
    origins: ['Brasilien','Madagaskar','Russland'],
    spiritualEffect: 'Stein des Mutes und der Klarheit. Wirkt wie ein klarer Bergsee fuer den Geist.',
    chakra: 'Hals', element: 'Wasser',
    tags: ['Mut','Klarheit','Kommunikation','Beruhigung'],
    intentions: ['Mut','Klarheit-sprechen','Beruhigung','Stressabbau'],
    emoji: '🌊', displayColor: Color(0xFF4FC3F7),
    howToUse: 'Vor wichtigen Vortraegen am Hals. Beim Schreiben auf den Tisch. Beim Schwimmen mitnehmen (sehr wasserfest).',
    birthMonths: [3], zodiac: ['Fische','Wassermann','Waage'], lifePathNumber: 2),

  CrystalEntry(
    name: 'Smaragd', nameEn: 'Emerald', formula: 'Be₃Al₂Si₆O₁₈', hardness: '7.5-8',
    colors: ['Tiefgruen'], crystalSystem: 'Hexagonal',
    origins: ['Kolumbien','Sambia','Brasilien'],
    spiritualEffect: 'Stein der Wahrheit und treuen Liebe. Oeffnet das Herzchakra weit.',
    chakra: 'Herz', element: 'Erde',
    tags: ['Liebe','Wahrheit','Treue','Heilung'],
    intentions: ['Bindung','Treue','Herzheilung','Wahrheit'],
    emoji: '💚', displayColor: Color(0xFF1B5E20),
    howToUse: 'Als Hochzeitsstein. Beim Klaeren wichtiger Beziehungs-Themen auf das Herzchakra legen.',
    birthMonths: [5], zodiac: ['Stier','Krebs','Waage'], lifePathNumber: 4),

  CrystalEntry(
    name: 'Saphir', nameEn: 'Sapphire', formula: 'Al₂O₃', hardness: '9',
    colors: ['Tiefblau','auch Rosa/Gelb/Gruen'], crystalSystem: 'Trigonal',
    origins: ['Sri Lanka','Burma','Thailand','Madagaskar'],
    spiritualEffect: 'Stein der Weisheit und himmlischen Wahrheit. Beruhigt geistige Verwirrung.',
    chakra: 'Stirn', element: 'Luft',
    tags: ['Weisheit','Wahrheit','Loyalitaet','Klarheit'],
    intentions: ['Weisheit','Konzentration','Loyalitaet','Klarheit'],
    emoji: '🔵', displayColor: Color(0xFF0D47A1),
    howToUse: 'Vor wichtigen Pruefungen am Hals tragen. Bei Entscheidungs-Schwierigkeiten auf die Stirn.',
    birthMonths: [9], zodiac: ['Jungfrau','Waage','Schuetze'], lifePathNumber: 9),

  CrystalEntry(
    name: 'Rubin', nameEn: 'Ruby', formula: 'Al₂O₃ + Cr', hardness: '9',
    colors: ['Tiefrot','Blutrot'], crystalSystem: 'Trigonal',
    origins: ['Burma','Thailand','Madagaskar'],
    spiritualEffect: 'Stein der Leidenschaft und Lebenskraft. Aktiviert Herz und Wurzel zugleich.',
    chakra: 'Wurzel', element: 'Feuer',
    tags: ['Leidenschaft','Mut','Liebe','Lebenskraft'],
    intentions: ['Leidenschaft','Mut','Liebe','Vitalitaet'],
    emoji: '❤️', displayColor: Color(0xFFC62828),
    howToUse: 'Als Schmuck bei matter Stimmung. Vor wichtigen Auftritten tragen.',
    birthMonths: [7], zodiac: ['Loewe','Krebs','Schuetze'], lifePathNumber: 3),

  CrystalEntry(
    name: 'Topas', nameEn: 'Topaz', formula: 'Al₂SiO₄(F,OH)₂', hardness: '8',
    colors: ['Gold','Blau','Klar','Pink'], crystalSystem: 'Orthorhombisch',
    origins: ['Brasilien','Russland','Pakistan'],
    spiritualEffect: 'Stein der Klarheit und des Ueberflusses. Schaerft Manifestations-Kraft.',
    chakra: 'Solarplexus', element: 'Feuer',
    tags: ['Klarheit','Manifestation','Selbstvertrauen','Wohlstand'],
    intentions: ['Manifestation','Klarheit','Wohlstand','Selbstvertrauen'],
    emoji: '💎', displayColor: Color(0xFFFFB300),
    howToUse: 'Beim Vision-Boarding in der Hand. Auf dem Schreibtisch fuer Karriere-Themen.',
    birthMonths: [11], zodiac: ['Schuetze','Loewe','Skorpion'], lifePathNumber: 3),

  CrystalEntry(
    name: 'Schwarzer Turmalin', nameEn: 'Black Tourmaline', formula: 'NaFe₃Al₆(BO₃)₃Si₆O₁₈(OH)₄', hardness: '7-7.5',
    colors: ['Schwarz'], crystalSystem: 'Trigonal',
    origins: ['Brasilien','Sri Lanka','USA'],
    spiritualEffect: 'Top-Schutzstein. Blockiert Elektrosmog, negative Energien, Energie-Vampire.',
    chakra: 'Wurzel', element: 'Erde',
    tags: ['Schutz','Erdung','Elektrosmog','Reinigung'],
    intentions: ['Schutz','Energiereinigung','Erdung','Elektrosmog-Abschirmung'],
    emoji: '🛡️', displayColor: Color(0xFF1B1B1B),
    howToUse: 'Neben Computer/Router platzieren. Am Eingang der Wohnung. Im Schuh bei Energie-Erschoepfung.',
    birthMonths: [10], zodiac: ['Steinbock','Skorpion','Stier'], lifePathNumber: 4),

  CrystalEntry(
    name: 'Pyrit', nameEn: 'Pyrite', formula: 'FeS₂', hardness: '6-6.5',
    colors: ['Messinggelb','Goldglaenzend'], crystalSystem: 'Kubisch',
    origins: ['Peru','Spanien','Russland'],
    spiritualEffect: 'Stein der Manifestation und des Wohlstands. Aktiviert die Solarplexus-Power.',
    chakra: 'Solarplexus', element: 'Feuer',
    tags: ['Wohlstand','Manifestation','Selbstvertrauen','Aktion'],
    intentions: ['Wohlstand','Geld-Manifestation','Selbstvertrauen','Action-Modus'],
    emoji: '🪙', displayColor: Color(0xFFFFB300),
    careNote: 'Reagiert mit Feuchtigkeit (rostet). Trocken halten.',
    howToUse: 'Auf dem Schreibtisch fuer Karriere-Erfolg. In der Geldboerse fuer Wohlstand. Niemals nass.',
    birthMonths: [5], zodiac: ['Loewe','Widder','Steinbock'], lifePathNumber: 8),

  CrystalEntry(
    name: 'Selenit', nameEn: 'Selenite', formula: 'CaSO₄·2H₂O', hardness: '2',
    colors: ['Weiss','Klar-weiss schimmernd'], crystalSystem: 'Monoklin',
    origins: ['Marokko','Mexiko','USA'],
    spiritualEffect: 'Selbstreinigend! Hoechste Schwingung. Reinigt Aura und andere Kristalle.',
    chakra: 'Krone', element: 'Aether',
    tags: ['Reinigung','Selbstreinigend','Aura','Hohe Schwingung'],
    intentions: ['Reinigung','Aura-Klaerung','Meditation','Engel-Verbindung'],
    emoji: '✨', displayColor: Color(0xFFF5F5F5),
    cleansing: 'KEINE Reinigung noetig -- Selenit reinigt sich selbst und andere Steine.',
    careNote: 'NIEMALS in Wasser! Loest sich auf. Sehr empfindlich.',
    howToUse: 'Andere Kristalle darauflegen zum Reinigen. Selenit-Stab fuer Aura-Streichen. Im Raum fuer Atmosphaere.',
    birthMonths: [6], zodiac: ['Krebs','Stier','Steinbock'], lifePathNumber: 7),

  CrystalEntry(
    name: 'Apatit', nameEn: 'Apatite', formula: 'Ca₅(PO₄)₃(F,Cl,OH)', hardness: '5',
    colors: ['Blau','Gruen','Gelb'], crystalSystem: 'Hexagonal',
    origins: ['Brasilien','Madagaskar','Mexiko'],
    spiritualEffect: 'Motivationsstein. Foerdert Selbstausdruck, Diaet-Disziplin, Inspiration.',
    chakra: 'Hals', element: 'Luft',
    tags: ['Motivation','Inspiration','Disziplin','Selbstausdruck'],
    intentions: ['Motivation','Diaet','Selbstausdruck','Inspiration'],
    emoji: '🟦', displayColor: Color(0xFF26C6DA),
    howToUse: 'Bei Diaet-Plaenen am Hals tragen. Bei kreativen Blockaden in die Hand. Vor Praesentationen.',
    birthMonths: [], zodiac: ['Zwillinge','Wassermann'], lifePathNumber: 5),

  CrystalEntry(
    name: 'Sodalith', nameEn: 'Sodalite', formula: 'Na₈(Al₆Si₆O₂₄)Cl₂', hardness: '5.5-6',
    colors: ['Tiefblau mit weiss'], crystalSystem: 'Kubisch',
    origins: ['Brasilien','Kanada','Russland'],
    spiritualEffect: 'Stein der Logik und Wahrheit. Beruhigt aufgeregten Geist, schaerft Analyse.',
    chakra: 'Hals', element: 'Luft',
    tags: ['Logik','Wahrheit','Beruhigung','Konzentration'],
    intentions: ['Konzentration','Logisches Denken','Wahrheit','Beruhigung'],
    emoji: '🔷', displayColor: Color(0xFF1565C0),
    howToUse: 'Beim Lernen auf den Schreibtisch. Bei Argumenten am Hals tragen.',
    birthMonths: [], zodiac: ['Schuetze','Jungfrau'], lifePathNumber: 9),

  CrystalEntry(
    name: 'Fluorit', nameEn: 'Fluorite', formula: 'CaF₂', hardness: '4',
    colors: ['Lila','Gruen','Blau','Klar','Regenbogen'], crystalSystem: 'Kubisch',
    origins: ['China','Mexiko','England','Deutschland'],
    spiritualEffect: 'Mental-Klaerer. Foerdert Konzentration, Lernen, mentale Ordnung.',
    chakra: 'Stirn', element: 'Luft',
    tags: ['Konzentration','Lernen','Klarheit','Mental'],
    intentions: ['Konzentration','Lernen','Pruefungen','Mental-Klarheit'],
    emoji: '💠', displayColor: Color(0xFF9575CD),
    careNote: 'Weich -- nicht zusammen mit haerteren Steinen aufbewahren.',
    howToUse: 'Auf dem Lerntisch. Bei Pruefungen in der Hosentasche. Auf das dritte Auge bei Verwirrung.',
    birthMonths: [], zodiac: ['Fische','Steinbock','Wassermann'], lifePathNumber: 7),

  CrystalEntry(
    name: 'Chrysokoll', nameEn: 'Chrysocolla', formula: '(Cu,Al)₂H₂Si₂O₅(OH)₄·nH₂O', hardness: '2-4',
    colors: ['Tuerkis-blau','Blaugruen'], crystalSystem: 'Amorph',
    origins: ['Israel','Peru','Kongo'],
    spiritualEffect: 'Stein des weiblichen Ausdrucks und der Friedensstifterin. Vermittelt zwischen Herz und Hals.',
    chakra: 'Hals', element: 'Wasser',
    tags: ['Weiblich','Ausdruck','Friede','Kommunikation'],
    intentions: ['Friedensstiftung','Weiblicher Ausdruck','Diplomatie','Sanftheit'],
    emoji: '🩵', displayColor: Color(0xFF4DD0E1),
    careNote: 'Sehr weich -- nicht in Wasser, nicht mit haerteren Steinen.',
    howToUse: 'Bei Konfliktgespraechen mitnehmen. Als Anhaenger am Hals fuer authentischen Ausdruck.',
    birthMonths: [], zodiac: ['Stier','Zwillinge','Jungfrau']),

  CrystalEntry(
    name: 'Schungit', nameEn: 'Shungite', formula: 'C₆₀ (Fulleren-Kohlenstoff)', hardness: '3.5-4',
    colors: ['Tiefschwarz'], crystalSystem: 'Amorph',
    origins: ['Russland (Karelien)'],
    spiritualEffect: 'Elektrosmog-Schild. Soll EMF-Strahlung neutralisieren, Aura schuetzen.',
    chakra: 'Wurzel', element: 'Erde',
    tags: ['Elektrosmog','Schutz','Reinigung','Aura'],
    intentions: ['EMF-Schutz','Aura-Reinigung','Wasser-Energetisierung','Erdung'],
    emoji: '🪨', displayColor: Color(0xFF1B1B1B),
    careNote: 'Faerbt manchmal ab -- nicht auf hellen Oberflaechen lagern.',
    howToUse: 'Neben WLAN-Router, Handy, Mikrowelle platzieren. Als Anhaenger bei viel Bildschirmarbeit.',
    birthMonths: [], zodiac: ['Steinbock','Skorpion']),

  CrystalEntry(
    name: 'Amazonit', nameEn: 'Amazonite', formula: 'KAlSi₃O₈', hardness: '6-6.5',
    colors: ['Tuerkis-gruen','Gruenblau'], crystalSystem: 'Triklin',
    origins: ['Brasilien','Russland','USA'],
    spiritualEffect: 'Stein der Hoffnung und der eigenen Wahrheit. Glaettet Stress.',
    chakra: 'Hals', element: 'Wasser',
    tags: ['Hoffnung','Wahrheit','Stress','Mut'],
    intentions: ['Stressabbau','Hoffnung','Mut-zur-Wahrheit','Sanftheit'],
    emoji: '🟢', displayColor: Color(0xFF66BB6A),
    howToUse: 'Bei chronischem Stress am Hals tragen. Beim Schreiben oder Sprechen schwieriger Themen.',
    birthMonths: [], zodiac: ['Jungfrau']),

  CrystalEntry(
    name: 'Howlith', nameEn: 'Howlite', formula: 'Ca₂B₅SiO₉(OH)₅', hardness: '3.5',
    colors: ['Weiss mit grauen Adern'], crystalSystem: 'Monoklin',
    origins: ['Kanada','USA'],
    spiritualEffect: 'Geduldsstein. Beruhigt Wut und impulsive Reaktionen.',
    chakra: 'Krone', element: 'Luft',
    tags: ['Geduld','Beruhigung','Wut-Mildernd','Schlaf'],
    intentions: ['Geduld','Wut-Beruhigung','Schlaf','Beruhigung'],
    emoji: '⚪', displayColor: Color(0xFFEEEEEE),
    howToUse: 'Bei impulsiven Wut-Momenten in die Hand. Unter dem Kissen fuer ruhigen Schlaf.',
    birthMonths: [], zodiac: ['Zwillinge','Krebs']),

  // ── WEITERE HEILSTEINE (Vol. 2) ────────────────────────────────────────
  CrystalEntry(
    name: 'Prehnit', nameEn: 'Prehnite', formula: 'Ca₂Al₂Si₃O₁₀(OH)₂', hardness: '6-6.5',
    colors: ['Hellgruen','Gelbgruen'], crystalSystem: 'Orthorhombisch',
    origins: ['Suedafrika','Australien'],
    spiritualEffect: 'Stein des bedingungslosen Loslassens. Heiler-Heiler-Stein.',
    chakra: 'Herz', element: 'Erde',
    tags: ['Loslassen','Heilung','Heiler-Stein'],
    intentions: ['Loslassen','Heilung','Selbst-Heilung'],
    emoji: '🌿', displayColor: Color(0xFFC5E1A5),
    howToUse: 'Fuer Therapeut:innen als Schutz beim Halten anderer. Bei Trauerprozessen am Herzen.',
    birthMonths: [], zodiac: ['Waage'], lifePathNumber: 6),

  CrystalEntry(
    name: 'Larimar', nameEn: 'Larimar', formula: 'NaCa₂Si₃O₈(OH)', hardness: '4.5-5',
    colors: ['Himmelblau','Tuerkis mit weissen Linien'], crystalSystem: 'Triklin',
    origins: ['Dominikanische Republik'],
    spiritualEffect: 'Atlantis-Stein. Bringt das Maennliche ins Sanfte, beruhigt erhitzte Gemueter.',
    chakra: 'Hals', element: 'Wasser',
    tags: ['Sanftheit','Beruhigung','Atlantisch','Heilung'],
    intentions: ['Beruhigung','Sanftheit','Maennlich-Weiblich-Balance'],
    emoji: '🪸', displayColor: Color(0xFF80DEEA),
    careNote: 'Lichtempfindlich -- nicht laenger in direkter Sonne.',
    howToUse: 'Bei hitzigen Konflikten am Hals tragen. Auf das Herz bei Verlust-Themen.',
    birthMonths: [], zodiac: ['Wassermann','Fische']),

  CrystalEntry(
    name: 'Kunzit', nameEn: 'Kunzite', formula: 'LiAlSi₂O₆', hardness: '6.5-7',
    colors: ['Hellrosa','Lila-rosa'], crystalSystem: 'Monoklin',
    origins: ['Afghanistan','Madagaskar','Brasilien'],
    spiritualEffect: 'Stein der goettlichen Liebe und Hingabe. Sehr sanft, oeffnet das Herz weit.',
    chakra: 'Herz', element: 'Wasser',
    tags: ['Liebe','Hingabe','Sanftheit','Spirituell'],
    intentions: ['Selbstliebe','Goettliche-Liebe','Hingabe','Sanftheit'],
    emoji: '🌺', displayColor: Color(0xFFF8BBD0),
    careNote: 'Lichtempfindlich -- verblasst bei Sonne.',
    howToUse: 'Bei Herzschmerz auf das Herzchakra. Als Anhaenger bei Liebes-Themen.',
    birthMonths: [], zodiac: ['Stier','Loewe','Skorpion']),

  CrystalEntry(
    name: 'Charoit', nameEn: 'Charoite', formula: '(K,Na)₅Ca₈Si₁₈O₄₆(OH,F)·H₂O', hardness: '5-6',
    colors: ['Lila-violett mit Maserung'], crystalSystem: 'Monoklin',
    origins: ['Russland (Sibirien)'],
    spiritualEffect: 'Stein der Transformation. Hilft bei tiefer Lebenswende.',
    chakra: 'Krone', element: 'Aether',
    tags: ['Transformation','Wandel','Wende','Mut'],
    intentions: ['Transformation','Lebenswende','Mut-zur-Veraenderung'],
    emoji: '🟣', displayColor: Color(0xFF7B1FA2),
    howToUse: 'In Lebens-Uebergangs-Phasen kontinuierlich am Koerper tragen.',
    birthMonths: [], zodiac: ['Skorpion','Schuetze']),

  CrystalEntry(
    name: 'Lepidolith', nameEn: 'Lepidolite', formula: 'K(Li,Al)₃(Si,Al)₄O₁₀(F,OH)₂', hardness: '2.5-3',
    colors: ['Lila','Hellrosa'], crystalSystem: 'Monoklin',
    origins: ['Brasilien','Madagaskar','USA'],
    spiritualEffect: 'Enthaelt natuerliches Lithium. Beruhigt bei Angst und Depression.',
    chakra: 'Stirn', element: 'Luft',
    tags: ['Beruhigung','Angst','Depression','Schlaf'],
    intentions: ['Angstloesung','Schlaf','Beruhigung','Depression-Linderung'],
    emoji: '💜', displayColor: Color(0xFFCE93D8),
    careNote: 'Sehr weich -- bricht leicht. Trocken halten.',
    howToUse: 'Bei Angstattacken in die Hand. Unter dem Kissen bei Albtraeumen. Beim Meditieren auf das dritte Auge.',
    birthMonths: [], zodiac: ['Waage','Fische']),

  CrystalEntry(
    name: 'Apophyllit', nameEn: 'Apophyllite', formula: 'KCa₄Si₈O₂₀(F,OH)·8H₂O', hardness: '4.5-5',
    colors: ['Klar','Weiss','Gruen'], crystalSystem: 'Tetragonal',
    origins: ['Indien'],
    spiritualEffect: 'Engelsstein. Bringt das Krongebiet zum Strahlen, foerdert Engelskontakt.',
    chakra: 'Krone', element: 'Aether',
    tags: ['Engel','Krongebiet','Hohe Schwingung','Reinheit'],
    intentions: ['Engelskontakt','Hoehere Schwingung','Meditation','Reinheit'],
    emoji: '👼', displayColor: Color(0xFFE1F5FE),
    careNote: 'Sehr empfindlich -- nicht ins Wasser, vor Stoss schuetzen.',
    howToUse: 'Auf dem Meditations-Altar. Beim Beten oder Engel-Anrufung in der Hand.',
    birthMonths: [], zodiac: ['Waage','Zwillinge']),

  CrystalEntry(
    name: 'Karneol', nameEn: 'Carnelian', formula: 'SiO₂', hardness: '7',
    colors: ['Orange-rot'], crystalSystem: 'Trigonal',
    origins: ['Brasilien','Indien','Madagaskar'],
    spiritualEffect: 'Lebenskraft, Selbstvertrauen, Kreativitaet. Aktiviert Sakralchakra.',
    chakra: 'Sakral', element: 'Feuer',
    tags: ['Lebenskraft','Kreativitaet','Selbstvertrauen'],
    intentions: ['Kreativitaet','Selbstvertrauen','Sexualitaet','Mut'],
    emoji: '🟠', displayColor: Color(0xFFFF6F00),
    howToUse: 'Bei Schreibblockade auf den Schreibtisch. Vor Auftritten am Koerper.',
    birthMonths: [7], zodiac: ['Stier','Krebs','Jungfrau'], lifePathNumber: 5),

  CrystalEntry(
    name: 'Pietersit', nameEn: 'Pietersite', formula: 'SiO₂', hardness: '7',
    colors: ['Blaugrau-gold mit Schimmer'], crystalSystem: 'Trigonal',
    origins: ['Namibia','China'],
    spiritualEffect: 'Tempest-Stone -- bringt Sturm der Veraenderung in stehende Wasser.',
    chakra: 'Stirn', element: 'Luft',
    tags: ['Veraenderung','Visionaer','Mut'],
    intentions: ['Visionssuche','Mut-zur-Veraenderung','Klarheit'],
    emoji: '🌪️', displayColor: Color(0xFF3F51B5),
    howToUse: 'Vor wichtigen Lebens-Entscheidungen meditativ in die Hand.',
    birthMonths: [], zodiac: ['Loewe','Schuetze']),

  CrystalEntry(
    name: 'Moldavit', nameEn: 'Moldavite', formula: 'SiO₂ Glas', hardness: '5.5-7',
    colors: ['Tiefgruen','Mossgruen'], crystalSystem: 'Amorph',
    origins: ['Tschechien (Meteoriten-Einschlag-Glas)'],
    spiritualEffect: 'Auerirdischer Beschleuniger. Verstaerkt jeden spirituellen Prozess radikal.',
    chakra: 'Herz', element: 'Aether',
    tags: ['Beschleuniger','Transformation','Ausserirdisch','Intensiv'],
    intentions: ['Spirituelle Beschleunigung','Tiefe Wandlung','Sternen-Verbindung'],
    emoji: '☄️', displayColor: Color(0xFF2E7D32),
    careNote: 'Intensiv -- kann zu starker innerer Bewegung fuehren. Mit Vorsicht und in Begleitung.',
    howToUse: 'Nur kurz in der Hand halten am Anfang. Auf das Herzchakra bei reifer Praxis.',
    birthMonths: [], zodiac: ['Skorpion']),

  CrystalEntry(
    name: 'Azurit', nameEn: 'Azurite', formula: 'Cu₃(CO₃)₂(OH)₂', hardness: '3.5-4',
    colors: ['Tiefblau'], crystalSystem: 'Monoklin',
    origins: ['Marokko','Australien','Namibia'],
    spiritualEffect: 'Stein der inneren Stimme. Schaerft Intuition und drittes Auge.',
    chakra: 'Stirn', element: 'Luft',
    tags: ['Intuition','Drittes-Auge','Visionen'],
    intentions: ['Intuition','Visionen','Hellsicht','Klarheit'],
    emoji: '🔵', displayColor: Color(0xFF1A237E),
    careNote: 'GIFTIG (Kupfer). Nicht in Wasser, nicht ans Mund-Bereich.',
    howToUse: 'Auf das dritte Auge bei Meditation. Beim Traumarbeiten ans Bett.',
    birthMonths: [], zodiac: ['Schuetze','Wassermann']),

  CrystalEntry(
    name: 'Sugilith', nameEn: 'Sugilite', formula: 'KNa₂(Fe,Mn,Al)₂Li₃Si₁₂O₃₀', hardness: '6-6.5',
    colors: ['Tieflila','Violett'], crystalSystem: 'Hexagonal',
    origins: ['Suedafrika','Japan'],
    spiritualEffect: 'Goldenes-Licht-Stein. Schuetzt sensible Menschen, foerdert spirituelle Wahrheit.',
    chakra: 'Krone', element: 'Aether',
    tags: ['Schutz','Spirituell','Empath-Stein','Wahrheit'],
    intentions: ['Empath-Schutz','Spirituelle Wahrheit','Hohe Schwingung'],
    emoji: '💜', displayColor: Color(0xFF6A1B9A),
    howToUse: 'Fuer hochsensible Menschen als Schutzschmuck. Beim Channeling auf der Krone.',
    birthMonths: [], zodiac: ['Jungfrau','Schuetze']),

  CrystalEntry(
    name: 'Rhodonit', nameEn: 'Rhodonite', formula: '(Mn,Fe,Mg,Ca)SiO₃', hardness: '5.5-6.5',
    colors: ['Pink mit schwarzen Adern'], crystalSystem: 'Triklin',
    origins: ['Russland','Schweden','Australien'],
    spiritualEffect: 'Verzeihensstein. Hilft alte Wunden und Groll zu loesen.',
    chakra: 'Herz', element: 'Erde',
    tags: ['Verzeihen','Heilung','Trauma','Liebe'],
    intentions: ['Verzeihen','Trauma-Heilung','Herzheilung','Versoehnung'],
    emoji: '💗', displayColor: Color(0xFFE91E63),
    howToUse: 'Auf das Herzchakra bei alten Wunden. Vor Versoehnungs-Gespraechen mitnehmen.',
    birthMonths: [], zodiac: ['Stier','Krebs']),

  CrystalEntry(
    name: 'Rhodochrosit', nameEn: 'Rhodochrosite', formula: 'MnCO₃', hardness: '3.5-4',
    colors: ['Pink-rosa mit weissen Baendern'], crystalSystem: 'Trigonal',
    origins: ['Argentinien','Peru','USA'],
    spiritualEffect: 'Stein des Inneren Kindes. Heilt fruehe emotionale Wunden.',
    chakra: 'Herz', element: 'Wasser',
    tags: ['Inneres-Kind','Heilung','Liebe','Selbstwert'],
    intentions: ['Inneres-Kind-Arbeit','Selbstwert','Emotionale Heilung'],
    emoji: '🌷', displayColor: Color(0xFFEC407A),
    careNote: 'Empfindlich gegen Saeure und Hitze. Nicht laenger ins Wasser.',
    howToUse: 'Bei inneres-Kind-Meditation auf das Herzchakra. Als sanfter Tagesbegleiter.',
    birthMonths: [], zodiac: ['Loewe','Skorpion']),

  CrystalEntry(
    name: 'Heliotrop', nameEn: 'Bloodstone', formula: 'SiO₂ + Eisenoxid', hardness: '6.5-7',
    colors: ['Dunkelgruen mit roten Punkten'], crystalSystem: 'Trigonal',
    origins: ['Indien','Australien'],
    spiritualEffect: 'Stein der Krieger. Mut, Vitalitaet, Schutz im Kampf.',
    chakra: 'Wurzel', element: 'Erde',
    tags: ['Mut','Krieger','Vitalitaet','Schutz'],
    intentions: ['Mut','Schutz','Vitalitaet','Selbstbehauptung'],
    emoji: '🩸', displayColor: Color(0xFF2E7D32),
    howToUse: 'Bei Konflikten zur Selbstbehauptung tragen. Bei Erschoepfung auf den Solarplexus.',
    birthMonths: [3], zodiac: ['Widder','Steinbock','Fische']),

  CrystalEntry(
    name: 'Jaspis (Roter)', nameEn: 'Red Jasper', formula: 'SiO₂', hardness: '7',
    colors: ['Rot','Rotbraun'], crystalSystem: 'Trigonal',
    origins: ['Brasilien','Indien','Madagaskar'],
    spiritualEffect: 'Stein der Erdung und Stabilitaet. Klassischer Wurzel-Aktivator.',
    chakra: 'Wurzel', element: 'Erde',
    tags: ['Erdung','Stabilitaet','Wurzel','Vitalitaet'],
    intentions: ['Erdung','Stabilitaet','Stresstoleranz'],
    emoji: '🟥', displayColor: Color(0xFFC62828),
    howToUse: 'Bei Bodenstaendigkeit gefragt: Hosentasche. Bei Hitzewellen oder Panik: in die Hand.',
    birthMonths: [], zodiac: ['Widder','Stier']),

  CrystalEntry(
    name: 'Jaspis (Ozean)', nameEn: 'Ocean Jasper', formula: 'SiO₂', hardness: '7',
    colors: ['Gruen-blau-weiss-rosa Punkte'], crystalSystem: 'Trigonal',
    origins: ['Madagaskar'],
    spiritualEffect: 'Stein der Freude und sanften Heilung. Wie ein Strand in der Hand.',
    chakra: 'Herz', element: 'Wasser',
    tags: ['Freude','Heilung','Sanft','Strand'],
    intentions: ['Freude','Stressabbau','Sanftheit','Heilung'],
    emoji: '🏖️', displayColor: Color(0xFFB2DFDB),
    howToUse: 'Bei chronischer Niedergeschlagenheit am Koerper tragen. Beim Lesen oder Faulenzen in der Hand.',
    birthMonths: [], zodiac: ['Krebs','Fische']),

  CrystalEntry(
    name: 'Unakit', nameEn: 'Unakite', formula: 'Granit-Komposit', hardness: '6-7',
    colors: ['Gruen mit rosa Flecken'], crystalSystem: 'Verschieden',
    origins: ['USA','Suedafrika'],
    spiritualEffect: 'Beziehungs-Stein. Bringt Herzqualitaet ins Tun.',
    chakra: 'Herz', element: 'Erde',
    tags: ['Beziehung','Herz','Wachstum'],
    intentions: ['Beziehungs-Harmonie','Herz-Wachstum','Geduld'],
    emoji: '🌷', displayColor: Color(0xFF9CCC65),
    howToUse: 'Im Schlafzimmer als Paar-Stein. Bei eigenem Herz-Wachstum am Koerper tragen.',
    birthMonths: [], zodiac: ['Skorpion']),

  CrystalEntry(
    name: 'Diamant', nameEn: 'Diamond', formula: 'C', hardness: '10',
    colors: ['Klar','Champagner','Pink','Blau (selten)'], crystalSystem: 'Kubisch',
    origins: ['Suedafrika','Russland','Australien','Kanada'],
    spiritualEffect: 'Stein der Klarheit und Unbesiegbarkeit. Verstaerkt jede Schwingung um ein Vielfaches.',
    chakra: 'Krone', element: 'Aether',
    tags: ['Klarheit','Unbesiegbarkeit','Verstaerker','Reinheit'],
    intentions: ['Maximale Klarheit','Unbesiegbarkeit','Hohe Schwingung','Manifestation'],
    emoji: '💎', displayColor: Color(0xFFE0E0E0),
    howToUse: 'Als Schmuck staendig. Bei wichtigen Lebens-Entscheidungen kurz halten.',
    birthMonths: [4], zodiac: ['Widder','Stier','Loewe']),

  CrystalEntry(
    name: 'Bernstein', nameEn: 'Amber', formula: 'Versteinerter Baumharz', hardness: '2-2.5',
    colors: ['Gold','Honigfarben','Kirsche'], crystalSystem: 'Amorph',
    origins: ['Baltikum','Dominikanische Republik','Russland'],
    spiritualEffect: 'Stein der Sonne und Lebensfreude. Versteinerte Energie aus Millionen Jahren.',
    chakra: 'Solarplexus', element: 'Feuer',
    tags: ['Lebensfreude','Sonne','Schutz','Wachstum'],
    intentions: ['Lebensfreude','Zahnen (Babys)','Lichtstimmung','Energie'],
    emoji: '🍯', displayColor: Color(0xFFFFAB00),
    careNote: 'Sehr weich -- kratzt leicht. Vor Alkohol/Parfum schuetzen.',
    howToUse: 'Klassisch als Bernstein-Kette fuer zahnende Babys. Allgemein als Sonnen-Schmuck.',
    birthMonths: [], zodiac: ['Loewe','Wassermann','Jungfrau']),

  CrystalEntry(
    name: 'Aragonit', nameEn: 'Aragonite', formula: 'CaCO₃', hardness: '3.5-4',
    colors: ['Braun','Hellbraun','Sand'], crystalSystem: 'Orthorhombisch',
    origins: ['Spanien','Marokko'],
    spiritualEffect: 'Stein der Erdung in Geduld. Bringt Ruhe ins ueberhastete Tun.',
    chakra: 'Wurzel', element: 'Erde',
    tags: ['Geduld','Erdung','Ruhe'],
    intentions: ['Geduld','Stresstoleranz','Erdung'],
    emoji: '🟫', displayColor: Color(0xFF8D6E63),
    howToUse: 'Bei Hetze in die Hand. Vor stressigen Phasen unter dem Kopfkissen.',
    birthMonths: [], zodiac: ['Steinbock']),

  CrystalEntry(
    name: 'Calcit (Honig)', nameEn: 'Honey Calcite', formula: 'CaCO₃', hardness: '3',
    colors: ['Honiggelb','Goldorange'], crystalSystem: 'Trigonal',
    origins: ['Mexiko','Brasilien'],
    spiritualEffect: 'Stein der suessen Lebenskraft. Aktiviert Solarplexus auf sanfte Art.',
    chakra: 'Solarplexus', element: 'Feuer',
    tags: ['Lebenskraft','Sanftheit','Solarplexus','Selbstvertrauen'],
    intentions: ['Selbstvertrauen','Sanfte Aktivierung','Lebenskraft'],
    emoji: '🍯', displayColor: Color(0xFFFFA000),
    careNote: 'Weich -- nicht ins Wasser, nicht mit haerteren Steinen.',
    howToUse: 'Bei sanftem Aufbau von Selbstvertrauen am Koerper. Auf den Solarplexus.',
    birthMonths: [], zodiac: ['Loewe','Krebs']),

  CrystalEntry(
    name: 'Kyanit (Blauer)', nameEn: 'Blue Kyanite', formula: 'Al₂SiO₅', hardness: '4.5-7',
    colors: ['Tiefblau','Hellblau'], crystalSystem: 'Triklin',
    origins: ['Brasilien','Nepal','USA'],
    spiritualEffect: 'Selbstreinigender Aura-Aligner. Bringt alle Chakren ins Lot.',
    chakra: 'Hals', element: 'Luft',
    tags: ['Aura','Selbstreinigend','Alignment','Wahrheit'],
    intentions: ['Aura-Alignment','Selbstreinigung','Wahrheit','Klarheit'],
    emoji: '🔵', displayColor: Color(0xFF1976D2),
    cleansing: 'Selbstreinigend -- keine Pflege noetig.',
    howToUse: 'Vor Meditation entlang der Wirbelsaeule fuehren. Im Buero fuer mentale Klarheit.',
    birthMonths: [], zodiac: ['Stier','Waage','Fische']),

  CrystalEntry(
    name: 'Smithsonit', nameEn: 'Smithsonite', formula: 'ZnCO₃', hardness: '4-4.5',
    colors: ['Hellblau-gruen','Rosa'], crystalSystem: 'Trigonal',
    origins: ['Mexiko','Namibia'],
    spiritualEffect: 'Stein der sanften Heilung. Beruhigt seelische Wunden.',
    chakra: 'Herz', element: 'Wasser',
    tags: ['Sanft','Heilung','Beruhigung'],
    intentions: ['Sanfte Heilung','Trauer','Selbstmitgefuehl'],
    emoji: '🌸', displayColor: Color(0xFFB2DFDB),
    careNote: 'Weich -- nicht ins Wasser.',
    howToUse: 'Bei tiefer Trauer am Herzchakra. Sanfter Tagesbegleiter.',
    birthMonths: [], zodiac: ['Jungfrau']),

  CrystalEntry(
    name: 'Petalit', nameEn: 'Petalite', formula: 'LiAlSi₄O₁₀', hardness: '6-6.5',
    colors: ['Klar','Hellrosa','Weiss'], crystalSystem: 'Monoklin',
    origins: ['Brasilien','Schweden','Australien'],
    spiritualEffect: 'Engelstein. Sanftes Lithium fuer hochsensible Menschen.',
    chakra: 'Krone', element: 'Aether',
    tags: ['Engel','Sanftheit','Empath'],
    intentions: ['Empath-Schutz','Sanftheit','Hohe Schwingung'],
    emoji: '✨', displayColor: Color(0xFFE1F5FE),
    howToUse: 'Beim Channeling ueber der Krone. Fuer hochsensible Menschen taeglich am Koerper.',
    birthMonths: [], zodiac: ['Loewe','Fische']),

  CrystalEntry(
    name: 'Dumortierit', nameEn: 'Dumortierite', formula: 'Al₇BO₃(SiO₄)₃O₃', hardness: '7-8.5',
    colors: ['Tiefblau','Violett-blau'], crystalSystem: 'Orthorhombisch',
    origins: ['Frankreich','Brasilien','Namibia'],
    spiritualEffect: 'Lernstein. Foerdert Lernerfolg und logisches Denken.',
    chakra: 'Stirn', element: 'Luft',
    tags: ['Lernen','Konzentration','Logik'],
    intentions: ['Lernerfolg','Konzentration','Pruefungen'],
    emoji: '📚', displayColor: Color(0xFF283593),
    howToUse: 'Auf dem Lerntisch bei Pruefungen. Beim Erlernen einer neuen Sprache als Begleiter.',
    birthMonths: [], zodiac: ['Loewe','Schuetze']),

  CrystalEntry(
    name: 'Chrysopras', nameEn: 'Chrysoprase', formula: 'SiO₂', hardness: '7',
    colors: ['Apfelgruen'], crystalSystem: 'Trigonal',
    origins: ['Australien','Polen','Brasilien'],
    spiritualEffect: 'Stein der jugendlichen Frische. Foerdert Hoffnung und Neuanfang.',
    chakra: 'Herz', element: 'Erde',
    tags: ['Hoffnung','Neuanfang','Heilung','Frische'],
    intentions: ['Hoffnung','Neuanfang','Frische','Liebe'],
    emoji: '🍏', displayColor: Color(0xFF7CB342),
    howToUse: 'Bei depressiver Stimmung am Herzen. Bei Sehnsucht nach Neuem in die Hand.',
    birthMonths: [5], zodiac: ['Stier','Waage','Krebs']),

  CrystalEntry(
    name: 'Peridot', nameEn: 'Peridot', formula: '(Mg,Fe)₂SiO₄', hardness: '6.5-7',
    colors: ['Hellgruen','Olivgruen'], crystalSystem: 'Orthorhombisch',
    origins: ['Pakistan','USA','China'],
    spiritualEffect: 'Stein der heilsamen Loesung von Schuldgefuehlen.',
    chakra: 'Herz', element: 'Erde',
    tags: ['Heilung','Schuld-Loesung','Wohlstand'],
    intentions: ['Schuldgefuehl-Loesung','Selbstvergebung','Wohlstand'],
    emoji: '🌱', displayColor: Color(0xFF9CCC65),
    howToUse: 'Bei Selbstvorwurf-Spiralen am Herzen. Als Wohlstands-Schmuck.',
    birthMonths: [8], zodiac: ['Loewe','Jungfrau','Skorpion']),

  CrystalEntry(
    name: 'Aragonit-Stern', nameEn: 'Star Aragonite', formula: 'CaCO₃', hardness: '3.5-4',
    colors: ['Braun-orange Sterne-Form'], crystalSystem: 'Orthorhombisch',
    origins: ['Marokko','Spanien'],
    spiritualEffect: 'Stein der Bewusstwerdung. Bringt Klarheit ueber das eigene Tun.',
    chakra: 'Wurzel', element: 'Erde',
    tags: ['Bewusstheit','Erdung','Klarheit'],
    intentions: ['Bewusstheit','Erdung','Reife'],
    emoji: '✴️', displayColor: Color(0xFFBF360C),
    careNote: 'Sehr empfindlich gegen Stoss und Saeure.',
    howToUse: 'Auf den Schreibtisch fuer bewusstes Arbeiten. Beim Tagebuchschreiben in die Hand.',
    birthMonths: [], zodiac: ['Steinbock']),

  CrystalEntry(
    name: 'Spinell', nameEn: 'Spinel', formula: 'MgAl₂O₄', hardness: '8',
    colors: ['Rot','Pink','Blau','Schwarz'], crystalSystem: 'Kubisch',
    origins: ['Burma','Sri Lanka','Tadschikistan'],
    spiritualEffect: 'Erneuerungsstein. Hilft beim Aufstehen nach Niederlagen.',
    chakra: 'Wurzel', element: 'Feuer',
    tags: ['Erneuerung','Mut','Wiederaufstehen','Kraft'],
    intentions: ['Erneuerung','Comeback','Mut','Kraft'],
    emoji: '🔺', displayColor: Color(0xFFAD1457),
    howToUse: 'Nach Lebens-Niederlagen kontinuierlich am Koerper tragen.',
    birthMonths: [8], zodiac: ['Schuetze','Loewe']),

  CrystalEntry(
    name: 'Tansanit', nameEn: 'Tanzanite', formula: 'Ca₂Al₃(SiO₄)(Si₂O₇)O(OH)', hardness: '6.5-7',
    colors: ['Tiefblau-violett'], crystalSystem: 'Orthorhombisch',
    origins: ['Tansania (einzige Quelle weltweit)'],
    spiritualEffect: 'Stein des hoeheren Wissens. Verbindet Hals (Wahrheit) mit Stirn (Visionen).',
    chakra: 'Stirn', element: 'Aether',
    tags: ['Hoeheres-Wissen','Wahrheit','Visionen'],
    intentions: ['Hoeheres-Wissen','Visionen','Wahrheit'],
    emoji: '💎', displayColor: Color(0xFF512DA8),
    howToUse: 'Auf der Stirn waehrend Meditation. Als Schmuck bei wichtigen Lebens-Entscheidungen.',
    birthMonths: [12], zodiac: ['Wassermann','Zwillinge']),

  CrystalEntry(
    name: 'Lepidocrocit', nameEn: 'Lepidocrocite', formula: 'FeO(OH)', hardness: '5',
    colors: ['Rostrot-orange'], crystalSystem: 'Orthorhombisch',
    origins: ['Madagaskar','Brasilien'],
    spiritualEffect: 'Geliebte-Erde-Stein. Verbindet stark mit der Erd-Mutter.',
    chakra: 'Wurzel', element: 'Erde',
    tags: ['Erdung','Mutter-Erde','Verbindung'],
    intentions: ['Erdung','Verbindung-mit-Erde','Heimat'],
    emoji: '🍂', displayColor: Color(0xFFBF360C),
    howToUse: 'Beim Wandern in der Natur in die Hand. Bei Heimweh am Wurzelchakra.',
    birthMonths: [], zodiac: ['Stier']),

  CrystalEntry(
    name: 'Phenakit', nameEn: 'Phenakite', formula: 'Be₂SiO₄', hardness: '7.5-8',
    colors: ['Klar','Weiss'], crystalSystem: 'Trigonal',
    origins: ['Brasilien','Russland'],
    spiritualEffect: 'Hochschwingender Krongebiet-Aktivator. Sehr selten.',
    chakra: 'Krone', element: 'Aether',
    tags: ['Hochschwingend','Krongebiet','Visionaer'],
    intentions: ['Hoechste Schwingung','Channeling','Visionen'],
    emoji: '⭐', displayColor: Color(0xFFE0E0E0),
    careNote: 'Sehr empfindlich -- nur fuer erfahrene Praktizierende.',
    howToUse: 'Nur in fortgeschrittener spiritueller Praxis verwenden. Auf der Krone bei Meditation.',
    birthMonths: [], zodiac: ['Schuetze']),

  CrystalEntry(
    name: 'Achroit (Weisser Turmalin)', nameEn: 'Achroite', formula: 'NaLi₃Al₆(BO₃)₃Si₆O₁₈(OH)₄', hardness: '7-7.5',
    colors: ['Klar','Weiss'], crystalSystem: 'Trigonal',
    origins: ['Brasilien','Madagaskar'],
    spiritualEffect: 'Reinheits-Turmalin. Sanfte Reinigung der Aura.',
    chakra: 'Krone', element: 'Aether',
    tags: ['Reinheit','Aura','Sanftheit'],
    intentions: ['Aura-Reinigung','Reinheit','Friede'],
    emoji: '🤍', displayColor: Color(0xFFF5F5F5),
    howToUse: 'Sanft entlang der Aura streichen. Auf der Krone bei Meditation.',
    birthMonths: [], zodiac: ['Waage']),

  CrystalEntry(
    name: 'Watermelon-Turmalin', nameEn: 'Watermelon Tourmaline', formula: 'NaLi₃Al₆(BO₃)₃Si₆O₁₈(OH)₄', hardness: '7-7.5',
    colors: ['Pink innen, Gruen aussen'], crystalSystem: 'Trigonal',
    origins: ['Brasilien','Madagaskar'],
    spiritualEffect: 'Doppel-Liebes-Stein. Heilt Herz und schenkt grosszuegige Energie.',
    chakra: 'Herz', element: 'Erde',
    tags: ['Liebe','Heilung','Grosszuegigkeit'],
    intentions: ['Herz-Heilung','Selbstliebe','Grosszuegigkeit'],
    emoji: '🍉', displayColor: Color(0xFFE91E63),
    howToUse: 'Auf das Herzchakra. Als Schmuck bei Beziehungs-Themen.',
    birthMonths: [], zodiac: ['Stier','Waage']),

  CrystalEntry(
    name: 'Picasso-Marmor', nameEn: 'Picasso Marble', formula: 'CaCO₃ mit Einschluessen', hardness: '3-4',
    colors: ['Cream mit Adern'], crystalSystem: 'Trigonal',
    origins: ['Utah (USA)'],
    spiritualEffect: 'Stein der inneren Geschichte. Hilft eigene Vergangenheit zu integrieren.',
    chakra: 'Wurzel', element: 'Erde',
    tags: ['Geschichte','Integration','Erdung'],
    intentions: ['Vergangenheits-Integration','Erdung'],
    emoji: '🎨', displayColor: Color(0xFF8D6E63),
    howToUse: 'Beim Tagebuch- oder Lebensruckblick in die Hand.',
    birthMonths: [], zodiac: ['Steinbock']),

  CrystalEntry(
    name: 'Septarie', nameEn: 'Septarian', formula: 'CaCO₃ + Calcit + Aragonit', hardness: '3-4',
    colors: ['Gelb-braun mit weissen Linien'], crystalSystem: 'Verschieden',
    origins: ['Madagaskar','USA'],
    spiritualEffect: 'Stein der ganzheitlichen Erdung. Vereint Element-Energien.',
    chakra: 'Wurzel', element: 'Erde',
    tags: ['Erdung','Ganzheit','Elemente'],
    intentions: ['Ganzheits-Gefuehl','Erdung','Integration'],
    emoji: '🥚', displayColor: Color(0xFFFFB74D),
    howToUse: 'Bei Ueberforderung in beide Haende. Auf den Bauch bei Verdauungs-Themen.',
    birthMonths: [], zodiac: ['Stier','Steinbock']),

  CrystalEntry(
    name: 'Septarie-Drache', nameEn: 'Septarian Dragon', formula: 'CaCO₃ + Aragonit + Calcit', hardness: '3-4',
    colors: ['Gelb-braun-grau'], crystalSystem: 'Verschieden',
    origins: ['Madagaskar'],
    spiritualEffect: 'Drachen-Energie. Mut und uralte Weisheit zugleich.',
    chakra: 'Wurzel', element: 'Erde',
    tags: ['Mut','Weisheit','Drachenenergie'],
    intentions: ['Mut','Uralte Weisheit','Schutz'],
    emoji: '🐲', displayColor: Color(0xFFD7CCC8),
    howToUse: 'Bei wichtigen Lebens-Schritten als Kraftstein. Auf dem Altar fuer Schutz.',
    birthMonths: [], zodiac: ['Schuetze','Loewe']),
];

/// Hilfs-Lookup: liefert Kristalle die fuer eine bestimmte Intention passen.
List<CrystalEntry> crystalsForIntention(String intention) {
  final q = intention.toLowerCase();
  return crystalLibrary.where((c) {
    if (c.intentions.any((i) => i.toLowerCase().contains(q))) return true;
    if (c.tags.any((t) => t.toLowerCase().contains(q))) return true;
    return false;
  }).toList();
}

/// Birthstone-Lookup: Kristalle fuer einen Geburtsmonat 1-12.
List<CrystalEntry> crystalsForMonth(int month) =>
    crystalLibrary.where((c) => c.birthMonths.contains(month)).toList();

/// Sternzeichen-Lookup.
List<CrystalEntry> crystalsForZodiac(String zodiac) =>
    crystalLibrary.where((c) => c.zodiac.contains(zodiac)).toList();

/// Lebenszahl-Lookup.
List<CrystalEntry> crystalsForLifePath(int n) =>
    crystalLibrary.where((c) => c.lifePathNumber == n).toList();

/// Chakra-Lookup.
List<CrystalEntry> crystalsForChakra(String chakra) =>
    crystalLibrary.where((c) => c.chakra == chakra).toList();
