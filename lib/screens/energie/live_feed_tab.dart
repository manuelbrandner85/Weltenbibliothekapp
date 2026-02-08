import 'package:flutter/material.dart';
import '../../models/live_feed_entry.dart';
import '../../services/live_feed_service.dart';
import 'dart:async';

/// Live-Feed-Tab für MATERIE-Welt
class EnergieLiveFeedTab extends StatefulWidget {
  const EnergieLiveFeedTab({super.key});

  @override
  State<EnergieLiveFeedTab> createState() => _EnergieLiveFeedTabState();
}

class _EnergieLiveFeedTabState extends State<EnergieLiveFeedTab> {
  final _feedService = LiveFeedService();
  List<EnergieFeedEntry> _feeds = [];
  String? _themenFilter;
  Timer? _uiUpdateTimer;

  @override
  void initState() {
    super.initState();
    _loadFeeds();
    _feedService.startAutoUpdate();
    
    // Callback für Feed-Updates
    _feedService.onFeedsUpdated = (feeds) {
      if (mounted) {
        setState(() {
          _loadFeeds();
        });
      }
    };
    
    // UI-Update alle 30 Sekunden (für "vor X Min" Anzeige)
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFeeds() async {
    final feeds = await _feedService.getEnergieFeeds(themenFilter: _themenFilter);
    setState(() {
      _feeds = feeds;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.topCenter,
          colors: [Color(0xFF4A148C), Color(0xFF1A1A1A)],
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildFilterBar(),
          Expanded(
            child: _feeds.isEmpty
                ? _buildEmptyState()
                : _buildFeedList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final lastUpdate = _feedService.lastUpdate;
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.rss_feed, color: Color(0xFF9C27B0), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LIVE-FEEDS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          lastUpdate != null
                              ? 'Aktualisiert ${_getTimeSince(lastUpdate)}'
                              : 'Lade...',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_feeds.length} Einträge',
                  style: const TextStyle(
                    color: Color(0xFF9C27B0),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Alle', _themenFilter == null, () {
              setState(() => _themenFilter = null);
              _loadFeeds();
            }),
            const SizedBox(width: 8),
            _buildFilterChip('Kabbala', _themenFilter == 'Kabbala', () {
              setState(() => _themenFilter = 'Kabbala');
              _loadFeeds();
            }),
            const SizedBox(width: 8),
            _buildFilterChip('Symbolik', _themenFilter == 'Symbolik', () {
              setState(() => _themenFilter = 'Symbolik');
              _loadFeeds();
            }),
            const SizedBox(width: 8),
            _buildFilterChip('Archetypen', _themenFilter == 'Archetypen', () {
              setState(() => _themenFilter = 'Archetypen');
              _loadFeeds();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF9C27B0)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFeedList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _feeds.length,
      itemBuilder: (context, index) => _buildFeedCard(_feeds[index]),
    );
  }

  Widget _buildFeedCard(EnergieFeedEntry feed) {
    return GestureDetector(
      onTap: () => _showFeedDetail(feed),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: feed.isNeu
                ? const Color(0xFF4CAF50)
                : const Color(0xFF9C27B0).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    feed.quellenTypLabel,
                    style: const TextStyle(
                      color: Color(0xFF9C27B0),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (feed.isNeu || feed.isAktualisiert)
                  Text(
                    feed.updateTypeLabel,
                    style: TextStyle(
                      color: feed.isNeu ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const Spacer(),
                Text(
                  feed.zeitSeitUpdate,
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Titel
            Text(
              feed.titel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Zusammenfassung
            Text(
              feed.symbolischeEinordnung,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            
            // Meta
            Row(
              children: [
                const Icon(Icons.source, color: Colors.white60, size: 14),
                const SizedBox(width: 4),
                Text(
                  feed.quelle,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Spirituell',
                    style: TextStyle(
                      color: const Color(0xFF9C27B0),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // TODO: Review unused method: _getTiefeLevelColor
  // Color _getTiefeLevelColor(int level) {
    // switch (level) {
      // case 1:
      // case 2:
        // return const Color(0xFF4CAF50);
      // case 3:
        // return const Color(0xFFFF9800);
      // case 4:
      // case 5:
        // return const Color(0xFFF44336);
      // default:
        // return Colors.white60;
    // }
  // }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rss_feed, size: 64, color: Colors.white30),
          SizedBox(height: 16),
          Text(
            'Keine Feeds gefunden',
            style: TextStyle(color: Colors.white60, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showFeedDetail(EnergieFeedEntry feed) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Header
              Text(
                feed.titel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.source, color: Color(0xFF9C27B0), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    feed.quelle,
                    style: const TextStyle(color: Color(0xFF9C27B0), fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    feed.zeitSeitUpdate,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Zusammenfassung
              const Text(
                'ZUSAMMENFASSUNG',
                style: TextStyle(
                  color: Color(0xFF9C27B0),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                feed.symbolischeEinordnung,
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 24),
              
              // Zentrale Fragestellung
              const Text(
                'ZENTRALE FRAGESTELLUNG',
                style: TextStyle(
                  color: Color(0xFF9C27B0),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  feed.reflexionsfragen.isNotEmpty ? feed.reflexionsfragen.first : 'Keine Fragen',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              
              if (feed.reflexionsfragen.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'REFLEXIONSFRAGEN',
                  style: TextStyle(
                    color: Color(0xFF9C27B0),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                ...feed.reflexionsfragen.map((narrative) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Color(0xFF9C27B0))),
                      Expanded(
                        child: Text(
                          narrative,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
              
              if (feed.archetypen.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'ARCHETYPEN',
                  style: TextStyle(
                    color: Color(0xFF9C27B0),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  feed.archetypen.join(", "),
                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
                ),
              ],
              
              if (feed.warumAngezeigtGrund != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Warum wird mir das angezeigt? ${feed.warumAngezeigtGrund}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Öffne Source URL (in Production)
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Quelle öffnen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27B0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeSince(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) {
      return 'gerade eben';
    } else if (diff.inMinutes < 60) {
      return 'vor ${diff.inMinutes} Min';
    } else {
      return 'vor ${diff.inHours} Std';
    }
  }
}
