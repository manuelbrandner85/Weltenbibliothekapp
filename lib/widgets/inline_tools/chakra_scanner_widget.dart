import 'package:flutter/material.dart';
import 'dart:async';
import 'package:weltenbibliothek/services/tool_api_service.dart';

class ChakraScannerWidget extends StatefulWidget {
  final String roomId;
  const ChakraScannerWidget({super.key, required this.roomId});
  @override
  State<ChakraScannerWidget> createState() => _ChakraScannerWidgetState();
}

class _ChakraScannerWidgetState extends State<ChakraScannerWidget> {
  final _apiService = ToolApiService();
  List<Map<String, dynamic>> _readings = [];
  bool _isLoading = false;
  Timer? _pollTimer;
  String _selectedChakra = 'Wurzelchakra';
  final _notesController = TextEditingController();
  
  final List<String> _chakras = [
    'Wurzelchakra',
    'Sakralchakra',
    'Solarplexuschakra',
    'Herzchakra',
    'Halschakra',
    'Stirnchakra',
    'Kronenchakra',
  ];
  
  @override
  void initState() {
    super.initState();
    _loadReadings();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadReadings());
  }
  
  @override
  void dispose() {
    _pollTimer?.cancel();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _loadReadings() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getToolData(
        endpoint: '/api/tools/chakra-readings',
        roomId: widget.roomId,
      );
      setState(() {
        _readings = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _addReading() async {
    try {
      await _apiService.postToolData(
        endpoint: '/api/tools/chakra-readings',
        data: {
          'room_id': widget.roomId,
          'chakra': _selectedChakra,
          'notes': _notesController.text,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
      );
      _notesController.clear();
      await _loadReadings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chakra-Reading gespeichert!')),
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
  
  Color _getChakraColor(String chakra) {
    switch (chakra) {
      case 'Wurzelchakra': return Colors.red;
      case 'Sakralchakra': return Colors.orange;
      case 'Solarplexuschakra': return Colors.yellow;
      case 'Herzchakra': return Colors.green;
      case 'Halschakra': return Colors.blue;
      case 'Stirnchakra': return Colors.indigo;
      case 'Kronenchakra': return Colors.purple;
      default: return Colors.white;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          bottom: BorderSide(color: Colors.purple.withValues(alpha: 0.3), width: 2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[800]!, Colors.purple[900]!],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.brightness_1, color: Colors.purpleAccent, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '🌈 CHAKRA-SCANNER',
                  style: TextStyle(
                    color: Colors.purpleAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_readings.length} Readings',
                    style: const TextStyle(color: Colors.purpleAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedChakra,
                    isExpanded: true,
                    dropdownColor: Colors.grey[850],
                    underline: Container(),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: _chakras.map((chakra) {
                      return DropdownMenuItem(
                        value: chakra,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getChakraColor(chakra),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(chakra),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedChakra = value!),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _notesController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Notizen (Gefühle, Empfindungen...)',
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
                      onPressed: _addReading,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
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
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: _isLoading && _readings.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
                : _readings.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Noch keine Chakra-Readings.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _readings.length,
                        itemBuilder: (context, index) {
                          final reading = _readings[index];
                          final chakra = reading['chakra'] ?? '';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[850],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getChakraColor(chakra).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _getChakraColor(chakra),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      chakra,
                                      style: TextStyle(
                                        color: _getChakraColor(chakra),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                if (reading['notes'] != null && (reading['notes'] as String).isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    reading['notes'],
                                    style: TextStyle(color: Colors.grey[300], fontSize: 12),
                                  ),
                                ],
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
}
