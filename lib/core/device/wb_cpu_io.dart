// CPU core count on native platforms (Android/iOS/desktop).
import 'dart:io' show Platform;

/// Number of logical CPU cores, or 0 if unknown.
int wbCpuCores() {
  try {
    return Platform.numberOfProcessors;
  } catch (_) {
    return 0;
  }
}
