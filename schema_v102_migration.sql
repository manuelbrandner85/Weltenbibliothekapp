-- ============================================================================
-- WELTENBIBLIOTHEK V102 - SCHEMA MIGRATION
-- Backend-First Voice Join: session_id column + duration_seconds
-- ============================================================================

-- Add session_id and duration_seconds columns to voice_sessions
ALTER TABLE voice_sessions ADD COLUMN session_id TEXT;
ALTER TABLE voice_sessions ADD COLUMN duration_seconds INTEGER DEFAULT 0;
ALTER TABLE voice_sessions ADD COLUMN speaking_seconds INTEGER DEFAULT 0;

-- Create index for session_id lookups
CREATE INDEX IF NOT EXISTS idx_voice_sessions_session_id 
  ON voice_sessions(session_id);

-- Update existing records: copy id to session_id
UPDATE voice_sessions SET session_id = id WHERE session_id IS NULL;

-- Note: Primary key remains 'id' for backwards compatibility
-- New inserts should use session_id as the main identifier
