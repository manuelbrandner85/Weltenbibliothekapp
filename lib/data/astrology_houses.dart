// Haus-Deutungen fuer Equal-House-System.
// Bereich B1 -- UI-Lookup-Tabelle.

library;

class HouseInterpretation {
  final int number;
  final String name;
  final String shortMeaning;
  final String keyTopic;
  const HouseInterpretation(
      this.number, this.name, this.shortMeaning, this.keyTopic);
}

const List<HouseInterpretation> astrologyHouses = [
  HouseInterpretation(
      1,
      'Erstes Haus (Aszendent)',
      'Selbst, Erscheinung, Identität. Wie du in die Welt eintrittst.',
      'Aszendent'),
  HouseInterpretation(
      2,
      'Zweites Haus',
      'Besitz, Werte, Ressourcen, Selbstwert. Was dir wirklich gehoert.',
      'Werte'),
  HouseInterpretation(3, 'Drittes Haus',
      'Kommunikation, Geschwister, kurze Reisen, Lernen.', 'Kommunikation'),
  HouseInterpretation(
      4,
      'Viertes Haus (IC)',
      'Heim, Familie, Wurzeln, innere Basis. Wo du dich geborgen fuehlst.',
      'Wurzeln'),
  HouseInterpretation(
      5,
      'Fünftes Haus',
      'Kreativität, Romantik, Kinder, Spielfreude. Wo du dich ausdrueckst.',
      'Kreativität'),
  HouseInterpretation(6, 'Sechstes Haus',
      'Gesundheit, Alltag, Dienst, Arbeit, Routinen.', 'Alltag'),
  HouseInterpretation(
      7,
      'Siebtes Haus (Deszendent)',
      'Partnerschaften, Ehe, offene Feinde. Spiegel des Selbst.',
      'Partnerschaft'),
  HouseInterpretation(
      8,
      'Achtes Haus',
      'Transformation, geteilte Ressourcen, Tod/Wiedergeburt, Okkultismus.',
      'Transformation'),
  HouseInterpretation(9, 'Neuntes Haus',
      'Philosophie, Fernreisen, höhere Bildung, Spiritualität.', 'Sinn'),
  HouseInterpretation(
      10,
      'Zehntes Haus (MC)',
      'Karriere, Berufung, öffentliches Ansehen. Was du der Welt zeigst.',
      'Berufung'),
  HouseInterpretation(11, 'Elftes Haus',
      'Freundschaften, Gruppen, Zukunftsvisionen, Hoffnungen.', 'Vision'),
  HouseInterpretation(
      12,
      'Zwölftes Haus',
      'Unterbewusstsein, Rueckzug, Karma, verborgene Feinde, Spiritualität.',
      'Unterbewusstes'),
];

HouseInterpretation? houseFor(int n) {
  if (n < 1 || n > 12) return null;
  return astrologyHouses[n - 1];
}
