// Gene Keys (Richard Rudd) Mapping zu den 64 Hexagrammen / Human Design Gates.
// Bereich C2 -- Cross-System Verbindung HD <-> I-Ging <-> Gene Keys.
//
// Jedes Gate/Hexagramm/Gene Key Nr. 1-64 hat ein Schatten-Gabe-Siddhi-Spektrum:
//   Shadow  = unbewusste Verzerrung
//   Gift    = bewusste Talent-Manifestation
//   Siddhi  = transzendente Verkoerperung
//
// Quelle: Richard Rudd, The Gene Keys (2009). Programming-Partner = das
// entgegengesetzte Hexagramm im Koenig-Wen-Schema.

library;

class GeneKey {
  final int number;        // 1-64
  final String shadowDE;
  final String giftDE;
  final String siddhiDE;
  final String ichingTitle; // Titel des Koenig-Wen-Hexagramms
  final int programmingPartner; // Gate-Nummer des Gegenpols

  const GeneKey({
    required this.number,
    required this.shadowDE,
    required this.giftDE,
    required this.siddhiDE,
    required this.ichingTitle,
    required this.programmingPartner,
  });
}

const List<GeneKey> geneKeys = [
  GeneKey(number: 1, shadowDE: 'Entropie', giftDE: 'Frische', siddhiDE: 'Schönheit',
      ichingTitle: 'Das Schöpferische', programmingPartner: 2),
  GeneKey(number: 2, shadowDE: 'Verschiebung', giftDE: 'Orientierung', siddhiDE: 'Einheit',
      ichingTitle: 'Das Empfangende', programmingPartner: 1),
  GeneKey(number: 3, shadowDE: 'Chaos', giftDE: 'Innovation', siddhiDE: 'Unschuld',
      ichingTitle: 'Anfangsschwierigkeit', programmingPartner: 50),
  GeneKey(number: 4, shadowDE: 'Intoleranz', giftDE: 'Verständnis', siddhiDE: 'Vergebung',
      ichingTitle: 'Jugendtorheit', programmingPartner: 49),
  GeneKey(number: 5, shadowDE: 'Ungeduld', giftDE: 'Geduld', siddhiDE: 'Zeitlosigkeit',
      ichingTitle: 'Das Warten', programmingPartner: 35),
  GeneKey(number: 6, shadowDE: 'Konflikt', giftDE: 'Diplomatie', siddhiDE: 'Frieden',
      ichingTitle: 'Der Streit', programmingPartner: 36),
  GeneKey(number: 7, shadowDE: 'Spaltung', giftDE: 'Führung', siddhiDE: 'Tugend',
      ichingTitle: 'Das Heer', programmingPartner: 13),
  GeneKey(number: 8, shadowDE: 'Mittelmäßigkeit', giftDE: 'Stil', siddhiDE: 'Exquisitheit',
      ichingTitle: 'Zusammenhalten', programmingPartner: 14),
  GeneKey(number: 9, shadowDE: 'Trägheit', giftDE: 'Entschlossenheit', siddhiDE: 'Unbesiegbarkeit',
      ichingTitle: 'Des Kleinen Zähmungskraft', programmingPartner: 16),
  GeneKey(number: 10, shadowDE: 'Selbstbesessenheit', giftDE: 'Natürlichkeit', siddhiDE: 'Sein',
      ichingTitle: 'Das Auftreten', programmingPartner: 15),
  GeneKey(number: 11, shadowDE: 'Verdunkelung', giftDE: 'Idealismus', siddhiDE: 'Licht',
      ichingTitle: 'Friede', programmingPartner: 12),
  GeneKey(number: 12, shadowDE: 'Eitelkeit', giftDE: 'Diskriminierung', siddhiDE: 'Reinheit',
      ichingTitle: 'Stockung', programmingPartner: 11),
  GeneKey(number: 13, shadowDE: 'Zwietracht', giftDE: 'Diskriminierung', siddhiDE: 'Empathie',
      ichingTitle: 'Gemeinschaft mit Menschen', programmingPartner: 7),
  GeneKey(number: 14, shadowDE: 'Kompromiss', giftDE: 'Kompetenz', siddhiDE: 'Großzügigkeit',
      ichingTitle: 'Besitz von Großem', programmingPartner: 8),
  GeneKey(number: 15, shadowDE: 'Stumpfheit', giftDE: 'Magnetismus', siddhiDE: 'Blüte',
      ichingTitle: 'Bescheidenheit', programmingPartner: 10),
  GeneKey(number: 16, shadowDE: 'Gleichgültigkeit', giftDE: 'Vielseitigkeit', siddhiDE: 'Meisterschaft',
      ichingTitle: 'Begeisterung', programmingPartner: 9),
  GeneKey(number: 17, shadowDE: 'Meinung', giftDE: 'Weitsicht', siddhiDE: 'Allwissenheit',
      ichingTitle: 'Nachfolge', programmingPartner: 18),
  GeneKey(number: 18, shadowDE: 'Beurteilung', giftDE: 'Integrität', siddhiDE: 'Vollkommenheit',
      ichingTitle: 'Arbeit am Verdorbenen', programmingPartner: 17),
  GeneKey(number: 19, shadowDE: 'Mitabhängigkeit', giftDE: 'Sensitivität', siddhiDE: 'Opfer',
      ichingTitle: 'Annäherung', programmingPartner: 33),
  GeneKey(number: 20, shadowDE: 'Oberflächlichkeit', giftDE: 'Selbst-Sicherheit', siddhiDE: 'Präsenz',
      ichingTitle: 'Die Betrachtung', programmingPartner: 34),
  GeneKey(number: 21, shadowDE: 'Kontrolle', giftDE: 'Autorität', siddhiDE: 'Tapferkeit',
      ichingTitle: 'Durchbeißen', programmingPartner: 48),
  GeneKey(number: 22, shadowDE: 'Schande', giftDE: 'Anmut', siddhiDE: 'Anmut',
      ichingTitle: 'Anmut', programmingPartner: 47),
  GeneKey(number: 23, shadowDE: 'Komplexität', giftDE: 'Einfachheit', siddhiDE: 'Quintessenz',
      ichingTitle: 'Zersplitterung', programmingPartner: 43),
  GeneKey(number: 24, shadowDE: 'Sucht', giftDE: 'Erfindungsreichtum', siddhiDE: 'Stille',
      ichingTitle: 'Die Wiederkehr', programmingPartner: 44),
  GeneKey(number: 25, shadowDE: 'Verengung', giftDE: 'Akzeptanz', siddhiDE: 'Universelle Liebe',
      ichingTitle: 'Unschuld', programmingPartner: 46),
  GeneKey(number: 26, shadowDE: 'Stolz', giftDE: 'Künstlertum', siddhiDE: 'Unbesiegbarkeit',
      ichingTitle: 'Des Großen Zähmungskraft', programmingPartner: 45),
  GeneKey(number: 27, shadowDE: 'Selbstsucht', giftDE: 'Altruismus', siddhiDE: 'Selbstlosigkeit',
      ichingTitle: 'Die Ernährung', programmingPartner: 28),
  GeneKey(number: 28, shadowDE: 'Zwecklosigkeit', giftDE: 'Totalität', siddhiDE: 'Unsterblichkeit',
      ichingTitle: 'Des Großen Übergewicht', programmingPartner: 27),
  GeneKey(number: 29, shadowDE: 'Halbherzigkeit', giftDE: 'Hingabe', siddhiDE: 'Hingabe',
      ichingTitle: 'Das Abgrundtiefe', programmingPartner: 30),
  GeneKey(number: 30, shadowDE: 'Begehren', giftDE: 'Frohsinn', siddhiDE: 'Verzückung',
      ichingTitle: 'Das Haftende', programmingPartner: 29),
  GeneKey(number: 31, shadowDE: 'Anmaßung', giftDE: 'Führerschaft', siddhiDE: 'Demut',
      ichingTitle: 'Die Einwirkung', programmingPartner: 41),
  GeneKey(number: 32, shadowDE: 'Versagen', giftDE: 'Bewahrung', siddhiDE: 'Verehrung',
      ichingTitle: 'Die Dauer', programmingPartner: 42),
  GeneKey(number: 33, shadowDE: 'Vergessen', giftDE: 'Achtsamkeit', siddhiDE: 'Offenbarung',
      ichingTitle: 'Der Rückzug', programmingPartner: 19),
  GeneKey(number: 34, shadowDE: 'Gewalt', giftDE: 'Stärke', siddhiDE: 'Majestät',
      ichingTitle: 'Des Großen Macht', programmingPartner: 20),
  GeneKey(number: 35, shadowDE: 'Hunger', giftDE: 'Abenteuer', siddhiDE: 'Grenzenlosigkeit',
      ichingTitle: 'Der Fortschritt', programmingPartner: 5),
  GeneKey(number: 36, shadowDE: 'Turbulenz', giftDE: 'Menschlichkeit', siddhiDE: 'Mitgefühl',
      ichingTitle: 'Verfinsterung des Lichts', programmingPartner: 6),
  GeneKey(number: 37, shadowDE: 'Schwäche', giftDE: 'Gleichberechtigung', siddhiDE: 'Zärtlichkeit',
      ichingTitle: 'Die Familie', programmingPartner: 40),
  GeneKey(number: 38, shadowDE: 'Kampf', giftDE: 'Beharrlichkeit', siddhiDE: 'Ehre',
      ichingTitle: 'Der Gegensatz', programmingPartner: 39),
  GeneKey(number: 39, shadowDE: 'Provokation', giftDE: 'Dynamik', siddhiDE: 'Befreiung',
      ichingTitle: 'Hemmnis', programmingPartner: 38),
  GeneKey(number: 40, shadowDE: 'Erschöpfung', giftDE: 'Entschlossenheit', siddhiDE: 'Göttlicher Wille',
      ichingTitle: 'Die Befreiung', programmingPartner: 37),
  GeneKey(number: 41, shadowDE: 'Phantasie', giftDE: 'Antizipation', siddhiDE: 'Emanation',
      ichingTitle: 'Die Minderung', programmingPartner: 31),
  GeneKey(number: 42, shadowDE: 'Erwartung', giftDE: 'Loslassen', siddhiDE: 'Feier',
      ichingTitle: 'Die Mehrung', programmingPartner: 32),
  GeneKey(number: 43, shadowDE: 'Taubheit', giftDE: 'Einsicht', siddhiDE: 'Epiphanie',
      ichingTitle: 'Der Durchbruch', programmingPartner: 23),
  GeneKey(number: 44, shadowDE: 'Einmischung', giftDE: 'Teamwork', siddhiDE: 'Synarchie',
      ichingTitle: 'Das Entgegenkommen', programmingPartner: 24),
  GeneKey(number: 45, shadowDE: 'Dominanz', giftDE: 'Synergie', siddhiDE: 'Gemeinschaft',
      ichingTitle: 'Die Sammlung', programmingPartner: 26),
  GeneKey(number: 46, shadowDE: 'Ernsthaftigkeit', giftDE: 'Entzückung', siddhiDE: 'Ekstase',
      ichingTitle: 'Das Empordringen', programmingPartner: 25),
  GeneKey(number: 47, shadowDE: 'Unterdrückung', giftDE: 'Transmutation', siddhiDE: 'Transfiguration',
      ichingTitle: 'Die Bedrängnis', programmingPartner: 22),
  GeneKey(number: 48, shadowDE: 'Unzulänglichkeit', giftDE: 'Einfallsreichtum', siddhiDE: 'Weisheit',
      ichingTitle: 'Der Brunnen', programmingPartner: 21),
  GeneKey(number: 49, shadowDE: 'Reaktion', giftDE: 'Revolution', siddhiDE: 'Wiedergeburt',
      ichingTitle: 'Die Umwälzung', programmingPartner: 4),
  GeneKey(number: 50, shadowDE: 'Korruption', giftDE: 'Gleichgewicht', siddhiDE: 'Harmonie',
      ichingTitle: 'Der Tiegel', programmingPartner: 3),
  GeneKey(number: 51, shadowDE: 'Aufregung', giftDE: 'Initiative', siddhiDE: 'Erwachen',
      ichingTitle: 'Das Erregende', programmingPartner: 57),
  GeneKey(number: 52, shadowDE: 'Stress', giftDE: 'Beschränkung', siddhiDE: 'Stille',
      ichingTitle: 'Das Stillehalten', programmingPartner: 58),
  GeneKey(number: 53, shadowDE: 'Unreife', giftDE: 'Expansion', siddhiDE: 'Überfluss',
      ichingTitle: 'Die Entwicklung', programmingPartner: 54),
  GeneKey(number: 54, shadowDE: 'Habgier', giftDE: 'Aspiration', siddhiDE: 'Aufstieg',
      ichingTitle: 'Das heiratende Mädchen', programmingPartner: 53),
  GeneKey(number: 55, shadowDE: 'Opferrolle', giftDE: 'Freiheit', siddhiDE: 'Freiheit',
      ichingTitle: 'Die Fülle', programmingPartner: 59),
  GeneKey(number: 56, shadowDE: 'Ablenkung', giftDE: 'Anreicherung', siddhiDE: 'Berauschung',
      ichingTitle: 'Der Wanderer', programmingPartner: 60),
  GeneKey(number: 57, shadowDE: 'Unbehagen', giftDE: 'Intuition', siddhiDE: 'Klarheit',
      ichingTitle: 'Das Sanfte', programmingPartner: 51),
  GeneKey(number: 58, shadowDE: 'Unzufriedenheit', giftDE: 'Vitalität', siddhiDE: 'Glückseligkeit',
      ichingTitle: 'Das Heitere', programmingPartner: 52),
  GeneKey(number: 59, shadowDE: 'Unehrlichkeit', giftDE: 'Intimität', siddhiDE: 'Transparenz',
      ichingTitle: 'Die Auflösung', programmingPartner: 55),
  GeneKey(number: 60, shadowDE: 'Begrenzung', giftDE: 'Realismus', siddhiDE: 'Gerechtigkeit',
      ichingTitle: 'Die Beschränkung', programmingPartner: 56),
  GeneKey(number: 61, shadowDE: 'Psychose', giftDE: 'Inspiration', siddhiDE: 'Heiligkeit',
      ichingTitle: 'Innere Wahrheit', programmingPartner: 62),
  GeneKey(number: 62, shadowDE: 'Intellekt', giftDE: 'Präzision', siddhiDE: 'Unfehlbarkeit',
      ichingTitle: 'Vorherrschen des Kleinen', programmingPartner: 61),
  GeneKey(number: 63, shadowDE: 'Zweifel', giftDE: 'Untersuchung', siddhiDE: 'Wahrheit',
      ichingTitle: 'Nach der Vollendung', programmingPartner: 64),
  GeneKey(number: 64, shadowDE: 'Konfusion', giftDE: 'Imagination', siddhiDE: 'Erleuchtung',
      ichingTitle: 'Vor der Vollendung', programmingPartner: 63),
];

/// Schneller Lookup per Gate-Nummer (1-64).
GeneKey? geneKeyFor(int number) {
  if (number < 1 || number > 64) return null;
  return geneKeys[number - 1];
}
