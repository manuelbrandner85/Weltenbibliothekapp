import 'package:flutter/material.dart';

import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/intel/intel_list_screen.dart';
import '../../../widgets/materie/osint_source_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Vorhang tools. Lobby radar & leaks search (GDELT, key-free) plus two curated
// knowledge tools: power networks and a symbol database.
// ─────────────────────────────────────────────────────────────────────────────

const Color _kGold = Color(0xFFC9A84C);
const Color _kVoSurface = Color(0xFF15130C);
const Color _kVoBg = Color(0xFF080806);

/// Lobby-Radar — Einfluss von Konzernen/Lobbys auf Politik (GDELT).
class LobbyRadarScreen extends StatelessWidget {
  const LobbyRadarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IntelListScreen(
      title: 'Lobby-Radar',
      icon: Icons.account_balance_rounded,
      accent: _kGold,
      world: WBWorld.vorhang,
      surface: _kVoSurface,
      background: _kVoBg,
      endpoint: '/api/intel/lobby',
      sourceText:
          'Aktuelle Medienberichte zu Lobbyismus, Konzern-Einfluss und '
          'Politik-Verflechtungen weltweit (GDELT-Nachrichtenanalyse). '
          'Zeigt, wer versucht politische Entscheidungen zu beeinflussen.',
      sources: const [OsintSource('GDELT Project', 'https://www.gdeltproject.org')],
      mapper: (e) => IntelRow(
        title: (e['title'] ?? '').toString(),
        subtitle: [
          (e['domain'] ?? '').toString(),
          (e['date'] ?? '').toString(),
        ].where((s) => s.isNotEmpty).join('  -  '),
        icon: Icons.account_balance_rounded,
        badgeColor: _kGold,
        url: (e['url'] ?? '').toString(),
      ),
    );
  }
}

/// Leaks-Suche — Enthuellungen & Whistleblower in Medien (GDELT).
class LeaksSearchScreen extends StatelessWidget {
  const LeaksSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IntelListScreen(
      title: 'Leaks-Suche',
      icon: Icons.lock_open_rounded,
      accent: _kGold,
      world: WBWorld.vorhang,
      surface: _kVoSurface,
      background: _kVoBg,
      endpoint: '/api/intel/leaks',
      sourceText:
          'Aktuelle Medienberichte zu Leaks, Whistleblowern und enthuellten '
          'Dokumenten weltweit (GDELT-Nachrichtenanalyse). Zum Aktualisieren '
          'nach unten ziehen.',
      sources: const [OsintSource('GDELT Project', 'https://www.gdeltproject.org')],
      mapper: (e) => IntelRow(
        title: (e['title'] ?? '').toString(),
        subtitle: [
          (e['domain'] ?? '').toString(),
          (e['date'] ?? '').toString(),
        ].where((s) => s.isNotEmpty).join('  -  '),
        icon: Icons.lock_open_rounded,
        badgeColor: _kGold,
        url: (e['url'] ?? '').toString(),
      ),
    );
  }
}

// ── Curated knowledge data ───────────────────────────────────────────────────

class _Entry {
  final String title;
  final String tag;
  final String body;
  const _Entry(this.title, this.tag, this.body);
}

const List<_Entry> _powerNetworks = [
  _Entry('Bilderberg-Konferenz', 'gegr. 1954',
      'Jaehrliches informelles Treffen von rund 130 Personen aus Politik, '
      'Wirtschaft, Hochfinanz und Medien. Tagungen unterliegen der Chatham-House-Regel '
      '(keine Zitate, keine Beschluesse oeffentlich). Kritiker sehen darin eine '
      'intransparente Einfluss-Plattform, Befuerworter ein offenes Diskussionsforum.'),
  _Entry('Trilaterale Kommission', 'gegr. 1973',
      'Von David Rockefeller mitgegruendet. Verbindet Eliten aus Nordamerika, '
      'Europa und Asien-Pazifik zur Foerderung enger Zusammenarbeit. '
      'Rund 400 Mitglieder aus Wirtschaft, Politik und Wissenschaft.'),
  _Entry('Council on Foreign Relations', 'gegr. 1921',
      'Einflussreicher US-Thinktank fuer Aussenpolitik mit Sitz in New York. '
      'Gibt die Zeitschrift "Foreign Affairs" heraus. Mitglieder sind viele '
      'fuehrende US-Diplomaten, Minister und Konzernchefs.'),
  _Entry('World Economic Forum', 'gegr. 1971',
      'Stiftung von Klaus Schwab, jaehrliches Treffen in Davos. Bringt '
      'Staats- und Konzernfuehrung zusammen ("Public-Private-Partnership"). '
      'Praegt Begriffe wie "Great Reset" und "Stakeholder-Kapitalismus".'),
  _Entry('Chatham House (RIIA)', 'gegr. 1920',
      'Britisches Royal Institute of International Affairs. Namensgeber der '
      '"Chatham-House-Regel" fuer vertrauliche Gespraeche. Eng mit dem '
      'US-CFR verbunden.'),
  _Entry('Atlantik-Bruecke', 'gegr. 1952',
      'Privater deutscher Verein zur Foerderung der deutsch-amerikanischen '
      'Beziehungen. Vernetzt Politik, Wirtschaft und Medien transatlantisch.'),
  _Entry('Bohemian Club / Grove', 'gegr. 1872',
      'Exklusiver US-Maennerclub mit jaehrlichem Treffen im "Bohemian Grove" '
      '(Kalifornien). Teilnehmer aus Politik, Wirtschaft und Kultur. '
      'Bekannt fuer das ritualisierte "Cremation of Care".'),
];

const List<_Entry> _symbols = [
  _Entry('Auge der Vorsehung', 'Allsehendes Auge',
      'Dreieck mit Auge, umgeben von Strahlen. Urspruenglich christliches '
      'Dreifaltigkeitssymbol (Gottes Allwissenheit). Spaeter in Freimaurerei '
      'und auf der US-Dollarnote (Grosses Siegel) verwendet.'),
  _Entry('Pyramide / Obelisk', 'Macht & Ewigkeit',
      'Altaegyptisches Symbol fuer Aufstieg, Hierarchie und Unsterblichkeit. '
      'Die unvollendete Pyramide auf dem Dollar steht fuer ein "work in progress". '
      'Obelisken (z.B. Washington Monument) als Macht-Marker im Stadtraum.'),
  _Entry('Zirkel & Winkel', 'Freimaurerei',
      'Wichtigstes Symbol der Freimaurer: Winkel (Materie/Erde) und Zirkel '
      '(Geist/Himmel), oft mit "G" (Geometrie/Gott). Steht fuer den moralischen '
      'Selbstbau des Menschen.'),
  _Entry('Eule', 'Weisheit & Geheimnis',
      'Symbol der Weisheit (Athene/Minerva), aber auch des Verborgenen und der '
      'Nacht. Im Bohemian Grove zentrale Figur (Moloch-Eule). Auf dem Dollar '
      'als verstecktes Detail.'),
  _Entry('Pentagramm', 'Fuenf Elemente',
      'Fuenfzackiger Stern. Aufrecht: Schutz, die fuenf Elemente, der Mensch '
      '(Leonardos vitruvianischer Mann). Umgekehrt: in manchen Stroemungen '
      'als Inversion gedeutet.'),
  _Entry('Doppeladler', 'Souveraenitaet',
      'Zweikoepfiger Adler: Herrschaft ueber Ost und West. Wappen von '
      'Byzanz, Habsburg, Russland - und Grad 33 des Schottischen Ritus '
      'der Freimaurerei.'),
  _Entry('Ouroboros', 'Ewiger Kreislauf',
      'Sich in den Schwanz beissende Schlange. Symbol fuer Unendlichkeit, '
      'zyklische Erneuerung und Einheit von Anfang und Ende. Alchemistisch '
      'fuer die Einheit der Materie.'),
  _Entry('Hexagramm', 'Wie oben so unten',
      'Sechszackiger Stern aus zwei Dreiecken (Feuer/Wasser, Himmel/Erde). '
      'Hermetisches Prinzip der Entsprechung; im Judentum Davidstern.'),
];

/// Macht-Netzwerke — kuratierte Wissens-Datenbank einflussreicher Netzwerke.
class PowerNetworksScreen extends StatelessWidget {
  const PowerNetworksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _CuratedListScreen(
      title: 'Macht-Netzwerke',
      icon: Icons.hub_rounded,
      entries: _powerNetworks,
      banner:
          'Kuratierte Wissens-Datenbank zu real existierenden, einflussreichen '
          'Netzwerken und Organisationen. Sachliche Darstellung - keine '
          'Verschwoerungs-Behauptungen. Bilde dir deine eigene Meinung.',
    );
  }
}

/// Symbol-Datenbank — kuratierte Symbol-Bedeutungen.
class SymbolDatabaseScreen extends StatelessWidget {
  const SymbolDatabaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _CuratedListScreen(
      title: 'Symbol-Datenbank',
      icon: Icons.auto_awesome_rounded,
      entries: _symbols,
      banner:
          'Kuratierte Sammlung historischer Symbole und ihrer dokumentierten '
          'Bedeutungen aus Religion, Mythologie und Geheimbuenden. '
          'Kulturhistorischer Kontext - keine Wertung.',
    );
  }
}

/// Shared expandable curated-knowledge list for Vorhang.
class _CuratedListScreen extends StatelessWidget {
  const _CuratedListScreen({
    required this.title,
    required this.icon,
    required this.entries,
    required this.banner,
  });

  final String title;
  final IconData icon;
  final List<_Entry> entries;
  final String banner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kVoBg,
      appBar: WBGlassAppBar(
        world: WBWorld.vorhang,
        titleWidget: Row(children: [
          Icon(icon, color: _kGold, size: 22),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OsintSourceBanner(source: banner, accent: _kGold, isDemo: true),
          ...entries.map(_card),
        ],
      ),
    );
  }

  Widget _card(_Entry e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _kVoSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGold.withValues(alpha: 0.25)),
      ),
      child: Theme(
        data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: _kGold,
          collapsedIconColor: _kGold,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(e.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(e.tag,
                style: TextStyle(color: _kGold.withValues(alpha: 0.8), fontSize: 12)),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(e.body,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                      height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}
