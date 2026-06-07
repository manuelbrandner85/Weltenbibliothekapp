-- v125 2026-06-07: prediction_votes table for the materie event-predictor
-- vote feature. Previously the client tried to insert into a table that
-- did not exist -- every vote silently failed with "Vote derzeit nicht
-- moeglich". This migration adds the table with a UNIQUE(prediction_id,
-- user_id) constraint so a fast double-tap can never produce 2 rows.

CREATE TABLE IF NOT EXISTS public.prediction_votes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  prediction_id text NOT NULL,
  user_id text NULL,
  vote smallint NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Idempotent insert key: same (prediction, user) => one row.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.prediction_votes'::regclass
      AND conname  = 'prediction_votes_unique_user_pred'
  ) THEN
    ALTER TABLE public.prediction_votes
      ADD CONSTRAINT prediction_votes_unique_user_pred
      UNIQUE (prediction_id, user_id);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS prediction_votes_pred_idx
  ON public.prediction_votes (prediction_id);

ALTER TABLE public.prediction_votes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS prediction_votes_select_all ON public.prediction_votes;
CREATE POLICY prediction_votes_select_all ON public.prediction_votes
  FOR SELECT USING (true);

DROP POLICY IF EXISTS prediction_votes_insert_any ON public.prediction_votes;
CREATE POLICY prediction_votes_insert_any ON public.prediction_votes
  FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS prediction_votes_update_own ON public.prediction_votes;
CREATE POLICY prediction_votes_update_own ON public.prediction_votes
  FOR UPDATE USING (true) WITH CHECK (true);

GRANT SELECT, INSERT, UPDATE ON public.prediction_votes TO anon;
GRANT SELECT, INSERT, UPDATE ON public.prediction_votes TO authenticated;
