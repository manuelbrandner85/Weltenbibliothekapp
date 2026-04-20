/// Tägliche Mond-Empfehlungen: Mondzeichen × Mondphase
///
/// Basiert auf der traditionellen europäischen Mondkalender-Lehre
/// (Paungger/Poppe), angepasst an den modernen Kontext.
///
/// Jede Empfehlung besteht aus Emoji + Thema + kurzem deutschen Text.
/// Die Liste für einen Tag = Zeichen-Empfehlungen + Phasen-Empfehlungen.
library;

import 'moon_calculator.dart';

/// Eine einzelne Tages-Empfehlung.
class MoonDailyTip {
  final String emoji;
  final String topic;
  final String text;
  /// true = positive Empfehlung, false = Warnung/Vermeiden.
  final bool positive;
  const MoonDailyTip({
    required this.emoji,
    required this.topic,
    required this.text,
    this.positive = true,
  });
}

// ═══════════════════════════════════════════════════════════
// Zeichen-abhängige Empfehlungen (unabhängig von der Phase)
// ═══════════════════════════════════════════════════════════

const Map<int, List<MoonDailyTip>> _signTips = {
  // 0 – Widder (Feuer, Frucht, Kopf)
  0: [
    MoonDailyTip(emoji: '💪', topic: 'Gesundheit',
      text: 'Mond im Widder: Kopfzone sensibel. Achte auf Kopfhaut, Augen und Zähne, vermeide anstrengende Operationen am Kopf.'),
    MoonDailyTip(emoji: '🌱', topic: 'Garten',
      text: 'Fruchtzeichen – guter Tag für Tomaten, Paprika, Kürbisse. Aussaat oder Pflege von Fruchtgemüse.'),
    MoonDailyTip(emoji: '🏃', topic: 'Energie',
      text: 'Feurige, treibende Energie. Ideal für Bewegung, Sport und Anstöße, die du schon lange aufschiebst.'),
  ],

  // 1 – Stier (Erde, Wurzel, Hals)
  1: [
    MoonDailyTip(emoji: '🎤', topic: 'Gesundheit',
      text: 'Mond im Stier: Hals, Nacken und Stimme sind empfindlich. Schal tragen, heiße Getränke, keine Erkältung riskieren.'),
    MoonDailyTip(emoji: '🥕', topic: 'Garten',
      text: 'Wurzelzeichen – perfekt für Karotten, Rote Bete, Kartoffeln. Wurzelgemüse pflanzen oder ernten.'),
    MoonDailyTip(emoji: '💰', topic: 'Finanzen',
      text: 'Stier-Mond stabilisiert. Guter Tag für ruhige, langfristige Entscheidungen, Verträge unterschreiben, Sparpläne.'),
  ],

  // 2 – Zwillinge (Luft, Blüte, Schultern/Arme/Lunge)
  2: [
    MoonDailyTip(emoji: '🫁', topic: 'Gesundheit',
      text: 'Mond in den Zwillingen: Lunge und Atemwege aktiv. Atemübungen, Spaziergang an frischer Luft, Yoga für Schultern.'),
    MoonDailyTip(emoji: '🌻', topic: 'Garten',
      text: 'Blütenzeichen – günstig für Blumen und Zierpflanzen. Rasen mähen bremst das Wachstum (bei abnehmendem Mond).'),
    MoonDailyTip(emoji: '💬', topic: 'Kommunikation',
      text: 'Sprache fließt. Wichtige Gespräche, E-Mails, Netzwerken, Lernen und Schreiben gelingen heute besonders gut.'),
  ],

  // 3 – Krebs (Wasser, Blatt, Brust/Magen)
  3: [
    MoonDailyTip(emoji: '🍽️', topic: 'Gesundheit',
      text: 'Mond im Krebs: Magen und Brust sensibel. Leichte, warme Kost bevorzugen. Nicht zu kalt trinken.'),
    MoonDailyTip(emoji: '🥬', topic: 'Garten',
      text: 'Blattzeichen – Salat, Spinat, Kräuter. Gießen wirkt intensiver, aber Gefahr von Pilz bei feuchtem Wetter.'),
    MoonDailyTip(emoji: '💫', topic: 'Spirituell',
      text: 'Starke emotionale Strömung. Ideal für Traumarbeit, Familiengespräche, heilsame Rückzüge.'),
  ],

  // 4 – Löwe (Feuer, Frucht, Herz/Rücken)
  4: [
    MoonDailyTip(emoji: '❤️', topic: 'Gesundheit',
      text: 'Mond im Löwen: Herz und Rücken im Fokus. Keine anstrengenden Herz-Kreislauf-Belastungen, gut für Rückenmobilisation.'),
    MoonDailyTip(emoji: '✂️', topic: 'Haare',
      text: 'Löwe-Mond stärkt die Haarwurzel. Exzellent für Haarschnitte – Haare wachsen voller und glänzender nach.'),
    MoonDailyTip(emoji: '🎭', topic: 'Ausstrahlung',
      text: 'Du wirkst präsent. Guter Tag für Auftritte, Präsentationen, wichtige Treffen, kreativen Ausdruck.'),
  ],

  // 5 – Jungfrau (Erde, Wurzel, Verdauung/Nerven)
  5: [
    MoonDailyTip(emoji: '🫃', topic: 'Gesundheit',
      text: 'Mond in der Jungfrau: Verdauung und Bauch sensibel. Probiotika, Ballaststoffe, keine schwere Kost.'),
    MoonDailyTip(emoji: '🧹', topic: 'Ordnung',
      text: 'Jungfrau-Mond liebt Struktur. Aufräumen, Listen machen, Backup, Finanzübersicht, Keller entrümpeln.'),
    MoonDailyTip(emoji: '✂️', topic: 'Haare',
      text: 'Zweitbester Tag für Haarschnitt nach dem Löwen – kräftige, gesunde Haarstruktur.'),
  ],

  // 6 – Waage (Luft, Blüte, Nieren/Hüfte)
  6: [
    MoonDailyTip(emoji: '🦵', topic: 'Gesundheit',
      text: 'Mond in der Waage: Nieren, Hüfte und Blase aktiv. Viel stilles Wasser, nicht zu salzig essen.'),
    MoonDailyTip(emoji: '🌷', topic: 'Garten',
      text: 'Blütenzeichen – Blumen pflanzen, Düfte genießen. Harmonische Gartenarbeit ohne harte Eingriffe.'),
    MoonDailyTip(emoji: '🤝', topic: 'Beziehung',
      text: 'Waage-Mond sucht Ausgleich. Klärungsgespräche, Partnerentscheidungen, ästhetische Projekte.'),
  ],

  // 7 – Skorpion (Wasser, Blatt, Geschlecht/Ausscheidung)
  7: [
    MoonDailyTip(emoji: '🔄', topic: 'Gesundheit',
      text: 'Mond im Skorpion: Ausscheidungsorgane sensibel. Entgiftung, Sauna, bewusster Verzicht, heilende Tees.'),
    MoonDailyTip(emoji: '🍃', topic: 'Garten',
      text: 'Blattzeichen (Wasser) – gießen wirkt tief. Heilpflanzen ernten, Kräuter trocknen.'),
    MoonDailyTip(emoji: '🔮', topic: 'Spirituell',
      text: 'Tief-transformierende Energie. Schattenarbeit, Schmerztherapie, Loslassen alter Muster. Nichts Oberflächliches.'),
  ],

  // 8 – Schütze (Feuer, Frucht, Oberschenkel/Leber)
  8: [
    MoonDailyTip(emoji: '🍷', topic: 'Gesundheit',
      text: 'Mond im Schützen: Leber und Oberschenkel aktiv. Leberfreundlich essen – wenig Alkohol, bittere Kräuter, Mariendistel.'),
    MoonDailyTip(emoji: '🍅', topic: 'Garten',
      text: 'Fruchtzeichen – Früchte und Beeren pflanzen, ernten, einkochen.'),
    MoonDailyTip(emoji: '🧭', topic: 'Horizont',
      text: 'Schütze-Mond will weit. Reisen planen, Philosophie, große Pläne, Lernen und Lehren – über den Tellerrand schauen.'),
  ],

  // 9 – Steinbock (Erde, Wurzel, Knochen/Knie/Haut)
  9: [
    MoonDailyTip(emoji: '🦴', topic: 'Gesundheit',
      text: 'Mond im Steinbock: Knochen, Knie, Zähne, Haut. Kalzium-Zufuhr, Hautpflege. Bei abnehmendem Mond ideal für Zahnarzt.'),
    MoonDailyTip(emoji: '🥔', topic: 'Garten',
      text: 'Wurzelzeichen – Kartoffeln und Wurzelgemüse setzen oder ernten. Erde bleibt aufnahmefähig.'),
    MoonDailyTip(emoji: '📋', topic: 'Struktur',
      text: 'Steinbock-Mond trägt Verantwortung. Langfristige Pläne, Karriere-Schritte, Strukturen bauen, Disziplin stärken.'),
  ],

  // 10 – Wassermann (Luft, Blüte, Unterschenkel/Kreislauf)
  10: [
    MoonDailyTip(emoji: '🦵', topic: 'Gesundheit',
      text: 'Mond im Wassermann: Unterschenkel, Waden, Kreislauf. Bewegung gegen Stau, Wechselduschen, Venen schonen.'),
    MoonDailyTip(emoji: '💡', topic: 'Ideen',
      text: 'Wassermann-Mond ist innovativ. Brainstorming, ungewöhnliche Lösungen, Gruppenprojekte, Technologie, Freundschaft.'),
    MoonDailyTip(emoji: '🌼', topic: 'Garten',
      text: 'Blütenzeichen – Blumen, Wildblumen, Bienenweide. Experimentelle Beetformen ausprobieren.'),
  ],

  // 11 – Fische (Wasser, Blatt, Füße/Lymphe)
  11: [
    MoonDailyTip(emoji: '🦶', topic: 'Gesundheit',
      text: 'Mond in den Fischen: Füße und Lymphe. Fußbad, Lymphdrainage, Massage. Keine neuen Fußeingriffe heute.'),
    MoonDailyTip(emoji: '🌿', topic: 'Garten',
      text: 'Blattzeichen – Pflanzen besonders empfindsam. Wenig gießen bei abnehmendem Mond, dafür ruhige Pflege.'),
    MoonDailyTip(emoji: '🎨', topic: 'Spirituell',
      text: 'Fische-Mond öffnet die Intuition. Kunst, Musik, Meditation, Träume, Mitgefühl. Meide Alkohol und harte Reize.'),
  ],
};

// ═══════════════════════════════════════════════════════════
// Phasen-abhängige Empfehlungen (unabhängig vom Zeichen)
// ═══════════════════════════════════════════════════════════

const Map<String, List<MoonDailyTip>> _phaseTips = {
  'new_moon': [
    MoonDailyTip(emoji: '🎯', topic: 'Fokus',
      text: 'Neumond – Intentionen setzen. Schreibe heute drei Dinge auf, die du in diesem Mondzyklus manifestieren willst.'),
    MoonDailyTip(emoji: '⚠️', topic: 'Vermeiden',
      text: 'Kein guter Tag für Ernte oder sichtbare Veränderungen. Ruhe, Einkehr, kein Streit.', positive: false),
  ],

  'waxing_crescent': [
    MoonDailyTip(emoji: '🌱', topic: 'Wachstum',
      text: 'Zunehmende Sichel – erste Schritte. Etwas Kleines, Konkretes für dein Neumond-Ziel tun.'),
    MoonDailyTip(emoji: '✂️', topic: 'Haare',
      text: 'Haare schneiden bei zunehmendem Mond = dickeres, volleres Nachwachsen.'),
  ],

  'first_quarter': [
    MoonDailyTip(emoji: '⚡', topic: 'Handeln',
      text: 'Erstes Viertel – Spannungsphase. Hindernisse werden sichtbar. Durchhalten, entscheiden, nicht ausweichen.'),
    MoonDailyTip(emoji: '💪', topic: 'Körper',
      text: 'Kraft-Training und anstrengende Bewegung gelingen heute besonders gut.'),
  ],

  'waxing_gibbous': [
    MoonDailyTip(emoji: '🔍', topic: 'Feinabstimmung',
      text: 'Zunehmender Mond – überprüfe und justiere. Was fehlt noch, damit dein Ziel Realität wird?'),
    MoonDailyTip(emoji: '💰', topic: 'Finanzen',
      text: 'Günstiger Zeitraum für aufbauende Finanzentscheidungen: Sparplan starten, Investition tätigen.'),
  ],

  'full_moon': [
    MoonDailyTip(emoji: '🌕', topic: 'Höhepunkt',
      text: 'Vollmond – maximale Energie. Feiere, was manifestiert wurde. Lass los, was nicht mehr dient.'),
    MoonDailyTip(emoji: '⚠️', topic: 'Vermeiden',
      text: 'Schlaf kann gestört sein. Keine schwerwiegenden OPs oder großen Entscheidungen in Streit-Situationen.', positive: false),
    MoonDailyTip(emoji: '💎', topic: 'Kristalle',
      text: 'Kristalle und Mondwasser im Vollmondlicht aufladen – besonders Bergkristall, Mondstein, Selenit.'),
  ],

  'waning_gibbous': [
    MoonDailyTip(emoji: '🙏', topic: 'Dankbarkeit',
      text: 'Abnehmender Mond – Dankbarkeit ausdrücken. Eine ehrliche Wertschätzung schreiben oder aussprechen.'),
    MoonDailyTip(emoji: '🌾', topic: 'Garten',
      text: 'Ernten wirkt jetzt besonders haltbar – Kräuter trocknen, einkochen, einlagern.'),
  ],

  'last_quarter': [
    MoonDailyTip(emoji: '🧹', topic: 'Reinigen',
      text: 'Letztes Viertel – entrümpeln. Ausmisten wirkt jetzt tief. Ein Bereich (Schublade, Inbox, Kalender) bewusst leeren.'),
    MoonDailyTip(emoji: '✂️', topic: 'Haare',
      text: 'Haare schneiden bei abnehmendem Mond = langsameres Nachwachsen (ideal für Augenbrauen, Bart, Rasur).'),
  ],

  'waning_crescent': [
    MoonDailyTip(emoji: '😌', topic: 'Ruhe',
      text: 'Abnehmende Sichel – tiefe Ruhephase. 60 Minuten ohne Bildschirm, bewusst auf Intuition lauschen.'),
    MoonDailyTip(emoji: '🔮', topic: 'Träume',
      text: 'Träume sind jetzt besonders klar. Traum-Journal bereithalten, morgens sofort notieren.'),
    MoonDailyTip(emoji: '⚠️', topic: 'Vermeiden',
      text: 'Keine Neuanfänge, keine großen Käufe. Warte auf den nächsten Neumond.', positive: false),
  ],
};

// ═══════════════════════════════════════════════════════════
// Öffentliche API
// ═══════════════════════════════════════════════════════════

/// Liefert die Tagesempfehlungen für einen Mond-Snapshot.
/// Ergebnis = Zeichen-Tipps + Phasen-Tipps (in dieser Reihenfolge).
List<MoonDailyTip> getDailyMoonTips(MoonSnapshot snapshot) {
  final signTips = _signTips[snapshot.moonSignIndex] ?? const [];
  final phaseTips = _phaseTips[snapshot.phaseKey] ?? const [];
  return [...signTips, ...phaseTips];
}

/// Kurz-Zusammenfassung für den Heute-Tab, z.B. "Zunehmender Mond im Stier".
String buildMoonHeadline(MoonSnapshot s) {
  final waxWan = s.isWaxing ? 'Zunehmender' : 'Abnehmender';
  // Bei den markanten Phasen (Neumond / Vollmond / Viertel) nicht generisch "Zunehmender/Abnehmender"
  switch (s.phaseKey) {
    case 'new_moon':
      return 'Neumond im ${s.moonSignName}';
    case 'full_moon':
      return 'Vollmond im ${s.moonSignName}';
    case 'first_quarter':
      return 'Erstes Viertel – Mond im ${s.moonSignName}';
    case 'last_quarter':
      return 'Letztes Viertel – Mond im ${s.moonSignName}';
    default:
      return '$waxWan Mond im ${s.moonSignName}';
  }
}
