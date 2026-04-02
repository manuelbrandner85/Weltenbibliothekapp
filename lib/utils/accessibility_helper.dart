/// ♿ ACCESSIBILITY HELPERS
/// Accessibility support utilities
/// 
/// Features:
/// - Semantic labels
/// - Screen reader support
/// - Keyboard navigation
/// - High contrast mode
/// - Font scaling
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class AccessibilityHelper {
  /// Wrap widget with Semantics
  static Widget semantic({
    required Widget child,
    String? label,
    String? hint,
    String? value,
    bool? button,
    bool? header,
    bool? link,
    bool? image,
    bool? focused,
    bool? selected,
    bool? enabled,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      value: value,
      button: button,
      header: header,
      link: link,
      image: image,
      focused: focused,
      selected: selected,
      enabled: enabled,
      onTap: onTap,
      onLongPress: onLongPress,
      child: child,
    );
  }
  
  /// Make text accessible
  static Widget accessibleText(
    String text, {
    TextStyle? style,
    String? semanticLabel,
    TextAlign? textAlign,
  }) {
    return Semantics(
      label: semanticLabel ?? text,
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
      ),
    );
  }
  
  /// Make button accessible
  static Widget accessibleButton({
    required Widget child,
    required VoidCallback onPressed,
    required String semanticLabel,
    String? tooltip,
    bool enabled = true,
  }) {
    Widget button = Tooltip(
      message: tooltip ?? semanticLabel,
      child: child,
    );
    
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      onTap: enabled ? onPressed : null,
      child: button,
    );
  }
  
  /// Make icon accessible
  static Widget accessibleIcon(
    IconData icon, {
    String? semanticLabel,
    double? size,
    Color? color,
  }) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: Icon(
          icon,
          size: size,
          color: color,
        ),
      ),
    );
  }
  
  /// Make image accessible
  static Widget accessibleImage(
    String url, {
    required String semanticLabel,
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return Semantics(
      image: true,
      label: semanticLabel,
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        semanticLabel: semanticLabel,
      ),
    );
  }
  
  /// Make list accessible
  static Widget accessibleList({
    required List<Widget> children,
    required String semanticLabel,
    ScrollController? controller,
  }) {
    return Semantics(
      label: semanticLabel,
      child: ListView(
        controller: controller,
        children: children,
      ),
    );
  }
  
  /// Screen reader announcement
  static void announce(String message) {
    SemanticsService.announce(
      message,
      TextDirection.ltr,
    );
  }
  
  /// Check if screen reader is enabled
  static bool isScreenReaderEnabled(BuildContext context) {
    return MediaQuery.of(context).accessibleNavigation;
  }
  
  /// Check if high contrast mode is enabled
  static bool isHighContrastEnabled(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }
  
  /// Get text scale factor
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor;
  }
  
  /// Accessible card
  static Widget accessibleCard({
    required Widget child,
    required String semanticLabel,
    VoidCallback? onTap,
    EdgeInsets? padding,
  }) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
  
  /// Accessible navigation
  static Widget accessibleBottomNav({
    required List<BottomNavigationBarItem> items,
    required int currentIndex,
    required ValueChanged<int> onTap,
  }) {
    return Semantics(
      container: true,
      label: 'Navigation',
      child: BottomNavigationBar(
        items: items,
        currentIndex: currentIndex,
        onTap: onTap,
      ),
    );
  }
  
  /// Focus node helper
  static FocusNode createFocusNode() {
    return FocusNode();
  }
  
  /// Request focus
  static void requestFocus(BuildContext context, FocusNode node) {
    FocusScope.of(context).requestFocus(node);
  }
  
  /// Accessible text field
  static Widget accessibleTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    VoidCallback? onSubmitted,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      textField: true,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        onSubmitted: onSubmitted != null ? (_) => onSubmitted() : null,
      ),
    );
  }
  
  /// Minimum touch target size (44x44 per iOS/Android guidelines)
  static const double minTouchTargetSize = 44.0;
  
  /// Ensure minimum touch target
  static Widget ensureTouchTarget({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: minTouchTargetSize,
      height: minTouchTargetSize,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              child: Center(child: child),
            )
          : Center(child: child),
    );
  }
  
  /// High contrast colors
  static Color getContrastColor(
    BuildContext context,
    Color normalColor,
    Color highContrastColor,
  ) {
    return isHighContrastEnabled(context) ? highContrastColor : normalColor;
  }
}
