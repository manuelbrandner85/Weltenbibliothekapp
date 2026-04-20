// 🟢 APK DOWNLOAD SERVICE – Lädt eine neue APK in den App-Cache und öffnet
// den Android-PackageInstaller. Kein externer Browser nötig.
//
// Flow:
//   1. downloadApk(url, onProgress) – HTTP-Download mit Fortschrittsangabe
//      → unterstützt Resume (Range-Header) wenn ein Teil-Download existiert
//   2. installApk(file) – öffnet den System-Installer via open_filex
//
// Resume-Logik:
//   - HEAD-Request ermittelt Gesamt-Größe
//   - Existiert bereits eine Teil-Datei: GET mit Range: bytes=N- und Append-Mode
//   - Bei Fehler: Teildatei bleibt erhalten → nächster Versuch setzt fort
//   - Ist die Datei bereits komplett: sofort zurückgeben (kein Download nötig)

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
  /// Unterstützt Resume: existiert eine Teildatei, wird der Download fortgesetzt.
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

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(minutes: 5),
      followRedirects: true,
      validateStatus: (status) => status != null && status < 400,
    ));

    // Gesamt-Größe via HEAD ermitteln (für Resume-Check)
    final totalBytes = await _getRemoteFileSize(dio, url);

    // Bestehende Teildatei prüfen
    final existingBytes = await file.exists() ? await file.length() : 0;

    if (totalBytes != null && existingBytes >= totalBytes && existingBytes > 0) {
      // Datei bereits vollständig
      if (kDebugMode) {
        debugPrint('✅ [ApkDownload] bereits vollständig: ${file.path}');
      }
      onProgress(ApkDownloadProgress(
        receivedBytes: existingBytes,
        totalBytes: existingBytes,
        percent: 100,
        speedBytesPerSec: 0,
      ));
      return file;
    }

    if (existingBytes > 0 && totalBytes != null) {
      // Resume: Range-Request + Datei anhängen
      if (kDebugMode) {
        debugPrint('▶️  [ApkDownload] Resume ab Byte $existingBytes / $totalBytes');
      }
      await _resumeDownload(
        dio: dio,
        file: file,
        url: url,
        startByte: existingBytes,
        totalBytes: totalBytes,
        onProgress: onProgress,
      );
    } else {
      // Neuer Download: alte Teildatei löschen falls vorhanden
      if (await file.exists()) await file.delete();
      await _freshDownload(
        dio: dio,
        file: file,
        url: url,
        totalBytes: totalBytes ?? 0,
        onProgress: onProgress,
      );
    }

    if (kDebugMode) {
      debugPrint('✅ [ApkDownload] fertig: ${file.path} '
          '(${await file.length()} bytes)');
    }
    return file;
  }

  /// HEAD-Request um Content-Length zu ermitteln.
  Future<int?> _getRemoteFileSize(Dio dio, String url) async {
    try {
      final resp = await dio.head<void>(url);
      final cl = resp.headers.value(Headers.contentLengthHeader);
      return cl != null ? int.tryParse(cl) : null;
    } catch (_) {
      return null;
    }
  }

  /// Vollständiger Download ohne Resume.
  Future<void> _freshDownload({
    required Dio dio,
    required File file,
    required String url,
    required int totalBytes,
    required void Function(ApkDownloadProgress) onProgress,
  }) async {
    final sw = Stopwatch()..start();
    int lastBytes = 0;
    double lastSpeed = 0;

    await dio.download(
      url,
      file.path,
      cancelToken: _cancelToken,
      deleteOnError: false, // Teildatei behalten für späteres Resume
      onReceiveProgress: (received, total) {
        final effectiveTotal = total > 0 ? total : totalBytes;
        final elapsed = sw.elapsedMilliseconds;
        if (elapsed >= 300) {
          lastSpeed = (received - lastBytes) * 1000 / elapsed;
          sw.reset();
          lastBytes = received;
        }
        onProgress(ApkDownloadProgress(
          receivedBytes: received,
          totalBytes: effectiveTotal,
          percent: effectiveTotal > 0 ? (received / effectiveTotal) * 100 : 0,
          speedBytesPerSec: lastSpeed,
        ));
      },
    );
  }

  /// Resume-Download via Range-Header, hängt an bestehende Datei an.
  Future<void> _resumeDownload({
    required Dio dio,
    required File file,
    required String url,
    required int startByte,
    required int totalBytes,
    required void Function(ApkDownloadProgress) onProgress,
  }) async {
    final response = await dio.get<ResponseBody>(
      url,
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Range': 'bytes=$startByte-'},
        validateStatus: (s) => s != null && (s == 206 || s < 400),
      ),
      cancelToken: _cancelToken,
    );

    final sink = file.openWrite(mode: FileMode.append);
    int received = startByte;
    final sw = Stopwatch()..start();
    int lastBytes = startByte;
    double lastSpeed = 0;

    try {
      await for (final chunk in response.data!.stream) {
        if (_cancelToken?.isCancelled ?? false) break;
        sink.add(chunk);
        received += chunk.length;
        final elapsed = sw.elapsedMilliseconds;
        if (elapsed >= 300) {
          lastSpeed = (received - lastBytes) * 1000 / elapsed;
          sw.reset();
          lastBytes = received;
        }
        onProgress(ApkDownloadProgress(
          receivedBytes: received,
          totalBytes: totalBytes,
          percent: (received / totalBytes) * 100,
          speedBytesPerSec: lastSpeed,
        ));
      }
    } finally {
      await sink.close();
    }
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
