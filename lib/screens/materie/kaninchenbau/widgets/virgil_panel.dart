/// 🌟 VIRGIL FULL-PANEL — vollwertiger KI-Ermittler-Chat.
///
/// Slidet von rechts in den Screen (¾ Breite mobile, max 480 desktop).
/// Persistente Konversation über die gesamte Session.
/// Glas-Look mit BackdropFilter, Welt-Akzent (Materie-Rot).
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/kaninchenbau_service.dart';
import 'kb_design.dart';

class VirgilMessage {
  final String role; // 'user' | 'assistant' | 'system'
  final String content;
  final DateTime time;
  VirgilMessage({
    required this.role,
    required this.content,
    DateTime? time,
  }) : time = time ?? DateTime.now();

  Map<String, String> toApi() => {'role': role, 'content': content};
}

class VirgilPanel extends StatefulWidget {
  final String topic;
  final String? cardContext;
  final String? initialInsight;
  final VoidCallback onClose;

  const VirgilPanel({
    super.key,
    required this.topic,
    required this.onClose,
    this.cardContext,
    this.initialInsight,
  });

  @override
  State<VirgilPanel> createState() => _VirgilPanelState();
}

class _VirgilPanelState extends State<VirgilPanel>
    with SingleTickerProviderStateMixin {
  final _service = KaninchenbauService();
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final List<VirgilMessage> _messages = [];
  bool _sending = false;
  late final AnimationController _slide;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();

    if (widget.initialInsight != null && widget.initialInsight!.isNotEmpty) {
      _messages.add(VirgilMessage(
        role: 'assistant',
        content: widget.initialInsight!,
      ));
    } else {
      _messages.add(VirgilMessage(
        role: 'assistant',
        content:
            'Frag mich alles zu "${widget.topic}". Ich verbinde Punkte zwischen den Karten, '
            'spüre Widersprüche auf und schlage dir nächste Recherche-Pfade vor.',
      ));
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    _ctrl.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _slide.reverse();
    if (mounted) widget.onClose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    HapticFeedback.lightImpact();

    setState(() {
      _messages.add(VirgilMessage(role: 'user', content: text));
      _sending = true;
      _ctrl.clear();
    });
    _scrollToEnd();

    final reply = await _service.chatWithVirgil(
      messages: _messages.map((m) => m.toApi()).toList(),
      topic: widget.topic,
      cardContext: widget.cardContext,
    );

    if (!mounted) return;
    setState(() {
      _messages.add(VirgilMessage(
        role: 'assistant',
        content: reply ??
            '⚠️ Verbindung zu Virgil unterbrochen. Versuche es nochmal.',
      ));
      _sending = false;
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final panelW = width < 600 ? width * 0.92 : 460.0;

    return AnimatedBuilder(
      animation: _slide,
      builder: (_, __) {
        final t = Curves.easeOutCubic.transform(_slide.value);
        return Stack(
          children: [
            // Backdrop-Tap zum Schließen
            Positioned.fill(
              child: GestureDetector(
                onTap: _close,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.55 * t),
                ),
              ),
            ),
            // Panel
            Positioned(
              right: -panelW * (1 - t),
              top: 0,
              bottom: 0,
              width: panelW,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  bottomLeft: Radius.circular(28),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xCC0F0F18),
                          Color(0xEE0A0A12),
                        ],
                      ),
                      border: Border(
                        left: BorderSide(
                          color: KbDesign.neonRed.withValues(alpha: 0.5),
                          width: 1.4,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: KbDesign.neonRed.withValues(alpha: 0.18),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        children: [
                          _buildHeader(),
                          Expanded(child: _buildMessageList()),
                          _buildInput(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  KbDesign.neonRedSoft.withValues(alpha: 0.95),
                  KbDesign.neonRed.withValues(alpha: 0.7),
                  const Color(0xFF300012),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: KbDesign.neonRed.withValues(alpha: 0.55),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: const Center(
              child: Text(
                'V',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 11,
                        color: KbDesign.goldAccent.withValues(alpha: 0.8)),
                    const SizedBox(width: 4),
                    Text(
                      'VIRGIL',
                      style: TextStyle(
                        color: KbDesign.goldAccent.withValues(alpha: 0.85),
                        fontSize: 9,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.topic,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon:
                const Icon(Icons.close_rounded, color: Colors.white60, size: 24),
            onPressed: _close,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: _messages.length + (_sending ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == _messages.length) return _buildTypingIndicator();
        return _buildMessage(_messages[i]);
      },
    );
  }

  Widget _buildMessage(VirgilMessage m) {
    final isUser = m.role == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 4),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      KbDesign.neonRedSoft.withValues(alpha: 0.85),
                      const Color(0xFF300012),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'V',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  gradient: isUser
                      ? const LinearGradient(
                          colors: [
                            Color(0xFF1A0010),
                            Color(0xFF2A0018),
                          ],
                        )
                      : null,
                  color: isUser ? null : Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                    color: isUser
                        ? KbDesign.neonRed.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: SelectableText(
                  m.content,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.94),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 4),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    KbDesign.neonRedSoft.withValues(alpha: 0.85),
                    const Color(0xFF300012),
                  ],
                ),
              ),
              child: const Center(
                child: SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              'denkt nach…',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: KbDesign.neonRed.withValues(alpha: 0.3),
                ),
              ),
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                maxLines: null,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
                cursorColor: KbDesign.neonRedSoft,
                decoration: InputDecoration(
                  hintText: 'Frag Virgil…',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF1744),
                  Color(0xFFAA0028),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: KbDesign.neonRed.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: IconButton(
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.arrow_upward_rounded,
                      color: Colors.white),
              onPressed: _sending ? null : _send,
            ),
          ),
        ],
      ),
    );
  }
}
