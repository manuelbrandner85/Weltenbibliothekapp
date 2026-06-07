// GENERATED SPLIT (TEIL 1B): part of world_admin_dashboard library.
// No logic changes -- structural extraction only.
part of '../world_admin_dashboard.dart';

// ═════════════════════════════════════════════════════════════════════════════
// TAB 2 – NUTZER
// ═════════════════════════════════════════════════════════════════════════════
class _UsersTab extends StatefulWidget {
  final String world;
  final AdminState admin;
  final Color accent, accentBright;
  // v123 Priority 5: prefilled search query when hub forwards a global search.
  final String? initialQuery;
  const _UsersTab(
      {required this.world,
      required this.admin,
      required this.accent,
      required this.accentBright,
      this.initialQuery});
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  List<WorldUser> _all = [];
  List<WorldUser> _filtered = [];
  bool _loading = true;
  bool _processing = false;
  String? _errorMessage;
  DateTime? _lastLoadedAt;
  String _search = '';
  String _roleFilter = 'all';
  String _sourceFilter = 'all'; // 'all' | 'web' | 'app'
  String _sortMode = 'role'; // 'role' | 'newest' | 'oldest' | 'az' | 'online' | 'bot'
  bool _hideGhosts = true; // hide auto-generated user_* accounts
  bool _showBotSuspects = false; // Priority 1.6: Bot-Verdacht filter
  final _searchCtrl = TextEditingController();

  // Bulk-Selection — UserIDs der angehakten User. Bulk-Action-Bar erscheint
  // wenn nicht leer (FAB-ähnlich am unteren Rand).
  final Set<String> _selectedIds = {};

  // Real-time-Subscription auf profiles — Liste aktualisiert sich live wenn
  // ein User promotet/gebannt/gelöscht/erstellt wird (egal welcher Admin).
  RealtimeChannel? _profilesChannel;
  Timer? _realtimeDebounce;

  @override
  void initState() {
    super.initState();
    // Priority 5: apply forwarded global search query (if any).
    final q = widget.initialQuery?.trim() ?? '';
    if (q.isNotEmpty) {
      _search = q;
      _searchCtrl.text = q;
    }
    _load();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _profilesChannel?.unsubscribe();
    _realtimeDebounce?.cancel();
    super.dispose();
  }

  void _subscribeRealtime() {
    try {
      _profilesChannel = supabase
          .channel('admin-profiles-${DateTime.now().millisecondsSinceEpoch}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'profiles',
            callback: (_) {
              if (kDebugMode)
                debugPrint('🔄 profiles change → reload (debounced)');
              // AUDIT-FIX B11: Debounce damit ein Schwall von Profile-
              // Aenderungen (z.B. 10 User joinen gleichzeitig) nicht 10
              // Reloads ausloest. 800ms Quiet-Period.
              _realtimeDebounce?.cancel();
              _realtimeDebounce = Timer(const Duration(milliseconds: 800), () {
                if (mounted) _load();
              });
            },
          )
          .subscribe();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Realtime-Subscribe failed: $e');
    }
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }
    try {
      final users = await WorldAdminService.getAllUsers();
      if (mounted) {
        setState(() {
          _all = users;
          _lastLoadedAt = DateTime.now();
          _applyFilter();
          _loading = false;
          if (users.isEmpty) {
            // PHASE-4 FIX: Bei leerer Liste den LETZTEN Worker-Fehler aus
            // dem Diag-Log holen damit der Admin sieht WAS schiefging.
            final lastCall = AdminApiClient.instance.diagLog
                .where((c) => c.path == '/api/admin/users')
                .toList()
                .reversed
                .firstOrNull;
            if (lastCall != null && lastCall.statusCode >= 400) {
              _errorMessage = '${_httpLabel(lastCall.statusCode)}\n\n'
                  'Tipp: Tap auf "Diagnose" in der Uebersicht fuer Details.';
            } else if (lastCall != null && lastCall.statusCode == 0) {
              _errorMessage = 'Verbindungsfehler - kein Netzwerk.\n\n'
                  'Tipp: Internet pruefen + Diagnose-Button in der Uebersicht.';
            } else {
              _errorMessage = 'Keine Nutzer gefunden.\n\n'
                  'Falls das nicht stimmt, tap auf "Diagnose" in der '
                  'Uebersicht um die Worker-Verbindung zu pruefen.';
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        setState(() {
          _loading = false;
          _errorMessage =
              'Laden fehlgeschlagen: ${msg.length > 120 ? '${msg.substring(0, 120)}...' : msg}';
        });
      }
    }
  }

  void _applyFilter() {
    var list = _all;
    if (_hideGhosts) {
      list = list.where((u) => !u.isGhostUser).toList();
    }
    if (_showBotSuspects) {
      list = list.where((u) => u.isBotSuspect).toList();
    } else if (_roleFilter == 'banned') {
      list = list.where((u) => u.isSuspended).toList();
    } else if (_roleFilter != 'all') {
      list = list.where((u) => u.role == _roleFilter).toList();
    }
    if (_sourceFilter != 'all') {
      list = list.where((u) => u.source == _sourceFilter).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((u) =>
              u.username.toLowerCase().contains(q) ||
              (u.displayName ?? '').toLowerCase().contains(q))
          .toList();
    }
    // Sortier-Mode anwenden (nicht-mutativ, Kopie).
    final sortable = [...list];
    switch (_sortMode) {
      case 'newest':
        sortable.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        sortable.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'az':
        sortable.sort((a, b) =>
            a.username.toLowerCase().compareTo(b.username.toLowerCase()));
        break;
      case 'online':
        sortable.sort((a, b) {
          final ad = a.lastSeenAt ?? '';
          final bd = b.lastSeenAt ?? '';
          return bd.compareTo(ad);
        });
        break;
      case 'role':
      default:
        // Default-Sortierung aus dem Service ist bereits Rollen-basiert.
        break;
    }
    _filtered = sortable;
  }

  String _formatRelative(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inSeconds < 60) return 'gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'vor ${diff.inHours} h';
    return 'vor ${diff.inDays} Tagen';
  }

  static String _httpLabel(int code) {
    switch (code) {
      case 400:
        return 'Fehlerhafte Anfrage (400) - Daten pruefen.';
      case 401:
        return 'Nicht authentifiziert (401) - Erneut einloggen.';
      case 403:
        return 'Keine Berechtigung (403) - Admin-Rechte pruefen.';
      case 404:
        return 'Endpunkt nicht gefunden (404) - Worker-Version pruefen.';
      case 409:
        return 'Konflikt (409) - Aktion wurde moeglicherweise schon ausgefuehrt.';
      case 429:
        return 'Zu viele Anfragen (429) - Bitte kurz warten.';
      case 500:
        return 'Server-Fehler (500) - Worker-Logs pruefen.';
      case 502:
        return 'Worker nicht erreichbar (502) - Deployment pruefen.';
      case 503:
        return 'Dienst nicht verfuegbar (503) - Wartungsarbeiten?';
      default:
        if (code >= 500) return 'Server-Fehler ($code).';
        if (code >= 400) return 'Client-Fehler ($code).';
        return 'Fehler ($code).';
    }
  }

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color ?? const Color(0xFF1A1A2E),
      duration: const Duration(seconds: 3),
    ));
  }

  // Confirmation dialog helper
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
              backgroundColor: confirmColor ?? Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child:
                const Text('Bestätigen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _ban(WorldUser u) async {
    if (u.username.trim().toLowerCase() ==
        (widget.admin.username ?? '').trim().toLowerCase()) {
      _snack('Du kannst dich nicht selbst sperren.', color: Colors.orange);
      return;
    }
    final result = await _showBanDialog(u.username);
    if (result == null) return;

    setState(() => _processing = true);
    final ok = await WorldAdminServiceV162.banUser(
      userId: u.userId,
      reason: result['reason'] as String,
      expiresAt: result['expiresAt'] as String?,
      adminUserId: widget.admin.username,
    );
    if (!mounted) return;
    setState(() => _processing = false);
    if (ok) {
      final label = result['durationLabel'] as String;
      _snack('🚫 @${u.username} gesperrt ($label)', color: Colors.red.shade700);
      _load();
    } else {
      final errMsg = AdminApiClient.instance.diagLog.isNotEmpty
          ? AdminApiClient.instance.diagLog.last.message
          : 'Unbekannter Fehler';
      _snack('❌ Sperren fehlgeschlagen: $errMsg', color: Colors.orange);
    }
  }

  /// v117: Granulare Bereichs-Sperren -- oeffnet einen Scope-Picker.
  Future<void> _restrict(WorldUser u) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RestrictionSheet(
        user: u,
        accent: widget.accent,
        accentBright: widget.accentBright,
        adminUsername: widget.admin.username ?? '',
        onChanged: _load,
      ),
    );
  }

  // ── v123: Shadow-Ban (root_admin only) ──────────────────────────────────
  Future<void> _shadowBan(WorldUser u) async {
    if (!widget.admin.isRootAdmin) return;
    final enable = !u.isShadowBanned;
    final action = enable ? 'Shadow-sperren' : 'Shadow-Sperre aufheben';
    final confirmed = await _confirm(
      action,
      enable
          ? '@${u.username} wird Shadow-gesperrt.\n\nDer Nutzer sieht eigene '
              'Posts normal, aber andere Nutzer sehen sie nicht.'
          : '@${u.username} Shadow-Sperre wird aufgehoben.',
      confirmColor: enable ? const Color(0xFF9C27B0) : Colors.teal,
    );
    if (!confirmed) return;
    setState(() => _processing = true);
    final ok = await WorldAdminServiceV162.shadowBanUser(
      userId: u.userId,
      enable: enable,
      adminUsername: widget.admin.username,
    );
    if (!mounted) return;
    setState(() => _processing = false);
    if (ok) {
      _snack(
        enable ? '👻 @${u.username} shadow-gesperrt' : '👻 Shadow-Sperre aufgehoben',
        color: enable ? const Color(0xFF9C27B0) : Colors.teal,
      );
      _load();
    } else {
      _snack('❌ Shadow-Ban fehlgeschlagen', color: Colors.red);
    }
  }

  // ── v123: Temp-Mute (admin+) ─────────────────────────────────────────────
  Future<void> _tempMute(WorldUser u) async {
    if (u.isMuted) {
      // Immediately unmute
      final confirmed = await _confirm(
        'Entmuten',
        '@${u.username} Stummschaltung aufheben?',
        confirmColor: Colors.teal,
      );
      if (!confirmed) return;
      setState(() => _processing = true);
      final ok = await WorldAdminServiceV162.tempMuteUser(
        userId: u.userId,
        durationMinutes: 0,
        adminUsername: widget.admin.username,
      );
      if (!mounted) return;
      setState(() => _processing = false);
      if (ok) {
        _snack('🔊 @${u.username} ist nicht mehr stumm', color: Colors.teal);
        _load();
      } else {
        _snack('❌ Entmuten fehlgeschlagen', color: Colors.red);
      }
      return;
    }

    // Pick duration
    const durationLabels = ['5 Minuten', '30 Minuten', '1 Stunde', '6 Stunden', '24 Stunden', '7 Tage'];
    const durationMinutes = [5, 30, 60, 360, 1440, 10080];
    int selectedIdx = 2;
    final reasonCtrl = TextEditingController();

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDs) => AlertDialog(
          backgroundColor: const Color(0xFF12121E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.volume_off_rounded, color: Colors.blueGrey, size: 20),
            SizedBox(width: 8),
            Text('Stummschalten', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('@${u.username}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 14),
              const Text('Dauer', style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1.2)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(durationLabels.length, (i) {
                  final sel = i == selectedIdx;
                  return GestureDetector(
                    onTap: () => setDs(() => selectedIdx = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? Colors.blueGrey.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: sel ? Colors.blueGrey : Colors.white12),
                      ),
                      child: Text(durationLabels[i], style: TextStyle(color: sel ? Colors.white : Colors.white54, fontSize: 12)),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Grund (optional)',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Abbrechen', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, selectedIdx),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              child: const Text('Stummschalten'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    setState(() => _processing = true);
    final ok = await WorldAdminServiceV162.tempMuteUser(
      userId: u.userId,
      durationMinutes: durationMinutes[result],
      reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
      adminUsername: widget.admin.username,
    );
    if (!mounted) return;
    setState(() => _processing = false);
    if (ok) {
      _snack('🔇 @${u.username} für ${durationLabels[result]} stumm', color: Colors.blueGrey);
      _load();
    } else {
      _snack('❌ Stummschalten fehlgeschlagen', color: Colors.red);
    }
  }

  /// Shows a dialog to pick ban reason and duration.
  /// Returns {'reason': String, 'expiresAt': String?, 'durationLabel': String}
  /// or null if cancelled.
  Future<Map<String, Object?>?> _showBanDialog(String username) async {
    final reasonCtrl = TextEditingController(text: 'Regelverstoß');
    int selectedIdx = 2; // default: 24h
    const durationLabels = [
      '1 Stunde',
      '6 Stunden',
      '24 Stunden',
      '7 Tage',
      'Permanent'
    ];
    const durationHours = [1, 6, 24, 168, 0]; // 0 = permanent

    return showDialog<Map<String, Object?>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDs) => AlertDialog(
          backgroundColor: const Color(0xFF12121E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.block_rounded,
                  color: Colors.redAccent, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nutzer sperren',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  Text('@$username',
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dauer',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(durationLabels.length, (i) {
                    final sel = selectedIdx == i;
                    final isPerm = durationHours[i] == 0;
                    return GestureDetector(
                      onTap: () => setDs(() => selectedIdx = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel
                              ? (isPerm ? Colors.red : Colors.orange)
                                  .withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel
                                ? (isPerm ? Colors.red : Colors.orange)
                                    .withValues(alpha: 0.7)
                                : Colors.white12,
                          ),
                        ),
                        child: Text(
                          durationLabels[i],
                          style: TextStyle(
                            color: sel
                                ? (isPerm
                                    ? Colors.red.shade200
                                    : Colors.orange.shade200)
                                : Colors.white70,
                            fontSize: 12,
                            fontWeight:
                                sel ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: reasonCtrl,
                  maxLength: 200,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Grund (fuer Audit-Log + Push)',
                    labelStyle: const TextStyle(color: Colors.white54),
                    counterStyle:
                        const TextStyle(color: Colors.white24, fontSize: 10),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.redAccent.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ban wird im Audit-Log protokolliert und an den Nutzer gesendet.',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Abbrechen',
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final reason = reasonCtrl.text.trim().isEmpty
                    ? 'Regelverstoß'
                    : reasonCtrl.text.trim();
                final hours = durationHours[selectedIdx];
                String? expiresAt;
                if (hours > 0) {
                  expiresAt = DateTime.now()
                      .add(Duration(hours: hours))
                      .toUtc()
                      .toIso8601String();
                }
                Navigator.pop<Map<String, Object?>>(ctx, {
                  'reason': reason,
                  'expiresAt': expiresAt,
                  'durationLabel': durationLabels[selectedIdx],
                });
              },
              icon: const Icon(Icons.block_rounded,
                  color: Colors.white, size: 16),
              label:
                  const Text('Sperren', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unban(WorldUser u) async {
    final confirmed = await _confirm(
      'Sperre aufheben',
      'Soll die Sperre fuer @${u.username} wirklich aufgehoben werden?',
      confirmColor: Colors.teal,
    );
    if (!confirmed) return;

    setState(() => _processing = true);
    final ok = await WorldAdminServiceV162.unbanUser(
        userId: u.userId, adminUserId: widget.admin.username ?? 'admin');
    if (!mounted) return;
    setState(() => _processing = false);
    if (ok) {
      _snack('✅ @${u.username} wurde entsperrt', color: Colors.teal);
      _load();
    } else {
      final errMsg = AdminApiClient.instance.diagLog.isNotEmpty
          ? AdminApiClient.instance.diagLog.last.message
          : 'Unbekannter Fehler';
      _snack('❌ Entsperren fehlgeschlagen: $errMsg', color: Colors.orange);
    }
  }

  // v115 (Feature B): Verwarnung aussprechen. Dialog mit Grund-Feld.
  // Bei der 3. Verwarnung bannt der Worker automatisch fuer 7 Tage.
  Future<void> _warn(WorldUser u) async {
    if (u.username.trim().toLowerCase() ==
        (widget.admin.username ?? '').trim().toLowerCase()) {
      _snack('Du kannst dich nicht selbst verwarnen.', color: Colors.orange);
      return;
    }
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            String? errorText;
            return StatefulBuilder(
              builder: (ctx2, setDs) => AlertDialog(
                backgroundColor: const Color(0xFF12121E),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Row(children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.orangeAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Verwarnen (${u.warningCount}/3)',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ]),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${u.username} verwarnen. Ab der 3. Verwarnung wird der '
                      'Nutzer automatisch fuer 7 Tage gesperrt.',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonCtrl,
                      autofocus: true,
                      maxLength: 200,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Grund (Pflicht, min. 3 Zeichen)',
                        labelStyle: const TextStyle(color: Colors.white54),
                        errorText: errorText,
                        counterStyle: const TextStyle(color: Colors.white38),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx2, false),
                    child: const Text('Abbrechen',
                        style: TextStyle(color: Colors.white54)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (reasonCtrl.text.trim().length < 3) {
                        setDs(() =>
                            errorText = 'Mindestens 3 Zeichen erforderlich');
                        return;
                      }
                      Navigator.pop(ctx2, true);
                    },
                    icon: const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 16),
                    label: const Text('Verwarnen',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            );
          },
        ) ??
        false;
    if (!confirmed) return;

    setState(() => _processing = true);
    final res = await WorldAdminServiceV162.warnUser(
      userId: u.userId,
      reason: reasonCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _processing = false);
    if (res != null && res['success'] == true) {
      final count = res['warning_count'] ?? 0;
      final autoBanned = res['auto_banned'] == true;
      _snack(
        autoBanned
            ? '🚫 @${u.username}: $count. Verwarnung -> Auto-Ban (7 Tage)'
            : '⚠️ @${u.username} verwarnt ($count/3)',
        color: autoBanned ? Colors.red.shade700 : Colors.orange,
      );
      _load();
    } else {
      final errMsg = AdminApiClient.instance.diagLog.isNotEmpty
          ? AdminApiClient.instance.diagLog.last.message
          : 'Unbekannter Fehler';
      _snack('❌ Verwarnung fehlgeschlagen: $errMsg', color: Colors.orange);
    }
  }

  // v115 (Feature D): CSV-Export der aktuell gefilterten Nutzerliste.
  // Baut einen RFC-4180-konformen CSV-String und kopiert ihn in die
  // Zwischenablage (kein Datei-IO noetig -> funktioniert auf Web + App).
  Future<void> _exportCsv() async {
    final rows = _filtered.isEmpty ? _all : _filtered;
    if (rows.isEmpty) {
      _snack('Keine Nutzer zum Exportieren');
      return;
    }
    String esc(String? v) {
      final s = (v ?? '').replaceAll('"', '""');
      return '"$s"';
    }

    final buf = StringBuffer();
    buf.writeln(
        'username,display_name,role,banned,warnings,source,created_at,last_seen');
    for (final u in rows) {
      buf.writeln([
        esc(u.username),
        esc(u.displayName),
        esc(u.role),
        esc(u.isSuspended ? 'ja' : 'nein'),
        esc('${u.warningCount}'),
        esc(u.source),
        esc(u.createdAt),
        esc(u.lastSeenAt ?? ''),
      ].join(','));
    }
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (!mounted) return;
    _snack('📋 ${rows.length} Nutzer als CSV in Zwischenablage kopiert',
        color: Colors.green.shade700);
  }

  // v115 (Feature C): Interne Admin-Notizen. BottomSheet mit Liste +
  // Eingabefeld. Notizen sind NUR fuer Admins sichtbar (RLS-geschuetzt).
  Future<void> _showNotes(WorldUser u) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF12121E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _NotesSheet(
        user: u,
        accent: widget.accent,
      ),
    );
  }

  // v116: Modul-Freischaltungs-Sheet
  Future<void> _showModuleAccess(WorldUser u) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF12121E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ModuleAccessSheet(
        user: u,
        accent: widget.accent,
        adminUsername: widget.admin.username ?? '',
      ),
    );
  }

  // Feiner-granularer Rollenwechsel (v5.44.3+): erlaubt user|moderator|
  // content_editor|admin|root_admin. Promote/Demote bleiben fuer
  // Rueckwaerts-Kompatibilitaet bestehen.
  Future<void> _changeRole(WorldUser u, String newRole) async {
    if (u.role == newRole) {
      _snack('@${u.username} hat bereits diese Rolle');
      return;
    }
    // FIX (#8): Client-seitiger Hierarchie-Pre-Check. Verhindert den
    // Umweg ueber einen Worker-403 (der nur "fehlgeschlagen" zeigte).
    if (!AppRoles.canPromoteToRole(widget.admin.role, newRole)) {
      _snack(
        'Deine Rolle (${_prettyRole(widget.admin.role ?? 'user')}) darf '
        '"${_prettyRole(newRole)}" nicht vergeben.',
        color: Colors.orange,
      );
      return;
    }
    // Selbst-Aenderung blockieren (Worker macht das auch, aber sofort
    // klarere Meldung). Vergleich ueber Username da AdminState keine
    // userId fuehrt.
    final adminName = widget.admin.username?.trim().toLowerCase();
    if (adminName != null &&
        adminName.isNotEmpty &&
        u.username.trim().toLowerCase() == adminName) {
      _snack('Du kannst deine eigene Rolle nicht aendern.',
          color: Colors.orange);
      return;
    }
    final pretty = _prettyRole(newRole);
    final confirmed = await _confirm(
      'Rolle aendern',
      '@${u.username} zu Rolle "$pretty" setzen?\n\nAktuell: ${_prettyRole(u.role)}',
      confirmColor: widget.accent,
    );
    if (!confirmed) return;

    setState(() => _processing = true);
    final ok = await WorldAdminServiceV162.changeUserRole(
      userId: u.userId,
      newRole: newRole,
      adminUsername: widget.admin.username,
    );
    if (!mounted) return;
    setState(() => _processing = false);
    if (ok) {
      _snack('🛡️ @${u.username} ist jetzt $pretty', color: Colors.green);
      _load();
    } else {
      final errMsg = AdminApiClient.instance.diagLog.isNotEmpty
          ? AdminApiClient.instance.diagLog.last.message
          : 'Unbekannter Fehler';
      _snack('❌ Rollenwechsel fehlgeschlagen: $errMsg', color: Colors.orange);
    }
  }

  String _prettyRole(String r) => switch (r) {
        'root_admin' => '👑 Root-Admin',
        'admin' => '🛡️ Admin',
        'content_editor' => '✍️ Content-Editor',
        'moderator' => '🧹 Moderator',
        'user' => '👤 User',
        _ => r,
      };

  // "Befoerdern"-Button: oeffnet einen Rollen-Picker statt einer harten
  // Promotion zu 'admin'. Picker zeigt nur Rollen ueber der aktuellen,
  // die der eingeloggte Admin laut canPromoteToRole tatsaechlich vergeben
  // darf.
  Future<void> _promote(WorldUser u) async {
    const order = [
      AppRoles.user,
      AppRoles.moderator,
      AppRoles.contentEditor,
      AppRoles.admin,
      AppRoles.rootAdmin,
    ];
    final currentIdx = order.indexOf(u.role);
    final targets = order
        .where((r) =>
            r != u.role &&
            (currentIdx < 0 || order.indexOf(r) > currentIdx) &&
            AppRoles.canPromoteToRole(widget.admin.role, r))
        .toList();
    if (targets.isEmpty) {
      _snack(
        'Keine hoehere Rolle verfuegbar, die du vergeben darfst.',
        color: Colors.orange,
      );
      return;
    }
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF12121E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                const Icon(Icons.arrow_upward_rounded,
                    color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '@${u.username} befoerdern',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Aktuell: ${_prettyRole(u.role)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            const Divider(color: Colors.white12, height: 20),
            for (final r in targets)
              ListTile(
                leading: const Icon(Icons.arrow_circle_up_rounded,
                    color: Colors.greenAccent, size: 20),
                title: Text(_prettyRole(r),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                onTap: () => Navigator.pop(ctx, r),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null) return;
    await _changeRole(u, picked);
  }

  Future<void> _demote(WorldUser u) async {
    final confirmed = await _confirm(
      'Degradieren',
      'Soll @${u.username} wirklich degradiert werden?\n\nRolle wird auf "User" zurueckgesetzt.',
      confirmColor: Colors.orange,
    );
    if (!confirmed) return;

    setState(() => _processing = true);
    final ok = await WorldAdminServiceV162.changeUserRole(
      userId: u.userId,
      newRole: 'user',
      adminUsername: widget.admin.username,
    );
    if (!mounted) return;
    setState(() => _processing = false);
    if (ok) {
      _snack('⬇️ @${u.username} degradiert', color: Colors.orange);
      _load();
    } else {
      final errMsg = AdminApiClient.instance.diagLog.isNotEmpty
          ? AdminApiClient.instance.diagLog.last.message
          : 'Unbekannter Fehler';
      _snack('❌ Degradieren fehlgeschlagen: $errMsg', color: Colors.red);
    }
  }

  // v98: Hard-Delete eines Users. Nur Root-Admin. Verlangt Eingabe des
  // exakten Usernames zur Bestaetigung (Fat-Finger-Schutz).
  Future<void> _deleteUser(WorldUser u) async {
    if (!widget.admin.isRootAdmin) return;
    if (u.username.trim().toLowerCase() ==
        (widget.admin.username ?? '').trim().toLowerCase()) {
      _snack('Du kannst dich nicht selbst loeschen.', color: Colors.orange);
      return;
    }
    final confirmCtrl = TextEditingController();
    // AUDIT-FIX B13: Reason-Feld bei Hard-Delete fuer Audit-Trail.
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        bool _acknowledged = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: const Color(0xFF12121E),
            title: const Row(children: [
              Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Hard-Delete', style: TextStyle(color: Colors.white)),
            ]),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${u.username} wird unwiderruflich geloescht.\n\n'
                    'Profile-Zeile + auth.users (falls vorhanden) werden geloescht. '
                    'XP, Chat-Eintraege und alle abhaengigen Daten gehen verloren.',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Grund (Pflicht, fuer Audit-Trail):',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonCtrl,
                    maxLength: 200,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'z.B. Account-Loeschung auf Wunsch',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: const Color(0xFF1A1A26),
                      counterStyle: const TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tippe "${u.username}" zur Bestaetigung:',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: confirmCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: u.username,
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: const Color(0xFF1A1A26),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: Colors.redAccent.withValues(alpha: 0.4)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text(
                      'Ich verstehe, dies ist unwiderruflich',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    value: _acknowledged,
                    activeColor: Colors.redAccent,
                    onChanged: (v) =>
                        setDialogState(() => _acknowledged = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Abbrechen',
                      style: TextStyle(color: Colors.white60))),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white),
                icon: const Icon(Icons.delete_forever_rounded, size: 16),
                label: const Text('Endgueltig loeschen'),
                onPressed: _acknowledged &&
                        confirmCtrl.text.trim() == u.username
                    ? () {
                        if (reasonCtrl.text.trim().length < 3) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                            content:
                                Text('Grund (min. 3 Zeichen) ist Pflicht.'),
                          ));
                          return;
                        }
                        Navigator.pop(ctx, true);
                      }
                    : null,
              ),
            ],
          ),
        );
      },
    );
    if (ok != true) return;

    setState(() => _processing = true);
    final success = await WorldAdminServiceV162.deleteUser(
      userId: u.userId,
      adminUsername: widget.admin.username,
      reason: reasonCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _processing = false);
    if (success) {
      _snack('🗑️ @${u.username} geloescht', color: Colors.red);
      _load();
    } else {
      final last = AdminApiClient.instance.diagLog
          .where((e) => e.path.contains('/admin/users/'))
          .toList()
          .reversed
          .firstOrNull;
      final errMsg = (last != null && last.message != 'ok')
          ? last.message
          : 'Nutzer nicht gefunden oder Datenbankfehler';
      _snack('❌ Loeschen fehlgeschlagen: $errMsg', color: Colors.orange);
    }
  }

  // v98: Sync-Endpoint -- backfillt fehlende profiles aus auth.users.
  Future<void> _syncUsers() async {
    setState(() => _processing = true);
    final result = await WorldAdminServiceV162.syncUsers();
    if (!mounted) return;
    setState(() => _processing = false);
    if (result == null) {
      _snack('❌ Sync fehlgeschlagen', color: Colors.red);
      return;
    }
    final inserted = result['profiles_inserted'] ?? 0;
    final authSeen = result['auth_users_seen'] ?? 0;
    _snack(
      '🔄 $inserted neue Profile (von $authSeen auth-Usern)',
      color: Colors.green,
    );
    _load();
  }

  // Manual XP-Vergabe: Dialog mit Quick-Buttons (+10/+50/+100/+500/-50) und
  // freiem Eingabefeld + Begründung. Sendet an Worker → audit_log + Push.
  Future<void> _grantXp(WorldUser u) async {
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    int? selectedPreset;
    final presets = [10, 50, 100, 250, 500, -50];

    final result = await showDialog<Map<String, Object>>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF12121E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFFFC107), Color(0xFFFF9800)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('XP-Vergabe',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Empfänger: @${u.username}',
                    style: TextStyle(color: widget.accent, fontSize: 12)),
                const SizedBox(height: 14),
                const Text('Schnell-Wahl',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        letterSpacing: 1.2)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: presets.map((p) {
                    final sel = selectedPreset == p;
                    final neg = p < 0;
                    return GestureDetector(
                      onTap: () => setDialogState(() {
                        selectedPreset = p;
                        amountCtrl.text = p.toString();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel
                              ? (neg ? Colors.red : const Color(0xFFFFC107))
                                  .withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel
                                ? (neg ? Colors.red : const Color(0xFFFFC107))
                                : Colors.white12,
                          ),
                        ),
                        child: Text(
                          p > 0 ? '+$p' : '$p',
                          style: TextStyle(
                            color: sel
                                ? (neg
                                    ? Colors.red.shade100
                                    : const Color(0xFFFFE082))
                                : Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Betrag (±, max 10000)',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: widget.accent),
                    ),
                  ),
                  onChanged: (_) => setDialogState(() => selectedPreset = null),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonCtrl,
                  maxLength: 80,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Begründung (sichtbar in Push)',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    counterStyle:
                        const TextStyle(color: Colors.white24, fontSize: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: widget.accent),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Vergabe wird im Audit-Log protokolliert.',
                    style: TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, null),
              child: const Text('Abbrechen',
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final a = int.tryParse(amountCtrl.text.trim());
                if (a == null || a == 0) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(const SnackBar(
                    content: Text('Bitte gültigen Betrag eingeben'),
                    backgroundColor: Colors.redAccent,
                  ));
                  return;
                }
                final r = reasonCtrl.text.trim().isEmpty
                    ? 'Admin-Anpassung'
                    : reasonCtrl.text.trim();
                Navigator.pop<Map<String, Object>>(
                    dialogCtx, {'amount': a, 'reason': r});
              },
              icon:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 16),
              label:
                  const Text('Vergeben', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    final amount = result['amount'] as int;
    final reason = result['reason'] as String;

    setState(() => _processing = true);
    final res = await WorldAdminServiceV162.grantXp(
      userId: u.userId,
      amount: amount,
      reason: reason,
      adminUsername: widget.admin.username,
    );
    if (!mounted) return;
    setState(() => _processing = false);
    if (res != null && (res['success'] == true)) {
      final newXp = res['new_xp'];
      _snack(
        amount > 0
            ? '✨ +$amount XP an @${u.username} (neu: $newXp)'
            : '⚠️ $amount XP für @${u.username} (neu: $newXp)',
        color: amount > 0 ? Colors.green.shade700 : Colors.orange,
      );
      // Reload so the new XP value is visible in the user list immediately.
      _load();
    } else {
      _snack('❌ XP-Vergabe fehlgeschlagen', color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(children: [
          // ── Suchleiste + Filter ──────────────────────────────────
          Container(
            color: const Color(0xFF0D0D1A),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(children: [
              // User count + Quellen-Aufschluesselung + Refresh-Hint
              if (!_loading) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    // Hauptzahl: X von Y -- klar verstaendlich
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: widget.accent.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _filtered.length == _all.length
                            ? '${_all.length} Nutzer'
                            : '${_filtered.length} von ${_all.length}',
                        style: TextStyle(
                            color: widget.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Quellen-Aufschluesselung
                    Tooltip(
                      message: 'Web-Profile (via Anmeldung)',
                      child: _MiniPill(
                        label:
                            '🌐 ${_all.where((u) => u.source == 'web').length}',
                        color: const Color(0xFF4FC3F7),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'App-Profile (InvisibleAuth)',
                      child: _MiniPill(
                        label:
                            '📱 ${_all.where((u) => u.source == 'app').length}',
                        color: const Color(0xFF81C784),
                      ),
                    ),
                    const Spacer(),
                    if (_lastLoadedAt != null)
                      Text(
                        'Aktualisiert ${_formatRelative(_lastLoadedAt!)}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10),
                      ),
                    const SizedBox(width: 8),
                    // v115 (Feature D): CSV-Export der (gefilterten) Liste.
                    GestureDetector(
                      onTap: _exportCsv,
                      child: Row(children: [
                        const Icon(Icons.download_rounded,
                            color: Colors.white54, size: 14),
                        const SizedBox(width: 3),
                        const Text('Export',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 11)),
                      ]),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _load,
                      child: Row(children: [
                        Icon(Icons.refresh_rounded,
                            color: Colors.white54, size: 14),
                        const SizedBox(width: 3),
                        const Text('Neu laden',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 11)),
                      ]),
                    ),
                  ]),
                ),
                // Fehler-Banner mit Retry, falls Last-Load fehlgeschlagen ist
                if (_errorMessage != null)
                  _ErrorBanner(message: _errorMessage!, onRetry: _load),
              ],
              // Search field
              TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nutzer suchen…',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: Colors.white38),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: Colors.white38),
                          onPressed: () => setState(() {
                                _search = '';
                                _searchCtrl.clear();
                                _applyFilter();
                              }))
                      : null,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: widget.accent.withValues(alpha: 0.4))),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (v) => setState(() {
                  _search = v;
                  _applyFilter();
                }),
              ),
              const SizedBox(height: 8),
              // Role filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      ['all', 'user', 'admin', 'root_admin', 'banned'].map((r) {
                    final labels = {
                      'all': '✦ Alle',
                      'user': '👤 User',
                      'admin': '🛡️ Admin',
                      'root_admin': '👑 Root',
                      'banned': '🚫 Gesperrt',
                    };
                    final sel = _roleFilter == r;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _roleFilter = r;
                          _applyFilter();
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? widget.accent.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: sel ? widget.accent : Colors.transparent,
                                width: 1.5),
                          ),
                          child: Text(labels[r]!,
                              style: TextStyle(
                                  color: sel
                                      ? widget.accentBright
                                      : Colors.white54,
                                  fontSize: 12,
                                  fontWeight: sel
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // v123: Bot-Verdacht Filter (Moderator+)
              if (AppRoles.canBanUsers(widget.admin.role))
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _showBotSuspects = !_showBotSuspects;
                      _applyFilter();
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _showBotSuspects
                            ? const Color(0xFFFF6F00).withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _showBotSuspects ? const Color(0xFFFF6F00) : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '🤖 Bot-Verdacht',
                        style: TextStyle(
                          color: _showBotSuspects ? const Color(0xFFFF6F00) : Colors.white54,
                          fontSize: 12,
                          fontWeight: _showBotSuspects ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              // Ghost-User toggle + Sort-Dropdown
              Row(children: [
                GestureDetector(
                  onTap: () => setState(() {
                    _hideGhosts = !_hideGhosts;
                    _applyFilter();
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _hideGhosts
                          ? Colors.orange.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _hideGhosts
                              ? Colors.orange.withValues(alpha: 0.5)
                              : Colors.transparent,
                          width: 1.5),
                    ),
                    child: Text(
                      _hideGhosts ? '👥 Echte Profile' : '👻 Alle inkl. Ghosts',
                      style: TextStyle(
                          color: _hideGhosts
                              ? Colors.orange.shade200
                              : Colors.white54,
                          fontSize: 11,
                          fontWeight: _hideGhosts
                              ? FontWeight.bold
                              : FontWeight.normal),
                    ),
                  ),
                ),
                const Spacer(),
                // Sort-Dropdown
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortMode,
                      dropdownColor: const Color(0xFF1A1A2E),
                      iconEnabledColor: Colors.white54,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      isDense: true,
                      items: const [
                        DropdownMenuItem(value: 'role', child: Text('↕ Rolle')),
                        DropdownMenuItem(
                            value: 'newest', child: Text('🕒 Neueste')),
                        DropdownMenuItem(
                            value: 'oldest', child: Text('📜 Aelteste')),
                        DropdownMenuItem(value: 'az', child: Text('🔤 A-Z')),
                        DropdownMenuItem(
                            value: 'online', child: Text('🟢 Online zuerst')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _sortMode = v;
                            _applyFilter();
                          });
                        }
                      },
                    ),
                  ),
                ),
              ]),
            ]),
          ),

          // ── Ghost-Bereinigung (root_admin only, nur wenn Ghosts vorhanden) ──
          Builder(builder: (ctx) {
            final ghosts = _all.where((u) => u.isGhostUser).toList();
            if (!widget.admin.isRootAdmin || ghosts.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: GestureDetector(
                onTap: () => _bulkDeleteGhosts(ghosts),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Row(children: [
                    const Icon(Icons.delete_sweep_rounded,
                        color: Colors.redAccent, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      '${ghosts.length} Ghost-Profile bereinigen',
                      style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const Text('(Hard-Delete)',
                        style: TextStyle(color: Colors.red, fontSize: 10)),
                  ]),
                ),
              ),
            );
          }),

          // ── Antrags-Inbox (Reaktivierung/Einspruch/Selbstloesch) ──────
          if (AppRoles.canBanUsers(widget.admin.role))
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: GestureDetector(
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _AccountRequestsSheet(
                    accent: widget.accent,
                    accentBright: widget.accentBright,
                  ),
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: widget.accent.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Row(children: [
                    Icon(Icons.inbox_rounded,
                        color: widget.accentBright, size: 15),
                    const SizedBox(width: 6),
                    Text('Antraege (Reaktivierung / Einspruch / Loeschung)',
                        style: TextStyle(
                            color: widget.accentBright,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        color: Colors.white38, size: 16),
                  ]),
                ),
              ),
            ),

          // ── User List ─────────────────────────────────────────────
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: widget.accent))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: widget.accent,
                    child: _filtered.isEmpty
                        ? ListView(children: [
                            const SizedBox(height: 40),
                            _EmptyHint(
                              _all.isEmpty
                                  ? 'Noch keine Profile geladen.\nZiehe nach unten zum Aktualisieren.'
                                  : 'Keine Treffer bei den aktuellen Filtern.\nLeere Suche oder waehle "Alle".',
                            ),
                          ])
                        : ListView.builder(
                            itemCount: _filtered.length,
                            padding: EdgeInsets.only(
                                top: 4,
                                bottom: _selectedIds.isNotEmpty ? 90 : 16),
                            itemBuilder: (ctx, i) {
                              final u = _filtered[i];
                              final selected = _selectedIds.contains(u.userId);
                              return Row(children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Checkbox(
                                    value: selected,
                                    activeColor: widget.accent,
                                    onChanged: (v) => setState(() {
                                      if (v == true) {
                                        _selectedIds.add(u.userId);
                                      } else {
                                        _selectedIds.remove(u.userId);
                                      }
                                    }),
                                  ),
                                ),
                                Expanded(
                                  child: _UserTile(
                                    user: u,
                                    isRootAdmin: widget.admin.isRootAdmin,
                                    actorRole: widget.admin.role,
                                    accent: widget.accent,
                                    accentBright: widget.accentBright,
                                    onBan: () => _ban(u),
                                    onUnban: () => _unban(u),
                                    onPromote: () => _promote(u),
                                    onDemote: () => _demote(u),
                                    onGrantXp:
                                        AppRoles.canGrantXp(widget.admin.role)
                                            ? () => _grantXp(u)
                                            : null,
                                    onDelete: AppRoles.canDeleteUsers(
                                            widget.admin.role)
                                        ? () => _deleteUser(u)
                                        : null,
                                    onWarn: () => _warn(u),
                                    onNotes: () => _showNotes(u),
                                    onModuleAccess:
                                        AppRoles.canBanUsers(widget.admin.role)
                                            ? () => _showModuleAccess(u)
                                            : null,
                                    onChangeRole: AppRoles.canPromoteDemote(
                                            widget.admin.role)
                                        ? (newRole) => _changeRole(u, newRole)
                                        : null,
                                    onViewDetail: () => _viewDetail(u),
                                    onRestrict:
                                        AppRoles.canBanUsers(widget.admin.role)
                                            ? () => _restrict(u)
                                            : null,
                                    onShadowBan: widget.admin.isRootAdmin
                                        ? () => _shadowBan(u)
                                        : null,
                                    onTempMute:
                                        AppRoles.canBanUsers(widget.admin.role)
                                            ? () => _tempMute(u)
                                            : null,
                                  ),
                                ),
                              ]);
                            },
                          ),
                  ),
          ),
        ]),

        // Bulk-Action-Bar — schwebt unten wenn _selectedIds nicht leer
        if (_selectedIds.isNotEmpty)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _BulkActionBar(
              count: _selectedIds.length,
              accent: widget.accent,
              accentBright: widget.accentBright,
              onSelectAll: () => setState(() {
                _selectedIds
                  ..clear()
                  ..addAll(_filtered
                      .map((u) => u.userId)
                      .where((id) => id.isNotEmpty));
              }),
              onPromote: _bulkPromote,
              onDemote: _bulkDemote,
              onBan: _bulkBan,
              onUnban: _bulkUnban,
              onDelete: widget.admin.isRootAdmin ? _bulkDelete : null,
              onWarn: AppRoles.canBanUsers(widget.admin.role) ? _bulkWarn : null,
              onRoleChange: AppRoles.canPromoteDemote(widget.admin.role) ? _bulkChangeRoleDialog : null,
              onClear: () => setState(_selectedIds.clear),
            ),
          ),

        // Processing overlay -- AbsorbPointer blockiert Doppel-Taps
        if (_processing)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: widget.accent),
                        const SizedBox(height: 16),
                        const Text('Wird verarbeitet…',
                            style: TextStyle(color: Colors.white70)),
                      ]),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Bulk-Actions ────────────────────────────────────────────────────
  Future<void> _bulkApply({
    required String label,
    required Future<bool> Function(WorldUser u) action,
  }) async {
    final targets = _all.where((u) => _selectedIds.contains(u.userId)).toList();
    if (targets.isEmpty) return;
    final ok = await _confirm(
      label,
      'Aktion auf ${targets.length} Nutzer anwenden?',
    );
    if (!ok) return;
    setState(() => _processing = true);
    int success = 0, failed = 0;
    for (final u in targets) {
      try {
        if (await action(u)) {
          success++;
        } else {
          failed++;
        }
      } catch (_) {
        failed++;
      }
    }
    if (!mounted) return;
    setState(() {
      _processing = false;
      _selectedIds.clear();
    });
    _snack(
        '✅ $success erfolgreich${failed > 0 ? ', $failed fehlgeschlagen' : ''}');
    _load();
  }

  Future<void> _bulkPromote() => _bulkApply(
        label: 'Befoerdern (Bulk)',
        action: (u) async => WorldAdminServiceV162.changeUserRole(
          userId: u.userId,
          newRole: 'admin',
          adminUsername: widget.admin.username,
        ),
      );
  Future<void> _bulkDemote() => _bulkApply(
        label: 'Degradieren (Bulk)',
        action: (u) async => WorldAdminServiceV162.changeUserRole(
          userId: u.userId,
          newRole: 'user',
          adminUsername: widget.admin.username,
        ),
      );
  Future<void> _bulkBan() => _bulkApply(
        label: 'Bannen (Bulk)',
        action: (u) async => WorldAdminServiceV162.banUser(
          userId: u.userId,
          reason: 'Bulk-Admin-Aktion',
          adminUserId: widget.admin.username,
        ),
      );
  Future<void> _bulkUnban() => _bulkApply(
        label: 'Entbannen (Bulk)',
        action: (u) async => WorldAdminServiceV162.unbanUser(
          userId: u.userId,
          adminUserId: widget.admin.username,
        ),
      );

  // v123: Bulk-Warn via single Worker call (more efficient than _bulkApply loop).
  Future<void> _bulkWarn() async {
    final targets = _all.where((u) => _selectedIds.contains(u.userId)).toList();
    if (targets.isEmpty) return;
    final reasonCtrl = TextEditingController(text: 'Regelverstoß (Bulk)');
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12121E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${targets.length} Nutzer verwarnen', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: reasonCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Grund',
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim().isEmpty ? 'Regelverstoß' : reasonCtrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            child: const Text('Verwarnen', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
    if (reason == null) return;
    setState(() => _processing = true);
    final ok = await WorldAdminServiceV162.bulkWarnUsers(
      userIds: targets.map((u) => u.userId).toList(),
      reason: reason,
      adminUsername: widget.admin.username,
    );
    if (!mounted) return;
    setState(() {
      _processing = false;
      _selectedIds.clear();
    });
    _snack(ok ? '⚠️ ${targets.length} Nutzer verwarnt' : '❌ Bulk-Verwarnung fehlgeschlagen',
        color: ok ? Colors.orange : Colors.red);
    if (ok) _load();
  }

  // v123: Bulk-Rollenwechsel via single Worker call.
  Future<void> _bulkChangeRoleDialog() async {
    final targets = _all.where((u) => _selectedIds.contains(u.userId)).toList();
    if (targets.isEmpty) return;
    String? newRole;
    final roles = AppRoles.rolesForPromotion(widget.admin.role);
    newRole = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12121E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${targets.length} Nutzer: Rolle setzen', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: roles.map((r) => ListTile(
            title: Text(_prettyRole(r), style: const TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(ctx, r),
          )).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen', style: TextStyle(color: Colors.white54))),
        ],
      ),
    );
    if (newRole == null) return;
    setState(() => _processing = true);
    final ok = await WorldAdminServiceV162.bulkChangeRole(
      userIds: targets.map((u) => u.userId).toList(),
      newRole: newRole,
      adminUsername: widget.admin.username,
    );
    if (!mounted) return;
    setState(() {
      _processing = false;
      _selectedIds.clear();
    });
    _snack(ok ? '🛡️ Rolle auf $_prettyRole($newRole) gesetzt' : '❌ Bulk-Rollenwechsel fehlgeschlagen',
        color: ok ? Colors.green : Colors.red);
    if (ok) _load();
  }

  // Hard-Delete der aktuell ausgewaehlten Nutzer (root_admin only).
  // Separate Methode statt _bulkApply weil Loeschen destruktiv ist und einen
  // roten Bestaetigungs-Dialog braucht.
  Future<void> _bulkDelete() async {
    if (!widget.admin.isRootAdmin) return;
    final targets = _all.where((u) => _selectedIds.contains(u.userId)).toList();
    if (targets.isEmpty) return;
    final confirmed = await _confirm(
      'Nutzer loeschen',
      '${targets.length} Nutzer werden unwiderruflich geloescht.\n\n'
          'Profil, Fortschritt und alle zugehoerigen Daten gehen verloren.',
      confirmColor: Colors.red,
    );
    if (!confirmed) return;

    setState(() => _processing = true);
    int deleted = 0, failed = 0;
    for (final u in targets) {
      try {
        if (await WorldAdminServiceV162.deleteUser(
          userId: u.userId,
          reason: 'Bulk-Loeschung',
          adminUsername: widget.admin.username,
        )) {
          deleted++;
        } else {
          failed++;
        }
      } catch (_) {
        failed++;
      }
    }
    if (!mounted) return;
    setState(() {
      _processing = false;
      _selectedIds.clear();
    });
    _snack(
      failed == 0
          ? '🗑️ $deleted Nutzer geloescht'
          : '🗑️ $deleted geloescht, $failed fehlgeschlagen',
      color: deleted > 0 ? Colors.orange : Colors.red,
    );
    _load();
  }

  // Hard-Delete aller uebergebenen Ghost-Profile nach Bestaetigungs-Dialog.
  Future<void> _bulkDeleteGhosts(List<WorldUser> ghosts) async {
    if (!widget.admin.isRootAdmin) return;
    final confirmed = await _confirm(
      'Ghost-Profile loeschen',
      '${ghosts.length} automatisch generierte Profile (user_<ts>) werden '
          'unwiderruflich geloescht.\n\nDiese Nutzer haben sich nie '
          'eingeloggt / kein echtes Profil angelegt.',
      confirmColor: Colors.red,
    );
    if (!confirmed) return;

    setState(() => _processing = true);
    int deleted = 0;
    for (final u in ghosts) {
      final ok = await WorldAdminServiceV162.deleteUser(
        userId: u.userId,
        reason: 'Bulk Ghost-Bereinigung',
        adminUsername: widget.admin.username,
      );
      if (ok) deleted++;
    }
    if (!mounted) return;
    setState(() => _processing = false);
    _snack(
      deleted == ghosts.length
          ? '🗑️ $deleted Ghost-Profile geloescht'
          : '🗑️ $deleted/${ghosts.length} geloescht (${ghosts.length - deleted} Fehler)',
      color: deleted > 0 ? Colors.orange : Colors.red,
    );
    _load();
  }

  Future<void> _viewDetail(WorldUser u) async {
    if (u.isWebOnly) {
      _snack('Noch kein vollstaendiges Profil -- Detail nicht verfuegbar.',
          color: Colors.orange);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserDetailSheet(
        user: u,
        accent: widget.accent,
        accentBright: widget.accentBright,
        isRootAdmin: widget.admin.isRootAdmin,
        adminUsername: widget.admin.username ?? '',
      ),
    );
  }
}
