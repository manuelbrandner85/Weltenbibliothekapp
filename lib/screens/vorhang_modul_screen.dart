import 'package:flutter/material.dart';

import '../config/wb_design.dart';
import '../core/responsive.dart';
import 'vorhang/vorhang_modules_screen.dart';
import 'vorhang/vorhang_page_route.dart';

// ═══════════════════════════════════════════════════════════════════════════
// VORHANG MODUL SCREEN — TabBar-Grundstruktur (Issue #418)
// "Curtain Gold" - DefaultTabController + TabBar mit 3 Lernpfad-Tabs.
//
// Strukturiert die 6 Vorhang-Branches in 3 thematische Tabs
// (Grundlagen / Praxis / Tiefe). Jeder Tab-Inhalt ist in einem eigenen
// Widget gekapselt (Separation of Concerns). Tippen auf eine Branche
// oeffnet den bestehenden VorhangModulesScreen - bestehende Navigation
// bleibt unveraendert.
// ═══════════════════════════════════════════════════════════════════════════

/// Immutable description of a single Vorhang learning branch.
///
/// Plain Dart class (NOT a Dart-3 record) so it compiles cleanly under
/// dart2js for the Flutter Web build (see CLAUDE.md rule #8).
class VorhangModulBranch {
  final String title;
  final String subtitle;
  final IconData icon;

  const VorhangModulBranch({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

/// Tab definition: a title plus the branches grouped under it.
class VorhangModulTab {
  final String label;
  final IconData icon;
  final List<VorhangModulBranch> branches;

  const VorhangModulTab({
    required this.label,
    required this.icon,
    required this.branches,
  });
}

/// The 3-tab structure required by the acceptance criteria. Defined as a
/// top-level constant so it can be reused directly in widget tests.
const List<VorhangModulTab> kVorhangModulTabs = [
  VorhangModulTab(
    label: 'Grundlagen',
    icon: Icons.school_outlined,
    branches: [
      VorhangModulBranch(
        title: 'Machtpsychologie',
        subtitle: 'Wie Einfluss und Autoritaet wirklich entstehen.',
        icon: Icons.psychology,
      ),
      VorhangModulBranch(
        title: 'Manipulationserkennung',
        subtitle: 'Muster durchschauen, bevor sie dich lenken.',
        icon: Icons.shield,
      ),
    ],
  ),
  VorhangModulTab(
    label: 'Praxis',
    icon: Icons.handshake_outlined,
    branches: [
      VorhangModulBranch(
        title: 'Verhandlung & Ueberzeugung',
        subtitle: 'Argumente, die tragen - ohne Druck.',
        icon: Icons.handshake,
      ),
      VorhangModulBranch(
        title: 'Koerpersprache & Nonverbales',
        subtitle: 'Was Haltung, Blick und Stimme verraten.',
        icon: Icons.accessibility_new,
      ),
    ],
  ),
  VorhangModulTab(
    label: 'Tiefe',
    icon: Icons.dark_mode_outlined,
    branches: [
      VorhangModulBranch(
        title: 'Strategisches Denken',
        subtitle: 'Mehrere Zuege vorausplanen.',
        icon: Icons.military_tech,
      ),
      VorhangModulBranch(
        title: 'Schattenarbeit',
        subtitle: 'Die eigenen blinden Flecken integrieren.',
        icon: Icons.dark_mode,
      ),
    ],
  ),
];

/// VORHANG module hub built around a [DefaultTabController] + [TabBar].
///
/// Pure structural scaffold: it groups the existing Vorhang branches into
/// three navigable tabs and links into the existing [VorhangModulesScreen]
/// without altering any existing screen flow.
class VorhangModulScreen extends StatelessWidget {
  const VorhangModulScreen({super.key, this.tabs = kVorhangModulTabs});

  /// Injectable for tests; defaults to the production [kVorhangModulTabs].
  final List<VorhangModulTab> tabs;

  static const Color _gold = WbDesign.vorhangGold;
  static const Color _bgBlack = WbDesign.bgVorhang;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: WbDesign.themeFor(context, 'vorhang'),
      child: DefaultTabController(
        length: tabs.length,
        child: Scaffold(
          backgroundColor: _bgBlack,
          appBar: AppBar(
            backgroundColor: _bgBlack,
            elevation: 0,
            iconTheme: const IconThemeData(color: _gold),
            title: Text(
              'VORHANG MODULE',
              style: TextStyle(
                color: _gold,
                fontWeight: FontWeight.w300,
                fontSize: context.rf(18),
                letterSpacing: 3.0,
              ),
            ),
            bottom: TabBar(
              isScrollable: false,
              labelColor: _gold,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.45),
              indicatorColor: _gold,
              indicatorWeight: 2.5,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: context.rf(13),
              ),
              tabs: [
                for (final tab in tabs)
                  Tab(
                    icon: Icon(tab.icon, size: context.rw(20)),
                    text: tab.label,
                  ),
              ],
            ),
          ),
          body: SafeArea(
            top: false,
            child: TabBarView(
              children: [
                for (final tab in tabs) _VorhangModulTabView(tab: tab),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Content of a single tab: a responsive, scrollable list of branch cards.
///
/// Kept as a dedicated widget so each tab body is self-contained
/// (clean separation of concerns, per the issue's hints).
class _VorhangModulTabView extends StatelessWidget {
  const _VorhangModulTabView({required this.tab});

  final VorhangModulTab tab;

  @override
  Widget build(BuildContext context) {
    final pad = context.rw(16);
    final spacing = context.rw(12);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Single column on phones, two columns on tablets/wide screens.
        // Cards keep their intrinsic height (no fixed aspect ratio), so the
        // layout never overflows on tiny phones or with large system fonts.
        final available = constraints.maxWidth - pad * 2;
        final columns = context.isTablet ? 2 : 1;
        final itemWidth = columns == 1 ? available : (available - spacing) / 2;

        return ListView(
          padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + context.rw(8)),
          children: [
            Text(
              tab.label,
              style: TextStyle(
                color: WbDesign.vorhangGoldLight,
                fontSize: context.rf(22),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: spacing),
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final branch in tab.branches)
                  SizedBox(
                    width: itemWidth,
                    child: _BranchCard(branch: branch),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// A single tappable branch card. Tapping opens the existing modules screen.
class _BranchCard extends StatelessWidget {
  const _BranchCard({required this.branch});

  final VorhangModulBranch branch;

  static const Color _gold = WbDesign.vorhangGold;

  void _openModules(BuildContext context) {
    Navigator.of(
      context,
    ).push(VorhangPageRoute(builder: (_) => const VorhangModulesScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WbDesign.surfaceVorhang,
      borderRadius: BorderRadius.circular(context.rw(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(context.rw(14)),
        onTap: () => _openModules(context),
        child: Container(
          padding: EdgeInsets.all(context.rw(14)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.rw(14)),
            border: Border.all(color: _gold.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.rw(10)),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(context.rw(10)),
                ),
                child: Icon(branch.icon, color: _gold, size: context.rw(22)),
              ),
              SizedBox(width: context.rw(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      branch.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.rf(15),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: context.rw(4)),
                    Text(
                      branch.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: context.rf(12),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: _gold.withValues(alpha: 0.5),
                size: context.rw(20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
