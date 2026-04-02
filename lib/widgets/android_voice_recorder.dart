import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Android-Compatible Voice Message Recorder
/// Nutzt flutter_sound für Android/iOS/Web Support
class AndroidVoiceRecorder extends StatefulWidget {
  final Function(String audioPath, Duration duration) onRecordingComplete;
  final VoidCallback onCancel;
  
  const AndroidVoiceRecorder({
    super.key,
    required this.onRecordingComplete,
    required this.onCancel,
  });
  
  @override
  State<AndroidVoiceRecorder> createState() => _AndroidVoiceRecorderState();
}

class _AndroidVoiceRecorderState extends State<AndroidVoiceRecorder>
    with SingleTickerProviderStateMixin {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  bool _isRecorderInitialized = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;
  late AnimationController _pulseController;
  String? _audioPath;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _initRecorder();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }
  
  Future<void> _initRecorder() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      
      if (status != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Mikrofon-Berechtigung erforderlich'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }
      
      // Open the recorder
      await _recorder.openRecorder();
      
      setState(() {
        _isRecorderInitialized = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler beim Initialisieren: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }
  
  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏳ Recorder wird initialisiert...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    try {
      // Create temp file path
      final tempDir = await getTemporaryDirectory();
      _audioPath = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';
      
      // Start recording
      await _recorder.startRecorder(
        toFile: _audioPath,
        codec: Codec.aacADTS, // AAC format (Android compatible)
      );
      
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });
      
      // Start timer
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration = Duration(seconds: timer.tick);
          
          // Auto-stop at 60 seconds
          if (_recordingDuration.inSeconds >= 60) {
            _stopRecording();
          }
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Aufnahme-Fehler: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _stopRecording() async {
    _timer?.cancel();
    
    if (_recordingDuration.inSeconds < 1) {
      // Too short
      await _recorder.stopRecorder();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Aufnahme zu kurz (min 1 Sekunde)'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
      });
      return;
    }
    
    try {
      await _recorder.stopRecorder();
      
      if (_audioPath != null) {
        widget.onRecordingComplete(_audioPath!, _recordingDuration);
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Fehler beim Stoppen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _cancelRecording() async {
    _timer?.cancel();
    
    if (_isRecording) {
      await _recorder.stopRecorder();
      
      // Delete temp file
      if (_audioPath != null) {
        try {
          final file = File(_audioPath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          // Ignore delete errors
        }
      }
    }
    
    widget.onCancel();
    if (mounted) {
      Navigator.pop(context);
    }
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Text(
            _isRecording ? 'Aufnahme läuft...' : 'Sprachnachricht',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          
          // Waveform Animation or Microphone Icon
          if (_isRecording)
            SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(5, (index) {
                  return AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final delay = index * 0.2;
                      final value = (_pulseController.value + delay) % 1.0;
                      final height = 20 + (value * 40);
                      
                      return Container(
                        width: 6,
                        height: height,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    },
                  );
                }),
              ),
            )
          else
            Icon(
              Icons.mic,
              size: 60,
              color: _isRecorderInitialized 
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.3),
            ),
          
          const SizedBox(height: 20),
          
          // Duration Display
          Text(
            _formatDuration(_recordingDuration),
            style: TextStyle(
              color: _isRecording ? Colors.red : Colors.white.withValues(alpha: 0.5),
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          
          if (_isRecording)
            Text(
              'Max 60 Sekunden',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            )
          else if (!_isRecorderInitialized)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            ),
          
          const SizedBox(height: 30),
          
          // Control Buttons
          if (_isRecorderInitialized)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cancel Button
                if (_isRecording)
                  IconButton(
                    onPressed: _cancelRecording,
                    icon: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    iconSize: 64,
                  ),
                
                const SizedBox(width: 20),
                
                // Record/Stop Button
                GestureDetector(
                  onTap: _isRecording ? _stopRecording : _startRecording,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // Spacer for symmetry
                if (_isRecording)
                  const SizedBox(width: 64),
              ],
            ),
          
          const SizedBox(height: 20),
          
          // Hint Text
          if (!_isRecording && _isRecorderInitialized)
            TextButton(
              onPressed: _cancelRecording,
              child: const Text(
                'Abbrechen',
                style: TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }
}
