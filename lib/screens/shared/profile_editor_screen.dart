import 'dart:async' show Timer, unawaited;

import 'package:flutter/material.dart';
import '../../services/spirit_profile_service.dart';
import '../../services/storage_service.dart';
import '../../services/username_availability_service.dart';
import '../../widgets/profile_chat_preview.dart';
import '../../widgets/profile_completeness_bar.dart';
import '../../widgets/responsive_web_container.dart';
import 'package:flutter/services.dart'; // ✅ Für InputFormatters
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint, kIsWeb;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' if (dart.library.html) '../../stubs/dart_io_stub.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 🆕 RIVERPOD
import '../../services/image_upload_service.dart';
import '../../services/profile_sync_service.dart'; // 🆕 Cloud-Sync
import '../../services/user_auth_service.dart'; // ✅ User Auth Service
import '../../models/materie_profile.dart';
import '../../models/energie_profile.dart';
import '../../features/admin/state/admin_state.dart'; // 🆕 Admin State Provider
import '../../core/persistence/auto_save_manager.dart'; // 🔄 Auto-Save System
import '../../core/storage/unified_storage_service.dart'; // ✅ user_data Box Sync
import 'dart:convert'; // v92 username change request JSON
import 'package:http/http.dart' as http; // v92 worker calls
import '../../config/api_config.dart'; // v92 ApiConfig.workerUrl
import '../../services/timezone_helper.dart'; // ✨ v93 TZ inference
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';
import '../../widgets/profile/birth_place_autocomplete.dart'; // ✨ v93 Geocoding

/// Vollständiger Profil-Editor für Materie & Energie Welten
/// Alle Felder bearbeitbar + neue Features (Avatar, Bio)
/// 🆕 RIVERPOD: ConsumerStatefulWidget für Auto-Refresh nach Speichern
class ProfileEditorScreen extends ConsumerStatefulWidget {
  final String world; // 'materie' oder 'energie'
  
  const ProfileEditorScreen({
    super.key,
    required this.world,
  });

  @override
  ConsumerState<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends ConsumerState<ProfileEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Username-Live-Check
  Timer? _usernameDebounce;
  UsernameCheckResult? _usernameCheck;
  bool _usernameChecking = false;
  String _lastCheckedUsername = '';

  // Geladene Profile — werden für den Username-Check (Vergleich gegen
  // bereits gespeicherten Namen) und beim Save (wasUsernameChanged?) gebraucht.
  MaterieProfile? _materieProfile;
  EnergieProfile? _energieProfile;

  /// Triggert nach 400ms Tipppause einen Server-Check.
  /// Bricht laufende Debounce-Timer ab.
  void _scheduleUsernameCheck(String value) {
    _usernameDebounce?.cancel();
    final trimmed = value.trim();
    // Wenn Eingabe = bereits gespeicherter Username → kein Check nötig
    if (trimmed == _materieProfile?.username ||
        trimmed == _energieProfile?.username) {
      setState(() {
        _usernameCheck = const UsernameCheckResult(
          status: UsernameStatus.available,
          message: 'Aktueller Benutzername.',
        );
        _usernameChecking = false;
      });
      return;
    }
    if (trimmed.isEmpty) {
      setState(() {
        _usernameCheck = null;
        _usernameChecking = false;
      });
      return;
    }
    _usernameDebounce = Timer(const Duration(milliseconds: 450), () async {
      if (!mounted) return;
      setState(() => _usernameChecking = true);
      // currentUsername mitschicken: eigener Name kollidiert nie mit sich selbst.
      final result = await UsernameAvailabilityService.instance.check(
        trimmed,
        currentUsername: _materieProfile?.username ?? _energieProfile?.username,
      );
      if (!mounted || _usernameController.text.trim() != trimmed) return;
      setState(() {
        _usernameCheck = result;
        _usernameChecking = false;
        _lastCheckedUsername = trimmed;
      });
    });
  }

  Widget? _buildUsernameStatusIcon() {
    if (_usernameChecking) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final status = _usernameCheck?.status;
    if (status == null) return null;
    switch (status) {
      case UsernameStatus.available:
        return const Icon(Icons.check_circle_rounded, color: Colors.green);
      case UsernameStatus.taken:
        return const Icon(Icons.cancel_rounded, color: Colors.red);
      case UsernameStatus.invalidFormat:
        return const Icon(Icons.warning_amber_rounded,
            color: Colors.orange);
      case UsernameStatus.checkFailed:
        return const Icon(Icons.cloud_off_rounded, color: Colors.grey);
    }
  }

  String? _buildUsernameHelperText() {
    if (_usernameChecking) return 'Verfügbarkeit wird geprüft …';
    return _usernameCheck?.message;
  }

  TextStyle? _buildUsernameHelperStyle() {
    final status = _usernameCheck?.status;
    Color? color;
    switch (status) {
      case UsernameStatus.available:
        color = Colors.green;
        break;
      case UsernameStatus.taken:
        color = Colors.red;
        break;
      case UsernameStatus.invalidFormat:
        color = Colors.orange;
        break;
      case UsernameStatus.checkFailed:
        color = Colors.grey;
        break;
      case null:
        return null;
    }
    return TextStyle(color: color, fontSize: 12);
  }
  
  // Gemeinsame Felder
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  
  // ✅ NEU: Root-Admin Flow
  final _passwordController = TextEditingController();
  bool _isWeltenbibliothek = false;  // Zeigt Admin Passwortfeld an (Root-Admin ODER Content-Editor)
  
  // Materie-spezifisch
  final _nameController = TextEditingController();
  
  // Energie-spezifisch
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _birthTimeController = TextEditingController();
  final _birthDateController = TextEditingController(); // ✅ NEU: Für manuelle Datumseingabe
  DateTime? _selectedBirthDate;

  // ✨ v93 Spirit-Tools-Extras (alle nullable, werden via Geocoding aus
  // Geburtsort automatisch befuellt - User tippt sie nie manuell)
  double? _birthLatitude;
  double? _birthLongitude;
  double? _timezoneOffsetHours;
  bool _birthTimeUnknown = false;
  String? _gender; // 'male'|'female'|'diverse'|'prefer_not_say'|null

  // ✨ v92: Username-Immutability. Sobald Profil geladen mit existierendem
  // username -> Feld disabled. Aenderung nur via Change-Request (Antrag).
  // Ausnahme: Root-Admin (effectiveRole == 'root_admin').
  String? _originalUsername;
  bool _userIsRootAdmin = false;
  bool _pendingUsernameRequest = false; // bereits offener Antrag?
  String? _pendingRequestedUsername;

  // Neue Features
  String? _selectedEmoji;
  String? _avatarUrl;
  File? _selectedImageFile;
  
  bool _isLoading = true;
  bool _isSaving = false;

  /// True sobald der User irgendein Feld geändert hat. Wird vom
  /// Form-onChanged-Handler gesetzt und nach erfolgreichem Speichern oder
  /// erfolgtem Verwerfen-Bestätigung zurückgesetzt.
  bool _hasUnsavedChanges = false;

  /// PopScope-Bestätigung: warnt bevor User mit ungespeicherten Daten zurückgeht.
  Future<bool> _confirmDiscardChanges() async {
    if (!_hasUnsavedChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Ungespeicherte Änderungen'),
        content: const Text(
          'Du hast Änderungen am Profil vorgenommen. '
          'Wenn du jetzt zurück gehst, gehen sie verloren.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bleiben'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.15),
              foregroundColor: Colors.red,
            ),
            child: const Text('Verwerfen'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
  
  // Emoji-Auswahl
  final List<String> _emojiOptions = [
    '🧙‍♂️', '🔬', '📚', '🗿', '👁️', '🔮', '🌟', '💫', 
    '🧘‍♀️', '🕉️', '☯️', '🌙', '✨', '🦋', '🌸', '🍃',
    '🎭', '🎨', '🎯', '🗝️', '⚡', '🔥', '💎', '🌈',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _setupAutoSave(); // 🔄 Auto-Save Setup
  }
  
  // 🔄 AUTO-SAVE SETUP
  void _setupAutoSave() {
    // Text-Felder mit Auto-Save verbinden (500ms Debounce)
    _usernameController.addListener(() {
      AutoSaveManager().scheduleSave(
        key: 'profile_${widget.world}_username_draft',
        data: {'username': _usernameController.text},
        boxName: 'profile_drafts',
        priority: SavePriority.medium,
      );
    });
    
    _bioController.addListener(() {
      AutoSaveManager().scheduleSave(
        key: 'profile_${widget.world}_bio_draft',
        data: {'bio': _bioController.text},
        boxName: 'profile_drafts',
        priority: SavePriority.low,
      );
    });
    
    if (widget.world == 'materie') {
      _nameController.addListener(() {
        AutoSaveManager().scheduleSave(
          key: 'profile_materie_name_draft',
          data: {'name': _nameController.text},
          boxName: 'profile_drafts',
          priority: SavePriority.low,
        );
      });
    } else {
      _firstNameController.addListener(() {
        AutoSaveManager().scheduleSave(
          key: 'profile_energie_firstname_draft',
          data: {'firstName': _firstNameController.text},
          boxName: 'profile_drafts',
          priority: SavePriority.low,
        );
      });
      _lastNameController.addListener(() {
        AutoSaveManager().scheduleSave(
          key: 'profile_energie_lastname_draft',
          data: {'lastName': _lastNameController.text},
          boxName: 'profile_drafts',
          priority: SavePriority.low,
        );
      });
      _birthPlaceController.addListener(() {
        AutoSaveManager().scheduleSave(
          key: 'profile_energie_birthplace_draft',
          data: {'birthPlace': _birthPlaceController.text},
          boxName: 'profile_drafts',
          priority: SavePriority.low,
        );
      });
    }
  }

  @override
  void dispose() {
    // 🔄 AUTO-SAVE: Flush pending saves before dispose
    AutoSaveManager().flushAll();

    _usernameDebounce?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();  // ✅ NEU
    _nameController.dispose();
    _bioController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthPlaceController.dispose();
    _birthTimeController.dispose();
    _birthDateController.dispose(); // ✅ NEU
    super.dispose();
  }
  
  // 🖼️ BILD-UPLOAD FUNKTIONEN
  Future<void> _pickImage(ImageSource source) async {
    if (kIsWeb) return;
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          _avatarUrl = pickedFile.path; // Temporärer lokaler Pfad
        });
        
        if (kDebugMode) {
          debugPrint('✅ Bild ausgewählt: ${pickedFile.path}');
        }
        
        // 🚀 SOFORT HOCHLADEN zu Cloudflare
        await _uploadImageToCloudflare(pickedFile);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Bild-Auswahl Fehler: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler beim Laden des Bildes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _uploadImageToCloudflare(XFile imageFile) async {
    try {
      final uploadService = ImageUploadService();
      
      // Upload mit User-ID
      final userId = _usernameController.text.trim().isEmpty 
          ? 'user_${DateTime.now().millisecondsSinceEpoch}'
          : _usernameController.text.trim();
      
      final imageUrl = await uploadService.uploadProfileImage(
        imageFile: imageFile,
        userId: userId,
        profileType: widget.world,
      );
      
      setState(() {
        _avatarUrl = imageUrl; // CDN URL setzen
      });
      
      if (kDebugMode) {
        debugPrint('✅ Bild hochgeladen: $imageUrl');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profilbild hochgeladen!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Upload Fehler: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Upload fehlgeschlagen: $e\n💡 Bild wird lokal gespeichert'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      // Behalte lokalen Pfad als Fallback
    }
  }
  
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Aus Galerie wählen'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (!kIsWeb) // Kamera nur auf Mobile
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.green),
                  title: const Text('Foto aufnehmen'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              if (_avatarUrl != null || _selectedEmoji != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Profilbild entfernen'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _avatarUrl = null;
                      _selectedImageFile = null;
                      _selectedEmoji = null;
                    });
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final storage = StorageService();
      await storage.init();
      
      if (widget.world == 'materie') {
        final profile = storage.getMaterieProfile();
        _materieProfile = profile;
        if (profile != null) {
          _usernameController.text = profile.username;
          _nameController.text = profile.name ?? '';
          _bioController.text = profile.bio ?? '';
          _selectedEmoji = profile.avatarEmoji;
          _avatarUrl = profile.avatarUrl;
        }
      } else {
        // energie, vorhang, ursprung all use the unified EnergieProfile (birth data)
        final profile = storage.getEnergieProfile();
        _energieProfile = profile;
        if (profile != null) {
          _usernameController.text = profile.username;
          _firstNameController.text = profile.firstName;
          _lastNameController.text = profile.lastName;
          _birthPlaceController.text = profile.birthPlace;
          _birthTimeController.text = profile.birthTime ?? '';
          _selectedBirthDate = profile.birthDate;
          // ✅ NEU: Initialisiere Birth Date Controller
          _birthDateController.text = DateFormat('dd.MM.yyyy').format(profile.birthDate);
                  _bioController.text = profile.bio ?? '';
          _selectedEmoji = profile.avatarEmoji;
          _avatarUrl = profile.avatarUrl;
          // ✨ v93: Spirit-Tools-Extras laden
          _birthLatitude = profile.birthLatitude;
          _birthLongitude = profile.birthLongitude;
          _timezoneOffsetHours = profile.timezoneOffsetHours;
          _birthTimeUnknown = profile.birthTimeUnknown;
          _gender = profile.gender;
          // ✨ v92: Username-Immutability-Tracking
          _originalUsername = profile.username.isEmpty ? null : profile.username;
          _userIsRootAdmin = profile.isRootAdmin();
          // Check for pending change request (async, fire-and-forget)
          if (_originalUsername != null && profile.userId != null) {
            _loadPendingUsernameRequest(profile.userId!);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden des Profils: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// v92: Check ob ein pending Username-Change-Request fuer diesen User
  /// existiert. Wird beim Profile-Load gerufen damit UI das Feld als
  /// "Antrag laeuft" markieren kann.
  Future<void> _loadPendingUsernameRequest(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.workerUrl}/api/profile/my-username-request?userId=$userId'),
      ).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200 || !mounted) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>? ?? {};
      final req = data['request'];
      if (req is Map) {
        setState(() {
          _pendingUsernameRequest = true;
          _pendingRequestedUsername = req['requested_username'] as String?;
        });
      }
    } catch (_) {/* non-fatal */}
  }

  /// v92: Bottom-Sheet Dialog wo der User einen Username-Wechsel beantragt.
  Future<void> _openUsernameChangeRequestDialog() async {
    if (_originalUsername == null) return;
    final userId = _energieProfile?.userId ?? _materieProfile?.userId;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Erst Profil speichern, dann Antrag stellen.'),
      ));
      return;
    }

    final newNameCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A0A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📝 Username-Antrag stellen',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            'Aktuell: @$_originalUsername\n\n'
            'Username ist nach erstmaliger Anlage gesperrt. '
            'Ein Admin entscheidet ueber deinen Wunschnamen.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: newNameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Wunsch-Username',
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              helperText: '3-32 Zeichen, nur a-z A-Z 0-9 . _ -',
              helperStyle: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: reasonCtrl,
            maxLines: 3,
            maxLength: 500,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Begruendung (optional)',
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              counterStyle: const TextStyle(color: Colors.white24, fontSize: 9),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Abbrechen', style: TextStyle(color: Colors.white70)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.send, size: 16),
                label: const Text('ANTRAG SENDEN'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );

    if (result != true) return;
    final requested = newNameCtrl.text.trim();
    if (requested.isEmpty || requested == _originalUsername) return;
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.workerUrl}/api/profile/username-change-request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'requested_username': requested,
          'reason': reasonCtrl.text.trim(),
        }),
      ).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>? ?? {};
      if (res.statusCode == 200 && data['success'] == true) {
        setState(() {
          _pendingUsernameRequest = data['direct'] != true;
          _pendingRequestedUsername = requested;
          if (data['direct'] == true) {
            // Root-Admin: sofort uebernommen
            _originalUsername = requested;
            _usernameController.text = requested;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data['message']?.toString() ?? 'Antrag eingereicht'),
          backgroundColor: const Color(0xFF26A69A),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data['error']?.toString() ?? 'Antrag fehlgeschlagen'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Netzwerk-Fehler: $e'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Pre-Save: finaler Username-Verfügbarkeits-Check (auch wenn User
    // schnell auf Speichern klickt während Live-Check noch lief).
    final desiredUsername = _usernameController.text.trim();
    final wasUsernameChanged =
        desiredUsername != (_materieProfile?.username ?? '') &&
            desiredUsername != (_energieProfile?.username ?? '');
    if (wasUsernameChanged) {
      setState(() => _isSaving = true);
      final result = await UsernameAvailabilityService.instance.check(
        desiredUsername,
        currentUsername: _materieProfile?.username ?? _energieProfile?.username,
      );
      if (!mounted) return;
      if (result.status == UsernameStatus.taken) {
        setState(() {
          _isSaving = false;
          _usernameCheck = result;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
      if (result.status == UsernameStatus.invalidFormat) {
        setState(() {
          _isSaving = false;
          _usernameCheck = result;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ ${result.message}'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      // Bei checkFailed lassen wir durch — Insert-Conflict fängt es ggf. ab
    }

    setState(() => _isSaving = true);

    // 🔥 FIX: Track Admin-Status für Toast
    bool isAdmin = false;
    bool isRootAdmin = false;

    try {
      final storage = StorageService();
      final syncService = ProfileSyncService(); // 🆕 Cloud-Sync Service
      
      if (widget.world == 'materie') {
        // 🔥 FIX: Verwende saveMaterieProfileAndGetUpdated für vollständige Backend-Sync
        final password = _isWeltenbibliothek ? _passwordController.text.trim() : null;
        
        final profile = MaterieProfile(
          username: _usernameController.text.trim(),
          name: _nameController.text.trim().isEmpty 
              ? null 
              : _nameController.text.trim(),
          bio: _bioController.text.trim().isEmpty 
              ? null 
              : _bioController.text.trim(),
          avatarEmoji: _selectedEmoji,
          avatarUrl: _avatarUrl,
        );
        
        // 🔥 FIX: Backend-Sync + Get Updated Profile (mit userId & role)
        final updatedProfile = await syncService.saveMaterieProfileAndGetUpdated(
          profile,
          password: password,
        );
        
        if (updatedProfile != null) {
          // 💾 Vollständiges Profil lokal speichern (mit userId & role)
          await storage.saveMaterieProfile(updatedProfile);
          // ✅ Sync in user_data Box (für AdminStateNotifier + Chat)
          await UnifiedStorageService().saveProfile('materie', {
            'username': updatedProfile.username,
            'role': updatedProfile.role ?? 'user',
            'avatar_emoji': updatedProfile.avatarEmoji,
            'avatar_url': updatedProfile.avatarUrl,
          });
          
          // ✅ Auth-Service aktualisieren für Inline-Tools
          await UserAuthService.setUsername(updatedProfile.username, world: 'materie');
          if (updatedProfile.userId != null) {
            await UserAuthService.setUserId(updatedProfile.userId!, world: 'materie');
          }
          
          // 🔥 Track Admin-Status für Toast
          isAdmin = updatedProfile.isAdmin();
          isRootAdmin = updatedProfile.isRootAdmin();
          
          if (kDebugMode) {
            debugPrint('✅ Materie-Profil gespeichert mit Backend-Daten:');
            debugPrint('   Username: ${updatedProfile.username}');
            debugPrint('   User ID: ${updatedProfile.userId}');
            debugPrint('   Role: ${updatedProfile.role}');
            debugPrint('   Is Admin: ${updatedProfile.isAdmin()}');
            debugPrint('   Is Root Admin: ${updatedProfile.isRootAdmin()}');
          }
        } else {
          // ✅ SECURITY FIX: Keine lokalen Admin-Rechte ohne Backend-Validierung
          // Speichere Profil NUR als normalen User
          await storage.saveMaterieProfile(profile);
          // ✅ Sync in user_data Box auch für Offline-Fallback
          await UnifiedStorageService().saveProfile('materie', {
            'username': profile.username,
            'role': 'user',
            'avatar_emoji': profile.avatarEmoji,
            'avatar_url': profile.avatarUrl,
          });
          
          // ✅ Auth-Service aktualisieren (ohne Backend-User-ID)
          await UserAuthService.setUsername(profile.username, world: 'materie');
          
          if (kDebugMode) {
            debugPrint('⚠️ Materie-Profil nur lokal gespeichert (Backend nicht erreichbar)');
            debugPrint('⚠️ Admin-Status erfordert Backend-Verbindung');
          }
          
          // Kein Warning-Banner für normale User – nur stiller Fallback
        }
        
      } else {
        // energie, vorhang, ursprung: all use the unified EnergieProfile (birth data)
        if (_selectedBirthDate == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Bitte wähle ein Geburtsdatum'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          setState(() => _isSaving = false);
          return;
        }
        
        // 🔥 FIX: Verwende saveEnergieProfileAndGetUpdated für vollständige Backend-Sync
        final password = _isWeltenbibliothek ? _passwordController.text.trim() : null;
        
        final profile = EnergieProfile(
          username: _usernameController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          birthDate: _selectedBirthDate!,
          birthPlace: _birthPlaceController.text.trim(),
          birthTime: _birthTimeController.text.trim().isEmpty
              ? null
              : _birthTimeController.text.trim(),
          bio: _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
          avatarEmoji: _selectedEmoji,
          avatarUrl: _avatarUrl,
          // ✨ v93: Spirit-Tools-Extras (Auto-Geocoding)
          birthLatitude: _birthLatitude,
          birthLongitude: _birthLongitude,
          timezoneOffsetHours: _timezoneOffsetHours,
          birthTimeUnknown: _birthTimeUnknown,
        );
        
        // 🔥 FIX: Backend-Sync + Get Updated Profile (mit userId & role)
        final updatedProfile = await syncService.saveEnergieProfileAndGetUpdated(
          profile,
          password: password,
        );
        
        if (updatedProfile != null) {
          // 💾 Vollständiges Profil lokal speichern (mit userId & role)
          await storage.saveEnergieProfile(updatedProfile);
          // Cross-sync username to MaterieProfile (unified profile)
          final existingMat = storage.getMaterieProfile();
          final syncedMat = MaterieProfile(
            username: updatedProfile.username,
            name: existingMat?.name ?? updatedProfile.fullName,
            avatarUrl: updatedProfile.avatarUrl,
            bio: updatedProfile.bio,
            avatarEmoji: updatedProfile.avatarEmoji,
            userId: updatedProfile.userId,
            role: updatedProfile.role,
          );
          await storage.saveMaterieProfile(syncedMat);
          // ✅ Sync in user_data Box (für AdminStateNotifier + Chat)
          await UnifiedStorageService().saveProfile('energie', {
            'username': updatedProfile.username,
            'role': updatedProfile.role ?? 'user',
            'avatar_emoji': updatedProfile.avatarEmoji,
            'avatar_url': updatedProfile.avatarUrl,
          });

          // ✅ Auth-Service aktualisieren für Inline-Tools
          await UserAuthService.setUsername(updatedProfile.username, world: 'energie');
          await UserAuthService.setUsername(updatedProfile.username, world: 'materie');
          if (updatedProfile.userId != null) {
            await UserAuthService.setUserId(updatedProfile.userId!, world: 'energie');
            await UserAuthService.setUserId(updatedProfile.userId!, world: 'materie');
          }

          // 🔥 Track Admin-Status für Toast
          isAdmin = updatedProfile.isAdmin();
          isRootAdmin = updatedProfile.isRootAdmin();
          
          if (kDebugMode) {
            debugPrint('✅ Energie-Profil gespeichert mit Backend-Daten:');
            debugPrint('   Username: ${updatedProfile.username}');
            debugPrint('   User ID: ${updatedProfile.userId}');
            debugPrint('   Role: ${updatedProfile.role}');
            debugPrint('   Is Admin: ${updatedProfile.isAdmin()}');
            debugPrint('   Is Root Admin: ${updatedProfile.isRootAdmin()}');
          }
        } else {
          // ✅ SECURITY FIX: Keine lokalen Admin-Rechte ohne Backend-Validierung
          // Speichere Profil NUR als normalen User
          await storage.saveEnergieProfile(profile);
          // Cross-sync username to MaterieProfile (unified profile)
          final existingMat2 = storage.getMaterieProfile();
          await storage.saveMaterieProfile(MaterieProfile(
            username: profile.username,
            name: existingMat2?.name ?? profile.fullName,
            avatarUrl: profile.avatarUrl,
            bio: profile.bio,
            avatarEmoji: profile.avatarEmoji,
          ));
          // ✅ Sync in user_data Box auch für Offline-Fallback
          await UnifiedStorageService().saveProfile('energie', {
            'username': profile.username,
            'role': 'user',
            'avatar_emoji': profile.avatarEmoji,
            'avatar_url': profile.avatarUrl,
          });

          // ✅ Auth-Service aktualisieren (ohne Backend-User-ID)
          await UserAuthService.setUsername(profile.username, world: 'energie');
          await UserAuthService.setUsername(profile.username, world: 'materie');
          
          if (kDebugMode) {
            debugPrint('⚠️ Energie-Profil nur lokal gespeichert (Backend nicht erreichbar)');
            debugPrint('⚠️ Admin-Status erfordert Backend-Verbindung');
          }
          
          // Kein Warning-Banner für normale User – nur stiller Fallback
        }
      }
      
      if (mounted) {
        // 🔥 FIX: Rolle-basierter Toast
        String message;
        Color backgroundColor;
        
        if (isRootAdmin) {
          message = '👑 Root-Admin aktiviert!';
          backgroundColor = const Color(0xFFFF6B00); // Orange
        } else if (isAdmin) {
          message = '⭐ Admin aktiviert!';
          backgroundColor = const Color(0xFFFF6B00); // Orange
        } else {
          message = '✅ Profil gespeichert!';
          backgroundColor = Colors.green;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
          ),
        );
        
        // 🌍 Spirit-Daten weltübergreifend in Supabase profiles speichern
        if (_selectedBirthDate != null ||
            _birthPlaceController.text.isNotEmpty ||
            _birthTimeController.text.isNotEmpty) {
          final fullName = widget.world == 'energie'
              ? '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim()
              : _nameController.text.trim();
          unawaited(SpiritProfileService.instance.save(
            fullName: fullName.isNotEmpty ? fullName : null,
            birthDate: _selectedBirthDate,
            birthTime: _birthTimeController.text.trim().isNotEmpty
                ? _birthTimeController.text.trim()
                : null,
            birthPlace: _birthPlaceController.text.trim().isNotEmpty
                ? _birthPlaceController.text.trim()
                : null,
          ));
        }

        // 🆕 RIVERPOD: Admin-State aktualisieren nach Profil-Speicherung
        ref.read(adminStateProvider(widget.world).notifier).refresh();
        
        // 🔄 AUTO-SAVE: Clear drafts after successful save
        AutoSaveManager().clearSavesForPrefix('profile_${widget.world}_');

        // PopScope: Dirty-Flag zurücksetzen damit Back-Navigation ohne Warnung geht
        if (mounted) {
          setState(() => _hasUnsavedChanges = false);
        }

        if (kDebugMode) {
          debugPrint('🔄 Admin-State für "${widget.world}" wurde refreshed');
          debugPrint('🗑️ Auto-Save drafts cleared for ${widget.world}');
        }

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Speichern: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // Berechnet die Felder die für den Completeness-Banner zählen.
  // Materie hat weniger Pflichtfelder als Energie (Geburtsdaten für die
  // Spirit-Tools).
  List<ProfileField> _completenessFields() {
    final hasAvatar = (_avatarUrl != null && _avatarUrl!.isNotEmpty)
        || (_selectedEmoji != null && _selectedEmoji!.isNotEmpty);
    final fields = <ProfileField>[
      ProfileField(
        key: 'username',
        label: 'Benutzername',
        filled: _usernameController.text.trim().isNotEmpty,
      ),
      ProfileField(key: 'avatar', label: 'Avatar', filled: hasAvatar),
      ProfileField(
        key: 'bio',
        label: 'Bio',
        filled: _bioController.text.trim().isNotEmpty,
      ),
    ];
    if (widget.world == 'materie') {
      fields.add(ProfileField(
        key: 'name',
        label: 'Name',
        filled: _nameController.text.trim().isNotEmpty,
      ));
    } else {
      fields.addAll([
        ProfileField(
          key: 'firstName',
          label: 'Vorname',
          filled: _firstNameController.text.trim().isNotEmpty,
        ),
        ProfileField(
          key: 'lastName',
          label: 'Nachname',
          filled: _lastNameController.text.trim().isNotEmpty,
        ),
        ProfileField(
          key: 'birthDate',
          label: 'Geburtsdatum',
          filled: _selectedBirthDate != null,
        ),
        ProfileField(
          key: 'birthPlace',
          label: 'Geburtsort',
          filled: _birthPlaceController.text.trim().isNotEmpty,
        ),
      ]);
    }
    return fields;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final worldColor = widget.world == 'materie'
        ? const Color(0xFF1E88E5)
        : const Color(0xFF7E57C2);
    
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscardChanges();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: WBGlassAppBar(
        world: WBWorld.neutral,
        title: '${widget.world == 'materie' ? 'Materie' : 'Energie'}-Profil bearbeiten',
      ),
      // ⛔ Speichern-FAB entfernt — der ElevatedButton "Profil speichern"
      // unten im Form reicht (User-Wunsch: nur EIN Save-Button).
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveWebContainer(
              variant: WebContainerVariant.compact,
              child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                onChanged: () {
                  if (!_hasUnsavedChanges) {
                    setState(() => _hasUnsavedChanges = true);
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Gamification: Fortschritts-Banner motiviert User
                    // die fehlenden Felder zu füllen.
                    ProfileCompletenessBar(
                      accent: worldColor,
                      fields: _completenessFields(),
                    ),
                    // Live-Preview: so sieht das Profil im Chat aus
                    ProfileChatPreview(
                      avatarUrl: _avatarUrl,
                      avatarEmoji: _selectedEmoji,
                      username: _usernameController.text,
                      displayName: widget.world == 'materie'
                          ? _nameController.text
                          : '${_firstNameController.text} ${_lastNameController.text}'.trim(),
                      accent: worldColor,
                    ),
                    // Avatar-Bereich
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  worldColor,
                                  worldColor.withValues(alpha: 0.6),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: worldColor.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: _selectedImageFile != null || (_avatarUrl != null && _avatarUrl!.startsWith('http'))
                              ? ClipOval(
                                  child: _selectedImageFile != null && !kIsWeb
                                    ? Image.file(
                                        _selectedImageFile! as dynamic,
                                        fit: BoxFit.cover,
                                        width: 120,
                                        height: 120,
                                      )
                                    : _avatarUrl != null
                                      ? Image.network(
                                          _avatarUrl!,
                                          fit: BoxFit.cover,
                                          width: 120,
                                          height: 120,
                                          errorBuilder: (context, error, stack) {
                                            return Center(
                                              child: Text(
                                                _selectedEmoji ?? '👤',
                                                style: const TextStyle(fontSize: 60),
                                              ),
                                            );
                                          },
                                        )
                                      : Center(
                                          child: Text(
                                            _selectedEmoji ?? '👤',
                                            style: const TextStyle(fontSize: 60),
                                          ),
                                        ),
                                )
                              : Center(
                                  child: Text(
                                    _selectedEmoji ?? '👤',
                                    style: const TextStyle(fontSize: 60),
                                  ),
                                ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Profilbild Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _showImageSourceDialog,
                                icon: const Icon(Icons.photo_camera, size: 18),
                                label: const Text('Bild'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: worldColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: _showEmojiPicker,
                                icon: const Icon(Icons.emoji_emotions, size: 18),
                                label: const Text('Emoji'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: worldColor.withValues(alpha: 0.8),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Username (für beide Welten) — mit Live-Verfügbarkeits-Check
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Benutzername (Chat-Name)',
                        hintText: 'Dein Chat-Name',
                        prefixIcon: const Icon(Icons.person),
                        suffixIcon: _buildUsernameStatusIcon(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white,
                        helperText: _buildUsernameHelperText(),
                        helperStyle: _buildUsernameHelperStyle(),
                        helperMaxLines: 2,
                      ),
                      onChanged: (value) {
                        setState(() {
                          final username = value.trim();
                          _isWeltenbibliothek = (username == 'Weltenbibliothek' ||
                              username == 'Weltenbibliothekedit');
                        });
                        _scheduleUsernameCheck(value);
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Benutzername ist erforderlich';
                        }
                        return null;
                      },
                    ),
                    // Vorschläge bei vergebenem Namen
                    if (_usernameCheck?.status == UsernameStatus.taken &&
                        _usernameCheck!.suggestions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _usernameCheck!.suggestions
                            .where((s) => s.length >= 3 && s.length <= 20)
                            .map((s) => ActionChip(
                                  label: Text(s),
                                  avatar: const Icon(Icons.auto_awesome,
                                      size: 14, color: Colors.amber),
                                  onPressed: () {
                                    _usernameController.text = s;
                                    _usernameController.selection =
                                        TextSelection.collapsed(
                                            offset: s.length);
                                    _scheduleUsernameCheck(s);
                                  },
                                ))
                            .toList(),
                      ),
                    ],
                    
                    // ✅ NEU: Root-Admin Passwortfeld (conditional)
                    if (_isWeltenbibliothek) ...[
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          border: Border.all(color: Colors.amber, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.admin_panel_settings, color: Colors.amber),
                                const SizedBox(width: 8),
                                Text(
                                  _usernameController.text.trim() == 'Weltenbibliothek' 
                                      ? '👑 Root-Admin Zugriff' 
                                      : '✏️ Content-Editor Zugriff',
                                  style: TextStyle(
                                    color: Colors.amber.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: _usernameController.text.trim() == 'Weltenbibliothek'
                                    ? '🔐 Root-Admin Passwort'
                                    : '🔐 Content-Editor Passwort',
                                hintText: _usernameController.text.trim() == 'Weltenbibliothek'
                                    ? 'Erforderlich für Root-Admin Rechte'
                                    : 'Erforderlich für Content-Editor Rechte',
                                prefixIcon: const Icon(Icons.lock),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (_isWeltenbibliothek) {
                                  if (value == null || value.isEmpty) {
                                    return 'Admin-Passwort erforderlich';
                                  }
                                  if (value != 'Jolene2305') {
                                    return 'Falsches Admin-Passwort';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'ℹ️ Admin-Accounts benötigen ein Passwort:\n'
                              '👑 "Weltenbibliothek" = Root-Admin (Vollzugriff)\n'
                              '✏️ "Weltenbibliothekedit" = Content-Editor (nur Content)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // MATERIE-SPEZIFISCHE FELDER
                    if (widget.world == 'materie') ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name (optional)',
                          hintText: 'Dein echter Name',
                          prefixIcon: const Icon(Icons.badge),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark 
                              ? Colors.white.withValues(alpha: 0.05) 
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // ENERGIE-SPEZIFISCHE FELDER
                    if (widget.world == 'energie') ...[
                      // Vorname
                      TextFormField(
                        controller: _firstNameController,
                        decoration: InputDecoration(
                          labelText: 'Vorname',
                          hintText: 'Dein Vorname',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark 
                              ? Colors.white.withValues(alpha: 0.05) 
                              : Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vorname ist erforderlich';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Nachname
                      TextFormField(
                        controller: _lastNameController,
                        decoration: InputDecoration(
                          labelText: 'Nachname',
                          hintText: 'Dein Nachname',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark 
                              ? Colors.white.withValues(alpha: 0.05) 
                              : Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nachname ist erforderlich';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // ✅ Geburtsdatum - Manuelle Eingabe mit Punkten + Kalender-Icon
                      TextFormField(
                        controller: _birthDateController,
                        decoration: InputDecoration(
                          labelText: 'Geburtsdatum',
                          hintText: 'TT.MM.JJJJ (z.B. 15.03.1990)',
                          prefixIcon: const Icon(Icons.cake),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: _selectBirthDate,
                            tooltip: 'Kalender öffnen',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark 
                              ? Colors.white.withValues(alpha: 0.05) 
                              : Colors.white,
                        ),
                        keyboardType: TextInputType.text, // ⌨️ Vollständige Text-Tastatur (nicht nur Zahlen)
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          LengthLimitingTextInputFormatter(10),
                          _DateInputFormatter(), // ✅ Auto-format with dots
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bitte Geburtsdatum eingeben';
                          }
                          // Validate format DD.MM.YYYY
                          final dateRegex = RegExp(r'^\d{2}\.\d{2}\.\d{4}$');
                          if (!dateRegex.hasMatch(value)) {
                            return 'Format: TT.MM.JJJJ (z.B. 15.03.1990)';
                          }
                          // Parse and validate date
                          try {
                            final parts = value.split('.');
                            final day = int.parse(parts[0]);
                            final month = int.parse(parts[1]);
                            final year = int.parse(parts[2]);
                            final date = DateTime(year, month, day);
                            if (date.isAfter(DateTime.now())) {
                              return 'Datum darf nicht in der Zukunft liegen';
                            }
                            if (year < 1900) {
                              return 'Jahr muss nach 1900 liegen';
                            }
                            // Update _selectedBirthDate when valid
                            _selectedBirthDate = date;
                          } catch (e) {
                            return 'Ungültiges Datum';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          // Try to parse date on each change
                          if (value.length == 10) {
                            try {
                              final parts = value.split('.');
                              final day = int.parse(parts[0]);
                              final month = int.parse(parts[1]);
                              final year = int.parse(parts[2]);
                              _selectedBirthDate = DateTime(year, month, day);
                            } catch (e) {
                              _selectedBirthDate = null;
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // ✨ v93: Geburtsort mit Auto-Geocoding (Stadt -> lat/lng/tz)
                      // User tippt nur Stadt-Name, wir holen Koordinaten + Timezone
                      // automatisch via OpenStreetMap Nominatim. Keine manuelle
                      // Eingabe von lat/lng/tz noetig.
                      BirthPlaceAutocomplete(
                        initialPlace: _birthPlaceController.text,
                        initialLatitude: _birthLatitude,
                        initialLongitude: _birthLongitude,
                        accentColor: const Color(0xFF7C4DFF), // Energie Lila
                        label: 'Geburtsort',
                        hintText: 'Stadt, Land tippen...',
                        onSelected: (place, lat, lng) {
                          setState(() {
                            _birthPlaceController.text = place;
                            _birthLatitude = lat;
                            _birthLongitude = lng;
                            // Timezone auto-inferieren aus lat/lng + Geburtsdatum
                            if (lat != null && lng != null) {
                              _timezoneOffsetHours = TimezoneHelper.inferOffsetHours(
                                latitude: lat,
                                longitude: lng,
                                birthDate: _selectedBirthDate,
                              );
                            } else {
                              // User hat frei getippt - Koordinaten zuruecksetzen
                              _timezoneOffsetHours = null;
                            }
                            _hasUnsavedChanges = true;
                          });
                        },
                      ),
                      if (_birthLatitude != null && _birthLongitude != null) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '✓ Koordinaten: ${_birthLatitude!.toStringAsFixed(4)}°, ${_birthLongitude!.toStringAsFixed(4)}°'
                            '${_timezoneOffsetHours != null ? "  ·  TZ ${TimezoneHelper.formatOffset(_timezoneOffsetHours!)}" : ""}',
                            style: TextStyle(
                              color: const Color(0xFF7C4DFF).withValues(alpha: 0.75),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      
                      // Geburtszeit (optional)
                      TextFormField(
                        controller: _birthTimeController,
                        decoration: InputDecoration(
                          labelText: 'Geburtszeit (optional)',
                          hintText: 'HH:MM (z.B. 14:30)',
                          prefixIcon: const Icon(Icons.access_time),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark 
                              ? Colors.white.withValues(alpha: 0.05) 
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Bio (für beide Welten)
                    TextFormField(
                      controller: _bioController,
                      maxLines: 4,
                      maxLength: 200,
                      decoration: InputDecoration(
                        labelText: 'Bio (optional)',
                        hintText: 'Erzähl etwas über dich...',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark 
                            ? Colors.white.withValues(alpha: 0.05) 
                            : Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Speichern-Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: worldColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Profil speichern',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            ),
    ),
    );
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: widget.world == 'materie' 
                  ? const Color(0xFF1E88E5) 
                  : const Color(0xFF7E57C2),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        // ✅ Update controller when date is picked from calendar
        _birthDateController.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1A1A)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Wähle deinen Avatar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: _emojiOptions.length,
                  itemBuilder: (context, index) {
                    final emoji = _emojiOptions[index];
                    final isSelected = emoji == _selectedEmoji;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedEmoji = emoji);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? (widget.world == 'materie'
                                  ? const Color(0xFF1E88E5)
                                  : const Color(0xFF7E57C2)
                                ).withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? (widget.world == 'materie'
                                    ? const Color(0xFF1E88E5)
                                    : const Color(0xFF7E57C2))
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// ✅ Custom Date Input Formatter
/// Erlaubt manuelle Eingabe mit Punkten (z.B. 15.03.1990)
/// Auto-formatiert während der Eingabe
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    // Nur Zahlen und Punkte erlauben
    if (text.isNotEmpty && !RegExp(r'^[0-9.]*$').hasMatch(text)) {
      return oldValue;
    }
    
    // Auto-insert dots at positions 2 and 5 (after DD and MM)
    String formatted = text.replaceAll('.', ''); // Remove existing dots
    
    if (formatted.length > 2) {
      formatted = '${formatted.substring(0, 2)}.${formatted.substring(2)}';
    }
    if (formatted.length > 5) {
      formatted = '${formatted.substring(0, 5)}.${formatted.substring(5)}';
    }
    
    // Limit to 10 characters (DD.MM.YYYY)
    if (formatted.length > 10) {
      formatted = formatted.substring(0, 10);
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
