import 'package:flutter/material.dart';
import '../services/push_notification_service.dart';
import '../services/auth_service.dart';

/// 🔔 Notification Settings Screen
///
/// Verwaltet Push Notification Einstellungen und Topics
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final PushNotificationService _pushService = PushNotificationService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  bool _isSubscribed = false;
  Map<String, bool> _topicSubscriptions = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _pushService.initialize();

    setState(() {
      _isSubscribed = _pushService.isSubscribed();
      _isLoading = false;
    });

    if (_isSubscribed) {
      await _loadSubscriptionSettings();
    }
  }

  Future<void> _loadSubscriptionSettings() async {
    final settings = await _pushService.getSubscriptionSettings();

    if (settings != null && mounted) {
      setState(() {
        final topics = settings['topics'] as List<dynamic>? ?? [];
        for (final topic in NotificationTopic.values) {
          _topicSubscriptions[topic.id] = topics.contains(topic.id);
        }
      });
    }
  }

  Future<void> _toggleMainSubscription(bool value) async {
    setState(() {
      _isLoading = true;
    });

    bool success;
    if (value) {
      // Subscribe
      final userId = _authService.userId ?? 'anonymous';
      success = await _pushService.subscribe(
        userId: userId,
        topics: ['new_events', 'system_updates'],
      );
    } else {
      // Unsubscribe
      success = await _pushService.unsubscribe();
    }

    if (mounted) {
      setState(() {
        _isSubscribed = value && success;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (value
                      ? '✅ Benachrichtigungen aktiviert'
                      : '✅ Benachrichtigungen deaktiviert')
                : '❌ Fehler beim Ändern der Einstellungen',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success && value) {
        await _loadSubscriptionSettings();
      }
    }
  }

  Future<void> _toggleTopic(NotificationTopic topic, bool value) async {
    bool success;
    if (value) {
      success = await _pushService.subscribeToTopic(topic.id);
    } else {
      success = await _pushService.unsubscribeFromTopic(topic.id);
    }

    if (mounted) {
      setState(() {
        if (success) {
          _topicSubscriptions[topic.id] = value;
        }
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? '✅ ${topic.label} aktiviert'
                  : '✅ ${topic.label} deaktiviert',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _sendTestNotification() async {
    final success = await _pushService.sendTestNotification();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ Test-Benachrichtigung gesendet'
                : '❌ Fehler beim Senden der Test-Benachrichtigung',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Benachrichtigungen'), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _isSubscribed
                                ? Icons.notifications_active
                                : Icons.notifications_off,
                            size: 64,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isSubscribed
                                ? 'Benachrichtigungen aktiv'
                                : 'Benachrichtigungen inaktiv',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isSubscribed
                                ? 'Du erhältst Updates zu deinen ausgewählten Themen'
                                : 'Aktiviere Benachrichtigungen um Updates zu erhalten',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Main Toggle
                  Card(
                    child: SwitchListTile(
                      title: const Text(
                        'Push-Benachrichtigungen',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Erhalte Benachrichtigungen zu wichtigen Events',
                      ),
                      secondary: const Icon(Icons.notifications),
                      value: _isSubscribed,
                      onChanged: _pushService.isSupported()
                          ? _toggleMainSubscription
                          : null,
                    ),
                  ),

                  if (!_pushService.isSupported()) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.orange[100],
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Push-Benachrichtigungen werden auf dieser Plattform nicht unterstützt',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (_isSubscribed) ...[
                    const SizedBox(height: 32),

                    // Topics Section
                    const Text(
                      'Benachrichtigungs-Themen',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Wähle aus, über welche Themen du informiert werden möchtest',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    ...NotificationTopic.values.map((topic) {
                      final isSubscribed =
                          _topicSubscriptions[topic.id] ?? false;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: SwitchListTile(
                          title: Text(topic.label),
                          subtitle: Text(_getTopicDescription(topic)),
                          secondary: Text(
                            topic.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          value: isSubscribed,
                          onChanged: (value) => _toggleTopic(topic, value),
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // Test Notification Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _sendTestNotification,
                        icon: const Icon(Icons.send),
                        label: const Text('Test-Benachrichtigung senden'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Info Section
                  Card(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Über Benachrichtigungen',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '• Benachrichtigungen werden nur für wichtige Updates gesendet\n'
                            '• Du kannst jederzeit einzelne Themen an- oder abwählen\n'
                            '• Deine Einstellungen werden sicher gespeichert\n'
                            '• Benachrichtigungen können in den System-Einstellungen deaktiviert werden',
                            style: TextStyle(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _getTopicDescription(NotificationTopic topic) {
    switch (topic) {
      case NotificationTopic.newEvents:
        return 'Neue mystische Orte und Ereignisse';
      case NotificationTopic.chatMessages:
        return 'Neue Nachrichten in deinen Chats';
      case NotificationTopic.liveStreams:
        return 'Live-Übertragungen von Events';
      case NotificationTopic.systemUpdates:
        return 'Wichtige App-Updates und Wartungen';
      case NotificationTopic.communityNews:
        return 'Community-Highlights und News';
    }
  }

  @override
  void dispose() {
    _pushService.dispose();
    super.dispose();
  }
}
