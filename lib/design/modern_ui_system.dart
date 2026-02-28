import 'package:flutter/material.dart';
import 'dart:ui';

/// 🎨 Modern UI Design System
/// Polished, professional design components für Weltenbibliothek
class ModernUISystem {
  // ═══════════════════════════════════════════════════════════
  // COLOR PALETTE - REFINED & PROFESSIONAL
  // ═══════════════════════════════════════════════════════════
  
  // Primary Colors - Deep & Rich
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color primaryPurple = Color(0xFF7B1FA2);
  static const Color primaryTeal = Color(0xFF00897B);
  
  // Gradient Colors
  static const Color gradientStart = Color(0xFF0D47A1);
  static const Color gradientEnd = Color(0xFF7B1FA2);
  
  // Accent Colors
  static const Color accentGold = Color(0xFFFFB300);
  static const Color accentCyan = Color(0xFF00BCD4);
  static const Color accentPink = Color(0xFFE91E63);
  
  // Surface Colors - Dark Mode Optimized
  static const Color surfaceDark = Color(0xFF121212);
  static const Color surfaceDarkElevated = Color(0xFF1E1E1E);
  static const Color surfaceDarkHighlight = Color(0xFF2C2C2C);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textTertiary = Color(0xFF707070);
  
  // Status Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  static const Color infoBlue = Color(0xFF2196F3);
  
  // ═══════════════════════════════════════════════════════════
  // GRADIENTS - SMOOTH & ELEGANT
  // ═══════════════════════════════════════════════════════════
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient materieGradient = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient energieGradient = LinearGradient(
    colors: [Color(0xFF7B1FA2), Color(0xFFE91E63)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFB300)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ═══════════════════════════════════════════════════════════
  // SHADOWS - SOFT & DEPTH
  // ═══════════════════════════════════════════════════════════
  
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get strongShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: primaryBlue.withValues(alpha: 0.4),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];
  
  // ═══════════════════════════════════════════════════════════
  // BORDER RADIUS - MODERN & CONSISTENT
  // ═══════════════════════════════════════════════════════════
  
  static const BorderRadius radiusSmall = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusMedium = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusLarge = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusXLarge = BorderRadius.all(Radius.circular(24));
  static const BorderRadius radiusRound = BorderRadius.all(Radius.circular(999));
  
  // ═══════════════════════════════════════════════════════════
  // MODERN CARD WIDGET
  // ═══════════════════════════════════════════════════════════
  
  static Widget modernCard({
    required Widget child,
    EdgeInsets? padding,
    Color? color,
    Gradient? gradient,
    VoidCallback? onTap,
    bool withShadow = true,
    bool withGlow = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? surfaceDarkElevated) : null,
        gradient: gradient,
        borderRadius: radiusMedium,
        boxShadow: withGlow ? glowShadow : (withShadow ? softShadow : null),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radiusMedium,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // GLASSMORPHISM EFFECT
  // ═══════════════════════════════════════════════════════════
  
  static Widget glassCard({
    required Widget child,
    EdgeInsets? padding,
    double blur = 10,
    double opacity = 0.1,
  }) {
    return ClipRRect(
      borderRadius: radiusMedium,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: radiusMedium,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // MODERN BUTTON STYLES
  // ═══════════════════════════════════════════════════════════
  
  static Widget primaryButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
    double? width,
  }) {
    return SizedBox(
      width: width,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: radiusMedium,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
  
  static Widget outlinedButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    Color? color,
  }) {
    final buttonColor = color ?? primaryBlue;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: buttonColor,
        side: BorderSide(color: buttonColor, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: radiusMedium,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // MODERN INPUT FIELD
  // ═══════════════════════════════════════════════════════════
  
  static Widget modernTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      style: const TextStyle(color: textPrimary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: textSecondary) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: surfaceDarkElevated,
        border: OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: BorderSide(color: textTertiary.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textTertiary),
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // ANIMATED GRADIENT BACKGROUND
  // ═══════════════════════════════════════════════════════════
  
  static Widget animatedGradientBackground({
    required Widget child,
    List<Color>? colors,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors ?? [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // SHIMMER LOADING EFFECT
  // ═══════════════════════════════════════════════════════════
  
  static Widget shimmerLoading({
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: surfaceDarkElevated,
        borderRadius: borderRadius ?? radiusMedium,
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // BADGE WIDGET
  // ═══════════════════════════════════════════════════════════
  
  static Widget badge({
    required String text,
    Color? color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? primaryBlue).withValues(alpha: 0.2),
        borderRadius: radiusRound,
        border: Border.all(
          color: color ?? primaryBlue,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color ?? primaryBlue),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color ?? primaryBlue,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
