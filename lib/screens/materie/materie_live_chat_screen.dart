import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart'; // 🗄️ HIVE für Profile
import '../../services/supabase_service.dart'; // 🔥 supabase Auth
import 'package:supabase_flutter/supabase_flutter.dart' show RealtimeChannel;
import '../../services/cloudflare_api_service.dart';
import '../../services/chat_notification_service.dart'; // 🔔 NOTIFICATIONS
import '../../services/user_service.dart'; // 🆕 User Service für Auth
import '../../widgets/mention_autocomplete.dart'; // @ MENTIONS
import 'package:image_picker/image_picker.dart'; // 📷 Image Picker
// 👤 PROFIL
import '../../services/storage_service.dart'; // StorageService for profile access
import '../../core/storage/unified_storage_service.dart'; // UnifiedStorageService sync
import '../../models/materie_profile.dart'; // MaterieProfile model
import '../../services/profile_sync_service.dart'; // ProfileSyncService
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod
// 🔥 BACKEND SYNC
// import '../../services/voice_message_service_export.dart'; // 🎙️ VOICE MESSAGE (Disabled for Android)
// import '../../widgets/voice_record_button.dart'; // 🎙️ VOICE RECORD BUTTON (Disabled for Android)
import '../../services/webrtc_voice_service.dart'; // 🎤 WEBRTC VOICE
// REMOVED: import '../../widgets/voice_chat_banner.dart'; (unused)
import '../../widgets/voice/voice_participant_header_bar.dart'; // 🎤 Voice Participant Header Bar
import '../../widgets/offline_indicator.dart'; // 📡 OFFLINE INDICATOR (NEW Phase 3)
// 👤 MATERIE PROFIL MODEL
import '../shared/profile_editor_screen.dart'; // ✅ Profile Editor
import '../../services/moderation_service.dart'; // 🔧 ADMIN MODERATION
import '../../services/admin_permissions.dart'; // 🔐 ADMIN SYSTEM
import '../../widgets/error_display_widget.dart'; // 🎨 ERROR DISPLAY (NEW)
// 💬 Enhanced Message Bubble  
import '../../widgets/message_reactions_widget.dart'; // 😀 Message Reactions
import '../../widgets/message_edit_widget.dart'; // ✏️ Message Edit
// 🗑️ Message Delete
import '../../widgets/message_search_widget.dart'; // 🔍 Message Search
import '../../widgets/poll_widget.dart'; // 🗳️ Poll Widget
import '../../widgets/pinned_message_banner.dart'; // 📌 Pinned Message Banner

import '../shared/modern_voice_chat_screen.dart'; // 🎤 Modern Voice Chat Screen (Phase B)
import '../shared/video_voice_chat_screen.dart'; // 🎥 Video + Voice Chat (Telegram-Style)
import '../../providers/webrtc_call_provider.dart'; // Riverpod provider
// 🎤 Admin Dialogs & Notifications
// 🚫 Kick User Dialog
// 🔴 Ban User Dialog
// ⚠️ Warning Dialog
// 📢 Admin Notifications
// 📋 Admin Action Models
// 🎤 Voice Player Widget
import '../../widgets/android_voice_recorder.dart'; // 🎤 Android Voice Recorder (flutter_sound)
// import '../../widgets/telegram_voice_recorder.dart'; // 🎙️ Telegram Voice Recorder (Disabled for Android)
// 🎵 Telegram Voice Player
import '../../widgets/voice_message_player.dart' show ChatVoicePlayer; // 🎤 Chat Voice Player (New)
import 'ufo_sightings_screen.dart'; // 🛸 UFO-Sichtungen
import 'history_timeline_screen.dart'; // 🏛️ Geschichte-Zeitleiste
import 'geopolitik_map_screen.dart'; // 🎭 Geopolitik-Kartierung
import 'conspiracy_network_screen.dart'; // 👁️ Verbindungsnetz
import 'research_archive_screen.dart'; // 🔬 Forschungs-Archiv
import 'alternative_healing_screen.dart'; // 💚 Alternative Gesundheit
// ✨ Batch-1 Chat-Erweiterungen
import '../../widgets/chat/chat_markdown_text.dart';
import '../../widgets/chat/chat_emoji_picker_button.dart';
import '../../widgets/chat/chat_status_banner.dart';
import '../../widgets/chat/chat_new_messages_fab.dart';
import '../../widgets/chat/chat_unread_badge.dart';
import '../../widgets/chat/chat_online_indicator.dart';
import '../../widgets/chat/chat_room_info_sheet.dart';
import '../../widgets/chat/chat_read_receipt_indicator.dart';
import '../../widgets/chat/chat_link_preview_card.dart';
import '../../services/chat/presence_service.dart';
import '../../services/chat/read_receipt_service.dart';
import '../../services/chat/link_preview_service.dart';
import '../../services/chat/chat_rate_limit_service.dart';
import '../../services/chat/chat_word_filter_service.dart';
import '../../services/chat/chat_draft_service.dart';
import '../../services/chat/user_block_service.dart';
import '../../services/chat/unread_tracker_service.dart';

/// MATERIE-WELT LIVE-CHAT - Cloudflare Edition
class MaterieLiveChatScreen extends StatefulWidget {
  final String? initialRoom;
  
  const MaterieLiveChatScreen({super.key, this.initialRoom});

  @override
  State<MaterieLiveChatScreen> createState() => _MaterieLiveChatScreenState();
}

class _MaterieLiveChatScreenState extends State<MaterieLiveChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final CloudflareApiService _api = CloudflareApiService();
  final ScrollController _scrollController = ScrollController();
  final ChatNotificationService _notificationService = ChatNotificationService(); // 🔔 NEW
  RealtimeChannel? _realtimeChannel; // 🔴 Supabase Realtime
  
  late String _selectedRoom;
  
  /// Maps internal room key → DB room ID (materie world)
  static const Map<String, String> _roomIdMap = {
    'politik': 'materie-politik',
    'geschichte': 'materie-geschichte',
    'ufo': 'materie-ufo',
    'ufos': 'materie-ufo',
    'verschwoerungen': 'materie-verschwoerung',
    'verschwoerung': 'materie-verschwoerung',
    'wissenschaft': 'materie-wissenschaft',
    'technologie': 'materie-tech',
    'tech': 'materie-tech',
    'gesundheit': 'materie-gesundheit',
    'medien': 'materie-medien',
    'finanzen': 'materie-finanzen',
  };
  
  /// Returns the full DB room ID for the currently selected room.
  String get _fullRoomId => _roomIdMap[_selectedRoom] ?? 'materie-$_selectedRoom';
  String _username = ''; // ✅ Leer bis Profil geladen – isOwn-Check + Profil-Dialog funktionieren korrekt
  late String _userId; // 🔥 Real User ID from UserService (initialized in initState)
  String _avatar = '👤'; // 🆕 Avatar Emoji (default)
  String? _avatarEmoji; // 🆕 Avatar Emoji aus Profil
  String? _avatarUrl; // 🆕 Avatar URL aus Profil
  
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _polls = []; // 🗳️ POLLS
  bool _isLoading = false;
  String? _errorMessage; // 🎨 NEW: Error state
  bool _profileDialogShown = false; // 🚨 Flag: Verhindert mehrfaches Popup
  Timer? _refreshTimer;
  
  // 🆕 ENHANCED FEATURES
  List<String> _mentionSuggestions = []; // @ Auto-Complete
  bool _showMentionPicker = false;
  
  // 🎙️ VOICE RECORDING
  // UNUSED FIELD: bool _isRecordingVoice = false;
  // UNUSED FIELD: Duration _recordingDuration = Duration.zero;
  // UNUSED FIELD: Timer? _recordingTimer;
  final FocusNode _inputFocusNode = FocusNode(); // Input Focus
  bool _isInputFocused = false; // 🔧 FIX 10: Explicit focus state
  
  // 🎤➤ DYNAMIC BUTTON STATE
  bool _hasText = false; // true = Send Button, false = Voice Button
  
  // 🆕 FEATURE 1: WEBRTC VOICE ROOM
  bool _isInVoiceRoom = false;
  bool _isMuted = false;
  List<Map<String, dynamic>> _voiceParticipants = [];
  
  // 🆕 ADMIN ACTION SERVICE
  
  // 🆕 FEATURE 2: TYPING INDICATORS (local state only — broadcast TBD via Supabase)
  final Set<String> _typingUsers = {};
  
  // 🆕 FEATURE 3: SWIPE TO REPLY
  Map<String, dynamic>? _replyingTo;
  
  // 🆕 PHASE 2: MESSAGE EDIT/DELETE/SEARCH
  String? _editingMessageId;
  bool _showSearch = false;
  
  // 🆕 FEATURE 4: EMOJI REACTIONS
  // ignore: unused_field
  final Map<String, Map<String, List<String>>> _messageReactions = {}; // messageId -> emoji -> userIds

  // ✨ Batch-1: Smart autoscroll + pagination + reconnect-state
  bool _isAtBottom = true;
  int _newMessagesCount = 0;
  bool _loadingOlder = false;
  bool _hasMoreOlder = true;
  bool _reconnecting = false;

  // 🔧 FIX 16: MATERIE Räume - API-kompatible IDs (Verschwörungstheorien-Themen)
  final Map<String, Map<String, dynamic>> _materieRooms = {
    'politik': {
      'name': '🎭 Geopolitik & Weltordnung',
      'description': 'Weltpolitik, geheime Agenden, Neue Weltordnung',
      'color': Colors.red,
      'icon': '🎭',
      'tool': 'Weltpolitik-Kartierung',
      'toolDescription': 'Gemeinsam politische Ereignisse & Verbindungen visualisieren',
    },
    'geschichte': {
      'name': '🏛️ Alternative Geschichte',
      'description': 'Verborgene Geschichte, antike Hochkulturen, Tartaria',
      'color': Colors.amber,
      'icon': '🏛️',
      'tool': 'Zeitleiste (Shared)',
      'toolDescription': 'Gemeinsame alternative Geschichts-Timeline erstellen',
    },
    'ufo': {
      'name': '🛸 UFOs & Außerirdisches',
      'description': 'Sichtungen, Kontakte, geheime Programme',
      'color': Colors.green,
      'icon': '🛸',
      'tool': 'Sichtungskarte (Global)',
      'toolDescription': 'UFO-Sichtungen weltweit gemeinsam dokumentieren',
    },
    'verschwoerungen': {
      'name': '👁️ Verschwörungen & Wahrheit',
      'description': 'Deep State, Geheimgesellschaften, Symbolik',
      'color': Colors.purple,
      'icon': '👁️',
      'tool': 'Verbindungsnetz',
      'toolDescription': 'Zusammenhänge zwischen Ereignissen & Personen visualisieren',
    },
    'wissenschaft': {
      'name': '🔬 Unterdrückte Technologie',
      'description': 'Freie Energie, Tesla, verbotene Erfindungen',
      'color': Colors.blue,
      'icon': '🔬',
      'tool': 'Forschungs-Archiv (Shared)',
      'toolDescription': 'Gemeinsame Sammlung unterdrückter Technologien',
    },
  };

  @override
  void initState() {
    super.initState();
    
    // 🔥 Initialize User ID from UserService
    _userId = UserService.getCurrentUserId();
    
    // 🔧 FIX 18: Set initial room from dashboard navigation
    _selectedRoom = widget.initialRoom ?? 'politik';

    // 🎤 Initialize WebRTC Voice Service
    _initializeWebRTC();

    // 📝 Listen to input changes for @ mentions
    _messageController.addListener(_onInputChanged);

    // 🔧 FIX 10: Listen for input focus changes with explicit state
    _inputFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isInputFocused = _inputFocusNode.hasFocus;
          debugPrint('🎯 [MATERIE INPUT] focused: $_isInputFocused');
        });
      }
    });

    // ✨ Batch-1: Scroll-Listener für at-bottom Detection + Pagination
    _scrollController.addListener(_onScroll);

    // ✨ Batch-1: Beim ersten Öffnen Raum als gesehen markieren.
    UnreadTrackerService.instance.markSeen(_fullRoomId);

    // 🔴 SUPABASE REALTIME: Echtzeit-Subscription starten (sofort, parallel zu Profil-Load)
    _subscribeToRoom(_fullRoomId);

    // 🔄 AUTO-REFRESH: Profil-Updates alle 30 Sekunden als Fallback (Realtime ist primär)
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadMessages(silent: true); // ✅ Silent refresh - kein Flickering
      _loadPolls(silent: true); // ✅ Silent refresh - kein Flickering
      _loadUsernameFromProfile(); // Profil-Sync für Avatar-Updates
    });

    // Profil VOR Nachrichten laden → Username garantiert gesetzt wenn User schreibt.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadUsernameFromProfile();
      _notificationService.setCurrentUsername(_username);
      // ✨ Batch-2: Presence aktivieren, sobald der Username bekannt ist.
      await _refreshPresence();
      // ✨ Batch-2.3: Read-Receipts für den Raum streamen + markieren.
      await ReadReceiptService.instance.watchRoom(_fullRoomId);
      await _markRoomRead();
      await _loadMessages();
      _loadPolls();
    });
  }

  // ✨ Batch-2.3: Eigenen Receipt für aktuellen Raum bumpen.
  Future<void> _markRoomRead() async {
    if (_userId.isEmpty) return;
    await ReadReceiptService.instance.markRead(
      roomId: _fullRoomId,
      userId: _userId,
    );
  }

  // ✨ Batch-2: Presence-Join/Re-Join für den aktuellen Raum.
  Future<void> _refreshPresence() async {
    if (_userId.isEmpty || _username.isEmpty) return;
    await PresenceService.instance.join(
      roomId: _fullRoomId,
      userId: _userId,
      username: _username,
      avatar: _avatar.isNotEmpty ? _avatar : '🔴',
    );
  }

  // ✨ Batch-2: Raum-Info-Sheet mit Beschreibung + Online-Counter.
  void _showRoomInfoSheet() {
    final room = _materieRooms[_selectedRoom];
    if (room == null) return;
    ChatRoomInfoSheet.show(
      context,
      roomName: (room['name'] as String?) ?? _selectedRoom,
      roomIcon: (room['icon'] as String?) ?? '💬',
      description:
          (room['description'] as String?) ?? 'Live-Chat in diesem Raum.',
      worldColor: Colors.red,
    );
  }

  // didChangeDependencies removed – profile loading happens once in initState.

  Future<void> _loadUsernameFromProfile() async {
    MaterieProfile? profile;
    try {
      // Ensure box is open – main.dart opens it, but guard for safety
      if (!Hive.isBoxOpen('materie_profiles')) {
        await Hive.openBox('materie_profiles');
      }
      final storage = StorageService();
      profile = storage.getMaterieProfile();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden des Materie-Profils: $e');
      }
      // Fall through – profile stays null → dialog will be shown
    }

    if (profile != null && profile.username.isNotEmpty) {
      if (mounted) {
        setState(() {
          _username = profile!.username;
          _userId = supabase.auth.currentUser?.id ?? 'user_${profile.username.toLowerCase()}';
          _avatar = profile.avatarEmoji ?? '👤';
          _avatarEmoji = profile.avatarEmoji;
          _avatarUrl = profile.avatarUrl;
        });
      }
      // Sync into user_data box so AdminStateNotifier can find it
      try {
        final unified = UnifiedStorageService();
        await unified.saveProfile('materie', {
          'username': profile.username,
          'role': profile.role ?? 'user',
          'avatar_emoji': profile.avatarEmoji,
          'avatar_url': profile.avatarUrl,
        });
      } catch (_) {}
      _notificationService.setCurrentUsername(_username);
      if (kDebugMode) {
        debugPrint('✅ Username aus Materie-Profil geladen: $_username (role: ${profile.role})');
      }
      // ✅ Flag NICHT zurücksetzen – verhindert erneutes Popup nach
      // Rückkehr aus ProfileEditorScreen wenn Profil schon existiert
    } else {
      // Kein Profil → Dialog einmalig zeigen
      if (kDebugMode) debugPrint('⚠️ Kein Materie-Profil gefunden – zeige Profil-Dialog');
      if (!_profileDialogShown) {
        _profileDialogShown = true;
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _showUsernameDialog();
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onInputChanged);
    _messageController.dispose();
    _scrollController.removeListener(_onScroll); // ✨ Batch-1
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _refreshTimer?.cancel();
    _voiceParticipantsSub?.cancel(); // 🔧 Prevent memory leak
    _realtimeChannel?.unsubscribe(); // 🔴 Realtime cleanup
    // ✨ Batch-2: Presence sauber verlassen.
    PresenceService.instance.leave();
    // ✨ Batch-2.3: Read-Receipt-Stream schließen.
    ReadReceiptService.instance.leave();
    super.dispose();
  }

  // ✨ Batch-1: Emoji-Insert an aktueller Caret-Position.
  void _insertEmoji(String emoji) {
    final text = _messageController.text;
    final sel = _messageController.selection;
    final insertAt = sel.isValid ? sel.start : text.length;
    final newText = text.replaceRange(
        insertAt, sel.isValid ? sel.end : text.length, emoji);
    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: insertAt + emoji.length),
    );
  }

  // ✨ Batch-1: Scroll-Listener — trackt at-bottom + triggert Pagination oben.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final distFromBottom = pos.maxScrollExtent - pos.pixels;
    final nowAtBottom = distFromBottom < 80;
    if (nowAtBottom != _isAtBottom) {
      setState(() {
        _isAtBottom = nowAtBottom;
        if (nowAtBottom) _newMessagesCount = 0;
      });
    }
    if (pos.pixels <= 120 &&
        _hasMoreOlder &&
        !_loadingOlder &&
        _messages.isNotEmpty) {
      _loadOlderMessages();
    }
  }

  // ✨ Batch-1: Pagination — ältere Nachrichten laden.
  Future<void> _loadOlderMessages() async {
    if (_loadingOlder) return;
    setState(() => _loadingOlder = true);
    try {
      final oldest = _messages.first;
      final cursor = (oldest['created_at'] ?? oldest['timestamp'])?.toString();
      if (cursor == null || cursor.isEmpty) return;
      final older = await SupabaseChatService.instance.getMessagesBefore(
        _fullRoomId,
        before: cursor,
        limit: 50,
      );
      if (!mounted) return;
      if (older.isEmpty) {
        setState(() => _hasMoreOlder = false);
        return;
      }
      final priorExtent = _scrollController.hasClients
          ? _scrollController.position.maxScrollExtent
          : 0.0;
      final priorOffset = _scrollController.hasClients
          ? _scrollController.position.pixels
          : 0.0;
      final existingIds = _messages.map((m) => m['id']).toSet();
      final merged = <Map<String, dynamic>>[
        ...older.where((m) => !existingIds.contains(m['id'])),
        ..._messages,
      ];
      setState(() => _messages = merged);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final delta =
            _scrollController.position.maxScrollExtent - priorExtent;
        _scrollController.jumpTo(priorOffset + delta);
      });
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Materie loadOlder failed: $e');
    } finally {
      if (mounted) setState(() => _loadingOlder = false);
    }
  }

  // ✨ Batch-1: Smart autoscroll — nur wenn User am Ende.
  void _scrollToBottomIfAtEnd() {
    if (_isAtBottom) _scrollToBottom();
  }

  // 🔴 SUPABASE REALTIME: Subscribe to live chat updates
  void _subscribeToRoom(String roomId) {
    _realtimeChannel?.unsubscribe();
    _reconnecting = true;
    _realtimeChannel = SupabaseChatService.instance.subscribeToRoom(
      roomId,
      onMessage: (newMsg) {
        if (!mounted) return;
        if (_reconnecting) setState(() => _reconnecting = false);
        final exists = _messages.any((m) => m['id'] == newMsg['id']);
        if (!exists) {
          final isOwn = (newMsg['username']?.toString() == _username) ||
              (newMsg['user_id']?.toString() == _userId);
          setState(() {
            _messages.add(newMsg);
            if (!_isAtBottom && !isOwn) _newMessagesCount++;
          });
          _scrollToBottomIfAtEnd();
        }
      },
      onUpdate: (updatedMsg) {
        if (!mounted) return;
        final id = updatedMsg['id']?.toString();
        if (id == null) return;
        final idx = _messages.indexWhere((m) => m['id']?.toString() == id);
        if (idx >= 0) {
          setState(() {
            _messages[idx] = {..._messages[idx], ...updatedMsg};
          });
        }
      },
      onDelete: (messageId) {
        if (!mounted) return;
        setState(() {
          _messages.removeWhere((m) => m['id']?.toString() == messageId);
        });
      },
    );
    if (kDebugMode) debugPrint('🔴 [Materie Realtime] Subscribed to room: $roomId');
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted && _reconnecting) setState(() => _reconnecting = false);
    });
  }
  
  // 🛠️ TOOL NAVIGATION
  // ignore: unused_element
  void _navigateToTool() {
    Widget? screen;
    
    switch (_selectedRoom) {
      case 'politik':
        screen = GeopolitikMapScreen(roomId: _selectedRoom);
        break;
      case 'geschichte':
        screen = HistoryTimelineScreen(roomId: _selectedRoom);
        break;
      case 'ufos':
        screen = UfoSightingsScreen(roomId: _selectedRoom);
        break;
      case 'verschwoerungen':
        screen = ConspiracyNetworkScreen(roomId: _selectedRoom);
        break;
      case 'technologie':
        screen = ResearchArchiveScreen(roomId: _selectedRoom);
        break;
      case 'gesundheit':
        screen = AlternativeHealingScreen(roomId: _selectedRoom);
        break;
    }
    
    if (screen != null && mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => screen!));
    }
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) {
      setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous error
    });
    }
    
    try {
      // 🔧 Lade echte Chat-Nachrichten von Cloudflare API
      final messages = await _api.getChatMessages(
        _fullRoomId, // 'materie-politik' etc.
        realm: 'materie',
        limit: 50,
      ).timeout(const Duration(seconds: 15));
      
      // 🔧 DEBUG: Log message count
      if (kDebugMode) {
        debugPrint('✅ MATERIE Chat geladen: ${messages.length} Nachrichten von Cloudflare');
        if (messages.isNotEmpty) {
          debugPrint('🔍 Erste Nachricht keys: ${messages.first.keys.toList()}');
          debugPrint('🔍 Erste Nachricht id: ${messages.first['id']}');
          debugPrint('🔍 Erste Nachricht message: ${messages.first['message']}');
        } else {
          debugPrint('⚠️ Keine Nachrichten geladen für Raum: $_selectedRoom');
        }
      }
      
      if (mounted) {
        setState(() {
        // Worker returns messages in ascending order (created_at.asc)
        // → already chronological, no reversal needed
        _messages = messages;
        _isLoading = false;
        _errorMessage = null;
      });
      }
      
      // Auto-scroll zum Ende
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ MATERIE Chat Load Error: $e');
        debugPrint('❌ Error type: ${e.runtimeType}');
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString(); // Store error for ErrorDisplayWidget
        });
      }
    }
  }
  
  // 🗳️ LOAD POLLS
  Future<void> _loadPolls({bool silent = false}) async {
    try {
      final polls = await _api.getPolls(_fullRoomId);
      if (mounted) {
        _polls = polls; // ← Update direkt
        
        // ✅ setState NUR wenn NICHT silent
        if (!silent) {
          if (mounted) setState(() {});
        }
      }
    } catch (e) {
      if (!silent && kDebugMode) debugPrint('❌ Load polls error: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // 🚨 USERNAME-CHECK: Verhindere Senden ohne Profil
    if (_username.isEmpty) {
      if (mounted && !_profileDialogShown) {
        _profileDialogShown = true; // ✅ Setze Flag sofort
        _showUsernameDialog();
      }
      return;
    }

    // 🛑 Batch-4: Word-Filter (Client-Side)
    final badWord = ChatWordFilterService.instance.firstHit(text);
    if (badWord != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Nachricht enthält ein blockiertes Wort: "${badWord.trim()}"',
            ),
            backgroundColor: const Color(0xFFE53935),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // 🛑 Batch-4: Rate-Limit + Slow-Mode (Client-Side Spambremse)
    if (!ChatRateLimitService.instance.canSend(_fullRoomId)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ChatRateLimitService.instance.cooldownMessage(_fullRoomId),
            ),
            backgroundColor: const Color(0xFFE53935),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    ChatRateLimitService.instance.recordSend(_fullRoomId);

    try {
      // 🟢 Sende Nachricht via Supabase (CloudflareApiService delegiert intern)
      final replyData = _replyingTo;
      final serverMsg = await _api.sendChatMessage(
        roomId: _fullRoomId, // 'materie-politik' etc.
        realm: 'materie',
        userId: _userId,
        username: _username,
        message: text,
        avatarEmoji: _avatarEmoji,
        avatarUrl: _avatarUrl,
        replyToId: replyData?['id']?.toString(),
        replyToContent: replyData?['message']?.toString()
            ?? replyData?['content']?.toString(),
        replyToSenderName: replyData?['username']?.toString(),
      );

      _messageController.clear();
      ChatDraftService.instance.clear(_fullRoomId);

      // 🔴 Optimistic add (Realtime-Sub dedup'd via ID → kein Duplikat,
      //    kein Full-Reload nötig).
      if (mounted) {
        setState(() {
          final exists = _messages.any((m) => m['id'] == serverMsg['id']);
          if (!exists) _messages.add(serverMsg);
          _replyingTo = null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Materie Chat] Senden fehlgeschlagen: $e');
      if (mounted) {
        String msg;
        final err = e.toString();
        if (err.contains('Nicht eingeloggt')) {
          msg = 'Bitte Profil anlegen oder erneut versuchen.';
        } else if (err.contains('permission denied') || err.contains('42501')) {
          msg = 'Keine Berechtigung – bitte App neu starten.';
        } else if (err.contains('violates row-level security')) {
          msg = 'Datenbank-Fehler – bitte App neu starten.';
        } else {
          msg = 'Nachricht konnte nicht gesendet werden.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// 🎤 VOICE MESSAGE SEND
  Future<void> _sendVoiceMessage(String audioUrl, Duration duration) async {
    try {
      // Send voice message with media_type
      final serverMsg = await _api.sendChatMessage(
        roomId: _fullRoomId, // 'materie-politik' etc.
        realm: 'materie',
        userId: _userId,
        username: _username,
        message: '🎤 Sprachnachricht (${duration.inSeconds}s)',
        avatarEmoji: _avatarEmoji,
        avatarUrl: _avatarUrl,
        mediaType: 'voice',
        mediaUrl: audioUrl,
      );

      // 🔴 Optimistic add (dedup in Realtime-Callback).
      if (mounted) {
        setState(() {
          final exists = _messages.any((m) => m['id'] == serverMsg['id']);
          if (!exists) _messages.add(serverMsg);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
      
      if (kDebugMode) {
        debugPrint('✅ Sprachnachricht gesendet: $audioUrl, Duration: ${duration.inSeconds}s');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Senden der Sprachnachricht: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Senden: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// 🎤 OPEN ANDROID VOICE RECORDER
  Future<void> _openVoiceRecorder() async {
    if (kDebugMode) {
      debugPrint('🎤 Opening Android Voice Recorder...');
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AndroidVoiceRecorder(
        onRecordingComplete: (String audioPath, Duration duration) async {
          // Upload to Cloudflare R2 and get URL
          try {
            if (kDebugMode) {
              debugPrint('🎤 Uploading voice message: $audioPath');
            }

            // Show uploading indicator
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('🎤 Sprachnachricht wird hochgeladen...'),
                    ],
                  ),
                  backgroundColor: Color(0xFF2196F3),
                  duration: Duration(seconds: 30),
                ),
              );
            }

            // Upload to Cloudflare
            final audioUrl = await _api.uploadVoiceMessage(
              filePath: audioPath,
              userId: _userId,
              roomId: _selectedRoom,
              realm: 'materie',
            );

            if (kDebugMode) {
              debugPrint('✅ Voice uploaded: $audioUrl');
            }

            // Close upload indicator
            if (mounted) {
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
            
            // Send voice message
            await _sendVoiceMessage(audioUrl, duration);
            
            if (mounted) {
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ Voice upload error: $e');
            }
            if (mounted) {
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Upload fehlgeschlagen: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onCancel: () {
          if (mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
  
  /// 📷 IMAGE UPLOAD
  Future<void> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image == null) return;
      
      // Read file bytes for preview
      final bytes = await image.readAsBytes();
      
      // 🖼️ SHOW IMAGE PREVIEW DIALOG
      if (mounted) {
        final shouldUpload = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF121212),
            title: const Text(
              'Bild senden?',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    height: 300,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Größe: ${(bytes.length / 1024).toStringAsFixed(1)} KB',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Abbrechen',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Senden'),
              ),
            ],
          ),
        );
        
        if (shouldUpload != true) return;
      }
      
      // Show uploading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('📤 Bild wird hochgeladen...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }
      
      // Upload to Cloudflare R2
      final result = await _api.uploadFile(
        fileBytes: bytes,
        fileName: image.name,
        contentType: 'image/jpeg',
        type: 'image',
        userId: _userId,
      );
      
      if (result['success'] == true && result['url'] != null) {
        // Send message with image URL
        await _api.sendChatMessage(
          roomId: _fullRoomId, // 'materie-politik' etc.
          realm: 'materie',
          userId: _userId,
          username: _username,
          message: '📷 Bild', // Text for image message
          avatarEmoji: _avatar,
          mediaType: 'image',
          mediaUrl: result['url'],
        );
        
        // Reload messages
        await _loadMessages(silent: true);
        
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Bild hochgeladen!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Image upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Upload fehlgeschlagen: ${e.toString().substring(0, 50)}...'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // 🆕 @ MENTION AUTO-COMPLETE
  void _onInputChanged() {
    final text = _messageController.text;
    final cursorPos = _messageController.selection.baseOffset;

    // ✨ Batch-5: Draft persistieren
    ChatDraftService.instance.set(_fullRoomId, text);

    // 🎤➤ UPDATE BUTTON STATE: Voice/Send
    if (mounted) {
      setState(() {
      _hasText = text.trim().isNotEmpty;
    });
    }
    
    // Check if user is typing @mention
    if (cursorPos > 0 && text.length >= cursorPos) {
      final beforeCursor = text.substring(0, cursorPos);
      final words = beforeCursor.split(' ');
      final lastWord = words.isNotEmpty ? words.last : '';
      
      if (lastWord.startsWith('@') && lastWord.length > 1) {
        // Show mention suggestions
        final query = lastWord.substring(1).toLowerCase();
        final allUsers = _messages
            .map((m) => m['username'] as String?)
            .where((u) => u != null && u != _username)
            .toSet()
            .toList();
        
        if (mounted) {
          setState(() {
          _mentionSuggestions = allUsers
              .where((u) => u!.toLowerCase().contains(query))
              .take(5)
              .cast<String>()
              .toList();
          _showMentionPicker = _mentionSuggestions.isNotEmpty;
        });
        }
      } else {
        if (mounted) {
          setState(() {
          _showMentionPicker = false;
          _mentionSuggestions = [];
        });
        }
      }
    }
  }
  
  // 🆕 SELECT MENTION
  void _selectMention(String username) {
    final text = _messageController.text;
    final cursorPos = _messageController.selection.baseOffset;
    final beforeCursor = text.substring(0, cursorPos);
    final afterCursor = text.substring(cursorPos);
    
    final words = beforeCursor.split(' ');
    if (words.isNotEmpty) {
      words[words.length - 1] = '@$username ';
      final newText = words.join(' ') + afterCursor;
      _messageController.text = newText;
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: words.join(' ').length),
      );
    }
    
    if (mounted) {
      setState(() {
      _showMentionPicker = false;
      _mentionSuggestions = [];
    });
    }
  }
  
  // ✅ SYNC REACTION via Cloudflare API (called after local state update)
  Future<void> _syncReactionToApi(String messageId, String emoji, bool isAdding) async {
    try {
      if (isAdding) {
        await _api.addReaction(
          messageId: messageId,
          emoji: emoji,
          username: _username,
          userId: _userId,
        );
      } else {
        await _api.removeReaction(
          messageId: messageId,
          emoji: emoji,
          username: _username,
          userId: _userId,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ syncReaction API error: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
    if (mounted) {
      setState(() {
        _isAtBottom = true;
        _newMessagesCount = 0;
      });
    }
    // ✨ Batch-2.3: User sieht das Ende → Receipt bumpen.
    _markRoomRead();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // 📱 Mobile: Keyboard doesn't cover input
      backgroundColor: const Color(0xFF04080F), // home-dashboard bg
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1020), // home-dashboard card
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _showRoomInfoSheet,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '💬 ${_materieRooms[_selectedRoom]?['name'] ?? 'MATERIE LIVE-CHAT'}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              const ChatOnlineIndicator(),
            ],
          ),
        ),
        actions: [
          // 🎥 VIDEO + VOICE CHAT BUTTON (Telegram-Style)
          IconButton(
            icon: const Icon(Icons.video_call, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoVoiceChatScreen(
                    roomId: 'materie_$_selectedRoom',
                    userId: _userId,
                    username: _username,
                    avatar: _avatar.isNotEmpty ? _avatar : '🔴',
                    accentColor: const Color(0xFFE53935),
                  ),
                ),
              );
            },
            tooltip: 'Video / Voice Chat',
          ),
          // 🔍 SEARCH BUTTON
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close : Icons.search,
              color: _showSearch ? Colors.red : Colors.white,
            ),
            onPressed: _toggleSearch,
            tooltip: 'Suchen',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Builder(
              builder: (context) {
            // 🔧 FIX 10: Hide headers using explicit focus state
            final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
            final hideHeaders = keyboardVisible || _isInputFocused;

            return GestureDetector(
              onTap: () {
                if (_isInputFocused) {
                  FocusScope.of(context).unfocus();
                  if (mounted) {
                    setState(() {
                    _isInputFocused = false;
                  });
                  }
                }
              },
              child: Column(
                children: [
                  // ✨ Batch-1: Status-Banner (Offline / Reconnecting / Pending-Queue)
                  ChatStatusBanner(
                    reconnecting: _reconnecting,
                    worldColor: Colors.red,
                  ),
                  // 🔍 SEARCH MODE
                  if (_showSearch)
                    Expanded(
                      child: MessageSearchWidget(
                        messages: _messages,
                        onSelectMessage: _jumpToMessage,
                        onClose: _toggleSearch,
                      ),
                    )
                  else ...[
                  // 🔧 HIDE WHEN INPUT FOCUSED OR KEYBOARD OPEN
                  if (!hideHeaders) ...[
                    // 📌 PINNED MESSAGE BANNER (Fixed height)
                    SizedBox(
                      height: 44, // 🔧 Reduziert für mehr Chat-Platz
                      child: PinnedMessageBanner(
                        room: _selectedRoom,
                        onRefresh: () {
                          _loadMessages();
                        },
                        onTap: () {
                          // ✅ Scroll to bottom (pinned message visible)
                          _scrollToBottom();
                        },
                        worldColor: Colors.red, // MATERIE Red
                      ),
                    ),
                    // ✅ REMOVED: VoiceChatBanner (redundant - use VoiceParticipantHeaderBar instead)
                  // 🎤 TELEGRAM VOICE HEADER BAR (ONLY WHEN ACTIVE - like real Telegram)
                  if (_isInVoiceRoom)
                    VoiceParticipantHeaderBar(
                      participants: _voiceParticipants,
                      accentColor: Colors.red,
                      onTap: _openTelegramVoiceScreen,
                    ),
                  // ⌨️ TYPING INDICATORS
                  if (_typingUsers.isNotEmpty) _buildTypingIndicators(),
                  _buildRoomSelector(),
                ], // End keyboard-hidden headers
          Expanded(child: _buildMessageList()),
          // 🗳️ ACTIVE POLLS
          if (_polls.isNotEmpty)
            Container(
              height: 180,
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.5),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                itemCount: _polls.length,
                itemBuilder: (context, index) {
                  final poll = _polls[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8, // 📱 Mobile: 80% screen width
                      child: PollWidget(
                        poll: poll,
                        currentUserId: _userId,
                        currentUsername: _username,
                        worldColor: Colors.red, // MATERIE Red
                        onVote: (pollId, optionIndex) async {
                          await _api.voteOnPoll(
                            pollId: pollId,
                            userId: _userId,
                            username: _username,
                            optionIndex: optionIndex,
                          );
                          _loadPolls();
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ], // END else (search mode)
          if (!_showSearch) // Hide input when searching
          _buildMessageInput(),
        ], // End Column children
      ), // End Column
      ); // End GestureDetector
    }, // End Builder builder
            ), // End Builder
            
            // 📡 OFFLINE INDICATOR (NEW Phase 3)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: OfflineIndicator(),
            ),

            // ✨ Batch-1: Floating "X neue Nachrichten" Button
            Positioned(
              right: 16,
              bottom: 90,
              child: ChatNewMessagesFab(
                visible: !_isAtBottom && _newMessagesCount > 0,
                count: _newMessagesCount,
                onTap: _scrollToBottom,
                color: Colors.red,
              ),
            ),
          ],
        ), // End Stack
      ), // End SafeArea
    );
  }

  // 🛠️ TOOL-WIDGET FÜR DEN AKTUELLEN RAUM
    // switch (_selectedRoom) {
      // case 'politik':
        // return DebattenKarte(roomId: 'politik');
      // case 'geschichte':
        // return ZeitleisteTool(roomId: 'geschichte');
      // case 'ufos':
        // return SichtungsKarteTool(roomId: 'ufos');
      // case 'verschwoerungen':
        // return RechercheTool(roomId: 'verschwoerungen');
      // case 'wissenschaft':
        // return ExperimentTool(roomId: 'wissenschaft');
      // default:
        // return null;
    // }
  // }

  // 🏷️ TOOL-NAME
    // switch (_selectedRoom) {
      // case 'politik':
        // return '🎯 DEBATTENKARTE';
      // case 'geschichte':
        // return '📅 ZEITLEISTE';
      // case 'ufos':
        // return '🗺️ SICHTUNGS-KARTE';
      // case 'verschwoerungen':
        // return '🔍 RECHERCHE-BOARD';
      // case 'wissenschaft':
        // return '🧪 EXPERIMENT-LOG';
      // default:
        // return 'WERKZEUG';
    // }
  // }

  // 🎨 TOOL-ICON
    // switch (_selectedRoom) {
      // case 'politik':
        // return Icons.forum;
      // case 'geschichte':
        // return Icons.timeline;
      // case 'ufos':
        // return Icons.map;
      // case 'verschwoerungen':
        // return Icons.account_tree;
      // case 'wissenschaft':
        // return Icons.science;
      // default:
        // return Icons.build;
    // }
  // }

  // 🌈 TOOL-COLOR
    // switch (_selectedRoom) {
      // case 'politik':
        // return Colors.blue;
      // case 'geschichte':
        // return Colors.amber;
      // case 'ufos':
        // return Colors.green;
      // case 'verschwoerungen':
        // return Colors.purple;
      // case 'wissenschaft':
        // return Colors.cyan;
      // default:
        // return Colors.grey;
    // }
  // }

  /// 🆕 MODERN TABBED ROOM SELECTOR (Telegram-Style)
  Widget _buildRoomSelector() {
    return Container(
      height: 32, // 🔧 FIX: 42 → 32px (Room Selector kompakt!)
      decoration: BoxDecoration(
        color: const Color(0xFF0A1020), // home-dashboard card
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: _materieRooms.entries.map((entry) {
          final isSelected = _selectedRoom == entry.key;
          final roomData = entry.value;
          final chipFullRoomId = 'materie-${entry.key}';

          return GestureDetector(
            onTap: () async {
              if (entry.key != _selectedRoom) {
                // ✨ Batch-5: Draft des alten Raums sichern
                ChatDraftService.instance.set(_fullRoomId, _messageController.text);
                if (mounted) {
                  setState(() {
                  _selectedRoom = entry.key;
                  _messages.clear();
                  _isLoading = true;
                  _hasMoreOlder = true;
                  _newMessagesCount = 0;
                  _isAtBottom = true;
                });
                }
                // ✨ Batch-5: Draft des neuen Raums laden
                _messageController.text = ChatDraftService.instance.get(_fullRoomId);
                // ✨ Batch-1: Unread für neuen Raum zurücksetzen.
                UnreadTrackerService.instance.markSeen(_fullRoomId);

                // 🔧 Switch WebRTC Voice Room
                await _voiceService.switchRoom(_fullRoomId); // ← WebRTC cleanup
                // ✨ Batch-2: Presence auf den neuen Raum umziehen.
                await _refreshPresence();
                // ✨ Batch-2.3: Read-Receipts auf neuen Raum umstellen.
                await ReadReceiptService.instance.watchRoom(_fullRoomId);
                await _markRoomRead();
                // 🔴 Re-subscribe Realtime for new room
                _subscribeToRoom(_fullRoomId);
                await _loadMessages();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6), // 🔧 FIX 6: Mehr spacing
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected 
                        ? (roomData['color'] as Color) 
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🔧 FIX 14: Icon + ✨ Batch-1: Unread-Badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Text(
                        roomData['icon'] ?? '💬',
                        style: TextStyle(
                          fontSize: isSelected ? 22 : 20,
                        ),
                      ),
                      Positioned(
                        top: -4,
                        right: -10,
                        child: ChatUnreadBadge(roomId: chipFullRoomId),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4), // Mehr Abstand
                  // 🔧 FIX 14: Label OHNE Icon, größer & lesbarer
                  Text(
                    (roomData['name'] as String)
                        .replaceAll('🌍 ', '')
                        .replaceAll('🧪 ', '')
                        .replaceAll('🔬 ', '')
                        .replaceAll('⚛️ ', '')
                        .replaceAll('🏗️ ', '')
                        .split('&')[0] // Vor & schneiden
                        .trim(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontSize: 11, // Größer für Lesbarkeit
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageList() {
    // 🎨 ERROR STATE (NEW)
    if (_errorMessage != null && _messages.isEmpty) {
      return ErrorDisplayWidget(
        error: _errorMessage!,
        onRetry: _loadMessages,
      );
    }
    
    // 🎨 LOADING STATE (NEW)
    if (_isLoading && _messages.isEmpty) {
      return const LoadingStateWidget(
        message: 'Lade Nachrichten...',
      );
    }

    // 🎨 EMPTY STATE (NEW)
    if (_messages.isEmpty) {
      return const EmptyStateWidget(
        title: 'Noch keine Nachrichten',
        message: 'Sei der Erste, der etwas schreibt!',
        icon: Icons.chat_bubble_outline,
      );
    }

    return AnimatedBuilder(
      animation: UserBlockService.instance,
      builder: (_, __) {
        final visible = UserBlockService.instance
            .filterMessages(_messages)
            .toList(growable: false);
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          reverse: false, // Normal order: Alte Nachrichten oben, neue unten
          itemCount: visible.length + (_loadingOlder ? 1 : 0),
          cacheExtent: 500, // 🚀 PERFORMANCE: Pre-render 500px ahead
          addAutomaticKeepAlives: false, // 🚀 PHASE B
          addRepaintBoundaries: true, // 🚀 PHASE B: Isolate repaints per item
          itemBuilder: (context, index) {
            // ✨ Batch-1: Pagination-Spinner an Position 0 beim Nachladen.
            if (_loadingOlder && index == 0) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.red,
                    ),
                  ),
                ),
              );
            }
            final message = visible[index - (_loadingOlder ? 1 : 0)];
            // 🚀 PHASE B: RepaintBoundary + ValueKey for performance
            return RepaintBoundary(
              key: ValueKey(message['message_id'] ?? message['id']),
              child: _buildSwipeableMessage(message),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1020), // home-dashboard card
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🆕 REPLY PREVIEW
          _buildReplyPreview(),
          // 🆕 MENTION AUTO-COMPLETE
          if (_showMentionPicker)
            MentionAutoComplete(
              suggestions: _mentionSuggestions,
              onSelectUser: _selectMention,
              accentColor: const Color(0xFF2196F3),
            ),
          
          // MESSAGE INPUT ROW
          Row(
            children: [
              // 📷 IMAGE UPLOAD BUTTON
              IconButton(
                icon: const Icon(Icons.image, color: Colors.red),
                onPressed: _pickAndUploadImage,
                tooltip: 'Bild hochladen',
              ),

              // 👤 AVATAR BUTTON (Klickbar zum Ändern - wie ENERGIE)
              GestureDetector(
                onTap: _showAvatarPicker, // ✅ Avatar-Picker implementiert
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.red, Color(0xFFE53935)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                        ? Image.network(
                            _avatarUrl!,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  _avatar.isEmpty ? '👤' : _avatar,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              _avatar.isEmpty ? '👤' : _avatar,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // ✨ Batch-1: Emoji-Picker-Button
              ChatEmojiPickerButton(
                onSelected: _insertEmoji,
                color: Colors.red,
              ),

              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _inputFocusNode,
                  // 🔧 FIX 11: DIREKTER onTap Handler um Headers SOFORT zu verstecken!
                  onTap: () {
                    debugPrint('🎯 [DIREKTER TAP] Input angeklickt!');
                    if (!_isInputFocused) {
                      if (mounted) {
                        setState(() {
                        _isInputFocused = true;
                        debugPrint('🔥 [DIREKTER TAP] _isInputFocused = true');
                      });
                      }
                    }
                  },
                  style: const TextStyle(color: Colors.white),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(), // ⌨️ Enter key sends message
                  decoration: InputDecoration(
                    hintText: 'Nachricht schreiben... (@mention)',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    prefixIcon: Icon(
                      Icons.alternate_email,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // ➤ SEND / MIC BUTTON (Energie-Style Gradient)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _hasText
                        ? [Colors.red, const Color(0xFFE53935)]
                        : [Colors.grey.shade400, Colors.grey.shade500],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _hasText ? _sendMessage : _openVoiceRecorder,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: Icon(
                        _hasText ? Icons.send : Icons.mic_none,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // EDIT/DELETE FUNCTIONS
  // ═══════════════════════════════════════════════════════════

  // OLD VERSION - REPLACED BY PHASE 2
  /*
  void _showMessageOptions(BuildContext context, Map<String, dynamic> message) {
    // 🔧 ROBUSTER USERID-CHECK: Support mehrere Formate
    final messageUserId = message['userId'] ?? message['user_id'] ?? '';
    final isOwnMessage = messageUserId == _userId || 
                         messageUserId.toLowerCase() == _userId.toLowerCase() ||
                         messageUserId == 'user_${_username.toLowerCase()}' ||
                         message['username'] == _username; // Fallback: username-check
    
    if (kDebugMode) {
      debugPrint('🔍 Message Options Check:');
      debugPrint('   messageUserId: $messageUserId');
      debugPrint('   current _userId: $_userId');
      debugPrint('   current _username: $_username');
      debugPrint('   isOwnMessage: $isOwnMessage');
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Nachricht-Optionen',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(color: Colors.grey),
            // Edit (nur eigene Nachrichten)
            if (isOwnMessage)
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Bearbeiten', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _editMessage(message);
                },
              ),
            // Delete (nur eigene Nachrichten)
            if (isOwnMessage)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Löschen', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteMessage(message);
                },
              ),
            // Reply (alle Nachrichten)
            ListTile(
              leading: const Icon(Icons.reply, color: Colors.green),
              title: const Text('Antworten', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _replyToMessage(message);
              },
            ),
            // Cancel
            ListTile(
              leading: const Icon(Icons.close, color: Colors.grey),
              title: const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  */ // END OLD VERSION

  // 🎨 AVATAR PICKER - Wie in ENERGIE
  Future<void> _showAvatarPicker() async {
    final avatars = ['👤', '🤓', '🧙', '🔮', '📚', '🎭', '🎨', '⚡', '🔥', '💀', '👁️', '🌙', '⭐', '💎', '🗿'];
    
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🎭 Wähle deinen Avatar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: avatars.length,
                itemBuilder: (context, index) {
                  final avatar = avatars[index];
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, avatar),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.red, Color(0xFFE53935)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _avatar == avatar 
                              ? Colors.white 
                              : Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          avatar,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        );
      },
    );
    
    if (selected != null) {
      if (mounted) {
        setState(() {
          _avatar = selected;
          _avatarEmoji = selected; // Update auch avatarEmoji
        });
      }
      
      // 💾 Speichere in Profil
      final storage = StorageService();
      final profile = storage.getMaterieProfile();
      if (profile != null) {
        final updated = MaterieProfile(
          username: profile.username,
          name: profile.name,
          bio: profile.bio,
          avatarEmoji: selected, // ✅ Avatar-Emoji speichern
          avatarUrl: profile.avatarUrl, // Behalte URL
          userId: profile.userId, // 🔥 FIX: Behalte userId
          role: profile.role, // 🔥 FIX: Behalte role
        );
        
        // 🔥 FIX: Backend-Sync durchführen um role zu bewahren
        final syncService = ProfileSyncService();
        final syncedProfile = await syncService.saveMaterieProfileAndGetUpdated(updated);
        
        if (syncedProfile != null) {
          await storage.saveMaterieProfile(syncedProfile);
          if (kDebugMode) {
            debugPrint('✅ Avatar-Emoji gespeichert mit Backend-Sync');
            debugPrint('   Role: ${syncedProfile.role}');
          }
        } else {
          // Fallback: Lokales Profil speichern
          await storage.saveMaterieProfile(updated);
        }
      }
    }
  }



  void _showUsernameDialog() {
    // ✅ NEU: Profil-Popup statt Username-Dialog
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Profil benötigt'),
          ],
        ),
        content: const Text(
          'Um den Chat nutzen zu können, musst du zuerst ein Profil erstellen.\n\n'
          'Erstelle dein Profil in der Materie-Welt.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // ✅ FIXED: await → nach Rückkehr Profil sofort neu laden
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileEditorScreen(world: 'materie'),
                ),
              );
              // Profil neu laden nachdem User zurückkehrt
              if (mounted) _loadUsernameFromProfile();
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Profil erstellen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5), // Materie blue
            ),
          ),
        ],
      ),
    );
  }

    // if (timestamp == null) return '';
     //     // final dt = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
    // final now = DateTime.now();
    // final diff = now.difference(dt);
     //     // if (diff.inMinutes < 1) return 'Gerade eben';
    // if (diff.inHours < 1) return '${diff.inMinutes}m';
    // if (diff.inDays < 1) return '${diff.inHours}h';
    // return '${dt.day}.${dt.month}. ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  // }
  
  // ═══════════════════════════════════════════════════════════
  // 🆕 NEUE FEATURES - WEBRTC, TYPING, REACTIONS, SWIPE
  // ═══════════════════════════════════════════════════════════
  
  // 🎤 WEBRTC VOICE METHODS
  final WebRTCVoiceService _voiceService = WebRTCVoiceService();
  StreamSubscription? _voiceParticipantsSub;
  
  Future<void> _initializeWebRTC() async {
    await _voiceService.initialize();
    
    // Listen to participants (cancel in dispose)
    _voiceParticipantsSub?.cancel();
    _voiceParticipantsSub = _voiceService.participantsStream.listen((participants) {
      if (!mounted) return;
      setState(() {
        _voiceParticipants = participants.map((p) => {
          'userId': p.userId,
          'username': p.username,
          'avatarEmoji': p.avatarEmoji,
          'isSpeaking': p.isSpeaking,
          'isMuted': p.isMuted,
        }).toList();
      });
    });
  }
  
  // ignore: unused_element
  Future<void> _toggleVoiceRoom() async {
    if (_isInVoiceRoom) {
      await _voiceService.leaveVoiceRoom();
      if (mounted) {
        setState(() {
        _isInVoiceRoom = false;
        _voiceParticipants = [];
      });
      }
      _showSnackBar('🔇 Voice Room verlassen', Colors.grey);
    } else {
      // ✅ PHASE 2: Enhanced Error Handling
      try {
        final success = await _voiceService.joinVoiceRoom(
          roomId: _selectedRoom,
          userId: _userId,
          username: _username,
          world: 'materie',  // 🆕 World parameter
        );
        
        if (success) {
          if (mounted) {
            setState(() {
            _isInVoiceRoom = true;
          });
          }
          _showSnackBar('🎤 Voice Room beigetreten', Colors.red);
        } else {
          // Check for specific error
          final error = _voiceService.getLastError();
          _showSnackBar(
            error ?? '❌ Fehler beim Beitreten',
            Colors.red,
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Voice Room Join Error: $e');
        }
        
        // Show user-friendly error message
        String errorMessage = '❌ Voice Chat Fehler';
        
        if (e.toString().contains('Berechtigung')) {
          errorMessage = '🎤 Mikrofon-Berechtigung erforderlich';
        } else if (e.toString().contains('aktiviert')) {
          errorMessage = '🎤 Mikrofon konnte nicht aktiviert werden';
        }
        
        _showSnackBar(errorMessage, Colors.red);
      }
    }
  }
  
  // ignore: unused_element
  Future<void> _toggleMute() async {
    await _voiceService.toggleMute();
    if (mounted) {
      setState(() {
      _isMuted = !_isMuted;
    });
    }
    _showSnackBar(
      _isMuted ? '🔇 Stummgeschaltet' : '🎤 Mikrofon aktiv',
      Colors.red,
    );
  }
  
  // 🎤 OPEN MODERN VOICE CHAT SCREEN (Phase B - Grid Layout)
  void _openTelegramVoiceScreen() {
    if (kDebugMode) {
      debugPrint('🎤 [MODERN MATERIE] Opening Modern Voice Chat Screen (2×5 Grid)...');
    }
    
    // 🔑 Get Admin Status from Backend Role
    final storage = StorageService();
    final profile = storage.getMaterieProfile();
    final backendRole = profile?.role;  // 'root_admin', 'admin', or 'user'
    final adminLevel = AdminPermissions.getAdminLevelFromBackendRole(backendRole);
    final isAdmin = adminLevel != AdminLevel.user;
    final isRootAdmin = adminLevel == AdminLevel.rootAdmin;
    
    if (kDebugMode) {
      debugPrint('🔑 [ADMIN CHECK MATERIE]');
      debugPrint('   userId: $_userId');
      debugPrint('   backendRole: $backendRole');
      debugPrint('   adminLevel: $adminLevel');
      debugPrint('   isAdmin: $isAdmin');
      debugPrint('   isRootAdmin: $isRootAdmin');
    }
    
    // ✅ Phase A: Set admin status in Riverpod provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ProviderScope.containerOf(context).read(webrtcCallProvider.notifier);
      notifier.setAdminStatus(isAdmin, isRootAdmin);
    });
    
    // ✅ Phase B: Navigate to Modern Grid UI
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModernVoiceChatScreen(
          roomId: _selectedRoom,
          roomName: 'Materie Chat - $_selectedRoom',
          userId: _userId,
          username: _username,
          world: 'materie',  // ✅ ADD: world parameter
          accentColor: Colors.red, // Materie red
          // ✅ NO participants prop - Riverpod provider handles it!
          // ✅ NO callbacks - Riverpod notifier handles everything!
        ),
      ),
    );
  }

  
  // 🎤 VOICE ROOM BAR
  // ignore: unused_element
  Widget _buildVoiceRoomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withValues(alpha: 0.2),
            Colors.orange.withValues(alpha: 0.2),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.red.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.headset_mic, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            '${_voiceParticipants.length}/10 im Voice Room',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const Spacer(),
          // Participants Avatars
          ..._voiceParticipants.take(5).map((p) {
            return Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: p['isSpeaking'] == true 
                        ? Colors.greenAccent 
                        : Colors.grey[700],
                    child: Text(
                      p['avatarEmoji']?.toString() ?? '👤',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  if (p['isSpeaking'] == true)
                    Positioned.fill(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.greenAccent,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
          if (_voiceParticipants.length > 5)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[700],
                child: Text(
                  '+${_voiceParticipants.length - 5}',
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // ⌨️ TYPING INDICATORS
  Widget _buildTypingIndicators() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[900],
      child: Row(
        children: [
          // Animated Dots
          SizedBox(
            width: 30,
            height: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(3, (index) {
                return TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                  builder: (context, double value, child) {
                    final delay = index * 0.2;
                    final animValue = ((value + delay) % 1.0);
                    final opacity = (0.3 + (0.7 * (1 - (animValue - 0.5).abs() * 2)))
                        .clamp(0.3, 1.0);
                    
                    return Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: opacity),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _typingUsers.length == 1
                  ? '${_typingUsers.first} tippt...'
                  : _typingUsers.length == 2
                      ? '${_typingUsers.elementAt(0)} und ${_typingUsers.elementAt(1)} tippen...'
                      : '${_typingUsers.length} Personen tippen...',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  // 😀 EMOJI REACTIONS
  void _showReactionPicker(Map<String, dynamic> msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ReactionPickerSheet(
        onSelectEmoji: (emoji) => _addReaction(msg, emoji),
      ),
    );
  }
  
  void _addReaction(Map<String, dynamic> msg, String emoji) {
    if (mounted) {
      setState(() {
      // Initialize reactions map if not exists
      if (msg['reactions'] == null) {
        msg['reactions'] = <String, dynamic>{};
      }
      
      final reactions = msg['reactions'] as Map<String, dynamic>;
      
      // Initialize emoji list if not exists
      if (reactions[emoji] == null) {
        reactions[emoji] = <String>[];
      }
      
      final userList = reactions[emoji] as List<dynamic>;
      
      // Toggle reaction
      if (userList.contains(_username)) {
        userList.remove(_username);
        if (userList.isEmpty) {
          reactions.remove(emoji);
        }
        // ✅ Sync to API (remove)
        final msgId = msg['id']?.toString() ?? '';
        if (msgId.isNotEmpty) _syncReactionToApi(msgId, emoji, false);
      } else {
        userList.add(_username);
        // ✅ Sync to API (add)
        final msgId = msg['id']?.toString() ?? '';
        if (msgId.isNotEmpty) _syncReactionToApi(msgId, emoji, true);
      }
    });
    }
  }
  
  // ✏️ MESSAGE EDIT
  void _startEditingMessage(Map<String, dynamic> msg) {
    final messageId = msg['id']?.toString() ?? msg['timestamp']?.toString() ?? '';
    if (mounted) {
      setState(() {
      _editingMessageId = messageId;
    });
    }
  }
  
  void _saveEditedMessage(Map<String, dynamic> msg, String newContent) {
    if (mounted) {
      setState(() {
      msg['message'] = newContent;
      msg['edited'] = true;
      msg['editedAt'] = DateTime.now().toIso8601String();
      _editingMessageId = null;
    });
    }
    
    if (kDebugMode) {
      debugPrint('✏️ Materie: Message edited');
    }
  }
  
  void _cancelEditingMessage() {
    if (mounted) {
      setState(() {
      _editingMessageId = null;
    });
    }
  }
  
  // 🗑️ MESSAGE DELETE
  // 🔍 MESSAGE SEARCH
  void _toggleSearch() {
    if (mounted) {
      setState(() {
      _showSearch = !_showSearch;
    });
    }
  }
  
  void _jumpToMessage(Map<String, dynamic> msg) {
    final index = _messages.indexOf(msg);
    if (index == -1) return;
    
    final scrollPosition = index * 80.0;
    _scrollController.animateTo(
      scrollPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  // 🛠️ MESSAGE OPTIONS
  void _showMessageOptions(BuildContext context, Map<String, dynamic> msg) async {
    final isOwnMessage = msg['username'] == _username;
    
    // ✅ SECURE: Check admin status from Backend Role (EXACT Dashboard Match!)
    final storage = StorageService();
    final profile = storage.getMaterieProfile();
    final backendRole = profile?.role;  // 'root_admin', 'admin', or 'user'
    
    final adminLevel = AdminPermissions.getAdminLevelFromBackendRole(backendRole);
    final isAdmin = adminLevel != AdminLevel.user;
    final adminBadge = AdminPermissions.getAdminBadgeFromBackendRole(backendRole);
    
    // Admin-Rechte basierend auf Backend-Rolle
    final canDeleteAny = isAdmin;  // root_admin oder admin
    final canBan = isAdmin;        // root_admin oder admin
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (isOwnMessage) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.red),
                title: const Text('Bearbeiten', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _startEditingMessage(msg);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Löschen', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(msg);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.reply, color: Colors.red),
              title: const Text('Antworten', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _replyToMessage(msg);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_reaction, color: Colors.red),
              title: const Text('Reaktion', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showReactionPicker(msg);
              },
            ),
            
            // 🔧 ADMIN MODERATION OPTIONS (Secure check via AdminPermissions)
            if (isAdmin) ...[
              const Divider(color: Colors.orange),
              
              // ADMIN: Delete any message (if has permission)
              if (canDeleteAny && !isOwnMessage)
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: Text('Nachricht löschen $adminBadge', style: const TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(msg);  // Backend checks admin status
                  },
                ),
              
              // ADMIN: Flag Content
              if (!isOwnMessage)
                ListTile(
                  leading: const Icon(Icons.flag, color: Colors.orange),
                  title: const Text('Inhalt melden', style: TextStyle(color: Colors.orange)),
                  onTap: () {
                    Navigator.pop(context);
                    _showFlagDialog(msg);
                  },
                ),
              
              // ADMIN: Ban/Mute User
              if (canBan && !isOwnMessage)
                ListTile(
                  leading: const Icon(Icons.volume_off, color: Colors.orange),
                  title: Text('User sperren $adminBadge', style: const TextStyle(color: Colors.orange)),
                  onTap: () {
                    Navigator.pop(context);
                    _showMuteDialog(msg, canBan);
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildMessageWithReactions(Map<String, dynamic> msg) {
    final messageId = msg['id']?.toString() ?? msg['timestamp']?.toString() ?? '';
    final isEditing = _editingMessageId == messageId;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isEditing)
          Padding(
            padding: const EdgeInsets.only(left: 60, right: 16, bottom: 8),
            child: MessageEditWidget(
              message: msg,
              onSave: (newContent) => _saveEditedMessage(msg, newContent),
              onCancel: _cancelEditingMessage,
            ),
          )
        else
          GestureDetector(
            onLongPress: () => _showMessageOptions(context, msg),
            onDoubleTap: () => _addReaction(msg, '❤️'),
            child: _buildEnhancedMessageBubble(msg),
          ),
        
        if (!isEditing)
          Padding(
            padding: const EdgeInsets.only(left: 60, top: 4),
            child: MessageReactionsWidget(
              message: msg,
              onReact: (emoji) => _addReaction(msg, emoji),
              currentUsername: _username,
            ),
          ),
        // ✨ Batch-3.1: Link-Preview-Karte unter Nachrichten mit URL.
        if (!isEditing) _buildLinkPreviewRow(msg),
        // ✨ Batch-2.3: „Gelesen von N" Haken nur für eigene Nachrichten.
        if (!isEditing) _buildReadReceiptRow(msg),
      ],
    );
  }

  Widget _buildLinkPreviewRow(Map<String, dynamic> msg) {
    final text = (msg['message'] ?? msg['content'] ?? '').toString();
    if (text.isEmpty) return const SizedBox.shrink();
    final url = LinkPreviewService.firstUrl(text);
    if (url == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 60, right: 16, top: 4),
      child: ChatLinkPreviewCard(
        url: url,
        accent: const Color(0xFFE53935),
      ),
    );
  }

  Widget _buildReadReceiptRow(Map<String, dynamic> msg) {
    final msgUserId =
        msg['userId']?.toString() ?? msg['user_id']?.toString() ?? '';
    final isOwn = (msgUserId.isNotEmpty && msgUserId == _userId) ||
        (msg['username']?.toString() == _username && _username.isNotEmpty);
    if (!isOwn) return const SizedBox.shrink();
    final ts = DateTime.tryParse(
          (msg['created_at'] ?? msg['timestamp'] ?? '').toString(),
        ) ??
        DateTime.now().toUtc();
    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 2),
      child: Align(
        alignment: Alignment.centerRight,
        child: ChatReadReceiptIndicator(
          messageCreatedAt: ts.toUtc(),
          ownUserId: _userId,
        ),
      ),
    );
  }

  // 💬 SWIPE TO REPLY
  void _replyToMessage(Map<String, dynamic> msg) {
    if (mounted) {
      setState(() {
      _replyingTo = msg;
    });
    }
    _inputFocusNode.requestFocus();
  }
  
  /// 🆕 SHOW MESSAGE ACTIONS (Long-Press on own messages)
  void _showMessageActions(Map<String, dynamic> msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Bearbeiten', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _editMessage(msg);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Löschen', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(msg);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
  
  /// 🆕 EDIT MESSAGE
  Future<void> _editMessage(Map<String, dynamic> msg) async {
    final controller = TextEditingController(text: msg['message']?.toString() ?? '');
    final newText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Nachricht bearbeiten', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nachricht eingeben...',
            hintStyle: TextStyle(color: Colors.grey[600]),
            border: const OutlineInputBorder(),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    
    if (newText != null && newText.trim().isNotEmpty && newText != msg['message']) {
      final trimmed = newText.trim();
      final msgId = msg['message_id'] ?? msg['id'] ?? '';

      // ✅ OPTIMISTIC UPDATE: Sofort lokal aktualisieren
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => (m['message_id'] ?? m['id']) == msgId);
          if (idx != -1) {
            _messages[idx] = {
              ..._messages[idx],
              'message': trimmed,
              'content': trimmed,
              'edited_at': DateTime.now().toIso8601String(),
            };
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Nachricht bearbeitet'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Server-Update im Hintergrund (fire-and-forget mit Retry)
      _api.editChatMessage(
        messageId: msgId,
        roomId: _fullRoomId,
        realm: 'materie',
        newMessage: trimmed,
        userId: _userId,
        username: _username,
      ).then((_) {
        if (kDebugMode) debugPrint('✅ Edit erfolgreich gespeichert');
        // Realtime-UPDATE-Handler synct andere Clients; kein Reload nötig.
      }).catchError((e) {
        if (kDebugMode) debugPrint('⚠️ Edit server error (optimistic update bleibt): $e');
      });
    }
  }
  
  /// 🆕 DELETE MESSAGE
  Future<void> _deleteMessage(Map<String, dynamic> msg) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Nachricht löschen?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Diese Aktion kann nicht rückgängig gemacht werden.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final msgId = msg['message_id'] ?? msg['id'] ?? '';

      // ✅ OPTIMISTIC UPDATE: Sofort lokal löschen
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => (m['message_id'] ?? m['id']) == msgId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Nachricht gelöscht'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Server-Update im Hintergrund
      _api.deleteChatMessage(
        messageId: msgId,
        roomId: _fullRoomId,
        realm: 'materie',
        userId: _userId,
        username: _username,
      ).then((_) {
        if (kDebugMode) debugPrint('✅ Delete erfolgreich gespeichert');
      }).catchError((e) {
        if (kDebugMode) debugPrint('⚠️ Delete server error (optimistic delete bleibt): $e');
        // Fehler ignorieren – Nachricht bleibt lokal gelöscht
      });
    }
  }
  
  Widget _buildReplyPreview() {
    if (_replyingTo == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(
            color: Colors.red,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Antwort an ${_replyingTo!['username']}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _replyingTo!['message']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () {
              if (mounted) {
                setState(() {
                _replyingTo = null;
              });
              }
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSwipeableMessage(Map<String, dynamic> msg) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Dismissible(
        key: Key(msg['id']?.toString() ?? msg['timestamp']?.toString() ?? '${DateTime.now().millisecondsSinceEpoch}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          _replyToMessage(msg);
          return false;
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: Colors.transparent,
          child: const Icon(
            Icons.reply,
            color: Colors.grey,
            size: 28,
          ),
        ),
        child: _buildMessageWithReactions(msg),
      ),
    );
  }
  
  // 🆕 ENHANCED MESSAGE BUBBLE (Modern Design)
  Widget _buildEnhancedMessageBubble(Map<String, dynamic> msg) {
    // ✅ isOwn: vergleiche userId (camelCase) und user_id (snake_case) + username als Fallback
    final msgUserId = msg['userId']?.toString() ?? msg['user_id']?.toString() ?? '';
    final isOwn = (msgUserId.isNotEmpty && msgUserId == _userId) ||
        (msg['username']?.toString() == _username && _username.isNotEmpty);
    
    return Padding(
      padding: EdgeInsets.only(
        left: isOwn ? 60 : 12,
        right: isOwn ? 12 : 60,
        bottom: 8,
      ),
      child: Row(
        mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar (nur bei anderen)
          if (!isOwn) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.red.withValues(alpha: 0.2),
              child: Text(
                msg['avatarEmoji']?.toString() ?? '👤',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Bubble mit Tail
          Flexible(
            child: InkWell(
              onLongPress: isOwn ? () => _showMessageActions(msg) : null,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                color: isOwn ? Colors.red : Colors.grey[800],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isOwn ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isOwn ? const Radius.circular(4) : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username (nur bei anderen)
                  if (!isOwn)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        msg['username']?.toString() ?? 'Unbekannt',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  
                  // 🎤 VOICE MESSAGE or 📷 IMAGE or 💬 TEXT
                  if (msg['mediaType'] == 'voice' || (msg['message']?.toString().startsWith('🎤 Sprachnachricht') == true && msg['mediaUrl'] != null))
                    // 🎵 VOICE MESSAGE PLAYER
                    ChatVoicePlayer(
                      audioUrl: msg['mediaUrl'] ?? '',
                      duration: Duration(seconds: int.tryParse(
                        msg['message']?.toString()
                          .replaceAll('🎤 Sprachnachricht (', '')
                          .replaceAll('s)', '')
                          .replaceAll(')', '') ?? '0'
                      ) ?? 0),
                      accentColor: const Color(0xFF2196F3),
                    )
                  else if (msg['mediaType'] == 'image' && msg['mediaUrl'] != null)
                    // Image Message
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        msg['mediaUrl'],
                        width: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 150,
                            color: Colors.grey[700],
                            child: const Icon(Icons.broken_image, size: 48),
                          );
                        },
                      ),
                    )
                  else
                    // Regular Text Message (Markdown-Light + klickbare Links)
                    ChatMarkdownText(
                      msg['message']?.toString() ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                  
                  const SizedBox(height: 4),
                  
                  // Timestamp & Status
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(msg['timestamp'] ?? msg['created_at']),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                      if (isOwn) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 14,
                          color: msg['read'] == true 
                              ? Colors.blue 
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ), // Container
            ), // InkWell
          ), // Flexible
        ],
      ),
    );
  }
  
  String _formatTime(dynamic timestamp) {
    try {
      if (timestamp == null) return '';
      
      DateTime dt;
      if (timestamp is int) {
        dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is String) {
        dt = DateTime.parse(timestamp);
      } else {
        return '';
      }
      
      final now = DateTime.now();
      final diff = now.difference(dt);
      
      if (diff.inMinutes < 1) return 'Jetzt';
      if (diff.inHours < 1) return '${diff.inMinutes}m';
      if (diff.inDays < 1) return '${diff.inHours}h';
      return '${dt.day}.${dt.month}. ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
  
  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  // 🔧 ADMIN MODERATION METHODS
  
  /// 🚩 FLAG DIALOG: Report content for moderation
  void _showFlagDialog(Map<String, dynamic> msg) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Inhalt melden', style: TextStyle(color: Colors.orange)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nachricht: "${msg['message'] ?? ''}"',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Grund der Meldung (optional)',
                hintStyle: TextStyle(color: Colors.white38),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                final moderation = ModerationService();
                await moderation.flagContent(
                  world: 'materie',
                  contentType: 'comment',
                  contentId: msg['id']?.toString() ?? '',
                  reason: reasonController.text.trim(),
                  adminToken: _username,
                );
                
                if (mounted) {
                  _showSnackBar('✅ Inhalt wurde gemeldet', Colors.green);
                }
              } catch (e) {
                if (mounted) {
                  _showSnackBar('❌ Fehler beim Melden: $e', Colors.red);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Melden'),
          ),
        ],
      ),
    );
  }
  
  /// 🗑️ ADMIN DELETE: Root admin can delete any message
  // ignore: unused_element
  void _adminDeleteMessage(Map<String, dynamic> msg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Nachricht löschen (Admin)', style: TextStyle(color: Colors.red)),
        content: Text(
          'Nachricht von ${msg['username']}: "${msg['message'] ?? ''}"',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final messageId = msg['id']?.toString() ?? msg['message_id']?.toString() ?? '';

      // ✅ OPTIMISTIC UPDATE: Sofort lokal entfernen
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) =>
              m['id']?.toString() == messageId ||
              m['message_id']?.toString() == messageId);
        });
        _showSnackBar('✅ Nachricht wurde gelöscht', Colors.green);
      }

      // Server-Update im Hintergrund
      if (messageId.isNotEmpty) {
        _api.deleteChatMessage(
          messageId: messageId,
          roomId: _fullRoomId,
          userId: _userId,
          username: _username,
          realm: 'materie',
          isAdmin: true,
        ).then((_) {
          if (kDebugMode) debugPrint('✅ Materie Admin-Delete gespeichert');
        }).catchError((e) {
          if (kDebugMode) debugPrint('⚠️ Materie Admin-Delete server error: $e');
        });
      }
    }
  }
  
  /// 🔇 MUTE DIALOG: Temporarily or permanently mute user
  void _showMuteDialog(Map<String, dynamic> msg, bool isRootAdmin) {
    final reasonController = TextEditingController();
    String muteType = '24h'; // Default: 24h
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('User sperren', style: TextStyle(color: Colors.orange)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User: ${msg['username']}',
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Mute Type Selector
              const Text('Sperrdauer:', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: muteType,
                onChanged: (value) {
                  if (mounted && value != null) {
                    setState(() {
                      muteType = value;
                    });
                  }
                },
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('24 Stunden', style: TextStyle(color: Colors.white, fontSize: 14)),
                        value: '24h',
                        activeColor: Colors.orange,
                      ),
                    ),
                    if (isRootAdmin)
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Permanent', style: TextStyle(color: Colors.white, fontSize: 14)),
                          value: 'permanent',
                          activeColor: Colors.red,
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Grund (optional)',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                
                try {
                  final targetUserId = 'materie_${msg['username']}'; // Construct user_id
                  final moderation = ModerationService();
                  
                  await moderation.muteUser(
                    world: 'materie',
                    userId: targetUserId,
                    username: msg['username'] ?? '',
                    muteType: muteType,
                    reason: reasonController.text.trim(),
                    adminToken: _username,
                  );
                  
                  if (mounted) {
                    final durationText = muteType == '24h' ? '24 Stunden' : 'permanent';
                    _showSnackBar('✅ User ${msg['username']} für $durationText gesperrt', Colors.green);
                  }
                } catch (e) {
                  if (mounted) {
                    _showSnackBar('❌ Fehler beim Sperren: $e', Colors.red);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: muteType == 'permanent' ? Colors.red : Colors.orange,
              ),
              child: const Text('Sperren'),
            ),
          ],
        ),
      ),
    );
  }
}

