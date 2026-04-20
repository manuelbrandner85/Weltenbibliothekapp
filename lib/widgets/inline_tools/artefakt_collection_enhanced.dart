import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/user_auth_service.dart'; // ✅ Real Auth

class ArtefaktCollectionEnhanced extends StatefulWidget {
  final String roomId;

  const ArtefaktCollectionEnhanced({super.key, required this.roomId});

  @override
  State<ArtefaktCollectionEnhanced> createState() => _ArtefaktCollectionEnhancedState();
}

class _ArtefaktCollectionEnhancedState extends State<ArtefaktCollectionEnhanced> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<Map<String, dynamic>> _artefakte = [];
  Timer? _refreshTimer;
  bool _isLoading = false;
  int _activeCollectors = 0;
  
  // ✅ Real User Auth
  String? _currentUsername;
  String? _currentUserId;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _loadUserAuth();
    _loadArtefakte();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadArtefakte());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _nameController.dispose();
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

  Future<void> _loadArtefakte() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.artefakteUrl}?room_id=${widget.roomId}'),
        headers: {'Authorization': 'Bearer _C578hgIAimVPG0WjfeAjk23RxQMQ9gox0W7ebLv'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _artefakte = data.cast<Map<String, dynamic>>();
          _activeCollectors = _artefakte.map((e) => e['username'] as String?).toSet().length;
        });
      }
    } catch (e) {
      // Fehler ignorieren
    }
  }

  Future<void> _addArtefakt() async {
    if (_nameController.text.isEmpty || _locationController.text.isEmpty) return;

    // ✅ Check authentication
    if (!_isAuthenticated || _currentUsername == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Bitte erstelle zuerst ein Profil'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.artefakteUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer _C578hgIAimVPG0WjfeAjk23RxQMQ9gox0W7ebLv',
        },
        body: jsonEncode({
          'room_id': widget.roomId,
          'name': _nameController.text.trim(),
          'location': _locationController.text.trim(),
          'description': _descriptionController.text.trim(),
          'username': _currentUsername, // ✅ Real username
          'user_id': _currentUserId,    // ✅ Real user ID
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _nameController.clear();
        _locationController.clear();
        _descriptionController.clear();
        await _loadArtefakte();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🏺 Artefakt zur Sammlung hinzugefügt!'), backgroundColor: Colors.amber),
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB300), Color(0xFFFFA000)],
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
            // Header mit Live-Stats
            Row(
              children: [
                const Icon(Icons.museum, color: Colors.white, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ARTEFAKT-SAMMLUNG',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${_artefakte.length} Fundstücke • $_activeCollectors Sammler',
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
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Artefakt-Name',
                      hintText: 'z.B. Goldene Maske',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Fundort',
                      hintText: 'z.B. Ägypten, Tal der Könige',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Beschreibung (optional)',
                      hintText: 'Details zum Fund...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _addArtefakt,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.add),
                      label: Text(_isLoading ? 'Wird hinzugefügt...' : 'Zur Sammlung hinzufügen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Artefakte-Liste
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: _artefakte.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.museum, size: 48, color: Colors.white54),
                            SizedBox(height: 8),
                            Text(
                              'Noch keine Artefakte gesammelt',
                              style: TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'Sei der Erste, der ein antikes Fundstück teilt!',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _artefakte.length,
                      itemBuilder: (context, index) {
                        final artefakt = _artefakte[index];
                        final username = artefakt['username'] as String? ?? 'Anonym';
                        final name = artefakt['name'] as String? ?? 'Unbekannt';
                        final location = artefakt['location'] as String? ?? 'Unbekannt';
                        final description = artefakt['description'] as String? ?? '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFFFB300),
                              child: Text(
                                username[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(location, style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                if (description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  'Gesammelt von $username',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.museum, color: Color(0xFFFFB300)),
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
