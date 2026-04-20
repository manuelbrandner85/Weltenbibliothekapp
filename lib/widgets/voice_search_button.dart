// lib/widgets/voice_search_button.dart
// WELTENBIBLIOTHEK v9.0 - SPRINT 2: AI RESEARCH ASSISTANT
// Feature 14.2: Voice Search Button with Recording Animation

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/voice_assistant_service.dart';

/// Voice Search Button Widget
/// Floating microphone button with recording animation and transcript dialog
class VoiceSearchButton extends StatefulWidget {
  final Function(String query)? onSearchQuery;
  final Function(VoiceCommand command)? onVoiceCommand;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const VoiceSearchButton({
    super.key,
    this.onSearchQuery,
    this.onVoiceCommand,
    this.backgroundColor,
    this.iconColor,
    this.size = 56.0,
  });

  @override
  State<VoiceSearchButton> createState() => _VoiceSearchButtonState();
}

class _VoiceSearchButtonState extends State<VoiceSearchButton>
    with SingleTickerProviderStateMixin {
  final VoiceAssistantService _voiceService = VoiceAssistantService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  bool _isRecording = false;
  String _transcript = '';
  String _statusMessage = '';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialize voice service
    _initializeVoiceService();
  }

  Future<void> _initializeVoiceService() async {
    try {
      final initialized = await _voiceService.initialize();
      if (!initialized) {
        setState(() {
          _statusMessage = 'Spracherkennung nicht verfügbar';
          _hasError = true;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Voice service initialization failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Toggle voice recording
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  /// Start voice recording
  Future<void> _startRecording() async {
    setState(() {
      _transcript = '';
      _statusMessage = 'Höre zu...';
      _hasError = false;
    });

    // Set up callbacks
    _voiceService.onTranscriptUpdate = (transcript) {
      setState(() {
        _transcript = transcript;
        _statusMessage = 'Höre zu...';
      });
    };

    _voiceService.onFinalTranscript = (transcript) {
      setState(() {
        _transcript = transcript;
        _statusMessage = 'Verarbeite...';
      });
      
      // Process command
      _processVoiceCommand(transcript);
    };

    _voiceService.onError = (error) {
      setState(() {
        _statusMessage = 'Fehler: $error';
        _hasError = true;
        _isRecording = false;
      });
    };

    // Start listening
    final started = await _voiceService.startListening(localeId: 'de_DE');
    
    if (started) {
      setState(() {
        _isRecording = true;
      });
      
      // Show transcript dialog
      if (mounted) {
        _showTranscriptDialog();
      }
    } else {
      setState(() {
        _statusMessage = 'Mikrofon nicht verfügbar';
        _hasError = true;
      });
      
      if (mounted) {
        _showErrorDialog();
      }
    }
  }

  /// Stop voice recording
  Future<void> _stopRecording() async {
    await _voiceService.stopListening();
    setState(() {
      _isRecording = false;
    });
  }

  /// Cancel voice recording
  Future<void> _cancelRecording() async {
    await _voiceService.cancelListening();
    setState(() {
      _isRecording = false;
      _transcript = '';
      _statusMessage = '';
    });
    
    if (mounted) {
      Navigator.of(context).pop(); // Close dialog
    }
  }

  /// Process voice command
  void _processVoiceCommand(String transcript) {
    final command = _voiceService.processCommand(transcript);
    
    if (kDebugMode) {
      debugPrint('🎤 Voice Command: $command');
    }

    // Close dialog
    if (mounted) {
      Navigator.of(context).pop();
    }

    // Execute command
    if (command.type == VoiceCommandType.search && command.query != null) {
      widget.onSearchQuery?.call(command.query!);
    }
    
    widget.onVoiceCommand?.call(command);
  }

  /// Show transcript dialog
  void _showTranscriptDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Update dialog when transcript changes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setDialogState(() {});
            }
          });

          return Dialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Recording Animation
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _hasError
                                  ? [Colors.red.shade700, Colors.red.shade900]
                                  : [Colors.purple.shade700, Colors.blue.shade700],
                            ),
                          ),
                          child: Icon(
                            _hasError ? Icons.error_outline : Icons.mic,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),

                  // Status Message
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _hasError ? Colors.red.shade400 : Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),

                  // Transcript Display
                  Container(
                    constraints: const BoxConstraints(minHeight: 60),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _hasError 
                            ? Colors.red.withValues(alpha: 0.3)
                            : Colors.purple.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _transcript.isEmpty ? '...' : _transcript,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Cancel Button
                      TextButton.icon(
                        onPressed: _cancelRecording,
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text(
                          'Abbrechen',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      
                      // Stop Button
                      if (_isRecording)
                        ElevatedButton.icon(
                          onPressed: _stopRecording,
                          icon: const Icon(Icons.stop),
                          label: const Text('Fertig'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Show error dialog
  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 12),
            Text('Fehler', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          _statusMessage,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _toggleRecording,
      backgroundColor: widget.backgroundColor ?? 
          (_isRecording ? Colors.red.shade700 : Colors.purple.shade700),
      heroTag: 'voice_search_button',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Icon(
          _isRecording ? Icons.stop : Icons.mic,
          key: ValueKey<bool>(_isRecording),
          color: widget.iconColor ?? Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
