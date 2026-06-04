-- v121: Ursprung core tool "Zeitleiste der Menschheitsursprünge"
-- Interaktive Timeline mit Schoepfungsmythen, Urkulturen und offenen Fragen.
-- Gleiche RLS-Logik wie vorhang_symbols (v120): oeffentlich lesbar,
-- Schreibzugriff nur content_editor+.

CREATE TABLE IF NOT EXISTS public.ursprung_timeline (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug            TEXT UNIQUE NOT NULL,
  sort_order      INTEGER NOT NULL DEFAULT 0,        -- chronologische Reihenfolge
  era             TEXT,                              -- Epochen-Label
  year_label      TEXT,                              -- Anzeige, z.B. 'ca. 3000 v. Chr.'
  title           TEXT NOT NULL,
  -- Kategorie steuert Filter + Farbe in der UI.
  category        TEXT NOT NULL DEFAULT 'urkultur'
    CHECK (category IN ('schoepfungsmythos', 'urkultur', 'offene_frage')),
  summary         TEXT,
  details         TEXT,
  -- Querverweise in die anderen Welten: { "materie":"...", "energie":"...", "vorhang":"..." }
  cross_world_refs JSONB NOT NULL DEFAULT '{}'::jsonb,
  keywords        TEXT[] NOT NULL DEFAULT '{}',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ursprung_timeline_order
  ON public.ursprung_timeline (sort_order);
CREATE INDEX IF NOT EXISTS idx_ursprung_timeline_category
  ON public.ursprung_timeline (category, sort_order);

GRANT SELECT ON TABLE public.ursprung_timeline TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.ursprung_timeline TO authenticated;

ALTER TABLE public.ursprung_timeline ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ursprung_timeline_public_select ON public.ursprung_timeline;
CREATE POLICY ursprung_timeline_public_select ON public.ursprung_timeline
  FOR SELECT USING (true);

DROP POLICY IF EXISTS ursprung_timeline_editor_insert ON public.ursprung_timeline;
CREATE POLICY ursprung_timeline_editor_insert ON public.ursprung_timeline
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles
      WHERE id::text = auth.uid()::text
        AND role IN ('admin', 'root_admin', 'content_editor')));

DROP POLICY IF EXISTS ursprung_timeline_editor_update ON public.ursprung_timeline;
CREATE POLICY ursprung_timeline_editor_update ON public.ursprung_timeline
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles
      WHERE id::text = auth.uid()::text
        AND role IN ('admin', 'root_admin', 'content_editor')));

DROP POLICY IF EXISTS ursprung_timeline_editor_delete ON public.ursprung_timeline;
CREATE POLICY ursprung_timeline_editor_delete ON public.ursprung_timeline
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles
      WHERE id::text = auth.uid()::text
        AND role IN ('admin', 'root_admin', 'content_editor')));

-- Seed: Querschnitt durch alle drei Kategorien, chronologisch geordnet.
INSERT INTO public.ursprung_timeline
  (slug, sort_order, era, year_label, title, category, summary, details, cross_world_refs, keywords)
VALUES
  ('urknall', 10, 'Kosmischer Ursprung', 'vor ca. 13,8 Mrd. Jahren',
   'Der Urknall', 'offene_frage',
   'Standardmodell: Raum, Zeit und Materie entstehen aus einem extrem dichten Anfangszustand.',
   'Die Kosmologie beschreibt die Expansion ab einem Anfangszustand -- aber WAS davor war oder warum es ueberhaupt etwas gibt, bleibt offen. Schnittstelle von Physik und Metaphysik.',
   '{"materie":"Kosmologie und Big-Bang-Physik","energie":"Schoepfung aus dem Einen / Urschwingung","vorhang":"Wer definiert die Deutungshoheit ueber den Anfang?"}'::jsonb,
   ARRAY['urknall','kosmos','anfang','physik']),
  ('enuma-elish', 20, 'Fruehe Hochkulturen', 'ca. 1800-1100 v. Chr. (Niederschrift)',
   'Enuma Elish (Babylon)', 'schoepfungsmythos',
   'Babylonischer Schoepfungsmythos: Ordnung entsteht aus dem Kampf gegen das Urchaos (Tiamat).',
   'Eines der aeltesten ueberlieferten Schoepfungsepen. Marduk erschlaegt die Chaosgoettin Tiamat und formt aus ihr die Welt -- ein wiederkehrendes Motiv: Kosmos aus Chaos.',
   '{"materie":"Mythos vs. wissenschaftliche Kosmogonie","energie":"Urchaos und Manifestation der Ordnung","vorhang":"Schoepfungsmythen als Herrschaftslegitimation"}'::jsonb,
   ARRAY['babylon','tiamat','marduk','schoepfung','mythos']),
  ('genesis', 30, 'Fruehe Hochkulturen', 'ca. 6.-5. Jh. v. Chr. (Niederschrift)',
   'Genesis (Hebraeische Bibel)', 'schoepfungsmythos',
   'Schoepfung in sieben Tagen; der Mensch als Ebenbild, eingesetzt ueber die Schoepfung.',
   'Praegt das abendlaendische Menschen- und Weltbild bis heute. Parallelen und Unterschiede zu aelteren mesopotamischen Mythen sind ein zentrales Forschungsthema.',
   '{"materie":"Wissenschaft vs. Schoepfungsglaube","energie":"Wort/Logos als schoepferische Kraft","vorhang":"Deutungsmacht religioeser Institutionen"}'::jsonb,
   ARRAY['genesis','bibel','schoepfung','sieben tage']),
  ('goebekli-tepe', 40, 'Jungsteinzeit', 'ca. 9600 v. Chr.',
   'Goebekli Tepe', 'urkultur',
   'Aeltestes bekanntes monumentales Heiligtum -- errichtet von Jaegern und Sammlern.',
   'Stellt die alte Annahme in Frage, dass erst Ackerbau und Sesshaftigkeit Tempel ermoeglichten. Hier kam moeglicherweise der Kult zuerst -- und die Siedlung danach.',
   '{"materie":"Archaeologie und Datierung","energie":"Heilige Orte und Ritual","vorhang":"Verschuettetes Wissen ueber unsere Vergangenheit"}'::jsonb,
   ARRAY['goebekli tepe','anatolien','tempel','jungsteinzeit']),
  ('sumer', 50, 'Fruehe Hochkulturen', 'ab ca. 4000 v. Chr.',
   'Sumer / Mesopotamien', 'urkultur',
   'Erste Staedte, Schrift (Keilschrift), Rad und Verwaltung -- "Wiege der Zivilisation".',
   'Mit der Schrift beginnt die aufgezeichnete Geschichte. Sumerische Koenigslisten und Mythen (Anunnaki) sind Gegenstand sowohl seriooeser Forschung als auch alternativer Deutungen.',
   '{"materie":"Entstehung von Staat und Buerokratie","energie":"Goetterwelt und kosmische Ordnung","vorhang":"Anunnaki-Narrative und ihre Quellenkritik"}'::jsonb,
   ARRAY['sumer','keilschrift','mesopotamien','anunnaki']),
  ('aegypten', 60, 'Fruehe Hochkulturen', 'ab ca. 3100 v. Chr.',
   'Altes Aegypten', 'urkultur',
   'Vereinigung der Reiche, Pyramidenbau, hochentwickelte Jenseits- und Schoepfungslehren.',
   'Mehrere parallele Schoepfungsmythen (Heliopolis, Memphis, Hermopolis). Die praezise Bautechnik der Pyramiden naehrt bis heute offene Fragen und Spekulationen.',
   '{"materie":"Ingenieurskunst der Pyramiden","energie":"Auge des Horus / drittes Auge","vorhang":"Symbolik und verborgenes Wissen"}'::jsonb,
   ARRAY['aegypten','pyramiden','horus','schoepfung']),
  ('indus', 70, 'Fruehe Hochkulturen', 'ca. 2600-1900 v. Chr.',
   'Indus-Kultur', 'urkultur',
   'Hochentwickelte Staedte (Mohenjo-daro) mit Kanalisation -- und eine bis heute unentzifferte Schrift.',
   'Eine der drei fruehesten Flusskulturen. Ihre Schrift ist nicht entschluesselt, ihr Niedergang nicht abschliessend geklaert -- ein echtes offenes Raetsel.',
   '{"materie":"Stadtplanung und Hydrotechnik","energie":"fruehe Yoga-/Meditationsdarstellungen","vorhang":"unentzifferte Schrift als Wissensluecke"}'::jsonb,
   ARRAY['indus','mohenjo-daro','harappa','schrift']),
  ('ursprung-sprache', 80, 'Offene Fragen', 'unbekannt',
   'Ursprung der Sprache', 'offene_frage',
   'Wann und wie entstand menschliche Sprache? Eine der haertesten offenen Fragen der Wissenschaft.',
   'Sprache hinterlaesst keine Fossilien. Theorien reichen von gradueller Evolution bis zu einem ploetzlichen kognitiven Sprung. Eng verknuepft mit der Frage nach dem Ursprung des Bewusstseins.',
   '{"materie":"Linguistik und Kognitionsforschung","energie":"Wort als schoepferische Schwingung","vorhang":"Sprache als Werkzeug der Macht"}'::jsonb,
   ARRAY['sprache','ursprung','kognition','evolution']),
  ('ursprung-bewusstsein', 90, 'Offene Fragen', 'unbekannt',
   'Ursprung des Bewusstseins', 'offene_frage',
   'Warum gibt es subjektives Erleben? Das "harte Problem" des Bewusstseins ist ungeloest.',
   'Ob Bewusstsein aus dem Gehirn emergiert oder fundamentaler ist, wird in Philosophie und Naturwissenschaft kontrovers diskutiert -- der thematische Kern der Ursprung-Welt.',
   '{"materie":"Neurowissenschaft des Gehirns","energie":"Bewusstsein als Grund allen Seins","vorhang":"Wer kontrolliert die Deutung des Geistes?"}'::jsonb,
   ARRAY['bewusstsein','hard problem','geist','philosophie'])
ON CONFLICT (slug) DO NOTHING;
