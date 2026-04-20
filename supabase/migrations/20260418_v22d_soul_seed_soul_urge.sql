-- ============================================================
-- v22d: Seed Seelenvertrag – Seelenantrieb (Soul Urge)
-- 1–9 + Meisterzahlen 11, 22, 33 = 12 Einträge
-- ============================================================
-- Die Seelenantriebszahl (aus den Vokalen des Namens) zeigt die
-- innerste Sehnsucht: Was will deine Seele wirklich, bevor der
-- Verstand eingreift? Das tiefste "Warum" des Vertrags.
-- ============================================================

INSERT INTO public.soul_number_meanings
  (number, category, title, keywords, short_text, deep_text, practice_text, sort_order)
VALUES

(1, 'soul_urge', 'Antrieb: Eigenständig sein',
 ARRAY['Autonomie','Freiheit','Selbstverwirklichung'],
 'Deine Seele sehnt sich danach, ihr eigenes Leben zu führen – ungefiltert, unverkleinert.',
 'Tief in dir pulsiert der Wunsch nach Unabhängigkeit. Du willst deinen Weg gehen, deine eigenen Entscheidungen treffen, niemandem gehören außer dir selbst. Wenn du das unterdrückst, wirst du unruhig, reizbar. Wenn du ihm folgst, wirst du ein Leuchtturm.',
 'Frage dich monatlich: Welche Entscheidung habe ich für jemand anderen getroffen, die ich für mich hätte treffen sollen?',
 201),

(2, 'soul_urge', 'Antrieb: Verbunden sein',
 ARRAY['Liebe','Partnerschaft','Harmonie'],
 'Deine Seele sehnt sich nach tiefer Verbundenheit – zu einem Menschen, einer Gruppe, dem Göttlichen.',
 'Tief in dir wohnt der Wunsch, nicht allein zu sein. Nicht aus Bedürftigkeit, sondern aus Essenz: du bist auf der Erde, um zu verbinden. Liebe, Freundschaft, Partnerschaft sind für dich keine Nebensache, sondern das Zentrum.',
 'Pflege eine Beziehung pro Woche bewusst: ein Anruf, ein Brief, eine Umarmung, ein echtes Gespräch.',
 202),

(3, 'soul_urge', 'Antrieb: Sich ausdrücken',
 ARRAY['Kreativität','Freude','Stimme'],
 'Deine Seele sehnt sich danach, gesehen, gehört, erlebt zu werden – durch ihren Ausdruck.',
 'Tief in dir will etwas raus: Worte, Bilder, Lieder, Lachen, Leben. Wenn du dich zurückhältst (aus Angst vor Urteil, aus "Bescheidenheit"), wirst du depressiv. Wenn du dich zeigst, selbst unvollkommen, lebst du auf.',
 'Zeige jeden Monat EIN kreatives Werk öffentlich. Unvollkommen. Unangepasst.',
 203),

(4, 'soul_urge', 'Antrieb: Etwas Festes bauen',
 ARRAY['Sicherheit','Ordnung','Beitrag'],
 'Deine Seele sehnt sich nach etwas, das sie bleiben lässt – Struktur, Haus, Werk, Familie.',
 'Tief in dir wohnt der Wunsch, nicht nur zu leben, sondern etwas zu hinterlassen. Du brauchst Ordnung um dich, Verlässlichkeit, Menschen, denen dein Wort gilt. Das Chaos der Welt macht dich krank – deine Heilung liegt im geduldigen Bauen.',
 'Wähle EIN Lebens-Projekt, das mindestens 10 Jahre braucht, und beginne.',
 204),

(5, 'soul_urge', 'Antrieb: Frei sein',
 ARRAY['Freiheit','Erfahrung','Sinnesfreude'],
 'Deine Seele sehnt sich nach Weite, Wechsel, Welt, Sinneserfahrung – in jeder Form.',
 'Tief in dir ist eine Bewegung. Stillstand fühlt sich wie Tod an. Du willst reisen, kosten, lernen, dich verlieben, wieder gehen. Das ist nicht Unreife – das ist deine Essenz. Deine Aufgabe: echte innere Freiheit zu finden, nicht nur äußere.',
 'Frage wöchentlich: Was habe ich diese Woche NEU erlebt? Und: Wovor fliehe ich gerade unter dem Vorwand der Freiheit?',
 205),

(6, 'soul_urge', 'Antrieb: Lieben und sorgen',
 ARRAY['Herz','Dienst','Schönheit'],
 'Deine Seele sehnt sich danach, Liebe zu geben und Schönheit zu schaffen – für andere.',
 'Tief in dir pulsiert eine Quelle der Fürsorge. Du willst heilen, wo es weh tut, schön machen, wo es karg ist, ein Zuhause sein für jemanden. Gefahr: alle anderen zu bedienen und dich selbst zu vergessen.',
 'Frage täglich: Was brauche ICH heute, um geliebt zu sein – von mir selbst?',
 206),

(7, 'soul_urge', 'Antrieb: Wahrheit finden',
 ARRAY['Weisheit','Mystik','Stille'],
 'Deine Seele sehnt sich nach tiefer Erkenntnis – nicht nach der Oberfläche des Lebens.',
 'Tief in dir ist ein Sucher. Du willst wissen, was WIRKLICH ist, hinter Religionen, Systemen, Meinungen. Stille, Natur, Meditation, Bücher sind deine heiligen Räume. Small Talk ist Folter. Deine Einsamkeit ist oft heilig, nicht krank.',
 'Schenke dir täglich 30 Minuten "Wahrheitssuche": eine Frage, die dich wirklich interessiert, und Stille.',
 207),

(8, 'soul_urge', 'Antrieb: Wirkmächtig sein',
 ARRAY['Kraft','Einfluss','Manifestation'],
 'Deine Seele sehnt sich danach, in der Welt sichtbar Wirkung zu erzeugen – durch Kraft und Struktur.',
 'Tief in dir wohnt der Wunsch, die Welt zu bewegen. Nicht im Stillen – sichtbar. Geld, Einfluss, Erfolg sind für dich keine "weltlichen Ablenkungen", sondern Werkzeuge, mit denen deine Seele wirken will. Deine Aufgabe: diesen Wunsch ohne Scham und ohne Gier zu leben.',
 'Frage vierteljährlich: Wo habe ich meine Kraft kleingeredet? Wo habe ich Macht ohne Dienst ausgeübt?',
 208),

(9, 'soul_urge', 'Antrieb: Dem Ganzen dienen',
 ARRAY['Universal','Mitgefühl','Hingabe'],
 'Deine Seele sehnt sich nach etwas, das größer ist als sie selbst – einer Sache, einer Menschheit, Gott.',
 'Tief in dir ist ein Wissen: Mein kleines Ich reicht mir nicht. Du willst deinem Leben eine Bedeutung geben, die über dich hinausreicht. Künstler, Aktivistin, Heiler, Weise – du bist glücklich nur dort, wo du dienst.',
 'Wähle jährlich eine "größere Sache", der du dich ernsthaft widmest (mit Zeit, Geld, Herzensarbeit).',
 209),

(11, 'soul_urge', 'Antrieb: Kanal sein (Meisterzahl)',
 ARRAY['Inspiration','Erleuchtung','Verbindung zum Höheren'],
 'Deine Seele sehnt sich danach, durchlässig zu sein für höhere Weisheit – und diese in die Welt zu bringen.',
 'Tief in dir ist der Wunsch, mehr zu sein als nur dein Alltags-Ich. Du willst Durchgang sein. Das macht dich hochsensibel und manchmal überwältigt. Wenn du dein Nervensystem pflegst und täglich meditierst, wirst du zur Brücke.',
 'Meditiere täglich mindestens 20 Minuten. Schreibe Visionen sofort auf, auch halb-verstandene.',
 211),

(22, 'soul_urge', 'Antrieb: Bauen, was bleibt (Meisterzahl)',
 ARRAY['Großes Werk','Manifestation','Erbe'],
 'Deine Seele sehnt sich danach, ein Werk zu hinterlassen, das Generationen überdauert.',
 'Tief in dir wohnt nicht der Wunsch, nur ein gutes Leben zu haben – sondern etwas zu bauen, das lange nach deinem Tod noch wirkt. Institutionen, Bewegungen, Werke. Der Preis: Jahrzehnte der Disziplin. Der Lohn: ein Erbe, das Tausenden dient.',
 'Arbeite immer an EINEM Jahrhundert-Projekt, nebenbei oder hauptsächlich. Gib es nie ganz auf.',
 222),

(33, 'soul_urge', 'Antrieb: Bedingungslos lieben (Meisterzahl)',
 ARRAY['Reine Liebe','Heilung','Hingabe'],
 'Deine Seele sehnt sich danach, Liebe zu sein – ohne Bedingung, ohne Erwartung, ohne Ich.',
 'Tief in dir ist eine seltene Sehnsucht: nicht zu LIEBEN, sondern LIEBE ZU SEIN. Das ist der anspruchsvollste Antrieb der Numerologie, weil er das Ego vollständig transformieren will. Wenn du ihm folgst, wirst du heilend ohne Worte.',
 'Übe täglich bedingungslose Liebe gegenüber einem schwierigen Menschen (auch dir selbst).',
 233)

ON CONFLICT (number, category) DO UPDATE SET
  title         = EXCLUDED.title,
  keywords      = EXCLUDED.keywords,
  short_text    = EXCLUDED.short_text,
  deep_text     = EXCLUDED.deep_text,
  practice_text = EXCLUDED.practice_text,
  sort_order    = EXCLUDED.sort_order;
