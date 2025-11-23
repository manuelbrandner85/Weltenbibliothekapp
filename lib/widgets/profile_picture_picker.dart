import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import 'user_avatar.dart';

/// ═══════════════════════════════════════════════════════════════
/// PROFILE PICTURE PICKER - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// Widget für Profilbild-Auswahl und Upload
/// Features:
/// - Zeigt aktuelles Profilbild oder Fallback
/// - Tap → Auswahl: Kamera oder Galerie
/// - Upload mit Progress-Indicator
/// - Error-Handling
/// ═══════════════════════════════════════════════════════════════

class ProfilePicturePicker extends StatefulWidget {
  final User user;
  final Future<void> Function(File imageFile) onImageSelected;
  final bool isEditable;

  const ProfilePicturePicker({
    super.key,
    required this.user,
    required this.onImageSelected,
    this.isEditable = true,
  });

  @override
  State<ProfilePicturePicker> createState() => _ProfilePicturePickerState();
}

class _ProfilePicturePickerState extends State<ProfilePicturePicker> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85, // Komprimierung
      );

      if (pickedFile == null) return; // User abgebrochen

      if (!mounted) return;

      setState(() {
        _isUploading = true;
      });

      // Web: Kann File nicht direkt verwenden
      if (kIsWeb) {
        // Für Web müssten wir Bytes verwenden, aber da UserService
        // File erwartet, müsste das angepasst werden.
        // Vorerst: Web-Upload nicht unterstützt
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profilbild-Upload auf Web noch nicht unterstützt'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() {
            _isUploading = false;
          });
        }
        return;
      }

      // Mobile: Verwende File
      final File imageFile = File(pickedFile.path);

      // Callback aufrufen (Upload)
      await widget.onImageSelected(imageFile);

      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profilbild erfolgreich aktualisiert'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler beim Upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Titel
                const Text(
                  'Profilbild auswählen',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Kamera-Option
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: Color(0xFF8B5CF6),
                  ),
                  title: const Text('Kamera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),

                // Galerie-Option
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: Color(0xFF8B5CF6),
                  ),
                  title: const Text('Galerie'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),

                // Abbrechen
                ListTile(
                  leading: const Icon(Icons.close, color: Colors.grey),
                  title: const Text('Abbrechen'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isEditable && !_isUploading ? _showImageSourcePicker : null,
      child: Stack(
        children: [
          // Avatar
          UserAvatar.fromUser(
            widget.user,
            size: AvatarSize.xlarge,
            showOnlineStatus: false,
            showRoleBadge: false,
          ),

          // Upload-Indicator
          if (_isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),

          // Edit-Icon (nur wenn editierbar)
          if (widget.isEditable && !_isUploading)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
