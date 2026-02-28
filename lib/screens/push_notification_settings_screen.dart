/// 📲 PUSH NOTIFICATION SETTINGS SCREEN
/// 
/// Allows users to configure:
/// - Notification categories (Messages, Mentions, Replies, System)
/// - Do-Not-Disturb schedule
/// - Sound & vibration preferences
library;

import 'package:flutter/material.dart';
import '../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../services/push_notification_service_v2.dart';

class PushNotificationSettingsScreen extends StatefulWidget {
  final String userId;

  const PushNotificationSettingsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<PushNotificationSettingsScreen> createState() => _PushNotificationSettingsScreenState();
}

class _PushNotificationSettingsScreenState extends State<PushNotificationSettingsScreen> {
  final _pushService = PushNotificationServiceV2();
  
  bool _enableMessages = true;
  bool _enableMentions = true;
  bool _enableReplies = true;
  bool _enableSystemAlerts = true;
  bool _dndEnabled = false;
  int _dndStartHour = 22;
  int _dndEndHour = 8;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final settings = await _pushService.getSettings(userId: widget.userId);
      
      setState(() {
        _enableMessages = settings['enable_messages'] ?? true;
        _enableMentions = settings['enable_mentions'] ?? true;
        _enableReplies = settings['enable_replies'] ?? true;
        _enableSystemAlerts = settings['enable_system_alerts'] ?? true;
        _dndEnabled = settings['dnd_enabled'] ?? false;
        _dndStartHour = settings['dnd_start_hour'] ?? 22;
        _dndEndHour = settings['dnd_end_hour'] ?? 8;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _pushService.updateSettings(
        userId: widget.userId,
        enableMessages: _enableMessages,
        enableMentions: _enableMentions,
        enableReplies: _enableReplies,
        enableSystemAlerts: _enableSystemAlerts,
        dndEnabled: _dndEnabled,
        dndStartHour: _dndStartHour,
        dndEndHour: _dndEndHour,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Einstellungen gespeichert'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fehler: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Push-Benachrichtigungen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Speichern',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Notification Categories
                _buildSectionHeader('Benachrichtigungs-Kategorien'),
                _buildSwitchTile(
                  title: 'Nachrichten',
                  subtitle: 'Benachrichtigungen für neue Chat-Nachrichten',
                  value: _enableMessages,
                  icon: Icons.message,
                  onChanged: (value) {
                    setState(() => _enableMessages = value);
                  },
                ),
                _buildSwitchTile(
                  title: 'Erwähnungen',
                  subtitle: 'Wenn du in einer Nachricht erwähnt wirst',
                  value: _enableMentions,
                  icon: Icons.alternate_email,
                  onChanged: (value) {
                    setState(() => _enableMentions = value);
                  },
                ),
                _buildSwitchTile(
                  title: 'Antworten',
                  subtitle: 'Wenn jemand auf deine Nachricht antwortet',
                  value: _enableReplies,
                  icon: Icons.reply,
                  onChanged: (value) {
                    setState(() => _enableReplies = value);
                  },
                ),
                _buildSwitchTile(
                  title: 'System-Benachrichtigungen',
                  subtitle: 'Wichtige Updates und Ankündigungen',
                  value: _enableSystemAlerts,
                  icon: Icons.notifications_active,
                  onChanged: (value) {
                    setState(() => _enableSystemAlerts = value);
                  },
                ),

                const Divider(height: 32),

                // Do-Not-Disturb
                _buildSectionHeader('Nicht Stören'),
                _buildSwitchTile(
                  title: 'Nicht Stören aktivieren',
                  subtitle: _dndEnabled
                      ? 'Aktiv von $_dndStartHour:00 bis $_dndEndHour:00'
                      : 'Keine Benachrichtigungen während dieser Zeit',
                  value: _dndEnabled,
                  icon: Icons.nightlight_round,
                  onChanged: (value) {
                    setState(() => _dndEnabled = value);
                  },
                ),

                if (_dndEnabled) ...[
                  ListTile(
                    leading: const Icon(Icons.bedtime),
                    title: const Text('Startzeit'),
                    subtitle: Text('$_dndStartHour:00 Uhr'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _selectTime(
                        context,
                        _dndStartHour,
                        (hour) => setState(() => _dndStartHour = hour),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.wb_sunny),
                    title: const Text('Endzeit'),
                    subtitle: Text('$_dndEndHour:00 Uhr'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _selectTime(
                        context,
                        _dndEndHour,
                        (hour) => setState(() => _dndEndHour = hour),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    int initialHour,
    ValueChanged<int> onSelected,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: 0),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onSelected(picked.hour);
    }
  }
}
