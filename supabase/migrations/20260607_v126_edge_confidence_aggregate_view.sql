-- v126 2026-06-07: edge_confidence_aggregate view
-- EdgeConfidenceService queried a table that did not exist; result was
-- always null and aggregate confidence stayed invisible. This creates a
-- live SQL VIEW (no materialization needed -- table stays small per node
-- pair) that aggregates user ratings into (vote_count, avg_rating).
DROP VIEW IF EXISTS public.edge_confidence_aggregate;
CREATE VIEW public.edge_confidence_aggregate AS
SELECT
  world,
  node_a,
  node_b,
  COUNT(*)::int           AS vote_count,
  AVG(rating)::numeric(4,2) AS avg_rating
FROM public.user_edge_confidence
GROUP BY world, node_a, node_b;

-- Inherit RLS from user_edge_confidence -- the view runs as the calling
-- user. anon/authenticated need SELECT GRANT to read.
GRANT SELECT ON public.edge_confidence_aggregate TO anon;
GRANT SELECT ON public.edge_confidence_aggregate TO authenticated;
