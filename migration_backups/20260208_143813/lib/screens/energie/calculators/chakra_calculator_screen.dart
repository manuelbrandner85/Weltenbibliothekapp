import 'package:flutter/material.dart';
import '../../../models/energie_profile.dart';
import '../../../services/storage_service.dart';
import '../../../services/spirit_calculations/chakra_engine.dart';
import '../../../widgets/profile_required_widget.dart';
import '../../widgets/universal_edit_wrapper.dart';
import '../../services/universal_content_service.dart';

/// 🌈 CHAKRA-RECHNER SCREEN
class ChakraCalculatorScreen extends StatefulWidget {
  const ChakraCalculatorScreen({super.key});

  @override
  State<ChakraCalculatorScreen> createState() => _ChakraCalculatorScreenState();
}

class _ChakraCalculatorScreenState extends State<ChakraCalculatorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  EnergieProfile? _profile;
  bool _isLoading = true;

  Map<int, int> _chakraScores = {};
  Map<String, dynamic>? _dominantChakra;  // ⚠️ UNUSED - For future UI enhancement
  Map<String, dynamic>? _blockedChakra;   // ⚠️ UNUSED - For future UI enhancement
  int _overallBalance = 0;
  List<String> _recommendations = [];
  
  // Tagebuch-State
  List<Map<String, dynamic>> _journalEntries = [];
  final TextEditingController _noteController = TextEditingController();
  
  // 🚀 BALANCE TRACKER STATE (v44.1.0)
  Map<String, dynamic>? _todayScores;
  List<Map<String, dynamic>> _scoreHistory = [];
  bool _isLoadingTracker = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // 🚀 5 Tabs jetzt (inkl. Balance Tracker)
    _loadProfile();
    _loadJournalEntries();
    _loadBalanceTracker();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = StorageService().getEnergieProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        if (_profile != null) {
          _calculateChakras();
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _calculateChakras() {
    if (_profile == null) return;
    
    final lifePathNumber = _profile!.birthDate.day + _profile!.birthDate.month + _profile!.birthDate.year;
    final reducedLifePath = _reduceToSingleDigit(lifePathNumber);

    _chakraScores = ChakraEngine.calculateChakraScores(
      _profile!.firstName,
      _profile!.lastName,
      _profile!.birthDate,
      reducedLifePath,
    );

    _dominantChakra = ChakraEngine.calculateDominantChakra(reducedLifePath);
    _blockedChakra = ChakraEngine.calculateBlockedChakra(reducedLifePath + 3);
    _overallBalance = ChakraEngine.calculateOverallBalance(_chakraScores);
    
    _recommendations = ChakraEngine.generateBalanceRecommendations(
      _chakraScores,
      ((reducedLifePath - 1) % 7) + 1,
      ((reducedLifePath + 2) % 7) + 1,
    );
  }

  int _reduceToSingleDigit(int number) {
    while (number > 9) {
      number = number.toString().split('').map(int.parse).reduce((a, b) => a + b);
    }
    return number;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_getContent('text.element_1', 'CHAKRA-ANALYSE')), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A148C), Color(0xFF1A1A2E)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _profile == null
                  ? ProfileRequiredWidget(
                      worldType: 'energie',
                      message: 'Energie-Profil erforderlich',
                      onProfileCreated: _loadProfile,
                    )
                  : Column(
                      children: [
                        _buildProfileHeader(),
                        _buildTabBar(),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildChakraScoresTab(),
                              _buildBalanceTab(),
                              _buildBalanceTrackerTab(), // 🚀 NEUER TAB (v44.1.0)
                              _buildAllChakrasTab(),
                              _buildJournalTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF4A148C)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: const Icon(Icons.spa, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_profile!.firstName} ${_profile!.lastName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Balance: $_overallBalance/100', style: const TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFFE91E63)]), borderRadius: BorderRadius.circular(12)),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        tabs: const [Tab(text: 'SCORES'), Tab(text: 'BALANCE'), Tab(text: 'TRACKER'), Tab(text: 'ALLE 7'), Tab(text: 'TAGEBUCH')],
      ),
    );
  }

  Widget _buildChakraScoresTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: _chakraScores.entries.map((entry) {
          final chakra = ChakraEngine.getAllChakras()[entry.key];
          if (chakra == null) return const SizedBox();
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [(chakra['color'] as Color).withValues(alpha: 0.3), const Color(0xFF1E1E1E)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: chakra['color'] as Color, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(color: chakra['color'] as Color, shape: BoxShape.circle),
                      child: Center(child: Text('${entry.key}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(chakra['name'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text(chakra['sanskritName'] as String, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                        ],
                      ),
                    ),
                    Text('${entry.value}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: entry.value / 100,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(chakra['color'] as Color),
                  minHeight: 8,
                ),
                const SizedBox(height: 12),
                Text('🎯 ${chakra['theme']}', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 6),
                Text('🔊 Mantra: ${chakra['mantra']} · ${chakra['frequency']} Hz', style: const TextStyle(fontSize: 12, color: Color(0xFFCE93D8))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBalanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF1E1E1E)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getContent('text.element_2', 'GESAMT-BALANCE')), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFFD700), letterSpacing: 1.5)),
                const SizedBox(height: 16),
                Text('$_overallBalance / 100', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: _overallBalance / 100, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)), minHeight: 8),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.3))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getContent('text.element_3', 'EMPFEHLUNGEN')), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFFD700), letterSpacing: 1.5)),
                const SizedBox(height: 16),
                ..._recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(rec, style: const TextStyle(fontSize: 14, color: Colors.white70))),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllChakrasTab() {
    final allChakras = ChakraEngine.getAllChakras();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_getContent('text.element_4', 'ALLE 7 CHAKREN')), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFD700), letterSpacing: 1.5)),
          const SizedBox(height: 16),
          ...allChakras.entries.map((entry) {
            final chakra = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: chakra['color'] as Color, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: chakra['color'] as Color, shape: BoxShape.circle),
                        child: Center(child: Text('${entry.key}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(chakra['name'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text(chakra['sanskritName'] as String, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('📍 ${chakra['location']}', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                  Text('🎯 ${chakra['theme']}', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                  Text('💚 ${chakra['affirmation']}', style: const TextStyle(fontSize: 13, color: Color(0xFFCE93D8), fontStyle: FontStyle.italic)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 🆕 CHAKRA-TAGEBUCH TAB
  Widget _buildJournalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildSectionHeader(
            'CHAKRA-TAGEBUCH',
            '30-Tage Balance-Tracking',
            Icons.book,
          ),
          const SizedBox(height: 20),
          
          // Neuen Eintrag hinzufügen
          _buildAddEntryCard(),
          const SizedBox(height: 24),
          
          // Fortschritts-Grafik
          if (_journalEntries.isNotEmpty) ...[
            _buildProgressChart(),
            const SizedBox(height: 24),
          ],
          
          // Tagebuch-Einträge
          _buildSectionHeader(
            'DEINE EINTRÄGE',
            '${_journalEntries.length} Einträge',
            Icons.list,
          ),
          const SizedBox(height: 16),
          
          if (_journalEntries.isEmpty)
            _buildEmptyJournalState()
          else
            ..._journalEntries.map((entry) => _buildJournalEntry(entry)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddEntryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NEUER EINTRAG',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          
          // Chakra-Scores für heute
          const Text(
            'Wie fühlst du dich heute?',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          
          // Schnell-Bewertung für jedes Chakra
          ..._chakraScores.entries.map((entry) {
            final chakra = ChakraEngine.getAllChakras()[entry.key];
            if (chakra == null) return const SizedBox();
            return _buildChakraQuickRating(entry.key, chakra);
          }),
          
          const SizedBox(height: 16),
          
          // Notiz-Feld
          TextField(
            controller: _noteController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Notizen zu deiner Chakra-Arbeit heute...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Speichern-Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveJournalEntry,
              icon: const Icon(Icons.save),
              label: Text(_getContent('text.element_5', 'EINTRAG SPEICHERN'))),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _tempRatings = 0; // Temporary storage for ratings

  Widget _buildChakraQuickRating(int chakraIndex, Map<String, dynamic> chakra) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: chakra['color'] as Color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              chakra['name'] as String,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          // Einfache Rating-Stars
          ...List.generate(5, (index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _tempRatings = index + 1;
                });
              },
              child: Icon(
                index < (_tempRatings)
                    ? Icons.star
                    : Icons.star_border,
                color: Colors.amber,
                size: 20,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyJournalState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_stories,
            size: 64,
            color: Colors.purple.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Noch keine Einträge',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Beginne dein Chakra-Tracking mit deinem ersten Eintrag',
            style: TextStyle(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart() {
    // Letzten 7 Tage Durchschnitts-Balance
    final last7Days = _journalEntries.take(7).toList();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade900, Colors.purple.shade700],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FORTSCHRITT (7 TAGE)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          
          // Einfache Balken-Grafik
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: last7Days.reversed.map((entry) {
                final balance = entry['balance'] as int? ?? 50;
                final height = (balance / 100) * 120;
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$balance%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 30,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.purple,
                            Colors.pink,
                            Colors.amber,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatShortDate(entry['date'] as DateTime),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalEntry(Map<String, dynamic> entry) {
    final date = entry['date'] as DateTime;
    final balance = entry['balance'] as int? ?? 0;
    final note = entry['note'] as String? ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatFullDate(date),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getBalanceColor(balance).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getBalanceColor(balance)),
                ),
                child: Text(
                  '$balance% Balance',
                  style: TextStyle(
                    color: _getBalanceColor(balance),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              note,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Hilfsmethoden
  Future<void> _loadJournalEntries() async {
    // Lade Einträge aus SharedPreferences oder lokaler Datenbank
    final storage = StorageService();
    final entries = await storage.getChakraJournalEntries();
    setState(() {
      _journalEntries = entries;
    });
  }

  void _saveJournalEntry() {
    if (_profile == null) return;
    
    final newEntry = {
      'date': DateTime.now(),
      'balance': _overallBalance,
      'note': _noteController.text,
      'chakraScores': Map<String, int>.from(_chakraScores),
    };
    
    setState(() {
      _journalEntries.insert(0, newEntry);
      _noteController.clear();
      _tempRatings = 0;
    });
    
    // Speichere in SharedPreferences
    StorageService().saveChakraJournalEntry(newEntry);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Eintrag gespeichert'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatShortDate(DateTime date) {
    return '${date.day}.${date.month}';
  }

  String _formatFullDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
    return '${date.day}. ${months[date.month - 1]} ${date.year}';
  }

  Color _getBalanceColor(int balance) {
    if (balance >= 80) return Colors.green;
    if (balance >= 60) return Colors.amber;
    return Colors.red;
  }
  
  Color _getChakraColor(int chakraNumber) {
    const colors = {
      1: Color(0xFFE74C3C), // Rot - Wurzel
      2: Color(0xFFE67E22), // Orange - Sakral
      3: Color(0xFFF39C12), // Gelb - Solarplexus
      4: Color(0xFF27AE60), // Grün - Herz
      5: Color(0xFF3498DB), // Blau - Hals
      6: Color(0xFF8E44AD), // Indigo - Stirn
      7: Color(0xFF9B59B6), // Violett - Krone
    };
    return colors[chakraNumber] ?? const Color(0xFF9C27B0);
  }
  
  // ════════════════════════════════════════════════════════════════
  // 🚀 BALANCE TRACKER METHODS (v44.1.0)
  // ════════════════════════════════════════════════════════════════
  
  /// Balance Tracker Daten laden
  Future<void> _loadBalanceTracker() async {
    setState(() => _isLoadingTracker = true);
    
    try {
      // Lade heutige Scores
      _todayScores = StorageService().getChakraDailyScores(DateTime.now());
      
      // Lade History (letzte 30 Tage)
      _scoreHistory = StorageService().getChakraHistory(30);
      
      setState(() {});
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
      setState(() => _isLoadingTracker = false);
    }
  }
  
  /// Heutige Chakra Scores speichern
  Future<void> _saveTodayScores(Map<int, int> scores) async {
    final today = DateTime.now();
    final dateStr = today.toIso8601String().split('T')[0];
    
    final scoresData = {
      'date': dateStr,
      'scores': scores.map((key, value) => MapEntry(key.toString(), value)),
      'overallBalance': _overallBalance,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await StorageService().saveChakraDailyScores(scoresData);
    await _loadBalanceTracker();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Scores gespeichert!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  /// Balance Tracker Tab bauen
  Widget _buildBalanceTrackerTab() {
    if (_isLoadingTracker) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF9C27B0)),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF9C27B0).withValues(alpha: 0.3),
                  const Color(0xFF1E1E1E),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF9C27B0).withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.trending_up, color: Color(0xFF9C27B0), size: 32),
                    SizedBox(width: 12),
                    Text(
                      'CHAKRA BALANCE TRACKER',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9C27B0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Verfolge deine tägliche Chakra-Balance',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Heutige Balance
                if (_todayScores != null) ...[
                  const Text(
                    'HEUTIGE BALANCE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9C27B0),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${_todayScores!['overallBalance']}%',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _getBalanceColor(_todayScores!['overallBalance'] as int),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        (_todayScores!['overallBalance'] as int) >= 80
                            ? Icons.check_circle
                            : (_todayScores!['overallBalance'] as int) >= 60
                                ? Icons.warning_amber
                                : Icons.error,
                        color: _getBalanceColor(_todayScores!['overallBalance'] as int),
                        size: 32,
                      ),
                    ],
                  ),
                ] else ...[
                  const Text(
                    'NOCH KEINE SCORES HEUTE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white60,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_chakraScores.isNotEmpty) {
                        _saveTodayScores(_chakraScores);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bitte berechne zuerst deine Chakra-Scores im SCORES Tab'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: Text(_getContent('text.element_9', 'Heutige Scores speichern'))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C27B0),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // History Section
          const Text(
            '📊 VERLAUF (30 TAGE)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_scoreHistory.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Noch keine History vorhanden.\nSpeichere täglich deine Scores!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60),
                ),
              ),
            )
          else
            ..._scoreHistory.map((entry) => _buildHistoryCard(entry)),
          
          const SizedBox(height: 24),
          
          // Stats Overview
          if (_scoreHistory.isNotEmpty) ...[
            const Text(
              '📈 STATISTIKEN',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatsOverview(),
          ],
        ],
      ),
    );
  }
  
  /// History Card
  Widget _buildHistoryCard(Map<String, dynamic> entry) {
    final date = DateTime.parse(entry['date'] as String);
    final overallBalance = entry['overallBalance'] as int;
    final scores = Map<String, dynamic>.from(entry['scores'] as Map);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBalanceColor(overallBalance).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: _getBalanceColor(overallBalance),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _formatFullDate(date),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getBalanceColor(overallBalance),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getBalanceColor(overallBalance).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getBalanceColor(overallBalance),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '$overallBalance%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getBalanceColor(overallBalance),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Chakra Scores Mini-Viz
          Row(
            children: List.generate(7, (index) {
              final chakraNum = index + 1;
              final score = scores[chakraNum.toString()] as int? ?? 0;
              final color = _getChakraColor(chakraNum);
              
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color,
                              color.withValues(alpha: 0.5),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            score.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chakraNum.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: color.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
  
  /// Stats Overview
  Widget _buildStatsOverview() {
    if (_scoreHistory.isEmpty) return const SizedBox();
    
    // Berechne Stats
    final allBalances = _scoreHistory
        .map((e) => e['overallBalance'] as int)
        .toList();
    
    final avgBalance = allBalances.reduce((a, b) => a + b) ~/ allBalances.length;
    final maxBalance = allBalances.reduce((a, b) => a > b ? a : b);
    final minBalance = allBalances.reduce((a, b) => a < b ? a : b);
    final totalDays = _scoreHistory.length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF9C27B0).withValues(alpha: 0.2),
            const Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatItem('Durchschnitt', '$avgBalance%', Icons.analytics),
              _buildStatItem('Maximum', '$maxBalance%', Icons.arrow_upward),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem('Minimum', '$minBalance%', Icons.arrow_downward),
              _buildStatItem('Tage erfasst', totalDays.toString(), Icons.event),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Stat Item
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF9C27B0), size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
