// GENERATED SPLIT (TEIL 1B): part of world_admin_dashboard library.
// No logic changes -- structural extraction only.
part of '../world_admin_dashboard.dart';

// ── Modul-Zugangs-Sheet (v116) ────────────────────────────────────────────
// Zeigt alle Vorhang- und Ursprung-Module fuer einen User mit den aktuellen
// Admin-Overrides. Admins koennen einzelne Module freischalten (Force-Unlock)
// oder sperren (Force-Block), unabhaengig vom normalen Prerequisite-System.
class _ModuleAccessSheet extends StatefulWidget {
  final WorldUser user;
  final Color accent;
  final String adminUsername;
  const _ModuleAccessSheet({
    required this.user,
    required this.accent,
    required this.adminUsername,
  });
  @override
  State<_ModuleAccessSheet> createState() => _ModuleAccessSheetState();
}

class _ModuleAccessSheetState extends State<_ModuleAccessSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _loading = true;
  bool _batchBusy = false;
  String? _loadError;

  // Alle Module aus DB (map: module_code -> row)
  List<Map<String, dynamic>> _vorhangModules = [];
  List<Map<String, dynamic>> _ursprungModules = [];

  // Admin-Overrides: pro module_code kann es mehrere Zeilen geben
  // (z.B. Altlast unter Legacy-ID + neue Zeile unter UUID).
  // Map: module_code -> List<{ user_id, is_granted }>
  final Map<String, List<_OverrideEntry>> _overridesByCode = {};

  // Laufende Aktionen
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final supa = Supabase.instance.client;
    try {
      // Module + aktuelle Overrides parallel laden
      final vorhangFuture = supa
          .from('vorhang_modules')
          .select('module_code,branch,title,is_boss_module,prerequisites')
          .order('module_code', ascending: true);
      final ursprungFuture = supa
          .from('ursprung_modules')
          .select('module_code,branch,title,is_boss_module,prerequisites')
          .order('module_code', ascending: true);
      final overrideFuture =
          WorldAdminServiceV162.getModuleAccess(widget.user.userId);

      final vorhangRaw =
          ((await vorhangFuture) as List).cast<Map<String, dynamic>>();
      final ursprungRaw =
          ((await ursprungFuture) as List).cast<Map<String, dynamic>>();
      final overrideList = await overrideFuture;

      if (!mounted) return;

      // Map: module_code -> Liste aller Override-Zeilen (inkl. evtl.
      // doppelte Eintraege unter unterschiedlichen IDs).
      final byCode = <String, List<_OverrideEntry>>{};
      for (final o in overrideList) {
        final code = o['module_code'] as String?;
        final granted = o['is_granted'] as bool?;
        final uid = o['user_id']?.toString();
        if (code == null || granted == null || uid == null) continue;
        byCode.putIfAbsent(code, () => []).add(
              _OverrideEntry(userId: uid, isGranted: granted),
            );
      }

      setState(() {
        _vorhangModules = vorhangRaw;
        _ursprungModules = ursprungRaw;
        _overridesByCode
          ..clear()
          ..addAll(byCode);
        _loading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('module_access_sheet load: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Fehler beim Laden: $e';
      });
    }
  }

  /// Sichtbarer Override-Status (es kann mehrere Zeilen geben):
  /// - genau 1 Eintrag → dessen is_granted
  /// - mehrere → wenn alle gleich: dieser Wert; sonst: erste (neueste) Zeile
  /// - keiner → null
  bool? _effectiveGrant(String code) {
    final list = _overridesByCode[code];
    if (list == null || list.isEmpty) return null;
    return list.first.isGranted;
  }

  Future<void> _setAccess(
      String moduleCode, String moduleType, bool isGranted) async {
    setState(() => _busy.add(moduleCode));
    final ok = await WorldAdminServiceV162.setModuleAccess(
      userId: widget.user.userId,
      moduleCode: moduleCode,
      moduleType: moduleType,
      isGranted: isGranted,
    );
    if (!mounted) return;
    if (ok) {
      // Nach erfolgreichem Schreiben: vollstaendig neu laden, damit die
      // tatsaechlich gespeicherte user_id (jetzt kanonische UUID) +
      // ggf. bereinigte Duplikate sichtbar werden.
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktion fehlgeschlagen')),
      );
      setState(() => _busy.remove(moduleCode));
    }
  }

  Future<void> _batchAll(bool isGranted) async {
    final label = isGranted ? 'freischalten' : 'sperren';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A30),
        title: Text(
          'Alle Module ${isGranted ? "freischalten" : "sperren"}?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Alle Vorhang- und Ursprung-Module fuer @${widget.user.username} werden $label.',
          style: const TextStyle(color: Colors.white70),
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
              backgroundColor: isGranted ? Colors.green.shade700 : Colors.red.shade800,
            ),
            child: Text('Ja, alle $label',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _batchBusy = true);
    final (ok, count) = await WorldAdminServiceV162.batchGrantModuleAccess(
      userId: widget.user.userId,
      isGranted: isGranted,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count Module ${isGranted ? "freigeschaltet" : "gesperrt"} (Vorhang + Ursprung)'),
          backgroundColor: const Color(0xFF1A1A30),
        ),
      );
      await _load();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Aktion fehlgeschlagen')));
      setState(() => _batchBusy = false);
    }
  }

  Future<void> _removeAccess(String moduleCode) async {
    setState(() => _busy.add(moduleCode));
    final ok = await WorldAdminServiceV162.removeModuleAccess(
      userId: widget.user.userId,
      moduleCode: moduleCode,
    );
    if (!mounted) return;
    if (ok) {
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktion fehlgeschlagen')),
      );
      setState(() => _busy.remove(moduleCode));
    }
  }

  Widget _buildModuleList(
      List<Map<String, dynamic>> modules, String moduleType) {
    if (modules.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Keine Module gefunden',
              style: TextStyle(color: Colors.white38)),
        ),
      );
    }

    // Module nach Branch gruppieren
    final byBranch = <String, List<Map<String, dynamic>>>{};
    for (final m in modules) {
      final branch = (m['branch'] as String?) ?? 'Weitere';
      byBranch.putIfAbsent(branch, () => []).add(m);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final entry in byBranch.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Text(
              entry.key,
              style: TextStyle(
                color: widget.accent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          for (final m in entry.value) _buildModuleRow(m, moduleType),
        ],
      ],
    );
  }

  Widget _buildModuleRow(Map<String, dynamic> m, String moduleType) {
    final code = m['module_code'] as String;
    final title = m['title'] as String? ?? code;
    final isBoss = m['is_boss_module'] as bool? ?? false;
    final prereqs = (m['prerequisites'] as List?)?.cast<String>() ?? [];
    final override = _effectiveGrant(code); // null = kein Override
    final entries = _overridesByCode[code] ?? const <_OverrideEntry>[];
    final isBusy = _busy.contains(code);

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    if (override == true) {
      statusColor = Colors.green;
      statusLabel = 'Freigeschaltet';
      statusIcon = Icons.lock_open_rounded;
    } else if (override == false) {
      statusColor = Colors.red;
      statusLabel = 'Gesperrt';
      statusIcon = Icons.lock_rounded;
    } else {
      statusColor = Colors.white24;
      statusLabel = prereqs.isEmpty ? 'Immer offen' : 'Voraussetzungen';
      statusIcon = Icons.hdr_auto_rounded;
    }

    // Speicher-Status-Hinweis (Task 2). Zeigt unter der Statuszeile, ob
    // der Eintrag unter UUID, Legacy-ID oder mehrfach gespeichert ist.
    final storageHint = _storageHintFor(entries);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: override == null
              ? Colors.white10
              : (override ? Colors.green : Colors.red).withValues(alpha: 0.35),
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isBoss
                ? Colors.amber.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isBoss ? Colors.amber.withValues(alpha: 0.4) : Colors.white10,
            ),
          ),
          child: Center(
            child: Text(
              isBoss ? '⭐' : code.split('-').last,
              style: TextStyle(
                fontSize: isBoss ? 14 : 10,
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Icon(statusIcon, size: 10, color: statusColor),
              const SizedBox(width: 4),
              Text(statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 10)),
            ]),
            if (storageHint != null) ...[
              const SizedBox(height: 2),
              Text(
                storageHint.text,
                style: TextStyle(color: storageHint.color, fontSize: 9.5),
              ),
            ],
          ],
        ),
        trailing: isBusy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white38))
            : PopupMenuButton<String>(
                color: const Color(0xFF1A1A30),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tooltip: 'Zugang steuern',
                itemBuilder: (_) => [
                  if (override != true)
                    PopupMenuItem(
                      value: 'grant',
                      child: Row(children: [
                        const Icon(Icons.lock_open_rounded,
                            size: 14, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text('Freischalten',
                            style:
                                TextStyle(color: Colors.white, fontSize: 13)),
                      ]),
                    ),
                  if (override != false)
                    PopupMenuItem(
                      value: 'block',
                      child: Row(children: [
                        const Icon(Icons.lock_rounded,
                            size: 14, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text('Sperren',
                            style:
                                TextStyle(color: Colors.white, fontSize: 13)),
                      ]),
                    ),
                  if (override != null)
                    PopupMenuItem(
                      value: 'reset',
                      child: Row(children: [
                        const Icon(Icons.restart_alt_rounded,
                            size: 14, color: Colors.white54),
                        const SizedBox(width: 8),
                        const Text('Zuruecksetzen (Standard)',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 13)),
                      ]),
                    ),
                ],
                onSelected: (action) {
                  if (action == 'grant') {
                    _setAccess(code, moduleType, true);
                  } else if (action == 'block') {
                    _setAccess(code, moduleType, false);
                  } else if (action == 'reset') {
                    _removeAccess(code);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.more_vert_rounded,
                      size: 14, color: Colors.white54),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overrideCount = _overridesByCode.length;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 8),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF26C6DA).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF26C6DA).withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.school_rounded,
                    color: Color(0xFF26C6DA), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Modul-Zugang',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text(
                      '@${widget.user.username}'
                      '${overrideCount > 0 ? ' · $overrideCount Override${overrideCount != 1 ? "s" : ""}' : ''}',
                      style: TextStyle(
                          color: widget.accent.withValues(alpha: 0.8),
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (_loading)
                const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white38)),
            ]),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabs,
            indicatorColor: const Color(0xFF26C6DA),
            labelColor: const Color(0xFF26C6DA),
            unselectedLabelColor: Colors.white38,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(
                  text:
                      'Vorhang${_vorhangModules.isNotEmpty ? " (${_vorhangModules.length})" : ""}'),
              Tab(
                  text:
                      'Ursprung${_ursprungModules.isNotEmpty ? " (${_ursprungModules.length})" : ""}'),
            ],
          ),
          // Beide-Welten-Batch-Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _batchBusy ? null : () => _batchAll(true),
                  icon: _batchBusy
                      ? const SizedBox(
                          width: 12, height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green))
                      : const Icon(Icons.lock_open_rounded, size: 14),
                  label: const Text('Alle entsperren', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _batchBusy ? null : () => _batchAll(false),
                  icon: const Icon(Icons.lock_rounded, size: 14),
                  label: const Text('Alle sperren', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
            ]),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Gilt fuer Vorhang + Ursprung',
              style: TextStyle(color: Colors.white30, fontSize: 10),
            ),
          ),
          const SizedBox(height: 4),
          const Divider(color: Colors.white10, height: 1),
          if (_loadError != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline,
                    size: 14, color: Colors.redAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(_loadError!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 11)),
                ),
              ]),
            ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF26C6DA)))
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _buildModuleList(_vorhangModules, 'vorhang'),
                      _buildModuleList(_ursprungModules, 'ursprung'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Generiert eine Klartext-Statuszeile pro Override-Eintrag, damit der
  /// Admin sieht ob die Freischaltung unter der kanonischen UUID oder
  /// einer veralteten Legacy-ID gespeichert ist (Task 2).
  _StorageHint? _storageHintFor(List<_OverrideEntry> entries) {
    if (entries.isEmpty) return null;
    if (entries.length > 1) {
      final ids = entries.map((e) => e.userId).toSet();
      if (ids.length > 1) {
        return _StorageHint(
          text:
              '⚠️ Mehrfacheintraege unter verschiedenen IDs (${ids.length}) -- bitte bereinigen',
          color: Colors.orangeAccent,
        );
      }
    }
    final uid = entries.first.userId;
    if (_isUuid(uid)) {
      final tail = uid.length >= 4 ? uid.substring(uid.length - 4) : uid;
      return _StorageHint(
        text: '✅ Gespeichert unter UUID …$tail',
        color: Colors.greenAccent.withValues(alpha: 0.8),
      );
    }
    if (uid.startsWith('user_')) {
      return const _StorageHint(
        text:
            '⚠️ Gespeichert unter Legacy-ID -- User liest evtl. mit anderer ID',
        color: Colors.orangeAccent,
      );
    }
    return _StorageHint(
      text: 'ℹ️ Gespeichert unter unbekanntem ID-Format ($uid)',
      color: Colors.white54,
    );
  }

  static bool _isUuid(String s) =>
      RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
              caseSensitive: false)
          .hasMatch(s);
}

class _OverrideEntry {
  final String userId;
  final bool isGranted;
  const _OverrideEntry({required this.userId, required this.isGranted});
}

class _StorageHint {
  final String text;
  final Color color;
  const _StorageHint({required this.text, required this.color});
}
