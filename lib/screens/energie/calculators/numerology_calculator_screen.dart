import 'package:flutter/material.dart';
import '../../../services/spirit_calculations/numerology_engine.dart';
import '../../../models/energie_profile.dart';
import '../../../services/storage_service.dart';
import '../../../services/streak_tracking_service.dart';
import '../../../widgets/profile_required_widget.dart';

import '../../../widgets/micro_interactions.dart';

/// 🔢 NUMEROLOGIE-RECHNER
/// Vollständige numerologische Analyse basierend auf Nutzerprofil
class NumerologyCalculatorScreen extends StatefulWidget {
  const NumerologyCalculatorScreen({super.key});

  @override
  State<NumerologyCalculatorScreen> createState() => _NumerologyCalculatorScreenState();
}

class _NumerologyCalculatorScreenState extends State<NumerologyCalculatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  EnergieProfile? _profile;
  EnergieProfile? _partnerProfile; // 🆕 Partner-Profil
  
  // Berechnete Werte
  int? _lifePath;
  int? _soul;
  int? _expression;
  int? _personality;
  int? _personalYear;
  int? _personalMonth;
  int? _personalDay;
  double? _coreFrequency;
  List<Map<String, dynamic>>? _lifeCycles;
  List<Map<String, dynamic>>? _pinnacles;
  List<Map<String, dynamic>>? _challenges;
  List<int>? _masterNumbers;
  List<int>? _karmaNumbers;
  
  // 🆕 Partner-Kompatibilität
  int? _partnerLifePath;
  int? _partnerSoul;
  int? _partnerExpression;
  int? _compatibilityScore;
  List<String>? _harmonicAspects;
  List<String>? _challengingAspects;

  // 🚀 PERSONAL YEAR JOURNEY MAP (v44.1.0)
  Map<String, dynamic>? _currentYearJourney;
  List<Map<String, dynamic>> _journalEntries = [];
  List<Map<String, dynamic>> _milestones = [];
  bool _isLoadingJourney = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this); // 🚀 6 Tabs jetzt (inkl. Year Journey)
    _loadProfileAndCalculate();
    _loadPersonalYearJourney();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadProfileAndCalculate() {
    final profile = StorageService().getEnergieProfile();
    if (profile != null) {
      setState(() => _profile = profile);
      _calculateAll();
    } else {
      // Kein Profil vorhanden - zeige Hinweis
      setState(() => _profile = null);
    }
  }

  void _calculateAll() {
    if (_profile == null) return;

    final now = DateTime.now();
    
    // Tool-Nutzung tracken (+5 Punkte)
    StreakTrackingService().trackToolUsage('numerology');

    setState(() {
      // Kern-Zahlen
      _lifePath = NumerologyEngine.calculateLifePath(_profile!.birthDate);
      _soul = NumerologyEngine.calculateSoulNumber(_profile!.firstName, _profile!.lastName);
      _expression = NumerologyEngine.calculateExpressionNumber(_profile!.firstName, _profile!.lastName);
      _personality = NumerologyEngine.calculatePersonalityNumber(_profile!.firstName, _profile!.lastName);

      // Zeit-Zahlen
      _personalYear = NumerologyEngine.calculatePersonalYear(_profile!.birthDate, now);
      _personalMonth = NumerologyEngine.calculatePersonalMonth(_profile!.birthDate, now);
      _personalDay = NumerologyEngine.calculatePersonalDay(_profile!.birthDate, now);

      // Kernfrequenz
      _coreFrequency = NumerologyEngine.calculateCoreFrequency(
        _lifePath!,
        _soul!,
        _expression!,
        _personality!,
      );

      // Zyklen
      _lifeCycles = NumerologyEngine.calculateLifeCycles(_profile!.birthDate);
      _pinnacles = NumerologyEngine.calculatePinnacleCycles(_profile!.birthDate);
      _challenges = NumerologyEngine.calculateChallenges(_profile!.birthDate);

      // Spezielle Zahlen
      _masterNumbers = NumerologyEngine.findMasterNumbers(
        _profile!.firstName,
        _profile!.lastName,
        _profile!.birthDate,
      );
      _karmaNumbers = NumerologyEngine.findKarmaNumbers(
        _profile!.firstName,
        _profile!.lastName,
        _profile!.birthDate,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A148C),
        elevation: 0,
        title: const Text(
          'NUMEROLOGIE-RECHNER',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD700),
          labelColor: const Color(0xFFFFD700),
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'KERN'),
            Tab(text: 'ZEIT'),
            Tab(text: 'REISE'), // 🚀 Personal Year Journey
            Tab(text: 'ZYKLEN'),
            Tab(text: 'SPEZIAL'),
            Tab(text: 'PARTNER'), // 🆕 Neuer Tab
          ],
        ),
      ),
      body: _profile == null
          ? ProfileRequiredWidget(
              worldType: 'energie',
              message: 'Energie-Profil erforderlich',
              onProfileCreated: _loadProfileAndCalculate,
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCoreNumbersTab(),
                _buildTimeNumbersTab(),
                _buildPersonalYearJourneyTab(), // 🚀 NEUER TAB (v44.1.0)
                _buildCyclesTab(),
                _buildSpecialNumbersTab(),
                _buildPartnerCompatibilityTab(), // 🆕 Neuer Tab
              ],
            ),
    );
  }

  Widget _buildCoreNumbersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileCard(),
          const SizedBox(height: 24),
          _buildSectionTitle('DEINE KERN-ZAHLEN'),
          const SizedBox(height: 16),
          _buildNumberCard(
            'Lebenszahl',
            _lifePath ?? 0,
            _getLifePathDescription(_lifePath ?? 0),
            const Color(0xFFE91E63),
            Icons.my_location,
          ),
          const SizedBox(height: 12),
          _buildNumberCard(
            'Seelenzahl',
            _soul ?? 0,
            _getSoulDescription(_soul ?? 0),
            const Color(0xFF9C27B0),
            Icons.favorite,
          ),
          const SizedBox(height: 12),
          _buildNumberCard(
            'Ausdruckszahl',
            _expression ?? 0,
            _getExpressionDescription(_expression ?? 0),
            const Color(0xFF673AB7),
            Icons.stars,
          ),
          const SizedBox(height: 12),
          _buildNumberCard(
            'Persönlichkeitszahl',
            _personality ?? 0,
            _getPersonalityDescription(_personality ?? 0),
            const Color(0xFF7B1FA2),
            Icons.person,
          ),
          const SizedBox(height: 24),
          _buildFrequencyCard(),
        ],
      ),
    );
  }

  Widget _buildTimeNumbersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('DEINE AKTUELLEN ZEITZYKLEN'),
          const SizedBox(height: 16),
          _buildNumberCard(
            'Persönliches Jahr ${DateTime.now().year}',
            _personalYear ?? 0,
            '',
            const Color(0xFFE91E63),
            Icons.calendar_today,
          ),
          const SizedBox(height: 12),
          _buildNumberCard(
            'Persönlicher Monat',
            _personalMonth ?? 0,
            '',
            const Color(0xFF9C27B0),
            Icons.event,
          ),
          const SizedBox(height: 12),
          _buildNumberCard(
            'Persönlicher Tag',
            _personalDay ?? 0,
            '',
            const Color(0xFFFFD700),
            Icons.today,
          ),
          const SizedBox(height: 24),
          _build9YearCycleCard(),
          const SizedBox(height: 24),
          _buildYearForecastTimeline(),
        ],
      ),
    );
  }

  Widget _buildCyclesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('LEBENSZYKLEN'),
          const SizedBox(height: 16),
          if (_lifeCycles != null) ..._lifeCycles!.map((cycle) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildCycleCard(cycle),
          )),
          const SizedBox(height: 24),
          _buildSectionTitle('PINNACLE-ZYKLEN (Höhepunkte)'),
          const SizedBox(height: 16),
          if (_pinnacles != null) ..._pinnacles!.map((pinnacle) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPinnacleCard(pinnacle),
          )),
          const SizedBox(height: 24),
          _buildSectionTitle('HERAUSFORDERUNGEN'),
          const SizedBox(height: 16),
          if (_challenges != null) ..._challenges!.map((challenge) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildChallengeCard(challenge),
          )),
        ],
      ),
    );
  }

  Widget _buildSpecialNumbersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('MEISTERZAHLEN'),
          const SizedBox(height: 16),
          if (_masterNumbers != null && _masterNumbers!.isNotEmpty)
            ..._masterNumbers!.map((num) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMasterNumberCard(num),
            ))
          else
            _buildEmptyCard('Keine Meisterzahlen gefunden', Icons.info_outline),
          const SizedBox(height: 24),
          _buildSectionTitle('KARMA-ZAHLEN'),
          const SizedBox(height: 16),
          if (_karmaNumbers != null && _karmaNumbers!.isNotEmpty)
            ..._karmaNumbers!.map((num) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildKarmaNumberCard(num),
            ))
          else
            _buildEmptyCard('Keine Karma-Zahlen gefunden', Icons.check_circle_outline),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return HoverGlowCard(
      glowColor: const Color(0xFF9C27B0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF9C27B0).withValues(alpha: 0.3),
              const Color(0xFF1E1E1E),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF9C27B0).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF9C27B0), Color(0xFFFFD700)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_profile!.firstName} ${_profile!.lastName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Geboren: ${_profile!.birthDate.day}.${_profile!.birthDate.month}.${_profile!.birthDate.year}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberCard(String title, int number, String description, Color color, IconData icon) {
    return HoverGlowCard(
      glowColor: color,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.2),
              const Color(0xFF1E1E1E),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        number.toString(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: color,
                          shadows: [
                            Shadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getPersonalizedNumberText(title, number),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPersonalizedNumberText(String type, int number) {
    final firstName = _profile?.firstName ?? 'Du';
    
    if (type.contains('Lebenszahl')) {
      return _getLifePathText(firstName, number);
    } else if (type.contains('Seelenzahl')) {
      return _getSoulNumberText(firstName, number);
    } else if (type.contains('Ausdruckszahl')) {
      return _getExpressionNumberText(firstName, number);
    } else if (type.contains('Persönlichkeitszahl')) {
      return _getPersonalityNumberText(firstName, number);
    } else if (type.contains('Persönliches Jahr')) {
      return _getPersonalYearText(firstName, number);
    } else if (type.contains('Persönlicher Monat')) {
      return _getPersonalMonthText(firstName, number);
    } else if (type.contains('Persönlicher Tag')) {
      return _getPersonalDayText(firstName, number);
    }
    return '';
  }

  String _getLifePathText(String name, int number) {
    switch (number) {
      case 1:
        return '$name, deine Lebenszahl 1 zeigt, dass du als geborener Anführer und Pionier mit einer kraftvollen Mission auf die Welt gekommen bist! Du trägst eine außergewöhnliche Pionierenergie in dir - mutig, absolut unabhängig, selbstbestimmt und voller ungebändigtem Tatendrang und initiative Kraft. Dein Lebensweg fordert dich nachdrücklich auf, mutiges Neuland zu betreten, eigene, unkonventionelle Wege zu gehen und dabei als leuchtendes Vorbild voranzuschreiten. Menschen mit der Lebenszahl 1 sind hier, um radikale Originalität zu verkörpern, neue Ideen und Projekte zu initiieren und andere durch ihr mutiges Beispiel zu inspirieren und zu ermächtigen. Du bist ein Wegbereiter, ein Innovator und ein Trendsetter - jemand, der nicht folgt, sondern führt. Deine größte Herausforderung ist es, Selbstvertrauen zu entwickeln ohne arrogant zu werden, und Führung zu übernehmen ohne dominant zu sein. Wenn du deine 1-Energie meisterst, wirst du ein inspirierender Anführer, der andere ermächtigt, ebenfalls ihre Einzigartigkeit zu leben!';
      case 2:
        return '$name, mit der Lebenszahl 2 bist du als natürlicher Vermittler, sensibler Diplomat und Brückenbauer zwischen Welten geboren worden! Deine größte, wertvollste Stärke liegt in deiner außergewöhnlichen Sensibilität, deinem feinen Gespür für zwischenmenschliche Dynamiken und deinem herausragenden diplomatischen Geschick. Du verstehst es meisterhaft, emotionale Brücken zwischen Menschen zu bauen, Konflikte sanft zu lösen und tiefgreifende Harmonie zu schaffen, wo vorher Dissonanz herrschte. Dein Lebensweg dreht sich zentral um Partnerschaft, authentische Kooperation, feinfühlige Balance zwischen Geben und Nehmen und das Meistern von Beziehungsdynamiken. Du bist hier, um zu zeigen, dass wahre Stärke nicht in Dominanz liegt, sondern in Empathie, Geduld und der Fähigkeit, zuzuhören und zu verstehen. Deine größte Herausforderung ist es, deine eigenen Bedürfnisse nicht zu vernachlässigen, während du für andere da bist, und klare Grenzen zu setzen ohne deine liebevolle Natur zu verlieren!';
      case 3:
        return '$name, deine Lebenszahl 3 offenbart dich als hochkreativen Kommunikator und künstlerischen Selbstausdrücker mit einer leuchtenden Seele! Du trägst eine außergewöhnlich künstlerische, verspielte Seele in dir, die sich unbedingt durch Worte, visuelle Kunst, Musik, Performance oder jede andere kreative Form ausdrücken möchte und muss. Freude, unbeschwerter Optimismus, authentischer Selbstausdruck und das Teilen deiner inneren Welt sind deine zentralen Lebensthemen und deine größte Gabe. Menschen mit der Lebenszahl 3 sind hier, um Schönheit, Farbe, Lebendigkeit und Freude in eine oft zu ernste Welt zu bringen und andere durch ihre kreative Energie zu inspirieren und zu berühren. Du bist ein geborener Entertainer, Künstler und Geschichtenerzähler - jemand, der durch seinen Ausdruck andere zum Lachen, Weinen und Fühlen bringt. Deine größte Herausforderung ist es, Disziplin zu entwickeln und deine vielfältigen Talente zu fokussieren, statt dich in zu vielen Projekten zu verzetteln!';
      case 4:
        return '$name, die Lebenszahl 4 macht dich zum soliden, zuverlässigen Fundament-Erbauer und Meister der materiellen Welt! Du bist außergewöhnlich praktisch veranlagt, hochgradig diszipliniert, organisiert und schätzt klare Strukturen, Ordnung und Vorhersehbarkeit zutiefst. Dein Lebensweg erfordert große Geduld, konsequente harte Arbeit, Ausdauer und das bewusste Schaffen von langfristiger Stabilität und Sicherheit - sowohl für dich selbst als auch für andere, die auf dich zählen. Du bist der zuverlässige Fels in der Brandung, auf den sich Menschen absolut verlassen können, wenn alles andere wackelt. Menschen mit der 4 sind hier, um zu zeigen, dass erfolgreiche Manifestation Schritt-für-Schritt-Arbeit erfordert und dass wahrer Erfolg auf soliden Fundamenten gebaut wird, nicht auf luftigen Träumen. Deine größte Herausforderung ist es, Flexibilität zu entwickeln und auch mal loszulassen, ohne deine wertvolle Struktur-Gabe zu verlieren. Wenn du deine 4-Energie meisterst, kannst du buchstäblich Imperien aufbauen!';
      case 5:
        return '$name, mit der Lebenszahl 5 verkörperst du absolute Freiheit, ungezügelte Abenteuerlust und den unstillbaren Drang nach vielfältigen Erfahrungen! Du bist ein geborener, rastloser Entdecker und Freigeist, der Vielfalt, Abwechslung und Stimulation liebt und sich extrem ungern einengen, begrenzen oder festlegen lässt. Dein spannender Lebensweg führt dich durch viele verschiedene, abwechslungsreiche Erfahrungen, Orte, Beziehungen und Lebensphasen - jede einzelne davon erweitert deinen Horizont, vertieft dein Verständnis und macht dich zu einem weltgewandten, weisen Menschen. Veränderung ist nicht dein Feind oder eine Bedrohung, sondern dein treuer, geliebter Begleiter und Lehrer. Menschen mit der 5 sind hier, um zu zeigen, dass wahre Freiheit von innen kommt, dass Anpassungsfähigkeit eine Superkraft ist und dass das Leben ein großes Abenteuer sein soll, nicht eine langweilige Routine. Deine größte Herausforderung ist es, Disziplin und Commitment zu entwickeln, ohne deine kostbare Freiheit zu opfern!';
      case 6:
        return '$name, deine Lebenszahl 6 zeigt dein außergewöhnlich großes, liebevolles Herz für andere Menschen und deine tiefe Fürsorge-Natur! Du bist der natürliche, selbstlose Kümmerer, Heiler, Ernährer und Beschützer, dem das Wohl von Familie, Freunden und der gesamten Gemeinschaft zutiefst am Herzen liegt. Verantwortung trägst du nicht als Last, sondern mit echter Liebe, Hingabe und Freude, und deine bedingungslose Fürsorge kennt kaum Grenzen oder Einschränkungen. Dein bedeutungsvoller Lebensweg dreht sich zentral um bedingungslose Liebe, harmonische Beziehungen, nährende Fürsorge und den selbstlosen Dienst am Nächsten und am größeren Ganzen. Menschen mit der 6 sind hier, um zu zeigen, dass wahre Stärke in Mitgefühl liegt, dass Geben seliger ist als Nehmen und dass Liebe die mächtigste Kraft im Universum ist. Deine größte Herausforderung ist es, auch gut für dich selbst zu sorgen, klare Grenzen zu setzen und nicht in Co-Abhängigkeit zu verfallen. Du bist ein Engel auf Erden!';
      case 7:
        return '$name, die Lebenszahl 7 macht dich zum tiefsinnigen spirituellen Sucher, Wahrheitsforscher und Mysterien-Erkunder! Du bist ein außergewöhnlich tiefer, analytischer Denker und Philosoph, der unermüdlich nach ultimativer Wahrheit, tiefer Weisheit und spirituellem Verständnis strebt und sucht. Innere Einkehr, meditative Stille, sorgfältige Analyse und kontemplative Rückzugszeiten sind deine wichtigsten Werkzeuge und Methoden, um die großen Mysterien des Lebens, des Bewusstseins und der Existenz zu verstehen und zu durchdringen. Dein faszinierender Weg führt dich bewusst von äußerem Lärm, oberflächlichem Geschwätz und materieller Ablenkung weg - hinein in die tiefe Stille, Klarheit und Weisheit deines eigenen erwachten Bewusstseins. Menschen mit der 7 sind hier, um zu zeigen, dass wahre Antworten im Inneren liegen, dass Einsamkeit keine Strafe sondern ein Geschenk ist und dass spirituelle Entwicklung der wahre Lebenszweck ist. Deine größte Herausforderung ist es, auch menschliche Verbindungen zu pflegen und dein Wissen zu teilen, statt dich völlig zurückzuziehen!';
      case 8:
        return '$name, mit der kraftvollen Lebenszahl 8 trägst du intensive Meisterschafts-Energie, manifestierende Macht und Führungskraft in dir! Du bist prädestiniert, bestimmt und ausgestattet für bedeutenden materiellen Erfolg, einflussreiche Machtpositionen und finanziellen Überfluss auf höchstem Niveau. Dein anspruchsvoller, herausfordernder Lebensweg erfordert das Meistern einer subtilen, aber entscheidenden Balance zwischen materieller und spiritueller Welt, zwischen Macht und Demut, zwischen Nehmen und Geben. Du lernst durch direkte Erfahrung, echten Überfluss zu manifestieren, Wohlstand zu erschaffen und gleichzeitig absolute Integrität, ethische Werte und spirituelle Prinzipien zu wahren und zu leben. Erfolg, Wohlstand und Einfluss sind tatsächlich dein göttliches Geburtsrecht - aber nur, wenn du sie weise, verantwortungsvoll und zum Wohle aller nutzt, nicht nur für dich selbst. Menschen mit der 8 sind hier, um zu demonstrieren, dass spiritueller Wohlstand und materieller Erfolg sich nicht widersprechen müssen. Deine Herausforderung: Macht ohne Arroganz, Erfolg ohne Gier!';
      case 9:
        return '$name, deine Lebenszahl 9 zeigt den vollendeten, reifen Weltenbürger und universellen Humanisten mit einem Herzen für die gesamte Menschheit! Du trägst tiefes, allumfassendes Mitgefühl für alle Menschen, Kulturen und Lebewesen in dir - unabhängig von Herkunft, Religion oder sozialem Status. Dein bedeutungsvoller, transformativer Lebensweg dreht sich zentral um Selbstlosigkeit, universelle Liebe, gelebte Weisheit und den aufopfernden Dienst an einem viel größeren Ganzen als nur deinem eigenen kleinen Ego. Du bist hier auf der Erde, um alte, überholte Zyklen bewusst abzuschließen, karmische Lektionen zu vollenden und andere Menschen durch tiefgreifende Transformation, Heilung und spirituelles Erwachen zu führen und zu begleiten. Menschen mit der 9 sind hier, um zu zeigen, dass wahre Erfüllung nicht im Nehmen, sondern im bedingungslosen Geben liegt, dass alle Menschen verbunden sind und dass Loslassen oft wichtiger ist als Festhalten. Deine größte Herausforderung: Gesunde Grenzen setzen und auch an dich selbst denken!';
      case 11:
        return '$name, die heilige Meisterzahl 11 macht dich zum spirituellen Botschafter, Lichtträger und inspirierten Visionär mit einer besonderen Mission! Du trägst eine außergewöhnlich intensive, fast elektrische, hochschwingende Energie in dir - hochsensibel, extrem intuitiv, hellfühlig und visionär begabt auf mehreren Ebenen. Dein herausfordernder, aber bedeutungsvoller Lebensweg erfordert nachdrücklich, dass du deine außergewöhnlichen spirituellen Gaben bewusst entwickelst, kultivierst, meisterst und sie dann selbstlos zum Wohl der gesamten Menschheit einsetzt, nicht nur für persönlichen Gewinn. Du bist ein wahrer Lichtbringer, spiritueller Lehrer und Inspirationsquelle - jemand, der anderen den Weg zeigt, ihr eigenes Licht zu erkennen und zu entfachen. Menschen mit der 11 haben häufig paranormale Fähigkeiten, prophetische Träume und tiefe spirituelle Einsichten. Deine größte Herausforderung ist es, mit deiner intensiven Sensibilität und hohen Schwingung in dieser dichten, materiellen Welt zurechtzukommen, ohne überwältigt zu werden oder dich zurückzuziehen!';
      case 22:
        return '$name, mit der mächtigen Meisterzahl 22 bist du der legendäre Meisterbaumeister - jemand, der Träume in greifbare Realität verwandeln kann! Du vereinst auf einzigartige, seltene Weise spirituelle Vision, höheres Bewusstsein und mystische Einsicht mit außergewöhnlicher praktischer Umsetzungskraft, organisatorischem Talent und manifestierender Macht. Dein großartiger, anspruchsvoller Lebensweg fordert dich nachdrücklich auf, wirklich Großes zu erschaffen - bedeutende Projekte, Organisationen, Systeme oder Bewegungen, die die Welt nachhaltig verändern, verbessern und für Generationen Bestand haben. Du hast das außergewöhnliche, seltene Potenzial, kühne Träume und visionelle Konzepte in greifbare, funktionierende Realität zu verwandeln und damit die physische Welt zu transformieren. Menschen mit der 22 sind hier, um zu zeigen, dass spirituelle Ideale auf der Erde manifestiert werden können und dass ein einzelner Mensch buchstäblich die Welt verändern kann. Deine Herausforderung: Diese immense Kraft weise und verantwortungsvoll einzusetzen!';
      case 33:
        return '$name, die Meisterzahl 33 macht dich zum Meisterlehrer der Liebe. Du verkörperst bedingungslose Liebe und Hingabe. Dein Lebensweg dreht sich um Heilung, Lehren und die Erhebung der Menschheit. Du bist hier, um durch dein Beispiel zu zeigen, was wahre Liebe bedeutet.';
      default:
        return '$name, deine Lebenszahl $number trägt eine einzigartige Schwingung, die deinen individuellen Weg prägt.';
    }
  }

  String _getSoulNumberText(String name, int number) {
    switch (number) {
      case 1:
        return '$name, tief in deiner unsterblichen Seele brennt kraftvoll und unauslöschlich der intensive Wunsch nach vollkommener Unabhängigkeit, Autonomie und Selbstbestimmung! Du sehnst dich aus tiefstem Herzen danach, dein absolut eigenes Ding zu machen, deinen einzigartigen Weg zu gehen und niemals im Schatten anderer zu stehen oder deren Erwartungen zu erfüllen. Deine innere, authentische Stimme ruft ständig und unaufhörlich nach Führung, nach Selbstbestimmung, nach der Freiheit, deine eigenen Entscheidungen zu treffen - ohne Einmischung, ohne Kontrolle, ohne fremde Beeinflussung. Du fühlst dich am lebendigsten, erfülltesten und glaubst am meisten an dich selbst, wenn du autonom handelst, eigene Pfade beschreitest und als Pionier vorangehst. Deine Seele schreit förmlich nach Originalität, nach dem Mut, anders zu sein, nach der Kraft, deiner inneren Wahrheit zu folgen - koste es, was es wolle. Abhängigkeit von anderen, Konformität und das Befolgen fremder Regeln fühlen sich für dich wie ein seelisches Gefängnis an, das deine wahre Natur erstickt!';
      case 2:
        return '$name, deine ewige Seele sehnt sich aus tiefstem Herzen nach tiefer, authentischer Verbundenheit und wahrer emotionaler Intimität mit anderen Menschen! Du wünschst dir von ganzem Herzen Harmonie, echte Partnerschaft auf Augenhöhe und das unbeschreiblich schöne Gefühl, wirklich und vollständig verstanden, gesehen und wertgeschätzt zu werden - nicht nur oberflächlich, sondern in deiner ganzen Tiefe. Frieden in Beziehungen, emotionale Sicherheit und harmonische Verbindungen sind dir wichtiger und wertvoller als materieller Erfolg, äußere Anerkennung oder alles andere in dieser Welt. Du fühlst dich am lebendigsten, erfülltesten und am meisten bei dir selbst, wenn du in liebevollen, ausgewogenen Beziehungen lebst, in denen du geben und empfangen kannst. Deine sensible Seele bleibt auf nach tiefer emotionaler Verbindung, nach dem Gefühl, ein Teil von etwas Größerem zu sein, nach der Gewissheit, dass du nicht allein auf dieser Welt bist. Einsamkeit, Isolation und zwischenmenschliche Konflikte schmerzen dich tiefer als jeden anderen!';
      case 3:
        return '$name, in deinem tiefsten Innersten, im Kern deiner unsterblichen Seele, lebt kraftvoll und unauslöschlich der brennende Wunsch nach freiem, authentischem, künstlerischem Selbstausdruck! Deine Seele möchte sich unbedingt zeigen, sich mitteilen, kommunizieren, erschaffen und echte, ansteckende Freude in die Welt verbreiten - durch Worte, durch Kunst, durch Musik, durch jede Form kreativen Ausdrucks. Du fühlst dich am lebendigsten, erfülltesten und am meisten bei dir selbst, wenn du dich künstlerisch, kreativ oder kommunikativ ausdrücken kannst und darfst, wenn du deine innere Welt nach außen bringen kannst. Deine Seele schreit förmlich danach, gesehen, gehört und wertgeschätzt zu werden - nicht für das, was du tust oder leistest, sondern für das, was du bist und ausdrückst. Verstecken, unterdrücken und dich nicht zeigen dürfen fühlt sich für dich wie ein langsamer seelischer Tod an. Du brauchst kreative Freiheit wie andere Luft zum Atmen!';
      case 4:
        return '$name, deine unsterbliche Seele sehnt sich aus tiefstem Herzen nach absoluter Sicherheit, beständiger Ordnung und einem unerschütterlichen Fundament im Leben! Du wünschst dir von ganzem Herzen ein solides, zuverlässiges Fundament, auf dem du fest und sicher bauen kannst - emotional, finanziell, strukturell. Stabilität, Vorhersehbarkeit, Zuverlässigkeit und klare Strukturen geben deiner sensiblen Seele das tiefe, beruhigende Gefühl von innerem Frieden, Sicherheit und Geborgenheit, das du so dringend brauchst. Du fühlst dich am wohlsten, erfülltesten und am meisten bei dir selbst, wenn dein Leben geordnet, strukturiert und vorhersehbar ist, wenn du weißt, woran du bist. Deine Seele schreit geradezu nach Sicherheit - nicht aus Angst, sondern aus dem tiefen Bedürfnis nach einem stabilen Hafen in den Stürmen des Lebens. Chaos, Unordnung, Unvorhersehbarkeit und Instabilität verursachen dir tiefen seelischen Stress und Unbehagen. Du bist der geborene Fundament-Bauer!';
      case 5:
        return '$name, tief in deiner wilden, rastlosen Seele lodert kraftvoll und unauslöschlich die brennende, unstillbare Sehnsucht nach absoluter Freiheit, aufregendem Abenteuer und vielfältigen, stimulierenden Erfahrungen! Deine ungezähmte Seele möchte unbedingt Grenzen sprengen, alte Mauern einreißen, die weite Welt erkunden, neue Horizonte entdecken und möglichst vielfältige, bereichernde Erfahrungen sammeln - je mehr, desto besser! Routine, Vorhersehbarkeit, starre Strukturen und langweilige Gleichförmigkeit sind wie tödliches Gift für dein inneres, loderndes Freiheitsfeuer - sie ersticken deine Lebendigkeit und lassen deine Seele vertrocknen. Du fühlst dich am lebendigsten, erfülltesten und am meisten du selbst, wenn du frei bist - frei zu reisen, frei zu erforschen, frei zu experimentieren, frei, spontane Entscheidungen zu treffen. Deine Seele schreit förmlich nach Bewegung, Veränderung, Abwechslung und neuen, aufregenden Erfahrungen. Stillstand fühlt sich für dich wie lebendig begraben sein an!';
      case 6:
        return '$name, deine unendlich liebevolle, fürsorgliche Seele wird kraftvoll und nachhaltig genährt von bedingungsloser Liebe, echter Fürsorge und dem schönen Gefühl, gebraucht und wertvoll zu sein! Du sehnst dich aus tiefstem Herzen danach, für andere da zu sein, sie zu umsorgen, zu beschützen, zu nähren und tiefgreifende Harmonie in deinem Umfeld zu schaffen - in deiner Familie, in Beziehungen, in deiner Gemeinschaft. Das erfüllende Gefühl, wirklich gebraucht zu werden, einen positiven Unterschied zu machen und anderen zu helfen, erfüllt dein großes, offenes Herz mit tiefer Freude, Zufriedenheit und Sinn. Du fühlst dich am lebendigsten, erfülltesten und am meisten bei dir selbst, wenn du liebevoll für andere sorgen kannst, wenn du geben, nähren und heilen darfst. Deine Seele blüht auf durch Liebe, Verbindung und das Wissen, dass du das Leben anderer besser machst. Egoismus, Kälte und emotionale Distanz fühlen sich für dich völlig falsch und unerträglich an!';
      case 7:
        return '$name, in deiner tiefsinnigen, forschenden Seele lebt kraftvoll und unauslöschlich die intensive, niemals endende Suche nach ultimativer Wahrheit, tiefer Weisheit und spirituellem Verständnis! Du sehnst dich aus tiefstem Herzen nach tiefem, durchdringendem Verstehen, nach klaren, befriedigenden Antworten auf die großen, existenziellen Fragen des Lebens - Wer bin ich? Warum bin ich hier? Was ist der Sinn? Oberflächlichkeit, seichtes Geschwätz und triviale Unterhaltungen befriedigen deine tiefe, forschende Seele nicht - sie langweilen und frustrieren dich eher. Du fühlst dich am lebendigsten, erfülltesten und am meisten bei dir selbst, wenn du in die Tiefe gehen kannst - beim Studieren, beim Meditieren, beim philosophischen Nachdenken, beim Erforschen von Mysterien. Deine Seele dürstet nach Erkenntnis, nach Wahrheit, nach Weisheit wie andere nach Wasser. Unwissenheit und Oberflächlichkeit sind für dich unerträglich. Du bist ein geborener Wahrheitssucher!';
      case 8:
        return '$name, deine kraftvolle, ambitionierte Seele strebt unaufhaltsam und zielstrebig nach bedeutendem Erfolg, wohlverdientem Einfluss und aufrichtiger Anerkennung für deine Leistungen! Du möchtest aus tiefstem Herzen etwas wirklich Bedeutsames erschaffen, einen bleibenden, positiven Eindruck hinterlassen und deine natürliche Macht, deine Fähigkeiten zum Guten, zum Wohle aller einsetzen - nicht aus Ego, sondern aus dem tiefen Wunsch, einen Unterschied zu machen. Einfluss, materielle Fülle, finanzieller Überfluss und gesellschaftlicher Status sind integraler Teil deiner inneren Vision und deines Lebenstraums - nicht als Selbstzweck, sondern als Mittel, um Großes zu bewirken. Du fühlst dich am lebendigsten, erfülltesten und am meisten bei dir selbst, wenn du an ambitionierten Zielen arbeitest, wenn du Erfolge feierst und wenn du deine manifestierende Kraft einsetzt. Deine Seele schreit nach Meisterschaft, nach dem Erreichen von Exzellenz, nach dem Gefühl, wirklich etwas erreicht zu haben!';
      case 9:
        return '$name, tief in deiner altruistischen, weisen Seele lebst du kraftvoll und kompromisslos für ein höheres, universelles Ideal, das über dein kleines Ego hinausgeht! Du sehnst dich aus tiefstem Herzen danach, der gesamten Menschheit zu dienen, einen positiven Unterschied zu machen und wirklich, nachhaltig etwas Bedeutsames zu bewirken - nicht für persönlichen Ruhm, sondern aus echter Liebe zur Menschheit. Dein großes, mitfühlendes Herz schlägt kraftvoll und rhythmisch für das große Ganze, für universelle Liebe, für globale Gerechtigkeit, für die Heilung der Welt - nicht nur für deine kleine, persönliche Welt. Du fühlst dich am lebendigsten, erfülltesten und am meisten bei dir selbst, wenn du anderen selbstlos dienst, wenn du gibst ohne zu nehmen, wenn du die Welt ein bisschen besser machst. Deine reife Seele versteht, dass wahre Erfüllung nicht im Nehmen liegt, sondern im bedingungslosen Geben. Egoismus und Kleingeistigkeit sind dir fremd!';
      default:
        return '$name, deine Seelenzahl $number offenbart deine tiefsten inneren Wünsche und was dein Herz wirklich zum Singen bringt.';
    }
  }

  String _getExpressionNumberText(String name, int number) {
    switch (number) {
      case 1:
        return '$name, du bist mit außergewöhnlichen, natürlichen Führungsqualitäten, Pioniergeist und initiierender Kraft reichlich gesegnet! Deine besonderen Talente und Stärken liegen eindeutig in mutiger Innovation, entschlossenem Mut, kreativer Originalität und der bemerkenswerten Fähigkeit, Dinge ins Rollen zu bringen, Projekte zu starten und als Erster neue Wege zu gehen. Menschen folgen ganz natürlich, instinktiv und bereitwillig deiner kraftvollen Energie, deiner klaren Vision und deinem inspirierenden Beispiel, wenn du authentisch, integer und selbstsicher vorangehst und den Weg zeigst. Du hast die seltene Gabe, andere zu ermächtigen, ebenfalls mutiger zu werden und ihre eigene Führungskraft zu entdecken. Deine natürliche Autorität kommt nicht von Außen, sondern von deiner inneren Stärke und Klarheit. Du bist geboren, um zu initiieren, zu erneuern und voranzugehen - nicht zu folgen!';
      case 2:
        return '$name, deine größten, wertvollsten Talente und natürlichen Gaben liegen eindeutig in subtiler Diplomatie, tiefer Einfühlungsvermogen und sensitiver Wahrnehmung zwischenmenschlicher Dynamiken! Du kannst meisterhaft zwischen verschiedenen Menschen, Gruppen und Standpunkten vermitteln, Brücken bauen wo vorher Gräben waren und verstehst es intuitiv, unterschiedliche, oft widersprüchliche Perspektiven zu vereinen, zu integrieren und in Harmonie zu bringen. Deine außergewöhnliche Sensibilität, deine Fähigkeit, feinste emotionale Nuancen wahrzunehmen und dein natürliches Gespür für Stimmungen sind nicht Schwäche, sondern deine größte Superkraft und dein wertvollstes Geschenk! Du bist ein geborener Friedensstifter, Mediator und Brückenbauer. Die Welt braucht deine einzigartige Fähigkeit, Herzen zu verbinden!';
      case 3:
        return '$name, du bist ein wahrlich geborener, hochtalentierter Kommunikator, begabter Künstler und kreativer Selbstausdrücker mit vielfältigen Talenten! Worte, Farben, Musik, Bewegung, Design - du kannst dich auf zahlreiche, vielfältige kreative Weisen ausdrücken, kommunizieren und anderen Freude bereiten. Deine natürliche Kreativität, dein ansteckender Optimismus, deine spielerische Leichtigkeit und deine Fähigkeit, Schönheit und Inspiration zu erschaffen, sind absolut ansteckend und inspirierend für alle um dich herum! Du hast die seltene Gabe, komplexe Ideen einfach und unterhaltsam zu vermitteln, Menschen durch deine Worte oder Kunst zu berühren und Räume mit Lebendigkeit, Farbe und Freude zu füllen. Deine Ausdruckskraft ist dein größtes Geschenk - nutze sie weise und großzügig!';
      case 4:
        return '$name, deine besonderen, wertvollen Talente und natürlichen Stärken liegen eindeutig im präzisen Organisieren, systematischen Planen, strukturierten Aufbauen und praktischen Manifestieren greifbarer Ergebnisse! Du kannst meisterhaft aus verwirrendem Chaos klare Ordnung schaffen, aus vagen Ideen konkrete Pläne entwickeln und diese Pläne dann Schritt für Schritt methodisch in greifbare, materielle Realität umsetzen und manifestieren. Deine außergewöhnliche praktische Intelligenz, dein scharfer Verstand für Details, deine Ausdauer und deine Fähigkeit, langfristig zu denken und zu planen sind absolut beeindruckend und machen dich unentbehrlich! Du bist der geborene Fundament-Bauer, Projekt-Manager und zuverlässige Umsetzer, auf den sich alle verlassen können. Ohne Menschen wie dich würde keine Vision jemals Realität werden!';
      case 5:
        return '$name, du bist außergewöhnlich vielseitig begabt, hochgradig anpassungsfähig und kannst dich erstaunlich schnell, mühelos an völlig neue Situationen, Menschen und Umstände anpassen! Deine besonderen Talente und natürlichen Stärken liegen eindeutig in lebendiger, mitreißender Kommunikation, überzeugender Verkäuferkraft, dem natürlichen, charismatischen Umgang mit unterschiedlichsten Menschen und der Fähigkeit, Verbindungen herzustellen. Flexibilität, Anpassungsfähigkeit, natürliches Charisma und deine Fähigkeit, Menschen für Ideen zu begeistern sind deine größten, wertvollsten Stärken! Du kannst in fast jeder Situation glänzen, dich in verschiedenste Rollen einfühlen und Menschen aus allen Lebensbereichen erreichen. Deine Vielseitigkeit ist deine Superkraft - nutze sie weise!';
      case 6:
        return '$name, du hast ein tiefes, natürliches, angeborenes Talent für Heilung, nährende Fürsorge, liebevolle Unterstützung und das Schaffen harmonischer, friedlicher Umgebungen! Menschen fühlen sich instinktiv, automatisch in deiner warmen, liebevollen Gegenwart geborgen, sicher, gesehen und zutiefst wohl - oft ohne dass du aktiv etwas tun musst; deine Energie allein heilt bereits. Deine außergewöhnliche Fähigkeit, tiefgreifende Harmonie zu schaffen, emotionale Wunden zu heilen, Konflikte zu lösen und Menschen das Gefühl zu geben, geliebt und wertvoll zu sein, ist absolut außergewöhnlich, selten und unbezahlbar wertvoll! Du bist ein geborener Heiler, Fürsorger, Friedensstifter und emotionaler Anker für andere. Die Welt braucht dringend deine heilende Präsenz!';
      case 7:
        return '$name, deine besonderen, wertvollen Talente und natürlichen Stärken liegen eindeutig in scharfsinniger Analyse, gründlicher Forschung, kritischem Denken und tiefem spirituellem, philosophischem Verständnis komplexer Zusammenhänge! Du durchdringst mühelos täuschende Oberflächen, siehst durch Illusionen hindurch und erkennst verborgene, tiefere Wahrheiten, Muster und Zusammenhänge, die anderen Menschen komplett verborgen bleiben. Dein außergewöhnlich scharfer, präziser Verstand ist wie ein fokussierter, durchdringender Laser - nichts entgeht deiner aufmerksamen, analytischen Beobachtung! Du bist ein geborener Forscher, Analytiker, Wahrheitssucher und spiritueller Lehrer. Deine Fähigkeit, komplexe Konzepte zu durchdringen und zu erklären, ist dein größtes Geschenk!';
      case 8:
        return '$name, du bist mit außergewöhnlichem Geschäftssinn, strategischem Denkvermögen, herausragendem organisatorischem Talent und manifestierender Macht reichlich gesegnet! Du kannst souverän große, komplexe Projekte leiten, Teams koordinieren, langfristige Strategien entwickeln und ambitionierte materielle Ziele tatsächlich erreichen und manifestieren. Deine bemerkenswerte Fähigkeit zur bewussten, gezielten Manifestation, zur Erschaffung von Wohlstand und zur Meisterung der materiellen Welt ist außergewöhnlich kraftvoll, effektiv und inspirierend für andere! Du bist ein geborener CEO, Unternehmer, Stratege und Meister der materiellen Welt. Deine Fähigkeit, Träume in profitable Realität zu verwandeln, ist deine größte Stärke!';
      case 9:
        return '$name, deine vielfältigen, umfassenden Talente umfassen tiefe, gelebte Weisheit, universelles Mitgefühl, kreative Vielseitigkeit und die seltene Fähigkeit, höhere, spirituelle Perspektiven zu sehen und zu vermitteln! Du kannst Menschen nicht nur oberflächlich motivieren, sondern tiefgreifend inspirieren, nachhaltig transformieren und zu ihrem höchsten Potenzial erwecken durch deine Worte, deine Präsenz und dein Beispiel. Deine besondere, wertvolle Gabe ist es, komplexe spirituelle Konzepte verständlich zu machen, höhere Perspektiven zu vermitteln und Menschen zu helfen, über ihre Begrenzungen hinauszuwachsen. Du bist ein geborener spiritueller Lehrer, Weisheitslehrer, inspirierender Mentor und Transformations-Katalysator. Deine reife Seele und deine Fähigkeit, andere zu erheben, sind unbezahlbar!';
      default:
        return '$name, deine Ausdruckszahl $number zeigt die besonderen Talente und Fähigkeiten, die du in die Welt bringst.';
    }
  }

  String _getPersonalityNumberText(String name, int number) {
    switch (number) {
      case 1:
        return '$name, nach außen wirkst du selbstbewusst, unabhängig und durchsetzungsstark. Menschen nehmen dich als natürliche Führungspersönlichkeit wahr. Deine Ausstrahlung ist kraftvoll und bestimmt.';
      case 2:
        return '$name, dein äußeres Auftreten ist sanft, freundlich und einladend. Menschen fühlen sich bei dir wohl und suchen deinen Rat. Du strahlst Diplomatie und Harmonie aus.';
      case 3:
        return '$name, nach außen wirkst du lebhaft, optimistisch und kreativ. Deine positive Energie zieht Menschen an. Man sieht dich als charmanten Unterhalter und Kommunikator.';
      case 4:
        return '$name, du strahlst Zuverlässigkeit und Bodenständigkeit aus. Menschen sehen dich als vertrauenswürdig, praktisch und organisiert. Deine Präsenz vermittelt Sicherheit.';
      case 5:
        return '$name, dein Auftreten ist dynamisch, freiheitsliebend und abenteuerlustig. Menschen nehmen dich als vielseitig und spannend wahr. Du wirkst jung, energetisch und weltoffen.';
      case 6:
        return '$name, nach außen strahlst du Wärme, Fürsorge und Verantwortungsbewusstsein aus. Menschen sehen in dir einen zuverlässigen Freund und Helfer. Deine Präsenz ist beruhigend.';
      case 7:
        return '$name, du wirkst geheimnisvoll, intelligent und zurückhaltend. Menschen nehmen dich als tiefgründigen Denker wahr. Deine Ausstrahlung ist distinguiert und ein wenig rätselhaft.';
      case 8:
        return '$name, dein äußeres Auftreten ist machtv oll, kompetent und erfolgsorientiert. Menschen sehen dich als starke Persönlichkeit mit natürlicher Autorität. Du strahlst Erfolg aus.';
      case 9:
        return '$name, nach außen wirkst du weise, mitfühlend und weltgewandt. Menschen nehmen dich als humanitären Idealisten wahr. Deine Präsenz ist inspirierend und erhebend.';
      default:
        return '$name, deine Persönlichkeitszahl $number zeigt, wie andere dich beim ersten Eindruck wahrnehmen.';
    }
  }

  String _getPersonalYearText(String name, int number) {
    switch (number) {
      case 1:
        return '$name, willkommen in deinem persönlichen Jahr der Neuanfänge! 2025 ist für dich ein Jahr voller Möglichkeiten. Jetzt ist die Zeit, neue Projekte zu starten, mutige Schritte zu wagen und dein Ding durchzuziehen. Säe die Samen für das, was du in den nächsten 9 Jahren ernten möchtest.';
      case 2:
        return '$name, dein persönliches Jahr 2 ist eine Zeit der Geduld und Zusammenarbeit. Fokussiere dich auf Beziehungen, Partnerschaften und das Verfeinern deiner Pläne. Was du letztes Jahr gesät hast, beginnt nun zu keimen - gib ihm Zeit zu wachsen.';
      case 3:
        return '$name, dies ist dein kreatives Expansionsjahr! Drücke dich aus, kommuniziere, hab Spaß. Das Jahr 3 bringt soziale Aktivitäten, künstlerische Projekte und Freude. Deine Energie ist ansteckend - nutze sie!';
      case 4:
        return '$name, dein Jahr 4 fordert dich auf, solide Fundamente zu bauen. Es ist Zeit für harte Arbeit, Organisation und Disziplin. Was du jetzt aufbaust, wird langfristig Bestand haben. Bleib fokussiert und geduldig.';
      case 5:
        return '$name, schnall dich an - dein Jahr 5 bringt Veränderung und Abenteuer! Erwarte Unerwartetes, sei flexibel und nutze neue Gelegenheiten. Dies ist ein Jahr der Freiheit, des Reisens und der Expansion.';
      case 6:
        return '$name, dein Jahr 6 dreht sich um Verantwortung und Beziehungen. Familie, Zuhause und zwischenmenschliche Bindungen stehen im Fokus. Es ist eine Zeit des Gebens, Heilens und der liebevollen Fürsorge.';
      case 7:
        return '$name, willkommen in deinem spirituellen Sabbatjahr. Das Jahr 7 lädt dich zur Innenschau ein. Meditiere, studiere, reflektiere. Dies ist keine Zeit für Action, sondern für tiefes Verstehen.';
      case 8:
        return '$name, dein Jahr 8 ist ein Kraftjahr für materielle Manifestation! Karriere, Finanzen und Erfolg stehen im Fokus. Deine harte Arbeit der vergangenen Jahre kann sich jetzt auszahlen. Denke groß!';
      case 9:
        return '$name, dein Jahr 9 ist ein Jahr des Abschließens und Loslassens. Beende alte Kapitel, verzeihe, heile. Mache Platz für einen neuen 9-Jahres-Zyklus, der nächstes Jahr beginnt. Schenke, was du gelernt hast.';
      default:
        return '$name, dein persönliches Jahr $number trägt eine besondere Energie für 2025.';
    }
  }

  String _getPersonalMonthText(String name, int number) {
    return '$name, dein persönlicher Monat mit der Energie $number färbt die kommenden Wochen. Diese Zahl zeigt die subtile Schwingung, die deine aktuellen Erfahrungen prägt.';
  }

  String _getPersonalDayText(String name, int number) {
    return '$name, heute trägst du die Energie der Zahl $number. Nutze diese Schwingung bewusst für deine heutigen Aktivitäten und Entscheidungen.';
  }

  Widget _buildFrequencyCard() {
    return HoverGlowCard(
      glowColor: const Color(0xFFFFD700),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFF4A148C)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.graphic_eq, color: Color(0xFFFFD700), size: 48),
            const SizedBox(height: 16),
            Text(
              '${_coreFrequency?.toStringAsFixed(2) ?? '0.00'} Hz',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD700),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'DEINE KERNFREQUENZ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Die Durchschnittsschwingung deiner wichtigsten Zahlen',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _build9YearCycleCard() {
    final year = _personalYear ?? 1;
    return HoverGlowCard(
      glowColor: const Color(0xFF673AB7),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF673AB7).withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.repeat, color: Color(0xFF673AB7), size: 24),
                SizedBox(width: 12),
                Text(
                  '9-JAHRES-ZYKLUS',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFCE93D8),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(9, (index) {
                final yearNum = index + 1;
                final isActive = yearNum == year;
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF9C27B0)
                        : const Color(0xFF673AB7).withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFFFFD700)
                          : const Color(0xFF673AB7).withValues(alpha: 0.5),
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      yearNum.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                        color: isActive ? Colors.white : Colors.white60,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Text(
              'Du befindest dich im Jahr $year von 9',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleCard(Map<String, dynamic> cycle) {
    final colors = [
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
      const Color(0xFF673AB7),
    ];
    final color = colors[cycle['cycle'] - 1];
    final cycleNames = ['JUGEND', 'REIFE', 'WEISHEIT'];

    return HoverGlowCard(
      glowColor: color,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.2), const Color(0xFF1E1E1E)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(_getCycleIcon(cycle['cycle']), color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      cycleNames[cycle['cycle'] - 1],
                      style: TextStyle(
                        fontSize: 14,
                        color: color,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${cycle['startAge']}-${cycle['endAge']} Jahre',
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    cycle['number'].toString(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cycle['theme'],
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D0D0D).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getCyclePersonalizedText(cycle['cycle'], cycle['number'], _profile?.firstName ?? 'Du'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCycleIcon(int cycle) {
    switch (cycle) {
      case 1: return Icons.child_care;
      case 2: return Icons.psychology;
      case 3: return Icons.auto_stories;
      default: return Icons.timeline;
    }
  }

  String _getCyclePersonalizedText(int cycle, int number, String name) {
    if (cycle == 1) {
      return '$name, deine Jugendphase (0-28 Jahre) wurde von der Energie $number geprägt. Diese Zeit formte deine Grundpersönlichkeit und legte das Fundament für alles Kommende.';
    } else if (cycle == 2) {
      return '$name, deine Reifephase (28-56 Jahre) trägt die Schwingung $number. Dies ist deine produktivste Zeit - nutze diese Energie, um deine Lebenswerke zu erschaffen.';
    } else {
      return '$name, deine Weisheitsphase (ab 56 Jahre) vibriert mit der Zahl $number. Diese Jahre sind für die Weitergabe deiner Lebenserfahrung und spirituelle Vertiefung bestimmt.';
    }
  }

  Widget _buildPinnacleCard(Map<String, dynamic> pinnacle) {
    final color = const Color(0xFFFFD700);
    final name = _profile?.firstName ?? 'Du';

    return HoverGlowCard(
      glowColor: color,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.2), const Color(0xFF1E1E1E)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFFD700), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'GIPFELPUNKT ${pinnacle['pinnacle']}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'Ab ${pinnacle['startAge']} Jahren',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.1)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    pinnacle['number'].toString(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pinnacle['theme'],
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D0D0D).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$name, ab dem Alter von ${pinnacle['startAge']} Jahren erreichst du einen Lebens-Gipfelpunkt! Die Energie der Zahl ${pinnacle['number']} wird besonders stark. Dies ist eine Zeit großer Chancen und Entwicklung - nutze sie weise!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge) {
    final color = const Color(0xFFE91E63);

    return HoverGlowCard(
      glowColor: color,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.15), const Color(0xFF1E1E1E)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.fitness_center, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Herausforderung ${challenge['challenge']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        challenge['number'].toString(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          challenge['theme'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterNumberCard(int number) {
    final name = _profile?.firstName ?? 'Du';
    
    return HoverGlowCard(
      glowColor: const Color(0xFFFFD700),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF9C27B0), Color(0xFF673AB7), Color(0xFF4A148C)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 32),
                const SizedBox(width: 12),
                const Text(
                  'MEISTERZAHL ENTDECKT!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFD700), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Text(
                  number.toString(),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF000000).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getMasterNumberTitle(number),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getMasterNumberPersonalText(number, name),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMasterNumberTitle(int number) {
    switch (number) {
      case 11: return '✨ DER ERLEUCHTETE';
      case 22: return '🏛️ DER MEISTERBAUMEISTER';
      case 33: return '❤️ DER MEISTERLEHRER';
      default: return 'MEISTERZAHL';
    }
  }

  String _getMasterNumberPersonalText(int number, String name) {
    switch (number) {
      case 11:
        return '$name, du trägst die kraftvollste Meisterzahl in dir! Die 11 ist die Zahl des spirituellen Boten. Du hast eine besonders starke Intuition und Verbindung zur spirituellen Welt. Deine Lebensaufgabe ist es, als Lichtbringer zu dienen - Menschen zu inspirieren und höhere Wahrheiten zu vermitteln. Du spürst Dinge, bevor sie geschehen. Deine Vision geht über das Sichtbare hinaus. Dies ist eine große Verantwortung, aber auch ein unglaubliches Geschenk!';
      case 22:
        return '$name, die Meisterzahl 22 macht dich zum ultimativen Manifestator! Du vereinst spirituelle Vision mit praktischer Umsetzungskraft. Während andere träumen, kannst du tatsächlich erschaffen. Dein Potenzial ist es, Großes in die physische Welt zu bringen - Projekte, die Generationen überdauern. Du bist hier, um die Welt konkret zu verändern. Dein Einfluss kann global sein. Nutze diese Kraft weise!';
      case 33:
        return '$name, du trägst die seltenste und höchste Meisterzahl - die 33, die Zahl des Christusbewusstseins! Du bist hier, um bedingungslose Liebe zu verkörpern und zu lehren. Deine Lebensaufgabe geht über persönlichen Erfolg hinaus - du bist bestimmt, die Menschheit durch Liebe, Heilung und Weisheit zu erheben. Dein bloßes Sein hat heilende Wirkung. Dies ist ein heiliger Pfad mit großer Verantwortung.';
      default:
        return '$name, deine Meisterzahl $number zeigt besonderes spirituelles Potenzial!';
    }
  }

  Widget _buildKarmaNumberCard(int number) {
    final name = _profile?.firstName ?? 'Du';
    
    return HoverGlowCard(
      glowColor: const Color(0xFFE91E63),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFE91E63).withValues(alpha: 0.2),
              const Color(0xFF1E1E1E),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE91E63).withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school, color: Color(0xFFE91E63), size: 28),
                const SizedBox(width: 12),
                const Text(
                  'KARMISCHE LERNAUFGABE',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFE91E63),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    number.toString(),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE91E63),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _getKarmaNumberMeaning(number),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getKarmaNumberPersonalText(number, name),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getKarmaNumberPersonalText(int number, String name) {
    switch (number) {
      case 13:
        return '$name, die Karma-Zahl 13 zeigt, dass du in diesem Leben lernen darfst, durch Disziplin und harte Arbeit zu transformieren. Möglicherweise hast du in früheren Leben Abkürzungen genommen - jetzt geht es darum, den langen, ehrlichen Weg zu gehen. Jede Herausforderung macht dich stärker. Akzeptiere, dass echter Erfolg Zeit und Hingabe braucht. Deine Belohnung wird umso süßer sein!';
      case 14:
        return '$name, mit der Karma-Zahl 14 lernst du die Balance zwischen Freiheit und Verantwortung. Vielleicht hast du in vergangenen Leben Exzesse gelebt - nun geht es um Maß und Ausgewogenheit. Du musst lernen, dass wahre Freiheit durch Selbstdisziplin entsteht, nicht durch Zügellosigkeit. Finde die Mitte zwischen Spaß und Pflicht. Dies ist deine Chance, echte Reife zu entwickeln!';
      case 16:
        return '$name, die Karma-Zahl 16 ist ein Ruf zur Ego-Transformation. Möglicherweise war in früheren Leben dein Ego zu groß - nun musst du lernen, Demut zu entwickeln. Das Leben wird dein Ego immer wieder herausfordern, bis du lernst loszulassen. Jede Demütigung ist eine Chance zur spirituellen Erhebung. Wenn du dich dem hingibst, wirst du wahre Weisheit finden!';
      case 19:
        return '$name, mit der Karma-Zahl 19 lernst du Unabhängigkeit und Selbstständigkeit. Vielleicht warst du in vergangenen Leben zu abhängig von anderen - nun musst du lernen, auf eigenen Füßen zu stehen. Das Leben fordert dich auf, deine eigene Kraft zu entdecken. Lehne dich nicht an andere an - finde deine eigene Stärke. Dies ist deine Chance, wahre Souveränität zu entwickeln!';
      default:
        return '$name, deine Karma-Zahl $number zeigt eine wichtige Lebenslektion, die du meistern darfst.';
    }
  }

  Widget _buildEmptyCard(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.3), size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFFCE93D8),
        letterSpacing: 1.5,
      ),
    );
  }

    // switch (number) {
      // case 11:
        // return 'Der Erleuchtete - Intuition, Inspiration, spirituelle Einsicht';
      // case 22:
        // return 'Der Meisterbaumeister - Manifestation großer Visionen';
      // case 33:
        // return 'Der Meisterlehrer - Bedingungslose Liebe und Dienst';
      // default:
        // return 'Spirituelle Meisterzahl';
    // }
  // }

  String _getKarmaNumberMeaning(int number) {
    switch (number) {
      case 13:
        return 'Transformation durch Disziplin und Fokus';
      case 14:
        return 'Balance zwischen Freiheit und Verantwortung';
      case 16:
        return 'Ego-Transformation und spirituelles Erwachen';
      case 19:
        return 'Unabhängigkeit und Selbstständigkeit lernen';
      default:
        return 'Karmische Lernaufgabe';
    }
  }

  // 🆕 JAHRESPROGNOSE-TIMELINE
  Widget _buildYearForecastTimeline() {
    final currentYear = DateTime.now().year;
    final currentMonth = DateTime.now().month;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade900, Colors.purple.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.timeline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'JAHRESPROGNOSE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Deine 12-Monats-Timeline $currentYear',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Timeline für 12 Monate
          ...List.generate(12, (index) {
            final month = index + 1;
            final monthName = _getMonthName(month);
            final personalMonth = _calculatePersonalMonthForYear(month);
            final isCurrentMonth = month == currentMonth;
            final isPastMonth = month < currentMonth;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildMonthTimelineItem(
                monthName,
                personalMonth,
                isCurrentMonth,
                isPastMonth,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMonthTimelineItem(
    String monthName,
    int personalMonth,
    bool isCurrentMonth,
    bool isPastMonth,
  ) {
    final monthData = _getMonthThemeAndEnergy(personalMonth);
    final Color backgroundColor = isCurrentMonth
        ? Colors.amber.shade700
        : isPastMonth
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.15);
    final Color textColor = isCurrentMonth ? Colors.black : Colors.white;
    final Color accentColor = _getNumberColor(personalMonth);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentMonth
              ? Colors.amber
              : accentColor.withValues(alpha: 0.3),
          width: isCurrentMonth ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Timeline-Indikator
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$personalMonth',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (isCurrentMonth)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.arrow_upward,
                    color: textColor,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Monats-Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      monthName.toUpperCase(),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    if (isCurrentMonth) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'JETZT',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  monthData['theme']!,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  monthData['energy']!,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          
          // Energie-Level-Indikator
          _buildEnergyLevelIndicator(personalMonth, textColor),
        ],
      ),
    );
  }

  Widget _buildEnergyLevelIndicator(int personalMonth, Color textColor) {
    final energyLevel = _getEnergyLevel(personalMonth);
    final bars = (energyLevel * 5).round();
    
    return Column(
      children: [
        Row(
          children: List.generate(5, (index) {
            return Container(
              margin: const EdgeInsets.only(left: 2),
              width: 4,
              height: 20 - (index * 3),
              decoration: BoxDecoration(
                color: index < bars
                    ? textColor.withValues(alpha: 0.8)
                    : textColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          '${(energyLevel * 100).toInt()}%',
          style: TextStyle(
            color: textColor.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  int _calculatePersonalMonthForYear(int month) {
    if (_personalYear == null) return 1;
    final sum = _personalYear! + month;
    return _reduceToSingleDigit(sum);
  }

  int _reduceToSingleDigit(int number) {
    while (number > 9) {
      number = number.toString().split('').map(int.parse).reduce((a, b) => a + b);
    }
    return number;
  }

  Map<String, String> _getMonthThemeAndEnergy(int personalMonth) {
    switch (personalMonth) {
      case 1:
        return {
          'theme': 'Neubeginn & Initiative',
          'energy': 'Zeit für neue Projekte und mutige Schritte',
        };
      case 2:
        return {
          'theme': 'Kooperation & Balance',
          'energy': 'Beziehungen stärken, Geduld üben',
        };
      case 3:
        return {
          'theme': 'Kreativität & Ausdruck',
          'energy': 'Selbstausdruck, soziale Aktivitäten',
        };
      case 4:
        return {
          'theme': 'Stabilität & Struktur',
          'energy': 'Fundamente schaffen, organisieren',
        };
      case 5:
        return {
          'theme': 'Veränderung & Freiheit',
          'energy': 'Flexibilität, neue Erfahrungen',
        };
      case 6:
        return {
          'theme': 'Liebe & Verantwortung',
          'energy': 'Familie, Zuhause, Harmonie',
        };
      case 7:
        return {
          'theme': 'Innenschau & Weisheit',
          'energy': 'Meditation, spirituelles Wachstum',
        };
      case 8:
        return {
          'theme': 'Erfolg & Manifestation',
          'energy': 'Karriere, finanzielle Chancen',
        };
      case 9:
        return {
          'theme': 'Vollendung & Loslassen',
          'energy': 'Abschlüsse, Transformation',
        };
      case 11:
        return {
          'theme': 'Erleuchtung & Intuition',
          'energy': 'Spirituelle Durchbrüche, Inspiration',
        };
      case 22:
        return {
          'theme': 'Meisterschaft & Vision',
          'energy': 'Große Projekte manifestieren',
        };
      default:
        return {
          'theme': 'Persönliches Wachstum',
          'energy': 'Entfalte dein Potenzial',
        };
    }
  }

  double _getEnergyLevel(int personalMonth) {
    switch (personalMonth) {
      case 1:
        return 0.9; // Hohe Energie für Neubeginn
      case 2:
        return 0.5; // Mittlere Energie für Balance
      case 3:
        return 0.8; // Hohe kreative Energie
      case 4:
        return 0.6; // Solide, stabile Energie
      case 5:
        return 1.0; // Maximale Energie für Veränderung
      case 6:
        return 0.7; // Harmonische Energie
      case 7:
        return 0.4; // Niedrige, introspektive Energie
      case 8:
        return 0.95; // Sehr hohe Manifestationsenergie
      case 9:
        return 0.65; // Abschluss-Energie
      case 11:
        return 0.85; // Hohe spirituelle Energie
      case 22:
        return 0.9; // Sehr hohe Meisterenergie
      default:
        return 0.6;
    }
  }

  Color _getNumberColor(int number) {
    switch (number) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return Colors.green;
      case 5:
        return Colors.blue;
      case 6:
        return Colors.indigo;
      case 7:
        return Colors.purple;
      case 8:
        return Colors.pink;
      case 9:
        return Colors.teal;
      case 11:
        return Colors.cyan;
      case 22:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
  // 🆕 PARTNER-KOMPATIBILITÄTS-TAB
  Widget _buildPartnerCompatibilityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('PARTNER-KOMPATIBILITÄT'),
          const SizedBox(height: 16),
          
          // Partner auswählen/laden Button
          if (_partnerProfile == null)
            _buildLoadPartnerButton()
          else
            _buildPartnerInfoCard(),
          
          const SizedBox(height: 24),
          
          // Kompatibilitäts-Score
          if (_compatibilityScore != null) ...[
            _buildCompatibilityScoreCard(),
            const SizedBox(height: 24),
            
            // Harmonische Aspekte
            _buildSectionTitle('HARMONISCHE ASPEKTE ✨'),
            const SizedBox(height: 12),
            if (_harmonicAspects != null)
              ..._harmonicAspects!.map((aspect) => _buildAspectCard(aspect, true)),
            
            const SizedBox(height: 24),
            
            // Herausfordernde Aspekte
            _buildSectionTitle('HERAUSFORDERNDE ASPEKTE ⚠️'),
            const SizedBox(height: 12),
            if (_challengingAspects != null)
              ..._challengingAspects!.map((aspect) => _buildAspectCard(aspect, false)),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadPartnerButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.favorite, size: 48, color: Color(0xFFE91E63)),
          const SizedBox(height: 16),
          Text(
            'Partner-Profil laden',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lade ein zweites Profil, um die numerologische Kompatibilität zu berechnen',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadPartnerProfile,
            icon: Icon(Icons.person_add),
            label: Text('Partner laden'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE91E63),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.favorite, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_partnerProfile!.firstName} ${_partnerProfile!.lastName}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Lebenszahl: $_partnerLifePath',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _clearPartnerProfile,
            icon: Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityScoreCard() {
    final score = _compatibilityScore ?? 0;
    final percentage = (score / 10 * 100).round();
    final scoreColor = score >= 8 ? Colors.green : score >= 6 ? Colors.orange : Colors.red;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor.withValues(alpha: 0.3), scoreColor.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scoreColor, width: 2),
      ),
      child: Column(
        children: [
          Text(
            'KOMPATIBILITÄTS-SCORE',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16, left: 4),
                child: Text(
                  '/10',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white60,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$percentage% Kompatibilität',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _getCompatibilityDescription(score),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAspectCard(String aspect, bool isHarmonic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHarmonic 
            ? Colors.green.withValues(alpha: 0.1) 
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHarmonic ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isHarmonic ? Icons.check_circle : Icons.warning,
            color: isHarmonic ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              aspect,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Partner-Profil Funktionen
  void _loadPartnerProfile() {
    // Zeige Dialog für Partner-Eingabe
    showDialog(
      context: context,
      builder: (context) => _PartnerInputDialog(
        onPartnerLoaded: (profile) {
          setState(() {
            _partnerProfile = profile;
            _calculatePartnerCompatibility();
          });
        },
      ),
    );
  }

  void _clearPartnerProfile() {
    setState(() {
      _partnerProfile = null;
      _partnerLifePath = null;
      _partnerSoul = null;
      _partnerExpression = null;
      _compatibilityScore = null;
      _harmonicAspects = null;
      _challengingAspects = null;
    });
  }

  void _calculatePartnerCompatibility() {
    if (_partnerProfile == null || _profile == null) return;

    // Partner-Zahlen berechnen
    _partnerLifePath = NumerologyEngine.calculateLifePath(_partnerProfile!.birthDate);
    _partnerSoul = NumerologyEngine.calculateSoulNumber(
      _partnerProfile!.firstName,
      _partnerProfile!.lastName,
    );
    _partnerExpression = NumerologyEngine.calculateExpressionNumber(
      _partnerProfile!.firstName,
      _partnerProfile!.lastName,
    );

    // Kompatibilität berechnen
    int score = 0;
    _harmonicAspects = [];
    _challengingAspects = [];

    // Lebenszahl-Kompatibilität (40% Gewichtung)
    final lifePathDiff = (_lifePath! - _partnerLifePath!).abs();
    if (lifePathDiff == 0) {
      score += 4;
      _harmonicAspects!.add('Identische Lebenszahlen (${{_lifePath}}) - Tiefes gegenseitiges Verständnis');
    } else if (lifePathDiff <= 2) {
      score += 3;
      _harmonicAspects!.add('Ähnliche Lebenswege ($_lifePath & $_partnerLifePath) - Gute Harmonie');
    } else if (lifePathDiff >= 5) {
      score += 1;
      _challengingAspects!.add('Unterschiedliche Lebenszahlen - Ergänzung durch Gegensätze');
    } else {
      score += 2;
    }

    // Seelenzahl-Kompatibilität (30% Gewichtung)
    final soulDiff = (_soul! - _partnerSoul!).abs();
    if (soulDiff == 0) {
      score += 3;
      _harmonicAspects!.add('Gleiche Seelenzahlen - Emotionale Verbindung');
    } else if (soulDiff <= 2) {
      score += 2;
      _harmonicAspects!.add('Harmonische Seelenzahlen - Emotionales Verständnis');
    } else {
      score += 1;
      _challengingAspects!.add('Unterschiedliche emotionale Bedürfnisse - Kommunikation wichtig');
    }

    // Ausdruckszahl-Kompatibilität (30% Gewichtung)
    final expressionDiff = (_expression! - _partnerExpression!).abs();
    if (expressionDiff == 0) {
      score += 3;
      _harmonicAspects!.add('Identische Ausdruckszahlen - Gleiche Kommunikationsweise');
    } else if (expressionDiff <= 2) {
      score += 2;
      _harmonicAspects!.add('Ähnlicher Ausdruck - Gute Verständigung');
    } else {
      score += 1;
      _challengingAspects!.add('Unterschiedliche Kommunikationsstile - Toleranz fördern');
    }

    setState(() {
      _compatibilityScore = score;
    });
  }

  String _getCompatibilityDescription(int score) {
    if (score >= 9) return 'Außergewöhnliche Harmonie - Seelenverwandt';
    if (score >= 8) return 'Sehr hohe Kompatibilität - Starke Verbindung';
    if (score >= 7) return 'Gute Kompatibilität - Harmonische Beziehung';
    if (score >= 6) return 'Ausgeglichene Beziehung - Arbeit lohnt sich';
    if (score >= 5) return 'Herausfordernde Dynamik - Wachstumspotenzial';
    return 'Gegensätze ziehen sich an - Viel Geduld nötig';
  }
  
  /// 🆕 Helper-Methoden für ausführliche Beschreibungen
  String _getLifePathDescription(int number) {
    final descriptions = {
      1: 'Du bist ein geborener Pionier und Anführer. Dein Weg ist es, Unabhängigkeit zu entwickeln, neue Wege zu beschreiten und andere durch dein Beispiel zu inspirieren.\n\nDie Lebenszahl 1 repräsentiert den Anfang, die Initiative und die Kraft der Manifestation. Menschen mit dieser Zahl sind natürliche Führungspersönlichkeiten, die den Mut haben, alleine voranzugehen. Deine Aufgabe ist es, Selbstvertrauen zu entwickeln und deine einzigartige Vision in die Welt zu bringen.\n\nHerausforderungen: Übermäßiger Stolz, Ungeduld, Schwierigkeit beim Delegieren.\nGeschenke: Mut, Originalität, Entschlossenheit, Pioniergeist.',
      2: 'Deine Seele sucht nach Harmonie und Partnerschaft. Du bist der Diplomat, der Vermittler, der Brückenbauer zwischen Gegensätzen.\n\nMit der Lebenszahl 2 bist du hochsensibel und intuitiv. Du spürst die Energien anderer Menschen und kannst Konflikte mit Geduld und Einfühlungsvermögen lösen. Deine Mission ist es, Frieden zu schaffen und die Kraft der Kooperation zu demonstrieren.\n\nHerausforderungen: Überempfindlichkeit, Selbstzweifel, zu sehr auf andere fokussiert.\nGeschenke: Diplomatie, Intuition, Teamfähigkeit, Friedfertigkeit.',
      3: 'Kreativität ist deine Essenz. Du bist hier, um Freude zu verbreiten, dich auszudrücken und andere durch deine Kunst zu inspirieren.\n\nDie Zahl 3 steht für Selbstausdruck, Kommunikation und kreative Entfaltung. Du bringst Licht und Freude in die Welt. Dein authentischer Ausdruck inspiriert andere, ihre eigene Stimme zu finden.\n\nHerausforderungen: Oberflächlichkeit, Verzettelung, Schwierigkeiten beim Fokussieren.\nGeschenke: Kreativität, Optimismus, Charisma, Kommunikationsstärke.',
      4: 'Stabilität und Ordnung sind deine Gaben. Du bist der Baumeister, der feste Fundamente für eine bessere Zukunft schafft.\n\nMit der Lebenszahl 4 bist du praktisch veranlagt und bodenständig. Du erschaffst dauerhafte Strukturen durch harte Arbeit und Disziplin. Deine Zuverlässigkeit macht dich zum Fels in der Brandung für andere.\n\nHerausforderungen: Starrheit, Workaholic-Tendenz, Widerstand gegen Veränderung.\nGeschenke: Verlässlichkeit, Ausdauer, Organisation, Pragmatismus.',
      5: 'Freiheit ist dein höchstes Gut. Deine Seele sehnt sich nach Abenteuer, Veränderung und der Erfahrung aller Facetten des Lebens.\n\nDie 5 repräsentiert Freiheit, Anpassungsfähigkeit und Abenteuer. Du bist hier, um alle Aspekte des Lebens zu erfahren und andere zu ermutigen, ihre Komfortzonen zu verlassen. Deine Flexibilität ist deine Superkraft.\n\nHerausforderungen: Rastlosigkeit, Impulsivität, Schwierigkeiten bei Verpflichtungen.\nGeschenke: Anpassungsfähigkeit, Abenteuerlust, Kommunikation, Vielseitigkeit.',
      6: 'Du bist der Nährende, der Heiler, der Beschützer. Verantwortung für andere zu übernehmen ist nicht Last, sondern Berufung.\n\nMit der Lebenszahl 6 hast du ein natürliches Talent für Fürsorge und Heilung. Familie und Gemeinschaft stehen im Zentrum deines Lebens. Du schaffst Harmonie durch bedingungslose Liebe und Dienst.\n\nHerausforderungen: Über-Verantwortlichkeit, Perfektionismus, Aufopferung.\nGeschenke: Mitgefühl, Verantwortungsbewusstsein, Harmonie, Heilfähigkeit.',
      7: 'Spirituelle Wahrheit ist dein Ziel. Du bist der Mystiker, der Philosoph, der Sucher nach tieferer Bedeutung.\n\nDie 7 ist die Zahl der Spiritualität und inneren Weisheit. Du suchst nach den verborgenen Wahrheiten des Lebens. Deine analytischen Fähigkeiten und deine Intuition führen dich zu tiefen Einsichten.\n\nHerausforderungen: Isolation, Überanalyse, Schwierigkeiten mit Emotionen.\nGeschenke: Weisheit, Intuition, analytischer Verstand, spirituelle Tiefe.',
      8: 'Manifestation und materieller Erfolg sind deine Domäne. Du verstehst die Gesetze von Ursache und Wirkung auf materieller Ebene.\n\nMit der Lebenszahl 8 hast du die Fähigkeit, große Dinge zu manifestieren. Du verbindest spirituelle Prinzipien mit materiellem Erfolg. Macht und Autorität fließen dir natürlich zu.\n\nHerausforderungen: Materialismus, Kontrollsucht, Machtmissbrauch.\nGeschenke: Manifestationskraft, Führungsqualität, finanzielles Geschick, Durchsetzungsvermögen.',
      9: 'Vollendung und Humanität definieren deinen Weg. Du bist hier, um zu heilen, zu dienen und die Welt zu einem besseren Ort zu machen.\n\nDie 9 ist die Zahl der Vollendung und des universellen Bewusstseins. Du fühlst mit der gesamten Menschheit. Dein Mitgefühl und deine Weisheit dienen dem höchsten Wohl aller.\n\nHerausforderungen: Über-Idealismus, Schwierigkeit loszulassen, Märtyrertum.\nGeschenke: Weisheit, Mitgefühl, Humanität, Transformation.',
    };
    return descriptions[number % 10] ?? 'Deine Lebenszahl $number trägt einzigartige Qualitäten. Erforshe ihre tiefe Bedeutung für dein Leben.';
  }

  String _getSoulDescription(int number) {
    return 'Deine Seelenzahl $number offenbart deine innersten Wünsche und was dein Herz wirklich begehrt.\n\nIm Kern deines Wesens sehnst du dich nach ${_getCycleTheme(number % 10)}. Diese Sehnsüchte sind authentische Impulse deiner Seele. Sie zu ignorieren führt zu Unzufriedenheit, sie zu ehren führt zu tiefer Erfüllung. Deine Seelenzahl erinnert dich daran, was wirklich wichtig ist im Leben.\n\nLebe authentisch aus deinem Herzen heraus, und du wirst wahre Erfüllung finden.';
  }

  String _getExpressionDescription(int number) {
    return 'Deine Ausdruckszahl $number zeigt deine natürlichen Talente und wie du dich in der Welt ausdrückst.\n\nDeine natürlichen Fähigkeiten liegen in ${_getCycleTheme(number % 10)}. Diese Talente sind nicht nur Geschenke, sondern auch Verantwortung. Je mehr du sie entwickelst und einsetzt, desto mehr erfüllst du deine Lebensaufgabe.\n\nDeine Schicksalszahl ist der Schlüssel zu deinem Erfolg und deiner Erfüllung. Kultiviere diese Gaben bewusst.';
  }

  String _getPersonalityDescription(int number) {
    return 'Deine Persönlichkeitszahl $number zeigt, wie andere dich wahrnehmen.\n\nMenschen nehmen dich als jemanden wahr, der ${_getCycleTheme(number % 10)} verkörpert. Dies ist deine natürliche Ausstrahlung, die Art, wie deine Energie in die Welt fließt.\n\nDer Unterschied zwischen deiner Persönlichkeitszahl und Seelenzahl zeigt, wie sehr dein äußeres Bild mit deinem inneren Wesen übereinstimmt. Je größer die Harmonie, desto authentischer lebst du.';
  }

  String _getCycleTheme(int number) {
    switch (number) {
      case 1: return 'Unabhängigkeit, Führung, Neuanfang';
      case 2: return 'Partnerschaft, Diplomatie, Balance';
      case 3: return 'Kreativität, Ausdruck, Freude';
      case 4: return 'Stabilität, Ordnung, Arbeit';
      case 5: return 'Freiheit, Veränderung, Abenteuer';
      case 6: return 'Verantwortung, Familie, Dienst';
      case 7: return 'Spiritualität, Analyse, Weisheit';
      case 8: return 'Macht, Erfolg, Manifestation';
      case 9: return 'Vollendung, Humanität, Loslassen';
      default: return 'besondere Qualitäten';
    }
  }
  
  // ════════════════════════════════════════════════════════════════
  // 🚀 PERSONAL YEAR JOURNEY MAP METHODS (v44.1.0)
  // ════════════════════════════════════════════════════════════════
  
  /// Personal Year Journey von Hive laden
  Future<void> _loadPersonalYearJourney() async {
    if (_profile == null) return;
    
    setState(() => _isLoadingJourney = true);
    
    try {
      final now = DateTime.now();
      final currentYear = now.year;
      
      // Lade Year Journey aus Hive
      final journey = StorageService().getPersonalYearJourney(currentYear);
      
      if (journey != null) {
        setState(() => _currentYearJourney = journey);
      } else {
        // Erstelle neue Journey für dieses Jahr
        await _createPersonalYearJourney();
      }
      
      // Lade Journal Entries
      final entries = StorageService().getNumerologyJournalEntries();
      setState(() => _journalEntries = entries);
      
      // Lade Milestones
      final milestones = StorageService().getNumerologyMilestones();
      setState(() => _milestones = milestones);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingJourney = false);
    }
  }
  
  /// Neue Personal Year Journey erstellen
  Future<void> _createPersonalYearJourney() async {
    if (_profile == null || _personalYear == null) return;
    
    final now = DateTime.now();
    final journey = {
      'year': now.year,
      'personalYear': _personalYear!,
      'createdAt': now.toIso8601String(),
      'monthlyEnergies': _calculateMonthlyEnergies(),
    };
    
    await StorageService().savePersonalYearJourney(journey);
    setState(() => _currentYearJourney = journey);
  }
  
  /// Monatliche Energien berechnen
  List<Map<String, dynamic>> _calculateMonthlyEnergies() {
    if (_profile == null) return [];
    
    final now = DateTime.now();
    final List<Map<String, dynamic>> months = [];
    
    for (int month = 1; month <= 12; month++) {
      final date = DateTime(now.year, month, 1);
      final monthEnergy = NumerologyEngine.calculatePersonalMonth(_profile!.birthDate, date);
      
      months.add({
        'month': month,
        'monthName': _getMonthName(month),
        'energy': monthEnergy,
        'theme': _getMonthTheme(monthEnergy),
        'isCurrent': month == now.month,
      });
    }
    
    return months;
  }
  
  /// Monatsname zurückgeben
  String _getMonthName(int month) {
    const months = [
      'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'
    ];
    return months[month - 1];
  }
  
  /// Monats-Thema basierend auf Energie-Nummer
  String _getMonthTheme(int energy) {
    const themes = {
      1: 'Neubeginn',
      2: 'Partnerschaft',
      3: 'Kreativität',
      4: 'Stabilität',
      5: 'Veränderung',
      6: 'Harmonie',
      7: 'Spiritualität',
      8: 'Erfolg',
      9: 'Vollendung',
      11: 'Erleuchtung',
      22: 'Meisterschaft',
    };
    return themes[energy] ?? 'Transformation';
  }
  
  /// Personal Year Journey Tab bauen
  Widget _buildPersonalYearJourneyTab() {
    if (_isLoadingJourney) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFD700)),
      );
    }
    
    if (_currentYearJourney == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_month, size: 64, color: Color(0xFFFFD700)),
            const SizedBox(height: 16),
            const Text(
              'Personal Year Journey wird geladen...',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPersonalYearJourney,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
              ),
              child: const Text('Journey laden'),
            ),
          ],
        ),
      );
    }
    
    final year = _currentYearJourney!['year'] as int;
    final personalYear = _currentYearJourney!['personalYear'] as int;
    final monthlyEnergies = _currentYearJourney!['monthlyEnergies'] as List<dynamic>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFD700).withValues(alpha: 0.3),
                  const Color(0xFF1E1E1E),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFFFFD700), size: 32),
                    const SizedBox(width: 12),
                    Text(
                      'DEINE REISE $year',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Personal Year: $personalYear',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getYearThemeDescription(personalYear),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Monatliche Energien
          _buildSectionTitle('MONATLICHE ENERGIEN'),
          const SizedBox(height: 16),
          
          ...monthlyEnergies.map((monthData) => _buildMonthEnergyCard(monthData)),
          
          const SizedBox(height: 24),
          
          // Meilensteine
          _buildSectionTitle('MEILENSTEINE'),
          const SizedBox(height: 16),
          
          if (_milestones.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Noch keine Meilensteine erfasst',
                  style: TextStyle(color: Colors.white60),
                ),
              ),
            )
          else
            ..._milestones.map((milestone) => _buildMilestoneCard(milestone)),
          
          const SizedBox(height: 24),
          
          // Journal Einträge
          _buildSectionTitle('JOURNAL'),
          const SizedBox(height: 16),
          
          if (_journalEntries.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Noch keine Journal-Einträge',
                  style: TextStyle(color: Colors.white60),
                ),
              ),
            )
          else
            ..._journalEntries.take(5).map((entry) => _buildJournalEntryCard(entry)),
          
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddMilestoneDialog,
                  icon: const Icon(Icons.flag),
                  label: const Text('Meilenstein'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddJournalDialog,
                  icon: const Icon(Icons.edit),
                  label: const Text('Journal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C27B0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Year Theme Description
  String _getYearThemeDescription(int year) {
    const descriptions = {
      1: 'Jahr des Neuanfangs - Zeit für neue Projekte und Selbstentwicklung',
      2: 'Jahr der Partnerschaft - Fokus auf Beziehungen und Zusammenarbeit',
      3: 'Jahr der Kreativität - Selbstausdruck und Freude stehen im Mittelpunkt',
      4: 'Jahr der Stabilität - Fundamente bauen und organisieren',
      5: 'Jahr der Veränderung - Freiheit, Reisen und Abenteuer',
      6: 'Jahr der Harmonie - Familie, Zuhause und Verantwortung',
      7: 'Jahr der Spiritualität - Innere Weisheit und Reflexion',
      8: 'Jahr des Erfolgs - Materieller Wohlstand und Leistung',
      9: 'Jahr der Vollendung - Abschluss und Transformation',
      11: 'Jahr der Erleuchtung - Spirituelle Meisterschaft',
      22: 'Jahr der Meisterschaft - Große Manifestationen',
    };
    return descriptions[year] ?? 'Jahr der Transformation und des Wachstums';
  }
  
  /// Monats-Energie Card
  Widget _buildMonthEnergyCard(Map<String, dynamic> monthData) {
    final month = monthData['month'] as int;
    final monthName = monthData['monthName'] as String;
    final energy = monthData['energy'] as int;
    final theme = monthData['theme'] as String;
    final isCurrent = monthData['isCurrent'] as bool;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isCurrent
            ? LinearGradient(
                colors: [
                  const Color(0xFFFFD700).withValues(alpha: 0.3),
                  const Color(0xFF2A2A2A),
                ],
              )
            : null,
        color: isCurrent ? null : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: isCurrent
            ? Border.all(color: const Color(0xFFFFD700), width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Month Number
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _getEnergyColor(energy),
                  _getEnergyColor(energy).withValues(alpha: 0.5),
                ],
              ),
            ),
            child: Center(
              child: Text(
                month.toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Month Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      monthName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'AKTUELL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$theme • Energie $energy',
                  style: TextStyle(
                    fontSize: 14,
                    color: _getEnergyColor(energy).withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          
          // Energy Number Badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getEnergyColor(energy).withValues(alpha: 0.3),
              border: Border.all(
                color: _getEnergyColor(energy),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                energy.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getEnergyColor(energy),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Energie-Farbe basierend auf Nummer
  Color _getEnergyColor(int energy) {
    const colors = {
      1: Color(0xFFE74C3C), // Rot
      2: Color(0xFFE67E22), // Orange
      3: Color(0xFFF39C12), // Gelb
      4: Color(0xFF27AE60), // Grün
      5: Color(0xFF3498DB), // Blau
      6: Color(0xFF9B59B6), // Lila
      7: Color(0xFF8E44AD), // Dunkel-Lila
      8: Color(0xFFFFD700), // Gold
      9: Color(0xFFE91E63), // Pink
      11: Color(0xFF00BCD4), // Cyan
      22: Color(0xFFFF5722), // Deep Orange
    };
    return colors[energy] ?? const Color(0xFFFFD700);
  }
  
  /// Meilenstein Card
  Widget _buildMilestoneCard(Map<String, dynamic> milestone) {
    final title = milestone['title'] as String;
    final date = milestone['date'] as String;
    final description = milestone['description'] as String?;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag, color: Color(0xFFFFD700), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFFFD700),
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Journal Entry Card
  Widget _buildJournalEntryCard(Map<String, dynamic> entry) {
    final timestamp = entry['timestamp'] as String;
    final content = entry['content'] as String;
    final mood = entry['mood'] as String?;
    
    final date = DateTime.parse(timestamp);
    final dateStr = '${date.day}.${date.month}.${date.year}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit, color: Color(0xFF9C27B0), size: 20),
              const SizedBox(width: 8),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9C27B0),
                ),
              ),
              if (mood != null) ...[
                const Spacer(),
                Text(
                  _getMoodEmoji(mood),
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  /// Mood Emoji
  String _getMoodEmoji(String mood) {
    const emojis = {
      'happy': '😊',
      'neutral': '😐',
      'sad': '😢',
      'excited': '🤩',
      'anxious': '😰',
      'peaceful': '😌',
    };
    return emojis[mood] ?? '😐';
  }
  
  /// Show Add Milestone Dialog
  void _showAddMilestoneDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Meilenstein hinzufügen',
          style: TextStyle(color: Color(0xFFFFD700)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Titel',
                labelStyle: TextStyle(color: Colors.white60),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFFD700)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Beschreibung (optional)',
                labelStyle: TextStyle(color: Colors.white60),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFFD700)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;
              
              final milestone = {
                'id': DateTime.now().millisecondsSinceEpoch.toString(),
                'title': titleController.text.trim(),
                'description': descriptionController.text.trim().isEmpty 
                    ? null 
                    : descriptionController.text.trim(),
                'date': DateTime.now().toIso8601String(),
              };
              
              await StorageService().saveNumerologyMilestone(milestone);
              await _loadPersonalYearJourney();
              
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
  
  /// Show Add Journal Dialog
  void _showAddJournalDialog() {
    final contentController = TextEditingController();
    String selectedMood = 'neutral';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Journal-Eintrag',
            style: TextStyle(color: Color(0xFF9C27B0)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mood Selector
              const Text(
                'Stimmung:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['happy', 'neutral', 'sad', 'excited', 'anxious', 'peaceful']
                    .map((mood) => GestureDetector(
                          onTap: () => setDialogState(() => selectedMood = mood),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: selectedMood == mood
                                  ? const Color(0xFF9C27B0).withValues(alpha: 0.3)
                                  : Colors.transparent,
                              border: Border.all(
                                color: selectedMood == mood
                                    ? const Color(0xFF9C27B0)
                                    : Colors.white24,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getMoodEmoji(mood),
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                style: const TextStyle(color: Colors.white),
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Was möchtest du festhalten?',
                  labelStyle: TextStyle(color: Colors.white60),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF9C27B0)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (contentController.text.trim().isEmpty) return;
                
                final entry = {
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'content': contentController.text.trim(),
                  'mood': selectedMood,
                  'timestamp': DateTime.now().toIso8601String(),
                };
                
                await StorageService().saveNumerologyJournalEntry(entry);
                await _loadPersonalYearJourney();
                
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                foregroundColor: Colors.white,
              ),
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }
  
}

// 🆕 PARTNER-EINGABE-DIALOG
class _PartnerInputDialog extends StatefulWidget {
  final Function(EnergieProfile) onPartnerLoaded;

  const _PartnerInputDialog({required this.onPartnerLoaded});

  @override
  State<_PartnerInputDialog> createState() => _PartnerInputDialogState();
}

class _PartnerInputDialogState extends State<_PartnerInputDialog> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  DateTime _birthDate = DateTime.now();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: Text(
        'Partner-Profil eingeben',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _firstNameController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Vorname',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE91E63)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lastNameController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nachname',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE91E63)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.cake, color: Color(0xFFE91E63)),
              title: Text(
                'Geburtsdatum',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              subtitle: Text(
                '${_birthDate.day}.${_birthDate.month}.${_birthDate.year}',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              trailing: IconButton(
                icon: Icon(Icons.calendar_today, color: Colors.white),
                onPressed: _selectDate,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _savePartner,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFE91E63),
          ),
          child: Text('Laden'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Color(0xFFE91E63),
              surface: Color(0xFF1A1A2E),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  void _savePartner() {
    if (_firstNameController.text.trim().isEmpty || 
        _lastNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bitte alle Felder ausfüllen'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final profile = EnergieProfile(
      username: 'partner', // Temporärer Username für Partner
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      birthDate: _birthDate,
      birthPlace: 'Unbekannt', // Temporär, da nicht benötigt für Numerologie
      birthTime: null,
    );

    widget.onPartnerLoaded(profile);
    Navigator.pop(context);
  }
}

