import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/push_notification_manager.dart';

/// E-X3: Self-contained Switch zum Aktivieren der taeglichen Tarot-Erinnerung.
///
/// Verwaltet die eigene Praeferenz (SharedPreferences) und plant bzw. storniert
/// die lokale Erinnerung ueber den PushNotificationManager (No-Op auf Web).
class DailyTarotReminderTile extends StatefulWidget {
  const DailyTarotReminderTile({super.key});

  @override
  State<DailyTarotReminderTile> createState() => _DailyTarotReminderTileState();
}

class _DailyTarotReminderTileState extends State<DailyTarotReminderTile> {
  static const _prefsKey = 'daily_tarot_reminder_enabled';
  bool _enabled = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _enabled = prefs.getBool(_prefsKey) ?? false);
    }
  }

  Future<void> _toggle(bool value) async {
    setState(() {
      _enabled = value;
      _busy = true;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
    if (value) {
      await PushNotificationManager.instance.scheduleDailyTarot();
    } else {
      await PushNotificationManager.instance.cancelDailyTarot();
    }
    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value
              ? 'Taegliche Tarot-Erinnerung aktiviert'
              : 'Tarot-Erinnerung deaktiviert'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        title: const Text(
          'Taegliche Tarot-Karte',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'Einmal taeglich eine Erinnerung zur Tageskarte',
        ),
        value: _enabled,
        onChanged: _busy ? null : _toggle,
        secondary: Icon(
          _enabled ? Icons.auto_awesome : Icons.auto_awesome_outlined,
          color: _enabled ? const Color(0xFFC9A84C) : Colors.grey,
        ),
      ),
    );
  }
}
