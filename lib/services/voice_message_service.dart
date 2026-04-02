/// 🎙️ Voice Message Service - Platform Switcher
/// Exports the correct implementation based on platform
library;

export 'voice_message_service_stub.dart'
  if (dart.library.html) 'voice_message_service_web.dart';
