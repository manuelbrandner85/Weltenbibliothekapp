// Data model for the immersive mentor avatar session.
// Tracks avatar animation state and session preferences.

import '../services/mentor_service.dart';

/// Visual state of the 3D avatar — drives CustomPainter animation.
enum MentorAvatarState {
  idle, // gentle pulse: mentor is ready
  listening, // expanding rings: mic is active
  thinking, // rotating particles: AI is generating
  speaking, // wave bands: TTS is reading response
}

/// Session-level data for the mentor avatar screen.
/// Not persisted — lives only for the duration of one screen session.
class MentorSessionModel {
  final String world;
  final MentorPersonality personality;
  MentorAvatarState avatarState;
  bool isTtsEnabled;
  bool isMicActive;

  MentorSessionModel({
    required this.world,
    required this.personality,
    this.avatarState = MentorAvatarState.idle,
    this.isTtsEnabled = true,
    this.isMicActive = false,
  });

  /// World accent color as a packed ARGB integer (no Color import needed here).
  /// Consumers convert with Color(session.accentArgb).
  int get accentArgb {
    switch (world) {
      case 'vorhang':
        return 0xFFC9A84C;
      case 'ursprung':
        return 0xFF00D4AA;
      case 'energie':
        return 0xFFA855F7;
      case 'materie':
      default:
        return 0xFF3B82F6;
    }
  }

  /// Display name shown below the avatar.
  String get mentorDisplayName {
    switch (personality) {
      case MentorPersonality.stratege:
        return 'Der Stratege';
      case MentorPersonality.alchemist:
        return 'Der Alchemist';
      case MentorPersonality.heiler:
        return 'Der Heiler';
      case MentorPersonality.forscher:
        return 'Der Forscher';
    }
  }

  /// Short label shown as avatar state caption.
  String get stateLabel {
    switch (avatarState) {
      case MentorAvatarState.idle:
        return 'Bereit';
      case MentorAvatarState.listening:
        return 'Hoert zu ...';
      case MentorAvatarState.thinking:
        return 'Denkt nach ...';
      case MentorAvatarState.speaking:
        return 'Spricht ...';
    }
  }
}
