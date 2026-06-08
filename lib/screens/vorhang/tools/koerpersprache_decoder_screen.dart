// Interactive body language decoder for the Vorhang world.
// Curated catalogue of nonverbal signals; no network calls needed.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/haptic_service.dart';

const Color _kGold = Color(0xFFC9A84C);
const Color _kBg = Color(0xFF000000);
const Color _kSurface = Color(0xFF0D0B00);

// ── Data model ───────────────────────────────────────────────────────────────

class _Signal {
  final String name;
  final String emoji;
  final String category;
  final String shortDesc;
  final List<String> meanings;
  final String context;
  final String counter;

  const _Signal({
    required this.name,
    required this.emoji,
    required this.category,
    required this.shortDesc,
    required this.meanings,
    required this.context,
    required this.counter,
  });
}

const List<_Signal> _signals = [
  // Gesicht
  _Signal(
    name: 'Microexpression Verachtung',
    emoji: '😤',
    category: 'Gesicht',
    shortDesc: 'Einseitiges Hochziehen des Mundwinkels fuer einen Bruchteil einer Sekunde.',
    meanings: [
      'Die Person fuehlt sich moralisch oder sozial ueberlegen.',
      'Unterschwellige Feindseligkeit oder Ablehnung.',
      'Kann auf tiefes Misstrauen oder Abwertung hinweisen.',
    ],
    context:
        'Mikroexpressionen dauern 1/25 bis 1/5 Sekunde. Kulturneutral: Verachtung '
        'ist die einzige Emotion mit einseitigem Gesichtsausdruck. Achtung: kurzes '
        'Schmunzeln vor dem Sprechen ist keine Verachtung.',
    counter:
        'Offene, neugierige Fragen stellen. Gemeinsamkeiten suchen. '
        'Eigene Position nicht defensiv rechtfertigen.',
  ),
  _Signal(
    name: 'Lippenpressen',
    emoji: '😬',
    category: 'Gesicht',
    shortDesc: 'Lippen werden fest zusammengepresst, oft waehrend des Zuhoerens.',
    meanings: [
      'Zurueckhalten einer Aussage oder Meinung.',
      'Unbehagen, Zweifel oder innerer Widerstand.',
      'Stress und Anspannung in einer Situation.',
    ],
    context:
        'Haufig nach Aussagen anderer als Reaktion sichtbar. Unterschied zu '
        'Konzentration: beim Denken entspannen die Lippen meistens wieder.',
    counter:
        'Pause einlegen und fragen: "Was denkst du dazu?" Raum fuer die '
        'zurueckgehaltene Meinung schaffen.',
  ),
  _Signal(
    name: 'Naseruessel / Nasenkraeuselung',
    emoji: '👃',
    category: 'Gesicht',
    shortDesc: 'Leichtes Kraeusen oder Ruempfen der Nase.',
    meanings: [
      'Ekel oder Abneigung gegenueber dem Gesprochenen.',
      'Ablehnung eines Angebots oder einer Idee.',
      'Starkes Unbehagen (physisch oder sozial).',
    ],
    context:
        'Kulturell konsistentes Ekelsignal (Paul Ekman). Kann reflexartig '
        'auftreten bei unangenehmen Themen, nicht nur Geruechern.',
    counter:
        'Thema kurz pausieren. Neutral ansprechen: "Ich habe den Eindruck, '
        'etwas stimmt dich nachdenklich?"',
  ),
  // Augen
  _Signal(
    name: 'Erhoeht-Blinzeln',
    emoji: '👁️',
    category: 'Augen',
    shortDesc: 'Die Blinzelfrequenz steigt deutlich an.',
    meanings: [
      'Innerer Stress oder Anspannung.',
      'Kognitiver Aufwand: die Person verarbeitet komplexe Informationen.',
      'Kann auf Luege oder Unbehagen hinweisen (im Kontext).',
    ],
    context:
        'Normales Blinzeln: 15-20 Mal pro Minute. Deutlicher Anstieg ohne '
        'erklaerbare Ursache (Zugluft, Muedigkeit) ist signifikant. Kein '
        'Einzelindikator fuer Luegen -- immer Baseline beachten.',
    counter:
        'Tempo drosseln. Vereinfachen. Offene Frage stellen, um Klarheit zu '
        'schaffen.',
  ),
  _Signal(
    name: 'Seitlicher Blick',
    emoji: '👀',
    category: 'Augen',
    shortDesc: 'Augen bewegen sich zur Seite, Kopf bleibt gerade.',
    meanings: [
      'Interesse an etwas ausserhalb des Gespraechs.',
      'Ablenkung oder Desinteresse.',
      'Unbehagensflucht: Wunsch, die Situation zu verlassen.',
    ],
    context:
        'Wenn kombiniert mit nach vorne geneigtem Koerper: eher Neugier. '
        'Wenn mit zurueckgeneigtem Koerper: eher Vermeidung. Kulturelle '
        'Unterschiede beachten -- direkter Blick ist nicht ueberall Norm.',
    counter:
        'Gespraechwichtigkeit erhoehen oder Thema wechseln. Kurz pausieren '
        'und die Person direkt einbinden.',
  ),
  _Signal(
    name: 'Gekniffene Augen',
    emoji: '🧐',
    category: 'Augen',
    shortDesc: 'Augenlider werden leicht zusammengekniffen.',
    meanings: [
      'Skepsis oder Zweifel an einer Aussage.',
      'Konzentriertes Nachdenken oder Abwaegen.',
      'Ablehnung oder Misstrauen.',
    ],
    context:
        'Unterschied zu Lichtreiz: bei Skepsis tritt das Kneifen unmittelbar '
        'nach einer Aussage auf. Bei Konzentration oft mit Pausen kombiniert.',
    counter:
        'Aussage mit Fakten oder Beispielen untermauern. Fragen: "Was brauchst '
        'du, um sicherzugehen?"',
  ),
  // Arme & Haende
  _Signal(
    name: 'Verschrankte Arme',
    emoji: '🤐',
    category: 'Arme & Haende',
    shortDesc: 'Arme werden vor dem Koerper verschraenkt.',
    meanings: [
      'Selbstschutz oder Abwehr in einer Situation.',
      'Unbehagen, Skepsis oder innerer Rueckzug.',
      'Kann bloss Kaelte oder Bequemlichkeit bedeuten.',
    ],
    context:
        'Immer Baseline beachten: manche Menschen verschraenken die Arme '
        'habituel. Signifikant wenn es als Reaktion auf ein Thema auftritt. '
        'Kombiniert mit anderen Signalen aussagekraeftiger.',
    counter:
        'Etwas zum Halten anbieten (Tasse, Unterlagen). Koerpersprache '
        'oeffnen, selbst lockerer werden.',
  ),
  _Signal(
    name: 'Handflaechen zeigen',
    emoji: '🖐️',
    category: 'Arme & Haende',
    shortDesc: 'Offene Handflaechen werden beim Sprechen sichtbar gezeigt.',
    meanings: [
      'Offenheit, Ehrlichkeit und Vertrauenswuerdigkeit signalisieren.',
      'Unterwerfungsgeste: "Ich habe nichts zu verbergen."',
      'Kann auch bewusst eingesetzt werden, um Vertrauen zu erzeugen.',
    ],
    context:
        'Eine der konsistentesten Vertrauensgesten. Wird in Verhandlungen '
        'und Praesentationen aktiv genutzt. Bewusstes Zeigen macht es nicht '
        'weniger wirksam beim Empfaenger.',
    counter:
        'Bewusst einsetzen, um Glaubwuerdigkeit zu staerken. Beim Gegenueber '
        'darauf achten, ob es mit dem Inhalt konsistent ist.',
  ),
  _Signal(
    name: 'Fingerspitzen-Kirchendach',
    emoji: '🙏',
    category: 'Arme & Haende',
    shortDesc: 'Fingerkuppen beider Haende beruehren sich nach oben zeigend.',
    meanings: [
      'Hohe Selbstsicherheit und Kompetenzgefuehl.',
      'Die Person fuehlt sich in der Sache ueberlegen.',
      'Nachdenkliche Selbst-Bestaetigung einer Idee.',
    ],
    context:
        'Haufig bei Fuehrungskraeften und Experten beim Abwaegen zu sehen. '
        'Keine negative Geste -- zeigt Sicherheit, nicht Arroganz.',
    counter:
        'Person ernstnehmen: Sie ist ueberzeugt. Direkte, faktenbasierte '
        'Argumente einbringen.',
  ),
  _Signal(
    name: 'Selbstberuehrung am Hals',
    emoji: '✋',
    category: 'Arme & Haende',
    shortDesc: 'Hand beruehrt Hals, Nacken oder Kragenausschnitt.',
    meanings: [
      'Stressreaktion: Nervensystem wird beruhigt.',
      'Hoher innerer Druck oder Unsicherheit.',
      'Zeigt Unwohlsein mit dem aktuellen Thema.',
    ],
    context:
        'Bei Maennern oft am Adamsapfel (Halskarunkeln reiben). Bei Frauen '
        'am Halsbeuge-Bereich. Evolutionaer: Schutz des empfindlichen Halses '
        'bei Bedrohung.',
    counter:
        'Druck aus der Situation nehmen. Thema kurz wechseln. Nachfragen '
        'ohne zu bedraengen.',
  ),
  // Koerperhaltung
  _Signal(
    name: 'Koerper abgewandt',
    emoji: '🚶',
    category: 'Koerperhaltung',
    shortDesc: 'Torso oder Fuesse zeigen weg vom Gesprächspartner.',
    meanings: [
      'Wunsch, die Situation zu verlassen.',
      'Geringeres Interesse am Gespraechwasinhalt.',
      'Soziale Bereitschaft ist bereits woanders.',
    ],
    context:
        'Fuesse sind ein zuverlässigerer Indikator als der Oberkörper, der '
        'leichter kontrolliert wird. Fuesse zeigen oft unbewusst dorthin, '
        'wo die Person wirklich hinmoechte.',
    counter:
        'Position veraendern, sodass man dem Gegenueber gegenuebersteht. '
        'Inhalt interessanter gestalten oder Gespraeche kurz beenden.',
  ),
  _Signal(
    name: 'Vorwaertslehnen',
    emoji: '🏃',
    category: 'Koerperhaltung',
    shortDesc: 'Der Oberkörper neigt sich leicht Richtung Gesprächspartner.',
    meanings: [
      'Echtes Interesse und aktive Aufmerksamkeit.',
      'Soziale Zuneigung oder Verbundenheit.',
      'Bereitschaft zur aktiven Mitarbeit.',
    ],
    context:
        'Eines der positiven Koerpersignale. Im Sitzen deutlicher als im '
        'Stehen. Auch unter Druck moeglich: invasive Annaeherung -- Kontext '
        'entscheidend.',
    counter:
        'Als positives Signal lesen und Gespraeche vertiefen. Eigenes '
        'Vorwaertslehnen spiegeln fuer Rapport.',
  ),
  _Signal(
    name: 'Koerper-Spiegeln',
    emoji: '🪞',
    category: 'Koerperhaltung',
    shortDesc: 'Person kopiert unbewusst Haltung oder Gesten des Gegenueber.',
    meanings: [
      'Starke Rapport und emotionale Verbindung.',
      'Gegenseitiges Einvernehmen oder Sympathie.',
      'Zeichen von Vertrauen und sozialer Synchronisation.',
    ],
    context:
        'Unbewusstes Spiegeln ist ein zuverlaessiges Zeichen von Rapport. '
        'Kann bewusst eingesetzt werden, um Verbindung zu staerken. '
        'Uebertriebenes, offensichtliches Spiegeln wirkt manipulativ.',
    counter:
        'Positiv: weiter im Gespraechwas vertiefen. Bei Verhandlungen: '
        'Spiegeln leicht unterbrechen, um Dynamik zu testen.',
  ),
  // Stimme & Sprache
  _Signal(
    name: 'Stimmhöhe steigt',
    emoji: '🎵',
    category: 'Stimme & Sprache',
    shortDesc: 'Stimmhöhe erhoehe sich am Satzende oder in bestimmten Momenten.',
    meanings: [
      'Nervositaet oder Stress.',
      'Unsicherheit oder Bitte um Bestaetigung.',
      'Echte Aufregung oder Begeisterung (positiv).',
    ],
    context:
        'Kulturabhaengig: manche Dialekte enden grundsaetzlich mit steigender '
        'Intonation. Auf Veraenderung zur persoenlichen Baseline achten, '
        'nicht auf Absolutwerte.',
    counter:
        'Eigene Stimme senken und verlangsamen: erzeugt Beruhigung durch '
        'paraverbale Spiegelung.',
  ),
  _Signal(
    name: 'Erhoehte Sprechgeschwindigkeit',
    emoji: '⚡',
    category: 'Stimme & Sprache',
    shortDesc: 'Person spricht deutlich schneller als ihre normale Rate.',
    meanings: [
      'Aufregung, Stress oder innerer Druck.',
      'Thema ist emotional aufgeladen.',
      'Kann auf Verschleierungsversuch hinweisen.',
    ],
    context:
        'Luegen zeigen meist gegenteiligen Effekt (langsamer, da kognitiver '
        'Aufwand steigt) -- "schneller sprechen = luegen" ist ein Mythos. '
        'Erhoehtes Tempo korrelliert haeufi mit echter Emotion.',
    counter:
        'Verlangsamung der eigenen Sprache als paraverbalen Ankerpunkt '
        'einsetzen. Kurze Pause einlegen.',
  ),
  _Signal(
    name: 'Haeufiges Raeuspern',
    emoji: '🗣️',
    category: 'Stimme & Sprache',
    shortDesc: 'Person raeupert sich wiederholt ohne erklaerenden physischen Grund.',
    meanings: [
      'Klassisches Stress- und Nervositaetssignal.',
      'Vorbereitung auf eine schwierige Aussage.',
      'Unbehagen mit der eigenen Position oder dem Thema.',
    ],
    context:
        'Eindeutig erst nach Ausschluss physischer Ursachen (Halsschmerzen, '
        'Trockenheit). Als Reaktion auf spezifische Fragen besonders signifikant.',
    counter:
        'Offene Atmosphaere schaffen. Auf Druck verzichten. Dem Gegenueber '
        'Zeit lassen, seine Gedanken zu formulieren.',
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class KoerperspracheDecoderScreen extends StatefulWidget {
  const KoerperspracheDecoderScreen({super.key});

  @override
  State<KoerperspracheDecoderScreen> createState() =>
      _KoerperspracheDecoderScreenState();
}

class _KoerperspracheDecoderScreenState
    extends State<KoerperspracheDecoderScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _activeCategory;

  static final _categories = _signals
      .map((s) => s.category)
      .toSet()
      .toList()
    ..sort();

  List<_Signal> get _filtered {
    Iterable<_Signal> items = _signals;
    if (_activeCategory != null) {
      items = items.where((s) => s.category == _activeCategory);
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      items = items.where((s) =>
          s.name.toLowerCase().contains(q) ||
          s.shortDesc.toLowerCase().contains(q) ||
          s.category.toLowerCase().contains(q));
    }
    return items.toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openDetail(_Signal signal) {
    HapticService.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SignalDetailSheet(signal: signal),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kGold),
        title: Text(
          'KOERPERSPRACHE-DECODER',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w300,
            fontSize: 15,
            letterSpacing: 2.5,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildIntro(),
          _buildSearchBar(),
          _buildCategoryChips(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Text(
        'Woehle ein nonverbales Signal, um moegliche Bedeutungen, '
        'Kontext-Hinweise und Handlungsoptionen zu sehen. '
        'Immer Baseline und Kontext des Gegenueber beachten.',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 12,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white),
        cursorColor: _kGold,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'Signal suchen ...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          prefixIcon: const Icon(Icons.search, color: _kGold),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: _kGold),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
          filled: true,
          fillColor: _kSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _kGold.withValues(alpha: 0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _kGold.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _kGold.withValues(alpha: 0.6)),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _chip(null, 'Alle'),
          for (final c in _categories) _chip(c, c),
        ],
      ),
    );
  }

  Widget _chip(String? value, String label) {
    final active = _activeCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => setState(() => _activeCategory = value),
        backgroundColor: _kSurface,
        selectedColor: _kGold.withValues(alpha: 0.25),
        labelStyle: TextStyle(
          color: active ? _kGold : Colors.white.withValues(alpha: 0.7),
          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          fontSize: 12,
        ),
        side: BorderSide(
          color: active
              ? _kGold.withValues(alpha: 0.6)
              : _kGold.withValues(alpha: 0.15),
        ),
      ),
    );
  }

  Widget _buildList() {
    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, color: _kGold.withValues(alpha: 0.4), size: 48),
            const SizedBox(height: 12),
            Text(
              'Kein Signal gefunden.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildSignalTile(items[i]),
    );
  }

  Widget _buildSignalTile(_Signal s) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetail(s),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_kSurface, _kGold.withValues(alpha: 0.05)],
            ),
            border: Border.all(color: _kGold.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kGold.withValues(alpha: 0.12),
                  border: Border.all(color: _kGold.withValues(alpha: 0.35)),
                ),
                child: Text(s.emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _kGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            s.category,
                            style: const TextStyle(
                              color: _kGold,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.shortDesc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: _kGold.withValues(alpha: 0.5), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Detail sheet ─────────────────────────────────────────────────────────────

class _SignalDetailSheet extends StatelessWidget {
  final _Signal signal;
  const _SignalDetailSheet({required this.signal});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _kGold.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Header
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kGold.withValues(alpha: 0.12),
                    border: Border.all(color: _kGold.withValues(alpha: 0.4)),
                  ),
                  child: Text(signal.emoji,
                      style: const TextStyle(fontSize: 30)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        signal.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        signal.category,
                        style: TextStyle(
                          color: _kGold.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Short description
            Text(
              signal.shortDesc,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            // Meanings
            _label('MOEGLICHE BEDEUTUNGEN'),
            const SizedBox(height: 10),
            for (final m in signal.meanings) _bullet(m),
            const SizedBox(height: 20),
            // Context
            _label('KONTEXT & ACHTUNG'),
            const SizedBox(height: 10),
            _infoBox(
              icon: Icons.info_outline,
              color: const Color(0xFF4FC3F7),
              text: signal.context,
            ),
            const SizedBox(height: 20),
            // Counter
            _label('HANDLUNGSOPTION'),
            const SizedBox(height: 10),
            _infoBox(
              icon: Icons.emoji_objects_outlined,
              color: _kGold,
              text: signal.counter,
            ),
            const SizedBox(height: 12),
            // Disclaimer
            Text(
              'Hinweis: Koerpersprache-Signale sind nie isoliert zu lesen. '
              'Immer Baseline, Kontext und kulturellen Hintergrund beruecksichtigen.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 11,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String s) => Text(
        s,
        style: const TextStyle(
          color: _kGold,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 3.0,
        ),
      );

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _kGold,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _infoBox({
    required IconData icon,
    required Color color,
    required String text,
  }) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.07),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
            ),
          ],
        ),
      );
}
