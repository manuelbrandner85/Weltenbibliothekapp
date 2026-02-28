import 'package:flutter/material.dart';
import '../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../../models/archetype_quiz.dart';

class ArchetypeCompassScreen extends StatefulWidget {
  const ArchetypeCompassScreen({super.key});

  @override
  State<ArchetypeCompassScreen> createState() => _ArchetypeCompassScreenState();
}

class _ArchetypeCompassScreenState extends State<ArchetypeCompassScreen> {
  int _currentQuestion = 0;
  final List<int> _answers = [];
  List<ArchetypeResult>? _results;

  void _answerQuestion(int archetypeIndex) {
    setState(() {
      _answers.add(archetypeIndex);
      if (_currentQuestion < ArchetypeQuestion.getQuestions().length - 1) {
        _currentQuestion++;
      } else {
        _results = ArchetypeResult.calculateResults(_answers);
      }
    });
  }

  void _restart() {
    setState(() {
      _currentQuestion = 0;
      _answers.clear();
      _results = null;
    });
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
          child: _results == null ? _buildQuiz() : _buildResults(),
        ),
      ),
    );
  }

  Widget _buildQuiz() {
    final questions = ArchetypeQuestion.getQuestions();
    final question = questions[_currentQuestion];
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
              Expanded(child: Text('Frage ${_currentQuestion + 1}/${questions.length}', style: const TextStyle(color: Colors.white, fontSize: 16))),
            ],
          ),
        ),
        LinearProgressIndicator(value: (_currentQuestion + 1) / questions.length, backgroundColor: Colors.white24, color: const Color(0xFF9C27B0)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔮', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 24),
                Text(question.question, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 48),
                ...question.answers.entries.map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _answerQuestion(e.value),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C27B0),
                      padding: const EdgeInsets.all(20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(e.key, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
                  ),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    final top3 = _results!.take(3).toList();
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
              const Expanded(child: Text('DEINE ARCHETYPEN', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _restart),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: top3.length,
            itemBuilder: (context, index) {
              final archetype = top3[index];
              final percentage = (archetype.score * 100).toStringAsFixed(0);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF9C27B0).withValues(alpha: 0.3 - index * 0.1),
                      const Color(0xFF9C27B0).withValues(alpha: 0.1 - index * 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 1.0 - index * 0.3), width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(archetype.emoji, style: const TextStyle(fontSize: 48)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(archetype.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('$percentage% Match', style: TextStyle(color: const Color(0xFF9C27B0).withValues(alpha: 1.0), fontSize: 14)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withValues(alpha: index == 0 ? 0.3 : 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('#${index + 1}', style: TextStyle(color: index == 0 ? const Color(0xFFFFD700) : Colors.white70, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(archetype.description, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: archetype.strengths.map((s) => Chip(
                        label: Text(s, style: const TextStyle(fontSize: 12)),
                        backgroundColor: const Color(0xFF9C27B0).withValues(alpha: 0.3),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.diamond, color: Color(0xFF64B5F6), size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(archetype.crystals.join(', '), style: const TextStyle(color: Colors.white70, fontSize: 12))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(archetype.mantras.join(' • '), style: const TextStyle(color: Colors.white70, fontSize: 12))),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Implementiere Share-Funktion (Social Media, Export)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔗 Share-Funktion coming soon'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Ergebnis teilen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
