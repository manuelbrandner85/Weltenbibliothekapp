// GENERATED SPLIT (TEIL 1B): part of world_admin_dashboard library.
// No logic changes -- structural extraction only.
part of '../world_admin_dashboard.dart';

// ── M3: Moderation-Queue-Screen ────────────────────────────────────
class _ModerationQueueScreen extends StatefulWidget {
  final Color accent;
  final String adminUsername;
  const _ModerationQueueScreen({
    required this.accent,
    required this.adminUsername,
  });

  @override
  State<_ModerationQueueScreen> createState() => _ModerationQueueScreenState();
}

class _ModerationQueueScreenState extends State<_ModerationQueueScreen> {
  List<MessageReport> _reports = const [];
  bool _loading = true;
  String _filter = 'open';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await ModerationQueueService.instance.queue(status: _filter);
    if (mounted) {
      setState(() {
        _reports = list;
        _loading = false;
      });
    }
  }

  Future<void> _act(MessageReport r, String status) async {
    final ok = await ModerationQueueService.instance.review(
      reportId: r.id,
      status: status,
      reviewedBy: widget.adminUsername,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? (status == 'actioned' ? '✅ Bearbeitet' : '✓ Verworfen')
          : '❌ Fehler'),
      backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
    ));
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050310),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Moderation-Queue',
            style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: widget.accent),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list_rounded, color: widget.accent),
            onSelected: (v) {
              setState(() => _filter = v);
              _load();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'open', child: Text('Offen')),
              PopupMenuItem(value: 'actioned', child: Text('Bearbeitet')),
              PopupMenuItem(value: 'dismissed', child: Text('Verworfen')),
            ],
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: widget.accent),
            )
          : _reports.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: Colors.white24, size: 56),
                        const SizedBox(height: 14),
                        Text(
                          'Keine Reports im Status "$_filter"',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55)),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: widget.accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: _reports.length,
                    itemBuilder: (_, i) => _reportCard(_reports[i]),
                  ),
                ),
    );
  }

  Widget _reportCard(MessageReport r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF12121E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: Colors.red, size: 16),
              const SizedBox(width: 6),
              Text(
                r.reason.toUpperCase(),
                style: const TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5),
              ),
              const Spacer(),
              Text(
                _relTime(r.createdAt),
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Gemeldet von @${r.reporterName ?? r.reporterId}'
            '${r.targetUser != null ? " · gegen @${r.targetUser}" : ""}',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
          ),
          if (r.notes?.isNotEmpty ?? false) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(r.notes!,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          ],
          const SizedBox(height: 4),
          Text('Message-ID: ${r.messageId}',
              style: const TextStyle(color: Colors.white24, fontSize: 10)),
          if (r.status == 'open') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _act(r, 'actioned'),
                    icon: const Icon(Icons.gavel, size: 16),
                    label: const Text('Maßnahme'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _act(r, 'dismissed'),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Verwerfen'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _relTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'jetzt';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'vor ${diff.inHours}h';
    return 'vor ${diff.inDays}d';
  }
}
