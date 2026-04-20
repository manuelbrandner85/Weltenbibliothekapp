-- ============================================================
-- v25b: Seed 12 Tierkreiszeichen
-- ============================================================

INSERT INTO public.astrology_meanings
  (category, key, title, emoji, keywords, short_text, deep_text, shadow_text, sort_order)
VALUES

('sign','0','Widder','♈',
 ARRAY['Initiative','Mut','Anfang','Impuls'],
 'Der Pionier. Feuer, kardinal. Du gehst voraus – der erste Funke im Rad des Jahres.',
 'Als Widder bist du die Urkraft des Anfangs. Mars-Energie pulsiert in dir. Du brauchst Bewegung, Herausforderung, neue Horizonte. Deine Gabe: den ersten Schritt tun, wenn andere zögern. Deine Frage: Wofür entzünde ich mein Feuer?',
 'Schatten: Ungeduld, Wut-Impulse, Alleingänge ohne Rücksicht. Übung: Pause zwischen Reiz und Tat.',
 1),

('sign','1','Stier','♉',
 ARRAY['Beständigkeit','Sinnlichkeit','Erde','Wert'],
 'Der Hüter. Erde, fix. Du erdest das, was andere flüchtig denken – in Körper, Werk und Wert.',
 'Als Stier ist Venus deine Herrin. Du schmeckst das Leben: Essen, Berührung, Schönheit, Natur. Deine Gabe: Dauerhaftes schaffen. Deine Frage: Was hat für mich wirklich Wert?',
 'Schatten: Besitzen statt sein, Starrsinn, Trägheit. Übung: bewusst loslassen, was du festhältst.',
 2),

('sign','2','Zwillinge','♊',
 ARRAY['Neugier','Sprache','Verbindung','Wandel'],
 'Der Bote. Luft, veränderlich. Du webst Brücken zwischen Ideen, Menschen, Welten.',
 'Als Zwilling ist Merkur dein Flügelschuh. Du sprichst, lernst, fragst – unersättlich. Deine Gabe: Vielfalt denken. Deine Frage: Wo hinter den Worten ruht meine Mitte?',
 'Schatten: Zerstreuung, Oberflächlichkeit, Doppelbödigkeit. Übung: ein Thema vertiefen, bevor du das nächste angehst.',
 3),

('sign','3','Krebs','♋',
 ARRAY['Nähe','Fürsorge','Heimat','Gefühl'],
 'Die Heilerin. Wasser, kardinal. Du trägst Zuhause in dir – für dich und die, die du liebst.',
 'Als Krebs reagierst du wie der Mond auf Gezeiten. Du spürst, was andere nicht sagen. Deine Gabe: halten, nähren, erinnern. Deine Frage: Wessen Gefühl trage ich und wessen sind wirklich meine?',
 'Schatten: Klammern, Launen, alte Kränkungen. Übung: Grenzen setzen, Panzer ablegen.',
 4),

('sign','4','Löwe','♌',
 ARRAY['Herz','Ausstrahlung','Schöpfung','Würde'],
 'Der König / die Königin. Feuer, fix. Du scheinst – und darfst gesehen werden.',
 'Als Löwe ist die Sonne dein Zentrum. Du schaffst wie ein Kind, das malt, ohne zu fragen. Deine Gabe: Wärme, Kreativität, echte Herzensregie. Deine Frage: Strahle ich aus Fülle oder aus Mangel an Anerkennung?',
 'Schatten: Ego, Drama, Stolz. Übung: dienen, ohne dich zu verlieren.',
 5),

('sign','5','Jungfrau','♍',
 ARRAY['Klarheit','Handwerk','Dienst','Reinheit'],
 'Die Handwerkerin. Erde, veränderlich. Du ordnest das Chaos – mit Hingabe, nicht Härte.',
 'Als Jungfrau verfeinerst du. Du siehst, was fehlt, und schenkst es. Merkur führt dich zum konkreten Tun. Deine Gabe: heilsame Präzision. Deine Frage: Für wen arbeite ich, und wessen Anspruch lebe ich?',
 'Schatten: Selbstkritik, Perfektionismus, Nörgeln. Übung: unvollkommen handeln, lernen, liebend.',
 6),

('sign','6','Waage','♎',
 ARRAY['Schönheit','Beziehung','Balance','Gerechtigkeit'],
 'Die Brückenbauerin. Luft, kardinal. Du suchst das Wir – und das Gleichgewicht.',
 'Als Waage regiert Venus den Raum dazwischen. Du bist Diplomat, Ästhet, Partner-Instinkt. Deine Gabe: Perspektiven verbinden. Deine Frage: Welches Ja ist meins, nicht bloß gefällig?',
 'Schatten: Unentschlossenheit, Harmonie-Sucht, Rückzug vor Konflikt. Übung: klar Position nehmen.',
 7),

('sign','7','Skorpion','♏',
 ARRAY['Tiefe','Wandlung','Wahrheit','Leidenschaft'],
 'Der Alchemist / die Alchemistin. Wasser, fix. Du tauchst unter die Oberfläche – bis zum Grund.',
 'Als Skorpion bewohnst du die Schattenschichten. Pluto ist dein Lehrer: Sterben und Werden. Deine Gabe: radikale Wahrheit, echte Intimität. Deine Frage: Welche alte Haut darf gehen?',
 'Schatten: Eifersucht, Machtspiele, Rache-Reflex. Übung: Kontrolle loslassen, vertrauen.',
 8),

('sign','8','Schütze','♐',
 ARRAY['Sinn','Weite','Philosophie','Reise'],
 'Der Pfeilbogen. Feuer, veränderlich. Du zielst über den Horizont – und vertraust dem Weg.',
 'Als Schütze sucht Jupiter in dir nach Sinn und Wahrheit, die trägt. Du reist – im Körper wie im Geist. Deine Gabe: Überblick, Humor, Glaubenskraft. Deine Frage: Wofür lebe ich, jenseits des Alltags?',
 'Schatten: Dogma, Überheblichkeit, Unruhe. Übung: da sein, wo du bist.',
 9),

('sign','9','Steinbock','♑',
 ARRAY['Struktur','Verantwortung','Meisterschaft','Zeit'],
 'Der Bergsteiger / die Bergsteigerin. Erde, kardinal. Du baust Schritt für Schritt, was Bestand hat.',
 'Als Steinbock gehört dir Saturn: Zeit, Disziplin, Würde. Du nimmst Verantwortung, auch die schwere. Deine Gabe: tragfähige Strukturen. Deine Frage: Welcher Gipfel ist wirklich meiner?',
 'Schatten: Härte, Kälte, Erfolgs-Zwang. Übung: spielen, Tränen zulassen.',
 10),

('sign','10','Wassermann','♒',
 ARRAY['Freiheit','Vision','Gemeinschaft','Originalität'],
 'Der Visionär / die Visionärin. Luft, fix. Du denkst weiter – und hebst ab, wenn nötig.',
 'Als Wassermann vereinst du Saturn und Uranus: Verantwortung und Revolution. Du siehst Muster, wo andere Zufall sehen. Deine Gabe: Zukunft imaginieren, Gemeinschaft neu denken. Deine Frage: Für welches Wir kämpfe ich?',
 'Schatten: Distanz, Kühle, Rebellion um der Rebellion willen. Übung: im Herzen ankommen, nicht nur im Kopf.',
 11),

('sign','11','Fische','♓',
 ARRAY['Hingabe','Mitgefühl','Traum','Einheit'],
 'Der Mystiker / die Mystikerin. Wasser, veränderlich. Du löst Grenzen – und erinnerst das Ganze.',
 'Als Fisch bist du Neptun und Jupiter zugleich: Gnade und Weite. Du fühlst, was nicht gesagt wird, schwimmst im Unterstrom. Deine Gabe: Heilung, Kunst, Mitfühlen. Deine Frage: Wo beginne ich, wo endet das Andere?',
 'Schatten: Flucht, Opfer-Haltung, Sucht. Übung: deinen Körper als Anker lieben.',
 12)

ON CONFLICT (category, key) DO UPDATE SET
  title       = EXCLUDED.title,
  emoji       = EXCLUDED.emoji,
  keywords    = EXCLUDED.keywords,
  short_text  = EXCLUDED.short_text,
  deep_text   = EXCLUDED.deep_text,
  shadow_text = EXCLUDED.shadow_text,
  sort_order  = EXCLUDED.sort_order;
