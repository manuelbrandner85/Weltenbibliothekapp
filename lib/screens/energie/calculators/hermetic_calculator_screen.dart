import 'package:flutter/material.dart';
import '../../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../../../models/energie_profile.dart';
import '../../../services/storage_service.dart';
import '../../../services/spirit_calculations/hermetic_engine.dart';
import '../../../widgets/profile_required_widget.dart';

/// 📜 HERMETIK-RECHNER SCREEN
class HermeticCalculatorScreen extends StatefulWidget {
  const HermeticCalculatorScreen({super.key});

  @override
  State<HermeticCalculatorScreen> createState() => _HermeticCalculatorScreenState();
}

class _HermeticCalculatorScreenState extends State<HermeticCalculatorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  EnergieProfile? _profile;
  bool _isLoading = true;

  Map<int, int> _principleScores = {};
  Map<String, dynamic>? _dominantPrinciple;
  Map<String, dynamic>? _weakPrinciple;
  int _masteryLevel = 0;
  int _balanceScore = 0;
  List<String> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        _calculateHermetic();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _calculateHermetic() {
    if (_profile == null) return;
    
    final lifePathNumber = _reduceToSingleDigit(_profile!.birthDate.day + _profile!.birthDate.month + _profile!.birthDate.year);
// UNUSED: final expressionNumber = _reduceToSingleDigit(_profile!.firstName.length + _profile!.lastName.length);

    _principleScores = HermeticEngine.calculatePrincipleScores(
      _profile!.firstName,
      _profile!.lastName,
      _profile!.birthDate,
      lifePathNumber,
    );

    _dominantPrinciple = HermeticEngine.calculateDominantPrinciple(lifePathNumber);
    _weakPrinciple = HermeticEngine.calculateWeakPrinciple(lifePathNumber + 3);
    _masteryLevel = HermeticEngine.calculateMasteryLevel(_principleScores);
    _balanceScore = HermeticEngine.calculateHermeticBalance(_principleScores);
    
    _recommendations = HermeticEngine.generatePracticeRecommendations(
      _dominantPrinciple!,
      _weakPrinciple!,
      _principleScores,
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
        title: const Text('HERMETIK - DAS KYBALION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
                              _buildPrinciplesTab(),
                              _buildMasteryTab(),
                              _buildAllPrinciplesTab(),
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
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_profile!.firstName} ${_profile!.lastName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Meisterschaft: $_masteryLevel/100', style: const TextStyle(fontSize: 14, color: Colors.white70)),
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
        tabs: const [Tab(text: 'PRINZIPIEN'), Tab(text: 'MEISTERSCHAFT'), Tab(text: 'ALLE 7')],
      ),
    );
  }

  Widget _buildPrinciplesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: _principleScores.entries.map((entry) {
          final principle = HermeticEngine.getAllPrinciples()[entry.key];
          if (principle == null) return const SizedBox();
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [(principle['color'] as Color).withValues(alpha: 0.3), const Color(0xFF1E1E1E)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: principle['color'] as Color, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(color: principle['color'] as Color, shape: BoxShape.circle),
                      child: Center(child: Text('${entry.key}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(principle['name'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text(principle['originalName'] as String, style: const TextStyle(fontSize: 12, color: Colors.white54)),
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
                  valueColor: AlwaysStoppedAnimation<Color>(principle['color'] as Color),
                  minHeight: 8,
                ),
                const SizedBox(height: 12),
                Text('📜 "${principle['axiom']}"', style: const TextStyle(fontSize: 13, color: Color(0xFFFFD700), fontStyle: FontStyle.italic)),
                const SizedBox(height: 8),
                Text('✨ ${principle['application']}', style: const TextStyle(fontSize: 13, color: Colors.white70)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMasteryTab() {
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
                const Text('MEISTERSCHAFTS-LEVEL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFFD700), letterSpacing: 1.5)),
                const SizedBox(height: 16),
                Text('$_masteryLevel / 100', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: _masteryLevel / 100, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)), minHeight: 8),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFF1E1E1E)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BALANCE-SCORE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFFD700), letterSpacing: 1.5)),
                const SizedBox(height: 16),
                Text('$_balanceScore / 100', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: _balanceScore / 100, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)), minHeight: 8),
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
                const Text('PRAXIS-EMPFEHLUNGEN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFFD700), letterSpacing: 1.5)),
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

  Widget _buildAllPrinciplesTab() {
    final allPrinciples = HermeticEngine.getAllPrinciples();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DIE 7 HERMETISCHEN PRINZIPIEN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFD700), letterSpacing: 1.5)),
          const SizedBox(height: 16),
          ...allPrinciples.entries.map((entry) {
            final principle = entry.value;
            final score = _principleScores[entry.key] ?? 0;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: principle['color'] as Color, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: principle['color'] as Color, shape: BoxShape.circle),
                        child: Center(child: Text('${entry.key}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(principle['name'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text(principle['originalName'] as String, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                          ],
                        ),
                      ),
                      Text('$score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('"${principle['axiom']}"', style: const TextStyle(fontSize: 13, color: Color(0xFFFFD700), fontStyle: FontStyle.italic)),
                  const SizedBox(height: 6),
                  Text('🎯 ${principle['description']}', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                  Text('🧘 Praxis: ${principle['practice']}', style: const TextStyle(fontSize: 12, color: Color(0xFFCE93D8))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
