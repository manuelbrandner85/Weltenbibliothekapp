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
  String _world = 'vorhang'; // 'vorhang' | 'ursprung'

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

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadExisting();
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
          indicatorColor: widget.accentBright,
          labelColor: widget.accentBright,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(
                icon: Icon(Icons.auto_awesome, size: 16),
                text: 'Neu erstellen'),
            Tab(icon: Icon(Icons.edit_note, size: 16), text: 'Bestehende'),
          ],
        ),
        const Divider(color: Colors.white10, height: 1),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _buildCreateTab(),
              _buildExistingTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorldSwitcher() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(children: [
        const Text('Welt:',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(width: 10),
        _worldChip('vorhang', 'Vorhang'),
        const SizedBox(width: 6),
        _worldChip('ursprung', 'Ursprung'),
      ]),
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
        });
        _loadExisting();
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
          const SizedBox(height: 12),
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
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _existingModules.length,
      itemBuilder: (_, i) {
        final m = _existingModules[i];
        return ListTile(
          dense: true,
          title: Text(
            (m['title'] as String?) ?? (m['module_code'] as String? ?? ''),
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          subtitle: Text(
            '${m['module_code']} - ${m['branch']}',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          trailing: Icon(Icons.chevron_right,
              color: widget.accentBright.withValues(alpha: 0.6)),
          onTap: () => _editExisting(m),
        );
      },
    );
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
