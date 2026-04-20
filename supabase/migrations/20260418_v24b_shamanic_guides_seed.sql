-- ============================================================
-- v24b: Seed Schamanische Reise-Leitfäden (6 Guides)
-- ============================================================

INSERT INTO public.shamanic_journey_guides
  (slug, title, world, emoji, description, steps, sample_intentions,
   duration_minutes, preparation, safety_notes, sort_order)
VALUES

('krafttier-finden',
 'Krafttier finden (Unterwelt)',
 'lower', '🐾',
 'Die klassische Reise zum Finden deines Krafttieres. In der Unterwelt, die kein dunkler Ort ist, sondern die Ebene der Natur und der Urinstinkte, begegnen wir Tier-Geistführern.',
 ARRAY[
   'Lege dich an einem ungestörten Ort hin, decke dich zu.',
   'Starte eine monotone Trommel-Aufnahme (4–7 Schläge/Sek, 20 Min).',
   'Stelle dir einen natürlichen Eingang zur Unterwelt vor: Höhle, Wurzelloch, See.',
   'Gehe hindurch, immer tiefer. Vertraue deinen inneren Bildern.',
   'Bitte darum: "Zeige dich, mein Krafttier."',
   'Das erste Tier, das sich dir dreimal zeigt, ist dein Krafttier.',
   'Frage: "Was möchtest du mir sagen? Was ist deine Gabe für mich?"',
   'Wenn der Rückruf kommt: bedanke dich, kehre denselben Weg zurück.',
   'Schreibe sofort auf, was du erlebt hast.'
 ],
 ARRAY['Wer ist mein Krafttier?', 'Welche Kraft brauche ich jetzt?'],
 25,
 'Trommel-Aufnahme vorbereiten, Raum abdunkeln, Journal bereit legen.',
 'Nur in einem nüchternen Zustand. Wenn starke Angst aufkommt, öffne die Augen und kehre sofort zurück.',
 10),

('antwort-auf-frage',
 'Reise zur Antwort auf eine Frage',
 'lower', '❓',
 'Eine gezielte Reise, um Klarheit zu einer konkreten Lebensfrage zu erhalten. Funktioniert am besten mit offenen Fragen (Was? Wie? Warum?).',
 ARRAY[
   'Formuliere deine Frage präzise und aufschreiben.',
   'Lies sie dreimal langsam laut vor.',
   'Starte die Trommel, beginne die Reise in die Unterwelt.',
   'Gehe zu deinem Krafttier oder einem vertrauten Ort.',
   'Stelle deine Frage und warte, was kommt. Bilder, Symbole, Worte.',
   'Hinterfrage nicht – nimm an.',
   'Prüfe durch eine Gegenfrage: "Ist das die Antwort, die ich hören soll?"',
   'Bedanke dich. Kehre zurück beim Rückruf.',
   'Notiere: die Antwort UND wie sie kam.'
 ],
 ARRAY['Soll ich diesen Schritt gehen?', 'Was brauche ich gerade?', 'Wie gehe ich mit X um?'],
 20,
 'Frage schriftlich formulieren, Journal + Stift bereit.',
 'Nutze das Erhaltene nicht für Entscheidungen, die andere betreffen, ohne sie einzubeziehen.',
 20),

('oberwelt-lehrer',
 'Reise zum Geistführer (Oberwelt)',
 'upper', '☁️',
 'Die Oberwelt ist die Ebene der Engel, Weisen, Ahnen-Guides und Lehrer. Hier begegnen wir Wesen, die uns auf dem Weg begleiten.',
 ARRAY[
   'Lege dich hin, starte die Trommel.',
   'Stelle dir einen Aufstieg vor: Berg, Baum, Leiter, Regenbogen, Spirale.',
   'Steige immer höher, durch Wolken oder Sternenhimmel.',
   'Trittst du durch eine Schicht (Membran, Licht, Nebel), bist du in der Oberwelt.',
   'Bitte: "Mein Lehrer, mein Geistführer – zeige dich."',
   'Begegne, was kommt. Frage nach Name, Aufgabe, Botschaft.',
   'Lausche. Dauere den Moment aus.',
   'Bedanke dich. Kehre zurück auf demselben Weg.',
   'Schreibe sofort auf.'
 ],
 ARRAY['Wer ist mein Geistführer?', 'Was ist mein nächster Lernschritt?'],
 25,
 'Aufstiegs-Bild vorbereiten. Kopfhörer empfohlen.',
 'Wenn die Begegnung zu intensiv wird, öffne die Augen. Kein Wesen hat das Recht, dich zu ängstigen.',
 30),

('ahnen-reise',
 'Reise zu einer Ahnin / einem Ahnen',
 'any', '🕯️',
 'Diese Reise verbindet dich mit einer bestimmten Ahnin oder einem Ahnen, deren Unterstützung oder Vergebung du suchst. Kombiniert schamanische Reise mit Ahnenarbeit.',
 ARRAY[
   'Stelle ein Foto oder Erinnerungsstück der/des Ahn_in neben dich.',
   'Setze klare Intention: "Ich möchte [Name] treffen, um…"',
   'Starte die Trommel. Reise in die mittlere oder obere Welt.',
   'Rufe innerlich den Namen. Nicht alle Ahnen kommen – das ist okay.',
   'Wenn sie/er kommt: spüre die Präsenz, ohne zu bewerten.',
   'Sprich aus, was gesagt werden will: Dank, Bitte, Vergebung.',
   'Höre, was zurückkommt.',
   'Verabschiede dich liebevoll.',
   'Kehre zurück. Ehre die Begegnung durch eine Handlung im Alltag.'
 ],
 ARRAY['Ich möchte meine Großmutter verstehen.', 'Ich möchte meinem Vater vergeben.'],
 30,
 'Foto/Gegenstand bereitlegen. Ruhigen Raum schaffen.',
 'Wenn du unverarbeitetes Trauma mit dieser Person hast, mache die Reise nicht alleine. Suche einen Raumhalter.',
 40),

('heilung-fuer-koerperteil',
 'Heil-Reise für einen Körperteil',
 'middle', '💚',
 'Eine Reise in die mittlere Welt – die Welt unseres Körpers und der Erde – zur Heilung einer körperlichen Beschwerde. Komplementär zur medizinischen Behandlung, kein Ersatz.',
 ARRAY[
   'Identifiziere die Körperstelle, die Heilung braucht.',
   'Lege die Hand darauf, während die Trommel startet.',
   'Reise in deinen Körper – als würdest du hinein-schrumpfen.',
   'Komme an der betroffenen Stelle an. Wie sieht es aus? Farbe? Form?',
   'Bitte dein Krafttier oder einen inneren Helfer um Unterstützung.',
   'Lasse heilende Energie fließen. Visualisiere die Wunde schließend, die Zelle leuchtend.',
   'Sprich mit dem Körperteil: "Was brauchst du von mir?"',
   'Danke ihm für die Botschaft.',
   'Kehre zurück, behalte die Intention über den Tag.'
 ],
 ARRAY['Rücken-Heilung', 'Kopfschmerz verstehen', 'Bauch beruhigen'],
 20,
 'Vorher den Körperteil konkret lokalisieren. Warm eingepackt sein.',
 'Schamanische Reise ersetzt keine Medizin. Bei akuten Symptomen immer Arzt konsultieren.',
 50),

('stille-reise-atem',
 'Stille Reise mit dem Atem',
 'any', '🌬️',
 'Eine Reise ohne Trommel, nur mit dem eigenen Atem als Transportmittel. Sanft, kraftvoll, jederzeit überall machbar.',
 ARRAY[
   'Setze dich bequem, Rücken gerade. Augen geschlossen.',
   'Atme 10 tiefe Atemzüge: 4 Sek ein, 6 Sek aus.',
   'Stell dir vor, mit jedem Ausatmen sinkst du tiefer hinein – in dich.',
   'Frage: "Was zeigt sich heute?" Bleibe offen.',
   'Folge den Bildern, den Empfindungen.',
   'Wenn du möchtest, stelle eine konkrete Frage.',
   'Nach 15 Minuten: atme wieder aktiver, spüre die Hände.',
   'Öffne sanft die Augen.',
   'Notiere 3 Sätze zu dem, was kam.'
 ],
 ARRAY['Was braucht meine Seele heute?', 'Was darf ich loslassen?'],
 15,
 'Timer stellen. Ruhiger Ort ohne Störungen.',
 'Für alle geeignet, auch ohne Vorerfahrung. Wenn Schwindel auftritt: kürzere Atemzüge.',
 60)

ON CONFLICT (slug) DO UPDATE SET
  title             = EXCLUDED.title,
  world             = EXCLUDED.world,
  emoji             = EXCLUDED.emoji,
  description       = EXCLUDED.description,
  steps             = EXCLUDED.steps,
  sample_intentions = EXCLUDED.sample_intentions,
  duration_minutes  = EXCLUDED.duration_minutes,
  preparation       = EXCLUDED.preparation,
  safety_notes      = EXCLUDED.safety_notes,
  sort_order        = EXCLUDED.sort_order;
