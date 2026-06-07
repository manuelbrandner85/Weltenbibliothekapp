-- T1: Verzeichnis aller interaktiven Tools/Features je Welt.
CREATE TABLE IF NOT EXISTS app_tools (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  world         text        NOT NULL,
  category      text        NOT NULL DEFAULT 'Allgemein',
  name          text        NOT NULL,
  description   text        NOT NULL DEFAULT '',
  content_table text,
  status        text        NOT NULL DEFAULT 'live',
  sort_order    integer     NOT NULL DEFAULT 0,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE(world, name)
);
ALTER TABLE app_tools ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "Public read app_tools" ON app_tools FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY "Service write app_tools" ON app_tools FOR ALL USING (auth.role() = 'service_role');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- T2: KI-Vorschlaege fuer neue Tools.
CREATE TABLE IF NOT EXISTS tool_suggestions (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  world        text        NOT NULL,
  category     text,
  name         text        NOT NULL,
  description  text        NOT NULL DEFAULT '',
  rationale    text,
  status       text        NOT NULL DEFAULT 'pending',
  github_issue_url text,
  created_at   timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE tool_suggestions ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "Service rw tool_suggestions" ON tool_suggestions FOR ALL USING (auth.role() = 'service_role');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ── Seed: bestehende Tools (idempotent via ON CONFLICT) ──
INSERT INTO app_tools (world, category, name, description, content_table) VALUES
-- MATERIE: Haupt-Werkzeuge
('materie','Recherche','Kaninchenbau','Automatische Tiefen-Recherche: Thema -> volles Dossier aus 46 Quellen',NULL),
('materie','Recherche','Verflechtungs-Netz','Beziehungs-/Macht-Netzwerk visualisieren',NULL),
('materie','Recherche','Meine Faelle','Gespeicherte Investigationen verwalten',NULL),
('materie','Community','Live Chat','Echtzeit-Diskussion (Materie)',NULL),
('materie','Community','Beitraege','Community-Feed lesen/posten',NULL),
('materie','Allgemein','Lesezeichen','Gespeicherte Inhalte',NULL),
-- MATERIE: OSINT-Werkzeuge
('materie','OSINT','Domain-Recherche','WHOIS + Registrar-Daten',NULL),
('materie','OSINT','Telefon-Recherche','Land/Anbieter/Typ-Erkennung',NULL),
('materie','OSINT','IP/ASN-Lookup','Geolokation via ipwho.is',NULL),
('materie','OSINT','Email Leak-Check','Breach-Datenbank-Suche',NULL),
('materie','OSINT','Person-Recherche','Wikipedia + oeffentliche Quellen',NULL),
('materie','OSINT','Bild-Analyse','KI-Bildinhalts-Analyse',NULL),
('materie','OSINT','KI-Detektor','GPT/Claude-Text-Erkennung',NULL),
('materie','OSINT','Geo-Analyse','Koordinaten-Mapping + Metadaten',NULL),
('materie','OSINT','Krypto-Tracker','Blockchain-Adress-Analyse',NULL),
('materie','OSINT','Propaganda-Vergleich','Artikel-Bias nebeneinander',NULL),
('materie','OSINT','Country Compare','Bevoelkerung, Gini, Sprachen',NULL),
('materie','OSINT','Power-Network Explorer','OpenSanctions + Aleph OCCRP',NULL),
('materie','OSINT','Study Analyst','PubMed + Semantic Scholar + KI',NULL),
('materie','OSINT','Versions-Waechter','Wayback-Diffs + Watchlist',NULL),
('materie','OSINT','EU-Parlament Tracker','Live-Abstimmungen + Werte-Matching',NULL),
('materie','Live','Welt-Ereignis-Radar','Erdbeben, Katastrophen (USGS/GDACS)',NULL),
('materie','Live','Medien-Tonalitaet','GDELT Sentiment-Analyse',NULL),
('materie','Live','Flugverfolgung','Live ADS-B via OpenSky',NULL),
('materie','Live','Cyber-Bedrohungen','Ransomware + C2-Feed',NULL),
('materie','Live','Waldbrand-Radar','NASA FIRMS Hotspots',NULL),
('materie','Live','Luftqualitaet','OpenAQ PM2.5/NO2/Ozon',NULL),
('materie','Live','Internet-Ausfaelle','Cloudflare Radar Outages',NULL),
('materie','Live','Reisewarnungen','Laender-Sicherheitsstufen',NULL),
('materie','Live','Wirtschafts-Indikatoren','Worldbank: Inflation, BIP',NULL),
('materie','Live','Konflikt-Datenbank','ACLED Konflikt-Ereignisse',NULL),
('materie','Live','Asteroiden-Anflug','NASA/JPL Near-Earth Objects',NULL),
('materie','Live','Vulkan-Aktivitaet','NASA EONET aktive Vulkane',NULL),
('materie','Live','Weltraumwetter','NOAA Sonnenstuerme & Aurora',NULL),
('materie','Live','Prognose-Maerkte','Polymarket Vorhersage-Quoten',NULL),
('materie','Live','GPS-Stoerungen','gpsjam.org Karte',NULL),
('materie','Live','Seekabel-Karte','Globales Internet-Backbone',NULL),
-- ENERGIE: Kosmische Energie
('energie','Kosmisch','Mondphasen','7-Tage Mond-Energie-Vorschau',NULL),
('energie','Kosmisch','Erd-Resonanz','Geomagnetik & Schumann (NOAA)',NULL),
('energie','Kosmisch','Tages-Mantra','Taeglicher Weisheits-Impuls',NULL),
('energie','Kosmisch','Bio-Rhythmus','Koerper/Seele/Geist 3-Zyklus',NULL),
('energie','Kosmisch','Mondkalender','Ephemeriden + Rituale + Journal','moon_rituals'),
('energie','Kosmisch','Pendel-Orakel','Ja/Nein-Divination',NULL),
-- ENERGIE: Numerologie
('energie','Numerologie','Numerologie','Lebensweg, Seele, Ausdruck, Persoenlichkeit','soul_number_meanings'),
('energie','Numerologie','Numerologie-Quiz','30 Fragen, 3 Schwierigkeiten',NULL),
('energie','Numerologie','Alltags-Numerologie','Adresse, Telefon, Kennzeichen',NULL),
('energie','Numerologie','Beziehungs-Numerologie','Zwei-Personen-Synastrie',NULL),
('energie','Numerologie','Gematria','Buchstaben-Zahl-Umrechnung',NULL),
-- ENERGIE: Tarot & Orakel
('energie','Orakel','Tarot','Tageskarte ziehen',NULL),
('energie','Orakel','Tarot-Lexikon','Alle 78 Karten mit Bedeutung',NULL),
('energie','Orakel','Tarot-Orakel','1/3/5/10-Karten-Legungen',NULL),
('energie','Orakel','Runen-Orakel','24 Elder Futhark',NULL),
('energie','Orakel','Bind-Rune','2-3 Runen kombinieren',NULL),
('energie','Orakel','I-Ging Muenzwurf','Muenz-Orakel mit KI-Deutung',NULL),
('energie','Orakel','Goetter-Orakel','30+ Gottheiten-Archetypen',NULL),
('energie','Orakel','Goetter-Dialog','KI-Chat als 17 Pantheon-Personas',NULL),
-- ENERGIE: Psychologie & Bewusstsein
('energie','Bewusstsein','Archetypen','12 Pearson-Archetypen-Profil',NULL),
('energie','Bewusstsein','Archetypen-Quiz','12-Fragen-Szenario-Assessment',NULL),
('energie','Bewusstsein','Chakren','7 Energiezentren-Balance','chakra_symptoms'),
('energie','Bewusstsein','Kabbala','Lebensbaum-Analyse',NULL),
('energie','Bewusstsein','Hermetik','7 hermetische Prinzipien',NULL),
('energie','Bewusstsein','Reality-Check','Hermetik auf Situation anwenden',NULL),
('energie','Bewusstsein','Spirit-Profil','10-Tab Gesamt-Analyse',NULL),
-- ENERGIE: Meditation & Koerper
('energie','Koerper','Meditation','Timer mit Gongs',NULL),
('energie','Koerper','Audio-Meditation','5 gefuehrte TTS-Sessions',NULL),
('energie','Koerper','Koerperscan','Symptom -> Chakra-Blockade','chakra_symptoms'),
('energie','Koerper','Audio-Koerperscan','10-min Vipassana',NULL),
('energie','Koerper','Erdung','10 Erdungs-Uebungen',NULL),
('energie','Koerper','Yoga Asanas','50+ Posen mit Anleitung',NULL),
('energie','Koerper','Epigenetik','12 Genexpressions-Praktiken',NULL),
-- ENERGIE: Frequenz & Klang
('energie','Klang','Frequenzen','Solfeggio & Binaural-Generator',NULL),
('energie','Klang','Mantras','30+ Sanskrit-Mantra-Bibliothek',NULL),
('energie','Klang','Mantra-Guide','12 Mantras, 21-Tage-Journal',NULL),
('energie','Klang','Schamanen-Reise','KI-gefuehrte 5-Phasen-Reise','shamanic_journey_guides'),
('energie','Klang','Trommel-Timer','Trommel-BPM-Bibliothek',NULL),
-- ENERGIE: Geometrie & Traum
('energie','Geometrie','Heilige Geometrie','6-stufiger Touch-Konstruktor',NULL),
('energie','Geometrie','Animierte Geometrie','8 Formen mit Animation',NULL),
('energie','Traum','Traumdeutung','Symbol-Lexikon + Auto-Tagging','dream_symbols'),
('energie','Traum','Traum-Muster KI','Jung-Analyse der letzten 60 Traeume',NULL),
('energie','Traum','Akasha-Chronik','Journal + KI-Reflexion + Streak',NULL),
-- ENERGIE: Beziehung & Ahnen
('energie','Ahnen','Stammbaum','3-Generationen-Ahnenbaum',NULL),
('energie','Ahnen','Ahnenarbeit','Ahnen-Muster + Heilrituale','ancestral_rituals'),
-- ENERGIE: Kristalle
('energie','Kristalle','Kristalle','50+ Heilstein-Datenbank',NULL),
('energie','Kristalle','Kristall-Foto-KI','Stein per Foto erkennen',NULL),
('energie','Kristalle','Kristall-Finder','3-Fragen-Assistent + Top-3',NULL),
('energie','Kristalle','Kristall-Kombi','2-Kristall-Synergie',NULL),
('energie','Kristalle','Geburtsstein-Matcher','Monat + Sternzeichen + Lebensweg',NULL),
('energie','Kristalle','Meine Kristalle','Persoenliche Sammlung + Statistik',NULL),
-- ENERGIE: Astrologie
('energie','Astrologie','Geburtshoroskop 360','Cinematic Tierkreisrad, 10 Planeten','astrology_meanings'),
('energie','Astrologie','Horoskop-Lexikon','Meeus-Astrologie + Lexikon','astrology_meanings'),
('energie','Astrologie','Planeten & Transite','Taegliche kosmische Einfluesse',NULL),
('energie','Astrologie','Synastrie-Chart','Partner-Astrologie-Vergleich',NULL),
('energie','Astrologie','Human Design 360','9-Center-Bodygraph','hd_meanings'),
('energie','Astrologie','HD-Lexikon','Gates, Profile, Kanaele','hd_meanings'),
-- ENERGIE: Transformation
('energie','Transformation','Transformation','5-Dimensionen-Tracker + Chart',NULL),
('energie','Transformation','Vor/Nach-Foto','Koerper/Geist/Seele-Timeline',NULL),
('energie','Transformation','Affirmationen','KI-Studio, 9 Kategorien, TTS',NULL),
('energie','Transformation','Voice-Affirmation','Selbst-Suggestion mit eigener Stimme',NULL),
('energie','Recherche','Spirituelle Recherche','Buecher, Studien, spirituelles Wissen',NULL)
ON CONFLICT (world, name) DO NOTHING;
