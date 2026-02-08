/// 15 Neue Spirit-Tool Screens - Vollständig implementiert
/// Weltenbibliothek v61 - mit Meditation-Stats + Moon Journal
library;

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:weltenbibliothek/services/storage_service.dart';
import 'package:weltenbibliothek/services/achievement_service.dart';
import 'package:weltenbibliothek/models/app_data.dart';
import 'package:weltenbibliothek/screens/energie/moon_journal_screen.dart';

// ═══════════════════════════════════════════════════════════
// 1. 🌙 MONDPHASEN-TRACKER SCREEN
// ═══════════════════════════════════════════════════════════

class MoonPhaseTrackerScreen extends StatefulWidget {
  const MoonPhaseTrackerScreen({super.key});

  @override
  State<MoonPhaseTrackerScreen> createState() => _MoonPhaseTrackerScreenState();
}

class _MoonPhaseTrackerScreenState extends State<MoonPhaseTrackerScreen> {
  String? _selectedPhase;
  
  @override
  Widget build(BuildContext context) {
    final moonPhase = _getCurrentMoonPhase();
    
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text('🌙 Mondphasen-Tracker'),
        backgroundColor: Color(0xFF1A237E),
        actions: [
          // 🆕 "30-Tage Kalender" Button
          IconButton(
            icon: Icon(Icons.calendar_month),
            tooltip: '30-Tage Kalender',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MoonCalendarScreen(),
                ),
              );
            },
          ),
          // 🆕 "Mein Mondtagebuch" Button
          IconButton(
            icon: Icon(Icons.book),
            tooltip: 'Mein Mondtagebuch',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MoonJournalScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A237E), Color(0xFF000000)],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // Aktuelle Mondphase
            _buildCurrentMoonCard(moonPhase),
            SizedBox(height: 24),
            
            // Info Card
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Tippe auf eine Mondphase für detaillierte Rituale und Bedeutungen',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // 8 Mondphasen
            Text(
              'Die 8 Mondphasen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            
            ..._getAllMoonPhases().map((phase) => _buildPhaseCard(phase)),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentMoonCard(Map<String, dynamic> phase) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF283593), Color(0xFF1A237E)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF283593).withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Aktuelle Mondphase',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 16),
          
          // Mond-Symbol
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Text(
                _getMoonEmoji(phase['phase']),
                style: TextStyle(fontSize: 60),
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          Text(
            phase['name'],
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          SizedBox(height: 12),
          
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              phase['ritual'],
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

  Widget _buildPhaseCard(Map<String, dynamic> phase) {
    final isSelected = _selectedPhase == phase['name'];
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPhase = phase['name'];
        });
        _showPhaseDetails(phase);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.indigo.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? Colors.indigoAccent 
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getMoonEmoji(phase['phase']),
                  style: TextStyle(fontSize: 32),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phase['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    phase['ritual'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
  
  void _showPhaseDetails(Map<String, dynamic> phase) {
    // Extended rituals and meanings for each phase
    final Map<int, Map<String, String>> phaseDetails = {
      0: {
        'energy': 'Neue Anfänge, Intention setzen, Manifestation',
        'ritual': 'Schreibe deine Wünsche auf ein Papier. Visualisiere sie bei Kerzenlicht. Verbrenne das Papier als Symbol der Freigabe an das Universum.',
        'meditation': 'Fokussiere auf Stille und innere Leere. Was möchtest du in dein Leben ziehen?',
        'element': 'Luft',
      },
      1: {
        'energy': 'Wachstum, Aufbau, Energie sammeln',
        'ritual': 'Pflanze Samen (real oder metaphorisch). Bewässere deine Träume mit Taten.',
        'meditation': 'Visualisiere wie deine Ziele wachsen und Form annehmen.',
        'element': 'Feuer',
      },
      2: {
        'energy': 'Entscheidungen, Aktion, Herausforderungen meistern',
        'ritual': 'Treffe eine wichtige Entscheidung. Schreibe Pro/Contra-Liste.',
        'meditation': 'Frage dich: Was braucht jetzt meine Aufmerksamkeit?',
        'element': 'Feuer',
      },
      3: {
        'energy': 'Verfeinern, Anpassen, letzte Schritte vor dem Höhepunkt',
        'ritual': 'Überprüfe deine Fortschritte. Korrigiere den Kurs wenn nötig.',
        'meditation': 'Sei geduldig. Der Höhepunkt naht.',
        'element': 'Wasser',
      },
      4: {
        'energy': 'Höhepunkt der Kraft, Manifestation, Dankbarkeit',
        'ritual': 'Lade den Mond in dein Wasser. Trinke es am nächsten Morgen. Feiere deine Erfolge.',
        'meditation': 'Bade im Mondlicht (real oder visualisiert). Sei dankbar.',
        'element': 'Wasser',
      },
      5: {
        'energy': 'Loslassen beginnt, Dankbarkeit, Reflexion',
        'ritual': 'Schreibe auf, wof\u00fcr du dankbar bist. Erkenne was vollendet ist.',
        'meditation': 'Was ist bereit losgelassen zu werden?',
        'element': 'Erde',
      },
      6: {
        'energy': 'Loslassen, Heilung, Transformation',
        'ritual': 'Räuchere deinen Raum. Reinige deine Energie. Lasse Altes ziehen.',
        'meditation': 'Vergebung - dir selbst und anderen.',
        'element': 'Erde',
      },
      7: {
        'energy': 'Ruhe, Vorbereitung, Abschluss des Zyklus',
        'ritual': 'Nimm ein Reinigungsbad mit Salz. Bereite dich auf Neues vor.',
        'meditation': 'Was hast du gelernt? Was nimmst du mit in den neuen Zyklus?',
        'element': 'Luft',
      },
    };
    
    final details = phaseDetails[phase['phase']]!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        title: Row(
          children: [
            Text(
              _getMoonEmoji(phase['phase']),
              style: TextStyle(fontSize: 32),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                phase['name'],
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.wb_twilight, size: 16, color: Colors.indigoAccent),
                  SizedBox(width: 8),
                  Text(
                    'Element: ${details['element']}',
                    style: TextStyle(
                      color: Colors.indigoAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'Energie:',
                style: TextStyle(
                  color: Colors.indigoAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                details['energy']!,
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                'Ritual:',
                style: TextStyle(
                  color: Colors.indigoAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                details['ritual']!,
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                'Meditation:',
                style: TextStyle(
                  color: Colors.indigoAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                details['meditation']!,
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Schließen', style: TextStyle(color: Colors.indigoAccent)),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getCurrentMoonPhase() {
    final now = DateTime.now();
    final moonPhaseIndex = (now.day % 8);
    return _getAllMoonPhases()[moonPhaseIndex];
  }

  List<Map<String, dynamic>> _getAllMoonPhases() {
    return [
      {'name': 'Neumond', 'ritual': 'Zeit für Neuanfänge & Manifestation', 'phase': 0},
      {'name': 'Zunehmender Mond', 'ritual': 'Wachstum & Aufbau', 'phase': 1},
      {'name': 'Erstes Viertel', 'ritual': 'Entscheidungen treffen', 'phase': 2},
      {'name': 'Zunehmender Dreiviertelmond', 'ritual': 'Verfeinern & Optimieren', 'phase': 3},
      {'name': 'Vollmond', 'ritual': 'Höhepunkt der Kraft', 'phase': 4},
      {'name': 'Abnehmender Dreiviertelmond', 'ritual': 'Dankbarkeit & Loslassen', 'phase': 5},
      {'name': 'Letztes Viertel', 'ritual': 'Reflexion & Heilung', 'phase': 6},
      {'name': 'Abnehmender Mond', 'ritual': 'Vorbereitung auf Neues', 'phase': 7},
    ];
  }

  String _getMoonEmoji(int phase) {
    const emojis = ['🌑', '🌒', '🌓', '🌔', '🌕', '🌖', '🌗', '🌘'];
    return emojis[phase];
  }
}

// ═══════════════════════════════════════════════════════════
// 2. 🔮 TAROT-TAGESZIEHUNG SCREEN
// ═══════════════════════════════════════════════════════════

class TarotDailyDrawScreen extends StatefulWidget {
  const TarotDailyDrawScreen({super.key});

  @override
  State<TarotDailyDrawScreen> createState() => _TarotDailyDrawScreenState();
}

class _TarotDailyDrawScreenState extends State<TarotDailyDrawScreen> with SingleTickerProviderStateMixin {
  final _storage = StorageService();
  Map<String, dynamic>? _drawnCard;
  late AnimationController _animationController;
  late Animation<double> _flipAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text('🔮 Tarot-Ziehung'),
        backgroundColor: Color(0xFF4A148C),
        actions: [
          IconButton(
            icon: Icon(Icons.view_list),
            tooltip: 'Meine Legungen',
            onPressed: () => _showReadingHistory(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A148C), Color(0xFF000000)],
          ),
        ),
        child: _drawnCard == null
            ? _buildDrawOptions()
            : _buildCardResult(),
      ),
    );
  }

  Widget _buildDrawOptions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Wähle deine Legung',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 40),
          
          // Single Card
          _buildLegungCard(
            '🃏 Tageskarte',
            'Eine Karte für heute',
            () => _drawCard(),
          ),
          SizedBox(height: 16),
          
          // 3-Card Reading
          _buildLegungCard(
            '🎴 3-Karten-Legung',
            'Vergangenheit • Gegenwart • Zukunft',
            () => _draw3Cards(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegungCard(String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF6A1B9A).withValues(alpha: 0.5),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _draw3Cards() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ThreeCardSpreadDialog(),
    );
  }

  void _showReadingHistory() {
    final readings = _storage.getAllTarotReadings();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Meine Legungen'),
        content: SizedBox(
          width: double.maxFinite,
          child: readings.isEmpty
              ? Text('Noch keine Legungen gespeichert')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: readings.length,
                  itemBuilder: (context, index) {
                    final reading = readings[index];
                    return ListTile(
                      title: Text(reading.cardName),
                      subtitle: Text(reading.timestamp.toString().split('.')[0]),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Schließen'),
          ),
        ],
      ),
    );
  }

  // OLD drawCard method (kept for compatibility)
  // TODO: Review unused method: _buildOldDrawButton
  // Widget _buildOldDrawButton() {
    // return Column(
      // mainAxisAlignment: MainAxisAlignment.center,
      // children: [
        // Text(
          // 'Ziehe deine Tageskarte',
          // style: TextStyle(
            // fontSize: 24,
            // fontWeight: FontWeight.bold,
            // color: Colors.white,
          // ),
        // ),
        // SizedBox(height: 40),
         //         // GestureDetector(
          // onTap: _drawCard,
          // child: Container(
            // width: 180,
            // height: 280,
            // decoration: BoxDecoration(
              // gradient: LinearGradient(
                // colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
              // ),
              // borderRadius: BorderRadius.circular(16),
              // boxShadow: [
                // BoxShadow(
                  // color: Color(0xFF6A1B9A).withValues(alpha: 0.5),
                  // blurRadius: 30,
                  // spreadRadius: 5,
                // ),
              // ],
            // ),
            // child: Column(
              // mainAxisAlignment: MainAxisAlignment.center,
              // children: [
                // Icon(Icons.auto_awesome, size: 80, color: Colors.amber),
                // SizedBox(height: 16),
                // Text(
                  // 'KARTE ZIEHEN',
                  // style: TextStyle(
                    // fontSize: 18,
                    // fontWeight: FontWeight.bold,
                    // color: Colors.white,
                  // ),
                // ),
              // ],
            // ),
          // ),
        // ),
      // ],
    // );
  // }

  Widget _buildCardResult() {
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final angle = _flipAnimation.value * math.pi;
        // Only show card when flip animation is complete
        final isFlipped = _flipAnimation.value > 0.5;
        
        if (!isFlipped) {
          // Show back of card during flip
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);
          
          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: Container(
              height: 280,
              margin: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(Icons.auto_awesome, size: 80, color: Colors.amber),
              ),
            ),
          );
        }
        
        // Show front of card (no transform, normal orientation)
        return ListView(
          padding: EdgeInsets.all(20),
          children: [
            // Karte
            Container(
              height: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF6A1B9A).withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _drawnCard!['symbol'],
                      style: TextStyle(fontSize: 60),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _drawnCard!['name'],
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Bedeutung
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bedeutung',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    _drawnCard!['meaning'],
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Neue Karte ziehen
            ElevatedButton(
              onPressed: () {
                setState(() => _drawnCard = null);
                _animationController.reset();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6A1B9A),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Neue Karte ziehen',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _drawCard() {
    final random = math.Random();
    final cards = _getTarotCards();
    final card = cards[random.nextInt(cards.length)];
    
    setState(() => _drawnCard = card);
    _animationController.forward();
  }

  List<Map<String, dynamic>> _getTarotCards() {
    return [
      {
        'name': 'Der Narr',
        'symbol': '🃏',
        'meaning': 'Neuanfang, Spontanität, Vertrauen ins Leben. Wage den Sprung ins Unbekannte!',
      },
      {
        'name': 'Der Magier',
        'symbol': '✨',
        'meaning': 'Manifestationskraft, Willenskraft, Können. Du hast alle Werkzeuge, die du brauchst.',
      },
      {
        'name': 'Die Hohepriesterin',
        'symbol': '🌙',
        'meaning': 'Intuition, Geheimnisse, inneres Wissen. Höre auf deine innere Stimme.',
      },
      {
        'name': 'Die Herrscherin',
        'symbol': '👑',
        'meaning': 'Fülle, Weiblichkeit, Kreativität. Zeit zu erschaffen und zu nähren.',
      },
      {
        'name': 'Der Herrscher',
        'symbol': '⚡',
        'meaning': 'Autorität, Struktur, Führung. Übernimm Verantwortung und führe.',
      },
      {
        'name': 'Der Hierophant',
        'symbol': '📿',
        'meaning': 'Tradition, Lehre, spirituelle Weisheit. Suche nach tieferem Verständnis.',
      },
      {
        'name': 'Die Liebenden',
        'symbol': '💕',
        'meaning': 'Liebe, Harmonie, Entscheidungen. Folge deinem Herzen.',
      },
      {
        'name': 'Der Wagen',
        'symbol': '🏹',
        'meaning': 'Willenskraft, Entschlossenheit, Sieg. Vorwärts mit Mut!',
      },
      {
        'name': 'Die Kraft',
        'symbol': '🦁',
        'meaning': 'Innere Stärke, Mut, Geduld. Deine Kraft liegt in Sanftmut.',
      },
      {
        'name': 'Der Eremit',
        'symbol': '🕯️',
        'meaning': 'Einsamkeit, Selbstreflexion, innere Führung. Zeit für Rückzug.',
      },
    ];
  }
}

// ═══════════════════════════════════════════════════════════
// 3. 💎 KRISTALL-DATENBANK SCREEN
// ═══════════════════════════════════════════════════════════

class CrystalDatabaseScreen extends StatefulWidget {
  const CrystalDatabaseScreen({super.key});

  @override
  State<CrystalDatabaseScreen> createState() => _CrystalDatabaseScreenState();
}

class _CrystalDatabaseScreenState extends State<CrystalDatabaseScreen> {
  final _storage = StorageService();
  String _searchQuery = '';
  String _filterChakra = 'Alle';

  @override
  void initState() {
    super.initState();
    // Collection loaded via storage methods
  }

  bool _isInCollection(String crystalName) {
    return _storage.isCrystalInCollection(crystalName);
  }

  void _toggleCollection(String crystalName) {
    if (_isInCollection(crystalName)) {
      _storage.removeCrystalFromCollection(crystalName);
    } else {
      // Use proper CrystalCollection constructor
      _storage.addCrystalToCollection(
        CrystalCollection(
          crystalName: crystalName,
          addedDate: DateTime.now(),
        ),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var crystals = _getCrystalDatabase();
    
    // Filter by search
    if (_searchQuery.isNotEmpty) {
      crystals = crystals.where((c) => 
        c['name'].toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Filter by chakra
    if (_filterChakra != 'Alle') {
      crystals = crystals.where((c) => c['chakra'] == _filterChakra).toList();
    }
    
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text('💎 Kristall-Datenbank'),
        backgroundColor: Color(0xFF1976D2),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterChakra = value;
              });
            },
            itemBuilder: (context) => [
              'Alle', 'Wurzelchakra', 'Sakralchakra', 'Solarplexus',
              'Herzchakra', 'Halschakra', 'Stirnchakra', 'Kronenchakra'
            ].map((chakra) => PopupMenuItem(
              value: chakra,
              child: Text(chakra),
            )).toList(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1976D2), Color(0xFF000000)],
          ),
        ),
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: EdgeInsets.all(16),
              child: TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Kristall suchen...',
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            // Filter Info
            if (_filterChakra != 'Alle')
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Chip(
                      label: Text(_filterChakra),
                      onDeleted: () {
                        setState(() {
                          _filterChakra = 'Alle';
                        });
                      },
                    ),
                  ],
                ),
              ),
            // Crystal List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: crystals.length,
                itemBuilder: (context, index) {
                  final crystal = crystals[index];
                  return _buildCrystalCard(context, crystal);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrystalCard(BuildContext context, Map<String, dynamic> crystal) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            crystal['color'].withValues(alpha: 0.3),
            crystal['color'].withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: crystal['color'].withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: crystal['color'].withValues(alpha: 0.3),
                ),
                child: Center(
                  child: Text(
                    crystal['symbol'],
                    style: TextStyle(fontSize: 30),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crystal['name'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      crystal['chakra'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              // Collection Toggle
              IconButton(
                icon: Icon(
                  _isInCollection(crystal['name'])
                      ? Icons.star
                      : Icons.star_border,
                  color: _isInCollection(crystal['name'])
                      ? Colors.amber
                      : Colors.white54,
                ),
                onPressed: () => _toggleCollection(crystal['name']),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          Text(
            'Wirkung',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: crystal['color'],
            ),
          ),
          SizedBox(height: 8),
          Text(
            crystal['effect'],
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getCrystalDatabase() {
    return [
      {
        'name': 'Amethyst',
        'symbol': '💜',
        'chakra': 'Kronenchakra',
        'color': Color(0xFF9C27B0),
        'effect': 'Spirituelles Wachstum, Intuition, Schutz vor negativen Energien. Beruhigt den Geist.',
      },
      {
        'name': 'Rosenquarz',
        'symbol': '💗',
        'chakra': 'Herzchakra',
        'color': Color(0xFFE91E63),
        'effect': 'Selbstliebe, Mitgefühl, emotionale Heilung. Öffnet das Herz für Liebe.',
      },
      {
        'name': 'Bergkristall',
        'symbol': '⚪',
        'chakra': 'Alle Chakren',
        'color': Color(0xFFFFFFFF),
        'effect': 'Klarheit, Reinigung, Verstärkung. Der universelle Heilstein.',
      },
      {
        'name': 'Citrin',
        'symbol': '💛',
        'chakra': 'Solarplexus',
        'color': Color(0xFFFFEB3B),
        'effect': 'Selbstvertrauen, Fülle, Freude. Zieht Wohlstand und Erfolg an.',
      },
      {
        'name': 'Schwarzer Turmalin',
        'symbol': '⚫',
        'chakra': 'Wurzelchakra',
        'color': Color(0xFF212121),
        'effect': 'Erdung, Schutz, Abschirmung. Wandelt negative Energie um.',
      },
      {
        'name': 'Lapislazuli',
        'symbol': '💙',
        'chakra': 'Stirnchakra',
        'color': Color(0xFF1976D2),
        'effect': 'Weisheit, Wahrheit, innere Vision. Aktiviert das dritte Auge.',
      },
      {
        'name': 'Türkis',
        'symbol': '🩵',
        'chakra': 'Halschakra',
        'color': Color(0xFF00BCD4),
        'effect': 'Kommunikation, Selbstausdruck, Heilung. Stärkt die Stimme.',
      },
      {
        'name': 'Karneol',
        'symbol': '🧡',
        'chakra': 'Sakralchakra',
        'color': Color(0xFFFF5722),
        'effect': 'Kreativität, Lebensfreude, Sexualität. Entfacht das innere Feuer.',
      },
      {
        'name': 'Grüner Aventurin',
        'symbol': '💚',
        'chakra': 'Herzchakra',
        'color': Color(0xFF4CAF50),
        'effect': 'Glück, Optimismus, Herzensfrieden. Der Stein der Gewinner.',
      },
      {
        'name': 'Mondstein',
        'symbol': '🤍',
        'chakra': 'Sakralchakra',
        'color': Color(0xFFECEFF1),
        'effect': 'Weiblichkeit, Intuition, Emotionen. Verbindet mit Mondenergie.',
      },
    ];
  }
}

// ═══════════════════════════════════════════════════════════
// 3.5. 🎴 THREE CARD SPREAD DIALOG
// ═══════════════════════════════════════════════════════════

class ThreeCardSpreadDialog extends StatefulWidget {
  const ThreeCardSpreadDialog({super.key});

  @override
  State<ThreeCardSpreadDialog> createState() => _ThreeCardSpreadDialogState();
}

class _ThreeCardSpreadDialogState extends State<ThreeCardSpreadDialog> {
  List<Map<String, dynamic>> _drawnCards = [];
  bool _isRevealed = false;

  @override
  void initState() {
    super.initState();
    _drawCards();
  }

  void _drawCards() {
    final allCards = _getTarotDeck();
    allCards.shuffle();
    setState(() {
      _drawnCards = allCards.take(3).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4A148C), Color(0xFF000000)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎴 3-Karten-Legung',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            
            // Three Cards Layout
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCard(0, 'Vergangenheit'),
                _buildCard(1, 'Gegenwart'),
                _buildCard(2, 'Zukunft'),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Reveal/Close Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!_isRevealed)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isRevealed = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A1B9A),
                    ),
                    child: const Text('AUFDECKEN'),
                  ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('SCHLIESSEN'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(int index, String position) {
    if (index >= _drawnCards.length) return const SizedBox();
    
    final card = _drawnCards[index];
    
    return Column(
      children: [
        Text(
          position,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            if (_isRevealed) {
              _showCardDetails(card);
            }
          },
          child: Container(
            width: 90,
            height: 140,
            decoration: BoxDecoration(
              gradient: _isRevealed
                  ? LinearGradient(
                      colors: [
                        card['color'].withValues(alpha: 0.8),
                        card['color'].withValues(alpha: 0.4),
                      ],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
                    ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white54),
            ),
            child: Center(
              child: _isRevealed
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          card['symbol'],
                          style: const TextStyle(fontSize: 30),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            card['name'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      '?',
                      style: TextStyle(
                        fontSize: 60,
                        color: Colors.white38,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCardDetails(Map<String, dynamic> card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${card['symbol']} ${card['name']}'),
        content: Text(card['meaning']),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getTarotDeck() {
    return [
      {'name': 'Der Narr', 'symbol': '🃏', 'meaning': 'Neue Anfänge, Unschuld, Spontanität', 'color': const Color(0xFFFFEB3B)},
      {'name': 'Der Magier', 'symbol': '🪄', 'meaning': 'Manifestation, Willenskraft, Geschicklichkeit', 'color': const Color(0xFFE91E63)},
      {'name': 'Die Hohepriesterin', 'symbol': '🌙', 'meaning': 'Intuition, Mysterien, innere Stimme', 'color': const Color(0xFF9C27B0)},
      {'name': 'Die Herrscherin', 'symbol': '👑', 'meaning': 'Fruchtbarkeit, Fülle, Natur', 'color': const Color(0xFF4CAF50)},
      {'name': 'Der Herrscher', 'symbol': '⚔️', 'meaning': 'Autorität, Struktur, Kontrolle', 'color': const Color(0xFFFF5722)},
      {'name': 'Der Hierophant', 'symbol': '📿', 'meaning': 'Tradition, Spiritualität, Lehre', 'color': const Color(0xFF3F51B5)},
      {'name': 'Die Liebenden', 'symbol': '💕', 'meaning': 'Liebe, Harmonie, Entscheidungen', 'color': const Color(0xFFE91E63)},
      {'name': 'Der Wagen', 'symbol': '🏇', 'meaning': 'Willenskraft, Sieg, Entschlossenheit', 'color': const Color(0xFF2196F3)},
      {'name': 'Die Kraft', 'symbol': '🦁', 'meaning': 'Mut, innere Stärke, Geduld', 'color': const Color(0xFFFF9800)},
      {'name': 'Der Eremit', 'symbol': '🕯️', 'meaning': 'Innenschau, Weisheit, Einsamkeit', 'color': const Color(0xFF9E9E9E)},
      {'name': 'Das Rad', 'symbol': '☸️', 'meaning': 'Schicksal, Zyklen, Wendepunkt', 'color': const Color(0xFF00BCD4)},
      {'name': 'Die Gerechtigkeit', 'symbol': '⚖️', 'meaning': 'Fairness, Wahrheit, Gesetz', 'color': const Color(0xFF673AB7)},
      {'name': 'Der Gehängte', 'symbol': '🙃', 'meaning': 'Loslassen, neue Perspektive, Opfer', 'color': const Color(0xFF607D8B)},
      {'name': 'Der Tod', 'symbol': '💀', 'meaning': 'Transformation, Ende, Neuanfang', 'color': const Color(0xFF212121)},
      {'name': 'Die Mäßigkeit', 'symbol': '🍷', 'meaning': 'Balance, Geduld, Harmonie', 'color': const Color(0xFF03A9F4)},
      {'name': 'Der Teufel', 'symbol': '😈', 'meaning': 'Versuchung, Bindung, Materialismus', 'color': const Color(0xFFD32F2F)},
      {'name': 'Der Turm', 'symbol': '🗼', 'meaning': 'Plötzliche Veränderung, Chaos, Befreiung', 'color': const Color(0xFFFF5722)},
      {'name': 'Der Stern', 'symbol': '⭐', 'meaning': 'Hoffnung, Inspiration, Gelassenheit', 'color': const Color(0xFF00BCD4)},
      {'name': 'Der Mond', 'symbol': '🌙', 'meaning': 'Illusion, Intuition, Unterbewusstsein', 'color': const Color(0xFF9C27B0)},
      {'name': 'Die Sonne', 'symbol': '☀️', 'meaning': 'Freude, Erfolg, Vitalität', 'color': const Color(0xFFFFEB3B)},
      {'name': 'Das Gericht', 'symbol': '📯', 'meaning': 'Wiedergeburt, innerer Ruf, Vergebung', 'color': const Color(0xFFFF9800)},
      {'name': 'Die Welt', 'symbol': '🌍', 'meaning': 'Vollendung, Erfüllung, Einheit', 'color': const Color(0xFF4CAF50)},
    ];
  }
}

// ═══════════════════════════════════════════════════════════
// 4. 📿 MEDITATION-TIMER SCREEN
// ═══════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════
// 🧘 GEFÜHRTE MEDITATIONEN - KOMPLETT-SCREEN
// ═══════════════════════════════════════════════════════════════

class GuidedMeditationsScreen extends StatefulWidget {
  const GuidedMeditationsScreen({super.key});

  @override
  State<GuidedMeditationsScreen> createState() => _GuidedMeditationsScreenState();
}

class _GuidedMeditationsScreenState extends State<GuidedMeditationsScreen> {
  // UNUSED FIELD: final _storageService = StorageService();
  List<String> _favorites = [];
  String _selectedCategory = 'Alle';

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    // Load from storage
    setState(() {
      _favorites = []; // Will be loaded from Hive
    });
  }

  List<Map<String, dynamic>> _getMeditationSessions() {
    return [
      {
        'id': 'body_scan',
        'title': 'Body Scan',
        'duration': 10,
        'category': 'Entspannung',
        'icon': '🧘',
        'color': 0xFF4A148C,
        'description': 'Achtsame Körperwahrnehmung von Kopf bis Fuß',
        'steps': [
          'Finde eine bequeme Position',
          'Schließe deine Augen',
          'Beginne bei deinem Kopf',
          'Wandere langsam durch deinen Körper',
          'Nimm jede Empfindung wahr',
          'Keine Bewertung, nur Beobachtung',
        ],
      },
      {
        'id': 'breath_meditation',
        'title': 'Atem-Meditation',
        'duration': 5,
        'category': 'Fokus',
        'icon': '🌬️',
        'color': 0xFF1976D2,
        'description': 'Konzentration auf den natürlichen Atemfluss',
        'steps': [
          'Setze dich aufrecht hin',
          'Atme natürlich',
          'Beobachte deinen Atem',
          'Einatmen... Ausatmen...',
          'Kehre sanft zum Atem zurück',
          'Bleibe präsent im Moment',
        ],
      },
      {
        'id': 'chakra_journey',
        'title': 'Chakra-Reise',
        'duration': 15,
        'category': 'Energie',
        'icon': '🌈',
        'color': 0xFF9C27B0,
        'description': 'Reise durch alle 7 Chakren',
        'steps': [
          'Wurzelchakra: Rote Energie',
          'Sakralchakra: Orange Energie',
          'Solarplexus: Gelbe Energie',
          'Herzchakra: Grüne Energie',
          'Halschakra: Blaue Energie',
          'Stirnchakra: Indigo Energie',
          'Kronenchakra: Violette Energie',
        ],
      },
      {
        'id': 'loving_kindness',
        'title': 'Liebende Güte',
        'duration': 10,
        'category': 'Herz',
        'icon': '💖',
        'color': 0xFFE91E63,
        'description': 'Kultiviere Liebe und Mitgefühl',
        'steps': [
          'Möge ich glücklich sein',
          'Möge ich gesund sein',
          'Möge ich in Frieden leben',
          'Sende diese Wünsche an geliebte Menschen',
          'Sende sie an neutrale Menschen',
          'Sende sie an alle Wesen',
        ],
      },
      {
        'id': 'visualization',
        'title': 'Visualisierung',
        'duration': 12,
        'category': 'Manifestation',
        'icon': '✨',
        'color': 0xFFFFB300,
        'description': 'Erschaffe deine Realität durch innere Bilder',
        'steps': [
          'Stelle dir deinen idealen Tag vor',
          'Visualisiere deine Ziele',
          'Fühle die Emotionen',
          'Sehe dich erfolgreich',
          'Glaube an die Möglichkeit',
          'Verankere die Vision',
        ],
      },
      {
        'id': 'mountain_meditation',
        'title': 'Berg-Meditation',
        'duration': 8,
        'category': 'Stabilität',
        'icon': '⛰️',
        'color': 0xFF5D4037,
        'description': 'Finde innere Stabilität wie ein Berg',
        'steps': [
          'Stelle dir einen majestätischen Berg vor',
          'Fühle seine Stabilität',
          'Du BIST dieser Berg',
          'Wetter kommt und geht',
          'Der Berg bleibt stehen',
          'Unerschütterlich und präsent',
        ],
      },
      {
        'id': 'gratitude_meditation',
        'title': 'Dankbarkeit',
        'duration': 7,
        'category': 'Herz',
        'icon': '🙏',
        'color': 0xFF00897B,
        'description': 'Kultiviere ein dankbares Herz',
        'steps': [
          'Was kannst du heute sehen?',
          'Wofür bist du dankbar?',
          'Spüre die Dankbarkeit',
          'Lass sie dein Herz füllen',
          'Danke für die kleinen Dinge',
          'Danke für dein Leben',
        ],
      },
      {
        'id': 'walking_meditation',
        'title': 'Geh-Meditation',
        'duration': 10,
        'category': 'Bewegung',
        'icon': '🚶',
        'color': 0xFF43A047,
        'description': 'Achtsames Gehen in der Natur',
        'steps': [
          'Gehe langsam und bewusst',
          'Spüre jeden Schritt',
          'Fühle den Boden unter dir',
          'Nimm deine Umgebung wahr',
          'Bleibe im Moment',
          'Jeder Schritt eine Meditation',
        ],
      },
      {
        'id': 'sound_meditation',
        'title': 'Klang-Meditation',
        'duration': 12,
        'category': 'Sinne',
        'icon': '🔔',
        'color': 0xFFD32F2F,
        'description': 'Tauche ein in heilende Klänge',
        'steps': [
          'Höre aufmerksam',
          'Folge dem Klang',
          'Spüre die Vibrationen',
          'Lass dich tragen',
          'Verschmelze mit dem Klang',
          'Kehre gestärkt zurück',
        ],
      },
      {
        'id': 'sleep_meditation',
        'title': 'Einschlaf-Meditation',
        'duration': 20,
        'category': 'Schlaf',
        'icon': '🌙',
        'color': 0xFF283593,
        'description': 'Sanfter Übergang in den Schlaf',
        'steps': [
          'Lege dich bequem hin',
          'Entspanne jeden Muskel',
          'Atme tief und langsam',
          'Lass alle Gedanken ziehen',
          'Sinke tiefer und tiefer',
          'Gleite in den Schlaf',
        ],
      },
    ];
  }

  List<String> _getCategories() {
    return ['Alle', 'Entspannung', 'Fokus', 'Energie', 'Herz', 'Manifestation', 'Stabilität', 'Bewegung', 'Sinne', 'Schlaf'];
  }

  List<Map<String, dynamic>> _getFilteredSessions() {
    final sessions = _getMeditationSessions();
    if (_selectedCategory == 'Alle') return sessions;
    return sessions.where((s) => s['category'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('🧘 Geführte Meditationen'),
        backgroundColor: const Color(0xFF4527A0),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              // Show favorites
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4527A0), Color(0xFF000000)],
          ),
        ),
        child: Column(
          children: [
            // Category Filter
            _buildCategoryFilter(),
            
            // Sessions List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: _getFilteredSessions()
                    .map((session) => _buildSessionCard(session))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _getCategories().length,
        itemBuilder: (context, index) {
          final category = _getCategories()[index];
          final isSelected = _selectedCategory == category;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              selectedColor: const Color(0xFF6A1B9A),
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final isFavorite = _favorites.contains(session['id']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(session['color']).withValues(alpha: 0.3),
              const Color(0xFF1E1E1E),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color(session['color']).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Color(session['color']),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                session['icon'],
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          title: Text(
            session['title'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                session['description'],
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.timer, color: Colors.white54, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${session['duration']} Min',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(session['color']).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      session['category'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.white54,
                ),
                onPressed: () {
                  setState(() {
                    if (isFavorite) {
                      _favorites.remove(session['id']);
                    } else {
                      _favorites.add(session['id']);
                    }
                  });
                },
              ),
              const Icon(
                Icons.play_circle_filled,
                color: Colors.white,
                size: 32,
              ),
            ],
          ),
          onTap: () {
            _startSession(session);
          },
        ),
      ),
    );
  }

  void _startSession(Map<String, dynamic> session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeditationSessionPlayer(session: session),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 🎵 MEDITATION SESSION PLAYER
// ═══════════════════════════════════════════════════════════════

class MeditationSessionPlayer extends StatefulWidget {
  final Map<String, dynamic> session;
  
  const MeditationSessionPlayer({super.key, required this.session});

  @override
  State<MeditationSessionPlayer> createState() => _MeditationSessionPlayerState();
}

class _MeditationSessionPlayerState extends State<MeditationSessionPlayer> {
  final _storageService = StorageService();
  
  int _currentStep = 0;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.session['duration'] * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    setState(() {
      _isRunning = !_isRunning;
    });
    
    if (_isRunning) {
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  void _startTimer() {
    final totalSteps = (widget.session['steps'] as List).length;
    final secondsPerStep = (_remainingSeconds / totalSteps).floor();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
          _currentStep = (widget.session['duration'] * 60 - _remainingSeconds) ~/ secondsPerStep;
          if (_currentStep >= totalSteps) _currentStep = totalSteps - 1;
        });
      } else {
        _completeSession();
      }
    });
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
    
    // Save to stats
    await _storageService.saveMeditationSessionComplete({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'duration': widget.session['duration'] ?? 0,
      'title': widget.session['title'] ?? 'Meditation',
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Show completion dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          '🎉 Session Abgeschlossen!',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Du hast die "${widget.session['title']}" Session erfolgreich abgeschlossen.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('FERTIG'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.session['steps'] as List;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(widget.session['title']),
        backgroundColor: Color(widget.session['color']),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(widget.session['color']),
              const Color(0xFF000000),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Timer Circle
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 8,
                  ),
                ),
                child: Center(
                  child: Text(
                    _formatTime(_remainingSeconds),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Current Step
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Schritt ${_currentStep + 1} von ${steps.length}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Step Text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  steps[_currentStep],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    height: 1.5,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Play/Pause Button
              Padding(
                padding: const EdgeInsets.all(32),
                child: FloatingActionButton.extended(
                  onPressed: _toggleTimer,
                  backgroundColor: _isRunning ? Colors.red : Color(widget.session['color']),
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(_isRunning ? 'PAUSE' : 'START'),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

// ═══════════════════════════════════════════════════════════════
// 📿 MEDITATION TIMER - ORIGINAL (Simple Timer)
// ═══════════════════════════════════════════════════════════════

class MeditationTimerScreen extends StatefulWidget {
  const MeditationTimerScreen({super.key});

  @override
  State<MeditationTimerScreen> createState() => _MeditationTimerScreenState();
}

class _MeditationTimerScreenState extends State<MeditationTimerScreen> {
  final _storageService = StorageService();
  
  int _selectedMinutes = 10;
  bool _isRunning = false;
  int _remainingSeconds = 600;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text('📿 Meditation-Timer'),
        backgroundColor: Color(0xFF4527A0),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4527A0), Color(0xFF000000)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Timer Display
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF5E35B1),
                      Color(0xFF4527A0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF5E35B1).withValues(alpha: 0.5),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _formatTime(_remainingSeconds),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 60),
              
              // Presets
              if (!_isRunning) ...[
                Text(
                  'Dauer wählen',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 20),
                
                Wrap(
                  spacing: 12,
                  children: [5, 10, 15, 20, 30, 60].map((minutes) {
                    return ChoiceChip(
                      label: Text('$minutes Min'),
                      selected: _selectedMinutes == minutes,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedMinutes = minutes;
                            _remainingSeconds = minutes * 60;
                          });
                        }
                      },
                      selectedColor: Color(0xFF5E35B1),
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        color: _selectedMinutes == minutes
                            ? Colors.white
                            : Colors.white70,
                      ),
                    );
                  }).toList(),
                ),
                
                SizedBox(height: 40),
              ],
              
              // Start/Stop Button
              ElevatedButton(
                onPressed: _toggleTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRunning ? Colors.red : Color(0xFF5E35B1),
                  padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  _isRunning ? 'STOPPEN' : 'STARTEN',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _toggleTimer() {
    setState(() {
      _isRunning = !_isRunning;
    });
    
    if (_isRunning) {
      _startTimer();
    }
  }

  void _startTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (_isRunning && mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
            _startTimer();
          } else {
            _isRunning = false;
            _showCompletionDialog();
          }
        });
      }
    });
  }

  void _showCompletionDialog() async {
    // Session speichern
    final session = MeditationSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      durationMinutes: _selectedMinutes,
      meditationType: 'timer',
    );
    
    await _storageService.saveMeditationSession(session);
    
    // 🏆 ACHIEVEMENT TRACKING
    final achievementService = AchievementService();
    if (mounted) {
      // TODO: Re-enable after achievement integration
      // await achievementService.onMeditationCompleted(context, _selectedMinutes);
    }
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        title: Text('🎉 Meditation abgeschlossen!', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Gut gemacht! Du hast $_selectedMinutes Minuten meditiert.',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFFD700).withValues(alpha: 0.3),
                    Color(0xFFFFA000).withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '✨ +$_selectedMinutes XP',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _remainingSeconds = _selectedMinutes * 60;
              });
            },
            child: Text('OK', style: TextStyle(color: Color(0xFF5E35B1))),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 5. 🌈 AURA-FARBEN READER SCREEN
// ═══════════════════════════════════════════════════════════

class AuraColorReaderScreen extends StatefulWidget {
  const AuraColorReaderScreen({super.key});

  @override
  State<AuraColorReaderScreen> createState() => _AuraColorReaderScreenState();
}

class _AuraColorReaderScreenState extends State<AuraColorReaderScreen> {
  Map<String, dynamic>? _result;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text('🌈 Aura-Farben Reader'),
        backgroundColor: Color(0xFFAD1457),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFAD1457), Color(0xFF000000)],
          ),
        ),
        child: _result == null
            ? _buildQuiz()
            : _buildResult(),
      ),
    );
  }

  Widget _buildQuiz() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Entdecke deine Aura-Farbe',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            
            ElevatedButton(
              onPressed: _analyzeAura,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE91E63),
                padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'ANALYSE STARTEN',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        // Aura-Visualisierung
        Container(
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _result!['color'],
                _result!['color'].withValues(alpha: 0.5),
                Colors.transparent,
              ],
            ),
          ),
          child: Center(
            child: Text(
              _result!['emoji'],
              style: TextStyle(fontSize: 80),
            ),
          ),
        ),
        
        SizedBox(height: 24),
        
        Text(
          'Deine Aura-Farbe',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: 8),
        
        Text(
          _result!['name'],
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: 24),
        
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bedeutung',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _result!['color'],
                ),
              ),
              SizedBox(height: 12),
              Text(
                _result!['meaning'],
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 16),
        
        ElevatedButton(
          onPressed: () => setState(() => _result = null),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFE91E63),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Neue Analyse',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _analyzeAura() {
    final random = math.Random();
    final auras = _getAuraColors();
    
    setState(() {
      _result = auras[random.nextInt(auras.length)];
    });
  }

  List<Map<String, dynamic>> _getAuraColors() {
    return [
      {
        'name': 'Rote Aura',
        'emoji': '❤️',
        'color': Color(0xFFF44336),
        'meaning': 'Leidenschaft, Energie, Willenskraft. Du bist voller Lebenskraft und Durchsetzungsvermögen.',
      },
      {
        'name': 'Blaue Aura',
        'emoji': '💙',
        'color': Color(0xFF2196F3),
        'meaning': 'Wahrheit, Kommunikation, Frieden. Du sprichst mit Klarheit und Weisheit.',
      },
      {
        'name': 'Grüne Aura',
        'emoji': '💚',
        'color': Color(0xFF4CAF50),
        'meaning': 'Heilung, Harmonie, Liebe. Du bist ein natürlicher Heiler und Friedensstifter.',
      },
      {
        'name': 'Gelbe Aura',
        'emoji': '💛',
        'color': Color(0xFFFFEB3B),
        'meaning': 'Freude, Optimismus, Intellekt. Du strahlst Sonnenschein und Inspiration aus.',
      },
      {
        'name': 'Violette Aura',
        'emoji': '💜',
        'color': Color(0xFF9C27B0),
        'meaning': 'Spiritualität, Intuition, Magie. Du bist tief verbunden mit dem Göttlichen.',
      },
      {
        'name': 'Weiße Aura',
        'emoji': '🤍',
        'color': Color(0xFFFFFFFF),
        'meaning': 'Reinheit, Klarheit, Erleuchtung. Du verkörperst spirituelle Reinheit.',
      },
    ];
  }
}

// ═══════════════════════════════════════════════════════════
// 6. 🧬 DNA-AKTIVIERUNG TRACKER SCREEN
// ═══════════════════════════════════════════════════════════

class DnaActivationTrackerScreen extends StatefulWidget {
  const DnaActivationTrackerScreen({super.key});

  @override
  State<DnaActivationTrackerScreen> createState() => _DnaActivationTrackerScreenState();
}

class _DnaActivationTrackerScreenState extends State<DnaActivationTrackerScreen> {
  final List<bool> _activatedStrands = List.filled(12, false);
  
  @override
  Widget build(BuildContext context) {
    final activatedCount = _activatedStrands.where((s) => s).length;
    
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text('🧬 DNA-Aktivierung Tracker'),
        backgroundColor: Color(0xFF00695C),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00695C), Color(0xFF000000)],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // Progress Card
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00897B), Color(0xFF00695C)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF00897B).withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'DNA-Stränge aktiviert',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '$activatedCount / 12',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: activatedCount / 12,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            Text(
              'Die 12 DNA-Stränge',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            
            ..._getDnaStrands().asMap().entries.map((entry) {
              final index = entry.key;
              final strand = entry.value;
              return _buildStrandCard(index, strand);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStrandCard(int index, Map<String, String> strand) {
    final isActivated = _activatedStrands[index];
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActivated 
            ? Color(0xFF00897B).withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActivated 
              ? Color(0xFF00897B)
              : Colors.white24,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isActivated 
                  ? Color(0xFF00897B)
                  : Colors.white12,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strand['name']!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  strand['description']!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isActivated,
            onChanged: (value) {
              setState(() {
                _activatedStrands[index] = value;
              });
            },
            activeTrackColor: Color(0xFF00897B),
            activeThumbColor: Color(0xFF00897B),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getDnaStrands() {
    return [
      {'name': 'Strang 1 & 2', 'description': 'Physischer Körper - Grundbedürfnisse'},
      {'name': 'Strang 3 & 4', 'description': 'Emotionalkörper - Gefühle & Beziehungen'},
      {'name': 'Strang 5 & 6', 'description': 'Mentalkörper - Gedanken & Glaubenssätze'},
      {'name': 'Strang 7 & 8', 'description': 'Spiritueller Körper - Höheres Selbst'},
      {'name': 'Strang 9 & 10', 'description': 'Kosmisches Bewusstsein - Einheit'},
      {'name': 'Strang 11 & 12', 'description': 'Christus-Bewusstsein - Vollendung'},
    ];
  }
}

// ═══════════════════════════════════════════════════════════
// 7. 🎵 FREQUENZ-GENERATOR SCREEN (LEGACY - Deprecated)
// ═══════════════════════════════════════════════════════════
// NOTE: This is the OLD version. Use ../frequency_generator_screen.dart instead!

class FrequencyGeneratorScreenLegacy extends StatefulWidget {
  const FrequencyGeneratorScreenLegacy({super.key});

  @override
  State<FrequencyGeneratorScreenLegacy> createState() => _FrequencyGeneratorScreenLegacyState();
}

class _FrequencyGeneratorScreenLegacyState extends State<FrequencyGeneratorScreenLegacy> {
  final Set<String> _selectedFrequencies = {};
  bool _isPlaying = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text('🎵 Frequenz-Generator'),
        backgroundColor: Color(0xFFD32F2F),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD32F2F), Color(0xFF000000)],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // Info Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.graphic_eq, size: 48, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Solfeggio Frequenzen',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Heilende Klangfrequenzen für Körper, Geist & Seele',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  
                  if (_selectedFrequencies.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(
                      '${_selectedFrequencies.length} Frequenz${_selectedFrequencies.length > 1 ? "en" : ""} ausgewählt',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isPlaying = !_isPlaying;
                        });
                      },
                      icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                      label: Text(_isPlaying ? 'STOPPEN' : 'ABSPIELEN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isPlaying ? Colors.red : Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            Text(
              'Wähle Frequenzen (Multi-Select)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            
            ..._getSolfeggioFrequencies().map((freq) => _buildFrequencyCard(freq)),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyCard(Map<String, dynamic> freq) {
    final isSelected = _selectedFrequencies.contains(freq['hz']);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedFrequencies.remove(freq['hz']);
          } else {
            _selectedFrequencies.add(freq['hz']);
          }
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    freq['color'],
                    freq['color'].withValues(alpha: 0.5),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? freq['color'] : Colors.white24,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: freq['color'].withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: freq['color'].withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: freq['color'],
                  width: 2,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSelected ? Icons.music_note : Icons.graphic_eq,
                      color: Colors.white,
                      size: 24,
                    ),
                    Text(
                      '${freq['hz']} Hz',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    freq['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    freq['effect'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.pause_circle : Icons.play_circle,
              color: isSelected ? freq['color'] : Colors.white54,
              size: 40,
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getSolfeggioFrequencies() {
    return [
      {
        'hz': '174',
        'name': 'Schmerzlinderung',
        'effect': 'Natürliches Anästhetikum',
        'color': Color(0xFF8B4513),
      },
      {
        'hz': '285',
        'name': 'Geweberegenerierung',
        'effect': 'Zellheilung & Verjüngung',
        'color': Color(0xFFFF6347),
      },
      {
        'hz': '396',
        'name': 'Befreiung von Angst',
        'effect': 'Löst Schuldgefühle auf',
        'color': Color(0xFFFF0000),
      },
      {
        'hz': '417',
        'name': 'Veränderung',
        'effect': 'Löst blockierte Situationen',
        'color': Color(0xFFFF8C00),
      },
      {
        'hz': '528',
        'name': 'Transformation',
        'effect': 'DNA-Reparatur & Wunder',
        'color': Color(0xFFFFD700),
      },
      {
        'hz': '639',
        'name': 'Beziehungen',
        'effect': 'Harmonie & Liebe',
        'color': Color(0xFF00FF00),
      },
      {
        'hz': '741',
        'name': 'Erwachen',
        'effect': 'Intuition & Ausdruck',
        'color': Color(0xFF1E90FF),
      },
      {
        'hz': '852',
        'name': 'Spirituelle Ordnung',
        'effect': 'Rückkehr zur Quelle',
        'color': Color(0xFF4B0082),
      },
      {
        'hz': '963',
        'name': 'Göttliche Verbindung',
        'effect': 'Einheitsbewusstsein',
        'color': Color(0xFF9370DB),
      },
    ];
  }
}

// ═══════════════════════════════════════════════════════════
// 8. 🌌 AKASHA-CHRONIK JOURNAL SCREEN
// ═══════════════════════════════════════════════════════════

class AkashaChronicleJournalScreen extends StatefulWidget {
  const AkashaChronicleJournalScreen({super.key});

  @override
  State<AkashaChronicleJournalScreen> createState() => _AkashaChronicleJournalScreenState();
}

class _AkashaChronicleJournalScreenState extends State<AkashaChronicleJournalScreen> {
  final List<Map<String, String>> _entries = [];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text('🌌 Akasha-Chronik Journal'),
        backgroundColor: Color(0xFF311B92),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF311B92), Color(0xFF000000)],
          ),
        ),
        child: _entries.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: EdgeInsets.all(20),
                itemCount: _entries.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: _buildInfoCard(),
                    );
                  }
                  return _buildJournalEntry(_entries[index - 1]);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewEntry,
        backgroundColor: Color(0xFF311B92),
        icon: Icon(Icons.add),
        label: Text('Neuer Eintrag'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 80, color: Colors.white24),
          SizedBox(height: 20),
          Text(
            'Dein Seelen-Journal',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Dokumentiere deine spirituellen Erkenntnisse,\nTräume und Seelenerinnerungen',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4527A0), Color(0xFF311B92)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4527A0).withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome, size: 40, color: Colors.white),
          SizedBox(height: 12),
          Text(
            'Die Akasha-Chronik',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Das universelle Gedächtnis aller Seelen, Gedanken und Ereignisse',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalEntry(Map<String, String> entry) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry['date']!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
          SizedBox(height: 8),
          Text(
            entry['title']!,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            entry['content']!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _addNewEntry() {
    showDialog(
      context: context,
      builder: (context) {
        final titleController = TextEditingController();
        final contentController = TextEditingController();
        
        return AlertDialog(
          backgroundColor: Color(0xFF1A1A1A),
          title: Text('Neuer Eintrag', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Titel',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: contentController,
                style: TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Inhalt',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _entries.insert(0, {
                    'date': DateTime.now().toString().split(' ')[0],
                    'title': titleController.text,
                    'content': contentController.text,
                  });
                });
                Navigator.pop(context);
              },
              child: Text('Speichern'),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 9. 🕉️ MANTRA-BIBLIOTHEK SCREEN
// ═══════════════════════════════════════════════════════════

class MantraLibraryScreen extends StatefulWidget {
  const MantraLibraryScreen({super.key});

  @override
  State<MantraLibraryScreen> createState() => _MantraLibraryScreenState();
}

class _MantraLibraryScreenState extends State<MantraLibraryScreen> {
  final Map<String, int> _mantraCounters = {};
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text('🕉️ Mantra-Bibliothek'),
        backgroundColor: Color(0xFFE65100),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE65100), Color(0xFF000000)],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // Info Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.self_improvement, size: 48, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Heilige Mantras',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Wiederhole Mantras für spirituelle Transformation',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            ..._getMantras().map((mantra) => _buildMantraCard(mantra)),
          ],
        ),
      ),
    );
  }

  Widget _buildMantraCard(Map<String, String> mantra) {
    final counter = _mantraCounters[mantra['text']!] ?? 0;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Text(
            mantra['text']!,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            mantra['translation']!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            mantra['meaning']!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white54,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Zähler: $counter',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _mantraCounters[mantra['text']!] = counter + 1;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE65100),
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(20),
                ),
                child: Icon(Icons.add, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getMantras() {
    return [
      {
        'text': 'OM',
        'translation': 'Der Urklang',
        'meaning': 'Das universelle Mantra der Einheit',
      },
      {
        'text': 'OM MANI PADME HUM',
        'translation': 'Om Juwel in der Lotusblüte',
        'meaning': 'Mitgefühl und Weisheit',
      },
      {
        'text': 'SO HAM',
        'translation': 'Ich bin Das',
        'meaning': 'Einheit mit dem Göttlichen',
      },
      {
        'text': 'OM NAMAH SHIVAYA',
        'translation': 'Verneigung vor Shiva',
        'meaning': 'Transformation und Erneuerung',
      },
      {
        'text': 'LOKAH SAMASTAH SUKHINO BHAVANTU',
        'translation': 'Mögen alle Wesen glücklich sein',
        'meaning': 'Universelles Mitgefühl',
      },
    ];
  }
}

// ═══════════════════════════════════════════════════════════
// 10-15: WEITERE SCREENS (Kompakt)
// ═══════════════════════════════════════════════════════════

// 10. Heilige Geometrie
class SacredGeometryScreen extends StatefulWidget {
  const SacredGeometryScreen({super.key});

  @override
  State<SacredGeometryScreen> createState() => _SacredGeometryScreenState();
}

class _SacredGeometryScreenState extends State<SacredGeometryScreen> {
  String? _selectedGeometry;
  
  final List<Map<String, String>> _geometries = [
    {
      'emoji': '🌸',
      'name': 'Blume des Lebens',
      'meaning': 'Symbol der Schöpfung und kosmischen Ordnung',
      'usage': 'Meditation, Energiearbeit, Raumharmonisierung',
    },
    {
      'emoji': '⭐',
      'name': 'Merkaba',
      'meaning': 'Lichtkörper-Aktivierung und dimensionale Reise',
      'usage': 'Spirituelle Transformation, Aufstieg',
    },
    {
      'emoji': '🔷',
      'name': 'Metatrons Würfel',
      'meaning': 'Vereinigung aller platonischen Körper',
      'usage': 'Schutz, Reinigung, spirituelle Geometrie',
    },
    {
      'emoji': '🔶',
      'name': 'Sri Yantra',
      'meaning': 'Manifestation göttlicher Energie',
      'usage': 'Fülle, Wohlstand, spirituelles Wachstum',
    },
    {
      'emoji': '🌀',
      'name': 'Fibonacci Spirale',
      'meaning': 'Natürliche Ordnung des Universums',
      'usage': 'Harmonie, Wachstum, universelle Balance',
    },
    {
      'emoji': '⬡',
      'name': 'Hexagon',
      'meaning': 'Stabilität und perfekte Balance',
      'usage': 'Erdung, Struktur, natürliche Ordnung',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text('🔯 Heilige Geometrie'),
        backgroundColor: Color(0xFF5E35B1),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5E35B1), Color(0xFF000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              // Info Card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.hexagon_outlined, size: 48, color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'Heilige Geometrie',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tippe auf ein Symbol für detaillierte Informationen',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Grid View
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _geometries.length,
                itemBuilder: (context, index) {
                  final geometry = _geometries[index];
                  return _buildGeometryCard(geometry);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeometryCard(Map<String, String> geometry) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGeometry = geometry['name'];
        });
        _showGeometryDetails(geometry);
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _selectedGeometry == geometry['name']
              ? Colors.purple.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selectedGeometry == geometry['name']
                ? Colors.purpleAccent
                : Colors.white24,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              geometry['emoji']!,
              style: TextStyle(fontSize: 64),
            ),
            SizedBox(height: 12),
            Text(
              geometry['name']!,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  void _showGeometryDetails(Map<String, String> geometry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        title: Row(
          children: [
            Text(geometry['emoji']!, style: TextStyle(fontSize: 32)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                geometry['name']!,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bedeutung:',
              style: TextStyle(
                color: Colors.purpleAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              geometry['meaning']!,
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              'Anwendung:',
              style: TextStyle(
                color: Colors.purpleAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              geometry['usage']!,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Schließen', style: TextStyle(color: Colors.purpleAccent)),
          ),
        ],
      ),
    );
  }
}

// 11. Erdung-Übungen
class GroundingExercisesScreen extends StatefulWidget {
  const GroundingExercisesScreen({super.key});

  @override
  State<GroundingExercisesScreen> createState() => _GroundingExercisesScreenState();
}

class _GroundingExercisesScreenState extends State<GroundingExercisesScreen> {
  String? _selectedExercise;
  
  final List<Map<String, String>> _exercises = [
    {
      'emoji': '👣',
      'name': 'Barfuß laufen',
      'duration': '10-15 Min',
      'description': 'Gehe barfuß über Gras, Erde oder Sand. Spüre die Verbindung zur Erde.',
      'benefits': 'Stärkt Erdverbindung, reduziert Stress, aktiviert Fußreflexzonen',
    },
    {
      'emoji': '🫁',
      'name': '4-7-8 Atemübung',
      'duration': '5 Min',
      'description': '4 Sekunden einatmen, 7 Sekunden halten, 8 Sekunden ausatmen.',
      'benefits': 'Beruhigt Nervensystem, reduziert Angst, verbessert Schlaf',
    },
    {
      'emoji': '🌳',
      'name': 'Baum-Meditation',
      'duration': '15 Min',
      'description': 'Umarme einen Baum oder lehne dich an. Spüre seine Energie.',
      'benefits': 'Tiefe Erdung, Energieausgleich, emotionale Stabilität',
    },
    {
      'emoji': '🧘',
      'name': 'Körper-Scan',
      'duration': '20 Min',
      'description': 'Scanne deinen Körper von Kopf bis Fuß. Nimm jede Empfindung wahr.',
      'benefits': 'Achtsamkeit, Körperbewusstsein, Stressabbau',
    },
    {
      'emoji': '🍃',
      'name': 'Natur-Atemzug',
      'duration': '10 Min',
      'description': 'Atme bewusst in der Natur. Rieche Erde, Pflanzen, frische Luft.',
      'benefits': 'Sauerstoffaufnahme, mentale Klarheit, Naturverbindung',
    },
    {
      'emoji': '🪨',
      'name': 'Stein-Meditation',
      'duration': '10 Min',
      'description': 'Halte einen Stein in der Hand. Spüre sein Gewicht und seine Energie.',
      'benefits': 'Stabilität, Fokus, Erdung durch Mineralien',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text('🌍 Erdung-Übungen'),
        backgroundColor: Color(0xFF6D4C41),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6D4C41), Color(0xFF000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // Info Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.nature_people, size: 48, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Grounding-Praktiken',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tippe auf eine Übung für detaillierte Anleitung',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            ..._exercises.map((exercise) => _buildExerciseCard(exercise)),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, String> exercise) {
    final isSelected = _selectedExercise == exercise['name'];
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedExercise = exercise['name'];
        });
        _showExerciseDetails(exercise);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.brown.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.brown : Colors.white24,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(
              exercise['emoji']!,
              style: TextStyle(fontSize: 32),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise['name']!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    exercise['duration']!,
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
  
  void _showExerciseDetails(Map<String, String> exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        title: Row(
          children: [
            Text(exercise['emoji']!, style: TextStyle(fontSize: 32)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                exercise['name']!,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dauer: ${exercise['duration']}',
                style: TextStyle(
                  color: Colors.brown.shade300,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Anleitung:',
                style: TextStyle(
                  color: Colors.brown.shade300,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                exercise['description']!,
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 16),
              Text(
                'Vorteile:',
                style: TextStyle(
                  color: Colors.brown.shade300,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                exercise['benefits']!,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Schließen', style: TextStyle(color: Colors.brown.shade300)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 12. 🦋 TRANSFORMATION-TRACKER SCREEN (VOLLSTÄNDIG)
// ═══════════════════════════════════════════════════════════

class TransformationTrackerScreen extends StatefulWidget {
  const TransformationTrackerScreen({super.key});
  @override
  State<TransformationTrackerScreen> createState() => _TransformationTrackerScreenState();
}

class _TransformationTrackerScreenState extends State<TransformationTrackerScreen> {
  final List<Map<String, dynamic>> _milestones = [
    {
      'title': 'Erste Meditation',
      'date': '2024-01-15',
      'category': 'Meditation',
      'description': 'Erste tiefe Meditationserfahrung - 20 Minuten',
      'level': 1,
    },
    {
      'title': 'Chakra-Öffnung',
      'date': '2024-02-03',
      'category': 'Energie',
      'description': 'Herzchakra-Aktivierung gespürt',
      'level': 2,
    },
    {
      'title': 'Luzider Traum',
      'date': '2024-03-12',
      'category': 'Bewusstsein',
      'description': 'Erster bewusster Traum - Flug-Erlebnis',
      'level': 3,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text('🦋 Transformation-Tracker'),
        backgroundColor: Color(0xFF00796B),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00796B), Color(0xFF000000)],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // Info Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.trending_up, size: 48, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Deine spirituelle Reise',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Dokumentiere wichtige Meilensteine deiner Transformation',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            Text(
              'Bisherige Meilensteine',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            
            ..._milestones.map((milestone) => _buildMilestoneCard(milestone)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Neuer Meilenstein - Feature kommt bald!')),
          );
        },
        backgroundColor: Color(0xFF00796B),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildMilestoneCard(Map<String, dynamic> milestone) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Color(0xFF00796B).withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                'L${milestone['level']}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  milestone['description'],
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${milestone['date']} • ${milestone['category']}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 13. 🌟 LICHTSPRACHE DECODER SCREEN (VOLLSTÄNDIG)
// ═══════════════════════════════════════════════════════════

class LightLanguageDecoderScreen extends StatefulWidget {
  const LightLanguageDecoderScreen({super.key});

  @override
  State<LightLanguageDecoderScreen> createState() => _LightLanguageDecoderScreenState();
}

class _LightLanguageDecoderScreenState extends State<LightLanguageDecoderScreen> {
  String? _selectedCode;
  
  final List<Map<String, String>> _codes = [
    {
      'symbol': '✧',
      'name': 'Stern-Code',
      'meaning': 'Verbindung zur Quelle',
      'activation': 'Visualisiere einen strahlenden Stern über deinem Kronenchakra',
      'frequency': '963 Hz - Einheit',
    },
    {
      'symbol': '◈',
      'name': 'Diamant-Code',
      'meaning': 'Kristallklare Wahrheit',
      'activation': 'Atme weißes Licht ein und fühle kristalline Klarheit',
      'frequency': '852 Hz - Intuition',
    },
    {
      'symbol': '∞',
      'name': 'Unendlichkeit',
      'meaning': 'Ewiges Bewusstsein',
      'activation': 'Zeichne eine liegende Acht in die Luft',
      'frequency': '741 Hz - Bewusstsein',
    },
    {
      'symbol': '☉',
      'name': 'Sonnen-Code',
      'meaning': 'Göttliches Licht',
      'activation': 'Stell dir eine goldene Sonne in deinem Herzen vor',
      'frequency': '528 Hz - Liebe',
    },
    {
      'symbol': '☽',
      'name': 'Mond-Code',
      'meaning': 'Intuitive Weisheit',
      'activation': 'Verbinde dich mit dem Mond und empfange seine Botschaft',
      'frequency': '417 Hz - Veränderung',
    },
    {
      'symbol': '◎',
      'name': 'Kreis-Code',
      'meaning': 'Ganzheit & Vollendung',
      'activation': 'Zeichne einen Kreis um dich herum - du bist geschützt',
      'frequency': '396 Hz - Befreiung',
    },
    {
      'symbol': '△',
      'name': 'Dreieck-Code',
      'meaning': 'Aufstieg & Transformation',
      'activation': 'Visualisiere ein aufwärts zeigendes Dreieck',
      'frequency': '639 Hz - Verbindung',
    },
    {
      'symbol': '✦',
      'name': 'Viereck-Stern',
      'meaning': 'Stabilität in Transformation',
      'activation': 'Erden und gleichzeitig aufsteigen',
      'frequency': '174 Hz - Fundament',
    },
    {
      'symbol': '⚛',
      'name': 'Atom-Code',
      'meaning': 'Schöpfungskraft',
      'activation': 'Erkenne dich als Schöpfer deiner Realität',
      'frequency': '285 Hz - Heilung',
    },
    {
      'symbol': '❂',
      'name': 'Blüten-Code',
      'meaning': 'Entfaltung des Potenzials',
      'activation': 'Öffne dich wie eine Blume dem Licht',
      'frequency': '963 Hz - Erleuchtung',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text('🌟 Lichtsprache Decoder'),
        backgroundColor: Color(0xFFFFA000),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFA000), Color(0xFF000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // Info Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.auto_awesome, size: 48, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Heilige Lichtcodes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tippe auf einen Code für Aktivierungsanleitung',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            ..._codes.map((code) => _buildCodeCard(code)),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeCard(Map<String, String> code) {
    final isSelected = _selectedCode == code['name'];
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCode = code['name'];
        });
        _showCodeDetails(code);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.amber.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.white24,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  code['symbol']!,
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code['name']!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    code['meaning']!,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
  
  void _showCodeDetails(Map<String, String> code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  code['symbol']!,
                  style: TextStyle(fontSize: 28),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                code['name']!,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bedeutung:',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                code['meaning']!,
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 16),
              Text(
                'Aktivierung:',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                code['activation']!,
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 16),
              Text(
                'Frequenz:',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                code['frequency']!,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Schließen', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 14. 🧘‍♀️ YOGA ASANA GUIDE SCREEN (VOLLSTÄNDIG)
// ═══════════════════════════════════════════════════════════

class YogaAsanaGuideScreen extends StatefulWidget {
  const YogaAsanaGuideScreen({super.key});

  @override
  State<YogaAsanaGuideScreen> createState() => _YogaAsanaGuideScreenState();
}

class _YogaAsanaGuideScreenState extends State<YogaAsanaGuideScreen> {
  String? _selectedAsana;
  
  final List<Map<String, String>> _asanas = [
    {
      'name': 'Tadasana',
      'german': 'Berg-Haltung',
      'difficulty': 'Anfänger',
      'benefits': 'Verbessert Haltung & Balance',
      'emoji': '🧍',
      'description': 'Stehe aufrecht mit geschlossenen Füßen. Verteile dein Gewicht gleichmäßig. Strecke die Wirbelsäule und entspanne die Schultern.',
      'chakra': 'Wurzelchakra',
    },
    {
      'name': 'Adho Mukha Svanasana',
      'german': 'Herabschauender Hund',
      'difficulty': 'Anfänger',
      'benefits': 'Stärkt Arme & Beine, dehnt Rücken',
      'emoji': '🐕',
      'description': 'Beginne im Vierfüßlerstand. Hebe das Becken nach oben und strecke die Beine. Bilde ein umgekehrtes V.',
      'chakra': 'Herzchakra',
    },
    {
      'name': 'Vrikshasana',
      'german': 'Baum-Haltung',
      'difficulty': 'Mittelstufe',
      'benefits': 'Balance, Konzentration & Erdung',
      'emoji': '🌳',
      'description': 'Stehe auf einem Bein. Platziere den anderen Fuß an der Innenseite des Oberschenkels. Hände vor der Brust oder nach oben.',
      'chakra': 'Wurzel- und Kronenchakra',
    },
    {
      'name': 'Balasana',
      'german': 'Kind-Haltung',
      'difficulty': 'Anfänger',
      'benefits': 'Tiefe Entspannung & Regeneration',
      'emoji': '🙏',
      'description': 'Knie nieder, setze dich auf die Fersen zurück. Beuge dich nach vorne und lege die Stirn auf den Boden. Arme nach vorne oder seitlich.',
      'chakra': 'Drittes Auge',
    },
    {
      'name': 'Padmasana',
      'german': 'Lotus-Sitz',
      'difficulty': 'Fortgeschritten',
      'benefits': 'Meditation & Flexibilität',
      'emoji': '🪷',
      'description': 'Setze dich aufrecht. Lege einen Fuß auf den gegenüberliegenden Oberschenkel, dann den anderen. Erfordert flexible Hüften.',
      'chakra': 'Kronenchakra',
    },
    {
      'name': 'Savasana',
      'german': 'Leichenstellung',
      'difficulty': 'Alle Stufen',
      'benefits': 'Vollständige Entspannung & Integration',
      'emoji': '😌',
      'description': 'Liege flach auf dem Rücken. Arme und Beine leicht gespreizt. Schließe die Augen und atme ruhig. Lass komplett los.',
      'chakra': 'Alle Chakren',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text('🧘‍♀️ Yoga Asana Guide'),
        backgroundColor: Color(0xFF7B1FA2),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7B1FA2), Color(0xFF000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // Info Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.self_improvement, size: 48, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Klassische Yoga-Positionen',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tippe auf eine Asana für detaillierte Anleitung',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            ..._asanas.map((asana) => _buildAsanaCard(asana)),
          ],
        ),
      ),
    );
  }

  Widget _buildAsanaCard(Map<String, String> asana) {
    final isSelected = _selectedAsana == asana['name'];
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAsana = asana['name'];
        });
        _showAsanaDetails(asana);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.purple.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.white24,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Color(0xFF7B1FA2).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  asana['emoji']!,
                  style: TextStyle(fontSize: 32),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asana['german']!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    asana['name']!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 12, color: Colors.amber),
                      SizedBox(width: 4),
                      Text(
                        asana['difficulty']!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
  
  void _showAsanaDetails(Map<String, String> asana) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        title: Row(
          children: [
            Text(asana['emoji']!, style: TextStyle(fontSize: 32)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asana['german']!,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    asana['name']!,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    'Schwierigkeit: ${asana['difficulty']}',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'Anleitung:',
                style: TextStyle(
                  color: Colors.purple.shade300,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                asana['description']!,
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                'Vorteile:',
                style: TextStyle(
                  color: Colors.purple.shade300,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                asana['benefits']!,
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 16),
              Text(
                'Chakra-Verbindung:',
                style: TextStyle(
                  color: Colors.purple.shade300,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                asana['chakra']!,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Schließen', style: TextStyle(color: Colors.purple.shade300)),
          ),
        ],
      ),
    );
  }
}
class GoddessOracleScreen extends StatefulWidget {
  const GoddessOracleScreen({super.key});
  @override
  State<GoddessOracleScreen> createState() => _GoddessOracleScreenState();
}

class _GoddessOracleScreenState extends State<GoddessOracleScreen> {
  Map<String, dynamic>? _selectedDeity;

  final List<Map<String, dynamic>> _deities = [
    {
      'name': 'Aphrodite',
      'culture': 'Griechisch',
      'domain': 'Liebe & Schönheit',
      'message': 'Öffne dein Herz für die Liebe. Selbstliebe ist der Schlüssel.',
      'color': Color(0xFFE91E63),
    },
    {
      'name': 'Athena',
      'culture': 'Griechisch',
      'domain': 'Weisheit & Strategie',
      'message': 'Vertraue deiner inneren Weisheit. Du kennst die Antwort bereits.',
      'color': Color(0xFF2196F3),
    },
    {
      'name': 'Isis',
      'culture': 'Ägyptisch',
      'domain': 'Magie & Heilung',
      'message': 'Deine Heilkraft ist erwacht. Nutze sie zum Wohle aller.',
      'color': Color(0xFF9C27B0),
    },
    {
      'name': 'Kali',
      'culture': 'Hinduistisch',
      'domain': 'Transformation & Macht',
      'message': 'Lass los, was nicht mehr dient. Transformation ist Befreiung.',
      'color': Color(0xFF000000),
    },
    {
      'name': 'Quan Yin',
      'culture': 'Chinesisch',
      'domain': 'Mitgefühl & Barmherzigkeit',
      'message': 'Sei sanft mit dir selbst. Mitgefühl beginnt im eigenen Herzen.',
      'color': Color(0xFF00BCD4),
    },
    {
      'name': 'Freyja',
      'culture': 'Nordisch',
      'domain': 'Liebe & Krieg',
      'message': 'Kämpfe für das, was du liebst. Wahre Stärke kommt aus dem Herzen.',
      'color': Color(0xFFFF9800),
    },
  ];

  void _drawCard() {
    setState(() {
      _selectedDeity = (_deities..shuffle()).first;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text('🌺 Göttinnen & Götter Orakel'),
        backgroundColor: Color(0xFFE91E63),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE91E63), Color(0xFF000000)],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // Info Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.auto_awesome, size: 48, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Orakel der Gottheiten',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Empfange eine Botschaft von den göttlichen Archetypen',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Draw Button
            Center(
              child: ElevatedButton(
                onPressed: _drawCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE91E63),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Karte ziehen',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Selected Deity Card
            if (_selectedDeity != null)
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _selectedDeity!['color'].withValues(alpha: 0.3),
                      _selectedDeity!['color'].withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedDeity!['color'].withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _selectedDeity!['name'],
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${_selectedDeity!['culture']} • ${_selectedDeity!['domain']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _selectedDeity!['message'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            SizedBox(height: 24),
            
            // Available Deities
            Text(
              'Verfügbare Gottheiten',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            
            ..._deities.map((deity) => Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: deity['color'].withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: deity['color'].withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deity['name'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${deity['culture']} • ${deity['domain']}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 🆕 16. 📅 MOON CALENDAR SCREEN (30-DAY VIEW)
// ═══════════════════════════════════════════════════════════

class MoonCalendarScreen extends StatefulWidget {
  const MoonCalendarScreen({super.key});

  @override
  State<MoonCalendarScreen> createState() => _MoonCalendarScreenState();
}

class _MoonCalendarScreenState extends State<MoonCalendarScreen> {
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('📅 Mondphasen-Kalender'),
        backgroundColor: const Color(0xFF1A237E),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A237E), Color(0xFF000000)],
          ),
        ),
        child: Column(
          children: [
            _buildMonthNavigation(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildCalendarGrid(),
                    const SizedBox(height: 24),
                    if (_selectedDate != null)
                      _buildDayDetails(_selectedDate!),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthNavigation() {
    final monthName = _getMonthName(_currentMonth.month);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(
                  _currentMonth.year,
                  _currentMonth.month - 1,
                );
              });
            },
          ),
          Text(
            '$monthName ${_currentMonth.year}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(
                  _currentMonth.year,
                  _currentMonth.month + 1,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    
    final weekdayOfFirst = firstDayOfMonth.weekday;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildWeekdayHeader(),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.9,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final dayNumber = index - (weekdayOfFirst - 1) + 1;
              
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox();
              }
              
              final date = DateTime(
                _currentMonth.year,
                _currentMonth.month,
                dayNumber,
              );
              
              return _buildDayCell(date);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    const weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays.map((day) {
        return SizedBox(
          width: 40,
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayCell(DateTime date) {
    final moonPhase = _getMoonPhaseForDate(date);
    final isToday = _isSameDay(date, DateTime.now());
    final isSelected = _selectedDate != null && _isSameDay(date, _selectedDate!);
    final isFullMoon = moonPhase['icon'] == '🌕';
    final isNewMoon = moonPhase['icon'] == '🌑';
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
                )
              : isToday
                  ? LinearGradient(
                      colors: [
                        Colors.amber.withValues(alpha: 0.3),
                        Colors.orange.withValues(alpha: 0.3),
                      ],
                    )
                  : null,
          color: !isSelected && !isToday
              ? Colors.white.withValues(alpha: 0.05)
              : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFullMoon || isNewMoon
                ? Colors.yellow.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                color: isSelected || isToday ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: isSelected || isToday
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              moonPhase['icon'] as String,
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayDetails(DateTime date) {
    final moonPhase = _getMoonPhaseForDate(date);
    final dayName = _getDayName(date.weekday);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF283593), Color(0xFF1A237E)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF283593).withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${moonPhase['icon']}',
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$dayName, ${date.day}. ${_getMonthName(date.month)} ${date.year}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      moonPhase['name'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🌟 ENERGIE',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  moonPhase['energy'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (moonPhase['icon'] == '🌕' || moonPhase['icon'] == '🌑') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'RITUAL-EMPFEHLUNG',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    moonPhase['icon'] == '🌕'
                        ? 'Vollmond-Ritual: Manifestation & Dankbarkeit. Zeit für Loslassen-Zeremonien und Energiereinigung.'
                        : 'Neumond-Ritual: Neue Absichten setzen. Zeit für Planung und Innenschau.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Map<String, dynamic> _getMoonPhaseForDate(DateTime date) {
    const lunarCycle = 29.53;
    final knownNewMoon = DateTime(2024, 1, 11);
    final daysSinceKnown = date.difference(knownNewMoon).inDays;
    final phaseDay = daysSinceKnown % lunarCycle;
    
    if (phaseDay < 3.7) {
      return {'icon': '🌑', 'name': 'Neumond', 'energy': 'Neue Anfänge, Innenschau'};
    } else if (phaseDay < 7.4) {
      return {'icon': '🌒', 'name': 'Zunehmende Sichel', 'energy': 'Wachstum beginnen'};
    } else if (phaseDay < 11.1) {
      return {'icon': '🌓', 'name': 'Erstes Viertel', 'energy': 'Aktion & Entscheidung'};
    } else if (phaseDay < 14.8) {
      return {'icon': '🌔', 'name': 'Zunehmender Mond', 'energy': 'Aufbau & Expansion'};
    } else if (phaseDay < 18.5) {
      return {'icon': '🌕', 'name': 'Vollmond', 'energy': 'Höhepunkt & Manifestation'};
    } else if (phaseDay < 22.2) {
      return {'icon': '🌖', 'name': 'Abnehmender Mond', 'energy': 'Dankbarkeit & Reflexion'};
    } else if (phaseDay < 25.9) {
      return {'icon': '🌗', 'name': 'Letztes Viertel', 'energy': 'Loslassen & Reinigung'};
    } else {
      return {'icon': '🌘', 'name': 'Abnehmende Sichel', 'energy': 'Ruhe & Vorbereitung'};
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'
    ];
    return months[month - 1];
  }

  String _getDayName(int weekday) {
    const days = [
      'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag',
      'Freitag', 'Samstag', 'Sonntag'
    ];
    return days[weekday - 1];
  }
}

// ═══════════════════════════════════════════════════════════════
// ♈ ASTROLOGIE-RECHNER - KOMPLETT-SCREEN
// ═══════════════════════════════════════════════════════════════

class AstrologyCalculatorScreen extends StatefulWidget {
  const AstrologyCalculatorScreen({super.key});

  @override
  State<AstrologyCalculatorScreen> createState() => _AstrologyCalculatorScreenState();
}

class _AstrologyCalculatorScreenState extends State<AstrologyCalculatorScreen> {
  DateTime _birthDate = DateTime(1990, 1, 1);
  TimeOfDay _birthTime = const TimeOfDay(hour: 12, minute: 0);
  // UNUSED FIELD: String _birthPlace = 'Berlin';
  
  String? _sunSign;
  String? _moonSign;
  String? _ascendant;
  
  Map<String, String>? _todayHoroscope;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    setState(() {
      _sunSign = _calculateSunSign(_birthDate);
      _moonSign = _calculateMoonSign(_birthDate);
      _ascendant = _calculateAscendant(_birthTime);
      _todayHoroscope = _getTodayHoroscope(_sunSign!);
    });
  }

  String _calculateSunSign(DateTime date) {
    final day = date.day;
    final month = date.month;
    
    // Zodiac sign date ranges
    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return 'Widder ♈';
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return 'Stier ♉';
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return 'Zwillinge ♊';
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return 'Krebs ♋';
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return 'Löwe ♌';
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return 'Jungfrau ♍';
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return 'Waage ♎';
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return 'Skorpion ♏';
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return 'Schütze ♐';
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return 'Steinbock ♑';
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return 'Wassermann ♒';
    return 'Fische ♓';
  }

  String _calculateMoonSign(DateTime date) {
    // Simplified moon sign calculation based on day of year
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    final moonCycle = dayOfYear % 12;
    
    final signs = [
      'Widder ♈', 'Stier ♉', 'Zwillinge ♊', 'Krebs ♋',
      'Löwe ♌', 'Jungfrau ♍', 'Waage ♎', 'Skorpion ♏',
      'Schütze ♐', 'Steinbock ♑', 'Wassermann ♒', 'Fische ♓'
    ];
    
    return signs[moonCycle];
  }

  String _calculateAscendant(TimeOfDay time) {
    // Simplified ascendant calculation based on hour
    final hour = time.hour;
    final signs = [
      'Widder ♈', 'Stier ♉', 'Zwillinge ♊', 'Krebs ♋',
      'Löwe ♌', 'Jungfrau ♍', 'Waage ♎', 'Skorpion ♏',
      'Schütze ♐', 'Steinbock ♑', 'Wassermann ♒', 'Fische ♓'
    ];
    
    return signs[hour % 12];
  }

  Map<String, String> _getTodayHoroscope(String sunSign) {
    // Get current horoscope based on sign
    final horoscopes = {
      'Widder ♈': {
        'today': 'Heute ist ein großartiger Tag für neue Beginne. Deine Energie ist hoch und du fühlst dich bereit für Herausforderungen.',
        'love': 'In der Liebe zeigst du Initiative. Single? Geh raus und lerne neue Menschen kennen.',
        'career': 'Beruflich stehen Türen offen. Nutze deine Führungsqualitäten.',
        'health': 'Deine Energie ist hoch, aber vergiss nicht, Pausen einzulegen.',
      },
      'Stier ♉': {
        'today': 'Stabilität und Sicherheit stehen heute im Fokus. Genieße die kleinen Freuden des Lebens.',
        'love': 'Beziehungen vertiefen sich. Zeige deine zuverlässige Seite.',
        'career': 'Geduld wird belohnt. Bleibe konsequent an deinen Zielen dran.',
        'health': 'Verwöhne deinen Körper mit gesundem Essen und Bewegung.',
      },
      'Zwillinge ♊': {
        'today': 'Kommunikation steht im Mittelpunkt. Du bist gesprächig und neugierig.',
        'love': 'Interessante Gespräche können zu tiefen Verbindungen führen.',
        'career': 'Deine Vielseitigkeit ist gefragt. Networking bringt Erfolg.',
        'health': 'Geistige Aktivität energetisiert dich. Lerne etwas Neues.',
      },
      'Krebs ♋': {
        'today': 'Emotionen sind intensiv. Höre auf dein Herz und deine Intuition.',
        'love': 'Tiefe emotionale Verbindungen entstehen. Familie ist wichtig.',
        'career': 'Deine Empathie macht dich zum idealen Teamplayer.',
        'health': 'Selbstfürsorge ist wichtig. Nimm dir Zeit für dich.',
      },
      'Löwe ♌': {
        'today': 'Du strahlst und ziehst Aufmerksamkeit an. Zeige, was du drauf hast.',
        'love': 'Deine Großzügigkeit macht dich attraktiv. Romance blüht.',
        'career': 'Führungsqualitäten werden anerkannt. Zeit für große Projekte.',
        'health': 'Deine Vitalität ist hoch. Genieße körperliche Aktivitäten.',
      },
      'Jungfrau ♍': {
        'today': 'Details und Organisation sind deine Stärke. Perfektioniere deine Arbeit.',
        'love': 'Praktische Liebe zeigt sich in kleinen Gesten der Fürsorge.',
        'career': 'Deine Analysen sind gefragt. Präzision führt zum Erfolg.',
        'health': 'Achte auf deine Gesundheit. Routinen sind hilfreich.',
      },
      'Waage ♎': {
        'today': 'Balance und Harmonie sind wichtig. Finde das Gleichgewicht.',
        'love': 'Beziehungen gedeihen durch Fairness und Kompromisse.',
        'career': 'Diplomatie bringt beruflichen Erfolg. Vermeide Konflikte.',
        'health': 'Ästhetik und Schönheit nähren deine Seele.',
      },
      'Skorpion ♏': {
        'today': 'Intensität und Transformation prägen den Tag. Gehe tief.',
        'love': 'Leidenschaft entflammt. Intimität wird wichtiger.',
        'career': 'Deine Forscherfähigkeiten führen zu Durchbrüchen.',
        'health': 'Emotionale Heilung ist möglich. Sei ehrlich zu dir.',
      },
      'Schütze ♐': {
        'today': 'Abenteuer ruft! Erweitere deinen Horizont und lerne Neues.',
        'love': 'Optimismus zieht positive Menschen an. Hab Spaß!',
        'career': 'Große Ideen und Vision bringen Erfolg. Denke groß.',
        'health': 'Bewegung und Natur geben dir Energie.',
      },
      'Steinbock ♑': {
        'today': 'Disziplin und Verantwortung zahlen sich aus. Bleibe fokussiert.',
        'love': 'Langfristige Bindungen werden gestärkt. Treue zählt.',
        'career': 'Harte Arbeit wird anerkannt. Karriereziele rücken näher.',
        'health': 'Struktur hilft dir, gesund zu bleiben.',
      },
      'Wassermann ♒': {
        'today': 'Innovation und Originalität zeichnen dich aus. Sei einzigartig.',
        'love': 'Freundschaft ist die Basis für Liebe. Sei authentisch.',
        'career': 'Deine Ideen sind revolutionär. Teile sie mit anderen.',
        'health': 'Gemeinschaft und soziale Kontakte tun gut.',
      },
      'Fische ♓': {
        'today': 'Intuition und Kreativität fließen. Vertraue deinen Träumen.',
        'love': 'Romantik und Fantasie beflügeln die Liebe.',
        'career': 'Deine Empathie macht dich zum idealen Helfer.',
        'health': 'Spirituelle Praktiken nähren deine Seele.',
      },
    };
    
    return horoscopes[sunSign] ?? horoscopes['Widder ♈']!;
  }

  Map<String, dynamic> _getSignDetails(String sign) {
    final details = {
      'Widder ♈': {
        'element': 'Feuer 🔥',
        'planet': 'Mars ♂',
        'strengths': 'Mutig, Entschlossen, Selbstbewusst, Enthusiastisch',
        'weaknesses': 'Ungeduldig, Impulsiv, Aggressiv',
        'color': 0xFFE53935,
      },
      'Stier ♉': {
        'element': 'Erde 🌍',
        'planet': 'Venus ♀',
        'strengths': 'Zuverlässig, Geduldig, Praktisch, Loyal',
        'weaknesses': 'Stur, Besitzergreifend, Unflexibel',
        'color': 0xFF43A047,
      },
      'Zwillinge ♊': {
        'element': 'Luft 💨',
        'planet': 'Merkur ☿',
        'strengths': 'Vielseitig, Kommunikativ, Witzig, Intellektuell',
        'weaknesses': 'Nervös, Unbeständig, Unentschlossen',
        'color': 0xFFFFB300,
      },
      'Krebs ♋': {
        'element': 'Wasser 💧',
        'planet': 'Mond ☽',
        'strengths': 'Fürsorglich, Intuitiv, Emotional, Beschützend',
        'weaknesses': 'launisch, Überempfindlich, Klammernd',
        'color': 0xFF8E24AA,
      },
      'Löwe ♌': {
        'element': 'Feuer 🔥',
        'planet': 'Sonne ☉',
        'strengths': 'Großzügig, Loyal, Energetisch, Humorvoll',
        'weaknesses': 'Arrogant, Stur, Eigenwillig, Eitel',
        'color': 0xFFFFB300,
      },
      'Jungfrau ♍': {
        'element': 'Erde 🌍',
        'planet': 'Merkur ☿',
        'strengths': 'Loyal, Analytisch, Freundlich, Arbeitsam',
        'weaknesses': 'Schüchtern, Sorge, Kritisch, Perfektionistisch',
        'color': 0xFF43A047,
      },
      'Waage ♎': {
        'element': 'Luft 💨',
        'planet': 'Venus ♀',
        'strengths': 'Kooperativ, Diplomatisch, Gerecht, Sozial',
        'weaknesses': 'Unentschlossen, Vermeidet Konflikte, Selbstmitleid',
        'color': 0xFFE91E63,
      },
      'Skorpion ♏': {
        'element': 'Wasser 💧',
        'planet': 'Pluto/Mars ♇♂',
        'strengths': 'Leidenschaftlich, Hartnäckig, Mutig, Loyal',
        'weaknesses': 'Eifersüchtig, Misstrauisch, Manipulativ',
        'color': 0xFF6A1B9A,
      },
      'Schütze ♐': {
        'element': 'Feuer 🔥',
        'planet': 'Jupiter ♃',
        'strengths': 'Großzügig, Idealistisch, Humorvoll',
        'weaknesses': 'Verspricht zu viel, Sehr ungeduldig, Taktlos',
        'color': 0xFFEF6C00,
      },
      'Steinbock ♑': {
        'element': 'Erde 🌍',
        'planet': 'Saturn ♄',
        'strengths': 'Verantwortlich, Diszipliniert, Selbstkontrolliert',
        'weaknesses': 'Unversöhnlich, Herablassend, Pessimistisch',
        'color': 0xFF5D4037,
      },
      'Wassermann ♒': {
        'element': 'Luft 💨',
        'planet': 'Uranus/Saturn ♅♄',
        'strengths': 'Progressiv, Original, Unabhängig, Humanitär',
        'weaknesses': 'Distanziert, Temperamentvoll, Unflexibel',
        'color': 0xFF1976D2,
      },
      'Fische ♓': {
        'element': 'Wasser 💧',
        'planet': 'Neptun/Jupiter ♆♃',
        'strengths': 'Mitfühlend, Künstlerisch, Intuitiv, Sanft',
        'weaknesses': 'Ängstlich, Überempfindlich, Traurig, Opferrolle',
        'color': 0xFF00897B,
      },
    };
    
    return details[sign] ?? details['Widder ♈']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('♈ Astrologie-Rechner'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1976D2), Color(0xFF000000)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Input Card
            _buildInputCard(),
            
            const SizedBox(height: 20),
            
            // Results
            if (_sunSign != null) ...[
              _buildSignCard('Sternzeichen (Sonne)', _sunSign!),
              const SizedBox(height: 16),
              _buildSignCard('Mondzeichen', _moonSign!),
              const SizedBox(height: 16),
              _buildSignCard('Aszendent', _ascendant!),
              const SizedBox(height: 20),
              _buildHoroscopeCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1976D2).withValues(alpha: 0.3),
              const Color(0xFF1E1E1E),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF1976D2).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Geburtsdaten',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Date Picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: Colors.white70),
              title: const Text(
                'Geburtsdatum',
                style: TextStyle(color: Colors.white70),
              ),
              subtitle: Text(
                '${_birthDate.day}.${_birthDate.month}.${_birthDate.year}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _birthDate,
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _birthDate = date;
                  });
                  _calculate();
                }
              },
            ),
            
            const Divider(color: Colors.white24),
            
            // Time Picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time, color: Colors.white70),
              title: const Text(
                'Geburtszeit',
                style: TextStyle(color: Colors.white70),
              ),
              subtitle: Text(
                '${_birthTime.hour.toString().padLeft(2, '0')}:${_birthTime.minute.toString().padLeft(2, '0')} Uhr',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _birthTime,
                );
                if (time != null) {
                  setState(() {
                    _birthTime = time;
                  });
                  _calculate();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignCard(String title, String sign) {
    final details = _getSignDetails(sign);
    
    return Card(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(details['color']).withValues(alpha: 0.3),
              const Color(0xFF1E1E1E),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color(details['color']).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sign,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildDetailRow('Element', details['element']),
            const SizedBox(height: 8),
            _buildDetailRow('Planet', details['planet']),
            const SizedBox(height: 8),
            _buildDetailRow('Stärken', details['strengths']),
            const SizedBox(height: 8),
            _buildDetailRow('Schwächen', details['weaknesses']),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHoroscopeCard() {
    if (_todayHoroscope == null) return const SizedBox();
    
    return Card(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF6A1B9A),
              Color(0xFF1E1E1E),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF6A1B9A).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔮 Tages-Horoskop',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            _buildHoroscopeSection('💫 Heute', _todayHoroscope!['today']!),
            const SizedBox(height: 16),
            _buildHoroscopeSection('❤️ Liebe', _todayHoroscope!['love']!),
            const SizedBox(height: 16),
            _buildHoroscopeSection('💼 Karriere', _todayHoroscope!['career']!),
            const SizedBox(height: 16),
            _buildHoroscopeSection('🏥 Gesundheit', _todayHoroscope!['health']!),
          ],
        ),
      ),
    );
  }

  Widget _buildHoroscopeSection(String title, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 🎵 FREQUENZ-GENERATOR - HEALING FREQUENCIES
// ═══════════════════════════════════════════════════════════════

