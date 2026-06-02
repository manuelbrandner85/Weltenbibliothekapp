import 'package:flutter/material.dart';
// OpenClaw v2.0
import 'package:flutter/foundation.dart';
import '../../services/cloudflare_push_service.dart';
import '../../services/quiet_hours_service.dart'; // 🌙 M1
import '../../services/storage_service.dart';
import '../../core/storage/unified_storage_service.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';
import '../../widgets/daily_tarot_reminder_tile.dart';

/// 🔔 Enhanced Notification Settings Screen
/// Features:
/// - Topic-based subscriptions
/// - Custom notification preferences
/// - Notification history
/// - Push notification testing
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final CloudflarePushService _pushService = CloudflarePushService();
  final UnifiedStorageService _storage = UnifiedStorageService();

  bool _isLoading = true;
  bool _notificationsEnabled = true;
  final Map<String, bool> _topicSubscriptions = {};
  List<Map<String, dynamic>> _notificationHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      // Load notification preferences
      final prefs = await _storage.getNotificationPreferences();
      _notificationsEnabled = prefs['enabled'] ?? true;

      // Load topic subscriptions
      final topics = CloudflarePushService.availableTopics.keys.toList();
      for (final topic in topics) {
        _topicSubscriptions[topic] =
            (prefs['topics'] as List?)?.contains(topic) ?? false;
      }

      // Load notification history
      _notificationHistory = await _pushService.getNotifications();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading notification settings: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    setState(() => _notificationsEnabled = enabled);

    try {
      if (enabled) {
        await _pushService.subscribe();
        _showSnackBar('✅ Benachrichtigungen aktiviert', Colors.green);
      } else {
        await _pushService.unsubscribe();
        _showSnackBar('❌ Benachrichtigungen deaktiviert', Colors.orange);
      }

      // Save preference
      await _storage.saveNotificationPreference('enabled', enabled);
    } catch (e) {
      _showSnackBar('❌ Fehler beim Aktualisieren', Colors.red);
    }
  }

  Future<void> _toggleTopic(String topic, bool subscribed) async {
    setState(() => _topicSubscriptions[topic] = subscribed);

    try {
      if (subscribed) {
        await _pushService.subscribeToTopics([topic]);
        _showSnackBar('✅ Thema abonniert', Colors.green);
      } else {
        // Unsubscribe logic would go here
        _showSnackBar('❌ Thema deabonniert', Colors.orange);
      }

      // Save preference
      final subscribedTopics = _topicSubscriptions.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();
      await _storage.saveNotificationPreferenceString(
          'topics', subscribedTopics.join(','));
    } catch (e) {
      _showSnackBar('❌ Fehler beim Aktualisieren', Colors.red);
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      await _pushService.sendTestNotification();
      _showSnackBar('✅ Test-Benachrichtigung gesendet', Colors.green);
    } catch (e) {
      _showSnackBar('❌ Fehler beim Senden', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF000004),
        appBar: WBGlassAppBar(
          title: 'Benachrichtigungen',
          world: WBWorld.neutral,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000004),
      appBar: WBGlassAppBar(
        title: 'Benachrichtigungen',
        world: WBWorld.neutral,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.white),
            onPressed: _sendTestNotification,
            tooltip: 'Test-Benachrichtigung senden',
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0D0A1A),
                    Color(0xFF050310),
                    Color(0xFF000004)
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: IgnorePointer(child: WBVignette())),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Master toggle
              Card(
                child: SwitchListTile(
                  title: const Text(
                    'Push-Benachrichtigungen',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _notificationsEnabled
                        ? 'Aktiviert - Du erhältst Benachrichtigungen'
                        : 'Deaktiviert - Keine Benachrichtigungen',
                  ),
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                  secondary: Icon(
                    _notificationsEnabled
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    color: _notificationsEnabled ? Colors.green : Colors.grey,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ⭐ E-X3: Taegliche Tarot-Erinnerung
              const DailyTarotReminderTile(),

              const SizedBox(height: 24),

              // Topic subscriptions
              const Text(
                '📚 Themen-Abonnements',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ...CloudflarePushService.availableTopics.entries.map((entry) {
                final topic = entry.key;
                final description = entry.value;
                final isSubscribed = _topicSubscriptions[topic] ?? false;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: SwitchListTile(
                    title: Text(description),
                    subtitle: Text(topic),
                    value: isSubscribed && _notificationsEnabled,
                    onChanged: _notificationsEnabled
                        ? (value) => _toggleTopic(topic, value)
                        : null,
                    secondary: Icon(
                      isSubscribed ? Icons.check_circle : Icons.circle_outlined,
                      color: isSubscribed ? Colors.green : Colors.grey,
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Notification history
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '📜 Benachrichtigungs-Verlauf',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_notificationHistory.length} Einträge',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_notificationHistory.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'Noch keine Benachrichtigungen',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ..._notificationHistory.take(10).map((notification) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        _getNotificationIcon(notification['type']),
                        color: _getNotificationColor(notification['type']),
                      ),
                      title: Text(notification['title'] ?? 'Benachrichtigung'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification['body'] ?? ''),
                          const SizedBox(height: 4),
                          Text(
                            _formatTimestamp(notification['timestamp']),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                }),

              const SizedBox(height: 16),
              // 🌙 M1: Quiet-Hours für stille Stunden
              const _QuietHoursCard(),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'breaking':
        return Icons.bolt;
      case 'research':
        return Icons.science;
      case 'meditation':
        return Icons.self_improvement;
      case 'astral':
        return Icons.nights_stay;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'breaking':
        return Colors.red;
      case 'research':
        return Colors.blue;
      case 'meditation':
        return Colors.purple;
      case 'astral':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unbekannt';

    try {
      final dt = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Gerade eben';
      if (diff.inMinutes < 60) return 'vor ${diff.inMinutes}m';
      if (diff.inHours < 24) return 'vor ${diff.inHours}h';
      if (diff.inDays < 7) return 'vor ${diff.inDays}d';

      return '${dt.day}.${dt.month}.${dt.year}';
    } catch (e) {
      return 'Unbekannt';
    }
  }
}

// 🌙 M1: Quiet-Hours-Karte für Notifications
class _QuietHoursCard extends StatefulWidget {
  const _QuietHoursCard();
  @override
  State<_QuietHoursCard> createState() => _QuietHoursCardState();
}

class _QuietHoursCardState extends State<_QuietHoursCard> {
  QuietHoursPrefs _prefs =
      const QuietHoursPrefs(enabled: false, startHour: 22, endHour: 7);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await QuietHoursService.instance.load();
    if (mounted) {
      setState(() {
        _prefs = p;
        _loading = false;
      });
    }
  }

  Future<void> _save(QuietHoursPrefs p) async {
    setState(() => _prefs = p);
    final storage = StorageService();
    final userId = storage.getMaterieProfile()?.userId ??
        storage.getEnergieProfile()?.userId;
    await QuietHoursService.instance.save(p, userId: userId);
  }

  Future<void> _pickHour({required bool isStart}) async {
    final current = TimeOfDay(
      hour: isStart ? _prefs.startHour : _prefs.endHour,
      minute: 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    await _save(QuietHoursPrefs(
      enabled: _prefs.enabled,
      startHour: isStart ? picked.hour : _prefs.startHour,
      endHour: isStart ? _prefs.endHour : picked.hour,
    ));
  }

  String _fmt(int h) => '${h.toString().padLeft(2, '0')}:00';

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Stille Stunden',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                _prefs.enabled
                    ? 'Aktiv von ${_fmt(_prefs.startHour)} bis ${_fmt(_prefs.endHour)} — keine Push/In-App-Notifs'
                    : 'Deaktiviert — Notifications kommen jederzeit',
              ),
              value: _prefs.enabled,
              onChanged: (v) => _save(QuietHoursPrefs(
                enabled: v,
                startHour: _prefs.startHour,
                endHour: _prefs.endHour,
              )),
              secondary: Icon(
                _prefs.enabled ? Icons.bedtime : Icons.bedtime_outlined,
                color: _prefs.enabled ? const Color(0xFF7C4DFF) : Colors.grey,
              ),
            ),
            if (_prefs.enabled) ...[
              const Divider(height: 1),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Beginn'),
                      subtitle: Text(_fmt(_prefs.startHour)),
                      onTap: () => _pickHour(isStart: true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Ende'),
                      subtitle: Text(_fmt(_prefs.endHour)),
                      onTap: () => _pickHour(isStart: false),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
