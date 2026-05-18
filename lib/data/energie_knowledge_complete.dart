import '../models/knowledge_extended_models.dart';

/// ============================================
/// ENERGIE WISSENSDATENBANK - KOMPLETT
/// Alle 50 Einträge (5 bereits in energie_knowledge_data.dart)
/// Diese 45 zusätzlichen Einträge ergänzen die Datenbank
/// ============================================

final List<KnowledgeEntry> energieKnowledgeComplete = [
  // EINTRÄGE 6-50 (45 weitere)
  
  // ==========================================
  // MEDITATION (10 weitere) - ene_006 bis ene_015
  // ==========================================
  
  KnowledgeEntry(
    id: 'ene_006',
    world: 'energie',
    title: 'Zazen - Zen Meditation der Samurai',
    description: 'Sitzmeditation im Zen-Buddhismus - "Nur sitzen"',
    fullContent: '''# Zazen - Die Kunst des Sitzens

## Was ist Zazen?
**Zazen** (Sitz-Meditation auf Japanisch) ist die Kern-Praxis aller Zen-Schulen.

## Geschichte
- **Ursprung:** China (Chan-Buddhismus, 500 AD)
- **Japan:** Eingeführt durch Dōgen Zenji (1200 AD)
- **Samurai:** Nutzten Zazen für mentale Stärke

## Die Technik

### Sitzposition (Lotus oder Seiza)
- Aufrechte Wirbelsäule
- Hände im Mudra (Daumen berühren sich leicht)
- Augen halb offen (Blick 45° nach unten)

### "Shikantaza" - Nur Sitzen
- Kein Fokus auf Atem oder Mantra
- Reine Gegenwärtigkeit
- Gedanken kommen und gehen wie Wolken

### Kinhin (Geh-Meditation)
Langsames Gehen zwischen Zazen-Sitzungen

## Zen-Klöster
- **Täglicher Ablauf:** 10+ Stunden Zazen
- **Sesshin:** Intensive 7-Tage-Retreats
- **Oryoki:** Ritualisierte Mahlzeiten

## Vorteile
- Mentale Klarheit
- Emotionale Stabilität
- "Kein-Geist" (Mushin)
- Perfekt für Krieger-Training

## Moderne Anwendung
- Führungskräfte nutzen Zazen
- Steve Jobs praktizierte täglich
- Silicon Valley Zen-Zentren

**Kern-Weisheit:** "Wenn du sitzt, sitz. Wenn du gehst, geh. Aber wackle nicht."
''',
    category: 'meditation',
    type: 'practice',
    tags: ['Zazen', 'Zen', 'Samurai', 'Shikantaza'],
    createdAt: DateTime(2024, 1, 22),
    readingTimeMinutes: 10,
  ),

  KnowledgeEntry(
    id: 'ene_007',
    world: 'energie',
    title: 'Metta Bhavana - Liebende-Güte Meditation',
    description: 'Kultiviere bedingungslose Liebe für dich selbst und alle Wesen',
    fullContent: '''# Metta Bhavana - Die Meditation der Liebe

## Was ist Metta?
**Metta** (Pali) = Liebende Güte, bedingungslose Liebe ohne Anhaftung.

## Die 5 Stufen

### 1. Selbst
Beginne mit dir: "Möge ich glücklich sein. Möge ich gesund sein. Möge ich in Frieden leben."

### 2. Geliebte Person
Jemand dem du dankbar bist (Lehrer, Freund)

### 3. Neutrale Person
Jemand den du kaum kennst (Nachbar, Kassierer)

### 4. Schwierige Person
Jemand mit dem du Konflikt hast

### 5. Alle Wesen
Erweitere Liebe auf alle Lebewesen

## Wissenschaft
- Aktiviert Präfrontaler Cortex (Empathie)
- Reduziert Amygdala-Aktivität (Angst)
- Erhöht Oxytocin (Bindungshormon)

## Traditionen
- **Buddhismus:** Kernpraxis
- **Yoga:** Karuna (Mitgefühl)
- **Christentum:** "Liebe deinen Nächsten"

**Transformation:** Wandelt Hass in Verständnis, Angst in Liebe.
''',
    category: 'meditation',
    type: 'practice',
    tags: ['Metta', 'Liebende Güte', 'Compassion', 'Buddhismus'],
    createdAt: DateTime(2024, 1, 23),
    readingTimeMinutes: 9,
  ),

  KnowledgeEntry(
    id: 'ene_008',
    world: 'energie',
    title: 'Transcendental Meditation (TM) - Maharishi Technik',
    description: 'Mantra-basierte Meditation - 20 Minuten zweimal täglich',
    fullContent: '''# Transcendental Meditation (TM)

## Geschichte
- **Gründer:** Maharishi Mahesh Yogi (1950s)
- **Beatles:** Lernten TM in Indien (1968)
- **Verbreitung:** 10 Millionen+ Praktizierende

## Die Technik
- **Mantra:** Persönliches Mantra (Sanskrit-Silben)
- **Zeit:** 20 Minuten, 2x täglich
- **Methode:** Müheloses Wiederholen des Mantras
- **Kein Fokus:** Gedanken dürfen kommen/gehen

## TM Lehrer
Man kann TM nur von zertifizierten Lehrern lernen (kontrovers - hohe Kosten).

## Wissenschaftliche Studien
- Über 600 Studien
- Reduziert Blutdruck
- Erhöht Kohärenz im Gehirn
- PTSD-Behandlung (Veteranen)

## Prominente Praktizierende
- David Lynch (Filmregisseur)
- Oprah Winfrey
- Jerry Seinfeld
- Katy Perry

## Kritik
- Hohe Kurskosten (\$1000+)
- Geheimhaltung der Mantras
- Organisation als "Kult" beschuldigt

**Kernidee:** Transzendiere Gedanken, erreiche reines Bewusstsein.
''',
    category: 'meditation',
    type: 'practice',
    tags: ['TM', 'Maharishi', 'Mantra', 'Beatles'],
    createdAt: DateTime(2024, 1, 24),
    readingTimeMinutes: 11,
  ),

  KnowledgeEntry(
    id: 'ene_009',
    world: 'energie',
    title: 'Chakra Meditation - Energiezentren aktivieren',
    description: '7 Chakras von Wurzel bis Krone - Farben, Mantras, Blockaden',
    fullContent: '''# Chakra Meditation

## Die 7 Hauptchakras

### 1. Muladhara (Wurzelchakra) - ROT
- **Lage:** Basis der Wirbelsäule
- **Element:** Erde
- **Mantra:** LAM
- **Thema:** Überleben, Sicherheit, Erdung

### 2. Svadhisthana (Sakralchakra) - ORANGE
- **Lage:** Unterbauch
- **Element:** Wasser
- **Mantra:** VAM
- **Thema:** Kreativität, Sexualität, Emotionen

### 3. Manipura (Solarplexus) - GELB
- **Lage:** Oberbauch
- **Element:** Feuer
- **Mantra:** RAM
- **Thema:** Macht, Willen, Selbstwert

### 4. Anahata (Herzchakra) - GRÜN
- **Lage:** Herz
- **Element:** Luft
- **Mantra:** YAM
- **Thema:** Liebe, Mitgefühl, Vergebung

### 5. Vishuddha (Kehlchakra) - BLAU
- **Lage:** Kehle
- **Element:** Äther
- **Mantra:** HAM
- **Thema:** Kommunikation, Wahrheit, Ausdruck

### 6. Ajna (Drittes Auge) - INDIGO
- **Lage:** Stirn (zwischen Augenbrauen)
- **Element:** Licht
- **Mantra:** OM
- **Thema:** Intuition, Vision, Weisheit

### 7. Sahasrara (Kronenchakra) - VIOLETT/WEISS
- **Lage:** Scheitel
- **Element:** Gedanke/Kosmos
- **Mantra:** Stille / OM
- **Thema:** Erleuchtung, Einheit, Göttlichkeit

## Meditation-Technik
1. Sitz aufrecht (Lotus oder Stuhl)
2. Beginne bei Wurzel
3. Visualisiere Farbe, chante Mantra
4. Fühle Energie in jedem Chakra
5. Arbeite dich nach oben

## Blockaden erkennen
- **Wurzel blockiert:** Angst, Unsicherheit
- **Sakral blockiert:** Kreativlosigkeit, Schuldgefühle
- **Solarplexus blockiert:** Mangel an Selbstwert
- **Herz blockiert:** Unfähigkeit zu lieben
- **Kehle blockiert:** Kommunikationsprobleme
- **Drittes Auge blockiert:** Mangel an Intuition
- **Krone blockiert:** Spirituelle Leere

**Ziel:** Alle Chakras in Balance - freier Energiefluss.
''',
    category: 'meditation',
    type: 'practice',
    tags: ['Chakras', 'Kundalini', 'Energie', 'Mantras'],
    createdAt: DateTime(2024, 1, 25),
    readingTimeMinutes: 14,
  ),

  KnowledgeEntry(
    id: 'ene_010',
    world: 'energie',
    title: 'Trataka - Kerzen-Starr-Meditation',
    description: 'Yogische Reinigungstechnik für Augen und Geist',
    fullContent: '''# Trataka - Die Flammen-Meditation

## Was ist Trataka?
**Trataka** ist eine der 6 Shatkarmas (Reinigungstechniken) im Hatha Yoga. Bedeutet "starren".

## Technik
1. Kerze auf Augenhöhe (2-3 Meter entfernt)
2. Starre auf Flamme ohne zu blinzeln (1-3 Minuten)
3. Schließe Augen, visualisiere Flamme im Dritten Auge
4. Wenn Nachbild verblasst, öffne Augen, wiederhole

## Vorteile
- **Augen:** Stärkt Sehkraft, reinigt Tränenkanäle
- **Geist:** Verbessert Konzentration, stoppt Gedanken
- **Drittes Auge:** Aktiviert Ajna-Chakra
- **Schlaf:** Behandelt Schlaflosigkeit

## Variationen
- **Bahya Trataka:** Äußeres Objekt (Kerze, Punkt, Symbol)
- **Antar Trataka:** Innere Visualisierung (Chakra, Gottheit)

## Traditionelle Anleitung
- **Zeit:** Morgens oder vor Schlaf
- **Dauer:** 5-20 Minuten
- **Vorsicht:** Nicht bei Augen-Krankheiten

**Weisheit:** "Wo der Blick hingeht, folgt die Energie."
''',
    category: 'meditation',
    type: 'practice',
    tags: ['Trataka', 'Yoga', 'Drittes Auge', 'Konzentration'],
    createdAt: DateTime(2024, 1, 26),
    readingTimeMinutes: 8,
  ),

  // Weitere Meditations-Einträge (kompakt)
  KnowledgeEntry(
    id: 'ene_011',
    world: 'energie',
    title: 'Body Scan Meditation - Progressive Entspannung',
    description: 'Systematisches Durchgehen des Körpers von Kopf bis Fuß',
    fullContent: 'Body Scan aus MBSR (Jon Kabat-Zinn). Beginne bei Kopf oder Füßen, wandere langsam durch jeden Körperteil. Beobachte Empfindungen ohne Bewertung. Perfekt für: Schlaf, Stressabbau, Körperbewusstsein. Dauer: 20-45 Minuten. Wissenschaft: Aktiviert Parasympathikus (Entspannung), reduziert chronische Schmerzen.',
    category: 'meditation',
    type: 'practice',
    tags: ['Body Scan', 'MBSR', 'Entspannung'],
    createdAt: DateTime(2024, 1, 27),
    readingTimeMinutes: 7,
  ),

  KnowledgeEntry(
    id: 'ene_012',
    world: 'energie',
    title: 'Mantra Meditation - OM & Sanskrit Silben',
    description: 'Kraftvolle Klang-Vibrationen für Gehirn und Körper',
    fullContent: 'OM (AUM): Ur-Klang des Universums. A (Erschaffung), U (Erhaltung), M (Zerstörung). Weitere Mantras: So Ham (Ich bin das), Gayatri Mantra (Schutz), Om Mani Padme Hum (Mitgefühl). Wissenschaft: Vagus-Nerv-Stimulation, Gehirnwellen-Kohärenz. 108 Wiederholungen traditionell (Mala-Kette). Wirkung: Beruhigung, Fokus, spirituelle Öffnung.',
    category: 'meditation',
    type: 'practice',
    tags: ['Mantra', 'OM', 'Sanskrit', 'Vibration'],
    createdAt: DateTime(2024, 1, 28),
    readingTimeMinutes: 9,
  ),

  KnowledgeEntry(
    id: 'ene_013',
    world: 'energie',
    title: 'Walking Meditation - Achtsamkeit in Bewegung',
    description: 'Zen-Geh-Meditation und Mindful Walking',
    fullContent: 'Langsames, bewusstes Gehen (1 Schritt pro Atemzug). Fühle jeden Fuß: Anheben, Bewegen, Platzieren. Zen: Kinhin (zwischen Zazen-Sitzungen). Thich Nhat Hanh: "Gehe als ob du den Boden küsst". Perfekt für Unruhige, die nicht stillsitzen können. Variante: Labyrinth-Gehen (Chartres-Labyrinth). Vorteile: Balance, Erdung, Integration von Meditation in Alltag.',
    category: 'meditation',
    type: 'practice',
    tags: ['Walking Meditation', 'Kinhin', 'Thich Nhat Hanh'],
    createdAt: DateTime(2024, 1, 29),
    readingTimeMinutes: 6,
  ),

  KnowledgeEntry(
    id: 'ene_014',
    world: 'energie',
    title: 'Wim Hof Methode - Atmung, Kälte, Fokus',
    description: 'Kontrolliere Immunsystem durch Hyperventilation und Kälteexposition',
    fullContent: 'Wim Hof ("The Iceman"): 3 Säulen - 1) Atmung (30-40 tiefe Atemzüge + Atem anhalten), 2) Kälte-Exposition (Eiswasser, kalte Duschen), 3) Fokus/Meditation. Wissenschaft: Kann Immunsystem willentlich steuern (Radboud University Study). Vorteile: Energie, Immunsystem, mentale Stärke. 26 Weltrekorde (längste Eiswasser-Zeit, höchster Berg barfuß). Achtung: Nicht beim Fahren/Schwimmen praktizieren!',
    category: 'meditation',
    type: 'practice',
    tags: ['Wim Hof', 'Atmung', 'Kälte', 'Immunsystem'],
    createdAt: DateTime(2024, 2, 1),
    readingTimeMinutes: 12,
  ),

  KnowledgeEntry(
    id: 'ene_015',
    world: 'energie',
    title: 'Yoga Nidra - Der yogische Schlaf',
    description: '1 Stunde Yoga Nidra = 4 Stunden Schlaf - Tiefenentspannung',
    fullContent: 'Yoga Nidra (Swami Satyananda Saraswati): Liege in Shavasana, folge geführter Meditation. Phasen: Sankalpa (Absicht), Body Scan, Atem-Bewusstsein, Gefühle, Visualisierungen. Zustand zwischen Wach und Schlaf (hypnagogic state). Wissenschaft: Theta-Wellen-Dominanz, Subconscious Reprogramming. Anwendung: Trauma-Heilung, Stress, Schlafprobleme, Manifestation. Apps: Insight Timer, Yoga Nidra Network.',
    category: 'meditation',
    type: 'practice',
    tags: ['Yoga Nidra', 'Schlaf', 'Entspannung', 'Sankalpa'],
    createdAt: DateTime(2024, 2, 2),
    readingTimeMinutes: 11,
  ),

  // ==========================================
  // ASTROLOGIE (15) - ene_016 bis ene_030
  // ==========================================

  KnowledgeEntry(
    id: 'ene_016',
    world: 'energie',
    title: 'Astrologie Grundlagen - 12 Häuser erklärt',
    description: 'Die 12 Lebensbereiche im Horoskop',
    fullContent: '''# Die 12 Häuser in der Astrologie

## 1. Haus - Selbst & Persönlichkeit
- **Thema:** ICH, physisches Erscheinungsbild, Lebensansatz
- **Ascendent** (Aszendent) beginnt hier

## 2. Haus - Werte & Besitz
- **Thema:** Geld, Ressourcen, Selbstwert

## 3. Haus - Kommunikation & Lernen
- **Thema:** Geschwister, Nachbarschaft, Schreiben, Reisen

## 4. Haus - Familie & Wurzeln
- **Thema:** Zuhause, Eltern (Mutter), emotionale Basis
- **IC** (Imum Coeli) - tiefster Punkt

## 5. Haus - Kreativität & Freude
- **Thema:** Kinder, Romanze, Hobbies, Selbstausdruck

## 6. Haus - Gesundheit & Arbeit
- **Thema:** Tägliche Routine, Service, Haustiere

## 7. Haus - Beziehungen & Partnerschaften
- **Thema:** Ehe, Business-Partner, offene Feinde
- **Descendant** (DC) beginnt hier

## 8. Haus - Transformation & Geheimnisse
- **Thema:** Sex, Tod, Erbe, Okkultismus, Psychologie

## 9. Haus - Philosophie & Fernreisen
- **Thema:** Höhere Bildung, Religion, Ausland

## 10. Haus - Karriere & Status
- **Thema:** Berufung, Reputation, Eltern (Vater)
- **MC** (Medium Coeli) - höchster Punkt

## 11. Haus - Freundschaft & Gemeinschaft
- **Thema:** Gruppen, Hoffnungen, Technologie

## 12. Haus - Spiritualität & Unbewusstes
- **Thema:** Rückzug, Geheimnisse, Karma, Mystik

**Interpretation:** Planeten in Häusern zeigen WO Energie wirkt, Zeichen zeigen WIE.
''',
    category: 'astrology',
    type: 'knowledge',
    tags: ['Astrologie', '12 Häuser', 'Horoskop'],
    createdAt: DateTime(2024, 2, 3),
    readingTimeMinutes: 10,
  ),

  KnowledgeEntry(
    id: 'ene_017',
    world: 'energie',
    title: 'Planeten & ihre Bedeutung - Von Sonne bis Pluto',
    description: 'Die 10 Himmelskörper und ihre astrologischen Kräfte',
    fullContent: '''# Die 10 Planeten in der Astrologie

## Persönliche Planeten (schnell)

### Sonne ☉
- **Bedeutung:** Kern-Ich, Ego, Lebenskraft
- **Zyklus:** 1 Jahr (durch Tierkreis)
- **Herrscht:** Löwe

### Mond ☽
- **Bedeutung:** Emotionen, Unbewusstes, Mutter
- **Zyklus:** 28 Tage
- **Herrscht:** Krebs

### Merkur ☿
- **Bedeutung:** Kommunikation, Denken, Reisen
- **Zyklus:** 88 Tage
- **Herrscht:** Zwillinge, Jungfrau
- **Retrograde:** 3-4x pro Jahr (Kommunikations-Chaos!)

### Venus ♀
- **Bedeutung:** Liebe, Schönheit, Werte, Geld
- **Zyklus:** 225 Tage
- **Herrscht:** Stier, Waage

### Mars ♂
- **Bedeutung:** Aktion, Aggression, Sexualität, Krieg
- **Zyklus:** 2 Jahre
- **Herrscht:** Widder (und Skorpion traditionell)

## Soziale Planeten

### Jupiter ♃
- **Bedeutung:** Expansion, Glück, Weisheit, Überfluss
- **Zyklus:** 12 Jahre
- **Herrscht:** Schütze (und Fische traditionell)

### Saturn ♄
- **Bedeutung:** Struktur, Disziplin, Karma, Grenzen
- **Zyklus:** 29 Jahre
- **Herrscht:** Steinbock (und Wassermann traditionell)
- **Saturn Return:** 29, 58, 87 Jahre (Lebens-Lektionen!)

## Generationsplaneten (langsam)

### Uranus ♅
- **Bedeutung:** Revolution, Freiheit, Technologie, Schock
- **Zyklus:** 84 Jahre
- **Herrscht:** Wassermann

### Neptun ♆
- **Bedeutung:** Illusion, Spiritualität, Träume, Sucht
- **Zyklus:** 165 Jahre
- **Herrscht:** Fische

### Pluto ♇
- **Bedeutung:** Transformation, Macht, Tod/Wiedergeburt
- **Zyklus:** 248 Jahre
- **Herrscht:** Skorpion

**Generationsplaneten:** Prägen ganze Generationen (z.B. Pluto in Skorpion 1983-1995 = Millennials).
''',
    category: 'astrology',
    type: 'knowledge',
    tags: ['Planeten', 'Astrologie', 'Horoskop'],
    createdAt: DateTime(2024, 2, 4),
    readingTimeMinutes: 13,
  ),

  KnowledgeEntry(
    id: 'ene_018',
    world: 'energie',
    title: 'Mondphasen & Manifestation - Neumond bis Vollmond',
    description: 'Nutze Mondzyklus für Absichten, Loslassen und Magie',
    fullContent: '''# Mondphasen-Zyklus

## 1. Neumond 🌑
- **Energie:** Neuanfang, Pflanzen von Seeds
- **Aktion:** Setze Absichten (Manifestation)
- **Ritual:** Schreibe 10 Wünsche, visualisiere

## 2. Zunehmender Mond 🌒
- **Energie:** Wachstum, Expansion
- **Aktion:** Handle auf Ziele hin, baue auf
- **Dauer:** 2 Wochen

## 3. Vollmond 🌕
- **Energie:** Höhepunkt, Erleuchtung, Emotion
- **Aktion:** Loslassen, Vergeben, Feiern
- **Ritual:** Full Moon Release (schreibe was du loslässt, verbrenne)

## 4. Abnehmender Mond 🌘
- **Energie:** Reduktion, Reinigung
- **Aktion:** Detox, Aufräumen, Reflektieren
- **Dauer:** 2 Wochen

## Spezielle Monde

### Blue Moon
Zweiter Vollmond im selben Monat (selten = "once in a blue moon")

### Super Moon
Vollmond nah an Erde (erscheint größer)

### Blood Moon
Totale Mondfinsternis (rot)

### Black Moon
Zweiter Neumond im Monat

## Manifestations-Ritual

### Neumond:
1. Schreibe: "Ich manifestiere..." (10 Absichten)
2. Visualisiere als ob bereits passiert
3. Fühle die Emotion
4. Lasse los (Vertrauen)

### Vollmond:
1. Schreibe: "Ich lasse los..." (Blockaden, Ängste)
2. Danke für Lektionen
3. Verbrenne Papier (sicher!)
4. Bad nehmen (Salzwasser-Reinigung)

**Wissenschaft:** Mond beeinflusst Gezeiten, Menstruation, Schlaf - warum nicht Energie?
''',
    category: 'astrology',
    type: 'practice',
    tags: ['Mondphasen', 'Manifestation', 'Vollmond', 'Neumond'],
    createdAt: DateTime(2024, 2, 5),
    readingTimeMinutes: 12,
  ),

  // Weitere Astrologie-Einträge (kompakt)
  KnowledgeEntry(
    id: 'ene_019',
    world: 'energie',
    title: 'Merkur Retrograde - Warum alles schief geht',
    description: '3-4x pro Jahr läuft Merkur rückwärts - Kommunikation, Technologie, Reisen leiden',
    fullContent: 'Merkur Retrograde: Planet scheint rückwärts zu laufen (optische Illusion). Effekte: Kommunikations-Fehler, Tech-Ausfälle, Reise-Verspätungen, Ex-Partner tauchen auf. Dauer: 3 Wochen, 3-4x pro Jahr. Regeln: NICHT unterschreiben, kaufen, reisen. DOCH: reflektieren, reparieren, re-connecten. Pre-Shadow + Post-Shadow: je 2 Wochen vor/nach. Tipp: Backup deine Daten!',
    category: 'astrology',
    type: 'knowledge',
    tags: ['Merkur Retrograde', 'Planeten', 'Chaos'],
    createdAt: DateTime(2024, 2, 6),
    readingTimeMinutes: 8,
  ),

  KnowledgeEntry(
    id: 'ene_020',
    world: 'energie',
    title: 'Saturn Return - Die 29-Jahr-Krise',
    description: 'Lebens-Test mit 29 und 58 Jahren - Zeit für Wahrheit',
    fullContent: 'Saturn Return: Saturn kehrt zu Geburts-Position zurück (alle 29 Jahre). Alter: 29-30 & 58-59. Effekte: Lebens-Überprüfung, Beziehungs-Ende, Karriere-Wechsel, Krisen. Ziel: Reifen, Verantwortung, Authentizität. Beispiele: Kurt Cobain starb mit 27 (vor Saturn Return), viele Stars haben mit 29 Breakthrough. Rat: Akzeptiere Veränderung, baue solides Fundament. Dauer: 2-3 Jahre.',
    category: 'astrology',
    type: 'knowledge',
    tags: ['Saturn Return', '29 Jahre', 'Krise', 'Transformation'],
    createdAt: DateTime(2024, 2, 7),
    readingTimeMinutes: 9,
  ),

  KnowledgeEntry(
    id: 'ene_021',
    world: 'energie',
    title: 'Synastrie - Beziehungs-Astrologie',
    description: 'Vergleiche 2 Horoskope - Kompatibilität, Karma, Seelenverträge',
    fullContent: 'Synastrie: Overlay von 2 Geburtshoroskopen. Wichtige Aspekte: Venus-Mars (Anziehung), Mond-Mond (Emotion), Sonne-Mond (Balance), Saturn-persönliche Planeten (Karma). Composite Chart: Mittelpunkt beider Charts (Beziehungs-Identität). Nodes: Nordknoten-Verbindungen = Schicksal. 7. Haus: Partnerschaften. Herausfordernd: Quadrate, Oppositionen. Harmonisch: Trinen, Sextile. Soulmates haben oft schwierige Aspekte (Wachstum!).',
    category: 'astrology',
    type: 'knowledge',
    tags: ['Synastrie', 'Beziehungen', 'Kompatibilität', 'Soulmate'],
    createdAt: DateTime(2024, 2, 8),
    readingTimeMinutes: 11,
  ),

  KnowledgeEntry(
    id: 'ene_022',
    world: 'energie',
    title: 'Vedische Astrologie (Jyotish) - Das indische System',
    description: 'Sidereal vs. Tropical - 23° Unterschied, karmische Astrologie',
    fullContent: 'Vedische (Jyotish) Astrologie: Nutzt Sidereal Zodiac (echte Stern-Positionen), nicht Tropical (westlich, Jahreszeiten). Unterschied: 23° (Ayanamsa) - dein westliches Zeichen kann vedisch anders sein! 27 Nakshatras (Mond-Häuser). Dasha-System: Planeten-Perioden (z.B. Venus-Periode 20 Jahre). Karma-fokussiert: Past Lives, Dharma. Präziser für Timing (Ereignis-Vorhersage). Auch: Muhurta (Wahl-Astrologie für beste Tage).',
    category: 'astrology',
    type: 'knowledge',
    tags: ['Vedic Astrology', 'Jyotish', 'Sidereal', 'Karma'],
    createdAt: DateTime(2024, 2, 9),
    readingTimeMinutes: 10,
  ),

  KnowledgeEntry(
    id: 'ene_023',
    world: 'energie',
    title: 'Chiron - Der verwundete Heiler',
    description: 'Astrologischer Komet zeigt deine tiefste Wunde und Heilungs-Gabe',
    fullContent: 'Chiron: Komet zwischen Saturn & Uranus. Entdeckt 1977. Bedeutung: Deine tiefste Wunde (oft aus Kindheit), die zur Heilungs-Kraft wird. Chiron in Zeichen: wo du verletzt wurdest. Chiron in Häusern: wo du heilen musst. Chiron Return: 50-51 Jahre (Heilungs-Krise und Weisheit). Aspekte: Chiron-Sonne (Ego-Verletzung), Chiron-Venus (Liebes-Wunden). Ziel: Heile dich selbst, dann andere.',
    category: 'astrology',
    type: 'knowledge',
    tags: ['Chiron', 'Heilung', 'Wunden', 'Astrologie'],
    createdAt: DateTime(2024, 2, 10),
    readingTimeMinutes: 9,
  ),

  KnowledgeEntry(
    id: 'ene_024',
    world: 'energie',
    title: 'Lilith (Black Moon) - Die dunkle Göttin',
    description: 'Unterdrückte weibliche Kraft, Sexualität, Rebellion',
    fullContent: 'Black Moon Lilith: Nicht ein Planet, sondern Mond-Apogäum (weitester Punkt Mond-Orbit). Mythologie: Adams erste Frau (vor Eva), verließ Eden weil sie gleich sein wollte. Bedeutung: Unterdrückte Sexualität, Macht, Wut, Taboo. Lilith in Zeichen: wie du rebellierst. Lilith in Häusern: wo du Scham fühlst. Aspekte: Lilith-Venus (erotische Spannung), Lilith-Mars (rohe Sexualität). Schatten-Arbeit erforderlich.',
    category: 'astrology',
    type: 'knowledge',
    tags: ['Lilith', 'Black Moon', 'Schatten', 'Sexualität'],
    createdAt: DateTime(2024, 2, 11),
    readingTimeMinutes: 10,
  ),

  // Weitere Astrologie kompakt
  KnowledgeEntry(
    id: 'ene_025',
    world: 'energie',
    title: 'Aszendent - Deine soziale Maske',
    description: 'Rising Sign - wie andere dich sehen, erste Impression',
    fullContent: 'Aszendent (Rising Sign): Zeichen das im Osten aufging bei Geburt. Bestimmt 1. Haus und äußere Persönlichkeit. Sonne = Wer du bist, Mond = Was du fühlst, Aszendent = Wie du wirkst. Ändert sich alle 2 Stunden - braucht exakte Geburtszeit. Körper & Stil: Aszendent beeinflusst Aussehen. Lebensreise: Aszendent zu Descendant (7. Haus) ist Wachstums-Achse.',
    category: 'astrology',
    type: 'knowledge',
    tags: ['Aszendent', 'Rising Sign', 'Persönlichkeit'],
    createdAt: DateTime(2024, 2, 12),
    readingTimeMinutes: 7,
  ),

  KnowledgeEntry(
    id: 'ene_026',
    world: 'energie',
    title: 'Nordknoten & Südknoten - Schicksal & Karma',
    description: 'Lunar Nodes zeigen Past Life & Soul Purpose',
    fullContent: 'Lunar Nodes: Punkte wo Mond-Orbit Ekliptik kreuzt. Südknoten = Past Life Skills (Komfortzone). Nordknoten = Soul Mission (Wachstums-Richtung). Immer gegenüber (180°). Nordknoten in Zeichen: Qualität zu entwickeln. Nordknoten in Haus: Lebens-Bereich für Wachstum. Nodal Return: alle 18 Jahre (Schicksals-Wendepunkt). Ziel: Vom Südknoten (sicher) zum Nordknoten (beängstigend aber erfüllend).',
    category: 'astrology',
    type: 'knowledge',
    tags: ['Nodes', 'Nordknoten', 'Karma', 'Past Life'],
    createdAt: DateTime(2024, 2, 13),
    readingTimeMinutes: 9,
  ),

  KnowledgeEntry(
    id: 'ene_027',
    world: 'energie',
    title: 'Eklipsen - Schicksals-Portale',
    description: 'Solar & Lunar Eclipses bringen plötzliche Veränderungen',
    fullContent: 'Eklipsen passieren wenn Sonne/Mond mit Lunar Nodes aligned. Solar Eclipse (Neumond): Neuanfänge, Doors öffnen. Lunar Eclipse (Vollmond): Enden, Wahrheit revealed. Effekt: 6 Monate vor/nach Eklipse. Eclipse Saison: 2x pro Jahr. Totale Eklipse = mächtigster. Nicht manifestieren während Eclipse! Lasse Schicksal wirken. Geburts-Eklipse: Wenn geboren während Eclipse, intensives Leben mit Schicksals-Ereignissen.',
    category: 'astrology',
    type: 'knowledge',
    tags: ['Eclipse', 'Eklipse', 'Schicksal', 'Nodes'],
    createdAt: DateTime(2024, 2, 14),
    readingTimeMinutes: 8,
  ),

  KnowledgeEntry(
    id: 'ene_028',
    world: 'energie',
    title: 'Progressed Chart - Deine innere Evolution',
    description: 'Secondary Progressions zeigen innere Entwicklung (1 Tag = 1 Jahr)',
    fullContent: 'Progressed Chart: Tag-für-Tag Bewegung nach Geburt = Jahr-für-Jahr inneres Wachstum. Formel: 1 Tag nach Geburt = 1 Jahr Leben. Progressed Moon: ändert Zeichen alle 2.5 Jahre (emotionale Phasen). Progressed Sun: neues Zeichen alle 30 Jahre (Life Chapter). Aspekte: Wenn progressed Planet Geburts-Planet berührt = bedeutsame innere Veränderung. Komplex aber akkurat für Timing.',
    category: 'astrology',
    type: 'knowledge',
    tags: ['Progressions', 'Timing', 'Evolution'],
    createdAt: DateTime(2024, 2, 15),
    readingTimeMinutes: 9,
  ),

  KnowledgeEntry(
    id: 'ene_029',
    world: 'energie',
    title: 'Transite - Aktuelle planetare Einflüsse',
    description: 'Wie Planeten heute deine Geburts-Planeten berühren',
    fullContent: 'Transite: Aktuelle Planeten-Positionen in Relation zu Geburts-Chart. Wichtigste: Saturn (Tests, 2-3 Jahre), Pluto (Transformation, Jahre), Jupiter (Glück, 1 Jahr), Uranus (Schock, Jahre). Transit-Typen: Konjunktion (intensiv), Opposition (Spannung), Quadrat (Herausforderung), Trine (Flow). Orbs: 1-10° Genauigkeit. Apps: TimePassages, Astro-Seek. Vorbereitung: Kenne deine Transite im Voraus!',
    category: 'astrology',
    type: 'knowledge',
    tags: ['Transite', 'Timing', 'Vorhersage'],
    createdAt: DateTime(2024, 2, 16),
    readingTimeMinutes: 10,
  ),

  KnowledgeEntry(
    id: 'ene_030',
    world: 'energie',
    title: 'Asteroids in Astrologie - Juno, Vesta, Pallas, Ceres',
    description: 'Asteroiden zeigen spezifische Themen - Ehe, Sex, Weisheit, Mutter',
    fullContent: 'Haupt-Asteroiden: Juno (Ehe, Commitment), Vesta (Sexualität, Hingabe, Sacred Fire), Pallas (Weisheit, Strategie, Kreativität), Ceres (Mütterlichkeit, Nahrung, Verlust). Weitere: Eros (erotische Liebe), Psyche (Seele, Mind), Amor (bedingungslose Liebe). Nutzen: Verfeinern Geburts-Chart. Beispiel: Juno in 7. Haus = Ehe zentral. Vesta in 8. Haus = tantrische Sexualität. Apps: Astro.com zeigt Asteroiden.',
    category: 'astrology',
    type: 'knowledge',
    tags: ['Asteroids', 'Juno', 'Vesta', 'Details'],
    createdAt: DateTime(2024, 2, 17),
    readingTimeMinutes: 9,
  ),

  // ==========================================
  // ENERGIE-ARBEIT (10) - ene_031 bis ene_040
  // ==========================================

  KnowledgeEntry(
    id: 'ene_031',
    world: 'energie',
    title: 'Pranayama - Die Kunst der Atmung',
    description: 'Yogische Atemtechniken für Energie, Klarheit und Heilung',
    fullContent: '''# Pranayama - Yoga Atemkontrolle

## Was ist Pranayama?
**Prana** = Lebensenergie (Chi, Ki)  
**Ayama** = Ausdehnung, Kontrolle

## Haupt-Techniken

### 1. Nadi Shodhana (Wechselatmung)
- Rechtes Nasenloch zu, links einatmen
- Beide zu, kurz halten
- Links zu, rechts ausatmen
- Wechseln
**Effekt:** Balance, Gehirn-Hemisphären synchronisieren

### 2. Kapalabhati (Feuer-Atem)
- Kraftvolle Ausatmung (Bauch einziehen)
- Passive Einatmung
- Schnell (1-2 Atemzüge/Sekunde)
**Effekt:** Energie, Entgiftung, Fokus

### 3. Bhastrika (Blasebalg-Atem)
- Kraftvolle Ein- UND Ausatmung
- Noch schneller als Kapalabhati
**Effekt:** Extreme Energie, Hitze

### 4. Ujjayi (Ozean-Atem)
- Kehle leicht zusammenziehen
- Klang wie Ozean-Wellen
**Effekt:** Beruhigung, Fokus (in Yoga Asanas)

### 5. Sitali (Kühlende Atmung)
- Zunge rollen (wie Strohhalm)
- Durch Mund einatmen, Nase ausatmen
**Effekt:** Kühlt Körper, reduziert Anger

## Wissenschaft
- Aktiviert Parasympathikus (Entspannung)
- Erhöht Sauerstoff im Blut
- Beeinflusst Herzrate-Variabilität
- Stimuliert Vagusnerv

**Warnung:** Bei Herzproblemen, Schwangerschaft Vorsicht!
''',
    category: 'energy_work',
    type: 'practice',
    tags: ['Pranayama', 'Atmung', 'Yoga', 'Prana'],
    createdAt: DateTime(2024, 2, 18),
    readingTimeMinutes: 12,
  ),

  // Weitere Energie-Arbeit Einträge (kompakt)
  KnowledgeEntry(
    id: 'ene_032',
    world: 'energie',
    title: 'Qi Gong - Chinesische Energie-Kultivierung',
    description: 'Langsame Bewegungen + Atem + Visualisierung = Heilung',
    fullContent: 'Qi Gong (Chi Kung): 5000 Jahre alt, Teil der TCM. Qi = Lebensenergie. Praxis: Langsame, fließende Bewegungen + Atmung + mentale Intention. Typen: Health Qigong (Heilung), Martial Qigong (Kampfkunst), Spiritual Qigong (Erleuchtung). Wissenschaft: Reduziert Blutdruck, stärkt Immunsystem, verlängert Leben. 8 Brokate: Beliebteste Routine. Praktiziere täglich 20-30 Min. Ziel: Öffne Meridiane, kultiviere Qi.',
    category: 'energy_work',
    type: 'practice',
    tags: ['Qi Gong', 'Chi', 'TCM', 'Energie'],
    createdAt: DateTime(2024, 2, 19),
    readingTimeMinutes: 10,
  ),

  KnowledgeEntry(
    id: 'ene_033',
    world: 'energie',
    title: 'Tai Chi - Meditation in Bewegung',
    description: 'Martial Art als Gesundheits-Praxis - Yin & Yang Balance',
    fullContent: 'Tai Chi Chuan: Innere Kampfkunst, heute mehr Gesundheits-Praxis. Prinzipien: Weich besiegt Hart, langsam ist schnell, Entspannung = Kraft. Formen: Yang (populärste), Chen (älteste), Wu, Sun. Vorteile: Balance (fällt Risiko reduziert), Flexibilität, Stress-Reduktion, Arthritis-Hilfe. Push Hands: Partner-Übung (Sensitivity Training). Taoismus: Tai Chi = Yin-Yang-Symbol in Bewegung. Empfohlen für Ältere.',
    category: 'energy_work',
    type: 'practice',
    tags: ['Tai Chi', 'Martial Arts', 'Balance', 'Taoismus'],
    createdAt: DateTime(2024, 2, 20),
    readingTimeMinutes: 9,
  ),

  KnowledgeEntry(
    id: 'ene_034',
    world: 'energie',
    title: 'EFT Tapping - Emotional Freedom Technique',
    description: 'Klopfe Meridian-Punkte während du negative Glaubenssätze sprichst',
    fullContent: 'EFT (Gary Craig, 1990s): Klopfe auf Akupressur-Punkte während du Problem aussprichst. 9 Punkte: Augenbraue, Augenseite, unter Auge, unter Nase, Kinn, Schlüsselbein, unter Arm, Kopf. Formel: "Obwohl ich [Problem] habe, akzeptiere ich mich tief und vollständig". Wissenschaft: Reduziert Cortisol, PTSD-Behandlung (Veteranen). Selbst anwendbar. Apps: The Tapping Solution. Kritik: "Zu simpel" - aber funktioniert!',
    category: 'energy_work',
    type: 'practice',
    tags: ['EFT', 'Tapping', 'Trauma', 'Meridiane'],
    createdAt: DateTime(2024, 2, 21),
    readingTimeMinutes: 8,
  ),

  KnowledgeEntry(
    id: 'ene_035',
    world: 'energie',
    title: 'Grounding / Erdung - Verbindung zur Erde',
    description: 'Barfuß auf Erde - Elektronen-Transfer für Heilung',
    fullContent: 'Grounding (Earthing): Direkter Haut-Kontakt mit Erde (barfuß, Gras, Wasser). Wissenschaft: Erde ist negativ geladen, Körper absorbiert Elektronen. Effekte: Reduziert Entzündung, verbessert Schlaf, reduziert Schmerz, normalisiert Cortisol. Studie: Clint Ober Dokumentation. Moderne: Grounding Matten (mit Erdungs-Stecker). Zeit: 20-30 Min täglich. Besonders wichtig in Städten (EMF-Exposition).',
    category: 'energy_work',
    type: 'practice',
    tags: ['Grounding', 'Earthing', 'Heilung', 'Natur'],
    createdAt: DateTime(2024, 2, 22),
    readingTimeMinutes: 7,
  ),

  KnowledgeEntry(
    id: 'ene_036',
    world: 'energie',
    title: 'Kriya Yoga - Paramahansa Yogananda',
    description: 'Geheime Technik für schnelle spirituelle Evolution',
    fullContent: 'Kriya Yoga: Alte Technik, wiederentdeckt von Lahiri Mahasaya (1861). Populär durch Paramahansa Yogananda (Autobiography of a Yogi). Technik: Prana durch Wirbelsäule zirkulieren (Chakra-Aktivierung). 1 Kriya = 1 Jahr spirituelle Evolution (traditionelle Behauptung). Geheim: Nur von Guru gelernt (Self-Realization Fellowship). Wissenschaft: Tiefe Meditation-Zustände. Steve Jobs las Autobiography jedes Jahr.',
    category: 'energy_work',
    type: 'practice',
    tags: ['Kriya Yoga', 'Yogananda', 'Spiritualität', 'Chakras'],
    createdAt: DateTime(2024, 2, 23),
    readingTimeMinutes: 10,
  ),

  KnowledgeEntry(
    id: 'ene_037',
    world: 'energie',
    title: 'Sound Healing - Frequenzen für Heilung',
    description: '432 Hz, 528 Hz, Solfeggio Frequenzen, Kristall-Schalen',
    fullContent: 'Sound Healing: Frequenzen für Zell-Heilung. 432 Hz (Universe Frequency), 528 Hz (Love/DNA-Reparatur), 396 Hz (Befreiung von Angst), 639 Hz (Beziehungs-Harmonisierung), 741 Hz (Detox), 852 Hz (Drittes Auge). Instrumente: Tibetische Klangschalen, Kristall-Schalen, Gongs, Tuning Forks. Wissenschaft: Cymatics (Vibration formt Materie), Wasser-Kristalle (Masaru Emoto). Apps: Insight Timer, YouTube 432 Hz Musik.',
    category: 'energy_work',
    type: 'practice',
    tags: ['Sound Healing', 'Frequenzen', '432 Hz', '528 Hz'],
    createdAt: DateTime(2024, 2, 24),
    readingTimeMinutes: 11,
  ),

  KnowledgeEntry(
    id: 'ene_038',
    world: 'energie',
    title: 'Breathwork - Holotropic & Rebirthing',
    description: 'Intensive Atem-Sessions für Trauma-Release und Bewusstseins-Erweiterung',
    fullContent: 'Holotropic Breathwork (Stanislav Grof): Schnelles, tiefes Atmen 1-3 Stunden. Erreiche non-ordinary states (wie Psychedelika). Rebirthing (Leonard Orr): Circular Breathing (keine Pausen). Effekte: Trauma-Release, emotionale Katharsis, spirituelle Erfahrungen. Körper-Reaktionen: Tetany (Hand-Krämpfe), Tingling, intensive Emotionen. Sicherheit: Nur mit erfahrenen Facilitators. Ähnlich: Wim Hof (aber kürzer).',
    category: 'energy_work',
    type: 'practice',
    tags: ['Breathwork', 'Holotropic', 'Trauma', 'Bewusstsein'],
    createdAt: DateTime(2024, 2, 25),
    readingTimeMinutes: 10,
  ),

  KnowledgeEntry(
    id: 'ene_039',
    world: 'energie',
    title: 'Acupuncture & Meridiane - TCM Energie-Bahnen',
    description: '12 Hauptmeridiane für Qi-Fluss, Akupunktur-Punkte',
    fullContent: '12 Hauptmeridiane: Lunge, Dickdarm, Magen, Milz, Herz, Dünndarm, Blase, Niere, Perikard, Triple Warmer, Gallenblase, Leber. Qi fließt durch Meridiane (wie Flüsse). Blockaden = Krankheit. Akupunktur: Nadeln an spezifischen Punkten (über 300). Wissenschaft: Faszien-Netzwerk, Endorphin-Release. Akupressur: Selbst anwendbar (Drücken statt Nadeln). Wichtige Punkte: LI4 (Kopfschmerz), LV3 (Stress), ST36 (Immunsystem).',
    category: 'energy_work',
    type: 'knowledge',
    tags: ['Akupunktur', 'Meridiane', 'TCM', 'Qi'],
    createdAt: DateTime(2024, 2, 26),
    readingTimeMinutes: 12,
  ),

  KnowledgeEntry(
    id: 'ene_040',
    world: 'energie',
    title: 'Aura Reading - Dein Energie-Feld sehen',
    description: 'Lerne Auras wahrzunehmen - 7 Schichten, Farben, Bedeutungen',
    fullContent: '7 Aura-Schichten: 1) Ätherisch (physisch), 2) Emotional, 3) Mental, 4) Astral (Herzbrücke), 5) Ätherische Vorlage, 6) Celestial, 7) Kausale Schablone (höchste). Farben: Rot (Leidenschaft), Orange (Kreativität), Gelb (Intellekt), Grün (Heilung), Blau (Kommunikation), Indigo (Intuition), Violett (Spiritualität). Training: Soft-Fokus auf Person vor weißem Hintergrund, sieh Licht-Umriss. Kirlian-Fotografie: Macht Aura sichtbar.',
    category: 'energy_work',
    type: 'knowledge',
    tags: ['Aura', 'Energie-Feld', 'Hellsehen', 'Farben'],
    createdAt: DateTime(2024, 2, 27),
    readingTimeMinutes: 9,
  ),

  // ==========================================
  // BEWUSSTSEIN (10 finale) - ene_041 bis ene_050
  // ==========================================

  KnowledgeEntry(
    id: 'ene_041',
    world: 'energie',
    title: 'Bewusstseins-Ebenen - Hawkins Map',
    description: 'Von Scham (20) bis Erleuchtung (700-1000) - Kalibrierung',
    fullContent: '''# Dr. David Hawkins - Map of Consciousness

## Die Skala (logarithmisch)

### Unterhalb 200 - Destruktive Energien
- **20 Scham:** Tod-Wünsche
- **30 Schuld:** Selbst-Zerstörung
- **50 Apathie:** Hoffnungslosigkeit
- **75 Trauer:** Bedauern
- **100 Angst:** Angst
- **125 Verlangen:** Sucht
- **150 Ärger:** Hass
- **175 Stolz:** Arroganz

### Kritischer Punkt - 200 Mut
Hier beginnst du dein Leben selbst zu kreieren

### 200-500 - Wachsende Kraft
- **200 Mut:** Bereitschaft
- **250 Neutralität:** Okay-ness
- **310 Bereitschaft:** Optimismus
- **350 Akzeptanz:** Vergebung
- **400 Vernunft:** Verstehen
- **500 Liebe:** Ehrfurcht

### 500-600 - Spirituelle Realisierung
- **540 Freude:** Heiterkeit
- **600 Frieden:** Seligkeit

### 700-1000 - Erleuchtung
- **700-1000:** Selbst-Realisierung
- **Krishna, Buddha, Jesus:** 1000

## Kinesiologie-Test
Hawkins nutzte Muskel-Testing um Wahrheit zu kalibrieren.

## Wichtig
85% der Menschheit ist unter 200. Jede Person über 200 gleicht 90.000 unter 200 aus.

**Ziel:** Steige die Leiter des Bewusstseins.
''',
    category: 'consciousness',
    type: 'knowledge',
    tags: ['Bewusstsein', 'Hawkins', 'Erleuchtung', 'Skala'],
    createdAt: DateTime(2024, 2, 28),
    readingTimeMinutes: 13,
  ),

  // Finale Einträge (kompakt)
  KnowledgeEntry(
    id: 'ene_042',
    world: 'energie',
    title: 'Monroe Institut - Gateway Experience & Hemisync',
    description: 'Außerkörperliche Erfahrungen durch binaurale Beats',
    fullContent: 'Robert Monroe: Entwickelte Hemisync (binaurale Beats für Gehirn-Synchronisierung). Gateway Experience: 6 CDs, führen zu Focus-Levels (10, 12, 15, 21, 27). CIA studierte Monroe (declassified: Gateway Process). Out-of-Body Erfahrungen (OBE). Focus 15: No-Time State. Focus 21: Jenseits Raum-Zeit. App/CDs: Monroe Institute Shop. Wissenschaft: Theta/Delta-Wellen induzieren. Kontrovers aber wirkungsvoll.',
    category: 'consciousness',
    type: 'practice',
    tags: ['Monroe', 'OBE', 'Hemisync', 'CIA Gateway'],
    createdAt: DateTime(2024, 3, 1),
    readingTimeMinutes: 11,
  ),

  KnowledgeEntry(
    id: 'ene_043',
    world: 'energie',
    title: 'Remote Viewing - CIA Psychic Spying',
    description: 'Trainierbare Fähigkeit um entfernte Orte/Personen zu "sehen"',
    fullContent: 'Remote Viewing: US Army/CIA Programm (1970s-1995). Stargate Project. Viewer "sieht" entfernten Ort nur mit Koordinaten. Protokolle: CRV (Controlled Remote Viewing), ERV (Extended RV). Berühmte Viewer: Ingo Swann, Joe McMoneagle, Russell Targ. Erfolge: Fand gestohlenes Flugzeug, Sowjet U-Boot. 1995: Öffentlich "beendet" (aber...?). Training verfügbar (IRVA, Farsight Institute). Jeder kann lernen.',
    category: 'consciousness',
    type: 'practice',
    tags: ['Remote Viewing', 'CIA', 'Stargate', 'Psychic'],
    createdAt: DateTime(2024, 3, 2),
    readingTimeMinutes: 12,
  ),

  KnowledgeEntry(
    id: 'ene_044',
    world: 'energie',
    title: 'Near Death Experience (NDE) - Nahtod-Erfahrungen',
    description: 'Gemeinsamkeiten aller NDEs - Tunnel, Licht, Life Review, Einheit',
    fullContent: 'NDE-Merkmale (IANDS): 1) Out-of-Body, 2) Tunnel & Licht, 3) verstorbene Verwandte, 4) Life Review (ganzes Leben in Sekunden), 5) Gefühl von Einheit/Liebe, 6) "Return" ungern. Wissenschaft: DMT-Release? Sauerstoffmangel? ABER: Berichte sind konsistent über Kulturen. Transformation: Keine Angst vor Tod, spiritueller. Berichte: "Proof of Heaven" (Eben Alexander), "To Heaven and Back" (Mary Neal).',
    category: 'consciousness',
    type: 'knowledge',
    tags: ['NDE', 'Nahtod', 'Jenseits', 'Bewusstsein'],
    createdAt: DateTime(2024, 3, 3),
    readingTimeMinutes: 10,
  ),

  KnowledgeEntry(
    id: 'ene_045',
    world: 'energie',
    title: 'Akashic Records - Die kosmische Bibliothek',
    description: 'Zugriff auf universelles Wissen & Past-Life Informationen',
    fullContent: 'Akasha (Sanskrit): Äther-Element. Akashic Records: Energetische Datenbank aller Gedanken, Ereignisse, Emotionen (Vergangenheit, Gegenwart, Zukunft). Zugriff: Meditation, Trance, Hellseher. Reading zeigt: Past Lives, Karma, Soul Contracts, Life Purpose. Berühmte Reader: Edgar Cayce (Sleeping Prophet). Selbst-Zugriff: Akashic Prayer (Linda Howe Methode). Kontrovers: Verifizierbar? Aber transformativ für viele.',
    category: 'consciousness',
    type: 'knowledge',
    tags: ['Akashic Records', 'Past Life', 'Edgar Cayce'],
    createdAt: DateTime(2024, 3, 4),
    readingTimeMinutes: 9,
  ),

  KnowledgeEntry(
    id: 'ene_046',
    world: 'energie',
    title: 'Shadow Work - Carl Jung Integration',
    description: 'Integriere deine unterdrückten Teile für Ganzheit',
    fullContent: 'Shadow (Jung): Unterdrückte Teile von dir (Wut, Eifersucht, Sexualität, Macht). Projektion: Was du an anderen hasst = dein Schatten. Prozess: 1) Erkenne Trigger, 2) Frage: "Was zeigt mir das über mich?", 3) Akzeptiere und integriere. Tools: Journaling (Schatten-Fragen), Inner Child Work, Parts Work (IFS), Psychedelika (Therapie-Kontext). Ziel: Nicht Licht vs. Dunkel, sondern GANZ werden. "Gold im Schatten."',
    category: 'consciousness',
    type: 'practice',
    tags: ['Shadow Work', 'Jung', 'Integration', 'Psychologie'],
    createdAt: DateTime(2024, 3, 5),
    readingTimeMinutes: 11,
  ),

  KnowledgeEntry(
    id: 'ene_047',
    world: 'energie',
    title: 'Sacred Geometry - Universum-Blaupause',
    description: 'Blume des Lebens, Metatrons Würfel, Fibonacci, Phi',
    fullContent: 'Heilige Geometrie: Muster die überall in Natur existieren. Blume des Lebens (19 Kreise): Enthält alle platonischen Körper. Metatrons Würfel: 13 Kreise, alle 5 platonischen Körper. Fibonacci (1,1,2,3,5,8...): Spiralen (Muscheln, Galaxien). Phi (1.618): Goldener Schnitt (Pyramiden, Kunst, Körper). Vesica Piscis: Zwei Kreise = Jesus-Fisch-Symbol. Nutzung: Meditation auf Symbole, Tragen als Schmuck, Architektur (Chartres-Kathedrale).',
    category: 'consciousness',
    type: 'knowledge',
    tags: ['Sacred Geometry', 'Blume des Lebens', 'Fibonacci', 'Phi'],
    createdAt: DateTime(2024, 3, 6),
    readingTimeMinutes: 12,
  ),

  KnowledgeEntry(
    id: 'ene_048',
    world: 'energie',
    title: 'Shamanism - Uralte spirituelle Praxis',
    description: 'Journey zur Unterwelt, Mittelwelt, Oberwelt - Krafttiere & Heilung',
    fullContent: 'Schamanismus: Älteste spirituelle Praxis (40.000+ Jahre). Schamane = Mittler zwischen Welten. 3 Welten: Unterwelt (Krafttiere, Ahnen), Mittelwelt (physische Realität), Oberwelt (Spirit Guides, Lehrer). Journey: Durch Trommel-Rhythmus (4-7 Hz Theta). Krafttier: Dein spiritueller Beschützer/Guide. Soul Retrieval: Zurückholen verlorener Seelen-Teile (Trauma). Moderne: Neo-Schamanismus (Michael Harner - Core Shamanism).',
    category: 'consciousness',
    type: 'practice',
    tags: ['Shamanism', 'Journey', 'Krafttier', 'Heilung'],
    createdAt: DateTime(2024, 3, 7),
    readingTimeMinutes: 13,
  ),

  KnowledgeEntry(
    id: 'ene_049',
    world: 'energie',
    title: 'Plant Medicine - Ayahuasca, Kambo, San Pedro',
    description: 'Schamanische Heilpflanzen für Bewusstseins-Erweiterung',
    fullContent: 'Ayahuasca: DMT + MAOI (Banisteriopsis caapi + Psychotria viridis). Zeremonie in Peru/Ecuador. Effekte: Purging (Erbrechen = Reinigung), Visionen, Ego-Tod, Heilung. Kambo: Frosch-Gift (Phyllomedusa bicolor) - extreme Entgiftung. San Pedro: Meskalin-Kaktus (Trichocereus pachanoi) - Herz-Öffnung. Psilocybin: Magische Pilze - Johns Hopkins Studien. Legality: Varies. Vorbereitung: Dieta (keine Salz, Zucker, Sex). Integration wichtig!',
    category: 'consciousness',
    type: 'knowledge',
    tags: ['Ayahuasca', 'Plant Medicine', 'DMT', 'Psychedelics'],
    createdAt: DateTime(2024, 3, 8),
    readingTimeMinutes: 14,
  ),

  KnowledgeEntry(
    id: 'ene_050',
    world: 'energie',
    title: 'Die Reise geht weiter - Integration & Praxis',
    description: 'Zusammenfassung - Wie man spirituell erwacht im Alltag lebt',
    fullContent: '''# Die Energie-Reise - Zusammenfassung

Du hast jetzt 50 Einträge über Meditation, Astrologie, Energie-Arbeit und Bewusstseins-Erweiterung gelesen. 🙏✨

## Die Integration

### 1. Tägliche Praxis wählen
**Meditation:** 20 Min jeden Morgen (Vipassana, Zazen, oder Chakra)  
**Atmung:** 5 Min Pranayama oder Wim Hof  
**Bewegung:** Yoga, Qi Gong, oder Tai Chi  

### 2. Astrologie nutzen
- Kenne deine Big 3 (Sonne, Mond, Aszendent)
- Verfolge Transite (Saturn, Jupiter)
- Nutze Mondphasen (Neumond Absichten, Vollmond Release)

### 3. Energie-Bewusstsein
- Grounding täglich (20 Min barfuß)
- Chakra-Balance (Meditation + Yoga)
- Schütze deine Energie (Grenzen setzen)

### 4. Bewusstseins-Arbeit
- Shadow Work (Journal, Therapie)
- Lese spirituelle Texte (Bhagavad Gita, Tao Te Ching)
- Suche Lehrer/Community

### 5. Ernährung & Lifestyle
- Pineal Gland decalcifizieren (kein Fluorid)
- Biologisch/pflanzlich essen
- Faste gelegentlich (Autophagie)
- Reduziere EMF-Exposition

## Die 7 Ebenen des Erwachens

1. **Unbewusst:** Leben auf Autopilot
2. **Erwachen:** "Es gibt mehr als das..."
3. **Suche:** Lesen, Lernen, Experimentieren
4. **Dunkle Nacht:** Alte Identität stirbt (schwierig!)
5. **Transformation:** Neue Identität entsteht
6. **Integration:** Leben aus höherem Bewusstsein
7. **Service:** Anderen helfen zu erwachen

## Häufige Fallen

### 1. Spiritual Bypass
Spiritualität nutzen um Probleme zu vermeiden (nicht zu heilen)

### 2. Ego-Inflation
"Ich bin erleuchtet, andere nicht" (neues Ego!)

### 3. Informations-Überlastung
Zu viel lesen, zu wenig PRAKTIZIEREN

### 4. Ungeduld
Erleuchtung ist kein Ziel - es ist der Weg

## Ressourcen

### Bücher
- "Power of Now" - Eckhart Tolle
- "Autobiography of a Yogi" - Yogananda
- "Be Here Now" - Ram Dass
- "The Untethered Soul" - Michael Singer

### Apps
- Insight Timer (Meditation)
- Co-Star (Astrologie)
- The Tapping Solution (EFT)

### Communities
- Lokale Meditation-Gruppen
- Yoga-Studios
- Astrologie-Circles
- Online-Communities (Reddit: r/Meditation, r/Chakras)

## Abschließende Weisheit

**"Du bist nicht ein Tropfen im Ozean. Du bist der gesamte Ozean in einem Tropfen." - Rumi**

Die Trennung ist Illusion. Alles ist Energie. Du bist Bewusstsein, das eine menschliche Erfahrung hat.

### Nächste Schritte:
1. Wähle 1 Meditation-Stil → praktiziere 30 Tage
2. Lerne dein Geburts-Chart
3. Finde 1 Energie-Praxis die resoniert
4. Connecte mit Gleichgesinnten

**Willkommen in der Weltenbibliothek - wo spirituelles Wissen lebendig bleibt.** 🌟

*"Das Ziel der Reise ist nicht anzukommen, sondern aufzuwachen." - Buddha*

Namaste. 🙏
''',
    category: 'consciousness',
    type: 'practice',
    tags: ['Integration', 'Praxis', 'Spiritualität', 'Zusammenfassung'],
    createdAt: DateTime(2024, 3, 9),
    readingTimeMinutes: 16,
  ),
];
