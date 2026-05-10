/// 🐇 KANINCHENBAU — Ultimative Recherche-Erfahrung.
///
/// A — Onboarding: Vorschläge + Verlauf in CinematicIntro
/// B — Cinematic Loading: Ticker + Glow-Ring beim ersten Laden
/// C — Section-Headers: 3 thematische Gruppen
/// D — Virgil als Chat-Begleiter: FloatingButton + Slide-Panel
/// E — Quellen-Timeline: RSS + GDELT kombiniert (TimelineCard)
/// F — Share & Export: Langer Druck → Clipboard-Kopie
/// G — Bookmark & History: SQLite-Verlauf, Chips auf Intro
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cards/abgeordnete_card.dart';
import 'cards/academic_card.dart';
import 'cards/ai_insight_card.dart';
import 'cards/aleph_card.dart';
import 'cards/annotations_card.dart';
import 'cards/archive_card.dart';
import 'cards/companies_card.dart';
import 'cards/court_cases_card.dart';
import 'cards/deep_research_card.dart';
import 'cards/documents_card.dart';
import 'cards/eu_votes_card.dart';
import 'cards/fact_check_card.dart';
import 'cards/global_impact_card.dart';
import 'cards/identity_card.dart';
import 'cards/key_persons_card.dart';
import 'cards/lobbying_card.dart';
import 'cards/media_compass_card.dart';
import 'cards/money_flow_card.dart';
import 'cards/network_card.dart';
import 'cards/offshore_card.dart';
import 'cards/opensanctions_card.dart';
import 'cards/power_relations_card.dart';
import 'cards/propaganda_card.dart';
import 'cards/pubmed_card.dart';
import 'cards/related_paths_card.dart';
import 'cards/rss_mentions_card.dart';
import 'cards/sanctions_card.dart';
import 'cards/semantic_papers_card.dart';
import 'cards/sherlock_card.dart';
import 'cards/skandale_card.dart';
import 'cards/sources_card.dart';
import 'cards/timeline_card.dart';
import 'cards/wayback_card.dart';
// ── Mindblow-Tier (18 Tiefenquellen) ──
import 'cards/usaspending_card.dart';
import 'cards/worldbank_card.dart';
import 'cards/openownership_card.dart';
import 'cards/openspending_card.dart';
import 'cards/courtlistener_card.dart';
import 'cards/muckrock_card.dart';
import 'cards/hudoc_card.dart';
import 'cards/eucuria_card.dart';
import 'cards/opensecrets_card.dart';
import 'cards/fec_card.dart';
import 'cards/littlesis_card.dart';
import 'cards/everypolitician_card.dart';
import 'cards/documentcloud_card.dart';
import 'cards/wikileaks_card.dart';
import 'cards/ciacrest_card.dart';
import 'cards/snowden_card.dart';
import 'cards/oc_network_card.dart';
import 'cards/corpwatch_card.dart';
import 'services/kb_history_service.dart';
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
import 'widgets/youtube_card.dart';

class KaninchenbauScreen extends StatefulWidget {
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

    // G — im Verlauf speichern
    KbHistoryService.addTopic(t);

    final state = _ThreadState(topic: t);
    setState(() => _stack.add(state));

    if (_scroll.hasClients) _scroll.jumpTo(0);

    // B — Ladeoverlay nach max. 3 s ausblenden (Fallback)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !state.disposed) {
        setState(() => state.showLoadingOverlay = false);
      }
    });

    _loadCards(state);
  }

  Future<void> _loadCards(_ThreadState s) async {
    // Identity — sobald geladen, Overlay nach kurzer Transition ausblenden
    _service.fetchIdentity(s.topic).then((d) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.identityData = d;
        s.identityLoading = false;
        s.loadedApiCount++;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && !s.disposed) setState(() => s.showLoadingOverlay = false);
      });
    });

    _service.fetchNetworkGraph(s.topic).then((graph) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.networkNodes = graph.nodes;
        s.networkEdges = graph.edges;
        s.networkLoading = false;
        s.loadedApiCount++;
      });
    });

    _service.fetchSources(s.topic).then((src) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.sources = src;
        s.sourcesLoading = false;
        s.loadedApiCount++;
      });
    });

    _service.fetchTimeline(s.topic).then((entries) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.timelineEntries = entries;
        s.timelineLoading = false;
        s.loadedApiCount++;
      });
    });

    _service.fetchRelatedTopics(s.topic).then((topics) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.relatedTopics = topics;
        s.relatedLoading = false;
        s.loadedApiCount++;
      });
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted || s.disposed) return;
      _service.fetchMoneyFlows(s.topic, networkContext: s.networkNodes).then((flows) {
        if (!mounted || s.disposed) return;
        setState(() {
          s.moneyFlows = flows;
          s.moneyLoading = false;
          s.loadedApiCount++;
        });
      });
    });

    _service.fetchMediaCompass(s.topic).then((points) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.compassPoints = points;
        s.compassLoading = false;
        s.loadedApiCount++;
      });
    });

    _service.fetchLeakedDocuments(s.topic).then((docs) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.documents = docs;
        s.documentsLoading = false;
        s.loadedApiCount++;
      });
    });

    _service.fetchGlobalImpact(s.topic).then((impacts) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.globalImpacts = impacts;
        s.globalLoading = false;
        s.loadedApiCount++;
      });
    });

    _osint.fetchOpenAlexPapers(s.topic).then((papers) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.academicPapers = papers;
        s.academicLoading = false;
        s.loadedApiCount++;
      });
    });

    _osint.fetchSanctions(s.topic).then((sanctions) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.sanctions = sanctions;
        s.sanctionsLoading = false;
        s.loadedApiCount++;
      });
    });

    _osint.fetchLittleSisRelations(s.topic).then((rels) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.powerRelations = rels;
        s.powerRelationsLoading = false;
        s.loadedApiCount++;
      });
    });

    _osint.fetchWaybackSnapshots(s.topic).then((snaps) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.waybackSnapshots = snaps;
        s.waybackLoading = false;
        s.loadedApiCount++;
      });
    });

    _osint.fetchCourtCases(s.topic).then((cases) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.courtCases = cases;
        s.courtLoading = false;
        s.loadedApiCount++;
      });
    });

    _osint.fetchFactChecks(s.topic).then((fcs) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.factChecks = fcs;
        s.factCheckLoading = false;
        s.loadedApiCount++;
      });
    });

    _service.fetchRssAggregate(s.topic).then((rss) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.rssItems = rss;
        s.rssLoading = false;
        s.loadedApiCount++;
      });
      _service.fetchPropagandaAnalysis(s.topic, rss).then((analysis) {
        if (!mounted || s.disposed) return;
        setState(() {
          s.propagandaAnalysis = analysis;
          s.propagandaLoading = false;
        });
      });
    });

    _service.fetchKeyPersons(s.topic).then((persons) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.keyPersons = persons;
        s.keyPersonsLoading = false;
        s.loadedApiCount++;
      });
    });

    _service.fetchLobbying(s.topic).then((entries) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.lobbyEntries = entries;
        s.lobbyLoading = false;
        s.loadedApiCount++;
      });
    });

    _service.fetchAbgeordnete(s.topic).then((pols) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.abgeordnete = pols;
        s.abgeordneteLoading = false;
        s.loadedApiCount++;
      });
    });

    _service.fetchSkandale(s.topic).then((items) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.skandale = items;
        s.skandaleLoading = false;
        s.loadedApiCount++;
      });
    });

    // ── DEEP-API LAYER ──────────────────────────────────────────────────────
    _service.fetchOffshoreLeaks(s.topic).then((entities) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.offshoreEntities = entities;
        s.offshoreLoading = false;
        s.loadedApiCount++;
      });
    });

    _service.fetchCompanies(s.topic).then((companies) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.companies = companies;
        s.companiesLoading = false;
        s.loadedApiCount++;
      });
    });

    _service.fetchOpenSanctions(s.topic).then((results) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.openSanctions = results;
        s.openSanctionsLoading = false;
        s.loadedApiCount++;
      });
    });

    _service.fetchAleph(s.topic).then((docs) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.alephDocs = docs;
        s.alephLoading = false;
        s.loadedApiCount++;
      });
    });

    _service.fetchPubMed(s.topic).then((papers) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.pubmedPapers = papers;
        s.pubmedLoading = false;
        s.loadedApiCount++;
      });
    });

    _service.fetchSemanticPapers(s.topic).then((papers) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.semanticPapers = papers;
        s.semanticLoading = false;
        s.loadedApiCount++;
      });
    });

    _service.fetchArchive(s.topic).then((docs) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.archiveDocs = docs;
        s.archiveLoading = false;
        s.loadedApiCount++;
      });
    });

    _service.fetchEuVotes(s.topic).then((votes) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.euVotes = votes;
        s.euVotesLoading = false;
        s.loadedApiCount++;

      });
    });

    // ── MINDBLOW-TIER (18 Tiefenquellen) ───────────────────────────────────
    _service.fetchUsaSpending(s.topic).then((items) {
      if (!mounted || s.disposed) return;
      setState(() { s.usaSpending = items; s.usaSpendingLoading = false; s.loadedApiCount++; });
    });
    _service.fetchWorldBank(s.topic).then((items) {
      if (!mounted || s.disposed) return;
      setState(() { s.worldBank = items; s.worldBankLoading = false; s.loadedApiCount++; });
    });
    _service.fetchOpenOwnership(s.topic).then((items) {
      if (!mounted || s.disposed) return;
      setState(() { s.openOwnership = items; s.openOwnershipLoading = false; s.loadedApiCount++; });
    });
    _service.fetchOpenSpending(s.topic).then((items) {
      if (!mounted || s.disposed) return;
      setState(() { s.openSpending = items; s.openSpendingLoading = false; s.loadedApiCount++; });
    });
    _service.fetchCourtListener(s.topic).then((items) {
      if (!mounted || s.disposed) return;
      setState(() { s.courtListener = items; s.courtListenerLoading = false; s.loadedApiCount++; });
    });
    _service.fetchMuckRock(s.topic).then((items) {
      if (!mounted || s.disposed) return;
      setState(() { s.muckRock = items; s.muckRockLoading = false; s.loadedApiCount++; });
    });
    _service.fetchHudoc(s.topic).then((items) {
      if (!mounted || s.disposed) return;
      setState(() { s.hudoc = items; s.hudocLoading = false; s.loadedApiCount++; });
    });
    _service.fetchEuCuria(s.topic).then((items) {
      if (!mounted || s.disposed) return;
      setState(() { s.euCuria = items; s.euCuriaLoading = false; s.loadedApiCount++; });
    });
    _service.fetchOpenSecrets(s.topic).then((items) {
      if (!mounted || s.disposed) return;
      setState(() { s.openSecrets = items; s.openSecretsLoading = false; s.loadedApiCount++; });
    });
    _service.fetchFec(s.topic).then((items) {
      if (!mounted || s.disposed) return;
      setState(() { s.fec = items; s.fecLoading = false; s.loadedApiCount++; });
    });
    _service.fetchLittleSis(s.topic).then((items) {
      if (!mounted || s.disposed) return;
      setState(() { s.littleSis = items; s.littleSisLoading = false; s.loadedApiCount++; });
    });
    _service.fetchEveryPolitician(s.topic).then((items) {
      if (!mounted || s.disposed) return;
      setState(() { s.everyPolitician = items; s.everyPoliticianLoading = false; s.loadedApiCount++; });
    });
    _service.fetchDocumentCloud(s.topic).then((items) {
      if (!mounted || s.disposed) return;
      setState(() { s.documentCloud = items; s.documentCloudLoading = false; s.loadedApiCount++; });
    });
    _service.fetchWikiLeaks(s.topic).then((items) {
      if (!mounted || s.disposed) return;
      setState(() { s.wikiLeaks = items; s.wikiLeaksLoading = false; s.loadedApiCount++; });
    });
    _service.fetchCiaCrest(s.topic).then((items) {
      if (!mounted || s.disposed) return;
      setState(() { s.ciaCrest = items; s.ciaCrestLoading = false; s.loadedApiCount++; });
    });
    _service.fetchSnowden(s.topic).then((items) {
      if (!mounted || s.disposed) return;
      setState(() { s.snowden = items; s.snowdenLoading = false; s.loadedApiCount++; });
    });
    _service.fetchOcNetwork(s.topic).then((items) {
      if (!mounted || s.disposed) return;
      setState(() { s.ocNetwork = items; s.ocNetworkLoading = false; s.loadedApiCount++; });
    });
    _service.fetchCorpWatch(s.topic).then((items) {
      if (!mounted || s.disposed) return;
      setState(() { s.corpWatch = items; s.corpWatchLoading = false; s.loadedApiCount++; });
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

  // F — Share: formatierten Text in Zwischenablage kopieren
  void _shareThread(_ThreadState s) {
    final buf = StringBuffer();
    buf.writeln('🐇 KANINCHENBAU — ${s.topic.toUpperCase()}');
    buf.writeln('');
    if (s.identityData != null) {
      buf.writeln('📌 ${s.identityData!['label'] ?? s.topic}');
      final desc = s.identityData!['description'];
      if (desc != null && (desc as String).isNotEmpty) buf.writeln(desc);
      buf.writeln('');
    }
    if (s.networkNodes.isNotEmpty) {
      final names = s.networkNodes
          .where((n) => n.id != 'center')
          .map((n) => n.label)
          .take(6)
          .join(', ');
      if (names.isNotEmpty) buf.writeln('🕸️ Netzwerk: $names');
    }
    if (s.keyPersons.isNotEmpty) {
      buf.writeln('👤 Schlüsselpersonen: ${s.keyPersons.take(4).map((p) => p.name).join(', ')}');
    }
    if (s.rssItems.isNotEmpty) {
      buf.writeln('');
      buf.writeln('📰 Aktuelle Berichte:');
      for (final item in s.rssItems.take(3)) {
        buf.writeln('• ${item.title}');
      }
    }
    if (s.skandale.isNotEmpty) {
      buf.writeln('');
      buf.writeln('🚨 Kontrovers: ${s.skandale.first.title}');
    }
    if (s.aiInsight != null && s.aiInsight!.isNotEmpty) {
      buf.writeln('');
      buf.writeln('🤖 Virgil: ${s.aiInsight!.substring(0, math.min(200, s.aiInsight!.length))}…');
    }
    buf.writeln('');
    buf.writeln('— via Weltenbibliothek App');

    Clipboard.setData(ClipboardData(text: buf.toString()));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('In Zwischenablage kopiert'),
          ],
        ),
        backgroundColor: KbDesign.neonRed.withValues(alpha: 0.9),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _stack.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _stack.isNotEmpty) _close();
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
              // B — AnimatedSwitcher: Loading-Overlay → Karten
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 700),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeIn,
                child: s.showLoadingOverlay
                    ? _ResearchLoadingOverlay(
                        key: const ValueKey('loading'),
                        topic: s.topic,
                        loadedCount: s.loadedApiCount,
                        totalCount: 46,
                      )
                    : _buildScrollContent(s),
              ),
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
            Positioned(
              left: 6, top: 0, bottom: 0,
              child: RoteFadenLine(scroll: _scroll, maxHeight: c.maxHeight),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 28, right: 16),
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.only(top: 16, bottom: 130),
                children: [
                  // ── C: ABSCHNITT 1 — ÜBERSICHT ──────────────────────────
                  const _SectionHeader(
                    label: 'ÜBERSICHT',
                    icon: Icons.search,
                    color: Color(0xFFE53935),
                  ),
                  _stag(0, IdentityCard(
                    topic: s.topic,
                    data: s.identityData,
                    loading: s.identityLoading,
                  )),
                  _gap(),
                  _stag(80, DeepResearchCard(topic: s.topic)),
                  _gap(),
                  _stag(150, AiInsightCard(
                    insight: s.aiInsight,
                    loading: s.aiLoading,
                  )),
                  _gap(),
                  _stag(200, YoutubeCard(topic: s.topic)),

                  // ── C: ABSCHNITT 2 — NETZWERK & MACHT ──────────────────
                  const _SectionHeader(
                    label: 'NETZWERK & MACHT',
                    icon: Icons.hub,
                    color: Color(0xFFFFB300),
                  ),
                  _stag(250, NetworkCard(
                    nodes: s.networkNodes,
                    edges: s.networkEdges,
                    loading: s.networkLoading,
                    onTapNode: _openThread,
                  )),
                  _gap(),
                  _stag(290, KeyPersonsCard(
                    persons: s.keyPersons,
                    loading: s.keyPersonsLoading,
                    onTapPerson: _openThread,
                  )),
                  _gap(),
                  _stag(310, PowerRelationsCard(
                    relations: s.powerRelations,
                    loading: s.powerRelationsLoading,
                  )),
                  _gap(),
                  _stag(330, LobbyingCard(
                    entries: s.lobbyEntries,
                    loading: s.lobbyLoading,
                  )),
                  _gap(),
                  _stag(350, AbgeordneteCard(
                    politicians: s.abgeordnete,
                    loading: s.abgeordneteLoading,
                  )),
                  _gap(),
                  _stag(370, MoneyFlowCard(
                    flows: s.moneyFlows,
                    loading: s.moneyLoading,
                  )),
                  _gap(),
                  _stag(390, SanctionsCard(
                    entries: s.sanctions,
                    loading: s.sanctionsLoading,
                  )),

                  // ── C: ABSCHNITT 3 — KRITIK & GEGENDARSTELLUNG ──────────
                  const _SectionHeader(
                    label: 'KRITIK & GEGENDARSTELLUNG',
                    icon: Icons.balance,
                    color: Color(0xFFAB47BC),
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
                  _stag(690, PubMedCard(
                    papers: s.pubmedPapers,
                    loading: s.pubmedLoading,
                  )),
                  _gap(),
                  _stag(700, SemanticPapersCard(
                    papers: s.semanticPapers,
                    loading: s.semanticLoading,
                  )),
                  _gap(),
                  _stag(710, ArchiveCard(
                    docs: s.archiveDocs,
                    loading: s.archiveLoading,
                  )),
                  _gap(),
                  _stag(720, EuVotesCard(
                    votes: s.euVotes,
                    loading: s.euVotesLoading,
                  )),
                  _gap(),

                  // ── MINDBLOW: GELDFLÜSSE & WIRTSCHAFTSMACHT ─────────────
                  const _SectionHeader(
                    label: 'GELDFLÜSSE & WIRTSCHAFTSMACHT',
                    icon: Icons.account_balance,
                    color: Color(0xFFFFB300),
                  ),
                  _stag(760, UsaSpendingCard(items: s.usaSpending, loading: s.usaSpendingLoading)),
                  _gap(),
                  _stag(770, WorldBankCard(items: s.worldBank, loading: s.worldBankLoading)),
                  _gap(),
                  _stag(780, OpenOwnershipCard(items: s.openOwnership, loading: s.openOwnershipLoading)),
                  _gap(),
                  _stag(790, OpenSpendingCard(items: s.openSpending, loading: s.openSpendingLoading)),
                  _gap(),

                  // ── MINDBLOW: GERICHTSAKTEN & RECHTSDOKUMENTE ───────────
                  const _SectionHeader(
                    label: 'GERICHTSAKTEN & RECHTSDOKUMENTE',
                    icon: Icons.gavel,
                    color: Color(0xFF7986CB),
                  ),
                  _stag(800, CourtListenerCard(items: s.courtListener, loading: s.courtListenerLoading)),
                  _gap(),
                  _stag(810, MuckRockCard(items: s.muckRock, loading: s.muckRockLoading)),
                  _gap(),
                  _stag(820, HudocCard(items: s.hudoc, loading: s.hudocLoading)),
                  _gap(),
                  _stag(830, EuCuriaCard(items: s.euCuria, loading: s.euCuriaLoading)),
                  _gap(),

                  // ── MINDBLOW: POLITISCHE FINANZIERUNG & NETZWERKE ───────
                  const _SectionHeader(
                    label: 'POLITISCHE FINANZIERUNG & NETZWERKE',
                    icon: Icons.how_to_vote,
                    color: Color(0xFFEC407A),
                  ),
                  _stag(840, OpenSecretsCard(items: s.openSecrets, loading: s.openSecretsLoading)),
                  _gap(),
                  _stag(850, FecCard(items: s.fec, loading: s.fecLoading)),
                  _gap(),
                  _stag(860, LittleSisCard(items: s.littleSis, loading: s.littleSisLoading)),
                  _gap(),
                  _stag(870, EveryPoliticianCard(items: s.everyPolitician, loading: s.everyPoliticianLoading)),
                  _gap(),

                  // ── MINDBLOW: INVESTIGATIVE DOKUMENTE & WHISTLEBLOWER ───
                  const _SectionHeader(
                    label: 'INVESTIGATIVE DOKUMENTE & WHISTLEBLOWER',
                    icon: Icons.warning_amber,
                    color: Color(0xFFFF7043),
                  ),
                  _stag(880, DocumentCloudCard(items: s.documentCloud, loading: s.documentCloudLoading)),
                  _gap(),
                  _stag(890, WikiLeaksCard(items: s.wikiLeaks, loading: s.wikiLeaksLoading)),
                  _gap(),
                  _stag(900, CiaCrestCard(items: s.ciaCrest, loading: s.ciaCrestLoading)),
                  _gap(),
                  _stag(910, SnowdenCard(items: s.snowden, loading: s.snowdenLoading)),
                  _gap(),

                  // ── MINDBLOW: UNTERNEHMENS-VERFLECHTUNGEN ───────────────
                  const _SectionHeader(
                    label: 'UNTERNEHMENS-VERFLECHTUNGEN',
                    icon: Icons.business_center,
                    color: Color(0xFF26A69A),
                  ),
                  _stag(920, OcNetworkCard(items: s.ocNetwork, loading: s.ocNetworkLoading)),
                  _gap(),
                  _stag(930, CorpWatchCard(items: s.corpWatch, loading: s.corpWatchLoading)),
                  _gap(),

                  _stag(940, AnnotationsCard(topic: s.topic)),
                  _gap(),
                  _stag(950, SherlockCard(topic: s.topic)),
                  _gap(),
                  _stag(960, RelatedPathsCard(
                    topics: s.relatedTopics,
                    loading: s.relatedLoading,
                    onTap: _openThread,
                  )),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _stag(int ms, Widget child) => _StaggeredCard(
        delay: Duration(milliseconds: ms),
        child: child,
      );

  Widget _gap() => const SizedBox(height: 14);
}

// ═══════════════════════════════════════════════════════════════════════════
// B — CINEMATIC LOADING OVERLAY
// ═══════════════════════════════════════════════════════════════════════════

class _ResearchLoadingOverlay extends StatefulWidget {
  final String topic;
  final int loadedCount;
  final int totalCount;

  const _ResearchLoadingOverlay({
    super.key,
    required this.topic,
    required this.loadedCount,
    required this.totalCount,
  });

  @override
  State<_ResearchLoadingOverlay> createState() => _ResearchLoadingOverlayState();
}

class _ResearchLoadingOverlayState extends State<_ResearchLoadingOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _ring;
  int _msgIdx = 0;

  static const _msgs = [
    'Wikidata wird befragt …',
    'Netzwerk-Verbindungen kartiert …',
    '46 Quellen werden analysiert …',
    'Historische Events durchsucht …',
    'Sanktionslisten geprüft …',
    'Lobbying-Register abgefragt …',
    'OCCRP Aleph durchsucht …',
    'Offshore-Leaks überprüft …',
    'Firmenregister abgefragt …',
    'OpenSanctions gecheckt …',
    'PubMed Studien geladen …',
    'Internet Archive durchsucht …',
    'EU-Abstimmungen abgerufen …',

    'Akademische Paper durchsucht …',
    'Propaganda-Linsen kalibriert …',
    'Vergangene Snapshots geladen …',
    'USASpending durchsucht …',
    'Weltbank-Projekte geladen …',
    'OpenOwnership geprüft …',
    'CourtListener durchsucht …',
    'MuckRock FOIA-Anfragen …',
    'EGMR-Urteile geladen …',
    'OpenSecrets analysiert …',
    'LittleSis-Netzwerk …',
    'DocumentCloud durchsucht …',
    'WikiLeaks-Archiv …',
    'CIA-CREST gecheckt …',
    'Snowden-Files …',
    'Vorstands-Verflechtungen …',
    'Virgil denkt nach …',
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _ring = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..repeat();
    _advanceMsg();
  }

  void _advanceMsg() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 1600));
      if (!mounted) return;
      setState(() => _msgIdx = (_msgIdx + 1) % _msgs.length);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalCount > 0
        ? (widget.loadedCount / widget.totalCount).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      key: const ValueKey('loading'),
      color: KbDesign.voidBlack,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulse, _ring]),
        builder: (_, __) {
          final pulse = _pulse.value;
          final ring = _ring.value;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Topic-Label
                Text(
                  widget.topic.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 11,
                        color: KbDesign.goldAccent.withValues(alpha: 0.7)),
                    const SizedBox(width: 5),
                    Text(
                      'KANINCHENBAU RECHERCHE',
                      style: TextStyle(
                        color: KbDesign.goldAccent.withValues(alpha: 0.65),
                        fontSize: 10,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                // Glow-Ring + Fortschritt
                SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: KbDesign.neonRed
                                  .withValues(alpha: 0.15 + 0.1 * pulse),
                              blurRadius: 60 + 20 * pulse,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      // Rotating arc background
                      CustomPaint(
                        size: const Size(160, 160),
                        painter: _RingPainter(
                          progress: progress,
                          rotation: ring * 2 * math.pi,
                          color: KbDesign.neonRed,
                        ),
                      ),
                      // Rabbit emoji
                      Text(
                        '🐇',
                        style: TextStyle(
                          fontSize: 52 + 4 * pulse,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Ticker-Nachricht
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: anim,
                        curve: Curves.easeOut,
                      )),
                      child: child,
                    ),
                  ),
                  child: Text(
                    _msgs[_msgIdx],
                    key: ValueKey(_msgIdx),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Fortschrittsanzeige
                Text(
                  '${widget.loadedCount} / ${widget.totalCount} Quellen',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double rotation;
  final Color color;

  const _RingPainter({
    required this.progress,
    required this.rotation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 8;

    // Track ring (dim)
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = color.withValues(alpha: 0.12),
    );

    // Progress arc
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect,
        rotation - math.pi / 2,
        progress * 2 * math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    // Rotating particle
    final angle = rotation - math.pi / 2;
    final px = center.dx + math.cos(angle) * radius;
    final py = center.dy + math.sin(angle) * radius;
    canvas.drawCircle(
      Offset(px, py),
      5,
      Paint()
        ..color = color.withValues(alpha: 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.rotation != rotation;
}

// ═══════════════════════════════════════════════════════════════════════════
// C — SECTION HEADER
// ═══════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: Icon(icon, color: color, size: 12),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.85),
              fontSize: 10,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.3),
                    color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// F — SHARE FAB
// ═══════════════════════════════════════════════════════════════════════════

class _ShareFab extends StatefulWidget {
  final VoidCallback onTap;
  const _ShareFab({required this.onTap});

  @override
  State<_ShareFab> createState() => _ShareFabState();
}

class _ShareFabState extends State<_ShareFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _expanded = !_expanded);
        if (_expanded) _c.forward(); else _c.reverse();
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.08),
              Colors.white.withValues(alpha: 0.04),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.ios_share,
              color: Colors.white.withValues(alpha: 0.7),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'TEILEN',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// THREAD STATE
// ═══════════════════════════════════════════════════════════════════════════

class _ThreadState {
  final String topic;
  bool disposed = false;

  // B — Loading-Overlay
  bool showLoadingOverlay = true;
  int loadedApiCount = 0;

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

  // ── Mindblow-Tier ──────────────────────────────────────────────────────
  List<UsaSpendingAward> usaSpending = const [];
  bool usaSpendingLoading = true;

  List<WorldBankProject> worldBank = const [];
  bool worldBankLoading = true;

  List<OpenOwnershipEntity> openOwnership = const [];
  bool openOwnershipLoading = true;

  List<OpenSpendingEntry> openSpending = const [];
  bool openSpendingLoading = true;

  List<CourtListenerCase> courtListener = const [];
  bool courtListenerLoading = true;

  List<MuckRockFoia> muckRock = const [];
  bool muckRockLoading = true;

  List<HudocCase> hudoc = const [];
  bool hudocLoading = true;

  List<EuCuriaCase> euCuria = const [];
  bool euCuriaLoading = true;

  List<OpenSecretsOrg> openSecrets = const [];
  bool openSecretsLoading = true;

  List<FecCandidate> fec = const [];
  bool fecLoading = true;

  List<LittleSisEntity> littleSis = const [];
  bool littleSisLoading = true;

  List<EveryPolitician> everyPolitician = const [];
  bool everyPoliticianLoading = true;

  List<DocumentCloudDoc> documentCloud = const [];
  bool documentCloudLoading = true;

  List<WikiLeaksDoc> wikiLeaks = const [];
  bool wikiLeaksLoading = true;

  List<CiaCrestDoc> ciaCrest = const [];
  bool ciaCrestLoading = true;

  List<SnowdenDoc> snowden = const [];
  bool snowdenLoading = true;

  List<OcNetworkOfficer> ocNetwork = const [];
  bool ocNetworkLoading = true;

  List<CorpWatchArticle> corpWatch = const [];
  bool corpWatchLoading = true;

  // ── Extra fields used by Deep-API layer ────────────────────────────────────
  String? propagandaAnalysis;
  bool propagandaLoading = true;

  List<KeyPerson> keyPersons = const [];
  bool keyPersonsLoading = true;

  List<LobbyEntry> lobbyEntries = const [];
  bool lobbyLoading = true;

  List<Abgeordneter> abgeordnete = const [];
  bool abgeordneteLoading = true;

  List<Skandal> skandale = const [];
  bool skandaleLoading = true;

  List<OffshoreEntity> offshoreEntities = const [];
  bool offshoreLoading = true;

  List<CompanyEntry> companies = const [];
  bool companiesLoading = true;

  List<SanctionResult> openSanctions = const [];
  bool openSanctionsLoading = true;

  List<AlephDocument> alephDocs = const [];
  bool alephLoading = true;

  List<PubMedPaper> pubmedPapers = const [];
  bool pubmedLoading = true;

  List<SemanticPaper> semanticPapers = const [];
  bool semanticLoading = true;

  List<ArchiveDoc> archiveDocs = const [];
  bool archiveLoading = true;

  List<EuVote> euVotes = const [];
  bool euVotesLoading = true;

  _ThreadState({required this.topic});
}

// ═══════════════════════════════════════════════════════════════════════════
// STAGGERED CARD ANIMATION
// ═══════════════════════════════════════════════════════════════════════════

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
