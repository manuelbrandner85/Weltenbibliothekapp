// MessageBarV2 — schlanke Chat-Eingabezeile fuer Live-Chats
//
// Drei sichtbare Elemente:
//   [⊕]  [TextField]  [▶ / 🎙️]
//
// Alle weiteren Aktionen (Bild, Voice, Poll, Pin, Live, Ort) sind in einem
// Slide-Up-Sheet versteckt. Smart-Replies und Mention-Picker werden oberhalb
// der Bar eingeblendet. Recording-State wird extern verwaltet und nur visuell
// gespiegelt.
//
// Voraussetzungen:
//   * Material 3
//   * dart2js-safe (kein Record-Pattern, keine const-Maps mit Records)
//   * Keine externen Pakete ausser Material + dart:ui + services

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Vorschlag fuer den Mention-Picker (`@user`).
class MentionSuggestion {
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String? avatarEmoji;

  const MentionSuggestion({
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.avatarEmoji,
  });
}

/// Welt-spezifische Farbtokens (siehe CLAUDE.md).
class _WorldTokens {
  final Color primary;
  final Color surface;
  const _WorldTokens({required this.primary, required this.surface});

  static _WorldTokens of(String world) {
    switch (world) {
      case 'energie':
        return const _WorldTokens(
          primary: Color(0xFF7C4DFF),
          surface: Color(0xFF1A0820),
        );
      case 'materie':
      default:
        return const _WorldTokens(
          primary: Color(0xFF2196F3),
          surface: Color(0xFF0A1929),
        );
    }
  }
}

/// Schlanke Message-Bar mit Plus-Sheet, Smart-Replies und Mention-Picker.
class MessageBarV2 extends StatefulWidget {
  final String world; // 'materie' | 'energie'
  final TextEditingController controller;
  final FocusNode? focusNode;

  // Senden
  final VoidCallback onSendText;

  // Plus-Sheet Optionen (null = im Sheet ausblenden)
  final VoidCallback? onAttachImage;
  final VoidCallback? onAttachVoice;
  final VoidCallback? onCreatePoll;
  final VoidCallback? onPinMessage;
  final VoidCallback? onCreateLiveSession;
  final VoidCallback? onShareLocation;

  // Inline-Features
  final ValueChanged<String>? onMentionTrigger;
  final List<MentionSuggestion>? mentionSuggestions;
  final ValueChanged<MentionSuggestion>? onMentionPicked;

  // Smart-Replies
  final List<String>? smartReplySuggestions;
  final ValueChanged<String>? onSmartReplyTap;
  final VoidCallback? onDismissSmartReplies;

  // Recording-State (extern verwaltet)
  final bool isRecordingVoice;
  final Duration? recordingDuration;
  final VoidCallback? onCancelVoiceRecording;

  const MessageBarV2({
    super.key,
    required this.world,
    required this.controller,
    required this.onSendText,
    this.focusNode,
    this.onAttachImage,
    this.onAttachVoice,
    this.onCreatePoll,
    this.onPinMessage,
    this.onCreateLiveSession,
    this.onShareLocation,
    this.onMentionTrigger,
    this.mentionSuggestions,
    this.onMentionPicked,
    this.smartReplySuggestions,
    this.onSmartReplyTap,
    this.onDismissSmartReplies,
    this.isRecordingVoice = false,
    this.recordingDuration,
    this.onCancelVoiceRecording,
  });

  @override
  State<MessageBarV2> createState() => _MessageBarV2State();
}

class _MessageBarV2State extends State<MessageBarV2>
    with SingleTickerProviderStateMixin {
  bool _hasText = false;
  String? _lastMentionQuery; // null = nicht aktiv
  late final AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
    _hasText = widget.controller.text.trim().isNotEmpty;
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant MessageBarV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChanged);
      widget.controller.addListener(_handleTextChanged);
      _handleTextChanged();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    _waveCtrl.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    final text = widget.controller.text;
    final hasText = text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }

    // Parse last word for mention trigger.
    final mentionQuery =
        _extractMentionQuery(text, widget.controller.selection);
    if (mentionQuery != _lastMentionQuery) {
      _lastMentionQuery = mentionQuery;
      if (widget.onMentionTrigger != null) {
        widget.onMentionTrigger!(mentionQuery ?? '');
      }
    }
  }

  /// Extrahiert die aktuelle `@`-Suche an Cursor-Position, oder null.
  static String? _extractMentionQuery(String text, TextSelection sel) {
    if (text.isEmpty) return null;
    final cursor = sel.isValid ? sel.baseOffset : text.length;
    if (cursor <= 0 || cursor > text.length) return null;
    // Walke rueckwaerts bis Whitespace oder Start.
    var i = cursor - 1;
    while (i >= 0) {
      final ch = text[i];
      if (ch == ' ' || ch == '\n' || ch == '\t') {
        return null;
      }
      if (ch == '@') {
        final q = text.substring(i + 1, cursor);
        if (q.isEmpty) return null;
        // Mindestens 1 Zeichen nach @
        return q;
      }
      i--;
    }
    return null;
  }

  void _openPlusSheet(BuildContext context, _WorldTokens tokens) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) => _PlusSheet(
        tokens: tokens,
        onAttachImage: widget.onAttachImage,
        onAttachVoice: widget.onAttachVoice,
        onCreatePoll: widget.onCreatePoll,
        onPinMessage: widget.onPinMessage,
        onCreateLiveSession: widget.onCreateLiveSession,
        onShareLocation: widget.onShareLocation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = _WorldTokens.of(widget.world);
    final mentions = widget.mentionSuggestions ?? const <MentionSuggestion>[];
    final smartReplies = widget.smartReplySuggestions ?? const <String>[];

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (smartReplies.isNotEmpty && !widget.isRecordingVoice)
            _SmartReplyRow(
              suggestions: smartReplies,
              tokens: tokens,
              onTap: widget.onSmartReplyTap,
              onDismiss: widget.onDismissSmartReplies,
            ),
          if (mentions.isNotEmpty && !widget.isRecordingVoice)
            _MentionPicker(
              suggestions: mentions,
              tokens: tokens,
              onPicked: widget.onMentionPicked,
            ),
          _buildBar(tokens),
        ],
      ),
    );
  }

  Widget _buildBar(_WorldTokens tokens) {
    if (widget.isRecordingVoice) {
      return _buildRecordingBar(tokens);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _CircleIconButton(
            tooltip: 'Anhang & Aktionen',
            color: tokens.primary,
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
            onTap: () => _openPlusSheet(context, tokens),
          ),
          const SizedBox(width: 8),
          Expanded(child: _buildTextField(tokens)),
          const SizedBox(width: 8),
          _buildTrailingAction(tokens),
        ],
      ),
    );
  }

  Widget _buildTextField(_WorldTokens tokens) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, maxHeight: 140),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: tokens.primary.withOpacity(0.32),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            minLines: 1,
            maxLines: 5,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            cursorColor: tokens.primary,
            textInputAction: TextInputAction.newline,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              isCollapsed: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
              hintText: 'Nachricht...',
              hintStyle: TextStyle(color: Colors.white38, fontSize: 15),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrailingAction(_WorldTokens tokens) {
    if (_hasText) {
      return _CircleIconButton(
        tooltip: 'Senden',
        color: tokens.primary,
        filled: true,
        child: const Icon(Icons.arrow_upward_rounded,
            color: Colors.white, size: 22),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onSendText();
        },
      );
    }
    // Leeres Textfeld → Mic-Icon (tap = onAttachVoice)
    final hasVoice = widget.onAttachVoice != null;
    return _CircleIconButton(
      tooltip: hasVoice ? 'Sprachnachricht' : 'Senden deaktiviert',
      color: tokens.primary,
      filled: hasVoice,
      onTap: hasVoice
          ? () {
              HapticFeedback.selectionClick();
              widget.onAttachVoice!();
            }
          : null,
      child: Icon(
        Icons.mic_rounded,
        color: hasVoice ? Colors.white : Colors.white38,
        size: 22,
      ),
    );
  }

  Widget _buildRecordingBar(_WorldTokens tokens) {
    final dur = widget.recordingDuration ?? Duration.zero;
    final mm = dur.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = dur.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.redAccent.withOpacity(0.45),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                _CircleIconButton(
                  tooltip: 'Abbrechen',
                  color: Colors.redAccent,
                  onTap: widget.onCancelVoiceRecording,
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                const _PulsingRecordDot(),
                const SizedBox(width: 8),
                Text(
                  'Aufnahme $mm:$ss',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _waveCtrl,
                    builder: (_, __) => CustomPaint(
                      painter: _WavePainter(
                        progress: _waveCtrl.value,
                        color: Colors.redAccent,
                      ),
                      size: const Size.fromHeight(36),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Plus-Sheet
// ---------------------------------------------------------------------------

class _PlusOption {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback callback;
  const _PlusOption({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.callback,
  });
}

class _PlusSheet extends StatelessWidget {
  final _WorldTokens tokens;
  final VoidCallback? onAttachImage;
  final VoidCallback? onAttachVoice;
  final VoidCallback? onCreatePoll;
  final VoidCallback? onPinMessage;
  final VoidCallback? onCreateLiveSession;
  final VoidCallback? onShareLocation;

  const _PlusSheet({
    required this.tokens,
    this.onAttachImage,
    this.onAttachVoice,
    this.onCreatePoll,
    this.onPinMessage,
    this.onCreateLiveSession,
    this.onShareLocation,
  });

  List<_PlusOption> _buildOptions() {
    final out = <_PlusOption>[];
    if (onAttachImage != null) {
      out.add(_PlusOption(
        emoji: '📷',
        title: 'Bild',
        subtitle: 'Aus Galerie',
        callback: onAttachImage!,
      ));
    }
    if (onAttachVoice != null) {
      out.add(_PlusOption(
        emoji: '🎙️',
        title: 'Voice',
        subtitle: 'Stimme aufnehmen',
        callback: onAttachVoice!,
      ));
    }
    if (onCreatePoll != null) {
      out.add(_PlusOption(
        emoji: '📊',
        title: 'Poll',
        subtitle: 'Umfrage starten',
        callback: onCreatePoll!,
      ));
    }
    if (onPinMessage != null) {
      out.add(_PlusOption(
        emoji: '📌',
        title: 'Pin',
        subtitle: 'Wichtige Nachricht',
        callback: onPinMessage!,
      ));
    }
    if (onCreateLiveSession != null) {
      out.add(_PlusOption(
        emoji: '🎥',
        title: 'Live',
        subtitle: 'Session starten',
        callback: onCreateLiveSession!,
      ));
    }
    if (onShareLocation != null) {
      out.add(_PlusOption(
        emoji: '📍',
        title: 'Ort',
        subtitle: 'Standort teilen',
        callback: onShareLocation!,
      ));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final options = _buildOptions();
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                tokens.surface.withOpacity(0.95),
                tokens.primary.withOpacity(0.18),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: tokens.primary.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 10,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'ANHANG & AKTIONEN',
                style: TextStyle(
                  color: tokens.primary.withOpacity(0.95),
                  fontSize: 11,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              if (options.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Keine Aktionen verfuegbar',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.55,
                  ),
                  itemCount: options.length,
                  itemBuilder: (ctx, i) => _PlusTile(
                    option: options[i],
                    tokens: tokens,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlusTile extends StatelessWidget {
  final _PlusOption option;
  final _WorldTokens tokens;
  const _PlusTile({required this.option, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).pop();
          option.callback();
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: tokens.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(option.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 6),
              Text(
                option.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                option.subtitle,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Smart-Replies
// ---------------------------------------------------------------------------

class _SmartReplyRow extends StatelessWidget {
  final List<String> suggestions;
  final _WorldTokens tokens;
  final ValueChanged<String>? onTap;
  final VoidCallback? onDismiss;

  const _SmartReplyRow({
    required this.suggestions,
    required this.tokens,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final shown = suggestions.take(3).toList(growable: false);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: shown.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final text = shown[i];
                  return _SmartReplyChip(
                    text: text,
                    tokens: tokens,
                    onTap: onTap == null
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            onTap!(text);
                          },
                  );
                },
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              tooltip: 'Vorschlaege ausblenden',
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              icon: const Icon(Icons.close_rounded, color: Colors.white54),
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}

class _SmartReplyChip extends StatelessWidget {
  final String text;
  final _WorldTokens tokens;
  final VoidCallback? onTap;
  const _SmartReplyChip({
    required this.text,
    required this.tokens,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: tokens.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mention-Picker
// ---------------------------------------------------------------------------

class _MentionPicker extends StatelessWidget {
  final List<MentionSuggestion> suggestions;
  final _WorldTokens tokens;
  final ValueChanged<MentionSuggestion>? onPicked;

  const _MentionPicker({
    required this.suggestions,
    required this.tokens,
    this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final shown = suggestions.take(5).toList(growable: false);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: tokens.surface.withOpacity(0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: tokens.primary.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List<Widget>.generate(shown.length, (i) {
                final s = shown[i];
                return InkWell(
                  onTap: onPicked == null
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          onPicked!(s);
                        },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        _MentionAvatar(s: s, tokens: tokens),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '@${s.username}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (s.displayName != null &&
                                  s.displayName!.trim().isNotEmpty)
                                Text(
                                  s.displayName!,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _MentionAvatar extends StatelessWidget {
  final MentionSuggestion s;
  final _WorldTokens tokens;
  const _MentionAvatar({required this.s, required this.tokens});

  @override
  Widget build(BuildContext context) {
    const size = 24.0;
    final url = s.avatarUrl;
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _emojiOrInitial(),
        ),
      );
    }
    return _emojiOrInitial();
  }

  Widget _emojiOrInitial() {
    const size = 24.0;
    final emoji = s.avatarEmoji;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.primary.withOpacity(0.25),
        shape: BoxShape.circle,
        border: Border.all(
          color: tokens.primary.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        (emoji != null && emoji.isNotEmpty)
            ? emoji
            : (s.username.isNotEmpty ? s.username[0].toUpperCase() : '?'),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers: CircleIconButton, Pulsing Dot, Wave Painter
// ---------------------------------------------------------------------------

class _CircleIconButton extends StatelessWidget {
  final Widget child;
  final Color color;
  final bool filled;
  final VoidCallback? onTap;
  final String? tooltip;

  const _CircleIconButton({
    required this.child,
    required this.color,
    this.filled = false,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: filled ? color : color.withOpacity(0.18),
            shape: BoxShape.circle,
            border: Border.all(
              color: filled ? color.withOpacity(0.0) : color.withOpacity(0.4),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
    if (tooltip == null) return btn;
    return Tooltip(message: tooltip!, child: btn);
  }
}

class _PulsingRecordDot extends StatefulWidget {
  const _PulsingRecordDot();

  @override
  State<_PulsingRecordDot> createState() => _PulsingRecordDotState();
}

class _PulsingRecordDotState extends State<_PulsingRecordDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final opacity = 0.55 + 0.45 * _c.value;
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(opacity),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.4 * _c.value),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  const _WavePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 18;
    final barWidth = (size.width / (barCount * 1.7)).clamp(2.0, 5.0);
    final spacing =
        (size.width - barWidth * barCount) / math.max(1, barCount - 1);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;
    final cy = size.height / 2;
    for (var i = 0; i < barCount; i++) {
      final phase = (i / barCount) * 2 * math.pi;
      final t = progress * 2 * math.pi;
      final amp = (math.sin(t + phase) + 1) / 2; // 0..1
      final h = 4 + amp * (size.height - 6);
      final x = i * (barWidth + spacing);
      final rect = Rect.fromLTWH(x, cy - h / 2, barWidth, h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.progress != progress || old.color != color;
}
