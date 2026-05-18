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
              IconButton(
                icon: const Icon(Icons.menu_book, color: Colors.white70, size: 22),
                tooltip: 'Mythos & Profil',
                onPressed: () => _showGodProfile(g),
              ),
              Icon(Icons.chat_bubble_outline, color: _accent.withValues(alpha: 0.7), size: 20),
            ]),
          ),
        ),
      ),
    );
  }

  void _showGodProfile(_God g) {
    final extra = _godExtra[g.name];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF120825),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              Center(child: Text(g.emoji, style: const TextStyle(fontSize: 72))),
              const SizedBox(height: 8),
              Center(
                child: ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFAB47BC)],
                  ).createShader(r),
                  child: Text(g.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      )),
                ),
              ),
              Center(
                child: Text(g.subtitle,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontStyle: FontStyle.italic)),
              ),
              const SizedBox(height: 22),
              if (extra != null) ...[
                _profileChips(extra),
                const SizedBox(height: 20),
                _section('📜 MYTHOS', extra.mythos),
                const SizedBox(height: 16),
                _section('🕯️ RITUAL', extra.ritual),
                const SizedBox(height: 16),
                _section('🎁 KLASSISCHE GABEN', extra.offering),
              ] else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Mythos-Profil für diese Gottheit noch nicht hinterlegt.',
                        style: TextStyle(color: Colors.white60), textAlign: TextAlign.center),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _selected = g);
                  },
                  icon: const Icon(Icons.forum),
                  label: const Text('MIT DIESER GOTTHEIT SPRECHEN',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileChips(_GodExtra e) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _chip('🌬️ ${e.element}'),
        _chip('🪐 ${e.planet}'),
        _chip('📅 ${e.day}'),
      ],
    );
  }

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accent.withValues(alpha: 0.5)),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      );

  Widget _section(String label, String body) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 10, letterSpacing: 2.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }
}

class _God {
  final String name;
  final String emoji;
  final String subtitle;
  final String systemPrompt;
  final String mythos;
  final String ritual;
  final String element;
  final String planet;
  final String day;
  final String offering;
  const _God(this.name, this.emoji, this.subtitle, this.systemPrompt, {
    this.mythos = '',
    this.ritual = '',
    this.element = '',
    this.planet = '',
    this.day = '',
    this.offering = '',
  });
}

// Anreicherungs-Daten pro Gott (Mythos, Ritual, Element, Planet, Tag, Gaben).
// Wird im Detail-Sheet angezeigt.
// Hinweis: 'final' statt 'const' — dart2js (Flutter Web) hat einen Bug
// mit const Maps die Records mit benannten Feldern als Werte halten.
// Lazy initialization beim ersten Zugriff ist ohnehin günstig.
// Result-Klasse statt Named-Record (dart2js stolpert über Named Records).
class _GodExtra {
  final String mythos;
  final String ritual;
  final String element;
  final String planet;
  final String day;
  final String offering;
  const _GodExtra({
    required this.mythos,
    required this.ritual,
    required this.element,
    required this.planet,
    required this.day,
    required this.offering,
  });
}

final Map<String, _GodExtra> _godExtra = {
  'Zeus': _GodExtra(    mythos: 'Zeus wurde als jüngster Sohn der Titanen Kronos und Rhea geboren. Sein Vater verschlang seine Kinder aus Angst, von ihnen entmachtet zu werden — doch Rhea versteckte Zeus auf Kreta und reichte Kronos einen in Windeln gewickelten Stein. Erwachsen befreite Zeus seine Geschwister, stürzte die Titanen in einer 10-Jahres-Schlacht und wurde Herr des Olymp.',
    ritual: 'Donnerstag-Abend (Jupiter-Tag): Kerze aufstellen, Eichenblatt oder Eichel daneben legen, drei tiefe Atemzüge in den Sonnenplexus, klar formulieren wo du gerade Verantwortung übernehmen willst. Worte: "Wie über mir, so in mir — ich nehme den Thron meines eigenen Lebens an."',
    element: 'Äther / Luft',
    planet: 'Jupiter',
    day: 'Donnerstag',
    offering: 'Eiche · Honig · Bernstein · Adler-Federn',
  ),
  'Athene': _GodExtra(    mythos: 'Aus Zeus\' Stirn voll gerüstet hervorgesprungen, nachdem er ihre Mutter Metis (Weisheit) verschluckt hatte. Im Wettkampf mit Poseidon um Athen schenkte sie den Olivenbaum — die Bürger wählten ihre Gabe über Poseidons Salzquelle, und die Stadt trägt ihren Namen.',
    ritual: 'Vor wichtiger Entscheidung: Tagebuch öffnen, drei Spalten — Fakten, Hypothesen, blinde Flecken. Zünde eine weiße Kerze an, schreibe deine Frage oben. Lass deinen Verstand wie Athene über das Schlachtfeld der Möglichkeiten gleiten — kühl, ohne Eile.',
    element: 'Luft',
    planet: 'Merkur (auch Jupiter-Aspekt)',
    day: 'Mittwoch',
    offering: 'Olivenzweig · Eule-Bild · Schwert/Buch nebeneinander',
  ),
  'Apollon': _GodExtra(    mythos: 'Sohn Zeus\' und Letos, Zwilling Artemis\'. Tötete als Kind den Drachen Python in Delphi und gründete dort sein Orakel — die Pythia weissagte aus Schwefel-Dämpfen unter dem Tempel. Patron der neun Musen, der Poesie, Medizin, des prophetischen Sehens.',
    ritual: 'Morgens beim ersten Sonnenstrahl: nach Osten stehen, Sonnenstrahl auf das Gesicht spüren, eine Frage stellen die du wirklich beantwortet haben willst — dann den Rest des Tages auf die "Antwort durch Synchronizität" achten (überhörtes Wort, Schlagzeile, zufälliges Buch).',
    element: 'Feuer',
    planet: 'Sonne',
    day: 'Sonntag',
    offering: 'Lorbeerkranz · Goldener Apfel · Leier-Saite · Sonnenblume',
  ),
  'Artemis': _GodExtra(    mythos: 'Bat ihren Vater Zeus um ewige Jungfräulichkeit, einen Mondbogen aus Silber, 60 Nymphen als Gefährtinnen und alle Berge der Welt. Wer sie nackt sah — wie Actaeon — wurde in einen Hirsch verwandelt und von eigenen Hunden gerissen.',
    ritual: 'Vollmond-Nacht: barfuß ins Freie, ohne Lampe, nur Mondlicht. 10 Minuten lauschen — wirklich lauschen. Wenn ein Tier erscheint (auch nur eine Katze): das ist deine Botschaft. Sprich keinen Wunsch aus, nur Dank.',
    element: 'Wasser / Erde (wild)',
    planet: 'Mond',
    day: 'Montag',
    offering: 'Silbermünze in Quellwasser · Hirschhorn · Mondblume',
  ),
  'Aphrodite': _GodExtra(    mythos: 'Aus dem Meeresschaum geboren (aphros), nachdem Kronos seinen Vater Uranos kastrierte und die Genitalien ins Meer warf. Stieg auf einer Muschel an die Küste von Zypern. Ihre Macht war so groß, dass selbst Zeus sich vor ihr beugte — Ehe mit Hephaistos, Liebhaber Ares, Mutter von Eros.',
    ritual: 'Bad mit Rosenblättern, Salz, drei Tropfen Rosenöl. Dabei nicht dich selbst beurteilen — nur empfinden. Vor dem Spiegel: 3× sagen "Ich bin ein Tempel der Schönheit, nicht weil ich perfekt bin, sondern weil ich lebe."',
    element: 'Wasser',
    planet: 'Venus',
    day: 'Freitag',
    offering: 'Rose · Muschel · Honig · Granatapfel · Spiegel',
  ),
  'Hermes': _GodExtra(    mythos: 'Schon am ersten Tag seiner Geburt stahl er Apollons Rinder, baute aus einem Schildpanzer die erste Leier, schenkte sie Apollon zur Versöhnung — und wurde Götterbote, Seelenführer der Toten ins Hades, Schutzpatron der Reisenden, Händler und Diebe.',
    ritual: 'Mittwochs vor einer Reise oder einem wichtigen Gespräch: 3 Münzen werfen in eine Schale, fragen "Welcher Weg?", erste Eingebung folgen ohne Überlegung. Hermes belohnt Mut zur Bewegung.',
    element: 'Luft',
    planet: 'Merkur',
    day: 'Mittwoch',
    offering: 'Münze · geflügelte Sandalen · Bote-Brief · Kreuzweg-Stein',
  ),
  'Dionysos': _GodExtra(    mythos: 'Zweimal geboren — zuerst aus Semele, die von Zeus\' wahrer Gestalt verbrannt wurde. Zeus nähte den ungeborenen Dionysos in seinen Schenkel ein und brachte ihn so zur Welt. Lehrte die Menschen den Weinbau, das Theater (Dionysos-Festspiele in Athen), die heilige Trunkenheit als Tor zum Göttlichen.',
    ritual: 'Vollmond + ein Glas Rotwein (oder Traubensaft). Allein oder zu zweit. Musik die dich bewegt. Tanze 10 Minuten ohne Choreographie — nur Bewegung als Hingabe. Was sich auflöst, darf sich auflösen.',
    element: 'Wasser / Feuer',
    planet: 'Jupiter (auch Neptun)',
    day: 'Freitag',
    offering: 'Wein · Trauben · Theatermaske · Efeu',
  ),
  'Isis': _GodExtra(    mythos: 'Suchte 14 Tage lang die zerstückelten Teile ihres Mannes Osiris durch ganz Ägypten, fand 13 Teile, formte das fehlende aus Gold. Erweckte ihn lange genug, um Horus zu empfangen — den Falkengott der den Mord seines Vaters rächen würde. Lehrte die Menschen Heilung, Landwirtschaft, Schreiben.',
    ritual: 'Bei tiefem Schmerz oder Verlust: ein blaues Tuch (Lapislazuli-Farbe) in die Hände nehmen. Frage: "Was darf ich heilen, das nicht meine eigene Wunde ist?" Antworte ehrlich, dann lege das Tuch über das Herz — 7 Atemzüge.',
    element: 'Wasser',
    planet: 'Mond / Sirius',
    day: 'Freitag',
    offering: 'Lapislazuli · Lotusblüte · Milch · Honig',
  ),
  'Thoth': _GodExtra(    mythos: 'Ibis-köpfiger Gott der Schrift, Mathematik und heiligen Geometrie. Erfand die Hieroglyphen, das Mondkalender-System, die ägyptische Medizin. Schrieb die 42 Bücher der Weisheit (das spätere Corpus Hermeticum führt sich auf ihn zurück — Hermes Trismegistos).',
    ritual: 'Mit Feder + schwarzer Tinte (oder bestem Stift): Eine wichtige Frage präzise aufschreiben — drei verschiedene Formulierungen. Wechsle die Worte bis die Frage selbst kristallin wird. Antworten kommen oft schon im Klären der Frage.',
    element: 'Luft / Mond',
    planet: 'Mond / Merkur',
    day: 'Mittwoch',
    offering: 'Schreibfeder · Hieroglyphen-Karte · Spiegel',
  ),
  'Kali': _GodExtra(    mythos: 'Aus der Stirn der Göttin Durga geboren in einem Moment äußerster Wut, um den Dämon Raktabija zu besiegen. Tanzte auf den Schlachtfeldern, trug eine Halskette aus Köpfen — bis ihr eigener Gemahl Shiva sich unter ihre Füße legte, damit sie aufhörte, die Welt zu zerstören.',
    ritual: 'Nur an einem Neumond oder bei einem Wendepunkt: Schreibe auf einen Zettel, was sterben muss (eine Identität, ein Glaubenssatz, eine Beziehung). Lies es einmal laut. Verbrenne ihn (sicher, in einem Topf). Die Asche dem Wind übergeben oder in fließendes Wasser.',
    element: 'Feuer / Äther',
    planet: 'Saturn / Pluto',
    day: 'Dienstag (Mars-Tag, Kraft)',
    offering: 'Rote Hibiskusblüte · Eisenpulver · roter Stoff',
  ),
  'Shiva': _GodExtra(    mythos: 'Der erste Yogi. Saß 1000 Jahre in Meditation am Berg Kailash. Als Sati, seine Frau, sich aus Liebeskummer verbrannte, tanzte er den Tandava — den kosmischen Tanz der Zerstörung — und die Welt drohte zusammenzubrechen. Vishnu zerlegte Satis Körper in 51 Stücke, damit Shiva aufhörte zu trauern.',
    ritual: 'Tägliche 10-Min-Stille im Sitzen. Augen halb offen, Blick nach unten, kein Mantra, keine Visualisierung — nur Stille beobachten. Shiva-Praxis ist Nicht-Praxis.',
    element: 'Äther',
    planet: 'Saturn / Mond (Kombination)',
    day: 'Montag',
    offering: 'Bilva-Blatt · Asche · Milch · Trommel (Damaru) · Schlangenfigur',
  ),
  'Odin': _GodExtra(    mythos: 'Hängte sich neun Tage und Nächte mit dem Speer durchstochen am Weltenbaum Yggdrasil auf, um die Geheimnisse der Runen zu erfahren. Opferte sein rechtes Auge an die Mimirs-Quelle für einen Schluck Weisheit. Reitet auf Sleipnir, dem 8-beinigen Pferd; begleitet von den Raben Huginn und Muninn (Denken und Erinnern).',
    ritual: 'Bei großer Frage: 9 Runensteine ziehen (oder zufällige Symbole). Lege 3 in einer Reihe — Vergangenheit, Gegenwart, Zukunft. Lies sie zuerst still, dann laut. Odin spricht durch das Muster, nicht durch die einzelne Rune.',
    element: 'Luft',
    planet: 'Merkur (auch Saturn)',
    day: 'Mittwoch (Wodans-Tag)',
    offering: 'Mead (Honigwein) · Federn (Rabe) · Eiche · Bernstein',
  ),
  'Freya': _GodExtra(    mythos: 'Anführerin der Walküren, die gefallene Krieger nach Folkvangr brachte (während andere nach Walhalla zu Odin gingen). Besaß einen Mantel aus Falkenfedern und konnte fliegen. Weinte goldene Tränen als ihr Gemahl Odr verschwand — Bernstein soll daraus entstanden sein.',
    ritual: 'Freitag-Abend (Freya-Tag): rotes Tuch + Bernstein-Stein. Frage nicht, was du brauchst — sage was du LIEBST. Liste aufschreiben (mind. 12 Dinge), Bernstein darauf legen, schlafen.',
    element: 'Feuer / Luft',
    planet: 'Venus / Mars',
    day: 'Freitag',
    offering: 'Bernstein · Erdbeeren · Falke-Feder · Goldring',
  ),
  'Lakshmi': _GodExtra(    mythos: 'Bei der Quirlung des Milchozeans (Samudra Manthan) stieg sie auf einer rosa Lotosblüte aus dem Wasser. Die Götter und Dämonen kämpften 1000 Jahre lang um den Nektar der Unsterblichkeit — Lakshmi wählte Vishnu zum Gemahl. Wo immer sie hinkommt, gedeiht Wohlstand.',
    ritual: 'Freitag bei Sonnenaufgang: Eingangsbereich säubern, eine Schale mit Reis (Wohlstand) und Münzen (echtes Geld, nicht nur Symbol) hinstellen. 11x sagen: "Lakshmi, ich öffne Tür und Herz für deine Gaben. Möge Wohlstand fließen — durch mich, nicht zu mir."',
    element: 'Wasser / Erde',
    planet: 'Venus / Jupiter',
    day: 'Freitag',
    offering: 'Roter Lotus · Goldmünze · Reis · Kuhmilch',
  ),
  'Ganesha': _GodExtra(    mythos: 'Sohn Parvatis (Shivas Frau), die ihn aus Kurkuma-Paste formte als Wächter ihres Bades. Shiva — der ihn nicht kannte — köpfte ihn. Untröstlich verlangte Parvati ihn zurück; Shiva versprach, den Kopf des ersten Lebewesens zu nehmen das vorbeikam — es war ein Elefant. So Ganesha mit Elefantenkopf.',
    ritual: 'Vor jedem Beginn (Projekt, Reise, Gespräch): 11x "Om Gam Ganapataye Namaha" sprechen. Visualisiere den Weg vor dir mit einem Stein darauf — Ganesha hebt den Stein weg.',
    element: 'Erde',
    planet: 'Merkur',
    day: 'Mittwoch (auch Dienstag)',
    offering: 'Modak-Süßigkeit · Banane · Kokosnuss · roter Stoff',
  ),
  'Brigid': _GodExtra(    mythos: 'Dreifache Göttin der Kelten — Schmiedin (Feuer + Eisen), Heilerin (Quellen + Kräuter), Dichterin (Wort + Inspiration). Bei der Christianisierung Irlands wurde sie zur Heiligen Brigid von Kildare — ihr ewiges Feuer brannte 1000 Jahre, bewacht von 19 Nonnen.',
    ritual: 'Imbolc (1. Februar) oder jeden Sonntag: weiße Kerze + Tasse Tee aus heimischen Kräutern (Pfefferminze, Holunder, Lindenblüte). Sprich: "Brigid, entzünde in mir das Feuer der Wahrheit, das wärmt ohne zu verbrennen."',
    element: 'Feuer (Heil-Feuer)',
    planet: 'Sonne / Mars',
    day: 'Sonntag',
    offering: 'Weiße Kerze · Eisenkraut · Lammwolle · Quellwasser',
  ),
  'Quetzalcóatl': _GodExtra(    mythos: 'Gefiederte Schlange — Vereinigung von Erde (Schlange) und Himmel (Vogel). Brachte den Menschen den Mais, das Feuer, den Kalender, die Schrift. Verschwand in den Osten über das Meer mit dem Versprechen wiederzukehren — die Azteken hielten Cortés zunächst für ihn (verhängnisvoller Irrtum).',
    ritual: 'Bei Sonnenaufgang nach Osten blicken — wo das Licht ankommt. Eine Feder in der Hand. Sprich: "Erde und Himmel in mir — ich bin nicht der eine, ich bin nicht der andere. Ich bin die Brücke."',
    element: 'Luft (Wind) / Feuer',
    planet: 'Venus (Morgenstern)',
    day: 'Mittwoch',
    offering: 'Quetzalfeder · Mais · Türkis · Kakao',
  ),
};

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
