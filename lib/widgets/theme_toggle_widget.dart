import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/haptic_service.dart';

/// Theme-Toggle-Widget für Settings
class ThemeToggleWidget extends StatefulWidget {
  const ThemeToggleWidget({super.key});

  @override
  State<ThemeToggleWidget> createState() => _ThemeToggleWidgetState();
}

class _ThemeToggleWidgetState extends State<ThemeToggleWidget>
    with SingleTickerProviderStateMixin {
  final ThemeService _themeService = ThemeService();
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    // Listen to theme changes
    _themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleTheme() async {
    HapticService.mediumImpact();
    await _controller.forward();
    await _themeService.toggleTheme();
    await _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeService.isDarkMode;
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  theme.colorScheme.primary.withValues(alpha: 0.2),
                  theme.colorScheme.secondary.withValues(alpha: 0.1),
                ]
              : [
                  theme.colorScheme.primary.withValues(alpha: 0.1),
                  theme.colorScheme.surface,
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _toggleTheme,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon mit Animation
                RotationTransition(
                  turns: _rotationAnimation,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.3),
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDark ? 'Dark Mode' : 'Light Mode',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isDark
                            ? 'Wechsel zu hellem Design'
                            : 'Wechsel zu dunklem Design',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Toggle-Indikator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tippen',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
