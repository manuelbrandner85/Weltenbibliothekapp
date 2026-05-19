import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/biometric_service.dart';

/// Smart diagnostic bottom sheet that explains *why* Health-Reading is not
/// working and offers an actionable fix for each cause.
///
/// Use [HealthDiagnosisDialog.showAndResolve] from any screen that depends on
/// biometric data — it auto-runs `service.diagnose()`, shows this sheet and
/// returns `true` once the user has either resolved the issue (data is
/// flowing) or `false` when they explicitly chose to continue without
/// biometrics.
class HealthDiagnosisDialog extends StatefulWidget {
  /// The diagnosis snapshot produced by [BiometricService.diagnose].
  final HealthDiagnosis diagnosis;

  /// Optional injection of the active service — required when the dialog
  /// should be able to launch the install / settings deeplinks and run a
  /// live test measurement.
  final BiometricService? service;

  /// Called after the user has taken an action and the dialog should
  /// re-trigger a diagnosis pass.
  final VoidCallback? onRetry;

  /// Called when the user picks the secondary "Trotzdem starten" option.
  final VoidCallback? onContinueWithout;

  /// Called when the user explicitly wants to jump to Health-Connect
  /// settings (deeplink).
  final VoidCallback? onOpenSettings;

  const HealthDiagnosisDialog({
    super.key,
    required this.diagnosis,
    this.service,
    this.onRetry,
    this.onContinueWithout,
    this.onOpenSettings,
  });

  /// Convenience helper: runs `service.diagnose()`, shows the sheet and
  /// returns:
  ///  - `true`  → user successfully resolved the issue (e.g. permission
  ///              granted and HR samples flowing)
  ///  - `false` → user dismissed / chose to continue without biometrics
  static Future<bool> showAndResolve(
    BuildContext context,
    BiometricService service,
  ) async {
    HealthDiagnosis current = await service.diagnose();
    // The sheet can be re-entered after the user fixed something.
    while (true) {
      if (!context.mounted) return current.isReady;

      final result = await showModalBottomSheet<_SheetResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.65),
        builder: (ctx) => HealthDiagnosisDialog(
          diagnosis: current,
          service: service,
        ),
      );

      switch (result) {
        case null:
        case _SheetResult.dismissed:
          return current.isReady;
        case _SheetResult.continueWithout:
          return false;
        case _SheetResult.resolved:
          return true;
        case _SheetResult.retry:
          current = await service.diagnose();
          continue;
      }
    }
  }

  @override
  State<HealthDiagnosisDialog> createState() => _HealthDiagnosisDialogState();
}

enum _SheetResult { dismissed, continueWithout, resolved, retry }

class _HealthDiagnosisDialogState extends State<HealthDiagnosisDialog>
    with SingleTickerProviderStateMixin {
  static const Color _accent = Color(0xFF26A69A);
  static const Color _accentSoft = Color(0xFF80CBC4);
  static const Color _glass = Color(0x33FFFFFF);
  static const Color _stroke = Color(0x55FFFFFF);

  late final AnimationController _intro;
  late final Animation<double> _introT;

  bool _busy = false;
  bool _testing = false;
  double? _liveHr;
  String? _liveError;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    )..forward();
    _introT = CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  // ─── Action handlers ──────────────────────────────────────────

  Future<void> _runPrimary() async {
    final svc = widget.service;
    final action = widget.diagnosis.recommendedAction;
    HapticFeedback.lightImpact();

    switch (action) {
      case HealthFixAction.installHealthConnect:
        setState(() => _busy = true);
        await svc?.openInstallHealthConnect();
        if (!mounted) return;
        setState(() => _busy = false);
        Navigator.of(context).pop(_SheetResult.retry);
        return;
      case HealthFixAction.grantPermission:
        setState(() => _busy = true);
        await svc?.requestPermissions();
        if (!mounted) return;
        setState(() => _busy = false);
        Navigator.of(context).pop(_SheetResult.retry);
        return;
      case HealthFixAction.openHealthConnectSettings:
      case HealthFixAction.connectDataSource:
        setState(() => _busy = true);
        widget.onOpenSettings?.call();
        await svc?.openHealthConnectSettings();
        if (!mounted) return;
        setState(() => _busy = false);
        Navigator.of(context).pop(_SheetResult.retry);
        return;
      case HealthFixAction.iosBuildMissing:
      case HealthFixAction.webNotSupported:
        Navigator.of(context).pop(_SheetResult.dismissed);
        return;
      case HealthFixAction.allOk:
        await _testMeasurement();
        return;
    }
  }

  Future<void> _testMeasurement() async {
    final svc = widget.service;
    if (svc == null) return;
    setState(() {
      _testing = true;
      _liveError = null;
      _liveHr = null;
    });
    try {
      final hr = await svc.getRestingHeartRate(
        since: const Duration(hours: 24),
      );
      if (!mounted) return;
      setState(() {
        _testing = false;
        if (hr == null) {
          _liveError =
              'Keine HR-Probe verfügbar. Bitte Smartwatch tragen und es erneut versuchen.';
        } else {
          _liveHr = hr;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testing = false;
        _liveError = 'Test-Messung fehlgeschlagen: $e';
      });
    }
  }

  void _runSecondary() {
    HapticFeedback.selectionClick();
    widget.onContinueWithout?.call();
    Navigator.of(context).pop(_SheetResult.continueWithout);
  }

  // ─── UI ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final action = widget.diagnosis.recommendedAction;

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: AnimatedBuilder(
        animation: _introT,
        builder: (context, child) => Opacity(
          opacity: _introT.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _introT.value) * 24),
            child: child,
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _glass.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
                border: Border(
                  top: BorderSide(color: _stroke, width: 1),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                12,
                24,
                24 + media.padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _grabber(),
                  const SizedBox(height: 12),
                  _icon(action),
                  const SizedBox(height: 18),
                  _title(action),
                  const SizedBox(height: 12),
                  _body(action),
                  if (action == HealthFixAction.allOk) ...[
                    const SizedBox(height: 18),
                    _testResultCard(),
                  ],
                  const SizedBox(height: 28),
                  _buttons(action),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _grabber() => Container(
        width: 44,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(4),
        ),
      );

  Widget _icon(HealthFixAction action) {
    final glyph = _glyphFor(action);
    final color =
        action == HealthFixAction.allOk ? const Color(0xFF66BB6A) : _accentSoft;
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 28,
            spreadRadius: 4,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        glyph,
        style: const TextStyle(fontSize: 44),
      ),
    );
  }

  Widget _title(HealthFixAction action) {
    return Text(
      _titleFor(action),
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.w900,
        height: 1.05,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _body(HealthFixAction action) {
    final sources = widget.diagnosis.detectedDataSources;
    final lines = <Widget>[];

    lines.add(
      Text(
        widget.diagnosis.summary,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 15,
          height: 1.4,
        ),
      ),
    );

    final extra = _detailFor(action);
    if (extra != null) {
      lines.add(const SizedBox(height: 10));
      lines.add(
        Text(
          extra,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 13,
            height: 1.45,
          ),
        ),
      );
    }

    if (action == HealthFixAction.connectDataSource) {
      lines.add(const SizedBox(height: 14));
      lines.add(_dataSourceList());
    }

    if (action == HealthFixAction.allOk && sources.isNotEmpty) {
      lines.add(const SizedBox(height: 14));
      lines.add(_sourceChips(sources));
    }

    return Column(mainAxisSize: MainAxisSize.min, children: lines);
  }

  Widget _dataSourceList() {
    const items = [
      'Galaxy Wear',
      'Samsung Health',
      'Google Fit',
      'Fitbit',
      'Garmin Connect',
      'Polar Flow',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _stroke, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Du brauchst eine Quelle wie:',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final i in items) _pill(i),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sourceChips(List<String> sources) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final s in sources) _pill(s, highlight: true),
      ],
    );
  }

  Widget _pill(String text, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? _accent.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlight
              ? _accent.withValues(alpha: 0.55)
              : Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: highlight ? Colors.white : Colors.white.withValues(alpha: 0.8),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _testResultCard() {
    if (_testing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(_accent),
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Messe Herzfrequenz...',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      );
    }
    if (_liveError != null) {
      return Text(
        _liveError!,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFFF8A80),
          fontSize: 13,
          height: 1.4,
        ),
      );
    }
    if (_liveHr != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _accent.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, color: Color(0xFFFF6B6B), size: 32),
            const SizedBox(width: 14),
            Text(
              _liveHr!.toStringAsFixed(0),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'BPM',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buttons(HealthFixAction action) {
    final primaryLabel = _primaryLabelFor(action);
    final secondaryLabel = _secondaryLabelFor(action);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _busy ? null : _runPrimary,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(primaryLabel.toUpperCase()),
          ),
        ),
        if (secondaryLabel != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: _busy ? null : _runSecondary,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.7),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
              child: Text(secondaryLabel),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Copy ──────────────────────────────────────────────────────

  String _glyphFor(HealthFixAction a) {
    switch (a) {
      case HealthFixAction.allOk:
        return '✓'; // check mark
      case HealthFixAction.installHealthConnect:
        return '\u{1F4E5}'; // inbox tray
      case HealthFixAction.grantPermission:
        return '\u{1F512}'; // lock
      case HealthFixAction.openHealthConnectSettings:
        return '⚙️'; // gear
      case HealthFixAction.connectDataSource:
        return '⌚'; // watch
      case HealthFixAction.iosBuildMissing:
        return '\u{1F34E}'; // apple
      case HealthFixAction.webNotSupported:
        return '\u{1F310}'; // globe
    }
  }

  String _titleFor(HealthFixAction a) {
    switch (a) {
      case HealthFixAction.allOk:
        return 'Health bereit';
      case HealthFixAction.installHealthConnect:
        return 'Health Connect fehlt';
      case HealthFixAction.grantPermission:
        return 'Berechtigung erforderlich';
      case HealthFixAction.openHealthConnectSettings:
        return 'Berechtigung verweigert';
      case HealthFixAction.connectDataSource:
        return 'Keine Datenquelle gefunden';
      case HealthFixAction.iosBuildMissing:
        return 'iOS-Build erforderlich';
      case HealthFixAction.webNotSupported:
        return 'Nicht auf Web';
    }
  }

  String? _detailFor(HealthFixAction a) {
    switch (a) {
      case HealthFixAction.allOk:
        final ts = widget.diagnosis.latestSampleAt;
        if (ts == null) return null;
        return 'Letzte Probe: ${_formatRelative(ts)}.';
      case HealthFixAction.installHealthConnect:
        return 'Health Connect ist Googles zentrale Schnittstelle für Gesundheitsdaten. Du brauchst sie damit deine Smartwatch HRV/HR an die Weltenbibliothek liefern kann.';
      case HealthFixAction.grantPermission:
        return 'Wir lesen ausschließlich Herzfrequenz und HRV — und nur lokal auf deinem Gerät, um den Wirkungs-Score deiner Meditation zu berechnen.';
      case HealthFixAction.openHealthConnectSettings:
        return 'Du kannst die Berechtigung jederzeit in den Health-Connect-Einstellungen neu erteilen.';
      case HealthFixAction.connectDataSource:
        return 'Health Connect ist installiert und die Berechtigung erteilt — aber es liegen noch keine Herzfrequenz-Daten vor. Bitte verbinde eine Smartwatch oder eine Fitness-App mit Health Connect.';
      case HealthFixAction.iosBuildMissing:
        return 'Apple HealthKit funktioniert nur in der iOS-Variante der Weltenbibliothek. Die ist bald verfügbar.';
      case HealthFixAction.webNotSupported:
        return 'Im Browser gibt es kein HealthKit oder Health Connect. Bitte nutze die Android- oder iOS-App.';
    }
  }

  String _primaryLabelFor(HealthFixAction a) {
    switch (a) {
      case HealthFixAction.allOk:
        return 'Test-Messung';
      case HealthFixAction.installHealthConnect:
        return 'Installieren';
      case HealthFixAction.grantPermission:
        return 'Erlauben';
      case HealthFixAction.openHealthConnectSettings:
        return 'Einstellungen öffnen';
      case HealthFixAction.connectDataSource:
        return 'Gerät verbinden';
      case HealthFixAction.iosBuildMissing:
        return 'OK verstanden';
      case HealthFixAction.webNotSupported:
        return 'OK';
    }
  }

  String? _secondaryLabelFor(HealthFixAction a) {
    switch (a) {
      case HealthFixAction.allOk:
        return 'Schließen';
      case HealthFixAction.installHealthConnect:
        return 'Später';
      case HealthFixAction.grantPermission:
      case HealthFixAction.openHealthConnectSettings:
      case HealthFixAction.connectDataSource:
        return 'Trotzdem starten';
      case HealthFixAction.iosBuildMissing:
      case HealthFixAction.webNotSupported:
        return null;
    }
  }

  String _formatRelative(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return 'gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'vor ${diff.inHours} h';
    if (diff.inDays < 7) return 'vor ${diff.inDays} Tagen';
    return ts.toLocal().toString().substring(0, 16);
  }
}
