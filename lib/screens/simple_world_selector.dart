import 'package:flutter/material.dart';
import 'materie_world_wrapper.dart';
import 'energie_world_wrapper.dart';

/// Einfacher Welten-Selector ohne komplexe Animationen (für Debugging)
class SimpleWorldSelector extends StatelessWidget {
  const SimpleWorldSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              const Text(
                'DUAL REALMS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Wähle deine Welt',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 60),
              
              // MATERIE Button
              _buildWorldButton(
                context,
                'MATERIE',
                'Verschwörungen & Recherche',
                Colors.blue,
                const MaterieWorldWrapper(),
              ),
              
              const SizedBox(height: 30),
              
              // ENERGIE Button
              _buildWorldButton(
                context,
                'ENERGIE',
                'Bewusstsein & Spiritualität',
                Colors.purple,
                const EnergieWorldWrapper(),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildWorldButton(
    BuildContext context,
    String title,
    String subtitle,
    Color color,
    Widget destination,
  ) {
    return GestureDetector(
      onTap: () {
        debugPrint('🌐 Navigiere zu $title Welt');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      child: Container(
        width: 280,
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.3),
              color.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
