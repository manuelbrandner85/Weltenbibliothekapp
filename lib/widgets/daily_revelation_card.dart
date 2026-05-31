// DailyRevelationCard -- zeigt jeden Tag ein neues Macht-/Strategie-
// Prinzip. Engagement-Hook fuer die Vorhang-Welt: gibt dem User einen
// Grund, die App taeglich zu oeffnen.
//
// FEATURE (V2): Das angezeigte Prinzip wird deterministisch aus dem
// Tag-des-Jahres gewaehlt -- so sieht jeder am gleichen Tag dasselbe,
// und es wechselt zuverlaessig um Mitternacht.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// dart2js-Bug-Workaround: Named Records kompilieren nicht zuverlaessig.
class Principle {
  final String title;
  final String body;
  const Principle({required this.title, required this.body});
}

class DailyRevelationCard extends StatelessWidget {
  final Color accent;
  final String emoji;
  final String label;
  final List<Principle>? principles;

  const DailyRevelationCard({
    super.key,
    this.accent = const Color(0xFFC9A84C),
    this.emoji = '🎭',
    this.label = 'TÄGLICHE ENTHÜLLUNG',
    this.principles,
  });

  /// Bewusstseins-/Quanten-Impulse fuer die Ursprung-Welt.
  static const List<Principle> ursprungInsights = [
    Principle(
      title: 'Beobachtung formt Realitaet',
      body:
          'In der Quantenphysik kollabiert die Wellenfunktion erst durch '
              'Messung. Deine Aufmerksamkeit ist kein passiver Akt -- sie '
              'gestaltet mit.',
    ),
    Principle(
      title: 'Focus 10 -- Koerper schlaeft, Geist wach',
      body:
          'Der erste Gateway-Zustand: tiefe koerperliche Entspannung bei '
              'voll wachem Bewusstsein. Das Tor zu allen weiteren Ebenen.',
    ),
    Principle(
      title: 'Resonanz',
      body:
          'Gleiche Frequenzen verstaerken sich. Was du innerlich kultivierst, '
              'zieht im Aussen Entsprechendes an -- Schwingung sucht Schwingung.',
    ),
    Principle(
      title: 'Der Beobachter hinter dem Denken',
      body:
          'Du bist nicht deine Gedanken -- du bist das Gewahrsein, das sie '
              'bemerkt. In diesem Raum liegt deine eigentliche Freiheit.',
    ),
    Principle(
      title: 'Nichtlokalitaet',
      body:
          'Verschraenkte Teilchen reagieren ueber jede Distanz hinweg '
              'augenblicklich. Bewusstsein kennt moeglicherweise keinen Raum.',
    ),
    Principle(
      title: 'Kohaerenz von Herz und Hirn',
      body:
          'Ein ruhiger, gleichmaessiger Herzrhythmus synchronisiert die '
              'Gehirnwellen. Kohaerenz ist messbar -- und trainierbar.',
    ),
    Principle(
      title: 'Die Schwelle der Stille',
      body:
          'Zwischen zwei Gedanken liegt eine Luecke. Wer sie weitet, betritt '
              'den Ursprungsraum, aus dem alle Form entsteht.',
    ),
    Principle(
      title: 'Intention als Saat',
      body:
          'Klar formulierte Absicht wirkt wie ein Same im Feld der '
              'Moeglichkeiten. Patterning macht aus Wunsch gerichtete Energie.',
    ),
    Principle(
      title: 'Theta -- das Tor zum Unbewussten',
      body:
          '4-7 Hz: die Frequenz tiefer Meditation und Heilung. Hier '
              'reorganisiert sich, was im Wachzustand verschlossen bleibt.',
    ),
    Principle(
      title: 'Du bist mehr als dein Koerper',
      body:
          'Das Gateway-Experiment postuliert: Bewusstsein nutzt das Gehirn, '
              'ist aber nicht darauf beschraenkt. Erfahre es selbst.',
    ),
  ];

  // Kuratierte Macht-Prinzipien (Kurzform, inspiriert von Greene/Cialdini/
  // Sun Tzu). Erweiterbar.
  static const List<Principle> _principles = [
    Principle(
      title: 'Verberge deine Absichten',
      body:
          'Halte Menschen im Unklaren, und sie koennen sich nicht verteidigen. '
              'Was sie nicht kommen sehen, koennen sie nicht abwehren.',
    ),
    Principle(
      title: 'Rede nie mehr als noetig',
      body:
          'Wer viel sagt, sagt Banales -- und gibt Angriffsflaeche. Schweigen '
              'wirkt machtvoller und laesst andere sich offenbaren.',
    ),
    Principle(
      title: 'Reziprozitaet',
      body:
          'Ein kleiner Gefallen erzeugt das Beduerfnis, ihn zu erwidern. Wer '
              'zuerst gibt, kontrolliert oft den naechsten Zug.',
    ),
    Principle(
      title: 'Sozialer Beweis',
      body:
          'Menschen orientieren sich am Verhalten anderer. Zeige, dass viele '
              'etwas tun -- und der Einzelne folgt fast automatisch.',
    ),
    Principle(
      title: 'Knappheit',
      body:
          'Was selten ist, wirkt wertvoller. Verfuegbarkeit zu begrenzen '
              'steigert Begehrlichkeit staerker als jedes Argument.',
    ),
    Principle(
      title: 'Framing',
      body:
          'Nicht die Fakten entscheiden, sondern ihr Rahmen. Wer den Kontext '
              'setzt, bestimmt, wie die gleiche Information gedeutet wird.',
    ),
    Principle(
      title: 'Ankereffekt',
      body:
          'Die erste Zahl im Raum praegt alle folgenden Urteile. Wer zuerst '
              'ankert, verschiebt die gesamte Verhandlung.',
    ),
    Principle(
      title: 'Spiegle, um zu binden',
      body:
          'Subtiles Angleichen von Sprache und Koerperhaltung erzeugt '
              'unbewusstes Vertrauen. Aehnlichkeit schafft Naehe.',
    ),
    Principle(
      title: 'Lass andere die Arbeit tun',
      body:
          'Nutze fremde Kompetenz und Energie fuer deine Ziele -- aber sorge '
              'dafuer, dass der Verdienst dir zugeschrieben wird.',
    ),
    Principle(
      title: 'Kenne das Spielfeld',
      body:
          'Sun Tzu: Wer sich selbst und den Gegner kennt, muss hundert '
              'Schlachten nicht fuerchten. Aufklaerung schlaegt Staerke.',
    ),
    Principle(
      title: 'Kontrolliere die Optionen',
      body:
          'Lass andere waehlen -- aber zwischen Alternativen, die DU gesetzt '
              'hast. Die Illusion der Wahl ist machtvoller als Zwang.',
    ),
    Principle(
      title: 'Geduld als Waffe',
      body:
          'Wer warten kann, diktiert das Tempo. Ungeduld ist eine Schwaeche, '
              'die der Geduldige gegen den Hastigen ausspielt.',
    ),
    Principle(
      title: 'Erzeuge Abhaengigkeit',
      body:
          'Mache dich unverzichtbar. Solange andere dich brauchen, bist du '
              'sicher -- Loyalitaet folgt dem Eigeninteresse.',
    ),
    Principle(
      title: 'Das Gesetz der Verknappung von Lob',
      body:
          'Selten verteiltes Lob wiegt schwerer. Wer staendig lobt, entwertet '
              'die eigene Anerkennung.',
    ),
  ];

  Principle get _today {
    final set = principles ?? _principles;
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return set[dayOfYear % set.length];
  }

  @override
  Widget build(BuildContext context) {
    final p = _today;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.14),
            Colors.black.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: TextStyle(fontSize: 16, color: accent)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Teilen',
                icon: Icon(Icons.ios_share_rounded, color: accent, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                      text: '$emoji ${p.title}\n\n${p.body}\n\n— Weltenbibliothek'));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('In Zwischenablage kopiert'),
                    duration: Duration(seconds: 2),
                  ));
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            p.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            p.body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
