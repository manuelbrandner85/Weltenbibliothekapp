import 'package:latlong2/latlong.dart';
import '../models/event_model.dart';

/// ERWEITERTE MYSTISCHE ORTE - Mit detaillierten Beschreibungen, Bildern und Videos
/// Diese Datei ersetzt die Basis-Daten mit reichhaltigeren Informationen
class MysticalEventsEnhanced {
  static List<EventModel> getAllEnhancedEvents() {
    return [
      // ========================================
      // ÄGYPTEN - Das Land der Pharaonen
      // ========================================
      EventModel(
        id: '1',
        title: 'Die Pyramiden von Gizeh',
        description:
            '''Die drei großen Pyramiden von Gizeh gehören zu den faszinierendsten Bauwerken der Menschheitsgeschichte. Die Cheops-Pyramide, mit ursprünglich 146,6 Metern Höhe das höchste Bauwerk der Antike, besteht aus etwa 2,3 Millionen Steinblöcken, von denen jeder durchschnittlich 2,5 Tonnen wiegt.

Was macht diese Strukturen so mysteriös? Ihre präzise astronomische Ausrichtung zu den Himmelsrichtungen (Abweichung: nur 0,015°), die mathematische Perfektion (Pi und Phi in den Proportionen), und die bis heute ungeklärten Bautechniken faszinieren Forscher weltweit.

Alternative Theorien:
• Energiekraftwerke: Manche Forscher vermuten, die Pyramiden dienten der Energiegewinnung durch piezoelektrische Effekte im Granit
• Astronomische Observatorien: Die Schächte könnten präzise auf wichtige Sterne ausgerichtet gewesen sein
• Wasserpumpen: Neueste Theorien deuten auf ein hydraulisches System hin

Die Präzision der Steinbearbeitung (Fugen von 0,5mm!) und die logistischen Herausforderungen (2,5 Mio. Blöcke in 20 Jahren = 1 Block alle 2 Minuten!) werfen bis heute Fragen auf.''',
        location: const LatLng(29.9792, 31.1342),
        category: 'archaeology',
        date: DateTime(2560, 1, 1).subtract(const Duration(days: 365 * 4580)),
        imageUrl:
            'https://images.unsplash.com/photo-1572252009286-268acec5ca0a?w=1200&q=80',
        videoUrl: 'https://www.youtube.com/watch?v=C1y8N0ePuF8',
        documentUrl: 'https://www.giza-legacy.org/research',
        tags: [
          'Ägypten',
          'Pyramiden',
          'Antike Technologie',
          'Energiepunkt',
          'Megalith-Architektur',
        ],
        source: 'Archaeological Research Institute',
        isVerified: true,
        resonanceFrequency: 7.83,
      ),

      EventModel(
        id: '2',
        title: 'Die Große Sphinx von Gizeh',
        description:
            '''Die Sphinx von Gizeh, eine monumentale Statue mit dem Körper eines Löwen und dem Kopf eines Menschen, birgt eines der größten Rätsel der Archäologie: Ihr wahres Alter.

Das Wassererosions-Rätsel:
Geologe Dr. Robert Schoch von der Boston University dokumentierte tiefe, vertikale Erosionsspuren am Körper der Sphinx, die charakteristisch für langanhaltende Wassererosion sind. Problem: Die letzte Regenperiode in Ägypten endete vor etwa 9.000-12.000 Jahren - Jahrtausende vor der offiziellen Datierung der Sphinx (2.500 v.Chr.).

Weitere Mysterien:
• Der ursprüngliche Kopf war vermutlich deutlich größer (Löwenkopf?) und wurde später umgearbeitet
• Unter der Sphinx existieren nachgewiesene Hohlräume und Kammern, die noch nicht vollständig erforscht wurden
• Die "Hall of Records": Edgar Cayce prophezeite eine Kammer unter der Sphinx mit Wissen von Atlantis

Wenn die Wassererosions-Theorie stimmt, könnte die Sphinx 10.000+ Jahre alt sein - älter als die ägyptische Zivilisation selbst. Was bedeutet das für unsere Geschichtsschreibung?''',
        location: const LatLng(29.9753, 31.1376),
        category: 'mystery',
        date: DateTime(10500, 1, 1).subtract(const Duration(days: 365 * 12500)),
        imageUrl:
            'https://images.unsplash.com/photo-1503177119275-0aa32b3a9368?w=1200&q=80',
        videoUrl: 'https://www.youtube.com/watch?v=XfWkNP9JY8c',
        documentUrl: 'https://www.robertschoch.com/sphinx.html',
        tags: [
          'Sphinx',
          'Ägypten',
          'Wassererosion',
          'Atlantis-Verbindung',
          'Prähistorische Zivilisation',
        ],
        source: 'Dr. Robert Schoch, Boston University',
        isVerified: false,
        resonanceFrequency: 8.12,
      ),

      // ========================================
      // TÜRKEI - Göbekli Tepe
      // ========================================
      EventModel(
        id: '3',
        title: 'Göbekli Tepe - Der älteste Tempel der Welt',
        description:
            '''Göbekli Tepe in der Türkei revolutionierte unser Verständnis der menschlichen Geschichte. Diese Megalith-Anlage wurde vor etwa 11.500 Jahren erbaut - 6.000 Jahre VOR Stonehenge und 7.000 Jahre VOR den Pyramiden!

Das paradigmensprengende Detail: Göbekli Tepe wurde von Jäger-Sammler-Gesellschaften erbaut, BEVOR die Landwirtschaft erfunden wurde. Die konventionelle Geschichtsschreibung besagte: Erst Landwirtschaft → dann Sesshaftigkeit → dann Religion und Monumentalbauten. Göbekli Tepe dreht diese Reihenfolge komplett um.

Archäologische Sensation:
• Über 200 T-förmige Megalithen (bis 20 Tonnen schwer)
• Aufwendige Tier-Reliefs: Schlangen, Skorpione, Geier, Füchse
• Astronomische Ausrichtung zu Sirius nachgewiesen
• Absichtlich begraben vor 10.000 Jahren - warum?

Radikal neue Theorie:
Archäologe Klaus Schmidt vermutete: Religion kam VOR der Zivilisation. Der Wunsch, solche Tempel zu bauen, könnte der eigentliche Motor für die Erfindung der Landwirtschaft gewesen sein, nicht umgekehrt!

Nur 5% der Anlage sind bisher ausgegraben. Was liegt noch unter der Erde?''',
        location: const LatLng(37.2233, 38.9225),
        category: 'archaeology',
        date: DateTime(9500, 1, 1).subtract(const Duration(days: 365 * 11500)),
        imageUrl:
            'https://images.unsplash.com/photo-1589308078059-be1415eab4c7?w=1200&q=80',
        videoUrl: 'https://www.youtube.com/watch?v=cI-FH1BQMMM',
        documentUrl: 'https://www.dainst.org/project/133684',
        tags: [
          'Türkei',
          'Göbekli Tepe',
          'Prähistorisch',
          'Zivilisationsursprung',
          'Megalith',
          'Jäger-Sammler',
        ],
        source: 'Deutsches Archäologisches Institut',
        isVerified: true,
        resonanceFrequency: 8.45,
      ),

      // ========================================
      // SÜDAMERIKA - Machu Picchu & Nazca
      // ========================================
      EventModel(
        id: '4',
        title: 'Machu Picchu - Die verlorene Stadt der Inka',
        description:
            '''Machu Picchu, auf 2.430 Metern Höhe in den peruanischen Anden gelegen, ist eines der beeindruckendsten archäologischen Wunder Südamerikas. Die "verlorene Stadt der Inka" wurde erst 1911 von Hiram Bingham wiederentdeckt.

Architektonische Mysterien:
• Präzise Steinbearbeitung ohne Mörtel - Messer passen nicht zwischen die Fugen
• Erdbebensicher: Die "Tanz der Steine"-Technik lässt Blöcke bei Beben schwingen
• Perfekte Sonnenausrichtung: Beim Intihuatana-Stein (Sonnenpfahl) steht die Sonne zur Wintersonnenwende senkrecht

Ungeklärte Techniken:
Wie transportierten die Inka tonnenschwere Granitblöcke auf 2.400m Höhe? Die offizielle Theorie (Rampen + Holzrollen) erscheint angesichts des steilen Geländes fragwürdig. Alternative Forscher vermuten:
• Fortgeschrittene Hebetechniken, die uns heute unbekannt sind
• Chemische Steinbearbeitung (macht Granit temporär weich)
• Akustische Levitation durch Resonanzfrequenzen

Energetische Eigenschaften:
Viele Besucher berichten von ungewöhnlichen Energieempfindungen an bestimmten Punkten der Anlage. Liegt das an der Höhe, der Architektur oder gibt es piezoelektrische Effekte im Gestein?''',
        location: const LatLng(-13.1631, -72.5450),
        category: 'archaeology',
        date: DateTime(1450, 1, 1),
        imageUrl:
            'https://images.unsplash.com/photo-1587595431973-160d0d94add1?w=1200&q=80',
        videoUrl: 'https://www.youtube.com/watch?v=kmMvLjlpJEg',
        documentUrl: 'https://whc.unesco.org/en/list/274',
        tags: [
          'Peru',
          'Inka',
          'Machu Picchu',
          'Energiezentrum',
          'Megalith-Architektur',
          'Präzisions-Steinmetzkunst',
        ],
        source: 'UNESCO World Heritage Centre',
        isVerified: true,
        resonanceFrequency: 8.23,
      ),

      EventModel(
        id: '5',
        title: 'Die Nazca-Linien - Botschaften aus der Vergangenheit',
        description:
            '''Die Nazca-Linien in Peru gehören zu den rätselhaftesten archäologischen Funden der Welt. Über 1.500 riesige Geoglyphen, die nur aus der Luft vollständig erkennbar sind, wurden vor etwa 2.000 Jahren in die Wüste geritzt.

Dimensionen der Linien:
• Einzelne Linien: Bis zu 370 Meter lang
• Figuren: Bis zu 200 Meter groß
• Gesamtfläche: Über 500 km²
• Sichtbarkeit: Nur aus 300+ Metern Höhe vollständig erkennbar

Die zentralen Rätsel:
1. Warum wurden Bilder geschaffen, die man vom Boden aus nicht sehen kann?
2. Wie erreichten die Nazca-Menschen die geometrische Präzision ohne Luftperspektive?
3. Was war der Zweck? Rituale? Astronomische Kalender? Landebahnen?

Wissenschaftliche Theorien:
• Astronomischer Kalender: Maria Reiche wies nach, dass einige Linien zu Sonnen-/Mondaufgängen zeigen
• Wasserkult: Linien führen zu unterirdischen Wasseradern
• Ritualwege: Prozessionspfade für religiöse Zeremonien

Alternative Theorien:
• Erich von Däniken: "Landebahnen" für außerirdische Raumschiffe
• Jim Woodmann: Die Nazca beherrschten Heißluftballons (experimentell nachgewiesen!)
• Energielinien: Verbindung zu globalen Ley-Linien

Die Tatsache, dass die Linien nach 2.000 Jahren noch sichtbar sind, zeigt die extreme Trockenheit der Region. Ein perfekter "natürlicher Speicher" für Botschaften an die Nachwelt?''',
        location: const LatLng(-14.7390, -75.1300),
        category: 'mystery',
        date: DateTime(500, 1, 1).subtract(const Duration(days: 365 * 2500)),
        imageUrl:
            'https://images.unsplash.com/photo-1531065208531-4036c0dba3f5?w=1200&q=80',
        videoUrl: 'https://www.youtube.com/watch?v=yh-_Vdp7JYo',
        documentUrl: 'https://www.mariareichemuseum.com/',
        tags: [
          'Peru',
          'Nazca',
          'Geoglyphen',
          'Astronomischer Kalender',
          'Ancient Aliens',
          'Aerial Archaeology',
        ],
        source: 'Maria Reiche Museum',
        isVerified: true,
        resonanceFrequency: 7.77,
      ),

      // ========================================
      // ENGLAND - Stonehenge
      // ========================================
      EventModel(
        id: '6',
        title: 'Stonehenge - Das prähistorische Observatorium',
        description:
            '''Stonehenge, das berühmteste prähistorische Monument Englands, wurde über einen Zeitraum von 1.500 Jahren (3.000-1.500 v.Chr.) in mehreren Phasen erbaut. Doch wie und warum?

Die logistische Meisterleistung:
• 80 Blaustein-Monolithen (je 4 Tonnen) wurden 240 km von Wales transportiert
• 30 Sarsen-Steine (je 25 Tonnen) aus 30 km Entfernung
• Präzise Ausrichtung zur Sommersonnenwende (Sonnenaufgang) und Wintersonnenwende (Sonnenuntergang)

Astronomische Präzision:
Stonehenge ist ein hochentwickelter Stein-Computer zur Berechnung von:
• Sonnenwenden und Tagundnachtgleichen
• Mond-Zyklen (18,6-Jahres-Zyklus)
• Sonnen- und Mondfinsternissen

Gerald Hawkins (Astronom, 1963) bewies: Die Positionen der Steine markieren 24 signifikante astronomische Ereignisse. Wahrscheinlichkeit durch Zufall: 1:1.000.000!

Akustische Mysterien:
Neueste Forschungen zeigen: Die Bluestones haben piezoelektrische Eigenschaften und klingen, wenn man sie anschlägt. Wurde Stonehenge als riesiges Musikinstrument genutzt? War es ein "Heilungs-Tempel" mit Klangtherapie?

Energetische Phänomene:
• Erhöhte elektromagnetische Felder nachgewiesen
• Ley-Linien-Kreuzungspunkt
• Besucher berichten von ungewöhnlichen Bewusstseinszuständen

Das größte Rätsel bleibt: Woher hatte eine steinzeitliche Gesellschaft das astronomische Wissen für solch präzise Berechnungen?''',
        location: const LatLng(51.1789, -1.8262),
        category: 'archaeology',
        date: DateTime(3000, 1, 1).subtract(const Duration(days: 365 * 5000)),
        imageUrl:
            'https://images.unsplash.com/photo-1599833975787-5d6f8c5c3b45?w=1200&q=80',
        videoUrl: 'https://www.youtube.com/watch?v=BPWVQ-Wy-jY',
        documentUrl:
            'https://www.english-heritage.org.uk/visit/places/stonehenge/',
        tags: [
          'England',
          'Stonehenge',
          'Megalith',
          'Sonnenwende',
          'Astronomisches Observatorium',
          'Ley-Linien',
        ],
        source: 'English Heritage',
        isVerified: true,
        resonanceFrequency: 7.83,
      ),

      // ========================================
      // ATLANTIK - Bermuda-Dreieck
      // ========================================
      EventModel(
        id: '7',
        title: 'Das Bermuda-Dreieck - Zone der Mysterien',
        description:
            '''Das Bermuda-Dreieck, ein Gebiet im westlichen Atlantik zwischen Miami, Bermuda und Puerto Rico, ist berüchtigt für unerklärliche Verschwinden von Schiffen und Flugzeugen.

Die berühmtesten Fälle:

Flight 19 (5. Dezember 1945):
• 5 US Navy Bomber verschwanden spurlos
• 14 Besatzungsmitglieder
• Letzter Funkspruch: "Wir wissen nicht, wo wir sind... Das Meer sieht seltsam aus"
• Das Rettungsflugzeug verschwand ebenfalls!

USS Cyclops (1918):
• Größtes Schiff der US Navy ohne Kampfeinwirkung verloren
• 309 Menschen an Bord
• Keine Notsignale, keine Wrackteile gefunden
• Bis heute ungeklärt

Wissenschaftliche Erklärungen:
• Methanhydrat-Ausbrüche: Gasblasen verringern die Wasserdichte → Schiffe sinken
• Freak Waves (Monsterwellen): Bis 30m hohe Einzelwellen
• Magnetische Anomalien: Kompass-Abweichungen dokumentiert
• Golfstrom: Starke Strömungen löschen Spuren aus

Alternative Theorien:
• Dimensionsportale / Zeitanomalien
• Außerirdische Basis unter Wasser
• Atlantis-Technologie aktiv
• Verbindung zu Unterwasser-Pyramiden (2012 via Sonar entdeckt!)

Die Statistik sagt: Die Unfallrate im Bermuda-Dreieck ist nicht höher als anderswo. Aber wie erklärt man die mysteriösen Umstände der prominenten Fälle?''',
        location: const LatLng(25.0000, -71.0000),
        category: 'phenomenon',
        date: DateTime(1945, 12, 5),
        imageUrl:
            'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=1200&q=80',
        videoUrl: 'https://www.youtube.com/watch?v=AgMcqNnqatw',
        tags: [
          'Bermuda',
          'Anomalie',
          'Magnetfeld',
          'Flight 19',
          'USS Cyclops',
          'Paranormal',
        ],
        source: 'US Navy Historical Archives',
        isVerified: false,
        resonanceFrequency: 6.66,
      ),

      // ========================================
      // MEXIKO - Teotihuacán
      // ========================================
      EventModel(
        id: '8',
        title: 'Teotihuacán - Die Stadt der Götter',
        description:
            '''Teotihuacán, etwa 50 km nordöstlich von Mexiko-Stadt, war einst die größte Stadt Amerikas (125.000+ Einwohner im Jahr 450 n.Chr.). Der Name bedeutet auf Nahuatl "Ort, wo man zu einem Gott wird".

Die Sonnenpyramide:
• Höhe: 65 Meter
• Basis: 225 x 225 Meter
• Volumen: 1,2 Millionen m³
• Genau auf den Sonnenuntergang am 12. August ausgerichtet (Maya-Kalender Nullpunkt!)

Mysteriöse Stadtplanung:
Die gesamte Stadt ist nach einem präzisen geometrischen Plan angelegt:
• Hauptachse ("Avenue of the Dead"): 15,5° von Nordausrichtung abweichend
• Grund: Ausrichtung auf Untergang der Plejaden!
• Mathematische Proportionen zwischen Pyramiden entsprechen planetaren Orbits

Hugh Harleston's Entdeckung (1974):
Die Abstände zwischen den Bauwerken bilden ein maßstabsgetreues Modell unseres Sonnensystems! Die "Hunab"-Einheit (1,059 m) taucht überall auf:
• Sonnenpyramide: 233,5 Hunab an der Basis
• Mond-Pyramide: Verhältnis zur Sonnenpyramide = Größenverhältnis Mond/Sonne!

Verborgene Kammern:
2003 wurde unter der Sonnenpyramide ein 100m langer Tunnel mit vier Kammern entdeckt. Was befindet sich dort? Die Ausgrabungen laufen noch...

Akustische Anomalien:
An bestimmten Punkten vor der Federserpent-Pyramide erzeugt Händeklatschen ein Echo, das wie ein Quetzal-Vogelschrei klingt. Zufall oder Ingenieurskunst?

Das größte Rätsel: Wer baute Teotihuacán wirklich? Als die Azteken die Stadt 1300 n.Chr. fanden, war sie bereits 700 Jahre verlassen und niemand wusste mehr, wer sie erbaut hatte!''',
        location: const LatLng(19.6925, -98.8438),
        category: 'archaeology',
        date: DateTime(100, 1, 1),
        imageUrl:
            'https://images.unsplash.com/photo-1518638150340-f706e86654de?w=1200&q=80',
        videoUrl: 'https://www.youtube.com/watch?v=KICk4H1ZpEw',
        documentUrl:
            'https://www.inah.gob.mx/zonas/146-zona-arqueologica-de-teotihuacan',
        tags: [
          'Mexiko',
          'Teotihuacán',
          'Sonnenpyramide',
          'Astronomische Ausrichtung',
          'Stadtplanung',
          'Plejaden',
        ],
        source: 'INAH (Instituto Nacional de Antropología e Historia)',
        isVerified: true,
        resonanceFrequency: 7.94,
      ),

      // ========================================
      // ASIEN - Angkor Wat
      // ========================================
      EventModel(
        id: '9',
        title: 'Angkor Wat - Das kosmische Mandala',
        description:
            '''Angkor Wat in Kambodscha ist der größte religiöse Baukomplex der Welt. Ursprünglich ein Hindu-Tempel (Vishnu gewidmet), später zum buddhistischen Tempel konvertiert, verkörpert er kosmische Prinzipien in Stein.

Dimensionen der Perfektion:
• Haupttempel: 1,5 km x 1,3 km
• Zentralturm: 65 Meter hoch (Symbol des Weltenbergs Meru)
• Wassergraben: 190 Meter breit (Symbol des kosmischen Ozeans)
• Gesamtanlage: Über 400 km²!

Astronomische Präzision:
Die gesamte Anlage ist ein riesiger Steinkalender:
• Exakte Ost-West-Ausrichtung
• Äquinoktium: Die Sonne geht genau über dem Zentralturm auf
• Die 72 Tempel der Anlage = 72 Erdenjahre = 1 Grad der Präzession
• Verhältnis Höhe/Umfang = präzessionaler Zyklus (25.920 Jahre / 360°)!

Graham Hancock's Entdeckung:
Die Anzahl der Säulen, Stufen und Terrassen kodiert astronomische Zyklen:
• 1.728 Stufen = Dauer des Satya Yuga (1.728.000 Jahre)
• Maße der Wassergräben = Durchmesser von Mond und Sonne!

Hydraulische Meisterleistung:
Das Wassersystem der Khmer-Zivilisation war revolutionär:
• Riesige Stauseen (Barays)
• Ausgeklügeltes Kanalsystem
• Ermöglichte 3 Reisernten pro Jahr
• Moderne Satelliten-Analysen enthüllen noch größere, verborgene Strukturen!

Archäoastronomie:
Robert Bauval entdeckte: Die wichtigsten Tempel von Angkor bilden am Boden die Konstellation des Draco (Drachen) nach, wie sie 10.500 v.Chr. am Himmel stand. Warum dieses uralte Datum?

Ein Tempel als Vermächtnis verlorener Weisheit?''',
        location: const LatLng(13.4125, 103.8670),
        category: 'archaeology',
        date: DateTime(1113, 1, 1),
        imageUrl:
            'https://images.unsplash.com/photo-1563640419859-293fd3655e97?w=1200&q=80',
        videoUrl: 'https://www.youtube.com/watch?v=qk6gZFU7mHQ',
        documentUrl: 'https://whc.unesco.org/en/list/668',
        tags: [
          'Kambodscha',
          'Angkor Wat',
          'Khmer',
          'Astronomisches Observatorium',
          'Kosmische Architektur',
          'Präzession',
        ],
        source: 'UNESCO World Heritage Centre',
        isVerified: true,
        resonanceFrequency: 8.01,
      ),

      // ========================================
      // OZEANIEN - Osterinsel (Rapa Nui)
      // ========================================
      EventModel(
        id: '10',
        title: 'Osterinsel - Die Moai und ihr Geheimnis',
        description:
            '''Die Osterinsel (Rapa Nui), die isolierteste bewohnte Insel der Welt, ist Heimat von 887 monumentalen Moai-Statuen. Diese bis zu 10 Meter hohen und 82 Tonnen schweren Steinkolosse werfen fundamentale Fragen auf.

Die Moai-Mysterien:

Transport-Rätsel:
Wie transportierten die Rapa Nui diese Kolosse über die Insel?
• Offizielle Theorie: Holzrollen und Seile
• Problem: Die Insel war zur Moai-Zeit bereits weitgehend entwaldet
• Alternative Theorie: Die Moai "gingen" (wurden aufrecht geschaukelt) - experimentell bewiesen!
• Thor Heyerdahl: Fortgeschrittene Hebelsysteme

Die roten Hüte (Pukao):
Viele Moai tragen rote Zylinder (bis 12 Tonnen). Wie wurden diese auf 10m hohe Statuen gehoben? Ohne Kräne? Ohne Räder?

Rongorongo-Schrift:
Die Osterinsel besitzt eine eigene, bis heute unentzifferte Schrift. Nur 26 Holztafeln existieren noch (die meisten wurden von Missionaren verbrannt!). Was steht darauf?
• Manche Forscher sehen Verbindungen zur Indus-Schrift
• Andere zu alt-ägyptischen Hieroglyphen
• Oder ist es eine vollkommen eigenständige Entwicklung?

Ökologische Katastrophe:
Die Rapa Nui-Zivilisation kollabierte vor europäischem Kontakt. Grund:
• Komplette Abholzung der Insel für Moai-Transport?
• Klimawandel?
• Krieg zwischen konkurrierenden Clans?
• Rattenplagen (Ratten fraßen alle Palmensamen)?

Alternative Theorien:
• Thor Heyerdahl: Verbindungen zu Südamerika (Kon-Tiki-Expedition)
• Graham Hancock: Überbleibsel einer untergegangenen Pazifik-Zivilisation (Mu/Lemuria)
• Lokale Legenden: Die Moai wanderten selbst durch Mana (göttliche Kraft)

Die Moai blicken ins Landesinnere (außer den 7 Ahu Akivi, die aufs Meer schauen). Warum? Beschützten sie die Lebenden oder wachten sie über die Ahnen?''',
        location: const LatLng(-27.1127, -109.3497),
        category: 'mystery',
        date: DateTime(1200, 1, 1),
        imageUrl:
            'https://images.unsplash.com/photo-1611727640537-2c8e03d407fa?w=1200&q=80',
        videoUrl: 'https://www.youtube.com/watch?v=oOLM5hCJJzY',
        documentUrl: 'https://www.worldhistory.org/Rapa_Nui/',
        tags: [
          'Osterinsel',
          'Moai',
          'Rapa Nui',
          'Rongorongo',
          'Megalith-Statuen',
          'Pazifik-Mysterium',
        ],
        source: 'World History Encyclopedia',
        isVerified: true,
        resonanceFrequency: 7.55,
      ),

      // ========================================
      // WEITERE EVENTS - Kurze Versionen
      // ========================================
      EventModel(
        id: '11',
        title: 'Puma Punku - Die unmöglichen Steine',
        description:
            '''Puma Punku in Bolivien präsentiert einige der präzisesten Steinbearbeitungen der prähistorischen Welt. H-förmige Andesit-Blöcke zeigen maschinelle Präzision mit Toleranzen unter 1mm - ohne Metallwerkzeuge! Winkelige Ausschnitte und ineinander greifende Verbindungen wirken wie moderne Fertigteile.''',
        location: const LatLng(-16.5575, -68.6820),
        category: 'archaeology',
        date: DateTime(536, 1, 1),
        imageUrl:
            'https://images.unsplash.com/photo-1526392060635-9d6019884377?w=1200&q=80',
        videoUrl: 'https://www.youtube.com/watch?v=UbZOMz5i0bw',
        tags: [
          'Bolivien',
          'Puma Punku',
          'Tiwanaku',
          'Präzisions-Steinmetzkunst',
          'Ancient Engineering',
        ],
        isVerified: true,
        resonanceFrequency: 8.67,
      ),

      EventModel(
        id: '12',
        title: 'Sacsayhuamán - Die Festung der Riesen',
        description:
            '''Die megalithische Festungsanlage über Cusco, Peru, besteht aus polygonalen Steinblöcken bis 200 Tonnen. Die Fugen sind so präzise, dass keine Rasierklinge dazwischen passt. Keine Verwendung von Mörtel! Die Inka behaupteten, sie hätten Sacsayhuamán nicht gebaut - sie fanden es bereits vor.''',
        location: const LatLng(-13.5085, -71.9819),
        category: 'archaeology',
        date: DateTime(1100, 1, 1),
        imageUrl:
            'https://images.unsplash.com/photo-1587595431623-881acd7c8b78?w=1200&q=80',
        videoUrl: 'https://www.youtube.com/watch?v=c0E93qEZSqo',
        tags: [
          'Peru',
          'Cusco',
          'Sacsayhuamán',
          'Megalith',
          'Inka',
          'Polygonale Mauern',
        ],
        isVerified: true,
        resonanceFrequency: 8.34,
      ),

      EventModel(
        id: '13',
        title: 'Baalbek - Plattform der Giganten',
        description:
            '''Die römischen Tempel von Baalbek im Libanon stehen auf einer megalithischen Plattform mit den größten behauenen Steinen der Welt. Die "Trilithon"-Blöcke wiegen je 800 Tonnen! Im Steinbruch liegt ein noch größerer Block: "Hajjar al-Hibla" (1.200 Tonnen). Wie wurden diese bewegt?''',
        location: const LatLng(34.0059, 36.2036),
        category: 'archaeology',
        date: DateTime.now().subtract(const Duration(days: 365 * 4000)),
        imageUrl:
            'https://images.unsplash.com/photo-1578271887552-5ac3a72752bc?w=1200&q=80',
        videoUrl: 'https://www.youtube.com/watch?v=BpLVJKe3Oo0',
        tags: [
          'Libanon',
          'Baalbek',
          'Trilithon',
          'Megalith',
          'Römisch',
          'Antike Technologie',
        ],
        source: 'Lebanese Ministry of Culture',
        isVerified: true,
        resonanceFrequency: 8.21,
      ),

      EventModel(
        id: '14',
        title: 'Derinkuyu - Die unterirdische Stadt',
        description:
            '''In Kappadokien, Türkei, liegt eine der größten unterirdischen Städte der Welt. Derinkuyu erstreckt sich über 18 Etagen bis 85 Meter Tiefe und bot Platz für 20.000 Menschen! Mit Belüftungssystemen, Weinkellern, Kapellen, Schulen. Wer baute dies und warum?''',
        location: const LatLng(38.3734, 34.7350),
        category: 'archaeology',
        date: DateTime(800).subtract(const Duration(days: 365 * 2800)),
        imageUrl:
            'https://images.unsplash.com/photo-1609137144813-7d9921338f24?w=1200&q=80',
        videoUrl: 'https://www.youtube.com/watch?v=1uwR5zzUC24',
        tags: [
          'Türkei',
          'Kappadokien',
          'Derinkuyu',
          'Unterirdische Stadt',
          'Schutzanlage',
        ],
        isVerified: true,
        resonanceFrequency: 7.12,
      ),

      EventModel(
        id: '15',
        title: 'Yonaguni-Monument - Japans Atlantis',
        description:
            '''Vor der Küste Japans liegt eine massive Unterwasser-Struktur mit rechtwinkligen Stufen, Säulen und Terrassen. Geologische Formation oder 10.000 Jahre alte Megalith-Stadt? Die Debatte spaltet Wissenschaftler. Treppenartige Strukturen, gerade Kanten und Straßen sprechen für menschlichen Ursprung.''',
        location: const LatLng(24.4333, 123.0000),
        category: 'mystery',
        date: DateTime.now().subtract(const Duration(days: 365 * 10000)),
        imageUrl:
            'https://images.unsplash.com/photo-1583508915901-b5f84c1dcde1?w=1200&q=80',
        videoUrl: 'https://www.youtube.com/watch?v=gEzqJbzPRdk',
        tags: [
          'Japan',
          'Yonaguni',
          'Unterwasser-Ruinen',
          'Atlantis',
          'Prähistorisch',
        ],
        isVerified: false,
        resonanceFrequency: 6.88,
      ),

      // ========================================
      // HISTORISCHE EREIGNISSE & ALTERNATIVE THEORIEN
      // ========================================
      EventModel(
        id: '26',
        title: 'JFK-Attentat - Dallas 1963',
        description:
            '''Am 22. November 1963 wurde Präsident Kennedy erschossen - Amerikas größtes ungeklärtes Rätsel.

DIE OFFIZIELLE VERSION:
Lee Harvey Oswald feuerte drei Schüsse vom Texas School Book Depository. Der Warren-Report kam zum Schluss: Einzeltäter.

ALTERNATIVE THEORIEN:

Die Magische-Kugel-Theorie: Eine Kugel soll Kennedy und Gouverneur Connally getroffen, 7 Wunden verursacht und 15cm Knochen zerschmettert haben.

Der Zapruder-Film: Das Amateur-Video zeigt Kennedys Kopf nach hinten schnellend - deutet auf Schuss von vorne hin.

Jack Rubys Mord an Oswald: 48 Stunden nach dem Attentat - verhinderte jeden Prozess.

CIA-Verbindungen: Neu freigegebene Dokumente (2024/2025) zeigen CIA-Operationen gegen Castro.

Mafia-Beteiligung: Die Kennedys gingen hart gegen organisierte Kriminalität vor.

FAKTEN:
• 60+ Zeugen hörten Schüsse vom Grassy Knoll
• House Committee (1979): "Wahrscheinlich mehrere Täter"
• 3.000+ CIA-Dokumente bleiben klassifiziert
• 70% der Amerikaner glauben nicht an Einzeltäter-Theorie''',
        location: const LatLng(32.7767, -96.8080), // Dealey Plaza, Dallas
        category: 'mystery',
        date: DateTime(1963, 11, 22),
        imageUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/5/52/John_F._Kennedy%2C_White_House_color_photo_portrait.jpg/400px-John_F._Kennedy%2C_White_House_color_photo_portrait.jpg',
        tags: [
          'JFK',
          'Attentat',
          'CIA',
          'Warren Commission',
          'Ungeklärte Fragen',
        ],
        source:
            'Warren Commission Report, House Select Committee (1979), Declassified CIA Documents',
        isVerified: true,
        resonanceFrequency: 7.88,
      ),

      EventModel(
        id: '27',
        title: 'COVID-19 Ursprung - Wuhan 2019',
        description:
            '''Der Ursprung von COVID-19 bleibt eines der größten Mysterien unserer Zeit.

NATÜRLICHER URSPRUNG VS. LABOR-LECK:

Zoonose-Theorie: SARS-CoV-2 sprang von Fledermäusen über Zwischenwirt auf Menschen über (Huanan-Seafood-Markt).

Beweise dafür:
• 96,2% genetische Ähnlichkeit zu Fledermaus-Coronaviren
• Frühe Fälle konzentrierten sich um Tiermarkt
• Historische Präzedenzfälle (SARS 2003, MERS 2012)

Labor-Leck-Theorie: Virus entkam aus Wuhan Institute of Virology (8 km vom Ausbruchsort).

Beweise dafür:
• WIV führte Gain-of-Function-Forschung durch
• 3 WIV-Forscher erkrankten November 2019
• Ungewöhnliche Furin-Spaltungsstelle im Genom
• Chinas mangelnde Transparenz

AKTUELLE LAGE (2024/2025):
• US-Kongress-Bericht (Dez 2024): "Beweise deuten auf Labor hin"
• FBI & DoE: "Moderates Vertrauen" in Labor-Leck
• WHO: Beide Theorien bleiben "auf dem Tisch"
• 770 Millionen+ Fälle, 7 Millionen+ Tote weltweit''',
        location: const LatLng(30.5928, 114.3055), // Wuhan, China
        category: 'mystery',
        date: DateTime(2019, 12, 31),
        imageUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/SARS-CoV-2_without_background.png/400px-SARS-CoV-2_without_background.png',
        tags: ['COVID-19', 'Pandemie', 'Wuhan', 'Labor-Leck', 'WHO'],
        source: 'WHO Reports, US Congressional Report (2024), NIH Documents',
        isVerified: true,
        resonanceFrequency: 8.12,
      ),

      EventModel(
        id: '28',
        title: 'Operation Paperclip - Nazi-Wissenschaftler',
        description:
            '''Nach WWII starteten die USA ein geheimes Programm: Über 1.600 deutsche Wissenschaftler - viele hochrangige Nazis - wurden in die USA gebracht.

DIE MISSION:
Technologie-Vorsprung sichern, bevor die Sowjetunion zugreift. Der Kalte Krieg machte Nazi-Raketen zu strategischen Prioritäten.

PROMINENTE REKRUTEN:

Wernher von Braun: SS-Sturmbannführer, V-2-Entwickler. In USA: Vater des Raumfahrtprogramms, Saturn-V für Mondlandung 1969.

Arthur Rudolph: Produktionsleiter KZ Mittelbau-Dora (12.000 Tote). In USA: Saturn-V-Produktionsleiter.

Hubertus Strughold: "Vater der Weltraummedizin". Anschuldigungen: Menschenversuche in Dachau.

DIE VERTUSCHUNG:
• JIOA fälschte Akten
• SS-Mitgliedschaften wurden gelöscht
• Kriegsverbrechen ignoriert

MORALISCHE KONTROVERSE:
Pro: Verhinderte sowjetischen Tech-Vorteil, ermöglichte Mondlandung
Contra: Kriegsverbrecher entkamen Gerechtigkeit

LANGZEITFOLGEN:
• US-Weltraumprogramm profitierte enorm
• Ethische Standards untergraben
• Präzedenzfall für "Zweck heiligt Mittel"''',
        location: const LatLng(38.9072, -77.0369), // Washington D.C.
        category: 'historical',
        date: DateTime(1945, 8, 15),
        imageUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c7/Wernher_von_Braun_1960.jpg/400px-Wernher_von_Braun_1960.jpg',
        tags: [
          'Operation Paperclip',
          'Nazis',
          'Wernher von Braun',
          'NASA',
          'Kriegsverbrechen',
        ],
        source:
            'Declassified US Documents, Annie Jacobsen "Operation Paperclip"',
        isVerified: true,
        resonanceFrequency: 7.73,
      ),

      EventModel(
        id: '29',
        title: '9/11 Terror-Anschläge - New York 2001',
        description:
            '''11. September 2001: Vier koordinierte Terroranschläge veränderten die Welt für immer.

ZEITLEISTE:
08:46 - Flug 11 trifft Nord-Turm
09:03 - Flug 175 trifft Süd-Turm
09:37 - Flug 77 trifft Pentagon
09:59 - Süd-Turm kollabiert
10:28 - Nord-Turm kollabiert

TRAGÖDIE:
• 2.977 Tote (+ 19 Attentäter)
• 6.000+ Verletzte
• 343 Feuerwehrleute starben

ALTERNATIVE THEORIEN:

Kontrollierte Sprengung: Gebäude fielen zu perfekt/symmetrisch
Widerlegung: NIST dokumentierte asymmetrischen Einsturz, keine Sprengstoff-Beweise

Pentagon-Rakete: Kleine Einschlagstelle, fehlendes Wrack
Widerlegung: Hunderte Augenzeugen sahen Flugzeug 77, Wrackteile dokumentiert

Inside Job: US-Regierung wusste Bescheid
Faktenlage: CIA hatte vage Warnungen, aber keine konkreten Pläne

UNGEKLÄRTE FRAGEN:
• Saudi-Arabien Verbindung (15/19 Attentäter)
• 28 Seiten blieben jahrelang geheim
• Pakistan ISI transferierte 100.000 Dollar an Atta

GLOBALE FOLGEN:
• War on Terror (Afghanistan, Irak)
• Patriot Act - Überwachungsausweitung
• Islamophobie nahm drastisch zu''',
        location: const LatLng(40.7128, -74.0060), // Ground Zero, NYC
        category: 'historical',
        date: DateTime(2001, 9, 11),
        imageUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/World_Trade_Center%2C_New_York_City_-_aerial_view_%28March_2001%29.jpg/400px-World_Trade_Center%2C_New_York_City_-_aerial_view_%28March_2001%29.jpg',
        tags: [
          '9/11',
          'World Trade Center',
          'Al-Qaeda',
          'Terrorismus',
          'Pentagon',
        ],
        source: '9/11 Commission Report, NIST Reports, FBI Investigation',
        isVerified: true,
        resonanceFrequency: 8.45,
      ),

      EventModel(
        id: '30',
        title: 'Area 51 & Roswell UFO - Nevada 1947',
        description:
            '''Area 51: Amerikas geheimste Militärbasis und Zentrum der UFO-Mythen.

ROSWELL CRASH (Juli 1947):
Offizielle Version: Wetterballon stürzte ab
Alternative Theorie: Außerirdisches Raumschiff mit Alien-Leichen

PENTAGON-ENTHÜLLUNG (2025):
Pentagon pflanzte absichtlich UFO-Narrative, um geheime Waffenprogramme zu verbergen!

AREA 51 REALITÄT:
Declassified Dokumente bestätigen:
• U-2 Spionageflugzeug-Tests
• F-117 Stealth-Bomber-Entwicklung
• Viele "UFO-Sichtungen" waren geheime Militärjets

BOB LAZAR'S BEHAUPTUNGEN (1989):
• Arbeitete an außerirdischer Technologie in S-4
• Zurück-Engineering von 9 UFOs
• Element 115 als Antrieb
Kontroverse: Keine Beweise für Bildungsabschlüsse

PROJECT BLUE BOOK (1952-1969):
• 12.618 UFO-Sichtungen untersucht
• 701 blieben "unidentified"
• Offiziell geschlossen 1969

WARUM DIE MYTHEN BESTEHEN:
• Regierungs-Geheimhaltung nährt Spekulationen
• Historische Lügen (z.B. U-2-Vertuschung)
• Menschliche Neugier nach Außerirdischem''',
        location: const LatLng(37.2350, -115.8111), // Area 51, Nevada
        category: 'mystery',
        date: DateTime(1947, 7, 8),
        imageUrl:
            'https://images.unsplash.com/photo-1614728894747-a83421e2b9c9?w=1200&q=80',
        tags: ['Area 51', 'Roswell', 'UFO', 'Aliens', 'Pentagon', 'Bob Lazar'],
        source:
            'Pentagon DoD Report, National Archives Project Blue Book, Declassified Documents',
        isVerified: true,
        resonanceFrequency: 8.88,
      ),

      EventModel(
        id: '31',
        title: 'MK-Ultra - CIA Mind Control',
        description:
            '''MK-Ultra: Das illegale CIA-Programm zur Gedankenkontrolle (1953-1973).

DAS PROGRAMM:
• 130+ geheime Experimente
• Universitäten, Krankenhäuser, Gefängnisse
• Ziel: Verhörmethoden, Gedankenkontrolle, Wahrheitsserum

SIDNEY GOTTLIEB - "Poisoner in Chief":
CIA-Chemiker leitete MK-Ultra. Experimente mit LSD, Elektroschocks, sensorischer Deprivation.

METHODEN:
• LSD-Tests an unwissenden Bürgern
• Elektroschock-"Therapie"
• Hypnose & Drogen-Kombinationen
• Sensorische Deprivation
• Verbale & sexuelle Misshandlung

BERÜCHTIGTE FÄLLE:

Fort Detrick: Kentucky-Gefängnis, Häftlinge erhielten 75 Tage LSD
McGill University: Dr. Ewen Cameron's "psychic driving" - Patienten wochenlang im Koma
Frank Olson: CIA-Wissenschaftler, LSD verabreicht, "fiel" aus Fenster (Mord?)

ENTHÜLLUNG:
• 1973: CIA-Direktor zerstörte die meisten Akten
• 1975: Church Committee deckte MK-Ultra auf
• 1977: FOIA-Anfragen brachten 20.000 Dokumente ans Licht

OPFER:
• Tausende unwissende Testpersonen
• Viele litten lebenslang an psychischen Schäden
• Keine Entschädigung für die meisten

VERMÄCHTNIS:
MK-Ultra wurde zum Symbol für Regierungsmissbrauch und nährte kontroverse Hypothesen über Mind Control bis heute.''',
        location: const LatLng(38.8816, -77.1082), // Fort Detrick, Maryland
        category: 'mystery',
        date: DateTime(1953, 4, 13),
        imageUrl:
            'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=1200&q=80',
        tags: ['MK-Ultra', 'CIA', 'Mind Control', 'LSD', 'Sidney Gottlieb'],
        source:
            'CIA FOIA Documents, Senate Church Committee Report (1975), NPR Investigation',
        isVerified: true,
        resonanceFrequency: 7.66,
      ),

      EventModel(
        id: '32',
        title: 'Illuminati - Bayerische Geheimgesellschaft',
        description:
            '''Die Illuminati: Von historischer Realität zu modernem Mythos.

HISTORISCHE FAKTEN:

Gründung 1776:
• Adam Weishaupt, Ingolstadt, Bayern
• Orden der Illuminati ("Die Erleuchteten")
• Ziel: Monarchien abschaffen, Religion durch Vernunft ersetzen

Aufstieg & Fall:
• Aufklärung: Vernunft, Freiheit, Gleichheit
• Mitglieder: Intellektuelle, Freimaurer
• 1785: Kurfürst verbot Geheimgesellschaften
• 1787: Ordre löste sich auf (nur 11 Jahre!)

MODERNE ALTERNATIVE THEORIEN:

New World Order: Illuminati kontrollieren heimlich die Weltregierung
Freimaurer-Verbindung: Gemeinsame Weltherrschaftspläne
Rothschild-Familie: Finanzieren angeblich Illuminati

POPULÄRKULTUR:
• US-Dollar: "Auge der Vorsehung" (All-Seeing Eye)
• Promis: Jay-Z, Beyoncé angeblich Mitglieder
• Filme: "Illuminati" (Dan Brown), "Eyes Wide Shut"

WARUM DIE MYTHEN BESTEHEN:

Psychologie: Menschen suchen Ordnung im Chaos
Machtstrukturen: Eliten existieren wirklich (Bilderberg, Davos)
Symbole: Dreiecke, Augen überall sichtbar

REALITÄT VS. FIKTION:
Historisch: Kurz existierende Aufklärungs-Gesellschaft
Modern: Sammelbegriff für Elite-Narrative''',
        location: const LatLng(48.7644, 11.4275), // Ingolstadt, Bayern
        category: 'mystery',
        date: DateTime(1776, 5, 1),
        imageUrl:
            'https://images.unsplash.com/photo-1509228468518-180dd4864904?w=1200&q=80',
        tags: [
          'Illuminati',
          'Adam Weishaupt',
          'Freimaurer',
          'NWO',
          'Geheimgesellschaft',
        ],
        source:
            'Britannica, National Geographic, ResearchGate Historical Study',
        isVerified: true,
        resonanceFrequency: 7.77,
      ),

      EventModel(
        id: '33',
        title: 'Philadelphia Experiment - USS Eldridge 1943',
        description:
            '''Oktober 1943: Angeblich machte die US Navy ein Schiff unsichtbar - mit verheerenden Folgen.

DIE LEGENDE:

Das Experiment:
• Ziel: USS Eldridge unsichtbar für Radar machen
• Elektromagnetische Felder um Schiff
• Schiff verschwand, teleportierte nach Norfolk, Virginia

Horror-Folgen:
• Crew wahnsinnig geworden
• Männer mit Schiffswänden verschmolzen
• Einige verschwanden für immer
• Überlebende litten an Zeitverlusten

QUELLEN DER LEGENDE:
• Carlos Allende (Carl Allen): Behauptete Augenzeuge
• Brief an Morris K. Jessup (1955)
• Verbindung zu Einstein's Unified Field Theory

US NAVY DEMENTIERUNG:

Offizielle Position:
• "Kein solches Experiment fand statt"
• USS Eldridge war nie in Philadelphia 1943
• Schiffslogbücher zeigen normale Operationen
• Crew-Mitglieder widersprachen der Geschichte

WISSENSCHAFTLICHE REALITÄT:

Was war möglich:
• Degaussing: Magnetische Entmagnetisierung (Minen-Schutz)
• Radar-Camouflage-Tests (frühe Stealth-Technologie)
• Optische Täuschungen durch Nebel

Warum Teleportation unmöglich war:
• Physikalisch keine Technologie vorhanden
• Einstein's UFT war unvollständig
• Keine Beweise in Archiven

WARUM DIE LEGENDE BESTEHT:
• Faszination mit Zeitreisen
• Sci-Fi-Popularität (Star Trek, X-Files)
• Misstrauen gegen Regierung nach MK-Ultra''',
        location: const LatLng(39.9526, -75.1652), // Philadelphia Naval Yard
        category: 'mystery',
        date: DateTime(1943, 10, 28),
        imageUrl:
            'https://images.unsplash.com/photo-1589519160732-57fc498494f8?w=1200&q=80',
        tags: [
          'Philadelphia Experiment',
          'USS Eldridge',
          'Teleportation',
          'Navy',
          'Zeitreise',
        ],
        source: 'US Naval History Command, Military.com Historical Analysis',
        isVerified: false,
        resonanceFrequency: 8.33,
      ),

      EventModel(
        id: '34',
        title: 'Apollo 11 Mondlandung - 1969',
        description:
            '''20. Juli 1969: "Ein kleiner Schritt für einen Menschen, ein riesiger Sprung für die Menschheit."

DIE MISSION:
• Start: 16. Juli 1969, Kennedy Space Center
• Besatzung: Neil Armstrong, Buzz Aldrin, Michael Collins
• Landung: 20. Juli, Mare Tranquillitatis (Meer der Ruhe)
• Rückkehr: 24. Juli 1969

TECHNISCHE MEISTERLEISTUNG:
Apollo Guidance Computer:
• 4 KB RAM, 72 KB ROM
• Weniger Rechenleistung als moderne Taschenrechner
• Navigierte präzise zum Mond und zurück!

Saturn V Rakete:
• Höhe: 110 Meter
• Gewicht: 3.000 Tonnen
• Leistung: 34 Millionen PS (entspricht 50 Boeing 747)

ALTERNATIVE THEORIEN:

Mondlandungs-Skepsis:
• Wehende Flagge (keine Atmosphäre?)
  → Wissenschaftlich erklärt: Flaggenstange-Bewegung + Trägheit
• Fehlende Sterne auf Fotos
  → Erklärt: Kurze Belichtungszeit für helle Mondoberfläche
• Identische Schatten-Winkel
  → Erklärt: Reflektiertes Sonnenlicht auf Mondoberfläche

Radiation Van Allen Belt:
• Kritik: Tödliche Strahlung würde Astronauten töten
• NASA-Antwort: Schnelle Durchquerung (wenige Stunden), Aluminium-Abschirmung ausreichend

Stanley Kubrick Theorie:
• Behauptung: Kubrick filmte gefälschte Mondlandung
• Widerlegung: Keine technischen Möglichkeiten 1969 (Slow-Motion Video, Lichttechnik)

BEWEISE FÜR ECHTHEIT:
• 382 kg Mondgestein (von 6 Missionen)
• Laser-Reflektoren auf dem Mond (bis heute messbar!)
• Sowjetunion bestätigte Landung (hätten Fälschung entlarvt)
• 400.000 NASA-Mitarbeiter (unmöglich geheim zu halten)

VERMÄCHTNIS:
• 12 Menschen betraten den Mond (Apollo 11, 12, 14, 15, 16, 17)
• Letzte Mission: Apollo 17 (Dezember 1972)
• Seit über 50 Jahren kein Mensch mehr auf dem Mond''',
        location: const LatLng(0.6734, 23.4731), // Mare Tranquillitatis
        category: 'historical',
        date: DateTime(1969, 7, 20),
        imageUrl:
            'https://images.unsplash.com/photo-1614728263952-84ea256f9679?w=1200&q=80',
        tags: [
          'Apollo 11',
          'Mondlandung',
          'NASA',
          'Neil Armstrong',
          'Space Race',
        ],
        source: 'NASA Archives, Apollo 11 Mission Reports',
        isVerified: true,
        resonanceFrequency: 7.69,
      ),

      EventModel(
        id: '35',
        title: 'Titanic Untergang - 1912',
        description:
            '''15. April 1912, 02:20 Uhr: Das "unsinkbare" Schiff sank im Nordatlantik.

DIE KATASTROPHE:
• Jungfernfahrt: Southampton → New York
• Kollision mit Eisberg: 14. April, 23:40 Uhr
• Sinkdauer: 2 Stunden 40 Minuten
• Tote: 1.514 von 2.224 Passagieren
• Überlebende: 710

TECHNISCHE FAKTEN:
RMS Titanic:
• Länge: 269 Meter
• Gewicht: 46.328 Tonnen
• Geschwindigkeit: 22 Knoten (41 km/h) - zu schnell für Eisberg-Gewässer!
• Rettungsboote: Nur für 1.178 Menschen (50% Kapazität)

Der Eisberg:
• 6-facher Warnungen ignoriert
• Kapitän Smith erhöhte Geschwindigkeit trotz Eisberg-Warnungen
• Nur 37 Sekunden vom Sichten bis Kollision

UNGEKLÄRTE MYSTERIEN:

Das Schwesterschiff-Szenario:
• Behauptung: Olympic (Schwesterschiff) wurde mit Titanic vertauscht
• Motiv: Versicherungsbetrug (Olympic war beschädigt)
• Beweise dagegen: Unterschiedliche Baudetails dokumentiert

JP Morgan's Absage:
• Besitzer J.P. Morgan sagte Reise kurzfristig ab
• Auch andere Eliten stornierten last minute
• Zufall oder Vorwissen?

Die Feuer-Theorie:
• Kohlebunker-Feuer brannte seit Belfast-Abfahrt
• Schwächte vermutlich Stahlrumpf an Kollisionsstelle
• 2017 durch Fotografien bestätigt!

Kapitän Smith's Entscheidungen:
• Warum volle Geschwindigkeit trotz Eisberg-Warnungen?
• Druck von White Star Line für Geschwindigkeitsrekord?

SS Californian - Das nahe Schiff:
• Nur 20 km entfernt, sah Notraketen
• Kapitän Lord ignorierte Signale (schlief)
• Hätte hunderte retten können!

VERMÄCHTNIS:
• SOLAS (Safety of Life at Sea) - internationale Seefahrt-Standards
• 24/7 Funkwache vorgeschrieben
• Rettungsboote für 100% Kapazität
• Internationale Eisberg-Patrouille gegründet''',
        location: const LatLng(41.7325, -49.9469), // Wrack-Position
        category: 'historical',
        date: DateTime(1912, 4, 15),
        imageUrl:
            'https://images.unsplash.com/photo-1548198806-7e91c9c84a77?w=1200&q=80',
        tags: ['Titanic', 'Schiffsunglück', 'Eisberg', 'Unsinkbar', 'Seefahrt'],
        source: 'British Wreck Commissioner Report, NOAA Research',
        isVerified: true,
        resonanceFrequency: 6.12,
      ),

      EventModel(
        id: '36',
        title: 'Pearl Harbor Angriff - 1941',
        description:
            '''7. Dezember 1941, 07:48 Uhr: "Ein Datum, das in Schande leben wird."

DER ANGRIFF:
Japanische Offensive:
• 353 Flugzeuge in 2 Wellen
• 6 Flugzeugträger
• Ziele: US-Pazifikflotte, Luftwaffenstützpunkte
• Dauer: 110 Minuten

Amerikanische Verluste:
• 2.403 Tote (1.177 auf USS Arizona allein)
• 1.178 Verwundete
• 8 Schlachtschiffe versenkt/beschädigt
• 188 Flugzeuge zerstört

KONTROVERSE FRAGEN:

"Roosevelt wusste Bescheid" - Theorie:
Behauptungen:
• USA hatte japanische Codes geknackt (MAGIC)
• Warnungen wurden ignoriert
• Roosevelt wollte Kriegseintritt (isolationistisches Amerika überzeugen)

Faktenlage:
• USA wusste: Japan plant IRGENDEINEN Angriff
• Wo und wann? Unklar (erwarteten Philippinen/Malaya)
• Keine konkrete Warnung für Pearl Harbor

McCollum Memo (1940):
• Navy Lieutenant Arthur McCollum: 8-Punkte-Plan
• Ziel: Japan zu Erstschlag provozieren
• Öl-Embargo, Flottenmanöver → Japan unter Druck
• War das absichtliche Provokation?

Warum war die Flotte in Pearl Harbor?
• Riskante Konzentration an einem Ort
• Alternative: Verteilung auf mehrere Häfen sicherer
• War es bewusste "Opfer-Strategie"?

Fehlende Flugzeugträger:
• USS Enterprise, Lexington, Saratoga waren auf See
• Zufall oder wurden sie absichtlich in Sicherheit gebracht?
• Verschwörungstheoretiker: Flugzeugträger waren wichtiger als alte Schlachtschiffe

KONSEQUENZEN:
• USA erklärt Japan den Krieg (8. Dezember)
• Deutschland erklärt USA den Krieg (11. Dezember)
• Ende der amerikanischen Isolation
• Mobilisierung: 16 Millionen Amerikaner im Militär
• Wendepunkt des Zweiten Weltkriegs''',
        location: const LatLng(21.3644, -157.9500), // Pearl Harbor, Hawaii
        category: 'historical',
        date: DateTime(1941, 12, 7),
        imageUrl:
            'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=1200&q=80',
        tags: ['Pearl Harbor', 'WWII', 'Japan', 'USA', 'Pazifikkrieg'],
        source: 'US National Archives, Pearl Harbor Investigations',
        isVerified: true,
        resonanceFrequency: 7.41,
      ),

      EventModel(
        id: '37',
        title: 'Atombomben: Hiroshima & Nagasaki - 1945',
        description:
            '''August 1945: Zwei Städte, zwei Atombomben, der Beginn des Atomzeitalters.

HIROSHIMA - 6. August 1945, 08:15 Uhr:
"Little Boy":
• Uranbombe, 15 Kilotonnen TNT
• B-29 Bomber "Enola Gay"
• Detonation: 580 Meter Höhe
• Sofort-Tote: 70.000-80.000
• Bis Jahresende: 140.000 Tote (Strahlung)

NAGASAKI - 9. August 1945, 11:02 Uhr:
"Fat Man":
• Plutoniumbombe, 21 Kilotonnen TNT
• B-29 Bomber "Bockscar"
• Eigentliches Ziel: Kokura (Nebel verhinderte Angriff)
• Sofort-Tote: 40.000
• Bis Jahresende: 70.000 Tote

ETHISCHE KONTROVERSEN:

War es notwendig?
Pro-Argument (Truman):
• Rettete 1 Million alliierte Leben (geschätzte Verluste bei Invasion)
• Japan weigerte sich zu kapitulieren (Bushido-Kodex)
• Beendete Krieg schnell

Contra-Argumente:
• Japan war bereits besiegt (Flotte zerstört, Städte bombardiert)
• Sowjetunion würde August angreifen → Japan hätte kapituliert
• Demonstration auf unbewohnter Insel hätte gereicht?

Zivile Opfer:
• 95% der Toten: Zivilisten
• Kinder, Frauen, Alte
• Genfer Konvention: Angriffe auf Zivilisten verboten?
• USA-Argument: Totaler Krieg, japanische Zivilisten unterstützten Kriegsanstrengung

Alternative Theorien:

Die "Sowjet-Botschaft" Theorie:
• Eigentliches Ziel: Nicht Japan sondern Sowjetunion beeindrucken
• Demonstration der US-Übermacht
• Start des Kalten Krieges
• Stalin beschleunigte daraufhin sowjetisches Atomprogramm

Keine Warnung?
• Warum keine Evakuierung-Warnung für Zivilisten?
• USA warf Flugblätter ab - aber nach Hiroshima!
• Ethisch vertretbar?

LANGZEITFOLGEN:
Hibakusha (Überlebende):
• 200.000+ Überlebende litten an Strahlenkrankheit
• Krebs, Leukämie, genetische Schäden
• Soziale Stigmatisierung in Japan

Globale Auswirkungen:
• Wettrüsten: USA, UdSSR, UK, Frankreich, China, Israel, Indien, Pakistan, Nordkorea
• 70.000 Atomsprengköpfe auf dem Höhepunkt (1986)
• Heute: ~13.000 Sprengköpfe
• Doomsday Clock: 90 Sekunden vor Mitternacht (2024)''',
        location: const LatLng(34.3853, 132.4553), // Hiroshima
        category: 'historical',
        date: DateTime(1945, 8, 6),
        imageUrl:
            'https://images.unsplash.com/photo-1518241353330-0f7941c2d9b5?w=1200&q=80',
        tags: ['Atombombe', 'Hiroshima', 'Nagasaki', 'WWII', 'Nuklearwaffen'],
        source: 'Manhattan Project Archives, Hiroshima Peace Memorial Museum',
        isVerified: true,
        resonanceFrequency: 9.45,
      ),

      EventModel(
        id: '38',
        title: 'Tunguska-Ereignis - Sibirien 1908',
        description:
            '''30. Juni 1908, 07:17 Uhr: Die größte Explosion der modernen Geschichte - ohne Krater!

DIE EXPLOSION:
Dimensionen:
• Stärke: 10-15 Megatonnen TNT (1.000x Hiroshima!)
• 2.000 km² Wald niedergewalzt
• 80 Millionen Bäume umgeknickt
• Druckwelle: 2x um die Erde gemessen
• Helligkeit: Nächte hell wie Tag in London, 6.000 km entfernt!

Zeugenberichte:
• Augenzeugen 70 km entfernt: "Himmel spaltete sich in zwei"
• Hitzewelle: Kleidung in Flammen (60 km Entfernung)
• Seismische Wellen weltweit registriert
• Keine direkten Todesopfer (dünn besiedelt)

DAS RÄTSEL: KEIN KRATER!

Wissenschaftliche Theorien:

1. Meteor/Asteroid (Mainstream):
• Objekt: 50-100 Meter Durchmesser
• Luftexplosion: 5-10 km Höhe
• Zerplatzte vor Bodenkontakt
• Erklärt: Fehlender Krater, Baumfall-Muster
• Problem: Keine signifikanten Meteoriten-Fragmente gefunden

2. Komet-Theorie:
• Eiskomet explodierte in Atmosphäre
• Verdampfte komplett
• Erklärt: Fehlende Trümmer
• Problem: Ungewöhnlich für Kometen

3. Methangas-Explosion:
• Untertage-Gasausbruch
• Natürliche Explosion
• Problem: Erklärt nicht die Leuchterscheinungen

Alternative Theorien:

Schwarzes Loch:
• Mini-Schwarzes Loch durchschlug Erde
• Eintritt: Sibirien, Austritt: Nordatlantik
• Problem: Keine Physik-Beweise

Antimaterie:
• Antimaterie-Meteor
• Annihilation mit Materie
• Problem: Keine Gamma-Strahlung nachgewiesen

Außerirdisches Raumschiff:
• UFO-Absturz oder Selbstzerstörung
• Nukleare Explosion
• Problem: Keine Wrackteile, keine Radioaktivität

Tesla's Death Ray:
• Nikola Tesla testete angeblich Energiewaffe
• Wardenclyffe Tower Experiment
• Timeline passt: Tesla arbeitete 1908 an Energieübertragung
• Problem: Keine technischen Möglichkeiten für solche Reichweite

EXPEDITIONEN:

1927 - Leonid Kulik:
• Erste wissenschaftliche Expedition
• Fand: Radialer Baumfall, keine Krater
• Suchte vergeblich nach Meteoriten

1950-2000er:
• Mikroskopische Metallkügelchen gefunden
• Chemische Analyse: Außerirdische Herkunft bestätigt
• Aber: Zu wenig Material für eindeutige Schlüsse

BIS HEUTE UNGEKLÄRT:
• Genauer Explosionsmechanismus unklar
• Objektzusammensetzung unbekannt
• Warum so wenige Fragmente?''',
        location: const LatLng(60.8860, 101.8940), // Tunguska, Sibirien
        category: 'mystery',
        date: DateTime(1908, 6, 30),
        imageUrl:
            'https://images.unsplash.com/photo-1419242902214-272b3f66ee7a?w=1200&q=80',
        tags: ['Tunguska', 'Meteor', 'Explosion', 'Sibirien', 'Ungeklärt'],
        source: 'Russian Academy of Sciences, Tunguska Research Papers',
        isVerified: true,
        resonanceFrequency: 8.88,
      ),

      EventModel(
        id: '39',
        title: 'D-Day - Invasion der Normandie 1944',
        description:
            '''6. Juni 1944: Operation Overlord - Der Beginn des Endes für Nazi-Deutschland.

DIE INVASION:
Größte Amphibien-Operation der Geschichte:
• 156.000 alliierte Soldaten
• 5.000 Schiffe
• 11.000 Flugzeuge
• 5 Landungsabschnitte: Utah, Omaha, Gold, Juno, Sword

Landung 06:30 Uhr:
• Omaha Beach: Blutigste Schlacht (2.000+ Tote)
• Utah Beach: Leichteste Verluste (200 Tote)
• Kanadier (Juno), Briten (Gold, Sword): Mittlere Verluste

DIE PLANUNG:

Operation Fortitude - Die Täuschung:
• Größte Desinformations-Kampagne des Krieges
• Phantom-Armee unter General Patton (aufblasbare Panzer!)
• Falsche Funksprüche
• Deutsche erwarteten Calais (kürzeste Distanz)
• Täuschung gelang: Hitler hielt Normandie für Ablenkung

Wetter-Gambit:
• Eisenhower verschob von 5. auf 6. Juni (Sturm)
• Meteorologe: Kurzes Wetterfenster am 6. Juni
• Risiko: Bei Scheitern keine zweite Chance 1944
• Deutsche Kommandeure: Glaubten Invasion unmöglich bei dem Wetter

KONTROVERSEN:

Unnötige Opfer?
• Omaha Beach: Frontaler Angriff auf befestigte Stellungen
• Alternative: Mehr Bombardierung vorher?
• Generals wussten: Hohe Verluste unvermeidlich
• Ethik: Soldaten als "akzeptable Verluste"?

Sowjet-Druck:
• Stalin forderte jahrelang zweite Front
• D-Day entlastete Ostfront
• Aber: War Verzögerung bis 1944 strategisch oder politisch?
• Sowjetunion trug Hauptlast (27 Mio. Tote vs. 400.000 USA)

HELDENGESCHICHTEN:

Pointe du Hoc:
• 225 US Rangers kletterten 30m Klippen
• Eroberten deutsche Geschützstellungen
• 90% Verluste

Pegasus Bridge:
• Britische Glider-Truppen
• Eroberten Brücke in 10 Minuten
• Verhinderten deutsche Verstärkungen

Die "Bedford Boys":
• 35 Soldaten aus Bedford, Virginia
• 19 starben am D-Day (höchste Pro-Kopf-Verluste)
• Kleine Stadt verlor ganze Generation

WENDEPUNKT:
• 100.000 deutsche Soldaten tot/gefangen bis August
• Paris befreit: 25. August 1944
• Deutschland kapitulierte: 8. Mai 1945
• Ohne D-Day: Krieg hätte Jahre länger gedauert''',
        location: const LatLng(49.3700, -0.8500), // Normandie Strände
        category: 'historical',
        date: DateTime(1944, 6, 6),
        imageUrl:
            'https://images.unsplash.com/photo-1627916607164-7b20241db935?w=1200&q=80',
        tags: ['D-Day', 'Normandie', 'WWII', 'Operation Overlord', 'Allierte'],
        source: 'US National Archives, Imperial War Museum',
        isVerified: true,
        resonanceFrequency: 7.44,
      ),

      EventModel(
        id: '40',
        title: 'Tschernobyl-Katastrophe - 1986',
        description:
            '''26. April 1986, 01:23 Uhr: Die schlimmste nukleare Katastrophe der Geschichte.

DER UNFALL:
Reaktor 4 - RBMK-1000:
• Test der Notstromversorgung
• Sicherheitssysteme deaktiviert
• Leistung sank unkontrolliert auf 1% (sollte 25%)
• Panik: Leistung hochgefahren
• 01:23:40 - Explosion!

Die Explosion:
• Dampfexplosion hob 1.000-Tonnen-Deckel an
• Graphit-Brand (10 Tage)
• Radioaktiver Fallout: 400x Hiroshima
• 50 Tonnen radioaktives Material freigesetzt

UNMITTELBARE FOLGEN:

Die Liquidatoren:
• 600.000 "Liquidatoren" (Aufräumarbeiter)
• 134 akute Strahlenkrankheit (28 starben)
• Viele starben später an Krebs
• "Biorobots": Menschen räumten Trümmer vom Dach (Roboter versagten)
• 90 Sekunden Einsatzzeit pro Person (tödliche Strahlung)

Evakuierung Pripyat:
• 50.000 Einwohner
• 36 Stunden nach Unfall (zu spät!)
• "Temporäre" Evakuierung (nie zurückgekehrt)
• Geisterstadt bis heute

Der Sarkophag:
• 300.000 Tonnen Beton
• Gebaut in 6 Monaten (Oktober 1986)
• Sollte 30 Jahre halten
• 2016: Neuer Sarkophag (100 Jahre Lebensdauer)

URSACHEN - DIE SCHULDIGEN:

Sowjetisches Design:
• RBMK-Reaktor: Instabil bei niedriger Leistung
• Positive Void Coefficient (Kontrollstäbe verschlimmerten Situation)
• Westliche Reaktoren: Fail-Safe Design
• Kosten-Einsparungen opferten Sicherheit

Menschliches Versagen:
• Anatoly Dyatlov (stellv. Chefingenieur): Ignorierte Warnungen
• Test trotz gefährlicher Bedingungen
• Operatoren: Unzureichend ausgebildet
• Kultur der Geheimhaltung: Niemand wagte zu widersprechen

Sowjetische Vertuschung:
• Erste 36 Stunden: Totale Geheimhaltung
• Schweden detektierte Radioaktivität → UdSSR gezwungen zuzugeben
• Gorbatschow erfuhr erst Stunden später
• Minimierte offiziell Folgen

LANGZEITFOLGEN:

Radioaktive Kontamination:
• Sperrzone: 2.600 km² (30 km Radius)
• Halbwertszeit Plutonium: 24.000 Jahre
• Grundwasser kontaminiert
• Landwirtschaft unmöglich

Gesundheit:
• WHO: 4.000 Todesfälle (Krebs)
• Greenpeace: 200.000+ Todesfälle
• Schilddrüsenkrebs bei Kindern: 6.000+ Fälle
• Genetische Mutationen: Nicht vollständig erforscht

Politische Folgen:
• Gorbatschows Glasnost beschleunigt
• Vertrauen in Sowjetregierung erodiert
• Beitrag zum Fall der UdSSR (1991)
• Deutschland: Ausstieg aus Atomkraft beschleunigt

HEUTE:
• Sperrzone: Überraschende Wildnis-Erholung
• Wölfe, Bären, Luchse, Przewalski-Pferde
• 200+ "Samosely" (alte Menschen kehrten zurück)
• Tourismus: 10.000+ Besucher jährlich
• Kiew: Nur 100 km entfernt (3 Mio. Einwohner)''',
        location: const LatLng(51.3890, 30.0990), // Tschernobyl, Ukraine
        category: 'historical',
        date: DateTime(1986, 4, 26),
        imageUrl:
            'https://images.unsplash.com/photo-1595055865763-18f6eff1f95a?w=1200&q=80',
        tags: [
          'Tschernobyl',
          'Nuklear',
          'Katastrophe',
          'UdSSR',
          'Radioaktivität',
        ],
        source: 'IAEA Reports, WHO Chernobyl Studies, Ukrainian Archives',
        isVerified: true,
        resonanceFrequency: 9.86,
      ),

      EventModel(
        id: '41',
        title: 'Challenger Space Shuttle Explosion - 1986',
        description:
            '''28. Januar 1986, 11:39 Uhr: 73 Sekunden nach dem Start - Live im Fernsehen.

DIE MISSION:
STS-51-L:
• 10. Flug der Challenger
• 25. Space Shuttle Mission insgesamt
• Besatzung: 7 Astronauten
• Besonderheit: Christa McAuliffe (erste Lehrerin im All)

Die Crew:
• Commander Francis Scobee
• Pilot Michael Smith
• Judith Resnik (Missionsspezialistin)
• Ellison Onizuka (Missionsspezialist)
• Ronald McNair (Missionsspezialist)
• Gregory Jarvis (Nutzlastspezialist)
• Christa McAuliffe (Lehrerin, "Teacher in Space")

DIE KATASTROPHE:
11:38 Uhr - Start:
• Kennedy Space Center, LC-39B
• Temperatur: -1°C (kältester Shuttle-Start)
• Millionen schauten live zu (wegen McAuliffe)

73 Sekunden später:
• 14 km Höhe, Geschwindigkeit: Mach 1.92
• Explosion vor laufenden Kameras
• Shuttle zerfiel in Rauchfahne
• NASA Kommentar: "Obviously a major malfunction..."

URSACHE:

O-Ring Versagen:
• Rechter Feststoff-Booster
• Gummi O-Ring verhärtete bei Kälte
• Heißgas entkam, traf externen Tank
• Flüssigwasserstoff explodierte

Die tragische Wahrheit:
• Crew überlebte wahrscheinlich anfängliche Explosion
• Pilotenkapsel blieb 2+ Minuten intakt
• Astronauten bewusstlos durch Druckverlust
• Tod beim Aufprall auf Atlantik (333 km/h)
• 4 Personal Egress Air Packs (PEAPs) waren aktiviert

DER SKANDAL:

Engineers' Warnungen:
• Morton Thiokol (O-Ring Hersteller): Warnten NASA
• Bob Ebeling, Allan McDonald: "Start verschieben!"
• Temperatur zu niedrig für O-Ringe
• NASA ignorierte Bedenken

Management-Druck:
• Reagan sollte Shuttle im State of Union erwähnen
• Medialer Druck (Lehrer im All)
• Vorherige Starts bereits mehrfach verschoben
• "Go Fever" - Druck zu starten trotz Bedenken

Rogers Commission:
• Untersuchungskommission unter Reagan
• Richard Feynman (Physiker): Berühmte O-Ring-Demonstration (Glas Eiswasser)
• Fazit: "NASA organisatorisch fehlerhaft"
• "Normalization of Deviance": O-Ring-Probleme ignoriert

KONSEQUENZEN:

Programm-Stopp:
• 32 Monate keine Shuttle-Flüge
• Komplettes Redesign
• 2,4 Milliarden Dollar Verlust
• Discovery erste Mission: 29. Sept. 1988

Sicherheits-Verbesserungen:
• Neue O-Ring-Designs
• Verbesserte Heizung
• Temperatur-Limits
• Escape-System (Crew-Bailout)

Emotionale Wirkung:
• Reagan verschob State of Union
• Gedenkrede: "slipped the surly bonds of Earth to touch the face of God"
• Schulkinder weltweit traumatisiert (sahen live zu)

VERMÄCHTNIS:
• Columbia Katastrophe 2003: 7 weitere Astronauten
• Shuttle-Programm 2011 beendet
• 135 Missionen, 355 Astronauten
• Trotz 2 Katastrophen: 98,5% Erfolgsquote''',
        location: const LatLng(28.5729, -80.6490), // Kennedy Space Center
        category: 'historical',
        date: DateTime(1986, 1, 28),
        imageUrl:
            'https://images.unsplash.com/photo-1516849677043-ef67c9557e16?w=1200&q=80',
        tags: [
          'Challenger',
          'Space Shuttle',
          'NASA',
          'Katastrophe',
          'Raumfahrt',
        ],
        source: 'Rogers Commission Report, NASA Archives',
        isVerified: true,
        resonanceFrequency: 7.28,
      ),

      EventModel(
        id: '42',
        title: 'Erster Weltkrieg Beginn - 1914',
        description:
            '''28. Juli 1914: "Die Urkatastrophe des 20. Jahrhunderts" beginnt.

DER AUSLÖSER:
Sarajevo, 28. Juni 1914:
• Erzherzog Franz Ferdinand (Österreich-Ungarn) ermordet
• Attentäter: Gavrilo Princip (serbischer Nationalist)
• Österreich-Ungarn stellt Ultimatum an Serbien
• Serbien lehnt teilweise ab

Bündnissystem aktiviert:
• 28. Juli: Österreich-Ungarn erklärt Serbien Krieg
• Russland mobilisiert (Unterstützung Serbien)
• Deutschland erklärt Russland Krieg (Bündnis mit Österreich)
• Frankreich mobilisiert (Bündnis mit Russland)
• Deutschland marschiert durch Belgien → UK erklärt Krieg

DER KRIEG:
Westfront:
• Grabenkrieg: 700 km Front von Nordsee bis Schweiz
• Verdun (1916): 700.000 Tote in 10 Monaten
• Somme (1916): 1 Million Tote, 11 km Geländegewinn
• Erste Giftgas-Einsätze (Ypern 1915)

Ostfront:
• Russland vs. Deutschland & Österreich-Ungarn
• Millionen russische Kriegsgefangene
• Revolution 1917 → Russland steigt aus

NEUE KRIEGSTECHNOLOGIEN:
• Panzer (erste Einsatz: Somme 1916)
• Flugzeuge (Aufklärung → Kampfflugzeuge)
• Giftgas (Chlor, Senfgas)
• U-Boote (Deutschland: Uneingeschränkter U-Boot-Krieg)
• Maschinengewehre (60.000 Schuss/Minute)

KONTROVERSE FRAGEN:

Wer ist schuld?
• Deutschland: Blank-Scheck für Österreich
• Österreich: Unverhältnismäßiges Ultimatum
• Russland: Voreilige Mobilisierung
• UK: Hätte neutraler bleiben können?
• Historiker-Konsens: Geteilte Verantwortung

"Lions led by Donkeys"?
• Britische/französische Generäle: Sture Frontalangriffe
• Millionen Soldaten verheizt für Meter
• Technologie überholte Taktiken
• Aber: Lernkurve existierte (1918 mobiler Krieg)

GLOBALE AUSWIRKUNGEN:
Kriegsende 11. November 1918:
• 17 Millionen Tote (10 Mio. Soldaten, 7 Mio. Zivilisten)
• 21 Millionen Verwundete
• Spanische Grippe: 50-100 Mio. zusätzliche Tote (1918-1920)

Versailler Vertrag (1919):
• Deutschland: Alleinschuld, Reparationen (132 Mrd. Goldmark)
• Österreich-Ungarn zerfällt
• Osmanisches Reich endet
• Neue Staaten: Polen, Tschechoslowakei, Jugoslawien

VERMÄCHTNIS:
• "Der Krieg, der alle Kriege beendet" (war es nicht!)
• Grundlage für WWII (Versailles-Demütigung)
• Völkerbund gegründet (Vorgänger der UN)
• Ende der Monarchien (Deutschland, Österreich, Russland, Türkei)''',
        location: const LatLng(49.2583, 4.0333), // Verdun, Frankreich
        category: 'historical',
        date: DateTime(1914, 7, 28),
        imageUrl:
            'https://images.unsplash.com/photo-1509711522177-9a4dae9a2c75?w=1200&q=80',
        tags: [
          'WWI',
          'Erster Weltkrieg',
          'Verdun',
          'Grabenkrieg',
          'Weltgeschichte',
        ],
        source: 'Imperial War Museum, Bundesarchiv, National Archives',
        isVerified: true,
        resonanceFrequency: 6.14,
      ),

      EventModel(
        id: '43',
        title: 'Zweiter Weltkrieg Beginn - 1939',
        description:
            '''1. September 1939, 04:45 Uhr: Deutschland überfällt Polen - WWII beginnt.

DER ÜBERFALL:
Operation "Fall Weiß":
• 1,5 Millionen deutsche Soldaten
• Blitzkrieg-Taktik: Panzer + Luftwaffe
• Warschau bombardiert (2.000 Tote)
• Polen kapituliert: 6. Oktober 1939

Sowjetischer Einmarsch:
• 17. September: UdSSR greift von Osten an
• Hitler-Stalin-Pakt (23. August 1939): Geheimes Zusatzprotokoll teilte Polen auf
• Polen zwischen Deutschland & UdSSR aufgeteilt

UK & Frankreich:
• 3. September: Kriegserklärung an Deutschland
• Aber: Keine militärische Hilfe für Polen (Sitzkrieg)

DER GLOBALE KRIEG:
Europäischer Krieg (1939-1941):
• 1940: Deutschland erobert Dänemark, Norwegen, Belgien, Niederlande, Frankreich
• Battle of Britain: Luftschlacht (Juli-Okt 1940) - UK überlebt
• Operation Barbarossa (22. Juni 1941): Angriff auf Sowjetunion

Pazifik-Krieg (1941-1945):
• Pearl Harbor (7. Dez 1941): USA tritt ein
• Japan erobert Ostasien
• Atombomben (Aug 1945): Kriegsende

HOLOCAUST:
Systematischer Genozid:
• 6 Millionen Juden ermordet
• 5 Millionen "Unerwünschte" (Roma, Homosexuelle, Behinderte, Gegner)
• Industrielle Vernichtung: Auschwitz, Treblinka, Sobibor
• Einsatzgruppen: Massenerschießungen Osteuropa

KRIEGSVERBRECHEN (ALLE SEITEN):

Achsenmächte:
• Holocaust (Deutschland)
• Nanking-Massaker (Japan: 300.000 Chinesen)
• Zwangsarbeit (12 Mio. Menschen)
• Menschenversuche (Mengele, Unit 731)

Alliierte:
• Flächenbombardements (Dresden: 25.000 Tote)
• Atombomben (Hiroshima/Nagasaki: 200.000+ Tote)
• Massenvergewaltigungen (Rote Armee Deutschland)

KRIEGSENDE:
Europa:
• D-Day (6. Juni 1944): Invasion Normandie
• Hitler Selbstmord (30. April 1945)
• Deutsche Kapitulation: 8. Mai 1945

Pazifik:
• Atombomben (6. + 9. August 1945)
• Japan kapituliert: 2. September 1945

BILANZ:
• 60-85 Millionen Tote (3% Weltbevölkerung!)
• 40 Millionen Zivilisten
• 19-28 Millionen Kriegstote durch Hunger/Krankheit
• Sowjetunion: 27 Millionen Tote (höchste Verluste)

NACHKRIEGSORDNUNG:
• UN gegründet (1945)
• Deutschland & Berlin geteilt
• Kalter Krieg beginnt
• Dekolonisierung beschleunigt
• Marshall-Plan: Wiederaufbau Europa
• Nürnberger Prozesse: Kriegsverbrecher-Tribunal''',
        location: const LatLng(52.2297, 21.0122), // Warschau, Polen
        category: 'historical',
        date: DateTime(1939, 9, 1),
        imageUrl:
            'https://images.unsplash.com/photo-1509711522177-9a4dae9a2c75?w=1200&q=80',
        tags: [
          'WWII',
          'Zweiter Weltkrieg',
          'Polen',
          'Holocaust',
          'Weltgeschichte',
        ],
        source:
            'US Holocaust Memorial Museum, Bundesarchiv, Imperial War Museum',
        isVerified: true,
        resonanceFrequency: 5.39,
      ),

      EventModel(
        id: '44',
        title: 'Fukushima Nuklearkatastrophe - 2011',
        description:
            '''11. März 2011, 14:46 Uhr: Erdbeben, Tsunami, Kernschmelze - Dreifachkatastrophe.

DAS ERDBEBEN:
Tōhoku-Erdbeben:
• Stärke: 9.1 Mw (viertgrößtes jemals gemessen)
• Epizentrum: 70 km vor Küste
• Tiefe: 30 km
• Dauer: 6 Minuten (!)
• Japan verschob sich 2,4 Meter nach Osten

DER TSUNAMI:
Monsterwelle:
• Höhe: Bis 40 Meter (in Buchten)
• Geschwindigkeit: 800 km/h (offenes Meer)
• Eindringtiefe: 10 km ins Inland
• Zerstörte Fläche: 561 km²
• 18.500 Tote/Vermisste

DIE KERNSCHMELZE:
Fukushima Daiichi Kraftwerk:

Reaktor 1, 2, 3:
• Notstrom fiel aus (Diesel-Generatoren geflutet)
• Kühlsysteme versagten
• Kernschmelze begann Stunden später
• Wasserstoff-Explosionen (12.-15. März)

Reaktor 4:
• War im Wartungsmodus
• Brennelemente-Becken gefährdet
• Hätte bei Brand globale Katastrophe ausgelöst

RADIOAKTIVE FREISETZUNG:
Kontamination:
• 10-20% von Tschernobyl (trotzdem massive Freisetzung)
• 160.000 Menschen evakuiert
• Sperrzone: 20 km Radius (heute teilweise geöffnet)
• Pazifik kontaminiert (Cäsium-137, Strontium-90)

Langzeitfolgen:
• Landwirtschaft zerstört (Reis, Fisch unbewertbar)
• Psychische Trauma bei Überlebenden
• Krebsrisiko erhöht (besonders Kinder)
• 2.000+ "Fukushima-Tote" (Stress, Evakuierung)

KONTROVERSEN:

TEPCO Vertuschung:
• Tokyo Electric Power Company unterschätzte Tsunami-Risiko
• Sicherheitswarnungen ignoriert (2008 Studie)
• Krisenkommunikation versagte
• 2019: 4 Ex-Manager freigesprochen (Empörung)

Regierungs-Reaktion:
• Evakuierung zu langsam
• Informationen zurückgehalten
• SPEEDI-System (Strahlungsprognose) Daten geheim
• Kinder unnötig verstrahlt

Aufräumarbeiten:
• 1 Million Tonnen kontaminiertes Wasser gespeichert
• 2023: Beginn kontrollierte Einleitung ins Meer (international umstritten)
• Kosten: 200+ Milliarden Dollar
• Dauer: 40+ Jahre geschätzt

GLOBALE AUSWIRKUNGEN:
Atomausstieg:
• Deutschland: Sofortiger Atomausstieg beschlossen (2011, vollendet 2023)
• Schweiz, Belgien: Ausstiegspläne
• Japan: Alle 50 Reaktoren abgeschaltet (2013)
• Heute: 10 wieder in Betrieb (kontrovers)

Erneuerbare Energien:
• Beschleunigter Ausbau Solar/Wind
• Energiewende global verstärkt
• Aber: Kohle/Gas als Übergang (CO2-Emissionen stiegen)

VERMÄCHTNIS:
• IAEA stufte ein: Level 7 (höchste Stufe, wie Tschernobyl)
• 54.000 Menschen leben noch in temporären Unterkünften
• "Safe to return" Gebiete umstritten
• Maschinelle Roboter erkunden Reaktoren (Strahlung zu hoch für Menschen)''',
        location: const LatLng(37.4217, 141.0327), // Fukushima Daiichi
        category: 'historical',
        date: DateTime(2011, 3, 11),
        imageUrl:
            'https://images.unsplash.com/photo-1530587191325-3db32d826c18?w=1200&q=80',
        tags: ['Fukushima', 'Tsunami', 'Nuklear', 'Katastrophe', 'Japan'],
        source: 'IAEA Reports, TEPCO Archives, Japanese Government Data',
        isVerified: true,
        resonanceFrequency: 9.11,
      ),

      EventModel(
        id: '45',
        title: 'WikiLeaks & Collateral Murder - 2010',
        description:
            '''5. April 2010: WikiLeaks veröffentlicht "Collateral Murder" - Beginn der größten Leak-Serie.

COLLATERAL MURDER VIDEO:
Baghdad, 12. Juli 2007:
• Apache-Helikopter feuert auf Gruppe
• 11 Tote (darunter 2 Reuters-Journalisten)
• Van mit Kindern beschossen (2 Kinder verletzt)
• Piloten-Kommunikation: "Ha ha, I hit 'em"

WikiLeaks Veröffentlichung:
• Zeigt ungefilterte Militär-Perspektive
• Infragestellung: Waren es Kämpfer oder Zivilisten?
• US-Militär: "Bedauerlich aber rechtmäßig"
• Öffentlichkeit: Schockiert über Kriegsrealität

AFGHAN WAR LOGS (Juli 2010):
91.000 geheime Militärberichte:
• Zivile Opferzahlen höher als offiziell
• Task Force 373: Geheime Tötungskommandos
• Pakistani ISI unterstützte Taliban
• Freundliches Feuer, Unfälle verschwiegen

IRAQ WAR LOGS (Oktober 2010):
400.000 Militärberichte:
• 109.000 dokumentierte Tote (66.000 Zivilisten)
• Systematische Folter durch irakische Polizei (US ignorierte)
• 15.000 zusätzliche zivile Tote als bekannt
• "Frago 242": US-Befehl Folter nicht zu untersuchen

CABLEGATE (November 2010):
251.000 diplomatische Depeschen:
• Arabische Führer drängten auf Iran-Angriff
• US spionierte UN-Generalsekretär aus
• Saudi-Arabien finanzierte Terroristen
• Clinton ordnete Spionage gegen Diplomaten an

JULIAN ASSANGE:

Ecuadorianische Botschaft (2012-2019):
• Politisches Asyl vor Auslieferung
• 7 Jahre Isolation in Botschaft London
• Gesundheit verschlechterte sich massiv
• Ecuador entzog Asyl unter Druck (2019)

Verhaftung & Anklagen:
• 11. April 2019: Britische Polizei verhaftet ihn
• US-Anklagen: 18 Counts (Spionagegesetz)
• Strafmaß: 175 Jahre Gefängnis möglich
• Erste Anwendung Spionagegesetz auf Journalisten

Auslieferungsverfahren:
• UK: 2021 Auslieferung abgelehnt (Suizidrisiko)
• Berufung läuft (Stand 2024/25)
• Gesundheit kritisch (Schlaganfall 2021)
• UN: "Willkürliche Haft", Folter-Vorwürfe

CHELSEA MANNING:
Der Whistleblower:
• US Army Intelligence Analyst
• Lud 700.000 Dokumente herunter
• Motivation: "Öffentlichkeit hat Recht auf Wahrheit"
• Verhaftet Mai 2010

Verurteilung:
• 35 Jahre Militärgefängnis (2013)
• Obama begnadigte sie 2017 (7 Jahre verbüßt)
• 2019: Erneut inhaftiert (weigerte sich gegen Assange auszusagen)

KONTROVERSEN:

Pressefreiheit vs. Sicherheit:
Pro WikiLeaks:
• Aufdeckung von Kriegsverbrechen
• Öffentliches Interesse überwiegt
• Journalismus, kein Spionage

Contra WikiLeaks:
• Gefährdete Leben (Informanten)
• Keine Redaktion (veröffentlichte unzensiert)
• Zusammenarbeit mit feindlichen Staaten?

GLOBALE AUSWIRKUNGEN:
• Arabischer Frühling: Tunesien-Cables lösten Proteste aus
• Journalismus verändert: Anonyme Leaks normalisiert
• Whistleblower-Schutz diskutiert
• Regierungen verstärkten Informationssicherheit''',
        location: const LatLng(51.5074, -0.1278), // London (Botschaft)
        category: 'mystery',
        date: DateTime(2010, 4, 5),
        imageUrl:
            'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=1200&q=80',
        tags: [
          'WikiLeaks',
          'Julian Assange',
          'Whistleblower',
          'Pressefreiheit',
          'Transparency',
        ],
        source: 'WikiLeaks Archive, UN Reports, Court Documents',
        isVerified: true,
        resonanceFrequency: 8.10,
      ),

      EventModel(
        id: '46',
        title: 'Edward Snowden NSA-Enthüllungen - 2013',
        description:
            '''6. Juni 2013: Guardian & Washington Post enthüllen globales Überwachungsprogramm.

DER WHISTLEBLOWER:
Edward Snowden:
• NSA Contractor (Booz Allen Hamilton)
• Top Secret Clearance
• Zugang zu PRISM, XKeyscore, anderen Programmen
• Motivation: "Massenüberwachung ist falsch"

Die Flucht:
• 20. Mai 2013: Verlässt Hawaii nach Hong Kong
• Trifft Journalisten: Glenn Greenwald, Laura Poitras
• 21. Juni: USA hebt Pass auf
• 1. Aug: Temporäres Asyl Russland (läuft bis heute)

DIE ENTHÜLLUNGEN:

PRISM (Juni 2013):
• NSA Direktzugriff auf Server:
• Microsoft, Google, Yahoo, Facebook, Apple, Skype, YouTube
• E-Mails, Chats, Videos, Fotos, Dateien
• Ohne individuellen Haftbefehl!

XKeyscore:
• "Google für Spione"
• Durchsucht gesamtes Internet-Verhalten
• 700+ Server weltweit
• E-Mails, Browsing, Chats in Echtzeit
• Kein Haftbefehl nötig für Nicht-US-Bürger

Tempora (UK):
• GCHQ zapft Transatlantik-Glasfaserkabel an
• 600 Millionen Telefonverbindungen/Tag
• Teilt Daten mit NSA

Bulk Metadata Collection:
• NSA sammelte ALLE Verizon-Anrufdaten
• Wer rief wen, wann, wie lange
• "Nur Metadaten" - aber: Enthüllt komplettes Sozialnetzwerk

GLOBALER SKANDAL:

Spionage gegen Verbündete:
• Angela Merkels Handy abgehört (seit 2002!)
• 35 Staatschefs überwacht
• EU-Gebäude verwanzt
• G20-Gipfel: Alle Teilnehmer ausspioniert

Five Eyes Allianz:
• USA, UK, Kanada, Australien, Neuseeland
• Umgehen eigene Gesetze: Spionieren gegenseitig Bürger aus, teilen Daten
• "Ich darf meine Bürger nicht überwachen? Kein Problem, UK macht es und gibt mir die Daten!"

KONTROVERSEN:

Held oder Verräter?

Pro Snowden:
• Enthüllte illegale Massenüberwachung
• Öffentliches Interesse
• Whistleblower-Schutz
• Obama: Reform nötig (erkannte Problem an)

Contra Snowden:
• Brach Eid, Geheimhaltungsvereinbarung
• Floh nach Russland/China (feindliche Staaten)
• Gefährdete nationale Sicherheit
• Hätte interne Kanäle nutzen sollen

RECHTLICHE SITUATION:
• US-Anklagen: Spionage, Diebstahl (30 Jahre+)
• Obama: Keine Begnadigung
• Trump: "Snowden ist Verräter, Todesstrafe"
• Biden: Keine Stellungnahme
• Russland: Permanent Residency (2020)

AUSWIRKUNGEN:

Reformen:
• USA Freedom Act (2015): Begrenzte Bulk Collection
• Aber: FISA-Gerichte weiterhin geheim
• Kritiker: Kosmetische Änderungen

Technologie-Reaktion:
• Apple: End-to-End Encryption iPhones
• WhatsApp, Signal: Verschlüsselung Standard
• VPN-Nutzung explodierte
• "Going Dark" Problem für Law Enforcement

Öffentliches Bewusstsein:
• Privacy-Bewegung gestärkt
• GDPR (EU): Teilweise Reaktion
• "Nothing to hide" Argument erschüttert
• Debatte: Sicherheit vs. Privatsphäre

VERMÄCHTNIS:
• 2014: Pulitzer Prize (Guardian/WaPo)
• 2015: Film "Citizenfour" Oscar
• Snowden: "Würde es wieder tun"
• Lebt weiter im russischen Exil mit Ehefrau''',
        location: const LatLng(55.7558, 37.6173), // Moskau, Russland
        category: 'mystery',
        date: DateTime(2013, 6, 6),
        imageUrl:
            'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=1200&q=80',
        tags: ['Snowden', 'NSA', 'Überwachung', 'PRISM', 'Whistleblower'],
        source: 'Guardian Archives, Washington Post, Snowden Documents',
        isVerified: true,
        resonanceFrequency: 7.13,
      ),

      EventModel(
        id: '47',
        title: 'Fall der Berliner Mauer - 1989',
        description:
            '''9. November 1989, 23:00 Uhr: "Die Mauer ist weg!" - Das Ende des Kalten Krieges beginnt.

DIE MAUER:
Bau (13. August 1961):
• "Antifaschistischer Schutzwall" (DDR-Propaganda)
• Wahrheit: Stopp der Massenflucht (3,6 Mio. flohen 1949-1961)
• Länge: 155 km (davon 43 km mitten durch Berlin)
• Todesstreifen: Minen, Selbstschussanlagen, Wachtürme
• 140+ Mauertote dokumentiert

Das System:
• Familien getrennt über Nacht
• Westberlin: Insel mitten in DDR
• Checkpoint Charlie: Berühmter Übergang
• Reagan (1987): "Mr. Gorbachev, tear down this wall!"

DER FALL:

Vorgeschichte:
• Gorbatschow: Perestroika & Glasnost (Reformen UdSSR)
• Ungarn öffnet Grenze zu Österreich (Mai 1989)
• Tausende DDR-Bürger fliehen über Ungarn
• Leipzig: Montags-Demonstrationen (70.000 Menschen)

Der verhängnisvolle Abend:
18:00 Uhr:
• SED-Politbüro beschließt: Reisefreiheit (ab 10. Nov)
• Schabowski soll es verkünden

19:00 Uhr:
• Pressekonferenz Günter Schabowski
• Journalist: "Wann tritt das in Kraft?"
• Schabowski (unsicher): "Das tritt nach meiner Kenntnis... ist das sofort, unverzüglich."

20:00 Uhr:
• West-Medien: "Mauer ist offen!"
• Tausende strömen zu Grenzübergängen

23:00 Uhr:
• Grenzposten überfordert
• Bornholmer Straße öffnet als Erste
• Jubel, Tränen, Champagner

DIE ERSTEN STUNDEN:

Massenhysterie:
• 100.000+ Menschen am Brandenburger Tor
• Menschen hämmern Mauer (Mauerspechte)
• Trabbi-Konvois Richtung Westen
• West-Berliner: Begrüßungsgeld 100 DM
• Party die ganze Nacht

Historische Momente:
• Leonard Bernstein dirigiert Beethovens 9.
• "Ode an die Freiheit" (statt "Freude")
• David Hasselhoff singt "Looking for Freedom"
• Willy Brandt: "Jetzt wächst zusammen, was zusammen gehört"

WIEDERVEREINIGUNG:

Der Weg zur Einheit:
• 18. März 1990: Erste freie DDR-Wahl
• 1. Juli: Währungsunion (D-Mark in DDR)
• 3. Oktober 1990: Wiedervereinigung (Tag der Deutschen Einheit)
• 2+4-Vertrag: Zustimmung Siegermächte

Bedingungen:
• Deutschland verzichtet auf Atomwaffen
• Oder-Neiße-Grenze zu Polen anerkannt
• NATO-Erweiterung nach Osten (umstritten!)
• Gorbatschow: Zugestimmt gegen 12 Mrd. DM

HERAUSFORDERUNGEN:

Wirtschaft:
• Treuhand: Privatisierung DDR-Betriebe
• Massenarbeitslosigkeit im Osten
• "Blühende Landschaften" (Kohl) blieben aus
• Solidaritätszuschlag (bis heute)

Gesellschaft:
• "Ossis vs. Wessis" Spannungen
• Lohngefälle Ost-West (noch heute)
• AfD Hochburgen im Osten (Frustration)
• Stasi-Akten Öffnung: Zerstörte Familien

GLOBALE AUSWIRKUNGEN:

Ende des Kalten Krieges:
• Warschauer Pakt aufgelöst (1991)
• Sowjetunion zerfällt (26. Dez 1991)
• Tschechoslowakei, Jugoslawien zerfallen
• NATO-Osterweiterung (1999, 2004...)

Fukuyamas "Ende der Geschichte":
• Liberale Demokratie triumphiert?
• 30 Jahre später: Demokratie in Krise
• China, Russland: Autoritäre Alternativen
• Populismus weltweit

VERMÄCHTNIS:
• 1,3 km Mauer steht noch (East Side Gallery)
• Checkpoint Charlie: Touristen-Attraktion
• Mauerfall-Jubiläen: Nationale Feiern
• Symbol für Freiheit weltweit''',
        location: const LatLng(52.5200, 13.4050), // Berlin
        category: 'historical',
        date: DateTime(1989, 11, 9),
        imageUrl:
            'https://images.unsplash.com/photo-1560969184-10fe8719e047?w=1200&q=80',
        tags: [
          'Berliner Mauer',
          'Wiedervereinigung',
          'Kalter Krieg',
          'Deutschland',
          'Freiheit',
        ],
        source: 'Bundesarchiv, Stiftung Berliner Mauer, Zeitzeugen-Berichte',
        isVerified: true,
        resonanceFrequency: 7.89,
      ),

      EventModel(
        id: '48',
        title: 'Kubakrise - 1962',
        description:
            '''16.-28. Oktober 1962: 13 Tage, die die Welt an den Rand der Auslöschung brachten.

DER KONFLIKT:

Vorgeschichte:
• Bay of Pigs (1961): CIA-Invasion Kubas scheiterte
• Castro wendet sich Sowjetunion zu
• USA stationierte Jupiter-Raketen in Türkei (1961)
• Chruschtschow fühlte sich bedroht

Operation Anadyr:
• Sommer 1962: UdSSR schickt heimlich Raketen nach Kuba
• 40 SS-4/SS-5 Mittelstreckenraketen (Reichweite: 2.000+ km)
• 80 Atomsprengköpfe
• 42.000 sowjetische Soldaten
• Können Washington D.C. in 13 Minuten erreichen!

DIE 13 TAGE:

16. Oktober:
• U-2 Aufklärungsfotos zeigen Raketenstartrampen
• Kennedy: "He can't do that to me!"
• ExComm (Executive Committee) gebildet

Optionen diskutiert:
1. Nichts tun → Politisch unmöglich
2. Diplomatie → Zu langsam
3. Blockade → Risiko Eskalation
4. Luftangriff → Könnte nicht alle Raketen zerstören
5. Invasion → WWIII wahrscheinlich

22. Oktober:
• Kennedy TV-Ansprache: Verkündet Quarantäne (Blockade)
• "Jeder atomare Angriff von Kuba wird als Angriff der UdSSR betrachtet"
• DEFCON 2 (höchste Alarmstufe vor Krieg!)

24. Oktober:
• Sowjetische Schiffe nähern sich Blockade
• Dean Rusk: "We're eyeball to eyeball"
• Schiffe stoppen in letzter Minute

27. Oktober - "Black Saturday":
• Sowjet-Rakete schießt U-2 über Kuba ab (Pilot tot)
• US-Generäle drängen auf Luftangriff
• Zweite U-2 verirrt sich über Sowjetunion (beinahe abgeschossen)
• Atomkrieg Minuten entfernt!

Vasili Arkhipov - Der Mann, der die Welt rettete:
• Sowjet-U-Boot B-59 vor Kuba
• US zwingt zum Auftauchen (Übungswasserbomben)
• Kapitän will atomaren Torpedo abfeuern
• Benötigt Zustimmung aller 3 Offiziere
• Arkhipov: NEIN! (Nur er verhinderte WWIII)

LÖSUNG:

Geheimer Deal:
• 28. Oktober: Chruschtschow zieht Raketen ab
• Öffentlich: Kennedy "gewann"
• Geheim: USA zog Raketen aus Türkei ab (6 Monate später)
• Kennedy versprach: Keine Kuba-Invasion

Gesichtswahrung:
• Chruschtschow: Frieden bewahrt, USA-Konzessionen
• Kennedy: Held, Raketen weg
• Castro: Wütend (nicht konsultiert)

KONSEQUENZEN:

Rotes Telefon (1963):
• Direkte Hotline Moskau-Washington
• Verhindert Missverständnisse
• Wurde während Krise vermisst!

Vertrag über Atomteststopp (1963):
• Oberirdische Tests verboten
• Erster Abrüstungsvertrag
• Beginn Détente

Beinahe-Katastrophe Fakten:
• 100+ Atombomben waren einsatzbereit
• Lokale Kommandeure hatten Autorität zu feuern
• Kommunikation chaotisch (Stunden Verzögerung)
• Mehrere Beinahe-Unfälle (Fehlalarme)

ALTERNATIVE HISTORIEN:

Was wäre wenn?
• Arkhipov sagt Ja → Torpedo trifft US-Schiff
• USA feuert zurück → Sowjetunion antwortet
• Nukleare Eskalation → Hemisphäre ausgelöscht
• Nuklearer Winter → Globale Zivilisation endet

McNamaras Einschätzung (später):
• "Wir hatten Glück"
• "Nicht Vernunft - Glück bewahrte uns"
• Entdeckte später: 162 Atomsprengköpfe auf Kuba (dachten 10-15!)

VERMÄCHTNIS:
• Nächste Mal könnte Glück ausgehen
• Zeigt Gefahr automatischer Eskalation
• Atomwaffen = Existenzgefahr
• Diplomatie > Konfrontation
• Helden sind oft unbekannt (Arkhipov)''',
        location: const LatLng(23.1136, -82.3666), // Havanna, Kuba
        category: 'historical',
        date: DateTime(1962, 10, 16),
        imageUrl:
            'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=1200&q=80',
        tags: [
          'Kubakrise',
          'Kalter Krieg',
          'Atomkrieg',
          'Kennedy',
          'Chruschtschow',
        ],
        source:
            'JFK Presidential Library, National Security Archive, Declassified Documents',
        isVerified: true,
        resonanceFrequency: 6.62,
      ),

      EventModel(
        id: '49',
        title: 'Vietnamkrieg - 1955-1975',
        description:
            '''Der längste Krieg Amerikas: 20 Jahre Dschungelkampf, 58.000 US-Tote, Millionen Vietnamesen.

URSPRUNG DES KONFLIKTS:

Französischer Indochinakrieg (1946-1954):
• Vietnam unter französischer Kolonialherrschaft
• Ho Chi Minh: Unabhängigkeitsbewegung (Viet Minh)
• Schlacht von Dien Bien Phu (1954): Frankreich besiegt
• Genfer Abkommen: Vietnam geteilt (Nord/Süd)
• Vorgesehen: Wiedervereinigung 1956 (fand nie statt)

Kalter Krieg Domino-Theorie:
• USA befürchtet: Südostasien fällt an Kommunismus
• Domino-Effekt: Ein Land nach dem anderen
• Eisenhower: "Müssen Südvietnam stützen"

US-ESKALATION:

Kennedy (1961-1963):
• "Militärberater" nach Südvietnam (16.000)
• In Wahrheit: Kampftruppen
• Unterstützte Diem-Regime (korrupt, unterdrückend)

Johnson (1963-1969):
• Golf von Tonkin-Zwischenfall (4. Aug 1964)
  - Angeblicher nordvietnamesischer Angriff auf US-Zerstörer
  - Heute bekannt: Teilweise erfunden!
  - Johnson bekam Kriegsermächtigung vom Kongress
• Operation Rolling Thunder (1965): Bombardierung Nordvietnam
• Bodentruppen: Von 16.000 (1963) auf 536.000 (1968)

DER KRIEG:

Guerilla-Taktik (Viet Cong):
• Tunnel-Systeme (Cu Chi: 250 km!)
• Hinterhalte, Booby Traps
• "Fish in the Water": Dorfbevölkerung unterstützt
• Ho-Chi-Minh-Pfad: Nachschubweg durch Laos/Kambodscha

US-Kriegsführung:
• Search and Destroy Missionen
• "Body Count" als Erfolgsmetrik
• Napalm-Bombardierung (brennt alles)
• Agent Orange: 80 Mio. Liter Herbizid
  - Entlaubung Dschungel
  - Bis heute: Krebs, Missbildungen

Tet-Offensive (1968):
• 30. Januar: Viet Cong greift 100+ Städte an
• Militärisch: US-Sieg
• Psychologisch: Wendepunkt
• US-Öffentlichkeit: "Krieg ist nicht zu gewinnen"
• Walter Cronkite: "Krieg ist Patt"

KRIEGSVERBRECHEN:

My Lai Massaker (16. März 1968):
• Lt. William Calley's Einheit
• 504 unbewaffnete Zivilisten ermordet
• Frauen vergewaltigt, Babys erschossen
• Hugh Thompson (Helikopter-Pilot) stoppte es
• Nur Calley verurteilt (3 Jahre Hausarrest!)

Phoenix Program:
• CIA-Operation: "Neutralisierung" Viet Cong
• 20.000-40.000 "Verdächtige" getötet
• Folter, außergerichtliche Hinrichtungen

Nordvietnam:
• Hue-Massaker (1968): 3.000-6.000 Südvietnamesen hingerichtet
• POW-Folter (Hanoi Hilton)
• Zwangsrekrutierung

HEIMATFRONT:

Anti-Kriegsbewegung:
• Kent State (1970): Nationalgarde tötet 4 Studenten
• Pentagon Papers (1971): NY Times enthüllt Regierungslügen
• Muhammad Ali verweigert Einberufung
• 500.000 demonstrieren Washington D.C. (1969)

Wehrpflicht:
• Lottery-System: Ungerecht
• Reiche vermieden Dienst (College-Aufschub)
• Afroamerikaner überproportional eingezogen
• 50.000+ flohen nach Kanada

ENDE DES KRIEGS:

Vietnamisierung (Nixon):
• Schrittweiser Truppenabzug
• Training südvietnamesischer Armee
• Gleichzeitig: Intensivierung Bombardierung

Paris Peace Accords (27. Jan 1973):
• Waffenstillstand
• US-Truppen ziehen ab
• Nordvietnam behält Truppen im Süden
• Kissinger & Le Duc Tho: Friedensnobelpreis (kontrovers!)

Fall of Saigon (30. April 1975):
• Nordvietnam erobert Südvietnam
• Chaos: Helikopter-Evakuierung US-Botschaft
• Ikonisches Bild: Menschen an Hubschrauber-Kufen
• Vietnam wiedervereinigt unter kommunistischer Herrschaft

BILANZ:

Tote:
• US: 58.220
• Südvietnam: 250.000+ Soldaten, 2 Mio.+ Zivilisten
• Nordvietnam/Viet Cong: 1 Mio.+ Soldaten
• Laos/Kambodscha: 1 Mio.+
• Total: 3-4 Millionen

Langzeitfolgen:
• Agent Orange: 3 Mio. Opfer (Krebs, Missbildungen bis heute)
• Unexploded Ordnance: 800.000 Tonnen Blindgänger
• PTSD: Generation traumatisierter Veteranen
• "Vietnam Syndrome": US-Zurückhaltung bei Intervention

VERMÄCHTNIS:
• Erster "TV-Krieg" (Bilder schockierten)
• Zerstörte Vertrauen in Regierung
• Bewies: Technik schlägt nicht Guerilla
• 1995: USA & Vietnam normalisieren Beziehungen''',
        location: const LatLng(10.8231, 106.6297), // Saigon/Ho Chi Minh City
        category: 'historical',
        date: DateTime(1955, 11, 1),
        imageUrl:
            'https://images.unsplash.com/photo-1509711522177-9a4dae9a2c75?w=1200&q=80',
        tags: [
          'Vietnamkrieg',
          'Kalter Krieg',
          'USA',
          'Ho Chi Minh',
          'Anti-Kriegsbewegung',
        ],
        source: 'Vietnam Veterans Memorial, National Archives, Pentagon Papers',
        isVerified: true,
        resonanceFrequency: 5.55,
      ),

      EventModel(
        id: '50',
        title: 'Holocaust - Systematischer Völkermord 1933-1945',
        description:
            '''Der industrialisierte Massenmord an 6 Millionen Juden und 5 Millionen anderen "Unerwünschten".

IDEOLOGIE:

Nazi-Rassenlehre:
• "Herrenrasse" vs. "Untermenschen"
• Antisemitismus als Staatsdoktrin
• Lebensraum im Osten (Slaven vertreiben)
• "Rassenhygiene": Behinderte, Homosexuelle, Roma

DIE STUFEN DER VERNICHTUNG:

Phase 1: Entrechtung (1933-1939):
• Nürnberger Rassegesetze (1935): Juden keine Bürger
• Boykott jüdischer Geschäfte
• Berufsverbote (Ärzte, Anwälte, Lehrer)
• Reichspogromnacht (9. Nov 1938): 1.000+ Synagogen zerstört

Phase 2: Ghettos (1939-1941):
• Warschauer Ghetto: 400.000 Menschen, 3,4 km²
• Absichtlich: Hunger, Krankheit, Tod
• 100.000 starben vor Deportationen

Phase 3: Einsatzgruppen (1941-1942):
• Mobile Todesschwadronen (Osteuropa)
• Massenerschießungen: Babi Yar (33.000 in 2 Tagen)
• 1,5 Millionen von Einsatzgruppen ermordet

Phase 4: Wannsee-Konferenz (20. Jan 1942):
• "Endlösung der Judenfrage"
• Heydrich koordiniert systematischen Völkermord
• 15 hochrangige Nazis, 90 Minuten
• Protokoll: Bürokratische Sprache für Massenmord

Phase 5: Vernichtungslager (1942-1945):

Auschwitz-Birkenau:
• 1,1 Millionen Tote (90% Juden)
• "Arbeit macht frei" (zynische Lüge)
• Selektion Rampe: Links (Tod), Rechts (Zwangsarbeit)
• Gaskammern: Zyklon B (Schädlingsbekämpfungsmittel)
• 6.000 Menschen/Tag ermordet (Höhepunkt 1944)

Treblinka, Sobibor, Belzec:
• Reine Tötungsfabriken
• Treblinka: 900.000 Tote in 15 Monaten
• Von Ankunft bis Tod: 2 Stunden
• Leichen verbrannt, Asche als Dünger

DAS SYSTEM:

Täter:
• SS-Totenkopfverbände
• Wehrmacht: Kollaboration (keine saubere Wehr!)
• Kollaborateure: Französische, polnische, ukrainische Polizei
• IG Farben: Zyklon B Produktion

Opfer:
• 6 Millionen Juden
• 500.000 Roma/Sinti
• 250.000 Behinderte (Aktion T4)
• 15.000 Homosexuelle
• Zehntausende politische Gefangene, Zeugen Jehovas

Medizinische Experimente:
• Josef Mengele: Zwillingsforschung
• Unterkühlung, Druck, Gifte
• Keine wissenschaftliche Grundlage
• Sadistische Folter

WIDERSTAND & RETTUNG:

Aufstände:
• Warschauer Ghetto (1943): Jüdischer Widerstand 4 Wochen
• Sobibor (1943): Häftlingsaufstand, 300 entkamen
• Einzelne SS-Anlagen sabotiert

Retter:
• Oskar Schindler: Rettete 1.200 Juden (Fabrik)
• Raoul Wallenberg: 100.000 ungarische Juden (Schutzpässe)
• Dänemark: 7.000 Juden nach Schweden geschmuggelt
• Righteous Among Nations: 27.000+ Retter geehrt

BEFREIUNG:

Sowjets:
• Auschwitz (27. Jan 1945): 7.000 Überlebende
• Majdanek (Juli 1944): Erste Beweise

Amerikaner/Briten:
• Bergen-Belsen (April 1945): 60.000 lebende Skelette
• Dachau (April 1945): US-Soldaten schockiert

Überlebende:
• 200.000-300.000 aus Lagern
• Displaced Persons Camps (DP)
• Viele konnten nicht zurück (Pogrome in Polen!)
• Emigration: Israel, USA

PROZESSE & ERINNERUNG:

Nürnberger Prozesse (1945-1946):
• 24 Hauptangeklagte
• 12 Todesurteile
• "Ich befolgte nur Befehle" - NICHT anerkannt!
• Präzedenzfall: Verbrechen gegen Menschlichkeit

Eichmann-Prozess (1961):
• Adolf Eichmann (Organisator Transporte)
• Entführt von Mossad aus Argentinien
• Verurteilt, hingerichtet in Israel

Holocaust-Leugnung:
• Strafbar in Deutschland, Österreich, andere
• Pseudowissenschaft widerlegt:
  - Dokumentation überwältigend
  - Täter-Geständnisse
  - Zeugenaussagen
  - Physische Beweise

VERMÄCHTNIS:
• "Nie wieder!" - Aber: Genozide passierten (Ruanda, Bosnien, Darfur)
• Holocaust Memorial Museums weltweit
• Yad Vashem: 4,8 Millionen Namen dokumentiert
• UN Genozid-Konvention (1948)
• Israel gegründet (1948)
• Ethische Frage: Wie war es möglich?''',
        location: const LatLng(50.0262, 19.2046), // Auschwitz
        category: 'historical',
        date: DateTime(1933, 1, 30),
        imageUrl:
            'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=1200&q=80',
        tags: ['Holocaust', 'WWII', 'Völkermord', 'Auschwitz', 'Nie Wieder'],
        source:
            'US Holocaust Memorial Museum, Yad Vashem, Nürnberger Dokumente',
        isVerified: true,
        resonanceFrequency: 3.33,
      ),
    ];
  }
}
