// Web-Stub für shorebird_code_push.
// Auf Web gibt es keine OTA-Patches — alle Methoden sind no-ops.

class Patch {
  final int number;
  const Patch({required this.number});
}

enum UpdateStatus {
  upToDate,
  outdated,
  unavailable,
  restartRequired,
}

enum UpdateTrack {
  stable,
  beta,
  staging,
}

class ShorebirdUpdater {
  ShorebirdUpdater();

  bool get isAvailable => false;

  Future<Patch?> readCurrentPatch() async => null;
  Future<Patch?> readNextPatch() async => null;

  Future<UpdateStatus> checkForUpdate({UpdateTrack? track}) async =>
      UpdateStatus.unavailable;

  Future<bool> isUpdateAvailable() async => false;

  Future<void> update({UpdateTrack? track}) async {
    throw UnsupportedError('Shorebird-Update auf Web nicht verfügbar');
  }
}

class UpdateException implements Exception {
  final String message;
  UpdateException(this.message);
  @override
  String toString() => 'UpdateException: $message';
}
