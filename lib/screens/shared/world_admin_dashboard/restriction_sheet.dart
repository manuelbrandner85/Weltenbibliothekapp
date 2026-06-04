// GENERATED SPLIT (TEIL 1B): part of world_admin_dashboard library.
// No logic changes -- structural extraction only.
part of '../world_admin_dashboard.dart';

// Kategorien -> Scopes. Reihenfolge bestimmt die Anzeige.
const Map<String, List<List<String>>> _kRestrictionCategories = {
  'Kommunikation': [
    ['chat', 'Chat', '💬'],
    ['livestream', 'Livestream', '🎥'],
    ['direct_messages', 'Direktnachrichten', '✉️'],
    ['shadow_mute', 'Shadow-Mute', '👻'],
  ],
  'Content': [
    ['create_articles', 'Artikel erstellen', '📝'],
    ['create_pins', 'Pins erstellen', '📍'],
    ['comment', 'Kommentieren', '💭'],
  ],
  'Gamification': [
    ['earn_xp', 'XP verdienen', '⭐'],
  ],
  'Werkzeuge': [
    ['spirit_tools', 'Spirit-Tools (alle)', '🔮'],
    ['research_tools', 'Recherche-Tools (alle)', '🔍'],
  ],
};

class _RestrictionSheet extends StatefulWidget {
  final WorldUser user;
  final Color accent, accentBright;
  final String adminUsername;
  final VoidCallback onChanged;
  const _RestrictionSheet({
    required this.user,
    required this.accent,
    required this.accentBright,
    required this.adminUsername,
    required this.onChanged,
  });

  @override
  State<_RestrictionSheet> createState() => _RestrictionSheetState();
}

class _RestrictionSheetState extends State<_RestrictionSheet> {
  final Set<String> _selected = {};
  final Map<String, Map<String, dynamic>> _active = {}; // scope -> row
  final _reasonCtrl = TextEditingController(text: 'Regelverstoss');
  bool _loading = true;
  bool _busy = false;
  int _durationIdx = 2; // default 24h
  bool _all = false;

  static const _durLabels = [
    '1 Std',
    '24 Std',
    '7 Tage',
    '30 Tage',
    'Permanent'
  ];
  static const _durHours = [1, 24, 168, 720, 0];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final rows =
        await WorldAdminServiceV162.getRestrictions(widget.user.userId);
    if (!mounted) return;
    setState(() {
      _active.clear();
      for (final r in rows) {
        final scope = r['scope'] as String?;
        if (scope != null) _active[scope] = r;
      }
      _all = _active.containsKey('all');
      _loading = false;
    });
  }

  String _expiryLabel(Map<String, dynamic> row) {
    if (row['is_permanent'] == true || row['expires_at'] == null) {
      return 'permanent';
    }
    final exp = DateTime.tryParse(row['expires_at'] as String? ?? '');
    if (exp == null) return '';
    final diff = exp.difference(DateTime.now());
    if (diff.isNegative) return 'abgelaufen';
    if (diff.inDays > 0) return 'noch ${diff.inDays}d';
    if (diff.inHours > 0) return 'noch ${diff.inHours}h';
    return 'noch ${diff.inMinutes}min';
  }

  Future<void> _applyNew() async {
    final scopes = _all ? ['all'] : _selected.toList();
    if (scopes.isEmpty) {
      _toast('Keine Bereiche ausgewaehlt');
      return;
    }
    setState(() => _busy = true);
    final ok = await WorldAdminServiceV162.restrictUser(
      userId: widget.user.userId,
      scopes: scopes,
      reason: _reasonCtrl.text.trim().isEmpty
          ? 'Admin-Sperre'
          : _reasonCtrl.text.trim(),
      durationHours: _durHours[_durationIdx],
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _toast('Bereiche gesperrt');
      _selected.clear();
      widget.onChanged();
      await _load();
    } else {
      _toast('Sperren fehlgeschlagen');
    }
  }

  Future<void> _lift(String scope) async {
    setState(() => _busy = true);
    final ok = await WorldAdminServiceV162.unrestrictUser(
      userId: widget.user.userId,
      scopes: scope == 'all' ? const [] : [scope],
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      widget.onChanged();
      await _load();
    } else {
      _toast('Aufheben fehlgeschlagen');
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m), duration: const Duration(seconds: 2)));
  }

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
        child: _loading
            ? Center(child: CircularProgressIndicator(color: widget.accent))
            : ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(children: [
                    Icon(Icons.tune_rounded, color: widget.accentBright),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Bereiche sperren - @${widget.user.username}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  const Text(
                    'Waehle einzelne Bereiche oder Vollsperrung. Bestehende '
                    'Sperren werden mit Ablauf angezeigt und koennen aufgehoben '
                    'werden.',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  const SizedBox(height: 16),

                  // Vollsperrung-Toggle
                  _buildAllToggle(),
                  const SizedBox(height: 8),

                  if (!_all)
                    for (final entry in _kRestrictionCategories.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: Text(entry.key.toUpperCase(),
                            style: TextStyle(
                                color: widget.accentBright,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5)),
                      ),
                      for (final scope in entry.value) _buildScopeRow(scope),
                    ],

                  const SizedBox(height: 18),
                  if (!_all || !_active.containsKey('all')) ...[
                    const Text('Grund',
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _reasonCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFF15111F),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Dauer',
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (int i = 0; i < _durLabels.length; i++)
                          ChoiceChip(
                            label: Text(_durLabels[i],
                                style: const TextStyle(fontSize: 11)),
                            selected: _durationIdx == i,
                            onSelected: (_) => setState(() => _durationIdx = i),
                            selectedColor: widget.accent.withValues(alpha: 0.4),
                            backgroundColor: const Color(0xFF15111F),
                            labelStyle: TextStyle(
                                color: _durationIdx == i
                                    ? Colors.white
                                    : Colors.white54),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _busy ? null : _applyNew,
                        icon: const Icon(Icons.lock_outline, size: 18),
                        label: Text(_all
                            ? 'Vollsperrung anwenden'
                            : 'Ausgewaehlte sperren'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF6C9A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ],
                  if (_active.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _busy ? null : () => _lift('all'),
                      icon: const Icon(Icons.lock_open_rounded,
                          size: 18, color: Colors.tealAccent),
                      label: const Text('Alle Sperren aufheben',
                          style: TextStyle(color: Colors.tealAccent)),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildAllToggle() {
    final active = _active.containsKey('all');
    return Container(
      decoration: BoxDecoration(
        color:
            _all ? Colors.red.withValues(alpha: 0.14) : const Color(0xFF15111F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _all ? Colors.red.withValues(alpha: 0.5) : Colors.white12),
      ),
      child: SwitchListTile(
        value: _all,
        onChanged: (v) => setState(() => _all = v),
        activeColor: Colors.red,
        title: const Text('🚫 Vollsperrung (alles)',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        subtitle: Text(
          active
              ? 'Aktiv - ${_expiryLabel(_active['all']!)}'
              : 'Sperrt saemtliche Funktionen (klassischer Ban)',
          style: TextStyle(
              color: active ? Colors.redAccent : Colors.white38, fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildScopeRow(List<String> scope) {
    final key = scope[0];
    final label = scope[1];
    final emoji = scope[2];
    final active = _active.containsKey(key);
    final checked = _selected.contains(key);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: active
            ? Colors.orange.withValues(alpha: 0.1)
            : const Color(0xFF12101C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color:
                active ? Colors.orange.withValues(alpha: 0.4) : Colors.white10),
      ),
      child: ListTile(
        dense: true,
        leading: Text(emoji, style: const TextStyle(fontSize: 18)),
        title: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
        subtitle: active
            ? Text('Aktiv - ${_expiryLabel(_active[key]!)}',
                style:
                    const TextStyle(color: Colors.orangeAccent, fontSize: 10))
            : null,
        trailing: active
            ? TextButton(
                onPressed: _busy ? null : () => _lift(key),
                child: const Text('Aufheben',
                    style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
              )
            : Checkbox(
                value: checked,
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _selected.add(key);
                  } else {
                    _selected.remove(key);
                  }
                }),
                activeColor: const Color(0xFFEF6C9A),
              ),
      ),
    );
  }
}
