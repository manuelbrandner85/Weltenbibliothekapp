import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../data/mystical_events_data.dart';
import '../models/event_model.dart';
import '../services/location_service.dart';
import 'modern_event_detail_screen.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen>
    with TickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  bool _isLoadingLocation = false;
  Position? _currentPosition;
  List<EventWithDistance>? _nearbyEvents;

  // Timeline-Animation Controls
  String _selectedEpoch = 'all'; // all, ancient, medieval, modern
  double _zoomLevel = 1.0; // 0.5x bis 2.0x
  late AnimationController _fadeController;
  late AnimationController _slideController;

  final Map<String, String> _epochs = {
    'all': '🌍 Alle Epochen',
    'ancient': '🏛️ Antike (<1000 n.Chr.)',
    'medieval': '🏰 Mittelalter (1000-1500)',
    'modern': '🎆 Neuzeit (1500+)',
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  List<EventModel> _filterEventsByEpoch(List<EventModel> events) {
    if (_selectedEpoch == 'all') return events;

    return events.where((event) {
      final year = event.date.year;
      switch (_selectedEpoch) {
        case 'ancient':
          return year < 1000;
        case 'medieval':
          return year >= 1000 && year < 1500;
        case 'modern':
          return year >= 1500;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allEvents = MysticalEventsData.getAllEvents();
    // Sortiere nach Datum (älteste zuerst)
    final sortedEvents = List<EventModel>.from(allEvents)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Epochen-Filter anwenden
    final filteredEvents = _filterEventsByEpoch(sortedEvents);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text(
          'Historische Timeline',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          // Satelliten-Button für GPS-basierte Event-Entdeckung
          IconButton(
            icon: Icon(
              Icons.satellite_alt,
              color: _nearbyEvents != null && _nearbyEvents!.isNotEmpty
                  ? Colors.greenAccent
                  : Colors.white,
            ),
            onPressed: _isLoadingLocation ? null : _findNearbyEvents,
            tooltip: 'Events in der Nähe finden',
          ),
        ],
      ),
      body: Column(
        children: [
          // GPS Status Banner (wenn aktiv)
          if (_currentPosition != null) _buildGpsStatusBanner(),

          // Nearby Events Banner (wenn Events gefunden)
          if (_nearbyEvents != null && _nearbyEvents!.isNotEmpty)
            _buildNearbyEventsBanner(),

          // Timeline Header mit Epochen-Filter & Zoom
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9B59B6), Color(0xFF3498DB)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9B59B6).withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                // Epochen-Filter
                Row(
                  children: [
                    const Icon(
                      Icons.filter_list,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _epochs.entries.map((entry) {
                            final isSelected = _selectedEpoch == entry.key;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedEpoch = entry.key;
                                    _slideController.reset();
                                    _slideController.forward();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.3)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    entry.value,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.white, height: 1),
                const SizedBox(height: 12),
                // Zoom Controls
                Row(
                  children: [
                    const Icon(Icons.zoom_in, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: _zoomLevel,
                        min: 0.5,
                        max: 2.0,
                        divisions: 15,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white.withValues(alpha: 0.3),
                        onChanged: (value) {
                          setState(() {
                            _zoomLevel = value;
                          });
                        },
                      ),
                    ),
                    Text(
                      '${(_zoomLevel * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Timeline Markers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TimelineMarker(label: '10000v', glow: true),
                    const Icon(Icons.arrow_forward, color: Colors.white),
                    _TimelineMarker(label: '2025', glow: true),
                    const Icon(Icons.arrow_forward, color: Colors.white),
                    _TimelineMarker(
                      label: '${filteredEvents.length}/${allEvents.length}',
                      glow: true,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Timeline List mit Animation
          Expanded(
            child: FadeTransition(
              opacity: _slideController.drive(
                CurveTween(curve: Curves.easeInOut),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredEvents.length,
                itemBuilder: (context, index) {
                  final event = filteredEvents[index];
                  final isLeft = index % 2 == 0;

                  // Prüfe ob Event in der Nähe ist
                  EventWithDistance? nearbyEvent;
                  if (_nearbyEvents != null) {
                    try {
                      nearbyEvent = _nearbyEvents!.firstWhere(
                        (e) => e.event.id == event.id,
                      );
                    } catch (e) {
                      nearbyEvent = null;
                    }
                  }

                  // Animierte Timeline-Items
                  return AnimatedBuilder(
                    animation: _fadeController,
                    builder: (context, child) {
                      final delay = (index * 0.05).clamp(0.0, 1.0);
                      final animation = CurvedAnimation(
                        parent: _fadeController,
                        curve: Interval(
                          delay,
                          (delay + 0.3).clamp(0.0, 1.0),
                          curve: Curves.easeOut,
                        ),
                      );

                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: isLeft
                                ? const Offset(-0.3, 0)
                                : const Offset(0.3, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: Transform.scale(
                            scale: _zoomLevel,
                            child: _buildTimelineItem(
                              context,
                              event,
                              isLeft,
                              nearbyEvent,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// GPS Status Banner
  Widget _buildGpsStatusBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.greenAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'GPS aktiv: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.greenAccent, size: 18),
            onPressed: () {
              setState(() {
                _currentPosition = null;
                _nearbyEvents = null;
              });
            },
          ),
        ],
      ),
    );
  }

  /// Nearby Events Banner
  Widget _buildNearbyEventsBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9B59B6), Color(0xFF3498DB)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.radar, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_nearbyEvents!.length} Events in deiner Nähe (< 50km)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _nearbyEvents!.length,
              itemBuilder: (context, index) {
                final eventWithDistance = _nearbyEvents![index];
                return _buildNearbyEventCard(eventWithDistance);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Nearby Event Card (horizontal scroll)
  Widget _buildNearbyEventCard(EventWithDistance eventWithDistance) {
    return Card(
      color: const Color(0xFF1A1A2E),
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ModernEventDetailScreen(event: eventWithDistance.event),
            ),
          );
        },
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.greenAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    eventWithDistance.formattedDistance,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                eventWithDistance.event.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                eventWithDistance.event.category.toUpperCase(),
                style: TextStyle(
                  color: const Color(0xFF9B59B6).withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Finde Events in der Nähe via GPS
  Future<void> _findNearbyEvents() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Prüfe Berechtigung
      final permissionStatus = await _locationService.checkPermissionStatus();

      if (permissionStatus == LocationPermissionStatus.serviceDisabled) {
        if (mounted) {
          _showErrorDialog(
            'GPS deaktiviert',
            'Bitte aktiviere GPS in den Geräteeinstellungen.',
          );
        }
        return;
      }

      if (permissionStatus == LocationPermissionStatus.denied) {
        final granted = await _locationService.requestPermission();
        if (!granted) {
          if (mounted) {
            _showErrorDialog(
              'Berechtigung verweigert',
              'Bitte erlaube Zugriff auf deinen Standort, um Events in der Nähe zu finden.',
            );
          }
          return;
        }
      }

      if (permissionStatus == LocationPermissionStatus.deniedForever) {
        if (mounted) {
          _showErrorDialog(
            'Berechtigung dauerhaft verweigert',
            'Bitte aktiviere die Standort-Berechtigung in den App-Einstellungen.',
            showSettingsButton: true,
          );
        }
        return;
      }

      // Hole aktuelle Position
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        if (mounted) {
          _showErrorDialog(
            'Standort nicht verfügbar',
            'Konnte deinen Standort nicht ermitteln. Bitte versuche es erneut.',
          );
        }
        return;
      }

      // Finde Events in der Nähe
      final allEvents = MysticalEventsData.getAllEvents();
      final nearbyEvents = await _locationService.findNearbyEvents(
        position,
        allEvents,
      );

      setState(() {
        _currentPosition = position;
        _nearbyEvents = nearbyEvents;
      });

      // Zeige Erfolgs-Nachricht
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nearbyEvents.isEmpty
                  ? 'Keine Events im Umkreis von 50km gefunden'
                  : '${nearbyEvents.length} Events in deiner Nähe gefunden!',
            ),
            backgroundColor: nearbyEvents.isEmpty
                ? Colors.orange
                : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Fehler', 'Ein Fehler ist aufgetreten: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  /// Zeige Fehler-Dialog
  void _showErrorDialog(
    String title,
    String message, {
    bool showSettingsButton = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          if (showSettingsButton)
            TextButton(
              onPressed: () {
                _locationService.openLocationSettings();
                Navigator.pop(context);
              },
              child: const Text('Einstellungen'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    EventModel event,
    bool isLeft,
    EventWithDistance? nearbyEvent,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          if (isLeft) ...[
            Expanded(child: _buildEventCard(context, event, nearbyEvent)),
            const SizedBox(width: 16),
            _buildTimelineIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Container()),
          ] else ...[
            Expanded(child: Container()),
            const SizedBox(width: 16),
            _buildTimelineIndicator(),
            const SizedBox(width: 16),
            Expanded(child: _buildEventCard(context, event, nearbyEvent)),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineIndicator() {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF9B59B6),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9B59B6).withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        Container(
          width: 2,
          height: 60,
          color: const Color(0xFF9B59B6).withValues(alpha: 0.3),
        ),
      ],
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    EventModel event,
    EventWithDistance? nearbyEvent,
  ) {
    final yearsBefore = DateTime.now().year - event.date.year;

    return Card(
      color: nearbyEvent != null
          ? const Color(0xFF1A1A2E).withValues(alpha: 1.0)
          : const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: nearbyEvent != null
            ? BorderSide(
                color: Colors.greenAccent.withValues(alpha: 0.5),
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ModernEventDetailScreen(event: event),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9B59B6).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      yearsBefore > 1000
                          ? '${(yearsBefore / 1000).toStringAsFixed(1)}k v.Chr.'
                          : yearsBefore > 0
                          ? '$yearsBefore v.Chr.'
                          : event.date.year.toString(),
                      style: const TextStyle(
                        color: Color(0xFF9B59B6),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Distanz-Badge (wenn in der Nähe)
                  if (nearbyEvent != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.greenAccent,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            nearbyEvent.formattedDistance,
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                event.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                event.description,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineMarker extends StatelessWidget {
  final String label;
  final bool glow;

  const _TimelineMarker({required this.label, this.glow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
