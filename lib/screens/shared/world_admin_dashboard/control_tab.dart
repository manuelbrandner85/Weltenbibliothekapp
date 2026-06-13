// v123: Steuerung Tab -- Feature Flags, Maintenance, Announcements, Content Queue, Banner.
// Root-Admin only (canManageKillSwitch). Admin+ for announcements and content queue.
part of '../world_admin_dashboard.dart';

// ═══════════════════════════════════════════════════════════════════════════
// STEUERUNG TAB
// ═══════════════════════════════════════════════════════════════════════════
class _ControlTab extends StatefulWidget {
  final Color accent, accentBright;
  final AdminState admin;
  const _ControlTab(
      {required this.accent, required this.accentBright, required this.admin});

  @override
  State<_ControlTab> createState() => _ControlTabState();
}

class _ControlTabState extends State<_ControlTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  static const _tabs = ['Flags', 'Ankuendigungen', 'Inhalte'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TabBar(
        controller: _tabCtrl,
        indicatorColor: widget.accent,
        labelColor: widget.accentBright,
        unselectedLabelColor: Colors.white38,
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
      Expanded(
        child: TabBarView(
          controller: _tabCtrl,
          children: [
            _FeatureFlagsPanel(
                accent: widget.accent,
                accentBright: widget.accentBright,
                admin: widget.admin),
            _AnnouncementsPanel(
                accent: widget.accent,
                accentBright: widget.accentBright,
                admin: widget.admin),
            _ContentQueuePanel(
                accent: widget.accent,
                accentBright: widget.accentBright,
                admin: widget.admin),
          ],
        ),
      ),
    ]);
  }
}

// ── Feature Flags Panel ────────────────────────────────────────────────────
class _FeatureFlagsPanel extends StatefulWidget {
  final Color accent, accentBright;
  final AdminState admin;
  const _FeatureFlagsPanel(
      {required this.accent, required this.accentBright, required this.admin});

  @override
  State<_FeatureFlagsPanel> createState() => _FeatureFlagsPanelState();
}

class _FeatureFlagsPanelState extends State<_FeatureFlagsPanel> {
  List<Map<String, dynamic>> _flags = [];
  bool _loading = true;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final flags = await WorldAdminServiceV162.getFeatureFlags();
      if (mounted)
        setState(() {
          _flags = flags;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(Map<String, dynamic> flag, bool enable) async {
    if (_processing) return;
    setState(() => _processing = true);
    final ok = await WorldAdminServiceV162.setFeatureFlag(
      key: flag['key'] as String,
      enabled: enable,
      world: flag['world'] as String?,
      adminUsername: widget.admin.username,
    );
    if (!mounted) return;
    setState(() => _processing = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(enable
            ? '✅ ${flag['key']} aktiviert'
            : '🔴 ${flag['key']} deaktiviert'),
        backgroundColor: const Color(0xFF1A1A2E),
      ));
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Fehler beim Setzen des Flags'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _addFlag() async {
    final keyCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    String? selectedWorld;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDs) => AlertDialog(
          backgroundColor: const Color(0xFF12121E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Neues Feature-Flag',
              style: TextStyle(color: Colors.white)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: keyCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco('Key (z.B. beta_feature)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: valueCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco('Wert (optional, Text)'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String?>(
              value: selectedWorld,
              dropdownColor: const Color(0xFF1A1A2E),
              decoration: _inputDeco('Welt (leer = global)'),
              items: const [
                DropdownMenuItem(
                    value: null,
                    child: Text('Alle Welten',
                        style: TextStyle(color: Colors.white70))),
                DropdownMenuItem(
                    value: 'materie',
                    child: Text('Materie',
                        style: TextStyle(color: Colors.white70))),
                DropdownMenuItem(
                    value: 'energie',
                    child: Text('Energie',
                        style: TextStyle(color: Colors.white70))),
                DropdownMenuItem(
                    value: 'vorhang',
                    child: Text('Vorhang',
                        style: TextStyle(color: Colors.white70))),
                DropdownMenuItem(
                    value: 'ursprung',
                    child: Text('Ursprung',
                        style: TextStyle(color: Colors.white70))),
              ],
              onChanged: (v) => setDs(() => selectedWorld = v),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Abbrechen',
                    style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: widget.accent),
              child: const Text('Erstellen'),
            ),
          ],
        ),
      ),
    );
    if (result != true || keyCtrl.text.trim().isEmpty) return;
    setState(() => _processing = true);
    final ok = await WorldAdminServiceV162.setFeatureFlag(
      key: keyCtrl.text.trim(),
      enabled: false,
      world: selectedWorld,
      value: valueCtrl.text.trim().isEmpty ? null : valueCtrl.text.trim(),
      adminUsername: widget.admin.username,
    );
    if (!mounted) return;
    setState(() => _processing = false);
    if (ok) _load();
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return Center(child: CircularProgressIndicator(color: widget.accent));
    final isRoot = widget.admin.isRootAdmin;
    return Stack(children: [
      ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (!isRoot)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Nur Root-Admin kann Feature-Flags aendern.',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                  textAlign: TextAlign.center),
            ),
          ..._flags.map((flag) {
            final key = flag['key']?.toString() ?? '';
            final enabled = flag['enabled'] as bool? ?? false;
            final world = flag['world']?.toString();
            final value = flag['value']?.toString();
            final isMaintenance = key == 'maintenance';
            final isBanner = key.startsWith('banner_');
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: enabled
                    ? (isMaintenance ? Colors.red : widget.accent)
                        .withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: enabled
                      ? (isMaintenance ? Colors.red : widget.accent)
                          .withValues(alpha: 0.35)
                      : Colors.white10,
                ),
              ),
              child: Row(children: [
                Icon(
                  isMaintenance
                      ? Icons.construction_rounded
                      : isBanner
                          ? Icons.announcement_rounded
                          : Icons.toggle_on_rounded,
                  color: enabled
                      ? (isMaintenance ? Colors.redAccent : widget.accentBright)
                      : Colors.white38,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(key,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      if (world != null)
                        Text('Welt: $world',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 10)),
                      if (value != null && value.isNotEmpty)
                        Text(value,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 11)),
                    ])),
                if (isRoot)
                  Switch(
                    value: enabled,
                    activeColor:
                        isMaintenance ? Colors.redAccent : widget.accent,
                    onChanged: _processing ? null : (v) => _toggle(flag, v),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: enabled
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(enabled ? 'An' : 'Aus',
                        style: TextStyle(
                          color: enabled ? Colors.greenAccent : Colors.white38,
                          fontSize: 11,
                        )),
                  ),
              ]),
            );
          }),
          if (_flags.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Keine Flags konfiguriert',
                    style: TextStyle(color: Colors.white38)),
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
      if (isRoot)
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: _addFlag,
            backgroundColor: widget.accent,
            label: const Text('Neues Flag'),
            icon: const Icon(Icons.add_rounded),
          ),
        ),
    ]);
  }
}

// ── Announcements Panel ────────────────────────────────────────────────────
class _AnnouncementsPanel extends StatefulWidget {
  final Color accent, accentBright;
  final AdminState admin;
  const _AnnouncementsPanel(
      {required this.accent, required this.accentBright, required this.admin});

  @override
  State<_AnnouncementsPanel> createState() => _AnnouncementsPanelState();
}

class _AnnouncementsPanelState extends State<_AnnouncementsPanel> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await WorldAdminServiceV162.getAnnouncements();
      if (mounted)
        setState(() {
          _items = items;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    DateTime runAt = DateTime.now().add(const Duration(hours: 1));
    bool push = false;
    String? world;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDs) => AlertDialog(
          backgroundColor: const Color(0xFF12121E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Neue Ankuendigung',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDeco('Titel'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bodyCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: _inputDeco('Nachricht'),
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Sendezeit: ${runAt.toLocal().toString().substring(0, 16)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                trailing: IconButton(
                  icon:
                      const Icon(Icons.schedule_rounded, color: Colors.white54),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx2,
                      initialDate: runAt,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked == null) return;
                    if (!ctx2.mounted) return;
                    final time = await showTimePicker(
                      context: ctx2,
                      initialTime: TimeOfDay.fromDateTime(runAt),
                    );
                    if (time == null) return;
                    setDs(() => runAt = DateTime(picked.year, picked.month,
                        picked.day, time.hour, time.minute));
                  },
                ),
              ),
              Row(children: [
                Checkbox(
                  value: push,
                  activeColor: widget.accent,
                  onChanged: (v) => setDs(() => push = v ?? false),
                ),
                const Text('Push-Notification senden',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
              DropdownButtonFormField<String?>(
                value: world,
                dropdownColor: const Color(0xFF1A1A2E),
                decoration: _inputDeco('Welt (leer = alle)'),
                items: const [
                  DropdownMenuItem(
                      value: null,
                      child: Text('Alle Welten',
                          style: TextStyle(color: Colors.white70))),
                  DropdownMenuItem(
                      value: 'materie',
                      child: Text('Materie',
                          style: TextStyle(color: Colors.white70))),
                  DropdownMenuItem(
                      value: 'energie',
                      child: Text('Energie',
                          style: TextStyle(color: Colors.white70))),
                  DropdownMenuItem(
                      value: 'vorhang',
                      child: Text('Vorhang',
                          style: TextStyle(color: Colors.white70))),
                  DropdownMenuItem(
                      value: 'ursprung',
                      child: Text('Ursprung',
                          style: TextStyle(color: Colors.white70))),
                ],
                onChanged: (v) => setDs(() => world = v),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Abbrechen',
                    style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: widget.accent),
              child: const Text('Planen'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (titleCtrl.text.trim().isEmpty || bodyCtrl.text.trim().isEmpty) return;
    setState(() => _processing = true);
    final created = await WorldAdminServiceV162.createAnnouncement(
      title: titleCtrl.text.trim(),
      body: bodyCtrl.text.trim(),
      runAt: runAt,
      world: world,
      push: push,
      adminUsername: widget.admin.username,
    );
    if (!mounted) return;
    setState(() => _processing = false);
    if (created) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ankuendigung geplant'),
        backgroundColor: Colors.green,
      ));
      _load();
    }
  }

  Future<void> _delete(String id) async {
    final ok = await WorldAdminServiceV162.deleteAnnouncement(id);
    if (ok && mounted) _load();
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return Center(child: CircularProgressIndicator(color: widget.accent));
    return Stack(children: [
      ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ..._items.map((item) {
            final id = item['id']?.toString() ?? '';
            final title = item['title']?.toString() ?? '';
            final body = item['body']?.toString() ?? '';
            final runAt = item['run_at']?.toString() ?? '';
            final sent = item['sent'] as bool? ?? false;
            final push = item['push'] as bool? ?? false;
            final world = item['world']?.toString();
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: sent
                    ? Colors.white.withValues(alpha: 0.03)
                    : widget.accent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sent
                      ? Colors.white10
                      : widget.accent.withValues(alpha: 0.25),
                ),
              ),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(sent ? Icons.check_circle_rounded : Icons.schedule_rounded,
                    color: sent ? Colors.white30 : widget.accentBright,
                    size: 18),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      Text(body,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Wrap(spacing: 8, children: [
                        if (runAt.isNotEmpty)
                          Text(_fmtTs(runAt),
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 10)),
                        if (world != null)
                          Text('[$world]',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 10)),
                        if (push)
                          const Text('[Push]',
                              style: TextStyle(
                                  color: Colors.orangeAccent, fontSize: 10)),
                        Text(sent ? 'Gesendet' : 'Ausstehend',
                            style: TextStyle(
                                color:
                                    sent ? Colors.white30 : Colors.greenAccent,
                                fontSize: 10)),
                      ]),
                    ])),
                if (!sent)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.white30, size: 18),
                    onPressed: () => _delete(id),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
              ]),
            );
          }),
          if (_items.isEmpty)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Keine Ankuendigungen geplant',
                  style: TextStyle(color: Colors.white38)),
            )),
          const SizedBox(height: 80),
        ],
      ),
      Positioned(
        right: 16,
        bottom: 16,
        child: FloatingActionButton.extended(
          onPressed: _processing ? null : _create,
          backgroundColor: widget.accent,
          label: const Text('Planen'),
          icon: const Icon(Icons.add_rounded),
        ),
      ),
    ]);
  }

  String _fmtTs(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return ts;
    }
  }
}

// ── Content Queue Panel ────────────────────────────────────────────────────
class _ContentQueuePanel extends StatefulWidget {
  final Color accent, accentBright;
  final AdminState admin;
  const _ContentQueuePanel(
      {required this.accent, required this.accentBright, required this.admin});

  @override
  State<_ContentQueuePanel> createState() => _ContentQueuePanelState();
}

class _ContentQueuePanelState extends State<_ContentQueuePanel> {
  List<Map<String, dynamic>> _pending = [];
  bool _loading = true;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final videos = await WorldAdminServiceV162.getPendingVideos();
      if (mounted)
        setState(() {
          _pending = videos;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm(String id) async {
    setState(() => _processing = true);
    final ok = await WorldAdminServiceV162.confirmArchiveVideo(id);
    if (mounted) setState(() => _processing = false);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Video freigeschaltet'),
        backgroundColor: Colors.green,
      ));
      _load();
    }
  }

  Future<void> _reject(String id) async {
    setState(() => _processing = true);
    final ok = await WorldAdminServiceV162.rejectArchiveVideo(id);
    if (mounted) setState(() => _processing = false);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Video abgelehnt'),
        backgroundColor: Colors.red,
      ));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return Center(child: CircularProgressIndicator(color: widget.accent));
    if (_pending.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check_circle_rounded,
                color: Colors.greenAccent, size: 40),
            SizedBox(height: 12),
            Text('Keine ausstehenden Videos',
                style: TextStyle(color: Colors.white54, fontSize: 14)),
          ]),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _pending.length,
      itemBuilder: (ctx, i) {
        final v = _pending[i];
        final id = v['id']?.toString() ?? '';
        final title =
            v['youtube_title']?.toString() ?? v['raw_title']?.toString() ?? '–';
        final thumb = v['thumbnail_url']?.toString() ?? '';
        final category = v['category']?.toString();
        final worlds =
            (v['worlds'] as List?)?.map((e) => e.toString()).join(', ') ?? '';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.accent.withValues(alpha: 0.2)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (thumb.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(thumb,
                    width: 80,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        width: 80, height: 56, color: Colors.white10)),
              )
            else
              Container(
                width: 80,
                height: 56,
                decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.play_circle_outline_rounded,
                    color: Colors.white30),
              ),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  if (category != null)
                    Text('Kategorie: $category',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10)),
                  if (worlds.isNotEmpty)
                    Text('Welten: $worlds',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _processing ? null : () => _confirm(id),
                        icon: const Icon(Icons.check_rounded, size: 14),
                        label: const Text('Freischalten',
                            style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.greenAccent,
                          side: const BorderSide(color: Colors.green),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _processing ? null : () => _reject(id),
                        icon: const Icon(Icons.close_rounded, size: 14),
                        label: const Text('Ablehnen',
                            style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                    ),
                  ]),
                ])),
          ]),
        );
      },
    );
  }
}
