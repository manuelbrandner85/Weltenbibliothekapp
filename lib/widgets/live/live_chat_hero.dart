import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/wb_cinematic_tokens.dart';

/// Information about an active live call in the current world room.
///
/// Carries the minimum payload the [LiveChatHero] needs to render the
/// "active" hero state. `avatarUrls` may be empty; the widget falls back
/// to placeholder circles in that case.
@immutable
class LiveCallInfo {
  final String callId;
  final String topic;
  final int participantCount;
  final Duration runningSince;
  final List<String> avatarUrls;

  const LiveCallInfo({
    required this.callId,
    required this.topic,
    required this.participantCount,
    required this.runningSince,
    this.avatarUrls = const <String>[],
  });
}

/// Static helper that turns next-session metadata into a user-friendly
/// German label such as "heute 20:00" or "Sa, 25.5. um 14:00".
class LiveScheduleHint {
  /// Returns a formatted hint or `null` when no session is scheduled.
  ///
  /// - `null` when [when] or [topic] is `null`/empty.
  /// - "heute HH:mm" when [when] is on the same calendar day.
  /// - "morgen HH:mm" when [when] is on the following day.
  /// - "Wd, d.M. um HH:mm" otherwise (e.g. "Sa, 25.5. um 14:00").
  static String? formatNextSession({DateTime? when, String? topic}) {
    if (when == null) return null;
    if (topic == null || topic.trim().isEmpty) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(when.year, when.month, when.day);
    final deltaDays = target.difference(today).inDays;

    final hh = when.hour.toString().padLeft(2, '0');
    final mm = when.minute.toString().padLeft(2, '0');

    if (deltaDays == 0) return 'heute $hh:$mm';
    if (deltaDays == 1) return 'morgen $hh:$mm';

    const weekdays = <String>['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final wd = weekdays[(when.weekday - 1).clamp(0, 6)];
    return '$wd, ${when.day}.${when.month}. um $hh:$mm';
  }
}

/// Cinematic top-of-chat hero. Visualizes the live status of a world room
/// and provides primary actions (join / remind / start) depending on state.
///
/// States:
/// - A: an [activeCall] is provided -> "LIVE NOW" layout with pulsing dot
///      and avatar stack.
/// - B: no active call but [scheduledTopic] + [scheduledAt] given ->
///      upcoming-session layout.
/// - C: nothing scheduled -> empty "Stille gerade" layout with optional
///      "Live starten" CTA.
class LiveChatHero extends StatefulWidget {
  /// World identifier: `'materie'` or `'energie'`.
  final String world;

  /// Total user count in the world chat room.
  final int totalRoomMembers;

  /// Currently running call, or `null` when nothing is live.
  final LiveCallInfo? activeCall;

  /// Tapped when user wants to join the call normally.
  final VoidCallback onJoinCall;

  /// Opens the replay / archive library.
  final VoidCallback onSeeReplays;

  /// Opens the live schedule view.
  final VoidCallback onSchedule;

  /// Optional: tapped when user wants to host a new live session.
  /// Defaults to a "Bald verfügbar"-SnackBar when omitted.
  final VoidCallback? onStartLive;

  /// Optional: join the call but immediately muted.
  final VoidCallback? onJoinMuted;

  /// Optional: set a local reminder for the upcoming session.
  final VoidCallback? onRemind;

  /// Optional next-session topic for state B.
  final String? scheduledTopic;

  /// Optional next-session datetime for state B.
  final DateTime? scheduledAt;

  /// Replay archive count (rendered as "Archiv (N)"). Defaults to 0.
  final int replayCount;

  const LiveChatHero({
    super.key,
    required this.world,
    required this.totalRoomMembers,
    this.activeCall,
    required this.onJoinCall,
    required this.onSeeReplays,
    required this.onSchedule,
    this.onStartLive,
    this.onJoinMuted,
    this.onRemind,
    this.scheduledTopic,
    this.scheduledAt,
    this.replayCount = 0,
  });

  @override
  State<LiveChatHero> createState() => _LiveChatHeroState();
}

class _LiveChatHeroState extends State<LiveChatHero>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _ambientCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant LiveChatHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    // React to world changes: restart ambient glow to refresh palette feel.
    if (oldWidget.world != widget.world) {
      _ambientCtrl
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  WBWorldPalette _palette(BuildContext context) {
    final wb = context.wb;
    switch (widget.world) {
      case 'materie':
        return wb.materie;
      case 'energie':
        return wb.energie;
      default:
        return wb.neutral;
    }
  }

  String _worldEmoji() {
    switch (widget.world) {
      case 'materie':
        return '🔷';
      case 'energie':
        return '⚡';
      default:
        return '🌌';
    }
  }

  String _worldLabel() {
    switch (widget.world) {
      case 'materie':
        return 'MATERIE-RAUM';
      case 'energie':
        return 'ENERGIE-RAUM';
      default:
        return 'LIVE-RAUM';
    }
  }

  void _handleJoin() {
    HapticFeedback.lightImpact();
    widget.onJoinCall();
  }

  void _handleStartLive() {
    HapticFeedback.mediumImpact();
    final cb = widget.onStartLive;
    if (cb != null) {
      cb();
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Live-Hosting bald verfuegbar'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleRemind() {
    HapticFeedback.selectionClick();
    final cb = widget.onRemind;
    if (cb != null) {
      cb();
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Erinnerung gesetzt'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palette(context);
    final wb = context.wb;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: WBSpace.lg,
        vertical: WBSpace.sm,
      ),
      child: AnimatedBuilder(
        animation: _ambientCtrl,
        builder: (context, child) {
          // Subtle ambient pulse on shadow intensity, very slow.
          final amb = 0.5 + 0.5 * math.sin(_ambientCtrl.value * 2 * math.pi);
          final glowAlpha = (0.18 + amb * 0.10).clamp(0.0, 1.0);

          return Container(
            constraints: const BoxConstraints(minHeight: 140, maxHeight: 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(WBRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: palette.glow.withValues(alpha: glowAlpha),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(WBRadius.xl),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        wb.glassElevated,
                        palette.deep.withValues(alpha: 0.45),
                      ],
                    ),
                    border: Border.all(
                      color: palette.primary.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: child,
                ),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            WBSpace.lg,
            WBSpace.md,
            WBSpace.lg,
            WBSpace.md,
          ),
          child: _buildContent(context, palette),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WBWorldPalette palette) {
    final call = widget.activeCall;
    if (call != null) {
      return _buildActiveCall(context, palette, call);
    }
    final hint = LiveScheduleHint.formatNextSession(
      when: widget.scheduledAt,
      topic: widget.scheduledTopic,
    );
    if (hint != null) {
      return _buildUpcoming(context, palette, hint);
    }
    return _buildEmpty(context, palette);
  }

  // -- State A: active call ---------------------------------------------------

  Widget _buildActiveCall(
    BuildContext context,
    WBWorldPalette palette,
    LiveCallInfo call,
  ) {
    final minutes = call.runningSince.inMinutes;
    final runningLabel = minutes < 1
        ? 'gerade gestartet'
        : minutes < 60
            ? 'laeuft seit $minutes min'
            : 'laeuft seit ${(minutes / 60).floor()}h ${minutes % 60}min';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _PulsingLiveDot(controller: _pulseCtrl),
            const SizedBox(width: WBSpace.sm),
            Text(
              'LIVE',
              style: WBType.eyebrow.copyWith(
                color: const Color(0xFFFF5252),
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.more_horiz,
              size: 18,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ],
        ),
        const SizedBox(height: WBSpace.xs),
        Text(
          call.topic,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: WBSpace.xs),
        Row(
          children: [
            _AvatarStack(
              urls: call.avatarUrls,
              ringColor: palette.primary,
              totalCount: call.participantCount,
            ),
            const SizedBox(width: WBSpace.sm),
            Flexible(
              child: Text(
                runningLabel,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.65),
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: WBSpace.sm),
        Row(
          children: [
            _PrimaryButton(
              label: 'BEITRETEN',
              color: palette.primary,
              onTap: _handleJoin,
            ),
            const SizedBox(width: WBSpace.sm),
            _SecondaryButton(
              icon: Icons.mic_off_outlined,
              label: 'Stumm',
              onTap: () {
                HapticFeedback.selectionClick();
                final cb = widget.onJoinMuted ?? widget.onJoinCall;
                cb();
              },
            ),
            const SizedBox(width: WBSpace.sm),
            _SecondaryButton(
              icon: Icons.play_arrow_rounded,
              label: 'Archiv',
              onTap: widget.onSeeReplays,
            ),
          ],
        ),
      ],
    );
  }

  // -- State B: upcoming session ---------------------------------------------

  Widget _buildUpcoming(
    BuildContext context,
    WBWorldPalette palette,
    String hint,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderRow(
          emoji: _worldEmoji(),
          label: _worldLabel(),
          onlineCount: widget.totalRoomMembers,
          palette: palette,
        ),
        const SizedBox(height: WBSpace.xs),
        Text(
          'Naechster Live-Talk:',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.55),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '"${widget.scheduledTopic ?? ''}" - $hint',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: palette.highlight,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: WBSpace.sm),
        Row(
          children: [
            _PrimaryButton(
              label: 'ERINNERN',
              color: palette.primary,
              onTap: _handleRemind,
            ),
            const SizedBox(width: WBSpace.sm),
            _SecondaryButton(
              icon: Icons.play_arrow_rounded,
              label: 'Archiv (${widget.replayCount})',
              onTap: widget.onSeeReplays,
            ),
            const Spacer(),
            _IconBtn(
              icon: Icons.event_outlined,
              onTap: widget.onSchedule,
              tint: palette.label,
            ),
          ],
        ),
      ],
    );
  }

  // -- State C: empty room ----------------------------------------------------

  Widget _buildEmpty(BuildContext context, WBWorldPalette palette) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderRow(
          emoji: _worldEmoji(),
          label: _worldLabel(),
          onlineCount: widget.totalRoomMembers,
          palette: palette,
        ),
        const SizedBox(height: WBSpace.xs),
        Text(
          'Stille gerade. Magst du etwas starten?',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.75),
            height: 1.25,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: WBSpace.sm),
        Row(
          children: [
            _PrimaryButton(
              label: 'LIVE STARTEN',
              color: palette.primary,
              onTap: _handleStartLive,
            ),
            const SizedBox(width: WBSpace.sm),
            _SecondaryButton(
              icon: Icons.play_arrow_rounded,
              label: 'Archiv (${widget.replayCount})',
              onTap: widget.onSeeReplays,
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
//                              Internal pieces
// =============================================================================

class _HeaderRow extends StatelessWidget {
  final String emoji;
  final String label;
  final int onlineCount;
  final WBWorldPalette palette;

  const _HeaderRow({
    required this.emoji,
    required this.label,
    required this.onlineCount,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          emoji,
          style: TextStyle(
            fontSize: 22,
            shadows: [
              Shadow(color: palette.glow, blurRadius: 14),
            ],
          ),
        ),
        const SizedBox(width: WBSpace.sm),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WBType.eyebrow.copyWith(
              color: palette.label,
              fontSize: 10,
              letterSpacing: 3.0,
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(WBRadius.pill),
            border: Border.all(
              color: palette.primary.withValues(alpha: 0.25),
              width: 0.6,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: palette.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: palette.glow, blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$onlineCount online',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.white,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PulsingLiveDot extends StatelessWidget {
  final AnimationController controller;
  const _PulsingLiveDot({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(controller.value);
        final scale = 1.0 + t * 0.4;
        final haloAlpha = (1.0 - t) * 0.6;
        return SizedBox(
          width: 18,
          height: 18,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 18 * scale,
                height: 18 * scale,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252)
                      .withValues(alpha: haloAlpha.clamp(0.0, 1.0)),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5252),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0x99FF5252), blurRadius: 8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final List<String> urls;
  final Color ringColor;
  final int totalCount;

  const _AvatarStack({
    required this.urls,
    required this.ringColor,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final visible = urls.take(4).toList();
    final extra = math.max(0, totalCount - visible.length);
    const size = 28.0;
    const overlap = 10.0;

    final width =
        visible.isEmpty ? size : size + (visible.length - 1) * (size - overlap);

    return SizedBox(
      height: size,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: width,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (int i = 0; i < visible.length; i++)
                  Positioned(
                    left: i * (size - overlap),
                    child: _AvatarCircle(
                      url: visible[i],
                      ringColor: ringColor,
                      size: size,
                    ),
                  ),
                if (visible.isEmpty)
                  _AvatarCircle(
                    url: null,
                    ringColor: ringColor,
                    size: size,
                  ),
              ],
            ),
          ),
          if (extra > 0) ...[
            const SizedBox(width: 6),
            Text(
              '+$extra',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.75),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String? url;
  final Color ringColor;
  final double size;

  const _AvatarCircle({
    required this.url,
    required this.ringColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1A1A2E),
        border: Border.all(color: ringColor, width: 1.6),
        image: (url != null && url!.isNotEmpty)
            ? DecorationImage(
                image: NetworkImage(url!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: (url == null || url!.isEmpty)
          ? Icon(
              Icons.person_outline,
              size: size * 0.55,
              color: Colors.white.withValues(alpha: 0.55),
            )
          : null,
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WBRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                Color.lerp(color, Colors.white, 0.18) ?? color,
              ],
            ),
            borderRadius: BorderRadius.circular(WBRadius.pill),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.45),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WBRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(WBRadius.pill),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color tint;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WBRadius.pill),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            shape: BoxShape.circle,
            border: Border.all(
              color: tint.withValues(alpha: 0.35),
              width: 0.6,
            ),
          ),
          child: Icon(icon, size: 16, color: tint),
        ),
      ),
    );
  }
}
