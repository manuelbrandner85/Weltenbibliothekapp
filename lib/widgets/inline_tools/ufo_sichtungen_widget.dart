import 'package:flutter/material.dart';
import 'dart:async';
import 'package:weltenbibliothek/services/tool_api_service.dart';

/// UFO-SICHTUNGS-MELDER - Kollaboratives Tool für UFO-Chat
class UfoSichtungenWidget extends StatefulWidget {
  final String roomId;
  
  const UfoSichtungenWidget({
    super.key,
    required this.roomId,
  });

  @override
  State<UfoSichtungenWidget> createState() => _UfoSichtungenWidgetState();
}

class _UfoSichtungenWidgetState extends State<UfoSichtungenWidget> {
  final _apiService = ToolApiService();
  List<Map<String, dynamic>> _sichtungen = [];
  bool _isLoading = false;
  Timer? _pollTimer;
  
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _verified = 'unverified';
  
  @override
  void initState() {
    super.initState();
    _loadSichtungen();
    // Echtzeit-Updates alle 10 Sekunden
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadSichtungen();
    });
  }
  
  @override
  void dispose() {
    _pollTimer?.cancel();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSichtungen() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final data = await _apiService.getToolData(
        endpoint: '/api/tools/ufo-sichtungen',
        roomId: widget.roomId,
      );
      
      setState(() {
        _sichtungen = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e')),
        );
      }
    }
  }
  
  Future<void> _addSichtung() async {
    if (_locationController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Ort und Beschreibung eingeben')),
      );
      return;
    }
    
    try {
      await _apiService.postToolData(
        endpoint: '/api/tools/ufo-sichtungen',
        data: {
          'room_id': widget.roomId,
          'location': _locationController.text,
          'description': _descriptionController.text,
          'verified': _verified,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      _locationController.clear();
      _descriptionController.clear();
      _verified = 'unverified';
      
      await _loadSichtungen();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('UFO-Sichtung hinzugefügt!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          bottom: BorderSide(color: Colors.green.withValues(alpha: 0.3), width: 2),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[800]!, Colors.green[900]!],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.explore, color: Colors.greenAccent, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '🛸 UFO-SICHTUNGS-MELDER',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_sichtungen.length} Sichtungen',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
          // Quick Add Form
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _locationController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Ort (z.B. Berlin, 52.52°N 13.40°E)',
                          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _verified,
                        dropdownColor: Colors.grey[850],
                        underline: Container(),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        items: const [
                          DropdownMenuItem(value: 'unverified', child: Text('❓ Ungeprüft')),
                          DropdownMenuItem(value: 'verified', child: Text('✅ Verifiziert')),
                          DropdownMenuItem(value: 'debunked', child: Text('❌ Widerlegt')),
                        ],
                        onChanged: (value) => setState(() => _verified = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _descriptionController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Beschreibung (Form, Größe, Verhalten...)',
                          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addSichtung,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.add, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Sichtungen Liste
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: _isLoading && _sichtungen.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
                : _sichtungen.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Noch keine UFO-Sichtungen gemeldet.\nSei der Erste!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _sichtungen.length,
                        itemBuilder: (context, index) {
                          final sichtung = _sichtungen[index];
                          final verified = sichtung['verified'] ?? 'unverified';
                          final verifiedIcon = verified == 'verified' 
                              ? '✅' 
                              : verified == 'debunked' 
                                  ? '❌' 
                                  : '❓';
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[850],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.greenAccent.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      verifiedIcon,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        sichtung['location'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.greenAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatTime(sichtung['created_at']),
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  sichtung['description'] ?? '',
                                  style: TextStyle(color: Colors.grey[300], fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
    final now = DateTime.now();
    final diff = now.difference(dt);
    
    if (diff.inMinutes < 1) return 'Jetzt';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'vor ${diff.inHours}h';
    return 'vor ${diff.inDays}d';
  }
}
