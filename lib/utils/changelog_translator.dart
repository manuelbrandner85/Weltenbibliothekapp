/// 📝 CHANGELOG TRANSLATOR — macht aus Git-Commits user-freundliche Texte
///
/// Eingabe: Roh-Changelog von Supabase `app_config.patch_changelog`
/// (typisch: `git log v5.39.0..HEAD --oneline`-Format mit Commit-Messages
/// wie `feat(livekit): WB eigene LiveKit-Instanz`)
///
/// Ausgabe: Gruppierte, übersetzte FriendlyChangelog-Struktur:
///   - ✨ Neue Funktionen (1-N Items)
///   - 🛠️ Verbessert (1-N Items)
///   - 🐛 Fehler behoben (1-N Items)
///
/// Filter:
///   - chore, ci, docs, refactor, build, test → versteckt (dev-only)
///   - Bundle-Präfixe (bundle-a, karte-k1, etc.) → versteckt
///   - Duplikate werden zusammengefasst
library;

import 'package:flutter/material.dart';

/// Eine Kategorie von Änderungen für den Update-Dialog.
class ChangelogCategory {
  final String emoji;
  final String title;
  final Color color;
  final List<String> items;

  const ChangelogCategory({
    required this.emoji,
    required this.title,
    required this.color,
    required this.items,
  });

  bool get isEmpty => items.isEmpty;
}

class FriendlyChangelog {
  final List<ChangelogCategory> categories;
  final int hiddenItemsCount; // technische Items die wir versteckt haben

  const FriendlyChangelog({
    required this.categories,
    required this.hiddenItemsCount,
  });

  bool get isEmpty => categories.every((c) => c.isEmpty);

  int get totalItems =>
      categories.fold(0, (sum, c) => sum + c.items.length);
}

/// Übersetzt technische Scope-Namen in user-freundliche Bereiche.
const Map<String, String> _scopeTranslations = {
  // LiveKit / Voice
  'livekit': 'Sprach-Anrufe',
  'livekit-wb': 'Sprach-Anrufe',
  'livekit-ui': 'Sprach-Anruf-Design',
  'voice': 'Sprach-Anrufe',
  // Karte
  'karte': 'Karten-Tab',
  'karte-k1': 'Karten-Tab',
  'karte-k2': 'Karten-Tab',
  'karte-k3': 'Karten-Tab',
  'karte-k4': 'Karten-Tab',
  'map': 'Karten-Tab',
  // Chat
  'chat': 'Chat',
  'energie-chat': 'Energie-Chat',
  'materie-chat': 'Materie-Chat',
  // Community
  'community': 'Community',
  // Profile
  'profile': 'Profil',
  'profile-settings': 'Profil-Einstellungen',
  'avatar': 'Profilbild',
  // Updates
  'update': 'App-Updates',
  'patch': 'OTA-Updates',
  // Auth
  'auth': 'Anmeldung',
  'supabase': 'Cloud-Sync',
  // Notifications
  'push': 'Benachrichtigungen',
  'notifications': 'Benachrichtigungen',
  // Search
  'search': 'Suche',
  'recherche': 'Recherche',
  // Bundle/Audit-Präfixe — komplett verstecken (übersetzt zu leer)
  'bundle-a': '',
  'bundle-b': '',
  'bundle-c': '',
  'bundle-d': '',
  'bundle-cd': '',
  'bundle-bd': '',
  'bundle-d5': '',
  'observability': 'Stabilität',
  'edge-fn': 'Server-Funktionen',
};

/// Commit-Typen die KOMPLETT versteckt werden (dev-only).
const Set<String> _hiddenTypes = {
  'chore',
  'ci',
  'docs',
  'refactor',
  'build',
  'test',
  'style',
};

FriendlyChangelog parseFriendlyChangelog(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return const FriendlyChangelog(categories: [], hiddenItemsCount: 0);
  }

  final lines = raw
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  final features = <String>[];
  final improvements = <String>[];
  final fixes = <String>[];
  int hidden = 0;

  for (final line in lines) {
    // Pattern: `type(scope): description` oder `type: description`
    final m = RegExp(r'^(\w+)(?:\(([^)]*)\))?:\s*(.+)$').firstMatch(line);
    if (m == null) {
      // Kein Conventional-Commit-Format → einfacher Eintrag
      improvements.add(_capitalize(line));
      continue;
    }

    final type = m.group(1)!.toLowerCase();
    final scope = m.group(2)?.toLowerCase();
    final desc = m.group(3)!;

    // Dev-only Types verstecken
    if (_hiddenTypes.contains(type)) {
      hidden++;
      continue;
    }

    // Scope übersetzen
    final scopeLabel = _translateScope(scope);

    // Beschreibung säubern
    final cleanDesc = _cleanDescription(desc);
    if (cleanDesc.isEmpty) {
      hidden++;
      continue;
    }

    final friendlyText = scopeLabel.isEmpty
        ? _capitalize(cleanDesc)
        : '$scopeLabel: ${_capitalize(cleanDesc)}';

    switch (type) {
      case 'feat':
      case 'feature':
        features.add(friendlyText);
        break;
      case 'fix':
      case 'bugfix':
        fixes.add(friendlyText);
        break;
      case 'perf':
      case 'security':
        improvements.add(friendlyText);
        break;
      default:
        improvements.add(friendlyText);
    }
  }

  // Duplikate entfernen (gleicher Text → 1×)
  final dedupedFeatures = features.toSet().toList();
  final dedupedImprovements = improvements.toSet().toList();
  final dedupedFixes = fixes.toSet().toList();

  // Ggf. zu "+N weitere" zusammenfassen wenn > 5 in einer Kategorie
  List<String> capList(List<String> list, int max) {
    if (list.length <= max) return list;
    final visible = list.take(max).toList();
    visible.add('… und ${list.length - max} weitere');
    return visible;
  }

  return FriendlyChangelog(
    hiddenItemsCount: hidden,
    categories: [
      ChangelogCategory(
        emoji: '✨',
        title: 'Neue Funktionen',
        color: const Color(0xFF69F0AE),
        items: capList(dedupedFeatures, 6),
      ),
      ChangelogCategory(
        emoji: '🐛',
        title: 'Behobene Probleme',
        color: const Color(0xFF40C4FF),
        items: capList(dedupedFixes, 6),
      ),
      ChangelogCategory(
        emoji: '🛠️',
        title: 'Verbessert',
        color: const Color(0xFFFFD740),
        items: capList(dedupedImprovements, 4),
      ),
    ],
  );
}

String _translateScope(String? scope) {
  if (scope == null || scope.isEmpty) return '';
  return _scopeTranslations[scope] ?? '';
}

String _cleanDescription(String desc) {
  // Entferne dev-Markierungen wie "(siehe X)", "Fixes #123", etc.
  String cleaned = desc;
  cleaned = cleaned.replaceAll(RegExp(r'\(siehe [^)]+\)'), '');
  cleaned = cleaned.replaceAll(RegExp(r'Fixes #\d+'), '');
  cleaned = cleaned.replaceAll(RegExp(r'Closes #\d+'), '');
  cleaned = cleaned.replaceAll(RegExp(r'\bPR #\d+\b'), '');
  // Entferne führende Bindestriche/Pfeile
  cleaned = cleaned.replaceFirst(RegExp(r'^[-—→]\s*'), '');
  return cleaned.trim();
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
