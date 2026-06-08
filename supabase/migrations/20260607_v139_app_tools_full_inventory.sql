-- v139: app_tools-Verzeichnis vervollstaendigen.
--
-- Problem: das Tool-Verzeichnis (Funktions-Werkstatt) zeigte nicht ALLE Tools/
-- Features der App. Vorhang & Ursprung hatten gar keine Eintraege, Energie
-- hatte keine Community, und "Livestream" fehlte (nur "Live Chat" war fuer
-- Materie geseedet). Damit der Admin wirklich ALLES bearbeiten/erweitern kann,
-- werden hier alle fehlenden user-erreichbaren Tools/Features ergaenzt.
--
-- Idempotent: ON CONFLICT (world, name) DO NOTHING -- bestehende Eintraege
-- (inkl. vom Admin bearbeiteter) bleiben unveraendert.

INSERT INTO app_tools (world, category, name, description, content_table) VALUES
-- ── MATERIE: fehlende Community-Bezeichnung (App zeigt "Livestream") ──
('materie','Community','Livestream','Live-Chat & Sprachraeume',NULL),

-- ── ENERGIE: Community (fehlte komplett) + restliche Tools ──
('energie','Community','Livestream','Live-Chat & Sprachraeume',NULL),
('energie','Community','Live Chat','Echtzeit-Diskussion (Energie)',NULL),
('energie','Community','Beitraege','Community-Feed lesen/posten',NULL),
('energie','Klang','Galdr-Meditation','24 Runen-Gesaenge - 3-9 min',NULL),
('energie','Klang','Mantra-Praxis','Audio - 108-Mala-Zaehler (Fortgeschritten)',NULL),
('energie','Geometrie','Heilige Symbole','Multikulturelle Sakralsymbole',NULL),
('energie','Aura','Aura-Quiz','12 Fragen -> deine Aura-Farbe',NULL),
('energie','Lernreihen','Lernreihen','Tagesweise Lernpfade - 17 Reihen',NULL),

-- ── VORHANG: alle Tools/Features (war komplett leer) ──
('vorhang','Kern-Tool','Symbol- & Logo-Decoder','Symbole entschluesseln: Bedeutung & Querverweise',NULL),
('vorhang','Werkzeug','Livestream','Live-Chat & Sprachraeume',NULL),
('vorhang','Werkzeug','Lobby-Radar','Konzern-Einfluss auf Politik - Live-Medien',NULL),
('vorhang','Werkzeug','Leaks-Suche','Enthuellungen & Whistleblower weltweit',NULL),
('vorhang','Werkzeug','Macht-Netzwerke','Einflussreiche Netzwerke - Wissens-Datenbank',NULL),
('vorhang','Werkzeug','Symbol-Datenbank','Historische Symbole & ihre Bedeutung',NULL),
('vorhang','Community','Beitraege','Community-Feed - Erkenntnisse teilen & lesen',NULL),
('vorhang','Lernen','Module','Dunkle Psychologie & Elite-Strategien (30 Module)',NULL),

-- ── URSPRUNG: alle Tools/Features (war komplett leer) ──
('ursprung','Kern-Tool','Zeitleiste der Menschheitsurspruenge','Schoepfungsmythen, Urkulturen & offene Fragen',NULL),
('ursprung','Werkzeug','Gateway-Kammer','Hemi-Sync Meditation - F10/F12/F15/F21',NULL),
('ursprung','Werkzeug','Frequenz-Generator','1-40 Hz Slider - 7 Presets (Schumann 7.83 Hz)',NULL),
('ursprung','Werkzeug','Atemmeister','Resonant Tuning - Coherent - Energy - Click-Out',NULL),
('ursprung','Werkzeug','CO2-Toleranz-Timer','Atemhalte-Training - Bestzeit - Verlauf',NULL),
('ursprung','Werkzeug','Realitaets-Architekt','6-Schritt Patterning - CIA McDonnell-Protokoll',NULL),
('ursprung','Werkzeug','RV Trainer','50 Targets - CRV 3-Stage - Ingo Swann',NULL),
('ursprung','Lebendiger Planet','Livestream','Live-Chat & Sprachraeume',NULL),
('ursprung','Lebendiger Planet','Artenvielfalt','Biodiversitaet weltweit - GBIF Live-Daten',NULL),
('ursprung','Lebendiger Planet','Sternenhimmel heute','Sichtbare Planeten - Himmelskalender',NULL),
('ursprung','Lebendiger Planet','Naturphaenomene','Stuerme, Eis, Duerre weltweit - NASA EONET',NULL),
('ursprung','Lebendiger Planet','Indigene Sprachen','Naturvoelker & ihr Wissen - Datenbank',NULL),
('ursprung','Community','Beitraege','Community-Feed - Erfahrungen teilen & lesen',NULL),
('ursprung','Lernen','Module','CIA Quanten-Code Kurse (25 Module)',NULL)
ON CONFLICT (world, name) DO NOTHING;
