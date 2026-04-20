// 🟢 UPDATE HISTORY SCREEN – Zeigt alle vergangenen Releases und OTA-Patches
//
// Liest public.update_history aus Supabase (read-only, absteigend nach Datum).
// Jeder Eintrag zeigt: Typ (Release/Patch), Version, Datum, Changelog.
// Pull-to-Refresh + Skeleton-Loading + freundlicher Leer-/Fehler-Zustand.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdateHistoryScreen extends StatefulWidget {
  const UpdateHistoryScreen({super.key});

  static const routeName = '/update_history';

  @override
  State<UpdateHistoryScreen> createState() => _UpdateHistoryScreenState();
}

class _UpdateHistoryScreenState extends State<UpdateHistoryScreen> {
  static const _bg = Color(0xFF04080F);
  static const _card = Color(0xFF0A1020);
  static const _cyan = Color(0xFF00E5FF);
  static const _purple = Color(0xFF7C4DFF);

  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final rows = await Supabase.instance.client
          .from('update_history')
          .select('type, version, patch_number, changelog, published_at, github_run_url')
          .order('published_at', ascending: false)
          .limit(50)
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _items = List<Map<String, dynamic>>.from(rows as List);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMsg = 'Laden fehlgeschlagen. Bitte erneut versuchen.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        foregroundColor: Colors.white,
        title: const Text(
          'Update-Verlauf',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _cyan.withValues(alpha: 0.2)),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildSkeleton();
    if (_errorMsg != null) return _buildError();
    if (_items.isEmpty) return _buildEmpty();
    return RefreshIndicator(
      color: _cyan,
      backgroundColor: _card,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: _items.length,
        itemBuilder: (context, i) => _buildItem(_items[i]),
      ),
    );
  }

  // ── Skeleton ─────────────────────────────────────────────────────────────

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: 5,
      itemBuilder: (_, __) => _SkeletonCard(),
    );
  }

  // ── Empty ─────────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return RefreshIndicator(
      color: _cyan,
      backgroundColor: _card,
      onRefresh: _load,
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Column(
            children: [
              Icon(Icons.history_rounded,
                  size: 56, color: Colors.white.withValues(alpha: 0.15)),
              const SizedBox(height: 16),
              Text(
                'Noch keine Einträge',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Releases und OTA-Patches erscheinen hier\nnach dem nächsten Workflow-Run.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 48, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              _errorMsg!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Erneut versuchen'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _cyan,
                side: BorderSide(color: _cyan.withValues(alpha: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── List item ─────────────────────────────────────────────────────────────

  Widget _buildItem(Map<String, dynamic> item) {
    final isRelease = item['type'] == 'release';
    final version = item['version'] as String? ?? '?';
    final patchNumber = item['patch_number'] as int?;
    final changelog = item['changelog'] as String?;
    final publishedAt = item['published_at'] as String?;
    final runUrl = item['github_run_url'] as String?;

    final color = isRelease ? _purple : _cyan;
    final label = isRelease ? 'Release' : 'Patch';
    final icon = isRelease ? Icons.new_releases_rounded : Icons.bolt_rounded;

    String title = 'v$version';
    if (!isRelease && patchNumber != null) title += ' · Patch $patchNumber';

    String? dateStr;
    if (publishedAt != null) {
      try {
        final dt = DateTime.parse(publishedAt).toLocal();
        dateStr =
            '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: color, size: 13),
                      const SizedBox(width: 5),
                      Text(label,
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                ),
                if (dateStr != null)
                  Text(dateStr,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11)),
              ],
            ),
            if (changelog != null && changelog.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                changelog,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    height: 1.6),
              ),
            ],
            if (runUrl != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.open_in_new_rounded,
                      size: 11, color: Colors.white.withValues(alpha: 0.3)),
                  const SizedBox(width: 4),
                  Text('CI-Run',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 11)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Animated skeleton placeholder ────────────────────────────────────────────

class _SkeletonCard extends StatefulWidget {
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final alpha = 0.04 + _anim.value * 0.06;
        final bg = Colors.white.withValues(alpha: alpha);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1020),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _pill(64, 22, bg),
                const SizedBox(width: 10),
                _pill(90, 14, bg),
                const Spacer(),
                _pill(52, 11, bg),
              ]),
              const SizedBox(height: 12),
              _pill(double.infinity, 11, bg),
              const SizedBox(height: 6),
              _pill(220, 11, bg),
            ],
          ),
        );
      },
    );
  }

  Widget _pill(double w, double h, Color c) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(6),
        ),
      );
}
