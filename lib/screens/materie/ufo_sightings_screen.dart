import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:url_launcher/url_launcher.dart';
import '../../services/group_tools_service.dart';
import '../../services/user_service.dart';
import '../../services/free_api_service.dart';

/// UFO-Sichtungen Screen
/// Community-Meldungen + offizielle NASA-Bolide/Fireball-Ereignisse
class UfoSightingsScreen extends StatefulWidget {
  final String roomId;

  const UfoSightingsScreen({super.key, this.roomId = 'ufos'});

  @override
  State<UfoSightingsScreen> createState() => _UfoSightingsScreenState();
}

class _UfoSightingsScreenState extends State<UfoSightingsScreen>
    with TickerProviderStateMixin {
  final GroupToolsService _toolsService = GroupToolsService();
  final UserService _userService = UserService();
  final _api = FreeApiService.instance;

  late final TabController _tabCtrl;
  late final AnimationController _pulseCtrl;

  // Suchfeld NASA
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> _sightings = [];
  List<NasaFireball> _fireballs = [];
  List<NasaFireball> _filteredFireballs = [];

  bool _loadingSightings = false;
  bool _loadingFireballs = false;

  String _username = '';
  String _userId = '';

  static const _accentRed = Color(0xFFE53935);
  static const _bgDark = Color(0xFF0D0505);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _loadUserData();
    _loadSightings();
    _loadFireballs();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _pulseCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _userService.getCurrentUser();
      setState(() {
        _username = user.username;
        _userId = 'user_${user.username.toLowerCase()}';
      });
    } catch (_) {}
  }

  Future<void> _loadSightings() async {
    setState(() => _loadingSightings = true);
    try {
      final response = await _toolsService.getUfoSightings(roomId: widget.roomId);
      if (mounted) setState(() { _sightings = response; _loadingSightings = false; });
    } catch (e) {
      if (kDebugMode) debugPrint('UFO load: $e');
      if (mounted) setState(() => _loadingSightings = false);
    }
  }

  Future<void> _loadFireballs() async {
    setState(() => _loadingFireballs = true);
    final result = await _api.fetchFireballs(limit: 30);
    if (mounted) {
      setState(() {
        _fireballs = result;
        _filteredFireballs = result;
        _loadingFireballs = false;
      });
    }
  }

  void _applySearch(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredFireballs = _fireballs;
      } else {
        _filteredFireballs = _fireballs.where((fb) {
          final loc = fb.locationLabel.toLowerCase();
          final date = fb.date != null
              ? '${fb.date!.year}'.toLowerCase()
              : '';
          return loc.contains(_searchQuery) || date.contains(_searchQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildCommunityTab(),
          _buildFireballTab(),
        ],
      ),
      floatingActionButton: _tabCtrl.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddSightingDialog,
              backgroundColor: _accentRed,
              icon: const Icon(Icons.add_location),
              label: const Text('Sichtung melden'),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 48),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0505), Color(0xFF0D0D1A)],
          ),
          border: Border(bottom: BorderSide(color: Color(0x33E53935), width: 1)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Titelzeile
              SizedBox(
                height: kToolbarHeight,
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    BackButton(color: Colors.white70),
                    const SizedBox(width: 4),
                    const Text(
                      'UFO & Luftphänomene',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                      onPressed: () { _loadSightings(); _loadFireballs(); },
                    ),
                  ],
                ),
              ),
              // TabBar
              TabBar(
                controller: _tabCtrl,
                indicatorColor: _accentRed,
                indicatorWeight: 3,
                labelColor: _accentRed,
                unselectedLabelColor: Colors.white54,
                tabs: [
                  Tab(text: 'Community (${_sightings.length})'),
                  const Tab(text: 'NASA Fireballs'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Stats-Banner ─────────────────────────────────────────────────────────

  Widget _buildStatsBanner(int count, String label, Color color) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        final opacity = 0.5 + 0.5 * _pulseCtrl.value;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              // Pulsierender roter Punkt
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: opacity),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: opacity * 0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$count $label',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'LIVE',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Tab 1: Community Sichtungen ──────────────────────────────────────────

  Widget _buildCommunityTab() {
    if (_loadingSightings) {
      return const Center(child: CircularProgressIndicator(color: _accentRed));
    }
    if (_sightings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rocket_launch, size: 64, color: _accentRed.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text('Noch keine Community-Sichtungen',
                style: TextStyle(color: Colors.white38)),
            const SizedBox(height: 8),
            const Text('Schau dir offizielle NASA-Daten im "Fireballs"-Tab an!',
                style: TextStyle(color: Colors.white24, fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadSightings,
      color: _accentRed,
      child: Column(
        children: [
          _buildStatsBanner(_sightings.length, 'Community-Sichtungen', _accentRed),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _sightings.length,
              itemBuilder: (context, index) => _buildSightingCard(_sightings[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSightingCard(Map<String, dynamic> sighting) {
    final title = sighting['sighting_title'] ?? 'Unbekannt';
    final description = sighting['sighting_description'] ?? '';
    final username = sighting['username'] ?? 'Anonym';
    final objectType = sighting['object_type'] ?? 'unknown';
    final witnesses = sighting['witnesses'] ?? 1;
    final verified = sighting['verified'] == 1 || sighting['verified'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [_accentRed.withValues(alpha: 0.6), _accentRed.withValues(alpha: 0.2)],
                    ),
                  ),
                  child: const Icon(Icons.rocket_launch, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(objectType.toUpperCase(),
                          style: TextStyle(color: _accentRed.withValues(alpha: 0.8), fontSize: 12)),
                    ],
                  ),
                ),
                if (verified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 14, color: Colors.blue),
                        SizedBox(width: 4),
                        Text('Verifiziert', style: TextStyle(color: Colors.blue, fontSize: 11)),
                      ],
                    ),
                  ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(description,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.white38),
                const SizedBox(width: 4),
                Text(username, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(width: 16),
                const Icon(Icons.group_outlined, size: 14, color: Colors.white38),
                const SizedBox(width: 4),
                Text('$witnesses Zeugen',
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 2: NASA Fireballs ────────────────────────────────────────────────

  Widget _buildFireballTab() {
    if (_loadingFireballs) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 16),
            Text('Lade NASA Bolide-Daten…', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }
    if (_fireballs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            const Text('NASA SSD nicht erreichbar', style: TextStyle(color: Colors.white54)),
            TextButton(
              onPressed: _loadFireballs,
              child: const Text('Neu laden', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadFireballs,
      color: Colors.orange,
      child: Column(
        children: [
          _buildStatsBanner(_fireballs.length, 'bestätigte Bolid-Ereignisse', Colors.orange),
          _buildFireballSearchBar(),
          Expanded(
            child: _filteredFireballs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 48, color: Colors.white24),
                        const SizedBox(height: 12),
                        Text('Keine Treffer für "$_searchQuery"',
                            style: const TextStyle(color: Colors.white54)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    itemCount: _filteredFireballs.length + 1,
                    itemBuilder: (ctx, i) {
                      if (i == 0) return _buildFireballHeader();
                      return _buildFireballCard(_filteredFireballs[i - 1]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFireballSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              onChanged: _applySearch,
              decoration: InputDecoration(
                hintText: 'Was ist das? (Ort, Jahr…)',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.orange.withValues(alpha: 0.5)),
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.orange, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _applySearch('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFireballHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.withValues(alpha: 0.15), Colors.red.withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('NASA Bolide / Fireball Monitor',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_filteredFireballs.length} von ${_fireballs.length} Einträgen · Quelle: NASA JPL',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final uri = Uri.parse('https://cneos.jpl.nasa.gov/fireballs/');
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: const Text(
              'cneos.jpl.nasa.gov/fireballs →',
              style: TextStyle(color: Colors.orange, fontSize: 12, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFireballCard(NasaFireball fb) {
    final date = fb.date;
    final dateStr = date != null
        ? '${date.day}.${date.month}.${date.year}'
        : 'Datum unbekannt';

    // Energie-Badge Farbe je nach Stärke
    Color energyColor = Colors.orange;
    String energyLabel = 'Unbekannt';
    if (fb.energy != null) {
      final e = fb.energy!;
      if (e >= 100) {
        energyColor = Colors.red;
        energyLabel = '${e.toStringAsFixed(0)} GJ';
      } else if (e >= 10) {
        energyColor = Colors.orange;
        energyLabel = '${e.toStringAsFixed(1)} GJ';
      } else {
        energyColor = Colors.yellow.shade700;
        energyLabel = '${e.toStringAsFixed(2)} GJ';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('☄️', style: TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fb.locationLabel,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  // Energie + Geschwindigkeit als farbige Badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (fb.energy != null)
                        _badge(Icons.bolt, energyLabel, energyColor),
                      if (fb.velocity != null)
                        _badge(Icons.speed,
                            '${fb.velocity!.toStringAsFixed(1)} km/s', Colors.blue),
                      if (fb.altitude != null)
                        _badge(Icons.height,
                            '${fb.altitude!.toStringAsFixed(0)} km', Colors.tealAccent.shade700),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(dateStr, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Dialog: Eigene Sichtung melden ──────────────────────────────────────

  void _showAddSightingDialog() {
    if (_username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte erstelle erst ein Profil')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final titleCtrl = TextEditingController();
        final descCtrl = TextEditingController();
        String objectType = 'light';
        int witnesses = 1;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Sichtung melden', style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Titel',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  TextField(
                    controller: descCtrl,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Beschreibung',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: objectType,
                    dropdownColor: const Color(0xFF1A1A2E),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Objekt-Typ',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'light', child: Text('Licht')),
                      DropdownMenuItem(value: 'craft', child: Text('Raumschiff')),
                      DropdownMenuItem(value: 'orb', child: Text('Orb')),
                      DropdownMenuItem(value: 'triangle', child: Text('Dreieck')),
                      DropdownMenuItem(value: 'disc', child: Text('Scheibe')),
                    ],
                    onChanged: (val) => setState(() => objectType = val!),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Zeugen:', style: TextStyle(color: Colors.white70)),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.white),
                        onPressed: () { if (witnesses > 1) setState(() => witnesses--); },
                      ),
                      Text('$witnesses', style: const TextStyle(color: Colors.white, fontSize: 18)),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () => setState(() => witnesses++),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
              ElevatedButton(
                onPressed: () async {
                  final id = await _toolsService.createUfoSighting(
                    roomId: widget.roomId,
                    userId: _userId,
                    username: _username,
                    title: titleCtrl.text,
                    description: descCtrl.text,
                    objectType: objectType,
                    witnesses: witnesses,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    if (id != null) _loadSightings();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _accentRed),
                child: const Text('Melden'),
              ),
            ],
          ),
        );
      },
    );
  }
}
