/// 🔊 AUDIO SETTINGS SERVICE
/// Manages audio settings (stub for compatibility)
library;

class AudioSettingsService {
  static final AudioSettingsService _instance = AudioSettingsService._internal();
  factory AudioSettingsService() => _instance;
  AudioSettingsService._internal();

  bool pushToTalk = false;
}
