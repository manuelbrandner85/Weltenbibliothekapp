// 🌐📱 CROSS-PLATFORM RECHERCHE EXPORTER
// Automatically uses Web or Mobile implementation

export 'recherche_exporter_web.dart'
    if (dart.library.io) 'recherche_exporter_mobile.dart';
