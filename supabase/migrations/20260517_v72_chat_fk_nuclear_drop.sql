-- v72: Chat FK nuclear drop + GRANT-Absicherung
-- Behebt "permission denied for table chat_rooms" dauerhaft.
-- Vorherige Migrationen (v53/v56) haben den FK nur per Name gedroppt —
-- wenn der Constraint-Name abwich, blieb er bestehen.
-- Diese Migration droppt ALLE FKs von chat_messages auf chat_rooms via FOR-Loop.

-- 1. Alle FK-Constraints von chat_messages → chat_rooms droppen (FOR-Loop = exhaustiv)
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT tc.constraint_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.referential_constraints rc
      ON rc.constraint_name = tc.constraint_name
      AND rc.constraint_schema = tc.constraint_schema
    JOIN information_schema.table_constraints tc2
      ON tc2.constraint_name = rc.unique_constraint_name
      AND tc2.constraint_schema = rc.unique_constraint_schema
    WHERE tc.table_schema = 'public'
      AND tc.table_name   = 'chat_messages'
      AND tc.constraint_type = 'FOREIGN KEY'
      AND tc2.table_name = 'chat_rooms'
  LOOP
    EXECUTE format('ALTER TABLE public.chat_messages DROP CONSTRAINT IF EXISTS %I', r.constraint_name);
    RAISE NOTICE 'Dropped FK constraint: %', r.constraint_name;
  END LOOP;
END $$;

-- Fallback: auch alle FK-Constraints droppen die "room" im Namen haben
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT constraint_name
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name   = 'chat_messages'
      AND constraint_type = 'FOREIGN KEY'
      AND constraint_name ILIKE '%room%'
  LOOP
    EXECUTE format('ALTER TABLE public.chat_messages DROP CONSTRAINT IF EXISTS %I', r.constraint_name);
    RAISE NOTICE 'Dropped room-FK: %', r.constraint_name;
  END LOOP;
END $$;

-- 2. GRANT SELECT auf chat_rooms (FK-Check braucht das — idempotent)
GRANT SELECT ON public.chat_rooms TO anon;
GRANT SELECT ON public.chat_rooms TO authenticated;

-- 3. RLS auf chat_rooms + offene SELECT-Policy
ALTER TABLE public.chat_rooms ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "chat_rooms_select_all" ON public.chat_rooms;
CREATE POLICY "chat_rooms_select_all" ON public.chat_rooms
  FOR SELECT USING (true);

-- 4. Vollständige Grants für chat_messages sicherstellen
GRANT SELECT, INSERT, UPDATE, DELETE ON public.chat_messages TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.chat_messages TO authenticated;

-- 5. INSERT-Policy: Jeder darf schreiben (anon + authenticated)
DROP POLICY IF EXISTS "chat_insert_allow_all"  ON public.chat_messages;
DROP POLICY IF EXISTS "chat_messages_insert_auth" ON public.chat_messages;
CREATE POLICY "chat_insert_allow_all" ON public.chat_messages
  FOR INSERT WITH CHECK (true);

-- 6. SELECT-Policy: Alle können lesen
DROP POLICY IF EXISTS "chat_messages_select_all" ON public.chat_messages;
CREATE POLICY "chat_messages_select_all" ON public.chat_messages
  FOR SELECT USING (true);

-- 7. UPDATE-Policy: eigene Nachrichten bearbeiten
--    user_id = auth.uid() ODER username = eigener Username aus Profil
DROP POLICY IF EXISTS "chat_messages_update_own"   ON public.chat_messages;
DROP POLICY IF EXISTS "chat_messages_admin_update" ON public.chat_messages;

CREATE POLICY "chat_messages_update_own" ON public.chat_messages
  FOR UPDATE USING (
    auth.uid() IS NOT NULL
    AND (
      user_id::text = auth.uid()::text
      OR username = (
        SELECT raw_user_meta_data->>'username'
        FROM auth.users WHERE id = auth.uid()
      )
    )
  );

CREATE POLICY "chat_messages_admin_update" ON public.chat_messages
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'moderator', 'root', 'root_admin')
    )
  );

-- 8. DELETE-Policy: eigene Nachrichten löschen + Admin kann alles löschen
DROP POLICY IF EXISTS "chat_messages_delete_own"   ON public.chat_messages;
DROP POLICY IF EXISTS "chat_messages_admin_delete" ON public.chat_messages;

CREATE POLICY "chat_messages_delete_own" ON public.chat_messages
  FOR DELETE USING (
    auth.uid() IS NOT NULL
    AND (
      user_id::text = auth.uid()::text
      OR username = (
        SELECT raw_user_meta_data->>'username'
        FROM auth.users WHERE id = auth.uid()
      )
    )
  );

CREATE POLICY "chat_messages_admin_delete" ON public.chat_messages
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'moderator', 'root', 'root_admin')
    )
  );
