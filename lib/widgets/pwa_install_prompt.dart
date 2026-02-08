/// 📱 WELTENBIBLIOTHEK - PWA INSTALL PROMPT
/// Shows install prompt for Progressive Web App

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/haptic_feedback_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PWAInstallPrompt extends StatefulWidget {
  const PWAInstallPrompt({super.key});

  @override
  State<PWAInstallPrompt> createState() => _PWAInstallPromptState();
}

class _PWAInstallPromptState extends State<PWAInstallPrompt> 
    with SingleTickerProviderStateMixin {
  bool _isVisible = false;
  bool _isDismissed = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  static const String _dismissedKey = 'pwa_install_prompt_dismissed';

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Check if should show prompt
    _checkShouldShow();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkShouldShow() async {
    // Only show on web
    if (!kIsWeb) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getBool(_dismissedKey) ?? false;
      
      if (!dismissed) {
        // Delay showing prompt by 3 seconds
        await Future.delayed(const Duration(seconds: 3));
        
        if (mounted && !_isDismissed) {
          setState(() => _isVisible = true);
          _animationController.forward();
        }
      }
    } catch (e) {
      debugPrint('❌ PWA Install Prompt: Error checking dismissed state - $e');
    }
  }

  Future<void> _dismissPrompt() async {
    await HapticFeedbackService().light();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dismissedKey, true);
      
      _animationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isVisible = false;
            _isDismissed = true;
          });
        }
      });
    } catch (e) {
      debugPrint('❌ PWA Install Prompt: Error dismissing - $e');
    }
  }

  Future<void> _installPWA() async {
    await HapticFeedbackService().success();
    
    // Show installation instructions
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.install_mobile, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'App installieren',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'So installierst du die Weltenbibliothek:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Chrome/Android
              _buildInstructionItem(
                icon: Icons.android,
                title: 'Chrome (Android)',
                steps: [
                  'Tippe auf Menü (⋮)',
                  'Wähle "App installieren"',
                  'Bestätige die Installation',
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Safari/iOS
              _buildInstructionItem(
                icon: Icons.apple,
                title: 'Safari (iOS)',
                steps: [
                  'Tippe auf Teilen-Icon (□↑)',
                  'Scrolle zu "Zum Home-Bildschirm"',
                  'Tippe auf "Hinzufügen"',
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _dismissPrompt();
              },
              child: const Text(
                'Verstanden',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildInstructionItem({
    required IconData icon,
    required String title,
    required List<String> steps,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...steps.map((step) => Padding(
          padding: const EdgeInsets.only(left: 28, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '• ',
                style: TextStyle(color: Colors.white60),
              ),
              Expanded(
                child: Text(
                  step,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible || _isDismissed) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom: 80,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF667eea),
                  Color(0xFF764ba2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.install_mobile,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'App installieren',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Nutze die App wie eine native App',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _installPWA,
                      icon: const Icon(Icons.download, color: Colors.white),
                      tooltip: 'Installieren',
                    ),
                    IconButton(
                      onPressed: _dismissPrompt,
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      tooltip: 'Schließen',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
