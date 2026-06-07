// 📖 Book Detail Screen — Geheime Bibliothek
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:url_launcher/url_launcher.dart';

class BookDetailScreen extends StatelessWidget {
  final Map<String, dynamic> book;
  const BookDetailScreen({super.key, required this.book});

  Color get _coverColor {
    final hex = book['cover_color'] as String?;
    if (hex != null && hex.startsWith('#') && hex.length == 7) {
      try {
        return Color(int.parse('FF${hex.substring(1)}', radix: 16));
      } catch (e) { if (kDebugMode) debugPrint('book_detail_screen: silent catch -> $e'); }
    }
    return const Color(0xFF5D4037);
  }

  @override
  Widget build(BuildContext context) {
    final title = (book['title'] as String?) ?? 'Ohne Titel';
    final author = (book['author'] as String?) ?? 'Unbekannt';
    final year = book['year']?.toString() ?? '';
    final summary = (book['summary'] as String?) ?? '';
    final insights = (book['key_insights'] as List?) ?? const [];
    final related = (book['related_modules'] as List?) ?? const [];
    final externalUrl = book['external_url'] as String?;
    final difficulty = book['difficulty']?.toString();
    final id = (book['id'] as String?) ?? title;

    return Scaffold(
      backgroundColor: const Color(0xFF1A0F00),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: _coverColor,
            iconTheme: const IconThemeData(color: Color(0xFFF5E6C8)),
            actions: [
              if (difficulty != null && difficulty.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color:
                                const Color(0xFFE0C872).withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        difficulty,
                        style: const TextStyle(
                          color: Color(0xFFE0C872),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'book_cover_$id',
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _coverColor,
                        _coverColor.withValues(alpha: 0.7),
                        const Color(0xFF1A0F00),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 18),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Color(0xFFF5E6C8),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            author,
                            style: const TextStyle(
                              color: Color(0xFFE0C872),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (year.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                year,
                                style: TextStyle(
                                  color: const Color(0xFFE0C872)
                                      .withValues(alpha: 0.7),
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (summary.isNotEmpty) ...[
                  _section('Zusammenfassung'),
                  const SizedBox(height: 8),
                  Text(
                    summary,
                    style: const TextStyle(
                      color: Color(0xFFEBE3D2),
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (insights.isNotEmpty) ...[
                  _section('Kern-Einsichten'),
                  const SizedBox(height: 10),
                  ...insights.whereType<String>().map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 6, right: 8),
                                child: Icon(Icons.auto_awesome,
                                    size: 12, color: Color(0xFFC9A84C)),
                              ),
                              Expanded(
                                child: Text(
                                  s,
                                  style: const TextStyle(
                                    color: Color(0xFFEBE3D2),
                                    fontSize: 13.5,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: 14),
                ],
                if (related.isNotEmpty) ...[
                  _section('Verknüpfte Module'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: related.whereType<String>().map((m) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFC9A84C).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFC9A84C)
                                  .withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          m,
                          style: const TextStyle(
                            color: Color(0xFFE0C872),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
                if (externalUrl != null && externalUrl.isNotEmpty) ...[
                  _section('Originalquelle'),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final uri = Uri.tryParse(externalUrl);
                        if (uri == null) return;
                        try {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        } catch (e) { if (kDebugMode) debugPrint('book_detail_screen: silent catch -> $e'); }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC9A84C),
                        foregroundColor: const Color(0xFF1A0F00),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text(
                        'Im Browser öffnen',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    externalUrl,
                    style: TextStyle(
                      color: const Color(0xFFE0C872).withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          color: const Color(0xFFC9A84C),
        ),
        const SizedBox(width: 10),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFFE0C872),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.2,
          ),
        ),
      ],
    );
  }
}
