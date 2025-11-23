import 'package:flutter/material.dart';
import 'dart:async';
import '../services/live_room_service.dart';
import '../services/auth_service.dart';
import 'live_stream_host_screen.dart';
import 'live_stream_viewer_screen.dart';

/// ═══════════════════════════════════════════════════════════════
/// LIVE STREAMS OVERVIEW SCREEN - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// Zeigt alle aktiven Live-Streams aus der D1-Datenbank
/// Features:
/// - Grid/List-Ansicht mit Live-Indikator
/// - Teilnehmerzahl in Echtzeit
/// - Auto-Refresh alle 10 Sekunden
/// - Join-Funktionalität
/// - Host-Badge für eigene Streams
/// ═══════════════════════════════════════════════════════════════

class LiveStreamsScreen extends StatefulWidget {
  const LiveStreamsScreen({super.key});

  @override
  State<LiveStreamsScreen> createState() => _LiveStreamsScreenState();
}

class _LiveStreamsScreenState extends State<LiveStreamsScreen> {
  final LiveRoomService _liveRoomService = LiveRoomService();
  final AuthService _authService = AuthService();

  List<LiveRoom> _liveRooms = [];
  bool _isLoading = true;
  String? _error;
  String? _currentUsername;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadLiveRooms();

    // Auto-Refresh alle 10 Sekunden
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadLiveRooms(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUsername = user['username'] as String?;
      });
    }
  }

  Future<void> _loadLiveRooms({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final rooms = await _liveRoomService.getActiveLiveRooms();

      if (mounted) {
        setState(() {
          _liveRooms = rooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Fehler beim Laden der Live-Streams: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createNewStream() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'mystery';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Neuer Live-Stream',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Titel',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF8B5CF6)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF8B5CF6)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setDialogState) =>
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Kategorie',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF8B5CF6)),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'mystery',
                          child: Text('🔮 Mystery'),
                        ),
                        DropdownMenuItem(
                          value: 'archaeology',
                          child: Text('🏛️ Archäologie'),
                        ),
                        DropdownMenuItem(
                          value: 'energy',
                          child: Text('⚡ Energie'),
                        ),
                        DropdownMenuItem(
                          value: 'phenomenon',
                          child: Text('❓ Phänomen'),
                        ),
                        DropdownMenuItem(
                          value: 'general',
                          child: Text('📚 Allgemein'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategory = value!;
                        });
                      },
                    ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Abbrechen',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
            ),
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );

    if (result == true && titleController.text.trim().isNotEmpty) {
      _showLoadingDialog();

      final createResult = await _liveRoomService.createLiveRoom(
        chatRoomId:
            'general_livestream', // General livestream room (not chat-specific)
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        category: selectedCategory,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (createResult['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Live-Stream erfolgreich erstellt!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          _loadLiveRooms();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${createResult['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> _joinStream(LiveRoom room) async {
    final isHost =
        _currentUsername != null && room.hostUsername == _currentUsername;

    if (isHost) {
      // Host startet Live-Stream mit WebRTC
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LiveStreamHostScreen(
            roomId: room.roomId,
            chatRoomId: room.chatRoomId ?? room.roomId,
            roomTitle: room.title,
          ),
        ),
      ).then((_) => _loadLiveRooms());
    } else {
      // Viewer tritt Live-Stream bei
      _showLoadingDialog();

      final result = await _liveRoomService.joinLiveRoom(room.roomId);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (result['success'] == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LiveStreamViewerScreen(
                roomId: room.roomId,
                chatRoomId: room.chatRoomId ?? room.roomId,
                roomTitle: room.title,
                hostUsername: room.hostUsername,
              ),
            ),
          ).then((_) => _loadLiveRooms());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _endStream(LiveRoom room) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Stream beenden?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Möchtest du den Stream "${room.title}" wirklich beenden?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Abbrechen',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Beenden'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _showLoadingDialog();

      final result = await _liveRoomService.endLiveRoom(room.roomId);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Stream erfolgreich beendet'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          _loadLiveRooms();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text('🔴 Live-Streams'),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadLiveRooms(),
            tooltip: 'Aktualisieren',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewStream,
        backgroundColor: const Color(0xFF8B5CF6),
        icon: const Icon(Icons.videocam),
        label: const Text('Neuer Stream'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _liveRooms.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
      );
    }

    if (_error != null && _liveRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadLiveRooms(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
              ),
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    if (_liveRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Keine aktiven Live-Streams',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Erstelle den ersten Stream!',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadLiveRooms(),
      color: const Color(0xFF8B5CF6),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _liveRooms.length,
        itemBuilder: (context, index) {
          return _buildStreamCard(_liveRooms[index]);
        },
      ),
    );
  }

  Widget _buildStreamCard(LiveRoom room) {
    final isHost =
        _currentUsername != null && room.hostUsername == _currentUsername;
    final categoryColor = _getCategoryColor(room.category ?? 'general');

    return Card(
      color: const Color(0xFF1E293B),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: room.isLive ? Colors.red : Colors.white.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _joinStream(room),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header mit LIVE-Indikator
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    categoryColor.withValues(alpha: 0.7),
                    categoryColor.withValues(alpha: 0.4),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // LIVE Badge
                  if (room.isLive)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 8, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Host Badge
                  if (isHost)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HOST',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Teilnehmerzahl
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${room.participantCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titel
                    Text(
                      room.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Host
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 12,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            room.hostUsername,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isHost
                            ? () => _endStream(room)
                            : () => _joinStream(room),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isHost
                              ? Colors.red
                              : const Color(0xFF8B5CF6),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(
                          isHost ? 'Beenden' : 'Beitreten',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'archaeology':
        return const Color(0xFFF59E0B); // Gold
      case 'mystery':
        return const Color(0xFF8B5CF6); // Violet
      case 'energy':
        return const Color(0xFF10B981); // Green
      case 'phenomenon':
        return const Color(0xFF06B6D4); // Cyan
      default:
        return const Color(0xFF8B5CF6); // Default Violet
    }
  }
}
