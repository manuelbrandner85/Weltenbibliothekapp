import 'package:flutter/material.dart';
import '../services/cloudflare_push_service.dart';

class CloudflareNotificationSettingsScreen extends StatefulWidget {
  const CloudflareNotificationSettingsScreen({super.key});

  @override
  State<CloudflareNotificationSettingsScreen> createState() =>
      _CloudflareNotificationSettingsScreenState();
}

class _CloudflareNotificationSettingsScreenState
    extends State<CloudflareNotificationSettingsScreen> {
  final CloudflarePushService _pushService = CloudflarePushService();
  List<String> _subscribedTopics = [];
  bool _isSubscribed = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    await _pushService.initialize();
    _subscribedTopics = _pushService.getSubscribedTopics();
    _isSubscribed = _subscribedTopics.isNotEmpty;

    // Load notification history
    _notifications = await _pushService.getNotifications();

    setState(() => _isLoading = false);
  }

  Future<void> _toggleSubscription(bool value) async {
    if (value) {
      await _pushService.subscribe();
      if (!mounted) return; // ✅ SAFETY: Check widget still mounted
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Push-Benachrichtigungen aktiviert')),
      );
    } else {
      await _pushService.unsubscribe();
      if (!mounted) return; // ✅ SAFETY: Check widget still mounted
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Push-Benachrichtigungen deaktiviert')),
      );
    }

    if (!mounted) return; // ✅ SAFETY: Check widget still mounted
    setState(() => _isSubscribed = value);
  }

  Future<void> _toggleTopic(String topic, bool value) async {
    if (value) {
      await _pushService.subscribeToTopics([topic]);
      if (!mounted) return; // ✅ SAFETY: Check widget still mounted
      setState(() => _subscribedTopics.add(topic));
    } else {
      // Unsubscribe would need additional API endpoint
      if (!mounted) return; // ✅ SAFETY: Check widget still mounted
      setState(() => _subscribedTopics.remove(topic));
    }

    if (!mounted) return; // ✅ SAFETY: Check widget still mounted
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? '✅ Topic aktiviert' : '❌ Topic deaktiviert'),
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    await _pushService.sendTestNotification();
    await _loadSettings(); // Reload to show new notification
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔔 Test-Benachrichtigung gesendet!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('🔔 Push-Benachrichtigungen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 24),

          // Main toggle
          _buildMainToggle(),
          const SizedBox(height: 24),

          // Topics
          if (_isSubscribed) ...[
            _buildTopicsSection(),
            const SizedBox(height: 24),
          ],

          // Test button
          _buildTestButton(),
          const SizedBox(height: 24),

          // Notification history
          _buildNotificationHistory(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Text(
                'Cloudflare Push',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Powered by Cloudflare Workers\nSchnell, zuverlässig & kostenlos',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'User ID: ${_pushService.getUserId()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          Icon(
            _isSubscribed ? Icons.notifications_active : Icons.notifications_off,
            color: _isSubscribed ? Colors.green : Colors.grey,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Push-Benachrichtigungen',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isSubscribed ? 'Aktiviert' : 'Deaktiviert',
                  style: TextStyle(
                    color: _isSubscribed ? Colors.green : Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isSubscribed,
            onChanged: _toggleSubscription,
            activeThumbColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            '📋 Themen abonnieren',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...CloudflarePushService.availableTopics.entries.map((entry) {
          final isSubscribed = _subscribedTopics.contains(entry.key);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSubscribed ? Colors.blue : const Color(0xFF2A2A2A),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.value,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                Switch(
                  value: isSubscribed,
                  onChanged: (value) => _toggleTopic(entry.key, value),
                  activeThumbColor: Colors.blue,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTestButton() {
    return ElevatedButton.icon(
      onPressed: _sendTestNotification,
      icon: const Icon(Icons.send),
      label: const Text('Test-Benachrichtigung senden'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildNotificationHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            '📜 Benachrichtigungsverlauf',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (_notifications.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.notifications_none, size: 48, color: Colors.grey[700]),
                  const SizedBox(height: 12),
                  Text(
                    'Keine Benachrichtigungen',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          ..._notifications.take(10).map((notif) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif['title'] ?? 'Benachrichtigung',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif['body'] ?? '',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTimestamp(notif['created_at']),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
    return '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
