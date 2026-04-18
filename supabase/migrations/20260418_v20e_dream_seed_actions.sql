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
