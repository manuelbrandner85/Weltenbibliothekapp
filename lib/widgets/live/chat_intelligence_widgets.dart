/// 🧠 CHAT INTELLIGENCE WIDGETS
///
/// Drei zusammengehoerige Intelligenz-Komponenten fuer die Live-Chat-Screens
/// (Materie & Energie):
///
///   1. [CatchupCard]        — AI-Zusammenfassung wenn User > 24h weg war.
///   2. [TopicCloud]         — momentan aktive Diskussions-Themen als Chip-Cloud.
///   3. [SmartReplyComputer] — Service-Klasse, computes Smart-Reply-Vorschlaege.
///
/// Bewusst in EINER Datei damit der Import in den Chat-Screens schlank bleibt.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/api_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 🎨 SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// Welt-Farbe — primary Akzent fuer Materie (blau) bzw. Energie (lila).
Color _worldColor(String world) {
  switch (world) {
    case 'energie':
      return const Color(0xFF7C4DFF);
    case 'materie':
    default:
      return const Color(0xFF2196F3);
  }
}

/// Deutsche Stopword-Liste fuer Topic-Extraction.
/// Bewusst klein gehalten (nur die haeufigsten Fuellwoerter).
const Set<String> _stopwords = <String>{
  'aber', 'auch', 'dann', 'wenn', 'sehr', 'ueber', 'über', 'dass', 'sich',
  'mein', 'dein', 'sein', 'wird', 'wurde', 'sind', 'habe', 'haben',
  'machen', 'heute', 'schon', 'noch', 'immer', 'nicht', 'dies', 'das',
  'bei', 'vom', 'vor', 'nach', 'mit', 'ohne', 'aus', 'und', 'oder',
  'der', 'die', 'des', 'dem', 'den', 'ein', 'eine', 'einer', 'eines',
  'einem', 'einen', 'ich', 'du', 'er', 'sie', 'wir', 'ihr', 'was',
  'wie', 'wo', 'wer', 'weil', 'denn', 'gibt', 'kann', 'mag', 'muss',
  'soll', 'will', 'mehr', 'viel', 'viele', 'einfach', 'wirklich',
  'ganz', 'eben', 'eigentlich', 'doch', 'mal', 'nur', 'auf', 'für',
  'fuer', 'zum', 'zur', 'zu', 'im', 'in', 'an', 'als', 'so',
  'ist', 'war', 'wenn', 'man',
};

/// Extrahiert die top-N Themen aus einer Message-Liste.
/// Zaehlt Worte (>4 chars, kein Stopword), Hashtags und Emoji-Cluster.
List<MapEntry<String, int>> _extractTopics(
  List<Map<String, dynamic>> messages, {
  int topN = 6,
}) {
  final Map<String, int> counts = <String, int>{};

  for (final Map<String, dynamic> msg in messages) {
    final dynamic raw = msg['content'] ?? msg['text'] ?? msg['message'] ?? '';
    final String text = raw is String ? raw : raw.toString();
    if (text.trim().isEmpty) continue;

    // Hashtags
    final Iterable<RegExpMatch> hashtags =
        RegExp(r'#([\wäöüÄÖÜß]+)').allMatches(text);
    for (final RegExpMatch m in hashtags) {
      final String tag = '#${m.group(1)!.toLowerCase()}';
      counts[tag] = (counts[tag] ?? 0) + 2; // Hashtags zaehlen doppelt
    }

    // Normale Worte
    final List<String> words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\wäöüÄÖÜß\s#]', unicode: true), ' ')
        .split(RegExp(r'\s+'))
        .where((String w) => w.length > 4 && !_stopwords.contains(w))
        .toList();
    for (final String w in words) {
      if (w.startsWith('#')) continue; // Hashtags schon gezaehlt
      counts[w] = (counts[w] ?? 0) + 1;
    }
  }

  final List<MapEntry<String, int>> sorted = counts.entries.toList()
    ..sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
        b.value.compareTo(a.value));
  return sorted.take(topN).toList();
}

/// Kapitalisiert ein Wort fuer die Anzeige.
String _capitalize(String s) {
  if (s.isEmpty) return s;
  if (s.startsWith('#')) {
    return '#${s.substring(1, 2).toUpperCase()}${s.substring(2)}';
  }
  return '${s.substring(0, 1).toUpperCase()}${s.substring(1)}';
}

/// Emoji-Praefix fuer ein Topic (heuristisch).
String _topicEmoji(String topic) {
  final String lower = topic.toLowerCase();
  if (lower.contains('wasser')) return '💧';
  if (lower.contains('mond')) return '🌙';
  if (lower.contains('sonne')) return '☀️';
  if (lower.contains('kristall')) return '💎';
  if (lower.contains('chakra')) return '🌀';
  if (lower.contains('medit')) return '🧘';
  if (lower.contains('mantra') || lower.contains('affirma')) return '✨';
  if (lower.contains('heil') || lower.contains('frequenz')) return '🎵';
  if (lower.contains('traum')) return '💭';
  if (lower.startsWith('#')) return '🏷️';
  return '💬';
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. CatchupCard
// ─────────────────────────────────────────────────────────────────────────────

/// Zeigt eine kompakte "Was hast du verpasst"-Karte wenn der User > 24h
/// weg war. Bietet On-Demand AI-Zusammenfassung via Mentor-Worker.
class CatchupCard extends StatefulWidget {
  final String world;
  final DateTime lastVisit;
  final List<Map<String, dynamic>> recentMessages;
  final VoidCallback onDismiss;

  const CatchupCard({
    super.key,
    required this.world,
    required this.lastVisit,
    required this.recentMessages,
    required this.onDismiss,
  });

  @override
  State<CatchupCard> createState() => _CatchupCardState();
}

class _CatchupCardState extends State<CatchupCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  bool _loadingAi = false;
  String? _aiSummary;
  String? _aiError;

  List<MapEntry<String, int>> _topics = <MapEntry<String, int>>[];
  int _messageCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _computeLocalPreview();
    _controller.forward();
  }

  void _computeLocalPreview() {
    _messageCount = widget.recentMessages.length;
    _topics = _extractTopics(widget.recentMessages, topN: 3);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatAgo(DateTime then) {
    final Duration diff = DateTime.now().difference(then);
    if (diff.inDays >= 1) {
      return diff.inDays == 1 ? '1 Tag' : '${diff.inDays} Tage';
    }
    if (diff.inHours >= 1) {
      return diff.inHours == 1 ? '1 Stunde' : '${diff.inHours} Stunden';
    }
    return '${diff.inMinutes} Minuten';
  }

  Future<void> _requestAiSummary() async {
    if (_loadingAi) return;
    setState(() {
      _loadingAi = true;
      _aiError = null;
    });

    try {
      // Kompakte Repraesentation (max 50 messages, max 80 chars each).
      final List<Map<String, dynamic>> sample =
          widget.recentMessages.take(50).toList();
      final String compactText = sample.map((Map<String, dynamic> m) {
        final dynamic c = m['content'] ?? m['text'] ?? m['message'] ?? '';
        final String s = c is String ? c : c.toString();
        return s.length > 80 ? '${s.substring(0, 80)}…' : s;
      }).join(' | ');

      final Map<String, String> headers = <String, String>{
        'Content-Type': 'application/json',
      };
      try {
        final Session? session = Supabase.instance.client.auth.currentSession;
        final String? token = session?.accessToken;
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      } catch (_) {
        // Supabase nicht initialisiert — public call, kein Token.
      }

      final Uri url = Uri.parse('${ApiConfig.workerUrl}/api/mentor/chat');
      final http.Response resp = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode(<String, dynamic>{
              'personality': 'heiler',
              'message':
                  'Fasse diese ${widget.recentMessages.length} Chat-Nachrichten in 5 Bullet-Points zusammen: $compactText',
              'world': widget.world,
              'conversationHistory': <Map<String, dynamic>>[],
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final dynamic data = jsonDecode(resp.body);
        final String reply = (data is Map)
            ? (data['reply'] ?? data['answer'] ?? data['response'] ?? '')
                .toString()
            : '';
        setState(() {
          _aiSummary = reply.trim().isEmpty
              ? 'Keine Zusammenfassung verfuegbar.'
              : reply.trim();
          _loadingAi = false;
        });
      } else {
        setState(() {
          _aiError = 'AI-Service nicht erreichbar (${resp.statusCode})';
          _loadingAi = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiError = 'Zusammenfassung fehlgeschlagen';
        _loadingAi = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gate: nur rendern wenn lastVisit > 24h zurueck UND >= 5 Messages.
    final Duration diff = DateTime.now().difference(widget.lastVisit);
    if (diff.inHours <= 24 || widget.recentMessages.length < 5) {
      return const SizedBox.shrink();
    }

    final Color accent = _worldColor(widget.world);
    final String topicLine = _topics.isEmpty
        ? ''
        : _topics
            .map((MapEntry<String, int> e) => _capitalize(e.key))
            .join(', ');

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: accent.withValues(alpha: 0.18),
                      blurRadius: 20,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Text('📥', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Du warst ${_formatAgo(widget.lastVisit)} weg',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: widget.onDismiss,
                          borderRadius: BorderRadius.circular(16),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.close,
                                color: Colors.white70, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      topicLine.isEmpty
                          ? '$_messageCount Nachrichten verpasst'
                          : '$_messageCount Nachrichten verpasst · Themen: $topicLine',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_aiSummary == null && _aiError == null)
                      Row(
                        children: <Widget>[
                          _AiSummaryButton(
                            loading: _loadingAi,
                            accent: accent,
                            onTap: _requestAiSummary,
                          ),
                        ],
                      ),
                    if (_aiError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.orangeAccent, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _aiError!,
                                style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _requestAiSummary,
                              child: const Text('Erneut versuchen'),
                            ),
                          ],
                        ),
                      ),
                    if (_aiSummary != null) ...<Widget>[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.25),
                          ),
                        ),
                        child: SelectableText(
                          _aiSummary!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: widget.onDismiss,
                          child: const Text('Geschlossen'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AiSummaryButton extends StatelessWidget {
  final bool loading;
  final Color accent;
  final VoidCallback onTap;

  const _AiSummaryButton({
    required this.loading,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              accent.withValues(alpha: 0.85),
              accent.withValues(alpha: 0.55),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (loading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              const Text('⚡', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Text(
              loading ? 'Fasse zusammen…' : 'AI-Zusammenfassung',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. TopicCloud
// ─────────────────────────────────────────────────────────────────────────────

/// Horizontale Chip-Cloud mit den momentan aktiv diskutierten Themen.
class TopicCloud extends StatefulWidget {
  final List<Map<String, dynamic>> recentMessages;
  final String world;
  final ValueChanged<String>? onTopicTap;

  const TopicCloud({
    super.key,
    required this.recentMessages,
    required this.world,
    this.onTopicTap,
  });

  @override
  State<TopicCloud> createState() => _TopicCloudState();
}

class _TopicCloudState extends State<TopicCloud> {
  List<MapEntry<String, int>> _topics = <MapEntry<String, int>>[];

  @override
  void initState() {
    super.initState();
    _recompute();
  }

  @override
  void didUpdateWidget(covariant TopicCloud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.recentMessages, widget.recentMessages) ||
        oldWidget.recentMessages.length != widget.recentMessages.length) {
      _recompute();
    }
  }

  void _recompute() {
    _topics = _extractTopics(widget.recentMessages, topN: 6);
  }

  @override
  Widget build(BuildContext context) {
    if (_topics.length < 3) return const SizedBox.shrink();

    final Color accent = _worldColor(widget.world);

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: _topics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext ctx, int i) {
          final MapEntry<String, int> entry = _topics[i];
          final String label =
              '${_topicEmoji(entry.key)} ${_capitalize(entry.key)} (${entry.value}x)';
          return _TopicChip(
            label: label,
            accent: accent,
            onTap: widget.onTopicTap == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    widget.onTopicTap!.call(entry.key);
                  },
          );
        },
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  final String label;
  final Color accent;
  final VoidCallback? onTap;

  const _TopicChip({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: accent.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
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

// ─────────────────────────────────────────────────────────────────────────────
// 3. SmartReplyComputer (Service)
// ─────────────────────────────────────────────────────────────────────────────

/// Heuristischer Smart-Reply-Berechner.
///
/// Bewusst KEINE echte AI hier — Reply-Vorschlaege werden bei jedem
/// neuen Message angezeigt, das wuerde Tausende Worker-Calls pro
/// Stunde bedeuten. Pattern-Matching ist ausreichend gut.
class SmartReplyComputer {
  /// Berechnet GENAU 3 plausible Antwort-Vorschlaege.
  ///
  /// Reihenfolge der Pattern-Pruefung: spezifisch -> generisch.
  /// Gibt nie eine leere Liste zurueck.
  static List<String> computeQuick({
    required String lastMessageText,
    required String world,
  }) {
    final String text = lastMessageText.trim();
    if (text.isEmpty) {
      return const <String>['Verstehe.', 'Spannend!', 'Erzaehl mehr.'];
    }

    final String lower = text.toLowerCase();
    final bool isEnergie = world == 'energie';

    // Emoji-only Check (alle non-whitespace chars sind non-ASCII).
    final String stripped = text.replaceAll(RegExp(r'\s+'), '');
    final bool onlyEmoji = stripped.isNotEmpty &&
        !RegExp(r'[A-Za-z0-9äöüÄÖÜß]', unicode: true).hasMatch(stripped);
    if (onlyEmoji) {
      return const <String>['❤️', '🙌', '🌟'];
    }

    // Begruessung
    const List<String> greetings = <String>[
      'hallo', 'hi ', 'hey', 'servus', 'moin', 'guten morgen', 'guten abend',
      'guten tag', 'gruess', 'grüß',
    ];
    if (greetings.any((String g) => lower.startsWith(g)) ||
        greetings.any((String g) => lower.contains(g))) {
      return const <String>[
        'Hallo zurueck! ✨',
        'Hi 🌟',
        'Schoen dich zu lesen.',
      ];
    }

    // Dank
    if (lower.contains('danke') ||
        lower.contains('dank dir') ||
        lower.contains('thx') ||
        lower.contains('vielen dank')) {
      return const <String>['Gerne!', 'Immer 💛', 'Bitte sehr.'];
    }

    // Welt-spezifisch: Energie + Meditation/Mantra
    if (isEnergie &&
        (lower.contains('meditation') ||
            lower.contains('mantra') ||
            lower.contains('affirmation') ||
            lower.contains('chakra'))) {
      return const <String>[
        'Sehr inspirierend ✨',
        'Welche praktizierst du?',
        'Danke fuer den Hinweis',
      ];
    }

    // Tipp / Idee
    if (lower.contains('tipp') ||
        lower.contains('idee') ||
        lower.contains('vorschlag') ||
        lower.contains('rat ')) {
      return const <String>[
        'Probier mal aus.',
        'Spannender Ansatz',
        'Erzaehl mehr darueber',
      ];
    }

    // Frage
    if (text.endsWith('?') || lower.startsWith('wie ') ||
        lower.startsWith('was ') || lower.startsWith('warum ') ||
        lower.startsWith('wieso ') || lower.startsWith('weshalb ')) {
      return const <String>[
        'Ja, finde ich auch.',
        'Hmm, ich sehe es anders.',
        'Erzaehl mehr.',
      ];
    }

    // Zustimmung / Begeisterung
    if (lower.contains('genial') ||
        lower.contains('mega') ||
        lower.contains('wow') ||
        lower.contains('super') ||
        lower.contains('toll')) {
      return const <String>[
        'Finde ich auch! 🙌',
        'Absolut.',
        'Geht mir genauso.',
      ];
    }

    // Trauer / Sorge
    if (lower.contains('traurig') ||
        lower.contains('sorge') ||
        lower.contains('schwer') ||
        lower.contains('schwierig')) {
      return const <String>[
        'Das tut mir leid 💛',
        'Ich verstehe dich.',
        'Magst du mehr erzaehlen?',
      ];
    }

    // Default
    return const <String>['Verstehe.', 'Spannend!', 'Erzaehl mehr.'];
  }
}
