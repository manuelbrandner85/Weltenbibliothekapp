-- ============================================================
-- v20d: Traumdeutung-Seed – Mensch/Familie-Symbole (12 Stück)
-- ============================================================
-- Menschen-Archetypen in Träumen mit Multi-Traditions-Deutungen.
-- Idempotent via ON CONFLICT DO UPDATE.
-- ============================================================

INSERT INTO public.dream_symbols
  (symbol_key, symbol_name, category, emoji, keywords, meanings, sort_order)
VALUES

('mutter', 'Mutter', 'mensch', '👩',
 ARRAY['mutter','mama','mami','mutti','mom','muttersymbol'],
 jsonb_build_object(
   'jungian',  'Mutter-Archetyp: nährend (Demeter) und verschlingend (Kali). Form der Mutter im Traum zeigt aktuellen Bezug zum Weiblichen.',
   'freudian', 'Zentrales Objekt der ödipalen Phase. Jede erotische und abhängige Regung wird zurück-gespiegelt.',
   'spiritual','Göttliches Weibliches in personaler Form. Heilung der Mutter-Linie = Heilung im Traum.',
   'shamanic', 'Ahnen-Mutter, Klan-Hüterin. Mutter-Traum = Botschaft aus der Sippe.',
   'germanic', 'Disen (weibliche Ahnen-Geister) zeigen sich als mütterliche Figur.'
 ),
 200),

('vater', 'Vater', 'mensch', '👨',
 ARRAY['vater','papa','papi','dad','vati','vatersymbol'],
 jsonb_build_object(
   'jungian',  'Vater-Archetyp: Ordnung, Gesetz, Weg-Öffnender. Vater-Traum = Frage nach Autorität und eigenem Platz in der Welt.',
   'freudian', 'Über-Ich-Instanz, Rivale, Vorbild zugleich. Konflikt-Figur der ödipalen Dynamik.',
   'spiritual','Himmlischer Vater, spirituelle Führung. Vater-Figur zeigt Beziehung zum Höheren Selbst.',
   'shamanic', 'Ältester des Klans, Weisheitsträger. Vater-Traum = Ruf nach Verantwortung.',
   'germanic', 'Odin-Archetyp: Ein-äugiger Seher. Weisheit um den Preis eines Opfers.'
 ),
 201),

('kind', 'Kind', 'mensch', '🧒',
 ARRAY['kind','kinder','junge','mädchen','klein-kind'],
 jsonb_build_object(
   'jungian',  'Göttliches Kind — der Aspekt, der neu werden will. Inneres Kind in Not oder Freude.',
   'freudian', 'Regressions-Wunsch, eigene Kindheits-Anteile. Kind in Gefahr = verdrängter Schmerz.',
   'spiritual','Seelenkind, noch ungelebter Lebensimpuls. "Werdet wie die Kinder." (Matthäus 18,3)',
   'shamanic', 'Seelen-Teil, der zurückgerufen werden will (Soul Retrieval).',
   'germanic', 'Baldur-Motiv: Licht-Kind, verletzlich, aber mit größter Kraft.'
 ),
 202),

('baby', 'Baby / Säugling', 'mensch', '👶',
 ARRAY['baby','säugling','neugeborenes','bebi'],
 jsonb_build_object(
   'jungian',  'Neu geborenes Potenzial in der Psyche. Ein Projekt, eine Beziehung, eine Seite von dir will Welt betreten.',
   'freudian', 'Oraler Wunsch, Regression. Auch: unbewusster Kinderwunsch.',
   'spiritual','Reine Seele, heilige Ankunft. Baby-Traum = Schwangerschaft einer neuen Lebensphase.',
   'shamanic', 'Seele kommt in den Kreis. Ahnen begrüßen den neuen Weg.',
   'germanic', 'Wiege-Magie. Das Kind, das benannt wird, ist geschützt.'
 ),
 203),

('verstorbener', 'Verstorbene Person', 'mensch', '👻',
 ARRAY['verstorbene','toter','tote','geist','ahne','ahnen','opa-tot','oma-tot'],
 jsonb_build_object(
   'jungian',  'Innere Repräsentation der Person, nicht die Person selbst. Klären offener Gefühle.',
   'freudian', 'Trauer-Arbeit, Schuldgefühl, Ambivalenz. Gespräch im Traum = Integration des Verlusts.',
   'spiritual','Realer Seelen-Kontakt über die Traum-Brücke. Botschaft der Seele.',
   'shamanic', 'Ahnen-Besuch. Wichtig: zuhören, nicht ängstigen. Ehren, dann handeln.',
   'germanic', 'Draugar-Glaube: Wer träumt, ist von Ahnen besucht. Geschenk oder Warnung.'
 ),
 204),

('fremder', 'Fremder / Unbekannter', 'mensch', '🕵️',
 ARRAY['fremder','fremde','unbekannter','schatten-person','fremdling'],
 jsonb_build_object(
   'jungian',  'Klarer Schatten-Archetyp. Was dich an der Person stört, ist eigener verdrängter Anteil.',
   'freudian', 'Uncanny (unheimlich) — eigenes Verdrängtes, das fremd wirkt.',
   'spiritual','Engel in Verkleidung (vgl. Hebräer 13,2). Achte auf Botschaft.',
   'shamanic', 'Andere-Welt-Bote. Höre genau, was gesagt wird.',
   'germanic', 'Wandernder Odin. Der Fremde könnte der Gott sein — immer höflich sein.'
 ),
 205),

('geliebter', 'Geliebte(r) / Partner(in)', 'mensch', '💑',
 ARRAY['geliebter','geliebte','partner','partnerin','freund-liebe','freundin-liebe','lover'],
 jsonb_build_object(
   'jungian',  'Anima/Animus — das innere Gegengeschlecht. Liebesakt im Traum = Integration der anderen Seite.',
   'freudian', 'Libido-Objekt, oft Verschiebung (früher Partner = Eltern-Imago).',
   'spiritual','Heilige Hochzeit (Hieros Gamos), Verbindung der inneren Polaritäten.',
   'shamanic', 'Geist-Gemahl-Motiv — seelische Verbindung jenseits der Alltags-Beziehung.',
   'germanic', 'Freyr/Freya-Prinzip: Liebe als kosmische Kraft.'
 ),
 206),

('ex_partner', 'Ex-Partner / frühere Liebe', 'mensch', '💔',
 ARRAY['ex','ex-partner','ex-freund','ex-freundin','alte-liebe','verflossene'],
 jsonb_build_object(
   'jungian',  'Nicht-integriertes Material der Beziehung. Was blieb unverarbeitet? Welcher Anima/Animus-Aspekt bleibt offen?',
   'freudian', 'Unabgeschlossene Trauer. Wunsch nach Wiedergutmachung oder Rache.',
   'spiritual','Seelenvertrag möglicherweise noch nicht abgeschlossen — Vergebungsarbeit im Traum.',
   'shamanic', 'Energetische Verbindung noch aktiv (Cords). Traum = Gelegenheit zur Auflösung.',
   'germanic', 'Eidbruch-Motiv: Wo wurde eine Treue gebrochen oder nicht gelebt?'
 ),
 207),

('freund', 'Freund / Freundin', 'mensch', '👥',
 ARRAY['freund','freundin','kumpel','kamerad','buddy','freunde'],
 jsonb_build_object(
   'jungian',  'Spiegel positiver Selbst-Anteile. Freund im Traum = eigene gesunde Identifikation.',
   'freudian', 'Geschwister-Ersatz, narzisstische Selbst-Spiegelung.',
   'spiritual','Seelen-Verwandter. Traum-Begegnung = Bestätigung der Verbindung.',
   'shamanic', 'Weggefährte, mit dem du schon viele Leben teiltest.',
   'germanic', 'Blutsbruderschaft. Traum-Freund = Eid-Verbindung.'
 ),
 208),

('lehrer', 'Lehrer / Weise Figur', 'mensch', '🧙',
 ARRAY['lehrer','lehrerin','meister','weiser','weise','guru','mentor'],
 jsonb_build_object(
   'jungian',  'Der Weise Alte — Archetyp innerer Führung. Botschaft im Traum ist direkt vom Selbst.',
   'freudian', 'Idealisierter Vater-Ersatz, Autorität ohne Bedrohung.',
   'spiritual','Seelen-Guide, Aufgestiegener Meister. Höre gut zu, was gelehrt wird.',
   'shamanic', 'Geist-Lehrer aus der oberen Welt. Kann als Mensch, Tier oder Wesen erscheinen.',
   'germanic', 'Mimir, Hüter der Weisheits-Quelle. Oder Runen-Meister.'
 ),
 209),

('doppelgaenger', 'Doppelgänger / Alter Ego', 'mensch', '👥',
 ARRAY['doppelgänger','doppelgaenger','alter-ego','ich-selbst','mein-doppel'],
 jsonb_build_object(
   'jungian',  'Begegnung mit dem Selbst oder dem Schatten. Entscheidende Individuations-Phase.',
   'freudian', 'Spaltung des Ich — abgelehnte Seite kehrt zurück.',
   'spiritual','Höheres oder niederes Selbst. Traum zeigt Richtungs-Entscheidung.',
   'shamanic', 'Seelen-Doppel, das zurück-gerufen werden will.',
   'germanic', 'Fylgja — persönlicher Schicksalsgeist. Zu sehen = Kraft-Zeichen.'
 ),
 210),

('schatten_person', 'Schatten-Figur (dunkle Gestalt)', 'mensch', '🕴️',
 ARRAY['schatten','schattengestalt','dunkle-figur','schwarze-gestalt','silhouette'],
 jsonb_build_object(
   'jungian',  'Klassischer Schatten — verdrängte Seite der Psyche. Nicht bekämpfen, sondern ins Gespräch kommen.',
   'freudian', 'Das Es in personifizierter Form. Aggressive/sexuelle Impulse.',
   'spiritual','Dunkle Nacht der Seele. Begegnung als Initiation in tiefere Selbsterkenntnis.',
   'shamanic', 'Seelen-Anteil, der ausgelagert wurde (z.B. durch Trauma). Zurück-Integration durch Soul Retrieval.',
   'germanic', 'Unhold — kann in Lichtgestalt verwandelt werden durch Namen-Nennen.'
 ),
 211)

ON CONFLICT (symbol_key) DO UPDATE SET
  symbol_name = EXCLUDED.symbol_name,
  category    = EXCLUDED.category,
  emoji       = EXCLUDED.emoji,
  keywords    = EXCLUDED.keywords,
  meanings    = EXCLUDED.meanings,
  sort_order  = EXCLUDED.sort_order;

-- ============================================================
-- Verifikation:
-- SELECT symbol_name, emoji FROM dream_symbols
--   WHERE category = 'mensch' ORDER BY sort_order;
-- ============================================================
