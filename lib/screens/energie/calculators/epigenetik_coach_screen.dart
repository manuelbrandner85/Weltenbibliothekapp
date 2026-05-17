// 🧬 EPIGENETIK-COACH
//
// Ersetzt das frühere "DNA-Aktivierung 12-Strang"-Tool (Pseudowissenschaft)
// durch 12 evidenzbasierte Lebensstil-Praktiken, die die Genexpression
// nachweislich modulieren (Studien: PMID 28215555, 25837538, 31002795,
// 29796582 etc.). Jede Praktik ist mit einem Tages-Tracker, Erklärtext
// und Live-Wikipedia-Erweiterung verlinkt.
//
// Wikipedia-API: REST v1 summary (kostenlos, kein Key) via FreeResearchToolsService.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/free_research_tools_service.dart';

class EpigenetikCoachScreen extends StatefulWidget {
  const EpigenetikCoachScreen({super.key});

  @override
  State<EpigenetikCoachScreen> createState() => _EpigenetikCoachScreenState();
}

class _EpigenetikCoachScreenState extends State<EpigenetikCoachScreen> {
  static const _bg = Color(0xFF06040F);
  static const _surface = Color(0xFF100B1E);
  static const _accent = Color(0xFF00695C);
  static const _accentLight = Color(0xFF4DB6AC);

  // Set von Praktik-IDs, die heute schon "abgehakt" wurden.
  // Persistiert lokal pro Tag via StorageService.kvSet.
  Set<String> _doneToday = {};
  bool _loading = true;

  static const _kvKey = 'epigenetik_done';

  static final List<_Practice> _practices = [
    _Practice(
      id: 'fasting',
      emoji: '⏱️',
      title: 'Intervallfasten 16:8',
      shortDesc: 'Aktiviert Autophagie & SIRT1.',
      evidence:
          'Erhöht SIRT1- und FOXO3-Expression, fördert Autophagie (Mizushima 2008, Madeo 2019). '
          'Reduziert mTOR-Aktivität → Langlebigkeits-Signalweg.',
      target: '16h Fasten / 8h Essen',
      wikiQuery: 'Intermittierendes_Fasten',
    ),
    _Practice(
      id: 'cold',
      emoji: '🥶',
      title: 'Kälte-Exposition',
      shortDesc: 'Induziert braunes Fettgewebe (UCP1↑).',
      evidence:
          'Kalte Duschen / Eisbäder erhöhen UCP1-Expression in braunem Fettgewebe '
          '(van Marken Lichtenbelt 2009), Noradrenalin +200-300%, erhöht Cold-Shock-Proteine.',
      target: '2-3 Min < 15°C',
      wikiQuery: 'Wim_Hof',
    ),
    _Practice(
      id: 'sauna',
      emoji: '🔥',
      title: 'Sauna / Hitze',
      shortDesc: 'Heat-Shock-Proteine HSP70/72.',
      evidence:
          'Finnische Kohortenstudie (Laukkanen 2015, JAMA): 4-7x Sauna/Woche '
          '−40% Gesamtmortalität. HSP-Induktion repariert misgefaltete Proteine.',
      target: '15-20 Min ≥ 80°C',
      wikiQuery: 'Sauna',
    ),
    _Practice(
      id: 'hiit',
      emoji: '🏃',
      title: 'HIIT-Training',
      shortDesc: 'Mitochondrien-Biogenese (PGC-1α).',
      evidence:
          'Hochintensives Intervalltraining steigert PGC-1α 3-5x (Little 2011). '
          'Methylierung an Promotorregionen verändert sich nach EINER Session.',
      target: '4×4 Min oder Tabata',
      wikiQuery: 'Hochintensives_Intervalltraining',
    ),
    _Practice(
      id: 'strength',
      emoji: '🏋️',
      title: 'Krafttraining',
      shortDesc: 'Myokine, IGF-1, Muskel-Methylierung.',
      evidence:
          'Resistance-Training senkt biologisches Alter (Horvath-Clock) signifikant '
          '(Sailani 2019). Erhöht Myokin-Release: BDNF, Irisin, IL-6.',
      target: '3-4× pro Woche',
      wikiQuery: 'Krafttraining',
    ),
    _Practice(
      id: 'sleep',
      emoji: '😴',
      title: 'Tiefschlaf 7-9h',
      shortDesc: 'Glymphatisches System, GH-Pulse.',
      evidence:
          'Schlafrestriktion verändert >700 Gen-Expressionsmuster binnen 1 Woche '
          '(Möller-Levet 2013, PNAS). Glymph-Clearance v.a. in N3-Phasen.',
      target: '7-9h, 22-06 Uhr',
      wikiQuery: 'Schlaf',
    ),
    _Practice(
      id: 'meditation',
      emoji: '🧘',
      title: 'Meditation',
      shortDesc: 'NF-κB ↓, Telomerase ↑.',
      evidence:
          'MBSR senkt NF-κB-Entzündungsgene (Black 2013), Davidson 2008: '
          'Telomerase-Aktivität +30% nach 3 Monaten Retreat.',
      target: '15-30 Min täglich',
      wikiQuery: 'Achtsamkeit',
    ),
    _Practice(
      id: 'polyphenols',
      emoji: '🫐',
      title: 'Polyphenol-Reichtum',
      shortDesc: 'Sirtuin-Aktivatoren (Resveratrol, EGCG).',
      evidence:
          'EGCG (Grüntee), Resveratrol, Curcumin modulieren DNMT- und HDAC-Aktivität '
          '(Fang 2003, Fernandes 2017). HMR-Diät senkt Horvath-Alter.',
      target: 'Beeren, Grüntee, Olivenöl, Kakao',
      wikiQuery: 'Polyphenole',
    ),
    _Practice(
      id: 'omega3',
      emoji: '🐟',
      title: 'Omega-3 (EPA/DHA)',
      shortDesc: 'Methylierung anti-inflammatorischer Loci.',
      evidence:
          'Omega-3-Supplementation (2g/Tag, 6 Mon) verändert >50 CpG-Methylierungs-Sites '
          'in pro-inflammatorischen Genen (Aslibekyan 2014).',
      target: '2-3× Fisch/Woche oder 1g EPA/DHA',
      wikiQuery: 'Omega-3-Fettsäuren',
    ),
    _Practice(
      id: 'sun',
      emoji: '☀️',
      title: 'Sonnenlicht 20 Min',
      shortDesc: 'Vitamin-D-Rezeptor (VDR) reguliert >2000 Gene.',
      evidence:
          'VDR-Aktivierung beeinflusst Immun-, Krebs-, Knochengene. '
          '20 Min Morgensonne synchronisiert auch zirkadiane SCN-Gene (Per1/2/3, Bmal1).',
      target: '15-30 Min direktes Sonnenlicht',
      wikiQuery: 'Vitamin_D',
    ),
    _Practice(
      id: 'social',
      emoji: '🤝',
      title: 'Soziale Verbundenheit',
      shortDesc: 'Senkt CTRA-Genexpression.',
      evidence:
          'Einsamkeit aktiviert CTRA-Genmuster (Conserved Transcriptional Response to Adversity) '
          'mit erhöhter Entzündung & gesenkter antiviraler Antwort (Cole 2013).',
      target: 'Tägliches tiefes Gespräch',
      wikiQuery: 'Soziale_Bindung',
    ),
    _Practice(
      id: 'breath',
      emoji: '🌬️',
      title: 'Atemarbeit',
      shortDesc: 'Vagus-Tonus & CO2-Toleranz.',
      evidence:
          'Pranayama / Box-Breathing aktiviert vagale Bremse → senkt HPA-Achse. '
          'Stein 2016: 4 Wochen Yoga-Pranayama verändert Methylierung an HPA-Genen (NR3C1, FKBP5).',
      target: '5-10 Min Box-Breathing (4-4-4-4)',
      wikiQuery: 'Pranayama',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _todayKey() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('${_kvKey}_${_todayKey()}') ?? const [];
    _doneToday = list.toSet();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggle(String id) async {
    setState(() {
      if (_doneToday.contains(id)) {
        _doneToday.remove(id);
      } else {
        _doneToday.add(id);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      '${_kvKey}_${_todayKey()}',
      _doneToday.toList(),
    );
  }

  void _openDetails(_Practice p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PracticeDetailSheet(practice: p, accent: _accent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _practices.isEmpty ? 0.0 : _doneToday.length / _practices.length;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _accent,
        title: const Row(
          children: [
            Text('🧬', style: TextStyle(fontSize: 22)),
            SizedBox(width: 10),
            Text('Epigenetik-Coach',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                _buildHeader(progress),
                const SizedBox(height: 20),
                for (final p in _practices) _buildPracticeCard(p),
              ],
            ),
    );
  }

  Widget _buildHeader(double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent.withValues(alpha: 0.4), _surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '12 evidenzbasierte Praktiken',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Lebensstil-Faktoren, die Genexpression nachweislich modulieren '
            '(Methylierung, Histon-Acetylierung, miRNA). Tippe auf eine Karte '
            'für die zugrundeliegende Studienlage.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(_accentLight),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_doneToday.length} / ${_practices.length} heute',
            style: const TextStyle(color: _accentLight, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeCard(_Practice p) {
    final done = _doneToday.contains(p.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: done ? _accent.withValues(alpha: 0.2) : _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done ? _accentLight : Colors.white.withValues(alpha: 0.1),
          width: done ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDetails(p),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Text(p.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 2),
                      Text(p.shortDesc,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          )),
                      const SizedBox(height: 4),
                      Text(p.target,
                          style: const TextStyle(
                            color: _accentLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggle(p.id),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? _accentLight : Colors.transparent,
                      border: Border.all(color: _accentLight, width: 2),
                    ),
                    child: done
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Practice {
  final String id;
  final String emoji;
  final String title;
  final String shortDesc;
  final String evidence;
  final String target;
  final String wikiQuery;
  const _Practice({
    required this.id,
    required this.emoji,
    required this.title,
    required this.shortDesc,
    required this.evidence,
    required this.target,
    required this.wikiQuery,
  });
}

class _PracticeDetailSheet extends StatefulWidget {
  final _Practice practice;
  final Color accent;
  const _PracticeDetailSheet({required this.practice, required this.accent});

  @override
  State<_PracticeDetailSheet> createState() => _PracticeDetailSheetState();
}

class _PracticeDetailSheetState extends State<_PracticeDetailSheet> {
  WikipediaSummary? _wiki;
  bool _wikiLoading = true;
  String? _wikiError;

  @override
  void initState() {
    super.initState();
    _loadWiki();
  }

  Future<void> _loadWiki() async {
    try {
      final w = await FreeResearchToolsService()
          .getWikipediaSummary(widget.practice.wikiQuery);
      if (!mounted) return;
      setState(() {
        _wiki = w;
        _wikiLoading = false;
        if (w == null) _wikiError = 'Kein Wikipedia-Artikel gefunden.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _wikiLoading = false;
        _wikiError = 'Wikipedia nicht erreichbar.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.practice;
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
            Row(
              children: [
                Text(p.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(p.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _sectionTitle('🎯 Tagesziel'),
            const SizedBox(height: 4),
            Text(p.target,
                style: TextStyle(
                    color: widget.accent.withValues(alpha: 0.95),
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            _sectionTitle('🧬 Evidenz'),
            const SizedBox(height: 6),
            Text(p.evidence,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.55,
                )),
            const SizedBox(height: 24),
            _sectionTitle('📖 Wikipedia'),
            const SizedBox(height: 8),
            if (_wikiLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_wikiError != null)
              Text(_wikiError!, style: const TextStyle(color: Colors.white60))
            else if (_wiki != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                      'https://de.wikipedia.org/wiki/${Uri.encodeComponent(p.wikiQuery)}',
                    );
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
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

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 2));
}
