// Ursprung-Welt: Bewusstseinsforschung, RV, Parapsychologie, alte
// Wissensorte. 50+ Sites mit Foto-URL.
//
// Fokus: was die offizielle Wissenschaft als "Grenz" oder "Pseudo"
// abtut, aber dokumentierte Forschung (CIA-Stargate, SRI, Princeton
// Engineering Anomalies Research, etc.) hervorgebracht hat.

import 'package:flutter/material.dart';

class ResearchSite {
  final String name;
  final String badge;
  final String founded;
  final String description;
  final String status;
  final List<String> findings;
  final List<String> researchers;
  final double lat;
  final double lng;
  final String? imageUrl;
  final String
      category; // 'consciousness' | 'rv' | 'ufo' | 'cymatics' | 'tradition' | 'archaeology'

  const ResearchSite({
    required this.name,
    required this.badge,
    required this.founded,
    required this.description,
    required this.status,
    required this.lat,
    required this.lng,
    this.findings = const [],
    this.researchers = const [],
    this.imageUrl,
    this.category = 'consciousness',
  });

  IconData get icon {
    switch (category) {
      case 'rv':
        return Icons.remove_red_eye;
      case 'ufo':
        return Icons.flight;
      case 'cymatics':
        return Icons.graphic_eq;
      case 'tradition':
        return Icons.local_fire_department;
      case 'archaeology':
        return Icons.account_balance;
      default:
        return Icons.psychology;
    }
  }
}

const allUrsprungSites = <ResearchSite>[
  // ── CONSCIOUSNESS-FORSCHUNG ─────────────────────────────────────
  ResearchSite(
    name: 'Monroe Institute',
    badge: 'Hemi-Sync',
    founded: 'Gegründet 1974, Faber Virginia',
    description:
        'Robert A. Monroe (1915–1995) entwickelte "Hemi-Sync" — Binaurale Beats zur Synchronisation der Gehirnhälften. Out-of-Body-Experiences (OBE) als trainier­bar. Gateway Process (1983 CIA-Report). Heute Workshops + Open-Source-Materialien.',
    status: 'Aktiv · Hemi-Sync Programme weltweit',
    lat: 37.875,
    lng: -78.668,
    findings: [
      'Hemi-Sync-Technologie',
      'OBE-Training',
      'CIA Gateway-Report 1983'
    ],
    researchers: ['Robert Monroe', 'Joseph McMoneagle (Remote Viewer)'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2c/Monroe_Institute_David_Francis_Hall.jpg/1024px-Monroe_Institute_David_Francis_Hall.jpg',
    category: 'consciousness',
  ),
  ResearchSite(
    name: 'IONS — Institute of Noetic Sciences',
    badge: 'IONS',
    founded: '1973, Edgar Mitchell (Apollo 14)',
    description:
        'Astronaut Mitchell hatte auf dem Heimflug eine Bewusstseins-Erfahrung. Gründete IONS für wissenschaftliche Erforschung von Bewusstsein, Telepathie, Intentions-Effekte.',
    status: 'Aktiv · Petaluma California',
    lat: 38.227,
    lng: -122.524,
    findings: ['Global Consciousness Project', 'Intentions-Studien Dean Radin'],
    researchers: ['Edgar Mitchell', 'Dean Radin', 'Marilyn Schlitz'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cc/Institute_of_Noetic_Sciences_logo.svg/640px-Institute_of_Noetic_Sciences_logo.svg.png',
    category: 'consciousness',
  ),
  ResearchSite(
    name: 'Princeton Engineering Anomalies Research (PEAR)',
    badge: 'PEAR',
    founded: '1979–2007, Princeton',
    description:
        'Robert Jahn (Dekan Engineering School) erforschte Mind-Matter-Interaktion mit Zufallsgeneratoren. ~3 Mio Studien-Trials. Stat. signifikante Abweichungen.',
    status: 'Eingestellt 2007 — Daten archiviert',
    lat: 40.350,
    lng: -74.659,
    findings: ['REG-Anomalie-Daten 30 Jahre', 'Operator-Effekt nachweisbar'],
    researchers: ['Robert Jahn', 'Brenda Dunne'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/Princeton_shield.svg/240px-Princeton_shield.svg.png',
    category: 'consciousness',
  ),
  ResearchSite(
    name: 'Global Consciousness Project',
    badge: 'GCP',
    founded: '1998, Roger Nelson',
    description:
        '70+ Random-Number-Generators weltweit. Sammelt Daten seit 1998. Auffällige Abweichungen bei globalen Großereignissen (9/11, etc.).',
    status: 'Aktiv · Open Data',
    lat: 40.349,
    lng: -74.659,
    findings: ['Anomalie-Spikes bei 9/11', 'IONS-finanziert'],
    researchers: ['Roger Nelson', 'Dean Radin'],
    category: 'consciousness',
  ),
  ResearchSite(
    name: 'University of Virginia DOPS',
    badge: 'DOPS',
    founded: '1967, Ian Stevenson',
    description:
        'Division of Perceptual Studies. Reinkarnation-Fälle bei Kindern (Stevenson sammelte 3000+). Near-Death-Experience-Forschung.',
    status: 'Aktiv · Charlottesville',
    lat: 38.034,
    lng: -78.508,
    findings: ['Reinkarnations-Cases', 'NDE-Studien Bruce Greyson'],
    researchers: ['Ian Stevenson', 'Jim Tucker', 'Bruce Greyson'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f0/University_of_Virginia_seal.svg/240px-University_of_Virginia_seal.svg.png',
    category: 'consciousness',
  ),
  ResearchSite(
    name: 'CIA Stargate Project',
    badge: 'Stargate',
    founded: '1978–1995 (deklassifiziert 1995)',
    description:
        'CIA/DIA-Programm für Remote Viewing. ~20 Mio USD Budget. 252+ Operative Missionen. Funktionierte gut genug für 20 Jahre Finanzierung.',
    status: 'Beendet 1995 · Akten zum Teil geöffnet',
    lat: 38.952,
    lng: -77.146,
    findings: ['200+ erfolgreiche RV-Missionen', 'Cold-War-Spionage'],
    researchers: ['Joe McMoneagle', 'Ingo Swann', 'Hal Puthoff'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4d/CIA_Headquarters%2C_Langley_VA.jpg/1024px-CIA_Headquarters%2C_Langley_VA.jpg',
    category: 'rv',
  ),
  ResearchSite(
    name: 'SRI Remote Viewing Lab',
    badge: 'SRI RV',
    founded: '1972, Menlo Park',
    description:
        'Stanford Research Institute. Russell Targ und Hal Puthoff. Ingo Swann erforschte Coordinate Remote Viewing.',
    status: 'Programm 1990 beendet',
    lat: 37.460,
    lng: -122.183,
    findings: ['CRV-Methodologie', 'Targ-Puthoff "Mind-Reach" Buch'],
    researchers: ['Russell Targ', 'Hal Puthoff', 'Ingo Swann', 'Pat Price'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d3/SRI_International_logo.svg/640px-SRI_International_logo.svg.png',
    category: 'rv',
  ),
  ResearchSite(
    name: 'Maharishi University of Management',
    badge: 'MUM',
    founded: '1971, Iowa',
    description:
        'TM (Transzendentale Meditation) als Lehrgebiet. "Maharishi-Effekt": gemeinschaftliche TM senkt Kriminalität messbar (mehrere Studien).',
    status: 'Aktiv',
    lat: 41.020,
    lng: -91.965,
    findings: ['Maharishi-Effekt Studien', 'TM-Sidhi-Programme'],
    researchers: ['Maharishi Mahesh Yogi', 'David Orme-Johnson'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c6/Maharishi_International_University_Building.jpg/1024px-Maharishi_International_University_Building.jpg',
    category: 'consciousness',
  ),
  ResearchSite(
    name: 'HeartMath Institute',
    badge: 'HeartMath',
    founded: '1991, Boulder Creek CA',
    description:
        'Forschung zur Herzkohärenz. HRV-Biofeedback. Studien zeigen messbare Effekte von Herzkohärenz auf Gehirn + Umgebung (GCM-Projekt).',
    status: 'Aktiv',
    lat: 37.118,
    lng: -122.040,
    findings: ['Herz-Hirn-Kohärenz', 'Global Coherence Monitoring'],
    researchers: ['Doc Childre', 'Rollin McCraty'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/9/93/HeartMath_Institute_Logo.png/640px-HeartMath_Institute_Logo.png',
    category: 'consciousness',
  ),
  ResearchSite(
    name: 'Rhine Research Center',
    badge: 'Rhine',
    founded: '1935, Duke University',
    description:
        'J.B. Rhine prägte Begriff "Parapsychologie". Zener-Karten-Tests, präkognitive Studien. Heute eigenständig in Durham.',
    status: 'Aktiv',
    lat: 35.971,
    lng: -78.901,
    findings: ['Zener-Karten-Studien', 'ESP-Statistik'],
    researchers: ['J.B. Rhine', 'Louisa Rhine'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0b/Rhine_Research_Center_logo.png/640px-Rhine_Research_Center_logo.png',
    category: 'consciousness',
  ),
  ResearchSite(
    name: 'University of Edinburgh Koestler PRU',
    badge: 'KPRU',
    founded: '1985, Edinburgh',
    description:
        'Koestler Parapsychology Unit. Größte Uni-Forschungs-Einheit in Europa für Psi-Phänomene. Stiftung von Arthur Koestler.',
    status: 'Aktiv',
    lat: 55.944,
    lng: -3.187,
    findings: ['Meta-Analysen Ganzfeld-Studien'],
    researchers: ['Caroline Watt', 'Robert Morris'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/df/University_of_Edinburgh_ceremonial_roundel.svg/240px-University_of_Edinburgh_ceremonial_roundel.svg.png',
    category: 'consciousness',
  ),
  ResearchSite(
    name: 'PA — Parapsychological Association',
    badge: 'PA',
    founded: '1957',
    description:
        '1969 von der American Association for the Advancement of Science (AAAS) aufgenommen. Wissenschaftlich anerkannte Fachgesellschaft.',
    status: 'Aktiv',
    lat: 35.998,
    lng: -78.901,
    category: 'consciousness',
  ),

  // ── REMOTE VIEWING / INTUITION-INSTITUTE ────────────────────────
  ResearchSite(
    name: 'Farsight Institute',
    badge: 'Farsight',
    founded: '1995, Courtney Brown',
    description:
        'Remote-Viewing-Projekte mit deklassifizierter SRI-Methode. Targets aus Geschichte, Politik, Zukunft. YouTube-Channel.',
    status: 'Aktiv · Atlanta',
    lat: 33.749,
    lng: -84.388,
    findings: ['Multiple-Viewer-Sessions', 'Historische Rekonstruktionen'],
    researchers: ['Courtney Brown'],
    category: 'rv',
  ),
  ResearchSite(
    name: 'IRVA — International Remote Viewing Association',
    badge: 'IRVA',
    founded: '1999',
    description:
        'Verband der ehemaligen Stargate-Operativen. Jährliche Konferenzen. RV-Lehre + ethische Standards.',
    status: 'Aktiv',
    lat: 30.267,
    lng: -97.743,
    researchers: ['Joe McMoneagle', 'Lyn Buchanan', 'Paul H. Smith'],
    category: 'rv',
  ),

  // ── UFO / NHI ───────────────────────────────────────────────────
  ResearchSite(
    name: 'Roswell Incident Site',
    badge: 'Roswell',
    founded: 'Crash 1947',
    description:
        'Bekanntester UFO-Vorfall der Geschichte. USAF-Statement vom 8. Juli 1947 sprach von "Flying Disc". Korrektur 1 Tag später: Wetterballon.',
    status: 'Historisch',
    lat: 33.396,
    lng: -104.524,
    findings: ['Mac-Brazel-Fragmente', 'AAR-Memos'],
    researchers: ['Stanton Friedman', 'Kevin Randle'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/Roswell_UFO_Museum.jpg/1024px-Roswell_UFO_Museum.jpg',
    category: 'ufo',
  ),
  ResearchSite(
    name: 'Area 51 / Groom Lake',
    badge: 'S-4',
    founded: '~1955',
    description:
        'US-Air-Force-Basis Nevada Test and Training Range. Bekannt aus UFO-Folklore. Existenz erst 2013 offiziell durch CIA bestätigt.',
    status: 'Aktiv (geheim)',
    lat: 37.235,
    lng: -115.811,
    findings: ['U-2-Tests 1955', 'F-117 Stealth-Entwicklung'],
    researchers: ['Bob Lazar (Whistleblower)'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b6/Sign_at_alien_research_center.jpg/1024px-Sign_at_alien_research_center.jpg',
    category: 'ufo',
  ),
  ResearchSite(
    name: 'AATIP / AAWSAP — Pentagon UAP-Programme',
    badge: 'AATIP',
    founded: '2007 (AAWSAP) / 2012 (AATIP)',
    description:
        'Advanced Aerospace Threat Identification Program. Luis Elizondo leitete bis 2017. 2017 NY-Times-Enthüllung machte UAP-Diskurs salonfähig.',
    status: '2017 öffentlich · 2022 in AARO überführt',
    lat: 38.871,
    lng: -77.056,
    findings: ['Nimitz-Tic-Tac-Sichtung', 'Gimbal-, GoFast-Videos'],
    researchers: ['Luis Elizondo', 'Christopher Mellon'],
    category: 'ufo',
  ),
  ResearchSite(
    name: 'AARO — All-Domain Anomaly Resolution Office',
    badge: 'AARO',
    founded: '2022, Pentagon',
    description:
        'Nachfolger von AATIP. Untersucht UAP-Sichtungen aus Militär-Quellen. Jährliche Berichte ans Kongress.',
    status: 'Aktiv',
    lat: 38.871,
    lng: -77.056,
    findings: ['2024 historische UAP-Review-Report'],
    category: 'ufo',
  ),
  ResearchSite(
    name: 'MUFON HQ',
    badge: 'MUFON',
    founded: '1969, Cincinnati',
    description:
        'Mutual UFO Network. Größte zivile UAP-Datenbank. Field Investigator-Trainings.',
    status: 'Aktiv',
    lat: 39.110,
    lng: -84.515,
    findings: ['STAR-Datenbank ~100k Sichtungen'],
    category: 'ufo',
  ),
  ResearchSite(
    name: 'CUFOS — J. Allen Hynek Center',
    badge: 'CUFOS',
    founded: '1973, Hynek',
    description:
        'J. Allen Hynek war US Air Force Project Blue Book Berater, wurde zum Skeptiker-zu-Forscher. Klassifikations-Schema "Close Encounters".',
    status: 'Aktiv',
    lat: 41.901,
    lng: -87.628,
    researchers: ['J. Allen Hynek'],
    category: 'ufo',
  ),
  ResearchSite(
    name: 'Skinwalker Ranch',
    badge: 'Skinwalker',
    founded: 'Ranch seit 1880er, Untersuchungen ab 1996',
    description:
        '512 Acres in Utah. NIDS (Robert Bigelow), dann AAWSAP, dann TV-Show. Hot-Spot für UAP- und Paranormal-Aktivität (lt. Berichten).',
    status: 'Privat · TV-Show "The Secret of Skinwalker Ranch"',
    lat: 40.252,
    lng: -109.879,
    findings: ['NIDS-Reports', 'Colm-Kelleher-Buch'],
    researchers: ['Robert Bigelow', 'Colm Kelleher', 'Travis Taylor'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5b/Uintah_Basin_Utah_aerial.jpg/1024px-Uintah_Basin_Utah_aerial.jpg',
    category: 'ufo',
  ),
  ResearchSite(
    name: 'Rendlesham Forest',
    badge: 'Rendlesham',
    founded: 'Vorfall Dez 1980',
    description:
        '"Britain\'s Roswell". USAF-Basis-Nahe-Sichtung mit physischen Spuren am Boden. Halt-Memo, Halt-Tonband (Originalaufnahme).',
    status: 'Historisch',
    lat: 52.090,
    lng: 1.460,
    findings: ['Halt-Memo', 'Penniston-Notizen'],
    researchers: ['Charles Halt', 'James Penniston'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/e/eb/Rendlesham_forest_2002_april.JPG/1024px-Rendlesham_forest_2002_april.JPG',
    category: 'ufo',
  ),

  // ── ARCHÄOLOGIE / ALTE STÄTTEN ──────────────────────────────────
  ResearchSite(
    name: 'Göbekli Tepe',
    badge: '9.600 v.Chr.',
    founded: 'Ausgrabungen 1995, Klaus Schmidt',
    description:
        'Älteste megalithische Tempelanlage. T-Pfeiler bis 5,5m, vor der Sesshaftwerdung erbaut. Stürzt klassische Zivilisations-Theorie um.',
    status: 'Aktiv · UNESCO Welterbe',
    lat: 37.223,
    lng: 38.922,
    findings: ['20+ Steinkreise', 'Tierreliefs (Schlangen, Skorpione)'],
    researchers: ['Klaus Schmidt'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c8/G%C3%B6bekli_Tepe%2C_Urfa.jpg/1024px-G%C3%B6bekli_Tepe%2C_Urfa.jpg',
    category: 'archaeology',
  ),
  ResearchSite(
    name: 'Karahan Tepe',
    badge: '~10.000 v.Chr.',
    founded: 'Ausgrabungen ab 2019',
    description:
        'Schwester-Site von Göbekli Tepe. Noch älter, noch komplexer. 250+ Pfeiler, Höhlen-Räume in den Fels gehauen.',
    status: 'Aktive Ausgrabung',
    lat: 37.115,
    lng: 39.297,
    researchers: ['Necmi Karul'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Karahan_Tepe_2.jpg/1024px-Karahan_Tepe_2.jpg',
    category: 'archaeology',
  ),
  ResearchSite(
    name: 'Gunung Padang',
    badge: 'Java, Indonesien',
    founded: 'Untersuchungen seit 2011',
    description:
        'Megalith-Komplex. Geo-Radar deutet auf Pyramide unter dem Hügel. Datierung der unteren Schichten umstritten: 9.000–25.000 v.Chr.',
    status: 'Forschung umstritten',
    lat: -6.994,
    lng: 107.057,
    researchers: ['Danny Hilman Natawidjaja', 'Graham Hancock'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/3/35/Gunung_Padang_first_terrace.jpg/1024px-Gunung_Padang_first_terrace.jpg',
    category: 'archaeology',
  ),
  ResearchSite(
    name: 'Yonaguni Monument',
    badge: 'Unterwasser-Stufenstruktur',
    founded: 'Entdeckt 1986, Kihachiro Aratake',
    description:
        'Stufenförmige Felsformation 25m unter Wasser, Ryukyu-Inseln. Künstlich oder Natur — heftig debattiert.',
    status: 'Umstritten',
    lat: 24.435,
    lng: 122.940,
    researchers: ['Masaaki Kimura'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8b/Yonaguni_Ruins_Stairs.jpg/1024px-Yonaguni_Ruins_Stairs.jpg',
    category: 'archaeology',
  ),
  ResearchSite(
    name: 'Sphinx von Gizeh',
    badge: 'Sphinx',
    founded: 'Vor ~4.500 J. (offiziell) / ~12.000 J. (Schoch)',
    description:
        'Robert Schoch (Boston University) datiert wegen Wasser-Erosionsspuren auf vor 9.000+ Jahre. John Anthony West: pre-Pharaonisch.',
    status: 'Aktive Forschung',
    lat: 29.975,
    lng: 31.138,
    researchers: ['Robert Schoch', 'John Anthony West'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9c/Great_Sphinx_of_Giza_-_20080716a.jpg/1024px-Great_Sphinx_of_Giza_-_20080716a.jpg',
    category: 'archaeology',
  ),
  ResearchSite(
    name: 'Cheops-Pyramide Innenkammern',
    badge: 'ScanPyramids',
    founded: 'Scanning 2015–2017',
    description:
        'Myon-Tomographie entdeckte 2017 große verborgene Kammer ("Big Void") oberhalb der Großen Galerie. Funktion unbekannt.',
    status: 'Aktive Forschung',
    lat: 29.979,
    lng: 31.134,
    findings: ['Big Void (30m+ lange Kammer)'],
    researchers: ['Mehdi Tayoubi', 'Kunihiro Morishima'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c0/Kheops-Pyramid.jpg/1024px-Kheops-Pyramid.jpg',
    category: 'archaeology',
  ),
  ResearchSite(
    name: 'Stonehenge',
    badge: 'Megalith',
    founded: '3.000–1.500 v.Chr.',
    description:
        'Megalith-Komplex. Bluestones aus Wales (240 km Transport). Astro-Ausrichtung Sommer-Sonnenwende.',
    status: 'UNESCO Welterbe',
    lat: 51.179,
    lng: -1.826,
    researchers: ['Paul Devereux (Akustik)', 'Michael Parker Pearson'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/b/be/Stonehenge_back_wide.jpg/1024px-Stonehenge_back_wide.jpg',
    category: 'archaeology',
  ),
  ResearchSite(
    name: 'Machu Picchu',
    badge: 'Inka',
    founded: '~1450, Pachacuti',
    description:
        'Inka-Stätte über dem Urubamba-Tal. Präzisions-Steinmetzkunst ohne Mörtel. Hiram Bingham "wiederentdeckte" sie 1911.',
    status: 'UNESCO Welterbe',
    lat: -13.163,
    lng: -72.545,
    researchers: ['Hiram Bingham'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/e/eb/Machu_Picchu%2C_Peru.jpg/1024px-Machu_Picchu%2C_Peru.jpg',
    category: 'archaeology',
  ),
  ResearchSite(
    name: 'Puma Punku',
    badge: 'Tiwanaku',
    founded: '~536 n.Chr. (umstritten)',
    description:
        'Megalith-Tempel in Bolivien. H-Block-Steine mit präziser Geometrie. Erich-von-Däniken-Liebling.',
    status: 'UNESCO Welterbe',
    lat: -16.561,
    lng: -68.679,
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8d/Pumapunku_stones_2.jpg/1024px-Pumapunku_stones_2.jpg',
    category: 'archaeology',
  ),
  ResearchSite(
    name: 'Nazca-Linien',
    badge: 'Geoglyphen',
    founded: '500 v.Chr.–500 n.Chr.',
    description:
        'Geoglyphen in der Atacama. Nur aus Höhe als Gesamtbild erkennbar. Zweck umstritten (Astronomie? Rituale?).',
    status: 'UNESCO Welterbe',
    lat: -14.692,
    lng: -75.130,
    researchers: ['Maria Reiche'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Nazca_monkey.jpg/1024px-Nazca_monkey.jpg',
    category: 'archaeology',
  ),
  ResearchSite(
    name: 'Easter Island / Rapa Nui',
    badge: 'Moai',
    founded: '1.000–1.600 n.Chr.',
    description:
        '887 Moai-Statuen. Transport bis zu 20 km — wie ohne Räder? Polynesische Kultur am Rand des Kollapses.',
    status: 'UNESCO Welterbe',
    lat: -27.117,
    lng: -109.367,
    researchers: ['Terry Hunt', 'Carl Lipo'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d2/Moai_Rano_raraku.jpg/1024px-Moai_Rano_raraku.jpg',
    category: 'archaeology',
  ),
  ResearchSite(
    name: 'Newgrange',
    badge: 'Megalith Irland',
    founded: '3.200 v.Chr.',
    description:
        'Älter als Stonehenge & Cheops. Innengang erleuchtet sich präzise zur Wintersonnenwende. Spiral-Reliefs unbekannter Bedeutung.',
    status: 'UNESCO Welterbe',
    lat: 53.694,
    lng: -6.475,
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Newgrange.JPG/1024px-Newgrange.JPG',
    category: 'archaeology',
  ),
  ResearchSite(
    name: 'Gobi-Khirgisuur Komplex',
    badge: 'Bronze-Hügel',
    founded: '1.500 v.Chr.',
    description:
        'Massive Steinringe in der Mongolei. Astro-Ausrichtungen. Bronze-Zeit-Ritualkomplexe.',
    status: 'Erforscht',
    lat: 47.0,
    lng: 102.0,
    category: 'archaeology',
  ),
  ResearchSite(
    name: 'Adam\'s Calendar Südafrika',
    badge: 'Megalith Mpumalanga',
    founded: 'Datierung 75.000+ J. (umstritten, Tellinger)',
    description:
        'Steinkreis-Komplex im südlichen Afrika. Michael Tellinger datiert auf Pre-Sumerian. Mainstream-Skepsis.',
    status: 'Umstritten',
    lat: -25.683,
    lng: 30.500,
    researchers: ['Michael Tellinger'],
    category: 'archaeology',
  ),

  // ── KULTUREN / TRADITIONEN ──────────────────────────────────────
  ResearchSite(
    name: 'Heart of the Andes — Q\'ero',
    badge: 'Q\'ero',
    founded: 'Inka-Erben',
    description:
        'Direkte Inka-Nachfahren in der Cordillera Vilcanota. Bewahren Erd-Heilungs-Rituale (Pago a la Tierra). Westliche Esoterik-Begegnungen ab 1985.',
    status: 'Lebendige Tradition',
    lat: -13.5,
    lng: -71.5,
    researchers: ['Alberto Villoldo (Vier Winde)'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Q%27eros_at_Apu_Ausangate.jpg/1024px-Q%27eros_at_Apu_Ausangate.jpg',
    category: 'tradition',
  ),
  ResearchSite(
    name: 'Hopi Reservation Arizona',
    badge: 'Hopi',
    founded: 'Antike Pueblo-Kultur',
    description:
        'Hopi-Prophezeiungen. "Die Reinigung" + "Neunte Welt". Älteste durchgehende Pueblo-Tradition Nordamerikas.',
    status: 'Lebendige Tradition',
    lat: 35.890,
    lng: -110.500,
    findings: ['Hopi-Steintafeln', 'Prophezeiungs-Trommel'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6d/Walpi_Village%2C_First_Mesa.jpg/1024px-Walpi_Village%2C_First_Mesa.jpg',
    category: 'tradition',
  ),
  ResearchSite(
    name: 'Lakota Pine Ridge',
    badge: 'Lakota',
    founded: 'Antike Lakota-Tradition',
    description:
        'Black Hills sind heilig für die Lakota. Sun Dance, Vision Quest. Standing Rock 2016 als modernes Widerstands-Symbol.',
    status: 'Lebendige Tradition',
    lat: 43.027,
    lng: -102.553,
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9b/Mount_Rushmore_National_Memorial.jpg/1024px-Mount_Rushmore_National_Memorial.jpg',
    category: 'tradition',
  ),
  ResearchSite(
    name: 'Mongolian Shamans (Khövsgöl)',
    badge: 'Tengrism',
    founded: 'Vor-buddhistische Tradition',
    description:
        'Tengrist-Schamanen am Khövsgöl-See. Trance-Trommeln. Sowjet-Zeit fast ausgelöscht — Renaissance seit 1990.',
    status: 'Wiederbelebung',
    lat: 51.0,
    lng: 100.5,
    category: 'tradition',
  ),
  ResearchSite(
    name: 'Australian Aboriginal Songlines',
    badge: 'Dreamtime',
    founded: '60.000+ Jahre',
    description:
        'Älteste durchgehende Kultur der Welt. Songlines als orale Landkarten. Uluru als heiliges Zentrum.',
    status: 'Lebendige Tradition',
    lat: -25.345,
    lng: 131.036,
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/22/Uluru_Australia%28cropped%29.jpg/1024px-Uluru_Australia%28cropped%29.jpg',
    category: 'tradition',
  ),
  ResearchSite(
    name: 'Maori (Aotearoa)',
    badge: 'Maori',
    founded: '~1300 n.Chr.',
    description:
        'Polynesische Tradition. Whakapapa (Genealogie). Modernes Maori-Renaissance prägt Neuseeland-Identität.',
    status: 'Lebendige Tradition',
    lat: -38.696,
    lng: 176.070,
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Maori_Meetinghouse_-_Te_Hau_ki_Turanga.jpg/1024px-Maori_Meetinghouse_-_Te_Hau_ki_Turanga.jpg',
    category: 'tradition',
  ),
  ResearchSite(
    name: 'San Bushmen Kalahari',
    badge: 'San',
    founded: 'Älteste menschliche Linie',
    description:
        'Genetisch älteste durchgehende menschliche Population. Tranceheilungs-Tänze. Animistische Weltsicht.',
    status: 'Bedroht',
    lat: -23.0,
    lng: 22.0,
    category: 'tradition',
  ),
  ResearchSite(
    name: 'Shipibo-Conibo Amazonien',
    badge: 'Shipibo',
    founded: 'Ucayali, Peru',
    description:
        'Pflanzenmedizin-Tradition (Ayahuasca). Heilige Geometrien als gewebte Muster. Modernes Mekka des "Ayahuasca-Tourismus".',
    status: 'Lebendige Tradition',
    lat: -8.378,
    lng: -74.541,
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Shipibo_kene_design.jpg/1024px-Shipibo_kene_design.jpg',
    category: 'tradition',
  ),
  ResearchSite(
    name: 'Tibetan Buddhism Lhasa',
    badge: 'Vajrayana',
    founded: '7. Jh. n.Chr.',
    description:
        'Potala-Palast. Bardo-Lehren, Reinkarnations-System. Seit 1959 Dalai Lama im Exil.',
    status: 'Bedroht',
    lat: 29.658,
    lng: 91.117,
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/3/30/Potala_Palace_2020.jpg/1024px-Potala_Palace_2020.jpg',
    category: 'tradition',
  ),
  ResearchSite(
    name: 'Mount Athos',
    badge: 'Orthodoxe Tradition',
    founded: '963 n.Chr.',
    description:
        'Halbinsel-Mönchstaat. 20 Klöster. Hesychasmus-Tradition (Jesus-Gebet). Frauen verboten.',
    status: 'Lebendige Tradition',
    lat: 40.250,
    lng: 24.250,
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d8/Mt._Athos_atop_Mount_Athos.JPG/1024px-Mt._Athos_atop_Mount_Athos.JPG',
    category: 'tradition',
  ),
  ResearchSite(
    name: 'Varanasi Ghats',
    badge: 'Kashi',
    founded: '11. Jh. v.Chr.',
    description:
        'Älteste durchgehend bewohnte Stadt Indiens. Brennghats am Ganges. Sterbe-Ort, der Moksha (Befreiung) verspricht.',
    status: 'Lebendige Tradition',
    lat: 25.319,
    lng: 83.012,
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Varanasi_ghat.jpg/1024px-Varanasi_ghat.jpg',
    category: 'tradition',
  ),

  // ── CYMATICS / FREQUENZ ─────────────────────────────────────────
  ResearchSite(
    name: 'CymaScope Lab',
    badge: 'Cymatics',
    founded: 'John Stuart Reid',
    description:
        'Cymatik-Forschung: Visualisierung von Klang als geometrische Muster in Flüssigkeiten. Wassermembran-Apparatur.',
    status: 'Aktiv',
    lat: 51.5,
    lng: -0.1,
    findings: ['Schumann-Visualisierungen', 'Sprach-Cymatik'],
    researchers: ['John Stuart Reid'],
    category: 'cymatics',
  ),

  // ── BEWUSSTSEINS-ARCHIVE ────────────────────────────────────────
  ResearchSite(
    name: 'Vatikanische Geheimarchive',
    badge: 'Archivum Apostolicum',
    founded: '17. Jh.',
    description:
        '85 km Regale. 1881 für Forscher (teil-)geöffnet. Akten zu Galileo, Templern, Hexenprozessen.',
    status: 'Teil-zugänglich',
    lat: 41.905,
    lng: 12.453,
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/Vatican_Library_old_books.jpg/1024px-Vatican_Library_old_books.jpg',
    category: 'archaeology',
  ),
  ResearchSite(
    name: 'Akashic Records Conference',
    badge: 'Akasha',
    founded: 'Theosophische Tradition',
    description:
        '"Lebensbuch" — kosmischer Speicher allen Wissens. Edgar Cayce trance-channelte angeblich daraus. Modern bei Linda Howe.',
    status: 'Esoterische Lehre',
    lat: 36.0,
    lng: -86.0,
    researchers: ['Edgar Cayce', 'Linda Howe'],
    category: 'consciousness',
  ),
  ResearchSite(
    name: 'NDE Research Foundation',
    badge: 'NDERF',
    founded: '1998, Jeffrey Long',
    description:
        'Sammelt Near-Death-Experience-Berichte weltweit. 5000+ dokumentierte NDEs. Statistische Muster-Analyse.',
    status: 'Aktiv',
    lat: 30.4,
    lng: -91.1,
    findings: ['Cross-Cultural NDE-Konsistenz'],
    researchers: ['Jeffrey Long'],
    category: 'consciousness',
  ),
  ResearchSite(
    name: 'University of Virginia Medical Center NDE Studies',
    badge: 'UVA NDE',
    founded: 'Bruce Greyson',
    description:
        'Greyson-NDE-Skala. Peer-reviewed Studien zu Bewusstsein-bei-klinischem-Tod.',
    status: 'Aktiv',
    lat: 38.032,
    lng: -78.501,
    researchers: ['Bruce Greyson'],
    category: 'consciousness',
  ),
  ResearchSite(
    name: 'Esalen Institute',
    badge: 'Esalen',
    founded: '1962, Big Sur',
    description:
        'Geburtsort des Human-Potential-Movement. Gestalttherapie, Sensitivitäts-Training, frühe Psychedelika-Forschung. Heißen Quellen.',
    status: 'Aktiv',
    lat: 36.121,
    lng: -121.640,
    researchers: ['Abraham Maslow', 'Fritz Perls', 'Stanislav Grof'],
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Esalen_Institute_2007_3.jpg/1024px-Esalen_Institute_2007_3.jpg',
    category: 'consciousness',
  ),
  ResearchSite(
    name: 'Findhorn Foundation',
    badge: 'Findhorn',
    founded: '1962, Scotland',
    description:
        'Spirituelle Eco-Community. Devic-Gärten — riesige Gemüse "gewachsen durch Kommunikation mit Naturgeistern".',
    status: 'Aktiv',
    lat: 57.654,
    lng: -3.610,
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Findhorn_Foundation_logo.svg/640px-Findhorn_Foundation_logo.svg.png',
    category: 'consciousness',
  ),
];
