-- ============================================================
-- v22c: Seed Seelenvertrag – Ausdruckszahl (Destiny/Expression)
-- 1–9 + Meisterzahlen 11, 22, 33 = 12 Einträge
-- ============================================================
-- Die Ausdruckszahl (aus dem vollen Geburtsnamen) zeigt die
-- Werkzeuge und Gaben, die du mitgebracht hast, um deinen
-- Lebensweg zu gehen.
-- ============================================================

INSERT INTO public.soul_number_meanings
  (number, category, title, keywords, short_text, deep_text, practice_text, sort_order)
VALUES

(1, 'destiny', 'Ausdruck: Der Anführer',
 ARRAY['Originalität','Mut','Autonomie'],
 'Dein natürliches Talent: Neues anfangen und andere mit deinem Beispiel führen.',
 'Die Ausdruckszahl 1 gibt dir Werkzeuge des Pioniers: ursprüngliche Ideen, Entschlossenheit, die Bereitschaft, der Erste zu sein. Du wirkst am stärksten, wenn du aus eigener Initiative handelst und dich nicht an fremden Wegen orientierst.',
 'Frage dich bei jedem Projekt: Was ist MEIN origineller Zugang, nicht die Kopie?',
 101),

(2, 'destiny', 'Ausdruck: Der Vermittler',
 ARRAY['Takt','Intuition','Zusammenarbeit'],
 'Dein Talent: Feinfühligkeit, Diplomatie, die Gabe der harmonischen Verbindung.',
 'Mit Ausdruck 2 bist du mit der Fähigkeit ausgestattet, zwischen Menschen, Ideen und Energien zu vermitteln. Partnerschaft und Team sind deine natürliche Bühne – nicht das Rampenlicht.',
 'Übe, deine Intuition auszusprechen statt sie zu schlucken.',
 102),

(3, 'destiny', 'Ausdruck: Der Kommunikator',
 ARRAY['Kreativität','Charme','Optimismus'],
 'Dein Talent: Ausdruck durch Wort, Bild, Ton, Bühne oder Freude.',
 'Ausdruck 3 bedeutet: Du bist ein Geschenk, wo auch immer du erscheinst. Deine Werkzeuge sind Wortgewandtheit, Charisma, Lebensfreude, oft künstlerische Begabung. Deine Aufgabe: das Licht nicht unter den Scheffel stellen.',
 'Mach jeden Monat ein Stück kreative Arbeit öffentlich – auch wenn es klein ist.',
 103),

(4, 'destiny', 'Ausdruck: Der Handwerker',
 ARRAY['Präzision','Verlässlichkeit','Ausdauer'],
 'Dein Talent: Systematisches Arbeiten, solide Strukturen, langer Atem.',
 'Mit Ausdruck 4 hast du Hände, die wirklich bauen. Du zerlegst Komplexes in machbare Schritte, hältst durch, wo andere aufgeben, und hinterlässt Werke, die Bestand haben. Im Schatten: zu viel Arbeit, zu wenig Spiel.',
 'Wähle EIN Lebens-Bauwerk (Buch, Haus, Projekt, Kind) und arbeite fünf Jahre dran.',
 104),

(5, 'destiny', 'Ausdruck: Der Verwandler',
 ARRAY['Flexibilität','Vielfalt','Redegewandtheit'],
 'Dein Talent: Sprachen, Reisen, Menschen, schnelle Anpassung.',
 'Ausdruck 5 gibt dir ein Schweizer Taschenmesser an Fähigkeiten. Du lernst schnell, kommunizierst leicht, bewegst dich in vielen Welten. Gefahr: alles ein bisschen, nichts ganz. Deine Aufgabe: deine Vielfalt zu einem kohärenten Beitrag zu weben.',
 'Wähle jedes Jahr ein Gebiet, in dem du dieses Mal wirklich in die Tiefe gehst.',
 105),

(6, 'destiny', 'Ausdruck: Der Heiler',
 ARRAY['Fürsorge','Verantwortung','Ästhetik'],
 'Dein Talent: Menschen, Räume und Beziehungen zu heilen und zu verschönern.',
 'Ausdruck 6 bedeutet: Du hast Heilerhände, ein Heilerherz, einen Heilerblick – auch wenn du nicht im medizinischen Beruf arbeitest. Überall, wo du bist, ordnen sich Dinge, werden Menschen gesehen, fühlt sich etwas nach "Zuhause" an.',
 'Frage wöchentlich: Wen habe ich diese Woche wirklich gesehen? Wen habe ich mir zu viel aufgebürdet?',
 106),

(7, 'destiny', 'Ausdruck: Der Forscher',
 ARRAY['Analyse','Tiefe','Spiritualität'],
 'Dein Talent: Systeme durchschauen, Muster erkennen, das Wahre hinter dem Schein sehen.',
 'Ausdruck 7 gibt dir den Geist eines Mystikers und eines Wissenschaftlers in einem. Du analysierst, fragst, gräbst, bis du den Kern siehst. In der Welt oft als "zu viel nachdenkend" missverstanden – deine Gabe ist gerade dieses Durchdringen.',
 'Schreibe wöchentlich eine große Frage auf, die du gerade lebst – und kein Jahr lang zu schnell beantwortest.',
 107),

(8, 'destiny', 'Ausdruck: Der Gestalter',
 ARRAY['Strategie','Führung','Manifestation'],
 'Dein Talent: Große Dinge organisieren, Fülle erzeugen, mit Macht umgehen.',
 'Ausdruck 8 rüstet dich mit strategischem Denken, Geschäftssinn, Autorität, Ausdauer im Großen. Du bist berufen, mit Ressourcen umzugehen – Geld, Menschen, Institutionen. Wichtig: lerne, Macht als Dienerschaft zu verstehen.',
 'Prüfe jährlich: Was habe ich aufgebaut, was dient über mich hinaus?',
 108),

(9, 'destiny', 'Ausdruck: Der Menschenfreund',
 ARRAY['Mitgefühl','Weite','Universalismus'],
 'Dein Talent: Über persönliche Grenzen hinauszudenken und -zu-fühlen.',
 'Ausdruck 9 bedeutet: Du bist gebaut für das Ganze. Deine Talente entfalten sich am vollsten, wenn du dich in einen Dienst stellst, der größer ist als dein eigenes Leben – Kunst, Heilung, humanitäres Werk, Lehre.',
 'Frage dich monatlich: In welchem größeren Strom stehe ich gerade? Und: Was darf ich diesen Monat loslassen?',
 109),

(11, 'destiny', 'Ausdruck: Der Inspirierer (Meisterzahl)',
 ARRAY['Intuition','Inspiration','Kanal'],
 'Du hast das Werkzeug eines Kanals: Eingebungen, die andere verändern.',
 'Ausdruck 11 bedeutet: deine Worte, deine Präsenz, deine Kunst kommen oft nicht nur "von dir" – sie kommen DURCH dich. Du inspirierst, auch wenn du selbst unsicher bist. Schütze deine Sensitivität wie ein feines Instrument.',
 'Erkenne, wann eine Eingebung kommt, und schreibe sie sofort auf – sie ist für die Welt gedacht, nicht nur für dich.',
 111),

(22, 'destiny', 'Ausdruck: Der Meister-Baumeister',
 ARRAY['Manifestation','Organisation','Visionär'],
 'Du hast das Werkzeug, Großes materiell zu verwirklichen.',
 'Ausdruck 22 gibt dir die seltene Verbindung: visionärer Geist UND praktische Hände. Du kannst Organisationen, Bewegungen, Werke aus dem Nichts bauen, die lange über dich hinaus wirken. Gefahr: zu früh "realistisch" werden und die Vision verkleinern.',
 'Denke im 50-Jahres-Horizont. Verbünde dich früh mit Menschen, die dein Bauwerk weiterführen können.',
 122),

(33, 'destiny', 'Ausdruck: Der Meister-Heiler',
 ARRAY['Bedingungslose Liebe','Heilung','Lehrer'],
 'Du hast das Werkzeug, durch pure Präsenz zu heilen.',
 'Ausdruck 33 ist selten. Du bist mit einem Werkzeug ausgestattet, das fast ohne Worte wirkt: deine Präsenz selbst heilt, unterrichtet, erinnert. Dieser Ausdruck fordert höchste ethische Reinheit, denn die Kraft ist groß.',
 'Schütze deine Frequenz wie ein heiliger Ort. Wähle deine Umgebung weise. Gib den größten Teil deiner Kraft dem Dienen.',
 133)

ON CONFLICT (number, category) DO UPDATE SET
  title         = EXCLUDED.title,
  keywords      = EXCLUDED.keywords,
  short_text    = EXCLUDED.short_text,
  deep_text     = EXCLUDED.deep_text,
  practice_text = EXCLUDED.practice_text,
  sort_order    = EXCLUDED.sort_order;
