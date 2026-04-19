import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 🎨 PREMIUM CARD COMPONENT
/// 
/// Wiederverwendbare Card mit Glassmorphism-Design

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final LinearGradient? gradient;
  final double? borderRadius;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  
  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.gradient,
    this.borderRadius,
    this.boxShadow,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final widget = Container(
      padding: padding ?? const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: color,
        gradient: gradient ?? LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.radiusMedium),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: boxShadow ?? AppTheme.shadowMedium,
      ),
      child: child,
    );
    
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: widget,
      );
    }
    
    return widget;
  }
}

/// 🔘 PREMIUM BUTTON
/// 
/// Wiederverwendbarer Button mit verschiedenen Stilen

enum PremiumButtonStyle { primary, secondary, outline, text }

class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final PremiumButtonStyle style;
  final Color? color;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  
  const PremiumButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.style = PremiumButtonStyle.primary,
    this.color,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppTheme.materieBlue;
    
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space6,
              vertical: AppTheme.space4,
            ),
            decoration: _getDecoration(buttonColor),
            child: Row(
              mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        style == PremiumButtonStyle.primary ? Colors.white : buttonColor,
                      ),
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: style == PremiumButtonStyle.primary ? Colors.white : buttonColor,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.space2),
                  ],
                  Text(
                    text,
                    style: AppTheme.labelLarge.copyWith(
                      color: style == PremiumButtonStyle.primary ? Colors.white : buttonColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  BoxDecoration _getDecoration(Color color) {
    switch (style) {
      case PremiumButtonStyle.primary:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.9),
              color.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.coloredShadow(color),
        );
      
      case PremiumButtonStyle.secondary:
        return BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        );
      
      case PremiumButtonStyle.outline:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: color, width: 2),
        );
      
      case PremiumButtonStyle.text:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        );
    }
  }
}

/// 🏷️ PREMIUM CHIP
/// 
/// Wiederverwendbarer Chip für Filter, Tags, etc.

class PremiumChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? color;
  final IconData? icon;
  final String? badge;
  
  const PremiumChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.color,
    this.icon,
    this.badge,
  });
  
  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.materieBlue;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space5,
          vertical: AppTheme.space3,
        ),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    chipColor.withValues(alpha: 0.7),
                    chipColor.withValues(alpha: 0.5),
                    chipColor.withValues(alpha: 0.3),
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.08),
                  ],
                ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.3),
            width: isSelected ? 2.5 : 1.8,
          ),
          boxShadow: isSelected ? AppTheme.coloredShadow(chipColor) : AppTheme.shadowSmall,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: AppTheme.space2),
            ],
            Text(
              label,
              style: AppTheme.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppTheme.textPrimary.withValues(alpha: 0.9),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: AppTheme.space2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.5),
                            Colors.white.withValues(alpha: 0.3),
                          ],
                        )
                      : null,
                  color: isSelected ? null : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    color: isSelected 
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  badge!,
                  style: AppTheme.labelSmall.copyWith(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
