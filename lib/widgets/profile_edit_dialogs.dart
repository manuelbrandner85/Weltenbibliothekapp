import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/materie_profile.dart';
import '../models/energie_profile.dart';
import '../services/storage_service.dart';
import '../services/profile_sync_service.dart';
import '../theme/premium_text_styles.dart';

/// Profil-Bearbeitungs-Dialog für MATERIE-Welt
class MaterieProfileEditDialog extends StatefulWidget {
  final MaterieProfile profile;
  final Function(MaterieProfile) onSave;

  const MaterieProfileEditDialog({
    super.key,
    required this.profile,
    required this.onSave,
  });

  @override
  State<MaterieProfileEditDialog> createState() => _MaterieProfileEditDialogState();
}

class _MaterieProfileEditDialogState extends State<MaterieProfileEditDialog> {
  late TextEditingController _usernameController;
  late TextEditingController _nameController;
  late TextEditingController _passwordController;
  final _formKey = GlobalKey<FormState>();
  bool _showPasswordField = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.profile.username);
    _nameController = TextEditingController(text: widget.profile.name ?? '');
    _passwordController = TextEditingController();
    
    // Check if username is "Weltenbibliothek" on init
    _showPasswordField = widget.profile.username == 'Weltenbibliothek';
    
    // Listen to username changes
    _usernameController.addListener(() {
      setState(() {
        _showPasswordField = _usernameController.text.trim() == 'Weltenbibliothek';
      });
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      try {
        final username = _usernameController.text.trim();
        final password = _passwordController.text.trim();
        
        // ✅ FIX 1: Verwende neue Methode (Save + Get in einem)
        final syncService = ProfileSyncService();
        final updatedProfile = await syncService.saveMaterieProfileAndGetUpdated(
          MaterieProfile(
            username: username, 
            name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
          ),
          password: password.isEmpty ? null : password,
        );
        
        if (updatedProfile != null) {
          // 🐛 DEBUG: Zeige was gespeichert wird
          if (kDebugMode) {
            debugPrint('🔍 PROFIL SPEICHERN:');
            debugPrint('   Username: ${updatedProfile.username}');
            debugPrint('   User ID: ${updatedProfile.userId}');
            debugPrint('   Role: ${updatedProfile.role}');
            debugPrint('   Is Admin: ${updatedProfile.isAdmin()}');
            debugPrint('   Is Root Admin: ${updatedProfile.isRootAdmin()}');
          }
          
          // In Storage speichern (mit userId + role vom Backend)
          await StorageService().saveMaterieProfile(updatedProfile);
          
          if (mounted) {
            widget.onSave(updatedProfile);
            Navigator.pop(context);
            
            // ✅ FIX 1: Rollenbasiertes Feedback
            final isRootAdmin = updatedProfile.isRootAdmin();
            final isAdmin = updatedProfile.isAdmin();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isRootAdmin 
                    ? '👑 Root-Admin aktiviert!' 
                    : isAdmin 
                      ? '⭐ Admin aktiviert!' 
                      : '✅ Profil gespeichert!',
                ),
                backgroundColor: isRootAdmin || isAdmin 
                  ? Colors.orange 
                  : Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Fehler beim Speichern'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Fehler: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D47A1),
              Color(0xFF1A1A1A),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF2196F3).withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2196F3).withValues(alpha: 0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1976D2), Color(0xFF2196F3)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Profil bearbeiten',
                      style: PremiumTextStyles.materieCardTitle.copyWith(
                        fontSize: 20,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Username Input
              Text(
                'BENUTZERNAME (Pflicht)',
                style: PremiumTextStyles.materieBadge.copyWith(
                  fontSize: 12,
                  color: const Color(0xFF90CAF9),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  hintText: 'z.B. Forscher_Max',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  prefixIcon: const Icon(
                    Icons.alternate_email,
                    color: Color(0xFF2196F3),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2196F3),
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte gib einen Benutzernamen ein';
                  }
                  if (value.trim().length < 3) {
                    return 'Mindestens 3 Zeichen erforderlich';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Name Input (Optional)
              Text(
                'ANZEIGENAME (Optional)',
                style: PremiumTextStyles.materieBadge.copyWith(
                  fontSize: 12,
                  color: const Color(0xFF90CAF9),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  hintText: 'z.B. Max Mustermann',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF2196F3),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2196F3),
                      width: 2,
                    ),
                  ),
                ),
              ),
              
              // 👑 ROOT-ADMIN PASSWORT (nur für "Weltenbibliothek")
              if (_showPasswordField) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6F00).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF6F00).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.admin_panel_settings, color: Color(0xFFFF6F00), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'ROOT-ADMIN AKTIVIERUNG',
                            style: PremiumTextStyles.materieBadge.copyWith(
                              fontSize: 12,
                              color: const Color(0xFFFF6F00),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gib das Root-Admin-Passwort ein, um alle Admin-Rechte zu erhalten.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF1E1E1E),
                          hintText: 'Root-Admin Passwort',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: Color(0xFFFF6F00),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: const Color(0xFFFF6F00).withValues(alpha: 0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: const Color(0xFFFF6F00).withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF6F00),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Abbrechen',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Speichern',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Profil-Bearbeitungs-Dialog für ENERGIE-Welt
class EnergieProfileEditDialog extends StatefulWidget {
  final EnergieProfile profile;
  final Function(EnergieProfile) onSave;

  const EnergieProfileEditDialog({
    super.key,
    required this.profile,
    required this.onSave,
  });

  @override
  State<EnergieProfileEditDialog> createState() => _EnergieProfileEditDialogState();
}

class _EnergieProfileEditDialogState extends State<EnergieProfileEditDialog> {
  late TextEditingController _usernameController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _birthPlaceController;
  late TextEditingController _birthTimeController;
  late TextEditingController _passwordController;
  DateTime? _selectedDate;
  final _formKey = GlobalKey<FormState>();
  bool _showPasswordField = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.profile.username);
    _firstNameController = TextEditingController(text: widget.profile.firstName);
    _lastNameController = TextEditingController(text: widget.profile.lastName);
    _birthPlaceController = TextEditingController(text: widget.profile.birthPlace);
    _birthTimeController = TextEditingController(text: widget.profile.birthTime);
    _passwordController = TextEditingController();
    _selectedDate = widget.profile.birthDate;
    
    _showPasswordField = widget.profile.username == 'Weltenbibliothek';
    
    _usernameController.addListener(() {
      setState(() {
        _showPasswordField = _usernameController.text.trim() == 'Weltenbibliothek';
      });
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthPlaceController.dispose();
    _birthTimeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('de', 'DE'), // Deutsches Datum
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF9C27B0),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      setState(() => _isSaving = true);
      
      try {
        final username = _usernameController.text.trim();
        final password = _passwordController.text.trim();
        
        // ✅ FIX 1: Verwende neue Methode (Save + Get in einem)
        final syncService = ProfileSyncService();
        final updatedProfile = await syncService.saveEnergieProfileAndGetUpdated(
          EnergieProfile(
            username: username,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            birthDate: _selectedDate!,
            birthPlace: _birthPlaceController.text.trim(),
            birthTime: _birthTimeController.text.trim(),
          ),
          password: password.isEmpty ? null : password,
        );
        
        if (updatedProfile != null) {
          // In Storage speichern (mit userId + role vom Backend)
          await StorageService().saveEnergieProfile(updatedProfile);
          
          if (mounted) {
            widget.onSave(updatedProfile);
            Navigator.pop(context);
            
            // ✅ FIX 1: Rollenbasiertes Feedback
            final isRootAdmin = updatedProfile.isRootAdmin();
            final isAdmin = updatedProfile.isAdmin();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isRootAdmin 
                    ? '👑 Root-Admin aktiviert!' 
                    : isAdmin 
                      ? '⭐ Admin aktiviert!' 
                      : '✅ Profil gespeichert!',
                ),
                backgroundColor: isRootAdmin || isAdmin 
                  ? Colors.orange 
                  : Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Fehler beim Speichern'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Fehler: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4A148C),
              Color(0xFF1A1A1A),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF9C27B0).withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF9C27B0), Color(0xFFFFD700)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Spirituelles Profil',
                        style: PremiumTextStyles.energieCardTitle.copyWith(
                          fontSize: 20,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Username (PFLICHT)
                _buildInputField(
                  label: 'BENUTZERNAME (Pflicht)',
                  controller: _usernameController,
                  icon: Icons.alternate_email,
                  hint: 'z.B. Spirit_Seeker',
                ),
                const SizedBox(height: 16),

                // Vorname
                _buildInputField(
                  label: 'VORNAME',
                  controller: _firstNameController,
                  icon: Icons.person_outline,
                  hint: 'Dein Vorname',
                ),
                const SizedBox(height: 16),

                // Nachname
                _buildInputField(
                  label: 'NACHNAME',
                  controller: _lastNameController,
                  icon: Icons.person_outline,
                  hint: 'Dein Nachname',
                ),
                const SizedBox(height: 16),

                // Geburtsdatum
                Text(
                  'GEBURTSDATUM',
                  style: PremiumTextStyles.energieBadge.copyWith(
                    fontSize: 12,
                    color: const Color(0xFFCE93D8),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF9C27B0),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDate != null
                              ? DateFormat('dd.MM.yyyy', 'de_DE').format(_selectedDate!)
                              : 'Datum wählen',
                          style: TextStyle(
                            color: _selectedDate != null
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Geburtsort
                _buildInputField(
                  label: 'GEBURTSORT',
                  controller: _birthPlaceController,
                  icon: Icons.location_on_outlined,
                  hint: 'Stadt/Ort',
                ),
                const SizedBox(height: 16),

                // Geburtszeit
                _buildInputField(
                  label: 'GEBURTSZEIT (optional)',
                  controller: _birthTimeController,
                  icon: Icons.access_time,
                  hint: 'z.B. 14:30',
                  required: false,
                ),
                const SizedBox(height: 32),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Abbrechen',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C27B0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Speichern',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: PremiumTextStyles.energieBadge.copyWith(
            fontSize: 12,
            color: const Color(0xFFCE93D8),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF9C27B0),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF9C27B0),
                width: 2,
              ),
            ),
          ),
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Dieses Feld ist erforderlich';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }
}
