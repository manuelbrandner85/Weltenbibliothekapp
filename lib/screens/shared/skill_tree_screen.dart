import 'package:flutter/material.dart';

import '../../config/wb_design.dart';
import '../../services/gamification_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🌳 SKILL TREE SCREEN — Octalysis Gamification
// Zeigt den Skill-Baum einer Welt mit Voraussetzungen und Level-Fortschritt.
// ═══════════════════════════════════════════════════════════════════════════

class SkillTreeScreen extends StatefulWidget {
  final String world; // materie, energie, noir, genesis

  const SkillTreeScreen({super.key, required this.world});

  @override
  State<SkillTreeScreen> createState() => _SkillTreeScreenState();
}

class _SkillTreeScreenState extends State<SkillTreeScreen>
    with SingleTickerProviderStateMixin {
  final _gs = GamificationService();
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  List<SkillNode> _unlockedSkills = [];
  late PlayerProgress _progress;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _unlockedSkills = _gs.getSkills(widget.world);
      _progress = _gs.getProgress(widget.world);
    });
  }

  Color get _accent => _worldAccent(widget.world);
  Color get _bg => _worldBg(widget.world);

  static Color _worldAccent(String world) {
    switch (world) {
      case 'energie':
        return WbDesign.energiePurple;
      case 'noir':
        return WbDesign.vorhangGold;
      case 'genesis':
        return WbDesign.ursprungCyan;
      default:
        return WbDesign.materieBlue;
    }
  }

  static Color _worldBg(String world) {
    switch (world) {
      case 'energie':
        return WbDesign.bgEnergie;
      case 'noir':
        return WbDesign.bgVorhang;
      case 'genesis':
        return WbDesign.bgUrsprung;
      default:
        return WbDesign.bgMaterie;
    }
  }

  static String _worldLabel(String world) {
    switch (world) {
      case 'energie':
        return 'Energie';
      case 'noir':
        return 'Noir';
      case 'genesis':
        return 'Genesis';
      default:
        return 'Materie';
    }
  }

  @override
  Widget build(BuildContext context) {
    final definitions = worldSkillDefinitions[widget.world] ?? [];
    final unlockedKeys = {for (final s in _unlockedSkills) s.skillKey: s};

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Skill-Baum · ${_worldLabel(widget.world)}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _buildLevelBadge(),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // XP Progress Bar
          _buildXpBar(),
          const SizedBox(height: 8),
          // Skill Tree
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: definitions.length,
              itemBuilder: (ctx, i) {
                final def = definitions[i];
                final node = unlockedKeys[def.key];
                final isUnlocked = node != null;
                final canUnlock = _gs.canUnlockSkill(widget.world, def.key);
                final isLocked = !isUnlocked && !canUnlock;

                return _buildSkillCard(
                  def: def,
                  node: node,
                  isUnlocked: isUnlocked,
                  canUnlock: canUnlock,
                  isLocked: isLocked,
                  isLast: i == definitions.length - 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            _accent.withValues(alpha: 0.3),
            _accent.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(color: _accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: _accent, size: 16),
          const SizedBox(width: 4),
          Text(
            'Lv. ${_progress.level}',
            style: TextStyle(
              color: _accent,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_progress.totalXp} XP',
                style: TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                '${_progress.xpForNextLevel} XP für Level ${_progress.level + 1}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progress.progressToNext,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(_accent),
            ),
          ),
          const SizedBox(height: 4),
          if (_progress.streakDays > 0)
            Row(
              children: [
                const Icon(Icons.local_fire_department,
                    color: Color(0xFFFF7043), size: 14),
                const SizedBox(width: 4),
                Text(
                  '${_progress.streakDays} Tage Streak',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
                if (_progress.freezesRemaining > 0) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.ac_unit,
                      color: Colors.cyan.withValues(alpha: 0.6), size: 12),
                  const SizedBox(width: 2),
                  Text(
                    '${_progress.freezesRemaining} Freeze',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSkillCard({
    required SkillDefinition def,
    required SkillNode? node,
    required bool isUnlocked,
    required bool canUnlock,
    required bool isLocked,
    required bool isLast,
  }) {
    return Column(
      children: [
        // Verbindungslinie
        if (def.prerequisites.isNotEmpty)
          Container(
            width: 2,
            height: 24,
            color: isUnlocked
                ? _accent.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.1),
          ),
        // Skill Card
        GestureDetector(
          onTap: canUnlock && !isLocked
              ? () => _onSkillTap(def, isUnlocked)
              : null,
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (ctx, child) {
              final glowAlpha = canUnlock && !isUnlocked
                  ? _pulseAnim.value * 0.3
                  : 0.0;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isUnlocked
                        ? [
                            _accent.withValues(alpha: 0.2),
                            _accent.withValues(alpha: 0.08),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.05),
                            Colors.white.withValues(alpha: 0.02),
                          ],
                  ),
                  border: Border.all(
                    color: isUnlocked
                        ? _accent.withValues(alpha: 0.5)
                        : canUnlock
                            ? _accent.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.08),
                    width: isUnlocked ? 1.5 : 1,
                  ),
                  boxShadow: glowAlpha > 0
                      ? [
                          BoxShadow(
                            color: _accent.withValues(alpha: glowAlpha),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isUnlocked
                              ? [
                                  _accent.withValues(alpha: 0.3),
                                  _accent.withValues(alpha: 0.1),
                                ]
                              : [
                                  Colors.white.withValues(alpha: 0.1),
                                  Colors.white.withValues(alpha: 0.04),
                                ],
                        ),
                        border: Border.all(
                          color: isUnlocked
                              ? _accent.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Center(
                        child: isLocked
                            ? Icon(Icons.lock,
                                color: Colors.white.withValues(alpha: 0.3),
                                size: 20)
                            : Text(
                                def.iconEmoji,
                                style: TextStyle(
                                  fontSize: 22,
                                  color: isUnlocked
                                      ? null
                                      : Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  def.nameDe,
                                  style: TextStyle(
                                    color: isUnlocked
                                        ? _accent
                                        : Colors.white.withValues(
                                            alpha: isLocked ? 0.3 : 0.7),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (isUnlocked && node != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: _accent.withValues(alpha: 0.2),
                                  ),
                                  child: Text(
                                    'Lv. ${node.level}/${def.maxLevel}',
                                    style: TextStyle(
                                      color: _accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            def.descriptionDe,
                            style: TextStyle(
                              color: Colors.white.withValues(
                                  alpha: isLocked ? 0.2 : 0.5),
                              fontSize: 12,
                            ),
                          ),
                          if (canUnlock && !isUnlocked)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'Tippen zum Freischalten',
                                style: TextStyle(
                                  color: _accent.withValues(alpha: 0.7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (isUnlocked && node != null && node.level < def.maxLevel)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'Tippen zum Upgrade',
                                style: TextStyle(
                                  color: _accent.withValues(alpha: 0.5),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!isLocked)
                      Icon(
                        isUnlocked
                            ? Icons.check_circle
                            : Icons.arrow_forward_ios,
                        color: isUnlocked
                            ? _accent
                            : _accent.withValues(alpha: 0.4),
                        size: isUnlocked ? 22 : 16,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        // Abschlusslinie
        if (!isLast)
          Container(
            width: 2,
            height: 16,
            color: isUnlocked
                ? _accent.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.06),
          ),
      ],
    );
  }

  Future<void> _onSkillTap(SkillDefinition def, bool isUnlocked) async {
    final action = isUnlocked ? 'upgraden' : 'freischalten';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _accent.withValues(alpha: 0.3)),
        ),
        title: Text(
          '${def.iconEmoji} ${def.nameDe}',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: Text(
          'Möchtest du "${def.nameDe}" $action?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Abbrechen',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent.withValues(alpha: 0.3),
              foregroundColor: _accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isUnlocked ? 'Upgraden' : 'Freischalten'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await _gs.unlockOrUpgradeSkill(widget.world, def.key);
      if (result != null) {
        // XP für Freischaltung/Upgrade
        await _gs.addXp(widget.world, isUnlocked ? 10 : 25,
            reason: isUnlocked ? 'skill_upgrade' : 'skill_unlock');
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isUnlocked
                  ? '${def.iconEmoji} ${def.nameDe} auf Level ${result.level}!'
                  : '${def.iconEmoji} ${def.nameDe} freigeschaltet!'),
              backgroundColor: _accent.withValues(alpha: 0.8),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }
}

