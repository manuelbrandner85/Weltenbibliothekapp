import 'package:flutter/material.dart';

/// Widget zur Darstellung von Faktenbasis mit zwei Perspektiven
/// 
/// Zeigt strukturierte Analyse mit:
/// - Faktenbasis (oben, gemeinsam)
/// - Mainstream-Narrativ (links)
/// - Alternative Sicht (rechts)
class PerspektivenCard extends StatelessWidget {
  final Map<String, dynamic> analyseData;
  
  const PerspektivenCard({
    super.key,
    required this.analyseData,
  });

  @override
  Widget build(BuildContext context) {
    final structured = analyseData['structured'] as Map<String, dynamic>?;
    
    // Fallback falls structured fehlt
    if (structured == null) {
      return _buildTextFallback(context);
    }

    final faktenbasis = structured['faktenbasis'] as Map<String, dynamic>?;
    final sichtweise1 = structured['sichtweise1_offiziell'] as Map<String, dynamic>?;
    final sichtweise2 = structured['sichtweise2_alternativ'] as Map<String, dynamic>?;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: FAKTENBASIS
          _buildFaktenbasisHeader(),
          
          // Faktenbasis Content
          if (faktenbasis != null)
            _buildFaktenbasisContent(faktenbasis),
          
          const Divider(height: 32, thickness: 2),
          
          // Perspektiven-Vergleich (Side-by-Side)
          if (sichtweise1 != null && sichtweise2 != null)
            _buildPerspektivenVergleich(context, sichtweise1, sichtweise2),
        ],
      ),
    );
  }

  Widget _buildFaktenbasisHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.fact_check, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Text(
            'FAKTENBASIS',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaktenbasisContent(Map<String, dynamic> faktenbasis) {
    final facts = faktenbasis['facts'] as List<dynamic>? ?? [];
    final actors = faktenbasis['actors'] as List<dynamic>? ?? [];
    final organizations = faktenbasis['organizations'] as List<dynamic>? ?? [];
    final financialFlows = faktenbasis['financial_flows'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nachweisbare Fakten
          if (facts.isNotEmpty) ...[
            _buildSectionTitle('📄 Nachweisbare Fakten', Colors.blue.shade900),
            const SizedBox(height: 8),
            ...facts.map((fact) {
              final statement = fact['statement'] ?? '';
              final source = fact['source'] ?? 'unbekannt';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                          children: [
                            TextSpan(text: statement),
                            TextSpan(
                              text: ' (Quelle: $source)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          // Beteiligte Akteure
          if (actors.isNotEmpty) ...[
            _buildSectionTitle('👥 Beteiligte Akteure', Colors.purple.shade700),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actors.map((actor) {
                return Chip(
                  avatar: const Icon(Icons.person, size: 16),
                  label: Text(actor.toString()),
                  backgroundColor: Colors.purple.shade50,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Organisationen
          if (organizations.isNotEmpty) ...[
            _buildSectionTitle('🏢 Organisationen & Strukturen', Colors.orange.shade700),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: organizations.map((org) {
                return Chip(
                  avatar: const Icon(Icons.business, size: 16),
                  label: Text(org.toString()),
                  backgroundColor: Colors.orange.shade50,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Geldflüsse
          if (financialFlows.isNotEmpty) ...[
            _buildSectionTitle('💰 Geldflüsse & Finanzen', Colors.green.shade700),
            const SizedBox(height: 8),
            ...financialFlows.map((flow) {
              final description = flow['description'] ?? '';
              final source = flow['source'] ?? 'unbekannt';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.attach_money, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                          children: [
                            TextSpan(text: description),
                            TextSpan(
                              text: ' (Quelle: $source)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPerspektivenVergleich(
    BuildContext context,
    Map<String, dynamic> sichtweise1,
    Map<String, dynamic> sichtweise2,
  ) {
    // Responsive Layout: Side-by-Side auf breiten Screens, vertikal auf schmalen
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    if (isWide) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildPerspektiveCard(
                title: 'MAINSTREAM-NARRATIV',
                icon: Icons.account_balance,
                color: Colors.blue.shade600,
                interpretation: sichtweise1['interpretation'] ?? '',
                sources: List<String>.from(sichtweise1['sources'] ?? []),
              ),
            ),
            const VerticalDivider(width: 2, thickness: 2),
            Expanded(
              child: _buildPerspektiveCard(
                title: 'ALTERNATIVE SICHT',
                icon: Icons.search,
                color: Colors.orange.shade700,
                interpretation: sichtweise2['interpretation'] ?? '',
                sources: List<String>.from(sichtweise2['sources'] ?? []),
              ),
            ),
          ],
        ),
      );
    } else {
      return Column(
        children: [
          _buildPerspektiveCard(
            title: 'MAINSTREAM-NARRATIV',
            icon: Icons.account_balance,
            color: Colors.blue.shade600,
            interpretation: sichtweise1['interpretation'] ?? '',
            sources: List<String>.from(sichtweise1['sources'] ?? []),
          ),
          const Divider(height: 2, thickness: 2),
          _buildPerspektiveCard(
            title: 'ALTERNATIVE SICHT',
            icon: Icons.search,
            color: Colors.orange.shade700,
            interpretation: sichtweise2['interpretation'] ?? '',
            sources: List<String>.from(sichtweise2['sources'] ?? []),
          ),
        ],
      );
    }
  }

  Widget _buildPerspektiveCard({
    required String title,
    required IconData icon,
    required Color color,
    required String interpretation,
    required List<String> sources,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Interpretation
          if (interpretation.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                interpretation,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Quellen
          if (sources.isNotEmpty) ...[
            Text(
              '📚 Quellen für diese Sichtweise:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            ...sources.map((source) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.source, size: 16, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        source,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  /// Fallback: Zeigt Original-Text wenn structured fehlt
  Widget _buildTextFallback(BuildContext context) {
    final inhalt = analyseData['inhalt'] as String? ?? 'Keine Analyse verfügbar';
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Vollständige Analyse',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              inhalt,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
