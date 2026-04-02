import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/user_auth_service.dart'; // ✅ Real Auth

class UfoSichtungenEnhanced extends StatefulWidget {
  final String roomId;

  const UfoSichtungenEnhanced({super.key, required this.roomId});

  @override
  State<UfoSichtungenEnhanced> createState() => _UfoSichtungenEnhancedState();
}

class _UfoSichtungenEnhancedState extends State<UfoSichtungenEnhanced> {
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<Map<String, dynamic>> _sichtungen = [];
  Timer? _refreshTimer;
  bool _isLoading = false;
  
  // ✅ Real User Auth
  String? _currentUsername;
  String? _currentUserId;
  bool _isAuthenticated = false;
  int _activeWitnesses = 0;
  String _selectedType = 'Licht';

  @override
  void initState() {
    super.initState();
    _loadUserAuth();
    _loadSichtungen();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadSichtungen());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ✅ Load real user auth
  Future<void> _loadUserAuth() async {
    _currentUsername = await UserAuthService.getUsername();
    _currentUserId = await UserAuthService.getUserId();
    setState(() {
      _isAuthenticated = _currentUsername != null;
    });
  }

  Future<void> _loadSichtungen() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.ufoSichtungenUrl}?room_id=${widget.roomId}'),
        headers: {'Authorization': 'Bearer _C578hgIAimVPG0WjfeAjk23RxQMQ9gox0W7ebLv'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _sichtungen = data.cast<Map<String, dynamic>>();
          _activeWitnesses = _sichtungen.map((e) => e['username'] as String?).toSet().length;
        });
      }
    } catch (e) {
      // Fehler ignorieren
    }
  }

  Future<void> _addSichtung() async {
    if (_locationController.text.isEmpty || _descriptionController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.ufoSichtungenUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer _C578hgIAimVPG0WjfeAjk23RxQMQ9gox0W7ebLv',
        },
        body: jsonEncode({
          'room_id': widget.roomId,
          'location': _locationController.text.trim(),
          'sighting_type': _selectedType,
          'description': _descriptionController.text.trim(),
          'username': _currentUsername, // ✅ Real username
          'user_id': _currentUserId,    // ✅ Real user ID,
          'verified': false,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _locationController.clear();
        _descriptionController.clear();
        await _loadSichtungen();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🛸 UFO-Sichtung gemeldet!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getUfoIcon(String type) {
    switch (type) {
      case 'Licht': return '💡';
      case 'Scheibe': return '🛸';
      case 'Dreieck': return '🔺';
      case 'Zigarre': return '🚬';
      default: return '🛸';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Text('🛸', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'UFO-SICHTUNGS-NETZWERK',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${_sichtungen.length} Sichtungen • $_activeWitnesses Zeugen',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Eingabeformular
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Ort der Sichtung',
                      hintText: 'z.B. Berlin, 52.52°N 13.40°E',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'UFO-Typ',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: ['Licht', 'Scheibe', 'Dreieck', 'Zigarre', 'Sonstiges']
                        .map((type) => DropdownMenuItem(value: type, child: Text('${_getUfoIcon(type)} $type')))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedType = value!),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Beschreibung',
                      hintText: 'Was hast du beobachtet?',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _addSichtung,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send),
                      label: Text(_isLoading ? 'Wird gemeldet...' : 'Sichtung melden'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sichtungen-Liste
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: _sichtungen.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🛸', style: TextStyle(fontSize: 48)),
                            SizedBox(height: 8),
                            Text(
                              'Noch keine Sichtungen',
                              style: TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'Sei der Erste, der eine UFO-Beobachtung meldet!',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _sichtungen.length,
                      itemBuilder: (context, index) {
                        final sichtung = _sichtungen[index];
                        final username = sichtung['username'] as String? ?? 'Anonym';
                        final location = sichtung['location'] as String? ?? 'Unbekannt';
                        final type = sichtung['sighting_type'] as String? ?? 'Unbekannt';
                        final description = sichtung['description'] as String? ?? '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF4CAF50),
                              child: Text(
                                _getUfoIcon(type),
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                            title: Text(
                              location,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Typ: $type', style: const TextStyle(fontSize: 12)),
                                if (description.isNotEmpty)
                                  Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  'Gemeldet von $username',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
