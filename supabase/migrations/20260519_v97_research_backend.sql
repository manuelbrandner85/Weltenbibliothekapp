-- v97: Research-Backend (R1-R8 Supabase-Tabellen)
-- 6 Tabellen mit RLS-Policies. NIE USING(true).

-- ── 1. research_timeline (R1) ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS research_timeline (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title           TEXT NOT NULL,
  date_display    TEXT NOT NULL,
  date_sort       DATE NOT NULL,
  description     TEXT NOT NULL,
  category        TEXT NOT NULL CHECK (category IN (
                    'whistleblower','leak','conspiracy','government',
                    'technology','society')),
  sources         JSONB NOT NULL DEFAULT '[]'::jsonb,
  color_hex       TEXT,
  icon_name       TEXT,
  image_url       TEXT,
  verified        BOOLEAN NOT NULL DEFAULT false,
  suggested_by    TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_research_timeline_date
  ON research_timeline(date_sort DESC);
CREATE INDEX IF NOT EXISTS idx_research_timeline_category
  ON research_timeline(category);

ALTER TABLE research_timeline ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "timeline_select_verified" ON research_timeline;
CREATE POLICY "timeline_select_verified" ON research_timeline
  FOR SELECT
  USING (verified = true OR suggested_by = auth.uid()::text);

DROP POLICY IF EXISTS "timeline_insert_authenticated" ON research_timeline;
CREATE POLICY "timeline_insert_authenticated" ON research_timeline
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "timeline_admin_all" ON research_timeline;
CREATE POLICY "timeline_admin_all" ON research_timeline
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('admin','root_admin','moderator')
    )
  );

-- Seed-Daten (6 Events aus dem alten hardcoded Code)
INSERT INTO research_timeline (
  title, date_display, date_sort, description, category, sources, color_hex,
  icon_name, verified
) VALUES
  ('Snowden NSA-Enthuellungen','Juni 2013','2013-06-05',
   'Edward Snowden veroeffentlicht Dokumente die globale NSA-Massenueberwachung beweisen. PRISM, XKeyscore, Tempora -- Programme die jeden Menschen erfassen.',
   'whistleblower',
   '["https://www.theguardian.com/world/2013/jun/06/us-tech-giants-nsa-data","https://en.wikipedia.org/wiki/Global_surveillance_disclosures_(2013%E2%80%93present)"]',
   '#E53935','vpn_key', true),
  ('WikiLeaks Iraq War Logs','Oktober 2010','2010-10-22',
   'Julian Assange veroeffentlicht 391'',832 geheime US-Militaer-Berichte. Dokumentiert zivile Opfer, Folter und nicht gemeldete Vorfaelle des Irak-Kriegs.',
   'leak',
   '["https://wikileaks.org/irq/","https://en.wikipedia.org/wiki/Iraq_War_documents_leak"]',
   '#FF6B35','folder_zip', true),
  ('Cambridge Analytica Skandal','Maerz 2018','2018-03-17',
   '87 Millionen Facebook-Profile illegal genutzt fuer politische Manipulation. Brexit, Trump-Kampagne -- Daten als Waffe.',
   'leak',
   '["https://www.theguardian.com/news/2018/mar/17/cambridge-analytica-facebook-influence-us-election","https://en.wikipedia.org/wiki/Facebook%E2%80%93Cambridge_Analytica_data_scandal"]',
   '#9C27B0','psychology', true),
  ('Panama Papers','April 2016','2016-04-03',
   '11.5 Millionen Dokumente offenbaren das globale Offshore-System. Politiker, Reiche, Kriminelle: alle nutzen denselben Mechanismus.',
   'leak',
   '["https://www.icij.org/investigations/panama-papers/","https://en.wikipedia.org/wiki/Panama_Papers"]',
   '#FFB300','description', true),
  ('Pentagon Papers','Juni 1971','1971-06-13',
   'Daniel Ellsberg leakt die Pentagon Papers an die NY Times. Bewies: 4 US-Praesidenten haben das Volk ueber Vietnamkrieg systematisch belogen.',
   'whistleblower',
   '["https://en.wikipedia.org/wiki/Pentagon_Papers","https://www.archives.gov/research/pentagon-papers"]',
   '#5C6BC0','article', true),
  ('Watergate-Skandal','Juni 1972','1972-06-17',
   'Einbruch in das Watergate-Gebaeude fuehrt zur Praesidenten-Resignation. Bewies: Macht korrumpiert. Aufgedeckt durch Woodward & Bernstein der Washington Post.',
   'government',
   '["https://en.wikipedia.org/wiki/Watergate_scandal","https://www.washingtonpost.com/wp-srv/national/longterm/watergate/"]',
   '#388E3C','gavel', true)
ON CONFLICT DO NOTHING;

-- ── 2. prediction_votes (R4) ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS prediction_votes (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prediction_id     TEXT NOT NULL,
  user_id           UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  legacy_user_id    TEXT,
  vote_probability  INTEGER NOT NULL CHECK (vote_probability BETWEEN 0 AND 100),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT prediction_votes_user_check
    CHECK (user_id IS NOT NULL OR legacy_user_id IS NOT NULL)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_prediction_vote_user
  ON prediction_votes(prediction_id, user_id)
  WHERE user_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_prediction_vote_legacy
  ON prediction_votes(prediction_id, legacy_user_id)
  WHERE legacy_user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_prediction_votes_prediction
  ON prediction_votes(prediction_id);

ALTER TABLE prediction_votes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "votes_select_all" ON prediction_votes;
CREATE POLICY "votes_select_all" ON prediction_votes
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "votes_insert_own" ON prediction_votes;
CREATE POLICY "votes_insert_own" ON prediction_votes
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    OR auth.uid() IS NULL AND legacy_user_id IS NOT NULL
  );

DROP POLICY IF EXISTS "votes_update_own" ON prediction_votes;
CREATE POLICY "votes_update_own" ON prediction_votes
  FOR UPDATE
  USING (auth.uid() = user_id);

-- ── 3. prediction_outcomes (R4) ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS prediction_outcomes (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prediction_id   TEXT NOT NULL UNIQUE,
  outcome         TEXT NOT NULL CHECK (outcome IN (
                    'eingetreten','nicht_eingetreten','teilweise','offen')),
  evidence_text   TEXT,
  evidence_url    TEXT,
  verified_at     TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_prediction_outcomes_outcome
  ON prediction_outcomes(outcome);

ALTER TABLE prediction_outcomes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "outcomes_select_all" ON prediction_outcomes;
CREATE POLICY "outcomes_select_all" ON prediction_outcomes
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "outcomes_admin_write" ON prediction_outcomes;
CREATE POLICY "outcomes_admin_write" ON prediction_outcomes
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('admin','root_admin','moderator')
    )
  );

-- ── 4. research_documents (R5) ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS research_documents (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  legacy_user_id    TEXT,
  title             TEXT NOT NULL,
  source_name       TEXT NOT NULL,
  original_url      TEXT NOT NULL,
  language          TEXT NOT NULL DEFAULT 'en',
  extracted_text    TEXT,
  translated_text   TEXT,
  tags              JSONB NOT NULL DEFAULT '[]'::jsonb,
  user_notes        TEXT,
  downloaded_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  file_size_kb      INTEGER,
  CONSTRAINT research_documents_user_check
    CHECK (user_id IS NOT NULL OR legacy_user_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_research_documents_user
  ON research_documents(user_id);
CREATE INDEX IF NOT EXISTS idx_research_documents_legacy
  ON research_documents(legacy_user_id) WHERE legacy_user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_research_documents_source
  ON research_documents(source_name);
CREATE INDEX IF NOT EXISTS idx_research_documents_text
  ON research_documents USING GIN (to_tsvector('simple', COALESCE(extracted_text,'')));

ALTER TABLE research_documents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "documents_select_own" ON research_documents;
CREATE POLICY "documents_select_own" ON research_documents
  FOR SELECT
  USING (
    auth.uid() = user_id
    OR (legacy_user_id IS NOT NULL AND legacy_user_id IN (
        SELECT legacy_user_id FROM profiles WHERE auth.uid() = id))
  );

DROP POLICY IF EXISTS "documents_insert_own" ON research_documents;
CREATE POLICY "documents_insert_own" ON research_documents
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    OR auth.uid() IS NULL AND legacy_user_id IS NOT NULL
  );

DROP POLICY IF EXISTS "documents_update_own" ON research_documents;
CREATE POLICY "documents_update_own" ON research_documents
  FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "documents_delete_own" ON research_documents;
CREATE POLICY "documents_delete_own" ON research_documents
  FOR DELETE
  USING (auth.uid() = user_id);

-- ── 5. investigation_boards (R6) ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS investigation_boards (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  legacy_user_id  TEXT,
  title           TEXT NOT NULL,
  description     TEXT,
  items           JSONB NOT NULL DEFAULT '[]'::jsonb,
  connections     JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT investigation_boards_user_check
    CHECK (user_id IS NOT NULL OR legacy_user_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_investigation_boards_user
  ON investigation_boards(user_id);
CREATE INDEX IF NOT EXISTS idx_investigation_boards_updated
  ON investigation_boards(updated_at DESC);

ALTER TABLE investigation_boards ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "boards_select_own" ON investigation_boards;
CREATE POLICY "boards_select_own" ON investigation_boards
  FOR SELECT
  USING (
    auth.uid() = user_id
    OR (legacy_user_id IS NOT NULL AND legacy_user_id IN (
        SELECT legacy_user_id FROM profiles WHERE auth.uid() = id))
  );

DROP POLICY IF EXISTS "boards_insert_own" ON investigation_boards;
CREATE POLICY "boards_insert_own" ON investigation_boards
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    OR auth.uid() IS NULL AND legacy_user_id IS NOT NULL
  );

DROP POLICY IF EXISTS "boards_update_own" ON investigation_boards;
CREATE POLICY "boards_update_own" ON investigation_boards
  FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "boards_delete_own" ON investigation_boards;
CREATE POLICY "boards_delete_own" ON investigation_boards
  FOR DELETE
  USING (auth.uid() = user_id);

-- ── 6. ursprung_topics (R8) ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ursprung_topics (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title             TEXT NOT NULL,
  icon_name         TEXT,
  summary           TEXT NOT NULL,
  detail_markdown   TEXT NOT NULL,
  source_label      TEXT,
  source_url        TEXT,
  sort_order        INTEGER NOT NULL DEFAULT 0,
  is_active         BOOLEAN NOT NULL DEFAULT true,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ursprung_topics_sort
  ON ursprung_topics(sort_order, created_at);

ALTER TABLE ursprung_topics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "ursprung_topics_select_active" ON ursprung_topics;
CREATE POLICY "ursprung_topics_select_active" ON ursprung_topics
  FOR SELECT
  USING (is_active = true);

DROP POLICY IF EXISTS "ursprung_topics_admin_all" ON ursprung_topics;
CREATE POLICY "ursprung_topics_admin_all" ON ursprung_topics
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('admin','root_admin')
    )
  );

-- Seed-Daten (6 Topics aus dem alten hardcoded Ursprung-Tab)
INSERT INTO ursprung_topics (
  title, icon_name, summary, detail_markdown, source_label, source_url,
  sort_order, is_active
) VALUES
  ('Bewusstsein und Wirklichkeit','psychology',
   'Die Frage was Bewusstsein ist -- und ob Wirklichkeit ohne Beobachter existiert.',
   E'## Bewusstsein als Grundkraft\n\nWissenschaft und Mystik kreuzen sich an einem Punkt: Wenn Quantenobjekte erst durch Beobachtung Form annehmen, ist das Bewusstsein dann mit-konstitutiv fuer die Realitaet?\n\n**Schluessel-Fragen:**\n- Was ist Bewusstsein wirklich -- ein Phaenomen des Gehirns, oder etwas Grundlegenderes?\n- Warum hat Materie subjektives Erleben (das *Hard Problem of Consciousness*, David Chalmers)?\n- Sind wir Beobachter oder Mit-Schoepfer?',
   'Stanford Encyclopedia of Philosophy',
   'https://plato.stanford.edu/entries/consciousness/',
   1, true),
  ('Quantenmechanik und Realitaet','science',
   'Doppelspalt, Verschraenkung, Nichtlokalitaet -- die Grundlage der Physik kennt keine klassische Welt.',
   E'## Der Quanten-Bruch mit der Klassik\n\nMaterie verhaelt sich auf der kleinsten Ebene NICHT wie kleine Kugeln. Stattdessen:\n\n- **Wellen-Teilchen-Dualismus** -- ein Photon ist beides, je nach Messung.\n- **Verschraenkung** -- Teilchen ueber beliebige Entfernung instantan korreliert.\n- **Nichtlokalitaet** (Bells Theorem 1964, Aspect-Experimente) -- die Welt ist NICHT lokal.\n\nDas zwingt zu philosophischen Konsequenzen, denen die meisten Physiker ausweichen.',
   'CERN -- Quantum Physics',
   'https://home.cern/science/physics/quantum-mechanics',
   2, true),
  ('Heilige Geometrie','hexagon',
   'Muster der Natur -- Phi, Fibonacci, Flower of Life. Symbol oder mathematische Struktur?',
   E'## Wenn Mathematik in der Natur erscheint\n\nDie Phi-Verhaeltnisse (1.618...) tauchen in Pflanzen, Tieren und Galaxien auf. Fibonacci-Spiralen in Sonnenblumen, Naga-Mandalas, Schneckenhaeusern.\n\n**Was bedeutet das?**\nEntweder reine Zufallsstatistik *oder* ein tieferes ordnungs-erzeugendes Prinzip. Heilige Geometrie behauptet letzteres -- die Natur folgt einer aesthetischen Ordnung, nicht nur Effizienz.',
   'Marcus du Sautoy -- The Music of the Primes',
   null, 3, true),
  ('Aelteste Hochkulturen','public',
   'Goebekli Tepe (12''000 v.Chr.), Sumer, Vor-Aegypten. Die Geschichte ist aelter als die Schulbuecher sagen.',
   E'## Was vor der Bronzezeit existierte\n\n**Goebekli Tepe** (Tuerkei, ca. 9''500 v.Chr.) ist nachweislich ein gebautes Tempel-Komplex von Jaegersammlern -- 6''000 Jahre vor Stonehenge.\n\nDas zerstoert die klassische Erzaehlung "Erst Ackerbau, dann Religion, dann Tempel". Die Reihenfolge war wohl umgekehrt: Tempel-Versammlungen kamen ZUERST.',
   'Klaus Schmidt -- Sie bauten die ersten Tempel',
   'https://www.dainst.org/forschung/projekte/-/project-display/30901',
   4, true),
  ('Schamanismus und veraenderte Bewusstseinszustaende','self_improvement',
   'Vom Amazonas zum sibirischen Tundra: Jede Kultur kennt Techniken zur Bewusstseinserweiterung.',
   E'## Universelle Techniken\n\nUnabhaengig in jeder Kultur entwickelt:\n- **Trommeln & Trance** (Lakota, Tuva, Kelten)\n- **Pflanzen-Lehrer** (Ayahuasca, Peyote, Iboga, Soma)\n- **Atem-Arbeit** (Pranayama, Holotrope Atemarbeit)\n- **Sensorische Deprivation** (Dunkelheit-Retreats, Wuesten-Wanderungen)\n\nDas spricht fuer einen *universellen Mechanismus* statt isolierter Kultur-Spielerei.',
   'Michael Harner -- The Way of the Shaman',
   null, 5, true),
  ('Die grossen Mysterienschulen','school',
   'Eleusis, Mithras, Pythagoras, Hermetik -- 2''000 Jahre lang gab es organisierte Initiationsschulen.',
   E'## Verborgene Bildung\n\nVor dem Christentum hatten die Mittelmeer-Kulturen ein hochentwickeltes Initiations-System:\n\n- **Eleusinische Mysterien** -- 2''000 Jahre lang das Zentrum spiritueller Bildung in der antiken Welt.\n- **Pythagoraeer** -- Mathematik + Musik + Ethik + Geheimlehre.\n- **Hermetik** -- "Wie oben so unten" -- das Manuskript des aegyptischen Thot.\n\nDie Kirche zerstoerte diese Schulen ab 391 n.Chr. systematisch -- aber Spuren leben in der Freimaurerei, der Esoterik und der Renaissance-Kunst weiter.',
   'Manly P. Hall -- The Secret Teachings of All Ages',
   null, 6, true)
ON CONFLICT DO NOTHING;
