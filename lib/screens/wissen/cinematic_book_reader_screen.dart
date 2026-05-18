// Cinematic Book Reader Screen.
//
// Hyperrealistisches, kinoreifes Lese-Erlebnis fuer ein einzelnes Buch aus
// der Weltenbibliothek-Bibliothek. Ersetzt den klassischen Markdown-Reader
// durch einen 3-State-Ablauf:
//   1) Cover -> 3D-Tilt, ambient particles, world-tinted glow
//   2) Reading -> custom markdown render, progress bar, FAB toolbar
//   3) Zitate -> vertical swipeable quote cards (PageView)
//
// NOTE: Das Paket `flutter_markdown` ist im Projekt NICHT verfuegbar
// (siehe pubspec.yaml). Daher implementiert diese Datei einen schlanken
// RegEx-basierten Custom-Renderer fuer H1/H2/H3, Blockquotes, Bullet-Lists,
// Bold (**...**) und Italic (*...*). Reicht fuer Buch-Inhalte vollkommen.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/knowledge_extended_models.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_ambient_particles.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';

// ---------------------------------------------------------------------------
// World palette helper
// ---------------------------------------------------------------------------

class _Palette {
  final Color primary;
  final Color accent;
  final Color bg;
  final WBWorld world;
  final String sigil;

  const _Palette({
    required this.primary,
    required this.accent,
    required this.bg,
    required this.world,
    required this.sigil,
  });

  static _Palette forWorld(String world) {
    switch (world) {
      case 'materie':
        return const _Palette(
          primary: Color(0xFFE53935),
          accent: Color(0xFFFF6B6B),
          bg: Color(0xFF1A0505),
          world: WBWorld.materie,
          sigil: '\u{1F534}',
        );
      case 'energie':
        return const _Palette(
          primary: Color(0xFF7C4DFF),
          accent: Color(0xFFB39DDB),
          bg: Color(0xFF0A0420),
          world: WBWorld.energie,
          sigil: '⚡',
        );
      case 'vorhang':
        return const _Palette(
          primary: Color(0xFFC9A84C),
          accent: Color(0xFFFFD54F),
          bg: Color(0xFF0A0805),
          world: WBWorld.vorhang,
          sigil: '\u{1F3AD}',
        );
      case 'ursprung':
        return const _Palette(
          primary: Color(0xFF00D4AA),
          accent: Color(0xFF80FFEA),
          bg: Color(0xFF050510),
          world: WBWorld.ursprung,
          sigil: '\u{1F30C}',
        );
      default:
        return const _Palette(
          primary: Color(0xFF7C4DFF),
          accent: Color(0xFFB39DDB),
          bg: Color(0xFF0A0820),
          world: WBWorld.neutral,
          sigil: '\u{1F4D6}',
        );
    }
  }

  List<Color> coverGradient() {
    switch (world) {
      case WBWorld.materie:
        return const [Color(0xFF8B0000), Color(0xFF1A0505)];
      case WBWorld.energie:
        return const [Color(0xFF4A148C), Color(0xFF0A0420)];
      case WBWorld.vorhang:
        return const [Color(0xFFB8860B), Color(0xFF0A0805)];
      case WBWorld.ursprung:
        return const [Color(0xFF004D40), Color(0xFF050510)];
      case WBWorld.neutral:
        return const [Color(0xFF333333), Color(0xFF111111)];
    }
  }
}

// ---------------------------------------------------------------------------
// Reader state machine
// ---------------------------------------------------------------------------

enum _ReaderState { cover, reading }

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

class CinematicBookReaderScreen extends StatefulWidget {
  final KnowledgeEntry book;

  const CinematicBookReaderScreen({super.key, required this.book});

  @override
  State<CinematicBookReaderScreen> createState() =>
      _CinematicBookReaderScreenState();
}

class _CinematicBookReaderScreenState extends State<CinematicBookReaderScreen>
    with TickerProviderStateMixin {
  late final _Palette _palette;
  late final List<_MdBlock> _blocks;
  late final List<_Quote> _quotes;

  final ScrollController _scrollController = ScrollController();
  late final AnimationController _animCtrl; // pulse/orb anim
  late final AnimationController _tiltCtrl; // 3D cover tilt
  late final AnimationController _transitionCtrl; // cover -> reading slide

  _ReaderState _state = _ReaderState.cover;
  double _progress = 0.0;
  bool _isFavorite = false;
  int _personalViewCount = 0;
  String? _personalNote;

  static const String _favsKey = 'wissen_favs_v1';

  @override
  void initState() {
    super.initState();
    _palette = _Palette.forWorld(widget.book.world);
    _blocks = _parseMarkdown(widget.book.fullContent);
    _quotes = _extractQuotes(widget.book.fullContent);

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _tiltCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    _transitionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _scrollController.addListener(_onScroll);
    _loadPersistedState();
  }

  Future<void> _loadPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList(_favsKey) ?? <String>[];
    final views = prefs.getInt('wissen_views_${widget.book.id}') ?? 0;
    final note = prefs.getString('wissen_note_${widget.book.id}');
    // fire-and-forget bump
    await prefs.setInt('wissen_views_${widget.book.id}', views + 1);

    if (!mounted) return;
    setState(() {
      _isFavorite = favs.contains(widget.book.id);
      _personalViewCount = views + 1;
      _personalNote = note;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;
    final p = (_scrollController.position.pixels / max).clamp(0.0, 1.0);
    if ((p - _progress).abs() > 0.005) {
      setState(() => _progress = p);
    }
  }

  Future<void> _toggleFavorite() async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList(_favsKey) ?? <String>[];
    final bookId = widget.book.id;
    final newState = !favs.contains(bookId);
    if (newState) {
      favs.add(bookId);
    } else {
      favs.remove(bookId);
    }
    await prefs.setStringList(_favsKey, favs);
    if (!mounted) return;
    setState(() => _isFavorite = newState);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newState
              ? 'Zu deinen Favoriten hinzugefuegt'
              : 'Aus Favoriten entfernt',
        ),
        backgroundColor: _palette.primary.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareBook() {
    HapticFeedback.lightImpact();
    final author = widget.book.author;
    final hook = widget.book.description.split('.').first.trim();
    final buffer = StringBuffer()
      ..writeln(widget.book.title)
      ..writeln(author != null ? 'von $author' : '')
      ..writeln()
      ..writeln(hook.isNotEmpty ? hook : 'Aus der Weltenbibliothek.')
      ..writeln()
      ..writeln('-- Weltenbibliothek');
    Share.share(buffer.toString().trim(), subject: widget.book.title);
  }

  Future<void> _openNoteSheet() async {
    HapticFeedback.lightImpact();
    final controller = TextEditingController(text: _personalNote ?? '');
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: _palette.bg.withValues(alpha: 0.92),
                  border: Border(
                    top: BorderSide(
                      color: _palette.primary.withValues(alpha: 0.6),
                      width: 2,
                    ),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit_note,
                          color: _palette.accent,
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Deine Notiz',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: controller,
                      maxLines: 6,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Was nimmst du aus diesem Buch mit?',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _palette.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _palette.primary),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _palette.primary.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              'Abbrechen',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _palette.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () =>
                                Navigator.pop(ctx, controller.text.trim()),
                            child: const Text(
                              'Speichern',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (result == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (result.isEmpty) {
      await prefs.remove('wissen_note_${widget.book.id}');
    } else {
      await prefs.setString('wissen_note_${widget.book.id}', result);
    }
    if (!mounted) return;
    setState(() => _personalNote = result.isEmpty ? null : result);
  }

  void _startReading() {
    HapticFeedback.mediumImpact();
    _transitionCtrl.forward(from: 0.0);
    setState(() => _state = _ReaderState.reading);
  }

  void _openQuotes() {
    if (_quotes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keine Zitate in diesem Buch markiert.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, anim, __) {
          return FadeTransition(
            opacity: anim,
            child: _QuoteCardsOverlay(
              quotes: _quotes,
              palette: _palette,
              bookTitle: widget.book.title,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animCtrl.dispose();
    _tiltCtrl.dispose();
    _transitionCtrl.dispose();
    super.dispose();
  }

  // ------------------------------- BUILD -----------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _palette.bg,
      extendBodyBehindAppBar: true,
      appBar: _state == _ReaderState.reading
          ? PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight + 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WBGlassAppBar(
                    world: _palette.world,
                    titleWidget: Text(
                      _shortenTitle(widget.book.title, 28),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    actions: [
                      IconButton(
                        tooltip: 'Zitate',
                        onPressed: _openQuotes,
                        icon: Icon(
                          Icons.format_quote,
                          color: _palette.accent,
                        ),
                      ),
                    ],
                  ),
                  _ProgressBar(progress: _progress, color: _palette.primary),
                ],
              ),
            )
          : null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // World-tinted background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.4,
                colors: [
                  _palette.primary.withValues(alpha: 0.18),
                  _palette.bg,
                ],
              ),
            ),
          ),
          // Ambient particles + pulsing orbs (cover state only)
          if (_state == _ReaderState.cover) ...[
            Positioned.fill(
              child: IgnorePointer(
                child: WBAmbientParticles(
                  world: _palette.world,
                  count: 60,
                ),
              ),
            ),
            _buildPulsingOrbs(),
          ],
          // Main content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _state == _ReaderState.cover
                ? _buildCoverState()
                : _buildReadingState(),
          ),
          // Vignette
          const Positioned.fill(child: WBVignette()),
        ],
      ),
    );
  }

  // ------------------------------- ORBS ------------------------------------

  Widget _buildPulsingOrbs() {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, _) {
        final t = _animCtrl.value;
        final pulse1 = 0.55 + 0.25 * math.sin(t * 2 * math.pi);
        final pulse2 = 0.55 + 0.25 * math.sin(t * 2 * math.pi + math.pi);
        return Stack(
          children: [
            Positioned(
              top: -120,
              left: -80,
              child: _orb(220, _palette.accent.withValues(alpha: 0.10 * pulse1)),
            ),
            Positioned(
              bottom: -120,
              right: -80,
              child: _orb(260, _palette.primary.withValues(alpha: 0.12 * pulse2)),
            ),
          ],
        );
      },
    );
  }

  Widget _orb(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0.0)],
          ),
        ),
      ),
    );
  }

  // ------------------------------- COVER STATE ------------------------------

  Widget _buildCoverState() {
    return SafeArea(
      key: const ValueKey('cover'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          children: [
            // Top bar with back button
            Row(
              children: [
                _GlassIconButton(
                  icon: Icons.arrow_back,
                  color: _palette.accent,
                  onPressed: () => Navigator.maybePop(context),
                ),
                const Spacer(),
                _GlassIconButton(
                  icon: _isFavorite ? Icons.bookmark : Icons.bookmark_outline,
                  color: _isFavorite ? _palette.accent : Colors.white70,
                  onPressed: _toggleFavorite,
                ),
              ],
            ),
            const Spacer(),
            // 3D-Tilt Cover
            Center(child: _build3DCover()),
            const SizedBox(height: 32),
            // Titel
            Text(
              widget.book.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1.15,
                shadows: [
                  Shadow(
                    color: _palette.primary.withValues(alpha: 0.7),
                    blurRadius: 18,
                  ),
                ],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Autor + Jahr
            if (widget.book.author != null || widget.book.yearPublished != null)
              Text(
                _authorLine(widget.book.author, widget.book.yearPublished),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 16),
            // Tags
            if (widget.book.tags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: widget.book.tags.take(5).map((t) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _palette.primary.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '#$t',
                      style: TextStyle(
                        color: _palette.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            const Spacer(),
            // CTA Button
            _buildStartReadingButton(),
            const SizedBox(height: 12),
            // Meta-Info
            _buildMetaRow(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _build3DCover() {
    return AnimatedBuilder(
      animation: _tiltCtrl,
      builder: (context, child) {
        final t = _tiltCtrl.value;
        final rotY = (t - 0.5) * 0.3; // -0.15..+0.15 rad
        final rotX = math.sin(t * math.pi) * 0.05;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015) // perspective
            ..rotateY(rotY)
            ..rotateX(rotX),
          child: child,
        );
      },
      child: widget.book.imageUrl != null
          ? _networkCover(widget.book.imageUrl!)
          : _fallbackCover(),
    );
  }

  Widget _networkCover(String url) {
    return Container(
      width: 220,
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: _palette.primary.withValues(alpha: 0.55),
            blurRadius: 32,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackCover(),
          loadingBuilder: (ctx, child, prog) {
            if (prog == null) return child;
            return Center(
              child: CircularProgressIndicator(
                color: _palette.accent,
                strokeWidth: 2,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _fallbackCover() {
    return Container(
      width: 220,
      height: 320,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _palette.coverGradient(),
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _palette.primary, width: 1),
        boxShadow: [
          BoxShadow(
            color: _palette.primary.withValues(alpha: 0.55),
            blurRadius: 26,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_palette.sigil, style: const TextStyle(fontSize: 40)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.book.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.book.author != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.book.author!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStartReadingButton() {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, _) {
        final pulse = 0.85 + 0.15 * math.sin(_animCtrl.value * 2 * math.pi);
        return GestureDetector(
          onTap: _startReading,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _palette.primary,
                  _palette.accent,
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: _palette.primary.withValues(alpha: 0.6 * pulse),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_book, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  'Lesen starten',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetaRow() {
    final items = <Widget>[];
    items.add(
      _metaChip(
        Icons.schedule,
        '${widget.book.readingTimeMinutes} Min',
      ),
    );
    if (widget.book.rating > 0) {
      items.add(_metaChip(Icons.star, widget.book.rating.toStringAsFixed(1)));
    }
    if (_personalViewCount > 0) {
      items.add(_metaChip(Icons.visibility, '${_personalViewCount}x gelesen'));
    }
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: items,
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _palette.accent.withValues(alpha: 0.8), size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ------------------------------- READING STATE ----------------------------

  Widget _buildReadingState() {
    return Stack(
      key: const ValueKey('reading'),
      children: [
        // Slide-up entrance animation
        AnimatedBuilder(
          animation: _transitionCtrl,
          builder: (context, child) {
            final v = _transitionCtrl.value;
            return Transform.translate(
              offset: Offset(0, (1.0 - v) * 80),
              child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
            );
          },
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                24,
                140,
              ),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Buch-Header in der Reading-View
                  _buildReadingHeader(),
                  const SizedBox(height: 28),
                  // Markdown Content
                  ..._blocks.map(_renderBlock),
                  if (_personalNote != null && _personalNote!.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    _buildNotePreview(),
                  ],
                  const SizedBox(height: 24),
                  // Ende-Marker
                  Center(
                    child: Container(
                      width: 60,
                      height: 2,
                      color: _palette.primary.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Ende des Buches',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Floating Action Bar
        Positioned(
          left: 16,
          right: 16,
          bottom: 16 + MediaQuery.of(context).padding.bottom,
          child: _buildFloatingActionBar(),
        ),
      ],
    );
  }

  Widget _buildReadingHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.book.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.15,
            shadows: [
              Shadow(
                color: _palette.primary.withValues(alpha: 0.5),
                blurRadius: 12,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (widget.book.author != null || widget.book.yearPublished != null)
          Text(
            _authorLine(widget.book.author, widget.book.yearPublished),
            style: TextStyle(
              color: _palette.accent.withValues(alpha: 0.85),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        const SizedBox(height: 12),
        if (widget.book.description.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border(
                left: BorderSide(color: _palette.primary, width: 3),
              ),
            ),
            child: Text(
              widget.book.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNotePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _palette.primary.withValues(alpha: 0.18),
            _palette.accent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _palette.accent.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: _palette.accent, size: 18),
              const SizedBox(width: 6),
              Text(
                'Deine Notiz',
                style: TextStyle(
                  color: _palette.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _personalNote!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _palette.primary.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _fabAction(
                _isFavorite ? Icons.bookmark : Icons.bookmark_outline,
                _isFavorite ? 'Favorit' : 'Merken',
                _palette.accent,
                _toggleFavorite,
              ),
              _fabAction(
                Icons.share_outlined,
                'Teilen',
                Colors.white70,
                _shareBook,
              ),
              _fabAction(
                Icons.edit_note,
                _personalNote == null ? 'Notiz' : 'Notiz ...',
                _personalNote == null ? Colors.white70 : _palette.accent,
                _openNoteSheet,
              ),
              _fabAction(
                Icons.format_quote,
                'Zitate (${_quotes.length})',
                _palette.accent,
                _openQuotes,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fabAction(IconData icon, String label, Color color, VoidCallback tap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------- MARKDOWN RENDERER ------------------------

  Widget _renderBlock(_MdBlock block) {
    switch (block.type) {
      case _MdBlockType.h1:
        return Padding(
          padding: const EdgeInsets.only(top: 28, bottom: 14),
          child: Text(
            block.text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.2,
              shadows: [
                Shadow(
                  color: _palette.primary.withValues(alpha: 0.5),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        );
      case _MdBlockType.h2:
        return Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 10),
          child: Text(
            block.text,
            style: TextStyle(
              color: _palette.accent,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        );
      case _MdBlockType.h3:
        return Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: Text(
            block.text,
            style: TextStyle(
              color: _palette.accent.withValues(alpha: 0.9),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        );
      case _MdBlockType.quote:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
            decoration: BoxDecoration(
              color: _palette.primary.withValues(alpha: 0.08),
              border: Border(
                left: BorderSide(color: _palette.primary, width: 4),
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: _richInline(
              block.text,
              base: TextStyle(
                color: _palette.accent,
                fontSize: 17,
                fontStyle: FontStyle.italic,
                height: 1.55,
              ),
            ),
          ),
        );
      case _MdBlockType.bullet:
        return Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 0, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 10),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _palette.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _palette.primary.withValues(alpha: 0.7),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _richInline(
                  block.text,
                  base: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 15,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        );
      case _MdBlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: _richInline(
            block.text,
            base: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 15.5,
              height: 1.65,
              letterSpacing: 0.1,
            ),
          ),
        );
    }
  }

  // Inline parser for **bold**, *italic*, `code`.
  Widget _richInline(String input, {required TextStyle base}) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'(\*\*[^*]+\*\*|\*[^*]+\*|`[^`]+`)');
    int last = 0;
    for (final m in pattern.allMatches(input)) {
      if (m.start > last) {
        spans.add(TextSpan(text: input.substring(last, m.start)));
      }
      final raw = m.group(0)!;
      if (raw.startsWith('**')) {
        spans.add(
          TextSpan(
            text: raw.substring(2, raw.length - 2),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        );
      } else if (raw.startsWith('`')) {
        spans.add(
          TextSpan(
            text: raw.substring(1, raw.length - 1),
            style: TextStyle(
              fontFamily: 'monospace',
              color: _palette.accent,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: raw.substring(1, raw.length - 1),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      }
      last = m.end;
    }
    if (last < input.length) {
      spans.add(TextSpan(text: input.substring(last)));
    }
    return SelectableText.rich(
      TextSpan(style: base, children: spans),
    );
  }

  // ------------------------------- UTILS ------------------------------------

  static String _authorLine(String? author, int? year) {
    if (author != null && year != null) return '$author  -  $year';
    if (author != null) return author;
    if (year != null) return '$year';
    return '';
  }

  static String _shortenTitle(String t, int max) {
    if (t.length <= max) return t;
    return '${t.substring(0, max - 1)}…';
  }
}

// ---------------------------------------------------------------------------
// Glass icon button (small)
// ---------------------------------------------------------------------------

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _GlassIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.white.withValues(alpha: 0.06),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: color, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress bar
// ---------------------------------------------------------------------------

class _ProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  const _ProgressBar({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: Stack(
        children: [
          Container(color: Colors.white.withValues(alpha: 0.06)),
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.7),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Markdown parser (lightweight, regex-based)
// ---------------------------------------------------------------------------

enum _MdBlockType { h1, h2, h3, quote, bullet, paragraph }

class _MdBlock {
  final _MdBlockType type;
  final String text;
  const _MdBlock(this.type, this.text);
}

List<_MdBlock> _parseMarkdown(String src) {
  final blocks = <_MdBlock>[];
  if (src.trim().isEmpty) {
    return [const _MdBlock(_MdBlockType.paragraph, '(Kein Inhalt vorhanden.)')];
  }
  final lines = src.replaceAll('\r\n', '\n').split('\n');

  final paraBuf = StringBuffer();
  void flushPara() {
    final txt = paraBuf.toString().trim();
    paraBuf.clear();
    if (txt.isEmpty) return;
    blocks.add(_MdBlock(_MdBlockType.paragraph, txt));
  }

  for (final rawLine in lines) {
    final line = rawLine.trimRight();
    if (line.trim().isEmpty) {
      flushPara();
      continue;
    }
    if (line.startsWith('# ')) {
      flushPara();
      blocks.add(_MdBlock(_MdBlockType.h1, line.substring(2).trim()));
    } else if (line.startsWith('## ')) {
      flushPara();
      blocks.add(_MdBlock(_MdBlockType.h2, line.substring(3).trim()));
    } else if (line.startsWith('### ')) {
      flushPara();
      blocks.add(_MdBlock(_MdBlockType.h3, line.substring(4).trim()));
    } else if (line.startsWith('> ')) {
      flushPara();
      blocks.add(_MdBlock(_MdBlockType.quote, line.substring(2).trim()));
    } else if (line.trimLeft().startsWith('- ') ||
        line.trimLeft().startsWith('* ')) {
      flushPara();
      final stripped = line.trimLeft();
      blocks.add(_MdBlock(_MdBlockType.bullet, stripped.substring(2).trim()));
    } else if (RegExp(r'^\d+\.\s').hasMatch(line.trimLeft())) {
      flushPara();
      final stripped = line.trimLeft();
      final idx = stripped.indexOf('. ');
      blocks.add(
        _MdBlock(_MdBlockType.bullet, stripped.substring(idx + 2).trim()),
      );
    } else if (line.startsWith('---') || line.startsWith('___')) {
      flushPara();
      // ignore horizontal rules (no dedicated style)
    } else {
      if (paraBuf.isNotEmpty) paraBuf.write(' ');
      paraBuf.write(line.trim());
    }
  }
  flushPara();
  return blocks;
}

// Extracts blockquote-style citations: lines beginning with `> "..."` or `> ...`.
class _Quote {
  final String text;
  final String? source;
  const _Quote(this.text, this.source);
}

List<_Quote> _extractQuotes(String src) {
  final list = <_Quote>[];
  final lines = src.replaceAll('\r\n', '\n').split('\n');
  String? pendingQuote;
  for (final raw in lines) {
    final line = raw.trim();
    if (line.startsWith('> ')) {
      final inner = line.substring(2).trim();
      if (pendingQuote != null) {
        pendingQuote = '$pendingQuote $inner';
      } else {
        pendingQuote = inner;
      }
    } else if (line.startsWith('--') && pendingQuote != null) {
      list.add(_Quote(_stripQuoteMarks(pendingQuote), line.replaceAll(RegExp(r'^-+\s*'), '').trim()));
      pendingQuote = null;
    } else {
      if (pendingQuote != null) {
        list.add(_Quote(_stripQuoteMarks(pendingQuote), null));
        pendingQuote = null;
      }
    }
  }
  if (pendingQuote != null) {
    list.add(_Quote(_stripQuoteMarks(pendingQuote), null));
  }
  return list;
}

String _stripQuoteMarks(String s) {
  var t = s.trim();
  if (t.startsWith('"') && t.endsWith('"') && t.length > 1) {
    t = t.substring(1, t.length - 1).trim();
  }
  if (t.startsWith('„') && t.endsWith('“') && t.length > 1) {
    t = t.substring(1, t.length - 1).trim();
  }
  return t;
}

// ---------------------------------------------------------------------------
// Quote cards overlay (vertical PageView)
// ---------------------------------------------------------------------------

class _QuoteCardsOverlay extends StatefulWidget {
  final List<_Quote> quotes;
  final _Palette palette;
  final String bookTitle;

  const _QuoteCardsOverlay({
    required this.quotes,
    required this.palette,
    required this.bookTitle,
  });

  @override
  State<_QuoteCardsOverlay> createState() => _QuoteCardsOverlayState();
}

class _QuoteCardsOverlayState extends State<_QuoteCardsOverlay> {
  final PageController _pageCtrl = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _copyCurrent() async {
    final q = widget.quotes[_index];
    final txt = q.source != null ? '"${q.text}" -- ${q.source}' : '"${q.text}"';
    await Clipboard.setData(ClipboardData(text: txt));
    if (!mounted) return;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Zitat in die Zwischenablage kopiert.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _next() {
    if (_index >= widget.quotes.length - 1) {
      Navigator.maybePop(context);
      return;
    }
    _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    p.bg.withValues(alpha: 0.95),
                    Colors.black.withValues(alpha: 0.98),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: WBAmbientParticles(world: p.world, count: 40),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Zitate aus "${_shortTitle(widget.bookTitle)}"',
                            style: TextStyle(
                              color: p.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                // PageView (vertikal swipe)
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    scrollDirection: Axis.vertical,
                    itemCount: widget.quotes.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (ctx, i) {
                      final q = widget.quotes[i];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(28, 30, 28, 30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.format_quote,
                              color: p.accent.withValues(alpha: 0.7),
                              size: 56,
                            ),
                            const SizedBox(height: 20),
                            Flexible(
                              child: SingleChildScrollView(
                                child: Text(
                                  q.text,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontStyle: FontStyle.italic,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                    shadows: [
                                      Shadow(
                                        color: p.primary.withValues(alpha: 0.55),
                                        blurRadius: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (q.source != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  '-- ${q.source}',
                                  style: TextStyle(
                                    color: p.accent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Action row
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                  child: Row(
                    children: [
                      Expanded(
                        child: _quoteActionBtn(
                          Icons.copy,
                          'Kopieren',
                          p,
                          _copyCurrent,
                          filled: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _quoteActionBtn(
                          _index >= widget.quotes.length - 1
                              ? Icons.check
                              : Icons.arrow_downward,
                          _index >= widget.quotes.length - 1
                              ? 'Fertig'
                              : 'Weiter',
                          p,
                          _next,
                          filled: true,
                        ),
                      ),
                    ],
                  ),
                ),
                // Indicator
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.quotes.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 22 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active
                              ? p.primary
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const Positioned.fill(child: IgnorePointer(child: WBVignette())),
        ],
      ),
    );
  }

  Widget _quoteActionBtn(
    IconData icon,
    String label,
    _Palette p,
    VoidCallback onTap, {
    required bool filled,
  }) {
    return Material(
      color: filled
          ? p.primary
          : Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: filled
                ? null
                : Border.all(color: p.accent.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _shortTitle(String t) {
    return t.length <= 30 ? t : '${t.substring(0, 29)}…';
  }
}
