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

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 4, vsync: this);
    _loadRequests();
    _loadTopics();
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
    });
    final res = await GodModeService.suggest(area: _suggestArea);
    if (!mounted) return;
    setState(() {
      _suggestions = res.suggestions;
      _learnedFromLast = res.learnedTopics;
      _suggesting = false;
    });
    if (res.suggestions.isEmpty) {
      _snack('Keine Vorschlaege -- spaeter erneut versuchen', color: Colors.orange);
    }
    if (res.learnedTopics.isNotEmpty) _loadTopics();
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
    _scrollChatDown();
  }

  Future<void> _confirmPendingOrder() async {
    final o = _pendingOrder;
    if (o == null) return;
    setState(() => _submitting = true);
    final res = await GodModeService.submit(
      category: o.category,
      type: o.type,
      title: o.title,
      description: o.description,
      source: 'chat',
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (res.success) {
        _pendingOrder = null;
        _chat.add(GodModeChatMessage('assistant',
            'Auftrag #${res.issueNumber ?? '?'} abgesetzt. Claude baut jetzt autonom -- '
            'du siehst den Fortschritt im Status-Tab.'));
      }
    });
    if (res.success) {
      _snack('Auftrag #${res.issueNumber} angelegt.', color: Colors.green.shade700);
      _loadRequests();
      _scrollChatDown();
    } else {
      _snack(res.message, color: Colors.red.shade700);
    }
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
  Future<void> _submitSuggestion(GodModeSuggestion s) async {
    setState(() => _submitting = true);
    final res = await GodModeService.submit(
      category: s.category,
      type: s.type,
      title: s.title,
      description: s.reason.isEmpty
          ? s.description
          : '${s.description}\n\nWarum: ${s.reason}',
      source: 'ai_suggestion',
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
          Tab(icon: Icon(Icons.auto_awesome_rounded, size: 18), text: 'KI-Ideen'),
          Tab(icon: Icon(Icons.category_rounded, size: 18), text: 'Bereiche'),
          Tab(icon: Icon(Icons.list_alt_rounded, size: 18), text: 'Status'),
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                color: _ab, fontSize: 9.5, fontWeight: FontWeight.bold,
                letterSpacing: 1.2),
          ),
        ),
      ]),
    );
  }

  // ─────────────── Tab 1: Chat ──────────────────────────────────────────────
  Widget _buildChatTab() {
    return Column(children: [
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
          child: Icon(Icons.forum_rounded, size: 54, color: _a.withValues(alpha: 0.3)),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'z.B. "Die Energie-Welt braucht einen Atem-Timer"\n'
            'oder "Der Login haengt manchmal -- bitte pruefen"',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12.5, height: 1.5),
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
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
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
                  Text('Assistent', style: TextStyle(
                      color: _ab, fontSize: 10, fontWeight: FontWeight.bold)),
                ]),
              ),
            Text(m.content, style: const TextStyle(
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
              width: 14, height: 14,
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
        Text(o.title, style: const TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
        if (o.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(o.description, style: const TextStyle(
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
                  ? const SizedBox(width: 15, height: 15,
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
      child: Row(children: [
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
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _chatBusy ? null : _sendChat,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _chatBusy ? Colors.white12 : _a,
              shape: BoxShape.circle,
            ),
            child: Icon(
                _chatBusy ? Icons.hourglass_empty_rounded : Icons.send_rounded,
                color: Colors.white, size: 20),
          ),
        ),
      ]),
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
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _suggesting ? null : _generateSuggestions,
            icon: _suggesting
                ? const SizedBox(width: 16, height: 16,
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
        ..._suggestions.map(_buildSuggestionCard),
      ],
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
          const Text('NEU GELERNTE BEREICHE', style: TextStyle(
              color: Colors.tealAccent, fontSize: 10,
              fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: _learnedFromLast.map((t) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.tealAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(t, style: const TextStyle(
                color: Colors.tealAccent, fontSize: 11)),
          );
        }).toList()),
      ]),
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
              onTap: () => setState(() => _suggestArea = e.$1),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: sel ? _ab.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sel ? _ab : Colors.white12),
                ),
                child: Text(e.$2, style: TextStyle(
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
          const Text('🤖 KI', style: TextStyle(
              color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 9),
        Text(s.title, style: const TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        Text(s.description, style: const TextStyle(
            color: Colors.white60, fontSize: 12.5, height: 1.45)),
        if (s.reason.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(9),
              border: Border(left: BorderSide(color: Color(t.colorValue), width: 2.5)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  size: 13, color: Colors.amberAccent),
              const SizedBox(width: 7),
              Expanded(
                child: RichText(text: TextSpan(children: [
                  const TextSpan(text: 'Warum: ', style: TextStyle(
                      color: Colors.amberAccent, fontSize: 11.5,
                      fontWeight: FontWeight.bold)),
                  TextSpan(text: s.reason, style: const TextStyle(
                      color: Colors.white54, fontSize: 11.5, height: 1.4)),
                ])),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.tonalIcon(
            onPressed: _submitting ? null : () => _submitSuggestion(s),
            icon: const Icon(Icons.rocket_launch_rounded, size: 15),
            label: const Text('Bauen lassen', style: TextStyle(fontSize: 12)),
            style: FilledButton.styleFrom(
              backgroundColor: _a.withValues(alpha: 0.25),
              foregroundColor: _ab,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
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
          _card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel(Icons.add_circle_outline_rounded, 'EIGENEN BEREICH ANLEGEN'),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _topicCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: _inputDeco('Bereichsname', 'z.B. Audio-Meditationen'),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addTopic,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _a,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  style: TextStyle(color: Colors.white38, fontSize: 12.5, height: 1.5),
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.label, style: const TextStyle(
                color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              t.isAi ? 'Selbst gelernt  ·  ${t.hitCount}x vorgeschlagen' : 'Manuell angelegt',
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
          icon: const Icon(Icons.archive_outlined, size: 17, color: Colors.white30),
          onPressed: () => _archiveTopic(t),
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
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _requests.length,
                  itemBuilder: (_, i) => _buildRequestTile(_requests[i]),
                ),
    );
  }

  Widget _buildRequestTile(GodModeRequest r) {
    final st = _statusStyle(r.status);
    final t = r.typeInfo;
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
                    color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: st.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(st.label, style: TextStyle(
                color: st.color, fontSize: 10, fontWeight: FontWeight.bold)),
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
          if (r.issueUrl != null) _linkChip('Issue #${r.issueNumber ?? '?'}', r.issueUrl),
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
            child: Row(children: [
              Icon(Icons.error_outline_rounded, size: 13, color: Colors.red.shade300),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_humanError(r.error!),
                    style: TextStyle(color: Colors.red.shade300, fontSize: 11)),
              ),
            ]),
          ),
        ],
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
      child: Text('${t.emoji} ${t.label}', style: TextStyle(
          color: c, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _miniBadge(String label, Color border) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: border),
        ),
        child: Text(label, style: const TextStyle(
            color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.w600)),
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
        'issue_created' => _GodModeStatusStyle('Beauftragt', Colors.amberAccent),
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
          Expanded(child: Text(text, style: const TextStyle(
              color: Colors.white60, fontSize: 12.5, height: 1.45))),
        ]),
      );

  Widget _sectionLabel(IconData icon, String text) => Row(children: [
        Icon(icon, color: _ab, size: 15),
        const SizedBox(width: 7),
        Text(text, style: TextStyle(
            color: _ab, fontSize: 11, fontWeight: FontWeight.bold,
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
