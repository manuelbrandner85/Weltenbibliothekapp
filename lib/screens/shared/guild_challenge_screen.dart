import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🏆 GUILD CHALLENGE SCREEN — Challenge-Detail mit Fortschritts-Tracking
// Zeigt Typ, Beschreibung, eigenen Fortschritt und Gildenmitglieder-Progress.
// ═══════════════════════════════════════════════════════════════════════════

// Challenge-Typ-Enum und Hilfsfunktionen
enum ChallengeType {
  silence,
  manifestation,
  quiz,
  shadow,
  frequency,
  remoteViewing,
}

ChallengeType parseChallengeType(String raw) {
  switch (raw) {
    case 'silence':
      return ChallengeType.silence;
    case 'manifestation':
      return ChallengeType.manifestation;
    case 'quiz':
      return ChallengeType.quiz;
    case 'shadow':
      return ChallengeType.shadow;
    case 'frequency':
      return ChallengeType.frequency;
    case 'remote_viewing':
      return ChallengeType.remoteViewing;
    default:
      return ChallengeType.quiz;
  }
}

String challengeLabel(ChallengeType type) {
  switch (type) {
    case ChallengeType.silence:
      return 'Schweigen';
    case ChallengeType.manifestation:
      return 'Manifestation';
    case ChallengeType.quiz:
      return 'Wissenstest';
    case ChallengeType.shadow:
      return 'Schattenarbeit';
    case ChallengeType.frequency:
      return 'Frequenz';
    case ChallengeType.remoteViewing:
      return 'Remote Viewing';
  }
}

IconData challengeIcon(ChallengeType type) {
  switch (type) {
    case ChallengeType.silence:
      return Icons.volume_off;
    case ChallengeType.manifestation:
      return Icons.auto_awesome;
    case ChallengeType.quiz:
      return Icons.quiz;
    case ChallengeType.shadow:
      return Icons.psychology;
    case ChallengeType.frequency:
      return Icons.waves;
    case ChallengeType.remoteViewing:
      return Icons.visibility;
  }
}

Color challengeColor(ChallengeType type) {
  switch (type) {
    case ChallengeType.silence:
      return const Color(0xFF78909C);
    case ChallengeType.manifestation:
      return const Color(0xFF7C4DFF);
    case ChallengeType.quiz:
      return const Color(0xFF00D4AA);
    case ChallengeType.shadow:
      return const Color(0xFFC9A84C);
    case ChallengeType.frequency:
      return const Color(0xFF00BCD4);
    case ChallengeType.remoteViewing:
      return const Color(0xFF4CAF50);
  }
}

class GuildChallengeScreen extends StatefulWidget {
  final String challengeId;
  final String guildId;

  const GuildChallengeScreen({
    super.key,
    required this.challengeId,
    required this.guildId,
  });

  @override
  State<GuildChallengeScreen> createState() => _GuildChallengeScreenState();
}

class _GuildChallengeScreenState extends State<GuildChallengeScreen> {
  static const _bg = Color(0xFF0D0D1A);
  static const _card = Color(0xFF1A1A2E);
  static const _accent = Color(0xFF7C4DFF);

  final _supabase = Supabase.instance.client;

  Map<String, dynamic>? _challenge;
  List<Map<String, dynamic>> _progress = [];
  Map<String, dynamic>? _myProgress;
  bool _loading = true;
  String? _error;

  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Challenge laden
      final challengeRes = await _supabase
          .from('guild_challenges')
          .select()
          .eq('id', widget.challengeId)
          .single();

      // Fortschritt aller Mitglieder laden (inkl. Profil via join)
      final progressRes = await _supabase
          .from('guild_challenge_progress')
          .select(
              'challenge_id, user_id, current_value, completed, profiles(username, avatar_url)')
          .eq('challenge_id', widget.challengeId);

      final progressList = List<Map<String, dynamic>>.from(progressRes as List);

      // Eigenen Fortschritt herausfiltern
      Map<String, dynamic>? myProgress;
      for (final p in progressList) {
        if (p['user_id'] == _currentUserId) {
          myProgress = p;
          break;
        }
      }

      if (mounted) {
        setState(() {
          _challenge = challengeRes;
          _progress = progressList;
          _myProgress = myProgress;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Fehler beim Laden: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _reportProgress(int newValue) async {
    try {
      await _supabase.from('guild_challenge_progress').upsert(
        {
          'challenge_id': widget.challengeId,
          'user_id': _currentUserId,
          'current_value': newValue,
          'completed': _challenge != null &&
              newValue >= ((_challenge!['goal_value'] as num?)?.toInt() ?? 1),
        },
        onConflict: 'challenge_id,user_id',
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fortschritt gespeichert!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showProgressDialog() async {
    final goalValue = (_challenge?['goal_value'] as num?)?.toInt() ?? 100;
    final currentValue = (_myProgress?['current_value'] as num?)?.toInt() ?? 0;
    final controller = TextEditingController(text: currentValue.toString());

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Fortschritt melden',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aktueller Wert (Ziel: $goalValue)',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Neuen Wert eingeben...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF0D0D1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _accent.withAlpha(100)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _accent.withAlpha(80)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _accent),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val == null || val < 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                      content: Text('Bitte eine gültige Zahl eingeben')),
                );
                return;
              }
              Navigator.of(ctx).pop();
              _reportProgress(val);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        foregroundColor: Colors.white,
        title: Text(
          _challenge?['title'] ?? 'Challenge',
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C4DFF)))
          : _error != null
              ? _buildError()
              : _challenge == null
                  ? const Center(
                      child: Text('Keine Daten',
                          style: TextStyle(color: Colors.white54)),
                    )
                  : _buildContent(),
      bottomNavigationBar: (!_loading && _error == null && _challenge != null)
          ? SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _showProgressDialog,
                  icon: const Icon(Icons.add_chart),
                  label: const Text(
                    'Fortschritt melden',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              _error ?? '',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _accent),
              onPressed: _load,
              child: const Text('Erneut versuchen',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final ch = _challenge!;
    final type = parseChallengeType(ch['challenge_type']?.toString() ?? 'quiz');
    final typeColor = challengeColor(type);
    final goalValue = (ch['goal_value'] as num?)?.toInt() ?? 1;
    final rewardXp = (ch['reward_xp'] as num?)?.toInt() ?? 0;
    final myCurrentValue =
        (_myProgress?['current_value'] as num?)?.toInt() ?? 0;
    final myCompleted = _myProgress?['completed'] == true;
    final myProgressFraction =
        (goalValue > 0) ? (myCurrentValue / goalValue).clamp(0.0, 1.0) : 0.0;

    return RefreshIndicator(
      onRefresh: _load,
      color: _accent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header-Card ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: typeColor.withAlpha(80)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Typ-Chip + XP-Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: typeColor.withAlpha(40),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: typeColor.withAlpha(120)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(challengeIcon(type),
                                color: typeColor, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              challengeLabel(type),
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9A825).withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFFF9A825).withAlpha(100)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                color: Color(0xFFF9A825), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '+$rewardXp XP',
                              style: const TextStyle(
                                color: Color(0xFFF9A825),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Titel
                  Text(
                    ch['title']?.toString() ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Datum-Bereich
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Colors.white38, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        '${_formatDate(ch['start_date']?.toString())} – '
                        '${_formatDate(ch['end_date']?.toString())}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Beschreibung ───────────────────────────────────────────────
            if (ch['description'] != null &&
                (ch['description'] as String).isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BESCHREIBUNG',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ch['description'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // ── Eigener Fortschritt ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
                border: myCompleted
                    ? Border.all(color: const Color(0xFF4CAF50).withAlpha(150))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'MEIN FORTSCHRITT',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Spacer(),
                      if (myCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withAlpha(40),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFF4CAF50).withAlpha(120)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  color: Color(0xFF4CAF50), size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Abgeschlossen',
                                style: TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$myCurrentValue',
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ' / $goalValue',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: myProgressFraction,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(typeColor),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(myProgressFraction * 100).toStringAsFixed(0)} % erreicht',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Gildenmitglieder-Fortschritt ───────────────────────────────
            if (_progress.isNotEmpty) ...[
              const Text(
                'GILDEN-FORTSCHRITT',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              ..._progress.map(
                (p) => _buildMemberProgressTile(p, goalValue, typeColor),
              ),
            ],

            const SizedBox(height: 80), // Platz für Bottom-Button
          ],
        ),
      ),
    );
  }

  Widget _buildMemberProgressTile(
    Map<String, dynamic> p,
    int goalValue,
    Color typeColor,
  ) {
    final profile = p['profiles'] as Map<String, dynamic>?;
    final username = profile?['username'] as String? ?? 'Unbekannt';
    final avatarUrl = profile?['avatar_url'] as String?;
    final currentValue = (p['current_value'] as num?)?.toInt() ?? 0;
    final completed = p['completed'] == true;
    final progressFraction =
        goalValue > 0 ? (currentValue / goalValue).clamp(0.0, 1.0) : 0.0;
    final isMe = p['user_id'] == _currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: isMe ? Border.all(color: _accent.withAlpha(100)) : null,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _accent.withAlpha(40),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _initialsWidget(username),
                  )
                : _initialsWidget(username),
          ),
          const SizedBox(width: 10),
          // Name + Fortschrittsbalken
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isMe ? '$username (ich)' : username,
                        style: TextStyle(
                          color: isMe ? _accent : Colors.white,
                          fontSize: 13,
                          fontWeight:
                              isMe ? FontWeight.bold : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (completed) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.check_circle,
                          color: Color(0xFF4CAF50), size: 14),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progressFraction,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      completed ? const Color(0xFF4CAF50) : typeColor,
                    ),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Wert
          Text(
            '$currentValue/$goalValue',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _initialsWidget(String username) {
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
