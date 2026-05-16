import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class VorhangMapTab extends StatefulWidget {
  const VorhangMapTab({super.key});

  @override
  State<VorhangMapTab> createState() => _VorhangMapTabState();
}

class _PowerCenter {
  final String name, description, badge, founded, influence;
  final List<String> members, connections;
  final double lat, lng;

  const _PowerCenter({
    required this.name,
    required this.description,
    required this.badge,
    required this.founded,
    required this.influence,
    required this.lat,
    required this.lng,
    this.members = const [],
    this.connections = const [],
  });
}

const _centers = [
  _PowerCenter(
    name: 'World Economic Forum',
    badge: 'WEF',
    founded: 'Gegründet 1971, Klaus Schwab',
    description:
        'Jährliches Treffen in Davos, Schweiz. Bringt ~3.000 Führungspersönlichkeiten aus Wirtschaft, Politik und Zivilgesellschaft zusammen. Bekannt für Agenda-Setting in Bereichen wie "Great Reset" und "Fourth Industrial Revolution".',
    influence: 'Wirtschaft · Politik · Medien',
    lat: 46.80,
    lng: 9.84,
    members: ['Klaus Schwab', 'Bill Gates', 'Christine Lagarde', 'Xi Jinping (2017)'],
    connections: ['Trilaterale Kommission', 'CFR', 'BIS'],
  ),
  _PowerCenter(
    name: 'Bilderberg-Gruppe',
    badge: 'Bilderberg',
    founded: 'Gegründet 1954, Prince Bernhard',
    description:
        'Jährliches Geheimtreffen ca. 120–150 Eingeladener aus Westeuropa und Nordamerika. Keine offizielle Agenda, keine Pressemitteilungen. Kritiker sehen es als informelle Steuerungsinstanz transatlantischer Politik.',
    influence: 'Politik · Finanzen · Medien',
    lat: 51.98,
    lng: 5.83,
    members: ['Henry Kissinger', 'David Rockefeller', 'George Soros', 'Various PMs & CEOs'],
    connections: ['CFR', 'Trilaterale Kommission', 'Chatham House'],
  ),
  _PowerCenter(
    name: 'City of London',
    badge: 'Square Mile',
    founded: 'Eigenständig seit 1067 (Wilhelm I.)',
    description:
        'Eigenständiger Stadtstaat innerhalb Londons mit eigener Polizei, eigenem Lord Mayor und über 500 Jahre alter Selbstverwaltung. Beherbergt ~500 Banken und Finanzinstitute. Kein normaler Wahlbezirk – Unternehmen haben Stimmrecht.',
    influence: 'Globales Finanzzentrum',
    lat: 51.5155,
    lng: -0.092,
    members: ['Bank of England', 'Lloyd\'s of London', 'London Stock Exchange'],
    connections: ['BIS', 'Federal Reserve', 'Rothschild-Gruppe'],
  ),
  _PowerCenter(
    name: 'Vatikan',
    badge: 'Heiliger Stuhl',
    founded: 'Lateranvertrag 1929 (Staatsgründung)',
    description:
        'Kleinster Souveränstaat der Welt (0,44 km²) mit globalem Einfluss auf ~1,3 Milliarden Katholiken. Vatikanbank (IOR) steht seit Jahrzehnten im Zentrum von Skandalen. Diplomatische Beziehungen zu 183 Staaten.',
    influence: 'Religion · Diplomatie · Finanzen',
    lat: 41.902,
    lng: 12.453,
    members: ['Papst Franziskus', 'Opus Dei', 'Jesuiten-Orden', 'Vatikanbank (IOR)'],
    connections: ['Malteserorden', 'Freimaurerlogen', 'CIA (historisch)'],
  ),
  _PowerCenter(
    name: 'Council on Foreign Relations',
    badge: 'CFR',
    founded: 'Gegründet 1921, New York',
    description:
        'Einflussreichste außenpolitische Denkfabrik der USA. Mitglieder waren fast alle US-Außenminister seit 1945. Gibt das Magazin "Foreign Affairs" heraus. Gilt als intellektuelle Heimat des US-amerikanischen Establishments.',
    influence: 'US-Außenpolitik · Medien',
    lat: 40.769,
    lng: -73.966,
    members: ['Henry Kissinger', 'Zbigniew Brzezinski', 'George H.W. Bush', 'Bill Clinton'],
    connections: ['Bilderberg', 'Trilaterale Kommission', 'Brookings Institution'],
  ),
  _PowerCenter(
    name: 'Bank für Internationalen Zahlungsausgleich',
    badge: 'BIS',
    founded: 'Gegründet 1930, Basel',
    description:
        'Die "Zentralbank der Zentralbanken". Koordiniert globale Geldpolitik und setzt Standards (Basel I/II/III). Besitzt diplomatische Immunität – kein Staat darf ihre Räumlichkeiten durchsuchen. Gegründet nach dem Ersten Weltkrieg.',
    influence: 'Globale Geldpolitik',
    lat: 47.544,
    lng: 7.601,
    members: ['Federal Reserve', 'EZB', 'Bank of England', '60+ Zentralbanken'],
    connections: ['IMF', 'Weltbank', 'City of London'],
  ),
  _PowerCenter(
    name: 'Trilaterale Kommission',
    badge: 'Trilateral',
    founded: 'Gegründet 1973, David Rockefeller',
    description:
        'Nichtstaatliche Organisation zur Koordination zwischen Nordamerika, Westeuropa und Japan. Von David Rockefeller und Zbigniew Brzezinski gegründet als Reaktion auf das Ende von Bretton Woods. Kritiker: Supranationale Regierung im Verborgenen.',
    influence: 'Transatlantische Koordination',
    lat: 50.85,
    lng: 4.35,
    members: ['David Rockefeller', 'Jimmy Carter', 'George H.W. Bush', 'Bill Clinton'],
    connections: ['CFR', 'Bilderberg', 'WEF'],
  ),
  _PowerCenter(
    name: 'Skull & Bones',
    badge: 'Order 322',
    founded: 'Gegründet 1832, Yale University',
    description:
        'Geheimer Studentenbund der Yale University. Jährlich nur 15 neue Mitglieder ("Tapped"). Alumni dominieren CIA, Supreme Court und Wall Street. Beide Kandidaten der US-Wahl 2004 (Bush & Kerry) waren Mitglieder.',
    influence: 'US-Elite · Geheimdienste',
    lat: 41.311,
    lng: -72.928,
    members: ['George H.W. Bush', 'George W. Bush', 'John Kerry', 'William Taft'],
    connections: ['CIA (historisch)', 'CFR', 'Russische Oligarchen (Gegenstück)'],
  ),
  _PowerCenter(
    name: 'Bohemian Grove',
    badge: 'Bohemian Club',
    founded: 'Seit 1878, Monte Rio, Kalifornien',
    description:
        'Jährliches Treffen (~2.500 Personen) im Redwood-Wald Nordkaliforniens. Zwei Wochen im Juli, strikt männlich, keine Presse. Richard Nixon: "Frömmste Verdammtheit auf der Erde." Hauptaktivität lt. Mitgliedern: Networking und Entspannung.',
    influence: 'US-Politik · Technologie · Finanzen',
    lat: 38.527,
    lng: -123.003,
    members: ['Nixon', 'Reagan', 'Kissinger', 'Clint Eastwood', 'CEOs großer Konzerne'],
    connections: ['CFR', 'Skull & Bones', 'Bilderberg'],
  ),
  _PowerCenter(
    name: 'Chatham House',
    badge: 'RIIA',
    founded: 'Royal Institute of International Affairs, 1920',
    description:
        'Britisches Pendant zum CFR. Bekannt für die "Chatham House Rule": Informationen aus Meetings dürfen genutzt, aber nicht der Quelle zugeordnet werden. Beeinflusst britische Außenpolitik seit dem Ersten Weltkrieg.',
    influence: 'Britische Außenpolitik',
    lat: 51.507,
    lng: -0.135,
    members: ['Boris Johnson', 'Tony Blair', 'MI6-Direktoren', 'Top-Journalisten'],
    connections: ['Bilderberg', 'CFR', 'Five Eyes'],
  ),
];

class _VorhangMapTabState extends State<VorhangMapTab> {
  static const _gold = Color(0xFFC9A84C);
  static const _bg = Color(0xFF000000);
  static const _surface = Color(0xFF0D0B00);

  final _mapController = MapController();
  _PowerCenter? _selected;

  void _showDetail(_PowerCenter c) {
    setState(() => _selected = c);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (_, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _gold.withValues(alpha: 0.5)),
                    ),
                    child: Text(c.badge,
                        style: const TextStyle(
                            color: _gold, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      c.influence,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(c.name,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(c.founded,
                  style: TextStyle(
                      color: _gold.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontStyle: FontStyle.italic)),
              const SizedBox(height: 12),
              Text(c.description,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 14, height: 1.55)),
              if (c.members.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Bekannte Mitglieder',
                    style: TextStyle(
                        color: _gold, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...c.members.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline, color: _gold, size: 14),
                          const SizedBox(width: 8),
                          Text(m,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 13)),
                        ],
                      ),
                    )),
              ],
              if (c.connections.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Verbindungen',
                    style: TextStyle(
                        color: _gold, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: c.connections
                      .map((x) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _gold.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: _gold.withValues(alpha: 0.35)),
                            ),
                            child: Text(x,
                                style: const TextStyle(color: _gold, fontSize: 12)),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _selected = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(47.0, 5.0),
            initialZoom: 3.2,
            minZoom: 2.0,
            maxZoom: 14.0,
            backgroundColor: _bg,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png',
              userAgentPackageName: 'com.myapp.mobile',
            ),
            MarkerLayer(
              markers: _centers.map((c) {
                final sel = _selected?.name == c.name;
                return Marker(
                  point: LatLng(c.lat, c.lng),
                  width: sel ? 36 : 24,
                  height: sel ? 36 : 24,
                  child: GestureDetector(
                    onTap: () {
                      _mapController.move(LatLng(c.lat, c.lng), 5.5);
                      _showDetail(c);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: sel ? _gold : _gold.withValues(alpha: 0.75),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: sel ? Colors.white : _gold,
                          width: sel ? 2.5 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _gold.withValues(alpha: sel ? 0.7 : 0.3),
                            blurRadius: sel ? 14 : 6,
                            spreadRadius: sel ? 3 : 0,
                          ),
                        ],
                      ),
                      child: sel
                          ? const Icon(Icons.close, color: Colors.black, size: 14)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: _bg.withValues(alpha: 0.82),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MACHTZENTREN',
                    style: TextStyle(
                        color: _gold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3)),
                Text(
                  '${_centers.length} Standorte · Marker antippen für Details',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
