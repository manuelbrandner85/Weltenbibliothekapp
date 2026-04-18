-- ============================================================
-- v19: Spirit-Tools Phase 1 – Mondkalender (Tool 8)
-- ============================================================
-- Legt die Tabellen für den neuen vollständigen Mondkalender an.
-- Folgt dem v18-Pattern: RLS + GRANT anon/authenticated +
-- DEFAULT PRIVILEGES für zukünftige Objekte.
-- ============================================================

-- 1. moon_calendar (optionaler Cache, öffentlich lesbar) -------
CREATE TABLE IF NOT EXISTS public.moon_calendar (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  calendar_date DATE NOT NULL UNIQUE,
  moon_phase TEXT NOT NULL,
  moon_phase_progress DOUBLE PRECISION,
  moon_sign TEXT NOT NULL,
  moon_element TEXT,
  is_void_of_course BOOLEAN DEFAULT false,
  void_start TIME,
  void_end TIME,
  recommendations JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_moon_calendar_date ON public.moon_calendar(calendar_date);

-- 2. moon_rituals (statisch, öffentlich lesbar) ----------------
CREATE TABLE IF NOT EXISTS public.moon_rituals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  moon_phase TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  steps TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0
);

-- 3. moon_intentions (pro User, ein Eintrag pro Zyklus) --------
CREATE TABLE IF NOT EXISTS public.moon_intentions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cycle_start DATE NOT NULL,
  intention TEXT NOT NULL,
  new_moon_reflection TEXT,
  full_moon_reflection TEXT,
  cycle_complete BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_moon_intentions_user ON public.moon_intentions(user_id, cycle_start DESC);

-- 4. moon_journal (pro User, chronologisch) --------------------
CREATE TABLE IF NOT EXISTS public.moon_journal (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  entry_date DATE NOT NULL,
  moon_phase TEXT,
  moon_sign TEXT,
  content TEXT NOT NULL,
  ritual_completed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_moon_journal_user ON public.moon_journal(user_id, entry_date DESC);

-- 5. RLS aktivieren ---------------------------------------------
ALTER TABLE public.moon_calendar     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moon_rituals      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moon_intentions   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moon_journal      ENABLE ROW LEVEL SECURITY;

-- 6. Policies (idempotent) --------------------------------------
DROP POLICY IF EXISTS "Mondkalender öffentlich"         ON public.moon_calendar;
CREATE POLICY "Mondkalender öffentlich" ON public.moon_calendar
  FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Rituale öffentlich"              ON public.moon_rituals;
CREATE POLICY "Rituale öffentlich" ON public.moon_rituals
  FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "User sieht eigene Intentionen"   ON public.moon_intentions;
CREATE POLICY "User sieht eigene Intentionen" ON public.moon_intentions
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "User sieht eigenes Mond-Journal" ON public.moon_journal;
CREATE POLICY "User sieht eigenes Mond-Journal" ON public.moon_journal
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 7. Table-Privileges (PostgREST braucht explizite GRANTs) -----
GRANT SELECT                         ON public.moon_calendar   TO anon, authenticated;
GRANT SELECT                         ON public.moon_rituals    TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.moon_intentions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.moon_journal    TO authenticated;

-- 8. Seed: Die 8 Mondphasen-Rituale (Deutsch) ------------------
INSERT INTO public.moon_rituals (moon_phase, title, description, steps, sort_order) VALUES
('new_moon',
 'Neumond-Ritual: Intentionen setzen',
 'Der Neumond ist der Beginn eines neuen Mondzyklus. In dieser Dunkelheit liegt die Kraft des Anfangs — ein unbeschriebenes Blatt für das, was du in den kommenden 28 Tagen in dein Leben rufen möchtest.',
 '1. Reinige deinen Raum (Fenster öffnen, Räuchern mit Salbei oder Palo Santo, Klangschale).
2. Schaffe einen Altar: Kerze (schwarz oder weiß), ein Glas Wasser, dein Journal, einen Stift.
3. Zünde die Kerze an und atme sieben Atemzüge tief in den Bauch.
4. Schreibe am oberen Blattrand: "In diesem Mondzyklus rufe ich in mein Leben:"
5. Formuliere 3–5 Intentionen in der Gegenwartsform ("Ich bin…", "Ich habe…", nicht "Ich will…").
6. Lies die Intentionen laut vor, in die Kerzenflamme hinein.
7. Falte den Zettel und lege ihn unter das Wasserglas. Lass ihn dort bis zum nächsten Vollmond.
8. Danke dem Mond und lösche die Kerze (nicht pusten — mit den Fingern oder einem Löffel).',
 1),

('waxing_crescent',
 'Zunehmende Sichel: Nähre deine Saat',
 'Die ersten zarten Mondtage. Deine Intentionen sind gesetzt, jetzt geht es ums bewusste Tun — kleine, kraftvolle Schritte in Richtung der Vision.',
 '1. Lies morgens deine Neumond-Intention erneut.
2. Wähle EINE Handlung für heute, die diese Intention nährt.
3. Visualisierung (5 min): Stell dir vor, wie deine Intention bereits Wirklichkeit ist. Fühle es im Körper.
4. Sprich eine Affirmation laut aus: "Ich wachse im Einklang mit dem zunehmenden Licht."',
 2),

('first_quarter',
 'Erstes Viertel: Durch den Widerstand',
 'Das Halbmond-Licht steht quer zur Sonne — Spannung und Entscheidung. Wo stößt du an Grenzen? Wo fordert dich das Leben zum Wachsen?',
 '1. Mach eine Liste: Welche Hindernisse sind zwischen mir und meiner Neumond-Intention aufgetaucht?
2. Wähle EINES davon aus. Schreibe einen konkreten Umgang auf — nicht Vermeidung, sondern Begegnung.
3. Dehn- oder Bewegungsübung (10 min), um körperliche Spannung zu lösen.
4. Erinnere dich: "Widerstand ist der Weg." (nach Ryan Holiday)',
 3),

('waxing_gibbous',
 'Zunehmender Mond: Verfeinere und vertraue',
 'Kurz vor Vollmond. Die Energie ist stark, aber noch nicht am Peak. Zeit, letzte Anpassungen vorzunehmen und Vertrauen zu üben.',
 '1. Überprüfe deine Neumond-Intention: Was brauchst du noch, um sie voll zu leben?
2. Mache eine kleine Verbesserung (ein Gespräch, eine E-Mail, eine Entscheidung).
3. Abendmeditation (10 min) mit Fokus auf Dankbarkeit für das, was bereits da ist.',
 4),

('full_moon',
 'Vollmond-Ritual: Loslassen und feiern',
 'Der Höhepunkt des Mondzyklus. Volles Licht, volle Sicht, volle Kraft. Zeit, das zu feiern, was manifestiert wurde — und das loszulassen, was nicht mehr dient.',
 '1. Finde einen Platz draußen im Mondlicht (oder am Fenster).
2. Hole deinen Neumond-Zettel hervor. Lies ihn laut. Was hat sich manifestiert? Was nicht — und warum?
3. Nimm ein zweites Blatt. Schreibe: "Ich lasse los:" — und alles, was dich blockiert (Ängste, Groll, alte Muster).
4. Verbrenne diesen Zettel sicher (Feuerschale, Kerze, Herd). Sprich: "Ich gebe dich dem Mond und dem Feuer zurück."
5. Trinke das Wasser vom Neumond-Altar als Mondwasser.
6. Schreibe drei Dinge in dein Journal, für die du dankbar bist.
7. Mondbad: Stell einen Kristall (Bergkristall, Mondstein) übers Nacht ins Mondlicht zum Aufladen.',
 5),

('waning_gibbous',
 'Abnehmender Mond: Teile deine Weisheit',
 'Die Fülle des Vollmonds wirkt noch nach. Zeit, zu geben — Wissen, Zuhören, Liebe — ohne etwas zurück zu erwarten.',
 '1. Schreibe einer Person eine ehrliche Wertschätzung (Nachricht, Brief, Gespräch).
2. Teile etwas, das du gelernt hast — mit jemandem, der davon profitiert.
3. Abendreflexion: "Was habe ich in diesem Zyklus gelernt, das ich weitergeben kann?"',
 6),

('last_quarter',
 'Letztes Viertel: Reinigen und entrümpeln',
 'Das zweite Halbmond-Licht. Die Zeit der Entrümpelung — innerlich und äußerlich. Was trägst du noch mit dir, das du am Ende des Zyklus zurücklassen kannst?',
 '1. Wähle einen Bereich (Schublade, Inbox, Kalender, Beziehung) und entrümple 20 Minuten bewusst.
2. Vergebe dir oder einer anderen Person innerlich (schriftlich oder still): "Ich entlasse dich aus meiner Erwartung."
3. Reinigungsbad: Salzwasser-Fußbad oder Dusche mit der Intention, alles abzuwaschen, was nicht mehr zu dir gehört.',
 7),

('waning_crescent',
 'Abnehmende Sichel: Ruhen und lauschen',
 'Die dunkelste Zeit vor dem neuen Anfang. Keine Kraft, die drückt — Einladung, zu ruhen, zu träumen, zu lauschen. Deine Intuition ist jetzt besonders klar.',
 '1. Gönn dir heute mindestens 60 Minuten ganz ohne Bildschirm und Input.
2. Ein Bad, ein Spaziergang, ein Tee in Stille.
3. Offene Frage an dich selbst, vor dem Einschlafen: "Was möchte beim nächsten Neumond durch mich entstehen?"
4. Traum-Journal bereitlegen — heute könnten besonders klare Träume kommen.',
 8);

-- ============================================================
-- Verifikation
-- ============================================================
-- SELECT moon_phase, title FROM moon_rituals ORDER BY sort_order;
