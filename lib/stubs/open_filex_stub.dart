// Stub for open_filex on web (package has no web implementation).
// ApkDownloadService guards all real usages with kIsWeb checks.

enum ResultType {
  done,
  error,
  noAppToOpen,
  permissionDenied,
  permissionDeniedOnOpenSetting,
  fileNotFound,
}

class OpenResult {
  final ResultType type;
  final String message;
  const OpenResult({required this.type, required this.message});
}

class OpenFilex {
  static Future<OpenResult> open(String? filePath,
          {String? type, String? uti}) async =>
      const OpenResult(type: ResultType.error, message: 'Not supported on web');
}
