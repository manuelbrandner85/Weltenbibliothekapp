import 'package:flutter/material.dart';
import '../services/checkin_service.dart';
import '../services/haptic_service.dart';
import '../services/streak_tracking_service.dart';

/// Check-In-Button Widget für Marker-Details
class CheckInButton extends StatefulWidget {
  final String locationId;
  final String locationName;
  final String category;
  final String worldType;
  final Color accentColor;
  
  const CheckInButton({
    super.key,
    required this.locationId,
    required this.locationName,
    required this.category,
    required this.worldType,
    required this.accentColor,
  });

  @override
  State<CheckInButton> createState() => _CheckInButtonState();
}

class _CheckInButtonState extends State<CheckInButton> 
    with SingleTickerProviderStateMixin {
  final CheckInService _checkInService = CheckInService();
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isCheckedIn = false;

  @override
  void initState() {
    super.initState();
    _isCheckedIn = _checkInService.hasVisited(widget.locationId);
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    // Stream für Updates
    _checkInService.checkInsStream.listen((_) {
      if (mounted) {
        setState(() {
          _isCheckedIn = _checkInService.hasVisited(widget.locationId);
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleCheckIn() async {
    if (_isCheckedIn) {
      // Bereits eingecheckt
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Du hast diesen Ort bereits besucht'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Animation
    await _controller.forward();
    await _controller.reverse();

    // Haptic Feedback
    HapticService.mediumImpact();

    // Check-In erstellen
    await _checkInService.checkIn(
      locationId: widget.locationId,
      locationName: widget.locationName,
      category: widget.category,
      worldType: widget.worldType,
    );

    // Streak tracken (+15 Punkte)
    await StreakTrackingService().trackCheckIn(widget.locationName);

    setState(() {
      _isCheckedIn = true;
    });

    // Success Snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('✓'),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Check-In bei ${widget.locationName}'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: ElevatedButton.icon(
        onPressed: _isCheckedIn ? null : _handleCheckIn,
        icon: Icon(
          _isCheckedIn ? Icons.check_circle : Icons.location_on,
          size: 20,
        ),
        label: Text(
          _isCheckedIn ? 'Besucht' : 'Check-In',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isCheckedIn
              ? Colors.green.withValues(alpha: 0.3)
              : widget.accentColor.withValues(alpha: 0.8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: _isCheckedIn ? 0 : 4,
        ),
      ),
    );
  }
}
