// 📚 Secret Library Screen — Die Geheime Bibliothek
//
// Zugang ab Global-Level 10. Zeigt Bücher in 6 Kategorien.

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../services/gamification_service.dart';
import 'book_detail_screen.dart';

class SecretLibraryScreen extends StatefulWidget {
  const SecretLibraryScreen({super.key});

  static const int requiredLevel = 10;

  @override
  State<SecretLibraryScreen> createState() => _SecretLibraryScreenState();
}

class _SecretLibraryScreenState extends State<SecretLibraryScreen>
    with TickerProviderStateMixin {
  // dart2js stolpert über const List<Record> → final Liste umgangen.
  static final List<(String, String)> _categories = <(String, String)>[
    ('CIA', 'cia'),
    ('Hermetik', 'hermetik'),
    ('Alchemie', 'alchemie'),
    ('Quantenphysik', 'quantenphysik'),
    ('Philosophie', 'philosophie'),
    ('Mystik', 'mystik'),
  ];

  late final AnimationController _candleCtrl;
  late final TabController _tabCtrl;
  int _level = 0;

  @override
  void initState() {
    super.initState();
    _candleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _tabCtrl = TabController(length: _categories.length, vsync: this);
    _level = GamificationService().globalLevel;
  }

  @override
  void dispose() {
    _candleCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  bool get _unlocked => _level >= SecretLibraryScreen.requiredLevel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0F00),
      body: Stack(
        children: [
          // Candle Glow Animation
          AnimatedBuilder(
            animation: _candleCtrl,
            builder: (context, _) {
              final t = _candleCtrl.value;
              return Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.6),
                      radius: 1.2 + math.sin(t * math.pi * 2) * 0.05,
                      colors: [
                        const Color(0xFFC9A84C)
                            .withValues(alpha: 0.10 + t * 0.04),
                        const Color(0xFF1A0F00).withValues(alpha: 0.95),
                        const Color(0xFF1A0F00),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: _unlocked ? _buildUnlocked() : _buildLocked(),
          ),
        ],
      ),
    );
  }

  // ─── LOCKED VIEW ─────────────────────────────────────────────────
  Widget _buildLocked() {
    final progress =
        (_level / SecretLibraryScreen.requiredLevel).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFFF5E6C8)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Spacer(),
          Icon(
            Icons.lock_outline,
            size: 96,
            color: const Color(0xFFC9A84C).withValues(alpha: 0.7),
          ),
          const SizedBox(height: 24),
          const Text(
            'Die Bibliothek ist noch verschlossen',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFF5E6C8),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Erreiche Level ${SecretLibraryScreen.requiredLevel}, um die Originalquellen freizuschalten.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFE0C872).withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFC9A84C)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Level $_level / ${SecretLibraryScreen.requiredLevel}',
            style: const TextStyle(
              color: Color(0xFFE0C872),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  // ─── UNLOCKED VIEW ───────────────────────────────────────────────
  Widget _buildUnlocked() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFFF5E6C8)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Text('📚', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Die Geheime Bibliothek',
                  style: TextStyle(
                    color: Color(0xFFF5E6C8),
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFFC9A84C).withValues(alpha: 0.3),
              ),
            ),
          ),
          child: TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: const Color(0xFFC9A84C),
            unselectedLabelColor:
                const Color(0xFFE0C872).withValues(alpha: 0.55),
            indicatorColor: const Color(0xFFC9A84C),
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.8),
            tabs: _categories.map((c) => Tab(text: c.$1)).toList(),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: _categories
                .map((c) => _BookGrid(category: c.$2, key: ValueKey(c.$2)))
                .toList(),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// _BookGrid — pro Kategorie eigene Fetch + Cache
// ════════════════════════════════════════════════════════════════════

class _BookGrid extends StatefulWidget {
  final String category;
  const _BookGrid({super.key, required this.category});

  @override
  State<_BookGrid> createState() => _BookGridState();
}

class _BookGridState extends State<_BookGrid>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>>? _books;
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http
          .get(
            Uri.parse(
                '${ApiConfig.workerUrl}/api/bibliothek/books?category=${widget.category}'),
            headers: ApiConfig.publicHeaders,
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw HttpException('HTTP ${res.statusCode}');
      }
      final json = jsonDecode(res.body);
      final List items = (json is Map && json['books'] is List)
          ? json['books'] as List
          : (json is List ? json : const []);
      final books = items
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (!mounted) return;
      setState(() {
        _books = books;
        _loading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ SecretLibrary fetch: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const _ShimmerGrid();
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: Color(0xFFC9A84C), size: 40),
              const SizedBox(height: 12),
              const Text(
                'Bücher konnten nicht geladen werden.',
                style: TextStyle(color: Color(0xFFEBE3D2)),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC9A84C),
                  foregroundColor: const Color(0xFF1A0F00),
                ),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      );
    }
    final books = _books ?? const [];
    if (books.isEmpty) {
      return const Center(
        child: Text(
          'Noch keine Bücher in dieser Kategorie.',
          style: TextStyle(color: Color(0xFFE0C872)),
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFFC9A84C),
      backgroundColor: const Color(0xFF2A1B05),
      onRefresh: _fetch,
      child: GridView.builder(
        padding: const EdgeInsets.all(14),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
        itemCount: books.length,
        itemBuilder: (_, i) => _BookCard(book: books[i]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// _BookCard
// ════════════════════════════════════════════════════════════════════

class _BookCard extends StatelessWidget {
  final Map<String, dynamic> book;
  const _BookCard({required this.book});

  Color get _coverColor {
    final hex = book['cover_color'] as String?;
    if (hex != null && hex.startsWith('#') && hex.length == 7) {
      try {
        return Color(int.parse('FF${hex.substring(1)}', radix: 16));
      } catch (e) { if (kDebugMode) debugPrint('secret_library_screen: silent catch -> $e'); }
    }
    return const Color(0xFF5D4037);
  }

  @override
  Widget build(BuildContext context) {
    final id = (book['id'] as String?) ?? (book['title'] as String? ?? '');
    final title = (book['title'] as String?) ?? 'Ohne Titel';
    final author = (book['author'] as String?) ?? 'Unbekannt';
    final year = book['year']?.toString() ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
        );
      },
      child: Hero(
        tag: 'book_cover_$id',
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_coverColor, _coverColor.withValues(alpha: 0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFFC9A84C).withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.menu_book, color: Color(0xFFF5E6C8), size: 26),
              const Spacer(),
              Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFF5E6C8),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFE0C872),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (year.isNotEmpty)
                Text(
                  year,
                  style: TextStyle(
                    color: const Color(0xFFE0C872).withValues(alpha: 0.7),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// _ShimmerGrid — animierte Pergament-Skeletons
// ════════════════════════════════════════════════════════════════════

class _ShimmerGrid extends StatefulWidget {
  const _ShimmerGrid();
  @override
  State<_ShimmerGrid> createState() => _ShimmerGridState();
}

class _ShimmerGridState extends State<_ShimmerGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: 6,
      itemBuilder: (_, __) {
        return AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF3A2410)
                    .withValues(alpha: 0.4 + _c.value * 0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFC9A84C).withValues(alpha: 0.15),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);
  @override
  String toString() => message;
}
