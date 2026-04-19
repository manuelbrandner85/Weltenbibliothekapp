// 🟢 UPDATE GATE – Wrapper der beim App-Start + bei App-Resume prüft,
// ob ein Release-Update oder OTA-Patch verfügbar ist.
//
// Verwendung in main.dart:
//   home: const UpdateGate(child: PortalHomeScreen()),

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../screens/release_update_screen.dart';
import '../services/update_service.dart';
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
    //    Bei Update: Fullscreen-Gate öffnen, das die App komplett sperrt.
    //    User muss neue APK downloaden & installieren (In-App-Download).
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
        // Wenn der User den Screen schließt (zB. App beendet und neu startet
        // ohne Update zu installieren), checken wir beim nächsten Resume
        // erneut.
        _releaseGateOpen = false;
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
