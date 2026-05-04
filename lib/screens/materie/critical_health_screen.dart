import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Kritische Gesundheits-Recherche — Materie-Welt (Rot)
/// Tab 1: OpenFDA Nebenwirkungen
/// Tab 2: Zurückgezogene Studien (CrossRef Retraction)
/// Tab 3: Pharma → Arzt Geldflüsse (CMS Open Payments)
class CriticalHealthScreen extends StatefulWidget {
  final String roomId;

  const CriticalHealthScreen({super.key, this.roomId = 'gesundheit'});

  @override
  State<CriticalHealthScreen> createState() => _CriticalHealthScreenState();
}

class _CriticalHealthScreenState extends State<CriticalHealthScreen>
    with SingleTickerProviderStateMixin {
  // ─── Theme ───────────────────────────────────────────────────────────────
  static const Color _accent = Color(0xFFE53935);
  static const Color _bg = Color(0xFF0D0505);
  static const Color _surface = Color(0xFF1A0000);
  static const Color _surfaceLight = Color(0xFF2A0808);
  static const Color _textPrimary = Colors.white;
  static const Color _textMuted = Color(0xFF9E9E9E);

  late final TabController _tabCtrl;

  // ─── Tab 1: OpenFDA ──────────────────────────────────────────────────────
  final _fdaSearchCtrl = TextEditingController(text: 'Ozempic');
  String _fdaQuery = 'Ozempic';
  List<_FdaReaction> _fdaResults = [];
  bool _fdaLoading = false;
  String? _fdaError;
  int _fdaTotalReports = 0;

  // ─── Tab 2: Retracted Studies ────────────────────────────────────────────
  final _retractSearchCtrl = TextEditingController(text: 'Ozempic');
  String _retractQuery = 'Ozempic';
  List<_RetractedPaper> _retractResults = [];
  bool _retractLoading = false;
  String? _retractError;

  // ─── Tab 3: CMS Open Payments ────────────────────────────────────────────
  final _cmsSearchCtrl = TextEditingController(text: 'Smith');
  String _cmsQuery = 'Smith';
  List<_CmsPayment> _cmsResults = [];
  bool _cmsLoading = false;
  String? _cmsError;
  double _cmsTotalAmount = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _fetchFda();
    _fetchRetractions();
    _fetchCms();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _fdaSearchCtrl.dispose();
    _retractSearchCtrl.dispose();
    _cmsSearchCtrl.dispose();
    super.dispose();
  }

  // ─── API: OpenFDA ─────────────────────────────────────────────────────────
  Future<void> _fetchFda([String? query]) async {
    final q = query ?? _fdaQuery;
    setState(() {
      _fdaLoading = true;
      _fdaError = null;
      _fdaResults = [];
      _fdaTotalReports = 0;
    });
    try {
      final encoded = Uri.encodeComponent('"$q"');
      final url = Uri.parse(
        'https://api.fda.gov/drug/event.json'
        '?search=patient.drug.medicinalproduct:$encoded'
        '&count=patient.reaction.reactionmeddrapt.exact'
        '&limit=15',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final rawResults = (data['results'] as List?) ?? [];
        final total = ((data['meta'] as Map?)?['results'] as Map?)?['total'] as int? ?? 0;
        final reactions = rawResults.map((e) {
          final m = e as Map<String, dynamic>;
          return _FdaReaction(
            term: (m['term'] as String?) ?? 'Unbekannt',
            count: (m['count'] as num?)?.toInt() ?? 0,
          );
        }).toList();
        if (mounted) {
          setState(() {
            _fdaResults = reactions;
            _fdaTotalReports = total;
            _fdaLoading = false;
          });
        }
      } else if (res.statusCode == 404) {
        if (mounted) {
          setState(() {
            _fdaError = 'Keine Nebenwirkungsdaten für "$q" gefunden.';
            _fdaLoading = false;
          });
        }
      } else {
        throw Exception('HTTP ${res.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('FDA error: $e');
      if (mounted) {
        setState(() {
          _fdaError = 'Fehler beim Laden der FDA-Daten. Bitte Verbindung prüfen.';
          _fdaLoading = false;
        });
      }
    }
  }

  // ─── API: CrossRef Retractions ────────────────────────────────────────────
  Future<void> _fetchRetractions([String? query]) async {
    final q = query ?? _retractQuery;
    setState(() {
      _retractLoading = true;
      _retractError = null;
      _retractResults = [];
    });
    try {
      final url = Uri.parse(
        'https://api.crossref.org/works'
        '?query=${Uri.encodeComponent(q)}'
        '&filter=update-type:retraction'
        '&rows=15'
        '&mailto=app@weltenbibliothek.de',
      );
      final res = await http.get(
        url,
        headers: {'User-Agent': 'WeltenbibliothekApp/1.0 (app@weltenbibliothek.de)'},
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final items = ((data['message'] as Map?)?['items'] as List?) ?? [];
        final papers = items.map((e) {
          final m = e as Map<String, dynamic>;
          final titleList = m['title'] as List?;
          final title = (titleList?.isNotEmpty == true)
              ? titleList!.first as String
              : 'Kein Titel';
          final authorList = (m['author'] as List?) ?? [];
          final authors = authorList
              .take(3)
              .map((a) => (a as Map<String, dynamic>)['family'] as String? ?? '')
              .where((s) => s.isNotEmpty)
              .join(', ');
          final dateParts = (m['published-print'] as Map?)?['date-parts'] as List?;
          final year = (dateParts?.isNotEmpty == true && (dateParts!.first as List).isNotEmpty)
              ? (dateParts.first as List).first?.toString() ?? ''
              : '';
          final doi = (m['DOI'] as String?) ?? '';
          final publisher = (m['publisher'] as String?) ?? '';
          return _RetractedPaper(
            title: title,
            authors: authors.isEmpty ? 'Unbekannte Autoren' : authors,
            year: year,
            doi: doi,
            publisher: publisher,
          );
        }).toList();
        if (mounted) {
          setState(() {
            _retractResults = papers;
            _retractLoading = false;
          });
        }
      } else {
        throw Exception('HTTP ${res.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('CrossRef retraction error: $e');
      if (mounted) {
        setState(() {
          _retractError = 'Fehler beim Laden der Retraction-Daten. Bitte Verbindung prüfen.';
          _retractLoading = false;
        });
      }
    }
  }

  // ─── API: CMS Open Payments ───────────────────────────────────────────────
  Future<void> _fetchCms([String? query]) async {
    final q = query ?? _cmsQuery;
    setState(() {
      _cmsLoading = true;
      _cmsError = null;
      _cmsResults = [];
      _cmsTotalAmount = 0;
    });
    try {
      final url = Uri.parse(
        'https://openpaymentsdata.cms.gov/api/1/datastore/query'
        '/06e845f8-bde8-4c9f-bb40-3a3e3e3f0b6a'
        '?conditions[0][property]=Physician_Last_Name'
        '&conditions[0][value]=${Uri.encodeComponent(q.toUpperCase())}'
        '&limit=15',
      );
      final res = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final results = (data['results'] as List?) ?? [];
        double total = 0;
        final payments = results.map((e) {
          final m = e as Map<String, dynamic>;
          final amountRaw = m['Total_Amount_of_Payment_USDollars'];
          final amount = double.tryParse(amountRaw?.toString() ?? '0') ?? 0;
          total += amount;
          return _CmsPayment(
            firstName: (m['Physician_First_Name'] as String?) ?? '',
            lastName: (m['Physician_Last_Name'] as String?) ?? '',
            amount: amount,
            company: (m['Applicable_Manufacturer_or_Applicable_GPO_Making_Payment_Name']
                    as String?) ??
                '',
            paymentType:
                (m['Nature_of_Payment_or_Transfer_of_Value'] as String?) ?? '',
            date: (m['Date_of_Payment'] as String?) ?? '',
          );
        }).toList();
        if (mounted) {
          setState(() {
            _cmsResults = payments;
            _cmsTotalAmount = total;
            _cmsLoading = false;
          });
        }
      } else if (res.statusCode == 404) {
        if (mounted) {
          setState(() {
            _cmsError = 'Keine Zahlungsdaten für "$q" gefunden.';
            _cmsLoading = false;
          });
        }
      } else {
        throw Exception('HTTP ${res.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('CMS error: $e');
      if (mounted) {
        setState(() {
          _cmsError =
              'CMS Open Payments nicht erreichbar. Bitte später erneut versuchen.';
          _cmsLoading = false;
        });
      }
    }
  }

  // ─── URL launcher ─────────────────────────────────────────────────────────
  Future<void> _launchDoi(String doi) async {
    if (doi.isEmpty) return;
    final uri = Uri.parse('https://doi.org/$doi');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('launch DOI error: $e');
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _textPrimary,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _accent.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _accent.withAlpha(80)),
              ),
              child: const Icon(Icons.health_and_safety, color: _accent, size: 18),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Kritische Gesundheit',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: _accent,
          indicatorWeight: 2.5,
          labelColor: _accent,
          unselectedLabelColor: _textMuted,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          tabs: const [
            Tab(text: 'OpenFDA', icon: Icon(Icons.warning_amber, size: 16)),
            Tab(text: 'Retractions', icon: Icon(Icons.remove_circle_outline, size: 16)),
            Tab(text: 'Pharma-\$', icon: Icon(Icons.attach_money, size: 16)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _FdaTab(
            accent: _accent,
            bg: _bg,
            surface: _surface,
            surfaceLight: _surfaceLight,
            textPrimary: _textPrimary,
            textMuted: _textMuted,
            searchCtrl: _fdaSearchCtrl,
            results: _fdaResults,
            loading: _fdaLoading,
            error: _fdaError,
            totalReports: _fdaTotalReports,
            query: _fdaQuery,
            onSearch: (q) {
              setState(() => _fdaQuery = q);
              _fetchFda(q);
            },
          ),
          _RetractTab(
            accent: _accent,
            bg: _bg,
            surface: _surface,
            surfaceLight: _surfaceLight,
            textPrimary: _textPrimary,
            textMuted: _textMuted,
            searchCtrl: _retractSearchCtrl,
            results: _retractResults,
            loading: _retractLoading,
            error: _retractError,
            query: _retractQuery,
            onSearch: (q) {
              setState(() => _retractQuery = q);
              _fetchRetractions(q);
            },
            onLaunchDoi: _launchDoi,
          ),
          _CmsTab(
            accent: _accent,
            bg: _bg,
            surface: _surface,
            surfaceLight: _surfaceLight,
            textPrimary: _textPrimary,
            textMuted: _textMuted,
            searchCtrl: _cmsSearchCtrl,
            results: _cmsResults,
            loading: _cmsLoading,
            error: _cmsError,
            totalAmount: _cmsTotalAmount,
            query: _cmsQuery,
            onSearch: (q) {
              setState(() => _cmsQuery = q);
              _fetchCms(q);
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

class _FdaReaction {
  final String term;
  final int count;
  _FdaReaction({required this.term, required this.count});
}

class _RetractedPaper {
  final String title;
  final String authors;
  final String year;
  final String doi;
  final String publisher;
  _RetractedPaper({
    required this.title,
    required this.authors,
    required this.year,
    required this.doi,
    required this.publisher,
  });
}

class _CmsPayment {
  final String firstName;
  final String lastName;
  final double amount;
  final String company;
  final String paymentType;
  final String date;
  _CmsPayment({
    required this.firstName,
    required this.lastName,
    required this.amount,
    required this.company,
    required this.paymentType,
    required this.date,
  });

  String get fullName => '$firstName $lastName'.trim();
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 1: OpenFDA Nebenwirkungen
// ═══════════════════════════════════════════════════════════════════════════════

class _FdaTab extends StatelessWidget {
  final Color accent;
  final Color bg;
  final Color surface;
  final Color surfaceLight;
  final Color textPrimary;
  final Color textMuted;
  final TextEditingController searchCtrl;
  final List<_FdaReaction> results;
  final bool loading;
  final String? error;
  final int totalReports;
  final String query;
  final void Function(String) onSearch;

  const _FdaTab({
    required this.accent,
    required this.bg,
    required this.surface,
    required this.surfaceLight,
    required this.textPrimary,
    required this.textMuted,
    required this.searchCtrl,
    required this.results,
    required this.loading,
    required this.error,
    required this.totalReports,
    required this.query,
    required this.onSearch,
  });

  Color _severityColor(int index) {
    if (index < 3) return const Color(0xFFE53935); // top 3 = rot
    if (index < 6) return const Color(0xFFFF9800); // nächste 3 = orange
    return const Color(0xFFFFEB3B); // rest = gelb
  }

  String _severityLabel(int index) {
    if (index < 3) return 'KRITISCH';
    if (index < 6) return 'ERHÖHT';
    return 'NORMAL';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      child: Column(
        children: [
          // Search bar
          Container(
            color: surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    style: TextStyle(color: textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Medikament suchen...',
                      hintStyle: TextStyle(color: textMuted, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: textMuted, size: 20),
                      filled: true,
                      fillColor: surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: onSearch,
                    textInputAction: TextInputAction.search,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => onSearch(searchCtrl.text.trim()),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.search, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          // Stats banner
          if (!loading && results.isNotEmpty)
            Container(
              width: double.infinity,
              color: accent.withAlpha(25),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.bar_chart, color: accent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$totalReports Nebenwirkungsmeldungen für "$query" (FDA-Datenbank)',
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Info source
          Container(
            width: double.infinity,
            color: surfaceLight,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'Quelle: FDA Adverse Event Reporting System (FAERS)',
              style: TextStyle(color: textMuted, fontSize: 11),
            ),
          ),
          // Content
          Expanded(
            child: loading
                ? Center(
                    child: CircularProgressIndicator(
                        color: accent, strokeWidth: 2.5),
                  )
                : error != null
                    ? _ErrorCard(message: error!, accent: accent, surface: surface)
                    : results.isEmpty
                        ? _EmptyState(
                            message:
                                'Keine Nebenwirkungen gefunden.\nAnderes Medikament eingeben.',
                            accent: accent,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: results.length,
                            itemBuilder: (ctx, i) {
                              final r = results[i];
                              final maxCount =
                                  results.isNotEmpty ? results.first.count : 1;
                              final barFraction = maxCount > 0
                                  ? (r.count / maxCount).clamp(0.0, 1.0)
                                  : 0.0;
                              final sColor = _severityColor(i);
                              final sLabel = _severityLabel(i);
                              return _FdaReactionCard(
                                reaction: r,
                                index: i,
                                barFraction: barFraction,
                                severityColor: sColor,
                                severityLabel: sLabel,
                                surface: surface,
                                surfaceLight: surfaceLight,
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _FdaReactionCard extends StatelessWidget {
  final _FdaReaction reaction;
  final int index;
  final double barFraction;
  final Color severityColor;
  final String severityLabel;
  final Color surface;
  final Color surfaceLight;
  final Color textPrimary;
  final Color textMuted;

  const _FdaReactionCard({
    required this.reaction,
    required this.index,
    required this.barFraction,
    required this.severityColor,
    required this.severityLabel,
    required this.surface,
    required this.surfaceLight,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: severityColor.withAlpha(50),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: rank + name + severity chip
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: severityColor.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: severityColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _capitalize(reaction.term),
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Severity chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: severityColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(5),
                  border:
                      Border.all(color: severityColor.withAlpha(100), width: 1),
                ),
                child: Text(
                  severityLabel,
                  style: TextStyle(
                    color: severityColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Bar chart row
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      // Background
                      Container(
                        height: 8,
                        color: surfaceLight,
                      ),
                      // Fill
                      FractionallySizedBox(
                        widthFactor: barFraction,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: severityColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatCount(reaction.count),
                style: TextStyle(
                  color: severityColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                ' Meldungen',
                style: TextStyle(color: textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 2: Zurückgezogene Studien
// ═══════════════════════════════════════════════════════════════════════════════

class _RetractTab extends StatelessWidget {
  final Color accent;
  final Color bg;
  final Color surface;
  final Color surfaceLight;
  final Color textPrimary;
  final Color textMuted;
  final TextEditingController searchCtrl;
  final List<_RetractedPaper> results;
  final bool loading;
  final String? error;
  final String query;
  final void Function(String) onSearch;
  final void Function(String) onLaunchDoi;

  const _RetractTab({
    required this.accent,
    required this.bg,
    required this.surface,
    required this.surfaceLight,
    required this.textPrimary,
    required this.textMuted,
    required this.searchCtrl,
    required this.results,
    required this.loading,
    required this.error,
    required this.query,
    required this.onSearch,
    required this.onLaunchDoi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      child: Column(
        children: [
          // Search bar
          Container(
            color: surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    style: TextStyle(color: textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Medikament oder Thema...',
                      hintStyle: TextStyle(color: textMuted, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: textMuted, size: 20),
                      filled: true,
                      fillColor: surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: onSearch,
                    textInputAction: TextInputAction.search,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => onSearch(searchCtrl.text.trim()),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.search, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          // Info banner
          Container(
            width: double.infinity,
            color: accent.withAlpha(18),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: accent, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Zurückgezogene Studien via CrossRef. Tippe auf eine Karte für Details.',
                    style: TextStyle(color: accent.withAlpha(200), fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: surfaceLight,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'Quelle: CrossRef Retraction Database',
              style: TextStyle(color: textMuted, fontSize: 11),
            ),
          ),
          // Content
          Expanded(
            child: loading
                ? Center(
                    child: CircularProgressIndicator(
                        color: accent, strokeWidth: 2.5),
                  )
                : error != null
                    ? _ErrorCard(message: error!, accent: accent, surface: surface)
                    : results.isEmpty
                        ? _EmptyState(
                            message:
                                'Keine zurückgezogenen Studien gefunden.\nAnderen Begriff eingeben.',
                            accent: accent,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: results.length,
                            itemBuilder: (ctx, i) {
                              final p = results[i];
                              return _RetractedPaperCard(
                                paper: p,
                                accent: accent,
                                surface: surface,
                                surfaceLight: surfaceLight,
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                                onTap: () => onLaunchDoi(p.doi),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _RetractedPaperCard extends StatelessWidget {
  final _RetractedPaper paper;
  final Color accent;
  final Color surface;
  final Color surfaceLight;
  final Color textPrimary;
  final Color textMuted;
  final VoidCallback onTap;

  const _RetractedPaperCard({
    required this.paper,
    required this.accent,
    required this.surface,
    required this.surfaceLight,
    required this.textPrimary,
    required this.textMuted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accent.withAlpha(60),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with retracted badge
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              decoration: BoxDecoration(
                color: accent.withAlpha(20),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'ZURÜCKGEZOGEN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  if (paper.year.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      paper.year,
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (paper.doi.isNotEmpty)
                    Icon(Icons.open_in_new, color: textMuted, size: 14),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paper.title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person_outline, color: textMuted, size: 13),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          paper.authors,
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (paper.publisher.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.business_outlined,
                            color: textMuted, size: 13),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            paper.publisher,
                            style: TextStyle(color: textMuted, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (paper.doi.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: surfaceLight,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'DOI: ${paper.doi}',
                        style: TextStyle(
                          color: accent.withAlpha(200),
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 3: CMS Open Payments
// ═══════════════════════════════════════════════════════════════════════════════

class _CmsTab extends StatelessWidget {
  final Color accent;
  final Color bg;
  final Color surface;
  final Color surfaceLight;
  final Color textPrimary;
  final Color textMuted;
  final TextEditingController searchCtrl;
  final List<_CmsPayment> results;
  final bool loading;
  final String? error;
  final double totalAmount;
  final String query;
  final void Function(String) onSearch;

  const _CmsTab({
    required this.accent,
    required this.bg,
    required this.surface,
    required this.surfaceLight,
    required this.textPrimary,
    required this.textMuted,
    required this.searchCtrl,
    required this.results,
    required this.loading,
    required this.error,
    required this.totalAmount,
    required this.query,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      child: Column(
        children: [
          // Search bar
          Container(
            color: surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    style: TextStyle(color: textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Arzt-Nachname oder Firma...',
                      hintStyle: TextStyle(color: textMuted, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: textMuted, size: 20),
                      filled: true,
                      fillColor: surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: onSearch,
                    textInputAction: TextInputAction.search,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => onSearch(searchCtrl.text.trim()),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.search, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          // Stats banner
          if (!loading && results.isNotEmpty)
            Container(
              width: double.infinity,
              color: accent.withAlpha(25),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.monetization_on, color: accent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${results.length} Zahlungen gefunden · Gesamt: ${_formatUsd(totalAmount)}',
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            width: double.infinity,
            color: surfaceLight,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'Daten: CMS Open Payments (USA) 2023',
              style: TextStyle(color: textMuted, fontSize: 11),
            ),
          ),
          // Content
          Expanded(
            child: loading
                ? Center(
                    child: CircularProgressIndicator(
                        color: accent, strokeWidth: 2.5),
                  )
                : error != null
                    ? _ErrorCard(message: error!, accent: accent, surface: surface)
                    : results.isEmpty
                        ? _EmptyState(
                            message:
                                'Keine Zahlungen gefunden.\nAndere Suchanfrage versuchen.',
                            accent: accent,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: results.length,
                            itemBuilder: (ctx, i) {
                              final p = results[i];
                              return _CmsPaymentCard(
                                payment: p,
                                accent: accent,
                                surface: surface,
                                surfaceLight: surfaceLight,
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  String _formatUsd(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(2)}M';
    }
    if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '\$${amount.toStringAsFixed(2)}';
  }
}

class _CmsPaymentCard extends StatelessWidget {
  final _CmsPayment payment;
  final Color accent;
  final Color surface;
  final Color surfaceLight;
  final Color textPrimary;
  final Color textMuted;

  const _CmsPaymentCard({
    required this.payment,
    required this.accent,
    required this.surface,
    required this.surfaceLight,
    required this.textPrimary,
    required this.textMuted,
  });

  // Farb-Mapping für Zahlungstypen
  Color _typeColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('food') || t.contains('meal')) return const Color(0xFF4CAF50);
    if (t.contains('speaking')) return const Color(0xFF2196F3);
    if (t.contains('consulting')) return const Color(0xFFFF9800);
    if (t.contains('research')) return const Color(0xFF9C27B0);
    if (t.contains('education')) return const Color(0xFF00BCD4);
    return const Color(0xFF607D8B);
  }

  String _formatDate(String date) {
    if (date.isEmpty) return '';
    try {
      final parts = date.split('/');
      if (parts.length == 3) return '${parts[1]}.${parts[0]}.${parts[2]}';
      return date;
    } catch (_) {
      return date;
    }
  }

  String _formatAmount(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(payment.paymentType);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: typeColor.withAlpha(50),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: doctor name + amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor avatar icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withAlpha(25),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withAlpha(80)),
                ),
                child: Icon(Icons.person, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.fullName.isEmpty ? 'Unbekannt' : payment.fullName,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (payment.date.isNotEmpty)
                      Text(
                        _formatDate(payment.date),
                        style: TextStyle(color: textMuted, fontSize: 11),
                      ),
                  ],
                ),
              ),
              // Amount badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accent.withAlpha(100)),
                ),
                child: Text(
                  _formatAmount(payment.amount),
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Row 2: company
          if (payment.company.isNotEmpty)
            Row(
              children: [
                Icon(Icons.business, color: textMuted, size: 13),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    payment.company,
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          if (payment.paymentType.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: typeColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                        color: typeColor.withAlpha(100), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.label_outline, color: typeColor, size: 11),
                      const SizedBox(width: 4),
                      Text(
                        payment.paymentType,
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _ErrorCard extends StatelessWidget {
  final String message;
  final Color accent;
  final Color surface;

  const _ErrorCard({
    required this.message,
    required this.accent,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withAlpha(80)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, color: accent.withAlpha(180), size: 40),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final Color accent;

  const _EmptyState({required this.message, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, color: accent.withAlpha(120), size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
