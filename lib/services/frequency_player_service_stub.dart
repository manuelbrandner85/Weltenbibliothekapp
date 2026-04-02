/// Stub implementation of FrequencyPlayerServiceAndroid for Web platform
/// This file is used when compiling for Web to avoid importing Android-specific code
class FrequencyPlayerServiceAndroid {
  static Future<void> play(double frequency) async {
    // Web uses FrequencyPlayerService directly
  }
  
  static Future<void> playWithVolume(double frequency, double volume) async {
    // Web uses FrequencyPlayerService directly
  }
  
  static Future<void> setVolume(double volume) async {
    // Web uses FrequencyPlayerService directly
  }
  
  static Future<void> stop() async {
    // Web uses FrequencyPlayerService directly
  }
  
  static Future<void> playBinaural(double leftFreq, double rightFreq) async {
    // Web uses FrequencyPlayerService directly
  }
  
  static Future<void> dispose() async {
    // Web uses FrequencyPlayerService directly
  }
}
