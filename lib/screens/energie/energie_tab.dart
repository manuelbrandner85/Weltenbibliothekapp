import 'package:flutter/material.dart';

/// Type-safe model for the ENERGIE world's bottom-tab navigation.
///
/// This enum is the single source of truth for tab order, labels and icons.
/// Previously the tab indices were passed around as bare magic numbers
/// (e.g. `onSwitchTab(1)` to reach Spirit), which silently broke whenever the
/// tab order changed. Centralising the mapping here keeps the floating nav
/// bar, the tab-content list and every in-content deep link in sync.
///
/// The declaration order MUST match the `tabs` list and the floating nav
/// items in `energie_world_screen.dart` -- `EnergieTab.values[i]` and the
/// built-in `.index` getter are what wire the two together.
enum EnergieTab {
  home(Icons.home, 'Home'),
  spirit(Icons.self_improvement, 'Spirit'),
  community(Icons.people, 'Community'),
  karte(Icons.map, 'Karte'),
  wissen(Icons.menu_book, 'Wissen'),
  videos(Icons.play_circle_outline, 'Videos');

  const EnergieTab(this.icon, this.label);

  /// Icon shown in the floating bottom navigation.
  final IconData icon;

  /// German label shown in the floating bottom navigation.
  final String label;

  /// Resolves a bottom-nav [index] to its [EnergieTab].
  ///
  /// Out-of-range values fall back to [EnergieTab.home] so navigation can
  /// never crash on a stale or corrupt index.
  static EnergieTab fromIndex(int index) =>
      isValidIndex(index) ? EnergieTab.values[index] : EnergieTab.home;

  /// `true` when [index] maps to a real tab.
  static bool isValidIndex(int index) =>
      index >= 0 && index < EnergieTab.values.length;
}
