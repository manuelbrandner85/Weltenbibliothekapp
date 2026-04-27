import 'package:flutter/material.dart';
import '../../config/wb_design.dart';
import '../../services/push_preferences_service.dart';

/// 🔔 Push Preferences Screen
///
/// User kann pro Notification-Typ entscheiden welche er bekommt.
/// Filter wird im PushNotificationManager._showLocal angewandt — die
/// Items bleiben in der notifications-Tabelle für das In-App-Center,
/// aber die OS-Push wird unterdrückt.
///
/// Design-Stil passend zum Home-Bereich (dunkel, glassmorphic, welt-
/// neutraler Cyan-Akzent für System-Settings).
class PushPreferencesScreen extends StatefulWidget {
  const PushPreferencesScreen({super.key});

  @override
  State<PushPreferencesScreen> createState() => _PushPreferencesScreenState();
}

class _PushPreferencesScreenState extends State<PushPreferencesScreen> {
  final _prefs = PushPreferencesService.instance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _prefs.init();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleAndRefresh(Future<void> Function() action) async {
    await action();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WbDesign.bgNeutral,
      appBar: AppBar(
        backgroundColor: WbDesign.bgNeutral,
        elevation: 0,
        title: const Text(
          'Benachrichtigungen',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(WbDesign.space16),
              children: [
                _buildMasterCard(),
                const SizedBox(height: WbDesign.space20),
                _buildSection(
                  icon: Icons.chat_bubble_outline,
                  title: 'Chat & Erwähnungen',
                  children: [
                    _buildToggle(
                      icon: '💬',
                      title: 'Chat-Nachrichten',
                      subtitle: 'Neue Nachrichten in Räumen',
                      value: _prefs.chat,
                      onChanged: (v) => _toggleAndRefresh(() => _prefs.setChat(v)),
                    ),
                    _buildToggle(
                      icon: '📣',
                      title: 'Erwähnungen',
                      subtitle: 'Wenn dich jemand mit @username markiert',
                      value: _prefs.mention,
                      onChanged: (v) => _toggleAndRefresh(() => _prefs.setMention(v)),
                    ),
                    _buildToggle(
                      icon: '↩️',
                      title: 'Antworten',
                      subtitle: 'Antworten auf deine Nachrichten',
                      value: _prefs.reply,
                      onChanged: (v) => _toggleAndRefresh(() => _prefs.setReply(v)),
                    ),
                  ],
                ),
                _buildSection(
                  icon: Icons.favorite_border,
                  title: 'Social',
                  children: [
                    _buildToggle(
                      icon: '❤️',
                      title: 'Likes',
                      subtitle: 'Wenn jemand deinen Beitrag mag',
                      value: _prefs.like,
                      onChanged: (v) => _toggleAndRefresh(() => _prefs.setLike(v)),
                    ),
                    _buildToggle(
                      icon: '💬',
                      title: 'Kommentare',
                      subtitle: 'Wenn jemand deinen Beitrag kommentiert',
                      value: _prefs.comment,
                      onChanged: (v) => _toggleAndRefresh(() => _prefs.setComment(v)),
                    ),
                    _buildToggle(
                      icon: '👤',
                      title: 'Neue Follower',
                      subtitle: 'Wenn dir jemand folgt',
                      value: _prefs.follow,
                      onChanged: (v) => _toggleAndRefresh(() => _prefs.setFollow(v)),
                    ),
                  ],
                ),
                _buildSection(
                  icon: Icons.article_outlined,
                  title: 'Inhalte & System',
                  children: [
                    _buildToggle(
                      icon: '📰',
                      title: 'Neue Artikel',
                      subtitle: 'In abonnierten Welten',
                      value: _prefs.article,
                      onChanged: (v) => _toggleAndRefresh(() => _prefs.setArticle(v)),
                    ),
                    _buildToggle(
                      icon: '🏆',
                      title: 'Achievements & System',
                      subtitle: 'Belohnungen, Updates, wichtige Hinweise',
                      value: _prefs.system,
                      onChanged: (v) => _toggleAndRefresh(() => _prefs.setSystem(v)),
                    ),
                  ],
                ),
                const SizedBox(height: WbDesign.space24),
                _buildHint(),
                const SizedBox(height: WbDesign.space40),
              ],
            ),
    );
  }

  Widget _buildMasterCard() {
    return Container(
      padding: const EdgeInsets.all(WbDesign.space16),
      decoration: BoxDecoration(
        gradient: WbDesign.updateAccent,
        borderRadius: BorderRadius.circular(WbDesign.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(WbDesign.radiusMedium),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: WbDesign.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alle Benachrichtigungen',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _prefs.isMasterEnabled
                      ? 'Aktiv — du bekommst Push-Nachrichten'
                      : 'Deaktiviert — keine Push-Nachrichten',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _prefs.isMasterEnabled,
            onChanged: (v) => _toggleAndRefresh(() => _prefs.setMaster(v)),
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.white.withValues(alpha: 0.3),
            inactiveThumbColor: Colors.white.withValues(alpha: 0.6),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: WbDesign.space12),
      padding: const EdgeInsets.symmetric(
        horizontal: WbDesign.space16,
        vertical: WbDesign.space8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF150E25),
        borderRadius: BorderRadius.circular(WbDesign.radiusCard),
        border: Border.all(color: WbDesign.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: WbDesign.space12),
            child: Row(
              children: [
                Icon(icon, color: WbDesign.energiePurpleLight, size: 18),
                const SizedBox(width: WbDesign.space8),
                Text(
                  title,
                  style: TextStyle(
                    color: WbDesign.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildToggle({
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isMasterDisabled = !_prefs.isMasterEnabled;
    return Opacity(
      opacity: isMasterDisabled ? 0.4 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: WbDesign.space8),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: WbDesign.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: WbDesign.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: WbDesign.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value && _prefs.isMasterEnabled,
              onChanged: isMasterDisabled ? null : onChanged,
              activeThumbColor: WbDesign.energiePurpleLight,
              activeTrackColor: WbDesign.energiePurple.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHint() {
    return Container(
      padding: const EdgeInsets.all(WbDesign.space12),
      decoration: BoxDecoration(
        color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(WbDesign.radiusMedium),
        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF00E5FF), size: 18),
          const SizedBox(width: WbDesign.space8),
          Expanded(
            child: Text(
              'Auch deaktivierte Benachrichtigungen erscheinen weiterhin in deinem '
              'In-App-Center — sie werden nur nicht als Push-Nachricht gezeigt.',
              style: TextStyle(
                color: WbDesign.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
