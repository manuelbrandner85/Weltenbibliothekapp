-- ============================================================
-- v22e: Seed Seelenvertrag – Personality + Karmic Debts
-- 9 Personality + 4 Karmische Schulden = 13 Einträge
-- ============================================================

INSERT INTO public.soul_number_meanings
  (number, category, title, keywords, short_text, deep_text, practice_text, sort_order)
VALUES

-- ── Personality (aus Konsonanten des Namens) ─────────────────
(1, 'personality', 'Außenwirkung: Der Selbstbewusste',
 ARRAY['Präsenz','Initiative','Stärke'],
 'Andere sehen dich als entschlossen, eigenständig, oft als Führungspersönlichkeit.',
 'Deine äußere Erscheinung vermittelt Autonomie. Man traut dir zu, allein klarzukommen – und kommt vielleicht selten auf die Idee, dich zu unterstützen. Lerne zu zeigen, wenn du Hilfe brauchst.',
 'Bitte diese Woche bewusst um Hilfe, wo du sonst allein gestemmt hättest.',
 301),

(2, 'personality', 'Außenwirkung: Die sanfte Präsenz',
 ARRAY['Warm','Diplomatisch','Einfühlsam'],
 'Andere sehen dich als warmherzig, zugänglich, harmonisierend.',
 'Deine äußere Erscheinung zieht Menschen an, die Trost oder Vermittlung suchen. Gefahr: du wirkst so sanft, dass deine Autorität übersehen wird. Übe, auch die harte Seite zu zeigen.',
 'Sprich diese Woche einen Konflikt direkt an, ohne zu beschwichtigen.',
 302),

(3, 'personality', 'Außenwirkung: Der Strahlende',
 ARRAY['Charismatisch','Lebenslustig','Gesellig'],
 'Andere sehen dich als charmant, unterhaltsam, lebendig.',
 'Deine äußere Erscheinung ist Licht. Menschen lachen mit dir, folgen deinem Ton. Gefahr: nur die strahlende Fassade wird gesehen, die Tiefe dahinter nicht.',
 'Zeige einem engen Menschen diese Woche deine Traurigkeit unverkleidet.',
 303),

(4, 'personality', 'Außenwirkung: Der Solide',
 ARRAY['Verlässlich','Geerdet','Beständig'],
 'Andere sehen dich als zuverlässig, bodenständig, als Fels in der Brandung.',
 'Deine äußere Erscheinung strahlt Stabilität aus. Man vertraut dir große Verantwortungen an. Gefahr: du wirkst so erwachsen, dass deine verspielte Seite keinen Raum findet.',
 'Tu diese Woche etwas bewusst "Unverantwortliches" – etwas, das dir Freude macht, ohne "produktiv" zu sein.',
 304),

(5, 'personality', 'Außenwirkung: Der Dynamische',
 ARRAY['Lebendig','Neugierig','Magnetisch'],
 'Andere sehen dich als abenteuerlich, spannend, schwer festzunageln.',
 'Deine äußere Erscheinung ist Bewegung. Menschen fühlen sich lebendig in deiner Nähe, wissen aber nicht immer, wo sie dich einordnen sollen.',
 'Verpflichte dich diese Woche zu EINER klaren Sache, die du nicht mehr änderst.',
 305),

(6, 'personality', 'Außenwirkung: Der Warmherzige',
 ARRAY['Nährend','Vertrauenswürdig','Ästhetisch'],
 'Andere sehen dich als fürsorglich, verantwortungsvoll, oft "elternhaft".',
 'Deine äußere Erscheinung lädt andere ein, sich fallen zu lassen. Du wirst oft zum "Kümmerer" gemacht, auch wenn du selbst müde bist.',
 'Lerne höflich "Nein" zu sagen, ohne Rechtfertigung. Übe es diese Woche dreimal.',
 306),

(7, 'personality', 'Außenwirkung: Der Rätselhafte',
 ARRAY['Geheimnisvoll','Tief','Zurückgezogen'],
 'Andere sehen dich als geheimnisvoll, oft unnahbar – aber mit einer Tiefe, die fasziniert.',
 'Deine äußere Erscheinung zieht sich leicht zurück. Menschen spüren eine unsichtbare Welt hinter dir. Gefahr: Missverständnisse, weil du nicht zeigst, was in dir vorgeht.',
 'Teile diese Woche EINE deiner inneren Fragen mit einem Menschen, dem du vertraust.',
 307),

(8, 'personality', 'Außenwirkung: Die Autorität',
 ARRAY['Stark','Erfolgreich','Kompetent'],
 'Andere sehen dich als mächtig, kompetent, geschäftstüchtig.',
 'Deine äußere Erscheinung kommandiert Respekt. Du wirkst wie jemand, der entscheidet. Gefahr: die weiche, verletzliche Seite kommt selten zum Vorschein.',
 'Zeige diese Woche einem nahen Menschen deine Verletzlichkeit – nicht als Schwäche, sondern als Wahrheit.',
 308),

(9, 'personality', 'Außenwirkung: Der Alte',
 ARRAY['Weise','Universal','Großzügig'],
 'Andere sehen dich als weise, großherzig, oft "über den Dingen stehend".',
 'Deine äußere Erscheinung wirkt gealtert im guten Sinne: man spürt, dass du vieles gesehen hast. Menschen kommen zu dir mit ihren tiefen Fragen. Gefahr: du wirkst fast zu abgeklärt, lädst niemanden ein, sich um dich zu sorgen.',
 'Erlaube dir diese Woche, jung, spielerisch, ungeschickt zu sein – ohne zu moderieren.',
 309),

-- ── Karmische Schulden ──────────────────────────────────────
(13, 'karmic_debt', 'Karmische Schuld 13 – Faulheit & Unausdauer',
 ARRAY['Disziplin','Transformation','Beharrlichkeit'],
 'Du trägst eine Seelenschuld aus mangelnder Anstrengung in früheren Zyklen. Jetzt: Disziplin ist dein Heiler.',
 'Die 13 ist die Energie der Transformation durch ehrliche Arbeit. Wenn diese Zahl in deinem Chart auftaucht, hat deine Seele gewählt, eine alte Neigung zu Vermeidung und Abkürzungen aufzulösen. Es wird sich oft anfühlen, als wärst du "mehr anstrengen müssen" als andere – das ist deine Heilung, nicht dein Unglück.',
 'Wähle EINE Sache, die du aufschiebst, und arbeite 30 Tage täglich eine Stunde daran – ohne Ausnahme.',
 413),

(14, 'karmic_debt', 'Karmische Schuld 14 – Exzess & Freiheitsmissbrauch',
 ARRAY['Mäßigung','Bewusste Freiheit','Verantwortung'],
 'Du trägst eine Seelenschuld aus übermäßigem Genuss in früheren Zyklen. Jetzt: maßvolle Freiheit ist dein Heiler.',
 'Die 14 erzählt von einer Seele, die in früheren Zyklen ihre Freiheit auf Kosten anderer genutzt hat – Sucht, Exzess, Untreue. In diesem Leben kommt sie in Situationen, die sie lehren, Freiheit mit Verantwortung zu verbinden.',
 'Wähle einen "Exzess", dem du dich oft hingibst, und praktiziere 40 Tage bewusste Mäßigung.',
 414),

(16, 'karmic_debt', 'Karmische Schuld 16 – Ego & Liebesmissbrauch',
 ARRAY['Demut','Neubau','Bedingungslose Liebe'],
 'Du trägst eine Seelenschuld aus Egoismus oder Liebesmissbrauch. Jetzt: Demut und Neubau sind deine Heilung.',
 'Die 16 ist die Energie des Ego-Zusammenbruchs im Dienst der Seele. Menschen mit dieser Zahl erleben oft einen Sturz, eine Krise, eine Demütigung im ersten Lebensdrittel – nicht als Strafe, sondern als Reinigung. Der Turm muss fallen, damit das wahre Zuhause gebaut werden kann.',
 'Wenn der Sturz kommt: widerstehe nicht. Lerne durch ihn. Baue danach mit mehr Demut neu.',
 416),

(19, 'karmic_debt', 'Karmische Schuld 19 – Machtmissbrauch',
 ARRAY['Dienende Macht','Verantwortung','Unabhängigkeit'],
 'Du trägst eine Seelenschuld aus Machtmissbrauch oder Kontrolle über andere. Jetzt: dienende Macht ist dein Heiler.',
 'Die 19 erzählt von einer Seele, die in früheren Zyklen Macht für sich missbraucht hat. In diesem Leben kommt sie in Situationen, die sie zwingen, alleine zu stehen, nicht von anderen abhängig zu sein, aber auch andere nicht mehr zu kontrollieren.',
 'Frage dich monatlich: Wo versuche ich gerade, Kontrolle über das Leben eines anderen auszuüben – aus gut gemeinter Absicht? Lass los.',
 419)

ON CONFLICT (number, category) DO UPDATE SET
  title         = EXCLUDED.title,
  keywords      = EXCLUDED.keywords,
  short_text    = EXCLUDED.short_text,
  deep_text     = EXCLUDED.deep_text,
  practice_text = EXCLUDED.practice_text,
  sort_order    = EXCLUDED.sort_order;
