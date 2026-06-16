/// 🎭 VORHANG Lernmodul-Uebersicht — pure logic
///
/// Flutter-free helper for the "A-Z" overview tab on the Vorhang modules
/// screen. Keeping the alphabetical sort + search filter here (instead of
/// inline in the widget) makes the behaviour unit-testable without pumping
/// the whole screen.
///
/// Note: plain `Map`/`List` types only — no Dart-3 named records (would
/// crash dart2js, see CLAUDE.md).
library;

class VorhangModuleOverview {
  const VorhangModuleOverview._();

  /// Flattens the per-branch module map into a single flat list.
  ///
  /// [order] pins the branch iteration order; branches missing from [order]
  /// are appended afterwards so no module is silently dropped.
  static List<Map<String, dynamic>> flatten(
    Map<String, List<Map<String, dynamic>>> branches, {
    List<String> order = const [],
  }) {
    final seen = <String>{};
    final out = <Map<String, dynamic>>[];
    for (final key in order) {
      if (seen.add(key)) out.addAll(branches[key] ?? const []);
    }
    for (final entry in branches.entries) {
      if (seen.add(entry.key)) out.addAll(entry.value);
    }
    return out;
  }

  /// True if [module] matches [query] across title, module_code or subtitle.
  /// An empty/whitespace query matches everything.
  static bool matches(Map<String, dynamic> module, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final title = (module['title'] as String?)?.toLowerCase() ?? '';
    final code = (module['module_code'] as String?)?.toLowerCase() ?? '';
    final sub = (module['subtitle'] as String?)?.toLowerCase() ?? '';
    return title.contains(q) || code.contains(q) || sub.contains(q);
  }

  /// All modules sorted A-Z by title (case-insensitive), optionally filtered
  /// by [query]. Equal titles fall back to module_code for a deterministic,
  /// stable order.
  static List<Map<String, dynamic>> sortedAndFiltered(
    Map<String, List<Map<String, dynamic>>> branches, {
    List<String> order = const [],
    String query = '',
  }) {
    final filtered = flatten(
      branches,
      order: order,
    ).where((m) => matches(m, query)).toList();
    filtered.sort((a, b) {
      final ta = ((a['title'] as String?) ?? '').toLowerCase();
      final tb = ((b['title'] as String?) ?? '').toLowerCase();
      final cmp = ta.compareTo(tb);
      if (cmp != 0) return cmp;
      final ca = (a['module_code'] as String?) ?? '';
      final cb = (b['module_code'] as String?) ?? '';
      return ca.compareTo(cb);
    });
    return filtered;
  }
}
