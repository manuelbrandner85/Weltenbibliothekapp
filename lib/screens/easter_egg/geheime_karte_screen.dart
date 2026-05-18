// 🗺️ GEHEIME KARTE - Liste verborgener Locations (CIA, Antike, Underground)
//
// Statt einer interaktiven Karte (waere ein eigenes Projekt): kuratierte
// Liste mit 24 verborgenen/dekklassifizierten/mysterioesen Orten weltweit.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_ambient_particles.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';

class GeheimeKarteScreen extends StatefulWidget {
  const GeheimeKarteScreen({super.key});
  @override
  State<GeheimeKarteScreen> createState() => _GeheimeKarteScreenState();
}

class _GeheimeKarteScreenState extends State<GeheimeKarteScreen>
    with TickerProviderStateMixin {
  static const Color _bg = Color(0xFF02100A);
  static const Color _primary = Color(0xFF66BB6A);
  static const Color _gold = Color(0xFFFFD700);

  String _filterCat = 'all';
  late final AnimationController _ambientCtrl;

  static final _locations = [
    _Loc('Area 51', 'USA, Nevada', 'cia', '37.2350° N · 115.8111° W',
        'Dekklassifiziert 2013. CIA-Testgelände für U-2/A-12. Lange offiziell nicht existent. Aurora-Project-Gerüchte.', '🛸'),
    _Loc('Mount Yamantau', 'Russland, Ural', 'underground', '54.2667° N · 58.1° E',
        'Massiver geheimer Bunker-Komplex - größer als manche Städte. Zweck offiziell nie bestätigt.', '⛰️'),
    _Loc('Pine Gap', 'Australien', 'cia', '23.7989° S · 133.7370° E',
        'Geheime US-Australien-Signal-Intelligence-Station. Snowden-Dokumente bestätigten Echelon-Beteiligung.', '📡'),
    _Loc('Diego Garcia', 'Indischer Ozean', 'cia', '7.3133° S · 72.4111° E',
        'US-Militärbasis mit Black-Site-Verdacht. UK pachtet die Insel - Bewohner 1968-73 zwangsdeportiert.', '🏝️'),
    _Loc('Ramstein Air Base', 'Deutschland', 'cia', '49.4356° N · 7.6005° E',
        'NATO-Hub. Snowden-Dokumente: Drohnen-Steuerung für Naher Osten läuft über Satellit-Hub hier.', '✈️'),
    _Loc('Mount Weather', 'USA, Virginia', 'underground', '39.0625° N · 77.8889° W',
        'FEMA-Operations-Center + Continuity-of-Government-Bunker. ~60 Acres Untergrund-Stadt.', '🚪'),
    _Loc('Raven Rock', 'USA, Pennsylvania', 'underground', '39.7406° N · 77.4036° W',
        'DoD-Backup-Pentagon. Bei Atom-Krieg Schaltzentrale. Mark 1 bis Mark 7 (7 Untergrund-Levels).', '🪨'),
    _Loc('Cheyenne Mountain', 'USA, Colorado', 'underground', '38.7430° N · 104.8480° W',
        'NORAD-Originalbau. 700 Meter unter Granit. 25 Tonnen Stahltüren - kann Nuklearschlag abfangen.', '🏔️'),
    _Loc('Vatikan-Archiv', 'Vatikan', 'history', '41.9036° N · 12.4536° E',
        '85 km Regale geheime Akten. 2019 für Forscher tlw. geöffnet - dauert Jahrzehnte zu sichten.', '📜'),
    _Loc('Sankt-Peter-Kirche', 'Antarktis', 'antarctic', '90° S',
        'Russisch-orthodoxe Kirche am Südpol. Plus: Operation Highjump 1946-47 mit 4700 Soldaten - bis heute mystifiziert.', '⛪'),
    _Loc('Yonaguni-Monument', 'Japan', 'history', '24.4319° N · 123.0089° E',
        'Untermeerische Stein-Strukturen, möglicherweise 10000+ Jahre alt - präzedäre antike Hochkultur?', '🗿'),
    _Loc('Göbekli Tepe', 'Türkei', 'history', '37.2233° N · 38.9225° E',
        'Älteste bekannte Tempelanlage 11500 Jahre - vor Jericho, vor Sumer, älter als Schrift.', '🏛️'),
    _Loc('Boschloo-Höhle', 'Niederlande', 'underground', '50.8 N · 5.7 E',
        'NATO-Bunker tief im Berg. Während Kalter Krieg: SHAPE-Backup-Command.', '🏚️'),
    _Loc('Burlington-Bunker', 'UK, Wiltshire', 'underground', '51.4036° N · 2.1855° W',
        '35-Hektar unterirdische Stadt für britische Regierung bei Atomkrieg. 1956-91 geheim, 2017 deklassifiziert.', '🇬🇧'),
    _Loc('Dulce Base', 'USA, New Mexico', 'cia', '36.9442° N · 106.9981° W',
        'Lange Whistleblower-Geschichten von unterirdischer Biolabor-Anlage. Offiziell nicht bestätigt.', '🔬'),
    _Loc('CERN', 'Schweiz/Frankreich', 'science', '46.2333° N · 6.0500° E',
        'LHC. Höchste Energien je auf Erden erzeugt. Kontroverse um "Schwarzes Loch"-Risiko und Mandela-Effekt.', '⚛️'),
    _Loc('Tunguska', 'Russland', 'mystery', '60.8858° N · 101.8939° E',
        '1908 Explosion 1000x Hiroshima - kein Krater. Bis heute Asteroid, Komet oder Tesla\'s Wardenclyffe-Test?', '💥'),
    _Loc('Skinwalker Ranch', 'USA, Utah', 'mystery', '40.2444° N · 109.8911° W',
        'Dokumentierte unerklärliche Phänomene seit 1970er. DoD-AAWSAP-Forschungsobjekt 2007-2012.', '👁️'),
    _Loc('Bohemian Grove', 'USA, Kalifornien', 'elite', '38.4944° N · 123.0067° W',
        'Privater 1100-Hektar-Wald. Sommerlich seit 1872 - US-Eliten. "Cremation of Care"-Ritual filmed 2000.', '🦉'),
    _Loc('Hellenic-Defense-Bunker', 'Griechenland', 'underground', '37.9 N · 23.7 E',
        'Athener-Stadt-Bunker. Verbunden mit antiken Tunneln unter der Akropolis (Demosthenes-Reden).', '🏺'),
    _Loc('Phoenix Lights', 'USA, Arizona', 'mystery', '33.4484° N · 112.0740° W',
        '13.3.1997 - Tausende sahen 3km langes V-förmiges Objekt. Air Force erst geleugnet, dann "Flares" - Gouverneur Symington bestätigte 2007.', '🛸'),
    _Loc('Antarktis Pyramide', 'Antarktis', 'antarctic', '79.9 S · 81.9 E',
        'Pyramidale Bergstrukturen - natürlich oder künstlich? Russische Wissenschaftler 2016 vorsichtig spekulativ.', '🔺'),
    _Loc('Kola-Bohrloch', 'Russland', 'science', '69.3960° N · 30.6086° E',
        '12262m tief gebohrt 1989. Trotz Versiegelung erscheinen "Sounds of Hell"-Records online. Bohrung gestoppt aus mysteriösen Gründen.', '🕳️'),
    _Loc('Wewelsburg', 'Deutschland', 'history', '51.6072° N · 8.6519° E',
        'SS-Burg Himmlers. Nord-Turm als geometrisches Zentrum geplanter "1000-jähriger Weltordnung". Schwarze-Sonne-Symbol erstmals dort verwendet.', '🏰'),
  ];

  static const _cats = {
    'all': '🌐 Alle',
    'cia': '🇺🇸 CIA/Mil',
    'underground': '⛰️ Untergrund',
    'history': '📜 Antike',
    'mystery': '👁️ Mystery',
    'antarctic': '❄️ Antarktis',
    'science': '⚛️ Science',
    'elite': '🦉 Elite',
  };

  @override
  void initState() {
    super.initState();
    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
  }

  @override
  void dispose() { _ambientCtrl.dispose(); super.dispose(); }

  Future<void> _openMaps(_Loc l) async {
    final coords = l.coords.replaceAll('°', '').replaceAll(' N', '').replaceAll(' S', '-').replaceAll(' E', '').replaceAll(' W', '-').replaceAll('·', ',').replaceAll(' ', '');
    final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(l.coords)}';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filterCat == 'all' ? _locations : _locations.where((l) => l.category == _filterCat).toList();
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: WBWorld.neutral,
        titleWidget: ShaderMask(
          shaderCallback: (r) => const LinearGradient(colors: [_gold, _primary]).createShader(r),
          child: const Text('GEHEIME KARTE',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3)),
        ),
      ),
      body: Stack(fit: StackFit.expand, children: [
        Container(decoration: const BoxDecoration(gradient: RadialGradient(
          center: Alignment.center, radius: 1.5,
          colors: [Color(0x551B5E20), Color(0x33082E18), _bg]))),
        IgnorePointer(child: AnimatedBuilder(animation: _ambientCtrl, builder: (_, __) =>
            CustomPaint(painter: _GkOrbsPainter(_ambientCtrl.value), size: Size.infinite))),
        const IgnorePointer(child: WBAmbientParticles(world: WBWorld.neutral, count: 40)),
        SafeArea(child: Column(children: [
          // Filter
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: _cats.entries.map((e) {
                final sel = e.key == _filterCat;
                return Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: GestureDetector(
                    onTap: () { HapticFeedback.selectionClick(); setState(() => _filterCat = e.key); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: sel ? _primary.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: sel ? _primary : Colors.transparent),
                      ),
                      child: Text(e.value, style: TextStyle(color: sel ? Colors.white : Colors.white60, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final l = filtered[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _primary.withValues(alpha: 0.25)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(l.emoji, style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(l.country, style: TextStyle(color: _primary.withValues(alpha: 0.85), fontSize: 11)),
                        ]),
                      ),
                      IconButton(
                        icon: const Icon(Icons.map_rounded, color: _gold, size: 18),
                        tooltip: 'Auf Google Maps',
                        onPressed: () => _openMaps(l),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text(l.description, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
                    const SizedBox(height: 4),
                    Text(l.coords, style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace')),
                  ]),
                );
              },
            ),
          ),
        ])),
        const IgnorePointer(child: WBVignette()),
      ]),
    );
  }
}

class _Loc {
  final String name, country, category, coords, description, emoji;
  const _Loc(this.name, this.country, this.category, this.coords, this.description, this.emoji);
}

class _GkOrbsPainter extends CustomPainter {
  final double t;
  _GkOrbsPainter(this.t);
  @override void paint(Canvas canvas, Size size) {
    _d(canvas, Offset(size.width * 0.2, size.height * (0.3 + math.sin(t * 2 * math.pi) * 0.05)), 100, const Color(0xFF66BB6A));
    _d(canvas, Offset(size.width * 0.85, size.height * (0.6 + math.cos(t * 2 * math.pi) * 0.04)), 90, const Color(0xFFFFD700));
  }
  void _d(Canvas c, Offset o, double r, Color col) {
    c.drawCircle(o, r, Paint()..color = col.withValues(alpha: 0.1)..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5));
  }
  @override bool shouldRepaint(_GkOrbsPainter o) => o.t != t;
}
