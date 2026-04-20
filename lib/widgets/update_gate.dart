// 🟢 UPDATE GATE – Steuert In-App-Update-Flow
//
// Wird als Wrapper um das Root-Widget der App verwendet (siehe main.dart).
// Prüft bei App-Start und beim Wechsel in den Foreground:
//   1. Release-Update (Supabase app_config) → Fullscreen ReleaseUpdateScreen
//   2. Shorebird-Patch bereits bereit        → PatchReadyDialog
//   3. Trigger neuen Patch-Download → Stream benachrichtigt uns automatisch
//
// Der Patch-Ready-Dialog wird stream-basiert gezeigt: UpdateService feuert
// ein Event sobald ein Patch erfolgreich heruntergeladen wurde — damit
// sehen User den Dialog auch während einer laufenden Session.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../screens/release_update_screen.dart';
import '../services/update_service.dart';
import 'patch_ready_dialog.dart';

class UpdateGate extends StatefulWidget {
  final Widget child;
  const UpdateGate({super.key, required this.child});

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> with WidgetsBindingObserver {
  bool _releaseGateOpen = false;
  bool _patchDialogShown = false;
  Timer? _periodicTimer;
  StreamSubscription<PatchCheckResult>? _patchSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Stream-Listener: sobald ein Patch heruntergeladen ist, zeigt der
    // UpdateService ein Event hier. Der Dialog erscheint dann sofort.
    _patchSub = UpdateService.instance.onPatchReady.listen((result) {
      if (!mounted || _patchDialogShown) return;
      _showPatchDialog(result);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _runChecks());

    // Alle 3 Minuten prüfen ob ein Patch inzwischen heruntergeladen wurde
    // (Fallback falls der Stream aus irgendeinem Grund nichts liefert).
    _periodicTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      if (mounted && !_patchDialogShown) _checkPatchReady();
    });
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    _patchSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runChecks();
    }
  }

  Future<void> _checkPatchReady() async {
    if (!mounted || _patchDialogShown) return;
    final result = await UpdateService.instance.checkPatchReady();
    if (mounted && result.patchReady && !_patchDialogShown) {
      _showPatchDialog(result);
    }
  }

  void _showPatchDialog(PatchCheckResult result) {
    _patchDialogShown = true;
    PatchReadyDialog.show(context, result);
  }

  Future<void> _runChecks() async {
    if (!mounted) return;

    // 1) Release-Update? (Supabase app_config vs. APP_VERSION)
    //    Debug-Builds (APP_VERSION='0.0.0') werden im Service abgefangen.
    if (!_releaseGateOpen) {
      final result = await UpdateService.instance.checkReleaseUpdate();
      if (!mounted) return;
      if (result.releaseUpdateAvailable) {
        _releaseGateOpen = true;
        await Navigator.of(context, rootNavigator: true).push(
          PageRouteBuilder(
            opaque: true,
            fullscreenDialog: true,
            barrierDismissible: false,
            transitionDuration: const Duration(milliseconds: 280),
            pageBuilder: (_, __, ___) => ReleaseUpdateScreen(info: result),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
        _releaseGateOpen = false;
      }
    }

    // 2) Patch bereits heruntergeladen?
    await _checkPatchReady();
    if (_patchDialogShown) return;

    // 3) Patch-Download anstoßen — Stream-Listener kümmert sich um den Dialog.
    UpdateService.instance.checkAndDownloadPatch().catchError((Object e) {
      if (kDebugMode) debugPrint('⚠️ [UpdateGate] patch download error: $e');
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
