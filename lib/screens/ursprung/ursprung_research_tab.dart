import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/mentor_service.dart';
import '../shared/mentor_chat_screen.dart';
import 'ursprung_modules_screen.dart';

class UrsprungResearchTab extends StatelessWidget {
  const UrsprungResearchTab({super.key});

  static const _cyan = Color(0xFF00D4AA);
  static const _bg = Color(0xFF050510);
  static const _surface = Color(0xFF080818);

  static const _topics = [
    _Topic(
      title: 'Gateway Experience',
      icon: Icons.blur_on_rounded,
      summary: 'Das CIA-Programm zur Erforschung veränderter Bewusstseinszustände.',
      detail:
          'Das Monroe Institute entwickelte in den 1970ern die "Gateway Experience" — ein systematisches Trainingsprogramm '
          'zur Erreichung veränderter Bewusstseinszustände durch Hemi-Sync-Audiotechnik.\n\n'
          '1983 beauftragte die CIA Major Wayne McDonnell mit einer wissenschaftlichen Analyse. '
          'Sein 29-seitiger Bericht (declassifiziert 2003) beschreibt das Bewusstsein als "holographische Energiematrix" '
          'und die Focus-Levels als reproduzierbare Bewusstseinszustände:\n\n'
          '• Focus 10 — Körper schläft, Geist wach\n'
          '• Focus 12 — Erweitertes Bewusstsein, erste Wahrnehmungen jenseits der Sinne\n'
          '• Focus 15 — Keine Zeit, keine Lokalität\n'
          '• Focus 21 — Rand zwischen physischer Existenz und anderen Energiesystemen\n\n'
          'McDonnells Fazit: Das Programm funktioniert. Die zugrundeliegenden Mechanismen sind physikalisch erklärbar '
          'über Resonanz, Holographie und Quantenphysik.',
      sourceLabel: 'CIA-Dokument öffnen',
      sourceUrl:
          'https://www.cia.gov/readingroom/document/cia-rdp96-00788r001700210016-5',
    ),
    _Topic(
      title: 'Remote Viewing',
      icon: Icons.visibility_rounded,
      summary: 'Militärisch erprobtes Protokoll zur Fernwahrnehmung — STAR GATE.',
      detail:
          'Das US-Militär finanzierte von 1972–1995 ein geheimes Fernwahrnehmungs-Programm. '
          'Erst am SRI (Stanford Research Institute) unter Russell Targ und Hal Puthoff, '
          'später als "STAR GATE" am Fort Meade unter militärischer Leitung.\n\n'
          'Ingo Swann und Pat Price erzielten in kontrollierten Experimenten statistisch signifikante Ergebnisse. '
          'Swann entwickelte das CRV-Protokoll (Controlled Remote Viewing) mit 6 Stufen:\n\n'
          '1. Stage I — Gestalt: Form, Größe, Textur\n'
          '2. Stage II — Sinneseindruck: Geräusche, Temperatur, Geruch\n'
          '3. Stage III — Raumwahrnehmung und Dimensionen\n'
          '4. Stage IV — Analytische Überzeugungen, Konzepte\n'
          '5. Stage V — Genaue Beschreibung von Teilen des Ziels\n'
          '6. Stage VI — 3D-Modell-Phase\n\n'
          'Die CIA-Abschluss­bewertung (1995): Statistisch valide, aber kein "operational intelligence tool".',
      sourceLabel: 'STAR GATE Archiv',
      sourceUrl: 'https://www.cia.gov/readingroom/collection/star-gate',
    ),
    _Topic(
      title: 'Hemi-Sync & Gehirnwellen',
      icon: Icons.graphic_eq_rounded,
      summary: 'Binaural Beats synchronisieren Gehirnhälften für tiefe Zustände.',
      detail:
          'Robert Monroe entdeckte zufällig, dass bestimmte Tonfrequenz-Differenzen zwischen den Ohren '
          'reproduzierbare Bewusstseinszustände auslösen. Das Gehirn "berechnet" die Differenz und erzeugt '
          'eine Eigenfrequenz — den Binaural Beat.\n\n'
          'Gehirnwellen und ihre Zustände:\n'
          '• Beta (13–30 Hz) — Normales Wachbewusstsein, Analyse\n'
          '• Alpha (8–12 Hz) — Entspannung, leichte Meditation\n'
          '• Theta (4–7 Hz) — Tiefe Meditation, Hypnagogie, Kreativität\n'
          '• Delta (0.5–3 Hz) — Tiefer Schlaf, Regeneration\n'
          '• Gamma (30–100 Hz) — Hochkonzentration, Spitzenerfahrungen\n\n'
          'Hemi-Sync-Audiospuren enthalten spezifische Binaural Beats um gezielt '
          'zwischen Focus-Levels zu navigieren. Das Monroe Institute hat über 50 Jahre Forschungsdaten.',
      sourceLabel: 'Monroe Institute',
      sourceUrl: 'https://www.monroeinstitute.org/',
    ),
    _Topic(
      title: 'Naturvölker-Kosmologie',
      icon: Icons.public_rounded,
      summary: 'Hopi, Lakota, Maya — Weltsicht und Prophezeiungen der Ursprungsvölker.',
      detail:
          'Naturvölker weltweit teilen erstaunlich ähnliche kosmologische Konzepte:\n\n'
          'Hopi (Nordamerika): 4 Weltzeitalter — wir leben im 4. (Tawa). Prophezeiungen über '
          '"Purification Day" wenn der Schwiegersohn aus dem Osten kommt und das Gleichgewicht zerstört.\n\n'
          'Lakota (Plains): Die Schwarzen Berge (Black Hills) als Nabel der Welt. '
          'Mitákuye Oyásʼiŋ — "Alles ist miteinander verbunden." Der Medizinmann Black Elk beschrieb '
          'außerkörperliche Visionen im Kindesalter die er später im Westen als "normal" bestätigt fand.\n\n'
          'Maya: Langer Kalender endet 2012 — nicht "Weltuntergang" sondern Ende eines 5.125-Jahre-Zyklus '
          '(Baktun). Bewusstseinswandel als Übergang, nicht Apokalypse.\n\n'
          'Gemeinsamer Nenner: Zeit ist zyklisch, Bewusstsein ist primär, Materie ist sekundär.',
      sourceLabel: null,
      sourceUrl: null,
    ),
    _Topic(
      title: 'Quantenbewusstsein',
      icon: Icons.science_rounded,
      summary: 'Penrose-Hameroff: Bewusstsein als Quantenphänomen in Mikrotubuli.',
      detail:
          'Roger Penrose (Mathematiker, Physik-Nobelpreis 2020) und Stuart Hameroff (Anästhesist) '
          'entwickelten die "Orchestrated Objective Reduction" (Orch-OR) Theorie:\n\n'
          'Kern: Bewusstsein entsteht nicht durch klassische Informationsverarbeitung im Gehirn, '
          'sondern durch Quantenprozesse in Mikrotubuli — Proteinstrukturen innerhalb von Neuronen. '
          'Diese Quantenprozesse kollabieren ("objektive Reduktion") in einer Weise die von der '
          'Raumzeit-Geometrie beeinflusst wird.\n\n'
          'Implikation: Bewusstsein ist kein emergentes Phänomen von Neuronen, sondern fundamental '
          'in die Struktur der Raumzeit eingebettet. Damit wäre Bewusstsein nicht auf das Gehirn '
          'beschränkt.\n\n'
          'Kritik: Dekoherenz-Zeiten im warmen, nassen Gehirn zu kurz für stabile Quantenprozesse. '
          'Gegenargument (Hameroff 2014): Neue Daten zeigen länger stabile Quantenkohärenz in biologischen Systemen.',
      sourceLabel: 'ArXiv: Consciousness & Quantum',
      sourceUrl:
          'https://arxiv.org/search/?query=consciousness+quantum&searchtype=all',
    ),
    _Topic(
      title: 'Göbekli Tepe & Ursprungswissen',
      icon: Icons.account_balance_rounded,
      summary: '12.000 Jahre alte Tempelanlage widerlegt das Bild früher Zivilisationen.',
      detail:
          'Göbekli Tepe (Südosttürkei, ausgegraben ab 1994) ist die älteste bekannte monumentale Kultstätte '
          'der Menschheit — 7.000 Jahre älter als Stonehenge, 6.000 Jahre älter als die Pyramiden.\n\n'
          'Erbaut von Jäger-Sammlern ca. 9.600–8.200 v.Chr. Das widerlegt die These, Architektur und Religion '
          'seien Folge der Landwirtschaft. Stattdessen: Möglicherweise entstand Landwirtschaft als Konsequenz '
          'der kollektiven Anstrengungen rund um diese Kultstätten.\n\n'
          'Forscher Klaus Schmidt: "Göbekli Tepe wurde nicht von Hunger gebaut, sondern von Glauben."\n\n'
          'Die Anlage wurde absichtlich begraben — bis heute unerklärt warum. '
          'Nur 5% der Anlage sind ausgegraben. Tierdarstellungen zeigen Symbole die in späteren Kulturen '
          '(Ägypten, Sumer) als heilig gelten.',
      sourceLabel: null,
      sourceUrl: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 0, bottom: 80),
        itemCount: _topics.length + 2,
        itemBuilder: (context, i) {
          if (i == 0) return _buildHeader();
          if (i == _topics.length + 1) return _buildFooter(context);
          return _TopicCard(topic: _topics[i - 1]);
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
            'BEWUSSTSEINS-ATLAS',
            style: TextStyle(
              color: _cyan,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_topics.length} Themengebiete · In-App lesbar',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'Dein Mentor & Module',
              style: TextStyle(
                  color: _cyan, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MentorChatScreen(
                  personality: MentorPersonality.alchemist,
                  world: 'ursprung',
                ),
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_surface, _cyan.withValues(alpha: 0.12)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: const Border(left: BorderSide(color: _cyan, width: 3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.all_inclusive, color: _cyan, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Der Alchemist',
                            style: TextStyle(
                                color: _cyan,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 3),
                        Text(
                          'KI-Mentor für Bewusstsein & hermetisches Wissen',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: _cyan, size: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.school_outlined, size: 18),
            label: const Text('Alle Ursprung-Module öffnen'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _cyan,
              side: const BorderSide(color: _cyan),
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 0),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UrsprungModulesScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _Topic {
  final String title, summary, detail;
  final IconData icon;
  final String? sourceLabel, sourceUrl;
  const _Topic({
    required this.title,
    required this.summary,
    required this.detail,
    required this.icon,
    this.sourceLabel,
    this.sourceUrl,
  });
}

class _TopicCard extends StatefulWidget {
  final _Topic topic;
  const _TopicCard({required this.topic, super.key});

  @override
  State<_TopicCard> createState() => _TopicCardState();
}

class _TopicCardState extends State<_TopicCard> {
  static const _cyan = Color(0xFF00D4AA);
  static const _surface = Color(0xFF080818);

  void _showDetail() {
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
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: _cyan.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(widget.topic.icon, color: _cyan, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.topic.title,
                      style: const TextStyle(
                          color: _cyan, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.topic.summary,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13,
                    fontStyle: FontStyle.italic),
              ),
              Divider(
                  color: _cyan.withValues(alpha: 0.2),
                  height: 28),
              Text(
                widget.topic.detail,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14, height: 1.65),
              ),
              if (widget.topic.sourceUrl != null) ...[
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 15),
                  label: Text(widget.topic.sourceLabel ?? 'Quelle öffnen'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _cyan,
                    side: BorderSide(color: _cyan.withValues(alpha: 0.6)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => launchUrl(
                    Uri.parse(widget.topic.sourceUrl!),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: _cyan, width: 3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _showDetail,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(widget.topic.icon, color: _cyan, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.topic.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.topic.summary,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: _cyan.withValues(alpha: 0.5), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
