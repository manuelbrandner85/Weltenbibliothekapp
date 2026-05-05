/// 📋 MEINE ERMITTLUNGEN — gespeicherte Recherche-Threads.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../kaninchenbau_screen.dart';
import '../services/saved_threads_service.dart';
import '../widgets/kb_design.dart';

class MyInvestigationsScreen extends StatefulWidget {
  const MyInvestigationsScreen({super.key});

  @override
  State<MyInvestigationsScreen> createState() => _MyInvestigationsScreenState();
}

class _MyInvestigationsScreenState extends State<MyInvestigationsScreen> {
  final _service = SavedThreadsService.instance;
  List<SavedThread> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _service.listMyThreads();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KbDesign.voidBlack,
      appBar: AppBar(
        backgroundColor: KbDesign.voidBlack,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.bookmark_rounded, color: KbDesign.neonRedSoft, size: 22),
            const SizedBox(width: 10),
            const Text(
              'Meine Ermittlungen',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: KbDesign.neonRedSoft,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (_, i) => _buildItem(_items[i]),
                  ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_outline_rounded,
                size: 60, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 14),
            Text(
              'Keine gespeicherten Ermittlungen',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tippe im Kaninchenbau auf das Lesezeichen-Icon\num einen Pfad zu speichern.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      );

  Widget _buildItem(SavedThread t) {
    final df = DateFormat('dd.MM.yyyy · HH:mm');
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => KaninchenbauScreen(initialTopic: t.topic),
        ));
      },
      borderRadius: BorderRadius.circular(KbDesign.radiusMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: KbDesign.glassBox(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.topic,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (t.isPublic)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: KbDesign.goldAccent.withValues(alpha: 0.18),
                    ),
                    child: Text(
                      'GETEILT',
                      style: TextStyle(
                        color: KbDesign.goldAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.white54, size: 20),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: KbDesign.cardSurface,
                        title: const Text('Löschen?',
                            style: TextStyle(color: Colors.white)),
                        content: Text(
                          '"${t.topic}" wirklich löschen?',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Abbrechen'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KbDesign.credAlert,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Löschen'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await _service.deleteThread(t.id);
                      await _load();
                    }
                  },
                ),
              ],
            ),
            if (t.path.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: t.path
                    .map((p) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                          child: Text(
                            p,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
            if (t.notes != null && t.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                t.notes!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              df.format(t.createdAt),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
