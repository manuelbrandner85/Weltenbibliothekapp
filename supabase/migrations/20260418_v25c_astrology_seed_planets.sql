-- ============================================================
-- v25c: Seed 10 Planeten / Himmelskörper
-- ============================================================

INSERT INTO public.astrology_meanings
  (category, key, title, emoji, keywords, short_text, deep_text, shadow_text, sort_order)
VALUES

('planet','sun','Sonne','☉',
 ARRAY['Selbst','Wille','Vitalität','Identität'],
 'Dein Zentrum. Wer du bist, wenn du strahlst.',
 'Die Sonne zeigt, wofür du leuchten sollst. Dein Zeichen der Sonne verrät den Weg deines Herzens – nicht wer du oberflächlich bist, sondern wem du dich im Leben annäherst. Hier zündet dein Feuer.',
 'Schatten: Ego-Blockade, Fremd-Identität, Strahlen aus Eitelkeit. Übung: bewusst ausatmen, dir Raum nehmen.',
 1),

('planet','moon','Mond','☽',
 ARRAY['Gefühl','Nahrung','Heimat','Gedächtnis'],
 'Deine innere Welt. Was dich berührt, nährt, prägt.',
 'Der Mond spricht, was du fühlst, oft unbewusst. Sein Zeichen verrät, wie du Nähe empfängst und gibst, was deine Seele nährt, welche Kindheits-Muster in dir weiterwirken.',
 'Schatten: Launen, Rückzug, emotionale Abhängigkeit. Übung: Gefühle benennen, bevor sie dich ergreifen.',
 2),

('planet','mercury','Merkur','☿',
 ARRAY['Denken','Sprache','Lernen','Austausch'],
 'Dein Geist in Bewegung. Wie du denkst, sprichst, fragst.',
 'Merkur regiert das Wie deines Kommunizierens und Lernens. Sein Zeichen zeigt, ob du schnell/langsam, visuell/verbal, konkret/abstrakt denkst. Hier liegt dein Werkzeug zur Welt.',
 'Schatten: Zynismus, Wort-Flucht, Besserwisserei. Übung: zuerst zuhören, dann antworten.',
 3),

('planet','venus','Venus','♀',
 ARRAY['Liebe','Schönheit','Wert','Anziehung'],
 'Was du liebst, wertschätzt, anziehst.',
 'Venus zeigt, was dir Freude macht und wer/was dich anzieht. Ihr Zeichen offenbart deine Beziehungs-Sprache – ob romantisch, praktisch, frei, treu. Auch: wie du Geld und Schönheit begegnest.',
 'Schatten: Selbst-Verkauf, Eifersucht, Genuss-Sucht. Übung: alleine genießen lernen.',
 4),

('planet','mars','Mars','♂',
 ARRAY['Wille','Aktion','Begehren','Konflikt'],
 'Deine Kraft, zu handeln. Dein Kampfgeist, dein Eros.',
 'Mars ist der Motor. Sein Zeichen verrät, wie du handelst, wie du Wut ausdrückst, was dich sexuell aufweckt. Er ist die Kraft, die Ideen in die Welt setzt.',
 'Schatten: Aggression, Rastlosigkeit, sexueller Missbrauch von Energie. Übung: bewegen statt explodieren.',
 5),

('planet','jupiter','Jupiter','♃',
 ARRAY['Weite','Sinn','Wachstum','Glaube'],
 'Dein Horizont. Wo du wächst und vertraust.',
 'Jupiter erweitert. Sein Zeichen zeigt, wo du Glück ziehst, was du studieren willst, welche Philosophie dich trägt. Er bringt Überfluss – wenn du Raum lässt.',
 'Schatten: Übertreibung, Dogma, Maßlosigkeit. Übung: "genug" als Mantra.',
 6),

('planet','saturn','Saturn','♄',
 ARRAY['Struktur','Grenze','Verantwortung','Zeit'],
 'Deine Schule. Was dich reift, bis du Meister wirst.',
 'Saturn ist der Lehrer. Sein Zeichen offenbart, wo du dich zusammenreißt, wo du Struktur brauchst, wo Früchte erst nach Disziplin reifen. Sein Transit nach 28/29 Jahren (Saturn-Return) krönt dein Erwachsenwerden.',
 'Schatten: Angst, Härte, Depression. Übung: Grenze heilig halten, aber nicht erstarren.',
 7),

('planet','uranus','Uranus','♅',
 ARRAY['Freiheit','Revolution','Blitz','Anders'],
 'Dein Durchbruch. Wo du anders bist, wo du erschütterst.',
 'Uranus bringt das Unerwartete. Sein Zeichen zeigt, wo du originell, rebellisch, genial bist. Er befreit dich aus eingefahrenen Spurrillen – oft schmerzhaft.',
 'Schatten: Chaos, Abbrüche, Entfremdung. Übung: Wandel gestalten, statt ihm zu unterliegen.',
 8),

('planet','neptune','Neptun','♆',
 ARRAY['Traum','Auflösung','Mitgefühl','Mystik'],
 'Dein Nebel. Wo du dich auflöst, träumst, heilst.',
 'Neptun ist der Ozean. Sein Zeichen zeigt, wo du Grenzen auflösen kannst, wo Kunst/Spiritualität/Hingabe wirken. Hier kommt das Unsagbare ins Sein.',
 'Schatten: Selbsttäuschung, Flucht, Sucht. Übung: realen Schritt machen, bevor du dich verlierst.',
 9),

('planet','pluto','Pluto','♇',
 ARRAY['Wandlung','Macht','Tiefe','Geburt'],
 'Deine Unterwelt. Wo alles Alte stirbt, damit Neues werden kann.',
 'Pluto regiert das radikal Unabänderliche: Tod, Macht, Sexualität, Wiedergeburt. Sein Zeichen zeigt, wo in dir ein Vulkan schlummert – und wo du ihn nicht länger verleugnen sollst.',
 'Schatten: Manipulation, Rache, Selbst-Zerstörung. Übung: zulassen, dass etwas stirbt.',
 10)

ON CONFLICT (category, key) DO UPDATE SET
  title       = EXCLUDED.title,
  emoji       = EXCLUDED.emoji,
  keywords    = EXCLUDED.keywords,
  short_text  = EXCLUDED.short_text,
  deep_text   = EXCLUDED.deep_text,
  shadow_text = EXCLUDED.shadow_text,
  sort_order  = EXCLUDED.sort_order;
