import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../models/materie_profile.dart';
import '../models/energie_profile.dart';
import '../services/profile_sync_service.dart'; // 🔥 BACKEND SYNC

/// Profil-Onboarding-Screen - Zeigt beim ersten App-Start ODER zum Bearbeiten
class ProfileOnboardingScreen extends StatefulWidget {
  final String worldType; // 'materie' oder 'energie'
  final MaterieProfile? existingMaterieProfile; // Für Edit-Modus
  final EnergieProfile? existingEnergieProfile; // Für Edit-Modus
  final VoidCallback? onProfileCreated; // 🆕 Callback nach Profil-Erstellung
  
  const ProfileOnboardingScreen({
    super.key,
    required this.worldType,
    this.existingMaterieProfile,
    this.existingEnergieProfile,
    this.onProfileCreated,
  });

  @override
  State<ProfileOnboardingScreen> createState() => _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState extends State<ProfileOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = StorageService();
  
  // Materie-Felder
  final _materieUsernameController = TextEditingController();
  final _materieNameController = TextEditingController();
  
  // Energie-Felder
  final _energieUsernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _birthTimeController = TextEditingController();
  DateTime? _selectedBirthDate;
  
  bool _isLoading = false;
  
  bool get _isEditMode => _isMaterie 
      ? widget.existingMaterieProfile != null
      : widget.existingEnergieProfile != null;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }
  
  /// Vorhandene Profil-Daten laden (Edit-Modus)
  void _loadExistingProfile() {
    if (_isMaterie && widget.existingMaterieProfile != null) {
      _materieUsernameController.text = widget.existingMaterieProfile!.username;
      _materieNameController.text = widget.existingMaterieProfile!.name ?? '';
    } else if (!_isMaterie && widget.existingEnergieProfile != null) {
      _energieUsernameController.text = widget.existingEnergieProfile!.username;
      _firstNameController.text = widget.existingEnergieProfile!.firstName;
      _lastNameController.text = widget.existingEnergieProfile!.lastName;
      _birthPlaceController.text = widget.existingEnergieProfile!.birthPlace;
      _selectedBirthDate = widget.existingEnergieProfile!.birthDate;
      
      // Geburtszeit optional (birthTime ist String im Format HH:mm)
      if (widget.existingEnergieProfile!.birthTime != null) {
        _birthTimeController.text = widget.existingEnergieProfile!.birthTime!;
      }
    }
  }

  @override
  void dispose() {
    _materieUsernameController.dispose();
    _materieNameController.dispose();
    _energieUsernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthPlaceController.dispose();
    _birthTimeController.dispose();
    super.dispose();
  }

  bool get _isMaterie => widget.worldType == 'materie';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _isMaterie
                ? [
                    const Color(0xFF0D47A1).withValues(alpha: 0.3),
                    Colors.black,
                  ]
                : [
                    const Color(0xFF4A148C).withValues(alpha: 0.3),
                    Colors.black,
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildInfoCard(),
                  const SizedBox(height: 30),
                  _isMaterie ? _buildMaterieForm() : _buildEnergieForm(),
                  const SizedBox(height: 30),
                  _buildSubmitButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          _isMaterie ? '🔵' : '🟣',
          style: const TextStyle(fontSize: 80),
        ),
        const SizedBox(height: 16),
        Text(
          _isMaterie ? 'MATERIE-PROFIL' : 'ENERGIE-PROFIL',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _isEditMode
              ? (_isMaterie 
                  ? 'Bearbeite dein Recherche-Profil' 
                  : 'Bearbeite dein Spirituelles Profil')
              : (_isMaterie
                  ? 'Erstelle dein Recherche-Profil'
                  : 'Erstelle dein Spirituelles Profil'),
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isMaterie
              ? [
                  Colors.blue.withValues(alpha: 0.15),
                  Colors.blue.withValues(alpha: 0.05),
                ]
              : [
                  Colors.purple.withValues(alpha: 0.15),
                  Colors.purple.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isMaterie
              ? Colors.blue.withValues(alpha: 0.3)
              : Colors.purple.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: _isMaterie ? Colors.blue : Colors.purple,
          ),
          const SizedBox(height: 16),
          Text(
            _isMaterie
                ? 'Dein Profil wird für personalisierte Recherche-Funktionen benötigt.'
                : 'Deine Geburtsdaten werden für präzise spirituelle Berechnungen (Numerologie, Archetypen, etc.) benötigt.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '🔒 Alle Daten bleiben lokal auf deinem Gerät gespeichert.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMaterieForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Benutzername *', 'Pflichtfeld'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _materieUsernameController,
          hint: 'z.B. Forscher_Max',
          icon: Icons.person,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Bitte Benutzernamen eingeben';
            }
            if (value.trim().length < 3) {
              return 'Mindestens 3 Zeichen erforderlich';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _buildFieldLabel('Name / Spitzname', 'Optional'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _materieNameController,
          hint: 'z.B. Max Mustermann',
          icon: Icons.badge,
        ),
      ],
    );
  }

  Widget _buildEnergieForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Benutzername *', 'Pflichtfeld'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _energieUsernameController,
          hint: 'z.B. Licht_Arbeiter',
          icon: Icons.person,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Bitte Benutzernamen eingeben';
            }
            if (value.trim().length < 3) {
              return 'Mindestens 3 Zeichen erforderlich';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _buildFieldLabel('Vorname *', 'Pflichtfeld'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _firstNameController,
          hint: 'Dein Vorname',
          icon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Bitte Vornamen eingeben';
            }
            if (value.trim().length < 2) {
              return 'Mindestens 2 Zeichen erforderlich';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _buildFieldLabel('Nachname *', 'Pflichtfeld'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _lastNameController,
          hint: 'Dein Nachname',
          icon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Bitte Nachnamen eingeben';
            }
            if (value.trim().length < 2) {
              return 'Mindestens 2 Zeichen erforderlich';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _buildFieldLabel('Geburtsdatum *', 'Pflichtfeld'),
        const SizedBox(height: 8),
        _buildDatePicker(),
        const SizedBox(height: 20),
        _buildFieldLabel('Geburtsort *', 'Pflichtfeld'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _birthPlaceController,
          hint: 'z.B. Wien, Österreich',
          icon: Icons.location_on,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Bitte Geburtsort eingeben';
            }
            if (value.trim().length < 2) {
              return 'Mindestens 2 Zeichen erforderlich';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _buildFieldLabel('Geburtszeit', 'Optional - für präzisere Berechnungen'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _birthTimeController,
          hint: 'z.B. 14:30',
          icon: Icons.access_time,
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label, String hint) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          hint,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.5),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
        ),
        prefixIcon: Icon(
          icon,
          color: _isMaterie ? Colors.blue : Colors.purple,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _isMaterie ? Colors.blue : Colors.purple,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        // Berechne erlaubte Datumsgrenzen
        final now = DateTime.now();
        final minDate = DateTime(now.year - 120, now.month, now.day); // Max 120 Jahre alt
        final maxDate = DateTime(now.year - 13, now.month, now.day);  // Min 13 Jahre alt
        
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedBirthDate ?? DateTime(now.year - 30, now.month, now.day),
          firstDate: minDate,
          lastDate: maxDate,
          helpText: 'Geburtsdatum auswählen',
          errorFormatText: 'Ungültiges Datum',
          errorInvalidText: 'Datum außerhalb des gültigen Bereichs',
          fieldLabelText: 'Geburtsdatum',
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: ColorScheme.dark(
                  primary: _isMaterie ? Colors.blue : Colors.purple,
                  onPrimary: Colors.white,
                  surface: const Color(0xFF2A2A2A),
                  onSurface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        
        if (date != null) {
          // Zusätzliche Validierung (doppelte Sicherheit)
          final age = now.year - date.year - 
                      ((now.month < date.month || 
                        (now.month == date.month && now.day < date.day)) ? 1 : 0);
          
          if (age < 13) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ Mindestalter: 13 Jahre'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
          
          if (age > 120) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ Maximales Alter: 120 Jahre'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
          
          setState(() => _selectedBirthDate = date);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedBirthDate != null
                ? (_isMaterie ? Colors.blue : Colors.purple)
                : Colors.white.withValues(alpha: 0.2),
            width: _selectedBirthDate != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: _isMaterie ? Colors.blue : Colors.purple,
            ),
            const SizedBox(width: 12),
            Text(
              _selectedBirthDate != null
                  ? '${_selectedBirthDate!.day.toString().padLeft(2, '0')}.${_selectedBirthDate!.month.toString().padLeft(2, '0')}.${_selectedBirthDate!.year}'
                  : 'Geburtsdatum auswählen',
              style: TextStyle(
                color: _selectedBirthDate != null
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.4),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isMaterie ? Colors.blue : Colors.purple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              'Profil erstellen und Welt betreten',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Energie: Geburtsdatum prüfen
    if (!_isMaterie && _selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte Geburtsdatum auswählen'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Energie: Alters-Validierung (13-120 Jahre)
    if (!_isMaterie && _selectedBirthDate != null) {
      final now = DateTime.now();
      final age = now.year - _selectedBirthDate!.year - 
                  ((now.month < _selectedBirthDate!.month || 
                    (now.month == _selectedBirthDate!.month && now.day < _selectedBirthDate!.day)) ? 1 : 0);
      
      if (age < 13) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Mindestalter: 13 Jahre'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      if (age > 120) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Maximales Alter: 120 Jahre'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      if (_isMaterie) {
        // Materie-Profil speichern
        final profile = MaterieProfile(
          username: _materieUsernameController.text.trim(),
          name: _materieNameController.text.trim().isEmpty
              ? null
              : _materieNameController.text.trim(),
        );
        
        // 🔥 FIX: Backend-Sync durchführen um userId & role zu erhalten
        final syncService = ProfileSyncService();
        final syncedProfile = await syncService.saveMaterieProfileAndGetUpdated(profile);
        
        if (syncedProfile != null) {
          await _storage.saveMaterieProfile(syncedProfile);
          if (kDebugMode) {
            debugPrint('✅ Materie-Profil gespeichert mit Backend-Sync: ${syncedProfile.username}');
            debugPrint('   User ID: ${syncedProfile.userId}');
            debugPrint('   Role: ${syncedProfile.role}');
          }
        } else {
          // Fallback: Lokales Profil speichern
          await _storage.saveMaterieProfile(profile);
          if (kDebugMode) {
            debugPrint('⚠️ Materie-Profil lokal gespeichert (Backend-Sync fehlgeschlagen)');
          }
        }
      } else {
        // Energie-Profil speichern
        final profile = EnergieProfile(
          username: _energieUsernameController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          birthDate: _selectedBirthDate!,
          birthPlace: _birthPlaceController.text.trim(),
          birthTime: _birthTimeController.text.trim().isEmpty
              ? null
              : _birthTimeController.text.trim(),
        );
        
        // 🔥 FIX: Backend-Sync durchführen um userId & role zu erhalten
        final syncService = ProfileSyncService();
        final syncedProfile = await syncService.saveEnergieProfileAndGetUpdated(profile);
        
        if (syncedProfile != null) {
          await _storage.saveEnergieProfile(syncedProfile);
          if (kDebugMode) {
            debugPrint('✅ Energie-Profil gespeichert mit Backend-Sync: ${syncedProfile.fullName}');
            debugPrint('   User ID: ${syncedProfile.userId}');
            debugPrint('   Role: ${syncedProfile.role}');
          }
        } else {
          // Fallback: Lokales Profil speichern
          await _storage.saveEnergieProfile(profile);
          if (kDebugMode) {
            debugPrint('⚠️ Energie-Profil lokal gespeichert (Backend-Sync fehlgeschlagen)');
          }
        }
      }

      if (mounted) {
        // Callback aufrufen BEVOR wir poppen
        widget.onProfileCreated?.call();
        
        // Zurück zur Welt und neu laden
        Navigator.pop(context, true); // true = Profil wurde erstellt
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Speichern: $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
