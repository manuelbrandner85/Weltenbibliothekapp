import 'package:flutter/widgets.dart';

/// Global key for the app's root [Navigator] (assigned to `MaterialApp.navigatorKey`).
///
/// Lives in its own file so that global overlays mounted via
/// `MaterialApp.builder` — which sit OUTSIDE/above the Navigator in the widget
/// tree (e.g. the floating live-call button) — can push routes. Those widgets
/// cannot use `Navigator.of(context)` because the Navigator is a descendant,
/// not an ancestor, of their context.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
