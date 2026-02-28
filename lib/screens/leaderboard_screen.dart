// =====================================================================
// LEADERBOARD SCREEN v1.0
// =====================================================================
// UI für Bestenlisten und Rankings
// Features:
// - Tabbed Interface (All-Time/Weekly/Monthly/Friends)
// - Top 10 Highlights
// - Current User Position
// - Rank Badges
// - Smooth Animations
// =====================================================================

import 'package:flutter/material.dart';
import '../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../services/leaderboard_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  final _leaderboardService = LeaderboardService();
  late TabController _tabController;
  
  LeaderboardType _currentType = LeaderboardType.allTime;
  List<LeaderboardEntry> _entries = [];
  LeaderboardEntry? _currentUserEntry;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentType = LeaderboardType.values[_tabController.index];
        _isLoading = true;
      });
      _loadLeaderboard();
    }
  }

  Future<void> _loadLeaderboard() async {
    try {
      final entries = await _leaderboardService.getLeaderboard(_currentType);
      final currentUser = await _leaderboardService.getCurrentUserEntry(_currentType);
      
      setState(() {
        _entries = entries;
        _currentUserEntry = currentUser;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'BESTENLISTE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: LeaderboardType.values.map((type) {
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(type.icon),
                  const SizedBox(width: 4),
                  Text(type.label),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : _buildLeaderboardView(),
    );
  }

  // =====================================================================
  // LEADERBOARD VIEW
  // =====================================================================

  Widget _buildLeaderboardView() {
    return CustomScrollView(
      slivers: [
        // CURRENT USER CARD
        if (_currentUserEntry != null)
          SliverToBoxAdapter(
            child: _buildCurrentUserCard(_currentUserEntry!),
          ),

        // TOP 3 PODIUM
        SliverToBoxAdapter(
          child: _buildPodium(),
        ),

        // LEADERBOARD LIST
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < 3) return const SizedBox.shrink(); // Skip top 3
                return _buildLeaderboardTile(_entries[index], index);
              },
              childCount: _entries.length,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  // =====================================================================
  // CURRENT USER CARD
  // =====================================================================

  Widget _buildCurrentUserCard(LeaderboardEntry entry) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade700,
            Colors.purple.shade900,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank Badge
          _buildRankBadge(entry.rank, size: 50),
          
          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatChip('Level ${entry.level}', Icons.military_tech),
                    const SizedBox(width: 8),
                    _buildStatChip('${entry.totalXp} XP', Icons.stars),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // PODIUM (TOP 3)
  // =====================================================================

  Widget _buildPodium() {
    if (_entries.length < 3) return const SizedBox.shrink();

    final top3 = _entries.take(3).toList();
    
    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          Expanded(child: _buildPodiumPlace(top3[1], 2, 200)),
          const SizedBox(width: 8),
          // 1st Place
          Expanded(child: _buildPodiumPlace(top3[0], 1, 250)),
          const SizedBox(width: 8),
          // 3rd Place
          Expanded(child: _buildPodiumPlace(top3[2], 3, 160)),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(LeaderboardEntry entry, int rank, double height) {
    Color color;
    String medal;
    
    switch (rank) {
      case 1:
        color = Colors.amber;
        medal = '🥇';
        break;
      case 2:
        color = Colors.grey.shade400;
        medal = '🥈';
        break;
      case 3:
        color = Colors.brown.shade300;
        medal = '🥉';
        break;
      default:
        color = Colors.grey;
        medal = '🏅';
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (rank * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Medal
          Text(medal, style: const TextStyle(fontSize: 40)),
          
          const SizedBox(height: 8),

          // Avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: color.withValues(alpha: 0.3),
            child: Text(
              entry.username[0].toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Username
          Text(
            entry.username,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // XP
          Text(
            '${entry.totalXp} XP',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 12),

          // Podium
          Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.6),
                  color.withValues(alpha: 0.3),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: color,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // LEADERBOARD TILE
  // =====================================================================

  Widget _buildLeaderboardTile(LeaderboardEntry entry, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: entry.isCurrentUser
              ? Colors.purple.shade900.withValues(alpha: 0.3)
              : const Color(0xFF1D1E33),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: entry.isCurrentUser
                ? Colors.purple.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
            width: entry.isCurrentUser ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Rank
            _buildRankBadge(entry.rank),
            
            const SizedBox(width: 16),

            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              child: Text(
                entry.username[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Level ${entry.level} • ${entry.achievementCount} Achievements',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // XP
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${entry.totalXp} XP',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // HELPERS
  // =====================================================================

  Widget _buildRankBadge(int rank, {double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: rank <= 10
              ? [Colors.amber, Colors.orange]
              : [Colors.blue.shade700, Colors.blue.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (rank <= 10 ? Colors.amber : Colors.blue).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.amber, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
