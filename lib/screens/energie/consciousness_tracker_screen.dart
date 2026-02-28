import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:fl_chart/fl_chart.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../../models/consciousness_entry.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0

class ConsciousnessTrackerScreen extends StatefulWidget {
  const ConsciousnessTrackerScreen({super.key});

  @override
  State<ConsciousnessTrackerScreen> createState() => _ConsciousnessTrackerScreenState();
}

class _ConsciousnessTrackerScreenState extends State<ConsciousnessTrackerScreen> {
  late Box<ConsciousnessEntry> _box;
  // UNUSED FIELD: String _selectedActivity = 'meditation';
  
  @override
  void initState() {
    super.initState();
    _initBox();
  }

  Future<void> _initBox() async {
    await ConsciousnessEntry.registerAdapter();
    _box = await Hive.openBox<ConsciousnessEntry>('consciousness');
    setState(() {});
  }

  void _addEntry() {
    showDialog(
      context: context,
      builder: (context) => _AddEntryDialog(onAdd: (entry) {
        _box.add(entry);
        setState(() {});
      }),
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
                    const Expanded(child: Text('CONSCIOUSNESS TRACKER', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2))),
                    IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFF9C27B0)), onPressed: _addEntry),
                  ],
                ),
              ),
              Expanded(
                child: _box.isEmpty
                    ? Center(child: Text('Noch keine Einträge', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildStats(),
                            const SizedBox(height: 24),
                            _buildChart(),
                            const SizedBox(height: 24),
                            _buildEntries(),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    final entries = _box.values.toList();
    final totalMinutes = entries.fold(0, (sum, e) => sum + e.duration);
    final avgMoodImprovement = entries.isEmpty ? 0.0 : entries.fold(0.0, (sum, e) => sum + e.moodImprovement) / entries.length;
    
    return Row(
      children: [
        Expanded(child: _buildStatCard('Sessions', '${entries.length}', Icons.calendar_today)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Minuten', '$totalMinutes', Icons.schedule)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Stimmung', '+${avgMoodImprovement.toStringAsFixed(1)}', Icons.mood)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final last7Days = _box.values.where((e) => e.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 7)))).toList();
    if (last7Days.isEmpty) return const SizedBox();
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: last7Days.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.moodAfter.toDouble())).toList(),
              isCurved: true,
              color: const Color(0xFF9C27B0),
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntries() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Verlauf', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._box.values.toList().reversed.take(10).map((entry) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(_getActivityIcon(entry.activityType), color: const Color(0xFF9C27B0)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.activityType.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('${entry.duration} Min · Stimmung: ${entry.moodBefore}→${entry.moodAfter}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'meditation': return Icons.self_improvement;
      case 'mantra': return Icons.music_note;
      case 'tarot': return Icons.auto_awesome;
      default: return Icons.circle;
    }
  }
}

class _AddEntryDialog extends StatefulWidget {
  final Function(ConsciousnessEntry) onAdd;
  const _AddEntryDialog({required this.onAdd});

  @override
  State<_AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<_AddEntryDialog> {
  String _activity = 'meditation';
  int _duration = 10;
  int _moodBefore = 5;
  int _moodAfter = 5;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text('Neuer Eintrag', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _activity,
            dropdownColor: const Color(0xFF1A1A1A),
            style: const TextStyle(color: Colors.white),
            items: const [
              DropdownMenuItem(value: 'meditation', child: Text('Meditation')),
              DropdownMenuItem(value: 'mantra', child: Text('Mantra')),
              DropdownMenuItem(value: 'tarot', child: Text('Tarot')),
            ],
            onChanged: (v) => setState(() => _activity = v!),
          ),
          const SizedBox(height: 16),
          Text('Dauer: $_duration Min', style: const TextStyle(color: Colors.white)),
          Slider(value: _duration.toDouble(), min: 1, max: 120, onChanged: (v) => setState(() => _duration = v.toInt())),
          const SizedBox(height: 16),
          Text('Stimmung vorher: $_moodBefore', style: const TextStyle(color: Colors.white)),
          Slider(value: _moodBefore.toDouble(), min: 1, max: 10, onChanged: (v) => setState(() => _moodBefore = v.toInt())),
          const SizedBox(height: 16),
          Text('Stimmung nachher: $_moodAfter', style: const TextStyle(color: Colors.white)),
          Slider(value: _moodAfter.toDouble(), min: 1, max: 10, onChanged: (v) => setState(() => _moodAfter = v.toInt())),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        ElevatedButton(
          onPressed: () {
            widget.onAdd(ConsciousnessEntry(
              timestamp: DateTime.now(),
              activityType: _activity,
              duration: _duration,
              moodBefore: _moodBefore,
              moodAfter: _moodAfter,
            ));
            Navigator.pop(context);
          },
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
