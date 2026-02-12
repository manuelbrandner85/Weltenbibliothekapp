import 'package:hive_flutter/hive_flutter.dart';

/// Script zum Erstellen eines Test-Admin-Profils
/// 
/// VERWENDUNG:
/// 1. Dieses Script in main.dart einbinden
/// 2. App starten
/// 3. Profil wird automatisch erstellt
void main() async {
  // Hive initialisieren (correct API)
  await Hive.initFlutter();
  
  // Materie Box öffnen
  final materieBox = await Hive.openBox('materie_profile');
  
  // Test-Admin Profil erstellen
  final testProfile = {
    'username': 'testadmin',
    'role': 'root_admin',
    'avatar_emoji': '👑',
    'bio': 'Test Root-Admin für Phase 2 Testing',
    'created_at': DateTime.now().toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
  };
  
  await materieBox.put('profile', testProfile);
  
  print('✅ Test-Admin Profil erstellt:');
  print('   Username: testadmin');
  print('   Role: root_admin');
  print('   Avatar: 👑');
  
  // Energie Box öffnen
  final energieBox = await Hive.openBox('energie_profile');
  await energieBox.put('profile', testProfile);
  
  print('✅ Profil auch für Energie erstellt');
  
  // Verifizierung
  final savedProfile = materieBox.get('profile');
  print('\n🔍 Gespeichertes Profil:');
  print(savedProfile);
}
