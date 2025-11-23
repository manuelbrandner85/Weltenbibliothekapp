import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';
import '../models/event_model.dart';
import 'event_detail_screen.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alle Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<EventProvider>().refreshEvents();
            },
            tooltip: 'Aktualisieren',
          ),
        ],
      ),
      body: Column(
        children: [
          // Suchleiste
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Events durchsuchen...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Event-Liste
          Expanded(
            child: Consumer<EventProvider>(
              builder: (context, eventProvider, child) {
                final events = _searchQuery.isEmpty
                    ? eventProvider.events
                    : eventProvider.searchEvents(_searchQuery);

                if (eventProvider.isLoading && events.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty
                              ? Icons.event_busy
                              : Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Keine Events vorhanden'
                              : 'Keine Events gefunden',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => eventProvider.refreshEvents(),
                  child: ListView.builder(
                    itemCount: events.length,
                    padding: const EdgeInsets.only(bottom: 80),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return _buildEventCard(event, eventProvider);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventModel event, EventProvider eventProvider) {
    final isFavorite = eventProvider.isFavorite(event.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToDetail(event),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bild
            if (event.imageUrl != null)
              Image.network(
                event.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 64),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titel
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_outline,
                          color: isFavorite ? Colors.red : null,
                        ),
                        onPressed: () {
                          eventProvider.toggleFavorite(event.id);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Beschreibung (gekürzt)
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  // Metadata
                  Row(
                    children: [
                      Chip(
                        avatar: Text(_getCategoryEmoji(event.category)),
                        label: Text(_getCategoryLabel(event.category)),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                      if (event.isVerified)
                        const Chip(
                          avatar: Icon(Icons.verified, size: 16),
                          label: Text('Verifiziert'),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.green,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd.MM.yyyy').format(event.date),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.place, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${event.location.latitude.toStringAsFixed(2)}, '
                        '${event.location.longitude.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryEmoji(String category) {
    final cat = EventCategory.values.firstWhere(
      (c) => c.name == category,
      orElse: () => EventCategory.mystery,
    );
    return cat.emoji;
  }

  String _getCategoryLabel(String category) {
    final cat = EventCategory.values.firstWhere(
      (c) => c.name == category,
      orElse: () => EventCategory.mystery,
    );
    return cat.label;
  }

  void _navigateToDetail(EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)),
    );
  }
}
