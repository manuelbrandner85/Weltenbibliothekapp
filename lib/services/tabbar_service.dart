import 'package:flutter/material.dart';

/// Single definition of one bottom-nav tab in a world dashboard.
///
/// Plain data only (icon + German label) so the tab configuration can be
/// shared between the page list and the floating nav and unit-tested without
/// spinning up the whole widget tree.
@immutable
class WorldTab {
  final IconData icon;
  final String label;

  const WorldTab({required this.icon, required this.label});
}

/// Central source of truth for the world-dashboard bottom navigation.
///
/// The page list and the visible nav items historically lived in two separate
/// literals inside `energie_world_screen.dart`. Whenever one was changed
/// without the other, indexing the page list (`tabs[_currentIndex]`) could
/// throw a `RangeError` and crash the whole world screen. This service keeps
/// the order in one place and exposes [clampIndex] / [isValidIndex] so a stray
/// index can never blow up navigation.
class TabBarService {
  const TabBarService._();

  /// Bottom-nav tabs of the ENERGIE world. Order MUST match the page list
  /// built in `EnergieWorldScreen.build` one-to-one.
  static const List<WorldTab> energieTabs = [
    WorldTab(icon: Icons.home, label: 'Home'),
    WorldTab(icon: Icons.self_improvement, label: 'Spirit'),
    WorldTab(icon: Icons.people, label: 'Community'),
    WorldTab(icon: Icons.map, label: 'Karte'),
    WorldTab(icon: Icons.menu_book, label: 'Wissen'),
    WorldTab(icon: Icons.play_circle_outline, label: 'Videos'),
  ];

  /// Index of the Spirit tab. Used by Home-shortcuts that switch the parent
  /// tab instead of pushing a new screen, so the magic number lives in exactly
  /// one place next to the tab definition it depends on.
  static const int energieSpiritIndex = 1;

  /// Returns true when [index] addresses a tab inside [tabs].
  static bool isValidIndex(int index, List<WorldTab> tabs) =>
      index >= 0 && index < tabs.length;

  /// Clamps [index] into the valid range of [tabs] so indexing the matching
  /// page list can never throw a `RangeError`. Falls back to `0` for an empty
  /// list.
  static int clampIndex(int index, List<WorldTab> tabs) {
    if (tabs.isEmpty) return 0;
    if (index < 0) return 0;
    if (index >= tabs.length) return tabs.length - 1;
    return index;
  }
}
