// Zentrale Health-Verwaltungs-Seite mit Watch-Anbindungs-Wizard.
// Erreichbar aus Profil-Settings und automatisch wenn die Health-Diagnose
// in Gateway/Breathmaster-Screen einen Fehler meldet.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/biometric_service.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_ambient_particles.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';

// ---------------------------------------------------------------------------
// Lokale Fallback-Typen.
// TODO: durch BiometricService.diagnose() / HealthDiagnosis / HealthFixAction
// ersetzen sobald vom parallelen Agent in biometric_service.dart geliefert.
// ---------------------------------------------------------------------------

enum _LocalHealthFixAction {
  none,
  installHealthConnect,
  grantPermissions,
  connectDataSource,
}

class _LocalHealthDiagnosis {
  final bool healthConnectInstalled;
  final bool permissionsGranted;
  final bool hasDataSource;
  final List<String> detectedSources;
  final String? lastError;
  final _LocalHealthFixAction recommendedFix;

  const _LocalHealthDiagnosis({
    required this.healthConnectInstalled,
    required this.permissionsGranted,
    required this.hasDataSource,
    required this.detectedSources,
    required this.recommendedFix,
    this.lastError,
  });

  bool get allOk =>
      healthConnectInstalled && permissionsGranted && hasDataSource;
}

// ---------------------------------------------------------------------------
// Watch-Geraete-Konfiguration
// ---------------------------------------------------------------------------

class _WatchDevice {
  final String id;
  final String label;
  final String emoji;
  final Color color;
  final String installAppId;
  final String installFallbackUrl;
  final List<String> steps;

  const _WatchDevice({
    required this.id,
    required this.label,
    required this.emoji,
    required this.color,
    required this.installAppId,
    required this.installFallbackUrl,
    required this.steps,
  });
}

const List<_WatchDevice> _kDevices = [
  _WatchDevice(
    id: 'galaxy',
    label: 'Galaxy Watch',
    emoji: '\u{1F7E6}',
    color: Color(0xFF1976D2),
    installAppId: 'com.sec.android.app.shealth',
    installFallbackUrl:
        'https://play.google.com/store/apps/details?id=com.sec.android.app.shealth',
    steps: [
      'Samsung Health App installieren.',
      'In Samsung Health -> Einstellungen -> Mit Health Connect verbinden.',
      'Health Connect -> Datenquellen -> Samsung Health autorisieren.',
    ],
  ),
  _WatchDevice(
    id: 'wearos',
    label: 'Wear OS',
    emoji: '⌚',
    color: Color(0xFF4DB6AC),
    installAppId: 'com.google.android.apps.fitness',
    installFallbackUrl:
        'https://play.google.com/store/apps/details?id=com.google.android.apps.fitness',
    steps: [
      'Stelle sicher dass dein Watch mit dem Telefon gekoppelt ist.',
      'Google Fit oder die Hersteller-App installieren.',
      'In den App-Einstellungen Health Connect Sync aktivieren.',
    ],
  ),
  _WatchDevice(
    id: 'fitbit',
    label: 'Fitbit',
    emoji: '\u{1F7E7}',
    color: Color(0xFFFF7043),
    installAppId: 'com.fitbit.FitbitMobile',
    installFallbackUrl:
        'https://play.google.com/store/apps/details?id=com.fitbit.FitbitMobile',
    steps: [
      'Fitbit App installieren und einloggen.',
      'Einstellungen -> Verbundene Konten -> Health Connect.',
      'Berechtigungen fuer Herzfrequenz und HRV erteilen.',
    ],
  ),
  _WatchDevice(
    id: 'garmin',
    label: 'Garmin',
    emoji: '\u{1F535}',
    color: Color(0xFF1565C0),
    installAppId: 'com.garmin.android.apps.connectmobile',
    installFallbackUrl:
        'https://play.google.com/store/apps/details?id=com.garmin.android.apps.connectmobile',
    steps: [
      'Garmin Connect App installieren und einloggen.',
      'Mehr -> Einstellungen -> Health Connect verbinden.',
      'Berechtigungen fuer Herzfrequenz und HRV erteilen.',
    ],
  ),
  _WatchDevice(
    id: 'polar',
    label: 'Polar',
    emoji: '\u{1F534}',
    color: Color(0xFFE53935),
    installAppId: 'fi.polar.polarflow',
    installFallbackUrl:
        'https://play.google.com/store/apps/details?id=fi.polar.polarflow',
    steps: [
      'Polar Flow App installieren und einloggen.',
      'Einstellungen -> Health Connect synchronisieren.',
      'Datentypen Heart Rate und HRV aktivieren.',
    ],
  ),
  _WatchDevice(
    id: 'other',
    label: 'Anderes',
    emoji: '❓',
    color: Color(0xFF78909C),
    installAppId: 'com.google.android.apps.healthdata',
    installFallbackUrl:
        'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata',
    steps: [
      'Stelle sicher dass die App deines Geraetes Daten in Health Connect speichert.',
      'In Health Connect -> Einstellungen -> Apps & Datenquellen pruefen.',
      'Berechtigungen fuer die Weltenbibliothek-App fuer Heart Rate / HRV erteilen.',
    ],
  ),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class HealthSettingsScreen extends StatefulWidget {
  const HealthSettingsScreen({super.key});

  @override
  State<HealthSettingsScreen> createState() => _HealthSettingsScreenState();
}

class _HealthSettingsScreenState extends State<HealthSettingsScreen>
    with TickerProviderStateMixin {
  final BiometricService _service = BiometricService();

  late final AnimationController _pulseController;
  late final AnimationController _entryController;

  _LocalHealthDiagnosis? _diagnosis;
  bool _loading = true;
  bool _measuring = false;
  double? _liveBpm;
  List<Map<String, dynamic>> _recentReadings = const [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _entryController = AnimationController(
      vsync: this,
      duration: WBMotion.reveal,
    )..forward();
    _refresh();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  // -------------------- Diagnostik / Refresh --------------------

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final diag = await _runDiagnosis();
    final recents = await _loadRecentReadings();
    if (!mounted) return;
    setState(() {
      _diagnosis = diag;
      _recentReadings = recents;
      _loading = false;
    });
  }

  Future<_LocalHealthDiagnosis> _runDiagnosis() async {
    // Defensiver Fallback: BiometricService.diagnose() existiert (noch) nicht.
    // Wir nutzen die public API requestPermissions() + getRestingHeartRate()
    // um Heuristiken abzuleiten.
    bool permissionsGranted = false;
    bool hasDataSource = false;
    String? lastError;
    final detected = <String>[];

    try {
      permissionsGranted = await _service.requestPermissions();
    } catch (e) {
      lastError = e.toString();
    }

    if (permissionsGranted) {
      try {
        final v = await _service.getRestingHeartRate(
          since: const Duration(hours: 24),
        );
        if (v != null) {
          hasDataSource = true;
          detected.add('Health Connect (aktive Quelle)');
        }
      } catch (e) {
        lastError = e.toString();
      }
    }

    // Health Connect Installation: kein direkter Check moeglich ohne diagnose().
    // Heuristik: wenn requestPermissions() ohne Exception lief, gehen wir davon
    // aus dass Health Connect erreichbar ist.
    final hcInstalled = lastError == null;

    _LocalHealthFixAction fix;
    if (!hcInstalled) {
      fix = _LocalHealthFixAction.installHealthConnect;
    } else if (!permissionsGranted) {
      fix = _LocalHealthFixAction.grantPermissions;
    } else if (!hasDataSource) {
      fix = _LocalHealthFixAction.connectDataSource;
    } else {
      fix = _LocalHealthFixAction.none;
    }

    return _LocalHealthDiagnosis(
      healthConnectInstalled: hcInstalled,
      permissionsGranted: permissionsGranted,
      hasDataSource: hasDataSource,
      detectedSources: detected,
      recommendedFix: fix,
      lastError: lastError,
    );
  }

  Future<List<Map<String, dynamic>>> _loadRecentReadings() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return const [];
      final res = await client
          .from('biometric_readings')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(5);
      if (res is List) {
        return res
            .whereType<Map>()
            .map<Map<String, dynamic>>(
                (e) => Map<String, dynamic>.from(e as Map))
            .toList(growable: false);
      }
    } catch (e) {
      debugPrint('HealthSettingsScreen._loadRecentReadings failed: $e');
    }
    return const [];
  }

  // -------------------- Live-Messung --------------------

  Future<void> _runLiveMeasurement() async {
    if (_measuring) return;
    setState(() {
      _measuring = true;
      _liveBpm = null;
    });
    HapticFeedback.selectionClick();
    // Mini-Animation
    await Future<void>.delayed(const Duration(seconds: 2));
    double? value;
    try {
      value = await _service.getRestingHeartRate(
        since: const Duration(hours: 24),
      );
    } catch (e) {
      debugPrint('HealthSettingsScreen.liveMeasurement failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _measuring = false;
      _liveBpm = value;
    });
    if (value == null) {
      _showSnack(
        'Keine Daten in den letzten 24h gefunden. Pruefe ob deine Watch synchronisiert ist.',
        isError: true,
      );
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFE53935)
            : const Color(0xFF26A69A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // -------------------- Deeplinks --------------------

  Future<void> _openHealthConnect() async {
    // Versuche zuerst Health Connect via market-Deeplink.
    const marketUri = 'market://details?id=com.google.android.apps.healthdata';
    const fallback =
        'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata';
    final ok = await _tryLaunch(marketUri);
    if (!ok) {
      await _tryLaunch(fallback);
    }
  }

  Future<void> _openPlayStore(String appId, String fallbackUrl) async {
    final ok = await _tryLaunch('market://details?id=$appId');
    if (!ok) {
      await _tryLaunch(fallbackUrl);
    }
  }

  Future<bool> _tryLaunch(String url) async {
    try {
      final uri = Uri.parse(url);
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('HealthSettingsScreen._tryLaunch($url) failed: $e');
      return false;
    }
  }

  // -------------------- Build --------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03020A),
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        titleWidget: ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: [Color(0xFFE5C97A), Color(0xFF26A69A)],
          ).createShader(rect),
          child: const Text(
            'HEALTH',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 2.4,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Hintergrund
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.3),
                  radius: 1.2,
                  colors: [
                    Color(0xFF0F1320),
                    Color(0xFF03020A),
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: WBAmbientParticles()),
          const Positioned.fill(child: WBVignette()),

          // Inhalt
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: const Color(0xFF26A69A),
              backgroundColor: const Color(0xFF1A1A2E),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  WBSpace.lg,
                  WBSpace.lg,
                  WBSpace.lg,
                  WBSpace.huge,
                ),
                children: [
                  _buildStatusHero(),
                  const SizedBox(height: WBSpace.xxl),
                  _buildStatusCards(),
                  const SizedBox(height: WBSpace.xxl),
                  _buildWatchWizard(),
                  const SizedBox(height: WBSpace.xxl),
                  _buildLiveTest(),
                  const SizedBox(height: WBSpace.xxl),
                  _buildRecentReadings(),
                  const SizedBox(height: WBSpace.xxxl),
                  _buildIosHint(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------- Sections --------------------

  Widget _buildStatusHero() {
    final diag = _diagnosis;
    final allOk = diag?.allOk ?? false;
    final hcMissing = diag != null && !diag.healthConnectInstalled;

    IconData icon;
    Color glow;
    String title;
    String subtitle;
    if (_loading || diag == null) {
      icon = Icons.favorite_outline;
      glow = const Color(0xFF78909C);
      title = 'Diagnose laeuft...';
      subtitle = 'Pruefe Health Connect und Datenquellen';
    } else if (hcMissing) {
      icon = Icons.block_outlined;
      glow = const Color(0xFFE53935);
      title = 'Health Connect fehlt';
      subtitle = 'Tippe auf "Health Connect installieren"';
    } else if (!diag.permissionsGranted) {
      icon = Icons.lock_outline;
      glow = const Color(0xFFFFA726);
      title = 'Berechtigung fehlt';
      subtitle = 'Bitte Heart Rate & HRV freigeben';
    } else if (!diag.hasDataSource) {
      icon = Icons.watch_outlined;
      glow = const Color(0xFFFFA726);
      title = 'Keine Datenquelle';
      subtitle = 'Verbinde unten dein Geraet';
    } else if (allOk) {
      icon = Icons.favorite;
      glow = const Color(0xFF26A69A);
      final src = diag.detectedSources.isEmpty
          ? 'Health Connect aktiv'
          : 'Quelle: ${diag.detectedSources.first}';
      title = 'Bereit fuer Biometrie';
      subtitle = src;
    } else {
      icon = Icons.favorite_outline;
      glow = const Color(0xFF78909C);
      title = 'Status unbekannt';
      subtitle = 'Ziehe zum Aktualisieren';
    }

    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            final t = _pulseController.value;
            final scale = allOk ? (0.94 + 0.08 * t) : 1.0;
            final opacity = 0.45 + 0.35 * t;
            return Container(
              width: 140,
              height: 140,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    glow.withValues(alpha: opacity * 0.6),
                    glow.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Transform.scale(
                scale: scale,
                child: Icon(icon, size: 96, color: glow),
              ),
            );
          },
        ),
        const SizedBox(height: WBSpace.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: WBSpace.sm),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (diag?.lastError != null) ...[
          const SizedBox(height: WBSpace.sm),
          Text(
            diag!.lastError!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFE53935).withValues(alpha: 0.8),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusCards() {
    final diag = _diagnosis;
    final installed = diag?.healthConnectInstalled ?? false;
    final granted = diag?.permissionsGranted ?? false;
    final source = diag?.hasDataSource ?? false;
    final sources = diag?.detectedSources ?? const <String>[];

    return Column(
      children: [
        _statusCard(
          emoji: '\u{1F4E5}',
          label: 'Health Connect installiert',
          ok: installed,
          onTap: installed ? null : _openHealthConnect,
          subtitle: installed ? 'Bereit' : 'Tippe zum Installieren',
        ),
        const SizedBox(height: WBSpace.md),
        _statusCard(
          emoji: '\u{1F512}',
          label: 'Berechtigung erteilt',
          ok: granted,
          onTap: granted
              ? null
              : () async {
                  await _service.requestPermissions();
                  await _refresh();
                },
          subtitle: granted ? 'Heart Rate & HRV' : 'Tippe zum Erteilen',
        ),
        const SizedBox(height: WBSpace.md),
        _statusCard(
          emoji: '⌚',
          label: 'Datenquelle verbunden',
          ok: source,
          onTap: source ? null : _openHealthConnect,
          subtitle: source
              ? (sources.isEmpty ? 'Aktiv' : sources.join(', '))
              : 'Watch koppeln und Health Connect autorisieren',
        ),
      ],
    );
  }

  Widget _statusCard({
    required String emoji,
    required String label,
    required bool ok,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final accent = ok ? const Color(0xFF26A69A) : const Color(0xFFE53935);
    return ClipRRect(
      borderRadius: BorderRadius.circular(WBRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.white.withValues(alpha: 0.04),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(WBSpace.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(WBRadius.lg),
                border: Border.all(
                  color: accent.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: WBSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: WBSpace.md),
                  Icon(
                    ok ? Icons.check_circle : Icons.cancel,
                    color: accent,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWatchWizard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GERAET VERBINDEN',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.4,
          ),
        ),
        const SizedBox(height: WBSpace.xs),
        const Text(
          'Welches Geraet trackt deine Herzfrequenz?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: WBSpace.lg),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: WBSpace.md,
          crossAxisSpacing: WBSpace.md,
          childAspectRatio: 0.95,
          children: [
            for (final d in _kDevices) _deviceCard(d),
          ],
        ),
      ],
    );
  }

  Widget _deviceCard(_WatchDevice d) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(WBRadius.md),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withValues(alpha: 0.03),
          child: InkWell(
            onTap: () => _showDeviceSheet(d),
            child: Container(
              padding: const EdgeInsets.all(WBSpace.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(WBRadius.md),
                border: Border.all(
                  color: d.color.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(d.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: WBSpace.xs),
                  Text(
                    d.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeviceSheet(_WatchDevice d) async {
    HapticFeedback.selectionClick();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _DeviceBottomSheet(
        device: d,
        onInstall: () => _openPlayStore(d.installAppId, d.installFallbackUrl),
        onOpenHealthConnect: _openHealthConnect,
      ),
    );
  }

  Widget _buildLiveTest() {
    final hasResult = _liveBpm != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(WBRadius.lg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Material(
              color: const Color(0xFFE53935).withValues(alpha: 0.12),
              child: InkWell(
                onTap: _measuring ? null : _runLiveMeasurement,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: WBSpace.xl,
                    horizontal: WBSpace.lg,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(WBRadius.lg),
                    border: Border.all(
                      color: const Color(0xFFE53935).withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_measuring)
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFFE53935),
                          ),
                        )
                      else
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, _) {
                            return Transform.scale(
                              scale: 0.9 + 0.18 * _pulseController.value,
                              child: const Icon(
                                Icons.favorite,
                                color: Color(0xFFE53935),
                                size: 26,
                              ),
                            );
                          },
                        ),
                      const SizedBox(width: WBSpace.md),
                      const Text(
                        'LIVE-MESSUNG STARTEN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (hasResult) ...[
          const SizedBox(height: WBSpace.lg),
          Container(
            padding: const EdgeInsets.all(WBSpace.xl),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(WBRadius.lg),
              border: Border.all(
                color: const Color(0xFFE53935).withValues(alpha: 0.5),
              ),
              color: Colors.black.withValues(alpha: 0.35),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: 0.9 + 0.2 * _pulseController.value,
                      child: const Icon(
                        Icons.favorite,
                        color: Color(0xFFE53935),
                        size: 56,
                      ),
                    );
                  },
                ),
                const SizedBox(width: WBSpace.lg),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _liveBpm!.toStringAsFixed(0),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    Text(
                      'BPM (Ruheherzfrequenz, 24h)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecentReadings() {
    if (_recentReadings.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LETZTE MESSUNGEN',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.4,
          ),
        ),
        const SizedBox(height: WBSpace.md),
        ..._recentReadings.map(_recentReadingTile),
      ],
    );
  }

  Widget _recentReadingTile(Map<String, dynamic> r) {
    final session = (r['session_type'] ?? r['source'] ?? 'Session').toString();
    final scoreRaw = r['effectiveness_score'] ?? r['score'];
    final score = scoreRaw is num ? scoreRaw.toDouble() : null;
    final createdAt = r['created_at']?.toString();
    DateTime? dt;
    if (createdAt != null) {
      dt = DateTime.tryParse(createdAt);
    }
    final dtStr =
        dt != null ? '${dt.day}.${dt.month}.${dt.year}' : (createdAt ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: WBSpace.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: WBSpace.lg,
        vertical: WBSpace.md,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(WBRadius.md),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.timeline, color: Color(0xFF26A69A), size: 20),
          const SizedBox(width: WBSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  dtStr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (score != null)
            Text(
              score.toStringAsFixed(0),
              style: const TextStyle(
                color: Color(0xFFE5C97A),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIosHint() {
    return Center(
      child: Text(
        'Apple Watch: erfordert iOS-Build der App. '
        'Aktuell ist die App nur fuer Android verfuegbar.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 11,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom-Sheet fuer Geraete-Anleitung
// ---------------------------------------------------------------------------

class _DeviceBottomSheet extends StatelessWidget {
  final _WatchDevice device;
  final Future<void> Function() onInstall;
  final Future<void> Function() onOpenHealthConnect;

  const _DeviceBottomSheet({
    required this.device,
    required this.onInstall,
    required this.onOpenHealthConnect,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0B0A14).withValues(alpha: 0.92),
            border: Border(
              top: BorderSide(
                color: device.color.withValues(alpha: 0.55),
                width: 1.2,
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            WBSpace.xl,
            WBSpace.lg,
            WBSpace.xl,
            WBSpace.xl + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: WBSpace.lg),
              Row(
                children: [
                  Text(device.emoji, style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: WBSpace.md),
                  Expanded(
                    child: Text(
                      device.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: WBSpace.lg),
              for (int i = 0; i < device.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: WBSpace.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(top: 2),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: device.color.withValues(alpha: 0.25),
                          border: Border.all(color: device.color, width: 1),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: device.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: WBSpace.md),
                      Expanded(
                        child: Text(
                          device.steps[i],
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: WBSpace.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await onInstall();
                      },
                      icon: const Icon(Icons.download_outlined),
                      label: Text('${device.label} installieren'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: device.color),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(WBRadius.md),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: WBSpace.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    await onOpenHealthConnect();
                  },
                  icon: const Icon(Icons.health_and_safety_outlined),
                  label: const Text('Health Connect oeffnen'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF26A69A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(WBRadius.md),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
