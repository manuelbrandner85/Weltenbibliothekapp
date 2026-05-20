// Zusätzliche Energie-Welt Marker (Phase 2).
//
// Diese 25 Sites ergänzen die bestehenden 33 in energie_karte_tab_pro.dart
// auf 58+. Alle mit Wikimedia-Commons Foto-URLs.
//
// Quellen / Begründungen sind in den `detailedInfo`-Texten; der Stil ist
// bewusst nicht-dogmatisch: was die offizielle Wissenschaft sagt + was die
// esoterische Tradition daraus macht.

import 'package:latlong2/latlong.dart';

import '../screens/energie/energie_karte_tab_pro.dart';

final List<EnergieLocationDetail> extraEnergieLocations = [
  // ── HEILIGE BERGE & VORTEXES ────────────────────────────────────
  EnergieLocationDetail(
    name: 'Mount Kailash - Tibet',
    description: 'Heiligster Berg in 4 Religionen',
    detailedInfo:
        '''6.638 m hoher Berg im Transhimalaya. Heilig für Buddhisten (Demchok), Hindus (Shiva), Jains (Adinatha) und die Bön-Religion. Bis heute UNBESTIEGEN — Bergsteiger respektieren die religiöse Bedeutung.

Pyramidenartige Form mit fast perfekt nach den Himmelsrichtungen ausgerichteten Flanken. "Achse der Welt" / "Mount Meru" der Mythen. Pilger umrunden ihn (Kora, 52 km) — eine Runde löscht angeblich die Sünden eines Lebens.

Wissenschaftlich kontroverse Berichte: Beschleunigtes Haar- und Nagelwachstum bei Pilgern, abrupte Wettermuster, magnetische Anomalien.''',
    position: const LatLng(31.0667, 81.3125),
    category: EnergieCategory.sacredSites,
    keywords: ['Kailash', 'Tibet', 'Shiva', 'Pyramide', 'Mount Meru'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0a/Kailash-Sept-2010.JPG/1024px-Kailash-Sept-2010.JPG',
    ],
    energyLevel: 10,
  ),
  EnergieLocationDetail(
    name: 'Mount Fuji - Japan',
    description: 'Heiliger Vulkan, Shinto-Zentrum',
    detailedInfo:
        '''3.776 m, Japans höchster Berg, perfekt symmetrischer Stratovulkan. Im Shintoismus Sitz der Göttin Sengen-Sama. UNESCO-Welterbe (2013) als "heiliger Ort und Inspirationsquelle".

Jährlich 300.000+ Pilger besteigen den Berg in der kurzen Saison (Juli-August). Der Krater am Gipfel = "Tor zur anderen Welt" in der Tradition. Erste belegte Besteigung: 663 n.Chr. durch einen Mönch.''',
    position: const LatLng(35.3606, 138.7274),
    category: EnergieCategory.sacredSites,
    keywords: ['Fuji', 'Japan', 'Shinto', 'Vulkan', 'Sengen'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cd/Lake_Kawaguchiko_Sakura_Mount_Fuji_3.jpg/1024px-Lake_Kawaguchiko_Sakura_Mount_Fuji_3.jpg',
    ],
    energyLevel: 9,
  ),
  EnergieLocationDetail(
    name: 'Sedona Vortexes - Arizona',
    description: 'Energiewirbel im Red Rock Country',
    detailedInfo:
        '''4 anerkannte Hauptvortexe: Bell Rock, Cathedral Rock, Boynton Canyon, Airport Mesa. Roter Sandstein mit hohem Eisenoxid-Gehalt — messbare elektromagnetische Anomalien.

Pete Sanders (MIT-Physiker) untersuchte 1995 die geomagnetischen Felder und fand reproduzierbare Abweichungen. Hopi-Tradition: Sedona ist Tor zur "Vierten Welt". Über 4 Millionen Besucher jährlich — größtes spirituelles Reiseziel Nordamerikas.''',
    position: const LatLng(34.8697, -111.7610),
    category: EnergieCategory.vortexPoints,
    keywords: ['Sedona', 'Vortex', 'Arizona', 'Hopi', 'Red Rock'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/40/Cathedral_Rock_at_dusk_blue_hour.jpg/1024px-Cathedral_Rock_at_dusk_blue_hour.jpg',
    ],
    energyLevel: 9,
  ),
  EnergieLocationDetail(
    name: 'Mount Shasta - Kalifornien',
    description: 'Vulkan, "Heimat aufgestiegener Meister"',
    detailedInfo:
        '''4.322 m Stratovulkan, heiliger Berg für die Wintu, Karuk, Modoc und Shasta. In der Neuzeit (seit 1880er) mit Theosophie verknüpft: "Lemurianer" leben angeblich im Inneren. Guy Ballard ("I AM Activity") behauptete 1930 Begegnungen mit Saint Germain hier.

Wissenschaftlich: aktiver Vulkan, letzte Eruption ~1786. Linsenwolken über dem Gipfel sind häufig — oft als UFO-Sichtungen interpretiert.''',
    position: const LatLng(41.4099, -122.1949),
    category: EnergieCategory.sacredSites,
    keywords: ['Shasta', 'Kalifornien', 'Lemurien', 'Vulkan'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/57/Mt_Shasta_aerial.jpg/1024px-Mt_Shasta_aerial.jpg',
    ],
    energyLevel: 9,
  ),
  EnergieLocationDetail(
    name: 'Uluru / Ayers Rock - Australien',
    description: 'Heiliger Monolith der Anangu',
    detailedInfo:
        '''348 m hoher Sandstein-Inselberg im Roten Zentrum Australiens. Heilig für die Anangu-Aborigines seit mindestens 30.000 Jahren. Songlines (Traumzeit-Pfade) der Schöpfungswesen kreuzen sich hier.

Seit 26. Oktober 2019 ist das Besteigen verboten — die Anangu hatten jahrzehntelang darum gebeten. UNESCO-Welterbe doppelt: Natur + Kultur. Geologisch faszinierend: das Sichtbare ist nur ~10% des Felsens — der Rest liegt unter der Wüste.''',
    position: const LatLng(-25.3444, 131.0369),
    category: EnergieCategory.sacredSites,
    keywords: ['Uluru', 'Australien', 'Anangu', 'Songlines', 'Traumzeit'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/22/Uluru_Australia%28cropped%29.jpg/1024px-Uluru_Australia%28cropped%29.jpg',
    ],
    energyLevel: 10,
  ),

  // ── ALTE TEMPEL & HEILIGTÜMER ───────────────────────────────────
  EnergieLocationDetail(
    name: 'Angkor Wat - Kambodscha',
    description: 'Größter sakraler Komplex der Welt',
    detailedInfo:
        '''162,6 Hektar — größte religiöse Anlage weltweit. Erbaut im 12. Jh. unter Suryavarman II als Hindu-Tempel für Vishnu, später buddhistisch genutzt. Bezeichnet das hinduistische Universum: zentrales Plateau = Mount Meru, äußere Mauer = Bergketten am Weltrand.

Astronomische Ausrichtung: Westeingang exakt zur Tagundnachtgleiche. Wissenschaftliche Studien (Graham Hancock) zeigen Sterne-Korrelation zur Konstellation Draco um 10.500 v.Chr.''',
    position: const LatLng(13.4125, 103.8670),
    category: EnergieCategory.ancientTemples,
    keywords: ['Angkor', 'Khmer', 'Vishnu', 'Hindu', 'Mount Meru'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a3/Angkor-Wat-from-the-air.JPG/1024px-Angkor-Wat-from-the-air.JPG',
    ],
    energyLevel: 10,
  ),
  EnergieLocationDetail(
    name: 'Borobudur - Java',
    description: 'Größter buddhistischer Tempel der Welt',
    detailedInfo:
        '''9. Jh. erbaut, dann ~400 Jahre vergessen unter Asche und Dschungel. 1814 von Raffles wiederentdeckt. 504 Buddha-Statuen, 72 perforierte Stupas am Hauptdach. 3 Ebenen = die drei buddhistischen Sphären (Kamadhatu, Rupadhatu, Arupadhatu).

Pilger umrunden den Komplex im Uhrzeigersinn, immer höher steigend — der Pfad zur Erleuchtung als gebaute Meditation. UNESCO-Welterbe seit 1991.''',
    position: const LatLng(-7.6079, 110.2038),
    category: EnergieCategory.ancientTemples,
    keywords: ['Borobudur', 'Buddha', 'Java', 'Stupa', 'Indonesien'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a4/Borobudur_Temple.jpg/1024px-Borobudur_Temple.jpg',
    ],
    energyLevel: 9,
  ),
  EnergieLocationDetail(
    name: 'Karnak-Tempel - Ägypten',
    description: 'Größter Tempelbezirk Ägyptens',
    detailedInfo:
        '''Über 2.000 Jahre lang erweitert (ca. 2055 v.Chr. bis 30 n.Chr.). 30+ Pharaonen ließen daran bauen. Säulenhalle mit 134 Säulen, die größten 21 m hoch und 5 m im Durchmesser.

Ausrichtung des Haupttempels: Sommer-Sonnenwende-Sonnenaufgang. Akustische Eigenschaften: Geräusche der heilen Steine sind dokumentiert. Heilige Geometrie und Maßeinheiten passen exakt zur Großen Pyramide.''',
    position: const LatLng(25.7188, 32.6573),
    category: EnergieCategory.ancientTemples,
    keywords: ['Karnak', 'Ägypten', 'Amun', 'Pharao', 'Heliopolis'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/Egypt-3B-001.jpg/1024px-Egypt-3B-001.jpg',
    ],
    energyLevel: 10,
  ),
  EnergieLocationDetail(
    name: 'Tikal - Guatemala',
    description: 'Maya-Stadtstaat mit astronomischen Pyramiden',
    detailedInfo:
        '''Höhepunkt 200-900 n.Chr. Pyramiden bis 70 m hoch, Tempel I (Tempel des Riesen-Jaguar). Astronomisch präzise: Pyramiden-Spitze von Tempel IV markiert Sonnenwende-Punkte exakt.

Mysteriöse Geschichte: Tikal kollabierte um 900 n.Chr. ohne klare Ursache. Theorien: Klimawandel, Krieg, Epidemie. Heute UNESCO-Welterbe im Regenwald.''',
    position: const LatLng(17.2229, -89.6230),
    category: EnergieCategory.ancientTemples,
    keywords: ['Tikal', 'Maya', 'Guatemala', 'Pyramide'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Tikal_Temple1_2006_08_11.JPG/1024px-Tikal_Temple1_2006_08_11.JPG',
    ],
    energyLevel: 9,
  ),
  EnergieLocationDetail(
    name: 'Newgrange - Irland',
    description: 'Megalithgrab, älter als Stonehenge & Cheops',
    detailedInfo:
        '''3.200 v.Chr. — älter als Stonehenge (3.000 v.Chr.) und die Cheops-Pyramide (2.560 v.Chr.). Hügelgrab mit 19 m langem Korridor zum zentralen Raum.

Sensationelle astronomische Funktion: Bei der Wintersonnenwende (21. Dez.) dringt das Sonnenlicht durch ein präzises "Roof-Box"-Fenster über dem Eingang und erleuchtet 17 Minuten lang den hintersten Raum. Die Spiral-Reliefs (Triskele) sind ikonisch.''',
    position: const LatLng(53.6948, -6.4753),
    category: EnergieCategory.ancientTemples,
    keywords: ['Newgrange', 'Irland', 'Megalith', 'Wintersonnenwende', 'Boyne'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Newgrange.JPG/1024px-Newgrange.JPG',
    ],
    energyLevel: 9,
  ),
  EnergieLocationDetail(
    name: 'Externsteine - Deutschland',
    description: 'Megalith-Sandsteinformation, germanischer Kraftort',
    detailedInfo:
        '''13 Sandsteinfelsen im Teutoburger Wald, bis 40 m hoch. In Stein gehauenes Kreuzabnahme-Relief (~1130 n.Chr.). Höhlenkammer mit kreisrundem Loch — am 21. Juni zeigt die aufgehende Sonne durch das Loch.

Wilhelm Teudt postulierte 1929 ein "Heiliges Linien-System" (Heilige Linien) durch Norddeutschland mit den Externsteinen als Knotenpunkt. Heute hochfrequentierter Kraftort für deutsche Esoterik-Tourismus.''',
    position: const LatLng(51.8689, 8.9152),
    category: EnergieCategory.kraftorte,
    keywords: ['Externsteine', 'Teutoburg', 'Germanen', 'Teudt', 'Lichtloch'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1c/Externsteine_Panorama.jpg/1024px-Externsteine_Panorama.jpg',
    ],
    energyLevel: 9,
  ),
  EnergieLocationDetail(
    name: 'Glastonbury Tor - England',
    description: 'Avalon-Hügel, weibliche Energie',
    detailedInfo:
        '''158 m hoher Hügel mit dem Turm der Saint Michael-Kirche (14. Jh.). Mit dem Avalon-Mythos (König Artus) verknüpft. Christliche Tradition: Joseph von Arimathäa soll hier 30 n.Chr. den Heiligen Gral begraben haben.

Der Hügel mit seinem Spiral-Pfad gilt als der "Heart Chakra der Erde" in der Neuzeit-Esoterik. Quellen am Fuß: Chalice Well (eisenhaltig-rot) und White Spring (kalkhaltig-weiß) — alchemistische Polarität.''',
    position: const LatLng(51.1448, -2.6986),
    category: EnergieCategory.sacredSites,
    keywords: ['Glastonbury', 'Avalon', 'Artus', 'Gral', 'Heart Chakra'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/85/Glastonbury_Tor.jpg/1024px-Glastonbury_Tor.jpg',
    ],
    energyLevel: 9,
  ),
  EnergieLocationDetail(
    name: 'Avebury - England',
    description: 'Größter prähistorischer Steinkreis Europas',
    detailedInfo:
        '''Vor 4.500 Jahren erbaut, etwa zeitgleich mit Stonehenge. 332 m Durchmesser des äußeren Rings — 14× größer als Stonehenge. Drei Steinkreise innerhalb eines Henges mit Graben (jetzt 9 m tief).

Avebury ist Teil eines größeren Komplexes mit Silbury Hill (38 m hoher künstlicher Hügel) und West Kennet Long Barrow. UNESCO-Welterbe gemeinsam mit Stonehenge.''',
    position: const LatLng(51.4286, -1.8542),
    category: EnergieCategory.ancientTemples,
    keywords: ['Avebury', 'Steinkreis', 'Megalith', 'Silbury', 'Wiltshire'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Avebury_henge_and_village_UK_aerial.jpg/1024px-Avebury_henge_and_village_UK_aerial.jpg',
    ],
    energyLevel: 9,
  ),

  // ── KRISTALL-HÖHLEN & GEOLOGISCHE WUNDER ────────────────────────
  EnergieLocationDetail(
    name: 'Naica Kristall-Höhle - Mexiko',
    description: 'Größte Selenit-Kristalle der Welt',
    detailedInfo:
        '''2000 entdeckt, 300 m tief unter der Wüste Chihuahua. Selenit-Kristalle bis 12 m lang und 1 m Durchmesser, schätzungsweise 500.000 Jahre alt. Wachstum war nur möglich, weil die Höhle exakt 58°C und 100% Luftfeuchtigkeit hatte — das gilt als "Kristall-Inkubator".

Forscher konnten nur mit Spezial-Schutzanzügen 30 Minuten am Stück hinein. 2017 wieder geflutet — die Bergwerk-Pumpen wurden abgeschaltet, das Wasser kehrt zurück. Die Kristalle wachsen jetzt wieder. Die Höhle ist faktisch verloren für die Forschung.''',
    position: const LatLng(27.8519, -105.4969),
    category: EnergieCategory.crystalCaves,
    keywords: ['Naica', 'Selenit', 'Kristall', 'Mexiko', 'Chihuahua'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b6/CuevaDeLosCristales5.JPG/1024px-CuevaDeLosCristales5.JPG',
    ],
    energyLevel: 10,
  ),
  EnergieLocationDetail(
    name: 'Mammoth Cave - Kentucky',
    description: 'Längstes Höhlensystem der Welt',
    detailedInfo:
        '''>676 km kartierte Gänge — fünfmal länger als das zweitgrößte System der Welt. Indigene Nutzung dokumentiert bis 4.000 Jahre zurück (Mumien gefunden 1813). UNESCO-Welterbe seit 1981.

Karst-Höhlenkomplex mit besonderem Mikroklima. Untergrund-Atmosphäre wirkt nachweislich beruhigend (negativ ionisierte Luft).''',
    position: const LatLng(37.1838, -86.1000),
    category: EnergieCategory.crystalCaves,
    keywords: ['Mammoth', 'Kentucky', 'Karst', 'Höhle'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6c/Mammoth_Cave_tour_-_Mammoth_Cave_National_Park.JPG/1024px-Mammoth_Cave_tour_-_Mammoth_Cave_National_Park.JPG',
    ],
    energyLevel: 8,
  ),

  // ── BERGKETTEN & ENERGIEKNOTEN ──────────────────────────────────
  EnergieLocationDetail(
    name: 'Aoraki / Mount Cook - Neuseeland',
    description: 'Heiligster Berg der Maori',
    detailedInfo:
        '''3.724 m, Neuseelands höchster Berg. Heilig für die Ngāi Tahu-Maori als versteinerter Vorfahre. 1998 in der Treaty of Waitangi-Reform offiziell auch unter Maori-Namen anerkannt.

Die Edmund-Hillary-Gedenkstätte erinnert an die Mount-Everest-Vorbereitung: Hillary trainierte hier. Aoraki Mackenzie Dark Sky Reserve — eines der dunkelsten Himmelsareale der Erde, optimal für Sternenbeobachtung.''',
    position: const LatLng(-43.5950, 170.1418),
    category: EnergieCategory.sacredSites,
    keywords: ['Aoraki', 'Maori', 'Mount Cook', 'Neuseeland'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/01/MountCook.jpg/1024px-MountCook.jpg',
    ],
    energyLevel: 8,
  ),
  EnergieLocationDetail(
    name: 'Cerro Aconcagua - Argentinien',
    description: 'Höchster Berg Südamerikas, Inka-Ritual-Berg',
    detailedInfo:
        '''6.961 m — höchster Gipfel der Anden und außerhalb Asiens. 1985 Fund einer Inka-Kindermumie auf 5.300 m — Beleg für Höhen-Ritualstätten der Inka. "Aconcagua" bedeutet möglicherweise "Steinwächter" (Quechua).

Wettergottheit-Sitz in der Inka-Kosmologie. Gilt heute als kraftvoller Bewusstseins-Punkt für die spirituelle Praxis "Munay-Ki" der Q'ero-Schamanen.''',
    position: const LatLng(-32.6532, -70.0109),
    category: EnergieCategory.sacredSites,
    keywords: ['Aconcagua', 'Anden', 'Inka', 'Argentinien'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1f/Aconcagua_in_January_2020_from_Plaza_Francia.jpg/1024px-Aconcagua_in_January_2020_from_Plaza_Francia.jpg',
    ],
    energyLevel: 9,
  ),
  EnergieLocationDetail(
    name: 'Mount Kilauea - Hawaii',
    description: 'Lebende Vulkangöttin Pele',
    detailedInfo:
        '''Einer der aktivsten Vulkane der Welt, fast durchgehend aktiv seit 1983. Im hawaiianischen Glauben ist hier Pele zu Hause — die Göttin der Vulkane, der Feuer und des Schaffens.

Lavaformen werden als Botschaften gedeutet. Touristen, die Lavasteine mitnehmen, bekommen laut Tradition Unglück ("Pele's curse") — die Volcanoes National Park-Verwaltung erhält jährlich Pakete mit zurückgeschickten Steinen.''',
    position: const LatLng(19.4069, -155.2834),
    category: EnergieCategory.sacredSites,
    keywords: ['Kilauea', 'Hawaii', 'Pele', 'Vulkan'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4a/Kilauea_at_night.JPG/1024px-Kilauea_at_night.JPG',
    ],
    energyLevel: 9,
  ),

  // ── PILGER-ZENTREN & MODERNE STÄTTEN ────────────────────────────
  EnergieLocationDetail(
    name: 'Lourdes - Frankreich',
    description: 'Heilstätte, 6 Millionen Pilger jährlich',
    detailedInfo:
        '''1858: Die 14-jährige Bernadette Soubirous hatte 18 Marienerscheinungen in der Grotte Massabielle. Quelle entsprang dort, wo die Jungfrau hinwies — heute kommen 6 Mio. Pilger jährlich für Heilung.

70 Heilungen offiziell von der katholischen Kirche als "wunderbar" anerkannt (von ~7.000 ungeklärten Spontanremissionen). Lourdes Medical Bureau prüft seit 1883 alle Heilungsberichte wissenschaftlich.''',
    position: const LatLng(43.0978, -0.0470),
    category: EnergieCategory.sacredSites,
    keywords: ['Lourdes', 'Maria', 'Heilung', 'Pilger', 'Soubirous'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4f/Lourdes_-_Basilika_4.JPG/1024px-Lourdes_-_Basilika_4.JPG',
    ],
    energyLevel: 9,
  ),
  EnergieLocationDetail(
    name: 'Goldener Tempel Amritsar - Indien',
    description: 'Heiligstes Zentrum der Sikhs',
    detailedInfo:
        'Harmandir Sahib (1604 gebaut), umgeben vom heiligen "Pool der Unsterblichkeit" (Amrit Sarovar). Tag und Nacht offen für alle Religionen — 100.000 Menschen täglich essen kostenlos im Langar (Gemeinschaftsküche).\n\nGoldene Kuppel: 750 kg reines Gold (1830 erneuert). Akustisch: Live-Kirtan (heilige Gesänge) 20 Stunden täglich. Eines der wenigen Heiligtümer mit 4 Eingängen — symbolisiert Offenheit für alle Himmelsrichtungen.',
    position: const LatLng(31.6200, 74.8765),
    category: EnergieCategory.sacredSites,
    keywords: ['Goldener Tempel', 'Sikh', 'Amritsar', 'Harmandir'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b3/The_Harmandir_Sahib_%28The_Golden_Temple%29.jpg/1024px-The_Harmandir_Sahib_%28The_Golden_Temple%29.jpg',
    ],
    energyLevel: 9,
  ),
  EnergieLocationDetail(
    name: 'Heiliger Berg Athos - Griechenland',
    description: 'Orthodoxes Mönchskloster-Republik',
    detailedInfo:
        '''20 Klöster auf einer Halbinsel in Griechenland. Autonomes Gebiet — Frauen seit 1.000 Jahren verboten (auch weibliche Tiere, bis auf Hauskatzen für Mäusebekämpfung). Hesychasmus: kontinuierliches Jesus-Gebet als Erleuchtungsweg.

Die ältesten Mönche praktizieren das "Herzensgebet" 18+ Stunden täglich. Manche der Klöster behalten Reliquien aus dem 9. Jh. bei. UNESCO-Welterbe.''',
    position: const LatLng(40.2444, 24.2208),
    category: EnergieCategory.meditationCenters,
    keywords: ['Athos', 'Orthodox', 'Hesychasmus', 'Griechenland'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d8/Simonopetra_monastery%2C_Mount_Athos%2C_Greece.jpg/1024px-Simonopetra_monastery%2C_Mount_Athos%2C_Greece.jpg',
    ],
    energyLevel: 9,
  ),
  EnergieLocationDetail(
    name: 'Sintra Quinta da Regaleira - Portugal',
    description: 'Esoterischer Garten mit Initiationsbrunnen',
    detailedInfo:
        '''Spätes 19. Jh. von António Augusto Carvalho Monteiro entworfen (mit dem Architekten Luigi Manini). Templer- und Freimaurer-Symbolik überall. Der "Initiationsbrunnen" — 27 m tief, mit 9 spiralförmigen Stockwerken — diente esoterischen Einweihungsritualen.

Tunnels verbinden den Brunnen mit anderen Symbolik-Orten des Gartens. Sintra selbst gilt seit der Romantik als magischer Ort, in einer "energetischen Kerbe" zwischen Atlantik und Iberischer Hochebene.''',
    position: const LatLng(38.7967, -9.3963),
    category: EnergieCategory.kraftorte,
    keywords: ['Sintra', 'Regaleira', 'Templer', 'Freimaurer', 'Portugal'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Quinta_da_Regaleira_Sintra_2.jpg/1024px-Quinta_da_Regaleira_Sintra_2.jpg',
    ],
    energyLevel: 8,
  ),
  EnergieLocationDetail(
    name: 'Petra - Jordanien',
    description: 'Felsenstadt der Nabatäer',
    detailedInfo:
        '''4. Jh. v.Chr. — 1. Jh. n.Chr. Hauptstadt der Nabatäer. In rosa Sandstein gehauen, das berühmte "Schatzhaus" (Al-Khazneh) zeigt die typische Architektur. Astronomische Ausrichtung der Hauptmonumente zur Tagundnachtgleiche.

Die Nabatäer kontrollierten die Karawanenrouten und das Wasser — eine Stadt mitten in der Wüste, gespeist durch ausgeklügelte Kanal-Systeme. UNESCO-Welterbe.''',
    position: const LatLng(30.3285, 35.4444),
    category: EnergieCategory.ancientTemples,
    keywords: ['Petra', 'Nabatäer', 'Jordanien', 'Felsenstadt'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/97/The_Treasury_2_Petra_Jordan2962.jpg/1024px-The_Treasury_2_Petra_Jordan2962.jpg',
    ],
    energyLevel: 9,
  ),
  EnergieLocationDetail(
    name: 'Bodhgaya - Indien',
    description: 'Ort der Erleuchtung Buddhas',
    detailedInfo:
        '''Hier saß Siddhartha Gautama unter dem Bodhi-Baum, als er Erleuchtung erlangte (~528 v.Chr.). Der Mahabodhi-Tempel (3. Jh. v.Chr. begonnen, im 5./6. Jh. n.Chr. ausgebaut) ist das heiligste Zentrum des Buddhismus.

Der jetzige Bodhi-Baum ist ein direkter Nachkomme des Originals — Ableger wurden mehrmals durch die Jahrhunderte gerettet. UNESCO-Welterbe. Jährlich 2 Millionen buddhistische Pilger.''',
    position: const LatLng(24.6961, 84.9911),
    category: EnergieCategory.sacredSites,
    keywords: ['Bodhgaya', 'Buddha', 'Erleuchtung', 'Bodhi-Baum'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c3/Mahabodhi_Temple_5.jpg/1024px-Mahabodhi_Temple_5.jpg',
    ],
    energyLevel: 10,
  ),
  EnergieLocationDetail(
    name: 'Lhasa Potala - Tibet',
    description: 'Ehemaliger Sitz des Dalai Lama',
    detailedInfo:
        '''3.700 m Höhe. 7. Jh. erbaut, mehrmals erneuert — heutige Form von Dalai Lama V (17. Jh.). 13 Stockwerke, über 1.000 Räume. UNESCO-Welterbe.

Bis 1959 Hauptresidenz des Dalai Lama und Sitz der tibetischen Regierung. Heute Museum unter chinesischer Verwaltung. Pilger umrunden den Komplex bis heute betend.''',
    position: const LatLng(29.6557, 91.1170),
    category: EnergieCategory.meditationCenters,
    keywords: ['Lhasa', 'Potala', 'Dalai Lama', 'Tibet'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/30/Potala_Palace_2020.jpg/1024px-Potala_Palace_2020.jpg',
    ],
    energyLevel: 9,
  ),
  EnergieLocationDetail(
    name: 'Mont-Saint-Michel - Frankreich',
    description: 'Klosterberg-Insel in der Normandie',
    detailedInfo:
        '''708 n.Chr. von Bischof Aubert gegründet, nach einer Vision des Erzengels Michael. Bei Flut wird der Berg eine Insel, bei Ebbe begehbar — Symbolik für den spirituellen Übergang.

Der Mont liegt exakt auf der "Apollo-Michael-Linie" — der berühmtesten europäischen Leyline (St. Michael's Mount in England → Hetlin in Cornwall → Mont-Saint-Michel → Sacra di San Michele in Italien → Monte Gargano → Symi-Insel → Stella Maris auf dem Karmel).''',
    position: const LatLng(48.6360, -1.5115),
    category: EnergieCategory.sacredSites,
    keywords: ['Mont-Saint-Michel', 'Michael-Linie', 'Normandie', 'Aubert'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/d/db/Mont_St_Michel_3%2C_Brittany%2C_France_-_July_2011.jpg/1024px-Mont_St_Michel_3%2C_Brittany%2C_France_-_July_2011.jpg',
    ],
    energyLevel: 10,
  ),
  EnergieLocationDetail(
    name: 'Sacra di San Michele - Italien',
    description: 'Felsenkloster auf der Apollo-Michael-Linie',
    detailedInfo:
        '''11. Jh. errichtet auf dem Monte Pirchiriano (962 m, Piemont). Liegt auf der berühmten "Sword of Michael"-Linie — sieben Michaelsheiligtümer auf einer geraden Linie quer durch Europa.

Inspirierte Umberto Eco zu "Der Name der Rose". 9. Jh. von Hugo de Montboissier als Pilgerstation zwischen Frankreich und Italien gegründet. Heute Sitz der Rosminianer-Patres.''',
    position: const LatLng(45.0975, 7.3429),
    category: EnergieCategory.sacredSites,
    keywords: ['Sacra', 'San Michele', 'Michael-Linie', 'Piemont'],
    imageUrls: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/Sacra_di_San_Michele_da_lontano.jpg/1024px-Sacra_di_San_Michele_da_lontano.jpg',
    ],
    energyLevel: 9,
  ),
];
