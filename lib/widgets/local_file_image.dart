// Plattform-Wrapper für Image.file(File(path)).
// Auf Web ist dart:io.File nicht verfügbar — dart2js bricht den Build wenn
// das Code-Pfad direkt referenziert wird (auch unter kIsWeb-Guard). Diese
// Datei re-exportiert die plattformspezifische Implementation via
// conditional import.
export 'local_file_image_io.dart'
    if (dart.library.html) 'local_file_image_web.dart';
