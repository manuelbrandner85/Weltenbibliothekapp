import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../theme/premium_text_styles.dart';
import '../../widgets/micro_interactions.dart';
import '../../widgets/sacred_geometry.dart';
import '../../widgets/profile_edit_dialogs.dart';
import '../../models/energie_profile.dart';
import '../../models/spirit_entry.dart';
import '../../core/storage/unified_storage_service.dart';
import '../../services/cloudflare_api_service.dart'; // 🌐 Cloudflare API
// Demo data removed - using real Cloudflare API
import '../../utils/time_helper.dart';
import '../../widgets/toast_helper.dart';

/// Home/Dashboard-Tab für ENERGIE-Welt
/// Zeigt: Spirituelles Profil, Energie-Level, Tagesimpuls, Chakra-Übersicht
class EnergieHomeTab extends StatefulWidget {
  const EnergieHomeTab({super.key});

  @override
  State<EnergieHomeTab> createState() => _EnergieHomeTabState();
}

class _EnergieHomeTabState extends State<EnergieHomeTab> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  EnergieProfile? _profile;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    _loadProfile();
  }

  void _loadProfile() {
    final profile = StorageService().getEnergieProfile();
    setState(() {
      _profile = profile; // Null wenn kein Profil vorhanden
    });
  }

  void _editProfile() {
    if (_profile == null) return;
    
    showDialog(
      context: context,
      builder: (context) => EnergieProfileEditDialog(
        profile: _profile!,
        onSave: (updatedProfile) {
          setState(() {
            _profile = updatedProfile;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF4A148C), // Dunkel-Lila
            Color(0xFF000000), // Schwarz
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Spiritueller Gruß
                _buildSpiritualGreeting(),
                const SizedBox(height: 24),

                // PROFIL-CARD (Anklickbar & Editierbar)
                _buildProfileCard(),
                const SizedBox(height: 24),

                // Tagesimpuls-Card
                _buildDailyImpulse(),
                const SizedBox(height: 24),

                // Energie-Level Anzeige
                _buildEnergyLevel(),
                const SizedBox(height: 24),

                // Chakra-Übersicht
                _buildChakraOverview(),
                const SizedBox(height: 24),

                // Spirit-Statistiken
                _buildSpiritStats(),
                const SizedBox(height: 24),

                // Kürzliche Einträge
                _buildRecentEntries(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpiritualGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Guten Morgen';
    } else if (hour < 18) {
      greeting = 'Namaste';
    } else {
      greeting = 'Gesegneten Abend';
    }

    final firstName = _profile?.firstName ?? 'Suchender';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: PremiumTextStyles.energieSubtitle.copyWith(
            fontSize: 14,
            color: const Color(0xFFCE93D8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          firstName,
          style: PremiumTextStyles.energieTitle.copyWith(
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF9C27B0),
                Color(0xFFFFD700),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9C27B0).withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 14),
              SizedBox(width: 8),
              Text(
                'Spirituelle Energie: Hoch',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return InkWell(
      onTap: _editProfile,
      borderRadius: BorderRadius.circular(16),
      child: HoverGlowCard(
        glowColor: const Color(0xFFFFD700),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF9C27B0).withValues(alpha: 0.3),
                const Color(0xFF1E1E1E),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF9C27B0).withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFFFFD700)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _profile?.firstName.isNotEmpty == true
                        ? _profile!.firstName[0].toUpperCase()
                        : 'M',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SPIRITUELLES PROFIL',
                      style: PremiumTextStyles.energieBadge.copyWith(
                        fontSize: 11,
                        color: const Color(0xFFCE93D8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_profile?.firstName ?? ''} ${_profile?.lastName ?? ''}',
                      style: PremiumTextStyles.energieCardTitle.copyWith(
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_profile?.birthDate != null)
                      Text(
                        'Geboren: ${_profile!.birthDate.day}.${_profile!.birthDate.month}.${_profile!.birthDate.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      'Tippen zum Bearbeiten',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.4),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Edit Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFFFFD700)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyImpulse() {
    const impulseText = 'Die Synchronizität ist heute besonders stark. Achte auf Zeichen und Symbole.';

    return HoverGlowCard(
      glowColor: const Color(0xFFFFD700),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF9C27B0).withValues(alpha: 0.3),
              const Color(0xFF4A148C).withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9C27B0), Color(0xFFFFD700)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'TAGESIMPULS',
                  style: PremiumTextStyles.energieBadge.copyWith(
                    letterSpacing: 2.0,
                    color: const Color(0xFFFFD700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              impulseText,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white,
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '🌙 ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnergyLevel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ENERGIE-LEVEL',
          style: PremiumTextStyles.energieBadge.copyWith(
            letterSpacing: 2.0,
            color: const Color(0xFFCE93D8),
          ),
        ),
        const SizedBox(height: 16),
        HoverGlowCard(
          glowColor: const Color(0xFF9C27B0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                // Kreisdiagramm mit Sacred Geometry
                SizedBox(
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Sacred Geometry Hintergrund
                      const SacredGeometryWidget(
                        type: 'flower',
                        size: 140,
                        primaryColor: Color(0xFF9C27B0),
                        secondaryColor: Color(0xFFFFD700),
                        animate: true,
                      ),
                      // Energie-Prozent
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '87%',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              foreground: Paint()
                                ..shader = const LinearGradient(
                                  colors: [
                                    Color(0xFF9C27B0),
                                    Color(0xFFFFD700),
                                  ],
                                ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                            ),
                          ),
                          const Text(
                            'Energie',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFCE93D8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Energie-Kategorien
                _buildEnergyCategory('Körperlich', 0.92, const Color(0xFFE91E63)),
                const SizedBox(height: 8),
                _buildEnergyCategory('Mental', 0.85, const Color(0xFF9C27B0)),
                const SizedBox(height: 8),
                _buildEnergyCategory('Emotional', 0.78, const Color(0xFF673AB7)),
                const SizedBox(height: 8),
                _buildEnergyCategory('Spirituell', 0.94, const Color(0xFFFFD700)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnergyCategory(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withValues(alpha: 0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChakraOverview() {
    final chakras = [
      {'name': 'Wurzel', 'color': const Color(0xFFE53935), 'level': 0.85},
      {'name': 'Sakral', 'color': const Color(0xFFFB8C00), 'level': 0.78},
      {'name': 'Solarplexus', 'color': const Color(0xFFFDD835), 'level': 0.92},
      {'name': 'Herz', 'color': const Color(0xFF43A047), 'level': 0.88},
      {'name': 'Hals', 'color': const Color(0xFF1E88E5), 'level': 0.75},
      {'name': 'Stirn', 'color': const Color(0xFF5E35B1), 'level': 0.90},
      {'name': 'Kronen', 'color': const Color(0xFF9C27B0), 'level': 0.95},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CHAKRA-ÜBERSICHT',
          style: PremiumTextStyles.energieBadge.copyWith(
            letterSpacing: 2.0,
            color: const Color(0xFFCE93D8),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: chakras.map((chakra) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    // Chakra-Symbol
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (chakra['color'] as Color).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (chakra['color'] as Color).withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (chakra['color'] as Color).withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: chakra['color'] as Color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name
                    SizedBox(
                      width: 90,
                      child: Text(
                        chakra['name'] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Balken
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          children: [
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: chakra['level'] as double,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: chakra['color'] as Color,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (chakra['color'] as Color).withValues(alpha: 0.6),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSpiritStats() {
    return Row(
      children: [
        Expanded(
          child: _buildSpiritStatCard(
            icon: Icons.book_outlined,
            label: 'Einträge',
            value: '23',
            color: const Color(0xFF9C27B0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSpiritStatCard(
            icon: Icons.auto_awesome,
            label: 'Synchronizität',
            value: '15',
            color: const Color(0xFFFFD700),
          ),
        ),
      ],
    );
  }

  Widget _buildSpiritStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return HoverGlowCard(
      glowColor: color,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEntries() {
    // 🌐 Cloudflare API: Hole ECHTE Energie-Artikel
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: CloudflareApiService().getArticles(realm: 'ENERGIE', limit: 3),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF9C27B0)));
        }
        
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'Noch keine Einträge vorhanden',
              style: TextStyle(color: Color(0xFF757575)),
            ),
          );
        }
        
        final entries = snapshot.data!;
        return _buildEntriesColumn(entries);
      },
    );
  }
  
  Widget _buildEntriesColumn(List<Map<String, dynamic>> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'KÜRZLICHE EINTRÄGE',
              style: PremiumTextStyles.energieBadge.copyWith(
                letterSpacing: 2.0,
                color: const Color(0xFFCE93D8),
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Alle Einträge werden geladen...'),
                    backgroundColor: const Color(0xFF9C27B0),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text(
                'Alle anzeigen',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9C27B0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildRecentEntryItem(entry),
        )),
      ],
    );
  }

  Widget _buildRecentEntryItem(Map<String, dynamic> entry) {
    // 🌐 Cloudflare API: Artikel-Daten (Map<String, dynamic>)
    final category = entry['category'] ?? 'Spirit';
    final icon = _getTypeIcon(category);
    final color = _getTypeColor(category);
    final title = entry['title'] ?? 'Unbenannt';
    final createdAt = entry['created_at'] != null 
        ? DateTime.parse(entry['created_at'])
        : DateTime.now();
    
    return InkWell(
      onTap: () {
        ToastHelper.showSuccess(context, '$title wird geöffnet...');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  TimeHelper.getRelativeTime(createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ],
      ),
    ),
    );
  }

  IconData _getTypeIcon(SpiritType type) {
    switch (type) {
      case SpiritType.journal:
        return Icons.book_outlined;
      case SpiritType.symbol:
        return Icons.category_outlined;
      case SpiritType.synchronicity:
        return Icons.auto_awesome;
      case SpiritType.mood:
        return Icons.mood;
      case SpiritType.archetype:
        return Icons.psychology_outlined;
      case SpiritType.dream:
        return Icons.bedtime_outlined;
    }
  }

  Color _getTypeColor(SpiritType type) {
    switch (type) {
      case SpiritType.journal:
        return const Color(0xFF9C27B0);
      case SpiritType.symbol:
        return const Color(0xFF673AB7);
      case SpiritType.synchronicity:
        return const Color(0xFFFFD700);
      case SpiritType.mood:
        return const Color(0xFFE91E63);
      case SpiritType.archetype:
        return const Color(0xFF7B1FA2);
      case SpiritType.dream:
        return const Color(0xFF5E35B1);
    }
  }
}
