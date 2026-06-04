// GENERATED SPLIT (TEIL 1B): part of world_admin_dashboard library.
// No logic changes -- structural extraction only.
part of '../world_admin_dashboard.dart';

// ── v115 (Feature C): Admin-Notizen-Sheet ────────────────────────────────
class _NotesSheet extends StatefulWidget {
  final WorldUser user;
  final Color accent;
  const _NotesSheet({required this.user, required this.accent});

  @override
  State<_NotesSheet> createState() => _NotesSheetState();
}

class _NotesSheetState extends State<_NotesSheet> {
  List<Map<String, dynamic>> _notes = [];
  bool _loading = true;
  bool _saving = false;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final notes = await WorldAdminServiceV162.getNotes(widget.user.userId);
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    final ok = await WorldAdminServiceV162.addNote(
        userId: widget.user.userId, note: text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      _ctrl.clear();
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notiz konnte nicht gespeichert werden')),
      );
    }
  }

  Future<void> _delete(String noteId) async {
    final ok = await WorldAdminServiceV162.deleteNote(
        userId: widget.user.userId, noteId: noteId);
    if (!mounted) return;
    if (ok) _load();
  }

  String _fmt(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return ts;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.sticky_note_2_rounded,
                  color: Color(0xFF9575CD), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Notizen zu @${widget.user.username}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
              ),
            ]),
            const Text('Nur fuer Admins sichtbar -- der Nutzer sieht das nie.',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 12),
            Flexible(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : _notes.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('Noch keine Notizen.',
                              style: TextStyle(color: Colors.white38)),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _notes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final n = _notes[i];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.08)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n['note']?.toString() ?? '',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 13)),
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    Expanded(
                                      child: Text(
                                        '${n['author_username'] ?? 'admin'} · ${_fmt(n['created_at']?.toString() ?? '')}',
                                        style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 10),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          _delete(n['id']?.toString() ?? ''),
                                      child: const Icon(Icons.delete_outline,
                                          size: 16, color: Colors.white38),
                                    ),
                                  ]),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  maxLength: 1000,
                  minLines: 1,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Neue Notiz...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _saving ? null : _add,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: Color(0xFF9575CD)),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
