import 'package:flutter/material.dart';
 // OpenClaw v2.0
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../../services/group_tools_service.dart';
import '../../services/user_service.dart';

/// 💫 Traum-Tagebuch Screen
/// Träume dokumentieren & gemeinsam analysieren
class DreamJournalScreen extends StatefulWidget {
  final String roomId;
  
  const DreamJournalScreen({
    super.key,
    this.roomId = 'traumarbeit',
  });

  @override
  State<DreamJournalScreen> createState() => _DreamJournalScreenState();
}

class _DreamJournalScreenState extends State<DreamJournalScreen> {
  final GroupToolsService _toolsService = GroupToolsService();
  final UserService _userService = UserService();
  
  List<Map<String, dynamic>> _dreams = [];
  bool _isLoading = false;
  String _username = '';
  String _userId = '';
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadDreams();
  }
  
  Future<void> _loadUserData() async {
    final user = await _userService.getCurrentUser();
    setState(() {
      _username = user.username;
      _userId = 'user_${user.username.toLowerCase()}';
    });
  }
  
  Future<void> _loadDreams() async {
    setState(() => _isLoading = true);
    try {
      final dreams = await _toolsService.getDreams(roomId: widget.roomId);
      setState(() {
        _dreams = dreams;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('💫 Traum-Tagebuch'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDreams),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dreams.isEmpty
              ? const Center(child: Text('Noch keine Träume', style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _dreams.length,
                  itemBuilder: (context, index) {
                    final dream = _dreams[index];
                    final title = dream['dream_title'] ?? '';
                    final lucid = dream['lucid'] == 1 || dream['lucid'] == true;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: const Color(0xFF1A1A2E),
                      child: ListTile(
                        leading: Icon(
                          lucid ? Icons.wb_twilight : Icons.bedtime,
                          color: lucid ? Colors.amber : Colors.purple,
                        ),
                        title: Text(title, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          lucid ? 'Luzider Traum' : 'Normaler Traum',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (_username.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('⚠️ Bitte erstelle erst ein Profil')),
            );
            return;
          }
          // Controller außerhalb showDialog → try/finally garantiert dispose
          final titleCtrl = TextEditingController();
          final descCtrl = TextEditingController();
          bool result = false;
          try {
            result = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    bool isLucid = false;
                    return StatefulBuilder(
                      builder: (context, setLocalState) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A2E),
                        title: const Text('💫 Traum hinzufügen',
                            style: TextStyle(color: Colors.white)),
                        content: Column(
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
                            CheckboxListTile(
                              title: const Text('Luzider Traum',
                                  style: TextStyle(color: Colors.white)),
                              value: isLucid,
                              onChanged: (val) =>
                                  setLocalState(() => isLucid = val ?? false),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Abbrechen'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final dreamId = await _toolsService.createDream(
                                roomId: widget.roomId,
                                userId: _userId,
                                username: _username,
                                title: titleCtrl.text,
                                description: descCtrl.text,
                                lucid: isLucid,
                              );
                              if (context.mounted) {
                                Navigator.pop(context, dreamId != null);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9C27B0)),
                            child: const Text('Hinzufügen'),
                          ),
                        ],
                      ),
                    );
                  },
                ) ??
                false;
          } finally {
            titleCtrl.dispose();
            descCtrl.dispose();
          }
          if (result) _loadDreams();
        },
        backgroundColor: const Color(0xFF9C27B0),
        icon: const Icon(Icons.add),
        label: const Text('Traum hinzufügen'),
      ),
    );
  }

  @override
  void dispose() {
    // 🧹 PHASE B: Proper resource disposal
    super.dispose();
  }

}
