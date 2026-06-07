// GENERATED SPLIT (TEIL 1B): part of world_admin_dashboard library.
// No logic changes -- structural extraction only.
part of '../world_admin_dashboard.dart';

// ═════════════════════════════════════════════════════════════════════════════
// TAB - USERNAME-AENDERUNGSANTRAEGE
// Liste pending Antraege aus /api/admin/username-change-requests.
// Approve/Reject senden POST an Worker. Reload + SnackBar nach Aktion.
// ═════════════════════════════════════════════════════════════════════════════
class _UsernameRequestsTab extends ConsumerStatefulWidget {
  final String world;
  final Color accent;
  final Color accentBright;
  final VoidCallback onChanged;
  const _UsernameRequestsTab({
    required this.world,
    required this.accent,
    required this.accentBright,
    required this.onChanged,
  });

  @override
  ConsumerState<_UsernameRequestsTab> createState() =>
      _UsernameRequestsTabState();
}

class _UsernameRequestsTabState extends ConsumerState<_UsernameRequestsTab> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _adminUsername {
    final admin = ref.read(adminStateProvider(widget.world));
    return admin.username ?? 'admin';
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final headers = await AdminAuthService.instance.headers();
      final res = await http
          .get(
              Uri.parse(
                  '${ApiConfig.workerUrl}/api/admin/username-change-requests'),
              headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final raw = (data['requests'] as List?) ?? const [];
        final list =
            raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
        if (mounted) {
          setState(() {
            _requests = list;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
        _snack('Laden fehlgeschlagen: HTTP ${res.statusCode}',
            color: Colors.orange);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      _snack('Fehler beim Laden: $e', color: Colors.orange);
    }
    widget.onChanged();
  }

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color ?? const Color(0xFF1A1A2E),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<bool> _confirm(String title, String msg, {Color? confirmColor}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17)),
        content: Text(msg,
            style: const TextStyle(
                color: Colors.white70, fontSize: 14, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? widget.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Bestaetigen',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _approve(Map<String, dynamic> req) async {
    final id = (req['id'] ?? '').toString();
    if (id.isEmpty) {
      _snack('Antrags-ID fehlt', color: Colors.red);
      return;
    }
    final cur = (req['current_username'] ?? '').toString();
    final neu = (req['requested_username'] ?? '').toString();
    final ok = await _confirm(
      'Username dauerhaft aendern?',
      '@$cur -> @$neu\n\nDie Aenderung wird sofort wirksam und ist nicht zurueckholbar.',
      confirmColor: Colors.green,
    );
    if (!ok) return;
    setState(() => _processing = true);
    try {
      final adminHeaders = await AdminAuthService.instance.headers();
      final res = await http
          .post(
            Uri.parse(
                '${ApiConfig.workerUrl}/api/admin/username-change-requests/$id/approve'),
            headers: {
              'Content-Type': 'application/json',
              ...adminHeaders,
            },
            body: jsonEncode(const {}),
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        _snack('✅ @$cur ist jetzt @$neu', color: Colors.green);
      } else {
        _snack('Genehmigen fehlgeschlagen: HTTP ${res.statusCode}',
            color: Colors.orange);
      }
    } catch (e) {
      _snack('Genehmigen Fehler: $e', color: Colors.orange);
    } finally {
      if (mounted) setState(() => _processing = false);
      await _load();
    }
  }

  Future<void> _reject(Map<String, dynamic> req) async {
    final id = (req['id'] ?? '').toString();
    if (id.isEmpty) {
      _snack('Antrags-ID fehlt', color: Colors.red);
      return;
    }
    final cur = (req['current_username'] ?? '').toString();
    final neu = (req['requested_username'] ?? '').toString();
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Antrag ablehnen',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('@$cur -> @$neu',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: noteCtrl,
            maxLength: 200,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Notiz (optional, sichtbar fuer den User)',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF0D0D1A),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child:
                const Text('Ablehnen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final note = noteCtrl.text.trim();
    setState(() => _processing = true);
    try {
      final adminHeaders = await AdminAuthService.instance.headers();
      final res = await http
          .post(
            Uri.parse(
                '${ApiConfig.workerUrl}/api/admin/username-change-requests/$id/reject'),
            headers: {
              'Content-Type': 'application/json',
              ...adminHeaders,
            },
            body: jsonEncode({
              if (note.isNotEmpty) 'note': note,
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        _snack('Antrag von @$cur abgelehnt', color: Colors.orange);
      } else {
        _snack('Ablehnen fehlgeschlagen: HTTP ${res.statusCode}',
            color: Colors.orange);
      }
    } catch (e) {
      _snack('Ablehnen Fehler: $e', color: Colors.orange);
    } finally {
      if (mounted) setState(() => _processing = false);
      await _load();
    }
  }

  String _relativeTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'gerade eben';
      if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'vor ${diff.inHours} h';
      if (diff.inDays < 30) return 'vor ${diff.inDays} d';
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D1A),
            border: Border(
                bottom:
                    BorderSide(color: Colors.white.withValues(alpha: 0.05))),
          ),
          child: Row(children: [
            const Text('📝', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            const Text('Username-Aenderungsantraege',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: widget.accent.withValues(alpha: 0.4)),
              ),
              child: Text(
                '${_requests.length}',
                style: TextStyle(
                    color: widget.accentBright,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.refresh_rounded,
                  color: widget.accentBright, size: 20),
              tooltip: 'Aktualisieren',
              onPressed: _loading ? null : _load,
            ),
          ]),
        ),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: widget.accent))
              : _requests.isEmpty
                  ? Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          Icon(Icons.inbox_rounded,
                              size: 56, color: Colors.white24),
                          const SizedBox(height: 12),
                          const Text('Keine offenen Antraege',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 14)),
                        ]))
                  : RefreshIndicator(
                      color: widget.accent,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
                        itemCount: _requests.length,
                        itemBuilder: (ctx, i) =>
                            _buildRequestCard(_requests[i]),
                      ),
                    ),
        ),
      ]),
      if (_processing)
        Container(
          color: Colors.black54,
          child: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircularProgressIndicator(color: widget.accent),
              const SizedBox(height: 12),
              const Text('Wird verarbeitet...',
                  style: TextStyle(color: Colors.white70)),
            ]),
          ),
        ),
    ]);
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final cur = (req['current_username'] ?? '').toString();
    final neu = (req['requested_username'] ?? '').toString();
    final reason = (req['reason'] ?? '').toString();
    final created = req['created_at']?.toString();
    final avatar = (req['avatar_url'] ?? '').toString();
    final role = (req['profile_role'] ?? 'user').toString();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.accent.withValues(alpha: 0.18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF12121E).withValues(alpha: 0.88),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: widget.accent.withValues(alpha: 0.18),
                  backgroundImage:
                      avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  child: avatar.isEmpty
                      ? Text(
                          cur.isNotEmpty ? cur[0].toUpperCase() : '?',
                          style: TextStyle(
                              color: widget.accentBright,
                              fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('@$cur',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      Icon(Icons.arrow_forward_rounded,
                          size: 16, color: widget.accentBright),
                      Text('@$neu',
                          style: TextStyle(
                              color: widget.accentBright,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      if (role != 'user')
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.4)),
                          ),
                          child: Text(role,
                              style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
                Text(_relativeTime(created),
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11)),
              ]),
              if (reason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Reason: $reason',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12, height: 1.35)),
                ),
              ],
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.cancel_outlined,
                        size: 16, color: Colors.redAccent),
                    label: const Text('Ablehnen',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: Colors.redAccent.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: _processing ? null : () => _reject(req),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text('Genehmigen',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: _processing ? null : () => _approve(req),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

