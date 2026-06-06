// GENERATED SPLIT (TEIL 1B): part of world_admin_dashboard library.
// No logic changes -- structural extraction only.
part of '../world_admin_dashboard.dart';

// ═══════════════════════════════════════════════════════════
// 🔔 PUSH-BROADCAST TAB
// ═══════════════════════════════════════════════════════════
// ═════════════════════════════════════════════════════════════════════════════
// TAB – CONTENT INSIGHTS (Wrapper · Module + Spirit-Tools)
// ═════════════════════════════════════════════════════════════════════════════
class _ContentInsightsTab extends StatefulWidget {
  final Color accent;
  final Color accentBright;
  // videosOnly=true: Rolle hat keine vollen Content-Rechte (z.B. Moderator/
  // Admin) -> es wird NUR der Video-Manager gezeigt, ohne die anderen
  // Content-Sub-Tabs (Fortschritt/Editor/Meldungen/Artikel).
  final bool videosOnly;
  const _ContentInsightsTab({
    required this.accent,
    required this.accentBright,
    this.videosOnly = false,
  });

  @override
  State<_ContentInsightsTab> createState() => _ContentInsightsTabState();
}

class _ContentInsightsTabState extends State<_ContentInsightsTab>
    with SingleTickerProviderStateMixin {
  TabController? _ctrl;

  @override
  void initState() {
    super.initState();
    // Nur ein TabController wenn die vollen Content-Tabs gezeigt werden.
    if (!widget.videosOnly) {
      _ctrl = TabController(length: 5, vsync: this);
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Eingeschraenkte Ansicht: nur Video-Manager (Moderator/Admin ohne
    // Content-Edit-Recht).
    if (widget.videosOnly) {
      return _VideoManagerTab(
          accent: widget.accent, accentBright: widget.accentBright);
    }
    return Column(children: [
      Container(
        color: const Color(0xFF0D0D1A),
        child: TabBar(
          controller: _ctrl,
          isScrollable: true,
          indicatorColor: widget.accent,
          labelColor: widget.accentBright,
          unselectedLabelColor: Colors.white38,
          labelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(
                icon: Icon(Icons.school_rounded, size: 16),
                text: 'Fortschritt'),
            Tab(icon: Icon(Icons.edit_note_rounded, size: 16), text: 'Editor'),
            Tab(icon: Icon(Icons.report_rounded, size: 16), text: 'Meldungen'),
            Tab(icon: Icon(Icons.article_rounded, size: 16), text: 'Artikel'),
            Tab(
                icon: Icon(Icons.play_circle_outline_rounded, size: 16),
                text: 'Videos'),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _ctrl,
          children: [
            _ModuleProgressTab(
                accent: widget.accent, accentBright: widget.accentBright),
            _ModuleEditorTab(
                accent: widget.accent, accentBright: widget.accentBright),
            _PostReportsTab(
                accent: widget.accent, accentBright: widget.accentBright),
            _ArticleManagerTab(
                accent: widget.accent, accentBright: widget.accentBright),
            _VideoManagerTab(
                accent: widget.accent, accentBright: widget.accentBright),
          ],
        ),
      ),
    ]);
  }
}

// =============================================================================
// SUB-TAB – ARTIKEL-MANAGER (Content-Tab)
// =============================================================================
class _ArticleManagerTab extends StatefulWidget {
  final Color accent, accentBright;
  const _ArticleManagerTab({required this.accent, required this.accentBright});
  @override
  State<_ArticleManagerTab> createState() => _ArticleManagerTabState();
}

class _ArticleManagerTabState extends State<_ArticleManagerTab> {
  List<Map<String, dynamic>>? _articles;
  bool _loading = true;
  String _worldFilter = 'all';
  String _statusFilter = 'all';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final rows = await WorldAdminServiceV162.getArticles(
      world: _worldFilter == 'all' ? null : _worldFilter,
      status: _statusFilter,
      limit: 100,
    );
    if (mounted)
      setState(() {
        _articles = rows;
        _loading = false;
      });
  }

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color ?? const Color(0xFF1A1A2E),
    ));
  }

  String _fmtDate(dynamic v) {
    if (v == null) return '–';
    try {
      final dt = DateTime.parse(v.toString()).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return '–';
    }
  }

  Future<void> _togglePublished(Map<String, dynamic> article) async {
    final id = article['id'] as String? ?? '';
    if (id.isEmpty) return;
    final cur = article['is_published'] as bool? ?? false;
    final ok = await WorldAdminServiceV162.updateArticle(
      articleId: id,
      fields: {'is_published': !cur},
    );
    _snack(
        ok ? (cur ? 'Artikel depubliziert' : 'Artikel publiziert') : '❌ Fehler',
        color: ok ? Colors.green : Colors.orange);
    if (ok) _load();
  }

  Future<void> _toggleFeatured(Map<String, dynamic> article) async {
    final id = article['id'] as String? ?? '';
    if (id.isEmpty) return;
    final cur = article['is_featured'] as bool? ?? false;
    final ok = await WorldAdminServiceV162.updateArticle(
      articleId: id,
      fields: {'is_featured': !cur},
    );
    _snack(
        ok ? (cur ? 'Featured entfernt' : 'Als Featured markiert') : '❌ Fehler',
        color: ok ? Colors.teal : Colors.orange);
    if (ok) _load();
  }

  Future<void> _editArticle(Map<String, dynamic> article) async {
    final id = article['id'] as String? ?? '';
    if (id.isEmpty) return;
    final titleCtrl =
        TextEditingController(text: article['title'] as String? ?? '');
    final contentCtrl =
        TextEditingController(text: article['content'] as String? ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12121E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.edit_rounded, color: widget.accent, size: 18),
          const SizedBox(width: 8),
          const Expanded(
              child: Text('Artikel bearbeiten',
                  style: TextStyle(color: Colors.white, fontSize: 15))),
        ]),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Titel',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                maxLines: 12,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Content (Markdown)',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12)),
                ),
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen',
                  style: TextStyle(color: Colors.white54))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: widget.accent),
              child: const Text('Speichern',
                  style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    final ok = await WorldAdminServiceV162.updateArticle(
      articleId: id,
      fields: {
        'title': titleCtrl.text.trim(),
        'content': contentCtrl.text.trim(),
      },
    );
    _snack(ok ? '✅ Artikel gespeichert' : '❌ Speichern fehlgeschlagen',
        color: ok ? Colors.green : Colors.orange);
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    final articles = _articles ?? [];
    return Column(children: [
      // Filter-Leiste
      Container(
        color: const Color(0xFF0D0D1A),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          // World-Filter
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _worldFilter,
              dropdownColor: const Color(0xFF1A1A2E),
              iconEnabledColor: Colors.white54,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              isDense: true,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Alle Welten')),
                DropdownMenuItem(value: 'materie', child: Text('Materie')),
                DropdownMenuItem(value: 'energie', child: Text('Energie')),
                DropdownMenuItem(value: 'vorhang', child: Text('Vorhang')),
                DropdownMenuItem(value: 'ursprung', child: Text('Ursprung')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _worldFilter = v);
                _load();
              },
            ),
          ),
          const SizedBox(width: 12),
          // Status-Filter
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _statusFilter,
              dropdownColor: const Color(0xFF1A1A2E),
              iconEnabledColor: Colors.white54,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              isDense: true,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Alle')),
                DropdownMenuItem(value: 'published', child: Text('Publiziert')),
                DropdownMenuItem(value: 'unpublished', child: Text('Entwurf')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _statusFilter = v);
                _load();
              },
            ),
          ),
          const Spacer(),
          Text('${articles.length} Artikel',
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: widget.accent, size: 18),
            onPressed: _load,
            tooltip: 'Aktualisieren',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ]),
      ),
      // Liste
      Expanded(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: widget.accent))
            : _articles == null
                ? const _EmptyHint(
                    'Laden fehlgeschlagen. Ziehe zum Aktualisieren.')
                : articles.isEmpty
                    ? const _EmptyHint('Keine Artikel gefunden.')
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: widget.accent,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: articles.length,
                          itemBuilder: (ctx, i) {
                            final a = articles[i];
                            final title = a['title'] as String? ?? '–';
                            final world = a['world'] as String? ?? '–';
                            final author = (a['profiles'] as Map?)?['username']
                                    as String? ??
                                '–';
                            final published =
                                a['is_published'] as bool? ?? false;
                            final featured = a['is_featured'] as bool? ?? false;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF12121E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.06)),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                title: Text(title,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(children: [
                                    _MiniPill(
                                        label: world,
                                        color: widget.accent
                                            .withValues(alpha: 0.8)),
                                    const SizedBox(width: 6),
                                    Text(
                                        '@$author · ${_fmtDate(a['created_at'])}',
                                        style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 10)),
                                  ]),
                                ),
                                trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Featured toggle
                                      IconButton(
                                        icon: Icon(
                                          featured
                                              ? Icons.star_rounded
                                              : Icons.star_border_rounded,
                                          color: featured
                                              ? Colors.amber
                                              : Colors.white24,
                                          size: 18,
                                        ),
                                        tooltip: featured
                                            ? 'Featured entfernen'
                                            : 'Als Featured markieren',
                                        onPressed: () => _toggleFeatured(a),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                            minWidth: 32, minHeight: 32),
                                      ),
                                      // Published toggle
                                      IconButton(
                                        icon: Icon(
                                          published
                                              ? Icons.visibility_rounded
                                              : Icons.visibility_off_rounded,
                                          color: published
                                              ? Colors.green
                                              : Colors.white24,
                                          size: 18,
                                        ),
                                        tooltip: published
                                            ? 'Depublizieren'
                                            : 'Publizieren',
                                        onPressed: () => _togglePublished(a),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                            minWidth: 32, minHeight: 32),
                                      ),
                                      // Edit
                                      IconButton(
                                        icon: const Icon(Icons.edit_rounded,
                                            color: Colors.white38, size: 16),
                                        tooltip: 'Bearbeiten',
                                        onPressed: () => _editArticle(a),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                            minWidth: 32, minHeight: 32),
                                      ),
                                    ]),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SUB-TAB – MODULE-EDITOR (Vorhang + Ursprung Felder bearbeiten)
// ═════════════════════════════════════════════════════════════════════════════
class _ModuleEditorTab extends StatefulWidget {
  final Color accent;
  final Color accentBright;
  const _ModuleEditorTab({required this.accent, required this.accentBright});

  @override
  State<_ModuleEditorTab> createState() => _ModuleEditorTabState();
}

class _ModuleEditorTabState extends State<_ModuleEditorTab> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  String _typeFilter = 'all';
  String _search = '';
  final _searchCtrl = TextEditingController();

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // AUDIT-FIX (Bug-Sweep 2): Admin-Auth-Header anhaengen.
      final headers = await AdminAuthService.instance.headers();
      final res = await http
          .get(Uri.parse('${ApiConfig.workerUrl}/api/admin/progress'),
              headers: headers)
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _data = jsonDecode(res.body) as Map<String, dynamic>;
          _loading = false;
        });
      } else if (mounted) {
        setState(() {
          _error =
              'HTTP ${res.statusCode}: ${res.body.length > 120 ? res.body.substring(0, 120) : res.body}';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Netzwerk: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _openEditor(String moduleType, String moduleCode) async {
    // Volles Modul vom Worker laden
    try {
      final headers = await AdminAuthService.instance.headers();
      final res = await http
          .get(
              Uri.parse(
                  '${ApiConfig.workerUrl}/api/admin/module/$moduleType/$moduleCode'),
              headers: headers)
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (res.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Modul laden: HTTP ${res.statusCode}'),
          backgroundColor: Colors.redAccent,
        ));
        return;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final module = data['module'] as Map<String, dynamic>?;
      if (module == null) return;
      if (!mounted) return;
      await _showEditorSheet(moduleType, moduleCode, module);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Netzwerk. Bitte erneut versuchen.'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  Future<void> _showEditorSheet(
      String moduleType, String moduleCode, Map<String, dynamic> module) async {
    final title =
        TextEditingController(text: module['title']?.toString() ?? '');
    final subtitle =
        TextEditingController(text: module['subtitle']?.toString() ?? '');
    final theory =
        TextEditingController(text: module['theory_content']?.toString() ?? '');
    final caseStudy =
        TextEditingController(text: module['case_study']?.toString() ?? '');
    final exercise = TextEditingController(
        text: module['exercise_description']?.toString() ?? '');
    final duration = TextEditingController(
        text: '${module['exercise_duration_minutes'] ?? 15}');
    final xp = TextEditingController(text: '${module['xp_reward'] ?? 50}');
    final youtube = TextEditingController(
        text: module['youtube_search_query']?.toString() ?? '');
    final freq = TextEditingController(
        text: module['audio_frequency_hz']?.toString() ?? '');
    // test_questions als formatiertes JSON (Array)
    final testQraw = module['test_questions'];
    final testQJson = testQraw == null
        ? '[]'
        : (testQraw is String
            ? testQraw
            : const JsonEncoder.withIndent('  ').convert(testQraw));
    final testQ = TextEditingController(text: testQJson);

    bool saving = false;

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A18),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            children: [
              Center(
                  child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              )),
              const SizedBox(height: 14),
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(moduleCode,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(moduleType.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          letterSpacing: 1)),
                ),
              ]),
              const SizedBox(height: 14),
              _editorField('Title', title),
              _editorField('Subtitle', subtitle),
              _editorField('Theory Content (Markdown OK)', theory, maxLines: 8),
              _editorField('Case Study', caseStudy, maxLines: 4),
              _editorField('Exercise Description', exercise, maxLines: 5),
              Row(children: [
                Expanded(
                    child: _editorField('Dauer (Min.)', duration,
                        keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(
                    child: _editorField('XP-Reward', xp,
                        keyboardType: TextInputType.number)),
              ]),
              _editorField('YouTube-Suchquery', youtube),
              _editorField('Audio-Frequenz Hz (z.B. 432)', freq,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              _editorField(
                'Test-Fragen (JSON-Array)',
                testQ,
                maxLines: 10,
                hint:
                    '[{"question":"...","options":["A","B","C"],"correct_index":0}]',
              ),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: saving ? null : () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Abbrechen'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            setSheet(() => saving = true);
                            final payload = <String, dynamic>{
                              'title': title.text.trim(),
                              'subtitle': subtitle.text.trim(),
                              'theory_content': theory.text.trim(),
                              'case_study': caseStudy.text.trim(),
                              'exercise_description': exercise.text.trim(),
                              'youtube_search_query': youtube.text.trim(),
                              'admin': 'admin',
                            };
                            final d = int.tryParse(duration.text.trim());
                            if (d != null) {
                              payload['exercise_duration_minutes'] = d;
                            }
                            final x = int.tryParse(xp.text.trim());
                            if (x != null) payload['xp_reward'] = x;
                            final f = double.tryParse(freq.text.trim());
                            if (f != null) payload['audio_frequency_hz'] = f;
                            // test_questions: parse JSON, fallback to raw string
                            final tqRaw = testQ.text.trim();
                            if (tqRaw.isNotEmpty) {
                              try {
                                payload['test_questions'] = jsonDecode(tqRaw);
                              } catch (_) {
                                payload['test_questions'] = tqRaw;
                              }
                            }

                            try {
                              final adminHeaders =
                                  await AdminAuthService.instance.headers();
                              final res = await http
                                  .patch(
                                    Uri.parse(
                                        '${ApiConfig.workerUrl}/api/admin/module/$moduleType/$moduleCode'),
                                    headers: {
                                      'Content-Type': 'application/json',
                                      ...adminHeaders,
                                    },
                                    body: jsonEncode(payload),
                                  )
                                  .timeout(const Duration(seconds: 12));
                              if (!mounted) return;
                              if (res.statusCode == 200) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text('✅ $moduleCode gespeichert'),
                                  backgroundColor: widget.accent,
                                ));
                                _load();
                              } else {
                                setSheet(() => saving = false);
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                  content: Text(
                                      '❌ HTTP ${res.statusCode}: ${res.body.length > 100 ? res.body.substring(0, 100) : res.body}'),
                                  backgroundColor: Colors.redAccent,
                                ));
                              }
                            } catch (e) {
                              setSheet(() => saving = false);
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                content:
                                    Text('Netzwerk. Bitte erneut versuchen.'),
                                backgroundColor: Colors.redAccent,
                              ));
                            }
                          },
                    icon: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded),
                    label: Text(saving ? 'Speichere…' : 'Speichern'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editorField(String label, TextEditingController ctrl,
      {int maxLines = 1, TextInputType? keyboardType, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(
            color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
          isDense: true,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.04),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: widget.accent),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: widget.accent));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Neu laden')),
          ]),
        ),
      );
    }
    final vorhangModules =
        (((_data?['vorhang'] as Map?)?['modules'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();
    final ursprungModules =
        (((_data?['ursprung'] as Map?)?['modules'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();

    final all = <Map<String, dynamic>>[
      ...vorhangModules.map((m) => {...m, '__type': 'vorhang'}),
      ...ursprungModules.map((m) => {...m, '__type': 'ursprung'}),
    ];

    final filtered = all.where((m) {
      if (_typeFilter != 'all' && m['__type'] != _typeFilter) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final blob =
            '${m['code'] ?? ''} ${m['title'] ?? ''} ${m['branch'] ?? ''}'
                .toLowerCase();
        if (!blob.contains(q)) return false;
      }
      return true;
    }).toList();

    return Column(children: [
      // Filter-Leiste
      Container(
        color: const Color(0xFF0D0D1A),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(children: [
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Suche Code / Title / Branch',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: Colors.white38, size: 18),
              isDense: true,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              suffixIcon: _search.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          color: Colors.white38, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      },
                    ),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 8),
          Row(children: [
            ...['all', 'vorhang', 'ursprung'].map((t) {
              final sel = _typeFilter == t;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _typeFilter = t),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel
                          ? widget.accent.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: sel ? widget.accent : Colors.transparent),
                    ),
                    child: Text(
                        t == 'all'
                            ? 'Alle'
                            : t[0].toUpperCase() + t.substring(1),
                        style: TextStyle(
                          color: sel ? widget.accentBright : Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ),
              );
            }),
            const Spacer(),
            Text('${filtered.length}/${all.length}',
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ]),
        ]),
      ),
      Expanded(
        child: RefreshIndicator(
          color: widget.accent,
          onRefresh: () async => _load(),
          child: filtered.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 60),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Keine Module für diesen Filter.',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 13)),
                    ),
                  ),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final m = filtered[i];
                    final type = m['__type'] as String;
                    final code = m['code']?.toString() ?? '';
                    final title = m['title']?.toString() ?? code;
                    final branch = m['branch']?.toString() ?? '';
                    final xpReward = (m['xp_reward'] ?? 0) as int;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _openEditor(type, code),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF12121E),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: type == 'vorhang'
                                      ? Colors.purple.withValues(alpha: 0.2)
                                      : Colors.teal.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(code,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(title,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 1),
                                      Text(branch,
                                          style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 9,
                                              letterSpacing: 0.6),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ]),
                              ),
                              if (xpReward > 0)
                                Text('+$xpReward',
                                    style: const TextStyle(
                                        color: Color(0xFFFFC107),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              const SizedBox(width: 6),
                              const Icon(Icons.edit_rounded,
                                  color: Colors.white38, size: 16),
                            ]),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    ]);
  }
}

// =============================================================================
// SUB-TAB - VIDEO-MANAGER (Mediathek einpflegen + bestaetigen)
// =============================================================================
class _VideoManagerTab extends StatefulWidget {
  final Color accent, accentBright;
  const _VideoManagerTab({required this.accent, required this.accentBright});
  @override
  State<_VideoManagerTab> createState() => _VideoManagerTabState();
}

class _VideoManagerTabState extends State<_VideoManagerTab> {
  List<Map<String, dynamic>>? _videos;
  bool _loading = true;
  String _worldFilter = 'all';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final rows = await WorldAdminServiceV162.getArchiveVideos(
      world: _worldFilter == 'all' ? null : _worldFilter,
      status: _statusFilter,
      limit: 200,
    );
    if (mounted) {
      setState(() {
        _videos = rows;
        _loading = false;
      });
    }
  }

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color ?? const Color(0xFF1A1A2E),
    ));
  }

  String _fmtDate(dynamic v) {
    if (v == null) return '-';
    try {
      final dt = DateTime.parse(v.toString()).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return '-';
    }
  }

  Future<void> _confirm(Map<String, dynamic> v) async {
    final id = v['id'] as String? ?? '';
    if (id.isEmpty) return;
    final ok = await WorldAdminServiceV162.confirmArchiveVideo(id);
    _snack(ok ? 'Video bestaetigt (sichtbar)' : 'Fehler beim Bestaetigen',
        color: ok ? Colors.green : Colors.orange);
    if (ok) _load();
  }

  Future<void> _reject(Map<String, dynamic> v) async {
    final id = v['id'] as String? ?? '';
    if (id.isEmpty) return;
    final ok = await WorldAdminServiceV162.rejectArchiveVideo(id);
    _snack(ok ? 'Video ausgeblendet' : 'Fehler beim Ausblenden',
        color: ok ? Colors.teal : Colors.orange);
    if (ok) _load();
  }

  Future<void> _delete(Map<String, dynamic> v) async {
    final id = v['id'] as String? ?? '';
    if (id.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12121E),
        title: const Text('Video loeschen?',
            style: TextStyle(color: Colors.white, fontSize: 15)),
        content: const Text('Das Video wird endgueltig entfernt.',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen',
                  style: TextStyle(color: Colors.white54))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child:
                  const Text('Loeschen', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await WorldAdminServiceV162.deleteArchiveVideo(id);
    _snack(ok ? 'Video geloescht' : 'Fehler beim Loeschen',
        color: ok ? Colors.green : Colors.orange);
    if (ok) _load();
  }

  Future<void> _addVideo() async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddVideoDialog(
        accent: widget.accent,
        accentBright: widget.accentBright,
      ),
    );
    if (saved == true) {
      _snack('Video eingepflegt + sichtbar', color: Colors.green);
      _load();
    }
  }

  // Nachtraegliche Bearbeitung von Kategorie + Welten eines Videos.
  Future<void> _editVideo(Map<String, dynamic> v) async {
    final id = v['id'] as String? ?? '';
    if (id.isEmpty) return;
    const allWorlds = ['materie', 'energie', 'vorhang', 'ursprung'];
    final categoryCtrl = TextEditingController(
        text: (v['category'] as String?) ?? '');
    final rawWorlds = v['worlds'];
    final selectedWorlds = <String>{
      ...(rawWorlds is List ? rawWorlds.map((e) => e.toString()) : <String>[]),
    };

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: const Color(0xFF12121E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Video bearbeiten',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (v['youtube_title'] ?? v['raw_title'] ?? '-').toString(),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                const Text('Welten',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        letterSpacing: 1.2)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: allWorlds.map((w) {
                    final sel = selectedWorlds.contains(w);
                    return GestureDetector(
                      onTap: () => setLocal(() {
                        if (sel) {
                          selectedWorlds.remove(w);
                        } else {
                          selectedWorlds.add(w);
                        }
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel
                              ? widget.accent.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: sel
                                  ? widget.accent
                                  : Colors.white24),
                        ),
                        child: Text(w,
                            style: TextStyle(
                                color: sel
                                    ? widget.accentBright
                                    : Colors.white70,
                                fontSize: 12,
                                fontWeight:
                                    sel ? FontWeight.w700 : FontWeight.normal)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: categoryCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Kategorie',
                    labelStyle: const TextStyle(color: Colors.white54),
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
                        borderSide: BorderSide(color: widget.accent)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen',
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedWorlds.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Mindestens eine Welt waehlen'),
                    backgroundColor: Colors.orange,
                  ));
                  return;
                }
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: widget.accent),
              child:
                  const Text('Speichern', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    final ok = await WorldAdminServiceV162.updateArchiveVideo(
      videoId: id,
      category: categoryCtrl.text.trim().isEmpty
          ? null
          : categoryCtrl.text.trim(),
      worlds: selectedWorlds.toList(),
    );
    _snack(ok ? 'Video aktualisiert' : 'Fehler beim Aktualisieren',
        color: ok ? Colors.green : Colors.orange);
    if (ok) _load();
  }
  @override
  Widget build(BuildContext context) {
    final videos = _videos ?? [];
    return Column(children: [
      // Filter-Leiste
      Container(
        color: const Color(0xFF0D0D1A),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _worldFilter,
              dropdownColor: const Color(0xFF1A1A2E),
              iconEnabledColor: Colors.white54,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              isDense: true,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Alle Welten')),
                DropdownMenuItem(value: 'materie', child: Text('Materie')),
                DropdownMenuItem(value: 'energie', child: Text('Energie')),
                DropdownMenuItem(value: 'vorhang', child: Text('Vorhang')),
                DropdownMenuItem(value: 'ursprung', child: Text('Ursprung')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _worldFilter = v);
                _load();
              },
            ),
          ),
          const SizedBox(width: 12),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _statusFilter,
              dropdownColor: const Color(0xFF1A1A2E),
              iconEnabledColor: Colors.white54,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              isDense: true,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Alle')),
                DropdownMenuItem(value: 'confirmed', child: Text('Sichtbar')),
                DropdownMenuItem(value: 'pending', child: Text('Wartend')),
                DropdownMenuItem(value: 'rejected', child: Text('Versteckt')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _statusFilter = v);
                _load();
              },
            ),
          ),
          const Spacer(),
          Text('${videos.length}',
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: widget.accent, size: 18),
            onPressed: _load,
            tooltip: 'Aktualisieren',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ]),
      ),
      // Liste
      Expanded(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: widget.accent))
            : _videos == null
                ? const _EmptyHint(
                    'Laden fehlgeschlagen. Ziehe zum Aktualisieren.')
                : videos.isEmpty
                    ? const _EmptyHint('Keine Videos. Tippe + zum Einpflegen.')
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: widget.accent,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: videos.length,
                          itemBuilder: (ctx, i) {
                            final v = videos[i];
                            final title = (v['youtube_title'] ??
                                    v['raw_title'] ??
                                    '-')
                                .toString();
                            final status =
                                v['status'] as String? ?? 'pending';
                            final category = v['category'] as String?;
                            final rawWorlds = v['worlds'];
                            final worlds = rawWorlds is List
                                ? rawWorlds.map((e) => e.toString()).toList()
                                : <String>[];
                            final thumb =
                                v['thumbnail_url'] as String? ?? '';
                            final statusColor = status == 'confirmed'
                                ? Colors.green
                                : status == 'rejected'
                                    ? Colors.white24
                                    : Colors.amber;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF12121E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.06)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(children: [
                                  // Thumbnail
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: thumb.isNotEmpty
                                        ? Image.network(
                                            thumb,
                                            width: 72,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                              width: 72,
                                              height: 48,
                                              color: const Color(0xFF1A1A2E),
                                              child: const Icon(
                                                  Icons.broken_image_rounded,
                                                  color: Colors.white24,
                                                  size: 18),
                                            ),
                                          )
                                        : Container(
                                            width: 72,
                                            height: 48,
                                            color: const Color(0xFF1A1A2E),
                                            child: const Icon(
                                                Icons
                                                    .play_circle_outline_rounded,
                                                color: Colors.white24,
                                                size: 18),
                                          ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(title,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            _MiniPill(
                                                label: status,
                                                color: statusColor),
                                            for (final w in worlds)
                                              _MiniPill(
                                                  label: w,
                                                  color: widget.accent
                                                      .withValues(alpha: 0.7)),
                                            if (category != null)
                                              Text(category,
                                                  style: const TextStyle(
                                                      color: Colors.white38,
                                                      fontSize: 10)),
                                            Text('· ${_fmtDate(v['created_at'])}',
                                                style: const TextStyle(
                                                    color: Colors.white24,
                                                    fontSize: 10)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Actions
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (status != 'confirmed')
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.check_circle_rounded,
                                                  color: Colors.green,
                                                  size: 18),
                                              tooltip: 'Bestaetigen',
                                              onPressed: () => _confirm(v),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(
                                                  minWidth: 30, minHeight: 30),
                                            ),
                                          if (status == 'confirmed')
                                            IconButton(
                                              icon: const Icon(
                                                  Icons
                                                      .visibility_off_rounded,
                                                  color: Colors.white38,
                                                  size: 18),
                                              tooltip: 'Ausblenden',
                                              onPressed: () => _reject(v),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(
                                                  minWidth: 30, minHeight: 30),
                                            ),
                                          IconButton(
                                            icon: Icon(Icons.edit_rounded,
                                                color: widget.accent, size: 16),
                                            tooltip: 'Kategorie/Welten bearbeiten',
                                            onPressed: () => _editVideo(v),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                                minWidth: 30, minHeight: 30),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.delete_outline_rounded,
                                                color: Colors.red,
                                                size: 16),
                                            tooltip: 'Loeschen',
                                            onPressed: () => _delete(v),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                                minWidth: 30, minHeight: 30),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
      ),
      // Add-Button
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _addVideo,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('Video einpflegen',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.accent,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ADD VIDEO DIALOG (Schritt-basiert: Suche → Ergebnis → Konfiguration)
// ═══════════════════════════════════════════════════════════════════════════

enum _VStep { input, loading, results, configuring }

class _AddVideoDialog extends StatefulWidget {
  final Color accent;
  final Color accentBright;
  const _AddVideoDialog({required this.accent, required this.accentBright});

  @override
  State<_AddVideoDialog> createState() => _AddVideoDialogState();
}

class _AddVideoDialogState extends State<_AddVideoDialog> {
  final _queryCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();

  _VStep _step = _VStep.input;
  List<YoutubeSearchResult> _results = [];
  YoutubeSearchResult? _selected;
  final Set<String> _selectedWorlds = {};
  String? _detectedTitle;
  String? _suggestSource;
  bool _suggesting = false;
  bool _saving = false;
  String? _errorMsg;
  String? _saveError;

  @override
  void dispose() {
    _queryCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  bool _isYoutubeUrl(String s) {
    final t = s.trim();
    return t.contains('youtube.com') ||
        t.contains('youtu.be') ||
        RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(t);
  }

  String? _extractId(String input) {
    final t = input.trim();
    final patterns = [
      RegExp(r'[?&]v=([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
      RegExp(r'/embed/([a-zA-Z0-9_-]{11})'),
      RegExp(r'/shorts/([a-zA-Z0-9_-]{11})'),
      RegExp(r'/live/([a-zA-Z0-9_-]{11})'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(t);
      if (m != null) return m.group(1);
    }
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(t)) return t;
    return null;
  }

  Future<void> _onSearch() async {
    final q = _queryCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _step = _VStep.loading;
      _errorMsg = null;
    });
    if (_isYoutubeUrl(q)) {
      final videoId = _extractId(q) ?? q;
      setState(() {
        _selected = YoutubeSearchResult(
          videoId: videoId,
          title: '',
          thumbnailUrl: '',
        );
        _step = _VStep.configuring;
      });
      _runSuggest(q);
    } else {
      final results = await WorldAdminServiceV162.searchYoutubeVideos(q);
      if (!mounted) return;
      if (results.isEmpty) {
        setState(() {
          _step = _VStep.input;
          _errorMsg = 'Keine Videos gefunden -- anderen Suchbegriff versuchen.';
        });
      } else {
        setState(() {
          _results = results;
          _step = _VStep.results;
        });
      }
    }
  }

  void _selectVideo(YoutubeSearchResult video) {
    setState(() {
      _selected = video;
      _step = _VStep.configuring;
      _selectedWorlds.clear();
      _categoryCtrl.clear();
      _detectedTitle = null;
      _suggestSource = null;
      _saveError = null;
    });
    _runSuggest(video.videoId);
  }

  Future<void> _runSuggest(String urlOrId) async {
    setState(() => _suggesting = true);
    final res = await WorldAdminServiceV162.suggestVideoClassification(urlOrId);
    if (!mounted) return;
    setState(() {
      _suggesting = false;
      if (res == null) return;
      _detectedTitle = res['title'] as String?;
      _suggestSource = res['source'] as String?;
      final worlds = (res['worlds'] as List?)
              ?.map((e) => e.toString())
              .where((w) =>
                  ['materie', 'energie', 'vorhang', 'ursprung'].contains(w))
              .toList() ??
          const [];
      if (worlds.isNotEmpty) {
        _selectedWorlds
          ..clear()
          ..addAll(worlds);
      }
      final cat = res['category'] as String?;
      if (cat != null && cat.isNotEmpty) _categoryCtrl.text = cat;
      final sel = _selected;
      if (sel != null &&
          sel.title.isEmpty &&
          _detectedTitle?.isNotEmpty == true) {
        _selected = YoutubeSearchResult(
          videoId: sel.videoId,
          title: _detectedTitle!,
          thumbnailUrl: sel.thumbnailUrl,
          channelTitle: sel.channelTitle,
        );
      }
    });
  }

  Future<void> _save() async {
    final sel = _selected;
    if (sel == null || _selectedWorlds.isEmpty) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final video = await WorldAdminServiceV162.createArchiveVideo(
      youtubeUrl: sel.videoId,
      worlds: _selectedWorlds.toList(),
      category: _categoryCtrl.text.trim(),
      status: 'confirmed',
    );
    if (!mounted) return;
    if (video != null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _saveError = 'Einpflegen fehlgeschlagen -- URL oder ID pruefen.';
      });
    }
  }

  void _goBack() {
    setState(() {
      _step = _VStep.input;
      _results.clear();
      _selected = null;
      _selectedWorlds.clear();
      _detectedTitle = null;
      _suggestSource = null;
      _saveError = null;
    });
  }

  Future<void> _showPreview(String videoId, String title) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _VideoPreviewDialog(
        videoId: videoId,
        title: title,
        accent: widget.accent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF12121E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        Icon(Icons.add_circle_outline_rounded, color: widget.accent, size: 18),
        const SizedBox(width: 8),
        const Expanded(
          child: Text('Video einpflegen',
              style: TextStyle(color: Colors.white, fontSize: 15)),
        ),
        if (_step != _VStep.input && _step != _VStep.loading)
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: Colors.white54, size: 18),
            onPressed: _goBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Zurueck zur Suche',
          ),
      ]),
      content: SizedBox(width: 500, child: _buildContent()),
      actions: _buildActions(),
    );
  }

  Widget _buildContent() {
    switch (_step) {
      case _VStep.input:
        return _buildInputStep();
      case _VStep.loading:
        return const SizedBox(
          height: 120,
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Suche laeuft...',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
            ]),
          ),
        );
      case _VStep.results:
        return _buildResultsStep();
      case _VStep.configuring:
        return _buildConfiguringStep();
    }
  }

  Widget _buildInputStep() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(
        controller: _queryCtrl,
        style: const TextStyle(color: Colors.white),
        onSubmitted: (_) => _onSearch(),
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'YouTube-URL oder Suchbegriff',
          hintText: 'z.B. "Quantenbewusstsein" oder https://youtu.be/...',
          labelStyle: const TextStyle(color: Colors.white54),
          hintStyle:
              const TextStyle(color: Colors.white24, fontSize: 12),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          suffixIcon: Icon(Icons.search_rounded,
              color: widget.accentBright, size: 20),
        ),
      ),
      if (_errorMsg != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(_errorMsg!,
              style:
                  const TextStyle(color: Colors.orange, fontSize: 12)),
        ),
      const SizedBox(height: 8),
      const Text(
        'Tipp: Themennamen eingeben zum Suchen,\noder YouTube-URL direkt einfuegen.',
        style: TextStyle(color: Colors.white38, fontSize: 11),
      ),
    ]);
  }

  Widget _buildResultsStep() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 380),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _results.length,
        separatorBuilder: (_, __) =>
            const Divider(color: Colors.white12, height: 1),
        itemBuilder: (_, i) => _YoutubeResultCard(
          result: _results[i],
          accent: widget.accent,
          accentBright: widget.accentBright,
          onPreview: () =>
              _showPreview(_results[i].videoId, _results[i].title),
          onSelect: () => _selectVideo(_results[i]),
        ),
      ),
    );
  }

  Widget _buildConfiguringStep() {
    final sel = _selected;
    if (sel == null) return const SizedBox.shrink();
    final thumb = sel.thumbnailUrl.isNotEmpty
        ? sel.thumbnailUrl
        : 'https://img.youtube.com/vi/${sel.videoId}/mqdefault.jpg';
    final displayTitle = _detectedTitle?.isNotEmpty == true
        ? _detectedTitle!
        : sel.title.isNotEmpty
            ? sel.title
            : sel.videoId;

    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Selected video preview header
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              thumb,
              width: 100,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 100,
                height: 56,
                color: Colors.white12,
                child: const Icon(Icons.videocam_rounded,
                    color: Colors.white38),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayTitle,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  if (sel.channelTitle?.isNotEmpty == true)
                    Text(sel.channelTitle!,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                  GestureDetector(
                    onTap: () => _showPreview(sel.videoId, displayTitle),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.play_circle_outline_rounded,
                          color: widget.accentBright, size: 14),
                      const SizedBox(width: 4),
                      Text('Vorschau',
                          style: TextStyle(
                              color: widget.accentBright, fontSize: 11)),
                    ]),
                  ),
                ]),
          ),
        ]),
        const SizedBox(height: 10),
        // KI-Status
        if (_suggesting)
          const Row(children: [
            SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 8),
            Text('KI analysiert Video...',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
          ])
        else if (_suggestSource != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Vorschlag via '
              '${_suggestSource == 'heuristic' ? 'Keywords' : 'KI'}'
              ' -- bitte pruefen',
              style:
                  TextStyle(color: widget.accentBright, fontSize: 11),
            ),
          ),
        const SizedBox(height: 10),
        // Welt-Chips
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Welten (mind. eine):',
              style:
                  TextStyle(color: Colors.white54, fontSize: 12)),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children:
              ['materie', 'energie', 'vorhang', 'ursprung'].map((w) {
            final isSelected = _selectedWorlds.contains(w);
            return FilterChip(
              label: Text(w[0].toUpperCase() + w.substring(1)),
              selected: isSelected,
              onSelected: (s) => setState(() {
                if (s) {
                  _selectedWorlds.add(w);
                } else {
                  _selectedWorlds.remove(w);
                }
              }),
              backgroundColor: const Color(0xFF1A1A2E),
              selectedColor: widget.accent.withValues(alpha: 0.3),
              labelStyle: TextStyle(
                color: isSelected
                    ? widget.accentBright
                    : Colors.white54,
                fontSize: 12,
              ),
              checkmarkColor: widget.accentBright,
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        // Kategorie
        TextField(
          controller: _categoryCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Kategorie (optional)',
            hintText: 'z.B. Doku, Vortrag, Interview',
            labelStyle: const TextStyle(color: Colors.white54),
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white12),
            ),
          ),
        ),
        if (_saveError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_saveError!,
                style: const TextStyle(
                    color: Colors.orange, fontSize: 12)),
          ),
      ]),
    );
  }

  List<Widget> _buildActions() {
    final cancelBtn = TextButton(
      onPressed: (_saving || _suggesting) ? null : () => Navigator.pop(context),
      child:
          const Text('Abbrechen', style: TextStyle(color: Colors.white54)),
    );
    if (_step == _VStep.input) {
      return [
        cancelBtn,
        ElevatedButton(
          onPressed: _onSearch,
          style: ElevatedButton.styleFrom(backgroundColor: widget.accent),
          child: const Text('Suchen / Laden',
              style: TextStyle(color: Colors.white)),
        ),
      ];
    }
    if (_step == _VStep.configuring) {
      return [
        cancelBtn,
        ElevatedButton(
          onPressed: (_saving || _suggesting || _selectedWorlds.isEmpty)
              ? null
              : _save,
          style: ElevatedButton.styleFrom(backgroundColor: widget.accent),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Einpflegen',
                  style: TextStyle(color: Colors.white)),
        ),
      ];
    }
    return [cancelBtn];
  }
}

// ── Einzelne Suchergebnis-Karte ──────────────────────────────────────────────

class _YoutubeResultCard extends StatelessWidget {
  final YoutubeSearchResult result;
  final Color accent;
  final Color accentBright;
  final VoidCallback onPreview;
  final VoidCallback onSelect;

  const _YoutubeResultCard({
    required this.result,
    required this.accent,
    required this.accentBright,
    required this.onPreview,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final thumb = result.thumbnailUrl.isNotEmpty
        ? result.thumbnailUrl
        : 'https://img.youtube.com/vi/${result.videoId}/mqdefault.jpg';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: Row(children: [
        GestureDetector(
          onTap: onPreview,
          child: Stack(alignment: Alignment.center, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                thumb,
                width: 88,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 88,
                  height: 50,
                  color: Colors.white12,
                  child: const Icon(Icons.videocam_rounded,
                      color: Colors.white38, size: 20),
                ),
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 18),
            ),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.title,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (result.channelTitle?.isNotEmpty == true)
                  Text(result.channelTitle!,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 10)),
              ]),
        ),
        const SizedBox(width: 6),
        ElevatedButton(
          onPressed: onSelect,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Auswaehlen',
              style: TextStyle(color: Colors.white, fontSize: 11)),
        ),
      ]),
    );
  }
}

// ── Video-Vorschau-Dialog (inline YoutubePlayer) ─────────────────────────────

class _VideoPreviewDialog extends StatefulWidget {
  final String videoId;
  final String title;
  final Color accent;
  const _VideoPreviewDialog(
      {required this.videoId, required this.title, required this.accent});

  @override
  State<_VideoPreviewDialog> createState() => _VideoPreviewDialogState();
}

class _VideoPreviewDialogState extends State<_VideoPreviewDialog> {
  late YoutubePlayerController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _ctrl,
        showVideoProgressIndicator: true,
        progressIndicatorColor: widget.accent,
      ),
      builder: (ctx, player) => Dialog(
        backgroundColor: Colors.black,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          player,
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 4, 4),
            child: Row(children: [
              Expanded(
                child: Text(
                  widget.title,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Schliessen',
                    style:
                        TextStyle(color: Colors.white54, fontSize: 12)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
