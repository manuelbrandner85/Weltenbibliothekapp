-- ============================================================
-- v23b: Seed Ahnen-Rituale (8 Rituale aus verschiedenen Traditionen)
-- ============================================================

INSERT INTO public.ancestral_rituals
  (slug, title, tradition, emoji, description, steps, materials, duration_minutes, best_time, sort_order)
VALUES

('ahnen-altar-einrichten',
 'Ahnen-Altar einrichten',
 'allgemein', '🕯️',
 'Ein physischer Ort der Verbindung zu deinen Ahnen. Ein Altar ist weder Religion noch Esoterik – er ist ein Akt der Erinnerung, der Anwesenheit und der Dankbarkeit.',
 ARRAY[
   'Wähle einen ruhigen Platz in deiner Wohnung – ein Regal, eine Kommode, eine Ecke.',
   'Reinige den Platz physisch (wischen) und energetisch (z. B. mit Salbei, Weihrauch, Klang, Gebet).',
   'Stelle Fotos deiner verstorbenen Ahnen auf (nur verstorbene – keine lebenden Personen).',
   'Füge Gegenstände hinzu, die sie erinnern: ein Schmuckstück, ein Brief, ein Werkzeug, ihre Lieblings-Blume.',
   'Eine Kerze darf nicht fehlen – sie ist das Licht der Erinnerung.',
   'Frisches Wasser in einem Glas gibt den Ahnen etwas zu trinken. Erneuere es regelmäßig.',
   'Sprich beim Einrichten laut oder leise: "Liebe Ahnen, ihr seid willkommen."'
 ],
 ARRAY['Kerze','Foto der Ahnen','Glas mit Wasser','Optional: Salbei/Weihrauch','Optional: Blumen'],
 45, 'bei Neumond oder zu Allerheiligen',
 10),

('totentor-november',
 'Totentor-Öffnung im November',
 'keltisch', '🍂',
 'Im alten keltischen Jahreskreis (Samhain) öffnen sich Ende Oktober/Anfang November die Tore zur Anderswelt. Diese Nächte sind besonders gut geeignet, um Kontakt zu den Ahnen aufzunehmen.',
 ARRAY[
   'Plane einen stillen Abend zwischen 31.10. und 2.11.',
   'Kleide dich in Dunkles oder Erdtöne.',
   'Iss ein einfaches Mahl, das deine Ahnen gekannt hätten (z. B. Brot, Suppe).',
   'Lasse beim Mahl einen leeren Teller für die Ahnen stehen.',
   'Entzünde nach dem Mahl Kerzen für jede/n Ahnin/Ahn, den/die du ehren willst.',
   'Sprich laut ihre Namen. Erzähle eine Geschichte über sie.',
   'Sitze in Stille. Höre zu, was (innerlich) kommen mag.',
   'Zum Abschluss: bedanke dich. Lösche die Kerzen nicht aus – lass sie sicher herunterbrennen.'
 ],
 ARRAY['Kerzen (pro Ahne eine)','Einfaches Mahl','Leerer Teller','Optional: Foto, Erinnerungsstück'],
 90, '31. Oktober – 2. November (Samhain)',
 20),

('ahnenreise-trommel',
 'Schamanische Ahnenreise mit Trommel',
 'schamanisch', '🥁',
 'Eine geführte innere Reise zu einer Ahnin/einem Ahn über einen Trommelrhythmus. Nicht für Anfänger ohne Vorbereitung – besser mit erfahrenem Raumhalter.',
 ARRAY[
   'Suche dir einen sicheren Ort. Niemand sollte dich stören.',
   'Lege dich hin, schließe die Augen.',
   'Setze die Intention: "Ich möchte die/den Ahn_in treffen, die/der Heilung für mich hat."',
   'Starte eine monotone Trommel-Aufnahme (4–7 Schläge/Sekunde, 20–30 Minuten).',
   'Stelle dir einen Eingang zur Unterwelt vor (Höhle, Wurzel, Baumstamm).',
   'Bitte darum, dass die/der passende Ahn_in dich trifft. Vertraue, was kommt.',
   'Höre, sieh, frage. Bleibe offen für Bilder, Worte, Gefühle.',
   'Wenn der Rückruf-Rhythmus ertönt, bedanke dich und kehre denselben Weg zurück.',
   'Schreibe direkt nach der Reise auf, was du erlebt hast.'
 ],
 ARRAY['Decke/Matte','Kopfhörer','Trommel-Aufnahme (z. B. Michael Harner, Sandra Ingerman)','Journal','Optional: Rassel, geweihte Feder'],
 35, 'abends oder bei Vollmond',
 30),

('familienaufstellung-stellvertreter',
 'Familien-Aufstellung im kleinen Rahmen',
 'familienaufstellung', '👥',
 'Eine vereinfachte Form der Aufstellungsarbeit nach Hellinger, die du zu zweit oder zu dritt machen kannst. Achtsam, nicht als Therapie-Ersatz.',
 ARRAY[
   'Wähle ein Thema: ein Muster, eine Beziehung, eine ungelöste Frage zu einem Ahnen.',
   'Nutze Bodenanker (z. B. Kissen, Blätter) für Mutter, Vater, Großeltern und dich.',
   'Stelle sie im Raum so auf, wie es sich für dich gerade stimmig anfühlt.',
   'Schau, wie die Positionen zueinander stehen. Wer ist wo? Wer fehlt?',
   'Stehe auf die Position jedes Elternteils/Großelternteils. Spüre kurz hinein.',
   'Führe innere Dialoge: "Ich sehe dich. Ich ehre dich. Ich gebe dir zurück, was dir gehört."',
   'Schließe mit einer heilenden Position (z. B. stehst du hinter den Eltern, nicht dazwischen).',
   'Räume bewusst auf. Danke dem Raum.'
 ],
 ARRAY['4–7 Bodenanker','Ruhiger Raum','Journal','Optional: Kerze'],
 60, 'wenn ein familiäres Thema drängt',
 40),

('wasserritus-versoehnung',
 'Wasserritual der Versöhnung',
 'allgemein', '💧',
 'Wasser trägt das Unausgesprochene. Dieses Ritual hilft, einer/einem Ahn_in zu vergeben oder um Vergebung zu bitten.',
 ARRAY[
   'Fülle eine Schale mit frischem Wasser.',
   'Setze dich ruhig davor, atme 10 Atemzüge tief.',
   'Sprich (innerlich oder laut) den Namen der/des Ahn_in.',
   'Erzähle, was zwischen euch stand. Kein Filter, keine Schönfärberei.',
   'Bitte um Vergebung oder biete sie an.',
   'Halte die Hand über das Wasser und spüre, was fließt.',
   'Gieße das Wasser anschließend bewusst in die Erde (Pflanze, Garten, Park).',
   'Sprich: "Fließe zurück zum Ursprung. Wir sind frei."'
 ],
 ARRAY['Glas-Schale mit Wasser','Pflanze oder Erde','Optional: Kerze'],
 25, 'bei abnehmendem Mond',
 50),

('matriarchenlinie',
 'Matriarchinnen-Linie aktivieren',
 'germanisch', '🌺',
 'Ehre die Frauenreihe, aus der du kommst: Mutter, Großmutter, Urgroßmutter, Ururgroßmutter. Besonders kraftvoll für Frauen, aber offen für alle.',
 ARRAY[
   'Lege 4–7 Blumen in einer Reihe vor dir aus (eine pro Generation).',
   'Lege eine zusätzliche Blume für dich selbst an den Anfang.',
   'Sprich die Namen, wenn du sie kennst. Wenn nicht: "die Mutter meiner Mutter…", "ihre Mutter…".',
   'Lege bei jedem Namen deine Hand auf die entsprechende Blume.',
   'Sage laut: "Ich danke dir. Ich nehme das Gute, das du mir gegeben hast. Das andere gebe ich zurück."',
   'Schließe, indem du die Blumen aneinanderlegst, sodass sie sich berühren.',
   'Bewahre eine Blume eine Woche lang in einem Glas auf deinem Ahnenaltar.'
 ],
 ARRAY['4–7 Blumen','Eine besondere Blume für dich selbst','Glas Wasser','Optional: Fotos'],
 30, 'am 21. Dezember (Wintersonnenwende) oder am 1. Mai',
 60),

('brief-an-einen-ahnen',
 'Brief an eine Ahnin / einen Ahnen',
 'allgemein', '✉️',
 'Ein persönlicher, handgeschriebener Brief ist einer der tiefsten Zugänge zur Ahnenarbeit. Nicht zum Abschicken – für die Verbindung.',
 ARRAY[
   'Wähle eine/n verstorbene/n Ahn_in, mit der/dem etwas offen ist.',
   'Nimm dir Papier und Stift. Kein Computer.',
   'Beginne: "Liebe/r [Name],"',
   'Schreibe alles. Fragen. Wut. Dankbarkeit. Unausgesprochenes.',
   'Erzähle auch, was aus deinem Leben gut läuft.',
   'Schließe mit: "Ich lasse dich ruhen. Ich gehe meinen Weg."',
   'Entscheide: Verbrennen (Loslassen), Vergraben (zurückgeben an die Erde), oder bewahren.'
 ],
 ARRAY['Papier','Stift','Optional: Umschlag','Optional: feuerfeste Schale'],
 40, 'wann immer ein Thema hochkommt',
 70),

('ahnenessen',
 'Das Ahnen-Essen',
 'ostasiatisch', '🍚',
 'In vielen asiatischen Traditionen wird den Ahnen regelmäßig ein kleines Mahl serviert – als Geste der Dankbarkeit und Verbundenheit.',
 ARRAY[
   'Koche ein einfaches, ehrliches Gericht (Reis, Suppe, Brot – je nach Kultur deiner Ahnen).',
   'Stelle einen kleinen Teller mit einer Portion auf deinen Altar oder auf den Esstisch.',
   'Stelle auch eine kleine Tasse Tee oder Wasser dazu.',
   'Verbeuge dich leicht oder senke den Kopf.',
   'Sprich: "Ich danke euch für alles, was durch euch zu mir kam. Nehmt an diesem Mahl teil."',
   'Iss deine Portion langsam und bewusst.',
   'Nach 1 Stunde: kippe die Ahnen-Portion in die Erde (draußen) oder kompostiere sie respektvoll.'
 ],
 ARRAY['Einfaches Mahl','Kleiner Teller','Tasse Tee oder Wasser'],
 20, 'zu Jahrestagen, Neumond, Vollmond',
 80)

ON CONFLICT (slug) DO UPDATE SET
  title            = EXCLUDED.title,
  tradition        = EXCLUDED.tradition,
  emoji            = EXCLUDED.emoji,
  description      = EXCLUDED.description,
  steps            = EXCLUDED.steps,
  materials        = EXCLUDED.materials,
  duration_minutes = EXCLUDED.duration_minutes,
  best_time        = EXCLUDED.best_time,
  sort_order       = EXCLUDED.sort_order;
