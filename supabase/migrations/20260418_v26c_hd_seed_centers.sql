-- ============================================================
-- v26c: Seed 9 Human-Design-Zentren
-- ============================================================

INSERT INTO public.hd_meanings
  (category, key, title, emoji, keywords, short_text, deep_text, shadow_text, sort_order)
VALUES

('center','head','Kopf-Zentrum','💡',
 ARRAY['Inspiration','Frage','Druck'],
 'Inspirations-Druck. Woher kommen deine Fragen?',
 'Das Kopf-Zentrum ist Druck: es will wissen. Definiert = dein Denken hat einen konstanten Impuls. Offen = du nimmst Fragen anderer auf und verstärkst sie – gefährlich, wenn sie nicht deine sind.',
 'Schatten offen: Gedanken-Karussell. Übung: "Ist diese Frage wirklich meine?"',
 1),

('center','ajna','Ajna-Zentrum','🔍',
 ARRAY['Analyse','Konzept','Denken'],
 'Wie du verarbeitest, was du denkst.',
 'Die Ajna verarbeitet. Definiert = feste Art zu denken. Offen = Flexibilität, kann aber zu „Ich muss sicher sein" werden.',
 'Schatten offen: Scheinsicherheit. Übung: nicht jedes Konzept gleich festnageln.',
 2),

('center','throat','Kehl-Zentrum','🗣️',
 ARRAY['Manifestation','Sprache','Handeln'],
 'Das Tor zur Welt. Wie du manifestierst.',
 'Die Kehle ist der Ort der Manifestation. Nur wenn ein Motor zur Kehle verbunden ist, kann jemand mit konstanter Kraft initiieren. Offen = Stimme klingt je nach Gegenüber anders.',
 'Schatten offen: Sprechen, um aufzufallen. Übung: sprechen, wenn du angesprochen wirst.',
 3),

('center','g','G-Zentrum','🧭',
 ARRAY['Identität','Liebe','Richtung'],
 'Magnetmonopol. Wer du bist, wohin du gehörst.',
 'Das G-Zentrum zieht magnetisch an, was zu deinem Leben gehört. Definiert = feste Identität und Richtung. Offen = Identität wechselt, geführt vom Ort und den Menschen.',
 'Schatten offen: Identitätssuche. Übung: Orte wählen, statt sich selbst zu "finden".',
 4),

('center','heart','Herz-/Ego-Zentrum','❤️',
 ARRAY['Willen','Ressource','Versprechen'],
 'Wille, Ego, Materie, Versprechen.',
 'Das Herz ist ein Motor des Willens. Definiert = konstante Willenskraft, kann sich selbst etwas beweisen. Offen (die Mehrheit) = kein konstantes "Ich will", sich beweisen müssen ist Schatten.',
 'Schatten offen: zu viel versprechen, um dazuzugehören. Übung: nichts beweisen müssen.',
 5),

('center','sacral','Sakral-Zentrum','⚙️',
 ARRAY['Energie','Antwort','Sexualität','Lebenskraft'],
 'Motor des Lebens. Nur Generatoren haben ihn definiert.',
 'Das Sakral ist der stärkste Motor. Definiert = nachhaltige Lebensenergie, die durch Ja/Nein antwortet. Offen = kennt seine eigene Energie nicht; nimmt sie von anderen auf.',
 'Schatten offen: bis zum Burnout arbeiten, weil man den eigenen Rhythmus nicht spürt. Übung: Körper als Lehrer.',
 6),

('center','solar_plexus','Solarplexus','🌊',
 ARRAY['Emotion','Welle','Intimität'],
 'Gefühls-Motor. Welle von Hoch zu Tief.',
 'Der Solarplexus arbeitet in Wellen. Definiert = Klarheit braucht Zeit (emotionale Autorität). Offen = nimmt die Wellen anderer auf, verstärkt sie – gefährlich in Konflikten.',
 'Schatten offen: Drama meiden um jeden Preis. Übung: Wahrheit sprechen, wenn die Welle der anderen nicht deine ist.',
 7),

('center','spleen','Milz-Zentrum','🦴',
 ARRAY['Intuition','Angst','Immunsystem','Jetzt'],
 'Leise Intuition. Immunsystem des Körpers und Geistes.',
 'Die Milz spricht flüsternd im Jetzt. Definiert = konstante Intuition, Wohlbefinden. Offen = chronische Angst, aber auch: die Gabe, Angst als Kompass zu lesen, was nicht stimmt.',
 'Schatten offen: an Ungesundem festhalten, weil Loslassen Angst macht. Übung: das Flüstern ernst nehmen.',
 8),

('center','root','Wurzel-Zentrum','🔥',
 ARRAY['Adrenalin','Druck','Stress'],
 'Druck-Zentrum. Deadlines, Adrenalin, Antrieb.',
 'Die Wurzel ist Druck für Aktion. Definiert = konstanter Antrieb. Offen = ständig unter Druck, etwas schnell fertig zu bekommen – dabei gibt es nichts zu beenden.',
 'Schatten offen: alles sofort, keine Ruhe. Übung: Druck fühlen, aber nicht ihm glauben.',
 9)

ON CONFLICT (category, key) DO UPDATE SET
  title       = EXCLUDED.title,
  emoji       = EXCLUDED.emoji,
  keywords    = EXCLUDED.keywords,
  short_text  = EXCLUDED.short_text,
  deep_text   = EXCLUDED.deep_text,
  shadow_text = EXCLUDED.shadow_text,
  sort_order  = EXCLUDED.sort_order;
