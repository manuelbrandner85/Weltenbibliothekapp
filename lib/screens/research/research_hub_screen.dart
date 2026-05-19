// Research-Hub: zentrale Startseite fuer alle R1-R8 Recherche-Tools.

import 'package:flutter/material.dart';

import '../materie/kaninchenbau/screens/investigation_board_screen.dart';
import 'additional_sources_screen.dart';
import 'cross_reference_screen.dart';
import 'document_archive_screen.dart';
import 'timeline_screen.dart';

class ResearchHubScreen extends StatelessWidget {
  const ResearchHubScreen({super.key});

  static const _accent = Color(0xFFE53935);
  static const _bg = Color(0xFF0A0A0A);
  static const _surface = Color(0xFF1A0000);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        title: const Text('RECHERCHE-TOOLS',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        iconTheme: const IconThemeData(color: _accent),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
        children: [
          _toolCard(
            context,
            icon: Icons.timeline,
            title: 'Timeline',
            subtitle: 'Whistleblower & Leaks chronologisch',
            color: const Color(0xFFE53935),
            screen: const ResearchTimelineScreen(),
          ),
          _toolCard(
            context,
            icon: Icons.hub_outlined,
            title: 'Cross-Reference',
            subtitle: '7 Quellen parallel durchsuchen',
            color: const Color(0xFFAB47BC),
            screen: const CrossReferenceScreen(),
          ),
          _toolCard(
            context,
            icon: Icons.picture_as_pdf_outlined,
            title: 'Dokumenten-Archiv',
            subtitle: 'PDFs mit Volltextsuche',
            color: const Color(0xFF66BB6A),
            screen: const DocumentArchiveScreen(),
          ),
          _toolCard(
            context,
            icon: Icons.account_tree_outlined,
            title: 'Investigation-Board',
            subtitle: 'Pinnwand mit Verbindungen',
            color: const Color(0xFFFFA726),
            screen: const InvestigationBoardScreen(),
          ),
          _toolCard(
            context,
            icon: Icons.travel_explore,
            title: 'Quellen-Browser',
            subtitle: 'FOIA, Archives, In-App-Browser',
            color: const Color(0xFF42A5F5),
            screen: const AdditionalSourcesScreen(),
          ),
          _toolCard(
            context,
            icon: Icons.online_prediction,
            title: 'Event-Predictor',
            subtitle: 'Live + Community + Archiv',
            color: const Color(0xFFE91E63),
            routeName: '/event-predictor',
          ),
        ],
      ),
    );
  }

  Widget _toolCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    Widget? screen,
    String? routeName,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (routeName != null) {
          Navigator.pushNamed(context, routeName);
        } else if (screen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.3),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Spacer(),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    height: 1.3)),
          ],
        ),
      ),
    );
  }
}
