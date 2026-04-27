import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:url_launcher/url_launcher.dart';
import '../../services/group_tools_service.dart';
import '../../services/user_service.dart';
import '../../services/free_api_service.dart';

/// 🛸 UFO-Sichtungen Screen
/// Community-Meldungen + offizielle NASA-Bolide/Fireball-Ereignisse
class UfoSightingsScreen extends StatefulWidget {
  final String roomId;

  const UfoSightingsScreen({super.key, this.roomId = 'ufos'});

  @override
  State<UfoSightingsScreen> createState() => _UfoSightingsScreenState();
}

class _UfoSightingsScreenState extends State<UfoSightingsScreen>
    with SingleTickerProviderStateMixin {
  final GroupToolsService _toolsService = GroupToolsService();
  final UserService _userService = UserService();
  final _api = FreeApiService.instance;

  late final TabController _tabCtrl;

  List<Map<String, dynamic>> _sightings = [];
  List<NasaFireball> _fireballs = [];

  bool _loadingSightings = false;
  bool _loadingFireballs = false;

  String _username = '';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadUserData();
    _loadSightings();
    _loadFireballs();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
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
      if (kDebugMode) debugPrint('❌ UFO load: $e');
      if (mounted) setState(() => _loadingSightings = false);
    }
  }

  Future<void> _loadFireballs() async {
    setState(() => _loadingFireballs = true);
    final result = await _api.fetchFireballs(limit: 30);
    if (mounted) setState(() { _fireballs = result; _loadingFireballs = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('🛸 UFO & Luftphänomene'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () { _loadSightings(); _loadFireballs(); },
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.green,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.white54,
          tabs: [
            Tab(text: 'Community (${_sightings.length})'),
            Tab(text: '🔥 NASA Fireballs'),
          ],
        ),
      ),
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
              backgroundColor: Colors.green,
              icon: const Icon(Icons.add_location),
              label: const Text('Sichtung melden'),
            )
          : null,
    );
  }

  // ── Tab 1: Community Sichtungen ──────────────────────────────────────────

  Widget _buildCommunityTab() {
    if (_loadingSightings) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }
    if (_sightings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rocket_launch, size: 64, color: Colors.green.shade400),
            const SizedBox(height: 16),
            const Text('Noch keine Community-Sichtungen',
                style: TextStyle(color: Colors.white38)),
            const SizedBox(height: 8),
            const Text('Schau dir offizielle NASA-Daten im "🔥 Fireballs"-Tab an!',
                style: TextStyle(color: Colors.white24, fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadSightings,
      color: Colors.green,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sightings.length,
        itemBuilder: (context, index) => _buildSightingCard(_sightings[index]),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      colors: [Colors.green.shade600, Colors.green.shade900],
                    ),
                  ),
                  child: const Icon(Icons.rocket_launch, color: Colors.white),
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
                          style: TextStyle(color: Colors.green.shade400, fontSize: 12)),
                    ],
                  ),
                ),
                if (verified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 12),
            Text(description,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.white54),
                const SizedBox(width: 4),
                Text(username, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(width: 16),
                const Icon(Icons.group, size: 16, color: Colors.white54),
                const SizedBox(width: 4),
                Text('$witnesses Zeugen',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _fireballs.length + 1,
        itemBuilder: (ctx, i) {
          if (i == 0) return _buildFireballHeader();
          return _buildFireballCard(_fireballs[i - 1]);
        },
      ),
    );
  }

  Widget _buildFireballHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.withValues(alpha: 0.2), Colors.red.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🔥', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text('NASA Bolide / Fireball Monitor',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_fireballs.length} bestätigte Atmosphären-Eintritte · Quelle: NASA JPL',
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
    final energy = fb.energy != null
        ? '${fb.energy!.toStringAsFixed(1)} GJ Energie'
        : null;
    final vel = fb.velocity != null
        ? '${fb.velocity!.toStringAsFixed(1)} km/s'
        : null;

    return Card(
      color: const Color(0xFF1A1A2E),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
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
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 10,
                    children: [
                      if (energy != null)
                        _chip(Icons.bolt, energy, Colors.orange),
                      if (vel != null)
                        _chip(Icons.speed, vel, Colors.blue),
                      if (fb.altitude != null)
                        _chip(Icons.height, '${fb.altitude!.toStringAsFixed(0)} km Höhe', Colors.green),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(dateStr, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(color: color, fontSize: 11)),
      ],
    );
  }

  // ── Dialog: Eigene Sichtung melden ──────────────────────────────────────

  void _showAddSightingDialog() {
    if (_username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Bitte erstelle erst ein Profil')),
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
            title: const Text('🛸 Sichtung melden', style: TextStyle(color: Colors.white)),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Melden'),
              ),
            ],
          ),
        );
      },
    );
  }
}
