import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../models/energie_profile.dart';
import '../../../services/storage_service.dart';
import '../../../services/spirit_calculations/archetype_engine.dart';
import '../../../widgets/profile_required_widget.dart';
import '../../../services/spirit_calculations/numerology_engine.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';

/// 🎭 ARCHETYPEN-ANALYSE SCREEN
///
/// Basiert auf C.G. Jung's 12 Archetypen
/// - Primär-Archetyp (Lebenszahl)
/// - Sekundär-Archetyp (Ausdruckszahl)
/// - Schatten-Archetyp (Gegenüber)
/// - Aktivierungs-Archetyp (Persönliches Jahr)
class ArchetypeCalculatorScreen extends StatefulWidget {
  const ArchetypeCalculatorScreen({super.key});

  @override
  State<ArchetypeCalculatorScreen> createState() =>
      _ArchetypeCalculatorScreenState();
}

class _ArchetypeCalculatorScreenState extends State<ArchetypeCalculatorScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  EnergieProfile? _profile;
  bool _isLoading = true;

  // Berechnete Daten
  Map<String, dynamic>? _primaryArchetype;
  Map<String, dynamic>? _secondaryArchetype;
  Map<String, dynamic>? _shadowArchetype;
  Map<String, dynamic>? _activationArchetype;
  int _integrationScore = 0;
  Map<String, int> _elementDistribution = {};
  List<String> _recommendations = [];

  // Cinematic animation controllers
  late AnimationController _bgCtrl;
  late AnimationController _mandalaCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProfile();

    _bgCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat(reverse: true);
    _mandalaCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bgCtrl.dispose();
    _mandalaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = StorageService().getEnergieProfile();
      if (!mounted) return;

      setState(() {
        _profile = profile;
        _calculateArchetypes();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _calculateArchetypes() {
    if (_profile == null) return;

    // Berechne numerologische Basis-Zahlen
    final lifePathNumber =
        NumerologyEngine.calculateLifePath(_profile!.birthDate);
    final expressionNumber = NumerologyEngine.calculateExpressionNumber(
      _profile!.firstName,
      _profile!.lastName,
    );
    final personalYear = NumerologyEngine.calculatePersonalYear(
      _profile!.birthDate,
      DateTime.now(),
    );

    // Berechne Archetypen
    _primaryArchetype =
        ArchetypeEngine.calculatePrimaryArchetype(lifePathNumber);
    _secondaryArchetype =
        ArchetypeEngine.calculateSecondaryArchetype(expressionNumber);
    _shadowArchetype = ArchetypeEngine.calculateShadowArchetype(lifePathNumber);
    _activationArchetype =
        ArchetypeEngine.calculateActivationArchetype(personalYear);

    // Berechne Integration Score
    _integrationScore = ArchetypeEngine.calculateIntegrationScore(
      _primaryArchetype!,
      _secondaryArchetype!,
      _shadowArchetype!,
    );

    // Berechne Element-Verteilung
    _elementDistribution = ArchetypeEngine.calculateElementDistribution(
      _primaryArchetype!,
      _secondaryArchetype!,
      _shadowArchetype!,
      _activationArchetype!,
    );

    // Generiere Empfehlungen
    _recommendations = ArchetypeEngine.generateDevelopmentRecommendations(
      _primaryArchetype!,
      _shadowArchetype!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06040F),
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: WBWorld.energie,
        title: 'ARCHETYPEN-ANALYSE',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([_bgCtrl, _mandalaCtrl]),
        builder: (context, child) {
          return Stack(
            children: [
              // Dark base
              const Positioned.fill(
                child: ColoredBox(color: Color(0xFF06040F)),
              ),
              // Ambient Orb 1 — Lila oben links
              Positioned(
                top: -80 + _bgCtrl.value * 40,
                left: -60 + _bgCtrl.value * 30,
                child: const _CineOrb(
                  color: Color(0xFF9C27B0),
                  size: 320,
                  opacity: 0.18,
                ),
              ),
              // Ambient Orb 2 — Gold unten rechts
              Positioned(
                bottom: -60 + (1 - _bgCtrl.value) * 40,
                right: -80 + (1 - _bgCtrl.value) * 30,
                child: const _CineOrb(
                  color: Color(0xFFFFD700),
                  size: 280,
                  opacity: 0.12,
                ),
              ),
              // Ambient Orb 3 — Dunkel-Lila Mitte
              Positioned(
                top: 300 + _bgCtrl.value * 60,
                left: 80,
                child: const _CineOrb(
                  color: Color(0xFF7E57C2),
                  size: 200,
                  opacity: 0.10,
                ),
              ),
              // Main content
              SafeArea(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                    : _profile == null
                        ? _buildNoProfileView()
                        : Column(
                            children: [
                              _buildMandalaHeader(),
                              _buildProfileHeader(),
                              _buildTabBar(),
                              Expanded(
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _buildPrimaryTab(),
                                    _buildSecondaryAndShadowTab(),
                                    _buildIntegrationTab(),
                                    _buildAllArchetypesTab(),
                                  ],
                                ),
                              ),
                            ],
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Animierter Mandala-Header (200px hoch)
  Widget _buildMandalaHeader() {
    final primaryColor = _primaryArchetype != null
        ? (_primaryArchetype!['color'] as Color? ?? const Color(0xFF9C27B0))
        : const Color(0xFF9C27B0);

    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hintergrund-Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withValues(alpha: 0.25),
                  const Color(0xFF06040F).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          // Rotierendes Mandala
          CustomPaint(
            size: const Size(180, 180),
            painter: _MandalaPainter(
              rotation: _mandalaCtrl.value * 2 * math.pi,
              color: primaryColor,
            ),
          ),
          // Inneres Glow
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.5),
                  primaryColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          // Archetyp-Icon in der Mitte
          if (_primaryArchetype != null)
            Text(
              '🎭',
              style: const TextStyle(fontSize: 28),
            ),
        ],
      ),
    );
  }

  Widget _buildNoProfileView() {
    return ProfileRequiredWidget(
      worldType: 'energie',
      message: 'Energie-Profil erforderlich',
      onProfileCreated: _loadProfile,
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9C27B0), Color(0xFF4A148C)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9C27B0).withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 28),
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
                Text(
                  'Geboren: ${_profile!.birthDate.day}.${_profile!.birthDate.month}.${_profile!.birthDate.year}',
                  style: TextStyle(
                      fontSize: 13, color: Colors.white.withValues(alpha: 0.6)),
                ),
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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.45),
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'PRIMÄR'),
          Tab(text: 'SCHATTEN'),
          Tab(text: 'INTEGRATION'),
          Tab(text: 'ALLE 12'),
        ],
      ),
    );
  }

  Widget _buildPrimaryTab() {
    if (_primaryArchetype == null || _activationArchetype == null) {
      return const Center(
          child: Text('Keine Daten', style: TextStyle(color: Colors.white)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildArchetypeCard(_primaryArchetype!, 'PRIMÄR-ARCHETYP',
              isPrimary: true),
          const SizedBox(height: 20),
          _buildArchetypeCard(_activationArchetype!,
              'AKTIVIERUNGS-ARCHETYP (${DateTime.now().year})',
              isActivation: true),
        ],
      ),
    );
  }

  Widget _buildSecondaryAndShadowTab() {
    if (_secondaryArchetype == null || _shadowArchetype == null) {
      return const Center(
          child: Text('Keine Daten', style: TextStyle(color: Colors.white)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildArchetypeCard(_secondaryArchetype!, 'SEKUNDÄR-ARCHETYP'),
          const SizedBox(height: 20),
          _buildArchetypeCard(_shadowArchetype!, 'SCHATTEN-ARCHETYP',
              isShadow: true),
        ],
      ),
    );
  }

  Widget _buildIntegrationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIntegrationScoreCard(),
          const SizedBox(height: 20),
          _buildElementDistributionCard(),
          const SizedBox(height: 20),
          _buildRecommendationsCard(),
        ],
      ),
    );
  }

  Widget _buildAllArchetypesTab() {
    final allArchetypes = ArchetypeEngine.getAllArchetypes();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ALLE 12 ARCHETYPEN',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...allArchetypes.entries.map((entry) {
            final archetype = entry.value;
            final archetypeColor = archetype['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: archetypeColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              archetypeColor.withValues(alpha: 0.8),
                              archetypeColor.withValues(alpha: 0.4),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: archetypeColor.withValues(alpha: 0.35),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              archetype['name'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              archetype['englishName'] as String,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.45)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    archetype['description'] as String,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.65)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildArchetypeCard(Map<String, dynamic> archetype, String label,
      {bool isPrimary = false,
      bool isShadow = false,
      bool isActivation = false}) {
    final archetypeColor = archetype['color'] as Color;
    final archetypeName = archetype['name'] as String;

    // Stärken-Chips aus Stärken-Text ableiten (erste 3 Stichwörter als Chips)
    final strengthText = _getPersonalizedStrength(archetypeName);
    final chipLabels = _extractStrengthChips(archetypeName);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: archetypeColor.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: archetypeColor.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Glassmorphischer Header-Bereich mit großem Emoji
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  archetypeColor.withValues(alpha: 0.22),
                  archetypeColor.withValues(alpha: 0.04),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                // Label
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: archetypeColor,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 16),
                // Großes Emoji / Symbol
                Text(
                  isPrimary
                      ? '⭐'
                      : isShadow
                          ? '🌑'
                          : isActivation
                              ? '⚡'
                              : '🔮',
                  style: const TextStyle(fontSize: 56),
                ),
                const SizedBox(height: 12),
                // Archetyp-Name
                Text(
                  archetypeName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  archetype['englishName'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.55),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                // Stärken-Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: chipLabels
                      .map((chip) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: archetypeColor.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color:
                                      archetypeColor.withValues(alpha: 0.45)),
                            ),
                            child: Text(
                              chip,
                              style: TextStyle(
                                fontSize: 12,
                                color: archetypeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          // Details-Bereich
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getPersonalizedArchetypeIntro(
                            archetypeName, isPrimary, isShadow, isActivation),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.88),
                          fontWeight: FontWeight.w500,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailedInfoRow('🎯 Was dich antreibt',
                          '${strengthText.substring(0, math.min(160, strengthText.length))}…'),
                      _buildDetailedInfoRow('😨 Was du fürchtest',
                          _getPersonalizedFear(archetypeName)),
                      _buildDetailedInfoRow('💪 Deine Superkraft',
                          '${_getPersonalizedStrength(archetypeName).substring(0, math.min(140, _getPersonalizedStrength(archetypeName).length))}…'),
                      _buildDetailedInfoRow('⚠️ Deine Falle',
                          _getPersonalizedWeakness(archetypeName)),
                      _buildDetailedInfoRow(
                          '🌍 Dein Element', '${archetype['element']}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Ableitung von 3 Stärken-Chips anhand des Archetyp-Namens
  List<String> _extractStrengthChips(String archetypeName) {
    const chipMap = <String, List<String>>{
      'Der Unschuldige': ['Reinheit', 'Hoffnung', 'Vertrauen'],
      'Der Weise': ['Klarheit', 'Analyse', 'Wahrheit'],
      'Der Entdecker': ['Freiheit', 'Neugier', 'Mut'],
      'Der Held': ['Tapferkeit', 'Disziplin', 'Stärke'],
      'Der Magier': ['Transformation', 'Vision', 'Manifest'],
      'Der Rebell': ['Wandel', 'Rebellion', 'Gerechtigkeit'],
      'Der Liebende': ['Intimität', 'Passion', 'Verbindung'],
      'Der Schöpfer': ['Kreativität', 'Originalität', 'Vision'],
      'Der Narr': ['Freude', 'Spontan', 'Leichtigkeit'],
      'Der Fürsorgliche': ['Mitgefühl', 'Fürsorge', 'Schutz'],
      'Der Herrscher': ['Führung', 'Struktur', 'Stabilität'],
    };
    return chipMap[archetypeName] ?? ['Kraft', 'Weisheit', 'Wachstum'];
  }

  Widget _buildDetailedInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getPersonalizedArchetypeIntro(
      String archetypeName, bool isPrimary, bool isShadow, bool isActivation) {
    final name = _profile?.firstName ?? 'Du';

    if (isPrimary) {
      return '$name, dein Kern-Archetyp ist der $archetypeName! Dies ist die tiefste Schicht deiner Persönlichkeit - das, wer du wirklich bist, wenn alle Masken fallen. Dieser Archetyp prägt deine gesamte Lebensreise.';
    } else if (isShadow) {
      return '$name, dein Schatten-Archetyp ist der $archetypeName. Dies repräsentiert die ungelebten Seiten deiner Persönlichkeit - nicht negativ, sondern Potenzial, das darauf wartet, integriert zu werden. Wenn du diesen Schatten annimmst, wirst du ganz.';
    } else if (isActivation) {
      return '$name, in diesem Jahr ${DateTime.now().year} ist der $archetypeName für dich aktiv! Diese Energie färbt deine aktuellen Erfahrungen und bietet dir besondere Chancen zur Entwicklung. Nutze diese Zeit bewusst!';
    } else {
      return '$name, der $archetypeName ist dein sekundärer Archetyp - die Art, wie du dich der Welt zeigst und deine Talente ausdrückst. Er ergänzt deinen Kern-Archetypen.';
    }
  }

  String _getPersonalizedMotivation(String archetypeName) {
    final name = _profile?.firstName ?? 'Du';

    switch (archetypeName) {
      case 'Der Unschuldige':
        return '$name, tief in dir brennt die Sehnsucht nach einer reinen, einfachen Welt, in der Ehrlichkeit und Güte die Norm sind. Du möchtest an das Gute glauben und Sicherheit finden, denn dein Herz ist voller Hoffnung, dass das Leben im Kern gut ist. Du suchst nach Vertrauen und Geborgenheit in einer komplexen Welt, und diese Hoffnung treibt dich an, selbst nach Enttäuschungen wieder aufzustehen. Du möchtest eine Welt schaffen, in der Menschen einander mit Respekt begegnen und Vertrauen nicht enttäuscht wird. Jede Begegnung ist für dich eine Chance, Reinheit und Güte zu bewahren und anderen zu zeigen, dass Optimismus keine Naivität ist, sondern eine bewusste Entscheidung für das Licht. Du bist der Hüter der Hoffnung, und dein tiefster Wunsch ist es, zu beweisen, dass Liebe und Vertrauen stärker sind als Angst und Misstrauen.';
      case 'Der Weise':
        return '$name, du wirst von unstillbarem Wissensdurst angetrieben, der niemals zur Ruhe kommt. Die Wahrheit zu verstehen und Wissen zu teilen ist für dich wichtiger als Komfort oder Bequemlichkeit, denn jede Frage, jedes Mysterium ruft dich und fordert dich heraus. Du suchst nach dem tieferen Sinn hinter allem - nicht oberflächlich, sondern in der tiefsten Essenz der Realität. Dein Geist ist ständig aktiv, analysiert, vergleicht, sucht nach Mustern und Zusammenhängen, die anderen verborgen bleiben. Du glaubst fest daran, dass Wissen befreit und dass Verständnis der Schlüssel zu einem erfüllten Leben ist. Für dich ist Bildung heilig und Unwissenheit eine vermeidbare Tragödie, die du mit all deiner Kraft bekämpfen möchtest. Deine Mission ist es, Licht in die Dunkelheit zu bringen und anderen zu zeigen, wie sie selbst Wahrheit von Illusion unterscheiden können.';
      case 'Der Entdecker':
        return '$name, Freiheit ist dein höchstes Gut - frei von Zwängen, Erwartungen und gesellschaftlichen Grenzen! Du möchtest die Welt in all ihrer Vielfalt erkunden, neue Orte entdecken, neue Kulturen kennenlernen und neue Erfahrungen sammeln, die deine Seele nähren. Du sehnst dich danach, Grenzen zu sprengen und authentisch zu leben, jenseits von Rollen und Masken, die dir die Gesellschaft aufzwingen möchte. Routine ist für dich wie ein goldener Käfig - schön anzusehen, aber erstickend für deinen freien Geist. Jeder Tag ist für dich eine Gelegenheit für ein Abenteuer, sei es physisch, geistig oder emotional. Du glaubst fest daran, dass das Leben draußen wartet und dass Sicherheit oft nur eine Illusion ist. Deine Mission ist es, andere zu inspirieren, ihre eigenen Grenzen zu überschreiten!';
      case 'Der Held':
        return '$name, du möchtest Herausforderungen meistern und dir selbst sowie der Welt beweisen, dass du stark genug bist für alles, was das Leben dir entgegenwirft! Disziplin, Mut und Entschlossenheit sind deine Leitwerte, und du glaubst fest daran, dass jede Herausforderung eine Chance ist, zu wachsen und deine innere Stärke zu entdecken. Herausforderungen zu meistern und die Welt zu verbessern, gibt deinem Leben wahren Sinn und Zweck. Du willst über dich hinauswachsen, deine eigenen Grenzen sprengen und anderen zeigen, was wirklich in ihnen steckt, wenn sie nur den Mut haben, den ersten Schritt zu wagen. Für dich ist das Leben ein Wettkampf - nicht gegen andere, sondern gegen deine eigenen Zweifel und Ängste. Du möchtest am Ende deines Lebens zurückblicken können und sagen: "Ich habe gekämpft, ich habe gewonnen, ich habe Mut bewiesen." Du willst etwas Bedeutsames bewirken!';
      case 'Der Magier':
        return '$name, du träumst davon, Träume in greifbare Realität zu verwandeln und die verborgenen Gesetze des Universums zu meistern! Transformation fasziniert dich auf tiefster Ebene - du möchtest das scheinbar Unmögliche möglich machen und andere durch deine Vision und Macht verzaubern und inspirieren. Du glaubst fest an die Kraft des Bewusstseins, der gezielten Absicht und der kreativen Visualisierung. Für dich ist die Welt voller verborgener Kräfte und magischer Möglichkeiten, die darauf warten, entdeckt und aktiviert zu werden. Du bist fasziniert von dem, was geschehen kann, wenn man die richtigen Prinzipien versteht und anwendet - die Alchemie der Transformation von Blei zu Gold, von Dunkelheit zu Licht, von Begrenzung zu Freiheit. Deine Mission ist es, Menschen zu helfen, ihr eigenes magisches Potenzial zu erkennen und zu aktivieren!';
      case 'Der Rebell':
        return '$name, du willst das System grundlegend verändern und Strukturen aufbrechen, die nicht mehr funktionieren! Status quo zu akzeptieren, ist für dich absolut keine Option, denn du siehst Ungerechtigkeit überall und kannst einfach nicht schweigen. Du kämpfst leidenschaftlich für Revolution, soziale Gerechtigkeit und echte, nachhaltige Veränderung, die Generationen überdauert. Dein Herz rebelliert gegen Unterdrückung, Heuchelei und blinde Konformität, die Menschen davon abhält, sie selbst zu sein. Für dich ist Bequemlichkeit der größte Feind des Fortschritts, und du bist bereit, Risiken einzugehen, dich unbeliebt zu machen und gegen den Strom zu schwimmen. Deine Vision ist eine Welt, in der Authentizität mehr zählt als Anpassung und in der jeder Mensch frei sein kann. Du möchtest beweisen, dass Einzelne die Welt verändern können!';
      case 'Der Liebende':
        return '$name, Liebe und tiefe menschliche Verbindung sind dein absolutes Lebenselixier und der Sinn deiner Existenz! Du sehnst dich nach tiefer Intimität, Leidenschaft und echter Nähe und möchtest geliebt und wertgeschätzt werden für das, was du wirklich bist - nicht für eine Maske oder Rolle. Beziehungen sind dir heilig, denn du glaubst fest daran, dass das Leben erst durch Begegnungen mit anderen wirklich lebendig und bedeutsam wird. Du möchtest jeden Moment voll auskosten, mit allen Sinnen erleben und nichts von der Schönheit verpassen, die uns umgibt. Für dich ist Schönheit überall: in der Natur, in Kunst, in liebevollen Gesten zwischen Menschen, in ehrlichen Blicken. Deine Mission ist es, Liebe zu geben und zu empfangen ohne Wenn und Aber. Du weißt, dass wahre Erfüllung durch Teilen kommt, nicht durch Besitzen!';
      case 'Der Schöpfer':
        return '$name, du musst erschaffen - es ist kein Wunsch, sondern eine existenzielle Notwendigkeit deiner Seele! Etwas wahrhaft Bleibendes zu schaffen, das deine einzigartige Vision klar ausdrückt, ist deine tiefste Motivation und dein Lebensantrieb. Deine Kreativität will sich unbedingt manifestieren und in der physischen Welt Gestalt annehmen, sonst fühlst du dich innerlich zerrissen und unvollständig. Du glaubst fest daran, dass jeder Mensch das gottgleiche Potenzial hat, etwas wahrhaft Einzigartiges und Originelles zu schaffen, das die Welt bereichert. Für dich ist Kreativität nicht nur ein Hobby, sondern heilig - sie ist der reinste Ausdruck menschlicher Göttlichkeit und schöpferischer Urkraft. Du möchtest eine bleibende Spur hinterlassen, ein Vermächtnis, das auch nach dir weiterlebt und kommende Generationen inspiriert und bewegt!';
      case 'Der Narr':
        return '$name, du möchtest das Leben in vollen Zügen genießen! Spaß, Spontaneität und lebendige Momente sind dir wichtiger als Sicherheit. Du willst wirklich LEBEN.';
      case 'Der Fürsorgliche':
        return '$name, anderen zu helfen, erfüllt dich tief. Du möchtest beschützen, nähren und Leid lindern. Das Wohlergehen anderer ist dir oft wichtiger als dein eigenes.';
      case 'Der Herrscher':
        return '$name, du willst Ordnung aus Chaos schaffen, klare Strukturen etablieren und verantwortungsvolle Führung übernehmen, wo sie gebraucht wird! Kontrolle im positiven Sinne und langfristige Stabilität zu gewährleisten, gibt dir das tiefe Gefühl, deinen wichtigsten Beitrag zur Gesellschaft zu leisten und ein dauerhaftes Erbe zu hinterlassen. Du möchtest Verantwortung tragen - nicht aus Machtgier, sondern aus der tiefen Überzeugung, dass starke, weise Führung absolut notwendig ist, damit eine Gemeinschaft wirklich prosperieren kann. Du siehst Chaos als Herausforderung, die nach einer starken, gerechten Hand ruft, die Ordnung schafft ohne zu unterdrücken. Du glaubst an klare Regeln, faire Hierarchien und nachhaltige Systeme, die Generationen überdauern. Deine Vision ist eine Welt, in der Ressourcen weise genutzt werden, Gerechtigkeit herrscht und jeder seinen Platz kennt und wertschätzt!';
      default:
        return 'Deine tiefste Motivation prägt alle deine Entscheidungen.';
    }
  }

  String _getPersonalizedFear(String archetypeName) {
    final name = _profile?.firstName ?? 'Du';

    switch (archetypeName) {
      case 'Der Unschuldige':
        return '$name, deine tiefste Angst ist Verlassenheit und Bestrafung. Du fürchtest, dass die Welt unsicher ist und du im Stich gelassen wirst. Jede Verletzung deines Vertrauens trifft dich tief.';
      case 'Der Weise':
        return '$name, Unwissenheit und getäuscht werden sind deine Urängste. Du fürchtest, etwas Wichtiges zu übersehen oder an Illusionen zu glauben. Dummheit ist für dich unerträglich.';
      case 'Der Entdecker':
        return '$name, gefangen zu sein - in Routinen, Beziehungen oder Erwartungen - ist dein Alptraum. Du fürchtest, dass dein Leben leer und bedeutungslos wird, wenn du nicht frei bist.';
      case 'Der Held':
        return '$name, Schwäche und Versagen sind das, was du am meisten fürchtest. Die Vorstellung, nicht stark genug zu sein oder als Feigling zu gelten, treibt dich manchmal zu sehr an.';
      case 'Der Magier':
        return '$name, du fürchtest, dass deine Visionen nur Träume bleiben. Machtlosigkeit und die Unfähigkeit, wirklich etwas zu verändern, sind deine Urängste.';
      case 'Der Rebell':
        return '$name, Machtlosigkeit und Irrelevanz erschrecken dich. Du fürchtest, dass du nichts verändern kannst und dass das System dich verschluckt. Konformität ist dein Alptraum.';
      case 'Der Liebende':
        return '$name, Einsamkeit und Zurückweisung sind deine tiefsten Ängste. Die Vorstellung, allein oder ungeliebt zu sein, kann dich lähmen. Verlust schmerzt dich besonders.';
      case 'Der Schöpfer':
        return '$name, Mittelmäßigkeit und Unoriginalität sind deine Urängste. Du fürchtest, nichts Bedeutsames zu erschaffen oder nur eine Kopie zu sein. Deine Vision könnte unverwirklicht bleiben.';
      case 'Der Narr':
        return '$name, Langeweile und tot zu sein, während du noch lebst, erschrecken dich. Du fürchtest, das Leben zu verpassen oder zu ernsthaft zu werden. Sinnlose Routine ist dein Albtraum.';
      case 'Der Fürsorgliche':
        return '$name, Egoismus und die Hilflosigkeit anderer zu sehen, schmerzt dich tief. Du fürchtest, undankbar oder selbstsüchtig zu sein. Leid, das du nicht lindern kannst, quält dich.';
      case 'Der Herrscher':
        return '$name, Chaos und Kontrollverlust sind deine größten Ängste. Du fürchtest, dass ohne deine Führung alles zusammenbricht. Schwäche zu zeigen, fällt dir schwer.';
      default:
        return 'Diese Angst treibt viele deiner Entscheidungen unterbewusst an.';
    }
  }

  String _getPersonalizedStrength(String archetypeName) {
    final name = _profile?.firstName ?? 'Du';

    switch (archetypeName) {
      case 'Der Unschuldige':
        return '$name, deine größte Superkraft ist dein unerschütterlich reines Herz und deine außergewöhnliche Fähigkeit, trotz aller Enttäuschungen wieder zu vertrauen! Du siehst das Gute in Menschen, selbst wenn sie es selbst nicht mehr sehen können, und du kannst Hoffnung schenken und Licht bringen, wenn andere in tiefster Verzweiflung sind. Deine Ehrlichkeit und Offenheit sind erfrischend wie ein klarer Bergquell in einer Welt voller Täuschung und Manipulation. Du hast die seltene Gabe, Menschen daran zu erinnern, dass Güte und Reinheit existieren und dass es sich lohnt, an das Gute zu glauben. Dein Optimismus ist keine Naivität, sondern eine bewusste Wahl und eine Form von Mut. Du bist ein Leuchtturm der Hoffnung in stürmischen Zeiten und deine Präsenz allein kann Menschen helfen, ihren Glauben an die Menschheit wiederzufinden.';
      case 'Der Weise':
        return '$name, dein brillanter, scharfer Geist und deine außergewöhnliche intellektuelle Klarheit sind deine größten Stärken! Du durchschaust komplexe Illusionen und Täuschungen mühelos, erkennst verborgene Muster und Zusammenhänge, die anderen verborgen bleiben, und findest Wahrheiten in scheinbar widersprüchlichen Informationen. Deine Weisheit und dein tiefes Verständnis können andere nicht nur führen und inspirieren, sondern wahrhaft erleuchten und ihr Bewusstsein erweitern. Du hast die seltene Fähigkeit, komplexe Konzepte einfach zu erklären und Menschen zu helfen, die Welt klarer zu sehen. Dein analytischer Verstand kombiniert mit intuitivem Wissen macht dich zu einem außergewöhnlichen Lehrer, Berater und Wegweiser. Du bist ein Licht der Erkenntnis in der Dunkelheit der Unwissenheit!';
      case 'Der Entdecker':
        return '$name, dein unerschütterlicher Mut, deine unstillbare Neugier und dein unbezähmbarer Freiheitsdrang sind absolut unschlagbar! Du wagst Dinge, die andere nicht einmal zu träumen wagen, und entdeckst dabei völlig neue Wege, Möglichkeiten und Perspektiven, die das Leben bereichern. Deine radikale Authentizität und dein Mut, du selbst zu sein - ohne Masken, ohne Kompromisse, ohne Angst vor Ablehnung - inspiriert andere Menschen zutiefst, ebenfalls authentischer und freier zu leben. Du zeigst durch dein Beispiel, dass ein Leben voller Abenteuer und Selbstbestimmung nicht nur möglich, sondern erfüllend ist. Deine Fähigkeit, loszulassen und ins Unbekannte zu springen, ist eine Kunst, die nur wenige beherrschen. Du bist ein lebendiges Beispiel dafür, dass Freiheit mehr wert ist als Sicherheit!';
      case 'Der Held':
        return '$name, deine außergewöhnliche Tapferkeit, deine eiserne Willenskraft und deine unerschütterliche Entschlossenheit sind absolut legendär und inspirieren alle um dich herum! Du gibst niemals auf, selbst wenn es schwierig, schmerzhaft oder scheinbar aussichtslos wird - du kämpfst weiter mit einer Ausdauer, die andere staunen lässt. Deine bemerkenswerte Fähigkeit, selbst die härtesten Herausforderungen nicht nur zu überstehen, sondern zu meistern und dabei zu wachsen, motiviert und inspiriert andere zutiefst, ebenfalls nicht aufzugeben. Du zeigst durch dein Beispiel, dass menschliche Willenskraft fast unbegrenzt ist, wenn sie richtig fokussiert wird. Deine Disziplin und dein Mut sind ein Vorbild für alle, die zweifeln, ob sie stark genug sind. Du beweist täglich, dass Helden real sind - und dass jeder einer sein kann!';
      case 'Der Magier':
        return '$name, du kannst wirklich manifestieren! Deine Vorstellungskraft und dein Verständnis von Energie ermöglichen echte Transformation. Du siehst Möglichkeiten, wo andere Grenzen sehen.';
      case 'Der Rebell':
        return '$name, dein unbändiger Mut zu rebellieren und Systeme grundlegend zu verändern ist eine seltene und wertvolle Gabe! Du sagst mutig und kompromisslos, was andere nur insgeheim denken aber nie auszusprechen wagen, und du kämpfst mit ganzer Leidenschaft für Gerechtigkeit, Gleichheit und echte gesellschaftliche Veränderung. Deine rebellische Energie, dein unermüdlicher Einsatz und deine Fähigkeit, Menschen zu mobilisieren und zu inspirieren, kann tatsächlich Revolutionen starten und überfälligen Wandel herbeiführen. Du hast die seltene Gabe, den Status quo in Frage zu stellen und Menschen aus ihrer Komfortzone zu reißen. Deine Authentizität und dein Mut, gegen den Strom zu schwimmen, sind inspirierend für alle, die sich ebenfalls unterdrückt fühlen. Du bist ein Katalysator für notwendige Veränderungen und ein Leuchtfeuer der Hoffnung für die Unterdrückten!';
      case 'Der Liebende':
        return '$name, deine außergewöhnliche Fähigkeit zu lieben - bedingungslos, tief und wahrhaftig - ist ein seltenes und kostbares Geschenk! Du schaffst mühelos tiefe, bedeutungsvolle Verbindungen zu Menschen und siehst die verborgene Schönheit in allem und jedem - selbst in dem, was andere als gewöhnlich oder unwichtig abtun. Deine vollkommene Hingabe, deine Fähigkeit, präsent zu sein und dein offenes Herz heilen emotionale Wunden und inspirieren andere, ebenfalls ihr Herz zu öffnen. Du zeigst durch dein Beispiel, dass wahre Liebe nicht besitzt, sondern befreit, nicht fordert, sondern schenkt. Deine Präsenz allein kann Räume mit Wärme, Intimität und echter menschlicher Verbindung füllen. Du erinnerst Menschen daran, dass das Leben nur durch Liebe und Verbindung wirklich lebenswert wird!';
      case 'Der Schöpfer':
        return '$name, deine grenzenlose Kreativität und deine Fähigkeit, aus dem absoluten Nichts wahre Schönheit, Bedeutung und Inspiration zu erschaffen, sind außergewöhnlich! Du kannst durch deine künstlerischen, visionellen Schöpfungen Menschen tief berühren, ihr Bewusstsein erweitern und die Welt nachhaltig bereichern. Deine einzigartigen Visionen und Ideen sind nicht nur originell, sondern zeitlos - sie überdauern Generationen und bleiben bestehen als Vermächtnis deines schöpferischen Geistes. Du hast die seltene Gabe, Unsichtbares sichtbar zu machen, Gefühltes ausdrückbar zu machen und Träume in greifbare Realität zu verwandeln. Deine Kreativität ist nicht nur ein Talent, sondern eine Form von Magie und ein Geschenk an die Menschheit, das die Welt reicher, bunter und bedeutungsvoller macht!';
      case 'Der Narr':
        return '$name, deine ansteckende, ungezügelte Lebensfreude und deine Fähigkeit, das Leben spielerisch und leicht zu nehmen, sind ein kostbares Geschenk für alle um dich herum! Du erinnerst andere auf charmante, humorvolle Weise daran, wirklich zu leben - mit vollem Herzen, im Moment präsent, voller Freude und Spontaneität - statt nur pflichtbewusst zu existieren und Tage abzuhaken. Deine erfrischende Spontaneität, dein Humor und deine Fähigkeit, dich nicht zu ernst zu nehmen, bringen heilende Leichtigkeit, befreiende Perspektivenwechsel und echtes Lachen in ernste, verkrampfte Situationen. Du zeigst durch dein Beispiel, dass wahre Weisheit oft in der Leichtigkeit liegt, nicht in der Schwere, und dass Verspieltheit keine Unreife, sondern eine Form von Meisterschaft ist. Du bist ein Leuchtfeuer der Freude in einer zu ernsten Welt!';
      case 'Der Fürsorgliche':
        return '$name, dein unendlich tiefes Mitgefühl und deine Fähigkeit, bedingungslos für andere da zu sein, kennen absolut keine Grenzen! Du spürst intuitiv und treffsicher, was andere Menschen wirklich brauchen - oft bevor sie es selbst wissen - und kannst auf eine Weise wirklich, nachhaltig und heilsam helfen, die weit über oberflächliche Gesten hinausgeht. Deine tiefe, selbstlose Fürsorge, deine liebevolle Aufmerksamkeit und deine Fähigkeit, einen sicheren Raum zu schaffen, heilen emotionale Wunden, die andere kaum sehen können. Du gibst ohne zu zögern, liebst ohne Bedingungen und hilfst ohne eine Gegenleistung zu erwarten. Deine Präsenz allein kann Menschen das Gefühl geben, wertgeschätzt, gesehen und geliebt zu sein. Du bist ein Engel auf Erden und ein lebendiges Beispiel dafür, was bedingungslose Liebe bedeutet!';
      case 'Der Herrscher':
        return '$name, deine natürliche Führungsqualität und deine Fähigkeit, selbst im größten Chaos klare Ordnung, Struktur und Stabilität zu schaffen, sind bemerkenswert! Menschen vertrauen instinktiv deiner inneren Stärke, deiner Zuverlässigkeit und der Stabilität, die von dir ausstrahlt - sie wissen, dass du für sie da bist und dass du Verantwortung übernimmst, wenn es darauf ankommt. Du kannst selbst große, komplexe Projekte souverän leiten, langfristige Visionen entwickeln und umsetzen und dabei alle Beteiligten koordinieren und motivieren. Deine Fähigkeit, den Überblick zu behalten, kluge Entscheidungen zu treffen und gleichzeitig fair und gerecht zu führen, macht dich zu einem wahren Anführer. Du schöpfst nicht nur Strukturen, sondern schaffst Rahmenbedingungen, in denen andere wachsen und gedeihen können!';
      default:
        return 'Diese außergewöhnliche Stärke ist dein größtes, wertvollstes Geschenk an die Welt und an alle Menschen, die das Glück haben, dich zu kennen! Sie ist nicht nur ein Talent oder eine Fähigkeit, sondern ein fundamentaler Teil deines Wesens, der die Welt bereichert, Menschen inspiriert und einen echten, nachhaltigen Unterschied macht. Diese Stärke ist einzigartig, unverwechselbar dein und niemand anders kann sie auf genau diese Weise in die Welt bringen. Je mehr du diese Stärke annimmst, kultivierst und großzügig teilst, desto mehr erfüllst du deinen wahren Lebenszweck und trägst dazu bei, die Welt zu einem besseren Ort zu machen. Verstehe, schätze und nutze diese Gabe weise - sie ist deine persönliche Form von Magie!';
    }
  }

  String _getPersonalizedWeakness(String archetypeName) {
    final name = _profile?.firstName ?? 'Du';

    switch (archetypeName) {
      case 'Der Unschuldige':
        return '$name, pass auf: Deine Naivität kann dich verletzbar machen. Manchmal übersiehst du rote Flaggen, weil du das Gute sehen willst. Lerne, gesund misstrauisch zu sein.';
      case 'Der Weise':
        return '$name, deine Falle ist Überanalyse. Manchmal denkst du so viel nach, dass du nicht ins Handeln kommst. Nicht alles muss verstanden werden - manchmal musst du einfach springen.';
      case 'Der Entdecker':
        return '$name, deine Unrast kann Probleme schaffen. Du springst zum nächsten Abenteuer, bevor du das aktuelle abgeschlossen hast. Manchmal braucht es Beharrlichkeit, nicht Flucht.';
      case 'Der Held':
        return '$name, deine Schwäche ist, dass du dich überforderst. Du willst alle Probleme lösen und vergisst dabei dich selbst. Nicht jeder Kampf ist deiner - lerne loszulassen.';
      case 'Der Magier':
        return '$name, pass auf: Deine Manipulationsfähigkeit kann nach hinten losgehen. Manchmal willst du zu sehr kontrollieren, wie Dinge sich entwickeln. Vertraue auch dem natürlichen Fluss.';
      case 'Der Rebell':
        return '$name, deine Falle ist destruktive Rebellion. Manchmal lehnst du Dinge ab, nur weil sie mainstream sind - nicht weil sie wirklich falsch sind. Wähle deine Kämpfe weise.';
      case 'Der Liebende':
        return '$name, deine Schwäche ist Selbstaufgabe. Du gibst so viel in Beziehungen, dass du dich selbst verlierst. Lernen zu empfangen ist genauso wichtig wie zu geben.';
      case 'Der Schöpfer':
        return '$name, Perfektionismus kann dich lähmen. Du startest Projekte nicht, weil sie "noch nicht gut genug" sind. Manchmal ist "done" besser als "perfect".';
      case 'Der Narr':
        return '$name, deine Verantwortungslosigkeit kann Probleme schaffen. Manchmal meidest du Verpflichtungen zu sehr. Nicht alles im Leben ist ein Spiel - manche Dinge brauchen Ernsthaftigkeit.';
      case 'Der Fürsorgliche':
        return '$name, pass auf: Du vergisst dich selbst für andere. Deine Überfürsorge kann erdrücken und Menschen klein halten. Andere dürfen auch kämpfen und wachsen.';
      case 'Der Herrscher':
        return '$name, Kontrollzwang ist deine Falle. Manchmal willst du zu viel steuern und lässt anderen keinen Raum. Flexibilität ist manchmal mächtiger als Kontrolle.';
      default:
        return 'Diese Schwäche zu erkennen, ist der erste Schritt zur Integration.';
    }
  }

  Widget _buildIntegrationScoreCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withValues(alpha: 0.12),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INTEGRATIONS-SCORE',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_integrationScore / 100',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _integrationScore / 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFFD700)),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getIntegrationMessage(_integrationScore),
            style: TextStyle(
                fontSize: 14, color: Colors.white.withValues(alpha: 0.65)),
          ),
        ],
      ),
    );
  }

  String _getIntegrationMessage(int score) {
    if (score >= 80) {
      return 'Exzellente Integration! Deine Archetypen arbeiten harmonisch zusammen.';
    }
    if (score >= 60) return 'Gute Integration. Es gibt noch Raum für Wachstum.';
    if (score >= 40) {
      return 'Moderate Integration. Arbeite an der Balance deiner Archetypen.';
    }
    return 'Niedrige Integration. Fokussiere dich auf Schattenarbeit.';
  }

  Widget _buildElementDistributionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ELEMENT-VERTEILUNG',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ..._elementDistribution.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.white),
                      ),
                      Text(
                        '${entry.value}',
                        style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: entry.value / 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          _getElementColor(entry.key)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getElementColor(String element) {
    switch (element) {
      case 'Feuer':
        return Colors.red;
      case 'Wasser':
        return Colors.blue;
      case 'Luft':
        return Colors.cyan;
      case 'Erde':
        return Colors.brown;
      case 'Äther':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRecommendationsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ENTWICKLUNGS-EMPFEHLUNGEN',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ..._recommendations.map((rec) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle,
                      color: Color(0xFF4CAF50), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rec,
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.65)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Mandala CustomPainter ────────────────────────────────────────────────────

class _MandalaPainter extends CustomPainter {
  final double rotation;
  final Color color;
  _MandalaPainter({required this.rotation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    for (int i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      canvas.save();
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -size.width * 0.2),
          width: size.width * 0.15,
          height: size.width * 0.3,
        ),
        paint..color = color.withValues(alpha: 0.3),
      );
      canvas.restore();
    }
    // Innere Kreise
    for (int r = 1; r <= 3; r++) {
      final alpha = math.max(0.02, 0.15 - r * 0.03);
      canvas.drawCircle(
        Offset.zero,
        size.width * 0.1 * r,
        paint..color = color.withValues(alpha: alpha),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MandalaPainter old) =>
      old.rotation != rotation || old.color != color;
}

// ─── Cinematic Orb Widget ─────────────────────────────────────────────────────

class _CineOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  const _CineOrb(
      {required this.color, required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      );
}
