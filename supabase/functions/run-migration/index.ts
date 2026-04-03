// run-migration: DDL Migration Runner
// Uses Deno postgres client with Supabase's internal DB connection

import postgres from "https://deno.land/x/postgresjs@v3.4.4/mod.js";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const body = await req.json().catch(() => ({}));
    if (body.token !== 'mig13-wb-2026') {
      return new Response(JSON.stringify({ error: 'Forbidden' }), { 
        status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      });
    }

    // Supabase Edge Functions have access to DATABASE_URL env var
    const dbUrl = Deno.env.get('DATABASE_URL')!;
    
    const sql = postgres(dbUrl, { ssl: 'require', max: 1 });
    const results: any[] = [];

    const migrations = [
      { 
        name: 'add_read_by_column',
        sql: `ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS read_by TEXT[] NOT NULL DEFAULT '{}'`
      },
      {
        name: 'create_read_by_index',
        sql: `CREATE INDEX IF NOT EXISTS idx_chat_messages_read_by ON chat_messages USING GIN (read_by)`
      },
      {
        name: 'create_mark_message_as_read_fn',
        sql: `
          CREATE OR REPLACE FUNCTION mark_message_as_read(p_message_id TEXT, p_user_id TEXT) 
          RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
          BEGIN 
            UPDATE chat_messages 
            SET read_by = array_append(read_by, p_user_id) 
            WHERE id = p_message_id AND NOT (p_user_id = ANY(read_by)); 
          END; $$
        `
      },
      {
        name: 'create_mark_room_messages_as_read_fn',
        sql: `
          CREATE OR REPLACE FUNCTION mark_room_messages_as_read(p_room_id TEXT, p_user_id TEXT) 
          RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
          BEGIN 
            UPDATE chat_messages 
            SET read_by = array_append(read_by, p_user_id) 
            WHERE room_id = p_room_id AND is_deleted = FALSE AND NOT (p_user_id = ANY(read_by)); 
          END; $$
        `
      },
      {
        name: 'create_push_subscriptions_table',
        sql: `
          CREATE TABLE IF NOT EXISTS push_subscriptions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            endpoint TEXT NOT NULL,
            p256dh TEXT NOT NULL DEFAULT '',
            auth_key TEXT NOT NULL DEFAULT '',
            platform TEXT NOT NULL DEFAULT 'web',
            fcm_token TEXT,
            device_info JSONB DEFAULT '{}',
            is_active BOOLEAN NOT NULL DEFAULT TRUE,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            UNIQUE(user_id, endpoint)
          )
        `
      },
      {
        name: 'enable_rls_push_subscriptions',
        sql: `ALTER TABLE push_subscriptions ENABLE ROW LEVEL SECURITY`
      },
      {
        name: 'create_push_subscriptions_policy',
        sql: `
          DO $d$ BEGIN 
            IF NOT EXISTS (
              SELECT 1 FROM pg_policies 
              WHERE tablename='push_subscriptions' AND policyname='Users manage own push subscriptions'
            ) THEN 
              CREATE POLICY "Users manage own push subscriptions" ON push_subscriptions 
              FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id); 
            END IF; 
          END $d$
        `
      },
      {
        name: 'create_push_subscriptions_index',
        sql: `CREATE INDEX IF NOT EXISTS idx_push_subscriptions_user_id ON push_subscriptions(user_id)`
      },
      {
        name: 'create_notification_queue_table',
        sql: `
          CREATE TABLE IF NOT EXISTS notification_queue (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            data JSONB DEFAULT '{}',
            status TEXT NOT NULL DEFAULT 'pending',
            attempts INT NOT NULL DEFAULT 0,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            processed_at TIMESTAMPTZ
          )
        `
      },
      {
        name: 'create_notification_queue_index',
        sql: `CREATE INDEX IF NOT EXISTS idx_notification_queue_pending ON notification_queue(status, created_at) WHERE status = 'pending'`
      },
    ];

    for (const m of migrations) {
      try {
        await sql.unsafe(m.sql);
        results.push({ name: m.name, status: 'ok' });
      } catch (e: any) {
        const msg = String(e.message || e);
        // Ignore "already exists" errors
        if (msg.includes('already exists')) {
          results.push({ name: m.name, status: 'already_exists' });
        } else {
          results.push({ name: m.name, status: 'error', error: msg });
        }
      }
    }

    await sql.end();

    return new Response(JSON.stringify({ ok: true, results }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error: any) {
    return new Response(JSON.stringify({ error: String(error.message || error) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});
