import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; // 📸 Image Picker
import '../models/materie_profile.dart';
import '../models/energie_profile.dart';
import '../services/cloudflare_sync_service.dart'; // 🆕 SYNC SERVICE
import '../services/avatar_upload_service.dart'; // 👤 AVATAR UPLOAD
import '../services/haptic_service.dart';
import '../services/haptic_feedback_service.dart'; // 📳 NEW: Haptic Feedback
import '../widgets/theme_toggle_widget.dart';
import 'shared/profile_editor_screen.dart'; // 🆕 NEW EDITOR

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
          SnackBar(content: Text('Fehler beim Laden der Profile: $e')),
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
  
  /// Energie-Profil bearbeiten
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
            content: Text('✅ Energie-Profil aktualisiert'),
            backgroundColor: Colors.purple,
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
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('👤 Profil-Einstellungen'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MATERIE-PROFIL SEKTION
                  _buildSectionHeader('🔵 MATERIE-PROFIL', Colors.blue),
                  const SizedBox(height: 12),
                  
                  if (_materieProfile != null && _materieProfile!.isValid)
                    _buildMaterieProfileCard()
                  else
                    _buildEmptyProfileCard(
                      worldName: 'Materie',
                      worldColor: Colors.blue,
                      onCreateTap: _editMaterieProfile,
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // ENERGIE-PROFIL SEKTION
                  _buildSectionHeader('🟣 ENERGIE-PROFIL', Colors.purple),
                  const SizedBox(height: 12),
                  
                  if (_energieProfile != null && _energieProfile!.isValid)
                    _buildEnergieProfileCard()
                  else
                    _buildEmptyProfileCard(
                      worldName: 'Energie',
                      worldColor: Colors.purple,
                      onCreateTap: _editEnergieProfile,
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // DATENSCHUTZ-HINWEIS
                  _buildPrivacyNotice(),
                  
                  const SizedBox(height: 32),
                  
                  // ☁️ CLOUD-SYNC SEKTION
                  _buildSectionHeader('☁️ CLOUD-SYNC', Colors.cyan),
                  const SizedBox(height: 12),
                  _buildCloudSyncCard(),
                  
                  const SizedBox(height: 32),
                  
                  // Backend Health Monitor removed
                  
                  const SizedBox(height: 32),
                  
                  // DESIGN-EINSTELLUNGEN
                  _buildSectionHeader('🎨 DESIGN', Colors.teal),
                  const SizedBox(height: 12),
                  const ThemeToggleWidget(),
                  
                  const SizedBox(height: 32),
                  
                  // 📳 HAPTIC FEEDBACK EINSTELLUNGEN (NEU)
                  _buildSectionHeader('📳 HAPTIC FEEDBACK', Colors.orange),
                  const SizedBox(height: 12),
                  _buildHapticFeedbackCard(),
                ],
              ),
            ),
    );
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
  
  /// Materie-Profil Card
  Widget _buildMaterieProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.blue.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
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
                  final source = await AvatarUploadService.showImageSourceDialog(context);
                  if (source != null && mounted) {
                    final avatarService = AvatarUploadService();
                    final file = source == ImageSource.gallery
                        ? await avatarService.pickImageFromGallery()
                        : await avatarService.pickImageFromCamera();
                    
                    if (file != null && mounted) {
                      // TODO: Upload to server with user ID
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Avatar hochgeladen! 📸')),
                      );
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
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: const Center(
                        child: Text(
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
                          color: Colors.blue,
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
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
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
            Colors.purple.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.3),
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
                  final source = await AvatarUploadService.showImageSourceDialog(context);
                  if (source != null && mounted) {
                    final avatarService = AvatarUploadService();
                    final file = source == ImageSource.gallery
                        ? await avatarService.pickImageFromGallery()
                        : await avatarService.pickImageFromCamera();
                    
                    if (file != null && mounted) {
                      // TODO: Upload to server with user ID
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Avatar hochgeladen! 📸')),
                      );
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
                        border: Border.all(color: Colors.purple, width: 2),
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
                          color: Colors.purple,
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
                    foregroundColor: Colors.purple,
                    side: const BorderSide(color: Colors.purple),
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
  
  /// ☁️ Cloud-Sync Card
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
  
  /// 🏥 Backend Health Monitor Card
  Widget _buildHealthMonitorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withValues(alpha: 0.1),
            Colors.green.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
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
                  color: Colors.green.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.health_and_safety,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backend Health Monitor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Überwache alle Backend-Services',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Zeigt den Status aller 6 Backend-APIs:\n'
            '• Community API\n'
            '• Main API\n'
            '• Backend Recherche\n'
            '• Recherche Worker\n'
            '• Media API\n'
            '• Group Tools API',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/health');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.monitor_heart),
              label: const Text(
                'Health Monitor öffnen',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// ☁️ Sync to Cloud
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
            content: Text('❌ Sync-Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// ☁️ Restore from Cloud
  Future<void> _restoreFromCloud() async {
    HapticService.selectionClick();
    
    // Zeige Username-Dialog
    final usernameController = TextEditingController();
    
    if (!mounted) return;
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
      try {
        final syncService = CloudflareSyncService();
        
        // Restore Materie
        final materieProfile = await syncService.restoreMaterieProfile(
          usernameController.text,
        );
        if (materieProfile != null) {
          await _storageService.saveMaterieProfile(materieProfile);
        }
        
        // Restore Energie
        final energieProfile = await syncService.restoreEnergieProfile(
          usernameController.text,
        );
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
              content: Text('❌ Restore-Fehler: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  /// 📳 Haptic Feedback Card (NEU)
  Widget _buildHapticFeedbackCard() {
    return FutureBuilder<bool>(
      future: HapticFeedbackService().initialize().then((_) => HapticFeedbackService().isEnabled),
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
                      setState(() {}); // Rebuild to update UI
                    },
                    activeThumbColor: Colors.orange,
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

  @override
  void dispose() {
    // 🧹 PHASE B: Proper resource disposal
    super.dispose();
  }
}
