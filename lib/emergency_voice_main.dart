/// 🚨 EMERGENCY SIMPLE VOICE DEBUG
/// ABSOLUT MINIMALISTISCH - NUR DAS NÖTIGSTE
library;

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const EmergencyVoiceApp());
}

class EmergencyVoiceApp extends StatelessWidget {
  const EmergencyVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergency Voice Test',
      theme: ThemeData.dark(),
      home: const EmergencyVoiceScreen(),
    );
  }
}

class EmergencyVoiceScreen extends StatefulWidget {
  const EmergencyVoiceScreen({super.key});

  @override
  State<EmergencyVoiceScreen> createState() => _EmergencyVoiceScreenState();
}

class _EmergencyVoiceScreenState extends State<EmergencyVoiceScreen> {
  MediaStream? _localStream;
  bool _isInitializing = false;
  String _status = 'Bereit';
  final List<String> _logs = [];

  void _log(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toIso8601String().substring(11, 19)} - $message');
      if (_logs.length > 20) _logs.removeLast();
    });
    debugPrint(message);
  }

  Future<void> _initMicrophone() async {
    setState(() {
      _isInitializing = true;
      _status = 'Initialisiere...';
    });

    try {
      _log('🎤 START: Mikrofon-Initialisierung');

      // STEP 1: Permission
      _log('📋 Requesting microphone permission...');
      final status = await Permission.microphone.request();
      
      if (!status.isGranted) {
        _log('❌ FEHLER: Permission verweigert');
        setState(() {
          _status = 'Permission verweigert';
          _isInitializing = false;
        });
        return;
      }

      _log('✅ Permission erteilt');

      // STEP 2: getUserMedia
      _log('🎙️ Calling getUserMedia...');
      
      final mediaConstraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      };

      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

      if (_localStream == null) {
        _log('❌ FEHLER: Stream ist NULL');
        setState(() {
          _status = 'Stream NULL';
          _isInitializing = false;
        });
        return;
      }

      final audioTracks = _localStream!.getAudioTracks();
      _log('✅ Stream erstellt: ${audioTracks.length} audio tracks');

      for (var track in audioTracks) {
        _log('   Track: ${track.label} | enabled: ${track.enabled}');
      }

      setState(() {
        _status = '✅ Mikrofon aktiv!';
        _isInitializing = false;
      });

      _log('🎉 SUCCESS: Mikrofon funktioniert!');

    } catch (e, stackTrace) {
      _log('❌ FEHLER: $e');
      _log('Stack: ${stackTrace.toString().split('\n').first}');
      
      setState(() {
        _status = 'Fehler: $e';
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _localStream?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('🚨 Emergency Voice Test'),
        backgroundColor: Colors.red[900],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // STATUS
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STATUS:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Stream: ${_localStream != null ? "✅" : "❌"}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (_localStream != null)
                      Text(
                        'Audio Tracks: ${_localStream!.getAudioTracks().length}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // BUTTON
              ElevatedButton(
                onPressed: _isInitializing ? null : _initMicrophone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                child: _isInitializing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '🎤 MIKROFON INITIALISIEREN',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),

              const SizedBox(height: 24),

              // LOGS
              const Text(
                'DEBUG LOGS:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          _logs[index],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
