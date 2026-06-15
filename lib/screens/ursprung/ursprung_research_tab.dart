// Ursprung research tab -- now a thin config over the shared [ResearchModule]
// (Erweiterung 4). Dynamic topics from Supabase with a local fallback; the
// header/search/card/detail scaffolding is provided by the shared module.

import 'package:flutter/material.dart';

import '../../services/mentor_service.dart';
import '../../services/ursprung_topics_service.dart';
import 'mentor_session_screen.dart';
import '../shared/research_module.dart';
import 'ursprung_modules_screen.dart';

class UrsprungResearchTab extends StatelessWidget {
  const UrsprungResearchTab({super.key});

  static const _cyan = Color(0xFF00D4AA);
  static const _bg = Color(0xFF050510);
  static const _surface = Color(0xFF080818);

  /// Loads topics from Supabase; falls back to a local list if none are
  /// reachable (offline / first launch).
  Future<ResearchLoadResult> _load() async {
    final fetched = await UrsprungTopicsService.instance.fetch();
    if (fetched.isEmpty) {
      return ResearchLoadResult(
        _fallbackTopics.map(_toItem).toList(),
        usedFallback: true,
      );
    }
    return ResearchLoadResult(fetched.map(_toItem).toList());
  }

  ResearchItem _toItem(UrsprungTopic t) => ResearchItem(
        id: t.id,
        title: t.title,
        summary: t.summary,
        detail: t.detailMarkdown,
        icon: t.icon,
        sourceLabel: t.sourceLabel,
        sourceUrl: t.sourceUrl,
      );

  @override
  Widget build(BuildContext context) {
    return ResearchModule(
      world: 'ursprung',
      accent: _cyan,
      background: _bg,
      surface: _surface,
      title: 'BEWUSSTSEINS-ATLAS',
      loader: _load,
      enableSearch: true,
      searchHint: 'Themen durchsuchen ...',
      footerBuilder: _buildFooter,
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 10, top: 4),
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
                builder: (_) => const MentorSessionScreen(
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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

/// Local fallback topics (used when Supabase is unreachable).
const List<UrsprungTopic> _fallbackTopics = [
  UrsprungTopic(
    id: 'fb-gateway',
    title: 'Gateway Experience',
    iconName: 'blur_on',
    summary:
        'Das CIA-Programm zur Erforschung veränderter Bewusstseinszustände.',
    detailMarkdown:
        'Das Monroe Institute entwickelte in den 1970ern die "Gateway Experience" - ein systematisches Trainingsprogramm zur Erreichung veränderter Bewusstseinszustände durch Hemi-Sync-Audiotechnik.\n\n'
        '1983 beauftragte die CIA Major Wayne McDonnell mit einer wissenschaftlichen Analyse. Sein 29-seitiger Bericht (declassifiziert 2003) beschreibt das Bewusstsein als "holographische Energiematrix" und die Focus-Levels als reproduzierbare Bewusstseinszustände:\n\n'
        '- Focus 10 - Körper schläft, Geist wach\n'
        '- Focus 12 - Erweitertes Bewusstsein\n'
        '- Focus 15 - Keine Zeit, keine Lokalität\n'
        '- Focus 21 - Rand zwischen physischer Existenz und anderen Energiesystemen',
    sourceLabel: 'CIA-Dokument öffnen',
    sourceUrl:
        'https://www.cia.gov/readingroom/document/cia-rdp96-00788r001700210016-5',
    sortOrder: 1,
  ),
  UrsprungTopic(
    id: 'fb-remote-viewing',
    title: 'Remote Viewing',
    iconName: 'visibility',
    summary: 'Militärisch erprobtes Protokoll zur Fernwahrnehmung - STAR GATE.',
    detailMarkdown:
        'Das US-Militär finanzierte von 1972-1995 ein geheimes Fernwahrnehmungs-Programm. Erst am SRI (Stanford Research Institute) unter Russell Targ und Hal Puthoff, später als "STAR GATE" am Fort Meade.\n\n'
        '**CRV-Protokoll (6 Stufen):**\n'
        '- Stage I: Gestalt - Form, Größe, Textur\n'
        '- Stage II: Sinneseindruck - Geräusche, Temperatur, Geruch\n'
        '- Stage III: Raumwahrnehmung\n'
        '- Stage IV: Analytische Konzepte\n'
        '- Stage V: Genaue Beschreibung\n'
        '- Stage VI: 3D-Modell-Phase',
    sourceLabel: 'STAR GATE Archiv',
    sourceUrl: 'https://www.cia.gov/readingroom/collection/star-gate',
    sortOrder: 2,
  ),
  UrsprungTopic(
    id: 'fb-hemisync',
    title: 'Hemi-Sync & Gehirnwellen',
    iconName: 'graphic_eq',
    summary: 'Binaural Beats synchronisieren Gehirnhälften für tiefe Zustände.',
    detailMarkdown:
        'Robert Monroe entdeckte zufällig, dass Tonfrequenz-Differenzen zwischen den Ohren reproduzierbare Bewusstseinszustände auslösen.\n\n'
        '**Gehirnwellen:**\n'
        '- Beta (13-30 Hz): Wachbewusstsein, Analyse\n'
        '- Alpha (8-12 Hz): Entspannung, leichte Meditation\n'
        '- Theta (4-7 Hz): Tiefe Meditation, Kreativität\n'
        '- Delta (0.5-3 Hz): Tiefer Schlaf, Regeneration\n'
        '- Gamma (30-100 Hz): Hochkonzentration',
    sourceLabel: 'Monroe Institute',
    sourceUrl: 'https://www.monroeinstitute.org/',
    sortOrder: 3,
  ),
  UrsprungTopic(
    id: 'fb-naturvoelker',
    title: 'Naturvölker-Kosmologie',
    iconName: 'public',
    summary:
        'Hopi, Lakota, Maya - Weltsicht und Prophezeiungen der Ursprungsvölker.',
    detailMarkdown:
        'Naturvölker weltweit teilen erstaunlich ähnliche kosmologische Konzepte:\n\n'
        '**Hopi:** 4 Weltzeitalter, wir leben im 4. (Tawa). Prophezeiungen über "Purification Day".\n\n'
        '**Lakota:** Mitákuye Oyásʼiŋ - "Alles ist miteinander verbunden."\n\n'
        '**Maya:** Langer Kalender endet 2012 - Ende eines 5.125-Jahre-Zyklus (Baktun).\n\n'
        'Gemeinsamer Nenner: Zeit ist zyklisch, Bewusstsein ist primär.',
    sortOrder: 4,
  ),
  UrsprungTopic(
    id: 'fb-quantum',
    title: 'Quantenbewusstsein',
    iconName: 'science',
    summary:
        'Penrose-Hameroff: Bewusstsein als Quantenphänomen in Mikrotubuli.',
    detailMarkdown:
        'Roger Penrose (Nobelpreis 2020) und Stuart Hameroff entwickelten die "Orchestrated Objective Reduction" (Orch-OR) Theorie:\n\n'
        'Bewusstsein entsteht nicht durch klassische Informationsverarbeitung, sondern durch Quantenprozesse in Mikrotubuli - Proteinstrukturen in Neuronen.\n\n'
        'Implikation: Bewusstsein ist fundamental in die Raumzeit eingebettet.',
    sourceLabel: 'ArXiv: Consciousness & Quantum',
    sourceUrl:
        'https://arxiv.org/search/?query=consciousness+quantum&searchtype=all',
    sortOrder: 5,
  ),
  UrsprungTopic(
    id: 'fb-goebekli',
    title: 'Göbekli Tepe & Ursprungswissen',
    iconName: 'account_balance',
    summary:
        '12.000 Jahre alte Tempelanlage widerlegt das Bild früher Zivilisationen.',
    detailMarkdown:
        'Göbekli Tepe (Südosttürkei) ist die älteste bekannte monumentale Kultstätte der Menschheit - 7.000 Jahre älter als Stonehenge.\n\n'
        'Erbaut von Jäger-Sammlern ca. 9.600-8.200 v.Chr. Das widerlegt die These, Architektur und Religion seien Folge der Landwirtschaft.\n\n'
        '**Klaus Schmidt:** "Göbekli Tepe wurde nicht von Hunger gebaut, sondern von Glauben."',
    sortOrder: 6,
  ),
];
