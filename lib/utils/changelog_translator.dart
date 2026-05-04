/// 📝 CHANGELOG TRANSLATOR — macht aus Git-Commits user-freundliche Texte
///
/// **Ziel:** Im Update-Dialog sieht der User NIE einen technischen Commit
/// wie "fix(livekit): coturn relay 3478 → external_ip" sondern lesbares
/// Deutsch wie "Sprach-Anrufe funktionieren in mehr Netzwerken".
///
/// **Funktionsweise:**
///   1. Commit parsen (`type(scope): description`)
///   2. Versuchen einen passenden **Template-Eintrag** zu finden
///      (Match auf Schlüsselwörter in description ODER auf scope-only)
///   3. Wenn kein Template passt: generischer Eintrag pro (type, scope)
///   4. Duplikate gleicher friendly-Text werden zusammengefasst
///   5. Alles was wir nicht zuordnen können wird **weggelassen** (hidden-counter)
///
/// Ergebnis: 3 Kategorien (✨ Neue Funktionen, 🛠️ Verbessert, 🐛 Behobene Probleme)
/// mit jeweils 0-N user-freundlichen Items, NIE technische Sprache.
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

/// ── TEMPLATES ──────────────────────────────────────────────────────────
///
/// Jeder Template-Eintrag matcht auf Schlüsselwörter im Commit
/// (case-insensitive, in description ODER scope) und ersetzt sie mit
/// einem klar formulierten User-Text.
///
/// Reihenfolge: spezifische Patterns zuerst, generische am Ende.
class _Template {
  /// Wenn description ODER scope einen dieser Strings enthält → Match
  final List<String> keywords;

  /// User-freundlicher Text (überschreibt die Original-Description)
  final String friendly;

  /// Bevorzugte Kategorie (überschreibt commit-type-basierte Auswahl)
  /// null = aus commit-type ableiten (feat→features, fix→fixes, sonst improvements)
  final _Category? forceCategory;

  const _Template(this.keywords, this.friendly, [this.forceCategory]);
}

enum _Category { features, improvements, fixes }

const List<_Template> _templates = [
  // ── Sprach-Anrufe / LiveKit ────────────────────────────────────────────
  _Template(
    ['turn', 'coturn', 'symmetric nat', 'cgnat', 'ice'],
    'Sprach-Anrufe funktionieren jetzt auch in eingeschränkten Netzwerken (Firmen-WLAN, Mobilfunk)',
    _Category.improvements,
  ),
  _Template(
    ['timeout', 'verbinden hängt', 'verbinde'],
    'Sprach-Anrufe verbinden zuverlässiger auf langsamen Netzwerken',
    _Category.improvements,
  ),
  _Template(
    ['guest-mode', 'gast-mode', 'guest mode', 'guestid', 'guest-id'],
    'Auch Gäste ohne Konto können dem Sprach-Anruf beitreten',
    _Category.features,
  ),
  _Template(
    ['screen.share', 'bildschirm.teil', 'bildschirm teil'],
    'Bildschirm-Teilen funktioniert stabiler',
    _Category.improvements,
  ),
  _Template(
    ['avatar', 'profilbild'],
    'Profilbilder im Sprach-Anruf werden zuverlässiger angezeigt',
    _Category.improvements,
  ),
  _Template(
    ['hand heben', 'hand-heben', 'hand raise'],
    'Hand-heben-Funktion im Sprach-Anruf',
    _Category.features,
  ),
  _Template(
    ['kamera', 'camera'],
    'Kamera-Steuerung im Sprach-Anruf verbessert',
    _Category.improvements,
  ),
  _Template(
    ['mikrofon', 'microphone', 'mic'],
    'Mikrofon-Steuerung im Sprach-Anruf verbessert',
    _Category.improvements,
  ),
  _Template(
    ['grid', 'tile', 'kachel', 'teilnehmer-grid'],
    'Teilnehmer-Anzeige im Sprach-Anruf — Kacheln springen nicht mehr',
    _Category.improvements,
  ),

  // ── Community ──────────────────────────────────────────────────────────
  _Template(
    ['pill-switcher', 'pill switcher', 'tab-switcher', 'community navigation'],
    'Neue Navigation zwischen Beiträgen und Live-Chat',
    _Category.features,
  ),
  _Template(
    ['beitrag erstell', 'post erstell', 'post-create', 'create-post'],
    'Beiträge erstellen verbessert',
    _Category.improvements,
  ),
  _Template(
    ['like', 'gefällt', 'gefaellt'],
    '"Gefällt mir"-Funktion verbessert',
    _Category.improvements,
  ),
  _Template(
    ['comment', 'kommentar'],
    'Kommentar-Funktion verbessert',
    _Category.improvements,
  ),
  _Template(
    ['empty.state', 'leer-state', 'empty state'],
    'Schönere Anzeige wenn noch keine Beiträge existieren',
    _Category.improvements,
  ),
  _Template(
    ['deutsch', 'german', 'i18n', 'übersetzung', 'uebersetzung'],
    'Vollständig deutsche Bezeichnungen in der App',
    _Category.improvements,
  ),

  // ── Chat ────────────────────────────────────────────────────────────────
  _Template(
    ['realtime chat', 'chat realtime', 'chat-realtime'],
    'Chat aktualisiert sich sofort bei neuen Nachrichten',
    _Category.improvements,
  ),
  _Template(
    ['chat edit', 'edit chat', 'chat-edit', 'nachricht bearbeit'],
    'Chat-Nachrichten bearbeiten',
    _Category.features,
  ),
  _Template(
    ['chat delete', 'delete chat', 'nachricht löschen', 'nachricht loesch'],
    'Chat-Nachrichten löschen',
    _Category.features,
  ),
  _Template(
    ['mention'],
    'Personen im Chat erwähnen (@username)',
    _Category.features,
  ),
  _Template(
    ['emoji', 'reaktion', 'reaction'],
    'Reaktionen auf Chat-Nachrichten',
    _Category.features,
  ),

  // ── Updates / Patches ───────────────────────────────────────────────────
  _Template(
    ['changelog', 'patch-changelog', 'release-notes'],
    'Update-Dialog zeigt was sich geändert hat (in verständlicher Sprache)',
    _Category.improvements,
  ),
  _Template(
    ['ota patch', 'shorebird', 'patch ready', 'patch-ready'],
    'Updates kommen jetzt schneller und automatisch beim App-Start',
    _Category.improvements,
  ),
  _Template(
    ['apk download', 'in-app install'],
    'Neue App-Version direkt in der App herunterladen + installieren',
    _Category.features,
  ),
  _Template(
    ['restart service', 'auto-restart'],
    'App startet sich nach Update automatisch neu',
    _Category.features,
  ),

  // ── Push-Notifications ──────────────────────────────────────────────────
  _Template(
    ['push notification', 'fcm', 'firebase messag', 'background push'],
    'Benachrichtigungen funktionieren auch wenn die App geschlossen ist',
    _Category.improvements,
  ),
  _Template(
    ['push prefs', 'push-pref', 'notification-settings', 'notification settings'],
    'Du kannst jetzt einstellen welche Benachrichtigungen du bekommst',
    _Category.features,
  ),

  // ── Profil / Auth ───────────────────────────────────────────────────────
  _Template(
    ['avatar upload', 'profilbild hochlad', 'avatar-upload'],
    'Profilbild hochladen',
    _Category.features,
  ),
  _Template(
    ['profile sync', 'profil synchron', 'profile-sync'],
    'Profil wird zwischen Geräten synchronisiert',
    _Category.improvements,
  ),
  _Template(
    ['logout', 'sign out', 'abmelden'],
    'Abmelden funktioniert sauberer',
    _Category.improvements,
  ),
  _Template(
    ['login', 'sign in', 'anmelden'],
    'Anmeldung verbessert',
    _Category.improvements,
  ),

  // ── Performance / Stabilität ────────────────────────────────────────────
  _Template(
    ['crash', 'absturz'],
    'Vereinzelte App-Abstürze behoben',
    _Category.fixes,
  ),
  _Template(
    ['memory leak', 'memory-leak', 'speicherleck'],
    'App verbraucht weniger Speicher',
    _Category.improvements,
  ),
  _Template(
    ['performance', 'schneller', 'speed'],
    'App reagiert schneller',
    _Category.improvements,
  ),
  _Template(
    ['offline', 'offline-queue', 'offline-sync'],
    'Aktionen werden auch offline gespeichert und später synchronisiert',
    _Category.improvements,
  ),
  _Template(
    ['connectivity', 'network-error', 'netzwerk-fehler'],
    'Bessere Fehlermeldungen bei Netzwerk-Problemen',
    _Category.improvements,
  ),

  // ── Tools / Werkzeuge ───────────────────────────────────────────────────
  _Template(
    ['kristall', 'crystal'],
    'Kristall-Bibliothek erweitert',
    _Category.improvements,
  ),
  _Template(
    ['meditation', 'astralreise'],
    'Meditations-Tools verbessert',
    _Category.improvements,
  ),
  _Template(
    ['chakra'],
    'Chakra-Scan überarbeitet',
    _Category.improvements,
  ),
  _Template(
    ['gematria', 'numerologie'],
    'Gematria-Rechner verbessert',
    _Category.improvements,
  ),
  _Template(
    ['ufo', 'sichtung'],
    'UFO-Sichtungen-Tool aktualisiert',
    _Category.improvements,
  ),
  _Template(
    ['heilfrequenz', 'frequency'],
    'Heilfrequenz-Tool verbessert',
    _Category.improvements,
  ),

  // ── Karte ───────────────────────────────────────────────────────────────
  _Template(
    ['map', 'karte', 'geopolitik'],
    'Karten-Tab verbessert',
    _Category.improvements,
  ),

  // ── Recherche ───────────────────────────────────────────────────────────
  _Template(
    ['recherche', 'search', 'suche', 'ai search'],
    'KI-Recherche verbessert',
    _Category.improvements,
  ),

  // ── UI / Design ─────────────────────────────────────────────────────────
  _Template(
    ['design-token', 'design tokens', 'wb-design', 'wbdesign'],
    'Einheitliches Design in allen Bereichen',
    _Category.improvements,
  ),
  _Template(
    ['shimmer', 'skeleton', 'loading'],
    'Schönere Lade-Animationen',
    _Category.improvements,
  ),
  _Template(
    ['animation', 'animated', 'animiert'],
    'Flüssigere Animationen',
    _Category.improvements,
  ),
  _Template(
    ['dark mode', 'dark-mode', 'darkmode', 'theme'],
    'Dunkles Design verbessert',
    _Category.improvements,
  ),
];

/// Generische Templates pro (type, scope) wenn kein spezifisches passt.
const Map<String, _GenericTemplate> _genericByScope = {
  // Sprach-Anrufe
  'livekit': _GenericTemplate(
    feat: 'Neue Funktion in den Sprach-Anrufen',
    fix: 'Sprach-Anrufe funktionieren zuverlässiger',
    perf: 'Sprach-Anrufe schneller geworden',
    other: 'Sprach-Anrufe verbessert',
  ),
  'voice': _GenericTemplate(
    feat: 'Neue Funktion in den Sprach-Anrufen',
    fix: 'Sprach-Anrufe funktionieren zuverlässiger',
    other: 'Sprach-Anrufe verbessert',
  ),
  // Chat
  'chat': _GenericTemplate(
    feat: 'Neue Funktion im Chat',
    fix: 'Chat-Probleme behoben',
    other: 'Chat verbessert',
  ),
  'energie-chat': _GenericTemplate(
    feat: 'Neue Funktion im Energie-Chat',
    fix: 'Energie-Chat-Probleme behoben',
    other: 'Energie-Chat verbessert',
  ),
  'materie-chat': _GenericTemplate(
    feat: 'Neue Funktion im Materie-Chat',
    fix: 'Materie-Chat-Probleme behoben',
    other: 'Materie-Chat verbessert',
  ),
  // Community
  'community': _GenericTemplate(
    feat: 'Neue Funktion im Community-Bereich',
    fix: 'Probleme im Community-Bereich behoben',
    other: 'Community-Bereich verbessert',
  ),
  // Profil
  'profile': _GenericTemplate(
    feat: 'Neue Profil-Funktion',
    fix: 'Profil-Probleme behoben',
    other: 'Profil verbessert',
  ),
  'profile-settings': _GenericTemplate(
    feat: 'Neue Profil-Einstellung',
    fix: 'Profil-Einstellungen verbessert',
    other: 'Profil-Einstellungen überarbeitet',
  ),
  // Push
  'push': _GenericTemplate(
    feat: 'Neue Benachrichtigungs-Funktion',
    fix: 'Benachrichtigungen funktionieren zuverlässiger',
    other: 'Benachrichtigungen verbessert',
  ),
  'notifications': _GenericTemplate(
    feat: 'Neue Benachrichtigungs-Funktion',
    fix: 'Benachrichtigungen funktionieren zuverlässiger',
    other: 'Benachrichtigungen verbessert',
  ),
  // Karte
  'karte': _GenericTemplate(
    feat: 'Neue Karten-Funktion',
    fix: 'Karten-Anzeige korrigiert',
    other: 'Karten-Tab verbessert',
  ),
  'map': _GenericTemplate(
    feat: 'Neue Karten-Funktion',
    fix: 'Karten-Anzeige korrigiert',
    other: 'Karten-Tab verbessert',
  ),
  // Recherche
  'recherche': _GenericTemplate(
    feat: 'Neue Recherche-Funktion',
    fix: 'Recherche-Probleme behoben',
    other: 'KI-Recherche verbessert',
  ),
  // Updates
  'update': _GenericTemplate(
    feat: 'Neues bei Updates',
    fix: 'Update-Mechanismus verbessert',
    other: 'App-Updates verbessert',
  ),
  'patch': _GenericTemplate(
    feat: 'Neues bei automatischen Updates',
    fix: 'Auto-Updates verbessert',
    other: 'Auto-Updates verbessert',
  ),
};

class _GenericTemplate {
  final String? feat;
  final String? fix;
  final String? perf;
  final String other;

  const _GenericTemplate({
    this.feat,
    this.fix,
    this.perf,
    required this.other,
  });

  String forType(String type) {
    switch (type) {
      case 'feat':
      case 'feature':
        return feat ?? other;
      case 'fix':
      case 'bugfix':
        return fix ?? other;
      case 'perf':
        return perf ?? other;
      default:
        return other;
    }
  }
}

/// Commit-Typen die KOMPLETT versteckt werden (dev-only, kein User-Mehrwert).
const Set<String> _hiddenTypes = {
  'chore',
  'ci',
  'docs',
  'refactor',
  'build',
  'test',
  'style',
  'revert', // Revert-Commits sind interne Aufräumarbeit
};

FriendlyChangelog parseFriendlyChangelog(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return const FriendlyChangelog(categories: [], hiddenItemsCount: 0);
  }

  final lines = raw
      .split('\n')
      .map((l) => l.trim())
      // Markdown-Bullets / Pfeile / Bullets entfernen damit Match klappt
      .map((l) => l.replaceFirst(RegExp(r'^[-*•→•]\s*'), ''))
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
      // Kein Conventional-Commit-Format → versuchen Pattern-Match auf
      // den ganzen Text. Wenn nichts matcht: verstecken (kein User-Mehrwert).
      final tpl = _findTemplate(line.toLowerCase(), '');
      if (tpl != null) {
        _addToCategory(tpl, 'other', features, improvements, fixes);
      } else {
        hidden++;
      }
      continue;
    }

    final type = m.group(1)!.toLowerCase();
    final scope = m.group(2)?.toLowerCase() ?? '';
    final desc = m.group(3)!;

    // Dev-only Types verstecken
    if (_hiddenTypes.contains(type)) {
      hidden++;
      continue;
    }

    // 1. Spezifischen Template-Match versuchen (Keyword in desc oder scope)
    final tpl = _findTemplate(desc.toLowerCase(), scope);
    if (tpl != null) {
      _addToCategory(tpl, type, features, improvements, fixes);
      continue;
    }

    // 2. Generisches Template pro scope
    final generic = _genericByScope[scope];
    if (generic != null) {
      final friendlyText = generic.forType(type);
      _appendByType(type, friendlyText, features, improvements, fixes);
      continue;
    }

    // 3. Wenn weder spezifisch noch generisch matched → verstecken
    // (User soll keine technischen Texte sehen die wir nicht zuordnen können)
    hidden++;
  }

  // Duplikate entfernen (gleicher Text → 1×)
  final dedupedFeatures = features.toSet().toList();
  final dedupedImprovements = improvements.toSet().toList();
  final dedupedFixes = fixes.toSet().toList();

  // Cap auf 6 Items pro Kategorie damit Dialog nicht endlos lang wird
  List<String> capList(List<String> list, int max) {
    if (list.length <= max) return list;
    final visible = list.take(max).toList();
    visible.add('… und ${list.length - max} weitere Verbesserungen');
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
        emoji: '🛠️',
        title: 'Verbessert',
        color: const Color(0xFFFFD740),
        items: capList(dedupedImprovements, 6),
      ),
      ChangelogCategory(
        emoji: '🐛',
        title: 'Behobene Probleme',
        color: const Color(0xFF40C4FF),
        items: capList(dedupedFixes, 6),
      ),
    ],
  );
}

_Template? _findTemplate(String descLower, String scopeLower) {
  for (final tpl in _templates) {
    for (final kw in tpl.keywords) {
      final kwLower = kw.toLowerCase();
      if (descLower.contains(kwLower) || scopeLower.contains(kwLower)) {
        return tpl;
      }
    }
  }
  return null;
}

void _addToCategory(
  _Template tpl,
  String commitType,
  List<String> features,
  List<String> improvements,
  List<String> fixes,
) {
  final category = tpl.forceCategory ??
      switch (commitType) {
        'feat' || 'feature' => _Category.features,
        'fix' || 'bugfix' => _Category.fixes,
        _ => _Category.improvements,
      };
  switch (category) {
    case _Category.features:
      features.add(tpl.friendly);
    case _Category.improvements:
      improvements.add(tpl.friendly);
    case _Category.fixes:
      fixes.add(tpl.friendly);
  }
}

void _appendByType(
  String type,
  String text,
  List<String> features,
  List<String> improvements,
  List<String> fixes,
) {
  switch (type) {
    case 'feat':
    case 'feature':
      features.add(text);
    case 'fix':
    case 'bugfix':
      fixes.add(text);
    default:
      improvements.add(text);
  }
}
