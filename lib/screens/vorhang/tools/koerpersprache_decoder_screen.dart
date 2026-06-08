// Vorhang tool: "Koerpersprache-Decoder".
// Interactive curated catalog of nonverbal signals with categories, search,
// and a context-based interpretation helper.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/haptic_service.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../theme/wb_cinematic_tokens.dart';

const Color _kGold = Color(0xFFC9A84C);
const Color _kBg = Color(0xFF000000);
const Color _kSurface = Color(0xFF0D0B00);

// ── Data model ───────────────────────────────────────────────────────────────

class _Signal {
  final String name;
  final String emoji;
  final String category;
  final String shortDesc;
  final List<String> interpretations;
  final String context;
  final String tip;

  const _Signal({
    required this.name,
    required this.emoji,
    required this.category,
    required this.shortDesc,
    required this.interpretations,
    required this.context,
    required this.tip,
  });
}

const List<_Signal> _signals = [
  // ── Gesicht ──────────────────────────────────────────────────────────────
  _Signal(
    name: 'Mikroausdruecke',
    emoji: '😶',
    category: 'Gesicht',
    shortDesc: 'Kurze, unwillkuerliche Gesichtsausdruecke (< 0,5 Sek.).',
    interpretations: [
      'Kurze Anspannung um Augen und Stirn zeigt versteckten Stress oder Aerger.',
      'Blitzschnelles Laecheln, das nicht die Augen erreicht, signalisiert soziale Hoeflichkeit statt echter Freude.',
      'Kurzes Hochziehen einer Augenbraue (Verachtung) deutet auf Ueberlegenheitsgefuehl hin.',
    ],
    context:
        'Besonders aufleuchtend in Verhandlungen, wenn die Gegenseite eine unerwartete Information erhaelt.',
    tip:
        'Beobachte das Gesicht in den ersten 0,2 Sekunden nach einer Aussage -- danach setzt bewusste Kontrolle ein.',
  ),
  _Signal(
    name: 'Echtes Laecheln (Duchenne)',
    emoji: '😊',
    category: 'Gesicht',
    shortDesc: 'Laecheln, das die Augenwinkel (Orbicularis oculi) einbezieht.',
    interpretations: [
      'Echter Kraehenfuesse-Effekt an den Augenwinkeln -- nicht willkuerlich kontrollierbar.',
      'Wangen werden angehoben, Lippen dehnen sich natuerllich.',
      'Fehlen dieser Zeichen bei einem Laecheln deutet auf Sozialmaske hin.',
    ],
    context:
        'Entscheidend beim Erstgespraech oder nach einer eigenen Aussage, um echte Zustimmung zu erkennen.',
    tip:
        'Vergleiche mehrere Laecheln einer Person im Gespraechsverlauf -- konsistente Augen-Beteiligung ist das Kriterium.',
  ),
  _Signal(
    name: 'Naserruempfen',
    emoji: '😤',
    category: 'Gesicht',
    shortDesc: 'Kurzes Zusammenziehen der Nasenfluegelmuskulatur.',
    interpretations: [
      'Unbewusste Ablehnung oder Ekel gegenueber einem Vorschlag.',
      'Kann auf versteckte Verachtung gegenueber einer Person hinweisen.',
      'Bei Fragen oft sichtbar, wenn die Antwort unerwuenscht ist.',
    ],
    context: 'Tritt haeufig auf, wenn jemand eine Option verbaepfeln muss, '
        'die er eigentlich ablehnt, aber nicht laut sagen will.',
    tip:
        'Kombiniere es mit dem Zurueckweichen des Kopfes -- beides zusammen ist ein starkes Ablehnungssignal.',
  ),

  // ── Augen ────────────────────────────────────────────────────────────────
  _Signal(
    name: 'Blickkontakt-Intensitaet',
    emoji: '👁️',
    category: 'Augen',
    shortDesc: 'Wie lange und wie direkt Augenkontakt gehalten wird.',
    interpretations: [
      'Zu wenig Blickkontakt (< 30 %): Unsicherheit, Desinteresse oder Luege.',
      'Normaler Blickkontakt (60-70 %): Aufmerksamkeit und Vertrauen.',
      'Erzwungener Dauerkontakt (> 90 %): Dominanzversuch oder Einschuechterung.',
    ],
    context:
        'Kulturgefaerbt: In manchen asiatischen Kulturen gilt gesenkter Blick als Respekt, nicht als Schwaeche.',
    tip:
        'Die "Dreieckmethode": Wechsle den Blick zwischen Augen und Mund in einem Dreieck -- wirkt natuerllich und verbindend.',
  ),
  _Signal(
    name: 'Pupillenerweiterung',
    emoji: '🔮',
    category: 'Augen',
    shortDesc: 'Erweiterung der Pupillen als Reaktion auf Reize.',
    interpretations: [
      'Grosse Pupillen signalisieren Interesse, Aufregung oder Anziehung.',
      'Zusammengezogene Pupillen bei normalem Licht deuten auf Stressreaktion hin.',
      'Pupillen weiten sich auch beim Erkennen einer vertrauten Person.',
    ],
    context:
        'In Verhandlungen: Wenn du ein Angebot praesentierst und Pupillen sich weiten, ist echtes Interesse vorhanden.',
    tip: 'Helle Umgebung halten, um Lichteinfluss zu minimieren und echte '
        'emotionale Pupillenreaktionen leichter zu lesen.',
  ),
  _Signal(
    name: 'Blickrichtung beim Erinnern',
    emoji: '↖️',
    category: 'Augen',
    shortDesc: 'Augenbewegungen beim Erinnern vs. Konstruieren.',
    interpretations: [
      'Oben-links (Rechtsh.): visuelles Erinnern -- Person ruft echte Bilder ab.',
      'Oben-rechts (Rechtsh.): visuelles Konstruieren -- Person entwirft ein neues Bild.',
      'Seitenlinks: auditives Erinnern; Seitenrechts: auditives Konstruieren.',
    ],
    context:
        'NLP-Theorie, wissenschaftlich nicht abgesichert -- als Hypothese nutzen, nicht als Beweis.',
    tip:
        'Beobachte erst die Basislinie: Frage nach einer bekannten, wahren Erinnerung und notiere das Blickmuster der Person.',
  ),

  // ── Haende ───────────────────────────────────────────────────────────────
  _Signal(
    name: 'Offene Handflaechen',
    emoji: '🤲',
    category: 'Haende',
    shortDesc: 'Handflaechenzeigen beim Sprechen oder Begruessen.',
    interpretations: [
      'Offene, sichtbare Handflächen signalisieren Offenheit, Ehrlichkeit und Kooperation.',
      'Haende mit Handflaechenzeigen nach unten druecken Beherrschung und Autoritaet aus.',
      'Haende hinter dem Ruecken halten kann Zurueckhaltung oder Anspannung anzeigen.',
    ],
    context:
        'In Praesentationen steigern offene Gesten die wahrgenommene Glaubwuerdigkeit beim Publikum.',
    tip:
        'Uebt gezielt, Aussagen mit offenen Handgesten zu begleiten -- das wirkt sofort vertrauensbildend.',
  ),
  _Signal(
    name: 'Kirchturmhaende (Steepling)',
    emoji: '⛪',
    category: 'Haende',
    shortDesc: 'Fingerspitzen beider Haende beruehren sich nach oben zeigend.',
    interpretations: [
      'Signalisiert Selbstvertrauen, Kompetenz und Kontrollgefuehl.',
      'Haeufig zu beobachten bei Experten, die sicher ueber ihr Fachgebiet sprechen.',
      'Steepling nach unten (Spitze zeigt bodenwarts) deutet auf defensiveres Selbstvertrauen hin.',
    ],
    context:
        'Manager nutzen Steepling bewusst als Machtgeste -- beobachte es, wenn jemand eine Entscheidung bekanntgibt.',
    tip:
        'Wenn eine Person mitten im Satz von offenen Gesten zu Steepling wechselt, hat sie vermutlich eine klare innere Entscheidung getroffen.',
  ),
  _Signal(
    name: 'Haende reiben',
    emoji: '🤝',
    category: 'Haende',
    shortDesc: 'Schnelles oder langsames Reiben der Handflächen aneinander.',
    interpretations: [
      'Schnelles Reiben: Vorfreude auf ein positives Ergebnis (fuer beide Seiten).',
      'Langsames Reiben: kann Kalkulation oder manipulative Erwartungshaltung andeuten.',
      'Haende reiben bei Kaelte vs. Erregung -- Kontext beachten.',
    ],
    context:
        'In Verkaufsgespraechen oft sichtbar, wenn ein Abschluss nahe ist -- sowohl beim Kaefer als auch beim Verkaeufer.',
    tip:
        'Tempo ist entscheidend: Schnell = freudige Erwartung, langsam = eher taktisches Kalkueren.',
  ),

  // ── Koerperhaltung ────────────────────────────────────────────────────────
  _Signal(
    name: 'Zuwendung / Abwendung des Torsos',
    emoji: '🔄',
    category: 'Koerperhaltung',
    shortDesc: 'Wohin der Oberkörper im Gespräch zeigt.',
    interpretations: [
      'Torso zeigt direkt auf Person: hohes Interesse und Engagement.',
      'Torso dreht sich weg: beginnendes Desinteresse oder Fluchtimpuls.',
      'Fuessse zeigen zur Tuer, waehrend der Kopf noch zugewandt ist: Wunsch das Gespraech zu beenden.',
    ],
    context:
        'In Gruppengespraechen zeigen Fuss- und Torso-Richtung oft, wem die Person tatsaechlich am meisten Aufmerksamkeit schenkt.',
    tip:
        'Beachte: Kopfnicken allein kann Houeflichkeit sein -- erster Indikator fuer echtes Interesse ist der Torso.',
  ),
  _Signal(
    name: 'Spiegeln (Mirroring)',
    emoji: '🪞',
    category: 'Koerperhaltung',
    shortDesc: 'Unbewusstes Nachahmen von Koerperhaltung, Gestik oder Tempo.',
    interpretations: [
      'Gegenseitiges Spiegeln signalisiert Rapport, Sympatie und Vertrauen.',
      'Einseitiges Spiegeln (du spiegelst, die andere Person nicht) kann auf Dominanz oder Desinteresse hinweisen.',
      'Platzendes Spiegeln nach einem Kommentar zeigt oft Ablehnung des Gesagten.',
    ],
    context:
        'Rapport-Technik: Bewusstes Spiegeln der Kouerperhaltung erhoehrt die wahrgenommene Verbundenheit.',
    tip:
        'Beginne mit subtilen Elementen (Atemtakt, Sitzhaltung) -- zu offensichtliches Spiegeln wirkt manipulativ.',
  ),
  _Signal(
    name: 'Geschlossene Koerperhaltung',
    emoji: '🚫',
    category: 'Koerperhaltung',
    shortDesc: 'Verschraenkte Arme, Beine, Abwenden des Koerpers.',
    interpretations: [
      'Armverschraenken deutet auf Schutz, Ablehnung oder Unbehagen hin.',
      'Beine uebereinanderschlagen kann Barriere oder bequeme Gewohnheit sein -- Kontext wichtig.',
      'Kombination aus verschraenkten Armen + Beinbarriere + Kopf zurueck: starkes Ablehnungssignal.',
    ],
    context:
        'Vorsicht: Armverschraenken kann auch Kaelte oder einfach Gewoohnheit bedeuten -- immer den Gesamtkontext lesen.',
    tip:
        'Loese eine Barriere auf, indem du etwas in die Haende gibst (Stift, Broschüre) -- der Koerper oeffnet sich oft automatisch.',
  ),

  // ── Stimme ───────────────────────────────────────────────────────────────
  _Signal(
    name: 'Stimmmodulation',
    emoji: '🎵',
    category: 'Stimme',
    shortDesc: 'Veraenderung von Tonhoehe, Lautstaerke und Sprechtempo.',
    interpretations: [
      'Steigende Tonhoehe am Satzende (Aufwaertsintonation) wirkt unsicher oder fragestellend.',
      'Gleichmaessiges, tiefes Sprechtempo wirkt autoritaer und ueberzeugt.',
      'Sehr schnelles Sprechen kann Nervositaet oder den Wunsch anzeigen, keine Fragen zu bekommen.',
    ],
    context:
        'In Prasentationen und Verhandlungen: Bewusstes Absenken der Stimme bei Kernaussagen verstaerkt deren Wirkung.',
    tip:
        'Uebe die "Abwartsintonation": Wichtige Aussagen mit leichtem Absenkender Stimme enden lassen -- das signalisiert Gewissheit.',
  ),
  _Signal(
    name: 'Fuellwoerter und Pausen',
    emoji: '💬',
    category: 'Stimme',
    shortDesc: '"Aehm", "aehhh", unnatuerliche Pausen beim Sprechen.',
    interpretations: [
      'Haeufige Fuellwoerter vor spezifischen Aussagen koennen auf Unsicherheit oder Nachdenken hindeuten.',
      'Bewusste Pausen (statt Fuellwoertern) wirken selbstsicher und nachdenklich.',
      'Pausen direkt nach einer Frage des Gegenueber: Person verarbeitet noch oder sucht die richtige Antwort.',
    ],
    context:
        'Fuellwoerter allein sind kein Luegenindikator -- sie zeigen kognitiven Aufwand, mehr nicht.',
    tip:
        'Ersetze Fuellwoerter durch kurze Pausen: "Ich denke... (3 Sekunden) das ist richtig" wirkt staerker.',
  ),

  // ── Beruehrung ────────────────────────────────────────────────────────────
  _Signal(
    name: 'Selbstberuehrungen (Adapter)',
    emoji: '✋',
    category: 'Beruehrung',
    shortDesc:
        'Beruehren des eigenen Gesichts, Halses oder Arme im Gespraech.',
    interpretations: [
      'Hals-Beruehren (Halsgrube, Krawattengriff): Anspannung, Unsicherheit oder Stress.',
      'Ohrlaeppchen-Ziehen oder Ohr-Beruehren: Person hoert lieber nicht, was gerade gesagt wird.',
      'Nasen-Reiben: oft mit kognitiver Last verbunden -- kann aber auch einfach jucken.',
    ],
    context:
        'Haeufig nach direkten Fragen oder bei heiklen Themen sichtbar -- erst dann ist der Kontext signifikant.',
    tip:
        'Beobachte Steigerungen: Wenn Adapter-Frequenz im Gespraechsverlauf zunimmt, steigt die innere Anspannung.',
  ),
  _Signal(
    name: 'Schulterklopfen / Arm-Beruehren',
    emoji: '🤜',
    category: 'Beruehrung',
    shortDesc: 'Beruehren des Gegenueber an Schulter oder Arm.',
    interpretations: [
      'Kurzes Schulter-Beruehren drueckt Solidaritaet, Zustimmung oder Dominanzgeste aus.',
      'Haelt jemand den Unterarm der anderen Person fest: will Aufmerksamkeit sichern.',
      'Beruehren zuerst initiiert oft die Person mit hoeherem Status oder groesserer Vertrautheit.',
    ],
    context:
        'Kulturell sehr unterschiedlich: In Deutschland eher selten, in suedlichen Kulturen alltaeglich.',
    tip:
        'Wer zuerst beruehrt, nimmt oft die Dominanzposition ein -- beobachte, wer in einer Gruppe den Erstkontakt initiiert.',
  ),

  // ── Raum ─────────────────────────────────────────────────────────────────
  _Signal(
    name: 'Proximik (Raumnutzung)',
    emoji: '📏',
    category: 'Raum',
    shortDesc: 'Abstand, den Menschen im Gespraech halten.',
    interpretations: [
      '0-45 cm (intime Zone): Familie, enge Freunde, Partner.',
      '45-120 cm (persoenliche Zone): Freunde, Bekanntschaften.',
      '120-360 cm (soziale Zone): formelle Gespraeche, Berufskontext.',
    ],
    context:
        'Eindringen in eine naehere Zone als erlaubt loest Stress aus; bewusstes Zurueckweichen kann Dominanz-Verschiebung anzeigen.',
    tip:
        'In Verhandlungen: Wenn die andere Seite den Tisch ueberquert oder naeher rueckt, signalisiert sie entweder Rapport oder Druckaufbau.',
  ),
  _Signal(
    name: 'Territoriales Verhalten',
    emoji: '🏳️',
    category: 'Raum',
    shortDesc: 'Ausbreiten auf Stuehlen, Tischen oder im Raum.',
    interpretations: [
      'Sich breit auf einem Stuhl ausdehnen: Dominanz und Selbstvertrauen demonstrieren.',
      'Eigene Gegenstaende auf dem Tisch des anderen ausbreiten: territoriales Eindringen.',
      'Aufrecht sitzen ohne Rueckenlehne: Wachsamkeit, erhohte Aufmerksamkeit.',
    ],
    context:
        'In Konferenzraeumen setzen Dominanzpersonen haeufig fruehzeitig Marker (Laptop, Akten) auf dem Tisch, um Raum zu beanspruchen.',
    tip:
        'Halte deinen Raum: Ordne deine Gegenstaende ruhig und besetzt deinen Platz voll -- das signalisiert Praesenz ohne Aggression.',
  ),
];

// ── Screen ───────────────────────────────────────────────────────────────────

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

  List<String> get _categories {
    final cats = <String>{};
    for (final s in _signals) cats.add(s.category);
    return cats.toList()..sort();
  }

  List<_Signal> get _filtered {
    Iterable<_Signal> items = _signals;
    if (_activeCategory != null) {
      items = items.where((s) => s.category == _activeCategory);
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      items = items.where((s) =>
          s.name.toLowerCase().contains(q) ||
          s.category.toLowerCase().contains(q) ||
          s.shortDesc.toLowerCase().contains(q));
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
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: WBGlassAppBar(
        world: WBWorld.vorhang,
        titleWidget: Row(children: [
          const Text('\u{1F440}', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            'KOERPERSPRACHE-DECODER',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w300,
              fontSize: 14,
              letterSpacing: 2.5,
              color: Colors.white,
            ),
          ),
        ]),
      ),
      body: Column(
        children: [
          _buildIntro(),
          _buildSearchBar(),
          _buildCategoryChips(),
          Expanded(child: _buildList(filtered)),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _kGold.withValues(alpha: 0.12),
            _kSurface,
          ],
        ),
        border: Border.all(color: _kGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kGold.withValues(alpha: 0.15),
              border: Border.all(color: _kGold.withValues(alpha: 0.45)),
            ),
            child: const Text('\u{1F9E0}', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Waehl ein nonverbales Signal, um moegliche Bedeutungen, '
              'typische Kontexte und praktische Tipps zur Entschluesselung zu sehen.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white),
        cursorColor: _kGold,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'Signal oder Kategorie suchen ...',
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
        selectedColor: _kGold.withValues(alpha: 0.22),
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

  Widget _buildList(List<_Signal> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, color: _kGold.withValues(alpha: 0.4), size: 48),
            const SizedBox(height: 12),
            Text(
              'Kein Signal gefunden.',
              style:
                  TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _tile(items[i]),
    );
  }

  Widget _tile(_Signal s) {
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
                              fontSize: 14,
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
                        color: Colors.white.withValues(alpha: 0.55),
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

// ── Detail Sheet ─────────────────────────────────────────────────────────────

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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
          children: [
            // Handle bar
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
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kGold.withValues(alpha: 0.12),
                    border: Border.all(color: _kGold.withValues(alpha: 0.4)),
                  ),
                  child: Text(signal.emoji,
                      style: const TextStyle(fontSize: 28)),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _kGold.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          signal.category,
                          style: const TextStyle(
                            color: _kGold,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              signal.shortDesc,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Interpretations
            _label('MOEGLICHE BEDEUTUNGEN'),
            const SizedBox(height: 10),
            for (final m in signal.interpretations) _bullet(m),
            const SizedBox(height: 20),
            // Context
            _label('TYPISCHER KONTEXT'),
            const SizedBox(height: 10),
            _infoBox(
              icon: Icons.location_on_outlined,
              text: signal.context,
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 20),
            // Tip
            _label('PRAXIS-TIPP'),
            const SizedBox(height: 10),
            _infoBox(
              icon: Icons.lightbulb_outline,
              text: signal.tip,
              color: _kGold,
            ),
            const SizedBox(height: 8),
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
    required String text,
    required Color color,
  }) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.35)),
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
