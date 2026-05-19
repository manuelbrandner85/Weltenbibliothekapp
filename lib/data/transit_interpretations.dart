// Lookup-Tabelle fuer Transit-Aspekt-Deutungen.
// Bereich B3 -- aus dem Natal-Chart-Service abfragbar.
//
// Schluessel-Format: 'transit_planet-aspect-natal_planet'
// (z.B. 'sun-conj-sun' = Solar Return)

library;

class TransitInterpretation {
  final String title;
  final String body;
  final String tone; // 'harmonic' | 'tension' | 'transform' | 'reflect'
  const TransitInterpretation(this.title, this.body, this.tone);
}

const Map<String, TransitInterpretation> transitInterpretations = {
  // Sonne
  'sun-conj-sun': TransitInterpretation(
      'Solar Return',
      'Dein persoenliches Neujahr -- die Sonne kehrt an den Geburtsort zurueck. '
          'Energie-Reset, Vision-Setting und Selbstpositionierung.',
      'transform'),
  'sun-trine-moon': TransitInterpretation(
      'Sonne Trigon Mond',
      'Inneres und Aeusseres im Einklang. Gefuehle und Handeln stimmen ueberein. '
          'Guter Tag fuer Familienthemen oder Selbstausdruck.',
      'harmonic'),
  'sun-square-saturn': TransitInterpretation(
      'Sonne Quadrat Saturn',
      'Pflicht steht zwischen dir und deinem Lebensgefuehl. Strukturieren statt '
          'rebellieren -- das Limit testet, was wirklich tragfaehig ist.',
      'tension'),
  'sun-conj-jupiter': TransitInterpretation(
      'Sonne Konjunktion Jupiter',
      'Gluecks-Tag! Vertrauen, Wachstum, Optimismus. Gute Verbindungen, '
          'Bauchgefuehl folgen.',
      'harmonic'),
  'sun-opp-saturn': TransitInterpretation(
      'Sonne Opposition Saturn',
      'Realitaets-Check. Verantwortung und Limits werden bewusst. Nicht '
          'kapitulieren, sondern reifen.',
      'tension'),

  // Mond
  'moon-conj-moon': TransitInterpretation(
      'Mond Konjunktion Mond',
      'Emotionaler Reset (Lunar Return). Spuere nach innen, was wirklich naehrt. '
          'Setze einen Wunsch fuer den naechsten Monatszyklus.',
      'transform'),
  'moon-trine-venus': TransitInterpretation(
      'Mond Trigon Venus',
      'Herz und Aesthetik im Fluss. Wunderschoener Tag fuer Liebe, Genuss, '
          'Kreativitaet.',
      'harmonic'),
  'moon-square-mars': TransitInterpretation(
      'Mond Quadrat Mars',
      'Emotionale Hitze -- Reizbarkeit moeglich. Frust ueber Bewegung kanalisieren, '
          'nicht ueber Streit.',
      'tension'),

  // Merkur
  'mercury-retro': TransitInterpretation(
      'Merkur rueckl.',
      'Kommunikation langsamer pruefen. Vertraege, Reisen, neue Geraete: doppelt '
          'checken. Gut fuer Rueckblick, Wiederaufnahme alter Projekte.',
      'reflect'),
  'mercury-conj-mercury': TransitInterpretation(
      'Merkur Konjunktion Merkur',
      'Mentaler Reset. Klarer Kopf, gute Gespraeche, neue Ideen finden Raum.',
      'transform'),
  'mercury-trine-saturn': TransitInterpretation(
      'Merkur Trigon Saturn',
      'Strukturiertes Denken. Hervorragend fuer Pruefungen, Vertraege und '
          'Detailarbeit.',
      'harmonic'),

  // Venus
  'venus-conj-venus': TransitInterpretation(
      'Venus Konjunktion Venus',
      'Venus-Return: Liebes- und Werte-Check. Was ist dir heute wertvoll? '
          'Schoenheit und Beziehungen rueken in den Fokus.',
      'transform'),
  'venus-trine-mars': TransitInterpretation(
      'Venus Trigon Mars',
      'Anziehung und Aktion im Einklang. Ideal fuer kreative Projekte, '
          'romantische Initiativen.',
      'harmonic'),
  'jupiter-trine-venus': TransitInterpretation(
      'Jupiter Trigon Venus',
      'Glueck-Aspekt fuer Liebe und Geld! Geschenke des Lebens annehmen.',
      'harmonic'),
  'venus-square-saturn': TransitInterpretation(
      'Venus Quadrat Saturn',
      'Liebes-Pruefung. Mangel-Gefuehl moeglich -- aber auch Chance fuer reife '
          'Bindung statt Spielerei.',
      'tension'),

  // Mars
  'mars-conj-sun': TransitInterpretation(
      'Mars Konjunktion Sonne',
      'Energie-Boost. Mut, Initiative, Sport-Tag. Kann auch hitzig werden -- '
          'Energie konstruktiv kanalisieren.',
      'tension'),
  'mars-square-sun': TransitInterpretation(
      'Mars Quadrat Sonne',
      'Konflikt-Potenzial. Wo wirst du gerade unter Druck gesetzt? Pause atmen '
          'bevor reagieren.',
      'tension'),
  'mars-trine-jupiter': TransitInterpretation(
      'Mars Trigon Jupiter',
      'Mutige Expansion. Spring jetzt, wenn es einen Sprung wert ist!',
      'harmonic'),

  // Jupiter
  'jupiter-conj-sun': TransitInterpretation(
      'Jupiter Konjunktion Sonne',
      'Vergroesserungs-Glas auf dein Wesen. Vertrauen wachsen lassen, Chancen '
          'ergreifen. Hueten vor Selbstueberschaetzung.',
      'harmonic'),
  'jupiter-conj-moon': TransitInterpretation(
      'Jupiter Konjunktion Mond',
      'Emotionaler Ueberfluss. Heimat, Familie, Frauen-Themen wichtig. Naehre '
          'dich heute besonders gut.',
      'harmonic'),

  // Saturn
  'saturn-conj-sun': TransitInterpretation(
      'Saturn Konjunktion Sonne',
      'Reife-Zyklus. Wer bin ich, wenn ich erwachsen werde? Verantwortung kommt -- '
          'aber auch eine festere Identitaet.',
      'transform'),
  'saturn-conj-moon': TransitInterpretation(
      'Saturn Konjunktion Mond',
      'Emotionale Reifung. Es kann sich einsam anfuehlen -- aber du baust '
          'tragfaehige Strukturen fuer dein Inneres.',
      'transform'),
  'saturn-square-sun': TransitInterpretation(
      'Saturn Quadrat Sonne',
      'Lebens-Reifepruefung. Pflicht ueber Wunsch. Was wirklich gewollt ist, '
          'haelt diesen Druck aus.',
      'tension'),

  // Uranus
  'uranus-conj-sun': TransitInterpretation(
      'Uranus Konjunktion Sonne',
      'Befreiung! Plietzliche Wende, Umbruch. Wandel zulassen statt '
          'verkrampfen.',
      'transform'),
  'uranus-square-sun': TransitInterpretation(
      'Uranus Quadrat Sonne',
      'Identitaets-Schock. Was muss raus, damit Neues kann? Mut zur '
          'Veraenderung.',
      'transform'),

  // Neptun
  'neptune-conj-sun': TransitInterpretation(
      'Neptun Konjunktion Sonne',
      'Aufloesung der Ego-Grenzen. Mystische Erfahrungen, aber auch Verwirrung. '
          'Erdung wichtig.',
      'reflect'),
  'neptune-trine-moon': TransitInterpretation(
      'Neptun Trigon Mond',
      'Tiefe Intuition, Traum-Botschaften, Mitgefuehl. Meditation lohnt heute '
          'besonders.',
      'harmonic'),

  // Pluto
  'pluto-conj-sun': TransitInterpretation(
      'Pluto Konjunktion Sonne',
      'Tiefgreifende Identitaets-Transformation. Was muss sterben, damit du '
          'wieder geboren wirst? Macht-Themen kommen auf.',
      'transform'),
};

/// Sucht alle Interpretationen, deren Schluessel das Praefix matched.
List<TransitInterpretation> interpretationsFor(String aspectKey) {
  final exact = transitInterpretations[aspectKey];
  if (exact != null) return [exact];
  return [];
}
