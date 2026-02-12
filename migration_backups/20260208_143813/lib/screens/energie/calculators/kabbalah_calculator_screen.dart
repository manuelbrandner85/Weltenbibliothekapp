import 'package:flutter/material.dart';
import '../../../models/energie_profile.dart';
import '../../../services/storage_service.dart';
import '../../../services/spirit_calculations/kabbalah_engine.dart';
import '../../../widgets/profile_required_widget.dart';
import '../../widgets/universal_edit_wrapper.dart';
import '../../services/universal_content_service.dart';

/// 🌳 KABBALA-RECHNER SCREEN
class KabbalahCalculatorScreen extends StatefulWidget {
  const KabbalahCalculatorScreen({super.key});

  @override
  State<KabbalahCalculatorScreen> createState() => _KabbalahCalculatorScreenState();
}

class _KabbalahCalculatorScreenState extends State<KabbalahCalculatorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  EnergieProfile? _profile;
  bool _isLoading = true;

  Map<int, int> _sephirothScores = {};
  Map<String, dynamic>? _personalSephira;
  Map<String, dynamic>? _developmentSephira;
  Map<String, dynamic>? _blockedSephira;
  Map<String, int> _pillarBalance = {};
  Map<String, int> _worldsDistribution = {};
  List<String> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = StorageService().getEnergieProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        if (_profile != null) {
          _calculateKabbalah();
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _calculateKabbalah() {
    if (_profile == null) return;
    
    final lifePathNumber = _reduceToSingleDigit(_profile!.birthDate.day + _profile!.birthDate.month + _profile!.birthDate.year);
    final expressionNumber = _reduceToSingleDigit(_profile!.firstName.length + _profile!.lastName.length);

    _sephirothScores = KabbalahEngine.calculateSephirothScores(
      _profile!.firstName,
      _profile!.lastName,
      _profile!.birthDate,
      lifePathNumber,
    );

    _personalSephira = KabbalahEngine.calculatePersonalSephira(lifePathNumber);
    _developmentSephira = KabbalahEngine.calculateDevelopmentSephira(expressionNumber);
    _blockedSephira = KabbalahEngine.calculateBlockedSephira(lifePathNumber + 3);
    
    _pillarBalance = KabbalahEngine.calculatePillarBalance(_sephirothScores);
    _worldsDistribution = KabbalahEngine.calculateWorldsDistribution(_sephirothScores);
    
    _recommendations = KabbalahEngine.generatePathworkRecommendations(
      _personalSephira!,
      _blockedSephira!,
      _sephirothScores,
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
        title: Text(_getContent('text.element_1', 'KABBALA - BAUM DES LEBENS')), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
                              _buildSephirothTab(),
                              _buildPillarsTab(),
                              _buildWorldsTab(),
                              _buildAllSephirothTab(),
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
            child: const Icon(Icons.account_tree, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_profile!.firstName} ${_profile!.lastName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Sephira: ${_personalSephira?['name'] ?? 'Unbekannt'}', style: const TextStyle(fontSize: 14, color: Colors.white70)),
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
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        tabs: const [Tab(text: 'SEPHIROTH'), Tab(text: 'SÄULEN'), Tab(text: 'WELTEN'), Tab(text: 'ALLE 10')],
      ),
    );
  }

  Widget _buildSephirothTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSephiraCard(_personalSephira!, 'PERSÖNLICHE SEPHIRA', isPersonal: true),
          const SizedBox(height: 16),
          _buildSephiraCard(_developmentSephira!, 'ENTWICKLUNGS-SEPHIRA'),
          const SizedBox(height: 16),
          _buildSephiraCard(_blockedSephira!, 'BLOCKIERTE SEPHIRA', isBlocked: true),
        ],
      ),
    );
  }

  Widget _buildSephiraCard(Map<String, dynamic> sephira, String label, {bool isPersonal = false, bool isBlocked = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [(sephira['color'] as Color).withValues(alpha: 0.3), const Color(0xFF1E1E1E)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sephira['color'] as Color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: sephira['color'] as Color, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: sephira['color'] as Color, shape: BoxShape.circle),
                child: Center(child: Icon(isPersonal ? Icons.star : isBlocked ? Icons.lock : Icons.circle, color: Colors.white, size: 32)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sephira['name'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(sephira['germanName'] as String, style: const TextStyle(fontSize: 14, color: Colors.white54)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('📖 ${sephira['meaning']}', style: const TextStyle(fontSize: 14, color: Colors.white70)),
          const SizedBox(height: 8),
          Text('🎯 ${sephira['attribute']}', style: const TextStyle(fontSize: 14, color: Colors.white70)),
          const SizedBox(height: 8),
          Text('💚 Tugend: ${sephira['virtue']}', style: const TextStyle(fontSize: 13, color: Color(0xFF4CAF50))),
          const SizedBox(height: 8),
          Text('⚠️ Laster: ${sephira['vice']}', style: const TextStyle(fontSize: 13, color: Color(0xFFE91E63))),
        ],
      ),
    );
  }

  Widget _buildPillarsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_getContent('text.element_2', 'SÄULEN-BALANCE')), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFD700), letterSpacing: 1.5)),
          const SizedBox(height: 16),
          ..._pillarBalance.entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('${entry.value}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: entry.value / 100,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)),
                    minHeight: 8,
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.3)),
            ),
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

  Widget _buildWorldsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_getContent('text.element_4', '4 WELTEN DER KABBALA')), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFD700), letterSpacing: 1.5)),
          const SizedBox(height: 16),
          ..._worldsDistribution.entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('${entry.value}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: entry.value / 100,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)),
                    minHeight: 8,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAllSephirothTab() {
    final allSephiroth = KabbalahEngine.getAllSephiroth();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_getContent('text.element_5', 'ALLE 10 SEPHIROTH')), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFD700), letterSpacing: 1.5)),
          const SizedBox(height: 16),
          ...allSephiroth.entries.map((entry) {
            final sephira = entry.value;
            final score = _sephirothScores[entry.key] ?? 0;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sephira['color'] as Color, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: sephira['color'] as Color, shape: BoxShape.circle),
                        child: Center(child: Text('${entry.key}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sephira['name'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text(sephira['germanName'] as String, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                          ],
                        ),
                      ),
                      Text('$score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${sephira['meaning']}', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                  Text('🏛️ ${sephira['pillar']}', style: const TextStyle(fontSize: 12, color: Color(0xFFCE93D8))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
