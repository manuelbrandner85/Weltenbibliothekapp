// 🌳 KABBALAH — 22 PFADE DES LEBENSBAUMS
//
// Jeder der 22 Pfade verbindet zwei Sephiroth und ist einem hebräischen
// Buchstaben + Tarot-Trumpf zugeordnet. Klassische Zuordnung aus dem
// Sepher Yetzirah & Golden-Dawn-System.

import '../widgets/lesson_series_screen.dart';

const List<LessonSeriesEntry> kabbalahPaths22 = [
  LessonSeriesEntry(
    code: 'p11',
    symbol: 'א',
    title: 'Pfad 11 — Aleph',
    subtitle: 'Der Narr · Kether → Chokmah · Luft',
    meaning: 'Reine Möglichkeit, der erste Atemzug aus dem Unmanifestierten. '
        'Aleph (1) verbindet die Krone mit der Weisheit — uranfänglicher Impuls, '
        'bevor Form entsteht.',
    reflection:
        'Wo in deinem Leben darfst du gerade den Sprung ins Unbekannte wagen, '
        'ohne zu wissen wohin?',
  ),
  LessonSeriesEntry(
    code: 'p12',
    symbol: 'ב',
    title: 'Pfad 12 — Bet',
    subtitle: 'Der Magier · Kether → Binah · Merkur',
    meaning:
        'Das Haus (Bet=2) — der Magier nutzt die vier Elemente (Stab/Schwert/Kelch/Pentakel) '
        'um Geistiges in Materielles zu übersetzen.',
    reflection:
        'Welche Werkzeuge stehen dir zur Verfügung, die du noch nicht bewusst einsetzt?',
  ),
  LessonSeriesEntry(
    code: 'p13',
    symbol: 'ג',
    title: 'Pfad 13 — Gimel',
    subtitle: 'Die Hohepriesterin · Kether → Tipheret · Mond',
    meaning:
        'Gimel = Kamel, das durch die Wüste trägt. Verbindet Krone direkt mit '
        'Schönheit/Sonne — der Weg der inneren Stille, der Intuition über den Abgrund.',
    reflection:
        'Welcher inneren Stimme schenkst du heute mehr Vertrauen als der äußeren Welt?',
  ),
  LessonSeriesEntry(
    code: 'p14',
    symbol: 'ד',
    title: 'Pfad 14 — Dalet',
    subtitle: 'Die Herrscherin · Chokmah → Binah · Venus',
    meaning:
        'Dalet = Tor. Venus verbindet aktiv-männliche Weisheit (Chokmah) mit '
        'empfangend-weiblichem Verstehen (Binah). Schöpferische Vereinigung.',
    reflection:
        'Wo sehnst du dich nach mehr Schönheit, Sinnlichkeit oder Verbundenheit?',
  ),
  LessonSeriesEntry(
    code: 'p15',
    symbol: 'ה',
    title: 'Pfad 15 — Heh',
    subtitle: 'Der Stern · Chokmah → Tipheret · Wassermann',
    meaning:
        'Heh = Fenster, das Licht durchlässt. Verbindet Vater-Weisheit mit '
        'Sonne — Hoffnung, neue Sicht, das Funkeln am Horizont.',
    reflection:
        'Welche Vision leitet dich gerade — auch wenn sie noch weit entfernt scheint?',
  ),
  LessonSeriesEntry(
    code: 'p16',
    symbol: 'ו',
    title: 'Pfad 16 — Vav',
    subtitle: 'Der Hierophant · Chokmah → Chesed · Stier',
    meaning:
        'Vav = Nagel, der verbindet. Bringt höhere Weisheit in die Form fester '
        'Strukturen (Chesed). Tradition, Lehrer, geweihte Räume.',
    reflection:
        'Wer war ein Lehrer in deinem Leben — und welche seiner Worte trägst du noch heute?',
  ),
  LessonSeriesEntry(
    code: 'p17',
    symbol: 'ז',
    title: 'Pfad 17 — Zayin',
    subtitle: 'Die Liebenden · Binah → Tipheret · Zwillinge',
    meaning: 'Zayin = Schwert der Unterscheidung. Wahl zwischen Wegen, '
        'Erkenntnis durch Polarität. Die Liebenden müssen wählen — und wachsen.',
    reflection:
        'Welche Entscheidung schiebst du auf, die deine Seele längst getroffen hat?',
  ),
  LessonSeriesEntry(
    code: 'p18',
    symbol: 'ח',
    title: 'Pfad 18 — Chet',
    subtitle: 'Der Wagen · Binah → Geburah · Krebs',
    meaning:
        'Chet = Zaun. Der Wagen wird von gegensätzlichen Sphinxen gezogen — '
        'Wille muss Polaritäten beherrschen. Triumph durch innere Disziplin.',
    reflection:
        'Welche zwei inneren Kräfte ziehen dich gerade auseinander — und wer hält die Zügel?',
  ),
  LessonSeriesEntry(
    code: 'p19',
    symbol: 'ט',
    title: 'Pfad 19 — Tet',
    subtitle: 'Die Kraft · Chesed → Geburah · Löwe',
    meaning:
        'Tet = Schlange. Verbindet Gnade mit Strenge — sanfte Beherrschung '
        'der wilden Triebe durch Liebe, nicht durch Gewalt.',
    reflection:
        'Welchen inneren "Löwen" zähmst du gerade — und mit welcher Methode?',
  ),
  LessonSeriesEntry(
    code: 'p20',
    symbol: 'י',
    title: 'Pfad 20 — Yod',
    subtitle: 'Der Eremit · Chesed → Tipheret · Jungfrau',
    meaning:
        'Yod = Hand, kleinster Buchstabe, Same aller anderen. Der Eremit trägt '
        'die Laterne der Weisheit — Rückzug zum inneren Licht.',
    reflection: 'Welcher Rückzug würde deiner Seele gerade gut tun?',
  ),
  LessonSeriesEntry(
    code: 'p21',
    symbol: 'כ',
    title: 'Pfad 21 — Kaph',
    subtitle: 'Schicksalsrad · Chesed → Netzach · Jupiter',
    meaning: 'Kaph = offene Hand. Jupiter expandiert. Rad symbolisiert die '
        'Wiederkehr, das große Spiel von Aufstieg und Fall.',
    reflection:
        'Wo erkennst du gerade ein wiederkehrendes Muster — Chance oder Karma?',
  ),
  LessonSeriesEntry(
    code: 'p22',
    symbol: 'ל',
    title: 'Pfad 22 — Lamed',
    subtitle: 'Gerechtigkeit · Geburah → Tipheret · Waage',
    meaning:
        'Lamed = Ochsenstachel/Lehrer. Karma wird gewogen, Ursache und Wirkung '
        'klar gesehen. Justitia ohne Augenbinde im Hermetischen.',
    reflection:
        'Welche Konsequenz aus früheren Entscheidungen darfst du gerade annehmen?',
  ),
  LessonSeriesEntry(
    code: 'p23',
    symbol: 'מ',
    title: 'Pfad 23 — Mem',
    subtitle: 'Der Gehängte · Geburah → Hod · Wasser',
    meaning: 'Mem = Wasser. Der Gehängte hängt verkehrt am Lebensbaum — '
        'Hingabe, Perspektivenwechsel, freiwilliges Opfer.',
    reflection: 'Was darfst du gerade loslassen, ohne zu kämpfen?',
  ),
  LessonSeriesEntry(
    code: 'p24',
    symbol: 'נ',
    title: 'Pfad 24 — Nun',
    subtitle: 'Der Tod · Tipheret → Netzach · Skorpion',
    meaning: 'Nun = Fisch, ständige Verwandlung. Tod-Karte = Transformation, '
        'nicht Ende. Was sterben muss, damit Neues wachsen kann.',
    reflection: 'Welche Identität, Rolle oder Gewohnheit darf gerade sterben?',
  ),
  LessonSeriesEntry(
    code: 'p25',
    symbol: 'ס',
    title: 'Pfad 25 — Samech',
    subtitle: 'Die Mäßigung · Tipheret → Yesod · Schütze',
    meaning:
        'Samech = Stütze, Kreis. Engel mischt Wasser zwischen zwei Kelchen — '
        'Alchemie der Gegensätze, Mittelweg.',
    reflection: 'Wo überdosierst du eine Energie — und wo läuft sie unter?',
  ),
  LessonSeriesEntry(
    code: 'p26',
    symbol: 'ע',
    title: 'Pfad 26 — Ayin',
    subtitle: 'Der Teufel · Tipheret → Hod · Steinbock',
    meaning: 'Ayin = Auge. Der "Teufel" zeigt selbstgewählte Ketten — '
        'das materielle Sehen, das die Freiheit vergisst. Schatten anerkennen.',
    reflection:
        'An welche selbstgemachte Kette hast du dich gewöhnt, dass du sie nicht mehr siehst?',
  ),
  LessonSeriesEntry(
    code: 'p27',
    symbol: 'פ',
    title: 'Pfad 27 — Peh',
    subtitle: 'Der Turm · Netzach → Hod · Mars',
    meaning:
        'Peh = Mund. Plötzlicher Bruch, Blitz erleuchtet falsche Strukturen. '
        'Was nicht auf Wahrheit gebaut ist, fällt.',
    reflection:
        'Welche Struktur deines Lebens wackelt — und ahnst du schon warum?',
  ),
  LessonSeriesEntry(
    code: 'p28',
    symbol: 'צ',
    title: 'Pfad 28 — Tsadi',
    subtitle: 'Der Stern · Netzach → Yesod · Wassermann',
    meaning:
        'Tsadi = Angelhaken. Sterne über der Quelle — Hoffnung nach dem Sturm, '
        'kosmische Verbindung wieder spürbar.',
    reflection:
        'Welche stille Hoffnung wagst du gerade wieder ans Licht zu lassen?',
  ),
  LessonSeriesEntry(
    code: 'p29',
    symbol: 'ק',
    title: 'Pfad 29 — Qoph',
    subtitle: 'Der Mond · Netzach → Malkuth · Fische',
    meaning: 'Qoph = Hinterkopf, Reptilienhirn. Mond zeigt das Unbewusste — '
        'Träume, Ängste, alte Programme aus den Tiefen.',
    reflection:
        'Welcher wiederkehrende Traum oder Angst will dir gerade etwas zeigen?',
  ),
  LessonSeriesEntry(
    code: 'p30',
    symbol: 'ר',
    title: 'Pfad 30 — Resh',
    subtitle: 'Die Sonne · Hod → Yesod · Sonne',
    meaning: 'Resh = Kopf, Erkenntnis. Die Sonne strahlt — Klarheit, Freude, '
        'das innere Kind tanzt im Licht der bewussten Wahrheit.',
    reflection:
        'Was bringt heute Klarheit in deine Tage — wo strahlt deine Sonne?',
  ),
  LessonSeriesEntry(
    code: 'p31',
    symbol: 'ש',
    title: 'Pfad 31 — Shin',
    subtitle: 'Gericht/Äon · Hod → Malkuth · Feuer',
    meaning: 'Shin = Zahn/Feuer, drei Flammen. Auferstehung — '
        'Erwachen zu einem höheren Selbst, Lebensphase endet, neue beginnt.',
    reflection:
        'Welcher Lebensabschnitt schließt sich gerade — wie willst du ihn würdigen?',
  ),
  LessonSeriesEntry(
    code: 'p32',
    symbol: 'ת',
    title: 'Pfad 32 — Tav',
    subtitle: 'Die Welt · Yesod → Malkuth · Saturn',
    meaning:
        'Tav = Kreuz, Siegel, Vollendung. Die Welt-Karte zeigt den Abschluss '
        'eines Zyklus — alles ist integriert, das Tanz im Ouroboros.',
    reflection:
        'Welche Reise hast du gerade vollendet, die noch keinen Namen hat?',
  ),
];
