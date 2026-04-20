// 🟢 APK DOWNLOAD SERVICE – Lädt eine neue APK in den App-Cache und öffnet
// den Android-PackageInstaller. Kein externer Browser nötig.
//
// Flow:
//   1. downloadApk(url, onProgress) – HTTP-Download mit Fortschrittsangabe
//   2. installApk(file) – öffnet den System-Installer via open_filex
//
// Bedarf:
//   - AndroidManifest: REQUEST_INSTALL_PACKAGES Permission
//   - AndroidManifest: FileProvider mit ${applicationId}.fileprovider
//   - android/app/src/main/res/xml/provider_paths.xml

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Fortschrittsinfo für den Download-Callback.
class ApkDownloadProgress {
  final int receivedBytes;
  final int totalBytes;
  final double percent;
  final double speedBytesPerSec;

  const ApkDownloadProgress({
    required this.receivedBytes,
    required this.totalBytes,
    required this.percent,
    required this.speedBytesPerSec,
  });
}

class ApkDownloadService {
  ApkDownloadService._();
  static final instance = ApkDownloadService._();

  CancelToken? _cancelToken;

  /// Lädt die APK nach [onProgress] fortschrittsanzeigend runter.
  /// Gibt den lokalen File-Pfad zurück, oder wirft [DioException].
  Future<File> downloadApk({
    required String url,
    required String version,
    required void Function(ApkDownloadProgress) onProgress,
  }) async {
    _cancelToken?.cancel('new-download');
    _cancelToken = CancelToken();

    final cacheDir = await getApplicationCacheDirectory();
    final file = File('${cacheDir.path}/weltenbibliothek-v$version.apk');
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {}
    }

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(minutes: 5),
      followRedirects: true,
      validateStatus: (status) => status != null && status < 400,
    ));

    final sw = Stopwatch()..start();
    int lastBytes = 0;
    double lastSpeed = 0;

    await dio.download(
      url,
      file.path,
      cancelToken: _cancelToken,
      onReceiveProgress: (received, total) {
        final elapsedMs = sw.elapsedMilliseconds;
        if (elapsedMs >= 300) {
          lastSpeed = (received - lastBytes) * 1000 / elapsedMs;
          sw.reset();
          lastBytes = received;
        }
        final percent = total > 0 ? (received / total) * 100 : 0.0;
        onProgress(ApkDownloadProgress(
          receivedBytes: received,
          totalBytes: total,
          percent: percent,
          speedBytesPerSec: lastSpeed,
        ));
      },
    );

    if (kDebugMode) {
      debugPrint('✅ [ApkDownload] fertig: ${file.path} '
          '(${await file.length()} bytes)');
    }
    return file;
  }

  /// Bricht den laufenden Download ab (falls vorhanden).
  void cancel() {
    _cancelToken?.cancel('user-cancelled');
    _cancelToken = null;
  }

  /// Öffnet die APK im System-Installer. Der User muss dann im Dialog
  /// "Installieren" tippen. Liefert false wenn das nicht möglich war.
  Future<bool> installApk(File file) async {
    try {
      final result = await OpenFilex.open(
        file.path,
        type: 'application/vnd.android.package-archive',
      );
      if (kDebugMode) {
        debugPrint('📲 [ApkInstall] type=${result.type} msg=${result.message}');
      }
      return result.type == ResultType.done;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [ApkInstall] Fehler: $e');
      return false;
    }
  }
}
