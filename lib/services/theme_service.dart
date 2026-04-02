import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme-Service für Dark/Light Mode Toggle
class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _keyThemeMode = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.dark; // Default: Dark
  
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  
  /// Initialisierung
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_keyThemeMode);
    
    if (savedMode == 'light') {
      _themeMode = ThemeMode.light;
    } else if (savedMode == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    
    notifyListeners();
  }
  
  /// Theme wechseln
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
    
    await _saveThemeMode();
    notifyListeners();
  }
  
  /// Spezifisches Theme setzen
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _saveThemeMode();
    notifyListeners();
  }
  
  /// Theme Mode speichern
  Future<void> _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    String modeString;
    
    switch (_themeMode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
    }
    
    await prefs.setString(_keyThemeMode, modeString);
  }
}

/// App-weite Theme-Daten
class AppThemes {
  // Dark Theme (Original)
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0A0A0A),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF2196F3), // Materie Blau
      secondary: Color(0xFF9C27B0), // Energie Lila
      surface: Color(0xFF1E1E1E),
      error: Color(0xFFCF6679),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0A0A0A),
      elevation: 0,
      centerTitle: true,
    ),
  );
  
  // Light Theme (Neu)
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1976D2), // Materie Blau (dunkler)
      secondary: Color(0xFF7B1FA2), // Energie Lila (dunkler)
      surface: Colors.white,
      error: Color(0xFFB00020),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 1,
      centerTitle: true,
      foregroundColor: Color(0xFF212121),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF212121)),
      bodyMedium: TextStyle(color: Color(0xFF424242)),
      titleLarge: TextStyle(color: Color(0xFF212121)),
    ),
  );
  
  // Gradient-Farben je nach Theme
  static List<Color> getMaterieGradient(bool isDark) {
    if (isDark) {
      return [
        const Color(0xFF0D47A1).withValues(alpha: 0.3),
        Colors.black,
      ];
    } else {
      return [
        const Color(0xFF2196F3).withValues(alpha: 0.2),
        const Color(0xFFE3F2FD),
      ];
    }
  }
  
  static List<Color> getEnergieGradient(bool isDark) {
    if (isDark) {
      return [
        const Color(0xFF4A148C).withValues(alpha: 0.3),
        Colors.black,
      ];
    } else {
      return [
        const Color(0xFF9C27B0).withValues(alpha: 0.2),
        const Color(0xFFF3E5F5),
      ];
    }
  }
}
