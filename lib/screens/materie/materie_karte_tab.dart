import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../widgets/toast_helper.dart';
import '../../widgets/checkin_button.dart';

/// MATERIE-Karte Tab - OpenStreetMap mit Forschungs-Hotspots
class MaterieKarteTab extends StatefulWidget {
  const MaterieKarteTab({super.key});

  @override
  State<MaterieKarteTab> createState() => _MaterieKarteTabState();
}

class _MaterieKarteTabState extends State<MaterieKarteTab> {
  final MapController _mapController = MapController();
  
  // Map-Modi
  String _selectedMapMode = 'Standard';
  final List<String> _mapModes = ['Standard', 'Satellit', 'Hell', 'Dunkel', 'Topografisch'];
  
  // MATERIE-spezifische Locations mit detaillierten Informationen
  final List<MaterieLocation> _locations = [
    MaterieLocation(
      name: 'Wien - Geopolitisches Zentrum',
      description: 'Internationale Organisationen, UNO-Standort, neutrale Verhandlungsstadt',
      detailedInfo: '''
Wien ist seit dem 19. Jahrhundert ein bedeutendes Zentrum der internationalen Diplomatie. Die Stadt beherbergt zahlreiche UN-Organisationen und dient als neutrale Plattform für Verhandlungen zwischen Großmächten.

**Wichtige Organisationen:**
• UN-Büro Wien (UNOV) - drittgrößter UN-Standort
• IAEO (Internationale Atomenergie-Organisation)
• OSZE (Organisation für Sicherheit und Zusammenarbeit)
• OPEC (Organisation erdölexportierender Länder)

**Historische Bedeutung:**
Wien war historisch Treffpunkt für Geheimdiplomatie und internationale Kongresse. Der Wiener Kongress (1814-1815) legte die Grundlage für das moderne Völkerrecht.

**Geopolitische Relevanz:**
Als neutraler Staat zwischen Ost und West spielte Österreich im Kalten Krieg eine Schlüsselrolle. Heute ist Wien ein wichtiger Knotenpunkt für Dialog zwischen unterschiedlichen Machtblöcken.
''',
      coordinates: '48.2082°N, 16.3738°E',
      position: const LatLng(48.2082, 16.3738),
      type: MaterieLocationType.geopolitics,
      category: 'Geopolitik',
    ),
    MaterieLocation(
      name: 'Berlin - Alternative Medien Hub',
      description: 'Zentrum für unabhängigen Journalismus und kritische Berichterstattung',
      detailedInfo: '''
Berlin hat sich als europäisches Zentrum für alternative Medien und unabhängigen Journalismus etabliert. Die Stadt zieht Aktivisten, Whistleblower und investigative Journalisten aus der ganzen Welt an.

**Medien-Landschaft:**
• Zahlreiche unabhängige Nachrichtenportale
• Investigative Recherche-Netzwerke
• Alternative Presseagenturen
• Kritische Kulturproduktion

**Transparenz-Bewegung:**
Berlin beherbergt wichtige Organisationen für Informationsfreiheit und Transparenz. Die Stadt wurde zum Zufluchtsort für Journalisten, die kritische Recherchen durchführen.

**Digitale Freiheit:**
Starke Hackerspace-Kultur und Netzaktivismus. Der Chaos Computer Club (CCC) hat hier seinen Ursprung und kämpft für digitale Rechte und Informationsfreiheit.
''',
      coordinates: '52.5200°N, 13.4050°E',
      position: const LatLng(52.5200, 13.4050),
      type: MaterieLocationType.alternativeMedia,
      category: 'Alternative Medien',
    ),
    MaterieLocation(
      name: 'Genf - CERN & Forschungszentrum',
      description: 'Europäische Organisation für Kernforschung, wissenschaftliche Durchbrüche',
      detailedInfo: '''
CERN (Conseil Européen pour la Recherche Nucléaire) ist das weltweit größte Zentrum für Teilchenphysik. Hier wurde das Internet erfunden und grundlegende Entdeckungen zur Struktur der Materie gemacht.

**Wissenschaftliche Meilensteine:**
• Entdeckung des Higgs-Bosons (2012) - "Gottesteilchen"
• Erfindung des World Wide Web (1989) durch Tim Berners-Lee
• Large Hadron Collider (LHC) - größter Teilchenbeschleuniger der Welt
• Antimaterie-Forschung und Dunkle Materie-Studien

**Technologie:**
27 km langer unterirdischer Teilchenbeschleuniger-Ring. Kollisionen bei nahezu Lichtgeschwindigkeit simulieren Bedingungen des Urknalls.

**Geheimhaltung & Spekulationen:**
Viele Verschwörungstheorien ranken sich um CERN: Portale zu anderen Dimensionen, Manipulation der Raumzeit, Schwarze Löcher. Die Forschung bleibt für Außenstehende schwer durchschaubar.
''',
      coordinates: '46.2044°N, 6.1432°E',
      position: const LatLng(46.2044, 6.1432),
      type: MaterieLocationType.research,
      category: 'Forschung',
    ),
    MaterieLocation(
      name: 'Brüssel - EU-Machtzentrum',
      description: 'Europäische Union Hauptquartier, politische Entscheidungen',
      detailedInfo: '''
Brüssel ist das administrative Herz der Europäischen Union und NATO. Hier werden Entscheidungen getroffen, die 450 Millionen EU-Bürger betreffen.

**EU-Institutionen:**
• Europäische Kommission - Exekutivorgan der EU
• Europäischer Rat - Gipfeltreffen der Staats- und Regierungschefs
• Europäisches Parlament - Legislatives Organ
• Nato-Hauptquartier - Militärische Allianz

**Lobbyismus:**
Über 30.000 Lobbyisten beeinflussen EU-Gesetzgebung. Brüssel gilt als Zentrum der Interessenvertretung von Konzernen und NGOs.

**Kritik & Transparenz:**
Demokratiedefizit der EU wird oft kritisiert. Komplexe Entscheidungsprozesse und Intransparenz fördern Skepsis. Alternative Medien berichten über Verflechtungen zwischen Politik und Wirtschaft.
''',
      coordinates: '50.8503°N, 4.3517°E',
      position: const LatLng(50.8503, 4.3517),
      type: MaterieLocationType.geopolitics,
      category: 'Geopolitik',
    ),
    MaterieLocation(
      name: 'London - Finanzzentrum',
      description: 'Globales Finanzzentrum, Wirtschaftsmacht, historische Geheimgesellschaften',
      detailedInfo: '''
Die City of London ist das historische Zentrum des globalen Finanzsystems. Ein autonomer Stadtstaat im Herzen Londons mit eigenen Gesetzen und Privilegien.

**Finanzmacht:**
• City of London - ältestes Bankenzentrum der Welt
• Kontrolle über Offshore-Steueroasen (Cayman Islands, Jersey, etc.)
• Zentrum des Eurodollar-Marktes
• Versicherungsmarkt Lloyd's of London

**Geheimgesellschaften:**
London war historisch Zentrum von Geheimgesellschaften: Freimaurer, Rosenkreuzer, Illuminati-Verbindungen. Die Elite trifft sich in exklusiven Clubs.

**Macht-Strukturen:**
Die City of London hat eigene Polizei und Verwaltung. Der Lord Mayor der City ist nicht der Bürgermeister von London - zwei getrennte Entitäten mit unterschiedlichen Machtstrukturen.
''',
      coordinates: '51.5074°N, 0.1278°W',
      position: const LatLng(51.5074, -0.1278),
      type: MaterieLocationType.geopolitics,
      category: 'Geopolitik',
    ),
    MaterieLocation(
      name: 'Basel - Pharma-Forschungszentrum',
      description: 'Internationale Pharmaindustrie, medizinische Forschung',
      detailedInfo: '''
Basel ist das globale Zentrum der Pharmaindustrie. Hier haben Konzerne wie Novartis und Roche ihren Hauptsitz - Unternehmen, die Milliarden mit Medikamenten verdienen.

**Pharma-Giganten:**
• Novartis - zweitgrößtes Pharmaunternehmen weltweit
• Roche - führend in Diagnostik und Onkologie
• Forschung an Gentherapien und Krebsmedikamenten

**Kritische Perspektive:**
Alternative Medien hinterfragen die Macht der Pharmaindustrie: Profitorientierung vs. Gesundheit, Patentrechte, Medikamentenpreise, Einfluss auf Politik.

**Forschung:**
Biotechnologie, personalisierte Medizin, CRISPR-Genbearbeitung. Basel ist Vorreiter in umstrittenen Forschungsgebieten.
''',
      coordinates: '47.5596°N, 7.5886°E',
      position: const LatLng(47.5596, 7.5886),
      type: MaterieLocationType.research,
      category: 'Forschung',
    ),
    MaterieLocation(
      name: 'Amsterdam - Freidenker Hub',
      description: 'Progressive Denkfabrik, alternative Gesellschaftsmodelle',
      detailedInfo: '''
Amsterdam ist bekannt für progressive Politik und alternative Lebensweisen. Die Stadt zieht Freidenker und Aktivisten an.

**Progressive Politik:**
• Liberale Drogenpolitik (Coffeeshops)
• LGBTQ+ Rechte-Vorreiter
• Experimentelle Gesellschaftsmodelle
• Bedingungsloses Grundeinkommen-Pilotprojekte

**Alternativkultur:**
Squatting-Bewegung, anarchistische Kollektive, Freespace-Gemeinschaften. Amsterdam war historisch Zentrum für Gegenkultur.

**Digitale Freiheit:**
Datenschutz-Aktivismus, Anti-Überwachung, dezentrale Technologien. Die Stadt fördert Open-Source-Projekte und digitale Souveränität.
''',
      coordinates: '52.3676°N, 4.9041°E',
      position: const LatLng(52.3676, 4.9041),
      type: MaterieLocationType.alternativeMedia,
      category: 'Alternative Kultur',
    ),
    MaterieLocation(
      name: 'Zürich - Internationales Bankenzentrum',
      description: 'Globales Finanzsystem, Geldströme, wirtschaftliche Macht',
      detailedInfo: '''
Zürich ist das Zentrum des Schweizer Bankensystems - bekannt für Diskretion und Vermögensverwaltung.

**Bankgeheimnis:**
Schweizer Banken waren lange Zuflucht für Schwarzgeld. Trotz Reformen bleibt Zürich ein Zentrum für Offshore-Vermögen.

**Finanzinstitute:**
• UBS und Credit Suisse - Systemrelevante Banken
• Verwaltung von Billionen Dollar
• Goldhandel und Rohstoff-Trading

**Kritik:**
Geldwäsche-Vorwürfe, Steuerflucht, intransparente Geldströme. Alternative Medien berichten über Verflechtungen mit globaler Elite.
''',
      coordinates: '47.3769°N, 8.5417°E',
      position: const LatLng(47.3769, 8.5417),
      type: MaterieLocationType.geopolitics,
      category: 'Geopolitik',
    ),
    MaterieLocation(
      name: 'Stockholm - Transparenz-Zentrum',
      description: 'Wikileaks-Verbindungen, investigativer Journalismus',
      detailedInfo: '''
Stockholm ist ein Zentrum für Transparenz und Informationsfreiheit. Schweden hat starke Pressefreiheitsgesetze.

**Wikileaks-Connection:**
Julian Assange hatte Verbindungen nach Schweden. Die Wikileaks-Bewegung wurde hier stark unterstützt.

**Investigativer Journalismus:**
Schwedische Journalisten haben mutige Enthüllungen gemacht: Panama Papers, Paradise Papers, Korruptionsskandale.

**Informationsfreiheit:**
Schweden war 1766 das erste Land mit Pressefreiheitsgesetz. Starke Tradition von Transparenz und Accountability.
''',
      coordinates: '59.3293°N, 18.0686°E',
      position: const LatLng(59.3293, 18.0686),
      type: MaterieLocationType.alternativeMedia,
      category: 'Transparenz',
    ),
    MaterieLocation(
      name: 'Prag - Historische Mysterien',
      description: 'Alchemie-Geschichte, esoterische Traditionen, verborgenes Wissen',
      detailedInfo: '''
Prag war historisch ein Zentrum für Alchemie, Esoterik und Geheimwissenschaften.

**Alchemie-Tradition:**
Kaiser Rudolf II. (16. Jh.) lud Alchemisten ein. Die "Goldene Gasse" war ihr Arbeitsplatz. Suche nach dem Stein der Weisen.

**Esoterische Symbolik:**
Prag ist voll mit okkulter Symbolik: Astronomische Uhr, kabbalistische Zeichen, Golem-Legende.

**Verborgenes Wissen:**
Die Stadt bewahrt Bibliotheken mit alchemistischen Manuskripten. Geheimgesellschaften waren hier aktiv.
''',
      coordinates: '50.0755°N, 14.4378°E',
      position: const LatLng(50.0755, 14.4378),
      type: MaterieLocationType.research,
      category: 'Historische Forschung',
    ),
    
    // 🆕 KRITISCHE EREIGNISSE & VERSCHWÖRUNGEN
    MaterieLocation(
      name: 'Dallas, Texas - JFK Attentat',
      description: '22. November 1963 - Präsident Kennedy ermordet',
      detailedInfo: '''
**JFK Attentat (1963)**
Präsident John F. Kennedy wurde in Dallas erschossen. Offizielle Version: Lee Harvey Oswald handelte allein.

**Zweifel & Fragen:**
• Magic Bullet Theory (eine Kugel, mehrere Wunden)
• Oswald wurde 2 Tage später von Jack Ruby erschossen
• Zeugenaussagen widersprechen offizieller Version
• Geheimdienst-Dokumente bis heute klassifiziert

**Alternative Theorien:**
CIA-Beteiligung, Mafia-Connection, Militärisch-industrieller Komplex
''',
      coordinates: '32.7767°N, 96.7970°W',
      position: const LatLng(32.7767, -96.7970),
      type: MaterieLocationType.conspiracy,
      category: 'Verschwörungen',
    ),
    
    MaterieLocation(
      name: 'New York City - 11. September 2001',
      description: 'World Trade Center Anschläge - offizielle Version vs. Fragen',
      detailedInfo: '''
**9/11 Anschläge (2001)**
Zwei Flugzeuge trafen die Twin Towers, ein drittes das Pentagon. Knapp 3.000 Tote.

**Offizielle Version:**
Al-Qaida-Terroristen entführten Flugzeuge. Towers stürzten durch Feuer ein.

**Kontroverse Punkte:**
• WTC 7 stürzte ohne Flugzeugeinschlag ein (Architekt: "Looks like controlled demolition")
• Physik des freien Falls (Ingenieure stellen Fragen)
• Pentagon: Kein erkennbares Flugzeugwrack
• Put-Optionen auf Airlines vor Anschlägen
• NORAD stand-down

**Folgen:**
Patriot Act, Irak-Krieg, Überwachungsstaat
''',
      coordinates: '40.7128°N, 74.0060°W',
      position: const LatLng(40.7128, -74.0060),
      type: MaterieLocationType.conspiracy,
      category: 'Verschwörungen',
    ),
    
    MaterieLocation(
      name: 'Wuhan, China - COVID-19 Ursprung',
      description: 'Dezember 2019 - Pandemie-Beginn, Laborthese vs. Tiermarkt',
      detailedInfo: '''
**COVID-19 Ursprung (2019)**
Offizielle Version: Zoonotischer Sprung vom Tiermarkt. Alternative: Labor-Leck.

**Wuhan Institute of Virology:**
• Hochsicherheitslabor (BSL-4) für Coronaviren-Forschung
• Gain-of-Function-Experimente (NIH-finanziert)
• 3 Labormitarbeiter erkrankten Nov 2019 (Intelligence-Berichte)

**Fragen:**
• Warum wurden Labor-Daten gelöscht?
• Warum Zensur von Wissenschaftlern, die Laborthese vertraten?
• Genetische Marker deuten auf Labor hin (Furin Cleavage Site)

**Geopolitik:**
US-China-Spannungen, WHO-Untersuchung blockiert, Whistleblower verschwunden
''',
      coordinates: '30.5928°N, 114.3055°E',
      position: const LatLng(30.5928, 114.3055),
      type: MaterieLocationType.research,
      category: 'Aktuelle Ereignisse',
    ),
    
    MaterieLocation(
      name: 'Langley, Virginia - CIA Hauptquartier',
      description: 'MK-ULTRA, Operation Mockingbird, Geheimoperationen',
      detailedInfo: '''
**CIA - Central Intelligence Agency**
US-Auslandsgeheimdienst, gegründet 1947. Berüchtigt für Geheimoperationen.

**MK-ULTRA (1953-1973):**
Bewusstseinskontrolle durch LSD, Hypnose, Folter. Experimente an ahnungslosen Bürgern.

**Operation Mockingbird:**
Infiltration der Medien. Journalisten auf CIA-Gehaltsliste. Propaganda-Kampagnen.

**Weitere Operationen:**
• COINTELPRO (Überwachung Aktivisten)
• Phoenix Program (Vietnam-Folter)
• Iran-Contra (Waffenhandel)
• Torture-Program (Waterboarding)

**Aktuelle Relevanz:**
Whistleblower (Snowden), Drohnenkrieg, Regime-Changes
''',
      coordinates: '38.9517°N, 77.1467°W',
      position: const LatLng(38.9517, -77.1467),
      type: MaterieLocationType.deepState,
      category: 'Deep State',
    ),
    
    MaterieLocation(
      name: 'Area 51, Nevada - Geheime Militärbasis',
      description: 'UFO-Forschung, Experimentalflugzeuge, Roswell-Connection',
      detailedInfo: '''
**Area 51 - Groom Lake**
Hochgeheime US-Militärbasis in der Nevada-Wüste. Offiziell: Testgelände für Experimentalflugzeuge.

**Roswell-Connection (1947):**
UFO-Absturz in New Mexico. Wrackteile nach Area 51 gebracht (Gerüchte).

**Geheimprojekte:**
• U-2 Spionageflugzeug
• SR-71 Blackbird
• F-117 Stealth Fighter
• Angeblich: Reverse Engineering außerirdischer Technologie

**Bob Lazar-Aussagen (1989):**
Physiker behauptet: Arbeitete an UFO-Antriebssystemen. Element 115 als Treibstoff.

**Aktuelle Entwicklungen:**
Pentagon gibt UFO-Videos frei (2020). UAP Task Force eingerichtet.
''',
      coordinates: '37.2350°N, 115.8111°W',
      position: const LatLng(37.2350, -115.8111),
      type: MaterieLocationType.research,
      category: 'UFOs & Technologie',
    ),
  ];

  Set<String> _selectedFilters = {'Alle'};

  List<MaterieLocation> get _filteredLocations {
    if (_selectedFilters.contains('Alle')) return _locations;
    return _locations.where((loc) => _selectedFilters.contains(loc.category)).toList();
  }

  String _getMapTileUrl() {
    switch (_selectedMapMode) {
      case 'Satellit':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case 'Hell':
        return 'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}{r}.png';
      case 'Dunkel':
        return 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png';
      case 'Topografisch':
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
      default: // Standard
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🗺️ VOLLBILD-KARTE (füllt kompletten Bildschirm)
          Positioned.fill(
            child: _buildMap(),
          ),
          
          // Kompakte Floating-Controls (Oben Rechts)
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: _buildCompactControls(),
            ),
          ),
          
          // Kompakte Legende (Unten Links)
          Positioned(
            bottom: 16,
            left: 16,
            child: SafeArea(
              child: _buildCompactLegend(),
            ),
          ),
        ],
      ),
    );
  }

  /// Kompakte Floating-Controls (Oben Rechts)
  Widget _buildCompactControls() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Map-Mode Dropdown
          _buildCompactDropdown(
            icon: Icons.map,
            value: _selectedMapMode,
            items: _mapModes,
            onChanged: (value) {
              setState(() {
                _selectedMapMode = value!;
              });
            },
          ),
          
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          
          // Kategorie-Chips (ersetzt Dropdown)
          _buildCategoryChips(),
        ],
      ),
    );
  }

  /// Kategorie-Chips (klickbare Filter mit Counter)
  Widget _buildCategoryChips() {
    // Zähle Marker pro Kategorie
    final categoryCount = <String, int>{};
    categoryCount['Alle'] = _locations.length;
    for (var location in _locations) {
      categoryCount[location.category] = (categoryCount[location.category] ?? 0) + 1;
    }

    final categories = [
      {'name': 'Alle', 'icon': '🔵', 'color': Color(0xFF2196F3)},
      {'name': 'Geopolitik', 'icon': '🟢', 'color': Color(0xFF4CAF50)},
      {'name': 'Alternative Medien', 'icon': '🔴', 'color': Color(0xFFFF5252)},
      {'name': 'Forschung', 'icon': '🟣', 'color': Color(0xFF9C27B0)},
      {'name': 'Transparenz', 'icon': '🟡', 'color': Color(0xFFFFEB3B)},
      {'name': 'Überwachung', 'icon': '🟠', 'color': Color(0xFFFF9800)},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.85),
            Colors.black.withValues(alpha: 0.65),
            Colors.black.withValues(alpha: 0.50),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        child: Row(
          children: categories.map((cat) {
            final catName = cat['name'] as String;
            final isSelected = _selectedFilters.contains(catName);
            final count = categoryCount[catName] ?? 0;
            final color = cat['color'] as Color;
            
            return Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (catName == 'Alle') {
                      _selectedFilters = {'Alle'};
                    } else {
                      if (_selectedFilters.contains(catName)) {
                        _selectedFilters.remove(catName);
                        if (_selectedFilters.isEmpty) {
                          _selectedFilters.add('Alle');
                        }
                      } else {
                        _selectedFilters.add(catName);
                        _selectedFilters.remove('Alle');
                      }
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: isSelected 
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withValues(alpha: 0.7),
                              color.withValues(alpha: 0.5),
                              color.withValues(alpha: 0.3),
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.12),
                              Colors.white.withValues(alpha: 0.08),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.3),
                      width: isSelected ? 2.5 : 1.8,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: Offset(0, 4),
                      ),
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 28,
                        spreadRadius: 4,
                        offset: Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ] : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isSelected ? RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.4),
                              color.withValues(alpha: 0.2),
                            ],
                          ) : null,
                        ),
                        child: Text(
                          cat['icon'] as String,
                          style: TextStyle(
                            fontSize: 20,
                            shadows: isSelected ? [
                              Shadow(
                                color: color.withValues(alpha: 0.9),
                                blurRadius: 12,
                              ),
                              Shadow(
                                color: Colors.white.withValues(alpha: 0.6),
                                blurRadius: 4,
                              ),
                            ] : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        catName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 15,
                          letterSpacing: 0.5,
                          shadows: isSelected ? [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.7),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                            Shadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                          ] : [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.5),
                                    Colors.white.withValues(alpha: 0.3),
                                    color.withValues(alpha: 0.4),
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.15),
                                    Colors.white.withValues(alpha: 0.10),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected 
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.2),
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ] : null,
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            shadows: isSelected ? [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 4,
                              ),
                            ] : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Kompaktes Dropdown Widget
  Widget _buildCompactDropdown({
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF2196F3), size: 20),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: value,
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            underline: const SizedBox(),
            dropdownColor: const Color(0xFF2C2C2C),
            icon: const Icon(
              Icons.arrow_drop_down,
              color: Color(0xFF2196F3),
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }



  Widget _buildMap() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: const LatLng(48.2082, 16.3738),
          initialZoom: 5.0,
          minZoom: 3.0,
          maxZoom: 18.0,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: _getMapTileUrl(),
            userAgentPackageName: 'com.dualrealms.knowledge',
          ),
          MarkerLayer(
            markers: _filteredLocations.map((location) {
              return Marker(
                point: location.position,
                width: 60,
                height: 60,
                child: GestureDetector(
                  onTap: () => _showLocationDetails(location),
                  child: _buildMarker(location),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMarker(MaterieLocation location) {
    final color = _getMarkerColor(location.type);
    final icon = _getMarkerIcon(location.type);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ],
    );
  }

  Color _getMarkerColor(MaterieLocationType type) {
    switch (type) {
      case MaterieLocationType.geopolitics:
        return const Color(0xFF2196F3);
      case MaterieLocationType.alternativeMedia:
        return const Color(0xFF00BCD4);
      case MaterieLocationType.research:
        return const Color(0xFF64B5F6);
      case MaterieLocationType.conspiracy:
        return const Color(0xFFFF5722); // 🆕 Orange-Rot
      case MaterieLocationType.deepState:
        return const Color(0xFF9C27B0); // 🆕 Lila
    }
  }

  IconData _getMarkerIcon(MaterieLocationType type) {
    switch (type) {
      case MaterieLocationType.geopolitics:
        return Icons.public;
      case MaterieLocationType.alternativeMedia:
        return Icons.newspaper;
      case MaterieLocationType.research:
        return Icons.science;
      case MaterieLocationType.conspiracy:
        return Icons.warning; // 🆕 Warnung-Icon
      case MaterieLocationType.deepState:
        return Icons.visibility_off; // 🆕 Versteckt-Icon
    }
  }

  void _showLocationDetails(MaterieLocation location) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: _getMarkerColor(location.type).withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getMarkerColor(location.type).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getMarkerIcon(location.type),
                      color: _getMarkerColor(location.type),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          location.coordinates,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getMarkerColor(location.type).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _getMarkerColor(location.type).withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  location.category,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getMarkerColor(location.type),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                location.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                location.detailedInfo,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              
              // Check-In Button
              Center(
                child: CheckInButton(
                  locationId: location.name.replaceAll(' ', '_').toLowerCase(),
                  locationName: location.name,
                  category: location.category.toLowerCase().replaceAll(' ', '_'),
                  worldType: 'materie',
                  accentColor: _getMarkerColor(location.type),
                ),
              ),
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _mapController.move(location.position, 12);
                    ToastHelper.showSuccess(context, 'Navigiere zu ${location.name}');
                  },
                  icon: const Icon(Icons.navigation),
                  label: const Text('Zur Location navigieren'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getMarkerColor(location.type).withValues(alpha: 0.3),
                    foregroundColor: _getMarkerColor(location.type),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _getMarkerColor(location.type).withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Kompakte Icon-basierte Legende (Unten Links)
  Widget _buildCompactLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCompactLegendIcon(Icons.public, const Color(0xFF2196F3)),
          const SizedBox(width: 12),
          _buildCompactLegendIcon(Icons.newspaper, const Color(0xFF00BCD4)),
          const SizedBox(width: 12),
          _buildCompactLegendIcon(Icons.science, const Color(0xFF64B5F6)),
        ],
      ),
    );
  }

  Widget _buildCompactLegendIcon(IconData icon, Color color) {
    return Icon(icon, color: color, size: 24);
  }
}

class MaterieLocation {
  final String name;
  final String description;
  final String detailedInfo;
  final String coordinates;
  final LatLng position;
  final MaterieLocationType type;
  final String category;

  MaterieLocation({
    required this.name,
    required this.description,
    required this.detailedInfo,
    required this.coordinates,
    required this.position,
    required this.type,
    required this.category,
  });
}

enum MaterieLocationType {
  geopolitics,
  alternativeMedia,
  research,
  conspiracy,    // 🆕 Verschwörungen
  deepState,     // 🆕 Deep State
}
