/// Plattform-Router für den Key-Value-Store.
/// • Mobile (Android/iOS): sqflite-basiert (sqlite_storage_service_io.dart)
/// • Web: SharedPreferences-basiert (sqlite_storage_service_web.dart)
export 'sqlite_storage_service_io.dart'
    if (dart.library.html) 'sqlite_storage_service_web.dart';
