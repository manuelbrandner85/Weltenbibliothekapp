import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt; // 🎤 L2
import 'package:url_launcher/url_launcher.dart';

import '../../services/mentor_service.dart';
import '../../widgets/wb_cached_image.dart';
import '../ursprung/mentor_session_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🧠 MENTOR CHAT SCREEN — KI-Mentor mit 4 Persönlichkeiten
// ═══════════════════════════════════════════════════════════════════════════

class MentorChatScreen extends StatefulWidget {
  final MentorPersonality personality;
  final String world; // 'materie', 'energie', 'vorhang', 'ursprung'

  const MentorChatScreen({
    super.key,
    required this.personality,
    required this.world,
  });

  @override
  State<MentorChatScreen> createState() => _MentorChatScreenState();
}

class _MentorChatScreenState extends State<MentorChatScreen>
    with TickerProviderStateMixin {
  final _service = MentorService();
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  List<MentorChatMessage> _messages = [];
  bool _isLoading = false;
  late AnimationController _typingCtrl;

  // 🎤 L2 Voice-Input
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechReady = false;

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }
    if (!_speechReady) {
      _speechReady = await _speech.initialize(
        onStatus: (s) {
          if (s == 'done' || s == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (e) {
          if (mounted) setState(() => _isListening = false);
        },
      );
      if (!_speechReady) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Mikrofon nicht verfügbar oder Berechtigung fehlt.',
              ),
            ),
          );
        }
        return;
      }
    }
    setState(() => _isListening = true);
    await _speech.listen(
      localeId: 'de_DE',
      onResult: (result) {
        if (!mounted) return;
        final base = _textCtrl.text;
        final transcription = result.recognizedWords;
        // Während des Diktats Live-Update.
        _textCtrl.text = base.isEmpty
            ? transcription
            : (result.finalResult ? '$base $transcription' : base);
        _textCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _textCtrl.text.length),
        );
        if (result.finalResult) {
          setState(() => _isListening = false);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  // ── Welt-Farben ──
  Color get _primaryColor {
    switch (widget.world) {
      case 'vorhang':
        return const Color(0xFFC9A84C);
      case 'ursprung':
        return const Color(0xFF00D4AA);
      case 'energie':
        return const Color(0xFFA855F7);
      case 'materie':
      default:
        return const Color(0xFF3B82F6);
    }
  }

  Color get _bgColor {
    switch (widget.world) {
      case 'vorhang':
        return const Color(0xFF0D0B00);
      case 'ursprung':
        return const Color(0xFF050510);
      case 'energie':
        return const Color(0xFF0C0318);
      case 'materie':
      default:
        return const Color(0xFF040D1F);
    }
  }

  IconData get _mentorIcon {
    switch (widget.personality) {
      case MentorPersonality.stratege:
        return Icons.psychology;
      case MentorPersonality.alchemist:
        return Icons.all_inclusive;
      case MentorPersonality.heiler:
        return Icons.favorite;
      case MentorPersonality.forscher:
        return Icons.science;
    }
  }

  @override
  void initState() {
    super.initState();
    _typingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _messages = _service.loadHistory(widget.world);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _typingCtrl.dispose();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SEND MESSAGE
  // ═══════════════════════════════════════════════════════════

  Future<void> _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _isLoading) return;

    _textCtrl.clear();
    final userMsg = MentorChatMessage(role: 'user', content: text);
    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _service.sendMessage(
        personality: widget.personality,
        message: text,
        history: _messages,
        world: widget.world,
      );

      if (!mounted) return;
      final assistantMsg = MentorChatMessage(
        role: 'assistant',
        content: response.reply,
      );
      setState(() {
        _messages.add(assistantMsg);
        _isLoading = false;
      });
      await _service.saveHistory(widget.world, _messages);
    } catch (e) {
      if (!mounted) return;
      final errorMsg = MentorChatMessage(
        role: 'assistant',
        content: '⚠️ ${e.toString().replaceFirst("Exception: ", "")}',
      );
      setState(() {
        _messages.add(errorMsg);
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  // ═══════════════════════════════════════════════════════════
  // FACTCHECK
  // ═══════════════════════════════════════════════════════════

  Future<void> _showFactCheckDialog() async {
    final claimCtrl = TextEditingController();
    final claim = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgColor.withValues(alpha: 0.95),
        title: Text(
          'Faktencheck',
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: claimCtrl,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Behauptung eingeben...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: _primaryColor.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: _primaryColor),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Abbrechen',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, claimCtrl.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: _primaryColor),
            child: const Text('Prüfen', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (claim == null || claim.isEmpty) return;

    setState(() {
      _messages.add(
        MentorChatMessage(
          role: 'user',
          content: '📋 Faktencheck: "$claim"',
          type: 'factcheck',
        ),
      );
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final result = await _service.factCheck(claim);
      if (!mounted) return;

      setState(() {
        _messages.add(
          MentorChatMessage(
            role: 'assistant',
            content: result.explanation,
            type: 'factcheck',
            metadata: {
              'verdict': result.verdict,
              'sources': result.sources
                  .map(
                    (s) => <String, dynamic>{
                      'claim': s.claim,
                      'source': s.source,
                      'rating': s.rating,
                      'url': s.url,
                    },
                  )
                  .toList(),
            },
          ),
        );
        _isLoading = false;
      });
      await _service.saveHistory(widget.world, _messages);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          MentorChatMessage(
            role: 'assistant',
            content: '⚠️ Faktencheck fehlgeschlagen: $e',
          ),
        );
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  // ═══════════════════════════════════════════════════════════
  // YOUTUBE SEARCH
  // ═══════════════════════════════════════════════════════════

  Future<void> _showYouTubeSearch() async {
    final queryCtrl = TextEditingController();
    final query = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgColor.withValues(alpha: 0.95),
        title: Text(
          'YouTube-Suche',
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: queryCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Suchbegriff...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: _primaryColor.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: _primaryColor),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Abbrechen',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, queryCtrl.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: _primaryColor),
            child: const Text('Suchen', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (query == null || query.isEmpty) return;

    setState(() {
      _messages.add(
        MentorChatMessage(
          role: 'user',
          content: '📺 YouTube: "$query"',
          type: 'youtube',
        ),
      );
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final videos = await _service.searchYouTube(query);
      if (!mounted) return;

      if (videos.isEmpty) {
        setState(() {
          _messages.add(
            MentorChatMessage(
              role: 'assistant',
              content: 'Keine Videos zu "$query" gefunden.',
            ),
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _messages.add(
            MentorChatMessage(
              role: 'assistant',
              content: '📺 ${videos.length} Videos gefunden:',
              type: 'youtube',
              metadata: {
                'videos': videos
                    .map(
                      (v) => <String, dynamic>{
                        'title': v.title,
                        'videoId': v.videoId,
                        'thumbnail': v.thumbnail,
                        'channel': v.channel,
                      },
                    )
                    .toList(),
              },
            ),
          );
          _isLoading = false;
        });
        await _service.saveHistory(widget.world, _messages);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          MentorChatMessage(
            role: 'assistant',
            content: '⚠️ YouTube-Suche fehlgeschlagen: $e',
          ),
        );
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  // ═══════════════════════════════════════════════════════════
  // INVESTIGATE
  // ═══════════════════════════════════════════════════════════

  Future<void> _showInvestigateDialog() async {
    final topicCtrl = TextEditingController();
    String depth = 'basic';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _bgColor.withValues(alpha: 0.95),
          title: Text(
            'Tiefenrecherche',
            style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: topicCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Thema eingeben...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _primaryColor.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _primaryColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final d in ['basic', 'deep', 'expert'])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ChoiceChip(
                          label: Text(
                            d == 'basic'
                                ? 'Kurz'
                                : d == 'deep'
                                    ? 'Tief'
                                    : 'Experte',
                            style: TextStyle(
                              fontSize: 12,
                              color: depth == d
                                  ? Colors.black
                                  : Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          selected: depth == d,
                          selectedColor: _primaryColor,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          onSelected: (_) => setDialogState(() => depth = d),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Abbrechen',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, {
                'topic': topicCtrl.text.trim(),
                'depth': depth,
              }),
              style: FilledButton.styleFrom(backgroundColor: _primaryColor),
              child: const Text(
                'Recherchieren',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == null || (result['topic'] ?? '').isEmpty) return;

    final topic = result['topic']!;
    final selectedDepth = result['depth'] ?? 'basic';

    setState(() {
      _messages.add(
        MentorChatMessage(
          role: 'user',
          content:
              '🔍 Recherche: "$topic" (${selectedDepth == 'basic' ? 'Kurz' : selectedDepth == 'deep' ? 'Tief' : 'Experte'})',
          type: 'investigation',
        ),
      );
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final inv = await _service.investigate(topic, depth: selectedDepth);
      if (!mounted) return;

      final sb = StringBuffer();
      sb.writeln('**${topic.toUpperCase()}**\n');
      sb.writeln(inv.summary);
      if (inv.facts.isNotEmpty) {
        sb.writeln('\n**Kernfakten:**');
        for (var i = 0; i < inv.facts.length; i++) {
          sb.writeln('${i + 1}. ${inv.facts[i]}');
        }
      }
      if (inv.sources.isNotEmpty) {
        sb.writeln('\n**Quellen:**');
        for (final s in inv.sources) {
          sb.writeln('- ${s.author}: "${s.title}" (${s.year})');
        }
      }
      if (inv.relatedTopics.isNotEmpty) {
        sb.writeln('\n**Verwandte Themen:** ${inv.relatedTopics.join(', ')}');
      }

      setState(() {
        _messages.add(
          MentorChatMessage(
            role: 'assistant',
            content: sb.toString(),
            type: 'investigation',
          ),
        );
        _isLoading = false;
      });
      await _service.saveHistory(widget.world, _messages);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          MentorChatMessage(
            role: 'assistant',
            content: '⚠️ Recherche fehlgeschlagen: $e',
          ),
        );
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  // ═══════════════════════════════════════════════════════════
  // CLEAR CHAT
  // ═══════════════════════════════════════════════════════════

  Future<void> _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgColor.withValues(alpha: 0.95),
        title: const Text(
          'Chat löschen?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Der gesamte Verlauf mit diesem Mentor wird gelöscht.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Abbrechen',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.clearHistory(widget.world);
      if (mounted) setState(() => _messages.clear());
    }
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final mentorName = mentorDisplayName(widget.personality);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Mentor Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _primaryColor.withValues(alpha: 0.3),
                    _primaryColor.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: _primaryColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Icon(_mentorIcon, color: _primaryColor, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mentorName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    color: _primaryColor.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Avatar-Modus: immersive 3D-Mentor-Session oeffnen
          IconButton(
            icon: Icon(
              Icons.face_retouching_natural,
              color: _primaryColor.withValues(alpha: 0.85),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MentorSessionScreen(
                  personality: widget.personality,
                  world: widget.world,
                ),
              ),
            ),
            tooltip: 'Avatar-Modus',
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            onPressed: _clearChat,
            tooltip: 'Chat loeschen',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Chat-Nachrichten ──
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(mentorName)
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == _messages.length && _isLoading) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[i]);
                    },
                  ),
          ),

          // ── Aktions-Buttons ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildActionChip(
                    Icons.checklist,
                    'Faktencheck',
                    _showFactCheckDialog,
                  ),
                  const SizedBox(width: 8),
                  _buildActionChip(
                    Icons.search,
                    'Recherche',
                    _showInvestigateDialog,
                  ),
                  const SizedBox(width: 8),
                  _buildActionChip(
                    Icons.play_circle_outline,
                    'YouTube',
                    _showYouTubeSearch,
                  ),
                ],
              ),
            ),
          ),

          // ── Input-Feld ──
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: _bgColor,
              border: Border(
                top: BorderSide(
                  color: _primaryColor.withValues(alpha: 0.15),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    focusNode: _focusNode,
                    maxLines: 4,
                    minLines: 1,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Nachricht an $mentorName...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 6),
                // 🎤 L2: Voice-Input via speech_to_text
                Material(
                  color: _isListening
                      ? Colors.red.withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.08),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _isLoading ? null : _toggleVoiceInput,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.white : Colors.white70,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Material(
                  color: _primaryColor,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _isLoading ? null : _sendMessage,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.send,
                        color: _isLoading ? Colors.black38 : Colors.black87,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ──
  Widget _buildEmptyState(String mentorName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryColor.withValues(alpha: 0.1),
                border: Border.all(
                  color: _primaryColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(_mentorIcon, color: _primaryColor, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              mentorName,
              style: TextStyle(
                color: _primaryColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _mentorGreeting,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _mentorGreeting {
    switch (widget.personality) {
      case MentorPersonality.stratege:
        return 'Ich bin dein strategischer Berater.\nFrage mich zu Machtdynamiken, Verhandlungen\noder sozialen Strategien.';
      case MentorPersonality.alchemist:
        return 'Ich bin dein Bewusstseinsexperte.\nFrage mich zum Gateway Process, Remote Viewing\noder hermetischen Prinzipien.';
      case MentorPersonality.heiler:
        return 'Ich bin dein Energie-Mentor.\nFrage mich zu Meditation, Chakren,\nAtemtechniken oder Heilmethoden.';
      case MentorPersonality.forscher:
        return 'Ich bin dein Forschungsbegleiter.\nFrage mich zu Quantenphysik, Neurowissenschaften\noder verborgenen Zivilisationen.';
    }
  }

  // ── Message Bubble ──
  Widget _buildMessageBubble(MentorChatMessage msg) {
    final isUser = msg.role == 'user';

    // Spezial-Card für Faktencheck-Ergebnis
    if (msg.type == 'factcheck' && !isUser && msg.metadata != null) {
      return _buildFactCheckCard(msg);
    }

    // Spezial-Card für YouTube-Ergebnisse
    if (msg.type == 'youtube' && !isUser && msg.metadata != null) {
      return _buildYouTubeCards(msg);
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isUser ? 48 : 0,
          right: isUser ? 0 : 48,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.white.withValues(alpha: 0.1)
              : _primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: Border.all(
            color: isUser
                ? Colors.white.withValues(alpha: 0.08)
                : _primaryColor.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
        child: SelectableText(
          msg.content,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14.5,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  // ── FactCheck Card ──
  Widget _buildFactCheckCard(MentorChatMessage msg) {
    final verdict = msg.metadata?['verdict'] ?? 'Unbekannt';
    final sources = msg.metadata?['sources'] as List<dynamic>? ?? [];

    Color verdictColor;
    if (verdict.contains('Wahr') || verdict.contains('Korrekt')) {
      verdictColor = Colors.green;
    } else if (verdict.contains('Falsch')) {
      verdictColor = Colors.red;
    } else {
      verdictColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4, right: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verdict Badge
          Row(
            children: [
              const Icon(Icons.fact_check, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              const Text(
                'FAKTENCHECK',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: verdictColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: verdictColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  verdict,
                  style: TextStyle(
                    color: verdictColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Explanation
          SelectableText(
            msg.content,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.5,
            ),
          ),

          // Sources
          if (sources.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Quellen:',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            for (final s in sources)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '- ${s['source'] ?? ''}: ${s['rating'] ?? ''}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ── YouTube Cards ──
  Widget _buildYouTubeCards(MentorChatMessage msg) {
    final videos = msg.metadata?['videos'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.play_circle, color: _primaryColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  msg.content,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: videos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) {
                final v = videos[i] as Map<String, dynamic>;
                return _buildYouTubeCard(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYouTubeCard(Map<String, dynamic> v) {
    final videoId = v['videoId'] ?? '';
    final thumbnail =
        v['thumbnail'] ?? 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';

    return GestureDetector(
      onTap: () {
        final url = 'https://www.youtube.com/watch?v=$videoId';
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      },
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _primaryColor.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            // PERF (P11): Mentor-Video-Thumbnails cachen.
            WbCachedImage(
              thumbnail,
              height: 85,
              width: 200,
              fit: BoxFit.cover,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              errorWidget: Container(
                height: 85,
                width: 200,
                color: Colors.white.withValues(alpha: 0.05),
                child: const Icon(
                  Icons.play_circle_outline,
                  color: Colors.white30,
                  size: 32,
                ),
              ),
            ),
            // Title
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                child: Text(
                  v['title'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Typing Indicator ──
  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 4, right: 120),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: _primaryColor.withValues(alpha: 0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: AnimatedBuilder(
          animation: _typingCtrl,
          builder: (ctx, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final delay = i * 0.25;
                final t = ((_typingCtrl.value + delay) % 1.0);
                final scale = 0.6 + 0.4 * (t < 0.5 ? t * 2 : 2 - t * 2);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _primaryColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  // ── Action Chip ──
  Widget _buildActionChip(IconData icon, String label, VoidCallback onPressed) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: _primaryColor),
      label: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 12,
        ),
      ),
      backgroundColor: _primaryColor.withValues(alpha: 0.1),
      side: BorderSide(color: _primaryColor.withValues(alpha: 0.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: _isLoading ? null : onPressed,
    );
  }
}
