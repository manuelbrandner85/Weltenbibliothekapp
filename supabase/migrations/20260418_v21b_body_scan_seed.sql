-- ============================================================
-- v21b: Körperscan-Seed – 7 Chakren × 8 Symptome (56 Einträge)
-- ============================================================
-- Idempotent: ON CONFLICT DO NOTHING (da kein UNIQUE auf text,
-- wird bei Neu-Run einfach übersprungen wenn IDs bereits existieren –
-- UUIDs sind primary key, also kein Konflikt. Safe to re-run.)
-- ============================================================

INSERT INTO public.chakra_symptoms
  (chakra_number, chakra_name, chakra_color, chakra_emoji,
   symptom_category, symptom_text, weight, sort_order)
VALUES

-- ── 1. WURZELCHAKRA (Muladhara) ─────────────────────────────
(1,'Wurzelchakra','#F44336','🔴','körperlich',
 'Rückenschmerzen im unteren Bereich oder Ischias',3,10),
(1,'Wurzelchakra','#F44336','🔴','körperlich',
 'Probleme mit Beinen, Knien oder Füßen',2,11),
(1,'Wurzelchakra','#F44336','🔴','emotional',
 'Ständige Existenzangst oder Angst vor dem Morgen',3,12),
(1,'Wurzelchakra','#F44336','🔴','emotional',
 'Gefühl von Unsicherheit und fehlendem Fundament',3,13),
(1,'Wurzelchakra','#F44336','🔴','mental',
 'Gedankenkarussell um Geld, Wohnen, Überleben',2,14),
(1,'Wurzelchakra','#F44336','🔴','mental',
 'Schwierigkeiten, im Hier und Jetzt präsent zu sein',2,15),
(1,'Wurzelchakra','#F44336','🔴','spirituell',
 'Gefühl, nicht zur Erde zu gehören oder fehl am Platz',2,16),
(1,'Wurzelchakra','#F44336','🔴','spirituell',
 'Unfähigkeit, sich zu erden oder zu zentrieren',2,17),

-- ── 2. SAKRALCHAKRA (Svadhisthana) ──────────────────────────
(2,'Sakralchakra','#FF9800','🟠','körperlich',
 'Probleme im Unterleib, Blase oder Nieren',3,20),
(2,'Sakralchakra','#FF9800','🟠','körperlich',
 'Sexuelle Dysfunktion oder Schmerzen',2,21),
(2,'Sakralchakra','#FF9800','🟠','emotional',
 'Gefühlstaubheit oder emotionale Überwältigung',3,22),
(2,'Sakralchakra','#FF9800','🟠','emotional',
 'Schuldgefühle rund um Genuss, Sexualität oder Körper',3,23),
(2,'Sakralchakra','#FF9800','🟠','mental',
 'Kreativitätsblockade – Ideen fließen nicht',2,24),
(2,'Sakralchakra','#FF9800','🟠','mental',
 'Zwanghaftes Kontrollbedürfnis in Beziehungen',2,25),
(2,'Sakralchakra','#FF9800','🟠','spirituell',
 'Schwierigkeiten, dem Leben und dem Fluss zu vertrauen',2,26),
(2,'Sakralchakra','#FF9800','🟠','spirituell',
 'Abgetrenntheit von Freude und spielerischer Leichtigkeit',2,27),

-- ── 3. SOLARPLEXUSCHAKRA (Manipura) ─────────────────────────
(3,'Solarplexuschakra','#FFEB3B','🟡','körperlich',
 'Verdauungsprobleme, Magenprobleme oder Sodbrennen',3,30),
(3,'Solarplexuschakra','#FFEB3B','🟡','körperlich',
 'Chronische Müdigkeit oder Erschöpfung ohne klare Ursache',2,31),
(3,'Solarplexuschakra','#FFEB3B','🟡','emotional',
 'Geringes Selbstwertgefühl oder ständige Selbstkritik',3,32),
(3,'Solarplexuschakra','#FFEB3B','🟡','emotional',
 'Machtlosigkeit oder Opferhaltung im Alltag',3,33),
(3,'Solarplexuschakra','#FFEB3B','🟡','mental',
 'Entscheidungsunfähigkeit oder anhaltende Unentschlossenheit',2,34),
(3,'Solarplexuschakra','#FFEB3B','🟡','mental',
 'Perfektionismus und Angst vor Fehlern',2,35),
(3,'Solarplexuschakra','#FFEB3B','🟡','spirituell',
 'Schwierigkeiten, die eigene Kraft und Mitte zu spüren',2,36),
(3,'Solarplexuschakra','#FFEB3B','🟡','spirituell',
 'Gefühl, dass andere über das eigene Leben bestimmen',2,37),

-- ── 4. HERZCHAKRA (Anahata) ─────────────────────────────────
(4,'Herzchakra','#4CAF50','💚','körperlich',
 'Herz-Kreislauf-Beschwerden, Herzrasen oder Brustenge',3,40),
(4,'Herzchakra','#4CAF50','💚','körperlich',
 'Probleme mit Lunge, Bronchien oder häufige Erkältungen',2,41),
(4,'Herzchakra','#4CAF50','💚','emotional',
 'Schwierigkeiten zu lieben oder Liebe anzunehmen',3,42),
(4,'Herzchakra','#4CAF50','💚','emotional',
 'Bitterkeit, Groll oder alte Verletzungen, die nicht heilen',3,43),
(4,'Herzchakra','#4CAF50','💚','mental',
 'Ständige Selbst-Verurteilung oder Unfähigkeit zur Vergebung',2,44),
(4,'Herzchakra','#4CAF50','💚','mental',
 'Isolation – das Gefühl, von anderen getrennt zu sein',2,45),
(4,'Herzchakra','#4CAF50','💚','spirituell',
 'Verschlossenes Herz – Mitgefühl fühlt sich weit entfernt an',2,46),
(4,'Herzchakra','#4CAF50','💚','spirituell',
 'Unfähigkeit, bedingungslose Liebe (auch zu sich selbst) zu empfinden',2,47),

-- ── 5. KEHLCHAKRA (Vishuddha) ───────────────────────────────
(5,'Kehlchakra','#2196F3','🔵','körperlich',
 'Häufige Halsschmerzen, Heiserkeit oder Schilddrüsenprobleme',3,50),
(5,'Kehlchakra','#2196F3','🔵','körperlich',
 'Probleme mit Kiefer, Nacken oder Schultern',2,51),
(5,'Kehlchakra','#2196F3','🔵','emotional',
 'Angst, die eigene Wahrheit auszusprechen',3,52),
(5,'Kehlchakra','#2196F3','🔵','emotional',
 'Das Gefühl, nicht gehört oder nicht verstanden zu werden',3,53),
(5,'Kehlchakra','#2196F3','🔵','mental',
 'Schwierigkeiten, Grenzen zu setzen oder Nein zu sagen',2,54),
(5,'Kehlchakra','#2196F3','🔵','mental',
 'Überreden oder Schweigen, anstatt authentisch zu sprechen',2,55),
(5,'Kehlchakra','#2196F3','🔵','spirituell',
 'Blockierter kreativer Ausdruck (Schreiben, Sprechen, Singen)',2,56),
(5,'Kehlchakra','#2196F3','🔵','spirituell',
 'Unwahrheit oder Lügen im Alltag, die sich wie eine Last anfühlen',2,57),

-- ── 6. DRITTES-AUGE-CHAKRA (Ajna) ───────────────────────────
(6,'Drittes Auge','#9C27B0','🟣','körperlich',
 'Häufige Kopfschmerzen, Migräne oder Augenbeschwerden',3,60),
(6,'Drittes Auge','#9C27B0','🟣','körperlich',
 'Schlafstörungen oder lebhafte, störende Träume',2,61),
(6,'Drittes Auge','#9C27B0','🟣','emotional',
 'Überwältigende Fantasien oder Realitätsverlust',2,62),
(6,'Drittes Auge','#9C27B0','🟣','emotional',
 'Angst vor dem Unbekannten oder vor Intuition',3,63),
(6,'Drittes Auge','#9C27B0','🟣','mental',
 'Überanalyse und Unfähigkeit, dem inneren Wissen zu vertrauen',3,64),
(6,'Drittes Auge','#9C27B0','🟣','mental',
 'Dogmatisches Denken – Unfähigkeit, neue Perspektiven zu sehen',2,65),
(6,'Drittes Auge','#9C27B0','🟣','spirituell',
 'Blockierte Intuition oder abgetrennte Wahrnehmung',2,66),
(6,'Drittes Auge','#9C27B0','🟣','spirituell',
 'Kein Zugang zu inneren Bildern, Visionen oder Träumen',2,67),

-- ── 7. KRONENCHAKRA (Sahasrara) ─────────────────────────────
(7,'Kronenchakra','#E1BEE7','⚪','körperlich',
 'Chronische Erschöpfung ohne körperliche Ursache',2,70),
(7,'Kronenchakra','#E1BEE7','⚪','körperlich',
 'Überempfindlichkeit gegenüber Licht oder Lärm',2,71),
(7,'Kronenchakra','#E1BEE7','⚪','emotional',
 'Tiefer Sinnverlust oder existenzielle Leere',3,72),
(7,'Kronenchakra','#E1BEE7','⚪','emotional',
 'Gefühl der Abgeschnittenheit vom Göttlichen oder dem Größeren',3,73),
(7,'Kronenchakra','#E1BEE7','⚪','mental',
 'Nihilismus oder der Glaube, dass nichts wirklich zählt',2,74),
(7,'Kronenchakra','#E1BEE7','⚪','mental',
 'Unfähigkeit, Still zu sitzen oder sich zu konzentrieren',2,75),
(7,'Kronenchakra','#E1BEE7','⚪','spirituell',
 'Kein Zugang zu Stille, Gebet oder meditativer Tiefe',2,76),
(7,'Kronenchakra','#E1BEE7','⚪','spirituell',
 'Spiritueller Hochmut oder totale Ablehnung des Spirituellen',2,77);

-- ============================================================
-- Verifikation:
-- SELECT chakra_number, chakra_name, COUNT(*) as cnt
--   FROM chakra_symptoms
--   GROUP BY chakra_number, chakra_name
--   ORDER BY chakra_number;
-- ============================================================
