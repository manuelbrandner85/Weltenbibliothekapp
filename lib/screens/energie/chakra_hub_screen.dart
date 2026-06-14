import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/animations/wb_tap_scale.dart';
import '../../widgets/cinematic/wb_model_view.dart';
import '../../widgets/animations/wb_animated_entrance.dart';
import 'calculators/chakra_calculator_screen.dart';
import 'chakra_scan_screen.dart';
import 'chakra_history_screen.dart';
import '../../data/chakra_program_7.dart';
import '../../widgets/lesson_series_screen.dart';

/// Intuitiver Einstiegs-Screen fuer das gesamte Chakren-System.
/// Zeigt:
///   - Animiertes Koerper-Diagramm mit 7 Energiezentren
///   - 4 Schnellzugriff-Aktionen (Scan, Analyse, Verlauf, Programm)
///   - Aufklappbare Info-Karten fuer jedes der 7 Chakren
class ChakraHubScreen extends StatefulWidget {
  const ChakraHubScreen({super.key});

  @override
  State<ChakraHubScreen> createState() => _ChakraHubScreenState();
}

class _ChakraHubScreenState extends State<ChakraHubScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _entryCtrl;
  late Animation<double> _entryAnim;

  // Tracks which chakra card is expanded (-1 = none)
  int _expandedIndex = -1;

  static const _bg = Color(0xFF06040F);
  static const _card = Color(0xFF100B1E);

  // Chakra data: all 7 chakras in ascending order (root → crown)
  static const _chakras = [
    _ChakraInfo(
      index: 1,
      name: 'Wurzel-Chakra',
      sanskrit: 'Muladhara',
      emoji: '🔴',
      color: Color(0xFFE53935),
      location: 'Steißbein / Basis der Wirbelsäule',
      element: 'Erde',
      mantra: 'LAM',
      frequency: '396 Hz',
      affirmation: 'Ich bin sicher und geerdet.',
      theme: 'Sicherheit · Überleben · Erdung',
      balanced:
          'Tiefes Sicherheitsgefühl, stabile Erdung, Vertrauen in das Leben. '
          'Du fühlst dich verwurzelt und in der Lage, deine Grundbedürfnisse zu erfüllen.',
      blocked:
          'Existenzängste, Misstrauen, finanzielle Sorgen, Entwurzelungsgefühl. '
          'Körperlich: Beine, Füße, Knochen.',
    ),
    _ChakraInfo(
      index: 2,
      name: 'Sakral-Chakra',
      sanskrit: 'Svadhisthana',
      emoji: '🟠',
      color: Color(0xFFFF6D00),
      location: 'Unterhalb des Nabels',
      element: 'Wasser',
      mantra: 'VAM',
      frequency: '417 Hz',
      affirmation: 'Ich fließe mit dem Leben.',
      theme: 'Kreativität · Sexualität · Emotionen',
      balanced:
          'Lebendige Kreativität, emotionale Balance, erfüllende Beziehungen. '
          'Lebensenergie fließt frei durch dich.',
      blocked:
          'Kreativitätsblockaden, emotionale Taubheit, Beziehungsprobleme. '
          'Körperlich: Fortpflanzungsorgane, Nieren, Blase.',
    ),
    _ChakraInfo(
      index: 3,
      name: 'Solarplexus-Chakra',
      sanskrit: 'Manipura',
      emoji: '🟡',
      color: Color(0xFFFFD600),
      location: 'Oberhalb des Nabels',
      element: 'Feuer',
      mantra: 'RAM',
      frequency: '528 Hz',
      affirmation: 'Ich bin kraftvoll und selbstbewusst.',
      theme: 'Macht · Willenskraft · Selbstwert',
      balanced:
          'Starker Wille, gesundes Selbstwertgefühl, klare Durchsetzungsfähigkeit. '
          'Du kennst deinen Wert und lebst ihn.',
      blocked: 'Kontrollzwang oder Machtlosigkeit, geringes Selbstwertgefühl. '
          'Körperlich: Magen, Leber, Bauchspeicheldrüse.',
    ),
    _ChakraInfo(
      index: 4,
      name: 'Herz-Chakra',
      sanskrit: 'Anahata',
      emoji: '💚',
      color: Color(0xFF43A047),
      location: 'Herz-Zentrum',
      element: 'Luft',
      mantra: 'YAM',
      frequency: '639 Hz',
      affirmation: 'Ich liebe bedingungslos.',
      theme: 'Liebe · Mitgefühl · Heilung',
      balanced: 'Bedingungslose Liebe, tiefes Mitgefühl, emotionale Balance. '
          'Du kannst geben und empfangen in gleichem Maße.',
      blocked:
          'Herzschmerz, Einsamkeit, Unfähigkeit zu lieben oder Liebe anzunehmen. '
          'Körperlich: Herz, Lunge, Thymusdrüse.',
    ),
    _ChakraInfo(
      index: 5,
      name: 'Hals-Chakra',
      sanskrit: 'Vishuddha',
      emoji: '💙',
      color: Color(0xFF1E88E5),
      location: 'Kehle',
      element: 'Äther',
      mantra: 'HAM',
      frequency: '741 Hz',
      affirmation: 'Ich spreche meine Wahrheit.',
      theme: 'Kommunikation · Ausdruck · Wahrheit',
      balanced: 'Klare, authentische Kommunikation. Du drückst deine Wahrheit '
          'respektvoll und mutig aus.',
      blocked: 'Kommunikationsprobleme, Schweigen, Angst vor Ausdruck. '
          'Körperlich: Schilddrüse, Nacken, Kehle.',
    ),
    _ChakraInfo(
      index: 6,
      name: 'Stirn-Chakra',
      sanskrit: 'Ajna',
      emoji: '💜',
      color: Color(0xFF5E35B1),
      location: 'Zwischen den Augenbrauen (Drittes Auge)',
      element: 'Licht',
      mantra: 'OM / SHAM',
      frequency: '852 Hz',
      affirmation: 'Ich vertraue meiner inneren Weisheit.',
      theme: 'Intuition · Weisheit · Inneres Sehen',
      balanced: 'Starke Intuition, klares inneres Sehen, tiefe Weisheit. '
          'Du erkennst Muster hinter den Dingen.',
      blocked: 'Mangelnde Intuition, Überanalysieren, Selbstzweifel. '
          'Körperlich: Augen, Stirn, Hypothalamus.',
    ),
    _ChakraInfo(
      index: 7,
      name: 'Kronen-Chakra',
      sanskrit: 'Sahasrara',
      emoji: '👑',
      color: Color(0xFF8E24AA),
      location: 'Scheitel des Kopfes',
      element: 'Gedanke / Kosmos',
      mantra: 'Stille (kein Mantra)',
      frequency: '963 Hz',
      affirmation: 'Ich bin eins mit dem Universum.',
      theme: 'Spiritualität · Verbundenheit · Einheit',
      balanced:
          'Tiefe Verbindung mit dem Göttlichen, Frieden, kosmisches Bewusstsein. '
          'Du erlebst dich als Teil des großen Ganzen.',
      blocked: 'Spirituelle Isolation, Sinnlosigkeit, Dogmatismus. '
          'Körperlich: Gehirn, Nervensystem, Zirbeldrüse.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _entryAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: Curves.easeOutCubic,
    );
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _openScreen(Widget screen) {
    HapticFeedback.lightImpact();
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _open7DayProgram() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonSeriesScreen(
          title: 'Chakren 7-Tage-Programm',
          emoji: '🌈',
          accent: const Color(0xFF9C27B0),
          storageKey: 'chakra_7day_v1',
          entries: chakraProgram7,
          tradition: 'Hinduistische Chakra-Tradition',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'CHAKREN',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_in_ar_rounded, color: Colors.white70),
            tooltip: '3D-Ansicht',
            onPressed: () => _openScreen(const _Chakra3DScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white70),
            tooltip: 'Verlauf',
            onPressed: () => _openScreen(const ChakraHistoryScreen()),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([_bgCtrl, _pulseCtrl]),
        builder: (context, _) {
          return Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: _bg)),
              // Ambient glow top-right
              Positioned(
                top: -80 + _bgCtrl.value * 40,
                right: -60 + _bgCtrl.value * 20,
                child: _AmbientOrb(
                  color: const Color(0xFF9C27B0),
                  size: 320,
                  opacity: 0.14 + _pulseCtrl.value * 0.06,
                ),
              ),
              // Ambient glow bottom-left
              Positioned(
                bottom: -60 + (1 - _bgCtrl.value) * 30,
                left: -80 + (1 - _bgCtrl.value) * 20,
                child: _AmbientOrb(
                  color: const Color(0xFFE91E63),
                  size: 280,
                  opacity: 0.10 + (1 - _bgCtrl.value) * 0.06,
                ),
              ),
              // Main scrollable content
              FadeTransition(
                opacity: _entryAnim,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.of(context).padding.top + 56,
                      ),
                    ),
                    SliverToBoxAdapter(child: _buildBodyDiagram()),
                    SliverToBoxAdapter(child: _buildQuickActions()),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                        child: Text(
                          'Die 7 Chakren',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _ChakraCard(
                          info: _chakras[i],
                          isExpanded: _expandedIndex == i,
                          onTap: () => setState(() {
                            _expandedIndex = _expandedIndex == i ? -1 : i;
                          }),
                          pulse: _pulseCtrl.value,
                        ),
                        childCount: _chakras.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Animated vertical body diagram showing all 7 chakra positions
  Widget _buildBodyDiagram() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: _card.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(
            '7 Energiezentren des Körpers',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vertical chakra column
              _BodyDiagramColumn(chakras: _chakras, pulse: _pulseCtrl.value),
              const SizedBox(width: 20),
              // Label column
              _BodyDiagramLabels(chakras: _chakras),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.4,
        children: [
          _QuickActionButton(
            index: 0,
            emoji: '📋',
            label: 'Chakra-Scan',
            subtitle: 'Fragebogen',
            color: const Color(0xFFE91E63),
            onTap: () => _openScreen(const ChakraScanScreen()),
          ),
          _QuickActionButton(
            index: 1,
            emoji: '🔢',
            label: 'Chakra-Analyse',
            subtitle: 'Numerologie',
            color: const Color(0xFF9C27B0),
            onTap: () => _openScreen(const ChakraCalculatorScreen()),
          ),
          _QuickActionButton(
            index: 2,
            emoji: '📈',
            label: 'Verlauf',
            subtitle: 'Bisherige Scans',
            color: const Color(0xFF3F51B5),
            onTap: () => _openScreen(const ChakraHistoryScreen()),
          ),
          _QuickActionButton(
            index: 3,
            emoji: '🌈',
            label: '7-Tage-Programm',
            subtitle: 'Tagesweise Pfad',
            color: const Color(0xFF00897B),
            onTap: _open7DayProgram,
          ),
        ],
      ),
    );
  }
}

// Vertical dots column representing the body's chakra centers (crown at top)
class _BodyDiagramColumn extends StatelessWidget {
  final List<_ChakraInfo> chakras;
  final double pulse;

  const _BodyDiagramColumn({required this.chakras, required this.pulse});

  @override
  Widget build(BuildContext context) {
    // Display crown (index 6) at top, root (index 0) at bottom
    final reversed = chakras.reversed.toList();
    return Column(
      children: [
        for (int i = 0; i < reversed.length; i++) ...[
          _ChakraDot(
            color: reversed[i].color,
            isHighlighted: i == 0 || i == reversed.length - 1,
            pulse: pulse,
          ),
          if (i < reversed.length - 1)
            Container(
              width: 2,
              height: 22,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    reversed[i].color.withValues(alpha: 0.5),
                    reversed[i + 1].color.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _ChakraDot extends StatelessWidget {
  final Color color;
  final bool isHighlighted;
  final double pulse;

  const _ChakraDot({
    required this.color,
    required this.isHighlighted,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final size = isHighlighted ? 22.0 : 16.0;
    return Container(
      width: size + 8,
      height: size + 8,
      alignment: Alignment.center,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4 + pulse * 0.3),
              blurRadius: isHighlighted ? 16 : 8,
              spreadRadius: isHighlighted ? 2 : 0,
            ),
          ],
        ),
      ),
    );
  }
}

// Label column next to the body diagram
class _BodyDiagramLabels extends StatelessWidget {
  final List<_ChakraInfo> chakras;

  const _BodyDiagramLabels({required this.chakras});

  @override
  Widget build(BuildContext context) {
    final reversed = chakras.reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < reversed.length; i++) ...[
          SizedBox(
            height: 30,
            child: Row(
              children: [
                Text(reversed[i].emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      reversed[i].name,
                      style: TextStyle(
                        color: reversed[i].color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      reversed[i].sanskrit,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (i < reversed.length - 1) const SizedBox(height: 22),
        ],
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final int index;

  const _QuickActionButton({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    // WbAnimatedEntrance: gestaffelter Eintritt; WbTapScale: Scale + Haptik.
    return WbAnimatedEntrance(
      index: index,
      child: WbTapScale(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Expandable card for one chakra
class _ChakraCard extends StatelessWidget {
  final _ChakraInfo info;
  final bool isExpanded;
  final VoidCallback onTap;
  final double pulse;

  const _ChakraCard({
    required this.info,
    required this.isExpanded,
    required this.onTap,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isExpanded
              ? info.color.withValues(alpha: 0.12)
              : const Color(0xFF100B1E).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded
                ? info.color.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
            width: isExpanded ? 1.5 : 1.0,
          ),
          boxShadow: isExpanded
              ? [
                  BoxShadow(
                    color: info.color.withValues(alpha: 0.15 + pulse * 0.08),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Header row — always visible
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    // Colored circle with emoji
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: info.color.withValues(alpha: 0.2),
                        border: Border.all(
                          color: info.color.withValues(alpha: 0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: info.color.withValues(
                              alpha: 0.2 + pulse * 0.15,
                            ),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          info.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            info.name,
                            style: TextStyle(
                              color: info.color,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            info.sanskrit,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            info.theme,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Mantra badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: info.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        info.mantra,
                        style: TextStyle(
                          color: info.color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            // Expanded detail section
            AnimatedCrossFade(
              firstChild: const SizedBox(height: 0),
              secondChild: _buildExpandedContent(),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: info.color.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 14),
          // Meta info row
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _MetaChip(
                icon: Icons.location_on_outlined,
                label: info.location,
                color: info.color,
              ),
              _MetaChip(
                icon: Icons.air_outlined,
                label: info.element,
                color: info.color,
              ),
              _MetaChip(
                icon: Icons.graphic_eq,
                label: info.frequency,
                color: info.color,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Affirmation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: info.color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.format_quote, color: info.color, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    info.affirmation,
                    style: TextStyle(
                      color: info.color,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Balanced state
          _StateSection(
            title: 'Ausgeglichen',
            icon: Icons.check_circle_outline,
            color: const Color(0xFF66BB6A),
            text: info.balanced,
          ),
          const SizedBox(height: 10),
          // Blocked state
          _StateSection(
            title: 'Blockiert',
            icon: Icons.warning_amber_outlined,
            color: const Color(0xFFEF9A9A),
            text: info.blocked,
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _StateSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String text;

  const _StateSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// Ambient glow orb (purely decorative)
class _AmbientOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _AmbientOrb({
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

// Plain Dart class instead of named record type (CLAUDE.md rule: no named Dart 3 records)
class _ChakraInfo {
  final int index;
  final String name;
  final String sanskrit;
  final String emoji;
  final Color color;
  final String location;
  final String element;
  final String mantra;
  final String frequency;
  final String affirmation;
  final String theme;
  final String balanced;
  final String blocked;

  const _ChakraInfo({
    required this.index,
    required this.name,
    required this.sanskrit,
    required this.emoji,
    required this.color,
    required this.location,
    required this.element,
    required this.mantra,
    required this.frequency,
    required this.affirmation,
    required this.theme,
    required this.balanced,
    required this.blocked,
  });
}

/// Vollbild-3D der Chakren-Saeule (7 farbige Energiezentren). forceEnable ->
/// Tier-Gate aus, Reduce-Motion bleibt aktiv; sonst Fallback-Hinweis.
class _Chakra3DScreen extends StatelessWidget {
  const _Chakra3DScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0612),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Chakren - 3D'),
      ),
      body: WbModelView(
        src: 'assets/models/wb_chakras.glb',
        alt: 'Chakren-Saeule',
        forceEnable: true,
        backgroundColor: const Color(0xFF0A0612),
        fallback: const Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Text(
              '3D ist hier deaktiviert\n(Reduce-Motion aktiv).',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, height: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
