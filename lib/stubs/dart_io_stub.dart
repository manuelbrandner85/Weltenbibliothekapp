// Web-Stub für dart:io (nicht verfügbar im Browser).
// Stellt minimale API-Kompatibilität für File/Directory/Platform/HttpClient/exit.
// Alle I/O-Operationen werfen UnsupportedError oder sind No-Ops.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

class FileMode {
  final int _mode;
  const FileMode._(this._mode);
  static const FileMode read = FileMode._(0);
  static const FileMode write = FileMode._(1);
  static const FileMode append = FileMode._(2);
  static const FileMode writeOnly = FileMode._(3);
  static const FileMode writeOnlyAppend = FileMode._(4);
  @override
  String toString() => 'FileMode($_mode)';
}

class IOException implements Exception {
  final String message;
  IOException([this.message = '']);
  @override
  String toString() => 'IOException: $message';
}

class SocketException implements IOException {
  @override
  final String message;
  final OSError? osError;
  final InternetAddress? address;
  final int? port;
  SocketException(this.message, {this.osError, this.address, this.port});
  SocketException.closed() : this('Socket closed');
  @override
  String toString() => 'SocketException: $message';
}

class TlsException implements IOException {
  @override
  final String message;
  TlsException([this.message = '']);
  @override
  String toString() => 'TlsException: $message';
}

class HandshakeException extends TlsException {
  HandshakeException([super.message]);
}

class CertificateException extends TlsException {
  CertificateException([super.message]);
}

class HttpException implements IOException {
  @override
  final String message;
  final Uri? uri;
  HttpException(this.message, {this.uri});
  @override
  String toString() => 'HttpException: $message';
}

class FileSystemException implements IOException {
  @override
  final String message;
  final String? path;
  final OSError? osError;
  FileSystemException([this.message = '', this.path, this.osError]);
  @override
  String toString() => 'FileSystemException: $message';
}

class OSError {
  final String message;
  final int errorCode;
  const OSError([this.message = '', this.errorCode = 0]);
  @override
  String toString() => 'OSError: $message';
}

class InternetAddress {
  final String address;
  final String host;
  const InternetAddress(this.address, {this.host = ''});
}

class IOSink {
  Future<void> close() async {}
  void add(List<int> data) {}
  void write(Object? obj) {}
  void writeln([Object? obj = '']) {}
  Future<void> flush() async {}
  Future<void> addStream(Stream<List<int>> stream) async {}
}

class FileStat {
  final int size;
  final DateTime modified;
  final DateTime accessed;
  final DateTime changed;
  FileStat._()
      : size = 0,
        modified = DateTime.fromMillisecondsSinceEpoch(0),
        accessed = DateTime.fromMillisecondsSinceEpoch(0),
        changed = DateTime.fromMillisecondsSinceEpoch(0);
  static FileStat get _empty => FileStat._();
}

class File {
  final String path;
  File(this.path);

  Future<bool> exists() async => false;
  bool existsSync() => false;

  Future<Uint8List> readAsBytes() async =>
      throw UnsupportedError('File.readAsBytes nicht auf Web verfügbar');
  Uint8List readAsBytesSync() =>
      throw UnsupportedError('File.readAsBytesSync nicht auf Web verfügbar');

  Future<String> readAsString({Encoding encoding = utf8}) async =>
      throw UnsupportedError('File.readAsString nicht auf Web verfügbar');
  String readAsStringSync({Encoding encoding = utf8}) =>
      throw UnsupportedError('File.readAsStringSync nicht auf Web verfügbar');

  Future<List<String>> readAsLines({Encoding encoding = utf8}) async =>
      const [];

  Future<File> writeAsBytes(List<int> bytes,
          {FileMode mode = FileMode.write, bool flush = false}) async =>
      throw UnsupportedError('File.writeAsBytes nicht auf Web verfügbar');
  void writeAsBytesSync(List<int> bytes,
          {FileMode mode = FileMode.write, bool flush = false}) =>
      throw UnsupportedError('File.writeAsBytesSync nicht auf Web verfügbar');

  Future<File> writeAsString(String contents,
          {FileMode mode = FileMode.write,
          Encoding encoding = utf8,
          bool flush = false}) async =>
      throw UnsupportedError('File.writeAsString nicht auf Web verfügbar');

  Future<File> delete({bool recursive = false}) async => this;
  void deleteSync({bool recursive = false}) {}

  Future<File> create({bool recursive = false, bool exclusive = false}) async =>
      this;
  void createSync({bool recursive = false, bool exclusive = false}) {}

  Future<int> length() async => 0;
  int lengthSync() => 0;

  Future<FileStat> stat() async => FileStat._empty;
  FileStat statSync() => FileStat._empty;

  IOSink openWrite(
          {FileMode mode = FileMode.write, Encoding encoding = utf8}) =>
      IOSink();

  Stream<List<int>> openRead([int? start, int? end]) =>
      const Stream<List<int>>.empty();

  File get absolute => this;

  Uri get uri => Uri.parse('file://$path');

  Future<File> copy(String newPath) async => File(newPath);

  Future<File> rename(String newPath) async => File(newPath);

  Directory get parent => Directory('');
}

class Directory {
  final String path;
  Directory(this.path);

  Future<bool> exists() async => false;
  bool existsSync() => false;
  Future<Directory> create({bool recursive = false}) async => this;
  void createSync({bool recursive = false}) {}
  Future<Directory> delete({bool recursive = false}) async => this;
  Stream<FileSystemEntity> list(
          {bool recursive = false, bool followLinks = true}) =>
      const Stream<FileSystemEntity>.empty();
  List<FileSystemEntity> listSync(
          {bool recursive = false, bool followLinks = true}) =>
      const <FileSystemEntity>[];
  Directory get absolute => this;
  static Directory get current => Directory('/');
  static Directory get systemTemp => Directory('/tmp');
}

abstract class FileSystemEntity {
  String get path;
}

class Platform {
  static const bool isAndroid = false;
  static const bool isIOS = false;
  static const bool isLinux = false;
  static const bool isMacOS = false;
  static const bool isWindows = false;
  static const bool isFuchsia = false;
  static const String operatingSystem = 'web';
  static const String operatingSystemVersion = '';
  static const String localHostname = 'localhost';
  static const String pathSeparator = '/';
  static const String localeName = 'en_US';
  static const Map<String, String> environment = <String, String>{};
  static const String executable = '';
  static const String resolvedExecutable = '';
  static const List<String> executableArguments = <String>[];
  static const String? packageConfig = null;
  static const String script = '';
  static const int numberOfProcessors = 1;
  static const String? version = null;
}

Never exit([int code = 0]) {
  throw UnsupportedError('exit() nicht auf Web verfügbar');
}

class HttpClient {
  Duration? connectionTimeout;
  Duration idleTimeout = const Duration(seconds: 15);
  bool autoUncompress = true;
  String? userAgent;

  HttpClient();

  Future<HttpClientRequest> getUrl(Uri url) async =>
      throw UnsupportedError('HttpClient nicht auf Web verfügbar');
  Future<HttpClientRequest> postUrl(Uri url) async =>
      throw UnsupportedError('HttpClient nicht auf Web verfügbar');
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      throw UnsupportedError('HttpClient nicht auf Web verfügbar');
  void close({bool force = false}) {}
}

abstract class HttpClientRequest {
  Future<HttpClientResponse> close();
}

abstract class HttpClientResponse extends Stream<List<int>> {
  int get statusCode;
  int get contentLength;
}

// consolidateHttpClientResponseBytes wird von flutter/foundation re-exportiert
// und ist daher nicht hier nochmal nötig.
