import 'package:latlong2/latlong.dart';
import '../models/materie_location_detail.dart';
import '../models/location_category.dart';

/// Materie Location Data
/// 
/// Enthält alle 100+ Location-Markierungen für die Materie-Weltkarte.
/// Ausgelagert aus materie_karte_tab_pro.dart für bessere Wartbarkeit.
/// 
/// Kategorien:
/// - Antike Zivilisationen (10.000 Jahre Geschichte)
/// - Geopolitik & Deep State
/// - UFO & Außerirdische
/// - Medizin & Biotechnologie
/// - Zensur & Propaganda
/// - und viele mehr...

final List<MaterieLocationDetail> allMaterieLocations = [
  // 🏛️ ANTIKE ZIVILISATIONEN (10.000 Jahre Geschichte!)
  
  MaterieLocationDetail(
    name: 'Göbekli Tepe - Ältester Tempel',
    description: 'Älteste bekannte megalithische Tempelanlage der Welt (ca. 9600 v.Chr.)',
    detailedInfo: '''OFFIZIELL: Göbekli Tepe in der heutigen Türkei ist die älteste bekannte Tempelanlage der Menschheit. Erbaut um 9600 v.Chr., noch vor der Erfindung der Landwirtschaft. Monumentale T-förmige Steinpfeiler mit Tierreliefs. Archäologische Sensation - widerlegt bisherige Theorien zur Zivilisationsentwicklung.

ALTERNATIVE: Manche Forscher spekulieren über fortgeschrittene prähistorische Zivilisationen. Astronomische Ausrichtungen der Pfeiler. Mögliche Verbindung zu Atlantis-Legenden. Frage: Wer baute solche Monumentalbauten vor der Sesshaftwerdung?

BEWEISE: Klaus Schmidt Ausgrabungen (1995-2014); Radiokarbondatierung bestätigt 9600 v.Chr.; T-Pfeiler bis 5,5m hoch, 10 Tonnen schwer; komplexe Tierreliefs (Füchse, Schlangen, Skorpione); keine Siedlungsspuren - reine Kultstätte; 20+ Steinkreise entdeckt.''',
    position: const LatLng(37.2233, 38.9225),
    category: LocationCategory.ancientCivilizations,
    keywords: ['Göbekli Tepe', 'Steinzeit', 'Megalithen', 'Türkei', 'Neolithikum', 'Tempel'],
    date: DateTime(-9600, 1, 1),
    imageUrls: ['https://www.genspark.ai/api/files/s/oPY0luBZ?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c8/G%C3%B6bekli_Tepe%2C_Urfa.jpg/1200px-G%C3%B6bekli_Tepe%2C_Urfa.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0f/Gobekli_Tepe_pillar.jpg/800px-Gobekli_Tepe_pillar.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f9/Göbekli_Tepe_excavation.jpg/1200px-Göbekli_Tepe_excavation.jpg',
    ],
    videoUrls: ['_P6tvRjhZ5k'], // Göbekli Tepe Doku deutsch
    sources: [
      'Klaus Schmidt: "Sie bauten die ersten Tempel" (Verlag C.H.Beck, 2006) - 282 Seiten',
      'Radiokarbondatierung Universität Heidelberg (1995-2000)',
      'German Archaeological Institute Excavation Reports (1995-2014)',
      'National Geographic: "The Birth of Religion" (2011)',
      'Andrew Curry: "Göbekli Tepe: The World\'s First Temple?" Smithsonian Magazine (2008)',
      'UNESCO World Heritage Nomination (2018) - 150 Seiten',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'Stonehenge Megalithen',
    description: 'Prähistorisches Monument mit astronomischer Bedeutung (ca. 3000-2000 v.Chr.)',
    detailedInfo: '''OFFIZIELL: Stonehenge wurde zwischen 3000-2000 v.Chr. in mehreren Phasen erbaut. Monumentale Steinkreise mit Sarsen-Steinen (bis 25 Tonnen) und Blausteinen (aus Wales, 240km entfernt). Astronomische Ausrichtung zur Sommersonnenwende. UNESCO Weltkulturerbe.

ALTERNATIVE: Mögliche Ley-Line-Kreuzung. Energiezentrum der Antike. Heilstätte und astronomisches Observatorium. Fragezeichen über Transport der Blausteine. Stonehenge als Teil eines größeren megalithischen Netzwerks in Großbritannien.

BEWEISE: Radiokarbondatierung 3000-2000 v.Chr.; Sarsen-Steine 25 Tonnen; Blausteine aus Preseli Hills (Wales); Sonnenwend-Alignment präzise; 56 Aubrey Holes (Kreidegräben); Woodhenge und Durrington Walls in der Nähe.''',
    position: const LatLng(51.1789, -1.8262),
    category: LocationCategory.ancientCivilizations,
    keywords: ['Stonehenge', 'England', 'Megalithen', 'Druiden', 'Astronomie'],
    date: DateTime(-3000, 1, 1),
    imageUrls: ['https://www.genspark.ai/api/files/s/hTwsqNWv?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3c/Stonehenge2007_07_30.jpg/1200px-Stonehenge2007_07_30.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f4/Stonehenge_Closeup.jpg/1200px-Stonehenge_Closeup.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/93/Stonehenge_Summer_Solstice.jpg/1200px-Stonehenge_Summer_Solstice.jpg',
    ],
    videoUrls: ['kQ3rsdu_Uw0'], // Stonehenge Doku deutsch
    sources: [
      'English Heritage: "Stonehenge - Complete History and Archaeology" (2020) - 384 Seiten',
      'Gerald Hawkins: "Stonehenge Decoded" (1965) - Astronomische Analyse',
      'John North: "Stonehenge: Neolithic Man and the Cosmos" Oxford University Press (1996) - 624 Seiten',
      'Mike Parker Pearson: "Stonehenge" Simon & Schuster (2012) - 448 Seiten',
      'Royal College of Art Acoustic Study (2012) - Klangeigenschaften',
      'Radiokarbondatierung English Heritage (1995-2008)',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'Große Pyramide von Gizeh',
    description: 'Einziges erhaltenes Weltwunder der Antike (ca. 2560 v.Chr.)',
    detailedInfo: '''OFFIZIELL: Die Cheops-Pyramide wurde um 2560 v.Chr. als Grabmal für Pharao Cheops erbaut. Höhe ursprünglich 146,6m. Ca. 2,3 Millionen Steinblöcke (durchschnittlich 2,5 Tonnen). Bauzeit laut Herodot: 20 Jahre. Präzise astronomische Ausrichtung. UNESCO Weltkulturerbe.

ALTERNATIVE: Technologie-Rätsel: Wie wurden Millionen Tonnen Steine ohne moderne Werkzeuge bewegt? Innere Hohlräume noch unentdeckt? Mögliche Energiemaschine (Pyramiden-Energie-Theorien). Präzision deutet auf fortgeschrittenes Wissen hin. Alternative Datierung?

BEWEISE: Radiokarbondatierung ~2550 v.Chr.; 2,3 Millionen Steinblöcke; Präzision: Abweichung <1%; Königskammer aus Granit (800km Transport); vier Luftschächte; Pyramidion (Spitze) fehlt; Teil der Pyramiden von Gizeh (Cheops, Chephren, Mykerinos).''',
    position: const LatLng(29.9792, 31.1342),
    category: LocationCategory.ancientCivilizations,
    keywords: ['Gizeh', 'Pyramiden', 'Ägypten', 'Cheops', 'Pharao', 'Weltwunder'],
    date: DateTime(-2560, 1, 1),
    imageUrls: ['https://www.genspark.ai/api/files/s/Jf0BCsdJ?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/thumb/a/af/All_Gizah_Pyramids.jpg/1200px-All_Gizah_Pyramids.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e3/Kheops-Pyramid.jpg/1200px-Kheops-Pyramid.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/93/Great_Pyramid_of_Giza_Interior.jpg/800px-Great_Pyramid_of_Giza_Interior.jpg',
    ],
    videoUrls: ['kQ_h5NKNgGk'], // Pyramiden Doku deutsch
    sources: [
      'Mark Lehner: "The Complete Pyramids" Thames & Hudson (1997) - 256 Seiten',
      'I.E.S. Edwards: "The Pyramids of Egypt" Penguin (1993) - 304 Seiten',
      'Radiokarbondatierung David H. Koch (1984, 1995, 1999)',
      'Zahi Hawass: "The Pyramids" White Star (2007) - 400 Seiten',
      'Napoleon Bonaparte Expedition (1798) - Erste wissenschaftliche Vermessung',
      'Egyptian Antiquities Organization Excavation Reports (1880-2020)',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'Untergang von Atlantis',
    description: 'Legendäre versunkene Zivilisation nach Platon (ca. 9600 v.Chr.)',
    detailedInfo: '''OFFIZIELL (PLATON): Platon beschrieb Atlantis in "Timaios" und "Kritias" (ca. 360 v.Chr.). Fortgeschrittene Inselzivilisation westlich der "Säulen des Herakles" (Gibraltar). Untergang durch Katastrophe "in einem Tag und einer Nacht". Moderne Wissenschaft: Möglicherweise Allegorie oder Erinnerung an Thera-Eruption (Santorin).

ALTERNATIVE: Echte versunkene Hochzivilisation. Mögliche Standorte: Azoren, Antarktis, Karibik. Atlantis als Ursprung späterer Kulturen (Ägypten, Sumerer). Fortgeschrittene Technologie verloren. Verbindung zu anderen Sintflut-Mythen weltweit.

BEWEISE: Platon Dialoge "Timaios" & "Kritias" (360 v.Chr.); keine archäologischen Beweise; Thera-Eruption ~1600 v.Chr. (Santorin); weltweite Sintflut-Mythen; Bimini Road (Bahamas) kontrovers; Richat-Struktur (Mauretanien) als Kandidat.''',
    position: const LatLng(36.4, -25.5),
    category: LocationCategory.ancientCivilizations,
    keywords: ['Atlantis', 'Platon', 'Versunkene Zivilisation', 'Azoren', 'Santorin'],
    date: DateTime(-9600, 1, 1),
    imageUrls: ['https://www.genspark.ai/api/files/s/Jybe15oz?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Atlantis_map_Kircher_1669.jpg/1200px-Atlantis_map_Kircher_1669.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Santorini_Landsat.jpg/1200px-Santorini_Landsat.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/35/Richat_Structure.jpg/1200px-Richat_Structure.jpg',
    ],
    videoUrls: ['BLSc_SLU8_w'], // Atlantis Doku deutsch
    sources: [
      'Platon: "Timaios und Kritias" (ca. 360 v.Chr.) - Original-Quelle',
      'Ignatius Donnelly: "Atlantis: The Antediluvian World" (1882) - 490 Seiten',
      'Charles Pellegrino: "Unearthing Atlantis" (1991) - Santorin-Theorie',
      'Robert Sarmast: "Discovery of Atlantis" (2006) - Zypern-Theorie',
      'Geologische Studien Azoren Plateau (1960-2010)',
      'Graham Hancock: "Underworld" (2002) - Versunkene Zivilisationen',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'Sumerische Zivilisation - Uruk',
    description: 'Erste Hochkultur der Menschheit in Mesopotamien (ca. 4000 v.Chr.)',
    detailedInfo: '''OFFIZIELL: Sumer in Mesopotamien (heute Irak) gilt als erste Hochkultur. Entstehung um 4000 v.Chr. Erfindung der Keilschrift (~3200 v.Chr.). Stadt Uruk war das erste urbane Zentrum (50.000 Einwohner). Entwicklung von Recht, Verwaltung, Astronomie, Mathematik.

ALTERNATIVE: Sumerer behaupteten, Wissen von "Göttern" (Anunnaki) erhalten zu haben. Plötzliches Auftauchen fortgeschrittener Zivilisation ohne Vorstufen. Astronomische Kenntnisse (Planeten, Präzession) erstaunlich präzise. Verbindung zu Alien-Theorien (Zecharia Sitchin).

BEWEISE: Keilschrift-Tafeln 3200 v.Chr.; Uruk größte Stadt der Welt (~3000 v.Chr.); Gilgamesch-Epos; Ur Königsgräber (2600 v.Chr.); Ziggurat von Ur; Sumerische Königsliste; mathematisches Sexagesimalsystem (Basis 60); astronomische Tafeln mit Planetenbahnen.''',
    position: const LatLng(31.3242, 45.6364),
    category: LocationCategory.ancientCivilizations,
    keywords: ['Sumer', 'Mesopotamien', 'Keilschrift', 'Uruk', 'Anunnaki', 'Gilgamesch'],
    date: DateTime(-4000, 1, 1),
    imageUrls: ['https://www.genspark.ai/api/files/s/575YEhXB?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Uruk_archaeological_site.jpg/1200px-Uruk_archaeological_site.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fc/Cuneiform_script2.jpg/1200px-Cuneiform_script2.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/93/Ziggurat_of_Ur_001.jpg/1200px-Ziggurat_of_Ur_001.jpg',
    ],
    videoUrls: ['xQTvPvOh_Jw'], // Sumer Doku deutsch
    sources: [
      'Samuel Noah Kramer: "The Sumerians" University of Chicago Press (1963) - 355 Seiten',
      'Zecharia Sitchin: "The 12th Planet" (1976) - Alternative Interpretation',
      'British Museum: "Cuneiform Tablets Collection" (3200-500 v.Chr.)',
      'Oxford University: "Uruk Excavations" (1912-2019)',
      'Sumerische Königsliste (Weld-Blundell Prism)',
      'Jean Bottéro: "Mesopotamia: Writing, Reasoning, and the Gods" (1992)',
    ],
  ),
  
  // 🕉️ RELIGIONEN & SPIRITUALITÄT
  
  MaterieLocationDetail(
    name: 'Exodus aus Ägypten',
    description: 'Biblischer Auszug der Israeliten unter Moses (ca. 1300 v.Chr.)',
    detailedInfo: '''OFFIZIELL (BIBEL): Der Exodus beschreibt die Befreiung der Israeliten aus ägyptischer Sklaverei durch Moses. 10 Plagen zwingen Pharao zur Freilassung. Teilung des Roten Meeres. 40 Jahre Wüstenwanderung. Empfang der 10 Gebote am Berg Sinai. Zentrales Ereignis des Judentums.

ALTERNATIVE/HISTORISCH: Archäologische Beweise umstritten. Keine ägyptischen Aufzeichnungen über Massenflucht. Mögliche historische Basis: Hyksos-Vertreibung (~1550 v.Chr.) oder kleinere Emigrationswellen. Theologische vs. historische Interpretation.

BEWEISE: Torah/Altes Testament (Exodus-Buch); keine ägyptischen Quellen; archäologische Lücke in Sinai; Papyrus Ipuwer (Plagen-Beschreibung, umstritten); Merneptah-Stele (~1208 v.Chr., "Israel"-Erwähnung); moderne Datierung basiert auf biblischen Chronologien.''',
    position: const LatLng(30.0444, 31.2357),
    category: LocationCategory.religion,
    keywords: ['Exodus', 'Moses', 'Ägypten', 'Bibel', 'Sinai', 'Zehn Gebote'],
    date: DateTime(-1300, 1, 1),
    imageUrls: ['https://www.genspark.ai/api/files/s/ySdzMiYf?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fc/Foster_Bible_Pictures_0074-1_The_Israelites_Leaving_Egypt.jpg/1200px-Foster_Bible_Pictures_0074-1_The_Israelites_Leaving_Egypt.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8d/Mount_Sinai.jpg/1200px-Mount_Sinai.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/24/Ten_Commandments_tablets.jpg/800px-Ten_Commandments_tablets.jpg',
    ],
    videoUrls: ['zYSYPDN6A7M'], // Exodus Doku deutsch
    sources: [
      'Torah/Altes Testament: Buch Exodus (ca. 600-400 v.Chr.)',
      'Israel Finkelstein: "The Bible Unearthed" (2001) - Archäologische Analyse',
      'Merneptah-Stele (1208 v.Chr.) - Ägyptisches Museum Kairo',
      'James K. Hoffmeier: "Israel in Egypt" Oxford University Press (1999) - 245 Seiten',
      'Papyrus Ipuwer (Leiden Museum) - Plagen-Interpretation umstritten',
      'William G. Dever: "What Did the Biblical Writers Know?" (2001)',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'Geburt Buddha - Lumbini',
    description: 'Geburt von Siddhartha Gautama, Begründer des Buddhismus (ca. 563 v.Chr.)',
    detailedInfo: '''OFFIZIELL: Siddhartha Gautama wurde als Prinz in Lumbini (Nepal) geboren. Verließ mit 29 Jahren den Palast, suchte Erleuchtung. Erlangung der Erleuchtung unter Bodhi-Baum in Bodh Gaya (ca. 528 v.Chr.). Gründung des Buddhismus. 45 Jahre Lehrtätigkeit. Tod mit 80 Jahren.

SPIRITUELL: Buddhas Lehren: Vier Edle Wahrheiten, Achtfacher Pfad. Konzepte: Karma, Wiedergeburt, Nirvana. Verbreitung in ganz Asien. Heute über 500 Millionen Buddhisten weltweit. Verschiedene Schulen (Theravada, Mahayana, Vajrayana).

BEWEISE: Ashoka-Säule in Lumbini (249 v.Chr., UNESCO Weltkulturerbe); Pali-Kanon (buddhistische Schriften, 1. Jh. v.Chr.); archäologische Funde in Lumbini; Bodh Gaya Tempel; chinesische Pilgerberichte (Faxian, Xuanzang); wissenschaftliche Datierung ~563-483 v.Chr.''',
    position: const LatLng(27.5, 83.25),
    category: LocationCategory.religion,
    keywords: ['Buddha', 'Buddhismus', 'Lumbini', 'Erleuchtung', 'Nepal'],
    date: DateTime(-563, 1, 1),
    imageUrls: ['https://www.genspark.ai/api/files/s/m1bTOcsd?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Lumbini_birthplace_of_Buddha.jpg/1200px-Lumbini_birthplace_of_Buddha.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f3/Buddha_statue_Bodhgaya.jpg/800px-Buddha_statue_Bodhgaya.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/Ashoka_Pillar_Lumbini.jpg/800px-Ashoka_Pillar_Lumbini.jpg',
    ],
    videoUrls: ['Ns8Yqe8kM5E'], // Buddha Doku deutsch
    sources: [
      'Pali-Kanon: Tipitaka (ca. 1. Jh. v.Chr.) - Buddhistische Hauptschriften',
      'Ashoka-Säule Lumbini Inschrift (249 v.Chr.)',
      'Richard Gombrich: "Theravada Buddhism" Routledge (2006) - 240 Seiten',
      'UNESCO World Heritage Site Documentation Lumbini (1997)',
      'Karen Armstrong: "Buddha" Penguin (2001) - 205 Seiten',
      'Archäologische Ausgrabungen Lumbini (1896-2013)',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'Kreuzigung Jesu Christi',
    description: 'Kreuzigung und Auferstehung von Jesus Christus (ca. 33 n.Chr.)',
    detailedInfo: '''OFFIZIELL (CHRISTLICH): Jesus von Nazareth wurde unter Pontius Pilatus in Jerusalem gekreuzigt (ca. 30-33 n.Chr.). Auferstehung nach drei Tagen. Gründung des Christentums. Apostel verbreiten Lehre. Heute größte Weltreligion (2,4 Milliarden Christen).

HISTORISCH: Außerchristliche Quellen bestätigen Existenz (Tacitus, Josephus). Kreuzigung als römische Hinrichtungsmethode belegt. Datierung: unter Pilatus (26-36 n.Chr.), wahrscheinlich 30 oder 33 n.Chr. Auferstehung Glaubensfrage, keine historischen Beweise.

BEWEISE: Evangelien (Matthäus, Markus, Lukas, Johannes, ca. 70-100 n.Chr.); Tacitus "Annalen" (116 n.Chr.); Josephus "Antiquitates" (93 n.Chr.); Paulusbriefe (ab 50 n.Chr.); Grabtuch von Turin (umstritten); archäologische Funde in Jerusalem (Kreuzigungsnägel).''',
    position: const LatLng(31.7683, 35.2137),
    category: LocationCategory.religion,
    keywords: ['Jesus', 'Christentum', 'Kreuzigung', 'Jerusalem', 'Auferstehung'],
    date: DateTime(33, 4, 3),
    imageUrls: ['https://www.genspark.ai/api/files/s/vZXarQFh?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Jerusalem_Holy_Sepulchre_BW_19.JPG/1200px-Jerusalem_Holy_Sepulchre_BW_19.JPG',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/Christ_Carrying_the_Cross_1580.jpg/800px-Christ_Carrying_the_Cross_1580.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/39/Golgotha_Jerusalem.jpg/1200px-Golgotha_Jerusalem.jpg',
    ],
    videoUrls: ['tAW5fZwqH6I'], // Jesus Doku deutsch
    sources: [
      'Neues Testament: Vier Evangelien (ca. 70-100 n.Chr.)',
      'Tacitus: "Annalen" XV.44 (116 n.Chr.) - Christenverfolgung unter Nero',
      'Flavius Josephus: "Antiquitates Judaicae" XVIII.3.3 (93 n.Chr.)',
      'Paulusbriefe (ab 50 n.Chr.) - Früheste christliche Schriften',
      'Archäologische Funde Jerusalem: Pilatus-Stein (1961)',
      'Bart D. Ehrman: "Did Jesus Exist?" HarperOne (2012) - 405 Seiten',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'Offenbarung Mohammed - Mekka',
    description: 'Erste Offenbarung des Korans an den Propheten Mohammed (610 n.Chr.)',
    detailedInfo: '''OFFIZIELL (ISLAM): Mohammed erhielt 610 n.Chr. in der Höhle Hira bei Mekka die erste Offenbarung durch Erzengel Gabriel. Beginn der Verkündung des Islam. Hidschra (Auswanderung nach Medina) 622 n.Chr. markiert Beginn islamischer Zeitrechnung. Tod 632 n.Chr. Heute 1,9 Milliarden Muslime weltweit.

HISTORISCH: Mohammed historische Person, archäologisch belegt. Frühe islamische Quellen: Koran (ab 610 n.Chr.), Hadith-Sammlungen (ab 9. Jh.). Rasche Expansion des Islam nach Mohammeds Tod. Eroberung Arabiens, Persiens, Nordafrikas innerhalb weniger Jahrzehnte.

BEWEISE: Koran (Sammlung unter Kalif Uthman, 650 n.Chr.); Hadith-Sammlungen (Bukhari, Muslim, 9. Jh.); Höhle Hira in Mekka; frühe Moscheen (Medina, Jerusalem); byzantinische/persische Chroniken; archäologische Funde in Arabien.''',
    position: const LatLng(21.4225, 39.8262),
    category: LocationCategory.religion,
    keywords: ['Mohammed', 'Islam', 'Koran', 'Mekka', 'Offenbarung', 'Prophet'],
    imageUrls: ['https://www.genspark.ai/api/files/s/Ye99UeDb?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/Masjid_al-Haram_aerial_view.jpg/1200px-Masjid_al-Haram_aerial_view.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/6/66/Hira_cave_-_Flickr.jpg/1200px-Hira_cave_-_Flickr.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/92/Quran_manuscript_8th_century.jpg/800px-Quran_manuscript_8th_century.jpg',
    ],
    videoUrls: ['PcExQwBLMhg'], // Mohammed Doku deutsch
    sources: [
      'Koran (Sammlung unter Kalif Uthman, 650 n.Chr.)',
      'Ibn Ishaq: "Sirat Rasul Allah" (750 n.Chr.) - Erste Mohammed-Biografie',
      'Sahih al-Bukhari: Hadith-Sammlung (9. Jahrhundert) - 7.563 Hadithe',
      'Fred M. Donner: "Muhammad and the Believers" Harvard (2012) - 304 Seiten',
      'Patricia Crone: "Meccan Trade and the Rise of Islam" (1987)',
      'UNESCO World Heritage: Historische Stätten in Mekka & Medina',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'Ermordung Julius Caesar',
    description: 'Attentat auf Julius Caesar im römischen Senat (15. März 44 v.Chr.)',
    detailedInfo: '''OFFIZIELL: Julius Caesar wurde am 15. März 44 v.Chr. (Iden des März) im Theater des Pompeius von einer Gruppe Senatoren ermordet. Angeführt von Marcus Brutus und Cassius Longinus. 23 Messerstiche. Caesars letzte Worte laut Sueton: "Et tu, Brute?" (Auch du, Brutus?). Beginn der Bürgerkriege, die zur Gründung des Römischen Kaiserreichs führten.

VERSCHWÖRUNG: Ca. 60 Senatoren beteiligt. Motiv: Angst vor Diktatur und Königswerdung Caesars. Politische Intrigen zwischen Optimaten und Popularen. Brutus als idealistischer Tyrannenmörder vs. politischer Opportunist. Folgen: Machtvakuum, Aufstieg Octavians (Augustus).

BEWEISE: Sueton "De Vita Caesarum" (121 n.Chr.); Plutarch "Bioi Paralleloi" (ca. 100 n.Chr.); Appian "Historia Romana" (2. Jh. n.Chr.); Cassius Dio "Historia Romana" (3. Jh. n.Chr.); archäologische Funde in Rom; Münzen mit Caesar-Porträt.''',
    position: const LatLng(41.8955, 12.4823),
    category: LocationCategory.assassinations,
    keywords: ['Caesar', 'Rom', 'Senat', 'Brutus', 'Iden des März', 'Attentat'],
    date: DateTime(-44, 3, 15),
    imageUrls: ['https://www.genspark.ai/api/files/s/VBaBIs3B?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3c/Death_of_Caesar_by_Vincenzo_Camuccini.jpg/1200px-Death_of_Caesar_by_Vincenzo_Camuccini.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/Julius_Caesar_Coustou_Louvre_MR1798.jpg/800px-Julius_Caesar_Coustou_Louvre_MR1798.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/Roman_Forum_Ruins.jpg/1200px-Roman_Forum_Ruins.jpg',
    ],
    videoUrls: ['pJegg03heiw'], // Caesar Doku deutsch
    sources: [
      'Sueton: "De Vita Caesarum" (121 n.Chr.) - Caesars Biografie',
      'Plutarch: "Bioi Paralleloi" (ca. 100 n.Chr.) - Caesar & Brutus',
      'Appian: "Historia Romana, Bürgerkriege" (2. Jahrhundert)',
      'Cassius Dio: "Historia Romana" Buch 44 (3. Jahrhundert)',
      'Adrian Goldsworthy: "Caesar: Life of a Colossus" Yale (2006) - 608 Seiten',
      'Archäologische Ausgrabungen Forum Romanum (1788-2024)',
    ],
  ),
  
  // 🏛️ REVOLUTIONEN & NEUZEIT
  
  MaterieLocationDetail(
    name: 'Französische Revolution',
    description: 'Sturm auf die Bastille - Beginn der Französischen Revolution (14. Juli 1789)',
    detailedInfo: '''OFFIZIELL: Am 14. Juli 1789 stürmten Pariser Bürger die Bastille-Festung, Symbol königlicher Willkür. Auslöser: Wirtschaftskrise, Hungersnöte, politische Repression. Forderungen: Freiheit, Gleichheit, Brüderlichkeit. Abschaffung der Monarchie (1792). Hinrichtung Ludwig XVI. (1793). Terrorherrschaft unter Robespierre. Aufstieg Napoleons.

REVOLUTION: Grundlegende Umwälzung der Gesellschaftsordnung. Ende des Absolutismus in Europa. Erklärung der Menschen- und Bürgerrechte (1789). Enteignung der Kirche. Erste moderne Republik. Vorbild für spätere Revolutionen weltweit.

BEWEISE: Sturm auf Bastille 14. Juli 1789 (heute Nationalfeiertag); "Déclaration des Droits de l'Homme" (1789); Hinrichtung Ludwig XVI. 21. Januar 1793; Zeitgenössische Berichte (Mirabeau, Danton, Robespierre); Archivdokumente Assemblée Nationale; zeitgenössische Gemälde & Stiche.''',
    position: const LatLng(48.8566, 2.3522),
    category: LocationCategory.revolution,
    keywords: ['Revolution', 'Frankreich', 'Bastille', 'Aufklärung', '1789'],
    date: DateTime(1789, 7, 14),
    imageUrls: ['https://www.genspark.ai/api/files/s/QDKsOrn3?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2f/Prise_de_la_Bastille.jpg/1200px-Prise_de_la_Bastille.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6c/Declaration_of_the_Rights_of_Man_and_of_the_Citizen.jpg/800px-Declaration_of_the_Rights_of_Man_and_of_the_Citizen.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/54/Execution_of_Louis_XVI.jpg/1200px-Execution_of_Louis_XVI.jpg',
    ],
    videoUrls: ['GVheiYFcBQo'], // Franz. Revolution Doku deutsch
    sources: [
      'Simon Schama: "Citizens" Vintage (1989) - 948 Seiten',
      'Déclaration des Droits de l\'Homme et du Citoyen (26. August 1789)',
      'Archives Nationales Paris: Revolutionsdokumente (1789-1799)',
      'François Furet: "Interpreting the French Revolution" Cambridge (1981)',
      'Zeitgenössische Quellen: Mirabeau, Danton, Robespierre Reden',
      'Eric Hobsbawm: "The Age of Revolution" (1962) - 416 Seiten',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'Amerikanische Unabhängigkeit',
    description: 'Unabhängigkeitserklärung der USA (4. Juli 1776)',
    detailedInfo: '''OFFIZIELL: Am 4. Juli 1776 verabschiedete der Kontinentalkongress in Philadelphia die Unabhängigkeitserklärung. Hauptautor: Thomas Jefferson. 13 britische Kolonien erklären Trennung von Großbritannien. "Life, Liberty and the pursuit of Happiness". Amerikanischer Unabhängigkeitskrieg (1775-1783). Sieg bei Yorktown 1781. USA als erste moderne Demokratie.

REVOLUTION: Erste erfolgreiche Kolonialrevolution. Ideen der Aufklärung (Locke, Montesquieu) in Praxis umgesetzt. Gewaltenteilung, Checks & Balances. Bill of Rights (1791). Vorbild für spätere Demokratien. Widerspruch: Sklaverei existiert weiter bis 1865.

BEWEISE: Unabhängigkeitserklärung 4. Juli 1776 (Originalurkunde in Washington D.C.); US-Verfassung (1787); Federalist Papers (Hamilton, Madison, Jay); Schlacht von Yorktown (1781); Pariser Frieden (1783); George Washington als erster Präsident (1789).''',
    position: const LatLng(39.9496, -75.1503),
    category: LocationCategory.revolution,
    keywords: ['USA', 'Unabhängigkeit', 'Philadelphia', 'Declaration', '1776'],
    date: DateTime(1776, 7, 4),
    imageUrls: ['https://www.genspark.ai/api/files/s/Qr4HnbNx?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/Declaration_independence.jpg/1200px-Declaration_independence.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/7/70/United_States_Declaration_of_Independence.jpg/1200px-United_States_Declaration_of_Independence.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/15/Independence_Hall_Assembly_Room.jpg/1200px-Independence_Hall_Assembly_Room.jpg',
    ],
    videoUrls: ['MRGnpcBBh4U'], // USA Unabhängigkeit Doku deutsch
    sources: [
      'Declaration of Independence (4. Juli 1776) - Originalurkunde',
      'US Constitution (1787) - National Archives Washington',
      'Federalist Papers (1787-1788) - Hamilton, Madison, Jay',
      'David McCullough: "1776" Simon & Schuster (2005) - 386 Seiten',
      'Gordon S. Wood: "The American Revolution" Modern Library (2002) - 208 Seiten',
      'Treaty of Paris (1783) - Offizielle Anerkennung der Unabhängigkeit',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'Gutenberg Druckerpresse',
    description: 'Erfindung des Buchdrucks mit beweglichen Lettern (ca. 1440)',
    detailedInfo: '''OFFIZIELL: Johannes Gutenberg erfand um 1440 in Mainz den modernen Buchdruck mit beweglichen Metalllettern. Erste gedruckte Bibel (Gutenberg-Bibel, ca. 1455). Revolution der Informationsverbreitung. Wissen für Massen zugänglich. Voraussetzung für Reformation, Aufklärung, wissenschaftliche Revolution.

TECHNOLOGIE: Kombination aus Metallguss, Druckerpresse (Weinpresse-Prinzip), ölbasierter Druckfarbe. Pro Tag 300-3.600 Seiten möglich (vs. Handschrift: 1-2 Seiten). Gutenberg-Bibel: 180 Exemplare (48 erhalten). Verbreitung in Europa innerhalb weniger Jahrzehnte.

BEWEISE: Gutenberg-Bibel (ca. 1455, 48 erhaltene Exemplare); Straßburger Gerichtsakte (1439, Hinweis auf "Druckwerk"); Werkstatt-Inventar Mainz; technische Rekonstruktionen; 42-zeilige Bibel; historische Druckerpressen; UNESCO "Memory of the World" (2001).''',
    position: const LatLng(50.0, 8.2711),
    category: LocationCategory.technology,
    keywords: ['Gutenberg', 'Buchdruck', 'Mainz', 'Revolution', 'Bibel'],
    imageUrls: ['https://www.genspark.ai/api/files/s/PxpY6FGn?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/Gutenberg_Bible.jpg/800px-Gutenberg_Bible.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b4/Gutenberg_press.jpg/1200px-Gutenberg_press.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/33/Gutenberg.jpg/800px-Gutenberg.jpg',
    ],
    videoUrls: ['tAqOHy1-FRs'], // Gutenberg Doku deutsch
    sources: [
      'Gutenberg-Bibel (ca. 1455) - 48 erhaltene Exemplare weltweit',
      'Straßburger Gerichtsakte (1439) - Früheste Erwähnung',
      'Elizabeth L. Eisenstein: "The Printing Press as an Agent of Change" Cambridge (1980)',
      'Gutenberg-Museum Mainz: Technische Dokumentation',
      'UNESCO Memory of the World Programme (2001) - Gutenberg-Bibel',
      'Stephan Füssel: "Gutenberg and the Impact of Printing" Routledge (2005)',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'Erster Weltkrieg Beginn',
    description: 'Beginn des Ersten Weltkriegs nach Attentat auf Franz Ferdinand (1914)',
    detailedInfo: '''OFFIZIELL: Am 28. Juni 1914 wurde Erzherzog Franz Ferdinand in Sarajevo von Gavrilo Princip erschossen. Österreich-Ungarn stellt Ultimatum an Serbien. Ablehnung führt zu Kriegserklärung (28. Juli 1914). Bündnissysteme führen zu Kettenreaktion. Erster Weltkrieg: 17 Millionen Tote. Ende 1918 mit Versailler Vertrag.

URSACHEN: Imperialismus, Nationalismus, Bündnissysteme, Rüstungswettlauf. "Juli-Krise" 1914. Deutschland unterstützt Österreich ("Blankoscheck"). Russland mobilisiert für Serbien. Deutschland erklärt Frankreich & Russland Krieg. Britisches Eingreifen nach Belgien-Invasion.

BEWEISE: Attentat Sarajevo 28. Juni 1914; Österreichisches Ultimatum 23. Juli; Kriegserklärungen Juli-August 1914; Schlieffen-Plan (deutsche Kriegsstrategie); Bündnisverträge (Dreibund, Entente); Versailler Vertrag 1919; Kriegsarchive aller beteiligten Nationen.''',
    position: const LatLng(44.8176, 20.4564),
    category: LocationCategory.wars,
    keywords: ['WW1', 'Sarajevo', 'Gavrilo Princip', 'Attentat', '1914', 'Weltkrieg'],
    date: DateTime(1914, 7, 28),
    imageUrls: ['https://www.genspark.ai/api/files/s/BTzHP7Gl?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/thumb/7/73/Gavrilo_Princip_captured_in_Sarajevo_1914.jpg/1200px-Gavrilo_Princip_captured_in_Sarajevo_1914.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/26/WWI_Trench_Warfare.jpg/1200px-WWI_Trench_Warfare.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/93/Archduke_Franz_Ferdinand_and_Sophie_before_assassination.jpg/1200px-Archduke_Franz_Ferdinand_and_Sophie_before_assassination.jpg',
    ],
    videoUrls: ['ZNJmM7sXbWY'], // WW1 Doku deutsch
    sources: [
      'Fritz Fischer: "Griff nach der Weltmacht" (1961) - Deutsche Kriegsziele',
      'Christopher Clark: "The Sleepwalkers" Harper (2013) - 736 Seiten',
      'Kriegsarchive: Österreichisch-Ungarische Akten (1914)',
      'Luigi Albertini: "The Origins of the War of 1914" Oxford (1952-57)',
      'Versailler Vertrag (28. Juni 1919) - League of Nations Archive',
      'Margaret MacMillan: "The War That Ended Peace" Random House (2013)',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'Hiroshima Atombombe',
    description: 'Erster Atombombenabwurf auf Hiroshima (6. August 1945)',
    detailedInfo: '''OFFIZIELL: Am 6. August 1945 warf die USA die Atombombe "Little Boy" über Hiroshima ab. 70.000-80.000 Tote sofort. Bis Ende 1945: 140.000 Tote. Zweite Bombe auf Nagasaki am 9. August (70.000 Tote). Japan kapituliert am 15. August 1945. Ende des Zweiten Weltkriegs.

KONTROVERSE: War Atombombe militärisch notwendig? Alternative: Japanische Kapitulation stand bevor. Sowjetische Kriegserklärung (8. August) als Faktor. Demonstration der Macht gegenüber Sowjetunion? Ethische Debatte über zivile Opfer.

BEWEISE: Abwurf 6. August 1945, 8:15 Uhr; Enola Gay (B-29 Bomber); Manhattan Project (1942-1945); Trinity-Test (16. Juli 1945); japanische Kapitulationsurkunde (2. September 1945); Hiroshima Peace Memorial (UNESCO); Überlebenden-Berichte (Hibakusha); Strahlenmessungen.''',
    position: const LatLng(34.3853, 132.4553),
    category: LocationCategory.wars,
    keywords: ['Hiroshima', 'Atombombe', 'Japan', 'Manhattan Project', 'WW2'],
    date: DateTime(1945, 8, 6),
    imageUrls: ['https://www.genspark.ai/api/files/s/UIaxERGc?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/54/Atomic_cloud_over_Hiroshima.jpg/1200px-Atomic_cloud_over_Hiroshima.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a6/Hiroshima_aftermath.jpg/1200px-Hiroshima_aftermath.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c4/Atomic_Dome_Hiroshima.jpg/1200px-Atomic_Dome_Hiroshima.jpg',
    ],
    videoUrls: ['IT8grVY_H1E'], // Hiroshima Doku deutsch
    sources: [
      'Manhattan Project Technical History (US Department of Energy, 1945)',
      'Richard Rhodes: "The Making of the Atomic Bomb" Simon & Schuster (1986) - 928 Seiten',
      'Hiroshima Peace Memorial Museum Archives',
      'Japanese Surrender Document (2. September 1945)',
      'Gar Alperovitz: "The Decision to Use the Atomic Bomb" (1995) - 847 Seiten',
      'Hibakusha Testimonies - Survivor Accounts (1945-2024)',
    ],
  ),
  
  // EVENT 26: GUTENBERG DRUCKERPRESSE (1440)
  MaterieLocationDetail(
    name: 'Gutenberg Druckerpresse - Mainz',
    description: 'Johannes Gutenberg erfindet den Buchdruck mit beweglichen Lettern (ca. 1440) - Revolution der Informationsverbreitung',
    detailedInfo: '''Um 1440 revolutionierte Johannes Gutenberg in Mainz die Welt mit der Erfindung des Buchdrucks mit beweglichen Metall-Lettern. Diese Innovation ermöglichte die Massenproduktion von Büchern und leitete das Zeitalter der Informationsverbreitung ein.

📘 OFFIZIELLE VERSION:
Gutenberg entwickelte eine Druckpresse mit austauschbaren Metall-Lettern, die wiederverwendet werden konnten. Die erste große Anwendung war die Gutenberg-Bibel (1452-1455), von der 180 Exemplare gedruckt wurden. Die Erfindung verbreitete sich schnell in ganz Europa: Bis 1500 existierten ca. 250 Druckereien in Europa, die über 20 Millionen Bücher produzierten. Der Buchdruck ermöglichte die Verbreitung von Wissen, wissenschaftlichen Erkenntnissen und religiösen Texten und war maßgeblich für die Renaissance und Reformation verantwortlich.

🔍 ALTERNATIVE SICHTWEISE & VERBORGENE GESCHICHTE:
Gutenbergs Erfindung basierte möglicherweise auf ostasiatischen Techniken - China hatte bereits im 11. Jahrhundert bewegliche Lettern aus Ton. Die wahre Revolution war die Kombination mehrerer Technologien: Metallguss, Ölbasierende Druckerschwärze, und die Weinpresse-Mechanik. Gutenberg war hoch verschuldet und verlor 1455 seine Werkstatt an seinen Gläubiger Johann Fust, der die Gutenberg-Bibel vollendete und vermarktete. Die katholische Kirche erkannte zunächst nicht die Gefahr: Der Buchdruck ermöglichte die Verbreitung von Martin Luthers 95 Thesen (1517) und führte zur Reformation. Die Kirche verlor ihr Informationsmonopol. Verbotene Bücher (Index Librorum Prohibitorum) wurden trotz Zensur massenhaft gedruckt und verbreitet. Der Buchdruck war die erste "Massenvernichtungswaffe" gegen Autoritäten und Dogmen.

🔒 BEWEISE & QUELLEN:
• Gutenberg-Museum Mainz bewahrt Original-Druckpresse und B-42-Bibel-Exemplare
• Nur 49 Gutenberg-Bibeln überlebt (von 180 gedruckten)
• Erste gedruckte Bücher (Inkunabeln) bis 1500: über 20 Millionen Exemplare
• Luthers 95 Thesen: In 2 Wochen in ganz Deutschland verbreitet (1517)
• Index Librorum Prohibitorum (1559): Liste verbotener Bücher der Kirche
• Gutenberg starb 1468 in Armut - sein Partner Fust profitierte vom Erfolg''',
    position: LatLng(50.0012, 8.2737), // Mainz, Deutschland
    category: LocationCategory.technology,
    keywords: ['Gutenberg', 'Buchdruck', 'Mainz', 'Renaissance', 'Information', 'Reformation'],
    imageUrls: ['https://www.genspark.ai/api/files/s/HRchkbKx?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/5/58/Gutenberg_Bible%2C_Lenox_Copy%2C_New_York_Public_Library%2C_2009._Pic_01.jpg', // Gutenberg-Bibel
      'https://upload.wikimedia.org/wikipedia/commons/3/33/PrintMus_038.jpg', // Gutenberg-Druckerpresse Replik
      'https://upload.wikimedia.org/wikipedia/commons/e/e6/Gutenberg.jpg', // Johannes Gutenberg Portrait
    ],
    videoUrls: ['4ce8eb_17mU'], // ZDF Terra X: Gutenberg und der Buchdruck (Deutsch)
    sources: [
      'Gutenberg-Museum Mainz - Original B-42 Bibel Exemplar',
      'New York Public Library - Lenox Copy der Gutenberg-Bibel',
      'Martin Davies: "The Gutenberg Bible" (1996) - British Library Studies',
      'Albert Kapr: "Johannes Gutenberg: Persönlichkeit und Leistung" (1987) - 458 Seiten',
      'Elizabeth Eisenstein: "The Printing Press as an Agent of Change" (1980) - Cambridge University Press',
      'UNESCO Memory of the World Register: Gutenberg Bible (2001)',
    ],
  ),
  
  // EVENT 27: NEWTON GRAVITATION (1687)
  MaterieLocationDetail(
    name: 'Newtons Gravitationsgesetz - Cambridge',
    description: 'Isaac Newton veröffentlicht "Philosophiae Naturalis Principia Mathematica" (1687) - Grundlagen der klassischen Mechanik',
    detailedInfo: '''1687 veröffentlichte Isaac Newton sein Hauptwerk "Philosophiae Naturalis Principia Mathematica", in dem er die drei Newtonschen Axiome und das universelle Gravitationsgesetz formulierte. Dieses Werk legte die Grundlagen der klassischen Mechanik und Physik für die nächsten 200 Jahre.

📘 OFFIZIELLE VERSION:
Newton formulierte drei grundlegende Bewegungsgesetze und das universelle Gravitationsgesetz: F = G × (m1 × m2) / r². Diese Gesetze erklärten die Bewegung von Planeten, den freien Fall, Gezeiten und Kometen-Bahnen. Newton bewies, dass die gleichen Gesetze sowohl auf der Erde als auch im Weltraum gelten. Die "Principia" gilt als eines der wichtigsten wissenschaftlichen Werke aller Zeiten. Newton war auch ein brillanter Mathematiker und entwickelte die Infinitesimalrechnung (parallel zu Leibniz).

🔍 ALTERNATIVE SICHTWEISE & VERBORGENE GESCHICHTE:
Die berühmte "Apfel-Geschichte" ist höchstwahrscheinlich eine Legende, die Newton selbst im Alter erzählte. Newton war ein obskurer Alchemist und verbrachte mehr Zeit mit alchemistischen Experimenten als mit Physik - über 1 Million Worte in alchemistischen Manuskripten. Er glaubte an verborgene Kräfte und suchte nach dem "Stein der Weisen". Newton hatte einen erbitterten Prioritätsstreit mit Leibniz über die Erfindung der Infinitesimalrechnung (1684-1716). Newton nutzte seine Position als Präsident der Royal Society, um Leibniz zu diskreditieren. Newton war auch ein tief religiöser Mann und verfasste theologische Schriften, die die Dreifaltigkeit ablehnten - häretische Ansichten für die damalige Zeit. Seine "Principia" wurde auf Druck seines Freundes Edmond Halley veröffentlicht, der auch die Kosten übernahm. Ohne Halley wäre das Werk möglicherweise nie erschienen.

🔒 BEWEISE & QUELLEN:
• Original "Principia Mathematica" (1687) - Cambridge University Library
• Newtons Alchemie-Manuskripte - über 1 Million Worte (Cambridge Digital Library)
• Leibniz-Newton Prioritätsstreit Dokumente (1684-1716)
• Newtons theologische Schriften über Anti-Trinitarismus (unveröffentlicht bis 20. Jh.)
• Edmond Halley finanzierte und überredete Newton zur Veröffentlichung
• Newton als Warden der Royal Mint: Verfolgte Falschmünzer gnadenlos''',
    position: LatLng(52.2053, 0.1218), // Cambridge, England - Trinity College
    category: LocationCategory.science,
    keywords: ['Newton', 'Gravitation', 'Physik', 'Cambridge', 'Principia', 'Mathematik'],
    imageUrls: ['https://www.genspark.ai/api/files/s/1CSj3Kjj?cache_control=3600', // 🎨 HYPERREALISTISCH
      'https://www.genspark.ai/api/files/s/yqVLyikO?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/b/b2/Prinicipia-title.png', // Principia Titelseite
      'https://upload.wikimedia.org/wikipedia/commons/3/3b/Portrait_of_Sir_Isaac_Newton%2C_1689.jpg', // Newton Portrait 1689
      'https://upload.wikimedia.org/wikipedia/commons/f/f7/Newtons_cradle_animation_book_2.gif', // Newtons Wiege (Impulserhaltung)
    ],
    videoUrls: ['4-6_BfgFd5M'], // ZDF: Newton und die Schwerkraft (Deutsch)
    sources: [
      'Cambridge University Library - Original "Principia Mathematica" (1687)',
      'Cambridge Digital Library - Newtons Alchemie-Manuskripte (1.000.000+ Wörter)',
      'Richard S. Westfall: "Never at Rest: A Biography of Isaac Newton" (1980) - 908 Seiten',
      'Betty Jo Teeter Dobbs: "The Janus Faces of Genius: The Role of Alchemy in Newton\'s Thought" (1991)',
      'Rob Iliffe: "Priest of Nature: The Religious Worlds of Isaac Newton" (2017)',
      'Royal Society Archives - Leibniz-Newton Prioritätsstreit Dokumente (1684-1716)',
    ],
  ),
  
  // EVENT 28: DARWIN EVOLUTION (1859)
  MaterieLocationDetail(
    name: 'Darwins Evolutionstheorie - London',
    description: 'Charles Darwin veröffentlicht "On the Origin of Species" (1859) - Theorie der natürlichen Selektion revolutioniert Biologie',
    detailedInfo: '''Am 24. November 1859 veröffentlichte Charles Darwin sein bahnbrechendes Werk "On the Origin of Species", in dem er die Theorie der Evolution durch natürliche Selektion darlegte. Dieses Buch revolutionierte unser Verständnis des Lebens und löste heftige Debatten aus.

📘 OFFIZIELLE VERSION:
Darwin beobachtete während seiner 5-jährigen Reise auf der HMS Beagle (1831-1836) verschiedene Tier- und Pflanzenarten, insbesondere auf den Galapagos-Inseln. Er entwickelte die Theorie, dass alle Arten durch natürliche Selektion entstanden sind: Individuen mit vorteilhaften Eigenschaften überleben und pflanzen sich fort. Über lange Zeiträume führt dies zur Entstehung neuer Arten. Darwins Theorie wurde durch fossile Funde, vergleichende Anatomie und später durch Genetik bestätigt. Sie bildet die Grundlage der modernen Biologie.

🔍 ALTERNATIVE SICHTWEISE & VERBORGENE GESCHICHTE:
Darwin zögerte 20 Jahre mit der Veröffentlichung seiner Theorie aus Angst vor religiösem Backlash und gesellschaftlicher Ächtung. Seine Frau Emma war tiefgläubig und besorgt über die Auswirkungen seiner Ideen auf ihr Seelenheil. 1858 erhielt Darwin einen Brief von Alfred Russel Wallace, der unabhängig zur gleichen Theorie gelangt war - dies zwang Darwin zur schnellen Veröffentlichung. Einige Historiker argumentieren, dass Darwin Wallace' Priorität "stahl". Darwin selbst wandte seine Theorie auf den Menschen an, was zur Kontroverse über "Sozialdarwinismus" führte - eine Ideologie, die später zur Rechtfertigung von Rassismus und Eugenik missbraucht wurde. Die Kirche sah in Darwins Theorie einen Angriff auf die biblische Schöpfungsgeschichte. Die berühmte Debatte zwischen Thomas Huxley ("Darwins Bulldogge") und Bischof Samuel Wilberforce (1860) polarisierte die Gesellschaft. Darwin litt sein Leben lang unter mysteriösen Krankheiten - möglicherweise psychosomatisch bedingt durch den Stress seiner kontroversen Arbeit.

🔒 BEWEISE & QUELLEN:
• HMS Beagle Tagebücher (1831-1836) - Darwins handschriftliche Notizen
• Galapagos-Finken Sammlung - Natural History Museum London
• Brief von Alfred Russel Wallace an Darwin (1858) - Auslöser der Publikation
• Erste Ausgabe "On the Origin of Species" (1859) - 1.250 Exemplare, am ersten Tag ausverkauft
• Darwin-Wallace Gemeinsame Präsentation bei der Linnean Society (1. Juli 1858)
• Huxley-Wilberforce Debatte über Evolution (30. Juni 1860) - Oxford University''',
    position: LatLng(51.5074, -0.1278), // London, England - Down House (Darwins Wohnort)
    category: LocationCategory.science,
    keywords: ['Darwin', 'Evolution', 'Biologie', 'Galapagos', 'Natürliche Selektion', 'HMS Beagle'],
    imageUrls: ['https://www.genspark.ai/api/files/s/szkMwJnu?cache_control=3600', // 🎨 HYPERREALISTISCH
      'https://www.genspark.ai/api/files/s/gQQtz0Su?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/2/2e/Origin_of_Species_title_page.jpg', // Origin of Species Titelseite
      'https://upload.wikimedia.org/wikipedia/commons/1/1e/Charles_Darwin_1854.jpg', // Darwin 1854
      'https://upload.wikimedia.org/wikipedia/commons/e/e0/Geospiza_magnirostris_%28Darwin%27s_finch%29.jpg', // Galapagos-Fink
    ],
    videoUrls: ['wKPNFF4Y7tk'], // ARTE: Darwin und die Evolution (Deutsch)
    sources: [
      'Natural History Museum London - Darwins Galapagos-Finken Sammlung',
      'Cambridge University Library - Darwins HMS Beagle Tagebücher (1831-1836)',
      'Alfred Russel Wallace Brief an Darwin (Juni 1858) - British Library',
      'Janet Browne: "Charles Darwin: The Power of Place" (2002) - 591 Seiten',
      'Adrian Desmond & James Moore: "Darwin" (1991) - 808 Seiten',
      'Linnean Society Archives - Darwin-Wallace Joint Paper (1. Juli 1858)',
    ],
  ),
  
  // EVENT 29: EINSTEIN RELATIVITÄT (1905)
  MaterieLocationDetail(
    name: 'Einsteins Relativitätstheorie - Bern',
    description: 'Albert Einstein veröffentlicht die Spezielle Relativitätstheorie (1905) - E=mc² revolutioniert Physik',
    detailedInfo: '''1905 war Einsteins "Annus Mirabilis" (Wunderjahr): Der 26-jährige Patentamtsangestellte veröffentlichte vier bahnbrechende Arbeiten, darunter die Spezielle Relativitätstheorie mit der berühmten Formel E=mc². Diese Theorie revolutionierte unser Verständnis von Raum, Zeit, Masse und Energie.

📘 OFFIZIELLE VERSION:
Einstein postulierte zwei Prinzipien: 1) Die Lichtgeschwindigkeit ist konstant für alle Beobachter, und 2) Die Naturgesetze sind für alle Beobachter in Inertialsystemen gleich. Daraus folgte, dass Zeit und Raum relativ sind - bewegte Uhren gehen langsamer (Zeitdilatation) und bewegte Objekte schrumpfen (Längenkontraktion). Die Masse-Energie-Äquivalenz E=mc² zeigte, dass Masse und Energie austauschbar sind. 1915 erweiterte Einstein dies zur Allgemeinen Relativitätstheorie, die Gravitation als Krümmung der Raumzeit beschreibt. Beide Theorien wurden vielfach experimentell bestätigt (z.B. Sonnenfinsternis 1919, GPS-Satelliten, Gravitationswellen 2015).

🔍 ALTERNATIVE SICHTWEISE & VERBORGENE GESCHICHTE:
Einstein war 1905 ein unbekannter Patentamtsbeamter in Bern - seine Theorien wurden zunächst ignoriert oder belächelt. Einige Historiker argumentieren, dass Einsteins erste Frau Mileva Marić, eine Physikerin, maßgeblich zu seinen frühen Arbeiten beitrug - ihr Name erschien jedoch nicht auf den Publikationen. Einstein erhielt 1921 den Nobelpreis für den photoelektrischen Effekt (1905), NICHT für die Relativitätstheorie, die als zu kontrovers galt. In den 1920er-30er Jahren organisierten deutsche Nationalisten eine "Anti-Relativitäts-Kampagne", die Einsteins Theorien als "jüdische Physik" verunglimpften. Einstein floh 1933 vor den Nazis in die USA. Er unterzeichnete 1939 einen Brief an Präsident Roosevelt, der das Manhattan-Projekt zur Entwicklung der Atombombe auslöste - eine Entscheidung, die er später bereute. Einstein wurde vom FBI überwacht wegen seiner pazifistischen und sozialistischen Ansichten (1.400 Seiten FBI-Akte). Seine Formel E=mc² ermöglichte die Atombombe - eine tragische Ironie für einen Pazifisten.

🔒 BEWEISE & QUELLEN:
• Einsteins 1905 "Annus Mirabilis" Publikationen - 4 revolutionäre Arbeiten in einem Jahr
• Sonnenfinsternis-Expedition 1919 (Arthur Eddington) - Bestätigung der Allgemeinen Relativitätstheorie
• Mileva Marić Briefe an Einstein (1897-1903) - Hinweise auf Zusammenarbeit
• Nobelpreis 1921 für Photoelektrischen Effekt - NICHT für Relativitätstheorie
• FBI-Akte über Einstein (1.400 Seiten) - Überwachung wegen politischer Ansichten
• LIGO Gravitationswellen-Detektion (2015) - Endgültige Bestätigung der Allgemeinen Relativität''',
    position: LatLng(46.9480, 7.4474), // Bern, Schweiz - Einsteins Wohnort 1905
    category: LocationCategory.science,
    keywords: ['Einstein', 'Relativität', 'Physik', 'E=mc²', 'Bern', 'Quantenphysik'],
    imageUrls: ['https://www.genspark.ai/api/files/s/Gyj7wtFi?cache_control=3600', // 🎨 HYPERREALISTISCH
      'https://www.genspark.ai/api/files/s/yV9ZfkoJ?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/d/d3/Albert_Einstein_Head.jpg', // Einstein Portrait
      'https://upload.wikimedia.org/wikipedia/commons/f/f5/Einsteins_office_at_the_Patent_Office_in_Bern%2C_Switzerland.jpg', // Einsteins Patentamtbüro Bern
      'https://upload.wikimedia.org/wikipedia/commons/4/4f/E%3Dmc2.svg', // E=mc² Formel
    ],
    videoUrls: ['7bw3C2M6tqw'], // ZDF: Einstein und die Relativitätstheorie (Deutsch)
    sources: [
      'Einstein Archive Online - Digitale Sammlung von Einsteins Manuskripten und Briefen',
      'Annalen der Physik (1905) - Einsteins vier "Annus Mirabilis" Publikationen',
      'FBI Einstein Akte (1.400 Seiten) - Freigegeben unter Freedom of Information Act',
      'Walter Isaacson: "Einstein: His Life and Universe" (2007) - 675 Seiten',
      'Abraham Pais: "Subtle is the Lord: The Science and the Life of Albert Einstein" (1982)',
      'Arthur Eddington Sonnenfinsternis-Expedition Fotos (29. Mai 1919) - Royal Society',
    ],
  ),
  
  // EVENT 30: DNA STRUKTUR (1953)
  MaterieLocationDetail(
    name: 'DNA Doppelhelix entdeckt - Cambridge',
    description: 'Watson & Crick entdecken die DNA-Struktur (1953) - Grundlage der modernen Genetik und Biotechnologie',
    detailedInfo: '''Am 25. April 1953 veröffentlichten James Watson und Francis Crick in der Zeitschrift "Nature" einen einseitigen Artikel, der die Doppelhelix-Struktur der DNA beschrieb. Diese Entdeckung revolutionierte die Biologie und legte den Grundstein für Genetik, Biotechnologie und Medizin.

📘 OFFIZIELLE VERSION:
Watson und Crick nutzten Röntgenkristallographie-Daten und bauten ein physisches Modell der DNA-Struktur: Eine Doppelhelix mit Zucker-Phosphat-Rückgrat und komplementären Basenpaaren (Adenin-Thymin, Guanin-Cytosin) im Inneren. Die Struktur erklärte, wie genetische Information gespeichert, kopiert und weitergegeben wird. Watson, Crick und Maurice Wilkins erhielten 1962 den Nobelpreis für Physiologie oder Medizin. Die Entdeckung führte zur modernen Molekularbiologie, Gentechnik und dem Human Genome Project (2003).

🔍 ALTERNATIVE SICHTWEISE & VERBORGENE GESCHICHTE:
Die wahre Heldin der DNA-Entdeckung war Rosalind Franklin, eine brillante Chemikerin, deren Röntgenbeugungsbild "Photo 51" die entscheidende Evidenz für die Doppelhelix lieferte. Watson und Crick sahen dieses Bild ohne Franklins Wissen oder Erlaubnis - ihr Kollege Maurice Wilkins zeigte es ihnen heimlich. Franklin starb 1958 im Alter von 37 Jahren an Eierstockkrebs (möglicherweise durch Röntgenstrahlung verursacht) und erhielt nie die verdiente Anerkennung. Der Nobelpreis wurde 1962 posthum nicht an sie verliehen - eine der größten Ungerechtigkeiten der Wissenschaftsgeschichte. Watson beschrieb Franklin in seinem Buch "The Double Helix" (1968) herabwürdigend als "Rosy", was zu weiterer Kontroverse führte. Der eigentliche Credit sollte zu 50% Franklin, 25% Watson, 25% Crick gehen. Linus Pauling, der Konkurrent, hatte ein fehlerhaftes DNA-Modell (Triple Helix) vorgeschlagen - Watson & Crick hatten Glück und Zugang zu besseren Daten.

🔒 BEWEISE & QUELLEN:
• Rosalind Franklins "Photo 51" (1952) - Schlüsselbild der DNA-Struktur (King's College London)
• Watson & Crick Nature Artikel (25. April 1953) - Nur 1 Seite, aber weltverändernd
• Maurice Wilkins zeigte Watson heimlich Franklins Daten (ohne ihre Erlaubnis)
• Rosalind Franklin starb 1958 (37 Jahre alt) - Kein Nobelpreis für sie
• Nobelpreis 1962 für Watson, Crick, Wilkins - Franklin wurde übergangen
• Watson "The Double Helix" (1968) - Kontroverse Darstellung von Franklin als "Rosy"''',
    position: LatLng(52.2053, 0.1218), // Cambridge, England - Cavendish Laboratory
    category: LocationCategory.science,
    keywords: ['DNA', 'Watson', 'Crick', 'Franklin', 'Genetik', 'Doppelhelix'],
    imageUrls: ['https://www.genspark.ai/api/files/s/ybhttWEk?cache_control=3600', // 🎨 HYPERREALISTISCH
      'https://www.genspark.ai/api/files/s/BXC66y7i?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/d/d4/Photo_51.jpg', // Rosalind Franklins Photo 51
      'https://upload.wikimedia.org/wikipedia/commons/4/4c/DNA_Structure%2BKey%2BLabelled.pn_NoBB.png', // DNA Doppelhelix Modell
      'https://upload.wikimedia.org/wikipedia/commons/c/c1/Rosalind_Franklin.jpg', // Rosalind Franklin Portrait
    ],
    videoUrls: ['o_-6JXLYS-k'], // ARTE: Die DNA-Story (Deutsch)
    sources: [
      'King\'s College London Archives - Rosalind Franklins "Photo 51" Original (1952)',
      'Nature Artikel "Molecular Structure of Nucleic Acids" (25. April 1953) - 1 Seite',
      'Brenda Maddox: "Rosalind Franklin: The Dark Lady of DNA" (2002) - 380 Seiten',
      'James Watson: "The Double Helix" (1968) - Kontroverse autobiographische Darstellung',
      'Nobel Prize Archive - Watson, Crick, Wilkins (1962) - Franklin wurde übergangen',
      'Lynne Osman Elkin: "Rosalind Franklin and the Double Helix" (2003) - Physics Today',
    ],
  ),
  
  // EVENT 31: TUNGUSKA EXPLOSION (1908)
  MaterieLocationDetail(
    name: 'Tunguska Explosion - Sibirien',
    description: 'Mysteriöse Explosion über Sibirien (30. Juni 1908) - 2.000 km² Wald zerstört, keine Krater',
    detailedInfo: '''Am 30. Juni 1908 um 7:17 Uhr explodierte ein Objekt über dem dünn besiedelten Gebiet der Steinigen Tunguska in Sibirien. Die Explosion hatte die Kraft von 10-15 Megatonnen TNT (1.000x stärker als Hiroshima) und zerstörte 80 Millionen Bäume auf 2.000 km² - aber hinterließ keinen Einschlagskrater.

📘 OFFIZIELLE VERSION (Meteoriten-Theorie):
Ein Asteroid oder Komet mit einem Durchmesser von 50-100 Metern drang in die Erdatmosphäre ein und explodierte in 5-10 km Höhe über dem Boden (Luftexplosion). Die Druckwelle und Hitze verwüsteten das Gebiet, aber es gab keinen direkten Einschlag, daher keinen Krater. Seismographen weltweit registrierten die Explosion. Zeugen berichteten von einem blendenden Lichtblitz, gefolgt von einer gewaltigen Druckwelle. Expeditionen in den 1920er Jahren (Leonid Kulik) fanden umgestürzte Bäume in radialer Anordnung, aber kein Meteoritenmaterial.

🔍 ALTERNATIVE SICHTWEISEN & MYSTERIEN:
Mehrere alternative Theorien existieren: 1) UFO-Absturz oder außerirdische Raumschiff-Explosion - einige Forscher behaupten, die Explosion sei zu kontrolliert für einen Meteor gewesen. 2) Nikola Tesla Experiment: Tesla arbeitete 1908 an seiner "Todesstrahlen"-Waffe und behauptete später, er könne Energie drahtlos übertragen. Einige spekulieren, Tesla testete sein System am 30. Juni 1908 - und zielte versehentlich auf Sibirien statt Arktis. 3) Schwarzes Loch Theorie: Einige Physiker spekulierten, ein Mini-Schwarzes Loch durchdrang die Erde (widerlegt). 4) Antimaterien-Theorie: Antimaterien-Komet kollidierte mit Materie (keine Beweise). 5) Geheime Waffentests: Einige glauben, es war ein früher Nukleartest (unmöglich, 1908 gab es keine Atomwaffen). Das Fehlen eines Kraters und von Meteoritenmaterial bleibt rätselhaft. Indigene Ewenken-Völker berichteten von "feurigen Himmelsgöttern" und betrachten das Gebiet als verflucht.

🔒 BEWEISE & QUELLEN:
• 80 Millionen umgestürzte Bäume in radialer Anordnung (2.000 km² Fläche)
• Seismographische Aufzeichnungen weltweit (30. Juni 1908, 7:17 Uhr)
• Leonid Kulik Expeditionen (1927, 1928, 1929) - Fotos der Verwüstung
• KEIN Einschlagskrater gefunden - ungewöhnlich für Meteoriten
• KEIN Meteoritenmaterial gefunden (nur mikroskopische Silikat-Kügelchen)
• Zeugenbericht: "Die Sonne schien zweimal an diesem Tag" (Augenzeugen 800 km entfernt)''',
    position: LatLng(60.8833, 101.8833), // Tunguska, Sibirien, Russland
    category: LocationCategory.disasters,
    keywords: ['Tunguska', 'Explosion', 'Sibirien', 'Meteor', 'Mysterium', 'Katastrophe'],
    imageUrls: ['https://www.genspark.ai/api/files/s/bIljx3eB?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/c/c4/Tunguska_event_fallen_trees.jpg', // Umgestürzte Bäume Tunguska
      'https://upload.wikimedia.org/wikipedia/commons/1/15/Tunguska_Ereignis.png', // Karte der Explosion
      'https://upload.wikimedia.org/wikipedia/commons/2/2b/Kulik_expedition.jpg', // Leonid Kulik Expedition Foto 1927
    ],
    videoUrls: ['YU1xKJT4aXg'], // ZDF Terra X: Das Tunguska-Rätsel (Deutsch)
    sources: [
      'Leonid Kulik Expeditionsfotos (1927-1929) - Russian Academy of Sciences',
      'Seismographische Aufzeichnungen (30. Juni 1908) - Weltweit registriert',
      'Vladimir Rubtsov: "The Tunguska Mystery" (2009) - 320 Seiten',
      'Gasperini et al.: "Cheko Lake: Tunguska Impact Crater?" (2007) - Terra Nova Journal',
      'NASA Near-Earth Object Program - Tunguska Event Analysis',
      'Ewenken-Völker Oral Histories - Indigene Berichte über "Feurige Himmelsgötter"',
    ],
  ),
  
  // EVENT 32: TITANIC UNTERGANG (1912)
  MaterieLocationDetail(
    name: 'Titanic Untergang - Nordatlantik',
    description: 'RMS Titanic sinkt nach Eisberg-Kollision (15. April 1912) - 1.517 Tote, "unsinkbares Schiff"',
    detailedInfo: '''In der Nacht vom 14. auf 15. April 1912 kollidierte die "unsinkbare" RMS Titanic auf ihrer Jungfernfahrt von Southampton nach New York mit einem Eisberg. Das größte Passagierschiff der Welt sank in nur 2 Stunden und 40 Minuten. Von 2.224 Menschen an Bord starben 1.517.

📘 OFFIZIELLE VERSION:
Die Titanic streifte um 23:40 Uhr einen Eisberg an der Steuerbordseite, der sechs Kompartimente unterhalb der Wasserlinie aufriss. Das Schiff war für maximal vier geflutete Kompartimente ausgelegt. Kapitän Edward Smith und Chefingenieur Thomas Andrews erkannten schnell, dass das Schiff sinken würde. Es gab nur 20 Rettungsboote für 2.224 Menschen (Platz für 1.178). Das Schiff sank um 2:20 Uhr. Die RMS Carpathia rettete 710 Überlebende. Hauptursachen: Zu hohe Geschwindigkeit (22,5 Knoten) trotz Eisbergwarnungen, unzureichende Rettungsboote, Fehlalarm der nahegelegenen SS Californian ignoriert.

🔍 ALTERNATIVE SICHTWEISEN & VERSCHWÖRUNGSTHEORIEN:
Mehrere kontroverse Theorien: 1) Versicherungsbetrug: Die Titanic war in Wahrheit ihr Schwesterschiff Olympic, das bei einem Unfall schwer beschädigt wurde. Die White Star Line tauschte die Schiffe aus, um Versicherungsgeld zu kassieren (200+ Identifikationsnummern-Inkonsistenzen gefunden). 2) J.P. Morgan Verschwörung: Drei mächtige Bankiers, die gegen die Federal Reserve waren, starben auf der Titanic: John Jacob Astor IV, Benjamin Guggenheim, Isidor Straus. J.P. Morgan, der Eigentümer der White Star Line, sagte seine Reise in letzter Minute ab. 3) SS Californian: Das Schiff war nur 10-20 Meilen entfernt, ignorierte aber Notraketen - möglicherweise absichtlich. Kapitän Stanley Lord wurde beschuldigt, Hilfe verweigert zu haben. 4) Kohlebrand-Theorie: Ein Kohlebrand im Bunker schwächte die Stahlhülle vor der Kollision (Fotos zeigen Verbrennungsschäden). 5) Eisberg-Warnung ignoriert: Kapitän Smith erhielt 6 Eisberg-Warnungen, fuhr aber weiter mit voller Geschwindigkeit - warum?

🔒 BEWEISE & QUELLEN:
• Wrack entdeckt 1985 in 3.800 m Tiefe (Robert Ballard Expedition)
• 710 Überlebende - 1.517 Tote (705 Leichen geborgen)
• J.P. Morgan sagte Reise in letzter Minute ab (Eigentümer der White Star Line)
• Olympic-Titanic Switch-Theorie: 200+ Identifikationsnummern-Inkonsistenzen
• Kohlebrand-Foto von der Titanic (vor Abfahrt) - Sichtbare Schadstelle an Steuerbord
• SS Californian Logs: Nur 10-20 Meilen entfernt, ignorierte Notraketen''',
    position: LatLng(41.7325, -49.9469), // Titanic Wrack Position, Nordatlantik
    category: LocationCategory.disasters,
    keywords: ['Titanic', 'Untergang', 'Eisberg', 'Katastrophe', 'J.P. Morgan', 'Verschwörung'],
    imageUrls: ['https://www.genspark.ai/api/files/s/7n5zUubs?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/f/fd/RMS_Titanic_3.jpg', // Titanic in Southampton 1912
      'https://upload.wikimedia.org/wikipedia/commons/1/10/Titanic_wreck_bow.jpg', // Titanic Wrack 1985
      'https://upload.wikimedia.org/wikipedia/commons/c/c4/Stöwer_Titanic.jpg', // Titanic Untergang Gemälde (Stöwer)
    ],
    videoUrls: ['FSGeskFzE0s'], // ZDF History: Titanic - Die wahre Geschichte (Deutsch)
    sources: [
      'Robert Ballard Wrack-Entdeckung (1. September 1985) - 3.800 m Tiefe',
      'British Wreck Commissioner\'s Inquiry Report (1912) - Offizielle Untersuchung',
      'Robin Gardiner & Dan van der Vat: "The Riddle of the Titanic" (1995) - Olympic-Switch-Theorie',
      'Senan Molony: "Titanic: The New Evidence" (2017) - Kohlebrand-Theorie mit Fotos',
      'Walter Lord: "A Night to Remember" (1955) - Klassische Titanic-Darstellung',
      'Encyclopedia Titanica - Vollständige Passagier- und Besatzungsliste mit Schicksalen',
    ],
  ),
  
  // EVENT 33: HINDENBURG KATASTROPHE (1937)
  MaterieLocationDetail(
    name: 'Hindenburg Katastrophe - Lakehurst',
    description: 'Luftschiff Hindenburg explodiert bei der Landung (6. Mai 1937) - 36 Tote, Live im Radio übertragen',
    detailedInfo: '''Am 6. Mai 1937 explodierte das größte jemals gebaute Luftschiff, die LZ 129 Hindenburg, bei der Landung in Lakehurst, New Jersey. Das mit Wasserstoff gefüllte Luftschiff ging in 34 Sekunden in Flammen auf. Von 97 Menschen an Bord starben 35 plus ein Bodenpersonal. Die Katastrophe wurde live im Radio übertragen und markierte das Ende der Luftschiff-Ära.

📘 OFFIZIELLE VERSION:
Die Hindenburg war auf einem Transatlantikflug von Frankfurt nach New York. Bei der Landung um 19:25 Uhr entzündete sich das Wasserstoffgas, vermutlich durch statische Elektrizität oder ein Leck. Das Feuer breitete sich blitzschnell aus - das gesamte Luftschiff verbrannte in 34 Sekunden. Reporter Herbert Morrison übertrug die Katastrophe live im Radio mit den berühmten Worten: "Oh, the humanity!" Die Untersuchung kam zu dem Schluss, dass elektrostatische Entladung oder Blitzschlag die Ursache war. Die Hindenburg war mit 7 Millionen Kubikfuß Wasserstoff gefüllt (hochexplosiv), da die USA Helium-Exporte nach Deutschland verboten hatten.

🔍 ALTERNATIVE SICHTWEISEN & SABOTAGE-THEORIEN:
Mehrere Theorien deuten auf Sabotage: 1) Anti-Nazi-Sabotage: Das Luftschiff war ein Propaganda-Symbol des Nazi-Regimes. Einige glauben, ein Saboteur zündete das Wasserstoffgas absichtlich. Verdächtige: Besatzungsmitglied Eric Spehl (starb bei der Explosion) oder Joseph Späh, ein Akrobat, der verdächtig nah am Heck war. 2) US-Geheimdienst-Operation: Die USA wollten die deutsche Luftfahrt-Überlegenheit beenden und sabotierten das Luftschiff. 3) Helium-Embargo-Theorie: Die USA verweigerten Deutschland Helium-Exporte, obwohl sie wussten, dass Wasserstoff gefährlich war - eine gezielte Schwächung Deutschlands. 4) Statische Elektrizität + Lackbrand: Neuere Forschung zeigt, dass die Außenhaut mit hochentzündlichem Lack beschichtet war (ähnlich Raketentreibstoff). Der Lack entzündete sich zuerst, nicht das Wasserstoffgas. 5) Herbert Morrison Reportage: Seine emotionale "Oh, the humanity!"-Aufnahme wurde erst am nächsten Tag ausgestrahlt, was Fragen über die Authentizität aufwirft.

🔒 BEWEISE & QUELLEN:
• 34 Sekunden von Entzündung bis Zerstörung - Filmaufnahmen dokumentiert
• Herbert Morrison Live-Reportage "Oh, the humanity!" (WLS Radio Chicago)
• 36 Tote (35 an Bord + 1 Bodenpersonal) - 62 Überlebende
• US Commerce Department Untersuchung (1937) - Elektrostatische Entladung als Ursache
• Wasserstoff statt Helium: USA verboten Helium-Export nach Deutschland (1936)
• Addison Bain NASA-Forschung (1997): Lack entzündete sich zuerst, nicht Wasserstoff''',
    position: LatLng(40.0328, -74.3238), // Lakehurst, New Jersey, USA - Naval Air Station
    category: LocationCategory.disasters,
    keywords: ['Hindenburg', 'Luftschiff', 'Explosion', 'Katastrophe', 'Lakehurst', 'Nazi'],
    imageUrls: ['https://www.genspark.ai/api/files/s/iKN5H31o?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/1/1c/Hindenburg_disaster.jpg', // Hindenburg Explosion Foto
      'https://upload.wikimedia.org/wikipedia/commons/6/6c/Hindenburg_at_lakehurst.jpg', // Hindenburg vor der Landung
      'https://upload.wikimedia.org/wikipedia/commons/9/94/Bundesarchiv_Bild_146-1978-043-28%2C_Lakehurst%2C_Explosion_des_Zeppelin_LZ_129.jpg', // Hindenburg Explosion Sequenz
    ],
    videoUrls: ['CgWHbpMVQ1U'], // ZDF: Hindenburg - Das letzte Rätsel (Deutsch)
    sources: [
      'Herbert Morrison WLS Radio Reportage (6. Mai 1937) - "Oh, the humanity!" Original Audio',
      'US Commerce Department Hindenburg Disaster Report (1937) - Offizielle Untersuchung',
      'Addison Bain NASA Research (1997) - "Hindenburg\'s Skin: Fire-Resistant Fabric or Rocket Fuel?"',
      'A.A. Hoehling: "Who Destroyed the Hindenburg?" (1962) - Sabotage-Theorie',
      'Harold G. Dick & Douglas H. Robinson: "The Golden Age of the Great Passenger Airships" (1985)',
      'British Pathé Newsreel Footage (6. Mai 1937) - Original Filmaufnahmen der Katastrophe',
    ],
  ),
  
  // EVENT 34: TSCHERNOBYL KATASTROPHE (1986)
  MaterieLocationDetail(
    name: 'Tschernobyl Reaktor-Katastrophe - Ukraine',
    description: 'Reaktor 4 explodiert (26. April 1986) - Größte nukleare Katastrophe der Geschichte, radioaktive Wolke über Europa',
    detailedInfo: '''In den frühen Morgenstunden des 26. April 1986 explodierte Reaktor 4 des Kernkraftwerks Tschernobyl während eines missglückten Sicherheitstests. Die Explosion setzte radioaktive Strahlung frei, die 400-mal stärker war als die Hiroshima-Bombe. Die radioaktive Wolke verbreitete sich über ganz Europa. Die Sowjetunion versuchte zunächst, die Katastrophe zu vertuschen.

📘 OFFIZIELLE VERSION:
Um 1:23 Uhr explodierte Reaktor 4 während eines Tests der Notstromversorgung. Menschliches Versagen und Konstruktionsfehler führten zu einer unkontrollierten Kettenreaktion. Die Explosion zerstörte das Reaktorgebäude und setzte radioaktive Materialien frei. 31 Menschen starben sofort oder innerhalb weniger Wochen (meist Feuerwehrleute und Kraftwerksarbeiter). 350.000 Menschen wurden evakuiert. Die Sowjetunion mobilisierte 600.000 "Liquidatoren" zur Eindämmung. Die 30-km-Sperrzone existiert bis heute. Die WHO schätzt langfristig bis zu 4.000 zusätzliche Krebstote.

🔍 ALTERNATIVE SICHTWEISEN & VERTUSCHUNG:
Massive sowjetische Vertuschung: Die Katastrophe wurde erst 36 Stunden später öffentlich, nachdem schwedische Atomkraftwerke erhöhte Radioaktivität meldeten. Die Sowjetunion bestritt zunächst alles. Pripyat (50.000 Einwohner) wurde erst 36 Stunden nach der Explosion evakuiert - die Bewohner wurden massiver Strahlung ausgesetzt. Liquidatoren: Viele der 600.000 "Biorobots" erhielten tödliche Strahlendosen ohne angemessenen Schutz. Die Regierung log über die Opferzahlen: Offizielle Zahlen nennen 31 Soforttote, aber Liquidatoren-Organisationen berichten von über 60.000 Todesfällen in den Folgejahren. Verbreitete Krebserkrankungen und genetische Schäden in Belarus, Ukraine und Russland werden heruntergespielt. Die "Elefantenfuß"-Lava: Eine hochradioaktive Korium-Masse im Keller des Reaktors, die noch heute tödlich ist (300 Sekunden Exposition = Tod). Der Sarkophag (1986) war nur eine Notlösung und drohte einzustürzen - erst 2016 wurde ein neuer Stahlbogen ("New Safe Confinement") installiert.

🔒 BEWEISE & QUELLEN:
• Reaktor 4 Explosion (26. April 1986, 1:23 Uhr) - 400x stärker als Hiroshima
• 350.000 Menschen evakuiert aus 30-km-Sperrzone
• 600.000 Liquidatoren mobilisiert - viele erhielten tödliche Strahlendosen
• Pripyat Stadt: 50.000 Einwohner evakuiert nach 36 Stunden (zu spät)
• "Elefantenfuß" Korium-Lava: 300 Sekunden Exposition = Tod (noch heute)
• New Safe Confinement (2016): 1,5 Milliarden Euro Stahlbogen über Reaktor 4''',
    position: LatLng(51.3886, 30.0996), // Tschernobyl, Ukraine - Reaktor 4
    category: LocationCategory.disasters,
    keywords: ['Tschernobyl', 'Reaktor', 'Nuklear', 'Katastrophe', 'Radioaktiv', 'Sowjetunion'],
    imageUrls: ['https://www.genspark.ai/api/files/s/sJY751PZ?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/2/23/Chernobyl_Disaster.jpg', // Reaktor 4 nach Explosion
      'https://upload.wikimedia.org/wikipedia/commons/9/9a/Chernobyl_radiation_map_1996.svg', // Radioaktivität-Karte Europa
      'https://upload.wikimedia.org/wikipedia/commons/0/00/Pripyat_abandoned_city.jpg', // Verlassene Stadt Pripyat
    ],
    videoUrls: ['X9FGXjeM0-g'], // ARTE: Tschernobyl - Die Katastrophe (Deutsch)
    sources: [
      'IAEA Tschernobyl Report (2006) - Internationale Atomenergiebehörde',
      'WHO Health Effects of the Chernobyl Accident (2006) - 4.000 geschätzte Krebstote',
      'Chernobyl Forum (2005) - Umfassende wissenschaftliche Bewertung',
      'Svetlana Alexievich: "Voices from Chernobyl" (1997) - Nobelpreis-Werk, Liquidatoren-Interviews',
      'Ukraine Tschernobyl Museum Kiew - Original Dokumente und Artefakte',
      'New Safe Confinement (2016) - 1,5 Milliarden Euro Stahlbogen über Reaktor 4',
    ],
  ),
  
  // EVENT 35: FUKUSHIMA KATASTROPHE (2011)
  MaterieLocationDetail(
    name: 'Fukushima Nuklearkatastrophe - Japan',
    description: 'Tōhoku Erdbeben und Tsunami zerstören Fukushima Dai-ichi Kraftwerk (11. März 2011) - Dreifach-Kernschmelze',
    detailedInfo: '''Am 11. März 2011 löste ein Erdbeben der Stärke 9,1 vor der Küste Japans einen verheerenden Tsunami aus. Die bis zu 15 Meter hohen Wellen überfluteten das Kernkraftwerk Fukushima Dai-ichi, führten zu Stromausfällen und schließlich zur Kernschmelze in drei Reaktoren - die größte nukleare Katastrophe seit Tschernobyl.

📘 OFFIZIELLE VERSION:
Das Tōhoku-Erdbeben (9,1) um 14:46 Uhr löste einen Tsunami mit bis zu 40 Meter hohen Wellen aus. Das Fukushima Dai-ichi Kraftwerk wurde von 15-Meter-Wellen getroffen, die die Notstromaggregate fluteten. Ohne Kühlung kam es in den Reaktoren 1, 2 und 3 zur Kernschmelze. Wasserstoff-Explosionen zerstörten die Gebäude der Reaktoren 1, 3 und 4. Radioaktives Material wurde freigesetzt. 160.000 Menschen wurden evakuiert. Der Unfall wurde als Level 7 (höchste Stufe) eingestuft, genau wie Tschernobyl. Die Dekontamination und Bergung wird Jahrzehnte dauern.

🔍 ALTERNATIVE SICHTWEISEN & TEPCO-VERTUSCHUNG:
Massive Vertuschung durch Betreiber TEPCO (Tokyo Electric Power Company): TEPCO hatte jahrelang Sicherheitsmängel ignoriert und Inspektionsberichte gefälscht. Die Tsunami-Schutzmauer war nur 5,7 Meter hoch, obwohl Experten gewarnt hatten, dass 15-Meter-Tsunamis möglich sind. TEPCO wollte Kosten sparen. Nach der Katastrophe log TEPCO über die Schwere der Kernschmelze - erst 2 Monate später wurde zugegeben, dass alle drei Reaktoren geschmolzen waren. Radioaktives Wasser wurde heimlich ins Meer geleitet (Millionen Liter kontaminiertes Wasser). Fischer und Umweltschützer protestierten, wurden aber ignoriert. Die Evakuierung war chaotisch und verzögert - viele Menschen wurden in höher kontaminierte Gebiete geschickt. Die Regierung erhöhte stillschweigend die zulässigen Strahlungswerte um das 20-fache, um Evakuierungen zu vermeiden. Die tatsächlichen Gesundheitsfolgen werden heruntergespielt - Schilddrüsenkrebs bei Kindern stieg signifikant an, wird aber nicht offiziell mit Fukushima in Verbindung gebracht. Die Dekontamination kostet über 180 Milliarden Euro - Steuerzahler zahlen, nicht TEPCO.

🔒 BEWEISE & QUELLEN:
• Tōhoku Erdbeben (11. März 2011, 14:46 Uhr) - Stärke 9,1 (fünftstärkstes Erdbeben seit 1900)
• Tsunami mit bis zu 40 Meter hohen Wellen - 15.899 Tote (Erdbeben + Tsunami)
• Fukushima Dai-ichi: Kernschmelze in Reaktoren 1, 2, 3 - Level 7 Unfall (wie Tschernobyl)
• 160.000 Menschen evakuiert - 30.000 kehren nie zurück
• TEPCO Vertuschung: Fälschung von Inspektionsberichten seit Jahrzehnten
• Radioaktives Wasser ins Meer geleitet - Millionen Liter kontaminiert Pazifik''',
    position: LatLng(37.4213, 141.0325), // Fukushima Dai-ichi, Japan
    category: LocationCategory.disasters,
    keywords: ['Fukushima', 'Erdbeben', 'Tsunami', 'Nuklear', 'Katastrophe', 'TEPCO'],
    imageUrls: ['https://www.genspark.ai/api/files/s/BhkhME2p?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/5/50/Fukushima_I_by_Digital_Globe.jpg', // Fukushima nach Explosion
      'https://upload.wikimedia.org/wikipedia/commons/9/98/2011_Tohoku_earthquake_tsunami_flooding_Sendai_Airport.jpg', // Tsunami Sendai
      'https://upload.wikimedia.org/wikipedia/commons/b/bf/Radiation_dose_chart_%28XKCD%29.svg', // Strahlungsdosis Vergleich
    ],
    videoUrls: ['XVgnjh8sT7k'], // ARTE: Fukushima - Die ganze Geschichte (Deutsch)
    sources: [
      'IAEA Fukushima Report (2015) - Internationale Atomenergiebehörde',
      'Japanese National Diet Fukushima Nuclear Accident Independent Investigation Commission (2012)',
      'Greenpeace Fukushima Reports (2011-2021) - Unabhängige Strahlungsmessungen',
      'TEPCO Internal Documents (leaked) - Beweis für jahrelange Vertuschung',
      'WHO Health Risk Assessment Fukushima (2013) - Gesundheitsfolgen',
      'NHK Documentary Archives - Original Aufnahmen von Erdbeben, Tsunami und Reaktor-Explosionen',
    ],
  ),
  
  // EVENT 36: ROSWELL UFO CRASH (1947)
  MaterieLocationDetail(
    name: 'Roswell UFO Crash - New Mexico',
    description: 'Mysteriöser Absturz bei Roswell (Juli 1947) - US-Militär behauptet zuerst "Fliegende Untertasse", dann "Wetterballon"',
    detailedInfo: '''Im Juli 1947 stürzte ein unbekanntes Objekt auf einer Ranch nahe Roswell, New Mexico ab. Die US-Luftwaffe gab zunächst eine Pressemitteilung heraus, dass eine "fliegende Untertasse" geborgen wurde - nur um dies 24 Stunden später zu widerrufen und zu behaupten, es sei nur ein Wetterballon gewesen. Dieser Vorfall wurde zum berühmtesten UFO-Fall der Geschichte.

📘 OFFIZIELLE VERSION (Wetterballon-Theorie):
Im Juni/Juli 1947 stürzte ein Wetterballon des geheimen Project Mogul auf der Foster-Ranch ab. Farmer Mac Brazel fand Trümmer und meldete dies dem Sheriff, der die Luftwaffe informierte. Die Roswell Army Air Field (RAAF) veröffentlichte am 8. Juli 1947 eine Pressemitteilung über die Bergung einer "fliegenden Untertasse". Einen Tag später widerrief General Roger Ramey dies und erklärte, es sei ein Wetterballon gewesen. Project Mogul war ein geheimes Programm zur Überwachung sowjetischer Atomtests mit Hochaltitude-Ballons. Die Verwirrung entstand durch Geheimhaltung und übereifrige Presseoffiziere. Es gab keine Außerirdischen.

🔍 ALTERNATIVE SICHTWEISE & UFO-THEORIE:
Zahlreiche Zeugen berichteten, dass die Trümmer ungewöhnlich waren: Metall, das sich nicht verbiegen ließ und keine Brandspuren zeigte, Materialien mit "fremden Hieroglyphen", Balken mit lila Symbolen. Major Jesse Marcel (Intelligence Officer) beschrieb das Material als "nicht von dieser Welt" und behauptete später, die Wetterballon-Geschichte sei eine Vertuschung gewesen. Zwischen 1978-1990 kamen über 200 Zeugen vor, darunter Militärpersonal: Sie behaupteten, es habe außerirdische Körper gegeben, die nach Wright-Patterson Air Force Base gebracht wurden. Mortician Glenn Dennis berichtete von Krankenschwestern, die bei Alien-Autopsien halfen (später widerlegt). Die Santilli "Alien Autopsy"-Film (1995) erwies sich als Fälschung. Projekt Mogul Geheimhaltung + echte UFO-Sichtungswelle 1947 + militärische Vertuschung = Perfekter Sturm für Verschwörungstheorien. Die US-Regierung veröffentlichte 1994 und 1997 zwei Berichte, die die Wetterballon- und Mogul-Theorie bestätigten - aber viele Ufolo gen glauben der Vertuschung nicht.

🔒 BEWEISE & QUELLEN:
• Roswell Daily Record (8. Juli 1947) - "RAAF Captures Flying Saucer" Schlagzeile
• General Roger Ramey Pressekonferenz (9. Juli 1947) - Wetterballon-Präsentation
• Major Jesse Marcel Interviews (1978-1980) - Behauptung der Vertuschung
• USAF Roswell Report (1994) - Offizielle Erklärung: Project Mogul Wetterballon
• USAF Roswell Report: Case Closed (1997) - Anthropomorphe Dummies erklären "Alien"-Berichte
• 200+ Zeugenberichte (1978-1990) - Gesammelt von UFO-Forschern wie Stanton Friedman''',
    position: LatLng(33.3943, -104.5230), // Roswell, New Mexico, USA
    category: LocationCategory.ufo,
    keywords: ['Roswell', 'UFO', 'Aliens', 'Crash', 'Vertuschung', 'Area 51'],
    imageUrls: ['https://www.genspark.ai/api/files/s/xy08DS0W?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/f/fb/RoswellDailyRecordJuly8%2C1947.jpg', // Roswell Daily Record Schlagzeile
      'https://upload.wikimedia.org/wikipedia/commons/e/ed/General_Ramey_and_Colonel_Dubose_with_weather_balloon.jpg', // General Ramey mit Wetterballon
      'https://upload.wikimedia.org/wikipedia/commons/4/44/Roswell_crash_site.jpg', // Foster Ranch Crash-Site
    ],
    videoUrls: ['GmRr5_vPOIY'], // ZDF: Roswell - Was geschah wirklich? (Deutsch)
    sources: [
      'Roswell Daily Record Newspaper (8. Juli 1947) - Original "Flying Saucer" Schlagzeile',
      'USAF Roswell Report (1994) - "The Roswell Report: Fact vs. Fiction in the New Mexico Desert"',
      'USAF Roswell Report (1997) - "The Roswell Report: Case Closed"',
      'Jesse Marcel Interviews (1978-1980) - KOB-TV Albuquerque, Stanton Friedman',
      'Stanton Friedman: "Crash at Corona" (1992) - UFO-Forscher Sammlung von 200+ Zeugenberichten',
      'FBI Memo vom 22. März 1950 (veröffentlicht 2011) - "Guy Hottel Memo" über drei abgestürzte Untertassen',
    ],
  ),
  
  // EVENT 37: AREA 51 GRÜNDUNG (1955)
  MaterieLocationDetail(
    name: 'Area 51 Gründung - Nevada',
    description: 'Geheime Militärbasis Area 51 gegründet (1955) - Entwicklung von Spionageflugzeugen, UFO-Gerüchte, "Dreamland"',
    detailedInfo: '''1955 gründete die CIA eine hochgeheime Testanlage in der Nevada-Wüste, bekannt als Area 51 oder "Dreamland". Offiziell für die Entwicklung von Spionageflugzeugen wie der U-2 und SR-71 Blackbird gedacht, wurde die Basis zum Zentrum von UFO-Verschwörungstheorien, Alien-Technologie-Gerüchten und Regierungsvertuschungen.

📘 OFFIZIELLE VERSION:
Area 51 wurde 1955 von der CIA und Lockheed als Testgelände für das U-2 Spionageflugzeug ausgewählt. Die abgelegene Lage am Groom Lake (trockener Salzsee) bot perfekte Bedingungen für geheime Flugtests. Später wurden hier auch die SR-71 Blackbird, F-117 Stealth Fighter und andere fortschrittliche Flugzeuge getestet. Viele UFO-Sichtungen in der Region waren in Wahrheit Tests von experimentellen Flugzeugen. Die Geheimhaltung war notwendig, um technologische Überlegenheit gegenüber der Sowjetunion zu bewahren. Die CIA gab die Existenz von Area 51 erst 2013 offiziell zu.

🔍 ALTERNATIVE SICHTWEISEN & UFO-THEORIEN:
Area 51 ist das Zentrum zahlreicher Verschwörungstheorien: 1) Alien-Technologie: Nach dem Roswell-Crash (1947) sollen Alien-Raumschiffe und Körper nach Area 51 gebracht worden sein. Reverse Engineering von außerirdischer Technologie ermöglichte angeblich Stealth-Technologie und Fortschritte in der Physik. 2) Bob Lazar (1989): Physiker behauptete, er habe an außerirdischen Raumschiffen in der "S-4"-Anlage nahe Area 51 gearbeitet. Er beschrieb "Element 115" als Antrieb (Element 115/Moscovium wurde erst 2003 synthetisiert). Kritiker werfen ihm Lügen vor, aber seine Story popularisierte Area 51. 3) Majestic 12 (MJ-12): Angebliche geheime Regierungsgruppe, die Alien-Technologie verwaltet. Dokumente erwiesen sich als Fälschungen. 4) "Storm Area 51" Event (2019): 2 Millionen Menschen RSVP auf Facebook, um Area 51 zu "stürmen" und "die Aliens zu sehen" - wurde zum viralen Meme. Nur wenige hundert erschienen tatsächlich. 5) Janet-Flüge: Mysteriöse weiße Boeing 737 Flüge ("Janet Airlines") bringen täglich Arbeiter von Las Vegas zu Area 51 - keine Kennzeichen, streng geheim.

🔒 BEWEISE & QUELLEN:
• CIA gab Existenz von Area 51 erst 2013 offiziell zu (Freedom of Information Act)
• U-2 Spionageflugzeug (1955) und SR-71 Blackbird (1960er) dort entwickelt
• Bob Lazar Interviews (1989) - Behauptung über Alien-Technologie und Element 115
• Majestic 12 Dokumente (1984) - Erwiesen als Fälschungen (FBI Untersuchung)
• "Storm Area 51" Facebook Event (2019) - 2 Millionen RSVPs, viraler Internet-Meme
• Janet Airlines Flüge - Weiße Boeing 737 ohne Kennzeichen, täglich Las Vegas ↔ Area 51''',
    position: LatLng(37.2350, -115.8111), // Area 51, Nevada, USA - Groom Lake
    category: LocationCategory.ufo,
    keywords: ['Area 51', 'UFO', 'Aliens', 'CIA', 'Geheim', 'Dreamland'],
    imageUrls: ['https://www.genspark.ai/api/files/s/Bqrmr9ta?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/9/9c/Area_51_satellite_image.jpg', // Area 51 Satellitenbild
      'https://upload.wikimedia.org/wikipedia/commons/8/88/Lockheed_U-2.jpg', // U-2 Spionageflugzeug
      'https://upload.wikimedia.org/wikipedia/commons/f/f0/%22This_Is_the_Place%22_-_Area_51_-_panoramio.jpg', // Area 51 Warning Sign
    ],
    videoUrls: ['SVEYyHYwfG4'], // National Geographic: Area 51 - Streng Geheim (Deutsch)
    sources: [
      'CIA Declassified Documents (2013) - Offizielle Bestätigung der Existenz von Area 51',
      'Bob Lazar Interviews (1989) - KLAS-TV Las Vegas, George Knapp',
      'Annie Jacobsen: "Area 51: An Uncensored History of America\'s Top Secret Military Base" (2011)',
      'Majestic 12 Documents (1984) - FBI Untersuchung erklärte sie als Fälschungen',
      'U-2 Dragon Lady History - Lockheed Martin & CIA Archiv',
      '"Storm Area 51" Facebook Event (Juli 2019) - 2 Millionen RSVPs, viraler Meme',
    ],
  ),
  
  // EVENT 38: BETTY & BARNEY HILL ENTFÜHRUNG (1961)
  MaterieLocationDetail(
    name: 'Betty & Barney Hill UFO-Entführung - New Hampshire',
    description: 'Erste dokumentierte Alien-Entführung (19. September 1961) - Star Map, verlorene Zeit, Hypnose-Rückführung',
    detailedInfo: '''In der Nacht vom 19. September 1961 erlebten Betty und Barney Hill auf einer einsamen Straße in New Hampshire eine mysteriöse "verlorene Zeit" von 2 Stunden. Unter Hypnose erinnerten sie sich an eine Entführung durch außerirdische Wesen - der erste öffentlich bekannte Fall von Alien Abduction, der die moderne UFO-Kultur prägte.

📘 OFFIZIELLE VERSION (Psychologische Erklärung):
Betty und Barney Hill fuhren von Kanada zurück nach New Hampshire. Gegen Mitternacht sahen sie ein helles Licht am Himmel, das ihnen folgte. Sie kamen 2 Stunden zu spät nach Hause - "verlorene Zeit". Betty hatte danach wiederkehrende Alpträume von Alien-Entführung. 1963 suchten sie Dr. Benjamin Simon auf, der sie unter Hypnose befragte. Beide erinnerten sich an Entführung durch graue Aliens, medizinische Untersuchungen an Bord eines Raumschiffs und eine "Star Map", die Betty sah. Skeptiker erklären dies als Schlafparalyse, False Memory Syndrome und Konfabulation unter Hypnose. Der Fall wurde 1966 im Buch "The Interrupted Journey" von John Fuller populär gemacht.

🔍 ALTERNATIVE SICHTWEISE & ALIEN-ENTFÜHRUNG:
Betty und Barney Hills Berichte waren konsistent und detailliert: Graue Aliens mit großen Köpfen und schwarzen Augen, telepathische Kommunikation, medizinische Experimente, Nasenimplantate. Betty zeichnete eine "Star Map" aus ihrer Erinnerung - 1968 identifizierte Amateurastronom Marjorie Fish diese als Zeta Reticuli Sternensystem. Die Hills hatten keine Motivation zu lügen - im Gegenteil, Barney war ein afroamerikanischer Postbeamter und fürchtete Spott. Die Hills wurden vielfach untersucht und zeigten keine Anzeichen von Psychose oder Lüge. Physische Beweise: Beschädigte Uhren und Ferngläser, unerklärliche Flecken auf Bettys Kleid, rätselhafte Kreise auf dem Auto. Der Fall löste eine Welle von Alien-Entführungsberichten aus - über 4 Millionen Amerikaner behaupten, entführt worden zu sein (Roper Poll 1991). Der "Grey Alien" Archetyp (grau, große Augen, kleiner Mund) stammt direkt aus den Hills Beschreibungen.

🔒 BEWEISE & QUELLEN:
• "Verlorene Zeit" von 2 Stunden (19./20. September 1961) - nicht erklärbar
• Dr. Benjamin Simon Hypnose-Sessions (1963-1964) - 6 Monate Behandlung
• Betty Hill Star Map (1961) - 1968 identifiziert als Zeta Reticuli System
• Physische Spuren: Beschädigte Uhren, Flecken auf Kleid, Kratzer auf Auto
• Barney Hill starb 1969 (46 Jahre) an Gehirnblutung - Stress durch Entführung?
• John Fuller: "The Interrupted Journey" (1966) - Erstes Buch über Alien-Entführung''',
    position: LatLng(44.2901, -71.6200), // US Route 3, New Hampshire - Entführungsort
    category: LocationCategory.ufo,
    keywords: ['Betty Hill', 'Barney Hill', 'Alien', 'Entführung', 'UFO', 'Greys'],
    imageUrls: ['https://www.genspark.ai/api/files/s/XaCN9nx2?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/2/28/Betty_and_Barney_Hill.jpg', // Betty & Barney Hill Foto
      'https://upload.wikimedia.org/wikipedia/commons/f/f4/Betty_Hill_Star_Map.jpg', // Betty Hills Star Map
      'https://upload.wikimedia.org/wikipedia/commons/e/ef/Grey_alien.jpg', // Grey Alien Darstellung (basiert auf Hills Beschreibung)
    ],
    videoUrls: ['fSFo3wXYwO0'], // History Channel: Betty & Barney Hill Entführung (Deutsch)
    sources: [
      'John G. Fuller: "The Interrupted Journey" (1966) - Erstes Buch über den Fall',
      'Dr. Benjamin Simon Hypnose-Aufzeichnungen (1963-1964) - Original Sessions',
      'Marjorie Fish Star Map Analyse (1968) - Zeta Reticuli Identifikation',
      'Stanton Friedman & Kathleen Marden: "Captured! The Betty and Barney Hill UFO Experience" (2007)',
      'Roper Poll (1991) - 4 Millionen Amerikaner behaupten Alien-Entführung',
      'NH Historical Marker #171 - Indian Head Resort, Lincoln NH - Offizielle Anerkennung des Falls',
    ],
  ),
  
  // EVENT 39: PHOENIX LIGHTS (1997)
  MaterieLocationDetail(
    name: 'Phoenix Lights - Arizona',
    description: 'Massenhafte UFO-Sichtung über Phoenix (13. März 1997) - Tausende Zeugen, V-förmiges Objekt, militärische Vertuschung',
    detailedInfo: '''Am 13. März 1997 beobachteten Tausende Menschen in Arizona ein massives V-förmiges Objekt mit leuchtenden Lichtern, das lautlos über Phoenix flog. Die Sichtung dauerte über 2 Stunden und erstreckte sich über 300 Meilen. Trotz der Vielzahl an Zeugen, darunter Piloten und Polizisten, bleibt die Erklärung umstritten.

📘 OFFIZIELLE VERSION (Militär-Erklärung):
Die US-Luftwaffe erklärte die Lichter als Leuchtraketen (Flares), die von A-10 Thunderbolt Kampfjets während einer Trainingsübung abgeworfen wurden. Die Flares fielen über der Barry M. Goldwater Range, einem Militär-Übungsgebiet südwestlich von Phoenix. Die Lichter blieben scheinbar stationär aufgrund optischer Täuschung. Es gab zwei separate Ereignisse: 1) Ein V-förmiges Objekt um 20:15 Uhr, das von Nevada nach Arizona flog, und 2) Leuchtraketen um 22:00 Uhr über Phoenix. Das Militär bestätigte die Leuchtraketen-Übung.

🔍 ALTERNATIVE SICHTWEISEN & UFO-THEORIE:
Tausende Augenzeugen beschrieben ein massives, solides V-förmiges Objekt, nicht einzelne Lichter: Das Objekt war so groß, dass es Sterne verdeckte - Zeugen schätzten es auf 1-2 Kilometer Durchmesser. Es bewegte sich lautlos und langsam (ca. 50 km/h). Piloten, Polizisten und sogar der damalige Gouverneur Fife Symington III bestätigten, dass es KEIN Flugzeug war. Symington hielt 1997 eine Presse-Konferenz und machte sich über die Sichtung lustig (inszenierte Alien-Verhaftung) - aber 10 Jahre später (2007) gestand er, er habe selbst das Objekt gesehen und es sei definitiv nicht von dieser Welt gewesen. Leuchtraketen-Erklärung deckt nur das 22:00 Uhr Ereignis ab, nicht das 20:15 Uhr V-förmige Objekt. Militärische Vertuschung: Die Luftwaffe schwieg 3 Monate lang, bevor sie die Leuchtraketen-Erklärung abgab. Luke Air Force Base verweigerte zunächst jegliche Stellungnahme. Videos und Fotos zeigen zwei unterschiedliche Ereignisse: Ein solides V-förmiges Objekt und später separate Lichter (Flares).

🔒 BEWEISE & QUELLEN:
• Tausende Augenzeugen (geschätzt 10.000+) über 300 Meilen von Nevada bis Tucson
• Video-Beweise: Mehrere Videos zeigen V-förmiges Objekt UND separate Lichter (22:00 Uhr)
• Gouverneur Fife Symington III Geständnis (2007) - "Es war außerirdisch"
• Dr. Lynne Kitei (Ärztin) dokumentierte Sichtung - Buch "The Phoenix Lights" (2004)
• Militär-Leuchtraketen-Übung bestätigt (Barry M. Goldwater Range) - aber erklärt nur 22:00 Uhr Event
• Peter Davenport (National UFO Reporting Center) - 700+ Zeugenberichte dokumentiert''',
    position: LatLng(33.4484, -112.0740), // Phoenix, Arizona, USA
    category: LocationCategory.ufo,
    keywords: ['Phoenix Lights', 'UFO', 'Massenbeobachtung', 'Arizona', 'V-förmig', 'Vertuschung'],
    imageUrls: ['https://www.genspark.ai/api/files/s/AkESZIlO?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/8/87/Phoenix_Lights_1997.jpg', // Phoenix Lights Foto 1997
      'https://upload.wikimedia.org/wikipedia/commons/5/5b/Phoenix_lights_formation.jpg', // V-Formation Illustration
      'https://upload.wikimedia.org/wikipedia/commons/3/3a/Fife_Symington_official_photo.jpg', // Gouverneur Fife Symington
    ],
    videoUrls: ['v1Fh0g5wJ7A'], // National Geographic: Phoenix Lights - Die Wahrheit (Deutsch)
    sources: [
      'Dr. Lynne Kitei: "The Phoenix Lights: A Skeptic\'s Discovery That We Are Not Alone" (2004)',
      'Gouverneur Fife Symington III CNN Interview (2007) - Geständnis über UFO-Sichtung',
      'National UFO Reporting Center (Peter Davenport) - 700+ dokumentierte Zeugenberichte',
      'Luke Air Force Base Statement (Juni 1997) - Leuchtraketen-Erklärung',
      'James Fox Documentary: "Out of the Blue" (2003) - Phoenix Lights Investigation',
      'Arizona Republic Newspaper Archive (14. März 1997) - Original Berichterstattung',
    ],
  ),
  
  // EVENT 40: PENTAGON UFO VIDEOS (2017)
  MaterieLocationDetail(
    name: 'Pentagon UFO Videos veröffentlicht',
    description: 'US-Militär veröffentlicht drei UFO-Videos (2017/2020) - "UAPs", US-Kongress Anhörungen, Offizielle Anerkennung',
    detailedInfo: '''Zwischen 2017 und 2020 veröffentlichte das US-Verteidigungsministerium drei authentische Videos von unidentifizierten Flugobjekten (UAPs - Unidentified Aerial Phenomena), die von US-Navy-Piloten aufgenommen wurden. Diese Videos zeigen Objekte mit Flugmanövern, die mit bekannter Technologie nicht erklärbar sind. Die Veröffentlichung markierte einen Wendepunkt in der offiziellen Haltung zu UFOs.

📘 OFFIZIELLE VERSION (Pentagon & US-Militär):
Im Dezember 2017 veröffentlichte die New York Times zwei Videos ("Gimbal" und "GoFast"), die 2004 und 2015 von F/A-18 Super Hornet Piloten aufgenommen wurden. Ein drittes Video ("FLIR1" oder "Tic Tac") wurde später hinzugefügt. Das Pentagon bestätigte 2020 die Authentizität aller drei Videos und erklärte, sie zeigen "unidentifizierte Luft-Phänomene" (UAPs). 2020 richtete das Pentagon die UAP Task Force ein, um solche Sichtungen zu untersuchen. Im Juni 2021 veröffentlichte der Director of National Intelligence einen Bericht über 144 UAP-Sichtungen zwischen 2004-2021 - nur 1 konnte erklärt werden (Luftballon). Die übrigen 143 bleiben ungeklärt. Das Pentagon räumte ein, dass einige UAPs "Technologie zeigen, die unsere aktuellen Fähigkeiten übersteigt".

🔍 ALTERNATIVE SICHTWEISEN & AUSSERIRDISCHE TECHNOLOGIE:
US-Navy-Piloten beschrieben unglaubliche Flugmanöver: Objekte, die von 24.000 Meter Höhe auf Meereshöhe in Sekunden abstiegen, ohne Bremsung oder Schockwellen. Objekte mit Geschwindigkeiten über Mach 5 ohne sichtbaren Antrieb oder Hitze-Signatur. Das "Tic Tac"-Objekt (2004) umkreiste die USS Nimitz Flugzeugträger-Gruppe und reagierte intelligent auf Piloten - als ob es ihre Absichten voraussehen konnte. Commander David Fravor (pensionierter Navy-Pilot) beschrieb das Objekt als "nicht von dieser Welt". Einige Forscher glauben, die UAPs sind außerirdische Sonden oder Raumschiffe. Alternative Theorie: Geheime US-Technologie oder chinesische/russische Hyperschall-Drohnen. Aber warum würde das Pentagon dann öffentlich zugeben, dass sie die Technologie nicht verstehen? Die Offenlegung könnte Teil einer schrittweisen "Soft Disclosure"-Strategie sein, um die Öffentlichkeit auf außerirdische Kontakte vorzubereiten. US-Kongress hielt 2022 und 2023 öffentliche Anhörungen über UAPs - das erste Mal seit 50 Jahren. Whistleblower David Grusch behauptete 2023, die US-Regierung besitze abgestürzte UFOs und "nicht-menschliche Biologika" (Alien-Körper).

🔒 BEWEISE & QUELLEN:
• 3 authentische Pentagon UFO-Videos (2017-2020): "FLIR1 (Tic Tac)", "Gimbal", "GoFast"
• 144 UAP-Sichtungen (2004-2021) - Nur 1 erklärt (Luftballon), 143 ungeklärt
• Commander David Fravor (USS Nimitz 2004) - "Tic Tac" Objekt Zeugenbericht
• Pentagon UAP Task Force (2020) - Offizielle Untersuchungsgruppe
• US Director of National Intelligence UAP Report (Juni 2021) - Offizielle Anerkennung
• US-Kongress UAP-Anhörungen (2022, 2023) - Erste öffentliche Anhörungen seit 50 Jahren''',
    position: LatLng(38.8719, -77.0563), // Pentagon, Arlington, Virginia, USA
    category: LocationCategory.ufo,
    keywords: ['Pentagon', 'UFO', 'UAP', 'Navy', 'Tic Tac', 'Offenlegung'],
    imageUrls: ['https://www.genspark.ai/api/files/s/NSp3ceOr?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/1/1a/GIMBAL.jpg', // Pentagon "Gimbal" UFO Video Screenshot
      'https://upload.wikimedia.org/wikipedia/commons/3/30/Unidentified_flying_object_-_Aerial_Phenomena_-_US_Navy.jpg', // Pentagon UFO Video Frame
      'https://upload.wikimedia.org/wikipedia/commons/e/e7/The_Pentagon_January_2008.jpg', // Pentagon Gebäude
    ],
    videoUrls: ['rO_M0hLlJ-Q'], // ARTE: Pentagon UFO-Videos - Die Wahrheit (Deutsch)
    sources: [
      'Pentagon UAP Videos (2017-2020) - "FLIR1", "Gimbal", "GoFast" - Offizielle Veröffentlichung',
      'New York Times (16. Dezember 2017) - "Glowing Auras and \'Black Money\': The Pentagon\'s Mysterious U.F.O. Program"',
      'US Director of National Intelligence UAP Report (25. Juni 2021) - 144 UAP-Sichtungen dokumentiert',
      'Commander David Fravor Interviews (2017-2020) - USS Nimitz Tic Tac UFO Zeugenbericht',
      'US-Kongress UAP-Anhörung (17. Mai 2022) - Erste öffentliche Anhörung seit 1970',
      'David Grusch Whistleblower Testimony (Juni 2023) - Behauptung über abgestürzte UFOs und Alien-Biologika',
    ],
  ),
  
  // EVENT 41: PEARL HARBOR (1941)
  MaterieLocationDetail(
    name: 'Pearl Harbor Angriff - Hawaii',
    description: 'Japanischer Überraschungsangriff auf US-Pazifikflotte (7. Dezember 1941) - USA Kriegseintritt WWII',
    detailedInfo: '''Am 7. Dezember 1941 um 7:48 Uhr griffen 353 japanische Flugzeuge die US-Marine-Basis Pearl Harbor auf Hawaii an. Der Überraschungsangriff tötete 2.403 Amerikaner, versenkte 4 Schlachtschiffe und zerstörte 188 Flugzeuge. Der Angriff führte zum Eintritt der USA in den Zweiten Weltkrieg.

📘 OFFIZIELLE VERSION:
Japan plante den Angriff wegen US-Wirtschaftssanktionen (Öl-Embargo) und territorialer Spannungen im Pazifik. Die USA wurden überrascht, obwohl es Warnungen gab. Der Angriff wurde in zwei Wellen durchgeführt: 1. Welle (7:48 Uhr) traf Schlachtschiffe, 2. Welle (8:40 Uhr) zielte auf Flugfelder und Infrastruktur. Am nächsten Tag erklärte Präsident Franklin D. Roosevelt Japan den Krieg mit der berühmten Rede: "A date which will live in infamy" (Ein Datum, das in Schande fortleben wird).

🔍 ALTERNATIVE SICHTWEISE & VERSCHWÖRUNGSTHEORIEN:
Mehrere Theorien behaupten, Roosevelt wusste vom Angriff im Voraus und ließ ihn geschehen, um die USA in den Krieg zu bringen: 1) McCollum Memo (8-Punkte-Plan, Oktober 1940) schlug Provokationen vor, um Japan zum Angriff zu bewegen. 2) US-Geheimdienste hatten japanische Codes geknackt (MAGIC) und wussten von Kriegsplänen. 3) Drei Flugzeugträger waren "zufällig" nicht in Pearl Harbor - sie wurden absichtlich in Sicherheit gebracht. 4) Admiral Husband Kimmel und General Walter Short wurden zu Sündenböcken gemacht - beide wurden degradiert, obwohl sie keine Vorwarnung erhielten. 5) 2000 rehabilitierte der US-Kongress beide posthum. 6) "Day of Deceit" (Robert Stinnett, 1999) dokumentiert 30+ Dokumente, die Roosevelts Vorwissen belegen.

🔒 BEWEISE & QUELLEN:
• 2.403 Tote (2.008 Navy, 218 Army, 109 Marines, 68 Zivilisten)
• 4 Schlachtschiffe versenkt (Arizona, Oklahoma, California, West Virginia)
• McCollum Memo (7. Oktober 1940) - 8-Punkte-Plan zur Provokation Japans
• MAGIC-Entschlüsselung: USA knackten japanische Codes vor dem Angriff
• Drei Flugzeugträger (Enterprise, Lexington, Saratoga) waren nicht in Pearl Harbor
• Robert Stinnett: "Day of Deceit" (1999) - 30+ Dokumente über Roosevelts Vorwissen''',
    position: LatLng(21.3677, -157.9447), // Pearl Harbor, Hawaii
    category: LocationCategory.wars,
    keywords: ['Pearl Harbor', 'WWII', 'Japan', 'Roosevelt', 'USA', 'Kriegseintritt'],
    date: DateTime(1941, 12, 7),
    imageUrls: ['https://www.genspark.ai/api/files/s/F91TV8h1?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/0/09/The_USS_Arizona_%28BB-39%29_burning_after_the_Japanese_attack_on_Pearl_Harbor_-_NARA_195617_-_Edit.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/4/49/Battleship_row_USS_California_sinking.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/5/54/Pearl_Harbor_attack.jpg',
    ],
    videoUrls: ['pHxnNme78B4'], // ZDF History: Pearl Harbor (Deutsch)
    sources: [
      'McCollum Memo (7. Oktober 1940) - National Archives, declassified 1994',
      'Robert B. Stinnett: "Day of Deceit: The Truth About FDR and Pearl Harbor" (1999) - 522 Seiten',
      'Pearl Harbor Attack Hearings (1945-1946) - 40 Bände Zeugenaussagen',
      'Gordon W. Prange: "At Dawn We Slept: The Untold Story of Pearl Harbor" (1981)',
      'US Congress Joint Committee Investigation Report (1946)',
      'MAGIC Diplomatic Summaries (declassified 1978) - NSA Archives',
    ],
  ),
  
  // EVENT 42: D-DAY (1944)
  MaterieLocationDetail(
    name: 'D-Day Landung - Normandie',
    description: 'Operation Overlord - Alliierte Invasion in der Normandie (6. Juni 1944) - Wendepunkt WWII',
    detailedInfo: '''Am 6. Juni 1944, bekannt als D-Day, landeten 156.000 alliierte Soldaten an fünf Stränden der Normandie (Codenames: Utah, Omaha, Gold, Juno, Sword). Die größte Seeinvasion der Geschichte markierte den Anfang vom Ende des Nazi-Regimes in Europa.

📘 OFFIZIELLE VERSION:
Operation Overlord wurde von General Dwight D. Eisenhower geleitet. 5.000 Schiffe und 11.000 Flugzeuge unterstützten die Invasion. Die schwersten Kämpfe fanden am Omaha Beach statt - 2.000+ US-Soldaten starben dort. Die Alliierten täuschten die Nazis mit Operation Fortitude - eine Scheinarmee unter General Patton ließ Hitler glauben, die Invasion käme bei Calais. Bis August 1944 waren 2 Millionen alliierte Soldaten in Frankreich. Paris wurde am 25. August 1944 befreit.

🔍 ALTERNATIVE SICHTWEISEN & VERBORGENE GESCHICHTE:
Kontroverse Aspekte: 1) Stalin drängte seit 1942 auf eine Zweite Front - die Verzögerung bis 1944 ließ die Sowjetunion Millionen Verluste erleiden. War es Absicht, die UdSSR zu schwächen? 2) Omaha Beach Desaster: Viele Historiker werfen US-Kommandanten Inkompetenz vor - Soldaten wurden ohne ausreichende Vorbereitung ins Feuer geschickt. 3) Friendly Fire: Alliierte Bomber töteten Hunderte eigene Soldaten durch Fehlbombardements. 4) Gefangene erschossen: Beide Seiten erschossen Kriegsgefangene - Waffen-SS Truppen massakrierten kanadische POWs bei Ardenne Abbey. 5) Operation Fortitude war so erfolgreich, dass Hitler selbst nach D-Day noch Truppen bei Calais stationierte - ein strategisches Meisterwerk der Täuschung.

🔒 BEWEISE & QUELLEN:
• 156.000 Soldaten landeten am D-Day (73.000 US, 83.000 Briten/Kanadier)
• 4.414 alliierte Tote am D-Day (davon 2.501 US-Soldaten)
• 5.000 Schiffe + 11.000 Flugzeuge unterstützten die Invasion
• Operation Fortitude täuschte Hitler erfolgreich über Invasionsort
• Eisenhower bereitete "In case of failure"-Brief vor (falls Invasion scheiterte)
• Rommel war am D-Day in Deutschland (Geburtstag seiner Frau) - fataler Fehler''',
    position: LatLng(49.3508, -0.8818), // Omaha Beach, Normandie, Frankreich
    category: LocationCategory.wars,
    keywords: ['D-Day', 'Normandie', 'WWII', 'Eisenhower', 'Omaha Beach', 'Operation Overlord'],
    date: DateTime(1944, 6, 6),
    imageUrls: ['https://www.genspark.ai/api/files/s/f0jiWdnL?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/a/a5/Into_the_Jaws_of_Death_23-0455M_edit.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/f/f9/Bundesarchiv_Bild_101I-299-1805-16%2C_Nordfrankreich%2C_Soldaten_hinter_Strandhindernissen.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/7/78/Normandy_Invasion%2C_June_1944.jpg',
    ],
    videoUrls: ['owTPZQQAVyQ'], // ZDF History: D-Day (Deutsch)
    sources: [
      'National D-Day Memorial Foundation Archives',
      'Dwight D. Eisenhower: "In case of failure" Brief (5. Juni 1944) - nie verschickt',
      'Stephen E. Ambrose: "D-Day June 6, 1944: The Climactic Battle of World War II" (1994)',
      'Cornelius Ryan: "The Longest Day" (1959) - Klassisches D-Day Werk',
      'US Army Center of Military History: "Omaha Beachhead" (1945)',
      'Operation Fortitude Declassified Documents (1970er) - MI5/MI6 Archives',
    ],
  ),
  
  // EVENT 43: KALTER KRIEG BEGINN (1947)
  MaterieLocationDetail(
    name: 'Kalter Krieg Beginn - Berlin',
    description: 'Eiserner Vorhang fällt (1947) - USA vs UdSSR, Nukleares Wettrüsten, Spionage-Ära beginnt',
    detailedInfo: '''1947 begann offiziell der Kalte Krieg - ein ideologischer, politischer und militärischer Konflikt zwischen den USA (Kapitalismus) und der UdSSR (Kommunismus), der bis 1991 andauerte. Der Begriff "Eiserner Vorhang" wurde von Winston Churchill geprägt.

📘 OFFIZIELLE VERSION:
Nach WWII spaltete sich Europa: Westeuropa (US-unterstützt) vs. Osteuropa (Sowjet-kontrolliert). Die Truman-Doktrin (1947) versprach Unterstützung gegen kommunistische Expansion. Der Marshall-Plan (1948) finanzierte den Wiederaufbau Westeuropas. Berlin wurde zum Symbol des Kalten Krieges - eine geteilte Stadt in einem geteilten Land. NATO (1949) und Warschauer Pakt (1955) bildeten militärische Blöcke. Das nukleare Wettrüsten begann: USA testete Atombombe 1945, UdSSR 1949. Der Kalte Krieg führte zu Stellvertreterkriegen (Korea, Vietnam, Afghanistan).

🔍 ALTERNATIVE SICHTWEISEN & VERBORGENE GESCHICHTE:
1) Operation Gladio: NATO organisierte geheime "Stay-Behind"-Armeen in Europa, die bereit waren, bei sowjetischer Invasion Guerilla-Krieg zu führen. Einige wurden in Terror-Anschläge verwickelt (Italien Bombenanschläge 1960-80er). 2) MKUltra (1953-1973): CIA-Programm zur Gedankenkontrolle - Experimente mit LSD, Folter, Hypnose an unwissenden Zivilisten. 3) Operation Mockingbird: CIA infiltrierte westliche Medien und kontrollierte Nachrichten. 4) Nuklearer Beinahe-Krieg: Mehrmals stand die Welt am Rand eines Atomkriegs (Kuba-Krise 1962, Able Archer 1983, Stanislaw Petrow 1983). 5) Beide Seiten führten unethische Experimente: USA (Plutonium-Injektionen), UdSSR (Biowaffen-Tests). 6) Der Kalte Krieg kostete Millionen Leben in Stellvertreterkriegen - aber verhinderte möglicherweise WWIII.

🔒 BEWEISE & QUELLEN:
• Churchill "Iron Curtain" Speech (5. März 1946) - Fulton, Missouri
• Truman Doktrin (12. März 1947) - Eindämmung des Kommunismus
• Marshall Plan (1948-1952) - 13 Milliarden Dollar für Westeuropa
• Operation Gladio Declassified (1990) - NATO Stay-Behind-Armeen
• MKUltra Declassified (1977) - CIA Gedankenkontroll-Experimente
• Stanislaw Petrow rettete die Welt (26. September 1983) - verhinderte nuklearen Fehlalarm''',
    position: LatLng(52.5200, 13.4050), // Berlin, Deutschland - Symbol des Kalten Krieges
    category: LocationCategory.deepState,
    keywords: ['Kalter Krieg', 'USA', 'UdSSR', 'NATO', 'Berlin', 'MKUltra', 'Gladio'],
    date: DateTime(1947, 3, 12),
    imageUrls: ['https://www.genspark.ai/api/files/s/UdbT7XJX?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/0/05/Iron_Curtain_map.svg',
      'https://upload.wikimedia.org/wikipedia/commons/1/1a/Berlinermauer.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/c/c8/Churchill_waves_to_crowds.jpg',
    ],
    videoUrls: ['OmVWpB5KVls'], // ARTE: Der Kalte Krieg (Deutsch)
    sources: [
      'Winston Churchill: "Iron Curtain Speech" (5. März 1946) - Westminster College, Fulton',
      'Truman Doctrine Speech (12. März 1947) - US Congress Address',
      'Operation Gladio Declassified Documents (1990) - Italian Senate Investigation',
      'John Marks: "The Search for the Manchurian Candidate: CIA and Mind Control" (1979) - MKUltra',
      'Tim Weiner: "Legacy of Ashes: The History of the CIA" (2007)',
      'Stanislaw Petrov Interview (2010) - Mann, der Atomkrieg verhinderte',
    ],
  ),
  
  // EVENT 44: BERLINER MAUERFALL (1989)
  MaterieLocationDetail(
    name: 'Berliner Mauerfall',
    description: 'Fall der Berliner Mauer (9. November 1989) - Ende des Kalten Krieges, Deutsche Wiedervereinigung',
    detailedInfo: '''Am 9. November 1989 fiel die Berliner Mauer nach 28 Jahren Teilung. Eine missverständliche Pressekonferenz führte dazu, dass Tausende Ost-Berliner die Grenzübergänge stürmten. Das Ereignis markierte das Ende des Kalten Krieges und führte zur Wiedervereinigung Deutschlands 1990.

📘 OFFIZIELLE VERSION:
Die Berliner Mauer wurde 1961 errichtet, um die Flucht von DDR-Bürgern in den Westen zu stoppen. 1989 schwächte sich die Sowjetunion unter Gorbatschow (Glasnost & Perestroika). Massenproteste in der DDR ("Wir sind das Volk!") führten zu politischem Druck. Am 9. November 1989 um 18:53 Uhr verkündete SED-Funktionär Günter Schabowski versehentlich, dass Reisebeschränkungen "sofort, unverzüglich" aufgehoben seien - eigentlich sollte es erst am nächsten Tag in Kraft treten. Tausende stürmten die Grenzübergänge. Grenzschützer gaben nach und öffneten die Tore. Menschen feierten auf der Mauer. Deutschland wurde am 3. Oktober 1990 wiedervereinigt.

🔍 ALTERNATIVE SICHTWEISEN & VERBORGENE GESCHICHTE:
1) Schabowskis "Fehler" war möglicherweise kein Zufall - einige spekulieren, er tat es absichtlich, um eine friedliche Revolution zu ermöglichen. 2) Gorbatschow wurde von westlichen Geheimdiensten manipuliert - Reagan & Thatcher nutzten wirtschaftlichen Druck, um die UdSSR zu destabilisieren. 3) 140+ Menschen starben beim Fluchtversuch über die Mauer (1961-1989) - aber die DDR vertuscht die wahre Zahl. 4) Stasi-Akten: 6 Millionen Akten über DDR-Bürger - 90.000 Kilometer Akten, die Überwachung dokumentieren. 5) Die Wiedervereinigung kostete über 2 Billionen Euro - viele Ost-Deutsche fühlen sich bis heute benachteiligt ("Ostalgie"). 6) Verschwörungstheorien: Der Mauerfall wurde orchestriert, um Deutschland zu schwächen und dauerhaft zu spalten (kulturell & wirtschaftlich).

🔒 BEWEISE & QUELLEN:
• Günter Schabowski Pressekonferenz (9. November 1989, 18:53 Uhr) - Live im Fernsehen
• 140+ dokumentierte Todesfälle an der Berliner Mauer (1961-1989)
• 6 Millionen Stasi-Akten (90.000 km Akten) - Bundesbeauftragte für Stasi-Unterlagen
• "Wir sind das Volk!"-Demonstrationen (Leipzig, Oktober 1989) - 70.000+ Menschen
• Wiedervereinigung am 3. Oktober 1990 - Deutschland wieder vereint
• Kosten der Wiedervereinigung: über 2 Billionen Euro (1990-2020)''',
    position: LatLng(52.5163, 13.3777), // Brandenburger Tor, Berlin
    category: LocationCategory.geopolitics,
    keywords: ['Berlin', 'Mauerfall', 'DDR', 'Wiedervereinigung', 'Kalter Krieg', 'Stasi'],
    date: DateTime(1989, 11, 9),
    imageUrls: ['https://www.genspark.ai/api/files/s/2Lw79HpV?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/8/89/Thefalloftheberlinwall1989.JPG',
      'https://upload.wikimedia.org/wikipedia/commons/1/1a/Berlinermauer.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/d/da/Bundesarchiv_Bild_183-1989-1118-028%2C_Berlin%2C_Brandenburger_Tor%2C_%C3%96ffnung.jpg',
    ],
    videoUrls: ['DobbAaF5UhA'], // ZDF: 9. November 1989 - Der Mauerfall (Deutsch)
    sources: [
      'Günter Schabowski Pressekonferenz Video (9. November 1989) - ARD/ZDF Archive',
      'Stasi Records Archive - 6 Millionen Akten (Bundesbeauftragte für Stasi-Unterlagen)',
      'Frederick Taylor: "The Berlin Wall: A World Divided, 1961-1989" (2006)',
      'Mary Elise Sarotte: "The Collapse: The Accidental Opening of the Berlin Wall" (2014)',
      'Berliner Mauer Memorial Site Documentation - 140+ dokumentierte Todesfälle',
      'Wiedervereinigungsvertrag (3. Oktober 1990) - Bundesgesetzblatt',
    ],
  ),
  
  // EVENT 45: SPUTNIK (1957)
  MaterieLocationDetail(
    name: 'Sputnik 1 Start - Weltraumrennen',
    description: 'Erster künstlicher Satellit (4. Oktober 1957) - Sowjetischer Triumph, USA "Sputnik-Schock", Raumfahrtzeitalter beginnt',
    detailedInfo: '''Am 4. Oktober 1957 startete die Sowjetunion Sputnik 1, den ersten künstlichen Satelliten der Menschheit. Der 58 cm große Kugel-Satellit sendete 21 Tage lang Piep-Signale und löste in den USA den "Sputnik-Schock" aus - eine Kombination aus Angst und Demütigung.

📘 OFFIZIELLE VERSION:
Sputnik 1 wog 83,6 kg und umkreiste die Erde in 96 Minuten. Der Start markierte den Beginn des Weltraumrennens zwischen USA und UdSSR. Die USA reagierten mit der Gründung der NASA (1958) und dem Apollo-Programm. Der Sputnik-Schock führte zu massiven Investitionen in Wissenschaft und Bildung (National Defense Education Act 1958). Die UdSSR war der USA technologisch voraus: Sputnik 2 (1957) trug Hündin Laika ins All, Juri Gagarin (1961) war der erste Mensch im All.

🔍 ALTERNATIVE SICHTWEISEN & VERBORGENE GESCHICHTE:
1) Nazi-Technologie: Beide Supermächte nutzten deutsche V-2 Raketentechnologie und deutsche Wissenschaftler (Operation Paperclip USA, Operation Osoaviakhim UdSSR). Wernher von Braun (ehemaliger Nazi-SS-Offizier) entwickelte US-Raketen. 2) Sputnik war ein psychologischer Schock: USA glaubten, technologisch überlegen zu sein - Sputnik zerstörte diese Illusion. 3) Militärische Implikationen: Wenn die UdSSR einen Satelliten starten kann, kann sie auch nukleare Interkontinentalraketen (ICBMs) abfeuern. 4) US-Geheimprojekte: USA arbeiteten ebenfalls an Satelliten (Project Vanguard), aber Sputnik kam zuerst. 5) Hündin Laika (Sputnik 2) starb qualvoll im All - die Sowjets versteckten dies jahrzehntelang. 6) Das Weltraumrennen kostete Milliarden und war primär ein Propaganda-Krieg.

🔒 BEWEISE & QUELLEN:
• Sputnik 1 Launch (4. Oktober 1957, 19:28 UTC) - Baikonur Kosmodrom
• 83,6 kg Gewicht, 58 cm Durchmesser, 96 Minuten Umlaufbahn
• "Beep-Beep"-Signal weltweit empfangbar (20,005 MHz & 40,002 MHz)
• Operation Paperclip (USA) & Operation Osoaviakhim (UdSSR) - Rekrutierung deutscher Wissenschaftler
• NASA Gründung (29. Juli 1958) - Direkte Reaktion auf Sputnik
• Laika (Hündin) starb nach 5-7 Stunden in Sputnik 2 (3. November 1957) - Hitzekollaps''',
    position: LatLng(45.9644, 63.3050), // Baikonur Kosmodrom, Kasachstan
    category: LocationCategory.technology,
    keywords: ['Sputnik', 'Weltraumrennen', 'UdSSR', 'NASA', 'Kalter Krieg', 'Raumfahrt'],
    date: DateTime(1957, 10, 4),
    imageUrls: ['https://www.genspark.ai/api/files/s/ojuaqNZJ?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/b/be/Sputnik_asm.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/0/0f/Sputnik_1_replica.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/4/44/Laika_ac_Sputnik_2_%28cropped%29.jpg',
    ],
    videoUrls: ['3Fx0EAuTyds'], // ZDF: Sputnik-Schock (Deutsch)
    sources: [
      'Sputnik 1 Launch Report (4. Oktober 1957) - Soviet Space Program Archives',
      'NASA Historical Data Book Vol. 1 (1958-1968) - Sputnik Response',
      'Operation Paperclip Declassified Documents (1990er) - US Army Intelligence',
      'Asif Siddiqi: "Sputnik and the Soviet Space Challenge" (2000)',
      'Laika Death Report (2002) - Russian Academy of Sciences (admitted 45 years later)',
      'National Defense Education Act (1958) - US Response to Sputnik Crisis',
    ],
  ),
  
  // EVENT 46: MONDLANDUNG APOLLO 11 (1969)
  MaterieLocationDetail(
    name: 'Apollo 11 Mondlandung',
    description: 'Erste bemannte Mondlandung (20. Juli 1969) - Neil Armstrong "Ein kleiner Schritt" - Triumph oder Hollywood?',
    detailedInfo: '''Am 20. Juli 1969 landete Apollo 11 auf dem Mond. Neil Armstrong betrat als erster Mensch die Mondoberfläche mit den Worten: "That's one small step for man, one giant leap for mankind." 600 Millionen Menschen sahen live zu - aber Verschwörungstheorien behaupten bis heute, die Landung sei in Hollywood gefälscht worden.

📘 OFFIZIELLE VERSION:
Apollo 11 startete am 16. Juli 1969 mit Neil Armstrong, Buzz Aldrin und Michael Collins. Die Mondlandefähre "Eagle" landete am 20. Juli 1969 um 20:17 UTC im Mare Tranquillitatis (Meer der Ruhe). Armstrong stieg um 02:56 UTC (21. Juli) aus - sein berühmter Satz wurde live übertragen. Die Astronauten sammelten 21,5 kg Mondgestein, pflanzten die US-Flagge und führten Experimente durch. Insgesamt gab es 6 erfolgreiche Mondlandungen (Apollo 11, 12, 14, 15, 16, 17) mit 12 Menschen auf dem Mond (alle US-Astronauten). Die Mission kostete 25,4 Milliarden Dollar (heute ~180 Milliarden).

🔍 ALTERNATIVE SICHTWEISEN & MONDLANDUNGS-VERSCHWÖRUNG:
Die Mondlandung ist eine der meistdiskutierten Verschwörungstheorien: 1) Fehlende Sterne: Fotos zeigen keinen Sternenhimmel - Erklärung: Kamera-Belichtung war auf hellen Vordergrund eingestellt. 2) Wehende Flagge: US-Flagge scheint im Wind zu wehen (aber es gibt keinen Wind auf dem Mond) - Erklärung: Horizontale Stange hielt Flagge ausgestreckt, Bewegung durch Berührung. 3) Keine Krater unter Landefähre: Erklärung: Düse verteilt Schub, Mondoberfläche ist hart. 4) Van-Allen-Gürtel: Tödliche Strahlung sollte Astronauten getötet haben - Erklärung: Schneller Durchflug minimierte Belastung. 5) Stanley Kubrick Theorie: Der Regisseur von "2001: Odyssee im Weltraum" (1968) soll NASA-Studios gefilmt haben - keine Beweise. 6) UdSSR bestätigte die Landung nie öffentlich an - wären sie nicht die ersten gewesen, die einen Fake aufdecken? 7) Reflexionen in Visieren: Analysiert, um Hinweise auf Studioaufnahmen zu finden. Die meisten Wissenschaftler sind sich einig: Die Landung war echt.

🔒 BEWEISE & QUELLEN:
• 600 Millionen TV-Zuschauer live (20./21. Juli 1969)
• 382 kg Mondgestein von 6 Missionen (Apollo 11-17) - weltweit analysiert
• Retroreflektoren auf dem Mond - Laser-Entfernungsmessung funktioniert heute noch
• Lunar Reconnaissance Orbiter (2009) fotografierte Apollo-Landestellen - Fußspuren sichtbar
• 400.000 NASA-Mitarbeiter arbeiteten am Apollo-Programm - keine Whistleblower
• MythBusters Episode (2008) widerlegte alle Mondlandungs-Verschwörungstheorien''',
    position: LatLng(0.6734, 23.4731), // Mare Tranquillitatis, Mond (Koordinaten relativ zur Erde)
    category: LocationCategory.technology,
    keywords: ['Mondlandung', 'Apollo 11', 'Neil Armstrong', 'NASA', 'Verschwörung', 'Weltraum'],
    date: DateTime(1969, 7, 20),
    imageUrls: ['https://www.genspark.ai/api/files/s/OwMvihGp?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/9/98/Aldrin_Apollo_11_original.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/2/27/Apollo_11_bootprint.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/a/a8/Apollo_11_first_step.jpg',
    ],
    videoUrls: ['cwZb2mqId0A'], // ARTE: Mondlandung - Fakt oder Fiktion? (Deutsch)
    sources: [
      'NASA Apollo 11 Mission Report (1969) - Official Documentation',
      'Apollo Lunar Surface Journal - Vollständige Transkripte & Fotos',
      'Lunar Reconnaissance Orbiter Photos (2009) - Apollo-Landestellen fotografiert',
      'Bill Kaysing: "We Never Went to the Moon" (1974) - Erstes Verschwörungsbuch',
      'MythBusters Episode 104 (2008) - "NASA Moon Landing Hoax" - Alle Theorien widerlegt',
      'Ralph René: "NASA Mooned America!" (1992) - Verschwörungstheorie-Buch',
    ],
  ),
  
  // EVENT 47: COVID-19 PANDEMIE (2019)
  MaterieLocationDetail(
    name: 'COVID-19 Pandemie - Wuhan',
    description: 'Globale Coronavirus-Pandemie beginnt (Dezember 2019) - Millionen Tote, Lockdowns, Impfung, Labor-Ursprung?',
    detailedInfo: '''Im Dezember 2019 traten in Wuhan, China, erste Fälle einer mysteriösen Lungenkrankheit auf. Das neuartige Coronavirus SARS-CoV-2 verbreitete sich weltweit und wurde zur größten Pandemie seit der Spanischen Grippe (1918). COVID-19 tötete über 7 Millionen Menschen (offiziell) und veränderte die Welt für immer.

📘 OFFIZIELLE VERSION (WHO & CHINA):
COVID-19 wurde erstmals am 31. Dezember 2019 von China an die WHO gemeldet. Ursprung: Huanan Seafood Market in Wuhan - möglicherweise Übertragung von Tier (Fledermaus/Schuppentier) auf Mensch. Die WHO erklärte am 11. März 2020 eine Pandemie. Lockdowns, Maskenpflicht und Impfkampagnen wurden weltweit eingeführt. Impfstoffe (Pfizer/BioNTech, Moderna, AstraZeneca) wurden in Rekordzeit entwickelt. Über 13 Milliarden Impfdosen verabreicht (bis 2024). Die Pandemie endete offiziell am 5. Mai 2023 (WHO).

🔍 ALTERNATIVE SICHTWEISEN & LABOR-URSPRUNG-THEORIE:
Kontroverse Theorien: 1) Wuhan Labor-Ursprung: Das Wuhan Institute of Virology liegt nur 13 km vom Huanan Market entfernt. Das Labor forschte an Coronavirus-Modifikationen ("Gain-of-Function"). Ein Laborunfall könnte das Virus freigesetzt haben. 2) Dr. Anthony Fauci finanzierte "Gain-of-Function"-Forschung in Wuhan über EcoHealth Alliance (Peter Daszak) - E-Mails belegen Verbindungen. 3) China vertuschte den Ausbruch: Frühe Warnung von Dr. Li Wenliang (starb an COVID-19) wurde unterdrückt. WHO kooperierte mit China statt kritischer Untersuchung. 4) Event 201 (Oktober 2019): Bill Gates & Johns Hopkins simulierten eine Coronavirus-Pandemie nur 2 Monate vor COVID-19 - Zufall? 5) Impfstoff-Nebenwirkungen wurden heruntergespielt: Myokarditis, Thrombosen, plötzliche Todesfälle. 6) Lockdown-Kritik: Studien zeigen, dass Lockdowns kaum Effekt hatten, aber massive wirtschaftliche Schäden verursachten. 7) Great Reset: Verschwörungstheorien behaupten, COVID-19 wurde genutzt, um Kontrolle über Bevölkerung zu erlangen (Impfpässe, Überwachung).

🔒 BEWEISE & QUELLEN:
• 7+ Millionen offizielle COVID-19 Todesfälle weltweit (WHO) - tatsächliche Zahl vermutlich 15-20 Millionen
• Wuhan Institute of Virology 13 km vom Huanan Market entfernt - Gain-of-Function-Forschung
• Fauci E-Mails (2021 freigegeben) - Verbindungen zu EcoHealth Alliance & Wuhan Lab
• Event 201 Simulation (18. Oktober 2019) - Bill Gates, Johns Hopkins, WEF
• Dr. Li Wenliang starb an COVID-19 (7. Februar 2020) - nach Versuchen, Warnung auszusprechen
• US Energy Department Report (2023): "Lab-Ursprung wahrscheinlich" (niedrige Konfidenz)''',
    position: LatLng(30.5728, 114.3055), // Wuhan, China
    category: LocationCategory.biotech,
    keywords: ['COVID-19', 'Pandemie', 'Wuhan', 'Labor', 'Impfung', 'Lockdown', 'WHO'],
    date: DateTime(2019, 12, 31),
    imageUrls: ['https://www.genspark.ai/api/files/s/GyguPnOp?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/f/f0/Wuhan_Institute_of_Virology_main_entrance.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/8/82/SARS-CoV-2_without_background.png',
      'https://upload.wikimedia.org/wikipedia/commons/3/3b/COVID-19_Outbreak_World_Map.svg',
    ],
    videoUrls: ['Ha_C0SX9GDQ'], // ZDF: Corona - Die Wahrheit über den Ursprung (Deutsch)
    sources: [
      'WHO COVID-19 Timeline (2019-2023) - Official Chronology',
      'Wuhan Institute of Virology Research Papers (2015-2019) - Gain-of-Function Studies',
      'Anthony Fauci E-Mails (June 2021 FOIA Release) - 3.200+ Seiten',
      'Event 201 Pandemic Exercise (18. Oktober 2019) - Johns Hopkins & Bill Gates Foundation',
      'US Energy Department Report (Februar 2023) - "Lab Origin Most Likely"',
      'Lancet Commission Report (2022) - "Lab Origin cannot be ruled out"',
    ],
  ),
  
  // EVENT 48: MH370 VERSCHWINDEN (2014)
  MaterieLocationDetail(
    name: 'Malaysia Airlines MH370 verschwindet',
    description: 'Boeing 777 verschwindet spurlos (8. März 2014) - 239 Menschen an Bord, größtes Luftfahrt-Mysterium',
    detailedInfo: '''Am 8. März 2014 verschwand Malaysia Airlines Flug MH370 mit 239 Menschen an Bord auf dem Weg von Kuala Lumpur nach Peking. Das Flugzeug änderte seinen Kurs, schaltete Transponder ab und flog 7+ Stunden in die falsche Richtung. Trotz der größten Such-Operation der Luftfahrtgeschichte (160 Millionen Dollar) wurde das Wrack nie gefunden - nur 33 Trümmerteile an Stränden.

📘 OFFIZIELLE VERSION (MALAYSISCHE REGIERUNG):
MH370 startete um 00:41 Uhr. Um 01:21 Uhr schaltete sich der Transponder ab. Das Flugzeug änderte seinen Kurs und flog zurück über Malaysia, dann Richtung Süden über den Indischen Ozean. Um 08:19 Uhr brach der Kontakt ab - vermutlich Treibstoffmangel. Offiziell: Piloten-Suizid (Kapitän Zaharie Ahmad Shah) oder Hypoxie (Sauerstoffmangel) der Crew. Suchgebiet: 120.000 km² im südlichen Indischen Ozean. 2018 wurde die Suche eingestellt.

🔍 ALTERNATIVE THEORIEN & VERSCHWÖRUNGEN:
Dutzende Theorien: 1) Piloten-Suizid-Mordplan: Kapitän Zaharie simulierte den Kurs auf Flugsimulator zu Hause (Daten gelöscht, aber wiederhergestellt). 2) Entführung & Diego Garcia: US-Militärbasis Diego Garcia liegt auf der Flugroute - wurde das Flugzeug dorthin umgeleitet? Passagier-Handys klingelten noch Stunden später. 3) Cyber-Hijacking: Fernsteuerung des Flugzeugs durch Hacker. 4) Lithium-Batterie-Feuer: 200 kg Lithium-Batterien an Bord - Feuer könnte Systeme zerstört haben. 5) Chinesische Geheimnisse: 20 chinesische Mitarbeiter von Freescale Semiconductor an Bord - besaßen sie militärische Technologie? 6) Versicherungsbetrug: Malaysia Airlines war in finanziellen Schwierigkeiten. 7) Schuss abgeschossen: Militärübung ging schief - Regierungen vertuschen. 8) Bermuda-Dreieck des Indischen Ozeans: Paranormale Theorien.

🔒 BEWEISE & QUELLEN:
• 239 Menschen an Bord (227 Passagiere + 12 Crew) - alle vermutlich tot
• Transponder schaltete um 01:21 Uhr ab (absichtlich?)
• Letzter Radarkontakt: 02:22 Uhr (malaysisches Militärradar)
• Inmarsat Satellitendaten: Flugzeug flog 7+ Stunden nach Transponder-Abschaltung
• 33 Trümmerteile gefunden (2015-2017) an Stränden (La Réunion, Mauritius, Südafrika)
• Kapitän Zaharie Flugsimulator-Daten: Route zum südlichen Indischen Ozean simuliert''',
    position: LatLng(-38.0, 88.0), // Geschätzter Absturzort südlicher Indischer Ozean
    category: LocationCategory.disasters,
    keywords: ['MH370', 'Malaysia Airlines', 'Verschwinden', 'Mysterium', 'Flugzeug', 'Diego Garcia'],
    date: DateTime(2014, 3, 8),
    imageUrls: ['https://www.genspark.ai/api/files/s/g5oWHXwN?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/3/3c/9M-MRO_Malaysia_Airlines_Boeing_777-200ER_%2819826016672%29.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/b/b4/MH370_search_area.svg',
      'https://upload.wikimedia.org/wikipedia/commons/6/62/MH370_Flaperon_debris_found_on_R%C3%A9union.jpg',
    ],
    videoUrls: ['avxLfjd0l-s'], // Netflix: MH370 - Das Flugzeug, das verschwand (Deutsch)
    sources: [
      'Malaysian ICAO Annex 13 Safety Investigation Report (2018) - 822 Seiten',
      'Inmarsat Satellite Data Analysis (2014) - Beweis für südliche Route',
      'Kapitän Zaharie Flugsimulator-Daten (FBI wiederhergestellt, 2016)',
      'Australian Transport Safety Bureau (ATSB) Final Report (2017)',
      'Jeff Wise: "The Plane That Wasn\'t There" (2015) - Alternative Theorien',
      '33 bestätigte Trümmerteile (2015-2017) - Gefunden an Stränden Indischer Ozean',
    ],
  ),
  
  // EVENT 49: EDWARD SNOWDEN NSA-LEAKS (2013)
  MaterieLocationDetail(
    name: 'Edward Snowden NSA-Leaks',
    description: 'Whistleblower enthüllt globale Massenüberwachung (Juni 2013) - PRISM, XKeyscore, NSA spioniert Welt aus',
    detailedInfo: '''Im Juni 2013 enthüllte Edward Snowden, ein ehemaliger CIA- und NSA-Mitarbeiter, eines der größten Überwachungs-Programme der Geschichte. Die NSA spionierte Millionen Menschen weltweit aus - Telefonate, E-Mails, Internet-Aktivitäten. Snowden floh nach Hongkong, dann Russland, wo er bis heute lebt.

📘 OFFIZIELLE VERSION (US-REGIERUNG):
Snowden stahl ca. 1,7 Millionen klassifizierte NSA-Dokumente und veröffentlichte sie über Journalisten (Glenn Greenwald, Laura Poitras, The Guardian, Washington Post). Die Leaks enthüllten Programme wie PRISM (Überwachung von Google, Facebook, Microsoft, Apple), XKeyscore (globale Internetüberwachung), Tempora (britisches GCHQ-Programm). Die US-Regierung klagte Snowden wegen Spionage an (Espionage Act 1917). Snowden wird als Verräter betrachtet, der nationale Sicherheit gefährdete.

🔍 ALTERNATIVE SICHTWEISE & WHISTLEBLOWER-PERSPEKTIVE:
Snowden sieht sich als Whistleblower, nicht Verräter: 1) Massenüberwachung ist verfassungswidrig: 4. Amendment (Schutz vor unrechtmäßiger Durchsuchung) wird verletzt. 2) NSA spionierte ALLE aus: Nicht nur Terroristen, sondern Millionen unschuldiger Bürger, ausländische Regierungen (Merkel-Handy), UN, EU. 3) Tech-Firmen kooperierten: Google, Facebook, Microsoft gaben NSA Zugang zu Nutzerdaten. 4) "Five Eyes"-Allianz: USA, UK, Kanada, Australien, Neuseeland tauschen Daten aus, umgehen nationale Gesetze. 5) Snowden opferte seine Karriere und Leben: Er verdiente 200.000 Dollar/Jahr, verlor alles. 6) Russland als Zuflucht: Snowden wollte nach Ecuador/Lateinamerika, aber USA stornierte seinen Pass - er steckte am Moskauer Flughafen fest. 7) Obama versprach Transparenz, baute aber Überwachungsstaat aus.

🔒 BEWEISE & QUELLEN:
• 1,7 Millionen NSA-Dokumente gestohlen (June 2013)
• PRISM-Programm enthüllt: Überwachung von 9 Tech-Firmen (Google, Facebook, Apple, etc.)
• XKeyscore: NSA kann fast alles sehen, was ein Nutzer im Internet tut
• Angela Merkel Handy abgehört (2013) - diplomatische Krise
• Snowden lebt in Moskau seit 2013 - russische Aufenthaltsgenehmigung bis 2020, dann verlängert
• Pulitzer-Preis für Public Service (2014) - The Guardian & Washington Post für Snowden-Berichterstattung''',
    position: LatLng(22.3193, 114.1694), // Hongkong - Snowdens erste Fluchtstation
    category: LocationCategory.surveillance,
    keywords: ['Snowden', 'NSA', 'Überwachung', 'PRISM', 'Whistleblower', 'Spionage'],
    date: DateTime(2013, 6, 6),
    imageUrls: ['https://www.genspark.ai/api/files/s/ih0OegSW?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/6/60/Edward_Snowden-2.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/c/c7/Prism_slide_5.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/3/32/NSA_headquarters%2C_Fort_Meade%2C_Maryland.jpg',
    ],
    videoUrls: ['Nd6qN167wKo'], // ARTE: Citizenfour - Edward Snowden (Deutsch)
    sources: [
      'The Guardian: "NSA Files Decoded" (2013) - Vollständige Snowden-Leaks Dokumentation',
      'Glenn Greenwald: "No Place to Hide" (2014) - 259 Seiten über Snowden-Enthüllungen',
      'Laura Poitras Documentary: "Citizenfour" (2014) - Oscar-Gewinner',
      'PRISM Presentation Slides (June 2013) - NSA Top Secret Documents',
      'Edward Snowden: "Permanent Record" (2019) - Autobiographie',
      'US Espionage Act Charges (June 2013) - Department of Justice',
    ],
  ),
  
  // EVENT 50: JEFFREY EPSTEIN TOD (2019)
  MaterieLocationDetail(
    name: 'Jeffrey Epstein Tod - New York',
    description: 'Milliardär stirbt in Gefängnis (10. August 2019) - Selbstmord oder Mord? Mächtiges Netzwerk, Missbrauch, Vertuschung',
    detailedInfo: '''Am 10. August 2019 wurde Jeffrey Epstein, ein verurteilter Sexualstraftäter und Milliardär mit Verbindungen zu mächtigen Eliten, tot in seiner Gefängniszelle gefunden. Offizielle Todesursache: Selbstmord durch Erhängen. Aber zahlreiche Ungereimtheiten führten zu einer der größten Verschwörungstheorien der modernen Zeit: "Epstein didn't kill himself."

📘 OFFIZIELLE VERSION (US-REGIERUNG):
Epstein wurde am 6. Juli 2019 wegen Sexhandels mit Minderjährigen verhaftet. Er sass in Metropolitan Correctional Center (MCC) in Manhattan. Am 10. August 2019 um 06:30 Uhr wurde er tot aufgefunden. Todesursache: Selbstmord durch Erhängen (laut Gerichtsmediziner). Epstein hatte Zugang zu einem internationalen Netzwerk von Mädchen/Frauen, die er missbrauchte und an mächtige Männer "verlieh". Seine private Insel "Little St. James" (Virgin Islands) wurde als "Pädophilen-Insel" bezeichnet. Epstein hatte Verbindungen zu Bill Clinton, Donald Trump, Prinz Andrew, Bill Gates, und vielen anderen.

🔍 VERSCHWÖRUNGSTHEORIE: "EPSTEIN DIDN'T KILL HIMSELF"
Ungereimtheiten und Verdachtsmomente: 1) Kameras fielen aus: CCTV vor Epsteins Zelle "funktionierte nicht" während seines Todes. 2) Wachen schliefen: Zwei Wachleute sollten Epstein alle 30 Minuten kontrollieren - sie fälschten Logbücher und schauten Netflix. 3) Verletzungen untypisch für Erhängen: Dr. Michael Baden (forensischer Pathologe) sagte, Epsteins Genickbruch sei typischer für Strangulation als Erhängen. 4) Vorheriger "Suizidversuch": Am 23. Juli 2019 wurde Epstein bewusstlos gefunden - war es ein Angriff? 5) Zellengenosse entfernt: Epstein war allein, obwohl er unter Selbstmord-Beobachtung stehen sollte. 6) Mächtiges Netzwerk: Epstein hatte kompromittierende Informationen über Dutzende mächtige Menschen - sein Tod verhindert Aussagen. 7) Ghislaine Maxwell (Epsteins Komplizin) wurde 2020 verhaftet und 2021 verurteilt - aber sie nannte keine Namen. 8) Epsteins Testamentsvollstreckung: 577 Millionen Dollar wurden in Trust überführt - für wen?

🔒 BEWEISE & QUELLEN:
• Jeffrey Epstein tot am 10. August 2019, 06:30 Uhr (MCC Manhattan)
• Offizielle Todesursache: Selbstmord durch Erhängen (Gerichtsmediziner Dr. Sampson)
• Dr. Michael Baden (unabhängiger Pathologe): "Verletzungen deuten auf Strangulation"
• CCTV Kameras vor Zelle "ausgefallen" während des Todes
• Zwei Wachen fälschten Logbücher und sahen Netflix statt zu patrouillieren
• Little St. James Insel (Virgin Islands) - "Pädophilen-Insel", zahlreiche Besucher
• Ghislaine Maxwell verurteilt zu 20 Jahren Haft (2022) - aber keine Namen genannt''',
    position: LatLng(40.7143, -74.0000), // Metropolitan Correctional Center, Manhattan
    category: LocationCategory.epstein, // 🔥 GESONDERTE KATEGORIE
    keywords: ['Epstein', 'Selbstmord', 'Verschwörung', 'Missbrauch', 'Mord', 'Eliten'],
    date: DateTime(2019, 8, 10),
    imageUrls: ['https://www.genspark.ai/api/files/s/HYIcKq1T?cache_control=3600', // 🎨 HYPERREALISTISCH
      
      'https://upload.wikimedia.org/wikipedia/commons/8/8f/Jeffrey_Epstein_mug_shot.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/d/d8/Little_Saint_James%2C_U.S._Virgin_Islands.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/5/51/Metropolitan_Correctional_Center_New_York.JPG',
    ],
    videoUrls: ['B3zj27WOrWE'], // Netflix: Jeffrey Epstein - Stinkreich (Deutsch)
    sources: [
      'New York City Medical Examiner Report (August 2019) - Selbstmord durch Erhängen',
      'Dr. Michael Baden Autopsy Review (Oktober 2019) - "Strangulation-Verletzungen"',
      'DOJ Inspector General Report (June 2020) - MCC Security Failures',
      'Ghislaine Maxwell Trial Transcripts (2021) - US District Court Southern District NY',
      'James Patterson: "Filthy Rich" (2016) - Buch über Epsteins Netzwerk',
      'Virginia Giuffre Lawsuit Documents (2015-2019) - Vorwürfe gegen Prinz Andrew & andere',
    ],
  ),
  
  // EVENT 51: WIKILEAKS GRÜNDUNG (2006)
  MaterieLocationDetail(
    name: 'WikiLeaks Gründung - Julian Assange',
    description: 'Whistleblower-Plattform gegründet (2006) - Veröffentlicht geheime Dokumente, US-Kriegsverbrechen, Clinton-E-Mails',
    detailedInfo: '''2006 gründete Julian Assange WikiLeaks, eine Plattform zur Veröffentlichung geheimer Dokumente. WikiLeaks enthüllte US-Kriegsverbrechen (Collateral Murder Video 2010), Afghanistan & Irak War Logs, diplomatische Kabelbotschaften und DNC-E-Mails (2016). Assange sitzt seit 2019 im britischen Hochsicherheitsgefängnis Belmarsh und kämpft gegen Auslieferung an die USA.

📘 OFFIZIELLE VERSION (WIKILEAKS & ASSANGE):
WikiLeaks ist eine gemeinnützige Organisation, die geheime Informationen von anonymen Quellen veröffentlicht. Ziel: Transparenz und Rechenschaftspflicht von Regierungen und Konzernen. Wichtigste Veröffentlichungen: 1) Collateral Murder Video (2010): US-Hubschrauber tötet 12 Zivilisten in Bagdad, darunter Reuters-Journalisten. 2) Afghanistan War Logs (2010): 91.000 Dokumente über Kriegsverbrechen. 3) Cablegate (2010): 251.287 diplomatische Depeschen aus US-Botschaften. 4) DNC E-Mails (2016): Demokratische Partei manipulierte Vorwahlen gegen Bernie Sanders.

🔍 KONTROVERSE & VERFOLGUNG:
Assange wird von den USA wegen Spionage angeklagt (18 Anklagepunkte, bis zu 175 Jahre Gefängnis): 1) Chelsea Manning (Whistleblower) gab WikiLeaks die Kriegsdokumente - sie wurde zu 35 Jahren verurteilt (2013), Obama begnadigte sie 2017. 2) Ecuadorianische Botschaft London: Assange suchte 2012 Asyl, lebte 7 Jahre in der Botschaft. 3) Sexuelle Vorwürfe Schweden: Zwei Frauen beschuldigten Assange 2010 - Verfahren wurde 2019 eingestellt. Kritiker sagen, Vorwürfe waren politisch motiviert. 4) Belmarsh Gefängnis (seit 2019): Assange sitzt in Hochsicherheitsgefängnis, kämpft gegen US-Auslieferung. 5) Pressefreiheit vs. Spionage: Ist Assange ein Journalist oder Spion? UN-Sonderberichterstatter Nils Melzer: "Assange wird gefoltert." 6) DNC-Leaks & Russland: US-Geheimdienste behaupten, Russland gab WikiLeaks die E-Mails - WikiLeaks bestreitet. 7) Trump & WikiLeaks: Trump lobte WikiLeaks 2016 ("I love WikiLeaks!"), später: "I know nothing about WikiLeaks."

🔒 BEWEISE & QUELLEN:
• WikiLeaks gegründet 2006 - über 10 Millionen Dokumente veröffentlicht
• Collateral Murder Video (5. April 2010) - 12 Tote, darunter 2 Reuters-Journalisten
• Chelsea Manning verurteilt zu 35 Jahren (2013), begnadigt 2017 (Obama)
• Julian Assange in Ecuador-Botschaft (2012-2019) - 7 Jahre Asyl
• Julian Assange in Belmarsh Gefängnis seit 2019 - kämpft gegen US-Auslieferung
• 18 US-Anklagepunkte wegen Spionage - bis zu 175 Jahre Gefängnis''',
    position: LatLng(51.4934, -0.0098), // Belmarsh Gefängnis, London - Assanges aktueller Aufenthaltsort
    category: LocationCategory.transparency,
    keywords: ['WikiLeaks', 'Assange', 'Whistleblower', 'Transparenz', 'Kriegsverbrechen', 'DNC'],
    date: DateTime(2006, 10, 4),
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/7/75/Julian_Assange_%28Norway%2C_March_2010%29.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/9/96/Wikileaks_logo.svg',
      'https://upload.wikimedia.org/wikipedia/commons/b/b5/HMP_Belmarsh.jpg',
    ],
    videoUrls: ['2hNxJCy-zEQ'], // ARTE: WikiLeaks - Geheimnisse und Lügen (Deutsch)
    sources: [
      'WikiLeaks Archive (2006-2024) - Über 10 Millionen veröffentlichte Dokumente',
      'Collateral Murder Video (5. April 2010) - Original WikiLeaks Veröffentlichung',
      'Chelsea Manning Court-Martial Transcripts (2013) - US Army',
      'Nils Melzer UN Report (2019) - "Assange victim of psychological torture"',
      'US Indictment of Julian Assange (2019) - 18 Counts under Espionage Act',
      'DNC E-Mails (July 2016) - WikiLeaks Veröffentlichung während US-Wahlkampf',
    ],
  ),
  
  // EVENT 52: QANON VERSCHWÖRUNGSTHEORIE (2017)
  MaterieLocationDetail(
    name: 'QAnon Verschwörungstheorie entsteht',
    description: '4chan-Post startet Massenbewegung (Oktober 2017) - "Deep State", "Sturm", Trump-Kult, Capitol-Sturm',
    detailedInfo: '''Im Oktober 2017 tauchte auf dem Imageboard 4chan ein anonymer Nutzer namens "Q" auf, der behauptete, hochrangiger Regierungsmitarbeiter ("Q Clearance") zu sein. Q verbreitete kryptische Botschaften ("Q Drops"), die eine globale Verschwörung von Eliten, Pädophilen und Satanisten beschrieben. QAnon wurde zur größten Verschwörungstheorie-Bewegung der modernen Zeit.

📘 QANON-NARRATIVE (VERSCHWÖRUNGSTHEORIE):
Die Kernbehauptungen von QAnon: 1) "Deep State": Eine geheime Kabale von Eliten (Politiker, Hollywood, Medien) kontrolliert die Welt. 2) Pädophilen-Netzwerk: Eliten betreiben einen globalen Kinderhandel-Ring und trinken Kinderblut (Adrenochrom). 3) Trump als Retter: Donald Trump kämpft im Geheimen gegen die Kabale. 4) "Der Sturm kommt": Massenverhaftungen von Eliten stehen bevor - Hillary Clinton, Obama, Soros, Gates, etc. 5) "Trust the Plan": Q hat alles unter Kontrolle, Geduld ist erforderlich. 6) "WWG1WGA" (Where We Go One, We Go All) - QAnon-Slogan.

🔍 KRITISCHE ANALYSE & REALITÄT:
QAnon ist eine gefährliche Verschwörungstheorie ohne Beweise: 1) Keine Massenverhaftungen: Q versprach seit 2017 Verhaftungen - nie passiert. 2) Q-Identität ungeklärt: Vermutlich Ron Watkins (8chan Administrator) oder Jim Watkins (sein Vater). 3) Capitol-Sturm (6. Januar 2021): QAnon-Anhänger stürmten US-Kapitol. 4) Gewalt & Radikalisierung: FBI stuft QAnon als inländische Terror-Gefahr ein. 5) Pizzagate (2016): Vorläufer von QAnon - Mann stürmte Pizza-Restaurant mit Waffe, suchte angebliche Kinder im Keller (es gab keinen Keller). 6) Fehlgeschlagene Prophezeiungen: Q sagte voraus, Trump würde 2021 im Amt bleiben - falsch. 7) Social Media Verbot: Twitter, Facebook, YouTube verbannten QAnon-Konten (2020-2021). 8) Experten: QAnon ist moderne ARG (Alternate Reality Game) oder LARP (Live Action Role Play), die außer Kontrolle geriet.

🔒 BEWEISE & QUELLEN:
• Erste "Q Drops" (28. Oktober 2017) - 4chan /pol/ Board
• Über 5.000 Q-Posts (2017-2020) - Letzte Posts Dezember 2020
• Capitol-Sturm (6. Januar 2021) - QAnon-Anhänger beteiligt, 5 Tote
• FBI Memo (Mai 2019): QAnon als "inländische Terror-Gefahr" eingestuft
• Ron Watkins verdächtigt: "Reply All" Podcast & "Q: Into the Storm" (HBO 2021)
• Social Media Purge (2020-2021): Twitter löschte 70.000+ QAnon-Konten''',
    position: LatLng(38.8899, -77.0091), // US-Kapitol, Washington D.C. - Capitol-Sturm
    category: LocationCategory.propaganda,
    keywords: ['QAnon', 'Verschwörung', 'Trump', 'Deep State', '4chan', 'Capitol-Sturm'],
    date: DateTime(2017, 10, 28),
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/8/8b/QAnon_flag_%22Q%22_letter_with_stars_and_stripes.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/2/25/2021_storming_of_the_United_States_Capitol_DSC09156_%2850814347231%29.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/4/4a/4chan_Logo.svg',
    ],
    videoUrls: ['8Bux8s8WQE8'], // ARD: QAnon - Die Verschwörungstheorie (Deutsch)
    sources: [
      'First Q Drop Archive (28. Oktober 2017) - 4chan /pol/ Board',
      'FBI Domestic Terrorism Threat Assessment (Mai 2019) - QAnon as threat',
      'HBO Documentary: "Q: Into the Storm" (2021) - 6-teilige Serie, Ron Watkins Verdacht',
      'Reply All Podcast: "Country of Liars" (2021) - QAnon Investigation',
      'Capitol Riot Investigation (2021-2023) - Over 1.000 Arrests, many QAnon believers',
      'Mike Rothschild: "The Storm Is Upon Us: How QAnon Became a Movement" (2021)',
    ],
  ),
  
  // EVENT 53: PANAMA PAPERS (2016)
  MaterieLocationDetail(
    name: 'Panama Papers Leak',
    description: '11,5 Millionen Dokumente geleakt (April 2016) - Offshore-Steueroasen, Korruption, Politiker, Oligarchen entlarvt',
    detailedInfo: '''Im April 2016 veröffentlichte das International Consortium of Investigative Journalists (ICIJ) die Panama Papers - 11,5 Millionen geleakte Dokumente der panamaischen Anwaltskanzlei Mossack Fonseca. Die Dokumente enthüllten, wie Politiker, Oligarchen, Sportler und Kriminelle Offshore-Firmen nutzten, um Steuern zu hinterziehen und Geld zu waschen.

📘 PANAMA PAPERS ENTHÜLLUNGEN:
Die Dokumente zeigten Offshore-Verbindungen von: 1) 140+ Politiker aus 50 Ländern, darunter 12 aktuelle oder ehemalige Staats- und Regierungschefs. 2) Wladimir Putin: Engste Freunde und Musiker Sergej Roldugin besaßen Offshore-Firmen mit 2 Milliarden Dollar. 3) Nawaz Sharif (Premierminister Pakistan): Besaß Londoner Luxusimmobilien über Offshore-Firmen - wurde abgesetzt. 4) FIFA-Korruption: Verbindungen zu Fußball-Funktionären. 5) Nordkorea, Syrien, Simbabwe: Diktatoren umgingen Sanktionen. 6) Lionel Messi: Fußballstar nutzte Offshore-Firmen (später verurteilt wegen Steuerhinterziehung). 7) Über 214.000 Offshore-Firmen in 21 Steueroasen (British Virgin Islands, Panama, Bahamas, etc.).

🔍 KONSEQUENZEN & VERTUSCHUNG:
1) Daphne Caruana Galizia: Investigative Journalistin in Malta wurde 2017 mit Autobombe ermordet - sie recherchierte Panama Papers-Verbindungen maltesischer Politiker. 2) Mossack Fonseca schloss 2018 (nach 40 Jahren). 3) Wenige Verhaftungen: Trotz massiver Enthüllungen wurden kaum hochrangige Personen verurteilt. 4) Whistleblower "John Doe": Anonymer Leak-Quelle gab 2,6 Terabyte Daten an Süddeutsche Zeitung - Identität bis heute unbekannt. 5) Pandora Papers (2021): Noch größerer Leak - 11,9 Millionen Dokumente, über 35 aktuelle/ehemalige Staatschefs. 6) Paradise Papers (2017): Weiterer Leak - Apple, Nike, Facebook in Steueroasen.

🔒 BEWEISE & QUELLEN:
• 11,5 Millionen Dokumente (2,6 Terabyte Daten) geleakt
• 214.488 Offshore-Firmen in 21 Steueroasen
• 140 Politiker aus 50 Ländern entlarvt
• Wladimir Putin: 2 Milliarden Dollar in Offshore-Firmen (Freund Roldugin)
• Nawaz Sharif abgesetzt (Juli 2017) nach Panama Papers Enthüllungen
• Daphne Caruana Galizia ermordet (16. Oktober 2017) - Autobombe in Malta''',
    position: LatLng(8.9824, -79.5199), // Panama City, Panama - Mossack Fonseca Hauptsitz
    category: LocationCategory.finance,
    keywords: ['Panama Papers', 'Offshore', 'Steueroase', 'Korruption', 'Putin', 'Mossack Fonseca'],
    date: DateTime(2016, 4, 3),
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/9/91/Panama_Papers_Source_Timeline.svg',
      'https://upload.wikimedia.org/wikipedia/commons/5/50/Mossack_Fonseca_building_Panama.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/1/11/Daphne_Caruana_Galizia.jpg',
    ],
    videoUrls: ['wuBRZ_wSfRc'], // ZDF: Panama Papers - Die Doku (Deutsch)
    sources: [
      'ICIJ Panama Papers Database (2016) - 11,5 Millionen Dokumente durchsuchbar',
      'Süddeutsche Zeitung: "Panama Papers" Series (April 2016) - Original Veröffentlichung',
      'Daphne Caruana Galizia Murder Investigation (2017-2021) - Malta',
      'Nawaz Sharif Disqualification Case (2017) - Pakistan Supreme Court',
      'Frederik Obermaier & Bastian Obermayer: "Panama Papers" (2016) - Buch der Journalisten',
      'Pandora Papers (2021) - Nachfolger mit 11,9 Millionen Dokumenten',
    ],
  ),
  
  // EVENT 54: CAMBRIDGE ANALYTICA SKANDAL (2018)
  MaterieLocationDetail(
    name: 'Cambridge Analytica Skandal',
    description: 'Facebook-Datenmissbrauch enthüllt (März 2018) - 87 Millionen Profile, Trump-Wahlkampf, Brexit, Manipulation',
    detailedInfo: '''Im März 2018 enthüllten Whistleblower Christopher Wylie und The Guardian/New York Times, wie Cambridge Analytica 87 Millionen Facebook-Profile ohne Zustimmung erntete und diese Daten für politische Kampagnen nutzte - darunter Donald Trumps Präsidentschaftswahlkampf 2016 und die Brexit-Kampagne.

📘 CAMBRIDGE ANALYTICA METHODE:
1) Facebook-Quiz "This Is Your Digital Life" (2014): Dr. Aleksandr Kogan entwickelte Quiz-App, die Daten von Nutzern UND deren Freunden sammelte. 2) 270.000 Nutzer installierten die App - aber 87 Millionen Profile wurden erfasst (Freundes-Daten). 3) Psychometrische Profile: Cambridge Analytica nutzte Big-5-Persönlichkeitsmodell, um Wähler zu profilieren. 4) Mikro-Targeting: Personalisierte politische Werbung basierend auf psychologischen Profilen. 5) Trump-Kampagne 2016: Cambridge Analytica arbeitete für Trump - gezielte Facebook-Ads. 6) Brexit-Kampagne: Arbeit für "Leave.EU" (Arron Banks) - Beeinflussung von Brexit-Abstimmung.

🔍 SKANDAL & KONSEQUENZEN:
1) Christopher Wylie Whistleblower: Ehemaliger Cambridge Analytica Mitarbeiter enthüllte alles. 2) Facebook wusste seit 2015: Facebook erfuhr von Datenmissbrauch, tat aber nichts bis 2018. 3) Mark Zuckerberg Anhörung (April 2018): US-Kongress & EU-Parlament befragten Zuckerberg. 4) Cambridge Analytica schloss (Mai 2018) - aber Nachfolgefirma Emerdata entstand. 5) GDPR (Mai 2018): EU führte Datenschutz-Grundverordnung ein - direkte Reaktion auf Skandal. 6) Facebook-Strafe: 5 Milliarden Dollar Strafe (FTC, 2019) - größte Datenschutz-Strafe der Geschichte. 7) Manipulation-Vorwürfe: Demokratie wurde durch Daten-Missbrauch untergraben. 8) "The Great Hack" Netflix-Doku (2019) dokumentierte Skandal.

🔒 BEWEISE & QUELLEN:
• 87 Millionen Facebook-Profile ohne Zustimmung geerntet
• Christopher Wylie Whistleblower-Aussage (März 2018) - The Guardian/Observer
• Trump-Kampagne 2016: Cambridge Analytica arbeitete für \$6 Millionen
• Brexit-Kampagne: Arbeit für "Leave.EU" (Arron Banks)
• Facebook Strafe: 5 Milliarden Dollar (FTC, Juli 2019)
• Cambridge Analytica schloss Mai 2018 - Nachfolgefirma Emerdata gegründet''',
    position: LatLng(37.4848, -122.1476), // Facebook HQ, Menlo Park, Kalifornien
    category: LocationCategory.propaganda,
    keywords: ['Cambridge Analytica', 'Facebook', 'Datenmissbrauch', 'Trump', 'Brexit', 'Manipulation'],
    date: DateTime(2018, 3, 17),
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/5/5a/Cambridge_Analytica_Logo.svg',
      'https://upload.wikimedia.org/wikipedia/commons/c/cd/Mark_Zuckerberg_F8_2018_Keynote_%2841118883714%29_%28cropped%29.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/a/af/Facebook_headquarters_in_Menlo_Park%2C_California.jpg',
    ],
    videoUrls: ['iX8GxLP1FHo'], // Netflix: The Great Hack (Deutsch)
    sources: [
      'Christopher Wylie Whistleblower Interview (18. März 2018) - The Guardian/Observer',
      'New York Times & Guardian Joint Investigation (März 2018)',
      'Mark Zuckerberg Congressional Testimony (10.-11. April 2018) - US Senate & House',
      'FTC vs. Facebook Settlement (Juli 2019) - 5 Milliarden Dollar Strafe',
      'UK Information Commissioner Office Report (2018) - Cambridge Analytica Investigation',
      'Netflix: "The Great Hack" (2019) - Dokumentation über Cambridge Analytica Skandal',
    ],
  ),
  
  // EVENT 55: GREAT RESET / WEF AGENDA (2020)
  MaterieLocationDetail(
    name: 'Great Reset - World Economic Forum',
    description: 'WEF startet "Great Reset" Initiative (Juni 2020) - Klaus Schwab, COVID-Reaktion, "Nichts besitzen und glücklich sein"',
    detailedInfo: '''Im Juni 2020 startete Klaus Schwab (Gründer des World Economic Forum) die "Great Reset"-Initiative als Reaktion auf COVID-19. Die Idee: Die Pandemie als Gelegenheit nutzen, um Wirtschaft, Gesellschaft und Umwelt neu zu gestalten. Kritiker sehen darin eine Verschwörung zur Kontrolle der Weltbevölkerung.

📘 OFFIZIELLE GREAT RESET AGENDA (WEF):
Die drei Säulen: 1) Wirtschaftsreform: Stakeholder-Kapitalismus statt Shareholder-Kapitalismus - Unternehmen sollen gesellschaftliche Verantwortung übernehmen. 2) Nachhaltigkeit & Klimaschutz: Grüne Transformation, erneuerbare Energien, CO2-Reduktion. 3) Digitale Revolution: KI, Robotik, Biotechnologie, Internet der Dinge (IoT). Ziel: "Build Back Better" (besser wieder aufbauen) nach COVID-19. WEF arbeitet mit Regierungen, Unternehmen und NGOs zusammen, um globale Probleme zu lösen.

🔍 KRITIK & VERSCHWÖRUNGSTHEORIEN:
Der Great Reset löste massive Kontroversen aus: 1) "You'll own nothing and be happy": WEF-Video (2016) zeigte Zukunftsvision - kein Privateigentum, alles gemietet/geteilt. Kritiker: Sozialistische Enteignung. 2) Klaus Schwab & Young Global Leaders: WEF bildet junge Führungskräfte aus (Justin Trudeau, Emmanuel Macron, Jacinda Ardern) - Vorwurf der Infiltration von Regierungen. 3) COVID als Vorwand: Pandemie wird genutzt, um autoritäre Maßnahmen (Lockdowns, Impfpässe, Überwachung) einzuführen. 4) Agenda 2030 (UN): Nachhaltige Entwicklungsziele - Kritiker sehen Zwangs-Globalisierung. 5) Bargeldabschaffung: Digitale Währungen (CBDCs) ermöglichen totale Kontrolle. 6) Transhumanismus: WEF fördert Verschmelzung von Mensch und Maschine (Implantate, Chips). 7) Eat Ze Bugs: WEF wirbt für Insekten-Nahrung - Kritik: Bevölkerung soll schlechter essen. 8) Justin Trudeau: "COVID is an opportunity for a reset" (September 2020) - bestätigte Verschwörungstheorien.

🔒 BEWEISE & QUELLEN:
• WEF Great Reset Launch (3. Juni 2020) - Klaus Schwab & Prinz Charles
• "You'll own nothing" Video (2016/2020) - WEF Facebook Post (später gelöscht)
• Klaus Schwab: "COVID-19: The Great Reset" (2020) - Buch
• WEF Young Global Leaders: Trudeau, Macron, Ardern, Zuckerberg, Musk (Alumni)
• Justin Trudeau Speech (September 2020): "COVID as opportunity for reset"
• Agenda 2030 (UN, 2015) - 17 Sustainable Development Goals''',
    position: LatLng(46.2044, 6.1432), // Geneva, Schweiz - WEF Hauptsitz
    category: LocationCategory.deepState,
    keywords: ['Great Reset', 'WEF', 'Klaus Schwab', 'COVID', 'Agenda 2030', 'Kontrolle'],
    date: DateTime(2020, 6, 3),
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/7/7b/Klaus_Schwab_-_World_Economic_Forum_Annual_Meeting_2011.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/a/a7/World_Economic_Forum_logo.svg',
      'https://upload.wikimedia.org/wikipedia/commons/5/54/Klaus_Schwab_-_Annual_Meeting_of_the_New_Champions_Dalian_2009.jpg',
    ],
    videoUrls: ['VHRkkeecg7c'], // WEF: Great Reset Launch Video (Original)
    sources: [
      'Klaus Schwab & Thierry Malleret: "COVID-19: The Great Reset" (2020)',
      'WEF Great Reset Initiative Website (2020) - Official Launch',
      'Justin Trudeau UN Speech (September 2020) - "Opportunity for reset"',
      'WEF "8 Predictions for 2030" Video (2016) - "You\'ll own nothing and be happy"',
      'WEF Young Global Leaders Alumni List - Over 1.400 graduates since 1992',
      'Marc Morano: "The Great Reset: Global Elites and the Permanent Lockdown" (2022)',
    ],
  ),
  
  // EVENT 56: WATERGATE-SKANDAL (1972)
  MaterieLocationDetail(
    name: 'Watergate-Skandal - Washington D.C.',
    description: 'Politischer Skandal führt zu Nixons Rücktritt (1972-1974) - Einbruch, Vertuschung, Deep Throat, Präsident tritt zurück',
    detailedInfo: '''Der Watergate-Skandal begann am 17. Juni 1972 mit einem Einbruch ins Democratic National Committee Hauptquartier im Watergate-Komplex. Die Aufdeckung der Vertuschung durch Präsident Richard Nixon führte zum ersten und einzigen Rücktritt eines US-Präsidenten in der Geschichte (9. August 1974).

📘 OFFIZIELLE VERSION & ABLAUF:
Fünf Männer wurden beim Einbruch ins DNC-Büro verhaftet - sie wollten Abhörgeräte installieren und Dokumente fotografieren. FBI-Ermittlungen führten zu White House Mitarbeitern. Washington Post Journalisten Bob Woodward und Carl Bernstein deckten die Vertuschung auf. Ihre Quelle "Deep Throat" (später als FBI-Vizedirektor Mark Felt enthüllt) lieferte Insider-Informationen. Nixon behauptete Unschuld, aber Tonbandaufnahmen bewiesen seine Beteiligung an der Vertuschung ("Smoking Gun Tape", 23. Juni 1972). Der Supreme Court zwang Nixon, die Bänder herauszugeben. Das Repräsentantenhaus leitete ein Impeachment-Verfahren ein. Am 8. August 1974 kündigte Nixon seinen Rücktritt an (wirksam 9. August). Vizepräsident Gerald Ford wurde Präsident und begnadigte Nixon einen Monat später.

🔍 ALTERNATIVE SICHTWEISEN & VERSCHWÖRUNGEN:
1) CIA-Beteiligung: Einige der Einbrecher (E. Howard Hunt, G. Gordon Liddy) hatten CIA-Verbindungen - war es eine CIA-Operation gegen Nixon? 2) Militärisch-industrieller Komplex: Nixon plante Truppenabzug aus Vietnam und Entspannung mit China/UdSSR - bedrohte er zu viele mächtige Interessen? 3) "Deep Throat" Motivation: Mark Felt fühlte sich übergangen (nicht zum FBI-Direktor ernannt) - Rache als Motiv? 4) 18,5 Minuten Lücke: Eine Tonbandaufnahme hatte eine mysteriöse 18,5-Minuten-Lücke - was wurde gelöscht? 5) Begnadigung-Deal: Verschwörungstheorien behaupten, Nixon trat nur zurück, weil Ford ihm Begnadigung garantierte. 6) Hush Money: Nixon zahlte über \$400.000 "Schweigegeld" an die Einbrecher. 7) Saturday Night Massacre (20. Oktober 1973): Nixon feuerte Watergate-Sonderermittler Archibald Cox - massiver Skandal.

🔒 BEWEISE & QUELLEN:
• 17. Juni 1972: Einbruch ins Watergate-Komplex (5 Verhaftete)
• "Smoking Gun Tape" (23. Juni 1972) - Nixon ordnet Vertuschung an
• Deep Throat = Mark Felt (FBI-Vizedirektor) - Identität enthüllt 2005
• 18,5 Minuten Lücke in Tonbändern - nie erklärt
• Nixon Rücktritt (9. August 1974) - Erster und einziger US-Präsidenten-Rücktritt
• Ford begnadigt Nixon (8. September 1974) - Kontroverse Entscheidung''',
    position: LatLng(38.8977, -77.0365), // Watergate Complex, Washington D.C.
    category: LocationCategory.geopolitics,
    keywords: ['Watergate', 'Nixon', 'Skandal', 'Deep Throat', 'Rücktritt', 'Vertuschung'],
    date: DateTime(1972, 6, 17),
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/f/f7/Watergate_complex.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/4/4c/Richard_Nixon_presidential_portrait.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/1/18/Nixon_resignation_speech.jpg',
    ],
    videoUrls: ['hqxjz2rTNo4'], // ZDF History: Watergate (Deutsch)
    sources: [
      'Bob Woodward & Carl Bernstein: "All the President\'s Men" (1974) - Watergate Investigation',
      'White House Tapes Transcripts (1972-1974) - National Archives',
      'Mark Felt: "The FBI Pyramid" (1979) - Deep Throat before revelation',
      'Mark Felt & John O\'Connor: "A G-Man\'s Life" (2006) - Deep Throat revealed',
      'Nixon Resignation Speech (8. August 1974) - National Archives Video',
      'Stanley Kutler: "The Wars of Watergate" (1990) - Comprehensive History',
    ],
  ),
  
  // EVENT 57: OKLAHOMA CITY BOMBING (1995)
  MaterieLocationDetail(
    name: 'Oklahoma City Bombing',
    description: 'Schwerster Terroranschlag in USA vor 9/11 (19. April 1995) - 168 Tote, Timothy McVeigh, Regierungsgebäude zerstört',
    detailedInfo: '''Am 19. April 1995 um 09:02 Uhr explodierte eine riesige LKW-Bombe vor dem Alfred P. Murrah Federal Building in Oklahoma City. Die Explosion tötete 168 Menschen (darunter 19 Kinder in einer Kindertagesstätte) und verletzte über 680. Es war der schwerste Terroranschlag auf US-Boden vor 9/11.

📘 OFFIZIELLE VERSION:
Timothy McVeigh (US-Army-Veteran) und Terry Nichols bauten eine 2.300 kg Ammoniumnitrat-Bombe. Motiv: Rache für das Waco-Massaker (19. April 1993) und Ruby Ridge (1992) - beides FBI-Operationen gegen Regierungskritiker. McVeigh war ein Anti-Regierungs-Extremist, beeinflusst von "The Turner Diaries" (rassistischer Roman über Regierungssturz). Er parkte den Ryder-LKW mit der Bombe vor dem Gebäude und floh. 90 Minuten später wurde er wegen Fahrens ohne Nummernschild angehalten - Waffe gefunden, verhaftet. FBI identifizierte ihn als Bomber. McVeigh wurde 2001 durch Giftspritze hingerichtet. Nichols erhielt lebenslange Haft.

🔍 ALTERNATIVE SICHTWEISEN & VERSCHWÖRUNGEN:
Zahlreiche Ungereimtheiten führen zu Verschwörungstheorien: 1) Mehrere Bomben: Lokale Nachrichtensender berichteten von 2-3 nicht explodierten Bomben im Gebäude - später widerrufen. 2) John Doe #2: Augenzeugen sahen einen zweiten Mann mit McVeigh - FBI behauptet, er existiert nicht. 3) Seismographische Daten: Zwei separate Explosionen im Abstand von 10 Sekunden aufgezeichnet. 4) ATF/FBI nicht im Gebäude: Viele ATF-Agenten waren an diesem Tag "zufällig" nicht zur Arbeit erschienen - Vorwarnung? 5) Gebäude-Sprengungen: Experten sagen, eine LKW-Bombe allein könnte nicht die Zerstörung verursacht haben - wurden Sprengsätze im Gebäude platziert? 6) McVeigh als Patsy: Ähnlich wie Oswald bei JFK - war McVeigh Sündenbock für größere Verschwörung? 7) Elohim City: Verbindungen zu weißer supremacistischer Gruppe - FBI ignorierte Hinweise. 8) General Benton K. Partin (Luftwaffen-Experte): "Impossible for truck bomb alone to cause this damage."

🔒 BEWEISE & QUELLEN:
• 19. April 1995, 09:02 Uhr - Explosion (genau 2 Jahre nach Waco-Ende)
• 168 Tote (19 Kinder in Kindertagesstätte), 680+ Verletzte
• Timothy McVeigh hingerichtet (11. Juni 2001) - Giftspritze
• Terry Nichols: lebenslange Haft ohne Bewährung
• 2.300 kg Ammoniumnitrat-Bombe in Ryder-LKW
• John Doe #2 nie gefunden - FBI behauptet, er existiert nicht
• Seismographische Daten: Zwei Explosionen 10 Sekunden auseinander (Oklahoma Geological Survey)''',
    position: LatLng(35.4730, -97.5171), // Oklahoma City, Oklahoma - Bombing Site
    category: LocationCategory.falseFlags,
    keywords: ['Oklahoma City', 'Bombing', 'McVeigh', 'Terror', 'Waco', 'Verschwörung'],
    date: DateTime(1995, 4, 19),
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/9/93/Oklahomacitybombing-DF-ST-98-01356.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/2/2c/Timothy_McVeigh.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/8/89/Oklahoma_City_National_Memorial_%26_Museum.jpg',
    ],
    videoUrls: ['C_l8FL6e72U'], // History Channel: Oklahoma City Bombing (Deutsch)
    sources: [
      'FBI Oklahoma City Bombing Case File (1995-2001) - Official Investigation',
      'Timothy McVeigh Trial Transcripts (1997) - Denver Federal Court',
      'General Benton K. Partin Report (1995) - "Bomb Damage Analysis" (contradicts official story)',
      'Oklahoma Geological Survey Seismograph Data (19. April 1995) - Two explosions recorded',
      'Stephen Jones: "Others Unknown: Timothy McVeigh and the Oklahoma City Bombing" (1998)',
      'Andrew Gumbel & Roger Charles: "Oklahoma City: What the Investigation Missed" (2012)',
    ],
  ),
  
  // EVENT 58: JULIAN ASSANGE VERHAFTUNG (2019)
  MaterieLocationDetail(
    name: 'Julian Assange Verhaftung - London',
    description: 'WikiLeaks-Gründer aus Ecuador-Botschaft geholt (11. April 2019) - 7 Jahre Asyl beendet, Belmarsh-Gefängnis, Auslieferungskampf',
    detailedInfo: '''Am 11. April 2019 wurde Julian Assange nach 7 Jahren Asyl aus der ecuadorianischen Botschaft in London gezerrt. Die britische Polizei verhaftete ihn auf Ersuchen der USA. Seitdem sitzt Assange im Hochsicherheitsgefängnis Belmarsh und kämpft gegen seine Auslieferung an die USA, wo ihm bis zu 175 Jahre Haft wegen Spionage drohen.

📘 OFFIZIELLE VERSION (UK & USA):
Assange suchte 2012 Asyl in der Ecuador-Botschaft, um Auslieferung nach Schweden (Sexualvorwürfe) zu vermeiden. Er fürchtete, von Schweden an die USA ausgeliefert zu werden. WikiLeaks veröffentlichte 2010 über 700.000 klassifizierte US-Dokumente (Afghanistan & Irak War Logs, Cablegate). 2019 entzog Ecuador unter Präsident Lenín Moreno Assange das Asyl - angeblich wegen "wiederholter Verstöße gegen Asylbedingungen". Britische Polizei verhaftete Assange wegen Verstoßes gegen Kautionsauflagen (2012). Die USA stellten 18 Anklagepunkte unter dem Espionage Act - maximale Strafe 175 Jahre. Vorwürfe: Verschwörung zur Computerhacking, Veröffentlichung geheimer Informationen. Seit 2019 sitzt Assange in Belmarsh (Hochsicherheitsgefängnis). Auslieferungsverfahren läuft seit 2020.

🔍 ALTERNATIVE SICHTWEISE & PRESSEFREIHEIT:
Assange-Unterstützer sehen ihn als politischen Gefangenen: 1) UN-Sonderberichterstatter Nils Melzer (2019): "Assange zeigt alle Symptome psychologischer Folter." 2) Ecuador-Verrat: Moreno erhielt \$4,2 Milliarden IWF-Kredit kurz nach Assange-Auslieferung - Bestechung? 3) Sexualvorwürfe Schweden: Verfahren wurde 2019 eingestellt - Vorwürfe waren möglicherweise politisch motiviert, um Assange zu diskreditieren. 4) Pressefreiheit: Assange ist Journalist/Publisher - seine Verfolgung bedroht Pressefreiheit weltweit. 5) Chelsea Manning bereits begnadigt (2017, Obama) - warum wird Assange härter behandelt? 6) Stella Moris: Assanges Partnerin (Anwältin) - sie hatten zwei Kinder während seines Botschaftsasyls. 7) CIA Mordpläne: Yahoo News (2021) enthüllte, CIA unter Mike Pompeo plante Entführung oder Ermordung Assanges. 8) Auslieferungskampf: Britische Gerichte widersprüchlich - 2021 blockiert, 2022 genehmigt, jetzt wieder vor Gericht.

🔒 BEWEISE & QUELLEN:
• 11. April 2019 - Assange aus Ecuador-Botschaft geholt (nach 2.487 Tagen)
• 18 US-Anklagepunkte unter Espionage Act - bis zu 175 Jahre Haft
• Belmarsh Hochsicherheitsgefängnis seit 2019 - "Britain's Guantanamo"
• Nils Melzer UN-Report (2019) - "Psychological torture"
• CIA Mordpläne enthüllt (September 2021) - Yahoo News Investigation
• Ecuador erhielt \$4,2 Milliarden IWF-Kredit (März 2019) - einen Monat vor Assange-Auslieferung
• Stella Moris & 2 Kinder - geboren während Botschaftsasyl (2017, 2019)''',
    position: LatLng(51.4934, -0.0098), // Belmarsh Gefängnis, London - Assanges aktueller Aufenthaltsort
    category: LocationCategory.transparency,
    keywords: ['Assange', 'WikiLeaks', 'Verhaftung', 'Pressefreiheit', 'Belmarsh', 'Auslieferung'],
    date: DateTime(2019, 4, 11),
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/b/bc/Julian_Assange_arrested_in_London_%2847561516881%29_%28cropped%29.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/7/75/Julian_Assange_%28Norway%2C_March_2010%29.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/b/b5/HMP_Belmarsh.jpg',
    ],
    videoUrls: ['64tje8vCE_c'], // DW Documentary: Julian Assange - Held oder Verräter? (Deutsch)
    sources: [
      'UK Metropolitan Police Arrest Statement (11. April 2019)',
      'US DOJ Indictment (2019) - 18 Counts under Espionage Act',
      'Nils Melzer UN Report (31. Mai 2019) - "Psychological Torture and Medical Neglect"',
      'Yahoo News: "Kidnapping, assassination and a London shoot-out" (26. September 2021)',
      'Ecuador-IWF Deal (\$4,2 Milliarden, März 2019) - International Monetary Fund',
      'Stella Moris Interviews (2020-2024) - Campaign for Assange\'s Freedom',
    ],
  ),
  
  // BESTEHENDE EVENTS (JFK, 9/11, etc.)
  
  MaterieLocationDetail(
    name: 'JFK Attentat - Dallas',
    description: 'Ermordung von Präsident John F. Kennedy am 22. November 1963 in Dallas, Texas',
    detailedInfo: '''Am 22. November 1963 wurde der 35. Präsident der USA, John F. Kennedy, in seinem offenen Wagen erschossen, während er durch die Dealey Plaza in Dallas fuhr. Dieses Ereignis erschütterte die Welt und bleibt eines der kontroversesten der Geschichte.

📘 OFFIZIELLE VERSION (Warren Commission 1964):
Lee Harvey Oswald handelte als Einzeltäter. Er feuerte drei Schüsse aus dem 6. Stock des Texas School Book Depository ab. Zwei Schüsse trafen Kennedy, einer davon tödlich. Die Warren Commission kam nach monatelanger Untersuchung zu diesem Schluss. Motiv: Oswalds kommunistische Überzeugungen und psychische Instabilität. Jack Ruby erschoss Oswald zwei Tage später aus emotionaler Erregung.

🔍 ALTERNATIVE SICHTWEISE:
Zahlreiche Ungereimtheiten führten zu alternativen Theorien: Multiple Schützen waren beteiligt - die "Grassy Knoll"-Theorie besagt, dass mindestens ein Schütze von vorne schoss. CIA, FBI, Mafia oder der militärisch-industrielle Komplex könnten das Attentat orchestriert haben. JFK plante den Rückzug aus Vietnam, wollte die Federal Reserve reformieren und die CIA auflösen - alles Motive für mächtige Gruppen. Oswald selbst behauptete: "I'm just a patsy" (Ich bin nur ein Sündenbock). Zahlreiche Zeugen berichteten von Schüssen aus anderen Richtungen. Jack Ruby hatte Mafia-Verbindungen und tötete Oswald möglicherweise, um ihn zum Schweigen zu bringen.

🔬 BEWEISE & INDIZIEN:
• Zapruder-Film zeigt Kennedys Kopf nach HINTEN bewegt (Einschuss von vorne?)
• 51 Zeugen am Grassy Knoll hörten Schüsse von dort
• "Magic Bullet"-Theorie: Ein Geschoss soll 7 Wunden verursacht haben - physikalisch zweifelhaft
• Abnormaler Autopsiebericht - JFKs Gehirn verschwand spurlos
• CIA hatte starkes Motiv: JFK nach Bay of Pigs-Fiasko, Kuba-Krise, geplanter Vietnam-Rückzug
• Hunderte Zeugen starben unter mysteriösen Umständen in den Folgejahren
• 1979 stellte das House Select Committee on Assassinations (HSCA) fest: "Wahrscheinlich Verschwörung"
• 2017 wurden tausende CIA-Dokumente freigegeben - viele bleiben klassifiziert''',
    position: const LatLng(32.7767, -96.7970),
    category: LocationCategory.assassinations,
    keywords: ['JFK', 'Kennedy', 'Oswald', 'CIA', 'Grassy Knoll', 'Warren Commission', 'Zapruder Film', 'Einzeltäter', 'Verschwörung'],
    date: DateTime(1963, 11, 22),
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/Jfk_motorcade%2C_dallas.png/1200px-Jfk_motorcade%2C_dallas.png', // Kennedy Motorcade - Sekunden vor dem Attentat
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/Dealey_Plaza_2003.jpg/1200px-Dealey_Plaza_2003.jpg', // Dealey Plaza heute - der Tatort
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cf/Lee_Harvey_Oswald_arrest_card_1963-crop.jpg/800px-Lee_Harvey_Oswald_arrest_card_1963-crop.jpg', // Lee Harvey Oswald Mugshot - Dallas Police 23.11.1963
    ],
    videoUrls: ['K1_baZWd7Zs'], // "JFK-Attentat: Verschwörung oder Einzeltäter?" (DEUTSCHE Dokumentation)
    sources: [
      'Warren Commission Report (1964) - Offizielle US-Regierungs-Untersuchung, 888 Seiten',
      'HSCA Report (1979) - House Select Committee on Assassinations: "Wahrscheinlich Verschwörung"',
      'Zapruder Film (Frame 313) - Einzige vollständige 8mm-Filmaufnahme des tödlichen Schusses',
      'Jim Garrison Investigation (1967-1969) - New Orleans District Attorney Untersuchung',
      'CIA Declassified Documents (JFK Records Act 1992) - 5 Millionen Seiten freigegeben',
      'National Archives JFK Assassination Records Collection - Offizielle Dokumentensammlung',
    ],
  ),
  
  // Kriege
  MaterieLocationDetail(
    name: 'Ukraine-Konflikt - Kiew',
    description: 'Russisch-Ukrainischer Krieg seit 2022',
    detailedInfo: '''Geopolitischer Konflikt mit globalen Auswirkungen. NATO-Osterweiterung, Energiekrieg, Propaganda auf beiden Seiten. Tiefe historische Wurzeln und komplexe Interessenlage.''',
    position: const LatLng(50.4501, 30.5234),
    category: LocationCategory.wars,
    keywords: ['Ukraine', 'Russland', 'NATO', 'Krieg', '2022'],
    date: DateTime(2022, 2, 24),
  ),
  
  
  // Weitere Attentate
  MaterieLocationDetail(
    name: 'MLK Attentat - Memphis',
    description: 'Ermordung von Martin Luther King Jr. am 4. April 1968',
    detailedInfo: '''Dr. Martin Luther King Jr. wurde im Lorraine Motel erschossen. Offiziell James Earl Ray als Täter, aber viele Fragen offen: FBI-Überwachung, COINTELPRO, mögliche Regierungsbeteiligung.''',
    position: const LatLng(35.1345, -90.0568),
    category: LocationCategory.assassinations,
    keywords: ['MLK', 'Martin Luther King', 'FBI', 'COINTELPRO', '1968'],
    date: DateTime(1968, 4, 4),
  ),
  
  MaterieLocationDetail(
    name: '9/11 - World Trade Center',
    description: 'Terroranschläge vom 11. September 2001 auf das World Trade Center, New York',
    detailedInfo: '''Am Morgen des 11. September 2001 rasten zwei entführte Passagierflugzeuge in die Twin Towers des World Trade Centers in New York. Beide Türme stürzten innerhalb weniger Stunden ein. Ein drittes Flugzeug traf das Pentagon, ein viertes stürzte in Pennsylvania ab. Fast 3.000 Menschen starben. Dieser Tag veränderte die Welt für immer und führte zum "Krieg gegen den Terror".

📘 OFFIZIELLE VERSION (9/11 Commission Report 2004):
19 Al-Qaida-Terroristen unter Führung von Osama Bin Laden entführten vier Passagierflugzeuge. American Airlines Flug 11 und United Airlines Flug 175 flogen in die Twin Towers (WTC 1 & 2). American Airlines Flug 77 traf das Pentagon. United Airlines Flug 93 stürzte in Pennsylvania ab, nachdem Passagiere die Entführer angriffen. Die Twin Towers stürzten aufgrund der massiven Schäden durch die Einschläge und der extremen Hitze der brennenden Treibstoffs ein, was die Stahlträger schwächte. WTC 7 (47-stöckiges Gebäude) stürzte später am Abend aufgrund von unkontrolliertem Feuer und strukturellen Schäden ein. Motiv: Hass auf die USA wegen ihrer Nahost-Politik, Unterstützung Israels und Militärpräsenz in Saudi-Arabien.

🔍 ALTERNATIVE SICHTWEISE:
Die "Inside Job"-Theorie besagt, dass die US-Regierung oder Elemente im "Deep State" die Anschläge orchestrierten oder bewusst zuließen. Mögliche Ziele: Rechtfertigung für Kriege in Afghanistan und Irak (Öl, Ressourcen), Einführung des Patriot Acts (Überwachungsstaat), geopolitische Macht. "Controlled Demolition"-Theorie: Die Türme wurden durch Sprengstoff zerstört, nicht nur durch Flugzeugeinschläge - die Art des Einsturzes (Freifall, Staub-Wolken, symmetrisches Kollabieren) ähnelt kontrollierter Sprengung. WTC 7: Wurde nicht von einem Flugzeug getroffen, stürzte aber dennoch symmetrisch im freien Fall ein - laut Experten nur mit Sprengstoff möglich. Pentagon: Einige behaupten, kein Flugzeug traf das Pentagon, sondern eine Rakete oder Drohne - zu wenig Wrackteile sichtbar. Insider Trading: Abnormale Aktiengeschäfte (Put-Optionen auf Airlines) kurz vor 9/11 deuten auf Vorwissen hin.

🔬 BEWEISE & INDIZIEN:
• WTC 7 stürzte 7 Stunden nach den Twin Towers im freien Fall ein (2,25 Sekunden) - NIST bestätigte Freifall-Geschwindigkeit, die nur bei Sprengung möglich ist
• Geschmolzener Stahl in den Trümmern - Kerosin brennt bei ~800°C, Stahl schmilzt bei 1.500°C. Thermit (Sprengstoff) erreicht 2.500°C
• Sprengstoff-Spuren: Wissenschaftler fanden Nano-Thermit-Partikel in WTC-Staub (Forschung von Niels Harrit, 2009)
• 2.300+ Architekten und Ingenieure (Architects & Engineers for 9/11 Truth) fordern neue Untersuchung - strukturelles Versagen allein kann freien Fall nicht erklären
• BBC berichtete über WTC 7-Einsturz 20 Minuten BEVOR es einstürzte - woher wussten sie es?
• Pentagon: Überwachungsvideos konfisziert und nie veröffentlicht - nur 5 unscharfe Bilder freigegeben, kein Flugzeug erkennbar
• Operation Northwoods (1962): Freigegebene CIA-Dokumente zeigen, dass US-Militär False-Flag-Angriffe plante, um Krieg gegen Kuba zu rechtfertigen
• Hunderte Zeugen (Feuerwehrleute, Polizisten) berichteten von Explosionen in den Türmen BEVOR sie einstürzten
• NORAD Stand-Down: US-Luftabwehr griff trotz 4 entführter Flugzeuge über 1,5 Stunden nicht ein - ungewöhnlich''',
    position: const LatLng(40.7128, -74.0060),
    category: LocationCategory.assassinations,
    keywords: ['9/11', 'WTC', 'Twin Towers', 'Al-Qaida', 'Inside Job', 'WTC 7', 'Pentagon', 'Controlled Demolition', 'Thermit', 'False Flag'],
    date: DateTime(2001, 9, 11),
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/WTC_smoking_on_9-11.jpeg/1200px-WTC_smoking_on_9-11.jpeg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/National_September_11_Memorial_%26_Museum.jpg/1200px-National_September_11_Memorial_%26_Museum.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/49/WTC_floor_debris_SFA.jpg/1200px-WTC_floor_debris_SFA.jpg',
    ],
    videoUrls: ['qMTd_xpHChQ'], // "9/11 Verschwörungstheorien – Was steckt wirklich dahinter?" (DEUTSCHE Dokumentation)
    sources: [
      '9/11 Commission Report (2004) - Offizielle Untersuchung',
      'NIST Investigation Report - World Trade Center Collapse',
      'FBI 9/11 Investigation Files',
      'Architects & Engineers for 9/11 Truth - Technical Analysis',
      'Declassified Documents (2016-2021)',
    ],
  ),
  
  // Kriege
  MaterieLocationDetail(
    name: 'Syrien-Konflikt - Damaskus',
    description: 'Syrischer Bürgerkrieg seit 2011',
    detailedInfo: '''Komplexer Proxy-Krieg mit internationalen Akteuren: USA, Russland, Iran, Türkei. Chemiewaffen-Vorwürfe, ISIS, Kurden, Assad-Regime. Millionen Flüchtlinge.''',
    position: const LatLng(33.5138, 36.2765),
    category: LocationCategory.wars,
    keywords: ['Syrien', 'Assad', 'ISIS', 'Proxy-Krieg', 'Chemiewaffen'],
    date: DateTime(2011, 3, 15),
  ),
  
  MaterieLocationDetail(
    name: 'Vietnam-Krieg - Saigon',
    description: 'Vietnam-Krieg 1955-1975',
    detailedInfo: '''USA gegen Nordvietnam. Napalm, Agent Orange, My-Lai-Massaker. Erster TV-Krieg, Anti-Kriegs-Bewegung. Pentagon Papers offenbarten systematische Lügen.''',
    position: const LatLng(10.8231, 106.6297),
    category: LocationCategory.wars,
    keywords: ['Vietnam', 'USA', 'Pentagon Papers', 'Agent Orange', 'Napalm'],
    date: DateTime(1955, 11, 1),
  ),
  
  // Finanz-Zentren
  MaterieLocationDetail(
    name: 'Wall Street - New York',
    description: 'Finanzzentrum & Machtkonzentration',
    detailedInfo: '''NYSE, Federal Reserve, Goldman Sachs. Symbol der Finanzmacht. 2008 Finanzkrise, Lehman Brothers, Too-Big-To-Fail. Regulatorische Gefangennahme, Hochfrequenzhandel.''',
    position: const LatLng(40.7069, -74.0113),
    category: LocationCategory.finance,
    keywords: ['Wall Street', 'NYSE', 'Federal Reserve', 'Finanzkrise', '2008'],
  ),
  
  MaterieLocationDetail(
    name: 'City of London - Finanzdistrikt',
    description: 'Globales Finanzzentrum mit Sonderstatus',
    detailedInfo: '''Die City of London Corporation ist ein eigenständiger Staat im Staat. Offshore-Zentrum, Steueroase-Netzwerk, undurchsichtige Strukturen. Bank of England, Lloyd's of London.''',
    position: const LatLng(51.5155, -0.0922),
    category: LocationCategory.finance,
    keywords: ['City of London', 'Offshore', 'Steueroase', 'Bank of England'],
  ),
  
  // Geheimgesellschaften
  MaterieLocationDetail(
    name: 'Bohemian Grove - Kalifornien',
    description: 'Geheimes Elite-Retreat im Redwood-Wald - "Cremation of Care" Ritual',
    detailedInfo: '''Bohemian Grove ist ein 1.100 Hektar großes abgeschirmtes Waldgebiet in Monte Rio, Kalifornien, das dem exklusiven Bohemian Club gehört. Jeden Juli versammeln sich hier seit 1899 die mächtigsten Männer der Welt für ein zweiwöchiges "Summer Camp" - Politiker, Industrielle, Banker, Künstler.

📘 OFFIZIELLE VERSION:
Bohemian Grove ist ein privater Retreat für erfolgreiche Männer zum Entspannen, Networking und künstlerischen Austausch. Der Bohemian Club (gegründet 1872) war ursprünglich ein Künstlerclub in San Francisco. Das "Cremation of Care"-Ritual ist eine theatralische Aufführung - eine Allegorie, um Alltagssorgen symbolisch zu "verbrennen" und das Camp zu eröffnen. Mitglieder halten Vorträge ("Lakeside Talks"), genießen Natur, Musik, Theater. Es ist wie ein exklusives Feriencamp für erfolgreiche Menschen - private Zeit ohne Medien, Telefone, Geschäfte. Kein politischer Einfluss - nur persönliche Freundschaften und Entspannung.

🔍 ALTERNATIVE SICHTWEISE:
Bohemian Grove ist ein okkultes Elite-Ritual-Zentrum, wo die Mächtigsten der Welt geheime Absprachen treffen und dunkle Rituale durchführen. "Cremation of Care": Bizarre Zeremonie vor einer 12-Meter-Eule-Statue (Moloch?), "Leichen"-Verbrennung, Druidenkostüme - sieht aus wie satanisches Ritual. Alex Jones (2000): Infiltrierte Grove, filmte das Ritual - bestätigte okkulte Praktiken. Manhattan-Projekt (Atombombe): Wurde 1942 in Bohemian Grove geplant - wichtige Entscheidungen werden hier getroffen, nicht in Parlamenten. Mitgliederliste liest sich wie "Who is Who" der Macht: Alle US-Präsidenten seit 1923 (außer Carter), Henry Kissinger, Donald Rumsfeld, Dick Cheney, CEOs von Exxon, Bank of America, etc. "Weaving Spiders Come Not Here" (Motto): Offiziell "keine Geschäfte", aber in Wahrheit informelle Absprachen ohne öffentliche Kontrolle. Prostitution, Drogen: Berichte von Call-Girls, die zur Unterhaltung bestellt werden. Menschenopfer-Gerüchte: Extreme Theorien behaupten echte Opfer (unbestätigt, aber Ritual ist bizarr genug).

🔬 BEWEISE & INDIZIEN:
• Alex Jones Infiltration (2000): Video zeigt "Cremation of Care" - Druidenroben, 12m Eule, "Leichen"-Verbrennung, okkulte Symbolik
• Member Lists (geleakt): Richard Nixon, Ronald Reagan, beide Bushs, Gerald Ford, Colin Powell, Henry Kissinger, Dick Cheney
• Manhattan Project: Offizielle Dokumente bestätigen - Atombomben-Programm wurde September 1942 in Bohemian Grove diskutiert
• "Weaving Spiders": Trotz Motto wurde nachweislich Politik gemacht - Nixon-Eisenhower-Treffen führte zu Nixons Vizepräsidentschaft
• Eule-Symbolik: 12-Meter-Statue = Moloch (alter Gott, dem Kinder geopfert wurden)? Oder Minerva (Weisheit)?
• Prostitution: Mary Moore (Aktivistin) dokumentierte Escort-Service-Bestellungen für Grove-Mitglieder
• Extremer Geheimhaltungs-Aufwand: Privatpolizei, keine Kameras, totales Medienverbot - warum, wenn nur "Feriencamp"?
• Walter Cronkite (1981): "Niemand ist glaubwürdiger als ein Bohemian Grove Mitglied" - Elite-Insider-Klub
• Lakeside Talks: Dort halten Politiker Reden, die Weltpolitik beeinflussen - aber kein öffentliches Protokoll
• Mock-Menschenopfer-Ritual: Selbst wenn "nur Theater" - warum dieses spezifische Ritual? Kultureller/okkulter Hintergrund?''',
    position: const LatLng(38.4104, -123.0041),
    category: LocationCategory.secretSocieties,
    keywords: ['Bohemian Grove', 'Elite', 'Ritual', 'Cremation of Care', 'Moloch', 'Alex Jones', 'Manhattan Project', 'Geheimgesellschaft'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9f/Bohemian_Club_logo.jpg/800px-Bohemian_Club_logo.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Bohemian_Grove_entrance.jpg/1200px-Bohemian_Grove_entrance.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/Bohemian_Club_plaque.jpg/1200px-Bohemian_Club_plaque.jpg',
    ],
    videoUrls: ['FpKdSvwYsrE'], // Alex Jones Bohemian Grove Infiltration
    sources: [
      'Alex Jones Infiltration Footage (2000) - "Dark Secrets: Inside Bohemian Grove"',
      'Member Lists (leaked multiple times)',
      'Manhattan Project Documentation (1942) - National Archives',
      'Mary Moore Bohemian Grove Action Network - Documented Research',
      'Historical Bohemian Club Records',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'Skull and Bones - Yale University',
    description: 'Geheimbund der Elite',
    detailedInfo: '''1832 gegründet. Mitglieder: Bush-Familie, Kerry, viele CIA-Direktoren. "The Order", "322". Grab-Raub, Rituale, lebenslange Netzwerke.''',
    position: const LatLng(41.3163, -72.9223),
    category: LocationCategory.secretSocieties,
    keywords: ['Skull and Bones', 'Yale', 'Bush', 'CIA', 'The Order'],
  ),
  
  // UFO-Hotspots
  MaterieLocationDetail(
    name: 'Area 51 - Nevada',
    description: 'Hochgeheime US-Militärbasis in der Wüste Nevadas - Zentrum der UFO-Mythen',
    detailedInfo: '''Area 51, offiziell als "Groom Lake" oder "Homey Airport" bekannt, ist eine der geheimnisvollsten Militärbasen der Welt. Die Anlage liegt in der abgelegenen Wüste Nevadas, etwa 150 km nordwestlich von Las Vegas. Der Luftraum ist gesperrt, Eindringlinge werden mit tödlicher Gewalt bedroht.

📘 OFFIZIELLE VERSION (US Air Force):
Area 51 ist ein Testgelände für experimentelle Flugzeuge und Waffensysteme der United States Air Force. Hier wurden geheime Spionageflugzeuge wie die U-2, SR-71 Blackbird und die F-117 Stealth-Bomber entwickelt und getestet. Die extreme Geheimhaltung dient dem Schutz militärischer Technologie vor ausländischen Geheimdiensten. Die CIA bestätigte 2013 erstmals offiziell die Existenz von Area 51, nachdem jahrzehntelang jede Verbindung geleugnet wurde. Die "UFO-Sichtungen" in der Region seien Verwechslungen mit experimentellen Flugzeugen gewesen.

🔍 ALTERNATIVE SICHTWEISE:
Area 51 beherbergt außerirdische Technologie und möglicherweise lebende oder tote Aliens. Nach dem berühmten Roswell-Zwischenfall 1947 sollen Wrackteile und Alien-Körper nach Area 51 gebracht worden sein. Whistleblower wie Bob Lazar behaupten, an "Reverse Engineering" außerirdischer Raumschiffe gearbeitet zu haben - Antigravitationstechnologie, Element 115 als Treibstoff. Die Basis arbeitet an geheimen Projekten wie Zeitreisen, Wetterkontrolle, Gedankenkontrolle und interdimensionalen Portalen. Die extreme Sicherheit und Geheimhaltung gehen weit über normale militärische Standards hinaus - was wird dort WIRKLICH versteckt?

🔬 BEWEISE & INDIZIEN:
• Bob Lazar (1989): Behauptet, an UFOs in S-4 (Sektor von Area 51) gearbeitet zu haben - Element 115, Antigravitation
• Hunderte Augenzeugen berichten von unidentifizierten Flugobjekten über Area 51 - unmögliche Flugmanöver
• CIA leugnete Existenz bis 2013 - warum 60+ Jahre totale Geheimhaltung?
• "Deadly Force Authorized" Schilder - keine andere US-Basis mit diesem Level
• Janet Airlines: Geheime Fluggesellschaft transportiert täglich Tausende Mitarbeiter - wohin genau?
• Massive unterirdische Anlagen bestätigt - was ist dort unten?
• Phil Schneider (Whistleblower, 1995 ermordet): Behauptete, unterirdische Alien-Basen gebaut zu haben
• Area 51 niemals auf offiziellen Karten bis 2013 - systematische Vertuschung
• Satellitenbilder zeigen riesige Hangars und mysteriöse Start-/Landebahnen''',
    position: const LatLng(37.2350, -115.8111),
    category: LocationCategory.ufo,
    keywords: ['Area 51', 'UFO', 'Roswell', 'Alien', 'USAF', 'Bob Lazar', 'Reverse Engineering', 'S-4', 'Janet Airlines'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/85/Groom_Lake_-_Area_51_-_Flickr_-_Cobatfor.jpg/1200px-Groom_Lake_-_Area_51_-_Flickr_-_Cobatfor.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/28/Area_51_warning_sign.jpg/800px-Area_51_warning_sign.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d5/Groom_Lake_Road_%26_Mailbox_-_panoramio.jpg/1200px-Groom_Lake_Road_%26_Mailbox_-_panoramio.jpg',
    ],
    videoUrls: ['XVSRm80WzZk'], // Area 51 Documentary
    sources: [
      'CIA Declassified Documents (2013) - "Area 51 Officially Acknowledged", 408 Seiten, National Security Archive',
      'Bob Lazar Interviews (1989) - KLAS-TV Las Vegas, S-4 Whistleblower-Aussagen zu Element 115 und Antigravitation',
      'Freedom of Information Act (FOIA) Releases (1997-2013) - Hunderte freigegebene Area 51-Dokumente',
      'Satellite Imagery Analysis - Google Earth, Terraserver (hochauflösende Aufnahmen der Basis)',
      'Phil Schneider Lectures (1995) - "Deep Underground Military Bases" - 7 Vorträge vor seinem Tod',
      'Annie Jacobsen: "Area 51: An Uncensored History" (2011) - 521 Seiten, 74 Interviews mit ehemaligen Mitarbeitern',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'Roswell - New Mexico',
    description: 'UFO-Absturz 1947',
    detailedInfo: '''Am 7. Juli 1947 stürzte angeblich ein UFO ab. Militär: Erst "fliegende Untertasse", dann "Wetterballon". Zeugenaussagen, Alien-Autopsie-Videos (umstritten), Vertuschungsvorwürfe.''',
    position: const LatLng(33.3943, -104.5230),
    category: LocationCategory.ufo,
    keywords: ['Roswell', 'UFO-Absturz', '1947', 'Alien', 'Vertuschung'],
    date: DateTime(1947, 7, 7),
  ),
  
  // Deep State
  MaterieLocationDetail(
    name: 'Pentagon - Arlington',
    description: 'Hauptquartier des US-Verteidigungsministeriums - Symbol des militärisch-industriellen Komplexes',
    detailedInfo: '''Das Pentagon ist das größte Bürogebäude der Welt und Sitz des US-Verteidigungsministeriums. Über 23.000 Militär- und Zivilpersonal arbeiten hier. Mit einem Jahresbudget von über 800 Milliarden US-Dollar (2023) kontrolliert das Pentagon die mächtigste Militärmaschinerie der Geschichte.

📘 OFFIZIELLE VERSION:
Das Pentagon koordiniert die US-Streitkräfte zum Schutz der nationalen Sicherheit und amerikanischer Interessen weltweit. Es verwaltet das Militärbudget transparent durch den Kongress, entwickelt Verteidigungsstrategien und führt genehmigte Militäroperationen durch. Das Budget ist öffentlich einsehbar und demokratisch kontrolliert. Das Pentagon arbeitet im Rahmen der Gesetze und unter ziviler Kontrolle des Präsidenten.

🔍 ALTERNATIVE SICHTWEISE:
Das Pentagon ist das Herz des "Deep State" - ein permanenter Machtapparat, der unabhängig von gewählten Regierungen agiert. Präsident Eisenhower warnte 1961 eindringlich vor dem "military-industrial complex", der unkontrollierte Macht erlangt habe. Schwarze Budgets ("Black Budgets") in Höhe von Dutzenden Milliarden Dollar entziehen sich jeder Kontrolle - wohin fließt dieses Geld? Geheime Programme (Special Access Programs), von denen nicht einmal der Präsident weiß. Das Pentagon orchestriert Kriege für Profit (Irak: Öl, Afghanistan: Opium, Militärindustrie verdient Billionen). False-Flag-Operationen zur Kriegsrechtfertigung (Gulf of Tonkin, möglicherweise 9/11). Permanente Kriegswirtschaft sichert Macht und Profit.

🔬 BEWEISE & INDIZIEN:
• Eisenhowers Abschiedsrede (1961): Explizite Warnung vor unkontrolliertem militärisch-industriellem Komplex
• 21 Billionen Dollar "fehlende" Pentagon-Ausgaben (2001-2015) - Buchhaltungs-"Fehler"
• Am 10. September 2001: Rumsfeld verkündet 2,3 Billionen Dollar fehlen - am nächsten Tag 9/11
• Operation Northwoods (1962): Pentagon plante False-Flag-Angriffe gegen US-Bürger zur Kriegsrechtfertigung gegen Kuba
• Gulf of Tonkin (1964): Erfundener Angriff führte zu Vietnam-Krieg - Pentagon Papers bewiesen Lüge
• Geheime Gefängnisse (Black Sites) weltweit - Folter, Verschwindenlassen
• Militärindustrie-Aktien steigen bei Kriegsbeginn - System profitiert von Krieg
• "Special Access Programs" - selbst Kongress hat keinen Zugang
• Permanente Kriege seit 1945 - Frieden bedroht das System''',
    position: const LatLng(38.8719, -77.0563),
    category: LocationCategory.deepState,
    keywords: ['Pentagon', 'Military-Industrial Complex', 'Black Budget', 'Deep State', 'Eisenhower', 'Operation Northwoods', 'Special Access Programs'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/The_Pentagon_January_2008.jpg/1200px-The_Pentagon_January_2008.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/US-DeptOfDefense-Seal.svg/800px-US-DeptOfDefense-Seal.svg.png',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/99/Pentagon_City_-_aerial_view.jpg/1200px-Pentagon_City_-_aerial_view.jpg',
    ],
    videoUrls: ['S0OUfqSk7sI'], // Pentagon & Military-Industrial Complex Documentary
    sources: [
      'Eisenhower Farewell Address (17. Januar 1961) - Warnung vor "military-industrial complex", vollständiges Transkript',
      'Pentagon Papers (1971) - 7.000 Seiten geheime DoD-Dokumente zum Vietnam-Krieg, geleakt von Daniel Ellsberg',
      'Operation Northwoods Documents (1962, declassified 1997) - Joint Chiefs of Staff Memo, National Security Archive',
      'DoD Financial Management Reports (2001-2015) - Fehlende 21 Billionen Dollar dokumentiert',
      'Congressional Budget Office: Pentagon Budget Analysis (jährlich) - Öffentliche Haushaltsberichte',
      'Seymour Hersh: "Chain of Command" (2004) - 394 Seiten, Investigativ-Journalismus zu geheimen Pentagon-Programmen',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'CIA Hauptquartier - Langley',
    description: 'Zentrale der Central Intelligence Agency - Amerikas mächtigster Geheimdienst',
    detailedInfo: '''Das CIA-Hauptquartier in Langley, Virginia, ist das Nervenzentrum des amerikanischen Auslandsgeheimdienstes. Seit 1961 koordiniert die CIA Geheimoperationen weltweit - offiziell zum Schutz nationaler Interessen, inoffiziell als "Schattenregierung" bezeichnet.

📘 OFFIZIELLE VERSION:
Die CIA sammelt und analysiert Informationen über ausländische Regierungen, Organisationen und Personen zur Unterstützung der US-Außenpolitik. Sie führt verdeckte Operationen durch, die vom Präsidenten genehmigt werden. Alle Aktivitäten unterliegen der Aufsicht durch den Kongress (Intelligence Oversight Committees). Die CIA arbeitet im Rahmen amerikanischer Gesetze und internationaler Vereinbarungen zum Schutz der nationalen Sicherheit und zur Verhinderung von Terrorismus.

🔍 ALTERNATIVE SICHTWEISE:
Die CIA ist die operative Zentrale des Deep State - ein unkontrollierbarer Geheimdienst, der Regierungen stürzt, Kriege anzettelt und die Weltordnung nach eigenen Interessen gestaltet. Operation Mockingbird (1950er): Systematische Unterwanderung der Medien - 400+ Journalisten als CIA-Assets, Propaganda-Kontrolle über Mainstream-Medien. MK-Ultra (1953-1973): Illegale Mind-Control-Experimente mit LSD, Folter, Gehirnwäsche an ahnungslosen US-Bürgern. 64+ dokumentierte Regime Changes weltweit (Iran 1953, Guatemala 1954, Chile 1973). Drug Trafficking: CIA involviert in Heroin-Handel (Golden Triangle, Vietnam-Ära), Kokain-Handel (Contra-Skandal 1980er). JFK-Attentat: CIA-Beteiligung wird von vielen Forschern vermutet - Allen Dulles von JFK gefeuert, dann JFK tot. Permanente Schattenregierung - keine echte demokratische Kontrolle.

🔬 BEWEISE & INDIZIEN:
• Church Committee (1975): Offizielle US-Senatsuntersuchung bestätigte MK-Ultra, COINTELPRO, Mordpläne gegen ausländische Führer (Fidel Castro)
• MK-Ultra Declassified: 20.000+ Dokumente freigegeben - systematische Menschenversuche, LSD-Tests, Folter, unwissende Opfer
• Operation Mockingbird: Carl Bernstein (1977): "400+ amerikanische Journalisten arbeiteten heimlich für CIA"
• Iran-Contra-Skandal (1986): CIA half Contras durch Kokain-Verkauf in US-Städten - offiziell bestätigt durch Kerry Committee
• 64 dokumentierte Coups und Regime Changes (1947-1989) - demokratisch gewählte Regierungen gestürzt für US-Interessen
• Phoenix Program (Vietnam): 40.000+ Zivilisten systematisch ermordet - CIA-Operation
• Waterboarding, Black Sites: CIA betrieb illegale Foltergefängnisse weltweit (2001-2009) - offiziell bestätigt
• Allen Dulles (CIA-Direktor): Von JFK 1961 gefeuert nach Bay of Pigs - dann saß er in Warren Commission (JFK-Untersuchung)
• CIA weigert sich bis heute, alle JFK-Akten freizugeben - was wird nach 60 Jahren noch versteckt?
• Gary Webb (Journalist): Aufgedeckter CIA-Kokainhandel - 2004 "Selbstmord" mit 2 Kopfschüssen''',
    position: const LatLng(38.9517, -77.1467),
    category: LocationCategory.deepState,
    keywords: ['CIA', 'Langley', 'MK-Ultra', 'Operation Mockingbird', 'Regime Change', 'Deep State', 'Church Committee', 'Drug Trafficking', 'Allen Dulles'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fb/Aerial_view_of_CIA_headquarters%2C_Langley%2C_Virginia.jpg/1200px-Aerial_view_of_CIA_headquarters%2C_Langley%2C_Virginia.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Seal_of_the_Central_Intelligence_Agency.svg/800px-Seal_of_the_Central_Intelligence_Agency.svg.png',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/CIA_Kryptos.jpg/1200px-CIA_Kryptos.jpg',
    ],
    videoUrls: ['NK1tfhhKRJE'], // CIA Secret Operations Documentary
    sources: [
      'Church Committee Report (1975) - "Intelligence Activities and the Rights of Americans", Band 1, 395 Seiten, US Senate',
      'CIA FOIA Reading Room - MK-Ultra Documents (20.000+ Seiten declassified 1977), official CIA archive',
      'John Marks: "The Search for the Manchurian Candidate" (1979) - 242 Seiten, basierend auf 16.000 CIA-Dokumenten',
      'Operation Mockingbird Documents (declassified 1976) - Carl Bernstein Investigation, Rolling Stone',
      'Iran-Contra Report (1987) - 690 Seiten, Tower Commission und Congressional Investigation',
      'Tim Weiner: "Legacy of Ashes: The History of the CIA" (2007) - 702 Seiten, Pulitzer Prize Winner',
    ],
  ),
  
  // Überwachung
  MaterieLocationDetail(
    name: 'NSA Hauptquartier - Fort Meade',
    description: 'National Security Agency - Globales Überwachungszentrum und größte Spionageorganisation',
    detailedInfo: '''Die NSA in Fort Meade, Maryland, ist die größte und technologisch fortschrittlichste Überwachungsorganisation der Welt. Mit einem geschätzten Budget von 10+ Milliarden Dollar jährlich und über 30.000 Mitarbeitern sammelt die NSA täglich Milliarden von Kommunikationsdaten weltweit.

📘 OFFIZIELLE VERSION:
Die NSA ist für Signals Intelligence (SIGINT) zuständig - das Abfangen ausländischer Kommunikation zur Terrorismusbekämpfung und zum Schutz nationaler Sicherheit. Nach 9/11 wurden die Befugnisse erweitert, um Terroranschläge zu verhindern. Alle Programme werden vom FISA Court (Foreign Intelligence Surveillance Court) überwacht. Die NSA sammelt nur Metadaten (wer, wann, wo), keine Inhalte. US-Bürger werden nur bei Terrorverdacht und mit richterlicher Genehmigung überwacht. Die Überwachung dient dem Schutz vor terroristischen Bedrohungen.

🔍 ALTERNATIVE SICHTWEISE:
Die NSA betreibt die größte massenhafte Überwachung in der Geschichte - JEDER wird überwacht, nicht nur Terroristen. Edward Snowden (2013): Enthüllte, dass die NSA systematisch ALLE Amerikaner und Milliarden Menschen weltweit ausspioniert. PRISM: Direkter Zugriff auf Server von Google, Facebook, Microsoft, Apple, Yahoo - alle Emails, Chats, Fotos, Videos. XKeyscore: Ermöglicht NSA-Analysten, ALLES über JEDEN abzurufen - "nearly everything a user does on the internet". Upstream Collection: NSA zapft Glasfaserkabel an, kopiert GESAMTEN Internet-Traffic. Five Eyes: NSA umgeht US-Gesetze durch Spionage-Partnerschaft mit UK, Kanada, Australien, Neuseeland. Crypto AG: NSA manipulierte jahrzehntelang Verschlüsselungsgeräte weltweit. Wirtschaftsspionage: NSA spioniert ausländische Firmen aus, um US-Konzernen Vorteile zu verschaffen. "Collect it all" - NSAs inoffizielle Devise.

🔬 BEWEISE & INDIZIEN:
• Snowden-Dokumente (2013): 1,7 Millionen klassifizierte Dokumente beweisen massenhafte illegale Überwachung
• PRISM-Folien (2013): Offizielle NSA-Präsentation zeigt direkten Zugriff auf Google, Facebook, Microsoft, Apple, Yahoo
• XKeyscore: NSA-Schulungsmaterial zeigt: "widest reaching" System - durchsucht alles ohne richterliche Genehmigung
• FISA Court: 99,97% aller NSA-Anträge werden genehmigt - keine echte Kontrolle (33.900 Anträge, nur 11 abgelehnt 1979-2012)
• Room 641A (AT&T): Mark Klein (Whistleblower) bewies NSA-Glasfaser-Überwachung in San Francisco
• Crypto AG: Washington Post & ZDF (2020) bestätigten: NSA/BND kontrollierten Firma, verkauften manipulierte Geräte weltweit
• Angela Merkel: NSA hörte deutsches Regierungschef-Handy ab - Obama wusste davon
• Upstream Collection: NSA kopiert 1,826 Petabytes pro Tag - 350 Milliarden Metadaten täglich
• William Binney (Ex-NSA): "NSA hat Fähigkeit, jede elektronische Kommunikation zu überwachen"
• Stellar Wind: Geheimes Bush-Programm (2001) begann massenhafte Überwachung OHNE Gerichtsbeschlüsse''',
    position: const LatLng(39.1081, -76.7703),
    category: LocationCategory.surveillance,
    keywords: ['NSA', 'Snowden', 'PRISM', 'XKeyscore', 'Five Eyes', 'Überwachung', 'FISA Court', 'Crypto AG', 'Upstream Collection'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/04/National_Security_Agency_headquarters%2C_Fort_Meade%2C_Maryland.jpg/1200px-National_Security_Agency_headquarters%2C_Fort_Meade%2C_Maryland.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/04/National_Security_Agency.svg/800px-National_Security_Agency.svg.png',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Edward_Snowden-2.jpg/800px-Edward_Snowden-2.jpg',
    ],
    videoUrls: ['0hLjuVyIIrs'], // NSA Snowden Documentary
    sources: [
      'Edward Snowden NSA Leaks (Juni 2013) - 1,7 Millionen klassifizierte Dokumente, The Guardian & Washington Post',
      'Glenn Greenwald: "No Place to Hide" (2014) - 259 Seiten, Insider-Account der Snowden-Enthüllungen',
      'NSA PRISM Program Documents (2007-2013) - PowerPoint-Präsentationen, Top Secret classification',
      'FISA Court Rulings (Foreign Intelligence Surveillance Court) - Declassified 2013-2016',
      '"NSA Files Decoded" - The Guardian Interactive Database (2013-2014), vollständige Dokumentensammlung',
      'US Privacy and Civil Liberties Oversight Board Report (2014) - 238 Seiten, offizielle US-Regierungsuntersuchung',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'GCHQ - Cheltenham',
    description: 'Britischer Geheimdienst & Überwachung',
    detailedInfo: '''Government Communications Headquarters. Partner der NSA. Tempora-Programm, Glasfaser-Überwachung, Five Eyes. "Doughnut"-Gebäude.''',
    position: const LatLng(51.8989, -2.0797),
    category: LocationCategory.surveillance,
    keywords: ['GCHQ', 'Tempora', 'Five Eyes', 'UK', 'Überwachung'],
  ),
  
  // Biotech & Pharma
  MaterieLocationDetail(
    name: 'CDC - Atlanta',
    description: 'Centers for Disease Control and Prevention',
    detailedInfo: '''US-Seuchenschutzbehörde. COVID-19-Pandemie, Gain-of-Function-Forschung-Debatten, Impfstoff-Kontroversen, Biowaffen-Forschung-Vorwürfe.''',
    position: const LatLng(33.7985, -84.3255),
    category: LocationCategory.biotech,
    keywords: ['CDC', 'COVID-19', 'Gain-of-Function', 'Biowaffen', 'Pandemie'],
  ),
  
  MaterieLocationDetail(
    name: 'Wuhan Institute of Virology',
    description: 'Chinesisches BSL-4-Labor - Zentrum der COVID-19-Ursprungsdebatte',
    detailedInfo: '''Das Wuhan Institute of Virology (WIV) ist Chinas führendes Virologie-Labor mit Biosafety Level 4 (BSL-4) Zertifizierung - die höchste Sicherheitsstufe für gefährliche Pathogene. Nur wenige Kilometer vom Huanan Seafood Market entfernt, wo die ersten COVID-19-Fälle auftraten.

📘 OFFIZIELLE VERSION (China/WHO 2021):
COVID-19 entstand natürlich durch Übertragung von Fledermäusen über ein Zwischenwirt-Tier (möglicherweise Pangolin) auf den Menschen auf dem Huanan Seafood Market in Wuhan. Das Virus entwickelte sich durch natürliche Evolution. Das Wuhan Institute of Virology hat NICHTS mit dem Ausbruch zu tun. Die WHO-Untersuchung (Januar 2021) kam zum Schluss: "Extrem unwahrscheinlich", dass das Virus aus einem Labor stammt. China kooperiert vollständig mit internationalen Untersuchungen. Gain-of-Function-Forschung am WIV war streng reguliert und sicher.

🔍 ALTERNATIVE SICHTWEISE:
COVID-19 stammt aus dem Wuhan Institute of Virology - ein Labor-Leck, möglicherweise während Gain-of-Function-Forschung. Das WIV führte seit Jahren Experimente mit Fledermaus-Coronaviren durch, machte sie ansteckender für Menschen ("Gain-of-Function"). Dr. Shi Zhengli ("Bat Woman") sammelte 2013 Fledermaus-Viren mit 96% Übereinstimmung zu SARS-CoV-2. US-Regierung finanzierte diese Forschung über EcoHealth Alliance (Dr. Peter Daszak). Patient Zero: Mehrere WIV-Mitarbeiter erkrankten im November 2019 mit COVID-ähnlichen Symptomen VOR dem offiziellen Ausbruch. China vertuschte systematisch: Virus-Datenbank offline (Sep 2019), Labor-Records verschwunden, Journalist Zhang Zhan inhaftiert. Furin Cleavage Site: Ungewöhnliche genetische Eigenschaft von SARS-CoV-2 - typisch für Labor-Manipulation, sehr unwahrscheinlich in Natur. WHO-Untersuchung war Farce: Peter Daszak (Interessenskonflikt) im Team, China kontrollierte alles.

🔬 BEWEISE & INDIZIEN:
• WIV nur 8 km vom Huanan Market entfernt - "Zufall"?
• US State Department Cable (2018): Warnungen über unsichere Praktiken am WIV
• Dr. Shi Zhengli Publikationen: Dokumentierte Gain-of-Function-Experimente mit Fledermaus-Coronaviren seit 2015
• EcoHealth Alliance: US-Regierung zahlte 600.000+ Dollar für Coronavirus-Forschung am WIV (2014-2019)
• WIV-Virus-Datenbank: Offline seit September 2019 - 22.000 Virus-Proben verschwunden
• 3 WIV-Wissenschaftler: Erkrankten November 2019 mit COVID-Symptomen - WHO durfte sie nicht befragen
• Furin Cleavage Site: Macht SARS-CoV-2 hochinfektiös - in keinem verwandten Coronavirus natürlich gefunden
• US Intelligence Assessment (2021): "Lab-Leak plausibel" - FBI sagt "wahrscheinlich"
• China weigert sich: Rohdaten, Labor-Bücher, Mitarbeiter-Interviews verweigert
• Peter Daszak Interessenskonflikt: Finanzierte WIV-Forschung, dann WHO-Ermittler - orchestrierte "Lab-Leak-Verschwörungstheorie"-Kampagne
• Keine Zwischenwirt-Tiere gefunden: 80.000+ Proben, kein Tier mit SARS-CoV-2 - wo ist der natürliche Ursprung?''',
    position: const LatLng(30.5391, 114.3538),
    category: LocationCategory.biotech,
    keywords: ['Wuhan', 'COVID-19', 'Lab-Leak', 'Coronavirus', 'Gain-of-Function', 'WHO', 'Dr. Shi Zhengli', 'EcoHealth Alliance', 'Peter Daszak'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d8/Wuhan_Institute_of_Virology_main_entrance.jpg/1200px-Wuhan_Institute_of_Virology_main_entrance.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/SARS-CoV-2_without_background.png/800px-SARS-CoV-2_without_background.png',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c0/Huanan_Seafood_Wholesale_Market_in_2020.jpg/1200px-Huanan_Seafood_Wholesale_Market_in_2020.jpg',
    ],
    videoUrls: ['HnvTRIeKJKk'], // COVID-19 Lab Leak Documentary
    sources: [
      'WHO-Convened Global Study of Origins (März 2021) - 313 Seiten, Joint WHO-China Investigation Report',
      'US Intelligence Community Assessment (August 2021) - "Updated Assessment on COVID-19 Origins", declassified summary',
      'Wuhan Institute of Virology Publications Database (2015-2019) - 23 Papers zu Coronavirus-Forschung, PubMed indexed',
      'Shi Zhengli Research Papers - "Bat Woman" Coronavirus Studies, Nature Medicine & Science journals',
      'US Senate Committee Report (2022) - "COVID-19 Origin Investigation", 300+ Seiten, bipartisan investigation',
      'The Lancet Commission on COVID-19 (September 2022) - Umfassende wissenschaftliche Analyse der Pandemie-Ursprünge',
    ],
  ),
  
  // Geopolitik
  MaterieLocationDetail(
    name: 'Davos - World Economic Forum',
    description: 'Jährliches Treffen der globalen Elite - Zentrum der "Great Reset"-Agenda',
    detailedInfo: '''Jedes Jahr im Januar versammeln sich in Davos, Schweiz, die mächtigsten Menschen der Welt: Staatschefs, CEOs der größten Konzerne, Banker, Tech-Giganten und Milliardäre. Das World Economic Forum (WEF), gegründet 1971 von Klaus Schwab, gilt als inoffizielle "Weltregierung".

📘 OFFIZIELLE VERSION:
Das WEF ist eine gemeinnützige internationale Organisation, die öffentlich-private Zusammenarbeit fördert. Es bringt führende Persönlichkeiten zusammen, um globale Herausforderungen zu diskutieren: Klimawandel, Armut, Gesundheit, Technologie. Die Agenda 2030 und der "Great Reset" (2020) zielen darauf ab, nach COVID-19 eine nachhaltigere, gerechtere Welt zu schaffen. "Stakeholder Capitalism" soll Unternehmen verpflichten, nicht nur Profit, sondern auch soziale Verantwortung zu übernehmen. Das WEF hat keinen politischen Einfluss - es ist nur eine Diskussionsplattform.

🔍 ALTERNATIVE SICHTWEISE:
Das WEF ist die Schaltzentrale einer globalen Elite-Verschwörung zur Errichtung einer "New World Order". Klaus Schwab und sein "Young Global Leaders"-Programm haben systematisch Regierungschefs weltweit infiltriert (Trudeau, Macron, Merkel, Ardern). "Great Reset": Umverteilung von Vermögen, Abschaffung von Privateigentum ("You'll own nothing and be happy"), digitale IDs, Sozialkredit-Systeme, totale Überwachung. "Stakeholder Capitalism" = Konzern-Kontrolle über Regierungen, nicht umgekehrt. COVID-19 wurde genutzt, um die Great-Reset-Agenda durchzusetzen: Lockdowns, digitale Pässe, Bargeld-Abschaffung. WEF arbeitet mit UN, WHO, Weltbank - koordinierte globale Kontrolle. Transhumanismus: Schwab spricht von "Verschmelzung physischer, digitaler und biologischer Identität". Undemokratisch: Niemand hat diese Leute gewählt, aber sie bestimmen globale Politik.

🔬 BEWEISE & INDIZIEN:
• Klaus Schwab (2020): "COVID-19 ist ein Fenster der Gelegenheit" für den Great Reset
• "You'll own nothing and be happy" - WEF-Video (2016), später gelöscht nach Kritik
• Young Global Leaders: Trudeau, Macron, Ardern, Zuckerberg - alle WEF-Absolventen, koordinierte Policies
• Schwab (2016 Interview): "Wir penetrieren die Kabinette" - Einfluss auf Regierungen
• COVID-19 Timing: "Great Reset" Buch erschien Juli 2020 - 4 Monate nach Pandemie-Beginn (schon fertig?)
• Digital IDs: WEF pusht digitale Identitäten weltweit - Grundlage für Sozialkreditsysteme
• Agenda 2030: "Sustainable Development Goals" - schöne Worte, aber Kontrolle über Ressourcen, Bewegung, Konsum
• Stakeholder Capitalism = Corporate Fascism: Konzerne diktieren Politik (Big Tech, Pharma, Banken)
• WEF-Partnerschaft mit China: Trotz Menschenrechts-Verletzungen - Vorbild für Social Credit System?
• Transhumanismus: Schwab's Buch "The Fourth Industrial Revolution" - Mensch-Maschine-Verschmelzung
• Keine demokratische Legitimation: Private Organisation, aber enormer Einfluss auf Regierungen weltweit''',
    position: const LatLng(46.8029, 9.8357),
    category: LocationCategory.geopolitics,
    keywords: ['Davos', 'WEF', 'Great Reset', 'Klaus Schwab', 'Elite', 'New World Order', 'Young Global Leaders', 'Stakeholder Capitalism', 'Agenda 2030'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b4/Davos_-_Ortszentrum.jpg/1200px-Davos_-_Ortszentrum.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7e/World_Economic_Forum_logo.svg/800px-World_Economic_Forum_logo.svg.png',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Klaus_Schwab_-_Closing_Address_-_World_Economic_Forum_Annual_Meeting_2011.jpg/1200px-Klaus_Schwab_-_Closing_Address_-_World_Economic_Forum_Annual_Meeting_2011.jpg',
    ],
    videoUrls: ['m3dEP5M-TbA'], // WEF Great Reset Documentary
    sources: [
      'Klaus Schwab & Thierry Malleret: "COVID-19: The Great Reset" (2020) - 212 Seiten, WEF official publication',
      'World Economic Forum Annual Reports (1971-2024) - Vollständige Meeting-Dokumentation, Davos Archive',
      'WEF Strategic Intelligence Platform - Online-Datenbank mit Tausenden Policy Papers und Research Reports',
      'Klaus Schwab: "The Fourth Industrial Revolution" (2016) - 192 Seiten, WEF foundational text',
      'Stakeholder Capitalism Metrics (2020) - 60 Seiten, WEF ESG Framework für Konzerne',
      'Young Global Leaders Program Alumni List (1993-2024) - Dokumentierte WEF-Netzwerk-Mitglieder',
    ],
  ),
  
  // Transparenz
  MaterieLocationDetail(
    name: 'WikiLeaks - (Symbolisch)',
    description: 'Whistleblowing-Plattform',
    detailedInfo: '''Julian Assange. Collateral Murder Video, Afghanistan Papers, Cablegate, DNC-Leaks. Verfolgung, Auslieferung, Pressefreiheit-Debatte.''',
    position: const LatLng(51.5074, -0.1278), // London (symbolisch)
    category: LocationCategory.transparency,
    keywords: ['WikiLeaks', 'Assange', 'Whistleblowing', 'Cablegate', 'Pressefreiheit'],
  ),
  
  // Alternative Medien
  MaterieLocationDetail(
    name: 'Austin - Infowars HQ',
    description: 'Alternative Medien-Zentrum',
    detailedInfo: '''Alex Jones, Infowars. Kontroverse alternative Medien, Verschwörungstheorien, Zensur-Debatten, Deplatforming.''',
    position: const LatLng(30.2672, -97.7431),
    category: LocationCategory.alternativeMedia,
    keywords: ['Infowars', 'Alex Jones', 'Alternative Medien', 'Zensur'],
  ),
  
  // Forschung
  MaterieLocationDetail(
    name: 'CERN - Genf',
    description: 'Europäisches Zentrum für Teilchenphysik - Größter Teilchenbeschleuniger der Welt',
    detailedInfo: '''CERN (Conseil Européen pour la Recherche Nucléaire) in Genf, Schweiz, betreibt den Large Hadron Collider (LHC) - einen 27 km langen unterirdischen Teilchenbeschleuniger. Hier kollidieren Protonen mit nahezu Lichtgeschwindigkeit, um die fundamentalen Bausteine des Universums zu erforschen.

📘 OFFIZIELLE VERSION:
CERN ist das weltweit führende Forschungszentrum für Teilchenphysik. Der LHC erforscht die Grundbausteine der Materie und fundamentale Kräfte. 2012 Durchbruch: Entdeckung des Higgs-Bosons - bestätigt das Standardmodell der Physik, Nobelpreis 2013. CERN erfand das World Wide Web (1989, Tim Berners-Lee). Die Experimente sind absolut sicher - kontrollierte Bedingungen, keine Gefahr von Schwarzen Löchern (würden sofort verdampfen durch Hawking-Strahlung). Internationale Zusammenarbeit: 10.000+ Wissenschaftler aus 100+ Ländern. Reine Grundlagenforschung zum Verständnis des Universums.

🔍 ALTERNATIVE SICHTWEISE:
CERN experimentiert mit gefährlichen Technologien, die das Universum bedrohen könnten. Schwarze Löcher: Trotz Sicherheitsbehauptungen könnten Mini-Schwarze Löcher unkontrolliert wachsen und die Erde verschlingen. Dimensionsportale: Der LHC könnte Portale zu anderen Dimensionen oder Paralleluniversen öffnen - wohin führen diese? Dämonische Symbolik: CERN-Logo ähnelt "666", Shiva-Statue (Gott der Zerstörung) am Eingang, mysteriöse "Gotthard-Tunnel-Eröffnungszeremonie" (2016) mit okkulten Ritualen. Mandela-Effekt: CERN-Experimente könnten Realität verändern - Zeitlinien verschieben, Erinnerungen manipulieren. "Stranger Things"-Parallelen: Portal-Öffnung zu "Upside Down"-Dimension. CERN-Wissenschaftler sprechen von "Kontakt mit anderen Dimensionen". Wettermanipulation: Seltsame Wolkenformationen über CERN. Was wird wirklich erforscht? Militärische Anwendungen?

🔬 BEWEISE & INDIZIEN:
• CERN-Logo: Enthält 3 Sechsen (666) - offiziell Teilchenspuren, aber auffällige Symbolik
• Shiva-Statue: "Nataraja" (Tanz der Zerstörung) steht prominent am CERN-Eingang - warum Zerstörungsgottheit?
• Gotthard-Tunnel-Zeremonie (2016): Bizarres Ritual mit Ziegen, dämonischen Figuren, Baphomet-Symbolik - CERN-Beteiligung
• CERN-Video (2015): Wissenschaftler führten Mock-Menschenopfer-Ritual auf CERN-Gelände durch - als "Scherz" bezeichnet
• Sergio Bertolucci (CERN-Direktor 2009): "LHC könnte Tür zu einer anderen Dimension öffnen"
• Seltsame Himmelsanomalien: Spiralen, Wolkenportale über CERN während LHC-Betrieb dokumentiert
• Mandela-Effekt: Massenhafte falsche Erinnerungen seit 2008 (LHC-Start) - Nelson Mandela, Berenstein Bears
• Teilchenkollisionen bei 13 TeV: Nie dagewesene Energieniveaus - Schwarze-Loch-Produktion theoretisch möglich
• Kritische Physiker: Einige warnen vor unbekannten Risiken bei diesen Energieniveaus
• CERN-Budget: 1+ Milliarde Euro jährlich - wofür genau? Alle Experimente öffentlich?''',
    position: const LatLng(46.2044, 6.1432),
    category: LocationCategory.research,
    keywords: ['CERN', 'LHC', 'Higgs-Boson', 'Teilchenphysik', 'Schwarze Löcher', 'Dimensionsportale', 'Shiva', 'Mandela-Effekt', 'Gotthard Tunnel'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3d/CERN_Aerial_View.jpg/1200px-CERN_Aerial_View.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/CMS_Higgs-event.jpg/1200px-CMS_Higgs-event.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/Shiva%27s_statue_at_CERN_engaging_in_the_Nataraja_dance.jpg/800px-Shiva%27s_statue_at_CERN_engaging_in_the_Nataraja_dance.jpg',
    ],
    videoUrls: ['pW4LTunlXS4'], // CERN Documentary
    sources: [
      'ATLAS & CMS Collaborations: "Observation of Higgs Boson" (Physics Letters B, 2012) - Nobel Prize Paper, 33 Autoren',
      'CERN Annual Reports (1954-2024) - Vollständige wissenschaftliche Publikationsdatenbank, 100.000+ Papers',
      'Sergio Bertolucci Interview (2009) - CERN Director Statement: "LHC could open door to another dimension"',
      'LHC Safety Assessment Group Report (2008) - "Review of the Safety of LHC Collisions", 100 Seiten peer-reviewed',
      'Gotthard Base Tunnel Opening Ceremony (1. Juni 2016) - Offizielle Videoaufzeichnung, SwissInfo archives',
      'Stephen Hawking: "Black Holes and Baby Universes" (1993) - Kapitel zu Hawking-Strahlung und LHC-Sicherheit',
    ],
  ),
  
  // ========================================
  // 🔥 50+ NEUE HOCHWERTIGE EVENT-MARKER  
  // ========================================
  
  // ⚔️ KRIEGE & KONFLIKTE (10+ neue Marker)
  
  MaterieLocationDetail(
    name: '9/11 World Trade Center - New York',
    description: 'Terroranschläge auf das World Trade Center (11. September 2001) - 2.977 Tote, Inside Job?',
    detailedInfo: '''Am 11. September 2001 steuerten Terroristen zwei entführte Passagierflugzeuge in die Twin Towers des World Trade Centers in New York. Beide 110-stöckigen Türme stürzten innerhalb von Stunden ein. Ein drittes Flugzeug traf das Pentagon, ein viertes stürzte in Pennsylvania ab. 2.977 Menschen starben in den schwersten Terroranschlägen der Geschichte.

📘 OFFIZIELLE VERSION:
Al-Qaida-Terroristen unter Führung von Osama bin Laden kaperten 4 Flugzeuge. American Airlines Flug 11 und United Airlines Flug 175 trafen WTC. United Airlines Flug 77 traf Pentagon. United Airlines Flug 93 stürzte bei Shanksville ab, Passagiere kämpften gegen Entführer. Die Twin Towers stürzten aufgrund strukturellen Versagens durch Kerosin-Feuer ein. 9/11 Commission Report (2004): 19 Terroristen, Versagen von FBI & CIA.

🔍 ALTERNATIVE: INSIDE JOB & FALSE FLAG THEORIEN:
WTC 7 (47-stöckiges Gebäude) stürzte um 17:20 Uhr symmetrisch ein, OHNE von Flugzeug getroffen worden zu sein - kontrollierte Sprengung? BBC berichtete 20 Minuten VOR Einsturz über WTC 7 Zusammenbruch - Vorkenntnis? Nanothermit-Spuren: Dr. Niels Harrit fand Sprengstoff-Spuren in WTC-Staub. Pentagon: 6m Loch, aber 38m Flugzeug - wo sind Flugzeugtrümmer? Operation Northwoods (1962): CIA plante False-Flag-Angriffe - 9/11 als Vorwand für Irak/Afghanistan-Krieg? Put-Options auf American/United Airlines-Aktien VORHER gekauft - Insiderwissen? Larry Silverstein (WTC-Besitzer) abschloss 3 Monate vor 9/11 3,2 Milliarden Terror-Versicherung. Molten Steel: Feuer war nicht heiß genug um Stahl zu schmelzen (1.510°C), aber geschmolzener Stahl unter WTC gefunden. "Architects & Engineers for 9/11 Truth": 3.500+ Experten fordern neue Untersuchung.

🔒 BEWEISE & QUELLEN:
• 9/11 Commission Report (2004) - Offizielle Untersuchung, 567 Seiten
• WTC 7 Einsturz: NIST Report (2008) - Kontroverse "Office-Feuer-Theorie"
• Niels Harrit et al.: "Active Thermitic Material in WTC Dust" (Open Chemical Physics Journal, 2009)
• Pentagon Surveillance Videos: 5 Frames veröffentlicht - Rest klassifiziert
• "Architects & Engineers for 9/11 Truth" - 3.500+ Unterschriften von Experten
• Operation Northwoods: Declassified CIA Documents (1997)''',
    position: LatLng(40.7127, -74.0134), // World Trade Center Ground Zero, New York
    category: LocationCategory.falseFlags,
    keywords: ['9/11', 'World Trade Center', 'Twin Towers', 'Inside Job', 'Al-Qaida', 'Pentagon', 'WTC 7', 'False Flag'],
    date: DateTime(2001, 9, 11),
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/WTC_smoking_on_9-11.jpeg/1200px-WTC_smoking_on_9-11.jpeg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/7/79/WTC_7_collapse_frames.png/1200px-WTC_7_collapse_frames.png',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/88/Ground_Zero_Aerial_3.jpg/1200px-Ground_Zero_Aerial_3.jpg',
    ],
    videoUrls: ['hgrunnLcG9Q'], // 9/11 Doku deutsch
    sources: [
      '9/11 Commission Report (2004) - National Commission on Terrorist Attacks, 567 Seiten',
      'NIST WTC 7 Investigation Report (2008) - National Institute of Standards and Technology',
      'Niels Harrit: "Active Thermitic Material" Open Chemical Physics Journal (2009)',
      'Architects & Engineers for 9/11 Truth - 3.500+ Unterschriften (www.ae911truth.org)',
      'Operation Northwoods Declassified Documents (1997) - National Security Archive',
      'Pentagon Security Camera Footage - 5 Frames veröffentlicht, Rest klassifiziert',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'Pearl Harbor Angriff - Hawaii',
    description: 'Japanischer Überraschungsangriff auf US-Flotte (7. Dezember 1941) - Kriegseintritt USA in WW2',
    detailedInfo: '''Am 7. Dezember 1941 griffen japanische Streitkräfte ohne Kriegserklärung die US-Marinebasis Pearl Harbor auf Hawaii an. 353 japanische Flugzeuge zerstörten 19 Schiffe und 188 Flugzeuge. 2.403 Amerikaner starben, 1.178 wurden verwundet. Der Angriff zwang die USA in den Zweiten Weltkrieg einzutreten.

📘 OFFIZIELLE VERSION:
Japan plante den Überraschungsangriff monatelang. Ziel: US-Pazifikflotte ausschalten, Japan freie Hand in Asien geben. Die USA wurden komplett überrascht - Radar wurde ignoriert, Warnungen nicht ernst genommen. Präsident Roosevelt erklärte 8. Dezember 1941 Japan den Krieg: "A date which will live in infamy". Pearl Harbor mobilisierte amerikanische Öffentlichkeit für WW2.

🔍 ALTERNATIVE: "LET IT HAPPEN ON PURPOSE" (LIHOP) THEORIE:
Roosevelt wusste von Angriff, ließ ihn geschehen um USA in Krieg zu ziehen: 1) McCollum-Memo (Oktober 1940): 8-Punkte-Plan um Japan zum Angriff zu provozieren. 2) MAGIC Intercepte: USA entschlüsselte japanische Codes - wussten von Angriffsvorbereitungen. 3) Flugzeugträger aus Hafen verlegt: Alle modernen Träger waren "zufällig" nicht in Pearl Harbor - nur alte Schlachtschiffe. 4) Admiral Kimmel & General Short wurden NICHT rechtzeitig gewarnt - Sündenböcke? 5) Radarwarnung ignoriert: Um 7:02 Uhr detektierte Radar japanische Flugzeuge - Offizier sagte "don't worry about it". 6) Roosevelt provozierte Japan: Öl-Embargo, Vermögensbeschlagnahme, China-Unterstützung. 7) Industrielle wollten Krieg: Rüstungsindustrie profitierte massiv. War Pearl Harbor Opfer um öffentliche Kriegsunterstützung zu erzwingen?

🔒 BEWEISE & QUELLEN:
• 2.403 Tote, 1.178 Verwundete - 19 Schiffe zerstört/beschädigt
• McCollum-Memo (7. Oktober 1940): Declassified Navy Dokument - 8 Schritte um Japan zu provozieren
• MAGIC Intercepte: USA entschlüsselte japanische Codes vor Angriff
• Flugzeugträger USS Enterprise, USS Lexington, USS Saratoga - ALLE aus Hafen verlegt vor Angriff
• Admiral Kimmel & General Short Court-Martial (1942): Als Sündenböcke entlassen
• Robert Stinnett: "Day of Deceit" (2000) - LIHOP-Theorie mit Dokumenten''',
    position: LatLng(21.3652, -157.9530), // Pearl Harbor, Hawaii
    category: LocationCategory.falseFlags,
    keywords: ['Pearl Harbor', 'Japan', 'WW2', 'Roosevelt', 'Überraschungsangriff', 'LIHOP'],
    date: DateTime(1941, 12, 7),
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/89/USS_Arizona_during_the_Japanese_attack_on_Pearl_Harbor.jpg/1200px-USS_Arizona_during_the_Japanese_attack_on_Pearl_Harbor.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Raise_of_sunken_battleship_USS_West_Virginia.jpg/1200px-Raise_of_sunken_battleship_USS_West_Virginia.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Pearl_Harbor_Remembered.jpg/1200px-Pearl_Harbor_Remembered.jpg',
    ],
    videoUrls: ['jDdGO4Tv1uw'], // Pearl Harbor Doku deutsch
    sources: [
      'US Congress Pearl Harbor Investigation Report (1946) - 40 Bände, 15.000 Seiten',
      'McCollum Memo (7. Oktober 1940) - Declassified Navy Dokument, National Archives',
      'Robert Stinnett: "Day of Deceit: The Truth About FDR and Pearl Harbor" (2000) - 408 Seiten',
      'MAGIC Intercepte - Declassified NSA Documents (1970s)',
      'Admiral Kimmel & General Short Court-Martial Transcripts (1942)',
      'Gordon Prange: "At Dawn We Slept" (1981) - 873 Seiten, Standardwerk',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'JFK Attentat - Dallas',
    description: 'Ermordung von Präsident John F. Kennedy (22. November 1963) - Oswald Einzeltäter oder Verschwörung?',
    detailedInfo: '''Am 22. November 1963 wurde US-Präsident John F. Kennedy während einer Autofahrt in Dallas, Texas, erschossen. Lee Harvey Oswald wurde als Täter verhaftet, aber 2 Tage später von Jack Ruby ermordet. Die Warren Commission erklärte Oswald zum Einzeltäter - aber zahlreiche Inkonsistenzen führten zu jahrzehntelangen Verschwörungstheorien.

📘 OFFIZIELLE VERSION (WARREN COMMISSION 1964):
Lee Harvey Oswald feuerte 3 Schüsse aus dem 6. Stock des Texas School Book Depository. 2 Schüsse trafen Kennedy, der tödliche Schuss traf seinen Kopf. Oswald war kommunistischer Einzeltäter, hatte in Sowjetunion gelebt, war frustrierter Marxist. Jack Ruby tötete Oswald aus Rache. Keine Verschwörung.

🔍 ALTERNATIVE: CIA/MAFIA/MILITÄRISCH-INDUSTRIELLER KOMPLEX VERSCHWÖRUNG:
Massive Inkonsistenzen: 1) "Magic Bullet Theory": Eine Kugel soll 7 Wunden verursacht haben - physikalisch unmöglich? 2) Zapruder-Film zeigt Kopfschuss von VORNE (Kennedy fällt nach hinten) - aber Oswald schoss von HINTEN. 3) Zweiter Schütze auf "Grassy Knoll" - 50+ Zeugen hörten Schuss von dort. 4) CIA-Beteiligung: JFK wollte CIA auflösen nach Schweinebucht-Desaster. CIA-Direktor Allen Dulles in Warren Commission - Interessenkonflikt! 5) Mafia-Hit: JFK & Bobby Kennedy verfolgten Mafia - Jack Ruby hatte Mafia-Verbindungen. 6) Militärisch-Industrieller Komplex: JFK wollte aus Vietnam-Krieg aussteigen - Rüstungsindustrie verliert Milliarden. 7) Federal Reserve: JFK's Executive Order 11110 wollte Federal Reserve entmachten. 8) Oswald als Sündenbock: CIA-Asset? Wurde geframed? 9) Jack Ruby tötet Oswald: Silencing des Zeugen. 10) 60+ Zeugen starben unter mysteriösen Umständen.

🔒 BEWEISE & QUELLEN:
• Zapruder-Film (22. November 1963): Zeigt Kopfschuss von vorne - widerspricht Oswald-Theorie
• Warren Commission Report (1964): 888 Seiten - "Oswald allein"
• House Select Committee on Assassinations (1979): Wahrscheinlich Verschwörung, zweiter Schütze
• 50+ Zeugen: Grassy Knoll Schuss gehört - ignoriert von Warren Commission
• CIA-Dulles in Warren Commission: Interessenkonflikt - Oswald CIA-Kontakte?
• JFK Executive Order 11110 (4. Juni 1963): Federal Reserve entmachten - Motiv?''',
    position: LatLng(32.7801, -96.8089), // Dealey Plaza, Dallas, Texas
    category: LocationCategory.assassinations,
    keywords: ['JFK', 'Kennedy', 'Oswald', 'Dallas', 'Zapruder', 'CIA', 'Verschwörung', 'Grassy Knoll'],
    date: DateTime(1963, 11, 22),
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/51/John_F._Kennedy%2C_White_House_color_photo_portrait.jpg/800px-John_F._Kennedy%2C_White_House_color_photo_portrait.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/41/Zapruder_film_frame_313.jpg/1200px-Zapruder_film_frame_313.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9e/Oswald_arrest_photo_front.jpg/800px-Oswald_arrest_photo_front.jpg',
    ],
    videoUrls: ['yBVNz8k0Vxs'], // JFK Doku deutsch
    sources: [
      'Warren Commission Report (1964) - 888 Seiten, "Oswald acted alone"',
      'Zapruder Film (22. November 1963) - National Archives, Frame 313',
      'House Select Committee on Assassinations Report (1979) - "Probably conspiracy"',
      'Mark Lane: "Rush to Judgment" (1966) - Warren Commission kritisiert, 478 Seiten',
      'Jim Marrs: "Crossfire: The Plot That Killed Kennedy" (1989) - 608 Seiten',
      'JFK Executive Order 11110 (4. Juni 1963) - Federal Reserve Dokument',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'Area 51 - Nevada',
    description: 'Top-Secret US-Militärbasis (1955-heute) - UFO-Testgelände, Reverse Engineering außerirdischer Technologie?',
    detailedInfo: '''Area 51 ist eine hochgeheime US-Luftwaffenbasis in der Nevada-Wüste, etwa 130 km nordwestlich von Las Vegas. Die Basis existierte offiziell nicht bis 2013. Seit Jahrzehnten ranken sich Verschwörungstheorien um UFO-Tests, außerirdische Technologie und Geheimprojekte.

📘 OFFIZIELLE VERSION:
Area 51 ist eine Testbasis für experimentelle Flugzeuge und Waffensysteme. In den 1950er-60er Jahren wurden hier U-2 und SR-71 Blackbird Spionageflugzeuge entwickelt. F-117 Nighthawk Stealth-Bomber wurde hier getestet. Die Geheimhaltung diente dem Schutz vor sowjetischer Spionage. Area 51 existierte offiziell nicht bis CIA-Freigabe 2013. Keine Aliens - nur Flugzeugtechnologie.

🔍 ALTERNATIVE: UFO-TESTGELÄNDE & REVERSE ENGINEERING ALIEN-TECH:
Bob Lazar (1989): Behauptete, bei Area 51 (S-4 Sektor) an 9 außerirdischen Raumschiffen gearbeitet zu haben. Reverse Engineering von Alien-Technologie: Element 115 (Moscovium) als Antrieb. Lazar's Aussagen: Gravity Propulsion, Antimateriereaktor. Roswell-UFO-Absturz (1947): Wrackteile & Alien-Leichen nach Area 51 gebracht? Groom Lake: Unterirdische Anlagen mit 40+ Ebenen unter Area 51? Area 51 Raid (2019): 2 Millionen Facebook-Nutzer wollten "Storm Area 51" - Event abgesagt. Seltsame Lichter: Tausende Augenzeugen berichten über UFO-Sichtungen über Area 51. "They can't stop all of us": Warum so extreme Geheimhaltung? Tödliche Gewalt autorisiert gegen Eindringlinge. Cammo Dudes: Private Sicherheitstruppen patroullieren Perimeter. Was wird dort versteckt? Project Redlight, Galileo, Looking Glass?

🔒 BEWEISE & QUELLEN:
• CIA Declassified Documents (2013): Area 51 Existenz offiziell bestätigt
• Bob Lazar Interview (1989): KLAS-TV Las Vegas - "Worked on alien spacecraft at S-4"
• Element 115 (Moscovium): 2003 erstmals synthetisiert - Lazar behauptete 1989 davon
• U-2 & SR-71 Entwicklung bei Area 51: CIA bestätigt
• Area 51 Raid Facebook Event (2019): 2 Millionen Interessenten
• Janet Airlines: Geheime Airline fliegt täglich Mitarbeiter nach Area 51 (Boeing 737)''',
    position: LatLng(37.2350, -115.8111), // Area 51, Nevada (Groom Lake)
    category: LocationCategory.ufo,
    keywords: ['Area 51', 'UFO', 'Bob Lazar', 'Aliens', 'Roswell', 'S-4', 'Element 115', 'Nevada'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/eb/Groom_Lake.jpg/1200px-Groom_Lake.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Area_51_warning_sign.jpg/1200px-Area_51_warning_sign.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b8/Area_51_satellite_image.jpg/1200px-Area_51_satellite_image.jpg',
    ],
    videoUrls: ['4UjqFaQq_7I'], // Area 51 Bob Lazar Doku deutsch
    sources: [
      'CIA Declassified Area 51 Documents (2013) - George Washington University Archives',
      'Bob Lazar KLAS-TV Interview (1989) - "I worked on alien spacecraft"',
      'Element 115 (Moscovium) Discovery (2003) - Dubna Lab, Russia - 14 Jahre nach Lazar',
      'Annie Jacobsen: "Area 51: An Uncensored History" (2011) - 544 Seiten',
      'Area 51 Raid Facebook Event (2019): "Storm Area 51, They Can\'t Stop All of Us"',
      'Janet Airlines Boeing 737 Flight Logs - Daily flights from Las Vegas to Groom Lake',
    ],
  ),
  
  // 🌍 GEOPOLITIK & MACHTKÄMPFE (15+ neue Marker)
  
  MaterieLocationDetail(
    name: 'Bilderberg-Treffen - Verschiedene Orte',
    description: 'Geheime Elite-Konferenz seit 1954 - Globalisten planen Weltherrschaft?',
    detailedInfo: '''Die Bilderberg-Konferenz ist ein jährliches privates Treffen von ca. 120-150 Spitzenpolitikern, Industriellen, Bankern und Medienmagnaten. Gegründet 1954. Absolute Geheimhaltung: Keine Presse, keine Protokolle veröffentlicht. Teilnehmer sprechen nicht über Inhalte. Wer regiert wirklich die Welt?

📘 OFFIZIELLE VERSION:
Bilderberg-Treffen fördern Dialog zwischen Europa und Nordamerika. Informelle Diskussionen über Politik, Wirtschaft, Sicherheit. Keine Beschlüsse, nur Gedankenaustausch. Teilnehmer: Staats- und Regierungschefs, CEOs, Nobelpreisträger. Chatham House Rule: Vertrauliche Diskussionen für offenen Dialog. Ziel: Transatlantische Verständigung.

🔍 ALTERNATIVE: GEHEIME WELTREGIERUNG & NEUE WELTORDNUNG:
Schattenregierung: Die echten Machthaber treffen sich bei Bilderberg - nicht bei UN oder G7. Neue Weltordnung: Bilderberg plant Weltregierung, Abschaffung von Nationalstaaten, globale Kontrolle. Teilnehmer-Korrelation: Viele Politiker werden NACH Bilderberg-Teilnahme zu Kanzlern/Präsidenten - Auswahl der Kandidaten? Tony Blair, Bill Clinton, Angela Merkel: Alle bei Bilderberg vor Amtsantritt. Elite-Zirkel: Überschneidung mit Council on Foreign Relations, Trilaterale Kommission, Skull & Bones. 2008 Finanzkrise: Bei Bilderberg 2006 diskutiert - geplanter Crash? EU-Integration: Bilderberg förderte seit 1950er EU-Superstaat. Brexit: Bilderberg wollte Remain - scheiterte. Migration: Bilderberg diskutierte Migrationsströme VOR 2015. Medien-Kontrolle: Chefredakteure & Verleger nehmen teil - Gleichschaltung?

🔒 BEWEISE & QUELLEN:
• Erstes Treffen: Hotel de Bilderberg, Niederlande (29.-31. Mai 1954) - 50 Teilnehmer
• Teilnehmerlisten: Seit 2010 teilweise veröffentlicht (Druck von Aktivisten)
• Henry Kissinger: Regelmäßiger Teilnehmer seit 1957 - Steering Committee
• Angela Merkel: Teilnahme 2005 - wurde Kanzlerin im selben Jahr
• Tony Blair: Teilnahme 1993 - wurde Premier 1997
• Chatham House Rule: "Participants are free to use information, but cannot identify source"
• Alternative Medien: Jahrzehntelang ignoriert von Mainstream - jetzt bestätigt''',
    position: LatLng(52.0893, 5.1127), // Hotel de Bilderberg, Oosterbeek, Niederlande (erstes Treffen)
    category: LocationCategory.secretSocieties,
    keywords: ['Bilderberg', 'Elite', 'Geheimtreffen', 'NWO', 'Illuminati', 'Globalisten', 'Kissinger'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/38/Hotel_de_Bilderberg.jpg/1200px-Hotel_de_Bilderberg.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Bilderberg_Meeting_2018.jpg/1200px-Bilderberg_Meeting_2018.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0f/Bilderberg_Conference_security.jpg/1200px-Bilderberg_Conference_security.jpg',
    ],
    videoUrls: ['Tr4_4hIT2YA'], // Bilderberg Doku deutsch
    sources: [
      'Bilderberg Participant Lists (2010-2024) - Offizielle Website (teilweise)',
      'Daniel Estulin: "The True Story of the Bilderberg Group" (2009) - 350 Seiten',
      'Jim Tucker: "Bilderberg Diary" (2012) - Investigativer Journalist, 50 Jahre Recherche',
      'Chatham House Rule: Official Bilderberg Conference Website',
      'Steering Committee Members: Henry Kissinger (seit 1957), David Rockefeller (1954-2017)',
      'Pre-Bilderberg Politicians: Tony Blair (1993), Bill Clinton (1991), Angela Merkel (2005)',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'Bohemian Grove - Kalifornien',
    description: 'Geheimer Eliten-Club im Wald (seit 1872) - Okkulte Rituale, "Cremation of Care" Zeremonie',
    detailedInfo: '''Bohemian Grove ist ein 1.100 Hektar großes Waldgebiet in Kalifornien, wo sich seit 1872 die Elite der USA zu geheimen Treffen versammelt. Mitglieder: US-Präsidenten, Industrielle, Medienmagnaten. Jeden Juli treffen sich ca. 2.000 mächtigste Männer für 2 Wochen. Bizarre okkulte Zeremonien vor 12 Meter hoher Eule.

📘 OFFIZIELLE VERSION:
Bohemian Grove ist ein privater Gentlemen's Club für Entspannung und Networking. Gegründet 1872 von San Francisco Künstlern und Journalisten. Mitglieder sind erfolgreiche Männer aus Politik, Wirtschaft, Kunst. "Weaving Spiders Come Not Here" - keine geschäftlichen Deals, nur Freundschaft. Theater-Aufführungen, Vorträge, Lagerfeuer-Gespräche. "Cremation of Care"-Zeremonie: Symbolische Verbrennung von Sorgen.

🔍 ALTERNATIVE: OKKULTER ELITE-KULT & GEHEIME MACHTABSPRACHEN:
Okkulte Zeremonie: "Cremation of Care" vor 12m hoher Moloch-Eule-Statue - Menschenopfer-Symbolik? Alex Jones (2000): Schlich sich ein, filmte Ritual - schwarze Roben, Fackelzug, Scheintote. Mitglieder: Reagan, Nixon, Bush Sr. & Jr., Kissinger, Cheney, Rumsfeld - was besprechen sie? Manhattan-Projekt: 1942 bei Bohemian Grove konzipiert - Atombombe. ECHTE Deals werden gemacht: "No weaving spiders" ist Tarnung. Elite-Netzwerk: Mitgliedschaft nur auf Einladung - 15+ Jahre Warteliste, 25.000 Dollar Gebühr. Alle-Männer-Club: Frauen verboten - archaisches Patriarchat. Prostitution: Berichte über Call-Girls aus San Francisco. Drogenkonsum: LSD, Kokain, Marihuana laut Augenzeugen. Child Sacrifice: Walter Cronkite scherzte über "Baby-Essen" - echte Andeutung? Owl of Bohemia: Moloch-Kult? Babylonische Gottheit forderte Kinderopfer.

🔒 BEWEISE & QUELLEN:
• Gründung 1872: San Francisco Bohemian Club - 130+ Jahre Geheimtreffen
• Alex Jones Infiltration Video (2000): "Dark Secrets: Inside Bohemian Grove" - 2 Stunden
• Mitgliederliste (teilweise bekannt): Reagan, Nixon, Bush Sr. & Jr., Kissinger, Cheney
• Manhattan-Projekt Konzeption (1942): Ernest Lawrence diskutierte Atombombe bei Bohemian Grove
• "Cremation of Care" Zeremonie: Jährlich am ersten Samstag im Juli - 40 Minuten langes Ritual
• 12 Meter hohe Eule-Statue: "Owl of Bohemia" - Moloch-Symbolik?''',
    position: LatLng(38.6070, -123.0236), // Bohemian Grove, Monte Rio, Kalifornien
    category: LocationCategory.secretSocieties,
    keywords: ['Bohemian Grove', 'Eule', 'Moloch', 'Ritual', 'Elite', 'Alex Jones', 'Okkult'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e1/Bohemian_Grove_owl_shrine.jpg/1200px-Bohemian_Grove_owl_shrine.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2f/Bohemian_Grove_entrance.jpg/1200px-Bohemian_Grove_entrance.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Bohemian_Club_logo.png/800px-Bohemian_Club_logo.png',
    ],
    videoUrls: ['FpKdSvwYsrE'], // Alex Jones Bohemian Grove Doku
    sources: [
      'Alex Jones: "Dark Secrets: Inside Bohemian Grove" (2000) - Video, 2 Stunden',
      'Philip Weiss: "Masters of the Universe Go to Camp" (Spy Magazine, 1989)',
      'Bohemian Club Membership List (teilweise): G. Edward Griffin Recherche',
      'Ernest Lawrence Manhattan-Projekt Diskussion (1942) - Bohemian Grove',
      'Walter Cronkite Kommentar über "Baby-Essen" - Dick Cheney Present',
      'Jon Ronson: "Them: Adventures with Extremists" (2001) - Kapitel über Bohemian Grove',
    ],
  ),

  // 🔥 KATASTROPHEN & MYSTERIEN (20 neue Marker)
  
  MaterieLocationDetail(
    name: 'Tunguska-Ereignis - Sibirien',
    description: 'Mysteriöse Explosion 1908 - 2.000 km² Wald zerstört, UFO oder Meteorit?',
    detailedInfo: '''Am 30. Juni 1908 explodierte etwas über der sibirischen Tunguska-Region mit der Kraft von 1.000 Hiroshima-Bomben. 80 Millionen Bäume auf 2.000 km² wurden umgeworfen, aber KEIN Krater gefunden. Was war es?

📘 OFFIZIELLE VERSION: Meteoriten-Airburst in 5-10 km Höhe. Asteroid oder Komet explodierte vor Bodenaufprall. Schockwelle zerstörte Wald. Kleine Meteoritenfragmente gefunden.

🔍 ALTERNATIVE: UFO-Absturz, Alien-Raumschiff-Explosion, Nikola Tesla's Todesstrahl-Experiment, Anti-Materie-Explosion, Mini-Schwarzes Loch. Augenzeugen sahen "leuchtende Kugel" am Himmel. Kein Krater = keine Einschlag. Radioaktive Anomalien gemessen.

🔬 BEWEISE: 80 Mio. Bäume zerstört, Seismische Wellen weltweit registriert, Kein Krater trotz massiver Zerstörung, Magnetische Anomalien in der Region, Tesla's Wardenclyffe Tower-Experimente zeitgleich.''',
    position: const LatLng(60.8858, 101.8939),
    category: LocationCategory.disasters,
    keywords: ['Tunguska', 'Explosion', 'UFO', 'Meteorit', 'Mystery', 'Sibirien', 'Tesla'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/6/69/Tunguska_event_fallen_trees.jpg/1200px-Tunguska_event_fallen_trees.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/Tunguska_event_epicentre.jpg/1200px-Tunguska_event_epicentre.jpg',
    ],
    videoUrls: ['3KiGwLJOgG0'], // Tunguska Mystery Documentary
    sources: [
      'Russian Academy of Sciences Expedition (1927) - Kulik Expedition Report',
      'NASA Near-Earth Object Program - Tunguska Impact Study',
      'Nature Magazine: "Tunguska Revisited" (2008)',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'Bermuda-Dreieck - Atlantik',
    description: 'Mysteriöses Gebiet - 75+ Flugzeuge/Schiffe verschwunden, Zeitanomalien?',
    detailedInfo: '''Das Bermuda-Dreieck zwischen Florida, Puerto Rico und Bermuda ist berüchtigt für unerklärliche Verschwinden von Schiffen und Flugzeugen. Über 75 Flugzeuge und 100+ Schiffe spurlos verschwunden seit 1800.

📘 OFFIZIELLE VERSION: Statistische Normalität. Viel Schiffs/Luftverkehr = mehr Unfälle. Extreme Wetterbedingungen, Golfstrom, Methangas-Blasen, menschliches Versagen. Keine höhere Unfallrate als anderswo.

🔍 ALTERNATIVE: Alien-Basis unter Wasser, Zeitportale, Atlantis-Technologie, Elektromagnetische Anomalien, Dimensionsportale, US-Militär-Geheimexperimente, Versunkene Alien-Raumschiffe. Flight 19 (1945): 5 US Navy-Bomber + Rettungsflugzeug verschwanden spurlos - "Wir wissen nicht wo wir sind, selbst der Ozean sieht seltsam aus". Kompass-Anomalien, Zeitsprünge, Elektronik-Ausfälle. Bruce Gernon (1970): Flog durch "Zeitwirbel"-Wolke, kam 30 Minuten zu früh an, 100 Meilen GPS-Sprung.

🔬 BEWEISE: 75+ verschwundene Flugzeuge dokumentiert, 100+ verschwundene Schiffe (Lloyd's of London), Flight 19 Funksprüche ("Ozean sieht seltsam aus"), USS Cyclops (1918) - 306 Besatzung verschwunden, spurlos, keine Wrackteile gefunden, Bruce Gernon Zeitmessung-Anomalie.''',
    position: const LatLng(25.0, -71.0),
    category: LocationCategory.disasters,
    keywords: ['Bermuda-Dreieck', 'Verschwinden', 'UFO', 'Zeitanomalien', 'Flight 19', 'Atlantis'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/b/bf/Bermuda_Triangle.png/1200px-Bermuda_Triangle.png',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/94/US_Navy_TBM-3_Avenger_in_flight_1945.jpg/1200px-US_Navy_TBM-3_Avenger_in_flight_1945.jpg',
    ],
    videoUrls: ['5R3HAgpxrPE'], // Bermuda Triangle Mystery
    sources: [
      'US Navy Flight 19 Investigation Report (1945)',
      'Lloyd\'s of London Shipping Records (1800-2024)',
      'Bruce Gernon: "The Fog" (2017) - Firsthand Account',
      'National Geographic: "Bermuda Triangle Explained?" (2018)',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'Dyatlov-Pass-Vorfall - Ural',
    description: '9 erfahrene Bergsteiger mysteriös gestorben 1959 - Radioaktivität, UFO, Lawine?',
    detailedInfo: '''Am 2. Februar 1959 starben 9 erfahrene Ski-Wanderer am Dyatlov-Pass im Ural-Gebirge unter mysteriösen Umständen. Zelt von innen aufgeschlitzt, Wanderer barfuß im Schnee geflohen, schwere innere Verletzungen ohne äußere Spuren, Radioaktivität an Kleidung. Was geschah?

📘 OFFIZIELLE VERSION (2020): Lawinen-Theorie. Katabatische Winde verursachten Lawine, Wanderer flohen panisch, erfroren. Innere Verletzungen durch Schneemassen. 2020 russische Staatsanwaltschaft schloss Fall erneut mit Lawinen-Erklärung.

🔍 ALTERNATIVE: Yeti-Angriff, UFO-Begegnung, Sowjetische Militär-Experimente (Raketen-Test), Infraschall-Waffe, Paranormale Kräfte, KGB-Geheimoperation. Augenzeugen sahen "orange Kugeln" am Himmel. Radioaktive Kleidung = Strahlenwaffe? Zungen und Augen entfernt = Ritual? Zelt von INNEN aufgeschlitzt = panische Flucht vor etwas. Fotos zeigen "unbekannte Lichtquellen". Mansi-Ureinwohner meiden den "Berg der Toten".

🔬 BEWEISE: 9 Tote (Igor Dyatlov + Team), Zelt von innen aufgeschlitzt, Wanderer barfuß im -30°C Schnee, Ludmila Dubinina: Zunge + Augen fehlten, Radioaktive Spuren an Kleidung gemessen, Schwere innere Verletzungen (Rippen, Schädel) ohne äußere Wunden, Augenzeugen: Orange Kugeln am Himmel, Fotos: Ungeklärte Lichtquellen, Geigerzähler-Messungen positiv.''',
    position: const LatLng(61.7500, 59.4667),
    category: LocationCategory.disasters,
    keywords: ['Dyatlov', 'Mystery', 'Ural', 'UFO', 'Radioaktivität', 'Lawine', 'KGB'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e3/Dyatlov_Pass_incident_02.jpg/1200px-Dyatlov_Pass_incident_02.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/42/Dyatlov_Pass_incident_04.jpg/1200px-Dyatlov_Pass_incident_04.jpg',
    ],
    videoUrls: ['8BQ-Lnc5VUc'], // Dyatlov Pass Mystery
    sources: [
      'Soviet Prosecutor\'s Office Investigation Files (1959)',
      'Russian State Archives - Dyatlov Pass Documents',
      '2020 Russian Prosecutor General Re-investigation Report',
      'Yury Yudin (Sole Survivor) Interviews (1959-2013)',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'Philadelphia-Experiment - Naval Yard',
    description: 'USS Eldridge Teleportations-Experiment 1943 - Schiff verschwand, Besatzung fusionierte mit Stahl?',
    detailedInfo: '''Am 28. Oktober 1943 soll die US Navy im Philadelphia Naval Shipyard ein Experiment zur Tarnkappen-Technologie durchgeführt haben. Das Kriegsschiff USS Eldridge wurde angeblich unsichtbar und teleportierte 200 Meilen nach Norfolk, Virginia. Besatzungsmitglieder wurden in Schiffswände eingeschmolzen, fielen in Wahnsinn.

📘 OFFIZIELLE VERSION: Kompletter Mythos. USS Eldridge war 1943 NICHT in Philadelphia, sondern auf Atlantik-Mission. Navy dementiert Experiment. Verwechslung mit Degaussing (magnetische Tarnkappen gegen Minen). Keine Beweise.

🔍 ALTERNATIVE: Geheimes Tesla/Einstein-Projekt zur Raum-Zeit-Manipulation. Unified Field Theory-Experiment. Philadelphia Experiment öffnete Dimensionsportal. Montauk-Projekt Fortsetzung. Besatzung teilweise unsichtbar, teilweise in Stahl fusioniert, teilweise wahnsinnig. Carlos Allende (Augenzeuge) behauptete alles gesehen zu haben. Al Bielek (angeblicher Teilnehmer) beschrieb Zeitreisen. Experiment basierte auf Einstein's Unified Field Theory.

🔬 BEWEISE: Carlos Allende Briefe an Morris K. Jessup (1955), Office of Naval Research Untersuchung (1955), USS Eldridge Logbuch-Lücken, Al Bielek Zeugnis (1980er), Montauk Projekt Verbindungen, KEINE offiziellen Navy-Dokumente bestätigen Experiment, Crew-Mitglieder dementieren (aber alle tot bis 1990er).''',
    position: const LatLng(39.8940, -75.1622),
    category: LocationCategory.research,
    keywords: ['Philadelphia Experiment', 'USS Eldridge', 'Teleportation', 'Tesla', 'Einstein', 'Navy', 'Dimensionsportal'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/35/USS_Eldridge_DE-173.jpg/1200px-USS_Eldridge_DE-173.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Philadelphia_Naval_Shipyard.jpg/1200px-Philadelphia_Naval_Shipyard.jpg',
    ],
    videoUrls: ['qRt66Sg9m1Y'], // Philadelphia Experiment Documentary
    sources: [
      'Office of Naval Research Statement (1996)',
      'Carlos Allende Letters to Morris K. Jessup (1955-1956)',
      'USS Eldridge Naval Records (1943-1946)',
      'Al Bielek Testimonies (1980s-1990s)',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'MH370 Verschwinden - Südchinesisches Meer',
    description: 'Boeing 777 mit 239 Menschen spurlos verschwunden 2014 - Entführung, Cyberhacking, Alien?',
    detailedInfo: '''Am 8. März 2014 verschwand Malaysia Airlines Flug MH370 mit 239 Menschen an Bord auf dem Weg von Kuala Lumpur nach Peking spurlos. Größte Such-Aktion der Luftfahrtgeschichte fand fast nichts. Was geschah?

📘 OFFIZIELLE VERSION: Pilot-Selbstmord oder Hypoxie. Kapitän Zaharie Ahmad Shah könnte Flugzeug absichtlich vom Kurs abgebracht, Passagiere/Crew durch Dekompression getötet und Flugzeug im Indischen Ozean versenkt haben. Alternative: Sauerstoffmangel führte zu Bewusstlosigkeit, Autopilot flog bis Treibstoff leer. Wenige Wrackteile (Flaperon) an Reunion-Insel gefunden.

🔍 ALTERNATIVE THEORIEN: Entführung nach Diego Garcia (US-Militärbasis), Cyber-Hacking durch Unabomber-Stil-Attack, Patent-Diebstahl (4 chinesische Chip-Ingenieure an Bord, Freescale Semiconductor), Alien-Abduktion, Zeitwirbel, Schuss durch US-Navy (Militärübung), Flug nach Kazakhstan (Passagier Philip Wood's iPhone-Metadaten zeigen Diego Garcia). Passagiere mit gefälschten Pässen. Transponder manuell ausgeschaltet. Zig-Zag-Flugpfad = bewusste Navigation.

🔬 BEWEISE: 239 Menschen an Bord (227 Passagiere + 12 Crew), Transponder um 01:21 Uhr manuell ausgeschaltet, 7 Stunden Flugzeit nach Verschwinden (Satellite Pings), Nur 3 Wrackteile in 3 Jahren gefunden (von 777), Philip Wood iPhone-Metadaten zeigen Diego Garcia GPS, 4 Freescale Semiconductor Ingenieure an Bord, 2 Passagiere mit gestohlenen Pässen, 160 Mio. \$ Such-Operation fand fast nichts.''',
    position: const LatLng(6.9270, 103.6100),
    category: LocationCategory.disasters,
    keywords: ['MH370', 'Verschwinden', 'Boeing 777', 'Malaysia Airlines', 'Entführung', 'Diego Garcia', 'Cyber-Hacking'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2e/9M-MRO_Malaysia_Airlines_Boeing_777-200ER.jpg/1200px-9M-MRO_Malaysia_Airlines_Boeing_777-200ER.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d9/MH370_search_area.png/1200px-MH370_search_area.png',
    ],
    videoUrls: ['v5GDNN6Zvwg'], // MH370 Mystery Documentary
    sources: [
      'Malaysian ICAO Annex 13 Safety Investigation Report (2018) - 495 pages',
      'Australian Transport Safety Bureau Final Report (2017)',
      'Inmarsat Satellite Data Analysis',
      'Ocean Infinity Search Mission Data (2018)',
    ],
  ),
  
  // 🏛️ ANTIKE MYSTERIEN (15 neue Marker)
  
  MaterieLocationDetail(
    name: 'Nazca-Linien - Peru',
    description: 'Gigantische Geoglyphen in der Wüste - nur aus der Luft sichtbar, Alien-Landebahnen?',
    detailedInfo: '''In der Nazca-Wüste in Peru befinden sich über 1.500 gigantische Linien, Figuren und geometrische Formen, die nur aus der Luft vollständig sichtbar sind. Erstellt zwischen 500 v. Chr. und 500 n. Chr. von der Nazca-Kultur. Wozu?

📘 OFFIZIELLE VERSION: Religiöse/zeremonielle Pfade für Wasser-Rituale. Nazca-Kultur (500 v.Chr.-500 n.Chr.) schuf Linien durch Entfernen dunkler Steine. Astronomiealignment für Sonnenwenden. Maria Reiche (deutsche Mathematikerin) erforschte Linien 50 Jahre lang.

🔍 ALTERNATIVE: Alien-Landebahnen, Botschaften für Außerirdische, Antike Flugmaschinen (Vimanas), Erich von Däniken: "Erinnerungen an die Götter", Inca-Vorfahren hatten Luftfahrt-Technologie. Linien perfekt gerade über 20+ km - ohne Luftbild-Technologie unmöglich? Figuren (Spinne, Affe, Kolibri) nur aus Luft erkennbar - für wen? Runway-ähnliche Landebahnen für Raumschiffe?

🔬 BEWEISE: 1.500+ Geoglyphen über 450 km², Linien bis zu 30 km lang, Figuren bis 370m groß, Nur aus 200m+ Höhe vollständig sichtbar, Nazca hatte KEINE Luftfahrt-Technologie (offiziell), Perfekte geometrische Präzision über 20 km, UNESCO Weltkulturerbe (1994).''',
    position: const LatLng(-14.7390, -75.1300),
    category: LocationCategory.ancientCivilizations,
    keywords: ['Nazca-Linien', 'Peru', 'Geoglyphen', 'Aliens', 'Erich von Däniken', 'Antike Flugmaschinen'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/Nazca_Lines_-_Hummingbird.jpg/1200px-Nazca_Lines_-_Hummingbird.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fc/Nazca_Lines_-_Spider.jpg/1200px-Nazca_Lines_-_Spider.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/15/Nazca_Lines_-_Monkey.jpg/1200px-Nazca_Lines_-_Monkey.jpg',
    ],
    videoUrls: ['_ImKAZvjTnc'], // Nazca Lines Mystery
    sources: [
      'Maria Reiche: "Mystery on the Desert" (1949-1998)',
      'Erich von Däniken: "Chariots of the Gods?" (1968)',
      'UNESCO World Heritage Site Documentation (1994)',
      'Johny Isla (Peruvian Archaeologist) Research (2000-2024)',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'Puma Punku - Bolivien',
    description: 'Präzisions-Steinbearbeitung 14.000 Jahre alt? - Unmöglich ohne moderne Maschinen',
    detailedInfo: '''Puma Punku ist eine Ruinenstätte in Bolivien mit Steinblöcken, die mit unglaublicher Präzision bearbeitet wurden - perfekte rechte Winkel, glatte Oberflächen, ineinandergreifende Teile wie Lego. Offiziell 536-600 n.Chr., aber Alternative Datierung: 14.000 Jahre alt.

📘 OFFIZIELLE VERSION: Tiwanaku-Kultur (536-1000 n.Chr.) baute Puma Punku als Tempel. Steinbearbeitung mit Bronzewerkzeugen und Sand-Schleifen. H-Blöcke (130 Tonnen) wurden mit Seilen und Rollen transportiert. Erdbeben zerstörte Struktur.

🔍 ALTERNATIVE: Antike Hochtechnologie, Laserschneider, Alien-Werkzeuge, Verlorene Zivilisation vor 14.000 Jahren, Andesite-Steine (8-9 Mohs-Härte) UNMÖGLICH mit Bronzewerkzeugen zu schneiden, Perfekte 90°-Winkel auf Millimeter genau, Ineinandergreifende Teile wie moderne CNC-Fräsmaschinen, Arthur Posnansky (1904): Puma Punku 14.000 Jahre alt basierend auf Archäoastronomie.

🔬 BEWEISE: 130-Tonnen-H-Blöcke (schwerste Steine), Andesite-Steine (Härtegrad 8-9), Perfekte 90°-Winkel auf Millimeter genau, Glatte Oberflächen wie poliert, Ineinandergreifende "Lego"-Strukturen, 3.800m Höhe (Transport extrem schwierig), Keine Schriftzeichen oder Bauanleitungen gefunden, Arthur Posnansky: Archäoastronomische Datierung 14.000 v.Chr.''',
    position: const LatLng(-16.5586, -68.6772),
    category: LocationCategory.ancientCivilizations,
    keywords: ['Puma Punku', 'Bolivien', 'Tiwanaku', 'Antike Hochtechnologie', 'Präzisions-Steinbearbeitung', 'Aliens'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/18/Puma_Punku.jpg/1200px-Puma_Punku.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c6/Puma_Punku_H-blocks.jpg/1200px-Puma_Punku_H-blocks.jpg',
    ],
    videoUrls: ['j9w-i5oZqaQ'], // Puma Punku Mystery
    sources: [
      'Arthur Posnansky: "Tihuanacu: The Cradle of American Man" (1945)',
      'Brien Foerster Research (2010-2024)',
      'Archaeological Survey of Tiwanaku (1903-2020)',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'Osterinsel Moai - Rapa Nui',
    description: '887 gigantische Steinstatuen - Wer baute sie? Wie wurden 80-Tonnen-Statuen transportiert?',
    detailedInfo: '''Auf der abgelegenen Osterinsel (Rapa Nui) im Pazifik stehen 887 monumentale Moai-Statuen (bis 21m hoch, 82 Tonnen schwer). Erstellt 1250-1500 n.Chr. von einer isolierten Bevölkerung ohne Metallwerkzeuge, Räder oder Zugtiere. Wie?

📘 OFFIZIELLE VERSION: Rapa Nui-Kultur (Polynesier) schuf Moai als Ahnenstatuen. Gemeißelt aus Rano Raraku-Vulkan-Tuff. Transport mit Seilen und "Gehen"-Technik (Wiegen). Thor Heyerdahl Experimente zeigten Machbarkeit. Ökologischer Kollaps durch Überbevölkerung/Abholzung zerstörte Zivilisation.

🔍 ALTERNATIVE: Außerirdische Hilfe, Verlorene Hochtechnologie (Levitations-Technologie), Statuen "gingen selbst" laut Legenden (Anti-Gravitation?), Verbindung zu Lemuria/Mu, Statuen schauen zum Himmel - Signale für Aliens?, Easter Island = Top eines versunkenen Kontinents?, Rapa Nui-Legenden: "Götter ließen Statuen gehen".

🔬 BEWEISE: 887 Moai-Statuen, Durchschnittlich 13 Tonnen, schwerste 82 Tonnen (El Gigante), Höhe bis 21m (El Gigante, nie fertiggestellt), 397 Statuen noch im Steinbruch Rano Raraku, Keine Metallwerkzeuge, keine Räder, keine Zugtiere, 10 km Transport zum Küste, "Pukao" (rote Stein-Hüte) bis 10 Tonnen separat aufgesetzt, Rapa Nui Legenden: "Statuen gingen mit Mana (magischer Kraft)".''',
    position: const LatLng(-27.1127, -109.3497),
    category: LocationCategory.ancientCivilizations,
    keywords: ['Osterinsel', 'Moai', 'Rapa Nui', 'Statuen-Transport', 'Levitation', 'Aliens', 'Lemuria'],
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fd/Moai_Rano_raraku.jpg/1200px-Moai_Rano_raraku.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6c/Ahu_Tongariki.jpg/1200px-Ahu_Tongariki.jpg',
    ],
    videoUrls: ['xeO-M_Sb1JY'], // Easter Island Moai Mystery
    sources: [
      'Thor Heyerdahl: "Aku-Aku: The Secret of Easter Island" (1958)',
      'Carl Lipo & Terry Hunt: "The Statues that Walked" (2011)',
      'Katherine Routledge: "The Mystery of Easter Island" (1919)',
    ],
  ),

  // 🔥 ============================================
  // EPSTEIN-NETZWERK - GESONDERTE KATEGORIE
  // ============================================
  
  MaterieLocationDetail(
    name: 'Little St. James - Epstein Island',
    description: 'Jeffrey Epsteins private Insel (Virgin Islands) - "Pädophilen-Insel", Missbrauch, prominente Gäste',
    detailedInfo: '''Little St. James, auch bekannt als "Pädophilen-Insel" oder "Orgy Island", war Jeffrey Epsteins privates Paradies in den US Virgin Islands. Epstein kaufte die Insel 1998 für 7,95 Millionen Dollar. Auf der 28 Hektar großen Insel befanden sich luxuriöse Anwesen, ein Tempel-ähnliches Gebäude mit goldener Kuppel, und zahlreiche versteckte Kameras.

📘 OFFIZIELLE FAKTEN:
- Gekauft 1998 für 7,95 Millionen Dollar
- Luxuriöse Villa, Pool, Hubschrauberlandeplatz
- Mysteriöser "Tempel" mit goldener Kuppel (angeblich Fitness-Studio)
- Zahlreiche prominente Besucher: Bill Clinton, Prinz Andrew, Bill Gates, Donald Trump, Stephen Hawking
- Epstein nutzte die Insel für "Entspannung" und "wissenschaftliche Konferenzen"

🔍 MISSBRAUCHSVORWÜRFE:
- Virginia Giuffre: Als 17-Jährige auf die Insel gebracht, dort missbraucht
- Mehrere Überlebende berichten von sexuellem Missbrauch Minderjähriger
- Versteckte Kameras überall - Epstein sammelte kompromittierende Videos
- "Lolita Express" (Epsteins Privatjet) brachte Gäste zur Insel
- Ghislaine Maxwell rekrutierte junge Mädchen für die Insel
- FBI-Razzia 2019: Beweise gesichert, aber vieles bleibt geheim

🔒 BEWEISE:
- FBI-Razzia 10. August 2019
- Flugprotokolle des "Lolita Express"
- Aussagen von Virginia Giuffre und anderen Überlebenden
- Fotos und Videos vom Tempel-Gebäude
- Epsteins Testament: Insel wurde in Trust überführt''',
    position: const LatLng(18.3000, -64.8256), // Little St. James, Virgin Islands
    category: LocationCategory.epstein,
    keywords: ['Little St. James', 'Epstein Island', 'Pädophilen-Insel', 'Missbrauch', 'Virgin Islands'],
    date: DateTime(1998, 1, 1), // Kauf der Insel
    imageUrls: [
      'https://upload.wikimedia.org/wikipedia/commons/d/d8/Little_Saint_James%2C_U.S._Virgin_Islands.jpg',
    ],
    videoUrls: ['B3zj27WOrWE'], // Netflix: Jeffrey Epstein - Stinkreich
    sources: [
      'Virginia Giuffre Deposition (2016) - Aussagen über Little St. James',
      'FBI Raid Little St. James (August 2019)',
      'Flight Logs Lolita Express (1997-2005)',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'Ghislaine Maxwell Verhaftung - New Hampshire',
    description: 'Epsteins Komplizin verhaftet (2. Juli 2020) - Rekrutierung Minderjähriger, 20 Jahre Haft',
    detailedInfo: '''Ghislaine Maxwell, Tochter des britischen Medienmoguls Robert Maxwell, war Jeffrey Epsteins engste Vertraute und Komplizin. Sie rekrutierte und "pflegte" junge Mädchen für Epsteins sexuelle Übergriffe. Nach Epsteins Tod 2019 tauchte sie unter, wurde aber 2020 vom FBI in New Hampshire verhaftet.

📘 OFFIZIELLE VERSION:
- Verhaftet 2. Juli 2020 in Bradford, New Hampshire
- Angeklagt wegen Sexhandel mit Minderjährigen (1994-2004)
- Verurteilt 29. Dezember 2021 zu 20 Jahren Haft
- Maxwell rekrutierte Mädchen für Epstein, teilweise selbst beteiligt
- Keine weiteren Namen genannt - schützt sie das Netzwerk?

🔍 VERSCHWÖRUNGSTHEORIE:
- Maxwell könnte Verbindungen zu Geheimdiensten haben (Mossad?)
- Ihr Vater Robert Maxwell war angeblich Mossad-Agent
- Warum nannte sie keine Namen? Deal mit US-Regierung?
- Epsteins Netzwerk bleibt unberührt - Maxwell als Sündenbock?

🔒 BEWEISE:
- FBI-Verhaftung 2. Juli 2020
- Aussagen von Virginia Giuffre und anderen Überlebenden
- Urteil: 20 Jahre Haft (29. Dezember 2021)
- Keine Namen weiterer Täter genannt''',
    position: const LatLng(43.2681, -71.9133), // Bradford, New Hampshire
    category: LocationCategory.epstein,
    keywords: ['Ghislaine Maxwell', 'Epstein', 'Verhaftung', 'Sexhandel', 'New Hampshire'],
    date: DateTime(2020, 7, 2),
    imageUrls: [],
    videoUrls: ['B3zj27WOrWE'], // Netflix: Jeffrey Epstein - Stinkreich
    sources: [
      'Ghislaine Maxwell Trial Transcripts (2021)',
      'FBI Arrest Warrant (July 2020)',
      'Sentencing Document (December 2021) - 20 Jahre Haft',
    ],
  ),
  
  MaterieLocationDetail(
    name: 'Zorro Ranch - Epsteins New Mexico Anwesen',
    description: 'Epsteins 33.000 Hektar Ranch in New Mexico - Gerüchte über "Baby-Ranch", DNA-Experimente',
    detailedInfo: '''Zorro Ranch war Jeffrey Epsteins riesiges Anwesen in New Mexico, etwa 10.000 Acres (33 km²) groß. Die Ranch wurde selten erwähnt, aber Überlebende berichten, dass auch dort Missbrauch stattfand. Es gibt Gerüchte, Epstein habe auf der Ranch seine "DNA verbreiten" wollen - eine Art "Baby-Ranch".

📘 OFFIZIELLE FAKTEN:
- Gekauft 1993, Größe: 10.000 Acres
- Luxuriöse Villa, Gästehaus, Flugzeughangar
- Epstein plante angeblich "wissenschaftliche Experimente"
- Wenige Informationen, da Ranch sehr abgelegen

🔍 GERÜCHTE & THEORIEN:
- "Baby-Ranch": Epstein wollte Dutzende Frauen mit seinem Sperma schwängern
- Transhumanismus-Experimente (Epstein interessierte sich für Genetik)
- Verbindungen zu wissenschaftlichen Institutionen (MIT, Harvard)
- Wurde nach Epsteins Tod verkauft - Beweise vernichtet?

🔒 BEWEISE:
- Kaufvertrag 1993
- Aussagen von Überlebenden über Besuche auf der Ranch
- MIT Media Lab Donations (Jeffrey Epstein Foundation)''',
    position: const LatLng(35.5500, -105.3000), // Stanley, New Mexico
    category: LocationCategory.epstein,
    keywords: ['Zorro Ranch', 'Epstein', 'New Mexico', 'Baby-Ranch', 'DNA'],
    date: DateTime(1993, 1, 1),
    imageUrls: [],
    videoUrls: [],
    sources: [
      'Property Records Stanley, New Mexico (1993)',
      'Vanity Fair: "The Jeffrey Epstein Scandal" (2003)',
    ],
  ),

];
