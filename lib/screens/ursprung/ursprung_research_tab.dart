// Ursprung-Research-Tab (R8): dynamische Topics aus Supabase mit Fallback.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/mentor_service.dart';
import '../../services/ursprung_topics_service.dart';
import '../shared/mentor_chat_screen.dart';
import 'ursprung_modules_screen.dart';

class UrsprungResearchTab extends StatefulWidget {
  const UrsprungResearchTab({super.key});

  @override
  State<UrsprungResearchTab> createState() => _UrsprungResearchTabState();
}

class _UrsprungResearchTabState extends State<UrsprungResearchTab> {
  static const _cyan = Color(0xFF00D4AA);
  static const _bg = Color(0xFF050510);
  static const _surface = Color(0xFF080818);

  final _searchCtrl = TextEditingController();
  List<UrsprungTopic> _topics = [];
  bool _loading = true;
  bool _usedFallback = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final q = _searchCtrl.text.trim();
    final fetched = await UrsprungTopicsService.instance
        .fetch(searchQuery: q.isEmpty ? null : q);
    if (!mounted) return;
    if (fetched.isEmpty && q.isEmpty) {
      // Fallback auf hardcoded Themen.
      setState(() {
        _topics = _fallbackTopics;
        _usedFallback = true;
        _loading = false;
      });
    } else {
      setState(() {
        _topics = fetched;
        _usedFallback = false;
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async => _load();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: RefreshIndicator(
        color: _cyan,
        backgroundColor: _surface,
        onRefresh: _refresh,
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 0, bottom: 80),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _topics.length + 3,
          itemBuilder: (context, i) {
            if (i == 0) return _buildHeader();
            if (i == 1) return _buildSearchBar();
            if (i == _topics.length + 2) return _buildFooter(context);
            if (_loading && _topics.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: _cyan)),
              );
            }
            if (_topics.isEmpty) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                child: Text(
                  'Keine Themen gefunden.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                ),
              );
            }
            return _TopicCard(
              topic: _topics[i - 2],
              onTap: () => _showDetail(_topics[i - 2]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BEWUSSTSEINS-ATLAS',
            style: TextStyle(
              color: _cyan,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_topics.length} Themengebiete${_usedFallback ? " - Offline" : ""}',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _load(),
        decoration: InputDecoration(
          hintText: 'Themen durchsuchen ...',
          hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: _cyan, size: 20),
          suffixIcon: _searchCtrl.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close,
                      color: Colors.white.withValues(alpha: 0.6), size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    _load();
                  },
                ),
          filled: true,
          fillColor: _surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _cyan.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _cyan),
          ),
        ),
      ),
    );
  }

  void _showDetail(UrsprungTopic topic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.94,
        builder: (_, sc) => _TopicDetailSheet(
          topic: topic,
          scrollController: sc,
          onRelatedTap: (t) {
            Navigator.pop(ctx);
            _showDetail(t);
          },
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 10, top: 4),
            child: Text(
              'Dein Mentor & Module',
              style: TextStyle(
                  color: _cyan, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MentorChatScreen(
                  personality: MentorPersonality.alchemist,
                  world: 'ursprung',
                ),
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_surface, _cyan.withValues(alpha: 0.12)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: const Border(left: BorderSide(color: _cyan, width: 3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.all_inclusive, color: _cyan, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Der Alchemist',
                            style: TextStyle(
                                color: _cyan,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 3),
                        Text(
                          'KI-Mentor für Bewusstsein & hermetisches Wissen',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: _cyan, size: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.school_outlined, size: 18),
            label: const Text('Alle Ursprung-Module öffnen'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _cyan,
              side: const BorderSide(color: _cyan),
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 0),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UrsprungModulesScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final UrsprungTopic topic;
  final VoidCallback onTap;
  const _TopicCard({required this.topic, required this.onTap});

  static const _cyan = Color(0xFF00D4AA);
  static const _surface = Color(0xFF080818);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: _cyan, width: 3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(topic.icon, color: _cyan, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      topic.summary,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right,
                  color: _cyan.withValues(alpha: 0.5), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicDetailSheet extends StatefulWidget {
  final UrsprungTopic topic;
  final ScrollController scrollController;
  final ValueChanged<UrsprungTopic> onRelatedTap;
  const _TopicDetailSheet({
    required this.topic,
    required this.scrollController,
    required this.onRelatedTap,
  });

  @override
  State<_TopicDetailSheet> createState() => _TopicDetailSheetState();
}

class _TopicDetailSheetState extends State<_TopicDetailSheet> {
  static const _cyan = Color(0xFF00D4AA);

  List<UrsprungTopic> _related = [];
  bool _loadingRelated = true;

  @override
  void initState() {
    super.initState();
    _loadRelated();
  }

  Future<void> _loadRelated() async {
    final r = await UrsprungTopicsService.instance.related(widget.topic);
    if (!mounted) return;
    setState(() {
      _related = r;
      _loadingRelated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: _cyan.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Icon(widget.topic.icon, color: _cyan, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.topic.title,
                  style: const TextStyle(
                      color: _cyan, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.topic.summary,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 13,
                fontStyle: FontStyle.italic),
          ),
          Divider(color: _cyan.withValues(alpha: 0.2), height: 28),
          _MarkdownText(text: widget.topic.detailMarkdown),
          if (widget.topic.sourceUrl != null) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new, size: 15),
              label: Text(widget.topic.sourceLabel ?? 'Quelle öffnen'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _cyan,
                side: BorderSide(color: _cyan.withValues(alpha: 0.6)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => launchUrl(
                Uri.parse(widget.topic.sourceUrl!),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (_loadingRelated)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                  child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: _cyan, strokeWidth: 2))),
            )
          else if (_related.isNotEmpty) ...[
            Text(
              'Verwandte Themen',
              style: TextStyle(
                  color: _cyan.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            ..._related.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () => widget.onRelatedTap(t),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: _cyan.withValues(alpha: 0.25)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(t.icon,
                              color: _cyan.withValues(alpha: 0.8), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(t.title,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13)),
                          ),
                          Icon(Icons.chevron_right,
                              color: _cyan.withValues(alpha: 0.5), size: 16),
                        ],
                      ),
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

/// Leichtgewichtiger Markdown-Renderer (Headings #/##, Bullet -/*, Bold **).
class _MarkdownText extends StatelessWidget {
  final String text;
  const _MarkdownText({required this.text});

  static const _cyan = Color(0xFF00D4AA);

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final widgets = <Widget>[];
    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }
      if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(line.substring(3),
              style: const TextStyle(
                  color: _cyan, fontSize: 15, fontWeight: FontWeight.bold)),
        ));
      } else if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(line.substring(2),
              style: const TextStyle(
                  color: _cyan, fontSize: 17, fontWeight: FontWeight.bold)),
        ));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 6, right: 8),
                child: Icon(Icons.circle, size: 5, color: _cyan),
              ),
              Expanded(
                child: _inline(line.substring(2)),
              ),
            ],
          ),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: _inline(line),
        ));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _inline(String s) {
    // Bold via ** ... **
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    int last = 0;
    for (final m in pattern.allMatches(s)) {
      if (m.start > last) {
        spans.add(TextSpan(text: s.substring(last, m.start)));
      }
      spans.add(TextSpan(
          text: m.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold)));
      last = m.end;
    }
    if (last < s.length) spans.add(TextSpan(text: s.substring(last)));
    return RichText(
      text: TextSpan(
        style:
            const TextStyle(color: Colors.white70, fontSize: 14, height: 1.65),
        children: spans,
      ),
    );
  }
}

// Fallback-Themen, falls Supabase nicht erreichbar ist.
final List<UrsprungTopic> _fallbackTopics = const [
  UrsprungTopic(
    id: 'fb-gateway',
    title: 'Gateway Experience',
    iconName: 'blur_on',
    summary:
        'Das CIA-Programm zur Erforschung veränderter Bewusstseinszustände.',
    detailMarkdown:
        'Das Monroe Institute entwickelte in den 1970ern die "Gateway Experience" - ein systematisches Trainingsprogramm zur Erreichung veränderter Bewusstseinszustände durch Hemi-Sync-Audiotechnik.\n\n'
        '1983 beauftragte die CIA Major Wayne McDonnell mit einer wissenschaftlichen Analyse. Sein 29-seitiger Bericht (declassifiziert 2003) beschreibt das Bewusstsein als "holographische Energiematrix" und die Focus-Levels als reproduzierbare Bewusstseinszustände:\n\n'
        '- Focus 10 - Körper schläft, Geist wach\n'
        '- Focus 12 - Erweitertes Bewusstsein\n'
        '- Focus 15 - Keine Zeit, keine Lokalität\n'
        '- Focus 21 - Rand zwischen physischer Existenz und anderen Energiesystemen',
    sourceLabel: 'CIA-Dokument öffnen',
    sourceUrl:
        'https://www.cia.gov/readingroom/document/cia-rdp96-00788r001700210016-5',
    sortOrder: 1,
  ),
  UrsprungTopic(
    id: 'fb-remote-viewing',
    title: 'Remote Viewing',
    iconName: 'visibility',
    summary: 'Militärisch erprobtes Protokoll zur Fernwahrnehmung - STAR GATE.',
    detailMarkdown:
        'Das US-Militär finanzierte von 1972-1995 ein geheimes Fernwahrnehmungs-Programm. Erst am SRI (Stanford Research Institute) unter Russell Targ und Hal Puthoff, später als "STAR GATE" am Fort Meade.\n\n'
        '**CRV-Protokoll (6 Stufen):**\n'
        '- Stage I: Gestalt - Form, Größe, Textur\n'
        '- Stage II: Sinneseindruck - Geräusche, Temperatur, Geruch\n'
        '- Stage III: Raumwahrnehmung\n'
        '- Stage IV: Analytische Konzepte\n'
        '- Stage V: Genaue Beschreibung\n'
        '- Stage VI: 3D-Modell-Phase',
    sourceLabel: 'STAR GATE Archiv',
    sourceUrl: 'https://www.cia.gov/readingroom/collection/star-gate',
    sortOrder: 2,
  ),
  UrsprungTopic(
    id: 'fb-hemisync',
    title: 'Hemi-Sync & Gehirnwellen',
    iconName: 'graphic_eq',
    summary: 'Binaural Beats synchronisieren Gehirnhälften für tiefe Zustände.',
    detailMarkdown:
        'Robert Monroe entdeckte zufällig, dass Tonfrequenz-Differenzen zwischen den Ohren reproduzierbare Bewusstseinszustände auslösen.\n\n'
        '**Gehirnwellen:**\n'
        '- Beta (13-30 Hz): Wachbewusstsein, Analyse\n'
        '- Alpha (8-12 Hz): Entspannung, leichte Meditation\n'
        '- Theta (4-7 Hz): Tiefe Meditation, Kreativität\n'
        '- Delta (0.5-3 Hz): Tiefer Schlaf, Regeneration\n'
        '- Gamma (30-100 Hz): Hochkonzentration',
    sourceLabel: 'Monroe Institute',
    sourceUrl: 'https://www.monroeinstitute.org/',
    sortOrder: 3,
  ),
  UrsprungTopic(
    id: 'fb-naturvoelker',
    title: 'Naturvölker-Kosmologie',
    iconName: 'public',
    summary:
        'Hopi, Lakota, Maya - Weltsicht und Prophezeiungen der Ursprungsvölker.',
    detailMarkdown:
        'Naturvölker weltweit teilen erstaunlich ähnliche kosmologische Konzepte:\n\n'
        '**Hopi:** 4 Weltzeitalter, wir leben im 4. (Tawa). Prophezeiungen über "Purification Day".\n\n'
        '**Lakota:** Mitákuye Oyásʼiŋ - "Alles ist miteinander verbunden."\n\n'
        '**Maya:** Langer Kalender endet 2012 - Ende eines 5.125-Jahre-Zyklus (Baktun).\n\n'
        'Gemeinsamer Nenner: Zeit ist zyklisch, Bewusstsein ist primär.',
    sortOrder: 4,
  ),
  UrsprungTopic(
    id: 'fb-quantum',
    title: 'Quantenbewusstsein',
    iconName: 'science',
    summary:
        'Penrose-Hameroff: Bewusstsein als Quantenphänomen in Mikrotubuli.',
    detailMarkdown:
        'Roger Penrose (Nobelpreis 2020) und Stuart Hameroff entwickelten die "Orchestrated Objective Reduction" (Orch-OR) Theorie:\n\n'
        'Bewusstsein entsteht nicht durch klassische Informationsverarbeitung, sondern durch Quantenprozesse in Mikrotubuli - Proteinstrukturen in Neuronen.\n\n'
        'Implikation: Bewusstsein ist fundamental in die Raumzeit eingebettet.',
    sourceLabel: 'ArXiv: Consciousness & Quantum',
    sourceUrl:
        'https://arxiv.org/search/?query=consciousness+quantum&searchtype=all',
    sortOrder: 5,
  ),
  UrsprungTopic(
    id: 'fb-goebekli',
    title: 'Göbekli Tepe & Ursprungswissen',
    iconName: 'account_balance',
    summary:
        '12.000 Jahre alte Tempelanlage widerlegt das Bild früher Zivilisationen.',
    detailMarkdown:
        'Göbekli Tepe (Südosttürkei) ist die älteste bekannte monumentale Kultstätte der Menschheit - 7.000 Jahre älter als Stonehenge.\n\n'
        'Erbaut von Jäger-Sammlern ca. 9.600-8.200 v.Chr. Das widerlegt die These, Architektur und Religion seien Folge der Landwirtschaft.\n\n'
        '**Klaus Schmidt:** "Göbekli Tepe wurde nicht von Hunger gebaut, sondern von Glauben."',
    sortOrder: 6,
  ),
];
