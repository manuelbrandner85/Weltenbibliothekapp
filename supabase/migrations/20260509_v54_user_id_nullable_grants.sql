-- v54: chat_messages user_id nullable + GRANT-Absicherung
-- Zusatz zu v53: user_id war in 001_initial_schema.sql als NOT NULL definiert.
-- Falls signInAnonymously() fehlschlägt und kein currentUser → user_id fehlt im Insert → NOT NULL Fehler.

-- user_id nullable machen (war ursprünglich NOT NULL REFERENCES auth.users)
ALTER TABLE public.chat_messages ALTER COLUMN user_id DROP NOT NULL;

-- Sicherheits-GRANT (falls v53 noch nicht vollständig gelaufen ist)
GRANT SELECT ON public.chat_rooms TO anon;
GRANT SELECT ON public.chat_rooms TO authenticated;
GRANT SELECT, INSERT ON public.chat_messages TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.chat_messages TO authenticated;

-- FK auf user_id→auth.users droppen (ebenfalls aus 001_initial_schema.sql)
ALTER TABLE public.chat_messages DROP CONSTRAINT IF EXISTS chat_messages_user_id_fkey;
