/// 💬 In-Call Chat Panel — Zoom-Style ausklappbarer Chat während des Calls
///
/// Zeigt den Chat-Verlauf als schwebender Panel über dem Call-Screen.
/// Eigene Nachrichten rechts (Welt-Akzent), andere links (grau).
library;

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/wb_design.dart';
import '../services/incall_chat_service.dart';

class InCallChatPanel extends StatefulWidget {
  final String world;
  final InCallChatService service;
  final VoidCallback onClose;

  const InCallChatPanel({
    super.key,
    required this.world,
    required this.service,
    required this.onClose,
  });

  @override
  State<InCallChatPanel> createState() => _InCallChatPanelState();
}

class _InCallChatPanelState extends State<InCallChatPanel> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  StreamSubscription<InCallMessage>? _sub;
  List<InCallMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _messages = List.of(widget.service.history);
    widget.service.markAllRead();
    _sub = widget.service.messageStream.listen((msg) {
      if (!mounted) return;
      setState(() => _messages.add(msg));
      widget.service.markAllRead();
      _scrollToBottom();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await widget.service.sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final accent = WbDesign.accent(widget.world);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: WbDesign.surface(widget.world).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: accent.withValues(alpha: 0.28), width: 1),
          ),
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: WbDesign.surfaceAlt(widget.world)
                      .withValues(alpha: 0.8),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_rounded,
                        color: accent, size: 17),
                    const SizedBox(width: 8),
                    const Text(
                      'Call-Chat',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 18, color: Colors.white54),
                      onPressed: widget.onClose,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // ── Nachrichtenbereich ───────────────────────────────────────
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded,
                                color: WbDesign.textTertiary
                                    .withValues(alpha: 0.4),
                                size: 36),
                            const SizedBox(height: 10),
                            Text(
                              'Noch keine Nachrichten.\nSchreib etwas!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: WbDesign.textTertiary,
                                fontSize: 13,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) =>
                            _MessageBubble(
                          msg: _messages[i],
                          accent: accent,
                        ),
                      ),
              ),
              // ── Eingabe ──────────────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.fromLTRB(10, 6, 6, 10),
                decoration: BoxDecoration(
                  color: WbDesign.surfaceAlt(widget.world)
                      .withValues(alpha: 0.6),
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                        maxLines: null,
                        maxLength: 300,
                        buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) =>
                            null,
                        decoration: InputDecoration(
                          hintText: 'Nachricht …',
                          hintStyle: TextStyle(
                              color: WbDesign.textTertiary, fontSize: 14),
                          filled: true,
                          fillColor:
                              Colors.white.withValues(alpha: 0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        onSubmitted: (_) => _send(),
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _send();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.35),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 18,
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
}

class _MessageBubble extends StatelessWidget {
  final InCallMessage msg;
  final Color accent;

  const _MessageBubble({required this.msg, required this.accent});

  String _timeLabel(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isLocal = msg.isLocal;
    return Padding(
      padding: EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: isLocal ? 40 : 0,
        right: isLocal ? 0 : 40,
      ),
      child: Column(
        crossAxisAlignment:
            isLocal ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isLocal)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(
                msg.name,
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isLocal
                  ? accent.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isLocal ? 14 : 4),
                bottomRight: Radius.circular(isLocal ? 4 : 14),
              ),
              border: Border.all(
                color: isLocal
                    ? accent.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.08),
                width: 0.8,
              ),
            ),
            child: Text(
              msg.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
            child: Text(
              _timeLabel(msg.timestamp),
              style: TextStyle(
                color: WbDesign.textTertiary.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
