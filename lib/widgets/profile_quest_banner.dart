// Profile-Quest-Banner — sanfter Onboarding-Prompt.
//
// Wird im Portal angezeigt, wenn der User noch kein Profil angelegt hat
// (weder Materie- noch Energie-Profil im StorageService). Tap → öffnet
// ProfileOnboardingScreen. Wenn der User danach ein Profil hat,
// verschwindet der Banner automatisch.
//
// Vorher: Web-User kam ohne Profil ins Portal und stolperte erst beim
// Eintritt in eine Funktion über ProfileRequiredWidget. Jetzt: aktiver
// Hinweis schon auf der Home-Screen.

import 'package:flutter/material.dart';

import '../screens/profile_onboarding_screen.dart';
import '../services/storage_service.dart';

class ProfileQuestBanner extends StatefulWidget {
  const ProfileQuestBanner({super.key});

  @override
  State<ProfileQuestBanner> createState() => _ProfileQuestBannerState();
}

class _ProfileQuestBannerState extends State<ProfileQuestBanner> {
  bool _hasProfile = true; // optimistisch — verbergen bis wir wissen es
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  void _check() {
    final s = StorageService();
    final m = s.getMaterieProfile();
    final e = s.getEnergieProfile();
    final has = (m?.username.isNotEmpty ?? false) || (e?.username.isNotEmpty ?? false);
    if (mounted) setState(() => _hasProfile = has);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasProfile || _dismissed) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                // Default 'materie' — User kann das Profil danach für jede
                // Welt mitnutzen, weil es nur ein unified Profile pro User
                // gibt (siehe Auth-Refactor in CLAUDE.md TODOs).
                builder: (_) => const ProfileOnboardingScreen(worldType: 'materie'),
                fullscreenDialog: true,
              ),
            );
            _check();
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFC9A84C).withValues(alpha: 0.18),
                  const Color(0xFFC9A84C).withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(
                color: const Color(0xFFC9A84C).withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFC9A84C).withValues(alpha: 0.18),
                    border: Border.all(
                      color: const Color(0xFFC9A84C).withValues(alpha: 0.6),
                    ),
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded,
                      color: Color(0xFFC9A84C), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lege dein Profil an',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Damit du Chats, Streams und Module nutzen kannst.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFC9A84C)),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white38, size: 16),
                  onPressed: () => setState(() => _dismissed = true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
