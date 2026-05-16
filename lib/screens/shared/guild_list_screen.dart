import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './guild_detail_screen.dart';

// ---------------------------------------------------------------------------
// World helpers
// ---------------------------------------------------------------------------

Color _worldColor(String? world) {
  switch (world) {
    case 'materie':
      return const Color(0xFFE53935);
    case 'energie':
      return const Color(0xFF7C4DFF);
    case 'vorhang':
      return const Color(0xFFC9A84C);
    case 'ursprung':
      return const Color(0xFF00D4AA);
    default:
      return const Color(0xFF607D8B);
  }
}

String _worldLabel(String? world) {
  switch (world) {
    case 'materie':
      return 'Materie';
    case 'energie':
      return 'Energie';
    case 'vorhang':
      return 'Vorhang';
    case 'ursprung':
      return 'Ursprung';
    default:
      return world ?? '?';
  }
}

IconData _emblemIcon(String? name) {
  // Map common icon names to Flutter IconData.
  // The DB stores the name without the 'Icons.' prefix.
  const Map<String, IconData> iconMap = {
    'shield': Icons.shield,
    'star': Icons.star,
    'flash_on': Icons.flash_on,
    'local_fire_department': Icons.local_fire_department,
    'bolt': Icons.bolt,
    'auto_awesome': Icons.auto_awesome,
    'diamond': Icons.diamond,
    'water_drop': Icons.water_drop,
    'wb_sunny': Icons.wb_sunny,
    'nightlight_round': Icons.nightlight_round,
    'eco': Icons.eco,
    'psychology': Icons.psychology,
    'science': Icons.science,
    'biotech': Icons.biotech,
    'public': Icons.public,
    'search': Icons.search,
    'explore': Icons.explore,
    'visibility': Icons.visibility,
    'lock': Icons.lock,
    'favorite': Icons.favorite,
    'group': Icons.group,
    'people': Icons.people,
    'emoji_events': Icons.emoji_events,
    'military_tech': Icons.military_tech,
    'all_inclusive': Icons.all_inclusive,
    'verified': Icons.verified,
  };
  return iconMap[name] ?? Icons.shield;
}

// ---------------------------------------------------------------------------
// GuildListScreen
// ---------------------------------------------------------------------------

class GuildListScreen extends StatefulWidget {
  const GuildListScreen({super.key});

  @override
  State<GuildListScreen> createState() => _GuildListScreenState();
}

class _GuildListScreenState extends State<GuildListScreen>
    with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _guilds = [];
  bool _loading = true;
  String? _error;
  String _filterWorld = 'alle';

  // Skeleton animation
  late final AnimationController _skeletonController;
  late final Animation<double> _skeletonAnim;

  // Joining state: guild id -> loading
  final Map<String, bool> _joiningMap = {};

  @override
  void initState() {
    super.initState();
    _skeletonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _skeletonAnim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _skeletonController, curve: Curves.easeInOut),
    );
    _loadGuilds();
  }

  @override
  void dispose() {
    _skeletonController.dispose();
    super.dispose();
  }

  Future<void> _loadGuilds() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      var query = _supabase.from('guilds').select();
      if (_filterWorld != 'alle') {
        query = query.eq('world', _filterWorld);
      }
      final data = await query.order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _guilds = List<Map<String, dynamic>>.from(data as List);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _joinGuild(Map<String, dynamic> guild) async {
    final guildId = guild['id'] as String;
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _showSnack('Du musst eingeloggt sein, um einer Gilde beizutreten.');
      return;
    }
    setState(() => _joiningMap[guildId] = true);
    try {
      await _supabase.from('guild_members').insert({
        'guild_id': guildId,
        'user_id': user.id,
        'role': 'member',
      });
      if (mounted) {
        _showSnack('Gilde erfolgreich beigetreten!');
        unawaited(_loadGuilds());
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Fehler beim Beitreten: ${_friendlyError(e)}');
      }
    } finally {
      if (mounted) setState(() => _joiningMap.remove(guildId));
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF1A1A2E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _friendlyError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('duplicate') || msg.contains('unique')) {
      return 'Du bist dieser Gilde bereits beigetreten.';
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return 'Keine Verbindung. Bitte Internetverbindung prüfen.';
    }
    return 'Unbekannter Fehler.';
  }

  void _openCreateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateGuildSheet(
        onCreated: _loadGuilds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.shield, color: Color(0xFF7C4DFF), size: 22),
            SizedBox(width: 8),
            Text(
              'Gilden',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateDialog,
        backgroundColor: const Color(0xFF7C4DFF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Gilde erstellen'),
      ),
      body: Column(
        children: [
          _buildFilterRow(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    final filters = ['alle', 'materie', 'energie', 'vorhang', 'ursprung'];
    final labels = {
      'alle': 'Alle',
      'materie': 'Materie',
      'energie': 'Energie',
      'vorhang': 'Vorhang',
      'ursprung': 'Ursprung',
    };
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = filters[i];
          final selected = _filterWorld == f;
          final color = f == 'alle'
              ? const Color(0xFF607D8B)
              : _worldColor(f);
          return FilterChip(
            label: Text(
              labels[f]!,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: selected,
            onSelected: (_) {
              setState(() => _filterWorld = f);
              _loadGuilds();
            },
            backgroundColor: const Color(0xFF1A1A2E),
            selectedColor: color.withOpacity(0.7),
            checkmarkColor: Colors.white,
            side: BorderSide(
              color: selected ? color : Colors.white24,
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildSkeleton();
    if (_error != null) return _buildError();
    if (_guilds.isEmpty) return _buildEmpty();
    return RefreshIndicator(
      onRefresh: _loadGuilds,
      color: const Color(0xFF7C4DFF),
      backgroundColor: const Color(0xFF1A1A2E),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: _guilds.length,
        itemBuilder: (context, i) => _GuildCard(
          guild: _guilds[i],
          joining: _joiningMap[_guilds[i]['id']] == true,
          onJoin: () => _joinGuild(_guilds[i]),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  GuildDetailScreen(guildId: _guilds[i]['id'] as String),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return AnimatedBuilder(
      animation: _skeletonAnim,
      builder: (context, _) {
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          itemCount: 3,
          itemBuilder: (_, __) => _SkeletonCard(opacity: _skeletonAnim.value),
        );
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white38, size: 56),
            const SizedBox(height: 16),
            Text(
              'Fehler beim Laden der Gilden',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style:
                  const TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadGuilds,
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_outlined,
                color: Colors.white24, size: 72),
            const SizedBox(height: 16),
            const Text(
              'Keine Gilden gefunden',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sei der Erste und gründe eine Gilde!',
              style: TextStyle(color: Colors.white38, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openCreateDialog,
              icon: const Icon(Icons.add),
              label: const Text('Gilde erstellen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Guild card
// ---------------------------------------------------------------------------

class _GuildCard extends StatelessWidget {
  final Map<String, dynamic> guild;
  final bool joining;
  final VoidCallback onJoin;
  final VoidCallback onTap;

  const _GuildCard({
    required this.guild,
    required this.joining,
    required this.onJoin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = guild['name'] as String? ?? 'Unbenannte Gilde';
    final description =
        guild['description'] as String? ?? '';
    final world = guild['world'] as String?;
    final memberCount = guild['member_count'] as int? ?? 0;
    final maxMembers = guild['max_members'] as int? ?? 20;
    final emblemIcon = guild['emblem_icon'] as String?;
    final emblemColorHex = guild['emblem_color'] as String?;
    final isPublic = guild['is_public'] as bool? ?? true;

    final emblemColor = _parseColor(emblemColorHex) ?? _worldColor(world);
    final wColor = _worldColor(world);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF131328),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: wColor.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: wColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emblem
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      emblemColor.withOpacity(0.6),
                      emblemColor.withOpacity(0.2),
                    ],
                  ),
                  border: Border.all(
                      color: emblemColor.withOpacity(0.7), width: 2),
                ),
                child: Icon(
                  _emblemIcon(emblemIcon),
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isPublic)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.lock,
                                size: 14, color: Colors.white38),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // World chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: wColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: wColor.withOpacity(0.4)),
                          ),
                          child: Text(
                            _worldLabel(world),
                            style: TextStyle(
                              color: wColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Member count
                        Icon(Icons.group,
                            size: 13, color: Colors.white54),
                        const SizedBox(width: 3),
                        Text(
                          '$memberCount/$maxMembers',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: joining
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF7C4DFF),
                              ),
                            )
                          : TextButton(
                              onPressed: onJoin,
                              style: TextButton.styleFrom(
                                foregroundColor: wColor,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                backgroundColor:
                                    wColor.withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                      color: wColor.withOpacity(0.4)),
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Beitreten',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) {
      try {
        return Color(int.parse('FF$cleaned', radix: 16));
      } catch (_) {
        return null;
      }
    }
    if (cleaned.length == 8) {
      try {
        return Color(int.parse(cleaned, radix: 16));
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Skeleton card
// ---------------------------------------------------------------------------

class _SkeletonCard extends StatelessWidget {
  final double opacity;
  const _SkeletonCard({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF131328),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white12,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 10,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Create guild bottom sheet
// ---------------------------------------------------------------------------

class _CreateGuildSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateGuildSheet({required this.onCreated});

  @override
  State<_CreateGuildSheet> createState() => _CreateGuildSheetState();
}

class _CreateGuildSheetState extends State<_CreateGuildSheet> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedWorld = 'materie';
  double _maxMembers = 20;
  Color _emblemColor = const Color(0xFF7C4DFF);
  bool _isPublic = true;
  bool _submitting = false;

  // Simple color swatches
  static const _swatches = [
    Color(0xFFE53935), // materie red
    Color(0xFF7C4DFF), // energie purple
    Color(0xFFC9A84C), // vorhang gold
    Color(0xFF00D4AA), // ursprung cyan
    Color(0xFF2196F3), // blue
    Color(0xFF4CAF50), // green
    Color(0xFFFF9800), // orange
    Color(0xFFE91E63), // pink
    Color(0xFF9C27B0), // deep purple
    Color(0xFF00BCD4), // teal
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _showSnack('Du musst eingeloggt sein.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final colorHex =
          '#${_emblemColor.value.toRadixString(16).substring(2).toUpperCase()}';
      await _supabase.from('guilds').insert({
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'world': _selectedWorld,
        'leader_id': user.id,
        'max_members': _maxMembers.round(),
        'emblem_color': colorHex,
        'emblem_icon': 'shield',
        'is_public': _isPublic,
        'member_count': 1,
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gilde erfolgreich erstellt!'),
            backgroundColor: Color(0xFF1A1A2E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) _showSnack('Fehler: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF1A1A2E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final wColor = _worldColor(_selectedWorld);

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 60, 0, 0),
      decoration: const BoxDecoration(
        color: Color(0xFF131328),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.shield, color: wColor, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'Neue Gilde gründen',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // Scrollable form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    _sectionLabel('Name der Gilde'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('z.B. Lichtwächter'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Bitte einen Namen eingeben';
                        }
                        if (v.trim().length < 3) {
                          return 'Mindestens 3 Zeichen';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _sectionLabel('Beschreibung (optional)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                          'Worum geht es in eurer Gilde?'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // World
                    _sectionLabel('Welt'),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0D1A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedWorld,
                          dropdownColor: const Color(0xFF131328),
                          isExpanded: true,
                          iconEnabledColor: Colors.white54,
                          style: const TextStyle(color: Colors.white),
                          items: const [
                            DropdownMenuItem(
                                value: 'materie',
                                child: Text('Materie')),
                            DropdownMenuItem(
                                value: 'energie',
                                child: Text('Energie')),
                            DropdownMenuItem(
                                value: 'vorhang',
                                child: Text('Vorhang')),
                            DropdownMenuItem(
                                value: 'ursprung',
                                child: Text('Ursprung')),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedWorld = v);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Max members
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionLabel('Max. Mitglieder'),
                        Text(
                          '${_maxMembers.round()}',
                          style: TextStyle(
                            color: wColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: wColor,
                        thumbColor: wColor,
                        inactiveTrackColor: Colors.white12,
                        overlayColor: wColor.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: _maxMembers,
                        min: 6,
                        max: 50,
                        divisions: 44,
                        onChanged: (v) =>
                            setState(() => _maxMembers = v),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('6', style: TextStyle(color: Colors.white38, fontSize: 11)),
                        Text('50', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Emblem color
                    _sectionLabel('Gildenfarbe'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _swatches.map((c) {
                        final selected = _emblemColor == c;
                        return GestureDetector(
                          onTap: () => setState(() => _emblemColor = c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: selected ? 3 : 0,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: c.withOpacity(0.6),
                                        blurRadius: 8,
                                      )
                                    ]
                                  : null,
                            ),
                            child: selected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 18)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Public toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionLabel('Öffentliche Gilde'),
                            const Text(
                              'Jeder kann beitreten',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isPublic,
                          onChanged: (v) => setState(() => _isPublic = v),
                          activeColor: wColor,
                          inactiveTrackColor: Colors.white12,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: wColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              wColor.withOpacity(0.4),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Gilde gründen',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF0D0D1A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF7C4DFF)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE53935)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE53935)),
      ),
      errorStyle: const TextStyle(color: Color(0xFFE53935)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
