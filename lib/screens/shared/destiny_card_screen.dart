import 'dart:math';

import 'package:flutter/material.dart';

import '../../config/wb_design.dart';
import '../../services/gamification_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🃏 DESTINY CARD SCREEN — Octalysis Gamification
// Tägliche Schicksalskarte ziehen + Historie der letzten 7 Tage.
// ═══════════════════════════════════════════════════════════════════════════

class DestinyCardScreen extends StatefulWidget {
  const DestinyCardScreen({super.key});

  @override
  State<DestinyCardScreen> createState() => _DestinyCardScreenState();
}

class _DestinyCardScreenState extends State<DestinyCardScreen>
    with SingleTickerProviderStateMixin {
  final _gs = GamificationService();
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  DestinyCard? _todayCard;
  List<DestinyCard> _history = [];
  bool _isDrawing = false;
  bool _showFront = false;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _flipAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOutBack),
    );
    _flipCtrl.addListener(() {
      if (_flipAnim.value >= 0.5 && !_showFront) {
        setState(() => _showFront = true);
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _loadData() {
    _todayCard = _gs.getTodayCard();
    _history = _gs.getCardHistory(days: 7);
    if (_todayCard != null) _showFront = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WbDesign.bgNeutral,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Schicksalskarte',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            // Hauptkarte
            _buildMainCard(),
            const SizedBox(height: 24),
            // Draw Button (wenn noch nicht gezogen)
            if (_todayCard == null) _buildDrawButton(),
            // Karten-Info (wenn gezogen)
            if (_todayCard != null) _buildCardInfo(),
            const SizedBox(height: 32),
            // Historie
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard() {
    return Center(
      child: AnimatedBuilder(
        animation: _flipAnim,
        builder: (ctx, child) {
          final angle = _flipAnim.value * pi;
          final isBack = angle < pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isBack || !_showFront
                ? _buildCardBack()
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _buildCardFront(),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      width: 260,
      height: 380,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F3460),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Pattern Background
          Positioned.fill(
            child: CustomPaint(painter: _CardPatternPainter()),
          ),
          // Center Symbol
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFD700).withValues(alpha: 0.3),
                        const Color(0xFFFFD700).withValues(alpha: 0.05),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Center(
                    child: Text('🔮', style: TextStyle(fontSize: 36)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'SCHICKSAL',
                  style: TextStyle(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tippe zum Ziehen',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFront() {
    if (_todayCard == null) return _buildCardBack();

    final card = _todayCard!;
    final typeColor = Color(GamificationService.cardTypeColor(card.type));
    final typeEmoji = GamificationService.cardTypeEmoji(card.type);
    final typeLabel = GamificationService.cardTypeLabel(card.type);

    return Container(
      width: 260,
      height: 380,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            typeColor.withValues(alpha: 0.2),
            const Color(0xFF0A0A0A),
          ],
        ),
        border: Border.all(
          color: typeColor.withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: typeColor.withValues(alpha: 0.2),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Type Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: typeColor.withValues(alpha: 0.2),
                border: Border.all(color: typeColor.withValues(alpha: 0.5)),
              ),
              child: Text(
                '$typeEmoji $typeLabel',
                style: TextStyle(
                  color: typeColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              card.titleDe,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            // Divider
            Container(
              width: 40,
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                color: typeColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            // Message
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  card.messageDe,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawButton() {
    return GestureDetector(
      onTap: _isDrawing ? null : _drawCard,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFD700).withValues(alpha: 0.3),
              const Color(0xFFFFD700).withValues(alpha: 0.1),
            ],
          ),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isDrawing)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                ),
              )
            else
              const Icon(Icons.auto_awesome,
                  color: Color(0xFFFFD700), size: 22),
            const SizedBox(width: 10),
            Text(
              _isDrawing ? 'Karte wird gezogen...' : 'Schicksalskarte ziehen',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardInfo() {
    if (_todayCard == null) return const SizedBox.shrink();
    final card = _todayCard!;
    final typeColor = Color(GamificationService.cardTypeColor(card.type));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: typeColor.withValues(alpha: 0.06),
        border: Border.all(color: typeColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  color: typeColor.withValues(alpha: 0.6), size: 16),
              const SizedBox(width: 6),
              Text(
                'Deine heutige Karte',
                style: TextStyle(
                  color: typeColor.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            card.messageDe,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    final history = _history.where((c) {
      // Heutige Karte bereits oben angezeigt
      final today = DateTime.now();
      final cardDay = c.drawnAt;
      return !(cardDay.year == today.year &&
          cardDay.month == today.month &&
          cardDay.day == today.day);
    }).toList();

    if (history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Letzte Karten',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),
        ...history.map((card) => _buildHistoryCard(card)),
      ],
    );
  }

  Widget _buildHistoryCard(DestinyCard card) {
    final typeColor = Color(GamificationService.cardTypeColor(card.type));
    final typeEmoji = GamificationService.cardTypeEmoji(card.type);
    final dayDiff = DateTime.now().difference(card.drawnAt).inDays;
    final dateLabel =
        dayDiff == 1 ? 'Gestern' : 'Vor $dayDiff Tagen';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: typeColor.withValues(alpha: 0.05),
          border: Border.all(color: typeColor.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Text(typeEmoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.titleDe,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: typeColor.withValues(alpha: 0.15),
              ),
              child: Text(
                GamificationService.cardTypeLabel(card.type),
                style: TextStyle(
                  color: typeColor.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _drawCard() async {
    setState(() => _isDrawing = true);

    // Kurze Verzögerung für dramatischen Effekt
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final card = await _gs.drawCard();
    if (card != null && mounted) {
      setState(() {
        _todayCard = card;
        _history = _gs.getCardHistory(days: 7);
        _isDrawing = false;
      });
      // Flip-Animation starten
      _flipCtrl.forward();
    } else {
      if (mounted) setState(() => _isDrawing = false);
    }
  }
}

/// AnimatedBuilder for the flip animation.
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) => builder(context, child);
}

/// Custom painter for the card back pattern.
class _CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw concentric circles
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 1; i <= 6; i++) {
      canvas.drawCircle(center, i * 30.0, paint);
    }

    // Draw diagonal lines
    for (var i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      final dx = cos(angle) * size.width;
      final dy = sin(angle) * size.height;
      canvas.drawLine(center, Offset(center.dx + dx, center.dy + dy), paint);
    }

    // Corner ornaments
    final cornerPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const m = 12.0; // margin
    const l = 30.0; // length

    // Top-left
    canvas.drawLine(
        const Offset(m, m + l), const Offset(m, m), cornerPaint);
    canvas.drawLine(
        const Offset(m, m), const Offset(m + l, m), cornerPaint);
    // Top-right
    canvas.drawLine(
        Offset(size.width - m, m + l), Offset(size.width - m, m), cornerPaint);
    canvas.drawLine(
        Offset(size.width - m, m), Offset(size.width - m - l, m), cornerPaint);
    // Bottom-left
    canvas.drawLine(
        Offset(m, size.height - m - l), Offset(m, size.height - m), cornerPaint);
    canvas.drawLine(
        Offset(m, size.height - m), Offset(m + l, size.height - m), cornerPaint);
    // Bottom-right
    canvas.drawLine(
        Offset(size.width - m, size.height - m - l),
        Offset(size.width - m, size.height - m),
        cornerPaint);
    canvas.drawLine(
        Offset(size.width - m, size.height - m),
        Offset(size.width - m - l, size.height - m),
        cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
