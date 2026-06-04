// GENERATED SPLIT (TEIL 1B): part of world_admin_dashboard library.
// No logic changes -- structural extraction only.
part of '../world_admin_dashboard.dart';

// ═════════════════════════════════════════════════════════════════════════════
// v117: ACCOUNT-REQUESTS-SHEET -- Antraege + Loesch-Blacklist verwalten
// ═════════════════════════════════════════════════════════════════════════════
class _AccountRequestsSheet extends StatefulWidget {
  final Color accent, accentBright;
  const _AccountRequestsSheet(
      {required this.accent, required this.accentBright});

  @override
  State<_AccountRequestsSheet> createState() => _AccountRequestsSheetState();
}

class _AccountRequestsSheetState extends State<_AccountRequestsSheet> {
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _blacklist = [];
  bool _loading = true;
  bool _busy = false;
  int _tab = 0; // 0 = Antraege, 1 = Blacklist

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final reqs =
        await WorldAdminServiceV162.getAccountRequests(status: 'pending');
    final bl = await WorldAdminServiceV162.getDeletedIdentities();
    if (!mounted) return;
    setState(() {
      _requests = reqs;
      _blacklist = bl;
      _loading = false;
    });
  }

  Future<void> _resolve(Map<String, dynamic> req, bool approve) async {
    final id = req['id'] as String?;
    if (id == null) return;
    setState(() => _busy = true);
    final ok = await WorldAdminServiceV162.resolveAccountRequest(
        requestId: id, approve: approve);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _toast(approve ? 'Angenommen' : 'Abgelehnt');
      await _load();
    } else {
      _toast('Fehlgeschlagen');
    }
  }

  Future<void> _freeBlacklist(Map<String, dynamic> row) async {
    final id = row['id'] as String?;
    if (id == null) return;
    setState(() => _busy = true);
    final ok = await WorldAdminServiceV162.removeDeletedIdentity(id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _toast('Freigegeben');
      await _load();
    } else {
      _toast('Fehlgeschlagen');
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m), duration: const Duration(seconds: 2)));
  }

  String _typeLabel(String? t) => switch (t) {
        'reactivation' => '🔓 Reaktivierung',
        'appeal' => '⚖️ Einspruch',
        'self_deletion' => '🗑️ Selbst-Loeschung',
        _ => t ?? '?',
      };

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scroll) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0B0817),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _tabChip('Antraege (${_requests.length})', 0),
                const SizedBox(width: 8),
                _tabChip('Blacklist (${_blacklist.length})', 1),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: widget.accent))
                  : _tab == 0
                      ? _buildRequests(scroll)
                      : _buildBlacklist(scroll),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabChip(String label, int idx) => ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: _tab == idx,
        onSelected: (_) => setState(() => _tab = idx),
        selectedColor: widget.accent.withValues(alpha: 0.4),
        backgroundColor: const Color(0xFF15111F),
        labelStyle:
            TextStyle(color: _tab == idx ? Colors.white : Colors.white54),
      );

  Widget _buildRequests(ScrollController scroll) {
    if (_requests.isEmpty) {
      return const Center(
        child: Text('Keine offenen Antraege.',
            style: TextStyle(color: Colors.white38)),
      );
    }
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
      itemCount: _requests.length,
      itemBuilder: (ctx, i) {
        final r = _requests[i];
        final msg = (r['message'] as String?) ?? '';
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF12101C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(_typeLabel(r['type'] as String?),
                    style: TextStyle(
                        color: widget.accentBright,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                const Spacer(),
                Text('@${r['username'] ?? r['user_id'] ?? '?'}',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 11)),
              ]),
              if (r['restriction_scope'] != null) ...[
                const SizedBox(height: 3),
                Text('Bereich: ${r['restriction_scope']}',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
              if (msg.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(msg,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _resolve(r, false),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Ablehnen'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : () => _resolve(r, true),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Annehmen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlacklist(ScrollController scroll) {
    if (_blacklist.isEmpty) {
      return const Center(
        child: Text('Blacklist ist leer.',
            style: TextStyle(color: Colors.white38)),
      );
    }
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
      itemCount: _blacklist.length,
      itemBuilder: (ctx, i) {
        final b = _blacklist[i];
        final status = (b['reactivation_status'] as String?) ?? 'blocked';
        final statusColor = status == 'requested'
            ? Colors.orangeAccent
            : status == 'approved'
                ? Colors.greenAccent
                : Colors.white38;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF12101C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('@${b['username_lower'] ?? '?'}',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('Status: $status',
                      style: TextStyle(color: statusColor, fontSize: 10)),
                  if (b['reason'] != null)
                    Text('Grund: ${b['reason']}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10)),
                ],
              ),
            ),
            TextButton(
              onPressed: _busy ? null : () => _freeBlacklist(b),
              child: const Text('Freigeben',
                  style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
            ),
          ]),
        );
      },
    );
  }
}
