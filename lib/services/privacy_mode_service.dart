// PrivacyModeService — Toggle für OSINT-Calls über Worker-Proxy (D3).
//
// Wenn aktiv, schicken OSINT-Tools ihre HTTP-Calls an den Worker-Proxy
// statt direkt. Worker leitet weiter mit anonymisiertem User-Agent +
// rotierter Referrer-URL. Bessere Privacy (Ziel-Server sieht nur
// Cloudflare-IP) auf Kosten von Latenz.

import 'package:flutter/foundation.dart' show ChangeNotifier, kDebugMode, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyModeService extends ChangeNotifier {
  PrivacyModeService._();
  static final instance = PrivacyModeService._();

  static const _key = 'osint_privacy_mode_enabled';

  bool _enabled = false;
  bool get enabled => _enabled;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_key) ?? false;
      notifyListeners();
    } catch (e) { if (kDebugMode) debugPrint('privacy_mode_service: silent catch -> $e'); }
  }

  Future<void> setEnabled(bool v) async {
    if (_enabled == v) return;
    _enabled = v;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, v);
    } catch (e) { if (kDebugMode) debugPrint('privacy_mode_service: silent catch -> $e'); }
  }

  /// Hilfsfunktion: rewrite-URL über Proxy wenn aktiv.
  /// Tool-Aufrufer: `final url = PrivacyModeService.instance.proxy(originalUrl);`
  Uri proxy(Uri url, {String workerUrl = ''}) {
    if (!_enabled || workerUrl.isEmpty) return url;
    return Uri.parse(
      '$workerUrl/api/osint/proxy?url=${Uri.encodeQueryComponent(url.toString())}',
    );
  }
}
