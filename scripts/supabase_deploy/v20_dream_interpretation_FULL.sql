-- ============================================================
-- v20: Spirit-Tools Phase 2 – Traumdeutung (Tool 6)
-- Step 6.1a: Schema only (no seed data)
-- ============================================================
-- Legt Tabellen für Symbol-Lexikon + User-Traumtagebuch an.
-- Folgt dem v18/v19-Pattern: RLS + GRANT anon/authenticated.
-- Seeds werden in v20b/c/d/e nachgereicht.
-- ============================================================

-- 1. dream_symbols (statisches Lexikon, öffentlich lesbar) -----
CREATE TABLE IF NOT EXISTS public.dream_symbols (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  -- Normalisierter Schlüssel (lowercase, ohne Umlaute/Leerzeichen).
  -- Beispiel: "wasser", "schlange", "verfolgtwerden".
  symbol_key TEXT NOT NULL UNIQUE,
  -- Anzeigename in Deutsch, z.B. "Wasser", "Verfolgt werden".
  symbol_name TEXT NOT NULL,
  -- Kategorie zum Gruppieren: 'element', 'tier', 'mensch',
  -- 'aktion', 'ort', 'objekt', 'natur', 'körper'.
  category TEXT NOT NULL,
  emoji TEXT,
  -- Synonyme/Stichwörter für Auto-Matching im Traumtext.
  -- Z.B. für "Wasser": ["see","meer","fluss","ozean","regen"].
  keywords TEXT[] NOT NULL DEFAULT '{}',
  -- Bedeutungen pro Tradition als JSONB:
  -- {
  --   "jungian": "...",   (Jung: Archetypen/kollektives Unbewusstes)
  --   "freudian": "...",  (Freud: verdrängte Wünsche)
  --   "spiritual": "...", (Esoterisch/New-Age)
  --   "shamanic": "...",  (Schamanisch/Naturvölker)
  --   "germanic": "..."   (Germanisch/Paungger-Tradition)
  -- }
  meanings JSONB NOT NULL DEFAULT '{}'::jsonb,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_dream_symbols_category
  ON public.dream_symbols(category, sort_order);
CREATE INDEX IF NOT EXISTS idx_dream_symbols_keywords
  ON public.dream_symbols USING GIN(keywords);

-- 2. dream_journal_v2 (pro User, chronologisch) ----------------
-- Neue Tabelle statt alter dream-Tabelle damit altes Tool
-- parallel weiter funktioniert, bis Phase 6.4 die Integration
-- umschaltet.
CREATE TABLE IF NOT EXISTS public.dream_journal_v2 (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  dream_date DATE NOT NULL DEFAULT CURRENT_DATE,
  title TEXT,
  description TEXT NOT NULL,
  -- Auto-getaggte Symbole (Array aus symbol_key-Werten).
  -- Z.B. ['wasser','schlange','verfolgtwerden'].
  symbol_tags TEXT[] NOT NULL DEFAULT '{}',
  -- Stimmung: 'angst','freude','traurig','wut','neutral','ekstatisch'.
  mood TEXT,
  lucid BOOLEAN NOT NULL DEFAULT false,
  -- Wiederkehrender Traum?
  recurring BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_dream_journal_v2_user
  ON public.dream_journal_v2(user_id, dream_date DESC);
CREATE INDEX IF NOT EXISTS idx_dream_journal_v2_tags
  ON public.dream_journal_v2 USING GIN(symbol_tags);

-- 3. RLS aktivieren ---------------------------------------------
ALTER TABLE public.dream_symbols     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dream_journal_v2  ENABLE ROW LEVEL SECURITY;

-- 4. Policies (idempotent) --------------------------------------
DROP POLICY IF EXISTS "Traumsymbole öffentlich"        ON public.dream_symbols;
CREATE POLICY "Traumsymbole öffentlich" ON public.dream_symbols
  FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "User sieht eigenes Traumbuch"   ON public.dream_journal_v2;
CREATE POLICY "User sieht eigenes Traumbuch" ON public.dream_journal_v2
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 5. Table-Privileges (PostgREST braucht explizite GRANTs) -----
GRANT SELECT                         ON public.dream_symbols    TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.dream_journal_v2 TO authenticated;

-- ============================================================
-- Verifikation (nach Apply):
-- SELECT table_name FROM information_schema.tables
--   WHERE table_schema='public'
--     AND table_name IN ('dream_symbols','dream_journal_v2');
-- ============================================================
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
-- ============================================================
-- v20c: Traumdeutung-Seed – Tier-Symbole (12 Stück)
-- ============================================================
-- Krafttiere und archetypische Traumtiere mit Bedeutungen
-- aus fünf Traditionen. Idempotent via ON CONFLICT DO UPDATE.
-- ============================================================

INSERT INTO public.dream_symbols
  (symbol_key, symbol_name, category, emoji, keywords, meanings, sort_order)
VALUES

('schlange', 'Schlange', 'tier', '🐍',
 ARRAY['schlange','natter','kobra','python','viper','otter-wasser'],
 jsonb_build_object(
   'jungian',  'Eines der vieldeutigsten Symbole — Transformation (Häutung), Weisheit, aber auch Schattenseite. Begegnung = Integration des Unbewussten.',
   'freudian', 'Phallus-Symbol par excellence. Verführung, Triebkraft, Tabu.',
   'spiritual','Kundalini-Energie steigt. Heilung durch Urkraft. Doppelschlange = Caduceus-Heilung.',
   'shamanic', 'Medizin der Erde. Die Schlange weiß, wie man heilt — Nachi-Volk, Naga, Regenbogenschlange.',
   'germanic', 'Midgardschlange Jörmungandr — Grenze der Welten. Aber auch: Fylgja eines starken Krieger-Klans.'
 ),
 100),

('wolf', 'Wolf', 'tier', '🐺',
 ARRAY['wolf','wölfe','rudel','wolfsrudel'],
 jsonb_build_object(
   'jungian',  'Wilder Aspekt des Selbst, ungezähmte Lebenskraft. Einsamer Wolf = isoliertes Ich; Rudel = soziale Eingebundenheit.',
   'freudian', 'Wolfsmann-Fall: Vater-Angst, Urszene. Angriffswolf = verdrängte Aggression.',
   'spiritual','Lehrer des Weges. Der Wolf zeigt, wie man dem Instinkt folgt ohne sich zu verlieren.',
   'shamanic', 'Kraftier der Lehrer und Pfadfinder. Wolfsmedizin = Intuition, Treue, Familie.',
   'germanic', 'Fenrir, aber auch Odins Begleiter Geri & Freki. Kraft, die gebunden oder frei sein kann.'
 ),
 101),

('adler', 'Adler', 'tier', '🦅',
 ARRAY['adler','greifvogel','steinadler','seeadler'],
 jsonb_build_object(
   'jungian',  'Geistige Höhe, Über-Sicht, königliches Prinzip. Der Adler sieht das Ganze — Vision-Quest im Traum.',
   'freudian', 'Vater-Imago, Autorität, hohes Über-Ich.',
   'spiritual','Bote der Sonne. Ein Adlertraum = Erinnerung an höhere Perspektive.',
   'shamanic', 'Ober-Welt-Bote. Trägt Gebete zum Großen Geist. Adlerfeder = heiliger Gegenstand.',
   'germanic', 'Hraesvelg — Windbringer, Adler am Yggdrasil. Weitsicht.'
 ),
 102),

('loewe', 'Löwe', 'tier', '🦁',
 ARRAY['löwe','loewe','löwen','loewen','leu'],
 jsonb_build_object(
   'jungian',  'Sonnen-Tier, Ich-Kraft, königliche Mitte. Löwenmut zeigt Kern-Stärke, die bereit ist sich zu zeigen.',
   'freudian', 'Väterliche Autorität, Stolz, Sexualität in bändigender Form.',
   'spiritual','Herz-Chakra-Tier. Der Löwe lehrt, mit ganzem Herzen aufzutreten.',
   'shamanic', 'In Afrika: Hüter der Savanne, Lehrer von Respekt und Territorium.',
   'germanic', 'Selten — aber in späteren Traditionen Symbol für königliche Würde (z.B. Bayern).'
 ),
 103),

('pferd', 'Pferd', 'tier', '🐴',
 ARRAY['pferd','ross','hengst','stute','fohlen','pferde'],
 jsonb_build_object(
   'jungian',  'Körperliche und emotionale Lebenskraft, auch Psyche-Bewegung. Galoppierendes Pferd = starkes Gefühl, das sich Bahn bricht.',
   'freudian', 'Triebkraft, sexuelle Dynamik, auch Vater-Projektion (Kleiner-Hans-Fall).',
   'spiritual','Treuer Gefährte auf dem Weg. Reiten = Meisterung der eigenen Kraft.',
   'shamanic', 'Geister-Pferd trägt Schamanen in andere Welten. Sleipnir-Motiv.',
   'germanic', 'Sleipnir, Odins achtbeiniges Pferd. Reise zwischen Welten. Weißes Pferd = Vorzeichen.'
 ),
 104),

('fisch', 'Fisch', 'tier', '🐟',
 ARRAY['fisch','fische','karpfen','forelle','hecht','schule'],
 jsonb_build_object(
   'jungian',  'Inhalt des Unbewussten, der ans Licht will. Fisch fangen = Einsicht gewinnen.',
   'freudian', 'Phallisch, aber auch Fruchtbarkeit. Fisch-als-Geschenk = orale Befriedigung.',
   'spiritual','Christusfisch, Ichthys — Seele im Wasser des Göttlichen.',
   'shamanic', 'Bote der Tiefen. Fisch-Medizin = Geduld, Stille, Empfang von Wissen aus dem Unbewussten.',
   'germanic', 'Lachs der Weisheit (auch keltisch). Wer ihn fängt/isst, erhält Einsicht.'
 ),
 105),

('eule', 'Eule', 'tier', '🦉',
 ARRAY['eule','eulen','uhu','kauz'],
 jsonb_build_object(
   'jungian',  'Weisheit des Dunklen, nächtliche Einsicht. Die Eule sieht, was das Tageslicht verbirgt.',
   'freudian', 'Heimliches Beobachten (Urszene). Auge der Nacht.',
   'spiritual','Hüterin der Mysterien. Ein Eulentraum kündigt Transformation an.',
   'shamanic', 'Tod-Bote bei manchen Stämmen, Weisheit-Bote bei anderen. Immer: Blick ins Verborgene.',
   'germanic', 'Begleiter von Freya. Nachtwächterin der Götter.'
 ),
 106),

('rabe', 'Rabe / Krähe', 'tier', '🐦‍⬛',
 ARRAY['rabe','raben','krähe','krähen','corvus','kolkrabe'],
 jsonb_build_object(
   'jungian',  'Schatten-Bote, Trickster. Der Rabe bringt, was man nicht hören will — aber braucht.',
   'freudian', 'Verdrängtes, das sich laut meldet. Omen-Angst.',
   'spiritual','Alchemistischer Rabe = Nigredo, Phase der Verdunkelung vor Transformation.',
   'shamanic', 'Magier-Tier. Raben können durch die Zeit fliegen, prophezeien.',
   'germanic', 'Huginn und Muninn, Odins Raben: Gedanke und Erinnerung. Höchste Weisheit-Botschaft.'
 ),
 107),

('hund', 'Hund', 'tier', '🐕',
 ARRAY['hund','hunde','welpe','köter','hündin'],
 jsonb_build_object(
   'jungian',  'Treue Beziehung zum Instinkt, Schwellenhüter zwischen Bewusstem und Unbewusstem.',
   'freudian', 'Gezähmte Triebkraft, Über-Ich in liebevoller Form. Bellender Hund = Wachsamkeits-Angst.',
   'spiritual','Begleiter auf dem Weg. Hund = bedingungslose Liebe, die uns lehrt zu empfangen.',
   'shamanic', 'Schwellen-Tier zum Totenreich (Cerberus, Anubis, auch Fenrir-Linie).',
   'germanic', 'Fylgja vieler Frauenlinien. Der Hund sieht Geister, die Menschen nicht sehen.'
 ),
 108),

('katze', 'Katze', 'tier', '🐈',
 ARRAY['katze','katzen','kater','katzenvieh','mieze'],
 jsonb_build_object(
   'jungian',  'Das Weibliche, Autonome, Unergründliche in der Psyche. Katze kommt und geht wie das Unbewusste selbst.',
   'freudian', 'Weibliches Genital-Symbol (Yoni). Sanfte, aber wildliche Sexualität.',
   'spiritual','Grenzwesen zwischen Welten. Katzen sehen Auren, schlafen dort, wo Heilung nötig ist.',
   'shamanic', 'Unabhängige Krafttier-Medizin. Katze = Mysterium, nicht zu besitzen.',
   'germanic', 'Freyas Katzen ziehen ihren Wagen. Liebe, Sexualität, Zauber.'
 ),
 109),

('spinne', 'Spinne', 'tier', '🕷️',
 ARRAY['spinne','spinnen','kreuzspinne','spinnennetz','spinne-netz'],
 jsonb_build_object(
   'jungian',  'Die Große Mutter als Weberin des Schicksals — kreativ und verschlingend zugleich. Netz = Verstrickung oder kreative Matrix.',
   'freudian', 'Ambivalente Mutter. Angst vor Einverleibung, aber auch umsorgender Schutz.',
   'spiritual','Weberin der Wirklichkeit. Die Spinne lehrt: Jeder Faden zählt.',
   'shamanic', 'Spinnenfrau (Hopi, Navajo) — Schöpferin der Welten durch Weben.',
   'germanic', 'Norne als Schicksalsweberin. Die Spinne spinnt den Lebensfaden.'
 ),
 110),

('schmetterling', 'Schmetterling', 'tier', '🦋',
 ARRAY['schmetterling','schmetterlinge','falter','nachtfalter'],
 jsonb_build_object(
   'jungian',  'Seele in Transformation (griechisch: Psyche = Schmetterling). Verpuppung → Flug.',
   'freudian', 'Reifung, auch sublimierte Sexualität in ihrer leichtesten Form.',
   'spiritual','Zeichen für Wandlung — der Schmetterling im Traum = du bist mitten in Metamorphose.',
   'shamanic', 'Mariposa-Medizin: sanfte Führung durch Wandel, Tanz mit dem Leben.',
   'germanic', 'Selten; später: Symbol für Seele der Verstorbenen, die zurückkommt.'
 ),
 111)

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
--   WHERE category = 'tier' ORDER BY sort_order;
-- ============================================================
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
-- ============================================================
-- v20e: Traumdeutung-Seed – Traum-Aktionen & klassische Motive
-- ============================================================
-- 13 der häufigsten Traum-Themen (Gallup/DreamBank-Statistiken):
-- fliegen, fallen, verfolgt, nackt, zähne-verlieren,
-- auto-unkontrollierbar, prüfung, zu-spät, schwanger, verirren,
-- + 3 Orte/Objekte: haus, tür, treppe.
-- ============================================================

INSERT INTO public.dream_symbols
  (symbol_key, symbol_name, category, emoji, keywords, meanings, sort_order)
VALUES

('fliegen', 'Fliegen', 'aktion', '🕊️',
 ARRAY['fliegen','schweben','abheben','flug','flugtraum'],
 jsonb_build_object(
   'jungian',  'Transzendenz-Motiv — der Geist erhebt sich über Alltagsbeschränkungen. Häufig in Individuations-Phasen.',
   'freudian', 'Sexuelle Erregung symbolisch. Aber auch kindliche Größen-Fantasie (Omnipotenz).',
   'spiritual','Astralreise oder Seelenaufstieg. Aktive Fähigkeit, ins höhere Bewusstsein zu gehen.',
   'shamanic', 'Klassischer Schamanenflug — Reise in die obere Welt. Bewusstes Fliegen = spirituelle Reife.',
   'germanic', 'Odin-Flug in Rabenform. Oder: Walküren-Motiv. Zeichen spiritueller Berufung.'
 ),
 300),

('fallen', 'Fallen / Sturz', 'aktion', '🕳️',
 ARRAY['fallen','fallen-lassen','sturz','runterfallen','abstürzen'],
 jsonb_build_object(
   'jungian',  'Kontrollverlust in einem Lebensbereich. Auch: Rückkehr ins Unbewusste (sinken).',
   'freudian', 'Moralischer Sturz, sexueller Fall, Versuchung. Auch hypnagoge Zuckung beim Einschlafen.',
   'spiritual','Ego-Tod, Loslassen — der Fall kann in Flug übergehen wenn Vertrauen kommt.',
   'shamanic', 'Abstieg in die untere Welt beginnt oft mit Fall-Gefühl. Krafttier holen.',
   'germanic', 'Hel''s Reich ist "unten". Fall kann Ahnen-Kontakt ankündigen.'
 ),
 301),

('verfolgtwerden', 'Verfolgt werden / Jagd', 'aktion', '🏃',
 ARRAY['verfolgt','verfolgung','jagd','jemand-jagt','fliehen','hinterher'],
 jsonb_build_object(
   'jungian',  'Schatten holt dich ein. Das, wovor du fliehst, ist der verdrängte Anteil — stell dich, frage ihn was er will.',
   'freudian', 'Verfolgungs-Ich: Über-Ich oder verdrängter Trieb jagt das Ich. Konflikt ans Licht holen.',
   'spiritual','Lebensbereich, dem du ausweichst. Umkehren, um zu heilen.',
   'shamanic', 'Der Schatten-Teil will zurück. Nicht fliehen, sondern umdrehen und fragen.',
   'germanic', 'Wilde Jagd-Motiv. Odin sucht dich — finde heraus, was er bringt.'
 ),
 302),

('nackt', 'Nacktheit in Öffentlichkeit', 'aktion', '🙈',
 ARRAY['nackt','entblößt','scham','bloß','unbekleidet'],
 jsonb_build_object(
   'jungian',  'Authentizitäts-Thema. Die Persona fehlt — wie viel Echtheit wagst du in der Öffentlichkeit?',
   'freudian', 'Exhibitionistischer Wunsch oder Scham-Konflikt. Gesehen-werden-wollen und -nicht-wollen.',
   'spiritual','Verletzlichkeit als Tor zur Freiheit. "Und sie schämten sich nicht." (Gen 2,25)',
   'shamanic', 'Häutung. Alte Identität löst sich, bevor die neue kommt.',
   'germanic', 'Schwertloses Stehen — innere Stärke statt äußerer Rüstung.'
 ),
 303),

('zaehne_verlieren', 'Zähne verlieren', 'aktion', '🦷',
 ARRAY['zähne','zahn','zähne-verlieren','zahnausfall','zahnverlust','zaehne'],
 jsonb_build_object(
   'jungian',  'Verlust an Durchsetzungskraft, Übergang zu einer neuen Lebensphase (wie beim Kinder-Zahnwechsel).',
   'freudian', 'Kastrations-Angst, Potenz-Verlust. Auch: aggressive Impulse, die man nicht mehr äußern kann.',
   'spiritual','Loslassen alter Identitäten. Schmerz des Übergangs zu etwas Reiferem.',
   'shamanic', 'Kraft-Verlust an einer Stelle. Wo gibst du Energie weg, die du brauchst?',
   'germanic', 'Eidbruch-Omen (Zähne = Beißen = Wort halten).'
 ),
 304),

('auto_unkontrollierbar', 'Auto außer Kontrolle', 'aktion', '🚗',
 ARRAY['auto-kontrolle','bremsen-versagen','auto-fährt-alleine','keine-bremse','lenkrad'],
 jsonb_build_object(
   'jungian',  'Du führst dein Leben nicht mehr — wer/was lenkt dich gerade?',
   'freudian', 'Ich verliert Kontrolle über Es. Triebkraft oder Affekt überfährt das Steuer.',
   'spiritual','Einladung, aufzuwachen und die Zügel wieder zu ergreifen.',
   'shamanic', 'Verlorener Seelen-Anteil steuert. Zurückhol-Arbeit nötig.',
   'germanic', 'Schicksal-Strömung ist stärker als dein Wille gerade. Wyrd annehmen.'
 ),
 305),

('pruefung', 'Prüfung / Examen', 'aktion', '📝',
 ARRAY['prüfung','pruefung','test','examen','klausur','abschlussprüfung'],
 jsonb_build_object(
   'jungian',  'Reife-Prüfung, Initiations-Schwelle. Nicht-Vorbereitet-Sein = Angst, einer neuen Rolle nicht zu genügen.',
   'freudian', 'Über-Ich prüft Ich. Schulmeister-Angst, Elternurteil projiziert.',
   'spiritual','Seelen-Prüfung im aktuellen Lebens-Thema. Vertrauen in eigene Bereitschaft.',
   'shamanic', 'Initiations-Test vom Geist. Du wirst auf dem Weg geprüft.',
   'germanic', 'Heldensage: Aufgabe, die den Charakter formt.'
 ),
 306),

('zu_spaet', 'Zu spät kommen', 'aktion', '⏰',
 ARRAY['zu-spät','zu-spaet','verspätung','rennen','verpassen','zug-weg'],
 jsonb_build_object(
   'jungian',  'Gefühl, im Leben etwas zu verpassen. Konflikt zwischen innerem Tempo und äußerer Zeit.',
   'freudian', 'Wiederholungszwang, Neurotisches Hindernis. Widerstand gegen ein Ziel, das man zu wollen glaubt.',
   'spiritual','Einladung, eigenes Timing zu ehren. "Es gibt kein zu spät im Leben der Seele."',
   'shamanic', 'Fehl-Ausrichtung mit dem natürlichen Rhythmus. Medizin: Stille, Lauschen.',
   'germanic', 'Vergangene Gelegenheit vom Wyrd — neue wird kommen.'
 ),
 307),

('schwanger', 'Schwanger sein', 'aktion', '🤰',
 ARRAY['schwanger','schwangerschaft','bauch-rund','ungeboren','baby-bauch'],
 jsonb_build_object(
   'jungian',  'Etwas Neues wächst in dir — ein Projekt, ein Bewusstseinszustand, eine Lebensphase.',
   'freudian', 'Kreativer Produktions-Wunsch. Auch: tatsächlicher/abgewehrter Kinderwunsch.',
   'spiritual','Seelen-Aufgabe reift heran. Ehrung der inneren Schwangerschaft.',
   'shamanic', 'Große Medizin kommt. Heiligen Raum bewahren für das, was geboren werden will.',
   'germanic', 'Freyas Fruchtbarkeits-Segen. Projekt-Geburt bevorstehend.'
 ),
 308),

('verirren', 'Sich verirren / den Weg verlieren', 'aktion', '🗺️',
 ARRAY['verirren','verlaufen','weg-nicht-finden','orientierungslos','labyrinth-irren'],
 jsonb_build_object(
   'jungian',  'Orientierungsverlust in einer Lebens-Phase. Die alte Karte passt nicht mehr.',
   'freudian', 'Regressionsimpuls, Rückkehr in vor-ödipale Unklarheit.',
   'spiritual','Einladung, äußere Wegweiser loszulassen und innerer Führung zu folgen.',
   'shamanic', 'Der Weg endet, damit ein tieferer beginnen kann. Dem Verlorensein trauen.',
   'germanic', 'Wald der Entscheidung — bevor der Held seinen Platz findet.'
 ),
 309),

('haus', 'Haus', 'ort', '🏠',
 ARRAY['haus','wohnung','heim','zuhause','eigenes-haus'],
 jsonb_build_object(
   'jungian',  'Psyche als Bau. Verschiedene Räume = verschiedene Bewusstseinsbereiche. Keller = Unbewusstes, Dach = Geist.',
   'freudian', 'Körper oder mütterlicher Leib. Zimmer = Aspekte der eigenen Intimität.',
   'spiritual','Seele als Wohnort Gottes. Zustand des Hauses = Zustand des inneren Heiligtums.',
   'shamanic', 'Innerer Kraftort. Bau dein Traum-Haus bewusst aus — es wird dein spiritueller Stützpunkt.',
   'germanic', 'Haus-Geister (Kobolde, Wichtel). Wie behandelst du deinen inneren Raum?'
 ),
 310),

('tuer', 'Tür', 'objekt', '🚪',
 ARRAY['tür','tor','eingang','tuer','türschwelle','schwelle'],
 jsonb_build_object(
   'jungian',  'Übergang zwischen Bewusstseins-Ebenen. Verschlossen = nicht bereit, offen = Einladung.',
   'freudian', 'Vagina-Symbol oder Geburts-Motiv. Eintritt in das Unbewusste.',
   'spiritual','Tor zur nächsten Lebens-Phase. "Ich stehe vor der Tür und klopfe an." (Offb 3,20)',
   'shamanic', 'Schwelle zwischen Welten. Respektvoll bitten, bevor du eintrittst.',
   'germanic', 'Hel-Tor, Thing-Tor. Schwellen-Übergänge sind heilig.'
 ),
 311),

('treppe', 'Treppe', 'objekt', '🪜',
 ARRAY['treppe','stufen','stiege','stufe','aufstieg-treppe','abstieg-treppe'],
 jsonb_build_object(
   'jungian',  'Schrittweise Bewusstseins-Erweiterung (hinauf) oder Integration (hinunter).',
   'freudian', 'Geschlechtsakt-Rhythmus (Auf-Ab). Auch: Hierarchie-Konflikt.',
   'spiritual','Jakobsleiter — Verbindung Erde-Himmel. Der Weg hat Stufen.',
   'shamanic', 'Weltenbaum-Stufen. Jede Etage = eine Bewusstseins-Ebene.',
   'germanic', 'Yggdrasil-Ebenen. Neun Welten, stufenweise erreichbar.'
 ),
 312)

ON CONFLICT (symbol_key) DO UPDATE SET
  symbol_name = EXCLUDED.symbol_name,
  category    = EXCLUDED.category,
  emoji       = EXCLUDED.emoji,
  keywords    = EXCLUDED.keywords,
  meanings    = EXCLUDED.meanings,
  sort_order  = EXCLUDED.sort_order;

-- ============================================================
-- Verifikation:
-- SELECT category, count(*) FROM dream_symbols GROUP BY category;
--   element → 13
--   tier    → 12
--   mensch  → 12
--   aktion  → 10
--   ort     →  1
--   objekt  →  2
-- ============================================================
