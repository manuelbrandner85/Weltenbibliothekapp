-- ============================================================
-- v26b: Seed 5 Human-Design-Typen + 7 Autoritäten + 4 Strategien
-- ============================================================

INSERT INTO public.hd_meanings
  (category, key, title, emoji, keywords, short_text, deep_text, shadow_text, sort_order)
VALUES

-- ── Types ──────────────────────────────────────────────────
('type','manifestor','Manifestor','🔥',
 ARRAY['Initiator','Impuls','Autonomie','Freiheit'],
 'Ca. 9 % der Menschheit. Du startest, ohne zu fragen.',
 'Manifestoren sind die einzigen, die aus eigener Kraft initiieren können. Ihre Aura stößt an, schockt manchmal. Strategie: informieren, bevor du handelst. Dann fließt, was sonst Widerstand weckt.',
 'Schatten: Wut, wenn andere dich stoppen. Übung: vorab kurz informieren, nicht um Erlaubnis zu fragen, sondern um Raum zu schaffen.',
 1),

('type','generator','Generator','⚙️',
 ARRAY['Sakral','Antwort','Lebensenergie','Meisterschaft'],
 'Ca. 37 % der Menschheit. Du bist die motorische Kraft.',
 'Generatoren haben ein definiertes Sakral-Zentrum – die Quelle nachhaltiger Energie. Sie sind nicht zum Initiieren gemacht, sondern zum Antworten. Dein "Uh-huh / Un-uh" zeigt den Weg.',
 'Schatten: Frust, wenn du auf Dinge einsteigst, die nicht "anklopfen". Übung: abwarten, bis etwas dich ruft.',
 2),

('type','manifesting_generator','Manifesting Generator','🌀',
 ARRAY['Multi-passionate','Schnell','Antwort & Initiieren','Sprungkraft'],
 'Ca. 33 %. Hybrid aus Generator + Manifestor.',
 'Du hast die Lebensenergie des Generators und die initiierende Kraft des Manifestors. Du springst zwischen Themen, findest Abkürzungen. Strategie: antworten + informieren.',
 'Schatten: Frust + Wut zugleich, wenn du überspringst oder ignorierst, was klopft. Übung: Sprünge bewusst ankündigen.',
 3),

('type','projector','Projector','👁️',
 ARRAY['Weisheit','Einladung','Anerkennung','System'],
 'Ca. 20 %. Du führst durch Einsicht, nicht durch Tun.',
 'Projektoren haben kein definiertes Sakral. Ihre Aura durchdringt das System des anderen. Sie sind die Berater des neuen Zeitalters. Strategie: auf Einladung warten – nicht für alles, aber für die großen Dinge.',
 'Schatten: Bitterkeit, wenn du nicht anerkannt wirst. Übung: Selbst-Anerkennung & Ruhe zulassen.',
 4),

('type','reflector','Reflector','🌕',
 ARRAY['Spiegel','Mond','Gemeinschaft','Zeit'],
 'Ca. 1 %. Du bist der Spiegel der Gesellschaft.',
 'Reflektoren haben kein definiertes Zentrum. Ihre Aura ist offen, nimmt alles wahr. Sie brauchen einen vollen Mondzyklus (28 Tage), bevor wichtige Entscheidungen klar werden. Strategie: warten, atmen, Umgebung wählen.',
 'Schatten: Enttäuschung, wenn du die Gemeinschaft spiegelst, in der du nicht gesund bist. Übung: Umgebung bewusst wählen.',
 5),

-- ── Authorities ────────────────────────────────────────────
('authority','emotional','Emotionale Autorität','🌊',
 ARRAY['Welle','Klarheit','Warten','Stimmung'],
 'Warte die emotionale Welle ab. Keine Wahrheit in der Höhe oder Tiefe.',
 'Mit definiertem Solarplexus brauchst du Zeit. Deine Klarheit kommt nicht im Moment, sondern über Stunden oder Tage – wenn du Freude, Zweifel, Ruhe gleichermaßen durchlaufen hast.',
 'Schatten: Impulsive Zusagen, die du später bereust. Übung: "Schlaf eine Nacht drüber."',
 1),

('authority','sacral','Sakrale Autorität','🔊',
 ARRAY['Bauch','Ja-Nein','Sofort','Körperlich'],
 'Dein Bauch weiß: "Uh-huh" (ja) oder "Un-uh" (nein).',
 'Generatoren ohne definierten Solarplexus entscheiden aus dem Sakral. Die Antwort kommt als Geräusch oder Körpergefühl im Moment der Frage. Vertraue, es braucht keine Analyse.',
 'Schatten: Kopf-Stimme übertönt das Bauch-Gefühl. Übung: Fragen so stellen, dass "Ja/Nein" reicht.',
 2),

('authority','splenic','Splenische Autorität','🦴',
 ARRAY['Intuition','Jetzt','Flüsternd','Überleben'],
 'Eine leise, blitzartige Stimme im Moment. Einmal.',
 'Die Milz spricht spontan und leise. Sie wiederholt sich nicht. Wer diese Autorität hat, muss lernen, ihrem ersten Impuls zu vertrauen – sie ist das älteste Überlebens-Organ im Körper.',
 'Schatten: Die Stimme ignorieren, dann zu spät bemerken. Übung: den ersten Impuls notieren.',
 3),

('authority','ego','Ego-/Herz-Autorität','❤️‍🔥',
 ARRAY['Willen','Versprechen','Ich-will','Ressource'],
 'Was du willst. Was du versprichst, das hältst du.',
 'Sehr selten. Der Wille des Herzens entscheidet. Diese Autorität folgt dem "Ich will" – authentisch, wenn es zu den eigenen Ressourcen passt. Das Versprechen ist heilig.',
 'Schatten: Überversprechen aus Ego. Übung: erst fühlen: habe ich wirklich Kraft dafür?',
 4),

('authority','self_projected','Selbst-projizierte Autorität','🎙️',
 ARRAY['Sprache','Laut denken','Kehle','Identität'],
 'Sprich es aus – und höre, was du sagst.',
 'Projektoren mit definierter Kehle + G-Zentrum. Deine Wahrheit wird hörbar, wenn du sie aussprichst. Du brauchst Zuhörer – nicht für Rat, sondern als Resonanzraum.',
 'Schatten: Schweigen im entscheidenden Moment. Übung: vertrauenswürdigen Kreis finden.',
 5),

('authority','lunar','Mond-Autorität','🌙',
 ARRAY['28 Tage','Transit','Klarheit','Zyklus'],
 'Eine volle Mond-Runde – dann weißt du.',
 'Nur Reflektoren. Eine Entscheidung braucht 28 Tage, in denen sich der Mond durch alle 64 Tore bewegt. Erst dann hast du jede Facette gespürt.',
 'Schatten: Unter Druck zu schnell "ja" sagen. Übung: Zeit als Geschenk einfordern.',
 6),

('authority','mental','Mentale Autorität','🧠',
 ARRAY['Projektoren','Umgebung','Austausch','Klarheit durch Gespräch'],
 'Kein Bauch-Kompass. Klarheit kommt durch Umgebung und Gespräch.',
 'Projektoren ohne definierte Motoren. Die Umgebung spiegelt, was stimmig ist. Du triffst Entscheidungen im Austausch mit vertrauten Menschen an stimmigen Orten.',
 'Schatten: Allein in Enge kreisen. Übung: ins Freie, ins Gespräch.',
 7),

-- ── Strategies ─────────────────────────────────────────────
('strategy','inform','Informieren','📣',
 ARRAY['Manifestor','Frieden','Vorankündigung'],
 'Sag es, bevor du handelst.',
 'Die Strategie des Manifestors. Informieren heißt nicht um Erlaubnis bitten – sondern die anderen aus dem Weg der eigenen Kraft nehmen.',
 'Ohne Informieren entsteht Wut und Widerstand. Übung: „Ich werde jetzt X tun." ohne Rechtfertigung.',
 1),

('strategy','respond','Antworten','👂',
 ARRAY['Generator','Sakral','Warten auf Anklopfen'],
 'Warte, bis das Leben anklopft.',
 'Generatoren und MGs. Die Welt fragt dich – dein Sakral antwortet. Initiieren ohne Frage führt zu Frust.',
 'Schatten: immer selbst anfangen, dann wundern, wieso niemand mitmacht. Übung: sichtbar werden, aber warten.',
 2),

('strategy','wait_invitation','Auf Einladung warten','✉️',
 ARRAY['Projector','Erkannt werden','Große Dinge'],
 'Für die großen Themen: Karriere, Liebe, Heimat.',
 'Projektoren werden eingeladen, wenn sie gesehen und erkannt sind. Nicht für Alltagsdinge, sondern für das, was dein Leben prägt.',
 'Schatten: sich aufdrängen. Übung: sichtbar sein, aber nicht drängen.',
 3),

('strategy','wait_lunar','Einen Mondzyklus warten','🌕',
 ARRAY['Reflector','28 Tage','Gemeinschaft'],
 'Gib jeder großen Entscheidung 28 Tage.',
 'Nur Reflektoren. Der Mond ist der beständige innere Impulsgeber. Deine Wahrheit zeigt sich über den Zyklus hinweg.',
 'Schatten: Druck, jetzt zu entscheiden. Übung: Zeit einfordern.',
 4)

ON CONFLICT (category, key) DO UPDATE SET
  title       = EXCLUDED.title,
  emoji       = EXCLUDED.emoji,
  keywords    = EXCLUDED.keywords,
  short_text  = EXCLUDED.short_text,
  deep_text   = EXCLUDED.deep_text,
  shadow_text = EXCLUDED.shadow_text,
  sort_order  = EXCLUDED.sort_order;
