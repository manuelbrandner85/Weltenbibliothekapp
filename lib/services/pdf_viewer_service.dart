/// 📄 PDF VIEWER SERVICE
/// Simple service for PDF handling
/// 
/// NOTE: PDFs are opened via url_launcher in external browser
/// This is a web-compatible approach
library;

import 'package:flutter/foundation.dart';

class PdfViewerService {
  /// Open PDF document from URL
  /// NOTE: For web, use url_launcher instead
  static Future<void> openPdfFromUrl(String url) async {
    if (kDebugMode) {
      debugPrint('📄 PDF Viewer: PDF URLs should be opened with url_launcher');
      debugPrint('   → URL: $url');
    }
    
    // PDFs are handled by url_launcher in the UI layer
    return;
  }
}
