/// 🌟 SPIRIT PORTAL HOME SCREEN
/// Zentrale Navigation für alle Spirit-Tools
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../energie/calculators/new_spirit_tool_screens.dart';
import '../energie/frequency_generator_screen.dart';  // 🎵 FREQUENCY GENERATOR
import 'spirit_tools_mega_screen.dart';
import '../achievements_screen.dart';

class SpiritPortalScreen extends StatelessWidget {
  const SpiritPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('🌟 Spirit Portal'),
        backgroundColor: const Color(0xFF4A148C),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AchievementsScreen()),
            ),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          _buildToolCard(context, '🔮', 'Tarot', Colors.purple, null),
          _buildToolCard(context, '🧘', 'Meditation', Colors.deepPurple, const MeditationTimerScreen()),
          _buildToolCard(context, '⭐', 'Astrologie', Colors.indigo, const AstrologyCalculatorScreen()),
          _buildToolCard(context, '💎', 'Kristalle', Colors.cyan, null),
          _buildToolCard(context, '🌙', 'Mondphasen', Colors.blue, const MoonPhaseTrackerScreen()),
          _buildToolCard(context, '🎵', 'Frequenzen', Colors.pink, const FrequencyGeneratorScreen()),
          _buildToolCard(context, '💠', 'Chakra', Colors.orange, null),
          _buildToolCard(context, '📔', 'Traumtagebuch', Colors.deepOrange, const DreamJournalScreen()),
          _buildToolCard(context, '🔮', 'Runen', Colors.indigo, const RuneOracleScreen()),
          _buildToolCard(context, '🌟', 'Affirmationen', Colors.amber, const AffirmationsScreen()),
          _buildToolCard(context, '📈', 'Biorhythmus', Colors.green, const BiorhythmScreen()),
          _buildToolCard(context, '📖', 'I-Ging', Colors.purple, const IChingScreen()),
        ],
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, String icon, String title, Color color, Widget? screen) {
    return GestureDetector(
      onTap: () {
        if (screen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title wird geladen...')),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.1)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// 🎨 THEME PROVIDER & SWITCHER
// ========================================

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }
}

class ThemeSwitcherButton extends StatelessWidget {
  final ThemeProvider themeProvider;

  const ThemeSwitcherButton({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
      onPressed: () {
        themeProvider.toggleTheme();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(themeProvider.isDarkMode ? '🌙 Dark Mode aktiviert' : '☀️ Light Mode aktiviert'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }
}

// ========================================
// 📡 OFFLINE MODE HANDLER
// ========================================

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  bool _isOnline = true;
  final List<Function> _syncQueue = [];

  bool get isOnline => _isOnline;

  Future<void> checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOnline = !connectivityResult.contains(ConnectivityResult.none);
  }

  void addToSyncQueue(Function action) {
    _syncQueue.add(action);
  }

  Future<void> syncAll() async {
    if (!_isOnline || _syncQueue.isEmpty) return;

    for (var action in _syncQueue) {
      try {
        await action();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Sync error: $e');
        }
      }
    }
    _syncQueue.clear();
  }
}

class OfflineIndicator extends StatefulWidget {
  const OfflineIndicator({super.key});

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  final _offlineService = OfflineService();

  @override
  void initState() {
    super.initState();
    _offlineService.checkConnectivity();
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {});
      if (!result.contains(ConnectivityResult.none)) {
        _offlineService.syncAll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_offlineService.isOnline) return const SizedBox.shrink();

    return Container(
      color: Colors.red,
      padding: const EdgeInsets.all(8),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text('Offline-Modus', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

// ========================================
// 🔔 PUSH NOTIFICATION SERVICE
// ========================================

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(settings);
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'weltenbibliothek_channel',
      'Weltenbibliothek Notifications',
      channelDescription: 'Meditation reminders and daily check-ins',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(0, title, body, details, payload: payload);
  }

  Future<void> scheduleDailyReminder(int hour, int minute, String title, String body) async {
    // Implementation would use timezone scheduling
    // Simplified for now
  }
}
