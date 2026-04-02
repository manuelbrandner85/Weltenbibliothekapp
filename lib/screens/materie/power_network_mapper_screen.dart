import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0

class PowerNetworkMapperScreen extends StatefulWidget {
  const PowerNetworkMapperScreen({super.key});

  @override
  State<PowerNetworkMapperScreen> createState() => _PowerNetworkMapperScreenState();
}

class _PowerNetworkMapperScreenState extends State<PowerNetworkMapperScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  String? _selectedNodeId;
  final Offset _panOffset = Offset.zero;
  final double _scale = 0.6;  // Start weiter rausgezoomt
  String _searchQuery = '';
  String _selectedCategory = 'Alle';

  final List<String> _categories = ['Alle', 'Finanz', 'Tech', 'Pharma', 'Medien', 'Politik', 'Elite', 'Energie', 'Militär'];

  // MASSIV ERWEITERTES NETZWERK (50+ Nodes)
  late final List<NetworkNode> _allNodes;
  late final List<NetworkConnection> _allConnections;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _initializeNetwork();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _initializeNetwork() {
    _allNodes = [
      // ═══════════ ZENTRUM ═══════════
      NetworkNode(
        id: 'wef',
        name: 'World Economic Forum',
        type: 'Elite',
        influence: 98,
        position: const Offset(0, 0),
        color: const Color(0xFFF44336),
        description: 'Klaus Schwab. Great Reset. Young Global Leaders Programm. Jährliche Davos-Treffen der globalen Elite.',
      ),

      // ═══════════ FINANZ (15 Nodes) ═══════════
      NetworkNode(
        id: 'blackrock',
        name: 'BlackRock',
        type: 'Finanz',
        influence: 95,
        position: const Offset(-350, -200),
        color: const Color(0xFFFF5722),
        description: 'Larry Fink. 10+ Billionen USD AUM. Aladdin KI-System. Größter Aktionär in fast allen S&P 500 Firmen.',
      ),
      NetworkNode(
        id: 'vanguard',
        name: 'Vanguard Group',
        type: 'Finanz',
        influence: 93,
        position: const Offset(350, -200),
        color: const Color(0xFFFF5722),
        description: '7+ Billionen USD AUM. Cross-Ownership mit BlackRock. Kontrolliert große Teile der US-Wirtschaft.',
      ),
      NetworkNode(
        id: 'state_street',
        name: 'State Street',
        type: 'Finanz',
        influence: 88,
        position: const Offset(0, -350),
        color: const Color(0xFFFF5722),
        description: '4+ Billionen USD AUM. Mit BlackRock & Vanguard die "Big Three" der Vermögensverwaltung.',
      ),
      NetworkNode(
        id: 'bis',
        name: 'Bank für Internationalen Zahlungsausgleich',
        type: 'Finanz',
        influence: 96,
        position: const Offset(-500, 0),
        color: const Color(0xFFE91E63),
        description: 'Zentralbank der Zentralbanken. Basel, Schweiz. Immun gegen nationale Gesetze. Koordiniert globale Geldpolitik.',
      ),
      NetworkNode(
        id: 'fed',
        name: 'Federal Reserve',
        type: 'Finanz',
        influence: 92,
        position: const Offset(-400, 150),
        color: const Color(0xFFE91E63),
        description: 'Privatbank im Besitz von Banken. Druckt US-Dollar. Jerome Powell. Kontrolliert Weltwährung.',
      ),
      NetworkNode(
        id: 'ecb',
        name: 'Europäische Zentralbank',
        type: 'Finanz',
        influence: 89,
        position: const Offset(-550, -150),
        color: const Color(0xFFE91E63),
        description: 'Christine Lagarde. Kontrolliert Euro. Negative Zinsen. CBDC-Pläne.',
      ),
      NetworkNode(
        id: 'jpmorgan',
        name: 'JPMorgan Chase',
        type: 'Finanz',
        influence: 87,
        position: const Offset(-250, -350),
        color: const Color(0xFFFF5722),
        description: 'Jamie Dimon. Größte US-Bank. Silber-Manipulation. Epstein-Verbindungen.',
      ),
      NetworkNode(
        id: 'goldman',
        name: 'Goldman Sachs',
        type: 'Finanz',
        influence: 86,
        position: const Offset(250, -350),
        color: const Color(0xFFFF5722),
        description: 'Revolving Door zu Regierungen. Ehemalige CEOs in Finanzministerien weltweit.',
      ),
      NetworkNode(
        id: 'rothschild',
        name: 'Rothschild & Co',
        type: 'Elite',
        influence: 94,
        position: const Offset(-600, -300),
        color: const Color(0xFF9C27B0),
        description: 'Historische Bankendynastie. Finanziert beide Seiten von Kriegen. Zentral bank-Gründungen.',
      ),
      NetworkNode(
        id: 'rockefeller',
        name: 'Rockefeller Foundation',
        type: 'Elite',
        influence: 92,
        position: const Offset(-650, 150),
        color: const Color(0xFF9C27B0),
        description: 'Öl-Dynastie. Finanziert WHO, Bildungssystem, Medizin. "Lock Step" Pandemie-Szenario 2010.',
      ),
      NetworkNode(
        id: 'morgan',
        name: 'Morgan Stanley',
        type: 'Finanz',
        influence: 84,
        position: const Offset(400, -280),
        color: const Color(0xFFFF5722),
        description: 'Investment Banking. Derivate-Handel. Verbindungen zu Federal Reserve.',
      ),
      NetworkNode(
        id: 'citadel',
        name: 'Citadel Securities',
        type: 'Finanz',
        influence: 81,
        position: const Offset(-150, -450),
        color: const Color(0xFFFF5722),
        description: 'Ken Griffin. Market Maker. GameStop-Skandal. Zahlung für Order-Flow.',
      ),
      NetworkNode(
        id: 'hsbc',
        name: 'HSBC',
        type: 'Finanz',
        influence: 79,
        position: const Offset(150, -450),
        color: const Color(0xFFFF5722),
        description: 'Drogen-Geldwäsche für Kartelle. "Too Big to Jail". Hongkong-Verbindungen.',
      ),
      NetworkNode(
        id: 'deutsche_bank',
        name: 'Deutsche Bank',
        type: 'Finanz',
        influence: 77,
        position: const Offset(500, -100),
        color: const Color(0xFFFF5722),
        description: 'Derivate-Risiko. Trump-Kredite. Epstein-Konto. Zahlreiche Skandale.',
      ),

      // ═══════════ TECH (12 Nodes) ═══════════
      NetworkNode(
        id: 'google',
        name: 'Google/Alphabet',
        type: 'Tech',
        influence: 91,
        position: const Offset(-300, 300),
        color: const Color(0xFF2196F3),
        description: 'Larry Page. Eric Schmidt. Datenmonopol. YouTube Zensur. Android Tracking. Google Idea/Jigsaw.',
      ),
      NetworkNode(
        id: 'meta',
        name: 'Meta (Facebook)',
        type: 'Tech',
        influence: 89,
        position: const Offset(300, 300),
        color: const Color(0xFF2196F3),
        description: 'Mark Zuckerberg. 3+ Milliarden Nutzer. Cambridge Analytica. Social Credit System. Metaverse.',
      ),
      NetworkNode(
        id: 'amazon',
        name: 'Amazon',
        type: 'Tech',
        influence: 88,
        position: const Offset(0, 450),
        color: const Color(0xFF2196F3),
        description: 'Jeff Bezos. AWS: 30% des Internets. Washington Post. CIA-Verträge. Ring Überwachung.',
      ),
      NetworkNode(
        id: 'microsoft',
        name: 'Microsoft',
        type: 'Tech',
        influence: 87,
        position: const Offset(-450, 400),
        color: const Color(0xFF2196F3),
        description: 'Bill Gates. Windows Monopol. Impf-Allianz. ID2020 Digital ID. Event 201 Pandemie-Übung.',
      ),
      NetworkNode(
        id: 'apple',
        name: 'Apple',
        type: 'Tech',
        influence: 85,
        position: const Offset(450, 400),
        color: const Color(0xFF2196F3),
        description: 'Tim Cook. Backdoors für NSA. China-Abhängigkeit. App Store Zensur.',
      ),
      NetworkNode(
        id: 'tesla',
        name: 'Tesla/SpaceX',
        type: 'Tech',
        influence: 83,
        position: const Offset(-200, 550),
        color: const Color(0xFF2196F3),
        description: 'Elon Musk. Neuralink Brain Chips. Starlink Satelliten-Netzwerk. X/Twitter Übernahme.',
      ),
      NetworkNode(
        id: 'palantir',
        name: 'Palantir',
        type: 'Tech',
        influence: 82,
        position: const Offset(200, 550),
        color: const Color(0xFF00BCD4),
        description: 'Peter Thiel. CIA/NSA Überwachung. Kriegs-KI. Dragnet-Systeme.',
      ),
      NetworkNode(
        id: 'nvidia',
        name: 'NVIDIA',
        type: 'Tech',
        influence: 80,
        position: const Offset(-600, 300),
        color: const Color(0xFF2196F3),
        description: 'Jensen Huang. KI-Chip-Monopol. Kontrolliert Machine Learning Hardware.',
      ),
      NetworkNode(
        id: 'openai',
        name: 'OpenAI',
        type: 'Tech',
        influence: 78,
        position: const Offset(600, 300),
        color: const Color(0xFF00BCD4),
        description: 'Sam Altman. ChatGPT. AGI-Entwicklung. Microsoft-Partnerschaft.',
      ),
      NetworkNode(
        id: 'deepmind',
        name: 'DeepMind (Google)',
        type: 'Tech',
        influence: 76,
        position: const Offset(-550, 450),
        color: const Color(0xFF00BCD4),
        description: 'Demis Hassabis. AlphaGo. KI für Proteinforschung. NHS-Daten Zugang.',
      ),
      NetworkNode(
        id: 'tencent',
        name: 'Tencent',
        type: 'Tech',
        influence: 82,
        position: const Offset(550, 450),
        color: const Color(0xFF2196F3),
        description: 'WeChat. Social Credit System. CCP-verbunden. Investiert in Western Gaming.',
      ),
      NetworkNode(
        id: 'alibaba',
        name: 'Alibaba',
        type: 'Tech',
        influence: 79,
        position: const Offset(0, 600),
        color: const Color(0xFF2196F3),
        description: 'Jack Ma (verschwunden 2020). E-Commerce. Cloud. Alipay Payment System.',
      ),

      // ═══════════ PHARMA (10 Nodes) ═══════════
      NetworkNode(
        id: 'pfizer',
        name: 'Pfizer',
        type: 'Pharma',
        influence: 90,
        position: const Offset(200, -100),
        color: const Color(0xFF4CAF50),
        description: 'Albert Bourla. mRNA Covid-Impfung. FDA Revolving Door. Größte Strafe in Pharma-Geschichte (2009).',
      ),
      NetworkNode(
        id: 'moderna',
        name: 'Moderna',
        type: 'Pharma',
        influence: 86,
        position: const Offset(350, 0),
        color: const Color(0xFF4CAF50),
        description: 'Stéphane Bancel. mRNA-Technologie. DARPA-Verbindungen. Nie zuvor zugelassene Produkte.',
      ),
      NetworkNode(
        id: 'j_and_j',
        name: 'Johnson & Johnson',
        type: 'Pharma',
        influence: 84,
        position: const Offset(280, -200),
        color: const Color(0xFF4CAF50),
        description: 'Babypuder-Krebs-Skandal. Opioid-Krise. Tausende Klagen. Impf-Haftungsschutz.',
      ),
      NetworkNode(
        id: 'astrazeneca',
        name: 'AstraZeneca',
        type: 'Pharma',
        influence: 81,
        position: const Offset(470, -150),
        color: const Color(0xFF4CAF50),
        description: 'Oxford University Partnerschaft. Covid-Impfung. Blutgerinnsel-Fälle.',
      ),
      NetworkNode(
        id: 'bayer',
        name: 'Bayer/Monsanto',
        type: 'Pharma',
        influence: 83,
        position: const Offset(200, 50),
        color: const Color(0xFF8BC34A),
        description: 'Glyphosat/Roundup Krebs-Klagen. GMO-Saatgut Monopol. IG Farben Nachfolger.',
      ),
      NetworkNode(
        id: 'gates_foundation',
        name: 'Bill & Melinda Gates Foundation',
        type: 'Elite',
        influence: 93,
        position: const Offset(100, -50),
        color: const Color(0xFF9C27B0),
        description: 'Größter WHO-Spender nach USA. GAVI Impf-Allianz. Event 201. Landwirt #1 in USA.',
      ),
      NetworkNode(
        id: 'gavi',
        name: 'GAVI (Impf-Allianz)',
        type: 'Elite',
        influence: 87,
        position: const Offset(250, 100),
        color: const Color(0xFF9C27B0),
        description: 'Gates-finanziert. Diplomatische Immunität in Genf. Globale Impf-Kampagnen.',
      ),
      NetworkNode(
        id: 'wellcome_trust',
        name: 'Wellcome Trust',
        type: 'Elite',
        influence: 80,
        position: const Offset(420, 50),
        color: const Color(0xFF8BC34A),
        description: 'Glaxo-SmithKline Wurzeln. Pharma-Research Finanzierung. Jeremy Farrar (WHO Chief Scientist).',
      ),
      NetworkNode(
        id: 'gilead',
        name: 'Gilead Sciences',
        type: 'Pharma',
        influence: 78,
        position: const Offset(320, -280),
        color: const Color(0xFF4CAF50),
        description: 'Remdesivir. Donald Rumsfeld Board Member. Tamiflu Vogelgrippe.',
      ),
      NetworkNode(
        id: 'glaxo',
        name: 'GlaxoSmithKline',
        type: 'Pharma',
        influence: 77,
        position: const Offset(520, 100),
        color: const Color(0xFF4CAF50),
        description: 'Impfstoff-Riese. Zahlreiche Strafen wegen Korruption und Datenfälschung.',
      ),

      // ═══════════ MEDIEN (10 Nodes) ═══════════
      NetworkNode(
        id: 'disney',
        name: 'Walt Disney',
        type: 'Medien',
        influence: 84,
        position: const Offset(-150, 150),
        color: const Color(0xFFFF9800),
        description: 'Bob Iger. ABC, ESPN, Marvel, Star Wars, Fox, National Geographic. Kulturelle Dominanz.',
      ),
      NetworkNode(
        id: 'comcast',
        name: 'Comcast/NBCUniversal',
        type: 'Medien',
        influence: 82,
        position: const Offset(150, 150),
        color: const Color(0xFFFF9800),
        description: 'Brian Roberts. NBC, MSNBC, CNBC, Universal. Größter Kabelnetzbetreiber USA.',
      ),
      NetworkNode(
        id: 'att',
        name: 'AT&T/Warner Media',
        type: 'Medien',
        influence: 80,
        position: const Offset(0, 200),
        color: const Color(0xFFFF9800),
        description: 'CNN, HBO, Warner Bros. NSA Daten-Partnerschaft. Room 641A Überwachung.',
      ),
      NetworkNode(
        id: 'viacom',
        name: 'ViacomCBS (Paramount)',
        type: 'Medien',
        influence: 76,
        position: const Offset(-250, 200),
        color: const Color(0xFFFF9800),
        description: 'MTV, Comedy Central, Paramount, Nickelodeon. Sumner Redstone Familie.',
      ),
      NetworkNode(
        id: 'newscorp',
        name: 'News Corp (Fox)',
        type: 'Medien',
        influence: 81,
        position: const Offset(250, 200),
        color: const Color(0xFFFF9800),
        description: 'Rupert Murdoch. Fox News, Wall Street Journal, NY Post. Konservatives Medien-Imperium.',
      ),
      NetworkNode(
        id: 'reuters',
        name: 'Thomson Reuters',
        type: 'Medien',
        influence: 85,
        position: const Offset(-350, 250),
        color: const Color(0xFFFF6F00),
        description: 'Nachrichten-Agentur. Rothschild-Gründung. Fact-Checking für Social Media.',
      ),
      NetworkNode(
        id: 'ap',
        name: 'Associated Press',
        type: 'Medien',
        influence: 83,
        position: const Offset(350, 250),
        color: const Color(0xFFFF6F00),
        description: 'Nachrichten-Agentur. Liefert Stories an tausende Medien. Gates-finanziertes Fact-Checking.',
      ),
      NetworkNode(
        id: 'bbc',
        name: 'BBC',
        type: 'Medien',
        influence: 79,
        position: const Offset(-450, 250),
        color: const Color(0xFFFF9800),
        description: 'British Broadcasting. Staatlicher Rundfunk. Jimmy Savile Cover-Up. 77th Brigade Verbindungen.',
      ),
      NetworkNode(
        id: 'nyt',
        name: 'New York Times',
        type: 'Medien',
        influence: 78,
        position: const Offset(450, 250),
        color: const Color(0xFFFF9800),
        description: 'Sulzberger Familie. "Paper of Record". CIA Operation Mockingbird Verbindungen.',
      ),
      NetworkNode(
        id: 'wapo',
        name: 'Washington Post',
        type: 'Medien',
        influence: 77,
        position: const Offset(0, 350),
        color: const Color(0xFFFF9800),
        description: 'Jeff Bezos. CIA 600-Millionen-Dollar-Vertrag über AWS.',
      ),

      // ═══════════ POLITIK & ELITE (10 Nodes) ═══════════
      NetworkNode(
        id: 'cfr',
        name: 'Council on Foreign Relations',
        type: 'Politik',
        influence: 91,
        position: const Offset(-200, -150),
        color: const Color(0xFF9C27B0),
        description: 'David Rockefeller Gründung. US-Außenpolitik Think Tank. Präsidenten, Außenminister, CIA-Direktoren.',
      ),
      NetworkNode(
        id: 'trilateral',
        name: 'Trilaterale Kommission',
        type: 'Politik',
        influence: 88,
        position: const Offset(200, -150),
        color: const Color(0xFF9C27B0),
        description: 'Zbigniew Brzezinski & David Rockefeller. USA-Europa-Asien Elite-Koordination.',
      ),
      NetworkNode(
        id: 'bilderberg',
        name: 'Bilderberg-Gruppe',
        type: 'Elite',
        influence: 92,
        position: const Offset(0, -200),
        color: const Color(0xFF9C27B0),
        description: 'Geheime Jahrestreffen seit 1954. Keine Öffentlichkeit, keine Presse. Prince Bernhard Gründung.',
      ),
      NetworkNode(
        id: 'un',
        name: 'Vereinte Nationen',
        type: 'Politik',
        influence: 89,
        color: const Color(0xFF673AB7),
        position: const Offset(-100, -250),
        description: 'Rockefeller Land-Spende. Agenda 2030. WHO, UNESCO, UNICEF. Globale Governance.',
      ),
      NetworkNode(
        id: 'who',
        name: 'World Health Organization',
        type: 'Politik',
        influence: 87,
        position: const Offset(100, -250),
        color: const Color(0xFF673AB7),
        description: 'Tedros Adhanom. Gates ist größter Spender. Pandemie-Vertrag. Internationale Gesundheitsvorschriften.',
      ),
      NetworkNode(
        id: 'nato',
        name: 'NATO',
        type: 'Militär',
        influence: 90,
        position: const Offset(-300, -100),
        color: const Color(0xFF795548),
        description: 'Militärallianz. Ost-Expansion. Operation Gladio. Stay-Behind-Armeen.',
      ),
      NetworkNode(
        id: 'imf',
        name: 'Internationaler Währungsfonds',
        type: 'Finanz',
        influence: 86,
        position: const Offset(300, -100),
        color: const Color(0xFFE91E63),
        description: 'Kristalina Georgieva. Schulden-Falle für Entwicklungsländer. Strukturanpassungsprogramme.',
      ),
      NetworkNode(
        id: 'worldbank',
        name: 'Weltbank',
        type: 'Finanz',
        influence: 85,
        position: const Offset(-450, -100),
        color: const Color(0xFFE91E63),
        description: 'David Malpass. Entwicklungs-"Hilfe" mit Bedingungen. Ressourcen-Extraktion.',
      ),
      NetworkNode(
        id: 'cia',
        name: 'CIA',
        type: 'Militär',
        influence: 94,
        position: const Offset(-100, -100),
        color: const Color(0xFF795548),
        description: 'Central Intelligence Agency. Regime Changes. Operation Mockingbird. MK-Ultra. Drogenhandel.',
      ),
      NetworkNode(
        id: 'mi6',
        name: 'MI6',
        type: 'Militär',
        influence: 88,
        position: const Offset(100, -100),
        color: const Color(0xFF795548),
        description: 'Secret Intelligence Service. Five Eyes. Skripal/Litvinenko. Integrity Initiative.',
      ),

      // ═══════════ MILITÄR-INDUSTRIAL (2 Nodes) ═══════════
      NetworkNode(
        id: 'lockheed',
        name: 'Lockheed Martin',
        type: 'Militär',
        influence: 84,
        position: const Offset(0, -400),
        color: const Color(0xFF795548),
        description: 'Größter Militärkonzern. F-35 Fighter. Raketen. Revolving Door zum Pentagon.',
      ),
      NetworkNode(
        id: 'raytheon',
        name: 'Raytheon',
        type: 'Militär',
        influence: 80,
        position: const Offset(-150, -380),
        color: const Color(0xFF795548),
        description: 'Waffen-Systeme. Patriot Missiles. Lloyd Austin (Verteidigungsminister) war Board Member.',
      ),

      // ═══════════ ENERGIE (5 Nodes) ═══════════
      NetworkNode(
        id: 'shell',
        name: 'Shell',
        type: 'Energie',
        influence: 79,
        position: const Offset(-350, 100),
        color: const Color(0xFFFFEB3B),
        description: 'Royal Dutch Shell. Öl & Gas. Nigeria Konflikte. Klimawandel-Leugnung Finanzierung.',
      ),
      NetworkNode(
        id: 'exxon',
        name: 'ExxonMobil',
        type: 'Energie',
        influence: 81,
        position: const Offset(350, 100),
        color: const Color(0xFFFFEB3B),
        description: 'Rex Tillerson (ehem. Außenminister). Klimaforschung verschleiert. Valdez Ölpest.',
      ),
      NetworkNode(
        id: 'bp',
        name: 'BP',
        type: 'Energie',
        influence: 77,
        position: const Offset(-250, 50),
        color: const Color(0xFFFFEB3B),
        description: 'British Petroleum. Deepwater Horizon Katastrophe. Regime-Change Profiteur.',
      ),
      NetworkNode(
        id: 'chevron',
        name: 'Chevron',
        type: 'Energie',
        influence: 75,
        position: const Offset(250, 50),
        color: const Color(0xFFFFEB3B),
        description: 'Ecuador Umweltzerstörung. Condoleezza Rice Board Member. Militäreinsätze für Öl.',
      ),
      NetworkNode(
        id: 'aramco',
        name: 'Saudi Aramco',
        type: 'Energie',
        influence: 83,
        position: const Offset(0, 100),
        color: const Color(0xFFFFEB3B),
        description: 'Staatliche Saudi-Ölfirma. Größte Ölfirma der Welt. Petrodollar-System.',
      ),
    ];

    _allConnections = [
      // WEF zentrale Verbindungen
      NetworkConnection('wef', 'blackrock', 'Führungsmitglied'),
      NetworkConnection('wef', 'vanguard', 'Strategiepartner'),
      NetworkConnection('wef', 'bis', 'Finanzsystem-Koordination'),
      NetworkConnection('wef', 'cfr', 'Policy Overlap'),
      NetworkConnection('wef', 'trilateral', 'Elite Network'),
      NetworkConnection('wef', 'bilderberg', 'Mitgliedschaft'),
      NetworkConnection('wef', 'gates_foundation', 'Great Reset Partner'),
      NetworkConnection('wef', 'google', 'Tech Partnership'),
      NetworkConnection('wef', 'pfizer', 'Pharma Partnership'),

      // Big Three Asset Manager
      NetworkConnection('blackrock', 'vanguard', 'Cross-Ownership'),
      NetworkConnection('blackrock', 'state_street', 'Big Three Alliance'),
      NetworkConnection('vanguard', 'state_street', 'Shared Holdings'),
      NetworkConnection('blackrock', 'google', 'Top Shareholder'),
      NetworkConnection('blackrock', 'meta', 'Top Shareholder'),
      NetworkConnection('blackrock', 'amazon', 'Top Shareholder'),
      NetworkConnection('blackrock', 'microsoft', 'Top Shareholder'),
      NetworkConnection('blackrock', 'apple', 'Top Shareholder'),
      NetworkConnection('blackrock', 'pfizer', 'Major Investor'),
      NetworkConnection('vanguard', 'google', 'Top Shareholder'),
      NetworkConnection('vanguard', 'meta', 'Top Shareholder'),
      NetworkConnection('vanguard', 'amazon', 'Top Shareholder'),
      NetworkConnection('vanguard', 'microsoft', 'Top Shareholder'),
      NetworkConnection('vanguard', 'pfizer', 'Major Investor'),

      // Zentral banken
      NetworkConnection('bis', 'fed', 'Central Bank Network'),
      NetworkConnection('bis', 'ecb', 'Central Bank Network'),
      NetworkConnection('fed', 'jpmorgan', 'Revolving Door'),
      NetworkConnection('fed', 'goldman', 'Revolving Door'),
      NetworkConnection('fed', 'blackrock', 'Monetary Policy Advisor'),

      // Elite Dynastien
      NetworkConnection('rothschild', 'bis', 'Historical Founding'),
      NetworkConnection('rothschild', 'reuters', 'Family Ownership'),
      NetworkConnection('rockefeller', 'cfr', 'Founder'),
      NetworkConnection('rockefeller', 'trilateral', 'Co-Founder'),
      NetworkConnection('rockefeller', 'un', 'Land Donation'),
      NetworkConnection('rockefeller', 'worldbank', 'Control'),
      NetworkConnection('rothschild', 'shell', 'Investment'),
      NetworkConnection('rothschild', 'bp', 'Investment'),

      // Tech Giganten untereinander
      NetworkConnection('google', 'meta', 'Data Sharing'),
      NetworkConnection('google', 'amazon', 'Ad Competition'),
      NetworkConnection('microsoft', 'openai', '\$10B Investment'),
      NetworkConnection('google', 'deepmind', 'Ownership'),
      NetworkConnection('amazon', 'cia', '\$600M AWS Contract'),
      NetworkConnection('palantir', 'cia', 'Surveillance Tools'),
      NetworkConnection('microsoft', 'nato', 'Cloud Contracts'),

      // Pharma & Gates
      NetworkConnection('gates_foundation', 'pfizer', 'Funding & Promotion'),
      NetworkConnection('gates_foundation', 'moderna', 'Funding & Promotion'),
      NetworkConnection('gates_foundation', 'who', 'Top Funder'),
      NetworkConnection('gates_foundation', 'gavi', 'Founder & Funder'),
      NetworkConnection('gates_foundation', 'un', 'Partnership'),
      NetworkConnection('pfizer', 'blackrock', 'Top Shareholder'),
      NetworkConnection('moderna', 'blackrock', 'Major Shareholder'),
      NetworkConnection('wellcome_trust', 'glaxo', 'Historical Ties'),
      NetworkConnection('gavi', 'who', 'Official Partnership'),

      // Medienkonzerne
      NetworkConnection('blackrock', 'disney', 'Top Shareholder'),
      NetworkConnection('blackrock', 'comcast', 'Top Shareholder'),
      NetworkConnection('blackrock', 'att', 'Top Shareholder'),
      NetworkConnection('vanguard', 'disney', 'Top Shareholder'),
      NetworkConnection('vanguard', 'comcast', 'Top Shareholder'),
      NetworkConnection('amazon', 'wapo', 'Bezos Ownership'),
      NetworkConnection('newscorp', 'fox', 'Murdoch Family'),
      NetworkConnection('reuters', 'rothschild', 'Founding Family'),

      // Intelligence Agencies
      NetworkConnection('cia', 'amazon', 'Cloud Services'),
      NetworkConnection('cia', 'google', 'In-Q-Tel Investment'),
      NetworkConnection('cia', 'palantir', 'Data Analysis'),
      NetworkConnection('cia', 'wapo', 'Mockingbird Program'),
      NetworkConnection('mi6', 'cia', 'Five Eyes Alliance'),
      NetworkConnection('nato', 'cia', 'Military Coordination'),

      // Politik Think Tanks
      NetworkConnection('cfr', 'bilderberg', 'Member Overlap'),
      NetworkConnection('cfr', 'trilateral', 'Strategic Alliance'),
      NetworkConnection('trilateral', 'bilderberg', 'Elite Coordination'),
      NetworkConnection('cfr', 'fed', 'Policy Influence'),
      NetworkConnection('cfr', 'cia', 'Foreign Policy'),

      // UN & WHO
      NetworkConnection('un', 'who', 'Specialized Agency'),
      NetworkConnection('un', 'worldbank', 'Bretton Woods'),
      NetworkConnection('un', 'imf', 'Bretton Woods'),
      NetworkConnection('who', 'pfizer', 'Vaccine Partnership'),
      NetworkConnection('who', 'gavi', 'Immunization Alliance'),

      // Energie-Sektor
      NetworkConnection('blackrock', 'shell', 'Major Shareholder'),
      NetworkConnection('blackrock', 'exxon', 'Major Shareholder'),
      NetworkConnection('vanguard', 'shell', 'Major Shareholder'),
      NetworkConnection('vanguard', 'exxon', 'Major Shareholder'),
      NetworkConnection('rockefeller', 'exxon', 'Historical Ownership'),
      NetworkConnection('aramco', 'jpmorgan', 'Petrodollar System'),

      // China Tech
      NetworkConnection('tencent', 'tesla', 'Investment'),
      NetworkConnection('alibaba', 'blackrock', 'Investment'),

      // Weitere Pharma Connections
      NetworkConnection('pfizer', 'moderna', 'mRNA Technology'),
      NetworkConnection('j_and_j', 'blackrock', 'Top Shareholder'),
      NetworkConnection('bayer', 'vanguard', 'Major Shareholder'),

      // Medien untereinander
      NetworkConnection('disney', 'comcast', 'Content Licensing'),
      NetworkConnection('reuters', 'ap', 'News Syndication'),
      NetworkConnection('nyt', 'wapo', 'Liberal Media Alliance'),

      // Tech-Pharma Bridge
      NetworkConnection('google', 'pfizer', 'Health Data'),
      NetworkConnection('microsoft', 'pfizer', 'AI Drug Research'),
      NetworkConnection('apple', 'moderna', 'Health Apps'),

      // Militär-Industrial
      NetworkConnection('nato', 'lockheed', 'Weapons Systems'),
      NetworkConnection('cia', 'blackrock', 'Investment'),
      NetworkConnection('mi6', 'hsbc', 'Money Laundering'),
    ];
  }

  List<NetworkNode> get _filteredNodes {
    return _allNodes.where((node) {
      final matchesCategory = _selectedCategory == 'Alle' || node.type == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty || 
          node.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  NetworkNode? _getNode(String id) {
    try {
      return _allNodes.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1A1A1A), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main Content (Column with Header, Network, Legend)
              Column(
                children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'POWER NETWORK MAPPER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '50+ Machtknoten • Alternative Recherchen',
                                style: TextStyle(color: Colors.white60, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF44336),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_allNodes.length} NODES',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Search & Filter
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            onChanged: (value) => setState(() => _searchQuery = value),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Suche...',
                              hintStyle: const TextStyle(color: Colors.white38),
                              prefixIcon: const Icon(Icons.search, color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF1A1A1A),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            items: _categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) setState(() => _selectedCategory = value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pinch Zoom mit Fingern • Tap für Details | ${_filteredNodes.length} von ${_allNodes.length}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Network Visualization mit PROFESSIONELLEM InteractiveViewer
              Expanded(
                child: Stack(
                  children: [
                    // Grid background
                    CustomPaint(
                      size: Size.infinite,
                      painter: GridPainter(),
                    ),
                    
                    // CRITICAL FIX: InteractiveViewer für echten Pinch-Zoom
                    InteractiveViewer(
                      boundaryMargin: const EdgeInsets.all(50),
                      minScale: 0.3,
                      maxScale: 3.0,
                      constrained: false,
                      
                      // CRITICAL: GestureDetector INNERHALB von InteractiveViewer
                      child: GestureDetector(
                        onTapDown: (details) {
                          _handleTap(details.localPosition);
                        },
                        child: Container(
                          width: 1400,
                          height: 1200,
                          color: Colors.transparent,
                          child: CustomPaint(
                            size: const Size(1400, 1200),
                            painter: NetworkPainter(
                              nodes: _filteredNodes,
                              connections: _allConnections,
                              selectedNodeId: _selectedNodeId,
                              pulseValue: _pulseController.value,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Legend
              _buildLegend(),
                ],
              ),
              
              // Node Details as Overlay
              if (_selectedNodeId != null) _buildNodeDetails(),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(Offset position) {
    // CRITICAL FIX: Einfache Tap-Detection ohne komplexe Transformation
    // InteractiveViewer gibt bereits die korrekte Position
    final center = const Offset(700, 600);
    final relativePos = position - center;
    
    NetworkNode? tappedNode;
    double minDistance = 80.0; // Konstanter Tap-Radius
    
    for (final node in _filteredNodes) {
      final distance = (node.position - relativePos).distance;
      if (distance < minDistance) {
        minDistance = distance;
        tappedNode = node;
      }
    }
    
    if (tappedNode != null) {
      setState(() {
        _selectedNodeId = tappedNode!.id;
      });
    }
  }

  Widget _buildNodeDetails() {
    final node = _getNode(_selectedNodeId!);
    if (node == null) return const SizedBox.shrink();
    
    final connections = _allConnections.where(
      (c) => c.from == node.id || c.to == node.id
    ).toList();
    
    return Positioned(
      left: 16,
      right: 16,
      bottom: 80,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 250),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  node.color.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: node.color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: node.color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconForType(node.type),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          node.type.toUpperCase(),
                          style: TextStyle(
                            color: node.color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => _selectedNodeId = null),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Text(
                node.description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Influence Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'EINFLUSS',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${node.influence}%',
                        style: TextStyle(
                          color: node.color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: node.influence / 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      color: node.color,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Connections List - ALLE anzeigen mit Details
              if (connections.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.link, color: node.color, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'VERBINDUNGEN (${connections.length}):',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Alle Verbindungen als Liste
                ...connections.map((conn) {
                  final otherId = conn.from == node.id ? conn.to : conn.from;
                  final other = _getNode(otherId);
                  if (other == null) return const SizedBox.shrink();
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: other.color.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Icon für anderen Node
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: other.color.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconForType(other.type),
                            color: other.color,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Verbindung Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                other.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white54,
                                    size: 10,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      conn.type,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 10,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Influence Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: other.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${other.influence}%',
                            style: TextStyle(
                              color: other.color,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
          ), // Ende innerer Container
        ), // Ende SingleChildScrollView
      ), // Ende äußerer Container
    ); // Ende Positioned
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLegendItem('Finanz', const Color(0xFFFF5722)),
            _buildLegendItem('Tech', const Color(0xFF2196F3)),
            _buildLegendItem('Pharma', const Color(0xFF4CAF50)),
            _buildLegendItem('Medien', const Color(0xFFFF9800)),
            _buildLegendItem('Politik', const Color(0xFF9C27B0)),
            _buildLegendItem('Elite', const Color(0xFFF44336)),
            _buildLegendItem('Energie', const Color(0xFFFFEB3B)),
            _buildLegendItem('Militär', const Color(0xFF795548)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Finanz': return Icons.monetization_on;
      case 'Tech': return Icons.devices;
      case 'Pharma': return Icons.medical_services;
      case 'Medien': return Icons.tv;
      case 'Politik': return Icons.account_balance;
      case 'Elite': return Icons.star;
      case 'Energie': return Icons.bolt;
      case 'Militär': return Icons.shield;
      default: return Icons.circle;
    }
  }
}

class NetworkNode {
  final String id;
  final String name;
  final String type;
  final double influence;
  final Offset position;
  final Color color;
  final String description;

  NetworkNode({
    required this.id,
    required this.name,
    required this.type,
    required this.influence,
    required this.position,
    required this.color,
    required this.description,
  });
}

class NetworkConnection {
  final String from;
  final String to;
  final String type;

  NetworkConnection(this.from, this.to, this.type);
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    
    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NetworkPainter extends CustomPainter {
  final List<NetworkNode> nodes;
  final List<NetworkConnection> connections;
  final String? selectedNodeId;
  final double pulseValue;

  NetworkPainter({
    required this.nodes,
    required this.connections,
    this.selectedNodeId,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw connections
    final connectionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    for (final conn in connections) {
      final fromNode = nodes.cast<NetworkNode?>().firstWhere((n) => n?.id == conn.from, orElse: () => null);
      final toNode = nodes.cast<NetworkNode?>().firstWhere((n) => n?.id == conn.to, orElse: () => null);
      
      if (fromNode == null || toNode == null) continue;
      
      final from = center + fromNode.position;
      final to = center + toNode.position;
      
      final isSelected = selectedNodeId == conn.from || selectedNodeId == conn.to;
      
      connectionPaint.color = isSelected
          ? Colors.white.withValues(alpha: 0.5)
          : Colors.white.withValues(alpha: 0.15);
      
      canvas.drawLine(from, to, connectionPaint);
      
      // Label for selected
      if (isSelected && selectedNodeId != null) {
        final midPoint = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
        final textPainter = TextPainter(
          text: TextSpan(
            text: conn.type,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              backgroundColor: Color(0xAA000000),
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          midPoint - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }
    }
    
    // Draw nodes
    for (final node in nodes) {
      final pos = center + node.position;
      final isSelected = selectedNodeId == node.id;
      
      // Glow for selected
      if (isSelected) {
        final glowRadius = 30 + (pulseValue * 8);
        final glowPaint = Paint()
          ..color = node.color.withValues(alpha: 0.3 * (1 - pulseValue))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(pos, glowRadius, glowPaint);
      }
      
      final nodeRadius = isSelected ? 22.0 : 16.0;
      
      // Shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(pos + const Offset(0, 1), nodeRadius, shadowPaint);
      
      // Circle
      final circlePaint = Paint()..color = node.color;
      canvas.drawCircle(pos, nodeRadius, circlePaint);
      
      // Border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.5 : 1.5;
      canvas.drawCircle(pos, nodeRadius, borderPaint);
      
      // Influence ring
      final influencePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(pos, nodeRadius + 3 + (node.influence / 15), influencePaint);
      
      // Label
      final textPainter = TextPainter(
        text: TextSpan(
          text: node.name,
          style: TextStyle(
            color: Colors.white,
            fontSize: isSelected ? 11 : 9,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: 100);
      textPainter.paint(
        canvas,
        Offset(pos.dx - (textPainter.width / 2), pos.dy + nodeRadius + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant NetworkPainter oldDelegate) {
    return oldDelegate.selectedNodeId != selectedNodeId ||
           oldDelegate.pulseValue != pulseValue;
  }
}
