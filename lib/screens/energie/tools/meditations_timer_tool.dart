import 'package:flutter/material.dart';
import 'dart:async';

class MeditationsTimerTool extends StatefulWidget {
  const MeditationsTimerTool({super.key});
  @override
  State<MeditationsTimerTool> createState() => _MeditationsTimerToolState();
}

class _MeditationsTimerToolState extends State<MeditationsTimerTool> {
  int _selectedMinutes = 10;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  Timer? _timer;

  void _startTimer() {
    setState(() {
      _remainingSeconds = _selectedMinutes * 60;
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _stopTimer();
        _showCompletionDialog();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _stopTimer();
    setState(() => _remainingSeconds = 0);
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✨ Meditation abgeschlossen'),
        content: Text('Du hast $_selectedMinutes Minuten meditiert! 🧘‍♀️'),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    return Scaffold(
      appBar: AppBar(title: const Text('⏱️ Meditations-Timer'), backgroundColor: Colors.blue),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.self_improvement, size: 80, color: Colors.blue),
            const SizedBox(height: 40),
            if (!_isRunning) ...[
              const Text('Wähle deine Meditations-Dauer:', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              Wrap(spacing: 12, children: [5, 10, 15, 20, 30].map((min) => ChoiceChip(label: Text('$min Min'), selected: _selectedMinutes == min, onSelected: (sel) => setState(() => _selectedMinutes = min))).toList()),
            ] else ...[
              Text('${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
            const SizedBox(height: 40),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (!_isRunning) ElevatedButton.icon(onPressed: _startTimer, icon: const Icon(Icons.play_arrow), label: const Text('Starten'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16))),
              if (_isRunning) ...[
                ElevatedButton.icon(onPressed: _stopTimer, icon: const Icon(Icons.pause), label: const Text('Pause'), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange)),
                const SizedBox(width: 12),
                ElevatedButton.icon(onPressed: _resetTimer, icon: const Icon(Icons.stop), label: const Text('Stopp'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red)),
              ],
            ]),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
