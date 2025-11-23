import 'package:flutter/material.dart';

/// 📐 Zentrales Spacing System
/// 
/// Alle Abstände an EINER Stelle definiert für:
/// - Konsistentes Layout-Grid
/// - Vorhersagbare Abstände
/// - Responsive Design
/// 
/// Best Practice 2024: 8px Grid System
class AppSpacing {
  // Private Constructor
  AppSpacing._();

  // ═══════════════════════════════════════════════════════════════
  // BASE SPACING - 8px Grid System
  // ═══════════════════════════════════════════════════════════════
  
  static const double xs = 4.0;      // Extra Small
  static const double sm = 8.0;      // Small
  static const double md = 16.0;     // Medium (Standard)
  static const double lg = 24.0;     // Large
  static const double xl = 32.0;     // Extra Large
  static const double xxl = 48.0;    // 2X Large
  static const double xxxl = 64.0;   // 3X Large

  // ═══════════════════════════════════════════════════════════════
  // SIZEDBOX HELPERS - Fertige SizedBoxes
  // ═══════════════════════════════════════════════════════════════
  
  /// Extra Small Vertical Space (4px)
  static const SizedBox vXs = SizedBox(height: xs);
  
  /// Small Vertical Space (8px)
  static const SizedBox vSm = SizedBox(height: sm);
  
  /// Medium Vertical Space (16px) - DEFAULT
  static const SizedBox vMd = SizedBox(height: md);
  
  /// Large Vertical Space (24px)
  static const SizedBox vLg = SizedBox(height: lg);
  
  /// Extra Large Vertical Space (32px)
  static const SizedBox vXl = SizedBox(height: xl);
  
  /// 2X Large Vertical Space (48px)
  static const SizedBox vXxl = SizedBox(height: xxl);

  /// Extra Small Horizontal Space (4px)
  static const SizedBox hXs = SizedBox(width: xs);
  
  /// Small Horizontal Space (8px)
  static const SizedBox hSm = SizedBox(width: sm);
  
  /// Medium Horizontal Space (16px) - DEFAULT
  static const SizedBox hMd = SizedBox(width: md);
  
  /// Large Horizontal Space (24px)
  static const SizedBox hLg = SizedBox(width: lg);
  
  /// Extra Large Horizontal Space (32px)
  static const SizedBox hXl = SizedBox(width: xl);

  // ═══════════════════════════════════════════════════════════════
  // EDGEINSETS HELPERS - Fertige Paddings
  // ═══════════════════════════════════════════════════════════════
  
  /// All Sides - Extra Small (4px)
  static const EdgeInsets allXs = EdgeInsets.all(xs);
  
  /// All Sides - Small (8px)
  static const EdgeInsets allSm = EdgeInsets.all(sm);
  
  /// All Sides - Medium (16px) - DEFAULT
  static const EdgeInsets allMd = EdgeInsets.all(md);
  
  /// All Sides - Large (24px)
  static const EdgeInsets allLg = EdgeInsets.all(lg);
  
  /// All Sides - Extra Large (32px)
  static const EdgeInsets allXl = EdgeInsets.all(xl);

  /// Horizontal - Small (8px)
  static const EdgeInsets horizSm = EdgeInsets.symmetric(horizontal: sm);
  
  /// Horizontal - Medium (16px)
  static const EdgeInsets horizMd = EdgeInsets.symmetric(horizontal: md);
  
  /// Horizontal - Large (24px)
  static const EdgeInsets horizLg = EdgeInsets.symmetric(horizontal: lg);

  /// Vertical - Small (8px)
  static const EdgeInsets vertSm = EdgeInsets.symmetric(vertical: sm);
  
  /// Vertical - Medium (16px)
  static const EdgeInsets vertMd = EdgeInsets.symmetric(vertical: md);
  
  /// Vertical - Large (24px)
  static const EdgeInsets vertLg = EdgeInsets.symmetric(vertical: lg);

  // ═══════════════════════════════════════════════════════════════
  // BORDER RADIUS - Abrundungen
  // ═══════════════════════════════════════════════════════════════
  
  /// Small Radius (8px)
  static const double radiusSm = 8.0;
  
  /// Medium Radius (12px)
  static const double radiusMd = 12.0;
  
  /// Large Radius (16px)
  static const double radiusLg = 16.0;
  
  /// Extra Large Radius (24px)
  static const double radiusXl = 24.0;
  
  /// Pill/Capsule Radius (999px)
  static const double radiusPill = 999.0;

  /// BorderRadius Small
  static BorderRadius get borderRadiusSm => BorderRadius.circular(radiusSm);
  
  /// BorderRadius Medium
  static BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);
  
  /// BorderRadius Large
  static BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);
  
  /// BorderRadius Extra Large
  static BorderRadius get borderRadiusXl => BorderRadius.circular(radiusXl);
  
  /// BorderRadius Pill
  static BorderRadius get borderRadiusPill => BorderRadius.circular(radiusPill);

  // ═══════════════════════════════════════════════════════════════
  // ICON SIZES
  // ═══════════════════════════════════════════════════════════════
  
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;
}
