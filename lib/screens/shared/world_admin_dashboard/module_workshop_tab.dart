// v128 (Task 3): MODUL-WERKSTATT -- KI-gestuetzte Modul-Erstellung im
// Admin-Dashboard. KEIN Code-Wissen noetig.
part of '../world_admin_dashboard.dart';

class _ModuleWorkshopTab extends StatefulWidget {
  final Color accent;
  final Color accentBright;
  final bool isRootAdmin;
  const _ModuleWorkshopTab({
    required this.accent,
    required this.accentBright,
    this.isRootAdmin = false,
  });

  @override
  State<_ModuleWorkshopTab> createState() => _ModuleWorkshopTabState();
}

class _ModuleWorkshopTabState extends State<_ModuleWorkshopTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _world = 'vorhang'; // 'vorhang' | 'ursprung' | 'materie' | 'energie'

  // Vorhang/Ursprung haben Lern-Module/Quiz UND koennen zusaetzlich Tools
  // bauen lassen. Dieser Schalter waehlt fuer diese Welten zwischen dem
  // Modul-Editor (false) und der Funktions-Werkstatt/Tools (true).
  bool _moduleWorldShowTools = false;

  // Tab 1 -- Neu erstellen
  final _topicCtrl = TextEditingController();
  final _hintCtrl = TextEditingController();
  final _themeCtrl = TextEditingController(); // Thema/Bereich (branch)
  List<String> _suggestions = const [];
  bool _topicsLoading = false;
  bool _generating = false;
  bool _newTheme = false; // komplett neues Thema?
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

  // W3/W5: Cover-Generierung + Undo laufend?
  bool _coverBusy = false;
  bool _undoBusy = false;

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
    _themeCtrl.dispose();
    _tabs.dispose();
    super.dispose();
  }

  // Bestehende Themen (Branches) der aktuellen Welt -- fuer Auswahl-Chips.
  List<String> get _existingBranches {
    final set = <String>{};
    for (final m in _existingModules) {
      final b = (m['branch'] as String?)?.trim();
      if (b != null && b.isNotEmpty) set.add(b);
    }
    return set.toList();
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
    final theme = _themeCtrl.text.trim();
    final mod = await WorldAdminServiceV162.generateModule(
      world: _world,
      topic: topic,
      branch: theme.isNotEmpty ? theme : _draftBranchHint,
      newTheme: _newTheme,
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

  // W3: Cover-Bereich (Bild + "per KI generieren").
  Widget _buildCoverSection(Map<String, dynamic> m) {
    final url = m['cover_image_url']?.toString() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (url.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.white10,
                  child: const Center(
                    child: Icon(Icons.broken_image,
                        color: Colors.white24, size: 32),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: _coverBusy ? null : () => _generateCover(m),
          icon: _coverBusy
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.image_outlined, size: 16),
          label: Text(url.isEmpty ? 'Cover per KI generieren' : 'Neues Cover'),
          style: OutlinedButton.styleFrom(
            foregroundColor: widget.accentBright,
            side: BorderSide(color: widget.accent),
            minimumSize: const Size.fromHeight(40),
          ),
        ),
      ],
    );
  }

  Future<void> _generateCover(Map<String, dynamic> m) async {
    final title = m['title']?.toString() ?? '';
    if (title.trim().isEmpty) {
      _snack('Bitte zuerst einen Titel');
      return;
    }
    setState(() => _coverBusy = true);
    final url = await WorldAdminServiceV162.generateModuleCover(
      world: _world,
      title: title,
      hint: m['subtitle']?.toString(),
    );
    if (!mounted) return;
    setState(() {
      _coverBusy = false;
      if (url != null) m['cover_image_url'] = url;
    });
    _snack(url != null
        ? 'Cover generiert (wird beim Speichern uebernommen)'
        : 'Cover-Generierung fehlgeschlagen');
  }

  // W5: Letzte Aenderung des aktuell editierten Moduls rueckgaengig machen.
  Future<void> _undoModule() async {
    final code = _activeEditCode;
    if (code == null) return;
    setState(() => _undoBusy = true);
    final ok = await WorldAdminServiceV162.undoModule(
      world: _world,
      moduleCode: code,
    );
    if (!mounted) return;
    setState(() => _undoBusy = false);
    if (ok) {
      _snack('Letzte Version wiederhergestellt');
      setState(() {
        _draftModule = null;
        _activeEditCode = null;
      });
      await _loadExisting();
      _tabs.animateTo(1);
    } else {
      _snack('Keine fruehere Version vorhanden');
    }
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

  /// Materie + Energie haben KEINE Lern-Module/Quiz, sondern interaktive
  /// Funktionen/Tools -> dort die Funktions-Werkstatt statt Quiz-Editor.
  bool get _isToolWorld => _world == 'materie' || _world == 'energie';

  @override
  Widget build(BuildContext context) {
    // Materie/Energie: nur Funktions-Werkstatt (keine Lern-Module).
    if (_isToolWorld) {
      return Column(
        children: [
          _buildWorldSwitcher(),
          const SizedBox(height: 4),
          Expanded(
            child: _FunctionWorkshop(
              key: ValueKey('fnws_$_world'),
              world: _world,
              accent: widget.accent,
              accentBright: widget.accentBright,
              isRootAdmin: widget.isRootAdmin,
            ),
          ),
        ],
      );
    }
    // Vorhang/Ursprung: Module ODER Tools (Umschalter). Im Tools-Modus die
    // gleiche Funktions-Werkstatt wie Materie/Energie -- inkl. KI-Tool-Vorschlaege.
    if (_moduleWorldShowTools) {
      return Column(
        children: [
          _buildWorldSwitcher(),
          const SizedBox(height: 4),
          _buildModuleWorldModeToggle(),
          const SizedBox(height: 4),
          Expanded(
            child: _FunctionWorkshop(
              key: ValueKey('fnws_$_world'),
              world: _world,
              accent: widget.accent,
              accentBright: widget.accentBright,
              isRootAdmin: widget.isRootAdmin,
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        _buildWorldSwitcher(),
        const SizedBox(height: 4),
        _buildModuleWorldModeToggle(),
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

  /// Umschalter fuer Vorhang/Ursprung: Lern-Module vs. interaktive Tools.
  /// Diese Welten haben Quiz-Module UND koennen Tools bauen lassen.
  Widget _buildModuleWorldModeToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        children: [
          _modeChip(
            label: 'Module & Quiz',
            icon: Icons.menu_book_rounded,
            active: !_moduleWorldShowTools,
            onTap: () {
              if (!_moduleWorldShowTools) return;
              setState(() => _moduleWorldShowTools = false);
            },
          ),
          const SizedBox(width: 8),
          _modeChip(
            label: 'Tools (KI baut)',
            icon: Icons.build_circle_outlined,
            active: _moduleWorldShowTools,
            onTap: () {
              if (_moduleWorldShowTools) return;
              setState(() => _moduleWorldShowTools = true);
            },
          ),
        ],
      ),
    );
  }

  Widget _modeChip({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? widget.accentBright.withValues(alpha: 0.16)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? widget.accentBright.withValues(alpha: 0.6)
                  : Colors.white12,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15,
                  color: active ? widget.accentBright : Colors.white54),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? widget.accentBright : Colors.white60,
                  fontSize: 12.5,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
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
          _moduleWorldShowTools = false;
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
        _sectionHeader('2. Bereich (Modul-Gruppe)'),
        const SizedBox(height: 4),
        Text(
          _newTheme
              ? 'Es wird ein komplett neuer Bereich angelegt.'
              : 'Das Thema wird automatisch in den passenden bestehenden Bereich '
                  'einsortiert (z.B. Machtpsychologie). Passt es zu keinem, entsteht ein neuer.',
          style: const TextStyle(color: Colors.white38, fontSize: 11, height: 1.3),
        ),
        const SizedBox(height: 6),
        Row(children: [
          Switch(
            value: _newTheme,
            onChanged: (v) => setState(() {
              _newTheme = v;
              if (v) _themeCtrl.clear();
            }),
            activeColor: widget.accentBright,
          ),
          const Expanded(
            child: Text('Als komplett neuen Bereich anlegen',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ]),
        TextField(
          controller: _themeCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDeco(_newTheme
              ? 'Name des neuen Bereichs (leer = KI waehlt)'
              : 'Bereich waehlen — leer = automatisch passend einsortieren'),
        ),
        if (!_newTheme && _existingBranches.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _existingBranches
                .map((b) => ActionChip(
                      label: Text(b,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11)),
                      backgroundColor: widget.accent.withValues(alpha: 0.18),
                      side: BorderSide(
                          color: widget.accentBright.withValues(alpha: 0.3)),
                      onPressed: () =>
                          setState(() => _themeCtrl.text = b),
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: 20),
        _sectionHeader('3. Modul generieren'),
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
          _sectionHeader('4. Vorschau & Speichern'),
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
          _buildCoverSection(m), // W3
          const SizedBox(height: 10),
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
          // W5: Undo nur beim Editieren eines bestehenden Moduls.
          if (_activeEditCode != null) ...[
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: _undoBusy ? null : _undoModule,
              icon: _undoBusy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.undo, size: 16),
              label: const Text('Letzte Aenderung rueckgaengig'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orangeAccent,
                side: BorderSide(color: Colors.orangeAccent.withValues(alpha: 0.5)),
              ),
            ),
          ],
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
            const SizedBox(height: 4),
            Builder(builder: (_) {
              final branch = s['branch'].toString();
              final rationale = (s['rationale'] as String?) ?? '';
              final isNewTheme = rationale.contains('NEUES THEMA') ||
                  (_existingBranches.isNotEmpty &&
                      !_existingBranches.contains(branch));
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isNewTheme ? Colors.purpleAccent : Colors.white24)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: (isNewTheme
                              ? Colors.purpleAccent
                              : Colors.white38)
                          .withValues(alpha: 0.4)),
                ),
                child: Text(
                  isNewTheme ? '🆕 Neues Thema: $branch' : 'Thema: $branch',
                  style: TextStyle(
                      color: isNewTheme
                          ? Colors.purpleAccent
                          : Colors.white60,
                      fontSize: 11,
                      fontWeight:
                          isNewTheme ? FontWeight.bold : FontWeight.normal),
                ),
              );
            }),
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
      if (res['pending_approval'] == true) {
        _snack(res['message']?.toString() ??
            'Zur Freigabe an den Root-Admin gesendet.');
      } else if (res['auto_created'] == true && res['issue_url'] != null) {
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

// ═══════════════════════════════════════════════════════════════════════════
// FUNKTIONS-WERKSTATT (Materie/Energie) — Funktion bauen lassen + Inhalte
// ═══════════════════════════════════════════════════════════════════════════
class _FunctionWorkshop extends StatefulWidget {
  final String world;
  final Color accent;
  final Color accentBright;
  final bool isRootAdmin;
  const _FunctionWorkshop({
    super.key,
    required this.world,
    required this.accent,
    required this.accentBright,
    this.isRootAdmin = false,
  });

  @override
  State<_FunctionWorkshop> createState() => _FunctionWorkshopState();
}

class _FunctionWorkshopState extends State<_FunctionWorkshop>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // Funktion-Tab
  bool _extend = false;
  final _fnTitle = TextEditingController();
  final _fnTarget = TextEditingController();
  final _fnDesc = TextEditingController();
  bool _requesting = false;
  String? _resultMsg;
  String? _resultUrl;

  // Inhalte-Tab
  List<Map<String, dynamic>> _contentTables = const [];
  String? _activeTable;
  List<Map<String, dynamic>> _rows = const [];
  List<String> _columns = const [];
  bool _contentLoading = false;

  // Tools-Tab (T1/T4)
  List<Map<String, dynamic>> _tools = const [];
  bool _toolsLoading = false;
  String _toolSearch = ''; // B1: Suche/Filter

  // KI & Status-Tab (T2/T3)
  List<Map<String, dynamic>> _toolSuggestions = const [];
  List<Map<String, dynamic>> _toolRequests = const [];
  bool _scanningTools = false;
  final Set<String> _toolSugBusy = {};

  // Freigaben: offene Admin-Anfragen, die der Root-Admin freigeben/ablehnen kann.
  List<Map<String, dynamic>> _toolApprovals = const [];
  final Set<String> _approvalBusy = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _loadTools();
    _loadContentTables();
    _loadToolSuggestions();
    _loadToolRequests();
    if (widget.isRootAdmin) _loadToolApprovals();
  }

  Future<void> _loadToolApprovals() async {
    // Welt-uebergreifend laden: der Root-Admin soll JEDE offene Admin-Anfrage
    // sehen, egal in welcher Welt er gerade steht.
    final a = await WorldAdminServiceV162.getToolApprovals('');
    if (!mounted) return;
    setState(() => _toolApprovals = a);
  }

  Future<void> _decideApproval(String id, bool approve) async {
    setState(() => _approvalBusy.add(id));
    final res = approve
        ? await WorldAdminServiceV162.approveToolRequest(id)
        : await WorldAdminServiceV162.rejectToolRequest(id);
    if (!mounted) return;
    setState(() => _approvalBusy.remove(id));
    if (res['success'] == true) {
      _snack(approve
          ? 'Freigegeben — Claude Code baut das Tool und oeffnet einen PR.'
          : 'Anfrage abgelehnt.');
      await _loadToolApprovals();
      await _loadToolRequests();
    } else {
      _snack('Aktion fehlgeschlagen: ${res['error'] ?? ''}',
          c: Colors.redAccent);
    }
  }

  Future<void> _loadToolSuggestions() async {
    final s = await WorldAdminServiceV162.getToolSuggestions(widget.world);
    if (!mounted) return;
    setState(() => _toolSuggestions = s);
  }

  Future<void> _loadToolRequests() async {
    final r = await WorldAdminServiceV162.getToolRequests(widget.world);
    if (!mounted) return;
    setState(() => _toolRequests = r);
  }

  Future<void> _scanTools() async {
    setState(() => _scanningTools = true);
    final n = await WorldAdminServiceV162.scanTools(widget.world);
    if (!mounted) return;
    setState(() => _scanningTools = false);
    _snack(n > 0 ? '$n neue Tool-Vorschlaege' : 'Keine neuen Vorschlaege');
    await _loadToolSuggestions();
  }

  Future<void> _acceptToolSuggestion(Map<String, dynamic> s) async {
    final id = s['id']?.toString() ?? '';
    setState(() => _toolSugBusy.add(id));
    final res = await WorldAdminServiceV162.acceptToolSuggestion(id);
    if (!mounted) return;
    setState(() => _toolSugBusy.remove(id));
    if (res['success'] == true) {
      _snack(res['auto_created'] == true
          ? 'Angenommen — Claude baut "${s['name']}".'
          : 'Angenommen (Issue manuell erstellen).');
      await _loadToolSuggestions();
      await _loadToolRequests();
      await _loadTools();
    } else {
      _snack('Annehmen fehlgeschlagen', c: Colors.redAccent);
    }
  }

  Future<void> _rejectToolSuggestion(Map<String, dynamic> s) async {
    final id = s['id']?.toString() ?? '';
    setState(() => _toolSugBusy.add(id));
    final ok = await WorldAdminServiceV162.rejectToolSuggestion(id);
    if (!mounted) return;
    setState(() => _toolSugBusy.remove(id));
    if (ok) _loadToolSuggestions();
  }

  Future<void> _loadTools() async {
    setState(() => _toolsLoading = true);
    final t = await WorldAdminServiceV162.getTools(widget.world);
    if (!mounted) return;
    setState(() {
      _tools = t;
      _toolsLoading = false;
    });
  }

  @override
  void dispose() {
    _fnTitle.dispose();
    _fnTarget.dispose();
    _fnDesc.dispose();
    _tabs.dispose();
    super.dispose();
  }

  void _snack(String m, {Color? c}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m), backgroundColor: c ?? const Color(0xFF1A1A30)));
  }

  bool _ideaBusy = false;

  // KI-Vorschlag holen und in die Felder einsetzen (neu ODER Verbesserung).
  Future<void> _suggestFunctionIdea() async {
    setState(() => _ideaBusy = true);
    final res = await WorldAdminServiceV162.getToolIdea(
      world: widget.world,
      mode: _extend ? 'extend' : 'new',
      target: _extend ? _fnTarget.text.trim() : null,
    );
    if (!mounted) return;
    setState(() => _ideaBusy = false);
    if (res != null) {
      setState(() {
        if ((res['title'] as String?)?.isNotEmpty ?? false) {
          _fnTitle.text = res['title'] as String;
        }
        if ((res['description'] as String?)?.isNotEmpty ?? false) {
          _fnDesc.text = res['description'] as String;
        }
      });
      _snack('KI-Vorschlag eingesetzt — du kannst ihn anpassen.');
    } else {
      _snack('Kein Vorschlag erhalten (KI evtl. ausgelastet)', c: Colors.orange);
    }
  }

  Future<void> _requestFunction() async {
    final title = _fnTitle.text.trim();
    final desc = _fnDesc.text.trim();
    if (title.length < 3 || desc.length < 10) {
      _snack('Titel (min. 3) und Beschreibung (min. 10 Zeichen) noetig');
      return;
    }
    setState(() {
      _requesting = true;
      _resultMsg = null;
      _resultUrl = null;
    });
    final res = await WorldAdminServiceV162.requestTool(
      title: title,
      description: desc,
      world: widget.world,
      mode: _extend ? 'extend' : 'new',
      target: _extend ? _fnTarget.text.trim() : null,
    );
    if (!mounted) return;
    setState(() => _requesting = false);
    if (res['success'] == true) {
      setState(() {
        _resultUrl = (res['issue_url'] ?? res['prefill_url'])?.toString();
        _resultMsg = res['pending_approval'] == true
            ? (res['message']?.toString() ??
                'Zur Freigabe an den Root-Admin gesendet. Das Tool wird nach Freigabe gebaut.')
            : res['auto_created'] == true
                ? 'Anfrage erstellt — Claude Code baut die Funktion und oeffnet einen PR.'
                : 'Anfrage vorbereitet — oeffne den Link und klicke "Submit".';
      });
      _fnTitle.clear();
      _fnDesc.clear();
      _fnTarget.clear();
    } else {
      _snack('Anfrage fehlgeschlagen: ${res['error'] ?? ''}', c: Colors.redAccent);
    }
  }

  Future<void> _loadContentTables() async {
    final t = await WorldAdminServiceV162.getContentTables(widget.world);
    if (!mounted) return;
    setState(() => _contentTables = t);
  }

  Future<void> _loadRows(String table) async {
    setState(() {
      _activeTable = table;
      _contentLoading = true;
    });
    final data = await WorldAdminServiceV162.getContentRows(
        world: widget.world, table: table);
    if (!mounted) return;
    setState(() {
      _rows = (data['rows'] as List).cast<Map<String, dynamic>>();
      _columns = (data['columns'] as List).cast<String>();
      _contentLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabs,
          indicatorColor: widget.accentBright,
          labelColor: widget.accentBright,
          unselectedLabelColor: Colors.white38,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(
              icon: const Icon(Icons.apps_rounded, size: 16),
              text: _tools.isEmpty ? 'Tools' : 'Tools (${_tools.length})',
            ),
            const Tab(icon: Icon(Icons.build_circle_outlined, size: 16), text: 'Funktion (KI baut)'),
            Tab(
              icon: const Icon(Icons.lightbulb_outline, size: 16),
              text: _toolSuggestions.isEmpty
                  ? 'KI & Status'
                  : 'KI & Status (${_toolSuggestions.length})',
            ),
            const Tab(icon: Icon(Icons.dataset_outlined, size: 16), text: 'Inhalte'),
          ],
        ),
        const Divider(color: Colors.white10, height: 1),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _buildToolsTab(),
              _buildFunctionTab(),
              _buildKiStatusTab(),
              _buildContentTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab: Tools-Verzeichnis (T1) + bearbeiten/erweitern (T4) ──
  Widget _buildToolsTab() {
    if (_toolsLoading) {
      return Center(child: CircularProgressIndicator(color: widget.accentBright));
    }
    // B1: Filter nach Suchbegriff (Name/Kategorie/Beschreibung).
    final q = _toolSearch.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _tools
        : _tools.where((t) {
            final hay =
                '${t['name'] ?? ''} ${t['category'] ?? ''} ${t['description'] ?? ''}'
                    .toLowerCase();
            return hay.contains(q);
          }).toList();
    // Nach Kategorie gruppieren.
    final byCat = <String, List<Map<String, dynamic>>>{};
    for (final t in filtered) {
      final c = (t['category'] as String?) ?? 'Allgemein';
      byCat.putIfAbsent(c, () => []).add(t);
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // A1: Kurz-Hilfe
        Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: widget.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.info_outline, size: 13, color: widget.accentBright),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Alle Tools dieser Welt. "Ändern lassen" baut Claude um. '
                  '"Inhalte" öffnet die Daten des Tools.',
                  style: TextStyle(color: Colors.white54, fontSize: 10.5),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            // A3: Status-Legende
            Wrap(spacing: 12, runSpacing: 4, children: const [
              _StatusLegend(color: Colors.green, label: 'live = aktiv in der App'),
              _StatusLegend(color: Colors.amber, label: 'im_bau = Claude baut gerade'),
              _StatusLegend(color: Colors.white38, label: 'geplant = noch nicht gestartet'),
            ]),
          ]),
        ),
        // B1: Suchfeld
        TextField(
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: _deco('Tool suchen …')
              .copyWith(prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white38)),
          onChanged: (v) => setState(() => _toolSearch = v),
        ),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text('Keine Treffer.', style: TextStyle(color: Colors.white38)),
            ),
          ),
        for (final entry in byCat.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
            child: Text(entry.key.toUpperCase(),
                style: TextStyle(
                    color: widget.accentBright,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8)),
          ),
          for (final t in entry.value) _buildToolTile(t),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _editTool(null),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Tool manuell eintragen'),
          style: OutlinedButton.styleFrom(
            foregroundColor: widget.accentBright,
            side: BorderSide(color: widget.accent),
          ),
        ),
      ],
    );
  }

  Widget _buildToolTile(Map<String, dynamic> t) {
    final status = (t['status'] as String?) ?? 'live';
    final statusColor = status == 'live'
        ? Colors.green
        : (status == 'im_bau' ? Colors.amber : Colors.white38);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text((t['name'] as String?) ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(status,
                  style: TextStyle(color: statusColor, fontSize: 9)),
            ),
          ]),
          if ((t['description'] as String?)?.isNotEmpty ?? false) ...[
            const SizedBox(height: 3),
            Text(t['description'].toString(),
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
          const SizedBox(height: 6),
          Row(children: [
            TextButton.icon(
              onPressed: () => _extendTool(t),
              icon: const Icon(Icons.auto_fix_high, size: 14),
              label: const Text('Ändern lassen', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                  foregroundColor: widget.accentBright,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 30)),
            ),
            if ((t['content_table'] as String?)?.isNotEmpty ?? false)
              TextButton.icon(
                onPressed: () {
                  _tabs.animateTo(2);
                  _loadRows(t['content_table'] as String);
                },
                icon: const Icon(Icons.dataset_outlined, size: 14),
                label: const Text('Inhalte', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.white54,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 30)),
              ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.edit, size: 15, color: Colors.white38),
              tooltip: 'Metadaten bearbeiten',
              onPressed: () => _editTool(t),
            ),
          ]),
        ],
      ),
    );
  }

  // T4: Bestehendes Tool aendern lassen -> Funktion-Tab im Extend-Modus.
  void _extendTool(Map<String, dynamic> t) {
    setState(() {
      _extend = true;
      _fnTarget.text = (t['name'] as String?) ?? '';
      _fnTitle.text = '${t['name']} erweitern';
      _fnDesc.clear();
      _resultMsg = null;
    });
    _tabs.animateTo(1);
  }

  // Tool-Metadaten bearbeiten/anlegen (Verzeichnis-Pflege).
  Future<void> _editTool(Map<String, dynamic>? t) async {
    final nameCtrl = TextEditingController(text: t?['name']?.toString() ?? '');
    final catCtrl = TextEditingController(text: t?['category']?.toString() ?? 'Allgemein');
    final descCtrl = TextEditingController(text: t?['description']?.toString() ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A30),
        title: Text(t == null ? 'Tool eintragen' : 'Tool bearbeiten',
            style: const TextStyle(color: Colors.white, fontSize: 15)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: _deco('Name')),
            const SizedBox(height: 8),
            TextField(controller: catCtrl, style: const TextStyle(color: Colors.white), decoration: _deco('Kategorie')),
            const SizedBox(height: 8),
            TextField(controller: descCtrl, maxLines: 3, style: const TextStyle(color: Colors.white), decoration: _deco('Beschreibung')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: widget.accent),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final ok = await WorldAdminServiceV162.saveTool({
      if (t?['id'] != null) 'id': t!['id'],
      'world': widget.world,
      'name': nameCtrl.text.trim(),
      'category': catCtrl.text.trim(),
      'description': descCtrl.text.trim(),
    });
    _snack(ok ? 'Gespeichert' : 'Speichern fehlgeschlagen',
        c: ok ? Colors.green : Colors.redAccent);
    if (ok) _loadTools();
  }

  // ── Tab 1: Funktion anfragen (Claude baut) ──
  Widget _buildFunctionTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
          ),
          child: Text(
            '${widget.world == 'energie' ? 'Energie' : 'Materie'} hat interaktive Funktionen/Tools (kein Quiz). '
            'Beschreibe eine neue Funktion oder eine Erweiterung — die KI verfasst eine Spezifikation, '
            'erstellt ein GitHub-Issue und Claude Code baut sie und oeffnet einen PR (du mergest, dann neues APK).',
            style: const TextStyle(color: Colors.amber, fontSize: 11, height: 1.4),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          ChoiceChip(
            label: const Text('Neue Funktion'),
            selected: !_extend,
            onSelected: (_) => setState(() => _extend = false),
            selectedColor: widget.accent,
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Bestehende erweitern'),
            selected: _extend,
            onSelected: (_) => setState(() => _extend = true),
            selectedColor: widget.accent,
          ),
        ]),
        const SizedBox(height: 12),
        if (_extend) ...[
          TextField(
            controller: _fnTarget,
            style: const TextStyle(color: Colors.white),
            decoration: _deco(widget.world == 'energie'
                ? 'Welches Tool? (z.B. Numerologie, Tarot, Chakren)'
                : 'Welches Tool? (z.B. Kaninchenbau, Krypto-Tracker)'),
          ),
          const SizedBox(height: 10),
        ],
        // KI-Vorschlag: fuellt Titel + Beschreibung (neu ODER Verbesserung).
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _ideaBusy ? null : _suggestFunctionIdea,
            icon: _ideaBusy
                ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome, size: 14),
            label: Text(
              _extend ? 'KI-Verbesserungsvorschlag' : 'KI-Idee vorschlagen',
              style: const TextStyle(fontSize: 11),
            ),
            style: TextButton.styleFrom(foregroundColor: widget.accentBright),
          ),
        ),
        TextField(
          controller: _fnTitle,
          style: const TextStyle(color: Colors.white),
          decoration: _deco('Kurzer Titel der Funktion'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _fnDesc,
          style: const TextStyle(color: Colors.white),
          maxLines: 6,
          decoration: _deco('Was soll die Funktion koennen? Eingaben, Ausgaben, Ablauf …'),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _requesting ? null : _requestFunction,
          icon: _requesting
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.auto_awesome),
          label: Text(_requesting ? 'KI erstellt Spezifikation …' : 'Anfragen & bauen lassen'),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.accentBright.withValues(alpha: 0.85),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(46),
          ),
        ),
        if (_resultMsg != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_resultMsg!, style: const TextStyle(color: Colors.white, fontSize: 12)),
              if (_resultUrl != null) ...[
                const SizedBox(height: 6),
                SelectableText(_resultUrl!,
                    style: TextStyle(color: widget.accentBright, fontSize: 11)),
              ],
            ]),
          ),
        ],
      ],
    );
  }

  // ── Tab: KI-Vorschlaege (T2) + Status der Anfragen (T3) ──
  Widget _buildKiStatusTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Root-Admin: offene Admin-Anfragen freigeben/ablehnen (welt-uebergreifend).
        // Immer sichtbar, damit der Root-Admin weiss, wo die Freigabe sitzt.
        if (widget.isRootAdmin) ...[
          Row(children: [
            const Icon(Icons.verified_user, size: 16, color: Colors.amber),
            const SizedBox(width: 6),
            Text('FREIGABEN (${_toolApprovals.length})',
                style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, size: 16, color: Colors.white38),
              onPressed: _loadToolApprovals,
            ),
          ]),
          const Text(
            'Hier gibst du Tool-Anfragen von Admins frei (oder lehnst ab). '
            'Erst nach Freigabe wird gebaut.',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 8),
          if (_toolApprovals.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Keine offenen Freigaben.',
                  style: TextStyle(color: Colors.white30, fontSize: 12)),
            )
          else
            for (final a in _toolApprovals) _buildApprovalCard(a),
          const Divider(color: Colors.white12, height: 28),
        ],
        ElevatedButton.icon(
          onPressed: _scanningTools ? null : _scanTools,
          icon: _scanningTools
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.auto_awesome, size: 16),
          label: Text(_scanningTools ? 'KI denkt nach …' : 'KI-Tool-Vorschlaege holen'),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.accentBright.withValues(alpha: 0.8),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(44),
          ),
        ),
        const SizedBox(height: 14),
        if (_toolSuggestions.isNotEmpty) ...[
          Text('KI-VORSCHLAEGE (${_toolSuggestions.length})',
              style: TextStyle(color: widget.accentBright, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 6),
          for (final s in _toolSuggestions) _buildToolSuggestionCard(s),
          const SizedBox(height: 16),
        ],
        Row(children: [
          Text('ANFRAGEN-STATUS',
              style: TextStyle(color: widget.accentBright, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, size: 16, color: Colors.white38),
            onPressed: _loadToolRequests,
          ),
        ]),
        const SizedBox(height: 6),
        if (_toolRequests.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Noch keine Anfragen.', style: TextStyle(color: Colors.white38)),
          )
        else
          for (final r in _toolRequests) _buildRequestStatusTile(r),
      ],
    );
  }

  Widget _buildApprovalCard(Map<String, dynamic> a) {
    final id = a['id']?.toString() ?? '';
    final busy = _approvalBusy.contains(id);
    final mode = (a['mode'] as String?) == 'extend' ? 'Erweiterung' : 'Neu';
    final target = (a['target'] as String?) ?? '';
    final by = (a['requested_by'] as String?) ?? '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Quelle eindeutig: diese Anfrage kommt von einem Admin (nicht von der KI).
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('👤 ADMIN-ANFRAGE - @$by',
                style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5)),
          ),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(mode,
                style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0)),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(((a['world'] as String?) ?? '').toUpperCase(),
                style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text((a['title'] as String?) ?? '',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        if (target.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text('Tool: $target',
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
        const SizedBox(height: 4),
        Text((a['description'] as String?) ?? '',
            style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 8),
        if (busy)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(4),
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          )
        else
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _decideApproval(id, true),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Freigeben & bauen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.withValues(alpha: 0.85),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _decideApproval(id, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text('Ablehnen'),
            ),
          ]),
      ]),
    );
  }

  Widget _buildToolSuggestionCard(Map<String, dynamic> s) {
    final id = s['id']?.toString() ?? '';
    final busy = _toolSugBusy.contains(id);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Quelle eindeutig: dieser Vorschlag kommt von der KI (nicht von einem Admin).
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('🤖 KI-VORSCHLAG',
                style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8)),
          ),
          const Spacer(),
          if ((s['category'] as String?)?.isNotEmpty ?? false)
            Text(s['category'].toString(),
                style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ]),
        const SizedBox(height: 5),
        Text((s['name'] as String?) ?? '',
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        if ((s['description'] as String?)?.isNotEmpty ?? false) ...[
          const SizedBox(height: 3),
          Text(s['description'].toString(), style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
        if ((s['rationale'] as String?)?.isNotEmpty ?? false) ...[
          const SizedBox(height: 3),
          Text(s['rationale'].toString(), style: const TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic)),
        ],
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: busy ? null : () => _acceptToolSuggestion(s),
              icon: busy
                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check, size: 14),
              label: const Text('Annehmen & bauen', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: busy ? null : () => _rejectToolSuggestion(s),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white54, side: const BorderSide(color: Colors.white24)),
            child: const Text('Ablehnen', style: TextStyle(fontSize: 11)),
          ),
        ]),
      ]),
    );
  }

  Widget _buildRequestStatusTile(Map<String, dynamic> r) {
    final ghState = r['gh_state'] as String?;
    final prUrl = r['pr_url'] as String?;
    final status = r['status'] as String?;
    String label;
    Color color;
    if (prUrl != null) {
      label = 'PR bereit';
      color = Colors.lightBlueAccent;
    } else if (ghState == 'closed') {
      label = 'Erledigt';
      color = Colors.green;
    } else if (status == 'pending_approval') {
      label = 'Wartet auf Freigabe';
      color = Colors.amberAccent;
    } else if (status == 'rejected') {
      label = 'Abgelehnt';
      color = Colors.redAccent;
    } else if (ghState == 'open' || status == 'issue_created') {
      label = 'Wird gebaut';
      color = Colors.amber;
    } else {
      label = 'Angefragt';
      color = Colors.white54;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((r['title'] as String?) ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
            if (prUrl != null)
              SelectableText(prUrl, style: TextStyle(color: widget.accentBright, fontSize: 10)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  // ── Tab 2: Inhalte verwalten ──
  Widget _buildContentTab() {
    if (_contentTables.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Fuer diese Welt gibt es aktuell keine direkt editierbaren Inhalte.\n'
            'Nutze die Funktions-Werkstatt, um neue Tools/Inhalte bauen zu lassen.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38),
          ),
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            const Text('Inhaltstyp:', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _activeTable,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1A1A2E),
                  hint: const Text('Auswaehlen …', style: TextStyle(color: Colors.white38)),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: [
                    for (final t in _contentTables)
                      DropdownMenuItem(
                        value: t['table'] as String,
                        child: Text(t['label'] as String? ?? t['table'] as String),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) _loadRows(v);
                  },
                ),
              ),
            ),
            if (_activeTable != null)
              IconButton(
                icon: Icon(Icons.add_circle, color: widget.accentBright),
                tooltip: 'Neuer Eintrag',
                onPressed: () => _editRow(null),
              ),
          ]),
        ),
        const Divider(color: Colors.white10, height: 1),
        Expanded(
          child: _activeTable == null
              ? const Center(child: Text('Inhaltstyp waehlen', style: TextStyle(color: Colors.white38)))
              : _contentLoading
                  ? Center(child: CircularProgressIndicator(color: widget.accentBright))
                  : _rows.isEmpty
                      ? const Center(child: Text('Keine Eintraege', style: TextStyle(color: Colors.white38)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _rows.length,
                          itemBuilder: (_, i) => _buildRowTile(_rows[i]),
                        ),
        ),
      ],
    );
  }

  String _rowTitle(Map<String, dynamic> r) {
    for (final k in ['name', 'title', 'label', 'symbol', 'keyword', 'animal', 'number']) {
      final v = r[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return r['id']?.toString() ?? '(ohne Titel)';
  }

  Widget _buildRowTile(Map<String, dynamic> r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        title: Text(_rowTitle(r),
            style: const TextStyle(color: Colors.white, fontSize: 13)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 16, color: Colors.white54),
            onPressed: () => _editRow(r),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
            onPressed: () => _deleteRow(r),
          ),
        ]),
        onTap: () => _editRow(r),
      ),
    );
  }

  Future<void> _deleteRow(Map<String, dynamic> r) async {
    final id = r['id'];
    if (id == null) {
      _snack('Eintrag ohne id kann nicht geloescht werden');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A30),
        title: const Text('Eintrag loeschen?', style: TextStyle(color: Colors.white)),
        content: Text(_rowTitle(r), style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Loeschen', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok != true) return;
    final done = await WorldAdminServiceV162.deleteContentRow(
        world: widget.world, table: _activeTable!, id: id);
    _snack(done ? 'Geloescht' : 'Loeschen fehlgeschlagen');
    if (done) _loadRows(_activeTable!);
  }

  Future<void> _editRow(Map<String, dynamic>? existing) async {
    final cols = _columns.isNotEmpty
        ? _columns
        : (existing?.keys.toList() ?? const <String>[]);
    final ctrls = <String, TextEditingController>{};
    for (final c in cols) {
      if (c == 'id' || c == 'created_at' || c == 'updated_at') continue;
      final v = existing?[c];
      ctrls[c] = TextEditingController(
          text: v == null ? '' : (v is String ? v : jsonEncode(v)));
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12121E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.all(16),
            children: [
              Text(existing == null ? 'Neuer Eintrag' : 'Eintrag bearbeiten',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              for (final e in ctrls.entries) ...[
                Text(e.key, style: TextStyle(color: widget.accentBright, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(
                  controller: e.value,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: null,
                  minLines: 1,
                  decoration: _deco(null),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Speichern'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
    if (saved != true) return;
    final row = <String, dynamic>{};
    for (final e in ctrls.entries) {
      final raw = e.value.text;
      // Versuche JSON zu parsen (fuer jsonb-Spalten), sonst String.
      dynamic val = raw;
      final trimmed = raw.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          val = jsonDecode(trimmed);
        } catch (_) {/* bleibt String */}
      }
      row[e.key] = val;
    }
    final ok = await WorldAdminServiceV162.saveContentRow(
      world: widget.world,
      table: _activeTable!,
      row: row,
      id: existing?['id'],
    );
    _snack(ok ? 'Gespeichert' : 'Speichern fehlgeschlagen',
        c: ok ? Colors.green : Colors.redAccent);
    if (ok) _loadRows(_activeTable!);
  }

  InputDecoration _deco(String? hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );
}

// A3: kleine Status-Legende (Punkt + Text).
class _StatusLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _StatusLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9.5)),
    ]);
  }
}
