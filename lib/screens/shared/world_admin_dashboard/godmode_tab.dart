// God Mode: Root-Admin Entwickler-Konsole.
// part of world_admin_dashboard library.
part of '../world_admin_dashboard.dart';

// ═══════════════════════════════════════════════════════════════════════════
// GOD MODE -- Root-Admin Entwickler-Konsole
// ---------------------------------------------------------------------------
// Erlaubt dem Root-Admin, beliebige App-Aenderungen direkt aus der App heraus
// zu beauftragen: UI/UX, Features, Module, Bugfixes, Performance.
// Vier Tabs:
//   Chat    -- konversationaler Auftrag (wie Claude), Bestaetigung per Ja/Nein
//   KI-Ideen-- proaktive Vorschlaege mit Typ-Badge (Bug/Neuerung/...) + Warum
//   Bereiche-- selbstgelernte + manuelle Themen, zu denen die KI vorschlaegt
//   Status  -- Live-Liste aller Auftraege mit Typ + Issue/PR-Links
// Jeder Auftrag -> GitHub-Issue (Label "godmode") -> claude_godmode.yml baut
// autonom -> Verify-Gate (bei rot: Auto-Fix) -> Auto-Merge -> OTA. Nur Root-Admin.
// ═══════════════════════════════════════════════════════════════════════════

class _GodModeTab extends StatefulWidget {
  final Color accent;
  final Color accentBright;
  const _GodModeTab({required this.accent, required this.accentBright});

  @override
  State<_GodModeTab> createState() => _GodModeTabState();
}

class _GodModeTabState extends State<_GodModeTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tc;

  // Chat state
  final _chatCtrl = TextEditingController();
  final _chatScroll = ScrollController();
  final List<GodModeChatMessage> _chat = [];
  bool _chatBusy = false;
  GodModeReadyOrder? _pendingOrder;

  // Suggestions state
  List<GodModeSuggestion> _suggestions = const [];
  List<String> _learnedFromLast = const [];
  String? _suggestArea;
  bool _suggesting = false;

  // Topics state
  List<GodModeTopic> _topics = const [];
  bool _loadingTopics = true;
  final _topicCtrl = TextEditingController();

  // Requests state
  List<GodModeRequest> _requests = const [];
  bool _loadingReqs = true;
  bool _submitting = false;

  // Locally dismissed suggestions by title (robust gegen Re-Sort/Mehr-laden).
  final Set<String> _dismissedTitles = {};
  // F4: KI-Quelle des letzten Laufs (groq/openrouter/gemini/workers-ai/fallback).
  String _lastSource = '';
  // N4: aktiver Typ-Filter (slug) | 'saved' | null = alle.
  String? _typeFilter;
  // I3: optionaler Welt-Fokus (materie|energie|vorhang|ursprung) | null.
  String? _world;
  // C6: Multi-Modell-Voting beim Generieren.
  bool _vote = false;
  // I1: mehrfach ausgewaehlte Vorschlaege (per Titel) fuer Sammel-Bauen.
  final Set<String> _selectedTitles = {};
  // S2: Status-Filter im Status-Tab (null=alle | open | done | failed).
  String? _reqFilter;
  // N3: lokal gemerkte Vorschlaege (per Titel, nicht persistiert).
  final Set<String> _savedTitles = {};
  bool _loadingMore = false;

  // C3: Voice-Input fuer den Chat.
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechReady = false;

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }
    if (!_speechReady) {
      _speechReady = await _speech.initialize(
        onStatus: (s) {
          if ((s == 'done' || s == 'notListening') && mounted) {
            setState(() => _isListening = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _isListening = false);
        },
      );
      if (!_speechReady) {
        _snack('Mikrofon nicht verfuegbar oder Berechtigung fehlt.',
            color: Colors.orange);
        return;
      }
    }
    setState(() => _isListening = true);
    await _speech.listen(
      localeId: 'de_DE',
      onResult: (result) {
        if (!mounted) return;
        final base = _chatCtrl.text;
        final t = result.recognizedWords;
        _chatCtrl.text =
            base.isEmpty ? t : (result.finalResult ? '$base $t' : base);
        _chatCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _chatCtrl.text.length),
        );
        if (result.finalResult) setState(() => _isListening = false);
      },
      listenFor: const Duration(seconds: 30),
    );
  }

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 5, vsync: this);
    _loadRequests();
    _loadTopics();
    _loadRepo(); // A1: Live-Repo-Insights
    _loadPersisted(); // C1/I2: Chat + Gemerkt aus letztem Mal wiederherstellen
  }

  // A1: Repo-Insights laden.
  GodModeRepoInsights _repo = GodModeRepoInsights.empty;
  bool _loadingRepo = true;

  Future<void> _loadRepo() async {
    setState(() => _loadingRepo = true);
    final r = await GodModeService.repoInsights();
    if (!mounted) return;
    setState(() {
      _repo = r;
      _loadingRepo = false;
    });
  }

  // ── C1/I2: lokale Persistenz (SharedPreferences) ──────────────────────────
  static const _kSavedKey = 'godmode_saved_v1';
  static const _kChatKey = 'godmode_chat_v1';

  Future<void> _loadPersisted() async {
    try {
      final p = await SharedPreferences.getInstance();
      final saved = p.getStringList(_kSavedKey) ?? const [];
      final chatRaw = p.getString(_kChatKey);
      final restored = <GodModeChatMessage>[];
      if (chatRaw != null && chatRaw.isNotEmpty) {
        final list = jsonDecode(chatRaw);
        if (list is List) {
          for (final e in list) {
            if (e is Map && e['role'] is String && e['content'] is String) {
              restored.add(GodModeChatMessage(
                  e['role'] as String, e['content'] as String));
            }
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _savedTitles
          ..clear()
          ..addAll(saved);
        if (restored.isNotEmpty) {
          _chat
            ..clear()
            ..addAll(restored);
        }
      });
    } catch (_) {/* ignore */}
  }

  Future<void> _persistSaved() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList(_kSavedKey, _savedTitles.toList());
    } catch (_) {}
  }

  Future<void> _persistChat() async {
    try {
      final p = await SharedPreferences.getInstance();
      // Nur die letzten 40 Nachrichten sichern.
      final tail = _chat.length > 40 ? _chat.sublist(_chat.length - 40) : _chat;
      await p.setString(
          _kChatKey, jsonEncode(tail.map((m) => m.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _clearChat() async {
    setState(() {
      _chat.clear();
      _pendingOrder = null;
    });
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_kChatKey);
    } catch (_) {}
  }

  void _toggleSaved(String title) {
    setState(() {
      if (_savedTitles.contains(title)) {
        _savedTitles.remove(title);
      } else {
        _savedTitles.add(title);
      }
    });
    _persistSaved();
  }

  @override
  void dispose() {
    _tc.dispose();
    _chatCtrl.dispose();
    _chatScroll.dispose();
    _topicCtrl.dispose();
    super.dispose();
  }

  Color get _a => widget.accent;
  Color get _ab => widget.accentBright;

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color ?? const Color(0xFF1A1A2E),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
    ));
  }

  // ───────────────────────────────────────────────────── data loaders
  Future<void> _loadRequests() async {
    setState(() => _loadingReqs = true);
    final list = await GodModeService.listRequests();
    if (!mounted) return;
    setState(() {
      _requests = list;
      _loadingReqs = false;
    });
  }

  Future<void> _loadTopics() async {
    setState(() => _loadingTopics = true);
    final list = await GodModeService.listTopics();
    if (!mounted) return;
    setState(() {
      _topics = list;
      _loadingTopics = false;
    });
  }

  Future<void> _generateSuggestions() async {
    setState(() {
      _suggesting = true;
      _suggestions = const [];
      _dismissedTitles.clear();
    });
    final res = await GodModeService.suggest(
        area: _suggestArea, world: _world, vote: _vote);
    if (!mounted) return;
    // N2: Quick-Wins zuerst (hoher Nutzen, niedriger Aufwand).
    final sorted = [...res.suggestions]
      ..sort((a, b) => b.score.compareTo(a.score));
    setState(() {
      _suggestions = sorted;
      _learnedFromLast = res.learnedTopics;
      _lastSource = res.source;
      _suggesting = false;
    });
    if (res.suggestions.isEmpty) {
      _snack('Keine Vorschlaege -- spaeter erneut versuchen',
          color: Colors.orange);
    }
    if (res.learnedTopics.isNotEmpty) _loadTopics();
  }

  // N3: weitere Vorschlaege nachladen und (ohne Duplikate) anhaengen.
  Future<void> _loadMore() async {
    if (_loadingMore || _suggesting) return;
    setState(() => _loadingMore = true);
    final res = await GodModeService.suggest(
        area: _suggestArea, world: _world, vote: _vote);
    if (!mounted) return;
    final existing = _suggestions.map((s) => s.title).toSet();
    final merged = [
      ..._suggestions,
      ...res.suggestions.where((s) => !existing.contains(s.title)),
    ]..sort((a, b) => b.score.compareTo(a.score));
    setState(() {
      _suggestions = merged;
      if (res.source.isNotEmpty) _lastSource = res.source;
      if (res.learnedTopics.isNotEmpty) _learnedFromLast = res.learnedTopics;
      _loadingMore = false;
    });
  }

  // ───────────────────────────────────────────────────── chat
  void _scrollChatDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendChat() async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty || _chatBusy) return;
    setState(() {
      _chat.add(GodModeChatMessage('user', text));
      _chatCtrl.clear();
      _chatBusy = true;
      _pendingOrder = null;
    });
    _scrollChatDown();

    final reply = await GodModeService.chat(_chat);
    if (!mounted) return;
    setState(() {
      _chatBusy = false;
      if (reply.message.isNotEmpty) {
        _chat.add(GodModeChatMessage('assistant', reply.message));
      }
      _pendingOrder = reply.readyToSubmit;
    });
    _persistChat(); // C1
    _scrollChatDown();
  }

  Future<void> _confirmPendingOrder() async {
    final o = _pendingOrder;
    if (o == null) return;
    // E: auch der Chat-Auftrag ist vor dem Bauen editierbar.
    setState(() => _pendingOrder = null);
    await _editAndBuild(
      category: o.category,
      type: o.type,
      title: o.title,
      description: o.description,
      source: 'chat',
    );
  }

  void _declinePendingOrder() {
    setState(() {
      _pendingOrder = null;
      _chat.add(const GodModeChatMessage('user', 'Nein, bitte anpassen.'));
    });
    _sendChatFollowUp();
  }

  Future<void> _sendChatFollowUp() async {
    setState(() => _chatBusy = true);
    final reply = await GodModeService.chat(_chat);
    if (!mounted) return;
    setState(() {
      _chatBusy = false;
      if (reply.message.isNotEmpty) {
        _chat.add(GodModeChatMessage('assistant', reply.message));
      }
      _pendingOrder = reply.readyToSubmit;
    });
    _scrollChatDown();
  }

  // ───────────────────────────────────────────────────── submit (KI-Idee)
  // E: jeder Vorschlag laeuft jetzt durch ein Bearbeiten-Sheet -- Titel +
  // Prompt sind editierbar, bevor Claude baut.
  Future<void> _submitSuggestion(GodModeSuggestion s) => _editAndBuild(
        category: s.category,
        type: s.type,
        title: s.title,
        description: s.reason.isEmpty
            ? s.description
            : '${s.description}\n\nWarum: ${s.reason}',
        source: 'ai_suggestion',
      );

  // Low-level: Auftrag direkt absetzen (nach Bearbeiten).
  Future<void> _submitRaw({
    required String category,
    required String type,
    required String title,
    required String description,
    required String source,
  }) async {
    setState(() => _submitting = true);
    final res = await GodModeService.submit(
      category: category,
      type: type,
      title: title,
      description: description,
      source: source,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.success) {
      _snack('Auftrag #${res.issueNumber} angelegt -- Claude baut autonom.',
          color: Colors.green.shade700);
      _loadRequests();
      _tc.animateTo(3);
    } else {
      _snack(res.message, color: Colors.red.shade700);
    }
  }

  // I1: alle ausgewaehlten Vorschlaege nacheinander absetzen.
  Widget _buildBatchBuildBar() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _submitting ? null : _buildSelected,
        icon: const Icon(Icons.playlist_add_check_rounded, size: 16),
        label: Text('${_selectedTitles.length} ausgewaehlte bauen lassen'),
        style: FilledButton.styleFrom(
          backgroundColor: _a.withValues(alpha: 0.3),
          foregroundColor: _ab,
          padding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }

  Future<void> _buildSelected() async {
    final picked =
        _suggestions.where((s) => _selectedTitles.contains(s.title)).toList();
    if (picked.isEmpty) return;
    setState(() => _submitting = true);
    var ok = 0;
    for (final s in picked) {
      final res = await GodModeService.submit(
        category: s.category,
        type: s.type,
        title: s.title,
        description: s.reason.isEmpty
            ? s.description
            : '${s.description}\n\nWarum: ${s.reason}',
        source: 'ai_suggestion',
      );
      if (res.success) ok++;
    }
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _selectedTitles.clear();
    });
    _snack('$ok/${picked.length} Auftraege angelegt.',
        color: ok > 0 ? Colors.green.shade700 : Colors.red.shade700);
    if (ok > 0) {
      _loadRequests();
      _tc.animateTo(3);
    }
  }

  // G1: Umsetzungs-Plan-Vorschau (Dateien/Schritte/Risiken/Aufwand) vor dem Bauen.
  Future<void> _showPlan(GodModeSuggestion s) async {
    final desc = s.reason.isEmpty
        ? s.description
        : '${s.description}\n\nWarum: ${s.reason}';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12121E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (ctx, scroll) => Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<String>(
            future: GodModeService.plan(title: s.title, description: desc),
            builder: (ctx, snap) {
              return ListView(
                controller: scroll,
                children: [
                  Row(children: [
                    Icon(Icons.account_tree_rounded, size: 18, color: _ab),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Umsetzungsplan',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(s.title,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 14),
                  if (snap.connectionState != ConnectionState.done)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    SelectableText(
                      (snap.data ?? '').isEmpty
                          ? 'Kein Plan erhalten -- spaeter erneut.'
                          : snap.data!,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13, height: 1.5),
                    ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // E: Bearbeiten-Sheet -- Titel + Prompt (das, was Claude baut) editierbar.
  Future<void> _editAndBuild({
    required String category,
    required String type,
    required String title,
    required String description,
    required String source,
  }) async {
    final titleCtrl = TextEditingController(text: title);
    final descCtrl = TextEditingController(text: description);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12121E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.edit_rounded, size: 18, color: _ab),
              const SizedBox(width: 8),
              const Text('Auftrag bearbeiten',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 4),
            const Text('Passe den Prompt an -- genau das setzt Claude um.',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: _editDecoration('Titel'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              minLines: 4,
              maxLines: 10,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, height: 1.4),
              decoration: _editDecoration('Prompt / Beschreibung'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  final t = titleCtrl.text.trim();
                  final d = descCtrl.text.trim();
                  if (t.isEmpty || d.isEmpty) return;
                  Navigator.of(ctx).pop();
                  _submitRaw(
                    category: category,
                    type: type,
                    title: t,
                    description: d,
                    source: source,
                  );
                },
                icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                label: const Text('Bauen lassen'),
                style: FilledButton.styleFrom(
                  backgroundColor: _a.withValues(alpha: 0.3),
                  foregroundColor: _ab,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    titleCtrl.dispose();
    descCtrl.dispose();
  }

  InputDecoration _editDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ───────────────────────────────────────────────────────── build
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildHeader(),
      TabBar(
        controller: _tc,
        isScrollable: true,
        labelColor: _ab,
        unselectedLabelColor: Colors.white38,
        indicatorColor: _ab,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: const [
          Tab(icon: Icon(Icons.forum_rounded, size: 18), text: 'Chat'),
          Tab(
              icon: Icon(Icons.auto_awesome_rounded, size: 18),
              text: 'KI-Ideen'),
          Tab(icon: Icon(Icons.category_rounded, size: 18), text: 'Bereiche'),
          Tab(icon: Icon(Icons.list_alt_rounded, size: 18), text: 'Status'),
          Tab(icon: Icon(Icons.hub_rounded, size: 18), text: 'Repo'),
        ],
      ),
      Expanded(
        child: TabBarView(
          controller: _tc,
          children: [
            _buildChatTab(),
            _buildSuggestTab(),
            _buildTopicsTab(),
            _buildStatusTab(),
            _buildRepoTab(),
          ],
        ),
      ),
    ]);
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_a.withValues(alpha: 0.22), Colors.transparent],
        ),
        border: Border(bottom: BorderSide(color: _a.withValues(alpha: 0.2))),
      ),
      child: Row(children: [
        Icon(Icons.auto_fix_high_rounded, color: _ab, size: 22),
        const SizedBox(width: 10),
        const Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'GOD MODE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.5,
              ),
            ),
            Text(
              'App aus der App heraus entwickeln -- Claude baut autonom',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _a.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'ROOT ONLY',
            style: TextStyle(
                color: _ab,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2),
          ),
        ),
      ]),
    );
  }

  // ─────────────── Tab 1: Chat ──────────────────────────────────────────────
  Widget _buildChatTab() {
    return Column(children: [
      if (_chat.isNotEmpty)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _clearChat,
            icon: const Icon(Icons.delete_outline_rounded, size: 15),
            label:
                const Text('Verlauf loeschen', style: TextStyle(fontSize: 11)),
            style: TextButton.styleFrom(foregroundColor: Colors.white38),
          ),
        ),
      Expanded(
        child: _chat.isEmpty
            ? _buildChatEmpty()
            : ListView.builder(
                controller: _chatScroll,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                itemCount: _chat.length + (_chatBusy ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i >= _chat.length) return _buildTypingBubble();
                  return _buildChatBubble(_chat[i]);
                },
              ),
      ),
      if (_pendingOrder != null) _buildConfirmCard(_pendingOrder!),
      _buildChatInput(),
    ]);
  }

  Widget _buildChatEmpty() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoBox(
          'Beschreib einfach was du brauchst -- wie ein Chat mit Claude. '
          'Der Assistent stellt Rueckfragen, formuliert den Auftrag und fragt '
          'dich um Bestaetigung. Erst wenn du "Ja" tippst, wird gebaut.',
        ),
        const SizedBox(height: 18),
        Center(
          child: Icon(Icons.forum_rounded,
              size: 54, color: _a.withValues(alpha: 0.3)),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'z.B. "Die Energie-Welt braucht einen Atem-Timer"\n'
            'oder "Der Login haengt manchmal -- bitte pruefen"',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: Colors.white38, fontSize: 12.5, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(GodModeChatMessage m) {
    final isUser = m.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? _a.withValues(alpha: 0.30) : const Color(0xFF15151F),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
          ),
          border: Border.all(
              color: isUser ? _a.withValues(alpha: 0.4) : Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.auto_fix_high_rounded, size: 12, color: _ab),
                  const SizedBox(width: 5),
                  Text('Assistent',
                      style: TextStyle(
                          color: _ab,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ]),
              ),
            Text(m.content,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13.5, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF15151F),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: _ab)),
          const SizedBox(width: 10),
          const Text('denkt nach ...',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildConfirmCard(GodModeReadyOrder o) {
    final t = GodModeType.forSlug(o.type);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _a.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _ab.withValues(alpha: 0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _typeBadge(t),
          const SizedBox(width: 6),
          _miniBadge(GodModeCategory.labelFor(o.category), Colors.white24),
        ]),
        const SizedBox(height: 8),
        Text(o.title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
        if (o.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(o.description,
              style: const TextStyle(
                  color: Colors.white60, fontSize: 12.5, height: 1.4)),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _submitting ? null : _declinePendingOrder,
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('Nein, anpassen'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _confirmPendingOrder,
              icon: _submitting
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.rocket_launch_rounded, size: 16),
              label: Text(_submitting ? 'Setze ab ...' : 'Ja, bauen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _a,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E16),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (_chat.isEmpty) _buildQuickPrompts(),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _chatCtrl,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendChat(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Auftrag beschreiben ...',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // C3: Voice-Input
          GestureDetector(
            onTap: _toggleVoiceInput,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isListening
                    ? Colors.redAccent.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none_rounded,
                color: _isListening ? Colors.white : Colors.white60,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _chatBusy ? null : _sendChat,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _chatBusy ? Colors.white12 : _a,
                shape: BoxShape.circle,
              ),
              child: Icon(
                  _chatBusy
                      ? Icons.hourglass_empty_rounded
                      : Icons.send_rounded,
                  color: Colors.white,
                  size: 20),
            ),
          ),
        ]),
      ]),
    );
  }

  // C2: Quick-Prompts -- fuellen das Eingabefeld vor (nur wenn Chat leer).
  Widget _buildQuickPrompts() {
    const prompts = <(String, String)>[
      ('🐞 Bug melden', 'Es gibt einen Bug: '),
      ('✨ Feature', 'Neues Feature: '),
      ('⚡ Performance', 'Performance-Problem: '),
      ('🎨 UI/UX', 'UI/UX verbessern: '),
    ];
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 30,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 8),
          children: prompts.map((p) {
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () {
                  _chatCtrl.text = p.$2;
                  _chatCtrl.selection = TextSelection.fromPosition(
                    TextPosition(offset: _chatCtrl.text.length),
                  );
                  setState(() {});
                },
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(p.$1,
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 11)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─────────────── Tab 2: KI-Ideen ─────────────────────────────────────────
  Widget _buildSuggestTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoBox(
          'Die KI analysiert die App und schlaegt konkrete Massnahmen vor -- '
          'jede markiert als Bug, Neuerung, Erweiterung, Verbesserung, Performance '
          'oder UX, immer mit einer Begruendung WARUM.',
        ),
        const SizedBox(height: 14),
        _buildAreaFilter(),
        const SizedBox(height: 8),
        _buildWorldFilter(),
        const SizedBox(height: 10),
        // C6: Voting-Toggle (2 Modelle + Judge -> beste 5).
        GestureDetector(
          onTap: () => setState(() => _vote = !_vote),
          child: Row(children: [
            Icon(
              _vote ? Icons.how_to_vote_rounded : Icons.how_to_vote_outlined,
              size: 16,
              color: _vote ? _ab : Colors.white38,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Multi-Modell-Voting (2 KIs + Judge, langsamer, bessere Auswahl)',
                style: TextStyle(
                    color: _vote ? _ab : Colors.white54, fontSize: 11.5),
              ),
            ),
            Switch(
              value: _vote,
              onChanged: (v) => setState(() => _vote = v),
              activeColor: _ab,
            ),
          ]),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _suggesting ? null : _generateSuggestions,
            icon: _suggesting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.auto_awesome_rounded, size: 18, color: _ab),
            label: Text(
              _suggesting ? 'KI denkt nach ...' : 'Vorschlaege generieren',
              style: TextStyle(color: _ab, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: _a.withValues(alpha: 0.6)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (_learnedFromLast.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildLearnedBanner(),
        ],
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSourceBadge(),
          const SizedBox(height: 10),
          _buildTypeFilter(),
          if (_selectedTitles.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildBatchBuildBar(),
          ],
        ],
        if (_suggestions.isEmpty && !_suggesting)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                'Noch keine Vorschlaege -- oben "Generieren" tippen.',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
          ),
        ..._visibleSuggestions().map(_buildSuggestionCard),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildLoadMore(),
        ],
      ],
    );
  }

  // Sichtbare Vorschlaege nach Dismiss + Typ/Gemerkt-Filter (N4).
  List<GodModeSuggestion> _visibleSuggestions() {
    return _suggestions.where((s) {
      if (_dismissedTitles.contains(s.title)) return false;
      if (_typeFilter == 'saved') return _savedTitles.contains(s.title);
      if (_typeFilter != null) return s.type == _typeFilter;
      return true;
    }).toList();
  }

  // F4: zeigt, ob echte KI geantwortet hat oder der Standard-Fallback griff.
  Widget _buildSourceBadge() {
    final ai = _lastSource.isNotEmpty && _lastSource != 'fallback';
    final color = ai ? Colors.tealAccent : Colors.orangeAccent;
    final label = ai
        ? 'KI aktiv ($_lastSource)'
        : 'Standard-Vorschlaege (KI nicht erreichbar)';
    return Row(children: [
      Icon(ai ? Icons.smart_toy_rounded : Icons.warning_amber_rounded,
          size: 14, color: color),
      const SizedBox(width: 6),
      Expanded(
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w500)),
      ),
    ]);
  }

  // N4: Filter nach Massnahmen-Typ + "Gemerkt".
  Widget _buildTypeFilter() {
    final chips = <(String?, String)>[
      (null, 'Alle'),
      ...GodModeType.all.map((t) => (t.slug, '${t.emoji} ${t.label}')),
      ('saved', '★ Gemerkt'),
    ];
    return SizedBox(
      height: 30,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: chips.map((c) {
          final sel = c.$1 == _typeFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _typeFilter = c.$1),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: sel
                      ? _ab.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sel ? _ab : Colors.white12),
                ),
                child: Text(c.$2,
                    style: TextStyle(
                        color: sel ? _ab : Colors.white54, fontSize: 11)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // N3: weitere Vorschlaege nachladen.
  Widget _buildLoadMore() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: (_loadingMore || _suggesting) ? null : _loadMore,
        icon: _loadingMore
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(Icons.add_rounded, size: 16, color: _ab),
        label: Text(_loadingMore ? 'Laedt ...' : 'Mehr laden',
            style: TextStyle(color: _ab, fontSize: 12)),
      ),
    );
  }

  Widget _buildLearnedBanner() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.tealAccent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.school_rounded, size: 14, color: Colors.tealAccent),
          const SizedBox(width: 6),
          const Text('NEU GELERNTE BEREICHE',
              style: TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
        ]),
        const SizedBox(height: 8),
        Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _learnedFromLast.map((t) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(t,
                    style: const TextStyle(
                        color: Colors.tealAccent, fontSize: 11)),
              );
            }).toList()),
      ]),
    );
  }

  // I3: Welt-Fokus -- schraenkt die Vorschlaege auf eine Welt ein.
  Widget _buildWorldFilter() {
    const worlds = <(String?, String)>[
      (null, '🌐 Alle Welten'),
      ('materie', '🔵 Materie'),
      ('energie', '🟣 Energie'),
      ('vorhang', '🟡 Vorhang'),
      ('ursprung', '🟢 Ursprung'),
    ];
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: worlds.map((e) {
          final sel = e.$1 == _world;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _world = e.$1);
                _generateSuggestions(); // F3: sofort neu
              },
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: sel
                      ? _ab.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sel ? _ab : Colors.white12),
                ),
                child: Text(e.$2,
                    style: TextStyle(
                        color: sel ? _ab : Colors.white54, fontSize: 11.5)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAreaFilter() {
    final entries = <(String?, String)>[
      (null, 'Gemischt'),
      ...GodModeCategory.all.map((c) => (c.label, c.label)),
      ..._topics.map((t) => (t.label, t.label)),
    ];
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: entries.map((e) {
          final sel = e.$1 == _suggestArea;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _suggestArea = e.$1);
                _generateSuggestions(); // F3: Filterwechsel -> sofort neu
              },
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: sel
                      ? _ab.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sel ? _ab : Colors.white12),
                ),
                child: Text(e.$2,
                    style: TextStyle(
                        color: sel ? _ab : Colors.white54, fontSize: 11.5)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSuggestionCard(GodModeSuggestion s) {
    final t = s.typeInfo;
    final saved = _savedTitles.contains(s.title);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(t.colorValue).withValues(alpha: 0.30)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _typeBadge(t),
          const SizedBox(width: 6),
          _miniBadge(s.categoryLabel, Colors.white24),
          const Spacer(),
          // I1: Mehrfachauswahl fuer Sammel-Bauen.
          GestureDetector(
            onTap: () => setState(() {
              if (_selectedTitles.contains(s.title)) {
                _selectedTitles.remove(s.title);
              } else {
                _selectedTitles.add(s.title);
              }
            }),
            child: Icon(
              _selectedTitles.contains(s.title)
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 18,
              color: _selectedTitles.contains(s.title) ? _ab : Colors.white30,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _toggleSaved(s.title),
            child: Icon(
              saved ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 18,
              color: saved ? Colors.amber : Colors.white30,
            ),
          ),
        ]),
        const SizedBox(height: 6),
        // N2: Nutzen/Aufwand-Bewertung.
        Row(children: [
          _miniBadge('Nutzen ${s.impact}/5',
              Colors.greenAccent.withValues(alpha: 0.45)),
          const SizedBox(width: 6),
          _miniBadge('Aufwand ${s.effort}/5',
              Colors.orangeAccent.withValues(alpha: 0.45)),
        ]),
        const SizedBox(height: 9),
        Text(s.title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        Text(s.description,
            style: const TextStyle(
                color: Colors.white60, fontSize: 12.5, height: 1.45)),
        if (s.reason.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(9),
              border: Border(
                  left: BorderSide(color: Color(t.colorValue), width: 2.5)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  size: 13, color: Colors.amberAccent),
              const SizedBox(width: 7),
              Expanded(
                child: RichText(
                    text: TextSpan(children: [
                  const TextSpan(
                      text: 'Warum: ',
                      style: TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold)),
                  TextSpan(
                      text: s.reason,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11.5, height: 1.4)),
                ])),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _showPlan(s),
            icon: const Icon(Icons.account_tree_outlined, size: 14),
            label: const Text('Plan ansehen', style: TextStyle(fontSize: 11.5)),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white54,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _dismissedTitles.add(s.title)),
              icon: const Icon(Icons.close_rounded, size: 15),
              label: const Text('Ablehnen', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white38,
                side: const BorderSide(color: Colors.white12),
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: _submitting ? null : () => _submitSuggestion(s),
              icon: const Icon(Icons.rocket_launch_rounded, size: 15),
              label: const Text('Bauen lassen', style: TextStyle(fontSize: 12)),
              style: FilledButton.styleFrom(
                backgroundColor: _a.withValues(alpha: 0.25),
                foregroundColor: _ab,
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  // ─────────────── Tab 3: Bereiche ──────────────────────────────────────────
  Widget _buildTopicsTab() {
    return RefreshIndicator(
      color: _ab,
      backgroundColor: const Color(0xFF12121E),
      onRefresh: _loadTopics,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoBox(
            'Die KI lernt mit der Zeit selbststaendig neue App-Bereiche und traegt '
            'sie hier ein. Zu jedem Bereich bekommst du gezielte Vorschlaege '
            '(im KI-Ideen-Tab als Filter). Du kannst auch eigene Bereiche anlegen.',
          ),
          const SizedBox(height: 14),
          _card(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel(
                  Icons.add_circle_outline_rounded, 'EIGENEN BEREICH ANLEGEN'),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _topicCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration:
                        _inputDeco('Bereichsname', 'z.B. Audio-Meditationen'),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addTopic,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _a,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  child: const Icon(Icons.add_rounded, size: 20),
                ),
              ]),
            ],
          )),
          const SizedBox(height: 16),
          _sectionLabel(Icons.category_rounded, 'BEKANNTE BEREICHE'),
          const SizedBox(height: 10),
          if (_loadingTopics)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_topics.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Noch keine Bereiche -- generiere KI-Ideen,\ndann lernt die KI automatisch dazu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white38, fontSize: 12.5, height: 1.5),
                ),
              ),
            )
          else
            ..._topics.map(_buildTopicTile),
        ],
      ),
    );
  }

  Widget _buildTopicTile(GodModeTopic t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.fromLTRB(13, 11, 8, 11),
      decoration: BoxDecoration(
        color: const Color(0xFF12121E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(children: [
        Text(t.isAi ? '🧠' : '👤', style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              t.isAi
                  ? 'Selbst gelernt  ·  ${t.hitCount}x vorgeschlagen'
                  : 'Manuell angelegt',
              style: const TextStyle(color: Colors.white38, fontSize: 10.5),
            ),
          ]),
        ),
        IconButton(
          tooltip: 'Vorschlaege zu diesem Bereich',
          icon: Icon(Icons.auto_awesome_rounded, size: 18, color: _ab),
          onPressed: () {
            setState(() => _suggestArea = t.label);
            _tc.animateTo(1);
            _generateSuggestions();
          },
        ),
        IconButton(
          tooltip: 'Archivieren',
          icon: const Icon(Icons.archive_outlined,
              size: 17, color: Colors.white30),
          onPressed: () => _archiveTopic(t),
        ),
        // B1: umbenennen / zusammenfuehren.
        PopupMenuButton<String>(
          tooltip: 'Mehr',
          icon: const Icon(Icons.more_vert_rounded,
              size: 17, color: Colors.white30),
          color: const Color(0xFF1A1A2E),
          onSelected: (v) {
            if (v == 'rename') {
              _renameTopic(t);
            } else if (v == 'merge') {
              _mergeTopic(t);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
                value: 'rename',
                child: Text('Umbenennen',
                    style: TextStyle(color: Colors.white, fontSize: 13))),
            PopupMenuItem(
                value: 'merge',
                child: Text('Zusammenfuehren',
                    style: TextStyle(color: Colors.white, fontSize: 13))),
          ],
        ),
      ]),
    );
  }

  Future<void> _addTopic() async {
    final label = _topicCtrl.text.trim();
    if (label.isEmpty) return;
    final ok = await GodModeService.addTopic(label);
    if (!mounted) return;
    if (ok) {
      _topicCtrl.clear();
      _snack('Bereich "$label" angelegt.', color: Colors.green.shade700);
      _loadTopics();
    } else {
      _snack('Konnte Bereich nicht anlegen.', color: Colors.red.shade700);
    }
  }

  Future<void> _archiveTopic(GodModeTopic t) async {
    final ok = await GodModeService.setTopicStatus(t.slug, archived: true);
    if (!mounted) return;
    if (ok) {
      _snack('Bereich archiviert.');
      _loadTopics();
    }
  }

  // B1: Bereich umbenennen.
  Future<void> _renameTopic(GodModeTopic t) async {
    final ctrl = TextEditingController(text: t.label);
    final newLabel = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Bereich umbenennen',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: _editDecoration('Neuer Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (newLabel == null || newLabel.isEmpty || newLabel == t.label) return;
    final ok = await GodModeService.renameTopic(t.slug, newLabel);
    if (!mounted) return;
    _snack(ok ? 'Umbenannt in "$newLabel".' : 'Umbenennen fehlgeschlagen.',
        color: ok ? Colors.green.shade700 : Colors.red.shade700);
    if (ok) _loadTopics();
  }

  // B1: Bereich in einen anderen zusammenfuehren.
  Future<void> _mergeTopic(GodModeTopic t) async {
    final others = _topics.where((x) => x.slug != t.slug).toList();
    if (others.isEmpty) {
      _snack('Kein anderer Bereich zum Zusammenfuehren vorhanden.');
      return;
    }
    final target = await showModalBottomSheet<GodModeTopic>(
      context: context,
      backgroundColor: const Color(0xFF12121E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text('"${t.label}" zusammenfuehren in ...',
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: others
                  .map((o) => ListTile(
                        title: Text(o.label,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13)),
                        onTap: () => Navigator.pop(ctx, o),
                      ))
                  .toList(),
            ),
          ),
        ]),
      ),
    );
    if (target == null) return;
    final ok = await GodModeService.mergeTopic(from: t.slug, into: target.slug);
    if (!mounted) return;
    _snack(
        ok
            ? '"${t.label}" -> "${target.label}" zusammengefuehrt.'
            : 'Zusammenfuehren fehlgeschlagen.',
        color: ok ? Colors.green.shade700 : Colors.red.shade700);
    if (ok) _loadTopics();
  }

  // ─────────────── Tab 4: Status ────────────────────────────────────────────
  Widget _buildStatusTab() {
    return RefreshIndicator(
      color: _ab,
      backgroundColor: const Color(0xFF12121E),
      onRefresh: _loadRequests,
      child: _loadingReqs
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? Center(
                  child: Text(
                    'Noch keine Auftraege.',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                )
              : Column(children: [
                  _buildStatusListHeader(),
                  _buildReqFilter(),
                  Expanded(
                    child: Builder(builder: (_) {
                      final list = _filteredRequests();
                      if (list.isEmpty) {
                        return Center(
                          child: Text('Kein Auftrag in diesem Filter.',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 13)),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        itemCount: list.length,
                        itemBuilder: (_, i) => _buildRequestTile(list[i]),
                      );
                    }),
                  ),
                ]),
    );
  }

  // ─────────────── Tab 5: Repo ──────────────────────────────────────────────
  Widget _buildRepoTab() {
    return RefreshIndicator(
      color: _ab,
      backgroundColor: const Color(0xFF12121E),
      onRefresh: _loadRepo,
      child: _loadingRepo
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _repoStatsHeader(),
                _repoSection('🔀 Offene PRs', _repo.pulls, Colors.tealAccent),
                _repoSection(
                    '❌ Fehlgeschlagene CI', _repo.runs, Colors.redAccent),
                _repoSection('🐞 Offene Issues', _repo.issues, Colors.amber),
                _repoSection(
                    '📝 Letzte Commits', _repo.commits, Colors.white54),
              ],
            ),
    );
  }

  // C5: Provider-Status + Auftrag-Statistik.
  Widget _repoStatsHeader() {
    final s = _repo.stats;
    final p = _repo.providers;
    if (s.isEmpty && p.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (s.isNotEmpty)
          Text(
            'Auftraege: ${s['total'] ?? 0}  ·  offen ${s['open'] ?? 0}  ·  '
            'erledigt ${s['done'] ?? 0}  ·  fehlgeschlagen ${s['failed'] ?? 0}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        if (p.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('KI-PROVIDER',
              style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: p.entries.map((e) {
              final on = e.value;
              final c = on ? Colors.greenAccent : Colors.white24;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.withValues(alpha: 0.4)),
                ),
                child: Text('${on ? '●' : '○'} ${e.key}',
                    style: TextStyle(
                        color: on ? Colors.greenAccent : Colors.white38,
                        fontSize: 10.5)),
              );
            }).toList(),
          ),
        ],
      ]),
    );
  }

  Widget _repoSection(
      String title, List<GodModeRepoEntry> items, Color accent) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 8),
        child: Text('$title (${items.length})',
            style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5)),
      ),
      if (items.isEmpty)
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child:
              Text('—', style: TextStyle(color: Colors.white24, fontSize: 12)),
        )
      else
        ...items.map((e) => InkWell(
              onTap: e.url.isEmpty ? null : () => _openUrl(e.url),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(children: [
                  Expanded(
                    child: Text(e.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12.5)),
                  ),
                  if (e.meta.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(e.meta,
                        style: TextStyle(
                            color: accent.withValues(alpha: 0.8),
                            fontSize: 10)),
                  ],
                  if (e.url.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.open_in_new_rounded,
                          size: 13, color: Colors.white30),
                    ),
                ]),
              ),
            )),
      const SizedBox(height: 10),
    ]);
  }

  // S2: Auftraege nach Status-Gruppe filtern.
  List<GodModeRequest> _filteredRequests() {
    return _requests.where((r) {
      final st = r.status.toLowerCase();
      switch (_reqFilter) {
        case 'open':
          return !['merged', 'done', 'completed', 'failed', 'error', 'rejected']
              .contains(st);
        case 'done':
          return ['merged', 'done', 'completed'].contains(st);
        case 'failed':
          return ['failed', 'error', 'rejected'].contains(st);
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildReqFilter() {
    const chips = <(String?, String)>[
      (null, 'Alle'),
      ('open', 'In Arbeit'),
      ('done', 'Erledigt'),
      ('failed', 'Fehlgeschlagen'),
    ];
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: chips.map((c) {
          final sel = c.$1 == _reqFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _reqFilter = c.$1),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: sel
                      ? _ab.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sel ? _ab : Colors.white12),
                ),
                child: Text(c.$2,
                    style: TextStyle(
                        color: sel ? _ab : Colors.white54, fontSize: 11)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusListHeader() {
    final hasDeletable = _requests.any((r) =>
        r.status == 'merged' || r.status == 'failed' || r.status == 'rejected');
    if (!hasDeletable) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      child: Row(children: [
        Text(
          '${_requests.length} Auftraege',
          style: const TextStyle(color: Colors.white38, fontSize: 11.5),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: _confirmClearDone,
          icon: const Icon(Icons.delete_sweep_outlined, size: 15),
          label: const Text('Erledigte loeschen',
              style: TextStyle(fontSize: 11.5)),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white38,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
        ),
      ]),
    );
  }

  Future<void> _confirmClearDone() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Erledigte loeschen?',
            style: TextStyle(color: Colors.white, fontSize: 15)),
        content: const Text(
          'Alle gemergten, fehlgeschlagenen und abgelehnten Eintraege werden geloescht.',
          style: TextStyle(color: Colors.white60, fontSize: 13),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Loeschen',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final toDelete = _requests
        .where((r) =>
            r.status == 'merged' ||
            r.status == 'failed' ||
            r.status == 'rejected')
        .toList();
    for (final r in toDelete) {
      await GodModeService.deleteRequest(r.id);
    }
    _snack('${toDelete.length} Eintraege geloescht.');
    _loadRequests();
  }

  Future<void> _deleteRequest(GodModeRequest r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Eintrag loeschen?',
            style: TextStyle(color: Colors.white, fontSize: 15)),
        content: Text(r.title,
            style: const TextStyle(color: Colors.white60, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Loeschen',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final deleted = await GodModeService.deleteRequest(r.id);
    if (!mounted) return;
    if (deleted) {
      setState(() => _requests = _requests.where((x) => x.id != r.id).toList());
      _snack('Eintrag geloescht.');
    } else {
      _snack('Loeschen fehlgeschlagen.', color: Colors.red.shade700);
    }
  }

  Future<void> _retryRequest(GodModeRequest r) async {
    setState(() => _submitting = true);
    final res = await GodModeService.retryRequest(r.id);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.success) {
      _snack('Auftrag #${res.issueNumber} erneut angelegt.',
          color: Colors.green.shade700);
      _loadRequests();
    } else {
      _snack(res.message, color: Colors.red.shade700);
    }
  }

  Widget _buildRequestTile(GodModeRequest r) {
    final st = _statusStyle(r.status);
    final t = r.typeInfo;
    final isFailed = r.status == 'failed' || r.status == 'rejected';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF12121E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(r.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: st.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(st.label,
                style: TextStyle(
                    color: st.color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          if (t != null) ...[_typeBadge(t), const SizedBox(width: 6)],
          Flexible(
            child: Text(
              '${r.isAi ? '🤖 KI' : (r.isChat ? '💬 Chat' : '👤 Manuell')}  ·  ${r.categoryLabel}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
          const Spacer(),
          if (r.issueUrl != null)
            _linkChip('Issue #${r.issueNumber ?? '?'}', r.issueUrl),
          if (r.prUrl != null) ...[
            const SizedBox(width: 6),
            _linkChip('PR #${r.prNumber ?? '?'}', r.prUrl),
          ],
        ]),
        if (r.error != null && r.error!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.error_outline_rounded,
                  size: 13, color: Colors.red.shade300),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_humanError(r.error!),
                    style: TextStyle(color: Colors.red.shade300, fontSize: 11)),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          // S3: fehlgeschlagenen Auftrag mit angepasstem Prompt neu absetzen.
          if (isFailed)
            TextButton.icon(
              onPressed: _submitting
                  ? null
                  : () => _editAndBuild(
                        category: r.category,
                        type: r.wbType ?? 'verbesserung',
                        title: r.title,
                        description: r.description,
                        source: 'manual',
                      ),
              icon: const Icon(Icons.edit_rounded, size: 14),
              label: const Text('Bearbeiten', style: TextStyle(fontSize: 11.5)),
              style: TextButton.styleFrom(
                foregroundColor: _ab,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          if (isFailed) const SizedBox(width: 6),
          if (isFailed)
            TextButton.icon(
              onPressed: _submitting ? null : () => _retryRequest(r),
              icon: _submitting
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded, size: 14),
              label: const Text('Nochmal', style: TextStyle(fontSize: 11.5)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.amberAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          if (isFailed) const SizedBox(width: 6),
          IconButton(
            tooltip: 'Loeschen',
            icon: const Icon(Icons.delete_outline_rounded, size: 17),
            color: Colors.white24,
            onPressed: () => _deleteRequest(r),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            visualDensity: VisualDensity.compact,
          ),
        ]),
      ]),
    );
  }

  String _humanError(String raw) {
    switch (raw) {
      case 'verify_gate_red':
        return 'CI rot -- Claude versucht automatisch zu fixen. Status aktualisiert sich.';
      case 'no_pr_created':
        return 'Kein PR erstellt -- Auftrag bitte praeziser formulieren.';
      default:
        return 'Fehler: $raw';
    }
  }

  // ─────────────── Badges + Shared helpers ─────────────────────────────────
  Widget _typeBadge(GodModeType t) {
    final c = Color(t.colorValue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Text('${t.emoji} ${t.label}',
          style:
              TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _miniBadge(String label, Color border) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: border),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 9.5,
                fontWeight: FontWeight.w600)),
      );

  Widget _linkChip(String label, String? url) => InkWell(
        onTap: () => _openUrl(url),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _a.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.open_in_new_rounded, size: 11, color: _ab),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: _ab, fontSize: 10.5)),
          ]),
        ),
      );

  _GodModeStatusStyle _statusStyle(String s) => switch (s) {
        'merged' => _GodModeStatusStyle('Gemergt', Colors.greenAccent),
        'building' => _GodModeStatusStyle('Baut ...', Colors.orangeAccent),
        'pr_open' => _GodModeStatusStyle('PR offen', Colors.lightBlueAccent),
        'issue_created' =>
          _GodModeStatusStyle('Beauftragt', Colors.amberAccent),
        'failed' => _GodModeStatusStyle('Fehlgeschlagen', Colors.redAccent),
        'rejected' => _GodModeStatusStyle('Abgelehnt', Colors.redAccent),
        _ => _GodModeStatusStyle('Wartend', Colors.white54),
      };

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF12121E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: child,
      );

  Widget _infoBox(String text) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _a.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _a.withValues(alpha: 0.2)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline_rounded, color: _ab, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 12.5, height: 1.45))),
        ]),
      );

  Widget _sectionLabel(IconData icon, String text) => Row(children: [
        Icon(icon, color: _ab, size: 15),
        const SizedBox(width: 7),
        Text(text,
            style: TextStyle(
                color: _ab,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4)),
      ]);

  InputDecoration _inputDeco(String label, String hint) => InputDecoration(
        labelText: label,
        hintText: hint.isEmpty ? null : hint,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12.5),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white12)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _ab)),
      );
}

/// Plain class fuer Status-Farbe (kein Dart-3-Record -- crasht dart2js).
class _GodModeStatusStyle {
  final String label;
  final Color color;
  const _GodModeStatusStyle(this.label, this.color);
}
