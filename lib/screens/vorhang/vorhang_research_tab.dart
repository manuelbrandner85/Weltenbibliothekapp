import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/mentor_service.dart';
import '../shared/mentor_chat_screen.dart';
import 'vorhang_modules_screen.dart';

class VorhangResearchTab extends StatefulWidget {
  const VorhangResearchTab({super.key});

  @override
  State<VorhangResearchTab> createState() => _VorhangResearchTabState();
}

class _VorhangResearchTabState extends State<VorhangResearchTab> {
  static const _gold = Color(0xFFC9A84C);
  static const _bg = Color(0xFF000000);
  static const _surface = Color(0xFF0D0B00);

  List<Map<String, dynamic>> _books = [];
  bool _loadingBooks = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    try {
      final rows = await Supabase.instance.client
          .from('bibliothek_books')
          .select()
          .inFilter('category', ['philosophie', 'hermetik'])
          .order('title');
      if (!mounted) return;
      setState(() {
        _books = List<Map<String, dynamic>>.from(rows);
        _loadingBooks = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingBooks = false);
    }
  }

  Color _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF1A1500);
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFF1A1500);
    }
  }

  void _showBookSheet(Map<String, dynamic> book) {
    final insights = (book['key_insights'] as List?)?.cast<String>() ?? [];
    final sourceUrl = book['source_url']?.toString() ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                book['title']?.toString() ?? '',
                style: const TextStyle(
                    color: _gold, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                book['author']?.toString() ?? '',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
              ),
              const SizedBox(height: 16),
              if (book['description'] != null) ...[
                Text(
                  book['description'].toString(),
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 16),
              ],
              if (insights.isNotEmpty) ...[
                const Text(
                  'Kernaussagen',
                  style: TextStyle(
                      color: _gold, fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...insights.take(3).map((insight) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ',
                              style: TextStyle(color: _gold, fontSize: 14)),
                          Expanded(
                            child: Text(insight,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
              ],
              if (sourceUrl.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Quelle öffnen'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _gold,
                      side: const BorderSide(color: _gold),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => launchUrl(Uri.parse(sourceUrl),
                        mode: LaunchMode.externalApplication),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('📚 Geheime Bibliothek'),
            _buildBooksSection(),
            const SizedBox(height: 24),
            _buildSectionHeader('🧠 Stratege fragen'),
            _buildMentorCard(),
            const SizedBox(height: 24),
            _buildSectionHeader('📖 Alle 30 Module'),
            _buildModulesButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Text(
        title,
        style: const TextStyle(
            color: _gold, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }

  Widget _buildBooksSection() {
    if (_loadingBooks) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator(color: _gold)),
      );
    }
    if (_books.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Keine Bücher verfügbar',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          ),
        ),
      );
    }
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _books.length,
        itemBuilder: (_, i) => _buildBookCard(_books[i]),
      ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book) {
    final coverColor = _parseHex(book['cover_color']?.toString());
    final difficulty = book['difficulty']?.toString() ?? '';
    return GestureDetector(
      onTap: () => _showBookSheet(book),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: coverColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _gold.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: _gold.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.menu_book_rounded, color: _gold, size: 28),
              const Spacer(),
              Text(
                book['title']?.toString() ?? '',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                book['author']?.toString() ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
              ),
              if (difficulty.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    difficulty,
                    style: const TextStyle(color: _gold, fontSize: 10),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMentorCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MentorChatScreen(
              personality: MentorPersonality.stratege,
              world: 'vorhang',
            ),
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_surface, _gold.withValues(alpha: 0.15)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: const Border(left: BorderSide(color: _gold, width: 3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.psychology_rounded, color: _gold, size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Der Stratege',
                      style: TextStyle(
                          color: _gold, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'KI-Mentor für Machtanalyse & strategisches Denken',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: _gold, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModulesButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.school_outlined),
        label: const Text('Alle 30 Module öffnen'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _gold,
          side: const BorderSide(color: _gold),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(double.infinity, 0),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VorhangModulesScreen()),
        ),
      ),
    );
  }
}
