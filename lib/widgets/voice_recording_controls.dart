/// 📹 VOICE RECORDING CONTROLS
/// UI for controlling voice room recording
library;

import 'package:flutter/material.dart';
import '../services/voice_room_recording_service.dart';

class VoiceRecordingControls extends StatefulWidget {
  final String roomId;

  const VoiceRecordingControls({
    super.key,
    required this.roomId,
  });

  @override
  State<VoiceRecordingControls> createState() => _VoiceRecordingControlsState();
}

class _VoiceRecordingControlsState extends State<VoiceRecordingControls> {
  final VoiceRoomRecordingService _recordingService =
      VoiceRoomRecordingService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RecordingState>(
      stream: _recordingService.stateStream,
      initialData: _recordingService.state,
      builder: (context, stateSnapshot) {
        final state = stateSnapshot.data ?? RecordingState.idle;

        return StreamBuilder<Duration>(
          stream: _recordingService.durationStream,
          initialData: _recordingService.recordedDuration,
          builder: (context, durationSnapshot) {
            final duration = durationSnapshot.data ?? Duration.zero;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _getColorForState(state).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getColorForState(state).withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Recording Indicator
                  if (state == RecordingState.recording)
                    _buildRecordingIndicator(),

                  // Duration
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(
                      color: _getColorForState(state),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Control Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _buildControlButtons(state),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 🔴 Recording Indicator (Pulsing)
  Widget _buildRecordingIndicator() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: value * 0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
      onEnd: () {
        if (mounted) setState(() {});
      },
    );
  }

  /// 🎛️ Control Buttons
  List<Widget> _buildControlButtons(RecordingState state) {
    switch (state) {
      case RecordingState.idle:
        return [
          _buildButton(
            icon: Icons.fiber_manual_record,
            color: Colors.red,
            onPressed: () async {
              final success =
                  await _recordingService.startRecording(widget.roomId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔴 Aufnahme gestartet'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ];

      case RecordingState.recording:
        return [
          _buildButton(
            icon: Icons.pause,
            color: Colors.orange,
            onPressed: () => _recordingService.pauseRecording(),
          ),
          const SizedBox(width: 8),
          _buildButton(
            icon: Icons.stop,
            color: Colors.red,
            onPressed: () async {
              final path = await _recordingService.stopRecording();
              if (path != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Aufnahme gespeichert:\n$path'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
        ];

      case RecordingState.paused:
        return [
          _buildButton(
            icon: Icons.play_arrow,
            color: Colors.green,
            onPressed: () => _recordingService.resumeRecording(),
          ),
          const SizedBox(width: 8),
          _buildButton(
            icon: Icons.stop,
            color: Colors.red,
            onPressed: () async {
              final path = await _recordingService.stopRecording();
              if (path != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Aufnahme gespeichert:\n$path'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
        ];

      case RecordingState.stopped:
        return [
          _buildButton(
            icon: Icons.fiber_manual_record,
            color: Colors.red,
            onPressed: () async {
              final success =
                  await _recordingService.startRecording(widget.roomId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔴 Aufnahme gestartet'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ];
    }
  }

  /// 🔘 Button Widget
  Widget _buildButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color.withValues(alpha: 0.2),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  /// 🎨 Get Color for State
  Color _getColorForState(RecordingState state) {
    switch (state) {
      case RecordingState.idle:
        return Colors.grey;
      case RecordingState.recording:
        return Colors.red;
      case RecordingState.paused:
        return Colors.orange;
      case RecordingState.stopped:
        return Colors.green;
    }
  }

  /// ⏱️ Format Duration
  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }
}
