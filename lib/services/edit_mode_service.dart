/// Global Edit Mode State Management
/// 
/// Ermöglicht Content Editors, den Edit-Modus app-weit zu aktivieren/deaktivieren
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/dynamic_content_service.dart';
import '../services/user_auth_service.dart';

/// ============================================================================
/// EDIT MODE SERVICE - Globaler Edit-Modus State
/// ============================================================================

class EditModeService {
  // Singleton Pattern
  static final EditModeService _instance = EditModeService._internal();
  factory EditModeService() => _instance;
  EditModeService._internal();

  // State
  bool _isEditMode = false;
  bool _canEdit = false;
  bool _isInitialized = false;
  
  // Stream für Edit Mode Changes
  final _editModeController = StreamController<bool>.broadcast();
  Stream<bool> get editModeStream => _editModeController.stream;
  
  // Getters
  bool get isEditMode => _isEditMode;
  bool get canEdit => _canEdit;
  bool get isInitialized => _isInitialized;
  
  /// Initialize Edit Mode Service
  /// Prüft, ob aktueller User Content Editor ist
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Check if user can edit content
      final contentService = DynamicContentService();
      _canEdit = await contentService.canEditContent();
      
      // Alternative: Check via UserAuthService
      if (!_canEdit) {
        final username = await UserAuthService.getUsername(world: 'energie');
        _canEdit = username == 'Weltenbibliothekedit' || username == 'Weltenbibliothek';
      }
      
      _isInitialized = true;
      
      if (_canEdit) {
        debugPrint('✏️ [EDIT MODE] User can edit content');
      }
    } catch (e) {
      debugPrint('❌ [EDIT MODE] Initialization failed: $e');
      _canEdit = false;
      _isInitialized = true;
    }
  }
  
  /// Toggle Edit Mode ON/OFF
  void toggleEditMode() {
    if (!_canEdit) {
      debugPrint('⚠️ [EDIT MODE] User cannot edit content');
      return;
    }
    
    _isEditMode = !_isEditMode;
    _editModeController.add(_isEditMode);
    
    debugPrint('✏️ [EDIT MODE] Edit mode ${_isEditMode ? 'ENABLED' : 'DISABLED'}');
  }
  
  /// Set Edit Mode directly
  void setEditMode(bool enabled) {
    if (!_canEdit && enabled) {
      debugPrint('⚠️ [EDIT MODE] User cannot enable edit mode');
      return;
    }
    
    if (_isEditMode != enabled) {
      _isEditMode = enabled;
      _editModeController.add(_isEditMode);
      
      debugPrint('✏️ [EDIT MODE] Edit mode set to ${_isEditMode ? 'ON' : 'OFF'}');
    }
  }
  
  /// Force disable Edit Mode (e.g., when leaving screen)
  void disableEditMode() {
    if (_isEditMode) {
      _isEditMode = false;
      _editModeController.add(_isEditMode);
      debugPrint('✏️ [EDIT MODE] Edit mode forcefully disabled');
    }
  }
  
  /// Clean up resources
  void dispose() {
    _editModeController.close();
  }
  
  /// Get singleton instance
  static EditModeService get instance => _instance;
}
