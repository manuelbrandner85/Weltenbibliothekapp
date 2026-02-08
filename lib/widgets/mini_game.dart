import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';

/// v5.40 - 3.1: Portal Defense Mini-Game
/// Tap invading particles before they reach the portal!
class PortalDefenseMiniGame extends StatefulWidget {
  final VoidCallback onExit;
  final Function(int score) onGameOver;

  const PortalDefenseMiniGame({
    super.key,
    required this.onExit,
    required this.onGameOver,
  });

  @override
  State<PortalDefenseMiniGame> createState() => _PortalDefenseMiniGameState();
}

class _PortalDefenseMiniGameState extends State<PortalDefenseMiniGame> {
  int _score = 0;
  int _lives = 3;
  bool _gameStarted = false;
  bool _gameOver = false;
  int _countdown = 3;
  Timer? _gameTimer;
  Timer? _spawnTimer;
  final List<InvadingParticle> _invaders = [];
  
  @override
  void initState() {
    super.initState();
    _startCountdown();
  }
  
  void _startCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        _startGame();
      }
    });
  }
  
  void _startGame() {
    setState(() {
      _gameStarted = true;
      _countdown = 0;
    });
    
    // Spawn invaders every 1.5 seconds
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!_gameOver) {
        _spawnInvader();
      } else {
        timer.cancel();
      }
    });
    
    // Update invaders position
    _gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_gameOver) {
        setState(() {
          for (var invader in _invaders) {
            invader.update();
            
            // Check if invader reached center (game over condition)
            if (invader.progress >= 1.0 && !invader.destroyed) {
              invader.destroyed = true;
              _lives--;
              HapticService.heavyImpact();
              
              if (_lives <= 0) {
                _endGame();
              }
            }
          }
          
          // Remove destroyed invaders
          _invaders.removeWhere((invader) => invader.destroyed && invader.progress >= 1.2);
        });
      } else {
        timer.cancel();
      }
    });
  }
  
  void _spawnInvader() {
    setState(() {
      _invaders.add(InvadingParticle());
    });
  }
  
  void _tapInvader(InvadingParticle invader) {
    if (!invader.destroyed && invader.progress < 1.0) {
      setState(() {
        invader.destroyed = true;
        _score += 10;
      });
      HapticService.lightImpact();
      SoundService.playGameSound('hit');
    }
  }
  
  void _endGame() {
    setState(() {
      _gameOver = true;
    });
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    
    // Check for achievement
    if (_score >= 100) {
      // Achievement will be unlocked by parent
    }
    
    widget.onGameOver(_score);
  }
  
  @override
  void dispose() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.95),
      child: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Color(0xFF1A237E),
                  Color(0xFF000000),
                ],
              ),
            ),
          ),
          
          // Countdown
          if (!_gameStarted && _countdown > 0)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '🎮 PORTAL DEFENSE',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Tippe auf eindringende Partikel!',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    '$_countdown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 96,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          
          // Game Area
          if (_gameStarted && !_gameOver)
            ..._invaders.map((invader) {
              final size = MediaQuery.of(context).size;
              final centerX = size.width / 2;
              final centerY = size.height / 2;
              
              final x = centerX + (invader.targetX - centerX) * (1 - invader.progress);
              final y = centerY + (invader.targetY - centerY) * (1 - invader.progress);
              
              return Positioned(
                left: x - 20,
                top: y - 20,
                child: GestureDetector(
                  onTap: () => _tapInvader(invader),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: invader.destroyed
                          ? Colors.transparent
                          : const Color(0xFFFF5722).withValues(alpha: 0.8),
                      boxShadow: invader.destroyed
                          ? []
                          : [
                              BoxShadow(
                                color: const Color(0xFFFF5722).withValues(alpha: 0.6),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                    ),
                    child: invader.destroyed
                        ? const Icon(Icons.close, color: Color(0xFF4CAF50), size: 30)
                        : const Icon(Icons.dangerous, color: Colors.white, size: 24),
                  ),
                ),
              );
            }),
          
          // Portal Center (target)
          if (_gameStarted)
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFF2196F3),
                      Color(0xFF9C27B0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.5),
                      blurRadius: 40,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          
          // HUD (Score & Lives)
          if (_gameStarted && !_gameOver)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Score
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFFD700)),
                          ),
                          child: Text(
                            'Score: $_score',
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Lives
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFF5722)),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                'Leben: ',
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                              ...List.generate(
                                _lives,
                                (index) => const Icon(
                                  Icons.favorite,
                                  color: Color(0xFFFF5722),
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          
          // Game Over
          if (_gameOver)
            Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFD700), width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🎮 GAME OVER',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Final Score: $_score',
                      style: const TextStyle(color: Colors.white, fontSize: 24),
                    ),
                    const SizedBox(height: 12),
                    if (_score >= 100)
                      const Text(
                        '🏆 Achievement freigeschaltet!',
                        style: TextStyle(color: Color(0xFF4CAF50), fontSize: 16),
                      ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: widget.onExit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: const Text(
                        'Zurück zum Portal',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Exit Button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  onPressed: widget.onExit,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Invading Particle class
class InvadingParticle {
  late double targetX;
  late double targetY;
  double progress = 0.0;
  bool destroyed = false;
  
  InvadingParticle() {
    // Random spawn position on screen edge
    final random = math.Random();
    final edge = random.nextInt(4);
    
    switch (edge) {
      case 0: // Top
        targetX = random.nextDouble() * 400;
        targetY = 0;
        break;
      case 1: // Right
        targetX = 400;
        targetY = random.nextDouble() * 800;
        break;
      case 2: // Bottom
        targetX = random.nextDouble() * 400;
        targetY = 800;
        break;
      case 3: // Left
        targetX = 0;
        targetY = random.nextDouble() * 800;
        break;
    }
  }
  
  void update() {
    if (!destroyed) {
      progress += 0.01; // Move towards center
    } else {
      progress += 0.05; // Quick fade out
    }
  }
}
