/// Chakra Meditation Guide Screen
/// Geführte Meditationen für jedes Chakra
library;
import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:flutter/foundation.dart';
import '../../widgets/premium_components.dart';

class ChakraMeditationScreen extends StatefulWidget {
  final String chakraName;
  final Color chakraColor;
  final int chakraLevel;

  const ChakraMeditationScreen({
    super.key,
    required this.chakraName,
    required this.chakraColor,
    required this.chakraLevel,
  });

  @override
  State<ChakraMeditationScreen> createState() => _ChakraMeditationScreenState();
}

class _ChakraMeditationScreenState extends State<ChakraMeditationScreen> {
  bool _isPlaying = false;
  int _currentStep = 0;
  late List<MeditationStep> _steps;

  @override
  void initState() {
    super.initState();
    _steps = _getChakraMeditationSteps(widget.chakraName);
    if (kDebugMode) {
      debugPrint('🧘 Chakra Meditation Screen: ${widget.chakraName}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_getChakraIcon(widget.chakraName)} ${widget.chakraName} Meditation',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.chakraColor.withValues(alpha: 0.3),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Chakra Info Card
              _buildChakraInfoCard(),
              const SizedBox(height: 20),
              
              // Meditation Progress
              _buildMeditationProgress(),
              const SizedBox(height: 20),
              
              // Current Step
              _buildCurrentStep(),
              const SizedBox(height: 20),
              
              // Controls
              _buildControls(),
              const SizedBox(height: 20),
              
              // All Steps Preview
              _buildAllSteps(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChakraInfoCard() {
    return PremiumCard(
      gradient: LinearGradient(
        colors: [
          widget.chakraColor.withValues(alpha: 0.3),
          widget.chakraColor.withValues(alpha: 0.1),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Chakra Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.chakraColor.withValues(alpha: 0.8),
                    widget.chakraColor.withValues(alpha: 0.4),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.chakraColor.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _getChakraIcon(widget.chakraName),
                  style: const TextStyle(fontSize: 50),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Chakra Name
            Text(
              widget.chakraName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            
            // Description
            Text(
              _getChakraDescription(widget.chakraName),
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Current Level
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Aktuelles Level: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${widget.chakraLevel}/10',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.chakraColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeditationProgress() {
    final progress = _currentStep / _steps.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Meditation Fortschritt',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '${_currentStep + 1}/${_steps.length}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(widget.chakraColor),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    final step = _steps[_currentStep];
    
    return PremiumCard(
      gradient: LinearGradient(
        colors: [
          widget.chakraColor.withValues(alpha: 0.2),
          widget.chakraColor.withValues(alpha: 0.05),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Number & Duration
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Schritt ${_currentStep + 1}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      step.duration,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Step Title
            Text(
              step.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            // Step Instruction
            Text(
              step.instruction,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
            
            if (step.affirmation != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.chakraColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.chakraColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💫 Affirmation',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"${step.affirmation}"',
                      style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous Button
        IconButton(
          onPressed: _currentStep > 0
              ? () => setState(() => _currentStep--)
              : null,
          icon: const Icon(Icons.skip_previous),
          color: Colors.white,
          disabledColor: Colors.white.withValues(alpha: 0.3),
          iconSize: 36,
        ),
        const SizedBox(width: 20),
        
        // Play/Pause Button
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.chakraColor,
                widget.chakraColor.withValues(alpha: 0.7),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.chakraColor.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 3,
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => setState(() => _isPlaying = !_isPlaying),
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            color: Colors.white,
            iconSize: 36,
          ),
        ),
        const SizedBox(width: 20),
        
        // Next Button
        IconButton(
          onPressed: _currentStep < _steps.length - 1
              ? () => setState(() => _currentStep++)
              : null,
          icon: const Icon(Icons.skip_next),
          color: Colors.white,
          disabledColor: Colors.white.withValues(alpha: 0.3),
          iconSize: 36,
        ),
      ],
    );
  }

  Widget _buildAllSteps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alle Schritte',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ..._steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isActive = index == _currentStep;
          
          return GestureDetector(
            onTap: () => setState(() => _currentStep = index),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive
                    ? widget.chakraColor.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? widget.chakraColor.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.1),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? widget.chakraColor
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.duration,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Icon(
                      Icons.play_circle_filled,
                      color: widget.chakraColor,
                      size: 24,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  String _getChakraIcon(String chakra) {
    switch (chakra) {
      case 'Wurzel':
        return '🔴';
      case 'Sakral':
        return '🟠';
      case 'Solarplexus':
        return '🟡';
      case 'Herz':
        return '💚';
      case 'Hals':
        return '🔵';
      case 'Stirn':
        return '🟣';
      case 'Krone':
        return '⚪';
      default:
        return '⭕';
    }
  }

  String _getChakraDescription(String chakra) {
    switch (chakra) {
      case 'Wurzel':
        return 'Erdung, Stabilität, Sicherheit und Überleben';
      case 'Sakral':
        return 'Kreativität, Emotionen, Sexualität und Beziehungen';
      case 'Solarplexus':
        return 'Willenskraft, Selbstvertrauen, Persönliche Macht';
      case 'Herz':
        return 'Liebe, Mitgefühl, Harmonie und Verbindung';
      case 'Hals':
        return 'Kommunikation, Wahrheit, Selbstausdruck';
      case 'Stirn':
        return 'Intuition, Weisheit, Inneres Sehen';
      case 'Krone':
        return 'Spiritualität, Bewusstsein, Einheit';
      default:
        return '';
    }
  }

  List<MeditationStep> _getChakraMeditationSteps(String chakra) {
    // Gemeinsame Schritte für alle Chakren
    final commonSteps = [
      MeditationStep(
        title: 'Vorbereitung',
        instruction: 'Setze dich bequem hin, schließe deine Augen und atme tief ein und aus. Finde eine Position, in der du für die nächsten Minuten entspannt bleiben kannst.',
        duration: '2 Min',
      ),
      MeditationStep(
        title: 'Atemübung',
        instruction: 'Atme langsam und tief durch die Nase ein, halte den Atem kurz an, und atme vollständig durch den Mund aus. Wiederhole dies 5 Mal.',
        duration: '2 Min',
      ),
    ];

    // Chakra-spezifische Schritte
    final chakraSteps = _getSpecificChakraSteps(chakra);

    // Abschluss-Schritte
    final closingSteps = [
      MeditationStep(
        title: 'Integration',
        instruction: 'Spüre die Energie in deinem $chakra-Chakra. Nimm wahr, wie sich dein Körper anfühlt. Verweile noch einen Moment in dieser Energie.',
        duration: '2 Min',
      ),
      MeditationStep(
        title: 'Abschluss',
        instruction: 'Atme noch einmal tief ein und aus. Wenn du bereit bist, öffne langsam deine Augen und kehre zurück ins Hier und Jetzt.',
        duration: '1 Min',
        affirmation: 'Ich bin im Einklang mit meiner inneren Kraft.',
      ),
    ];

    return [...commonSteps, ...chakraSteps, ...closingSteps];
  }

  List<MeditationStep> _getSpecificChakraSteps(String chakra) {
    switch (chakra) {
      case 'Wurzel':
        return [
          MeditationStep(
            title: 'Erdung spüren',
            instruction: 'Visualisiere rote Energie an der Basis deiner Wirbelsäule. Stelle dir vor, wie Wurzeln aus deinem Körper wachsen und tief in die Erde reichen. Du bist fest verwurzelt und sicher.',
            duration: '3 Min',
            affirmation: 'Ich bin sicher, geerdet und versorgt.',
          ),
          MeditationStep(
            title: 'Stabilität stärken',
            instruction: 'Fühle die Verbindung zur Erde. Mit jedem Atemzug wirst du stabiler und geerdeter. Du bist hier, du bist sicher, du gehörst hierher.',
            duration: '3 Min',
          ),
        ];
      case 'Sakral':
        return [
          MeditationStep(
            title: 'Kreativität aktivieren',
            instruction: 'Visualisiere orange Energie unterhalb deines Bauchnabels. Spüre die fließende, kreative Energie in deinem Beckenbereich. Erlaube dir, deine Gefühle zu fühlen.',
            duration: '3 Min',
            affirmation: 'Ich bin kreativ, leidenschaftlich und im Fluss des Lebens.',
          ),
          MeditationStep(
            title: 'Emotionale Balance',
            instruction: 'Atme orange Licht in dein Sakralchakra. Mit jedem Atemzug löst sich emotionale Blockade. Du erlaubst dir, deine Emotionen frei zu fühlen und auszudrücken.',
            duration: '3 Min',
          ),
        ];
      case 'Solarplexus':
        return [
          MeditationStep(
            title: 'Persönliche Macht',
            instruction: 'Visualisiere gelbes Licht in deinem Solarplexus. Spüre deine innere Kraft und Willenskraft. Du bist selbstbewusst und kraftvoll.',
            duration: '3 Min',
            affirmation: 'Ich bin kraftvoll, selbstbewusst und handle aus meiner Mitte.',
          ),
          MeditationStep(
            title: 'Selbstvertrauen stärken',
            instruction: 'Mit jedem Atemzug wächst dein Selbstvertrauen. Du traust dir zu, deine Ziele zu erreichen. Deine innere Sonne strahlt hell.',
            duration: '3 Min',
          ),
        ];
      case 'Herz':
        return [
          MeditationStep(
            title: 'Liebe öffnen',
            instruction: 'Visualisiere grünes oder rosa Licht in deinem Herzbereich. Öffne dein Herz für Liebe – für dich selbst und andere. Spüre Mitgefühl und Wärme.',
            duration: '3 Min',
            affirmation: 'Ich liebe mich selbst bedingungslos und teile diese Liebe mit der Welt.',
          ),
          MeditationStep(
            title: 'Vergebung praktizieren',
            instruction: 'Atme Liebe in dein Herz. Mit jedem Ausatmen lässt du Groll und Verletzungen los. Du vergibst dir selbst und anderen. Dein Herz ist frei.',
            duration: '3 Min',
          ),
        ];
      case 'Hals':
        return [
          MeditationStep(
            title: 'Wahrheit ausdrücken',
            instruction: 'Visualisiere blaues Licht in deinem Hals. Spüre, wie sich dein Hals öffnet und frei wird. Du hast das Recht, deine Wahrheit auszusprechen.',
            duration: '3 Min',
            affirmation: 'Ich spreche meine Wahrheit klar, authentisch und liebevoll.',
          ),
          MeditationStep(
            title: 'Kommunikation reinigen',
            instruction: 'Mit jedem Atemzug reinigst du deine Kommunikation. Alte Worte, die unausgesprochen blieben, werden freigesetzt. Du kommunizierst authentisch.',
            duration: '3 Min',
          ),
        ];
      case 'Stirn':
        return [
          MeditationStep(
            title: 'Drittes Auge aktivieren',
            instruction: 'Visualisiere indigoblaues Licht zwischen deinen Augenbrauen. Spüre, wie sich dein inneres Auge öffnet. Deine Intuition wird klarer.',
            duration: '3 Min',
            affirmation: 'Ich vertraue meiner Intuition und meiner inneren Weisheit.',
          ),
          MeditationStep(
            title: 'Inneres Sehen',
            instruction: 'Erllaube Bildern, Gefühlen oder Einsichten zu kommen. Bewerte sie nicht, beobachte sie nur. Dein inneres Wissen zeigt sich.',
            duration: '3 Min',
          ),
        ];
      case 'Krone':
        return [
          MeditationStep(
            title: 'Spirituelle Verbindung',
            instruction: 'Visualisiere violettes oder weißes Licht am Scheitel deines Kopfes. Spüre die Verbindung zum Universum, zum Göttlichen, zu allem was ist.',
            duration: '3 Min',
            affirmation: 'Ich bin verbunden mit dem Universum und Teil des großen Ganzen.',
          ),
          MeditationStep(
            title: 'Einheit erfahren',
            instruction: 'Löse alle Grenzen auf. Du bist reines Bewusstsein, eins mit allem. Erfahre die Stille, den Frieden, die Einheit.',
            duration: '3 Min',
          ),
        ];
      default:
        return [];
    }
  }
}

class MeditationStep {
  final String title;
  final String instruction;
  final String duration;
  final String? affirmation;

  MeditationStep({
    required this.title,
    required this.instruction,
    required this.duration,
    this.affirmation,
  });
}
