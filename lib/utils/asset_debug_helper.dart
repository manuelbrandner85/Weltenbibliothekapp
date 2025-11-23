import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class AssetDebugHelper {
  static Future<bool> assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      if (kDebugMode) {
        debugPrint('✅ Asset: $assetPath');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Missing: $assetPath');
      }
      return false;
    }
  }
}
