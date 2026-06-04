// GENERATED SPLIT (TEIL 1B): part of world_admin_dashboard library.
// No logic changes -- structural extraction only.
part of '../world_admin_dashboard.dart';

// ═════════════════════════════════════════════════════════════════════════════
// TAB 4 – SYSTEM / HEALTH
// ═════════════════════════════════════════════════════════════════════════════
class _SystemTab extends StatefulWidget {
  final Color accent, accentBright;
  final AdminState admin;
  const _SystemTab(
      {required this.accent, required this.accentBright, required this.admin});
  @override
  State<_SystemTab> createState() => _SystemTabState();
}

class _SystemTabState extends State<_SystemTab> {
  final _health = HealthCheckService();
  bool _ready = false;
  bool _checking = false;

  // App-Config state
  List<Map<String, dynamic>>? _appConfigRows;
  bool _appConfigLoading = false;

  @override
  void initState() {
    super.initState();
    _init();
    // PERF-FIX (#1): Statt Timer.periodic alle 2s (= bis zu 1800 leere
    // Rebuilds/Stunde, Akku-Drain) hoeren wir auf den ChangeNotifier.
    // Rebuild nur wenn sich der Health-Status tatsaechlich aendert.
    _health.addListener(_onHealthChanged);
    if (widget.admin.isRootAdmin) _loadAppConfig();
  }

  void _onHealthChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _init() async {
    await _health.initialize();
    _health.startMonitoring(interval: const Duration(seconds: 30));
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _loadAppConfig() async {
    if (!mounted) return;
    setState(() => _appConfigLoading = true);
    final rows = await WorldAdminServiceV162.getAppConfig();
    if (mounted)
      setState(() {
        _appConfigRows = rows;
        _appConfigLoading = false;
      });
  }

  Future<void> _editAppConfig(Map<String, dynamic> row) async {
    final platform = row['platform'] as String? ?? 'android';
    final latestCtrl =
        TextEditingController(text: row['latest_version'] as String? ?? '');
    final minCtrl =
        TextEditingController(text: row['min_version'] as String? ?? '');
    final urlCtrl =
        TextEditingController(text: row['apk_download_url'] as String? ?? '');
    final changelogCtrl =
        TextEditingController(text: row['changelog'] as String? ?? '');
    final patchCtrl =
        TextEditingController(text: row['patch_changelog'] as String? ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12121E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.system_update_rounded, color: widget.accent, size: 20),
          const SizedBox(width: 8),
          Text('App-Config ($platform)',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildConfigField(latestCtrl, 'Aktuelle Version (latest_version)',
                  '1.0.0', Icons.new_releases_rounded),
              const SizedBox(height: 10),
              _buildConfigField(minCtrl, 'Mindestversion (min_version)',
                  '0.9.0', Icons.block_rounded),
              const SizedBox(height: 10),
              _buildConfigField(urlCtrl, 'APK-Download-URL', 'https://',
                  Icons.download_rounded),
              const SizedBox(height: 10),
              _buildConfigField(changelogCtrl, 'Changelog (Release)',
                  'Was ist neu?', Icons.notes_rounded,
                  maxLines: 4),
              const SizedBox(height: 10),
              _buildConfigField(patchCtrl, 'Patch-Changelog (OTA)',
                  'Bugfixes...', Icons.auto_fix_high_rounded,
                  maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: widget.accent),
            child:
                const Text('Speichern', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;

    setState(() => _appConfigLoading = true);
    final ok = await WorldAdminServiceV162.updateAppConfig(
      platform: platform,
      updates: {
        'latest_version': latestCtrl.text.trim(),
        'min_version': minCtrl.text.trim(),
        'apk_download_url': urlCtrl.text.trim(),
        'changelog': changelogCtrl.text.trim(),
        'patch_changelog': patchCtrl.text.trim(),
      },
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? '✅ app_config ($platform) gespeichert'
          : '❌ Speichern fehlgeschlagen'),
      backgroundColor: ok ? Colors.green : Colors.orange,
    ));
    _loadAppConfig();
  }

  Widget _buildConfigField(
      TextEditingController ctrl, String label, String hint, IconData icon,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: Colors.white38, size: 16),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Future<void> _checkAll() async {
    setState(() => _checking = true);
    await _health.checkAllServices();
    if (mounted) setState(() => _checking = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('✅ System-Check abgeschlossen'),
        backgroundColor: widget.accent,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  void dispose() {
    _health.removeListener(_onHealthChanged);
    _health.stopMonitoring();
    super.dispose();
  }

  // FIX (#2): Metric-Cards hatten leere onTap-Handler (tote Buttons).
  // Jetzt zeigen sie eine kurze Erklaerung der jeweiligen Metrik.
  void _explainMetric(String title, String body) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12121E),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(body,
            style: const TextStyle(color: Colors.white70, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Verstanden'),
          ),
        ],
      ),
    );
  }

  Color _latencyColor(double ms) {
    if (ms < 300) return Colors.green;
    if (ms < 800) return Colors.orange;
    return Colors.red;
  }

  Color _statusColor(HealthStatus s) {
    switch (s) {
      case HealthStatus.healthy:
        return Colors.green;
      case HealthStatus.degraded:
        return Colors.orange;
      case HealthStatus.unhealthy:
        return Colors.red;
      case HealthStatus.unknown:
        return Colors.grey;
    }
  }

  double _calcUptime() {
    final svcs = _health.serviceHealth;
    if (svcs.isEmpty) return 100;
    final healthy =
        svcs.values.where((s) => s.status == HealthStatus.healthy).length;
    return (healthy / svcs.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Center(child: CircularProgressIndicator(color: widget.accent));
    }

    final svcs = _health.serviceHealth;
    final anyUnhealthy =
        svcs.values.any((s) => s.status == HealthStatus.unhealthy);
    final allOk = svcs.values.every((s) => s.status == HealthStatus.healthy);

    final overallColor = anyUnhealthy
        ? Colors.red
        : allOk
            ? Colors.green
            : Colors.orange;
    final overallLabel = anyUnhealthy
        ? 'Probleme erkannt'
        : allOk
            ? 'Alle Systeme OK'
            : 'Eingeschränkt';
    final overallIcon = anyUnhealthy
        ? Icons.error_rounded
        : allOk
            ? Icons.check_circle_rounded
            : Icons.warning_amber_rounded;

    final uptime = _calcUptime();
    final errRate = _health.errorRate;
    final avgLatency = _health.averageLatency;

    return RefreshIndicator(
      onRefresh: _checkAll,
      color: widget.accent,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionLabel(
              'System-Status', Icons.monitor_heart_rounded, widget.accent),
          const SizedBox(height: 12),

          // ── Gesamt-Status ─────────────────────────────────────────
          GestureDetector(
            onTap: _checkAll,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: overallColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: overallColor.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: overallColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(overallIcon, color: overallColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(overallLabel,
                            style: TextStyle(
                                color: overallColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text(
                            '${svcs.length} Dienste überwacht · Tippen zum Prüfen',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                      ]),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: overallColor.withValues(alpha: 0.6), size: 14),
              ]),
            ),
          ),

          const SizedBox(height: 20),

          // ── Metriken ──────────────────────────────────────────────
          _SectionLabel('Metriken', Icons.speed_rounded, widget.accent),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: _ClickableMetricCard(
                    label: 'Ø Latenz',
                    value: '${avgLatency.round()} ms',
                    icon: Icons.timer_rounded,
                    color: _latencyColor(avgLatency),
                    onTap: () => _explainMetric(
                        'Ø Latenz',
                        'Durchschnittliche Antwortzeit aller ueberwachten '
                            'Dienste. Unter 300 ms = sehr gut, ueber 800 ms '
                            '= langsam.'))),
            const SizedBox(width: 10),
            Expanded(
                child: _ClickableMetricCard(
                    label: 'Fehlerrate',
                    value: '${errRate.toStringAsFixed(1)} %',
                    icon: Icons.error_outline_rounded,
                    color: errRate > 10 ? Colors.red : Colors.green,
                    onTap: () => _explainMetric(
                        'Fehlerrate',
                        'Anteil der Dienste die aktuell nicht erreichbar '
                            'sind. 0 % = alle gesund.'))),
            const SizedBox(width: 10),
            Expanded(
                child: _ClickableMetricCard(
                    label: 'Uptime',
                    value: '${uptime.toStringAsFixed(0)} %',
                    icon: Icons.power_rounded,
                    color: uptime > 95 ? Colors.green : Colors.orange,
                    onTap: () => _explainMetric(
                        'Uptime',
                        'Anteil der erfolgreichen Health-Checks seit App-'
                            'Start. Ueber 95 % = stabil.'))),
          ]),

          const SizedBox(height: 20),

          // ── Einzelne Dienste ──────────────────────────────────────
          _SectionLabel('Dienste', Icons.dns_rounded, widget.accent),
          const SizedBox(height: 10),

          if (svcs.isEmpty)
            _EmptyHint('Keine Dienste überwacht.\nTippe auf „Jetzt prüfen".')
          else
            ...svcs.entries.map((e) => _ClickableServiceRow(
                  name: e.key,
                  health: e.value,
                  statusColor: _statusColor(e.value.status),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A2E),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        title: Text(e.key,
                            style: TextStyle(
                                color: widget.accentBright,
                                fontWeight: FontWeight.bold)),
                        content:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          _InfoRow2(Icons.speed_rounded,
                              'Latenz: ${e.value.latencyMs} ms'),
                          const SizedBox(height: 6),
                          _InfoRow2(
                              Icons.circle, 'Status: ${e.value.statusText}'),
                        ]),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('OK',
                                style: TextStyle(color: widget.accent)),
                          ),
                        ],
                      ),
                    );
                  },
                )),

          const SizedBox(height: 20),

          // ── Check-Button ──────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _checking ? null : _checkAll,
              icon: _checking
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text(_checking ? 'Prüfe…' : 'Jetzt prüfen',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── App-Update-Konfiguration (nur root_admin) ─────────────
          if (widget.admin.isRootAdmin) ...[
            _SectionLabel('App-Update-Konfiguration',
                Icons.system_update_rounded, widget.accent),
            const SizedBox(height: 10),
            if (_appConfigLoading)
              const Center(child: CircularProgressIndicator())
            else if (_appConfigRows == null)
              _EmptyHint(
                  'Fehler beim Laden. Zum Aktualisieren nach unten ziehen.')
            else if (_appConfigRows!.isEmpty)
              _EmptyHint(
                  'Keine app_config-Eintraege gefunden.\nTabelle evtl. leer.')
            else
              ..._appConfigRows!.map((row) {
                final platform = row['platform'] as String? ?? '?';
                final latest = row['latest_version'] as String? ?? '-';
                final minV = row['min_version'] as String? ?? '-';
                final url =
                    (row['apk_download_url'] as String? ?? '').isNotEmpty;
                return GestureDetector(
                  onTap: () => _editAppConfig(row),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: widget.accent.withValues(alpha: 0.25)),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          platform == 'android'
                              ? Icons.android_rounded
                              : Icons.apple_rounded,
                          color: widget.accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              platform.toUpperCase(),
                              style: TextStyle(
                                  color: widget.accentBright,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Aktuell: $latest  |  Min: $minV  |  APK: ${url ? "gesetzt" : "fehlt"}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.edit_rounded, color: Colors.white38, size: 16),
                    ]),
                  ),
                );
              }),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// GEMEINSAME WIDGETS
// ═════════════════════════════════════════════════════════════════════════════
