import 'package:flutter/material.dart';

/// Voice Recording Button with animated indicator
class VoiceRecordingButton extends StatefulWidget {
  final VoidCallback? onStartRecording;
  final VoidCallback? onStopRecording;
  final VoidCallback? onCancelRecording;
  final bool isRecording;
  final Duration recordingDuration;
  
  const VoiceRecordingButton({
    super.key,
    this.onStartRecording,
    this.onStopRecording,
    this.onCancelRecording,
    this.isRecording = false,
    this.recordingDuration = Duration.zero,
  });

  @override
  State<VoiceRecordingButton> createState() => _VoiceRecordingButtonState();
}

class _VoiceRecordingButtonState extends State<VoiceRecordingButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.isRecording) {
      // Recording mode - show timer and controls
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            // Animated recording indicator
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(width: 12),
            
            // Duration timer
            Text(
              _formatDuration(widget.recordingDuration),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            
            const SizedBox(width: 8),
            
            const Text(
              'Aufnahme...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            
            const Spacer(),
            
            // Cancel button
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: widget.onCancelRecording,
              tooltip: 'Abbrechen',
            ),
            
            // Stop button
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: widget.onStopRecording,
              tooltip: 'Senden',
            ),
          ],
        ),
      );
    }
    
    // Normal mode - microphone button
    return IconButton(
      icon: const Icon(Icons.mic, color: Colors.grey),
      onPressed: widget.onStartRecording,
      tooltip: 'Sprachnachricht',
    );
  }
}

/// Voice Recording Overlay - full-screen recording UI
class VoiceRecordingOverlay extends StatelessWidget {
  final Duration duration;
  final VoidCallback? onCancel;
  final VoidCallback? onSend;
  
  const VoiceRecordingOverlay({
    super.key,
    this.duration = Duration.zero,
    this.onCancel,
    this.onSend,
  });
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated microphone icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 1.0 + (value * 0.3),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic,
                      size: 80,
                      color: Colors.red,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Duration
            Text(
              _formatDuration(duration),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'Sprachnachricht wird aufgenommen',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            
            const SizedBox(height: 64),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cancel button
                FloatingActionButton(
                  onPressed: onCancel,
                  backgroundColor: Colors.grey[800],
                  child: const Icon(Icons.close, size: 32),
                ),
                
                const SizedBox(width: 32),
                
                // Send button
                FloatingActionButton.extended(
                  onPressed: onSend,
                  backgroundColor: Colors.blue,
                  icon: const Icon(Icons.send),
                  label: const Text('SENDEN'),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Hint
            const Text(
              'Wischen Sie nach links zum Abbrechen',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
