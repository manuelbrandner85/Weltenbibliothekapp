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
