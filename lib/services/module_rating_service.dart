import 'package:shared_preferences/shared_preferences.dart';

/// V-X5: Lokale Modul-Bewertung (1-5 Sterne) pro Modul.
///
/// Bewusst on-device (SharedPreferences) gehalten -- keine Server-Tabelle,
/// damit das kritische RLS/Auth-TODO nicht beruehrt wird. Spiegelt die
/// persoenliche Einschaetzung des Nutzers, kein geteilter Durchschnitt.
class ModuleRatingService {
  ModuleRatingService._();
  static final ModuleRatingService instance = ModuleRatingService._();

  static const _prefix = 'module_rating_';

  /// Liefert die gespeicherte Bewertung (1-5) oder null.
  Future<int?> getRating(String moduleCode) async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt('$_prefix$moduleCode');
    if (v == null || v < 1 || v > 5) return null;
    return v;
  }

  /// Speichert die Bewertung (1-5). Werte ausserhalb werden ignoriert.
  Future<void> setRating(String moduleCode, int stars) async {
    if (stars < 1 || stars > 5) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefix$moduleCode', stars);
  }
}
