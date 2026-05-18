// 3D Bookshelf View - cinematic library background for the Wissen tab.
// Puts the user INTO a library: vertical wooden shelves, leather-bound spines
// in world accent colors, with tap-to-fly-out 3D animation per book.
//
// Design goals:
// - One CustomPaint per shelf board (cheap), spines are real widgets so they
//   can host gesture + animation state without re-painting siblings.
// - Each `_BookSpine` owns its own AnimationController -> no global rebuild
//   when a book is tapped.
// - World-specific wood + glow themes via `_ShelfTheme.forWorld(world)`.
// - Title text rendered vertically (RotatedBox quarterTurns: 3) along the
//   leather spine for the classic library look.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/knowledge_extended_models.dart';
// ignore: unused_import
import '../../theme/wb_cinematic_tokens.dart';

/// Number of books rendered per wooden shelf row.
const int _booksPerShelf = 7;

/// Height reserved for one shelf row (book area + wood board).
const double _shelfRowHeight = 168;

/// Wood board thickness at the bottom of each shelf row.
const double _boardThickness = 14;

/// Min / max heights for individual book spines (px).
const double _bookMinHeight = 82;
const double _bookMaxHeight = 132;

/// Min / max widths for individual book spines (px).
const double _bookMinWidth = 22;
const double _bookMaxWidth = 42;

/// Public 3D bookshelf widget. The parent feeds an already-filtered list.
class Bookshelf3DView extends StatelessWidget {
  final List<KnowledgeEntry> books;
  final String world;
  final void Function(KnowledgeEntry) onTap;

  const Bookshelf3DView({
    super.key,
    required this.books,
    required this.world,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = _ShelfTheme.forWorld(world);

    if (books.isEmpty) {
      return _EmptyShelfState(theme: theme);
    }

    // Split into shelves of fixed size; last shelf can be partial.
    final shelves = <List<KnowledgeEntry>>[];
    for (var i = 0; i < books.length; i += _booksPerShelf) {
      final end = math.min(i + _booksPerShelf, books.length);
      shelves.add(books.sublist(i, end));
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        // Soft cinematic backdrop: world glow + dark vignette.
        gradient: RadialGradient(
          center: const Alignment(0, -0.4),
          radius: 1.4,
          colors: [
            theme.ambientGlow.withValues(alpha: 0.22),
            const Color(0xFF0A0708),
          ],
          stops: const [0.0, 0.85],
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: shelves.length,
        // Slight cache extent so off-screen spines pre-mount their controllers.
        cacheExtent: 600,
        itemBuilder: (context, index) {
          return _ShelfRow(
            books: shelves[index],
            theme: theme,
            shelfIndex: index,
            onTap: onTap,
          );
        },
      ),
    );
  }
}

/// One horizontal shelf row: book band + wooden board underneath.
class _ShelfRow extends StatelessWidget {
  final List<KnowledgeEntry> books;
  final _ShelfTheme theme;
  final int shelfIndex;
  final void Function(KnowledgeEntry) onTap;

  const _ShelfRow({
    required this.books,
    required this.theme,
    required this.shelfIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _shelfRowHeight,
      child: Stack(
        children: [
          // Back wall: subtle vertical gradient suggesting depth behind books.
          Positioned.fill(
            child: CustomPaint(
              painter: _BackWallPainter(theme: theme),
            ),
          ),
          // Books band - aligned to the bottom so spines "stand" on the board.
          Positioned(
            left: 12,
            right: 12,
            bottom: _boardThickness,
            top: 6,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < books.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: _BookSpine(
                        book: books[i],
                        theme: theme,
                        // Deterministic randomness so layout is stable across
                        // rebuilds. Same book id -> same height/width/tilt.
                        seed: _seedFor(books[i], shelfIndex, i),
                        onTap: onTap,
                      ),
                    ),
                  // Pad short shelves with a couple of decorative "filler"
                  // books so the row never looks visually broken.
                  if (books.length < _booksPerShelf)
                    for (var i = books.length; i < _booksPerShelf; i++)
                      _DecorativeFillerSpine(
                        theme: theme,
                        seed: shelfIndex * 31 + i * 7,
                      ),
                ],
              ),
            ),
          ),
          // Wooden shelf board at the bottom.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _boardThickness,
            child: CustomPaint(
              painter: _ShelfBoardPainter(theme: theme),
            ),
          ),
        ],
      ),
    );
  }

  int _seedFor(KnowledgeEntry book, int shelfIdx, int slotIdx) {
    // Combine id hashCode with positional info for stable variance.
    return book.id.hashCode ^ (shelfIdx * 1009) ^ (slotIdx * 17);
  }
}

/// Painter for the backdrop behind each shelf row.
class _BackWallPainter extends CustomPainter {
  final _ShelfTheme theme;
  const _BackWallPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          theme.wallTop,
          theme.wallBottom,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _BackWallPainter oldDelegate) =>
      oldDelegate.theme != theme;
}

/// Painter for one wooden shelf board (single Paint call, 1 gradient).
class _ShelfBoardPainter extends CustomPainter {
  final _ShelfTheme theme;
  const _ShelfBoardPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final boardRect = Offset.zero & size;

    // Drop shadow underneath the shelf - sells the depth.
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 3, size.width, 8),
      shadowPaint,
    );

    // Wood grain gradient.
    final woodPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          theme.woodLight,
          theme.woodDark,
          Colors.black,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(boardRect);
    canvas.drawRect(boardRect, woodPaint);

    // Subtle wood grain striations.
    final grainPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = 0.6;
    final rng = math.Random(theme.hashCode);
    for (var i = 0; i < 18; i++) {
      final y = rng.nextDouble() * size.height;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + (rng.nextDouble() - 0.5) * 2),
        grainPaint,
      );
    }

    // 1px world-accent underline (light catch on the front lip).
    final accentPaint = Paint()
      ..color = theme.accent.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, 1),
      Offset(size.width, 1),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ShelfBoardPainter oldDelegate) =>
      oldDelegate.theme != theme;
}

/// A single tappable, animated book spine.
class _BookSpine extends StatefulWidget {
  final KnowledgeEntry book;
  final _ShelfTheme theme;
  final int seed;
  final void Function(KnowledgeEntry) onTap;

  const _BookSpine({
    required this.book,
    required this.theme,
    required this.seed,
    required this.onTap,
  });

  @override
  State<_BookSpine> createState() => _BookSpineState();
}

class _BookSpineState extends State<_BookSpine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _tilt;
  late final Animation<double> _glow;

  // Per-book derived layout (stable per build).
  late final double _height;
  late final double _width;
  late final double _baseTiltDeg;
  late final Color _spineColor;
  late final Color _spineColorEdge;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 260),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.15)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_ctrl);
    _tilt = Tween<double>(begin: 0, end: -10 * math.pi / 180)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_ctrl);
    _glow = Tween<double>(begin: 0, end: 1)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_ctrl);

    final rng = math.Random(widget.seed);

    // Variable height based on title length (longer title -> taller book,
    // capped). Adds character to the row.
    final titleLen = widget.book.title.length.clamp(4, 60);
    final heightT = 0.3 + (titleLen / 60) * 0.7 + (rng.nextDouble() - 0.5) * 0.2;
    _height = lerpDouble(_bookMinHeight, _bookMaxHeight, heightT.clamp(0.0, 1.0))!;

    final widthT = rng.nextDouble();
    _width = lerpDouble(_bookMinWidth, _bookMaxWidth, widthT)!;

    // Tiny natural lean so the row doesn't look surgical.
    _baseTiltDeg = (rng.nextDouble() - 0.5) * 3.0;

    // World accent with hue variance.
    final variance = (rng.nextDouble() - 0.5) * 0.18;
    _spineColor = _shiftColor(widget.theme.accent, variance);
    _spineColorEdge = _shiftColor(widget.theme.accentDark, variance * 0.5);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    HapticFeedback.selectionClick();
    await _ctrl.forward();
    if (!mounted) return;
    // Slight hold so the user sees the book fly forward before navigation.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    widget.onTap(widget.book);
    // Reverse so the visible spine resets if user returns to the shelf.
    if (mounted) {
      _ctrl.reverse();
    }
  }

  bool get _isLegendary {
    final tags = widget.book.tags;
    final hasBossTag =
        tags.any((t) => t.toLowerCase() == 'boss' || t.toLowerCase() == 'legendary');
    final highRating = widget.book.rating > 4.7;
    return hasBossTag || highRating;
  }

  bool get _hasImage => widget.book.imageUrl != null && widget.book.imageUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final tiltRad = _tilt.value + (_baseTiltDeg * math.pi / 180);
          final m = Matrix4.identity()
            ..setEntry(3, 2, 0.0015) // perspective
            ..rotateX(tiltRad)
            ..scale(_scale.value);
          return Transform(
            alignment: Alignment.bottomCenter,
            transform: m,
            child: child,
          );
        },
        child: _buildSpine(),
      ),
    );
  }

  Widget _buildSpine() {
    final radius = BorderRadius.circular(3);

    return AnimatedBuilder(
      animation: _glow,
      builder: (context, _) {
        final glowAlpha = _isLegendary
            ? (0.55 + _glow.value * 0.35)
            : (0.18 + _glow.value * 0.45);

        return Container(
          width: _width,
          height: _height,
          decoration: BoxDecoration(
            borderRadius: radius,
            // Leather spine gradient.
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                _spineColorEdge,
                _spineColor,
                _spineColor,
                _spineColorEdge.withValues(alpha: 0.85),
              ],
              stops: const [0.0, 0.18, 0.82, 1.0],
            ),
            boxShadow: [
              // Tight contact shadow on board.
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 3,
                offset: const Offset(1.2, 1.2),
              ),
              // Accent / legendary glow.
              BoxShadow(
                color: (_isLegendary
                        ? const Color(0xFFFFD66B)
                        : widget.theme.accent)
                    .withValues(alpha: glowAlpha),
                blurRadius: _isLegendary ? 14 : 8,
                spreadRadius: _isLegendary ? 1.2 : 0,
              ),
            ],
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.4),
              width: 0.6,
            ),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Subtle vertical highlight (leather sheen).
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.10),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        stops: const [0.35, 0.5, 0.65],
                      ),
                    ),
                  ),
                ),
                // Decorative gold bands top + bottom (classic leather binding).
                Positioned(
                  top: 6,
                  left: 2,
                  right: 2,
                  child: _goldBand(),
                ),
                Positioned(
                  bottom: 6,
                  left: 2,
                  right: 2,
                  child: _goldBand(),
                ),
                // Vertical title text.
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 1),
                  child: Center(
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        widget.book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFFE9D9B0),
                          fontSize: _width < 28 ? 8.5 : 9.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          shadows: const [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Image-marker sticker (small dot near the bottom).
                if (_hasImage)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 18,
                    child: Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD66B),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD66B)
                                  .withValues(alpha: 0.6),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Legendary crown indicator.
                if (_isLegendary)
                  const Positioned(
                    top: 2,
                    left: 0,
                    right: 0,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 9,
                      color: Color(0xFFFFE08A),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _goldBand() {
    return Container(
      height: 1.2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFB8860B).withValues(alpha: 0.0),
            const Color(0xFFFFD66B).withValues(alpha: 0.85),
            const Color(0xFFB8860B).withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

/// Static decorative filler used to round out short shelves.
class _DecorativeFillerSpine extends StatelessWidget {
  final _ShelfTheme theme;
  final int seed;

  const _DecorativeFillerSpine({required this.theme, required this.seed});

  @override
  Widget build(BuildContext context) {
    final rng = math.Random(seed);
    final h = lerpDouble(_bookMinHeight, _bookMaxHeight - 20, rng.nextDouble())!;
    final w = lerpDouble(_bookMinWidth, _bookMaxWidth, rng.nextDouble())!;
    final color = _shiftColor(theme.woodLight, (rng.nextDouble() - 0.5) * 0.1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5),
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              color.withValues(alpha: 0.7),
              color.withValues(alpha: 0.45),
            ],
          ),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.45),
            width: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Empty-state when no books match.
class _EmptyShelfState extends StatelessWidget {
  final _ShelfTheme theme;
  const _EmptyShelfState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            theme.ambientGlow.withValues(alpha: 0.25),
            const Color(0xFF0A0708),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Empty wooden shelf graphic.
              SizedBox(
                width: 220,
                height: _shelfRowHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _BackWallPainter(theme: theme)),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: _boardThickness,
                      child: CustomPaint(
                        painter: _ShelfBoardPainter(theme: theme),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Hier entstehen neue Schaetze',
                style: TextStyle(
                  color: theme.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Schau bald wieder vorbei.',
                style: TextStyle(
                  color: Color(0xFFB8AFA1),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Color palette per world. Holds wood + accent + ambient glow tuning that
/// drives the cinematic atmosphere unique to each world.
@immutable
class _ShelfTheme {
  final Color woodLight;
  final Color woodDark;
  final Color wallTop;
  final Color wallBottom;
  final Color accent;
  final Color accentDark;
  final Color ambientGlow;

  const _ShelfTheme({
    required this.woodLight,
    required this.woodDark,
    required this.wallTop,
    required this.wallBottom,
    required this.accent,
    required this.accentDark,
    required this.ambientGlow,
  });

  static _ShelfTheme forWorld(String world) {
    switch (world.toLowerCase()) {
      case 'materie':
        // Industrial-wood, red glow - skeptic's library vibe.
        return const _ShelfTheme(
          woodLight: Color(0xFF4A2E22),
          woodDark: Color(0xFF1F140F),
          wallTop: Color(0xFF1A0E0B),
          wallBottom: Color(0xFF0A0605),
          accent: Color(0xFFE5564A),
          accentDark: Color(0xFF7A1F18),
          ambientGlow: Color(0xFFD83A2C),
        );
      case 'energie':
        // Brighter mandala wood, purple glow - temple library.
        return const _ShelfTheme(
          woodLight: Color(0xFF5A3F6E),
          woodDark: Color(0xFF20142C),
          wallTop: Color(0xFF1A0F26),
          wallBottom: Color(0xFF0A0612),
          accent: Color(0xFFB48BFF),
          accentDark: Color(0xFF5A36A8),
          ambientGlow: Color(0xFF8B5CF6),
        );
      case 'vorhang':
        // Dark mahogany, gold spotlights - old-money studio.
        return const _ShelfTheme(
          woodLight: Color(0xFF3A1F12),
          woodDark: Color(0xFF14080A),
          wallTop: Color(0xFF180F0A),
          wallBottom: Color(0xFF080404),
          accent: Color(0xFFFFD66B),
          accentDark: Color(0xFF8A6210),
          ambientGlow: Color(0xFFFFB347),
        );
      case 'ursprung':
        // Raw natural wood, greenish moonlight - indigenous carvings.
        return const _ShelfTheme(
          woodLight: Color(0xFF55452B),
          woodDark: Color(0xFF1E1810),
          wallTop: Color(0xFF0F1410),
          wallBottom: Color(0xFF050807),
          accent: Color(0xFF6BE3C8),
          accentDark: Color(0xFF1F7A66),
          ambientGlow: Color(0xFF3FB8A4),
        );
      default:
        return const _ShelfTheme(
          woodLight: Color(0xFF3A2A1E),
          woodDark: Color(0xFF14100C),
          wallTop: Color(0xFF14100C),
          wallBottom: Color(0xFF06050A),
          accent: Color(0xFFC8B07A),
          accentDark: Color(0xFF5E4A28),
          ambientGlow: Color(0xFFB59060),
        );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is _ShelfTheme &&
      other.woodLight == woodLight &&
      other.woodDark == woodDark &&
      other.wallTop == wallTop &&
      other.wallBottom == wallBottom &&
      other.accent == accent &&
      other.accentDark == accentDark &&
      other.ambientGlow == ambientGlow;

  @override
  int get hashCode => Object.hash(
        woodLight,
        woodDark,
        wallTop,
        wallBottom,
        accent,
        accentDark,
        ambientGlow,
      );
}

/// Shift an RGB color uniformly by `delta` (-1..1) to add variance to spines.
Color _shiftColor(Color base, double delta) {
  final r = (base.r * 255.0).round();
  final g = (base.g * 255.0).round();
  final b = (base.b * 255.0).round();
  final shift = (delta * 50).round();
  int clamp(int v) => v.clamp(0, 255);
  return Color.fromARGB(
    (base.a * 255.0).round(),
    clamp(r + shift),
    clamp(g + shift),
    clamp(b + shift),
  );
}
