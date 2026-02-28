import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'frequency_generator_screen.dart';
import 'lunar_optimizer_screen.dart';
import 'consciousness_tracker_screen.dart';
import 'archetype_compass_screen.dart';
import 'synchronicity_journal_screen.dart';
import 'divination_suite_screen.dart';

class EnergieToolsScreen extends StatelessWidget {
  const EnergieToolsScreen({super.key});

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
                    const Expanded(child: Text('ENERGIE TOOLS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2))),
                  ],
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.all(16),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildToolCard(context, '🎵', 'Frequency\nGenerator', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FrequencyGeneratorScreen()))),
                    _buildToolCard(context, '🌙', 'Lunar\nOptimizer', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LunarOptimizerScreen()))),
                    _buildToolCard(context, '🧘', 'Consciousness\nTracker', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConsciousnessTrackerScreen()))),
                    _buildToolCard(context, '🔮', 'Archetyp\nKompass', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArchetypeCompassScreen()))),
                    _buildToolCard(context, '✨', 'Synchronicity\nJournal', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SynchronicityJournalScreen()))),
                    _buildToolCard(context, '🎴', 'Divination\nSuite', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DivinationSuiteScreen()))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, String emoji, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF9C27B0).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
