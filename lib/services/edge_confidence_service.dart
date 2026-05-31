// EdgeConfidenceService — User-Ratings für Conspiracy-Network-Edges (B4).
//
// Speichert pro User + Welt + (node_a, node_b) ein Rating 1-5. Liefert
// auch die aggregierten Community-Werte (über alle User).

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

class EdgeConfidence {
  final int rating; // 1-5
  final int voteCount;
  final double avgRating;
  const EdgeConfidence({
    required this.rating,
    required this.voteCount,
    required this.avgRating,
  });
}

// dart2js-Bug-Workaround: Named Records kompilieren nicht zuverlaessig.
class _EdgePair {
  final String a;
  final String b;
  const _EdgePair(this.a, this.b);
}

class EdgeConfidenceService {
  EdgeConfidenceService._();
  static final instance = EdgeConfidenceService._();

  SupabaseClient get _s => Supabase.instance.client;

  /// Normalisiert das Node-Paar: alphabetisch sortiert.
  _EdgePair _normalize(String a, String b) {
    return a.compareTo(b) <= 0 ? _EdgePair(a, b) : _EdgePair(b, a);
  }

  Future<EdgeConfidence?> getForUser({
    required String userId,
    required String world,
    required String nodeA,
    required String nodeB,
  }) async {
    try {
      final pair = _normalize(nodeA, nodeB);

      // 1) eigene Bewertung
      final ownRes = await _s
          .from('user_edge_confidence')
          .select('rating')
          .eq('user_id', userId)
          .eq('world', world)
          .eq('node_a', pair.a)
          .eq('node_b', pair.b)
          .maybeSingle();
      final ownRating =
          (ownRes)?['rating'] as int? ?? 0;

      // 2) aggregat
      final aggRes = await _s
          .from('edge_confidence_aggregate')
          .select('vote_count,avg_rating')
          .eq('world', world)
          .eq('node_a', pair.a)
          .eq('node_b', pair.b)
          .maybeSingle();
      final voteCount =
          (aggRes)?['vote_count'] as int? ?? 0;
      final avgRating = ((aggRes)?['avg_rating'] as num?)?.toDouble() ?? 0.0;

      return EdgeConfidence(
        rating: ownRating,
        voteCount: voteCount,
        avgRating: avgRating,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ EdgeConfidence get: $e');
      return null;
    }
  }

  Future<bool> rate({
    required String userId,
    required String world,
    required String nodeA,
    required String nodeB,
    required int rating, // 1-5
    String? comment,
  }) async {
    if (rating < 1 || rating > 5) return false;
    try {
      final pair = _normalize(nodeA, nodeB);
      await _s.from('user_edge_confidence').upsert({
        'user_id': userId,
        'world': world,
        'node_a': pair.a,
        'node_b': pair.b,
        'rating': rating,
        'comment': comment,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,world,node_a,node_b');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ EdgeConfidence rate: $e');
      return false;
    }
  }
}
