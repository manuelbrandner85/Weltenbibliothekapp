// GENERATED SPLIT (TEIL 1B): part of world_admin_dashboard library.
// No logic changes -- structural extraction only.
part of '../world_admin_dashboard.dart';

class _PushBroadcastTab extends StatefulWidget {
  final Color accent;
  final Color accentBright;
  const _PushBroadcastTab({required this.accent, required this.accentBright});

  @override
  State<_PushBroadcastTab> createState() => _PushBroadcastTabState();
}

class _PushBroadcastTabState extends State<_PushBroadcastTab> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _deeplink = TextEditingController();
  String _target = 'all';
  bool _sending = false;
  List<Map<String, dynamic>> _history = [];
  bool _loadingHistory = true;

  // Direct push to single user
  final _directUsername = TextEditingController();
  final _directTitle = TextEditingController();
  final _directBody = TextEditingController();
  bool _sendingDirect = false;

  // Push delivery stats
  Map<String, dynamic>? _pushStats;
  bool _loadingStats = true;
  bool _clearingQueue = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadStats();
  }

  /// Leert die Push-Zaehler.
  /// scope='failed' (nur Fehler), 'pending' (nur Ausstehend),
  /// 'all' (sent+failed) oder 'everything' (alle drei Zaehler -> Voll-Reset).
  Future<void> _clearQueue(String scope) async {
    final titles = {
      'failed': 'Fehler loeschen',
      'pending': 'Ausstehende loeschen',
      'all': 'Statistik leeren',
      'everything': 'Alle Zaehler zuruecksetzen',
    };
    final bodies = {
      'failed':
          'Alle fehlgeschlagenen Push-Eintraege entfernen? Der Fehler-Zaehler wird auf 0 gesetzt.',
      'pending':
          'Alle ausstehenden Push-Eintraege entfernen? Diese werden dann NICHT mehr zugestellt. '
              'Sinnvoll um einen festgefahrenen Backlog zu raeumen.',
      'all':
          'Alle erledigten Push-Eintraege (zugestellt + fehlgeschlagen) entfernen?',
      'everything':
          'ALLE Push-Eintraege entfernen (zugestellt + fehlgeschlagen + ausstehend)? '
              'Setzt alle drei Zaehler auf 0. Ausstehende werden nicht mehr gesendet.',
    };
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF12121E),
            title: Text(titles[scope] ?? 'Loeschen',
                style: const TextStyle(color: Colors.white)),
            content: Text(bodies[scope] ?? '',
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
    setState(() => _clearingQueue = true);
    final ok = await WorldAdminServiceV162.clearPushQueue(scope: scope);
    if (!mounted) return;
    setState(() => _clearingQueue = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Push-Zaehler bereinigt' : 'Loeschen fehlgeschlagen'),
      backgroundColor: ok ? Colors.green : Colors.redAccent,
    ));
    if (ok) _loadStats();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _loadingStats = true);
    final stats = await WorldAdminServiceV162.getPushStats();
    if (mounted)
      setState(() {
        _pushStats = stats;
        _loadingStats = false;
      });
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _deeplink.dispose();
    _directUsername.dispose();
    _directTitle.dispose();
    _directBody.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final headers = await AdminAuthService.instance.headers();
      final res = await http
          .get(
            Uri.parse('${ApiConfig.workerUrl}/api/admin/push/history'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (data['broadcasts'] as List?) ?? const [];
        if (mounted) {
          setState(() {
            _history = list.cast<Map<String, dynamic>>();
            _loadingHistory = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Verlauf leeren',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
            'Alle gesendeten Broadcasts aus dem Verlauf loeschen?\nDie Nachrichten wurden bereits zugestellt.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leeren', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final adminHeaders = await AdminAuthService.instance.headers();
      final res = await http
          .delete(
            Uri.parse('${ApiConfig.workerUrl}/api/admin/push/history'),
            headers: adminHeaders,
          )
          .timeout(const Duration(seconds: 15));
      if (mounted) {
        if (res.statusCode == 200) {
          setState(() => _history = []);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Verlauf geleert'),
            backgroundColor: widget.accent,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Fehler ${res.statusCode}'),
            backgroundColor: Colors.redAccent,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Netzwerkfehler'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  Future<void> _send() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Titel und Body sind pflicht'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    setState(() => _sending = true);
    try {
      final adminHeaders = await AdminAuthService.instance.headers();
      final res = await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/admin/push/broadcast'),
            headers: {
              'Content-Type': 'application/json',
              ...adminHeaders,
            },
            body: jsonEncode({
              'target': _target,
              'title': _title.text.trim(),
              'body': _body.text.trim(),
              if (_deeplink.text.trim().isNotEmpty)
                'deeplink': _deeplink.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final enq = data['enqueued'] ?? 0;
        // v103 (5.1): Zusaetzlicher Broadcast ueber den neuen Endpoint --
        // schreibt admin_audit_log mit Admin-Username und sendet via
        // sendPushToUser direkt an alle aktiven Subscriptions.
        // Fire-and-forget, blockiert die UI nicht.
        if (_target == 'all') {
          // 2026-06-07: Ein-Profil-Migration -- vorher wurden getMaterieProfile()
          // UND getEnergieProfile() abgefragt; beide projizieren auf denselben
          // Unified-Store. Einmal getProfile() reicht.
          final adminName = StorageService().getProfile()?.username ??
              supabase.auth.currentUser?.email ??
              'admin';
          PushNotificationHelper.instance
              .sendBroadcast(
                title: _title.text.trim(),
                body: _body.text.trim(),
                adminUsername: adminName,
                data: _deeplink.text.trim().isEmpty
                    ? null
                    : {'deeplink': _deeplink.text.trim()},
              )
              .ignore();
        }
        if (mounted) {
          if (enq == 0) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                '⚠️ 0 Empfaenger eingereiht - keine aktiven Push-Subscriptions '
                'oder falscher Zielbereich gewahlt.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  '✅ $enq Empfaenger in Queue - Cron sendet via FCM (max 5min)'),
              backgroundColor: widget.accent,
            ));
          }
          _title.clear();
          _body.clear();
          _deeplink.clear();
          await _loadHistory();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('❌ Fehler ${res.statusCode}: ${res.body}'),
            backgroundColor: Colors.redAccent,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Netzwerk. Bitte erneut versuchen.'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendDirect() async {
    final recipient = _directUsername.text.trim();
    final title = _directTitle.text.trim();
    final body = _directBody.text.trim();
    if (recipient.isEmpty || title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Empfaenger, Titel und Nachricht sind Pflichtfelder'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    setState(() => _sendingDirect = true);
    final (ok, errMsg) = await WorldAdminServiceV162.sendDirectPush(
      username: recipient,
      title: title,
      body: body,
    );
    if (!mounted) return;
    setState(() => _sendingDirect = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? '✅ Push an "$recipient" gesendet'
          : '❌ ${errMsg ?? "Nutzer nicht gefunden oder Push fehlgeschlagen"}'),
      backgroundColor: ok ? Colors.green : Colors.redAccent,
    ));
    if (ok) {
      _directTitle.clear();
      _directBody.clear();
    }
  }

  // Zeigt eine Klartext-Warnung wenn FCM nicht korrekt konfiguriert ist
  // (haeufigste Ursache fuer "Push kommt nicht an").
  Widget _buildFcmStatusBanner(String status, String? error, int devices) {
    final isInvalid = status == 'invalid';
    final color = isInvalid ? Colors.red : Colors.orange;
    final title = isInvalid
        ? 'FCM falsch konfiguriert - es gehen KEINE Push-Nachrichten raus'
        : 'FCM nicht eingerichtet - nur In-App-Benachrichtigungen';
    final detail = isInvalid
        ? 'Das Secret FCM_SERVICE_ACCOUNT ist gesetzt, aber ungueltig '
            '(kein valides Firebase-Service-Account-JSON). Bitte in den '
            'GitHub-Repo-Secrets FCM_SERVICE_ACCOUNT_JSON durch das korrekte '
            'JSON ersetzen und den Worker neu deployen.'
        : 'Kein FCM_SERVICE_ACCOUNT-Secret hinterlegt. Setze es in den '
            'GitHub-Repo-Secrets (FCM_SERVICE_ACCOUNT_JSON), damit echte '
            'Push-Nachrichten zugestellt werden koennen.';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.warning_amber_rounded, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      color: color, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(detail,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 6),
          Text('Registrierte Geraete mit Token: $devices',
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
          if (error != null) ...[
            const SizedBox(height: 4),
            Text('Fehler: $error',
                style: TextStyle(
                    color: color.withValues(alpha: 0.8), fontSize: 10)),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _pushStats;
    final totalSent = stats?['total_sent'] as int? ?? 0;
    final totalFailed = stats?['total_failed'] as int? ?? 0;
    final totalPending = stats?['total_pending'] as int? ?? 0;
    final fcmStatus = stats?['fcm_status'] as String?;
    final fcmError = stats?['fcm_error'] as String?;
    final devices = stats?['registered_devices'] as int? ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── FCM-Konfigurationsstatus ──────────────────────────────
          if (fcmStatus != null && fcmStatus != 'ok')
            _buildFcmStatusBanner(fcmStatus, fcmError, devices),
          if (fcmStatus != null && fcmStatus != 'ok')
            const SizedBox(height: 12),
          // ── Push-Zustellstatistik ─────────────────────────────────
          Row(children: [
            Expanded(
                child: _PushStatCard('Zugestellt', totalSent.toString(),
                    Icons.check_circle_rounded, Colors.green, widget.accent)),
            const SizedBox(width: 8),
            Expanded(
                child: _PushStatCard('Fehlgeschlagen', totalFailed.toString(),
                    Icons.error_rounded, Colors.red, widget.accent)),
            const SizedBox(width: 8),
            Expanded(
                child: _PushStatCard('Ausstehend', totalPending.toString(),
                    Icons.schedule_rounded, Colors.orange, widget.accent)),
          ]),
          // Aufraeumen-Aktionen fuer die Zaehler (sonst bleiben Zahlen ewig).
          // Jeder Zaehler einzeln loeschbar + ein Voll-Reset.
          if (totalFailed > 0 || totalSent > 0 || totalPending > 0) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (totalFailed > 0)
                  OutlinedButton.icon(
                    onPressed:
                        _clearingQueue ? null : () => _clearQueue('failed'),
                    icon: const Icon(Icons.cleaning_services_rounded, size: 14),
                    label: Text('Fehler ($totalFailed)',
                        style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(
                          color: Colors.redAccent.withValues(alpha: 0.5)),
                    ),
                  ),
                if (totalPending > 0)
                  OutlinedButton.icon(
                    onPressed:
                        _clearingQueue ? null : () => _clearQueue('pending'),
                    icon: const Icon(Icons.schedule_rounded, size: 14),
                    label: Text('Ausstehend ($totalPending)',
                        style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: BorderSide(
                          color: Colors.orange.withValues(alpha: 0.5)),
                    ),
                  ),
                if (totalSent > 0)
                  OutlinedButton.icon(
                    onPressed: _clearingQueue ? null : () => _clearQueue('all'),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 14),
                    label: Text('Erledigte ($totalSent)',
                        style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white54,
                      side: const BorderSide(color: Colors.white24),
                    ),
                  ),
                // Voll-Reset immer anbieten wenn mind. 2 Zaehler belegt sind.
                if ([totalFailed, totalPending, totalSent]
                        .where((n) => n > 0)
                        .length >=
                    2)
                  OutlinedButton.icon(
                    onPressed:
                        _clearingQueue ? null : () => _clearQueue('everything'),
                    icon: _clearingQueue
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.restart_alt_rounded, size: 14),
                    label: const Text('Alles zuruecksetzen',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red.withValues(alpha: 0.25),
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                widget.accent.withValues(alpha: 0.35),
                widget.accent.withValues(alpha: 0.1)
              ]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.accent.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PUSH BROADCAST',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _field('Empfänger-Zielgruppe', children: [
                  for (final t in [
                    'all',
                    'admins',
                    'active',
                    'materie',
                    'energie',
                    'vorhang',
                    'ursprung'
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(t.toUpperCase(),
                            style: const TextStyle(fontSize: 10)),
                        selected: _target == t,
                        onSelected: (_) => setState(() => _target = t),
                        selectedColor: widget.accent,
                      ),
                    ),
                ]),
                const SizedBox(height: 10),
                TextField(
                  controller: _title,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDeco('Titel (max 60 Zeichen)'),
                  maxLength: 60,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _body,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  maxLength: 200,
                  decoration: _inputDeco('Body (max 200 Zeichen)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _deeplink,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      _inputDeco('Deeplink (optional, z.B. /vorhang/module)'),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send),
                    label: Text(_sending ? 'Sende…' : 'BROADCAST SENDEN',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Direktnachricht an einzelnen Nutzer ───────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: widget.accent.withValues(alpha: 0.25), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.person_pin_rounded,
                      color: widget.accent, size: 18),
                  const SizedBox(width: 8),
                  Text('DIREKTNACHRICHT',
                      style: TextStyle(
                          color: widget.accentBright,
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: _directUsername,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDeco('Name oder @Username des Empfaengers'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _directTitle,
                  style: const TextStyle(color: Colors.white),
                  maxLength: 60,
                  decoration: _inputDeco('Titel'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _directBody,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  maxLength: 200,
                  decoration: _inputDeco('Nachricht'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _sendingDirect ? null : _sendDirect,
                    icon: _sendingDirect
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 16),
                    label: Text(_sendingDirect ? 'Sende...' : 'DIREKT SENDEN',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Row(children: [
            Text('VERLAUF · ${_history.length} Broadcasts',
                style: TextStyle(
                    color: widget.accentBright,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            if (_history.isNotEmpty)
              TextButton.icon(
                onPressed: _clearHistory,
                icon: const Icon(Icons.delete_sweep_rounded, size: 14),
                label: const Text('Leeren', style: TextStyle(fontSize: 11)),
                style:
                    TextButton.styleFrom(foregroundColor: Colors.red.shade300),
              ),
            IconButton(
              icon: Icon(Icons.refresh, color: widget.accent),
              onPressed: _loadHistory,
            ),
          ]),
          const SizedBox(height: 8),
          if (_loadingHistory)
            const Center(child: CircularProgressIndicator())
          else if (_history.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Noch keine Broadcasts',
                    style: TextStyle(color: Colors.white60)),
              ),
            )
          else
            for (final b in _history) _buildHistoryCard(b),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> b) {
    final sent = (b['sent'] as num?)?.toInt() ?? 0;
    final failed = (b['failed'] as num?)?.toInt() ?? 0;
    final pending = (b['pending'] as num?)?.toInt() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text((b['title'] as String?) ?? '',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          Text((b['body'] as String?) ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(children: [
            Text((b['created_at'] as String?)?.substring(0, 16) ?? '',
                style: const TextStyle(color: Colors.white54, fontSize: 10)),
            const Spacer(),
            _stat('✓', sent, Colors.green),
            const SizedBox(width: 6),
            _stat('⏳', pending, Colors.amber),
            const SizedBox(width: 6),
            _stat('✗', failed, Colors.redAccent),
          ]),
        ],
      ),
    );
  }

  Widget _stat(String icon, int n, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: c.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8)),
        child: Text('$icon $n',
            style:
                TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
        isDense: true,
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.4),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        counterStyle: const TextStyle(color: Colors.white38, fontSize: 10),
      );

  Widget _field(String label, {required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: widget.accentBright,
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        SingleChildScrollView(
            scrollDirection: Axis.horizontal, child: Row(children: children)),
      ],
    );
  }
}

class _PushStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, accent;
  const _PushStatCard(
      this.label, this.value, this.icon, this.color, this.accent);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 9),
              textAlign: TextAlign.center),
        ]),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// v117: RESTRICTION-SHEET -- granulare Bereichs-Sperren waehlen
// ═════════════════════════════════════════════════════════════════════════════
