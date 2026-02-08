import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/materie_profile.dart';
import '../models/energie_profile.dart';

/// Cloudflare Profile Service
/// Synchronisiert Profile-Daten mit Cloudflare D1 Backend
/// 
/// ✅ PUBLIC ENDPOINTS (Keine Auth-Headers erforderlich):
/// - POST /api/profile/materie - Profil erstellen/aktualisieren
/// - POST /api/profile/energie - Profil erstellen/aktualisieren
/// - GET /api/profile/:world/:username - Profil abrufen
/// 
/// 🔐 PROTECTED ENDPOINTS (Auth-Headers erforderlich):
/// - Siehe WorldAdminService für Admin-Endpoints
/// 
/// ⚠️  WICHTIG: Profile Sync ist absichtlich public, da:
/// - Jeder User muss sein erstes Profil erstellen können
/// - Root-Admin Passwort wird backend-seitig validiert
/// - Admin Endpoints sind separat geschützt (WorldAdminService)
/// 
/// 🆕 NEUE METHODEN (FIX 2):
/// - saveMaterieProfileAndGetUpdated() - Save + Get in einem (mit Backend-Rollen)
/// - saveEnergieProfileAndGetUpdated() - Save + Get in einem (mit Backend-Rollen)
class ProfileSyncService {
  // Cloudflare Worker URL (v2 - World-Based Multi-Profile System)
  static const String _baseUrl = 'https://weltenbibliothek-api-v2.brandy13062.workers.dev';
  
  // ════════════════════════════════════════════════════════════
  // MATERIE PROFILE
  // ════════════════════════════════════════════════════════════
  
  /// Save Materie Profile to Cloud
  /// 
  /// ✅ FAIL-SAFE: Optional password parameter for Root Admin validation
  /// - password: Optional, only required for username "Weltenbibliothek"
  /// - Rückwärtskompatibel: Bestehende Aufrufe funktionieren weiter
  Future<bool> saveMaterieProfile(
    MaterieProfile profile,
    {String? password}  // ✅ NEU: Optional Root-Admin Passwort
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/api/profile/materie');
      
      // ✅ Build request body (additiv)
      final body = <String, dynamic>{
        'username': profile.username,
        'name': profile.name,
        'avatar_url': profile.avatarUrl,
        'avatar_emoji': profile.avatarEmoji,
        'bio': profile.bio,
      };
      
      // ✅ NEU: Passwort nur hinzufügen wenn vorhanden
      if (password != null && password.isNotEmpty) {
        body['password'] = password;
        if (kDebugMode) {
          debugPrint('🔐 Root-Admin Passwort wird gesendet');
        }
      }
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        // ✅ NEU: Backend-Response mit Rollen-Informationen verarbeiten
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (kDebugMode) {
          debugPrint('✅ Materie-Profil gespeichert: ${profile.username}');
          if (data['userId'] != null) {
            debugPrint('   User ID: ${data['userId']}');
          }
          if (data['role'] != null) {
            debugPrint('   Rolle: ${data['role']}');
          }
          if (data['isAdmin'] == true) {
            debugPrint('   ⭐ Admin-Status erkannt');
          }
          if (data['isRootAdmin'] == true) {
            debugPrint('   👑 Root-Admin-Status erkannt');
          }
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Fehler beim Speichern: ${response.statusCode}');
          debugPrint('   Body: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Netzwerk-Fehler beim Speichern: $e');
      }
      return false;
    }
  }
  
  /// Save Materie Profile to Cloud und return aktualisiertes Profil mit Backend-Daten
  /// 
  /// ✅ NEUE METHODE (FIX 2): Kombiniert Save + Get für kompletten Flow
  /// Returns: Updated MaterieProfile mit userId und role vom Backend
  Future<MaterieProfile?> saveMaterieProfileAndGetUpdated(
    MaterieProfile profile,
    {String? password}
  ) async {
    // 1. Speichern
    final success = await saveMaterieProfile(profile, password: password);
    
    if (!success) {
      return null;
    }
    
    // 2. Aktualisiertes Profil vom Backend holen
    final updatedProfile = await getMaterieProfile(profile.username);
    
    return updatedProfile;
  }
  
  /// Get Materie Profile from Cloud
  Future<MaterieProfile?> getMaterieProfile(String username) async {
    try {
      final url = Uri.parse('$_baseUrl/api/profile/materie/$username');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['profile'] != null) {
          final profileData = data['profile'];
          
          return MaterieProfile(
            username: profileData['username'] as String,
            userId: profileData['user_id'] as String?,      // ✅ Backend userId
            role: profileData['role'] as String?,           // ✅ Backend role
            name: profileData['name'] as String?,
            avatarUrl: profileData['avatar_url'] as String?,
            avatarEmoji: profileData['avatar_emoji'] as String?,
            bio: profileData['bio'] as String?,
          );
        }
      } else if (response.statusCode == 404) {
        if (kDebugMode) {
          debugPrint('ℹ️ Profil nicht gefunden: $username');
        }
        return null;
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden: $e');
      }
      return null;
    }
  }
  
  /// Get All Materie Profiles
  Future<List<MaterieProfile>> getAllMaterieProfiles() async {
    try {
      final url = Uri.parse('$_baseUrl/api/profiles/materie');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['profiles'] != null) {
          final profilesList = data['profiles'] as List<dynamic>;
          
          return profilesList.map((p) => MaterieProfile(
            username: p['username'] as String,
            name: p['name'] as String?,
            avatarUrl: p['avatar_url'] as String?,
            avatarEmoji: p['avatar_emoji'] as String?,
            bio: p['bio'] as String?,
          )).toList();
        }
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden aller Profile: $e');
      }
      return [];
    }
  }
  
  // ════════════════════════════════════════════════════════════
  // ENERGIE PROFILE
  // ════════════════════════════════════════════════════════════
  
  /// Save Energie Profile to Cloud
  /// 
  /// ✅ FAIL-SAFE: Optional password parameter for Root Admin validation
  /// - password: Optional, only required for username "Weltenbibliothek"
  /// - Rückwärtskompatibel: Bestehende Aufrufe funktionieren weiter
  Future<bool> saveEnergieProfile(
    EnergieProfile profile,
    {String? password}  // ✅ NEU: Optional Root-Admin Passwort
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/api/profile/energie');
      
      // ✅ Build request body (additiv)
      final body = <String, dynamic>{
        'username': profile.username,
        'firstName': profile.firstName,
        'lastName': profile.lastName,
        'birthDate': profile.birthDate.toIso8601String(),
        'birthPlace': profile.birthPlace,
        'birthTime': profile.birthTime,
        'avatar_url': profile.avatarUrl,
        'avatar_emoji': profile.avatarEmoji,
        'bio': profile.bio,
      };
      
      // ✅ NEU: Passwort nur hinzufügen wenn vorhanden
      if (password != null && password.isNotEmpty) {
        body['password'] = password;
        if (kDebugMode) {
          debugPrint('🔐 Root-Admin Passwort wird gesendet');
        }
      }
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        // ✅ NEU: Backend-Response mit Rollen-Informationen verarbeiten
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (kDebugMode) {
          debugPrint('✅ Energie-Profil gespeichert: ${profile.username}');
          if (data['userId'] != null) {
            debugPrint('   User ID: ${data['userId']}');
          }
          if (data['role'] != null) {
            debugPrint('   Rolle: ${data['role']}');
          }
          if (data['isAdmin'] == true) {
            debugPrint('   ⭐ Admin-Status erkannt');
          }
          if (data['isRootAdmin'] == true) {
            debugPrint('   👑 Root-Admin-Status erkannt');
          }
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Fehler beim Speichern: ${response.statusCode}');
          debugPrint('   Body: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Netzwerk-Fehler beim Speichern: $e');
      }
      return false;
    }
  }
  
  /// Save Energie Profile to Cloud und return aktualisiertes Profil mit Backend-Daten
  /// 
  /// ✅ NEUE METHODE (FIX 2): Kombiniert Save + Get für kompletten Flow
  /// Returns: Updated EnergieProfile mit userId und role vom Backend
  Future<EnergieProfile?> saveEnergieProfileAndGetUpdated(
    EnergieProfile profile,
    {String? password}
  ) async {
    // 1. Speichern
    final success = await saveEnergieProfile(profile, password: password);
    
    if (!success) {
      return null;
    }
    
    // 2. Aktualisiertes Profil vom Backend holen
    final updatedProfile = await getEnergieProfile(profile.username);
    
    return updatedProfile;
  }
  
  /// Get Energie Profile from Cloud
  Future<EnergieProfile?> getEnergieProfile(String username) async {
    try {
      final url = Uri.parse('$_baseUrl/api/profile/energie/$username');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['profile'] != null) {
          final p = data['profile'];
          
          return EnergieProfile(
            username: p['username'] as String,
            userId: p['user_id'] as String?,        // ✅ Backend userId
            role: p['role'] as String?,             // ✅ Backend role
            firstName: p['first_name'] as String,
            lastName: p['last_name'] as String,
            birthDate: DateTime.parse(p['birth_date'] as String),
            birthPlace: p['birth_place'] as String,
            birthTime: p['birth_time'] as String?,
            avatarUrl: p['avatar_url'] as String?,
            avatarEmoji: p['avatar_emoji'] as String?,
            bio: p['bio'] as String?,
          );
        }
      } else if (response.statusCode == 404) {
        if (kDebugMode) {
          debugPrint('ℹ️ Profil nicht gefunden: $username');
        }
        return null;
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden: $e');
      }
      return null;
    }
  }
  
  /// Get All Energie Profiles
  Future<List<EnergieProfile>> getAllEnergieProfiles() async {
    try {
      final url = Uri.parse('$_baseUrl/api/profiles/energie');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['profiles'] != null) {
          final profilesList = data['profiles'] as List<dynamic>;
          
          return profilesList.map((p) => EnergieProfile(
            username: p['username'] as String,
            firstName: p['first_name'] as String,
            lastName: p['last_name'] as String,
            birthDate: DateTime.parse(p['birth_date'] as String),
            birthPlace: p['birth_place'] as String,
            birthTime: p['birth_time'] as String?,
            avatarUrl: p['avatar_url'] as String?,
            avatarEmoji: p['avatar_emoji'] as String?,
            bio: p['bio'] as String?,
          )).toList();
        }
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden aller Profile: $e');
      }
      return [];
    }
  }
}
