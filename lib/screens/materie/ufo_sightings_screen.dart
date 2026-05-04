import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;

import '../../services/free_api_service.dart';
import '../../services/group_tools_service.dart';
import '../../services/user_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design-Tokens (Materie – Rot)
// ─────────────────────────────────────────────────────────────────────────────
const _kAccent = Color(0xFFE53935);
const _kAccentDim = Color(0xFFB71C1C);
const _kBg = Color(0xFF0D0505);
const _kSurface = Color(0xFF1A0000);
const _kSurfaceAlt = Color(0xFF150A0A);
const _kText = Colors.white;
const _kTextMuted = Color(0xFFB0A0A0);
const _kBorder = Color(0x33E53935);

// ─────────────────────────────────────────────────────────────────────────────
// Screen Widget
// ─────────────────────────────────────────────────────────────────────────────

/// UFO-Sichtungen Screen — 3 Tabs:
///   1. Community-Sichtungen (GroupToolsService)
///   2. NASA Fireballs      (FreeApiService)
///   3. OpenSky Radar       (OpenSky REST API — no auth)
class UfoSightingsScreen extends StatefulWidget {
  final String roomId;

  const UfoSightingsScreen({super.key, this.roomId = 'ufos'});

  @override
  State<UfoSightingsScreen> createState() => _UfoSightingsScreenState();
}

class _UfoSightingsScreenState extends State<UfoSightingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  // ── Community state ──────────────────────────────────────────────────────
  final _toolsService = GroupToolsService();
  List<Map<String, dynamic>> _sightings = [];
  bool _loadingSightings = false;
  String? _sightingsError;

  // ── NASA Fireball state ──────────────────────────────────────────────────
  final _api = FreeApiService.instance;
  List<NasaFireball> _fireballs = [];
  List<NasaFireball> _filteredFireballs = [];
  bool _loadingFireballs = false;
  String? _fireballsError;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // ── Radar state ───────────────────────────────────────────────────────────
  final _latCtrl = TextEditingController(text: '48.8');
  final _lonCtrl = TextEditingController(text: '2.35');
  List<_AircraftState> _aircraft = [];
  bool _loadingRadar = false;
  String? _radarError;

  // ── User ─────────────────────────────────────────────────────────────────
  String _userId = '';
  String _username = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(_onTabChanged);
    _resolveUser();
    _loadSightings();
  }

  void _onTabChanged() {
    if (!_tabCtrl.indexIsChanging) return;
    if (_tabCtrl.index == 1 && _fireballs.isEmpty && !_loadingFireballs) {
      _loadFireballs();
    }
  }

  Future<void> _resolveUser() async {
    _userId = UserService.getCurrentUserId();
    _username = UserService.getCurrentUsername();
  }

  @override
  void dispose() {
    _tabCtrl.removeListener(_onTabChanged);
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Data loading
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadSightings() async {
    setState(() {
      _loadingSightings = true;
      _sightingsError = null;
    });
    try {
      final data = await _toolsService.getUfoSightings(roomId: widget.roomId);
      if (!mounted) return;
      setState(() {
        _sightings = data;
        _loadingSightings = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sightingsError = 'Fehler beim Laden: $e';
        _loadingSightings = false;
      });
    }
  }

  Future<void> _loadFireballs() async {
    setState(() {
      _loadingFireballs = true;
      _fireballsError = null;
    });
    try {
      final data = await _api.fetchFireballs(limit: 40);
      if (!mounted) return;
      setState(() {
        _fireballs = data;
        _filteredFireballs = data;
        _loadingFireballs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fireballsError = 'NASA-Daten konnten nicht geladen werden: $e';
        _loadingFireballs = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredFireballs = _fireballs;
      } else {
        _filteredFireballs = _fireballs.where((f) {
          final loc = f.locationLabel.toLowerCase();
          final date = (f.date?.toIso8601String() ?? '').toLowerCase();
          return loc.contains(_searchQuery) || date.contains(_searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _fetchRadar() async {
    final lat = double.tryParse(_latCtrl.text.trim());
    final lon = double.tryParse(_lonCtrl.text.trim());
    if (lat == null || lon == null) {
      setState(() => _radarError = 'Bitte gültige Koordinaten eingeben (z.B. 48.8 / 2.35).');
      return;
    }
    setState(() {
      _loadingRadar = true;
      _radarError = null;
      _aircraft = [];
    });
    final url = Uri.parse(
      'https://opensky-network.org/api/states/all'
      '?lamin=${lat - 2}&lomin=${lon - 2}&lamax=${lat + 2}&lomax=${lon + 2}',
    );
    try {
      final resp = await http.get(url).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final states = body['states'] as List? ?? [];
        setState(() {
          _aircraft = states.map(_AircraftState.fromList).toList()
            ..sort((a, b) => (b.altitude ?? -1).compareTo(a.altitude ?? -1));
          _loadingRadar = false;
        });
      } else if (resp.statusCode == 429) {
        setState(() {
          _radarError = 'Rate-Limit erreicht. Bitte 10 Sekunden warten und erneut versuchen.';
          _loadingRadar = false;
        });
      } else {
        setState(() {
          _radarError = 'OpenSky-Server antwortete mit Status ${resp.statusCode}.';
          _loadingRadar = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _radarError = 'Verbindungsfehler: $e';
        _loadingRadar = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Add sighting dialog
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _showAddSightingDialog() async {
    final titleCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool submitting = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: _kSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _kBorder),
          ),
          title: const Text(
            'Sichtung melden',
            style: TextStyle(color: _kText, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dlgField(titleCtrl, 'Titel', Icons.title),
                const SizedBox(height: 12),
                _dlgField(locationCtrl, 'Ort / Region', Icons.location_on_outlined),
                const SizedBox(height: 12),
                _dlgField(descCtrl, 'Beschreibung', Icons.description_outlined,
                    maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen', style: TextStyle(color: _kTextMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: submitting
                  ? null
                  : () async {
                      final title = titleCtrl.text.trim();
                      final location = locationCtrl.text.trim();
                      final rawDesc = descCtrl.text.trim();
                      if (title.isEmpty || rawDesc.isEmpty) return;
                      final desc = location.isNotEmpty
                          ? 'Ort: $location\n$rawDesc'
                          : rawDesc;
                      setDlgState(() => submitting = true);
                      try {
                        await _toolsService.createUfoSighting(
                          roomId: widget.roomId,
                          userId: _userId,
                          username: _username.isNotEmpty ? _username : 'Anonym',
                          title: title,
                          description: desc,
                          objectType: 'light',
                          witnesses: 1,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _loadSightings();
                      } catch (e) {
                        if (kDebugMode) debugPrint('❌ createUfoSighting: $e');
                        setDlgState(() => submitting = false);
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Melden'),
            ),
          ],
        ),
      ),
    );
    titleCtrl.dispose();
    locationCtrl.dispose();
    descCtrl.dispose();
  }

  Widget _dlgField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: _kText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kTextMuted),
        prefixIcon: Icon(icon, color: _kAccent, size: 18),
        filled: true,
        fillColor: _kSurfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kAccent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kSurface,
        foregroundColor: _kText,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _kAccent.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.blur_on, color: _kAccent, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'UFO-Sichtungen',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _kText),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: _kAccent,
          unselectedLabelColor: _kTextMuted,
          indicatorColor: _kAccent,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(icon: Icon(Icons.people_outline, size: 18), text: 'Community'),
            Tab(icon: Icon(Icons.local_fire_department_outlined, size: 18), text: 'NASA'),
            Tab(icon: Icon(Icons.radar, size: 18), text: 'Radar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildCommunityTab(),
          _buildNasaTab(),
          _buildRadarTab(),
        ],
      ),
      floatingActionButton: _tabCtrl.index == 0
          ? FloatingActionButton.extended(
              backgroundColor: _kAccent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Sichtung melden'),
              onPressed: _showAddSightingDialog,
            )
          : null,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tab 1: Community
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCommunityTab() {
    if (_loadingSightings) {
      return const Center(
          child: CircularProgressIndicator(color: _kAccent));
    }
    if (_sightingsError != null) {
      return _errorView(_sightingsError!, _loadSightings);
    }
    if (_sightings.isEmpty) {
      return _emptyView(
        Icons.blur_on,
        'Noch keine Sichtungen',
        'Sei der Erste, der eine UFO-Sichtung meldet!',
      );
    }

    final latest = _sightings.first;
    final latestDate = _formatDate(latest['created_at'] as String?);

    return RefreshIndicator(
      color: _kAccent,
      backgroundColor: _kSurface,
      onRefresh: _loadSightings,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _statsBanner(_sightings.length, latestDate)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _sightingCard(_sightings[i]),
                childCount: _sightings.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsBanner(int count, String latestDate) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kAccent.withAlpha(40), _kSurface],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          _statChip(Icons.visibility_outlined, '$count', 'Sichtungen'),
          const SizedBox(width: 16),
          _statChip(Icons.calendar_today_outlined, latestDate, 'Zuletzt'),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: _kAccent, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    color: _kText,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            Text(label,
                style: const TextStyle(color: _kTextMuted, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _sightingCard(Map<String, dynamic> s) {
    final title = s['sighting_title'] as String? ?? 'Unbekanntes Objekt';
    final desc = s['sighting_description'] as String? ?? '';
    final date = _formatDate(s['created_at'] as String?);
    final username = s['username'] as String? ?? 'Anonym';
    final objectType = s['object_type'] as String? ?? 'light';
    final witnesses = s['witnesses'] as int? ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kAccent.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_shapeIcon(objectType),
                      color: _kAccent, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: _kText,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('@$username · $date',
                          style: const TextStyle(
                              color: _kTextMuted, fontSize: 11)),
                    ],
                  ),
                ),
                _badge(Icons.person_outline, '$witnesses Zeuge${witnesses != 1 ? 'n' : ''}'),
              ],
            ),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(desc,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _kTextMuted, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }

  IconData _shapeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'disc':
      case 'disk':
        return Icons.circle_outlined;
      case 'triangle':
        return Icons.change_history_outlined;
      case 'orb':
      case 'sphere':
      case 'ball':
        return Icons.brightness_1_outlined;
      case 'cylinder':
        return Icons.crop_portrait_outlined;
      case 'chevron':
        return Icons.chevron_right;
      default:
        return Icons.blur_on;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tab 2: NASA Fireballs
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildNasaTab() {
    if (_loadingFireballs) {
      return const Center(
          child: CircularProgressIndicator(color: _kAccent));
    }
    if (_fireballsError != null) {
      return _errorView(_fireballsError!, _loadFireballs);
    }
    if (_fireballs.isEmpty) {
      return Center(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: _kAccent),
          icon: const Icon(Icons.download_rounded, color: Colors.white),
          label: const Text('NASA-Daten laden',
              style: TextStyle(color: Colors.white)),
          onPressed: _loadFireballs,
        ),
      );
    }

    final maxEnergy = _fireballs
        .map((f) => f.energy ?? 0.0)
        .fold(0.0, (a, b) => a > b ? a : b);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              _nasaStatsBanner(_fireballs.length, maxEnergy),
              _searchBar(),
            ],
          ),
        ),
        if (_filteredFireballs.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Text('Keine Ergebnisse für diese Suche.',
                  style: TextStyle(color: _kTextMuted)),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _fireballCard(_filteredFireballs[i]),
                childCount: _filteredFireballs.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _nasaStatsBanner(int count, double maxEnergy) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A0000), _kSurface],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          _statChip(Icons.local_fire_department, '$count', 'Bolide'),
          const SizedBox(width: 16),
          _statChip(Icons.bolt_outlined,
              maxEnergy > 0 ? '${maxEnergy.toStringAsFixed(1)} GJ' : '–',
              'Max. Energie'),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _kAccent.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _kBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: _kTextMuted, size: 12),
                  SizedBox(width: 4),
                  Text('NASA SSD', style: TextStyle(color: _kTextMuted, fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _onSearchChanged,
        style: const TextStyle(color: _kText),
        decoration: InputDecoration(
          hintText: 'Nach Ort oder Datum suchen…',
          hintStyle: const TextStyle(color: _kTextMuted),
          prefixIcon: const Icon(Icons.search, color: _kTextMuted, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: _kTextMuted, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: _kSurface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kAccent, width: 1.5)),
        ),
      ),
    );
  }

  Widget _fireballCard(NasaFireball f) {
    final energy = f.energy;
    final energyColor = energy == null
        ? _kTextMuted
        : energy >= 100
            ? const Color(0xFFE53935)
            : energy >= 10
                ? const Color(0xFFFF9800)
                : const Color(0xFFFFEB3B);
    final energyLabel =
        energy != null ? '${energy.toStringAsFixed(1)} GJ' : '–';
    final date = f.date != null
        ? '${f.date!.day.toString().padLeft(2, '0')}.${f.date!.month.toString().padLeft(2, '0')}.${f.date!.year}'
        : 'Datum unbekannt';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Energy badge
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: energyColor.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: energyColor.withAlpha(80)),
              ),
              child: Column(
                children: [
                  Icon(Icons.local_fire_department,
                      color: energyColor, size: 20),
                  const SizedBox(height: 4),
                  Text(energyLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: energyColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: _kTextMuted, size: 13),
                      const SizedBox(width: 4),
                      Text(date,
                          style: const TextStyle(
                              color: _kText,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: _kTextMuted, size: 13),
                      const SizedBox(width: 4),
                      Text(f.locationLabel,
                          style: const TextStyle(
                              color: _kTextMuted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (f.velocity != null)
                        _infoChip(Icons.speed_outlined,
                            '${f.velocity!.toStringAsFixed(1)} km/s'),
                      if (f.altitude != null)
                        _infoChip(Icons.height_outlined,
                            '${f.altitude!.toStringAsFixed(0)} km'),
                      if (f.impactEnergy != null)
                        _infoChip(Icons.bolt_outlined,
                            '${f.impactEnergy!.toStringAsFixed(2)} kt Impact'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: _kSurfaceAlt,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _kTextMuted, size: 11),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(color: _kTextMuted, fontSize: 10)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tab 3: OpenSky Radar
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildRadarTab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _radarHeader(),
              _radarInputPanel(),
              if (_radarError != null) _radarErrorBanner(_radarError!),
              if (_loadingRadar)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                      child: CircularProgressIndicator(color: _kAccent)),
                ),
              if (!_loadingRadar && _aircraft.isNotEmpty)
                _aircraftListHeader(),
            ],
          ),
        ),
        if (!_loadingRadar && _aircraft.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _aircraftCard(_aircraft[i]),
                childCount: _aircraft.length,
              ),
            ),
          ),
        if (!_loadingRadar && _aircraft.isEmpty && _radarError == null)
          const SliverFillRemaining(
            child: Padding(
              padding: EdgeInsets.only(top: 32),
              child: _RadarEmptyHint(),
            ),
          ),
      ],
    );
  }

  Widget _radarHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.radar, color: _kAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'Radar-Check: Konventionelle Flugzeuge?',
                style: TextStyle(
                    color: _kText,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Gib die Koordinaten eines Sichtungsortes ein. '
            'Die App prüft via OpenSky Network, ob zum Zeitpunkt '
            'konventionelle Luftfahrzeuge im ±2°-Umkreis aktiv waren. '
            'Leere Ergebnisse erhöhen die Glaubwürdigkeit einer Sichtung.',
            style: TextStyle(color: _kTextMuted, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _radarInputPanel() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _coordField(
                  _latCtrl,
                  'Breitengrad',
                  'z.B. 48.8',
                  Icons.north_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _coordField(
                  _lonCtrl,
                  'Längengrad',
                  'z.B. 2.35',
                  Icons.east_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: _loadingRadar
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.radar, size: 18),
              label: Text(_loadingRadar ? 'Suche läuft…' : 'Radar starten'),
              onPressed: _loadingRadar ? null : _fetchRadar,
            ),
          ),
        ],
      ),
    );
  }

  Widget _coordField(
    TextEditingController ctrl,
    String label,
    String hint,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: _kTextMuted, fontSize: 11)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true, signed: true),
          style: const TextStyle(color: _kText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _kTextMuted),
            prefixIcon: Icon(icon, color: _kAccent, size: 16),
            filled: true,
            fillColor: _kSurface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kBorder)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kAccent, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _radarErrorBanner(String msg) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kAccentDim.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kAccentDim),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: _kAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg,
                style: const TextStyle(color: _kTextMuted, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _aircraftListHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          const Icon(Icons.flight, color: _kAccent, size: 16),
          const SizedBox(width: 6),
          Text(
            '${_aircraft.length} Luftfahrzeug${_aircraft.length != 1 ? 'e' : ''} im Umkreis',
            style: const TextStyle(
                color: _kText,
                fontWeight: FontWeight.bold,
                fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _aircraftCard(_AircraftState ac) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kAccent.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.flight, color: _kAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ac.callsign.isNotEmpty ? ac.callsign : '(kein Rufzeichen)',
                  style: const TextStyle(
                      color: _kText,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (ac.altitude != null)
                      _infoChip(Icons.height_outlined,
                          '${ac.altitude!.round()} m'),
                    if (ac.altitude != null) const SizedBox(width: 6),
                    if (ac.velocity != null)
                      _infoChip(Icons.speed_outlined,
                          '${ac.velocity!.round()} m/s'),
                    if (ac.velocity != null) const SizedBox(width: 6),
                    if (ac.heading != null)
                      _infoChip(Icons.navigation_outlined,
                          '${ac.heading!.round()}°'),
                  ],
                ),
              ],
            ),
          ),
          if (ac.onGround)
            _badge(Icons.airplanemode_active_outlined, 'Am Boden'),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Shared helpers
  // ─────────────────────────────────────────────────────────────────────────

  Widget _badge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: _kSurfaceAlt,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _kTextMuted, size: 11),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(color: _kTextMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _errorView(String msg, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: _kTextMuted, size: 48),
            const SizedBox(height: 16),
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kTextMuted, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _kAccent),
              icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
              label: const Text('Erneut versuchen',
                  style: TextStyle(color: Colors.white)),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyView(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _kTextMuted, size: 52),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: _kText,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kTextMuted, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '–';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return iso.length > 10 ? iso.substring(0, 10) : iso;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Aircraft state model (OpenSky Network)
// ─────────────────────────────────────────────────────────────────────────────

class _AircraftState {
  final String callsign;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? velocity;
  final double? heading;
  final bool onGround;

  const _AircraftState({
    required this.callsign,
    this.latitude,
    this.longitude,
    this.altitude,
    this.velocity,
    this.heading,
    required this.onGround,
  });

  /// OpenSky `states/all` returns arrays:
  /// [0]=icao24, [1]=callsign, [2]=origin_country, [3]=time_pos,
  /// [4]=last_contact, [5]=lon, [6]=lat, [7]=baro_alt,
  /// [8]=on_ground, [9]=velocity, [10]=true_track, ...
  factory _AircraftState.fromList(dynamic raw) {
    final List list = raw as List;
    double? _d(int i) {
      if (i >= list.length || list[i] == null) return null;
      return (list[i] as num?)?.toDouble();
    }

    return _AircraftState(
      callsign: ((list.length > 1 ? list[1] : null) as String? ?? '').trim(),
      longitude: _d(5),
      latitude: _d(6),
      altitude: _d(7),
      onGround: (list.length > 8 && list[8] == true),
      velocity: _d(9),
      heading: _d(10),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Radar empty hint (const-safe)
// ─────────────────────────────────────────────────────────────────────────────

class _RadarEmptyHint extends StatelessWidget {
  const _RadarEmptyHint();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.radar, color: _kTextMuted, size: 52),
        const SizedBox(height: 14),
        const Text(
          'Koordinaten eingeben und\n„Radar starten" tippen.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _kTextMuted, fontSize: 13),
        ),
        const SizedBox(height: 8),
        const Text(
          'OpenSky liefert Live-Daten — kein API-Key nötig.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _kTextMuted, fontSize: 11),
        ),
      ],
    );
  }
}
