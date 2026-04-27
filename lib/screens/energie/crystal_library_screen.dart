import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'dart:convert';
import '../../services/group_tools_service.dart';
import '../../services/user_service.dart';

/// 💠 Kristall-Bibliothek Screen
/// Gemeinsame Kristall-Sammlung & Erfahrungen
class CrystalLibraryScreen extends StatefulWidget {
  final String roomId;
  
  const CrystalLibraryScreen({
    super.key,
    this.roomId = 'kristalle',
  });

  @override
  State<CrystalLibraryScreen> createState() => _CrystalLibraryScreenState();
}

class _CrystalLibraryScreenState extends State<CrystalLibraryScreen>
    with SingleTickerProviderStateMixin {
  final GroupToolsService _toolsService = GroupToolsService();
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _mineralSearchCtrl = TextEditingController();

  late final TabController _tabCtrl;

  List<Map<String, dynamic>> _crystals = [];
  bool _isLoading = false;
  String _username = '';
  String _userId = '';
  String? _errorMessage;

  // Mineralien-Tab
  List<_MineralEntry> _filteredMinerals = List.from(_kMinerals);

  // Filter
  String _sortBy = 'likes';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadUserData();
    _loadCrystals();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchController.dispose();
    _mineralSearchCtrl.dispose();
    super.dispose();
  }

  void _filterMinerals(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filteredMinerals = q.isEmpty
          ? List.from(_kMinerals)
          : _kMinerals
              .where((m) =>
                  m.name.toLowerCase().contains(q) ||
                  m.nameEn.toLowerCase().contains(q) ||
                  m.formula.toLowerCase().contains(q) ||
                  m.colors.any((c) => c.toLowerCase().contains(q)))
              .toList();
    });
  }
  
  Future<void> _loadUserData() async {
    final user = await _userService.getCurrentUser();
    setState(() {
      _username = user.username;
      _userId = 'user_${user.username.toLowerCase()}';
    });
  }
  
  Future<void> _loadCrystals({String? search}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final crystals = await _toolsService.getCrystals(
        roomId: widget.roomId,
        search: search,
        limit: 100,
      );
      
      if (kDebugMode) {
        debugPrint('💠 Loaded ${crystals.length} crystals');
      }
      
      // Sort
      crystals.sort((a, b) {
        if (_sortBy == 'likes') {
          return (b['likes'] ?? 0).compareTo(a['likes'] ?? 0);
        } else if (_sortBy == 'recent') {
          return (b['created_at'] ?? '').compareTo(a['created_at'] ?? '');
        } else {
          return (a['crystal_name'] ?? '').compareTo(b['crystal_name'] ?? '');
        }
      });
      
      setState(() {
        _crystals = crystals;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading crystals: $e');
      }
      setState(() {
        _errorMessage = 'Fehler beim Laden: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _showAddCrystalDialog() async {
    if (_username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Bitte erstelle erst ein Profil im Energie- oder Materie-Tab'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddCrystalDialog(
        username: _username,
        userId: _userId,
        roomId: widget.roomId,
      ),
    );
    
    if (result != null && result['success'] == true) {
      _loadCrystals(); // Reload
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['crystal_name']} hinzugefügt!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
  
  void _showCrystalDetails(Map<String, dynamic> crystal) {
    showDialog(
      context: context,
      builder: (context) => _CrystalDetailsDialog(crystal: crystal),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('💠 Kristall-Bibliothek'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white70),
            onSelected: (value) {
              setState(() => _sortBy = value);
              _loadCrystals();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'likes', child: Text('🔥 Beliebteste')),
              const PopupMenuItem(value: 'recent', child: Text('🕐 Neueste')),
              const PopupMenuItem(value: 'name', child: Text('🔤 Name')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadCrystals(),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.purple,
          labelColor: Colors.purple,
          unselectedLabelColor: Colors.white54,
          tabs: [
            Tab(text: 'Community (${_crystals.length})'),
            Tab(text: '🌍 Mineralien (${_kMinerals.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildCommunityTab(),
          _buildMineralienTab(),
        ],
      ),
      floatingActionButton: _tabCtrl.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddCrystalDialog,
              backgroundColor: const Color(0xFF9C27B0),
              icon: const Icon(Icons.add),
              label: const Text('Kristall hinzufügen'),
            )
          : null,
    );
  }

  // ── Community-Tab (bisherige Inhalte) ────────────────────────────────────
  Widget _buildCommunityTab() {
    return Column(
      children: [
        // Search Bar
        Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4A148C).withValues(alpha: 0.2),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Kristall suchen...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                prefixIcon: const Icon(Icons.search, color: Colors.purple),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          _loadCrystals();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) => _loadCrystals(search: value),
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadCrystals(),
                              child: const Text('Erneut versuchen'),
                            ),
                          ],
                        ),
                      )
                    : _crystals.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.diamond, size: 64, color: Colors.purple),
                                const SizedBox(height: 16),
                                const Text(
                                  'Noch keine Kristalle',
                                  style: TextStyle(color: Colors.white70, fontSize: 18),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Sei der Erste und füge einen Kristall hinzu!',
                                  style: TextStyle(color: Colors.white38),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _crystals.length,
                            itemBuilder: (context, index) {
                              final crystal = _crystals[index];
                              return _buildCrystalCard(crystal);
                            },
                          ),
          ),
        ],
      );
  }

  // ── Mineralien-Tab ────────────────────────────────────────────────────────
  Widget _buildMineralienTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: const Color(0xFF0A0A0F),
          child: TextField(
            controller: _mineralSearchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Mineral suchen (Name, Formel, Farbe)…',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              prefixIcon: const Icon(Icons.search, color: Colors.purple),
              suffixIcon: _mineralSearchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white38),
                      onPressed: () {
                        _mineralSearchCtrl.clear();
                        _filterMinerals('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF1A1A2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: _filterMinerals,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: const Color(0xFF0A0A0F),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: Colors.white38),
              const SizedBox(width: 6),
              Text(
                '${_filteredMinerals.length} Mineralien · Quellen: Mindat, IMA, mineralienatlas.de',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _filteredMinerals.length,
            itemBuilder: (ctx, i) => _buildMineralCard(_filteredMinerals[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildMineralCard(_MineralEntry m) {
    return Card(
      color: const Color(0xFF1A1A2E),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: m.displayColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: m.displayColor.withValues(alpha: 0.5)),
          ),
          child: Center(child: Text(m.emoji, style: const TextStyle(fontSize: 20))),
        ),
        title: Text(m.name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text('${m.nameEn} · ${m.formula}',
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('Härte ${m.hardness}',
              style: const TextStyle(color: Colors.purple, fontSize: 11)),
        ),
        iconColor: Colors.purple,
        collapsedIconColor: Colors.white38,
        children: [
          // Farben
          _mineralRow('🎨', 'Farben', m.colors.join(', ')),
          _mineralRow('🔷', 'Kristallsystem', m.crystalSystem),
          _mineralRow('📍', 'Fundorte', m.origins.join(', ')),
          _mineralRow('💡', 'Wirkung (spirituell)', m.spiritualEffect),
          if (m.chakra != null) _mineralRow('🌈', 'Chakra', m.chakra!),
          if (m.element != null) _mineralRow('🌿', 'Element', m.element!),
          const SizedBox(height: 6),
          // Tags
          Wrap(
            spacing: 6, runSpacing: 6,
            children: m.tags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: m.displayColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: m.displayColor.withValues(alpha: 0.3)),
              ),
              child: Text(tag,
                  style: TextStyle(color: m.displayColor, fontSize: 11)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _mineralRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildCrystalCard(Map<String, dynamic> crystal) {
    final name = crystal['crystal_name'] ?? 'Unbekannt';
    final type = crystal['crystal_type'] ?? '';
    final uses = crystal['uses'] ?? '';
    final likes = crystal['likes'] ?? 0;
    final username = crystal['username'] ?? 'Anonym';
    
    // Parse properties JSON
    List<String> properties = [];
    try {
      final propsJson = crystal['properties'];
      if (propsJson is String) {
        final decoded = List<String>.from(
          (propsJson.isNotEmpty ? (propsJson.startsWith('[') 
            ? (jsonDecode(propsJson) as List) 
            : [propsJson]) 
          : [])
        );
        properties = decoded;
      } else if (propsJson is List) {
        properties = List<String>.from(propsJson);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error parsing properties: $e');
      }
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showCrystalDetails(crystal),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Kristall-Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                      ),
                    ),
                    child: const Icon(Icons.diamond, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  // Name & Type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (type.isNotEmpty)
                          Text(
                            type,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Likes
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite, size: 16, color: Colors.purple),
                        const SizedBox(width: 4),
                        Text(
                          likes.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Properties
              if (properties.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: properties.take(5).map((prop) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        prop,
                        style: const TextStyle(color: Colors.purple, fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),
              ],
              
              // Uses
              if (uses.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  uses,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              // Footer
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(
                    username,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showCrystalDetails(crystal),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Details'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mineralien-Datenmodell & Dataset ─────────────────────────────────────────

class _MineralEntry {
  final String name;
  final String nameEn;
  final String formula;
  final String hardness;
  final List<String> colors;
  final String crystalSystem;
  final List<String> origins;
  final String spiritualEffect;
  final String? chakra;
  final String? element;
  final List<String> tags;
  final String emoji;
  final Color displayColor;

  const _MineralEntry({
    required this.name,
    required this.nameEn,
    required this.formula,
    required this.hardness,
    required this.colors,
    required this.crystalSystem,
    required this.origins,
    required this.spiritualEffect,
    this.chakra,
    this.element,
    required this.tags,
    required this.emoji,
    required this.displayColor,
  });
}

const List<_MineralEntry> _kMinerals = [
  _MineralEntry(
    name: 'Amethyst', nameEn: 'Amethyst', formula: 'SiO₂',
    hardness: '7', colors: ['Violett', 'Lila', 'Dunkelviolett'],
    crystalSystem: 'Trigonal',
    origins: ['Brasilien', 'Uruguay', 'Sambia', 'Madagaskar'],
    spiritualEffect: 'Beruhigt Geist und Emotionen, fördert Intuition und spirituelles Bewusstsein.',
    chakra: 'Stirn- & Kronenchakra', element: 'Wind',
    tags: ['Beruhigend', 'Intuition', 'Schlaf', 'Meditation'],
    emoji: '💜', displayColor: Color(0xFF9C27B0),
  ),
  _MineralEntry(
    name: 'Rosenquarz', nameEn: 'Rose Quartz', formula: 'SiO₂',
    hardness: '7', colors: ['Rosa', 'Hellrosa', 'Blasslila'],
    crystalSystem: 'Trigonal',
    origins: ['Brasilien', 'Madagaskar', 'USA', 'Indien'],
    spiritualEffect: 'Stein der bedingungslosen Liebe. Öffnet das Herzchakra, fördert Selbstliebe und Mitgefühl.',
    chakra: 'Herzchakra', element: 'Wasser',
    tags: ['Liebe', 'Selbstliebe', 'Herzchakra', 'Mitgefühl'],
    emoji: '🌸', displayColor: Color(0xFFE91E8C),
  ),
  _MineralEntry(
    name: 'Bergkristall', nameEn: 'Clear Quartz', formula: 'SiO₂',
    hardness: '7', colors: ['Klar', 'Weiß', 'Transparent'],
    crystalSystem: 'Trigonal',
    origins: ['Weltweit', 'Brasilien', 'Schweiz', 'USA'],
    spiritualEffect: 'Universalverstärker. Klärt Gedanken, verstärkt Intentionen und andere Steine.',
    chakra: 'Alle Chakren', element: 'Sturm',
    tags: ['Verstärker', 'Klarheit', 'Energie', 'Programmierbar'],
    emoji: '🔮', displayColor: Color(0xFFE0E0E0),
  ),
  _MineralEntry(
    name: 'Citrin', nameEn: 'Citrine', formula: 'SiO₂',
    hardness: '7', colors: ['Gelb', 'Orange', 'Goldgelb'],
    crystalSystem: 'Trigonal',
    origins: ['Brasilien', 'Madagaskar', 'Spanien', 'Russland'],
    spiritualEffect: 'Stein der Fülle und Freude. Aktiviert Solarplexus, fördert Selbstvertrauen und Kreativität.',
    chakra: 'Solarplexus-Chakra', element: 'Feuer',
    tags: ['Fülle', 'Freude', 'Kreativität', 'Energie', 'Manifestation'],
    emoji: '🌟', displayColor: Color(0xFFFFC107),
  ),
  _MineralEntry(
    name: 'Labradorit', nameEn: 'Labradorite', formula: 'CaAl₂Si₂O₈–NaAlSi₃O₈',
    hardness: '6–6.5', colors: ['Grau', 'Blau', 'Grün', 'Gold (Labradoreszenz)'],
    crystalSystem: 'Triklin',
    origins: ['Kanada', 'Finnland', 'Madagaskar', 'Russland'],
    spiritualEffect: 'Stein der Transformation. Schützt die Aura, weckt mystische Fähigkeiten und Intuition.',
    chakra: 'Drittes Auge', element: 'Wind',
    tags: ['Transformation', 'Schutz', 'Magie', 'Intuition'],
    emoji: '🌊', displayColor: Color(0xFF1976D2),
  ),
  _MineralEntry(
    name: 'Obsidian', nameEn: 'Obsidian', formula: 'SiO₂ (vulkanisches Glas)',
    hardness: '5–5.5', colors: ['Schwarz', 'Schwarz-Gold (Goldscheen)', 'Regenbogen'],
    crystalSystem: 'Amorph',
    origins: ['Mexiko', 'USA', 'Äthiopien', 'Island'],
    spiritualEffect: 'Wahrheitsspiegel. Tief reinigend, schützt vor negativer Energie, verwurzelt.',
    chakra: 'Wurzelchakra', element: 'Erde',
    tags: ['Schutz', 'Erdung', 'Reinigung', 'Wahrheit'],
    emoji: '🖤', displayColor: Color(0xFF212121),
  ),
  _MineralEntry(
    name: 'Malachit', nameEn: 'Malachite', formula: 'Cu₂(CO₃)(OH)₂',
    hardness: '3.5–4', colors: ['Grün', 'Dunkelgrün', 'Hellgrün (Bänderung)'],
    crystalSystem: 'Monoklin',
    origins: ['Kongo', 'Russland', 'Australien', 'Namibia'],
    spiritualEffect: 'Stein der Transformation und des Schutzes. Zieht Emotionen an die Oberfläche.',
    chakra: 'Herzchakra', element: 'Erde',
    tags: ['Transformation', 'Herzchakra', 'Heilung', 'Schutz'],
    emoji: '🌿', displayColor: Color(0xFF388E3C),
  ),
  _MineralEntry(
    name: 'Lapis Lazuli', nameEn: 'Lapis Lazuli', formula: 'Lazurit + Calcit + Pyrit',
    hardness: '5–6', colors: ['Dunkelblau', 'Mittelblau', 'Blau mit Goldflecken'],
    crystalSystem: 'Isometrisch',
    origins: ['Afghanistan', 'Chile', 'Russland', 'Pakistan'],
    spiritualEffect: 'Königsstein der Weisheit. Aktiviert drittes Auge, fördert intellektuelle Klarheit.',
    chakra: 'Kehlchakra & Drittes Auge', element: 'Wind & Wasser',
    tags: ['Weisheit', 'Wahrheit', 'Kommunikation', 'Intuition'],
    emoji: '🔵', displayColor: Color(0xFF1565C0),
  ),
  _MineralEntry(
    name: 'Türkis', nameEn: 'Turquoise', formula: 'CuAl₆(PO₄)₄(OH)₈·4H₂O',
    hardness: '5–6', colors: ['Türkis', 'Blaugrün', 'Hellblau'],
    crystalSystem: 'Triklin',
    origins: ['Iran', 'USA', 'China', 'Mexiko'],
    spiritualEffect: 'Stein der Weisheit und des Schutzes. Brücke zwischen Himmel und Erde.',
    chakra: 'Kehlchakra', element: 'Sturm',
    tags: ['Schutz', 'Kommunikation', 'Heilung', 'Reisen'],
    emoji: '🩵', displayColor: Color(0xFF00BCD4),
  ),
  _MineralEntry(
    name: 'Hämatit', nameEn: 'Hematite', formula: 'Fe₂O₃',
    hardness: '5–6', colors: ['Silbergrau', 'Schwarz', 'Rotbraun'],
    crystalSystem: 'Trigonal',
    origins: ['Brasilien', 'England', 'Australien', 'Deutschland'],
    spiritualEffect: 'Stärkster Erdungsstein. Verankert im Hier und Jetzt, stärkt Willenskraft.',
    chakra: 'Wurzelchakra', element: 'Erde',
    tags: ['Erdung', 'Schutz', 'Fokus', 'Stärke'],
    emoji: '⚫', displayColor: Color(0xFF546E7A),
  ),
  _MineralEntry(
    name: 'Fluorit', nameEn: 'Fluorite', formula: 'CaF₂',
    hardness: '4', colors: ['Lila', 'Grün', 'Blau', 'Gelb', 'Mehrfarbig'],
    crystalSystem: 'Isometrisch',
    origins: ['China', 'Mexiko', 'England', 'Deutschland'],
    spiritualEffect: 'Geniusstein. Strukturiert das Denken, schützt vor elektromagnetischen Feldern.',
    chakra: 'Stirnchakra', element: 'Wind',
    tags: ['Konzentration', 'Klarheit', 'Lernstein', 'EMF-Schutz'],
    emoji: '🟣', displayColor: Color(0xFF7E57C2),
  ),
  _MineralEntry(
    name: 'Tigerauge', nameEn: "Tiger's Eye", formula: 'SiO₂ (Chatoyant)',
    hardness: '7', colors: ['Goldbraun', 'Braun', 'Rot'],
    crystalSystem: 'Trigonal',
    origins: ['Südafrika', 'Australien', 'USA', 'Indien'],
    spiritualEffect: 'Stein des Mutes und der Stärke. Fördert Willenskraft und klares Urteilsvermögen.',
    chakra: 'Solarplexus-Chakra', element: 'Feuer & Erde',
    tags: ['Mut', 'Stärke', 'Fokus', 'Selbstvertrauen'],
    emoji: '🐯', displayColor: Color(0xFFFF8F00),
  ),
  _MineralEntry(
    name: 'Selenit', nameEn: 'Selenite', formula: 'CaSO₄·2H₂O',
    hardness: '2', colors: ['Weiß', 'Perlweiß', 'Transparent'],
    crystalSystem: 'Monoklin',
    origins: ['Mexiko', 'USA', 'Marokko', 'Australien'],
    spiritualEffect: 'Mondstein des Lichts. Reinigt andere Steine, öffnet Kronenchakra, verbindet mit höheren Welten.',
    chakra: 'Kronenchakra', element: 'Wind',
    tags: ['Reinigung', 'Engel', 'Frieden', 'Bewusstsein'],
    emoji: '🤍', displayColor: Color(0xFFF5F5F5),
  ),
  _MineralEntry(
    name: 'Karneol', nameEn: 'Carnelian', formula: 'SiO₂ (Chalzedon)',
    hardness: '7', colors: ['Orange', 'Rot', 'Rotorange'],
    crystalSystem: 'Trigonal',
    origins: ['Indien', 'Brasilien', 'Uruguay', 'Ägypten'],
    spiritualEffect: 'Stein der Vitalität und Kreativität. Stärkt Lebensenergie und Motivation.',
    chakra: 'Sakral-Chakra', element: 'Feuer',
    tags: ['Vitalität', 'Kreativität', 'Motivation', 'Sexualität'],
    emoji: '🔶', displayColor: Color(0xFFE64A19),
  ),
  _MineralEntry(
    name: 'Mondstein', nameEn: 'Moonstone', formula: 'KAlSi₃O₈',
    hardness: '6–6.5', colors: ['Weiß', 'Cremeweiß', 'Blauer Schimmer'],
    crystalSystem: 'Monoklin',
    origins: ['Sri Lanka', 'Indien', 'Australien', 'Madagaskar'],
    spiritualEffect: 'Stein der inneren Göttin. Stärkt Intuition, Empfindsamkeit und weibliche Energie.',
    chakra: 'Sakral- & Kronenchakra', element: 'Wasser',
    tags: ['Intuition', 'Weiblichkeit', 'Mondenergie', 'Träume'],
    emoji: '🌙', displayColor: Color(0xFFB0BEC5),
  ),
  _MineralEntry(
    name: 'Rhodonit', nameEn: 'Rhodonite', formula: 'MnSiO₃',
    hardness: '5.5–6.5', colors: ['Rosa', 'Rot', 'Rosa mit schwarzen Adern'],
    crystalSystem: 'Triklin',
    origins: ['Russland', 'Australien', 'Schweden', 'Brasilien'],
    spiritualEffect: 'Stein der Wunden-Heilung. Löst emotionale Verletzungen, fördert Vergebung.',
    chakra: 'Herzchakra', element: 'Erde',
    tags: ['Heilung', 'Vergebung', 'Liebe', 'Emotionen'],
    emoji: '🌺', displayColor: Color(0xFFE91E63),
  ),
  _MineralEntry(
    name: 'Aventurin', nameEn: 'Aventurine', formula: 'SiO₂ (Quarz)',
    hardness: '7', colors: ['Grün', 'Blau', 'Orange', 'Gelb'],
    crystalSystem: 'Trigonal',
    origins: ['Indien', 'Brasilien', 'Russland', 'Tansania'],
    spiritualEffect: 'Glücksstein par excellence. Stärkt Optimismus, öffnet Herzchakra, zieht Fülle an.',
    chakra: 'Herzchakra', element: 'Erde',
    tags: ['Glück', 'Optimismus', 'Fülle', 'Herzchakra'],
    emoji: '🍀', displayColor: Color(0xFF43A047),
  ),
  _MineralEntry(
    name: 'Amazonit', nameEn: 'Amazonite', formula: 'KAlSi₃O₈',
    hardness: '6–6.5', colors: ['Türkisgrün', 'Blaugrün', 'Grünblau'],
    crystalSystem: 'Triklin',
    origins: ['Brasilien', 'USA', 'Russland', 'Äthiopien'],
    spiritualEffect: 'Stein der Wahrheit und Kommunikation. Beruhigt Nerven, fördert Ausgewogenheit.',
    chakra: 'Herzchakra & Kehlchakra', element: 'Wasser',
    tags: ['Kommunikation', 'Wahrheit', 'Balance', 'Beruhigung'],
    emoji: '🏞️', displayColor: Color(0xFF00897B),
  ),
  _MineralEntry(
    name: 'Azurit', nameEn: 'Azurite', formula: 'Cu₃(CO₃)₂(OH)₂',
    hardness: '3.5–4', colors: ['Tiefblau', 'Azurblau', 'Dunkelblau'],
    crystalSystem: 'Monoklin',
    origins: ['Marokko', 'USA', 'Chile', 'Australien'],
    spiritualEffect: 'Stein des dritten Auges. Stimuliert Hellsehen und psychische Fähigkeiten.',
    chakra: 'Drittes Auge', element: 'Wind',
    tags: ['Hellsehen', 'Drittes Auge', 'Intuition', 'Meditation'],
    emoji: '🔷', displayColor: Color(0xFF1976D2),
  ),
  _MineralEntry(
    name: 'Moldavit', nameEn: 'Moldavite', formula: 'SiO₂ (Tektit)',
    hardness: '5.5', colors: ['Flaschengrün', 'Olivgrün', 'Transparent-Grün'],
    crystalSystem: 'Amorph',
    origins: ['Tschechien', 'Deutschland', 'Österreich'],
    spiritualEffect: 'Stein des Kosmos. Extraterrestrischer Ursprung (Meteorit-Impact). Starke Transformation und spirituelles Erwachen.',
    chakra: 'Herzchakra & Kronenchakra', element: 'Sturm',
    tags: ['Transformation', 'Extraterrestrisch', 'Erwachen', 'Kosmisch'],
    emoji: '☄️', displayColor: Color(0xFF558B2F),
  ),
];

// ========================================
// 💠 ADD CRYSTAL DIALOG
// ========================================

class _AddCrystalDialog extends StatefulWidget {
  final String username;
  final String userId;
  final String roomId;
  
  const _AddCrystalDialog({
    required this.username,
    required this.userId,
    required this.roomId,
  });

  @override
  State<_AddCrystalDialog> createState() => _AddCrystalDialogState();
}

class _AddCrystalDialogState extends State<_AddCrystalDialog> {
  final GroupToolsService _toolsService = GroupToolsService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _usesController = TextEditingController();
  final _propertyController = TextEditingController();
  
  final List<String> _properties = [];
  bool _isSubmitting = false;
  
  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _usesController.dispose();
    _propertyController.dispose();
    super.dispose();
  }
  
  void _addProperty() {
    final prop = _propertyController.text.trim();
    if (prop.isNotEmpty && !_properties.contains(prop)) {
      setState(() {
        _properties.add(prop);
        _propertyController.clear();
      });
    }
  }
  
  void _removeProperty(String prop) {
    setState(() => _properties.remove(prop));
  }
  
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final crystalId = await _toolsService.addCrystal(
        roomId: widget.roomId,
        userId: widget.userId,
        username: widget.username,
        crystalName: _nameController.text.trim(),
        crystalType: _typeController.text.trim(),
        properties: _properties,
        uses: _usesController.text.trim(),
      );
      
      if (crystalId != null && mounted) {
        Navigator.of(context).pop({
          'success': true,
          'crystal_name': _nameController.text.trim(),
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Fehler beim Hinzufügen'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                        ),
                      ),
                      child: const Icon(Icons.diamond, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '💠 Kristall hinzufügen',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Name
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Kristall-Name *',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'z.B. Amethyst',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Bitte Namen eingeben';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Type
                TextFormField(
                  controller: _typeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Typ/Kategorie',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'z.B. Quarz, Edelstein',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Properties
                const Text(
                  'Eigenschaften',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _propertyController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'z.B. Beruhigend',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _addProperty(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addProperty,
                      icon: const Icon(Icons.add_circle, color: Colors.purple),
                    ),
                  ],
                ),
                
                if (_properties.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _properties.map((prop) {
                      return Chip(
                        label: Text(prop),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeProperty(prop),
                        backgroundColor: Colors.purple.withValues(alpha: 0.2),
                        labelStyle: const TextStyle(color: Colors.white),
                      );
                    }).toList(),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Uses
                TextFormField(
                  controller: _usesController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Anwendung & Wirkung',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'z.B. Meditation, Schlaf, Drittes Auge öffnen...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Abbrechen'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C27B0),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Hinzufügen'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========================================
// 💠 CRYSTAL DETAILS DIALOG
// ========================================

class _CrystalDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> crystal;
  
  const _CrystalDetailsDialog({required this.crystal});

  @override
  Widget build(BuildContext context) {
    final name = crystal['crystal_name'] ?? 'Unbekannt';
    final type = crystal['crystal_type'] ?? '';
    final uses = crystal['uses'] ?? '';
    final likes = crystal['likes'] ?? 0;
    final username = crystal['username'] ?? 'Anonym';
// UNUSED: final createdAt = crystal['created_at'] ?? '';
    
    // Parse properties
    List<String> properties = [];
    try {
      final propsJson = crystal['properties'];
      if (propsJson is String && propsJson.isNotEmpty) {
        final decoded = List<String>.from(
          propsJson.startsWith('[') 
            ? (jsonDecode(propsJson) as List) 
            : [propsJson]
        );
        properties = decoded;
      } else if (propsJson is List) {
        properties = List<String>.from(propsJson);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error parsing properties in details: $e');
      }
    }
    
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                      ),
                    ),
                    child: const Icon(Icons.diamond, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (type.isNotEmpty)
                          Text(
                            type,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Properties
              if (properties.isNotEmpty) ...[
                const Text(
                  'Eigenschaften',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: properties.map((prop) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.purple.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        prop,
                        style: const TextStyle(color: Colors.purple, fontSize: 14),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
              
              // Uses
              if (uses.isNotEmpty) ...[
                const Text(
                  'Anwendung & Wirkung',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  uses,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                ),
                const SizedBox(height: 24),
              ],
              
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 20, color: Colors.white54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        username,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    ),
                    const Icon(Icons.favorite, size: 20, color: Colors.purple),
                    const SizedBox(width: 4),
                    Text(
                      likes.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
