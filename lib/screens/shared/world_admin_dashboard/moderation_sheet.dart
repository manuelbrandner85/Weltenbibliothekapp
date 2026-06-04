// GENERATED SPLIT (TEIL 1B): part of world_admin_dashboard library.
// No logic changes -- structural extraction only.
part of '../world_admin_dashboard.dart';

// ── v115 (Feature E): Moderationsqueue-Sheet ─────────────────────────────
class _ModerationSheet extends StatefulWidget {
  final Color accent;
  const _ModerationSheet({required this.accent});

  @override
  State<_ModerationSheet> createState() => _ModerationSheetState();
}

class _ModerationSheetState extends State<_ModerationSheet> {
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;
  String _statusFilter = 'open';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await WorldAdminServiceV162.getReports(
        status: _statusFilter, limit: 100);
    if (!mounted) return;
    setState(() {
      _reports = data == null
          ? []
          : ((data['reports'] as List?) ?? const [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
      _loading = false;
    });
  }

  Future<void> _resolve(String id, String status) async {
    final ok =
        await WorldAdminServiceV162.updateReport(reportId: id, status: status);
    if (!mounted) return;
    if (ok) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktion fehlgeschlagen')),
      );
    }
  }

  String _fmt(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return ts;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.flag_rounded, color: Colors.redAccent, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Moderationsqueue',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: Colors.white54),
            ),
          ]),
          const SizedBox(height: 8),
          // Status-Filter
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final s in const [
                  ('open', 'Offen'),
                  ('reviewing', 'In Pruefung'),
                  ('resolved', 'Erledigt'),
                  ('dismissed', 'Verworfen'),
                  ('all', 'Alle'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(s.$2, style: const TextStyle(fontSize: 11)),
                      selected: _statusFilter == s.$1,
                      onSelected: (_) {
                        setState(() => _statusFilter = s.$1);
                        _load();
                      },
                      selectedColor: widget.accent,
                      backgroundColor: const Color(0xFF1A1A26),
                      labelStyle: TextStyle(
                        color: _statusFilter == s.$1
                            ? Colors.white
                            : Colors.white70,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : _reports.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text('Keine Meldungen in dieser Kategorie.',
                              style: TextStyle(color: Colors.white38)),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _reports.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final r = _reports[i];
                          final id = r['id']?.toString() ?? '';
                          final type = r['type']?.toString() ?? 'report';
                          final title =
                              r['title']?.toString() ?? '(ohne Titel)';
                          final body = r['body']?.toString() ?? '';
                          final reporter = r['username']?.toString() ?? '?';
                          final status = r['status']?.toString() ?? 'open';
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  _MiniPill(
                                    label: type,
                                    color: widget.accent,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(title,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ]),
                                if (body.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(body,
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  'von @$reporter · ${_fmt(r['created_at']?.toString() ?? '')}',
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 10),
                                ),
                                if (status == 'open' ||
                                    status == 'reviewing') ...[
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    _ActionBtn(
                                        Icons.check_circle_rounded,
                                        'Erledigt',
                                        Colors.green,
                                        () => _resolve(id, 'resolved')),
                                    const SizedBox(width: 8),
                                    _ActionBtn(
                                        Icons.cancel_rounded,
                                        'Verwerfen',
                                        Colors.white38,
                                        () => _resolve(id, 'dismissed')),
                                  ]),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
