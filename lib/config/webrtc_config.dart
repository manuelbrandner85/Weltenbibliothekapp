/// ═══════════════════════════════════════════════════════════════
/// WEBRTC CONFIGURATION - Weltenbibliothek
/// ═══════════════════════════════════════════════════════════════
/// ✅ PRODUCTION-READY: Unified STUN/TURN configuration
///
/// FEATURES:
/// - Google STUN servers (fast, reliable NAT detection)
/// - Metered.ca TURN servers (free tier, handles Symmetric NAT)
/// - Multiple protocols: UDP, TCP, TLS (Port 443)
/// - Fixes: One-way video, Connection failures, Firewall issues
///
/// TURN SERVER INFO:
/// - Provider: Metered.ca (https://www.metered.ca/tools/openrelay/)
/// - Free tier: 50GB/month traffic
/// - Protocols: UDP (port 80), TCP (port 80/443), TLS (port 443)
/// - Latency: Global anycast network
///
/// FOR UPGRADE (Optional):
/// - Cloudflare Calls TURN (requires subscription)
/// - Self-hosted Coturn server
/// ═══════════════════════════════════════════════════════════════

class WebRTCConfig {
  /// ✅ Unified ICE Servers Configuration
  ///
  /// Using Google STUN + Metered.ca TURN servers (free tier, production-ready)
  /// Supports Symmetric NAT and complex network topologies
  static final Map<String, dynamic> iceServers = {
    'iceServers': [
      // Google STUN servers (primary NAT traversal)
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},

      // ✅ PRODUCTION TURN SERVERS - Metered.ca (Free Tier)
      // Handles Symmetric NAT, Firewall traversal, One-way video fixes
      {
        'urls': 'turn:a.relay.metered.ca:80',
        'username': 'c71aa02dc4baaa26942a3e1c',
        'credential': 'Mji3tBjcLFPSxaYL',
      },
      {
        'urls': 'turn:a.relay.metered.ca:80?transport=tcp',
        'username': 'c71aa02dc4baaa26942a3e1c',
        'credential': 'Mji3tBjcLFPSxaYL',
      },
      {
        'urls': 'turn:a.relay.metered.ca:443',
        'username': 'c71aa02dc4baaa26942a3e1c',
        'credential': 'Mji3tBjcLFPSxaYL',
      },
      {
        'urls': 'turn:a.relay.metered.ca:443?transport=tcp',
        'username': 'c71aa02dc4baaa26942a3e1c',
        'credential': 'Mji3tBjcLFPSxaYL',
      },
    ],
    'iceCandidatePoolSize': 10,
    'sdpSemantics': 'unified-plan',
  };

  /// Alternative: Cloudflare TURN Configuration Template
  /// (For future use when Cloudflare Calls is configured)
  /// Guide: https://developers.cloudflare.com/calls/turn/
  static Map<String, dynamic> get cloudflareIceServers => {
    'iceServers': [
      // Cloudflare STUN
      {'urls': 'stun:stun.cloudflare.com:3478'},

      // Cloudflare TURN (requires Cloudflare Calls subscription + real credentials)
      // To get credentials: Cloudflare Dashboard > Calls > TURN Credentials
      {
        'urls': ['turn:relay.cloudflare.com:3478?transport=udp'],
        'username': 'YOUR_CLOUDFLARE_TURN_USERNAME',
        'credential': 'YOUR_CLOUDFLARE_TURN_CREDENTIAL',
      },
    ],
    'iceCandidatePoolSize': 10,
    'sdpSemantics': 'unified-plan',
  };

  /// Get ICE servers for production environment
  /// (Currently returns Google STUN - update for production)
  static Map<String, dynamic> getIceServersForEnvironment({
    bool useCloudflare = false,
  }) {
    return useCloudflare ? cloudflareIceServers : iceServers;
  }
}
