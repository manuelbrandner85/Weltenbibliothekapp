/// 🔧 AUTO-SAVE EXTENSIONS
/// Convenience extensions for easy auto-save integration
library;

import 'auto_save_manager.dart';

/// Extension on StorageService for auto-save support
extension AutoSaveExtension on dynamic {
  /// Auto-save to Materie Profile box
  void autoSaveMaterieProfile(String username) {
    AutoSaveManager().scheduleSave(
      key: username,
      data: this,
      boxName: 'materie_profiles',
      priority: SavePriority.critical,
    );
  }
  
  /// Auto-save to Energie Profile box
  void autoSaveEnergieProfile(String username) {
    AutoSaveManager().scheduleSave(
      key: username,
      data: this,
      boxName: 'energie_profiles',
      priority: SavePriority.critical,
    );
  }
  
  /// Auto-save chat message
  void autoSaveChatMessage(String messageId) {
    AutoSaveManager().scheduleSave(
      key: messageId,
      data: this,
      boxName: 'chat_messages',
      priority: SavePriority.high,
    );
  }
  
  /// Auto-save UI state
  void autoSaveUIState(String key) {
    AutoSaveManager().scheduleSave(
      key: key,
      data: this,
      boxName: 'ui_state',
      priority: SavePriority.medium,
    );
  }
  
  /// Auto-save with custom box and priority
  void autoSave({
    required String key,
    required String boxName,
    SavePriority priority = SavePriority.medium,
  }) {
    AutoSaveManager().scheduleSave(
      key: key,
      data: this,
      boxName: boxName,
      priority: priority,
    );
  }
}

/// Example usage:
/// 
/// ```dart
/// // In your profile screen:
/// void _updateProfile() {
///   final profile = MaterieProfile(...);
///   
///   // Auto-save with debounce (500ms delay)
///   profile.autoSaveMaterieProfile(username);
///   
///   // UI updates immediately, save happens in background
/// }
/// ```
