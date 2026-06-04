-- v120: Vorhang core tool "Symbol- & Logo-Decoder"
-- Eigene Wissensbasis fuer die Vorhang-Welt (gold): Symbole/Logos mit moeglichen
-- Bedeutungen, Herkunft und Querverweisen in die anderen drei Welten.
--
-- RLS: read-only fuer alle (oeffentlicher Wissens-Content, kein per-User-Bezug),
-- Schreibzugriff nur fuer content_editor+ (Defense-in-Depth; der eigentliche
-- Pflege-Pfad laeuft ueber den Worker per service_role und umgeht RLS).

CREATE TABLE IF NOT EXISTS public.vorhang_symbols (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug            TEXT UNIQUE NOT NULL,              -- stabiler Code, z.B. 'all-seeing-eye'
  name            TEXT NOT NULL,                     -- Anzeigename (Deutsch)
  emoji           TEXT,                              -- optionales Schnell-Visual
  image_url       TEXT,                              -- optionales Symbolbild
  category        TEXT,                              -- z.B. 'Okkult', 'Religion', 'Politik'
  short_meaning   TEXT,                              -- Einzeiler fuer Listenansicht
  meanings        JSONB NOT NULL DEFAULT '[]'::jsonb,-- Array moeglicher Bedeutungen
  origin          TEXT,                              -- Herkunft / historischer Ursprung
  -- Querverweise in die anderen Welten: { "materie": "...", "energie": "...", "ursprung": "..." }
  cross_world_refs JSONB NOT NULL DEFAULT '{}'::jsonb,
  keywords        TEXT[] NOT NULL DEFAULT '{}',      -- Suchbegriffe (Volltext-Hilfe)
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index fuer Kategorie-Filter und alphabetische Sortierung
CREATE INDEX IF NOT EXISTS idx_vorhang_symbols_category
  ON public.vorhang_symbols (category, name);

-- GIN-Index fuer Keyword-Suche
CREATE INDEX IF NOT EXISTS idx_vorhang_symbols_keywords
  ON public.vorhang_symbols USING GIN (keywords);

-- Table-level Privilegien: anon/authenticated duerfen lesen, nur authenticated
-- (eingeloggt) kann schreiben -- die Row-Level-Policy gated dann auf die Rolle.
GRANT SELECT ON TABLE public.vorhang_symbols TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.vorhang_symbols TO authenticated;

ALTER TABLE public.vorhang_symbols ENABLE ROW LEVEL SECURITY;

-- Lesen: oeffentlich (Wissens-Content, unkritisch)
DROP POLICY IF EXISTS vorhang_symbols_public_select ON public.vorhang_symbols;
CREATE POLICY vorhang_symbols_public_select ON public.vorhang_symbols
  FOR SELECT USING (true);

-- Schreiben: nur content_editor+ (Defense-in-Depth)
DROP POLICY IF EXISTS vorhang_symbols_editor_insert ON public.vorhang_symbols;
CREATE POLICY vorhang_symbols_editor_insert ON public.vorhang_symbols
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id::text = auth.uid()::text
        AND role IN ('admin', 'root_admin', 'content_editor')
    )
  );

DROP POLICY IF EXISTS vorhang_symbols_editor_update ON public.vorhang_symbols;
CREATE POLICY vorhang_symbols_editor_update ON public.vorhang_symbols
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id::text = auth.uid()::text
        AND role IN ('admin', 'root_admin', 'content_editor')
    )
  );

DROP POLICY IF EXISTS vorhang_symbols_editor_delete ON public.vorhang_symbols;
CREATE POLICY vorhang_symbols_editor_delete ON public.vorhang_symbols
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id::text = auth.uid()::text
        AND role IN ('admin', 'root_admin', 'content_editor')
    )
  );

-- Seed: einige bekannte Symbole, damit der Decoder direkt befuellt ist.
-- Idempotent via ON CONFLICT (slug).
INSERT INTO public.vorhang_symbols
  (slug, name, emoji, category, short_meaning, meanings, origin, cross_world_refs, keywords)
VALUES
  (
    'all-seeing-eye', 'Allsehendes Auge', '👁️', 'Okkult',
    'Auge in Dreieck/Strahlenkranz -- Symbol fuer Allwissenheit und Beobachtung.',
    '["Goettliche Vorsehung und Allwissenheit","Wachsamkeit und Schutz","In Verschwoerungs-Narrativen: verborgene Kontrolle / Ueberwachung"]'::jsonb,
    'Christliche Ikonografie (Auge der Vorsehung, 17. Jh.); aufgegriffen in Freimaurer-Symbolik und auf der US-Dollarnote.',
    '{"materie":"Ueberwachungsstaat und Panopticon","energie":"Drittes Auge / Ajna-Chakra","ursprung":"Auge des Ra / Horus in aegyptischer Mythologie"}'::jsonb,
    ARRAY['auge','vorsehung','dreieck','pyramide','ueberwachung','freimaurer']
  ),
  (
    'pentagram', 'Pentagramm', '⛤', 'Okkult',
    'Fuenfzackiger Stern -- je nach Ausrichtung Schutz- oder Umkehr-Symbol.',
    '["Schutzsymbol (Spitze nach oben)","Die fuenf Elemente / Sinne","Umgekehrt: Gegen-Symbolik in der Popkultur"]'::jsonb,
    'Antike (Pythagoreer als Zeichen der Gesundheit); spaeter in westlicher Esoterik und Ritualmagie.',
    '{"materie":"Geometrie und Goldener Schnitt","energie":"Fuenf-Elemente-Lehre","ursprung":"Sternkulte fruehzeitlicher Kulturen"}'::jsonb,
    ARRAY['stern','pentagramm','elemente','schutz','esoterik']
  ),
  (
    'ouroboros', 'Ouroboros', '🐍', 'Mythologie',
    'Schlange, die sich in den eigenen Schwanz beisst -- Kreislauf und Ewigkeit.',
    '["Ewige Wiederkehr und Zyklus von Werden/Vergehen","Einheit von Anfang und Ende","Alchemistisches Symbol der Wandlung"]'::jsonb,
    'Altaegypten und Antike; zentrales Bild der Alchemie und Hermetik.',
    '{"materie":"Geschlossene Systeme und Recycling","energie":"Karma und Wiedergeburt","ursprung":"Schoepfung aus dem Chaos / Weltenschlange"}'::jsonb,
    ARRAY['schlange','kreislauf','ewigkeit','alchemie','zyklus']
  ),
  (
    'hexagram', 'Hexagramm', '✡️', 'Religion',
    'Sechszackiger Stern aus zwei Dreiecken -- Verbindung der Gegensaetze.',
    '["Vereinigung von oben und unten / Geist und Materie","Davidstern als juedisches Identitaetssymbol","In Esoterik: Makrokosmos und Mikrokosmos"]'::jsonb,
    'Antikes geometrisches Motiv; seit dem Mittelalter zunehmend als juedisches Symbol.',
    '{"materie":"Kristallgitter und Symmetrie","energie":"Herz-Chakra (Anahata)","ursprung":"Sternsymbolik und Kosmos-Ordnung"}'::jsonb,
    ARRAY['stern','davidstern','dreieck','hexagramm','gegensaetze']
  ),
  (
    'triskele', 'Triskele', '🌀', 'Kultur',
    'Drei rotierende Spiralen/Schenkel -- Bewegung und Dreiheit.',
    '["Werden, Sein, Vergehen","Land, Meer, Himmel","Ewige Bewegung und Fortschritt"]'::jsonb,
    'Keltische und vorkeltische Kunst (z.B. Newgrange); auch in Sizilien und der Bretagne.',
    '{"materie":"Rotation und Dynamik","energie":"Dreifaltigkeit von Koerper/Geist/Seele","ursprung":"Megalith-Kulturen und Sonnenlauf"}'::jsonb,
    ARRAY['spirale','kelten','dreiheit','triskele','bewegung']
  ),
  (
    'eye-of-horus', 'Auge des Horus', '𓂀', 'Mythologie',
    'Aegyptisches Schutzauge -- Heilung, Wahrnehmung und koenigliche Macht.',
    '["Schutz und Heilung","Vollkommene Wahrnehmung","Mathematische Bruchteile (Hekat-System)"]'::jsonb,
    'Altaegypten; Mythos vom verletzten und wiederhergestellten Auge des Horus.',
    '{"materie":"Anatomie des Auges / Optik","energie":"Drittes Auge und Hellsicht","ursprung":"Aegyptische Schoepfungs- und Goettermythen"}'::jsonb,
    ARRAY['horus','auge','aegypten','schutz','udjat']
  )
ON CONFLICT (slug) DO NOTHING;
