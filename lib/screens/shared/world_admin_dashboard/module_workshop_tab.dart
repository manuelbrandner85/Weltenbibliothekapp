// v128 (Task 3): MODUL-WERKSTATT -- KI-gestuetzte Modul-Erstellung im
// Admin-Dashboard. KEIN Code-Wissen noetig.
part of '../world_admin_dashboard.dart';

class _ModuleWorkshopTab extends StatefulWidget {
  final Color accent;
  final Color accentBright;
  const _ModuleWorkshopTab({
    required this.accent,
    required this.accentBright,
  });

  @override
  State<_ModuleWorkshopTab> createState() => _ModuleWorkshopTabState();
}

class _ModuleWorkshopTabState extends State<_ModuleWorkshopTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _world = 'vorhang'; // 'vorhang' | 'ursprung' | 'materie' | 'energie'

  // Tab 1 -- Neu erstellen
  final _topicCtrl = TextEditingController();
  final _hintCtrl = TextEditingController();
  List<String> _suggestions = const [];
  bool _topicsLoading = false;
  bool _generating = false;
  Map<String, dynamic>? _draftModule;
  String? _draftBranchHint;

  // Tab 2 -- Bestehende editieren
  List<Map<String, dynamic>> _existingModules = const [];
  bool _existingLoading = false;
  String? _existingError;
  bool _orderDirty = false; // W2: Reihenfolge geaendert?
  bool _orderSaving = false;

  // Tab 3 -- KI-Vorschlaege (A/B/C)
  List<Map<String, dynamic>> _kiSuggestions = const [];
  bool _suggestionsLoading = false;
  bool _scanning = false;
  String? _suggestionsError;
  final Set<String> _suggestionBusy = {};

  // W7: Auto-Scan-Konfiguration
  bool _autoScanEnabled = true;
  bool _autoScanLoading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadExisting();
    _loadSuggestions();
    _loadScanConfig();
  }

  Future<void> _loadScanConfig() async {
    final cfg = await WorldAdminServiceV162.getScanConfig();
    if (!mounted || cfg == null) return;
    setState(() => _autoScanEnabled = cfg['enabled'] as bool? ?? true);
  }

  Future<void> _toggleAutoScan(bool value) async {
    setState(() => _autoScanLoading = true);
    final ok = await WorldAdminServiceV162.setScanConfig(enabled: value);
    if (!mounted) return;
    setState(() {
      _autoScanLoading = false;
      if (ok) _autoScanEnabled = value;
    });
    _snack(ok
        ? (value ? 'Auto-Scan aktiviert' : 'Auto-Scan deaktiviert')
        : 'Aenderung fehlgeschlagen');
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    _hintCtrl.dispose();
    _tabs.dispose();
    super.dispose();
  }

  // ── Daten-Laden ──────────────────────────────────────────────────────

  Future<void> _loadExisting() async {
    setState(() {
      _existingLoading = true;
      _existingError = null;
    });
    try {
      final list =
          await WorldAdminServiceV162.listWorkshopModules(world: _world);
      if (!mounted) return;
      setState(() {
        _existingModules = list;
        _existingLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _existingError = 'Fehler: $e';
        _existingLoading = false;
      });
    }
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _suggestionsLoading = true;
      _suggestionsError = null;
    });
    try {
      final list =
          await WorldAdminServiceV162.getModuleSuggestions(world: _world);
      if (!mounted) return;
      setState(() {
        _kiSuggestions = list;
        _suggestionsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _suggestionsError = 'Fehler: $e';
        _suggestionsLoading = false;
      });
    }
  }

  Future<void> _runScan(List<String> modes) async {
    setState(() => _scanning = true);
    final res = await WorldAdminServiceV162.scanModuleSuggestions(
      world: _world,
      modes: modes,
    );
    if (!mounted) return;
    setState(() => _scanning = false);
    if (res == null || res['success'] != true) {
      _snack('Scan fehlgeschlagen (KI evtl. nicht erreichbar)');
      return;
    }
    final c = (res['created'] as Map?) ?? const {};
    _snack(
        'Scan fertig: ${c['new'] ?? 0} neu, ${c['improve'] ?? 0} Verbesserung(en), ${c['quality'] ?? 0} Qualitaets-Hinweis(e)');
    await _loadSuggestions();
  }

  Future<void> _acceptSuggestion(String id) async {
    setState(() => _suggestionBusy.add(id));
    final res = await WorldAdminServiceV162.acceptModuleSuggestion(id);
    if (!mounted) return;
    setState(() => _suggestionBusy.remove(id));
    if (res['success'] == true) {
      _snack(
          'Uebernommen: ${res['module_code'] ?? res['action'] ?? 'erledigt'}');
      await _loadSuggestions();
      await _loadExisting();
    } else {
      _snack('Annehmen fehlgeschlagen: ${res['error'] ?? ''}');
    }
  }

  Future<void> _rejectSuggestion(String id) async {
    setState(() => _suggestionBusy.add(id));
    final ok = await WorldAdminServiceV162.rejectModuleSuggestion(id);
    if (!mounted) return;
    setState(() => _suggestionBusy.remove(id));
    if (ok) {
      await _loadSuggestions();
    } else {
      _snack('Ablehnen fehlgeschlagen');
    }
  }

  Future<void> _suggestTopics() async {
    setState(() => _topicsLoading = true);
    final list = await WorldAdminServiceV162.getModuleTopicSuggestions(
      world: _world,
      hint: _hintCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _suggestions = list;
      _topicsLoading = false;
    });
    if (list.isEmpty) {
      _snack('Keine Themenvorschlaege erhalten (KI evtl. nicht erreichbar)');
    }
  }

  Future<void> _generateDraft() async {
    final topic = _topicCtrl.text.trim();
    if (topic.length < 3) {
      _snack('Bitte ein Thema eingeben (min. 3 Zeichen)');
      return;
    }
    setState(() => _generating = true);
    final mod = await WorldAdminServiceV162.generateModule(
      world: _world,
      topic: topic,
      branch: _draftBranchHint,
    );
    if (!mounted) return;
    setState(() {
      _draftModule = mod;
      _generating = false;
    });
    if (mod == null) {
      _snack('Modul-Generierung fehlgeschlagen');
    }
  }

  Future<void> _expandDraft() async {
    if (_draftModule == null) return;
    setState(() => _generating = true);
    final mod = await WorldAdminServiceV162.expandModule(
      world: _world,
      current: _draftModule!,
    );
    if (!mounted) return;
    setState(() {
      if (mod != null) _draftModule = mod;
      _generating = false;
    });
    if (mod == null) _snack('Ausarbeitung fehlgeschlagen');
  }

  Future<void> _saveDraft({String? editCode}) async {
    if (_draftModule == null) return;
    final saveRes = await WorldAdminServiceV162.saveModule(
      world: _world,
      module: _draftModule!,
      editCode: editCode,
    );
    if (!mounted) return;
    if (saveRes['success'] == true) {
      _snack(
          'Modul ${saveRes['action'] == 'created' ? 'erstellt' : 'aktualisiert'}: ${saveRes['module_code']}');
      setState(() {
        _draftModule = null;
        _topicCtrl.clear();
        _draftBranchHint = null;
        _activeEditCode = null;
      });
      await _loadExisting();
      _tabs.animateTo(1);
    } else {
      final errs = (saveRes['errors'] as List?)?.join('\n') ?? 'Unbekannt';
      await _showErrorDialog('Modul konnte nicht gespeichert werden', errs);
    }
  }

  // W4: Modul uebersetzen -> als NEUES Modul-Entwurf laden (kein editCode).
  Future<void> _translateDraft(Map<String, dynamic> m) async {
    const langs = {
      'en': 'Englisch',
      'tr': 'Tuerkisch',
      'fr': 'Franzoesisch',
      'es': 'Spanisch',
      'ru': 'Russisch',
      'ar': 'Arabisch',
    };
    final lang = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: const Color(0xFF1A1A30),
        title: const Text('In welche Sprache uebersetzen?',
            style: TextStyle(color: Colors.white, fontSize: 15)),
        children: [
          for (final e in langs.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, e.key),
              child: Text(e.value,
                  style: const TextStyle(color: Colors.white70)),
            ),
        ],
      ),
    );
    if (lang == null || !mounted) return;
    setState(() => _generating = true);
    final translated = await WorldAdminServiceV162.translateModule(
      module: m,
      targetLang: lang,
    );
    if (!mounted) return;
    setState(() {
      _generating = false;
      if (translated != null) {
        // Als neues Modul behandeln (neuer Code), Titel mit Sprach-Tag.
        translated['title'] =
            '${translated['title'] ?? ''} [${lang.toUpperCase()}]';
        _draftModule = translated;
        _activeEditCode = null;
      }
    });
    _snack(translated != null
        ? 'Uebersetzt - als neues Modul speicherbar'
        : 'Uebersetzung fehlgeschlagen');
  }

  // W6: Echte Vorschau im Reader-Layout (Markdown gerendert).
  void _showModulePreview(Map<String, dynamic> m) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E0E18),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ModulePreviewSheet(m: m, accent: widget.accentBright),
    );
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: const Color(0xFF1A1A30),
      ),
    );
  }

  Future<void> _showErrorDialog(String title, String body) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A30),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Text(body,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: TextStyle(color: widget.accentBright)),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildWorldSwitcher(),
        const SizedBox(height: 4),
        _buildLogicHint(),
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: widget.accentBright,
          labelColor: widget.accentBright,
          unselectedLabelColor: Colors.white38,
          tabs: [
            const Tab(
                icon: Icon(Icons.auto_awesome, size: 16),
                text: 'Neu erstellen'),
            const Tab(
                icon: Icon(Icons.edit_note, size: 16), text: 'Bestehende'),
            Tab(
              icon: const Icon(Icons.lightbulb_outline, size: 16),
              text: _kiSuggestions.isEmpty
                  ? 'Vorschlaege'
                  : 'Vorschlaege (${_kiSuggestions.length})',
            ),
          ],
        ),
        const Divider(color: Colors.white10, height: 1),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _buildCreateTab(),
              _buildExistingTab(),
              _buildSuggestionsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorldSwitcher() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('Welt:',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          _worldChip('vorhang', 'Vorhang'),
          _worldChip('ursprung', 'Ursprung'),
          _worldChip('materie', 'Materie'),
          _worldChip('energie', 'Energie'),
        ],
      ),
    );
  }

  Widget _worldChip(String value, String label) {
    final active = _world == value;
    return InkWell(
      onTap: () {
        if (_world == value) return;
        setState(() {
          _world = value;
          _draftModule = null;
          _draftBranchHint = null;
          _suggestions = const [];
          _activeEditCode = null;
        });
        _loadExisting();
        _loadSuggestions();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? widget.accentBright.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? widget.accentBright.withValues(alpha: 0.6)
                : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? widget.accentBright : Colors.white60,
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLogicHint() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline, color: Colors.amber, size: 14),
        const SizedBox(width: 6),
        const Expanded(
          child: Text(
            'Hier kannst du Text-Module (Theorie, Fallstudien, Uebungen) erstellen. '
            'Neue interaktive Tools oder Rechner brauchen ein App-Update durch den Entwickler.',
            style: TextStyle(color: Colors.amber, fontSize: 11),
          ),
        ),
      ]),
    );
  }

  // ── Tab: Neu erstellen ──────────────────────────────────────────────

  Widget _buildCreateTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('1. Thema waehlen'),
        const SizedBox(height: 8),
        TextField(
          controller: _topicCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDeco('Worum soll das neue Modul gehen?'),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _hintCtrl,
              style: const TextStyle(color: Colors.white),
              decoration:
                  _inputDeco('Stichwort fuer KI-Vorschlaege (optional)'),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _topicsLoading ? null : _suggestTopics,
            icon: _topicsLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome, size: 14),
            label: const Text('KI-Vorschlaege'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.accent.withValues(alpha: 0.4),
              foregroundColor: Colors.white,
            ),
          ),
        ]),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _suggestions
                .map((s) => ActionChip(
                      label:
                          Text(s, style: const TextStyle(color: Colors.white)),
                      backgroundColor: widget.accent.withValues(alpha: 0.2),
                      side: BorderSide(
                          color: widget.accentBright.withValues(alpha: 0.4)),
                      onPressed: () => setState(() => _topicCtrl.text = s),
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: 20),
        _sectionHeader('2. Modul generieren'),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _generating ? null : _generateDraft,
          icon: _generating
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.auto_awesome_motion),
          label: const Text('Neues Modul aus Thema erstellen'),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.accentBright.withValues(alpha: 0.7),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(44),
          ),
        ),
        if (_draftModule != null) ...[
          const SizedBox(height: 20),
          _sectionHeader('3. Vorschau & Speichern'),
          const SizedBox(height: 8),
          _buildDraftPreview(),
        ],
      ],
    );
  }

  Widget _buildDraftPreview() {
    final m = _draftModule!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _previewField('Titel', m['title']?.toString() ?? '',
              onChanged: (v) => setState(() => m['title'] = v)),
          _previewField('Untertitel', m['subtitle']?.toString() ?? '',
              onChanged: (v) => setState(() => m['subtitle'] = v)),
          _previewField('Branch', m['branch']?.toString() ?? '',
              onChanged: (v) => setState(() => m['branch'] = v)),
          _previewField('XP-Belohnung', '${m['xp_reward'] ?? 100}',
              onChanged: (v) =>
                  setState(() => m['xp_reward'] = int.tryParse(v) ?? 100)),
          _previewField('Theorie', m['theory_content']?.toString() ?? '',
              multiline: true,
              onChanged: (v) => setState(() => m['theory_content'] = v)),
          _previewField('Fallstudie', m['case_study']?.toString() ?? '',
              multiline: true,
              onChanged: (v) => setState(() => m['case_study'] = v)),
          _previewField('Uebung', m['exercise_description']?.toString() ?? '',
              multiline: true,
              onChanged: (v) => setState(() => m['exercise_description'] = v)),
          const SizedBox(height: 14),
          _buildQuizEditor(m), // W1
          const SizedBox(height: 14),
          _buildSourcesEditor(m), // W8
          const SizedBox(height: 12),
          // W6 + W4: Vorschau + Uebersetzen
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showModulePreview(m),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('Vorschau'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _generating ? null : () => _translateDraft(m),
                icon: const Icon(Icons.translate, size: 16),
                label: const Text('Uebersetzen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber,
                  side: BorderSide(color: Colors.amber.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _generating ? null : _expandDraft,
                icon: const Icon(Icons.psychology, size: 16),
                label: const Text('Von KI weiter ausarbeiten'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: widget.accentBright,
                  side: BorderSide(color: widget.accent),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _generating
                    ? null
                    : () => _saveDraft(editCode: _activeEditCode),
                icon: const Icon(Icons.save, size: 16),
                label: Text(_activeEditCode != null
                    ? 'Aenderungen speichern'
                    : 'Speichern und Veroeffentlichen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => setState(() {
              _draftModule = null;
              _activeEditCode = null;
            }),
            icon: const Icon(Icons.delete_outline,
                size: 14, color: Colors.white54),
            label: const Text('Entwurf verwerfen',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // W1: Quiz-Editor. test_questions = [{question, options:[...], answer_index}]
  Widget _buildQuizEditor(Map<String, dynamic> m) {
    final raw = m['test_questions'];
    final questions = (raw is List)
        ? raw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
    m['test_questions'] = questions; // sicherstellen, dass es eine Liste ist

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.quiz_outlined, size: 14, color: widget.accentBright),
            const SizedBox(width: 6),
            Text('Quiz-Fragen (${questions.length})',
                style: TextStyle(
                    color: widget.accentBright,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => setState(() {
                questions.add({
                  'question': '',
                  'options': ['', '', '', ''],
                  'answer_index': 0,
                });
              }),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Frage', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(foregroundColor: widget.accentBright),
            ),
          ]),
          for (int i = 0; i < questions.length; i++)
            _buildQuestionCard(questions, i),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(List<Map<String, dynamic>> questions, int i) {
    final q = questions[i];
    final options = (q['options'] is List)
        ? (q['options'] as List).map((e) => e.toString()).toList()
        : <String>['', '', '', ''];
    q['options'] = options;
    final answerIdx = (q['answer_index'] is int) ? q['answer_index'] as int : 0;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: TextFormField(
                initialValue: q['question']?.toString() ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: _inputDeco('Frage ${i + 1}'),
                onChanged: (v) => q['question'] = v,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: Colors.white38),
              onPressed: () => setState(() => questions.removeAt(i)),
            ),
          ]),
          const SizedBox(height: 4),
          for (int o = 0; o < options.length; o++)
            Row(children: [
              Radio<int>(
                value: o,
                groupValue: answerIdx,
                onChanged: (v) => setState(() => q['answer_index'] = v ?? 0),
                visualDensity: VisualDensity.compact,
                activeColor: Colors.green,
              ),
              Expanded(
                child: TextFormField(
                  initialValue: options[o],
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  decoration: _inputDeco('Antwort ${o + 1}'),
                  onChanged: (v) => options[o] = v,
                ),
              ),
            ]),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Gruener Punkt = richtige Antwort',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3), fontSize: 9)),
          ),
        ],
      ),
    );
  }

  // W8: Quellen-Editor. sources = [{title, url}]
  Widget _buildSourcesEditor(Map<String, dynamic> m) {
    final raw = m['sources'];
    final sources = (raw is List)
        ? raw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
    m['sources'] = sources;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.menu_book_outlined, size: 14, color: widget.accentBright),
            const SizedBox(width: 6),
            Text('Quellen (${sources.length})',
                style: TextStyle(
                    color: widget.accentBright,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
              onPressed: () =>
                  setState(() => sources.add({'title': '', 'url': ''})),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Quelle', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(foregroundColor: widget.accentBright),
            ),
          ]),
          for (int i = 0; i < sources.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: sources[i]['title']?.toString() ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: _inputDeco('Titel'),
                    onChanged: (v) => sources[i]['title'] = v,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: sources[i]['url']?.toString() ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    decoration: _inputDeco('URL'),
                    onChanged: (v) => sources[i]['url'] = v,
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.close, size: 16, color: Colors.white38),
                  onPressed: () => setState(() => sources.removeAt(i)),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _previewField(String label, String value,
      {bool multiline = false, required ValueChanged<String> onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: widget.accentBright,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: value,
            maxLines: multiline ? null : 1,
            minLines: multiline ? 4 : 1,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDeco(null),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ── Tab: Bestehende editieren ───────────────────────────────────────

  Widget _buildExistingTab() {
    if (_existingLoading) {
      return Center(
          child: CircularProgressIndicator(color: widget.accentBright));
    }
    if (_existingError != null) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(_existingError!,
            style: const TextStyle(color: Colors.redAccent)),
      ));
    }
    if (_existingModules.isEmpty) {
      return const Center(
        child:
            Text('Noch keine Module', style: TextStyle(color: Colors.white38)),
      );
    }
    final modules = List<Map<String, dynamic>>.from(_existingModules);
    return Column(
      children: [
        if (_orderDirty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _orderSaving ? null : _saveOrder,
                icon: _orderSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, size: 16),
                label: const Text('Neue Reihenfolge speichern'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: modules.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _existingModules.removeAt(oldIndex);
                (_existingModules as List).insert(newIndex, item);
                _orderDirty = true;
              });
            },
            itemBuilder: (_, i) {
              final m = modules[i];
              final code = (m['module_code'] as String?) ?? '';
              return Container(
                key: ValueKey(code.isNotEmpty ? code : 'mod_$i'),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.drag_handle,
                      color: Colors.white.withValues(alpha: 0.3), size: 18),
                  title: Text(
                    (m['title'] as String?) ?? code,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  subtitle: Text(
                    '$code - ${m['branch']}',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Colors.redAccent),
                      tooltip: 'Loeschen',
                      onPressed: () => _deleteExisting(m),
                    ),
                    Icon(Icons.chevron_right,
                        color: widget.accentBright.withValues(alpha: 0.6)),
                  ]),
                  onTap: () => _editExisting(m),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _saveOrder() async {
    setState(() => _orderSaving = true);
    final order = <Map<String, dynamic>>[];
    for (var i = 0; i < _existingModules.length; i++) {
      final code = _existingModules[i]['module_code'];
      if (code != null) {
        order.add({'module_code': code, 'branch_order': i + 1});
      }
    }
    final ok = await WorldAdminServiceV162.reorderWorkshopModules(
      world: _world,
      order: order,
    );
    if (!mounted) return;
    setState(() {
      _orderSaving = false;
      if (ok) _orderDirty = false;
    });
    _snack(ok ? 'Reihenfolge gespeichert' : 'Speichern fehlgeschlagen');
    if (ok) await _loadExisting();
  }

  Future<void> _deleteExisting(Map<String, dynamic> m) async {
    final code = (m['module_code'] as String?) ?? '';
    if (code.isEmpty) return;
    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A30),
            title: Text('Modul $code loeschen?',
                style: const TextStyle(color: Colors.white)),
            content: const Text(
                'Das Modul wird endgueltig entfernt. Nutzer-Fortschritt dazu geht verloren.',
                style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Abbrechen',
                      style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Loeschen')),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    final deleted = await WorldAdminServiceV162.deleteWorkshopModule(
      world: _world,
      moduleCode: code,
    );
    if (!mounted) return;
    _snack(deleted ? 'Modul geloescht' : 'Loeschen fehlgeschlagen (nur Root-Admin)');
    if (deleted) await _loadExisting();
  }

  void _editExisting(Map<String, dynamic> m) {
    setState(() {
      _draftModule = Map<String, dynamic>.from(m);
      _tabs.animateTo(0);
    });
    // Wir nutzen denselben Vorschau-Block, plus "Speichern" wird zu UPDATE
    // weil _draftEditCode != null sein wird.
    final code = m['module_code'] as String?;
    if (code != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showEditConfirmDialog(code);
      });
    }
  }

  Future<void> _showEditConfirmDialog(String code) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A30),
        title: Text('Modul $code editieren',
            style: const TextStyle(color: Colors.white)),
        content: const Text(
          'Du editierst ein veroeffentlichtes Modul. Aenderungen sind sofort fuer alle User sichtbar.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.accent,
            ),
            child: const Text('Weiter'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      // Speicher-Button wechselt zu UPDATE-Modus via _saveDraft(editCode: code).
      // Wir merken uns den Edit-Code via state-Variable.
      _activeEditCode = code;
      setState(() {});
    } else {
      // Abbrechen -> Draft verwerfen
      setState(() => _draftModule = null);
    }
  }

  String? _activeEditCode;

  // ── Tab: KI-Vorschlaege (A/B/C + D) ─────────────────────────────────

  Widget _buildSuggestionsTab() {
    return Column(
      children: [
        // Scan-Buttons (manueller Trigger statt Cron)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.search, size: 14, color: widget.accentBright),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'KI prueft den Modul-Bestand und macht Vorschlaege. Du bestaetigst, was umgesetzt wird.',
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ),
              ]),
              // W7: Auto-Scan (Cron) an/aus
              Row(children: [
                Icon(Icons.schedule, size: 14, color: widget.accentBright),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('Taeglicher Auto-Scan (KI schlaegt automatisch vor)',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
                Switch(
                  value: _autoScanEnabled,
                  onChanged: _autoScanLoading ? null : _toggleAutoScan,
                  activeColor: widget.accentBright,
                ),
              ]),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                _scanChip('Neue Module', ['new'], Icons.add_circle_outline),
                _scanChip('Verbesserungen', ['improve'], Icons.upgrade),
                _scanChip('Qualitaets-Check', ['quality'], Icons.fact_check),
                _scanChip(
                    'Alles pruefen', ['new', 'improve', 'quality'], Icons.bolt),
              ]),
              const SizedBox(height: 8),
              // Vorschlag D: Tool anfragen (LOGIK-Modul)
              OutlinedButton.icon(
                onPressed: _scanning ? null : _showToolRequestDialog,
                icon: const Icon(Icons.build_circle_outlined, size: 16),
                label: const Text('Neues interaktives Tool anfragen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber,
                  side: BorderSide(color: Colors.amber.withValues(alpha: 0.5)),
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
            ],
          ),
        ),
        if (_scanning)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: widget.accentBright),
              ),
              const SizedBox(width: 8),
              const Text('KI arbeitet ... (kann 10-30s dauern)',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
            ]),
          ),
        const Divider(color: Colors.white10, height: 1),
        Expanded(child: _buildSuggestionsList()),
      ],
    );
  }

  Widget _scanChip(String label, List<String> modes, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 14, color: widget.accentBright),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: widget.accent.withValues(alpha: 0.18),
      side: BorderSide(color: widget.accentBright.withValues(alpha: 0.4)),
      onPressed: _scanning ? null : () => _runScan(modes),
    );
  }

  Widget _buildSuggestionsList() {
    if (_suggestionsLoading) {
      return Center(
          child: CircularProgressIndicator(color: widget.accentBright));
    }
    if (_suggestionsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(_suggestionsError!,
              style: const TextStyle(color: Colors.redAccent)),
        ),
      );
    }
    if (_kiSuggestions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Noch keine Vorschlaege.\nTippe oben auf einen Scan-Button.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _kiSuggestions.length,
      itemBuilder: (_, i) => _buildSuggestionCard(_kiSuggestions[i]),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> s) {
    final id = s['id']?.toString() ?? '';
    final kind = s['kind']?.toString() ?? 'new';
    final busy = _suggestionBusy.contains(id);
    final findings =
        (s['quality_findings'] as List?)?.map((e) => e.toString()).toList() ??
            const [];

    // Kopfzeile je nach Art
    late final String badge;
    late final Color badgeColor;
    late final IconData badgeIcon;
    switch (kind) {
      case 'improve':
        badge = 'VERBESSERUNG';
        badgeColor = Colors.lightBlueAccent;
        badgeIcon = Icons.upgrade;
        break;
      case 'quality':
        badge = 'QUALITAET';
        badgeColor = Colors.orangeAccent;
        badgeIcon = Icons.fact_check;
        break;
      default:
        badge = 'NEUES MODUL';
        badgeColor = Colors.greenAccent;
        badgeIcon = Icons.add_circle_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(badgeIcon, size: 13, color: badgeColor),
            const SizedBox(width: 5),
            Text(badge,
                style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            const Spacer(),
            if (s['target_module_code'] != null)
              Text('${s['target_module_code']}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ]),
          const SizedBox(height: 6),
          Text(
            (s['title'] as String?) ?? '(ohne Titel)',
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          if (s['branch'] != null) ...[
            const SizedBox(height: 2),
            Text('Branch: ${s['branch']}',
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
          if ((s['rationale'] as String?)?.isNotEmpty ?? false) ...[
            const SizedBox(height: 6),
            Text(s['rationale'].toString(),
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontStyle: FontStyle.italic)),
          ],
          // Qualitaets-Findings als Liste
          if (findings.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...findings.map((f) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ',
                            style: TextStyle(
                                color: Colors.orangeAccent, fontSize: 12)),
                        Expanded(
                          child: Text(f,
                              style: const TextStyle(
                                  color: Colors.orangeAccent, fontSize: 12)),
                        ),
                      ]),
                )),
          ],
          // Inhalt-Vorschau (new/improve) ausklappbar
          if (kind != 'quality' &&
              ((s['theory_content'] as String?)?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: Text('Inhalt ansehen',
                    style: TextStyle(color: widget.accentBright, fontSize: 12)),
                iconColor: widget.accentBright,
                collapsedIconColor: widget.accentBright,
                children: [
                  _previewReadonly('Theorie', s['theory_content']),
                  _previewReadonly('Fallstudie', s['case_study']),
                  _previewReadonly('Uebung', s['exercise_description']),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: busy ? null : () => _acceptSuggestion(id),
                icon: busy
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check, size: 15),
                label: Text(kind == 'quality' ? 'Erledigt' : 'Uebernehmen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: busy ? null : () => _rejectSuggestion(id),
              icon: const Icon(Icons.close, size: 15),
              label: const Text('Ablehnen'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white54,
                side: const BorderSide(color: Colors.white24),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _previewReadonly(String label, dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: widget.accentBright,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(text,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                  height: 1.35)),
        ],
      ),
    );
  }

  // Vorschlag D: Tool-Anfrage-Dialog
  Future<void> _showToolRequestDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A30),
        title: const Text('Neues interaktives Tool anfragen',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tools/Rechner/Spiele brauchen echten Code + App-Update. '
                'Diese Anfrage erstellt ein GitHub-Issue fuer den Entwickler/Claude Code.',
                style: TextStyle(color: Colors.amber, fontSize: 11),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco('Kurzer Titel (z.B. "Atem-Timer")'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco('Was soll das Tool koennen?'),
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child:
                const Text('Anfragen', style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
    if (submitted != true) {
      titleCtrl.dispose();
      descCtrl.dispose();
      return;
    }
    final res = await WorldAdminServiceV162.requestTool(
      title: titleCtrl.text.trim(),
      description: descCtrl.text.trim(),
      world: _world,
    );
    titleCtrl.dispose();
    descCtrl.dispose();
    if (!mounted) return;
    if (res['success'] == true) {
      if (res['auto_created'] == true && res['issue_url'] != null) {
        _snack('GitHub-Issue erstellt: ${res['issue_url']}');
      } else if (res['prefill_url'] != null) {
        await _showInfoDialog(
          'Issue oeffnen',
          'Tippe auf den Link, um das vorbefuellte GitHub-Issue zu oeffnen und abzuschicken:\n\n${res['prefill_url']}',
        );
      } else {
        _snack('Tool-Anfrage gespeichert');
      }
    } else {
      _snack('Tool-Anfrage fehlgeschlagen: ${res['error'] ?? ''}');
    }
  }

  Future<void> _showInfoDialog(String title, String body) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A30),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: SelectableText(body,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: TextStyle(color: widget.accentBright)),
          ),
        ],
      ),
    );
  }

  // ── Hilfen ──────────────────────────────────────────────────────────

  Widget _sectionHeader(String text) => Text(
        text,
        style: TextStyle(
          color: widget.accentBright,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      );

  InputDecoration _inputDeco(String? hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      );
}

// W6: Modul-Vorschau im Reader-Layout (Markdown gerendert wie im Lern-Screen).
class _ModulePreviewSheet extends StatelessWidget {
  final Map<String, dynamic> m;
  final Color accent;
  const _ModulePreviewSheet({required this.m, required this.accent});

  @override
  Widget build(BuildContext context) {
    final tq = (m['test_questions'] is List)
        ? (m['test_questions'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList()
        : <Map<String, dynamic>>[];
    final sources = (m['sources'] is List)
        ? (m['sources'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList()
        : <Map<String, dynamic>>[];

    Widget section(String title, String body) {
      if (body.trim().isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          Text(title.toUpperCase(),
              style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5)),
          const SizedBox(height: 6),
          ChatMarkdownText(
            body,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, height: 1.5),
          ),
        ],
      );
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
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
          Row(children: [
            Icon(Icons.menu_book_rounded, color: accent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                (m['title'] as String?) ?? 'Vorschau',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ]),
          if ((m['subtitle'] as String?)?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Text(m['subtitle'].toString(),
                style: const TextStyle(color: Colors.white60, fontSize: 14)),
          ],
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            if ((m['branch'] as String?)?.isNotEmpty ?? false)
              _chip(m['branch'].toString(), accent),
            _chip('${m['xp_reward'] ?? 100} XP', Colors.amber),
          ]),
          section('Theorie', m['theory_content']?.toString() ?? ''),
          section('Fallstudie', m['case_study']?.toString() ?? ''),
          section('Uebung', m['exercise_description']?.toString() ?? ''),
          // Quiz
          if (tq.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('QUIZ (${tq.length})',
                style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5)),
            for (var i = 0; i < tq.length; i++) _quizPreview(tq[i], i),
          ],
          // Quellen
          if (sources.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('QUELLEN',
                style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5)),
            const SizedBox(height: 6),
            for (final s in sources)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '• ${s['title']}${(s['url']?.toString().isNotEmpty ?? false) ? " — ${s['url']}" : ""}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withValues(alpha: 0.4)),
        ),
        child: Text(label, style: TextStyle(color: c, fontSize: 11)),
      );

  Widget _quizPreview(Map<String, dynamic> q, int i) {
    final options = (q['options'] is List)
        ? (q['options'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final ans = (q['answer_index'] is int) ? q['answer_index'] as int : 0;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${i + 1}. ${q['question']}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          for (var o = 0; o < options.length; o++)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(children: [
                Icon(
                  o == ans
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 14,
                  color: o == ans ? Colors.green : Colors.white24,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(options[o],
                      style: TextStyle(
                          color: o == ans ? Colors.green : Colors.white60,
                          fontSize: 12)),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}
