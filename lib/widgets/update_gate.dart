// 🟢 UPDATE GATE – Wrapper der beim App-Start + bei App-Resume prüft,
// ob ein Release-Update oder OTA-Patch verfügbar ist.
//
// Verwendung in main.dart:
//   home: const UpdateGate(child: PortalHomeScreen()),

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/update_service.dart';
import 'update_dialogs.dart';

class UpdateGate extends StatefulWidget {
  final Widget child;
  const UpdateGate({super.key, required this.child});

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> with WidgetsBindingObserver {
  bool _releaseDialogShown = false;
  bool _patchBannerShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runChecks());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runChecks();
    }
  }

  Future<void> _runChecks() async {
    if (!mounted) return;

    // 1) Release-Update? (Supabase app_config vs. APP_VERSION)
    if (!_releaseDialogShown) {
      final result = await UpdateService.instance.checkReleaseUpdate();
      if (!mounted) return;
      if (result.releaseUpdateAvailable) {
        _releaseDialogShown = true;
        await ReleaseUpdateDialog.show(context, result);
      }
    }

    // 2) OTA-Patch bereits heruntergeladen?
    if (!_patchBannerShown && mounted) {
      final ready = await UpdateService.instance.isPatchReady();
      if (!mounted) return;
      if (ready) {
        _patchBannerShown = true;
        PatchReadyBanner.show(context);
      }
    }

    // 3) Im Hintergrund: nach neuem Patch auf Shorebird-Server suchen
    //    (idR. macht das die Engine selbst, hier nur als sanfter Trigger)
    unawaited(UpdateService.instance.checkAndDownloadPatch());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

void unawaited(Future<void> future) {
  // Intentional fire-and-forget
  future.catchError((Object e) {
    if (kDebugMode) {
      debugPrint('⚠️  [UpdateGate] background task error: $e');
    }
  });
}
