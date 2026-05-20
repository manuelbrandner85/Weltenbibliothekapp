// 📌 PINS + POLLS HEADER - Kollabierbare Karten oberhalb des Chats
//
// Statt separater Toggle/Tab-Navigation fuer Pinned Messages und aktive Polls
// werden beide hier als kompakte ausklappbare Karten direkt ueber der Message-
// Liste angezeigt. Spart einen ganzen Navigation-Layer und macht den Live-
// Kontext sofort sichtbar.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Eine gepinnte Nachricht
class PinnedMessageEntry {
  final String id;
  final String authorName;
  final String? authorAvatarUrl;
  final String? authorAvatarEmoji;
  final String content;
  final DateTime pinnedAt;
  final VoidCallback? onJump; // Tap auf Karte -> scrolle zur Nachricht im Chat
  final VoidCallback? onUnpin; // optional: nur sichtbar wenn nicht null

  const PinnedMessageEntry({
    required this.id,
    required this.authorName,
    this.authorAvatarUrl,
    this.authorAvatarEmoji,
    required this.content,
    required this.pinnedAt,
    this.onJump,
    this.onUnpin,
  });
}

/// Eine aktive Umfrage
class ActivePollEntry {
  final String id;
  final String question;
  final List<PollOption> options;
  final int totalVotes;
  final DateTime? endsAt; // null = open-ended
  final int? userVoteIndex; // null = User hat noch nicht abgestimmt
  final ValueChanged<int>? onVote;
  final VoidCallback? onOpen; // oeffnet Detail-Sheet

  const ActivePollEntry({
    required this.id,
    required this.question,
    required this.options,
    required this.totalVotes,
    this.endsAt,
    this.userVoteIndex,
    this.onVote,
    this.onOpen,
  });
}

class PollOption {
  final String label;
  final int votes;
  const PollOption({required this.label, required this.votes});
}

/// Cinematic kollabierbarer Header fuer Pins + Polls.
class PinsPollsHeader extends StatefulWidget {
  final String world; // 'materie' | 'energie'
  final List<PinnedMessageEntry> pins;
  final List<ActivePollEntry> polls;
  final bool initiallyExpanded;

  const PinsPollsHeader({
    super.key,
    required this.world,
    this.pins = const [],
    this.polls = const [],
    this.initiallyExpanded = false,
  });

  @override
  State<PinsPollsHeader> createState() => _PinsPollsHeaderState();
}

class _PinsPollsHeaderState extends State<PinsPollsHeader>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late final AnimationController _animCtrl;

  Color get _primary => widget.world == 'materie'
      ? const Color(0xFF2196F3)
      : const Color(0xFF7C4DFF);

  Color get _accent => widget.world == 'materie'
      ? const Color(0xFF64B5F6)
      : const Color(0xFFB39DDB);

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      value: _expanded ? 1.0 : 0.0,
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _animCtrl.forward();
      } else {
        _animCtrl.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pins.isEmpty && widget.polls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _primary.withValues(alpha: 0.18),
                  _primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _primary.withValues(alpha: 0.35)),
            ),
            child: Column(
              children: [
                _buildSummaryHeader(),
                SizeTransition(
                  sizeFactor: CurvedAnimation(
                    parent: _animCtrl,
                    curve: Curves.easeOutCubic,
                  ),
                  axisAlignment: -1,
                  child: _buildExpandedContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    final pinCount = widget.pins.length;
    final pollCount = widget.polls.length;
    final parts = <String>[];
    if (pinCount > 0) {
      parts.add('📌 $pinCount ${pinCount == 1 ? "Pin" : "Pins"}');
    }
    if (pollCount > 0) {
      parts.add('📊 $pollCount ${pollCount == 1 ? "Umfrage" : "Umfragen"}');
    }
    return InkWell(
      onTap: _toggle,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                parts.join('   ·   '),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            AnimatedRotation(
              turns: _expanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 240),
              child: Icon(
                Icons.expand_more_rounded,
                color: _accent,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.polls.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...widget.polls.map((p) => _PollCard(
                  poll: p,
                  primary: _primary,
                  accent: _accent,
                )),
          ],
          if (widget.pins.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...widget.pins.map((p) => _PinCard(
                  pin: p,
                  primary: _primary,
                )),
          ],
        ],
      ),
    );
  }
}

class _PinCard extends StatelessWidget {
  final PinnedMessageEntry pin;
  final Color primary;

  const _PinCard({required this.pin, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: InkWell(
        onTap: pin.onJump,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatar(),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.push_pin_rounded, size: 12, color: primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            pin.authorName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (pin.onUnpin != null)
                          GestureDetector(
                            onTap: pin.onUnpin,
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pin.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: 12,
                        height: 1.35,
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

  Widget _avatar() {
    final url = pin.authorAvatarUrl;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(radius: 14, backgroundImage: NetworkImage(url));
    }
    final emoji = pin.authorAvatarEmoji ?? '👤';
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primary.withValues(alpha: 0.25),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 14)),
    );
  }
}

class _PollCard extends StatelessWidget {
  final ActivePollEntry poll;
  final Color primary;
  final Color accent;

  const _PollCard({
    required this.poll,
    required this.primary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final total = poll.totalVotes <= 0 ? 1 : poll.totalVotes;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primary.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        onTap: poll.onOpen,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.poll_outlined, size: 13, color: accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      poll.question,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  Text(
                    '${poll.totalVotes} ${poll.totalVotes == 1 ? "Stimme" : "Stimmen"}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(poll.options.length, (i) {
                final opt = poll.options[i];
                final pct = opt.votes / total;
                final isUserChoice = poll.userVoteIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: GestureDetector(
                    onTap: poll.userVoteIndex == null
                        ? () {
                            HapticFeedback.lightImpact();
                            poll.onVote?.call(i);
                          }
                        : null,
                    child: Stack(
                      children: [
                        Container(
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: pct.clamp(0.0, 1.0),
                          child: Container(
                            height: 28,
                            decoration: BoxDecoration(
                              color: isUserChoice
                                  ? primary.withValues(alpha: 0.45)
                                  : primary.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              children: [
                                if (isUserChoice)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      size: 14,
                                      color: accent,
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    opt.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${(pct * 100).round()}%',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
