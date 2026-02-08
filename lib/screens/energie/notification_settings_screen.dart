/// Notification Settings Screen
/// Weltenbibliothek v61
library;

import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _notificationsEnabled = false;
  bool _dailyReminder = false;
  bool _achievementAlerts = false;
  bool _streakReminder = false;
  
  final String _selectedTime = '09:00';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text('🔔 Benachrichtigungen'),
        backgroundColor: Color(0xFFFF9800),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF9800).withValues(alpha: 0.3), Color(0xFF000000)],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // Info Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFF9800).withValues(alpha: 0.3),
                    Color(0xFFFFA000).withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFFFF9800).withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Icon(Icons.notifications_active, size: 48, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Bleib auf deinem spirituellen Pfad',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Erhalte tägliche Erinnerungen für deine Praxis',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Main Toggle
            _buildSettingCard(
              'Benachrichtigungen aktivieren',
              'Erlaube Push-Benachrichtigungen',
              Icons.notifications,
              _notificationsEnabled,
              (value) {
                setState(() {
                  _notificationsEnabled = value;
                  if (!value) {
                    _dailyReminder = false;
                    _achievementAlerts = false;
                    _streakReminder = false;
                  }
                });
                
                if (value) {
                  _requestPermission();
                }
              },
            ),
            
            if (_notificationsEnabled) ...[
              SizedBox(height: 16),
              
              // Daily Reminder
              _buildSettingCard(
                'Tägliche Erinnerung',
                'Meditation & Praxis-Reminder',
                Icons.alarm,
                _dailyReminder,
                (value) {
                  setState(() {
                    _dailyReminder = value;
                  });
                },
              ),
              
              // Time Picker
              if (_dailyReminder) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Uhrzeit',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextButton(
                        onPressed: () {
                          // Time picker would go here
                        },
                        child: Text(
                          _selectedTime,
                          style: TextStyle(
                            color: Color(0xFFFF9800),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              SizedBox(height: 16),
              
              // Achievement Alerts
              _buildSettingCard(
                'Achievement-Benachrichtigungen',
                'Bei neuen Erfolgen benachrichtigen',
                Icons.emoji_events,
                _achievementAlerts,
                (value) {
                  setState(() {
                    _achievementAlerts = value;
                  });
                },
              ),
              
              SizedBox(height: 16),
              
              // Streak Reminder
              _buildSettingCard(
                'Streak-Erinnerung',
                'Behalte deinen Streak bei',
                Icons.local_fire_department,
                _streakReminder,
                (value) {
                  setState(() {
                    _streakReminder = value;
                  });
                },
              ),
              
              SizedBox(height: 24),
              
              // Test Notification Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sendTestNotification,
                  icon: Icon(Icons.send),
                  label: Text('Test-Benachrichtigung senden'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            
            SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingCard(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFFFF9800), size: 32),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Color(0xFFFF9800),
          ),
        ],
      ),
    );
  }
  
  void _requestPermission() {
    // Browser notification permission
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Benachrichtigungen aktiviert! 🔔'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _sendTestNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.notifications, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🕉️ Zeit für deine Praxis',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Nimm dir 10 Minuten für Meditation',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFFFF9800),
        duration: Duration(seconds: 4),
      ),
    );
  }
}
