// GENERATED SPLIT (TEIL 1B): part of world_admin_dashboard library.
// No logic changes -- structural extraction only.
part of '../world_admin_dashboard.dart';

// ═══════════════════════════════════════════════════════════
// 📜 AUDIT-LOG TAB
// ═══════════════════════════════════════════════════════════
// ═════════════════════════════════════════════════════════════════════════════
// TAB – PROTOKOLL WRAPPER (Audit-Log + Username-Antraege)
// 2026-06-07: Reports lebten frueher als 3. Sub-Tab hier mit; sind jetzt
// EINMALIG unter Moderation -> Protokoll hat nur noch Audit + Usernamen.
// Klassenname bleibt _AuditReportsWrapper aus Patch-Kompatibilitaet.
// ═════════════════════════════════════════════════════════════════════════════
class _AuditReportsWrapper extends StatefulWidget {
  final String world;
  final Color accent;
  final Color accentBright;
  final bool isRootAdmin;
  const _AuditReportsWrapper({
    required this.world,
    required this.accent,
    required this.accentBright,
    this.isRootAdmin = false,
  });

  @override
  State<_AuditReportsWrapper> createState() => _AuditReportsWrapperState();
}

class _AuditReportsWrapperState extends State<_AuditReportsWrapper>
    with SingleTickerProviderStateMixin {
  late TabController _ctrl;
  int _openUsernameRequests = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = TabController(length: 2, vsync: this);
    _loadUsernameRequestsCount();
  }

  Future<void> _loadUsernameRequestsCount() async {
    try {
      final headers = await AdminAuthService.instance.headers();
      final res = await http
          .get(
              Uri.parse(
                  '${ApiConfig.workerUrl}/api/admin/username-change-requests'),
              headers: headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final total =
            (data['total'] as int?) ?? (data['requests'] as List?)?.length ?? 0;
        setState(() => _openUsernameRequests = total);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('audit_tabs: silent catch -> $e');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: const Color(0xFF0D0D1A),
        child: TabBar(
          controller: _ctrl,
          indicatorColor: widget.accent,
          labelColor: widget.accentBright,
          unselectedLabelColor: Colors.white38,
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          tabs: [
            const Tab(
                icon: Icon(Icons.history_rounded, size: 16), text: 'Audit-Log'),
            Tab(
              icon: Stack(clipBehavior: Clip.none, children: [
                const Icon(Icons.edit_note_rounded, size: 16),
                if (_openUsernameRequests > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.amberAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$_openUsernameRequests',
                          style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 8,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ]),
              text: 'Usernamen',
            ),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _ctrl,
          children: [
            _AuditLogTab(
                world: widget.world,
                accent: widget.accent,
                accentBright: widget.accentBright,
                isRootAdmin: widget.isRootAdmin),
            _UsernameRequestsTab(
              world: widget.world,
              accent: widget.accent,
              accentBright: widget.accentBright,
              onChanged: _loadUsernameRequestsCount,
            ),
          ],
        ),
      ),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB – REPORTS-INBOX
// ═════════════════════════════════════════════════════════════════════════════
class _ReportsInboxTab extends StatefulWidget {
  final Color accent;
  final Color accentBright;
  final VoidCallback onChanged;
  final bool isRootAdmin;
  // Wer darf Meldungen loeschen/leeren? Admin + Root (Worker erzwingt es).
  final bool canDelete;
  const _ReportsInboxTab({
    required this.accent,
    required this.accentBright,
    required this.onChanged,
    this.isRootAdmin = false,
    this.canDelete = false,
  });

  @override
  State<_ReportsInboxTab> createState() => _ReportsInboxTabState();
}

class _ReportsInboxTabState extends State<_ReportsInboxTab> {
  List<Map<String, dynamic>> _reports = [];
  Map<String, int> _counts = {};
  Map<String, int> _byType = {};
  bool _loading = true;
  String _filterStatus = 'open';
  String _filterType = 'all';
  String? _error;

  // B2: KI-Moderation -- pro Report-ID das Triage-Ergebnis + laufende Calls.
  final Map<String, Map<String, dynamic>> _triage = {};
  final Set<String> _triaging = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _runTriage(Map<String, dynamic> r) async {
    final id = r['id'] as String?;
    if (id == null) return;
    setState(() => _triaging.add(id));
    final res = await WorldAdminServiceV162.triageReport(
      title: r['title']?.toString() ?? '',
      body: r['body']?.toString(),
      type: r['type']?.toString(),
    );
    if (!mounted) return;
    setState(() {
      _triaging.remove(id);
      if (res != null) _triage[id] = res;
    });
    if (res == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('KI-Analyse fehlgeschlagen'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  Color _sevColor(String sev) {
    switch (sev) {
      case 'kritisch':
        return Colors.red;
      case 'hoch':
        return Colors.orangeAccent;
      case 'mittel':
        return Colors.amber;
      default:
        return Colors.greenAccent;
    }
  }

  Widget _buildTriageResult(Map<String, dynamic> t) {
    final sev = (t['severity'] as String?) ?? 'mittel';
    final action = (t['action'] as String?) ?? '';
    final summary = (t['summary'] as String?) ?? '';
    final c = _sevColor(sev);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.auto_awesome, size: 12, color: c),
            const SizedBox(width: 4),
            Text('KI: ${sev.toUpperCase()}',
                style: TextStyle(
                    color: c, fontSize: 10, fontWeight: FontWeight.bold)),
          ]),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(summary,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
          if (action.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('→ $action',
                style: TextStyle(
                    color: c.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse('${ApiConfig.workerUrl}/api/admin/reports')
          .replace(queryParameters: {
        if (_filterStatus != 'all') 'status': _filterStatus,
        if (_filterType != 'all') 'type': _filterType,
        'limit': '100',
      });
      final headers = await AdminAuthService.instance.headers();
      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _reports = ((data['reports'] as List?) ?? const [])
              .cast<Map<String, dynamic>>();
          _counts =
              ((data['counts'] as Map?)?.cast<String, dynamic>() ?? const {})
                  .map((k, v) => MapEntry(k, (v as num).toInt()));
          _byType =
              ((data['by_type'] as Map?)?.cast<String, dynamic>() ?? const {})
                  .map((k, v) => MapEntry(k, (v as num).toInt()));
          _loading = false;
        });
      } else if (mounted) {
        setState(() {
          _error =
              'HTTP ${res.statusCode}: ${res.body.substring(0, res.body.length > 120 ? 120 : res.body.length)}';
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

  Future<void> _setStatus(Map<String, dynamic> report, String status,
      {String? note}) async {
    final id = report['id'] as String?;
    if (id == null) return;
    try {
      final adminHeaders = await AdminAuthService.instance.headers();
      final res = await http
          .patch(
            Uri.parse('${ApiConfig.workerUrl}/api/admin/reports/$id'),
            headers: {
              'Content-Type': 'application/json',
              ...adminHeaders,
            },
            body: jsonEncode({
              'status': status,
              if (note != null) 'resolution_note': note,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Status: $status'),
          backgroundColor: widget.accent,
        ));
        _load();
        widget.onChanged();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ HTTP ${res.statusCode}'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Netzwerk. Bitte erneut versuchen.'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  // Meldung loeschen (nur root_admin -- Worker prueft Rolle zusaetzlich).
  Future<void> _deleteReport(Map<String, dynamic> report) async {
    final id = report['id'] as String?;
    if (id == null) return;
    final ok = await WorldAdminServiceV162.deleteReport(id);
    if (!mounted) return;
    if (ok) {
      setState(() => _reports.removeWhere((e) => e['id'] == id));
      widget.onChanged();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Meldung geloescht'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Loeschen fehlgeschlagen'),
          backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _clearReports() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF12121E),
            title: const Text('Meldungen leeren',
                style: TextStyle(color: Colors.white)),
            content: Text(
                _filterStatus == 'all'
                    ? 'Wirklich ALLE Meldungen unwiderruflich loeschen?'
                    : 'Wirklich alle Meldungen mit Status "$_filterStatus" loeschen?',
                style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Abbrechen')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Loeschen',
                      style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    final ok = await WorldAdminServiceV162.clearReports(status: _filterStatus);
    if (!mounted) return;
    if (ok) {
      widget.onChanged();
      _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Meldungen geleert'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Leeren fehlgeschlagen'),
          backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _showDetail(Map<String, dynamic> r) async {
    final noteCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A18),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            Center(
                child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 16),
            Row(children: [
              _typeChip(r['type'] as String? ?? '?', big: true),
              const SizedBox(width: 8),
              _severityChip(r['severity'] as String? ?? 'medium'),
              const Spacer(),
              _statusChip(r['status'] as String? ?? 'open'),
            ]),
            const SizedBox(height: 14),
            Text(r['title']?.toString() ?? '',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
                '@${r['username'] ?? 'anonym'} · ${_fmt(r['created_at'] as String? ?? '')}',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            if ((r['body'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(r['body'].toString(),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.5)),
              ),
            ],
            if ((r['target_id'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              _InfoRow(Icons.gps_fixed_rounded, 'Target: ${r['target_id']}'),
            ],
            if ((r['context'] != null) &&
                (r['context'] is Map) &&
                (r['context'] as Map).isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoRow(Icons.info_outline_rounded,
                  'Context: ${jsonEncode(r['context'])}'),
            ],
            if ((r['resolution_note'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 14),
              const Text('AUFLÖSUNG',
                  style: TextStyle(
                      color: Colors.white38, fontSize: 10, letterSpacing: 2)),
              const SizedBox(height: 4),
              Text(r['resolution_note'].toString(),
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Text(
                  '— @${r['reviewed_by'] ?? '?'} · ${_fmt(r['reviewed_at'] as String? ?? '')}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
            const SizedBox(height: 22),
            const Text('Bearbeiten',
                style: TextStyle(
                    color: Colors.white54, fontSize: 11, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              maxLength: 400,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Notiz/Lösung (optional)',
                hintStyle: const TextStyle(color: Colors.white38),
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
              ),
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _setStatus(r, 'reviewing',
                      note: noteCtrl.text.trim().isEmpty
                          ? null
                          : noteCtrl.text.trim());
                },
                icon: const Icon(Icons.remove_red_eye_rounded, size: 16),
                label: const Text('In Bearbeitung'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.black),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _setStatus(r, 'resolved',
                      note: noteCtrl.text.trim().isEmpty
                          ? null
                          : noteCtrl.text.trim());
                },
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text('Erledigt'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _setStatus(r, 'dismissed',
                      note: noteCtrl.text.trim().isEmpty
                          ? null
                          : noteCtrl.text.trim());
                },
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Verwerfen'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                    foregroundColor: Colors.white),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _setStatus(r, 'open');
                },
                icon: const Icon(Icons.replay_rounded, size: 16),
                label: const Text('Erneut öffnen'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white),
              ),
              if (widget.canDelete)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _deleteReport(r);
                  },
                  icon: const Icon(Icons.delete_forever_rounded, size: 16),
                  label: const Text('Loeschen'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      foregroundColor: Colors.white),
                ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String type, {bool big = false}) {
    final String label;
    final Color color;
    switch (type) {
      case 'bug':
        label = '🐛 Bug';
        color = Colors.red;
        break;
      case 'content':
        label = '🚩 Inhalt';
        color = Colors.orange;
        break;
      case 'feedback':
        label = '💬 Feedback';
        color = Colors.blue;
        break;
      case 'voice':
        label = '🎙️ Voice';
        color = Colors.purple;
        break;
      default:
        label = '?';
        color = Colors.grey;
    }
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: big ? 10 : 6, vertical: big ? 5 : 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(big ? 10 : 6),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: big ? 12 : 10,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _severityChip(String sev) {
    final String label;
    final Color color;
    switch (sev) {
      case 'low':
        label = 'Niedrig';
        color = Colors.grey;
        break;
      case 'high':
        label = 'Hoch';
        color = Colors.orange;
        break;
      case 'critical':
        label = 'KRITISCH';
        color = Colors.red;
        break;
      case 'medium':
      default:
        label = 'Medium';
        color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5)),
    );
  }

  Widget _statusChip(String status) {
    final String label;
    final Color color;
    switch (status) {
      case 'reviewing':
        label = 'IN BEARB.';
        color = const Color(0xFFFFC107);
        break;
      case 'resolved':
        label = 'ERLEDIGT';
        color = Colors.green;
        break;
      case 'dismissed':
        label = 'VERWORFEN';
        color = Colors.grey;
        break;
      case 'open':
      default:
        label = 'OFFEN';
        color = Colors.redAccent;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1)),
    );
  }

  String _fmt(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}. ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Widget _filterPill(String label, String value, String current, int? count,
      void Function(String) onTap) {
    final sel = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel
              ? widget.accent.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? widget.accent : Colors.transparent),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: TextStyle(
                  color: sel ? widget.accentBright : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          if (count != null && count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$count',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Filter-Leiste
      Container(
        color: const Color(0xFF0D0D1A),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('STATUS',
                style: TextStyle(
                    color: Colors.white38, fontSize: 9, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            SizedBox(
                height: 30,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterPill('Offen', 'open', _filterStatus, _counts['open'],
                        (v) {
                      setState(() => _filterStatus = v);
                      _load();
                    }),
                    _filterPill('In Bearb.', 'reviewing', _filterStatus,
                        _counts['reviewing'], (v) {
                      setState(() => _filterStatus = v);
                      _load();
                    }),
                    _filterPill('Erledigt', 'resolved', _filterStatus,
                        _counts['resolved'], (v) {
                      setState(() => _filterStatus = v);
                      _load();
                    }),
                    _filterPill('Verworfen', 'dismissed', _filterStatus,
                        _counts['dismissed'], (v) {
                      setState(() => _filterStatus = v);
                      _load();
                    }),
                    _filterPill('Alle', 'all', _filterStatus, null, (v) {
                      setState(() => _filterStatus = v);
                      _load();
                    }),
                  ],
                )),
            const SizedBox(height: 8),
            const Text('TYP',
                style: TextStyle(
                    color: Colors.white38, fontSize: 9, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            SizedBox(
                height: 30,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterPill('Alle', 'all', _filterType, null, (v) {
                      setState(() => _filterType = v);
                      _load();
                    }),
                    _filterPill('🐛 Bug', 'bug', _filterType, _byType['bug'],
                        (v) {
                      setState(() => _filterType = v);
                      _load();
                    }),
                    _filterPill(
                        '🚩 Inhalt', 'content', _filterType, _byType['content'],
                        (v) {
                      setState(() => _filterType = v);
                      _load();
                    }),
                    _filterPill('💬 Feedback', 'feedback', _filterType,
                        _byType['feedback'], (v) {
                      setState(() => _filterType = v);
                      _load();
                    }),
                    _filterPill(
                        '🎙️ Voice', 'voice', _filterType, _byType['voice'],
                        (v) {
                      setState(() => _filterType = v);
                      _load();
                    }),
                  ],
                )),
            // Admin+: alle (gefilterten) Meldungen loeschen.
            if (widget.canDelete && _reports.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _clearReports,
                  icon: const Icon(Icons.delete_sweep_rounded,
                      size: 16, color: Colors.redAccent),
                  label: Text(
                      _filterStatus == 'all'
                          ? 'Alle Meldungen loeschen'
                          : 'Gefilterte loeschen',
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12)),
                ),
              ),
            ],
          ],
        ),
      ),

      Expanded(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: widget.accent))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Colors.redAccent, size: 40),
                        const SizedBox(height: 12),
                        Text(_error!,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                            onPressed: _load, child: const Text('Neu laden')),
                      ]),
                    ),
                  )
                : _reports.isEmpty
                    ? RefreshIndicator(
                        color: widget.accent,
                        onRefresh: () async => _load(),
                        child: ListView(children: const [
                          SizedBox(height: 80),
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(children: [
                                Icon(Icons.inbox_rounded,
                                    color: Colors.white24, size: 60),
                                SizedBox(height: 12),
                                Text('Keine Reports in diesem Filter.',
                                    style: TextStyle(
                                        color: Colors.white54, fontSize: 13)),
                              ]),
                            ),
                          ),
                        ]),
                      )
                    : RefreshIndicator(
                        color: widget.accent,
                        onRefresh: () async => _load(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _reports.length,
                          itemBuilder: (_, i) {
                            final r = _reports[i];
                            final card = Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _showDetail(r),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF12121E),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          _typeChip(
                                              r['type'] as String? ?? '?'),
                                          const SizedBox(width: 6),
                                          _severityChip(
                                              r['severity'] as String? ??
                                                  'medium'),
                                          const Spacer(),
                                          _statusChip(
                                              r['status'] as String? ?? 'open'),
                                        ]),
                                        const SizedBox(height: 8),
                                        Text(r['title']?.toString() ?? '',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis),
                                        if ((r['body'] as String?)
                                                ?.isNotEmpty ==
                                            true) ...[
                                          const SizedBox(height: 4),
                                          Text(r['body'].toString(),
                                              style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 11,
                                                  height: 1.3),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis),
                                        ],
                                        const SizedBox(height: 6),
                                        Row(children: [
                                          Expanded(
                                            child: Text(
                                                '@${r['username'] ?? 'anonym'} · ${_fmt(r['created_at'] as String? ?? '')}',
                                                style: const TextStyle(
                                                    color: Colors.white38,
                                                    fontSize: 10)),
                                          ),
                                          if (_triage[r['id']] == null)
                                            TextButton.icon(
                                              onPressed:
                                                  _triaging.contains(r['id'])
                                                      ? null
                                                      : () => _runTriage(r),
                                              icon: _triaging.contains(r['id'])
                                                  ? const SizedBox(
                                                      width: 12,
                                                      height: 12,
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2))
                                                  : const Icon(
                                                      Icons.auto_awesome,
                                                      size: 13),
                                              label: const Text('KI-Analyse',
                                                  style:
                                                      TextStyle(fontSize: 11)),
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    widget.accentBright,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8),
                                                minimumSize: const Size(0, 28),
                                              ),
                                            ),
                                        ]),
                                        if (_triage[r['id']] != null) ...[
                                          const SizedBox(height: 6),
                                          _buildTriageResult(_triage[r['id']]!),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                            if (!widget.canDelete) return card;
                            final id = r['id'] as String?;
                            if (id == null) return card;
                            // Admin+: per Swipe loeschbar.
                            return Dismissible(
                              key: ValueKey('report_$id'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.only(right: 20, bottom: 8),
                                child: const Icon(Icons.delete_forever_rounded,
                                    color: Colors.redAccent),
                              ),
                              confirmDismiss: (_) async {
                                await _deleteReport(r);
                                return false; // _deleteReport pflegt Liste selbst.
                              },
                              child: card,
                            );
                          },
                        ),
                      ),
      ),
    ]);
  }
}

class _AuditLogTab extends StatefulWidget {
  final String world;
  final Color accent;
  final Color accentBright;
  final bool isRootAdmin;
  const _AuditLogTab(
      {required this.world,
      required this.accent,
      required this.accentBright,
      this.isRootAdmin = false});

  @override
  State<_AuditLogTab> createState() => _AuditLogTabState();
}

class _AuditLogTabState extends State<_AuditLogTab> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  String _filterAction = 'all';
  // v103 Phase 4f: zusaetzlicher Zeitraum-Filter.
  String _filterRange = 'all'; // 'today' | '7d' | '30d' | 'all'
  // v123: Actor filter + undo
  String _filterActor = ''; // empty = all actors
  Map<String, dynamic>? _lastUndoableEntry; // latest reversible action

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _matchesRange(DateTime? created) {
    if (_filterRange == 'all' || created == null) return true;
    final now = DateTime.now();
    switch (_filterRange) {
      case 'today':
        return created.year == now.year &&
            created.month == now.month &&
            created.day == now.day;
      case '7d':
        return now.difference(created).inDays <= 7;
      case '30d':
        return now.difference(created).inDays <= 30;
      default:
        return true;
    }
  }

  DateTime? _parseLogTs(Map<String, dynamic> l) {
    final ts = l['created_at'] ?? l['timestamp'];
    if (ts is String) return DateTime.tryParse(ts);
    return null;
  }

  List<int> _last7DaysCounts() {
    final counts = List<int>.filled(7, 0);
    final now = DateTime.now();
    for (final l in _logs) {
      final ts = _parseLogTs(l);
      if (ts == null) continue;
      final delta = now.difference(ts).inDays;
      if (delta >= 0 && delta < 7) {
        counts[6 - delta]++;
      }
    }
    return counts;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final headers = await AdminAuthService.instance.headers();
      final res = await http
          .get(
            Uri.parse(
                '${ApiConfig.workerUrl}/api/admin/audit/${widget.world}?limit=200'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (data['logs'] as List?) ?? const [];
        if (mounted) {
          // Find last reversible entry (has undo_payload or is a role/ban action).
          Map<String, dynamic>? undoable;
          for (final item in list.cast<Map<String, dynamic>>()) {
            final action = item['action']?.toString() ?? '';
            final hasPayload = item['undo_payload'] != null;
            final isReversible = hasPayload ||
                action.contains('role') ||
                action.contains('ban') ||
                action.contains('suspend');
            if (isReversible) {
              undoable = item;
              break;
            }
          }
          setState(() {
            _logs = list.cast<Map<String, dynamic>>();
            _loading = false;
            _lastUndoableEntry = undoable;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    return _logs.where((l) {
      if (_filterAction != 'all' &&
          !(l['action'] as String? ?? '').contains(_filterAction)) {
        return false;
      }
      if (!_matchesRange(_parseLogTs(l))) return false;
      if (_filterActor.isNotEmpty) {
        final actor =
            (l['actor_id'] ?? l['actor'] ?? '').toString().toLowerCase();
        if (!actor.contains(_filterActor.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }

  // v123: CSV-Export des gefilterten Audit-Logs (clipboard, kein File-IO).
  Future<void> _exportCsv() async {
    final rows = _filtered;
    if (rows.isEmpty) return;
    final buf = StringBuffer();
    buf.writeln('timestamp,action,actor,target,details');
    for (final l in rows) {
      final ts = (l['created_at'] ?? l['timestamp'] ?? '').toString();
      final action = (l['action'] ?? '').toString().replaceAll(',', ';');
      final actor =
          (l['actor_id'] ?? l['actor'] ?? '').toString().replaceAll(',', ';');
      final target = (l['target_identity'] ?? l['target_id'] ?? '')
          .toString()
          .replaceAll(',', ';');
      final details = (l['details'] ?? l['reason'] ?? '')
          .toString()
          .replaceAll(',', ';')
          .replaceAll('\n', ' ');
      buf.writeln('"$ts","$action","$actor","$target","$details"');
    }
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('📋 ${rows.length} Eintraege als CSV kopiert'),
        backgroundColor: const Color(0xFF1A1A2E),
      ));
    }
  }

  // v123: Undo last reversible action (root_admin only).
  Future<void> _undo() async {
    final entry = _lastUndoableEntry;
    if (entry == null) return;
    final entryId = (entry['log_id'] ?? entry['id'] ?? '').toString();
    if (entryId.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12121E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Aktion rueckgaengig?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Letzte Aktion: ${entry['action'] ?? '?'}\nZiel: ${entry['target_identity'] ?? entry['target_id'] ?? '?'}',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen',
                  style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Rueckgaengig'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await WorldAdminServiceV162.undoAuditEntry(entryId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            ok ? '↩️ Aktion rueckgaengig gemacht' : '❌ Undo fehlgeschlagen'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
      if (ok) _load();
    }
  }

  void _toast(String m, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m), backgroundColor: color));
  }

  // Einzelnen Audit-Eintrag loeschen (nur root_admin). edit_/del_-Eintraege
  // stammen aus chat_messages und sind hier nicht loeschbar.
  Future<void> _deleteEntry(Map<String, dynamic> l) async {
    final logId = (l['log_id'] as String?) ?? '';
    if (!logId.startsWith('audit_')) {
      _toast('Dieser Eintrag (Chat-Historie) ist nicht loeschbar.',
          color: Colors.orange);
      return;
    }
    final ok = await WorldAdminServiceV162.deleteAuditEntry(
        world: widget.world, logId: logId);
    if (!mounted) return;
    if (ok) {
      setState(() => _logs.removeWhere((e) => e['log_id'] == logId));
      _toast('Eintrag geloescht', color: Colors.green);
    } else {
      _toast('Loeschen fehlgeschlagen', color: Colors.red);
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF12121E),
            title: const Text('Audit-Log leeren',
                style: TextStyle(color: Colors.white)),
            content: const Text(
                'Wirklich ALLE Audit-/Log-Eintraege unwiderruflich loeschen?',
                style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Abbrechen')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Alles loeschen',
                      style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    final ok = await WorldAdminServiceV162.clearAuditLog(world: widget.world);
    if (!mounted) return;
    if (ok) {
      setState(() => _logs.clear());
      _toast('Audit-Log geleert', color: Colors.green);
    } else {
      _toast('Leeren fehlgeschlagen', color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = {
      'all',
      ..._logs.map((l) => (l['action'] as String? ?? 'unknown')).toSet()
    };
    final dayCounts = _last7DaysCounts();
    final maxCount = dayCounts.isEmpty
        ? 1
        : (dayCounts.reduce((a, b) => a > b ? a : b).clamp(1, 9999));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(children: [
            Text('${_filtered.length}/${_logs.length} EINTRAEGE',
                style: TextStyle(
                    color: widget.accentBright,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            // v123: CSV Export
            if (_filtered.isNotEmpty)
              IconButton(
                tooltip: 'Als CSV kopieren',
                icon: const Icon(Icons.download_rounded,
                    color: Colors.greenAccent),
                onPressed: _exportCsv,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            // v123: Undo last action (root_admin only)
            if (widget.isRootAdmin && _lastUndoableEntry != null)
              IconButton(
                tooltip: 'Letzte Aktion rueckgaengig',
                icon:
                    const Icon(Icons.undo_rounded, color: Colors.orangeAccent),
                onPressed: _undo,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            if (widget.isRootAdmin && _logs.isNotEmpty)
              IconButton(
                  tooltip: 'Audit-Log leeren',
                  icon: const Icon(Icons.delete_sweep_rounded,
                      color: Colors.redAccent),
                  onPressed: _clearAll,
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36)),
            IconButton(
                icon: Icon(Icons.refresh, color: widget.accent),
                onPressed: _load,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
          ]),
        ),
        // v123: Actor filter field
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          child: TextField(
            style: const TextStyle(color: Colors.white, fontSize: 12),
            onChanged: (v) => setState(() => _filterActor = v.trim()),
            decoration: InputDecoration(
              hintText: 'Nach Admin-ID filtern...',
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
              prefixIcon: const Icon(Icons.person_search_rounded,
                  color: Colors.white38, size: 16),
              isDense: true,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        // v103 Phase 4f: Mini-Balkendiagramm letzte 7 Tage.
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: widget.accent.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aktionen pro Tag (letzte 7 Tage)',
                style: TextStyle(
                    color: widget.accentBright,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 36,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int i = 0; i < dayCounts.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                height: (dayCounts[i] / maxCount) * 28,
                                decoration: BoxDecoration(
                                  color: dayCounts[i] > 0
                                      ? widget.accent
                                      : widget.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${dayCounts[i]}',
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 8),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Zeitraum-Filter (Phase 4f).
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final r in [
                ('all', 'Alle'),
                ('today', 'Heute'),
                ('7d', '7 Tage'),
                ('30d', '30 Tage'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(r.$2, style: const TextStyle(fontSize: 10)),
                    selected: _filterRange == r.$1,
                    onSelected: (_) => setState(() => _filterRange = r.$1),
                    selectedColor: widget.accentBright,
                  ),
                ),
            ],
          ),
        ),
        // v115 (Feature F): Kategorie-Schnellfilter. Setzt _filterAction auf
        // einen Substring, der via .contains() mehrere Aktionstypen matcht
        // (z.B. 'role' -> role_promote + role_change_explicit).
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final c in const [
                ('all', '📋 Alle'),
                ('role', '🛡️ Rollen'),
                ('ban', '🚫 Bans'),
                ('warning', '⚠️ Verwarnungen'),
                ('message', '💬 Nachrichten'),
                ('xp', '✨ XP'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(c.$2, style: const TextStyle(fontSize: 10)),
                    selected: _filterAction == c.$1,
                    onSelected: (_) => setState(() => _filterAction = c.$1),
                    selectedColor: widget.accentBright,
                    backgroundColor: const Color(0xFF1A1A26),
                    labelStyle: TextStyle(
                      color:
                          _filterAction == c.$1 ? Colors.black : Colors.white70,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Action-Filter -- nur rendern wenn echte Aktionen im Audit-Log
        // existieren. Bei leerem Log hat actions nur 'all' und der Chip
        // wirkt redundant zum Zeitraum-Filter darueber.
        if (actions.length > 1)
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final a in actions)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(
                        a == 'all' ? 'Alle Aktionen' : a,
                        style: const TextStyle(fontSize: 10),
                      ),
                      selected: _filterAction == a,
                      onSelected: (_) => setState(() => _filterAction = a),
                      selectedColor: widget.accent,
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? const Center(
                      child: Text('Keine Einträge',
                          style: TextStyle(color: Colors.white60)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final l = _filtered[i];
                        if (!widget.isRootAdmin) return _buildLogRow(l);
                        // Root-Admin: per Swipe loeschbar (nur audit_-Eintraege).
                        final logId = (l['log_id'] as String?) ?? '';
                        final deletable = logId.startsWith('audit_');
                        if (!deletable) return _buildLogRow(l);
                        return Dismissible(
                          key: ValueKey(logId),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding:
                                const EdgeInsets.only(right: 20, bottom: 6),
                            child: const Icon(Icons.delete_forever_rounded,
                                color: Colors.redAccent),
                          ),
                          confirmDismiss: (_) async {
                            await _deleteEntry(l);
                            return false; // _deleteEntry pflegt die Liste selbst.
                          },
                          child: _buildLogRow(l),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildLogRow(Map<String, dynamic> l) {
    final action = (l['action'] as String?) ?? '';
    final admin = (l['admin_username'] as String?) ?? 'unknown';
    final target = (l['target_username'] as String?) ?? '';
    final details = (l['details'] as String?) ?? '';
    final ts = (l['timestamp'] as String?) ?? '';
    final icon = _iconFor(action);
    final color = _colorFor(action);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(action,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                    ts
                        .substring(0, ts.length >= 16 ? 16 : ts.length)
                        .replaceAll('T', ' '),
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 10)),
              ]),
              Text('$admin → $target',
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
              if (details.isNotEmpty)
                Text(details,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ]),
    );
  }

  IconData _iconFor(String a) {
    if (a.contains('ban')) return Icons.block;
    if (a.contains('delete')) return Icons.delete;
    if (a.contains('edit')) return Icons.edit;
    if (a.contains('role')) return Icons.shield;
    if (a.contains('mute')) return Icons.volume_off;
    return Icons.history;
  }

  Color _colorFor(String a) {
    if (a.contains('ban') || a.contains('delete')) return Colors.redAccent;
    if (a.contains('role') || a.contains('admin')) return Colors.amber;
    if (a.contains('edit')) return Colors.lightBlueAccent;
    if (a.contains('mute')) return Colors.orangeAccent;
    return Colors.white60;
  }
}
