// Zentrale Health-Verwaltungs-Seite mit Watch-Anbindungs-Wizard.
// Erreichbar aus Profil-Settings und automatisch wenn die Health-Diagnose
// in Gateway/Breathmaster-Screen einen Fehler meldet.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/ble_heart_rate_service.dart';
import '../../services/biometric_service.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_ambient_particles.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';

// ---------------------------------------------------------------------------
// v5.44.1: lokale Fallback-Typen entfernt - nutzen jetzt die echten
// HealthDiagnosis / HealthFixAction / HealthPermissionStatus aus
// BiometricService.
// ---------------------------------------------------------------------------

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

  HealthDiagnosis? _diagnosis;
  bool _loading = true;
  bool _measuring = false;
  double? _liveBpm;
  List<Map<String, dynamic>> _recentReadings = const [];

  // BLE Direct-Connection state
  final BleHeartRateService _ble = BleHeartRateService.instance;
  BleStatus? _bleStatus;
  bool _bleScanning = false;
  int _bleScanRemainingSec = 0;
  Timer? _bleScanTimer;
  final List<BleHrDevice> _bleDiscovered = <BleHrDevice>[];
  StreamSubscription<BleHrDevice>? _bleScanSub;
  StreamSubscription<int>? _bleHrSub;
  int? _bleLiveBpm;
  final List<int> _bleHrHistory = <int>[]; // last 10 readings (sparkline)
  String? _bleConnectingId;

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
    _initBle();
  }

  @override
  void dispose() {
    _bleScanTimer?.cancel();
    _bleScanSub?.cancel();
    _bleHrSub?.cancel();
    _pulseController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  // -------------------- BLE Direct --------------------

  Future<void> _initBle() async {
    final status = await _ble.getStatus();
    if (!mounted) return;
    setState(() => _bleStatus = status);
    // Subscribe to live HR if already connected (e.g. auto-reconnect happened
    // earlier in app lifecycle).
    if (_ble.isConnected) {
      _subscribeBleHr();
    }
  }

  void _subscribeBleHr() {
    _bleHrSub?.cancel();
    _bleHrSub = _ble.heartRateStream.listen((bpm) {
      if (!mounted) return;
      setState(() {
        _bleLiveBpm = bpm;
        _bleHrHistory.add(bpm);
        if (_bleHrHistory.length > 10) {
          _bleHrHistory.removeAt(0);
        }
      });
    });
    _bleLiveBpm = _ble.lastBpm;
  }

  Future<void> _refreshBleStatus() async {
    final status = await _ble.getStatus();
    if (!mounted) return;
    setState(() => _bleStatus = status);
  }

  Future<void> _startBleScan() async {
    if (_bleScanning) return;
    HapticFeedback.selectionClick();
    setState(() {
      _bleScanning = true;
      _bleDiscovered.clear();
      _bleScanRemainingSec = 10;
    });

    _bleScanTimer?.cancel();
    _bleScanTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _bleScanRemainingSec =
            _bleScanRemainingSec > 0 ? _bleScanRemainingSec - 1 : 0;
      });
      if (_bleScanRemainingSec <= 0) t.cancel();
    });

    try {
      await _bleScanSub?.cancel();
      _bleScanSub = _ble.scan(timeout: const Duration(seconds: 10)).listen(
        (dev) {
          if (!mounted) return;
          setState(() {
            // Replace if same id already in list (RSSI update).
            final idx = _bleDiscovered
                .indexWhere((e) => e.device.remoteId == dev.device.remoteId);
            if (idx >= 0) {
              _bleDiscovered[idx] = dev;
            } else {
              _bleDiscovered.add(dev);
            }
          });
        },
        onDone: () {
          if (!mounted) return;
          setState(() => _bleScanning = false);
          _bleScanTimer?.cancel();
        },
        onError: (Object e) {
          if (!mounted) return;
          setState(() => _bleScanning = false);
          _bleScanTimer?.cancel();
          _showSnack('BLE-Scan fehlgeschlagen: $e', isError: true);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _bleScanning = false);
      _bleScanTimer?.cancel();
      _showSnack('BLE-Scan fehlgeschlagen: $e', isError: true);
    }
  }

  Future<void> _connectBleDevice(BleHrDevice dev) async {
    if (_bleConnectingId != null) return;
    HapticFeedback.selectionClick();
    setState(() => _bleConnectingId = dev.device.remoteId.str);
    final ok = await _ble.connect(dev.device);
    if (!mounted) return;
    setState(() {
      _bleConnectingId = null;
      if (ok) {
        _bleDiscovered.clear();
        _bleScanning = false;
        _bleHrHistory.clear();
      }
    });
    if (ok) {
      _subscribeBleHr();
      HapticFeedback.mediumImpact();
      _showSnack('Verbunden mit ${_ble.connectedDeviceName ?? dev.name}');
    } else {
      _showSnack('Verbindung fehlgeschlagen', isError: true);
    }
  }

  Future<void> _disconnectBle() async {
    HapticFeedback.selectionClick();
    await _ble.disconnect();
    await _bleHrSub?.cancel();
    if (!mounted) return;
    setState(() {
      _bleLiveBpm = null;
      _bleHrHistory.clear();
    });
    _showSnack('Geraet getrennt');
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

  Future<HealthDiagnosis> _runDiagnosis() => _service.diagnose();

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
      return res
          .whereType<Map>()
          .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
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
        backgroundColor:
            isError ? const Color(0xFFE53935) : const Color(0xFF26A69A),
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
                  _buildBleDirectSection(),
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
    final allOk = diag?.isReady ?? false;
    final hcMissing = diag != null && !diag.isHealthConnectInstalled;
    final granted = diag?.permissionStatus == HealthPermissionStatus.granted;

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
    } else if (!granted) {
      icon = Icons.lock_outline;
      glow = const Color(0xFFFFA726);
      title = 'Berechtigung fehlt';
      subtitle = 'Bitte Heart Rate & HRV freigeben';
    } else if (!diag.hasAnyDataSource) {
      icon = Icons.watch_outlined;
      glow = const Color(0xFFFFA726);
      title = 'Keine Datenquelle';
      subtitle = 'Verbinde unten dein Geraet';
    } else if (allOk) {
      icon = Icons.favorite;
      glow = const Color(0xFF26A69A);
      final src = diag.detectedDataSources.isEmpty
          ? 'Health Connect aktiv'
          : 'Quelle: ${diag.detectedDataSources.first}';
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
        if (diag != null && !diag.isPluginAvailable) ...[
          const SizedBox(height: WBSpace.sm),
          Text(
            diag.summary,
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
    final installed = diag?.isHealthConnectInstalled ?? false;
    final granted = diag?.permissionStatus == HealthPermissionStatus.granted;
    final source = diag?.hasAnyDataSource ?? false;
    final sources = diag?.detectedDataSources ?? const <String>[];

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

  // -------------------- BLE Direct-Verbindung Section --------------------

  Widget _buildBleDirectSection() {
    const accent = Color(0xFF26A69A);
    final status = _bleStatus;
    final supported = status?.supported ?? true;
    final isConnected = _ble.isConnected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '⚡',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 6),
            Text(
              'DIREKT-VERBINDUNG (BLUETOOTH)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: WBSpace.xs),
        const Text(
          'Schneller als Health Connect - aber nur fuer Geraete mit '
          'Standard-BLE Heart Rate Service (Polar, Wahoo, Garmin, '
          'manche Galaxy Watches).',
          style: TextStyle(
            color: Color(0xFFB0BEC5),
            fontSize: 12.5,
            height: 1.35,
          ),
        ),
        const SizedBox(height: WBSpace.md),

        // Status-Indikator
        _bleStatusIndicator(status, supported),
        const SizedBox(height: WBSpace.md),

        // Glass-Card mit dynamischem Inhalt
        ClipRRect(
          borderRadius: BorderRadius.circular(WBRadius.lg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(WBSpace.lg),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(WBRadius.lg),
                border: Border.all(
                  color: isConnected
                      ? accent.withValues(alpha: 0.65)
                      : accent.withValues(alpha: 0.30),
                  width: isConnected ? 1.4 : 1,
                ),
                boxShadow: isConnected
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.25),
                          blurRadius: 24,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: _bleCardBody(accent),
            ),
          ),
        ),

        // Plattform-Hinweise
        const SizedBox(height: WBSpace.sm),
        Text(
          'Hinweis iOS: Apple Watch funktioniert hier nicht (siehe '
          'iOS-Hinweis unten). Polar / Wahoo / Garmin OK.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Tipp Galaxy Watch: funktioniert nur wenn sie NICHT ueber die '
          'Samsung-Wearable-App gepaart ist.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _bleStatusIndicator(BleStatus? status, bool supported) {
    if (!supported) {
      return _bleStatusPill(
        icon: Icons.bluetooth_disabled,
        label: 'BLE auf dieser Plattform nicht unterstuetzt',
        color: const Color(0xFF78909C),
      );
    }
    if (status == null) {
      return _bleStatusPill(
        icon: Icons.bluetooth_searching,
        label: 'BLE-Status wird geprueft...',
        color: const Color(0xFF78909C),
      );
    }
    if (!status.bluetoothOn) {
      return _bleStatusPill(
        icon: Icons.bluetooth_disabled,
        label: 'Bluetooth ist aus',
        color: const Color(0xFFE53935),
        onTap: _refreshBleStatus,
      );
    }
    if (!status.permissionsGranted) {
      return _bleStatusPill(
        icon: Icons.lock_outline,
        label: status.errorReason ?? 'Bluetooth-Berechtigung fehlt',
        color: const Color(0xFFFFA726),
        onTap: _refreshBleStatus,
      );
    }
    return _bleStatusPill(
      icon: Icons.bluetooth_connected,
      label: 'Bluetooth AN, Berechtigungen OK',
      color: const Color(0xFF26A69A),
    );
  }

  Widget _bleStatusPill({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WBRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: WBSpace.md,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(WBRadius.pill),
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bleCardBody(Color accent) {
    final isConnected = _ble.isConnected;
    if (isConnected) return _bleConnectedView(accent);
    if (_bleScanning) return _bleScanningView(accent);
    return _bleIdleView();
  }

  Widget _bleIdleView() {
    final ready = _bleStatus?.isReady ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: ready ? _startBleScan : _refreshBleStatus,
            borderRadius: BorderRadius.circular(WBRadius.md),
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: WBSpace.md,
                horizontal: WBSpace.lg,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(WBRadius.md),
                border: Border.all(
                  color: ready
                      ? Colors.white.withValues(alpha: 0.55)
                      : Colors.white.withValues(alpha: 0.2),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bluetooth_searching,
                    color: ready
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    ready ? 'GERAETE-SCAN STARTEN' : 'NICHT BEREIT',
                    style: TextStyle(
                      color: ready
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!ready) ...[
          const SizedBox(height: WBSpace.sm),
          Text(
            _bleStatus?.errorReason ??
                'Bitte Bluetooth aktivieren und Berechtigungen erteilen.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _bleScanningView(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Color(0xFF26A69A)),
              ),
            ),
            const SizedBox(width: WBSpace.sm),
            Text(
              'Suche... ${_bleScanRemainingSec}s verbleibend',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: WBSpace.md),
        if (_bleDiscovered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: WBSpace.md),
            child: Text(
              'Noch keine Geraete gefunden. Stelle sicher, dass deine '
              'Watch / dein Brustgurt aktiv ist.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
          )
        else
          for (final d in _bleDiscovered) _bleDeviceRow(d, accent),
      ],
    );
  }

  Widget _bleDeviceRow(BleHrDevice dev, Color accent) {
    final isConnecting = _bleConnectingId == dev.device.remoteId.str;
    return Padding(
      padding: const EdgeInsets.only(bottom: WBSpace.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: WBSpace.md,
          vertical: WBSpace.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(WBRadius.md),
          border: Border.all(
            color: accent.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            _signalBars(dev.signalBars, accent),
            const SizedBox(width: WBSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dev.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Signal: ${_signalLabel(dev.signalBars)} (${dev.rssi} dBm)',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: WBSpace.sm),
            TextButton(
              onPressed: isConnecting ? null : () => _connectBleDevice(dev),
              style: TextButton.styleFrom(
                foregroundColor: accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: WBSpace.md,
                  vertical: WBSpace.xs,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(WBRadius.pill),
                  side: BorderSide(
                    color: accent.withValues(alpha: 0.55),
                    width: 1,
                  ),
                ),
              ),
              child: isConnecting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Color(0xFF26A69A)),
                      ),
                    )
                  : const Text(
                      'Verbinden',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.6,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _signalBars(int bars, Color color) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          final active = i < bars;
          return Container(
            width: 4,
            height: 6.0 + (i * 5.0),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: active ? color : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(1.5),
            ),
          );
        }),
      ),
    );
  }

  String _signalLabel(int bars) {
    switch (bars) {
      case 3:
        return 'stark';
      case 2:
        return 'mittel';
      case 1:
        return 'schwach';
      default:
        return 'sehr schwach';
    }
  }

  Widget _bleConnectedView(Color accent) {
    final bpm = _bleLiveBpm ?? _ble.lastBpm;
    final name = _ble.connectedDeviceName ?? 'BLE-Geraet';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle, color: accent, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Verbunden mit "$name"',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: WBSpace.md),
        Row(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final t = _pulseController.value;
                final scale = 0.92 + 0.10 * t;
                return Transform.scale(
                  scale: bpm != null ? scale : 1.0,
                  child: Icon(
                    Icons.favorite,
                    color: const Color(0xFFE53935)
                        .withValues(alpha: 0.65 + 0.30 * t),
                    size: 28,
                  ),
                );
              },
            ),
            const SizedBox(width: WBSpace.sm),
            Text(
              bpm != null ? '$bpm' : '--',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'BPM (live)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: WBSpace.md),
        // Mini-Sparkline der letzten 10 Werte
        SizedBox(
          height: 36,
          child: _bleHrHistory.isEmpty
              ? Center(
                  child: Text(
                    'Warte auf erste Messung...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : CustomPaint(
                  painter: _SparklinePainter(
                    values: List<int>.unmodifiable(_bleHrHistory),
                    color: accent,
                  ),
                  size: Size.infinite,
                ),
        ),
        const SizedBox(height: WBSpace.md),
        // Trennen-Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _disconnectBle,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
              side: BorderSide(
                color: const Color(0xFFE53935).withValues(alpha: 0.6),
                width: 1.2,
              ),
              padding: const EdgeInsets.symmetric(vertical: WBSpace.sm),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(WBRadius.md),
              ),
            ),
            icon: const Icon(Icons.bluetooth_disabled, size: 16),
            label: const Text(
              'Trennen',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ],
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

// ---------------------------------------------------------------------------
// Sparkline painter for the BLE live HR mini-graph (last N readings).
// ---------------------------------------------------------------------------

class _SparklinePainter extends CustomPainter {
  final List<int> values;
  final Color color;
  _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 0 || size.height <= 0) return;

    int minV = values.first;
    int maxV = values.first;
    for (final v in values) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    // Avoid divide-by-zero for flat lines.
    final range = (maxV - minV).abs() < 1 ? 1 : (maxV - minV);

    final dx =
        values.length > 1 ? size.width / (values.length - 1) : size.width;
    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final ratio = (values[i] - minV) / range;
      final y =
          size.height - (ratio * size.height * 0.85) - (size.height * 0.075);
      points.add(Offset(i * dx, y));
    }

    // Glow under-line.
    final glow = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, glow);
    canvas.drawPath(path, line);

    // Last point dot.
    final dot = Paint()..color = color;
    canvas.drawCircle(points.last, 3, dot);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) {
    if (old.values.length != values.length) return true;
    for (int i = 0; i < values.length; i++) {
      if (old.values[i] != values[i]) return true;
    }
    return old.color != color;
  }
}
