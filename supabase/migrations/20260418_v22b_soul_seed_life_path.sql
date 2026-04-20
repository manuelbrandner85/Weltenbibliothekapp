-- ============================================================
-- v22b: Seed Seelenvertrag – Lebensweg-Zahlen (Life Path)
-- 1–9 + Meisterzahlen 11, 22, 33 = 12 Einträge
-- ============================================================
-- Der Lebensweg ist die Haupt-Lebensaufgabe, berechnet aus dem
-- Geburtsdatum. Das Kernfeld im Seelenvertrag.
-- ============================================================

INSERT INTO public.soul_number_meanings
  (number, category, title, keywords, short_text, deep_text, practice_text, sort_order)
VALUES

(1, 'life_path', 'Der Pionier',
 ARRAY['Führung','Unabhängigkeit','Mut','Neubeginn'],
 'Du bist hier, um zu führen und neue Wege zu bahnen. Dein Seelenvertrag trägt die Signatur des Ersten.',
 'Als Lebensweg 1 bist du die schöpferische Urkraft. Deine Seele hat gewählt zu pionieren, Entscheidungen zu treffen wo andere zögern, und Wahrheit sichtbar zu machen durch dein eigenes Vorangehen. Der Schatten: Einsamkeit, Selbstzweifel, Arroganz. Die Gabe: eine Vision zu halten wenn sonst niemand sie sieht.',
 'Fühle täglich: Was will DURCH DICH entstehen, das ohne dich nicht entstehen würde? Handle einmal pro Tag ohne Rückversicherung.',
 1),

(2, 'life_path', 'Die Brücke',
 ARRAY['Diplomatie','Empathie','Harmonie','Kooperation'],
 'Du bist hier, um zu verbinden und zu vermitteln. Dein Vertrag ist der eines Friedensstifters.',
 'Als Lebensweg 2 verbindet deine Seele, was getrennt scheint. Du spürst feinste Nuancen, siehst beide Seiten, webst Harmonie. Der Schatten: Selbstaufgabe, Konfliktvermeidung, Co-Abhängigkeit. Die Gabe: in einem Raum die Schwingung zu heben, einfach durch deine Anwesenheit.',
 'Übe jede Woche eine bewusste Grenze. Frag dich: Wessen Gefühle trage ich gerade, die nicht meine sind?',
 2),

(3, 'life_path', 'Der Ausdruck',
 ARRAY['Kreativität','Freude','Kommunikation','Inspiration'],
 'Du bist hier, um auszudrücken und zu inspirieren. Deine Seele wählte die Stimme.',
 'Als Lebensweg 3 ist Ausdruck dein Atem. Worte, Bilder, Musik, Geschichten, Lachen – durch dich fließt die schöpferische Lebensfreude. Der Schatten: Oberflächlichkeit, Selbstzweifel, Zerstreuung. Die Gabe: eine schwere Wahrheit leicht machen zu können.',
 'Schreibe täglich drei Sätze, die niemand sonst sehen wird. Sprich einmal pro Tag eine unbequeme Wahrheit aus.',
 3),

(4, 'life_path', 'Der Baumeister',
 ARRAY['Ordnung','Disziplin','Verlässlichkeit','Fundament'],
 'Du bist hier, um Strukturen zu bauen, die tragen. Dein Vertrag ist das Fundament.',
 'Als Lebensweg 4 baust du Säulen – in Familie, Arbeit, Gemeinschaft. Deine Seele wählte Geduld, Wiederholung, das Jahrzehnte-Projekt. Der Schatten: Rigidität, Kontrolle, "Arbeit als Identität". Die Gabe: Dinge wirklich fertigzustellen in einer Welt der Anfänge.',
 'Plane dein Lebens-Bauwerk in 10-Jahres-Schritten. Frag dich monatlich: Welcher Stein, den ich legte, trägt andere?',
 4),

(5, 'life_path', 'Der Freiheitssucher',
 ARRAY['Freiheit','Wandel','Erfahrung','Abenteuer'],
 'Du bist hier, um Erfahrungen zu sammeln und Grenzen zu überschreiten.',
 'Als Lebensweg 5 ist Bewegung dein Gebet. Reisen, Lernen, Wechseln, Neues kosten – deine Seele ist auf dieser Erde, um möglichst viele Facetten zu erleben. Der Schatten: Flucht, Süchte, Unbeständigkeit. Die Gabe: anderen zu zeigen, dass Veränderung möglich ist.',
 'Prüfe monatlich: Welche Freiheit lebe ich wirklich? Welche Abhängigkeit tarnt sich als Freiheit?',
 5),

(6, 'life_path', 'Der Hüter',
 ARRAY['Verantwortung','Liebe','Fürsorge','Gerechtigkeit'],
 'Du bist hier, um zu sorgen und zu heilen. Dein Seelenvertrag trägt das Herz.',
 'Als Lebensweg 6 bist du die Matriarchin/der Patriarch der Welt, auch wenn du allein lebst. Familie, Gemeinschaft, Tiere, Pflanzen – alles spürt deine Obhut. Der Schatten: Märtyrer-Rolle, Kontrolle durch Fürsorge, Erschöpfung. Die Gabe: heilenden Raum halten zu können, einfach durch Liebe.',
 'Frage wöchentlich: Helfe ich aus Liebe oder aus Schuld? Nimm einen Tag pro Woche, an dem du nur für dich sorgst.',
 6),

(7, 'life_path', 'Der Suchende',
 ARRAY['Weisheit','Innenschau','Mystik','Forschung'],
 'Du bist hier, um die Tiefe zu erkunden. Deine Seele wählte das Wissen unter der Oberfläche.',
 'Als Lebensweg 7 gehst du nach innen, wo andere nach außen gehen. Philosophie, Spiritualität, Wissenschaft, Mystik – du suchst die Wahrheit hinter dem Schein. Der Schatten: Isolation, Zynismus, Überkopflastigkeit. Die Gabe: eine Wahrheit zu erkennen, die andere nicht sehen können.',
 'Schütze täglich 30 Minuten Stille. Halte einmal pro Woche eine Frage, ohne sie beantworten zu wollen.',
 7),

(8, 'life_path', 'Der Manifestierer',
 ARRAY['Macht','Fülle','Autorität','Manifestation'],
 'Du bist hier, um Materie und Geist zu verbinden. Dein Vertrag trägt die Zahl der Kraft.',
 'Als Lebensweg 8 bist du berufen, großen Einfluss zu manifestieren – Geld, Strukturen, Unternehmen, gerechte Autorität. Deine Seele hat sich Material und Macht gewählt, um dort Bewusstsein zu bringen. Der Schatten: Gier, Härte, Machtmissbrauch, Burnout. Die Gabe: Visionen in Wirklichkeit zu verwandeln.',
 'Frage monatlich: Dient meine Macht dem Leben oder dem Ego? Gib regelmäßig einen Teil deiner Fülle weiter.',
 8),

(9, 'life_path', 'Der Weise',
 ARRAY['Mitgefühl','Vollendung','Loslassen','Universelles'],
 'Du bist hier, um zu vollenden und bedingungslos zu lieben. Deine Seele ist eine alte.',
 'Als Lebensweg 9 trägst du die Essenz aller Zahlen. Deine Seele hat sich dieses Leben gewählt, um zu heilen, was gebrochen ist, und loszulassen, was nicht mehr dient. Der Schatten: Opferhaltung, emotionale Überwältigung, Festhalten. Die Gabe: universelles Mitgefühl, das Herzen öffnet.',
 'Übe täglich eine bewusste Loslass-Praxis. Frage dich: Wen will meine Seele heute segnen, ohne zu belehren?',
 9),

(11, 'life_path', 'Der Visionär (Meisterzahl)',
 ARRAY['Intuition','Vision','Erleuchtung','Brücke zum Höheren'],
 'Du bist hier, um die Brücke zwischen Himmel und Erde zu sein. Eine Meisterzahl mit Doppelkraft.',
 'Als Lebensweg 11 (Meisterzahl) ist dein Seelenvertrag besonders anspruchsvoll. Du bist Kanal für höhere Einsichten, spirituelle Lehrer-Energie, visionäre Ideen. Der Preis: erhöhte Sensitivität, Nervensystem-Überlastung, Selbstzweifel. Die Gabe: Dinge zu sehen, die andere erst Jahrzehnte später sehen.',
 'Schütze dein Nervensystem wie ein heiliges Instrument. Meditiere täglich. Lerne zwischen Intuition und Angst zu unterscheiden.',
 11),

(22, 'life_path', 'Der Meister-Baumeister',
 ARRAY['Manifestation','Vision','Großes Werk','Erdung des Himmels'],
 'Du bist hier, um Himmel auf die Erde zu bauen – sichtbar, materiell, im Großen.',
 'Als Lebensweg 22 (Meisterzahl) hat deine Seele einen der größten Verträge gewählt: Vision und Materie zu vereinen. Du bist der Meister-Baumeister, fähig, Institutionen, Bewegungen, Werke zu schaffen, die Generationen überdauern. Der Preis: hoher Druck, Perfektionismus, Einsamkeit an der Spitze. Die Gabe: aus reinem Geist tatsächliche Strukturen zu erschaffen.',
 'Denke und baue in 100-Jahres-Horizonten. Arbeite mit Team – du kannst es nicht allein. Pflege deinen Körper als Werkzeug.',
 22),

(33, 'life_path', 'Der Meister-Lehrer',
 ARRAY['Bedingungslose Liebe','Heiler','Christus-Frequenz','Hingabe'],
 'Du bist hier, um durch reine Liebe zu heilen. Die höchste Meisterzahl.',
 'Als Lebensweg 33 (Meisterzahl) trägt deine Seele die seltenste Signatur: reine, bedingungslose Liebe in Form. Du bist Meister-Heiler, Meister-Lehrer, manchmal unsichtbar in deiner Wirkung. Der Preis: totale Hingabe, Verzicht auf eigenes Ego. Die Gabe: Räume so zu halten, dass Menschen in deiner Präsenz sich erinnern, wer sie wirklich sind.',
 'Diene, ohne Lohn zu erwarten. Erlaube dir, auch selbst bedingungslos geliebt zu werden. Schütze deine Energie wie ein Priester seinen Altar.',
 33)

ON CONFLICT (number, category) DO UPDATE SET
  title         = EXCLUDED.title,
  keywords      = EXCLUDED.keywords,
  short_text    = EXCLUDED.short_text,
  deep_text     = EXCLUDED.deep_text,
  practice_text = EXCLUDED.practice_text,
  sort_order    = EXCLUDED.sort_order;

-- ============================================================
-- Verifikation:
-- SELECT number, title FROM soul_number_meanings
--   WHERE category='life_path' ORDER BY sort_order;
-- ============================================================
