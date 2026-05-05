/// 🐇 KANINCHENBAU — Ultimative Recherche-Erfahrung.
///
/// User gibt EIN Thema ein → es entsteht ein Faden mit:
///   1. Identität (Wikidata)
///   2. Netzwerk-Graph (verbundene Entitäten)
///   3. Quellen mit Multi-Perspektive (offiziell ↔ kritisch)
///   4. Zeitstrahl (GDELT-Events)
///   5. Verwandte Pfade (Datamuse + Wikidata)
///   6. KI-Einsicht (VIRGIL via Workers AI)
///
/// Tippt der User einen Knoten/Begriff an, öffnet sich ein neuer Faden für dieses Thema.
/// Breadcrumb oben zeigt den ganzen Pfad.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cards/academic_card.dart';
import 'cards/ai_insight_card.dart';
import 'cards/annotations_card.dart';
import 'cards/court_cases_card.dart';
import 'cards/deep_research_card.dart';
import 'cards/documents_card.dart';
import 'cards/fact_check_card.dart';
import 'cards/global_impact_card.dart';
import 'cards/identity_card.dart';
import 'cards/media_compass_card.dart';
import 'cards/money_flow_card.dart';
import 'cards/network_card.dart';
import 'cards/power_relations_card.dart';
import 'cards/related_paths_card.dart';
import 'cards/rss_mentions_card.dart';
import 'cards/sanctions_card.dart';
import 'cards/sherlock_card.dart';
import 'cards/sources_card.dart';
import 'cards/timeline_card.dart';
import 'cards/wayback_card.dart';
import 'services/osint_apis.dart';
import 'services/saved_threads_service.dart';
import 'models/thread.dart';
import 'services/kaninchenbau_service.dart';
import 'widgets/breadcrumb_bar.dart';
import 'widgets/cinematic_intro.dart';
import 'widgets/kb_design.dart';
import 'widgets/rote_faden_line.dart';
import 'widgets/virgil_orb.dart';
import 'widgets/virgil_panel.dart';

class KaninchenbauScreen extends StatefulWidget {
  /// Optional vorausgewähltes Thema (z.B. von einem Tool-Button).
  final String? initialTopic;

  const KaninchenbauScreen({super.key, this.initialTopic});

  @override
  State<KaninchenbauScreen> createState() => _KaninchenbauScreenState();
}

class _KaninchenbauScreenState extends State<KaninchenbauScreen> {
  final _service = KaninchenbauService();
  final _osint = OsintApis.instance;
  final _saved = SavedThreadsService.instance;
  final _scroll = ScrollController();
  final List<_ThreadState> _stack = [];
  final Set<String> _savedTopics = {};
  bool _virgilOpen = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTopic != null && widget.initialTopic!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openThread(widget.initialTopic!);
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _openThread(String topic) async {
    final t = topic.trim();
    if (t.isEmpty) return;

    final state = _ThreadState(topic: t);
    setState(() {
      _stack.add(state);
    });

    if (_scroll.hasClients) {
      _scroll.jumpTo(0);
    }

    // Parallel laden, Karten erscheinen sobald Daten da sind.
    _loadCards(state);
  }

  Future<void> _loadCards(_ThreadState s) async {
    // Identity
    _service.fetchIdentity(s.topic).then((d) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.identityData = d;
        s.identityLoading = false;
      });
    });

    // Network — echter Wikidata-SPARQL-Graph mit Beziehungen
    _service.fetchNetworkGraph(s.topic).then((graph) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.networkNodes = graph.nodes;
        s.networkEdges = graph.edges;
        s.networkLoading = false;
      });
    });

    // Sources
    _service.fetchSources(s.topic).then((src) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.sources = src;
        s.sourcesLoading = false;
      });
    });

    // Timeline
    _service.fetchTimeline(s.topic).then((entries) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.timelineEntries = entries;
        s.timelineLoading = false;
      });
    });

    // Related
    _service.fetchRelatedTopics(s.topic).then((topics) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.relatedTopics = topics;
        s.relatedLoading = false;
      });
    });

    // Geldflüsse (warten bis Network-Daten da sind, dann mit Kontext)
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted || s.disposed) return;
      _service
          .fetchMoneyFlows(s.topic, networkContext: s.networkNodes)
          .then((flows) {
        if (!mounted || s.disposed) return;
        setState(() {
          s.moneyFlows = flows;
          s.moneyLoading = false;
        });
      });
    });

    // Medien-Kompass
    _service.fetchMediaCompass(s.topic).then((points) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.compassPoints = points;
        s.compassLoading = false;
      });
    });

    // Dokumente
    _service.fetchLeakedDocuments(s.topic).then((docs) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.documents = docs;
        s.documentsLoading = false;
      });
    });

    // Globale Auswirkungen
    _service.fetchGlobalImpact(s.topic).then((impacts) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.globalImpacts = impacts;
        s.globalLoading = false;
      });
    });

    // OSINT-Layer parallel
    _osint.fetchOpenAlexPapers(s.topic).then((papers) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.academicPapers = papers;
        s.academicLoading = false;
      });
    });

    _osint.fetchSanctions(s.topic).then((sanctions) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.sanctions = sanctions;
        s.sanctionsLoading = false;
      });
    });

    _osint.fetchLittleSisRelations(s.topic).then((rels) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.powerRelations = rels;
        s.powerRelationsLoading = false;
      });
    });

    _osint.fetchWaybackSnapshots(s.topic).then((snaps) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.waybackSnapshots = snaps;
        s.waybackLoading = false;
      });
    });

    _osint.fetchCourtCases(s.topic).then((cases) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.courtCases = cases;
        s.courtLoading = false;
      });
    });

    _osint.fetchFactChecks(s.topic).then((fcs) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.factChecks = fcs;
        s.factCheckLoading = false;
      });
    });

    // RSS-Aggregator (Worker)
    _service.fetchRssAggregate(s.topic).then((rss) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.rssItems = rss;
        s.rssLoading = false;
      });
    });

    // AI Insight (etwas verzögert, damit Kontext vorhanden ist)
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || s.disposed) return;
      _service.fetchAiInsight(s.topic).then((text) {
        if (!mounted || s.disposed) return;
        setState(() {
          s.aiInsight = text;
          s.aiLoading = false;
        });
      });
    });
  }

  void _jumpToBreadcrumb(int index) {
    if (index >= _stack.length - 1) return;
    setState(() {
      for (var i = _stack.length - 1; i > index; i--) {
        _stack[i].disposed = true;
        _stack.removeAt(i);
      }
    });
  }

  void _close() {
    if (_stack.isEmpty) {
      Navigator.of(context).maybePop();
    } else {
      HapticFeedback.selectionClick();
      setState(() {
        _stack.last.disposed = true;
        _stack.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _stack.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _stack.isNotEmpty) {
          _close();
        }
      },
      child: Scaffold(
        backgroundColor: KbDesign.voidBlack,
        body: _stack.isEmpty
            ? CinematicIntro(onSubmit: _openThread)
            : _buildThread(_stack.last),
      ),
    );
  }

  Widget _buildThread(_ThreadState s) {
    final path = _stack.map((e) => e.topic).toList();
    return Stack(
      children: [
        Column(
          children: [
            BreadcrumbBar(
              path: path,
              onJump: _jumpToBreadcrumb,
              onClose: _close,
              saved: _savedTopics.contains(s.topic.toLowerCase()),
              onSave: () => _saveCurrentThread(s),
            ),
            Expanded(
              child: _buildScrollContent(s),
            ),
          ],
        ),
        // Virgil-Orb unten rechts — öffnet Full-Panel beim Tap
        Positioned(
          right: 18,
          bottom: 18,
          child: VirgilOrb(
            insight: s.aiInsight,
            thinking: s.aiLoading,
            onTap: () => setState(() => _virgilOpen = true),
          ),
        ),
        // Virgil Full-Panel
        if (_virgilOpen)
          VirgilPanel(
            topic: s.topic,
            initialInsight: s.aiInsight,
            cardContext: _buildCardContext(s),
            onClose: () => setState(() => _virgilOpen = false),
          ),
      ],
    );
  }

  Future<void> _saveCurrentThread(_ThreadState s) async {
    final result = await _saved.saveThread(
      topic: s.topic,
      path: _stack.map((e) => e.topic).toList(),
    );
    if (!mounted) return;
    if (result != null) {
      setState(() => _savedTopics.add(s.topic.toLowerCase()));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔖 Recherche gespeichert'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Speichern fehlgeschlagen — eingeloggt?'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Aggregiert den Inhalt aller geladenen Karten als Kontext für Virgil.
  String _buildCardContext(_ThreadState s) {
    final parts = <String>[];
    if (s.identityData != null) {
      final d = s.identityData!;
      parts.add('Identität: ${d['label']} — ${d['description']}');
    }
    if (s.networkNodes.isNotEmpty) {
      final names = s.networkNodes
          .where((n) => n.id != 'center')
          .map((n) => n.label)
          .take(8)
          .join(', ');
      if (names.isNotEmpty) parts.add('Netzwerk: $names');
    }
    if (s.timelineEntries.isNotEmpty) {
      final events = s.timelineEntries
          .take(5)
          .map((e) => '${e.year}: ${e.title}')
          .join(' | ');
      parts.add('Zeitstrahl: $events');
    }
    if (s.sources.isNotEmpty) {
      final titles = s.sources.take(4).map((src) => src.title).join(' | ');
      parts.add('Quellen: $titles');
    }
    return parts.join(' || ');
  }

  Widget _buildScrollContent(_ThreadState s) {
    return LayoutBuilder(
      builder: (_, c) {
        return Stack(
          children: [
            // Roter Faden links
            Positioned(
              left: 6,
              top: 0,
              bottom: 0,
              child: RoteFadenLine(scroll: _scroll, maxHeight: c.maxHeight),
            ),
            // Inhalt
            Padding(
              padding: const EdgeInsets.only(left: 28, right: 16),
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.only(top: 16, bottom: 120),
                children: [
                  _StaggeredCard(
                    delay: const Duration(milliseconds: 0),
                    child: IdentityCard(
                      topic: s.topic,
                      data: s.identityData,
                      loading: s.identityLoading,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StaggeredCard(
                    delay: const Duration(milliseconds: 80),
                    child: DeepResearchCard(topic: s.topic),
                  ),
                  const SizedBox(height: 16),
                  _StaggeredCard(
                    delay: const Duration(milliseconds: 150),
                    child: AiInsightCard(
                      insight: s.aiInsight,
                      loading: s.aiLoading,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StaggeredCard(
                    delay: const Duration(milliseconds: 300),
                    child: NetworkCard(
                      nodes: s.networkNodes,
                      edges: s.networkEdges,
                      loading: s.networkLoading,
                      onTapNode: _openThread,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StaggeredCard(
                    delay: const Duration(milliseconds: 340),
                    child: PowerRelationsCard(
                      relations: s.powerRelations,
                      loading: s.powerRelationsLoading,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StaggeredCard(
                    delay: const Duration(milliseconds: 380),
                    child: SanctionsCard(
                      entries: s.sanctions,
                      loading: s.sanctionsLoading,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StaggeredCard(
                    delay: const Duration(milliseconds: 420),
                    child: MoneyFlowCard(
                      flows: s.moneyFlows,
                      loading: s.moneyLoading,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StaggeredCard(
                    delay: const Duration(milliseconds: 450),
                    child: SourcesCard(
                      sources: s.sources,
                      loading: s.sourcesLoading,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StaggeredCard(
                    delay: const Duration(milliseconds: 480),
                    child: AcademicCard(
                      papers: s.academicPapers,
                      loading: s.academicLoading,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StaggeredCard(
                    delay: const Duration(milliseconds: 520),
                    child: MediaCompassCard(
                      points: s.compassPoints,
                      loading: s.compassLoading,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StaggeredCard(
                    delay: const Duration(milliseconds: 560),
                    child: FactCheckCard(
                      checks: s.factChecks,
                      loading: s.factCheckLoading,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StaggeredCard(
                    delay: const Duration(milliseconds: 600),
                    child: TimelineCard(
                      entries: s.timelineEntries,
                      loading: s.timelineLoading,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StaggeredCard(
                    delay: const Duration(milliseconds: 640),
                    child: WaybackCard(
                      snapshots: s.waybackSnapshots,
                      loading: s.waybackLoading,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StaggeredCard(
                    delay: const Duration(milliseconds: 670),
                    child: GlobalImpactCard(
                      impacts: s.globalImpacts,
                      loading: s.globalLoading,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StaggeredCard(
                    delay: const Duration(milliseconds: 700),
                    child: CourtCasesCard(
                      cases: s.courtCases,
                      loading: s.courtLoading,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StaggeredCard(
                    delay: const Duration(milliseconds: 740),
                    child: DocumentsCard(
                      docs: s.documents,
                      loading: s.documentsLoading,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StaggeredCard(
                    delay: const Duration(milliseconds: 770),
                    child: RssMentionsCard(
                      items: s.rssItems,
                      loading: s.rssLoading,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StaggeredCard(
                    delay: const Duration(milliseconds: 790),
                    child: AnnotationsCard(topic: s.topic),
                  ),
                  const SizedBox(height: 16),
                  _StaggeredCard(
                    delay: const Duration(milliseconds: 810),
                    child: SherlockCard(topic: s.topic),
                  ),
                  const SizedBox(height: 16),
                  _StaggeredCard(
                    delay: const Duration(milliseconds: 830),
                    child: RelatedPathsCard(
                      topics: s.relatedTopics,
                      loading: s.relatedLoading,
                      onTap: _openThread,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Mutable State pro Faden — Karten werden einzeln und parallel gefüllt.
class _ThreadState {
  final String topic;
  bool disposed = false;

  Map<String, dynamic>? identityData;
  bool identityLoading = true;

  List<NetworkNode> networkNodes = const [];
  List<NetworkEdge> networkEdges = const [];
  bool networkLoading = true;

  List<SourceItem> sources = const [];
  bool sourcesLoading = true;

  List<TimelineEntry> timelineEntries = const [];
  bool timelineLoading = true;

  List<String> relatedTopics = const [];
  bool relatedLoading = true;

  String? aiInsight;
  bool aiLoading = true;

  List<MoneyFlow> moneyFlows = const [];
  bool moneyLoading = true;

  List<MediaCompassPoint> compassPoints = const [];
  bool compassLoading = true;

  List<LeakedDocument> documents = const [];
  bool documentsLoading = true;

  List<GlobalImpact> globalImpacts = const [];
  bool globalLoading = true;

  List<AcademicPaper> academicPapers = const [];
  bool academicLoading = true;

  List<SanctionEntry> sanctions = const [];
  bool sanctionsLoading = true;

  List<PowerRelation> powerRelations = const [];
  bool powerRelationsLoading = true;

  List<WaybackSnapshot> waybackSnapshots = const [];
  bool waybackLoading = true;

  List<CourtCase> courtCases = const [];
  bool courtLoading = true;

  List<FactCheck> factChecks = const [];
  bool factCheckLoading = true;

  List<RssItem> rssItems = const [];
  bool rssLoading = true;

  _ThreadState({required this.topic});
}

/// Karte mit gestaffeltem Einfliege-Effekt von unten.
class _StaggeredCard extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _StaggeredCard({required this.child, required this.delay});

  @override
  State<_StaggeredCard> createState() => _StaggeredCardState();
}

class _StaggeredCardState extends State<_StaggeredCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _slide = Tween(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _slide.value),
        child: Opacity(opacity: _fade.value, child: widget.child),
      ),
    );
  }
}
