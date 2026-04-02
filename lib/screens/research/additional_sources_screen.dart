import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:url_launcher/url_launcher.dart';

class AdditionalSourcesScreen extends StatelessWidget {
  const AdditionalSourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSourceCard(
            context,
            title: 'WikiLeaks',
            description: 'Whistleblowing-Plattform mit geheimen Dokumenten',
            url: 'https://wikileaks.org',
            icon: Icons.shield_outlined,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          _buildSourceCard(
            context,
            title: 'Internet Archive',
            description: 'Digitale Bibliothek mit historischen Dokumenten',
            url: 'https://archive.org',
            icon: Icons.library_books,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildSourceCard(
            context,
            title: 'CIA FOIA Reading Room',
            description: 'Freigegebene CIA-Dokumente',
            url: 'https://www.cia.gov/readingroom/',
            icon: Icons.folder_open,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildSourceCard(
            context,
            title: 'FBI Vault',
            description: 'FBI Freedom of Information Act Dokumente',
            url: 'https://vault.fbi.gov',
            icon: Icons.account_balance,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          _buildSourceCard(
            context,
            title: 'National Security Archive',
            description: 'Declassified US Government Documents',
            url: 'https://nsarchive.gwu.edu',
            icon: Icons.security,
            color: Colors.purple,
          ),
          const SizedBox(height: 16),
          _buildSourceCard(
            context,
            title: 'The Black Vault',
            description: 'FOIA Dokumente & Government Secrets',
            url: 'https://www.theblackvault.com',
            icon: Icons.lock_open,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          _buildSourceCard(
            context,
            title: 'ProPublica',
            description: 'Investigativer Journalismus',
            url: 'https://www.propublica.org',
            icon: Icons.article,
            color: Colors.cyan,
          ),
          const SizedBox(height: 16),
          _buildSourceCard(
            context,
            title: 'ICIJ (Panama Papers)',
            description: 'International Consortium of Investigative Journalists',
            url: 'https://www.icij.org',
            icon: Icons.public,
            color: Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildSourceCard(
    BuildContext context, {
    required String title,
    required String description,
    required String url,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _launchUrl(url),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
