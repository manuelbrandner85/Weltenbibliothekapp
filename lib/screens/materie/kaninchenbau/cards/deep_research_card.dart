/// 🔬 TIEFEN-RECHERCHE-CARD — Multi-Source-Aggregat in einer Karte.
///
/// Aggregiert in einem einzigen Worker-Call:
///   • Deutsche Wikipedia (Volltext-Zusammenfassung + Bild)
///   • arXiv (Pre-Prints)
///   • GDELT 2.0 (deutsche Nachrichten letzte 7 Tage)
///   • Europeana (EU-Kulturarchiv, 50M+ Objekte)
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/api_config.dart';
import '../widgets/kb_design.dart';

class DeepResearchCard extends StatefulWidget {
  final String topic;
  const DeepResearchCard({super.key, required this.topic});

  @override
  State<DeepResearchCard> createState() => _DeepResearchCardState();
}

class _DeepResearchCardState extends State<DeepResearchCard> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  int _activeTab = 0; // 0 wiki, 1 news, 2 arxiv, 3 europeana

  static const _accent = Color(0xFF7E57C2);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(DeepResearchCard old) {
    super.didUpdateWidget(old);
    if (old.topic != widget.topic) {
      setState(() {
        _data = null;
        _loading = true;
        _activeTab = 0;
      });
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final url = Uri.parse(
          '${ApiConfig.workerUrl}/api/kaninchenbau/deep?topic=${Uri.encodeComponent(widget.topic)}');
      final resp = await http.get(url).timeout(const Duration(seconds: 20));
      if (!mounted) return;
      if (resp.statusCode == 200) {
        setState(() {
          _data = jsonDecode(resp.body) as Map<String, dynamic>;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(String url) async {
    HapticFeedback.lightImpact();
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: _accent, opacity: 0.12),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.travel_explore_rounded,
                  color: _accent, size: 18),
              const SizedBox(width: 8),
              const Text(
                'TIEFEN-RECHERCHE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_loading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      color: _accent, strokeWidth: 1.5),
                )
              else if (_data != null)
                Text(
                  _totalCount(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Wikipedia DE · arXiv · GDELT-News · Europeana',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),

          if (_loading)
            const _SkeletonBlock()
          else if (_data == null)
            _buildEmpty()
          else ...[
            _buildTabBar(),
            const SizedBox(height: 14),
            _buildContent(),
          ],
        ],
      ),
    );
  }

  String _totalCount() {
    if (_data == null) return '';
    final n = (_data!['arxiv'] as List? ?? []).length +
        (_data!['gdelt_news_de'] as List? ?? []).length +
        (_data!['europeana'] as List? ?? []).length +
        (_data!['wikipedia_de'] != null ? 1 : 0);
    return '$n Treffer';
  }

  Widget _buildEmpty() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'Keine deutschen Quellen verfügbar — ggf. Worker-Endpoint nicht deployed.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        ),
      );

  Widget _buildTabBar() {
    final tabs = [
      ('Wikipedia', _data!['wikipedia_de'] != null ? 1 : 0),
      ('GDELT-News', (_data!['gdelt_news_de'] as List?)?.length ?? 0),
      ('arXiv', (_data!['arxiv'] as List?)?.length ?? 0),
      ('Europeana', (_data!['europeana'] as List?)?.length ?? 0),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = _activeTab == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _activeTab = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: active
                      ? _accent.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: active
                          ? _accent.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tabs[i].$1,
                      style: TextStyle(
                        color: active ? Colors.white : Colors.white60,
                        fontSize: 11,
                        fontWeight:
                            active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: active
                            ? _accent.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${tabs[i].$2}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContent() {
    switch (_activeTab) {
      case 0:
        return _buildWikipedia();
      case 1:
        return _buildGdelt();
      case 2:
        return _buildArxiv();
      case 3:
        return _buildEuropeana();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWikipedia() {
    final w = _data!['wikipedia_de'] as Map<String, dynamic>?;
    if (w == null) {
      return _emptyBox('Kein Wikipedia-Eintrag (DE) gefunden.');
    }
    return InkWell(
      onTap: w['url'] != null ? () => _open(w['url'] as String) : null,
      borderRadius: BorderRadius.circular(KbDesign.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(KbDesign.radiusSm),
          border: Border.all(color: _accent.withValues(alpha: 0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (w['thumbnail'] != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    w['thumbnail'] as String,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (w['title'] ?? widget.topic).toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (w['extract'] ?? '').toString(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded,
                color: _accent, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGdelt() {
    final items = (_data!['gdelt_news_de'] as List?) ?? [];
    if (items.isEmpty) {
      return _emptyBox('Keine deutschen GDELT-News gefunden.');
    }
    return Column(
      children: items.map<Widget>((raw) {
        final m = raw as Map<String, dynamic>;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: m['url'] != null ? () => _open(m['url'] as String) : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      (m['domain'] ?? '?').toString(),
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (m['title'] ?? '').toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildArxiv() {
    final items = (_data!['arxiv'] as List?) ?? [];
    if (items.isEmpty) return _emptyBox('Keine arXiv-Papers gefunden.');
    return Column(
      children: items.map<Widget>((raw) {
        final m = raw as Map<String, dynamic>;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: m['url'] != null ? () => _open(m['url'] as String) : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (m['title'] ?? '').toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (m['summary'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      m['summary'] as String,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 10,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEuropeana() {
    final items = (_data!['europeana'] as List?) ?? [];
    if (items.isEmpty) {
      return _emptyBox('Keine Europeana-Kulturobjekte gefunden.');
    }
    return Column(
      children: items.map<Widget>((raw) {
        final m = raw as Map<String, dynamic>;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: m['url'] != null ? () => _open(m['url'] as String) : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (m['title'] ?? '').toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (m['provider'] != null || m['year'] != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            [m['provider'], m['year']]
                                .where((e) => e != null)
                                .join(' · '),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _emptyBox(String text) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        ),
      );
}

class _SkeletonBlock extends StatefulWidget {
  const _SkeletonBlock();

  @override
  State<_SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<_SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Column(
        children: List.generate(
          3,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                  alpha: 0.04 + 0.04 * _ctrl.value),
              borderRadius: BorderRadius.circular(KbDesign.radiusSm),
            ),
          ),
        ),
      ),
    );
  }
}
