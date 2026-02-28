import 'package:flutter/material.dart';
import '../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0

class DivinationSuiteScreen extends StatefulWidget {
  const DivinationSuiteScreen({super.key});

  @override
  State<DivinationSuiteScreen> createState() => _DivinationSuiteScreenState();
}

class _DivinationSuiteScreenState extends State<DivinationSuiteScreen> {
  String _selectedOracle = 'tarot';
  String? _result;

  void _performDivination() {
    setState(() {
      switch (_selectedOracle) {
        case 'tarot':
          _result = '🎴 Der Magier: Du hast die Macht, deine Realität zu manifestieren.';
          break;
        case 'iching':
          _result = '☯️ Hexagramm 1 - Das Schöpferische: Starke schöpferische Energie.';
          break;
        case 'runes':
          _result = 'ᚱ Raidho - Die Reise: Eine wichtige Reise oder Veränderung steht bevor.';
          break;
        case 'pendulum':
          _result = '⚖️ Ja - Deine Frage wurde mit Ja beantwortet.';
          break;
      }
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                    const Expanded(child: Text('DIVINATION SUITE', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2))),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  children: [
                    _buildOracleChip('tarot', '🎴 Tarot'),
                    _buildOracleChip('iching', '☯️ I-Ging'),
                    _buildOracleChip('runes', 'ᚱ Runen'),
                    _buildOracleChip('pendulum', '⚖️ Pendel'),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_result == null) ...[
                        Text(_getOracleEmoji(), style: const TextStyle(fontSize: 80)),
                        const SizedBox(height: 24),
                        Text(_getOracleName(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 48),
                        ElevatedButton(
                          onPressed: _performDivination,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9C27B0),
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                          ),
                          child: const Text('Orakel befragen', style: TextStyle(fontSize: 18)),
                        ),
                      ] else ...[
                        Container(
                          margin: const EdgeInsets.all(24),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Text(_result!, style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5), textAlign: TextAlign.center),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () => setState(() => _result = null),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.2)),
                                child: const Text('Erneut befragen'),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildOracleChip(String id, String label) {
    final isActive = _selectedOracle == id;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedOracle = id;
        _result = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isActive ? const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)]) : null,
          color: isActive ? null : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? const Color(0xFF9C27B0) : Colors.white24),
        ),
        child: Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  String _getOracleEmoji() {
    switch (_selectedOracle) {
      case 'tarot': return '🎴';
      case 'iching': return '☯️';
      case 'runes': return 'ᚱ';
      case 'pendulum': return '⚖️';
      default: return '🔮';
    }
  }

  String _getOracleName() {
    switch (_selectedOracle) {
      case 'tarot': return 'Tarot';
      case 'iching': return 'I-Ging';
      case 'runes': return 'Runen';
      case 'pendulum': return 'Pendel';
      default: return 'Orakel';
    }
  }
}
