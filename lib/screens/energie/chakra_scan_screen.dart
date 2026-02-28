import 'package:flutter/material.dart';
import '../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'dart:convert';
import '../../services/group_tools_service.dart';
import '../../services/user_service.dart';

/// 💎 Chakra Scan Screen
/// Gegenseitige Energie-Analysen & Chakra-Status
class ChakraScanScreen extends StatefulWidget {
  final String roomId;
  
  const ChakraScanScreen({
    super.key,
    this.roomId = 'chakra',
  });

  @override
  State<ChakraScanScreen> createState() => _ChakraScanScreenState();
}

class _ChakraScanScreenState extends State<ChakraScanScreen> {
  final GroupToolsService _toolsService = GroupToolsService();
  final UserService _userService = UserService();
  
  List<Map<String, dynamic>> _scans = [];
  bool _isLoading = false;
  String _username = '';
  String _userId = '';
  String? _errorMessage;
  
  // Chakra States: offen, ausgeglichen, blockiert
  // TODO: Use _chakraStates for real-time chakra state tracking
  /*
  final Map<String, String> _chakraStates = {
    'Wurzel': 'ausgeglichen',
    'Sakral': 'ausgeglichen',
    'Solarplexus': 'ausgeglichen',
    'Herz': 'ausgeglichen',
    'Hals': 'ausgeglichen',
    'Stirn': 'ausgeglichen',
    'Krone': 'ausgeglichen',
  };
  */
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadScans();
  }
  
  Future<void> _loadUserData() async {
    final user = await _userService.getCurrentUser();
    setState(() {
      _username = user.username;
      _userId = 'user_${user.username.toLowerCase()}';
    });
  }
  
  Future<void> _loadScans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final scans = await _toolsService.getChakraScans(
        roomId: widget.roomId,
        limit: 50,
      );
      
      if (kDebugMode) {
        debugPrint('💎 Loaded ${scans.length} scans');
      }
      
      setState(() {
        _scans = scans;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading scans: $e');
      }
      setState(() {
        _errorMessage = 'Fehler beim Laden: $e';
        _isLoading = false;
      });
    }
  }
  
  void _startSelfScan() {
    if (_username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Bitte erstelle erst ein Profil'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => _ChakraScanDialog(
        username: _username,
        userId: _userId,
        roomId: widget.roomId,
        onScanComplete: (scanData) async {
          // Save scan
          final scanId = await _toolsService.createChakraScan(
            roomId: widget.roomId,
            scannedUserId: _userId,
            scannedUsername: _username,
            scannerUserId: _userId,
            scannerUsername: _username,
            scanData: scanData,
            blockages: _findBlockages(scanData),
          );
          
          if (scanId != null) {
            _loadScans();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Chakra-Scan gespeichert!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        },
      ),
    );
  }
  
  List<String> _findBlockages(Map<String, dynamic> scanData) {
    final blockages = <String>[];
    scanData.forEach((chakra, state) {
      if (state == 'blockiert') {
        blockages.add('$chakra-Chakra: Blockiert');
      }
    });
    return blockages;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('💎 Chakra Scan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadScans(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Scan Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4A148C).withValues(alpha: 0.3),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: ElevatedButton.icon(
              onPressed: _startSelfScan,
              icon: const Icon(Icons.center_focus_strong, size: 28),
              label: const Text('Selbst-Scan starten', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          
          // Scans List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white)))
                    : _scans.isEmpty
                        ? const Center(
                            child: Text(
                              'Noch keine Scans',
                              style: TextStyle(color: Colors.white38),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _scans.length,
                            itemBuilder: (context, index) {
                              return _buildScanCard(_scans[index]);
                            },
                          ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScanCard(Map<String, dynamic> scan) {
    final scannedUsername = scan['scanned_username'] ?? 'Anonym';
    final scannerUsername = scan['scanner_username'] ?? 'Anonym';
    
    // Parse scan data
    Map<String, dynamic> scanData = {};
    try {
      final dataJson = scan['scan_data'];
      if (dataJson is String && dataJson.isNotEmpty) {
        scanData = Map<String, dynamic>.from(jsonDecode(dataJson));
      } else if (dataJson is Map) {
        scanData = Map<String, dynamic>.from(dataJson);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error parsing scan_data: $e');
      }
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                Text(
                  scannedUsername,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Text('←', style: TextStyle(color: Colors.white38)),
                const SizedBox(width: 8),
                Text(
                  scannerUsername,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: scanData.entries.map((entry) {
                final color = entry.value == 'blockiert' 
                    ? Colors.red 
                    : entry.value == 'offen' 
                        ? Colors.green 
                        : Colors.blue;
                return Chip(
                  label: Text('${entry.key}: ${entry.value}'),
                  backgroundColor: color.withValues(alpha: 0.2),
                  labelStyle: TextStyle(color: color, fontSize: 12),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// Chakra Scan Dialog
class _ChakraScanDialog extends StatefulWidget {
  final String username;
  final String userId;
  final String roomId;
  final Function(Map<String, dynamic>) onScanComplete;
  
  const _ChakraScanDialog({
    required this.username,
    required this.userId,
    required this.roomId,
    required this.onScanComplete,
  });

  @override
  State<_ChakraScanDialog> createState() => _ChakraScanDialogState();
}

class _ChakraScanDialogState extends State<_ChakraScanDialog> {
  final Map<String, String> _chakraStates = {
    'Wurzel': 'ausgeglichen',
    'Sakral': 'ausgeglichen',
    'Solarplexus': 'ausgeglichen',
    'Herz': 'ausgeglichen',
    'Hals': 'ausgeglichen',
    'Stirn': 'ausgeglichen',
    'Krone': 'ausgeglichen',
  };
  
  final Map<String, Color> _chakraColors = {
    'Wurzel': Colors.red,
    'Sakral': Colors.orange,
    'Solarplexus': Colors.yellow,
    'Herz': Colors.green,
    'Hals': Colors.blue,
    'Stirn': Colors.indigo,
    'Krone': Colors.purple,
  };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '💎 Chakra-Status wählen',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ..._chakraStates.keys.map((chakra) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _chakraColors[chakra],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$chakra-Chakra',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'blockiert', label: Text('Blockiert')),
                          ButtonSegment(value: 'ausgeglichen', label: Text('Ausgegl.')),
                          ButtonSegment(value: 'offen', label: Text('Offen')),
                        ],
                        selected: {_chakraStates[chakra]!},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _chakraStates[chakra] = newSelection.first;
                          });
                        },
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Abbrechen'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      widget.onScanComplete(_chakraStates);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C27B0)),
                    child: const Text('Speichern'),
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
