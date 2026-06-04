import 'package:flutter/material.dart';

import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/intel/intel_list_screen.dart';
import '../../../widgets/materie/osint_source_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Ursprung tools (key-free). Biodiversity (GBIF), tonight's sky
// (visibleplanets.dev), global nature events (EONET) and a curated database of
// indigenous peoples and their languages.
// ─────────────────────────────────────────────────────────────────────────────

const Color _kCyan = Color(0xFF00D4AA);
const Color _kUrSurface = Color(0xFF080818);
const Color _kUrBg = Color(0xFF050510);

/// Artenvielfalt — Biodiversitaet weltweit (GBIF).
class BiodiversityScreen extends StatelessWidget {
  const BiodiversityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IntelListScreen(
      title: 'Artenvielfalt',
      icon: Icons.pets_rounded,
      accent: _kCyan,
      world: WBWorld.ursprung,
      surface: _kUrSurface,
      background: _kUrBg,
      endpoint: '/api/intel/species',
      sourceText:
          'Aktuelle Arten-Beobachtungen aus der weltweiten GBIF-Datenbank '
          '(Global Biodiversity Information Facility). Zeigt dokumentierte '
          'Sichtungen von Lebewesen rund um den Planeten.',
      sources: const [OsintSource('GBIF', 'https://www.gbif.org')],
      mapper: (e) {
        final kingdom = (e['kingdom'] ?? '').toString();
        final country = (e['country'] ?? '').toString();
        final date = (e['date'] ?? '').toString();
        return IntelRow(
          title: (e['species'] ?? '').toString(),
          subtitle: [
            if (kingdom.isNotEmpty) kingdom,
            if (country.isNotEmpty) country,
            if (date.isNotEmpty) date,
          ].join('  -  '),
          icon: Icons.eco_rounded,
          badgeColor: _kCyan,
        );
      },
    );
  }
}

/// Sternenhimmel heute — sichtbare Planeten (visibleplanets.dev).
class NightSkyScreen extends StatelessWidget {
  const NightSkyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IntelListScreen(
      title: 'Sternenhimmel heute',
      icon: Icons.stars_rounded,
      accent: _kCyan,
      world: WBWorld.ursprung,
      surface: _kUrSurface,
      background: _kUrBg,
      endpoint: '/api/intel/starsky',
      sourceText:
          'Aktuell sichtbare Planeten und Himmelskoerper am Nachthimmel '
          '(Standard-Standort Mitteleuropa). Hoehe = Winkel ueber dem '
          'Horizont. Naturvoelker nutzten den Sternenhimmel seit jeher als '
          'Kalender und Orientierung.',
      sources: const [
        OsintSource('visibleplanets.dev', 'https://visibleplanets.dev')
      ],
      headerNote: 'Hoehe ueber 0 Grad = aktuell ueber dem Horizont sichtbar.',
      mapper: (e) {
        final alt = (e['altitude'] as num?)?.toDouble();
        final constellation = (e['constellation'] ?? '').toString();
        final mag = e['magnitude'];
        final visible = alt != null && alt > 0;
        return IntelRow(
          title: (e['name'] ?? '').toString(),
          subtitle: [
            if (constellation.isNotEmpty) 'Sternbild $constellation',
            if (alt != null) 'Hoehe ${alt.toStringAsFixed(0)} Grad',
            if (mag != null) 'Helligkeit $mag',
          ].join('  -  '),
          badge: visible ? 'sichtbar' : 'unter Horizont',
          badgeColor: visible ? _kCyan : Colors.white24,
          icon: Icons.brightness_high_rounded,
        );
      },
    );
  }
}

/// Naturphaenomene — Stuerme, Eis, Duerre weltweit (NASA EONET).
class NaturePhenomenaScreen extends StatelessWidget {
  const NaturePhenomenaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IntelListScreen(
      title: 'Naturphaenomene',
      icon: Icons.public_rounded,
      accent: _kCyan,
      world: WBWorld.ursprung,
      surface: _kUrSurface,
      background: _kUrBg,
      endpoint: '/api/intel/naturevents',
      sourceText:
          'Laufende Naturereignisse weltweit aus dem NASA Earth Observatory '
          '(EONET): Stuerme, Meereis, Duerren, Ueberschwemmungen und mehr. '
          'Der lebendige Planet in Echtzeit.',
      sources: const [OsintSource('NASA EONET', 'https://eonet.gsfc.nasa.gov')],
      mapper: (e) {
        final lat = (e['lat'] as num?)?.toDouble();
        final lon = (e['lon'] as num?)?.toDouble();
        return IntelRow(
          title: (e['title'] ?? '').toString(),
          subtitle: [
            (e['date'] ?? '').toString(),
            if (lat != null && lon != null)
              '${lat.toStringAsFixed(1)}, ${lon.toStringAsFixed(1)}',
          ].where((s) => s.isNotEmpty).join('  -  '),
          badge: (e['category'] ?? '').toString(),
          badgeColor: _kCyan,
          icon: Icons.cyclone_rounded,
        );
      },
    );
  }
}

// ── Curated: indigenous peoples & languages ──────────────────────────────────

class _People {
  final String name;
  final String region;
  final String language;
  final String body;
  const _People(this.name, this.region, this.language, this.body);
}

const List<_People> _peoples = [
  _People('Sentinelesen', 'Nord-Sentinel-Insel (Indien)', 'Sentinelesisch',
      'Eines der letzten unkontaktierten Voelker der Erde. Lehnen jeden '
      'Kontakt zur Aussenwelt ab; ihre Sprache ist voellig unklassifiziert.'),
  _People('San (Khoisan)', 'Suedliches Afrika (Kalahari)', 'Khoisan (Klick-Sprachen)',
      'Eines der genetisch aeltesten Voelker der Menschheit. Ihre Sprachen '
      'nutzen einzigartige Klick-Laute. Traditionell Jaeger und Sammler.'),
  _People('Yanomami', 'Amazonas (Brasilien/Venezuela)', 'Yanomami',
      'Grosses indigenes Volk des Regenwaldes, lebt halbnomadisch in '
      'Gemeinschaftshaeusern (Shabono). Tiefes Wissen ueber Heilpflanzen.'),
  _People('Sami', 'Sapmi (Nordskandinavien)', 'Samisch',
      'Einziges anerkanntes indigenes Volk der EU. Traditionell Rentier-'
      'Nomaden. Eigene Parlamente in Norwegen, Schweden und Finnland.'),
  _People('Aborigines', 'Australien', 'ueber 250 Sprachen',
      'Aelteste durchgehende Kultur der Welt (ueber 65.000 Jahre). '
      '"Traumzeit" (Dreamtime) als Kosmologie. Songlines als Wissensspeicher.'),
  _People('Inuit', 'Arktis (Groenland/Kanada/Alaska)', 'Inuktitut',
      'Arktische Voelker mit tiefem Wissen ueber Eis, Jagd und Ueberleben '
      'in extremer Kaelte. Bekannt fuer detaillierten Wortschatz fuer Schnee.'),
  _People('Maori', 'Neuseeland (Aotearoa)', 'Te Reo Maori',
      'Polynesisches Volk mit reicher muendlicher Tradition (Whakapapa = '
      'Genealogie). Haka als rituelle Performance. Sprache offiziell anerkannt.'),
  _People('Quechua', 'Anden (Peru/Bolivien/Ecuador)', 'Quechua / Runasimi',
      'Nachkommen der Inka, groesste indigene Sprachfamilie Amerikas '
      '(ueber 8 Mio. Sprecher). "Pachamama" (Mutter Erde) als zentrales Konzept.'),
  _People('Ainu', 'Hokkaido (Japan)', 'Ainu',
      'Indigenes Volk Nordjapans mit animistischer Religion (Kamuy = '
      'Geister/Goetter). Sprache stark bedroht, eigenstaendige Sprachfamilie.'),
  _People('Pirahã', 'Amazonas (Brasilien)', 'Pirahã',
      'Kleines Volk mit einer Sprache ohne Zahlwoerter und (umstritten) ohne '
      'Rekursion - bedeutsam fuer die Sprachwissenschaft. Fokus auf das '
      'unmittelbar Erfahrbare.'),
];

/// Indigene Sprachen — kuratierte Datenbank von Naturvoelkern & Sprachen.
class IndigenousLanguagesScreen extends StatelessWidget {
  const IndigenousLanguagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kUrBg,
      appBar: WBGlassAppBar(
        world: WBWorld.ursprung,
        titleWidget: Row(children: const [
          Icon(Icons.translate_rounded, color: _kCyan, size: 22),
          SizedBox(width: 8),
          Text('Indigene Sprachen',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const OsintSourceBanner(
            source:
                'Kuratierte Wissens-Datenbank zu Naturvoelkern und ihren '
                'Sprachen. Viele dieser Sprachen sind vom Aussterben bedroht '
                'und bewahren einzigartiges Wissen ueber Natur und Kosmos.',
            accent: _kCyan,
            isDemo: true,
          ),
          ..._peoples.map(_card),
        ],
      ),
    );
  }

  Widget _card(_People p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _kUrSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kCyan.withValues(alpha: 0.25)),
      ),
      child: Theme(
        data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: _kCyan,
          collapsedIconColor: _kCyan,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(p.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('${p.region}  -  ${p.language}',
                style: TextStyle(
                    color: _kCyan.withValues(alpha: 0.8), fontSize: 12)),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(p.body,
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
