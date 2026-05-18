// 👑 WEB ADMIN PANEL v2
// Verwaltung von Web-Zugängen über die web_access_requests Tabelle.
// Tabs: Ausstehend / Freigegeben / Abgelehnt
// Aktionen: Freischalten, Ablehnen, Zugang entziehen, Reaktivieren

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/wb_cinematic_tokens.dart';
class WebAdminPanel extends StatefulWidget {
  const WebAdminPanel({super.key});

  @override
  State<WebAdminPanel> createState() => _WebAdminPanelState();
}

class _WebAdminPanelState extends State<WebAdminPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _loading = true;
  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _approved = [];
  List<Map<String, dynamic>> _rejected = [];
  String? _error;

  static const Color _gold = Color(0xFFC9A84C);
  static const Color _bgDark = Color(0xFF0A0A0A);

  /// Theme-aware background. Light-Mode liefert helle `context.wb.bgVoid`,
  /// Dark-Mode behält den Original-Ton.
  Color _bg(BuildContext context) {
    final wb = Theme.of(context).extension<WBCinematic>();
    return wb?.bgVoid ?? _bgDark;
  }
  static const Color _surface = Color(0xFF141414);
  static const Color _border = Color(0xFF2A2A2A);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;

      final all = await supabase
          .from('web_access_requests')
          .select()
          .order('requested_at', ascending: false);

      if (!mounted) return;

      final rows = List<Map<String, dynamic>>.from(all);

      setState(() {
        _pending =
            rows.where((r) => r['status'] == 'pending').toList();
        _approved =
            rows.where((r) => r['status'] == 'approved').toList();
        _rejected =
            rows.where((r) => r['status'] == 'rejected').toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Fehler beim Laden: $e';
        _loading = false;
      });
    }
  }

  Future<void> _setStatus(String id, String name, String status) async {
    final now = DateTime.now().toIso8601String();
    final update = <String, dynamic>{'status': status};
    if (status == 'approved') update['approved_at'] = now;
    if (status == 'rejected') update['rejected_at'] = now;

    try {
      await Supabase.instance.client
          .from('web_access_requests')
          .update(update)
          .eq('id', id);

      if (mounted) {
        final label = status == 'approved'
            ? 'freigeschaltet'
            : status == 'rejected'
                ? 'abgelehnt'
                : 'aktualisiert';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"$name" $label.'),
          backgroundColor: status == 'approved'
              ? Colors.green.shade700
              : Colors.orange.shade700,
        ));
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Fehler: $e'),
          backgroundColor: Colors.red.shade700,
        ));
      }
    }
  }

  Future<void> _delete(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Eintrag löschen',
            style: TextStyle(color: Colors.white)),
        content: Text('Eintrag für "$name" vollständig löschen?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Abbrechen', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('web_access_requests')
          .delete()
          .eq('id', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"$name" gelöscht.'),
          backgroundColor: Colors.red.shade700,
        ));
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Fehler: $e'),
          backgroundColor: Colors.red.shade700,
        ));
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('web_logged_in');
    await prefs.remove('web_user_name');
    await prefs.remove('web_is_admin');
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      appBar: AppBar(
        backgroundColor: _surface,
        title: const Row(
          children: [
            Icon(Icons.manage_accounts_rounded, color: _gold, size: 22),
            SizedBox(width: 10),
            Text('Web-Zugänge verwalten',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white54),
            tooltip: 'Ausloggen',
            onPressed: _logout,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _gold),
            tooltip: 'Aktualisieren',
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _gold,
          labelColor: _gold,
          unselectedLabelColor: Colors.white38,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Ausstehend'),
                  if (_pending.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _badge(_pending.length, Colors.orange.shade700),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Freigegeben'),
                  if (_approved.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _badge(_approved.length, Colors.green.shade700),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Abgelehnt'),
                  if (_rejected.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _badge(_rejected.length, Colors.red.shade700),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _buildList(
                      _pending,
                      emptyText: 'Keine ausstehenden Anträge',
                      emptyIcon: Icons.inbox_rounded,
                      primaryAction: (item) => _setStatus(
                          item['id'], item['display_name'], 'approved'),
                      primaryLabel: 'Freischalten',
                      secondaryAction: (item) => _setStatus(
                          item['id'], item['display_name'], 'rejected'),
                      secondaryLabel: 'Ablehnen',
                    ),
                    _buildList(
                      _approved,
                      emptyText: 'Keine freigeschalteten Nutzer',
                      emptyIcon: Icons.people_outline_rounded,
                      primaryAction: null,
                      primaryLabel: '',
                      secondaryAction: (item) => _setStatus(
                          item['id'], item['display_name'], 'pending'),
                      secondaryLabel: 'Zugang entziehen',
                      deleteAction: (item) =>
                          _delete(item['id'], item['display_name']),
                    ),
                    _buildList(
                      _rejected,
                      emptyText: 'Keine abgelehnten Anträge',
                      emptyIcon: Icons.block_rounded,
                      primaryAction: (item) => _setStatus(
                          item['id'], item['display_name'], 'approved'),
                      primaryLabel: 'Reaktivieren',
                      secondaryAction: null,
                      secondaryLabel: '',
                      deleteAction: (item) =>
                          _delete(item['id'], item['display_name']),
                    ),
                  ],
                ),
    );
  }

  Widget _badge(int count, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$count',
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white38, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _loadData,
              style: OutlinedButton.styleFrom(
                  foregroundColor: _gold,
                  side: const BorderSide(color: _gold)),
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );

  Widget _buildList(
    List<Map<String, dynamic>> items, {
    required String emptyText,
    required IconData emptyIcon,
    required Function(Map<String, dynamic>)? primaryAction,
    required String primaryLabel,
    required Function(Map<String, dynamic>)? secondaryAction,
    required String secondaryLabel,
    Function(Map<String, dynamic>)? deleteAction,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, color: Colors.white24, size: 56),
            const SizedBox(height: 16),
            Text(emptyText,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 15)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _gold,
      backgroundColor: _surface,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          final name = item['display_name'] as String? ?? 'Unbekannt';
          final status = item['status'] as String? ?? 'pending';
          final requestedAt = item['requested_at'] as String?;
          final approvedAt = item['approved_at'] as String?;
          final lastLogin = item['last_login_at'] as String?;

          String subtitle = requestedAt != null
              ? 'Beantragt: ${_fmt(requestedAt)}'
              : 'Datum unbekannt';
          if (approvedAt != null && status == 'approved') {
            subtitle += ' · Freig.: ${_fmt(approvedAt)}';
          }
          if (lastLogin != null) {
            subtitle += ' · Zuletzt: ${_fmt(lastLogin)}';
          }

          return _UserCard(
            name: name,
            subtitle: subtitle,
            status: status,
            onPrimary:
                primaryAction != null ? () => primaryAction(item) : null,
            primaryLabel: primaryLabel,
            onSecondary:
                secondaryAction != null ? () => secondaryAction(item) : null,
            secondaryLabel: secondaryLabel,
            onDelete: deleteAction != null ? () => deleteAction(item) : null,
          );
        },
      ),
    );
  }

  String _fmt(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _UserCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String status;
  final VoidCallback? onPrimary;
  final String primaryLabel;
  final VoidCallback? onSecondary;
  final String secondaryLabel;
  final VoidCallback? onDelete;

  static const Color _gold = Color(0xFFC9A84C);
  static const Color _surface = Color(0xFF141414);
  static const Color _border = Color(0xFF2A2A2A);

  const _UserCard({
    required this.name,
    required this.subtitle,
    required this.status,
    required this.onPrimary,
    required this.primaryLabel,
    required this.onSecondary,
    required this.secondaryLabel,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final (iconData, iconColor, bgColor) = switch (status) {
      'approved' => (
          Icons.check_circle_rounded,
          Colors.green,
          Colors.green.withValues(alpha: 0.12)
        ),
      'rejected' => (
          Icons.block_rounded,
          Colors.red,
          Colors.red.withValues(alpha: 0.12)
        ),
      _ => (
          Icons.hourglass_empty_rounded,
          Colors.orange,
          Colors.orange.withValues(alpha: 0.12)
        ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.white24, size: 18),
                  onPressed: onDelete,
                  tooltip: 'Löschen',
                ),
            ],
          ),
          if (onPrimary != null || onSecondary != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onPrimary != null) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onPrimary,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: Text(primaryLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  if (onSecondary != null) const SizedBox(width: 8),
                ],
                if (onSecondary != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSecondary,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: BorderSide(
                            color: Colors.red.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(secondaryLabel,
                          style: const TextStyle(fontSize: 13)),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
