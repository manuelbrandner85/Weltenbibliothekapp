import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../../widgets/animations/wb_tap_scale.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/branch_boss_test_service.dart'; // 👑 I3 Boss-Test
import '../../services/gamification_service.dart';
import '../../services/xp_retry_queue.dart';
import '../../services/new_unlock_tracker.dart';
import '../../services/storage_service.dart';
import '../../services/unified_profile_service.dart';
import '../../services/ursprung_service.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/responsive_web_container.dart';
import 'ursprung_lesson_screen.dart';

/// 🌀 URSPRUNG Modules Screen
///
/// Zeigt alle 25 Ursprung-Module (U-QC-01 … U-QC-25) gruppiert in 5 Branches
/// aus dem CIA-Gateway-Material.
///
/// Jede Branche ist eine ExpansionTile mit:
/// - Branch-Icon + Titel + Fortschrittsbalken
/// - 5 ListTiles (eine pro Modul) mit Status-Icon
///   ✅ completed | 🔓 available | 🔒 locked
/// Tap auf freigeschaltetes Modul → UrsprungLessonScreen.
class UrsprungModulesScreen extends StatefulWidget {
  const UrsprungModulesScreen({super.key});

  @override
  State<UrsprungModulesScreen> createState() => _UrsprungModulesScreenState();
}

class _UrsprungModulesScreenState extends State<UrsprungModulesScreen> {
  // Ursprung-Akzent: Cyan/Teal (matching world_color)
  static const _gold = Color(0xFF00D4AA);
  static const _goldDim = Color(0xFF008B72);
  static const _bgBlack = Color(0xFF050510);
  static const _surface = Color(0xFF001A14);

  bool _loading = true;
  String? _error;
  Map<String, List<Map<String, dynamic>>> _branches = {};
  int _totalCount = 0;
  int _completedCount = 0;

  // V1-Pattern: Modul-Suche
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  // 2026-06-07: 200ms Debounce -- bei 25+ Modulen filterte jeder Tastendruck
  // sofort und liess die UI laggy wirken. Jetzt erst nach kurzer Pause.
  Timer? _searchDebounce;

  // A3: neu freigeschaltete Module (seit letztem Besuch)
  Set<String> _newModuleCodes = {};

  // Branch-Code → Icon. Codes wie in der DB (snake_case).
  static const Map<String, IconData> _branchIcons = {
    'gateway_foundation': Icons.foundation,
    'focus_levels': Icons.tune,
    'energy_tools': Icons.bolt,
    'patterning_manifestation': Icons.auto_fix_high,
    'remote_viewing': Icons.remove_red_eye,
  };

  // Lesbare Anzeige-Titel pro Branch-Code.
  static const Map<String, String> _branchTitles = {
    'gateway_foundation': 'Gateway-Fundament',
    'focus_levels': 'Focus-Level',
    'energy_tools': 'Energie-Werkzeuge',
    'patterning_manifestation': 'Patterning & Manifestation',
    'remote_viewing': 'Remote Viewing',
  };

  // Reihenfolge der 5 Branches (Lernpfad-Progression).
  static const List<String> _branchOrder = [
    'gateway_foundation',
    'focus_levels',
    'energy_tools',
    'patterning_manifestation',
    'remote_viewing',
  ];

  @override
  void initState() {
    super.initState();
    _fetchModules();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> _searchResults() {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final results = <Map<String, dynamic>>[];
    for (final branch in _branchOrder) {
      for (final m in _branches[branch] ?? const []) {
        final title = (m['title'] as String?)?.toLowerCase() ?? '';
        final code = (m['module_code'] as String?)?.toLowerCase() ?? '';
        final sub = (m['subtitle'] as String?)?.toLowerCase() ?? '';
        if (title.contains(q) || code.contains(q) || sub.contains(q)) {
          results.add(m);
        }
      }
    }
    return results;
  }

  Map<String, dynamic>? _nextModule() {
    for (final branch in _branchOrder) {
      for (final m in _branches[branch] ?? const []) {
        final completed = m['is_completed'] == true;
        final unlocked = m['is_unlocked'] == true;
        if (unlocked && !completed) return m;
      }
    }
    return null;
  }

  Future<void> _fetchModules() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Fall back to UnifiedProfileService.userId when no Supabase Auth
      // session exists (InvisibleAuth users) -- otherwise admin module
      // overrides never load for app-only profiles.
      final user = Supabase.instance.client.auth.currentUser;
      final userId = user?.id ?? UnifiedProfileService.instance.userId;
      // Direct-Supabase Pfad (Worker-Bypass) — funktioniert auch bei
      // Cloudflare-Worker-Quota-Outage.
      final data = await UrsprungService.fetchModules(userId: userId);
      final rawBranches = (data['branches'] as Map?) ?? {};
      final mapped = <String, List<Map<String, dynamic>>>{};
      for (final b in _branchOrder) {
        final list = (rawBranches[b] as List?) ?? const [];
        mapped[b] = list
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
      setState(() {
        _branches = mapped;
        _totalCount = (data['total'] as num?)?.toInt() ?? 0;
        _completedCount = (data['completed'] as num?)?.toInt() ?? 0;
        _loading = false;
      });
      await _detectNewUnlocks(mapped);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// A3: neu freigeschaltete, nicht abgeschlossene Module erkennen.
  Future<void> _detectNewUnlocks(
      Map<String, List<Map<String, dynamic>>> mapped) async {
    final unlockedCodes = <String>[];
    for (final list in mapped.values) {
      for (final m in list) {
        if (m['is_unlocked'] == true && m['is_completed'] != true) {
          final code = m['module_code'] as String?;
          if (code != null) unlockedCodes.add(code);
        }
      }
    }
    final fresh = <String>{};
    for (final code in unlockedCodes) {
      if (await NewUnlockTracker.instance.isNew('ursprung', code)) {
        fresh.add(code);
      }
    }
    await NewUnlockTracker.instance.markSeen('ursprung', unlockedCodes);
    if (mounted && fresh.isNotEmpty) {
      setState(() => _newModuleCodes = fresh);
      // B1: Sofort-Feedback -- zeigt welche Module gerade freigeschaltet wurden.
      final titles = <String>[];
      for (final list in mapped.values) {
        for (final m in list) {
          if (fresh.contains(m['module_code'])) {
            titles.add(
                (m['title'] as String?) ?? (m['module_code'] as String? ?? ''));
          }
        }
      }
      if (titles.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('🔓 Neu freigeschaltet: ${titles.join(', ')}'),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 4),
        ));
      }
    }
  }

  void _openLesson(Map<String, dynamic> module) {
    final code = module['module_code'] as String?;
    if (code == null) return;
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => UrsprungLessonScreen(moduleCode: code),
          ),
        )
        .then((_) => _fetchModules());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: _bgBlack,
      appBar: WBGlassAppBar(
        world: WBWorld.ursprung,
        title: 'URSPRUNG MODULE',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _gold),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _gold),
            tooltip: 'Neu laden',
            onPressed: _fetchModules,
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: _gold,
                  strokeWidth: 2,
                ),
              )
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                color: _gold.withValues(alpha: 0.6), size: 48),
            const SizedBox(height: 16),
            Text(
              'Module konnten nicht geladen werden',
              style: TextStyle(
                color: _gold,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _fetchModules,
              icon: const Icon(Icons.refresh, color: _gold),
              label: const Text('Erneut versuchen',
                  style: TextStyle(color: _gold)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _gold.withValues(alpha: 0.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final percent = _totalCount > 0 ? _completedCount / _totalCount : 0.0;
    final next = _nextModule();
    final results = _searchResults();
    // Responsive: bound the reading column on tablet/desktop so module tiles
    // stay readable instead of stretching edge-to-edge (phones unchanged).
    return ResponsiveWebContainer(
      variant: WebContainerVariant.compact,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 100, 16, 32),
        children: [
          // Overall progress card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _surface,
                  _gold.withValues(alpha: 0.08),
                  _bgBlack,
                ],
              ),
              border: Border.all(color: _gold.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_stories, color: _gold, size: 22),
                    const SizedBox(width: 10),
                    const Text(
                      'GESAMTFORTSCHRITT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4.0,
                        color: _gold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$_completedCount / $_totalCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 8,
                    backgroundColor: _gold.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation(_gold),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${(percent * 100).round()}% des Gateway-Pfads beschritten',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                if (next != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openLesson(next),
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: Text(
                        'Weitermachen: ${next['title'] ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: _bgBlack,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Modul-Suche
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            onChanged: (v) {
              // 200ms Debounce: Filter setzt erst wenn der User kurz pausiert.
              _searchDebounce?.cancel();
              _searchDebounce = Timer(const Duration(milliseconds: 200), () {
                if (mounted) setState(() => _searchQuery = v);
              });
            },
            decoration: InputDecoration(
              hintText: 'Modul suchen (Code oder Stichwort)',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
              prefixIcon:
                  Icon(Icons.search, color: _gold.withValues(alpha: 0.7)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close,
                          color: _gold.withValues(alpha: 0.7)),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _gold.withValues(alpha: 0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _gold.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _gold.withValues(alpha: 0.6)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_searchQuery.trim().isNotEmpty) ...[
            if (results.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Kein Modul gefunden für "$_searchQuery"',
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                ),
              )
            else
              ...results.map(_buildModuleTile),
          ] else
            // 5 Branches
            for (final branchName in _branchOrder)
              _buildBranchTile(branchName, _branches[branchName] ?? const []),
        ],
      ),
    );
  }

  Widget _buildBranchTile(
      String branchName, List<Map<String, dynamic>> modules) {
    final icon = _branchIcons[branchName] ?? Icons.folder;
    final completed = modules.where((m) => m['is_completed'] == true).length;
    final total = modules.length;
    final percent = total > 0 ? completed / total : 0.0;
    final allDone = total > 0 && completed == total;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: _surface.withValues(alpha: 0.55),
        border: Border.all(
          color: allDone
              ? _gold.withValues(alpha: 0.5)
              : _gold.withValues(alpha: 0.18),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          unselectedWidgetColor: _gold,
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: _gold),
        ),
        child: ExpansionTile(
          // Alle Branches per Default offen — sonst sieht der User nur 6 Header
          // mit Zähler "0/5" und glaubt, 25 Module fehlen.
          initiallyExpanded: true,
          maintainState: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          iconColor: _gold,
          collapsedIconColor: _gold,
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _gold.withValues(alpha: 0.3),
                  _gold.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(color: _gold.withValues(alpha: 0.45)),
            ),
            child: Icon(icon, color: _gold, size: 22),
          ),
          title: Text(
            _branchTitles[branchName] ?? branchName,
            style: const TextStyle(
              color: _gold,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 5,
                          backgroundColor: _gold.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation(
                            allDone ? _gold : _goldDim,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$completed/$total',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          children: [
            // Statt eigener BranchPath-Widget (gibt's für Ursprung noch nicht):
            // schlichte vertikale Liste der Modul-Tiles.
            for (final m in modules) _buildModuleTile(m),
            // 👑 Boss-Test-Button erscheint wenn alle Module der Branch geschafft.
            if (allDone)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _BossTestCard(
                  branch: branchName,
                  accent: _gold,
                  onTap: () => _startBossTest(branchName),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleTile(Map<String, dynamic> module) {
    final isCompleted = module['is_completed'] == true;
    final isUnlocked = module['is_unlocked'] == true;
    final isBoss = module['is_boss_module'] == true;
    final title = (module['title'] as String?) ?? '?';
    final subtitle = (module['subtitle'] as String?) ?? '';
    final code = (module['module_code'] as String?) ?? '';
    final xp = (module['xp_reward'] as num?)?.toInt() ?? 50;

    IconData statusIcon;
    Color statusColor;
    String statusLabel;
    if (isCompleted) {
      statusIcon = Icons.check_circle;
      statusColor = const Color(0xFF4CAF50);
      statusLabel = 'Abgeschlossen';
    } else if (isUnlocked) {
      statusIcon = Icons.lock_open;
      statusColor = _gold;
      statusLabel = 'Verfügbar';
    } else {
      statusIcon = Icons.lock;
      statusColor = Colors.white.withValues(alpha: 0.3);
      statusLabel = 'Gesperrt';
    }

    // WbTapScale: Scale-on-Press + Haptik; gesperrte Module sind deaktiviert.
    return WbTapScale(
      enabled: isUnlocked || isCompleted,
      onTap: () => _openLesson(module),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color:
              isCompleted ? _gold.withValues(alpha: 0.06) : Colors.transparent,
          border: Border.all(
            color: isBoss
                ? _gold.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.05),
            width: isBoss ? 1.2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          code,
                          style: const TextStyle(
                            color: _gold,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      if (isBoss) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              _gold,
                              _gold.withValues(alpha: 0.7),
                            ]),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'BOSS',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                      // A3: NEU-Badge fuer frisch freigeschaltete Module
                      if (_newModuleCodes.contains(code)) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D4AA),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '✨ NEU',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        '+$xp XP',
                        style: TextStyle(
                          color: _gold.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: TextStyle(
                      color: isUnlocked || isCompleted
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            if (isUnlocked || isCompleted)
              Icon(Icons.chevron_right,
                  color: _gold.withValues(alpha: 0.6), size: 20),
          ],
        ),
      ),
    );
  }
}

extension _BossTestActions on _UrsprungModulesScreenState {
  Future<void> _startBossTest(String branch) async {
    final test = await BranchBossTestService.instance.forBranch(branch);
    if (!mounted) return;
    if (test == null || test.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('🔒 Boss-Test für „$branch" noch nicht verfügbar'),
        backgroundColor: const Color(0xFF008B72),
      ));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _BossTestScreen(test: test, branch: branch),
      ),
    );
  }
}

class _BossTestCard extends StatelessWidget {
  final String branch;
  final Color accent;
  final VoidCallback onTap;
  const _BossTestCard({
    required this.branch,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: 0.28),
                accent.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(color: accent, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.35),
                blurRadius: 14,
              ),
            ],
          ),
          child: Row(
            children: [
              const Text('👑', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BOSS-TEST',
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Alle 5 Module geschafft — beweise dein Wissen!',
                      style: TextStyle(color: Colors.white, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Boss-Test-Screen ────────────────────────────────────────────────
class _BossTestScreen extends StatefulWidget {
  final BossTest test;
  final String branch;
  const _BossTestScreen({required this.test, required this.branch});

  @override
  State<_BossTestScreen> createState() => _BossTestScreenState();
}

class _BossTestScreenState extends State<_BossTestScreen> {
  static const _gold = Color(0xFF00D4AA);
  final Map<int, int> _answers = {};
  bool _submitted = false;
  BossAttemptResult? _result;

  Future<void> _submit() async {
    if (_answers.length < widget.test.questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bitte alle Fragen beantworten.'),
        backgroundColor: Color(0xFF008B72),
      ));
      return;
    }
    final ordered = List<int>.generate(
      widget.test.questions.length,
      (i) => _answers[i] ?? -1,
    );
    final result =
        BranchBossTestService.instance.evaluate(widget.test, ordered);
    setState(() {
      _submitted = true;
      _result = result;
    });
    final storage = StorageService();
    final userId = (storage.getMaterieProfile()?.userId ??
        storage.getEnergieProfile()?.userId ??
        'anon');
    await BranchBossTestService.instance.recordAttempt(
      userId: userId,
      branch: widget.branch,
      result: result,
    );
    if (result.passed && mounted) {
      // XP-Reward via GamificationService. Bei Fehler in die Retry-Queue
      // schreiben und User informieren -- vorher still verloren.
      try {
        await GamificationService().addXp(
          'ursprung',
          widget.test.xpReward,
          reason: 'boss_test_${widget.branch}',
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('ursprung_modules_screen: XP-Sync fehlgeschlagen -> $e');
        }
        await XpRetryQueue.enqueue(
          world: 'ursprung',
          xp: widget.test.xpReward,
          reason: 'boss_test_${widget.branch}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '⚠️ XP-Sync fehlgeschlagen. Werden beim nächsten Login nachgeholt.'),
              backgroundColor: Colors.orange.shade800,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.test.title,
            style: const TextStyle(color: _gold, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: _gold),
      ),
      body: _submitted
          ? _buildResult()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (widget.test.description != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      widget.test.description!,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                for (var i = 0; i < widget.test.questions.length; i++)
                  _buildQuestion(i, widget.test.questions[i]),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Abgeben',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuestion(int i, BossQuestion q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF001A14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frage ${i + 1}/${widget.test.questions.length}',
            style: TextStyle(
              color: _gold.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(q.question,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 12),
          for (var j = 0; j < q.options.length; j++)
            _buildOption(i, j, q.options[j]),
        ],
      ),
    );
  }

  Widget _buildOption(int qIdx, int optIdx, String label) {
    final selected = _answers[qIdx] == optIdx;
    return GestureDetector(
      onTap: () => setState(() => _answers[qIdx] = optIdx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? _gold.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _gold : Colors.white.withValues(alpha: 0.08),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? _gold : Colors.white38,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontSize: 13,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final r = _result!;
    final passed = r.passed;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(passed ? '👑' : '🗝️', style: const TextStyle(fontSize: 96)),
            const SizedBox(height: 18),
            Text(
              passed ? 'BOSS BESIEGT' : 'Noch nicht durch',
              style: TextStyle(
                color: passed ? _gold : Colors.white70,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${r.correctCount} von ${r.totalCount} richtig (${r.scorePct}%)',
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            if (passed) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _gold),
                ),
                child: Text(
                  '+${widget.test.xpReward} XP',
                  style: TextStyle(
                    color: _gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 36),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(passed),
              style: ElevatedButton.styleFrom(
                backgroundColor: passed ? _gold : Colors.white12,
                foregroundColor: passed ? Colors.black : Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(passed ? 'Weiter' : 'Nochmal versuchen'),
            ),
          ],
        ),
      ),
    );
  }
}
