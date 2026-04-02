import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../../services/group_tools_service.dart';
import '../../services/user_service.dart'; // 🆕 User Service für Auth

/// 🏛️ GESCHICHTE-ZEITLEISTE SCREEN
/// Alternative Geschichte gemeinsam dokumentieren
class HistoryTimelineScreen extends StatefulWidget {
  final String roomId;
  
  const HistoryTimelineScreen({
    super.key,
    required this.roomId,
  });

  @override
  State<HistoryTimelineScreen> createState() => _HistoryTimelineScreenState();
}

class _HistoryTimelineScreenState extends State<HistoryTimelineScreen> {
  final GroupToolsService _toolsService = GroupToolsService();
  
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = false;
  String _selectedCategory = 'all';
  
  final Map<String, dynamic> _categories = {
    'all': {'name': 'Alle', 'color': Colors.white, 'icon': '📜'},
    'tartaria': {'name': 'Tartaria', 'color': Colors.amber, 'icon': '🏛️'},
    'ancient': {'name': 'Antike Hochkulturen', 'color': Colors.orange, 'icon': '⚱️'},
    'mudflood': {'name': 'Mud Flood', 'color': Colors.brown, 'icon': '🌊'},
    'reset': {'name': 'Zivilisations-Reset', 'color': Colors.red, 'icon': '🔄'},
    'artifacts': {'name': 'Unerklärliche Artefakte', 'color': Colors.purple, 'icon': '🗿'},
    'technology': {'name': 'Verlorene Technologie', 'color': Colors.blue, 'icon': '⚙️'},
  };
  
  @override
  void initState() {
    super.initState();
    _loadEvents();
  }
  
  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await _toolsService.getHistoryEvents(roomId: widget.roomId);
      if (mounted) {
        setState(() {
          _events = events;
          // Sort by year
          _events.sort((a, b) => (a['event_year'] ?? 0).compareTo(b['event_year'] ?? 0));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final yearController = TextEditingController();
    String selectedCategory = 'tartaria';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('📜 Historisches Ereignis hinzufügen', style: TextStyle(color: Colors.amber)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Ereignis-Titel',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintText: 'z.B. Tartaria Hauptstadt entdeckt',
                    hintStyle: TextStyle(color: Colors.white30),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: yearController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Jahr (negativ für v. Chr.)',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintText: 'z.B. -10000 oder 1850',
                    hintStyle: TextStyle(color: Colors.white30),
                  ),
                ),
                const SizedBox(height: 16),
                
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Kategorie:', style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 8),
                
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.entries.where((e) => e.key != 'all').map((entry) {
                    final cat = entry.key;
                    final data = entry.value;
                    final isSelected = selectedCategory == cat;
                    
                    return InkWell(
                      onTap: () {
                        setDialogState(() => selectedCategory = cat);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? data['color'].withValues(alpha: 0.3) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? data['color'] : Colors.grey[700]!,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(data['icon'], style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Text(
                              data['name'],
                              style: TextStyle(
                                color: isSelected ? data['color'] : Colors.white70,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Beschreibung',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintText: 'Detaillierte Beschreibung des Ereignisses...',
                    hintStyle: TextStyle(color: Colors.white30),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bitte Titel eingeben'), backgroundColor: Colors.red),
                  );
                  return;
                }
                
                Navigator.pop(context);
                await _addEvent(
                  title: titleController.text.trim(),
                  description: descController.text.trim(),
                  year: int.tryParse(yearController.text.trim()) ?? 0,
                  category: selectedCategory,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: const Text('Hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _addEvent({
    required String title,
    required String description,
    required int year,
    required String category,
  }) async {
    try {
      await _toolsService.createHistoryEvent(
        roomId: widget.roomId,
        userId: UserService.getCurrentUserId(),
        username: 'Manuel',
        title: title,
        description: description,
        eventYear: year,
        category: category,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Ereignis hinzugefügt!'), backgroundColor: Colors.green),
      );
      
      await _loadEvents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Fehler: $e'), backgroundColor: Colors.red),
      );
    }
  }
  
  List<Map<String, dynamic>> get _filteredEvents {
    if (_selectedCategory == 'all') return _events;
    return _events.where((e) => e['category'] == _selectedCategory).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    final filteredEvents = _filteredEvents;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text('🏛️ Geschichte-Zeitleiste'),
        backgroundColor: const Color(0xFF1B263B),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          Container(
            height: 60,
            color: const Color(0xFF1A1A2E),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              children: _categories.entries.map((entry) {
                final cat = entry.key;
                final data = entry.value;
                final isSelected = _selectedCategory == cat;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? data['color'].withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? data['color'] : Colors.grey[700]!,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(data['icon'], style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            data['name'],
                            style: TextStyle(
                              color: isSelected ? data['color'] : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Timeline
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                : filteredEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.history_edu, size: 64, color: Colors.white24),
                            const SizedBox(height: 16),
                            const Text(
                              'Keine Ereignisse vorhanden',
                              style: TextStyle(color: Colors.white54, fontSize: 16),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _showAddEventDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Erstes Ereignis hinzufügen'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredEvents.length,
                        cacheExtent: 200.0, // 🚀 PHASE B: Pre-render 200px ahead
                        addAutomaticKeepAlives: false, // 🚀 PHASE B: Memory optimization
                        addRepaintBoundaries: true, // 🚀 PHASE B: Isolate repaints
                        itemBuilder: (context, index) {
                          final event = filteredEvents[index];
                          final category = event['category'] ?? 'ancient';
                          final catData = _categories[category] ?? _categories['ancient']!;
                          final year = event['event_year'] ?? 0;
                          final yearString = year < 0 ? '${year.abs()} v. Chr.' : '$year n. Chr.';
                          
                          // 🚀 PHASE B: RepaintBoundary + ValueKey for performance
                          return RepaintBoundary(
                            key: ValueKey(event['event_id']),
                            child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Timeline indicator
                                Column(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: catData['color'].withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: catData['color'], width: 2),
                                      ),
                                      child: Center(
                                        child: Text(catData['icon'], style: const TextStyle(fontSize: 20)),
                                      ),
                                    ),
                                    if (index < filteredEvents.length - 1)
                                      Container(
                                        width: 2,
                                        height: 60,
                                        color: Colors.white24,
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                
                                // Event card
                                Expanded(
                                  child: Card(
                                    color: const Color(0xFF1A1A2E),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: catData['color'].withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  yearString,
                                                  style: TextStyle(
                                                    color: catData['color'],
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                catData['name'],
                                                style: TextStyle(
                                                  color: catData['color'],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          
                                          Text(
                                            event['event_title'] ?? 'Unbekanntes Ereignis',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          
                                          Text(
                                            event['event_description'] ?? '',
                                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                                          ),
                                          const SizedBox(height: 12),
                                          
                                          Row(
                                            children: [
                                              const Icon(Icons.person, size: 14, color: Colors.blue),
                                              const SizedBox(width: 4),
                                              Text(
                                                event['username'] ?? 'Unbekannt',
                                                style: const TextStyle(color: Colors.blue, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ), // 🚀 PHASE B: End of RepaintBoundary
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEventDialog,
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Ereignis'),
      ),
    );
  }

  @override
  void dispose() {
    // 🧹 PHASE B: Proper resource disposal
    super.dispose();
  }
}
