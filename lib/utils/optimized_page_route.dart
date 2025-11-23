import 'package:flutter/material.dart';

/// 🚀 Optimized Page Route für schnellere Navigation
///
/// Features:
/// - Reduzierte Transition-Dauer (150ms statt 300ms)
/// - Fade-Transition statt Slide (smoother auf Low-End-Geräten)
/// - Optimized Rebuild-Verhalten
class OptimizedPageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  final bool _maintainState;
  final Duration _transitionDuration;

  OptimizedPageRoute({
    required this.builder,
    bool maintainState = true,
    Duration transitionDuration = const Duration(milliseconds: 150),
    super.settings,
  })  : _maintainState = maintainState,
        _transitionDuration = transitionDuration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // ✅ FADE TRANSITION: Smoother als Slide, weniger GPU-Last
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      ),
      child: child,
    );
  }

  @override
  bool get maintainState => _maintainState;

  @override
  Duration get transitionDuration => _transitionDuration;
}

/// 🎯 Fast Page Route für sofortige Navigation (kein Animation)
///
/// Verwende für:
/// - Login → Home (nach erfolgreicher Authentifizierung)
/// - Settings → Settings-Detail
/// - Alle Fälle wo Animation störend ist
class InstantPageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  InstantPageRoute({
    required this.builder,
    super.settings,
  });

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child; // No animation
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Duration.zero;
}

/// 📱 Slide Page Route für Modal-Screens (Bottom-to-Top)
///
/// Verwende für:
/// - Modals, Sheets, Dialogs
/// - Detail-Screens mit "Zurück"-Button
class SlidePageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  final SlideDirection direction;

  SlidePageRoute({
    required this.builder,
    this.direction = SlideDirection.bottomToTop,
    super.settings,
  });

  @override
  Color? get barrierColor => Colors.black54;

  @override
  String? get barrierLabel => 'Schließen';

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    Offset beginOffset;
    switch (direction) {
      case SlideDirection.bottomToTop:
        beginOffset = const Offset(0.0, 1.0);
        break;
      case SlideDirection.rightToLeft:
        beginOffset = const Offset(1.0, 0.0);
        break;
      case SlideDirection.leftToRight:
        beginOffset = const Offset(-1.0, 0.0);
        break;
      case SlideDirection.topToBottom:
        beginOffset = const Offset(0.0, -1.0);
        break;
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: beginOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: child,
    );
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);
}

enum SlideDirection {
  bottomToTop,
  rightToLeft,
  leftToRight,
  topToBottom,
}

/// 🎨 Custom Transitions Helper
class NavigationHelper {
  /// Navigate mit Fade-Transition
  static Future<T?> pushFade<T>(BuildContext context, Widget screen) {
    return Navigator.of(context).push<T>(
      OptimizedPageRoute<T>(
        builder: (context) => screen,
      ),
    );
  }

  /// Navigate ohne Animation (sofort)
  static Future<T?> pushInstant<T>(BuildContext context, Widget screen) {
    return Navigator.of(context).push<T>(
      InstantPageRoute<T>(
        builder: (context) => screen,
      ),
    );
  }

  /// Navigate mit Slide-Transition
  static Future<T?> pushSlide<T>(
    BuildContext context,
    Widget screen, {
    SlideDirection direction = SlideDirection.bottomToTop,
  }) {
    return Navigator.of(context).push<T>(
      SlidePageRoute<T>(
        builder: (context) => screen,
        direction: direction,
      ),
    );
  }

  /// Replace mit Fade-Transition
  static Future<T?> replaceFade<T>(BuildContext context, Widget screen) {
    return Navigator.of(context).pushReplacement<T, void>(
      OptimizedPageRoute<T>(
        builder: (context) => screen,
      ),
    );
  }

  /// Replace ohne Animation
  static Future<T?> replaceInstant<T>(BuildContext context, Widget screen) {
    return Navigator.of(context).pushReplacement<T, void>(
      InstantPageRoute<T>(
        builder: (context) => screen,
      ),
    );
  }

  /// Pop bis zur ersten Route mit Fade
  static void popToFirst(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Navigate und entferne alle vorherigen Routes
  static Future<T?> pushAndRemoveAll<T>(BuildContext context, Widget screen) {
    return Navigator.of(context).pushAndRemoveUntil<T>(
      OptimizedPageRoute<T>(
        builder: (context) => screen,
      ),
      (route) => false,
    );
  }
}

/// 🔥 Pre-Warming Helper für schnellere Navigation
///
/// Lädt Screens im Hintergrund vor, sodass Navigation instant ist
class ScreenPreWarmer {
  static final Map<String, Widget> _preWarmedScreens = {};

  /// Screen vorladen
  static void preWarm(String key, Widget screen) {
    _preWarmedScreens[key] = screen;
  }

  /// Pre-Warmed Screen holen
  static Widget? get(String key) {
    return _preWarmedScreens[key];
  }

  /// Pre-Warmed Screen entfernen
  static void clear(String key) {
    _preWarmedScreens.remove(key);
  }

  /// Alle Pre-Warmed Screens entfernen
  static void clearAll() {
    _preWarmedScreens.clear();
  }

  /// Navigate zu Pre-Warmed Screen
  static Future<T?> pushPreWarmed<T>(
    BuildContext context,
    String key,
    Widget fallbackScreen,
  ) {
    final screen = _preWarmedScreens[key] ?? fallbackScreen;
    _preWarmedScreens.remove(key); // Entfernen nach Verwendung
    
    return Navigator.of(context).push<T>(
      OptimizedPageRoute<T>(
        builder: (context) => screen,
      ),
    );
  }
}
