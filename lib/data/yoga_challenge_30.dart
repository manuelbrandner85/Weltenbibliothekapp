// 🧘‍♀️ YOGA — 30-TAGE-CHALLENGE
// Progressiv aufbauend: W1 Grundhaltungen · W2 Sonnengruß · W3 Standasanas
// W4 Tiefe Asanas & Inversionen.

import '../widgets/lesson_series_screen.dart';

const List<LessonSeriesEntry> yogaChallenge30 = [
  // WOCHE 1: GRUNDHALTUNGEN (5-15 Min)
  LessonSeriesEntry(
    code: 'y01', symbol: '🧘',
    title: 'Tag 1 — Sukhasana',
    subtitle: 'Einfacher Sitz · 5 Min',
    meaning:
        'Schneidersitz mit aufgerichteter Wirbelsäule. Beobachte deine Atmung. '
        'Hier beginnt jede Praxis.',
    reflection:
        'Wo im Körper hast du heute am stärksten Spannung gespürt?',
  ),
  LessonSeriesEntry(
    code: 'y02', symbol: '🧘',
    title: 'Tag 2 — Tadasana',
    subtitle: 'Berghaltung · 5 Min',
    meaning:
        'Stehen wie ein Berg. Füße fest, Knie weich, Becken neutral, Krone '
        'nach oben. Die Mutter aller Stehhaltungen.',
    reflection:
        'Wann hast du heute zuletzt einfach nur gestanden, ohne sofort weiterzugehen?',
  ),
  LessonSeriesEntry(
    code: 'y03', symbol: '🐈',
    title: 'Tag 3 — Marjaryasana/Bitilasana',
    subtitle: 'Katze-Kuh · 10× · 5 Min',
    meaning:
        'Vierfüßlerstand. Einatmen Bauch runter (Kuh), ausatmen Rücken hoch '
        '(Katze). Mobilisiert die ganze Wirbelsäule.',
    reflection:
        'Welche Wirbelsäulen-Region war heute am beweglichsten — welche am steifsten?',
  ),
  LessonSeriesEntry(
    code: 'y04', symbol: '🐕',
    title: 'Tag 4 — Adho Mukha Svanasana',
    subtitle: 'Herabschauender Hund · 1 Min × 3',
    meaning:
        'Hände und Füße auf der Matte, Gesäß nach oben, V-Form. Die '
        'klassische Yoga-Pose schlechthin.',
    reflection:
        'Was war heute schwerer — die Schultern oder die Hamstrings?',
  ),
  LessonSeriesEntry(
    code: 'y05', symbol: '🧘',
    title: 'Tag 5 — Balasana',
    subtitle: 'Kindeshaltung · 3 Min',
    meaning:
        'Knie breit, Großzehen zusammen, Stirn auf der Matte, Arme nach '
        'vorne oder zurück. Die Heim-Pose nach jeder Anstrengung.',
    reflection:
        'Wo darfst du heute weicher werden statt härter zu kämpfen?',
  ),
  LessonSeriesEntry(
    code: 'y06', symbol: '🦋',
    title: 'Tag 6 — Baddha Konasana',
    subtitle: 'Schmetterling · 5 Min',
    meaning:
        'Sitzen, Fußsohlen zusammen, Knie sinken zur Seite. Öffnet Hüften, '
        'sanft auch Leistenbereich.',
    reflection:
        'Wo speicherst du Stress in deinen Hüften — und was möchtest du loslassen?',
  ),
  LessonSeriesEntry(
    code: 'y07', symbol: '🪷',
    title: 'Tag 7 — Savasana + Integration W1',
    subtitle: 'Totenstellung · 10 Min',
    meaning:
        'Auf dem Rücken, Arme leicht abgespreizt, Füße fallen auseinander. '
        'Tiefe Entspannung. Härteste und wichtigste Pose.',
    reflection:
        'Welche der 6 Grundhaltungen ist deine bereits — welche braucht noch Übung?',
  ),
  // WOCHE 2: SONNENGRUSS (10-20 Min)
  LessonSeriesEntry(
    code: 'y08', symbol: '☀️',
    title: 'Tag 8 — Surya Namaskar A',
    subtitle: 'Sonnengruß A · 3 Runden',
    meaning:
        '12-Posen-Sequenz fließend mit Atem. Tadasana → Uttanasana → '
        'Plank → Chaturanga → Cobra → Down Dog → zurück.',
    reflection:
        'In welcher Übergangs-Phase war dein Atem heute am wackeligsten?',
  ),
  LessonSeriesEntry(
    code: 'y09', symbol: '☀️',
    title: 'Tag 9 — Surya Namaskar A · 5 Runden',
    subtitle: '20 Min',
    meaning:
        'Mehr Wiederholungen, gleicher Rhythmus. Atem führt die Bewegung, '
        'nicht umgekehrt.',
    reflection:
        'Bei welcher Runde kam Müdigkeit — bei welcher zweite Luft?',
  ),
  LessonSeriesEntry(
    code: 'y10', symbol: '☀️',
    title: 'Tag 10 — Surya Namaskar B',
    subtitle: 'Sonnengruß B · 3 Runden',
    meaning:
        'Erweiterte Version mit Krieger 1. Mehr Beinkraft, mehr Hüftöffnung. '
        'Die Ashtanga-Klassik.',
    reflection:
        'Wo hat Krieger-1 deine Beine zum Reden gebracht?',
  ),
  LessonSeriesEntry(
    code: 'y11', symbol: '☀️',
    title: 'Tag 11 — Sonnengruß A+B kombiniert',
    subtitle: '3+3 Runden',
    meaning:
        'Erst 3× A, dann 3× B. Komplette Aufwärm- und Energiesequenz '
        'in 20-30 Min.',
    reflection:
        'Welche Variante (A oder B) liegt dir mehr — und warum?',
  ),
  LessonSeriesEntry(
    code: 'y12', symbol: '🐍',
    title: 'Tag 12 — Cobra & Upward Dog',
    subtitle: 'Rückbeugen aus dem Sonnengruß isolieren',
    meaning:
        'Cobra (Bhujangasana) mit weichen Ellbogen, Upward Dog '
        '(Urdhva Mukha) mit gestreckten Armen. Brust öffnet sich.',
    reflection:
        'Wie offen ist dein Brustkorb heute — auf einer Skala 1-10?',
  ),
  LessonSeriesEntry(
    code: 'y13', symbol: '⏬',
    title: 'Tag 13 — Forward-Folds-Day',
    subtitle: 'Stehende und sitzende Vorbeugen',
    meaning:
        'Uttanasana (steh), Paschimottanasana (sitz), Padangusthasana '
        '(Zehengriff). Dehnt Rücken, beruhigt den Geist.',
    reflection:
        'Welcher Gedanke ist beim Vorbeugen aufgekommen — und losgelassen?',
  ),
  LessonSeriesEntry(
    code: 'y14', symbol: '🌅',
    title: 'Tag 14 — Integration W2 · Eigene Mini-Flow',
    subtitle: '20 Min eigene Sequenz',
    meaning:
        'Stelle deine eigene 20-Min-Flow aus dem Bekannten zusammen. '
        'Atem führt, kein Plan zwingt.',
    reflection:
        'Welche unerwartete Reihenfolge hat sich heute aus dir ergeben?',
  ),
  // WOCHE 3: STANDASANAS (20-30 Min)
  LessonSeriesEntry(
    code: 'y15', symbol: '⚔️',
    title: 'Tag 15 — Virabhadrasana I',
    subtitle: 'Krieger 1 · beide Seiten · 1 Min',
    meaning:
        'Vorderes Bein 90°, hinteres Bein gestreckt 45°, Becken vorwärts, '
        'Arme nach oben. Kraft und Würde des Kriegers.',
    reflection:
        'Welcher innere "Krieger" in dir wartet auf Aktivierung?',
  ),
  LessonSeriesEntry(
    code: 'y16', symbol: '⚔️',
    title: 'Tag 16 — Virabhadrasana II',
    subtitle: 'Krieger 2 · beide Seiten · 1 Min',
    meaning:
        'Vorderes Bein 90°, hinteres Bein gestreckt, Arme parallel zum '
        'Boden ausgestreckt. Standhaftigkeit.',
    reflection:
        'Wo darfst du heute klar deine Position halten?',
  ),
  LessonSeriesEntry(
    code: 'y17', symbol: '🛡️',
    title: 'Tag 17 — Trikonasana',
    subtitle: 'Dreieck · beide Seiten · 1 Min',
    meaning:
        'Beine breit, vorderes Knie gestreckt, eine Hand zum Schienbein/Block, '
        'die andere zum Himmel. Geometrie pur.',
    reflection:
        'Welche Polarität (oben/unten, vorn/hinten) erfährst du gerade?',
  ),
  LessonSeriesEntry(
    code: 'y18', symbol: '🌳',
    title: 'Tag 18 — Vrksasana',
    subtitle: 'Baum · beide Seiten · 1 Min',
    meaning:
        'Standbein fest, anderes Bein an Innenschenkel (nicht am Knie), '
        'Hände vor Herz oder zum Himmel. Gleichgewicht.',
    reflection:
        'Wo wackelst du heute innerlich — und wo findest du deinen Stand?',
  ),
  LessonSeriesEntry(
    code: 'y19', symbol: '🦅',
    title: 'Tag 19 — Garudasana',
    subtitle: 'Adler · beide Seiten · 1 Min',
    meaning:
        'Beine verschränkt, Arme verschränkt, ineinander gewickelt. '
        'Konzentration auf einen Punkt.',
    reflection:
        'Welche "Verstrickung" in deinem Leben kannst du heute klar sehen?',
  ),
  LessonSeriesEntry(
    code: 'y20', symbol: '🪑',
    title: 'Tag 20 — Utkatasana',
    subtitle: 'Stuhl · 3 × 30 Sek',
    meaning:
        'Knie tief beugen, als sässest du auf einem Stuhl. Arme nach oben. '
        'Pure Beinkraft.',
    reflection:
        'Wie reagiert dein Geist auf körperliche Anstrengung — Widerstand oder Akzeptanz?',
  ),
  LessonSeriesEntry(
    code: 'y21', symbol: '🌊',
    title: 'Tag 21 — Integration W3 · Standing-Flow',
    subtitle: '20 Min Standasanas-Sequenz',
    meaning:
        'Krieger 1 → 2 → Dreieck → Baum → Adler → Stuhl, jede Seite. '
        'Atem führt durch.',
    reflection:
        'Welche Standasana ist deine "Stärke", welche dein "Wachstum"?',
  ),
  // WOCHE 4: TIEFE & INVERSIONEN (30-45 Min)
  LessonSeriesEntry(
    code: 'y22', symbol: '🏹',
    title: 'Tag 22 — Dhanurasana',
    subtitle: 'Bogen · 3 × 30 Sek',
    meaning:
        'Auf dem Bauch, Knöchel greifen, Brust hochziehen. Rückbeuge, '
        'aktiviert ganze Hinterkette.',
    reflection:
        'Welche Energie ist beim "Spannen" des Körper-Bogens freigeworden?',
  ),
  LessonSeriesEntry(
    code: 'y23', symbol: '🐪',
    title: 'Tag 23 — Ustrasana',
    subtitle: 'Kamel · 30 Sek × 3',
    meaning:
        'Kniend, Hände zu den Fersen, Brust nach oben, Becken vorne. '
        'Tiefe Brustkorb-Öffnung.',
    reflection:
        'Welche Emotion stieg beim Brustkorb-Öffnen auf?',
  ),
  LessonSeriesEntry(
    code: 'y24', symbol: '🌉',
    title: 'Tag 24 — Setu Bandha Sarvangasana',
    subtitle: 'Brücke · 1 Min × 3',
    meaning:
        'Auf dem Rücken, Knie gebeugt, Hüften hoch. Sanfte Inversion, '
        'aktiviert Gesäß und stärkt unteren Rücken.',
    reflection:
        'Welche "Brücke" baust du gerade in deinem Leben?',
  ),
  LessonSeriesEntry(
    code: 'y25', symbol: '🦂',
    title: 'Tag 25 — Sarvangasana',
    subtitle: 'Schulterstand · 2-5 Min',
    meaning:
        '"Mutter aller Asanas". Auf den Schultern, Beine senkrecht. '
        'Reguliert Schilddrüse, wirkt jugend-erhaltend laut Tradition.',
    reflection:
        'Wie fühlt sich Welt von "kopfüber" an?',
  ),
  LessonSeriesEntry(
    code: 'y26', symbol: '🌊',
    title: 'Tag 26 — Halasana',
    subtitle: 'Pflug · 1-3 Min',
    meaning:
        'Vom Schulterstand: Beine über den Kopf zum Boden. Tiefe '
        'Rücken-Dehnung. Sehr therapeutisch.',
    reflection:
        'Was hast du beim "Umpflügen" der Wirbelsäule wahrgenommen?',
  ),
  LessonSeriesEntry(
    code: 'y27', symbol: '🦅',
    title: 'Tag 27 — Sirsasana',
    subtitle: 'Kopfstand · 30 Sek - 2 Min (an Wand)',
    meaning:
        '"König der Asanas". Anfangs an der Wand. Geist wird klar, '
        'Wahrnehmung kehrt um. Vorsichtig.',
    reflection:
        'Welche Wahrnehmung dreht sich gerade in deinem Leben um 180°?',
  ),
  LessonSeriesEntry(
    code: 'y28', symbol: '🪷',
    title: 'Tag 28 — Padmasana',
    subtitle: 'Lotussitz · 5-10 Min',
    meaning:
        'Klassischer Meditationssitz. Wenn unbequem, halber Lotus oder '
        'Sukhasana. Stabile Basis für Pranayama.',
    reflection:
        'In welcher Sitzhaltung bleibt dein Geist am ruhigsten?',
  ),
  LessonSeriesEntry(
    code: 'y29', symbol: '🌬️',
    title: 'Tag 29 — Pranayama-Tag',
    subtitle: 'Nadi Shodhana + Kapalabhati + Bhastrika',
    meaning:
        'Nur Pranayama, keine Asana. Wechselatmung 5 Min, Feueratem 1 Min, '
        'Blasebalg 1 Min. Energetische Reinigung.',
    reflection:
        'Welche Energie spürst du nach 7 Min Pranayama, die du sonst nicht hattest?',
  ),
  LessonSeriesEntry(
    code: 'y30', symbol: '✨',
    title: 'Tag 30 — Volle Praxis',
    subtitle: '60 Min · alle Komponenten',
    meaning:
        'Sonnengruß A 3× + B 3× → 5 Krieger-Variationen → 3 Rückbeugen → '
        '1 Inversion → Savasana 10 Min. Du hast eine vollständige Yoga-Praxis.',
    reflection:
        'Was hat sich in 30 Tagen am stärksten verändert — Körper, Geist oder Atem?',
  ),
];
