import 'package:flutter/material.dart';
import '../models/room_connection_state.dart';

/// ═══════════════════════════════════════════════════════════════
/// CONNECTION QUALITY INDICATOR
/// ═══════════════════════════════════════════════════════════════
/// Visual indicator for WebRTC connection quality
///
/// Features:
/// - Color-coded quality badges
/// - Animated signal strength icons
/// - Detailed stats on tap
/// - Quality messages
/// ═══════════════════════════════════════════════════════════════

class ConnectionQualityIndicator extends StatelessWidget {
  final ConnectionQuality quality;
  final RoomStats? roomStats;
  final bool showDetails;
  final VoidCallback? onTap;

  const ConnectionQualityIndicator({
    super.key,
    required this.quality,
    this.roomStats,
    this.showDetails = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getBackgroundColor().withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _getBackgroundColor(), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getIcon(), color: _getBackgroundColor(), size: 16),
            const SizedBox(width: 6),
            Text(
              _getLabel(),
              style: TextStyle(
                color: _getBackgroundColor(),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (showDetails && roomStats != null) ...[
              const SizedBox(width: 8),
              Text(
                '${roomStats!.averageRttMs}ms',
                style: TextStyle(
                  color: _getBackgroundColor().withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (quality) {
      case ConnectionQuality.excellent:
        return Colors.green;
      case ConnectionQuality.good:
        return Colors.lightGreen;
      case ConnectionQuality.poor:
        return Colors.orange;
      case ConnectionQuality.critical:
        return Colors.red;
      case ConnectionQuality.unknown:
        return Colors.grey;
    }
  }

  IconData _getIcon() {
    switch (quality) {
      case ConnectionQuality.excellent:
        return Icons.signal_cellular_alt;
      case ConnectionQuality.good:
        return Icons.signal_cellular_alt_2_bar;
      case ConnectionQuality.poor:
        return Icons.signal_cellular_alt_1_bar;
      case ConnectionQuality.critical:
        return Icons.signal_cellular_connected_no_internet_0_bar;
      case ConnectionQuality.unknown:
        return Icons.signal_cellular_null;
    }
  }

  String _getLabel() {
    switch (quality) {
      case ConnectionQuality.excellent:
        return 'Excellent';
      case ConnectionQuality.good:
        return 'Good';
      case ConnectionQuality.poor:
        return 'Poor';
      case ConnectionQuality.critical:
        return 'Critical';
      case ConnectionQuality.unknown:
        return 'Unknown';
    }
  }
}

/// ═══════════════════════════════════════════════════════════════
/// DETAILED CONNECTION STATS DIALOG
/// ═══════════════════════════════════════════════════════════════

class ConnectionStatsDialog extends StatelessWidget {
  final RoomStats roomStats;
  final Map<String, ConnectionStats>? peerStats;

  const ConnectionStatsDialog({
    super.key,
    required this.roomStats,
    this.peerStats,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: const Text(
        'Connection Statistics',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room Stats
            _buildSectionTitle('Room Overview'),
            _buildStatRow('Participants', '${roomStats.participantCount}'),
            _buildStatRow('Average RTT', '${roomStats.averageRttMs} ms'),
            _buildStatRow(
              'Packet Loss',
              '${roomStats.packetLossPercent.toStringAsFixed(1)}%',
            ),
            _buildStatRow(
              'Upload',
              '${roomStats.uploadBandwidthMbps.toStringAsFixed(2)} Mbps',
            ),
            _buildStatRow(
              'Download',
              '${roomStats.downloadBandwidthMbps.toStringAsFixed(2)} Mbps',
            ),

            // Quality Badge
            const SizedBox(height: 16),
            ConnectionQualityIndicator(
              quality: roomStats.quality,
              roomStats: roomStats,
              showDetails: true,
            ),

            // Peer Stats
            if (peerStats != null && peerStats!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSectionTitle('Peer Connections'),
              ...peerStats!.entries.map(
                (entry) => _buildPeerCard(entry.key, entry.value),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Close',
            style: TextStyle(color: Color(0xFF8B5CF6)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF8B5CF6),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeerCard(String peerId, ConnectionStats stats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getQualityColor(stats.quality).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                peerId,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ConnectionQualityIndicator(
                quality: stats.quality,
                showDetails: false,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('RTT', '${stats.rttMs}ms'),
              _buildMiniStat('Loss', '${stats.packetLoss.toStringAsFixed(1)}%'),
              _buildMiniStat('Jitter', '${stats.jitterMs}ms'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getQualityColor(ConnectionQuality quality) {
    switch (quality) {
      case ConnectionQuality.excellent:
        return Colors.green;
      case ConnectionQuality.good:
        return Colors.lightGreen;
      case ConnectionQuality.poor:
        return Colors.orange;
      case ConnectionQuality.critical:
        return Colors.red;
      case ConnectionQuality.unknown:
        return Colors.grey;
    }
  }
}
