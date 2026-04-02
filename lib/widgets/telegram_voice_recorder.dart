import 'package:flutter/material.dart';

/// Telegram Voice Recorder - Disabled for Android Build
class TelegramVoiceRecorder extends StatelessWidget {
  final Function(String, int)? onRecordComplete;
  final Function(String)? onVoiceMessageSent;
  final String? realm;
  final Color? accentColor;
  
  const TelegramVoiceRecorder({
    super.key,
    this.onRecordComplete,
    this.onVoiceMessageSent,
    this.realm,
    this.accentColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.mic_off),
      color: accentColor ?? Colors.grey,
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice recording disabled in this build')),
        );
      },
      tooltip: 'Voice recording disabled',
    );
  }
}
