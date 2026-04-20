import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../screens/release_update_screen.dart';
import '../services/update_service.dart';
import 'ota_debug_banner.dart';
import 'update_dialogs.dart';

class UpdateGate extends StatefulWidget {
  final Widget child;
  const UpdateGate({super.key, required this.child});

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> with WidgetsBindingObserver {
  bool _releaseGateOpen = false;
  bool _patchBannerShown = false;
  Timer? _periodicTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runChecks());

    // Alle 3 Minuten prüfen ob ein Patch inzwischen heruntergeladen wurde.
    _periodicTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      if (mounted && !_patchBannerShown) _checkPatchReady();
    });
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
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
    if (!mounted || _patchBannerShown) return;
    final ready = await UpdateService.instance.isPatchReady();
    if (mounted && ready && !_patchBannerShown) {
      _patchBannerShown = true;
      PatchReadyBanner.show(context);
    }
  }

  Future<void> _runChecks() async {
    if (!mounted) return;

    // 1) Release-Update? (Supabase app_config vs. APP_VERSION)
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
    if (_patchBannerShown) return;

    // 3) Patch herunterladen — danach sofort Banner zeigen wenn bereit.
    //    Kein Fire-and-forget mehr: wir warten auf den Download und prüfen dann nochmal.
    UpdateService.instance.checkAndDownloadPatch().then((_) {
      if (mounted && !_patchBannerShown) _checkPatchReady();
    }).catchError((Object e) {
      if (kDebugMode) debugPrint('⚠️ [UpdateGate] patch download error: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        const OtaDebugBanner(),
      ],
    );
  }
}
