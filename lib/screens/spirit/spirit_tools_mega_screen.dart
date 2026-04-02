/// 🌟 SPIRIT TOOLS MEGA SCREEN - V115+ Weltenbibliothek
/// Alle neuen Spirit-Tools in einem kompakten Screen
library;

import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'dart:math' as math;
import '../../models/spirit_tools_models.dart';
import '../../services/achievement_service.dart';

// ========================================
// 📔 TRAUMTAGEBUCH SCREEN
// ========================================
class DreamJournalScreen extends StatefulWidget {
  const DreamJournalScreen({super.key});

  @override
  State<DreamJournalScreen> createState() => _DreamJournalScreenState();
}

class _DreamJournalScreenState extends State<DreamJournalScreen> {
  // UNUSED FIELD: final _storage = StorageService();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  List<DreamEntry> _dreams = [];
  DreamCategory _selectedCategory = DreamCategory.mundane;
  bool _isLucid = false;
  int _clarity = 3;

  @override
  void initState() {
    super.initState();
    _loadDreams();
  }

  Future<void> _loadDreams() async {
    // Load from storage
    setState(() {
      // Dummy data for now
      _dreams = [];
    });
  }

  Future<void> _saveDream() async {
    if (_titleController.text.isEmpty) return;
    
    // TODO: Use dream entry or remove
    /*
    final dream = DreamEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      title: _titleController.text,
      content: _contentController.text,
      category: _selectedCategory,
      clarity: _clarity,
      isLucid: _isLucid,
    );
    */

    // Save to storage
    _titleController.clear();
    _contentController.clear();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Traum gespeichert!')),
      );
      _loadDreams();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('📔 Traumtagebuch'),
        backgroundColor: const Color(0xFF4A148C),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title Input
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Titel',
              labelStyle: const TextStyle(color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Content Input
          TextField(
            controller: _contentController,
            style: const TextStyle(color: Colors.white),
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Traumbeschreibung',
              labelStyle: const TextStyle(color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Category Selector
          DropdownButtonFormField<DreamCategory>(
            initialValue: _selectedCategory,
            dropdownColor: const Color(0xFF1A1A2E),
            decoration: const InputDecoration(labelText: 'Kategorie'),
            items: DreamCategory.values.map((cat) {
              return DropdownMenuItem(
                value: cat,
                child: Text(_getCategoryName(cat), style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedCategory = value!),
          ),
          const SizedBox(height: 16),
          
          // Lucid Toggle
          SwitchListTile(
            title: const Text('Luzider Traum', style: TextStyle(color: Colors.white)),
            value: _isLucid,
            onChanged: (value) => setState(() => _isLucid = value),
            activeThumbColor: Colors.purple,
          ),
          
          // Clarity Slider
          const Text('Klarheit', style: TextStyle(color: Colors.white70)),
          Slider(
            value: _clarity.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: _clarity.toString(),
            onChanged: (value) => setState(() => _clarity = value.toInt()),
          ),
          const SizedBox(height: 16),
          
          // Save Button
          ElevatedButton(
            onPressed: _saveDream,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B1FA2),
              padding: const EdgeInsets.all(16),
            ),
            child: const Text('Traum speichern'),
          ),
          const SizedBox(height: 24),
          
          // Dream Symbols Database
          const Text(
            '🔍 Traumsymbole',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...SpiritToolsData.dreamSymbols.entries.take(5).map((entry) {
            return Card(
              color: const Color(0xFF1A1A2E),
              child: ListTile(
                leading: const Icon(Icons.psychology, color: Colors.purple),
                title: Text(entry.key, style: const TextStyle(color: Colors.white)),
                subtitle: Text(entry.value, style: const TextStyle(color: Colors.white70)),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getCategoryName(DreamCategory cat) {
    switch (cat) {
      case DreamCategory.adventure: return '🗺️ Abenteuer';
      case DreamCategory.nightmare: return '😱 Albtraum';
      case DreamCategory.lucid: return '✨ Luzid';
      case DreamCategory.prophetic: return '🔮 Prophetisch';
      case DreamCategory.recurring: return '🔄 Wiederkehrend';
      case DreamCategory.healing: return '💚 Heilend';
      case DreamCategory.spiritual: return '🙏 Spirituell';
      case DreamCategory.mundane: return '😴 Alltäglich';
    }
  }
}

// ========================================
// 🔮 RUNEN-ORAKEL SCREEN
// ========================================
class RuneOracleScreen extends StatefulWidget {
  const RuneOracleScreen({super.key});

  @override
  State<RuneOracleScreen> createState() => _RuneOracleScreenState();
}

class _RuneOracleScreenState extends State<RuneOracleScreen> {
  final _achievement = AchievementService();
  final _questionController = TextEditingController();
  
  List<DrawnRune>? _drawnRunes;
  bool _isDrawing = false;

  Future<void> _drawRunes() async {
    if (_questionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte stelle eine Frage')),
      );
      return;
    }

    setState(() => _isDrawing = true);
    
    await Future.delayed(const Duration(seconds: 2));
    
    final random = math.Random();
    final positions = ['Vergangenheit', 'Gegenwart', 'Zukunft'];
    final drawnRunes = <DrawnRune>[];
    
    for (int i = 0; i < 3; i++) {
      final rune = SpiritToolsData.elderFuthark[random.nextInt(8)];
      drawnRunes.add(DrawnRune(
        runeName: rune.name,
        isReversed: random.nextBool(),
        position: positions[i],
      ));
    }
    
    setState(() {
      _drawnRunes = drawnRunes;
      _isDrawing = false;
    });
    
    // Achievement tracking
    if (mounted) {
      // TODO: Re-enable after achievement integration
      // await _achievement.trackProgress(context, 'rune_first');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('🔮 Runen-Orakel'),
        backgroundColor: const Color(0xFF1A237E),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Question Input
          TextField(
            controller: _questionController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Deine Frage',
              labelStyle: const TextStyle(color: Colors.white70),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          
          // Draw Button
          ElevatedButton(
            onPressed: _isDrawing ? null : _drawRunes,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF283593),
              padding: const EdgeInsets.all(16),
            ),
            child: _isDrawing
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Runen ziehen'),
          ),
          const SizedBox(height: 24),
          
          // Drawn Runes
          if (_drawnRunes != null) ...[
            const Text(
              '✨ Deine Runen-Legung',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._drawnRunes!.map((drawnRune) {
              final rune = SpiritToolsData.elderFuthark.firstWhere(
                (r) => r.name == drawnRune.runeName,
              );
              return Card(
                color: const Color(0xFF1A1A2E),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            rune.symbol,
                            style: const TextStyle(fontSize: 40, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${rune.name} (${rune.germanName})',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  drawnRune.position,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (drawnRune.isReversed)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Umgekehrt',
                                style: TextStyle(color: Colors.red, fontSize: 10),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        drawnRune.isReversed ? rune.reverseMeaning : rune.meaning,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rune.interpretation,
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ========================================
// 🌟 AFFIRMATIONS-GENERATOR SCREEN
// ========================================
class AffirmationsScreen extends StatefulWidget {
  const AffirmationsScreen({super.key});

  @override
  State<AffirmationsScreen> createState() => _AffirmationsScreenState();
}

class _AffirmationsScreenState extends State<AffirmationsScreen> {
  AffirmationCategory _selectedCategory = AffirmationCategory.success;
  String? _currentAffirmation;

  void _generateAffirmation() {
    final affirmations = SpiritToolsData.affirmations[_selectedCategory]!;
    final random = math.Random();
    setState(() {
      _currentAffirmation = affirmations[random.nextInt(affirmations.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('🌟 Affirmationen'),
        backgroundColor: const Color(0xFFD84315),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Category Selector
            DropdownButton<AffirmationCategory>(
              value: _selectedCategory,
              dropdownColor: const Color(0xFF1A1A2E),
              isExpanded: true,
              items: AffirmationCategory.values.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(_getCategoryName(cat), style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
            const SizedBox(height: 24),
            
            // Generate Button
            ElevatedButton(
              onPressed: _generateAffirmation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Affirmation generieren'),
            ),
            const SizedBox(height: 32),
            
            // Current Affirmation
            if (_currentAffirmation != null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withValues(alpha: 0.3),
                      Colors.deepOrange.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _currentAffirmation!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(AffirmationCategory cat) {
    switch (cat) {
      case AffirmationCategory.success: return '🏆 Erfolg';
      case AffirmationCategory.love: return '❤️ Liebe';
      case AffirmationCategory.health: return '💚 Gesundheit';
      case AffirmationCategory.spirituality: return '🙏 Spiritualität';
      case AffirmationCategory.abundance: return '💰 Fülle';
      case AffirmationCategory.confidence: return '💪 Selbstvertrauen';
    }
  }
}

// ========================================
// 📈 BIORHYTHMUS-RECHNER SCREEN
// ========================================
class BiorhythmScreen extends StatefulWidget {
  const BiorhythmScreen({super.key});

  @override
  State<BiorhythmScreen> createState() => _BiorhythmScreenState();
}

class _BiorhythmScreenState extends State<BiorhythmScreen> {
  DateTime? _birthDate;
  BiorhythmData? _biorhythm;

  Future<void> _selectBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _birthDate = date;
        _biorhythm = BiorhythmData.calculate(date, DateTime.now());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('📈 Biorhythmus'),
        backgroundColor: const Color(0xFF00897B),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: _selectBirthDate,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF26A69A),
              padding: const EdgeInsets.all(16),
            ),
            child: Text(_birthDate == null ? 'Geburtsdatum wählen' : 'Geburtsdatum: ${_birthDate!.day}.${_birthDate!.month}.${_birthDate!.year}'),
          ),
          const SizedBox(height: 24),
          
          if (_biorhythm != null) ...[
            _buildRhythmCard('💪 Physisch', _biorhythm!.physical, Colors.red),
            const SizedBox(height: 12),
            _buildRhythmCard('❤️ Emotional', _biorhythm!.emotional, Colors.blue),
            const SizedBox(height: 12),
            _buildRhythmCard('🧠 Intellektuell', _biorhythm!.intellectual, Colors.green),
          ],
        ],
      ),
    );
  }

  Widget _buildRhythmCard(String title, double value, Color color) {
    final percentage = ((value + 1) / 2 * 100).toInt();
    return Card(
      color: const Color(0xFF1A1A2E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (value + 1) / 2,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 10,
            ),
            const SizedBox(height: 4),
            Text('$percentage%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ========================================
// 📖 I-GING ORAKEL SCREEN (Kompakt)
// ========================================
class IChingScreen extends StatefulWidget {
  const IChingScreen({super.key});

  @override
  State<IChingScreen> createState() => _IChingScreenState();
}

class _IChingScreenState extends State<IChingScreen> {
  Hexagram? _drawnHexagram;

  void _throwCoins() {
    final random = math.Random();
    final hexagram = SpiritToolsData.hexagrams[random.nextInt(SpiritToolsData.hexagrams.length)];
    setState(() => _drawnHexagram = hexagram);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('📖 I-Ging Orakel'),
        backgroundColor: const Color(0xFF6A1B9A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _throwCoins,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E24AA),
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Münzen werfen'),
            ),
            const SizedBox(height: 24),
            if (_drawnHexagram != null)
              Expanded(
                child: Card(
                  color: const Color(0xFF1A1A2E),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_drawnHexagram!.number}. ${_drawnHexagram!.name}',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _drawnHexagram!.chineseName,
                            style: const TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          Text('Bedeutung: ${_drawnHexagram!.meaning}', style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 12),
                          Text('Urteil: ${_drawnHexagram!.judgment}', style: const TextStyle(color: Colors.white60)),
                          const SizedBox(height: 12),
                          Text('Bild: ${_drawnHexagram!.image}', style: const TextStyle(color: Colors.white60)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
