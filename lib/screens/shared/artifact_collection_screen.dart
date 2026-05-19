import 'package:flutter/material.dart';

import '../../config/wb_design.dart';
import '../../services/gamification_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🏺 ARTIFACT COLLECTION SCREEN — Octalysis Gamification
// Zeigt alle Artefakte (Katalog + besessene) mit Rarity-Filtern.
// ═══════════════════════════════════════════════════════════════════════════

class ArtifactCollectionScreen extends StatefulWidget {
  final String? filterWorld; // null = alle Welten

  const ArtifactCollectionScreen({super.key, this.filterWorld});

  @override
  State<ArtifactCollectionScreen> createState() =>
      _ArtifactCollectionScreenState();
}

class _ArtifactCollectionScreenState extends State<ArtifactCollectionScreen>
    with SingleTickerProviderStateMixin {
  final _gs = GamificationService();
  late TabController _tabCtrl;

  List<Artifact> _catalog = [];
  List<UserArtifact> _owned = [];
  bool _loading = true;
  String _selectedRarity = 'all';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      _catalog = await _gs.getArtifactCatalog();
      _owned = await _gs.getUserArtifacts();
    } catch (e) {
      debugPrint('⚠️ ArtifactCollectionScreen._loadData: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Color get _accent {
    switch (widget.filterWorld) {
      case 'energie':
        return WbDesign.energiePurple;
      case 'noir':
        return WbDesign.vorhangGold;
      case 'genesis':
        return WbDesign.ursprungCyan;
      default:
        return WbDesign.materieBlue;
    }
  }

  Color get _bg {
    switch (widget.filterWorld) {
      case 'energie':
        return WbDesign.bgEnergie;
      case 'noir':
        return WbDesign.bgVorhang;
      case 'genesis':
        return WbDesign.bgUrsprung;
      default:
        return WbDesign.bgMaterie;
    }
  }

  List<Artifact> get _filteredCatalog {
    var list = _catalog.toList();
    if (widget.filterWorld != null) {
      list = list
          .where((a) => a.world == widget.filterWorld || a.world == 'universal')
          .toList();
    }
    if (_selectedRarity != 'all') {
      list = list.where((a) => a.rarity.name == _selectedRarity).toList();
    }
    // Sortierung: legendary > epic > rare > common
    list.sort((a, b) => b.rarity.index.compareTo(a.rarity.index));
    return list;
  }

  Set<String> get _ownedArtifactIds =>
      {for (final ua in _owned) ua.artifact.id};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Artefakt-Sammlung',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: _accent,
          labelColor: _accent,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.collections_bookmark, size: 16),
                  const SizedBox(width: 6),
                  const Text('Katalog'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inventory_2, size: 16),
                  const SizedBox(width: 6),
                  Text('Meine (${_owned.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: _accent),
            )
          : Column(
              children: [
                // Rarity Filter Chips
                _buildRarityFilter(),
                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildCatalogGrid(),
                      _buildOwnedGrid(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRarityFilter() {
    final rarities = [
      ('all', 'Alle', 0xFFFFFFFF),
      (
        'common',
        'Gewöhnlich',
        GamificationService.rarityColor(ArtifactRarity.common)
      ),
      ('rare', 'Selten', GamificationService.rarityColor(ArtifactRarity.rare)),
      ('epic', 'Episch', GamificationService.rarityColor(ArtifactRarity.epic)),
      (
        'legendary',
        'Legendär',
        GamificationService.rarityColor(ArtifactRarity.legendary)
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: rarities.map((r) {
          final isSelected = _selectedRarity == r.$1;
          final color = Color(r.$3);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(
                r.$2,
                style: TextStyle(
                  color:
                      isSelected ? Colors.black : color.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              backgroundColor: color.withValues(alpha: 0.08),
              selectedColor: color.withValues(alpha: 0.7),
              side: BorderSide(
                color: isSelected
                    ? color.withValues(alpha: 0.8)
                    : color.withValues(alpha: 0.2),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (_) => setState(() => _selectedRarity = r.$1),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCatalogGrid() {
    final items = _filteredCatalog;
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Keine Artefakte gefunden',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final artifact = items[i];
        final isOwned = _ownedArtifactIds.contains(artifact.id);
        return _buildArtifactCard(artifact, isOwned: isOwned);
      },
    );
  }

  Widget _buildOwnedGrid() {
    var ownedFiltered = _owned.toList();
    if (widget.filterWorld != null) {
      ownedFiltered = ownedFiltered
          .where((ua) =>
              ua.artifact.world == widget.filterWorld ||
              ua.artifact.world == 'universal')
          .toList();
    }
    if (_selectedRarity != 'all') {
      ownedFiltered = ownedFiltered
          .where((ua) => ua.artifact.rarity.name == _selectedRarity)
          .toList();
    }

    if (ownedFiltered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                color: Colors.white.withValues(alpha: 0.2), size: 48),
            const SizedBox(height: 12),
            Text(
              'Noch keine Artefakte gesammelt',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 4),
            Text(
              'Erkunde die Bibliothek, um Artefakte zu finden!',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: ownedFiltered.length,
      itemBuilder: (ctx, i) {
        final ua = ownedFiltered[i];
        return _buildArtifactCard(ua.artifact,
            isOwned: true, isEquipped: ua.isEquipped, userArtifactId: ua.id);
      },
    );
  }

  Widget _buildArtifactCard(
    Artifact artifact, {
    required bool isOwned,
    bool isEquipped = false,
    String? userArtifactId,
  }) {
    final rarityCol = Color(GamificationService.rarityColor(artifact.rarity));
    final rarityLabel = GamificationService.rarityLabel(artifact.rarity);

    return GestureDetector(
      onTap: () => _showArtifactDetail(artifact,
          isOwned: isOwned,
          isEquipped: isEquipped,
          userArtifactId: userArtifactId),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              rarityCol.withValues(alpha: isOwned ? 0.15 : 0.06),
              Colors.black.withValues(alpha: 0.3),
            ],
          ),
          border: Border.all(
            color: isEquipped
                ? rarityCol.withValues(alpha: 0.8)
                : rarityCol.withValues(alpha: isOwned ? 0.4 : 0.15),
            width: isEquipped ? 2 : 1,
          ),
          boxShadow: isEquipped
              ? [
                  BoxShadow(
                    color: rarityCol.withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Emoji Icon
                  Text(
                    artifact.iconEmoji,
                    style: TextStyle(
                      fontSize: 36,
                      color:
                          isOwned ? null : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Name
                  Text(
                    artifact.nameDe,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isOwned
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Rarity Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: rarityCol.withValues(alpha: 0.2),
                    ),
                    child: Text(
                      rarityLabel,
                      style: TextStyle(
                        color: rarityCol,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // XP Bonus
                  if (artifact.xpBonus > 0)
                    Text(
                      '+${artifact.xpBonus} XP',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  // World Tag
                  const SizedBox(height: 4),
                  Text(
                    _worldEmoji(artifact.world),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            // Owned Badge
            if (isOwned)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withValues(alpha: 0.2),
                    border:
                        Border.all(color: Colors.green.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.check, color: Colors.green, size: 12),
                ),
              ),
            // Equipped Badge
            if (isEquipped)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: rarityCol.withValues(alpha: 0.3),
                    border: Border.all(color: rarityCol.withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    'Ausgerüstet',
                    style: TextStyle(
                      color: rarityCol,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            // Locked Overlay
            if (!isOwned)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                  child: Center(
                    child: Icon(Icons.lock_outline,
                        color: Colors.white.withValues(alpha: 0.2), size: 28),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _worldEmoji(String world) {
    switch (world) {
      case 'materie':
        return '🔬';
      case 'energie':
        return '💜';
      case 'noir':
        return '🎭';
      case 'genesis':
        return '🌱';
      case 'universal':
        return '🌍';
      default:
        return '📦';
    }
  }

  void _showArtifactDetail(
    Artifact artifact, {
    required bool isOwned,
    bool isEquipped = false,
    String? userArtifactId,
  }) {
    final rarityCol = Color(GamificationService.rarityColor(artifact.rarity));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: rarityCol.withValues(alpha: 0.4), width: 2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Icon
            Text(artifact.iconEmoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            // Name
            Text(
              artifact.nameDe,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            // Rarity
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: rarityCol.withValues(alpha: 0.2),
                border: Border.all(color: rarityCol.withValues(alpha: 0.5)),
              ),
              child: Text(
                GamificationService.rarityLabel(artifact.rarity),
                style: TextStyle(
                  color: rarityCol,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Description
            Text(
              artifact.descriptionDe,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (artifact.xpBonus > 0)
                  _statChip(
                      '⚡ +${artifact.xpBonus} XP', const Color(0xFFFFD54F)),
                if (artifact.xpBonus > 0) const SizedBox(width: 8),
                _statChip(
                  '${_worldEmoji(artifact.world)} ${_worldLabel(artifact.world)}',
                  _accent,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Actions
            if (isOwned && userArtifactId != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEquipped
                        ? Colors.white.withValues(alpha: 0.1)
                        : rarityCol.withValues(alpha: 0.3),
                    foregroundColor: isEquipped ? Colors.white70 : rarityCol,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(
                      isEquipped ? Icons.remove_circle_outline : Icons.shield),
                  label: Text(isEquipped ? 'Ablegen' : 'Ausrüsten'),
                  onPressed: () async {
                    await _gs.toggleEquipArtifact(userArtifactId);
                    await _loadData();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ),
            if (!isOwned)
              Text(
                '🔒 Noch nicht entdeckt',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _worldLabel(String world) {
    switch (world) {
      case 'energie':
        return 'Energie';
      case 'noir':
        return 'Noir';
      case 'genesis':
        return 'Genesis';
      case 'universal':
        return 'Universal';
      default:
        return 'Materie';
    }
  }
}
