import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

/// Auth-State Stream – lauscht auf Supabase Auth-Änderungen.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

/// Aktueller User (null = nicht eingeloggt).
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider); // rebuild bei Auth-Wechsel
  return supabase.auth.currentUser;
});

/// Ist der User authentifiziert?
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// Aktuelle User-ID (null = nicht eingeloggt).
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.id;
});

/// Username aus user_metadata oder E-Mail.
final currentUsernameProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 'Gast';
  final meta = user.userMetadata;
  return meta?['username'] as String?
      ?? meta?['display_name'] as String?
      ?? user.email?.split('@').first
      ?? 'Anonym';
});

/// User-Profil aus user_profiles Tabelle.
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  try {
    return await supabase
        .from('user_profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
  } catch (_) {
    return null;
  }
});

/// Ist der User Admin? Liest aus user_profiles.is_admin.
final isAdminProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.maybeWhen(
    data: (data) => data?['is_admin'] == true,
    orElse: () => false,
  );
});
