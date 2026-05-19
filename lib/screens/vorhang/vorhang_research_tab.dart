import 'package:flutter/material.dart';

class VorhangResearchTab extends StatelessWidget {
  const VorhangResearchTab({super.key});

  static const _gold = Color(0xFFC9A84C);
  static const _bg = Color(0xFF000000);
  static const _surface = Color(0xFF0D0B00);

  static const _categories = [
    _Category(
      title: 'Machtpsychologie',
      icon: Icons.psychology_rounded,
      concepts: [
        _Concept(
          name: '48 Gesetze der Macht',
          summary:
              'Robert Greenes Standardwerk über Machtdynamiken in Gesellschaft und Politik.',
          detail:
              'Robert Greene analysiert in seinen 48 Gesetzen historische Machtkämpfe von Ludwigs XIV. bis zu modernen CEOs. '
              'Kernprinzipien: Niemals den Chef überstrahlen (Gesetz 1), Handlungen durch Stellvertreter ausführen lassen (Gesetz 26), '
              'Lob nutzen um zu kontrollieren (Gesetz 33). Macht ist kein Zustand, sondern ein Spiel – wer es nicht versteht, verliert automatisch.\n\n'
              'Praxis: Identifiziere in deinem Umfeld, wer wirklich Entscheidungen trifft vs. wer nominell führt.',
        ),
        _Concept(
          name: 'Dunkle Triade',
          summary:
              'Narzissmus, Machiavellismus und Psychopathie als Machtprofil.',
          detail:
              'Psychologische Forschung zeigt: Personen mit hohen Werten in der Dunklen Triade steigen überproportional in Führungspositionen auf. '
              'Narzissmus liefert Selbstpräsentation und Charisma. Machiavellismus ermöglicht strategische Manipulation ohne emotionale Hemmung. '
              'Psychopathie sorgt für Kälte unter Druck und Risikobereitschaft.\n\n'
              'Praxis: Erkenne diese Muster in Führungspersonen um dich – nicht um sie zu imitieren, sondern um dich zu schützen.',
        ),
        _Concept(
          name: 'Soziale Dominanzhierarchien',
          summary:
              'Wie Statusspiele in Gruppen funktionieren (Jordan Peterson, Lorenz).',
          detail:
              'Status in sozialen Gruppen wird nonverbal kommuniziert und unbewusst registriert. Körperhaltung, Tonlage, Raumnahme – '
              'alle signalisieren Rang. Wer den Raum betritt und sich setzt, bevor andere sitzen, signalisiert automatisch Dominanz. '
              'Konrad Lorenz beschrieb diese Muster bei Tieren, Peterson übertrug sie auf menschliche Hierarchien.\n\n'
              'Praxis: Senke nie den Blick zuerst, nimm dir physisch Raum, sprich langsamer als du glaubst.',
        ),
        _Concept(
          name: 'Framing & Deutungshoheit',
          summary: 'Wer den Rahmen setzt, gewinnt – unabhängig vom Inhalt.',
          detail:
              'George Lakoff zeigte: Menschen denken in Frames (Rahmen). Wer den Frame definiert, kontrolliert die Diskussion. '
              '"Erbschaftssteuer" vs. "Todessteuer" – gleiche Realität, entgegengesetzte emotionale Wirkung. '
              'In Verhandlungen, Konflikten und Politik gilt: Wer reagiert, übernimmt implizit den Frame des anderen.\n\n'
              'Praxis: Antworte nie auf den Inhalt einer Frage, wenn der Frame falsch ist – setze zuerst deinen eigenen.',
        ),
      ],
    ),
    _Category(
      title: 'Manipulationstechniken',
      icon: Icons.theater_comedy_rounded,
      concepts: [
        _Concept(
          name: 'Gaslighting',
          summary:
              'Systematische Realitätsverdrehung zur psychologischen Kontrolle.',
          detail:
              'Gaslighting (nach dem Film "Gaslight", 1944) beschreibt die gezielte Manipulation, bei der das Opfer '
              'seine eigene Wahrnehmung in Frage stellt. Typische Aussagen: "Das hast du dir eingebildet", "Du bist zu sensibel", '
              '"Das habe ich nie gesagt." Ziel ist die vollständige Abhängigkeit des Opfers vom Täter als Realitätsinstanz.\n\n'
              'Schutz: Führe ein Tagebuch über Gespräche. Gaslighting verliert seine Wirkung wenn du externe Beweise hast.',
        ),
        _Concept(
          name: 'Love Bombing',
          summary: 'Überwältigende Zuneigung als Manipulationsstrategie.',
          detail:
              'Love Bombing ist die Phase extremer Idealisierung zu Beginn einer Beziehung. Massives Lob, Geschenke, '
              'Daueraufmerksamkeit – alles in einem Tempo das normale soziale Grenzen überschreitet. '
              'Das Ziel ist emotionale Abhängigkeit aufzubauen bevor der eigentliche Missbrauch beginnt. '
              'Häufig genutzt von narzisstischen Persönlichkeiten und Sekten.\n\n'
              'Warnsignal: Wenn jemand zu schnell zu viel gibt – frage warum.',
        ),
        _Concept(
          name: 'DARVO',
          summary: 'Deny, Attack, Reverse Victim and Offender.',
          detail:
              'DARVO ist das Muster mit dem Täter auf Konfrontation reagieren: Leugnen (Deny), Angreifen (Attack), '
              'dann die Rollen umkehren (Reverse Victim and Offender) – plötzlich ist der Täter das Opfer. '
              'Jennifer Freyd (Uni Oregon) dokumentierte das Muster ursprünglich bei Missbrauchstätern, '
              'heute findet es sich in Politik, Unternehmensführung und privaten Konflikten.\n\n'
              'Praxis: Wenn jemand bei einer sachlichen Konfrontation sofort angreift und sich victimisiert – erkenne das Muster.',
        ),
        _Concept(
          name: 'Sekten-Taktiken',
          summary:
              'Love Bombing, Isolation, Loaded Language, Demand for Purity.',
          detail:
              'Robert Liftons "Thought Reform and the Psychology of Totalism" (1961) identifiziert 8 Kriterien für Gedankenkontrolle: '
              'Milieu Control (Kontrolle der Umgebung), Mystical Manipulation, Demand for Purity, Confession, Sacred Science, '
              'Loading the Language, Doctrine over Person, Dispensing of Existence. '
              'Diese Taktiken finden sich nicht nur in religiösen Kulten, sondern auch in politischen Bewegungen und Unternehmen.\n\n'
              'Praxis: Je mehr einer Gruppe du nicht angehören kannst ohne alles zu verlieren, desto mehr Macht hat sie über dich.',
        ),
      ],
    ),
    _Category(
      title: 'Verhandlung & Überzeugung',
      icon: Icons.handshake_rounded,
      concepts: [
        _Concept(
          name: 'Harvard-Konzept',
          summary: 'Sachbezogenes Verhandeln nach Fisher & Ury.',
          detail:
              '"Getting to Yes" (Fisher, Ury, 1981): Trenne Menschen vom Problem. Konzentriere dich auf Interessen, nicht Positionen. '
              'Entwickle Optionen zum beiderseitigen Vorteil. Bestehe auf objektiven Kriterien. '
              'Die Methode ist defensiv stark – sie schützt vor emotionaler Eskalation und Machtspiele durch sachliche Anker.\n\n'
              'Praxis: Frage immer "Was ist dein eigentliches Ziel?" – die genannte Position ist fast nie das wahre Interesse.',
        ),
        _Concept(
          name: 'Chris Voss Taktiken',
          summary:
              'FBI-Verhandlungsführer: Taktisches Einfühlungsvermögen & "No"-Orientierung.',
          detail:
              'Chris Voss ("Never Split the Difference") lehrt FBI-Verhandlungstaktiken für den Alltag: '
              'Tactical Empathy (den emotionalen Zustand benennen ohne zu bewerten), Calibrated Questions ("Wie soll ich das schaffen?"), '
              'The Accusation Audit (Einwände vorwegnehmen), "That\'s right" als Zielzustand (nicht "You\'re right"). '
              'Kern: Menschen wollen verstanden werden bevor sie überzeugt werden.\n\n'
              'Praxis: Ersetze "Warum" durch "Was" und "Wie" – weniger defensiv, mehr lösungsorientiert.',
        ),
        _Concept(
          name: 'Cialdini: 6 Prinzipien',
          summary:
              'Reziprozität, Knappheit, Autorität, Konsistenz, Sympathie, Konsens.',
          detail:
              'Robert Cialdinis "Influence" (1984) ist das meistzitierte Werk der Überzeugungspsychologie. '
              'Reziprozität: Wer gibt, bekommt zurück – immer. Knappheit: Was selten ist, wirkt wertvoller. '
              'Autorität: Titel und Symbole erhöhen Compliance. Konsistenz: Menschen bleiben bei einmal getroffenen Entscheidungen. '
              'Sympathie: Wir sagen Ja zu Menschen die wir mögen. Konsens: Wir orientieren uns an was andere tun.\n\n'
              'Praxis: Erkenne bei jedem Angebot welches Prinzip genutzt wird – dann entscheide rational.',
        ),
        _Concept(
          name: 'Reframing',
          summary:
              'Bedeutung durch neuen Rahmen verändern ohne Fakten zu ändern.',
          detail:
              'Reframing verändert nicht die Realität, sondern die Perspektive auf sie. "Das Glas ist halb leer" vs. "halb voll" '
              'ist banal – aber: "Wir haben 40% Kundenverlust" vs. "60% unserer Kunden sind noch bei uns" aktiviert '
              'fundamental andere Handlungsimpulse. In Verhandlungen: Wer zuerst reframt, dominiert die Agenda.\n\n'
              'Praxis: Formuliere jedes Problem als Ressource ("Was haben wir, das wir nutzen können?").',
        ),
      ],
    ),
    _Category(
      title: 'Körpersprache & Nonverbales',
      icon: Icons.accessibility_new_rounded,
      concepts: [
        _Concept(
          name: 'Mikroexpressionen (Ekman)',
          summary: 'Unbewusste Gesichtsausdrücke die echte Emotionen zeigen.',
          detail:
              'Paul Ekman (FACS – Facial Action Coding System) identifizierte 7 universelle Basisemotionen die '
              'kulturunabhängig in Gesichtern erscheinen: Freude, Trauer, Angst, Ekel, Überraschung, Verachtung, Wut. '
              'Mikroexpressionen dauern 1/25 bis 1/5 Sekunde und sind schwer zu unterdrücken. '
              'Verachtung (einseitiges Mundwinkelziehen) ist oft der verlässlichste Indikator für echte Ablehnung.\n\n'
              'Praxis: Übe mit Ekmans FACS-Trainingssoftware oder achte auf Diskrepanzen zwischen Worten und Gesicht.',
        ),
        _Concept(
          name: 'Power Poses',
          summary:
              'Körperhaltung beeinflusst Hormonspiegel und Risikobereitschaft.',
          detail:
              'Amy Cuddys Forschung (Harvard, 2010) zeigte: 2 Minuten in einer "Power Pose" erhöhen Testosteron und senken Cortisol. '
              'Kontroverse: Direkte Replikationen waren gemischt, aber subjektives Selbstvertrauen steigt konsistent. '
              'Der Mechanismus: Körper und Geist kommunizieren bidirektional – Haltung beeinflusst Stimmung genauso wie umgekehrt.\n\n'
              'Praxis: Vor wichtigen Gesprächen: 2 Minuten aufrecht stehen, Schultern zurück, Kinn leicht hoch.',
        ),
        _Concept(
          name: 'Lügenerkennung',
          summary:
              'Kein einzelnes Signal – Verhaltensbaselines und Abweichungen.',
          detail:
              'Lügen erkennen ist keine Frage einzelner Signale sondern von Baseline-Abweichungen. '
              'Jeder Mensch hat individuelle Verhaltensmuster wenn er entspannt ist. Stress-Indikatoren (Blickabwenden, Berühren des Gesichts, '
              'Stimmveränderungen) sind nur bei Abweichung von der persönlichen Baseline bedeutsam. '
              'Das FBI nutzt "Statement Analysis" – Lügner sind oft zu detailliert oder auffällig vage.\n\n'
              'Praxis: Beobachte jemanden 5 Minuten bei entspannter Konversation bevor du eine kritische Frage stellst.',
        ),
        _Concept(
          name: 'Stimme als Machtinstrument',
          summary: 'Tonlage, Tempo und Pausen als Führungssignale.',
          detail:
              'Forschung zeigt: Stimmen mit tieferer Tonlage werden als kompetenter und vertrauenswürdiger wahrgenommen. '
              'Langsames Sprechen signalisiert Selbstsicherheit (Nervosität beschleunigt das Sprechtempo). '
              'Strategische Pausen: Wer nach einer Aussage schweigt, erzeugt Druck beim Gegenüber zu reagieren. '
              'Margaret Thatcher ließ ihre Stimme professionell trainieren um tiefer zu klingen.\n\n'
              'Praxis: Sprich bewusst 20% langsamer als du es für nötig hältst – die Wirkung ist sofort spürbar.',
        ),
      ],
    ),
    _Category(
      title: 'Strategisches Denken',
      icon: Icons.flag_rounded,
      concepts: [
        _Concept(
          name: 'Sun Tzus Kunst des Krieges',
          summary:
              '2.500 Jahre alte Strategielehre – heute in Wirtschaft und Politik.',
          detail:
              '"Die höchste Kunst des Krieges ist es, den Feind zu besiegen ohne zu kämpfen." Sun Tzu, ca. 500 v.Chr. '
              'Kernprinzipien: Kenne deinen Feind und dich selbst. Nutze Täuschung als primäres Werkzeug. '
              'Geschwindigkeit schlägt Stärke. Anpassen schlägt starre Strategie. '
              'Heute genutzt: Amazon-Strategie (Marktdominanz ohne direkte Konfrontation), politische Kampagnenführung.\n\n'
              'Praxis: Vor jedem Konflikt: Was will der andere WIRKLICH? Selten ist es das was er sagt.',
        ),
        _Concept(
          name: 'OODA-Loop',
          summary:
              'Observe-Orient-Decide-Act: Schneller entscheiden als der Gegner.',
          detail:
              'John Boyd (US Air Force) entwickelte den OODA-Loop aus Luftkampf-Analysen. '
              'Wer den OODA-Zyklus schneller durchläuft als der Gegner, gewinnt – nicht wer stärker ist. '
              'Orientierung (Orient) ist der kritische Schritt: Vergangene Erfahrungen, kulturelle Prägung und '
              'mentale Modelle bestimmen wie wir neue Informationen interpretieren. '
              'Den Gegner zu verwirren (in seine Orient-Phase einzugreifen) ist mächtiger als direkte Überlegenheit.\n\n'
              'Praxis: Schaffe bewusst Unklarheit in Verhandlungen – wer verwirrt ist, agiert reaktiv.',
        ),
        _Concept(
          name: 'Spieltheorie',
          summary:
              'Nash-Gleichgewicht, Prisoners Dilemma und strategische Entscheidungen.',
          detail:
              'Spieltheorie (von Neumann/Morgenstern, Nash) modelliert Entscheidungen bei denen das Ergebnis von '
              'den Entscheidungen anderer abhängt. Gefangenendilemma: Individuell rationale Entscheidungen führen zu '
              'kollektiv schlechteren Ergebnissen. Nash-Gleichgewicht: Ein Zustand in dem keine Seite durch '
              'unilaterale Änderung besser gestellt wird. Geopolitik, Kartellpreise, Rüstungswettläufe – überall.\n\n'
              'Praxis: Frage bei jedem Konflikt: Was ist mein bester Zug wenn der andere optimal spielt?',
        ),
        _Concept(
          name: 'Systemisches Denken',
          summary:
              'Feedbackschleifen, Hebelwirkung und unbeabsichtigte Konsequenzen.',
          detail:
              'Peter Senges "Die fünfte Disziplin" (1990) und Donella Meadows "Thinking in Systems": '
              'Komplexe Systeme haben Feedback-Schleifen (verstärkend und ausgleichend), Verzögerungen und '
              'Kipppunkte. Interventionen an offensichtlichen Stellen wirken oft gegenteilig. '
              'Hebelwirkung entsteht an unerwarteten Stellen – meistens in Informationsflüssen und Zielen, nicht in physischen Ressourcen.\n\n'
              'Praxis: Zeichne bei jedem Problem die Kausalschleifen auf – erst dann siehst du die Hebelwirkung.',
        ),
      ],
    ),
    _Category(
      title: 'Schattenarbeit',
      icon: Icons.nights_stay_rounded,
      concepts: [
        _Concept(
          name: 'Jungs Schatten',
          summary:
              'Die verdrängte Seite der Persönlichkeit als Quelle verborgener Macht.',
          detail:
              'Carl Gustav Jung: Der "Schatten" enthält alles was wir an uns selbst verleugnen – Aggression, Neid, '
              'Lust, Schwäche, Größenphantasien. Was wir verdrängen, projizieren wir auf andere. '
              '"Wer nach innen schaut, erwacht. Wer nach außen schaut, träumt." '
              'Schattenintegration ist kein Ausleben des Schattens, sondern das bewusste Erkennen und Integrieren '
              'dieser Energien als Ressource.\n\n'
              'Praxis: Was dich an anderen extrem stört, ist oft eine Projektion deines eigenen Schattens.',
        ),
        _Concept(
          name: 'Projektion erkennen',
          summary:
              'Eigene verdrängte Inhalte im Spiegel anderer Menschen sehen.',
          detail:
              'Projektion ist der unbewusste Mechanismus, eigene unangenehme Eigenschaften in anderen zu sehen. '
              'Wenn du jemanden als "lügnerisch" wahrnimmst – prüfe wann du selbst unehrlich bist. '
              'Wenn du jemanden als "zu dominant" erlebst – prüfe deine eigene unterdrückte Machtlust. '
              'Projektion kostet psychische Energie und verzerrt die Wahrnehmung der Realität.\n\n'
              'Praxis: Führe eine "Spiegelliste": Notiere 3 Eigenschaften die dich an anderen stören – und prüfe sie bei dir.',
        ),
        _Concept(
          name: 'Goldener Schatten',
          summary:
              'Positive Fähigkeiten die wir in anderen bewundern aber uns selbst absprechen.',
          detail:
              'Der goldene Schatten (Debbie Ford) enthält unsere positiven, aber verdrängten Anteile. '
              'Wenn du jemanden stark bewunderst – was genau bewunderst du? Oft sind es Eigenschaften die du dir '
              'selbst nicht erlaubst. Charisma, Kreativität, Stärke, Freiheit – was du in anderen bewunderst, '
              'liegt auch in dir, wurde aber früh unterdrückt.\n\n'
              'Praxis: Liste 3 Menschen die du bewunderst. Was genau ist es? Das ist dein goldener Schatten – reclaim it.',
        ),
        _Concept(
          name: 'Innerer Kritiker',
          summary:
              'Die internalisierte Stimme der Unterdrückung und ihre Neutralisierung.',
          detail:
              'Der innere Kritiker ist die Stimme die sagt: "Du bist nicht gut genug", "Wer bist du dass du..." '
              'Er entsteht durch frühe Prägungen und dient ursprünglich dem Schutz vor sozialer Ablehnung. '
              'In der Schattenarbeit wird er nicht bekämpft sondern dialogisiert – als ein Teil der Psyche '
              'der Angst hat. Byron Katies "The Work" und IFS (Internal Family Systems) sind effektive Methoden.\n\n'
              'Praxis: Wenn der innere Kritiker spricht: "Stimmt das? Absolut sicher?" – fast nie.',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: _categories.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) return _buildHeader();
          return _CategoryCard(category: _categories[i - 1]);
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PSYCHOLOGIE-KOMPENDIUM',
            style: TextStyle(
              color: _gold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '6 Kategorien · ${_categories.fold(0, (s, c) => s + c.concepts.length)} Konzepte',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _Category {
  final String title;
  final IconData icon;
  final List<_Concept> concepts;
  const _Category(
      {required this.title, required this.icon, required this.concepts});
}

class _Concept {
  final String name, summary, detail;
  const _Concept(
      {required this.name, required this.summary, required this.detail});
}

class _CategoryCard extends StatefulWidget {
  final _Category category;
  const _CategoryCard({required this.category, super.key});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  static const _gold = Color(0xFFC9A84C);
  static const _surface = Color(0xFF0D0B00);
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: _gold, width: 3)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(widget.category.icon, color: _gold, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.category.concepts.length} Konzepte',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down,
                        color: _gold.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(color: _gold.withValues(alpha: 0.15), height: 1),
                ...widget.category.concepts
                    .map((c) => _ConceptTile(concept: c))
                    .toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConceptTile extends StatelessWidget {
  final _Concept concept;
  const _ConceptTile({required this.concept, super.key});

  static const _gold = Color(0xFFC9A84C);
  static const _surface = Color(0xFF0D0B00);

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        builder: (_, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                concept.name,
                style: const TextStyle(
                    color: _gold, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                concept.summary,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              Divider(color: _gold.withValues(alpha: 0.2)),
              const SizedBox(height: 12),
              Text(
                concept.detail,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14, height: 1.65),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showDetail(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration:
                  const BoxDecoration(color: _gold, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    concept.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    concept.summary,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: _gold.withValues(alpha: 0.5), size: 18),
          ],
        ),
      ),
    );
  }
}
