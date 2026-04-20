-- ============================================================
-- v20b: Traumdeutung-Seed – Elementar-Symbole (13 Stück)
-- ============================================================
-- Elemente Wasser / Feuer / Erde / Luft mit Unter-Symbolen.
-- Mehrsprachige Bedeutungen aus fünf Traditionen (jungian,
-- freudian, spiritual, shamanic, germanic). Idempotent via
-- ON CONFLICT (symbol_key) DO UPDATE.
-- ============================================================

INSERT INTO public.dream_symbols
  (symbol_key, symbol_name, category, emoji, keywords, meanings, sort_order)
VALUES

-- === WASSER-SYMBOLE ===========================================
('wasser', 'Wasser', 'element', '💧',
 ARRAY['wasser','h2o','nass','flüssig','flut','strömung'],
 jsonb_build_object(
   'jungian',  'Das Unbewusste schlechthin. Klarheit des Wassers spiegelt Zugang zu inneren Schichten — trüb=Verdrängung, klar=Integration.',
   'freudian', 'Mutterleib, Geburt, sexuelle Energie. Wassertraum oft mit Wunsch nach Regression verbunden.',
   'spiritual','Emotionale Reinigung und Fluss der Lebensenergie. Wasser lehrt, dem Leben zu vertrauen.',
   'shamanic', 'Das weibliche Element, Heilwasser, Tor zur Unterwelt. Ahnen kommunizieren durch Wasser.',
   'germanic', 'Quelle der Nornen (Urd). Wasser bringt Schicksal und Weisheit aus der Tiefe.'
 ),
 10),

('meer', 'Meer / Ozean', 'element', '🌊',
 ARRAY['meer','ozean','see-groß','salzwasser','küste','brandung','wellen'],
 jsonb_build_object(
   'jungian',  'Kollektives Unbewusstes. Die Unendlichkeit zeigt die Tiefe psychischer Ressourcen — Sturm=innere Krise, Stille=Integration.',
   'freudian', 'Ur-Mutter, Schoß, Rückzug ins Pränatale. Meeresgefahr = Angst vor Verschlungenwerden.',
   'spiritual','Die Seele in ihrer Weite. Wer ins Meer taucht, taucht in die eigene Ewigkeit.',
   'shamanic', 'Andere Welt, Heimat der Ahnen-Seelen. Meer-Tiere sind Krafttiere der Tiefe.',
   'germanic', 'Aegir''s Reich. Im Meer zu schwimmen heißt, sich dem großen Schicksal zu überlassen.'
 ),
 11),

('fluss', 'Fluss', 'element', '🏞️',
 ARRAY['fluss','bach','strom','strömung','fließen','flussbett'],
 jsonb_build_object(
   'jungian',  'Lebensweg, Zeit, gerichtete Energie. Flussrichtung = Lebensrichtung — gegen den Strom = innerer Widerstand.',
   'freudian', 'Geburtskanal, sexuelles Fließen, auch Tränen-/Speichelflüsse der frühen Kindheit.',
   'spiritual','Göttlicher Fluss (Tao). Nicht kämpfen — mit dem Strom gehen ist die Lektion.',
   'shamanic', 'Grenze zwischen Welten. Den Fluss überqueren = Schwellenübergang, Initiation.',
   'germanic', 'Grenze zwischen Midgard und anderen Welten. Flussüberquerung = wichtige Lebensentscheidung.'
 ),
 12),

('regen', 'Regen', 'element', '🌧️',
 ARRAY['regen','niederschlag','schauer','gewitter','tropfen'],
 jsonb_build_object(
   'jungian',  'Reinigung und Fruchtbarkeit. Tränen, die nach außen fallen. Auch: Segen von oben auf bewusste Ebene.',
   'freudian', 'Aufgestaute Emotion, die endlich strömt. Tränenersatz in der Trauerarbeit.',
   'spiritual','Segen des Himmels. Regen im Traum = emotionale Heilung, Loslösung.',
   'shamanic', 'Himmel spricht zur Erde. Regenmacher-Ritual = Balance zwischen Welten.',
   'germanic', 'Donar (Thor) schickt den nährenden Regen. Reinigung und Neuanfang.'
 ),
 13),

-- === FEUER-SYMBOLE ============================================
('feuer', 'Feuer', 'element', '🔥',
 ARRAY['feuer','flammen','brand','verbrennen','glut','lagerfeuer'],
 jsonb_build_object(
   'jungian',  'Transformation und Leidenschaft. Feuer verwandelt Materie — so wie Bewusstsein Erfahrung verwandelt.',
   'freudian', 'Libido, erotische Erregung. Unkontrolliertes Feuer = Angst vor eigener Triebkraft.',
   'spiritual','Göttliche Gegenwart. Das Feuer der Kundalini, das innere Licht.',
   'shamanic', 'Grosser Transformator. Im Feuer spricht der Geist der Ahnen, Visionen kommen.',
   'germanic', 'Loki''s zweischneidige Kraft — kann heilen oder zerstören. Herdfeuer = Schutz der Sippe.'
 ),
 20),

('kerze', 'Kerze / Flamme', 'element', '🕯️',
 ARRAY['kerze','flamme','docht','wachs','licht-klein'],
 jsonb_build_object(
   'jungian',  'Bewusstsein im Dunkel. Eine Kerze = individuelle Einsicht, die der kollektiven Dunkelheit widersteht.',
   'freudian', 'Phallisches Symbol, aber auch Hoffnungslicht in depressiver Phase.',
   'spiritual','Die Seele selbst. Brennt die Kerze ruhig, ist der Geist klar — flackert sie, ist Unruhe da.',
   'shamanic', 'Licht-Anker für Zwischenwelten-Reise. Ausgepustete Kerze = Zeichen von Präsenz.',
   'germanic', 'Herdfeuer en miniature. Die Kerze ehrt die Hausgeister.'
 ),
 21),

-- === ERDE-SYMBOLE =============================================
('erde', 'Erde / Boden', 'element', '🌍',
 ARRAY['erde','boden','acker','erdboden','humus'],
 jsonb_build_object(
   'jungian',  'Mutter-Archetyp, Fundament der Persönlichkeit. Auf der Erde stehen = geerdet, im Selbst verankert.',
   'freudian', 'Mutterleib, Grab, orale Grundversorgung.',
   'spiritual','Die Erdmutter Gaia. Barfuss auf Erde = Heilung durch Erdung (Grounding).',
   'shamanic', 'Unterwelt-Eingang, Ort der Kraft-Ahnen. Erde aufnehmen = Medizin empfangen.',
   'germanic', 'Nerthus/Frigg. Die nährende Göttin. Fruchtbarkeit und Verlässlichkeit.'
 ),
 30),

('berg', 'Berg', 'element', '⛰️',
 ARRAY['berg','gipfel','felsen-groß','alpen','höhe','hügel'],
 jsonb_build_object(
   'jungian',  'Selbst-Verwirklichung, Ziel der Individuation. Bergbesteigung = innere Reife-Arbeit.',
   'freudian', 'Über-Ich, väterliche Autorität. Zum Gipfel streben = ödipaler Ehrgeiz.',
   'spiritual','Aufstieg zum Göttlichen. Der Berg ist der Meister — er verlangt Respekt.',
   'shamanic', 'Axis mundi, Weltenbaum-Ersatz. Auf dem Berg sprechen die Geister der Höhe.',
   'germanic', 'Wohnsitz der Riesen (Jötnar). Kraft und Gefahr zugleich.'
 ),
 31),

('stein', 'Stein / Fels', 'element', '🪨',
 ARRAY['stein','fels','gestein','brocken','kiesel'],
 jsonb_build_object(
   'jungian',  'Das Selbst als unverrückbare Mitte. Der Stein der Weisen = vollendete Individuation.',
   'freudian', 'Verhärtung, Abwehr, emotionale Starre.',
   'spiritual','Zeuge der Zeit. Steine speichern Weisheit — im Traum erhalten = bleibende Lektion.',
   'shamanic', 'Alte Ahnen sprechen durch Steine. Jeder Stein hat einen Geist.',
   'germanic', 'Runen-Träger. Der Stein ist der Schreiber der Götter.'
 ),
 32),

-- === LUFT-SYMBOLE =============================================
('luft', 'Luft', 'element', '🌬️',
 ARRAY['luft','atem','atmung','atemluft','sauerstoff'],
 jsonb_build_object(
   'jungian',  'Geist, Denken, Intellekt. Atem-Traum = Frage nach dem eigenen Lebens-Raum.',
   'freudian', 'Erste Trennung (erster Atemzug nach Geburt). Ersticken = Angst vor Trennung.',
   'spiritual','Prana, Chi. Die Luft trägt das Bewusstsein selbst.',
   'shamanic', 'Die Stimme der Ahnen, Wind-Botschaft. Tief atmen = Geister einladen.',
   'germanic', 'Odin''s Atemhauch (Önd), der den ersten Menschen Leben gab.'
 ),
 40),

('wind', 'Wind / Sturm', 'element', '💨',
 ARRAY['wind','sturm','brise','böe','orkan','tornado','wehen'],
 jsonb_build_object(
   'jungian',  'Bewegung im Unbewussten, unerwartete Wandlung. Sturm = Konflikt zwischen Bewusstem und Schatten.',
   'freudian', 'Unkontrollierbare Triebkraft, auch Wut.',
   'spiritual','Der Heilige Geist. Wind weht, wo er will — Vertrauen statt Planung.',
   'shamanic', 'Vier-Winde-Medizin: Ost=Neubeginn, Süd=Jugend, West=Einkehr, Nord=Weisheit.',
   'germanic', 'Odin auf Wilder Jagd. Sturm = Götter in Aktion, Zeit der Entscheidung.'
 ),
 41),

('wolke', 'Wolken', 'element', '☁️',
 ARRAY['wolke','wolken','kumulus','nebel','dunst'],
 jsonb_build_object(
   'jungian',  'Schwebende Gedanken, Tagträume, Projektionen. Dunkle Wolke = verdrängter Affekt.',
   'freudian', 'Träumerei, Flucht vor Realität, pränatale Schwebe.',
   'spiritual','Botschaften in Wolkenform — achte auf Symbole im Himmel.',
   'shamanic', 'Wolkenwesen, Wettergeister. Reisen auf der Wolke = schamanischer Flug.',
   'germanic', 'Asen reiten auf Wolken. Himmelszeichen deuten.'
 ),
 42),

('blitz', 'Blitz / Donner', 'element', '⚡',
 ARRAY['blitz','donner','gewitter','einschlag','wetterleuchten'],
 jsonb_build_object(
   'jungian',  'Plötzliche Erkenntnis (satori), Durchbruch des Unbewussten ins Bewusste.',
   'freudian', 'Ur-Szene (Elterliche Sexualität vom Kind erahnt) — Schockmoment.',
   'spiritual','Göttlicher Funke erreicht die Erde. Blitz im Traum = Initiation.',
   'shamanic', 'Donnervogel-Medizin. Wer vom Blitz geträumt hat, ist berufen.',
   'germanic', 'Thor''s Hammer Mjölnir. Segen und Strafe in einem.'
 ),
 43)

ON CONFLICT (symbol_key) DO UPDATE SET
  symbol_name = EXCLUDED.symbol_name,
  category    = EXCLUDED.category,
  emoji       = EXCLUDED.emoji,
  keywords    = EXCLUDED.keywords,
  meanings    = EXCLUDED.meanings,
  sort_order  = EXCLUDED.sort_order;

-- ============================================================
-- Verifikation:
-- SELECT symbol_name, emoji, array_length(keywords,1) AS kw_count
--   FROM dream_symbols
--   WHERE category = 'element'
--   ORDER BY sort_order;
-- ============================================================
