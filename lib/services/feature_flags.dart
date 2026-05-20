// 🚩 FEATURE FLAGS - SharedPreferences-backed Toggle-System
//
// Zentrales Opt-In/Opt-Out fuer experimentelle Features. Default IMMER aus,
// User kann pro Feature im Profil oder via Deep-Link aktivieren.
//
// Verwendung:
//   if (await FeatureFlags.instance.isEnabled(FeatureFlag.newPinsHeader)) {
//     // render new UI
//   }
//
// Cache: synchroner Lookup via getSync(), wenn vorher initialisiert.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Alle verfuegbaren Feature-Flags. Default-State steht in [_kDefaults].
enum FeatureFlag {
  newPinsHeader, // Phase 2 Live-Chat: PinsPollsHeader statt Legacy-Banner
  newMessageBar, // Phase 2 Live-Chat: MessageBarV2 statt inline TextField
  sharedWeltLiveChat, // Phase 2 Live-Chat: shared WeltLiveChatScreen statt Energie+Materie-Duplikate
}

const Map<FeatureFlag, bool> _kDefaults = <FeatureFlag, bool>{
  FeatureFlag.newPinsHeader: false,
  FeatureFlag.newMessageBar: false,
  FeatureFlag.sharedWeltLiveChat: false,
};

String _keyFor(FeatureFlag f) => 'feature_flag_${f.name}_v1';

class FeatureFlags {
  FeatureFlags._();
  static final FeatureFlags instance = FeatureFlags._();

  SharedPreferences? _prefs;
  final Map<FeatureFlag, bool> _cache = <FeatureFlag, bool>{};

  /// Einmal beim App-Start aufrufen (z.B. in main() vor runApp). Liest alle
  /// Flag-Werte in den Cache - danach kann getSync() ueberall verwendet werden.
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      for (final f in FeatureFlag.values) {
        final v = _prefs!.getBool(_keyFor(f));
        _cache[f] = v ?? _kDefaults[f] ?? false;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[FeatureFlags] init failed: $e');
      // Fail-safe: alle defaults
      for (final f in FeatureFlag.values) {
        _cache[f] = _kDefaults[f] ?? false;
      }
    }
  }

  /// Synchroner Lookup. Wirft Exception wenn init() noch nicht aufgerufen wurde.
  /// Gibt Default-Wert zurueck wenn Flag unbekannt.
  bool getSync(FeatureFlag f) {
    return _cache[f] ?? _kDefaults[f] ?? false;
  }

  /// Async-Variante - fuer Call-Sites die nicht sicher sind ob init() lief.
  Future<bool> isEnabled(FeatureFlag f) async {
    if (_cache.containsKey(f)) return _cache[f]!;
    await init();
    return _cache[f] ?? _kDefaults[f] ?? false;
  }

  /// Toggle ein Flag und persistiere. Benachrichtigt keine Listener -
  /// Caller koennen setState() ihres Widgets nach setEnabled() rufen.
  Future<void> setEnabled(FeatureFlag f, bool value) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setBool(_keyFor(f), value);
      _cache[f] = value;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FeatureFlags] setEnabled $f=$value failed: $e');
      }
    }
  }

  /// Liefert alle Flag-Werte fuer ein Debug/Settings-UI.
  Map<FeatureFlag, bool> snapshot() => Map<FeatureFlag, bool>.from(_cache);
}
