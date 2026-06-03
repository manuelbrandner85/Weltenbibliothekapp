import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:url_launcher/url_launcher.dart';
// OpenClaw v2.0
import '../config/wb_design.dart'; // 🎨 Design-Tokens
import '../theme/wb_cinematic_tokens.dart';
import '../widgets/cinematic/wb_glass_app_bar.dart';
import '../widgets/cinematic/wb_vignette.dart';
import '../widgets/responsive_web_container.dart';
import '../services/storage_service.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; // 📸 Image Picker
import '../models/materie_profile.dart';
import '../models/energie_profile.dart';
import '../services/cloudflare_sync_service.dart'; // 🆕 SYNC SERVICE
import '../services/avatar_upload_service.dart'; // 👤 AVATAR UPLOAD
import '../services/supabase_service.dart'; // 🔥 Supabase Auth
import '../services/haptic_service.dart';
import '../services/haptic_feedback_service.dart'; // 📳 NEW: Haptic Feedback
import '../services/privacy_mode_service.dart'; // 🛡️ D3
import '../services/account_service.dart'; // ⚠️ v117 Konto-Verwaltung
import '../services/unified_profile_service.dart'; // v117 Identitaet
import '../widgets/theme_toggle_widget.dart';
import 'shared/profile_editor_screen.dart'; // 🆕 NEW EDITOR
import 'shared/secret_library_screen.dart'; // 📚 Geheime Bibliothek
import '../services/gamification_service.dart';
import '../widgets/cross_world_overview_card.dart';

/// **PROFIL-EINSTELLUNGEN**
///
/// Zentrale Verwaltung für beide Profile:
/// - Materie-Profil anzeigen/bearbeiten
/// - Energie-Profil anzeigen/bearbeiten
/// - Profile löschen
/// - Profile exportieren (geplant)
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final StorageService _storageService = StorageService();

  MaterieProfile? _materieProfile;
  EnergieProfile? _energieProfile;

  bool _isLoading = true;
  bool _isUploadingAvatar = false;
  String? _avatarUrl;

  /// Mappt technische Avatar-Upload-Errors auf nutzerfreundliche deutsche Texte.
  String _avatarErrorMessage(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('socket') ||
        s.contains('failed host lookup') ||
        s.contains('network')) {
      return '📡 Keine Internet-Verbindung — bitte WLAN/Mobilfunk prüfen.';
    }
    if (s.contains('timeout') || s.contains('timed out')) {
      return '⏱️ Upload-Timeout — bitte später erneut versuchen.';
    }
    if (s.contains('413') || s.contains('too large')) {
      return '📏 Bild zu groß — bitte ein kleineres wählen (max 5 MB).';
    }
    if (s.contains('401') || s.contains('unauthorized')) {
      return '🔒 Nicht angemeldet — bitte App neu starten und einloggen.';
    }
    return '⚠️ Upload fehlgeschlagen — bitte später erneut versuchen.';
  }

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);

    try {
      final materieProfile = _storageService.getMaterieProfile();
      final energieProfile = _storageService.getEnergieProfile();

      setState(() {
        _materieProfile = materieProfile;
        _energieProfile = energieProfile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Fehler beim Laden der Profile. Bitte erneut versuchen.')),
        );
      }
    }
  }

  /// Materie-Profil bearbeiten
  Future<void> _editMaterieProfile() async {
    HapticService.selectionClick();

    if (!mounted) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileEditorScreen(
          world: 'materie',
        ),
      ),
    );

    if (result == true) {
      await _loadProfiles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Materie-Profil aktualisiert'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// Profil bearbeiten — öffnet unified Energie-Editor (Spirit-Daten + Username)
  Future<void> _editEnergieProfile() async {
    HapticService.selectionClick();

    if (!mounted) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileEditorScreen(
          world: 'energie',
        ),
      ),
    );

    if (result == true) {
      await _loadProfiles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profil aktualisiert'),
            backgroundColor: Color(0xFF7C4DFF),
          ),
        );
      }
    }
  }

  /// Materie-Profil löschen mit Bestätigung
  Future<void> _deleteMaterieProfile() async {
    HapticService.selectionClick();

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Materie-Profil löschen?'),
        content: const Text(
          'Diese Aktion kann nicht rückgängig gemacht werden.\n\n'
          'Alle Materie-bezogenen Daten (Recherche-Verlauf, Bookmarks) gehen verloren.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.deleteMaterieProfile();
      await _loadProfiles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Materie-Profil gelöscht'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Energie-Profil löschen mit Bestätigung
  Future<void> _deleteEnergieProfile() async {
    HapticService.selectionClick();

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Energie-Profil löschen?'),
        content: const Text(
          'Diese Aktion kann nicht rückgängig gemacht werden.\n\n'
          'Alle Spirit-Tool-Berechnungen müssen neu erstellt werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.deleteEnergieProfile();
      await _loadProfiles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Energie-Profil gelöscht'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000004),
      appBar: const WBGlassAppBar(
        title: 'Profil-Einstellungen',
        world: WBWorld.neutral,
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0D0A1A),
                    Color(0xFF050310),
                    Color(0xFF000004)
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: IgnorePointer(child: WBVignette())),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ResponsiveWebContainer(
                  variant: WebContainerVariant.compact,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // UNIFIED PROFIL SEKTION (eine Karte für alle 4 Welten)
                        _buildSectionHeader(
                            '👤 MEIN PROFIL', const Color(0xFF7C4DFF)),
                        const SizedBox(height: 12),

                        if (_energieProfile != null && _energieProfile!.isValid)
                          _buildUnifiedProfileCard()
                        else if (_materieProfile != null &&
                            _materieProfile!.isValid)
                          _buildUnifiedProfileCard()
                        else
                          _buildEmptyProfileCard(
                            worldName: 'Profil',
                            worldColor: const Color(0xFF7C4DFF),
                            onCreateTap: _editEnergieProfile,
                          ),

                        const SizedBox(height: 32),

                        // A2: CROSS-WORLD-UEBERSICHT
                        _buildSectionHeader(
                            '🌌 WELTEN-FORTSCHRITT', Colors.amber),
                        const SizedBox(height: 12),
                        const CrossWorldOverviewCard(),

                        const SizedBox(height: 32),

                        // DATENSCHUTZ-HINWEIS
                        _buildPrivacyNotice(),

                        const SizedBox(height: 32),

                        // DESIGN-EINSTELLUNGEN
                        _buildSectionHeader('🎨 DESIGN', Colors.teal),
                        const SizedBox(height: 12),
                        const ThemeToggleWidget(),

                        const SizedBox(height: 32),

                        // 📳 HAPTIC FEEDBACK EINSTELLUNGEN (NEU)
                        _buildSectionHeader(
                            '📳 HAPTIC FEEDBACK', Colors.orange),
                        const SizedBox(height: 12),
                        _buildHapticFeedbackCard(),

                        const SizedBox(height: 32),

                        // 📚 GEHEIME BIBLIOTHEK — Ab Level 10
                        _buildSectionHeader(
                            '📚 GEHEIME BIBLIOTHEK', const Color(0xFFC9A84C)),
                        const SizedBox(height: 12),
                        _buildSecretLibraryCard(),

                        const SizedBox(height: 32),

                        // 🛡️ D3 Privacy-Mode für OSINT-Tools
                        _buildSectionHeader(
                            '🛡️ PRIVACY', const Color(0xFF00D4AA)),
                        const SizedBox(height: 12),
                        const _PrivacyModeCard(),

                        const SizedBox(height: 32),

                        // 🤝 MENSAENA — Schwester-Plattform für Nachbarschaftshilfe
                        _buildSectionHeader(
                            '🤝 GEMEINSCHAFT', const Color(0xFF26A69A)),
                        const SizedBox(height: 12),
                        _buildMensaenaCard(),

                        const SizedBox(height: 32),

                        // ⚠️ KONTO — Einspruch + Selbst-Loeschung (v117)
                        _buildSectionHeader('⚠️ KONTO', Colors.redAccent),
                        const SizedBox(height: 12),
                        _buildAccountCard(),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  /// v117: Konto-Verwaltung -- Einspruch gegen Sperre + Selbst-Loeschung.
  Widget _buildAccountCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12101C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        ListTile(
          leading: const Icon(Icons.gavel_rounded, color: Colors.orangeAccent),
          title: const Text('Einspruch gegen Sperre',
              style: TextStyle(color: Colors.white, fontSize: 14)),
          subtitle: const Text(
              'Wenn du gesperrt wurdest, kannst du hier Einspruch einlegen.',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
          trailing: const Icon(Icons.chevron_right, color: Colors.white38),
          onTap: _showAppealDialog,
        ),
        const Divider(height: 1, color: Colors.white10),
        ListTile(
          leading:
              const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
          title: const Text('Konto-Loeschung beantragen',
              style: TextStyle(color: Colors.white, fontSize: 14)),
          subtitle: const Text(
              'Ein Admin prueft und loescht dein Konto endgueltig.',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
          trailing: const Icon(Icons.chevron_right, color: Colors.white38),
          onTap: _showSelfDeleteDialog,
        ),
      ]),
    );
  }

  Future<void> _showAppealDialog() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12101C),
        title: const Text('Einspruch einlegen',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Beschreibe, warum die Sperre aufgehoben werden soll...',
            hintStyle: TextStyle(color: Colors.white30),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Senden',
                  style: TextStyle(color: Colors.orangeAccent))),
        ],
      ),
    );
    if (ok != true) return;
    final uid = UnifiedProfileService.instance.userId;
    if (uid == null) return;
    final sent = await AccountService.instance.submitAppeal(
      userId: uid,
      username: UnifiedProfileService.instance.username,
      message: ctrl.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(sent
          ? 'Einspruch gesendet. Ein Admin prueft ihn.'
          : 'Senden fehlgeschlagen.'),
    ));
  }

  Future<void> _showSelfDeleteDialog() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12101C),
        title: const Text('Konto-Loeschung',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Dein Antrag wird an einen Admin geschickt. Nach Bestaetigung '
              'wird dein Konto endgueltig geloescht und eine Neuanmeldung mit '
              'denselben Daten ist gesperrt.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Grund (optional)',
                hintStyle: TextStyle(color: Colors.white30),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Loeschung beantragen',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok != true) return;
    final ups = UnifiedProfileService.instance;
    if (ups.userId == null) return;
    final sent = await AccountService.instance.requestSelfDeletion(
      userId: ups.userId!,
      username: ups.username,
      fullName: ups.displayName,
      birthDate: ups.birthDate?.toIso8601String().split('T').first,
      birthPlace: ups.birthPlace,
      message: ctrl.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(sent
          ? 'Loeschungs-Antrag gesendet.'
          : 'Senden fehlgeschlagen.'),
    ));
  }

  /// Section-Header mit Gradient-Bar
  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.3)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Unified Profil Card — zeigt EnergieProfile (mit Geburtsdaten) bevorzugt,
  /// fällt auf MaterieProfile zurück wenn EnergieProfile nicht existiert.
  Widget _buildUnifiedProfileCard() {
    final dateFormat = DateFormat('dd.MM.yyyy');
    // EnergieProfile ist primary; MaterieProfile als Fallback für username
    final hasEnergie = _energieProfile != null && _energieProfile!.isValid;
    final displayName = hasEnergie
        ? _energieProfile!.displayName
        : (_materieProfile?.displayName ?? '');
    final username = hasEnergie
        ? _energieProfile!.username
        : (_materieProfile?.username ?? '');
    final avatarEmoji = hasEnergie
        ? (_energieProfile!.avatarEmoji ?? '👤')
        : (_materieProfile?.avatarEmoji ?? '👤');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF7C4DFF).withValues(alpha: 0.12),
            const Color(0xFFC9A84C).withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + Name
          Row(
            children: [
              GestureDetector(
                onTap: _isUploadingAvatar
                    ? null
                    : () async {
                        final source =
                            await AvatarUploadService.showImageSourceDialog(
                                context);
                        if (source == null || !mounted) return;
                        final avatarService = AvatarUploadService();
                        final file = source == ImageSource.gallery
                            ? await avatarService.pickImageFromGallery()
                            : await avatarService.pickImageFromCamera();
                        if (file == null || !mounted) return;
                        setState(() => _isUploadingAvatar = true);
                        try {
                          final userId = supabase.auth.currentUser?.id ??
                              _energieProfile?.userId ??
                              _materieProfile?.userId ??
                              'anonymous';
                          final url =
                              await avatarService.uploadAvatar(file, userId);
                          if (!mounted) return;
                          if (url != null) setState(() => _avatarUrl = url);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(url != null
                                ? '✅ Profilbild gespeichert'
                                : '⚠️ Upload fehlgeschlagen'),
                            backgroundColor:
                                url != null ? Colors.green : Colors.orange,
                          ));
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(_avatarErrorMessage(e)),
                            backgroundColor: Colors.red,
                          ));
                        } finally {
                          if (mounted) {
                            setState(() => _isUploadingAvatar = false);
                          }
                        }
                      },
                child: Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C4DFF), Color(0xFFC9A84C)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF7C4DFF), width: 2),
                      ),
                      child: Center(
                        child: _isUploadingAvatar
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white)),
                              )
                            : Text(avatarEmoji,
                                style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C4DFF),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          _isUploadingAvatar
                              ? Icons.hourglass_top
                              : Icons.camera_alt,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '@$username',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    if (hasEnergie) ...[
                      const SizedBox(height: 2),
                      Text(
                        '✨ Spirit-Profil aktiv',
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFF7C4DFF).withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Geburtsdaten (nur wenn EnergieProfile vorhanden)
          if (hasEnergie) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    '📅 Geburtsdatum',
                    dateFormat.format(_energieProfile!.birthDate),
                  ),
                  if (_energieProfile!.birthTime != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                        '🕐 Geburtszeit', _energieProfile!.birthTime!),
                  ],
                  const SizedBox(height: 8),
                  _buildInfoRow('📍 Geburtsort', _energieProfile!.birthPlace),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Aktionen
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _editEnergieProfile,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Bearbeiten'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF7C4DFF),
                    side: const BorderSide(color: Color(0xFF7C4DFF)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _deleteUnifiedProfile,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Löschen'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Unified Profil löschen (beide Profile)
  Future<void> _deleteUnifiedProfile() async {
    HapticService.selectionClick();
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Profil löschen?'),
        content: const Text(
          'Alle Profildaten werden gelöscht.\n\n'
          'Spirit-Tool-Berechnungen müssen neu erstellt werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _storageService.deleteEnergieProfile();
      await _storageService.deleteMaterieProfile();
      await _loadProfiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Profil gelöscht'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Materie-Profil Card (Legacy — noch intern, aber nicht mehr im Layout)
  Widget _buildMaterieProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            WbDesign.materieBlue.withValues(alpha: 0.1),
            WbDesign.materieBlue.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: WbDesign.materieBlue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + Name (mit Upload-Funktion)
          Row(
            children: [
              GestureDetector(
                onTap: _isUploadingAvatar
                    ? null
                    : () async {
                        final source =
                            await AvatarUploadService.showImageSourceDialog(
                                context);
                        if (source == null || !mounted) return;

                        final avatarService = AvatarUploadService();
                        final file = source == ImageSource.gallery
                            ? await avatarService.pickImageFromGallery()
                            : await avatarService.pickImageFromCamera();
                        if (file == null || !mounted) return;

                        setState(() => _isUploadingAvatar = true);
                        try {
                          final userId = supabase.auth.currentUser?.id ??
                              _materieProfile?.userId ??
                              _energieProfile?.userId ??
                              'anonymous';
                          final url =
                              await avatarService.uploadAvatar(file, userId);
                          if (!mounted) return;
                          if (url != null) setState(() => _avatarUrl = url);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(url != null
                                  ? '✅ Profilbild gespeichert'
                                  : '⚠️ Upload fehlgeschlagen — bitte später erneut versuchen'),
                              backgroundColor:
                                  url != null ? Colors.green : Colors.orange,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_avatarErrorMessage(e)),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isUploadingAvatar = false);
                          }
                        }
                      },
                child: Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2196F3), Color(0xFF00BCD4)],
                        ),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: WbDesign.materieBlue, width: 2),
                      ),
                      child: Center(
                        child: _isUploadingAvatar
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text(
                                '🔵',
                                style: TextStyle(fontSize: 28),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: WbDesign.materieBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          _isUploadingAvatar
                              ? Icons.hourglass_top
                              : Icons.camera_alt,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _materieProfile!.displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '@${_materieProfile!.username}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Aktionen
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _editMaterieProfile,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Bearbeiten'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: WbDesign.materieBlue,
                    side: const BorderSide(color: WbDesign.materieBlue),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _deleteMaterieProfile,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Löschen'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Energie-Profil Card
  Widget _buildEnergieProfileCard() {
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            WbDesign.energiePurple.withValues(alpha: 0.1),
            WbDesign.energiePurple.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: WbDesign.energiePurple.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + Name (mit Upload-Funktion)
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  final source =
                      await AvatarUploadService.showImageSourceDialog(context);
                  if (source != null && mounted) {
                    final avatarService = AvatarUploadService();
                    final file = source == ImageSource.gallery
                        ? await avatarService.pickImageFromGallery()
                        : await avatarService.pickImageFromCamera();

                    if (file != null && mounted) {
                      // ✅ Upload avatar to server (Energie section)
                      final userId = supabase.auth.currentUser?.id ??
                          _energieProfile?.userId ??
                          _materieProfile?.userId ??
                          'anonymous';
                      final avatarSvc = AvatarUploadService();
                      final url = await avatarSvc.uploadAvatar(file, userId);
                      if (mounted) {
                        if (url != null) setState(() => _avatarUrl = url);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(url != null
                                  ? '✅ Profilbild gespeichert'
                                  : '⚠️ Upload fehlgeschlagen')),
                        );
                      }
                    }
                  }
                },
                child: Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                        ),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: WbDesign.energiePurple, width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          '🟣',
                          style: TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: WbDesign.energiePurple,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _energieProfile!.displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '@${_energieProfile!.username}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Geburtsdaten
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  '📅 Geburtsdatum',
                  dateFormat.format(_energieProfile!.birthDate),
                ),
                if (_energieProfile!.birthTime != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    '🕐 Geburtszeit',
                    _energieProfile!.birthTime!,
                  ),
                ],
                const SizedBox(height: 8),
                _buildInfoRow(
                  '📍 Geburtsort',
                  _energieProfile!.birthPlace,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Aktionen
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _editEnergieProfile,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Bearbeiten'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: WbDesign.energiePurple,
                    side: const BorderSide(color: WbDesign.energiePurple),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _deleteEnergieProfile,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Löschen'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Info-Row (Label + Value)
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Empty Profile Card (Profil erstellen)
  Widget _buildEmptyProfileCard({
    required String worldName,
    required Color worldColor,
    required VoidCallback onCreateTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: worldColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_add_outlined,
            size: 48,
            color: worldColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Kein $worldName-Profil',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: worldColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Erstelle ein Profil, um alle Features zu nutzen',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreateTap,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Profil erstellen'),
            style: FilledButton.styleFrom(
              backgroundColor: worldColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Datenschutz-Hinweis
  Widget _buildPrivacyNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.privacy_tip_outlined,
            color: Colors.white.withValues(alpha: 0.5),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '🔒 Datenschutz\n\n'
              'Alle Profildaten werden lokal auf deinem Gerät gespeichert. '
              'Es findet keine Cloud-Synchronisation statt.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ☁️ Cloud-Sync Card — NICHT MEHR im Profil-Layout sichtbar (entfernt
  /// auf Wunsch des Users). Methode bleibt als Tot-Code zur Reaktivierung.
  // ignore: unused_element
  Widget _buildCloudSyncCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.cyan.withValues(alpha: 0.1),
            Colors.cyan.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.cyan.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.cyan.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_sync,
                  color: Colors.cyan,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cloud-Synchronisation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sichere deine Profile in der Cloud',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sync-Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _syncToCloud,
                  icon: const Icon(Icons.cloud_upload, size: 20),
                  label: const Text('Backup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _restoreFromCloud,
                  icon: const Icon(Icons.cloud_download, size: 20),
                  label: const Text('Restore'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan.withValues(alpha: 0.2),
                    foregroundColor: Colors.cyan,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ☁️ Sync to Cloud — UI entfernt, Methode bleibt erreichbar via
  /// `_buildCloudSyncCard` falls Sektion wieder eingeblendet wird.
  // ignore: unused_element
  Future<void> _syncToCloud() async {
    HapticService.selectionClick();

    try {
      final syncService = CloudflareSyncService();
      await syncService.autoSync();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile in Cloud gesichert'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Sync-Fehler. Bitte erneut versuchen.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ☁️ Restore from Cloud
  // ignore: unused_element
  Future<void> _restoreFromCloud() async {
    HapticService.selectionClick();

    if (!mounted) return;

    // Username-Dialog mit Controller-Lifecycle in try/finally garantiert
    final usernameController = TextEditingController();
    String? username;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('☁️ Aus Cloud wiederherstellen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Gib deinen Username ein:'),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  hintText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Wiederherstellen'),
            ),
          ],
        ),
      );
      if (confirmed == true && usernameController.text.isNotEmpty) {
        username = usernameController.text;
      }
    } finally {
      usernameController.dispose();
    }

    if (username == null) return;

    try {
      final syncService = CloudflareSyncService();

      // Restore Materie
      final materieProfile = await syncService.restoreMaterieProfile(username);
      if (materieProfile != null) {
        await _storageService.saveMaterieProfile(materieProfile);
      }

      // Restore Energie
      final energieProfile = await syncService.restoreEnergieProfile(username);
      if (energieProfile != null) {
        await _storageService.saveEnergieProfile(energieProfile);
      }

      await _loadProfiles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile wiederhergestellt'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Restore-Fehler. Bitte erneut versuchen.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 📳 Haptic Feedback Card (NEU)
  Widget _buildHapticFeedbackCard() {
    return FutureBuilder<bool>(
      future: HapticFeedbackService()
          .initialize()
          .then((_) => HapticFeedbackService().isEnabled),
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? true;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.withValues(alpha: 0.1),
                Colors.orange.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.orange.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.vibration,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Haptic Feedback',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEnabled
                              ? '✅ Aktiviert - Spüre jede Interaktion'
                              : '⚪ Deaktiviert - Keine Vibration',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isEnabled,
                    onChanged: (value) async {
                      await HapticFeedbackService().setEnabled(value);
                      if (value) {
                        await HapticFeedbackService().success();
                      }
                      if (mounted) setState(() {}); // Rebuild to update UI
                    },
                    activeColor: Colors.orange,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Feedback-Typ Beispiele
              Text(
                '🎯 Feedback-Typen:',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildHapticTestButton(
                    label: 'Light',
                    icon: Icons.touch_app,
                    color: Colors.green,
                    onTap: () => HapticFeedbackService().light(),
                  ),
                  _buildHapticTestButton(
                    label: 'Medium',
                    icon: Icons.touch_app,
                    color: Colors.orange,
                    onTap: () => HapticFeedbackService().medium(),
                  ),
                  _buildHapticTestButton(
                    label: 'Heavy',
                    icon: Icons.touch_app,
                    color: Colors.red,
                    onTap: () => HapticFeedbackService().heavy(),
                  ),
                  _buildHapticTestButton(
                    label: 'Success',
                    icon: Icons.check_circle,
                    color: Colors.green,
                    onTap: () => HapticFeedbackService().success(),
                  ),
                  _buildHapticTestButton(
                    label: 'Error',
                    icon: Icons.error,
                    color: Colors.red,
                    onTap: () => HapticFeedbackService().error(),
                  ),
                  _buildHapticTestButton(
                    label: 'Warning',
                    icon: Icons.warning,
                    color: Colors.orange,
                    onTap: () => HapticFeedbackService().warning(),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tippe auf einen Button, um verschiedene Feedback-Typen zu testen',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Haptic Test Button Widget
  Widget _buildHapticTestButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🤝 Mensaena — Schwester-Plattform für Nachbarschaftshilfe.
  /// 📚 Geheime Bibliothek — Card mit Lock-State je nach Global-Level.
  Widget _buildSecretLibraryCard() {
    const gold = Color(0xFFC9A84C);
    const goldLight = Color(0xFFE0C872);
    final level = GamificationService().globalLevel;
    final unlocked = level >= SecretLibraryScreen.requiredLevel;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticService.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SecretLibraryScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: unlocked
                ? [gold.withValues(alpha: 0.25), gold.withValues(alpha: 0.08)]
                : [
                    Colors.white.withValues(alpha: 0.04),
                    Colors.white.withValues(alpha: 0.02)
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: unlocked
                ? gold.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.1),
            width: unlocked ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: unlocked
                    ? gold.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                unlocked ? Icons.menu_book : Icons.lock_outline,
                color: unlocked ? goldLight : Colors.white54,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unlocked ? 'Die Geheime Bibliothek' : 'Geheime Bibliothek',
                    style: TextStyle(
                      color: unlocked ? goldLight : Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unlocked
                        ? 'Originalquellen · 6 Kategorien'
                        : 'Ab Level ${SecretLibraryScreen.requiredLevel} (aktuell: Level $level)',
                    style: TextStyle(
                      color: unlocked
                          ? goldLight.withValues(alpha: 0.75)
                          : Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: unlocked ? goldLight : Colors.white38,
            ),
          ],
        ),
      ),
    );
  }

  /// Optionaler Banner der den User auf mensaena.de verlinkt. Bewusst
  /// dezent gehalten damit es nicht aufdringlich wirkt.
  Widget _buildMensaenaCard() {
    const teal = Color(0xFF26A69A);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [teal.withValues(alpha: 0.18), teal.withValues(alpha: 0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: teal.withValues(alpha: 0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.handshake,
                  color: teal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Mensaena',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Unsere Schwester-Plattform für echte Nachbarschaftshilfe — '
            'Hilfe anbieten, Hilfe finden, Menschen in deiner Nähe '
            'kennenlernen.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openMensaena,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Mensaena öffnen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMensaena() async {
    final uri = Uri.parse('https://www.mensaena.de');
    try {
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konnte Mensaena nicht öffnen.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Mensaena-Launch fehlgeschlagen: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konnte Mensaena nicht öffnen.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // 🧹 PHASE B: Proper resource disposal
    super.dispose();
  }
}

// 🛡️ D3: Privacy-Mode-Toggle für OSINT-Tools-Calls über Worker-Proxy
class _PrivacyModeCard extends StatefulWidget {
  const _PrivacyModeCard();
  @override
  State<_PrivacyModeCard> createState() => _PrivacyModeCardState();
}

class _PrivacyModeCardState extends State<_PrivacyModeCard> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    PrivacyModeService.instance.load().then((_) {
      if (mounted) setState(() => _loading = false);
    });
    PrivacyModeService.instance.addListener(_onChange);
  }

  @override
  void dispose() {
    PrivacyModeService.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(height: 70);
    }
    final enabled = PrivacyModeService.instance.enabled;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12121E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              const Color(0xFF00D4AA).withValues(alpha: enabled ? 0.4 : 0.12),
        ),
      ),
      child: SwitchListTile(
        title: const Text('Privacy-Mode für OSINT-Tools',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(
          enabled
              ? 'Aktiv — Tool-Calls über Worker-Proxy, anonymer User-Agent.'
              : 'Aus — Tools rufen Ziel-Server direkt an.',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
        ),
        value: enabled,
        activeColor: const Color(0xFF00D4AA),
        onChanged: (v) => PrivacyModeService.instance.setEnabled(v),
        secondary: Icon(
          enabled ? Icons.privacy_tip : Icons.privacy_tip_outlined,
          color: enabled ? const Color(0xFF00D4AA) : Colors.white38,
        ),
      ),
    );
  }
}
