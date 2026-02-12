import 'package:flutter/material.dart';
import 'propaganda_detector_screen.dart';
import 'image_forensics_screen.dart';
import 'power_network_mapper_screen.dart';
import 'event_predictor_screen.dart';
import '../../widgets/universal_edit_wrapper.dart';
import '../../services/universal_content_service.dart';

/// 🔬 MATERIE TOOLS - PROFESSIONELLE ANALYSE-WERKZEUGE
class MaterieToolsScreen extends StatelessWidget {
  const MaterieToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D47A1), // Dunkelblau
              Color(0xFF1A1A1A), // Dunkelgrau
              Color(0xFF000000), // Schwarz
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MATERIE TOOLS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Professionelle Analyse-Werkzeuge',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Tools Grid
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Row 1
                      Row(
                        children: [
                          Expanded(
                            child: _buildToolCard(
                              context,
                              title: 'Propaganda\nDetector',
                              subtitle: 'KI-Bias-Analyse',
                              icon: Icons.psychology,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
                              ),
                              badge: 'KI',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PropagandaDetectorScreen()),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildToolCard(
                              context,
                              title: 'Image\nForensics',
                              subtitle: 'Manipulations-Check',
                              icon: Icons.image_search,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                              ),
                              badge: 'NEU',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ImageForensicsScreen()),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Row 2
                      Row(
                        children: [
                          Expanded(
                            child: _buildToolCard(
                              context,
                              title: 'Power\nNetwork',
                              subtitle: 'Netzwerk-Analyse',
                              icon: Icons.hub,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                              ),
                              badge: null,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PowerNetworkMapperScreen()),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildToolCard(
                              context,
                              title: 'Event\nPredictor',
                              subtitle: 'Trend-Vorhersage',
                              icon: Icons.trending_up,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                              ),
                              badge: 'PRO',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EventPredictorScreen()),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildToolCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Pattern
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                icon,
                size: 120,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  
                  const Spacer(),
                  
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Subtitle
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            
            // Badge
            if (badge != null)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Color(0xFF0D47A1),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
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
