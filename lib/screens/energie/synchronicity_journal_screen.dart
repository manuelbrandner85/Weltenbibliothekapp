import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/synchronicity_entry.dart';

class SynchronicityJournalScreen extends StatefulWidget {
  const SynchronicityJournalScreen({super.key});

  @override
  State<SynchronicityJournalScreen> createState() => _SynchronicityJournalScreenState();
}

class _SynchronicityJournalScreenState extends State<SynchronicityJournalScreen> {
  late Box<SynchronicityEntry> _box;
  
  @override
  void initState() {
    super.initState();
    _initBox();
  }

  Future<void> _initBox() async {
    await SynchronicityEntry.registerAdapter();
    _box = await Hive.openBox<SynchronicityEntry>('synchronicity');
    setState(() {});
  }

  void _addEntry() {
    final descController = TextEditingController();
    int significance = 5;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Neuer Zufall', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Beschreibe den Zufall...',
                  hintStyle: TextStyle(color: Colors.white38),
                ),
              ),
              const SizedBox(height: 16),
              Text('Bedeutung: $significance/10', style: const TextStyle(color: Colors.white)),
              Slider(
                value: significance.toDouble(),
                min: 1,
                max: 10,
                onChanged: (v) => setDialogState(() => significance = v.toInt()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
            ElevatedButton(
              onPressed: () {
                final patterns = SynchronicityEntry.detectPatterns(descController.text);
                _box.add(SynchronicityEntry(
                  timestamp: DateTime.now(),
                  description: descController.text,
                  pattern: patterns.isNotEmpty ? patterns.join(', ') : null,
                  significance: significance,
                ));
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF4A148C), Color(0xFF1A1A1A), Color(0xFF000000)]),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                    const Expanded(child: Text('SYNCHRONICITY JOURNAL', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2))),
                    IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFF9C27B0)), onPressed: _addEntry),
                  ],
                ),
              ),
              Expanded(
                child: _box.isEmpty
                    ? Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('✨', style: TextStyle(fontSize: 64)),
                          const SizedBox(height: 16),
                          Text('Noch keine Zufälle', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16)),
                        ],
                      ))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _box.length,
                        itemBuilder: (context, index) {
                          final entry = _box.getAt(_box.length - 1 - index)!;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF9C27B0).withValues(alpha: 0.2),
                                  const Color(0xFF9C27B0).withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.description,
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${entry.significance}/10',
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (entry.pattern != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '🔮 ${entry.pattern}',
                                      style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  '${entry.timestamp.day}.${entry.timestamp.month}.${entry.timestamp.year} · ${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 🧹 PHASE B: Proper resource disposal
    super.dispose();
  }
}
