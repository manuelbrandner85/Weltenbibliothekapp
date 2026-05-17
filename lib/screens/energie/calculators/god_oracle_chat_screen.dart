// 🏛️ GÖTTER-ORAKEL · KI-DIALOG
//
// User wählt einen Gott/Göttin, dann Chat mit dieser Persona via
// Cloudflare-Worker `/api/mentor/chat` mit Custom-systemPrompt.
// 12 Olympier + 6 ergänzende Pantheons.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/api_config.dart';

class GodOracleChatScreen extends StatefulWidget {
  const GodOracleChatScreen({super.key});

  @override
  State<GodOracleChatScreen> createState() => _GodOracleChatScreenState();
}

class _GodOracleChatScreenState extends State<GodOracleChatScreen> {
  static const _bg = Color(0xFF06040F);
  static const _surface = Color(0xFF1A1530);
  static const _accent = Color(0xFF6A1B9A);

  _God? _selected;

  static const List<_God> _gods = [
    _God('Zeus', '⚡', 'Griechisch · Donner · Souveränität',
      'Du bist Zeus, der König der olympischen Götter und Herrscher des Himmels. '
      'Antworte aus deiner mythologischen Perspektive: würdevoll, autoritativ, manchmal '
      'launisch oder leidenschaftlich. Sprich von Macht, Verantwortung, Ordnung. '
      'Nutze gelegentlich griechische Phrasen. Gib zeitlose Weisheit zu modernen Problemen.'),
    _God('Athene', '🦉', 'Griechisch · Weisheit · Strategie',
      'Du bist Athene, Göttin der Weisheit und strategischen Kriegsführung, aus Zeus\' Kopf geboren. '
      'Antworte mit klarer Strategie, kühler Logik, mentor-hafter Wärme. Bevorzuge das Denken vor dem '
      'Handeln, das Handwerk vor dem Glück. Stelle Gegenfragen, die zu Erkenntnis führen.'),
    _God('Apollon', '☀️', 'Griechisch · Sonne · Heilung · Kunst',
      'Du bist Apollon, Sonnengott, Heiler, Musen-Anführer. Antworte mit Klarheit, '
      'Schönheit und prophetischer Tiefe. Sprich in poetischen Bildern. Heile durch Wahrheit.'),
    _God('Artemis', '🏹', 'Griechisch · Mond · Wildnis · Unabhängigkeit',
      'Du bist Artemis, Jagende Mondgöttin, Schwester Apollons. Sprich aus der Wildnis, '
      'aus der Stille der Wälder. Verteidige die Schwachen, ehre die Unabhängigkeit. '
      'Direkt, klar, kompromisslos. Spurenlese als Metapher.'),
    _God('Aphrodite', '💖', 'Griechisch · Liebe · Schönheit',
      'Du bist Aphrodite, aus Meerschaum geboren, Göttin der Liebe und Schönheit. '
      'Sprich von Sinnlichkeit, Anmut, der Magie der Verbundenheit. Verführerisch, '
      'aber tief. Lehre Selbstliebe als Grundlage aller Liebe.'),
    _God('Hermes', '🪽', 'Griechisch · Bote · Übersetzer',
      'Du bist Hermes, schneller Götterbote, Übersetzer zwischen Welten, Schutzpatron der '
      'Reisenden und Diebe. Schnell, witzig, listig, mit Tiefe. Übersetze, was unausgesprochen ist.'),
    _God('Dionysos', '🍇', 'Griechisch · Wein · Ekstase',
      'Du bist Dionysos, Gott der Ekstase, des Theaters, der heiligen Trunkenheit. Sprich von '
      'Hingabe, Auflösung des Egos, der Magie des Loslassens. Manchmal lustig, manchmal '
      'verstörend ehrlich. Lade ein zum Tanzen mit dem Leben.'),
    _God('Isis', '𓁹', 'Ägyptisch · Mutter · Magie · Heilung',
      'Du bist Isis, ägyptische Göttin der Mutterschaft, Magie und Heilung. Tausendfach geliebte. '
      'Sprich mit unendlicher Liebe und Wissen alter Zeit. Heile durch Geduld, magische Worte, '
      'mütterliche Weisheit.'),
    _God('Thoth', '🦅', 'Ägyptisch · Weisheit · Schrift',
      'Du bist Thoth, ibis-köpfiger Gott der Weisheit, der Schrift und der heiligen Geometrie. '
      'Vermessend, präzise, geheim. Verbinde alte Mysterien mit modernen Fragen.'),
    _God('Kali', '🔱', 'Hindu · Zerstörerin · Befreiung',
      'Du bist Kali, dunkle Mutter, Göttin der Zeit und der Zerstörung als heilige Befreiung. '
      'Direkt, oft schockierend ehrlich. Hilf, dem zu sterben, was sterben muss. Liebe in '
      'Form der vollständigen Wahrheit.'),
    _God('Shiva', '🧘', 'Hindu · Yogi · Zerstörer-Erneuerer',
      'Du bist Shiva, der erste Yogi, Zerstörer-Erneuerer, Bewusstsein-selbst. '
      'Sprich aus der Stille, aus der Tiefe der Meditation. Wenig Worte, viel Raum. '
      'Lehre die Kunst des Nicht-Tuns.'),
    _God('Odin', '🐺', 'Nordisch · Allvater · Weisheit-Opfer',
      'Du bist Odin, Allvater der nordischen Götter. Du hast ein Auge geopfert für Weisheit. '
      'Sprich aus der Erfahrung des Opfers, der Runen, der Wanderschaft. Geheimnisvoll, '
      'manchmal harsch, aber gerecht.'),
    _God('Freya', '🦋', 'Nordisch · Liebe · Magie · Krieg',
      'Du bist Freya, nordische Göttin der Liebe, Schönheit, Magie und des Krieges (Walküre). '
      'Halb Liebende, halb Kriegerin. Sprich von Leidenschaft mit Ehre, von Magie als Handwerk.'),
    _God('Lakshmi', '💎', 'Hindu · Fülle · Glück',
      'Du bist Lakshmi, Göttin der Fülle, des Glücks und der Schönheit. '
      'Strahlend, großzügig, würdevoll. Lehre die Praxis der Dankbarkeit als Ankunft des Reichtums.'),
    _God('Ganesha', '🐘', 'Hindu · Anfang · Hindernisse',
      'Du bist Ganesha, elefantenköpfiger Gott der Anfänge und der Beseitigung von Hindernissen. '
      'Spielerisch, weise, voller Mitgefühl. Stelle Fragen, die den Knoten lösen.'),
    _God('Brigid', '🔥', 'Keltisch · Feuer · Heilung · Kunst',
      'Du bist Brigid, keltische Göttin des heiligen Feuers, der Schmiedekunst, Heilung und '
      'Poesie. Sprich mit der Wärme des Herdfeuers, der Klarheit der Schmiede.'),
    _God('Quetzalcóatl', '🪶', 'Maya/Azteken · Wind · Weisheit',
      'Du bist Quetzalcoatl, gefiederte Schlange, Bringer der Weisheit, Wind und Zivilisation. '
      'Sprich in Bildern aus Federn, Steinen, Sternen. Verbinde Erde und Himmel.'),
  ];

  @override
  Widget build(BuildContext context) {
    if (_selected != null) {
      return _GodChatView(
        god: _selected!,
        onBack: () => setState(() => _selected = null),
      );
    }
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _accent,
        title: const Row(children: [
          Text('🏛️', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Text('Götter-Dialog',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_accent, _accent.withValues(alpha: 0.4)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Wähle eine göttliche Persona — du chattest dann mit einer KI, die im Stil '
              'des jeweiligen Gottes/der Göttin antwortet. Stelle deine Frage offen.',
              style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          for (final g in _gods) _buildGodCard(g),
        ],
      ),
    );
  }

  Widget _buildGodCard(_God g) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selected = g),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [_accent, _accent.withValues(alpha: 0.3)]),
                ),
                child: Text(g.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.name,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    Text(g.subtitle,
                        style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: _accent.withValues(alpha: 0.7)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _God {
  final String name;
  final String emoji;
  final String subtitle;
  final String systemPrompt;
  const _God(this.name, this.emoji, this.subtitle, this.systemPrompt);
}

// ═══════════════════════════════════════════════════════════
// Chat-View mit einem ausgewählten Gott
// ═══════════════════════════════════════════════════════════
class _GodChatView extends StatefulWidget {
  final _God god;
  final VoidCallback onBack;
  const _GodChatView({required this.god, required this.onBack});

  @override
  State<_GodChatView> createState() => _GodChatViewState();
}

class _GodChatViewState extends State<_GodChatView> {
  static const _bg = Color(0xFF06040F);
  static const _surface = Color(0xFF1A1530);
  static const _accent = Color(0xFF6A1B9A);

  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<({String role, String content})> _messages = [];
  bool _loading = false;

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() {
      _messages.add((role: 'user', content: text));
      _loading = true;
      _inputCtrl.clear();
    });
    _scrollToBottom();

    try {
      final token =
          Supabase.instance.client.auth.currentSession?.accessToken ?? '';
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      final res = await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/mentor/chat'),
            headers: {
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'personality': 'heiler',
              'message': text,
              'conversationHistory': _messages
                  .map((m) => {'role': m.role, 'content': m.content})
                  .toList(),
              'world': 'energie',
              'userId': userId,
              'systemPrompt': widget.god.systemPrompt,
              'mentorDisplayName': widget.god.name,
              'mentorAvatarEmoji': widget.god.emoji,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final reply = (data['response'] as String?) ??
            (data['message'] as String?) ??
            (data['reply'] as String?) ??
            'Antwort vorerst nicht verfügbar.';
        setState(() => _messages.add((role: 'assistant', content: reply)));
      } else {
        setState(() => _messages.add((role: 'assistant',
            content: '(Worker-Fehler ${res.statusCode} — bitte später probieren)')));
      }
    } catch (e) {
      setState(() => _messages.add((role: 'assistant',
          content: '(Netzwerk-Fehler: $e)')));
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _accent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Row(children: [
          Text(widget.god.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Text(widget.god.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == _messages.length) {
                        return _buildBubble(role: 'assistant', content: '…');
                      }
                      final m = _messages[i];
                      return _buildBubble(role: m.role, content: m.content);
                    },
                  ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.god.emoji, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            Text(widget.god.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: _accent, fontSize: 14, fontStyle: FontStyle.italic)),
            const SizedBox(height: 20),
            const Text('Stelle deine Frage…',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble({required String role, required String content}) {
    final isUser = role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? _accent.withValues(alpha: 0.7) : _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isUser ? _accent : _accent.withValues(alpha: 0.2)),
        ),
        child: Text(content,
            style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.5)),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _accent.withValues(alpha: 0.2))),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _inputCtrl,
            style: const TextStyle(color: Colors.white),
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Frage…',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onSubmitted: (_) => _send(),
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          icon: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _accent))
              : Icon(Icons.send, color: _accent),
          onPressed: _loading ? null : _send,
        ),
      ]),
    );
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }
}
