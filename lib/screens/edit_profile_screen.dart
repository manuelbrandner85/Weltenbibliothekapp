import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/profile_picture_picker.dart';

/// ═══════════════════════════════════════════════════════════════
/// EDIT PROFILE SCREEN - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// Bearbeiten des eigenen Profils
/// Features:
/// - Profilbild ändern (Kamera/Galerie)
/// - Display-Name bearbeiten
/// - Bio bearbeiten
/// - Validierung & Error-Handling
/// - Speichern mit Feedback
/// ═══════════════════════════════════════════════════════════════

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  void _loadCurrentProfile() {
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.currentUser;

    if (currentUser != null) {
      _displayNameController.text = currentUser.displayName ?? '';
      _bioController.text = currentUser.bio ?? '';
    }

    // Track changes
    _displayNameController.addListener(_markAsChanged);
    _bioController.addListener(_markAsChanged);
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleAvatarUpload(File imageFile) async {
    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.uploadAvatar(imageFile);
      setState(() {
        _hasChanges = true;
      });
    } catch (e) {
      // Error wird bereits in ProfilePicturePicker angezeigt
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = context.read<UserProvider>();
      final currentUser = userProvider.currentUser;

      // Nur speichern wenn Änderungen vorliegen
      final displayName = _displayNameController.text.trim();
      final bio = _bioController.text.trim();

      final displayNameChanged =
          displayName != (currentUser?.displayName ?? '');
      final bioChanged = bio != (currentUser?.bio ?? '');

      if (!displayNameChanged && !bioChanged && !_hasChanges) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Keine Änderungen zum Speichern'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Profil aktualisieren
      await userProvider.updateProfile(
        displayName: displayNameChanged ? displayName : null,
        bio: bioChanged ? bio : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profil erfolgreich aktualisiert'),
            backgroundColor: Colors.green,
          ),
        );

        // Zurück zur vorherigen Seite mit "updated=true"
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fehler: $e'), backgroundColor: Colors.red),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Änderungen verwerfen?'),
        content: const Text(
          'Du hast ungespeicherte Änderungen. Möchtest du sie verwerfen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Verwerfen'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final currentUser = userProvider.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text(
            'Nicht angemeldet',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              if (_hasChanges) {
                final shouldPop = await _onWillPop();
                if (shouldPop && mounted) {
                  Navigator.pop(context);
                }
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: const Text(
            'Profil bearbeiten',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            if (_hasChanges && !_isLoading)
              TextButton(
                onPressed: _saveProfile,
                child: const Text(
                  'Speichern',
                  style: TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),

                  // Profilbild-Picker
                  ProfilePicturePicker(
                    user: currentUser,
                    onImageSelected: _handleAvatarUpload,
                  ),

                  const SizedBox(height: 32),

                  // Username (nicht editierbar)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_circle,
                          color: Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Benutzername',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '@${currentUser.username}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.lock, color: Colors.grey, size: 20),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Display-Name
                  TextFormField(
                    controller: _displayNameController,
                    enabled: !_isLoading,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Display-Name',
                      labelStyle: const TextStyle(color: Colors.white60),
                      hintText: 'Dein öffentlicher Name',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      prefixIcon: const Icon(
                        Icons.person,
                        color: Color(0xFF8B5CF6),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF8B5CF6),
                          width: 2,
                        ),
                      ),
                      helperText:
                          'Optional: Ein Name, der anderen Usern angezeigt wird',
                      helperStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                    maxLength: 50,
                    validator: (value) {
                      if (value != null &&
                          value.trim().isNotEmpty &&
                          value.trim().length < 2) {
                        return 'Mindestens 2 Zeichen';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Bio
                  TextFormField(
                    controller: _bioController,
                    enabled: !_isLoading,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Bio',
                      labelStyle: const TextStyle(color: Colors.white60),
                      hintText: 'Erzähle anderen etwas über dich...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 64),
                        child: Icon(Icons.edit_note, color: Color(0xFF8B5CF6)),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF8B5CF6),
                          width: 2,
                        ),
                      ),
                      helperText: 'Optional: Eine kurze Beschreibung',
                      helperStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                    maxLength: 200,
                    validator: (value) {
                      if (value != null &&
                          value.trim().isNotEmpty &&
                          value.trim().length < 10) {
                        return 'Mindestens 10 Zeichen oder leer lassen';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // Speichern-Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Änderungen speichern',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
