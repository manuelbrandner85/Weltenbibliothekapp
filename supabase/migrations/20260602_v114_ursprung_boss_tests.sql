-- ======================================================================
-- MIGRATION v114 -- Ursprung Boss-Tests (Content-Seed)
-- ======================================================================
--
-- Nach dem Unlock-Bugfix (PR #219) ist der Boss-Test-Pfad in Ursprung
-- erreichbar (erscheint wenn alle 5 Module einer Branch abgeschlossen
-- sind). Es gab bisher KEINE Boss-Tests fuer die Ursprung-Branches in
-- vorhang_branch_boss_tests -> der Button zeigte nur "noch nicht
-- verfuegbar". Diese Migration seedet 5 Boss-Tests (je 8 Fragen),
-- inhaltlich am jeweiligen Branch-Stoff orientiert.
--
-- Branches: gateway_foundation, focus_levels, energy_tools,
--           patterning_manifestation, remote_viewing
--
-- Fragen-Format (gelesen von BossQuestion.fromJson):
--   { "q": <text>, "options": [..4..], "correct": <index>, "explanation": <text> }
-- pass_pct = 80, xp_reward = 300 (konsistent mit Vorhang-Boss-Tests).
--
-- Idempotent: loescht zuerst die Ursprung-Branch-Eintraege, dann Insert.
-- Beruehrt KEINE Vorhang-Boss-Tests (andere Branch-Namen).
-- ======================================================================

delete from public.vorhang_branch_boss_tests
where branch in (
  'gateway_foundation', 'focus_levels', 'energy_tools',
  'patterning_manifestation', 'remote_viewing'
);

-- ── 1) gateway_foundation ────────────────────────────────────────────
insert into public.vorhang_branch_boss_tests (branch, title, description, questions, pass_pct, xp_reward)
values (
  'gateway_foundation',
  'Boss: Gateway-Grundlagen',
  'Du hast die 5 Grundlagen-Module gemeistert. Zeig, dass du das Fundament des Gateway-Prozesses verstanden hast.',
  $q$[
    {"q": "Wie beschreibt der CIA-Gateway-Report die fundamentale Natur der Realitaet?", "options": ["Als rein materielle Substanz", "Als Hologramm aus interferierenden Schwingungen", "Als Zufallsprozess ohne Struktur", "Als Illusion ohne Energie"], "correct": 1, "explanation": "Der Report beschreibt das Universum als holografisch - alles ist interferierende Energie/Schwingung."},
    {"q": "Was bewirkt die Frequency Following Response (FFR)?", "options": ["Das Gehirn folgt einer extern angebotenen Frequenz", "Der Koerper erhoeht die Herzfrequenz", "Die Augen folgen einem Lichtpunkt", "Die Atmung stoppt kurzzeitig"], "correct": 0, "explanation": "Bei der FFR synchronisiert sich die Gehirnwellenaktivitaet mit einer von aussen angebotenen Frequenz."},
    {"q": "Wie entsteht ein binauraler Beat bei Hemi-Sync?", "options": ["Durch einen einzelnen lauten Ton", "Durch zwei leicht verschiedene Frequenzen je Ohr", "Durch Stille zwischen zwei Toenen", "Durch reine Bassfrequenzen"], "correct": 1, "explanation": "Zwei leicht verschiedene Frequenzen pro Ohr - das Gehirn erzeugt die Differenz als wahrgenommenen Beat und synchronisiert die Hemisphaeren."},
    {"q": "Welche Frequenz wird mit der Schumann-Resonanz / Erdfrequenz in Verbindung gebracht?", "options": ["Etwa 40 Hz", "Etwa 100 Hz", "Etwa 7,8 Hz", "Etwa 528 Hz"], "correct": 2, "explanation": "Die Schumann-Resonanz liegt bei rund 7,8 Hz - im Modul als Erdfrequenz und 7,5-Hz-Mysterium behandelt."},
    {"q": "Was bezeichnet der Begriff Click-Out im Gateway-Kontext?", "options": ["Das Einschlafen des Koerpers", "Ein kurzer Moment ausserhalb der gewohnten Raumzeit-Wahrnehmung", "Das Abschalten der Kopfhoerer", "Ein Fehler im Hemi-Sync-Signal"], "correct": 1, "explanation": "Click-Out beschreibt das Hinausgleiten aus der gewohnten Wahrnehmung - im Modul mit der Planck-Distanz verknuepft."},
    {"q": "Welche geometrische Form wird im Boss-Modul als Form des Universums beschrieben?", "options": ["Der Wuerfel", "Die Pyramide", "Der Torus", "Die flache Scheibe"], "correct": 2, "explanation": "Der Torus - eine sich selbst durchstroemende Donut-Form - gilt als geometrisches Grundmuster von Energie und Universum."},
    {"q": "Wer gilt als Begruender des Verfahrens, auf dem der Gateway-Prozess aufbaut?", "options": ["Robert Monroe", "Albert Einstein", "Carl Jung", "Nikola Tesla"], "correct": 0, "explanation": "Robert Monroe und das von ihm gegruendete Monroe Institute entwickelten Hemi-Sync und den Gateway-Prozess."},
    {"q": "Was ist die zentrale Idee hinter Resonanz im Gateway-Modell?", "options": ["Energie loescht sich immer aus", "Gleiche Frequenzen verstaerken und koppeln sich", "Resonanz blockiert Bewusstsein", "Nur Schall kann resonieren"], "correct": 1, "explanation": "Resonanz koppelt Systeme gleicher Frequenz und verstaerkt sie - Grundlage von Hemi-Sync und Erdfrequenz-Arbeit."}
  ]$q$::jsonb,
  80, 300
);

-- ── 2) focus_levels ──────────────────────────────────────────────────
insert into public.vorhang_branch_boss_tests (branch, title, description, questions, pass_pct, xp_reward)
values (
  'focus_levels',
  'Boss: Die Focus-Level',
  'Du hast die Bewusstseinszustaende von Focus 10 bis 49 durchschritten. Beweise deine Landkarte des Bewusstseins.',
  $q$[
    {"q": "Wie lautet die klassische Beschreibung von Focus 10?", "options": ["Koerper wach, Geist schlaeft", "Geist wach, Koerper schlaeft", "Beide schlafen", "Beide voll wach"], "correct": 1, "explanation": "Focus 10 = mind awake, body asleep - Geist wach, Koerper schlaeft."},
    {"q": "Was kennzeichnet Focus 12?", "options": ["Tiefschlaf", "Erweiterte Wahrnehmung ueber die koerperlichen Sinne hinaus", "Vollstaendige Bewusstlosigkeit", "Normaler Wachzustand"], "correct": 1, "explanation": "Focus 12 ist der Zustand erweiterter Wahrnehmung - Wave II, Threshold."},
    {"q": "Welcher Zustand wird als Kein-Zeit-Zustand beschrieben?", "options": ["Focus 10", "Focus 12", "Focus 15", "Focus 21"], "correct": 2, "explanation": "Focus 15 gilt als Zustand jenseits der Zeit (no time) - Wave III, Freedom."},
    {"q": "Was sind die Belief System Territories?", "options": ["Geografische Orte", "Bereiche ab Focus 21-27 jenseits der physischen Raumzeit", "Ein Atemmuster", "Eine Frequenz in Hz"], "correct": 1, "explanation": "Ab Focus 21-27 erschliessen sich laut Modell die Belief System Territories jenseits der Raumzeit."},
    {"q": "Welche Wave traegt den Namen Discovery?", "options": ["Wave I", "Wave III", "Wave V", "Wave VI"], "correct": 0, "explanation": "Wave I - Discovery ist der Einstieg, in dem Focus 10 erlernt wird."},
    {"q": "Was beschreibt der Begriff I-There im Boss-Modul (Focus 34-49)?", "options": ["Ein einzelnes Ego", "Eine Versammlung/Cluster des erweiterten Selbst", "Ein Koerperteil", "Ein Hemi-Sync-Signal"], "correct": 1, "explanation": "I-There bezeichnet die Versammlung des erweiterten Selbst - die ultimative Reise in Focus 34-49."},
    {"q": "In welcher Reihenfolge werden die Focus-Level typischerweise erlernt?", "options": ["15, 12, 10, 21", "10, 12, 15, 21", "21, 15, 12, 10", "12, 10, 21, 15"], "correct": 1, "explanation": "Die Progression verlaeuft aufsteigend: Focus 10, dann 12, 15 und 21+."},
    {"q": "Was ist der praktische Sinn der Focus-Level-Landkarte?", "options": ["Reine Unterhaltung", "Bewusstseinszustaende gezielt ansteuern und stabilisieren", "Den Schlaf zu verhindern", "Die Herzfrequenz zu messen"], "correct": 1, "explanation": "Die Level dienen als reproduzierbare Landkarte, um bestimmte Bewusstseinszustaende gezielt zu erreichen."}
  ]$q$::jsonb,
  80, 300
);

-- ── 3) energy_tools ──────────────────────────────────────────────────
insert into public.vorhang_branch_boss_tests (branch, title, description, questions, pass_pct, xp_reward)
values (
  'energy_tools',
  'Boss: Die Energie-Werkzeuge',
  'Du beherrschst die Gateway-Energiewerkzeuge. Zeig, dass du sie sicher anwenden kannst.',
  $q$[
    {"q": "Wozu dient die Energy Conversion Box?", "options": ["Zum Aufladen des Smartphones", "Zum Ablegen von Sorgen und Ablenkungen vor der Uebung", "Zum Messen der Herzfrequenz", "Zum Speichern von Toenen"], "correct": 1, "explanation": "Die Energy Conversion Box ist das erste Werkzeug: man legt mental Sorgen/Ablenkungen ab, um frei zu werden."},
    {"q": "Was geschieht beim Resonant Tuning?", "options": ["Energie wird eingeatmet, im Koerper gekreist und ausgeatmet", "Man haelt den Atem moeglichst lange an", "Man spricht laut Mantras", "Man zaehlt rueckwaerts von 100"], "correct": 0, "explanation": "Resonant Tuning: Vibrationsenergie einatmen, im Koerper kreisen lassen und wieder ausatmen."},
    {"q": "Wofuer steht die Abkuerzung REBAL?", "options": ["Rapid Energy Balance", "Resonant Energy Balloon", "Radial Energy Band", "Reflective Body Alignment"], "correct": 1, "explanation": "REBAL = Resonant Energy Balloon, ein persoenlicher Energie-Schutzschild."},
    {"q": "Welche Funktion hat der REBAL primaer?", "options": ["Schutz und Abgrenzung des eigenen Energiefelds", "Erhoehung der Koerpertemperatur", "Verbesserung des Hoervermoegens", "Beschleunigung des Herzschlags"], "correct": 0, "explanation": "Der REBAL bildet einen schuetzenden Energieballon um die Person."},
    {"q": "Wie wird das Energy Bar Tool beschrieben?", "options": ["Als aeusseres Messgeraet", "Als innerer Zauberstab zum Lenken/Heilen von Energie", "Als Atemtechnik", "Als Frequenztabelle"], "correct": 1, "explanation": "Das Energy Bar Tool ist der innere Zauberstab, mit dem Energie gezielt gelenkt wird - ergaenzt durch die Living Body Map."},
    {"q": "Was ist die Living Body Map?", "options": ["Eine geografische Karte", "Eine innere Heilkarte des Koerpers", "Ein Hemi-Sync-Track", "Ein Belief System Territory"], "correct": 1, "explanation": "Die Living Body Map ist eine innere Heilkarte, auf der Energie zu Koerperbereichen gefuehrt wird."},
    {"q": "Worum geht es beim Color Breathing (Boss-Modul)?", "options": ["Farben werden zur Heilung in den Koerper geatmet/gelenkt", "Man betrachtet bunte Bilder", "Man malt waehrend der Meditation", "Man zaehlt Farben im Raum"], "correct": 0, "explanation": "Color Breathing nutzt Farben, die mental eingeatmet und zur Heilung/Energielenkung in den Koerper gefuehrt werden."},
    {"q": "Welches Werkzeug wird typischerweise zuerst eingesetzt?", "options": ["Color Breathing", "REBAL", "Energy Conversion Box", "Energy Bar Tool"], "correct": 2, "explanation": "Die Energy Conversion Box ist das erste Gateway-Werkzeug - sie schafft die innere Voraussetzung fuer alles Weitere."}
  ]$q$::jsonb,
  80, 300
);

-- ── 4) patterning_manifestation ──────────────────────────────────────
insert into public.vorhang_branch_boss_tests (branch, title, description, questions, pass_pct, xp_reward)
values (
  'patterning_manifestation',
  'Boss: Patterning & Manifestation',
  'Du kennst die CIA-Manifestationstechnik in Tiefe. Beweise deine Meisterschaft im Patterning.',
  $q$[
    {"q": "Ueber welchen Zeitraum laeuft das One-Month Patterning?", "options": ["Eine Woche", "Einen Monat", "Ein Jahr", "Einen Tag"], "correct": 1, "explanation": "Das One-Month Patterning ist als einmonatige Manifestationstechnik angelegt."},
    {"q": "Was thematisiert das Modul Seite 25?", "options": ["Eine wiedergefundene, zuvor fehlende Seite des Materials", "Die 25. Focus-Stufe", "25 Energiewerkzeuge", "Eine Frequenz von 25 Hz"], "correct": 0, "explanation": "Seite 25 behandelt die fehlende, wiedergefundene Seite - das fehlende Puzzlestueck."},
    {"q": "Wie laesst sich Reality Scripting einordnen?", "options": ["Als moderne Erweiterung des CIA-Patterning", "Als aelteste Form der Meditation", "Als Atemtechnik", "Als Remote-Viewing-Stufe"], "correct": 0, "explanation": "Reality Scripting (Gedanken-Architektur) ist die moderne Erweiterung des CIA-Patterning."},
    {"q": "Worum geht es bei Release & Recharge?", "options": ["Akku des Geraets laden", "Limitierungen schichtweise aufloesen bis zur reinen Energie", "Neue Sorgen aufbauen", "Toene lauter stellen"], "correct": 1, "explanation": "Release & Recharge loest Limitierungen Schicht fuer Schicht auf, bis reine Energie bleibt."},
    {"q": "Aus welchem Kontext stammt die Patterning-Technik laut Modul?", "options": ["Aus dem CIA-/Gateway-Umfeld", "Aus dem Mittelalter", "Aus der Boersenwelt", "Aus der Sportmedizin"], "correct": 0, "explanation": "Das Patterning wird als CIA-Manifestationstechnik im Gateway-Kontext vermittelt."},
    {"q": "Wie viele Regeln umfasst das klassische Patterning laut Modul?", "options": ["3 Regeln", "10 Regeln", "21 Regeln", "49 Regeln"], "correct": 1, "explanation": "Das Modul nennt die 10 Regeln des Patterning."},
    {"q": "Was ist das Ziel des Boss-Moduls Meisterklasse der Manifestation?", "options": ["Die Synthese aller zuvor gelernten Techniken", "Das Vergessen aller Techniken", "Nur Atemuebungen", "Reine Theorie ohne Praxis"], "correct": 0, "explanation": "Die Meisterklasse fuehrt alle Techniken der Branch zu einer Synthese zusammen."},
    {"q": "Welche Haltung gilt im Patterning als foerderlich?", "options": ["Zweifel und Anspannung", "Klare Absicht verbunden mit Loslassen", "Staendiges Kontrollieren des Ergebnisses", "Gleichgueltigkeit"], "correct": 1, "explanation": "Klare Absicht plus Loslassen (statt Klammern ans Ergebnis) ist der Kern - daher auch Release & Recharge."}
  ]$q$::jsonb,
  80, 300
);

-- ── 5) remote_viewing ────────────────────────────────────────────────
insert into public.vorhang_branch_boss_tests (branch, title, description, questions, pass_pct, xp_reward)
values (
  'remote_viewing',
  'Boss: Remote Viewing',
  'Von Stargate bis zur sechsten CRV-Stufe - zeig, dass du das Controlled Remote Viewing verstanden hast.',
  $q$[
    {"q": "Was war Project Stargate?", "options": ["Ein NASA-Raketenprogramm", "Ein langjaehriges CIA-/US-Psi-Forschungsprogramm zum Remote Viewing", "Ein Filmprojekt", "Ein Hemi-Sync-Track"], "correct": 1, "explanation": "Project Stargate (aus SCANATE u.a. hervorgegangen) war ein ueber rund 23 Jahre laufendes US-Programm zur Psi-/Remote-Viewing-Forschung."},
    {"q": "Wofuer steht die Abkuerzung CRV?", "options": ["Controlled Remote Viewing", "Central Recording Vault", "Coordinated Radar Vision", "Cognitive Reality View"], "correct": 0, "explanation": "CRV = Controlled Remote Viewing, das von Ingo Swann mitentwickelte strukturierte Verfahren."},
    {"q": "Was geschieht in CRV Stage 1?", "options": ["Detaillierte Skizze", "Das Ideogramm - eine spontane Stiftbewegung als erster Eindruck", "Emotionale Analyse", "Mentales Betreten des Ziels"], "correct": 1, "explanation": "Stage 1 erzeugt das Ideogramm - eine reflexhafte Stiftbewegung als erster Kontakt mit dem Ziel."},
    {"q": "Welche Daten stehen in CRV Stage 2 im Vordergrund?", "options": ["Sensorische Eindruecke (Texturen, Temperaturen, Geraeusche)", "Geldbetraege", "Namen von Personen", "Exakte Koordinaten"], "correct": 0, "explanation": "Stage 2 erfasst sensorische Basisdaten wie Texturen, Temperaturen und Geraeusche."},
    {"q": "Was kommt in den Stages 3 und 4 hinzu?", "options": ["Skizze (raeumlich) und emotionale/aesthetische Eindruecke", "Nur Zahlen", "Das Ideogramm", "Die Abschlussbewertung"], "correct": 0, "explanation": "Stage 3 bringt die raeumliche Skizze, Stage 4 emotionale und aesthetische Daten (AI - aesthetic impact)."},
    {"q": "Was kennzeichnet die Stages 5 und 6?", "options": ["Abbruch der Sitzung", "Exploration und detailliertes Modellieren des Ziels", "Reines Aufwaermen", "Wiederholung von Stage 1"], "correct": 1, "explanation": "Stage 5-6 vertiefen mit Exploration und dem Erstellen eines detaillierten (auch raeumlichen) Modells."},
    {"q": "Wer gilt als zentraler Entwickler des CRV-Protokolls?", "options": ["Ingo Swann", "Robert Monroe", "Albert Einstein", "Wayne McDonnell"], "correct": 0, "explanation": "Ingo Swann entwickelte das Controlled Remote Viewing massgeblich mit (am SRI)."},
    {"q": "Welche Namen werden im Boss-Modul als Meister-Viewer genannt?", "options": ["Swann, Price, McMoneagle", "Tesla, Edison, Bohr", "Jung, Freud, Adler", "Monroe, Bentov, Schumann"], "correct": 0, "explanation": "Die Meisterklasse nennt Ingo Swann, Pat Price und Joe McMoneagle als herausragende Remote Viewer."}
  ]$q$::jsonb,
  80, 300
);
