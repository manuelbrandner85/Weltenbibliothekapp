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

import 'cards/ai_insight_card.dart';
import 'cards/identity_card.dart';
import 'cards/network_card.dart';
import 'cards/related_paths_card.dart';
import 'cards/sources_card.dart';
import 'cards/timeline_card.dart';
import 'models/thread.dart';
import 'services/kaninchenbau_service.dart';
import 'widgets/breadcrumb_bar.dart';
import 'widgets/cinematic_intro.dart';
import 'widgets/kb_design.dart';
import 'widgets/rote_faden_line.dart';
import 'widgets/virgil_orb.dart';

class KaninchenbauScreen extends StatefulWidget {
  /// Optional vorausgewähltes Thema (z.B. von einem Tool-Button).
  final String? initialTopic;

  const KaninchenbauScreen({super.key, this.initialTopic});

  @override
  State<KaninchenbauScreen> createState() => _KaninchenbauScreenState();
}

class _KaninchenbauScreenState extends State<KaninchenbauScreen> {
  final _service = KaninchenbauService();
  final _scroll = ScrollController();
  final List<_ThreadState> _stack = [];

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

    // Network
    _service.fetchNetworkNodes(s.topic).then((nodes) {
      if (!mounted || s.disposed) return;
      setState(() {
        s.networkNodes = nodes;
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
            ),
            Expanded(
              child: _buildScrollContent(s),
            ),
          ],
        ),
        // Virgil-Orb unten rechts
        Positioned(
          right: 18,
          bottom: 18,
          child: VirgilOrb(
            insight: s.aiInsight,
            thinking: s.aiLoading,
          ),
        ),
      ],
    );
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
                      loading: s.networkLoading,
                      onTapNode: _openThread,
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
                    delay: const Duration(milliseconds: 600),
                    child: TimelineCard(
                      entries: s.timelineEntries,
                      loading: s.timelineLoading,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StaggeredCard(
                    delay: const Duration(milliseconds: 750),
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
  bool networkLoading = true;

  List<SourceItem> sources = const [];
  bool sourcesLoading = true;

  List<TimelineEntry> timelineEntries = const [];
  bool timelineLoading = true;

  List<String> relatedTopics = const [];
  bool relatedLoading = true;

  String? aiInsight;
  bool aiLoading = true;

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
