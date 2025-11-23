import 'package:latlong2/latlong.dart';
import '../models/event_model.dart';
import 'mystical_events_data_extended.dart';
import 'mystical_events_enhanced.dart';

/// 85+ Mystische Orte & Alternative Ereignisse weltweit
class MysticalEventsData {
  static List<EventModel> getAllEvents() {
    // NEUE VERSION: Nutze erweiterte Events mit detaillierten Beschreibungen und Medien
    final enhancedEvents = MysticalEventsEnhanced.getAllEnhancedEvents();

    // Kombiniere mit zusätzlichen Events (falls vorhanden)
    final extendedEvents = MysticalEventsDataExtended.getExtendedEvents();

    return [...enhancedEvents, ...extendedEvents];
  }

  // Alte Basis-Events (nicht mehr verwendet - durch enhanced Events ersetzt)
  // ignore: unused_element
  static List<EventModel> _getBaseEvents() {
    return [
      // Die ersten 22 Events aus der vorherigen Erstellung...
      EventModel(
        id: '1',
        title: 'Pyramiden von Gizeh',
        description:
            'Die großen Pyramiden - Präzise astronomische Ausrichtung, mathematische Perfektion und ungeklärte Bautechniken der Antike.',
        location: const LatLng(29.9792, 31.1342),
        category: 'archaeology',
        date: DateTime(2560).subtract(const Duration(days: 365 * 4580)),
        imageUrl:
            'https://images.unsplash.com/photo-1572252009286-268acec5ca0a?w=800',
        tags: ['Ägypten', 'Pyramiden', 'Antike', 'Energiepunkt'],
        source: 'Archaeological Research',
        isVerified: true,
        resonanceFrequency: 7.83,
      ),
      EventModel(
        id: '2',
        title: 'Sphinx von Gizeh',
        description:
            'Geologische Erosionsspuren deuten auf ein Alter von 10.000+ Jahren hin - deutlich älter als offiziell angegeben.',
        location: const LatLng(29.9753, 31.1376),
        category: 'mystery',
        date: DateTime(10500).subtract(const Duration(days: 365 * 12500)),
        imageUrl:
            'https://images.unsplash.com/photo-1503177119275-0aa32b3a9368?w=800',
        tags: ['Sphinx', 'Ägypten', 'Wassererosion', 'Atlantis-Verbindung'],
        isVerified: false,
        resonanceFrequency: 8.12,
      ),
      EventModel(
        id: '3',
        title: 'Göbekli Tepe',
        description:
            'Ältester bekannter Tempelkomplex (11.500 Jahre alt) - erbaut VOR der Erfindung der Landwirtschaft!',
        location: const LatLng(37.2233, 38.9225),
        category: 'archaeology',
        date: DateTime(9500).subtract(const Duration(days: 365 * 11500)),
        imageUrl:
            'https://images.unsplash.com/photo-1589308078059-be1415eab4c7?w=800',
        tags: [
          'Türkei',
          'Göbekli Tepe',
          'Prähistorisch',
          'Zivilisationsursprung',
        ],
        source: 'German Archaeological Institute',
        isVerified: true,
        resonanceFrequency: 8.45,
      ),
      EventModel(
        id: '4',
        title: 'Machu Picchu',
        description:
            'Inka-Stadt auf 2.430m Höhe mit präziser Sonnenausrichtung und unerklärbaren Steinbearbeitungstechniken.',
        location: const LatLng(-13.1631, -72.5450),
        category: 'archaeology',
        date: DateTime(1450, 1, 1),
        imageUrl:
            'https://images.unsplash.com/photo-1587595431973-160d0d94add1?w=800',
        tags: ['Peru', 'Inka', 'Machu Picchu', 'Energiezentrum'],
        isVerified: true,
        resonanceFrequency: 8.23,
      ),
      EventModel(
        id: '5',
        title: 'Nazca-Linien',
        description:
            'Riesige Geoglyphen (bis 370m lang) nur aus der Luft erkennbar - Zweck bis heute ungeklärt.',
        location: const LatLng(-14.7390, -75.1300),
        category: 'mystery',
        date: DateTime(500).subtract(const Duration(days: 365 * 2500)),
        imageUrl:
            'https://images.unsplash.com/photo-1531065208531-4036c0dba3f5?w=800',
        tags: ['Peru', 'Nazca', 'Geoglyphen', 'Astronomische Kalender'],
        isVerified: true,
        resonanceFrequency: 7.77,
      ),
      EventModel(
        id: '6',
        title: 'Stonehenge',
        description:
            'Prähistorisches Monument mit astronomischer Ausrichtung zu Sonnenwenden. Transport der Steine ungeklärt.',
        location: const LatLng(51.1789, -1.8262),
        category: 'archaeology',
        date: DateTime(3000).subtract(const Duration(days: 365 * 5000)),
        imageUrl:
            'https://images.unsplash.com/photo-1599833975787-5d6f8c5c3b45?w=800',
        tags: ['England', 'Stonehenge', 'Megalith', 'Sonnenwende'],
        isVerified: true,
        resonanceFrequency: 7.83,
      ),
      EventModel(
        id: '7',
        title: 'Bermuda-Dreieck',
        description:
            'Gebiet mit unerklärlichen Schiffs- und Flugzeugverschwinden. Magnetische Anomalien gemessen.',
        location: const LatLng(25.0000, -71.0000),
        category: 'phenomenon',
        date: DateTime(1945, 12, 5),
        tags: ['Bermuda', 'Anomalie', 'Magnetfeld'],
        isVerified: false,
        resonanceFrequency: 6.66,
      ),
      EventModel(
        id: '8',
        title: 'Angkor Wat',
        description:
            'Größter religiöser Komplex der Welt mit präziser astronomischer Ausrichtung.',
        location: const LatLng(13.4125, 103.8670),
        category: 'archaeology',
        date: DateTime(1113, 1, 1),
        imageUrl:
            'https://images.unsplash.com/photo-1545581431-57bff8c6b189?w=800',
        tags: ['Kambodscha', 'Angkor Wat', 'Tempel', 'Khmer'],
        isVerified: true,
        resonanceFrequency: 8.18,
      ),
      // Weitere Events folgen zur Erreichung von 141 Orten...
      EventModel(
        id: '9',
        title: 'Chichén Itzá',
        description:
            'Maya-Pyramide mit akustischen Phänomenen und präziser Kalender-Astronomie.',
        location: const LatLng(20.6843, -88.5678),
        category: 'archaeology',
        date: DateTime(600, 1, 1),
        imageUrl:
            'https://images.unsplash.com/photo-1518638150340-f706e86654de?w=800',
        tags: ['Mexiko', 'Maya', 'Chichén Itzá', 'Kukulkan'],
        isVerified: true,
        resonanceFrequency: 7.85,
      ),
      EventModel(
        id: '10',
        title: 'Newgrange',
        description:
            '5.200 Jahre altes Hügelgrab - älter als Stonehenge! Licht dringt nur zur Wintersonnenwende ins Innere.',
        location: const LatLng(53.6947, -6.4755),
        category: 'archaeology',
        date: DateTime(3200).subtract(const Duration(days: 365 * 5200)),
        tags: ['Irland', 'Newgrange', 'Sonnenwende', 'Neolithikum'],
        isVerified: true,
        resonanceFrequency: 8.05,
      ),

      // === MEGALITHISCHE STRUKTUREN (11-30) ===
      EventModel(
        id: '11',
        title: 'Baalbek',
        description:
            'Massive Steinblöcke bis 1.200 Tonnen - größte bearbeitete Steine der Antike. Transport-Methode ungeklärt.',
        location: const LatLng(34.0063, 36.2039),
        category: 'archaeology',
        date: DateTime(2000).subtract(const Duration(days: 365 * 4000)),
        imageUrl:
            'https://images.unsplash.com/photo-1578496479914-7ef3b0193be3?w=800',
        tags: ['Libanon', 'Baalbek', 'Megalith', 'Römische Ruinen'],
        isVerified: true,
        resonanceFrequency: 8.55,
      ),
      EventModel(
        id: '12',
        title: 'Teotihuacán',
        description:
            'Sonnen- und Mondpyramide mit geometrischer Präzision. Erbauer und Zweck unbekannt.',
        location: const LatLng(19.6925, -98.8438),
        category: 'archaeology',
        date: DateTime(100, 1, 1),
        imageUrl:
            'https://images.unsplash.com/photo-1512813498716-28b3e2d55923?w=800',
        tags: ['Mexiko', 'Teotihuacán', 'Pyramiden', 'Präkolumbisch'],
        isVerified: true,
        resonanceFrequency: 7.95,
      ),
      EventModel(
        id: '13',
        title: 'Carnac-Steine',
        description:
            'Über 3.000 prähistorische Megalithen in Reihen aufgestellt - Zweck unbekannt.',
        location: const LatLng(47.5828, -3.0776),
        category: 'archaeology',
        date: DateTime(4500).subtract(const Duration(days: 365 * 6500)),
        tags: ['Frankreich', 'Carnac', 'Megalith', 'Steinreihen'],
        isVerified: true,
        resonanceFrequency: 7.88,
      ),
      EventModel(
        id: '14',
        title: 'Moai-Statuen Osterinsel',
        description:
            '887 monumentale Statuen (bis 82 Tonnen). Transport- und Aufstellungsmethode rätselhaft.',
        location: const LatLng(-27.1127, -109.3497),
        category: 'archaeology',
        date: DateTime(1250, 1, 1),
        imageUrl:
            'https://images.unsplash.com/photo-1555881675-7a2ebe615c0b?w=800',
        tags: ['Osterinsel', 'Moai', 'Rapa Nui', 'Steinstatuen'],
        isVerified: true,
        resonanceFrequency: 7.91,
      ),
      EventModel(
        id: '15',
        title: 'Derinkuyu Untergrundstadt',
        description:
            '18-stöckige unterirdische Stadt für 20.000 Menschen. Erbauer und Alter unklar.',
        location: const LatLng(38.3736, 34.7347),
        category: 'archaeology',
        date: DateTime(800).subtract(const Duration(days: 365 * 2800)),
        tags: ['Türkei', 'Derinkuyu', 'Unterirdisch', 'Kappadokien'],
        isVerified: true,
        resonanceFrequency: 8.02,
      ),
      EventModel(
        id: '16',
        title: 'Puma Punku',
        description:
            'Präzise geschnittene Steinblöcke mit Laser-ähnlicher Genauigkeit - prähistorische Technologie?',
        location: const LatLng(-16.5581, -68.6786),
        category: 'archaeology',
        date: DateTime(536, 1, 1),
        imageUrl:
            'https://images.unsplash.com/photo-1569154941061-e231b4725ef1?w=800',
        tags: ['Bolivien', 'Puma Punku', 'Tiwanaku', 'Megalith'],
        isVerified: true,
        resonanceFrequency: 8.33,
      ),
      EventModel(
        id: '17',
        title: 'Sacsayhuamán',
        description:
            'Präzise zusammengefügte Megalithsteine ohne Mörtel - Erdbebensicher.',
        location: const LatLng(-13.5088, -71.9817),
        category: 'archaeology',
        date: DateTime(1438, 1, 1),
        tags: ['Peru', 'Cusco', 'Sacsayhuamán', 'Inka'],
        isVerified: true,
        resonanceFrequency: 8.11,
      ),
      EventModel(
        id: '18',
        title: 'Avebury',
        description:
            'Größter steinerner Steinkreis Europas - Teil eines größeren rituellen Landschaftskomplexes.',
        location: const LatLng(51.4285, -1.8538),
        category: 'archaeology',
        date: DateTime(2850).subtract(const Duration(days: 365 * 4850)),
        tags: ['England', 'Avebury', 'Steinkreis', 'Neolithikum'],
        isVerified: true,
        resonanceFrequency: 7.89,
      ),
      EventModel(
        id: '19',
        title: 'Carnac Tumulus',
        description:
            'Megalithische Grabstätten mit astronomischer Ausrichtung.',
        location: const LatLng(47.5897, -3.0945),
        category: 'archaeology',
        date: DateTime(4000).subtract(const Duration(days: 365 * 6000)),
        tags: ['Frankreich', 'Carnac', 'Tumulus', 'Grabstätte'],
        isVerified: true,
        resonanceFrequency: 7.92,
      ),
      EventModel(
        id: '20',
        title: 'Nuraghe-Türme Sardinien',
        description:
            'Über 7.000 prähistorische Steintürme - älteste Steinbauten Europas.',
        location: const LatLng(40.3204, 9.1123),
        category: 'archaeology',
        date: DateTime(1500).subtract(const Duration(days: 365 * 3500)),
        tags: ['Sardinien', 'Nuraghe', 'Prähistorisch', 'Türme'],
        isVerified: true,
        resonanceFrequency: 7.97,
      ),

      // === ENERGIEPUNKTE & VORTEXE (21-40) ===
      EventModel(
        id: '21',
        title: 'Sedona Vortex',
        description:
            'Vier Hauptvortex-Punkte mit messbaren elektromagnetischen Anomalien.',
        location: const LatLng(34.8697, -111.7610),
        category: 'energy',
        date: DateTime.now(),
        tags: ['USA', 'Sedona', 'Vortex', 'Energiepunkt'],
        isVerified: false,
        resonanceFrequency: 9.13,
      ),
      EventModel(
        id: '22',
        title: 'Mount Shasta',
        description:
            'Heiliger Berg mit Ley-Linien-Kreuzung und mystischen Sichtungen.',
        location: const LatLng(41.4093, -122.1949),
        category: 'energy',
        date: DateTime.now(),
        tags: ['USA', 'Mount Shasta', 'Energieberg', 'Ley Lines'],
        isVerified: false,
        resonanceFrequency: 8.88,
      ),
      EventModel(
        id: '23',
        title: 'Uluru (Ayers Rock)',
        description:
            'Heiliger Berg der Aborigines mit starker spiritueller Energie.',
        location: const LatLng(-25.3444, 131.0369),
        category: 'energy',
        date: DateTime(600).subtract(const Duration(days: 365 * 60000)),
        imageUrl:
            'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
        tags: ['Australien', 'Uluru', 'Heiliger Berg', 'Aborigines'],
        isVerified: true,
        resonanceFrequency: 8.25,
      ),
      EventModel(
        id: '24',
        title: 'Glastonbury Tor',
        description: 'Ley-Linien-Kreuzung und legendärer Eingang nach Avalon.',
        location: const LatLng(51.1442, -2.6990),
        category: 'energy',
        date: DateTime(500, 1, 1),
        tags: ['England', 'Glastonbury', 'Avalon', 'Ley Lines'],
        isVerified: false,
        resonanceFrequency: 8.67,
      ),
      EventModel(
        id: '25',
        title: 'Mount Kailash',
        description:
            'Heiligster Berg Asiens - nie bestiegen. Ley-Linien-Kreuzung.',
        location: const LatLng(31.0668, 81.3120),
        category: 'energy',
        date: DateTime.now(),
        imageUrl:
            'https://images.unsplash.com/photo-1626621341517-bbf3d9990a23?w=800',
        tags: ['Tibet', 'Kailash', 'Heiliger Berg', 'Shiva'],
        isVerified: true,
        resonanceFrequency: 9.52,
      ),
      EventModel(
        id: '26',
        title: 'Machu Picchu Inka-Trail',
        description: 'Energetischer Pilgerpfad zu Inka-Kraftorten.',
        location: const LatLng(-13.2093, -72.4954),
        category: 'energy',
        date: DateTime(1450, 1, 1),
        tags: ['Peru', 'Inka-Trail', 'Pilgerweg', 'Energie'],
        isVerified: true,
        resonanceFrequency: 8.14,
      ),
      EventModel(
        id: '27',
        title: 'Yellowstone Caldera',
        description:
            'Supervulkan mit elektromagnetischen Anomalien und Energiefeldern.',
        location: const LatLng(44.4280, -110.5885),
        category: 'phenomenon',
        date: DateTime.now(),
        tags: ['USA', 'Yellowstone', 'Vulkan', 'Geothermal'],
        isVerified: true,
        resonanceFrequency: 7.23,
      ),
      EventModel(
        id: '28',
        title: 'Rila-Gebirge',
        description: 'Bulgarisches Energiezentrum mit mystischen Kraftplätzen.',
        location: const LatLng(42.1333, 23.5833),
        category: 'energy',
        date: DateTime.now(),
        tags: ['Bulgarien', 'Rila', 'Energiezentrum', 'Kloster'],
        isVerified: false,
        resonanceFrequency: 8.44,
      ),
      EventModel(
        id: '29',
        title: 'Huangshan (Gelbe Berge)',
        description: 'Heilige daoistische Berge mit "Tor zum Himmel".',
        location: const LatLng(30.1334, 118.1583),
        category: 'energy',
        date: DateTime.now(),
        imageUrl:
            'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?w=800',
        tags: ['China', 'Huangshan', 'Taoismus', 'Heilige Berge'],
        isVerified: true,
        resonanceFrequency: 8.77,
      ),
      EventModel(
        id: '30',
        title: 'Shasta-Sedona Ley Line',
        description: 'Hauptenergie-Linie zwischen zwei Vortex-Zentren.',
        location: const LatLng(38.1392, -117.0046),
        category: 'energy',
        date: DateTime.now(),
        tags: ['USA', 'Ley Line', 'Energie-Korridor'],
        isVerified: false,
        resonanceFrequency: 8.99,
      ),

      // === UNTERWASSER-MYSTERIEN (31-45) ===
      EventModel(
        id: '31',
        title: 'Bimini Road',
        description:
            'Unterwasser-Steinformation vor Bahamas - mögliche Reste von Atlantis?',
        location: const LatLng(25.7779, -79.2960),
        category: 'alternative',
        date: DateTime(1968, 9, 2),
        tags: ['Bahamas', 'Bimini', 'Unterwasser', 'Atlantis'],
        isVerified: false,
        resonanceFrequency: 7.44,
      ),
      EventModel(
        id: '32',
        title: 'Yonaguni Monument',
        description:
            'Unterwasser-Pyramide vor Japan - Natur oder 10.000 Jahre alte Struktur?',
        location: const LatLng(24.4333, 123.0167),
        category: 'alternative',
        date: DateTime(1987, 1, 1),
        imageUrl:
            'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800',
        tags: ['Japan', 'Yonaguni', 'Unterwasser', 'Pyramide'],
        isVerified: false,
        resonanceFrequency: 7.66,
      ),
      EventModel(
        id: '33',
        title: 'Dwarka',
        description:
            'Versunkene Stadt vor Indiens Küste - mythischer Sitz von Krishna.',
        location: const LatLng(22.2442, 68.9685),
        category: 'archaeology',
        date: DateTime(1500).subtract(const Duration(days: 365 * 3500)),
        tags: ['Indien', 'Dwarka', 'Unterwasser', 'Krishna'],
        isVerified: true,
        resonanceFrequency: 8.03,
      ),
      EventModel(
        id: '34',
        title: 'Pavlopetri',
        description: 'Älteste versunkene Stadt (5.000 Jahre) vor Griechenland.',
        location: const LatLng(36.6144, 22.8903),
        category: 'archaeology',
        date: DateTime(3000).subtract(const Duration(days: 365 * 5000)),
        tags: ['Griechenland', 'Pavlopetri', 'Unterwasser', 'Bronzezeit'],
        isVerified: true,
        resonanceFrequency: 7.52,
      ),
      EventModel(
        id: '35',
        title: 'Heraklion',
        description: 'Versunkene ägyptische Hafenstadt entdeckt 2000.',
        location: const LatLng(31.2977, 30.1039),
        category: 'archaeology',
        date: DateTime(800).subtract(const Duration(days: 365 * 2800)),
        tags: ['Ägypten', 'Heraklion', 'Unterwasser', 'Hafenstadt'],
        isVerified: true,
        resonanceFrequency: 7.71,
      ),
      EventModel(
        id: '36',
        title: 'Atlit Yam',
        description: 'Unterwasser-Neolithikum-Dorf vor Israel mit Steinkreis.',
        location: const LatLng(32.6936, 34.9393),
        category: 'archaeology',
        date: DateTime(7000).subtract(const Duration(days: 365 * 9000)),
        tags: ['Israel', 'Atlit Yam', 'Neolithikum', 'Unterwasser'],
        isVerified: true,
        resonanceFrequency: 7.89,
      ),
      EventModel(
        id: '37',
        title: 'Nan Madol',
        description:
            'Megalithische Ruinen auf künstlichen Inseln - "Venedig des Pazifiks".',
        location: const LatLng(6.8406, 158.3314),
        category: 'archaeology',
        date: DateTime(1200, 1, 1),
        tags: ['Mikronesien', 'Nan Madol', 'Megalith', 'Künstliche Inseln'],
        isVerified: true,
        resonanceFrequency: 8.21,
      ),
      EventModel(
        id: '38',
        title: 'Lake Michigan Stonehenge',
        description:
            'Unterwasser-Steinkreis mit Mastodon-Gravur entdeckt 2007.',
        location: const LatLng(45.0200, -86.4100),
        category: 'alternative',
        date: DateTime(2007, 1, 1),
        tags: ['USA', 'Lake Michigan', 'Stonehenge', 'Prähistorisch'],
        isVerified: false,
        resonanceFrequency: 7.93,
      ),
      EventModel(
        id: '39',
        title: 'Cuba Unterwasser-Strukturen',
        description:
            'Sonar-Bilder zeigen pyramidenartige Strukturen 700m tief.',
        location: const LatLng(22.0000, -84.0000),
        category: 'alternative',
        date: DateTime(2001, 5, 1),
        tags: ['Kuba', 'Unterwasser', 'Pyramiden', 'Anomalie'],
        isVerified: false,
        resonanceFrequency: 7.33,
      ),
      EventModel(
        id: '40',
        title: 'Baltic Sea Anomaly',
        description:
            '60m großes rundes Objekt am Meeresboden - Natur oder Artefakt?',
        location: const LatLng(59.6500, 19.3000),
        category: 'phenomenon',
        date: DateTime(2011, 6, 19),
        tags: ['Ostsee', 'Anomalie', 'Unterwasser', 'UFO-Diskussion'],
        isVerified: false,
        resonanceFrequency: 6.88,
      ),
      EventModel(
        id: '41',
        title: 'Zakynthos Columns',
        description:
            'Unterwasser-Säulenformationen - geologisch oder künstlich?',
        location: const LatLng(37.7833, 20.9000),
        category: 'phenomenon',
        date: DateTime(2013, 1, 1),
        tags: ['Griechenland', 'Zakynthos', 'Unterwasser', 'Säulen'],
        isVerified: false,
        resonanceFrequency: 7.55,
      ),
      EventModel(
        id: '42',
        title: 'Port Royal',
        description:
            'Versunkene Piratenstadt - "Sodom der Karibik" (1692 Erdbeben).',
        location: const LatLng(17.9392, -76.8425),
        category: 'history',
        date: DateTime(1692, 6, 7),
        tags: ['Jamaika', 'Port Royal', 'Piraten', 'Erdbeben'],
        isVerified: true,
        resonanceFrequency: 7.12,
      ),
      EventModel(
        id: '43',
        title: 'Doggerland',
        description:
            'Versunkenes prähistorisches Land zwischen England und Europa.',
        location: const LatLng(54.0000, 3.0000),
        category: 'alternative',
        date: DateTime(8200).subtract(const Duration(days: 365 * 10200)),
        tags: ['Nordsee', 'Doggerland', 'Mesolithikum', 'Landbrücke'],
        isVerified: true,
        resonanceFrequency: 7.67,
      ),
      EventModel(
        id: '44',
        title: 'Sundaland',
        description:
            'Versunkener Kontinent in Südostasien - mögliche Wiege der Zivilisation.',
        location: const LatLng(2.0000, 108.0000),
        category: 'alternative',
        date: DateTime(10000).subtract(const Duration(days: 365 * 12000)),
        tags: ['Südostasien', 'Sundaland', 'Eiszeit', 'Versunken'],
        isVerified: false,
        resonanceFrequency: 7.78,
      ),
      EventModel(
        id: '45',
        title: 'Cleopatra Palace Alexandria',
        description: 'Versunkener Palast von Kleopatra vor Alexandria.',
        location: const LatLng(31.2001, 29.9187),
        category: 'archaeology',
        date: DateTime(365, 7, 21),
        tags: ['Ägypten', 'Alexandria', 'Kleopatra', 'Unterwasser'],
        isVerified: true,
        resonanceFrequency: 7.84,
      ),

      // Die Datei wird zu lang - ich teile auf in weitere Edits...
    ];
  }
}
