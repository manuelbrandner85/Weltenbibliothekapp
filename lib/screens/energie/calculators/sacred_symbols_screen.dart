// 🔱 HEILIGE SYMBOLE — Multikulturelle Sakralsymbolik
//
// Ersetzt das frühere "Lichtsprache 30+ Lichtcodes"-Tool (esoterische
// Static-Liste ohne Substanz) durch eine kuratierte Sammlung
// dokumentierter Sakralsymbole aus 8 Traditionen mit echter
// etymologischer / historischer Bedeutung via Wikipedia-API.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/free_research_tools_service.dart';

class SacredSymbolsScreen extends StatefulWidget {
  const SacredSymbolsScreen({super.key});

  @override
  State<SacredSymbolsScreen> createState() => _SacredSymbolsScreenState();
}

class _SacredSymbolsScreenState extends State<SacredSymbolsScreen> {
  static const _bg = Color(0xFF06040F);
  static const _surface = Color(0xFF1A1530);
  static const _accent = Color(0xFFFDD835);

  String _filterTradition = 'Alle';
  String _searchQuery = '';
  Set<String> _bookmarks = {};

  static const _bookmarkKey = 'sacred_symbols_bookmarks';

  static const List<String> _traditions = [
    'Alle',
    'Favoriten',
    'Ägyptisch',
    'Hindu',
    'Buddhistisch',
    'Christlich',
    'Hebräisch',
    'Nordisch',
    'Keltisch',
    'Maya/Azteken',
  ];

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _bookmarks =
          (prefs.getStringList(_bookmarkKey) ?? const []).toSet();
    });
  }

  Future<void> _toggleBookmark(String name) async {
    setState(() {
      if (_bookmarks.contains(name)) {
        _bookmarks.remove(name);
      } else {
        _bookmarks.add(name);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_bookmarkKey, _bookmarks.toList());
  }

  static final List<_Symbol> _symbols = [
    // Ägyptisch
    _Symbol('Ankh', '☥', 'Ägyptisch', 'Schlüssel des Lebens, Unsterblichkeit',
        'Ankh'),
    _Symbol('Auge des Horus', '𓂀', 'Ägyptisch', 'Schutz, königliche Macht, Heilung',
        'Horusauge'),
    _Symbol('Skarabäus', '🪲', 'Ägyptisch',
        'Wiedergeburt, Sonnengott Chepre, Schöpfung', 'Skarabäus_(Ägypten)'),
    _Symbol('Djed-Pfeiler', '𓊽', 'Ägyptisch',
        'Stabilität, Rückgrat des Osiris, ewige Beständigkeit', 'Djed-Pfeiler'),

    // Hindu
    _Symbol('Om', 'ॐ', 'Hindu', 'Urklang des Universums, Brahman', 'Om_(Hinduismus)'),
    _Symbol('Sri Yantra', '🔯', 'Hindu',
        'Yantra der Tripura Sundari, Vereinigung Shiva/Shakti', 'Shri_Yantra'),
    _Symbol('Lotus', '🪷', 'Hindu',
        'Reinheit, spirituelles Erwachen, Chakren-Symbol', 'Lotosblume'),
    _Symbol('Trishula', '🔱', 'Hindu',
        'Shivas Dreizack, Vergangenheit/Gegenwart/Zukunft', 'Trishula'),

    // Buddhistisch
    _Symbol('Dharma-Rad', '☸️', 'Buddhistisch',
        'Dharmachakra, edle achtfache Pfad', 'Dharmachakra'),
    _Symbol('Endloser Knoten', '∞', 'Buddhistisch',
        'Verflechtung von Weisheit und Mitgefühl, Karma', 'Endloser_Knoten'),
    _Symbol('Bodhi-Blatt', '🍃', 'Buddhistisch',
        'Erleuchtung Buddhas unter dem Bodhi-Baum', 'Bodhi-Baum'),

    // Christlich
    _Symbol('Kreuz', '✝️', 'Christlich',
        'Opfertod und Auferstehung Jesu', 'Kreuz_(Christentum)'),
    _Symbol('Ichthys', '🐟', 'Christlich',
        'Frühchristliches Erkennungszeichen, Akrostichon', 'Ichthys'),
    _Symbol('Chi-Rho', '☧', 'Christlich',
        'Konstantinisches Christusmonogramm', 'Christusmonogramm'),
    _Symbol('Alpha & Omega', 'ΑΩ', 'Christlich',
        'Anfang und Ende, göttliche Allumfassendheit', 'Alpha_und_Omega'),

    // Hebräisch
    _Symbol('Davidstern', '✡️', 'Hebräisch',
        'Magen David, Schild Davids, Vereinigung der Gegensätze', 'Davidstern'),
    _Symbol('Menora', '🕎', 'Hebräisch',
        'Siebenarmiger Leuchter, Tempel, göttliches Licht', 'Menora'),
    _Symbol('Baum des Lebens', '🌳', 'Hebräisch',
        'Etz Chaim, Kabbala-Sephiroth-Schema', 'Lebensbaum_(Kabbala)'),
    _Symbol('Hamsa', '🪬', 'Hebräisch',
        'Hand der Miriam, Schutz vor bösem Blick', 'Hamsa'),

    // Nordisch
    _Symbol('Mjölnir', '🔨', 'Nordisch',
        'Thors Hammer, Schutz, Heiligung', 'Mjölnir'),
    _Symbol('Yggdrasil', '🌲', 'Nordisch',
        'Weltenbaum, neun Welten der Edda', 'Yggdrasil'),
    _Symbol('Valknut', '⛤', 'Nordisch',
        'Knoten der Erschlagenen, Odin-Symbol', 'Valknut'),
    _Symbol('Vegvísir', '🧭', 'Nordisch',
        'Isländischer Wegweiser, Orientierung in Stürmen', 'Vegvísir'),

    // Keltisch
    _Symbol('Triskele', '☘️', 'Keltisch',
        'Dreierspirale, Land/Meer/Himmel oder Vergangenheit/Gegenwart/Zukunft',
        'Triskele'),
    _Symbol('Keltisches Kreuz', '🕀', 'Keltisch',
        'Verbindung von Sonnenscheibe und Kreuz', 'Keltisches_Kreuz'),
    _Symbol('Awen', '|/|', 'Keltisch',
        'Drei Strahlen göttlicher Inspiration, Druiden-Symbol', 'Awen'),

    // Maya/Azteken
    _Symbol('Hunab Ku', '◯', 'Maya/Azteken',
        'Einziger Gott, Zentrum der Galaxis (Wiederentdeckung 20. Jh.)',
        'Hunab_Ku'),
    _Symbol('Quetzalcóatl', '🪶', 'Maya/Azteken',
        'Gefiederte Schlange, Wind/Weisheit', 'Quetzalcóatl'),
    _Symbol('Tonatiuh-Scheibe', '🌞', 'Maya/Azteken',
        'Aztekischer Sonnenkalender / Stein der Sonne', 'Stein_der_Sonne'),
  ];

  List<_Symbol> get _filtered {
    Iterable<_Symbol> list = _symbols;
    if (_filterTradition == 'Favoriten') {
      list = list.where((s) => _bookmarks.contains(s.name));
    } else if (_filterTradition != 'Alle') {
      list = list.where((s) => s.tradition == _filterTradition);
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((s) =>
          s.name.toLowerCase().contains(q) ||
          s.shortDesc.toLowerCase().contains(q) ||
          s.tradition.toLowerCase().contains(q));
    }
    return list.toList();
  }

  void _openDetails(_Symbol s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SymbolDetailSheet(symbol: s, accent: _accent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _accent.withValues(alpha: 0.9),
        foregroundColor: Colors.black,
        title: const Row(
          children: [
            Text('🔱', style: TextStyle(fontSize: 22)),
            SizedBox(width: 10),
            Text('Heilige Symbole',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Symbol/Tradition suchen…',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                prefixIcon: Icon(Icons.search, color: _accent.withValues(alpha: 0.8), size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: _surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _accent.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _accent.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final t in _traditions) ...[
                  _buildFilterChip(t),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.85,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _filtered.length,
              itemBuilder: (_, i) => _buildSymbolCard(_filtered[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String t) {
    final selected = t == _filterTradition;
    return GestureDetector(
      onTap: () => setState(() => _filterTradition = t),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _accent : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _accent : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          t,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSymbolCard(_Symbol s) {
    final bookmarked = _bookmarks.contains(s.name);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetails(s),
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accent.withValues(alpha: 0.25)),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(s.glyph, style: const TextStyle(fontSize: 36)),
                  const SizedBox(height: 6),
                  Text(
                    s.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.tradition,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _accent.withValues(alpha: 0.8),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: () => _toggleBookmark(s.name),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                  child: Icon(
                    bookmarked ? Icons.favorite : Icons.favorite_border,
                    size: 14,
                    color: bookmarked ? _accent : Colors.white60,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Symbol {
  final String name;
  final String glyph;
  final String tradition;
  final String shortDesc;
  final String wikiQuery;
  const _Symbol(this.name, this.glyph, this.tradition, this.shortDesc, this.wikiQuery);
}

class _SymbolDetailSheet extends StatefulWidget {
  final _Symbol symbol;
  final Color accent;
  const _SymbolDetailSheet({required this.symbol, required this.accent});

  @override
  State<_SymbolDetailSheet> createState() => _SymbolDetailSheetState();
}

class _SymbolDetailSheetState extends State<_SymbolDetailSheet> {
  WikipediaSummary? _wiki;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final w = await FreeResearchToolsService()
          .getWikipediaSummary(widget.symbol.wikiQuery);
      if (!mounted) return;
      setState(() {
        _wiki = w;
        _loading = false;
        if (w == null) _error = 'Kein Wikipedia-Artikel gefunden.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Wikipedia nicht erreichbar.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.symbol;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => SingleChildScrollView(
        controller: scrollCtrl,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(s.glyph, style: const TextStyle(fontSize: 72)),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(s.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  )),
            ),
            const SizedBox(height: 6),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(s.tradition,
                    style: TextStyle(
                        color: widget.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 20),
            Text(s.shortDesc,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.5,
                    fontStyle: FontStyle.italic)),
            const SizedBox(height: 20),
            const Text('📖 Wikipedia',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2)),
            const SizedBox(height: 8),
            if (_loading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(strokeWidth: 2),
              ))
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.white60))
            else if (_wiki != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Text(
                  _wiki!.extract,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(
                      'https://de.wikipedia.org/wiki/${Uri.encodeComponent(s.wikiQuery)}',
                    );
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: Icon(Icons.open_in_new, color: widget.accent),
                  label: Text('Vollständiger Artikel',
                      style: TextStyle(color: widget.accent)),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
