import 'package:flutter/material.dart';
import 'soundcloud_player.dart';

/// 🎵 Musik SoundCloud Widget
/// 
/// Integriert SoundCloud in Musik-Chat als Alternative zu Radio
/// Features:
/// - Kuratierte SoundCloud Playlists
/// - Genre-basierte Empfehlungen
/// - Compact Player für Chat
/// - URL-Input für eigene Tracks
class MusicSoundCloudWidget extends StatefulWidget {
  final bool isExpanded;

  const MusicSoundCloudWidget({
    super.key,
    this.isExpanded = false,
  });

  @override
  State<MusicSoundCloudWidget> createState() => _MusicSoundCloudWidgetState();
}

class _MusicSoundCloudWidgetState extends State<MusicSoundCloudWidget> {
  String? _currentTrackUrl;
  bool _showUrlInput = false;
  final TextEditingController _urlController = TextEditingController();

  // 🎵 Kuratierte SoundCloud Playlists (ECHTE URLs - 2025) - 30+ GENRES!
  static const List<Map<String, String>> _curatedPlaylists = [
    // ✨ CHILL & RELAXING
    {
      'name': 'Lo-Fi Chill',
      'url': 'https://soundcloud.com/magicmusicsquad/sets/lofi-playlist-2025',
      'emoji': '😌',
      'color': '03A9F4',
    },
    {
      'name': 'Summer Vibes',
      'url': 'https://soundcloud.com/stormmusicgroup/sets/summer-vibes-music',
      'emoji': '☀️',
      'color': 'FFD700',
    },
    {
      'name': 'Ambient Piano',
      'url': 'https://soundcloud.com/klangspot/sets/calming-piano-music-best',
      'emoji': '🎹',
      'color': '90CAF9',
    },
    {
      'name': 'Classical',
      'url': 'https://soundcloud.com/klangspot/sets/classical-morning-relaxing',
      'emoji': '🎻',
      'color': '9FA8DA',
    },
    
    // 🎧 ELECTRONIC & DANCE
    {
      'name': 'Techno 2025',
      'url': 'https://soundcloud.com/vocaltrance4ever/sets/new-techno-music-01-01-2025',
      'emoji': '⚡',
      'color': '00D2FF',
    },
    {
      'name': 'EDM Hits',
      'url': 'https://soundcloud.com/vocaltrance4ever/sets/new-techno-music-08-08-2025',
      'emoji': '🎧',
      'color': '00BCD4',
    },
    {
      'name': 'Deep House',
      'url': 'https://soundcloud.com/m-sol-deep/deep-house-relax-chill-blue-vibes-best-deep-house-lounge-mix-2025',
      'emoji': '🏠',
      'color': '9C27B0',
    },
    {
      'name': 'Lounge 2025',
      'url': 'https://soundcloud.com/luk_music/sets/chill-lounge-2023-deep-house',
      'emoji': '🍸',
      'color': 'AB47BC',
    },
    {
      'name': 'Dubstep',
      'url': 'https://soundcloud.com/selected_playlist/sets/best-dubstep-trap-2025',
      'emoji': '🔊',
      'color': '7E57C2',
    },
    {
      'name': 'Drum & Bass',
      'url': 'https://soundcloud.com/quadportalrecords/sets/dnb2025',
      'emoji': '🥁',
      'color': '5E35B1',
    },
    {
      'name': 'Future Bass',
      'url': 'https://soundcloud.com/chendamusic/chenda2025set',
      'emoji': '🌊',
      'color': '3F51B5',
    },
    
    // 🎤 HIP HOP & RAP
    {
      'name': 'Hip Hop 2025',
      'url': 'https://soundcloud.com/dylanchasetannor/sets/rap-music-2025-best-rap-1',
      'emoji': '🎤',
      'color': 'FF9800',
    },
    {
      'name': 'Top Rap Hits',
      'url': 'https://soundcloud.com/globeats/sets/us-rap-playlist-2025-best',
      'emoji': '🔥',
      'color': 'FF6F00',
    },
    {
      'name': 'Party Mix',
      'url': 'https://soundcloud.com/hypedupreese/hip-hop-rb-2025-party-starter-mix',
      'emoji': '🎉',
      'color': 'F57C00',
    },
    
    // 🎶 R&B & SOUL
    {
      'name': 'R&B Soul',
      'url': 'https://soundcloud.com/clinton-shoyemi-117118674/2025-r-b-soul-mix-beyonce-ne',
      'emoji': '💜',
      'color': 'E91E63',
    },
    {
      'name': 'Jazz & Blues',
      'url': 'https://soundcloud.com/chillijil/sets/blues-jazz-r-b',
      'emoji': '🎷',
      'color': 'C2185B',
    },
    {
      'name': 'Late Night R&B',
      'url': 'https://soundcloud.com/boknowsdjing/late-nights-rnb-mix-2025-ft-sza-jazmine-sullivan-lucky-daye-partynextdoor-more-bo-aalegra',
      'emoji': '🌙',
      'color': 'AD1457',
    },
    
    // 🌍 WORLD & LATIN
    {
      'name': 'Afrobeat',
      'url': 'https://soundcloud.com/jo-coaching/sets/afro-beat-mix-2025',
      'emoji': '🌍',
      'color': '4CAF50',
    },
    {
      'name': 'Latin House',
      'url': 'https://soundcloud.com/house-rhythm-syndicate/best-afro-house-latin-house-mix-2025-week-1-november',
      'emoji': '💃',
      'color': '43A047',
    },
    {
      'name': 'Salsa Party',
      'url': 'https://soundcloud.com/jopey0718/party-mix-2025-salsa-reggaeton-afro-house-more',
      'emoji': '🎺',
      'color': '388E3C',
    },
    {
      'name': 'Reggae Vibes',
      'url': 'https://soundcloud.com/soundcloud-vibrations/sets/new-roots-reggae-afrobeats',
      'emoji': '🎸',
      'color': '2E7D32',
    },
    
    // 🎸 ROCK & INDIE
    {
      'name': 'Indie Rock',
      'url': 'https://soundcloud.com/alexrainbirdmusic/sets/2025-indie-rock',
      'emoji': '🎸',
      'color': 'F44336',
    },
    {
      'name': 'Alternative',
      'url': 'https://soundcloud.com/indiemusicnation/sets/indie-alternative-rock-june-7',
      'emoji': '🤘',
      'color': 'E53935',
    },
    {
      'name': 'Rock Classics',
      'url': 'https://soundcloud.com/alexrainbirdmusic/sets/january-2025-indie-rock-alt',
      'emoji': '⚡',
      'color': 'D32F2F',
    },
    
    // 🎻 ACOUSTIC & FOLK
    {
      'name': 'Acoustic Folk',
      'url': 'https://soundcloud.com/user-947739979/sets/bluegrass-folk-country',
      'emoji': '🎻',
      'color': '8D6E63',
    },
    {
      'name': 'Country',
      'url': 'https://soundcloud.com/robertrubymusic/sets/country-folk-americana-reel',
      'emoji': '🤠',
      'color': '795548',
    },
    {
      'name': 'Bluegrass',
      'url': 'https://soundcloud.com/danny-hensley-2/roots-of-my-heritage-6-23-2025',
      'emoji': '🪕',
      'color': '6D4C41',
    },
    
    // 💪 WORKOUT & ENERGY
    {
      'name': 'Workout Mix',
      'url': 'https://soundcloud.com/luk_music/sets/fitness-workout-mix-2023',
      'emoji': '💪',
      'color': 'FF5722',
    },
    {
      'name': 'Gym Motivation',
      'url': 'https://soundcloud.com/songrocket-records/sets/gym-music-2025-fitness-music',
      'emoji': '🏋️',
      'color': 'F4511E',
    },
    {
      'name': 'Dance Party',
      'url': 'https://soundcloud.com/kevin-riddagh/sets/party-mix-2025-party-music',
      'emoji': '💃',
      'color': 'E64A19',
    },
  ];

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _loadPlaylist(String url) {
    setState(() {
      _currentTrackUrl = url;
      _showUrlInput = false;
    });
  }

  void _loadCustomUrl() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty && SoundCloudHelper.isValidSoundCloudUrl(url)) {
      _loadPlaylist(url);
      _urlController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Ungültige SoundCloud URL'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isExpanded) {
      return _buildCompactView();
    }
    return _buildExpandedView();
  }

  Widget _buildCompactView() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF5500).withValues(alpha: 0.95), // SoundCloud Orange
            const Color(0xFFFF3300).withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // SoundCloud Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.cloud_queue,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentTrackUrl != null ? 'SoundCloud läuft...' : '☁️ SoundCloud',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tippe um Playlists zu sehen',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.cloud_queue, color: Color(0xFFFF5500), size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'SoundCloud Musik',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _showUrlInput ? Icons.close : Icons.add,
                  color: Colors.white,
                ),
                onPressed: () => setState(() => _showUrlInput = !_showUrlInput),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // URL Input
          if (_showUrlInput) ...[
            TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'SoundCloud URL eingeben...',
                hintStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.link, color: Colors.white70),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFFFF5500)),
                  onPressed: _loadCustomUrl,
                ),
              ),
              onSubmitted: (_) => _loadCustomUrl(),
            ),
            const SizedBox(height: 16),
          ],

          // Aktiver Player
          if (_currentTrackUrl != null) ...[
            SoundCloudCompactPlayer(
              trackUrl: _currentTrackUrl!,
              autoPlay: true,
            ),
            const SizedBox(height: 16),
          ],

          // Playlist Grid
          const Text(
            '🎵 Kuratierte Playlists',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.0,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _curatedPlaylists.length,
            itemBuilder: (context, index) {
              return _buildPlaylistCard(_curatedPlaylists[index]);
            },
          ),

          const SizedBox(height: 16),
          
          // Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Füge eigene SoundCloud URLs hinzu oder wähle eine Playlist',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistCard(Map<String, String> playlist) {
    final isActive = _currentTrackUrl == playlist['url'];
    final color = Color(int.parse('FF${playlist['color']}', radix: 16));

    return GestureDetector(
      onTap: () => _loadPlaylist(playlist['url']!),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: isActive ? 0.4 : 0.2),
              color.withValues(alpha: isActive ? 0.3 : 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(
              playlist['emoji']!,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                playlist['name']!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive)
              const Icon(
                Icons.play_circle_filled,
                color: Color(0xFFFF5500),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
