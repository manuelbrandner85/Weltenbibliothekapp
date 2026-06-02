import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './guild_challenge_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🛡️ GUILD DETAIL SCREEN — Vollständige Gilde-Detailansicht (AUFGABE 8C)
// Tabs: Mitglieder | Challenges
// Beitreten / Verlassen / Challenge-Erstellen für Anführer
// ═══════════════════════════════════════════════════════════════════════════

class GuildDetailScreen extends StatefulWidget {
  final String guildId;

  const GuildDetailScreen({super.key, required this.guildId});

  @override
  State<GuildDetailScreen> createState() => _GuildDetailScreenState();
}

class _GuildDetailScreenState extends State<GuildDetailScreen>
    with SingleTickerProviderStateMixin {
  // ── Konstanten ─────────────────────────────────────────────────────────
  static const _bg = Color(0xFF0D0D1A);
  static const _card = Color(0xFF1A1A2E);

  static const Map<String, Color> _worldColors = {
    'materie': Color(0xFFE53935),
    'energie': Color(0xFF7C4DFF),
    'vorhang': Color(0xFFC9A84C),
    'ursprung': Color(0xFF00D4AA),
  };

  static const Map<String, String> _worldLabels = {
    'materie': 'Materie',
    'energie': 'Energie',
    'vorhang': 'Vorhang',
    'ursprung': 'Ursprung',
  };

  // ── State ───────────────────────────────────────────────────────────────
  final _supabase = Supabase.instance.client;
  late final TabController _tabController;

  Map<String, dynamic>? _guild;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _challenges = [];
  // challenge_id → Anzahl completions
  Map<String, int> _challengeCompletions = {};

  bool _loadingGuild = true;
  bool _loadingMembers = false;
  bool _loadingChallenges = false;
  String? _error;

  bool _isMember = false;
  bool _isLeader = false;
  String? _myRole; // 'leader' | 'elder' | 'member'
  bool _actionLoading = false;

  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  Color get _accentColor {
    final world = _guild?['world']?.toString() ?? 'energie';
    return _worldColors[world] ?? const Color(0xFF7C4DFF);
  }

  // ── Lifecycle ───────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    // Lazy-load beim ersten Tab-Wechsel
    if (_tabController.index == 1 && _challenges.isEmpty) {
      _loadChallenges();
    }
  }

  Future<void> _loadAll() async {
    await _loadGuild();
    await _loadMembers();
    // Challenges erst beim Tab-Wechsel oder sofort wenn bereits offen
    if (_tabController.index == 1) await _loadChallenges();
  }

  // ── Daten laden ─────────────────────────────────────────────────────────
  Future<void> _loadGuild() async {
    setState(() {
      _loadingGuild = true;
      _error = null;
    });
    try {
      final data = await _supabase
          .from('guilds')
          .select()
          .eq('id', widget.guildId)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));
      if (mounted) {
        setState(() {
          _guild = data;
          _loadingGuild = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gilde konnte nicht geladen werden.';
          _loadingGuild = false;
        });
      }
    }
  }

  Future<void> _loadMembers() async {
    setState(() => _loadingMembers = true);
    try {
      final res = await _supabase
          .from('guild_members')
          .select(
              'guild_id, user_id, role, joined_at, profiles(username, avatar_url)')
          .eq('guild_id', widget.guildId)
          .order('joined_at', ascending: true)
          .timeout(const Duration(seconds: 10));

      final list = List<Map<String, dynamic>>.from(res as List);

      // Eigene Mitgliedschaft ermitteln
      String? myRole;
      for (final m in list) {
        if (m['user_id'] == _currentUserId) {
          myRole = m['role']?.toString();
          break;
        }
      }

      if (mounted) {
        setState(() {
          _members = list;
          _myRole = myRole;
          _isMember = myRole != null;
          _isLeader = myRole == 'leader';
          _loadingMembers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  Future<void> _loadChallenges() async {
    setState(() => _loadingChallenges = true);
    try {
      final res = await _supabase
          .from('guild_challenges')
          .select()
          .eq('guild_id', widget.guildId)
          .order('start_date', ascending: false)
          .timeout(const Duration(seconds: 10));

      final list = List<Map<String, dynamic>>.from(res as List);

      // Completion-Counts pro Challenge laden
      if (list.isNotEmpty) {
        final ids = list.map((c) => c['id'] as String).toList();
        final progressRes = await _supabase
            .from('guild_challenge_progress')
            .select('challenge_id, completed')
            .inFilter('challenge_id', ids)
            .eq('completed', true)
            .timeout(const Duration(seconds: 10));

        final Map<String, int> completions = {};
        for (final p in (progressRes as List)) {
          final cid = p['challenge_id']?.toString() ?? '';
          completions[cid] = (completions[cid] ?? 0) + 1;
        }

        if (mounted) {
          setState(() {
            _challenges = list;
            _challengeCompletions = completions;
            _loadingChallenges = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _challenges = list;
            _loadingChallenges = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadingChallenges = false);
    }
  }

  // ── Aktionen ─────────────────────────────────────────────────────────────
  Future<void> _joinGuild() async {
    if (_actionLoading || _currentUserId.isEmpty) return;
    setState(() => _actionLoading = true);
    try {
      await _supabase.from('guild_members').insert({
        'guild_id': widget.guildId,
        'user_id': _currentUserId,
        'role': 'member',
        'joined_at': DateTime.now().toIso8601String(),
      });
      // member_count hochzählen
      final currentCount = (_guild?['member_count'] as num?)?.toInt() ?? 0;
      await _supabase
          .from('guilds')
          .update({'member_count': currentCount + 1}).eq('id', widget.guildId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Du bist der Gilde "${_guild?['name']}" beigetreten!'),
            backgroundColor: _accentColor,
          ),
        );
        await _loadMembers();
        await _loadGuild();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Beitritt fehlgeschlagen. Bitte erneut versuchen.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _leaveGuild() async {
    if (_actionLoading || _isLeader) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Gilde verlassen',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Möchtest du die Gilde "${_guild?['name']}" wirklich verlassen?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Verlassen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _actionLoading = true);
    try {
      await _supabase
          .from('guild_members')
          .delete()
          .eq('guild_id', widget.guildId)
          .eq('user_id', _currentUserId);

      final currentCount = (_guild?['member_count'] as num?)?.toInt() ?? 1;
      await _supabase.from('guilds').update({
        'member_count': (currentCount - 1).clamp(0, 999999),
      }).eq('id', widget.guildId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Du hast die Gilde verlassen.'),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadMembers();
        await _loadGuild();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Etwas ist schiefgelaufen. Bitte erneut versuchen.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _createChallenge() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final goalCtrl = TextEditingController(text: '10');
    final xpCtrl = TextEditingController(text: '50');
    String selectedType = 'quiz';

    final types = [
      'silence',
      'manifestation',
      'quiz',
      'shadow',
      'frequency',
      'remote_viewing',
    ];

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Neue Challenge',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(titleCtrl, 'Titel', Icons.title),
                const SizedBox(height: 10),
                _dialogField(descCtrl, 'Beschreibung', Icons.description,
                    maxLines: 3),
                const SizedBox(height: 10),
                // Typ-Auswahl
                DropdownButtonFormField<String>(
                  value: selectedType,
                  dropdownColor: const Color(0xFF0D0D1A),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Challenge-Typ',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF0D0D1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _accentColor.withAlpha(80)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _accentColor.withAlpha(60)),
                    ),
                  ),
                  items: types.map((t) {
                    final ct = parseChallengeType(t);
                    return DropdownMenuItem(
                      value: t,
                      child: Row(
                        children: [
                          Icon(challengeIcon(ct),
                              size: 16, color: challengeColor(ct)),
                          const SizedBox(width: 8),
                          Text(challengeLabel(ct)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedType = v ?? 'quiz'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: _dialogField(goalCtrl, 'Ziel-Wert', Icons.flag,
                            inputType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _dialogField(xpCtrl, 'Belohnungs-XP', Icons.star,
                            inputType: TextInputType.number)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Abbrechen',
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Bitte einen Titel eingeben')),
                  );
                  return;
                }
                Navigator.of(ctx).pop();
                await _saveChallenge(
                  title: title,
                  description: descCtrl.text.trim(),
                  type: selectedType,
                  goalValue: int.tryParse(goalCtrl.text.trim()) ?? 10,
                  rewardXp: int.tryParse(xpCtrl.text.trim()) ?? 50,
                );
              },
              child: const Text('Erstellen'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChallenge({
    required String title,
    required String description,
    required String type,
    required int goalValue,
    required int rewardXp,
  }) async {
    try {
      final now = DateTime.now();
      final end = now.add(const Duration(days: 7));
      await _supabase.from('guild_challenges').insert({
        'guild_id': widget.guildId,
        'title': title,
        'description': description,
        'challenge_type': type,
        'start_date': now.toIso8601String(),
        'end_date': end.toIso8601String(),
        'goal_value': goalValue,
        'reward_xp': rewardXp,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Challenge erstellt!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        await _loadChallenges();
        _tabController.animateTo(1); // Zum Challenges-Tab wechseln
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Erstellen. Bitte erneut versuchen.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────
  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.'
          '${dt.month.toString().padLeft(2, '0')}.'
          '${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType inputType = TextInputType.text,
  }) {
    final color = _accentColor;
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: inputType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        filled: true,
        fillColor: const Color(0xFF0D0D1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color.withAlpha(80)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color.withAlpha(60)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color),
        ),
      ),
    );
  }

  Widget _initialsWidget(String username, {double size = 40}) {
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loadingGuild) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
            backgroundColor: _bg,
            iconTheme: const IconThemeData(color: Colors.white)),
        body: Center(
          child: CircularProgressIndicator(color: _accentColor),
        ),
      );
    }

    if (_error != null || _guild == null) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
            backgroundColor: _bg,
            iconTheme: const IconThemeData(color: Colors.white)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                _error ?? 'Gilde nicht gefunden',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _accentColor),
                onPressed: _loadAll,
                child: const Text('Erneut versuchen',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final guild = _guild!;
    final world = guild['world']?.toString() ?? 'energie';
    final accentColor = _worldColors[world] ?? const Color(0xFF7C4DFF);
    final memberCount =
        (guild['member_count'] as num?)?.toInt() ?? _members.length;
    final maxMembers = (guild['max_members'] as num?)?.toInt() ?? 50;
    final emblIcon = _parseEmblemIcon(guild['emblem_icon']?.toString());
    final emblColor =
        _parseEmblemColor(guild['emblem_color']?.toString(), accentColor);

    return Scaffold(
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverHeader(
            guild: guild,
            world: world,
            accentColor: accentColor,
            memberCount: memberCount,
            maxMembers: maxMembers,
            emblemIcon: emblIcon,
            emblemColor: emblColor,
          ),
        ],
        body: Column(
          children: [
            // TabBar
            Container(
              color: _card,
              child: TabBar(
                controller: _tabController,
                indicatorColor: accentColor,
                labelColor: accentColor,
                unselectedLabelColor: Colors.white38,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'Mitglieder'),
                  Tab(text: 'Challenges'),
                ],
              ),
            ),
            // Tab-Inhalte
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMembersTab(accentColor),
                  _buildChallengesTab(accentColor),
                ],
              ),
            ),
          ],
        ),
      ),
      // Bottom-Action-Bar: Beitreten / Verlassen
      bottomNavigationBar: _buildBottomBar(accentColor),
      // FAB für Anführer: Challenge erstellen
      floatingActionButton: _isLeader
          ? FloatingActionButton.extended(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              onPressed: _createChallenge,
              icon: const Icon(Icons.add),
              label: const Text('Challenge'),
            )
          : null,
    );
  }

  // ── SliverAppBar-Header ──────────────────────────────────────────────────
  Widget _buildSliverHeader({
    required Map<String, dynamic> guild,
    required String world,
    required Color accentColor,
    required int memberCount,
    required int maxMembers,
    required IconData emblemIcon,
    required Color emblemColor,
  }) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: _card,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeroHeader(
          guild: guild,
          world: world,
          accentColor: accentColor,
          memberCount: memberCount,
          maxMembers: maxMembers,
          emblemIcon: emblemIcon,
          emblemColor: emblemColor,
        ),
      ),
    );
  }

  Widget _buildHeroHeader({
    required Map<String, dynamic> guild,
    required String world,
    required Color accentColor,
    required int memberCount,
    required int maxMembers,
    required IconData emblemIcon,
    required Color emblemColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accentColor.withAlpha(60),
            _card,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Gilde-Emblem (großer farbiger Kreis mit Icon)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: emblemColor.withAlpha(40),
                  shape: BoxShape.circle,
                  border: Border.all(color: emblemColor, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: emblemColor.withAlpha(80),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(emblemIcon, color: emblemColor, size: 38),
              ),
              const SizedBox(width: 18),
              // Gilden-Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Gildenname
                    Text(
                      guild['name']?.toString() ?? 'Gilde',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Welt-Chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentColor.withAlpha(120)),
                      ),
                      child: Text(
                        _worldLabels[world] ?? world,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Mitglieder-Zähler
                    Row(
                      children: [
                        Icon(Icons.group, color: Colors.white54, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$memberCount / $maxMembers Mitglieder',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    // Rolle-Badge (wenn Mitglied)
                    if (_myRole != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            _roleIcon(_myRole!),
                            color: _roleColor(_myRole!, accentColor),
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _roleLabel(_myRole!),
                            style: TextStyle(
                              color: _roleColor(_myRole!, accentColor),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom-Action-Bar ─────────────────────────────────────────────────────
  Widget? _buildBottomBar(Color accentColor) {
    if (_loadingMembers) return null;
    if (_isMember && _isLeader) return null; // Anführer braucht keinen Button

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: _isMember
            ? OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _actionLoading ? null : _leaveGuild,
                icon: _actionLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.red),
                      )
                    : const Icon(Icons.exit_to_app),
                label: const Text(
                  'Gilde verlassen',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              )
            : ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _actionLoading ? null : _joinGuild,
                icon: _actionLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.shield),
                label: const Text(
                  'Beitreten',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
      ),
    );
  }

  // ── Mitglieder-Tab ─────────────────────────────────────────────────────────
  Widget _buildMembersTab(Color accentColor) {
    if (_loadingMembers) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }
    if (_members.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, color: Colors.white24, size: 48),
            SizedBox(height: 12),
            Text(
              'Noch keine Mitglieder',
              style: TextStyle(color: Colors.white38),
            ),
          ],
        ),
      );
    }

    // Sortierung: leader zuerst, dann elder, dann member
    final sorted = List<Map<String, dynamic>>.from(_members)
      ..sort((a, b) {
        final ra = _roleSortOrder(a['role']?.toString() ?? 'member');
        final rb = _roleSortOrder(b['role']?.toString() ?? 'member');
        return ra.compareTo(rb);
      });

    return RefreshIndicator(
      onRefresh: _loadMembers,
      color: accentColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        itemCount: sorted.length,
        itemBuilder: (_, i) => _buildMemberTile(sorted[i], accentColor),
      ),
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member, Color accentColor) {
    final profile = member['profiles'] as Map<String, dynamic>?;
    final username = profile?['username'] as String? ?? 'Unbekannt';
    final avatarUrl = profile?['avatar_url'] as String?;
    final role = member['role']?.toString() ?? 'member';
    final isMe = member['user_id'] == _currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: isMe ? Border.all(color: accentColor.withAlpha(120)) : null,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withAlpha(40),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _initialsWidget(username, size: 44),
                  )
                : _initialsWidget(username, size: 44),
          ),
          const SizedBox(width: 12),
          // Name + Beitrittsdatum
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '$username (ich)' : username,
                  style: TextStyle(
                    color: isMe ? accentColor : Colors.white,
                    fontSize: 14,
                    fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (member['joined_at'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Seit ${_formatDate(member['joined_at']?.toString())}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          // Rollen-Badge
          _buildRoleBadge(role, accentColor),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role, Color accentColor) {
    final color = _roleColor(role, accentColor);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_roleIcon(role), color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            _roleLabel(role),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Challenges-Tab ──────────────────────────────────────────────────────────
  Widget _buildChallengesTab(Color accentColor) {
    if (_loadingChallenges) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }
    if (_challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_outlined,
                color: Colors.white24, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Noch keine Challenges',
              style: TextStyle(color: Colors.white38),
            ),
            if (_isLeader) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: _createChallenge,
                icon: const Icon(Icons.add),
                label: const Text('Erste Challenge erstellen'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChallenges,
      color: accentColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        itemCount: _challenges.length,
        itemBuilder: (_, i) => _buildChallengeTile(_challenges[i], accentColor),
      ),
    );
  }

  Widget _buildChallengeTile(
      Map<String, dynamic> challenge, Color accentColor) {
    final type =
        parseChallengeType(challenge['challenge_type']?.toString() ?? 'quiz');
    final typeColor = challengeColor(type);
    final title = challenge['title']?.toString() ?? 'Challenge';
    final rewardXp = (challenge['reward_xp'] as num?)?.toInt() ?? 0;
    final goalValue = (challenge['goal_value'] as num?)?.toInt() ?? 1;
    final challengeId = challenge['id']?.toString() ?? '';
    final completions = _challengeCompletions[challengeId] ?? 0;
    final totalMembers = _members.length.clamp(1, 999999);
    final completionFraction = (completions / totalMembers).clamp(0.0, 1.0);

    final now = DateTime.now();
    bool isActive = true;
    try {
      if (challenge['end_date'] != null) {
        isActive =
            DateTime.parse(challenge['end_date'].toString()).isAfter(now);
      }
    } catch (_) {}

    return GestureDetector(
      onTap: () {
        if (challengeId.isEmpty) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GuildChallengeScreen(
              challengeId: challengeId,
              guildId: widget.guildId,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: typeColor.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Obere Zeile: Typ-Chip + XP + Aktiv-Badge
            Row(
              children: [
                // Typ-Chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withAlpha(35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: typeColor.withAlpha(100)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(challengeIcon(type), color: typeColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        challengeLabel(type),
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Aktiv-Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF4CAF50).withAlpha(30)
                        : Colors.white12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'Aktiv' : 'Beendet',
                    style: TextStyle(
                      color:
                          isActive ? const Color(0xFF4CAF50) : Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // XP-Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9A825).withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star,
                          color: Color(0xFFF9A825), size: 11),
                      const SizedBox(width: 3),
                      Text(
                        '+$rewardXp XP',
                        style: const TextStyle(
                          color: Color(0xFFF9A825),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Titel
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Datum
            Text(
              '${_formatDate(challenge['start_date']?.toString())} – '
              '${_formatDate(challenge['end_date']?.toString())}  '
              '· Ziel: $goalValue',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 10),
            // Fortschrittsbalken: Wie viele Mitglieder haben abgeschlossen?
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: completionFraction,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(typeColor),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$completions/$totalMembers abgeschlossen',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Rolle Helpers ─────────────────────────────────────────────────────────
  String _roleLabel(String role) {
    switch (role) {
      case 'leader':
        return 'Anführer';
      case 'elder':
        return 'Ältester';
      default:
        return 'Mitglied';
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'leader':
        return Icons.military_tech;
      case 'elder':
        return Icons.star;
      default:
        return Icons.person;
    }
  }

  Color _roleColor(String role, Color accentColor) {
    switch (role) {
      case 'leader':
        return const Color(0xFFF9A825); // Gold
      case 'elder':
        return const Color(0xFF00D4AA); // Cyan
      default:
        return accentColor.withAlpha(200);
    }
  }

  int _roleSortOrder(String role) {
    switch (role) {
      case 'leader':
        return 0;
      case 'elder':
        return 1;
      default:
        return 2;
    }
  }

  // ── Emblem Helpers ────────────────────────────────────────────────────────
  IconData _parseEmblemIcon(String? iconName) {
    switch (iconName) {
      case 'shield':
        return Icons.shield;
      case 'star':
        return Icons.star;
      case 'bolt':
        return Icons.bolt;
      case 'forest':
        return Icons.forest;
      case 'psychology':
        return Icons.psychology;
      case 'visibility':
        return Icons.visibility;
      case 'waves':
        return Icons.waves;
      case 'auto_awesome':
        return Icons.auto_awesome;
      default:
        return Icons.shield;
    }
  }

  Color _parseEmblemColor(String? hexColor, Color fallback) {
    if (hexColor == null || hexColor.isEmpty) return fallback;
    try {
      final hex = hexColor.replaceFirst('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
      if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return fallback;
  }
}
