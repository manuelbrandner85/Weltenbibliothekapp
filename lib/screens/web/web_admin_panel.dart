// 👑 WEB ADMIN PANEL
// Verwaltung von Web-Zugängen: Anträge genehmigen/ablehnen, Zugänge widerrufen.
// Nur für Admins (root_admin in Supabase profiles).

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  String? _error;

  static const Color _gold = Color(0xFFC9A84C);
  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _surface = Color(0xFF141414);
  static const Color _border = Color(0xFF2A2A2A);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
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

      // Warten auf Freigabe
      final pendingRes = await supabase
          .from('web_user_profiles')
          .select()
          .eq('is_approved', false)
          .order('requested_at', ascending: true);

      // Freigegebene User
      final approvedRes = await supabase
          .from('web_user_profiles')
          .select()
          .eq('is_approved', true)
          .order('approved_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _pending = List<Map<String, dynamic>>.from(pendingRes);
        _approved = List<Map<String, dynamic>>.from(approvedRes);
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

  Future<void> _approve(String userId, String email) async {
    try {
      await Supabase.instance.client.from('web_user_profiles').update({
        'is_approved': true,
        'approved_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$email wurde freigeschaltet.'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _reject(String userId, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Antrag ablehnen',
            style: TextStyle(color: Colors.white)),
        content: Text('Zugangsantrag von $email ablehnen und Eintrag löschen?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Abbrechen', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ablehnen',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('web_user_profiles')
          .delete()
          .eq('user_id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Antrag von $email abgelehnt.'),
            backgroundColor: Colors.orange.shade700,
          ),
        );
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _revoke(String userId, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Zugang widerrufen',
            style: TextStyle(color: Colors.white)),
        content: Text('Den Zugang von $email widerrufen?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Abbrechen', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Widerrufen',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('web_user_profiles')
          .update({'is_approved': false, 'approved_at': null})
          .eq('user_id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zugang von $email widerrufen.'),
            backgroundColor: Colors.orange.shade700,
          ),
        );
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade700,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_pending.length}',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Freigeschaltet'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _gold),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off, color: Colors.white38, size: 48),
                      const SizedBox(height: 16),
                      Text(_error!,
                          style: const TextStyle(color: Colors.white54)),
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
                )
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _buildPendingList(),
                    _buildApprovedList(),
                  ],
                ),
    );
  }

  Widget _buildPendingList() {
    if (_pending.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, color: Colors.white24, size: 56),
            SizedBox(height: 16),
            Text('Keine ausstehenden Anträge',
                style: TextStyle(color: Colors.white38, fontSize: 15)),
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
        itemCount: _pending.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final item = _pending[i];
          final email = item['email'] as String? ?? 'Unbekannt';
          final userId = item['user_id'] as String;
          final requestedAt = item['requested_at'] as String?;

          return _UserCard(
            email: email,
            userId: userId,
            subtitle: requestedAt != null
                ? 'Beantragt: ${_formatDate(requestedAt)}'
                : 'Datum unbekannt',
            status: _UserStatus.pending,
            onPrimary: () => _approve(userId, email),
            onSecondary: () => _reject(userId, email),
            primaryLabel: 'Freischalten',
            secondaryLabel: 'Ablehnen',
          );
        },
      ),
    );
  }

  Widget _buildApprovedList() {
    if (_approved.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, color: Colors.white24, size: 56),
            SizedBox(height: 16),
            Text('Keine freigeschalteten Nutzer',
                style: TextStyle(color: Colors.white38, fontSize: 15)),
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
        itemCount: _approved.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final item = _approved[i];
          final email = item['email'] as String? ?? 'Unbekannt';
          final userId = item['user_id'] as String;
          final approvedAt = item['approved_at'] as String?;

          return _UserCard(
            email: email,
            userId: userId,
            subtitle: approvedAt != null
                ? 'Freigeschaltet: ${_formatDate(approvedAt)}'
                : 'Datum unbekannt',
            status: _UserStatus.approved,
            onPrimary: null,
            onSecondary: () => _revoke(userId, email),
            primaryLabel: '',
            secondaryLabel: 'Zugang entziehen',
          );
        },
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }
}

enum _UserStatus { pending, approved }

class _UserCard extends StatelessWidget {
  final String email;
  final String userId;
  final String subtitle;
  final _UserStatus status;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;
  final String primaryLabel;
  final String secondaryLabel;

  static const Color _gold = Color(0xFFC9A84C);
  static const Color _surface = Color(0xFF141414);
  static const Color _border = Color(0xFF2A2A2A);

  const _UserCard({
    required this.email,
    required this.userId,
    required this.subtitle,
    required this.status,
    required this.onPrimary,
    required this.onSecondary,
    required this.primaryLabel,
    required this.secondaryLabel,
  });

  @override
  Widget build(BuildContext context) {
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
                decoration: BoxDecoration(
                  color: status == _UserStatus.pending
                      ? Colors.orange.withValues(alpha: 0.12)
                      : Colors.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  status == _UserStatus.pending
                      ? Icons.hourglass_empty_rounded
                      : Icons.check_circle_rounded,
                  color: status == _UserStatus.pending
                      ? Colors.orange
                      : Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(email,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
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
                const SizedBox(width: 8),
              ],
              if (onSecondary != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSecondary,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side:
                          BorderSide(color: Colors.red.withValues(alpha: 0.4)),
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
      ),
    );
  }
}
