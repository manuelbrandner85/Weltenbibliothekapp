import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // kDebugMode
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'dart:io'; // File for uploads
import '../../config/api_config.dart';
import '../shared/livekit_group_call_screen.dart';
import '../../services/supabase_service.dart'; // 🔥 supabase client für Auth
import 'package:supabase_flutter/supabase_flutter.dart' show RealtimeChannel;
// Removed: dart:convert (unused after FIX 15)
// Removed: package:http (unused after FIX 15)
import 'package:image_picker/image_picker.dart'; // Image Picker
import '../../services/cloudflare_api_service.dart';
import '../../services/offline_sync_service.dart'; // 📡 OFFLINE SYNC (NEW Phase 3)
import '../../services/user_service.dart';
import '../../services/storage_service.dart'; // StorageService for profile access
import '../../core/storage/unified_storage_service.dart'; // UnifiedStorageService
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod
import '../../services/profile_sync_service.dart'; // 🔥 BACKEND SYNC
import '../../models/energie_profile.dart';
import '../shared/profile_editor_screen.dart'; // ✅ Profile Editor
import '../../services/moderation_service.dart'; // 🔧 ADMIN MODERATION
import '../../services/admin_permissions.dart'; // 🔐 ADMIN SYSTEM
import '../../widgets/error_display_widget.dart'; // 🎨 ERROR DISPLAY (NEW)
import 'crystal_library_screen.dart'; // 💠 Kristall-Bibliothek Screen
import 'meditation_timer_screen.dart'; // 🧘 Meditation Timer Screen
import 'astral_journal_screen.dart'; // 🌙 Astrales Tagebuch Screen
import 'chakra_scan_screen.dart'; // 💎 Chakra Scan Screen
import 'dream_journal_screen.dart'; // 💫 Traum-Tagebuch Screen
import 'frequency_session_screen.dart'; // 🎵 Frequenz-Sessions Screen
import '../../widgets/enhanced_message_bubble.dart'; // 💬 Enhanced Message Bubble
import '../../widgets/message_reactions_widget.dart'; // 😀 Message Reactions
import '../../widgets/message_edit_widget.dart'; // ✏️ Message Edit
// 🗑️ Message Delete
import '../../widgets/message_search_widget.dart'; // 🔍 Message Search
// 📁 File Upload
// 👁️ Read Receipts
// 🎤 Voice Messages
import '../../widgets/android_voice_recorder.dart'; // 🎤 Android Voice Recorder (flutter_sound)
import '../../widgets/poll_widget.dart'; // 🗳️ Poll Widget
import '../../widgets/pinned_message_banner.dart'; // 📌 Pinned Message Banner
// Voice-Imports entfernt — WebRTC wird durch LiveKit ersetzt.
// LiveKit-UI kommt im Folge-PR; Voice-Button zeigt vorerst Coming-Soon-Hinweis.
// 🎤 Admin Dialogs & Notifications
// 🚫 Kick User Dialog
// 🔴 Ban User Dialog
// ⚠️ Warning Dialog
// 📢 Admin Notifications
// 📋 Admin Action Models
// import '../../widgets/telegram_voice_recorder.dart'; // 🎙️ Telegram Voice Recorder (Disabled for Android)
// 🎵 Telegram Voice Player
import '../../widgets/voice_message_player.dart' show ChatVoicePlayer; // 🎤 Chat Voice Player (New)
import '../../widgets/mention_autocomplete.dart'; // @ Mentions
// import '../../widgets/voice_record_button.dart'; // 🎤 Voice Recording (Android disabled)
// webrtc_voice_service entfernt — siehe livekit_call_service.dart
import '../../services/typing_indicator_service.dart'; // ⌨️ Typing Indicator
// REMOVED: import '../../widgets/voice_chat_banner.dart'; (unused)
import '../../widgets/offline_indicator.dart'; // 📡 OFFLINE INDICATOR (NEW Phase 3)
// ✨ Batch-1 Chat-Erweiterungen
import '../../widgets/chat/chat_markdown_text.dart';
import '../../widgets/chat/chat_emoji_picker_button.dart';
import '../../widgets/chat/chat_status_banner.dart';
import '../../widgets/chat/chat_new_messages_fab.dart';
import '../../widgets/chat/chat_unread_badge.dart';
import '../../widgets/chat/chat_room_info_sheet.dart';
import '../../widgets/chat/chat_read_receipt_indicator.dart';
import '../../widgets/chat/chat_link_preview_card.dart';
import '../../widgets/chat/bouncing_dots_bubble.dart';
import '../../widgets/chat/chat_image_viewer.dart';
import '../../services/chat/presence_service.dart';
import '../../services/chat/read_receipt_service.dart';
import '../../services/chat/link_preview_service.dart';
import '../../services/chat/chat_rate_limit_service.dart';
import '../../services/haptic_feedback_service.dart';
import '../../services/chat/chat_word_filter_service.dart';
import '../../services/chat/chat_draft_service.dart';
import '../../services/chat/recent_rooms_service.dart';
import '../../services/chat/mention_notification_service.dart';
import '../../services/chat/user_block_service.dart';
import '../../services/chat/unread_tracker_service.dart';
// 📷 Image Picker

/// ✅ EINFACHER ENERGIE LIVE CHAT - MIT ALLEN 11 FEATURES!
class EnergieLiveChatScreen extends StatefulWidget {
  final String? initialRoom;
  
  const EnergieLiveChatScreen({super.key, this.initialRoom});

  @override
  State<EnergieLiveChatScreen> createState() => _EnergieLiveChatScreenState();
}

class _EnergieLiveChatScreenState extends State<EnergieLiveChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final CloudflareApiService _api = CloudflareApiService();
  // ignore: unused_field
  final UserService _userService = UserService();
  final ScrollController _scrollController = ScrollController();
  final TypingIndicatorService _typingService = TypingIndicatorService(); // ⌨️ NEW
  
  late String _selectedRoom;
  
  /// Maps internal room key → DB room ID (energie world)
  static const Map<String, String> _roomIdMap = {
    'meditation': 'energie-meditation',
    'astralreisen': 'energie-traeume',   // Map to closest existing room
    'chakren': 'energie-chakra',
    'chakra': 'energie-chakra',
    'spiritualitaet': 'energie-bewusstsein', // Map to closest existing room
    'bewusstsein': 'energie-bewusstsein',
    'heilung': 'energie-heilung',
    'astrologie': 'energie-astrologie',
    'kristalle': 'energie-kristalle',
    'kraftorte': 'energie-kraftorte',
    'traeume': 'energie-traeume',
    'traumarbeit': 'energie-traeume',
    'frequenzen': 'energie-heilung',     // Map to closest existing room
  };
  
  /// Returns the full DB room ID for the currently selected room.
  String get _fullRoomId => _roomIdMap[_selectedRoom] ?? 'energie-$_selectedRoom';
  String _username = ''; // ✅ Leer bis Profil geladen
  String _avatar = '👤';
  String? _avatarUrl; // 🖼️ Hochgeladenes Profilbild (PRIORITÄT!)
  late String _userId; // 🔥 Real User ID from UserService (initialized in initState)
  
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _polls = []; // 🆕 Polls list
  bool _isLoading = false;
  String? _errorMessage; // 🎨 NEW: Error state
  bool _isSending = false;
  Timer? _refreshTimer;
  StreamSubscription<int>? _pendingSub;
  
  // 🆕 MENTIONS & MEDIA
  List<String> _mentionSuggestions = [];
  bool _showMentionPicker = false;
  final FocusNode _inputFocusNode = FocusNode();
  bool _isInputFocused = false; // 🔧 FIX 10: Explicit focus state for reliable hiding
  
  // 🎤➤ DYNAMIC BUTTON STATE
  bool _hasText = false; // true = Send Button, false = Voice Button
  
  // ⏳ Voice-Room-Migration WebRTC → LiveKit. UI kommt im Folge-PR.
  // Voice-Button zeigt vorerst Coming-Soon-SnackBar.
  
  // 🆕 ADMIN ACTION SERVICE
  
  // 🆕 FEATURE 2: TYPING INDICATORS
  final Set<String> _typingUsers = {};
  Timer? _typingTimer;

  // Feature #17: Smart replies
  List<String> _smartReplies = [];

  // Feature #16: Message scheduler
  final List<(DateTime, String)> _scheduledMessages = [];
  final List<Timer> _scheduledTimers = [];
  
  // 🆕 FEATURE 3: SWIPE TO REPLY
  Map<String, dynamic>? _replyingTo;
  // ignore: unused_field
  Map<String, dynamic>? _replyToMessageData; // Highlight indicator for scroll-to-message

  // 🆕 FEATURE 4: EMOJI REACTIONS
  // ignore: unused_field
  final Map<String, Map<String, List<String>>> _messageReactions = {}; // messageId -> emoji -> userIds
  
  // 🆕 PHASE 2: MESSAGE EDIT/DELETE/SEARCH
  String? _editingMessageId;
  bool _showSearch = false;
  
  // 🆕 PHASE 3: FILE UPLOAD & VOICE MESSAGES
  // ignore: unused_field
  File? _selectedFile;
  // ignore: unused_field
  String? _selectedFileType;
  
  // ✅ PROFIL-DIALOG FLAG: Verhindert mehrfaches Anzeigen
  bool _profileDialogShown = false;
  
  // 🔴 SUPABASE REALTIME: Live-Subscription für neue Nachrichten
  RealtimeChannel? _realtimeChannel;

  // ✨ Batch-1: Smart autoscroll + pagination + reconnect-state
  bool _isAtBottom = true;
  int _newMessagesCount = 0;
  bool _loadingOlder = false;
  bool _hasMoreOlder = true;
  bool _reconnecting = false;

  // ✨ Chat UX Redesign: Animationen + Mood + Sync-Timer
  late AnimationController _headerAuraCtrl;
  late AnimationController _headerOrbitCtrl;
  String _myMood = '';
  bool _showMoodPicker = false;
  bool _meditationSyncActive = false;
  int _meditationSyncSeconds = 0;
  Timer? _meditationSyncTimer;
  
  // 🔧 FIX 13: ENERGIE Räume reduziert auf 5 (Option C - Ausgewogen)
  // 🔧 FIX 17: ENERGIE Räume - API-kompatible IDs
  final Map<String, Map<String, dynamic>> _rooms = {
    'meditation': {
      'name': '🧘 Meditation & Achtsamkeit',
      'description': 'Gemeinsame Meditation & Atemtechniken',
      'icon': '🧘',
      'tool': 'Gruppen-Meditation Timer',
      'toolDescription': 'Gemeinsam meditieren mit synchronisiertem Timer',
    },
    'astralreisen': {
      'name': '🌌 Astralreisen & Träume',
      'description': 'Außerkörperliche Erfahrungen & Luzide Träume',
      'icon': '🌌',
      'tool': 'Astrales Tagebuch (Shared)',
      'toolDescription': 'Gemeinsame Astralreisen dokumentieren',
    },
    'chakren': {
      'name': '🔥 Kundalini & Chakren',
      'description': 'Chakra-Heilung & Kundalini-Energie',
      'icon': '🔥',
      'tool': 'Chakra-Scan (Gemeinsam)',
      'toolDescription': 'Gegenseitige Energie-Analysen',
    },
    'spiritualitaet': {
      'name': '🔮 Spiritualität & Mystik',
      'description': 'Mystische Erfahrungen, Erleuchtung, Bewusstsein',
      'icon': '🔮',
      'tool': 'Bewusstseins-Journal',
      'toolDescription': 'Gemeinsame spirituelle Erfahrungen dokumentieren',
    },
    'heilung': {
      'name': '💫 Energieheilung & Reiki',
      'description': 'Energiearbeit, Reiki, Fernheilung',
      'icon': '💫',
      'tool': 'Heilungs-Kreis (Remote)',
      'toolDescription': 'Gemeinsame Heilungs-Sessions & Energie senden',
    },
  };

  @override
  void initState() {
    super.initState();

    // ✨ Chat UX Redesign: Header-Animationen starten
    _headerAuraCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _headerOrbitCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();

    // 🔥 Initialize User ID from UserService
    _userId = UserService.getCurrentUserId();

    // 🔧 FIX 18: Set initial room from dashboard navigation
    _selectedRoom = widget.initialRoom ?? 'meditation';
    RecentRoomsService.instance.touch('energie', _selectedRoom);

    // 🎥 Voice-Service: WebRTC → LiveKit Migration läuft. Init geschieht
    // jetzt via LiveKitCallService.joinRoom() beim User-Klick auf Voice-Button.

    // 🆕 Listen for @ mentions
    _messageController.addListener(_onInputChanged);
    
    // 🔧 FIX 10: Listen for input focus changes with explicit state
    _inputFocusNode.addListener(() {
      if (mounted) {
        setState(() {
        _isInputFocused = _inputFocusNode.hasFocus;
      });
      }
    });
    
    // ✨ Batch-1: Scroll-Listener für at-bottom Detection + Pagination
    _scrollController.addListener(_onScroll);

    // ✨ Batch-1: Beim ersten Öffnen Raum als gesehen markieren.
    UnreadTrackerService.instance.markSeen(_fullRoomId);

    // 🔴 SUPABASE REALTIME: Echtzeit-Subscription starten (sofort, parallel zu Profil-Load)
    _subscribeToRoom(_fullRoomId);

    // 📡 Pending-Cleanup: Wenn alle Queue-Einträge synced sind, entferne
    //    die lokalen Pending-Platzhalter — echte Server-Nachrichten kommen
    //    via Realtime rein.
    _pendingSub = OfflineSyncService().pendingActionsStream.listen((count) {
      if (count == 0 && mounted) {
        final hadPending = _messages.any(
          (m) => m['id']?.toString().startsWith('pending_') == true,
        );
        if (hadPending) {
          setState(() {
            _messages.removeWhere(
              (m) => m['id']?.toString().startsWith('pending_') == true,
            );
          });
          _loadMessages(silent: true);
        }
      }
    });

    // 🔄 Auto-Refresh alle 30 Sekunden als Fallback (Realtime ist primär)
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadMessages(silent: true);
      _loadUserData(); // 🆕 Profil-Sync
      _loadPolls(silent: true); // 🆕 Polls-Sync
    });

    // Profil VOR Nachrichten laden → Username ist garantiert gesetzt wenn User schreibt.
    // addPostFrameCallback stellt sicher dass der erste Frame gebaut ist.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _loadUserData();
      if (!mounted) return;
      // ✨ Batch-2: Presence aktivieren, sobald der Username bekannt ist.
      await _refreshPresence();
      if (!mounted) return;
      // ✨ Batch-2.3: Read-Receipts für den Raum streamen + markieren.
      await ReadReceiptService.instance.watchRoom(_fullRoomId);
      if (!mounted) return;
      await _markRoomRead();
      if (!mounted) return;
      await _loadMessages();
      if (!mounted) return;
      _loadPolls();
    });
  }

  // ✨ Batch-2.3: Eigenen Receipt für aktuellen Raum bumpen.
  Future<void> _markRoomRead() async {
    if (_userId.isEmpty) return;
    // Server-Call nur sinnvoll mit echter Session (RLS auth.uid()=user_id).
    await ReadReceiptService.instance.markRead(
      roomId: _fullRoomId,
      userId: _userId,
    );
  }

  // didChangeDependencies removed – profile loading happens once in initState.

  Future<void> _loadUserData() async {
    EnergieProfile? energieProfile;
    try {
      final storage = StorageService();
      energieProfile = storage.getEnergieProfile();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ _loadUserData Fehler: $e');
      // Fall through – profile stays null → dialog will be shown
    }

    if (energieProfile != null && energieProfile.username.isNotEmpty) {
      if (mounted) {
        setState(() {
          _username = energieProfile!.username;
          _avatar = energieProfile.avatarEmoji ?? '🔮';
          _avatarUrl = energieProfile.avatarUrl;
          _userId = supabase.auth.currentUser?.id ?? 'user_${energieProfile.username.toLowerCase()}';
        });
      }
      // Sync into user_data box so AdminStateNotifier can find it
      try {
        final unified = UnifiedStorageService();
        await unified.saveProfile('energie', {
          'username': energieProfile.username,
          'role': energieProfile.role ?? 'user',
          'avatar_emoji': energieProfile.avatarEmoji,
          'avatar_url': energieProfile.avatarUrl,
        });
      } catch (_) {}
      if (kDebugMode) {
        debugPrint('✅ Energie-Profil geladen: ${energieProfile.username} (role: ${energieProfile.role})');
      }
      // ✅ Flag NICHT zurücksetzen – verhindert Popup bei Rückkehr
    } else {
      // Kein Profil → Popup (nur einmal)
      if (kDebugMode) debugPrint('⚠️ Kein Energie-Profil gefunden – zeige Profil-Dialog');
      if (!_profileDialogShown && mounted) {
        _profileDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showProfileRequiredDialog();
        });
      }
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
      final messages = await _api.getChatMessages(
        _fullRoomId, // 'energie-meditation' etc.
        realm: 'energie',
        limit: 50,
      );
      
      // 🔧 DEBUG: Log message count
      debugPrint('✅ ENERGIE Chat loaded: ${messages.length} messages for room $_selectedRoom');
      if (messages.isNotEmpty) {
        debugPrint('🔍 First message: ${messages.first}');
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
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      debugPrint('❌ ENERGIE Chat Load Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString(); // Store error for ErrorDisplayWidget
        });
      }
    }
  }
  
  // 🆕 Load polls for current room
  Future<void> _loadPolls({bool silent = false}) async {
    try {
      final polls = await _api.getPolls(_fullRoomId);
      if (mounted) {
        setState(() => _polls = polls);
      }
    } catch (e) {
      if (!silent) {
        debugPrint('❌ Load polls error: $e');
      }
    }
  }
  
  // 🆕 MENTIONS DETECTION
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
    
    // 🆕 SEND TYPING INDICATOR
    if (text.trim().isNotEmpty) {
      _sendTypingIndicator();
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

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    // 🚨 USERNAME-CHECK: Verhindere Senden ohne Profil
    if (_username.isEmpty) {
      if (mounted) {
        _showProfileRequiredDialog();
      }
      return;
    }

    // 🛑 Batch-4: Word-Filter (Client-Side)
    final badWord = ChatWordFilterService.instance.firstHit(message);
    if (badWord != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Nachricht enthält ein blockiertes Wort: "${badWord.trim()}"',
            ),
            backgroundColor: const Color(0xFF7C4DFF),
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
            backgroundColor: const Color(0xFF7C4DFF),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    ChatRateLimitService.instance.recordSend(_fullRoomId);
    HapticFeedbackService().messageSent();

    setState(() => _isSending = true);
    
    try {
      // 📡 OFFLINE-FIRST: Check network status
      final offlineService = OfflineSyncService();
      final isOnline = offlineService.isOnline;
      
      if (!isOnline) {
        // Queue message for later — _fullRoomId, damit beim Replay derselbe
        // Raum getroffen wird wie online (z.B. 'energie-meditation' statt
        // 'meditation').
        final queueId = await offlineService.queueAction(
          type: OfflineActionType.sendMessage,
          data: {
            'roomId': _fullRoomId,
            'realm': 'energie',
            'userId': _userId,
            'username': _username,
            'message': message,
            'avatarEmoji': _avatar,
          },
          userId: _userId,
        );

        // Optimistisches Einfügen mit Pending-Flag → User sieht seine Nachricht
        // mit Clock-Icon. Cleanup passiert wenn pendingActionsStream auf 0 geht.
        final pendingMsg = {
          'id': 'pending_$queueId',
          'room_id': _fullRoomId,
          'user_id': _userId,
          'username': _username,
          'message': message,
          'content': message,
          'avatar_emoji': _avatar,
          'avatar_url': _avatarUrl,
          'timestamp': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'is_pending': true,
        };
        if (mounted) {
          setState(() {
            _messages.add(pendingMsg);
            _replyingTo = null;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }

        _messageController.clear();
        ChatDraftService.instance.clear(_fullRoomId);
        return;
      }
      
      // Online: Send directly via Supabase
      final replyData = _replyingTo;
      final serverMsg = await _api.sendChatMessage(
        roomId: _fullRoomId, // 'energie-meditation' etc.
        realm: 'energie',
        userId: _userId,
        username: _username,
        message: message,
        avatarEmoji: _avatar,
        avatarUrl: _avatarUrl,
        replyToId: replyData?['id']?.toString(),
        replyToContent: replyData?['message']?.toString()
            ?? replyData?['content']?.toString(),
        replyToSenderName: replyData?['username']?.toString(),
      );

      _messageController.clear();
      ChatDraftService.instance.clear(_fullRoomId);

      // 🔴 Optimistic add – Realtime-Subscription deduplicated via ID.
      //    Verhindert Flicker durch redundanten Full-Reload.
      if (mounted) {
        setState(() {
          final exists = _messages.any((m) => m['id'] == serverMsg['id']);
          if (!exists) _messages.add(serverMsg);
          // Reply-Kontext nach erfolgreichem Senden schließen.
          _replyingTo = null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Energie Chat] Senden fehlgeschlagen: $e');
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
            content: Text('❌ $msg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// 🎤 SEND VOICE MESSAGE
  Future<void> _sendVoiceMessage(String audioUrl, Duration duration) async {
    try {
      // Send voice message with media_type
      final serverMsg = await _api.sendChatMessage(
        roomId: _fullRoomId, // 'energie-meditation' etc.
        realm: 'energie',
        userId: _userId,
        username: _username,
        message: '🎤 Sprachnachricht (${duration.inSeconds}s)',
        avatarEmoji: _avatar,
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
        debugPrint('✅ Voice message sent: $audioUrl');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎤 Sprachnachricht gesendet (${duration.inSeconds}s)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Voice message error: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler beim Senden: $e'),
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
                  backgroundColor: Color(0xFF9B51E0),
                  duration: Duration(seconds: 30),
                ),
              );
            }

            // Upload to Cloudflare
            final audioUrl = await _api.uploadVoiceMessage(
              filePath: audioPath,
              userId: _userId,
              roomId: _selectedRoom,
              realm: 'energie',
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
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 75,
      );
      
      if (image == null) return;
      
      // Read file bytes for preview
      final bytes = await image.readAsBytes();
      
      // 🖼️ SHOW IMAGE PREVIEW DIALOG
      if (mounted) {
        final shouldUpload = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF0D0D1A),
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
                  backgroundColor: const Color(0xFF9B51E0),
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
          roomId: _fullRoomId, // 'energie-meditation' etc.
          realm: 'energie',
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

    // if (timestamp == null) return '';
    // try {
      // final dt = DateTime.parse(timestamp);
      // final now = DateTime.now();
      // final diff = now.difference(dt);
       //       // if (diff.inMinutes < 1) return 'Gerade eben';
      // if (diff.inMinutes < 60) return 'vor ${diff.inMinutes}m';
      // if (diff.inHours < 24) return 'vor ${diff.inHours}h';
      // return 'vor ${diff.inDays}d';
    // } catch (e) {
      // return timestamp;
    // }
  // }

  /// 🔧 NACHRICHT BEARBEITEN/LÖSCHEN MENÜ
    // showModalBottomSheet(
      // context: context,
      // backgroundColor: const Color(0xFF1A1A2E),
      // shape: const RoundedRectangleBorder(
        // borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      // ),
      // builder: (context) {
        // return Container(
          // padding: const EdgeInsets.all(24),
          // child: Column(
            // mainAxisSize: MainAxisSize.min,
            // children: [
              // Bearbeiten
              // ListTile(
                // leading: const Icon(Icons.edit, color: Colors.blue),
                // title: const Text('Bearbeiten', style: TextStyle(color: Colors.white)),
                // onTap: () {
                  // Navigator.pop(context);
                  // _editMessage(messageId, currentText);
                // },
              // ),
              // const Divider(color: Colors.white24),
              // Löschen
              // ListTile(
                // leading: const Icon(Icons.delete, color: Colors.red),
                // title: const Text('Löschen', style: TextStyle(color: Colors.white)),
                // onTap: () {
                  // Navigator.pop(context);
                  // _deleteMessage(messageId);
                // },
              // ),
              // const SizedBox(height: 16),
              // Abbrechen
              // TextButton(
                // onPressed: () => Navigator.pop(context),
                // child: const Text('Abbrechen', style: TextStyle(color: Colors.white54)),
              // ),
            // ],
          // ),
        // );
      // },
    // );
  // }

  /// ✏️ NACHRICHT BEARBEITEN

  /// 🎨 AVATAR-PICKER
  Future<void> _showAvatarPicker() async {
    final avatars = ['🔮', '💎', '🧘', '🌙', '✨', '⚡', '🌈', '🔥', '💫', '🌟', '🦋', '🐉', '👤', '🎭', '🎨'];
    
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
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
                '🎨 Wähle deinen Avatar',
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
                          colors: [Color(0xFF9B51E0), Color(0xFF6A5ACD)],
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
      setState(() => _avatar = selected);
      
      // 💾 Speichere in Profil
      final storage = StorageService();
      final energieProfile = storage.getEnergieProfile();
      if (energieProfile != null) {
        // Update Energie-Profil mit neuem Avatar
        final updated = EnergieProfile(
          username: energieProfile.username,
          firstName: energieProfile.firstName,
          lastName: energieProfile.lastName,
          birthDate: energieProfile.birthDate,
          birthPlace: energieProfile.birthPlace,
          birthTime: energieProfile.birthTime,
          avatarUrl: energieProfile.avatarUrl,
          bio: energieProfile.bio,
          avatarEmoji: selected, // 🆕 Neuer Avatar
          userId: energieProfile.userId, // 🔥 FIX: Behalte userId
          role: energieProfile.role, // 🔥 FIX: Behalte role
        );
        
        // 🔥 FIX: Backend-Sync durchführen um role zu bewahren
        final syncService = ProfileSyncService();
        final syncedProfile = await syncService.saveEnergieProfileAndGetUpdated(updated);
        
        if (syncedProfile != null) {
          await storage.saveEnergieProfile(syncedProfile);
          if (kDebugMode) {
            debugPrint('✅ Avatar-Emoji gespeichert mit Backend-Sync');
            debugPrint('   Role: ${syncedProfile.role}');
          }
        } else {
          // Fallback: Lokales Profil speichern
          await storage.saveEnergieProfile(updated);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Avatar geändert: $selected'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    }
  }

  /// 🛠️ GRUPPEN-TOOL ANZEIGEN
  // ignore: unused_element
  void _showGroupTool() {
    final room = _rooms[_selectedRoom]!;
    
    // ✅ NAVIGATION ZU ECHTEN TOOL-SCREENS
    if (_selectedRoom == 'meditation') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MeditationTimerScreen(roomId: _selectedRoom),
        ),
      );
      return;
    }
    
    if (_selectedRoom == 'astralreisen') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AstralJournalScreen(roomId: _selectedRoom),
        ),
      );
      return;
    }
    
    if (_selectedRoom == 'chakra') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChakraScanScreen(roomId: _selectedRoom),
        ),
      );
      return;
    }
    
    if (_selectedRoom == 'kristalle') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CrystalLibraryScreen(roomId: _selectedRoom),
        ),
      );
      return;
    }
    
    if (_selectedRoom == 'traumarbeit') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DreamJournalScreen(roomId: _selectedRoom),
        ),
      );
      return;
    }
    
    if (_selectedRoom == 'frequenzen') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FrequencySessionScreen(roomId: _selectedRoom),
        ),
      );
      return;
    }
    
    // 🚧 Fallback: Info-Dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Row(
          children: [
            Text(
              room['icon'],
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room['tool'],
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    room['name'],
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                room['toolDescription'],
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              
              // 🚀 GEMEINSAME FUNKTIONEN
              const Text(
                '🌐 Gemeinsame Funktionen:',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildToolFeature('👥', 'Echtzeit-Synchronisation', 'Alle Teilnehmer sehen Updates sofort'),
              _buildToolFeature('💾', 'Gemeinsamer Speicher', 'Daten für die ganze Gruppe'),
              _buildToolFeature('📊', 'Gruppen-Statistiken', 'Fortschritt gemeinsam tracken'),
              _buildToolFeature('🔔', 'Benachrichtigungen', 'Bei Gruppen-Aktivitäten'),
              
              const SizedBox(height: 24),
              
              // 📝 FEATURE-SPEZIFISCH
              Text(
                '✨ ${_getToolSpecificFeatures(_selectedRoom)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // ✅ Tool öffnen via _showGroupTool (navigiert direkt)
              _showGroupTool();
            },
            icon: const Icon(Icons.rocket_launch),
            label: const Text('Tool starten'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildToolFeature(String icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getToolSpecificFeatures(String roomId) {
    switch (roomId) {
      case 'meditation':
        return 'Gruppen-Timer synchronisiert automatisch. Startet gemeinsam mit Countdown!';
      case 'astralreisen':
        return 'Teilt eure Reisen! Andere können kommentieren und ähnliche Erfahrungen teilen.';
      case 'chakra':
        return 'Gegenseitige Energie-Scans. Helft euch bei Blockaden!';
      case 'kristalle':
        return 'Gemeinsame Sammlung! Jeder kann Kristalle hinzufügen und Erfahrungen teilen.';
      case 'frequenzen':
        return 'Synchronisierte Sessions! Alle hören die gleiche Frequenz gleichzeitig.';
      case 'traumarbeit':
        return 'Analysiert Träume gemeinsam! KI-gestützte Traumdeutung für alle.';
      default:
        return 'Gemeinsam stärker!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // 📱 Mobile: Keyboard doesn't cover input
      backgroundColor: const Color(0xFF06040F), // home-dashboard bg
      appBar: AppBar(
        flexibleSpace: AnimatedBuilder(
          animation: _headerAuraCtrl,
          builder: (_, __) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A0A2E),
                  Color.lerp(const Color(0xFF100B1E), const Color(0xFF1E0A3A), _headerAuraCtrl.value)!,
                  const Color(0xFF0D0820),
                ],
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _showRoomInfoSheet,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _rooms[_selectedRoom]?['icon'] ?? '💬',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      (_rooms[_selectedRoom]?['name'] as String? ?? 'ENERGIE LIVE-CHAT')
                          .replaceAll(RegExp(r'^\S+\s'), ''),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              ListenableBuilder(
                listenable: PresenceService.instance,
                builder: (_, __) {
                  final count = PresenceService.instance.onlineCount;
                  return Text(
                    count > 0 ? '$count online · Energie-Welt' : 'Energie-Welt',
                    style: TextStyle(
                      fontSize: 11,
                      color: count > 0 ? const Color(0xFF9B51E0) : Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          // 🎥 LIVEKIT VIDEO/VOICE GROUPCALL
          IconButton(
            icon: const Icon(Icons.video_call, color: Colors.white),
            onPressed: () {
              if (!ApiConfig.isLivekitEnabled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sprach-Anruf ist serverseitig noch nicht aktiviert.'),
                    duration: Duration(seconds: 3),
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LiveKitGroupCallScreen(
                    roomName: 'wb-energie-$_selectedRoom',
                    world: 'energie',
                    displayName: _username.isNotEmpty ? _username : 'Mitglied',
                    avatarUrl: _avatarUrl,
                  ),
                ),
              );
            },
            tooltip: 'Sprach- & Video-Chat',
          ),
          if (_username.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.alternate_email, color: Colors.white),
              tooltip: 'Erwähnungen',
              onPressed: _showMentionsInbox,
            ),
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close : Icons.search,
              color: _showSearch ? const Color(0xFF9B51E0) : Colors.white,
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
                    worldColor: const Color(0xFF9B51E0),
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
                    // ✨ STORIES BAR — Online-User als glühende Avatar-Kreise
                    _buildStoriesBar(),
                    // 📌 PINNED MESSAGE BANNER (Kompakt für mehr Chat-Platz)
                    SizedBox(
                      height: 36,
                      child: PinnedMessageBanner(
                        room: _selectedRoom,
                        onRefresh: () {
                          _loadMessages(silent: true);
                        },
                        onTap: () {
                          // ✅ Scroll to bottom when pinned message tapped
                          _scrollToBottom();
                        },
                        worldColor: const Color(0xFF9B51E0), // ENERGIE Purple
                      ),
                    ),
                  
                  // ✅ REMOVED: VoiceChatBanner (redundant - use VoiceParticipantHeaderBar instead)
                
                  // 🎥 Voice-Header-Bar entfernt — kommt im LiveKit-Folge-PR.
                  // ⌨️ TYPING INDICATORS
                  if (_typingUsers.isNotEmpty) _buildTypingIndicators(),
                  
                  // ✨ UPGRADED ROOM SELECTOR — Glassmorphism Chips mit Glow
                  _buildRoomSelector(),
                  // ✨ ROOM VIBE BANNER — Stimmungs-Emojis der aktiven User
                  _buildRoomVibeBanner(),
                ], // End of keyboard-hidden headers
          
          // Messages List — Feature #21: swipe left/right between rooms
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                final v = details.primaryVelocity ?? 0;
                if (v.abs() < 350) return;
                final keys = _rooms.keys.toList();
                final idx = keys.indexOf(_selectedRoom);
                if (v < 0 && idx < keys.length - 1) _switchToRoom(keys[idx + 1]);
                if (v > 0 && idx > 0) _switchToRoom(keys[idx - 1]);
              },
              behavior: HitTestBehavior.translucent,
              child: _errorMessage != null && _messages.isEmpty
                ? ErrorDisplayWidget(
                    error: _errorMessage!,
                    onRetry: _loadMessages,
                  )
                : _isLoading && _messages.isEmpty
                    ? const LoadingStateWidget(
                        message: 'Lade Nachrichten...',
                      )
                    : _messages.isEmpty
                        ? EmptyStateWidget(
                            title: 'Noch keine Nachrichten',
                            message: 'Sei der Erste in ${_rooms[_selectedRoom]!['name']}!',
                            icon: Icons.chat_bubble_outline,
                          )
                        : AnimatedBuilder(
                            animation: UserBlockService.instance,
                            builder: (_, __) {
                              final visible = UserBlockService.instance
                                  .filterMessages(_messages)
                                  .toList(growable: false);
                              // Feature #10/#11: pre-compute flat items with grouping + separators
                              final chatItems = <Map<String, dynamic>>[];
                              {
                                DateTime? prevDate;
                                String? prevSender;
                                DateTime? prevTs;
                                for (final msg in visible) {
                                  final ts = _parseMessageTimestamp(msg['timestamp'] ?? msg['created_at']);
                                  final msgDay = ts != null ? DateTime(ts.year, ts.month, ts.day) : null;
                                  if (msgDay != null && msgDay != prevDate) {
                                    chatItems.add({'type': 'separator', 'date': ts});
                                    prevDate = msgDay;
                                    prevSender = null;
                                    prevTs = null;
                                  }
                                  final isGrouped = prevSender != null &&
                                      prevSender == msg['username']?.toString() &&
                                      ts != null && prevTs != null &&
                                      ts.difference(prevTs).inSeconds.abs() <= 120;
                                  chatItems.add({'type': 'message', 'msg': Map<String, dynamic>.from(msg)..['_isGrouped'] = isGrouped});
                                  prevSender = msg['username']?.toString();
                                  prevTs = ts;
                                }
                              }
                              return ListView.builder(
                                reverse: false,
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: chatItems.length + (_loadingOlder ? 1 : 0),
                                cacheExtent: 500,
                                addAutomaticKeepAlives: false,
                                addRepaintBoundaries: true,
                                itemBuilder: (context, index) {
                                  if (_loadingOlder && index == 0) {
                                    return const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Center(
                                        child: SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF9B51E0),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  final item = chatItems[index - (_loadingOlder ? 1 : 0)];
                                  if (item['type'] == 'separator') {
                                    return _buildDateSeparator(item['date'] as DateTime, const Color(0xFF9B51E0));
                                  }
                                  final msg = item['msg'] as Map<String, dynamic>;
                                  return RepaintBoundary(
                                    key: ValueKey(msg['message_id'] ?? msg['id']),
                                    child: _buildSwipeableMessage(msg),
                                  );
                                },
                              );
                            },
                          ),
            ), // GestureDetector
          ),  // Expanded

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
                        worldColor: const Color(0xFF9B51E0), // ENERGIE Purple
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
          
          // Input Area
          if (!_showSearch) // Hide input when searching
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF100B1E), // home-dashboard card
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ⌨️ TYPING INDICATOR
                StreamBuilder<Map<String, Set<String>>>(
                  stream: _typingService.typingStream,
                  builder: (context, snapshot) {
                    final typingText = _typingService.getTypingText(_selectedRoom, _username);
                    if (typingText.isEmpty) return const SizedBox.shrink();
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9B51E0)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            typingText,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // ✨ MOOD PICKER
                if (_showMoodPicker) _buildMoodPickerRow(),
                // Feature #17: Smart replies
                _buildSmartRepliesRow(const Color(0xFF9B51E0)),
                // 🆕 REPLY PREVIEW
                _buildReplyPreview(),
                // 🆕 MENTION AUTOCOMPLETE
                if (_showMentionPicker)
                  MentionAutoComplete(
                    suggestions: _mentionSuggestions,
                    onSelectUser: _selectMention,
                    accentColor: const Color(0xFF9B51E0),
                  ),
                
                // ─── MESSAGE INPUT ROW (Telegram-Style: kompakt, "+" öffnet Anhänge) ───
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // ➕ ATTACH-BUTTON (Bild / Mood / Avatar hinter "+"-Menü)
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFF9B51E0), size: 28),
                      onPressed: _showAttachmentSheet,
                      tooltip: 'Anhänge & Profil',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),

                    // ✨ EMOJI-PICKER (inline)
                    ChatEmojiPickerButton(
                      onSelected: _insertEmoji,
                      color: const Color(0xFFBB86FC),
                    ),

                    // ✍️ TEXT-INPUT (kompakt)
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _inputFocusNode,
                        enabled: true,
                        onTap: () {
                          if (!_isInputFocused && mounted) {
                            setState(() => _isInputFocused = true);
                          }
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Nachricht',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // ➤ SEND / MIC BUTTON (swap bei Text-Eingabe)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _hasText
                              ? [const Color(0xFF9B51E0), const Color(0xFF6A5ACD)]
                              : [Colors.grey.shade400, Colors.grey.shade500],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isSending
                              ? null
                              : (_hasText ? _sendMessage : _openVoiceRecorder),
                          onLongPress: _hasText ? _showScheduleMessageDialog : null,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            child: _isSending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    _hasText ? Icons.send : Icons.mic_none,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ), // Row Ende
            ],
          ), // Column (Input Area) Ende
        ), // Container (Input Area) Ende
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
              ),
            ),
          ],
        ), // End Stack
      ), // End SafeArea
    );
  }

  // ignore: unused_element
  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isMyMessage = msg['username'] == _username;
    return EnhancedMessageBubble(
      message: msg,
      currentUserId: _userId,
      currentUsername: _username,
      isMyMessage: isMyMessage,
      worldColor: const Color(0xFF9B51E0), // ENERGIE Purple
      onReply: () {
        // ✅ Reply: Set reply context and focus input
        _replyToMessage(msg);
      },
      onEdit: () {
        _editMessage(msg);
      },
      onDelete: () {
        _deleteMessage(msg);
      },
    );
  }

  @override
  void dispose() {
    _headerAuraCtrl.dispose();
    _headerOrbitCtrl.dispose();
    _meditationSyncTimer?.cancel();
    _messageController.removeListener(_onInputChanged);
    _inputFocusNode.dispose();
    _refreshTimer?.cancel();
    _pendingSub?.cancel();
    _typingTimer?.cancel(); // 🆕
    _typingService.dispose(); // 🧹 Bundle 4.1: StreamController nicht mehr leaken
    _messageController.dispose();
    _scrollController.removeListener(_onScroll); // ✨ Batch-1
    _scrollController.dispose();
    // Voice-Service-dispose entfällt — LiveKit-Service hat eigenen Lifecycle.
    _realtimeChannel?.unsubscribe(); // 🔴 Realtime cleanup
    PresenceService.instance.leave();
    ReadReceiptService.instance.leave();
    for (final t in _scheduledTimers) { t.cancel(); }
    super.dispose();
  }

  // ✨ Batch-2: Presence-Join/Re-Join für den aktuellen Raum.
  Future<void> _refreshPresence() async {
    if (_userId.isEmpty || _username.isEmpty) return;
    await PresenceService.instance.join(
      roomId: _fullRoomId,
      userId: _userId,
      username: _username,
      avatar: _avatar.isNotEmpty ? _avatar : '🔮',
    );
  }

  // ✨ Batch-2: Raum-Info-Sheet mit Beschreibung + Online-Counter.
  void _showRoomInfoSheet() {
    final room = _rooms[_selectedRoom];
    if (room == null) return;
    ChatRoomInfoSheet.show(
      context,
      roomName: (room['name'] as String?) ?? _selectedRoom,
      roomIcon: (room['icon'] as String?) ?? '💬',
      description:
          (room['description'] as String?) ?? 'Live-Chat in diesem Raum.',
      worldColor: const Color(0xFF9B51E0),
    );
  }
  
  /// Telegram-Style Attach-Menü: Bild / Mood / Avatar hinter "+"-Button.
  /// Spart horizontal Platz im Input, damit der Hint-Text nicht mehr umbricht.
  void _showAttachmentSheet() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0D2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _attachOption(
                    icon: Icons.image,
                    label: 'Bild',
                    color: const Color(0xFF9B51E0),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndUploadImage();
                    },
                  ),
                  _attachOption(
                    icon: Icons.mood,
                    label: 'Stimmung',
                    color: const Color(0xFFBB86FC),
                    onTap: () {
                      Navigator.pop(ctx);
                      if (mounted) {
                        setState(() => _showMoodPicker = !_showMoodPicker);
                      }
                    },
                  ),
                  _attachOption(
                    icon: Icons.face,
                    label: 'Avatar',
                    color: const Color(0xFF6A5ACD),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAvatarPicker();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ✨ Batch-1: Emoji-Insert an aktueller Caret-Position.
  void _insertEmoji(String emoji) {
    final text = _messageController.text;
    final sel = _messageController.selection;
    final insertAt = sel.isValid ? sel.start : text.length;
    final newText = text.replaceRange(insertAt, sel.isValid ? sel.end : text.length, emoji);
    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: insertAt + emoji.length),
    );
  }

  // 📜 Scroll to bottom helper (unconditional — für Send-Action & Room-Wechsel)
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
    if (mounted) {
      setState(() {
        _isAtBottom = true;
        _newMessagesCount = 0;
      });
    }
    // ✨ Batch-2.3: User sieht das Ende → Receipt bumpen.
    _markRoomRead();
  }

  // ✨ Batch-1: Nur scrollen wenn User ohnehin am Ende ist, sonst Counter erhöhen.
  void _scrollToBottomIfAtEnd() {
    if (_isAtBottom) {
      _scrollToBottom();
    }
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
    // Am oberen Ende → ältere Nachrichten laden (Pagination).
    if (pos.pixels <= 120 && _hasMoreOlder && !_loadingOlder && _messages.isNotEmpty) {
      _loadOlderMessages();
    }
  }

  // ✨ Batch-1: Pagination — lädt Nachrichten vor dem ältesten bekannten Timestamp.
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
      final priorExtent =
          _scrollController.hasClients ? _scrollController.position.maxScrollExtent : 0.0;
      final priorOffset =
          _scrollController.hasClients ? _scrollController.position.pixels : 0.0;
      final existingIds = _messages.map((m) => m['id']).toSet();
      final merged = <Map<String, dynamic>>[
        ...older.where((m) => !existingIds.contains(m['id'])),
        ..._messages,
      ];
      setState(() => _messages = merged);
      // Scroll-Position erhalten: nach Layout-Pass wieder an gleiche Inhalts-Stelle.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final delta =
            _scrollController.position.maxScrollExtent - priorExtent;
        _scrollController.jumpTo(priorOffset + delta);
      });
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ loadOlder failed: $e');
    } finally {
      if (mounted) setState(() => _loadingOlder = false);
    }
  }

  // 🔴 SUPABASE REALTIME: Subscribe to live chat updates
  void _subscribeToRoom(String roomId) {
    _realtimeChannel?.unsubscribe();
    _reconnecting = true;
    _realtimeChannel = SupabaseChatService.instance.subscribeToRoom(
      roomId,
      onMessage: (newMsg) {
        if (!mounted) return;
        if (_reconnecting) {
          setState(() => _reconnecting = false);
        }
        // Deduplication: nur hinzufügen wenn unbekannte ID.
        final exists = _messages.any((m) => m['id'] == newMsg['id']);
        if (!exists) {
          final isOwn = (newMsg['username']?.toString() == _username) ||
              (newMsg['user_id']?.toString() == _userId);
          setState(() {
            _messages.add(newMsg);
            if (!_isAtBottom && !isOwn) _newMessagesCount++;
          });
          if (!isOwn) {
            HapticFeedbackService().messageReceived();
            final text = (newMsg['message'] ?? newMsg['content'] ?? '').toString();
            if (_username.isNotEmpty &&
                MentionNotificationService.containsMention(text, _username)) {
              MentionNotificationService.instance.notifyMention(
                fromUsername:
                    (newMsg['username'] ?? 'Unbekannt').toString(),
                roomLabel: _rooms[_selectedRoom]?['name']?.toString() ?? 'Chat',
                snippet: text.length > 80 ? '${text.substring(0, 77)}…' : text,
              );
            }
            // Feature #17: Smart-Replies nur regenerieren wenn der User sie
            // GERADE NICHT angetippt hat — flackerten vorher pro Fremd-Msg.
            // Bundle 5.6: Lass die alte Liste stehen wenn _replyingTo aktiv
            // ist oder Input-Feld fokussiert.
            if (mounted &&
                _replyingTo == null &&
                !_inputFocusNode.hasFocus) {
              setState(() => _smartReplies = _generateSmartReplies(text));
            }
          }
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
    if (kDebugMode) debugPrint('🔴 [Energie Realtime] Subscribed to room: $roomId');
    // Reconnect-Flag nach kurzer Zeit auf false fallen lassen (optimistisch).
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted && _reconnecting) setState(() => _reconnecting = false);
    });
  }
  
  // ✅ PROFIL-WARNUNG als Popup mit Navigation
  void _showProfileRequiredDialog() {
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
          'Erstelle dein Profil in der Energie- oder Materie-Welt.',
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
                  builder: (context) => const ProfileEditorScreen(world: 'energie'),
                ),
              );
              // Profil neu laden nachdem User zurückkehrt
              if (mounted) _loadUserData();
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Profil erstellen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7E57C2), // Energie purple
            ),
          ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // 🆕 NEUE FEATURES - WEBRTC, TYPING, REACTIONS, SWIPE (ENERGIE)
  // ═══════════════════════════════════════════════════════════
  
  // ⌨️ TYPING INDICATORS
  // Feature #12: improved typing indicator with avatars + bouncing dots
  Widget _buildTypingIndicators() {
    if (_typingUsers.isEmpty) return const SizedBox.shrink();
    final users = _typingUsers.take(3).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar stack
          SizedBox(
            width: 28.0 + (users.length - 1) * 14.0,
            height: 28,
            child: Stack(
              children: [
                for (int i = 0; i < users.length; i++)
                  Positioned(
                    left: i * 14.0,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFF9B51E0).withValues(alpha: 0.25),
                      child: Text(
                        users[i].isNotEmpty ? users[i][0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9B51E0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const BouncingDotsBubble(color: Color(0xFF9B51E0)),
              const SizedBox(height: 3),
              Text(
                users.length == 1
                    ? '${users[0]} tippt...'
                    : users.length == 2
                        ? '${users[0]} & ${users[1]} tippen...'
                        : '${_typingUsers.length} Personen tippen...',
                style: TextStyle(color: Colors.grey[500], fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _sendTypingIndicator() {
    _typingTimer?.cancel();
    
    // ⌨️ Start typing indicator
    _typingService.startTyping(_selectedRoom, _username);
    
    if (kDebugMode) {
      debugPrint('⌨️ User is typing in room: $_selectedRoom');
    }
    
    // Stop after 3 seconds
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _typingService.stopTyping(_selectedRoom, _username);
    });
  }
  
  // 😀 EMOJI REACTIONS
  // 🛠️ MESSAGE OPTIONS (EDIT/DELETE)
  void _showMessageOptions(BuildContext context, Map<String, dynamic> msg) async {
    final isOwnMessage = msg['username'] == _username;
    
    // ✅ SECURE: Check admin status from Backend Role (EXACT Dashboard Match!)
    final storage = StorageService();
    final profile = storage.getEnergieProfile();
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
            // Handle Bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Options
            if (isOwnMessage) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF9B51E0)),
                title: const Text(
                  'Bearbeiten',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _startEditingMessage(msg);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Löschen',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(msg);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.reply, color: Color(0xFF9B51E0)),
              title: const Text(
                'Antworten',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _replyToMessage(msg);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_reaction, color: Color(0xFF9B51E0)),
              title: const Text(
                'Reaktion hinzufügen',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showReactionPicker(msg);
              },
            ),
            
            // 🔧 ADMIN MODERATION OPTIONS (Secure check via AdminPermissions)
            if (isAdmin) ...[
              const Divider(color: Color(0xFF9B51E0)),
              
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
                  leading: const Icon(Icons.flag, color: Color(0xFF9B51E0)),
                  title: const Text('Inhalt melden', style: TextStyle(color: Color(0xFF9B51E0))),
                  onTap: () {
                    Navigator.pop(context);
                    _showFlagDialog(msg);
                  },
                ),
              
              // ADMIN: Ban/Mute User
              if (canBan && !isOwnMessage)
                ListTile(
                  leading: const Icon(Icons.volume_off, color: Color(0xFF9B51E0)),
                  title: Text('User sperren $adminBadge', style: const TextStyle(color: Color(0xFF9B51E0))),
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
      } else {
        userList.add(_username);
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
  
  Future<void> _saveEditedMessage(Map<String, dynamic> msg, String newContent) async {
    if (mounted) {
      setState(() {
        msg['message'] = newContent;
        msg['content'] = newContent;
        msg['edited'] = true;
        msg['editedAt'] = DateTime.now().toIso8601String();
        _editingMessageId = null;
      });
    }
    
    // Server-Update im Hintergrund (fire-and-forget)
    final messageId = msg['id']?.toString() ?? msg['message_id']?.toString() ?? '';
    if (messageId.isNotEmpty) {
      _api.editChatMessage(
        messageId: messageId,
        newMessage: newContent,
        userId: _userId,
        username: _username,
        roomId: _fullRoomId,
        realm: 'energie',
      ).then((_) {
        if (kDebugMode) debugPrint('✅ Energie Edit gespeichert');
        if (mounted) _loadMessages(silent: true);
      }).catchError((e) {
        if (kDebugMode) debugPrint('⚠️ Energie Edit server error (optimistic bleibt): $e');
      });
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
      if (!_showSearch) {
        // Reset search when closing
        FocusScope.of(context).unfocus();
      }
    });
    }
  }
  
  void _jumpToMessage(Map<String, dynamic> msg) {
    // Find message index
    final msgId = msg['id']?.toString() ?? '';
    final index = _messages.indexWhere((m) => m['id']?.toString() == msgId);
    if (index == -1) return;
    
    // Scroll to message (approximate)
    final scrollPosition = index * 80.0; // Approximate message height
    _scrollController.animateTo(
      scrollPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    // ✅ Highlight message briefly
    if (mounted && msgId.isNotEmpty) {
      setState(() => _replyToMessageData = msg); // Use as highlight indicator
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _replyToMessageData = null);
      });
    }
  }
  
  Widget _buildMessageWithReactions(Map<String, dynamic> msg) {
    final messageId = msg['id']?.toString() ?? msg['timestamp']?.toString() ?? '';
    final isEditing = _editingMessageId == messageId;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✏️ EDIT MODE
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
            // Long Press = Message Options (Edit/Delete/Reply/React)
            onLongPress: () => _showMessageOptions(context, msg),
            // Double Tap = Quick Reaction (❤️)
            onDoubleTap: () => _addReaction(msg, '❤️'),
            child: _buildEnhancedMessageBubble(msg),
          ),
        
        // 😀 NEW: Unified Reactions Widget
        if (!isEditing)
          Padding(
            padding: const EdgeInsets.only(left: 60, top: 4),
            child: MessageReactionsWidget(
              message: msg,
              onReact: (emoji) => _addReaction(msg, emoji),
              currentUsername: _username,
            ),
          ),
        // ✨ Batch-3.1: Link-Preview-Karte unter Nachrichten mit URL
        if (!isEditing) _buildLinkPreviewRow(msg),
        // ✨ Batch-2.3: „Gelesen von N" Haken nur für eigene Nachrichten
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
        accent: const Color(0xFF7C4DFF),
      ),
    );
  }

  Widget _buildReadReceiptRow(Map<String, dynamic> msg) {
    final msgUserId = msg['userId']?.toString() ?? msg['user_id']?.toString() ?? '';
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
              borderSide: BorderSide(color: Color(0xFF9B51E0), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9B51E0)),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    
    if (newText != null && newText.trim().isNotEmpty && newText != msg['message']) {
      final msgId = (msg['message_id'] ?? msg['id']).toString();
      final trimmed = newText.trim();
      final original = Map<String, dynamic>.from(msg);

      // Optimistic local update (Realtime UPDATE bestätigt später).
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere(
              (m) => (m['id']?.toString() ?? m['message_id']?.toString()) == msgId);
          if (idx >= 0) {
            _messages[idx] = {
              ..._messages[idx],
              'message': trimmed,
              'content': trimmed,
              'edited_at': DateTime.now().toUtc().toIso8601String(),
            };
          }
        });
      }

      try {
        await _api.editChatMessage(
          messageId: msgId,
          roomId: _fullRoomId,
          realm: 'energie',
          newMessage: trimmed,
          userId: _userId,
          username: _username,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Nachricht bearbeitet'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        // Rollback bei Fehler.
        if (mounted) {
          setState(() {
            final idx = _messages.indexWhere(
                (m) => (m['id']?.toString() ?? m['message_id']?.toString()) == msgId);
            if (idx >= 0) _messages[idx] = original;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Fehler: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
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

      // Backup für Rollback
      final backupMsg = Map<String, dynamic>.from(msg);
      final backupIndex = _messages.indexWhere((m) => (m['message_id'] ?? m['id']) == msgId);

      // Optimistic: sofort lokal entfernen
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => (m['message_id'] ?? m['id']) == msgId);
        });
      }

      try {
        await _api.deleteChatMessage(
          messageId: msgId,
          roomId: _fullRoomId,
          realm: 'energie',
          userId: _userId,
          username: _username,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Nachricht gelöscht'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        // Rollback: Nachricht wiederherstellen
        if (mounted) {
          setState(() {
            if (backupIndex >= 0 && backupIndex <= _messages.length) {
              _messages.insert(backupIndex, backupMsg);
            } else {
              _messages.add(backupMsg);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Löschen fehlgeschlagen. Bitte erneut versuchen.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
  
  // Feature #21: programmatic room switch (also called from swipe gesture)
  Future<void> _switchToRoom(String roomId) async {
    if (roomId == _selectedRoom || !mounted) return;
    HapticFeedback.selectionClick();
    ChatDraftService.instance.set(_fullRoomId, _messageController.text);
    RecentRoomsService.instance.touch('energie', roomId);
    setState(() {
      _selectedRoom = roomId;
      _messages.clear();
      _isLoading = true;
      _hasMoreOlder = true;
      _newMessagesCount = 0;
      _isAtBottom = true;
    });
    _messageController.text = ChatDraftService.instance.get(_fullRoomId);
    UnreadTrackerService.instance.markSeen(_fullRoomId);
    // Voice-Service-switchRoom entfällt — LiveKit nutzt eigene Room-Logik.
    await _refreshPresence();
    await ReadReceiptService.instance.watchRoom(_fullRoomId);
    await _markRoomRead();
    _subscribeToRoom(_fullRoomId);
    await _loadMessages();
  }

  // Feature #22: room info preview on long-press room chip
  void _showRoomPreview(String roomId, Map room) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(room['icon'] ?? '💬', style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 10),
              Text(
                room['name'] ?? roomId,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              if (room['description'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  room['description'].toString(),
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              if (roomId != _selectedRoom)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B51E0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _switchToRoom(roomId);
                    },
                    child: const Text('Zu diesem Raum wechseln'),
                  ),
                )
              else
                Text('Du bist bereits in diesem Raum', style: TextStyle(color: Colors.grey[500])),
            ],
          ),
        ),
      ),
    );
  }

  // Feature #16: message scheduler — long-press send button
  void _showScheduleMessageDialog() {
    HapticFeedback.mediumImpact();
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final delays = [
      const Duration(minutes: 5),
      const Duration(minutes: 15),
      const Duration(minutes: 30),
      const Duration(hours: 1),
      const Duration(hours: 2),
    ];
    final labels = ['5 Min', '15 Min', '30 Min', '1 Std', '2 Std'];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nachricht planen', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('"${text.length > 50 ? '${text.substring(0, 47)}…' : text}"', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(delays.length, (i) => GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    final sendAt = DateTime.now().add(delays[i]);
                    setState(() {
                      _scheduledMessages.add((sendAt, text));
                      _messageController.clear();
                    });
                    final t = Timer(delays[i], () {
                      if (mounted) {
                        _messageController.text = text;
                        _sendMessage();
                      }
                    });
                    _scheduledTimers.add(t);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('✅ Geplant für ${labels[i]}'),
                      backgroundColor: const Color(0xFF9B51E0),
                      duration: const Duration(seconds: 2),
                    ));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9B51E0).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF9B51E0).withValues(alpha: 0.4)),
                    ),
                    child: Text(labels[i], style: const TextStyle(color: Color(0xFF9B51E0), fontWeight: FontWeight.w600)),
                  ),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Feature #24: Mentions inbox — all session messages containing @username
  void _showMentionsInbox() {
    final mentions = _messages.where((m) {
      final text = (m['message'] ?? m['content'] ?? '').toString();
      return MentionNotificationService.containsMention(text, _username);
    }).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.alternate_email, color: Color(0xFF9B51E0), size: 20),
                  const SizedBox(width: 8),
                  Text('Erwähnungen (${mentions.length})', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: Colors.white12),
            Expanded(
              child: mentions.isEmpty
                ? const Center(child: Text('Keine Erwähnungen in dieser Sitzung', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    controller: ctrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: mentions.length,
                    itemBuilder: (_, i) {
                      final m = mentions[mentions.length - 1 - i]; // newest first
                      final text = (m['message'] ?? m['content'] ?? '').toString();
                      final sender = m['username']?.toString() ?? '?';
                      final ts = _formatTime(m['timestamp'] ?? m['created_at']);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9B51E0).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF9B51E0).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(sender, style: const TextStyle(color: Color(0xFF9B51E0), fontWeight: FontWeight.bold, fontSize: 13)),
                              const Spacer(),
                              Text(ts, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ]),
                            const SizedBox(height: 4),
                            Text(text, style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 3, overflow: TextOverflow.ellipsis),
                          ],
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

  // Feature #17: smart reply suggestions based on last received message
  static List<String> _generateSmartReplies(String msg) {
    final lower = msg.toLowerCase();
    if (msg.trim().endsWith('?')) return ['Ja', 'Nein', 'Vielleicht', 'Weiß nicht'];
    if (lower.contains('danke') || lower.contains('thanks')) return ['Gerne!', 'Kein Problem', '👍', '😊'];
    if (lower.contains('hallo') || lower.contains('hey') || lower.contains('hi')) return ['Hey! 👋', 'Wie geht\'s?', '😊', 'Hi!'];
    if (lower.contains('interessant') || lower.contains('spannend') || lower.contains('krass')) return ['Wirklich? 😮', 'Mehr davon!', 'Quelle?', '🔥'];
    if (lower.contains('ok') || lower.contains('alles klar') || lower.contains('verstanden')) return ['👍', 'Super', '✅', 'Danke'];
    return ['Ok', 'Verstanden', '👍', '❤️'];
  }

  Widget _buildSmartRepliesRow(Color accentColor) {
    if (_smartReplies.isEmpty || _messageController.text.isNotEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _smartReplies.map((reply) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _messageController.text = reply;
                setState(() => _smartReplies = []);
                _sendMessage();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                ),
                child: Text(reply, style: TextStyle(color: accentColor, fontSize: 13, fontWeight: FontWeight.w500)),
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    if (_replyingTo == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(
            color: Color(0xFF9B51E0),
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
                    color: Color(0xFF9B51E0),
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
            tooltip: 'Antwort abbrechen',
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
  
  // 🆕 ENHANCED MESSAGE BUBBLE (Modern Design - ENERGIE Purple)
  Widget _buildEnhancedMessageBubble(Map<String, dynamic> msg) {
    // ✅ isOwn: vergleiche userId (camelCase und snake_case) + username als Fallback
    final msgUserId = msg['userId']?.toString() ?? msg['user_id']?.toString() ?? '';
    final isOwn = (msgUserId.isNotEmpty && msgUserId == _userId) ||
        (msg['username']?.toString() == _username && _username.isNotEmpty);
    // Feature #10: iMessage-style grouping
    final isGrouped = msg['_isGrouped'] == true;

    return Padding(
      padding: EdgeInsets.only(
        left: isOwn ? 60 : 12,
        right: isOwn ? 12 : 60,
        bottom: isGrouped ? 2 : 8,
        top: isGrouped ? 0 : 2,
      ),
      child: Row(
        mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar placeholder keeps alignment; hidden when grouped
          if (!isOwn) ...[
            if (!isGrouped)
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF9B51E0).withValues(alpha: 0.2),
                child: Text(
                  // Realtime-Payload von Supabase nutzt snake_case
                  // (avatar_emoji); local-optimistic Inserts können auch
                  // camelCase oder den 'avatar'-Alias enthalten.
                  msg['avatar']?.toString()
                      ?? msg['avatar_emoji']?.toString()
                      ?? msg['avatarEmoji']?.toString()
                      ?? '👤',
                  style: const TextStyle(fontSize: 16),
                ),
              )
            else
              const SizedBox(width: 36),
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
                  color: isOwn ? const Color(0xFF9B51E0) : const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isGrouped && !isOwn ? 4 : 16),
                    topRight: Radius.circular(isGrouped && isOwn ? 4 : 16),
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
                  // Username (nur bei anderen, nicht wenn gruppiert)
                  if (!isOwn && !isGrouped)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        msg['username']?.toString() ?? 'Unbekannt',
                        style: const TextStyle(
                          color: Color(0xFFBB86FC),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  // Feature #14: Reply chain visualization
                  if ((msg['reply_to_id']?.toString().isNotEmpty ?? false))
                    _buildInlineReplyQuote(
                      senderName: msg['reply_to_sender_name']?.toString(),
                      content: msg['reply_to_content']?.toString(),
                      color: const Color(0xFF9B51E0),
                    ),

                  // 🎤 VOICE MESSAGE or 📷 IMAGE or 💬 TEXT
                  if (() {
                    final t = (msg['mediaType'] ?? msg['message_type'])?.toString();
                    final url = (msg['mediaUrl'] ?? msg['media_url'])?.toString();
                    return t == 'voice' && url != null && url.isNotEmpty;
                  }())
                    // 🎵 VOICE MESSAGE PLAYER
                    ChatVoicePlayer(
                      audioUrl: (msg['mediaUrl'] ?? msg['media_url'] ?? '').toString(),
                      duration: Duration(seconds: int.tryParse(
                        msg['message']?.toString()
                          .replaceAll('🎤 Sprachnachricht (', '')
                          .replaceAll('s)', '')
                          .replaceAll(')', '') ?? '0'
                      ) ?? 0),
                      accentColor: const Color(0xFF9B51E0),
                    )
                  else if (() {
                    final t = (msg['mediaType'] ?? msg['message_type'])?.toString();
                    final url = (msg['mediaUrl'] ?? msg['media_url'])?.toString();
                    return t == 'image' && url != null && url.isNotEmpty;
                  }())
                    // Feature #15: Tappable image with hero → fullscreen viewer
                    Builder(builder: (_) {
                      final url = (msg['mediaUrl'] ?? msg['media_url']).toString();
                      return GestureDetector(
                        onTap: () => ChatImageViewer.open(
                          context,
                          imageUrl: url,
                          heroTag: 'chat-img-${msg['id'] ?? msg['timestamp']}',
                          accentColor: const Color(0xFF9B51E0),
                        ),
                        child: Hero(
                          tag: 'chat-img-${msg['id'] ?? msg['timestamp']}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: url,
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              errorWidget: (context, _, __) => Container(
                                width: 200,
                                height: 150,
                                color: const Color(0xFF2A2A3E),
                                child: const Icon(Icons.broken_image, size: 48),
                              ),
                            ),
                          ),
                        ),
                      );
                    })
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
  
  // Feature #14: inline reply quote block inside bubble
  Widget _buildInlineReplyQuote({String? senderName, String? content, required Color color}) {
    final name = (senderName ?? '').trim().isEmpty ? 'Nachricht' : senderName!.trim();
    final snippet = (content ?? '').trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          if (snippet.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              snippet,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.65)),
            ),
          ],
        ],
      ),
    );
  }

  // Feature #11: parse message timestamp from any format
  static DateTime? _parseMessageTimestamp(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    return null;
  }

  // Feature #11: date separator chip between days
  Widget _buildDateSeparator(DateTime date, Color color) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDay = DateTime(date.year, date.month, date.day);
    String label;
    if (msgDay == today) {
      label = 'Heute';
    } else if (msgDay == yesterday) {
      label = 'Gestern';
    } else {
      const wd = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
      const mo = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
      label = '${wd[date.weekday - 1]}, ${date.day}. ${mo[date.month - 1]}.';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
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
        title: const Text('Inhalt melden', style: TextStyle(color: Color(0xFF9B51E0))),
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
                  world: 'energie',
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9B51E0)),
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
          _messages.removeWhere((m) => (m['id'] ?? m['message_id']) == messageId);
        });
        _showSnackBar('✅ Nachricht wurde gelöscht', Colors.green);
      }

      // Server-Update im Hintergrund
      if (messageId.isNotEmpty) {
        _api.deleteChatMessage(
          messageId: messageId,
          userId: _userId,
          username: _username,
          roomId: _fullRoomId,
          realm: 'energie',
          isAdmin: true,
        ).then((_) {
          if (kDebugMode) debugPrint('✅ Admin-Delete gespeichert');
        }).catchError((e) {
          if (kDebugMode) debugPrint('⚠️ Admin-Delete server error: $e');
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
          title: const Text('User sperren', style: TextStyle(color: Color(0xFF9B51E0))),
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
                        activeColor: const Color(0xFF9B51E0),
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
                  final targetUserId = 'energie_${msg['username']}'; // Construct user_id
                  final moderation = ModerationService();
                  
                  await moderation.muteUser(
                    world: 'energie',
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
                backgroundColor: muteType == 'permanent' ? Colors.red : const Color(0xFF9B51E0),
              ),
              child: const Text('Sperren'),
            ),
          ],
        ),
      ),
    );
  }

  // ✨ STORIES BAR — Online-User als glühende Avatar-Kreise
  Widget _buildStoriesBar() {
    return ListenableBuilder(
      listenable: PresenceService.instance,
      builder: (_, __) {
        final members = PresenceService.instance.members;
        if (members.isEmpty) return const SizedBox.shrink();
        return Container(
          height: 52,
          color: const Color(0xFF0A0618),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: members.length,
            itemBuilder: (_, i) {
              final m = members[i];
              final isMe = m.userId == _userId;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _headerAuraCtrl,
                      builder: (_, __) => Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            const Color(0xFF9B51E0).withValues(alpha: isMe ? 0.9 : 0.5),
                            const Color(0xFF4A148C).withValues(alpha: isMe ? 0.7 : 0.3),
                          ]),
                          border: Border.all(
                            color: const Color(0xFF9B51E0).withValues(alpha: 0.5 + _headerAuraCtrl.value * 0.4),
                            width: isMe ? 2.0 : 1.5,
                          ),
                          boxShadow: [BoxShadow(
                            color: const Color(0xFF9B51E0).withValues(alpha: 0.3 + _headerAuraCtrl.value * 0.2),
                            blurRadius: 6,
                          )],
                        ),
                        child: Center(
                          child: Text(m.avatar.isNotEmpty ? m.avatar : '👤', style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      isMe ? 'Du' : m.username.length > 6 ? '${m.username.substring(0, 5)}…' : m.username,
                      style: TextStyle(
                        color: isMe ? const Color(0xFF9B51E0) : Colors.grey[400],
                        fontSize: 8,
                        fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ✨ UPGRADED ROOM SELECTOR — Glassmorphism Chips mit Glow
  Widget _buildRoomSelector() {
    return AnimatedBuilder(
      animation: _headerAuraCtrl,
      builder: (_, __) => Container(
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFF0D0820),
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFF9B51E0).withValues(alpha: 0.15),
            ),
          ),
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          itemCount: _rooms.length,
          itemBuilder: (_, index) {
            final roomId = _rooms.keys.elementAt(index);
            final room = _rooms[roomId]!;
            final isSelected = roomId == _selectedRoom;
            final chipFullRoomId = _roomIdMap[roomId] ?? 'energie-$roomId';
            return GestureDetector(
              onLongPress: () => _showRoomPreview(roomId, room),
              onTap: () async {
                if (roomId != _selectedRoom) {
                  ChatDraftService.instance.set(_fullRoomId, _messageController.text);
                  if (mounted) {
                    RecentRoomsService.instance.touch('energie', roomId);
                    setState(() {
                      _selectedRoom = roomId;
                      _messages.clear();
                      _isLoading = true;
                      _hasMoreOlder = true;
                      _newMessagesCount = 0;
                      _isAtBottom = true;
                    });
                  }
                  _messageController.text = ChatDraftService.instance.get(_fullRoomId);
                  UnreadTrackerService.instance.markSeen(_fullRoomId);
                  // Voice-Service-switchRoom entfällt — LiveKit nutzt eigene Room-Logik.
                  await _refreshPresence();
                  await ReadReceiptService.instance.watchRoom(_fullRoomId);
                  await _markRoomRead();
                  _subscribeToRoom(_fullRoomId);
                  await _loadMessages();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  gradient: isSelected ? LinearGradient(colors: [
                    const Color(0xFF4A148C).withValues(alpha: 0.8),
                    const Color(0xFF7B1FA2).withValues(alpha: 0.6),
                  ]) : null,
                  color: isSelected ? null : const Color(0xFF100B1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF9B51E0).withValues(alpha: 0.7 + _headerAuraCtrl.value * 0.3)
                        : const Color(0xFF2A1A4A).withValues(alpha: 0.5),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected ? [BoxShadow(
                    color: const Color(0xFF9B51E0).withValues(alpha: 0.25 + _headerAuraCtrl.value * 0.15),
                    blurRadius: 12,
                  )] : null,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(room['icon'] ?? '💬', style: TextStyle(fontSize: isSelected ? 16 : 14)),
                        const SizedBox(width: 5),
                        Text(
                          (room['name'] as String).replaceAll(RegExp(r'^\S+\s'), '').split('&').first.trim(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[400],
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: -6, right: -6,
                      child: ChatUnreadBadge(roomId: chipFullRoomId),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ✨ ROOM VIBE BANNER — Raumstimmung als kompakte Mood-Anzeige
  Widget _buildRoomVibeBanner() {
    const moods = ['🧘', '💫', '🔮', '✨', '🌙', '💜', '🌟', '🕊️'];
    if (_myMood.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 28,
      color: const Color(0xFF08041A),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text('Vibe: ', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          Text(_myMood, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text('· Du bist im ${_rooms[_selectedRoom]?['icon'] ?? '💬'} Raum', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
          const Spacer(),
          // Show other online users' moods from room description (placeholder)
          ...moods.take(3).map((e) => Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(e, style: const TextStyle(fontSize: 11, color: Colors.white24)),
          )),
        ],
      ),
    );
  }

  // ✨ MOOD PICKER ROW — erscheint über dem Input-Feld
  Widget _buildMoodPickerRow() {
    const moods = ['🧘', '💫', '🔮', '✨', '🌙', '💜', '🌟', '🕊️', '🌺', '⚡', '🔥', '💎'];
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: () => setState(() { _myMood = ''; _showMoodPicker = false; }),
            child: Container(
              width: 32, height: 32,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A0A2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.grey),
            ),
          ),
          ...moods.map((e) => GestureDetector(
            onTap: () => setState(() { _myMood = e; _showMoodPicker = false; }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 32, height: 32,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: _myMood == e ? const Color(0xFF4A148C) : const Color(0xFF1A0A2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _myMood == e ? const Color(0xFF9B51E0) : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Center(child: Text(e, style: const TextStyle(fontSize: 16))),
            ),
          )),
        ],
      ),
    );
  }

  // ✨ MEDITATION SYNC — Gemeinsamer Timer für den Meditation-Raum
  void _toggleMeditationSync() {
    if (_meditationSyncActive) {
      _meditationSyncTimer?.cancel();
      setState(() { _meditationSyncActive = false; _meditationSyncSeconds = 0; });
    } else {
      setState(() { _meditationSyncActive = true; _meditationSyncSeconds = 0; });
      _meditationSyncTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _meditationSyncSeconds++);
      });
    }
  }

  String _formatSync(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

