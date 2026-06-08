// God Mode: Root-Admin Entwickler-Konsole.
// part of world_admin_dashboard library.
part of '../world_admin_dashboard.dart';

// ═══════════════════════════════════════════════════════════════════════════
// GOD MODE -- Root-Admin Entwickler-Konsole
// ---------------------------------------------------------------------------
// Erlaubt dem Root-Admin, beliebige App-Aenderungen direkt aus der App heraus
// zu beauftragen: UI/UX, Features, Module, Bugfixes, Performance.
// Jeder Auftrag -> GitHub-Issue (Label "godmode") -> claude_godmode.yml baut
// autonom (bypassPermissions, voller Skill-Zugriff) -> Auto-Merge -> OTA.
// KI liefert proaktiv Vorschlaege. Nur Root-Admin sichtbar.
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

  // Form state
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'feature';

  // Flags
  bool _submitting = false;
  bool _suggesting = false;
  bool _loadingReqs = true;

  List<GodModeSuggestion> _suggestions = const [];
  List<GodModeRequest> _requests = const [];
  String? _suggestArea;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 3, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tc.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
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

  Future<void> _loadRequests() async {
    setState(() => _loadingReqs = true);
    final list = await GodModeService.listRequests();
    if (!mounted) return;
    setState(() {
      _requests = list;
      _loadingReqs = false;
    });
  }

  Future<void> _generateSuggestions() async {
    setState(() {
      _suggesting = true;
      _suggestions = const [];
    });
    final list = await GodModeService.suggest(area: _suggestArea);
    if (!mounted) return;
    setState(() {
      _suggestions = list;
      _suggesting = false;
    });
    if (list.isEmpty) {
      _snack('Keine Vorschlaege -- spaeter erneut versuchen', color: Colors.orange);
    }
  }

  Future<void> _submit({
    required String category,
    required String title,
    required String description,
    bool fromAi = false,
  }) async {
    if (title.trim().isEmpty) {
      _snack('Bitte Titel angeben', color: Colors.orange);
      return;
    }
    setState(() => _submitting = true);
    final res = await GodModeService.submit(
      category: category,
      title: title.trim(),
      description: description.trim(),
      fromAi: fromAi,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.success) {
      _snack(
        res.issueNumber != null
            ? 'Auftrag #${res.issueNumber} angelegt -- Claude baut autonom.'
            : res.message,
        color: Colors.green.shade700,
      );
      if (!fromAi) {
        _titleCtrl.clear();
        _descCtrl.clear();
      }
      _loadRequests();
      // Zum Status-Tab springen
      _tc.animateTo(2);
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
        labelColor: _ab,
        unselectedLabelColor: Colors.white38,
        indicatorColor: _ab,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: const [
          Tab(icon: Icon(Icons.edit_rounded, size: 18), text: 'Auftrag'),
          Tab(icon: Icon(Icons.auto_awesome_rounded, size: 18), text: 'KI-Ideen'),
          Tab(icon: Icon(Icons.list_alt_rounded, size: 18), text: 'Status'),
        ],
      ),
      Expanded(
        child: TabBarView(
          controller: _tc,
          children: [
            _buildOrderTab(),
            _buildSuggestTab(),
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

  // ─────────────── Tab 1: Auftrag ──────────────────────────────────────────
  Widget _buildOrderTab() {
    return RefreshIndicator(
      color: _ab,
      backgroundColor: const Color(0xFF12121E),
      onRefresh: _loadRequests,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoBox(
            'Claude implementiert deinen Auftrag autonom (vollstaendiger '
            'Skill-Zugriff, bypassPermissions). Nach gruenem CI-Gate wird '
            'automatisch gemergt und per OTA-Patch ausgeliefert.',
          ),
          const SizedBox(height: 16),
          _card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel(Icons.tune_rounded, 'BEREICH'),
              const SizedBox(height: 10),
              _buildCategoryChips(),
              const SizedBox(height: 16),
              _sectionLabel(Icons.title_rounded, 'TITEL'),
              const SizedBox(height: 8),
              TextField(
                controller: _titleCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: _inputDeco(
                  'Was soll gebaut / geaendert / behoben werden?',
                  'z.B. Dark-Mode-Toggle in Einstellungen',
                ),
              ),
              const SizedBox(height: 14),
              _sectionLabel(Icons.description_rounded, 'BESCHREIBUNG'),
              const SizedBox(height: 8),
              TextField(
                controller: _descCtrl,
                maxLines: 5,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: _inputDeco(
                  'Details -- je konkreter, desto besser. Wo in der App? '
                  'Was genau soll anders sein? Warum?',
                  '',
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting
                      ? null
                      : () => _submit(
                            category: _category,
                            title: _titleCtrl.text,
                            description: _descCtrl.text,
                          ),
                  icon: _submitting
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.rocket_launch_rounded, size: 18),
                  label: Text(
                    _submitting ? 'Wird beauftragt ...' : 'Auftrag absetzen',
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _a,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(spacing: 8, runSpacing: 8, children: GodModeCategory.all.map((c) {
      final sel = c.slug == _category;
      return GestureDetector(
        onTap: () => setState(() => _category = c.slug),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: sel ? _a.withValues(alpha: 0.28) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: sel ? _a : Colors.white24, width: sel ? 1.4 : 1),
          ),
          child: Text(c.label, style: TextStyle(
            color: sel ? _ab : Colors.white70, fontSize: 12.5,
            fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
          )),
        ),
      );
    }).toList());
  }

  // ─────────────── Tab 2: KI-Ideen ─────────────────────────────────────────
  Widget _buildSuggestTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoBox(
          'Die KI analysiert die App und schlaegt konkrete Weiterentwicklungen '
          'vor. Tippe "Generieren", dann auf "Bauen lassen" bei einem Vorschlag.',
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

  Widget _buildAreaFilter() {
    final entries = <(String?, String)>[
      (null, 'Gemischt'),
      ...GodModeCategory.all.map((c) => (c.label, c.label)),
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
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.22)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '🤖  ${s.categoryLabel}',
              style: const TextStyle(
                  color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Text(s.title, style: const TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        Text(s.description, style: const TextStyle(
            color: Colors.white60, fontSize: 12.5, height: 1.45)),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.tonalIcon(
            onPressed: _submitting
                ? null
                : () => _submit(
                      category: s.category,
                      title: s.title,
                      description: s.description,
                      fromAi: true,
                    ),
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

  // ─────────────── Tab 3: Status ────────────────────────────────────────────
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
        const SizedBox(height: 6),
        Row(children: [
          Text(
            '${r.isAi ? '🤖 KI' : '👤 Manuell'}  ·  ${r.categoryLabel}',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const Spacer(),
          if (r.issueUrl != null) _linkChip('Issue #${r.issueNumber ?? '?'}', r.issueUrl),
          if (r.prUrl != null) ...[
            const SizedBox(width: 6),
            _linkChip('PR #${r.prNumber ?? '?'}', r.prUrl),
          ],
        ]),
        if (r.error != null && r.error!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Fehler: ${r.error}',
              style: TextStyle(color: Colors.red.shade300, fontSize: 11)),
        ],
      ]),
    );
  }

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
    'merged'        => _GodModeStatusStyle('Gemergt', Colors.greenAccent),
    'building'      => _GodModeStatusStyle('Baut ...', Colors.orangeAccent),
    'pr_open'       => _GodModeStatusStyle('PR offen', Colors.lightBlueAccent),
    'issue_created' => _GodModeStatusStyle('Beauftragt', Colors.amberAccent),
    'failed'        => _GodModeStatusStyle('Fehlgeschlagen', Colors.redAccent),
    'rejected'      => _GodModeStatusStyle('Abgelehnt', Colors.redAccent),
    _               => _GodModeStatusStyle('Wartend', Colors.white54),
  };

  // ─────────────── Shared helpers ──────────────────────────────────────────
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
