import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class UrsprungMapTab extends StatefulWidget {
  const UrsprungMapTab({super.key});

  @override
  State<UrsprungMapTab> createState() => _UrsprungMapTabState();
}

class _ResearchSite {
  final String name, badge, founded, description, status;
  final List<String> findings, researchers;
  final double lat, lng;

  const _ResearchSite({
    required this.name,
    required this.badge,
    required this.founded,
    required this.description,
    required this.status,
    required this.lat,
    required this.lng,
    this.findings = const [],
    this.researchers = const [],
  });
}

const _sites = [
  _ResearchSite(
    name: 'Monroe Institute',
    badge: 'Hemi-Sync',
    founded: 'Gegründet 1974, Faber, Virginia',
    description:
        'Forschungszentrum für Bewusstseinserweiterung durch Hemi-Sync-Audiotechnik. '
        'Entwickelt von Robert Monroe nach eigenen außerkörperlichen Erfahrungen. '
        'CIA-Bericht 1983 bestätigte die Wirksamkeit des Gateway-Programms. '
        'Heute aktiv mit öffentlichen Retreats und Forschungsprogrammen.',
    status: 'Aktiv',
    lat: 37.83,
    lng: -78.77,
    findings: [
      'Focus 10–21 reproduzierbar durch Binaural Beats',
      'CIA-Validierung des Gateway Experience (1983)',
      'Über 10.000 dokumentierte Teilnehmer-Erfahrungen',
    ],
    researchers: ['Robert Monroe', 'Darlene Miller', 'Skip Atwater (ex-CIA)'],
  ),
  _ResearchSite(
    name: 'SRI International (Stanford)',
    badge: 'STAR GATE',
    founded: 'Remote Viewing Programm 1972–1985',
    description:
        'Das Stanford Research Institute führte im Auftrag der CIA und NSA '
        'jahrelange Experimente zu Remote Viewing durch. Forscher Hal Puthoff und Russell Targ '
        'erzielten statistisch signifikante Ergebnisse. Ingo Swann und Pat Price '
        'identifizierten sowjetische Militäranlagen durch Fernwahrnehmung.',
    status: 'Abgeschlossen 1995',
    lat: 37.45,
    lng: -122.18,
    findings: [
      'Statistische Signifikanz p < 0.001 in kontrollierten Tests',
      'Ingo Swann beschrieb Jupiter-Ringe vor Voyager-Bestätigung',
      'Pat Price identifizierte sowjetisches Uranprogramm in Semipalatinsk',
    ],
    researchers: ['Hal Puthoff', 'Russell Targ', 'Ingo Swann', 'Pat Price'],
  ),
  _ResearchSite(
    name: 'Esalen Institute',
    badge: 'Human Potential',
    founded: 'Gegründet 1962, Big Sur, Kalifornien',
    description:
        'Pioniierzentrum der Human Potential Movement. Verbindet westliche Psychologie '
        'mit östlicher Philosophie und indigenem Wissen. Gastgeber für Aldous Huxley, '
        'Alan Watts, Carlos Castaneda, Timothy Leary und andere Schlüsselfiguren '
        'des Bewusstseins-Diskurses des 20. Jahrhunderts.',
    status: 'Aktiv',
    lat: 36.138,
    lng: -121.628,
    findings: [
      'Grundlagen der transpersonalen Psychologie',
      'Integration von Meditation in westliche Therapie',
      'Erforschung von LSD-Therapie (prä-Verbot)',
    ],
    researchers: ['Abraham Maslow', 'Fritz Perls', 'Stanislav Grof', 'Alan Watts'],
  ),
  _ResearchSite(
    name: 'Fort Meade – STAR GATE HQ',
    badge: 'Militär-RV',
    founded: 'Programm 1978–1995',
    description:
        'Hauptquartier des US-Militär Remote Viewing Programms. '
        'Speziell ausgebildete Soldaten (Military Remote Viewers) wurden eingesetzt '
        'für Aufklärungsoperationen. General Stubblebine forderte den flächendeckenden '
        'Einsatz im Militär. 1995 öffentlich gemacht und offiziell aufgelöst.',
    status: 'Aufgelöst 1995',
    lat: 39.108,
    lng: -76.772,
    findings: [
      'Geiseln in Iran 1979 lokalisiert',
      'Nordkoreanische Tunnels kartiert',
      'Mindestens 23 ausgebildete Military Remote Viewers',
    ],
    researchers: ['Ingo Swann (Trainer)', 'Joseph McMoneagle', 'David Morehouse'],
  ),
  _ResearchSite(
    name: 'Princeton PEAR Lab',
    badge: 'PEAR',
    founded: 'Princeton Engineering Anomalies Research, 1979–2007',
    description:
        'Ingenieur Robert Jahn und Psychologin Brenda Dunne untersuchten 28 Jahre lang '
        'die Wechselwirkung zwischen menschlicher Intention und Zufallsgeneratoren. '
        'Über 2,5 Millionen Versuche zeigten konsistent kleine aber statistisch signifikante '
        'Abweichungen wenn Probanden mentale Intention einsetzten.',
    status: 'Abgeschlossen 2007',
    lat: 40.344,
    lng: -74.651,
    findings: [
      '2,5 Mio. Versuche: p < 10⁻¹² Gesamteffekt',
      'Intention beeinflusst Zufallsgeneratoren minimal aber konsistent',
      'Effektstärke unabhängig von Distanz (bis 10.000 km getestet)',
    ],
    researchers: ['Robert Jahn', 'Brenda Dunne'],
  ),
  _ResearchSite(
    name: 'Findhorn Foundation',
    badge: 'Spirituell',
    founded: 'Gegründet 1962, Schottland',
    description:
        'Internationale Gemeinschaft und Bildungszentrum in Nordschottland. '
        'Bekannt für das Konzept des "Co-creation with Nature" — Kommunikation mit '
        'Pflanzengeistern als Gartenbaugrundlage. Heute UN-akkreditierte NGO mit '
        'Programmen für nachhaltige Entwicklung und Bewusstseinswandel.',
    status: 'Aktiv',
    lat: 57.658,
    lng: -3.603,
    findings: [
      'Ungewöhnlich große Gemüsepflanzen in karger Erde dokumentiert (1960er)',
      'UN-akkreditierte NGO für nachhaltige Entwicklung',
      'Über 40.000 Menschen jährlich in Bildungsprogrammen',
    ],
    researchers: ['Peter Caddy', 'Eileen Caddy', 'Dorothy Maclean'],
  ),
  _ResearchSite(
    name: 'Skinwalker Ranch',
    badge: 'UAP & Anomalien',
    founded: 'Seit den 1990ern erforscht, Utah',
    description:
        'Privates Gelände in Utah das seit Jahrzehnten anomale Phänomene aufweist: '
        'UAPs, Poltergeist-Aktivitäten, Viehverstümmelungen, Portale. '
        'Bigelow Aerospace kaufte das Gelände 1996. Seit 2017 staatlich erforscht '
        'durch das AAWSAP-Programm. Heute TV-Dokumentation "The Secret of Skinwalker Ranch".',
    status: 'Aktiv — laufende Forschung',
    lat: 40.258,
    lng: -109.892,
    findings: [
      'Magnetische Anomalien und ungewöhnliche Strahlung dokumentiert',
      'Über 100 Mitarbeiter-Berichte zu anomalen Erfahrungen',
      'US-Regierung finanzierte AAWSAP-Programm (2008–2012)',
    ],
    researchers: ['Robert Bigelow', 'Colm Kelleher', 'George Knapp'],
  ),
  _ResearchSite(
    name: 'Institute of Noetic Sciences',
    badge: 'IONS',
    founded: 'Gegründet 1973, Edgar Mitchell (Apollo 14)',
    description:
        'Gegründet von Astronaut Edgar Mitchell nach seiner Erleuchtungserfahrung auf dem '
        'Weg von Mond zur Erde. Erforscht das Verhältnis zwischen Bewusstsein und Physik, '
        'Heilung, Intuition und außergewöhnliche menschliche Fähigkeiten. '
        'Verbindet strenge Wissenschaft mit spirituellen Erfahrungen.',
    status: 'Aktiv',
    lat: 38.3,
    lng: -122.7,
    findings: [
      'Fernheilung zeigt statistisch signifikante Effekte in 30+ Studien',
      'Präkognition reproduzierbar in kontrollierten Experimenten (Dean Radin)',
      'Globales Bewusstseins-Projekt: Zufallsgeneratoren reagieren auf Weltevents',
    ],
    researchers: ['Edgar Mitchell', 'Dean Radin', 'Marilyn Schlitz'],
  ),
];

class _UrsprungMapTabState extends State<UrsprungMapTab> {
  static const _cyan = Color(0xFF00D4AA);
  static const _bg = Color(0xFF050510);
  static const _surface = Color(0xFF080818);

  final _mapController = MapController();
  _ResearchSite? _selected;

  void _showDetail(_ResearchSite s) {
    setState(() => _selected = s);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.62,
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
                    color: _cyan.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _cyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _cyan.withValues(alpha: 0.5)),
                    ),
                    child: Text(s.badge,
                        style: const TextStyle(
                            color: _cyan, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: s.status.startsWith('Aktiv')
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      s.status,
                      style: TextStyle(
                          color: s.status.startsWith('Aktiv')
                              ? Colors.greenAccent
                              : Colors.orange,
                          fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(s.name,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text(s.founded,
                  style: TextStyle(
                      color: _cyan.withValues(alpha: 0.65),
                      fontSize: 12,
                      fontStyle: FontStyle.italic)),
              const SizedBox(height: 12),
              Text(s.description,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 14, height: 1.55)),
              if (s.findings.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Schlüsselergebnisse',
                    style: TextStyle(
                        color: _cyan, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...s.findings.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ',
                              style: TextStyle(color: _cyan, fontSize: 14)),
                          Expanded(
                            child: Text(f,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 13,
                                    height: 1.4)),
                          ),
                        ],
                      ),
                    )),
              ],
              if (s.researchers.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('Forscher',
                    style: TextStyle(
                        color: _cyan, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: s.researchers
                      .map((r) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _cyan.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _cyan.withValues(alpha: 0.3)),
                            ),
                            child: Text(r,
                                style: const TextStyle(
                                    color: _cyan, fontSize: 12)),
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
            initialCenter: LatLng(42.0, -90.0),
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
              markers: _sites.map((s) {
                final sel = _selected?.name == s.name;
                return Marker(
                  point: LatLng(s.lat, s.lng),
                  width: sel ? 36 : 24,
                  height: sel ? 36 : 24,
                  child: GestureDetector(
                    onTap: () {
                      _mapController.move(LatLng(s.lat, s.lng), 5.5);
                      _showDetail(s);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: sel ? _cyan : _cyan.withValues(alpha: 0.75),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: sel ? Colors.white : _cyan,
                          width: sel ? 2.5 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _cyan.withValues(alpha: sel ? 0.7 : 0.3),
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
                const Text('BEWUSSTSEINSZENTREN',
                    style: TextStyle(
                        color: _cyan,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3)),
                Text(
                  '${_sites.length} Forschungsstandorte · Marker antippen für Details',
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
