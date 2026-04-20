// 🟢 UPDATE HISTORY SCREEN – Zeigt alle vergangenen Releases und OTA-Patches
//
// Liest public.update_history aus Supabase (read-only, absteigend nach Datum).
// Jeder Eintrag zeigt: Typ (Release/Patch), Version, Datum, Changelog.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdateHistoryScreen extends StatefulWidget {
  const UpdateHistoryScreen({super.key});

  static const routeName = '/update_history';

  @override
  State<UpdateHistoryScreen> createState() => _UpdateHistoryScreenState();
}

class _UpdateHistoryScreenState extends State<UpdateHistoryScreen> {
  late final Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchHistory();
  }

  Future<List<Map<String, dynamic>>> _fetchHistory() async {
    final rows = await Supabase.instance.client
        .from('update_history')
        .select('type, version, patch_number, changelog, published_at, github_run_url')
        .order('published_at', ascending: false)
        .limit(50)
        .timeout(const Duration(seconds: 10));
    return List<Map<String, dynamic>>.from(rows as List);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1020),
        foregroundColor: Colors.white,
        title: const Text(
          'Update-Verlauf',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
            );
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Fehler beim Laden:\n${snap.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                ),
              ),
            );
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Text(
                'Noch keine Einträge vorhanden.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) => _buildItem(items[index]),
          );
        },
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> item) {
    final isRelease = item['type'] == 'release';
    final version = item['version'] as String? ?? '?';
    final patchNumber = item['patch_number'] as int?;
    final changelog = item['changelog'] as String?;
    final publishedAt = item['published_at'] as String?;
    final runUrl = item['github_run_url'] as String?;

    final color = isRelease ? const Color(0xFF7C4DFF) : const Color(0xFF00E5FF);
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
        color: const Color(0xFF0A1020),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (dateStr != null)
                  Text(
                    dateStr,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
            if (changelog != null && changelog.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                changelog,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
            ],
            if (runUrl != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 11,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'CI-Run',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 11,
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
