/// 🖥️ WELTENBIBLIOTHEK - SCREEN SHARE VIEWER WIDGET
/// Displays shared screens in voice chat
/// Features: Full screen view, PiP mode, quality indicator
library;

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/screen_sharing_service.dart';

class ScreenShareViewer extends StatefulWidget {
  const ScreenShareViewer({super.key});

  @override
  State<ScreenShareViewer> createState() => _ScreenShareViewerState();
}

class _ScreenShareViewerState extends State<ScreenShareViewer> {
  final ScreenSharingService _screenService = ScreenSharingService();
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  bool _isInitialized = false;
  bool _isPiPMode = false;
  
  ScreenShareParticipant? _currentSharer;

  @override
  void initState() {
    super.initState();
    _initRenderer();
    
    _screenService.screenParticipantsStream.listen((participants) {
      if (mounted && participants.isNotEmpty) {
        setState(() {
          _currentSharer = participants.first;
          if (_isInitialized) {
            _renderer.srcObject = _currentSharer!.stream;
          }
        });
      } else if (mounted) {
        setState(() {
          _currentSharer = null;
          if (_isInitialized) {
            _renderer.srcObject = null;
          }
        });
      }
    });
  }

  Future<void> _initRenderer() async {
    try {
      await _renderer.initialize();
      setState(() => _isInitialized = true);
      
      if (_currentSharer != null) {
        _renderer.srcObject = _currentSharer!.stream;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Initialisieren: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentSharer == null) {
      return const SizedBox.shrink();
    }
    
    if (_isPiPMode) {
      return _buildPiPView();
    } else {
      return _buildFullView();
    }
  }

  Widget _buildFullView() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        title: Row(
          children: [
            const Icon(Icons.screen_share, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${_currentSharer!.username} teilt Bildschirm',
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_in_picture, color: Colors.white),
            tooltip: 'Picture-in-Picture',
            onPressed: () {
              setState(() => _isPiPMode = true);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Center(
        child: _isInitialized
            ? RTCVideoView(
                _renderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                mirror: false,
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildPiPView() {
    return Positioned(
      bottom: 100,
      right: 16,
      child: GestureDetector(
        onTap: () {
          setState(() => _isPiPMode = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                body: _buildFullView(),
              ),
            ),
          );
        },
        child: Container(
          width: 160,
          height: 90,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _isInitialized
                    ? RTCVideoView(
                        _renderer,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        mirror: false,
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
              ),
              Positioned(
                bottom: 4,
                left: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.screen_share,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _currentSharer!.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isPiPMode = false;
                      _currentSharer = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
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

/// Screen Share Button for Admin/Moderator
class ScreenShareButton extends StatefulWidget {
  final String userId;
  final String username;
  final bool isAdmin;
  
  const ScreenShareButton({
    super.key,
    required this.userId,
    required this.username,
    this.isAdmin = false,
  });

  @override
  State<ScreenShareButton> createState() => _ScreenShareButtonState();
}

class _ScreenShareButtonState extends State<ScreenShareButton> {
  final ScreenSharingService _screenService = ScreenSharingService();
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    
    _screenService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isSharing = state == ScreenShareState.active;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAdmin) {
      return const SizedBox.shrink();
    }
    
    return FloatingActionButton.small(
      heroTag: 'screen_share',
      backgroundColor: _isSharing ? Colors.red : Colors.blue,
      onPressed: () async {
        if (_isSharing) {
          await _screenService.stopScreenShare();
        } else {
          final success = await _screenService.startScreenShare(
            userId: widget.userId,
            username: widget.username,
          );
          
          if (!success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fehler beim Starten der Bildschirmfreigabe'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Icon(
        _isSharing ? Icons.stop_screen_share : Icons.screen_share,
        color: Colors.white,
      ),
    );
  }
}
