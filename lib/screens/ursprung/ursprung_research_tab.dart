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

  static const _sources = [
    (
      title: 'CIA Reading Room',
      icon: Icons.security,
      desc: 'Über 13 Mio. deklassifizierte CIA-Dokumente',
      url: 'https://www.cia.gov/readingroom/',
    ),
    (
      title: 'Gateway Process Report',
      icon: Icons.auto_awesome,
      desc: 'Das vollständige CIA-Memo zum Gateway Experience (1983)',
      url:
          'https://www.cia.gov/readingroom/document/cia-rdp96-00788r001700210016-5',
    ),
    (
      title: 'STAR GATE Dokumente',
      icon: Icons.visibility,
      desc: 'Deklassifizierte Remote-Viewing-Forschung des US-Militärs',
      url: 'https://www.cia.gov/readingroom/collection/star-gate',
    ),
    (
      title: 'NSA Declassified',
      icon: Icons.article,
      desc: 'Deklassifizierte NSA-Dokumente',
      url: 'https://www.nsa.gov/Press-Room/Declassified-Intelligence/',
    ),
    (
      title: 'Monroe Institute',
      icon: Icons.all_inclusive,
      desc: 'Ressourcen zum Hemi-Sync und Focus-Levels',
      url: 'https://www.monroeinstitute.org/',
    ),
    (
      title: 'ArXiv Quantenbewusstsein',
      icon: Icons.science,
      desc: 'Aktuelle wissenschaftliche Paper zu Bewusstsein & Quantenphysik',
      url:
          'https://arxiv.org/search/?query=consciousness+quantum&searchtype=all',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            ..._sources.map((s) => _buildSourceCard(context, s)),
            const SizedBox(height: 24),
            _buildMentorSection(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _surface,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUELLEN-ARCHIV',
            style: TextStyle(
              color: _cyan,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Deklassifizierte Dokumente & Primärquellen',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceCard(
    BuildContext context,
    ({String title, IconData icon, String desc, String url}) source,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: _cyan, width: 3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(source.icon, color: _cyan, size: 28),
        title: Text(
          source.title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            source.desc,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
          ),
        ),
        trailing: TextButton(
          onPressed: () => launchUrl(Uri.parse(source.url),
              mode: LaunchMode.externalApplication),
          style: TextButton.styleFrom(foregroundColor: _cyan),
          child: const Text('Öffnen →'),
        ),
        onTap: () => launchUrl(Uri.parse(source.url),
            mode: LaunchMode.externalApplication),
      ),
    );
  }

  Widget _buildMentorSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dein Mentor & Module',
            style: TextStyle(
                color: _cyan, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
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
              padding: const EdgeInsets.all(18),
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
                  const Icon(Icons.all_inclusive, color: _cyan, size: 36),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Der Alchemist',
                          style: TextStyle(
                              color: _cyan,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'KI-Mentor für Bewusstsein & hermetisches Wissen',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: _cyan, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.school_outlined),
            label: const Text('Alle Ursprung-Module öffnen'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _cyan,
              side: const BorderSide(color: _cyan),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
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
